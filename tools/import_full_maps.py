"""Import original stage layers, spawn points, boundaries and platform rectangles."""
import json,xml.etree.ElementTree as E,pathlib
from import_full_roster import Document,dump,command,CACHE
from import_godot_assets import ROOT,SOURCE,JAVA,FF,timeline,transform
out=ROOT/'godot/assets/maps';out.mkdir(exist_ok=True)
for t in E.parse(SOURCE/'config/map.xml').getroot():
 if t.find('file') is None:continue
 name=t.get('id');doc=Document('map',name);fs,_=timeline(doc.tags);placed={v['name']:v for v in fs[0].values() if v['name']};dest=out/name;req=[];layers={}
 for layer in ['bg','map','front','front_fix']:
  if layer in placed:
   p=placed[layer];req.append(f'{p["id"]}\t{dest/layer}');layers[layer]={'matrix':p['matrix']}
 (doc.work/'map-requests.tsv').write_text('\n'.join(req))
 with (doc.work/'render.log').open('w') as log:command([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwfBatch',SOURCE/'map'/f'{name}.swf',doc.work/'map-requests.tsv'],log)
 for layer,value in layers.items():value['frames']=json.loads((dest/layer/'frames.json').read_text())
 platforms=[]
 if 'floor' in placed:
  floor=placed['floor'];fr,_=doc.frames(floor['id'])
  for child in fr[0].values():
   b=transform(doc.bounds(child['id']),child['matrix']);platforms.append(transform(b,floor['matrix']))
 data={'id':name,'name':t.get('name'),'layers':layers,'width':placed['line_right']['matrix'][4],'left':placed['line_left']['matrix'][4],'floor':placed.get('line_player_bottom',placed['line_bottom'])['matrix'][5],'bottom':placed['line_bottom']['matrix'][5],'platforms':platforms,'p1':placed['p1']['matrix'][4:6],'p2':placed['p2']['matrix'][4:6],'bgm':t.find('bgm').get('url')}
 offset=600-data['bottom']
 for layer,value in layers.items():
  if layer!='bg':value['matrix'][5]+=offset
 for marker in ['p1','p2']:data[marker][1]+=offset
 for platform in platforms:platform[1]+=offset
 data['floor']+=offset;data['bottom']=600;data['normalized']=True
 dump(dest/'map.json',data);print(name,data['width'],len(platforms),'platforms',flush=True)
