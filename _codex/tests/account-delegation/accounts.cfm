<cfscript>
dsn=application.delegationTest.datasource;
function db(required string sql,struct params={}){return queryExecute(sql,params,{datasource=application.delegationTest.datasource});}
// Extend the minimal harness only with the existing cadastral schema used by these commands.
db("CREATE TYPE tipo_titular_conta AS ENUM('PF','PJ')");
db("CREATE TYPE status_conta AS ENUM('PENDENTE','ATIVA','SUSPENSA','CANCELADA')");
db("CREATE TYPE status_conta_cadastro_solicitacao AS ENUM('PENDENTE','APROVADA','RECUSADA')");
db("CREATE TYPE status_usuario_conta AS ENUM('ATIVO','INATIVO','CONVIDADO','BLOQUEADO')");
db("CREATE SEQUENCE accounts_fixture_ids START 5000");
db("ALTER TABLE tb_contas ALTER COLUMN id_conta SET DEFAULT nextval('accounts_fixture_ids'), ADD COLUMN tipo_titular tipo_titular_conta, ADD COLUMN documento varchar(20) UNIQUE, ADD COLUMN nome_titular varchar(200), ADD COLUMN email_principal varchar(255), ADD COLUMN telefone_principal varchar(30), ADD COLUMN data_atualizacao timestamptz DEFAULT now()");
db("ALTER TABLE tb_conta_usuarios ALTER COLUMN id_conta_usuario SET DEFAULT nextval('accounts_fixture_ids'), ADD COLUMN usuario_convite bigint, ADD COLUMN data_convite timestamptz, ADD COLUMN data_aceite timestamptz, ADD COLUMN data_atualizacao timestamptz DEFAULT now()");
db("ALTER TABLE tb_conta_cadastro_solicitacoes ALTER COLUMN id_solicitacao SET DEFAULT nextval('accounts_fixture_ids'), ADD COLUMN nome_empresa varchar(160), ADD COLUMN tipo_titular tipo_titular_conta, ADD COLUMN documento varchar(20), ADD COLUMN nome_responsavel varchar(200), ADD COLUMN email_responsavel varchar(255), ADD COLUMN telefone_responsavel varchar(30), ADD COLUMN site varchar(256), ADD COLUMN cidade varchar(128), ADD COLUMN estado varchar(2), ADD COLUMN tipo_prestador varchar(80), ADD COLUMN mensagem text, ADD COLUMN id_usuario_revisor bigint, ADD COLUMN data_revisao timestamptz");
db("CREATE SCHEMA ads");db("CREATE TABLE ads.tb_ad_vouchers(id_conta bigint,credito numeric)");
service=createObject('component','services.BusinessAccountDelegation').init(dsn,true);
store=createObject('component','services.accountDelegation.Store').init(dsn);
manager={id=902,email=' OWNER@EXAMPLE.TEST ',emailVerified=true};
recipient={id=904,email=' CLIENT@EXAMPLE.TEST ',emailVerified=true};
reviewer={id=901,email='reviewer@example.test',emailVerified=true,accessMode='DIRECT'};
db('UPDATE tb_usuarios SET is_admin=true WHERE id=901');
function fields(string document='12.345.678/0001-99') {return {nome_empresa='Client Created',tipo_titular='PJ',documento=document,nome_responsavel='Client Representative',email_responsavel=' CLIENT@EXAMPLE.TEST ',telefone_responsavel='123',site='',cidade='Sao Paulo',estado='sp',tipo_prestador='Organizador',mensagem='Requested by agency'};}
function created(string document='12345678000199'){return service.createClient(manager,101,fields(document),['events.manage']);}
function clientId(required any relationshipId){return store.relationship(relationshipId).id_conta_cliente;}
function registration(required any relationshipId){return db('SELECT id_solicitacao FROM tb_conta_cadastro_solicitacoes WHERE gestao_vinculo_id=:id',{id={value=relationshipId,cfsqltype='cf_sql_bigint'}}).id_solicitacao[1];}
function testNewClientHasNoAgencyOwner(){
 var result=created();var account=clientId(result.id);
 assertEqual(result.status,'AGUARDANDO_CONTA','new relationship pending');
 assertEqual(store.account(account).status,'PENDENTE','approval');
 assertEqual(db('SELECT count(*) n FROM tb_conta_usuarios WHERE id_conta=:id',{id={value=account,cfsqltype='cf_sql_bigint'}}).n[1],0,'not owner');
 assertEqual(db('SELECT count(*) n FROM ads.tb_ad_vouchers WHERE id_conta=:id',{id={value=account,cfsqltype='cf_sql_bigint'}}).n[1],0,'no benefits');
 var savedRequest=db('SELECT * FROM tb_conta_cadastro_solicitacoes WHERE gestao_vinculo_id=:id',{id={value=result.id,cfsqltype='cf_sql_bigint'}});
 assertEqual(savedRequest.id_usuario[1],902,'real requester separate');assertEqual(savedRequest.email_responsavel[1],'client@example.test','client contact');
 assertThrowsType(function(){service.resolve(manager,{accountId=account,managerAccountId=101,relationshipId=result.id,accessMode='DELEGATED'});},'BusinessDelegation.Forbidden','pending cannot operate');
}
function testDuplicateDocumentDoesNotGrantAccess(){
 var before=db('SELECT count(*) n FROM tb_conta_gestao_vinculos').n[1];
 assertThrowsType(function(){created('12.345.678/0001-99');},'BusinessDelegation.Forbidden','duplicate generic denial');
 assertEqual(db('SELECT count(*) n FROM tb_conta_gestao_vinculos').n[1],before,'duplicate has no relationship');
 assertEqual(db("SELECT count(*) n FROM tb_conta_usuarios WHERE id_usuario=902").n[1],2,'duplicate no owner');
}
function testOwnerAcceptanceDoesNotActivatePendingAccount(){
 var row=created('20000000000001');var issued=service.inviteOwner(manager,row.id,row.version,' CLIENT@EXAMPLE.TEST ');var token=listLast(issued.url,'=');
 var invite=service.inspectInvite(recipient,token);assertEqual(invite.type,'TITULAR','safe inspected type');
 assertEqual(structKeyExists(invite,'token_hash'),false,'no hash disclosure');assertEqual(structKeyExists(invite,'email_destinatario'),false,'no recipient disclosure');
 assertThrowsType(function(){service.inspectInvite(manager,token);},'BusinessDelegation.Forbidden','outsider cannot inspect');
 assertThrowsType(function(){service.acceptOwner({id=904,email='client@example.test',emailVerified=false},token,invite.version);},'BusinessDelegation.Forbidden','verified email required');
 assertThrowsType(function(){service.acceptOwner({id=904,email='other@example.test',emailVerified=true},token,invite.version);},'BusinessDelegation.Forbidden','current DB email required');
 var accepted=service.acceptOwner(recipient,token,invite.version);
 assertEqual(store.account(clientId(row.id)).status,'PENDENTE','owner does not activate');
 assertEqual(store.membership(904,clientId(row.id)).papel,'OWNER','recipient becomes owner');
 var altered=fields('20000000009999');
 assertThrowsType(function(){service.updatePendingClient(manager,row.id,issued.version,altered);},'BusinessDelegation.Conflict','confirmed document immutable to agency');
 db("UPDATE tb_conta_usuarios SET status='INATIVO' WHERE id_conta=:id",{id={value=clientId(row.id),cfsqltype='cf_sql_bigint'}});
 assertThrowsType(function(){service.inviteOwner(manager,row.id,issued.version,'next@example.test');},'BusinessDelegation.Conflict','inactive owner is still confirmed');
 assertThrowsType(function(){service.acceptOwner(recipient,token,invite.version);},'BusinessDelegation.Conflict','single acceptance');
 assertThrowsType(function(){service.inviteOwner(manager,row.id,store.relationship(row.id).version,'next@example.test');},'BusinessDelegation.Conflict','owner not replaceable');
 db('DELETE FROM tb_conta_usuarios WHERE id_conta=:id',{id={value=clientId(row.id),cfsqltype='cf_sql_bigint'}});
 assertThrowsType(function(){service.inviteOwner(manager,row.id,store.relationship(row.id).version,'next@example.test');},'BusinessDelegation.Conflict','confirmation survives removed membership');
}
function testRequesterCannotBecomeOwnerThroughOwnInvite(){
 var row=created('20000000000002');var invite=service.inviteOwner(manager,row.id,row.version,'owner@example.test');var token=listLast(invite.url,'=');
 assertThrowsType(function(){service.acceptOwner(manager,token,1);},'BusinessDelegation.Forbidden','requester cannot own');
 var renewed=service.inviteOwner(manager,row.id,invite.version,'operator@example.test');
 assertThrowsType(function(){service.acceptOwner({id=903,email='operator@example.test',emailVerified=true},listLast(renewed.url,'='),1);},'BusinessDelegation.Forbidden','any active agency member excluded');
 assertThrowsType(function(){service.acceptOwner(manager,token,1);},'BusinessDelegation.Conflict','renewal cancels old token');
}
function testReviewAndPendingCorrection(){
 var row=created('20000000000003');var issued=service.inviteOwner(manager,row.id,row.version,'client@example.test');
 var revised=fields('20000000003003');revised.email_responsavel='corrected@example.test';
 var collision=fields('12345678000199');
 assertThrowsType(function(){service.updatePendingClient(manager,row.id,issued.version,collision);},'BusinessDelegation.Forbidden','pending correction cannot acquire existing document');
 var updated=service.updatePendingClient(manager,row.id,issued.version,revised);
 assertEqual(db('SELECT documento FROM tb_contas WHERE id_conta=:id',{id={value=clientId(row.id),cfsqltype='cf_sql_bigint'}}).documento[1],'20000000003003','pending document correction');
 assertThrowsType(function(){service.acceptOwner(recipient,listLast(issued.url,'='),1);},'BusinessDelegation.Conflict','corrected contact cancels invitation');
 assertThrowsType(function(){service.updatePendingClient(manager,row.id,issued.version,revised);},'BusinessDelegation.Conflict','stale correction');
 var registrationId=registration(row.id);
 assertThrowsType(function(){service.reviewCreatedClient(manager,registrationId,updated.version,'APPROVE',['events.view']);},'BusinessDelegation.Forbidden','DB admin required');
 for(var mode in ['','DELEGATED','INTERNAL_SIMULATION']) {
  var internal=duplicate(reviewer);if(len(mode)) internal.accessMode=mode;else structDelete(internal,'accessMode');
  assertThrowsType(function(){service.reviewCreatedClient(internal,registrationId,updated.version,'APPROVE',['events.view']);},'BusinessDelegation.Forbidden','non direct review refused');
 }
 assertThrowsType(function(){service.reviewCreatedClient(reviewer,registrationId,updated.version,'APPROVE',['ads.campaigns.manage']);},'BusinessDelegation.Forbidden','review cannot widen');
 var approved=service.reviewCreatedClient(reviewer,registrationId,updated.version,'APPROVE',['events.view']);
 assertEqual(approved.status,'ATIVO','review activates relation');assertEqual(store.account(clientId(row.id)).status,'ATIVA','review activates account');
 assertEqual(store.grants(row.id),['events.view'],'reviewed capabilities');
 assertEqual(store.membership(902,clientId(row.id)),{},'review never agency owner');
 assertEqual(db('SELECT count(*) n FROM ads.tb_ad_vouchers').n[1],0,'review no benefits');
 assertEqual(db('SELECT id_usuario FROM tb_conta_cadastro_solicitacoes WHERE id_solicitacao=:id',{id={value=registrationId,cfsqltype='cf_sql_bigint'}}).id_usuario[1],902,'requester preserved');
 assertEqual(service.has(service.resolve(manager,{accountId=clientId(row.id),managerAccountId=101,relationshipId=row.id,accessMode='DELEGATED'}),'events.view'),true,'review assigns responsible');
 var denied=created('20000000000004');service.reviewCreatedClient(reviewer,registration(denied.id),denied.version,'DECLINE',[]);
 assertEqual(store.relationship(denied.id).status,'RECUSADO','decline');assertEqual(store.account(clientId(denied.id)).status,'PENDENTE','decline no activation');
 service.changeRelationship(manager,row.id,approved.version,'RENOUNCE',[]);
 assertEqual(store.account(clientId(row.id)).status,'ATIVA','renunciation retains ownerless client');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE id_vinculo=:id",{id={value=row.id,cfsqltype='cf_sql_bigint'}}).n[1]>0,true,'renunciation retains audit');
}
function testExactOwnerExpiry(){
 var row=created('20000000000005');clockNow=createDateTime(2026,10,3,12,0,0);
 var accounts=createObject('component','services.accountDelegation.Accounts').init(dsn,store,createObject('component','services.accountDelegation.Policy'),function(){return clockNow;});
 var invite=accounts.inviteOwner(manager,row.id,row.version,'client@example.test');var token=listLast(invite.url,'=');
 assertEqual(len(token),64,'high entropy token');assertEqual(invite.expiresAt,dateAdd('d',7,clockNow),'seven days');
 clockNow=dateAdd('d',7,clockNow);
 assertThrowsType(function(){accounts.acceptOwner(recipient,token,1);},'BusinessDelegation.Conflict','expiry equality');
}
function waitForLock(required string fragment){
 var deadline=getTickCount()+10000;
 while(getTickCount()<deadline){db('SELECT pg_stat_clear_snapshot()');if(db("SELECT count(*) n FROM pg_stat_activity WHERE datname=current_database() AND pid<>pg_backend_pid() AND wait_event_type='Lock' AND query LIKE :fragment",{fragment={value='%' & fragment & '%',cfsqltype='cf_sql_varchar'}}).n[1]>0)return true;sleep(20);}return false;
}
function testConcurrentOwnerAcceptance(){
 var row=created('20000000000006');var invite=service.inviteOwner(manager,row.id,row.version,'client@example.test');var token=listLast(invite.url,'=');var observed=false;
 transaction isolation='read_committed' {
  service.acceptOwner(recipient,token,1);
  thread name='ownerDuplicate' svc=service actor=recipient token=token {try{attributes.svc.acceptOwner(attributes.actor,attributes.token,1);thread.outcome='UNSAFE_SUCCESS';}catch(any e){thread.outcome=e.type;thread.detail=e.message;}}
  observed=waitForLock('SELECT id_conta FROM tb_contas');
 }
 thread action='join' name='ownerDuplicate' timeout=15000;
 assertEqual(observed,true,'owner acceptance independent connection lock');assertEqual(cfthread.ownerDuplicate.outcome,'BusinessDelegation.Conflict','duplicate owner acceptance blocked');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE id_vinculo=:id AND acao='owner.accept'",{id={value=row.id,cfsqltype='cf_sql_bigint'}}).n[1],1,'one owner acceptance audited');
 writeOutput('PASS accounts concurrent owner acceptance, observed real PostgreSQL lock wait' & chr(10));
}
function testConcurrentDocumentCollision(){
 var observed=false;var payload=fields('20000000000007');
 // Separate managers and actors avoid the agency mutex: the document uniqueness constraint decides.
 db("INSERT INTO tb_usuarios VALUES(907,'Other Agency','otheragency@example.test',false,false,false)");
 db("INSERT INTO tb_conta_usuarios(id_conta,id_usuario,papel,status) VALUES(103,907,'ADMIN','ATIVO')");
 transaction isolation='read_committed' {
  created('20000000000007');
  thread name='documentDuplicate' svc=service payload=payload {try{attributes.svc.createClient({id=907,email='otheragency@example.test',emailVerified=true},103,attributes.payload,['events.view']);thread.outcome='UNSAFE_SUCCESS';}catch(any e){thread.outcome=e.type;thread.detail=e.message;}}
  observed=waitForLock('INSERT INTO tb_contas');
 }
 thread action='join' name='documentDuplicate' timeout=15000;
 assertEqual(observed,true,'document unique collision waits on independent connection');assertEqual(cfthread.documentDuplicate.outcome,'BusinessDelegation.Forbidden','constraint collision generic denial');
 assertEqual(db("SELECT count(*) n FROM tb_contas WHERE documento='20000000000007'").n[1],1,'single document account');
 writeOutput('PASS accounts concurrent duplicate document, observed real PostgreSQL lock wait' & chr(10));
}
function testRegularQueuePreserved(){
 var normalBefore=db('SELECT status,id_usuario,id_conta FROM tb_conta_cadastro_solicitacoes WHERE id_solicitacao=4001');
 assertThrowsType(function(){service.reviewCreatedClient(reviewer,4001,1,'APPROVE',['events.view']);},'BusinessDelegation.Forbidden','legacy request not delegation command');
 assertEqual(serializeJSON(db('SELECT status,id_usuario,id_conta FROM tb_conta_cadastro_solicitacoes WHERE id_solicitacao=4001')),serializeJSON(normalBefore),'normal request unchanged');
 db("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO' WHERE id_vinculo=2001");
 var company=service.createRelationshipInvite(recipient,102,101,['events.view']);
 var info=service.inspectInvite(manager,listLast(company.url,'='));assertEqual(info.type,'RELACAO','company invite inspection');
 assertThrowsType(function(){service.acceptOwner(manager,listLast(company.url,'='),1);},'BusinessDelegation.Forbidden','company token not owner token');
 assertThrowsType(function(){service.inspectInvite(reviewer,listLast(company.url,'='));},'BusinessDelegation.Forbidden','unlinked admin not recipient');
 db("INSERT INTO tb_conta_usuarios(id_conta,id_usuario,papel,status) VALUES(101,901,'ADMIN','ATIVO')");
 assertEqual(service.inspectInvite(reviewer,listLast(company.url,'=')).type,'RELACAO','different current company admin may inspect');
}
function testReviewAdapterGuardsAndBypass(){
 var settings=getApplicationSettings();var sources=duplicate(settings.datasources);sources.runnerhub=sources.business_delegation_test;
 application action='update' datasources=sources;
 application.businessAccountDelegationEnabled=true;
 var row=created('20000000000008');
 variables.accountRegistrationRequestId=registration(row.id);variables.accountRegistrationErrors=[];variables.accountRegistrationAction='aprovar';variables.accountRegistrationRedirectUrl='';
 variables.businessAccountContextCsrf='internal-session-csrf';variables.businessAccountsCanAdminAll=true;variables.businessAccountsSimulationActive=false;
 request.businessDelegationIdentity=duplicate(reviewer);
 form.business_account_access_csrf=variables.businessAccountContextCsrf;form.expectedVersion=row.version;form.capabilities='events.view';
 // CLI HTTP fields can be set only in this isolated harness, never runtime hooks.
 application action='update' cgiReadOnly=false;
 cgi.request_method='POST';
 include '../../../administracao/contas/includes/delegation_backend.cfm';
 assertEqual(variables.accountRegistrationDelegationHandled,true,'agency branch intercepted');
 assertEqual(arrayLen(variables.accountRegistrationErrors),0,'adapter approval succeeds');
 assertEqual(store.relationship(row.id).status,'ATIVO','adapter uses real service');assertEqual(store.membership(902,clientId(row.id)),{},'adapter never agency owner');
 variables.accountRegistrationRequestId=4001;variables.accountRegistrationErrors=[];
 include '../../../administracao/contas/includes/delegation_backend.cfm';
 assertEqual(variables.accountRegistrationDelegationHandled,false,'ordinary queue continues legacy path');
 var rejected=created('20000000000009');variables.accountRegistrationRequestId=registration(rejected.id);form.expectedVersion=rejected.version;
 request.businessAccessContext={accessMode='INTERNAL_SIMULATION',actorId=901};
 include '../../../administracao/contas/includes/delegation_backend.cfm';
 assertEqual(variables.accountRegistrationDelegationHandled,true,'simulation still cannot fall through');assertEqual(arrayLen(variables.accountRegistrationErrors)>0,true,'simulation blocked');assertEqual(store.relationship(rejected.id).status,'AGUARDANDO_CONTA','simulation did not approve');
 structDelete(request,'businessAccessContext');variables.accountRegistrationErrors=[];form.business_account_access_csrf='wrong';
 include '../../../administracao/contas/includes/delegation_backend.cfm';
 assertEqual(arrayLen(variables.accountRegistrationErrors)>0,true,'adapter checks csrf');
 var source=fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & '../../../administracao/contas/includes/backend.cfm');
 assertContains(source,'NOT VARIABLES.accountRegistrationDelegationHandled','legacy branch explicitly excludes agency');
}
function assertOwnerTokenDenied(required struct row,required string token,required string label){
 assertThrowsType(function(){service.inspectInvite(recipient,token);},'BusinessDelegation.Conflict',label & ' inspection');
 assertThrowsType(function(){service.acceptOwner(recipient,token,1);},'BusinessDelegation.Conflict',label & ' acceptance');
 assertEqual(db("SELECT count(*) n FROM tb_conta_usuarios WHERE id_conta=:id AND papel='OWNER'",{id={value=clientId(row.id),cfsqltype='cf_sql_bigint'}}).n[1],0,label & ' no owner');
 assertEqual(db("SELECT count(*) n FROM tb_conta_gestao_auditoria WHERE id_vinculo=:id AND acao='owner.accept'",{id={value=row.id,cfsqltype='cf_sql_bigint'}}).n[1],0,label & ' no acceptance audit');
}
function testOwnerInvitationAfterRenunciation(){
 var row=created('20000000000010');row=service.reviewCreatedClient(reviewer,registration(row.id),row.version,'APPROVE',['events.view']);
 var issued=service.inviteOwner(manager,row.id,row.version,'client@example.test');var token=listLast(issued.url,'=');
 service.changeRelationship(manager,row.id,issued.version,'RENOUNCE',[]);
 assertOwnerTokenDenied(row,token,'renounced owner token');
 assertEqual(db('SELECT status FROM tb_conta_gestao_convites WHERE id_convite=:id',{id={value=issued.inviteId,cfsqltype='cf_sql_bigint'}}).status[1],'CANCELADO','renunciation cancels owner token');
 assertEqual(store.account(clientId(row.id)).status,'ATIVA','renunciation retains account');
}
function testOwnerInvitationAfterSuspensionAndReactivation(){
 var row=created('20000000000011');row=service.reviewCreatedClient(reviewer,registration(row.id),row.version,'APPROVE',['events.view']);
 var issued=service.inviteOwner(manager,row.id,row.version,'client@example.test');var token=listLast(issued.url,'=');
 var suspended=service.changeRelationship(reviewer,row.id,issued.version,'SUSPEND',[]);
 assertOwnerTokenDenied(row,token,'suspended owner token');
 var reactivated=service.changeRelationship(reviewer,row.id,suspended.version,'REACTIVATE',[]);
 assertOwnerTokenDenied(row,token,'old owner token after reactivation');
 var fresh=service.inviteOwner(manager,row.id,reactivated.version,'client@example.test');var freshToken=listLast(fresh.url,'=');
 assertEqual(service.inspectInvite(recipient,freshToken).type,'TITULAR','fresh invitation after reactivation');
 service.acceptOwner(recipient,freshToken,1);
 var membership=store.membership(recipient.id,clientId(row.id));
 suspended=service.changeRelationship(reviewer,row.id,fresh.version,'SUSPEND',[]);
 assertEqual(store.membership(recipient.id,clientId(row.id)),membership,'suspension preserves confirmed direct owner');
 service.changeRelationship(recipient,row.id,suspended.version,'REVOKE',[]);
 assertEqual(store.membership(recipient.id,clientId(row.id)),membership,'revocation preserves confirmed direct owner');
 assertEqual(db('SELECT status FROM tb_conta_gestao_convites WHERE id_convite=:id',{id={value=fresh.inviteId,cfsqltype='cf_sql_bigint'}}).status[1],'ACEITO','accepted owner proof preserved');
}
function testOwnerInvitationRechecksCurrentRelationshipState(){
 var row=created('20000000000012');var issued=service.inviteOwner(manager,row.id,row.version,'client@example.test');var token=listLast(issued.url,'=');
 // Model a still-pending legacy token to prove the reader/acceptor enforce current DB state independently of cancellation.
 for(var state in ['REVOGADO','SUSPENSO','RECUSADO','ATIVO']){
  db('UPDATE tb_conta_gestao_vinculos SET status=:status WHERE id_vinculo=:id',{status={value=state,cfsqltype='cf_sql_varchar'},id={value=row.id,cfsqltype='cf_sql_bigint'}});
  assertOwnerTokenDenied(row,token,'incompatible relationship ' & state);
 }
 db("UPDATE tb_conta_gestao_vinculos SET status='AGUARDANDO_CONTA' WHERE id_vinculo=:id",{id={value=row.id,cfsqltype='cf_sql_bigint'}});
 db("UPDATE tb_contas SET status='ATIVA' WHERE id_conta=:id",{id={value=clientId(row.id),cfsqltype='cf_sql_bigint'}});
 assertOwnerTokenDenied(row,token,'waiting relation with active account');
}
// Fixture 4001 represents an ordinary registration, not agency provenance.
db('UPDATE tb_conta_cadastro_solicitacoes SET origem_gestora_id=NULL,gestao_vinculo_id=NULL WHERE id_solicitacao=4001');
testOwnerInvitationAfterRenunciation();testOwnerInvitationAfterSuspensionAndReactivation();testOwnerInvitationRechecksCurrentRelationshipState();testNewClientHasNoAgencyOwner();testDuplicateDocumentDoesNotGrantAccess();testOwnerAcceptanceDoesNotActivatePendingAccount();testRequesterCannotBecomeOwnerThroughOwnInvite();testReviewAndPendingCorrection();testExactOwnerExpiry();testConcurrentOwnerAcceptance();testConcurrentDocumentCollision();testRegularQueuePreserved();testReviewAdapterGuardsAndBypass();
</cfscript>
