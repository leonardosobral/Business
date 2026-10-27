from pathlib import Path
import json,hashlib,subprocess,shlex,runpy
stage=Path(__file__).resolve().parent; root=stage.parents[2]; config=runpy.run_path(str(stage/'release.py'))
names=config['NAMES']; watch=['ads/home.cfm','services/accountDelegation/Store.cfc','includes/estrutura/header.cfm','includes/estrutura/navbar.cfm','services/BusinessAccountDelegation.cfc','ads/includes/delegation.cfm']
old=json.loads((root/'_codex/staging/ads-budget-edit-20261024/release-prepare.json').read_text())['candidate_hashes']
expected={n:old[n] if n in old else hashlib.sha256(subprocess.check_output(['git','show','HEAD:'+n],cwd=root)).hexdigest() for n in names}
remote='''from pathlib import Path
import json,hashlib,stat
root=Path('/var/www/business.roadrunners.run')
def info(n):
 p=root/n;s=p.stat();return {'exists':True,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'mode':stat.S_IMODE(s.st_mode),'uid':s.st_uid,'gid':s.st_gid}
'''+f"print(json.dumps({{'files':{{n:info(n) for n in {names!r}}},'watch':{{n:info(n) for n in {watch!r}}}}}))"
r=subprocess.run(config['SSH']+['python3 -c '+shlex.quote(remote)],capture_output=True,text=True,timeout=30)
if r.returncode:raise SystemExit(r.stderr[-1000:])
data=json.loads(r.stdout)
for n in names:
 if data['files'][n]['sha256']!=expected[n]:raise SystemExit('Baseline differs from known source: '+n)
(stage/'production-baseline.json').write_text(json.dumps(data,indent=2)+'\n');print('6 runtime baselines verified; 6 dependencies captured')
