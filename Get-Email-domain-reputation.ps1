function Get-Email-domain-reputation {
    [CmdletBinding()]
    param (
        [String[]]$OutgoingServerName,
        [String[]]$OutgoingServerIP,
        [String]$SendEmail,
        [String]$MailFrom,
        [String]$MailTo,
        [String]$SMTPServer
    )

    BEGIN {
        }

    PROCESS {
        # check reputation of outgoing email server hostnames
        if (($OutgoingServerName) -and ($null -eq $OutgoingServerIP)){
            $Reputation_results = foreach ($ServerName in $OutgoingServerName){

                $URL_hostname = "https://talosintelligence.com/cloud_intel/host_info?hostname="+$ServerName
                $URL_hostname_results = ((Invoke-WebRequest $URL_hostname | ConvertFrom-Json).related_ips) 

                $URL_IP = "https://talosintelligence.com/cloud_intel/ip_reputation?ip="+($URL_hostname_results | %{$_.address})
                $URL_IP_results = ((Invoke-WebRequest $URL_IP | ConvertFrom-Json).reputation) 
                
                [PSCustomObject]@{
                    "hostname" = $URL_IP_results.hostname
                    "address" = ($URL_hostname_results | %{$_.address})
                    "email reputation" = $URL_IP_results.threat_level_mnemonic
                    "spam level" = $URL_IP_results.spam_level
                    "block_lists" = $URL_hostname_results.block_lists
                    "daychange" = $URL_IP_results.daychange
                    "url" = ("https://talosintelligence.com/reputation_center/lookup?search="+$ServerName)
                }
            }
            
        }
        # check reputation of outgoing email server IP addresses
        if (($OutgoingServerIP) -and ($null -eq $OutgoingServerName)){
            $Reputation_results = foreach ($IP in $OutgoingServerIP){
                
                $URL_IP = "https://talosintelligence.com/cloud_intel/ip_reputation?ip="+$IP
                $URL_IP_results = ((Invoke-WebRequest $URL_IP | ConvertFrom-Json).reputation) 

                $URL_hostname = "https://talosintelligence.com/cloud_intel/host_info?hostname="+($URL_IP_results).hostname
                $URL_hostname_results = ((Invoke-WebRequest $URL_hostname | ConvertFrom-Json).related_ips) 
               
                [PSCustomObject]@{
                    "hostname" = $URL_IP_results.hostname
                    "address" = ($URL_hostname_results | %{$_.address})
                    "email reputation" = $URL_IP_results.threat_level_mnemonic
                    "spam level" = $URL_IP_results.spam_level
                    "block_lists" = $URL_hostname_results.block_lists
                    "daychange" = $URL_IP_results.daychange
                    "url" = ("https://talosintelligence.com/reputation_center/lookup?search="+$IP)
                }
            }
        }

        if ($OutgoingServerIP -and $OutgoingServerName) {
            Throw "Error: use OutgoingServerName OR OutgoingServerIP"
        }

        # Send email ...
        if ($SendEmail){
            Send-MailMessage -To $MailTo -From $MailFrom -subject "Email reputation report" -SmtpServer $SMTPServer -Body ($Reputation_results | Format-List | Out-String) 
        }
        
        # ... or output results to screen
        else {
            $Reputation_results
        }
    }
    # clear variables and array
    END {
        Clear-Variable Reputation_results -ErrorAction silentlycontinue
        }   
}
