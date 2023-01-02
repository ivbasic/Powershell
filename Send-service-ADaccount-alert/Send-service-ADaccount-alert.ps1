#### DESCRIPTION

    <#
    Send notification to owners of service accounts which have password close to or over 1 year of age. 
    #>


#### SKRIPTA

    # get all enabled service users which didint change their pw for 320 days (45 days before their pw is one year old)
    # script is ignoring service users created in the last 320 days, because they did never change their password and PasswordLastSet attribute is empty for them

    $pwlastset_date = (get-date).AddDays(-320) 
    $pwlastset_date_escalation = (get-date).AddDays(-351) # 14 days
    $created = (get-date).AddDays(-320) 

    $users_all = get-aduser -filter {Enabled -eq $True} -Server  -Properties displayname, samaccountname, description, enabled, msDS-UserPasswordExpiryTimeComputed, employeetype, created, canonicalname, passwordlastset, passwordneverexpires, department | 
    where {($_.employeetype -notmatch "0|1|2|3") -and ($_.canonicalname -notlike  "domain.com/Microsoft Exchange System Objects/*") -and ($_.created -lt $created)} 

    $users_w = ($users_all | where passwordlastset -lt $pwlastset_date) | where passwordlastset -gt $pwlastset_date_escalation  # warning users
    $users_c = $users_all | where passwordlastset -lt $pwlastset_date_escalation # critical users


# WARNING USERS
    # save all warning users in .txt file in "export" folder 
    # script is grouping all service accounts from one owner to one .txt file. In the end only one email is sent o owner even if multiple AD accounts needs password change
    
    $dir_w = "C:\Scripts\Send-system-account-alert\export\warning\"

    foreach ($user_w in $users_w){
        $file_w = ($dir_w + $user_w.department+ ".txt")
        if (Test-Path $file_w){
            Add-Content $file_w ($user_w.samaccountname)
        }
        else {
            New-Item $file_w
            Add-Content $file_w ($user_w.samaccountname)
        }    
    }


