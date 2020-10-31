
#System Deployed
$VMViewInstalled= $False							# VMware View Deployed
$CTX7Install = $False								  # Citrix XenDesktop 7.x Installed
$CTX65Install = $False								# Citrix XenApp 6.5 Installed
$CTX5Install = $False								  # Citrix XenApp 5.x Installed
$CTX45Install = $False								# Citrix XenApp 4.5 Installed
$CTXPVSDeployed = $False							# Citrix Provisioning Services installed

# General Settings
$PVSPrepUNC = "\\DS1815\Storage\Citrix_Software\PVS\PVSPrepProd"	# UNC Path to PVS Files - No trailing "\"
$PVSPrepLocal = "C:\Windows\PVSPrep"                              # Local PVSPrep Files location
$WriteCacheDrive = "D"								                            # Write Cache Drive Letter
$pagemin = 16384 									                                # Pagefile minimum size
$pagemax = 16384  									                              # Pagefile maximum size
$CDDriveLetter = "Z:"                             	              # What drive to change the CD to (Must have the ":")
$ELSizeKB = 1024KB                             		                # What is the size for the Eventlog)

#Addins
$Datacenter = "" 									                                # Define Datacenter
$ComputerName = $env:COMPUTERNAME					                        # Set computername variable
$GPODDCs = $False                                 	              # To set DDCs from GPO
$ListOfDDCs = ""                                 	                # Leave Blank for no changes - This string value takes a space-delimited list of Controllers, which Fully Qualified Domain Name (FQDN) (for example, myddc.mydomain.com) is specified.
$ClearEventLogs	= $False							                            # Clear All Event Logs on Device
$ReArm = $False                                		                # ReArm Windows Licensing
$ReArmOffice = $False								                              # ReArm Office
$SCCM2007Remove = $False                           	# Remove SSCM 2007 for PVD VMs
$SCCM2012Installed = $False                         # Is SCCM 2012 Deployed
$IvantiUWMInstalled = $False                        # Is Ivanti UWM Deployed
$RESInstalled = $False                             	# Is RES Deployed
$SymantecInstalled = $False                         # Is Symantec Deployed
$McAfeeInstalled = $False                           # Is McAfee Deployed
$McAfeeMoveInstalled = $False                    	  # Is McAfee Move Deployed
$WindowsDefenderATP = $False                        # Is Windows Defender ATP Installed
$AppV5Installed = $False                           	# Is App-v 5 Deployed
$Nibsoft = $False                               	  # Is Nibsoft Deployed
$Imprivata = $False                              	  # Is Imprivata Deployed
$Liquidware = $False                              	# Is Liquidware Stratosphere Deployed
$PVDInventory = $False                            	# Is for PVS Image Inventory
$PerfectDisk = $False                           	  # Defrag using Perfect Disk (Set PerfectDisk in gui if using thin provisioing)
$CleanDisk = $False									                # Cleanup Disk Space
$PSdefrag = $False									                # Defrag drive with Powershell
$ZeroFreeSpace = $False                             # Zero out free space

#Client request
$OSManufacturer = $False                          	# Change Manufacturer name in OS
$hubAddress = "LocalHost"                          	# Address of Stratosphere Server Set to "LocalHost" if set by GPO
