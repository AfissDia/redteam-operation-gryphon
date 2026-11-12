# Opération Gryphon - Procédure complète de reproduction

**Projet 6 - Mastère Cybersécurité, La Plateforme_**  
**Périmètre : laboratoire local fictif Meridian Bank, domaine `meridian.test`**  
**Version documentaire : 12 novembre 2026**

> Objectif : reconstruire en une journée de travail le laboratoire, les tests autorisés et la chaîne de collecte/analyse, **si** les ISO, exécutables, VM et ressources ont été préparés au préalable. Il ne s'agit pas d'une promesse pour une installation à partir de zéro sur n'importe quel PC.

## 0. Lecture rapide - parcours en une journée

| Phase | Repère indicatif | Preuve de réussite |
|---|---|---|
| Préparer la VM et les réseaux | 30 à 60 min si ISO/VM prêts | `P6-DC01` répond sur `192.168.60.10` |
| AD DS, DNS, OU, comptes | 60 à 90 min | `Get-ADDomain`, `Resolve-DnsName` et inventaire AD |
| Partages, GPO et tests | 60 à 90 min | Accès `Commun`, refus `Finance`, GPO liée |
| BloodHound.py CE, Kerberos, LDAPS | 60 à 90 min si outils disponibles | ZIP `bloodhound.zip` contenant les JSON |
| Sysmon et export des journaux | 30 à 60 min | EVTX contenant les ID 1, 11 et 22 |
| Chainsaw, Hayabusa, synthèse | 45 à 75 min si outils installés | JSON Chainsaw et CSV Hayabusa |

**Accélérateurs** : récupérer les archives officielles à l'avance, utiliser une VM préconfigurée/snapshot, reprendre les scripts de ce dépôt et ne jamais reconstruire inutilement l'environnement du Projet 5.

### Règles du laboratoire

- N'exécuter les tests que sur les VM et comptes créés pour ce TP. Pas de cible réelle.
- Pas de désactivation de Microsoft Defender ni de la signature LDAP pour faciliter BloodHound.
- Sauvegarder/snapshotter la VM avant les changements sensibles et protéger les fichiers EVTX et ZIP AD.
- Les comptes et noms donnés ici sont **fictifs** ; définir des mots de passe uniques pendant l'exécution, jamais dans les scripts ou Git.
- Distinguer une **action d'administration volontaire** d'une élévation de privilèges exploitée.

## 1. Repères et définitions essentielles

| Mot-clé | Définition très simple | Pourquoi utile |
|---|---|---|
| AD DS | Annuaire Windows qui centralise comptes et autorisations. | Gérer le SI Meridian. |
| Domaine | Ensemble d'objets et de politiques partageant une identité AD. | `meridian.test`. |
| Forêt | Frontière logique englobant un ou plusieurs domaines AD. | Ici, une forêt, un domaine. |
| Contrôleur de domaine (DC) | Serveur qui héberge AD DS et authentifie les comptes. | `P6-DC01`. |
| DNS / SRV | Traduit les noms en IP et localise les services AD. | Permet de trouver LDAP et Kerberos. |
| OU | Conteneur logique pour ranger les objets AD et cibler des GPO. | `IT`, `Finance`, `Direction`... |
| Groupe de sécurité | Ensemble de membres auquel attribuer des droits. | `GG_Finance` pour un partage. |
| ACL / NTFS / SMB | ACL : règles d'accès ; NTFS : permissions sur disque ; SMB : partage réseau. | Deux niveaux de contrôle sur `Finance`. |
| GPO | Stratégie de groupe appliquée aux objets AD visés. | Écran de veille et verrouillage. |
| FSMO / PDC Emulator | Rôles spéciaux AD ; le PDC synchronise l'heure du domaine. | Kerberos tolère mal un décalage d'horloge. |
| NAT | Réseau VirtualBox autorisant la sortie et la redirection de ports. | SSH depuis l'hôte. |
| Réseau interne | Réseau isolé reliant uniquement les VM concernées. | `P6-LAB`. |
| Kerberos / TGT | Authentification à tickets ; TGT = premier ticket obtenu. | Évite une connexion LDAP NTLM non signée. |
| LDAP signing / LDAPS | Signature LDAP protège l'intégrité ; LDAPS chiffre via TLS. | Authentification/collecte AD protégée. |
| PKI / CA / certificat | Chaîne de confiance reliant un certificat à une identité. | Faire approuver le certificat du DC par Ubuntu. |
| Sysmon / EVTX | Sysmon = télémétrie Windows ; EVTX = fichier journal. | Traces d'exécution, DNS et fichiers. |
| Sigma | Format générique de règles de détection sur événements. | Détection réutilisable entre moteurs. |
| Chainsaw | Recherche et hunting dans des journaux Windows. | Filtrer les Event ID et lancer des règles. |
| Hayabusa | Moteur de détection/chronologie pour EVTX Windows. | Produire une timeline CSV. |
| Wazuh | Plateforme SIEM/XDR avec agents et supervision continue. | Différent d'une analyse ponctuelle hors ligne. |
| BloodHound | Cartographie de relations AD et, dans CE, analyse de chemins d'attaque. | Comprendre les droits effectifs. |
| MITRE ATT&CK | Référentiel de comportements adverses. | Qualifier les techniques sans inventer d'exploit. |

