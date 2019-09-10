#!/usr/bin/powershell
# FailoverMonitor script by Krey
# this script ping endpoints and switch gateways on specified routing tables
# script worked in special pre-configuried infrastructure 
#

$v = "0.2"

function Preamble{
    Write-Host ""
    Write-Host ("Storj3Monitor script by Krey ver {0}" -f $v)
    Write-Host "mail-to: krey@irinium.ru"
    Write-Host ""
    Write-Host -ForegroundColor Yellow "I work on beer. If you like my scripts please donate bottle of beer in STORJ or ETH to 0x7df3157909face2dd972019d590adba65d83b1d8"
    Write-Host -ForegroundColor Gray "This wallet only for beer. Only beer will be bought from this wallet."
    Write-Host -ForegroundColor Gray "I will think later how to arrange it in the form of a public contract. Now you have only my promise. Just for lulz."
    Write-Host -ForegroundColor Gray "Why should I send bootles if everything works like that ?"
    Write-Host -ForegroundColor Gray "... see TODO comments in the script body"
    Write-Host ""
}


function GetFullPath($file)
{
    # full path
    if ([System.IO.File]::Exists($file)) { return $file }

    # full path fixed
    $file2 = [System.IO.Path]::GetFullPath($file)
    if ([System.IO.File]::Exists($file2)) { return $file2 }    

    #current dir
    $file3 = [System.IO.Path]::Combine(((Get-Location).Path), $file)
    if ([System.IO.File]::Exists($file3)) { return $file3 }
    
    # from script path
    $scriptPath = ((Get-Variable MyInvocation -Scope 2).Value).InvocationName | Split-Path -Parent
    $file4 = [System.IO.Path]::Combine($scriptPath, $file)
    if ([System.IO.File]::Exists($file4)) { return $file4 }

    return $null
}


function LoadConfig{
    param ($cmdlineArgs)
    $idx = $cmdlineArgs.IndexOf("-c")
    

    if ($idx -lt 0 -or ($cmdlineArgs.Length -le ($idx + 1)) ) {
        Write-Host -ForegroundColor Red "Please specify config file"
        return $null
    }

    $argfile = $cmdlineArgs[$idx + 1]
    $file = GetFullPath -file $argfile
    if ([String]::IsNullOrEmpty($file) -or (-not [System.IO.File]::Exists($file))) {
        Write-Host -ForegroundColor Red ("config file {0} not found" -f $argfile)
        return $false
    }
    
    $config = Get-Content -Path $file | ConvertFrom-Json 
    return $config
}



function GetTables {
    param ($routeInfo)
    $i = 0
    $routeInfo | ForEach-Object {
        $i++
        $route = $_
        try {
            $rt = ParseTable -table $route.RouteTable
            $route.RouteEntry | ForEach-Object {
                $entry = $_
                if ($null -eq $entry.GatewayAddress) { $entry.GatewayAddress = $rt.GatewayAddress }
                if ($null -eq $entry.Device) { $entry.Device = $rt.Device }
                Write-Host -ForegroundColor Yellow ("Entry for {0} table {1} address {2} dev {3}" -f $route.Location, $entry.Table, $entry.GatewayAddress, $entry.Device)
            }
            return $true
        }
        catch {
            $errorMessage = $_.Exception.Message
            return $errorMessage
        }
    }
}

function ExecCommand {
    param ($path, $params, [switch]$out)
    Write-Host -foreground gray $params

    $content = $null
    if ($out) { 
	$temp = [System.IO.Path]::GetTempFileName()
	$proc = Start-Process -FilePath $path -ArgumentList $params -RedirectStandardOutput $temp -Wait -PassThru
	$content = Get-Content -Path $temp
	[System.IO.File]::Delete($temp)
	if ($proc.ExitCode -ne 0) { throw $content }
	else { return $content }
    }
    else { 
	$proc = Start-Process -FilePath $path -ArgumentList $params -Wait -PassThru
	if ($proc.ExitCode -ne 0) { return $false }
	else { return $true }
    }
}

function ParseTable {
    param ($table)

    $content = ExecCommand -path "/bin/ip" -params ("route show table {0}" -f $table) -out
    $line = $content | Where-Object {$_.StartsWith("default via")} | Select-Object -First 1 
    $matchResult = ($line -match "default via\s+(?<ip>[^\s]+)\s+dev\s+(?<dev>[^\s]+)\s")
    if (-not $matchResult) { throw "route table parse failed" }
    if ([String]::IsNullOrEmpty($Matches["ip"])) {throw "route table parse gateway address failed"}
    if ([String]::IsNullOrEmpty($Matches["dev"])) {throw "route table parse gateway device failed"}

    return @{
        Table = $table
        GatewayAddress = $Matches["ip"]
        Device = $Matches["dev"]
    }
}

