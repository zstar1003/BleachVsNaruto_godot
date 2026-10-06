"""Reproducible SWF frame/data import. Requires the local 3.4 release and FFDec."""
import json, pathlib, subprocess, xml.etree.ElementTree as E, re, hashlib, shutil, math
ROOT=pathlib.Path(__file__).resolve().parents[1]
JAVA='/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home/bin/java'
FF=ROOT/'research/tools/ffdec/ffdec.jar'
OUT=ROOT/'godot/assets'
SOURCE=ROOT/'research/release/swf_output/assets'
def ff(*args):
 subprocess.run([JAVA,'-Djava.awt.headless=true','-jar',str(FF),*map(str,args)],check=True,stdout=subprocess.DEVNULL)
def balanced(text,start,opening='{',closing='}'):
 depth=0; quoted=False;esc=False
 for i in range(start,len(text)):
  c=text[i]
  if quoted:
   if esc:esc=False
   elif c=='\\':esc=True
   elif c=='"':quoted=False
   continue
  if c=='"':quoted=True
  elif c==opening:depth+=1
  elif c==closing:
   depth-=1
   if depth==0:return text[start:i+1],i+1
 raise ValueError('Unbalanced AS')
def functions(text):
 result={}
 for m in re.finditer(r'internal function frame(\d+)\(\)\s*:\s*\*\s*\{',text):
  result[int(m[1])]=balanced(text,m.end()-1)[0][1:-1]
 return result
def matrix(t):
 m=t.find('matrix')
 if m is None:return None
 return [float(m.get('scaleX','1')) if m.get('hasScale')=='true' else 1,float(m.get('rotateSkew0','0')),float(m.get('rotateSkew1','0')),float(m.get('scaleY','1')) if m.get('hasScale')=='true' else 1,float(m.get('translateX','0'))/20,float(m.get('translateY','0'))/20]
def transform(b,m):
 a,c,d,e,x,y=m
 pts=[(a*u+d*v+x,c*u+e*v+y) for u in (b[0],b[0]+b[2]) for v in (b[1],b[1]+b[3])]
 xs,ys=zip(*pts);return [min(xs),min(ys),max(xs)-min(xs),max(ys)-min(ys)]
def timeline(tags):
 states={};frames=[];labels={}
 for t in tags:
  typ=t.get('type');depth=t.get('depth')
  if typ=='FrameLabelTag':labels[t.get('name')]=len(frames)+1
  elif typ.startswith('PlaceObject'):
   if t.get('placeFlagMove')!='true' or depth not in states:states[depth]={'matrix':[1,0,0,1,0,0],'name':''}
   s=states[depth]
   if t.get('placeFlagHasName')=='true':s['name']=t.get('name','')
   if t.get('placeFlagHasCharacter')=='true':s['id']=t.get('characterId')
   if matrix(t):s['matrix']=matrix(t)
  elif typ.startswith('RemoveObject'):states.pop(depth,None)
  elif typ=='ShowFrameTag':frames.append(json.loads(json.dumps(states)))
 return frames,labels

