<cfscript>
dsn=application.delegationTest.datasource;
function db(required string statement,struct params={}) { return queryExecute(statement,params,{datasource=dsn}); }
service=createObject('component','services.BusinessAccountDelegation').init(dsn,true);
store=createObject('component','services.accountDelegation.Store').init(dsn);
manager={id=902,email='owner@example.test',emailVerified=true,accessMode='DIRECT'};
operator={id=903,email='operator@example.test',emailVerified=true,accessMode='DIRECT'};
clientOwner={id=904,email='client@example.test',emailVerified=true,accessMode='DIRECT'};
internal={id=901,email='reviewer@example.test',emailVerified=true,accessMode='DIRECT'};
db('UPDATE tb_usuarios SET is_admin=true WHERE id=901');
db("ALTER TABLE tb_conta_cadastro_solicitacoes ADD COLUMN nome_empresa text,ADD COLUMN tipo_titular text,ADD COLUMN documento text,ADD COLUMN nome_responsavel text,ADD COLUMN email_responsavel text,ADD COLUMN telefone_responsavel text,ADD COLUMN site text,ADD COLUMN cidade text,ADD COLUMN estado text,ADD COLUMN tipo_prestador text,ADD COLUMN mensagem text,ADD COLUMN data_criacao timestamptz DEFAULT now()");
db("UPDATE tb_conta_cadastro_solicitacoes SET nome_empresa='Pending Client',tipo_titular='PJ',documento='20000000000014',nome_responsavel='Pending Owner',email_responsavel='client@example.test',tipo_prestador='Organizador' WHERE id_solicitacao=4001");

