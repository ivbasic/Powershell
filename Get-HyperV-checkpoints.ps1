function Get-HyperV-Checkpoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)][String]$SCVMMServer,
        [Parameter(Mandatory=$True)][int]$Days,
        [String]$VMIgnoreList,
        [String]$SendEmail,
        [String]$MailFrom,
        [String]$MailTo,
        [String]$SMTPServer
    )

    BEGIN {
        Get-SCVMMServer -ComputerName $SCVMMServer | Out-Null
        $Date = (Get-date).AddDays(-$Days) | Get-Date -Format "MM/dd/yyyy"
    }

    PROCESS {

        if ($VMIgnoreList){
            $VMIgnore = (Get-Content $VMIgnoreList -ErrorAction silentlycontinue)
            if ($VMIgnoreList -notlike "*.txt") {
                Write-Host "Can't get VM ignore list $VMIgnoreList" -Foregroundcolor Red
                break
            }
        } 

        $VMCheckpoints = Get-SCVMCheckpoint -VMMServer $SCVMMServer | Where-Object {($VMIgnore -notcontains $_.VM) -and ($_.AddedTime -lt $Date)} 
        

        # send results in an email
        if (($SendEmail) -and ($null -ne $VMCheckpoints)){  

             foreach($Checkpoint in $VMCheckpoints){
                $AddedTime = ($Checkpoint.AddedTime).ToString("MM/dd/yyyy")
                $VM = $Checkpoint.VM
                $Name = $Checkpoint.Name
                $Description = $Checkpoint.Description
                $DataRow = "
                </tr>
                <td>$AddedTime</td>
                <td>$VM</td>
                <td>$Name</td>
                <td>$Description</td>
                </tr>
                "
                $VMCheckpointReport += $DataRow
            }
            foreach($Ignore in $VMIgnore){
                $IgnoreReport += $Ignore 
                $IgnoreReport += "<br>"
            }
       
        
            $EmailReport = "<html>
            <style>
            {font-family: Verdana; font-size: 10pt;}
            TABLE{border: 1px solid black; border-collapse: collapse; font-size:10pt;}
            TH{border: 1px solid black; background: #c9e1ff; padding: 5px; color: #000000;font-family: Verdana; font-size: 10pt;}
            TD{border: 1px solid black; padding: 5px;font-family: Verdana; font-size: 10pt;}
            H3{font-family: Verdana; font-size: 10pt;}
            </style>
            <body><font face='verdana' size='2'>
            There are checkpoints older than $Days, please check if they're still needed: 
            <br>
            <br>
            </font></body>
            <table>
            <tr>
            <th>Date</th>
            <th>VM</th>
            <th>Name</th>
            <th>Description</th>

            </tr>
            $VMCheckpointReport
            </table>
            <body><font face='verdana' size='2'>
            <br>
            <b>This script ignores following servers:</b>
            <br>
            $IgnoreReport
            <br>
            <br>
            *** 
            </font></body>
            "

            if (($null -ne $VMCheckpoints) -and ($VMCheckpoints.AddedTime -lt (Get-Date).AddDays(-$Days))){
                Send-MailMessage -From $MailFrom -To $MailTo -Body $EmailReport -BodyAsHTML -Subject "Hyper-V Checkpoint report" -SmtpServer $SMTPServer
                Write-Host "`nEmail is sent if there are no errors." -Foregroundcolor Yellow
            }
        }

        # output results to screen if SendEmail switch is not specified 
        else {
            $VMCheckpoints | Format-Table AddedTime, VM, Name, Description
        }
    }
        
    # clear variables and arrays
    END {
        Clear-Variable VMCheckpoints -ErrorAction silentlycontinue
        Clear-Variable CheckpointReport -ErrorAction silentlycontinue
        Clear-Variable IgnoreReport -ErrorAction silentlycontinue
        }   
}
