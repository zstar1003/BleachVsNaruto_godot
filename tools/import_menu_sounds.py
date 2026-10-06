from pathlib import Path
import subprocess,shutil
root=Path(__file__).resolve().parents[1];dest=root/'research/menu-sounds';dest.mkdir(exist_ok=True)
java='/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home/bin/java'
subprocess.run([java,'-Djava.awt.headless=true','-jar',str(root/'research/tools/ffdec/ffdec.jar'),'-selectid','9,11,12','-export','sound',str(dest),str(root/'research/release/swf_output/FighterTester.swf')],check=True)
for cid,name in [('9','gameover'),('11','menu_select'),('12','menu_confirm')]:
 files=list(dest.glob(cid+'_*.mp3')) or list(dest.glob(cid+'*.mp3'))
 if not files:raise ValueError(cid)
 shutil.copy2(files[0],root/'godot/assets/audio'/f'{name}.mp3')