function ChangeDefaultGateway {
    param ($address, $device, $table)
    $path = "/bin/ip"

    try {
        # remove old gateway
        ExecCommand -path $path -params ("route del default table {0}" -f $table)

        # add new gateway
        $params = ("route add default via {0} dev {1} table {2}" -f $address, $device, $table)
	ExecCommand -path $path -params $params
    }
    catch {
	Write-Host -ForegroundColor Red $_.Exception.Message
	throw "failed to change route"
    }
}

function ApplyRoute{
    param ($ddnsInfo, $route)
    #Authentication and Updating using a POST
    #curl "https://dyn.dns.he.net/nic/update" -d "hostname=dyn.example.com" -d "password=password" -d "myip=192.168.0.1"
    try {

        $route.RouteEntry | ForEach-Object { ChangeDefaultGateway -table $_.Table -address $_.GatewayAddress -device $_.Device }

        Write-Host -ForegroundColor Green "Post address to ddns provider"
        $responce = Invoke-WebRequest -Method Post -Uri https://dyn.dns.he.net/nic/update -Timeout 10 -Body @{
                hostname = $ddnsInfo.Hostname
                password = $ddnsInfo.Password
                myip = $route.IpAddress
        }
        if ($responce.StatusCode -ne 200) {throw ("Bad responce: {0}" -f $responce.StatusDescription) }
        else { Write-Host -ForegroundColor Green $responce.StatusDescription }

        return $true
    }
    catch {
        $errorMessage = $_.Exception.Message
        return $errorMessage
    }
}

function TestRoute{
    param ($testAddress)
    #TODO ipsets for test addresses for each connection
    $pingObj = Test-Connection -TargetName $testAddress -IPv4 -TimeoutSeconds 5 -InformationAction Ignore 6>$null
    $cntSuccess = ($pingObj.Replies | Where-Object {$_.Status -eq "Success"}).Count
    return ($cntSuccess -gt 0)
}

function Say{
    param ($buffer, $str)
    Write-Host -ForegroundColor Green $str
    $buffer.AppendLine($str) | Out-Null
}

Preamble

$config = LoadConfig -cmdlineArgs $args
if (-not $config) { return }

Write-Host "Failover monitor starting"

$currentRoute = $null
$tablesResult = GetTables -routeInfo $config.RouteInfo
if (-not $tablesResult) { 
    Write-Error "Failed to get route info"
    exit 
}
$sb = [System.Text.StringBuilder]::new()
while ($true) {
    $sb.Clear() | Out-Null
    for ($i=0; $i -lt $config.RouteInfo.Count; $i++) {
        $testRoute = $config.RouteInfo[$i]
        $routeResult = TestRoute -testAddress $testRoute.TestAddress
        if ($routeResult -ne $testRoute.RouteResult) {
	    Say -buffer $sb -str ("{0:yyyy-MM-dd HH:mm:ss} Route {1}-{2} state changed from {3} to {4}" -f [DateTimeOffset]::Now, $testRoute.Location, $testRoute.Provider, $testRoute.RouteResult, $routeResult)
            $testRoute.RouteResult = $routeResult
        }
    }

    #Debug
    #$routeInfo[0].RouteResult = $false

    $nextRoute = ($config.RouteInfo | Where-Object {$_.RouteResult} | Select-Object -First 1)
    if ($null -eq $nextRoute) {
        Write-Host -ForegroundColor Green "No working routes"
    }
    elseif ($config.RouteInfo.IndexOf($nextRoute) -ne $config.RouteInfo.IndexOf($currentRoute)) {
        if ($null -eq $currentRoute){
           Say -buffer $sb -str ("Setting initial route to {0}-{1}" -f $nextRoute.Location, $nextRoute.Provider)
        }
        else {
            Say -buffer $sb -str ("Changing route from {0}-{1} to {2}-{3}" -f $currentRoute.Location, $currentRoute.Provider, $nextRoute.Location, $nextRoute.Provider)
        }
        $applyResult = ApplyRoute -ddnsInfo $ddnsInfo -route $nextRoute
        if ($applyResult) { 
            $currentRoute = $nextRoute 
            Say -buffer $sb -str "Succesefull apply route"
        }
        else {
            Say -buffer $sb -str $applyResult
        }
    }
    #else { Write-Host -ForegroundColor Green "No changes in routes" }

    Start-Sleep -Seconds 300
}


