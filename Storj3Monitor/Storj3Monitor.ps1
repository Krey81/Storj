# Storj3Monitor script by Krey
# this script gathers, aggregate displays and monitor all you node thresholds
# if uptime or audit down by [threshold] script send email to you
# https://github.com/Krey81/Storj

$v = "0.6.3"

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
# v0.4    - 20190919                            - [5 bottles withdraw]
#               -   Changes due new api 0.21.1
#               -   Add node summary
#               -   Add satellite graphs
#               -   Add pips
#               -   Add delete counter
#               -   Add wellknown satellite names in script
#               -   Add wallknow node names (your nodes) in config (please check updated examples)
#               -   Add last ping (older last contact) formated like d:h:m:s
# v0.4.1   - 20190920
#               -   fix for "new satellite" mails, thanks LordMerlin
#               -   replace some in-script symbols and pseudographics symbols with byte array for workaround bad text editors, change encoding to UTF-8 with BOM, thanks underflow17
# v0.4.2   - 20191010
#               -   storj api changes
#               -   Totals
#               -   score counters month based
# v0.4.3   - 20191018
#               -   add per-node info (satellite data grouped by nodes) - ingress, egress, audit, uptime
#               -   change sat and node output order
#               -   extended output in canopy warning
#               -   misc
# v0.4.4   - 20191113
#               -   reorder columns in nodes summary, add disk used column
#               -   revised graph design
#               -   add egress and ingress cmdline params
#               -   traffic daily graph
# v0.4.5   - 20191114
#               -   fix int32 overwlow, fix div by zero 
# v0.5     - 20191115 (first anniversary version)
#               -   revised pips
#               -   powershell 5 (default in win10) compatibility
#               -   fix some bugs 
# v0.5.1   - 20191115
#               -   fix last ping issue from win nodes
#               -   add last ping monitoring, config value LastPingWarningMinutes, default 30
# v0.5.2   - 20191119
#               -   add -d param; -d only current day, -d -10 current-10 day, -d 3 last 3 days
#               -   send mail when last ping restored
# v0.5.3   - 20191120
#               -   add nodes count to timeline caption
# v0.5.4   - 20191121
#               -   group nodes by version in nodes summary
# v0.6.0   - 20191122
#               -   compare node version with version.storj.io
#                   -- Thanks "STORJ Russian Chat" members Sans Kokor to attention and Vladislav Solovei for suggestion.
# v0.6.1   - 20191126
#               -   Output disqualified field value in Comment
#               -   Mail when Comment changed
#               -   Max egress node show in footer
#               -   Max ingress and egress show below timeline graph
#               -   Fixes for windows powershell
#               -   html monospace mails
# v0.6.2   - 20191128
#               -   add statellite url
#               -   add total bandwidth to timeline footer
#               -   add averages to egress, ingress and bandwidth in timeline footer
#               -   add -node cmdline parameter for filter output to specific node
#               -   fix temp file not exists error
# v0.6.3   - 20191129
#               -   change output in nodes summary footer
#               -   fix max ingress value in nodes summary footer, thanks Sans Konor

#TODO-Drink-and-cheers
#               -   Early bird (1-bottle first), greatings for all versions of this script
#               -   Big thanks (10-bottles first), greatings for all versions of this script
#               -   Telegram bot (100-bottles, sum), development telegram bot to send messages
#               -   The service (1000-bottles, sum), full time service for current and past functions on my dedicated servers
#               -   The world's fist bottle-based crypto-currency (1M [1kk for Russians], sum). You and I will create the world's first cryptocurrency, which is really worth something.

#TODO
#               -   MQTT
#               -   SVG graphics
#               -   Script autoupdating

#USAGE          !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#RUN
#   Display only with default config: one node on 127.0.0.1:14002, no monitoring and mail
#       pwsh ./Storj3Monitor.ps1
#
#
#   Display only for specefied nodes
#       pwsh ./Storj3Monitor.ps1 -c <config-file> [ingress|egress] [-node name]
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

$wellKnownSat = @{
    "118UWpMCHzs6CvSgWd9BfFVjw5K9pZbJjkfZJexMtSkmKxvvAW" = "stefan-benten";
    "12EayRS2V1kEsWESU9QMRseFhdxYxKicsiFmxrsLZHeLUtdps3S" = "us-central-1";
    "121RTSDpyNZVcEU84Ticf2L1ntiuUimbWgfATz21tuvgk3vzoA6" = "asia-east-1";
    "12L9ZFwhzVpuEKMUNUqkaTLGzwY9G24tbiigLiXpmZWKwmcNDDs" = "europe-west-1"
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
    Write-Host -NoNewline ("Storj3Monitor script by Krey ver {0}" -f $v)
    if (IsAnniversaryVersion($v)) { Write-Host -ForegroundColor Green "`t- Anniversary version: Astrologers proclaim the week of incredible bottled income" }
    else { Write-Host }
    Write-Host "mail-to: krey@irinium.ru"
    Write-Host ""
    Write-Host -ForegroundColor Yellow "I work on beer. If you like my scripts please donate bottle of beer in STORJ or ETH to 0x7df3157909face2dd972019d590adba65d83b1d8"
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
    }
    else {
        $argfile = $cmdlineArgs[$idx + 1]
        $file = GetFullPath -file $argfile
        if ([String]::IsNullOrEmpty($file) -or (-not [System.IO.File]::Exists($file))) {
            Write-Host -ForegroundColor Red ("config file {0} not found" -f $argfile)
            return $false
        }
        
        $config = Get-Content -Path $file | ConvertFrom-Json
    }

    $config | Add-Member -NotePropertyName StartTime -NotePropertyValue ([System.DateTimeOffset]::Now)
    $config | Add-Member -NotePropertyName Canary -NotePropertyValue $null
    
    if ($null -eq $config.LastPingWarningMinutes) { 
        $config | Add-Member -NotePropertyName LastPingWarningMinutes -NotePropertyValue 30
    }

    return $config
}

