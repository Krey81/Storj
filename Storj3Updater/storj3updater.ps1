# Storj3Updater script by Krey (krey@irinium.ru)
# this script download storagenode binary from two sources
# 1. From links provided by version.storj.io
# 2. From docker storagenode docker images on hub.docker.com
# https://github.com/Krey81/Storj

$v = "0.1"

# Changes:
# v0.1    - 20200304 Initial version. Download only (no update and service start\stop).


$constants = @{
    #target dir for update only (download command write file to current directory)
    target = "/usr/sbin"
    os = ""
    arch = ""
    image = "storjlabs/storagenode";
    tag="beta";
    digest="";
    temp_path="";
    temp_path_dir="storj-blob";
    temp_path_dir_fs="fs";
    binary_name="storagenode"
    command="";
    method="auto"
}

# uri templates for external API queries
$hubUriTemplate= "https://hub.docker.com/v2/repositories/{image}/tags/{tag}"
$authUriTemplate = "https://auth.docker.io/token?service=registry.docker.io&scope=repository:{image}:pull"
$manifestUriTemplate = "https://registry-1.docker.io/v2/{image}/manifests/{digest}"
$blobUriTemplate = "https://registry-1.docker.io/v2/{image}/blobs/{digest}"
$versionUriTemplate = "https://version.storj.io"

# END OF INPUT PARAMS ------------------------------------------------------

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
}

function GetConstants {
    param($constants, $cmdlineArgs)
    Set-Os -constants $constants

    if ([String]::IsNullOrEmpty($constants.arch)) { $constants.arch = $env:PROCESSOR_ARCHITECTURE }
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
        Write-Host -ForegroundColor Green ("Docker updater found image {0} bytes for {1}, updated {2} ({3} days ago)" -f 
            $platformImage.size, 
            ($constants.os + "/" + $constants.arch), 
            $images.last_updated, 
            [int]([DateTimeOffset]::Now - [DateTimeOffset]::Parse($images.last_updated)).TotalDays
        )
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
    param ($sourceBin, $target)
    if ([System.IO.File]::Exists($sourceBin)) {
        Write-Host "Downloaded" 
        $targetBin = $null
        try
        {
            $name = [System.IO.Path]::GetFileName($sourceBin)
            $targetBin = [System.IO.Path]::Combine($target, $name)
            Copy-Item $sourceBin -Destination $targetBin
        }
        catch 
        {
            $targetBin = [System.IO.Path]::Combine($target, "storagenode.new")
            Copy-Item $sourceBin -Destination $targetBin
        }
        if ($null -ne $targetBin -and [System.IO.File]::Exists($targetBin)) { Write-Host ("copied to {0}" -f $targetBin) }
        else { throw "copy failed" }
        return $targetBin
    }
    else { throw "download failed" }
}

function GetCloudVersion
{
    $v = Invoke-WebRequest $versionUriTemplate | ConvertFrom-Json
    return $v.processes.storagenode.suggested
}

#return target platform file name with extension
function GetBinFileName
{
    param ($constants)
    if ($constants["os"].Contains("windows")) { $name = $constants.binary_name + ".exe" }
    else { $name = $constants.binary_name }
    return $name
}


function GetBinFile
{
    param ($constants)
    if ($null -eq $constants -or $null -eq $constants.target) { throw "bad params target" }
    if (-not [System.IO.Directory]::Exists($constants.target)) { throw "bad params target not exists" }

    $sourceBin = GetBinFileName -constants $constants
    $sourceBin = [System.IO.Path]::Combine($constants.target, $sourceBin)


    if (-not [System.IO.File]::Exists($sourceBin)) { throw ("bad params target file {0} not exists" -f $sourceBin) }
    return $sourceBin
}



function GetBinVersion
{
    param ($file)
    $temp = $null
    try
    {
        $temp = [System.IO.Path]::GetTempFileName()
        $p = Start-Process -FilePath $file -ArgumentList "version" -Wait -PassThru -NoNewWindow -RedirectStandardOutput $temp
        if (($p.ExitCode -ne 0) -or (-not [System.IO.File]::Exists($temp))) { throw "Bad binary" }

        $text = [System.IO.File]::ReadAllLines($temp)
        Write-Host ("File version {0}: " -f $file) -NoNewline
        Write-Host $text

        $vstr = ($text | Where-Object {$_.StartsWith("Version:")} | Select-Object -First 1)
        if ([String]::IsNullOrEmpty($vstr)) { throw "Can't get binary version" }

        $v = $vstr.Substring(8).Trim().TrimStart('v').Trim()
        if ([String]::IsNullOrEmpty($v)) { throw "Can't get binary version from version string" }
        return $v

    }
    finally
    {
        if ($null -ne $temp -and [System.IO.File]::Exists($temp)) { Remove-Item $temp}
    }
   
}

function NativeUpdate
{
    param ($uriTemplate, $constants)

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
        catch [System.Net.WebException] {
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

        return UpdateBin -sourceBin $sourceBin -target $constants.target
    }
    finally
    {
        TempDir -constants $constants -action "delete"
    }
}

function DockerUpdate
{
    param ($token, $constants)

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
            Invoke-Webrequest -Headers @{Authorization="Bearer " + $token.token} -Method GET -Uri $uri -OutFile $tempfile -ErrorAction Stop
	        Start-Process -FilePath "tar" -ArgumentList ("-x", "-k", "-z", "-f " + $tempfile, "-C fs", "app/storagenode") -Wait -PassThru -NoNewWindow
        }

        $sourceBin = [System.IO.Path]::Combine($temp.temp_storj, "fs", "app", "storagenode")
        return UpdateBin -sourceBin $sourceBin -target $constants.target
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

function Update 
{
    param ($constants)
    if (-not [System.IO.Directory]::Exists($constants.target)) { throw ("Target path {0} not exists" -f $constants.target) }
    $file = GetBinFile -constants $constants
    $localVersion = GetBinVersion -file $file
    $cloudVersion = GetCloudVersion
    Write-Host ("Cloud version is {0}, local file version is {1}" -f $cloudVersion.version, $localVersion)
    if ((CompareVersion -v1 $localVersion -v2 $cloudVersion) -eq 0)
    {
        Write-Host -ForegroundColor Green "Versions are equal. Exiting."
        return
    }

    if (($constants.method -eq "native") -or ($constants.method -eq "auto")) {
        $file = NativeUpdate -uriTemplate $cloudVersion.url -constants $constants
        if (-not [String]::IsNullOrEmpty($file))
        {
            Write-Host -ForegroundColor Green "Updated"
            return
        }
    }

    if (($constants.method -eq "docker") -or ($constants.method -eq "auto")) {
        $image = GetImage -constants $constants
        if ($null -ne $image) {
            $constants.digest = $image.digest
            $file = DockerUpdate -constants $constants
            if (-not [String]::IsNullOrEmpty($file))
            {
                Write-Host -ForegroundColor Green "Updated"
                return
            }
        }
    }

    Write-Host -ForegroundColor Red "Update failed"
}

#PROGRAM BODY
Preamble
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$constants = GetConstants -constants $constants -cmdlineArgs $args
if ($constants.command -eq "version") {
    Write-Host ("Script version {0}" -f $v)
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
}

