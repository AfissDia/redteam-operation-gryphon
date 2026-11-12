#requires -RunAsAdministrator
# Revoir les chemins et les groupes ; laboratoire isolé uniquement.
$ErrorActionPreference='Stop'
$root='C:\Meridian\Partages'
$items=@(
 @{Name='Commun';Group='MERIDIAN\GG_Employes'},
 @{Name='Finance';Group='MERIDIAN\GG_Finance'},
 @{Name='Direction';Group='MERIDIAN\GG_Direction'}
)
# Selon la politique métier, tous les comptes employés peuvent avoir accès à Commun.
# Ici, 'Utilisateurs du domaine' est ajouté en lecture seule pour Commun.
foreach($s in $items) {
 $path=Join-Path $root $s.Name
 New-Item -ItemType Directory -Path $path -Force | Out-Null
 $acl=Get-Acl $path
 $acl.SetAccessRuleProtection($true,$false)
 foreach($entry in @('AUTORITE NT\SYSTEM','BUILTIN\Administrators')) {
   $r=New-Object System.Security.AccessControl.FileSystemAccessRule($entry,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
   $acl.SetAccessRule($r)
 }
 $accessGroup = if($s.Name -eq 'Commun') {'MERIDIAN\Utilisateurs du domaine'} else {$s.Group}
 $r=New-Object System.Security.AccessControl.FileSystemAccessRule($accessGroup,($(if($s.Name -eq 'Commun') {'ReadAndExecute'} else {'Modify'})),'ContainerInherit,ObjectInherit','None','Allow')
 $acl.SetAccessRule($r)
 Set-Acl -Path $path -AclObject $acl
 if(-not (Get-SmbShare -Name $s.Name -ErrorAction SilentlyContinue)) {
   if($s.Name -eq 'Commun') {
     New-SmbShare -Name $s.Name -Path $path -FullAccess 'BUILTIN\Administrators' -ReadAccess $accessGroup
   } else {
     New-SmbShare -Name $s.Name -Path $path -FullAccess 'BUILTIN\Administrators' -ChangeAccess $accessGroup
   }
 }
 # Ne pas écraser des ACL SMB existantes sans revue :
 Get-SmbShareAccess -Name $s.Name
}
