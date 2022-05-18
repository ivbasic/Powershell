$dateYesterday = (get-date).AddDays(-1) | get-date -Format "yyyy-MM-dd" 
$users_TOdelete = import-csv "C:\Scripts\Remove-disabled-ADaccounts\files\2-filtered-from-Splunk-report\Filtered-AD-Accounts-disabled-more-than-90-days-ago-$dateYesterday.csv" -Delimiter ";"  
$logpath = "C:\Scripts\Remove-disabled-ADaccounts\files\3-deleted-AD-accounts\"
$logname = "Deleted-disabled_ADaccounts-$(get-date -f yyyy-MM-dd).txt"
$logfile = $logpath + $logname
$datestamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")

Function LogWrite
{
	Param ([string]$logstring)
	
	if (!(Test-Path $logpath)) {
		New-Item -ItemType Directory $logpath | Out-Null
	} 
	else { 
		Add-content $logfile -value $logstring
	}
}


foreach ($user in $users_TOdelete.user){
    remove-aduser $user -confirm:$false -WhatIf
    LogWrite "$user deleted; $datestamp"
    }


$body = "<html>
<style>
{font-family: Verdana; font-size: 10pt;}
TABLE{border: 1px solid black; border-collapse: collapse; font-size:10pt;}
TH{border: 1px solid black; background: #c9e1ff; padding: 5px; color: #000000;font-family: Verdana; font-size: 10pt;}
TD{border: 1px solid black; padding: 5px;font-family: Verdana; font-size: 10pt;}
H3{font-family: Verdana; font-size: 10pt;}
</style>
<body><font face='verdana' size='2'>
Hi,
<br>
<br>
AD accounts disabled more than 90 days ago are deleted!
<br>
<br>
Br
<br>
<br>
*** This script is running on server <>, stored in 'C:\Scripts\Remove-disabled-ADaccounts\' and scheduled as '2-Remove-Disabled-ADaccounts'. *** 
</font></body>
"

# Send report

$to= "recipient@domain.com"

$datum = get-date -Format "dd-MM-yyyy" 
Send-MailMessage -From sender@domain.com -to $to  -SmtpServer smtp.domain.com -Body $body -BodyAsHtml -Subject "AD accounts - deleted! - $datum" -Priority High -Attachments $logfile

