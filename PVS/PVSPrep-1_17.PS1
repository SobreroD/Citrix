<#Requires -Version 5.0
 PVSPrep.PS1
 Version 1.1b

 Powershell 5 is recommend
 https://www.microsoft.com/en-us/download/details.aspx?id=50395

 This will prepare a computer for provisioning with Citrix Provisioning Server.
 Use: PVSPrep.PS1

 Change Log
 1.0
  Initial Build

 1.01b
  Added support for Windows 8 and Server 2012
  Added OS Detection for Win8 and Win2012
  Added Win7 and Win2012 to Disable unneeded tasks
  Enabled Page File Configuration section - I do not know why this was disabled.
  Corrected some spelling errors.

 1.02b
  Added Provisioning Services Device Optimizer section
  Added Customer Specific Settings Section
  Add NimSoft Configuration

 1.03b
  Changed name of Function StopService to StopDisableService
  Created Function StopService to just stop services
  Added Section for Citrix Smart Auditor
  Corrected issue with Page file Function

 1.1b
  Added OS detection for Win 10 os
  Added Impravata settings
  Added Check for Large Send Offload
  Added Liquidware Labs Section
  Modified Task-Disable function to not throw errors on missing tasks

 1.11b
  Added items to Disable Services

 1.12b
  Added check for service existance
  Added DDC registryset
  Added Setting of DDCs through GPO
  Correction of Liquidware

 1.13b
  Added Section for changing the Manufacturer name in the OS
  Task-Disable "Scheduled"
  Task-Disable "RegIdleBackup"
  Task-Disable "WinSAT"
  Removed Themes from being disabled needed for Win 7 VDI
  Added SCCM2007Remove section

 1.14a Donovan Sobrero @ Donovan@networkmechanics.net
  Added Powershell Opmiztition
  Added Support for PerfectDisk Defrag Tool
  Added Support for Windows 2016 all Editions
  Add Section for Vmware View
  Define System Deployment better

 1.14b
  Added Provisioning Services Device Optimizer section
  Added Customer Specific Settings Section

 1.14c
  Added Systrack section for Lakeside Systrack.
  Added check for AppV to ensure executables to be renamed were not running prior to renaming them.
  Fixed some Typos in the script.


 1.14d
  Added timezone set for EMEA, and APAC.
  Added ipconfig /flushdns, ard /d, and gpupdate to the script.
  Updated McAfee to cater for new EPO agent update command.

 1.14e
  Added sdelete to clear unused space in vhd.
  Set Cache Drive to W

 1.15
  Add Removeal of unwanted Windows 10 and 2016 PreInstalls apps
  V2 admin check
  Added check to see if sdelete is on system and download if needed

 1.16
  Cleaned up excess indents.
  Moved Zero space to the end.
  Fixed Typos

 1.17
  Added support for Windows Defender ATP.
  Added Support for Windows Server 2019.
  Renamed Appsense to Ivanti UWM.
  Corrected grammar.
  Corrected Syntax issues.
  Changed DNS CAche clear and gpupdate to support Win7 and Win2k8R2.
#>

#Write-Host -foregroundcolor Green ""
#write-log ""

#------------ User variable section START ---------------------------------------------------------------------------------

#System Deployed
$VMViewInstalled= $False							# VMware View Deployed
$CTX7Install = $False								# Citrix XenDesktop 7.x Installed
$CTX65Install = $False								# Citrix XenApp 6.5 Installed
$CTX5Install = $False								# Citrix XenApp 5.x Installed
$CTX45Install = $False								# Citrix XenApp 4.5 Installed
$CTXPVSDeployed = $False							# Citrix Provisioning Services installed

# General Settings
$PVSPrepUNC = "\\DS1815\Storage\Citrix_Software\PVS\PVSPrepProd"	# UNC Path to PVS Files - No trailing "\"
$PVSPrepLocal = "C:\Windows\PVSPrep"                # Local PVSPrep Files location
$WriteCacheDrive = "D"								# Write Cache Drive Letter
$pagemin = 16384 									# Pagefile minimum size
$pagemax = 16384  									# Pagefile maximum size
$CDDriveLetter = "Z:"                             	# What drive to change the CD to (Must have the ":")
$ELSizeKB = 1024KB                             		# What is the size for the Eventlog)

#Addins
$Datacenter = "" 									# Define Datacenter
$ComputerName = $env:COMPUTERNAME					# Set computername variable
$GPODDCs = $False                                 	# To set DDCs from GPO
$ListOfDDCs = ""                                 	# Leave Blank for no changes - This string value takes a space-delimited list of Controllers, which Fully Qualified Domain Name (FQDN) (for example, myddc.mydomain.com) is specified.
$ClearEventLogs	= $False							# Clear All Event Logs on Device
$ReArm = $False                                		# ReArm Windows Licensing
$ReArmOffice = $False								# ReArm Office
$SCCM2007Remove = $False                           	# Remove SSCM 2007 for PVD VMs
$SCCM2012Installed = $False                         # Is SCCM 2012 Deployed
$IvantiUWMInstalled = $False                        # Is Ivanti UWM Deployed
$RESInstalled = $False                             	# Is RES Deployed
$SymantecInstalled = $False                         # Is Symantec Deployed
$McAfeeInstalled = $False                           # Is McAfee Deployed
$McAfeeMoveInstalled = $False                    	# Is McAfee Move Deployed
$WindowsDefenderATP = $False                        # Is Windows Defender ATP Installed
$AppV5Installed = $False                           	# Is App-v 5 Deployed
$Nibsoft = $False                               	# Is Nibsoft Deployed
$Imprivata = $False                              	# Is Imprivata Deployed
$Liquidware = $False                              	# Is Liquidware Stratosphere Deployed
$PVDInventory = $False                            	# Is for PVS Image Inventory
$PerfectDisk = $False                           	# Defrag using Perfect Disk (Set PerfectDisk in gui if using thin provisioing)
$CleanDisk = $False									# Cleanup Disk Space
$PSdefrag = $False									# Defrag drive with Powershell
$ZeroFreeSpace = $False                             # Zero out free space

#Client request
$OSManufacturer = $False                          	# Change Manufacturer name in OS
$hubAddress = "LocalHost"                          	# Address of Stratosphere Server Set to "LocalHost" if set by GPO

#------------ User variable section END -----------------------------------------------------------------------------------

#------------------------ Setup Script ------------------------------------------------------------------------------------

# Elevate script to run as administrator
# https://community.spiceworks.com/topic/1327099-invoke-command-as-administrator
#If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
#{
#$arguments = "& '" + $myinvocation.mycommand.definition + "'"
#Start-Process powershell -Verb runAs -ArgumentList $arguments
#start-sleep 6
#Break
#}

# V2 admin check
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Write-Warning "Please run this script as an Administrator!"
		Start-Sleep 5
    Exit 1
}

#-------------- Dependency Check -------------------------------------------------------------------------------------------
#Check if Folder is there if not create it.
If(!(test-path $PVSPrepLocal)) {
	Write-Host -foregroundcolor Green "Creating Systemroot\PVSPREP"
	New-Item -ItemType -type Directory -Force -Path $PVSPrepLocal
	}