## 2. Préparation - machines et réseau

### 2.1 Matériel observé

- Hôte Windows avec 15,65 Go de RAM et 4 processeurs logiques ; espace C: limité (~11 Go à la fin).
- VirtualBox 7.2.22 ; VM Windows Server 2025 Datacenter Evaluation **Server Core** : `P6-DC01`.
- VM Ubuntu existante : `p5_client-01`, ~1,8 Gio de RAM, racine 16 Go.
- Le projet a fonctionné sans installer Docker Desktop/BloodHound CE officiel sur l'hôte.

### 2.2 Plan d'adressage

```text
HOTE WINDOWS
  |-- VirtualBox NAT (P6-DC01 : 10.0.2.15, port SSH hôte 2223 -> invité 22)
  |-- VirtualBox NAT (Ubuntu : 10.0.3.15, port SSH hôte 2222 -> invité 22)

RESEAU INTERNE P6-LAB : 192.168.60.0/24
  P6-DC01 Windows Server : 192.168.60.10/24   DNS AD : 192.168.60.10
  p5_client-01 Ubuntu    : 192.168.60.20/24   NIC enp0s9
```

**Pourquoi deux cartes ?** NAT pour les téléchargements/SSH ; réseau interne pour les échanges AD/SMB isolés. Sur la carte `P6-LAB`, ne pas renseigner de passerelle Internet.

### 2.3 Configurer l'interface Windows interne

Sur `P6-DC01`, ouvrir PowerShell administrateur (console VirtualBox ou SSH) et vérifier les interfaces :

```powershell
Get-NetAdapter | Format-Table Name,Status,MacAddress
Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias,IPAddress,PrefixLength
# Exécuter seulement si Ethernet 2 n'a pas déjà cette adresse :
New-NetIPAddress -InterfaceAlias 'Ethernet 2' -IPAddress 192.168.60.10 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias 'Ethernet 2' -ServerAddresses 192.168.60.10
```

Interface NAT : conserver la configuration DHCP. Après promotion en DC, vérifier les DNS (`127.0.0.1` et/ou `192.168.60.10`) et la résolution du domaine. Éviter d'appliquer aveuglément une adresse déjà configurée.

### 2.4 Ajouter la carte Ubuntu sans casser le Projet 5

Dans VirtualBox, adapter 3 de `p5_client-01` = `Réseau interne`, nom **P6-LAB**. Dans Ubuntu :

```bash
ip -br addr
sudo ip addr add 192.168.60.20/24 dev enp0s9  # si adresse absente
ping -c 2 192.168.60.10
# DNS uniquement pour notre domaine AD :
sudo resolvectl dns enp0s9 192.168.60.10
sudo resolvectl domain enp0s9 '~meridian.test'
sudo resolvectl flush-caches
resolvectl query p6-dc01.meridian.test
```

**Attention** : `ip addr add` et `resolvectl` sont des réglages de session ; ils peuvent disparaître au redémarrage. Pour un labo permanent, les déclarer dans Netplan (sans toucher aux routes pfSense du Projet 5). Si Ubuntu perd Internet, vérifier `ip route` : la route par défaut de pfSense peut prendre le dessus sur NAT.

### 2.5 SSH depuis le Windows hôte

Configurer les redirections NAT VirtualBox : port `2223` de l'hôte vers SSH de P6-DC01, port `2222` vers Ubuntu. Tester :

```powershell
ssh -p 2223 administrateur@127.0.0.1
ssh -p 2222 p5_client-01@127.0.0.1
```

## 3. Déployer AD DS et DNS

