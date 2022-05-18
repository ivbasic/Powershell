#### START OF SPENCER SCRIPT https://www.spenceralessi.com/Using-Powershell-and-Microsoft-EWS-Managed-API-to-download-attachments-in-Exchange-2016/#

# User defined variables. Change these to fit your needs
$mailbox = "yourmailbox@domain.com"
$user = "userwithmailboxpermission" #$env:USERNAME
$reportroot = "C:\Scripts\Remove-disabled-ADaccounts\files\1-Splunk-report\" 
$logpath = "C:\Scripts\Remove-disabled-ADaccounts\logs\"
$logname = "1_Get-disabled-ADaccounts-$(get-date -f yyyy-MM-dd).log"
$logfile = $logpath + $logname
$processedfolderpath = "/Inbox/Processed"
$subjectfilter = "Splunk Report: AD Accounts - disabled more than 90 days ago"
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

Function FindTargetFolder($folderpath){
	$tftargetidroot = New-Object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot,$mailbox)
	$tftargetfolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($exchangeservice,$tftargetidroot)
    $pfarray = $folderpath.Split("/")
	
	# Loop processed folders path until target folder is found
	for ($i = 1; $i -lt $pfarray.Length; $i++){
		$fvfolderview = New-Object Microsoft.Exchange.WebServices.Data.FolderView(1)
		$sfsearchfilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName,$pfarray[$i])
        $findfolderresults = $exchangeservice.FindFolders($tftargetfolder.Id,$sfsearchfilter,$fvfolderview)
		
		if ($findfolderresults.TotalCount -gt 0){
			foreach ($folder in $findfolderresults.Folders){
				$tftargetfolder = $folder				
			}
		}
		else {
			#LogWrite "### Error ###"
			#LogWrite $datestamp " : Folder Not Found"
			$tftargetfolder = $null
			break
		}	
	}
	$Global:findFolder = $tfTargetFolder
}

Function FindTargetEmail($subject){
	foreach ($email in $foundemails.Items){
		$email.Load()
		$attachments = $email.Attachments

		foreach ($attachment in $attachments){
			$attachment.Load()
			$attachmentname = $attachment.Name.ToString()
            
			#LogWrite "$attachmentname saved to $reportroot"
			$file = New-Object System.IO.FileStream(($reportroot + $attachmentname), [System.IO.FileMode]::Create)
			$file.Write($attachment.Content, 0, $attachment.Content.Length)
			$file.Close()
			} 
		}
	# Mark email as read & move to processed folder
	$email.IsRead = $true
	$email.Update([Microsoft.Exchange.WebServices.Data.ConflictResolutionMode]::AlwaysOverwrite)
	[VOID]$email.Move($Global:findFolder.Id)
	}

#LogWrite "---"
#LogWrite "DATETIME: $datestamp"
#LogWrite "Mailbox: $mailbox"
#LogWrite "Report Root: $reportroot"
#LogWrite "Processed Folder: $processedfolderpath"
#LogWrite "Subject Filter: $subjectfilter"

# Load the EWS Managed API
$dllpath = "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
[void][Reflection.Assembly]::LoadFile($dllpath)

# Create EWS Service object for the target mailbox name
# Note, ExchangeVersion does not need to match the version of your Exchange server
# You set the version to indicate the lowest level of service you support
$exchangeservice = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2007_SP1)
$exchangeservice.UseDefaultCredentials = $true
$exchangeservice.AutodiscoverUrl($mailbox)

# Bind to the Inbox folder of the target mailbox
$inboxfolderid = New-Object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox,$mailbox)
$inboxfolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($exchangeservice,$inboxfolderid)

# Search the Inbox for messages that are: unread, has specific subject AND has attachment(s)
$sfunread = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::IsRead, $false)
$sfsubject = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+ContainsSubstring ([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::Subject, $subjectfilter)
$sfattachment = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::HasAttachments, $true)
$sfcollection = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+SearchFilterCollection([Microsoft.Exchange.WebServices.Data.LogicalOperator]::And);
#$sfcollection.add($sfunread)
#$sfcollection.add($sfsubject)
$sfcollection.add($sfattachment)

