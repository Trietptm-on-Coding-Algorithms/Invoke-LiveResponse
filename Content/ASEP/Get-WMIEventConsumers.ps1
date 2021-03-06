<#
.SYNOPSIS
	Get-WMIEventConsumers.ps1 outputs all WMI Event Consumers on local machine and enables remediation.
    
    Name: WMIEventConsulmers.ps1
    Version: 1.1
    Author: Matt Green (@mgreen27)
    
.DESCRIPTION
    Get-WMIEventConsumers.ps1 outputs all WMI Event Consumers on local machine after parsing all availible Namespaces.
    Option to output in formatted or raw versions.
    Option to target specific Namespace to increase speed.
    Option to remove specific WMI Event Consumers and also using wildcards.
    Tested PS2+
    
.PARAMETER Raw
    Optional switch to output raw WMIEventConsumer values instead of default parsed lists.
    
.PARAMETER Remove
    Optional parameter for specifying the name of the WMI Event Consumer to remove. Note: typo will result in no fields.

.PARAMETER Namespace
    Optional parameter for specifying targetted namespace. Required to remove. Note: typo will result in no results.

.PARAMETER Like
    Optional switch for specifying Consumername paramater is a contains.
    e.g -Name EvilName -like  :  CONTAINS *EvilName*
    
.EXAMPLE
	Get-WMIEventConsumers.ps1
    
    Namespace    : ROOT\subscription
    ConsumerName : EvilPOC
    ConsumerType : CommandLineEventConsumer
    Payload      : powershell -enc "VwByAGkAdABlAC0ASABvAHMAdAAgACIAJAAoAFsARABhAHQAZQBUAGkAbQBlAF0AOgA6AE4AbwB3ACkAIABUAGU
                   AcwB0AGkAbgBnACAAVwBNAEkARQB2AGUAbgB0AEMAbwBuAHMAdQBtAGUAcgAiADsAIgAkACgAWwBEAGEAdABlAFQAaQBtAGUAXQA6ADo
                   ATgBvAHcAKQAgAFQAZQBzAHQAaQBuAGcAIABXAE0ASQBFAHYAZQBuAHQAQwBvAG4AcwB
                   1AG0AZQByACIAIAB8ACAATwB1AHQALQBGAGkAbABlACAAKABKAG8AaQBuAC0AUABhAHQAaAAgACQARQBuAHYAOgBUAEUATQBQACAAcgB
                   lAHMAdQBsAHQALgB0AHgAdAApACAALQBBAHAAcABlAG4AZAA7AFMAdABhAHIAdAAtAHMAbABlAGUAcAAgAC0AcwBlAGMAbwBuAGQAcwA
                   gADIA"
    
.EXAMPLE
	Get-WMIEventConsumers.ps1 -raw
    
    __GENUS               : 2
    __CLASS               : CommandLineEventConsumer
    __SUPERCLASS          : __EventConsumer
    __DYNASTY             : __SystemClass
    __RELPATH             : CommandLineEventConsumer.Name="EvilPOC"
    __PROPERTY_COUNT      : 27
    __DERIVATION          : {__EventConsumer, __IndicationRelated, __SystemClass}
    __SERVER              : WIN7X64
    __NAMESPACE           : ROOT\subscription
    __PATH                : \\WIN7X64\ROOT\subscription:CommandLineEventConsumer.Name="EvilPOC"
    CommandLineTemplate   : powershell -enc "VwByAGkAdABlAC0ASABvAHMAdAAgACIAJAAoAFsARABhAHQAZQBUAGkAbQBlAF0AOgA6AE4AbwB3AC
                            kAIABUAGUAcwB0AGkAbgBnACAAVwBNAEkARQB2AGUAbgB0AEMAbwBuAHMAdQBtAGUAcgAiADsAIgAkACgAWwBEAGEAdABlA
                            FQAaQBtAGUAXQA6ADoATgBvAHcAKQAgAFQAZQBzAHQAaQBuAGcAIABXAE0ASQBFAHYAZQBuAHQAQwBvAG4AcwB
                            1AG0AZQByACIAIAB8ACAATwB1AHQALQBGAGkAbABlACAAKABKAG8AaQBuAC0AUABhAHQAaAAgACQARQBuAHYAOgBUAEUATQ
                            BQACAAcgBlAHMAdQBsAHQALgB0AHgAdAApACAALQBBAHAAcABlAG4AZAA7AFMAdABhAHIAdAAtAHMAbABlAGUAcAAgAC0Ac
                            wBlAGMAbwBuAGQAcwAgADIA"
    CreateNewConsole      : False
    CreateNewProcessGroup : False
    CreateSeparateWowVdm  : False
    CreateSharedWowVdm    : False
    CreatorSID            : {1, 5, 0, 0...}
    DesktopName           :
    ExecutablePath        :
    FillAttribute         :
    ForceOffFeedback      : False
    ForceOnFeedback       : False
    KillTimeout           : 0
    MachineName           :
    MaximumQueueSize      :
    Name                  : EvilPOC
    Priority              : 32
    RunInteractively      : False
    ShowWindowCommand     :
    UseDefaultErrorMode   : False
    WindowTitle           :
    WorkingDirectory      :
    XCoordinate           :
    XNumCharacters        :
    XSize                 :
    YCoordinate           :
    YNumCharacters        :
    YSize                 :


.EXAMPLE
	Get-WMIEventConsumers.ps1 -namespace ROOT\Subscription -remove EvilPOC
    <LOGIC TO CONFIRM REMOVAL>
    <OUTPUT REMAINING Event Consumers>   
#>

[CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)][String]$Namespace = $Null,
        [Parameter(Mandatory = $False)][String]$Remove = $Null,
        [Parameter(Mandatory = $False)][Switch]$Like = $False,
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



