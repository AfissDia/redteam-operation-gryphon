#requires -RunAsAdministrator
# À exécuter sur le DC d'un laboratoire meridian.test déjà créé.
Import-Module ActiveDirectory
$ErrorActionPreference = 'Stop'
$dn = (Get-ADDomain).DistinguishedName
if ($dn -ne 'DC=meridian,DC=test') { throw "Domaine inattendu : $dn" }
$ouList = 'Direction','Finance','IT','Utilisateurs','Serveurs','Groupes'
foreach ($name in $ouList) {
  if (-not (Get-ADOrganizationalUnit -LDAPFilter "(ou=$name)" -SearchBase $dn -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $name -Path $dn -ProtectedFromAccidentalDeletion $true
  }
}
$groups = 'GG_Direction','GG_Finance','GG_IT','GG_Employes'
foreach ($name in $groups) {
  if (-not (Get-ADGroup -Filter "SamAccountName -eq '$name'" -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name $name -SamAccountName $name -GroupScope Global -GroupCategory Security -Path "OU=Groupes,$dn"
  }
}
$members = @(
 @{Account='s.martin'; Name='Sophie Martin'; OU='Direction'; Group='GG_Direction'},
 @{Account='a.dupont'; Name='Alex Dupont'; OU='Finance'; Group='GG_Finance'},
 @{Account='t.bernard'; Name='Thomas Bernard'; OU='IT'; Group='GG_IT'},
 @{Account='a.dia'; Name='Alex Dia'; OU='IT'; Group='GG_IT'},
 @{Account='j.petit'; Name='Julie Petit'; OU='Utilisateurs'; Group='GG_Employes'}
)
foreach ($u in $members) {
  $sam = $u.Account
  if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue)) {
    $pw = Read-Host -AsSecureString "Mot de passe initial pour $sam (politique AD requise)"
    New-ADUser -Name $u.Name -SamAccountName $sam -UserPrincipalName "$sam@meridian.test" `
      -Path "OU=$($u.OU),$dn" -Enabled $true -AccountPassword $pw -ChangePasswordAtLogon $true
  }
  if (-not (Get-ADGroupMember -Identity $u.Group | Where-Object SamAccountName -eq $sam)) {
    Add-ADGroupMember -Identity $u.Group -Members $sam
  }
}
Write-Host 'OU, groupes et comptes vérifiés.'
