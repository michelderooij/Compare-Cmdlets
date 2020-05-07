<#
    .SYNOPSIS
    Compare-Cmdlets
    Script to compare cmdlets available through Exchange Online or Azure Active Directory.
    This allows you to spot any differences in cmdlets and parameters available in different
    versions of Exchange Online as well as the Azure AD module from PowerShell gallery.

    Michel de Rooij
    michel@eightwone.com

    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

    Version 1.1, May 7th, 2020

    .DESCRIPTION
    Script to compare cmdlets available through Exchange Online or Azure Active Directory.
    This allows you to spot any differences in cmdlets and parameters available in different
    versions of Exchange Online as well as the Azure AD module from PowerShell gallery.

    The script has two operating modi:

    1) Retrieving Exchange Online & Azure Active directory cmdlet information and exporting
    this information to files. This mode is used when the Export switch is specified. You need to
    be currently connected to Exchange Online or Azure Active Directory.

    2) Comparing two of these export files. looking for differences in cmdlets as well
    as parameters. This mode is used when specifying ReferenceCmds/DifferenceCmds.

    The export files are stored in the current folder and follow this naming convention:
    - ExchangeOnline-<Exchange Online build>.xml
    - AzureAD-<Azure Active Directory Module version>.xml
    - MicrosoftTeams-<MicrosoftTeams Module version>.xml

    .LINK
    http://eightwone.com

    .NOTES

    Revision History
    --------------------------------------------------------------------------------
    1.0     Initial community release
    1.01    Some changes in output format
    1.02    Added handling of not connected AzureAD session
    1.03    Added Microsoft Teams
            Removed timestamp from export files (version should do)
            Fixed version reporting when multiple versions are installed
    1.04    Added MSOnline processing
    1.05    Added InformationAction and InformationVariable to the ignored common parameters
    1.06    Added ExchangeOnlineManagement processing
    1.1     Speed up comparison using parameter lookup tables and dropping parameter sorting
            Replaced hard-coded list of common parameters with system provided list
            Changed output to use writing to host and verbose 

    .PARAMETER ReferenceCmds
    Specifies the file containing the cmdlet reference set.

    .PARAMETER DifferenceCmds
    Specifies the file containing the cmdlet difference set.

    .PARAMETER Export
    Specifies to export cmdlet information.

    .EXAMPLE
    Export information on the currently available Exchange Online and Azure AD cmdlets
    .\Compare-Cmdlets.ps1 -Export

    .EXAMPLE
    Compare two sets of cmdlets and show which cmdlets and parameters are new or removed
    .\Compare-Cmdlets.ps1 -ReferenceCmds .\ExchangeOnline-15.20.527.22.xml -DifferenceCmds .\ExchangeOnline-15.20.548.21.xml

#>
#Version 3.0

[Cmdletbinding()]
param(
    [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'Compare')]
    [ValidateScript( {Test-Path $_ -PathType 'Leaf'})]
    [String]
    $ReferenceCmds,

    [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Compare')]
    [ValidateScript( {Test-Path $_ -PathType 'Leaf'})]
    [String]
    $DifferenceCmds,

    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Export')]
    [Switch]
    $Export
)

