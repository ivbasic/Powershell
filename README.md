# Powershell
Collection of my Powershell scripts that you can use and customize as you wish. There are no comments inside of .ps1 files, because scripts were originaly written for custom environment and were not intended to be published. Some scripts are rewritten as functions for easier readability. 

* Remove-disabled-ADaccounts - delete AD accounts disabled more than 90 days ago
* Send-service-ADaccount-alert - send alert to owners of AD service accounts with password older than 1 year
* Disable-ADaccounts-lastlogondate-90days.ps1 - disable inactive AD accounts with last logon date more than 90 days ago
* Get-CiscoESA-AV-status.ps1 - receive Cisco ESA antivirus status
* Get-Exchange-queue.ps1 - receive alerts for high Exchange email queue
* Get-FireEyeEX-AV-status.ps1 - receive FireEye EX antivirus status
* Get-HyperV-checkpoints.ps1 - receive reports about old Hyper-V checkpoints
* Get-email-domain-reputation.ps1 - receive reports for email domain reputation from Talos
* Get-free-disk-space.ps1 - get free disk space for remote machines
* Get-service-ADaccounts-without-owner.ps1 - find all AD service accounts without owner and other mandatory attributes
