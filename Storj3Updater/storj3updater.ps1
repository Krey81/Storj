# Storj3Updater script by Krey (krey@irinium.ru)
# this script download storagenode binary from two sources
# 1. From links provided by version.storj.io
# 2. From docker storagenode docker images on hub.docker.com
# https://github.com/Krey81/Storj

$v = "0.1.4"

# Changes:
# v0.1      - 20200304 Initial version. Download only (no update and service start\stop).
# v0.1.1    - 20200304 Fix arch detection on linux, small other fixes
# v0.1.2    - 20200305
#           - Fix arch armv7l detection on linux
#           - Check cloud url for suggested version match
#           - Caching docker image digest to prevent unneeded downloads
#           - Systemd integration for automatic start and stop nodes during update
#           - other bug fixes
#           - add some constants and descriptions
# v0.1.3    - 20200318 Fix caching docker image
# v0.1.4    - 20201009 
#           - Fix permission denied on linux
#           - Add cursor check
#           - systemd_integration default to true

# INPUT PARAMS ------------------------------------------------------
$constants = @{
    #target dir path for update only (download command write file to current directory)
    target = "/usr/sbin";

    #os type: windows, linux. Script will try to autodetect it
    os = "";

    #platform architecture: amd64, arm64, armv6 etc. Script will try to autodetect it
    arch = "";

    #DEBUG
    #target = "C:\Projects\Repos\Storj"
    #os = "linux"
    #arch = "amd64"

    #storagenode image name on docker hub
    image = "storjlabs/storagenode";

    #image tag on docker hub
    tag="latest";

    #update when cursor equals this symbol, or immediatelly when wait_cursor empty
    wait_cursor="f";

    #dir for temp files. Script will try to autodetect it
    temp_path="";
    
    #subdirectory in temp directory for script
    temp_path_dir="storj-blob";

    #subdirectory in temp_path_dir for extraction fs from docker images
    temp_path_dir_fs="fs";

    #file name within temp_path for caching values between runs
    mem_file = "Storj3Updater_mem";

    #storagenode binary name. For windows script add ".exe" to it
    binary_name="storagenode"

    #if true script will stoping systemd services before update and start it after update
    systemd_integration = $true
    #system service name search pattern. I named my services like storj-node02
    service_pattern = "storj-node??.service";

    #other runtime values (do not fill it)
    digest="";
    command="";
    method="auto";
}

# uri templates for external API queries
$hubUriTemplate= "https://hub.docker.com/v2/repositories/{image}/tags/{tag}"
$authUriTemplate = "https://auth.docker.io/token?service=registry.docker.io&scope=repository:{image}:pull"
$manifestUriTemplate = "https://registry-1.docker.io/v2/{image}/manifests/{digest}"
$blobUriTemplate = "https://registry-1.docker.io/v2/{image}/blobs/{digest}"
$versionUriTemplate = "https://version.storj.io"

# END OF INPUT PARAMS ------------------------------------------------------

function ExternalCommand 
{
    param ($file, $arguments)
    $temp = $null
    try
    {
        $temp = [System.IO.Path]::GetTempFileName()
        $p = Start-Process -FilePath $file -ArgumentList $arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput $temp
        if (($p.ExitCode -ne 0) -or (-not [System.IO.File]::Exists($temp))) { throw "Failed on external command" }

        $text = [System.IO.File]::ReadAllLines($temp)
        return $text

    }
    finally
    {
        if ($null -ne $temp -and [System.IO.File]::Exists($temp)) { Remove-Item $temp}
    }
}

