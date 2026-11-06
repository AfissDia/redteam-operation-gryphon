# Red Team — Opération Gryphon

**Projet pédagogique — Mastère Cybersécurité, La Plateforme_**  
**Client fictif :** Meridian Bank (1 200 collaborateurs)  
**Statut :** laboratoire AD opérationnel ; tests SMB initiaux réalisés ; cartographie BloodHound à venir.

## Objectif

Monter un laboratoire Active Directory local, y simuler une intrusion autorisée, puis relier chaque action aux traces produites, aux techniques MITRE ATT&CK et aux mesures de détection. Les actions destructives et les cibles extérieures au laboratoire sont exclues.

## Laboratoire

| Composant | Configuration observée / retenue |
|---|---|
| Virtualisation | VirtualBox 7.2.22, hôte Windows |
| VM | `P6-DC01`, Windows Server 2025 Datacenter Evaluation (Core) |
| Domaine | `meridian.test` (NetBIOS `MERIDIAN`) |
| Carte NAT (administration) | `10.0.2.15/24`, SSH redirigé depuis l'hôte sur `127.0.0.1:2223` |
| Carte interne `P6-LAB` | `192.168.60.10/24`, sans passerelle |
| Rôles | AD DS, DNS, partages SMB |
| OU métier | Direction, Finance, IT, Utilisateurs, Serveurs, Groupes |
| Groupes métier | GG_Direction, GG_Finance, GG_IT, GG_Employes |

## Travaux validés

- Déploiement de Server Core et résolution du blocage de démarrage via mise à jour VirtualBox 7.0.0 → 7.2.22.
- Promotion du serveur en contrôleur de domaine ; services NTDS, DNS, Netlogon actifs.
- Résolution DNS de `meridian.test` sur `192.168.60.10` et enregistrement SRV LDAP vérifié.
- Création de 6 OU, 5 comptes employés fictifs et 4 groupes métier.
- Création de trois partages SMB (`Commun`, `Finance`, `Direction`) et correction de leurs ACL NTFS.
- Tests initiaux : lecture Finance refusée avec les identifiants de `a.dia`, réussie avec `a.dupont` ; audit indépendant de l'identité SMB à compléter.
- Inventaire AD exporté (utilisateurs, groupes et ordinateur du lab).

## Prochaines étapes

1. Vérifier l'isolation des accès SMB sous sessions utilisateurs non privilégiées et capturer les événements associés.
2. Cartographier AD avec BloodHound / SharpHound en gardant les exports bruts hors du dépôt.
3. Préparer des scénarios Red Team limités au laboratoire, journaliser chaque action horodatée.
4. Analyser les traces Windows et rédiger les règles Sigma et les recommandations.
5. Finaliser le rapport narratif (30–50 pages) et la restitution.

## Organisation

- [`docs/cadrage/note-cadrage.md`](docs/cadrage/note-cadrage.md) — périmètre, risques, planning.
- [`docs/architecture/infrastructure.md`](docs/architecture/infrastructure.md) — architecture AD et réseau.
- [`docs/progression.md`](docs/progression.md) — état de J1 à J5.
- [`reconnaissance/inventaire-ad.md`](reconnaissance/inventaire-ad.md) — inventaire synthétique.
- [`lab/configuration/verification-readonly.ps1`](lab/configuration/verification-readonly.ps1) — contrôles en lecture seule.
- [`redteam/journal/journal-actions.md`](redteam/journal/journal-actions.md) — modèle de traçabilité.
- [`detection/README.md`](detection/README.md) — plan de preuves et de détection.

## Confidentialité et limites

Le dépôt GitHub doit rester **privé**, conformément au sujet. Aucun mot de passe, secret, capture sensible, dump d'identifiants ou export brut de l'annuaire ne doit être publié. Le `.gitignore` exclut ces catégories par défaut. Cette documentation décrit un laboratoire pédagogique, pas un audit d'une vraie banque.

## Licence

Voir [`LICENSE.md`](LICENSE.md). Mention restrictive provisoire à valider avec les membres de l'équipe et l'établissement ; elle ne constitue pas une licence open source.