function GetJson
{
    param($uri)

    #RAW
    # ((Invoke-WebRequest -Uri http://192.168.156.204:4404/api/dashboard).content | ConvertFrom-Json).data
    # ((Invoke-WebRequest -Uri http://192.168.156.204:4404/api/satellite/118UWpMCHzs6CvSgWd9BfFVjw5K9pZbJjkfZJexMtSkmKxvvAW).content | ConvertFrom-Json).data

    $resp = Invoke-WebRequest -Uri $uri -TimeoutSec 5
    if ($resp.StatusCode -ne 200) { throw $resp.StatusDescription }
    $json = ConvertFrom-Json $resp.Content
    if (-not [System.String]::IsNullOrEmpty($json.Error)) { throw $json.Error }
    else { $json = $json.data }
    return $json
}

# For powershell v5 compatibility
function FixDateSat {
    param($sat)
    for ($i=0; $i -lt $sat.bandwidthDaily.Length; $i++) {
        $sat.bandwidthDaily[$i].intervalStart = [DateTimeOffset]$sat.bandwidthDaily[$i].intervalStart
    }
}

function FixNode {
    param($node)
    try {
        if ($node.lastPinged.GetType().Name -eq "String") { $node.lastPinged = [DateTimeOffset]::Parse($node.lastPinged)}
        elseif ($node.lastPinged.GetType().Name -eq "DateTime") { $node.lastPinged = [DateTimeOffset]$node.lastPinged }
    }
    catch { Write-Host -ForegroundColor Red $_.Exception.Message }
}

function FilterBandwidth {
    param ($bw, $query)
    if ($null -eq $query.Days) { return $bw }
    elseif ($query.Days -le 0) {
        $is = ($bw[$bw.Count - 1 + $query.Days]).IntervalStart
        return $bw | Where-Object { ($_.IntervalStart.Year -eq $is.Year) -and ($_.IntervalStart.Month -eq $is.Month) -and ($_.IntervalStart.Day -eq $is.Day) }
    }
    elseif ($query.Days -gt 0) {
        $is = ($bw[$bw.Count - 1]).IntervalStart
        $from = ($bw[$bw.Count - $query.Days]).IntervalStart.Day
        $to = $is.Day
        return $bw | Where-Object { 
            ($_.IntervalStart.Year -eq $is.Year) -and 
            ($_.IntervalStart.Month -eq $is.Month) -and 
            ($_.IntervalStart.Day -ge $from) -and
            ($_.IntervalStart.Day -le $to)
        }
    }
}

function GetNodes
{
    param ($config, $query)
    $result = [System.Collections.Generic.List[PSCustomObject]]@()
    
    #Start get storj services versions
    $jobName = "StorjVersionQuery"
    $address = "https://version.storj.io"
    $timeout = 5

    $job = Get-Job -Name $jobName -ErrorAction Ignore | Select-Object -First 1
    if ($null -eq $job) {
        Write-Host ("Send version query to {0}" -f $address)
        Start-Job -Name $jobName -ScriptBlock {(Invoke-WebRequest -Uri $args[0]).Content | ConvertFrom-Json } -ArgumentList $address | Out-Null
    }
    elseif ($job.State -eq "Running") { Write-Host "version query still executed" }
    elseif ($job.State -eq "Completed") { Write-Host "Got version info" }
    else { Write-Host ("{0} in state {1}" -f $jobName, $job.State) }
    
    $config.Nodes | ForEach-Object {
        $address = $_
        try {
            $dash = GetJson -uri ("http://{0}/api/dashboard" -f $address)
            $name = GetNodeName -config $config -id $dash.nodeID
            if ($null -ne $query.Node) {
                if (-not ($name -match $query.Node)) { return }
            }

            FixNode($dash)
            $dash | Add-Member -NotePropertyName Address -NotePropertyValue $address
            $dash | Add-Member -NotePropertyName Name -NotePropertyValue $name
            $dash | Add-Member -NotePropertyName Sat -NotePropertyValue ([System.Collections.Generic.List[PSCustomObject]]@())
            $dash | Add-Member -NotePropertyName BwSummary -NotePropertyValue $null
            $dash | Add-Member -NotePropertyName Audit -NotePropertyValue $null
            $dash | Add-Member -NotePropertyName Uptime -NotePropertyValue $null
            $dash | Add-Member -NotePropertyName LastPingWarningValue -NotePropertyValue 0
            $dash | Add-Member -NotePropertyName LastVersion -NotePropertyValue $null
            $dash | Add-Member -NotePropertyName MinimalVersion -NotePropertyValue $null
            $dash | Add-Member -NotePropertyName LastVerWarningValue -NotePropertyValue $null

            $dash.satellites | ForEach-Object {
                $satid = $_.id
                try {
                    $sat = GetJson -uri ("http://{0}/api/satellite/{1}" -f $address, $satid)
                    if ($sat.bandwidthDaily.Length -gt 0) {
                        if ($sat.bandwidthDaily[0].intervalStart.GetType().Name -eq "String") { FixDateSat -sat $sat }
                        $sat.bandwidthDaily = FilterBandwidth -bw $sat.bandwidthDaily -query $query
                    }
                    $sat | Add-Member -NotePropertyName Url -NotePropertyValue ($_.url)
                    $sat | Add-Member -NotePropertyName Dq -NotePropertyValue ($_.disqualified)
                    $dash.Sat.Add($sat)
                }
                catch {
                    Write-Host -ForegroundColor Red ("Node on address {0} fail sat {1}: {2}" -f $address, $satid, $_.Exception.Message )        
                }
            }
            $dash.PSObject.Properties.Remove('satellites')            
            $result.Add($dash)
        }
        catch {
            Write-Host -ForegroundColor Red ("Node on address {0} fail: {1}" -f $address, $_.Exception.Message )
        }
    }

    if ($null -eq $job) {
        #wait 5 seconds
        Write-Host ("Wait version no more than {0} seconds" -f $timeout)
        $job = Wait-Job -Name $jobName -Timeout $timeout
    }

    if (($null -ne $job) -and ($job.State -eq "Completed")) {
        $satVer = (Receive-Job -Job $job)
        Remove-Job -Job $job
        if ($null -ne $satVer) {
            Write-Host "Set version info"
            $latest = $satVer.processes.storagenode.suggested.version
            $minimal = [String]::Join('.',  $satVer.Storagenode.major.ToString(), $satVer.Storagenode.minor.ToString(), $satVer.Storagenode.patch.ToString())

            #DEBUG latest
            #$latest = "99.0.0"

            #DEBUG oldest
            #$minimal = "90"
            #$latest = "90.1"

            Write-Host ("Latest storagenode version is {0}" -f $latest)
            $result | ForEach-Object { 
                $_.LastVersion = $latest 
                $_.MinimalVersion = $minimal 
            }
        }
        else { Write-Host -ForegroundColor Red "Version query completed with no results" }
    }
    return $result
}

