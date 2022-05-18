function Get-Free-disk-space {
    [CmdletBinding()]
    param (
        [String[]]$ServerName,
        [String]$ServerList,
        [String]$Report,
        [String]$SendEmail,
        [String]$MailFrom,
        [String]$MailTo,
        [String]$SMTPServer
    )

    BEGIN {
        }

    PROCESS {
        # error handing 
        if ($ServerList -and $ServerName){
            Write-Host "Use only one of the switches: -ServerName or -ServerList" -Foregroundcolor Red
            break
        }

        # cant use "[String[]]$ServerName = ($env:COMPUTERNAME)" as parameter because of two many IFs in this Function which are used for error handling
        if (!($ServerList) -and !($ServerName)){
            $ServerName = $env:COMPUTERNAME
        }

        # import server list from .txt
        if ($ServerList){
            $ServerName = (Get-Content $ServerList -ErrorAction silentlycontinue)
            if (($null -eq $ServerName) -or ($ServerList -notlike "*.txt")) {
                Write-Host "Can't import $ServerList" -Foregroundcolor Red
                break
            }
        } 

        # get free disk space for servers and add results to array
        $Counter = 0
        $DriveInfoResults = foreach ($Server in $ServerName){
            $Counter++
            Write-Progress -Activity "Get-FreeDiskSpace" -CurrentOperation $Server -PercentComplete (($Counter / $ServerName.count) * 100)
            $DriveInfo = Get-WMIobject win32_LogicalDisk -ComputerName $Server -filter "DriveType=3" -ErrorAction silentlycontinue |
            Select-Object SystemName, DeviceID, VolumeName,
            @{Name="Size(GB)"; Expression={"{0:N1}" -f($_.size/1gb)}},
            @{Name="FreeSpace(GB)"; Expression={"{0:N1}" -f($_.freespace/1gb)}},
            @{Name="FreeSpace(%)"; Expression={"{0:N2}%" -f(($_.freespace/$_.size)*100)}} 
            
            if ($null -eq $DriveInfo){
                $Server_Error += ("`n" + $Server)
                } 
            else{
                foreach ($Drive in $DriveInfo){
                    Write-Output $Drive

                    $SystemName = $Drive.SystemName
                    $DeviceID = $Drive.DeviceID
                    $VolumeName = $Drive.VolumeName
                    $Size_GB = $Drive.'Size(GB)'
                    $FreeSpace_GB = $Drive.'FreeSpace(GB)'
                    $FreeSpace_P = $Drive.'FreeSpace(%)'

                    $DataRow = "
                    </tr>
                    <td>$SystemName</td>
                    <td>$DeviceID</td>
                    <td>$VolumeName</td>
                    <td>$Size_GB</td>
                    <td>$FreeSpace_GB</td>
                    <td>$FreeSpace_P</td>
                    </tr>
                    "
                    $FreeSpaceReport += $DataRow
                }
            }
        }

        # error connecting to servers (server does not exists, missing permissions, etc)
        if ($null -ne $Server_Error){
            Write-Host "Can't connect to following Server(s):" -Foregroundcolor Red -nonewline
            Write-Host $Server_Error 
        }
        
        # output results to screen if no switch is specified 
        if (!($Report) -and !($SendEmail)){
            $DriveInfoResults | Format-Table 
        }

        # write results to file
        if ($Report){
            $FileName = "$Report\FreeDiskSpace_$((Get-Date).ToString('dd-MM-yyyy')).csv"

            try {
                $DriveInfoResults | Export-Csv -Path "$FileName" -Force -NoTypeInformation -Delimiter ";" 
                Write-Host "Report saved: $FileName" -Foregroundcolor Green
                }
            catch {
                Write-Host $_.Exception.Message -Foregroundcolor Red
                }
        }

        # send results in an email
        if ($SendEmail){  
            Write-Output "`nSending email..."
		
            $EmailReport = "<html>
            <style>
            {font-family: Verdana; font-size: 10pt;}
            TABLE{border: 1px solid black; border-collapse: collapse; font-size:10pt;}
            TH{border: 1px solid black; background: #c9e1ff; padding: 5px; color: #000000;font-family: Verdana; font-size: 10pt;}
            TD{border: 1px solid black; padding: 5px;font-family: Verdana; font-size: 10pt;}
            H3{font-family: Verdana; font-size: 10pt;}
            </style>
            <body><font face='verdana' size='2'>
            Free disk space report: 
            <br>
            <br>
            </font></body>
            <table>
            <tr>
            <th>SystemName</th>
            <th>DeviceID</th>
            <th>VolumeName</th>
            <th>Size(GB)</th>
            <th>FreeSpace(GB)</th>
            <th>FreeSpace(%)</th>
            </tr>
            $FreeSpaceReport
            </table>
            <body><font face='verdana' size='2'>
            <br>
            <br>
            *** 
            <br>
            </font></body>
            "

            try {
                Send-MailMessage -From $MailFrom -To $MailTo -Subject "Free Disk Space_$((Get-Date).ToString('dd-MM-yyyy'))" -Body $EmailReport -BodyAsHTML -SmtpServer $SMTPServer
                Write-Host "`nEmail is sent if there are no errors." -Foregroundcolor yellow
            }
            catch {
                Write-Host $_.Exception.Message -Foregroundcolor Red
                }
        }
    }
    
    # clear variables and array
    End {
        Clear-Variable DriveInfo -ErrorAction silentlycontinue
        Clear-Variable FreeSpaceReport -ErrorAction silentlycontinue
        Clear-Variable Server_Error -ErrorAction silentlycontinue
        }   
}