function testPortfolioOnlyAssignedClients(){
    var owned=service.listClients(manager,101,{page=1});
    assertEqual(owned.pageSize,25,'pagination');
    assertEqual(owned.total,2,'owner sees accepted and own pending client');
    var staff=service.listClients(operator,101,{page=1});
    assertEqual(staff.total,1,'staff sees only assigned relationship');
    assertEqual(staff.items[1].clientId,102,'staff assigned client');
    var unassignedCampaignRows=0;
    for(var item in staff.items)if(structKeyExists(item,'campaigns') || structKeyExists(item,'events'))unassignedCampaignRows++;
    assertEqual(unassignedCampaignRows,0,'management is not data access');
    assertThrowsType(function(){service.listClients(operator,103,{});},'BusinessDelegation.Forbidden','filter is direct manager membership, not selection');
}
function testManagerCanAssignWithoutReadingUnassignedData(){
    db("INSERT INTO tb_contas(id_conta,nome_conta,status) VALUES(105,'Other Client','ATIVA')");
    db("INSERT INTO tb_conta_gestao_vinculos(id_vinculo,id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante) VALUES(2004,101,105,'CONVITE_CLIENTE','ATIVO',902)");
    db("INSERT INTO tb_conta_gestao_permissoes SELECT 2004,id_permissao FROM tb_business_permissoes WHERE codigo='events.view'");
    assertEqual(service.listClients(operator,101,{}).total,1,'staff does not see unassigned metadata');
    var ownerPage=service.listClients(manager,101,{});assertEqual(ownerPage.total,3,'manager sees own portfolio metadata');
    assertEqual(structKeyExists(ownerPage.items[1],'eventRows'),false,'portfolio does not read event rows');
    var result=service.assignMember(manager,2004,1002,1,['events.view']);
    assertEqual(result.status,'ATIVO','manager may assign');
    assertEqual(service.listClients(operator,101,{}).total,2,'assigned client appears only after grant');
}
function testOwnerCanRevokeAgency(){
    var rows=service.listClientManagers(clientOwner,102);
    assertEqual(arrayLen(rows),2,'direct client owner sees both agencies');
    var relation=service.changeRelationship(clientOwner,2002,1,'REVOKE',[]);
    assertEqual(relation.status,'REVOGADO','owner revokes agency');
    assertEqual(service.listClientManagers(clientOwner,102)[2].status,'REVOGADO','client list shows revoked state');
}
function testPendingClientVisibleWithoutModuleAccess(){
    var page=service.listClients(manager,101,{state='AGUARDANDO_CONTA'});
    assertEqual(page.total,1,'pending client visible');
    assertEqual(page.items[1].clientId,104,'pending client identity');
    assertEqual(page.items[1].pendingFields.nome_empresa,'Pending Client','pending edit fields from own creation');
    assertThrowsType(function(){service.resolve(manager,{accountId=104,accessMode='DELEGATED',managerAccountId=101,relationshipId=2003});},'BusinessDelegation.Forbidden','pending has no module access');
}
function testTabsPreserveFilters(){
    var page=service.listClients(manager,101,{page=2,search='Client',state='ATIVO'});
    assertEqual(page.page,2,'requested page is preserved');
    assertEqual(page.pageSize,25,'page size');
    assertEqual(service.listTeam(manager,101,{page=1}).pageSize,25,'team pagination');
    var team=service.listTeam(manager,101,{search='Operator'});
    assertEqual(team.items[1].assignments[1].assignmentId,3002,'team assignment displayed for removal');
    assertEqual(service.listInvites(manager,101,{page=1}).pageSize,25,'invitation pagination');
    assertEqual(service.listAudit(manager,101,{page=1}).pageSize,25,'audit pagination');
    var view=createObject('component','services.accountDelegation.WorkspaceView');
    var link=view.tabUrl(101,'equipe',{search='Client & Cia',state='ATIVO',page=2});
    assertContains(link,'tab=equipe','tab direct link');
    assertContains(link,'busca=Client%20%26%20Cia','search escaped in link');
    assertContains(link,'estado=ATIVO','state retained');
    assertContains(link,'pagina=2','page retained');
    assertEqual(view.capabilities({cap_ads_campaigns_view='1',cap_events_manage='1'}),['ads.campaigns.view','events.manage'],'unique checkbox capability names');
    assertThrowsType(function(){view.capabilities({cap_events_view=['1','1']});},'BusinessDelegation.Validation','duplicate checkbox rejected');
}
function testInternalDirectOnly(){
    assertThrowsType(function(){service.configureManager(manager,102,true,'AGENCIA',0);},'BusinessDelegation.Forbidden','member not db admin');
    for(var mode in ['DELEGATED','INTERNAL_SIMULATION']){
      var forged=duplicate(internal);forged.accessMode=mode;
      assertThrowsType(function(){service.configureManager(forged,102,true,'AGENCIA',0);},'BusinessDelegation.Forbidden','admin mode direct only');
      assertThrowsType(function(){service.changeRelationship(forged,2001,1,'SUSPEND',[]);},'BusinessDelegation.Forbidden','suspension direct only');
    }
    var configured=service.configureManager(internal,102,true,'AGENCIA',0);
    assertEqual(configured.version,1,'new manager config version');
}
function testWorkspaceRender(){
    VARIABLES.wsManagers=db('SELECT id_conta,nome_conta FROM tb_contas WHERE id_conta=101');
    VARIABLES.wsManagerId=101;VARIABLES.wsTab='clientes';VARIABLES.wsFilters={search='Client',state='ATIVO',page=2};
    VARIABLES.wsView=createObject('component','services.accountDelegation.WorkspaceView');
    VARIABLES.wsClientPage=service.listClients(manager,101,{state='AGUARDANDO_CONTA'});
    VARIABLES.wsTeamPage={items=[],page=1,pageSize=25,total=0};VARIABLES.wsInvitesPage=VARIABLES.wsTeamPage;VARIABLES.wsAuditPage=VARIABLES.wsTeamPage;
    VARIABLES.wsPage=VARIABLES.wsClientPage;VARIABLES.wsCanManage=true;VARIABLES.wsError='';VARIABLES.wsNotice='';VARIABLES.wsIssuedLink='';VARIABLES.wsCsrf='test-csrf';
    VARIABLES.wsLink=VARIABLES.wsView.tabUrl(101,'clientes',VARIABLES.wsFilters);
    savecontent variable='html'{include '../../../gestao-clientes/home.cfm';}
    assertContains(html,'Titular ainda não confirmado','ownership');
    assertContains(html,'aria-current="page"','current tab');
    assertContains(html,'Equipe','team tab rendered');
    assertContains(html,'Client','search rendered');
}
function testPendingOwnerFreshLogin(){
    db("UPDATE tb_conta_cadastro_solicitacoes SET id_usuario=902 WHERE id_solicitacao=4001");
    db("INSERT INTO tb_conta_usuarios(id_conta_usuario,id_conta,id_usuario,papel,status) VALUES(1007,104,904,'OWNER','ATIVO'),(1008,104,903,'OPERADOR','ATIVO')");
    db("INSERT INTO tb_conta_gestao_convites(tipo,id_conta,id_vinculo,email_destinatario,token_hash,id_usuario_autor,id_usuario_aceite,status) VALUES('TITULAR',104,2003,'client@example.test',repeat('a',64),902,904,'ACEITO')");
    var pending=createObject('component','services.accountDelegation.Workspace').init(store,createObject('component','services.accountDelegation.Policy')).pendingOwnerRegistration(clientOwner);
    assertEqual(pending.id_conta,104,'fresh recipient sees pending account');
    assertEqual(pending.id_solicitacao,4001,'recipient gets original agency-created protocol');
    assertEqual(createObject('component','services.accountDelegation.Workspace').init(store,createObject('component','services.accountDelegation.Policy')).pendingOwnerRegistration(operator),{},'other role cannot read pending registration');
    assertThrowsType(function(){service.resolve(clientOwner,{accountId=104,accessMode='DIRECT',managerAccountId=0,relationshipId=0});},'BusinessDelegation.Forbidden','accepted owner has no operations before approval');
}
function testAdminAndOwnerPanelsRender(){
    var settings=getApplicationSettings();var sources=duplicate(settings.datasources);sources.runnerhub=sources.business_delegation_test;
    application action='update' datasources=sources sessionmanagement=true;
    application.businessAccountDelegationEnabled=true;
    REQUEST.businessDelegationIdentity=internal;
    VARIABLES.businessAccountsSimulationActive=false;VARIABLES.businessAccountsCanAdminAll=true;VARIABLES.businessAccountContextCsrf='test-csrf';VARIABLES.accountsPage=1;
    qBusinessAccountEdit=db('SELECT id_conta,nome_conta FROM tb_contas WHERE id_conta=102');
    savecontent variable='adminBackendOutput'{include '../../../administracao/contas/includes/delegation_workspace_backend.cfm';}
    VARIABLES.accountManagementTab='gestoras';
    savecontent variable='adminHtml'{include '../../../administracao/contas/delegation_home.cfm';include '../../../administracao/contas/delegation_queue.cfm';}
    assertContains(adminHtml,'Configuração interna','admin config rendered');
    assertContains(adminHtml,'Clientes criados por gestoras','agency review queue rendered');
    assertContains(adminHtml,'expectedVersion','review uses relationship version');
    REQUEST.businessDelegationIdentity=clientOwner;VARIABLES.businessAccountsCanAdminAll=false;
    savecontent variable='ownerBackendOutput'{include '../../../administracao/contas/includes/delegation_workspace_backend.cfm';}
    savecontent variable='ownerHtml'{include '../../../administracao/contas/delegation_home.cfm';}
    assertContains(ownerHtml,'Confirmar revogação','direct owner revoke UI');
}
function testUnacceptedOutboundHidden(){
    db("INSERT INTO tb_contas(id_conta,nome_conta,status) VALUES(106,'Prospect Secret','ATIVA')");
    db("INSERT INTO tb_conta_gestao_vinculos(id_vinculo,id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante) VALUES(2006,101,106,'SOLICITACAO_GESTORA','PENDENTE_CLIENTE',902)");
    db("INSERT INTO tb_conta_gestao_convites(tipo,id_conta,id_vinculo,email_destinatario,token_hash,id_usuario_autor) VALUES('RELACAO',106,2006,'secret@example.test',repeat('b',64),902)");
    db("INSERT INTO tb_conta_gestao_auditoria(id_usuario_ator,id_conta_gestora,id_conta_cliente,id_vinculo,acao,recurso_tipo,recurso_id,resultado) VALUES(902,101,106,2006,'relationship.request','RELATIONSHIP','2006','SUCCESS')");
    var secret={search='Prospect Secret'};
    assertEqual(service.listClients(manager,101,secret).total,0,'unaccepted outbound hidden from portfolio count');
    assertEqual(service.listInvites(manager,101,secret).total,0,'unaccepted outbound hidden from invitation count');
    assertEqual(service.listAudit(manager,101,secret).total,0,'unaccepted outbound hidden from audit count');
    assertEqual(service.listTeam(manager,101,secret).total,0,'unaccepted outbound hidden from team count');
    db("UPDATE tb_conta_gestao_vinculos SET status='REVOGADO' WHERE id_vinculo=2006");
    assertEqual(service.listClients(manager,101,secret).total,0,'never accepted revoked outbound stays hidden');
    db("UPDATE tb_conta_gestao_vinculos SET id_usuario_aprovador_cliente=904 WHERE id_vinculo=2002");
    assertEqual(service.listClients(manager,103,{state='REVOGADO'}).total,1,'previously approved revoked relationship remains visible');
}
function testWorkspaceBackendGet(){
    REQUEST.businessDelegationIdentity=manager;
    REQUEST.businessDelegationService=service;
    application.businessAccountDelegationEnabled=true;
    savecontent variable='workspaceBackendOutput'{include '../../../gestao-clientes/includes/backend.cfm';}
    assertEqual(VARIABLES.wsManagerId,101,'workspace selects verified direct manager');
    assertEqual(VARIABLES.wsClientPage.pageSize,25,'workspace backend obtains paginated service data');
}
function testStaffHistoryRequiresCurrentAssignment(){
    db("INSERT INTO tb_conta_gestao_convites(tipo,id_conta,id_vinculo,email_destinatario,token_hash,id_usuario_autor) VALUES('RELACAO',102,2001,'client@example.test',repeat('c',64),902)");
    db("INSERT INTO tb_conta_gestao_auditoria(id_usuario_ator,id_conta_gestora,id_conta_cliente,id_vinculo,acao,recurso_tipo,recurso_id,resultado) VALUES(902,101,102,2001,'invitation.issue','INVITATION','5009','SUCCESS')");
    db("UPDATE tb_conta_usuarios SET papel='OPERADOR' WHERE id_conta_usuario=1001");
    assertEqual(service.listInvites(manager,101,{search='Client One'}).total,1,'downgraded assigned actor sees own invite');
    assertEqual(service.listAudit(manager,101,{search='Client One'}).total>0,true,'downgraded assigned actor sees own audit');
    db("UPDATE tb_conta_gestao_equipe SET status='REMOVIDO' WHERE id_equipe=3001");
    assertEqual(service.listInvites(manager,101,{search='Client One'}).total,0,'unassigned staff invite total hidden');
    assertEqual(arrayLen(service.listInvites(manager,101,{search='Client One'}).items),0,'unassigned staff invite rows hidden');
    assertEqual(service.listAudit(manager,101,{search='Client One'}).total,0,'unassigned staff audit total hidden');
    assertEqual(arrayLen(service.listAudit(manager,101,{search='Client One'}).items),0,'unassigned staff audit rows hidden');
    db("UPDATE tb_conta_usuarios SET papel='OWNER' WHERE id_conta_usuario=1001");
    db("UPDATE tb_conta_gestao_equipe SET status='ATIVO' WHERE id_equipe=3001");
}
function testApprovedUnconfirmedOwnerRender(){
    db("INSERT INTO tb_contas(id_conta,nome_conta,status) VALUES(107,'Approved Unconfirmed','ATIVA')");
    db("INSERT INTO tb_conta_gestao_vinculos(id_vinculo,id_conta_gestora,id_conta_cliente,origem,status,id_usuario_solicitante) VALUES(2007,101,107,'CRIACAO_GESTORA','ATIVO',902)");
    VARIABLES.wsManagers=db('SELECT id_conta,nome_conta FROM tb_contas WHERE id_conta=101');
    VARIABLES.wsManagerId=101;VARIABLES.wsTab='clientes';VARIABLES.wsFilters={search='Approved Unconfirmed',state='ATIVO',page=1};
    VARIABLES.wsView=createObject('component','services.accountDelegation.WorkspaceView');
    VARIABLES.wsClientPage=service.listClients(manager,101,VARIABLES.wsFilters);
    VARIABLES.wsTeamPage={items=[],page=1,pageSize=25,total=0};VARIABLES.wsInvitesPage=VARIABLES.wsTeamPage;VARIABLES.wsAuditPage=VARIABLES.wsTeamPage;
    VARIABLES.wsPage=VARIABLES.wsClientPage;VARIABLES.wsCanManage=true;VARIABLES.wsError='';VARIABLES.wsNotice='';VARIABLES.wsIssuedLink='';VARIABLES.wsCsrf='test-csrf';
    VARIABLES.wsLink=VARIABLES.wsView.tabUrl(101,'clientes',VARIABLES.wsFilters);
    savecontent variable='approvedHtml'{include '../../../gestao-clientes/home.cfm';}
    assertContains(approvedHtml,'Titular ainda não confirmado','approved creation still warns');
    assertContains(approvedHtml,'Emitir ou renovar link','approved creation still invites owner');
    assertEqual(find('Corrigir cadastro pendente',approvedHtml),0,'approved creation has no pending correction');
}
function testRenderedWorkspaceContext(){
    db("INSERT INTO tb_usuarios(id,name,email) SELECT 10000+i,'A Member '||i,'member'||i||'@example.test' FROM generate_series(1,25) AS i");
    db("INSERT INTO tb_conta_usuarios(id_conta_usuario,id_conta,id_usuario,papel,status) SELECT 11000+i,101,10000+i,'OPERADOR','ATIVO' FROM generate_series(1,25) AS i");
    VARIABLES.wsManagers=db('SELECT id_conta,nome_conta FROM tb_contas WHERE id_conta=101');
    VARIABLES.wsManagerId=101;VARIABLES.wsTab='equipe';VARIABLES.wsFilters={search='example.test',state='ATIVO',page=2};
    VARIABLES.wsView=createObject('component','services.accountDelegation.WorkspaceView');
    VARIABLES.wsLink=VARIABLES.wsView.tabUrl(101,'equipe',VARIABLES.wsFilters);
    VARIABLES.wsClientPage=service.listClients(manager,101,{});VARIABLES.wsTeamPage=service.listTeam(manager,101,VARIABLES.wsFilters);
    VARIABLES.wsInvitesPage={items=[],page=1,pageSize=25,total=0};VARIABLES.wsAuditPage=VARIABLES.wsInvitesPage;
    VARIABLES.wsPage=VARIABLES.wsTeamPage;VARIABLES.wsCanManage=true;VARIABLES.wsError='';VARIABLES.wsNotice='';VARIABLES.wsIssuedLink='';VARIABLES.wsCsrf='test-csrf';
    savecontent variable='postedHtml'{include '../../../gestao-clientes/home.cfm';}
    assertEqual(arrayLen(VARIABLES.wsTeamPage.items)>0,true,'page two has a real form');
    assertContains(postedHtml,'action="' & encodeForHTMLAttribute(VARIABLES.wsLink) & '"','rendered POST retains canonical context');
    assertContains(postedHtml,'name="assignment_target"','page two assignment form visible');
}
testPortfolioOnlyAssignedClients();
testManagerCanAssignWithoutReadingUnassignedData();
testOwnerCanRevokeAgency();
testPendingClientVisibleWithoutModuleAccess();
testTabsPreserveFilters();
testInternalDirectOnly();
testWorkspaceRender();
testPendingOwnerFreshLogin();
testAdminAndOwnerPanelsRender();
testUnacceptedOutboundHidden();
testWorkspaceBackendGet();
testApprovedUnconfirmedOwnerRender();
testRenderedWorkspaceContext();
testStaffHistoryRequiresCurrentAssignment();
</cfscript>
