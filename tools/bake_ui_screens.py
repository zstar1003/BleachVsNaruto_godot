"""Bake original screen composites so masks and Flash color transforms stay exact."""
import sys,json,pathlib
from import_full_roster import Document,command
from import_godot_assets import ROOT,JAVA
DEST=ROOT/'godot/assets/ui';p=DEST/'manifest.json';m=json.loads(p.read_text())
for group,cls in [('title','stg_title'),('select','stg_select'),('setting','stg_set_ui'),('gameover','stg_gameover_mc'),('howtoplay','movie_howtoplay')]:
 d=Document('ui',group);cid=m[group]['classes'][cls];dest=DEST/group/'composite'/cid
 request=d.work/'composite-requests.tsv';request.write_text(f'{cid}\t{dest}')
 source=next((ROOT/'research/ui-swfs').glob('*_'+group+'_swf*'))
 with (d.work/'composite.log').open('w') as log:command([JAVA,'-Xmx1536m','-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwfBatch',source,request],log)
 m[group]['nodes'][cid]['composite']=json.loads((dest/'frames.json').read_text());print(group,flush=True)
p.write_text(json.dumps(m,ensure_ascii=False,separators=(',',':')))