function AggBandwidth
{
    [CmdletBinding()]
    Param(
          [Parameter(ValueFromPipeline)]
          $item
         )    
    begin {
        [long]$ingress = 0
        [long]$egress = 0
        [long]$delete = 0
        $from = $null
        $to = $null
    }
    process {
        $ingress+=$item.ingress.usage
        $egress+= $item.egress.usage
        $delete+= $item.delete

        if ($null -eq $from) { $from = $item.intervalStart}
        elseif ($item.intervalStart -lt $from) { $from = $item.intervalStart}

        if ($null -eq $to) { $to = $item.intervalStart}
        elseif ($item.intervalStart -gt $to) { $to = $item.intervalStart}
    }
    end {
        $p = @{
            'Ingress'  = $ingress
            'Egress'   = $egress
            'TotalBandwidth'= $ingress + $egress
            'MaxBandwidth'= [Math]::Max($ingress, $egress)
            'Delete'   = $delete
            'From'     = $from
            'To'       = $to
        }
        Write-Output (New-Object -TypeName PSCustomObject –Prop $p)
    }
}

function AggBandwidth2
{
    [CmdletBinding()]
    Param(
          [Parameter(ValueFromPipeline)]
          $item
         )    
    begin {
        $ingress = 0
        $ingressMax = 0
        $egress = 0
        $egressMax = 0
        $delete = 0
        $deleteMax = 0
        $from = $null
        $to = $null
    }
    process {
        $ingress+=$item.Ingress
        if ($item.Ingress -gt $ingressMax) { $ingressMax = $item.Ingress }
        
        $egress+= $item.Egress
        if ($item.Egress -gt $egressMax) { $egressMax = $item.Egress }

        $delete+= $item.Delete
        if ($item.Delete -gt $deleteMax) { $deleteMax = $item.Delete }

        if ($null -eq $from) { $from = $item.From}
        elseif ($item.From -lt $from) { $from = $item.From}

        if ($null -eq $to) { $to = $item.To}
        elseif ($item.To -gt $to) { $to = $item.To}
    }
    end {
        $p = @{
            'Ingress'       = $ingress
            'IngressMax'    = $ingressMax
            'Egress'        = $egress
            'EgressMax'     = $egressMax
            'Delete'        = $delete
            'DeleteMax'     = $deleteMax
            'Bandwidth'     = $ingress + $egress
            'From'          = $from
            'To'            = $to
        }
        Write-Output (New-Object -TypeName PSCustomObject –Prop $p)
    }
}

function GetScore
{
    param($nodes)

    $score = $nodes | Sort-Object nodeID | ForEach-Object {
        $node = $_
        $node.Sat | Sort-Object id | ForEach-Object {
            $sat = $_
            $comment = [String]::Empty
            if ($null -ne $sat.Dq) { $comment = ("disqualified {0}" -f $sat.Dq) }
    
            New-Object PSCustomObject -Property @{
                Key = ("{0}-{1}" -f $node.nodeID, $sat.id)
                NodeId = $node.nodeID
                NodeName = $node.Name
                SatelliteId = $sat.id
                Audit = $sat.audit.score
                Uptime = $sat.uptime.score
                Bandwidth = ($sat.bandwidthDaily | AggBandwidth)
                Comment = $comment
            }
        }
    }

    #calc per node bandwidth
    $score | Group-Object NodeId | ForEach-Object {
        $nodeId = $_.Name
        $node = $nodes | Where-Object {$_.NodeId -eq $nodeId} | Select-Object -First 1
        $node.BwSummary = ($_.Group | Select-Object -ExpandProperty Bandwidth | AggBandwidth2)
        $node.Audit = ($_.Group | Select-Object -ExpandProperty Audit | Measure-Object -Min).Minimum
        $node.Uptime = ($_.Group | Select-Object -ExpandProperty Uptime | Measure-Object -Min).Minimum
    }

    $score
}

