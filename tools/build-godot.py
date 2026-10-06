"""Build the self-contained Godot Mac development application."""
import argparse, pathlib, subprocess, sys, shutil
ROOT=pathlib.Path(__file__).resolve().parents[1]
GODOT=pathlib.Path('/Applications/Godot.app/Contents/MacOS/Godot')
JAVA=pathlib.Path('/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home/bin/java')
parser=argparse.ArgumentParser()
parser.add_argument('--import-assets',action='store_true',help='Regenerate the committed PNG/JSON/audio resources from local 3.4 SWFs')
parser.add_argument('--import-full',action='store_true',help='Import every 3.4 fighter/form, assist, map, UI and combat effect')
args=parser.parse_args()
def run(command):
 result=subprocess.run(list(map(str,command)),cwd=ROOT,capture_output=True,text=True)
 if result.returncode or 'SCRIPT ERROR:' in result.stdout+result.stderr or 'ERROR:' in result.stdout+result.stderr:
  print((result.stdout+result.stderr)[-12000:]);raise RuntimeError('Failed: '+str(command))
 print((result.stdout+result.stderr)[-600:])
if args.import_assets:
 run([JAVA.parent/'javac','-cp',ROOT/'research/tools/ffdec/lib/*','-d',ROOT/'research/tools',ROOT/'tools/RenderSwf.java'])
 run([sys.executable,ROOT/'tools/import_godot_assets.py'])
 for character,cid,portraits in [('ichigo',632,'11,12'),('naruto',662,'6,7')]:
  run([JAVA,'-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwf',ROOT/'research/convert'/character/'visual.swf',cid,ROOT/'godot/assets'/character/'idle',12])
  run([JAVA,'-Djava.awt.headless=true','-jar',ROOT/'research/tools/ffdec/ffdec.jar','-selectid',portraits,'-export','image',ROOT/'godot/assets'/character/'portraits',ROOT/'research/release/swf_output/assets/fighter'/f'{character}.swf'])
 for cid,folder in [(3,'bg'),(6,'map')]:
  run([JAVA,'-Djava.awt.headless=true','-cp',str(ROOT/'research/tools')+':'+str(ROOT/'research/tools/ffdec/lib/*'),'RenderSwf',ROOT/'research/release/swf_output/assets/map/KonohaMura.swf',cid,ROOT/'godot/assets/stage'/folder])
 audio=ROOT/'godot/assets/audio';audio.mkdir(exist_ok=True,parents=True)
 for source in (ROOT/'research/release/swf_output/assets/sound').glob('*.mp3'):shutil.copy2(source,audio/source.name)
 shutil.copy2(ROOT/'research/release/swf_output/assets/bgm/naruto.mp3',audio/'bgm.mp3')
 run([sys.executable,ROOT/'tools/import_attacker_events.py'])
 run([sys.executable,ROOT/'tools/finish_godot_import.py'])
if args.import_full:
 run([JAVA.parent/'javac','-cp',ROOT/'research/tools/ffdec/lib/*','-d',ROOT/'research/tools',ROOT/'tools/RenderSwfBatch.java'])
 for tool in ['prepare_full_port.py','import_full_roster.py','import_original_ui.py','bake_ui_screens.py','bake_fight_overlays.py','import_full_maps.py','finish_full_import.py','import_effects.py','import_original_ai.py','finish_ui_font.py','import_menu_sounds.py']:
  run([sys.executable,ROOT/'tools'/tool])
run([GODOT,'--headless','--path',ROOT/'godot','--editor','--import','--quit'])
run([GODOT,'--headless','--path',ROOT/'godot','--script','res://tests/test_battle.gd'])
for test in ['test_full_port.gd','test_modes.gd','test_original_ai.gd']:
 run([GODOT,'--headless','--path',ROOT/'godot','--script','res://tests/'+test])
run([GODOT,'--headless','--path',ROOT/'godot','--export-release','macOS',ROOT/'BleachVsNaruto-Godot.app'])
run(['codesign','--verify','--deep','--strict',ROOT/'BleachVsNaruto-Godot.app'])
print('Built:',ROOT/'BleachVsNaruto-Godot.app')
