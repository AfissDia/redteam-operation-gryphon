#!/usr/bin/env python3
"""Résumé d'une chronologie Hayabusa au format CSV (sans dépendance)."""
import csv, sys
from collections import Counter
from pathlib import Path
if len(sys.argv) != 2:
    print('Usage: python summarize_hayabusa.py chemin/chronologie.csv')
    sys.exit(2)
path=Path(sys.argv[1])
with path.open(encoding='utf-8-sig', newline='') as f:
    rows=list(csv.DictReader(f))
counts=Counter(str(r.get('EventID','')) for r in rows)
rules=Counter(str(r.get('RuleTitle','')) for r in rows)
print('Fichier :', path.name)
print('Lignes de détection :',len(rows))
for eid in ('1','11','22','4728','4729','5145'):
    print(f'Event ID {eid}: {counts[eid]} lignes')
print('Principales règles :')
for name,n in rules.most_common(8): print(f'  {n:5d}  {name}')
print('Note : plusieurs règles peuvent détecter un même enregistrement EVTX.')
