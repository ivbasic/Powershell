<# Prerequisites: 
1. Create application FireEyeEX user account with api_analyst role
2. Install PowerShell Secrets Management Module and set secret for FireEyeEX api_analyst user account: 
Install-Module Microsoft.PowerShell.SecretManagement
Install-Module -Name SecretManagement.JustinGrote.CredMan -Scope AllUsers -Force
Register-SecretVault -Module SecretManagement.JustinGrote.CredMan -Name CredManStore
Set-Secret -Name <FireEyeEX username> -Secret '<FireEyeEX password>' -Vault CredManStore
#>

function Get-FireEyeEX-AV-status {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)][String]$FireEyeEX_IPaddress,
        [Parameter(Mandatory=$True)][String]$FireEyeEX_Username,
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

        # Set Powershell to trust FireEye EX self signed certificate 
        Try {
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@ 
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy -ErrorAction SilentlyContinue
        }
        Catch{}

        # Disable proxy
        $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        Set-ItemProperty -Path $reg -Name ProxyOverride -Value "$FireEyeEX_IPaddress"
    }

    PROCESS {
        # Set username and password of api_analyst user account
        $FireEyeEX_Password = Get-Secret -name $FireEyeEX_Username -AsPlainText
        $pair = "$($FireEyeEX_Username):$($FireEyeEX_Password)"
        $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
        $basicAuthValue = "Basic $encodedCreds"

        $HeadersLogin = @{
            Authorization = $basicAuthValue
        } 

        # Connect to FireEye EX (in my case connection to FireEye EX was failing for some unknown reason, so the script is set to try again for 10 times)
        [int] $count = 0
        if($null -eq $Connection){
            do {
                Start-Sleep -Seconds 1
                $Connection = Invoke-WebRequest -Uri https://"$FireEyeEX_IPaddress":443/wsapis/v2.0.0/auth/login -Method Post -Headers $HeadersLogin -UseBasicParsing
                $count++
            } while (($count -lt 10) -and ($null -eq $Connection))
        }
        
        $ConnectionToken = ($Connection.RawContent | findstr "X-FeApi-Token") -split "X-FeApi-Token: "
        $HeadersHealth = @{
            'X-FeApi-Token' = "$ConnectionToken"
        }

        # Get health status and save results
        $log_FireEyeEX_health_system = "$Logs_Location\FireEyeEX_health_system.txt" 

        [int] $count = 0
        if($null -eq $FE_HealthResults){
            do {
                Start-Sleep -Seconds 1
                $FE_HealthResults = Invoke-WebRequest -Uri https://"$FireEyeEX_IPaddress":443/wsapis/v2.0.0/health/system -Method get -Headers $HeadersHealth -UseBasicParsing
                $count++
            } while (($count -lt 10) -and ($null -eq $FE_HealthResults))
        }

        $FE_HealthResults.Content -split "," | Out-File $log_FireEyeEX_health_system

        # Conditional statements
        $OK = 2  # default value
        # 0 - AV was successfully updated today 
        # 1 - AV was NOT successfully updated today 
        # 2 - default value, if value $OK=2 then the script didn't axecute successfully   

        # Check todays date with lastUpdateTime in logs
        $content_FireEyeEX_lastupdate = (($FE_HealthResults.Content -split "," | Select-String 'lastUpdateTime' | Out-String).replace('"',"").replace(' lastUpdateTime: ',"") -split " ")[0]
        $today = (get-date ((Get-date).AddDays(0)) -UFormat "%Y/%m/%d").ToString() 

        if ($content_FireEyeEX_lastupdate -match $today){
            $OK = 0}
        else {$OK = 1}

        if ($content_FireEyeEX_lastupdate -match $today){
            $OK = 0}
        else {$OK = 1}

        # Logs formatting 
        $log_FE_HealthResult_MAIL_temp1 = ($FE_HealthResults.rawContent -split "," | Select-String '"name": "securityContent"' -Context 0,1 | Out-String).Replace("
        ","")
        $log_FE_HealthResult_MAIL_temp2 = ($FE_HealthResults.rawContent -split "," | Select-String '"version"' | Select-Object -First 1 -Skip 1| Out-String).Replace(" ","   ")
        $log_FE_HealthResult_MAIL = ((($log_FE_HealthResult_MAIL_temp1 + $log_FE_HealthResult_MAIL_temp2).replace('"',"").replace('{',"").replace('}',"").replace('
        >  ',"   ").Replace("
        ","").Replace("   ","    ")).replace("
    ","")).replace("version","    version")
        
                
        # Email formatting if $OK=0 (AV update successfull)
        $html=""
        $body_OK = "<html>
        <style>
            BODY{font-family: Verdana; font-size: 10pt;}
            H1{font-size: 26px;}
            H2{font-size: 24px;}
            H3{font-size: 10px;}
        </style>
        <pre><body align=""left""><font color =""#03ad00"">Antivirus definitions are up to date. Detailed logs attached. </font>
        $log_FE_HealthResult_MAIL
        </body></pre>
        " + $html

        # Email formatting if $OK=1 (AV update NOT successfull)
        $body_NOK = "<html>
        <style>
            BODY{font-family: Verdana; font-size: 10pt;}
            H1{font-size: 26px;}
            H2{font-size: 24px;}
            H3{font-size: 10px;}
        </style>
        <pre><body align=""left""><font color =""#ff0000"">Antivirus definitions are NOT up to date. Detailed logs attached. </font>
        $log_FE_HealthResult_MAIL
        </body></pre>
        " + $html

        # Send email...
        $subject_date = get-date -Format "dd.MM.yyyy"
        $subject_OK = "FireEye EX AV - OK - $subject_date"
        $subject_NOK = "FireEye EX AV - NOT OK - $subject_date"

        if ($SendEmail){
            if ($OK -eq 0){
                Send-MailMessage -To $MailTo -From $MailFrom -Body $body_OK -BodyAsHtml -subject $subject_OK -SmtpServer $SMTPServer -Attachments $log_FireEyeEX_health_system 
                }
            elseif ($OK -eq 1){
                Send-MailMessage -To $MailTo -From $MailFrom -Body $body_NOK -BodyAsHtml -subject $subject_NOK -SmtpServer $SMTPServer -Attachments $log_FireEyeEX_health_system  -Priority High
                }
            elseif ($OK -eq 2){
                Send-MailMessage -To $MailTo -From $MailFrom -subject "FireEye EX script failed - $subject_date" -SmtpServer $SMTPServer -Priority High -Body "FireEye EX script failed, please investigate!"
                }
        }

        # ... or output results to screen
        else {
            $log_FE_HealthResult_MAIL
        }
    }

    # clear variables and arrays
    END {
        Clear-Variable OK -ErrorAction silentlycontinue
        Stop-Transcript
        }   
}
