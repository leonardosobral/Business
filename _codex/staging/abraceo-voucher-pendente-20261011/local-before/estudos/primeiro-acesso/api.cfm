<cfinclude template="../_context.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
try {
    if(CGI.request_method!='POST') {cfheader(statuscode=405);writeOutput('{"ok":false,"message":"Use POST."}');abort;}
    if(!studyActor) {cfheader(statuscode=401);writeOutput('{"ok":false,"message":"Entre com sua conta Google para continuar."}');abort;}
    if(!structKeyExists(FORM,'csrf') || !isSimpleValue(FORM.csrf) || compare(FORM.csrf,SESSION.businessStudyCsrf)!=0) {
        cfheader(statuscode=403);writeOutput('{"ok":false,"message":"A sessão expirou. Recarregue a página."}');abort;
    }
    lock scope='session' type='exclusive' timeout=5 {
        if(!structKeyExists(SESSION,'businessFirstAccessRate') || dateDiff('s',SESSION.businessFirstAccessRate.start,now())>=60)
            SESSION.businessFirstAccessRate={start=now(),count=0};
        SESSION.businessFirstAccessRate.count++;
        rateExceeded=SESSION.businessFirstAccessRate.count>40;
    }
    if(rateExceeded) {cfheader(statuscode=429);writeOutput('{"ok":false,"message":"Aguarde um minuto antes de tentar novamente."}');abort;}
    service=new estudos.includes.FirstAccess().init('runner_dba');
    param name='FORM.operation' default='overview';
    param name='FORM.mode' default=''; param name='FORM.value' default='';
    param name='FORM.role' default=''; param name='FORM.declared' default='false'; param name='FORM.corrections' default='';
    param name='FORM.cnpj' default=''; param name='FORM.email' default=''; param name='FORM.expiresOn' default='';
    switch(FORM.operation) {
        case 'overview': result=service.overview(studyActor);break;
        case 'lookup': result=service.lookup(studyActor,FORM.mode,FORM.value);break;
        case 'confirm': result=service.confirm(studyActor,FORM.mode,FORM.value,FORM.role,FORM.declared=='true',FORM.corrections);break;
        case 'issue': result=service.adminIssue(studyActor,FORM.cnpj,FORM.email,FORM.expiresOn);break;
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
    cfheader(statuscode=status);writeOutput(serializeJSON({'ok':false,'message':message}));
}
</cfscript>
