#!/usr/bin/powershell
# Storj3LogMeasure script by Krey
# this script analize storj v3 log and calculates some stats
#
# Changes:
# v0.0    - 20190702 Initial version
# v0.1    - fixes
# v0.2    - 20190711 Add graph timeline
# v0.3    - 20190715 Script input and fixes, misc. Checked with linux. Published on telegramm
# v0.4    - 20190722 Other errors store in logResult
# v0.5    - 20190801 Multi-threaded version (use -ST parameter to lock to single-threaded for workaround and bug hunting). 
#         - add sat stat before all satellites
#         - add well-known satellites check
# v0.6    - 20190809 polished
# v0.7    - 20190910 published on github


# TODO
# Req00  - Performance
# Req01  - Combine completed and failed graphs
# Req02  - [del]Monitor (alert) functionality to email, mqtt, telegramm[/del] moved to Storj3Monior
# Req03  - SVG graphs and html output
# Req04  - multi-node analitics
# Req05  - Satellite bandwidth graph

# Known bugs
# Bug01  - errors sections sometimes includes stat table
# Bug02  - DateTimeOffset
# Bug03  - Passthrought $timeSpan variable to GetTimeSlot
# Bug04  - Linux performance ugly

#USAGE:
#
#analize logfile multithreaded (for Windows)
#pwsh Storj3LogMeasure.ps1 -logFile storagenode.log
#
#analize logfile singlethreaded 
#pwsh Storj3LogMeasure.ps1 -logFile storagenode.log -ST
#
#pipe from docker
#docker logs storagenode 2>&1 | pwsh Storj3LogMeasure.ps1 
#
#where
#logFile - path to file
#ST - Single Thread mode


 param (
    [string]$logFile,
    [switch]$st
 )

$sriptVersion = "v0.7"
$maxrows = 20000
$timeSpan = [Timespan]::FromMinutes(15)

$wellKnownSat = ("118UWpMCHzs6CvSgWd9BfFVjw5K9pZbJjkfZJexMtSkmKxvvAW", "12EayRS2V1kEsWESU9QMRseFhdxYxKicsiFmxrsLZHeLUtdps3S", "121RTSDpyNZVcEU84Ticf2L1ntiuUimbWgfATz21tuvgk3vzoA6", "12L9ZFwhzVpuEKMUNUqkaTLGzwY9G24tbiigLiXpmZWKwmcNDDs")

$actionListShort = ("GET_AUDIT", "GET", "GET_REPAIR", "PUT", "PUT_REPAIR")
$actionList = (
    "GET_AUDIT", 
    "GET_AUDIT_COMPLETED",
    "GET_AUDIT_FAILED",

    "PUT", 
    "PUT_COMPLETED", 
    "PUT_FAILED", 
    
    "PUT_REPAIR", 
    "PUT_REPAIR_COMPLETED",
    "PUT_REPAIR_FAILED", 

    "GET", 
    "GET_COMPLETED",
    "GET_FAILED", 
    
    "GET_REPAIR", 
    "GET_REPAIR_COMPLETED",
    "GET_REPAIR_FAILED"
)

function GetLogMessage
{
   $p = @{
        'Time'                  = $null
        'Level'                 = $null
        'Source'                = $null
        'Message'               = $null
        'Json'                  = $null
        'HaveTime'              = $false
        'TimeParsed'            = [System.DateTime]::MinValue
        'TimeSlot'              = -1
    }
    return New-Object –TypeName PSObject –Prop $p
}

function GetResult
{
    #$logResult = [hashtable]::Synchronized(@{
    $result = @{
        NodeId                = ""

        LinesProcessed        = 0
        StartTime             = [DateTime]::Now
        EndTime                = [DateTime]::MinValue

        StartLog              = [DateTime]::MaxValue
        EndLog                = [DateTime]::MinValue

        RunningTimeline       = New-Object "System.Collections.Generic.SortedList[int,int]"

        FilesProcessed        = 0
        FilesTotal            = 0

        Satellites            = @{}
        Errors                = @{}
        Trace                 = ""

        #counters
        UploadStarted         = 0
        UploadCompleted       = 0
        UploadFailed          = 0
        DownloadStarted       = 0
        DownloadCompleted     = 0
        DownloadFailed        = 0
        Deleted               = 0
        DeleteFailed          = 0

        Ignored               = 0
        Unparsed              = 0
    }
    return $result
}

function GetSat
{
    param ($id)
    #$sat = [hashtable]::Synchronized(@{
    $sat = @{
        Id                    = $id
        Actions               = @{}

        #counters
        UploadStarted         = 0
        UploadCompleted       = 0
        UploadFailed          = 0
        DownloadStarted       = 0
        DownloadCompleted     = 0
        DownloadFailed        = 0
        Deleted               = 0
        DeleteFailed          = 0
    }
    return $sat
}

