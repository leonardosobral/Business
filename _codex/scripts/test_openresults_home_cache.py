from pathlib import Path
import subprocess,shlex,json,sys
root=Path(__file__).resolve().parents[2];stage=root/'_codex/staging/openresults-home-cache-20261004'
source=(root/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/opt/ColdFusion/cfusion/wwwroot')").replace("dir=root/'_codex'","dir=root").replace('https://business.roadrunners.run/_codex/','http://127.0.0.1:8500/')
source=source.replace('this.datasource="runner_dba";','this.datasource="runnerhub";this.mappings["/profileServices"]="PROFILEPATH";this.mappings["/services"]="PROFILEPATH";')
payload={'FixtureSource.cfc':(root/'_codex/tests/openresults-home-cache/FixtureSource.cfc').read_text(),'cache.cfm':(root/'_codex/tests/openresults-home-cache/cache.cfm').read_text()}
for p in (stage/'candidate/services').glob('*'):payload[p.name]=p.read_text()
if len(sys.argv)>1 and sys.argv[1]=='integration':
 payload['cache.cfm']=(root/'_codex/tests/openresults-home-cache/integration.cfm').read_text()
 for name,folder,file in [('baseline.cfm','baseline','includes/backend.cfm'),('candidate.cfm','candidate','includes/backend.cfm'),('baseline-city.cfm','baseline','includes/backend_home_cidades.cfm'),('candidate-city.cfm','candidate','includes/backend_home_cidades.cfm')]:payload[name]=(stage/folder/file).read_text()
remote=source+'''
payload=json.load(sys.stdin)
with tempfile.TemporaryDirectory(prefix='or-cache-test-',dir='/var/tmp') as d:
 p=Path(d);fixtureRoot=p;os.chmod(p,0o755)
 for name,content in payload.items():(p/name).write_text(content)
 # Update the fixture factory only; production application is never changed.
 template=os.path.relpath(p/'cache.cfm',ROOT/'fixture')
 print(json.dumps(bridge(ROOT,'include '+json.dumps(template)+';')))
'''
# Replace mapping with stable per-run path through environment in remote Python source before defining bridge.
remote=remote.replace('(work/\'Application.cfc\').write_text(', '(work/\'Application.cfc\').write_text(').replace('PROFILEPATH', "'+str(fixtureRoot)+'")
p=subprocess.run(['ssh','-o','BatchMode=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps(payload),capture_output=True,text=True,timeout=110)
print(p.stdout);print(p.stderr[-2500:]);(stage/('test-'+(sys.argv[1] if len(sys.argv)>1 else 'green')+'.json')).write_text(p.stdout or p.stderr);raise SystemExit(p.returncode)
