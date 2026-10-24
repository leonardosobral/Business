"""Scoped first-access release: live baseline, recoverable backup, compile, rollback tests, publish."""
from pathlib import Path
import base64,hashlib,json,os,shlex,shutil,subprocess,sys,tempfile,uuid
ROOT=Path(__file__).resolve().parents[2]
LOCAL=ROOT/'_codex/staging/abraceo-voucher-pendente-20261011'
STAGE='/var/backups/business-abraceo-voucher-pendente-20261011'
NAMES=['services/accountDelegation/RequestBoundary.cfc','estudos/includes/FirstAccess.cfc','estudos/primeiro-acesso/index.cfm','estudos/primeiro-acesso/api.cfm','estudos/primeiro-acesso/primeiro-acesso.js']
SNAPSHOT="""SELECT jsonb_build_object(
'accounts', (SELECT md5(coalesce(jsonb_agg(to_jsonb(c) ORDER BY c.id_conta)::text,'[]')) FROM tb_contas c JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE p.origem='ABRACEO'),
'memberships',(SELECT md5(coalesce(jsonb_agg(to_jsonb(u) ORDER BY u.id_conta_usuario)::text,'[]')) FROM tb_conta_usuarios u JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE p.origem='ABRACEO'),
'events',(SELECT md5(coalesce(jsonb_agg(to_jsonb(e) ORDER BY e.id_conta_evento)::text,'[]')) FROM tb_conta_eventos e JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE p.origem='ABRACEO'),
'campaigns',(SELECT jsonb_agg(to_jsonb(c) ORDER BY id) FROM estudo.campanhas c WHERE codigo<>'abraceo-primeiro-acesso'),
'vouchers',(SELECT count(*) FROM estudo.vouchers),
'grants',(SELECT count(*) FROM estudo.acessos),
'profiles',(SELECT count(*) FROM tb_conta_perfis_publicos WHERE origem='ABRACEO'))::text payload"""
def sqlq(sql):return 'q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{}, {datasource="runner_dba",timeout=40});'
def remote(mode,p):
 root=Path('/var/www/business.roadrunners.run');stage=Path(STAGE)
 if mode=='prepare':
  for n,h in p['dependencies'].items():assert digest((root/n).read_bytes())==h,'Dependency baseline changed: '+n
  result=prepare(root,stage,p['files'],p['before']);(stage/'payload.json').write_text(json.dumps(p))
  saved=bridge(root,sqlq(SNAPSHOT)+'report={snapshot=q.payload[1]};');(stage/'database-before.json').write_text(json.dumps(saved))
  return {'files':len(p['files']),'backup':str(stage)}
 if mode=='restage':
  saved=json.loads((stage/'payload.json').read_text());baseline(root,saved['files'],saved['before'])
  assert p['before']==saved['before'] and p['dependencies']==saved['dependencies']
  for n,s in p['files'].items():
   t=stage/'candidate'/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_text(s)
  (stage/'payload.json').write_text(json.dumps(p));m=json.loads((stage/'manifest.json').read_text());m['candidate']={n:digest(s.encode()) for n,s in p['files'].items()};(stage/'manifest.json').write_text(json.dumps(m))
  for f in ['compile.json','tests.json']:
   if (stage/f).exists():(stage/f).unlink()
  return {'restaged':len(p['files'])}
 if mode=='http-checks':
  cases=[('anonymous_page','/estudos/primeiro-acesso/',None,200),('anonymous_lookup','/estudos/primeiro-acesso/api.cfm','operation=lookup&mode=CNPJ&value=28674754000146',401),('forged_actor','/estudos/primeiro-acesso/api.cfm','operation=lookup&actorId=1',403),('duplicate_operation','/estudos/primeiro-acesso/api.cfm','operation=lookup&operation=confirm',403)]
  results=[]
  for label,path,data,expected in cases:
   args=['curl','-sS','--max-time','30','--resolve','business.roadrunners.run:443:127.0.0.1','-w','\n%{http_code}','https://business.roadrunners.run'+path]
   if data:args+=['--data',data]
   r=subprocess.run(args,capture_output=True,text=True,timeout=35);body,status=r.stdout.rsplit('\n',1)
   assert r.returncode==0 and int(status) in ([401,403] if label in ['forged_actor','duplicate_operation'] else [expected]),(label,status,body[:300])
   if label=='anonymous_page':assert 'Entre com o Google.' in body and 'name="role"' not in body
   results.append({'check':label,'status':int(status)})
  return {'origin_http':results}
 if mode=='update-ui':
  verify(root,stage)
  m=json.loads((stage/'manifest.json').read_text());names=['estudos/primeiro-acesso/'+n for n in ['index.cfm','primeiro-acesso.js','primeiro-acesso.css']]
  assert set(p['files'])==set(names)
  patch=stage/'ui-update';prepare(root,patch,p['files'],{n:m['candidate'][n] for n in names})
  with tempfile.TemporaryDirectory(prefix='abraceo-ui-',dir='/var/tmp') as d:
   w=Path(d);os.chmod(w,0o755);source=w/'source';shutil.copytree(patch/'candidate',source);dest=w/'compiled';dest.mkdir(mode=0o777);os.chmod(dest,0o777)
   r=subprocess.run(['/opt/coldfusion2025/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','coldfusion','-webroot',str(source),'-dir',str(source),'-deploydir',str(dest)],capture_output=True,text=True,timeout=160)
   assert r.returncode==0 and 'Error compiling' not in r.stdout+r.stderr and any(dest.rglob('*.cfm')),r.stdout+r.stderr
  result=publish(root,patch);verify(root,patch)
  saved=json.loads((stage/'payload.json').read_text())
  for n,s in p['files'].items():
   (stage/'candidate'/n).write_text(s);m['candidate'][n]=digest(s.encode());saved['files'][n]=s
  (stage/'manifest.json').write_text(json.dumps(m));(stage/'payload.json').write_text(json.dumps(saved));result['compiled']=True
  return result
 p=json.loads((stage/'payload.json').read_text())
 if mode=='compile':
  with tempfile.TemporaryDirectory(prefix='abraceo-first-access-',dir='/var/tmp') as d:
   w=Path(d);os.chmod(w,0o755);source=w/'source';shutil.copytree(stage/'candidate',source);dest=w/'compiled';dest.mkdir(mode=0o777);os.chmod(dest,0o777)
   r=subprocess.run(['/opt/coldfusion2025/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','coldfusion','-webroot',str(source),'-dir',str(source),'-deploydir',str(dest)],capture_output=True,text=True,timeout=160)
   result={'returncode':r.returncode,'output':r.stdout+r.stderr,'compiled':len([x for x in dest.rglob('*') if x.is_file()])}
   (stage/'compile.json').write_text(json.dumps(result));assert r.returncode==0 and result['compiled']>=4 and 'Error compiling' not in result['output'],result
   return result
 if mode=='enable':
  assert not (stage/'eligibility.json').exists() and (stage/'tests.json').exists()
  assert json.loads((stage/'tests.json').read_text()).get('TOTAL',0)>=47
  ids=','.join(str(r['id_conta']) for r in p['contacts'] if r['status']=='APTO');n=sum(r['status']=='APTO' for r in p['contacts'])
  assert n==46
  body='transaction {'+sqlq("SELECT count(*) n FROM public.tb_contas c JOIN public.tb_conta_perfis_publicos p USING(id_conta) WHERE c.id_conta IN ("+ids+") AND c.documento_pendente AND c.documento IS NULL AND c.status='PENDENTE' AND p.origem='ABRACEO'")+'if(q.n[1]!=46)throw(message="Pending company inventory changed");'
  body+=sqlq('INSERT INTO estudo.primeiro_acesso_empresas(id_conta) SELECT id_conta FROM public.tb_contas WHERE id_conta IN ('+ids+') RETURNING id_conta')+'if(q.recordCount!=46)throw(message="Eligibility count mismatch");report={enabled=q.recordCount};}'
  result=bridge(root,body);(stage/'eligibility.json').write_text(json.dumps(result));return result
 if mode=='test':
  work=root/'_codex'/('abraceo_candidate_'+uuid.uuid4().hex);work.mkdir(mode=0o755)
  try:
   (work/'.htaccess').write_text('Require local\n');(work/'FirstAccess.cfc').write_text(p['files']['estudos/includes/FirstAccess.cfc']);(work/'RequestBoundary.cfc').write_text(p['files']['services/accountDelegation/RequestBoundary.cfc'])
   body=p['tests'].replace('__SERVICE__','_codex.'+work.name+'.FirstAccess').replace('__BOUNDARY__','_codex.'+work.name+'.RequestBoundary')
   result=bridge(root,body);(stage/'tests.json').write_text(json.dumps(result));return result
  finally:shutil.rmtree(work)
 if mode=='publish':
  assert (stage/'eligibility.json').exists() and (stage/'tests.json').exists()
  for n,h in p['dependencies'].items():assert digest((root/n).read_bytes())==h,'Dependency changed'
  result=publish(root,stage);(stage/'published.json').write_text(json.dumps(result));return result
 if mode=='verify':
  result=verify(root,stage)
  for n,h in p['dependencies'].items():assert digest((root/n).read_bytes())==h,'Dependency changed'
  old=json.loads((stage/'database-before.json').read_text());old=json.loads(old.get('SNAPSHOT',old.get('snapshot')))
  now=bridge(root,sqlq(SNAPSHOT)+'report={snapshot=q.payload[1]};');now=json.loads(now.get('SNAPSHOT',now.get('snapshot')))
  for k in ['accounts','memberships','events','campaigns','profiles']:assert old[k]==now[k],'Baseline changed: '+k
  result.update({'existing_business_state_preserved':True,'existing_campaigns_preserved':True,'profiles':now['profiles'],'vouchers':now['vouchers'],'grants':now['grants']});(stage/'verified.json').write_text(json.dumps(result));return result
 if mode=='rollback':return rollback(root,stage)
 raise ValueError(mode)