function GetSatAction
{
    param ($key)
    $result = @{
        Key                   = $key
        Count                 = 0
        Timeline              = New-Object "System.Collections.Generic.SortedList[int,int]"
        Errors                = @{}
    }
    return $result
}

function AddTimeline
{
    param ($timeline, $timeSlot)
    if (-not $timeline.ContainsKey($timeSlot)) { $timeline.Add($timeSlot, 1) }
    else { $timeline[$timeSlot]++ }
}

function GetTimeSlot
{
    param ($start, $current)
    $timeSpan = [Timespan]::FromMinutes(15)
    $timeSlot = [int][Math]::Floor((($current - $start).TotalMinutes/$timeSpan.TotalMinutes))
    return $timeSlot
}

function StoreError
{
    param($collection, $text)
    if (-not $collection.ContainsKey($text)) {
        $collection.Add($text, 1)
    }
    else { $collection[$text]++ }
}

function GetLogKey
{
    param ($logResult, $message, [ref]$mr, [ref]$key, $level, $source)
    $mr.Value = 0
    #Check message
    if ($null -eq $message) {
        if ($level -match "ERROR") {
            StoreError -collection $logResult.Errors -text $source
        }
        else { Write-Error "GetLogKey: message is null" }
    }
    elseif ($message -eq "upload started") { $key.Value ="UploadStarted" }
    elseif ($message -eq "uploaded") { 
        $mr.Value = 1
        $key.Value ="UploadCompleted"
    }
    elseif ($message -eq "upload failed") { 
        $mr.Value = -1
        $key.Value ="UploadFailed"
    }
    elseif ($message -eq "download started") { $key.Value="DownloadStarted" }
    elseif ($message -eq "downloaded") { 
            $mr.Value = 1
            $key.Value="DownloadCompleted"
    }
    elseif ($message -eq "download failed") { 
        $mr.Value = -1
        $key.Value="DownloadFailed"
    }
    elseif ($message -eq "deleted") { $key.Value="Deleted" }
    elseif ($message -eq "delete failed") { $key.Value="DeleteFailed" }
    elseif ($message.StartsWith("Remaining", [System.StringComparison]::OrdinalIgnoreCase) ) { 
        #TODO remaining threasholds
    }
    elseif ($message -eq "sending") { 
        #TODO sending counts per satellites
    }
    elseif ($message -eq "finished") { 
        #TODO pieces
    }
    else {
        #TODO add this to errors
        #Write-Host $message
    }
}

function Acc
{
    param ($logResult, $message, $jsonstr, $timeSlot, $level, $source)

    [ref]$mrRef = 0
    [ref]$keyRef = ""
    GetLogKey -logResult $logResult -message $message -mr ([ref]$mrRef) -key ([ref]$keyRef) -level $level -source $source
    $mr = $mrRef.Value
    $key = $keyRef.Value

    if ([String]::IsNullOrEmpty($key)) {
        ;
        return;
    }

    $logResult[$key]++
    if ($null -ne $jsonstr) {
        $json = ConvertFrom-Json $jsonstr
        $action = $json.Action
        $satId = $json.SatelliteID
        $sat = $null

        # store all errors to logresult
        if ($null -ne $json.error) {
            StoreError -collection $logResult.Errors -text $json.error
        }

        if ([String]::IsNullOrEmpty($key))
        {
            if ($null -eq $json.error) { Write-Host $message + " " + $jsonstr -ForegroundColor Gray }
        }
        elseif (-not [String]::IsNullOrEmpty($satId))
        {
            if (-not $logResult.Satellites.ContainsKey($satId))
            {
                $sat = (GetSat -id $satId)
                $logResult.Satellites.Add($satId, $sat)
            }
            else { $sat = $logResult.Satellites[$satId] }


            if ([String]::IsNullOrEmpty($sat.Id)) { Write-Error "Acc empty sat id" } #DEBUG

            $sat[$key]++

            #Add action
            if ($null -ne $action) { 
                $actionKey = ""
                if ($mr -eq 0) { $actionKey = $action }
                elseif ($mr -eq -1) { $actionKey = $action + "_FAILED" }
                elseif ($mr -eq 1) { $actionKey = $action + "_COMPLETED" }
                else { 
                    ;
                    Write-Error ("Unknown mr {0} for {1}" -f $mr, $jsonstr)
                }

                $act = $null
                if (-not $sat.Actions.ContainsKey($actionKey))
                {
                    $act = GetSatAction -key $actionKey
                    $sat.Actions.Add($actionKey, $act)
                }
                else { $act = $sat.Actions[$actionKey] }
                
                $act.Count++
                AddTimeline -timeline $act.Timeline -timeSlot $timeSlot

                if ($null -ne $json.error) { 
                    StoreError -collection $act.Errors -text $json.error 
                }
            }
        }
    }
    ;
}


