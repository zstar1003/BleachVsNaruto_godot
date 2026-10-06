"""Retain the original FighterAILogic decisions as a closed interpreted AST."""
import re,json
from import_full_roster import dump,Document,OUT
from import_godot_assets import ROOT,balanced,transform
from as3_timeline import parse
base=ROOT/'research/OpenBleachVsNaruto/swf_source/#FighterTester/src/net/play5d/game/obvn'
source=(base/'fighter/ctrler/ai/FighterAILogic.as').read_text();methods={};params={}
for m in re.finditer(r'(?:public|private|protected)\s+function\s+(\w+)\(([^)]*)\)\s*:\s*\w+\s*\{',source):
 raw,_=balanced(source,m.end()-1)
 body=raw[1:-1]
 body=re.sub(r'for each\(var (\w+):([\w.<*>]+) in ([^)]+)\)',r'var \1:\2;for each(\1 in \3)',body)
 methods[m[1]]=parse(body);params[m[1]]=[v.strip().split(':')[0] for v in m[2].split(',') if v.strip()]
constants={m[1]:int(m[2]) for m in re.finditer(r'const\s+(\w+)\s*:\s*int\s*=\s*(\d+)',(base/'fighter/data/FighterActionState.as').read_text())}
defaults={m[1]:float(m[2]) for m in re.finditer(r'(?:public|private|protected)\s+var\s+(\w+)\s*:\s*\w+\s*=\s*([\d.]+)',source)}
for m in re.finditer(r'public\s+var\s+(\w+)\s*:\s*Boolean',source):defaults[m[1]]=False
dump(OUT/'ai.json',{'methods':methods,'method_parameters':params,'script_defaults':defaults,'constants':constants,'source':'FighterAILogic.as'})
for p in (OUT/'fighter').glob('*.json'):
 d=json.loads(p.read_text());doc=Document('fighter',__import__('pathlib').Path(d['source']).stem);fs,_=doc.frames(d['sprite']);ai=next((s for f in fs for s in f.values() if s['name']=='AImain'),None);ranges={}
 if ai:
  afr,_=doc.frames(ai['id'])
  for s in afr[min(1,len(afr)-1)].values():
   if s['name'] and 'id' in s:ranges[s['name']]=transform(transform(doc.bounds(s['id']),s['matrix']),ai['matrix'])
 d['ai_ranges']=ranges;dump(p,d)
print('Retained',len(methods),'original AI decision functions and 58 fighter range definitions')
