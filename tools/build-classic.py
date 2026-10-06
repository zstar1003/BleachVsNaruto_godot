"""Compile the Mac entry point and package the original OpenBVN 3.4 assets."""
import os
import pathlib
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
SDK = pathlib.Path(os.environ.get('AIR_SDK_PATH', ROOT / 'research/tools/air-sdk'))
JAVA = pathlib.Path('/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home/bin/java')
GAME = ROOT / 'research/release/swf_output'
STAGE = ROOT / 'build/classic'
APP = ROOT / 'BleachVsNaruto-3.4-Mac.app'
STAGE.mkdir(parents=True, exist_ok=True)
jars = ['guava-r08.jar', 'compiler.jar', 'antlr.jar', 'commons-io-2.0.1.jar', 'commons-cli-1.2.jar']
classpath = os.pathsep.join(str(SDK / 'lib' / jar) for jar in jars)
subprocess.run([
    str(JAVA), '-cp', classpath, 'com.adobe.flash.compiler.clients.MXMLC',
    '-load-config=' + str(ROOT / 'mac/compiler-config.xml'),
    '-external-library-path=' + str(SDK / 'frameworks/libs/air/airglobal.swc'),
    '-target-player=32.0', '-swf-version=43', '-debug=false', '-omit-trace-statements=false',
    '-output=' + str(STAGE / 'ClassicMain.swf'), str(ROOT / 'mac/ClassicMain.as')
], check=True)
shutil.copy2(ROOT / 'mac/application.xml', STAGE / 'application.xml')
shutil.copy2(GAME / 'FighterTester.swf', STAGE / 'FighterTester.swf')
shutil.copytree(GAME / 'assets', STAGE / 'assets', dirs_exist_ok=True)
password = (ROOT / 'research/tools/local-dev-password').read_text().strip()
env = os.environ.copy()
env['JAVA_HOME'] = str(JAVA.parent.parent)
packaging = subprocess.run([
    str(SDK / 'bin/adt'), '-package', '-storetype', 'pkcs12',
    '-keystore', str(ROOT / 'research/tools/local-dev.p12'), '-storepass', password,
    '-tsa', 'none', '-target', 'bundle', str(APP), 'application.xml',
    'ClassicMain.swf', 'FighterTester.swf', 'assets'
], cwd=STAGE, env=env)
if packaging.returncode:
    raise SystemExit('AIR packaging failed with exit code ' + str(packaging.returncode))
subprocess.run(['codesign', '--force', '--sign', '-', str(APP)], check=True)
subprocess.run(['codesign', '--verify', '--verbose', str(APP)], check=True)
print('Built:', APP)
