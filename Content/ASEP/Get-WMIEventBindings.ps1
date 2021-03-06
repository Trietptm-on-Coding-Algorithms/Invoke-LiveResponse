<#
.SYNOPSIS
	Get-WMIEventBindings.ps1 outputs all WMI Event Filter to Consumer Bindings on local machine and enables remediation.
    
    Name: Get-WMIEventBindings.ps1
    Version: 1.1
    Author: Matt Green (@mgreen27)
    
.DESCRIPTION
    Get-WMIEventBindings.ps1 outputs all WMI Event Bindings on local machine. 
    Option to output in formatted or raw versions.
    Option to remove specific WMI Event Bindings and also using wildcards.
    Tested PS2+
    
.PARAMETER Raw
    Optional switch to output raw WMIEventBinding values instead of default parsed lists.
    
.PARAMETER Remove
    Optional parameter for specifying the WMI Event Binding path to remove. This parameter works as a CONTAINS.
    e.g -Name EvilName  :  CONTAINS *EvilName*

.PARAMETER Namespace
    Optional parameter for specifying targetted namespace. Note: typo will result in no results.

.EXAMPLE
	Get-WMIEventBindings.ps1
    
    Namespace    : ROOT\subscription
    ConsumerName : EvilConsumer
    FilterName   : EvilFilter
    Path         : \\WIN7X64\ROOT\subscription:__FilterToConsumerBinding.Consumer="EvilConsumer",Filter="EvilFilter"
    

.EXAMPLE
	Get-WMIEventBindings.ps1 -raw

    __GENUS                 : 2
    __CLASS                 : __FilterToConsumerBinding
    __SUPERCLASS            : __IndicationRelated
    __DYNASTY               : __SystemClass
    __RELPATH               : __FilterToConsumerBinding.Consumer="EvilConsumer",Filter="EvilFilter"
    __PROPERTY_COUNT        : 7
    __DERIVATION            : {__IndicationRelated, __SystemClass}
    __SERVER                : WIN7X64
    __NAMESPACE             : ROOT\subscription
    __PATH                  : \\WIN7X64\ROOT\subscription:__FilterToConsumerBinding.Consumer="EvilConsumer",Filter="EvilFilter"
    Consumer                : EvilConsumer
    CreatorSID              : {1, 5, 0, 0...}
    DeliverSynchronously    : False
    DeliveryQoS             : 
    Filter                  : EvilFilter
    MaintainSecurityContext : False
    SlowDownProviders       : False


.EXAMPLE
	Get-WMIEventBindings.ps1 -namespace ROOT\Subscription -name EvilPOC -remove 
    <LOGIC TO CONFIRM REMOVAL>
    <OUTPUT REMAINING Event Bindings>   
#>

[CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)][String]$Namespace = $Null,
        [Parameter(Mandatory = $False)][String]$Remove = $Null,
        [Parameter(Mandatory = $False)][Switch]$Raw = $False  
)


function Get-WmiNamespace {
<#
.SYNOPSIS
    Returns a list of WMI namespaces present within the specified namespace.
.PARAMETER Namespace
    Specifies the WMI repository namespace in which to list sub-namespaces. Get-WmiNamespace defaults to the ROOT namespace.
.PARAMETER Recurse
    Specifies that namespaces should be recursed upon starting from the specified root namespace.
.EXAMPLE
    Get-WmiNamespace
.EXAMPLE
    Get-WmiNamespace -Recurce
.EXAMPLE
    Get-WmiNamespace -Namespace ROOT\CIMV2
.EXAMPLE
    Get-WmiNamespace -Namespace ROOT\CIMV2 -Recurse
.OUTPUTS
    System.String
    Get-WmiNamespace returns fully-qualified names.
.NOTES    
    This version is modified from: @Matifestation
    https://gist.githubusercontent.com/mattifestation/69c50a87044ba1b22eaebcb79e352144/raw/f4a41dff4eb8cf0db30a34e17ac15327cdb797e8/WmiNamespace.ps1
    
    Initially inspired from: Boe Prox
    https://github.com/KurtDeGreeff/PlayPowershell/blob/master/Get-WMINamespace.ps1
#>

    [OutputType([String])]
    Param (
        [String][ValidateNotNullOrEmpty()]$Namespace = "ROOT",
        [Switch]$Recurse
    )

    $BoundParamsCopy = $PSBoundParameters
    $null = $BoundParamsCopy.Remove("Namespace")

    # To Exclude locale specific namespaces replace line below with Get-WmiObject -Class __NAMESPACE -Namespace $Namespace -Filter 'NOT Name LIKE "ms_4%"' |
    Get-WmiObject -Class __NAMESPACE -Namespace $Namespace |
    ForEach-Object {
        $FullyQualifiedNamespace = "{0}\{1}" -f $_.__NAMESPACE, $_.Name
        $FullyQualifiedNamespace

        if ($Recurse) {
            Get-WmiNamespace -Namespace $FullyQualifiedNamespace @BoundParamsCopy
        }
    }
}