function Compact
{
    param($id)
    return $id.Substring(0,4) + "-" + $id.Substring($id.Length-2)
}

function GetNodeName{
    param ($config, $id)
    $name = $config.WellKnownNodes."$id"
    if ($null -eq $name) { $name = Compact($id) }
    else {$name+= " (" + (Compact($id)) + ")"}
    return $name
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
    #if ($rest -lt 0.001) { return [String]::Empty }
    if ($rest -lt 0.001) { return "0" }
    $mant = [Math]::Max(3 - [Math]::Floor($rest).ToString().Length,0)
    return ("{0} {1}" -f [Math]::Round($rest,$mant), $suff[$level])
}

function HumanTime {
    param ([TimeSpan]$time)
    $str = ("{0:00}:{1:00}:{2:00}:{3:00}" -f $time.Days, $time.Hours, $time.Minutes, $time.Seconds)
    while ($str.StartsWith("00:")) { $str = $str.TrimStart("00:") }
    return $str
}

function CheckNodes{
    param(
        $config, 
        $body,
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
            $nodeName = (GetNodeName -id $_.nodeID -config $config)
            Write-Output ("Disconnected from node {0}" -f $nodeName) | Tee-Object -Append -FilePath $body
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
                Write-Output ("Node {0} is outdated ({1}.{2}.{3})" -f $testNode.nodeID, $testNode.version.major, $testNode.version.minor, $testNode.version.patch) | Tee-Object -Append -FilePath $body
            }
        }
    }
    
    # Check new wallets
    $oldWal = $oldNodes | Select-Object -ExpandProperty wallet -Unique
    $newWal = $newNodes | Select-Object -ExpandProperty wallet -Unique | Where-Object {$oldWal -notcontains $_ }
    if ($newWal.Count -gt 0) {
        $newWal | ForEach-Object {
            Write-Output ("!WARNING! NEW WALLET {0}" -f $_) | Tee-Object -Append -FilePath $body
        }
    }


    # Check new satellites
    $oldSat = $oldNodes.satellites | Select-Object -ExpandProperty id -Unique

    #DEBUG drop some satellites
    #$oldSat = $oldSat | Sort-Object | Select-Object -First 2

    $newSat = $newNodes.satellites | Select-Object -ExpandProperty id -Unique | Where-Object {$oldSat -notcontains $_ }
    if ($newSat.Count -gt 0) {
        $newSat | ForEach-Object {
            Write-Output ("New satellite {0}" -f $_) | Tee-Object -Append -FilePath $body
        }
    }

    #DEBUG
    #$newNodes[0].lastPinged = [System.DateTimeOffset]::Now - [TimeSpan]::FromMinutes(55)

    #Check last ping
    $newNodes | ForEach-Object {
        #restore old values
        $id = $_.nodeID
        $old = $oldNodes | Where-Object {$_.nodeID -eq $id } | Select-Object -First 1
        if ($null -ne $old) { 
            $_.LastPingWarningValue = $old.LastPingWarningValue 
            $_.LastVerWarningValue = $old.LastVerWarningValue
        }

        $lostMin = [int](([DateTimeOffset]::Now - $_.lastPinged).TotalMinutes)
        if (($_.LastPingWarningValue -eq 0) -and ($lostMin -ge $config.LastPingWarningMinutes)) {
            Write-Output ("Node {0} last ping greater than {1} minutes" -f $_.Name, $lostMin) | Tee-Object -Append -FilePath $body
            $_.LastPingWarningValue = $lostMin
        }
        elseif (($_.LastPingWarningValue -ge $config.LastPingWarningMinutes) -and ($lostMin -lt $config.LastPingWarningMinutes)) {
            $_.LastPingWarningValue = 0
            Write-Output ("Node {0} last ping back to normal ({1} minutes)" -f $_.Name, $lostMin) | Tee-Object -Append -FilePath $body
        }

        if ($null -ne $_.LastVersion) {
            if ($_.version -ne $_.LastVersion) {
                if ($_.LastVerWarningValue -ne $_.LastVersion) {
                    Write-Output ("Node {0} version {1} may be updated to {2}" -f $_.Name, $_.version, $_.LastVersion ) | Tee-Object -Append -FilePath $body
                    $_.LastVerWarningValue = $_.LastVersion
                }
            }
        }
    }
    $oldNodesRef.Value = $newNodes
}

