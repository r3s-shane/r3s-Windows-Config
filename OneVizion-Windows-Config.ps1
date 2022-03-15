$text = @"
OneVizion's enduser laptop configuration script
"@

#download the installation assets from our S3 bucket
New-Item -Path "c:\" -Name "new_install" -ItemType "directory"
Invoke-WebRequest -Uri https://s3.amazonaws.com/public.risk3sixty.com/standard_packages.txt -OutFile C:\new_install\standard_packages.txt

#add the local user admin
$LAPassword = Read-Host -AsSecureString -Prompt 'Please set the local admin password defined in Asana'
New-LocalUser "Local_Admin" -Password $LAPassword -FullName "Local Admin"
Add-LocalGroupMember -Group "Administrators" -Member "Local_Admin"

#rename the PC
$Rename = Read-Host -Prompt 'Please input the computer name based on the associated asset tag'
Rename-Computer -NewName $Rename

#set DNS to secure services (should work on most Dell laptops out of the box, else you may need to query the InterfaceAlias using the Get-NetAdapter CmdLet
Set-DnsClientServerAddress -InterfaceAlias Wi-Fi -ServerAddresses ("9.9.9.9","208.67.222.222")
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses ("9.9.9.9","208.67.222.222")

#Backup Bitlocker to Azure AD/O365 - Narrow scope to applicable recovery protector
$AllProtectors = (Get-BitlockerVolume -MountPoint $env:SystemDrive).KeyProtector
$RecoveryProtector = ($AllProtectors | where-object { $_.KeyProtectorType -eq "RecoveryPassword" })

#Push Recovery Password Azure AD/O365
BackupToAAD-BitLockerKeyProtector $env:systemdrive -KeyProtectorId $RecoveryProtector.KeyProtectorID

#Remove the Windows 10 Mail and Calendar app as we want users to use Outlook or O365 Webapps
Get-AppxPackage Microsoft.windowscommunicationsapps | Remove-AppxPackage

# install chocolatey if not installed
if (!(Test-Path -Path "$env:ProgramData\Chocolatey")) {
  Invoke-Expression((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# for each package in the list run install
Get-Content "c:\new_install\standard_packages.txt" | ForEach-Object{($_ -split "\r\n")[0]} | ForEach-Object{choco install -y $_}
