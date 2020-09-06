# Compare-Cmdlets

## Getting Started

Script to compare cmdlets available through supported modules. 

The script allows you to spot any differences in cmdlets and parameters available in different 
versions of those modules, such as new or removed cmdlets, changes in parameters, etc. To accomplish 
this, first export currently available cmdlet and parameter sets to XML files. Then use the script
to compare two sets of XML files, and it will report on differences, for example:

<pre>
❯ .\Compare-Cmdlets.ps1 -ReferenceCmds .\MicrosoftTeams-1.1.4.xml -DifferenceCmds .\MicrosoftTeams-1.1.5.xml
Reading cmdlets from .\MicrosoftTeams-1.1.4.xml
Reading cmdlets from .\MicrosoftTeams-1.1.5.xml

Change  Cmdlet                               Type      Parameter
------  ------                               ----      ---------
Removed Get-CsBatchPolicyAssignmentOperation Parameter Break
Removed Get-CsGroupPolicyAssignment          Parameter Break
New     Get-TeamChannel                      Parameter GroupId
Removed New-CsBatchPolicyAssignmentOperation Parameter HttpPipelineAppend
Removed New-CsGroupPolicyAssignment          Parameter PolicyType
Removed New-CsGroupPolicyAssignment          Parameter Break
New     New-Team                             Parameter AllowChannelMentions
New     New-Team                             Parameter AllowCustomMemes
New     New-TeamChannel                      Parameter MembershipType
New     New-TeamChannel                      Parameter GroupId
Removed Remove-CsGroupPolicyAssignment       Parameter Break
New     Set-Team                             Parameter AllowCustomMemes
New     Add-TeamChannelUser                  Cmdlet
New     Add-TeamsAppInstallation             Cmdlet
New     Get-CsOnlinePowerShellEndpoint       Cmdlet
New     Get-TeamChannelUser                  Cmdlet
New     Get-TeamsAppInstallation             Cmdlet
New     New-CsOnlineSession                  Cmdlet
New     Remove-TeamChannelUser               Cmdlet
New     Remove-TeamsAppInstallation          Cmdlet
New     Remove-TeamTargetingHierarchy        Cmdlet
New     Set-CsGroupPolicyAssignment          Cmdlet
New     Set-TeamTargetingHierarchy           Cmdlet
New     Update-TeamsAppInstallation          Cmdlet
</pre>

### Prerequisites

* PowerShell 3.0
* For exporting cmdlet information, you need to be connected to Exchange Online or Azure Active Directory

### Usage

Export information on the currently available Exchange Online and Azure AD cmdlets
```
.\Compare-Cmdlets.ps1 -Export
```

Compare two sets of cmdlets and show which cmdlets and parameters are new or removed
```
.\Compare-Cmdlets.ps1 -ReferenceCmds .\201803011416-ExchangeOnline-15.20.527.22.xml -DifferenceCmds .\201803121707-ExchangeOnline-15.20.548.21.xml
```

## License

This project is licensed under the MIT License - see the LICENSE.md for details.