def build(c,id,klass):
 work=ROOT/'research/convert'/c;work.mkdir(parents=True,exist_ok=True)
 xml=ROOT/('research/'+c+'.xml')
 if not xml.exists():ff('-swf2xml',SOURCE/'fighter'/f'{c}.swf',xml)
 if not (work/'scripts').exists():ff('-export','script',work,SOURCE/'fighter'/f'{c}.swf')
 tree=E.parse(xml);r=tree.getroot();tags=r.find('tags')
 defs={t.get('spriteId',t.get('shapeId','')):t for t in tags}
 sp=defs[str(id)];frames,labels=timeline(sp.find('subTags'))
 def bounds(cid,stack=()):
  if cid in stack:return [0,0,0,0]
  t=defs.get(cid)
  if t is None:return [0,0,0,0]
  rect=t.find('shapeBounds')
  if rect is not None:
   x,y=float(rect.get('Xmin'))/20,float(rect.get('Ymin'))/20
   return [x,y,float(rect.get('Xmax'))/20-x,float(rect.get('Ymax'))/20-y]
  if t.get('type')=='DefineSpriteTag':
   fr,_=timeline(t.find('subTags'));bs=[transform(bounds(s['id'],stack+(cid,)),s['matrix']) for f in fr for s in f.values() if 'id' in s]
   if bs:
    x=min(b[0] for b in bs);y=min(b[1] for b in bs)
    return [x,y,max(b[0]+b[2] for b in bs)-x,max(b[1]+b[3] for b in bs)-y]
  return [0,0,0,0]
 collisions=[]
 spawns={}
 for frame,body in functions((work/'scripts'/f'{c}_fla'/f'{klass}.as').read_text()).items():
  for m in re.finditer(r'parent.\$mc_ctrler.(?:fire|addAttacker)\("([^"]+)"',body):
   name=m[1]
   found=next((s for f in frames[frame-1:frame+3] for s in f.values() if s['name']==name),None)
   if found:spawns[name]={'id':found['id'],'position':found['matrix'][4:6],'matrix':found['matrix']}
 for f in frames:
  hits=[];body=[-10,-50,20,50];checks={}
  for s in f.values():
   n=s['name']
   if 'id' not in s:continue
   if n=='bdmn':body=transform(bounds(s['id']),s['matrix'])
   if n.endswith('atm'):hits.append({'id':n[:-3],'rect':transform(bounds(s['id']),s['matrix'])})
   if n.endswith('chkm'):checks[n]=transform(bounds(s['id']),s['matrix'])
  collisions.append({'body':body,'hits':hits,'checks':checks})
 # Suppress only the original debugging geometry; never edit the original SWF.
 for sprite in [t for t in tags if t.get('type')=='DefineSpriteTag']:
  sub=sprite.find('subTags');state={}
  for t in list(sub):
   typ=t.get('type');dep=t.get('depth')
   if typ.startswith('PlaceObject'):
    if t.get('placeFlagMove')!='true':state[dep]=''
    if t.get('placeFlagHasName')=='true':state[dep]=t.get('name','')
    n=state.get(dep,'')
    if n in ('AImain','bdmn','main') or n.endswith(('atm','chkm')) or (sprite is sp and n in spawns):sub.remove(t)
   elif typ.startswith('RemoveObject'):
    n=state.pop(dep,'')
    if n in ('AImain','bdmn','main') or n.endswith(('atm','chkm')) or (sprite is sp and n in spawns):sub.remove(t)
 cleanxml=work/'visual.xml';tree.write(cleanxml,encoding='utf-8',xml_declaration=True)
 visual=work/'visual.swf';ff('-xml2swf',cleanxml,visual)
 dest=OUT/c;dest.mkdir(parents=True,exist_ok=True)
 subprocess.run([JAVA,'-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwf',str(visual),str(id),str(dest)],check=True)
 render=json.loads((dest/'frames.json').read_text())
 for name,spawn in spawns.items():
  sprite_dest=dest/'spawn'/name
  subprocess.run([JAVA,'-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwf',str(visual),spawn['id'],str(sprite_dest)],check=True,stdout=subprocess.DEVNULL)
  spawn['frames']=json.loads((sprite_dest/'frames.json').read_text())
  original=E.parse(xml).getroot()
  child=next(t for t in original.find('tags') if t.get('spriteId')==spawn['id'])
  fr,la=timeline(child.find('subTags'));spawn['labels']=la
  spawn['collisions']=[]
  for f in fr:
   hs=[]
   for st in f.values():
    n=st['name']
    if n=='main' or n.endswith('atm'):
     hs.append({'id':name[:-3] if n=='main' else n[:-3], 'rect':transform(bounds(st['id']),st['matrix'])})
   spawn['collisions'].append(hs)
 text=(work/'scripts'/f'{c}_fla'/f'{klass}.as').read_text()
 events={}
 unknown=[]
 for frame,body in functions(text).items():
  calls=[]
  for m in re.finditer(r'parent\.\$(mc|effect|fighter)_ctrler\.(\w+)\(',body):
   raw,_=balanced(body,m.end()-1,'(',')');args=raw[1:-1]
   try:values=json.loads('['+args+']')
   except json.JSONDecodeError:values=[];unknown.append({'frame':frame,'method':m[2],'arguments':args})
   conditional=bool(re.search(r'\bif\s*\(',body))
   calls.append({'controller':m[1],'method':m[2],'args':values,'conditional':conditional})
  if calls:events[str(frame)]=calls
 rootfunc=functions((work/'scripts'/f'{c}_fla/MainTimeline.as').read_text())[2]
 actions={}
 for m in re.finditer(r'this.defineAction\("(\w+)",\s*\{',rootfunc):
  raw,_=balanced(rootfunc,m.end()-1);actions[m[1]]=json.loads(raw)
 stats={m[1]:float(m[2]) for m in re.finditer(r'this.\$fighter_ctrler\.(speed|jumpPower|heavy)\s*=\s*([\d.]+)',rootfunc)}
 data={'id':c,'name':'黑崎一护' if c=='ichigo' else '漩涡鸣人','fps':30,'frames':render,'labels':labels,'collisions':collisions,'events':events,'actions':actions,'stats':stats,'spawns':spawns,'unparsed_calls':unknown,'source_sha256':hashlib.sha256((SOURCE/'fighter'/f'{c}.swf').read_bytes()).hexdigest()}
 (dest/'fighter.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')))
 ref=ROOT/'godot/reference'/c;ref.mkdir(parents=True,exist_ok=True)
 shutil.copy2(work/'scripts'/f'{c}_fla'/f'{klass}.as',ref/'timeline.as')
 (ref/'base_initialization.as').write_text(rootfunc)
 ff('-export','sound',dest,SOURCE/'fighter'/f'{c}.swf')
 print(c,len(render),'frames',len(labels),'labels',len(actions),'hit definitions',len(unknown),'unparsed calls')

if __name__=='__main__':
 build('ichigo',632,'mc_0059_1')
 build('naruto',662,'mc_0004_1')
