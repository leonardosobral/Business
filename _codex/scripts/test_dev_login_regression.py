"""Regression checks against current DEV files; private fixtures, no account writes."""
import ast,hashlib,json,pathlib,shlex,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
WORK=pathlib.Path('/private/tmp/dev-login-fix-20261114')
TREE=ast.parse((ROOT/'_codex/scripts/test_dev_login_native.py').read_text())
REMOTE=next(ast.literal_eval(n.value) for n in TREE.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='REMOTE' for t in n.targets))
REMOTE=REMOTE.replace('import hashlib,json,os,pathlib,re,secrets,subprocess,sys,tempfile','import hashlib,json,os,pathlib,re,secrets,subprocess,sys,tempfile,shutil')
REMOTE=REMOTE.replace("dir='/var/backups'","dir='/run'").replace("if stage.exists():stage.rename(archive/'fixture')","if stage.exists():shutil.rmtree(stage)\n shutil.rmtree(archive)")
REMOTE=REMOTE.replace("dev=(pathlib.Path('/var/www/dev.roadrunners.run')/'Application.cfc').read_text(encoding='utf-8-sig')","dev=payload.pop('dev_candidate',None) or (pathlib.Path('/var/www/dev.roadrunners.run')/'Application.cfc').read_text(encoding='utf-8-sig')")
a=REMOTE.index(" header_patch=payload.pop('header_patch',None)");b=REMOTE.index(" return_start=",a)
REMOTE=REMOTE[:a]+''' header_source=payload.pop('header_candidate',None) or pathlib.Path('/var/www/dev.roadrunners.run/includes/estrutura/header.cfm').read_text()
 header_hash=hashlib.sha256(header_source.encode()).hexdigest()
 header_snippet=payload.pop('header_snippet')
 payload['header-return.cfm']=header_snippet if header_snippet in header_source else ''
 return_source=payload.pop('return_candidate',None) or pathlib.Path('/var/www/dev.roadrunners.run/includes/backend/backend.cfm').read_text()
 return_hash=hashlib.sha256(return_source.encode()).hexdigest()
'''+REMOTE[b:]
REMOTE=REMOTE.replace("content=content.replace('\"includes.models.Usuario\"'", "content=content.replace('\"services.VerifiedEntitlement\"','\"_codex.'+name+'.services.VerifiedEntitlement\"')\n  content=content.replace('\"includes.models.Usuario\"'")
REMOTE=REMOTE.replace("data-dev-login\\\\b", "data-dev-login")
# Count attribute occurrences on the full, now larger users page without an unbounded regex.
REMOTE=REMOTE.replace("count=arrayLen(reMatchNoCase('<form[^>]*data-dev-login',rendered));", 'count=0;position=1;while(true){position=findNoCase("data-dev-login",rendered,position);if(!position)break;if(mid(rendered,position-1,1)==" ")count++;position+=14;}')
MODE=sys.argv[1] if len(sys.argv)>1 else 'baseline'
if MODE not in ('baseline','candidate','published'):raise SystemExit('Use baseline, candidate, or published')
payload={'backend':(ROOT/'administracao/usuarios/includes/backend.cfm').read_text(),'native.cfm':(ROOT/'_codex/tests/dev-login/native.cfm').read_text(),'home.cfm':(ROOT/'administracao/usuarios/home.cfm').read_text()}
for include in (ROOT/'administracao/usuarios/includes').glob('*.cfm'):
 if include.name!='backend.cfm':payload['includes/'+include.name]=include.read_text()
for rel in ['services/BusinessDevLogin.cfc','services/UserAcquisitionMetrics.cfc']:payload[rel]=(ROOT/rel).read_text()
for rel in ['includes/models/Usuario.cfc','services/VerifiedEntitlement.cfc']:payload[rel]=(ROOT.parent/'RoadRunners'/rel).read_text()
patch=json.loads((ROOT/'_codex/patches/dev-login-return-header.json').read_text())
payload['header_snippet']=patch['after'].replace(patch['before'],'')
baseline=WORK/'baseline'
payload['published_hashes']={str(pathlib.Path('/var/www')/p.relative_to(baseline)):hashlib.sha256(p.read_bytes()).hexdigest() for p in baseline.rglob('*') if p.is_file()}
if MODE=='candidate':
 for name,rel in [('dev_candidate','Application.cfc'),('header_candidate','includes/estrutura/header.cfm'),('return_candidate','includes/backend/backend.cfm')]:payload[name]=(WORK/'candidate'/rel).read_text()
if MODE=='published':
 receipt=json.loads((WORK/'published.json').read_text())
 for rel,sha in receipt['candidate_hashes'].items():payload['published_hashes']['/var/www/'+rel]=sha
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','StrictHostKeyChecking=yes','-o','ConnectTimeout=10','rr-prod','python3 -c '+shlex.quote(REMOTE)],input=json.dumps(payload).encode(),capture_output=True,timeout=150)
if not p.stdout:raise SystemExit(p.stderr.decode(errors='replace')[-600:])
result=json.loads(p.stdout)
result.update(mode=MODE)
(WORK/('tests-'+MODE+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False))
raise SystemExit(0 if not p.returncode and result.get('ok') else 1)