# WARNING EMAIL 
 
    $files_w = (dir $dir_w).name  

    foreach ($file_w in $files_w) {
        $accounts_w = Get-Content ($dir_w + $file_w)
        foreach ($account_w in $accounts_w){
            $aduser_w = get-aduser $account_w -Properties displayname, samaccountname, description, enabled, passwordlastset, department
            $displayname_w = $aduser_w.displayname
            $username_w = $aduser_w.samaccountname
            $description_w = $aduser_w.description
            $enabled_w = $aduser_w.enabled
            $pwlastset_w = (($aduser_w.passwordlastset).Day).ToString() + "." + (($aduser_w.passwordlastset).Month).ToString() + "." + (($aduser_w.passwordlastset).Year).ToString()
            $department_w = $aduser_w.department

            $dataRow_w = "
            </tr>
            <td>$displayname_w</td>
            <td>$username_w</td>
            <td>$description_w</td>
            <td>$enabled_w</td>
            <td>$pwlastset_w</td>
            <td>$department_w</td>
            </tr>
            "
            $userreport_w += $datarow_w
        }

        $body_w = "<html>
        <style>
        {font-family: Verdana; font-size: 10pt;}
        TABLE{border: 1px solid black; border-collapse: collapse; font-size:10pt;}
        TH{border: 1px solid black; background: #c9e1ff; padding: 5px; color: #000000;font-family: Verdana; font-size: 10pt;}
        TD{border: 1px solid black; padding: 5px;font-family: Verdana; font-size: 10pt;}
        H3{font-family: Verdana; font-size: 10pt;}
        </style>
        <body><font face='verdana' size='4'>
        <p style='text-align: center;'><strong>Service accounts password change</strong></p>
        </body>
        <body><font face='verdana' size='2'>
        <p></p>
        <p>Hi,</p>
        <p>Please change password for the following accounts:</p>
        <table>
        <tr>
        <th>Displayname</th>
        <th>Username</th>
        <th>Description</th>
        <th>Enabled</th>
        <th>PasswordLastSet</th>
        <th>Owner</th>
        </tr>
        $userreport_w
        </table>
        <br>
        </body>
        "
  
        # SEND EMAIL ###################################################################
        $to_w = ($file_w -replace ".txt")    #prod
        $subject_w = "System account reset password alert! - " + ($file_w -replace ".txt")
        Send-MailMessage -From sender@domain.com -to $to_w -SmtpServer smtp.domain.com -Body $body_w -BodyAsHtml -Subject $subject_w -Priority High 
        Clear-Variable userreport_w
    }
    

# CRITICAL USERS
    $dir_c = "C:\Scripts\Send-system-account-alert\export\critical\"

    foreach ($user_c in $users_c){
        $file_c = ($dir_c + $user_c.department+ ".txt")
        if (Test-Path $file_c){
            Add-Content $file_c ($user_c.samaccountname)
        }
        else {
            New-Item $file_c
            Add-Content $file_c ($user_c.samaccountname)
        }    
    }


# CRITICALE MAIL 

    $files_c = (dir $dir_c).name 

    foreach ($file_c in $files_c) {
        $accounts_c = Get-Content ($dir_c + $file_c)

        foreach ($account_c in $accounts_c){
            $aduser_c = get-aduser $account_c -Properties displayname, samaccountname, description, enabled, passwordlastset, department
            $displayname_c = $aduser_c.displayname
            $username_c = $aduser_c.samaccountname
            $description_c = $aduser_c.description
            $enabled_c = $aduser_c.enabled
            $pwlastset_c = (($aduser_c.passwordlastset).Day).ToString() + "." + (($aduser_c.passwordlastset).Month).ToString() + "." + (($aduser_c.passwordlastset).Year).ToString()
            $department_c = $aduser_c.department

            $dataRow_c = "
            </tr>
            <td>$displayname_c</td>
            <td>$username_c</td>
            <td>$description_c</td>
            <td>$enabled_c</td>
            <td>$pwlastset_c</td>
            <td>$department_c</td>
            </tr>
            "
            $userreport_c += $datarow_c
        }

        $body_c = "<html>
        <style>
        {font-family: Verdana; font-size: 10pt;}
        TABLE{border: 1px solid black; border-collapse: collapse; font-size:10pt;}
        TH{border: 1px solid black; background: #c9e1ff; padding: 5px; color: #000000;font-family: Verdana; font-size: 10pt;}
        TD{border: 1px solid black; padding: 5px;font-family: Verdana; font-size: 10pt;}
        H3{font-family: Verdana; font-size: 10pt;}
        </style>
        <body><font face='verdana' size='4'>
        <p style='text-align: center;'><strong>Service accounts password change</strong></p>
        </body>
        <body><font face='verdana' size='2'>
        <p></p>
        <p>Hi,</p>
        <p>Please change password for the following accounts:</p>
        <table>
        <tr>
        <th>Displayname</th>
        <th>Username</th>
        <th>Description</th>
        <th>Enabled</th>
        <th>PasswordLastSet</th>
        <th>Owner</th>
        </tr>
        $userreport_c
        </table>
        <br>
        </body>
        "
  
        # SEND EMAIL ###################################################################
        $to_c = ($file_c -replace ".txt")      
        $cc_c_manager = (get-aduser -filter 'UserPrincipalName -like $to_c'  -Properties manager).manager
        $subject_c = "System account reset password critical alert! - " + ($file_c -replace ".txt")

        if ($cc_c_manager -eq $null){
            Send-MailMessage -From sender@domain.com -to $to_c -SmtpServer smtp.domain.com -Body $body_c -BodyAsHtml -Subject $subject_c -Priority High  
        }
        else {
            $cc_c_manager_email = (get-aduser $cc_c_manager -Properties mail ).mail 
            Send-MailMessage -From sender@domain.com -to $to_c -cc $cc_c_manager_email  -SmtpServer smtp.domain.com -Body $body_c -BodyAsHtml -Subject $subject_c -Priority High 
        }
        Clear-Variable userreport_c   
    }

    
#### CLEANUP

    $reportfolderlocation = "C:\Scripts\Send-system-account-alert\export\_reports\"
    $reportfoldername = ((get-date -Format dd.MM.yyy).ToString())
    New-Item -Path $reportfolderlocation -name $reportfoldername -ItemType "directory"
    Copy-Item -Path $dir_w -Destination "$reportfolderlocation$reportfoldername\" -recurse -Force
    Copy-Item -Path $dir_c -Destination "$reportfolderlocation$reportfoldername\" -recurse -Force

    Remove-Item "$dir_w*" -Recurse -Force
    Remove-Item "$dir_c*" -Recurse -Force

    
#### SEND REPORT
   
    # total number of system users
    $totalnumberofsystemusers = (get-aduser -filter {Enabled -eq $True}  -Properties displayname, samaccountname, description, enabled, msDS-UserPasswordExpiryTimeComputed, employeetype, created, canonicalname, passwordlastset, passwordneverexpires, department | 
    where {($_.employeetype -notmatch "0|1|2|3") -and ($_.canonicalname -notlike  "domain.com/Microsoft Exchange System Objects/*")}).count

    # total number of system users which need to change their password
    $totalnumberofsystemusersPW = ($users_all | where passwordlastset -lt $pwlastset_date).count

    # urgent password change (escalated to manager)
    $totalnumberofsystemusersPWurgent = ($users_all | where passwordlastset -lt $pwlastset_date_escalation).count

    # password older than 1 year
    $pwlastset_date_escalation_1year = (get-date).AddDays(-365) 
    $totalnumberofsystemusersPWurgent_expired = $users_all | where passwordlastset -lt $pwlastset_date_escalation_1year
    $totalnumberofsystemusersPWurgent_expired_COUNT = ($totalnumberofsystemusersPWurgent_expired).count


    foreach ($expired in $totalnumberofsystemusersPWurgent_expired){
        $aduser_expired = get-aduser $expired  -Properties displayname, samaccountname, description, enabled, passwordlastset, department
        $displayname_expired = $aduser_expired.displayname
        $username_expired = $aduser_expired.samaccountname
        $description_expired = $aduser_expired.description
        $enabled_expired = $aduser_expired.enabled
        $pwlastset_expired = (($aduser_expired.passwordlastset).Day).ToString() + "." + (($aduser_expired.passwordlastset).Month).ToString() + "." + (($aduser_expired.passwordlastset).Year).ToString()
        $department_expired = $aduser_expired.department
        $manager_expired = (get-aduser -filter 'UserPrincipalName -like $department_expired' -Properties manager ).manager
        $manager_mail_expired = (get-aduser $manager_expired -Properties mail ).mail

        $datarow_expired = "
        </tr>
        <td>$displayname_expired</td>
        <td>$username_expired</td>
        <td>$description_expired</td>
        <td>$enabled_expired</td>
        <td>$pwlastset_expired</td>
        <td>$department_expired</td>
        <td>$manager_mail_expired</td>
        </tr>
        "
        $userreport_expired += $datarow_expired
        }
    
    $body_report = "<html>
    <style>
    {font-family: Verdana; font-size: 10pt;}
    TABLE{border: 1px solid black; border-collapse: collapse; font-size:10pt;}
    TH{border: 1px solid black; background: #c9e1ff; padding: 5px; color: #000000;font-family: Verdana; font-size: 10pt;}
    TD{border: 1px solid black; padding: 5px;font-family: Verdana; font-size: 10pt;}
    H3{font-family: Verdana; font-size: 10pt;}
    </style>
    <body><font face='verdana' size='2'>
    <p></p>
    <p>Service accounts password stats:</p>
    - total number of system accounts: $totalnumberofsystemusers
    <br>
    - must change password in 45 days: $totalnumberofsystemusersPW
    <br>
    -- out of that $totalnumberofsystemusersPW accounts, password needs urgent change (escalated to owner manager): $totalnumberofsystemusersPWurgent
    <br>
    --- out of that $totalnumberofsystemusersPWurgent accounts, password older than 1 year already has: $totalnumberofsystemusersPWurgent_expired_COUNT
    <br><br>
    <table>
    <tr>
    <th>Displayname</th>
    <th>Username</th>
    <th>Description</th>
    <th>Enabled</th>
    <th>PasswordLastSet</th>
    <th>Owner</th>
    <th>Manager</th>
    </tr>
    $userreport_expired
    </table>
    <br>
    Br
    </body>
    "

    Send-MailMessage -From sender@domain.com -to reports@domain.com -Cc sender@domain.com -SmtpServer smtp.domain.com -Body $body_report -BodyAsHtml -Subject "System account reset password - Statistics"
    Clear-Variable userreport_expired

# THE END