If ( -not $Export) {
    # Comparison mode

    # Common parameters
    $SkipParams = [System.Management.Automation.PSCmdlet]::CommonParameters + [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    Write-Host ('Reading cmdlets from {0}' -f $ReferenceCmds)
    $Cmds1Table=@{}
    $Cmds1 = Import-CliXml -Path $ReferenceCmds | Select-Object Name, Parameters | Sort-Object Name
    If ( !$Cmds1) {
        Throw ('File {0} does not seem to contain any cmdlet information' -f $ReferenceCmds)
    }
    Else {
        $Cmds1 | % { $Cmds1Table[ $_.Name]= $_ }
    }
    Write-Verbose ('Reference set contains {0} cmdlets.' -f $Cmds1.Count)

    Write-Host ('Reading cmdlets from {0}' -f $DifferenceCmds)
    $Cmds2Table=@{}
    $Cmds2 = Import-CliXml -Path $DifferenceCmds | Select-Object Name, Parameters | Sort-Object Name
    If ( !$Cmds2) {
        Throw ('File {0} does not seem to contain any cmdlet information' -f $DifferenceCmds)
    }
    Else {
        $Cmds2 | % { $Cmds2Table[ $_.Name]= $_ }
    }
    Write-Verbose ('Difference set contains {0} cmdlets.' -f $Cmds2.Count)

    $Diff = Compare-Object -ReferenceObject $Cmds1 -DifferenceObject $Cmds2 -Property Name -IncludeEqual -PassThru
    $Max = $Diff.Count
    $Num = 0
    ForEach ( $Item in $Diff) {
        Write-Progress -Id 1 -Activity ('Checking {0}' -f $Item.Name) -PercentComplete ($Num / $Max * 100)
        Switch ( $Item.SideIndicator) {
            '=>' {
                $Obj = New-Object -TypeName PSCustomObject -Property @{
                    'Change'     = 'New'
                    'Type'       = 'Cmdlet'
                    'Cmdlet'     = $Item.Name
                    'Parameter'  = $null
                }
                $Obj
            }
            '<=' {
                $Obj = New-Object -TypeName PSCustomObject -Property @{
                    'Change'     = 'Removed'
                    'Type'       = 'Cmdlet'
                    'Cmdlet'     = $Item.Name
                    'Parameter'  = $null
                }
                $Obj
            }
            '==' {
                # Equal cmdlet, check parameters
                $Cmd1P = $Cmds1Table[ $Item.Name].Parameters.GetEnumerator() | Where-Object {$SkipParams -notcontains $_.Name}
                $Cmd2P = $Cmds2Table[ $Item.Name].Parameters.GetEnumerator() | Where-Object {$SkipParams -notcontains $_.Name}
                If ( [string]::IsNullOrEmpty($Cmd1P) -and [string]::IsNullOrEmpty( $Cmd2p)) {
                    # No parameters to check
                }
                Else {
                    $ParamDiff = Compare-Object -ReferenceObject $Cmd1P -DifferenceObject $Cmd2P -ErrorAction SilentlyContinue
                    ForEach ( $Param in $ParamDiff) {
                        Switch ( $Param.SideIndicator) {
                            '=>' {
                                $Obj = New-Object -TypeName PSCustomObject -Property @{
                                    'Change'    = 'New'
                                    'Type'      = 'Parameter'
                                    'Cmdlet'    = $Item.Name
                                    'Parameter' = ('{0}' -f $Param.InputObject.Name)
                                }
                                $Obj
                            }
                            '<=' {
                                $Obj = New-Object -TypeName PSCustomObject -Property @{
                                    'Change'    = 'Removed'
                                    'Type'      = 'Parameter'
                                    'Cmdlet'    = $Item.Name
                                    'Parameter' = ('{0}' -f $Param.InputObject.Name)
                                }
                                $Obj
                            }
                            '==' {
                                # Equal
                            }
                        }
                    }
                }
            }
        }
        $Num++
    }
    Write-Progress -Id 1 -Activity 'Completed' -Completed

}
Else {

    If ( Get-Command Get-Mailbox -ErrorAction SilentlyContinue) {
        $User = ((Get-PsSession | Where-Object {$_.ConfigurationName -eq 'Microsoft.Exchange' -and $_.State -eq 'Opened' -and $_.Availability -eq 'Available'} | Sort-Object Id -Descending) | Select-Object -First 1).Runspace.ConnectionInfo.Credential.UserName
        $Module = (Get-Command Get-Mailbox -ErrorAction SilentlyContinue ).Source
        $Cmdlets = Get-Command -Module $Module | Select-Object Name, Parameters
        $Version = (Get-Command Get-Mailbox -ErrorAction SilentlyContinue ).Version
        $null = [string]((Get-OrganizationConfig).AdminDisplayVersion) -match '^.*\((?<build>[\d\.]+)\)$'
        $Build = $matches.build
        $File = 'ExchangeOnline-{0}.xml' -f $Build
	If( -not( Test-Path -Path $File)) {
        	Write-Output ('Storing Exchange Online cmdlets in {0}' -f $File)
	        $Cmdlets | Export-CliXml -Path $File
	}
	Else {
		Write-Warning ('File {0} already exists' -f $File)
	}
    }
    Else {
        Write-Warning 'Exchange cmdlets not available, skipping'
    }

    If ( Get-Command Get-AzureADUser -ErrorAction SilentlyContinue) {
	Try {
        	$User = (Get-AzureADCurrentSessionInfo -ErrorAction SilentlyContinue).Account
	}
	Catch {
		$User = 'Disconnected'
	}
        $Module = (Get-Command Get-AzureADUser -ErrorAction SilentlyContinue ).Source
        $Cmdlets = Get-Command -Module $Module | Select-Object Name, Parameters
        $Version = (Get-Command Get-AzureADUser -ErrorAction SilentlyContinue ).Version
        $File = 'AzureAD-{0}.xml' -f $Version
	If( -not( Test-Path -Path $File)) {
        	Write-Output ('Storing Azure AD cmdlets in {0}' -f $File)
        	$Cmdlets | Export-CliXml -Path $File
	}
	Else {
		Write-Warning ('File {0} already exists' -f $File)
	}
    }
    Else {
        Write-Warning 'Azure AD cmdlets not available, skipping'
    }

    If ( Get-Command Get-MsolUser -ErrorAction SilentlyContinue) {
	$User = 'NA'
        $Module = (Get-Command Get-MsolUser -ErrorAction SilentlyContinue ).Source
        $Cmdlets = Get-Command -Module $Module | Select-Object Name, Parameters
        $Version = (Get-Command Get-MSolUser -ErrorAction SilentlyContinue ).Version
        $File = 'MSOnline-{0}.xml' -f $Version
	If( -not( Test-Path -Path $File)) {
        	Write-Output ('Storing MSOnline cmdlets in {0}' -f $File)
        	$Cmdlets | Export-CliXml -Path $File
	}
	Else {
		Write-Warning ('File {0} already exists' -f $File)
	}
    }
    Else {
        Write-Warning 'Azure AD cmdlets not available, skipping'
    }

    If ( Get-Command Get-Team -ErrorAction SilentlyContinue) {
	$User = 'NA'
        $Module = (Get-Command Get-Team -ErrorAction SilentlyContinue ).Source
        $Cmdlets = Get-Command -Module $Module | Select-Object Name, Parameters
        $Version = (Get-Command Get-Team -ErrorAction SilentlyContinue ).Version
        $File = 'MicrosoftTeams-{0}.xml' -f $Version
	If( -not( Test-Path -Path $File)) {
        	Write-Output ('Storing Microsoft Teams cmdlets in {0}' -f $File)
        	$Cmdlets | Export-CliXml -Path $File
	}
	Else {
		Write-Warning ('File {0} already exists' -f $File)
	}
    }
    Else {
        Write-Warning 'Microsoft Teams not available, skipping'
    }

    If ( Get-Command Get-EXOMailbox -ErrorAction SilentlyContinue) {
	$User = 'NA'
        $Module = (Get-Command Get-EXOMailbox -ErrorAction SilentlyContinue ).Source
        $Cmdlets = Get-Command -Module $Module | Select-Object Name, Parameters
        $Version = (Get-Command Get-EXOMailbox -ErrorAction SilentlyContinue ).Version
        $File = 'ExchangeOnlineManagement-{0}.xml' -f $Version
	If( -not( Test-Path -Path $File)) {
        	Write-Output ('Storing Exchange Online Management cmdlets in {0}' -f $File)
        	$Cmdlets | Export-CliXml -Path $File
	}
	Else {
		Write-Warning ('File {0} already exists' -f $File)
	}
    }
    Else {
        Write-Warning 'ExchangeOnlineManagement not available, skipping'
    }

}