function Set-Os {
    param($constants)

    if ([String]::IsNullOrEmpty($constants.os)) { $constants.os = $env:OS }
    if ([String]::IsNullOrEmpty($constants.os)) { 
        if ($IsLinux) { $constants.os = "linux" }
        elseif ($IsMacOS) { $constants.os = "macos" }
        elseif ($IsWindows) { $constants.os = "windows" }
    }
    
    if ($constants.os -eq "Windows_NT") { $constants.os = "Windows" }
    if ([String]::IsNullOrEmpty($constants.os)) { throw "Unknown OS. Please specify it in constants in script body" }

    if ([String]::IsNullOrEmpty($constants.arch)) { $constants.arch = $env:PROCESSOR_ARCHITECTURE }
    if ([String]::IsNullOrEmpty($constants.arch) -and $IsLinux) {
        $constants.arch = ExternalCommand -file "uname" -arguments "-m"
        if ($constants.arch -eq "x86_64") { $constants.arch = "amd64" }
        elseif ($constants.arch -eq "armv7l") { $constants.arch = "arm64" }
    }

    if ([String]::IsNullOrEmpty($constants.arch)) { throw "Unknown architecture. Please specify it in constants in script body" }
}

function GetConstants {
    param($constants, $cmdlineArgs)
    Set-Os -constants $constants

    if ([String]::IsNullOrEmpty($constants.target)) { $constants.target = Get-Location }

    if ($cmdlineArgs.Length -gt 0) { $constants.command = $cmdlineArgs[0] }

    $idx = $cmdlineArgs.IndexOf("-m")
    if ($idx -gt 0 -and $cmdlineArgs.Length -ge ($idx + 1)) {
        $constants.method = $cmdlineArgs[$idx + 1]
    }

    return $constants
}
 

function IsAnniversaryVersion {
    param($vstr)
    $standardBootleVolumeLitters = 0.5
    $vstr = [String]::Join(".", ($vstr.Split('.') | Select-Object -First 2) )
    $vdec = [Decimal]::Parse($vstr, [CultureInfo]::InvariantCulture)
    if (($vdec % $standardBootleVolumeLitters) -eq 0.0) { return $true }
    else { return $false }
}

function Preamble{
    Write-Host ""
    Write-Host -NoNewline ("Storj3Updater script by Krey ver {0}" -f $v)
    if (IsAnniversaryVersion($v)) { Write-Host -ForegroundColor Green "`t- Anniversary version: Astrologers proclaim the week of incredible bottled income" }
    else { Write-Host }
    Write-Host "mail-to: krey@irinium.ru"
    Write-Host ""
    Write-Host -ForegroundColor Yellow "I work on beer. If you like my scripts please donate bottle of beer in STORJ or ETH to 0x7df3157909face2dd972019d590adba65d83b1d8"
    Write-Host -ForegroundColor Gray "Why should I send bootles if everything works like that ?"
    Write-Host -ForegroundColor Gray "... see TODO comments in the script body"
    Write-Host ""
}

function GetUri
{
    param ($template, $constants)
    if ($null -eq $constants) { throw "Bad constants" }

    $uri = $template
    $constants.Keys | ForEach-Object {
        $repl = '{' + $_ + '}'
        if ($uri.Contains($repl)) {
            $uri = $uri.Replace($repl, $constants[$_])
        }
    }
    return $uri
}


function IsNeedNewToken
{
    param($token)
    if ($null -eq $token) {return $true}
    else {
        $expireIn = [DateTime]::Parse($token.issued_at) + [TimeSpan]::FromSeconds($token.expires_in)
        if ([DateTime]::Now -ge $expireIn) { return $true }
        else {return $false}
    }
}

function GetDate
{
    param($value)
    if ($value.GetType().Name -eq "String") { $value = [DateTimeOffset]::Parse($value)}
    elseif ($value.GetType().Name -eq "DateTime") { $value = [ DateTimeOffset]$value }
    return $value
}

