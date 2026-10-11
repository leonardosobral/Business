from pathlib import Path
import base64,hashlib,json,os,shlex,shutil,subprocess,sys,tempfile
ROOT=Path(__file__).resolve().parents[3]
STAGE='/var/backups/business-abraceo-precadastro-20261011'
def q(sql):
 return 'q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{}, {datasource="runner_dba",timeout=45});'
def sqljson(data):return "convert_from(decode('"+base64.b64encode(json.dumps(data,ensure_ascii=False).encode()).decode()+"','base64'),'UTF8')::jsonb"
def snapshot(rows):
 docs=','.join("'"+r['documento']+"'" for r in rows)
 return "SELECT coalesce(jsonb_agg(to_jsonb(c) ORDER BY id_conta),'[]')::text payload FROM tb_contas c WHERE regexp_replace(documento,'[^0-9]','','g') IN ("+docs+")"
def remote(mode,p):
 root=Path('/var/www/business.roadrunners.run');stage=Path(STAGE)
 if mode=='prepare':
  assert not stage.exists(),'Stage already exists'
  for name,data in p['files'].items():
   t=root/name
   assert not t.is_symlink()
   if name in p['before']:assert hashlib.sha256(t.read_bytes()).hexdigest()==p['before'][name],'Runtime baseline changed'
   else:assert not t.exists(),'New destination already exists'
  stage.mkdir(mode=0o700)
  for name,data in p['files'].items():
   t=stage/'candidate'/name;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(base64.b64decode(data))
   if name in p['before']:
    b=stage/'baseline'/name;b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/name,b)
  (stage/'payload.json').write_text(json.dumps(p))
  snap=bridge(root,q(snapshot(p['rows']))+'report={snapshot=q.payload[1]};')
  (stage/'database-before.json').write_text(json.dumps(snap))
  return {'backup':str(stage),'files':len(p['files']),'database_saved':True}
 if mode=='restage-data':
  assert not (stage/'commit.json').exists()
  old=json.loads((stage/'payload.json').read_text());assert old['files']==p['files'] and old['migration']==p['migration']
  for a,b in zip(old['rows'],p['rows']):
   assert {k:v for k,v in a.items() if k!='telefone'}=={k:v for k,v in b.items() if k!='telefone'}
  (stage/'payload-before-phones.json').write_text(json.dumps(old));(stage/'payload.json').write_text(json.dumps(p));return {'phones_normalized':True}
 p=json.loads((stage/'payload.json').read_text())
 if mode=='compile':
  with tempfile.TemporaryDirectory(prefix='abraceo-compile-',dir='/var/tmp') as d:
   w=Path(d);os.chmod(w,0o755);s=w/'source';shutil.copytree(stage/'candidate'/'administracao',s/'administracao');dest=w/'compiled';dest.mkdir(mode=0o777);os.chmod(dest,0o777)
   r=subprocess.run(['/opt/ColdFusion/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','nobody','-webroot',str(s),'-dir',str(s),'-deploydir',str(dest)],capture_output=True,text=True,timeout=160)
   result={'returncode':r.returncode,'output':r.stdout+r.stderr,'compiled':len(list(dest.rglob('*.cfm')))}
   (stage/'compile.json').write_text(json.dumps(result));assert r.returncode==0 and result['compiled']>=2 and 'Error compiling' not in result['output'],result
   return result
 if mode in ('dryrun','commit'):
  assert (stage/'compile.json').exists()
  if mode=='commit':assert (stage/'dryrun.json').exists() and not (stage/'commit.json').exists()
  before=json.loads((stage/'database-before.json').read_text()); before=before.get('SNAPSHOT',before.get('snapshot'))
  body='transaction {'+q("SET LOCAL lock_timeout='3s'")+q("SET LOCAL statement_timeout='40s'")+q('LOCK TABLE public.tb_contas IN SHARE ROW EXCLUSIVE MODE')+q(snapshot(p['rows']))
  body+='if(lCase(hash(q.payload[1],"SHA-256","UTF-8"))!="'+hashlib.sha256(before.encode()).hexdigest()+'")throw(message="Account baseline changed");'
  body+=q(p['migration'])
  data=sqljson(p['rows']); items="SELECT x FROM jsonb_array_elements("+data+") x"
  new=" FROM ("+items+") s WHERE x->>'id_existente' IS NULL"
  idcol='id_conta,' if mode=='dryrun' else ''
  idval='-1000-row_number() over(), ' if mode=='dryrun' else ''
  body+=q('INSERT INTO tb_contas ('+idcol+'nome_conta,tipo_titular,documento,nome_titular,email_principal,telefone_principal,status) SELECT '+idval+"x->>'nome_empresa','PJ',x->>'documento',x->>'razao_social',nullif(x->>'email',''),nullif(x->>'telefone',''),'PENDENTE'"+new+' RETURNING id_conta')+'if(q.recordCount!=36)throw(message="Expected 36 new accounts");'
  body+=q("INSERT INTO tb_conta_perfis_publicos(id_conta,origem,id_origem,logo_path,dados,data_pesquisa) SELECT c.id_conta,'ABRACEO',x->>'id_filiado',x->>'logo_path',x->'dados','2026-10-11'::date FROM ("+items+") s JOIN tb_contas c ON c.documento=x->>'documento' RETURNING id_conta")+'if(q.recordCount!=41)throw(message="Expected 41 profiles");'
  body+=q("SELECT c.id_conta,c.documento,c.nome_conta,c.status,p.id_origem,p.logo_path,(SELECT count(*) FROM tb_conta_usuarios u WHERE u.id_conta=c.id_conta) usuarios FROM tb_conta_perfis_publicos p JOIN tb_contas c USING(id_conta) WHERE p.origem='ABRACEO' ORDER BY p.id_origem")+'report={accounts=[]};for(r in q)arrayAppend(report.accounts,r);'
  if mode=='dryrun':body+='transaction action="rollback";'
  body+='}'
  report=bridge(root,body);(stage/(mode+'.json')).write_text(json.dumps(report));return report
 if mode=='publish':
  assert (stage/'commit.json').exists()
  for n,b64 in p['files'].items():
   t=root/n;old=p['before'].get(n)
   assert hashlib.sha256(t.read_bytes()).hexdigest()==old if old else not t.exists(),'Production conflict: '+n
  for n,b64 in p['files'].items():
   t=root/n;t.parent.mkdir(parents=True,exist_ok=True);tmp=t.with_name(t.name+'.abraceo-new');tmp.write_bytes(base64.b64decode(b64));os.chmod(tmp,0o644);os.replace(tmp,t)
  return {'published':len(p['files']),'backup':str(stage)}
 if mode=='verify':
  for n,b64 in p['files'].items():assert (root/n).read_bytes()==base64.b64decode(b64),'Runtime differs'
  # Existing account rows must remain byte-for-byte equivalent to their baseline.
  before=json.loads((stage/'database-before.json').read_text());before=json.loads(before.get('SNAPSHOT',before.get('snapshot')))
  now=bridge(root,q(snapshot(p['rows']))+'report={snapshot=q.payload[1]};');now=json.loads(now.get('SNAPSHOT',now.get('snapshot')))
  byid={r['id_conta']:r for r in now};assert all(byid[r['id_conta']]==r for r in before),'Existing account changed'
  assert len(now)==41 and len(before)==5
  new=[r for r in now if r['id_conta'] not in {b['id_conta'] for b in before}];assert len(new)==36 and all(r['status']=='PENDENTE' for r in new)
  ids=','.join(str(r['id_conta']) for r in new)
  checks=bridge(root,q('SELECT count(*) n FROM tb_conta_usuarios WHERE id_conta IN ('+ids+')')+'report={new_account_users=q.n[1]};');assert int(checks.get('NEW_ACCOUNT_USERS',checks.get('new_account_users')))==0
  report={'new_accounts':36,'reused_accounts_unchanged':5,'profiles_and_logos':41,'files_verified':len(p['files']),'new_account_users':0}
  (stage/'verified.json').write_text(json.dumps(report));return report
 raise ValueError(mode)
