$text = @"
██████╗ ██╗███████╗██╗  ██╗██████╗ ███████╗██╗██╗  ██╗████████╗██╗   ██╗
██╔══██╗██║██╔════╝██║ ██╔╝╚════██╗██╔════╝██║╚██╗██╔╝╚══██╔══╝╚██╗ ██╔╝
██████╔╝██║███████╗█████╔╝  █████╔╝███████╗██║ ╚███╔╝    ██║    ╚████╔╝ 
██╔══██╗██║╚════██║██╔═██╗  ╚═══██╗╚════██║██║ ██╔██╗    ██║     ╚██╔╝  
██║  ██║██║███████║██║  ██╗██████╔╝███████║██║██╔╝ ██╗   ██║      ██║   
╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝ 
  
███████╗████████╗██████╗  █████╗ ███╗   ██╗ ██████╗ ███████╗
██╔════╝╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔════╝
███████╗   ██║   ██████╔╝███████║██╔██╗ ██║██║  ███╗█████╗  
╚════██║   ██║   ██╔══██╗██╔══██║██║╚██╗██║██║   ██║██╔══╝  
███████║   ██║   ██║  ██║██║  ██║██║ ╚████║╚██████╔╝███████╗

██████╗ ███████╗███╗   ██╗███████╗ ██████╗  █████╗ ██████╗ ███████╗███████╗
██╔══██╗██╔════╝████╗  ██║██╔════╝██╔════╝ ██╔══██╗██╔══██╗██╔════╝██╔════╝
██████╔╝█████╗  ██╔██╗ ██║█████╗  ██║  ███╗███████║██║  ██║█████╗  ███████╗
██╔══██╗██╔══╝  ██║╚██╗██║██╔══╝  ██║   ██║██╔══██║██║  ██║██╔══╝  ╚════██║
██║  ██║███████╗██║ ╚████║███████╗╚██████╔╝██║  ██║██████╔╝███████╗███████║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝
"@   

#download the installation assets from our S3 bucket
New-Item -Path "c:\" -Name "new_install" -ItemType "directory"
Invoke-WebRequest -Uri https://s3.amazonaws.com/public.risk3sixty.com/phalanx_shield_bg.jpg -OutFile C:\new_install\phalanx_bg.jpg
Invoke-WebRequest -Uri https://s3.amazonaws.com/public.risk3sixty.com/standard_packages.txt -OutFile C:\new_install\standard_packages.txt
Invoke-WebRequest -Uri https://s3.amazonaws.com/public.risk3sixty.com/SentinelInstaller-x64_windows_64bit_v4_1_2_45.exe -OutFile C:\new_install\SentinelInstaller-x64_windows_64bit_v4_1_2_45.exe
Invoke-WebRequest -Uri https://s3.amazonaws.com/public.risk3sixty.com/r3s-wifi.xml -OutFile C:\new_install\r3s-wifi.xml


#add the local user admin
$LAPassword = Read-Host -Prompt 'Please set the standard local admin password defined in Asana' 
New-LocalUser "Local_Admin" -Password $LAPassword -FullName "Local Admin"
Add-LocalGroupMember -Group "Administrators" -Member "Local_Admin"

#rename the PC
$Rename = Read-Host -Prompt 'Please input the computer name based on the associated asset tag'
Rename-Computer -NewName $Rename

#add the corporate office Wi-Fi profile to the laptop
$PW= Read-Host -Prompt 'Please enter the office Wi-Fi password' 
$xmlfile= "C:\new-install\r3s-wifi.xml"
netsh wlan add profile filename="$($xmlfile)"

#set DNS to secure services (should work on most Dell laptops out of the box, else you may need to query the InterfaceAlias using the Get-NetAdapter CmdLet
Set-DnsClientServerAddress -InterfaceAlias Wi-Fi -ServerAddresses ("9.9.9.9","208.67.222.222")
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses ("9.9.9.9","208.67.222.222")

#set wallpaper
Function Get-WallPaper()
{
 $wp=Get-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name wallpaper
 if(!$wp.WallPaper)
   { "Wall paper is not set" }
 Else
  {"Wall paper is set to $($wp.WallPaper)" }
}
Function Set-WallPaper($Value)
{
 Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name wallpaper -value $value
 rundll32.exe user32.dll, UpdatePerUserSystemParameters
}
Get-WallPaper
Set-WallPaper -value "C:\new_install\phalanx_bg.jpg"
Get-WallPaper

#Backup Bitlocker to Azure AD/O365 - Narrow scope to applicable recovery protector
$AllProtectors = (Get-BitlockerVolume -MountPoint $env:SystemDrive).KeyProtector 
$RecoveryProtector = ($AllProtectors | where-object { $_.KeyProtectorType -eq "RecoveryPassword" })

#Push Recovery Passoword Azure AD/O365
BackupToAAD-BitLockerKeyProtector $env:systemdrive -KeyProtectorId $RecoveryProtector.KeyProtectorID

# install chocolatey if not installed
if (!(Test-Path -Path "$env:ProgramData\Chocolatey")) {
  Invoke-Expression((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# for each package in the list run install
Get-Content "c:\new_install\standard_packages.txt" | ForEach-Object{($_ -split "\r\n")[0]} | ForEach-Object{choco install -y $_}

#run the SentinelOne installer
Invoke-Item C:\new_install\SentinelInstaller-x64_windows_64bit_v4_1_2_45.exe                                                               