### 3.1 Installer les rôles

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName 'meridian.test' -DomainNetbiosName 'MERIDIAN' -InstallDNS
```

La deuxième commande sollicite un mot de passe DSRM et redémarre le serveur après promotion. **Ne pas la relancer sur un DC existant.**

### 3.2 Vérifier la forêt et les services

```powershell
Get-ADDomain | Select-Object DNSRoot,NetBIOSName,PDCEmulator
Get-ADForest | Select-Object Name,Domains
Get-Service NTDS,DNS,Netlogon
Resolve-DnsName meridian.test -Server 192.168.60.10
Resolve-DnsName _ldap._tcp.dc._msdcs.meridian.test -Type SRV -Server 192.168.60.10
```

Résultats attendus : domaine/forêt `meridian.test`, services actifs, DNS renvoyant le DC.

## 4. OU, utilisateurs et groupes

### 4.1 Organisation et comptes fictifs

```text
meridian.test
  OU=Direction        s.martin
  OU=Finance          a.dupont
  OU=IT               t.bernard, a.dia
  OU=Utilisateurs     j.petit
  OU=Serveurs         (prévue pour serveurs membres)
  OU=Groupes          GG_Direction, GG_Finance, GG_IT, GG_Employes
```

Un compte de domaine est un compte d'annuaire ; il n'est pas administrateur parce qu'il appartient à une OU nommée `IT`.

### 4.2 Script reproductible

Utiliser `lab/scripts/01-bootstrap-ad.ps1` depuis le DC, dans une session administrateur. Il teste l'existence des objets avant création et **demande les mots de passe à la saisie**.

```powershell
Set-ExecutionPolicy -Scope Process Bypass
& '.\lab\scripts\01-bootstrap-ad.ps1'
```

Si les scripts sont exécutés sur le DC, copier d'abord le dossier `lab/scripts` sur celui-ci. Vérification :

```powershell
Get-ADOrganizationalUnit -Filter * | Select Name,DistinguishedName
Get-ADUser -Filter * | Where-Object SamAccountName -in 's.martin','a.dupont','t.bernard','a.dia','j.petit' | Select Name,SamAccountName,Enabled
Get-ADGroupMember GG_Finance
```

## 5. Partages SMB et contrôle d'accès

### 5.1 Partages attendus

| Partage | Droit métier attendu | Test témoin |
|---|---|---|
| `Commun` | Lecture selon politique de labo ; écriture si voulue | `a.dia` lit `reglement.txt` |
| `Finance` | Membres `GG_Finance` et administrateurs | `a.dia` refusé hors groupe |
| `Direction` | Membres `GG_Direction` et administrateurs | Refus des non-membres |

La permission effective résulte du **partage SMB ET du système NTFS** : si l'un refuse, l'accès échoue. Prévoir les comptes administrateurs et SYSTEM dans les ACL.

### 5.2 Installation contrôlée

```powershell
New-Item C:\Meridian\Partages\Commun,C:\Meridian\Partages\Finance,C:\Meridian\Partages\Direction -ItemType Directory -Force
# Les ACL exactes sont spécifiques au labo et doivent être validées avant publication ;
# ne pas se contenter du défaut « Everyone Full Control ».
Get-SmbShare | Where-Object Name -in 'Commun','Finance','Direction'
Get-SmbShareAccess -Name Finance
icacls C:\Meridian\Partages\Finance
```

Pour reproduire la politique, appliquer le script `lab/scripts/02-partages.ps1` **après relecture** des chemins et des groupes. Il crée les dossiers, ajoute les groupes et limite les ACL de manière explicite.

### 5.3 Tests Ubuntu

```bash
sudo apt install -y smbclient
smbclient //192.168.60.10/Commun -U 'MERIDIAN\a.dia' -m SMB3
# Dans l'invite smb: ls, get reglement.txt, exit
smbclient //192.168.60.10/Finance -U 'MERIDIAN\a.dia' -m SMB3
# Dans l'invite smb: ls -> refus attendu si a.dia n'est pas membre Finance.
```

Ne jamais inclure les mots de passe dans les arguments des commandes.

### 5.4 Simulation contrôlée des changements de groupe

Un administrateur du laboratoire ajoute puis retire temporairement `a.dia` du groupe Finance :

```powershell
Add-ADGroupMember -Identity 'GG_Finance' -Members 'a.dia'
Get-ADGroupMember 'GG_Finance' | Select Name,SamAccountName
Remove-ADGroupMember -Identity 'GG_Finance' -Members 'a.dia' -Confirm:$false
```

Le jeton des sessions déjà ouvertes peut nécessiter une reconnexion pour refléter un changement d'appartenance. **Ceci est une opération administrative volontaire, pas un exploit d'élévation de privilèges.**

### 5.5 Activer l'audit des accès aux partages (pour un nouvel essai 5145)

L'ID **5145** nécessite l'audit « Detailed File Share » approprié. Sur le DC, consulter/activer la sous-catégorie locale, et vérifier que la GPO domaine ne la remplace pas :

```powershell
auditpol /get /subcategory:'Detailed File Share'
# Sur Windows FR, le nom localisé peut différer : auditpol /list /subcategory:*
# Pour l'activation reproductible, consulter l'identifiant GUID retourné par auditpol.
```

Notre capture initiale prouvait le refus `a.dia` sur `Finance`, mais **le dernier EVTX exporté et analysé ne contenait aucun 5145 détectable**. Ne pas promettre sa présence au nouvel export sans la vérifier.

## 6. GPO de verrouillage

**Définition** : une GPO est une stratégie AD appliquée à une OU, un domaine ou un site. Une GPO de paramètres utilisateur exige un utilisateur Windows dans le périmètre pour valider l'application.

```powershell
Import-Module GroupPolicy
$gpo = Get-GPO -Name 'GPO_Meridian_Securite' -ErrorAction SilentlyContinue
if (-not $gpo) { $gpo = New-GPO -Name 'GPO_Meridian_Securite' }
$target = 'OU=IT,DC=meridian,DC=test'
# Exécuter New-GPLink seulement si le lien n'existe pas déjà.
New-GPLink -Name 'GPO_Meridian_Securite' -Target $target -LinkEnabled Yes
$key = 'HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop'
Set-GPRegistryValue -Name 'GPO_Meridian_Securite' -Key $key -ValueName ScreenSaveActive -Type String -Value '1'
Set-GPRegistryValue -Name 'GPO_Meridian_Securite' -Key $key -ValueName ScreenSaveTimeOut -Type String -Value '600'
Set-GPRegistryValue -Name 'GPO_Meridian_Securite' -Key $key -ValueName ScreenSaverIsSecure -Type String -Value '1'
Get-GPInheritance -Target $target
Get-GPRegistryValue -Name 'GPO_Meridian_Securite' -Key $key -ValueName ScreenSaveTimeOut
Get-GPOReport -Name 'GPO_Meridian_Securite' -ReportType Html -Path 'C:\Gryphon\GPO\rapport-gpo.html'
```

**Dans notre réalisation** : création/lien et paramètres vérifiés. Pas de poste Windows client joint au domaine pour tester l'application effective de l'écran de veille.

## 7. Cartographie Active Directory avec BloodHound.py CE

### 7.1 Pourquoi cette méthode ?

Le collecteur Linux ne nécessite pas le logiciel SharpHound Windows, que Defender avait bloqué lors de téléchargements. Le collecteur exporte des **JSON**, puis un ZIP. **Il ne fournit pas l'interface graphique officielle BloodHound CE.**

### 7.2 Prérequis Ubuntu

```bash
sudo apt update
sudo apt install -y python3-venv python3-pip openssl ca-certificates dnsutils
mkdir -p ~/gryphon-bloodhound && cd ~/gryphon-bloodhound
python3 -m venv .venv
source .venv/bin/activate
python -m pip install bloodhound-ce
bloodhound-ce-python --help
```

Sur notre image Ubuntu, `python3.14-venv` a dû être installé séparément. Si `ensurepip` manque, installer le paquet `python3.x-venv` correspondant à l'interpréteur actif.

### 7.3 Kerberos : DNS et horloges

```bash
resolvectl query p6-dc01.meridian.test
nc -zv -w 3 p6-dc01.meridian.test 88
```

`KRB_AP_ERR_SKEW` = horloges trop éloignées. Vérifier `date -Is` sur Ubuntu, `Get-Date` et `w32tm /query /source` sur le DC. Le DC jouant PDC Emulator doit s'appuyer sur une heure fiable ; ne jamais désactiver la vérification de l'heure.

### 7.4 Créer LDAPS proprement sur le DC

Dans notre laboratoire isolé, un certificat **autosigné** a été créé pour `p6-dc01.meridian.test`. Pour un SI réel, utiliser une PKI approuvée.

```powershell
New-Item C:\Gryphon\LDAPS -ItemType Directory -Force | Out-Null
$cert = New-SelfSignedCertificate -DnsName 'p6-dc01.meridian.test' `
  -CertStoreLocation 'Cert:\LocalMachine\My' -Type SSLServerAuthentication `
  -KeyAlgorithm RSA -KeyLength 2048 -KeyExportPolicy NonExportable `
  -NotAfter (Get-Date).AddMonths(12)
$cert | Format-List Subject,Thumbprint,HasPrivateKey,NotAfter
Export-Certificate -Cert $cert -FilePath 'C:\Gryphon\LDAPS\p6-dc01-ldaps.cer'
# Seulement pour ce lab autosigné : faire confiance localement à ce certificat
Import-Certificate -FilePath 'C:\Gryphon\LDAPS\p6-dc01-ldaps.cer' -CertStoreLocation 'Cert:\LocalMachine\Root'
```

