<cfprocessingdirective pageencoding="utf-8">
<cfsetting showdebugoutput="false" requesttimeout="120">
<cfcontent type="application/json; charset=utf-8">
<cfheader name="Cache-Control" value="no-store">
<cfscript>
// Test fixture, not an administrative API. Install ONLY inside the loopback synthetic harness.
if(!listFind('127.0.0.1,::1',CGI.remote_addr)){cfheader(statuscode=403);abort;}
if(CGI.request_method!='POST'){cfheader(statuscode=405);abort;}
testDatasource='codex_comparador_test';
function db(sql,params={}){return queryExecute(sql,params,{datasource=testDatasource});}
function p(value,type='cf_sql_varchar',nullable=false){return {value=value,cfsqltype=type,null=nullable AND !len(value & '')};}
if(db('SELECT current_database() AS name').name!='comparador_codex_test')throw(message='Banco sintético obrigatório');
guard=new services.ComparadorAdminService().init(testDatasource);
s=new services.ComparadorCuradoriaService().init(testDatasource);
testContext={actorId=999999999,isAdmin=true,delegated=false};
action=guard.field(FORM,'action',16);run=guard.field(FORM,'run',32);result={};
if(!reFind('^[a-f0-9]{32}$',run))throw(message='Identificador de execução inválido');
lock name='codex-comparador-curadoria-http-fixture' type='exclusive' timeout=15 {
 if(!structKeyExists(APPLICATION,'codexCuradoriaHttpFixtures'))APPLICATION.codexCuradoriaHttpFixtures={};
 if(action=='diagnose') {
  result={runs=[]};
  for(ownedRun in APPLICATION.codexCuradoriaHttpFixtures) {
   ownedState=APPLICATION.codexCuradoriaHttpFixtures[ownedRun];ownedCurrent=s.load(testContext);
   recordedData={};
   if(arrayLen(ownedState.audits))recordedData=deserializeJSON(db('SELECT depois::text AS data FROM comparador.tb_cadastro_auditoria WHERE id_auditoria=:id',{id=p(ownedState.audits[arrayLen(ownedState.audits)],'cf_sql_bigint')}).data);
   arrayAppend(result.runs,{run=ownedRun,recorded_token=ownedState.token,current_token=ownedCurrent.token,current_data=ownedCurrent.data,recorded_data=recordedData,audits=ownedState.audits,created=ownedState.created});
  }
 } else if(action=='setup') {
  if(structKeyExists(APPLICATION.codexCuradoriaHttpFixtures,run))throw(message='Execução já preparada');
  if(structCount(APPLICATION.codexCuradoriaHttpFixtures))throw(message='Outra execução de curadoria precisa ser restaurada primeiro');
  state={home=db("SELECT h.*,h.atualizado_em::text AS timestamp_text,coalesce(h.ator_id::text,'') AS actor_text FROM comparador.tb_home_curadoria h WHERE id_config=1"),flags=db('SELECT * FROM comparador.tb_marca_curadoria ORDER BY tag_marca'),created=[],audits=[],actor=guard.identifier(guard.field(FORM,'actor',10))};
  if(!state.home.recordCount)throw(message='Singleton da curadoria ausente');
  transaction {
   db('LOCK TABLE comparador.tb_marca IN SHARE ROW EXCLUSIVE MODE');
   brandCount=db('SELECT count(*) AS n FROM comparador.tb_marca').n;
   for(i=brandCount+1;i<=max(59,brandCount+1);i++) {
    tag='codex-http-' & left(run,16) & '-' & i;
    db('INSERT INTO comparador.tb_marca(tag_marca,marca) VALUES(:tag,:name)',{tag=p(tag),name=p('Marca sintética ' & numberFormat(i,'00') & ' <teste>')});
    arrayAppend(state.created,tag);
   }
  }
  state.token=s.load(testContext).token;
  APPLICATION.codexCuradoriaHttpFixtures[run]=state;
  result={ready=true,brand_count=arrayLen(s.load(testContext).data.marcas)};
 } else {
  if(!structKeyExists(APPLICATION.codexCuradoriaHttpFixtures,run))throw(message='Execução não preparada');
  state=APPLICATION.codexCuradoriaHttpFixtures[run];current=s.load(testContext);
  if(action=='inspect') {
   result={data=current.data,token=current.token,optional_rows=db('SELECT count(*) AS n FROM comparador.tb_marca_curadoria').n,audits_recorded=arrayLen(state.audits)};
  } else if(action=='record') {
   beforeToken=guard.field(FORM,'before_token',64);
   if(compare(beforeToken,state.token)!=0)throw(message='Token anterior não pertence à execução');
   candidates=db("SELECT id_auditoria,antes::text,depois::text FROM comparador.tb_cadastro_auditoria WHERE entidade='curadoria' AND chave='principal' AND ator_id=:actor ORDER BY id_auditoria DESC LIMIT 100",{actor=p(state.actor,'cf_sql_bigint')});
   matched=[];
   for(row in candidates)if(lCase(hash(row.antes,'SHA-256'))==beforeToken AND lCase(hash(row.depois,'SHA-256'))==current.token)arrayAppend(matched,row.id_auditoria);
   if(arrayLen(matched)!=1)throw(message='A gravação HTTP não possui uma auditoria correspondente');
   arrayAppend(state.audits,matched[1]);state.token=current.token;
   APPLICATION.codexCuradoriaHttpFixtures[run]=state;result={recorded=true};
  } else if(action=='cleanup') {
   if(compare(current.token,state.token)!=0)throw(message='Estado externo mudou; restauração recusada para preservar outra frente');
   transaction {
    db('LOCK TABLE comparador.tb_marca IN SHARE ROW EXCLUSIVE MODE');
    db('SELECT id_config FROM comparador.tb_home_curadoria WHERE id_config=1 FOR UPDATE');
    if(compare(s.load(testContext).token,state.token)!=0)throw(message='Estado mudou durante a restauração');
    db('DELETE FROM comparador.tb_marca_curadoria');
    for(row in state.flags)db('INSERT INTO comparador.tb_marca_curadoria(tag_marca,destaque,presente_brasil) VALUES(:tag,:featured,:brazil)',{tag=p(row.tag_marca),featured=p(row.destaque,'cf_sql_bit'),brazil=p(row.presente_brasil,'cf_sql_bit')});
    db('UPDATE comparador.tb_home_curadoria SET lancamentos_por_ciclo=:launches,ofertas_por_ciclo=:offers,revisao=:revision,atualizado_em=CAST(:stamp AS timestamptz),ator_id=:actor WHERE id_config=1',{launches=p(state.home.lancamentos_por_ciclo,'cf_sql_smallint'),offers=p(state.home.ofertas_por_ciclo,'cf_sql_smallint'),revision=p(state.home.revisao,'cf_sql_bigint'),stamp=p(state.home.timestamp_text),actor=p(state.home.actor_text,'cf_sql_bigint',true)});
    for(tag in state.created)db('DELETE FROM comparador.tb_marca WHERE tag_marca=:tag',{tag=p(tag)});
    for(auditId in state.audits)db("DELETE FROM comparador.tb_cadastro_auditoria WHERE id_auditoria=:id AND entidade='curadoria' AND chave='principal' AND ator_id=:actor",{id=p(auditId,'cf_sql_bigint'),actor=p(state.actor,'cf_sql_bigint')});
   }
   structDelete(APPLICATION.codexCuradoriaHttpFixtures,run);result={restored=true,audits_removed=arrayLen(state.audits),brands_removed=arrayLen(state.created)};
  } else throw(message='Ação de fixture inválida');
 }
}
writeOutput(serializeJSON(result));
</cfscript>