function ParseLogString
{
    param($message)
    ;
    $result = GetLogMessage
    $parts = $message.Split("`t")

    $result.Time = $parts[0]
    $result.Level = $parts[1]

    if ([String]::IsNullOrEmpty($parts[3])) { $result.Message = $parts[2] }
    else {
        $result.Source = $parts[2]
        $result.Message = $parts[3]
        $result.Json = $parts[4]
    }

    if (-not [String]::IsNullOrEmpty($result.Time)) {
        $hFormat = "yyyy-MM-ddTHH:mm:ss.fffZ"
        [ref]$logTimeRef = [DateTimeOffset]::MinValue
        if ([DateTimeOffset]::TryParseExact($result.Time, $hFormat, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, $logTimeRef)) {
            $result.HaveTime = $true
            $result.TimeParsed = $logTimeRef.Value.DateTime
        }
    }


    return $result
}

function ParseLogMessage
{
    param ($logResult, $lm)

    if ($null -ne $lm.Source) {

        # Storage message
        if ($lm.Source.StartsWith("piecestore",[System.StringComparison]::OrdinalIgnoreCase)) { 
            Acc -logResult $logResult -level $lm.Level -source $lm.Source -message $lm.Message -jsonstr $lm.Json -timeSlot $lm.TimeSlot
        }
    }
    elseif ($null -ne $lm.Message) {
        # Configuration message 
        if ($lm.Message.StartsWith("Configuration loaded",[System.StringComparison]::OrdinalIgnoreCase)) {
            #TODO config
        }
        # Version message
        elseif ($lm.Message.StartsWith($verFormat,[System.StringComparison]::OrdinalIgnoreCase)) {
            $version = $lm.Message.Substring($verFormat.Length)
            AddTimeline -timeline $logResult.RunningTimeline -timeSlot $lm.TimeSlot
            if (-not ($logResult.Versions -contains $version)) {
                $logResult.Versions += ($version)
            }
        }
        # Node started message
        elseif ($lm.Message.StartsWith("Node",[System.StringComparison]::OrdinalIgnoreCase) -and $lm.Message.EndsWith("started",[System.StringComparison]::OrdinalIgnoreCase)) {
            $nodeId = $lm.Message.TrimStart("Node").TrimEnd("started").Trim()
            if($nodeId.Length -ne 50) {
                Write-Host -ForegroundColor Red ("Bad node id at: {0}" -f $_)
            }
            if ($logResult.NodeId -ne $nodeId) {
                if ([String]::IsNullOrEmpty($logResult.NodeId)) {
                    $logResult.NodeId = $nodeId 
                }
                else { throw "New node id, this script support only one node" }
            }
        }
        elseif ($lm.Message.StartsWith("operator",[System.StringComparison]::OrdinalIgnoreCase)) {
            #private
        }
        elseif ($lm.Message.StartsWith("db.migration", [System.StringComparison]::OrdinalIgnoreCase)) {
            #TODO store db version
        }
        elseif ($lm.Message.StartsWith("vouchers", [System.StringComparison]::OrdinalIgnoreCase)) {
            #TODO some work with voucher messages
        }
        elseif ($lm.Message.StartsWith("Configuration loaded from", [System.StringComparison]::OrdinalIgnoreCase)) { 
            #nothing 
        }
        elseif ($lm.Message.StartsWith("Version", [System.StringComparison]::OrdinalIgnoreCase)) { 
            #TODO set initial version 
        }
        elseif ($lm.Message -match "server started on") { 
            #TODO addresses 
        }
        elseif ($lm.Message -match "Failed to do periodic version check") { 
            StoreError -collection $logResult.Errors -text "Failed to do periodic version check"
        }
        else { 
            StoreError -collection $logResult.Errors -text $lm.Message
        }
    }
    else { 
        $logResult.Unparsed++
        Write-Host -ForegroundColor Gray ("Unparsed at {0}" -f $lm.TimeParsed) 
    }
}