#Check if file is there
If (-Not (Test-Path "$($env:SystemRoot)\pvsprep\sdelete.exe")) {
	Write-Host -foregroundcolor RED "Support files are missing downloading and extracting them now"
	write-log "Sdelete.exe is missing downloading and placing in correct folder"
	# Download Sdelete if Missing
	$Url = "https://download.sysinternals.com/files/SDelete.zip"
	$Username = ""
	$Password = ""
	$PathDL = "$PVSPrepLocal\sdelete.zip"
	$WebClient = New-Object System.Net.WebClient
	$WebClient.Credentials = New-Object System.Net.Networkcredential($Username, $Password)
	$WebClient.DownloadFile( $url, $pathDL )

	# Exstract downloaded file
	Write-Host -foregroundcolor RED "Extracting support files now"
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	function Unzip
	{
		param([string]$zipfile, [string]$outpath)

		[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
	}
	Unzip "$PVSPrepLocal\sdelete.zip" "$PVSPrepLocal\"
	Write-Host -foregroundcolor green "All Suppport files are on the system NOW"
}
#-------------- Dependency Check section END ------------------------------------------------------------------------------

#------------ Functions START ---------------------------------------------------------------------------------------------
<#Get-ScriptDirectory
This function will return the current script path with file name.
	Use: Get-ScriptDirectory
#>
function Get-ScriptDirectory {
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  $Invocation.MyCommand.Path
}

#We have to test if the computer Architecture and the PowerShell Architecture match if not exist.
If ((Test-Path 'C:\Program Files (x86)') -eq $True){
    if ([System.IntPtr]::Size -eq 4) {
        "This PowerShell script must be executed from 64 bit PowerShell on a 64 bit machine"
        exit
    }
    Else {
        $OSArch = "x64"
    }
}
Else {
        $OSArch = "x86"
}

#Detect what OS version we are running. We will exit if it is unsupported.
$OSVersion = (Get-WmiObject Win32_OperatingSystem).Caption
$OSVersion = Switch -wildcard ($OSVersion){
    "*Windows 7*" {"Win7"}
    "*Microsoft Windows 8*" {"Win8"}
    "*Microsoft Windows 10*" {"Win10"}
    "*Windows Server 2008 R2*" {"Win2k8R2"}
    "*Windows(R) Server 2003*" {"Win2k3"}
    "*Microsoft Windows Server 2012*" {"Win2012"}
    "*Microsoft Windows Server 2016*" {"Win2016"}
    "*Microsoft Windows Server 2019*" {"Win2019"}
    default {"Unsupported"}
}
If ($OSVersion -eq "Unsupported") {
        "This version of the OS is unsupported."
        exit
}

#Get the current executing file name.
$FileName = Get-ScriptDirectory
#Log File
$LogFile = $PVSPrepLocal + "\PVSPREP.LOG"
$Seperator = "$("=" * 75)"
$loginitialized = $false
$FileHeader = @"
$seperator
***Application Information***
Filename:  $FileName
Created By: Donovan Sobrero - Dsobrero@kanavelgroup.com, Donovan@networkmechanics.net
Last Modified:  $(Get-Date -Date (get-item ($FileName)).LastWriteTime -f G)
OS Architecture $OSArch
The current OS is $OSVersion
$seperator

"@

#This will load the required information for the pop up windows.
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

<#Write-Log
This function will create a log file and add entries to it.
	Use: Write-Log "Test to enter into log"
#>
function write-log([string]$info){
    If (!(Test-Path -path (split-path $LogFile -Parent))) {
            New-Item (split-path $LogFile -Parent) -type directory
            write-log "Created Folder $PVSPrepLocal"
    }
	if($loginitialized -eq $false){
        $FileHeader > $logfile
                $FileHeader
        $script:loginitialized = $True
    }
    #Remove the "#" in the below line to enable date/time stamp on log entries.
    $info = $info# + " - " + (Get-Date -f G)
    $info >> $logfile
    $info
}

<#Test-RegistryValue Function
This function will check if a registry value exists.
	Use: Test-RegistryValue "Registry Path" "Registry Value" "PassThru True\False"
#>
function Test-RegistryValue($regkey, $name) {
    Get-ItemProperty $regkey $name -ErrorAction SilentlyContinue |
    Out-Null
    $?
}

<#Reg-Write Function
This function will write the the registry if the value if not already set and then writes to the log.
	Use: Reg-Write "Registry Path" "Registry Value" "Data to set"
#>
function Reg-Write([String]$RegPath, [String]$RegValue, $RegValueData) {
    If (test-path $RegPath) {
        if ((Get-ItemProperty -path $RegPath).$RegValue -eq $RegValueData) {
            write-log "$RegPath\$RegValue Already Set to $RegValueData(Nothing Done)"
        }
        Else {
            Set-ItemProperty -path $RegPath -name $RegValue -value $RegValueData
            write-log "$RegPath\$RegValue Set to $RegValueData"
        }
    }
    Else {
        write-log "$RegPath does not exist (Nothing Done)"
    }
}

<#Reg-Delete Function
This function will Delete the the registry Value if it exists and then writes to the log.
	Use: Reg-Delete "Registry Path" "Registry Value"
#>
function Reg-Delete([String]$RegPath, [String]$RegValue) {
    if (Test-RegistryValue $RegPath $RegValue) {
        Remove-ItemProperty -Path $RegPath -Name $RegValue
        write-log "$RegPath\$RegValue Has been deleted."
    }
    Else {
        write-log "$RegPath\$RegValue does not exist.(Nothing Done)"
    }
}

<#Execute-File Function
This function will execute a file with command lines and then log it.
	Use: Reg-Delete "Command with path" "Switches"
#>
function Execute-File([String]$Command, [String]$AppArgs, [Bool]$Log) {
    If (Test-Path $Command) {
        Start-Process $Command $AppArgs -Wait -RedirectStandardError ($Command + "RSE.txt") -RedirectStandardOutput ($Command + "RSO.txt")
        If ($Log) {
            write-log "File $Command was executed with the following command line."
            write-log "$Command $AppArgs"
        }
        if (Test-Path ($Command + "RSE.txt")) {
            $FileInfo = Get-Item ($Command + "RSE.txt")
            if ($FileInfo.length -ne 0) {
                $ErrLog = [string]::join([environment]::newline, (get-content ($Command + "RSE.txt")))
                If ($Log) {
                    write-log "The following error was returned by the command"
                    write-log $ErrLog
                }
            Remove-Item ($Command + "RSE.txt") -recurse
            }
        }
        if (Test-Path ($Command + "RSO.txt")) {
            $FileInfo = Get-Item ($Command + "RSO.txt")
            if ($FileInfo.length -ne 0) {
                If ($Log) {
                    write-log "The following output was returned by the command"
                    $ErrLog = [string]::join([environment]::newline, (get-content ($Command + "RSO.txt")))
                    write-log $ErrLog
                }
            }
            Remove-Item ($Command + "RSO.txt") -recurse
        }
    }
    Else {
        write-log "File $Command does not exist. File could not be executed."
    }
}

<#Copy-File Function
This function will copy a file and then log it.
	Use: copy-file "File Name"
#>
function Copy-File([String]$FileName) {
    Copy ($PVSPrepUNC + "\" + $FileName) $PVSPrepLocal -force
    write-log "File $FileName copied from $PVSPrepUNC to $PVSPrepLocal"
}

<#Set-PageFile Function
PowerShell Function to Set Page File Initial/Maximum Size
Modified from http://www.out-web.net/?p=1109
#>
function Set-PageFile {
    # .SYNOPSIS
        # Sets Page File to custom size
   # .DESCRIPTION
        # Applies the given values for initial and maximum page file size.
    # .PARAMETER Path
        # The page file's fully qualified file name (such as C:\pagefile.sys)
    # .PARAMETER InitialSize
        # The page file's initial size [MB]
    # .PARAMETER MaximumSize
        # The page file's maximum size [MB]
    # .EXAMPLE
        # Set-PageFile C:\pagefile.sys 4096 6144
    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $InitialSize,
        [Parameter(Mandatory=$true,Position=2)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $MaximumSize
    )

    Set-PSDebug -Strict

    $ComputerSystem = $null
    $CurrentPageFile = $null
    $Modified = $false

    # Disables automatically managed page file setting first
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
    if ($ComputerSystem.AutomaticManagedPagefile)
    {
        $ComputerSystem.AutomaticManagedPagefile = $false
        if ($PSCmdlet.ShouldProcess("$($ComputerSystem.Path.Server)", "Disable automatic managed page file"))
        {
            $ComputerSystem.Put()
        }
    }

    $CurrentPageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($CurrentPageFile.Name -eq $Path)
    {
        # Keeps the existing page file
        if ($CurrentPageFile.InitialSize -ne $InitialSize)
        {
            $CurrentPageFile.InitialSize = $InitialSize
            $Modified = $true
        }
        if ($CurrentPageFile.MaximumSize -ne $MaximumSize)
        {
            $CurrentPageFile.MaximumSize = $MaximumSize
            $Modified = $true
        }
        if ($Modified)
        {
            if ($PSCmdlet.ShouldProcess("Page file $Path", "Set initial size to $InitialSize and maximum size to $MaximumSize"))
            {
                $CurrentPageFile.Put()
            }
        }
    }
    else
    {
        # Creates a new page file
        if ($PSCmdlet.ShouldProcess("Page file $($CurrentPageFile.Name)", "Delete old page file"))
        {
            $CurrentPageFile.Delete()
        }
        if ($PSCmdlet.ShouldProcess("Page file $Path", "Set initial size to $InitialSize and maximum size to $MaximumSize"))
        {
            Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name=$Path; InitialSize = $InitialSize; MaximumSize = $MaximumSize}
        }
    }
}

<#Task-Disable Function
This function will Disable Tasks.
	Use: Task-Disable "Task" "Task Path"
#>
function Task-Disable([String]$Task, [String]$TaskPath) {
    write-log ("Starting Configuration of UnNeeded Scheduled Task:" + $TaskPath + "\" + $Task)
    $schedule = new-object -com("Schedule.Service")
    $schedule.connect()
    Try {
        $tasks = $schedule.getfolder($TaskPath).gettasks(0) | ? { $_.Name -eq $Task } | select Name, Path, State
        If ($tasks.State -eq 3) {
            write-log ("Disabling Task" + $TaskPath + "\" + $Task)
            Execute-File "c:\windows\system32\schtasks.exe" "/change /tn ""$TaskPath\$Task"" /Disable" $false
         }
        Else {
             write-log ("Task " + $TaskPath + "\" + $Task + " Already Disabled")
         }
    }
    Catch {
        write-log ("Task " + $TaskPath + "\" + $Task + " does not exist Nothing Done")
    }

}

<#StopDisableService Function
This function will Stop a Service and set Start up to Manual.
	Use: StopDisableService "Service"
#>
function StopDisableService([String]$ServiceName) {
    write-log ("Disabling Service $ServiceName")
    If(Get-Service $ServiceName -ErrorAction SilentlyContinue) {
        Stop-Service -Name $ServiceName -force
        write-log ("Setting Service $ServiceName to Manual Start up")
        Set-Service -Name $ServiceName -startuptype manual
    }
    Else {
        write-log ("Service $ServiceName Not Found nothing done")
    }
}

<#StopService Function
This function will Stop a Service.
	Use: StopService "Service"
#>
function StopService([String]$ServiceName) {
    write-log ("Stopping the $ServiceName Service")
    $Service = Get-Service $ServiceName
    Stop-Service $Service -force
    $Service.WaitForStatus('Stopped')
    write-log ("The $ServiceName Service is stopped")
}

<#DelayStartService Function
This function will Stop a Service.
	Use: DelayStartService "Service"
#>
function DelayStartService([String]$ServiceName) {
    write-log ("Stopping the $ServiceName Service")
    $Service = Get-Service $ServiceName
    Stop-Service $Service -force
    $Service.WaitForStatus('Stopped')
    write-log ("The $ServiceName Service is stopped")
    Set-Service -Name $ServiceName -startuptype Automatic
    If(Test-RegistryValue $("HKLM:System\CurrentControlSet\Services\"+$ServiceName) "DelayedAutostart") {
        Set-ItemProperty -Path $("HKLM:System\CurrentControlSet\Services\"+$ServiceName) -Name "DelayedAutostart" -Value 1 -Type DWORD
    }
    Else {
        New-ItemProperty -Path $("HKLM:System\CurrentControlSet\Services\"+$ServiceName) -Name "DelayedAutostart" -Value 1 -Type DWORD
    }
    write-log ("Setting Service $ServiceName to Delayed Start")
}

<#Test-RegistryValue Function
This function will check if a value exists
	Use: Test-RegistryValue "Path" "Value"
http://stackoverflow.com/questions/5648931/test-if-registry-value-exists
#>
function Test-RegistryValue {
    param(
        [Alias("PSPath")]
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Path
        ,
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Name
        ,
        [Switch]$PassThru
    )

    process {
        if (Test-Path $Path) {
            $Key = Get-Item -LiteralPath $Path
            if ($Key.GetValue($Name, $null) -ne $null) {
                if ($PassThru) {
                    Get-ItemProperty $Path $Name
                } else {
                    $true
                }
            } else {
                $false
            }
        } else {
            $false
        }
    }
}

function Exists-Drive {
    param($driveletter)
    (New-Object System.IO.DriveInfo($driveletter)).DriveType -ne 'NoRootDirectory'
}
#------------ Functions END -----------------------------------------------------------------------------------------------

#------------ Main Script START -------------------------------------------------------------------------------------------
#Copy Required Files to C:
write-log " "
write-log ("="*75)
write-log "Starting Copy Files"
If (!(Test-Path -path $PVSPrepLocal)) {
    New-Item $PVSPrepLocal -type directory
    write-log "Created Folder $PVSPrepLocal"
}
#Copy-File "Startup.cmd"
# WHERE IS THE COPY????

write-log "Complete Copy Files"
write-log ("-"*75)

#Change CD ROM to $CDDriveLetter
write-log " "
write-log ("="*75)
write-log "Starting Configure CD Drive Letter"
(gwmi Win32_cdromdrive).drive | %{$a = mountvol $_ /l;mountvol $_ /d;$a = $a.Trim();mountvol $CDDriveLetter $a}
write-log ("CD ROM drive letter changed to '" + $CDDriveLetter + "'")
write-log ("-"*75)

#Label $WriteCacheDrive: to "Write Cache"
write-log " "
write-log ("="*75)
write-log "Starting Write Cache Drive Label Change"
$drive = gwmi win32_volume -Filter $("DriveLetter = '" + $WriteCacheDrive + ":'")
$drive.Label =  "Write Cache"
$Null = $drive.put()
write-log ("Drive name changed for " + $WriteCacheDrive + ":\ to 'Write Cache'")
write-log "Complete Configure Drive Letters"
write-log ("-"*75)

#Page File Configuration
#Move Page file to $WriteCacheDrive:\ and set min and max size to memory size.
write-log " "
write-log ("="*75)
write-log "Starting Page File Config"
Write-Host -foregroundcolor Green "Move Page file to $WriteCacheDrive and set min and max size to memory size"

if (Exists-Drive ($WriteCacheDrive + ":")) {
    Set-PageFile ($WriteCacheDrive + ":\pagefile.sys") $pagemin $pagemax
}
Else {
    write-log "$WriteCacheDrive drive does not exist. Page File cannot be configured."
    $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("$WriteCacheDrive drive does not exist. Page File cannot be configured.","Page File","OKCancel","Error")
    if($ErrorReturn -eq "Cancel") {
		exit
	}
}
write-log "Complete Page File Config"
	 Write-Host -foregroundcolor Green "Complete Page File Config"
Write-log ("-"*75)

#Check for Large Send Offload disabled
#http://support.citrix.com/article/CTX117374

If (Test-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP\Parameters" "DisableTaskOffload") {
    if ((Get-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP\Parameters")."DisableTaskOffload" = 1) {
        write-log "Large Send Offload is set correctly"
    }
    Else {
        write-log "Large Send Offload not set"
        $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("Large Send Offload not set","Large Send Offload","OKCancel","Error")
        if($ErrorReturn -eq "Cancel") {exit}
    }
}
Else {
    write-log "Large Send Offload not set"
    $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("Large Send Offload not set","Large Send Offload","OKCancel","Error")
    if($ErrorReturn -eq "Cancel") {exit}
}

#Disable Unneeded Services
if (($OSVersion -eq "Win7") -or ($OSVersion -eq "Win2k8R2") -or ($OSVersion -eq "Win8") -or ($OSVersion -eq "Win10") -or ($OSVersion -eq "Win2012") -or ($OSVersion -eq "Win2016")) {
	Write-Host -foregroundcolor Red "Disabling UnNeeded Services"
	write-log " "
    write-log ("="*75)
    write-log "Starting Disable of unneeded Services"
    #The following came from:https://virtualfeller.com/2010/06/24/windows-7-optimization-disable-services-2/
	StopDisableService "ALG"               	#
	StopDisableService "bthserv"						# Bluetooth Support Service
	StopDisableService "BcmBtRSupport"					# Bluetooth Driver Management Service
	StopDisableService "BthHFSrv"						# Bluetooth Handsfree Service
	StopDisableService "PeerDistSvc"					# BranchCache
	#StopDisableService "Browser"						# Computer Browser
	StopDisableService "DeviceAssociationService"		# Device Association Service
	StopDisableService "wbengine"             			# Block Level Backup Engine Service
	StopDisableService "DPS"               				#
	StopDisableService "WdiServiceHost"         		#
	StopDisableService "WdiSystemHost"          		#
	StopDisableService "TrkWks" 						#
	StopDisableService "EFS" 							# Encrypting File System (EFS)
	StopDisableService "Fax" 							# Faxing
	StopDisableService "HomeGroupListener" 				# HomeGroup Listener
	StopDisableService "HomeGroupProvider" 				# HomeGroupProvider
	StopDisableService "swprv" 							# Microsoft Software Shadow Copy Provider
	StopDisableService "CscService" 					# Offline Files
	#StopDisableService "SstpSvc" 						# Secure Socket Tunneling Protocol Service
	StopDisableService "wscsvc" 						# Security Center
	StopDisableService "SSDPSRV" 						# Discovers networked devices and services that use the SSDP discovery protocol, such as UPnP devices. Also announces SSDP devices and services running on the local computer. If this service is stopped, SSDP-based devices will not be discovered. If this service is disabled, any services that explicitly depend on it will fail to sta
	StopDisableService "TapiSrv" 						# Provides Telephony API (TAPI) support for programs that control telephony devices on the local computer and, through the LAN, on servers that are also running the service.
	StopDisableService "WlanSvc" 						# The WLANSVC service provides the logic required to configure, discover, connect to, and disconnect from a wireless local area network (WLAN) as defined by IEEE 802.11 standards. It also contains the logic to turn your computer into a software access point so that other devices or computers can connect to your computer wirelessly using a WLAN adapter that can support this. Stopping or disabling the WLANSVC service will make all WLAN adapters on your computer inaccessible from the Windows networking UI. It is strongly recommended that you have the WLANSVC service running if your computer has a WLAN adapter.
	StopDisableService "WwanSvc" 						# This service manages mobile broadband (GSM & CDMA) data card/embedded module adapters and connections by auto-configuring the networks. It is strongly recommended that this service be kept running for best user experience of mobile broadband devices.
	StopDisableService "BITS"               			# Background Intelligent Transfer Service
    StopDisableService "WinDefend"  					# Windows Defender
    StopDisableService "UxSms"              			# Desktop Windows Manager Session Manager
    StopDisableService "fdPHost"    					# Function Discovery Resource Publication
    StopDisableService "HomeGroupListener" 				# HomeGroup listener
    StopDisableService "HomeGroupProvider"  			# HomeGroup provider
    StopDisableService "WSearch"    					# Windows Search\Indexing Service
    StopDisableService "CscService" 					# Offline Files
    StopDisableService "SysMain"    					# SuperFetch
    StopDisableService "srservice"  					# System Restore
    StopDisableService "wuauserv"   					# Windows Update
    #StopDisableService "Themes"            			# Themes
    StopDisableService "MpsSvc"             			# Windows Firewall
    #StopDisableService "appsvc"            			# Software Protection
    StopDisableService "uxsms"              			# Windows Aero
    write-log "Complete Disable of unneeded Services"
    write-log ("-"*75)
	Write-Host -foregroundcolor Green "Services Disabled"
}

#Disable unneeded tasks
if (($OSVersion -eq "Win7") -or ($OSVersion -eq "Win2k8R2") -or ($OSVersion -eq "Win8") -or ($OSVersion -eq "Win10") -or ($OSVersion -eq "Win2012") -or ($OSVersion -eq "Win2016")-or ($OSVersion -eq "Win2019")) {
	Write-Host -foregroundcolor Red "Disabling UnNeeded Tasks"
	write-log " "
    write-log ("="*75)
    write-log "Starting Scheduled Task Cleanup"
    bcdedit /set bootux disabled
    Task-Disable "AitAgent" "\Microsoft\Windows\Application Experience"
    Task-Disable "ProgramDataUpdater" "\Microsoft\Windows\Application Experience"
    Task-Disable "Proxy" "\Microsoft\Windows\Autochk"
    Task-Disable "Consolidator" "\Microsoft\Windows\Customer Experience Improvement Program"
    Task-Disable "KernelCeipTask" "\Microsoft\Windows\Customer Experience Improvement Program"
    Task-Disable "UsbCeip" "\Microsoft\Windows\Customer Experience Improvement Program"
    Task-Disable "ServerCeipAssistant" "\Microsoft\Windows\Customer Experience Improvement Program\Server"
    Task-Disable "ServerRoleCollector" "\Microsoft\Windows\Customer Experience Improvement Program\Server"
    Task-Disable "ServerRoleUsageCollector" "\Microsoft\Windows\Customer Experience Improvement Program\Server"
    Task-Disable "Microsoft-Windows-DiskDiagnosticDataCollector" "\Microsoft\Windows\DiskDiagnostic"
    Task-Disable "AnalyzeSystem" "\Microsoft\Windows\Power Efficiency Diagnostics"
    Task-Disable "ServerManager" "\Microsoft\Windows\Server Manager"
    Task-Disable "QueueReporting" "\Microsoft\Windows\Windows Error Reporting"
    Task-Disable "Scheduled" "\Microsoft\Windows\Diagnosis"
    Task-Disable "RegIdleBackup" "\Microsoft\Windows\Registry"
    Task-Disable "WinSAT" "\Microsoft\Windows\Maintenance"
	#Advance Tuning
		#Task-Disable "StartupAppTask"  "microsoft\windows\Application Experience"
		#Task-Disable "Proxy"  "microsoft\windows\Autochk"
		#Task-Disable "microsoft\windows\Bluetooth\UninstallDevice#Task"
		#Task-Disable "BthSQM"  "microsoft\windows\Customer Experience Improvement Program"
		#Task-Disable "Uploader"  "microsoft\windows\Customer Experience Improvement Program"
		#Task-Disable "Scheduled"  "microsoft\windows\Diagnosis"
		#Task-Disable "Microsoft-Windows-DiskDiagnosticDataCollector"  "microsoft\windows\DiskDiagnostic"
		#Task-Disable "Microsoft-Windows-DiskDiagnosticResolver"  "microsoft\windows\DiskDiagnostic"
		#Task-Disable "HotStart"  "microsoft\windows\MobilePC"
		#Task-Disable "microsoft\windows\RAC\Rac#Task"
		#Task-Disable "MobilityManager"  "microsoft\windows\Ras"
		#Task-Disable "RegIdleBackup"  "microsoft\windows\Registry"
		#Task-Disable "FamilySafetyMonitor"  "microsoft\windows\Shell"
		#Task-Disable "FamilySafetyRefresh"  "microsoft\windows\Shell"
		#Task-Disable "AutoWake"  "microsoft\windows\SideShow"
		#Task-Disable "GadgetManager"  "microsoft\windows\SideShow"
		#Task-Disable "SessionAgent"  "microsoft\windows\SideShow"
		#Task-Disable "SystemDataProviders"  "microsoft\windows\SideShow"
		#Task-Disable "UPnPHostConfig"  "microsoft\windows\UPnP"
		#Task-Disable "ResolutionHost"  "microsoft\windows\WDI"
		#Task-Disable "BfeOnServiceStartTypeChange"  "microsoft\windows\Windows Filtering Platform"
		#Task-Disable "UpdateLibrary"  "microsoft\windows\Windows Media Sharing"
		#Task-Disable "ConfigNotification"  "microsoft\windows\WindowsBackup"
    write-log "Complete Scheduled Task Cleanup"
    write-log ("-"*75)
	Write-Host -foregroundcolor Green "Complete - Disabling UnNeeded Tasks"
}

#SCCM Remove
#This will Remove SCCM 2007 if detected
#
If ($SCCM2007Remove) {
    write-log " "
    write-log ("="*75)
    write-log "Starting SCCM 2007 Removal Check"
    If (test-path ("C:\WINDOWS\SysWOW64\CCM\SMSCFGRC.cpl")) {
        write-log "Found C:\WINDOWS\SysWOW64\CCM\SMSCFGRC.cpl removing SCCM 2007"
        Execute-File "C:\Windows\ccmsetup\Ccmsetup.exe" "/uninstall" $True
        Execute-File "C:\Windows\System32\certutil.exe" "-delstore SMS SMS" $True
        write-log "Removed SCCM 2007"
    }
    If (Test-Path -path "C:\Windows\smscfg.ini") {
        Remove-Item -Path "C:\Windows\smscfg.ini" -Force
        write-log "Deleted C:\Windows\smscfg.ini"
    }
    write-log "Completed SCCM 2007 Removal Check"
    write-log ("-"*75)
}

#SCCM 2012
#This clears the personal information for the registry
if ($SCCM2012Installed) {
    Write-Host -foregroundcolor Red "Clearing the personal information for the registry"
	write-log " "
    write-log ("="*75)
    write-log "Starting SCCM 2012 Config"
    $RegPath = "HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client"
    $RegValue = "ProductVersion"
    $RegValueData = 5
    $SCCMVer = (Get-ItemProperty -path $RegPath).$RegValue
    If (($SCCMVer.substring(0,1)) -eq $RegValueData) {
        StopDisableService "CcmExec"
        Execute-File "C:\windows\System32\certutil.exe" "-delstore SMS SMS" $True
        If (test-path ("c:\windows\SMSCFG.ini")) {
            write-log "Found c:\windows\SMSCFG.ini. Deleting."
            Remove-Item -Force c:\windows\SMSCFG.ini
        }
    }
    Else {
        write-log "SCCM 2012 not installed."
        $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("SCCM 2012 not installed.","SCCM 2012","OKCancel","Error")
        if($ErrorReturn -eq "Cancel") {
			exit
		}
    }
    write-log "Complete SCCM 2012 Config"
    write-log ("-"*75)
	Write-Host -foregroundcolor Green "Complete"
}

#App-v 5
#Prepare App-v 5 for PVS devices
if ($AppV5Installed) {
    Write-Host -foregroundcolor Red "prepairs App-v 5 for PVS devices"
	write-log " "
    write-log ("="*75)
    write-log "Starting App-v Config"
    If (test-path ("C:\Program Files\Microsoft Application Virtualization\Client\AppVStreamingUX.exe")) {
            write-log "Found C:\Program Files\Microsoft Application Virtualization\Client\AppVStreamingUX.exe. Renaming."
            Rename-Item -Force "C:\Program Files\Microsoft Application Virtualization\Client\AppVStreamingUX.exe" "C:\Program Files\Microsoft Application Virtualization\Client\AppVStreamingUXDisable.exe"
    }
    If (test-path ("C:\Program Files\Microsoft Application Virtualization\Client\AppVShNotify.exe")) {
            write-log "Found C:\Program Files\Microsoft Application Virtualization\Client\AppVShNotify.exe. Renaming."
            Rename-Item -Force "C:\Program Files\Microsoft Application Virtualization\Client\AppVShNotify.exe" "C:\Program Files\Microsoft Application Virtualization\Client\AppVShNotifyDisable.exe"
    }
	write-log "Complete App-V 5.x Config"
    write-log ("-"*75)
	Write-Host -foregroundcolor Green "Complete"
}

#Ivanti UWM
#Clear the Machine settings from the registry
if ($IvantiUWMInstalled) {
    Write-Host -foregroundcolor Red "Ivanti UWM clears the personal information from the registry"
		 write-log " "
    write-log ("="*75)
    write-log "Starting Ivanti UWM Config"
    If (test-path "HKLM:\Software\Appsense Technologies\Communications Agent") {
        Stop-Service -Name "AppSense Client Communications Agent" -force
		Reg-Delete "HKLM:\Software\Appsense Technologies\Communications Agent" "machine id"
        Reg-Delete "HKLM:\Software\Appsense Technologies\Communications Agent" "group id"
		if (test-path C:\AppSenseVirtual) {
            write-log "Found C:\AppSenseVirtual. Deleting."
			Remove-Item -Recurse -Force C:\AppSenseVirtual
        }
    }
    Else {
            write-log "Ivanti UWM not installed."
            $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("AppSense not installed.","AppSense","OKCancel","Error")
            if($ErrorReturn -eq "Cancel") {exit}
    }
    write-log "Completed Ivanti UWM Config"
    write-log ("-"*75)
	Write-Host -foregroundcolor Green "Complete"
}

#McAfee
#This tool will reset the Agent GUID to ensure uniqueness in the ePO directory.
#https://kc.mcafee.com/corporate/index?page=content&id=KB56086
If ($McAfeeInstalled) {
    write-log " "
    write-log ("="*75)
    write-log "Starting McAfee Config"
    If (test-path "HKLM:\SOFTWARE\Network Associates\ePolicy Orchestrator\Agent") {
        Reg-Delete "HKLM:\SOFTWARE\Network Associates\ePolicy Orchestrator\Agent" "AgentGUID"
        #Force McAfee dat update
        Execute-File "c:\Program Files (x86)\McAfee\VirusScan Enterprise\mcupdate.exe" "/update"
        #Force McAfee epo update
        Execute-File "c:\Program Files (x86)\McAfee\Common Framework\CmdAgent.exe" "/c"
    }
    Else {
        If (test-path "HKLM:\SOFTWARE\Wow6432Node\Network Associates\ePolicy Orchestrator\Agent") {
            Reg-Delete "HKLM:\SOFTWARE\Wow6432Node\Network Associates\ePolicy Orchestrator\Agent" "AgentGUID"
            #Force McAfee dat update
            Execute-File "c:\Program Files (x86)\McAfee\VirusScan Enterprise\mcupdate.exe" "/update"
            #Force McAfee epo update
            Execute-File "c:\Program Files (x86)\McAfee\Common Framework\CmdAgent.exe" "/c"
        }
        Else {
            write-log "McAfee Endpoint Protection not installed."
            $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("McAfee not installed.","McAfee","OKCancel","Error")
            if($ErrorReturn -eq "Cancel") {exit}
        }
    }
    write-log "Completed McAfee Config"
    write-log ("-"*75)
}

#Symantec Endpoint Protection
#This tool will remove all Symantec Endpoint Protection client identifiers and leave the Endpoint Protection services stopped.
#http://www.symantec.com/business/support/index?page=content&id=HOWTO54706
If ($SymantecInstalled) {
    write-log " "
    write-log ("="*75)
    write-log "Starting SEP Config"
    If (test-path "HKLM:\SYSTEM\CurrentControlSet\services\SepMasterService") {
        Execute-File "$PVSPrepLocal\vietool.exe" "c: --generate --verbose" $True
        Execute-File "$PVSPrepLocal\vietool.exe" "d: --generate --verbose" $True
        # Execute-File "$PVSPrepLocal\ClientSideClonePrepTool.exe" " " $True
    }
    Else {
        write-log "Symantec Endpoint Protection not installed."
        $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("Symantec Endpoint Protection not installed.","Symantec Endpoint Protection","OKCancel","Error")
        if($ErrorReturn -eq "Cancel") {exit}
    }
    write-log "Complete SEP Config"
    write-log ("-"*75)
}

#Windows Defender ATP
#This will remove settings for ATP to ensure uniqueness in the Cloud directory.
If ($WindowsDefenderATP) {
    write-log " "
    write-log ("="*75)
    write-log "Starting Windows Defender ATP"
    If (test-path "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection") {
        if (($OSVersion -eq "Win7") -or ($OSVersion -eq "Win2k8R2")) {
			Reg-Delete "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection" "senseGuid"			
		}
		else {
			#Run the following as System
			Invoke-CommandAs -ComputerName $ComputerName -ScriptBlock {
            #Delete senseGUID from registry
			Reg-Delete "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection" "senseGuid"
			#Delete Cyber update
			Remove-Item "C:\ProgramData\Microsoft\Windows Defender Advanced Threat Protection\Cyber" -force
			} -AsSystem -RunElevated
		}
	}
    write-log "Completed Windows Defender ATP Config"
    write-log ("-"*75)
}

#Lakeside Systrack
if (Test-Path "C:\Program Files (x86)\SysTrack\LsiAgent") {
	write-log " "
	write-log ("="*75)
	write-log "Starting Lakeside Systrack config."
	Stop-Service -Name "Systems Management Agent" -force
	Remove-Item "C:\Program Files (x86)\SysTrack\LsiAgent\LsiAgent1.log"
	write-log "Completed Systrack Config"
	write-log ("-"*75)
}

#Nibsoft
#This will stop the Nibsoft service and delete directories
#No Documentation. This information came from Donovan dsobrero@kanavelgroup.com
If ($Nibsoft) {
    write-log " "
    write-log ("="*75)
    write-log "Starting Nibsoft Config"
    If (test-path "HKLM:\SOFTWARE\Wow6432Node\Nimsoft LLC]") {
		write-log "Stopping the Nibsoft Service"
		$Nimsoft_Service = Get-Service NimbusWatcherService
		StopService $Nimsoft_Service
		$Nimsoft_Service.WaitForStatus('Stopped')
        write-log "The Nibsoft Service is stopped"
        write-log "Deleting Nibsoft directories"
        Remove-Item "C:\Program Files (x86)\nimsoft\probes\System\cdm" -Recurse -ErrorAction SilentlyContinue
        Remove-Item "C:\Program Files (x86)\nimsoft\probes\System\Ntservices" -Recurse -ErrorAction SilentlyContinue
        Remove-Item "C:\Program Files (x86)\nimsoft\probes\System\Ntevl" -Recurse -ErrorAction SilentlyContinue
        Remove-Item "C:\Program Files (x86)\nimsoft\probes\System\Processes" -Recurse -ErrorAction SilentlyContinue
        Remove-Item "C:\Program Files (x86)\nimsoft\niscache" -Recurse -ErrorAction SilentlyContinue
        }
    Else {
        write-log "Nibsoft agent not installed."
        $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("Nibsoft Agent not installed.","Nibsoft","OKCancel","Error")
        if($ErrorReturn -eq "Cancel") {exit}
        }
    write-log "Complete Nibsoft Config"
    write-log ("-"*75)
}


#Rearm Windows
#This will rearm Windows
if ($ReArm) {
        write-log " "
        write-log ("="*75)
        write-log "Rearming Windows"
        Execute-File "C:\Windows\System32\cscript.exe" "C:\Windows\System32\slmgr.vbs /rearm" $True
    write-log "Complete Rearm Windows"
        write-log ("-"*75)
}

#Rearm Office
#This will rearm Office Office versions
if ($ReArmOffice) {
	if ("C:\Program Files (x86)\Microsoft Office\Office16") {
		write-log " "
		write-log ("="*75)
		write-log "Rearming Windows"
		Execute-File "C:\Program Files (x86)\Microsoft Office\Office16\OSPPREARM.exe" $True
		Execute-File "C:\Windows\system32\cscript.exe "C:\Program Files (x86)\Microsoft Office\Office16\ospp.vbs" /act" $True
		write-log "Complete Rearm Windows"
		write-log ("-"*75)
	}
	if ("C:\Program Files (x86)\Microsoft Office\Office15\ospprearm.exe") {
					 
		write-log " "
		write-log ("="*75)
		write-log "Rearming Windows"
		Execute-File "C:\Program Files (x86)\Microsoft Office\Office15\OSPPREARM.exe" $True
		Execute-File "C:\Windows\system32\cscript.exe "C:\Program Files (x86)\Microsoft Office\Office15\ospp.vbs" /act" $True
		write-log "Complete Rearm Windows"
		write-log ("-"*75)
	}
	if ("C:\Program Files (x86)\Microsoft Office\Office14\OSPPREARM.exe") {
					 
		write-log " "
		write-log ("="*75)
		write-log "Rearming Windows"
		Execute-File "C:\Program Files (x86)\Microsoft Office\Office14\OSPPREARM.exe" $True
		Execute-File "C:\Windows\system32\cscript.exe "C:\Program Files (x86)\Microsoft Office\Office14\ospp.vbs" /act" $True
		write-log "Complete Rearm Windows"
		write-log ("-"*75)
	}
}

#Citrix XenApp 5
#This will execute XenAppPrep on XenApp 5
if (($CTX5Install) -and ($OSVersion -eq "Win2k3")) {
    write-log " "
    write-log ("="*75)
    write-log "Starting XenAppPrep Config"
    StopService IMAService -force
    Execute-File "C:\Program Files\Citrix\system32\Citrix\Ima\DsMaint.exe" "RecreateLHC" $True
    Execute-File "C:\Program Files\Citrix\system32\Citrix\Ima\DsMaint.exe" "RecreateRade" $True
    Execute-File "C:\Program Files\Citrix\Streaming Client\RadeCache.exe" "/flushall" $True
    Execute-File "C:\Program Files\Citrix\Streaming Client\RadeCache.exe" "/flushstore:all" $True
    If (test-path ("C:\Program Files\Citrix\XenAppPrep")) {
        Execute-File "C:\Program Files\Citrix\XenAppPrep\XenAppPrep.exe" "/pvs" $True
    }
    Else {
        write-log "XenApp Prep is not installed. Please Install XenAppPrep."
        $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("XenApp Prep is not installed. Please Install XenAppPrep.","XenAppPerp","OKCancel","Error")
        if($ErrorReturn -eq "Cancel") {exit}
    }
    write-log "Complete XenAppPrep Config"
    write-log ("-"*75)
}

#Citrix XenApp 6.5
#The following command will remove the server from the XenApp 6.5 Farm and clear all XenApp settings.

if (($CTX65Install) -and ($OSVersion -eq "Win2k8R2")) {
    write-log " "
    write-log ("="*75)
    write-log "Starting XenAppPrep Config"
    StopService "IMAService"
    Execute-File "C:\Program Files (x86)\Citrix\system32\Citrix\Ima\DsMaint.exe" "RecreateLHC" $True
    Execute-File "C:\Program Files (x86)\Citrix\system32\Citrix\Ima\DsMaint.exe" "RecreateRade" $True
    Execute-File "C:\Program Files (x86)\Citrix\Streaming Client\RadeCache.exe" "/flushall" $True
    Execute-File "C:\Program Files (x86)\Citrix\Streaming Client\RadeCache.exe" "/flushstore:all" $True
    Execute-File "C:\Program Files (x86)\Citrix\XenApp\ServerConfig\XenAppConfigConsole.exe" "/ExecutionMode:ImagePrep" $True
    write-log "Complete XenAppPrep Config"
    write-log ("-"*75)
}

#Citrix XenDesktop 7.x
#Remove DDC from Registry and set BrokerAgent to Delayed Start to allow it to be set from GPO
#http://support.citrix.com/article/CTX118976
if ($CTX7Install) {
 if ($GPODDCs) {
    write-log " "
    write-log ("="*75)
    write-log "Starting DDC Registry Removal"
    DelayStartService "BrokerAgent"
    Reg-Write "HKLM:Software\Citrix\VirtualDesktopAgent" "ListOfDDCs" ""
    write-log "Complete DDC Registry Removal"
    write-log ("-"*75)
 }

#Set DDC from Registry
#http://support.citrix.com/article/CTX118976
 if ($ListOfDDCs -ne "") {
    write-log " "
    write-log ("="*75)
    write-log "Setting DDC Registry Info"
    Reg-Write "HKLM:Software\Citrix\VirtualDesktopAgent" "ListOfDDCs" $ListOfDDCs
    write-log "Complete DDC Registry ListOfDDCs=$ListOfDDCs"
    write-log ("-"*75)
 }
}

#Citrix Smart Auditor
#Configure Citrix Smart Auditor for imaging
write-log "Checking if CitrixSmAudAgent Service is installed"
if (Get-Service "CitrixSmAudAgent" -ErrorAction SilentlyContinue){
    StopService "CitrixSmAudAgent"
    StopService "MSMQ"
    Reg-Delete "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters\MachineCache" "QMId"
    write-log "Creating HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters\Sysprep"
    New-ItemProperty "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters" -Name "Sysprep" -PropertyType "DWORD" -Value 1 -Force | Out-Null
    #reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSMQ\Parameters /v Sysprep /t REG_DWORD /d 1 /f
    }
Else{
    write-log "CitrixSmAudAgent Service is not installed"
    }

#Imprivata
#This will delete the registry settings for Imprivata
#No Documentation. This information came from Casey Donovan Casey.Donovan@LogisticsOne.com
If ($Imprivata) {
    write-log " "
    write-log ("="*75)
    write-log "Starting Imprivata Config"
    If (test-path "C:\Program Files (x86)\Imprivata\OneSign Agent\ISXAgent.exe") {
        write-log "Deleting Imprivata Registry Entry"
        Reg-Delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Provider Filters" "{F8660363-781C-617B-0100-128274950002}"
        }
    Else {
        write-log "Imprivata agent not installed."
        $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("Imprivata Agent not installed.","Imprivata","OKCancel","Error")
        if($ErrorReturn -eq "Cancel") {exit}
        }
    write-log "Completed Imprivata Config"
    write-log ("-"*75)
}

#Liquidware Labs
#This will clean the Liquidware Labs files
#No Documentation. This information came from Casey Donovan Casey.Donovan@LogisticsOne.com
If ($Liquidware) {
    $LiquidwareRegPath = "HKLM:SOFTWARE\Wow6432Node\Liquidware Labs\ConnectorID"
    write-log " "
    write-log ("="*75)
    write-log "Starting Liquidware Labs"
    If (test-path $LiquidwareRegPath) {
		write-log "Cleaning Liquidware Labs"
        Execute-File "C:\Program Files (x86)\Liquidware Labs\Connector ID\idcontrol.exe" "Clean" $True
        If(Test-RegistryValue $LiquidwareRegPath "hubAddress") {
            Reg-Write $LiquidwareRegPath "hubAddress" $hubAddress
            }
        Else{
            New-ItemProperty -Path $LiquidwareRegPath -Name "hubAddress" -Value $hubAddress -PropertyType String -Force | Out-Null
            }
    }
    Else {
        write-log "Liquidware Labs agent not installed."
        $ErrorReturn=[System.Windows.Forms.MessageBox]::Show("Liquidware Labs not installed.","Liquidware Labs","OKCancel","Error")
        if($ErrorReturn -eq "Cancel") {exit}
    }
    write-log "Completed Liquidware Labs Config"
    write-log ("-"*75)
}

# Get a list of all apps Windows 10, 2016, and 2019
if (($OSVersion -eq "Win10") -or ($OSVersion -eq "Win2016") -or ($OSVersion -eq "Win2019"))   {
$AppArrayList = Get-AppxPackage -PackageTypeFilter Bundle | Select-Object -Property Name, PackageFullName | Sort-Object -Property Name

# Loop through the list of apps
foreach ($App in $AppArrayList) {
    # Exclude essential Windows apps
    if (($App.Name -in "Microsoft.WindowsCalculator", "Microsoft.WindowsStore", "Microsoft.Appconnector", "Microsoft.WindowsCommunicationsApps", "Microsoft.WindowsSoundRecorder", "Microsoft.DesktopAppInstaller", "Microsoft.Messaging", "Microsoft.StorePurchaseApp")) {
        Write-Output -InputObject "Skipping essential Windows app: $($App.Name)"
    }
    # Remove AppxPackage and AppxProvisioningPackage
    else {
        # Gather package names
        $AppPackageFullName = Get-AppxPackage -Name $App.Name | Select-Object -ExpandProperty PackageFullName
        $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App.Name } | Select-Object -ExpandProperty PackageName

        # Attempt to remove AppxPackage
        try {
            Write-Output -InputObject "Removing AppxPackage: $($AppPackageFullName)"
            Remove-AppxPackage -Package $AppPackageFullName -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message
        }

        # Attempt to remove AppxProvisioningPackage
        try {
            Write-Output -InputObject "Removing AppxProvisioningPackage: $($AppProvisioningPackageName)"
            Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message
        }
    }
}
}

#PVD Inventory
#This will Run the PVD Inventory
#Citrix PVS Inventory
If ($PVDInventory) {
    write-log " "
    write-log ("="*75)
    write-log "Starting PVD Inventory"
    Execute-File "c:\program files (x86)\mcafee\move av client\mvadm.exe" "disable" $True
    Execute-File "C:\Program Files\Citrix\personal vDisk\bin\CtxPvD.exe" "-s inventory" $True
    write-log "Completed PVD Inventory"
    write-log ("-"*75)
}

#VMView
If ($VMviewinstalled) {
	write-log " "
	write-log ("="*75)
	write-log "Starting VMView Config"
#actions to be added later
	write-log "Complete VMview Config"
	write-log ("-"*75)
	}

#Provisioning Services Device Optimizer
#This section imports the registry files created by the Provisioning Services Device Optimizer
Switch ($OSVersion) {
	"Win7" {
		#Do Nothing Need Reg File
		}
	"Win8" {
		#Do Nothing Need Reg File
		}
	"Win2k3" {
		#Execute-File "C:\windows\regedit.exe" "/s \\VFCorp.vfc.com\Infrastructure\VCCP\PVSPrep\W2K3_X86_optimizations.reg"
		}
	"Win2k8R2" {
		#Do Nothing Need Reg File
		}
	"Win2012" {
		#Do Nothing Need Reg File
		}
	"Win2016" {
		#Do Nothing Need Reg File
		}
	"Win2019" {
		}
	default {
		#Do Nothing Need Reg File
		}
}

#---------------------------------------------------------------------------------------------------------
#Customer Specific Settings
#The following are setting unique for the customer.
 
 $DataCenter = $ComputerName.substring(0,4)
 
 Switch ($Datacenter){
	"VEAT" {
		tzutil /s "Romance Standard Time"
	}
	"VIWL" {
		tzutil /s "China Standard Time"
	}
	"NAMR" {
		tzutil /s "Eastern Standard Time"
	}
}


#OS Manufacturer
#We do this so we can append the Image name on the end for the Support Desk
If ($OSManufacturer) {
    write-log " "
    write-log ("="*75)
    write-log "Starting OS Manufacturer Name Change"
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
    $RegValue = "Manufacturer"
    $ManufacturerValue = (Get-ItemProperty -path $RegPath).$RegValue
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.visualbasic")
    $ManufacturerNewValue = [Microsoft.VisualBasic.Interaction]::InputBox("Manufacturer name", "Manufacturer name", "$ManufacturerValue")
    Reg-Write $RegPath $RegValue $ManufacturerNewValue
    write-log "Completed PVD Inventory"
    write-log ("-"*75)
}

#End Customer Specific Settings
#---------------------------------------------------------------------------------------------------------

# Setting Event Logs Size
write-log " "
write-log ("="*75)
write-log "Setting Eventlog size to " $ELSizeKB
Limit-EventLog -LogName "Application" -MaximumSize $ELSizeKB -Confirm
Limit-EventLog -LogName "HardwareEvents" -MaximumSize $ELSizeKB -Confirm
Limit-EventLog -LogName "Internet Explorer" -MaximumSize $ELSizeKB -Confirm
Limit-EventLog -LogName "Key Management Service" -MaximumSize $ELSizeKB -Confirm
Limit-EventLog -LogName "OAlerts" -MaximumSize $ELSizeKB -Confirm
Limit-EventLog -LogName "Security" -MaximumSize $ELSizeKB -Confirm
Limit-EventLog -LogName "System" -MaximumSize $ELSizeKB -Confirm
#Limit-EventLog -LogName "ThinPrint Diagnostic" -MaximumSize $ELSizeKB -Confirm
Limit-EventLog -LogName "Windows PowerShell" -MaximumSize $ELSizeKB -Confirm
Limit-EventLog -LogName "Windows PowerShell" -MaximumSize $ELSizeKB -Confirm
write-log "Completed EventLog Resize"
write-log ("-"*75)

# Clear All Event Logs on Device
If ($ClearEventLogs) {
write-log " "
write-log ("="*75)
write-log "Clear Eventlogs"
function Clear-All-Event-Logs ($hubAddress)
 {
   $Logs = Get-EventLog -ComputerName $hubAddress -List | ForEach {$_.Log}
   $Logs | ForEach {Clear-EventLog -Comp $hubAddress -Log $_ }
   Get-EventLog -ComputerName $hubAddress -List
 }
write-log "Completed clearing EventLogs"
write-log ("-"*75)
}

#Clean out System Temp Folders
write-log " "
write-log ("="*75)
write-log "Clear Temporary Files, software downloads, recycle bin"
Remove-Item C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Temp\*   -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\Windows\ServiceProfiles\LocalService\AppData\Local\Temp\*  -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item c:\windows\temp\*  -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item C:\windows\SoftwareDistribution\Download\*  -Recurse -Force -ErrorAction SilentlyContinue
#reset $RECYCLE.BIN
Get-ChildItem "C:\`$Recycle.Bin\" -Force | del -Recurse -ErrorAction SilentlyContinue
write-log "Completed clearing Temporary Files, software downloads, recycle bin"
write-log ("-"*75)

# Clean up IP Cached settings. ¯\_(ツ)_/¯
write-log " "
write-log ("="*75)
write-log "Clear DNS and update GPO"
if (($OSVersion -eq "Win7") -or ($OSVersion -eq "Win2KR2")) {

}
else {
Clear-DnsClientCache
}
Execute-File "ipconfig.exe /flushdns"
Execute-File "arp.exe -d"

# Update Group policy.
if (($OSVersion -eq "Win7") -or ($OSVersion -eq "Win2KR2")) {
	Execute-File "gpupdate.exe /force"
	}
else {
	Invoke-GPUpdate -force
	}
write-log " "
write-log ("="*75)
write-log "Cleared DNS and update GPO"

<#Defrag drives online using Perfectdisk
PDCmd /dol|/sp|/cfs  /alldrives|<drive1> <drive2>... [/w] [/c <computer-name>]
	Where:
		/dol          - Defragment only
		/sp           - SMARTPlacement
		/cfs          - Consolidate free space
		/alldrives - perform compaction of all drives
		/w            - wait until operation completes
		#>
if ($Perfectdisk) {
    write-log " "
    write-log ("="*75)
    write-log "PerfectDisk Defrag"
	Write-Verbose "PerfectDisk is defraging system Please WAIT"
    Execute-File "%ProgramFiles%\Raxco\PerfectDisk\PDCMD.exe /sp /w c" $True
	Execute-File "%ProgramFiles%\Raxco\PerfectDisk\PDCMD.exe /w /sto c" $True
    write-log "Complete PerfectDisk Defrag"
    write-log ("-"*75)
}

# Optimize Volume using Powershell
# Requires Powershell 5 or higher
# Clear Free Space
# Run Disk Cleanup
if ($CleanDisk) {
	write-log " "
	write-log ("="*75)
	write-log "Starting Disk Cleanup"
	Start-Process cleanmgr /VERYLOWDISK -NoNewWindow -Wait
	write-log "Completed Disk Cleanup"
	write-log ("-"*75)
}

if ($PSDefrag) {
	If (($OSVersion -eq "Win2k8R2") -or ($OSVersion -eq "Win10") -or ($OSVersion -eq "Win2016") -or ($OSVersion -eq "Win2019")) {
		write-log " "
		write-log ("="*75)
		write-log "Started Powershell Defrag"
		Write-Verbose "Optimizing System Volume Please Wait"
		Execute-File "Optimize-Volume -DriveLetter C -Defrag –Verbose" $True
		write-log "Completed PowerShell Defrag"
		write-log ("-"*75)
	}
}

#Zero out free space with SDelete
#http://technet.microsoft.com/en-us/sysinternals/bb897443.
If ($ZeroFreeSpace) {
	Write-Host -foregroundcolor Red "ZeroFreeSpace Begin"
	write-log " "
    write-log ("="*75)
    write-log "Starting SDelete"
    #This line will add agreement of the SysInternals EULA to the registry
    if (!(Test-RegistryValue "HKCU:\Software\Sysinternals\SDelete" "EulaAccepted")) {
        if (!(Test-Path "HKCU:\Software\Sysinternals\SDelete")) {
            New-Item "HKCU:\Software\Sysinternals\SDelete"
            write-log "HKCU:\Software\Sysinternals\SDelete Created"
        }
        New-ItemProperty "HKCU:\Software\Sysinternals\SDelete" -Name "EulaAccepted" -Value 1 -PropertyType "DWord"
        write-log "HKCU:\Software\Sysinternals\SDelete EulaAccepted Created with value of 1"
    }
    Else {
        Reg-Write "HKCU:\Software\Sysinternals\SDelete" "EulaAccepted" 1
            }
    Execute-File "$PVSPrepLocal\sdelete.exe" "-c -z c:" $True
    write-log "Completed SDelete"
    write-log ("-"*75)
	Write-Host -foregroundcolor Green "ZeroFreeSpace End"
}