Après snapshot et redémarrage contrôlé de `P6-DC01` si nécessaire :

```bash
openssl s_client -connect p6-dc01.meridian.test:636 \
 -servername p6-dc01.meridian.test -showcerts </dev/null
```

**Résultat obtenu** : handshake TLS 1.3 `TLS_AES_256_GCM_SHA384`. Avant installation de la confiance, OpenSSL indiquait `self-signed certificate`, ce qui n'annule pas la réussite du handshake.

### 7.5 Transférer et approuver uniquement le certificat public

Depuis PowerShell sur l'hôte Windows :

```powershell
scp -P 2223 'administrateur@127.0.0.1:C:/Gryphon/LDAPS/p6-dc01-ldaps.cer' "$env:USERPROFILE\"
scp -P 2222 "$env:USERPROFILE\p6-dc01-ldaps.cer" 'p5_client-01@127.0.0.1:/home/p5_client-01/gryphon-bloodhound/'
```

Sur Ubuntu, vérifier **l'empreinte attendue depuis le DC** avant de faire confiance :

```bash
cd ~/gryphon-bloodhound
openssl x509 -inform DER -in p6-dc01-ldaps.cer -noout -fingerprint -sha256 -subject
openssl x509 -inform DER -in p6-dc01-ldaps.cer -out p6-dc01-ldaps.crt
openssl s_client -connect p6-dc01.meridian.test:636 \
 -servername p6-dc01.meridian.test -CAfile ./p6-dc01-ldaps.crt \
 -verify_hostname p6-dc01.meridian.test -verify_return_error </dev/null
sudo cp p6-dc01-ldaps.crt /usr/local/share/ca-certificates/p6-dc01-ldaps.crt
sudo update-ca-certificates
```