function CheckScore{
    param(
        $config, 
        $body,
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
                Write-Output ("Node {0} down audit from {1} to {2} on {3}" -f $new.nodeID, $old.Audit, $new.Audit, $new.SatelliteId) | Tee-Object -Append -FilePath $body
                $oldScore[$idx].Audit = $new.Audit
            }
            elseif ($new.Audit -gt $old.Audit) { $oldScore[$idx].Audit = $new.Audit }

            if ($old.Uptime -ge ($new.Uptime + $config.Threshold)) {
                Write-Output ("Node {0} down uptime from {1} to {2} on {3}" -f $new.nodeID, $old.Uptime, $new.Uptime, $new.SatelliteId) | Tee-Object -Append -FilePath $body
                $oldScore[$idx].Uptime = $new.Uptime
            }
            elseif ($new.Uptime -gt $old.Uptime) { $oldScore[$idx].Uptime = $new.Uptime }

            if ($old.Comment -ne $new.Comment) {
                Write-Output ("Node {0} update comment: {1}" -f $new.nodeID, $new.Comment) | Tee-Object -Append -FilePath $body
            }
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
        $body
    )

    try {
        $header = $body + "_header"
        if (-not [System.IO.File]::Exists($header))
        {
            $sb = New-Object System.Text.StringBuilder
            $sb.AppendLine("<html>") | Out-Null
            $sb.AppendLine("<body>") | Out-Null
            $sb.AppendLine("<pre style='font: monospace'>") | Out-Null
            [System.IO.File]::WriteAllText($header, $sb.ToString())
        }

        $footer = $body + "_footer"
        if (-not [System.IO.File]::Exists($footer))
        {
            $sb = New-Object System.Text.StringBuilder
            $sb.AppendLine("</pre>") | Out-Null
            $sb.AppendLine("</body>") | Out-Null
            $sb.AppendLine("</html>") | Out-Null
            [System.IO.File]::WriteAllText($footer, $sb.ToString())
        }
        
        $catParam = "'{0}' '{1}' {2}" -f $header, $body, $footer
        $mailParam = "--content-type text/html -s '{0}' {1}" -f $config.Mail.Subj, $config.Mail.To
        $bashParam = ('-c "cat {0} | mail {1}"' -f $catParam, $mailParam)
        $output = ExecCommand -path $config.Mail.Path -params $bashParam -out

        Write-Host ("Mail sent to {0} via linux agent" -f $config.Mail.To)
        if ($output.Length -gt 0) { Write-Host $output }
    }
    catch {
        Write-Host -ForegroundColor Red ($_.Exception.Message)        
    }
}