# Use -ArgumentList 10 to reduce query overhead by viewing the Inbox 10 items at a time
$view = New-Object -TypeName Microsoft.Exchange.WebServices.Data.ItemView -ArgumentList 10
$foundemails = $inboxfolder.FindItems($sfcollection,$view)

# Find $processedfolderpath Folder ID
FindTargetFolder($processedfolderpath)

# Process found emails
FindTargetEmail($subject)


#### END OF SPENCER SCRIPT https://www.spenceralessi.com/Using-Powershell-and-Microsoft-EWS-Managed-API-to-download-attachments-in-Exchange-2016/#

sleep 10 # just in case, wait for file download to finish



# get downloaded file and filter results
$date = get-date -Format "yyyy-MM-dd" 
$csv_location = $reportroot + (dir $reportroot | where Name -like "*$date*").Name
$csv = (import-csv $csv_location -Delimiter ",")
$whitelist = Get-Content "C:\Scripts\Remove-disabled-ADaccounts\files\_whitelist\whitelist.txt"

foreach ($row in $csv){
    $CSVuser = $row.user
    $itemDetails = Get-ADObject -Filter 'samaccountname -eq $CSVuser'
    if ($itemDetails.ObjectClass -eq "user"){
        $aduser = (get-aduser $CSVuser -ErrorAction SilentlyContinue -Properties description, employeetype, msExchRecipientTypeDetails | where msExchRecipientTypeDetails -match "$null|1|2147483648")
        <#
        msExchRecipientTypeDetails 
        1 	UserMailbox
        2 	LinkedMailbox
        4 	SharedMailbox
        16 	RoomMailbox
        32 	EquipmentMailbox
        128 	MailUser
        2147483648 	RemoteUserMailbox
        8589934592 	RemoteRoomMailbox
        17179869184 	RemoteEquipmentMailbox
        34359738368 	RemoteSharedMailbox 
        #>
        if (($aduser.enabled -eq $false) -and ($whitelist -notcontains $aduser.SamAccountName)){
            $row | Add-Member -MemberType NoteProperty -Name "enabled" -Value $aduser.enabled
            $row | Add-Member -MemberType NoteProperty -Name "description" -Value $aduser.description

            $disableduser = $row.user
            $disabledtime = $row._time
            $disabledby = $row.src_user
            $enabled = $aduser.enabled
            $description = $aduser.description

            $dataRow = "
            </tr>    
            <td>$disableduser</td>
            <td>$disabledtime</td>
            <td>$disabledby</td>
            <td>$enabled</td>
            <td>$description</td>
            </tr>
            "
            $userreport += $datarow
            }
        }
    }
    $csv | where enabled -ne $null | export-csv "C:\Scripts\Remove-disabled-ADaccounts\files\2-filtered-from-Splunk-report\Filtered-AD-Accounts-disabled-more-than-90-days-ago-$date.csv" -Delimiter ";" -NoTypeInformation


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
Following AD accounts are disabled more than 90 days ago. Check if some of them can not be deleted and enter them into shared whitelist file: \\SERVER\WHITELIST-disable-AD-account$
<br>
Tomorrow at 10:00AM all users that are not whitelisted will be deleted! 
<br><br>
</font></body>
<table>
<tr>
<th>Disabled user</th>
<th>Disabled on</th>
<th>Disabled by</th>
<th>Status</th>
<th>Description</th>
</tr>
$userreport
</table>
<body><font face='verdana' size='2'>
<br>
Br
<br>
<br>
*** This script is running on server <>, stored in 'C:\Scripts\Remove-disabled-ADaccounts\' and scheduled as '1-Get-Disabled-ADaccounts'. *** 
</font></body>
"

# posalji report u mailu

$to= "recipient@domain.com"

$datum = (get-date).AddDays(1) | get-date -Format "dd-MM-yyyy"  
if ($userreport -ne $null){
    Send-MailMessage -From sender@domain.com -to $to -SmtpServer smtp.domain.com -Body $body -BodyAsHtml -Subject "AD accounts - to be deleted on $datum!" -Priority High 
    }

Clear-Variable userreport
