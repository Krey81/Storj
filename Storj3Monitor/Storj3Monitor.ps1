# Storj3Monitor script by Krey
# this script gathers, aggregate displays and monitor all you node thresholds
# if uptime or audit down by [threshold] script send email to you
# https://github.com/Krey81/Storj

$v = "0.9.15"

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
# v0.6.4   - 20191130
#               -   move trafic summary down below satellite details
#               -   add vetting info in comment field
# v0.6.5   - 20191130
#               -   vetting info audit. totalCount replaced with successCount
#               -   fix Now to UtcNow date, bug on month boundary
# v0.6.6   - 20191204
#               -   fix comment monitoring cause mail storm
#               -   add MonitorFullComment option
#               -   fix mail text cliping in linux
#               -   show node name in mails instead of id
#               -   add HideNodeId config option
#               -   add satellite details to canopy warning
# v0.6.7   - 20191205
#               -   IMPORTANT - fix incorrect supressing graph lines (* N). Not only bottom lines was supressed before fix. Incorrect graphs.
#                   - thanks again to Sans Konor
#               -   Add repair graphs and counters
#               -   Add config option DisplayRepairOption, by default repairs show totals and "by days" graph
# v0.6.8   - 20191205
#               -   fix powershell 5.0 issues
# v0.6.9   - 20191205
#               -   zero base graphs by default
#               -   config option GraphStart [zero, minbandwidth]
# v0.7.0   - 20191213
#               -   parallel nodes quering
# v0.7.1   - 20191216
#               -   Top 5 vetting nodes
#               -   Fix Compat function not included in job scope
# v0.7.2   - 20191217
#               -   add vetting to sat details
#               -   add workaround to job awaiter for linux
#               -   add -np cmdline parameter to ommit parallel queries
#               -   small fixes
# v0.7.3   - 20200211
#               -   fix null call on new satellite, add saltlake satellite
#               -   remove deleted column
#               -   Uptime now meen uptime failed count. Enable uptime monitoring with UptimeThreashold=3 by default.
#               -   Add Runtime column (display count of hours from node start)
# v0.7.4   - 20200214
#               -   Fix Windows powershell compatibility issues
# v0.7.5   - 20200228
#               -   Fix UptimeFail counter calculation (previous version multiplied by 100 because before it was a percentage)
#               -   Change default UptimeThreashold from 10 to 3
#               -   Output sum of uptime failed in node stats
#               -   Short headers from UptimeFail to UptimeF
# v0.7.6   - 20200305
#               -   fix monitor issue when offline nodes replaced with last online in monitor loop
#               -   add "node back online" notice
#               -   add "node updated" notice (for work with new Storj3Updater script)
# v0.8.0   - 20200310 
#               -   add etherscan.io integration
#               -   add parameter -p
# v0.8.1   - 20200310 
#               -   add transaction count to payouts output
# v0.8.2   - 20200320 
#               -   new api endpoints
# v0.8.3   - 20200328
#               -   add debug messages for satellite timeout
#               -   add TimeoutSec config option
# v0.9.0   - 20200501
#               -   add europe-north-1 wellknown satellite, thanks fmoledina
#               -   add payments info (use cmdline key -p all)
#               -   add suspended comment if present
#               -   remove bandwidth columns
# v0.9.1   - 20200502
#               -   cache etherscan data
#               -   fix payments sorting
#               -   fix joined at date - may reflect on you amounts compare to 0.9.0
#               -   add codes https://github.com/storj/storj/blob/895eac17113f74f7a6364cdf2fdbcea1b8d93ccc/satellite/compensation/codes.go#L11-L29
# v0.9.2   - 20200502
#               -   default months for -p changed from 2 to 4
#               -   add Storage grow, grow factor, Earned column and graphics in payments and nodes
#               -   Move text footer down after payments. Add Total earned to footer.
# v0.9.3   - 20200502
#               -   add relative payments table. You can safely post it on forums, where no amounts
#               -   add dir column to indicate direction of trafic and it difference (egress/ingress or vice versa)
# v0.9.4   - 20200503
#               -   fix -d parameter
# v0.9.5   - 20200507
#               -   add debug message to future fix empty node back online in monitoring mode
#               -   fix div by zero
#               -   restore footer in canapy leters
#               -   possible fix empty node back online in monitoring mode
#               -   add failed nodes to footer
#               -   hide payment columns without -p parameter
# v0.9.6   - 20200508
#               -   fix joins storj payments with etherscan 
#               -   move held columns in absolute payments
#               -   add -nocache cmdline option to ignore saved etherscan data
#               -   fix date compare (old powershell) issue
# v0.9.7   - 20200509
#               -   congratulations on the day of Victory over the most terrible evil in the known history of mankind
#               -   add "Disk space used this month" graph for all nodes
#               -   add current earnings with held and paid, disk and egress
# v0.9.8   - 20200520
#               -   add per satellite storage graph
#               -   add per satellite nodes payouts
# v0.9.9   - 20200520
#               -   fix update grouping
#               -   fix empty node name in quotes, thanks to @aleksandr_k
# v0.9.10   - 20200520
#               -   fix node name again
# v0.9.11   - 20200818
#               -   fix error if config contains only one node
# v0.9.12   - 20200820 ( private, experimental )
#               -   fix error on absent payments for new nodes and parameter -p
#               -   substract disposed from months earnings, fix summary
#               -   add repair and audit to current earnings
#               -   add БАБЛОМЕТР (experimental)
# v0.9.13   - 20200824
#               -   fix day earnings
#               -   earnings pips in node summary take percent from max node
#               -   add calculation for egress sum missmatch
# v0.9.14   - 20200824
#               -   remove r&a from egress in currend earnings
#               -   remove calculation for egress sum missmatch
# v0.9.15   - 20200906
#               -   change and compact totals output
#               -   add estimate month earnings
#               -   add days earnings to monitor output
#               -   improve old powershell compatibles


# TODO v0.9.9
#               -   add held amount rate
#               -   fix () without wellknown nodes
#               -   add current earnings

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
#       pwsh ./Storj3Monitor.ps1 -c <config-file> [ingress|egress] [-node name] [-np] [-p <num>|year|all]
#
#
#      Where 
#           ingress     - only ingress traffic
#           egress      - only egress traffic
#           -node       - filter output to that node
#           -np         - no parallel execution
#           -p          - show payments from etherscan.io; 
#                       - num  - count of last months
#                       - year - current year
#                       - all  - all available transactons
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

$repairOptionValues = @(
    "none", 
    "totals", 
    "traffic", 
    "sat"
)

$graphStartOptionValues = @(
    "zero", 
    "minbandwidth"
)

$code = @'
using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

namespace InProcess
{
    public class InMemoryJob : System.Management.Automation.Job
    {
        private static int _InMemoryJobNumber = 0;
        private PowerShell _PowerShell;
        private bool _IsDisposed = false;
        private IAsyncResult _AsyncResult = null;

        public override bool HasMoreData 
        {
            get 
            {
                return (Output.Count > 0);
            }
        }
        public override string Location 
        {
            get
            {
                return "In Process";
            }
        }
        public override string StatusMessage
        {
            get
            {
                return String.Empty;
            }
        }

        public InMemoryJob(PowerShell powerShell, string name)
        {
            _PowerShell = powerShell;
            Init(name);
        }
        private void Init(string name)
        {
            int id = System.Threading.Interlocked.Add(ref _InMemoryJobNumber, 1);

            if (!string.IsNullOrEmpty(name)) Name = name;
            else Name = "InProcessJob" + id;

            _PowerShell.Streams.Information = Information;
            _PowerShell.Streams.Progress = Progress;
            _PowerShell.Streams.Verbose = Verbose;
            _PowerShell.Streams.Error = Error;
            _PowerShell.Streams.Debug = Debug;
            _PowerShell.Streams.Warning = Warning;
            _PowerShell.Runspace.AvailabilityChanged += new EventHandler<RunspaceAvailabilityEventArgs>(Runspace_AvailabilityChanged);
        }

        void Runspace_AvailabilityChanged(object sender, RunspaceAvailabilityEventArgs e)
        {
            if (e.RunspaceAvailability == RunspaceAvailability.Available) SetJobState(JobState.Completed);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && !_IsDisposed)
            {
                _IsDisposed = true;
                try
                {
                    if (!IsFinishedState()) StopJob();
                    foreach (Job job in ChildJobs) job.Dispose();
                }
                finally { base.Dispose(disposing); }
            }
        }

        public bool IsFinishedState()
        {
           return (JobStateInfo.State == JobState.Completed || JobStateInfo.State == JobState.Failed || JobStateInfo.State == JobState.Stopped);
        }

        public void Start()
        {
            _AsyncResult = _PowerShell.BeginInvoke<PSObject, PSObject>(null, Output);
            SetJobState(JobState.Running);
        }

        public override void StopJob()
        {
            _PowerShell.Stop();
            _PowerShell.EndInvoke(_AsyncResult);
            SetJobState(JobState.Stopped);
        }

        public bool WaitJob(TimeSpan timeout)
        {
            return _AsyncResult.AsyncWaitHandle.WaitOne(timeout);
        }
    }
}
'@
Add-Type -TypeDefinition $code
function Start-QueryNode
{
  [CmdletBinding()]
  param
  (
    $Name,
    [scriptblock] $InitializationScript,
    $Address,
    $Config,
    $Query
  )
  $PowerShell = [PowerShell]::Create().AddScript($InitializationScript)
  $PowerShell.Invoke()
  $PowerShell.AddCommand("QueryNode").AddParameter("address", $Address).AddParameter("config", $Config).AddParameter("query", $Query) | Out-Null
  $MemoryJob = New-Object InProcess.InMemoryJob $PowerShell, $Name
  $MemoryJob.Start()
  $MemoryJob
}
function StartWebRequest
{
  [CmdletBinding()]
  param
  (
    $Name,
    $Address,
    $Timeout
  )
  $PowerShell = [PowerShell]::Create().AddScript("(Invoke-WebRequest -Uri $address -TimeoutSec $timeout).Content | ConvertFrom-Json").AddParameter("address", $Address).AddParameter("timeout", $Timeout)
  $MemoryJob = New-Object InProcess.InMemoryJob $PowerShell, $Name
  $MemoryJob.Start()
  $MemoryJob
}
   
function IsAnniversaryVersion {
    param($vstr)
    $standardBootleVolumeLitters = 0.5
    $vstr = [String]::Join(".", ($vstr.Split('.') | Select-Object -First 2) )
    $vdec = [Decimal]::Parse($vstr, [CultureInfo]::InvariantCulture)
    if (($vdec % $standardBootleVolumeLitters) -eq 0.0) { return $true }
    else { return $false }
}
function IsVictoryDay {
    $now = [System.DateTime]::Now
    if (($now.Month -eq 5) -and ($now.Day -eq 9)) { return $true }
    return $false
}
function IsBirthday {
    $now = [System.DateTime]::Now
    if (($now.Month -eq 9) -and ($now.Day -eq 14)) { return $true }
    return $false
}

