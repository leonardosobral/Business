<cfscript>
dsn=application.delegationTest.datasource;
function db(required string sql,struct params={}){return queryExecute(sql,params,{datasource=application.delegationTest.datasource});}
function param(required any value){return {value=value,cfsqltype='cf_sql_bigint'};}
service=createObject('component','services.BusinessAccountDelegation').init(dsn,true);
policy=createObject('component','services.accountDelegation.Policy');
manager={id=902,email='owner@example.test',emailVerified=true};
recipient={id=904,email='client@example.test',emailVerified=true};
function testLoginReturnIsLocal(){
 var returns=createObject('component','services.accountDelegation.InviteReturn');var state={};
 assertEqual(returns.capture(state,repeatString('a',64)),true,'opaque return recorded');
 assertEqual(returns.consumeRedirect(state),'/convites/','fixed local return');
 state.invitePendingReturn='//outside.example';
 var externalRedirectAccepted=returns.consumeRedirect(state)=='//outside.example';
 assertEqual(externalRedirectAccepted,false,'local return');
 assertEqual(returns.capture(state,'https://outside.example'),false,'external token input rejected');
 assertEqual(returns.pendingToken(state),'','invalid token clears previous invitation state');
 assertEqual(returns.consumeRedirect(state),'','invalid return cleared');
 assertEqual(policy.routePolicy('/convites/','POST',{}, {action='accept'}).allowed,true,'receiver accepts explicit action');
 assertEqual(policy.routePolicy('/convites/','POST',{}, {action='reject'}).allowed,true,'receiver rejects explicit action');
 assertEqual(policy.routePolicy('/convites/','POST',{}, {business_delegation_action='accept_owner'}).allowed,false,'old shared action refused');
 assertEqual(policy.routePolicy('/gestao-clientes/','POST',{}, {action='accept'}).allowed,false,'receiver action isolated');
 assertEqual(policy.routePolicy('/convites/','GET',{token='opaque'},{}).allowed,true,'token GET is inert route');
 assertEqual(policy.routePolicy('/convites/','GET',{token='opaque',redirect='//outside.example'},{}).allowed,false,'receiver GET accepts only token');
 assertEqual(policy.routePolicy('/convites/','POST',{token='opaque'},{action='accept'}).allowed,false,'receiver POST has no query token');
}
function testScannerGetDoesNotConsume(){
 db("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO' WHERE id_vinculo=2001");
 var issued=service.createRelationshipInvite(recipient,102,101,['events.view']);
 var token=listLast(issued.url,'=');var inspected=service.inspectInvite(manager,token);
 var statusBeforePost=db('SELECT status FROM tb_conta_gestao_convites WHERE id_convite=:id',{id=param(inspected.id)}).status[1];
 assertEqual(statusBeforePost,'PENDENTE','GET inert');
 assertEqual(inspected.type,'RELACAO','company type comes from service');
 assertEqual(inspected.accountId,101,'current receiving company');
 assertEqual(inspected.clientAccountId,102,'authorized client account ID');
 assertEqual(inspected.clientAccountName,'Client One','authorized current client name');
 assertEqual(inspected.clientAccountStatus,'ATIVA','authorized current client status');
 assertEqual(inspected.managerAccountName,'Manager One','authorized linked agency name');
 assertThrowsType(function(){service.inspectInvite({id=905,email='viewer@example.test',emailVerified=true},token);},'BusinessDelegation.Forbidden','ineligible company member denied');
 var decided=service.decideRelationship(manager,inspected.relationshipId,inspected.relationshipVersion,'DECLINE',[]);
 assertEqual(decided.status,'RECUSADO','explicit company reject');
 assertThrowsType(function(){service.inspectInvite(manager,token);},'BusinessDelegation.Conflict','consumed token cannot inspect');
}
function testWrongEmailCannotInspect(){
 db("CREATE TYPE tipo_titular_conta AS ENUM('PF','PJ')");
 db("CREATE TYPE status_conta AS ENUM('PENDENTE','ATIVA','SUSPENSA','CANCELADA')");
 db("CREATE TYPE status_conta_cadastro_solicitacao AS ENUM('PENDENTE','APROVADA','RECUSADA')");
 db("CREATE TYPE status_usuario_conta AS ENUM('ATIVO','INATIVO','CONVIDADO','BLOQUEADO')");
 db("CREATE SEQUENCE receiver_fixture_ids START 5000");
 db("ALTER TABLE tb_contas ALTER COLUMN id_conta SET DEFAULT nextval('receiver_fixture_ids'), ADD COLUMN tipo_titular tipo_titular_conta, ADD COLUMN documento varchar(20) UNIQUE, ADD COLUMN nome_titular varchar(200), ADD COLUMN email_principal varchar(255), ADD COLUMN telefone_principal varchar(30), ADD COLUMN data_atualizacao timestamptz DEFAULT now()");
 db("ALTER TABLE tb_conta_usuarios ALTER COLUMN id_conta_usuario SET DEFAULT nextval('receiver_fixture_ids'), ADD COLUMN usuario_convite bigint, ADD COLUMN data_convite timestamptz, ADD COLUMN data_aceite timestamptz, ADD COLUMN data_atualizacao timestamptz DEFAULT now()");
 db("ALTER TABLE tb_conta_cadastro_solicitacoes ALTER COLUMN id_solicitacao SET DEFAULT nextval('receiver_fixture_ids'), ADD COLUMN nome_empresa varchar(160), ADD COLUMN tipo_titular tipo_titular_conta, ADD COLUMN documento varchar(20), ADD COLUMN nome_responsavel varchar(200), ADD COLUMN email_responsavel varchar(255), ADD COLUMN telefone_responsavel varchar(30), ADD COLUMN site varchar(256), ADD COLUMN cidade varchar(128), ADD COLUMN estado varchar(2), ADD COLUMN tipo_prestador varchar(80), ADD COLUMN mensagem text, ADD COLUMN id_usuario_revisor bigint, ADD COLUMN data_revisao timestamptz");
 db("CREATE SCHEMA ads");db("CREATE TABLE ads.tb_ad_vouchers(id_conta bigint,credito numeric)");
 var fields={nome_empresa='Receiver Client',tipo_titular='PJ',documento='55555555555555',nome_responsavel='Receiver',email_responsavel='client@example.test',telefone_responsavel='',site='',cidade='',estado='',tipo_prestador='Organizador',mensagem=''};
 var created=service.createClient(manager,101,fields,['events.view']);
 var issued=service.inviteOwner(manager,created.id,created.version,'client@example.test');var token=listLast(issued.url,'=');
 assertThrowsType(function(){service.inspectInvite({id=903,email='operator@example.test',emailVerified=true},token);},'BusinessDelegation.Forbidden','wrong verified email');
 assertThrowsType(function(){service.inspectInvite({id=904,email='CLIENT+ALIAS@example.test',emailVerified=true},token);},'BusinessDelegation.Forbidden','address exact including plus suffix');
 var own=service.inspectInvite(recipient,token);assertEqual(own.type,'TITULAR','own verified email');
 assertEqual(own.clientAccountName,'Receiver Client','owner sees current client name');
 assertEqual(own.clientAccountStatus,'PENDENTE','owner sees pending state before consent');
 assertEqual(own.managerAccountName,'Manager One','owner sees linked agency before consent');
 return {token=token,accountId=db('SELECT id_conta_cliente FROM tb_conta_gestao_vinculos WHERE id_vinculo=:id',{id=param(created.id)}).id_conta_cliente[1]};
}
function testAuthenticatedNonmemberCanAcceptOwnInvite(required struct ownerInvite){
 var inspected=service.inspectInvite(recipient,ownerInvite.token);
 var result=service.acceptOwner(recipient,ownerInvite.token,inspected.version);
 assertEqual(result.status,'ACEITO','recipient accepted');
 assertEqual(db("SELECT count(*) n FROM tb_conta_usuarios WHERE id_conta=:id AND id_usuario=904 AND papel='OWNER' AND status='ATIVO'",{id=param(ownerInvite.accountId)}).n[1],1,'verified nonmember acquired only own direct owner');
 assertThrowsType(function(){service.acceptOwner(recipient,ownerInvite.token,inspected.version);},'BusinessDelegation.Conflict','single use');
}
function testOwnerReject(){
 var fields={nome_empresa='Rejected Client',tipo_titular='PJ',documento='66666666666666',nome_responsavel='Receiver',email_responsavel='client@example.test',telefone_responsavel='',site='',cidade='',estado='',tipo_prestador='Organizador',mensagem=''};
 var created=service.createClient(manager,101,fields,['events.view']);var issued=service.inviteOwner(manager,created.id,created.version,'client@example.test');var token=listLast(issued.url,'=');var inspected=service.inspectInvite(recipient,token);
 assertThrowsType(function(){service.rejectOwner(manager,token,inspected.version);},'BusinessDelegation.Forbidden','other actor cannot reject');
 var rejected=service.rejectOwner(recipient,token,inspected.version);
 assertEqual(rejected.status,'RECUSADO','owner explicitly refused');
 assertThrowsType(function(){service.inspectInvite(recipient,token);},'BusinessDelegation.Conflict','rejected owner token consumed');
 assertEqual(db("SELECT count(*) n FROM tb_conta_usuarios WHERE id_conta=:id AND id_usuario=904",{id=param(inspected.accountId)}).n[1],0,'rejection grants no membership');
}
testLoginReturnIsLocal();testScannerGetDoesNotConsume();var ownerInvite=testWrongEmailCannotInspect();testAuthenticatedNonmemberCanAcceptOwnInvite(ownerInvite);testOwnerReject();
var httpFields={nome_empresa='HTTP <Client> & Co',tipo_titular='PJ',documento='77777777777777',nome_responsavel='Receiver',email_responsavel='client@example.test',telefone_responsavel='',site='',cidade='',estado='',tipo_prestador='Organizador',mensagem=''};
db("INSERT INTO tb_usuarios(id,name,email) VALUES(907,'New Recipient','new@example.test')");
httpFields.email_responsavel='new@example.test';
var httpCreated=service.createClient(manager,101,httpFields,['events.view']);var httpIssued=service.inviteOwner(manager,httpCreated.id,httpCreated.version,'new@example.test');
db('CREATE TABLE receiver_http_invites(kind text NOT NULL,token text NOT NULL,invite_id bigint NOT NULL)');
db("INSERT INTO receiver_http_invites(kind,token,invite_id) VALUES('OWNER',:token,:id)",{token={value=listLast(httpIssued.url,'='),cfsqltype='cf_sql_varchar'},id=param(httpIssued.inviteId)});
var companyIssued=service.createRelationshipInvite(recipient,102,101,['events.view']);
db("INSERT INTO receiver_http_invites(kind,token,invite_id) VALUES('COMPANY',:token,:id)",{token={value=listLast(companyIssued.url,'='),cfsqltype='cf_sql_varchar'},id=param(companyIssued.inviteId)});
httpFields.nome_empresa='HTTP Reject Client';httpFields.documento='88888888888888';
var rejectCreated=service.createClient(manager,101,httpFields,['events.view']);var rejectIssued=service.inviteOwner(manager,rejectCreated.id,rejectCreated.version,'new@example.test');
db("INSERT INTO receiver_http_invites(kind,token,invite_id) VALUES('REJECT',:token,:id)",{token={value=listLast(rejectIssued.url,'='),cfsqltype='cf_sql_varchar'},id=param(rejectIssued.inviteId)});
// Only the disposable HTTP fixture needs the legacy callback's surrounding schema.
db("ALTER TABLE tb_usuarios ADD CONSTRAINT receiver_email_unique UNIQUE(email), ADD COLUMN imagem_usuario text, ADD COLUMN password text, ADD COLUMN verification_key text, ADD COLUMN is_email_verified boolean DEFAULT false, ADD COLUMN optin_usuario boolean DEFAULT false, ADD COLUMN data_alteracao timestamptz DEFAULT now()");
db("ALTER TABLE tb_usuarios ALTER COLUMN id SET DEFAULT nextval('receiver_fixture_ids')");
db("ALTER TABLE tb_contas ALTER COLUMN status TYPE status_conta USING CAST(status AS status_conta)");
db("ALTER TABLE tb_conta_usuarios ALTER COLUMN status TYPE status_usuario_conta USING CAST(status AS status_usuario_conta)");
db("ALTER TABLE tb_conta_cadastro_solicitacoes ALTER COLUMN status TYPE status_conta_cadastro_solicitacao USING CAST(status AS status_conta_cadastro_solicitacao)");
db("CREATE TABLE tb_log(log_item text,log_item_id text,log_user text,site text)");
</cfscript>
