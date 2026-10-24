<cfprocessingdirective pageencoding="utf-8">
<cfsetting showdebugoutput="false" requesttimeout="120">
<cfcontent type="application/json; charset=utf-8">
<cfscript>
// Private, synthetic harness only. Never deploy this test to the public Business.
if(!listFind('127.0.0.1,::1',CGI.remote_addr)){cfheader(statuscode=403);abort;}
testDatasource='codex_comparador_test';
function db(sql,params={}){return queryExecute(sql,params,{datasource=testDatasource});}
function p(value,type='cf_sql_varchar',nullable=false){return {value=value,cfsqltype=type,null=nullable AND !len(value & '')};}
if(db('SELECT current_database() AS name').name!='comparador_codex_test')throw(message='Banco sintético obrigatório');
results=[];
function check(label,ok){arrayAppend(results,{name=label,pass=ok?true:false});if(!ok)throw(message=label);}
function rejects(label,action,kind='Comparador.Validation'){
 var caught=false;try{action();}catch(any e){if(!len(kind) OR e.type==kind)caught=true;else rethrow;}
 check(label,caught);
}
s=new services.ComparadorCuradoriaService().init(testDatasource);
actor=randRange(100000000,999999999);
while(db('SELECT 1 FROM comparador.tb_cadastro_auditoria WHERE ator_id=:actor',{actor=p(actor,'cf_sql_bigint')}).recordCount)actor=randRange(100000000,999999999);
c={actorId=actor,isAdmin=true,delegated=false,isPost=true,csrfVerified=true};
originalHome=db("SELECT h.*,h.atualizado_em::text AS timestamp_text,coalesce(h.ator_id::text,'') AS actor_text FROM comparador.tb_home_curadoria h WHERE id_config=1");
if(!originalHome.recordCount)throw(message='Instale o singleton da curadoria no harness antes do teste');
originalBrands=db('SELECT * FROM comparador.tb_marca_curadoria ORDER BY tag_marca');
auditStart=db('SELECT coalesce(max(id_auditoria),0) AS n FROM comparador.tb_cadastro_auditoria').n;
nonce=lCase(left(replace(createUUID(),'-','','all'),16));
tagA='codex-curadoria-' & nonce & '-a';tagB='codex-curadoria-' & nonce & '-b';
triggerName='codex_curadoria_audit_' & nonce;triggerInstalled=false;
try {
 for(role in [{actorId=0,isAdmin=true,delegated=false},{actorId=actor,isAdmin=false,delegated=false},{actorId=actor,isAdmin=true,delegated=true}]){
  context=duplicate(role);
  rejects('Leitura restrita: ' & serializeJSON(role),function(){s.load(context);},'Comparador.Forbidden');
  rejects('Disponibilidade restrita: ' & serializeJSON(role),function(){s.ready(context);},'Comparador.Forbidden');
  rejects('Histórico restrito: ' & serializeJSON(role),function(){s.history(context);},'Comparador.Forbidden');
 }
 check('Admin global pode ler a configuração',s.ready(c));
 for(gate in ['isPost','csrfVerified']){
  blocked=duplicate(c);blocked[gate]=false;
  rejects('Salvar home exige ' & gate,function(){s.saveHome(blocked,{lancamentos_por_ciclo='2',ofertas_por_ciclo='1',token=s.load(c).token});},'Comparador.Forbidden');
  rejects('Salvar marcas exige ' & gate,function(){s.saveMarcas(blocked,{formulario_completo='curadoria',token=s.load(c).token});},'Comparador.Forbidden');
 }
 for(role in [{actorId=actor,isAdmin=false,delegated=false,isPost=true,csrfVerified=true},{actorId=actor,isAdmin=true,delegated=true,isPost=true,csrfVerified=true}]){
  context=duplicate(role);
  rejects('Não global não grava home',function(){s.saveHome(context,{});},'Comparador.Forbidden');
  rejects('Não global não grava marcas',function(){s.saveMarcas(context,{});},'Comparador.Forbidden');
 }
 for(bad in ['0','11','1.5','-1','1e1','01','true']){
  current=s.load(c);candidate={formulario_completo='curadoria',token=current.token,lancamentos_por_ciclo=bad,ofertas_por_ciclo='1'};
  rejects('Lançamentos inválidos: ' & bad,function(){s.saveHome(c,candidate);});
  candidate={formulario_completo='curadoria',token=current.token,lancamentos_por_ciclo='2',ofertas_por_ciclo=bad};
  rejects('Ofertas inválidas: ' & bad,function(){s.saveHome(c,candidate);});
  check('Razão inválida não altera estado',s.load(c).token==current.token);
 }
 rejects('Array na razão recusado',function(){s.saveHome(c,{formulario_completo='curadoria',token=s.load(c).token,lancamentos_por_ciclo=['2'],ofertas_por_ciclo='1'});});
 current=s.load(c);
 s.saveHome(c,{formulario_completo='curadoria',token=current.token,lancamentos_por_ciclo='10',ofertas_por_ciclo='1'});
 changed=s.load(c);check('Razão salva com revisão',changed.data.home.lancamentos_por_ciclo==10 AND changed.data.home.ofertas_por_ciclo==1 AND changed.data.home.revisao==current.data.home.revisao+1);
 rejects('Token obsoleto de home recusado',function(){s.saveHome(c,{formulario_completo='curadoria',token=current.token,lancamentos_por_ciclo='3',ofertas_por_ciclo='2'});},'Comparador.Conflict');
 check('Conflito preserva estado',s.load(c).token==changed.token);
 db('INSERT INTO comparador.tb_marca(tag_marca,marca) VALUES(:a,:nameA),(:b,:nameB)',{a=p(tagA),b=p(tagB),nameA=p('Marca A <teste seguro>'),nameB=p('Marca B sintética')});
 current=s.load(c);brandForm={formulario_completo='curadoria',token=current.token,escopo_tags=tagA & ',' & tagB};brandForm['destaque_' & tagA]='true';brandForm['brasil_' & tagB]='true';
 s.saveMarcas(c,brandForm);
 flags=db('SELECT * FROM comparador.tb_marca_curadoria WHERE tag_marca IN (:a,:b) ORDER BY tag_marca',{a=p(tagA),b=p(tagB)});
 check('Destaque independe de presença no Brasil',flags.recordCount==2 AND flags.destaque[1] AND !flags.presente_brasil[1] AND !flags.destaque[2] AND flags.presente_brasil[2]);
 catalog=new services.ComparadorCatalogService().init(testDatasource);curatedBrand=catalog.loadRecord(c,'marcas',tagA);
 rejects('Marca curada sem produto continua protegida da exclusão',function(){catalog.deleteRecord(c,'marcas',tagA,curatedBrand.token);});
 rejects('Token de marcas anterior à gravação recusado',function(){s.saveMarcas(c,brandForm);},'Comparador.Conflict');
 current=s.load(c);badForm={formulario_completo='curadoria',token=current.token,escopo_tags=tagA & ',' & tagB};badForm['destaque_marca-inexistente']='true';
 rejects('Marca inexistente recusada sem parcial',function(){s.saveMarcas(c,badForm);});
 for(badValue in ['false','true,true','1']){
  badForm={formulario_completo='curadoria',token=current.token,escopo_tags=tagA & ',' & tagB};badForm['destaque_' & tagA]=badValue;
  rejects('Valor de checkbox inválido: ' & badValue,function(){s.saveMarcas(c,badForm);});
 }
 badForm={formulario_completo='curadoria',token=current.token,escopo_tags=tagA & ',' & tagB};badForm['destaque_' & tagA]=['true'];
 rejects('Array de checkbox recusado',function(){s.saveMarcas(c,badForm);});
 check('Marcas inválidas não alteram estado',s.load(c).token==current.token);
 s.saveMarcas(c,{formulario_completo='curadoria',token=current.token,escopo_tags=tagA & ',' & tagB});
 check('Desmarcar página remove só as suas linhas opcionais',db('SELECT count(*) AS n FROM comparador.tb_marca_curadoria WHERE tag_marca IN (:a,:b)',{a=p(tagA),b=p(tagB)}).n==0);
 check('Salvar página preserva flags de outras marcas',db('SELECT count(*) AS n FROM comparador.tb_marca_curadoria').n==originalBrands.recordCount);
 current=s.load(c);
 db('UPDATE comparador.tb_marca SET marca=:name WHERE tag_marca=:tag',{name=p('Nome atualizado externamente'),tag=p(tagA)});
 rejects('Token inclui nomes das marcas',function(){s.saveHome(c,{formulario_completo='curadoria',token=current.token,lancamentos_por_ciclo='2',ofertas_por_ciclo='1'});},'Comparador.Conflict');

 current=s.load(c);
 rejects('Sentinela home obrigatória',function(){s.saveHome(c,{token=current.token,lancamentos_por_ciclo='2',ofertas_por_ciclo='1'});});
 rejects('Sentinela marcas obrigatória',function(){s.saveMarcas(c,{token=current.token,escopo_tags=tagA & ',' & tagB});});
 rejects('Sentinela repetida recusada',function(){s.saveHome(c,{formulario_completo='curadoria,curadoria',token=current.token,lancamentos_por_ciclo='2',ofertas_por_ciclo='1'});});
 for(badScope in ['',tagA & ',' & tagA,'unknown-brand',repeatString(tagA & ',',30) & tagA]) {
  scoped={formulario_completo='curadoria',token=current.token,escopo_tags=badScope};
  rejects('Escopo inválido recusado: ' & left(badScope,70),function(){s.saveMarcas(c,scoped);});
 }
 outside={formulario_completo='curadoria',token=current.token,escopo_tags=tagA};outside['brasil_' & tagB]='true';
 rejects('Checkbox fora da página recusado',function(){s.saveMarcas(c,outside);});
 // Force the audit INSERT to fail after config DML; the service must roll back both changes.
 db('CREATE FUNCTION comparador.' & triggerName & '() RETURNS trigger LANGUAGE plpgsql AS $body$ BEGIN IF NEW.ator_id=' & actor & ' THEN RAISE EXCEPTION ''synthetic audit failure''; END IF; RETURN NEW; END $body$');
 db('CREATE TRIGGER ' & triggerName & ' BEFORE INSERT ON comparador.tb_cadastro_auditoria FOR EACH ROW EXECUTE FUNCTION comparador.' & triggerName & '()');
 triggerInstalled=true;current=s.load(c);countBefore=db('SELECT count(*) AS n FROM comparador.tb_cadastro_auditoria').n;
 rejects('Falha da auditoria cancela a operação',function(){s.saveHome(c,{formulario_completo='curadoria',token=current.token,lancamentos_por_ciclo='3',ofertas_por_ciclo='2'});},'');
 check('Falha da auditoria reverte razão e revisão',s.load(c).token==current.token);
 check('Falha da auditoria não cria histórico',db('SELECT count(*) AS n FROM comparador.tb_cadastro_auditoria').n==countBefore);
} finally {
 if(triggerInstalled)db('DROP TRIGGER IF EXISTS ' & triggerName & ' ON comparador.tb_cadastro_auditoria');
 db('DROP FUNCTION IF EXISTS comparador.' & triggerName & '()');
 // No encompassing transaction around service calls: CF nested failures would invalidate it.
 transaction {
  db('LOCK TABLE comparador.tb_marca IN SHARE ROW EXCLUSIVE MODE');
  db('SELECT id_config FROM comparador.tb_home_curadoria WHERE id_config=1 FOR UPDATE');
  db('DELETE FROM comparador.tb_marca_curadoria');
  for(row in originalBrands)db('INSERT INTO comparador.tb_marca_curadoria(tag_marca,destaque,presente_brasil) VALUES(:tag,:featured,:brazil)',{tag=p(row.tag_marca),featured=p(row.destaque,'cf_sql_bit'),brazil=p(row.presente_brasil,'cf_sql_bit')});
  db('UPDATE comparador.tb_home_curadoria SET lancamentos_por_ciclo=:launches,ofertas_por_ciclo=:offers,revisao=:revision,atualizado_em=CAST(:stamp AS timestamptz),ator_id=:actor WHERE id_config=1',{launches=p(originalHome.lancamentos_por_ciclo,'cf_sql_smallint'),offers=p(originalHome.ofertas_por_ciclo,'cf_sql_smallint'),revision=p(originalHome.revisao,'cf_sql_bigint'),stamp=p(originalHome.timestamp_text),actor=p(originalHome.actor_text,'cf_sql_bigint',true)});
  db('DELETE FROM comparador.tb_marca WHERE tag_marca IN (:a,:b)',{a=p(tagA),b=p(tagB)});
  db("DELETE FROM comparador.tb_cadastro_auditoria WHERE entidade='curadoria' AND chave='principal' AND ator_id=:actor AND id_auditoria>:start",{actor=p(actor,'cf_sql_bigint'),start=p(auditStart,'cf_sql_bigint')});
 }
}
writeOutput(serializeJSON({passed=arrayLen(results),results=results}));
</cfscript>
