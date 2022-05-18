Basically, create and schedule Splunk report to get all users disabled between 90-97 days ago, send that report to some onpremise mailbox, use EWS and Powershell to download the attachment, filter attachment for users, send email notification to IT support department, delete users the next day. 

```
.
├── 1-Get-disabled-ADaccounts.ps1
├── 2-Remove-disabled-ADaccounts.ps1
└── files
    ├── _whitelist.txt
    ├── 1-Splunk-report
    ├── 2_filtered-from-Splunk-report
    └── 3-deleted-AD-accounts
```
