<cfscript>
if(!structKeyExists(REQUEST,'businessDelegationIdentity') || !isStruct(REQUEST.businessDelegationIdentity) || !structKeyExists(REQUEST.businessDelegationIdentity,'emailVerified') || !REQUEST.businessDelegationIdentity.emailVerified){
    cfheader(statuscode=403,statustext='Forbidden');abort;
}
VARIABLES.wsIdentity=REQUEST.businessDelegationIdentity;
VARIABLES.wsService=structKeyExists(REQUEST,'businessDelegationService')?REQUEST.businessDelegationService:createObject('component','services.BusinessAccountDelegation').init('runnerhub',structKeyExists(APPLICATION,'businessAccountDelegationEnabled') && APPLICATION.businessAccountDelegationEnabled);
VARIABLES.wsView=createObject('component','services.accountDelegation.WorkspaceView');
VARIABLES.wsError='';VARIABLES.wsNotice='';VARIABLES.wsIssuedLink='';
if(!structKeyExists(SESSION,'businessWorkspaceCsrf'))SESSION.businessWorkspaceCsrf=lCase(hash(createUUID() & now() & getTickCount(),'SHA-256'));
VARIABLES.wsCsrf=SESSION.businessWorkspaceCsrf;
VARIABLES.wsManagers=queryExecute("SELECT c.id_conta,c.nome_conta,g.classificacao,m.papel FROM tb_conta_usuarios m JOIN tb_contas c ON c.id_conta=m.id_conta JOIN tb_conta_gestoras g ON g.id_conta=c.id_conta WHERE m.id_usuario=:actor AND m.status='ATIVO' AND m.papel IN('OWNER','ADMIN','OPERADOR','VISUALIZADOR') AND c.status='ATIVA' AND g.habilitada=true ORDER BY c.nome_conta,c.id_conta",{actor={value=VARIABLES.wsIdentity.id,cfsqltype='cf_sql_integer'}},{datasource='runnerhub'});
if(!VARIABLES.wsManagers.recordCount){cfheader(statuscode=403,statustext='Forbidden');abort;}
VARIABLES.wsManagerId=VARIABLES.wsManagers.id_conta[1];
if(structKeyExists(URL,'gestora')){
    if(!isSimpleValue(URL.gestora) || !reFind('^[1-9][0-9]*$',URL.gestora & '')){cfheader(statuscode=400,statustext='Bad Request');abort;}
    VARIABLES.wsManagerId=val(URL.gestora);
}
if(CGI.request_method=='POST' && structKeyExists(FORM,'business_delegation_action')){
    if(!structKeyExists(FORM,'workspace_manager') || !isSimpleValue(FORM.workspace_manager) || !reFind('^[1-9][0-9]*$',FORM.workspace_manager & '') || (structKeyExists(URL,'gestora') && val(URL.gestora)!=val(FORM.workspace_manager))){cfheader(statuscode=400,statustext='Bad Request');abort;}
    VARIABLES.wsManagerId=val(FORM.workspace_manager);
}
VARIABLES.wsCanManage=false;
VARIABLES.wsManagerAllowed=false;
for(VARIABLES.wsManagerRow in VARIABLES.wsManagers){if(VARIABLES.wsManagerRow.id_conta==VARIABLES.wsManagerId){VARIABLES.wsManagerAllowed=true;VARIABLES.wsCanManage=listFind('OWNER,ADMIN',VARIABLES.wsManagerRow.papel)>0;}}
if(!VARIABLES.wsManagerAllowed){cfheader(statuscode=403,statustext='Forbidden');abort;}
VARIABLES.wsTab=structKeyExists(URL,'tab') && isSimpleValue(URL.tab)?lCase(trim(URL.tab)):'clientes';
if(!listFind('clientes,equipe,convites,historico',VARIABLES.wsTab))VARIABLES.wsTab='clientes';
VARIABLES.wsFilters={search=structKeyExists(URL,'busca') && isSimpleValue(URL.busca)?trim(URL.busca):'',state=structKeyExists(URL,'estado') && isSimpleValue(URL.estado)?trim(URL.estado):'',page=structKeyExists(URL,'pagina') && isSimpleValue(URL.pagina)?URL.pagina:1};
if(len(VARIABLES.wsFilters.search)>160)VARIABLES.wsFilters.search=left(VARIABLES.wsFilters.search,160);
if(!reFind('^[1-9][0-9]{0,5}$',VARIABLES.wsFilters.page & ''))VARIABLES.wsFilters.page=1;
VARIABLES.wsLink=VARIABLES.wsView.tabUrl(VARIABLES.wsManagerId,VARIABLES.wsTab,VARIABLES.wsFilters);
if(structKeyExists(SESSION,'businessWorkspaceIssuedLink')){
    VARIABLES.wsIssuedLink=SESSION.businessWorkspaceIssuedLink;
    structDelete(SESSION,'businessWorkspaceIssuedLink');
}
if(structKeyExists(URL,'ok') && URL.ok=='1')VARIABLES.wsNotice='Alteração registrada.';
if(CGI.request_method=='POST' && structKeyExists(FORM,'business_delegation_action')){
    try{
        if(structKeyExists(CGI,'content_type') && !findNoCase('application/x-www-form-urlencoded',CGI.content_type))throw(type='BusinessDelegation.Validation',message='Unexpected form encoding');
        if(!createObject('component','services.accountDelegation.Policy').uniqueParameters(toString(getHttpRequestData().content)))throw(type='BusinessDelegation.Validation',message='Duplicate form field');
        for(VARIABLES.wsPostedField in FORM)if(!isSimpleValue(FORM[VARIABLES.wsPostedField]))throw(type='BusinessDelegation.Validation',message='Invalid form field');
        if(!isSimpleValue(FORM.business_delegation_action) || !structKeyExists(FORM,'business_workspace_csrf') || !isSimpleValue(FORM.business_workspace_csrf) || compare(FORM.business_workspace_csrf,VARIABLES.wsCsrf)!=0)throw(type='BusinessDelegation.Forbidden',message='Invalid form');
        VARIABLES.wsAction=FORM.business_delegation_action;
        VARIABLES.wsCapabilities=VARIABLES.wsView.capabilities(FORM);
        if(VARIABLES.wsAction=='request_relationship'){
            VARIABLES.wsService.requestRelationship(VARIABLES.wsIdentity,VARIABLES.wsManagerId,FORM.client_reference,VARIABLES.wsCapabilities);
            VARIABLES.wsNotice='Solicitação recebida. Caso a conta seja elegível, o titular poderá avaliá-la.';
        }else if(VARIABLES.wsAction=='create_client'){
            VARIABLES.wsFields={};
            for(VARIABLES.wsField in listToArray('nome_empresa,tipo_titular,documento,nome_responsavel,email_responsavel,telefone_responsavel,site,cidade,estado,tipo_prestador,mensagem'))VARIABLES.wsFields[VARIABLES.wsField]=structKeyExists(FORM,VARIABLES.wsField)?FORM[VARIABLES.wsField]:'';
            VARIABLES.wsService.createClient(VARIABLES.wsIdentity,VARIABLES.wsManagerId,VARIABLES.wsFields,VARIABLES.wsCapabilities);
        }else if(VARIABLES.wsAction=='update_pending_client'){
            VARIABLES.wsFields={};
            for(VARIABLES.wsField in listToArray('nome_empresa,tipo_titular,documento,nome_responsavel,email_responsavel,telefone_responsavel,site,cidade,estado,tipo_prestador,mensagem'))VARIABLES.wsFields[VARIABLES.wsField]=structKeyExists(FORM,VARIABLES.wsField)?FORM[VARIABLES.wsField]:'';
            VARIABLES.wsService.updatePendingClient(VARIABLES.wsIdentity,FORM.relationship_id,FORM.expected_version,VARIABLES.wsFields);
        }else if(VARIABLES.wsAction=='assign_member'){
            if(!structKeyExists(FORM,'assignment_target') || !isSimpleValue(FORM.assignment_target) || !reFind('^[1-9][0-9]*:[1-9][0-9]*$',FORM.assignment_target))throw(type='BusinessDelegation.Validation',message='Invalid assignment target');
            VARIABLES.wsTarget=listToArray(FORM.assignment_target,':');
            VARIABLES.wsService.assignMember(VARIABLES.wsIdentity,VARIABLES.wsTarget[1],FORM.membership_id,VARIABLES.wsTarget[2],VARIABLES.wsCapabilities);
        }else if(VARIABLES.wsAction=='remove_assignment'){
            VARIABLES.wsService.removeAssignment(VARIABLES.wsIdentity,FORM.assignment_id,FORM.expected_version);
        }else if(VARIABLES.wsAction=='invite_owner'){
            VARIABLES.wsIssued=VARIABLES.wsService.inviteOwner(VARIABLES.wsIdentity,FORM.relationship_id,FORM.expected_version,FORM.owner_email);
            SESSION.businessWorkspaceIssuedLink=VARIABLES.wsIssued.url;
        }else if(VARIABLES.wsAction=='decide_relationship'){
            if(!structKeyExists(FORM,'decision') || !isSimpleValue(FORM.decision) || !listFind('APPROVE,DECLINE',FORM.decision))throw(type='BusinessDelegation.Validation',message='Invalid decision');
            VARIABLES.wsService.decideRelationship(VARIABLES.wsIdentity,FORM.relationship_id,FORM.expected_version,FORM.decision,FORM.decision=='APPROVE'?VARIABLES.wsCapabilities:[]);
        }else if(VARIABLES.wsAction=='change_relationship'){
            if(!structKeyExists(FORM,'relationship_action') || !isSimpleValue(FORM.relationship_action) || !listFind('RENOUNCE,CANCEL,EXPAND',FORM.relationship_action))throw(type='BusinessDelegation.Validation',message='Invalid relationship action');
            VARIABLES.wsChanged=VARIABLES.wsService.changeRelationship(VARIABLES.wsIdentity,FORM.relationship_id,FORM.expected_version,FORM.relationship_action,VARIABLES.wsCapabilities);
            if(structKeyExists(VARIABLES.wsChanged,'url'))SESSION.businessWorkspaceIssuedLink=VARIABLES.wsChanged.url;
        }else throw(type='BusinessDelegation.Validation',message='Invalid action');
        if(!len(VARIABLES.wsNotice))VARIABLES.wsNotice='Alteração registrada.';
        SESSION.businessWorkspaceNotice=VARIABLES.wsNotice;
        location(url=VARIABLES.wsLink & '&ok=1',addtoken=false);
    }catch(any wsFailure){
        VARIABLES.wsError=listFindNoCase(wsFailure.type,'BusinessDelegation.Conflict')?'Os dados mudaram. Atualize a página e tente novamente.':
            listFindNoCase(wsFailure.type,'BusinessDelegation.Validation')?'Revise os campos do formulário.':'Não foi possível concluir. Confira seu acesso e tente novamente.';
    }
}
if(structKeyExists(SESSION,'businessWorkspaceNotice')){VARIABLES.wsNotice=SESSION.businessWorkspaceNotice;structDelete(SESSION,'businessWorkspaceNotice');}
VARIABLES.wsClientPage=VARIABLES.wsService.listClients(VARIABLES.wsIdentity,VARIABLES.wsManagerId,VARIABLES.wsTab=='clientes'?VARIABLES.wsFilters:{});
VARIABLES.wsTeamPage=VARIABLES.wsTab=='equipe'?VARIABLES.wsService.listTeam(VARIABLES.wsIdentity,VARIABLES.wsManagerId,VARIABLES.wsFilters):{items=[],page=1,pageSize=25,total=0};
VARIABLES.wsInvitesPage=VARIABLES.wsTab=='convites'?VARIABLES.wsService.listInvites(VARIABLES.wsIdentity,VARIABLES.wsManagerId,VARIABLES.wsFilters):{items=[],page=1,pageSize=25,total=0};
VARIABLES.wsAuditPage=VARIABLES.wsTab=='historico'?VARIABLES.wsService.listAudit(VARIABLES.wsIdentity,VARIABLES.wsManagerId,VARIABLES.wsFilters):{items=[],page=1,pageSize=25,total=0};
VARIABLES.wsPage=VARIABLES.wsTab=='clientes'?VARIABLES.wsClientPage:VARIABLES.wsTab=='equipe'?VARIABLES.wsTeamPage:VARIABLES.wsTab=='convites'?VARIABLES.wsInvitesPage:VARIABLES.wsAuditPage;
</cfscript>
