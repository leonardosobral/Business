<!--- Events owns its existing runner_dba datasource, including authorization locks and audit. --->
<cfscript>
function eventDelegationActive(){return structKeyExists(REQUEST,'businessAccessContext') AND REQUEST.businessAccessContext.accessMode=='DELEGATED';}
function eventDelegationAssertAction(required any action){
 if(!isSimpleValue(action) OR !listFind('editar_evento_basico,editar_evento_fornecedores,editar_evento_competition_id,editar_evento_descricao,editar_evento_percursos,salvar_evento_percurso',action))
  throw(type='BusinessDelegation.Forbidden',message='Event action unavailable');
}
function eventDelegationEvents(){
 return queryExecute("SELECT ce.id_evento FROM tb_conta_eventos ce JOIN tb_evento_corridas evt ON evt.id_evento=ce.id_evento WHERE ce.id_conta=:account AND ce.status='ATIVO' AND evt.ativo=true",{account={value=REQUEST.businessAccessContext.accountId,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'});
}
function eventDelegationMutation(required struct posted,required string capability,required struct resource,required any work,required struct state){
 if(CGI.request_method!='POST') throw(type='BusinessDelegation.Forbidden',message='POST required');
 var context=structKeyExists(REQUEST,'businessAccessContext')?REQUEST.businessAccessContext:{};
 if(structIsEmpty(context) AND structKeyExists(posted,'business_access_token')) throw(type='BusinessDelegation.Conflict',message='Reopen the event form');
 var service=createObject('component','services.BusinessAccountDelegation').init('runner_dba',structKeyExists(APPLICATION,'businessAccountDelegationEnabled') AND APPLICATION.businessAccountDelegationEnabled);
 var policy=createObject('component','services.accountDelegation.Policy');
 var callback=work;var callbackState=state;
 var bound=function(fresh){return callback(fresh,callbackState);};
 if(!structIsEmpty(context) AND (context.accessMode=='DELEGATED' OR structKeyExists(posted,'business_access_token'))){
  service.verifyForm(context,policy.postedContext(posted),SESSION.businessDelegationFormSeed);
  var fresh=service.resolve({id=context.actorId},context);policy.assertExpected(fresh,context);
  if(context.accessMode=='DELEGATED') return service.withMutation(context,capability,context,resource,bound);
 }
 // Preserve existing direct/internal module authorization and the original datasource.
 transaction {return bound({datasource='runner_dba'});}
}
function eventMutationScope(required struct fresh,required struct posted,required struct state){
 var policy=createObject('component','services.accountDelegation.Policy');
 var requiredFields={editar_evento_basico='nome_evento,cidade,estado,data_inicial,data_final,tag,tipo_corrida,endereco,coordenadas,url_inscricao,url_hotsite',editar_evento_descricao='descricao,url_imagem,resumo',editar_evento_percursos='categorias',salvar_evento_percurso='id_evento_percurso,percurso_evento,unidade_de_medida,data_percurso,hora_largada,tipo_corrida',editar_evento_competition_id='id_evento_parceiro',editar_evento_fornecedores='fornecedor_count'};
 for(var field in listToArray(requiredFields[posted.action])) if(!structKeyExists(posted,field) OR !isSimpleValue(posted[field])) policy.fail('Validation','Invalid event field');
 if(posted.action=='editar_evento_basico' AND !len(trim(posted.nome_evento))) policy.fail('Validation','Event name required');
 var eventId=policy.identifier(posted.id_evento,true);
 var delegated=structKeyExists(fresh,'accessMode') AND fresh.accessMode=='DELEGATED';
 if(delegated){
  eventDelegationAssertAction(posted.action);
  var linked=queryExecute("SELECT evt.id_evento FROM tb_conta_eventos ce JOIN tb_evento_corridas evt ON evt.id_evento=ce.id_evento WHERE ce.id_conta=:account AND ce.id_evento=:id AND ce.status='ATIVO' AND evt.ativo=true FOR UPDATE OF ce,evt",{account={value=fresh.accountId,cfsqltype='cf_sql_bigint'},id={value=eventId,cfsqltype='cf_sql_integer'}},{datasource=fresh.datasource});
  if(!linked.recordCount) policy.fail('NotFound','Event unavailable');
 } else if(!state.adminIsAdmin AND (!structKeyExists(state,'qEventosConta') OR !listFind(valueList(state.qEventosConta.id_evento),eventId))) policy.fail('NotFound','Event unavailable');
 if(posted.action=='salvar_evento_percurso'){
  var childId=policy.identifier(posted.id_evento_percurso);
  var child=queryExecute('SELECT id_evento_percurso FROM tb_evento_corridas_percursos WHERE id_evento_percurso=:child AND id_evento=:parent FOR UPDATE',{child={value=childId,cfsqltype='cf_sql_integer'},parent={value=eventId,cfsqltype='cf_sql_integer'}},{datasource=fresh.datasource});
  if(!child.recordCount) policy.fail('NotFound','Course unavailable');
 }
 if(posted.action=='editar_evento_competition_id'){
  var competition=policy.identifier(posted.id_evento_parceiro);
  queryExecute('SELECT pg_advisory_xact_lock(17012026,CAST(:competition AS integer))',{competition={value=competition,cfsqltype='cf_sql_integer'}},{datasource=fresh.datasource});
  var conflict=queryExecute("SELECT id_evento FROM tb_evento_corridas_relaciona WHERE id_evento_parceiro=:competition AND id_parceiro=1 AND nome_variavel='competition_id' AND id_evento<>:event FOR UPDATE",{competition={value=competition,cfsqltype='cf_sql_integer'},event={value=eventId,cfsqltype='cf_sql_integer'}},{datasource=fresh.datasource});
  if(conflict.recordCount) policy.fail('NotFound','Competition unavailable');
 }
 if(posted.action=='editar_evento_fornecedores'){
  state.eventSupplierRows=[];
  if(!structKeyExists(posted,'fornecedor_count')) policy.fail('Validation','Reopen the supplier form');
  var count=policy.identifier(posted.fornecedor_count,true);
  if(val(count)>100) policy.fail('Validation','Too many suppliers');
  for(var key in posted) if(reFindNoCase('^fornecedor_(tipo_)?',key) AND key!='fornecedor_count') {
   if(!reFindNoCase('^fornecedor_(tipo_)?[1-9][0-9]*$',key) OR val(listLast(key,'_'))>val(count)) policy.fail('Validation','Invalid supplier index');
  }
  var seen={};
  for(var i=1;i<=val(count);i++){
   if(!structKeyExists(posted,'fornecedor_' & i) OR !structKeyExists(posted,'fornecedor_tipo_' & i) OR !isSimpleValue(posted['fornecedor_' & i]) OR !isSimpleValue(posted['fornecedor_tipo_' & i])) policy.fail('Validation','Invalid supplier pair');
   var id=trim(posted['fornecedor_' & i]);var type=trim(posted['fornecedor_tipo_' & i]);
   if(!len(id) AND !len(type)) continue;
   id=policy.identifier(id);type=policy.identifier(type);
   if(structKeyExists(seen,id & ':' & type)) policy.fail('Validation','Duplicate supplier pair');seen[id & ':' & type]=true;
   var valid=queryExecute('SELECT f.id_fornecedor FROM tb_fornecedores f CROSS JOIN tb_fornecedores_tipos t WHERE f.id_fornecedor=:id AND t.id_fornecedor_tipo=:type',{id={value=id,cfsqltype='cf_sql_integer'},type={value=type,cfsqltype='cf_sql_integer'}},{datasource=fresh.datasource});
   if(!valid.recordCount) policy.fail('Validation','Supplier unavailable');
   arrayAppend(state.eventSupplierRows,{id=id,type=type});
  }
 }
}
</cfscript>