function GetImage 
{
    param ($constants)
    $uri = GetUri -template $hubUriTemplate -constants $constants
    $images = (Invoke-Webrequest -Method GET -Uri $uri).Content | ConvertFrom-Json
    $platformImage = $images.images | Where-Object {$_.os -eq $constants.os -and $_.architecture -eq $constants.arch}
    if ($null -eq $platformImage) {
        Write-Host ("Docker image not found for {0}/{1}" -f $constants.os, $constants.arch)
        return $null
    }
    else {
        $binDate = $images.last_updated
        Write-Host -ForegroundColor Green ("Docker updater found image {0} bytes for {1}, updated {2:yyyy.MM.dd HH:mm:ss (UTCzzz)} ({3} days ago)" -f 
            $platformImage.size, 
            ($constants.os + "/" + $constants.arch), 
            $binDate, 
            [int]([DateTimeOffset]::Now - $binDate).TotalDays
        )

        #recall old digest
        $memFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $constants.mem_file)
        $lastDigest = ""
        if ([System.IO.File]::Exists($memFile)) {
            $memLines = [System.IO.File]::ReadAllLines($memFile)
            if ($memLines.Length -gt 0) { $lastDigest = $memLines[$memLines.Length - 1] }
        }

        if (-not [String]::IsNullOrEmpty($lastDigest) -and $platformImage.digest -eq $lastDigest) {
            Write-Host "image has already been downloaded before. ignoring."
            return $null
        }
        else {
            [System.IO.File]::AppendAllLines($memFile, [string[]]$platformImage.digest)
            Write-Host ("docker image digest added to {0}" -f $memFile)
        }
        return $platformImage
    }
}

function TempDir
{
    param ($constants, $action)
    
    #base temp
    $temp_path = [System.IO.Path]::GetTempPath()
    if ($constants.ContainsKey("temp_path") -and -not [String]::IsNullOrEmpty($constants["temp_path"])) { $temp_path = $constants["temp_path"] }
    if (-not [System.IO.Directory]::Exists($temp_path)) {
        Write-Error "fail on temp directory"
        return $null
    }

    $temp_path_dir = "storj-blob";
    if ($constants.ContainsKey("temp_path_dir")) { $temp_path_dir = $constants["temp_path_dir"] }

    $temp_path_dir_fs = "fs";
    if ($constants.ContainsKey("temp_path_dir_fs")) { $temp_path_dir_fs = $constants["temp_path_dir_fs"] }

    $temp_storj = [System.IO.Path]::Combine($temp_path, $temp_path_dir)
    $temp_storj_fs=[System.IO.Path]::Combine($temp_storj, $temp_path_dir_fs)

    if (($temp_path + $temp_path_dir + $temp_storj + $temp_storj_fs).Contains("..")) { throw "bad hack"}

    if ($action -eq "create") {
        if (-not [System.IO.Directory]::Exists($temp_storj)) { New-Item -Path $temp_path -ItemType directory -Name $temp_path_dir | Out-Null } 
        if (-not [System.IO.Directory]::Exists($temp_storj_fs)) { New-Item -Path $temp_storj -ItemType directory -Name $temp_path_dir_fs | Out-Null } 

        $p = @{
            'temp_path' = $temp_path
            'temp_path_dir' = $temp_path_dir
            'temp_storj'= $temp_storj
            'temp_storj_fs'= $temp_storj_fs
        }
        return New-Object -TypeName PSCustomObject –Prop $p
    }
    elseif ($action -eq "delete") {
        if ([System.IO.Directory]::Exists($temp_storj_fs)) {Remove-Item -Path $temp_storj_fs -Force -Recurse}
        if ([System.IO.Directory]::Exists($temp_storj)) { Remove-Item -Path $temp_storj -Force -Recurse } 
    }
}

# check and write sourceBin to target
function UpdateBin 
{
    param ($sourceBin, $targetBin)
    if ([System.IO.File]::Exists($sourceBin)) {
        Write-Host "Downloaded" 
        Copy-Item $sourceBin -Destination $targetBin
        if ($null -ne $targetBin -and [System.IO.File]::Exists($targetBin)) { Write-Host ("copied to {0}" -f $targetBin) }
        else { throw "copy failed" }
        return $targetBin
    }
    else { throw "download failed" }
}

function GetCloudVersion
{
    $v = Invoke-WebRequest $versionUriTemplate | ConvertFrom-Json
    $vobj = $v.processes.storagenode.suggested
    $cursor = $v.processes.storagenode.rollout.cursor
    $vobj | Add-Member -NotePropertyName "cursor" -NotePropertyValue $cursor
    return $vobj
}

#return target platform file name with extension
function GetBinFileName
{
    param ($constants, $suffix)
    if ($null -eq $suffix) { $suffix = "" }
    if ($constants.os.ToLowerInvariant().Contains("windows")) { $name = $constants.binary_name + $suffix + ".exe" }
    else { $name = $constants.binary_name + $suffix }
    return $name
}


