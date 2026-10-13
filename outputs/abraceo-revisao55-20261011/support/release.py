from pathlib import Path
import base64,hashlib,json,os,shlex,shutil,subprocess,sys,tempfile
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'outputs/abraceo-revisao55-20261011/support'
STAGE='/var/backups/business-abraceo-revisao55-20261011'
def q(sql):return 'try {q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{}, {datasource="runner_dba",timeout=45});}catch(any stepError){throw(message="Database step '+sql.split()[0]+' failed",detail=stepError.message & " / " & stepError.detail);}'
def sqljson(data):return "convert_from(decode('"+base64.b64encode(json.dumps(data,ensure_ascii=False).encode()).decode()+"','base64'),'UTF8')::jsonb"
def lower(d):return {k.lower():v for k,v in d.items()}
def snapshot():
 return "SELECT jsonb_build_object('accounts',(SELECT jsonb_agg(to_jsonb(c)-'documento_pendente' ORDER BY id_conta) FROM tb_contas c),'profiles',(SELECT jsonb_agg(jsonb_build_object('id_conta',id_conta,'id_origem',id_origem,'hash',md5(to_jsonb(p)::text)) ORDER BY id_conta) FROM tb_conta_perfis_publicos p),'links',(SELECT jsonb_agg(jsonb_build_object('id_conta_evento',id_conta_evento,'hash',md5(to_jsonb(e)::text)) ORDER BY id_conta_evento) FROM tb_conta_eventos e),'users',(SELECT md5(coalesce(jsonb_agg(to_jsonb(u) ORDER BY id_conta_usuario)::text,'[]')) FROM tb_conta_usuarios u),'eligibility',(SELECT md5(coalesce(jsonb_agg(to_jsonb(x) ORDER BY id_conta)::text,'[]')) FROM estudo.primeiro_acesso_empresas x),'vouchers',(SELECT md5(coalesce(jsonb_agg(to_jsonb(x) ORDER BY id)::text,'[]')) FROM estudo.vouchers x),'grants',(SELECT md5(coalesce(jsonb_agg(to_jsonb(x) ORDER BY id)::text,'[]')) FROM estudo.acessos x))::text payload"
def snap(root):
 sql="SELECT substring(s.payload from i for 32000) part FROM ("+snapshot()+")s CROSS JOIN LATERAL generate_series(1,length(s.payload),32000) i ORDER BY i"
 return json.loads(lower(bridge(root,q(sql)+'s="";for(row in q)s &= row.part;report={snapshot=s};'))['snapshot'])
def baseline(root,p):
 for n,b in p['files'].items():
  t=root/n;assert not t.is_symlink()
  if n in p['before']:assert hashlib.sha256(t.read_bytes()).hexdigest()==p['before'][n],'Production conflict: '+n
  else:assert not t.exists(),'Destination exists: '+n

