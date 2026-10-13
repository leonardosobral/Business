from pathlib import Path
import base64,hashlib,json,os,shlex,shutil,subprocess,sys,tempfile
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
STAGE='/var/backups/business-abraceo-revisao8-20261011'
def q(sql):return 'q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{}, {datasource="runner_dba",timeout=45});'
def sqljson(data):return "convert_from(decode('"+base64.b64encode(json.dumps(data,ensure_ascii=False).encode()).decode()+"','base64'),'UTF8')::jsonb"
def lower(d):return {k.lower():v for k,v in d.items()}
def snapshot():
 return "SELECT jsonb_build_object('accounts',(SELECT jsonb_agg(to_jsonb(c) ORDER BY id_conta) FROM tb_contas c),'profiles',(SELECT jsonb_agg(to_jsonb(p) ORDER BY id_conta) FROM tb_conta_perfis_publicos p),'links',(SELECT jsonb_agg(to_jsonb(e) ORDER BY id_conta_evento) FROM tb_conta_eventos e),'eligibility',(SELECT jsonb_agg(to_jsonb(e) ORDER BY id_conta) FROM estudo.primeiro_acesso_empresas e),'users',(SELECT md5(coalesce(jsonb_agg(to_jsonb(u) ORDER BY id_conta_usuario)::text,'[]')) FROM tb_conta_usuarios u),'vouchers',(SELECT md5(coalesce(jsonb_agg(to_jsonb(v) ORDER BY id)::text,'[]')) FROM estudo.vouchers v),'grants',(SELECT md5(coalesce(jsonb_agg(to_jsonb(a) ORDER BY id)::text,'[]')) FROM estudo.acessos a),'claims',(SELECT md5(coalesce(jsonb_agg(to_jsonb(r))::text,'[]')) FROM estudo.primeiro_acesso_representantes r))::text payload"
def snap(root):
 sql="SELECT substring(s.payload from i for 32000) part FROM ("+snapshot()+")s CROSS JOIN LATERAL generate_series(1,length(s.payload),32000) i ORDER BY i"
 return json.loads(lower(bridge(root,q(sql)+'s="";for(row in q)s &= row.part;report={snapshot=s};'))['snapshot'])
def baseline(root,p,published=False):
 for n,h in p['hashes'].items():assert hashlib.sha256((root/n).read_bytes()).hexdigest()==h,'Runtime baseline conflict: '+n
 for n,b in p['files'].items():
  target=root/n;assert not target.is_symlink()
  if published:assert target.read_bytes()==base64.b64decode(b),'Logo differs: '+n
  else:assert not target.exists(),'Logo already exists: '+n