def main():
 mode=sys.argv[1]
 if mode=='--remote':
  payload=json.load(sys.stdin);exec(payload.pop('bridge_source'),globals());print(json.dumps(remote(sys.argv[2],payload)));return
 p=json.loads((ROOT/'outputs/abraceo-20261010/importacao/payload.json').read_text()) if mode in ('prepare','restage-data') else {}
 source=(ROOT/'_codex/scripts/deploy_estudo.py').read_text();p['bridge_source']=source[source.index('def bridge('):source.index('\ndef raw_query(')]
 script=Path(__file__).read_text().replace('ROOT=Path(__file__).resolve().parents[3]',"ROOT=Path('/var/www/business.roadrunners.run')",1)
 args=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(script)+' --remote '+shlex.quote(mode)]
 r=subprocess.run(args,input=json.dumps(p),capture_output=True,text=True,timeout=180)
 if r.returncode:raise SystemExit(r.stderr[-4000:])
 data=json.loads(r.stdout);(ROOT/'outputs/abraceo-20261010/importacao'/('release-'+mode+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2))
 print(json.dumps(data,ensure_ascii=False) if mode not in ('dryrun','commit') else json.dumps({'mode':mode,'accounts':len(data.get('ACCOUNTS',data.get('accounts',[])))}))
if __name__=='__main__':main()
