<cfscript>
VARIABLES.businessDelegationAdminReady=structKeyExists(APPLICATION,'businessAccountDelegationEnabled') && APPLICATION.businessAccountDelegationEnabled
    && structKeyExists(REQUEST,'businessDelegationIdentity') && isStruct(REQUEST.businessDelegationIdentity);
VARIABLES.businessDelegationTabError='';
VARIABLES.businessDelegationClientManagers=[];
VARIABLES.businessDelegationInternalManagers=queryNew('relationshipId,version,status,managerName,managerId');
VARIABLES.businessDelegationAgencyQueue=queryNew('id_solicitacao,nome_empresa,id_conta,id_vinculo,version,capacidades_propostas,gestora_nome');
VARIABLES.businessDelegationManagerConfig={};
VARIABLES.businessDelegationCanSeeClientManagers=false;
if(VARIABLES.businessDelegationAdminReady){
    VARIABLES.businessDelegationTabIdentity=duplicate(REQUEST.businessDelegationIdentity);
    VARIABLES.businessDelegationTabIdentity.accessMode='DIRECT';
    if(structKeyExists(REQUEST,'businessAccessContext')){
        if(!isStruct(REQUEST.businessAccessContext) || !structKeyExists(REQUEST.businessAccessContext,'actorId') || REQUEST.businessAccessContext.actorId!=VARIABLES.businessDelegationTabIdentity.id)VARIABLES.businessDelegationTabIdentity.accessMode='INVALID';
        else VARIABLES.businessDelegationTabIdentity.accessMode=REQUEST.businessAccessContext.accessMode;
    }
    if(VARIABLES.businessAccountsSimulationActive)VARIABLES.businessDelegationTabIdentity.accessMode='INTERNAL_SIMULATION';
    VARIABLES.businessDelegationTabService=createObject('component','services.BusinessAccountDelegation').init('runnerhub',true);
    if(CGI.request_method=='POST' && structKeyExists(FORM,'account_delegation_action')){
        try{
            if(!isSimpleValue(FORM.account_delegation_action) || !structKeyExists(FORM,'business_account_access_csrf') || !isSimpleValue(FORM.business_account_access_csrf)
                || !structKeyExists(VARIABLES,'businessAccountContextCsrf') || compare(FORM.business_account_access_csrf,VARIABLES.businessAccountContextCsrf)!=0)throw(type='BusinessDelegation.Forbidden',message='Invalid form');
            VARIABLES.businessDelegationPostedAction=FORM.account_delegation_action;
            if(VARIABLES.businessDelegationPostedAction=='configure_manager'){
                if(!structKeyExists(FORM,'enabled') || !isSimpleValue(FORM.enabled) || !listFind('0,1',FORM.enabled))throw(type='BusinessDelegation.Validation',message='Invalid setting');
                VARIABLES.businessDelegationTabService.configureManager(VARIABLES.businessDelegationTabIdentity,FORM.account_id,FORM.enabled=='1',FORM.classification,FORM.expected_version);
            }else if(listFind('suspend_relationship,reactivate_relationship',VARIABLES.businessDelegationPostedAction)){
                VARIABLES.businessDelegationTabService.changeRelationship(VARIABLES.businessDelegationTabIdentity,FORM.relationship_id,FORM.expected_version,VARIABLES.businessDelegationPostedAction=='suspend_relationship'?'SUSPEND':'REACTIVATE',[]);
            }else if(VARIABLES.businessDelegationPostedAction=='revoke_relationship'){
                if(VARIABLES.businessDelegationTabIdentity.accessMode!='DIRECT')throw(type='BusinessDelegation.Forbidden',message='Direct owner required');
                VARIABLES.businessDelegationTabService.changeRelationship(VARIABLES.businessDelegationTabIdentity,FORM.relationship_id,FORM.expected_version,'REVOKE',[]);
            }else throw(type='BusinessDelegation.Validation',message='Invalid action');
            location(url='./?conta_id=' & urlEncodedFormat(FORM.account_id) & '&tab=gestoras&busca=' & urlEncodedFormat(URL.busca) & '&pagina=' & VARIABLES.accountsPage & '&sucesso=gestoras##conta-gerenciamento',addtoken=false);
        }catch(any delegationTabFailure){
            VARIABLES.businessDelegationTabError=findNoCase('Conflict',delegationTabFailure.type)?'Os dados mudaram. Atualize a página.':
                findNoCase('Validation',delegationTabFailure.type)?'Confira os campos do formulário.':'Ação não autorizada. Confira seu acesso.';
        }
    }
    if(qBusinessAccountEdit.recordCount){
        VARIABLES.businessDelegationSelectedAccountId=qBusinessAccountEdit.id_conta[1];
        VARIABLES.businessDelegationCurrentMembership=queryExecute("SELECT papel,status FROM tb_conta_usuarios WHERE id_usuario=:actor AND id_conta=:account",{actor={value=VARIABLES.businessDelegationTabIdentity.id,cfsqltype='cf_sql_integer'},account={value=VARIABLES.businessDelegationSelectedAccountId,cfsqltype='cf_sql_bigint'}},{datasource='runnerhub'});
        VARIABLES.businessDelegationCanSeeClientManagers=VARIABLES.businessDelegationTabIdentity.accessMode=='DIRECT' && VARIABLES.businessDelegationCurrentMembership.recordCount
            && VARIABLES.businessDelegationCurrentMembership.papel[1]=='OWNER' && VARIABLES.businessDelegationCurrentMembership.status[1]=='ATIVO';
        if(VARIABLES.businessDelegationCanSeeClientManagers)VARIABLES.businessDelegationClientManagers=VARIABLES.businessDelegationTabService.listClientManagers(VARIABLES.businessDelegationTabIdentity,VARIABLES.businessDelegationSelectedAccountId);
        if(VARIABLES.businessAccountsCanAdminAll && VARIABLES.businessDelegationTabIdentity.accessMode=='DIRECT'){
            VARIABLES.businessDelegationManagerConfig=queryExecute('SELECT id_conta,classificacao,habilitada,version FROM tb_conta_gestoras WHERE id_conta=:id',{id={value=VARIABLES.businessDelegationSelectedAccountId,cfsqltype='cf_sql_bigint'}},{datasource='runnerhub'});
            VARIABLES.businessDelegationInternalManagers=queryExecute("SELECT v.id_vinculo AS relationshipId,v.version,v.status,m.nome_conta AS managerName,m.id_conta AS managerId FROM tb_conta_gestao_vinculos v JOIN tb_contas m ON m.id_conta=v.id_conta_gestora WHERE v.id_conta_cliente=:id AND v.status IN('ATIVO','SUSPENSO') ORDER BY m.nome_conta,m.id_conta",{id={value=VARIABLES.businessDelegationSelectedAccountId,cfsqltype='cf_sql_bigint'}},{datasource='runnerhub'});
        }
    }
    if(VARIABLES.businessAccountsCanAdminAll && VARIABLES.businessDelegationTabIdentity.accessMode=='DIRECT'){
        VARIABLES.businessDelegationAgencyQueue=queryExecute("SELECT sol.id_solicitacao,sol.nome_empresa,sol.id_conta,v.id_vinculo,v.version,CAST(v.capacidades_propostas AS text) AS capacidades_propostas,m.nome_conta AS gestora_nome FROM tb_conta_cadastro_solicitacoes sol JOIN tb_conta_gestao_vinculos v ON v.id_vinculo=sol.gestao_vinculo_id AND v.id_conta_gestora=sol.origem_gestora_id JOIN tb_contas m ON m.id_conta=sol.origem_gestora_id WHERE sol.origem_gestora_id IS NOT NULL AND sol.status='PENDENTE' AND v.status='AGUARDANDO_CONTA' ORDER BY sol.data_criacao,sol.id_solicitacao LIMIT 25",{}, {datasource='runnerhub'});
    }
}
</cfscript>
