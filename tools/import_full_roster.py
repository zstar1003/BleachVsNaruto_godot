"""Import every configured fighter/form/assist from the unmodified BVN 3.4 release."""
import pathlib,json,re,xml.etree.ElementTree as E,subprocess,concurrent.futures,hashlib,functools,shutil,copy
from import_godot_assets import ROOT,SOURCE,JAVA,FF,timeline,transform,functions,balanced
from as3_timeline import parse
CACHE=ROOT/'research/full-port';OUT=ROOT/'godot/assets/full'
def dump(p,data):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')))
def command(args,log):subprocess.run(list(map(str,args)),check=True,stdout=log,stderr=log)
class Document:
 def __init__(self,kind,name):
  self.work=CACHE/kind/name;self.tree=E.parse(self.work/'source.xml');self.tags=self.tree.getroot().find('tags')
  self.defs={t.get('spriteId',t.get('shapeId',t.get('characterID',t.get('characterId',t.get('soundId',t.get('fontID','')))))):t for t in self.tags if t.get('type','').startswith('Define')}
  self.classes={}
  for t in self.tags:
   if t.get('type')=='SymbolClassTag':self.classes.update({x.text:y.text for x,y in zip(t.find('tags'),t.find('names'))})
  self.scripts={}
  for cid,cls in self.classes.items():
   p=self.work/'scripts'/pathlib.Path(*cls.split('.')).with_suffix('.as')
   if p.exists():self.scripts[cid]=p.read_text()
  self.errors=[]
 @functools.lru_cache(None)
 def frames(self,cid):
  d=self.defs.get(str(cid));return timeline(d.find('subTags')) if d is not None and d.get('type')=='DefineSpriteTag' else ([],{})
 @functools.lru_cache(None)
 def bounds(self,cid):
  t=self.defs.get(str(cid))
  if t is None:return [0,0,0,0]
  rect=t.find('shapeBounds')
  if rect is not None:return [float(rect.get('Xmin'))/20,float(rect.get('Ymin'))/20,(float(rect.get('Xmax'))-float(rect.get('Xmin')))/20,(float(rect.get('Ymax'))-float(rect.get('Ymin')))/20]
  fs,_=self.frames(cid);bs=[]
  for f in fs:
   for s in f.values():
    if 'id' in s and s['id']!=cid:bs.append(transform(self.bounds(s['id']),s['matrix']))
  if not bs:return [0,0,0,0]
  x=min(b[0] for b in bs);y=min(b[1] for b in bs);return [x,y,max(b[0]+b[2] for b in bs)-x,max(b[1]+b[3] for b in bs)-y]
 def ast(self,cid):
  out={}
  for frame,body in functions(self.scripts.get(cid,'')).items():
   try:out[str(frame)]=parse(body)
   except Exception as e:self.errors.append({'sprite':cid,'frame':frame,'error':str(e),'source':body})
  return out
 def collision(self,cid,attacker=False):
  fs,_=self.frames(cid);out=[]
  for f in fs:
   hits=[];body=[-10,-50,20,50];checks={};markers={}
   for s in f.values():
    n=s['name']
    if 'id' not in s:continue
    if n:markers[n]=s['matrix'][4:6]
    if n=='bdmn':body=transform(self.bounds(s['id']),s['matrix'])
    if n.endswith('atm') or n.startswith('atm') or attacker and n=='main':hits.append({'id':n[:-3] if n.endswith('atm') else n if n.startswith('atm') else '', 'rect':transform(self.bounds(s['id']),s['matrix'])})
    if n.endswith('chkm'):checks[n]=transform(self.bounds(s['id']),s['matrix'])
   out.append({'body':body,'hits':hits,'checks':checks,'markers':markers})
  return out
 def sounds(self,cid,folder):
  frame=1;out={}
  for t in self.defs[cid].find('subTags'):
   if t.get('type')=='ShowFrameTag':frame+=1
   if t.get('type')=='StartSoundTag':
    sid=t.get('soundId');p=next((p for p in folder.glob('*') if p.stem==sid or p.stem.startswith(sid+'_')),None)
    if p:
     info=t.find('soundInfo');out.setdefault(str(frame),[]).append({'file':str(p.relative_to(OUT)),'start':int(info.get('inPoint','0'))/44100,'stop':info.get('syncStop')=='true','end':int(info.get('outPoint','0'))/44100})
  return out
 def spawns(self,cid):
  fs,_=self.frames(cid);out={}
  for frame,body in functions(self.scripts.get(cid,'')).items():
   for m in re.finditer(r'(?:\$(?:mc|attacker)_ctrler|\$assisterCtrler)\.(?:fire|addAttacker)\("([^"]+)"',body):
    name=m[1];found=next((s for f in fs[frame-1:frame+5] for s in f.values() if s['name']==name),None)
    if found:out[name]=copy.deepcopy(found)
    else:self.errors.append({'sprite':cid,'frame':frame,'error':'Missing spawned display '+name})
  return out

