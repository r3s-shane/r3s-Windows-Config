$PW= Read-Host -Prompt 'Please enter the office Wi-Fi password' 
$xmlfile= "C:\r3s-wifi.xml"

netsh wlan add profile filename="$($xmlfile)"

