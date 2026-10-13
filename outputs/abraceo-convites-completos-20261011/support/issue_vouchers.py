from pathlib import Path
import base64,hashlib,json,os,pwd,shlex,shutil,subprocess,sys,tempfile

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
STAGE='/var/backups/business-abraceo-vouchers-finais-20261011'
LINK='https://business.roadrunners.run/estudos/primeiro-acesso/'
STATE_SQL="""SELECT jsonb_build_object(
 'accounts',(SELECT md5(coalesce(jsonb_agg(to_jsonb(c) ORDER BY c.id_conta)::text,'[]')) FROM tb_contas c JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE p.origem='ABRACEO'),
 'memberships',(SELECT md5(coalesce(jsonb_agg(to_jsonb(u) ORDER BY u.id_conta_usuario)::text,'[]')) FROM tb_conta_usuarios u JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE p.origem='ABRACEO'),
 'events',(SELECT md5(coalesce(jsonb_agg(to_jsonb(e) ORDER BY e.id_conta_evento)::text,'[]')) FROM tb_conta_eventos e JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE p.origem='ABRACEO'),
 'grants',(SELECT count(*) FROM estudo.acessos),
 'claims',(SELECT count(*) FROM estudo.primeiro_acesso_representantes))::text payload"""
def enc(s):return base64.b64encode(s.encode()).decode()
def query(sql):return 'q=queryExecute(toString(binaryDecode("'+enc(sql)+'","base64")),{}, {datasource="runner_dba",timeout=30});'
def normal(x):
 if isinstance(x,dict):return {k.lower():normal(v) for k,v in x.items()}
 if isinstance(x,list):return [normal(v) for v in x]
 return x
