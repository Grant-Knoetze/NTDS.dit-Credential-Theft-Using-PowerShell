# First, import the PowerShell ActiveDirectory module.

import-module ActiveDirectory

# List all domain accounts

Get-ADUsers -filter *

# List all domain admins.

Get-ADGroupMember -Server "domain controller" -Identity "Domain Admins" - Recursive | Get-ADUsers

