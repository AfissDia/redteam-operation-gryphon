# Script de collecte non destructif — à lancer uniquement sur P6-DC01
# Ne contient aucun secret et ne modifie pas la configuration.
Import-Module ActiveDirectory
Write-Host "--- Domaine ---"
Get-ADDomain | Select-Object DNSRoot,NetBIOSName,DistinguishedName
Write-Host "--- Réseau ---"
Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias,IPAddress,PrefixLength
Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object InterfaceAlias,ServerAddresses
Write-Host "--- Services ---"
Get-Service NTDS,DNS,Netlogon
Write-Host "--- OU ---"
Get-ADOrganizationalUnit -Filter * | Select-Object Name,DistinguishedName
Write-Host "--- Groupes projet ---"
Get-ADGroup -Filter 'Name -like "GG_*"' | Select-Object Name,GroupScope
Write-Host "--- Partages ---"
Get-SmbShare | Where-Object Name -in @('Commun','Finance','Direction') | Select-Object Name,Path
