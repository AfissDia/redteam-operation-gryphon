# Note de cadrage — J1

## Contexte et mission

Meridian Bank est une banque fictive de 1 200 salariés. Une équipe Red Team pédagogique doit éprouver la résistance d'un environnement Active Directory conçu et construit par elle-même, puis analyser les traces de la simulation du point de vue du défenseur.

## Périmètre et objectifs

**Inclus :** un domaine `meridian.test`, contrôleur `P6-DC01`, DNS, utilisateurs fictifs, OU, groupes, partage de documents fictifs, cartographie AD, tests d'intrusion autorisés et analyse défensive différée.

**Exclus :** tout système tiers, toute donnée réelle, toute action destructive, tout cloud ou serveur extérieur.

**Critères de succès :** environnement AD fonctionnel, chaîne d'attaque reproductible et horodatée, techniques MITRE ATT&CK annotées, preuves de détection, mesures de mitigation et rapport final.

## Palier technique et limites

Socle minimal du sujet : Windows Server 2025 Datacenter Evaluation en mode Core, AD DS, DNS et partages cibles sur une seule VM. Hôte Windows avec 16 Go de RAM ; stockage hôte limité. La VM dispose de deux cartes : NAT pour SSH et réseau interne isolé pour AD. La couche client de domaine, Kali ou EDR n'est pas déployée à ce stade.

## Répartition de l'équipe

Équipe de **2 à 3 personnes**, à compléter avant remise au formateur :

| Membre | Rôle | Responsabilités |
|---|---|---|
| À renseigner | Infrastructure | Lab, AD, DNS, sauvegardes |
| À renseigner | Red Team | Cartographie, scénario, journal |
| À renseigner (si 3) | Défense et rapport | Événements, Sigma, restitution |

## Planning (5 jours / 35 h)

| Jour | Objectif / jalon |
|---|---|
| J1 | Cadrage, VM, AD DS, DNS et note de cadrage |
| J2 | OU, groupes, comptes, partages, contrôle d'accès et cartographie |
| J3 | Simulation de chaîne d'attaque, collecte horodatée |
| J4 | Forensic, ATT&CK, Sigma et recommandations SOC |
| J5 | Rapport 30–50 pages et restitution |

## Risques et mesures

- **Manque de stockage :** limiter le nombre de VM, vérifier l'espace avant captures/snapshots.
- **Démarrage VM :** documenter versions et réglages ; sauvegarder la configuration.
- **DNS multi-cartes :** publier la seule IP interne pour la découverte AD et vérifier après redémarrage.
- **ACL incohérentes :** préserver Administrateurs/SYSTEM, vérifier les ACL et tester avec des identités distinctes.
- **Traçabilité incomplète :** journaliser date/heure, compte, outil, commande, résultat, événements et ATT&CK.

## Livrables attendus

Note de cadrage (2 pages au rendu final), rapport narratif 30–50 pages, matrice ATT&CK annotée, recommandations de détection et IOC, journal Red Team horodaté, note de montage du lab et analyse défensive différée.

> Cette note est un brouillon structuré. Les noms des membres, leurs rôles et les dates exactes de rendu doivent être complétés.
