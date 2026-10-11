<cfinclude template="_context.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
try {
    if(CGI.request_method!='POST') {cfheader(statuscode=405);writeOutput('{"ok":false,"message":"Use POST."}');abort;}
    if(!studyActor) {cfheader(statuscode=401);writeOutput('{"ok":false,"message":"Entre com sua conta para continuar."}');abort;}
    if(!structKeyExists(FORM,'csrf') || !isSimpleValue(FORM.csrf) || compare(FORM.csrf,SESSION.businessStudyCsrf)!=0) {cfheader(statuscode=403);writeOutput('{"ok":false,"message":"Recarregue a página para continuar."}');abort;}
    param name='FORM.action' default='dashboard';
    switch(FORM.action) {
        case 'dashboard': result=studyService.dashboard(studyActor); break;
        case 'redeem': result=studyService.redeem(studyActor,FORM.code); break;
        case 'requestAccess': result=studyService.requestAccess(studyActor,FORM.company,FORM.role,FORM.message,FORM.kind); break;
        case 'interest': result=studyService.interest(studyActor,FORM.kind,FORM.enabled=='true'); break;
        case 'adminOverview': result=studyService.adminOverview(studyActor); break;
        case 'adminCampaign': result=studyService.adminCampaign(studyActor,FORM.campaignId,FORM.status,FORM.expectedVersion,FORM.note); break;
        case 'adminCreateVoucher': result=studyService.adminCreateVoucher(studyActor,FORM.campaignId,FORM.email,FORM.expiresOn,FORM.note,FORM.requestId); break;
        case 'adminDeclineRequest': result=studyService.adminDeclineRequest(studyActor,FORM.requestId,FORM.note); break;
        case 'adminRevokeVoucher': result=studyService.adminRevokeVoucher(studyActor,FORM.voucherId,FORM.note); break;
        case 'adminRevokeAccess': result=studyService.adminRevokeAccess(studyActor,FORM.accessId,FORM.note); break;
        default: throw(type='StudyAccess.Validation',message='Ação inválida.');
    }
    writeOutput(serializeJSON({'ok':true,'data':result}));
} catch(any err) {
    status=500;message='Não foi possível concluir. Tente novamente.';
    kind=listLast(err.type,'.');
    if(kind=='Validation') status=400;
    else if(kind=='Conflict') status=409;
    else if(kind=='Access' || kind=='Forbidden') status=403;
    else if(kind=='Missing') status=404;
    if(status!=500) message=err.message;
    cfheader(statuscode=status);
    writeOutput(serializeJSON({'ok':false,'message':message}));
}
</cfscript>