function GetBinFile
{
    param ($constants, $suffix)
    if ($null -eq $constants -or $null -eq $constants.target) { throw "bad params target" }
    if (-not [System.IO.Directory]::Exists($constants.target)) { throw "bad params target not exists" }

    $sourceBin = GetBinFileName -constants $constants -suffix $suffix
    $sourceBin = [System.IO.Path]::Combine($constants.target, $sourceBin)

    return $sourceBin
}

function GetBinVersion
{
    param ($file)

    $text = ExternalCommand -file $file -arguments "version"
    Write-Host ("File version {0}: " -f $file) -NoNewline
    Write-Host $text

    $vstr = ($text | Where-Object {$_.StartsWith("Version:")} | Select-Object -First 1)
    if ([String]::IsNullOrEmpty($vstr)) { throw "Can't get binary version" }

    $v = $vstr.Substring(8).Trim().TrimStart('v').Trim()
    if ([String]::IsNullOrEmpty($v)) { throw "Can't get binary version from version string" }
    return $v
}

function NativeUpdate
{
    param ($uriTemplate, $constants, $targetBin)

    #version url                                                                                     
    #0.33.4  https://github.com/storj/storj/releases/download/v0.33.4/storagenode_{os}_{arch}.exe.zip
    #        https://github.com/storj/storj/releases/download/v0.33.4/storagenode_windows_amd64.exe.zip
    $uri = GetUri -template $uriTemplate -constants $constants

    try
    {
        $temp = TempDir -constants $constants -action "create"
        $sourceZip = [System.IO.Path]::Combine($temp.temp_storj, $uri.Substring($uri.LastIndexOf("/") + 1))

        try {
            Invoke-WebRequest -Uri $uri -OutFile $sourceZip
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq "NotFound") {
                Write-Host ("Native updater not found image for {0}/{1}" -f $constants.os, $constants.arch)
                return $null
            }
            else { throw }
        }
        Write-Host -ForegroundColor Green ("Native updater found image for {0}" -f ($constants.os + "/" + $constants.arch))

        Expand-Archive -Path $sourceZip -DestinationPath $temp.temp_storj_fs

        $sourceName = GetBinFileName -constants $constants
        $sourceBin = [System.IO.Path]::Combine($temp.temp_storj_fs, $sourceName)

        if ($constants.os -eq "linux") { 
            ExternalCommand -file "chmod" -arguments ("+x", $sourceBin)
        }

        if ($null -eq $targetBin) { $targetBin = [System.IO.Path]::Combine($constants.target, $sourceName) }
        return UpdateBin -sourceBin $sourceBin -target $targetBin
    }
    finally
    {
        TempDir -constants $constants -action "delete"
    }
}

function DockerUpdate
{
    param ($token, $constants, $targetBin)

    if (IsNeedNewToken -token $token) {
        Write-Host -ForegroundColor Green "Autorization..."
        $uri = GetUri -template $authUriTemplate -constants $constants
        $token = Invoke-WebRequest -Uri $uri | ConvertFrom-Json
    }

    $uri = GetUri -template $manifestUriTemplate -constants $constants
    $manifest = Invoke-Webrequest -Headers @{Authorization="Bearer " + $token.token; Accept= "application/vnd.docker.distribution.manifest.v2+json"} -Method GET -Uri $uri | ConvertFrom-Json
    if ($null -eq $manifest -or $null -eq $manifest.layers) { throw "failed to get manifest"}

    $old = Get-Location
    try
    {
        $temp = TempDir -constants $constants -action "create"
        Set-Location $temp.temp_storj

        $manifest.layers | ForEach-Object {
            $tempfile = [System.IO.Path]::Combine($temp.temp_storj, $_.digest.Split(":")[1])
            Write-Host ("Download {0}" -f $tempfile)
            $constants["digest"] = $_.digest
            $uri = GetUri -template $blobUriTemplate -constants $constants
            Invoke-Webrequest -Headers @{Authorization="Bearer " + $token.token} -Method GET -Uri $uri -OutFile $tempfile -ErrorAction Stop | Out-Null
	        Start-Process -FilePath "tar" -ArgumentList ("-x", "-k", "-z", "-f " + $tempfile, "-C fs", "app/storagenode") -Wait -PassThru -NoNewWindow | Out-Null
        }

        $sourceBin = [System.IO.Path]::Combine($temp.temp_storj, "fs", "app", "storagenode")
        if ($null -eq $targetBin) { $targetBin = [System.IO.Path]::Combine($constants.target,"storagenode") }
        return UpdateBin -sourceBin $sourceBin -target $targetBin
    }
    finally
    {
        Set-Location $old
        TempDir -constants $constants -action "delete"
    }
}