Le fichier public `.cer`/`.crt` peut circuler ; **ne pas transférer la clé privée**. L'empreinte doit être comparée à celle affichée sur le DC. L'empreinte SHA-1 observée pendant notre réalisation : `CEA41A2EEC73BEDFFD1471B038BC837B0B9420ED` (propre à CE certificat et non réutilisable lors d'une reconstruction).

### 7.6 Collecter les objets AD

```bash
cd ~/gryphon-bloodhound && source .venv/bin/activate
bloodhound-ce-python -u a.dia -d meridian.test -ns 192.168.60.10 \
 -dc p6-dc01.meridian.test --auth-method kerberos --use-ldaps \
 -c DCOnly --zip -op gryphon
ls -lh *.zip
unzip -l gryphon_*_bloodhound.zip
```

La commande demande le mot de passe en saisie interactive. **Ne pas l'écrire sur la ligne de commande.**

**Résultats effectivement obtenus, 10/11/2026** : 9 utilisateurs, 59 groupes, 3 GPO, 7 OU, 19 conteneurs, 1 ordinateur, 1 domaine, 0 trust, 7 JSON, archive ZIP d'environ 165 Ko. Mode `DCOnly` = certaines données des endpoints/sessions sont absentes.

### 7.7 Graphe HTML léger sans Docker

```bash
python -m pip install networkx pyvis
python graph_meridian.py  # script fourni dans lab/scripts/graph_meridian.py
```

Pour faciliter la reproduction :

```bash
cp /chemin/vers/repo/lab/scripts/graph_meridian.py ~/gryphon-bloodhound/
cd ~/gryphon-bloodhound
python graph_meridian.py --zip "$(ls -1t gryphon_*_bloodhound.zip | head -1)" \
 --output meridian_ad_graph.html
```

Le HTML montre les **relations présentes dans les JSON**, sans inventer des droits supplémentaires. Ne pas confondre cette visualisation et le moteur officiel de recherche de chemins BloodHound CE.

### 7.8 Limitations BloodHound CE

L'application officielle n'a **pas** été déployée sur ce poste : disque hôte C: ~11 Go libres ; VM Ubuntu ~8,2 Go libres et 1,8 Gio RAM. L'analyse de chemins vers `DOMAIN ADMINS` avec le moteur officiel reste à réaliser sur un système adapté. Ne pas inventer de chemin d'élévation.

## 8. Installer et configurer Sysmon

### 8.1 Installation sur le contrôleur de domaine

Sysmon produit des journaux **Windows Event Log**. Il ne constitue pas à lui seul un SIEM.

```powershell
New-Item C:\Gryphon\Sysmon -ItemType Directory -Force | Out-Null
Invoke-WebRequest 'https://download.sysinternals.com/files/Sysmon.zip' -OutFile 'C:\Gryphon\Sysmon\Sysmon.zip'
Expand-Archive 'C:\Gryphon\Sysmon\Sysmon.zip' 'C:\Gryphon\Sysmon' -Force
Get-AuthenticodeSignature 'C:\Gryphon\Sysmon\Sysmon64.exe' | Select Status
& 'C:\Gryphon\Sysmon\Sysmon64.exe' -accepteula -i
Get-Service Sysmon64
```

Notre installation : Sysmon **15.22**, signature Microsoft valide. Sur cette installation Windows Server 2025 build 26100, la fonctionnalité Sysmon intégrée ne figurait pas dans DISM ; utilisation de Sysinternals.

### 8.2 Charger la configuration ciblée

Copier le fichier `detection/config/sysmon-gryphon.xml` sur le DC, puis :

```powershell
& 'C:\Gryphon\Sysmon\Sysmon64.exe' -c 'C:\Gryphon\Sysmon\sysmon-gryphon.xml'
& 'C:\Gryphon\Sysmon\Sysmon64.exe' -c
```

Journalisation : ID 1 processus, ID 3 connexions réseau PowerShell ciblées, ID 11 fichiers sous `C:\Gryphon\`, ID 22 requêtes DNS PowerShell. **Ne pas activer un flux massif sur un disque limité.**

### 8.3 Générer des traces bénignes

```powershell
cmd.exe /c 'echo GRYPHON_SYSMON_TEST > C:\Gryphon\Sysmon\test.txt'
Resolve-DnsName meridian.test -Server 192.168.60.10
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Sysmon/Operational'; Id=1,11,22; StartTime=(Get-Date).AddMinutes(-10)} | Select TimeCreated,Id | Format-Table
```

Tests observés : **IDs 1, 11 et 22**. Le processus et la création de fichier partagent un `ProcessGuid`, utile à la corrélation.

### 8.4 Export EVTX sans effacer le journal

```powershell
New-Item C:\Gryphon\Detection -ItemType Directory -Force | Out-Null
wevtutil epl 'Microsoft-Windows-Sysmon/Operational' 'C:\Gryphon\Detection\Sysmon-Gryphon.evtx'
Get-WinEvent -Path 'C:\Gryphon\Detection\Sysmon-Gryphon.evtx' -MaxEvents 5 | Select TimeCreated,Id
```

Fichier observé : **1 118 208 octets**, soit ~1,07 Mio. Le journal Security précédent : `C:\Gryphon\J3-J4\Security-J3-J4.evtx`, ~13,1 Mio.

### 8.5 Copier les EVTX du DC vers Ubuntu via l'hôte

```powershell
# Sur l'hôte Windows :
scp -P 2223 'administrateur@127.0.0.1:C:/Gryphon/Detection/Sysmon-Gryphon.evtx' "$env:USERPROFILE\"
scp -P 2222 "$env:USERPROFILE\Sysmon-Gryphon.evtx" 'p5_client-01@127.0.0.1:/home/p5_client-01/gryphon-bloodhound/'
scp -P 2223 'administrateur@127.0.0.1:C:/Gryphon/J3-J4/Security-J3-J4.evtx' "$env:USERPROFILE\"
scp -P 2222 "$env:USERPROFILE\Security-J3-J4.evtx" 'p5_client-01@127.0.0.1:/home/p5_client-01/gryphon-bloodhound/'
```

## 9. Chainsaw - rechercher et sauvegarder les résultats

### 9.1 Installation Linux x86_64

Téléchargement uniquement depuis les releases officielles de WithSecure :

```bash
mkdir -p ~/gryphon-tools/chainsaw && cd ~/gryphon-tools/chainsaw
sudo apt install -y jq
curl -sL https://api.github.com/repos/WithSecureOpenSource/chainsaw/releases/latest \
 | jq -r '.assets[] | select(.name=="chainsaw_x86_64-unknown-linux-gnu.tar.gz") | .browser_download_url' \
 | xargs -r curl -fL -o chainsaw-linux.tar.gz
tar -xzf chainsaw-linux.tar.gz
find . -type f -name chainsaw
chmod +x ./chainsaw/chainsaw
./chainsaw/chainsaw --help
```

### 9.2 Recherche Sysmon ID 1

```bash
cd ~/gryphon-tools/chainsaw
mkdir -p ~/gryphon-bloodhound/results
./chainsaw/chainsaw search -t 'Event.System.EventID: =1' -j \
 ~/gryphon-bloodhound/Sysmon-Gryphon.evtx \
 > ~/gryphon-bloodhound/results/processes-chainsaw.json
```

**Résultat observé** : **94 événements** de création de processus, JSON ~147 Ko. Ce nombre **n'est pas un nombre d'attaques**.

### 9.3 Recherches Security ciblées

```bash
for id in 4728 4729 5145; do
  ./chainsaw/chainsaw search -t "Event.System.EventID: =$id" -j \
   ~/gryphon-bloodhound/Security-J3-J4.evtx \
   > ~/gryphon-bloodhound/results/security-$id.json
done
```

Résultat sur **l'export réellement analysé** : ID 4728 = **9 hits** ; ID 4729 = **1 hit** ; ID 5145 = **0 hit**. Un 5145 d'accès Finance refusé avait été vu précédemment côté Windows, mais son absence dans la copie EVTX analysée est une limite documentaire à signaler.

### 9.4 Sigma

Les trois règles du dépôt visent 4728, 4729, 5145 (cette dernière est **spécifique au test** : compte `a.dia`, IP `192.168.60.20`, partage Finance, masque `0x81`). Elles ont été validées syntaxiquement avec Sigma CLI :

```bash
sigma check detection/sigma/
```

**Important** : `sigma check` ne prouve pas que les règles déclenchent des alertes dans un moteur. Pour une démonstration complète, adapter/tester leur backend sur des journaux effectivement présents.

## 10. Hayabusa - détection et chronologie CSV

### 10.1 Installation

Version utilisée dans notre expérience : **4.4.0** (Linux x86_64). Utiliser les releases officielles Yamato-Security.

```bash
mkdir -p ~/gryphon-tools/hayabusa && cd ~/gryphon-tools/hayabusa
curl -fL 'https://github.com/Yamato-Security/hayabusa/releases/download/v4.4.0/hayabusa-4.4.0-lin-x64-gnu.zip' -o hayabusa.zip
unzip hayabusa.zip
chmod +x hayabusa-4.4.0-lin-x64-gnu
./hayabusa-4.4.0-lin-x64-gnu --help
```

### 10.2 Analyser Sysmon et Security

```bash
cd ~/gryphon-tools/hayabusa
./hayabusa-4.4.0-lin-x64-gnu dfir-timeline \
 -f ~/gryphon-bloodhound/Sysmon-Gryphon.evtx -r ./rules \
 -o ~/gryphon-bloodhound/results/hayabusa-sysmon.csv -w
./hayabusa-4.4.0-lin-x64-gnu dfir-timeline \
 -f ~/gryphon-bloodhound/Security-J3-J4.evtx -r ./rules \
 -o ~/gryphon-bloodhound/results/hayabusa-security.csv -w
```

Sur Sysmon, une règle `File Created (Sysmon Alert)` a classé notre création volontaire de `test.txt` en **med**. Ce n'est pas la preuve d'une attaque. Sur Security, **1 248 lignes** au total, dont **27 lignes 4728**, **1 ligne 4729**, **0 ligne 5145**. Plusieurs règles Hayabusa peuvent correspondre à un même événement Windows.

### 10.3 Résumé rapide et corrélation

Le script `detection/scripts/summarize_hayabusa.py` lit un CSV et affiche les comptes par Event ID et les détections principales :

```bash
python3 /chemin/vers/repo/detection/scripts/summarize_hayabusa.py \
 ~/gryphon-bloodhound/results/hayabusa-security.csv
```

## 11. Interpréter les résultats - ce qui est prouvé / non prouvé

| Observation vérifiée | Conclusion raisonnable | Ne pas conclure |
|---|---|---|
| `a.dia` hors `GG_Finance` : accès refusé | Contrôle d'accès SMB vérifié à ce moment | Exploit de mouvement latéral |
| Ajout puis retrait d'`a.dia` par admin | Événements 4728/4729 produits | Escalade de privilège par attaquant |
| 5145 vu sur DC à un instant, puis absent EVTX | Conserver la preuve antérieure, signaler l'écart | Forcer une alerte 5145 inexistante |
| BloodHound.py collecte AD et zippe les JSON | Cartographie d'annuaire possible | Chemin réel vers Domain Admin |
| Sysmon ID 1,11,22 | Télémétrie fonctionnelle | Suspicion sans contexte |
| Hayabusa `File Created` sur test.txt | Règle déclenchée sur un test bénin | Compromission du serveur |

**MITRE ATT&CK** : T1098 (manipulation de comptes) est une correspondance possible pour la modification d'appartenance à un groupe ; T1135 décrit la découverte de partages si cette activité est effectivement établie. Le contexte volontaire de l'exercice prime sur l'étiquette technique. Ne pas inventer de TTP d'exfiltration.

## 12. Conserver les preuves sans publier les données sensibles

Structure conseillée :

```text
redteam-operation-gryphon/
  README.md
  docs/rapport/rapport-final.docx
  docs/procedure/PROCEDURE.md
  lab/scripts/*.ps1, graph_meridian.py
  detection/config/sysmon-gryphon.xml
  detection/sigma/*.yml
  detection/scripts/summarize_hayabusa.py
  preuves/README.md
```

Conserver hors Git : EVTX bruts, ZIP BloodHound, CSV contenant des identités, HTML de cartographie, clés privées/certificats et captures non anonymisées. Sauvegarder localement les versions de travail. Un dépôt privé réduit l'exposition mais ne remplace pas une gestion prudente des secrets.

## 13. Pannes fréquentes et solutions rapides

| Symptôme | Vérifier / corriger |
|---|---|
| VM ne démarre pas | Version VirtualBox, EFI, disque libre ; vérifier la compatibilité de l'hôte. |
| Ubuntu ne joint pas `192.168.60.10` | `P6-LAB` identique sur les deux cartes, `enp0s9` adressée, VM DC démarrée. |
| Ubuntu n'a plus Internet | `ip route`, gateway NAT vs route pfSense prioritaire ; ne pas supprimer la config Projet 5. |
| `p6-dc01.meridian.test` non résolu | `resolvectl dns enp0s9 192.168.60.10` et `~meridian.test`. |
| `KRB_AP_ERR_SKEW` | Comparer UTC, PDC et NTP ; synchroniser les horloges. |
| LDAP signing refuse la connexion | Utiliser Kerberos + LDAPS ; **ne pas désactiver la signature LDAP**. |
| LDAPS `errno=104` avant handshake | Certificat serveur, TLS, SAN, clé privée ; redémarrage DC si nécessaire. |
| Certificat self-signed non approuvé | Vérifier empreinte ; importer cert public dans magasin de confiance Ubuntu. |
| BloodHound CE officiel trop lourd | Utiliser la collecte Linux + graph HTML léger et documenter la limite. |
| `docker system df` = permission denied | `sudo docker system df`, sans toucher au socket. |
| Chainsaw `Is a directory` | Binaire réel `./chainsaw/chainsaw`. |
| Hayabusa CSV ≠ événements distincts | Une entrée EVTX peut faire déclencher plusieurs règles. |
| Événement 5145 introuvable | Comparer période, filtre, audit détaillé, et contenu brut de l'EVTX. |

## 14. Fin de session et rejouabilité

- Snapshot VM DC ; noter les versions et empreintes des archives utilisées.
- Sauvegarder le dossier de preuves **hors du dépôt Git** ; éviter de copier les mots de passe dans les notes.
- Vérifier les livrables : `Get-Service Sysmon64`, `unzip -l *.zip`, `ls -lh results/`, `sigma check`.
- Publier **seulement** scripts, procédures, règles relues et rapport expurgé.
- Pour rejouer en une journée, partir d'une VM Windows Server installée/snapshotée et d'un cache d'outils téléchargés ; les téléchargements/erreurs réseau sont les principales incertitudes.

## 15. Sources officielles / références de méthode

- Sujet fourni : `M1-06_PenTesting Approfondi.pdf`, Opération Gryphon, Mastère Cybersécurité.
- Microsoft AD DS : https://learn.microsoft.com/windows-server/identity/ad-ds/
- Microsoft Sysmon : https://learn.microsoft.com/sysinternals/downloads/sysmon
- Microsoft LDAPS : https://learn.microsoft.com/troubleshoot/windows-server/active-directory/enable-ldap-over-ssl-3rd-certification-authority
- SpecterOps BloodHound : https://bloodhound.specterops.io/
- BloodHound.py CE : https://github.com/dirkjanm/BloodHound.py
- WithSecure Chainsaw : https://github.com/WithSecureOpenSource/chainsaw
- Yamato-Security Hayabusa : https://github.com/Yamato-Security/hayabusa
- Sigma : https://sigmahq.io/ ; MITRE ATT&CK : https://attack.mitre.org/