function ProcessLogBlock
{
    param ([string[]]$logString, $logResult, $fromTime = [DateTime]::MaxValue, $first = $false)
    #TODO pass this vars to job procedures
    #$hFormat = "yyyy-MM-ddTHH:mm:ss.fffZ"
    #$hFormat2 = "yyyy-MM-dd HH:mm:ss"
    #$verFormat = "running on version v"

    if ($null -eq $logResult) { 
        $logResult = GetResult
        if ($fromTime -ne [DateTime]::MaxValue) { $logResult.StartLog = $fromTime }
    }

    $logTimeEnd = $null

    #$logString | ForEach-Object 
    foreach ($str in $logString) {
        $logResult.LinesProcessed++
        $lm = ParseLogString -message $str

        if ($lm.HaveTime){
            $logTime = $lm.TimeParsed
            $logTimeEnd = $logTime

            if ($fromTime -ne [DateTime]::MaxValue -and $logTime -le $fromTime) 
            { 
                $logResult.LinesProcessed--
                continue 
            }

            if ($logResult.StartLog -eq [DateTime]::MaxValue) {
                $logResult.StartLog = $logTime
            }

            $lm.TimeSlot = GetTimeSlot -start $logResult.StartLog -current $logTime
            if ($null -ne $lm.Message) { ParseLogMessage -logResult $logResult -lm $lm }

            if ($first) {
                break
            }
        }
        else { 
            $logResult.Ignored++
            #Write-Host -ForegroundColor Gray ("Ignored: {0}" -f $_) 
        }
        
    }
    $logResult.EndLog = $logTimeEnd
    $logResult.EndTime = [DateTime]::Now
    return $logResult
}

