# SETTING
$LINE_TOKEN = "FLh4IQEgqtQAQdT2IGU5BRPp7T6GkuDVJPAwy0Cmljc"  # LINE Notify Token
$MESSAGE_WON = "RICHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH&stickerPackageId=6370&stickerId=11088036"

Get-Content "~\.chia\mainnet\log\debug.log" -Wait -Tail 10 | select-string 'plots were eligible|error|warning|finished.signage.point|updated.wallet.peak|new_signage_point_harvester' | ForEach {
    write-host -f $(
        if ($_ -Match "[1-9][0-9]*\sproofs") {
            'green' 
            if(![string]::IsNullOrEmpty($LINE_TOKEN) -And $LINE_TOKEN -ne "LINETOKEN"){
                # Send message to LINE Notify API
                $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $headers.Add("Content-Type", "application/x-www-form-urlencoded")
                $headers.Add("Authorization", "Bearer " + $LINE_TOKEN)
                $body = "message=" + $MESSAGE_WON
                $response = Invoke-RestMethod 'https://notify-api.line.me/api/notify' -Method 'POST' -Headers $headers -Body $body
            }
        } 
        elseif ($_ -Match "new_signage_point_harvester") { 'darkcyan' }
        elseif ($_ -Match "[1-9][0-9]*\splots\swere\seligible") { 'cyan' } 
        elseif ($_ -Match "Time:\s[5-9][0-9]*\.\d+") { 'red' } 
        elseif ($_ -Match "\d+\splots\swere\seligible") { 'white' } 
        elseif ($_ -Match "error") { 'red' } 
        elseif ($_ -Match "warning") { 'yellow' } 
        else {
            'DarkGray' 
        } 
    ) $_.line 
}
