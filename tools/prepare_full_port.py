"""Cache the complete 3.4 SWF documents, AS3 timelines and original UI."""
import pathlib, subprocess, concurrent.futures, json, shutil
from import_godot_assets import ROOT, SOURCE, JAVA, FF
CACHE=ROOT/'research/full-port'
CACHE.mkdir(parents=True,exist_ok=True)
jobs=[]
for kind in ['fighter','assist','map']:
 folder=SOURCE/kind
 if not folder.exists():folder=SOURCE/'fighter/assistant' if kind=='assist' else folder
 for source in sorted(folder.glob('*.swf')):jobs.append((kind,source.stem,source))
for name in ['face','effect']:
 jobs.append(('shared',name,SOURCE/(name+'.swf')))
for source in sorted((ROOT/'research/ui-swfs').glob('*.bin')):
 name=source.name.split('_',1)[1].split('_swf')[0]
 jobs.append(('ui',name,source))
def process(job):
 kind,name,source=job; dest=CACHE/kind/name;dest.mkdir(parents=True,exist_ok=True)
 with (dest/'extract.log').open('w') as log:
  if not (dest/'source.xml').exists():subprocess.run([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-jar',str(FF),'-swf2xml',str(source),str(dest/'source.xml')],stdout=log,stderr=log,check=True)
  if not (dest/'scripts').exists():subprocess.run([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-jar',str(FF),'-export','script',str(dest),str(source)],stdout=log,stderr=log,check=True)
 print(kind,name,flush=True)
 return {'kind':kind,'name':name,'source':str(source),'cache':str(dest)}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:result=list(pool.map(process,jobs))
(CACHE/'sources.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print('Prepared',len(result),'SWF documents',flush=True)
