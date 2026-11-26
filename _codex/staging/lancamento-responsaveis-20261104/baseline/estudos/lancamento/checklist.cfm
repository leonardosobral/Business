<cfinclude template="../_context.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
try {
    if(CGI.request_method!='POST') {cfheader(statuscode=405);cfheader(name='Allow',value='POST');writeOutput('{"ok":false,"message":"Use POST."}');abort;}
    if(!studyActor) {cfheader(statuscode=401);writeOutput('{"ok":false,"message":"Entre com sua conta de administrador."}');abort;}
    if(structCount(URL)>0 || (structKeyExists(CGI,'path_info') && len(CGI.path_info))) {cfheader(statuscode=400);writeOutput('{"ok":false,"message":"Requisição inválida."}');abort;}
    if(!structKeyExists(FORM,'csrf') || !isSimpleValue(FORM.csrf) || compare(FORM.csrf,SESSION.businessStudyCsrf)!=0) {cfheader(statuscode=403);writeOutput('{"ok":false,"message":"Recarregue a página para continuar."}');abort;}
    for(field in ['step','completed','expectedVersion']) if(!structKeyExists(FORM,field) || !isSimpleValue(FORM[field])) throw(type='StudyAccess.Validation',message='Informe a etapa e o estado esperado.');
    if(!listFind('true,false',FORM.completed)) throw(type='StudyAccess.Validation',message='Estado inválido.');
    result=studyService.adminValidateLaunchStep(studyActor,toString(FORM.step),FORM.completed=='true',toString(FORM.expectedVersion));
    writeOutput(serializeJSON({'ok':true,'data':result}));
} catch(any err) {
    status=500;message='Não foi possível salvar. Tente novamente.';kind=listLast(err.type,'.');
    if(kind=='Validation') status=400;
    else if(kind=='Conflict') status=409;
    else if(kind=='Access' || kind=='Forbidden') status=403;
    else if(kind=='Missing') status=404;
    if(status!=500) message=err.message;
    response={'ok':false,'message':message};
    if(status==409) response['data']=studyService.adminLaunchChecklist(studyActor);
    cfheader(statuscode=status);writeOutput(serializeJSON(response));
}
</cfscript>