def main():
 mode=sys.argv[1]
 if mode=='--remote':
  p=json.load(sys.stdin);exec(p.pop('helpers'),globals());print(json.dumps(remote(sys.argv[2],p)));return
 p={}
 if mode=='update-ui':p={'files':{'estudos/primeiro-acesso/'+n:(ROOT/'estudos/primeiro-acesso'/n).read_text() for n in ['index.cfm','primeiro-acesso.js','primeiro-acesso.css']}}
 if mode in ['prepare','restage']:
  baselines=json.loads((LOCAL/'baseline.json').read_text());before={n:h for n,h in baselines.items() if n in NAMES};dependencies={'estudos/includes/StudyAccess.cfc':hashlib.sha256((ROOT/'estudos/includes/StudyAccess.cfc').read_bytes()).hexdigest()}
  p={'files':{n:(ROOT/n).read_text() for n in NAMES},'before':before,'dependencies':dependencies,'migration':(ROOT/'_codex/sql/2026-10-11_estudo_primeiro_acesso.sql').read_text(),'tests':(ROOT/'_codex/tests/abraceo_primeiro_acesso_pendente.cfscript').read_text(),'contacts':json.loads((ROOT/'outputs/abraceo-convites-atualizados-20261011/support/contacts.json').read_text())}
 s=(ROOT/'_codex/scripts/deploy_estudo.py').read_text();p['helpers']=s[s.index('def digest('):s.index('\ndef raw_query(')]
 source=Path(__file__).read_text().replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')",1)
 args=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)+' --remote '+shlex.quote(mode)]
 r=subprocess.run(args,input=json.dumps(p),capture_output=True,text=True,timeout=180)
 if r.returncode:raise SystemExit(r.stderr[-5500:])
 data=json.loads(r.stdout);(LOCAL/('release-'+mode+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2));print(json.dumps(data,ensure_ascii=False))
if __name__=='__main__':main()
