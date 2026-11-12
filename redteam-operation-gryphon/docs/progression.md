# Progression - état au 12 novembre 2026

- J1 : Windows Server 2025 / VirtualBox / AD DS / DNS installés et vérifiés.
- J2 : OU, comptes fictifs, groupes et partages SMB fonctionnels.
- J3/J4 : tests d'accès, ajout/retrait de membre du groupe Finance par l'administrateur, audit Security, règles Sigma.
- GPO : configuration utilisateur de verrouillage après 600 s créée et liée à OU IT ; application client non démontrée.
- Reconnaissance : BloodHound.py CE en Kerberos/LDAPS ; 7 JSON et ZIP ; cartographie PyVis.
- Blue Team : Sysmon 15.22 ; Chainsaw et Hayabusa sur EVTX hors ligne.
- Limites : pas de latéral/exfiltration réels ; interface officielle BloodHound CE non installée ; 5145 absent de la copie EVTX de fin de projet.
- Rendu : rapport final Word, procédure .md et scripts reproductibles disponibles.
