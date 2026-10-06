"""Complete runtime metadata and repair source audio after the full SWF export."""
import json,re,pathlib,sys,subprocess,shutil,xml.etree.ElementTree as E
from import_full_roster import Document,dump,command,OUT
from import_godot_assets import ROOT,JAVA,balanced
from as3_timeline import parse,Parser

def metadata(source):
 methods={};defaults={}
 for m in re.finditer(r'(?:public|private|internal|protected)\s+function\s+(\w+)\([^)]*\)\s*(?::\s*[^\s{]+)?\s*\{',source):
  if m[1].startswith('frame') or m[1] in ['MainTimeline','setAssistCtrler','defineActions','setAttackerCtrler']:continue
  raw,_=balanced(source,m.end()-1)
  try:methods[m[1]]=parse(raw[1:-1])
  except Exception as e:
   if 'addFrameScript' not in raw:raise ValueError(m[1]+': '+str(e))
 for m in re.finditer(r'(?:public|private|internal|protected)\s+(?:var|const)\s+(\w+)\s*:\s*[^=;]+\s*=\s*([^;]+);',source):
  try:
   ast=Parser(m[2]).expr()
   if ast[0]=='lit':defaults[m[1]]=ast[1]
   elif ast[0]=='array' and all(x[0]=='lit' for x in ast[1]):defaults[m[1]]=[x[1] for x in ast[1]]
  except Exception:pass
 return methods,defaults

def parameters(source):
 return {m[1]:[p.split(':')[0].strip() for p in m[2].split(',') if p.strip()] for m in re.finditer(r'function\s+(\w+)\(([^)]*)\)',source)}

docs={}
for kind in ['fighter','assist']:
 for p in (OUT/kind).glob('*.json'):
  d=json.loads(p.read_text());name=pathlib.Path(d['source']).stem
  doc=docs.setdefault((kind,name),Document(kind,name))
  source=doc.scripts.get(d['sprite'],doc.scripts.get('0',''))
  d['methods'],d['script_defaults']=metadata(source)
  d['method_parameters']=parameters(source)
  if kind=='assist' and name=='byakuya':
   cid=next(k for k,v in doc.classes.items() if v=='atmmc');dest=OUT/kind/name/cid
   if not (dest/'frames.json').exists():
    req=doc.work/'dynamic-requests.tsv';req.write_text(f'{cid}\t{dest}')
    with (doc.work/'dynamic-render.log').open('w') as log:command([JAVA,'-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwfBatch',doc.work/'full-visual.swf',req],log)
   fs,labels=doc.frames(cid)
   d['spawns']['atmmc']={'id':cid,'position':[0,0],'matrix':[1,0,0,1,0,0],'labels':labels,'program':doc.ast(cid),'frames':json.loads((dest/'frames.json').read_text()),'asset_base':str(dest.relative_to(OUT))+'/','events':{}}
  for spawn in d['spawns'].values():
   sid=spawn['id'];coll=doc.collision(sid,True)
   spawn['checks']=[c['checks'] for c in coll]
   spawn['collisions']=[c['hits'] for c in coll]
   # Anonymous 'main' hitboxes use the sole action of dynamic attackers.
   for c in spawn['collisions']:
    for hit in c:
     if not hit['id'] and len(d['actions'])==1:hit['id']=next(iter(d['actions']))
   spawn['methods'],spawn['script_defaults']=metadata(doc.scripts.get(sid,''))
   spawn['method_parameters']=parameters(doc.scripts.get(sid,''))
   spawn['sounds']=doc.sounds(sid,OUT/'audio'/kind/name)
  for sounds in [d['sounds']]+[s['sounds'] for s in d['spawns'].values()]:
   for events in sounds.values():
    for e in events:
     audio=OUT/e['file']
     if audio.suffix=='.mp3' and audio.exists():
      result=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0',str(audio)],capture_output=True)
      if result.returncode:
       repaired=audio.with_suffix('.wav')
       if not repaired.exists():subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(audio),str(repaired)],check=True)
       e['file']=str(repaired.relative_to(OUT))
       backup=ROOT/'research/full-port/invalid-audio'/kind/name/audio.name;backup.parent.mkdir(parents=True,exist_ok=True);shutil.move(audio,backup)
     elif audio.suffix=='.mp3' and audio.with_suffix('.wav').exists():e['file']=str(audio.with_suffix('.wav').relative_to(OUT))
  dump(p,d)
# Keep the original embedded move list and all original background music.
move=ROOT/'godot/assets/ui/movelist';move.mkdir(parents=True,exist_ok=True)
if not (move/'movelist.jpg').exists():
 with (ROOT/'research/movelist-export.log').open('w') as log:command([JAVA,'-Djava.awt.headless=true','-jar',ROOT/'research/tools/ffdec/ffdec.jar','-selectid','17','-export','image',move,ROOT/'research/release/swf_output/FighterTester.swf'],log)
 shutil.move(next(move.glob('17_*.jpg')),move/'movelist.jpg')
for src in (ROOT/'research/release/swf_output/assets/bgm').glob('*.mp3'):
 target=ROOT/'godot/assets/audio/bgm'/src.name;target.parent.mkdir(exist_ok=True,parents=True);shutil.copy2(src,target)
print('Completed methods, defaults, attacker hit checks, audio and original move list')

base=ROOT/'research/OpenBleachVsNaruto/swf_source/#FighterTester/src/net/play5d/game/obvn'
src=(base/'ui/SetBtnGroup.as').read_text();start=src.index('settingMenu = [')+len('settingMenu = ')
parser=Parser(src[start:]);ast=parser.expr()
def literal(n):
 if n[0]=='lit':return n[1]
 if n[0]=='array':return [literal(x) for x in n[1]]
 if n[0]=='object':return {k:literal(v) for k,v in n[1]}
 if n[0]=='un' and n[1]=='-':return -literal(n[2])
 raise ValueError(n)
dump(ROOT/'godot/assets/ui/settings.json',literal(ast))
missions=[{'comic_type':int(e.get('comicType')),'mode':int(e.get('gameMode')),'stages':[s.attrib for s in e]} for e in E.parse(ROOT/'research/release/swf_output/assets/config/mission.xml').getroot()]
dump(OUT/'missions.json',missions)
