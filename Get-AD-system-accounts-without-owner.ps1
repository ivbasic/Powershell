<#
This script founds all enabled service domain AD users:
- without owners (we used 'name.surname@domain.com' format in department AD attribute)
- without employeetype AD attribute (with which we distinguished service users from normal employees)
and sends alert to IT department to fix AD users without those attributes.

Script is ignoring Exchange objects inside "win.vipnet.hr/Microsoft Exchange System Objects/*"
#>

Import-module ActiveDirectory

# Get all enabled service users
$users = get-aduser -filter {Enabled -eq $True}  -Properties displayname, samaccountname, created, description, enabled, employeetype, canonicalname, department, manager  | 
where {($_.employeetype -notmatch "0|1|2|3") -and ($_.canonicalname -notlike  "win.vipnet.hr/Microsoft Exchange System Objects/*")} 

# Check if there is an owner for every service AD user
foreach($user in $users){
    $owner = (get-aduser ($user.SamAccountName) -Properties department).department
    $emptype = (get-aduser ($user.SamAccountName) -Properties employeetype).employeetype

    if (($owner -ne $null) -and ((Get-ADUser -Filter 'mail -eq $owner').enabled -eq $true) -and ($emptype -ne $null)){
        # OK, service user is enabled, has employeetype and owner 
        }
    else {
        # NOT OK
    
        $displayname = $user.displayname
        $username = $user.samaccountname
        $employeetype = $user.employeetype
        $department = $user.department
        $description = $user.description

        $dataRow = "
        </tr>
        <td>$displayname</td>
        <td>$username</td>
        <td>$employeetype</td>
        <td>$department</td>
        <td>$description</td>
        </tr>
        "
        $userreport += $datarow
        }
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
Following service accounts dont have correct employeetype or department (owner) attributes. 
<br>
<br>
</font></body>
<table>
<tr>
<th>Displayname</th>
<th>Username</th>
<th>Employeetype</th>
<th>Department</th>
<th>Description</th>
</tr>
$userreport
</table>
<body><font face='verdana' size='2'>
<br>
Lp,
<br>
Robot
<br>
<br>
*** This script is running on server <>, stored in 'C:\Scripts\Get-AD-system-accounts-without-owner.ps1' and scheduled as 'Get-AD-system-accounts-without-owner'. *** 
</font></body>
"


# Send email report

$to = "recipient@domain.com" 

if ($userreport -ne $null){
    Send-MailMessage -From sender@domain.com -to $to -Cc $cc -SmtpServer smtp.domain.com -Body $body -BodyAsHtml -Subject "Service accounts without owner" -Priority High 
    }

Clear-Variable userreport