function CompareVersion {
    param ($v1, $v2)
    if ($v1 -eq $v2) { return 0 }

    try {
        $v1int = $v1.Split('.') | ForEach-Object {[int]$_}
        $v2int = $v2.Split('.') | ForEach-Object {[int]$_}
        for ($i = 0; $i -lt ([Math]::Min($v1int.Length, $v2int.Length)); $i++ ) {
            if ($v1int[$i] -gt $v2int[$i]) { return 1 }
            elseif ($v1int[$i] -lt $v2int[$i]) { return -1 }
        }
        if ($v1int.Length -gt $v2int.Length) { return 1}
        elseif ($v2int.Length -gt $v1int.Length) { return -1}
        else { return 0 }
    }
    catch {return 0}
}


function Download 
{
    param ($constants)

    $constants.target = Get-Location
    $file = $null

    if ($constants.method -eq "native") {
        $cloud = GetCloudVersion
        $file = NativeUpdate -uriTemplate $cloud.url -constants $constants
    }
    elseif ($constants.method -eq "docker") {
        $image = GetImage -constants $constants
        if ($null -ne $image) {
            $constants.digest = $image.digest
            $file = DockerUpdate -constants $constants
        }
    }
    elseif ($constants.method -eq "auto") {
        $cloud = GetCloudVersion
        $file = NativeUpdate -uriTemplate $cloud.url -constants $constants
        if ($null -eq $file) {
            $image = GetImage -constants $constants
            if ($null -ne $image) {
                $constants.digest = $image.digest
                $file = DockerUpdate -constants $constants
            }
        }
    }
}

function CheckUpdate 
{
    param($file, $expected)
    if ([String]::IsNullOrEmpty($file)) {return $false}
    elseif (-not [System.IO.File]::Exists($file)) { return $false }

    $version = GetBinVersion -file $file
    if ((CompareVersion -v1 $version -v2 $expected) -ne 0) { 
        Write-Host ("downloaded binary have the other version than expected ({0})" -f $version)
        return $false 
    }
    return $true
}

function SystemdAction{
    param ($constants, [string[]]$services, [string]$action)
    $services | ForEach-Object {
        $service = $_
        Write-Host ("{0}ing {1}" -f $action, $service)
        ExternalCommand -file "systemctl" -arguments ($action, $service) | Out-Null
    }
}

function SystemdListServices {
    param ($constants)
    #root@ovh-arm:/etc/scripts# systemctl -o json-pretty list-units storj-node??.service --state active --plain --no-pager --no-legend
    #storj-node11.service loaded active running Storagenode-11 service
    $services = New-Object System.Collections.Specialized.StringCollection   
    $text = ExternalCommand -file "systemctl" -arguments ("list-units", $constants.service_pattern, "--state active", "--plain", "--no-pager", "--no-legend")
    $text | ForEach-Object {
        if (![String]::IsNullOrEmpty($_)) {
            $parts = $_.Split(" ")
            $services.Add($parts[0].Trim()) | Out-Null
        }
    }
    return $services
}

