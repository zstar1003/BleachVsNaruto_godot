"""Rasterize original UI symbols while preserving their display tree and transforms."""
import pathlib,copy,json,shutil,subprocess,xml.etree.ElementTree as E
from import_full_roster import Document,CACHE,OUT,dump,command
from import_godot_assets import ROOT,SOURCE,JAVA,FF,timeline
DEST=ROOT/'godot/assets/ui'
DEST.mkdir(parents=True,exist_ok=True)
manifest={}
for name in ['title','select','fight','common_ui','setting','gameover','howtoplay','loading']:
 doc=Document('ui',name);nodes={};req=[];maxid=max(int(k) for k in doc.defs if k.isdigit());nextid=maxid+1
 wrappers={}
 def wrap(cid):
  global nextid
  if cid in wrappers:return wrappers[cid]
  wid=str(nextid);nextid+=1;sp=E.SubElement(doc.tags,'item',{'type':'DefineSpriteTag','spriteId':wid,'frameCount':'1','forceWriteAsLong':'true'})
  sub=E.SubElement(sp,'subTags');place=E.SubElement(sub,'item',{'type':'PlaceObject2Tag','depth':'1','placeFlagHasCharacter':'true','characterId':cid,'placeFlagHasMatrix':'true','placeFlagMove':'false'})
  E.SubElement(place,'matrix',{'type':'MATRIX','hasScale':'false','hasRotate':'false','translateX':'0','translateY':'0'})
  E.SubElement(sub,'item',{'type':'ShowFrameTag'});E.SubElement(sub,'item',{'type':'EndTag'})
  wrappers[cid]=wid;return wid
 # The display-tree renderer retains all symbol ordering, including anonymous children.
 for cid,t in list(doc.defs.items()):
  if not cid:continue
  if t.get('type')=='DefineSpriteTag':
   frames,labels=doc.frames(cid);nodes[cid]={'frames':[list(f.values()) for f in frames],'labels':labels}
  elif t.get('type') not in ['DefineSoundTag','DefineFont2Tag','DefineFont3Tag','DefineFont4Tag','DefineFontTag','DefineFontNameTag','DefineFontAlignZonesTag']:
   wid=wrap(cid);nodes[cid]={'image':cid};req.append(f'{wid}\t{DEST/name/cid}')
 visual=doc.work/'ui-symbols.swf';xml=doc.work/'ui-symbols.xml';doc.tree.write(xml,encoding='utf-8',xml_declaration=True)
 log=(doc.work/'render.log').open('w');command([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-jar',FF,'-xml2swf',xml,visual],log)
 (doc.work/'ui-requests.tsv').write_text('\n'.join(req))
 command([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwfBatch',visual,doc.work/'ui-requests.tsv'],log)
 for cid,node in nodes.items():
  if 'image' in node:
   node['image']=json.loads((DEST/name/cid/'frames.json').read_text())[0]
 manifest[name]={'classes':{v:k for k,v in doc.classes.items()},'nodes':nodes}
 print(name,len(nodes),'original symbols',flush=True)
 log.close()
# Original linked bitmaps include all selectable faces, bar faces and winner portraits.
face=DEST/'face'
if not face.exists():
 with (CACHE/'shared/face/images.log').open('w') as log:command([JAVA,'-Djava.awt.headless=true','-jar',FF,'-export','image',face,SOURCE/'face.swf'],log)
manifest['faces']={}
for p in face.iterdir():manifest['faces'][p.stem.split('_',1)[1]]=str(p.relative_to(DEST))
font=DEST/'font';font.mkdir(exist_ok=True)
for p in (SOURCE/'font').glob('*'):shutil.copy2(p,font/p.name)
for p in (SOURCE/'font').glob('*.xml'):
 glyphs={c.get('id'):c.attrib for c in E.parse(p).getroot().find('chars')};manifest[p.stem]={'file':'font/'+p.stem+'.png','glyphs':glyphs}
# Exact select-grid positions from the original config (including row/column offsets).
select=E.parse(SOURCE/'config/select.xml').getroot();layout=select.find('stage_setting/layout').attrib
manifest['select_grid']={}
for name in ['char_list','assist_list']:
 rows=select.find(name);items=[];gapx=(800-50-15-15)/9;gapy=(600-50-100-10)/(len(rows)-1)
 for y,row in enumerate(rows):
  ro=[float(v) for v in row.get('offset','0,0').split(',')]
  for x,item in enumerate(row):
   if not item.text:continue
   off=[float(v) for v in item.get('offset','0,0').split(',')]
   items.append({'id':item.text,'more':item.get('more',''),'x':x,'y':y,'position':[15+gapx*x+ro[0]+off[0],100+gapy*y+ro[1]+off[1]]})
 manifest['select_grid'][name]=items
maps=[]
for t in E.parse(SOURCE/'config/map.xml').getroot():
 p=SOURCE.parent/t.find('img').get('url');dest=DEST/'map'/p.name;dest.parent.mkdir(exist_ok=True);shutil.copy2(p,dest)
 maps.append({'id':t.get('id'),'name':t.get('name'),'image':str(dest.relative_to(DEST)),'bgm':t.find('bgm').get('url') if t.find('bgm') is not None else ''})
manifest['maps']=maps
dump(DEST/'manifest.json',manifest)
print('UI complete',len(manifest['faces']),'linked faces',flush=True)