$init = 
[scriptblock]::Create(@"
function GetResult {$function:GetResult}
function GetSat {$function:GetSat}
function GetSatAction {$function:GetSatAction}
function AddTimeline {$function:AddTimeline}
function GetTimeSlot {$function:GetTimeSlot}
function StoreError {$function:StoreError}
function GetLogKey {$function:GetLogKey}
function Acc {$function:Acc}
function GetLogMessage {$function:GetLogMessage}
function ParseLogString {$function:ParseLogString}
function ParseLogMessage {$function:ParseLogMessage}
function ProcessLogBlock {$function:ProcessLogBlock}

"@)

function ProcessLogFile
{
    param ($file, $logResult)

    Write-Host ("Start reading by {0} lines..." -f $maxrows)
    $content = (Get-Content -ReadCount $maxrows $file.FullName)
    $totalRows = (($content.Length - 1)*$maxrows + $content[$content.Length-1].Length)
    Write-Host ("End reading {0} lines" -f $totalRows)

    Write-Host "Process logs synchronously (single-threading)"
    $lastReport = [System.DateTime]::Now
    $content | ForEach-Object { 
        ProcessLogBlock -logString $_ -logResult $logResult
        if (([System.DateTime]::Now - $lastReport).TotalSeconds -gt 5) {
            $lastReport = [System.DateTime]::Now
            Write-Host ("{0} lines processed of {1}" -f $logResult.LinesProcessed, $totalRows)
        }
    }
}

function AggregateHash
{
    param ($hash1, $hash2)
    ;
    $hash2.Keys | ForEach-Object {
        $key = $_
        if ($hash1.ContainsKey($key)) { $hash1[$key]+= $hash2[$key] }
        else { $hash1.Add($key, $hash2[$key]) }
    }

}

function AggregateActions
{
    param ($act1, $act2)
    if (($null -eq $act2) -or ($act2.Count -eq 0)) { return }

    $act2.Keys | ForEach-Object {
        $key = $_
        if ($act1.ContainsKey($key)) {
            $act1obj = $act1[$key]
            $act2obj = $act2[$key]
            $act1obj.Count+=$act2obj.Count

            AggregateHash -hash1 $act1obj.Timeline -hash2 $act2obj.Timeline
            AggregateHash -hash1 $act1obj.Errors -hash2 $act2obj.Errors
        }
        else { 
            $act1[$key] = $act2[$key] 
        }
    }
}

function AggregateCounters
{
    param ($obj1, $obj2)
    $obj1.UploadStarted+=$obj2.UploadStarted
    $obj1.UploadCompleted+=$obj2.UploadCompleted
    $obj1.UploadFailed+=$obj2.UploadFailed
    $obj1.DownloadStarted+=$obj2.DownloadStarted
    $obj1.DownloadCompleted+=$obj2.DownloadCompleted
    $obj1.DownloadFailed+=$obj2.DownloadFailed
    $obj1.Deleted+=$obj2.Deleted
    $obj1.DeleteFailed+=$obj2.DeleteFailed
}

function AggregateSatellites
{
    param ($sat1, $sat2)
    if (($null -eq $sat2) -or ($sat2.Count -eq 0)) { return }

    $sat2.Keys | ForEach-Object {
        $key = $_
        if ($sat1.ContainsKey($key)) {
            #Aggregate sat
            $sat1obj = $sat1[$key]
            $sat2obj = $sat2[$key]
            AggregateCounters -obj1 $sat1obj -obj2 $sat2obj
            AggregateActions -act1 $sat1obj.Actions -act2 $sat2obj.Actions
        }
        else { 
            $sat1[$key] = $sat2[$key] 
        }
    }
}


function AddResult
{
    param ($summary, $current)

    if ((-not [String]::IsNullOrEmpty($summary.NodeId)) -and (-not [String]::IsNullOrEmpty($current.NodeId)) -and ($summary.NodeId -ne $current.NodeId)) { 
        Write-Host -ForegroundColor Red ("Different nodes not supported now. Results may lie. Node1 is {0}, Node2 is {1}" -f $summary.NodeId, $current.NodeId)
    }
    elseif ([String]::IsNullOrEmpty($summary.NodeId) -and (-not [String]::IsNullOrEmpty($current.NodeId))) { 
        $summary.NodeId = $current.NodeId 
    }

    $summary.LinesProcessed+=$current.LinesProcessed
    $summary.FilesProcessed+=$current.FilesProcessed
    $summary.Ignored+=$current.Ignored
    $summary.Unparsed+=$current.Unparsed

    $summary.FilesProcessed+=$current.FilesProcessed

    ;
    if ($summary.StartTime -gt $current.StartTime) { $summary.StartTime = $current.StartTime }
    if ($summary.EndTime -lt $current.EndTime) { $summary.EndTime = $current.EndTime }

    ;
    if ($summary.StartLog -gt $current.StartLog) { $summary.StartLog = $current.StartLog }
    if ($summary.EndLog -lt $current.EndLog) { $summary.EndLog = $current.EndLog }

    AggregateCounters -obj1 $summary -obj2 $current
    AggregateHash -hash1 $summary.RunningTimeline -hash2 $current.RunningTimeline
    AggregateHash -hash1 $summary.Errors -hash2 $current.Errors
    AggregateSatellites -sat1 $summary.Satellites -sat2 $current.Satellites
}

function ProcessLogMp
{
    param ($content, $logResult)
    $index = 0
    $processed = 0

    # First need log string with time
    $isContinue = $true
    do
    {
        $currentResult = ProcessLogBlock -logString ($content[$index]) -logResult $null -first $true
        if ($currentResult.StartLog -eq [DateTime]::MaxValue) { 
            $processed++ 
            $index++
        }
        else { $isContinue = $false }
        AddResult -summary $logResult -current $currentResult 
    }
    while ($isContinue)
    ;

    $waitList = New-Object System.Collections.Generic.List[int]

    ;
    while ($processed -lt $content.Count -or $waitList.Count -gt 0) {

        # refill waitlist
        $waitList.Clear()
        $jobs = @(Get-Job -Name ("StorjLogMeasure") -ErrorAction SilentlyContinue)
        $jobs | ForEach-Object {$waitList.Add($_.Id)}

        # add job
        while (($waitList.Count -lt [Environment]::ProcessorCount) -and ($index -lt $content.Count)) {
            [string[]] $data = $content[$index++]
            $job = Start-Job -Name "StorjLogMeasure" -InitializationScript $init -ScriptBlock { ProcessLogBlock -logString $args[0] -logResult $null -fromTime $args[1] } -ArgumentList @($data), $logResult.StartLog
            $waitList.Add($job.Id)
        }
            
        if ($waitList.Count -gt 0) {
            $job = Wait-Job -Id $waitList -Any -Timeout 5
            if ($null -ne $job) {
                $processed++
                $currentResult = Receive-Job $job
                ;
                if ($null -eq $currentResult) { 
                    ;
                    Write-Host -ForegroundColor Red "NullResult from job. Try use -ST param"
                }
                elseif ($currentResult.GetType().Name -eq "Object[]") {
                    if ($job.State -eq "Completed") { 
                        $currentResult | ForEach-Object {
                            AddResult -summary $logResult -current $_ 
                        }
                    }
                }
                else {
                    ;
                    if ($job.State -eq "Completed") { 
                        AddResult -summary $logResult -current $currentResult 
                    }
                }
                if ($IsLinux -or $IsMacOs) {
                    Write-Host ("{0} lines processed of {1}" -f $logResult.LinesProcessed, $totalRows)
                }
                else {
                    Write-Progress -Activity "Analize logs" -PercentComplete ($processed / $content.Count * 100) -Status ("{0} lines processed of {1}" -f $logResult.LinesProcessed, $totalRows)
                }
                Remove-Job $job.Id
            }
        }
        elseif ($processed -lt $content.Count) { 
            throw "Something wrong in job list" 
        }
    }
}

function ProcessLogFileMp
{
    param ($file, $logResult)
    Write-Host -ForegroundColor Green ("{0}" -f $file.Name)

    Write-Host ("Start reading by {0} lines..." -f $maxrows)
    $content = (Get-Content -ReadCount $maxrows $file.FullName)
    $totalRows = (($content.Length - 1)*$maxrows + $content[$content.Length-1].Length)
    Write-Host ("End reading {0} lines" -f $totalRows)
    Write-Host 
    Write-Host "Process logs asynchronously (multi-threading)"
    Write-Host ("Start parsing...")
    ;
    if ($content.Count -eq 1) { ProcessLogBlock -logString ($content[0])  -logResult $logResult }
    elseif($content.Count -gt 1) { ProcessLogMp -content $content -logResult $logResult }
    else {Write-Error "No content"}

    Write-Host ("{0} lines parsed" -f $logResult.LinesProcessed)
    Write-Host ("End parsing at {0} seconds from start" -f ([System.DateTime]::Now - $logResult.StartTime).TotalSeconds)
}


function GraphTimeline 
{
    param ($title, $decription, [int]$height, $fromTime, $toTime, $timeline)
    $width = 160
    if ($height -eq 0) { $height = 10 }
    if ($fromTime -ge $toTime) {
        Write-Host -ForegroundColor Red ("{0}: Bad timeline params. exiting." -f $title)
        return
    }
    $lastSlot = GetTimeSlot -start $fromTime -current $toTime

    [int]$idx = 0
    $colWidth = [int]([Math]::Floor([Math]::Max(1.0, $lastSlot / $width)))
    $lastCol = [int][Math]::Ceiling($lastSlot/$colWidth)
    $data = new-object int[] ($lastCol + 1)

    #grouping to fit width
    for ($i = 0; $i -le $lastCol; $i++)
    {
        for ($j = 0; $j -lt $colWidth; $j++)
        {
            $idx = $i * $colWidth + $j
            if ($timeline.ContainsKey($idx)) { $data[$i]+=$timeline[$idx] }
        }
    }
   
    #max in groups while min in original data. otherwise min was zero in empty data cells
    $dataMin = ($timeline.Values | Measure-Object -Minimum).Minimum
    $dataMax = ($data | Measure-Object -Maximum).Maximum

    #limit height to actual data
    $rowWidth = ($dataMax - $dataMin) / $height
    if ($rowWidth -lt $dataMin) { $rowWidth = $dataMin }
    if ($dataMax / $rowWidth -lt $height) { $height = $dataMax / $rowWidth }

    $graph = New-Object System.Collections.Generic.List[string]
    $graph.Add("└".PadRight($lastCol + 1, "─"))

    1..$height | ForEach-Object {
        $r = $_
        $line = "│"
        1..$lastCol | ForEach-Object {
            $c = $_
            $v = $data[$c-1]
            $h = $v / $rowWidth
            if ($h -ge $r ) {$line+="-"}
            else {$line+=" "}
        }
        $graph.Add($line)
    }
    $graph.Reverse()

    Write-Host $title -NoNewline
    if (-not [String]::IsNullOrEmpty($decription)) {Write-Host (" - {0}" -f $decription) -ForegroundColor Gray -NoNewline}
    Write-Host
    Write-Host ("Y-axis from {0} to {1}, cell = {2}" -f $dataMin, $dataMax, $rowWidth) -ForegroundColor Gray
    $graph | ForEach-Object {Write-Host $_}
    Write-Host -ForegroundColor Gray ("X-axis from {0:$hformat2} to {1:$hformat2}, cell = {2} minutes, total = {3} hours" -f $fromTime, $toTime, ($colWidth * $timeSpan.TotalMinutes), ([int](($toTime - $fromTime).TotalHours)))
    Write-Host
    Write-Host
}

function AggSat
{
    param ($logResult, $action)
    $sum = 0
    $logResult.Satellites.Values | ForEach-Object {
        $sat = $_
        $sum += $sat.Actions[$action].Count
    }
    return $sum
}

function Write-Errors
{
    param ($errors, $subj, $action)
    if (($null -ne $errors) -and ($errors.Count -gt 0)) 
    {
        Write-Host ("Errors {0} on {1} >" -f $action, $subj) -ForegroundColor Red
        $errors.GetEnumerator()| Sort-Object -Descending Value | Select-Object @{Name="Count";Expression={$_.Value}}, @{Name="Text";Expression={$_.Name}} | Format-Table
        Write-Host "< End of Errors" -ForegroundColor Red
        Write-Host 
    }
}

function Write-Ef
{
   param ($tab, $name, $total, $comleted, $failed)
   $pips = 30.0
   $ef = 1.0
   if ($total -gt 0) { $ef = (1.0 - $failed/$total) }
   $efStr = [Math]::Round($ef * 100, 4).ToString().PadRight(8, " ")
   
   $efPips = [int]($pips * $ef )
   $repPips = "[" + "".PadRight($efPips, "-").PadRight($pips, " ") + "] " + $efStr + ("`t{0} of {1}" -f $comleted, $total)
   $tab[$name] = $repPips
}

function Write-Ef-Sat
{
    param ($logResult)
    ;
    $allSatTotal = $logResult["DownloadStarted"] + $logResult["UploadStarted"]

    $logResult.Satellites.GetEnumerator() | ForEach-Object {
        $sat = $_.Value
        $satTotal = $sat["DownloadStarted"] + $sat["UploadStarted"]
        if ($satTotal -gt 0 -and $allSatTotal -gt 0) { $satPercent = [Math]::Round([decimal]$satTotal / $allSatTotal * 100, 2) }
        else {$satPercent = 0}

        Write-Host 
        Write-Host ("  Satellite: {0}`t{1}%" -f $sat.Id, $satPercent) -BackgroundColor Green -ForegroundColor Black
        Write-Host 

        $tab = @{}
        Write-Ef -tab $tab -name "1. DOWNLOAD" -total $sat["DownloadStarted"] -comleted $sat["DownloadCompleted"] -failed $sat["DownloadFailed"]
        Write-Ef -tab $tab -name "2. UPLOAD" -total $sat["UploadStarted"] -comleted $sat["UploadCompleted"] -failed $sat["UploadFailed"]

        $idx = $tab.Count
        $actionListShort | ForEach-Object {
            $idx++
            $action = $_
            $total = $sat.Actions[$action].Count
            if ($total -gt 0) {
                Write-Ef -tab $tab -name ("{0}. {1}" -f $idx, $action) -total $total -comleted $sat.Actions[$action + "_COMPLETED"].Count -failed $sat.Actions[$action + "_FAILED"].Count
            }
        }
        Write-Ef -tab $tab -name "9. EFFECIENCY" -total ($sat["UploadStarted"] + $sat["DownloadStarted"]) -comleted ($sat["UploadCompleted"] + $sat["DownloadCompleted"]) -failed ($sat["UploadFailed"] + $sat["DownloadFailed"])
        $tab.GetEnumerator() | Sort-Object Name | Format-Table
        Write-Host

        $actionList | ForEach-Object {
            $name = $_
            $act = $sat.Actions[$name]
            ;
            if (($null -ne $act) -and ($null -ne $act.Timeline)) {
                GraphTimeline -title ("{0} graph" -f $name) -from $logResult.StartLog -to $logResult.EndLog -timeline $act.Timeline
                Write-Errors -errors $sat.Actions[$name].Errors -subj $sat.Id -action $name
            }
        }

        Write-Host
        Write-Host
    }
}

function Efficiency
{
    param ($logResult)
    Write-Host Efficiency -ForegroundColor Red

    Write-Ef-Sat -logResult $logResult
    Write-Host

    $tab = @{}
    Write-Ef -tab $tab -name "1. DOWNLOAD" -total $logResult["DownloadStarted"] -comleted $logResult["DownloadCompleted"] -failed $logResult["DownloadFailed"]
    Write-Ef -tab $tab -name "2. UPLOAD" -total $logResult["UploadStarted"] -comleted $logResult["UploadCompleted"] -failed $logResult["UploadFailed"]
    ;
    $idx = $tab.Count
    $actionListShort | ForEach-Object {
            $idx++
            $action = $_
            $total = AggSat -logResult $logResult -action $action
            if ($total -gt 0) {
                $completed = AggSat -logResult $logResult -action ($action + "_COMPLETED")
                $failed = AggSat -logResult $logResult -action ($action + "_FAILED")
                Write-Ef -tab $tab -name ("{0}. {1}" -f $idx, $action) -total $total -comleted $completed -failed $failed
            }
    }


    Write-Ef -tab $tab -name "9. EFFECIENCY" -total ($logResult["UploadStarted"] + $logResult["DownloadStarted"]) -comleted ($logResult["UploadCompleted"] + $logResult["DownloadCompleted"]) -failed ($logResult["UploadFailed"] + $logResult["DownloadFailed"])
    
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "--- A L L  S A T E L L I T E S---"
    Write-Host

    $logResult.Satellites.GetEnumerator() | ForEach-Object {
        $sat = $_.Value
        $allSatTotal = $logResult["DownloadStarted"] + $logResult["UploadStarted"]
        $satTotal = $sat["DownloadStarted"] + $sat["UploadStarted"]
        if ($satTotal -gt 0 -and $allSatTotal -gt 0) { $satPercent = [Math]::Round([decimal]$satTotal / $allSatTotal * 100, 2) }
        else {$satPercent = 0}
        #$satComleted = $sat["UploadCompleted"] + $sat["DownloadCompleted"]
        $satFailed = $sat["UploadFailed"] + $sat["DownloadFailed"]
        if ($satTotal -gt 0) { $satEf = [Math]::Round((1.0 - $satFailed/$satTotal) * 100, 2) }
        else { $satEf = 0}
        Write-Host ("{0}: {1}% bandwidth, {2}% effeciency" -f $sat.Id.PadRight(55, " "), $satPercent, $satEf)
    }

    $wellKnownSat | ForEach-Object {
        if (-not $logResult.Satellites.ContainsKey($_)) {
            Write-Host -ForegroundColor Red ("{0}: no data from this satellite. Maybe Disqualified!" -f $_.PadRight(55, " "))
        }
    }
    

    $tab.GetEnumerator() | Sort-Object Name | Format-Table
    Write-Host
    Write-Errors -errors $logResult.Errors -subj "all satellites" -action ""
}

function Preamble{
    Write-Host ""
    Write-Host ("Storj3LogMeasure script by Krey ver {0}" -f $sriptVersion)
    Write-Host "mail-to: krey@irinium.ru"
    Write-Host ""
    Write-Host -ForegroundColor Yellow "I work on beer. If you like my scripts please donate bottle of beer in STORJ or ETH to 0x7df3157909face2dd972019d590adba65d83b1d8"
    Write-Host -ForegroundColor Gray "This wallet only for beer. Only beer will be bought from this wallet."
    Write-Host -ForegroundColor Gray "I will think later how to arrange it in the form of a public contract. Now you have only my promise. Just for lulz."
    Write-Host -ForegroundColor Gray "Why should I send bootles if everything works like that ?"
    Write-Host -ForegroundColor Gray "... see TODO comments in the script body"
    Write-Host ""
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

function ProcessFiles
{
    param($filesByDate, $logResult, $st = $false)
    $logResult.FilesTotal = $filesByDate.Count
    if ($null -eq $logResult.FilesTotal) {
        Write-Host -ForegroundColor Red "No log files to process. Exiting."
        return
    }

    $logTotalSize = ($filesByDate | Measure-Object -Sum Length).Sum
    Write-Host -ForegroundColor Green ("Starting analize {0} files {1} total size" -f $logResult.FilesTotal, (HumanBytes($logTotalSize)))
    if ((Get-Process -Id $pid).priorityclass -ne "BelowNormal") {
        Write-Host Setting BelowNormal priority 
        (Get-Process -Id $pid).priorityclass = "BelowNormal"
    }

    $allfiles = $filesByDate
    if ($st) { $allfiles | ForEach-Object { ProcessLogFile -file $_ -logResult $logResult | Out-Null } }
    else { $allfiles | ForEach-Object { ProcessLogFileMp -file $_ -logResult $logResult | Out-Null } }
    
    Write-Host ("Log to {0:$hFormat2}" -f $logResult.EndLog)
    Write-Host 

    ;
    GraphTimeline -title "Uptime graph" -decription "'running on version' messages count" -height 10 -from $logResult.StartLog -to $logResult.EndLog -timeline $logResult.RunningTimeline
    Write-Host 

    Write-Host ("Start aggregations")
    Write-Host

    Efficiency($logResult)
    Write-Host

    $logResult.EndTime = [DateTime]::Now
    Write-Host ("Exec time {0} seconds" -f [int]($logResult.EndTime - $logResult.StartTime).TotalSeconds)
}

Preamble
$logResult = GetResult

#Process args
if (-not [String]::IsNullOrEmpty($logfile)) {
    $filesByDate = Get-ChildItem -Path $logfile
    ProcessFiles -filesByDate $filesByDate -logResult $logResult -st $st
}
else {
    Write-Host "No log file specified. Read StdIn..."
    $line = 0
    $mt = $true
    $buffer = New-Object System.Text.StringBuilder($maxrows)
    $lastReport = [System.DateTime]::Now

    if (-not $st) 
    {
        #fill buffer
        foreach ($str in $input) {
            $line++
            $buffer.Append($str) | Out-Null
            if (([System.DateTime]::Now - $lastReport).TotalSeconds -gt 5) {
                Write-Host ("Buffered {0} log strings" -f $line)
                $lastReport = [System.DateTime]::Now
            }
            if ($line -ge $maxrows) {
                ProcessLogBlock -logString $buffer.ToArray() -logResult $logResult | Out-Null
            }

        }
        return
    }

    foreach ($str in $input) {
        $line++
        ProcessLogBlock -logString $str -logResult $logResult | Out-Null
        if (([System.DateTime]::Now - $lastReport).TotalSeconds -gt 5) {
            Write-Host ("Processed {0} log strings" -f $logResult.LinesProcessed)
            $lastReport = [System.DateTime]::Now
        }
    }

    $logResult.EndTime = [DateTime]::Now
    ;
    GraphTimeline -title "Uptime graph" -decription "running on version messages count" -height 10 -from $logResult.StartLog -to $logResult.EndLog -timeline $logResult.RunningTimeline
    Efficiency($logResult)
    Write-Host
    Write-Host ("End of pipelenie. Process {0} lines, {1} seconds" -f $line, [int]($logResult.EndTime - $logResult.StartTime).TotalSeconds)
}






