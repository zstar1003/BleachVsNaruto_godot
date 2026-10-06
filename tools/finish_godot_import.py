"""Collect nested idle frames and timeline audio with original sample offsets."""
import json,pathlib,xml.etree.ElementTree as E
from import_godot_assets import ROOT
for c,cid in [('ichigo',632),('naruto',662)]:
 p=ROOT/'godot/assets'/c/'fighter.json';d=json.loads(p.read_text());d['idle']=json.loads((p.parent/'idle/frames.json').read_text());r=E.parse(ROOT/('research/'+c+'.xml')).getroot();d['sounds']={}
 sp=next(t for t in r.find('tags') if t.get('spriteId')==str(cid));frame=1
 for t in sp.find('subTags'):
  if t.get('type')=='ShowFrameTag':frame+=1
  if t.get('type')=='StartSoundTag':
   sound=t.get('soundId');path=next((f for f in p.parent.glob('*.mp3') if f.stem==sound or f.stem.startswith(sound+'_')),None)
   if path:
    info=t.find('soundInfo');d['sounds'].setdefault(str(frame),[]).append({'file':path.name,'start':int(info.get('inPoint','0'))/44100,'stop':info.get('syncStop')=='true','end':int(info.get('outPoint','0'))/44100})
 d['portraits']={}
 for key,pattern in [('face1','*bsface1*png'),('face2','*bsface2*png')]:
  file=next((p.parent/'portraits').rglob(pattern),None)
  if file:d['portraits'][key]=str(file.relative_to(p.parent))
 p.write_text(json.dumps(d,ensure_ascii=False,separators=(',',':')))
 print(c,len(d['sounds']),'timeline audio cues',d['portraits'])
