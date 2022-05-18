<# Prerequisites: 
1. Install and configure Plink 
https://somoit.net/ironport/ironport-automate-commands-scripts-from-windows
Generate public/private keys with Puttygen
Configure public Key in CiscoESA
2. Create local user account on Cisco ESA with Operator permissions
3. Create txt files with cmdlets which will be run by plink on Cisco ESA 
$CiscoESA_AV_status should be a text file in $Logs_Location
$CiscoESA_updater_logs 
#>

function Get-CiscoESA-AV-status {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)][String[]]$CiscoESA_IPaddress, 
        [Parameter(Mandatory=$True)][String]$CiscoESA_ppk, 
        [Parameter(Mandatory=$True)][String]$CiscoESA_user, 
        [Parameter(Mandatory=$True)][String]$CiscoESA_AV_status,
        [Parameter(Mandatory=$True)][String]$CiscoESA_updater_logs, 
        [Parameter(Mandatory=$True)][String]$Logs_Location, 
        [String]$SendEmail,
        [String]$MailFrom,
        [String]$MailTo,
        [String]$SMTPServer
    )

    BEGIN {
        # Start transcript
        Try {
            Start-Transcript $Logs_Location\transcript.txt -ErrorAction Stop
        }
        Catch {
            Start-Transcript $Logs_Location\transcript.txt
        }
    }

    PROCESS {
        $OK = @() 
        $log_CiscoESA_AV_status_MAIL = @()
        $attachment = @()
        $counter = 0
        # Cisco ESA connect with plink and execute commands remotely
        foreach($CiscoESA in $CiscoESA_IPaddress){
                    
            $Counter++
            Write-Progress -Activity "Get-CiscoESA-AV-status" -CurrentOperation $CiscoESA -PercentComplete (($Counter / $CiscoESA_IPaddress.count) * 100)

            $log_CiscoESA_AV_status = "$Logs_Location\CiscoESA_"+$CiscoESA+"_antivirusstatus.txt"
            $log_CiscoESA_updater_logs_ALL = "$Logs_Location\CiscoESA_"+$CiscoESA+"_updater_logs_ALL.txt"
            (New-Item ("$Logs_Location\CiscoESA_" + $CiscoESA + "_updater_logs.txt") -Force) > $null
            $log_CiscoESA_updater_logs_TODAY = "$Logs_Location\CiscoESA_"+$CiscoESA+"_updater_logs.txt" # later used to send in an email 
        
            plink.exe -ssh $CiscoESA -i $CiscoESA_ppk -l $CiscoESA_user -no-antispoof -m $CiscoESA_AV_status > $log_CiscoESA_AV_status
            plink.exe -ssh $CiscoESA -i $CiscoESA_ppk -l $CiscoESA_user -no-antispoof -m $CiscoESA_updater_logs > $log_CiscoESA_updater_logs_ALL 
        
            # Cisco ESA - check date in log with "IDE serial"
            $content_IDE_Serial = (Get-Content $log_CiscoESA_AV_status)[1]
            $today_1 =  (get-date).AddDays(0).toString("yyyyMMdd")
            if ($content_IDE_Serial -match $today_1){
                $OK += 0
            }
            else {
                $OK += 1
            }

            # Cisco ESA - check date in log with "Last Update"
            $content_Last_IDE_Update = (Get-Content $log_CiscoESA_AV_status)[3]
            $culture = [CultureInfo]'en'
            $today_2 =  (get-date).AddDays(0).toString("dd MMM yyyy", $culture)
            if ($content_Last_IDE_Update -match $today_2){
                $OK += 0
            }
            else {
                $OK += 1
            }
        
            # Logs formatting for email body and attachment
            get-content $log_CiscoESA_updater_logs_ALL | Select-Object -Last 33 > $log_CiscoESA_updater_logs_TODAY
            $attachment += "$log_CiscoESA_updater_logs_TODAY"
            #echo $attachment
            $log_CiscoESA_AV_status_MAIL += ((Get-Content $log_CiscoESA_AV_status | Select-Object -First 2) + (Get-Content $log_CiscoESA_AV_status | Select-Object -Last 1) | Out-String)
        }
 
        # Email formatting if $OK does not contain 1 (AV update successfull)
        $html=""
        $body_OK = "<html>
        <style>
            BODY{font-family: Verdana; font-size: 10pt;}
            H1{font-size: 26px;}
            H2{font-size: 24px;}
            H3{font-size: 10px;}
        </style>
        <pre><body align=""left""><font color =""#03ad00"">Antivirus definitions are up to date. Detailed logs attached. </font>
        $log_CiscoESA_AV_status_MAIL
        </body></pre>
        " + $html

        # Email formatting if $OK contains 1 (AV update NOT successfull)
        $body_NOK = "<html>
        <style>
            BODY{font-family: Verdana; font-size: 10pt;}
            H1{font-size: 26px;}
            H2{font-size: 24px;}
            H3{font-size: 10px;}
        </style>
        <pre><body align=""left""><font color =""#ff0000"">Antivirus definitions are NOT up to date. Detailed logs attached. </font>
        $log_CiscoESA_AV_status_MAIL
        </body></pre>
        " + $html

        # Send email...
        $subject_date = get-date -Format "dd.MM.yyyy"
        $subject_OK = "Cisco ESA AV - OK - $subject_date"
        $subject_NOK = "Cisco ESA AV - NOT OK - $subject_date"

        # Conditional statements
        # 0 - AV was successfully updated today 
        # 1 - AV was NOT successfully updated today 
        if ($SendEmail){
            if (($OK -contains 0) -and ($OK -notcontains 1)){
                Send-MailMessage -To $MailTo -From $MailFrom -Body $body_OK -BodyAsHtml -subject $subject_OK -SmtpServer $SMTPServer -Attachments $attachment[0..($CiscoESA_IPaddress).count]
                }
            if ($OK -contains 1){
                Send-MailMessage -To $MailTo -From $MailFrom -Body $body_NOK -BodyAsHtml -subject $subject_NOK -SmtpServer $SMTPServer  -Attachments $attachment[0..($CiscoESA_IPaddress).count] -Priority High
                }
        }

        # ... or output to screen
        else {
            $log_CiscoESA_AV_status_MAIL
        }
    }
    
    # clear variables and arrays
    END {
        Clear-Variable OK -ErrorAction silentlycontinue
        Clear-Variable log_CiscoESA_AV_status_MAIL -ErrorAction silentlycontinue
        Clear-Variable attachment -ErrorAction silentlycontinue
        Stop-Transcript
        }   
}
