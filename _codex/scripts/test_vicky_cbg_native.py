"""Private localhost CF fixtures; never invoke the delivery worker."""
import ast,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
RR=ROOT.parent/'RoadRunners'
mode=sys.argv[1] if len(sys.argv)>1 else 'source'
tree=ast.parse((ROOT/'_codex/scripts/test_user_acquisition_native.py').read_text())
remote=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
remote=remote.replace('user_acquisition_','vicky_cbg_').replace('business-user-acquisition-test-','business-vicky-cbg-test-').replace('USER_ACQUISITION_','VICKY_CBG_')
remote=remote.replace('this.sessionManagement=true;', 'this.mappings["/cbgPublishedRR"]="/var/www/roadrunners.com.br";this.sessionManagement=true;')
remote=remote.replace("body=body.replace('new services.UserAcquisitionMetrics','new _codex.'+name+'.services.UserAcquisitionMetrics')", "body=body.replace('new repositories.VickyBrasilGiganteRepository','new _codex.'+name+'.repositories.VickyBrasilGiganteRepository').replace('new services.VickyProactiveService','new _codex.'+name+'.services.VickyProactiveService')")
remote=remote.replace("dest.write_text(body,encoding='utf-8-sig')", "body=body.replace('__CBG_COMPONENT__','_codex.'+name+'.repositories.VickyBrasilGiganteRepository')\n  dest.write_text(body,encoding='utf-8-sig')")
remote=remote.replace("body=body.replace('__CBG_COMPONENT__'", "body=body.replace('new repositories.VickyProactiveRepository','new _codex.'+name+'.repositories.VickyProactiveRepository')\n  body=body.replace('__CBG_COMPONENT__'")
if mode=='form':remote=remote.replace("'--header','X-Acquisition-Test: '+nonce", "'--request','POST','--header','X-Acquisition-Test: '+nonce")
payload={'mode':mode}
payload['tests/install.sql']=(ROOT/'_codex/sql/2026-10-24_vicky_brasil_gigante.sql').read_text()
for rel in ['administracao/vicky/includes/backend.cfm','administracao/vicky/home.cfm']:
    payload[rel]=(ROOT/rel).read_text()
for rel in ['repositories/VickyBrasilGiganteRepository.cfc','services/VickyProactiveService.cfc','repositories/VickyProactiveRepository.cfc']:
    path=RR/rel
    if path.exists():
        body=path.read_text()
        if '--production-variant' in sys.argv and rel=='services/VickyProactiveService.cfc':body=body.replace('services.VickyMetaWhatsappServiceV3','services.VickyMetaWhatsappServiceV2')
        payload[rel]=body
for path in (ROOT/'_codex/tests/vicky-cbg').glob('*.cfm'):payload['tests/'+path.name]=path.read_text()
for path in (ROOT/'_codex/tests/vicky-cbg').glob('*.cfc'):payload['tests/'+path.name]=path.read_text()
run=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=12','rr-prod','python3 -c '+shlex.quote(remote)],input=json.dumps(payload).encode(),capture_output=True,timeout=65)
try:result=json.loads(run.stdout)
except ValueError:result={'ok':False,'error':run.stderr.decode(errors='replace')[-600:] or 'Native transport failed'}
print(json.dumps(result,ensure_ascii=False));raise SystemExit(0 if not run.returncode and result.get('ok') else 1)