def remote(mode,p):
 root=Path('/var/www/business.roadrunners.run');stage=Path(STAGE)
 for n,h in p['hashes'].items():assert hashlib.sha256((root/n).read_bytes()).hexdigest()==h,'Service baseline changed'
 if mode=='prepare':
  if stage.exists():assert not any(stage.iterdir()),'Existing batch: inspect before continuing'
  else:stage.mkdir(mode=0o700,exist_ok=False)
  body=query(STATE_SQL)+'report={state=deserializeJSON(q.payload[1])};'
  body+=query("SELECT coalesce(jsonb_agg(to_jsonb(v)),'[]')::text payload FROM estudo.vouchers v JOIN estudo.campanhas c ON c.id=v.campanha_id WHERE c.codigo='abraceo-primeiro-acesso'")+'report.vouchers=deserializeJSON(q.payload[1]);'
  body+=query("SELECT c.id_conta,coalesce(c.documento,'') documento,c.status,e.ativo,p.id_origem FROM tb_contas c JOIN estudo.primeiro_acesso_empresas e USING(id_conta) JOIN tb_conta_perfis_publicos p USING(id_conta) ORDER BY c.id_conta")+'report.companies=[];for(r in q)arrayAppend(report.companies,{id_conta=r.id_conta,cnpj=r.documento,status=r.status,ativo=r.ativo});'
  before=normal(bridge(root,body));(stage/'before.json').write_text(json.dumps(before));(stage/'input.json').write_text(json.dumps(p))
  active={r['email_destinatario'] for r in before['vouchers'] if r['status'] in ['READY','REDEEMED']}
  companies={str(r['id_conta']):r for r in before['companies']}
  eligible=[];pending=[]
  for r in p['contacts']:
   if r['status']!='APTO':pending.append(r);continue
   c=companies.get(str(r['id_conta']))
   assert c and c['cnpj']==(r['cnpj'] or '') and c['ativo'] and c['status']=='PENDENTE','Company eligibility changed'
   if r['email'] in active:
    pending.append(dict(r,status='PENDENTE',motivo='Já há voucher nesta campanha; código anterior não pode ser recuperado do hash'));continue
   eligible.append(r)
  assert len({r['email'] for r in eligible})==len(eligible),'Duplicate recipients'
  (stage/'eligible.json').write_text(json.dumps(eligible));(stage/'pending.json').write_text(json.dumps(pending))
  return {'eligible':len(eligible),'pending':pending,'baseline_saved':True}
 if mode=='issue':
  assert not (stage/'codes.json').exists() and not (stage/'code-recovery-path.txt').exists(),'Existing issuance attempt: verify/recover, do not reissue'
  rows=json.loads((stage/'eligible.json').read_text());before=json.loads((stage/'before.json').read_text())
  private=Path(tempfile.mkdtemp(prefix='abraceo-voucher-codes-',dir='/var/tmp'))
  owner=pwd.getpwnam('coldfusion');os.chown(private,owner.pw_uid,owner.pw_gid);os.chmod(private,0o700)
  (stage/'code-recovery-path.txt').write_text(str(private/'codes.json'))
  body=query(STATE_SQL)+'current=deserializeJSON(q.payload[1]);expected=deserializeJSON(toString(binaryDecode("'+enc(json.dumps(before['state']))+'","base64")));for(key in expected){if(current[key]!=expected[key])throw(message="Business state changed");}'
  body+='actor=queryExecute("SELECT id,name,lower(trim(email)) email FROM public.tb_usuarios WHERE lower(trim(email))=\'leonardo.sobral@gmail.com\' AND is_admin=true",{}, {datasource="runner_dba"});if(actor.recordCount!=1)throw(message="Authorized operator unavailable");'
  body+='REQUEST.businessIdentity={id=actor.id[1],name=actor.name[1],email=actor.email[1],version=1,sub="authorized-operator-batch-abraceo-20261011"};'
  body+='items=deserializeJSON(toString(binaryDecode("'+enc(json.dumps(rows))+'","base64")));svc=new estudos.includes.FirstAccess().init("runner_dba");issued=[];transaction {'
  body+='for(item in items){v=svc.adminIssue(actor.id[1],"",item.email,item.vence_em,toString(item.id_conta));arrayAppend(issued,{id_conta=item.id_conta,cnpj="",email=item.email,voucher_id=v.voucher.id,voucher=v.code_once,expira_em=v.voucher.expira_em});}'
  body+='fileWrite("'+str(private/'codes.json')+'",serializeJSON(issued),"UTF-8");}report={issued=arrayLen(issued)};'
  result=normal(bridge(root,body));shutil.move(str(private/'codes.json'),stage/'codes.json');private.rmdir();os.chmod(stage/'codes.json',0o600);os.chown(stage/'codes.json',0,0);(stage/'issued.json').write_text(json.dumps(result));return result
 if mode=='verify':
  codes=normal(json.loads((stage/'codes.json').read_text()));before=json.loads((stage/'before.json').read_text())
  body=query(STATE_SQL)+'report={state=deserializeJSON(q.payload[1])};'
  body+=query("SELECT coalesce(jsonb_agg(to_jsonb(v)),'[]')::text payload FROM estudo.vouchers v JOIN estudo.campanhas c ON c.id=v.campanha_id WHERE c.codigo='abraceo-primeiro-acesso'")+'report.current_vouchers=deserializeJSON(q.payload[1]);'
  body+=query("SELECT v.id,v.email_destinatario,v.codigo_hash,v.status,CAST(v.expira_em AT TIME ZONE 'America/Sao_Paulo' AS text) expira_local,x.id_conta,c.codigo,p.codigo produto,c.beneficio_percentual FROM estudo.vouchers v JOIN estudo.primeiro_acesso_convites x ON x.voucher_id=v.id JOIN estudo.campanhas c ON c.id=v.campanha_id JOIN estudo.produtos p ON p.id=c.produto_id WHERE c.codigo='abraceo-primeiro-acesso'")+'report.vouchers=[];for(r in q)arrayAppend(report.vouchers,{id=r.id,email=r.email_destinatario,hash=r.codigo_hash,status=r.status,expires=r.expira_local,company=r.id_conta,campaign=r.codigo,product=r.produto,benefit=r.beneficio_percentual});'
  result=normal(bridge(root,body));assert result['state']==before['state'],'Business state changed'
  live={str(r['id']):r for r in result['vouchers']}
  current={str(r['id']):r for r in result['current_vouchers']}
  assert all(current[str(r['id'])]==r for r in before['vouchers']),'Previous voucher changed'
  for r in codes:
   v=live[str(r['voucher_id'])]
   assert v['hash']==hashlib.sha256(r['voucher'].encode()).hexdigest() and v['email']==r['email'] and str(v['company'])==str(r['id_conta'])
   assert v['status']=='READY' and v['expires']=='2026-11-11 00:00:00' and v['product']=='previa-2026-q3' and v['benefit']==0
  assert len(codes)==len(json.loads((stage/'eligible.json').read_text()))
  summary={'verified':len(codes),'state_preserved':True,'all_ready':True,'redemption_deadline':'2026-11-10 23:59:59 America/Sao_Paulo'}
  (stage/'verified.json').write_text(json.dumps(summary));return dict(summary,codes=codes,previous_vouchers=[live[str(r['id'])] for r in before['vouchers']])
 raise ValueError(mode)
def main():
 mode=sys.argv[1]
 if mode=='--remote':
  p=json.load(sys.stdin);exec(p.pop('helpers'),globals());print(json.dumps(remote(sys.argv[2],p)));return
 helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text();helpers=helpers[helpers.index('def digest('):helpers.index('\ndef raw_query(')]
 p={'helpers':helpers,'hashes':{n:hashlib.sha256((ROOT/n).read_bytes()).hexdigest() for n in ['estudos/includes/FirstAccess.cfc','estudos/includes/StudyAccess.cfc']}}
 if mode=='prepare':p['contacts']=json.loads((OUT/'contacts.json').read_text())
 source=Path(__file__).read_text().replace('ROOT=Path(__file__).resolve().parents[3]',"ROOT=Path('/var/www/business.roadrunners.run')",1).replace('OUT=Path(__file__).resolve().parent',"OUT=Path('/var/backups/business-abraceo-vouchers-finais-20261011')",1)
 args=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)+' --remote '+shlex.quote(mode)]
 r=subprocess.run(args,input=json.dumps(p),capture_output=True,text=True,timeout=120)
 if r.returncode:raise SystemExit(r.stderr[-3000:])
 result=json.loads(r.stdout);dest=OUT/(mode+'.json');dest.write_text(json.dumps(result,ensure_ascii=False,indent=2));dest.chmod(0o600)
 print(json.dumps({k:v for k,v in result.items() if k not in ['codes','previous_vouchers']},ensure_ascii=False))
if __name__=='__main__':main()
