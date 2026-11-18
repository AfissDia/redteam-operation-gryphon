
# Opération Gryphon - Active Directory, contrôle d'accès et investigation

**Projet 6 - Mastère Cybersécurité, La Plateforme_**  
**Client fictif :** Meridian Bank - laboratoire local `meridian.test`  
**État au 12 novembre 2026 :** expérimentation principale achevée, limites documentées, rapport et procédure mis à jour.

## Résumé du projet

Déploiement d'un domaine Active Directory sous Windows Server 2025 Server Core et simulation autorisée de contrôles d'accès. Cartographie AD avec BloodHound.py CE, audit Windows/Sysmon et analyse de journaux avec Chainsaw, Sigma et Hayabusa.

## Résultats principaux

| Axe | Résultat vérifié |
|---|---|
| Infrastructure | `P6-DC01`, forêt et domaine `meridian.test`, DNS AD |
| Organisation | 6 OU métier, 5 comptes fictifs, 4 groupes métier |
| Partages | Commun, Finance, Direction ; test d'accès Finance refusé hors groupe |
| GPO | `GPO_Meridian_Securite` liée à OU IT, verrouillage après 600 s configuré |
| BloodHound.py CE | 9 utilisateurs, 59 groupes, 3 GPO, 7 OU, 19 conteneurs, 1 ordinateur |
| Cartographie | HTML interactif Python/NetworkX/PyVis produit à partir de 7 JSON |
| Sysmon | Version 15.22, événements 1/11/22 validés, EVTX exporté |
| Chainsaw | 94 processus ID 1 ; Security : 9 × 4728, 1 × 4729, 0 × 5145 |
| Hayabusa | CSV Security 1 248 lignes ; 27 détections 4728, 1 détection 4729, 0 détection 5145 |

Les lignes Hayabusa ne sont pas nécessairement des événements uniques. Les actions de groupe ont été réalisées volontairement par un administrateur du lab : **aucune compromission du domaine n'est démontrée**.

## Lire / reproduire

- [Guide de reproduction](docs/procedure/PROCEDURE.md) - commandes, scripts, définitions, tests, dépannage, parcours d'une journée.
- [Rapport final](docs/rapport/Rapport_final_Operation_Gryphon.docx) - analyse, résultats, limites, recommandations.
- [Script AD](lab/scripts/01-bootstrap-ad.ps1) et [partages](lab/scripts/02-partages.ps1) - exemples de lab à relire avant usage.
- [Configuration Sysmon](detection/config/sysmon-gryphon.xml) - journalisation ciblée.
- [Cartographie HTML](lab/scripts/graph_meridian.py) - générateur local, sans moteur officiel CE.
- [Règles Sigma](detection/sigma/) et [résumé Hayabusa](detection/scripts/summarize_hayabusa.py).
- [Architecture](docs/architecture/infrastructure.md) et [cadrage](docs/cadrage/note-cadrage.md).

## Périmètre et limites

- Une seule machine Windows Server DC et une VM Ubuntu ; pas de client Windows membre distinct.
- Pas de chemin BloodHound CE officiel validé (stockage/mémoire insuffisants pour l'interface).
- Pas de mouvement latéral ni d'exfiltration effectivement démontrés ; ne pas confondre administration volontaire et exploitation.
- Un ID 5145 a été observé initialement dans le journal Windows, mais n'a pas été retrouvé dans l'EVTX exporté lors de l'analyse finale.
- Configuration GPO vérifiée au niveau AD ; application sur un poste Windows non testée.

## Sécurité documentaire

Dépôt **privé**. Ne pas committer les EVTX bruts, archives BloodHound, graphe réel, certificats, mots de passe, identités réelles ni dumps. Les rapports/captures sont à expurger selon le contexte.

## Licence

Voir `LICENSE.md`. Les binaires, scripts et règles tiers restent sous leurs licences respectives.
