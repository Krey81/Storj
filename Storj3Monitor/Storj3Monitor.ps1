# Storj3Monitor script by Krey
# this script gathers, aggregate displays and monitor all you node thresholds
# if uptime or audit down by [threshold] script send email to you
# https://github.com/Krey81/Storj

$v = "0.3"

# Changes:
# v0.0    - 20190828 Initial version, only displays data
# v0.1    - 20190904 
#           Add monitoring 
#               -   lost node connection
#               -   outdate storj version
#               -   new satellite
#               -   audit score
#               -   uptime score
#               -   Warrant canary
#           Add mail senders
#               -   for windows & linux internal powershell mail agent
#               -   for linux via bash -c "cat | mail"
# v0.2    - 20190904 
#               -   Remove [ref] for string buffer
#               -   Move config to external file
# v0.3    - 20190910
#               -   Add warning on new wallet
#               -   Fix usage examples in script
#               -   Fix config path search routines
#               -   Add testmail command
#               -   Add config examples

#TODO-Drink-and-cheers
#               -   Early bird (1-bottle first), greatings for all versions of this script
#               -   Big thanks (10-bottles first), greatings for all versions of this script
#               -   Telegram bot (100-bottles, sum), development telegtam bot to send messages
#               -   The service (1000-bottles, sum), full time service for current and past functions on my dedicated servers
#               -   The world's fist barter crypto-currency (1M [1kk for Russians], sum). You and I will create the world's first cryptocurrency, which is really worth something.

#TODO
#               -   MQTT
#
#

#USAGE          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#RUN
#   Display only with default config: one node on 127.0.0.1:14002, no monitoring and mail
#       pwsh ./Storj3Monitor.ps1
#
#
#   Display only for specefied nodes
#       pwsh ./Storj3Monitor.ps1 -c <config-file>
#
#
#   Test config and mail sender
#       pwsh ./Storj3Monitor.ps1 -c <config-file> testmail
#
#
#   Monitor and mail
#       pwsh ./Storj3Monitor.ps1 -c <config-file> monitor
#
#
#   Dump default config to stdout
#       pwsh ./Storj3Monitor.ps1 example
#       also see config examples on github 
#
#   Full installation
#       1. Create config, specify all nodes and mailer configuration. Examples on github.
#       2. Create systemd service specify path to this script and configuration. Examples on github.
#


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