def config(kind):
 filename='assistant' if kind=='assist' else 'fighter';out=[]
 for t in E.parse(SOURCE/'config'/f'{filename}.xml').getroot():
  if t.find('file') is None:continue
  out.append({'id':t.get('id'),'name':t.get('name',''),'comic_type':int(t.get('comic_type','-1')),'source':t.find('file').get('url'),'start':int(t.find('file').get('startFrame','1')),'face':t.find('face').attrib,'says':[s.text for s in t.findall('says/say_item')],'bgm':t.find('bgm').get('url') if t.find('bgm') is not None else ''})
 return out

def export_source(job):
 kind,name,entries=job
 if all((OUT/kind/(e['id']+'.json')).exists() for e in entries):
  return json.loads((CACHE/kind/name/'coverage.json').read_text())
 doc=Document(kind,name);work=doc.work;dest=OUT/kind/name;dest.mkdir(parents=True,exist_ok=True)
 source=ROOT/'research/release/swf_output'/entries[0]['source'];log=(work/'render.log').open('w')
 audio=OUT/'audio'/kind/name
 if not audio.exists():command([JAVA,'-Djava.awt.headless=true','-jar',FF,'-export','sound',audio,source],log)
 images=OUT/'portraits'/kind/name
 if not images.exists():command([JAVA,'-Djava.awt.headless=true','-jar',FF,'-export','image',images,source],log)
 rootframes,_=timeline(doc.tags);root=functions(doc.scripts.get('0',''));sprites={};forms=[]
 if kind=='assist':
  aid=str(max(int(k) for k in doc.defs if k.isdigit())+1)
  sp=E.SubElement(doc.tags,'item',{'type':'DefineSpriteTag','spriteId':aid,'frameCount':str(len(rootframes)),'forceWriteAsLong':'true'})
  sub=E.SubElement(sp,'subTags')
  for tag in list(doc.tags):
   if tag.get('type','').startswith(('PlaceObject','RemoveObject')) or tag.get('type') in ['ShowFrameTag','FrameLabelTag','StartSoundTag','SoundStreamBlockTag']:sub.append(copy.deepcopy(tag))
  E.SubElement(sub,'item',{'type':'EndTag'});doc.defs[aid]=sp;doc.scripts[aid]=doc.scripts.get('0','')
 for entry in entries:
  init_frame=entry['start']+1 if kind=='fighter' else 1
  root_index=entry['start'] if kind=='fighter' else 0
  placements=rootframes[root_index]
  placed=next((s for s in placements.values() if s['name']=='mc'),None)
  if placed is None:
   placed=next((s for s in placements.values() if s.get('id') in doc.scripts),None)
  if placed is None and kind=='fighter':raise ValueError(f'Cannot discover {entry}')
  cid=placed['id'] if kind=='fighter' else aid;fs,labels=doc.frames(cid);init=root.get(init_frame,'') if kind=='fighter' else doc.scripts.get('0','')
  # Some assist roots initialize on frame 2 despite no fighter-style startFrame.
  if not init and root:init=root.get(2,next(iter(root.values())))
  actions={}
  for m in re.finditer(r'this.defineAction\("([^"]+)",\s*\{',init):
   raw,_=balanced(init,m.end()-1);actions[m[1]]=json.loads(raw)
  stats={'speed':8,'jumpPower':15,'heavy':3,'defenseType':0}
  stats.update({m[1]:float(m[2]) for m in re.finditer(r'this.\$fighter_ctrler\.(speed|jumpPower|heavy|defenseType)\s*=\s*([\d.]+)',init)})
  portraitmap={}
  for m in re.finditer(r'defineBishaFace\("([^"]+)",\s*(\w+)\)',init):
   p=next((p for p in images.glob('*.png') if p.stem.endswith('_'+m[2])),None)
   if p:portraitmap[m[1]]=str(p.relative_to(OUT))
  data={**entry,'id':entry['id'],'fps':30,'sprite':cid,'asset_base':str(dest.relative_to(OUT))+'/'+cid+'/','labels':labels,'collisions':doc.collision(cid),'program':doc.ast(cid),'events':{},'actions':actions,'stats':stats,'spawns':{},'portraits':portraitmap,'sounds':doc.sounds(cid,audio),'init_source':init,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest()}
  forms.append(data);sprites[cid]=None
  # Keep the complete outer/root program, including per-form initialization variables.
  try:data['root_program']=parse(init) if kind=='fighter' else []
  except Exception as e:doc.errors.append({'sprite':'0','frame':init_frame,'error':str(e)})
  todo=[cid];visited=set()
  while todo:
   sid=todo.pop()
   if sid in visited:continue
   visited.add(sid)
   for n,s in doc.spawns(sid).items():
    scid=s['id'];sprites[scid]=None;todo.append(scid)
    sfs,sls=doc.frames(scid);coll=doc.collision(scid,True)
    for col in coll:
     for area in col['hits']:
      if not area['id']:area['id']=n[:-3] if n.endswith('atm') else n
    data['spawns'][n]={'id':scid,'position':s['matrix'][4:6],'matrix':s['matrix'],'labels':sls,'collisions':[c['hits'] for c in coll],'program':doc.ast(scid),'events':{},'sounds':doc.sounds(scid,audio),'asset_base':str(dest.relative_to(OUT))+'/'+scid+'/'}
 # Remove helper geometry and spawned objects; independent spawned sprites are drawn by the runtime.
 for t in doc.tags:
  if t.get('type')!='DefineSpriteTag':continue
  sub=t.find('subTags');state={};spawn_names=set(doc.spawns(t.get('spriteId')))
  for tag in list(sub):
   typ=tag.get('type');dep=tag.get('depth');n=''
   if typ.startswith('PlaceObject'):
    if tag.get('placeFlagMove')!='true':state[dep]=''
    if tag.get('placeFlagHasName')=='true':state[dep]=tag.get('name','')
    n=state.get(dep,'')
   elif typ.startswith('RemoveObject'):n=state.pop(dep,'')
   if n in ('AImain','bdmn','main') or n.endswith(('atm','chkm')) or n.startswith('atm') or n in spawn_names:sub.remove(tag)
 visual=work/'full-visual.swf'
 if not visual.exists():
  xml=work/'full-visual.xml';doc.tree.write(xml,encoding='utf-8',xml_declaration=True);command([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-jar',FF,'-xml2swf',xml,visual],log)
 requests=[]
 for cid in sprites:requests.append(f'{cid}\t{dest/cid}')
 # Render nested idle loops for every form using the original child timelines.
 for form in forms:
  cid=form['sprite'];fs,_=doc.frames(cid);count=1
  for st in fs[form['labels'].get('站立',1)-1].values():
   if 'id' in st:count=max(count,len(doc.frames(st['id'])[0]))
  requests.append(f'{cid}\t{dest/(cid+"-idle")}\t{count}\t{form["labels"].get("站立",1)-1}')
 (work/'requests.tsv').write_text('\n'.join(requests))
 command([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwfBatch',visual,work/'requests.tsv'],log)
 for form in forms:
  cid=form['sprite'];form['frames']=json.loads((dest/cid/'frames.json').read_text());form['idle']=json.loads((dest/(cid+'-idle')/'frames.json').read_text());form['idle_base']=str((dest/(cid+'-idle')).relative_to(OUT))+'/'
  for spawn in form['spawns'].values():spawn['frames']=json.loads((dest/spawn['id']/'frames.json').read_text())
  dump(OUT/kind/(form['id']+'.json'),form)
 dump(work/'coverage.json',{'forms':[f['id'] for f in forms],'errors':doc.errors,'frames':sum(len(f['frames']) for f in forms)})
 print(kind,name,len(forms),'forms',sum(len(f['frames']) for f in forms),'frames',len(doc.errors),'issues',flush=True)
 log.close();return {'kind':kind,'name':name,'forms':[f['id'] for f in forms],'errors':doc.errors}
if __name__=='__main__':
 jobs=[];catalog={}
 for kind in ['fighter','assist']:
  entries=config(kind);catalog[kind]=entries;groups={}
  for e in entries:groups.setdefault(pathlib.Path(e['source']).stem,[]).append(e)
  jobs += [(kind,name,entries) for name,entries in groups.items()]
 dump(OUT/'catalog.json',catalog)
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(export_source,jobs))
 dump(OUT/'coverage.json',results)
 print('COMPLETE',len(catalog['fighter']),'fighter/forms',len(catalog['assist']),'assists',flush=True)