function GetMailBody {
    param($body)
    $sb = New-Object System.Text.StringBuilder
    $sb.AppendLine("<html>") | Out-Null
    $sb.AppendLine("<body>") | Out-Null
    $sb.AppendLine("<pre style='font: monospace'>") | Out-Null
    $sb.AppendLine([System.IO.File]::ReadAllText($body)) | Out-Null
    $sb.AppendLine("</pre>") | Out-Null
    $sb.AppendLine("</body>") | Out-Null
    $sb.AppendLine("</html>") | Out-Null
    return $sb.ToString()
}
function SendMailPowershell{
    param(
        $config, 
        $body
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
                -Body (GetMailBody -body $body) `
                -BodyAsHtml `
                -Encoding utf8 `
                -UseSsl: $ssl `
                -SmtpServer ($config.Mail.Smtp) `
                -Port ($config.Mail.Port) `
                -Credential $credential `
                -ErrorAction Stop 
                
            
            Write-Host ("Mail sent to {0} via powershell agent" -f $config.Mail.To)
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
        $body
    )

    if ($config.Mail.MailAgent -eq "powershell") { SendMailPowershell -config $config -body $body }
    elseif ($config.Mail.MailAgent -eq "linux") { SendMailLinux -config $config -body $body }
    else {
        Write-Host -ForegroundColor Red "Mail not properly configuried"
    }
}

function Monitor {
    param (
        $config, 
        $body, 
        $oldNodes,
        $oldScore
    )

    #DEBUG canopy
    #$config.Canary = [System.DateTimeOffset]::Now.Subtract([System.TimeSpan]::FromDays(1))

    while ($true) {
        Start-Sleep -Seconds $config.WaitSeconds
        CheckNodes -config $config -body $body -oldNodesRef ([ref]$oldNodes)
        CheckScore -config $config -body $body -nodes $oldNodes -oldScore $oldScore

        # Canopy warning
        #DEBUG check hour, must be 10
        if (($null -eq $config.Canary) -or ([System.DateTimeOffset]::Now.Day -ne $config.Canary.Day -and [System.DateTimeOffset]::Now.Hour -ge 10)) {
            $config.Canary = [System.DateTimeOffset]::Now
            Write-Output ("storj3monitor is alive {0}" -f $config.Canary) | Tee-Object -Append -FilePath $body
            DisplayNodes -nodes $oldNodes >>$body
        }
        if (([System.IO.File]::Exists($body)) -and (Get-Item -Path $body).Length -gt 0)
        {
            SendMail -config $config -body $body
            Clear-Content -Path $body
        }
    }
    Write-Host "Stop monitoring"
}

function GetPips {
    param ($width, [int64]$max, [int64]$current, [int64]$maxg = $null)

    if ($max -gt 0) { $val = $current/$max }
    else { $val = 0 }
    $pips = [int]($width * $val )
    $pipsg = 0

    if (($null -ne $maxg) -and ($maxg -gt 0)) {
        $valg = $current/$maxg
        $pipsg = [int]($width * $valg)
        $str = "[" + "".PadRight($pips, "=").PadRight($pipsg, "-").PadRight($width, " ") + "] "
    }
    else {
        $str = "[" + "".PadRight($pips, "-").PadRight($width, " ") + "] "
    }

    return $str
}

function DisplayPips {
    param($width, $bandwidth, $name)
}

function CompareVersion {
    param ($v1, $v2)
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

function DisplayNodes {
    param ($nodes, $bwsummary)
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "N O D E S    S U M M A R Y"

    if ($null -eq $bwsummary) {
        $bwsummary = ($nodes | Select-Object -ExpandProperty BwSummary | AggBandwidth2)
    }

    $used = ($nodes.diskspace.used | Measure-Object -Sum).Sum
    $avail = ($nodes.diskspace.available | Measure-Object -Sum).Sum
    $latest = $nodes | Where-Object {$null -ne $_.LastVersion } | Select-Object -ExpandProperty LastVersion -First 1
    $minimal = $nodes | Where-Object {$null -ne $_.MinimalVersion } | Select-Object -ExpandProperty MinimalVersion -First 1

    $nodes | Group-Object Version | ForEach-Object {
        Write-Host -NoNewline ("storagenode version {0}" -f $_.Name)
        if ($null -ne $latest) {
            if ((CompareVersion -v1 $minimal -v2 $latest) -gt 0) { 
                Write-Host -ForegroundColor Red (" (Something wrong in satellite. Oldest version {0} greater than latest version {1})" -f $minimal, $latest)
            }
            elseif ( ($_.Name -eq $latest) -or ((CompareVersion -v1 $_.Name -v2 $latest) -eq 0)) { 
                Write-Host -ForegroundColor Green " (latest)" 
            }
            elseif ((CompareVersion -v1 $_.Name -v2 $latest) -gt 0) { 
                Write-Host (" (Something wrong in my algorythm or satellite. Node version greater than latest {0})" -f $latest)
            }
            elseif ((CompareVersion -v1 $_.Name -v2 $minimal) -ge 0) { 
                Write-Host -ForegroundColor Yellow (" (not latest but still actual between {0} and {1})" -f $minimal, $latest) 
            }
            elseif ((CompareVersion -v1 $_.Name -v2 $minimal) -lt 0) { 
                Write-Host -ForegroundColor Red (" (obsolete! min {0} max {1} please update quickly)" -f $minimal, $latest) 
            }
        else { Write-Host -ForegroundColor Red "Something wrong in version check" }
        }
        else { Write-Host }

        $_.Group | Sort-Object Name | Format-Table `
        @{n="Node"; e={$_.Name}}, `
        @{n="Ping"; e={HumanTime([DateTimeOffset]::Now - $_.lastPinged)}}, `
        @{n="Audit"; e={Round($_.Audit)}}, `
        @{n="Uptime"; e={Round($_.Uptime)}}, `
        @{n="[ Used  "; e={HumanBytes($_.diskSpace.used)}}, `
        @{n="Disk                  "; e={("{0}" -f ((GetPips -width 20 -max $_.diskSpace.available -current $_.diskSpace.used)))}}, `
        @{n="Free ]"; e={HumanBytes(($_.diskSpace.available - $_.diskSpace.used))}}, `
        @{n="Egress"; e={("{0} ({1})" -f ((GetPips -width 10 -max $bwsummary.Egress -maxg $bwsummary.EgressMax -current $_.BwSummary.Egress)), (HumanBytes($_.BwSummary.Egress)))}}, `
        @{n="Ingress"; e={("{0} ({1})" -f ((GetPips -width 10 -max $bwsummary.Ingress -maxg $bwsummary.IngressMax -current $_.BwSummary.Ingress)), (HumanBytes($_.BwSummary.Ingress)))}}, `
        @{n="Delete"; e={("{0} ({1})" -f ((GetPips -width 10 -max $bwsummary.Delete -maxg $bwsummary.DeleteMax -current $_.BwSummary.Delete)), (HumanBytes($_.BwSummary.Delete)))}}, `
        @{n="[ Bandwidth"; e={("{0}" -f ((GetPips -width 10 -max $_.bandwidth.available -current $_.bandwidth.used)))}}, `
        @{n="Free ]"; e={HumanBytes(($_.bandwidth.available - $_.bandwidth.used))}}

    }

    Write-Output ("Stat time {0:yyyy.MM.dd HH:mm:ss (UTCzzz)}" -f [DateTimeOffset]::Now)
    Write-Output ("Total storage {0}; used {1}; available {2}" -f (HumanBytes($avail)), (HumanBytes($used)), (HumanBytes($avail-$used)))
    Write-Output ("Total bandwidth {0} Ingress, {1} Egress, {2} Delete" -f 
        (HumanBytes($bwsummary.Ingress)), 
        (HumanBytes($bwsummary.Egress)), 
        (HumanBytes($bwsummary.Delete))
    )

    Write-Output ("from {0:yyyy.MM.dd} to {1:yyyy.MM.dd} on {2} nodes" -f 
        $bwsummary.From, 
        $bwsummary.To, 
        $nodes.Count
    )

    $maxEgress = $nodes | Sort-Object -Descending {$_.BwSummary.Egress} | Select-Object -First 1
    Write-Output ("- Max egress {0} at {1}" -f (HumanBytes($maxEgress.BwSummary.Egress)), $maxEgress.Name)

    $maxIngress = $nodes | Sort-Object -Descending {$_.BwSummary.Ingress} | Select-Object -First 1
    Write-Output ("- Max ingress {0} at {1}" -f (HumanBytes($maxIngress.BwSummary.Ingress)), $maxIngress.Name)

    $maxBandwidth = $nodes | Sort-Object -Descending {$_.BwSummary.Bandwidth} | Select-Object -First 1
    Write-Output ("- Max bandwidth {0} at {1}" -f (HumanBytes($maxBandwidth.BwSummary.Bandwidth)), $maxBandwidth.Name)
}

function DisplayScore {
    param ($score, $bwsummary)

    Write-Host
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "S A T E L L I T E S    D E T A I L S"

    $tab = [System.Collections.Generic.List[PSCustomObject]]@()
    $score | Sort-Object SatelliteId, NodeName | ForEach-Object {
        $p = @{
            'Satellite' = ("{0} ({1})" -f $wellKnownSat[$_.SatelliteId], (Compact($_.SatelliteId)))
            'Node'      = $_.NodeName
            'Ingress'   = ("{0} {1}" -f (GetPips -width 10 -max $bwsummary.Ingress -maxg $bwsummary.IngressMax -current $_.Bandwidth.Ingress), (HumanBytes($_.Bandwidth.Ingress)))
            'Egress'    = ("{0} {1}" -f (GetPips -width 10 -max $bwsummary.Egress -maxg $bwsummary.EgressMax -current $_.Bandwidth.Egress), (HumanBytes($_.Bandwidth.Egress)))
            'Delete'    = ("{0} {1}" -f (GetPips -width 10 -max $bwsummary.Delete -maxg $bwsummary.DeleteMax -current $_.Bandwidth.Delete), (HumanBytes($_.Bandwidth.Delete)))
            'Audit'     = Round($_.Audit)
            'Uptime'    = Round($_.Uptime)
            'Comment'   = $_.Comment
        }
        $tab.Add((New-Object -TypeName PSCustomObject –Prop $p))
    }
    $tab.GetEnumerator() | Format-Table Satellite, Node, Ingress, Egress, Delete, Audit, Uptime, Comment

    Write-Host
}

function GraphTimeline
{
    param ($title, $decription, [int]$height, $bandwidth, $query, $nodesCount)
    if ($height -eq 0) { $height = 10 }

    $bd = $bandwidth | Group-Object {$_.intervalStart.Day}
    $timeline = New-Object "System.Collections.Generic.SortedList[int, PSCustomObject]"
    $bd | ForEach-Object { $timeline.Add([Int]::Parse($_.Name), ($_.Group | AggBandwidth)) }

    #max in groups while min in original data. otherwise min was zero in empty data cells
    $firstCol = ($timeline.Keys | Measure-Object -Minimum).Minimum
    $lastCol = ($timeline.Keys | Measure-Object -Maximum).Maximum
    $dataMin = ($timeline.Values | Measure-Object -Minimum -Property MaxBandwidth).Minimum
    $dataMax = ($timeline.Values | Measure-Object -Maximum -Property MaxBandwidth).Maximum

    if (($null -eq $dataMax) -or ($dataMax -eq 0)) { 
        Write-Host -ForegroundColor Red ("{0}: no traffic data" -f $title)
        return
    }
    elseif ($dataMax -eq $dataMin) { $rowWidth = $dataMax / $height}
    else { $rowWidth = ($dataMax - $dataMin) / $height }

    $graph = New-Object System.Collections.Generic.List[string]

    #workaround for bad text editors
    $pseudoGraphicsSymbols = [System.Text.Encoding]::UTF8.GetString(([byte]226, 148,148,226,148,130,45,226,148,128))
    if ($pseudoGraphicsSymbols.Length -ne 4) { throw "Error with pseudoGraphicsSymbols" }
    $sb = New-Object System.Text.StringBuilder(1)
    $firstCol..$lastCol | ForEach-Object { 
        $sb.Append(("{0:00} " -f $_)) | Out-Null
    } 
    $graph.Add(" " + $sb.ToString())
    $graph.Add($pseudoGraphicsSymbols[0].ToString().PadRight($lastCol*3 + 1, $pseudoGraphicsSymbols[3]))

    $fill1 = "   "
    $fill2 = $pseudoGraphicsSymbols[2] + $pseudoGraphicsSymbols[2] + " "

    $skip = 0
    $first = $null
    $line = $null
    1..$height | ForEach-Object {
        $r = $_
        $line = $pseudoGraphicsSymbols[1]
        $firstCol..$lastCol | ForEach-Object {
            $c = $_
            $agg = $timeline[$c]
            $h = ($agg.MaxBandwidth - $dataMin) / $rowWidth
            if ($h -ge $r ) {
                $hi = ($agg.Ingress - $dataMin) / $rowWidth
                $he = ($agg.Egress - $dataMin) / $rowWidth
                if (-not ($query.Ingress -xor $query.Egress)) {
                    if ($hi -ge $r -and $he -ge $r) { $line+="ie " }
                    elseif ($hi -ge $r) { $line+="i  " }
                    elseif ($he -ge $r) { $line+=" e " }
                }
                else {
                    if (($query.Ingress -and $hi -ge $r) -or ($query.Egress -and $he -ge $r)) { $line+=$fill2 }
                    else {$line+=$fill1}
                }
            }
            else {$line+=$fill1}
        }
        if (($null -eq $first) -or ($line -ne $first)) { 
            $graph.Add($line) 
            #allow skips only for full month
            if ($null -eq $query.Days) { $first = $line }
        }
        elseif (($null -ne $first) -and ($line -eq $first)) { $skip++ }
        elseif (($null -ne $first) -and ($line -ne $first)) { 
            $graph.Add($line)
            $first = "xxx"
        }

        #else {$skip++}
    }
    if ($skip -gt 0) { $graph[1] = $graph[1] + " * " + $skip.ToString() }
    $graph.Reverse()


    Write-Host $title -NoNewline -ForegroundColor Yellow
    if (-not [String]::IsNullOrEmpty($decription)) {Write-Host (" - {0}" -f $decription) -ForegroundColor Gray -NoNewline}
    Write-Host
    Write-Host ("Y-axis from {0} to {1}; cell = {2}; {3} nodes" -f (HumanBytes($dataMin)), (HumanBytes($dataMax)), (HumanBytes($rowWidth)), $nodesCount) -ForegroundColor Gray
    $graph | ForEach-Object {Write-Host $_}

    $maxEgress = $timeline.Values | Sort-Object -Descending {$_.Egress} | Select-Object -First 1
    $avgEgress = ($timeline.Values | Measure-Object -Average Egress).Average
    Write-Host (" - egress max {0} ({1:yyyy-MM-dd}), average {2}" -f `
        (HumanBytes($maxEgress.Egress)), `
        $maxEgress.To, `
        (HumanBytes($avgEgress)))

    $maxIngress = $timeline.Values | Sort-Object -Descending {$_.Ingress} | Select-Object -First 1
    $avgIngress = ($timeline.Values | Measure-Object -Average Ingress).Average
    Write-Host (" - ingress max {0} ({1:yyyy-MM-dd}), average {2}" -f `
        (HumanBytes($maxIngress.Ingress)), `
        $maxIngress.To, `
        (HumanBytes($avgIngress)))

    $maxBandwidth = $timeline.Values | Sort-Object -Descending {$_.TotalBandwidth} | Select-Object -First 1
    $avgBandwidth = ($timeline.Values | Measure-Object -Average TotalBandwidth).Average
    Write-Host (" - bandwidth max {0} ({1:yyyy-MM-dd}), average {2}" -f `
        (HumanBytes($maxBandwidth.TotalBandwidth)), `
        $maxBandwidth.To, `
        (HumanBytes($avgBandwidth)))

    Write-Host
    Write-Host
}

