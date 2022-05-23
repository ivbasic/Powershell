Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;
$mailboxes = get-mailbox -filter {(Name -like "CustomerSupport" -or Name -like "*SOX*" -or Name -like "*ITGC*")}

foreach ($mailbox in $mailboxes){
    if ((get-mailbox $mailbox).IssueWarningQuota -ne "Unlimited"){
        $warning = get-mailbox $mailbox | ft IssueWarningQuota -HideTableHeaders | Out-String
        $total = get-mailbox $mailbox | Get-MailboxStatistics | ft TotalItemSize -HideTableHeaders | Out-String

        $warning = $warning -split " " 
        $warning_value = $warning[0] -replace "`n" -replace "`r"
        $warning_bytes = $warning[1] -replace "`n" -replace "`r"

        $total = $total -split " "
        $total_value = $total[0] -replace "`n" -replace "`r"
        $total_bytes = $total[1] -replace "`n" -replace "`r"
    }
    else {
        $warning_value = "7.9"
        $warning_bytes = "GB"
        $total = get-mailbox $mailbox | Get-MailboxStatistics | ft TotalItemSize -HideTableHeaders | Out-String
        $total = $total -split " "
        $total_value = $total[0] -replace "`n" -replace "`r"
        $total_bytes = $total[1] -replace "`n" -replace "`r"
    }

    $list = $mailboxes | Get-MailboxStatistics | select displayname, totalitemsize | out-string
    $report = "$mailbox is almost full! `n`nWarning is set to $warning_value GB, and this mailbox has $total_value GB. `n`nMonited mailboxes:`n$list"

    if ($total_bytes -like "*GB*"){
        if ([int]$total_value -gt [int]$warning_value){
            send-mailmessage -from sender@domain.com -to recipient@domain.com -subject "$mailbox - mailbox almost full" -SmtpServer smtp.domain.com -Body $report   
        }
    }
}
