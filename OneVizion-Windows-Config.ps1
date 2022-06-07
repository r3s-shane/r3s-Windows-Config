$text = @"
OneVizion's enduser laptop configuration scripts

To run this script:
1. Save the file to C:\ or another directory you can easily navigate to in Powershell. Make sure you change the file type from a .txt to a .ps1 (change the folder options to display file extensions for known file types)
2. Open Powershell as an admin and navigate to the directory where you stored this OutFile (e.g., CD c:\)
3. Change the remote execution policy by typing:  set-executionpolicy remotesigned   Then type "Y"
4. Run this Powershell script by typing its name and hitting enter
5. Change the remote execution policy back by typing: set-executionpolicy remotesigned   Then type "N"
6. IM Shane if you get stuck or something breaks.
"@

#download the installation assets
New-Item -Path "c:\" -Name "new_install" -ItemType "directory"
Invoke-WebRequest -Uri https://raw.githubusercontent.com/shanepeden/OneVizion-Windows-Config/master/standard_packages.txt -OutFile C:\new_install\standard_packages.txt

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
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# for each package in the list run install
Get-Content "c:\new_install\standard_packages.txt" | ForEach-Object{($_ -split "\r\n")[0]} | ForEach-Object{choco install -y $_}
