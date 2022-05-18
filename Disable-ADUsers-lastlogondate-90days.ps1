######### Disable inactive users with last logon date more than 90 days ago


# GET USERS
# script is ignoring all users with "no_disable" value in "extensionAttribute10" attribute and all users which were already disabled in the last week
$90Days = (get-date).adddays(-90)

$d0 = (get-date).ToString("dd.MM.yyyy")
$d1 = (get-date).AddDays(-1).ToString("dd.MM.yyyy")
$d2 = (get-date).AddDays(-2).ToString("dd.MM.yyyy")
$d3 = (get-date).AddDays(-3).ToString("dd.MM.yyyy")
$d4 = (get-date).AddDays(-4).ToString("dd.MM.yyyy")
$d5 = (get-date).AddDays(-5).ToString("dd.MM.yyyy")
$d6 = (get-date).AddDays(-6).ToString("dd.MM.yyyy")
$d7 = (get-date).AddDays(-7).ToString("dd.MM.yyyy")
$d8 = (get-date).AddDays(-8).ToString("dd.MM.yyyy")
$d9 = (get-date).AddDays(-9).ToString("dd.MM.yyyy")
$d10 = (get-date).AddDays(-10).ToString("dd.MM.yyyy")
$d11 = (get-date).AddDays(-11).ToString("dd.MM.yyyy")
$d12 = (get-date).AddDays(-12).ToString("dd.MM.yyyy")
$d13 = (get-date).AddDays(-13).ToString("dd.MM.yyyy")
$d14 = (get-date).AddDays(-14).ToString("dd.MM.yyyy")
$d15 = (get-date).AddDays(-15).ToString("dd.MM.yyyy")
$d16 = (get-date).AddDays(-16).ToString("dd.MM.yyyy")
$d17 = (get-date).AddDays(-17).ToString("dd.MM.yyyy")
$d18 = (get-date).AddDays(-18).ToString("dd.MM.yyyy")
$d19 = (get-date).AddDays(-19).ToString("dd.MM.yyyy")
$d20 = (get-date).AddDays(-20).ToString("dd.MM.yyyy")
$d21 = (get-date).AddDays(-21).ToString("dd.MM.yyyy")

$Users = Get-ADUser -properties * -Filter {((-not(lastlogontimestamp -like "*")) -or (LastLogonDate -lt $90Days)) -and (enabled -eq $true)} | where {($_.Created -lt $90days) -and ($_.employeetype -match "0|1|2|3") -and ($_.extensionAttribute10 -ne "no_disable") -and 
(($_.extensionAttribute10 -notlike $d1) -and ($_.extensionAttribute10 -notlike $d2) -and 
($_.extensionAttribute10 -notlike $d3) -and ($_.extensionAttribute10 -notlike $d4) -and 
($_.extensionAttribute10 -notlike $d5) -and ($_.extensionAttribute10 -notlike $d6) -and 
($_.extensionAttribute10 -notlike $d7) -and ($_.extensionAttribute10 -notlike $d8) -and 
($_.extensionAttribute10 -notlike $d9) -and ($_.extensionAttribute10 -notlike $d10) -and 
($_.extensionAttribute10 -notlike $d11) -and ($_.extensionAttribute10 -notlike $d12) -and 
($_.extensionAttribute10 -notlike $d13) -and ($_.extensionAttribute10 -notlike $d14) -and 
($_.extensionAttribute10 -notlike $d15) -and ($_.extensionAttribute10 -notlike $d16) -and 
($_.extensionAttribute10 -notlike $d17) -and ($_.extensionAttribute10 -notlike $d18) -and 
($_.extensionAttribute10 -notlike $d19) -and ($_.extensionAttribute10 -notlike $d20)-and 
($_.extensionAttribute10 -notlike $d21) 
)
} 

$ignorelist = Get-ADUser -properties * -Filter 'extensionAttribute10 -like "no_disable"'

# DISABLE USERA
if ($users -ne $null){
    forEach ($user in $users) {
        (Disable-ADAccount -Identity $user)
        $desc = ($user.Description + "; Inactive more than 90 days, disabled by IT $d0")
        Set-ADUser $user -Description $desc
        set-aduser $user -Replace @{extensionAttribute10=$d0}
        }

    foreach ($ignore in $ignorelist){
        $ignorereport += $ignore
        $ignorereport += "<br>"    
    }

    # SEND EMAIL
    $Users_status_new =  foreach($user in $users){Get-ADUser $user -properties *}

    foreach($user in $Users_status_new){
        $Name = $user.Name
        $username = $user.samaccountname
        $LastLogonTimestamp = [DateTime]::FromFileTime($user.LastLogonTimestamp)
        $LastLogonDate = $user.LastLogonDate
        $created = $user.created
        $description = $user.description
        $enabled = $user.enabled

        $dataRow = "
        </tr>
        <td>$Name</td>
        <td>$username</td>
        <td>$LastLogonTimestamp</td>
        <td>$LastLogonDate</td>
        <td>$created</td>
        <td>$description</td>
        <td>$enabled</td>
        </tr>
        "
        $userreport += $datarow
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
    Following users are disabled because of inactivity: 
    <br>
    <br>
    </font></body>
    <table>
    <tr>
    <th>Name</th>
    <th>Username</th>
    <th>LastLogonTimestamp</th>
    <th>LastLogonDate</th>
    <th>Created</th>
    <th>Description</th>
    <th>Enabled</th>
    </tr>
    $userreport
    </table>
    <body><font face='verdana' size='2'>
    <br>
    Users with 'no_disable' value in extensionAttribute10 attribute:
    <br>
    $ignorelist
    <br>
    <br>
    Br
    <br>
    *** This script is running on server <>, stored in 'C:\Scripts\Disable-ADUsers-lastlogondate-90days.ps1' and scheduled as 'Disable-ADUsers-lastlogondate-90days.ps1'. *** 
    </font></body>
    "


    $to = "recipient@domain.com"
    Send-MailMessage -From sender@domain.com -to $to -SmtpServer smtp.domain.com -Body $body -BodyAsHtml -Subject "Disabled inactive users"
}

Clear-Variable userreport
Clear-Variable ignorereport