function DisplaySat {
    param ($nodes, $bw, $query)
    Write-Host
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "S A T E L L I T E S   B A N D W I D T H"
    Write-Host "Legenda:"
    Write-Host "`ti `t-ingress"
    Write-Host "`te `t-egress"
    Write-Host "`t= `t-pips from all bandwidth"
    Write-Host "`t- `t-pips from bandwidth of maximum node, or simple percent line"
    Write-Host "`t* n `t-down line supressed n times"
    Write-Host
    $now = [System.DateTimeOffset]::Now
    ($nodes | Select-Object -ExpandProperty Sat) | Group-Object id | ForEach-Object {
        #Write-Host $_.Name
        $sat = $_
        $bw = $sat.Group | Select-Object -ExpandProperty bandwidthDaily | Where-Object { ($_.IntervalStart.Year -eq $now.Year) -and ($_.IntervalStart.Month -eq $now.Month)}
        $title = ("{0} ({1})" -f  $sat.Group[0].Url, $sat.Name)
        GraphTimeline -title $title -bandwidth $bw -query $query -nodesCount $nodes.Count
    }
    Write-Host
}
function DisplayTraffic {
    param ($nodes, $query)
    $bw = $nodes | Select-Object -ExpandProperty Sat | Select-Object -ExpandProperty bandwidthDaily
    GraphTimeline -title "Traffic by days" -height 15 -bandwidth $bw -query $query -nodesCount $nodes.Count
}

