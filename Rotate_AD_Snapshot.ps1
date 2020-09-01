$DcName = "DC-NAME01" # the name of DC to connect to

Invoke-Command -ComputerName $DcName -ScriptBlock {
$MaxAge = "7" # maximum snapshot age
$SmtpServer = "smtp.domain.com" # smtp server used to send notifications
$Recipient = "admin@domain.com" # alert recipient
$NtdsDiskPatt = "\s[G]:\s" # pattern containing disk letter. G by default.

function GetSnapshotLists {
    $global:output = ntdsutil "activate instance ntds" snapshot "list all" quit quit | Select-String -Pattern '^\s\d:\s' ## non-empty lines
    $global:WithDates = $output | Select-String -Pattern "\s\d{4}\/\d{2}\/\d{2}\:" ## lines containing date
    $global:NoDates = $output | Select-String -Pattern "\s[A-Z]:\s" ## lines containing drive letter
    $global:NotNTDS = $NoDates | Select-String -Pattern $NtdsDiskPatt -NotMatch ## lines not containing NTDS drive letter (G:)
    }

$GuidDate = @()
GetSnapshotLists ## getting initial snapshot list

## organizing date lines into object array containing "Date" and "Guid" properties

foreach ($WithDate in $WithDates) {
    $Matches = $null
    $WithDate -match "\s(?<date>\d{4}\/\d{2}\/\d{2}:\d{2}:\d{2})\s(?<guid>{?([0-9a-fA-F]){8}(-([0-9a-fA-F]){4}){3}-([0-9a-fA-F]){12}}?)"
    $GuidDate += New-Object -TypeName psobject -Property @{"GUID" = $Matches["GUID"]; "date" = [datetime]::ParseExact($Matches["Date"], "yyyy/MM/dd:H:mm", $null)}
    }

## removing snapshots older than X

foreach ($i in $GuidDate){
    $guid = $null
    if ($i.date -lt (get-date).AddDays(-$MaxAge)){
        $guid = $i.guid
        ntdsutil "activate instance ntds" snapshot "delete $guid" quit quit
        }
    }

## creating new snapshot

ntdsutil "activate instance ntds" snapshot create quit quit

## udpating snapshot list

GetSnapshotLists

## removing shapshots of every disk except NTDS one.

foreach ($No in $NotNTDS) {
    $guid = $null
    $Matches = $null
    $No -match "({?([0-9a-fA-F]){8}(-([0-9a-fA-F]){4}){3}-([0-9a-fA-F]){12}}?)"
    $guid = $Matches[0]
    ntdsutil "activate instance ntds" snapshot "delete $guid" quit quit
    }

## updating snapshot list

GetSnapshotLists

## sending snapshot list report via SMTP

$output = $output | Out-String

Send-MailMessage -From "$env:computername@domain.com" -To $Recipient -Subject "DC Snapshot Report" -SmtpServer $SmtpServer -Body $output
}