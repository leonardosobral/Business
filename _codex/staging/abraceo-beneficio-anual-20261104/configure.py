from inspect import remote,W
import json,base64,sys
mode=sys.argv[1];before=json.loads((W/'benefit-before.json').read_text());campaign=before['campaign'];cid=campaign['id'];annual=before['annual']['id'];actor=before['actor']['id'];version=campaign['version']
encoded=base64.b64encode(json.dumps(campaign,ensure_ascii=False).encode()).decode()
cf=r'''
function benefitDb(required string sql,struct params={}){var x=queryExecute(sql,params,{datasource='runner_dba',timeout=30});return isNull(local.x)?queryNew(''):x;}
function bp(required any v,string t='cf_sql_varchar'){return{value=v,cfsqltype=t};}
function requiredCheck(required boolean yes,required string message){if(!yes)throw(message=message);}
function configureBenefit(){
 var result={};
 transaction {
  var staff=benefitDb("SELECT u.id FROM public.tb_usuarios u LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id WHERE u.id=:a AND coalesce(u.is_admin,false) AND coalesce(g.ativo,true) AND NOT coalesce(g.excluido,false)",{a=bp(ACTOR_ID,'cf_sql_bigint')});requiredCheck(staff.recordCount==1,'Approved administrator unavailable');
  var expected=toString(binaryDecode('EXPECTED_JSON','base64'));
  var current=benefitDb("SELECT c.id,c.version,md5(to_jsonb(c)::text)=md5(CAST(:expected AS jsonb)::text) AS matches FROM estudo.campanhas c WHERE c.id=:c AND c.codigo='abraceo-primeiro-acesso' FOR UPDATE OF c",{c=bp(CAMPAIGN_ID,'cf_sql_bigint'),expected=bp(expected,'cf_sql_longvarchar')});
  requiredCheck(current.recordCount==1 && current.matches[1],'Campaign changed after review');
  var annual=benefitDb("SELECT id FROM estudo.produtos WHERE id=:p AND codigo='anual-2026' AND tipo='ANUAL' AND ano=2026 FOR SHARE",{p=bp(ANNUAL_ID,'cf_sql_bigint')});requiredCheck(annual.recordCount==1,'Annual target changed');
  var wrong=benefitDb("SELECT count(*) AS n FROM estudo.acessos a JOIN estudo.vouchers v ON v.id=a.voucher_id JOIN estudo.beneficios b ON b.acesso_id=a.id WHERE v.campanha_id=:c AND (b.usuario_id<>a.usuario_id OR b.produto_id<>:p OR b.percentual<>50)",{c=bp(CAMPAIGN_ID,'cf_sql_bigint'),p=bp(ANNUAL_ID,'cf_sql_bigint')});requiredCheck(wrong.n[1]==0,'Existing benefits need manual review');
  var changed=benefitDb("UPDATE estudo.campanhas SET beneficio_percentual=50,beneficio_produto_id=:p,version=version+1,atualizado_por=:a,atualizado_em=clock_timestamp() WHERE id=:c AND version=:v AND beneficio_percentual=0 AND beneficio_produto_id IS NULL RETURNING id,version",{p=bp(ANNUAL_ID,'cf_sql_bigint'),a=bp(ACTOR_ID,'cf_sql_bigint'),c=bp(CAMPAIGN_ID,'cf_sql_bigint'),v=bp(EXPECTED_VERSION,'cf_sql_integer')});requiredCheck(changed.recordCount==1,'Campaign update conflict');
  var note={"before":deserializeJSON(expected),"after":{"benefit_percent":50,"annual_product_id":ANNUAL_ID,"annual_product_code":"anual-2026"},"kind":"EARLY_PURCHASE","reason":"Solicitação do responsável em 04/11/2026: resgate ABRACEO dá direito à compra antecipada do anual de 2026 com 50% de desconto."};
  benefitDb("INSERT INTO estudo.auditoria_comercial(ator_id,acao,entidade,entidade_id,detalhes) VALUES(:a,'CAMPAIGN_ANNUAL_BENEFIT','campaign',:c,CAST(:d AS jsonb))",{a=bp(ACTOR_ID,'cf_sql_bigint'),c=bp(CAMPAIGN_ID,'cf_sql_bigint'),d=bp(serializeJSON(note),'cf_sql_longvarchar')});
  var filled=benefitDb("WITH inserted AS (
   INSERT INTO estudo.beneficios(usuario_id,produto_id,acesso_id,percentual)
   SELECT a.usuario_id,c.beneficio_produto_id,a.id,50 FROM estudo.acessos a JOIN estudo.vouchers v ON v.id=a.voucher_id JOIN estudo.campanhas c ON c.id=v.campanha_id
   WHERE c.id=:c AND c.beneficio_percentual=50 AND a.produto_id=c.produto_id AND a.status='ACTIVE' AND v.status='REDEEMED' AND v.resgatado_por=a.usuario_id
     AND NOT EXISTS(SELECT 1 FROM estudo.beneficios b WHERE b.acesso_id=a.id)
   ON CONFLICT(acesso_id) DO NOTHING RETURNING id,usuario_id,produto_id,acesso_id
  ), audited AS (
   INSERT INTO estudo.auditoria_comercial(ator_id,acao,entidade,entidade_id,detalhes)
   SELECT :a,'ANNUAL_BENEFIT_BACKFILL','benefit',i.id,jsonb_build_object('access_id',i.acesso_id,'campaign_id',:c,'annual_product_id',i.produto_id,'percent',50,'kind','EARLY_PURCHASE') FROM inserted i RETURNING entidade_id
  ) SELECT i.id,i.acesso_id FROM inserted i JOIN audited x ON x.entidade_id=i.id",{c=bp(CAMPAIGN_ID,'cf_sql_bigint'),a=bp(ACTOR_ID,'cf_sql_bigint')});
  var missing=benefitDb("SELECT count(*) AS n FROM estudo.acessos a JOIN estudo.vouchers v ON v.id=a.voucher_id WHERE v.campanha_id=:c AND a.status='ACTIVE' AND v.status='REDEEMED' AND v.resgatado_por=a.usuario_id AND NOT EXISTS(SELECT 1 FROM estudo.beneficios b WHERE b.acesso_id=a.id)",{c=bp(CAMPAIGN_ID,'cf_sql_bigint')});requiredCheck(missing.n[1]==0,'Active redeemed grants still missing benefits');
  result={"campaign_id":CAMPAIGN_ID,"campaign_version":changed.version[1],"annual_product":ANNUAL_ID,"benefit_percent":50,"backfilled":filled.recordCount,"active_grants_missing_benefit":missing.n[1]};
 }
 return result;
}
'''.replace('ACTOR_ID',str(actor)).replace('CAMPAIGN_ID',str(cid)).replace('ANNUAL_ID',str(annual)).replace('EXPECTED_VERSION',str(version)).replace('EXPECTED_JSON',encoded)
if mode=='dry-run':
 cf+=r'''
fixtureIds=[];
transaction {
 var users=benefitDb("SELECT u.id,u.email FROM public.tb_usuarios u WHERE u.id>0 AND NOT coalesce(u.is_admin,false) AND length(trim(u.email))>3 AND NOT EXISTS(SELECT 1 FROM estudo.vouchers v WHERE v.campanha_id=:c AND v.email_destinatario=lower(btrim(u.email))) ORDER BY u.id LIMIT 2",{c=bp(CID,'cf_sql_bigint')});requiredCheck(users.recordCount==2,'QA identities unavailable');
 for(var i=1;i<=2;i++) {
  var v=benefitDb("INSERT INTO estudo.vouchers(campanha_id,codigo_hash,email_destinatario,status,expira_em,criado_por,resgatado_por,resgatado_em) VALUES(:c,:h,:e,'REDEEMED',clock_timestamp()+interval '1 day',:actor,:u,clock_timestamp()) RETURNING id",{c=bp(CID,'cf_sql_bigint'),h=bp(lCase(hash(createUUID(),'SHA-256','UTF-8'))),e=bp(lCase(trim(users.email[i]))),actor=bp(AID,'cf_sql_bigint'),u=bp(users.id[i],'cf_sql_bigint')});
  var grant=benefitDb('INSERT INTO estudo.acessos(usuario_id,produto_id,voucher_id) VALUES(:u,:p,:v) RETURNING id',{u=bp(users.id[i],'cf_sql_bigint'),p=bp(PREVIEW_ID,'cf_sql_bigint'),v=bp(v.id[1],'cf_sql_bigint')});arrayAppend(fixtureIds,grant.id[1]);
  if(i==2) benefitDb("INSERT INTO estudo.beneficios(usuario_id,produto_id,acesso_id,percentual,status,revogado_em,revogado_por) VALUES(:u,:p,:a,50,'REVOKED',clock_timestamp(),:actor)",{u=bp(users.id[i],'cf_sql_bigint'),p=bp(ANID,'cf_sql_bigint'),a=bp(grant.id[1],'cf_sql_bigint'),actor=bp(AID,'cf_sql_bigint')});
 }
 report=configureBenefit();requiredCheck(report.backfilled==1,'Backfill did not insert exactly one missing benefit');
 var states=benefitDb('SELECT acesso_id,status,percentual FROM estudo.beneficios WHERE acesso_id IN (:ids) ORDER BY acesso_id',{ids:{value:arrayToList(fixtureIds),cfsqltype:'cf_sql_bigint',list:true}});
 requiredCheck(states.recordCount==2 && states.status[1]=='ELIGIBLE' && states.percentual[1]==50 && states.status[2]=='REVOKED','Backfill restored revoked benefit or missed eligible access');
 transaction action='rollback';
}
var remaining=benefitDb('SELECT count(*) AS n FROM estudo.acessos WHERE id IN (:ids)',{ids:{value:arrayToList(fixtureIds),cfsqltype:'cf_sql_bigint',list:true}});requiredCheck(remaining.n[1]==0,'Dry-run fixtures persisted');
report['dry_run_rolled_back']=true;report['revoked_benefit_preserved']=true;
'''.replace('CID',str(cid)).replace('AID',str(actor)).replace('ANID',str(annual)).replace('PREVIEW_ID',str(campaign['produto_id'])).replace('var ','')
elif mode=='apply': cf+='report=configureBenefit();'
else:raise SystemExit('Expected dry-run or apply')
body="""stage=Path(payload['stage']);assert (stage/'compile.txt').is_file()
if payload['apply']:
 verify(ROOT,stage)
 (stage/'benefit-before.json').write_text(json.dumps(payload['before'],ensure_ascii=False,indent=2))
result=bridge(ROOT,payload['body'])
if payload['apply']:(stage/'benefit-update.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))"""
r=remote(body,{'stage':'/var/backups/business-abraceo-annual-benefit-20261104','apply':mode=='apply','before':before,'body':cf});(W/('configure-'+mode+'.json')).write_text(json.dumps(r,indent=2));print(r)
