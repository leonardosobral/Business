<cfscript>
// Internal adapter, included after the existing registration form validation.
// Provenance is read before choosing the legacy branch, even when delegation is disabled.
VARIABLES.accountRegistrationDelegationHandled=false;
try {
    if(!structKeyExists(VARIABLES,'accountRegistrationRequestId') || !isSimpleValue(VARIABLES.accountRegistrationRequestId) || !reFind('^[1-9][0-9]*$',VARIABLES.accountRegistrationRequestId & ''))throw(type='BusinessDelegation.Validation',message='Solicitação inválida.');
    VARIABLES.delegationRegistration=queryExecute('SELECT * FROM tb_conta_cadastro_solicitacoes WHERE id_solicitacao=:id', {id={value=VARIABLES.accountRegistrationRequestId,cfsqltype='cf_sql_bigint'}},{datasource='runnerhub'});
    VARIABLES.accountRegistrationDelegationHandled=VARIABLES.delegationRegistration.recordCount>0
        && listFindNoCase(VARIABLES.delegationRegistration.columnList,'origem_gestora_id')>0
        && len(VARIABLES.delegationRegistration.origem_gestora_id[1] & '')>0;
    if(VARIABLES.accountRegistrationDelegationHandled){
        if(CGI.request_method!='POST' || !structKeyExists(FORM,'business_account_access_csrf') || !isSimpleValue(FORM.business_account_access_csrf)
            || !structKeyExists(VARIABLES,'businessAccountContextCsrf') || !len(VARIABLES.businessAccountContextCsrf)
            || compare(FORM.business_account_access_csrf,VARIABLES.businessAccountContextCsrf)!=0)throw(type='BusinessDelegation.Forbidden',message='A sessão do formulário expirou.');
        if(!structKeyExists(VARIABLES,'businessAccountsCanAdminAll') || !VARIABLES.businessAccountsCanAdminAll
            || !structKeyExists(VARIABLES,'businessAccountsSimulationActive') || VARIABLES.businessAccountsSimulationActive
            || !structKeyExists(REQUEST,'businessDelegationIdentity') || !isStruct(REQUEST.businessDelegationIdentity))throw(type='BusinessDelegation.Forbidden',message='Revisão interna fora de simulação obrigatória.');
        VARIABLES.delegationReviewIdentity=duplicate(REQUEST.businessDelegationIdentity);
        VARIABLES.delegationReviewIdentity.accessMode='DIRECT';
        if(structKeyExists(REQUEST,'businessAccessContext')){
            if(!isStruct(REQUEST.businessAccessContext) || !structKeyExists(REQUEST.businessAccessContext,'accessMode')
                || !structKeyExists(REQUEST.businessAccessContext,'actorId') || REQUEST.businessAccessContext.actorId!=VARIABLES.delegationReviewIdentity.id)throw(type='BusinessDelegation.Forbidden',message='Contexto inválido.');
            VARIABLES.delegationReviewIdentity.accessMode=REQUEST.businessAccessContext.accessMode;
        }
        if(!structKeyExists(FORM,'expectedVersion') || !isSimpleValue(FORM.expectedVersion) || !reFind('^[1-9][0-9]*$',FORM.expectedVersion & '')
            || !structKeyExists(FORM,'capabilities') || !isSimpleValue(FORM.capabilities))throw(type='BusinessDelegation.Validation',message='Revisão inválida.');
        if(!listFind('aprovar,recusar',VARIABLES.accountRegistrationAction))throw(type='BusinessDelegation.Validation',message='Ação inválida.');
        VARIABLES.delegationReviewService=createObject('component','services.BusinessAccountDelegation').init('runnerhub',structKeyExists(APPLICATION,'businessAccountDelegationEnabled') && APPLICATION.businessAccountDelegationEnabled);
        VARIABLES.delegationReviewResult=VARIABLES.delegationReviewService.reviewCreatedClient(VARIABLES.delegationReviewIdentity,VARIABLES.accountRegistrationRequestId,FORM.expectedVersion,
            VARIABLES.accountRegistrationAction=='aprovar'?'APPROVE':'DECLINE',listToArray(FORM.capabilities));
        VARIABLES.accountRegistrationRedirectUrl='./?tab=gestoras&sucesso=' & (VARIABLES.accountRegistrationAction=='aprovar'?'solicitacao_aprovada':'solicitacao_recusada');
    }
}catch(any error){
    // Failure to classify a request must never fall through to the owner/voucher legacy path.
    VARIABLES.accountRegistrationDelegationHandled=true;
    if(!structKeyExists(VARIABLES,'accountRegistrationErrors'))VARIABLES.accountRegistrationErrors=[];
    arrayAppend(VARIABLES.accountRegistrationErrors,'Não foi possível revisar o cadastro da gestora. Atualize a página e confira sua autorização.');
}
</cfscript>
