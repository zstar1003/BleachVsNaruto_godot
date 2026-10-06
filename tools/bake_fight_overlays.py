"""Bake masked/glowing original fight overlays while retaining dynamic round/winner slots."""
import copy,json,xml.etree.ElementTree as E
from import_full_roster import Document,command
from import_godot_assets import ROOT,JAVA
DEST=ROOT/'godot/assets/ui';p=DEST/'manifest.json';m=json.loads(p.read_text());d=Document('ui','fight')
for cid,names in [('228',['nummc','winnermc']),('221',['perfectmc'])]:
 definition=d.defs[cid];sub=definition.find('subTags');state={}
 for t in list(sub):
  typ=t.get('type');dep=t.get('depth')
  if typ.startswith('PlaceObject'):
   if t.get('placeFlagMove')!='true':state[dep]=''
   if t.get('placeFlagHasName')=='true':state[dep]=t.get('name','')
  if state.get(dep) in names:sub.remove(t)
  if typ.startswith('RemoveObject'):state.pop(dep,None)
 m['fight']['nodes'][cid]['composite_dynamic']=names
xml=d.work/'overlays-visual.xml';visual=d.work/'overlays-visual.swf';d.tree.write(xml,encoding='utf-8',xml_declaration=True)
with (d.work/'overlay-bake.log').open('w') as log:
 command([JAVA,'-Djava.awt.headless=true','-jar',ROOT/'research/tools/ffdec/ffdec.jar','-xml2swf',xml,visual],log)
 req=d.work/'overlays-request.tsv';req.write_text('\n'.join(f'{cid}\t{DEST/"fight/composite"/cid}' for cid in ['228','196','221']))
 command([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwfBatch',visual,req],log)
for cid in ['228','196','221']:m['fight']['nodes'][cid]['composite']=json.loads((DEST/'fight/composite'/cid/'frames.json').read_text())
p.write_text(json.dumps(m,ensure_ascii=False,separators=(',',':')));print('Original round numbers and winner overlays baked')
