from pathlib import Path
import hashlib,json,shlex,subprocess,sys
P=Path(__file__).parent;ROOT=P.parents[2];mode=sys.argv[1];assert mode in ['prepare','publish','verify','rollback']
names={'Business':['portal/audiencia/queries/advertiser_acquisition.sql','portal/audiencia/advertiser_acquisition.cfm','portal/includes/audience_backend.cfm','portal/audiencia/home.cfm'],'RoadRunners':['assets/js/rr-audience.js','includes/analytics/bootstrap.cfm']}
bases={'Business':{'portal/includes/audience_backend.cfm':'audience_backend.cfm','portal/audiencia/home.cfm':'home.cfm'},'RoadRunners':{'assets/js/rr-audience.js':'rr-audience.js','includes/analytics/bootstrap.cfm':'bootstrap.cfm'}}
files={g:{n:(P/'candidate'/g/n).read_text() for n in ns} for g,ns in names.items()}
before={g:{n:hashlib.sha256((P/'baseline'/b).read_bytes()).hexdigest() for n,b in bs.items()} for g,bs in bases.items()}
if mode=='publish':
 assert json.loads((P/'candidate-checks.json').read_text())['passed']==10
 assert json.loads((P/'sql-tests.json').read_text())['checks_passed']==7
 t=subprocess.run(['node','--test',str(P/'tracker.test.cjs')],capture_output=True);assert t.returncode==0
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
remote=helpers+r'''
p=json.load(sys.stdin);roots={'Business':Path('/var/www/business.roadrunners.run'),'RoadRunners':Path('/var/www/roadrunners.com.br')};stage=Path('/var/backups/ads-followup-20261008');mode=p['mode']
if mode=='prepare':
 stage.mkdir(mode=0o700,exist_ok=False)
 for g,root in roots.items():prepare(root,stage/g,p['files'][g],p['before'][g])
 watch={'Business':['portal/audiencia/queries/filter.sql','portal/audiencia/queries/.htaccess','portal/audiencia/live_journey.cfm','assets/js/audience-dashboard.js','includes/backend/require_admin.cfm'],'RoadRunners':['includes/estrutura/seo-web-tools-head.cfm','services/AudienceMeasurementService.cfc','api/analytics/collect.cfm','includes/ads_v1/viewability.cfm']}
 (stage/'guards.json').write_text(json.dumps({g:{n:digest((roots[g]/n).read_bytes()) for n in ns} for g,ns in watch.items()}))
 with tempfile.TemporaryDirectory(prefix='ads-followup-compile-',dir='/var/tmp') as d:
  w=Path(d);os.chmod(w,0o755);src=w/'src';src.mkdir();out=w/'out';out.mkdir();os.chmod(out,0o777)
  for g,fs in p['files'].items():
   for n,s in fs.items():
    if n.endswith('.cfm'):
     t=src/g/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_text(s)
  cp=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(src),'-dir',str(src),'-deploydir',str(out)],capture_output=True,text=True,timeout=120)
  log=cp.stdout+cp.stderr;(stage/'compile.log').write_text(log)
  if cp.returncode or 'Error compiling' in log or not any(out.rglob('*.cfm')):raise RuntimeError(log)
 (stage/'compiled.json').write_text(json.dumps({g:json.loads((stage/g/'manifest.json').read_text())['candidate'] for g in roots}))
 print(json.dumps({'prepared':6,'compiled':4,'backup':str(stage)}))
elif mode=='publish':
 compiled=json.loads((stage/'compiled.json').read_text());guards=json.loads((stage/'guards.json').read_text())
 for g,root in roots.items():
  baseline(root,p['files'][g],p['before'][g]);baseline(root,guards[g],guards[g])
  for n,s in p['files'][g].items():assert digest(s.encode())==compiled[g][n]==digest((stage/g/'candidate'/n).read_bytes())
 installed=[]
 try:
  for g,root in roots.items():
   ref=(root/next(iter(p['before'][g]))).stat()
   for n in p['files'][g]:
    target=root/n;replace_file(stage/g/'candidate'/n,target,target.stat() if target.exists() else ref)
   installed.append(g);verify(root,stage/g)
 except Exception:
  for g in reversed(list(roots)):rollback(roots[g],stage/g)
  raise
 print(json.dumps({'published':6,'backup':str(stage)}))
elif mode=='verify':
 guards=json.loads((stage/'guards.json').read_text())
 for g,root in roots.items():verify(root,stage/g);baseline(root,guards[g],guards[g])
 print(json.dumps({'verified_hashes':6,'preserved_dependencies':sum(map(len,guards.values()))}))
else:
 for g,root in roots.items():rollback(root,stage/g)
 print(json.dumps({'rollback':True}))
'''
r=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'mode':mode,'files':files,'before':before}),capture_output=True,text=True,timeout=180)
if r.returncode:raise SystemExit(r.stderr[-5000:])
(P/(mode+'-receipt.json')).write_text(r.stdout);print(r.stdout)
