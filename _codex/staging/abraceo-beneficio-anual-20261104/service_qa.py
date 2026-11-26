from inspect import remote,W
import json,base64
study=(W/'runtime/estudos/includes/StudyAccess.cfc').read_text();first=(W/'runtime/estudos/includes/FirstAccess.cfc').read_text()
body=r'''
import secrets
work=Path(tempfile.mkdtemp(prefix='abraceo-benefit-qa-',dir=ROOT/'_codex'));os.chmod(work,0o755);token=secrets.token_hex(24)
try:
 (work/'.htaccess').write_text('Require local\n')
 (work/'StudyAccess.cfc').write_text(payload['study'])
 first=payload['first'].replace("new estudos.includes.StudyAccess().init(datasource)","createObject('component','_codex."+work.name+".StudyAccess').init(datasource)")
 (work/'FirstAccess.cfc').write_text(first)
 (work/'Application.cfc').write_text('component {this.name="'+work.name+'";this.datasource="runner_dba";boolean function onRequestStart(string target){if(!listFind("127.0.0.1,::1",cgi.remote_addr)||cgi.request_method!="POST"||compare(form.key ?: "","'+token+'")!=0){cfheader(statuscode=404);abort;}return true;}}')
 (work/'run.cfm').write_text('<cfsetting requesttimeout="90" showdebugoutput="false"/><cfcontent type="application/json" reset="true"/><cftry><cfscript>'+payload['cf']+'writeOutput(serializeJSON(report));</cfscript><cfcatch><cfheader statuscode="500"/><cfoutput>#serializeJSON({error=cfcatch.message,detail=cfcatch.detail,trace=cfcatch.tagContext})#</cfoutput></cfcatch></cftry>')
 p=subprocess.run(['curl','-sS','--max-time','95','--resolve','business.roadrunners.run:443:127.0.0.1','-X','POST','--data-urlencode','key='+token,'https://business.roadrunners.run/_codex/'+work.name+'/run.cfm'],capture_output=True,text=True,timeout=100)
 result=json.loads(p.stdout)
 if any(k.lower()=='error'for k in result):raise RuntimeError(json.dumps(result))
 print(json.dumps(result))
finally:shutil.rmtree(work)
'''
cf=r'''
function q(required string sql,struct params={}){var x=queryExecute(sql,params,{datasource='runner_dba',timeout=15});return isNull(local.x)?queryNew(''):x;}
function bind(required any v,string t='cf_sql_varchar'){return{value=v,cfsqltype=t};}
function check(required boolean yes,required string message){if(!yes)throw(message=message);}
function identity(required struct u){REQUEST.businessIdentity={id=u.id,email=u.email,version=1,sub='qa-abraceo-benefit'};}
function prepareCampaign(boolean fifty=true){q('UPDATE estudo.campanhas SET beneficio_percentual=:n,beneficio_produto_id=:p WHERE id=:c',{n=bind(fifty?50:0,'cf_sql_integer'),p={value=annual.id[1],cfsqltype='cf_sql_bigint',null=!fifty},c=bind(campaign.id[1],'cf_sql_bigint')});}
function invitation(required struct u,boolean expired=false,boolean revoked=false){var code='BQ26-' & uCase(left(hash(createUUID(),'SHA-256'),32));var v=q("INSERT INTO estudo.vouchers(campanha_id,codigo_hash,email_destinatario,status,expira_em,criado_por) VALUES(:c,:h,:e,:s,clock_timestamp()+CAST(:days AS integer)*interval '1 day',:a) RETURNING id",{c=bind(campaign.id[1],'cf_sql_bigint'),h=bind(lCase(hash(code,'SHA-256','UTF-8'))),e=bind(lCase(trim(u.email))),s=bind(revoked?'REVOKED':'READY'),days=bind(expired?-1:1,'cf_sql_integer'),a=bind(admin.id[1],'cf_sql_bigint')});q('INSERT INTO estudo.primeiro_acesso_convites(voucher_id,id_conta) VALUES(:v,:c)',{v=bind(v.id[1],'cf_sql_bigint'),c=bind(company.id_conta[1],'cf_sql_bigint')});return{code=code,id=toString(v.id[1])};}
function stats(){return q("SELECT (SELECT md5(coalesce(jsonb_agg(to_jsonb(v) ORDER BY v.id)::text,'[]')) FROM estudo.vouchers v JOIN estudo.campanhas c ON c.id=v.campanha_id WHERE c.codigo='abraceo-primeiro-acesso') AS vouchers,(SELECT count(*) FROM estudo.acessos) AS grants,(SELECT count(*) FROM estudo.beneficios) AS benefits,(SELECT count(*) FROM estudo.primeiro_acesso_representantes) AS representatives,(SELECT md5(to_jsonb(c)::text) FROM estudo.campanhas c WHERE codigo='abraceo-primeiro-acesso') AS campaign");}
campaign=q("SELECT id FROM estudo.campanhas WHERE codigo='abraceo-primeiro-acesso'");annual=q("SELECT id FROM estudo.produtos WHERE codigo='anual-2026'");admin=q('SELECT ator_id AS id FROM estudo.auditoria_comercial WHERE id=513');
users=q("SELECT u.id,u.email FROM public.tb_usuarios u LEFT JOIN public.tb_usuarios_gestao g ON g.id_usuario=u.id WHERE u.id>0 AND coalesce(u.is_admin,false)=false AND coalesce(g.ativo,true)=true AND coalesce(g.excluido,false)=false AND length(trim(u.email))>3 AND NOT EXISTS(SELECT 1 FROM estudo.vouchers v WHERE v.campanha_id=:c AND v.email_destinatario=lower(btrim(u.email))) ORDER BY u.id LIMIT 2",{c=bind(campaign.id[1],'cf_sql_bigint')});
check(users.recordCount==2,'Two eligible QA identities unavailable');u={id=users.id[1],email=users.email[1]};other={id=users.id[2],email=users.email[2]};
company=q("SELECT c.id_conta,c.documento FROM estudo.primeiro_acesso_empresas e JOIN public.tb_contas c USING(id_conta) JOIN public.tb_conta_perfis_publicos p USING(id_conta) WHERE e.ativo AND c.tipo_titular='PJ' AND c.status IN ('ATIVA','PENDENTE') AND p.origem='ABRACEO' AND NOT c.documento_pendente AND c.documento ~ '^[0-9]{14}$' ORDER BY c.id_conta LIMIT 1");check(company.recordCount==1,'QA company unavailable');
componentBase='_codex.' & listLast(getDirectoryFromPath(getCurrentTemplatePath()),'/');sa=createObject('component',componentBase & '.StudyAccess').init('runner_dba');fa=createObject('component',componentBase & '.FirstAccess').init('runner_dba');before=stats();identity(u);
transaction {
 prepareCampaign();inv=invitation(u);firstGrant=sa.redeem(u.id,inv.code);
 check(firstGrant.benefit.percentual==50 && firstGrant.benefit.status=='ELIGIBLE' && firstGrant.benefit.produto_codigo=='anual-2026','Voucher benefit failed');
 repeated=sa.redeem(u.id,inv.code);check(repeated.access.id==firstGrant.access.id && repeated.benefit.id==firstGrant.benefit.id,'Repeated redemption duplicated grant/benefit');
 viaFirst=fa.confirm(u.id,'VOUCHER',inv.code,'QA',true);check(viaFirst.benefit.id==firstGrant.benefit.id && !viaFirst.operational_access_granted,'First access voucher mismatch');
 viaCnpj=fa.confirm(u.id,'CNPJ',company.documento[1],'QA',true);check(viaCnpj.benefit.id==firstGrant.benefit.id,'CNPJ repeat mismatch');
 dashboard=sa.dashboard(u.id);for(product in dashboard.products)if(product.codigo=='anual-2026')check(!product.allowed,'Annual reading granted without purchase');
 counts=q('SELECT count(*) AS n FROM estudo.beneficios WHERE acesso_id=:a',{a=bind(firstGrant.access.id,'cf_sql_bigint')});check(counts.n[1]==1,'Duplicate benefit');
 transaction action='rollback';
}
transaction {
 prepareCampaign();newCnpj=fa.confirm(u.id,'CNPJ',company.documento[1],'QA',true);check(newCnpj.benefit.percentual==50 && newCnpj.benefit.status=='ELIGIBLE','New CNPJ benefit missing');
 again=fa.confirm(u.id,'CNPJ',company.documento[1],'QA',true);check(again.benefit.id==newCnpj.benefit.id,'New CNPJ not idempotent');
 transaction action='rollback';
}
transaction {
 prepareCampaign();inv=invitation(u);cnpjReady=fa.confirm(u.id,'CNPJ',company.documento[1],'QA',true);check(cnpjReady.benefit.percentual==50,'Nominal READY CNPJ missing benefit');
 state=q('SELECT status FROM estudo.vouchers WHERE id=:v',{v=bind(inv.id,'cf_sql_bigint')});check(state.status[1]=='REDEEMED','Nominal CNPJ voucher not redeemed');
 transaction action='rollback';
}
transaction {
 prepareCampaign(false);inv=invitation(u);oldGrant=sa.redeem(u.id,inv.code);check(structIsEmpty(oldGrant.benefit),'Zero-percent transition changed');
 prepareCampaign(true);retro=sa.redeem(u.id,inv.code);check(retro.access.id==oldGrant.access.id && retro.benefit.percentual==50,'Already redeemed missing-benefit repair failed');
 transaction action='rollback';
}
transaction {
 prepareCampaign();inv=invitation(u);created=sa.redeem(u.id,inv.code);q("UPDATE estudo.beneficios SET status='REVOKED',revogado_em=clock_timestamp(),revogado_por=:a WHERE id=:b",{a=bind(admin.id[1],'cf_sql_bigint'),b=bind(created.benefit.id,'cf_sql_bigint')});
 repeated=sa.redeem(u.id,inv.code);check(repeated.benefit.id==created.benefit.id && repeated.benefit.status=='REVOKED','Revoked benefit reactivated');
 transaction action='rollback';
}
transaction {
 prepareCampaign();inv=invitation(u,true);denied=false;try{sa.redeem(u.id,inv.code);}catch(any err){denied=listLast(err.type,'.')=='Access';}check(denied,'Expired voucher allowed');transaction action='rollback';
}
transaction {
 prepareCampaign();inv=invitation(u,false,true);denied=false;try{fa.confirm(u.id,'CNPJ',company.documento[1],'QA',true);}catch(any err){denied=listLast(err.type,'.')=='Access';}check(denied,'Revoked CNPJ voucher allowed');transaction action='rollback';
}
transaction {
 prepareCampaign();inv=invitation(u);identity(other);denied=false;try{sa.redeem(other.id,inv.code);}catch(any err){denied=listLast(err.type,'.')=='Access';}check(denied,'Other email allowed');transaction action='rollback';
}
identity(u);
transaction {
 prepareCampaign();inv=invitation(u);created=sa.redeem(u.id,inv.code);identity(other);denied=false;try{sa.ensureAnnualBenefit(other.id,created.access.id);}catch(any err){denied=listLast(err.type,'.')=='Access';}check(denied,'Benefit grant across accounts allowed');transaction action='rollback';
}
structDelete(REQUEST,'businessIdentity');denied=false;try{sa.ensureAnnualBenefit(u.id,'1');}catch(any err){denied=listLast(err.type,'.')=='Access';}check(denied,'Unverified identity accepted');
after=stats();for(field in listToArray(before.columnList))check(toString(before[field][1])==toString(after[field][1]),'QA changed persistent state: ' & field);
report={'voucher_50':true,'voucher_repeat_idempotent':true,'first_access_voucher':true,'cnpj_new':true,'cnpj_nominal_ready':true,'cnpj_repeat_idempotent':true,'redeemed_repair':true,'zero_percent_transition':true,'revoked_benefit_preserved':true,'expired_voucher_denied':true,'revoked_cnpj_denied':true,'wrong_email_denied':true,'cross_account_grant_denied':true,'verified_identity_required':true,'no_free_annual_reading':true,'qa_transactions_rolled_back':true};
'''
r=remote(body,{'study':study,'first':first,'cf':cf});(W/'service-qa.json').write_text(json.dumps(r,indent=2));print(r)
