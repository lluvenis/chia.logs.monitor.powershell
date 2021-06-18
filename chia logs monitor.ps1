# LINE notification settings.
$LINE_TOKEN = "LINETOKEN"  # Input your LINE Notify Token.
$MESSAGE_WON = "RICHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH&stickerPackageId=6370&stickerId=11088036"
$DELAY_SEND_SUMMARY = 300 # Second

# No changes required.
$num_measurements = 0
$avg_time_seconds = 0
$over_1_seconds = 0
$over_5_seconds = 0
$over_30_seconds = 0
$proofs_total = 0
$eligible_plots_total = 0
$eligible_events_total = 0
$pct_Eligible_plots = 0
$unfinished_block_total = 0
$pct_unfinished_block = 0
$summary = ""
$line_message = ""

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

Get-Content "~\.chia\mainnet\log\debug.log" -Wait -Tail 10 | select-string 'plots were eligible|error|warning|finished.signage.point|updated.wallet.peak|new_signage_point_harvester|Added unfinished_block' | ForEach-Object {
    
    if ($_ -Match "([0-9:.]*) harvester (?:src|chia).harvester.harvester(?:\s?): INFO\s*([0-9]+) plots were eligible for farming ([0-9a-z.]*) Found ([0-9]) proofs. Time: ([0-9.]*) s. Total ([0-9]*) plots"){
        $HarvesterActivityMessage = @{
            timestamp=[datetime]$Matches[1]
            eligible_plots_count=$Matches[2]
            challenge_hash= $Matches[3]
            found_proofs_count=$Matches[4]
            search_time_seconds=[double]$Matches[5]
            total_plots_count=$Matches[6]
        }

        $num_measurements++
        $avg_time_seconds += ($HarvesterActivityMessage.search_time_seconds - $avg_time_seconds) / $num_measurements

        switch ($HarvesterActivityMessage.search_time_seconds) {
            {$_ -ge 1} {$over_1_seconds++}
            {$_ -ge 5} {$over_5_seconds++}
            {$_ -ge 30} {$over_30_seconds++}
        }

        if ($HarvesterActivityMessage.eligible_plots_count -ne 0){
            $eligible_plots_total += $HarvesterActivityMessage.eligible_plots_count
            $eligible_events_total++
        }
        if ($eligible_events_total -ne 0){
            $pct_Eligible_plots = [math]::Round(($eligible_plots_total/$eligible_events_total),2)
        }
        $proofs_total += $HarvesterActivityMessage.found_proofs_count
        
    } elseif ($_ -Match "Added unfinished_block")
    {
        $unfinished_block_total++
    }

    if ($eligible_plots_total -ne 0){
        $pct_unfinished_block = [math]::Round(($unfinished_block_total/$eligible_plots_total),2)
    }

    $summary = "Search - average: "+[math]::Round($avg_time_seconds, 2)+"s, - over 1s: $over_1_seconds, - over 5s: $over_5_seconds, - over 30s: $over_30_seconds, Plots: " + $HarvesterActivityMessage.total_plots_count + ",  Eligible plots: $pct_Eligible_plots average, Not farmed: $pct_unfinished_block average, Proofs: $proofs_total"
    $line_message = "Proofs: $proofs_total found`nSearch`n- average: "+[math]::Round($avg_time_seconds, 2)+"s`n- over 1s: $over_1_seconds`n- over 5s: $over_5_seconds`n- over 30s: $over_30_seconds`nPlots: " + $HarvesterActivityMessage.total_plots_count + "`nEligible plots: $pct_Eligible_plots average`nNot farmed: $pct_unfinished_block average"

    $host.UI.RawUI.WindowTitle = $summary

    if ($Later -lt (Get-Date)){
        SendMessageLine $line_message $LINE_TOKEN;
        $Later = Get-Date
        $Later = $Later.AddSeconds($DELAY_SEND_SUMMARY)
    }

    write-host -f $(
        if ($_ -Match "([1-9][0-9]*)\sproofs") {'green' ;SendMessageLine $MESSAGE_WON  $LINE_TOKEN; } 
        elseif ($_ -Match "new_signage_point_harvester") { 'darkcyan' }
        elseif ($_ -Match "([1-9][0-9]*)\splots\swere\seligible") { 'cyan' } 
        elseif ($_ -Match "Added unfinished_block") { 'magenta' } 
        elseif ($_ -Match "Time:\s[5-9][0-9]*\.\d+") { 'red' } 
        elseif ($_ -Match "\d+\splots\swere\seligible") { 'white' } 
        elseif ($_ -Match ":\sError\s*(.*)") { 'red' ;SendMessageLine $Matches[1]  $LINE_TOKEN; } 
        elseif ($_ -Match ":\sWarning\s*(.*)") { 'yellow' ;SendMessageLine $Matches[1]  $LINE_TOKEN; } 
        else {
            'DarkGray' 
        } 
    ) $_.line 
}
