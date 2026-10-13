from pathlib import Path
import base64,hashlib,json,os,shlex,shutil,subprocess,sys,tempfile
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).parent
STAGE='/var/backups/business-abraceo-contatos-finais-20261011'
def query(sql):return 'q=queryExecute(toString(binaryDecode("'+base64.b64encode(sql.encode()).decode()+'","base64")),{}, {datasource="runner_dba",timeout=30});'
def norm(x):
 if isinstance(x,dict):return {k.lower():norm(v) for k,v in x.items()}
 if isinstance(x,list):return [norm(v) for v in x]
 return x
STATE="""SELECT jsonb_build_object(
 'accounts_unchanged',(SELECT md5(jsonb_agg(CASE WHEN c.id_conta IN(45,89) THEN to_jsonb(c)-'email_principal'-'data_atualizacao' ELSE to_jsonb(c) END ORDER BY c.id_conta)::text) FROM tb_contas c),
 'profiles_unchanged',(SELECT md5(jsonb_agg(CASE WHEN p.id_conta IN(45,89) THEN to_jsonb(p)||jsonb_build_object('dados',p.dados-'email_publico'-'revisao_contato_convite') ELSE to_jsonb(p) END ORDER BY p.id_conta)::text) FROM tb_conta_perfis_publicos p),
 'memberships',(SELECT md5(coalesce(jsonb_agg(to_jsonb(u) ORDER BY id_conta_usuario)::text,'[]')) FROM tb_conta_usuarios u),
 'events',(SELECT md5(coalesce(jsonb_agg(to_jsonb(e) ORDER BY id_conta_evento)::text,'[]')) FROM tb_conta_eventos e),
 'vouchers',(SELECT md5(coalesce(jsonb_agg(to_jsonb(v) ORDER BY id)::text,'[]')) FROM estudo.vouchers v),
 'access',(SELECT md5(coalesce(jsonb_agg(to_jsonb(a) ORDER BY id)::text,'[]')) FROM estudo.acessos a),
 'claims',(SELECT md5(coalesce(jsonb_agg(to_jsonb(a) ORDER BY id)::text,'[]')) FROM estudo.primeiro_acesso_representantes a),
 'targets',(SELECT jsonb_agg(jsonb_build_object('account',to_jsonb(c),'profile',to_jsonb(p)) ORDER BY c.id_conta) FROM tb_contas c JOIN tb_conta_perfis_publicos p USING(id_conta) WHERE c.id_conta IN(45,89)),
 'eligibility',(SELECT jsonb_agg(to_jsonb(e) ORDER BY id_conta) FROM estudo.primeiro_acesso_empresas e)
)::text payload"""
def snapshot(root):return norm(bridge(root,query(STATE)+'report=deserializeJSON(q.payload[1]);'))
def remote(mode,rows):
 root=Path('/var/www/business.roadrunners.run');stage=Path(STAGE)
 if mode=='prepare':
  assert not stage.exists();before=snapshot(root);targets={r['account']['id_conta']:r for r in before['targets']}
  assert targets[45]['account']['email_principal']=='__morro@morro-mt.com.br'
  assert not targets[89]['account']['email_principal']
  assert all(t['profile']['origem']=='ABRACEO' and t['account']['status']=='PENDENTE' for t in targets.values())
  assert targets[89]['account']['documento'] is None and targets[45]['account']['documento']=='18305726000106'
  assert len(before['eligibility'])==87 and 89 not in {r['id_conta'] for r in before['eligibility']}
  stage.mkdir(mode=0o700);(stage/'before.json').write_text(json.dumps(before));(stage/'contacts.json').write_text(json.dumps(rows))
  return {'backed_up_accounts':2,'eligible_before':87,'backup':str(stage)}
 before=json.loads((stage/'before.json').read_text());rows=json.loads((stage/'contacts.json').read_text())
 if mode=='apply':
  assert not (stage/'applied.json').exists();assert snapshot(root)==before,'Concurrent database change'
  body='transaction {'+query("SET LOCAL lock_timeout='3s'")+query('LOCK TABLE tb_contas,tb_conta_perfis_publicos,estudo.primeiro_acesso_empresas IN SHARE ROW EXCLUSIVE MODE')
  for r in rows:
   i=int(r['id_conta']);assert i in [45,89]
   data={'email_anterior':r['email_business'],'email_confirmado':r['email'],'fonte':r['fonte'],'verificado_em':'2026-10-11','evidencia':r['motivo'],'entrega_testada':False}
   enc=base64.b64encode(json.dumps(data,ensure_ascii=False).encode()).decode()
   body+=query("UPDATE tb_contas SET email_principal='"+r['email']+"',data_atualizacao=now() WHERE id_conta="+str(i)+" AND coalesce(email_principal,'')='"+r['email_business']+"' RETURNING id_conta")+'if(q.recordCount!=1)throw(message="Contact baseline changed");'
   body+=query("UPDATE tb_conta_perfis_publicos SET dados=dados||jsonb_build_object('email_publico','"+r['email']+"','revisao_contato_convite',convert_from(decode('"+enc+"','base64'),'UTF8')::jsonb) WHERE origem='ABRACEO' AND id_conta="+str(i)+" RETURNING id_conta")+'if(q.recordCount!=1)throw(message="Profile baseline changed");'
  body+=query('INSERT INTO estudo.primeiro_acesso_empresas(id_conta) VALUES(89) RETURNING id_conta')+'if(q.recordCount!=1)throw(message="Eligibility count mismatch");}report={contacts_updated=2,eligibility_added=1};'
  result=norm(bridge(root,body));(stage/'applied.json').write_text(json.dumps(result));return result
 if mode=='verify':
  now=snapshot(root)
  for k in ['accounts_unchanged','profiles_unchanged','memberships','events','vouchers','access','claims']:assert now[k]==before[k],k+' changed outside scope'
  assert len(now['eligibility'])==88
  assert all(r in now['eligibility'] for r in before['eligibility'])
  targets={r['account']['id_conta']:r for r in now['targets']}
  for r in rows:
   t=targets[r['id_conta']];assert t['account']['email_principal']==r['email'] and t['profile']['dados']['email_publico']==r['email']
   assert t['profile']['dados']['revisao_contato_convite']['fonte']==r['fonte']
  result={'contacts_verified':2,'eligible_total':88,'outside_scope_preserved':True};(stage/'verified.json').write_text(json.dumps(result));return result
 raise ValueError(mode)
def main():
 if sys.argv[1]=='--remote':
  p=json.load(sys.stdin);exec(p['helpers'],globals());print(json.dumps(remote(sys.argv[2],p['rows'])));return
 s=(ROOT/'_codex/scripts/deploy_estudo.py').read_text();p={'helpers':s[s.index('def bridge('):s.index('\ndef raw_query(')],'rows':json.loads((OUT/'contacts.json').read_text())}
 source=Path(__file__).read_text().replace('ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).parent',"ROOT=Path('/var/www/business.roadrunners.run');OUT=ROOT",1)
 cmd=['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(source)+' --remote '+shlex.quote(sys.argv[1])]
 r=subprocess.run(cmd,input=json.dumps(p),text=True,capture_output=True,timeout=120)
 if r.returncode:raise SystemExit(r.stderr[-2500:])
 result=json.loads(r.stdout);(OUT/('contact-'+sys.argv[1]+'.json')).write_text(json.dumps(result,indent=2));print(json.dumps(result))
if __name__=='__main__':main()