function Remove-WMIEventBindings {
<#
.SYNOPSIS
    Removes specified WMIEventBinding
.PARAMETER Namespace
    Specifies the WMI repository namespace in which to list sub-namespaces. Get-WmiNamespace defaults to the ROOT\Subscription namespace.
.PARAMETER Name
    Specifies that namespaces should be recursed upon starting from the specified root namespace.
.PARAMETER Like
    Switch to remove Like %Name%
.EXAMPLE
    Remove-WMIEventBindings -Namespace ROOT\CIMV2 -Name EvilPOC
.OUTPUTS

.NOTES    
#>

[OutputType([String])]
    Param (
        [Parameter(Mandatory = $False)][String]$Namespace = $Null,
        [Parameter(Mandatory = $False)][String]$Remove = $Null
)
    
    $ToRemove = $False    
    $Output = @()
    Get-WmiObject -Namespace $Namespace -Class "__FilterToConsumerBinding" -ErrorAction silentlycontinue | where-object {$_.Path -Like "*" + $Remove + "*"} | Foreach {
        $Line = "" | Select Namespace, ConsumerName, ConsumerType, FilterName, Path
        $Line.Namespace = $_.__Namespace
        
        $Line.ConsumerName = (($_.Consumer -split '="')[1] -split '"')[0]
        If($Line.ConsumerName.length -lt 1){$Line.ConsumerName = $_.Consumer}
        $Line.ConsumerType = ($_.Consumer -split '.name')[0]
        If($Line.ConsumerType -eq $Line.ConsumerName){$Line.ConsumerType = ""}
            
        $Line.FilterName = (($_.Filter -split '="')[1] -split '"')[0]
        If($Line.FilterName.length -lt 1){$Line.FilterName = $_.Filter}
        $Line.Path = $_.Path
        
        $Output += $Line
        $ToRemove = $True
    }
    If ($ToRemove){
        Write-Host -ForegroundColor Red "`nItems to remove:"
        $Output | Format-List
            
        write-host -ForegroundColor Red -nonewline "Are you sure you want to remove? (Y/N) "
        $Response = read-host
        if ($Response -ne "Y") {exit}
                
        Get-WmiObject -Namespace $Namespace -Class "__FilterToConsumerBinding" -ErrorAction silentlycontinue | where-object {$_.Path -Like "*" + $Remove + "*"}  | Remove-WmiObject
    }   
    If(!($ToRemove)){Write-Host -ForegroundColor Yellow "No WMIEventBinding found to remove. Printing availible Bindings - Please check spelling."}
    Else{Write-Host -ForegroundColor Yellow "Printing remaining Bindings."}
}

# Main

If($Remove){
    If (!$Namespace){$Namespace = Read-Host -Prompt "Enter WMI Namespace you would like to remove Binding"}
    Remove-WMIEventBindings -Namespace $NameSpace -Remove $Remove
}

If($Namespace){
    $Namespaces = @()
    $Namespaces += $Namespace
    $Namespaces += $(Get-WmiNamespace -Namespace $Namespace -recurse)
}
Else {$Namespaces = Get-WmiNamespace -recurse}


# Running WMIEventBindings Enumeration at the end.
ForEach ($NameSpace in $Namespaces){
    If ($Raw){Get-WmiObject -Namespace $Namespace -Class "__FilterToConsumerBinding" -ErrorAction silentlycontinue}
    Else{
        $output=@()
        Get-WmiObject -Namespace $Namespace -Class "__FilterToConsumerBinding" -ErrorAction silentlycontinue | Foreach {
            $Line = "" | Select Namespace, ConsumerName, ConsumerType, FilterName, Path
            $Line.Namespace = $_.__Namespace
            
            $Line.ConsumerName = (($_.Consumer -split '="')[1] -split '"')[0]
            If($Line.ConsumerName.length -lt 1){$Line.ConsumerName = $_.Consumer}
            $Line.ConsumerType = ($_.Consumer -split '.name')[0]
            If($Line.ConsumerType -eq $Line.ConsumerName){$Line.ConsumerType = ""}
            
            $Line.FilterName = (($_.Filter -split '="')[1] -split '"')[0]
            If($Line.FilterName.length -lt 1){$Line.FilterName = $_.Filter}
            $Line.Path = $_.Path
            
            $Output += $Line
        }
        $Output | Format-List
            
    }
}
