<cfscript>
application action="update" sessionmanagement=true datasource='business_delegation_test';
testDS=duplicate(getApplicationSettings().datasources);testDS.runner_dba=duplicate(testDS.business_delegation_test);testDS.runner_dba.username='runner_dba';application action="update" datasources=testDS;
application.businessAccountDelegationEnabled=true;
SESSION.businessDelegationFormSeed=repeatString('events-seed-',5);
service=createObject('component','services.BusinessAccountDelegation').init('runner_dba',true);
policy=createObject('component','services.accountDelegation.Policy');
function db(required string sql,struct params={}){return queryExecute(sql,params,{datasource='business_delegation_test'});}
manager=service.resolve({id=903},{accountId=102,accessMode='DELEGATED',managerAccountId=101,relationshipId=2001});
viewer=service.resolve({id=905},manager);
owner=service.resolve({id=902},manager);
function eventForm(required struct context,required struct values){var posted=duplicate(values);structAppend(posted,policy.formFields(context,policy.formToken(context,SESSION.businessDelegationFormSeed)));return posted;}
function setupEvent(required struct context,required struct values){
 REQUEST.businessAccessContext=context;REQUEST.businessIdentity={id=context.actorId};
 structClear(FORM);structAppend(FORM,eventForm(context,values));
 structClear(URL);structAppend(URL,{id_evento='',periodo='',busca='',estado='',sessao='dados',preset=''});
 VARIABLES.adminIsAdmin=false;VARIABLES.businessEffectiveIsAdmin=false;VARIABLES.businessRealIsAdmin=true;
 VARIABLES.businessEffectiveAccountIds='102';VARIABLES.qEventosConta=db("SELECT id_evento FROM tb_conta_eventos WHERE id_conta=102 AND status='ATIVO'");
 VARIABLES.qPerfil=db('SELECT * FROM tb_usuarios WHERE id=:id',{id={value=context.actorId,cfsqltype='cf_sql_integer'}});
}
</cfscript>
<cffunction name="runEventHandler" output="false">
 <cfinclude template="../../../eventos/includes/backend/backend_evento_edicao.cfm"/>
</cffunction>
<cffunction name="runRequestHandler" output="false">
 <cfinclude template="../../../eventos/includes/backend/backend_evento_solicitacoes.cfm"/>