function Update 
{
    param ($constants)
    if (-not [System.IO.Directory]::Exists($constants.target)) { throw ("Target path {0} not exists" -f $constants.target) }
    $file = GetBinFile -constants $constants
    $localVersion = GetBinVersion -file $file
    $cloudVersion = GetCloudVersion
    Write-Host ("Cloud version is {0}, local file version is {1}" -f $cloudVersion.version, $localVersion)
    if ((CompareVersion -v1 $localVersion -v2 $cloudVersion.version) -eq 0)
    {
        Write-Host -ForegroundColor Green "Versions are equal. Exiting."
        return
    }

    if ($null -ne $cloudVersion.cursor) {
        Write-Host ("cursor: {0}" -f $cloudVersion.cursor)
        if (-not [String]::IsNullOrEmpty($constants.wait_cursor)) {
            $target_cursor = "".PadRight($cloudVersion.cursor.Length, $constants.wait_cursor);
            if ($target_cursor -ne $cloudVersion.cursor) {
                Write-Host -ForegroundColor Green "Cursor not completed. Exiting."
                return
            }
        }
    }

    $tempBin = GetBinFile -constants $constants -suffix "_temp"
    $updated = $false

    try {
        if ([System.IO.File]::Exists($tempBin)) { Remove-Item $tempBin }
        if (($constants.method -eq "native") -or ($constants.method -eq "auto")) {
            if (-not $cloudVersion.url.Contains($cloudVersion.version)) { Write-Host -ForegroundColor Red ("Bad version url {0}, ignoring native updater" -f $cloudVersion.url) }
            else {
                $file = NativeUpdate -uriTemplate $cloudVersion.url -constants $constants -targetBin $tempBin
                $updated = CheckUpdate -file $file -expected $cloudVersion.version
            }
        }

        if (-not $updated -and (($constants.method -eq "docker") -or ($constants.method -eq "auto"))) {
            $image = GetImage -constants $constants
            if ($null -ne $image) {
                $constants.digest = $image.digest
                $file = DockerUpdate -constants $constants -targetBin $tempBin
                $updated = CheckUpdate -file $file -expected $cloudVersion.version
            }
        }
    }        
    catch {
        Write-Error $_.Exception.Message
        $updated = $false
    }

    if (-not $updated)
    {
        Write-Host -ForegroundColor Red "Update failed"
        return
    }

    $services = $null
    try {
        if ($constants.systemd_integration) {
            Write-Host "Get active services"
            $services = SystemdListServices -constants $constants
            Write-Host ("Found {0} active services" -f $services.Count)

            SystemdAction -constants $constants -services $services -action "stop"
        }

        $sourceName = GetBinFileName -constants $constants
        $targetBin = [System.IO.Path]::Combine($constants.target, $sourceName) 
        if ([System.IO.File]::Exists($targetBin)) { Remove-Item $targetBin }
        Move-Item -Path $tempBin -Destination $targetBin
    }
    finally{
        if ($constants.systemd_integration -and ($null -ne $services) -and ($services.Count -gt 0)) {
            Write-Host "Starting services"
            SystemdAction -constants $constants -services $services -action "start"
        }
    }
}

#PROGRAM BODY
Preamble
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$constants = GetConstants -constants $constants -cmdlineArgs $args

if ($constants.command -eq "version") {
    Write-Host ("Script version {0}" -f $v)
    Write-Host ("System {0}/{1}" -f $constants.os, $constants.arch)
    $bin = GetBinFile -constants $constants 
    GetBinVersion -file $bin
    $cloud = GetCloudVersion
    Write-Host ("Cloud version is {0}" -f $cloud.version)
}
elseif ($constants.command -eq "download") { Download -constants $constants }
elseif ($constants.command -eq "update") { Update -constants $constants }
else{
    Write-Host "usage:"
    Write-Host "storj3updater version"
    Write-Host "storj3updater download -m [auto|docker|native]"
    Write-Host "storj3updater update -m [auto|docker|native]"
    Write-Host
    Write-Host "For automatic updates set systemd_integration to true, check service_pattern and add command to cron"
    Write-Host "cron line example for every hour updates:"
    Write-Host "`t15 * * * * /usr/bin/pwsh /etc/scripts/Storj3Updater.ps1 update 2>&1 >>/var/log/storj/updater.log"
    Write-Host "`t- Be sure to change 15 minutes to something else so as not to create peak loads on the update servers"

}