function Remove-WMIEventConsumers {
<#
.SYNOPSIS
    Removes specified WMIEventConsumer
.PARAMETER Namespace
    Specifies the WMI repository namespace in which to list sub-namespaces. Get-WmiNamespace defaults to the ROOT\Subscription namespace.
.PARAMETER Name
    Specifies that namespaces should be recursed upon starting from the specified root namespace.
.PARAMETER Like
    Switch to remove Like %Name%
.EXAMPLE
    Remove-WMIEventConsumers -Namespace ROOT\CIMV2 -Name EvilPOC
.OUTPUTS

.NOTES    
#>

[OutputType([String])]
    Param (
        [Parameter(Mandatory = $False)][String]$Namespace = $Null,
        [Parameter(Mandatory = $False)][String]$Remove = $Null,
        [Parameter(Mandatory = $False)][Switch]$Like = $False
)
    
    $ToRemove = $False    
    If ($Like){
        $Output = @()
        Get-WmiObject -Namespace $Namespace -Class "__EventConsumer" -ErrorAction silentlycontinue | where-object {$_.Name -Like "*" + $Remove + "*"} | Foreach {
            $Line = "" | Select Namespace, ConsumerName, ConsumerType, Payload
            $Line.Namespace = $_.__Namespace
            $Line.ConsumerName = $_.Name
            $Line.ConsumerType = $_.__CLASS
            If($_.ExecutablePath){$Line.Payload = $_.ExecutablePath}
            If($_.CommandLineTemplate){$Line.Payload = $_.CommandLineTemplate}
            If($_.ScriptFileName){$Line.Payload = $_.ScriptFileName}
            If($_.ScriptText){$Line.Payload = $_.ScriptText}
            If($_.SourceName){$Line.Payload = "N/A"}
            $Output += $Line
            $ToRemove = $True
        }
        If ($ToRemove){
            Write-Host -ForegroundColor Red "`nItems to remove:"
            $Output | Format-List
            
            write-host -ForegroundColor Red -nonewline "Are you sure you want to remove? (Y/N) "
            $Response = read-host
            if ($Response -ne "Y") {exit}
                
            Get-WmiObject -Namespace $Namespace -Class "__EventConsumer" -ErrorAction silentlycontinue | where-object {$_.Name -Like "*" + $Remove + "*"}  | Remove-WmiObject
        }   
    }
    Else{
        $Output = @()
        Get-WmiObject -Namespace $Namespace -Class "__EventConsumer" -ErrorAction silentlycontinue | where-object {$_.Name -eq $Remove} | Foreach {
            $Line = "" | Select Namespace, ConsumerName, ConsumerType, Payload
            $Line.Namespace = $_.__Namespace
            $Line.ConsumerName = $_.Name
            $Line.ConsumerType = $_.__CLASS
            If($_.ExecutablePath){$Line.Payload = $_.ExecutablePath}
            If($_.CommandLineTemplate){$Line.Payload = $_.CommandLineTemplate}
            If($_.ScriptFileName){$Line.Payload = $_.ScriptFileName}
            If($_.ScriptText){$Line.Payload = $_.ScriptText}
            If($_.SourceName){$Line.Payload = "N/A"}
            $Output += $Line
            $ToRemove = $True
        }
        
        If ($ToRemove){
            Write-Host -ForegroundColor Red "Item to remove:"
            $Output | Format-List
            
            write-host -ForegroundColor Red -nonewline "Are you sure you want to remove? (Y/N) "
            $Response = read-host
            if ($Response -ne "Y") {exit}
                
            Get-WmiObject -Namespace $Namespace -Class "__EventConsumer" -ErrorAction silentlycontinue | where-object {$_.Name -eq $Name}  | Remove-WmiObject
        }
    }
    If(!($ToRemove)){Write-Host -ForegroundColor Yellow "No WMIEventConsumer found to remove. Printing availible Consumers - Please check spelling."}
    Else{Write-Host -ForegroundColor Yellow "Printing remaining Consumers."}
}

# Main

If($Remove){
    If (!$Namespace){$Namespace = Read-Host -Prompt "Enter WMI Namespace you would like to remove consumer"}
        
    If($Like){Remove-WMIEventConsumers -Namespace $Namespace -Remove $Remove -Like}
    Else{Remove-WMIEventConsumers -Namespace $Namespace -Remove $Remove}
}

 
If($Namespace){
    $Namespaces = @()
    $Namespaces += $Namespace
    $Namespaces += $(Get-WmiNamespace -Namespace $Namespace -recurse)
}
Else {$Namespaces = Get-WmiNamespace -recurse}


# Running WMIEventConsumer Enumeration at the end.
ForEach ($NameSpace in $Namespaces){
    If ($Raw){Get-WmiObject -Namespace $Namespace -Class "__EventConsumer" -ErrorAction SilentlyContinue}
    Else{
        $output=@()
        Get-WmiObject -Namespace $Namespace -Class "__EventConsumer" -ErrorAction SilentlyContinue | Foreach {            
            $Line = "" | Select Namespace, ConsumerName, ConsumerType, Payload
            $Line.Namespace = $_.__Namespace
            $Line.ConsumerName = $_.Name
            $Line.ConsumerType = $_.__CLASS
            If($_.ExecutablePath){$Line.Payload = $_.ExecutablePath}
            If($_.CommandLineTemplate){$Line.Payload = $_.CommandLineTemplate}
            If($_.ScriptFileName){$Line.Payload = $_.ScriptFileName}
            If($_.ScriptText){$Line.Payload = $_.ScriptText}
            If($_.SourceName){$Line.Payload = "N/A"}
            $Output += $Line
        }
        $Output | Format-List
    }
}
