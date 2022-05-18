# Powershell
Collection of Powershell scripts I wrote, that you can use and customize as you wish. There are no comments inside of .ps1 files, because scripts were originaly written for custom environment and were not intended to be published. Some scripts are rewritten as functions for easier readability. 

* Remove-disabled-ADaccounts - find old disabled AD users and delete them
* Disable-ADUsers-lastlogondate-90days.ps1 - disable inactive AD users with last logon date more than 90 days ago
* Get-AD-system-accounts-without-owner.ps1 - find all AD service accounts without owner and other mandatory attributes
* Get-CiscoESA-AV-status.ps1 - receive Cisco ESA antivirus status
* Get-Email-domain-reputation.ps1 - receive reports for email domain reputation from Talos
* Get-Exchange-queue.ps1 - receive alerts for high Exchange email queue
* Get-FireEyeEX-AV-status.ps1 - receive FireEye EX antivirus status
* Get-Free-disk-space.ps1 - get free disk space for remote machines
* Get-HyperV-checkpoints.ps1 - receive reports about old Hyper-V checkpoints
