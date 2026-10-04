<cfprocessingdirective pageencoding="utf-8"/>
<cfscript>
VARIABLES.inviteHttpStatus=200;
VARIABLES.inviteMessage='';
VARIABLES.inviteProjection={};
VARIABLES.inviteReturn=createObject('component','services.accountDelegation.InviteReturn');
VARIABLES.invitePolicy=createObject('component','services.accountDelegation.Policy');
VARIABLES.inviteIdentity=structKeyExists(REQUEST,'businessDelegationIdentity')?REQUEST.businessDelegationIdentity:{};
VARIABLES.inviteService=structKeyExists(REQUEST,'businessDelegationService')?REQUEST.businessDelegationService:createObject('component','services.BusinessAccountDelegation').init('runnerhub',structKeyExists(APPLICATION,'businessAccountDelegationEnabled') && APPLICATION.businessAccountDelegationEnabled);
VARIABLES.inviteSignedIn=!structIsEmpty(VARIABLES.inviteIdentity);

if(uCase(CGI.request_method)=='GET' && structKeyExists(URL,'token')) {
    if(!VARIABLES.inviteReturn.capture(SESSION,URL.token)) {
        VARIABLES.inviteHttpStatus=404;
        VARIABLES.inviteMessage='Este convite não está disponível.';
    } else {
        location(url=VARIABLES.inviteSignedIn?'/convites/':'/?login=1',addtoken=false);
    }
}
if(VARIABLES.inviteHttpStatus==200 && !VARIABLES.inviteSignedIn) location(url='/?login=1',addtoken=false);

if(VARIABLES.inviteHttpStatus==200 && uCase(CGI.request_method)=='POST') {
    VARIABLES.inviteRoute=VARIABLES.invitePolicy.routePolicy(CGI.script_name,CGI.request_method,URL,FORM);
    VARIABLES.invitePending=VARIABLES.inviteReturn.pendingToken(SESSION);
    if(!VARIABLES.inviteRoute.allowed || !len(VARIABLES.invitePending) || !structKeyExists(FORM,'token') || !isSimpleValue(FORM.token)
        || !reFind('^[a-f0-9]{64}$',FORM.token & '')
        || compare(FORM.token & '',VARIABLES.invitePending)!=0 || !structKeyExists(FORM,'invite_csrf') || !isSimpleValue(FORM.invite_csrf)
        || !reFind('^[a-f0-9]{64}$',FORM.invite_csrf & '')
        || !structKeyExists(SESSION,'businessInviteCsrf') || !isSimpleValue(SESSION.businessInviteCsrf)
        || !createObject('java','java.security.MessageDigest').isEqual(charsetDecode(FORM.invite_csrf & '','UTF-8'),charsetDecode(SESSION.businessInviteCsrf & '','UTF-8'))
        || !structKeyExists(FORM,'expectedVersion') || !isSimpleValue(FORM.expectedVersion)) {
        VARIABLES.inviteHttpStatus=403;VARIABLES.inviteMessage='Não foi possível confirmar esta ação.';
    } else {
        try {
            VARIABLES.inviteProposal=VARIABLES.inviteService.inspectInvite(VARIABLES.inviteIdentity,VARIABLES.invitePending);
            VARIABLES.inviteCurrentVersion=VARIABLES.inviteProposal.type=='TITULAR'?VARIABLES.inviteProposal.version:VARIABLES.inviteProposal.relationshipVersion;
            if(compare(FORM.expectedVersion & '',VARIABLES.inviteCurrentVersion & '')!=0) VARIABLES.invitePolicy.fail('Conflict','Invitation changed');
            if(VARIABLES.inviteProposal.type=='TITULAR') {
                if(VARIABLES.inviteRoute.action=='accept') VARIABLES.inviteService.acceptOwner(VARIABLES.inviteIdentity,VARIABLES.invitePending,VARIABLES.inviteCurrentVersion);
                else VARIABLES.inviteService.rejectOwner(VARIABLES.inviteIdentity,VARIABLES.invitePending,VARIABLES.inviteCurrentVersion);
            } else if(listFind('RELACAO,AMPLIACAO',VARIABLES.inviteProposal.type)) {
                VARIABLES.inviteService.decideRelationship(VARIABLES.inviteIdentity,VARIABLES.inviteProposal.relationshipId,VARIABLES.inviteCurrentVersion,VARIABLES.inviteRoute.action=='accept'?'APPROVE':'DECLINE',VARIABLES.inviteRoute.action=='accept'?VARIABLES.inviteProposal.capabilities:[]);
            } else VARIABLES.invitePolicy.fail('Forbidden','Invitation unavailable');
            VARIABLES.inviteReturn.clear(SESSION);
            SESSION.businessInviteFlash=VARIABLES.inviteRoute.action=='accept'?'Convite aceito.':'Convite recusado.';
            location(url='/convites/',addtoken=false);
        } catch(any inviteDecisionError) {
            if(left(inviteDecisionError.type,19)!='BusinessDelegation.') rethrow;
            VARIABLES.inviteHttpStatus=listFind('BusinessDelegation.Forbidden,BusinessDelegation.NotFound',inviteDecisionError.type)?404:(inviteDecisionError.type=='BusinessDelegation.Unavailable'?503:409);
            VARIABLES.inviteMessage=VARIABLES.inviteHttpStatus==404?'Este convite não está disponível.':(VARIABLES.inviteHttpStatus==503?'Convites indisponíveis no momento.':'Este convite venceu, foi usado ou mudou. Solicite um novo link.');
        }
    }
}
if(VARIABLES.inviteHttpStatus==200 && structKeyExists(SESSION,'businessInviteFlash')) {
    VARIABLES.inviteMessage=SESSION.businessInviteFlash;
    structDelete(SESSION,'businessInviteFlash',false);
}
if(VARIABLES.inviteHttpStatus==200 && uCase(CGI.request_method)=='GET') {
    VARIABLES.inviteCurrentToken=VARIABLES.inviteReturn.pendingToken(SESSION);
    if(len(VARIABLES.inviteCurrentToken)) {
        try {
            VARIABLES.inviteProjection=VARIABLES.inviteService.inspectInvite(VARIABLES.inviteIdentity,VARIABLES.inviteCurrentToken);
            if(!structKeyExists(SESSION,'businessInviteCsrf') || !isSimpleValue(SESSION.businessInviteCsrf) || len(SESSION.businessInviteCsrf)<32)
                SESSION.businessInviteCsrf=lCase(hash(generateSecretKey('AES',256),'SHA-256'));
        } catch(any inviteInspectError) {
            if(left(inviteInspectError.type,19)!='BusinessDelegation.') rethrow;
            VARIABLES.inviteHttpStatus=listFind('BusinessDelegation.Forbidden,BusinessDelegation.NotFound',inviteInspectError.type)?404:(inviteInspectError.type=='BusinessDelegation.Unavailable'?503:410);
            if(VARIABLES.inviteHttpStatus==404) VARIABLES.inviteReturn.clear(SESSION);
            VARIABLES.inviteMessage=VARIABLES.inviteHttpStatus==404?'Este convite não está disponível.':(VARIABLES.inviteHttpStatus==503?'Convites indisponíveis no momento.':'Este convite venceu, foi usado ou mudou. Solicite um novo link.');
        }
    } else if(!len(VARIABLES.inviteMessage)) {
        VARIABLES.inviteHttpStatus=404;VARIABLES.inviteMessage='Abra o link do convite para continuar.';
    }
}
</cfscript>
