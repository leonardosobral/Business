from config import *
import json,shutil,subprocess
root=S/'test-root';root.mkdir(exist_ok=True)
files=['includes/modal/modal_youtube.cfm','includes/ads_v1/viewability.cfm','atleta/parts/sidebar_desktop.cfm','includes/estrutura/barra_lateral.cfm','canal/index.cfm','desafios/desafio_confirmado.cfm']
tests=['audience-tracker.test.js','audience-editorial.test.js','audience-static-promos.test.js','audience-live-registration.test.js','estado-city-navigation.test.cjs']
for file in files:
 dest=root/file;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(R/file,dest)
for name in tests:
 dest=root/'_codex/tests'/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(R/'_codex/tests'/name,dest)
for source,target in zip(SOURCES,GENERATED):
 dest=root/source;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(S/'candidate/rr'/target,dest)
(root/'estado').mkdir(exist_ok=True);shutil.copyfile(S/'candidate/rr/estado/index.cfm',root/'estado/index.cfm')
cp=subprocess.run(['node','--test','--test-reporter=spec']+[str(root/'_codex/tests'/name) for name in tests],cwd=root,capture_output=True,text=True,timeout=90)
(S/'node-tests.log').write_text(cp.stdout+cp.stderr)
if cp.returncode:print(cp.stdout[-5500:]);print(cp.stderr[-2500:]);raise SystemExit(cp.returncode)
import re
count=int(re.search(r'tests (\d+)',cp.stdout).group(1));assert count>=90
r={'passed_tests':count,'against_generated_assets':True,'test_files':tests};(S/'node-tests-passed.json').write_text(json.dumps(r,indent=2));print(json.dumps(r))