function Preamble{
    Write-Host ""
    Write-Host -NoNewline ("Storj3Monitor script by Krey ver {0}" -f $v)
    if (IsAnniversaryVersion($v)) { Write-Host -ForegroundColor Green "`t- Anniversary version: Astrologers proclaim the week of incredible bottled income" }
    else { Write-Host }
    if (IsVictoryDay) { Write-Host -ForegroundColor Green "GLORIOUS VICTORY"}
    Write-Host "mail-to: krey@irinium.ru"
    Write-Host "telegram: Krey81"
    if (IsBirthday) { Write-Host -ForegroundColor Blue "THIS DAY IS KREY'S BIRTHDAY! "}
    Write-Host ""
    Write-Host -ForegroundColor Yellow "I work on beer. If you like my scripts please donate bottle of beer in STORJ or ETH to 0x7df3157909face2dd972019d590adba65d83b1d8"
    Write-Host -ForegroundColor Gray "Why should I send bootles if everything works like that ?"
    Write-Host -ForegroundColor Gray "... see TODO comments in the script body"
    Write-Host ""
    Write-Host "Thanks Sans Kokor, DmitryOligarch for bug hunting"
    Write-Host "Thanks underflow17"
    Write-Host "Thanks aleksandr_k"
    Write-Host "...and last but not least Dr_Odmin, 3bl3gamer"
    Write-Host "...and all STORJ Russian Chat members"
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

function DefaultConfig{
    $config = @{
        Nodes = "127.0.0.1:14002"
        WaitSeconds = 300
        Threshold = 0.2
        MonitorFullComment = $false
        HideNodeId = $false
        DisplayRepairOption = "traffic"
        GraphStart = "zero"
        Mail = @{
            MailAgent = "none"
        }
    }
    return $config
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
    $config | Add-Member -NotePropertyName MemFile -NotePropertyValue ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "Storj3Monitor_mem"))
    $config | Add-Member -NotePropertyName NoCache -NotePropertyValue $false

    if ($null -eq $config.LastPingWarningMinutes) { 
        $config | Add-Member -NotePropertyName LastPingWarningMinutes -NotePropertyValue 30
    }

    if ($null -eq $config.MonitorFullComment) { 
        $config | Add-Member -NotePropertyName MonitorFullComment -NotePropertyValue $false
    }

    if ($null -eq $config.HideNodeId) { 
        $config | Add-Member -NotePropertyName HideNodeId -NotePropertyValue $false
    }

    if ($null -eq $config.DisplayRepairOption) { 
        $config | Add-Member -NotePropertyName DisplayRepairOption -NotePropertyValue "traffic"
    }
    elseif ($repairOptionValues -notcontains $config.DisplayRepairOption) {
        throw ("Bad DisplayRepairOption value in config")
    }

    if ($null -eq $config.GraphStart) { 
        $config | Add-Member -NotePropertyName GraphStart -NotePropertyValue "zero"
    }
    elseif ($graphStartOptionValues -notcontains $config.GraphStart) {
        throw ("Bad GraphStart value in config")
    }

    if ($null -eq $config.UptimeThreshold) { 
        $config | Add-Member -NotePropertyName UptimeThreshold -NotePropertyValue 3
    }

    if ($null -eq $config.TimeoutSec) { 
        $config | Add-Member -NotePropertyName TimeoutSec -NotePropertyValue 20
    }

    $config | Add-Member -NotePropertyName Payout -NotePropertyValue $null
    $idx = $cmdlineArgs.IndexOf("-p")
    if ($idx -gt 0) {

        # PLEASE setup you own API key: Register on etherscan.io and create API-KEY in you profile, 
        # add it to config like "EtherscanKey": "you-key"
        # if this is not done beginners will suffer 
        # if you read this, then you are not a beginner, so just do it, use a you own API-KEY

        # api key for Storj3Monitor FOR ALL newbies
        if ($null -eq $config.EtherscanKey) { 
            $config | Add-Member -NotePropertyName EtherscanKey -NotePropertyValue "938G2GAQP1TZGU5JYEQ9JHUEQ7J39NINM4"
            Write-Host -ForegroundColor Red ("Etherscan.io quering with newbies API-KEY. Please setup you own key !!!")
        } 

        [int]$payout = 4
        if (($cmdlineArgs.Length - 1) -gt $idx)
        {
            $pstr = $cmdlineArgs[$idx + 1]
            if (-not [int]::TryParse($pstr, [ref]$payout)) {
                if ($pstr -eq "year") { $payout = [System.DateTimeOffset]::Now.Month }
                elseif ($pstr -eq "all") { $payout = -1 }
                else { throw "bad -p (payment) parameter. Expected <num> of months or 'year' or 'all'"}
            }
        }
        $config.Payout = $payout
    }

    $idx = $cmdlineArgs.IndexOf("-nocache")
    if ($idx -gt 0) { $config.NoCache = $true }

    return $config
}

function GetJson
{
    param($uri, $timeout)

    #RAW
    # ((Invoke-WebRequest -Uri http://192.168.157.2:14002/api/sno).content | ConvertFrom-Json)
    #((Invoke-WebRequest -Uri http://192:4401/api/sno).content | ConvertFrom-Json)
    #((Invoke-WebRequest -Uri http://192:4401/api/sno/satellite/118UWpMCHzs6CvSgWd9BfFVjw5K9pZbJjkfZJexMtSkmKxvvAW).content | ConvertFrom-Json)
    #((Invoke-WebRequest -Uri http://51.89.0.35:4409/api/heldamount/paystubs/2020-03).content | ConvertFrom-Json)

    $resp = Invoke-WebRequest -Uri $uri -TimeoutSec $timeout
    if ($resp.StatusCode -ne 200) { throw $resp.StatusDescription }
    $json = ConvertFrom-Json $resp.Content
    if ($json.PSObject.Properties.Name -contains "Error") {
        if (-not [System.String]::IsNullOrEmpty($json.Error)) { throw $json.Error }
    }
    return $json
}

# For powershell v5 compatibility
function FixDateSat {
    param($sat)
    for ($i=0; $i -lt $sat.bandwidthDaily.Length; $i++) {
        $sat.bandwidthDaily[$i].intervalStart = [DateTimeOffset]$sat.bandwidthDaily[$i].intervalStart
    }
    for ($i=0; $i -lt $sat.storageDaily.Length; $i++) {
        $sat.storageDaily[$i].intervalStart = [DateTimeOffset]$sat.storageDaily[$i].intervalStart
    }
    $sat.nodeJoinedAt = [DateTimeOffset]$sat.nodeJoinedAt
}

