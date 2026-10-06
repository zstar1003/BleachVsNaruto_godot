"""Export the shared original combat effects and their 3.4 effect definitions."""
import re,json,pathlib
from import_full_roster import Document,dump,command,OUT
from import_godot_assets import ROOT,SOURCE,JAVA,balanced
from as3_timeline import Parser
DOC=Document('shared','effect');dest=OUT/'effects';request=DOC.work/'effect-requests.tsv'
symbols={};requests=[]
for cid,cls in DOC.classes.items():
 frames,labels=DOC.frames(cid)
 if not frames:continue
 symbols[cls]={'id':cid,'labels':labels,'asset_base':'effects/'+cid+'/'};requests.append(f'{cid}\t{dest/cid}')
 if cls=='bisha_face_mc':symbols[cls]['faces']=[{s['name']:s['matrix'] for s in f.values() if s['name'].startswith('facemc')} for f in frames]
request.write_text('\n'.join(requests));source=SOURCE/'effect.swf'
with (DOC.work/'effects-render.log').open('w') as log:
 if not all((dest/v['id']/'frames.json').exists() for v in symbols.values()):command([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwfBatch',source,request],log)
 audio=dest/'audio'
 if not audio.exists():command([JAVA,'-Djava.awt.headless=true','-jar',ROOT/'research/tools/ffdec/ffdec.jar','-export','sound',audio,source],log)
for value in symbols.values():value['frames']=json.loads((dest/value['id']/'frames.json').read_text())
sounds={}
for cid,cls in DOC.classes.items():
 if cls.startswith('snd_'):
  f=next((p for p in audio.glob('*') if p.stem==cid or p.stem.startswith(cid+'_')),None)
  if f:sounds[cls]=str(f.relative_to(OUT))
base=ROOT/'research/OpenBleachVsNaruto/swf_source/#FighterTester/src/net/play5d/game/obvn'
text=(base/'model/EffectModel.as').read_text();hit_types={m[1]:int(m[2]) for m in re.finditer(r'const\s+(\w+)\s*:\s*int\s*=\s*(\d+)',(base/'data/HitType.as').read_text())}
def value(n):
 if n[0]=='lit':return n[1]
 if n[0]=='get':return n[2].lower() if n[1]==['var','BlendMode'] else n[2]
 if n[0]=='array':return [value(v) for v in n[1]]
 if n[0]=='object':return {k:value(v) for k,v in n[1]}
 if n[0]=='un' and n[1]=='-':return -value(n[2])
 return None
models={}
pattern=r'(?:_effect\["([^"]+)"\]\s*=\s*new EffectVO\(|add(Hit|Defense)Effect\(HitType\.(\w+),\s*)"([^"]+)"'
for m in re.finditer(pattern,text):
 key=m[1] if m[1] else ('hit_' if m[2]=='Hit' else 'defense_')+str(hit_types[m[3]])
 tail=text[m.end():];params={}
 if re.match(r',\s*\{',tail):
  start=m.end()+tail.index('{');raw,_=balanced(text,start);params=value(Parser(raw).expr())
 models[key]={'symbol':m[4],**params}
dump(dest/'library.json',{'symbols':symbols,'models':models,'sounds':sounds})
print('Imported',len(symbols),'original shared effects,',len(models),'definitions,',len(sounds),'sounds')
