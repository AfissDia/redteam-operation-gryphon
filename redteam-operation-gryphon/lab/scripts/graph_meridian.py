#!/usr/bin/env python3
"""Visualisation légère des relations réellement présentes dans les JSON BloodHound CE.
Ne remplace pas l'interface officielle BloodHound CE.
"""
import argparse, json, zipfile
from pathlib import Path
import networkx as nx
from pyvis.network import Network

p=argparse.ArgumentParser()
p.add_argument('--zip',required=True, help='Archive ZIP produite par bloodhound-ce-python')
p.add_argument('--output',default='meridian_ad_graph.html')
a=p.parse_args()
colors={'User':'#4DA3FF','Group':'#F59E0B','Computer':'#EF4444','OU':'#A78BFA','GPO':'#34D399','Domain':'#F472B6','Container':'#94A3B8'}
kindmap={'users':'User','groups':'Group','computers':'Computer','ous':'OU','gpos':'GPO','domains':'Domain','containers':'Container'}
objects={}
with zipfile.ZipFile(a.zip) as z:
 for filename in z.namelist():
  if not filename.endswith('.json'): continue
  kind=kindmap.get(filename.rsplit('_',1)[-1].replace('.json',''),'Other')
  data=json.loads(z.read(filename))
  for obj in data.get('data',[]):
   oid=obj.get('ObjectIdentifier')
   if oid: objects[oid]={'kind':kind,'data':obj,'name':str((obj.get('Properties') or {}).get('name',oid))}
G=nx.DiGraph()
def edge(source,target,relation):
 if source and target and source in objects and target in objects:
  G.add_edge(source,target,relation=relation)
for oid,item in objects.items():
 obj=item['data']; kind=item['kind']
 if kind=='Group':
  for m in obj.get('Members',[]): edge(m.get('ObjectIdentifier'),oid,'MemberOf')
 if kind in ('OU','Domain','Container'):
  for child in obj.get('ChildObjects',[]): edge(oid,child.get('ObjectIdentifier'),'Contains')
 if kind in ('OU','Domain'):
  for link in obj.get('Links',[]) + obj.get('GPLinks',[]):
   edge(oid,link.get('GUID') or link.get('ObjectIdentifier'),'GPLink')
net=Network(height='850px',width='100%',bgcolor='#0B1220',font_color='white',directed=True,cdn_resources='in_line')
net.barnes_hut(gravity=-5000,central_gravity=0.2,spring_length=170,spring_strength=0.025)
for oid in G.nodes:
 item=objects[oid]; name=item['name']; kind=item['kind']; label=name.split('@')[0][:30]
 net.add_node(oid,label=label,title=f'{kind} : {name}',color=colors.get(kind,'#FFFFFF'),size=20 if kind in ('Domain','Group') else 14)
for source,target,attr in G.edges(data=True):
 net.add_edge(source,target,title=attr['relation'],color='#64748B',arrows='to')
net.write_html(a.output)
print(f'Graphe : {a.output}; objets relies : {G.number_of_nodes()}; relations : {G.number_of_edges()}')
