# server list
$ServerList = Get-Content -path "C:\ServerList.txt" 
$Table = New-Object System.Data.DataTable
$Table.Columns.AddRange(@("ComputerName","Windows Edition","Version","SCCM total","SCCM not started","SCCM pending","SCCM need restart","SCCM failed","Windows Update History (-24h)","Last Restarted", "Pending Restart"))

# scriptblock for remote servers
$block = {
    $ServerProductName = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' –Name ProductName).ProductName
    try {
        $ServerVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' –Name ReleaseID –ErrorAction Stop).ReleaseID
        }
    Catch {$ServerVersion = "N/A"}

    $Last24h = (get-date).AddDays(-1) 
    $InstalledUpdates_WindowsUpdateHistory = (Get-HotFix | where InstalledOn -gt $Last24h).count # check Widnows Update History
    $LastRestarted = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime 
    
    # check SCMM updates
    try {
        $TargetedUpdates = Get-WmiObject -Namespace root\CCM\ClientSDK -Class CCM_SoftwareUpdate -Filter ComplianceState=0 
        $ApprovedUpdates = ($TargetedUpdates | Measure-Object).count  # total number of updates
        $NonestateUpdates = ($TargetedUpdates | Where-Object {$_.EvaluationState -eq 0} | Measure-Object).count # number of 'ready to install' updates
        $PendingUpdates = ($TargetedUpdates | Where-Object {$_.EvaluationState -ne 8} | Measure-Object).count # number of 'not installed' updates
        $RebootUpdates = ($TargetedUpdates | Where-Object {$_.EvaluationState -eq 8} | Measure-Object).count # number of 'needs restart' updates
        $FailedUpdates = ($TargetedUpdates | Where-Object {$_.EvaluationState -eq 13} | Measure-Object).count # number of 'failed' updates
        }
    catch {}
    
    <#
    if (not installed){
        start installation
        }
    if (pending reboot){
        reboot
        }
    else ()
    #>
    
    # check if pending restart:
    $PendingRestart = $false
    if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) {$PendingRestart = $true}
    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) {$PendingRestart = $true}
    try { 
        $SCCM = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities" 
        $SCCMReboot = $SCCM.DetermineIfRebootPending()
        if(($SCCMReboot -ne $null) -and (($SCCMReboot.RebootPending -eq $true) -or ($SCCMReboot.IsHardRebootPending -eq $true))){
            $PendingRestart = $true
            }
        }
    catch {}
    
    $TempTable = New-Object System.Data.DataTable
    $TempTable.Columns.AddRange(@("ComputerName","Windows Edition","Version","SCCM total","SCCM not started","SCCM pending","SCCM need restart","SCCM failed","Windows Update History (-24h)","Last Restarted","Pending Restart"))
    [void]$TempTable.Rows.Add($env:COMPUTERNAME,$ServerProductName,$ServerVersion,$ApprovedUpdates,$NonestateUpdates,$PendingUpdates,$RebootUpdates,$FailedUpdates,$InstalledUpdates_WindowsUpdateHistory,$LastRestarted,$PendingRestart)   
    Return $TempTable
}

cls 
echo "`nCannot connect to:`n"

# measure time
$StopwatchStart = $(get-date)
$i = 0
foreach($Server in $ServerList){
    $i = $i + 1 
    $j = ($ServerList).count
    Write-Progress -Activity "checking installed updates for $server" -Status "$i/$j complete" ;
    $Result = Invoke-Command -ComputerName $Server -ScriptBlock $block
    [void]$Table.Rows.Add($Result.Computername,$Result.'Windows Edition',$Result.Version,$Result.'SCCM total',$Result.'SCCM not started',$Result.'SCCM pending',$Result.'SCCM need restart',$Result.'SCCM failed',$Result.'Windows Update History (-24h)',$Result.'Last Restarted',$Result.'Pending Restart')
} 

# results
$StopwatchStop = (($(get-date) - $StopwatchStart)).totalseconds
$StopwatchTime = [math]::Round($StopwatchStop)
write-host "`n`n" $StopwatchTime "seconds needed to check" ($ServerList).count "servers. "
Return $Table | ft ComputerName, 'Windows Edition', 'Version', 'SCCM total', 'SCCM not started', 'SCCM pending', 'SCCM need restart', 'SCCM failed', 'Windows Update History (-24h)', 'Last Restarted', 'Pending Restart'