Preamble
if ($args.Contains("example")) {
    $config = DefaultConfig
    $config | ConvertTo-Json
    return
}

$config = LoadConfig -cmdlineArgs $args
#DEBUG
#$config = LoadConfig -cmdlineArgs "-c", ".\ConfigSamples\Storj3Monitor.Debug.conf"

if (-not $config) { return }

function GetQuery {
    param($cmdlineArgs)

    $days = $null
    $index = $cmdlineArgs.IndexOf("-d")
    if ($index -ge 0) {
        if (($cmdlineArgs.Count -ge $index + 1) -and [System.Int32]::TryParse($cmdlineArgs[$index + 1], [ref]$days)) {
            if ($days -eq 0) { Write-Host "Query today" }
            elseif ($days -lt 0) { Write-Host ("Query today {0}" -f $days) }
            elseif ($days -gt 0) { Write-Host ("Query {0} last days" -f $days) }
        }
        else {
            $days = 0
            Write-Host "Query today"
        }
    }

    $node = $null
    $index = $cmdlineArgs.IndexOf("-node")
    if ($index -ge 0) { $node = $cmdlineArgs[$index + 1] }

    $query = @{
        Ingress = $cmdlineArgs.Contains("ingress")
        Egress = $cmdlineArgs.Contains("egress")
        Days = $days
        Node = $node
    }
    return $query
}

$query = GetQuery -cmdlineArgs $args
$nodes = GetNodes -config $config -query $query
$score = GetScore -nodes $nodes
$bwsummary = ($nodes | Select-Object -ExpandProperty BwSummary | AggBandwidth2)
;
#DEBUG    
if ($args.Contains("monitor")) {
    $body = [System.IO.Path]::GetTempFileName()
    Write-Output ("Start monitoring {0} entries at {1}, {2} seconds cycle" -f $score.Count, $config.StartTime, $config.WaitSeconds) | Tee-Object -FilePath $body
    Write-Host ("Output to {0}" -f $body)

    Monitor -config $config -body $body -oldNodes $nodes -oldScore $score
    [System.IO.File]::Delete($body)
}
elseif ($args.Contains("testmail")) {
    $body = [System.IO.Path]::GetTempFileName()
    Write-Output ("Test mail. Configured {0} entries" -f $score.Count) | Tee-Object -FilePath $body
    SendMail -config $config -body $body
    [System.IO.File]::Delete($body)
}
elseif ($nodes.Count -gt 0) {
    if ($null -eq $query.Days -or $query.Days -gt 0) {
        DisplaySat -nodes $nodes -query $query
        DisplayTraffic -nodes $nodes -query $query
    }
    DisplayScore -score $score -bwsummary $bwsummary
    DisplayNodes -nodes $nodes -bwsummary $bwsummary
}

#DEBUG
#.\Storj3Monitor\Storj3Monitor.ps1 -c .\Storj3Monitor\ConfigSamples\Storj3Monitor.Debug.conf
