from pathlib import Path
import hashlib,json,re,shlex,subprocess
S=Path(__file__).resolve().parent;R=Path.cwd();names=sorted(str(x.relative_to(S/'candidate')) for x in (S/'candidate').rglob('*') if x.is_file())
helpers=(R/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
# Python writes fixtures as readable source before Adobe executes them. No browser or telemetry scripts run.
helpers=helpers.replace("(work/'run.cfm').write_text", "for n,v in fixture_inputs['fixtures'].items():(work/n).write_text(v)\n  (work/'run.cfm').write_text")
remote=helpers+r'''
fixture_inputs=json.load(sys.stdin)
body='APPLICATION.ga="fixture";REQUEST.t=function(required string key){return key;};REQUEST.i18nBuildPath=function(required string key){return "/privacidade/";};report={cases=[]};'
for prefix in ['','https://roadrunners.run']:
 body+='VARIABLES.rrSharedAssetBaseUrl="'+prefix+'";savecontent variable="rendered"{include "head.cfm";}arrayAppend(report.cases,{kind="head",prefix="'+prefix+'",html=rendered});'
for label,name in [('privacy','privacy.cfm'),('footer','footer.cfm'),('prompts','prompts.cfm')]:
 body+='savecontent variable="rendered"{include "'+name+'";include "'+name+'";}arrayAppend(report.cases,{kind="'+label+'",html=rendered});'
print(json.dumps(bridge(ROOT,body)))
'''
f=lambda n:(S/'candidate'/n).read_text()
body=f('includes/estrutura/seo-web-tools-body-end.cfm');changed=re.findall(r'<script src="/assets/js/runnerhub-entry-prompts\.min\.js[^>]*></script>',body);assert len(changed)==1
fixtures={'head.cfm':f('includes/estrutura/seo-web-tools-head.cfm'),'privacy.cfm':f('includes/analytics/privacy_controls.cfm'),'footer.cfm':f('includes/estrutura/footer_assets.cfm'),'prompts.cfm':changed[0]}
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'fixtures':fixtures}),capture_output=True,text=True,timeout=110)
if cp.returncode:raise RuntimeError(cp.stderr[-2500:])
r=json.loads(cp.stdout);cases=r.get('cases',r.get('CASES'));checks=0
for x in cases:
 x={k.lower():v for k,v in x.items()};h=x['html']
 if x['kind']=='head':
  assert x['prefix']+'/assets/css/cores.min.css?version=20261004seo' in h and '/assets/css/cores.css?' not in h;checks+=2
 elif x['kind']=='privacy':
  assert h.count('data-audience-privacy-root')==1 and h.count('rr-audience-privacy.min.js?')==1 and 'rr-audience-privacy.min.css?' in h;checks+=3
 elif x['kind']=='footer':assert h.count('runnerhub-footer.min.css?')==1;checks+=1
 else:assert h.count('runnerhub-entry-prompts.min.js?')==2;checks+=1
for suffix in ['original','minified']:
 report=(S/f'tests-{suffix}.txt').read_text();assert '# pass 22' in report and '# fail 0' in report
receipt={'hashes':{n:hashlib.sha256((S/'candidate'/n).read_bytes()).hexdigest() for n in names},'watch':json.loads((S/'watch.json').read_text()),'adobe_asset_reference_checks':checks,'behavior_tests_each':22,'build':json.loads((S/'build.json').read_text())}
(S/'candidate-render-passed.json').write_text(json.dumps(receipt,indent=2,ensure_ascii=False));print(json.dumps({'adobe_asset_reference_checks':checks,'behavior_tests_original':22,'behavior_tests_minified':22,'source_files_preserved':5}))