</cffunction>
<cfscript>
function testViewerCannotPostEvent(){
 setupEvent(viewer,{action='editar_evento_descricao',id_evento='701',descricao='forbidden',url_imagem='',resumo=''});
 assertThrowsType(function(){runEventHandler();},'BusinessDelegation.Forbidden','viewer');
 assertEqual(db("SELECT coalesce(descricao,'') AS value FROM tb_evento_corridas WHERE id_evento=701").value[1],'','viewer unchanged');
}
function testNestedResourceBelongsToEventAndClient(){
 setupEvent(manager,{action='salvar_evento_percurso',id_evento='701',id_evento_percurso='712',percurso_evento='42',unidade_de_medida='km',data_percurso='2026-12-01',hora_largada='',tipo_corrida='rua'});
 assertThrowsType(function(){runEventHandler();},'BusinessDelegation.NotFound','foreign parent');
 assertEqual(db('SELECT percurso_evento FROM tb_evento_corridas_percursos WHERE id_evento_percurso=712').percurso_evento[1],10,'foreign parent unchanged');
 setupEvent(manager,{action='editar_evento_competition_id',id_evento='701',id_evento_parceiro='888'});
 assertThrowsType(function(){runEventHandler();},'BusinessDelegation.NotFound','foreign competition');
 setupEvent(manager,{action='editar_evento_fornecedores',id_evento='702',fornecedor_count='1',fornecedor_1='1',fornecedor_tipo_1='1'});
 assertThrowsType(function(){runEventHandler();},'BusinessDelegation.NotFound','foreign supplier parent');
}
function testGlobalEventActionsDenied(){
 for(var action in ['editar_evento_configuracoes','editar_evento_or','editar_evento_agregadores','excluir_evento','excluir_resultados','confirmar_inscricao_disponibilidade']){
  setupEvent(manager,{action=action,id_evento='701'});VARIABLES.adminIsAdmin=true;
  assertThrowsType(function(){runEventHandler();},'BusinessDelegation.Forbidden',action);
 }
}
function testRequestDoesNotSelfApprove(){
 setupEvent(owner,{evento_solicitacao_action='solicitar',id_evento='703',id_conta_solicitacao='102',evento_referencia='public-event',mensagem='Synthetic request'});
 VARIABLES.eventoSolicitacaoSelectedAccountId='102';VARIABLES.eventoSolicitacaoReferencia='public-event';VARIABLES.eventoSolicitacaoTag='public-event';VARIABLES.eventoSolicitacaoUsingPendingAccount=false;
 eventDelegationMutation(FORM,'events.links.request',{type='EVENT_REQUEST',id='703'},eventMutationRequest,VARIABLES);
 assertEqual(db('SELECT status FROM tb_conta_eventos WHERE id_conta=102 AND id_evento=703').status[1],'PENDENTE','needs approval');
 assertEqual(db('SELECT id_usuario_solicitante FROM tb_conta_evento_solicitacoes WHERE id_conta=102 AND id_evento=703').id_usuario_solicitante[1],902,'actual actor');
 setupEvent(owner,{evento_solicitacao_action='aprovar',id_solicitacao='1'});
 assertThrowsType(function(){runRequestHandler();},'BusinessDelegation.Forbidden','no self approval');
}
function testAllOperationalWritesAndRollback(){
 setupEvent(manager,{action='editar_evento_descricao',id_evento='701',descricao='Own description',url_imagem='https://example.test/a.png',resumo='Own summary'});runEventHandler();
 assertEqual(db('SELECT descricao FROM tb_evento_corridas WHERE id_evento=701').descricao[1],'Own description','description');
 setupEvent(manager,{action='editar_evento_percursos',id_evento='701',categorias='5km,10km'});runEventHandler();
 assertEqual(db('SELECT categorias FROM tb_evento_corridas WHERE id_evento=701').categorias[1],'5km,10km','categories');
 setupEvent(manager,{action='salvar_evento_percurso',id_evento='701',id_evento_percurso='711',percurso_evento='5',unidade_de_medida='km',data_percurso='2026-12-02',hora_largada='08:30',tipo_corrida='trail'});runEventHandler();
 assertEqual(db('SELECT tipo_corrida FROM tb_evento_corridas_percursos WHERE id_evento_percurso=711').tipo_corrida[1],'trail','own course');
 setupEvent(manager,{action='editar_evento_competition_id',id_evento='701',id_evento_parceiro='777'});runEventHandler();
 assertEqual(db('SELECT id_evento_parceiro FROM tb_evento_corridas_relaciona WHERE id_evento=701').id_evento_parceiro[1],777,'own competition');
 setupEvent(manager,{action='editar_evento_fornecedores',id_evento='701',fornecedor_count='3',fornecedor_1='1',fornecedor_tipo_1='1',fornecedor_2='',fornecedor_tipo_2='',fornecedor_3='2',fornecedor_tipo_3='2'});runEventHandler();
 assertEqual(db('SELECT count(*) n FROM tb_evento_corridas_fornecedores WHERE id_evento=701').n[1],2,'supplier pairs preserve empty row');
 FORM.fornecedor_tipo_3='999';assertThrowsType(function(){runEventHandler();},'BusinessDelegation.Validation','invalid supplier type');
 assertEqual(db('SELECT count(*) n FROM tb_evento_corridas_fornecedores WHERE id_evento=701').n[1],2,'failed replacement preserves rows');
 FORM.fornecedor_tipo_3='';assertThrowsType(function(){runEventHandler();},'BusinessDelegation.Validation','half supplier pair');
 FORM.fornecedor_tipo_3='2';FORM.fornecedor_3=['2'];assertThrowsType(function(){runEventHandler();},'BusinessDelegation.Validation','array supplier');
 db("UPDATE tb_evento_corridas SET inscricao_disponibilidade=jsonb_build_object('status','open') WHERE id_evento=701");
 setupEvent(manager,{action='editar_evento_basico',id_evento='701',nome_evento='Updated own',cidade='123',estado='SP',data_inicial='2026-12-01',data_final='2026-12-02',tag='own-event',tipo_corrida='rua',endereco='Test',coordenadas='',url_inscricao='https://example.test/old',url_hotsite=''});runEventHandler();
 assertEqual(db('SELECT inscricao_disponibilidade IS NOT NULL AS kept FROM tb_evento_corridas WHERE id_evento=701').kept[1],true,'same registration URL preserves existing admin confirmation');
 FORM.url_inscricao='https://example.test/new';runEventHandler();
 assertEqual(db('SELECT inscricao_disponibilidade IS NULL AS cleared FROM tb_evento_corridas WHERE id_evento=701').cleared[1],true,'new registration URL clears stale confirmation');
 var audit=db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE resultado='SUCCESS' AND id_usuario_ator=903 AND id_conta_cliente=102 AND id_conta_gestora=101 AND id_vinculo=2001");assertEqual(audit.n[1],7,'seven real writes audited with actual actor');
 setupEvent(manager,{action='editar_evento_descricao',id_evento='701',descricao='rolled back',url_imagem='',resumo=''});
 db('ALTER TABLE tb_conta_gestao_auditoria RENAME COLUMN resultado TO missing_resultado');
 try{assertThrowsType(function(){runEventHandler();},'database','audit failure rolls back write');}finally{db('ALTER TABLE tb_conta_gestao_auditoria RENAME COLUMN missing_resultado TO resultado');}
 assertEqual(db('SELECT descricao FROM tb_evento_corridas WHERE id_evento=701').descricao[1],'Own description','same DSN rollback');
 db("UPDATE tb_conta_eventos SET status='INATIVO' WHERE id_conta=102 AND id_evento=701");
 assertThrowsType(function(){runEventHandler();},'BusinessDelegation.NotFound','revoked event link');
 db("UPDATE tb_conta_eventos SET status='ATIVO' WHERE id_conta=102 AND id_evento=701");
 db('UPDATE tb_conta_gestao_vinculos SET version=version+1 WHERE id_vinculo=2001');
 assertThrowsType(function(){runEventHandler();},'BusinessDelegation.Conflict','stale rendered form');
 VARIABLES.manager=service.resolve({id=903},manager);VARIABLES.owner=service.resolve({id=902},manager);
 setupEvent(manager,{action='editar_evento_descricao',id_evento='701',descricao='revoked',url_imagem='',resumo=''});
 db("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO',version=version+1 WHERE id_vinculo=2001");
 assertThrowsType(function(){runEventHandler();},'BusinessDelegation.Forbidden','revoked relation before mutation');
 db("UPDATE tb_conta_gestao_vinculos SET status='ATIVO',version=version+1 WHERE id_vinculo=2001");
 VARIABLES.manager=service.resolve({id=903},manager);VARIABLES.owner=service.resolve({id=902},manager);
}
testViewerCannotPostEvent();testNestedResourceBelongsToEventAndClient();testGlobalEventActionsDenied();testAllOperationalWritesAndRollback();testRequestDoesNotSelfApprove();
</cfscript>

<cfoutput>PASS events real handlers and database#chr(10)#</cfoutput>
