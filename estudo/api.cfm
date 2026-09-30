<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting requesttimeout="65" showdebugoutput="false"/>
<cfset VARIABLES.template="/estudo/"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/require_admin.cfm"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
try {
    if(CGI.request_method!="POST" || !structKeyExists(SESSION,"estudoCsrf") || !structKeyExists(FORM,"csrf") || compare(FORM.csrf,SESSION.estudoCsrf)!=0)
        throw(type="Study.Access",message="Sessão expirada. Recarregue a página.");
    if(!isDefined("REQUEST.businessIdentity.id") || !isValid("integer",REQUEST.businessIdentity.id))throw(type="Study.Access",message="Identificação administrativa indisponível.");
    actor=REQUEST.businessIdentity.id;
    service=new estudo.includes.StudyNotebook().init();
    action=FORM.action ?: "";
    data={};
    switch(action){
        case "webCatalog": data=new estudo.includes.StudyPublication().catalog();break;
        case "webPreview": data=new estudo.includes.StudyPublication().preview(FORM.year,FORM.runId);break;
        case "webPublish": data=new estudo.includes.StudyPublication().publish(FORM.year,FORM.runId,FORM.expected,FORM.note,actor);break;
        case "list": data=service.listBooks();break;
        case "sections": data=service.sections(FORM.bookId);break;
        case "notebook": data=service.getNotebook(FORM.id);break;
        case "saveBook": data=service.saveBook(FORM.id,FORM.version,FORM.title,actor);break;
        case "archived": data=service.archivedCells(FORM.notebookId);break;
        case "createBook": data=service.createBook(FORM.title,FORM.year,actor);break;
        case "createNotebook": data=service.createNotebook(FORM.bookId,FORM.title,actor);break;
        case "saveNotebook": data=service.saveNotebook(FORM.id,FORM.version,FORM.title,actor);break;
        case "createCell": data=service.createCell(FORM.notebookId,FORM.type,FORM.lang,FORM.content ?: "",actor);break;
        case "saveCell": data=service.saveCell(FORM.id,FORM.version,FORM.type,FORM.lang,FORM.content ?: "",actor);break;
        case "archiveCell": data=service.archiveCell(FORM.id,FORM.version,FORM.archived,actor);break;
        case "reorderCells": data=service.reorderCells(FORM.notebookId,deserializeJSON(FORM.ids),actor);break;
        case "revisions": data=service.revisions(FORM.cellId);break;
        case "runs": data=service.runs(FORM.notebookId);break;
        case "run": data=service.execute(FORM.cellId,FORM.version,FORM.sql,actor);break;
        case "getRun": data=service.getRun(FORM.id);break;
        case "freeze": data=service.freeze(FORM.id,FORM.title,FORM.note ?: "",actor);break;
        case "export":
            data=service.getRun(FORM.id);
            if(data.status!="ok")throw(type="Study.Validation",message="Esta execução não tem resultado para exportar.");
            cfheader(name="Content-Disposition",value='attachment; filename="estudo-execucao-'&data.id&'.json"');
            // Keep PostgreSQL JSON intact, including null and integers beyond JavaScript precision.
            raw=data.result_json;structDelete(data,"result_json");
            writeOutput('{"execution":'&serializeJSON(data)&',"result":'&raw&'}');abort;
        default: throw(type="Study.Validation",message="Ação inválida.");
    }
    writeOutput(serializeJSON({ok=true,data=data}));
} catch(any e){
    status=500;message="Não foi possível concluir. Recarregue e tente novamente.";code="internal";
    if(findNoCase("Study.",e.type)==1){
        message=e.message;code=listLast(e.type,".");status=400;
        if(code=="Conflict")status=409;
        if(code=="Access")status=403;
        if(code=="Missing")status=404;
    }else{writeLog(file="estudo",type="error",text="Estudo action="&action&": "&left(e.message,1500));}
    cfheader(statuscode=status);
    writeOutput(serializeJSON({ok=false,error=message,code=code}));
}
</cfscript>