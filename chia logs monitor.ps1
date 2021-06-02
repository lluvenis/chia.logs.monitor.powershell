# LINE notification settings.
$LINE_TOKEN = "LINETOKEN"  # Input your LINE Notify Token.
$MESSAGE_WON = "RICHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH&stickerPackageId=6370&stickerId=11088036"
$DELAY_SEND_SUMMARY = 600 # Second

# No changes required.
$FastestTime = 1000
$WorstTime = 0
$Above1Seconds = 0
$Above5Seconds = 0
$Above30Seconds = 0
$TotalChallenge  = 0
$EligiblePlotsRatio = 0
$TotalFindTime = 0
$proofs = 0
$AverageSpeed
$PassedFilterPercent

$CurrentTime = Get-Date
$Later = $CurrentTime.AddSeconds($DELAY_SEND_SUMMARY)
$host.UI.RawUI.BackgroundColor = "black"

function SendMessageLine {
    param (
        [string]$message = "",[string]$tokens = "LINETOKEN"
    )
    if (![string]::IsNullOrEmpty($tokens) -And $tokens -ne "LINETOKEN"){
        # Send message to LINE Notify API
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Content-Type", "application/x-www-form-urlencoded")
        $headers.Add("Authorization", "Bearer " + $tokens)
        $body = "message=" + $message
        $response = Invoke-RestMethod 'https://notify-api.line.me/api/notify' -Method 'POST' -Headers $headers -Body $body
    }
}

Get-Content "~\.chia\mainnet\log\debug.log" -Wait -Tail 10 | select-string 'plots were eligible|error|warning|finished.signage.point|updated.wallet.peak|new_signage_point_harvester' | ForEach-Object {
    
    if ($_ -Match "INFO\s*([0-9]*)\splots\swere\seligible\sfor\sfarming\s([a-z0-9.]*)\sFound\s([0-9]*)\sproofs.\sTime:\s([0-9.]*)\ss.\sTotal\s([0-9]*)\splots"){
        $TotalChallenge++
        $Activity = @{
            EligiblePlots = $Matches[1]
            FindTime = [double]$Matches[4]
            ProofsFound = $Matches[3]
            TotalPlots = $Matches[5]
            FilterRatio = $Matches[1] / $Matches[5]
        }
        switch ($Activity.FindTime) {
            {$_ -lt $FastestTime} {$FastestTime = $_}
            {$_ -gt $WorstTime} {$WorstTime = $_}
            {$_ -ge 1} {$Above1Seconds++}
            {$_ -ge 5} {$Above5Seconds++}
            {$_ -ge 30} {$Above30Seconds++}
        }
        $proofs += $Activity.ProofsFound
        $TotalFindTime += $Activity.FindTime
        $AverageSpeed = [math]::Round(($TotalFindTime / $TotalChallenge ),5)
        $EligiblePlotsRatio += $Activity.FilterRatio
        $PassedFilterPercent = [math]::Round(($EligiblePlotsRatio / $TotalChallenge ),5)  * 100
        $summary = "Total Challenge: $TotalChallenge, RT - Best: $FastestTime, Worst: $WorstTime, Avg: $AverageSpeed, Above (1 Sec: $Above1Seconds, 5 Sec: $Above5Seconds, 30 Sec: $Above30Seconds), Percent Passing Filter: $PassedFilterPercent, Total Plots: " + $Activity.TotalPlots + ", Proofs: $proofs"
        $host.UI.RawUI.WindowTitle = $summary
        if($Later -lt (Get-Date)){
            SendMessageLine $summary $LINE_TOKEN;
            $Later.AddSeconds($DELAY_SEND_SUMMARY)
        }
    };

    write-host -f $(
        if ($_ -Match "([1-9][0-9]*)\sproofs") {'green' ;SendMessageLine $MESSAGE_WON  $LINE_TOKEN; } 
        elseif ($_ -Match "new_signage_point_harvester") { 'darkcyan' }
        elseif ($_ -Match "([1-9][0-9]*)\splots\swere\seligible") { 'cyan' } 
        elseif ($_ -Match "Time:\s[5-9][0-9]*\.\d+") { 'red' } 
        elseif ($_ -Match "\d+\splots\swere\seligible") { 'white' } 
        elseif ($_ -Match "error") { 'red' } 
        elseif ($_ -Match "warning") { 'yellow' } 
        else {
            'DarkGray' 
        } 
    ) $_.line 
}
