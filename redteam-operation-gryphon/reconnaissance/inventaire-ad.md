# Inventaire AD — Synthèse

Inventaire issu des commandes `Get-ADUser`, `Get-ADGroup` et `Get-ADComputer` exécutées dans le lab. Les CSV bruts restent **hors Git**.

## Comptes employés fictifs

| Compte | Service / groupe métier |
|---|---|
| s.martin | Direction — GG_Direction |
| a.dupont | Finance — GG_Finance |
| t.bernard | IT — GG_IT |
| j.petit | Utilisateurs — GG_Employes |
| a.dia | IT — GG_IT |

Autres comptes natifs observés : Administrateur, Invité, krbtgt.

## Ordinateur

`P6-DC01.meridian.test` — contrôleur de domaine unique actuellement présent.

## Exports générés dans la VM

- `C:\Gryphon\Recon\users.csv`
- `C:\Gryphon\Recon\groups.csv`
- `C:\Gryphon\Recon\computers.csv`

Ces exports ne sont pas copiés dans le dépôt. Reproduire au besoin avec `lab/configuration/verification-readonly.ps1`.

## BloodHound — Préparation

- Collecte limitée au domaine de laboratoire autorisé.
- Documenter la version de BloodHound / collecteur, la commande de collecte et l'horodatage.
- Conserver les archives brutes dans `reconnaissance/raw/` (ignoré par Git).
- Publier seulement captures expurgées et résultats analysés.
