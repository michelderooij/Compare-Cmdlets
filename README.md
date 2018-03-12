# Compare-Cmdlets

## Getting Started

Script to compare cmdlets available through Exchange Online or Azure Active Directory.
This allows you to spot any differences in cmdlets and parameters available in different
versions of Exchange Online as well as the Azure AD module from PowerShell gallery.

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

