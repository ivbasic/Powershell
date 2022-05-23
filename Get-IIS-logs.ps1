$servers =  #Get-Content C:\\iis_serverlis.txt

foreach ($server in $servers){
    try {
        Invoke-Command -ComputerName $server -ErrorAction stop -ScriptBlock{
            Set-ExecutionPolicy remotesigned -force
            Import-Module WebAdministration -force
	        foreach($WebSite in $(get-website)){
		        $logFile="$($Website.logFile.directory)\w3svc$($website.id)".replace("%SystemDrive%",$env:SystemDrive)
		        Write-host -NoNewline "$env:computername;$($WebSite.name);$logfile";";","{0:N2} GB" -f ((gci $logFile | measure Length -s).sum / 1Gb)	
	        }
        }
    }
    catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
        $OS = Get-WmiObject -Class Win32_OperatingSystem -Namespace root/cimv2 -ComputerName $server -ErrorAction Stop
        Write-Host "Cannot connect to $server ($([System.Net.Dns]::GetHostAddresses($server).IPAddressToString));"$OS.caption
    }
}