function FixNode {
    param($node)
    try {
        if ($node.lastPinged.GetType().Name -eq "String") { $node.lastPinged = [DateTimeOffset]::Parse($node.lastPinged)}
        elseif ($node.lastPinged.GetType().Name -eq "DateTime") { $node.lastPinged = [DateTimeOffset]$node.lastPinged }
        
        if ($node.lastPinged -gt [DateTimeOffset]::Now) { $node.lastPinged = [DateTimeOffset]::Now }

        if ($node.startedAt.GetType().Name -eq "DateTime") { $node.startedAt = [DateTimeOffset]$node.startedAt }
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

function Compact
{
    param($id)
    return $id.Substring(0,4) + "-" + $id.Substring($id.Length-2)
}

function GetNodeName{
    param ($config, $id)
    $nodeName = ($config.WellKnownNodes | Select-Object -ExpandProperty $id)
    $cid = Compact($id)
    if ([String]::IsNullOrEmpty($nodeName)) { $nodeName = $cid }
    elseif (-not $config.HideNodeId) { $nodeName += " (" + $cid + ")" }
    return $nodeName
}

function GetSatName{
    param ($config, $id, $url)

    $wellKnownSat = @{
        "118UWpMCHzs6CvSgWd9BfFVjw5K9pZbJjkfZJexMtSkmKxvvAW" = "stefan-benten";
        "12EayRS2V1kEsWESU9QMRseFhdxYxKicsiFmxrsLZHeLUtdps3S" = "us-central-1";
        "121RTSDpyNZVcEU84Ticf2L1ntiuUimbWgfATz21tuvgk3vzoA6" = "asia-east-1";
        "12L9ZFwhzVpuEKMUNUqkaTLGzwY9G24tbiigLiXpmZWKwmcNDDs" = "europe-west-1";
        "1wFTAgs9DP5RSnCqKV1eLf6N9wtk4EAtmN5DpSxcs8EjT69tGE"  = "saltlake";
        "12rfG3sh9NCWiX3ivPjq2HtdLmbqCrvHVEzJubnzFzosMuawymB" = "europe-north-1"
    }
    
    $name = $wellKnownSat[$id] 
    if (($null -eq $name) -and ($null -ne $url)) {
        $point = $url.IndexOf(":")
        if ($point -gt 0) { $name = $url.Substring(0, $point) }
    }
    
    if ($null -eq $name) { $name = Compact($id) }
    elseif (-not $config.HideNodeId) {$name+= " (" + (Compact($id)) + ")"}
    Write-Output $name
}

function GetJobResultNormal {
    param ([System.Collections.Generic.List[[InProcess.InMemoryJob]]] $waitList, $timeoutSec)

    $start = [System.DateTimeOffset]::Now
    while (($waitList.Count -gt 0) -and (([System.DateTimeOffset]::Now - $start).TotalSeconds -le $timeoutSec)) {
        $completed = $waitList | Where-Object { $_.IsFinishedState() }
        $completed | ForEach-Object {
            if ($_.Error.Count -gt 0 ) { Write-Error $_.Error[0] }
            elseif( $_.Output.Count -eq 1 ) { Write-Output $_.Output[0] }
            else { Write-Error ("Bad output from {0}" -f $_.Name) }
            $waitList.Remove($_) | Out-Null
        }
    }
    if ($waitList.Count -gt 0) { Write-Error "Some jobs hang" }
}

function GetJobResultFailSafe {
    param ([System.Collections.Generic.List[[InProcess.InMemoryJob]]] $waitList, $timeoutSec)
    
    $start = [System.DateTimeOffset]::Now
    $timeoutTry =  [TimeSpan]::FromSeconds(([double]$timeoutSec) / ($waitList.Count + 1)) 
    
    while (($waitList.Count -gt 0) -and (([System.DateTimeOffset]::Now - $start).TotalSeconds -le $timeoutSec)) {
        for($i=$waitList.Count-1; $i -ge 0; $i--)
        {
            $job = $waitList[$i]
            if ($job.WaitJob($timeoutTry)) {
                $waitList.Remove($job) | Out-Null
                if ($job.Error.Count -gt 0 ) { 
                    if ($job.Error[0].Exception.Message -match "operation was canceled") { 
                        Write-Error ("timeout canceled {0}" -f $job.Name) -ErrorAction Continue 
                    }
                    else { Write-Error $job.Error[0] -ErrorAction Continue }
                }
                elseif( $job.Output.Count -eq 1 ) { Write-Output $job.Output[0] }
                else { Write-Error ("Bad output from {0}" -f $_.Name) -ErrorAction Continue }
            }
        }
    }
    if ($waitList.Count -gt 0) { Write-Error "Some jobs hang" }
}

function GetDailyTimeline
{
    param($daily)
    $rest = $daily | Group-Object intervalStart
    $timeline = New-Object "System.Collections.Generic.SortedList[int, long]"
    $rest | ForEach-Object {
        $key = [DateTime]::Parse($_.Name).Day
        $valueDec = ($_.Group | Measure-Object -Sum atRestTotal).Sum
        $value = [long]([System.Math]::Ceiling($valueDec))
        $timeline.Add($key, $value)
    }
    return $timeline
}

#Debug 
function QueryNode
{
    param($address, $config, $query)

    $dash = $null
    try {
        if ($null -eq $config) {Write-Error "Bad config in QueryNode"}
        $dash = GetJson -uri ("http://{0}/api/sno" -f $address) -timeout $config.TimeoutSec

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
        $dash | Add-Member -NotePropertyName Payments -NotePropertyValue ([System.Collections.Generic.List[PSCustomObject]]@())
        $dash | Add-Member -NotePropertyName Held -NotePropertyValue $null
        $dash | Add-Member -NotePropertyName Paid -NotePropertyValue $null

        $satResult = [System.Collections.Generic.List[PSCustomObject]]@()

        if ($query.Parallel) {
            $waitList = New-Object System.Collections.Generic.List[[InProcess.InMemoryJob]]
            $dash.satellites | ForEach-Object {
                $satid = $_.id
                $job = StartWebRequest -Name ("SatQueryJob node {0}, sat {1}" -f $name, $satid) -Address ("http://{0}/api/sno/satellite/{1}" -f $address, $satid) -Timeout $config.TimeoutSec
                $waitList.Add($job)
            }
            GetJobResultFailSafe -waitList $waitList -timeoutSec $config.TimeoutSec | ForEach-Object { $satResult.Add($_) }
        }
        else {
            $dash.satellites | ForEach-Object {
                $satid = $_.id
                $t = [System.DateTimeOffset]::Now
                try 
                {
                    Write-Host -NoNewline ("query {0} sat {1}..." -f $address, $satid)
                    $sat = GetJson -uri ("http://{0}/api/sno/satellite/{1}" -f $address, $satid) -timeout $config.TimeoutSec
                    $satResult.Add($sat)
                    Write-Host ("completed {0} sec" -f ([int](([System.DateTimeOffset]::Now - $t).TotalSeconds)))
                }
                catch [System.OperationCanceledException] {
                    Write-Host -ForegroundColor Red ("Timeout canceled node {0} sat {1}, {2} sec" -f $name, $satid, ([int](([System.DateTimeOffset]::Now - $t).TotalSeconds)))
                }
                catch {
                    Write-Error ($_.Exception.Message)
                }
            }
        }

        $satResult | ForEach-Object {
            $sat = $_
            $dashSat = $dash.satellites | Where-Object { $_.id -eq $sat.id }
            FixDateSat -sat $sat
            if ($sat.bandwidthDaily.Length -gt 0) {
                $sat.bandwidthDaily = FilterBandwidth -bw $sat.bandwidthDaily -query $query
            }

            $now = [DateTimeOffset]::UtcNow
            $age =  (($now.Month - $sat.nodeJoinedAt.Month) + 12 * ($now.Year - $sat.nodeJoinedAt.Year))
            $rest = GetDailyTimeline -daily $sat.storageDaily
            $restTotal = ($rest.Values | Measure-Object -Sum).Sum
            
            $sat | Add-Member -NotePropertyName Url -NotePropertyValue ($dashSat.url)
            $sat | Add-Member -NotePropertyName Name -NotePropertyValue (GetSatName -config $config -id $sat.id -url $sat.url)
            $sat | Add-Member -NotePropertyName NodeName -NotePropertyValue $name
            $sat | Add-Member -NotePropertyName Dq -NotePropertyValue ($dashSat.disqualified)
            $sat | Add-Member -NotePropertyName Susp -NotePropertyValue ($dashSat.suspended)
            $sat | Add-Member -NotePropertyName Age -NotePropertyValue $age
            $sat | Add-Member -NotePropertyName RestByDay -NotePropertyValue $rest
            $sat | Add-Member -NotePropertyName RestByDayTotal -NotePropertyValue $restTotal
            $dash.Sat.Add($sat)
        }

        $dash.PSObject.Properties.Remove('satellites')            
    }
    catch {
        Write-Error ("Node on address {0} fail: {1}" -f $address, $_.Exception.Message )
    }

    #Get payment info
    if (($null -ne $dash) -and ($null -ne $config.Payout)) {
        try {
            #$pays = ((Invoke-WebRequest -Uri  http://192:4401/api/heldamount/paystubs/2019-02/2020-05).content | ConvertFrom-Json)
            $earlest = ($dash | Select-Object -ExpandProperty Sat | Measure-Object -Minimum nodeJoinedAt).Minimum
            $paym = GetJson -uri ("http://{0}/api/heldamount/paystubs/{1}/{2}" -f `
                $address, `
                ($earlest.Year.ToString() + "-" + $earlest.Month.ToString()), `
                ([System.DateTimeOffset]::Now.Year.ToString() + "-" + [System.DateTimeOffset]::Now.Month.ToString()) `
                ) -timeout $config.TimeoutSec
            
            if ($null -ne $paym) {
                $paym | Add-Member -NotePropertyName NodeId -NotePropertyValue $dash.nodeID
                $paym | Add-Member -NotePropertyName Node -NotePropertyValue $name
                $dash.Payments = $paym
                $dash.Held = ($paym | Measure-Object -Sum {$_.held - $_.disposed}).Sum
                $dash.Paid = ($paym | Measure-Object -Sum paid).Sum
            }
            else { 
                Write-Host -ForegroundColor Red ("Failed to get payment {0}: no data from satellite" -f $address )
            }
        }
        catch {
            Write-Error ("Failed to get payment {0}: {1}" -f $address, $_.Exception.Message )
        }
    }
    if ($null -ne $dash) { Write-Output $dash }
}

$init = 
[scriptblock]::Create(@"
function GetJson {$function:GetJson}
function Compact {$function:Compact}
function GetNodeName {$function:GetNodeName}
function GetSatName {$function:GetSatName}
function FixNode {$function:FixNode}
function FixDateSat {$function:FixDateSat}
function FilterBandwidth {$function:FilterBandwidth}
function GetJobResultNormal {$function:GetJobResultNormal}
function GetJobResultFailSafe {$function:GetJobResultFailSafe}
function StartWebRequest {$function:StartWebRequest}
function GetDailyTimeline {$function:GetDailyTimeline}
function QueryNode {$function:QueryNode}
"@)

function GetNodes
{
    param ($config, $query)
    $result = [System.Collections.Generic.List[PSCustomObject]]@()
    
    #Start get storj services versions
    $jobVersion = StartWebRequest -Name "StorjVersionQuery" -Address "https://version.storj.io" -Timeout $config.TimeoutSec

    if ($query.Parallel) {
        $waitList = New-Object System.Collections.Generic.List[[InProcess.InMemoryJob]]
        $config.Nodes | ForEach-Object {
            $address = $_
            $jobNode = Start-QueryNode -Name ("JobQueryNode[{0}]" -f $address) -InitializationScript $init -Address $address -Config $config -Query $query 
            $waitList.Add($jobNode)
        }
        GetJobResultFailSafe -waitList $waitList -timeoutSec $config.TimeoutSec | ForEach-Object { $result.Add($_)}
    }
    else {
        $config.Nodes | ForEach-Object {
            $address = $_
            $dash = QueryNode -address $address -config $config -query $query
            if ($null -ne $dash) { $result.Add($dash) }
        }
    }
    
    $jobVersion.WaitJob([TimeSpan]::FromSeconds(1)) | Out-Null
    if (-not $jobVersion.IsFinishedState()) { Write-Error "jobVersion hang" }
    elseif ($jobVersion.Error.Count -gt 0) { Write-Error $jobVersion.Error }
    elseif ($jobVersion.Output.Count -ne 1) { Write-Error "Bad output from jobVersion" }
    else {
        $satVer = $jobVersion.Output[0]
        $latest = $satVer.processes.storagenode.suggested.version
        $minimal = [String]::Join('.',  $satVer.Storagenode.major.ToString(), $satVer.Storagenode.minor.ToString(), $satVer.Storagenode.patch.ToString())
        Write-Host ("Latest storagenode version is {0}" -f $latest)
        $result | ForEach-Object { 
            $_.LastVersion = $latest 
            $_.MinimalVersion = $minimal 
        }
    }
    return $result.ToArray()
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
        [long]$repairIngress = 0
        [long]$repairEgress = 0
        [long]$auditEgress = 0
        $from = $null
        $to = $null
    }
    process {
        #egress
        $egress+= $item.egress.usage
        $repairEgress+=$item.egress.repair
        $auditEgress+=$item.egress.audit

        #ingress
        $ingress+=$item.ingress.usage
        $repairIngress+=$item.ingress.repair       


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
            'RepairIngress' = $repairIngress
            'RepairEgress' = $repairEgress
            'AuditEgress' = $auditEgress
            'MaxRepairBandwidth'= [Math]::Max($repairIngress, $repairEgress)
            'From'     = $from
            'To'       = $to
        }
        Write-Output (New-Object -TypeName PSCustomObject –Prop $p)
    }
}

function AggPayments
{
    [CmdletBinding()]
    Param(
          [Parameter(ValueFromPipeline)]
          $item
         )    
    begin {
        [long]$usageAtRest = 0
        [long]$usageGet = 0
        [long]$usagePut = 0
        [long]$usageGetRepair = 0
        [long]$usagePutRepair = 0
        [long]$usageGetAudit = 0
        [long]$compAtRest = 0
        [long]$compGet = 0
        [long]$compPut = 0
        [long]$compGetRepair = 0
        [long]$compPutRepair = 0
        [long]$compGetAudit = 0
        [long]$surgePercentMin = 0
        [long]$surgePercentMax = 0
        [long]$held = 0
        [long]$owed = 0
        [long]$disposed = 0
        [long]$paid = 0
        $from = $null
        $to = $null

        [long]$maxearned = 0
    }
    process {
        $usageAtRest +=$item.usageAtRest
        $usageGet +=$item.usageGet
        $usagePut +=$item.usagePut
        $usageGetRepair +=$item.usageGetRepair
        $usagePutRepair +=$item.usagePutRepair
        $usageGetAudit +=$item.usageGetAudit
        $compAtRest +=$item.compAtRest
        $compGet +=$item.compGet
        $compPut +=$item.compPut
        $compGetRepair +=$item.compGetRepair
        $compPutRepair +=$item.compPutRepair
        $compGetAudit +=$item.compGetAudit
        $held +=$item.held
        $owed +=$item.owed
        $disposed +=$item.disposed
        $paid +=$item.paid

        if (($item.paid + $item.held - $item.disposed) -gt $maxearned) { $maxearned = ($item.paid + $item.held - $item.disposed)}

        $surgePercentMin = $null
        $surgePercentMax = $null
        $from = $null
        $to = $null
    }
    end {
        $p = @{
            'usageAtRest'       = $usageAtRest
            'usageGet'          = $usageGet
            'usagePut'          = $usagePut
            'usageGetRepair'    = $usageGetRepair
            'usagePutRepair'    = $usagePutRepair
            'usageGetAudit'     = $usageGetAudit
            'compAtRest'        = $compAtRest
            'compGet'           = $compGet
            'compPut'           = $compPut
            'compGetRepair'     = $compGetRepair
            'compPutRepair'     = $compPutRepair
            'compGetAudit'      = $compGetAudit
            'held'              = $held
            'owed'              = $owed
            'disposed'          = $disposed
            'paid'              = $paid
            'maxEarned'         = $maxearned
        }
        Write-Output (New-Object -TypeName PSCustomObject –Prop $p)
    }
}


function ConvertRepair
{
    [CmdletBinding()]
    Param(
          [Parameter(ValueFromPipeline)]
          $item
    )
    process {
        $p = @{
            'Ingress'  = $item.RepairIngress
            'Egress'   = $item.RepairEgress
            'TotalBandwidth'= $item.RepairIngress + $item.RepairEgress
            'MaxBandwidth'= $item.MaxRepairBandwidth
            'From'     = $item.From
            'To'       = $item.To
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
        $repairEgress = 0
        $auditEgress = 0
        $repairIngress = 0
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

        $repairEgress+=$item.RepairEgress
        $repairIngress+=$item.RepairIngress
        $auditEgress+=$item.AuditEgress

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
            'RepairEgress'  = $repairEgress
            'RepairIngress' = $repairIngress
            'AuditEgress'   = $auditEgress
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
            $commentMonitored = @()
            if ($null -ne $sat.Dq) { $commentMonitored += ("disqualified {0}" -f $sat.Dq) }
            if ($null -ne $sat.Susp) { $commentMonitored += ("suspended {0}" -f $sat.Susp) }

            $comment = @()
            if ($sat.audit.successCount -lt 100) { $comment += ("vetting {0}" -f $sat.audit.successCount) }

            $held = $null
            $paid = $null
            $codes = $null
            if ($null -ne $node.Payments) {
                $satPayments = ($node.Payments | Where-Object { $_.satelliteId -eq $sat.id })
                $held =  ($satPayments | Measure-Object -Sum held).Sum
                $paid = ($satPayments | Measure-Object -Sum paid).Sum

                $lastPaym = ($satPayments | Select-Object -Last 1)
                if ($null -ne $lastPaym) { $codes = $lastPaym.codes }
            }
    
            New-Object PSCustomObject -Property @{
                Key = ("{0}-{1}" -f $node.nodeID, $sat.id)
                NodeId = $node.nodeID
                NodeName = $node.Name
                SatelliteId = $sat.id
                SatelliteName = $sat.Name
                Audit = $sat.audit.score
                Uptime = ($sat.uptime.totalCount - $sat.uptime.successCount)
                Bandwidth = ($sat.bandwidthDaily | AggBandwidth)
                CommentMonitored = [String]::Join("; ", $commentMonitored)
                Joined = $sat.nodeJoinedAt
                Age = $sat.Age
                Comment = [String]::Join("; ", $comment)
                Codes = $codes
                Held = $held
                Paid = $paid
            }
        }
    }

    #calc per node bandwidth
    $score | Group-Object NodeId | ForEach-Object {
        $nodeId = $_.Name
        $node = $nodes | Where-Object {$_.NodeId -eq $nodeId} | Select-Object -First 1
        $bw = ($_.Group | Select-Object -ExpandProperty Bandwidth | AggBandwidth2)
        #$node.BwSummary = GetNodeSummary -bandwidth
        $node.BwSummary = $bw
        $node.Audit = ($_.Group | Select-Object -ExpandProperty Audit | Measure-Object -Min).Minimum
        $node.Uptime = ($_.Group | Select-Object -ExpandProperty Uptime | Measure-Object -Sum).Sum
    }

    $score
}

function Round
{
    param($value)
    return [Math]::Round($value * 100, 2)
}

function HumanBytes {
    param ([int64]$bytes, [switch]$dec)
    $suff = "bytes", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "IiB"
    $level = 0
    if ($dec) {
        $base = 1000
        for ($i = 1; $i -lt $suff.Length; $i++) {$suff = $suff.Replace("i","");}
    }
    else {$base = 1024}
    $rest = [double]$bytes
    while ([Math]::Abs($rest/$base) -ge 1) {
        $level++
        $rest = $rest/$base
    }
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
function HumanBaks {
    param ([long]$value)
    $rv = [Math]::Round([decimal]$value / 1000000, 2)
    if ($rv -lt 0.001) { return "0" }
    #TODO забыл, потом поправлю
    return ($rv.ToString().Replace(",","."))
}
function CheckNodes{
    param(
        $config, 
        $body,
        $newNodes,
        [ref]$oldNodesRef
    )
    $oldNodes = $oldNodesRef.Value

    #DEBUG drop some satellites and reset update
    #$newNodes = $newNodes | Select-Object -First 2
    #$newNodes[1].upToDate = $false

    # Check absent nodes
    $failNodes = ($oldNodes | Where-Object { ($newNodes | Select-Object -ExpandProperty nodeID) -notcontains $_.nodeID })
    if ($failNodes.Count -gt 0) {
        $failNodes | ForEach-Object {
            $nodeName = ( GetNodeName -config $config -id $_.nodeID  )
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

        if ($null -eq $old) { 
            if (-not [String]::IsNullOrEmpty($_.Name)) {
                Write-Output ("Node {0} back online" -f $_.Name) | Tee-Object -Append -FilePath $body
            }
            return 
        }

        $_.LastPingWarningValue = $old.LastPingWarningValue 
        $_.LastVerWarningValue = $old.LastVerWarningValue

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

        if ($_.version -ne $old.version) {
            Write-Output ("Node {0} updated from {1} to {2}" -f $_.Name, $old.version, $_.version) | Tee-Object -Append -FilePath $body
        }
    }
    $oldNodesRef.Value = $newNodes
}

function CheckScore{
    param(
        $config, 
        $body,
        $oldScore,
        $newScore
    )

    #DEBUG drop scores
    #$newScore[0].Audit = 0.2
    #$newScore[3].Uptime = 0.6

    $newScore | ForEach-Object {
        $new = $_
        $old = $oldScore | Where-Object { $_.Key -eq $new.Key }
        if ($null -ne $old){
            $idx = $oldScore.IndexOf($old)
            if ($old.Audit -ge ($new.Audit + $config.Threshold)) {
                Write-Output ("Node {0} down audit from {1} to {2} on {3}" -f $new.NodeName, $old.Audit, $new.Audit, $new.SatelliteId) | Tee-Object -Append -FilePath $body
                $oldScore[$idx].Audit = $new.Audit
            }
            elseif ($new.Audit -gt $old.Audit) { $oldScore[$idx].Audit = $new.Audit }

            if (($old.Uptime + $config.UptimeThreshold) -lt $new.Uptime) {
                Write-Output ("Node {0} fail uptime checks. Old value {1}, new {2} on {3}" -f $new.NodeName, $old.Uptime, $new.Uptime, $new.SatelliteId) | Tee-Object -Append -FilePath $body
                $oldScore[$idx].Uptime = $new.Uptime
            }

            if ($old.CommentMonitored -ne $new.CommentMonitored) {
                Write-Output ("Node {0} update comment for {1} to {2}. Old was {3}" -f $new.NodeName, $new.SatelliteName, $new.CommentMonitored, $old.CommentMonitored) | Tee-Object -Append -FilePath $body
                $oldScore[$idx].CommentMonitored = $new.CommentMonitored
            }

            if ($config.MonitorFullComment -and ($old.Comment -ne $new.Comment)) {
                Write-Output ("Node {0} update comment for {1} to {2}. Old was {3}" -f $new.NodeName, $new.SatelliteName, $new.Comment, $old.Comment) | Tee-Object -Append -FilePath $body
                $oldScore[$idx].Comment = $new.Comment
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
            $sb.AppendLine("<pre style='font: monospace; white-space: pre;'>") | Out-Null
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
        $mailParam = "--mime --content-type text/html -s '{0}' {1}" -f $config.Mail.Subj, $config.Mail.To
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
    $sb.AppendLine("<pre style='font: monospace; white-space: pre;'>") | Out-Null
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
        $newNodes = GetNodes -config $config
        $newScore = GetScore -nodes $newNodes
        CheckNodes -config $config -body $body -newNodes $newNodes -oldNodesRef ([ref]$oldNodes)
        CheckScore -config $config -body $body -oldScore $oldScore -newScore $newScore

        # Canopy warning
        #DEBUG check hour, must be 10
        if (($null -eq $config.Canary) -or ([System.DateTimeOffset]::Now.Day -ne $config.Canary.Day -and [System.DateTimeOffset]::Now.Hour -ge 10)) {
            $config.Canary = [System.DateTimeOffset]::Now
            Write-Output ("storj3monitor is alive {0}" -f $config.Canary) | Tee-Object -Append -FilePath $body
            #$bwsummary_old = ($newNodes | Select-Object -ExpandProperty BwSummary | AggBandwidth2)
            $bwsummary = GetSummary -nodes $newNodes

            DisplayScore -score $newScore -bwsummary $bwsummary >> $body
            DisplayTraffic -nodes $newNodes -config $config >> $body
            DisplayNodes -nodes $newNodes -bwsummary $bwsummary -config $config >> $body
            DisplayFooter -nodes $newNodes -bwsummary $bwsummary -config $config >> $body
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
    param ($width, [int64]$max, [int64]$current, [int64]$maxg = $null, [bool]$condition = $true)

    if (-not $condition) { return "" }

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
    param ($nodes, $bwsummary, $config)
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "N O D E S    S U M M A R Y"

    if ($null -eq $bwsummary) {
        $bwsummary = ($nodes | Select-Object -ExpandProperty BwSummary | AggBandwidth2)
    }

    $latest = $nodes | Where-Object {$null -ne $_.LastVersion } | Select-Object -ExpandProperty LastVersion -First 1
    $minimal = $nodes | Where-Object {$null -ne $_.MinimalVersion } | Select-Object -ExpandProperty MinimalVersion -First 1

    $nodes | Group-Object Version | ForEach-Object {
        Write-Host -NoNewline ("storagenode version {0}" -f $_.Name)
        $tab = [System.Collections.Generic.List[PSCustomObject]]@()
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

        $_.Group | Sort-Object Name | ForEach-Object {
            $p = @{
                "Node"      = $_.Name
                "Runtime"   = ([int](([DateTimeOffset]::Now - [DateTimeOffset]$_.startedAt).TotalHours))
                "Ping"      = ([DateTimeOffset]::Now - $_.lastPinged)
                "Audit"     = Round($_.Audit)
                "Uptime"   = $_.Uptime
                "Used"      = $_.diskSpace.used
                "Available" = $_.diskSpace.available
                "Egress"    = $_.BwSummary.Egress
                "Ingress"   = $_.BwSummary.Ingress
                "Held"      = $_.Held
                "Paid"      = $_.Paid
            }
            $tab.Add((New-Object -TypeName PSCustomObject –Prop $p))
        }

        if ($null -ne $config.Payout) {
            $tab | Format-Table -AutoSize `
            @{n="Node"; e={$_.Node}}, `
            @{n="Runtime"; e={$_.Runtime}}, `
            @{n="Ping"; e={HumanTime($_.Ping)}}, `
            @{n="Audit"; e={$_.Audit}}, `
            @{n="UptimeF"; e={$_.Uptime}}, `
            @{n="[ Used  "; e={HumanBytes($_.Used)}}, `
            @{n="Disk                  "; e={("{0}" -f ((GetPips -width 20 -max $_.Available -current $_.Used)))}}, `
            @{n="Free ]"; e={HumanBytes(($_.Available - $_.Used))}}, `
            @{n="Egress"; e={("{0} ({1})" -f ((GetPips -width 10 -max $bwsummary.Egress -maxg $bwsummary.EgressMax -current $_.Egress)), (HumanBytes($_.Egress)))}}, `
            @{n="Ingress"; e={("{0} ({1})" -f ((GetPips -width 10 -max $bwsummary.Ingress -maxg $bwsummary.IngressMax -current $_.Ingress)), (HumanBytes($_.Ingress)))}}, `
            @{n="($) Held"; e={HumanBaks(($_.Held))}}, `
            @{n="Paid"; e={HumanBaks(($_.Paid))}}, `
            @{n="Earned                "; e={("{0} {1}" -f ((GetPips -width 20 -max ($bwsummary.MaxNodeEarned) -current ($_.Held + $_.Paid)), (HumanBaks(($_.Held + $_.Paid)))))}} `
            | Out-String -Width 200
        }
        else {
            $tab | Format-Table -AutoSize `
            @{n="Node"; e={$_.Node}}, `
            @{n="Runtime"; e={$_.Runtime}}, `
            @{n="Ping"; e={HumanTime($_.Ping)}}, `
            @{n="Audit"; e={$_.Audit}}, `
            @{n="UptimeF"; e={$_.Uptime}}, `
            @{n="[ Used  "; e={HumanBytes($_.Used)}}, `
            @{n="Disk                  "; e={("{0}" -f ((GetPips -width 20 -max $_.Available -current $_.Used)))}}, `
            @{n="Free ]"; e={HumanBytes(($_.Available - $_.Used))}}, `
            @{n="Egress"; e={("{0} ({1})" -f ((GetPips -width 10 -max $bwsummary.Egress -maxg $bwsummary.EgressMax -current $_.Egress)), (HumanBytes($_.Egress)))}}, `
            @{n="Ingress"; e={("{0} ({1})" -f ((GetPips -width 10 -max $bwsummary.Ingress -maxg $bwsummary.IngressMax -current $_.Ingress)), (HumanBytes($_.Ingress)))}} `
            | Out-String -Width 200
        }
    }

    $vetting = $nodes | Select-Object -ExpandProperty Sat `
    | Where-Object { $_.audit.totalCount -lt 100 } `
    | Sort-Object -Descending {$_.audit.totalCount} `
    | Select-Object @{ Name = 'Audit count';  Expression =  { $_.audit.totalCount }}, @{ Name = 'Node'; Expression = { $_.NodeName }}, @{ Name = 'on Sat'; Expression = { $_.Name }}

    if ($vetting.Count -gt 0) {
        $top = $vetting | Select-Object -First 5
        Write-Output ("Top {0} of {1} vettings:" -f $top.Count, $vetting.Count)
        $top | Format-Table
    }
}

function GetHeldPercent
{
    param ($age)
    if ($age -lt 4) { return 0.75 }
    elseif ($age -lt 7) { return 0.5 }
    elseif ($age -lt 10) { return 0.25 }
    else { return 0 }
}

function DisplayFooter {
    param ($nodes, $bwsummary, $config)

    #special symbol 💵
    GraphDailyTimeline -title "Day earnings" -timeline $bwsummary.PayByDay -nodesCount $nodes.Count -unit "baks"
    if ($bwsummary.PayByDay.Count -gt 1) {
        $nm = ([DateTime]::Now).AddMonths(1)
        $days = ((Get-Date -Year $nm.Year -Month $nm.Month -Day 1).AddDays(-1).Day)
        $dc = $bwsummary.PayByDay.Count -1
        $avg = (($bwsummary.PayByDay.Values | Select-Object -First $dc) | Measure-Object -Sum).Sum / $dc
        $est = $days * $avg
        Write-Output (" - estimate at the end of the month {0:N2}" -f $est)
    }
    Write-Output ""

    Write-Output ("Stat time {0:yyyy.MM.dd HH:mm:ss (UTCzzz)}" -f [DateTimeOffset]::Now)

    $used = ($nodes.diskspace.used | Measure-Object -Sum).Sum
    $avail = ($nodes.diskspace.available | Measure-Object -Sum).Sum

    $today = $nodes | Select-Object -ExpandProperty Sat | Select-Object -ExpandProperty bandwidthDaily | Where-Object {$_.intervalStart.UtcDateTime.Date -eq [DateTimeOffset]::UtcNow.UtcDateTime.Date} | AggBandwidth 

    Write-Output ("Today bandwidth {0} - {1} Egress, {2} Ingress, include repair and audit {3} Egress, {4} Ingress" -f 
        (HumanBytes($today.Egress + $today.RepairEgress + $today.AuditEgress + $today.Ingress + $today.RepairIngress)), 
        (HumanBytes($today.Egress + $today.RepairEgress + $today.AuditEgress)), 
        (HumanBytes($today.Ingress + $today.RepairIngress)),
        (HumanBytes($today.RepairEgress + $today.AuditEgress)), 
        (HumanBytes($today.RepairIngress))
        #,(HumanBytes($today.Delete))
    )

    Write-Output ("Total bandwidth {0} - {1} Egress, {2} Ingress, include repair and audit {3} Egress, {4} Ingress" -f 
    (HumanBytes($bwsummary.Egress  + $bwsummary.RepairEgress + $bwsummary.AuditEgress + $bwsummary.Ingress + $bwsummary.RepairIngress)), 
    (HumanBytes($bwsummary.Egress  + $bwsummary.RepairEgress + $bwsummary.AuditEgress)), 
    (HumanBytes($bwsummary.Ingress + $bwsummary.RepairIngress)),
    (HumanBytes($bwsummary.RepairEgress + $bwsummary.AuditEgress)), 
    (HumanBytes($bwsummary.RepairIngress))
    #,(HumanBytes($bwsummary.Delete))
    )

    Write-Output ("Total storage {0}; used {1}; available {2}" -f (HumanBytes($avail)), (HumanBytes($used)), (HumanBytes($avail-$used)))

    Write-Host
    Write-Output ("From {0:yyyy.MM.dd} to {1:yyyy.MM.dd} on {2} nodes" -f 
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
    Write-Output ""

    if ($null -ne $config.Payout) { 
        #priceModel       : @{EgressBandwidth=2000; RepairBandwidth=1000; AuditBandwidth=1000; DiskSpace=150}        
        $nm = ([DateTime]::Now).AddMonths(1)
        $hours = ((Get-Date -Year $nm.Year -Month $nm.Month -Day 1).AddDays(-1).Day) * 24

        #$nodes | Select-Object -ExpandProperty Sat | Select-Object -ExpandProperty bandwidthDaily

        #TODO add R&A
        $currentPayments = $nodes | Select-Object -ExpandProperty Sat | ForEach-Object { 
            $agb = $_.BandwidthDaily | AggBandwidth
            New-Object PSCustomObject -Property @{
                Node = $_.NodeName
                Sat = $_.Name
                Age = $_.Age
                HeldPercent =(GetHeldPercent -age $_.Age)
                RestByDayTotal = $_.RestByDayTotal
                Disk = $_.RestByDayTotal  / 1000000 / $hours * 1.50
                Egress = ($_.egressSummary - $agb.RepairEgress - $agb.AuditEgress ) / 1000000 * 20.0
                RA = ($agb.RepairEgress + $agb.AuditEgress) / 1000000 * 10.0
                Earned = 0
                Held = 0
                Paid = 0
            }
        }
        $currentPayments | ForEach-Object {
            $_.Earned = $_.Disk + $_.Egress + $_.RA
            $_.Held = $_.Earned * $_.HeldPercent
            $_.Paid = $_.Earned - $_.Held
        }

        $disk = (HumanBaks -value (($currentPayments | Measure-Object -Sum Disk).Sum))
        $egress = (HumanBaks -value (($currentPayments | Measure-Object -Sum Egress).Sum))
        $ra = (HumanBaks -value (($currentPayments | Measure-Object -Sum RA).Sum))
        $earned = (HumanBaks -value (($currentPayments | Measure-Object -Sum Earned).Sum))
        $held = (HumanBaks -value (($currentPayments | Measure-Object -Sum Held).Sum))
        $paid = (HumanBaks -value (($currentPayments | Measure-Object -Sum Paid).Sum))

        Write-Output ("Current month earnings {0}$ - {1}$ held, {2}$ paid ({3}$ storage, {4}$ egress, {5}$ R&A)" -f $earned, $held, $paid, $disk, $egress, $ra)

        if ($null -ne $bwsummary.EtherSum -and $bwsummary.EtherSum -gt 0) { $tokens = ("({0} STORJ)" -f [Math]::Round($bwsummary.EtherSum,0)) }
        else { $tokens = "" }
        Write-Output ("Total earned {0}$ - held {1}$; paid {2}$ {3}" -f (HumanBaks($bwsummary.HeldAcc + $bwsummary.Paid)), (HumanBaks($bwsummary.HeldAcc)), (HumanBaks($bwsummary.Paid)), $tokens)
        Write-Output ""
    }

    $failedNodesCount = ($config.Nodes.Count - $nodes.Count)
    if ($failedNodesCount -gt 0) {
        $respond = ($nodes | Select-Object -ExpandProperty Address)
        $failed = $config.Nodes | Where-Object {$respond -notcontains $_}
        Write-Output ""
        Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        if ($failedNodesCount -eq 1) {
            Write-Output ("NODE ON ADDRESS {0} DOES NOT RESPOND" -f $failed)
        }
        else {
            Write-Output ("{0} NODES DOES NOT RESPOND: " -f $failedNodesCount)
            $failed | ForEach-Object { 
                Write-Output ("`tNODE ON ADDRESS {0}" -f $_)
            }
        }
        Write-Output "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        Write-Output ""
    }
}

function DisplayScore {
    param ($score, $bwsummary)
    Write-Host
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "S A T E L L I T E S    D E T A I L S"

    $tab = [System.Collections.Generic.List[PSCustomObject]]@()
    $score | Sort-Object SatelliteId, NodeName | ForEach-Object {

        $comment = @() 
        if (-not [String]::IsNullOrEmpty($_.CommentMonitored)) { $comment += $_.CommentMonitored}
        if (-not [String]::IsNullOrEmpty($_.Comment)) { $comment += $_.Comment}

        $p = @{
            'Satellite' = $_.SatelliteName
            'Node'      = $_.NodeName
            'Ingress'   = ("{0} {1}" -f (GetPips -width 10 -max $bwsummary.Ingress -maxg $bwsummary.IngressMax -current $_.Bandwidth.Ingress), (HumanBytes($_.Bandwidth.Ingress)))
            'Egress'    = ("{0} {1}" -f (GetPips -width 10 -max $bwsummary.Egress -maxg $bwsummary.EgressMax -current $_.Bandwidth.Egress), (HumanBytes($_.Bandwidth.Egress)))
            #'Delete'    = ("{0} {1}" -f (GetPips -width 10 -max $bwsummary.Delete -maxg $bwsummary.DeleteMax -current $_.Bandwidth.Delete), (HumanBytes($_.Bandwidth.Delete)))
            'Audit'     = Round($_.Audit)
            'UptimeF'   = $_.Uptime
            'Joined'    = ("{0:yyyy-MM-dd} ({1,2})" -f $_.Joined, $_.Age)
            'Held'      = HumanBaks($_.Held)
            'Paid'      = HumanBaks($_.Paid)
            'Codes'     = $_.Codes
            'Comment'   = "- " + [String]::Join("; ", $comment)
        }
        $tab.Add((New-Object -TypeName PSCustomObject –Prop $p))
    }

    if ($null -ne $config.Payout) { 
        $tab.GetEnumerator() | Format-Table -AutoSize Satellite, Node, Joined, Ingress, Egress, Audit, UptimeF, Held, Paid, Codes, Comment | Out-String -Width 200
    }
    else {
        $tab.GetEnumerator() | Format-Table -AutoSize Satellite, Node, Ingress, Egress, Audit, UptimeF, Comment | Out-String -Width 200
    }
    Write-Host
}

function GraphTimelineDirect
{
    param ($title, $decription, [int]$height, $bandwidth, $query, $nodesCount, $config)
    $bd = $bandwidth | Group-Object {$_.intervalStart.Day}
    $timeline = New-Object "System.Collections.Generic.SortedList[int, PSCustomObject]"
    $bd | ForEach-Object { $timeline.Add([Int]::Parse($_.Name), ($_.Group | AggBandwidth)) }
    GraphTimeline -title $title -decription $decription -height $height -timeline $timeline -query $query -nodesCount $nodesCount -config $config
}

function GraphTimelineRepair
{
    param ($title, $decription, [int]$height, $bandwidth, $query, $nodesCount, $config)
    $bd = $bandwidth | Group-Object {$_.intervalStart.Day}
    $timeline = New-Object "System.Collections.Generic.SortedList[int, PSCustomObject]"
    $bd | ForEach-Object { $timeline.Add([Int]::Parse($_.Name), ($_.Group | AggBandwidth | ConvertRepair)) }
    GraphTimeline -title $title -decription $decription -height $height -timeline $timeline -query $query -nodesCount $nodesCount -config $config
}

function GraphTimeline
{
    param ($title, $decription, [int]$height, $timeline, $query, $nodesCount, $config)
    if ($height -eq 0) { $height = 10 }

    #max in groups while min in original data. otherwise min was zero in empty data cells
    $firstCol = ($timeline.Keys | Measure-Object -Minimum).Minimum
    $lastCol = ($timeline.Keys | Measure-Object -Maximum).Maximum
    
    #data bounds
    if ($config.GraphStart -eq "zero") {$dataMin = 0}
    elseif ($config.GraphStart -eq "minbandwidth") {
        $dataMin = ($timeline.Values | Measure-Object -Minimum -Property MaxBandwidth).Minimum
    }
    else {throw "Bad graph start config value"}
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
                    if (($hi -ge $r) -and ($he -ge $r)) { $line+="ie " }
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
        
        if ($null -eq $first) { 
            $graph.Add($line) 
            #allow skips only for full month
            if ($null -eq $query.Days) { $first = $line }
        }
        elseif ($null -ne $first)
        {
            if ($line -eq $first) { $skip++ }
            else {
                $graph.Add($line)
                $first = "xxx"
            }
        }
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

    $totalEgress = ($timeline.Values | Measure-Object -Sum Egress).Sum
    $totalIngress = ($timeline.Values | Measure-Object -Sum Ingress).Sum
    Write-Host (" - bandwidth total {0} egress, {1} ingress" -f (HumanBytes($totalEgress)), (HumanBytes($totalIngress)))
    
    Write-Host
    Write-Host
}

function GraphRest
{
    param ($summary)
    GraphDailyTimeline -title "Disk space used this month" -timeline $summary.RestByDay -nodesCount $summary.NodesCount -unit "bytes"
    Write-Output ""
}


function GraphDailyTimeline
{
    param ($title, $timeline, $nodesCount, $unit)
    $height = 10

    #max in groups while min in original data. otherwise min was zero in empty data cells
    $firstCol = ($timeline.Keys | Measure-Object -Minimum).Minimum
    $lastCol = ($timeline.Keys | Measure-Object -Maximum).Maximum
    
    #data bounds
    $dataMin = 0
    $dataMax = ($timeline.Values | Measure-Object -Maximum).Maximum

    if (($null -eq $dataMax) -or ($dataMax -eq 0)) { 
        Write-Output ("{0}: no data" -f $title)
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


    1..$height | ForEach-Object {
        $r = $_
        $line = "│"
        $firstCol..$lastCol | ForEach-Object {
            $c = $_
            $v = $timeline[$c]
            $h = $v / $rowWidth
            if ($h -ge $r ) {
                $line+="-- "
                #if ($unit -eq "baks") {$line+="💵 "}
                #else { $line+="-- " }
            }
            else {$line+="   "}
        }
        $graph.Add($line) 
    }
    $graph.Reverse()

    Write-Output $title #-NoNewline #-ForegroundColor Yellow
    if (-not [String]::IsNullOrEmpty($decription)) { Write-Output (" - {0}" -f $decription) }
    if ($unit -eq "bytes") {
        Write-Output ("Y-axis from {0} to {1}h; cell = {2}h; {3} nodes" -f (HumanBytes -bytes $dataMin -dec), (HumanBytes -bytes $dataMax -dec), (HumanBytes -bytes $rowWidth -dec), $nodesCount) 
    }
    else {
        Write-Output ("Y-axis from {0} to {1:N2}; cell = {2:N2}; {3} nodes" -f $dataMin, $dataMax, $rowWidth, $nodesCount)
    }
    $graph | ForEach-Object {Write-Output $_}
  
    $total = ($timeline.Values | Measure-Object -Sum).Sum
    if ($unit -eq "bytes") {
        Write-Output (" - total {0}h" -f ( HumanBytes -bytes $total -dec ) )
    }
    else {
        Write-Output (" - total {0:N2}" -f $total)
    }
}


function DisplaySat {
    param ($nodes, $bw, $query, $config)
    Write-Host
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "S A T E L L I T E S   B A N D W I D T H"
    Write-Host "Legenda:"
    Write-Host "`ti `t-ingress"
    Write-Host "`te `t-egress"
    Write-Host "`t= `t-pips from all bandwidth"
    Write-Host "`t- `t-pips from bandwidth of maximum node, or simple percent line"
    Write-Host "`t* n `t-down line supressed n times"
    Write-Host
    $now = [System.DateTimeOffset]::UtcNow
    ($nodes | Select-Object -ExpandProperty Sat) | Group-Object id | ForEach-Object {
        #Write-Host $_.Name
        $sat = $_
        $bw = $sat.Group | Select-Object -ExpandProperty bandwidthDaily | Where-Object { ($_.IntervalStart.Year -eq $now.Year) -and ($_.IntervalStart.Month -eq $now.Month)}
        $title = ("{0} ({1})" -f  $sat.Group[0].Url, $sat.Name)
        GraphTimelineRepair -title ('Repair ' + $title) -bandwidth $bw -query $query -nodesCount $nodes.Count -config $config
        GraphTimelineDirect -title $title -bandwidth $bw -query $query -nodesCount $nodes.Count -config $config

        # Display storage graph for this satellite
        $daily =  $sat.Group | Select-Object -ExpandProperty Storagedaily | Where-Object { ($_.IntervalStart.Year -eq $now.Year) -and ($_.IntervalStart.Month -eq $now.Month)}
        $timeline = GetDailyTimeline -daily $daily
        $satrest = New-Object -TypeName PSCustomObject
        $satrest | Add-Member -NotePropertyName RestByDay -NotePropertyValue $timeline
        GraphRest -summary $satrest

        # Display payments for this satellite
        if ($null -ne $config.Payout) {
            $tab = [System.Collections.Generic.List[PSCustomObject]]@()
            $payments = $nodes | Select-Object -ExpandProperty Payments | Where-Object { $_.satelliteId -eq $sat.Name }
            $paymentsByNode = $payments | Group-Object Node

            $paymentsByNode | ForEach-Object {
                $np= $_
                $npp = $np.Group | AggPayments
                $p = @{
                    'Count'                = $np.Count
                    'Node'              = $np.Name
                    'Held'             = $npp.held
                    'Paid'             = $npp.paid
                    'Earned'    = $npp.held + $npp.paid

                }
                $tab.Add((New-Object -TypeName PSCustomObject –Prop $p))
            }
            $maxEarned = ($tab | Measure-Object -Maximum Earned).Maximum
            $sum = $payments | AggPayments

            
            $p = @{
                'Count' = $sum.Count
                'Node'  = "All nodes"
                'Held'  = $sum.held
                'Paid'  = $sum.paid
                'Earned'= $sum.held + $sum.paid
            }
            $tab.Add((New-Object -TypeName PSCustomObject –Prop $p))
            
            $tab | Format-Table -AutoSize `
                @{n="Node"; e={$_.Node}}, `
                @{n="Held"; e={HumanBaks($_.Held)}}, `
                @{n="Paid"; e={HumanBaks($_.Paid)}}, `
                @{n="Earned"; e={("{0}{1}" -f ((GetPips -width 20 -max $maxEarned -current $_.Earned -condition ($_.Node -ne "All nodes")), (HumanBaks($_.Earned))))}} `
            | Out-String -Width 200
        }

        $vetting = $sat.Group `
        | Where-Object { $_.audit.totalCount -lt 100 } `
        | Sort-Object -Descending {$_.audit.totalCount} `
        | Select-Object @{ Name = 'Audit count';  Expression =  { $_.audit.totalCount }}, @{ Name = 'Node'; Expression = { $_.NodeName }}
    
        if ($vetting.Count -gt 0) {
            $top = $vetting | Select-Object -First 5
            Write-Output ("Top {0} of {1} vetting nodes:" -f $top.Count, $vetting.Count)
            $top | Format-Table
        }

        ;
    
    }
    Write-Host
}
function DisplayTraffic {
    param ($nodes, $query, $config)
    $bw = $nodes | Select-Object -ExpandProperty Sat | Select-Object -ExpandProperty bandwidthDaily
    GraphTimelineRepair -title "Repair by days" -height 15 -bandwidth $bw -query $query -nodesCount $nodes.Count -config $config
    GraphTimelineDirect -title "Traffic by days" -height 15 -bandwidth $bw -query $query -nodesCount $nodes.Count -config $config
}

function GetFirstDate
{
    param($date)
    return New-Object DateTimeOffset((New-Object DateTime($date.Year, $date.Month, 1)), [TimeSpan]::Zero)
}

function GetFirstDateFromPeriod
{
    param($period)
    $pp = $period.Split('-')
    $year = [int]$pp[0]
    $month = [int]$pp[1]
    return New-Object DateTimeOffset((New-Object DateTime($year, $month, 1)), [TimeSpan]::Zero)
}

function QueryPayout {
    param ($nodes, $config)
    if ($null -eq $config.EtherscanKey) { throw "No EtherscanKey given in config. This is etherscan.io API key. Please got it."}

    if ($null -eq $config.Payout) { throw "No payouts queried" }
    elseif ($config.Payout -eq 0) { Write-Host "Query payments for current month..." }
    elseif ($config.Payout -eq -1) { Write-Host "Query all payments..." }
    else { Write-Host ("Query payments for last {0} months..." -f $config.Payout) }
    Write-Host

    $ethScanUrlTemplate = ("http://api.etherscan.io/api?module=account&action=tokentx&address=[address]&startblock=0&endblock=999999999&sort=asc&apikey={0}" -f $config.EtherscanKey)
    $addresses = $nodes | Select-Object -ExpandProperty wallet -Unique
    if (($null -eq $addresses) -or ($addresses.Count -eq 0) ) { throw "Fail to get wallet addresses from nodes"}

    $storj = $null
    $addresses | ForEach-Object {
        $address = $_
        $ethScanUrl = $ethScanUrlTemplate.Replace("[address]", $address)
        Write-Host ("Quering {0}" -f $address)

        $tnx = Invoke-WebRequest -Method Get -Uri $ethScanUrl | ConvertFrom-Json
        if ($tnx.message -ne "OK") {
            throw ("Error getting eth transactions: {0}" -f $tnx.message)
        }

        $tnx = $tnx.result | Where-Object {$_.tokenSymbol -eq "STORJ" -and $_.to -eq $address } | Select-Object -Property `
            @{name='from'; expression={$_.from}}, `
            @{name='date'; expression={[DateTimeOffset]::FromUnixTimeSeconds($_.timestamp)}}, `
            @{name='value'; expression={($_.value / ([Math]::Pow(10, $_.tokenDecimal)))}}
        if ($null -eq $storj) { $storj = $tnx }
        else { $storj = $storj += $tnx }
    }
    return $storj
}

function GetPayout {
    param ($nodes, $config)

    $storj = $null
    try {
        #Try load from cache
        if ( (-not $config.NoCache) `
            -and ($null -ne $config.MemFile) `
            -and [System.IO.File]::Exists($config.MemFile) `
            -and (([DateTime]::Now - [System.IO.File]::GetCreationTime($config.MemFile)).TotalHours -lt 1.0) `
            ){
                $Storj3MonitorMem = ([System.IO.File]::ReadAllText($config.MemFile) | ConvertFrom-Json)
                $storj = $Storj3MonitorMem.Etherscan
        }
    }
    catch {
        Write-Host -ForegroundColor Red $_.Exception.Message
    }

    if ($null -eq $storj) {
        #Query etherscan and cache result
        $storj = QueryPayout -nodes $nodes -config $config
        try {
            if ($null -ne $config.MemFile) {
                $Storj3MonitorMem = New-Object pscustomobject
                $Storj3MonitorMem | Add-Member -NotePropertyName Etherscan -NotePropertyValue $storj
                $memJson = ConvertTo-Json $Storj3MonitorMem
                [System.IO.File]::WriteAllText($config.MemFile, $memJson)
            }
        }
        catch {
            Write-Host -ForegroundColor Red $_.Exception.Message
        }
    }
    
    #Fix date issue for older powershell versions
    if (($null -ne $storj) -and ($storj.Count -gt 0) -and $storj[0].date.GetType().Name -ne "DateTimeOffset") {
        Write-Host "Converting DateTimes..."
        $storj | ForEach-Object { $_.date = [System.DateTimeOffset]($_.date)} 
    }
    
    $storj | ForEach-Object {
        $fd = GetFirstDate -date $_.date.AddMonths(-1)
        $period = ("{0}-{1:00}" -f $fd.Year, $fd.Month) 
        $_ | Add-Member -NotePropertyName Period -NotePropertyValue $period
    }

    $storjFiltered = $null
    if ($config.Payout -eq 0) { $storjFiltered = $storj | Where-Object {$_.date -ge (GetFirstDate -date ([DateTimeOffset]::Now))} }
    elseif ($config.Payout -gt 0) { $storjFiltered = $storj | Where-Object {$_.date -ge (GetFirstDate -date ([DateTimeOffset]::Now.AddMonths(($config.Payout * -1) + 1)))} }
    elseif ($config.Payout -eq -1) { $storjFiltered = $storj }
    else { throw "bad param -p (Payout)" }

    return $storjFiltered
}

function SafeRound()
{
    param ([double]$nominator, [double]$denominator, [int]$decimals)
    if ($denominator -eq 0) { return 0 }
    return [Math]::Round($nominator / $denominator, $decimals)
}

function GetPayments {
    param ($nodes, $config, $summary)
    $now = [System.DateTimeOffset]::UtcNow
   
    $ether = $null
    if ($true){
        try {
            $ether = GetPayout -nodes $nodes -config $config
        }
        catch {
            Write-Host -ForegroundColor Red $_.Exception.Message
            $ether = $null
        }
    }

    [long]$heldAcc=0
    $allp = ($nodes | Select-Object -ExpandProperty Payments | Group-Object period | Sort-Object Name)
    $data = [System.Collections.Generic.List[PSCustomObject]]@()
    $allp | ForEach-Object {
        $period = $_.Name
        $etherCount = 0
        $etherSum = 0
        if ($null -ne $ether) {
            $em = ($ether | Where-Object { $_.Period -eq $period } | Measure-Object -Sum value)
            $etherCount = $em.Count
            $etherSum = $em.Sum
        }

        $surgeMin = ($_.Group | Measure-Object -Min surgePercent).Minimum
        $surgeMax = ($_.Group | Measure-Object -Max surgePercent).Maximum
        if ($surgeMin -eq $surgeMax) { $surge = $surgeMin.ToString() }
        else { $surge = ("{0}-{1}" -f $surgeMin, $surgeMax) }

        #Any held amount payback. In this example graceful exit. It will also show the 50% payback in month 15
        $dispM = ($_.Group | Measure-Object -Sum disposed).Sum

        $heldM = ($_.Group | Measure-Object -Sum held).Sum
        $heldAcc += $heldM - $dispM

        #For pwsh 5
        #$gra = ($_.Group | Measure-Object -Sum { $_.usageGetRepair + $_.usageGetAudit}).Sum
        #$grap = ($_.Group | Measure-Object -Sum { $_.compGetRepair + $_.compGetAudit}).Sum

        $gra1 = ($_.Group | Measure-Object -Sum usageGetRepair).Sum
        $gra2 = ($_.Group | Measure-Object -Sum usageGetAudit).Sum
        $gra = $gra1 + $gra2

        $grap1 = ($_.Group | Measure-Object -Sum compGetRepair).Sum
        $grap2 = ($_.Group | Measure-Object -Sum compGetAudit).Sum
        $grap = $grap1 + $grap2

        $paid = ($_.Group | Measure-Object -Sum paid).Sum

        $storage = ($_.Group | Measure-Object -Sum usageAtRest).Sum
        $storagePayment = ($_.Group | Measure-Object -Sum compAtRest).Sum
        $ingress = ($_.Group | Measure-Object -Sum usagePut).Sum
        $egress = ($_.Group | Measure-Object -Sum usageGet).Sum
        $egressPayment = ($_.Group | Measure-Object -Sum compGet).Sum

        if ($data.Count -eq 0) { 
            $gF = 1.0 
            $gpF = 1.0
            $iF = 1.0
            $eF = 1.0
            $epF = 1.0
            $erF = 1.0
        }
        else { 
            $prev =  $data[$data.Count - 1]
            $gF = SafeRound -nominator $storage -denominator $prev.StorageAvgMonth -decimals 2
            $gpF = SafeRound -nominator $storagePayment -denominator $prev.StoragePayment -decimals 2
            $iF = SafeRound -nominator $ingress -denominator $prev.Put -decimals 2
            $eF = SafeRound -nominator $egress -denominator $prev.Get -decimals 2
            $epF = SafeRound -nominator $egressPayment -denominator $prev.GetPayment -decimals 2
            $erF = SafeRound -nominator ($paid + $heldM - $dispM) -denominator $prev.Earned -decimals 2
        }

        if ($egress -gt $ingress) { 
            if ($ingress -eq 0) { $dir = "[ > ]" }
            else { $dir = ("[ {0}> ]" -f ([Math]::Round([decimal]$egress / [decimal]$ingress, 2))) }
        }
        elseif ($egress -lt $ingress) { 
            if ($egress -eq 0) { $dir = "[ < ]" }
            else { $dir = ("[ <{0} ]" -f ([Math]::Round([decimal]$ingress / [decimal]$egress, 2))) }
        }
        else { $dir = "[ <=> ]" }

        $p = @{
            'Period'                = $period
            'FirstDate'             = (GetFirstDateFromPeriod -period $period)
            'RecordCount'           = $_.Count
            'StorageAvgMonth'       = $storage
            'gF'                    = $gF
            'gpF'                   = $gpF
            'StoragePayment'        = $storagePayment
            'Get'                   = $egress
            'GetPayment'            = $egressPayment
            'eF'                    = $eF
            'epF'                   = $epF
            'GetRepairAudit'        = $gra
            'GetRepairAuditPayment' = $grap
            'Put'                   = $ingress
            'PutPayment'            = ($_.Group | Measure-Object -Sum compPut).Sum
            'iF'                    = $iF
            'PutRepair'             = ($_.Group | Measure-Object -Sum usagePutRepair).Sum
            'PutRepairPayment'      = ($_.Group | Measure-Object -Sum compPutRepair).Sum
            'Dir'                   = $dir
            'Surge'                 = $surge
            'HeldThisMonth'         = $heldM #Held amount depending on the node age
            'HeldAcc'               = $heldAcc
            'Owed'                  = ($_.Group | Measure-Object -Sum owed).Sum #Payout reduced by held amount
            'Disposed'              = $dispM  
            'Paid'                  = $paid #Final payment for usage + held amount
            'Earned'                = $heldM + $paid - $dispM
            'erF'                   = $erF
            'EtherCount'            = $etherCount
            'EtherSum'              = $etherSum
        }
        $data.Add((New-Object -TypeName PSCustomObject –Prop $p)) | Out-Null
        $prev = $_
    }

    $fd = ($nodes | Select-Object -ExpandProperty Sat | Select-Object -ExpandProperty nodeJoinedAt | Measure-Object -Minimum).Minimum
    $dd = $data | Select-Object -ExpandProperty Period -Unique
    $absent = $ether | Where-Object { ($_.date -gt $fd) -and ($dd -notcontains $_.Period) }

    if ($absent.Count -gt 0) {
        $absent | Group-Object Period | ForEach-Object {
            $m = $_.Group | Measure-Object -Sum value
            $p = @{
                'Period'        = $_.Name
                'FirstDate'     = (GetFirstDateFromPeriod -period $_.Name)
                'RecordCount'   = 0
                'EtherCount'    = $_.Count
                'EtherSum'      = $m.Sum
            }
            $data.Add((New-Object -TypeName PSCustomObject –Prop $p)) | Out-Null
        }
        $data = ($data | Sort-Object Period)
    }

    [System.Collections.ArrayList]$dataFiltered = $null
    if ($config.Payout -eq 0) { $dataFiltered = $data | Where-Object {$_.Period -eq ("{0}-{1}" -f $now.Year, $now.Month)} }
    elseif ($config.Payout -gt 0) { $dataFiltered = @($data | Where-Object {$_.FirstDate -ge (GetFirstDate -date ([DateTimeOffset]::Now.AddMonths(($config.Payout * -1) + 1)))})}
    elseif ($config.Payout -eq -1) { $dataFiltered = $data }
    else { throw "bad param -p (Payout)" }

    if ($dataFiltered.Count -eq 0) {
        Write-Host "No payment data for given period"
        return
    }

    $sum_HeldM = ($dataFiltered | Measure-Object -Sum HeldThisMonth).Sum
    $sum_Disposed = ($dataFiltered | Measure-Object -Sum Disposed).Sum
    $paySummary = @{
        'Period'                = ("{0}m" -f ($dataFiltered | Measure-Object).Count)
        'RecordCount'           = ($dataFiltered | Measure-Object -Sum RecordCount).Sum
        'StorageAvgMonth'       = ($dataFiltered | Measure-Object -Sum StorageAvgMonth).Sum
        'StoragePayment'        = ($dataFiltered | Measure-Object -Sum StoragePayment).Sum
        'Get'                   = ($dataFiltered | Measure-Object -Sum Get).Sum
        'GetPayment'            = ($dataFiltered | Measure-Object -Sum GetPayment).Sum
        'GetRepairAudit'        = ($dataFiltered | Measure-Object -Sum GetRepairAudit).Sum
        'GetRepairAuditPayment' = ($dataFiltered | Measure-Object -Sum GetRepairAuditPayment).Sum
        'Put'                   = ($dataFiltered | Measure-Object -Sum Put).Sum
        'PutPayment'            = ($dataFiltered | Measure-Object -Sum PutPayment).Sum
        'PutRepair'             = ($dataFiltered | Measure-Object -Sum PutRepair).Sum
        'PutRepairPayment'      = ($dataFiltered | Measure-Object -Sum PutRepairPayment).Sum
        'Surge'                 = ""
        'HeldThisMonth'         = ""
        'HeldAcc'               = ($sum_HeldM - $sum_Disposed)
        'Owed'                  = ($dataFiltered | Measure-Object -Sum Owed).Sum
        'Disposed'              = $sum_Disposed
        'Paid'                  = ($dataFiltered | Measure-Object -Sum Paid).Sum
        'EtherCount'            = ($dataFiltered | Measure-Object -Sum EtherCount).Sum
        'EtherSum'              = ($dataFiltered | Measure-Object -Sum EtherSum).Sum
    }
    
    $storageMax = ($dataFiltered | Measure-Object -Maximum StorageAvgMonth).Maximum
    $storagePaymentMax = ($dataFiltered | Measure-Object -Maximum StoragePayment).Maximum

    $putMax = ($dataFiltered | Measure-Object -Maximum Put).Maximum
    
    $egressMax = ($dataFiltered | Measure-Object -Maximum Get).Maximum
    $egressPaymentMax = ($dataFiltered | Measure-Object -Maximum GetPayment).Maximum

    $earnedMax = ($dataFiltered | Measure-Object -Maximum Earned).Maximum

    
    $dataFiltered.Add((New-Object -TypeName PSCustomObject –Prop $PaySummary)) | Out-Null
    $summary | Add-Member $paySummary
    $summary | Add-Member -NotePropertyName StorageMaximum -NotePropertyValue $storageMax
    $summary | Add-Member -NotePropertyName StoragePaymentMaximum -NotePropertyValue $storagePaymentMax
    $summary | Add-Member -NotePropertyName IngressMaximum -NotePropertyValue $putMax
    $summary | Add-Member -NotePropertyName EgressMaximum -NotePropertyValue $egressMax
    $summary | Add-Member -NotePropertyName EgressPaymentMaximum -NotePropertyValue $egressPaymentMax
    $summary | Add-Member -NotePropertyName EarnedMaximum -NotePropertyValue $earnedMax

    return $dataFiltered
}

function DisplayPayments {
    param ($payments, $summary)
    Write-Host Payments
    $payments | Format-Table -AutoSize `
    @{n="Period"; e={$_.Period}}, `
    @{n="Count"; e={$_.RecordCount}}, `
    @{n="Surge"; e={$_.Surge}}, `
    @{n="Storage"; e={(HumanBytes -bytes $_.StorageAvgMonth -dec) + "m"}}, `
    @{n="Storage grow"; e={(GetPips -width 12 -max $summary.StorageMaximum -current $_.StorageAvgMonth -condition ($_.Period.IndexOf("-") -gt 0)) + $_.gF.ToString() }}, `
    @{n="Ingress"; e={(HumanBytes -bytes $_.Put -dec)}}, `
    @{n="Dir"; e={$_.Dir}}, `
    @{n="Egress"; e={(HumanBytes -bytes $_.Get -dec)}}, `
    @{n="R&A Egress"; e={(HumanBytes -bytes $_.GetRepairAudit -dec)}}, `
    @{n="Storage"; e={HumanBaks($_.StoragePayment)}}, `
    @{n="Egress"; e={HumanBaks($_.GetPayment)}}, `
    @{n="R&A"; e={HumanBaks($_.GetRepairAuditPayment)}}, `
    @{n="Owed"; e={HumanBaks($_.Owed)}}, `
    @{n="Disposed"; e={HumanBaks($_.Disposed)}}, `
    @{n="HeldAcc"; e={HumanBaks($_.HeldAcc)}}, `
    @{n="Held(month)"; e={HumanBaks($_.HeldThisMonth)}}, `
    @{n="Paid"; e={HumanBaks($_.Paid)}}, `
    @{n="Earned(month) "; e={("{0} {1}" -f ((GetPips -width 12 -max $summary.EarnedMaximum -current ($_.HeldThisMonth + $_.Paid - $_.Disposed) -condition ($_.Period.IndexOf("-") -gt 0)), (HumanBaks(($_.HeldThisMonth + $_.Paid - $_.Disposed)))))}}, `
    @{n="EtherCount"; e={$_.EtherCount}}, `
    @{n="EtherSum"; e={[Math]::Round($_.EtherSum, 2)}}
}

function DisplayRelativePayments {
    param ($payments, $summary)
    if ($null -ne $payments) {
        Write-Host Relative payments
        $payments | Where-Object {$_.Period.Contains("-") -and ($_.RecordCount -gt 0)} | Format-Table -AutoSize `
        @{n="Period"; e={$_.Period}}, `
        @{n="Surge"; e={$_.Surge}}, `
        @{n="Storage, gF"; e={(GetPips -width 14 -max $summary.StorageMaximum -current $_.StorageAvgMonth) + $_.gF.ToString() }}, `
        @{n="Storage payment"; e={(GetPips -width 14 -max $summary.StoragePaymentMaximum -current $_.StoragePayment) + $_.gpF.ToString()}}, `
        @{n="Ingress"; e={(GetPips -width 14 -max $summary.IngressMaximum -current $_.Put)  + $_.iF.ToString()}}, `
        @{n="Dir"; e={$_.Dir}}, `
        @{n="Egress"; e={(GetPips -width 14 -max $summary.EgressMaximum -current $_.Get) + $_.eF.ToString()}}, `
        @{n="Egress payment"; e={(GetPips -width 14 -max $summary.EgressPaymentMaximum -current $_.GetPayment) + $_.epF.ToString()}}, `
        @{n="Earned          "; e={(GetPips -width 14 -max $summary.EarnedMaximum -current ($_.HeldThisMonth + $_.Paid - $_.Disposed)) + $_.erF.ToString()}}
    }
}

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

    if ($cmdlineArgs.IndexOf("-np") -ge 0) { $parallel = $false }
    else { $parallel = $true }

    $query = @{
        Ingress = $cmdlineArgs.Contains("ingress")
        Egress = $cmdlineArgs.Contains("egress")
        Days = $days
        Node = $node
        StartData = [System.DateTimeOffset]::Now
        EndData = $null
        Parallel = $parallel
    }
    return $query
}

function GetDailyPaymentTimeline {
    param ($sat)
    $nm = ([DateTime]::Now).AddMonths(1)
    $hours = ((Get-Date -Year $nm.Year -Month $nm.Month -Day 1).AddDays(-1).Day) * 24

    $stor = ($sat | Select-Object -ExpandProperty storageDaily)
    $bw = $sat | Select-Object -ExpandProperty bandwidthDaily | Select-Object intervalStart, egress

    $timeline = New-Object "System.Collections.Generic.SortedList[int, double]"

    $times = (($stor | Select-Object -ExpandProperty intervalStart) + ($bw | Select-Object -ExpandProperty intervalStart)) | Select-Object -Unique | Sort-Object
    $times | ForEach-Object {
        $day = $_
        #$storageDaily = ($stor | Where-Object {$_.intervalStart -eq $day} | Measure-Object -Sum {$_.atRestTotal}).Sum / 1000000000000 / $hours * 1.50
        $storageDaily = ($stor | Where-Object {$_.intervalStart -eq $day} | Measure-Object -Sum atRestTotal).Sum / 1000000000000 / $hours * 1.50
        $bandwidthDaily = ($bw | Where-Object {$_.intervalStart -eq $day} | Measure-Object -Sum {
            ($_.egress.repair + $_.egress.audit) * 10.0 / 1000000000000 + 
            $_.egress.usage * 20.0 / 1000000000000
        }).Sum
        $totalDaily = $storageDaily + $bandwidthDaily
        $timeline.Add($day.Day, $totalDaily)
    }
    
    #$timelineSum = ($timeline.Values | Measure-Object -Sum).Sum

    $summarySum = ($sat | Select-Object -ExpandProperty egressSummary | Measure-Object -Sum).Sum # / 1000000000000
    #$byDaySum = ($bw | Measure-Object -Sum {$_.egress.usage}).Sum #/ 1000000000000
    $byDaySum = ($bw | Select-Object -ExpandProperty egress | Select-Object -ExpandProperty usage | Measure-Object -Sum).Sum
    $delta = $summarySum - $byDaySum
    $deltaBaks = $delta / 1000000000000 * 20.0

    if ($deltaBaks -gt 1) {
        Write-Host -ForegroundColor Yellow ("Storj API data for egress summary and egress by days differs for {0} ({1:N2}$)" -f (HumanBytes($delta)), $deltaBaks)
    }

    return $timeline
}

function GetSummary {
    param ($nodes)
    $summary = ($nodes | Select-Object -ExpandProperty BwSummary | AggBandwidth2)
    $summary | Add-Member -NotePropertyName NodesCount -NotePropertyValue $nodes.Count

    $sat = $nodes | Select-Object -ExpandProperty Sat 

    $daily = $sat | Select-Object -ExpandProperty storageDaily
    $timeline = GetDailyTimeline -daily $daily
    $summary | Add-Member -NotePropertyName RestByDay -NotePropertyValue $timeline

    $dailyPayment = GetDailyPaymentTimeline -sat $sat
    $summary | Add-Member -NotePropertyName PayByDay -NotePropertyValue $dailyPayment

    #$maxNodeEarned = ($nodes | Measure-Object -max {$_.Held + $_.Paid}).Maximum
    $maxNodeEarned = ($nodes | ForEach-Object { $_.Held + $_.Paid } | Measure-Object -Maximum).Maximum

    $summary | Add-Member -NotePropertyName MaxNodeEarned -NotePropertyValue $maxNodeEarned

    return $summary
}

Preamble
if ($args.Contains("example")) {
    $config = DefaultConfig
    $config | ConvertTo-Json
    return
}

#DEBUG
##$args = "-c", ".\ConfigSamples\Storj3Monitor.Debug.conf", "-np", "-node", "node01", "-p", "all"
#$args = "-c", ".\ConfigSamples\Storj3Monitor.Debug.conf", "-np", "-p", "all"
#$args = "-c", ".\ConfigSamples\Storj3Monitor.Debug.conf"
#$args = "-c", ".\ConfigSamples\Storj3Monitor.Debug.conf", "-p", "all"
#$args = "-c", ".\ConfigSamples\Storj3Monitor.Debug.conf", "monitor"

$config = LoadConfig -cmdlineArgs $args

if (-not $config) { return }

$query = GetQuery -cmdlineArgs $args
$nodes = @(GetNodes -config $config -query $query)
$score = GetScore -nodes $nodes
$bwsummary = GetSummary -nodes $nodes
$query.EndData = [DateTimeOffset]::Now
$payments = $null
if ($null -ne $config.Payout) { 
    $payments = GetPayments -nodes $nodes -config $config -summary $bwsummary
}

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
        DisplaySat -nodes $nodes -query $query -config $config
        Write-Host -ForegroundColor Yellow "All Satellites" 
        GraphRest -summary $bwsummary
        DisplayScore -score $score -bwsummary $bwsummary
        DisplayTraffic -nodes $nodes -query $query -config $config
    }
    else 
    {
        DisplayScore -score $score -bwsummary $bwsummary
    }
    DisplayNodes -nodes $nodes -bwsummary $bwsummary -config $config
    Write-Host
    if ($null -ne $config.Payout) { 
        DisplayPayments -payments $payments -summary $bwsummary 
        DisplayRelativePayments -payments $payments -summary $bwsummary 
    }
    DisplayFooter -nodes $nodes -bwsummary $bwsummary -config $config

    Write-Host ("Data collect time {0}s" -f ($query.EndData - $query.StartData).TotalSeconds)
}

#DEBUG
#cd C:\Projects\Repos\Storj
#.\Storj3Monitor\Storj3Monitor.ps1 -c .\Storj3Monitor\ConfigSamples\Storj3Monitor.Debug.conf -np
#.\Storj3Monitor\Storj3Monitor.ps1 -c .\Storj3Monitor\ConfigSamples\Alex.conf -np

