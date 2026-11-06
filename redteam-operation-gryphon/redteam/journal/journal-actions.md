# Journal technique — Opération Gryphon

> Les horaires précis et les noms de responsables sont à compléter à partir des traces locales. Les opérations ci-dessous relèvent de la préparation, non d'une intrusion effective.

| Date | Phase | Action | Résultat / observation |
|---|---|---|---|
| 04/11/2026 | Préparation | Mise à jour VirtualBox 7.0.0 → 7.2.22 | Démarrage Server 2025 débloqué |
| 04/11/2026 | Infrastructure | Installation Windows Server 2025 Core | VM opérationnelle |
| 04/11/2026 | Infrastructure | Installation AD DS, promotion forêt et DNS | `meridian.test` opérationnel |
| 05/11/2026 | Réseau | IP interne statique 192.168.60.10 et correction DNS | A et SRV LDAP validés |
| 05/11/2026 | AD | Création de six OU, comptes et groupes | Inventaire réalisé |
| 05–06/11/2026 | Accès | Dossiers, SMB et correction ACL NTFS | Contrôles appliqués |
| 06/11/2026 | Test | Compte `a.dia` → fichier Finance | Lecture refusée |
| 06/11/2026 | Test | Compte `a.dupont` → fichier Finance | Lecture réussie |

## Gabarit d'action Red Team (à remplir en temps réel)

- **Horodatage avec fuseau :**
- **Auteur et identité utilisée :**
- **Cible dans le lab :**
- **Objectif :**
- **Commande / outil / version :**
- **Technique MITRE ATT&CK :**
- **Résultat et impacts :**
- **Artefacts / Event IDs :**
- **Preuve (nom fichier expurgé) :**
- **Hypothèse de détection :**
- **Mesure de mitigation :**