def remote(mode,p):
 root=Path('/var/www/business.roadrunners.run');stage=Path(STAGE)
 if mode=='prepare':
  baseline(root,p);state=snap(root);assert len(state['profiles'])==88 and len(state['accounts'])==103 and len(state['eligibility'])==88
  stage.mkdir(mode=0o700,parents=True,exist_ok=False)
  for n,b in p['files'].items():
   t=stage/'candidate'/n;t.parent.mkdir(parents=True,exist_ok=True);t.write_bytes(base64.b64decode(b))
  (stage/'payload.json').write_text(json.dumps(p));(stage/'database-before.json').write_text(json.dumps(state))
  return {'backup':STAGE,'before_accounts':103,'before_abraceo':88,'logos_prepared':len(p['files'])}
 p=json.loads((stage/'payload.json').read_text());old=json.loads((stage/'database-before.json').read_text())
 if mode in ['dryrun','commit']:
  baseline(root,p,mode=='commit');assert snap(root)==old,'Database baseline changed'
  if mode=='commit':assert (stage/'dryrun.json').exists() and (stage/'published.json').exists() and not (stage/'commit.json').exists()
  n=len(p['rows']);ne=len(p['events']);items="SELECT x FROM jsonb_array_elements("+sqljson(p['rows'])+") x";evitems="SELECT x FROM jsonb_array_elements("+sqljson(p['events'])+") x";ids=','.join(str(e['id_evento']) for e in p['events'])
  body='transaction {'+q("SET LOCAL lock_timeout='3s'")+q('LOCK TABLE tb_contas,tb_conta_perfis_publicos,tb_conta_eventos,estudo.primeiro_acesso_empresas IN SHARE ROW EXCLUSIVE MODE')
  body+=q("SELECT count(*) n FROM tb_contas c JOIN ("+items+") s ON lower(trim(c.nome_conta))=lower(x->>'nome_empresa') OR c.documento=x->'dados'->>'cnpj_pesquisado' OR lower(trim(c.email_principal))=lower(x->>'email')")+'if(q.n[1]!=0)throw(message="Possible duplicate account");'
  body+=q("SELECT count(*) n FROM tb_conta_perfis_publicos p JOIN ("+items+")s ON p.origem='ABRACEO' AND p.id_origem=x->>'id_filiado'")+'if(q.n[1]!=0)throw(message="Existing affiliate");'
  body+=q("SELECT count(*) n FROM tb_evento_corridas e JOIN ("+evitems+")s ON e.id_evento=(x->>'id_evento')::int WHERE e.ativo=true AND e.data_inicial::date>'2026-10-11' AND e.data_inicial::date=(x->>'data_inicial')::date")+'if(q.n[1]!='+str(ne)+')throw(message="Future event changed");'
  body+=q('SELECT count(*) n FROM tb_conta_eventos WHERE id_evento IN ('+ids+')')+'if(q.n[1]!=0)throw(message="Existing event link");'
  idcol='id_conta,' if mode=='dryrun' else '';idval='-12000-row_number() over(), ' if mode=='dryrun' else ''
  body+=q('INSERT INTO tb_contas('+idcol+"nome_conta,tipo_titular,documento,documento_pendente,nome_titular,email_principal,telefone_principal,status) SELECT "+idval+"x->>'nome_empresa','PJ',NULL,true,x->>'nome_empresa',x->>'email',nullif(x->>'telefone',''),'PENDENTE' FROM ("+items+")s RETURNING id_conta")+'if(q.recordCount!='+str(n)+')throw(message="Account count mismatch");'
  body+=q("INSERT INTO tb_conta_perfis_publicos(id_conta,origem,id_origem,logo_path,dados,data_pesquisa) SELECT c.id_conta,'ABRACEO',x->>'id_filiado',x->>'logo_path',x->'dados','2026-10-11'::date FROM ("+items+")s JOIN tb_contas c ON c.nome_conta=x->>'nome_empresa' AND c.documento_pendente RETURNING id_conta")+'if(q.recordCount!='+str(n)+')throw(message="Profile count mismatch");'
  body+=q("INSERT INTO estudo.primeiro_acesso_empresas(id_conta,ativo) SELECT p.id_conta,true FROM tb_conta_perfis_publicos p JOIN ("+items+")s ON p.origem='ABRACEO' AND p.id_origem=x->>'id_filiado' RETURNING id_conta")+'if(q.recordCount!='+str(n)+')throw(message="Eligibility count mismatch");'
  idcol='id_conta_evento,' if mode=='dryrun' else '';idval='-12000-row_number() over(), ' if mode=='dryrun' else ''
  body+=q('INSERT INTO tb_conta_eventos('+idcol+"id_conta,id_evento,status,usuario_cadastro) SELECT "+idval+"p.id_conta,(x->>'id_evento')::int,'ATIVO',NULL FROM ("+evitems+")s JOIN tb_conta_perfis_publicos p ON p.origem='ABRACEO' AND p.id_origem=x->>'id_filiado' RETURNING id_conta_evento")+'if(q.recordCount!='+str(ne)+')throw(message="Event link count mismatch");'
  body+=q("SELECT jsonb_agg(jsonb_build_object('id_conta',c.id_conta,'id_filiado',p.id_origem,'nome_conta',c.nome_conta,'status',c.status,'logo_path',p.logo_path) ORDER BY p.id_origem)::text payload FROM tb_contas c JOIN tb_conta_perfis_publicos p USING(id_conta) JOIN ("+items+")s ON p.id_origem=x->>'id_filiado' AND p.origem='ABRACEO'")+'report={accounts=deserializeJSON(q.payload[1]),created='+str(n)+',events='+str(ne)+'};'
  if mode=='dryrun':body+='transaction action="rollback";'
  result=lower(bridge(root,body+'}'));(stage/(mode+'.json')).write_text(json.dumps(result))
  if mode=='dryrun':assert snap(root)==old,'Dry run changed state'
  return result
 if mode=='publish':
  baseline(root,p);assert (stage/'dryrun.json').exists() and not (stage/'published.json').exists()
  ref=(root/old['profiles'][0]['logo_path'].lstrip('/')).stat()
  for n,b in p['files'].items():
   target=root/n;temp=target.with_name(target.name+'.abraceo-eight-new')
   with temp.open('xb') as f:f.write(base64.b64decode(b))
   os.chmod(temp,0o644);os.chown(temp,ref.st_uid,ref.st_gid);os.replace(temp,target)
  baseline(root,p,True);(stage/'published.json').write_text(json.dumps({'logos':len(p['files'])}));return {'logos_published':len(p['files'])}
 if mode=='verify':
  baseline(root,p,True);now=snap(root)
  for key,idkey in [('accounts','id_conta'),('profiles','id_conta'),('links','id_conta_evento'),('eligibility','id_conta')]:
   cur={x[idkey]:x for x in now[key]};assert all(cur[x[idkey]]==x for x in old[key]),'Existing state altered: '+key
   assert len(now[key])-len(old[key])==(len(p['events']) if key=='links' else len(p['rows']))
  for k in ['users','vouchers','grants','claims']:assert now[k]==old[k],'Access changed: '+k
  oldids={r['id_conta'] for r in old['accounts']};new=[r for r in now['accounts'] if r['id_conta'] not in oldids]
  assert all(r['documento'] is None and r['documento_pendente'] and r['status']=='PENDENTE' and r['tipo_titular']=='PJ' for r in new)
  result={'created':len(new),'new_future_links':len(p['events']),'abraceo_profiles':len(now['profiles']),'eligible':len(now['eligibility']),'existing_rows_preserved':True,'permissions_preserved':True,'logos_verified':len(p['files'])}
  (stage/'verified.json').write_text(json.dumps(result));(stage/'database-after.json').write_text(json.dumps(now));return result
 raise ValueError(mode)
