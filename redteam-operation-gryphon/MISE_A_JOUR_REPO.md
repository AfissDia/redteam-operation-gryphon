# Mise à jour du dépôt Git local - Opération Gryphon

Ce paquet a été préparé à partir de l'archive du dépôt existant `redteam-operation-gryphon`. Il **ne contient pas le dossier `.git`** et **n'a pas encore été poussé sur GitHub**. Le dépôt distant n'a pas été modifié.

## 1. Avant de remplacer les fichiers

Depuis **PowerShell sur Windows**, définir les chemins et contrôler les changements déjà présents :

```powershell
$repo = 'C:\Users\DELL\OneDrive\Bureau\TPs\t6\redteam-operation-gryphon'
Set-Location $repo
git status --short
git remote -v
```

Si `git status` indique des changements locaux, les sauvegarder ou les committer d'abord : les fichiers du paquet peuvent remplacer certains documents existants.

## 2. Décompresser et comparer avant de copier

Télécharger l'archive `Gryphon_Repo_MAJ_2026-11-12.zip`, puis adapter le chemin du ZIP si nécessaire :

```powershell
$zip = "$env:USERPROFILE\Downloads\Gryphon_Repo_MAJ_2026-11-12.zip"
$stage = "$env:TEMP\gryphon-maj"
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Expand-Archive -Path $zip -DestinationPath $stage -Force
$src = Join-Path $stage 'redteam-operation-gryphon'
robocopy $src $repo /E /L
```

`/L` **simule** la copie sans changer aucun fichier. Regarder les chemins et s'assurer que la source est bien `redteam-operation-gryphon`.

## 3. Appliquer la copie

Si la liste est cohérente :

```powershell
robocopy $src $repo /E
git -C $repo status --short
git -C $repo diff --stat
```

Robocopy peut renvoyer un code non nul même en cas de succès. Vérifier les messages et la présence des fichiers. La copie n'efface pas les fichiers supplémentaires de l'ancien dépôt (`/E`, sans `/MIR`).

## 4. Contrôler les données sensibles et pousser

```powershell
Set-Location $repo
Get-ChildItem docs\rapport,docs\procedure

git status --short
git add README.md MISE_A_JOUR_REPO.md docs detection lab reconnaissance redteam preuves .gitignore

git diff --cached --name-only
git diff --cached --check
```

Vérifier qu'aucun fichier `.evtx`, `.zip` de BloodHound, `.cer`, `.crt`, `*.csv`, `*.json` de collecte, `*.html` de cartographie ni mot de passe n'a été ajouté. Le ZIP de livraison, lui, n'est pas à committer.

```powershell
git commit -m "docs: finaliser Operation Gryphon et guide de reproduction"
git push
```

Ne lancer `git push` que lorsque le bon `remote` et la branche attendue sont confirmés. Le dépôt doit rester **privé**.

## Contenu principal

- `docs/rapport/Rapport_final_Operation_Gryphon.docx` - rapport complet.
- `docs/procedure/PROCEDURE.md` - parcours de reproduction et dépannage.
- `lab/scripts/` - scripts d'AD, partages et graphe.
- `detection/config/sysmon-gryphon.xml` - politique Sysmon.
- `detection/sigma/` - règles Sigma de laboratoire.
- `detection/scripts/summarize_hayabusa.py` - résumé CSV.
- `docs/progression.md` et `README.md` - synthèses.

Les scripts sont des **modèles** à relire et à exécuter uniquement dans un laboratoire autorisé. Les chiffres présentés dans les rapports sont ceux de la session documentée, pas des résultats garantis lors d'une nouvelle exécution.
