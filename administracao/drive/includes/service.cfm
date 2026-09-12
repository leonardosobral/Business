<cfscript>
function driveFail(required string message) { throw(type="Drive.Validation", message=arguments.message); }
function driveParam(required any value) { return {value=arguments.value,cfsqltype="cf_sql_varchar"}; }
function driveDb(required string sql, struct params={}) { return queryExecute(arguments.sql,arguments.params,{datasource="runner_dba"}); }
function driveReady() {
    var q=driveDb("SELECT to_regclass('public.tb_google_drive_config') IS NOT NULL AND to_regclass('public.tb_google_drive_auditoria') IS NOT NULL AS ready");
    return q.ready;
}
function driveConfig() {
    if (!structKeyExists(application,"googleDrive")) driveFail("Reinicie a aplicação para carregar a configuração de Documentos.");
    var c=application.googleDrive;
    if (!structKeyExists(c,"rootName") || !len(trim(c.rootName & ""))) driveFail("Configure o nome da pasta raiz de Documentos.");
    if (!structKeyExists(c,"maxUploadBytes") || val(c.maxUploadBytes)<1048576) driveFail("Configure o limite de upload de Documentos.");
    return c;
}
function drivePickerConfigured() {
    var c=driveConfig();
    return structKeyExists(c,"pickerConfigured") && c.pickerConfigured && structKeyExists(c,"pickerApiKey") && len(trim(c.pickerApiKey & "")) && structKeyExists(c,"appId") && reFind("^[0-9]{6,32}$",c.appId & "");
}
function driveMutation() {
    if (CGI.request_method!="POST" || !structKeyExists(form,"csrf_token") || !structKeyExists(session,"driveCsrf") || compare(form.csrf_token,session.driveCsrf)!=0) driveFail("Sessão de segurança expirada. Recarregue a página.");
}
function driveInput(required string key,string fallback="") {
    return structKeyExists(form,arguments.key) && isSimpleValue(form[arguments.key]) ? trim(form[arguments.key] & "") : arguments.fallback;
}
function driveId(required string value) {
    var id=trim(arguments.value);
    if (!reFind("^[A-Za-z0-9_-]{1,255}$",id)) driveFail("Identificador de arquivo inválido.");
    return id;
}
function driveName(required string value) {
    var name=trim(arguments.value);
    if (!len(name) || len(name)>255) driveFail("Informe um nome de até 255 caracteres.");
    return name;
}
function driveQueryEscape(required string value) {
    return replace(replace(arguments.value,"\","\\","all"),"'","\'","all");
}
function driveRemoteMessage(required struct data,string fallback="O Google Drive recusou a operação.") {
    var message=arguments.fallback;
    var detail={};
    if (structKeyExists(arguments.data,"error") && isStruct(arguments.data.error)) {
        if (structKeyExists(arguments.data.error,"message") && isSimpleValue(arguments.data.error.message)) message=arguments.data.error.message & "";
        if (structKeyExists(arguments.data.error,"errors") && isArray(arguments.data.error.errors) && arrayLen(arguments.data.error.errors) && isStruct(arguments.data.error.errors[1])) detail=arguments.data.error.errors[1];
    }
    message=reReplace(message,"[\r\n\t]+"," ","all");
    if (structKeyExists(detail,"location") && isSimpleValue(detail.location) && reFind("^[A-Za-z][A-Za-z0-9_.-]{0,63}$",detail.location & "")) message &= " (parâmetro " & detail.location & ")";
    return left(message,300);
}
// Drive search expressions contain quotes. Let cfhttpparam encode URL values once instead of
// interpolating an already encoded expression into the URL attribute (which differs across CF engines).
function driveHttp(required string endpoint,string method="GET",struct params={},struct body={},string token="") {
    var response={};
    cfhttp(url=arguments.endpoint,method=arguments.method,result="response",timeout=30,redirect=false,throwonerror=false) {
        cfhttpparam(type="header",name="Accept",value="application/json");
        if (len(arguments.token)) cfhttpparam(type="header",name="Authorization",value="Bearer " & arguments.token);
        for (var key in arguments.params) cfhttpparam(type="url",name=key,value=arguments.params[key] & "");
        if (listFind("POST,PATCH",uCase(arguments.method))) {
            cfhttpparam(type="header",name="Content-Type",value="application/json; charset=utf-8");
            cfhttpparam(type="body",value=serializeJSON(arguments.body));
        }
    }
    var raw=structKeyExists(response,"fileContent") ? response.fileContent & "" : "";
    return {"status"=val(response.statusCode),"data"=isJSON(raw) ? deserializeJSON(raw) : {}};
}
function driveGoogle(required string path,string method="GET",struct params={},struct body={},boolean allowMissing=false) {
    if (!reFind("^/files(?:/[A-Za-z0-9_-]{1,255})?$",arguments.path)) driveFail("Caminho da API do Drive inválido.");
    if (!listFind("GET,POST,PATCH",uCase(arguments.method))) driveFail("Método da API do Drive inválido.");
    var r=driveHttp("https://www.googleapis.com/drive/v3" & arguments.path,arguments.method,arguments.params,arguments.body,agendaAccessToken());
    if (r.status==401) r=driveHttp("https://www.googleapis.com/drive/v3" & arguments.path,arguments.method,arguments.params,arguments.body,agendaAccessToken(true));
    if (r.status==404 && arguments.allowMissing) return {"missing"=true};
    if (r.status==401) driveFail("A conexão Google expirou. Reconecte a conta em Agenda Google.");
    if (r.status==403) driveFail("O Google Drive negou esta operação. Reconecte a conta e confirme a permissão de Documentos.");
    if (r.status==404) driveFail("O arquivo não foi encontrado. Atualize a pasta.");
    if (r.status==429 || r.status>=500 || r.status==0) driveFail("O Google Drive está indisponível ou limitou as consultas. Aguarde e tente novamente.");
    if (r.status<200 || r.status>=300) driveFail(driveRemoteMessage(r.data));
    return r.data;
}
function driveRoot() {
    var result={"configured"=false,"id"="","name"=""};
    if (!driveReady()) return result;
    var q=driveDb("SELECT root_folder_id,root_folder_name FROM public.tb_google_drive_config WHERE id=1");
    if (q.recordCount) result={"configured"=true,"id"=q.root_folder_id[1] & "","name"=q.root_folder_name[1] & ""};
    return result;
}
function driveFile(required string id,string fields="id,name,mimeType,parents,trashed,webViewLink,modifiedTime,size,capabilities/canEdit,capabilities/canRename,capabilities/canTrash,capabilities/canDownload",boolean allowMissing=false) {
    return driveGoogle("/files/" & driveId(arguments.id),"GET",{"fields"=arguments.fields,"supportsAllDrives"="true"},{},arguments.allowMissing);
}
function driveAssertInside(required string id,boolean requireFolder=false) {
    var root=driveRoot();
    if (!root.configured) driveFail("Crie a pasta raiz de Documentos primeiro.");
    var target=driveFile(arguments.id);
    if (structKeyExists(target,"trashed") && target.trashed) driveFail("O arquivo está na lixeira.");
    if (arguments.requireFolder && (!structKeyExists(target,"mimeType") || target.mimeType!="application/vnd.google-apps.folder")) driveFail("Selecione uma pasta válida.");
    var current=target;
    var visited={};
    for (var depth=1; depth<=50; depth++) {
        if (current.id==root.id) return target;
        if (structKeyExists(visited,current.id)) driveFail("A hierarquia da pasta é inválida.");
        visited[current.id]=true;
        if (!structKeyExists(current,"parents") || !isArray(current.parents) || !arrayLen(current.parents)) break;
        current=driveFile(current.parents[1],"id,name,mimeType,parents,trashed");
        if (structKeyExists(current,"trashed") && current.trashed) driveFail("A pasta está na lixeira.");
    }
    driveFail("O arquivo não pertence à pasta de Documentos do Business.");
}
function driveTrail(required string folderId) {
    var root=driveRoot();
    var current=driveAssertInside(arguments.folderId,true);
    var reversed=[];
    for (var depth=1; depth<=50; depth++) {
        arrayAppend(reversed,{"id"=current.id,"name"=current.name});
        if (current.id==root.id) break;
        if (!structKeyExists(current,"parents") || !arrayLen(current.parents)) driveFail("A pasta não pertence a Documentos.");
        current=driveFile(current.parents[1],"id,name,mimeType,parents,trashed");
    }
    var result=[];
    for (var index=arrayLen(reversed); index>=1; index--) arrayAppend(result,reversed[index]);
    return result;
}
function driveListWithoutQuery(required string folderId,string search="") {
    var items=[];
    var page="";
    var pages=0;
    do {
        pages++;
        var params={
            "spaces"="drive",
            "pageSize"=1000,
            "fields"="nextPageToken,files(id,name,mimeType,modifiedTime,size,trashed,webViewLink,iconLink,thumbnailLink,parents,capabilities/canEdit,capabilities/canRename,capabilities/canTrash,capabilities/canDownload)",
            "supportsAllDrives"="true",
            "includeItemsFromAllDrives"="true"
        };
        if (len(page)) params["pageToken"]=page;
        var response=driveGoogle("/files","GET",params);
        if (structKeyExists(response,"files") && isArray(response.files)) for (var item in response.files) {
            if (structKeyExists(item,"trashed") && item.trashed) continue;
            if (!structKeyExists(item,"parents") || !isArray(item.parents) || !arrayFind(item.parents,arguments.folderId)) continue;
            if (len(arguments.search) && (!structKeyExists(item,"name") || !findNoCase(arguments.search,item.name & ""))) continue;
            arrayAppend(items,item);
            if (arrayLen(items)>=1000) driveFail("Esta pasta tem muitos itens. Use a busca para reduzir a lista.");
        }
        page=structKeyExists(response,"nextPageToken") ? response.nextPageToken : "";
    } while(len(page) && pages<10);
    if (len(page)) driveFail("Há muitos arquivos autorizados no Drive. Refine a organização da pasta.");
    return items;
}
function driveList(required string folderId,string search="",string pageToken="") {
    var folder=driveAssertInside(arguments.folderId,true);
    var term=trim(arguments.search);
    if (len(term)>100) driveFail("Busque por até 100 caracteres.");
    if (len(arguments.pageToken)>2048) driveFail("Paginação inválida.");
    var query="'" & driveQueryEscape(folder.id) & "' in parents and trashed = false";
    if (len(term)) query &= " and name contains '" & driveQueryEscape(term) & "'";
    var params={
        "q"=query,
        "spaces"="drive",
        "pageSize"=100,
        "orderBy"="folder,name_natural",
        "fields"="nextPageToken,files(id,name,mimeType,modifiedTime,size,webViewLink,iconLink,thumbnailLink,parents,capabilities/canEdit,capabilities/canRename,capabilities/canTrash,capabilities/canDownload)",
        "supportsAllDrives"="true",
        "includeItemsFromAllDrives"="true"
    };
    if (len(arguments.pageToken)) params["pageToken"]=arguments.pageToken;
    var response={};
    try {
        response=driveGoogle("/files","GET",params);
    } catch(any queryError) {
        if (!findNoCase("parâmetro q",queryError.message & "")) rethrow;
        return {"folder"={"id"=folder.id,"name"=folder.name},"trail"=driveTrail(folder.id),"items"=driveListWithoutQuery(folder.id,term),"nextPageToken"=""};
    }
    return {"folder"={"id"=folder.id,"name"=folder.name},"trail"=driveTrail(folder.id),"items"=structKeyExists(response,"files") && isArray(response.files) ? response.files : [],"nextPageToken"=structKeyExists(response,"nextPageToken") ? response.nextPageToken : ""};
}
function driveMimeFor(required string type) {
    var values={"folder"="application/vnd.google-apps.folder","document"="application/vnd.google-apps.document","spreadsheet"="application/vnd.google-apps.spreadsheet"};
    if (!structKeyExists(values,arguments.type)) driveFail("Tipo de documento inválido.");
    return values[arguments.type];
}
function driveAudit(required string action,string fileId="",string name="") {
    var q=driveDb("INSERT INTO public.tb_google_drive_auditoria(id_usuario,acao,file_id,nome) VALUES(:actor,:action,:file,:name) RETURNING id",{
        actor={value=val(qPerfil.id),cfsqltype="cf_sql_integer"},action=driveParam(arguments.action),file=driveParam(arguments.fileId),name=driveParam(left(arguments.name,255))
    });
    return q.id;
}
function driveAuditEnd(required numeric id,required string state) {
    driveDb("UPDATE public.tb_google_drive_auditoria SET estado=:state WHERE id=:id",{state=driveParam(arguments.state),id={value=arguments.id,cfsqltype="cf_sql_bigint"}});
}
function driveCreateFile(required string name,required string mimeType,required string parentId) {
    var parent=driveAssertInside(arguments.parentId,true);
    return driveGoogle("/files","POST",{"fields"="id,name,mimeType,modifiedTime,size,webViewLink,parents,capabilities/canEdit,capabilities/canRename,capabilities/canTrash,capabilities/canDownload","supportsAllDrives"="true"},{"name"=driveName(arguments.name),"mimeType"=arguments.mimeType,"parents"=[parent.id]});
}
function driveUploadContent(required string id,required string path,required string mimeType) {
    driveId(arguments.id);
    if (!fileExists(arguments.path)) driveFail("O arquivo temporário não foi encontrado.");
    var address="https://www.googleapis.com/upload/drive/v3/files/" & arguments.id & "?uploadType=media&supportsAllDrives=true&fields=id,name,mimeType,modifiedTime,size,webViewLink,parents,capabilities/canEdit,capabilities/canRename,capabilities/canTrash,capabilities/canDownload";
    var response={};
    var token=agendaAccessToken();
    for (var attempt=1; attempt<=2; attempt++) {
        cfhttp(url=address,method="PATCH",result="response",timeout=90,redirect=false,throwonerror=false) {
            cfhttpparam(type="header",name="Authorization",value="Bearer " & token);
            cfhttpparam(type="header",name="Accept",value="application/json");
            cfhttpparam(type="header",name="Content-Type",value=len(arguments.mimeType) ? arguments.mimeType : "application/octet-stream");
            cfhttpparam(type="body",value=fileReadBinary(arguments.path));
        }
        if (val(response.statusCode)!=401 || attempt==2) break;
        token=agendaAccessToken(true);
    }
    var raw=structKeyExists(response,"fileContent") ? response.fileContent & "" : "";
    var data=isJSON(raw) ? deserializeJSON(raw) : {};
    var status=val(response.statusCode);
    if (status==401) driveFail("A conexão Google expirou. Reconecte a conta em Agenda Google.");
    if (status==403) driveFail("O Google Drive negou o envio. Verifique a permissão de Documentos.");
    if (status==429 || status>=500 || status==0) driveFail("O Google Drive está indisponível ou limitou o envio. Aguarde e tente novamente.");
    if (status<200 || status>=300) driveFail(driveRemoteMessage(data,"O Google Drive recusou o envio do arquivo."));
    return data;
}
function driveDownload(required string id) {
    var item=driveAssertInside(arguments.id);
    if (find("application/vnd.google-apps.",item.mimeType)==1) driveFail("Documentos nativos devem ser abertos no Google.");
    if (structKeyExists(item,"capabilities") && structKeyExists(item.capabilities,"canDownload") && !item.capabilities.canDownload) driveFail("O Google não permite baixar este arquivo.");
    var address="https://www.googleapis.com/drive/v3/files/" & item.id & "?alt=media&supportsAllDrives=true";
    var response={};
    var token=agendaAccessToken();
    for (var attempt=1; attempt<=2; attempt++) {
        cfhttp(url=address,method="GET",result="response",timeout=90,redirect=false,throwonerror=false,getasbinary="yes") {
            cfhttpparam(type="header",name="Authorization",value="Bearer " & token);
        }
        if (val(response.statusCode)!=401 || attempt==2) break;
        token=agendaAccessToken(true);
    }
    if (val(response.statusCode)<200 || val(response.statusCode)>=300 || !structKeyExists(response,"fileContent")) driveFail("Não foi possível baixar o arquivo do Google Drive.");
    return {"item"=item,"content"=response.fileContent};
}
</cfscript>