def main():
 mode=sys.argv[1]
 if mode=='--remote':
  p=json.load(sys.stdin);exec(p.pop('bridge_source'),globals());print(json.dumps(remote(sys.argv[2],p)));return
 p=json.loads((OUT/'payload.json').read_text()) if mode=='prepare' else {}
 src=(ROOT/'_codex/scripts/deploy_estudo.py').read_text();p['bridge_source']=src[src.index('def bridge('):src.index('\ndef raw_query(')]
 source=Path(__file__).read_text().replace('ROOT=Path(__file__).resolve().parents[3]',"ROOT=Path('/var/www/business.roadrunners.run')",1).replace('OUT=Path(__file__).resolve().parent',"OUT=Path(STAGE)".replace('STAGE',repr(STAGE)),1)
 args=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)+' --remote '+shlex.quote(mode)]
 r=subprocess.run(args,input=json.dumps(p),capture_output=True,text=True,timeout=150)
 if r.returncode:raise SystemExit(r.stderr[-3500:])
 data=json.loads(r.stdout);dest=OUT/('release-'+mode+'.json');dest.write_text(json.dumps(data,ensure_ascii=False,indent=2));dest.chmod(0o600);print(json.dumps({k:v for k,v in data.items() if k!='accounts'}))
if __name__=='__main__':main()