function DefaultConfig{
    $config = @{
        Nodes = "127.0.0.1:14002"
        WaitSeconds = 300
        Threshold = 0.2
        Mail = @{
            MailAgent = "none"
        }
    }
    return $config
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
        Write-Host "Example: Storj3Monitor.ps1 -c Storj3Monitor.conf"

        Write-Host
        Write-Host -ForegroundColor Red "No config was specified. Use defaults."
        Write-Host "Run 'Storj3Monitor.ps1 example' to retrieve default config"
        $config = DefaultConfig        
        return $config
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


function GetJson
{
    param($uri)

    #RAW
    # ((Invoke-WebRequest -Uri http://192.168.156.4:4404/api/dashboard).content | ConvertFrom-Json).data

    $resp = Invoke-WebRequest -Uri $uri
    if ($resp.StatusCode -ne 200) { throw $resp.StatusDescription }
    $json = ConvertFrom-Json $resp.Content
    if (-not [System.String]::IsNullOrEmpty($json.Error)) { throw $json.Error }
    else { $json = $json.data }
    return $json
}

function GetNodes
{
    param ($config)
    $result = [System.Collections.Generic.List[PSCustomObject]]@()
    
    $config.Nodes | ForEach-Object {
        $address = $_
        try {
            $dash = GetJson -uri ("http://{0}/api/dashboard" -f $address)
            $dash | Add-Member -NotePropertyName Sat -NotePropertyValue ([System.Collections.Generic.List[PSCustomObject]]@())

            $dash.satellites | ForEach-Object {
                $satid = $_
                try {
                    $sat = GetJson -uri ("http://{0}/api/satellite/{1}" -f $address, $satid)
                    $dash.Sat.Add($sat)
                }
                catch {
                    Write-Host -ForegroundColor Red ("Node on address {0} fail sat {1}: {2}" -f $address, $satid, $_.Exception.Message )        
                }
            }
            $result.Add($dash)
        }
        catch {
            Write-Host -ForegroundColor Red ("Node on address {0} fail: {1}" -f $address, $_.Exception.Message )
        }
    }
    return $result
}

function GetScore
{
    param($nodes)
    #$result = [System.Collections.Generic.List[PSObject]]@()
    $nodes | Sort-Object nodeID | ForEach-Object {
        $node = $_
        $node.Sat | Sort-Object id | ForEach-Object {
            $sat = $_
            New-Object PSCustomObject -Property @{
                Key = ("{0}-{1}" -f $node.nodeID, $sat.id)
                NodeId = $node.nodeID
                SatelliteId = $sat.id
                Audit = $sat.audit.score
                Uptime = $sat.uptime.score
                Ingress = $sat.bandwidthDaily.ingress.repair + $sat.bandwidthDaily.ingress.usage
                Egress = $sat.bandwidthDaily.egress.repair + $sat.bandwidthDaily.egress.usage
            }
        }
    }
}
function Compact
{
    param($id)
    return $id.Substring(0,4) + "-" + $id.Substring($id.Length-2)
}

function Round
{
    param($value)
    return [Math]::Round($value * 100, 2)
}

function HumanBytes {
    param ([int64]$bytes)
    $suff = "bytes", "KiB", "MiB", "GiB", "TiB", "PiB"
    $level = 0
    $rest = [double]$bytes
    while ([Math]::Abs($rest/1024) -ge 1) {
        $level++
        $rest = $rest/1024
    }
    $mant = [Math]::Max(3 - [Math]::Floor($rest).ToString().Length,0)
    return ("{0} {1}" -f [Math]::Round($rest,$mant), $suff[$level])
}

function Out-Buffer {
    param ($sb, $msg)
    $sb.AppendLine($msg) | Out-Null
    Write-Host $msg
}

function CheckNodes{
    param(
        $config, 
        $sb,
        [ref]$oldNodesRef
    )
    $oldNodes = $oldNodesRef.Value
    ;
    $newNodes = GetNodes -config $config

    #DEBUG drop some satellites and reset update
    #$newNodes = $newNodes | Select-Object -First 2
    #$newNodes[1].upToDate = $false

    # Check absent nodes
    $failNodes = ($oldNodes | Where-Object { ($newNodes | Select-Object -ExpandProperty nodeID) -notcontains $_.nodeID })
    if ($failNodes.Count -gt 0) {
        $failNodes | ForEach-Object {
            Out-Buffer -sb ($sb) -msg ("Disconnected from node {0}" -f $_.nodeID)
        }
    }

    ;
    # Check versions
    $oldVersion = ($newNodes | Where-Object {-not $_.upToDate})
    if ($oldVersion.Count -gt 0) {
        $oldVersion | ForEach-Object {
            $testNode = $_
            $oldVersionStatus = $oldNodes | Where-Object { $_.nodeID -eq $testNode.nodeID } | Select-Object -First 1 -ExpandProperty upToDate
            if ($oldVersionStatus) {
                Out-Buffer -sb ($sb) -msg ("Node {0} is old ({1}.{2}.{3})" -f $testNode.nodeID, $testNode.version.major, $testNode.version.minor, $testNode.version.patch)
            }
        }
    }
    
    # Check new wallets
    $oldWal = $oldNodes | Select-Object -ExpandProperty wallet -Unique
    $newWal = $newNodes | Select-Object -ExpandProperty wallet -Unique | Where-Object {$oldWal -notcontains $_ }
    if ($newWal.Count -gt 0) {
        $newWal | ForEach-Object {
            Out-Buffer -sb $sb -msg ("!WARNING! NEW WALLET {0}" -f $_)
        }
    }


    # Check new satellites
    $oldSat = $oldNodes.satellites | Select-Object -Unique

    #DEBUG drop some satellites
    #$oldSat = $oldSat | Sort-Object | Select-Object -First 2

    $newSat = $newNodes.satellites | Select-Object -Unique | Where-Object {$oldSat -notcontains $_ }
    if ($newSat.Count -gt 0) {
        $newSat | ForEach-Object {
            Out-Buffer -sb $sb -msg ("New satellite {0}" -f $_)
        }
    }

    $oldNodesRef.Value = $newNodes
}

function CheckScore{
    param(
        $config, 
        $sb,
        $nodes,
        $oldScore
    )
    $newScore = GetScore -nodes $nodes

    #DEBUG drop scores
    #$newScore[0].Audit = 0.2
    #$newScore[3].Uptime = 0.6

    $newScore | ForEach-Object {
        $new = $_
        $old = $oldScore | Where-Object { $_.Key -eq $new.Key }
        if ($null -ne $old){
            $idx = $oldScore.IndexOf($old)
            if ($old.Audit -ge ($new.Audit + $config.Threshold)) {
                Out-Buffer -sb ($sb) -msg ("Node {0} down audit from {1} to {2} on {3}" -f $new.nodeID, $old.Audit, $new.Audit, $new.SatelliteId)
                $oldScore[$idx].Audit = $new.Audit
            }
            elseif ($new.Audit -gt $old.Audit) { $oldScore[$idx].Audit = $new.Audit }

            if ($old.Uptime -ge ($new.Uptime + $config.Threshold)) {
                Out-Buffer -sb ($sb) -msg ("Node {0} down uptime from {1} to {2} on {3}" -f $new.nodeID, $old.Uptime, $new.Uptime, $new.SatelliteId)
                $oldScore[$idx].Uptime = $new.Uptime
            }
            elseif ($new.Uptime -gt $old.Uptime) { $oldScore[$idx].Uptime = $new.Uptime }
        }
    }
}


function ExecCommand {
    param ($path, $params, [switch]$out)

    $content = $null
    if ($out) { 
    $temp = [System.IO.Path]::GetTempFileName()
    #Write-Host ("Exec {0} {1}" -f $path, $params)
    #Write-Host ("Output redirected to {0}" -f $temp)
    $proc = Start-Process -FilePath $path -ArgumentList $params -RedirectStandardOutput $temp -Wait -PassThru
    #Write-Host done
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

function SendMailLinux{
    param(
        $config, 
        $sb
    )

    ;
    $body = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($body, $sb.ToString())

        $catParam = "'{0}'" -f $body
        $mailParam = "-s '{0}' {1}" -f $config.Mail.Subj, $config.Mail.To
        $bashParam = ('-c "cat {0} | mail {1}"' -f $catParam, $mailParam)
        $output = ExecCommand -path $config.Mail.Path -params $bashParam -out

        Write-Host ("Mail sent to {0} via linux agent" -f $config.Mail.To)
        if ($output.Length -gt 0) { Write-Host $output }
        $sb.Clear() | Out-Null
        Write-Host "Buffer cleared"
    }
    catch {
        Write-Host -ForegroundColor Red ($_.Exception.Message)        
    }
    finally {
        try {
            #if ([System.IO.File]::Exists($body)) { [System.IO.File]::Delete($body) }    
        }
        catch { }
    }

}

function SendMailPowershell{
    param(
        $config, 
        $sb
    )
    try {
        $pd = $config.Mail.AuthPass | ConvertTo-SecureString -asPlainText -Force

        if ([String]::IsNullOrEmpty($config.Mail.AuthUser)) { $user = $config.Mail.From }
        else { $user = $config.Mail.AuthUser }

        $credential = New-Object System.Management.Automation.PSCredential($user, $pd)

        $ssl = $true
        if ($config.Mail.Port -eq 25) { $ssl = $false }

        try {
            Send-MailMessage  `
                -To ($config.Mail.To) `
                -From ($config.Mail.From) `
                -Subject ($config.Mail.Subj) `
                -Body ($sb.ToString()) `
                -UseSsl: $ssl `
                -SmtpServer ($config.Mail.Smtp) `
                -Port ($config.Mail.Port) `
                -Credential $credential `
                -ErrorAction Stop
            
            Write-Host ("Mail sent to {0} via powershell agent" -f $config.Mail.To)
            $sb.Clear() | Out-Null
            Write-Host "Buffer cleared"
        }
        catch 
        {

            if ($config.Mail.From -match "gmail.com") { $msg = ("google is bad mail sender. try other service: {0}" -f $_.Exception.Message) }
            else { $msg = ("Bad mail sender or something wrong in mail config: {0}" -f $_.Exception.Message) }
            throw $msg
        }
    }
    catch {
        Write-Host -ForegroundColor Red ($_.Exception.Message)
    }

}

#SendMail -config $config -sb (sb)
function SendMail{
    param(
        $config, 
        $sb
    )

    if ($null -eq $config.Mail -or $config.Mail.MailAgent -eq "none") { 
        $sb.Clear() | Out-Null
    }
    elseif ($config.Mail.MailAgent -eq "powershell") { SendMailPowershell -config $config -sb $sb }
    elseif ($config.Mail.MailAgent -eq "linux") { SendMailLinux -config $config -sb $sb }
    else {
        Write-Host -ForegroundColor Red "Mail not properly configuried"
    }
}

function Monitor {
    param (
        $config, 
        $sb, 
        $oldNodes,
        $oldScore
    )

    while ($true) {
        Start-Sleep -Seconds $config.WaitSeconds
        CheckNodes -config $config -sb $sb -oldNodesRef ([ref]$oldNodes)
        CheckScore -config $config -sb $sb -nodes $oldNodes -oldScore $oldScore

        ;
        if ([System.DateTimeOffset]::Now.Day -ne $config.Canary.Day -and [System.DateTimeOffset]::Now.Hour -gt 9) {
            $config.Canary = [System.DateTimeOffset]::Now
            Out-Buffer -sb $sb -msg ("i'am alive {0}" -f $config.Canary)
        }

        if ($sb.Length -gt 0) { SendMail -config $config -sb $sb }
    }
    Write-Host "Stop monitoring"
}

Preamble
if ($args.Contains("example")) {
    $config = DefaultConfig
    $config | ConvertTo-Json
    return
}

$config = LoadConfig -cmdlineArgs $args
if (-not $config) { return }

$config | Add-Member -NotePropertyName StartTime -NotePropertyValue ([System.DateTimeOffset]::Now)
$config | Add-Member -NotePropertyName Canary -NotePropertyValue $config.StartTime

#DEBUG check Canary
#$config.Canary = [System.DateTimeOffset]::Now.Subtract([System.TimeSpan]::FromDays(1))

$nodes = GetNodes -config $config
$score = GetScore -nodes $nodes
$tab = $score | Sort-Object SatelliteId, NodeId | Format-Table `
    @{n='Satellite';e={Compact($_.SatelliteId)}}, `
    @{n='Node';e={Compact($_.NodeId)}}, `
    @{n='Ingress';e={HumanBytes($_.Ingress)}}, `
    @{n='Egress';e={HumanBytes($_.Egress)}}, `
    @{n='Audit';e={Round($_.Audit)}}, `
    @{n='Uptime';e={Round($_.Uptime)}}

if ($args.Contains("monitor")) {
    [System.Text.StringBuilder]$sb = [System.Text.StringBuilder]::new()
    $sb.AppendLine(("Start monitoring {0} entries at {1}, {2} seconds cycle" -f $score.Count, $config.StartTime, $config.WaitSeconds)) | Out-Null
    $sb.Append(($tab | Out-String)) | Out-Null
    $sb.ToString()

    Monitor -config $config -sb $sb -oldNodes $nodes -oldScore $score
}
if ($args.Contains("testmail")) {
    [System.Text.StringBuilder]$sb = [System.Text.StringBuilder]::new()
    $sb.AppendLine("Test mail. Configured {0} entries" -f $score.Count) | Out-Null
    $sb.Append(($tab | Out-String)) | Out-Null
    SendMail -config $config -sb $sb
}
else {
    $tab
}

#END OF SCRIPT Storj3Monitor.ps1 mail to krey@irinium.ru

#END OF SCRIPT Storj3Monitor.ps1 mail to krey@irinium.ru

#/etc/systemd/system/Storj3Monitor.service
#[Unit]
#Description=Storj v3 monitor by Krey
##Requires=network.target
#After=network-online.target
#Wants=network-online.target
#
#[Service]
#Type=simple
#ExecStart=/usr/bin/pwsh /etc/scripts/Storj3Monitor.ps1 -c /etc/scripts/Storj3Monitor.conf monitor #edit path
#ExecStop=/bin/kill --signal SIGINT ${MAINPID}
#
#[Install]
#WantedBy=multi-user.target
