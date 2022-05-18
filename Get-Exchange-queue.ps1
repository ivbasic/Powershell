function Get-Exchange-queue {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [String[]]$ExchServerList,
        [parameter(Mandatory=$true)]
        [Int]$MaxQueueSize
    )


    BEGIN {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;
    }

    PROCESS {
        # Get Exchange queue
        $ExchServers = foreach ($ExchServer in $ExchServerList){
            get-exchangeserver $ExchServer
            }
        $Q = foreach ($ExchServer in $ExchServers) {
            ((get-queue -server $ExchServer.Name -Filter 'DeliveryType -ne "ShadowRedundancy"').messagecount | Measure-Object -Sum).sum   
            }  
        $Queue = ($Q | Measure-Object -sum).sum

        # Get Exchange Admin phone numbers
        $AdminMobileNumbers = ((get-adgroup "<AdministratorGroup>" | Get-ADGroupMember -Recursive | get-aduser -Properties mobile).mobile | 
        ForEach-Object {
            ($_).substring(1) -replace ",", ""
            }) 

        # Send alerts
        $SMS = "Exchange queue too large!"
        if ($Queue -gt $MaxQueueSize){
            foreach ($Number in $AdminMobileNumbers){
                # SMS
                Invoke-WebRequest "http://smsgw.domain.com/xxxx/xxxx/xxxx?from=alert&to=$Number&text=$SMS" -Method Get -UseBasicParsing | Out-Null
                # Email
                Send-MailMessage -From Exchange@domain.com -to recipient@domain.com -SmtpServer smtp.domain.com -subject "Exchange queue too large!" -Body "Exchange queue too large!"
                }
            }
        }
    }
