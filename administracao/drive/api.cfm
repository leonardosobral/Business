<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="120"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../agenda/includes/service.cfm"/>
<cfinclude template="includes/service.cfm"/>
<cfscript>
function driveReply(required struct payload,numeric status=200) {
    cfheader(statuscode=arguments.status);
    cfheader(name="Cache-Control",value="no-store");
    cfcontent(type="application/json; charset=utf-8",reset=true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}
function driveDispatch() {
    driveMutation();
    var action=driveInput("action");
    if (action=="status") {
        if (!driveReady()) return {"schemaReady"=false,"connected"=false,"rootConfigured"=false,"message"="Execute administracao/drive/drive_schema.sql no banco runner_dba."};
        if (!agendaReady()) return {"schemaReady"=true,"connected"=false,"rootConfigured"=false,"message"="Aplique também o schema da Agenda Google."};
        var connection=driveDb("SELECT email,scopes FROM public.tb_google_agenda_conexao WHERE id=1");
        var root=driveRoot();
        var connected=connection.recordCount>0 && listFind(connection.scopes[1] & "","https://www.googleapis.com/auth/drive.file"," ");
        return {"schemaReady"=true,"connected"=connected,"email"=connection.recordCount ? connection.email[1] : "contato@runnerhub.run","rootConfigured"=root.configured,"root"=root,"maxUploadBytes"=driveConfig().maxUploadBytes,"pickerConfigured"=drivePickerConfigured(),"message"=connected ? (root.configured ? "Documentos conectados." : "Crie a pasta raiz para começar.") : "Reconecte a conta em Agenda Google para autorizar Documentos."};
    }
    if (!driveReady()) driveFail("Execute administracao/drive/drive_schema.sql no banco runner_dba.");
    agendaAccessToken();
    var root=driveRoot();
    var response={};
    var audit=0;
    if (action=="create_root") {
        if (root.configured) driveFail("A pasta raiz já está configurada.");
        var rootName=driveName(driveConfig().rootName);
        audit=driveAudit(action,"",rootName);
        try {
            response=driveGoogle("/files","POST",{"fields"="id,name,mimeType,webViewLink,parents","supportsAllDrives"="true"},{"name"=rootName,"mimeType"="application/vnd.google-apps.folder"});
            transaction {
                driveDb("UPDATE public.tb_google_drive_auditoria SET file_id=:file WHERE id=:id",{file=driveParam(response.id),id={value=audit,cfsqltype="cf_sql_bigint"}});
                driveDb("INSERT INTO public.tb_google_drive_config(id,root_folder_id,root_folder_name,criado_por) VALUES(1,:file,:name,:actor)",{file=driveParam(response.id),name=driveParam(response.name),actor={value=val(qPerfil.id),cfsqltype="cf_sql_integer"}});
                driveAuditEnd(audit,"success");
            }
        } catch(any rootError) {
            if (structKeyExists(response,"id")) try { driveGoogle("/files/" & response.id,"PATCH",{"supportsAllDrives"="true"},{"trashed"=true}); } catch(any cleanupError) {}
            try { driveAuditEnd(audit,"failed"); } catch(any auditError) {}
            rethrow;
        }
        return {"message"="Pasta raiz criada.","root"={"configured"=true,"id"=response.id,"name"=response.name,"webViewLink"=structKeyExists(response,"webViewLink") ? response.webViewLink : ""}};
    }
    if (!root.configured) driveFail("Crie a pasta raiz de Documentos primeiro.");
    if (action=="list") {
        var folderId=len(driveInput("folder_id")) ? driveId(driveInput("folder_id")) : root.id;
        return driveList(folderId,driveInput("search"),driveInput("page_token"));
    }
    if (action=="authorize_picker") {
        if (!drivePickerConfigured()) driveFail("Configure a chave e o App ID do Google Picker no servidor.");
        var rawIds=driveInput("ids");
        if (len(rawIds)>30000 || !isJSON(rawIds)) driveFail("A seleção do Google Drive é inválida.");
        var pickedIds=deserializeJSON(rawIds);
        if (!isArray(pickedIds) || !arrayLen(pickedIds) || arrayLen(pickedIds)>100) driveFail("Selecione de 1 a 100 itens por vez.");
        // Refresh after the Picker grants per-file access so the server immediately sees the new authorization.
        agendaAccessToken(true);
        var authorized=0;
        var rejected=0;
        var seen={};
        for (var pickedIdValue in pickedIds) {
            try {
                if (!isSimpleValue(pickedIdValue)) driveFail("Identificador selecionado inválido.");
                var pickedId=driveId(pickedIdValue & "");
                if (structKeyExists(seen,pickedId)) continue;
                seen[pickedId]=true;
                var pickedItem=driveAssertInside(pickedId);
                audit=driveAudit(action,pickedId,structKeyExists(pickedItem,"name") ? pickedItem.name : "");
                driveAuditEnd(audit,"success");
                authorized++;
            } catch(any pickedError) {
                var rejectedReason=pickedError.message & "";
                if (!findNoCase("Identificador",rejectedReason) && !findNoCase("não pertence",rejectedReason) && !findNoCase("não foi encontrado",rejectedReason) && !findNoCase("lixeira",rejectedReason)) rethrow;
                rejected++;
            }
        }
        if (!authorized) driveFail("Nenhum item selecionado pertence à pasta de Documentos atual. Abra o Picker nesta pasta e selecione seus arquivos ou subpastas.");
        return {"message"=authorized & (authorized==1 ? " item autorizado." : " itens autorizados.") & (rejected ? " " & rejected & (rejected==1 ? " item foi ignorado por estar fora da pasta ou sem acesso." : " itens foram ignorados por estarem fora da pasta ou sem acesso.") : ""),"authorized"=authorized,"rejected"=rejected};
    }
    if (action=="create") {
        var createType=driveInput("type");
        var createName=driveName(driveInput("name"));
        var parentId=len(driveInput("parent_id")) ? driveId(driveInput("parent_id")) : root.id;
        var createMime=driveMimeFor(createType);
        audit=driveAudit("create_" & createType,"",createName);
        try {
            response=driveCreateFile(createName,createMime,parentId);
            driveDb("UPDATE public.tb_google_drive_auditoria SET file_id=:file WHERE id=:id",{file=driveParam(response.id),id={value=audit,cfsqltype="cf_sql_bigint"}});
            driveAuditEnd(audit,"success");
        } catch(any createError) { driveAuditEnd(audit,"failed"); rethrow; }
        return {"message"=createType=="folder" ? "Pasta criada." : "Documento criado.","item"=response};
    }
    if (action=="rename") {
        var renameId=driveId(driveInput("file_id"));
        if (renameId==root.id) driveFail("O nome da pasta raiz é fixo nesta versão.");
        var current=driveAssertInside(renameId);
        if (structKeyExists(current,"capabilities") && ((structKeyExists(current.capabilities,"canRename") && !current.capabilities.canRename) || (!structKeyExists(current.capabilities,"canRename") && structKeyExists(current.capabilities,"canEdit") && !current.capabilities.canEdit))) driveFail("O Google não permite renomear este arquivo.");
        var newName=driveName(driveInput("name"));
        audit=driveAudit(action,renameId,newName);
        try {
            response=driveGoogle("/files/" & renameId,"PATCH",{"fields"="id,name,mimeType,modifiedTime,size,webViewLink,parents,capabilities/canEdit,capabilities/canRename,capabilities/canTrash,capabilities/canDownload","supportsAllDrives"="true"},{"name"=newName});
            driveAuditEnd(audit,"success");
        } catch(any renameError) { driveAuditEnd(audit,"failed"); rethrow; }
        return {"message"="Item renomeado.","item"=response};
    }
    if (action=="trash") {
        var trashId=driveId(driveInput("file_id"));
        if (trashId==root.id) driveFail("A pasta raiz não pode ser enviada à lixeira pelo Business.");
        var trashItem=driveAssertInside(trashId);
        if (structKeyExists(trashItem,"capabilities") && structKeyExists(trashItem.capabilities,"canTrash") && !trashItem.capabilities.canTrash) driveFail("O Google não permite enviar este item à lixeira.");
        audit=driveAudit(action,trashId,trashItem.name);
        try {
            driveGoogle("/files/" & trashId,"PATCH",{"fields"="id,trashed","supportsAllDrives"="true"},{"trashed"=true});
            driveAuditEnd(audit,"success");
        } catch(any trashError) { driveAuditEnd(audit,"failed"); rethrow; }
        return {"message"="Item enviado à lixeira do Google Drive."};
    }
    if (action=="upload") {
        var uploadParent=len(driveInput("parent_id")) ? driveId(driveInput("parent_id")) : root.id;
        driveAssertInside(uploadParent,true);
        if (!structKeyExists(form,"upload_file") || !len(trim(form.upload_file & ""))) driveFail("Selecione um arquivo.");
        var uploadedPath="";
        var uploadedItem={};
        var uploadAudit=0;
        try {
            var uploadResult=fileUpload(getTempDirectory(),"upload_file","","makeUnique");
            uploadedPath=uploadResult.serverDirectory & "/" & uploadResult.serverFile;
            if (val(uploadResult.fileSize)<=0 || val(uploadResult.fileSize)>driveConfig().maxUploadBytes) driveFail("O arquivo deve ter entre 1 byte e " & int(driveConfig().maxUploadBytes/1048576) & " MB.");
            var clientName=listLast(replace(uploadResult.clientFile & "","\","/","all"),"/");
            clientName=driveName(clientName);
            var extension=lCase(listLen(clientName,".")>1 ? listLast(clientName,".") : "");
            var blocked="cfm,cfc,cfml,jsp,php,asp,aspx,exe,dll,com,bat,cmd,sh,ps1,jar,war,js,mjs";
            if (listFindNoCase(blocked,extension)) driveFail("Este tipo de arquivo não é permitido.");
            var uploadMime=len(trim(uploadResult.contentType & "")) ? uploadResult.contentType & "/" & uploadResult.contentSubType : "application/octet-stream";
            uploadAudit=driveAudit(action,"",clientName);
            uploadedItem=driveCreateFile(clientName,uploadMime,uploadParent);
            driveDb("UPDATE public.tb_google_drive_auditoria SET file_id=:file WHERE id=:id",{file=driveParam(uploadedItem.id),id={value=uploadAudit,cfsqltype="cf_sql_bigint"}});
            try {
                uploadedItem=driveUploadContent(uploadedItem.id,uploadedPath,uploadMime);
                driveAuditEnd(uploadAudit,"success");
            } catch(any contentError) {
                try { driveGoogle("/files/" & uploadedItem.id,"PATCH",{"supportsAllDrives"="true"},{"trashed"=true}); } catch(any cleanupError) {}
                driveAuditEnd(uploadAudit,"failed");
                rethrow;
            }
        } finally {
            if (len(uploadedPath) && fileExists(uploadedPath)) fileDelete(uploadedPath);
        }
        return {"message"="Arquivo enviado.","item"=uploadedItem};
    }
    driveFail("Operação de Documentos inválida.");
}
try {
    lock name="RunnerHubBusiness.GoogleDrive" type="exclusive" timeout="110" { result=driveDispatch(); }
    result["success"]=true;
    driveReply(result);
} catch(any error) {
    driveReply({"success"=false,"message"=error.type=="Drive.Validation" || error.type=="Agenda.Validation" ? error.message : "Não foi possível concluir a operação em Documentos."},400);
}
</cfscript>