def remote(mode,p):
 root=Path('/var/www/business.roadrunners.run');stage=Path(STAGE)
 if mode=='prepare':
  baseline(root,p);state=snap(root)
  assert len(state['accounts'])==56 and len(state['profiles'])==41,'Initial account/profile inventory changed'
  stage.mkdir(mode=0o700,parents=True,exist_ok=False)
  for n,b in p['files'].items():
   t=stage/'candidate'/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(base64.b64decode(b))
   if n in p['before']:
    t=stage/'baseline'/n;t.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/n,t)
  (stage/'payload.json').write_text(json.dumps(p));(stage/'database-before.json').write_text(json.dumps(state));return {'backup':str(stage),'files':len(p['files']),'accounts_before':56}
 p=json.loads((stage/'payload.json').read_text())
 if mode=='compile':
  with tempfile.TemporaryDirectory(prefix='abraceo-review-',dir='/var/tmp') as d:
   w=Path(d);os.chmod(w,0o755);s=w/'source';shutil.copytree(stage/'candidate'/'administracao',s/'administracao');dest=w/'compiled';dest.mkdir(mode=0o777);os.chmod(dest,0o777)
   r=subprocess.run(['/opt/coldfusion2025/cfusion/bin/cfcompile.sh','-deploy','-cfruntimeuser','coldfusion','-webroot',str(s),'-dir',str(s),'-deploydir',str(dest)],capture_output=True,text=True,timeout=160)
   result={'returncode':r.returncode,'output':r.stdout+r.stderr,'compiled':len(list(dest.rglob('*.cfm')))}
   assert r.returncode==0 and result['compiled']>=3 and 'Error compiling' not in result['output'],result
   (stage/'compile.json').write_text(json.dumps(result));return result
 if mode in ['dryrun','commit']:
  baseline(root,p);assert (stage/'compile.json').exists()
  if mode=='commit':assert (stage/'dryrun.json').exists() and not (stage/'commit.json').exists()
  old=json.loads((stage/'database-before.json').read_text());assert snap(root)==old,'Database inventory changed'
  ids=','.join(str(int(e['id_evento'])) for e in p['events']); n=len(p['rows']);ne=len(p['events']);items="SELECT x FROM jsonb_array_elements("+sqljson(p['rows'])+") x"
  schema_sql="SELECT count(*) n FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_contas' AND ((column_name='documento_pendente' AND data_type='boolean' AND is_nullable='NO' AND column_default='false') OR (column_name='documento' AND is_nullable='YES'))"
  guard=q(schema_sql)+'if(q.n[1]!=2)throw(message="Manual migration columns missing");'
  guard+=q("SELECT count(*) n FROM pg_constraint WHERE conrelid='public.tb_contas'::regclass AND convalidated AND conname IN ('tb_contas_documento_pendente_check','unq_tb_contas_documento')")+'if(q.n[1]!=2)throw(message="Manual migration constraints missing");'
  insert_probe="INSERT INTO tb_contas(id_conta,nome_conta,tipo_titular,documento,documento_pendente,nome_titular,status) VALUES(-90001,'test','PJ',NULL,true,'test','PENDENTE'),(-90002,'test2','PJ',NULL,true,'test2','PENDENTE')"
  # Use ordinary DML transactions, preserving the datasource's DDL restriction.
  probes=[("status='ATIVA'",'tb_contas_documento_pendente_check'),("tipo_titular='PF'",'tb_contas_documento_pendente_check'),("documento_pendente=false",'tb_contas_documento_pendente_check'),("documento='123',documento_pendente=true",'tb_contas_documento_pendente_check'),("documento='',documento_pendente=false",'tb_contas_documento_pendente_check'),("documento=(SELECT documento FROM tb_contas WHERE id_conta=1),documento_pendente=false",'unq_tb_contas_documento')]
  guard+='transaction {'+q(insert_probe)+'transaction action="rollback";}'
  for assignment,constraint in probes:
   guard+='rejected=false;try {transaction {'+q(insert_probe)+q('UPDATE tb_contas SET '+assignment+' WHERE id_conta=-90001')+'transaction action="rollback";}}catch(any probeError){if(!findNoCase("'+constraint+'",probeError.message & probeError.detail))rethrow;rejected=true;}if(!rejected)throw(message="Constraint probe was accepted");'
  guard+='transaction {'+q(insert_probe)+q("UPDATE tb_contas SET documento='00000000000191',documento_pendente=false,status='ATIVA' WHERE id_conta=-90001")+'transaction action="rollback";}'
  bridge(root,guard+'report={constraint_checks=8};')
  assert snap(root)==old,'Constraint probes did not restore baseline'
  body='transaction {'+q("SET LOCAL lock_timeout='3s'")+q('LOCK TABLE tb_contas,tb_conta_perfis_publicos,tb_conta_eventos IN SHARE ROW EXCLUSIVE MODE')
  body+=q("SELECT count(*) n FROM tb_contas c JOIN ("+items+") s ON lower(c.nome_conta)=lower(x->>'nome_empresa') OR c.documento=x->'dados'->>'cnpj_pesquisado'")+'if(q.n[1]!=0)throw(message="Possible existing account match");'
  body+=q("SELECT count(*) n FROM tb_evento_corridas WHERE id_evento IN ("+ids+") AND ativo=true AND data_inicial::date>'2026-10-11'")+'if(q.n[1]!='+str(ne)+')throw(message="Future event eligibility changed");'
  # Exact event dates protect against parallel catalog changes and stale editions.
  evitems="SELECT x FROM jsonb_array_elements("+sqljson(p['events'])+") x"
  body+=q("SELECT count(*) n FROM tb_evento_corridas e JOIN ("+evitems+") s ON e.id_evento=(x->>'id_evento')::int AND e.data_inicial::date=(x->>'data_inicial')::date")+'if(q.n[1]!='+str(ne)+')throw(message="Event date changed");'
  body+=q('SELECT count(*) n FROM tb_conta_eventos WHERE id_evento IN ('+ids+')')+'if(q.n[1]!=0)throw(message="Existing event association");'
  idcol='id_conta,' if mode=='dryrun' else '';idval='-1000-row_number() over(), ' if mode=='dryrun' else ''
  body+=q('INSERT INTO tb_contas('+idcol+"nome_conta,tipo_titular,documento,documento_pendente,nome_titular,email_principal,telefone_principal,status) SELECT "+idval+"x->>'nome_empresa','PJ',NULL,true,x->>'nome_empresa',nullif(x->>'email',''),nullif(x->>'telefone',''),'PENDENTE' FROM ("+items+")s RETURNING id_conta")+'if(q.recordCount!='+str(n)+')throw(message="Account count mismatch");'
  body+=q("INSERT INTO tb_conta_perfis_publicos(id_conta,origem,id_origem,logo_path,dados,data_pesquisa) SELECT c.id_conta,'ABRACEO',x->>'id_filiado',x->>'logo_path',x->'dados','2026-10-11'::date FROM ("+items+")s JOIN tb_contas c ON c.nome_conta=x->>'nome_empresa' AND c.documento_pendente RETURNING id_conta")+'if(q.recordCount!='+str(n)+')throw(message="Profile count mismatch");'
  idcol='id_conta_evento,' if mode=='dryrun' else '';idval='-1000-row_number() over(), ' if mode=='dryrun' else ''
  # Automated evidence import has no human actor. Do not attribute it to a prior user's ID.
  body+=q('INSERT INTO tb_conta_eventos('+idcol+"id_conta,id_evento,status,usuario_cadastro) SELECT "+idval+"p.id_conta,(x->>'id_evento')::int,'ATIVO',NULL FROM ("+evitems+")s JOIN tb_conta_perfis_publicos p ON p.origem='ABRACEO' AND p.id_origem=x->>'id_filiado' RETURNING id_conta_evento")+'if(q.recordCount!='+str(ne)+')throw(message="Event link count mismatch");'
  body+=q("SELECT coalesce(jsonb_agg(jsonb_build_object('id_conta',c.id_conta,'id_filiado',p.id_origem,'nome_conta',c.nome_conta,'status',c.status,'documento',c.documento,'logo_path',p.logo_path) ORDER BY p.id_origem),'[]')::text payload FROM tb_contas c JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE c.documento_pendente")+'report={accounts=deserializeJSON(q.payload[1]),new_accounts='+str(n)+',new_events='+str(ne)+',constraint_checks=8};'
  if mode=='dryrun':body+='transaction action="rollback";'
  body+='}'
  result=bridge(root,body);(stage/(mode+'.json')).write_text(json.dumps(result))
  if mode=='dryrun':assert snap(root)==old,'Dry run did not restore baseline'
  return result
 if mode=='publish':
  assert (stage/'commit.json').exists();baseline(root,p)
  ref=(root/next(iter(p['before']))).stat()
  written=[]
  try:
   for name,b in p['files'].items():
    target=root/name;target.parent.mkdir(parents=True,exist_ok=True);temp=target.with_name(target.name+'.abraceo-review-new')
    with temp.open('xb') as f:f.write(base64.b64decode(b))
    os.chmod(temp,0o644);os.chown(temp,ref.st_uid,ref.st_gid);os.replace(temp,target);written.append(name)
   for name,b in p['files'].items():assert (root/name).read_bytes()==base64.b64decode(b),'Publication mismatch '+name
  except Exception:
   for name in reversed(written):
    target=root/name
    assert target.read_bytes()==base64.b64decode(p['files'][name]),'Concurrent change during recovery: '+name
    if name in p['before']:
     temp=target.with_name(target.name+'.abraceo-restore');shutil.copy2(stage/'baseline'/name,temp);os.chown(temp,ref.st_uid,ref.st_gid);os.replace(temp,target)
    else:target.unlink()
   raise
  return {'published_files':len(p['files']),'backup':str(stage)}
 if mode=='verify':
  for n,b in p['files'].items():assert (root/n).read_bytes()==base64.b64decode(b),'File mismatch '+n
  old=json.loads((stage/'database-before.json').read_text());now=snap(root)
  for key in ['accounts','profiles','links']:
   idkey={'accounts':'id_conta','profiles':'id_conta','links':'id_conta_evento'}[key];current={x[idkey]:x for x in now[key]}
   assert all(current[x[idkey]]==x for x in old[key]),'Existing state changed '+key
  for k in ['users','eligibility','vouchers','grants']:assert now[k]==old[k],'Access baseline changed '+k
  assert len(now['accounts'])==103 and len(now['profiles'])==88 and len(now['links'])-len(old['links'])==47
  check=lower(bridge(root,q("SELECT count(*) n FROM tb_contas c WHERE documento_pendente AND status='PENDENTE' AND tipo_titular='PJ' AND documento IS NULL AND NOT EXISTS(SELECT 1 FROM tb_conta_usuarios u WHERE u.id_conta=c.id_conta)")+'report={pending_without_members=q.n[1]};'));assert check['pending_without_members']==47
  result={'new_accounts':47,'new_future_links':47,'new_account_users':0,'existing_accounts_preserved':56,'existing_profiles_preserved':41,'existing_study_access_preserved':True,'total_abraceo_profiles':88,'logos_verified':47,'files_verified':len(p['files'])};(stage/'verified.json').write_text(json.dumps(result));return result
 raise ValueError(mode)
def main():
 mode=sys.argv[1]
 if mode=='--remote':
  p=json.load(sys.stdin);exec(p.pop('bridge_source'),globals());print(json.dumps(remote(sys.argv[2],p)));return
 p=json.loads((OUT/'payload.json').read_text()) if mode=='prepare' else {}
 src=(ROOT/'_codex/scripts/deploy_estudo.py').read_text();p['bridge_source']=src[src.index('def bridge('):src.index('\ndef raw_query(')]
 source=Path(__file__).read_text().replace('ROOT=Path(__file__).resolve().parents[3]',"ROOT=Path('/var/www/business.roadrunners.run')",1)
 args=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)+' --remote '+shlex.quote(mode)]
 r=subprocess.run(args,input=json.dumps(p),capture_output=True,text=True,timeout=180)
 if r.returncode:raise SystemExit(r.stderr[-5000:])
 data=json.loads(r.stdout);(OUT/('release-'+mode+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2));print(json.dumps(data if mode not in ['dryrun','commit'] else {k:v for k,v in data.items() if k.lower()!='accounts'},ensure_ascii=False))
if __name__=='__main__':main()
