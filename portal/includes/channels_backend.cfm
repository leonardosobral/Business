<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
channelManager=new services.YoutubeChannelManager(val(qPerfil.id));
if(!structKeyExists(SESSION,"youtubeChannelCsrf"))SESSION.youtubeChannelCsrf=lCase(hash(generateSecretKey("AES",256),"SHA-256"));
channelError="";channelNotice="";
channelSearch=left(trim(URL.busca ?: ""),100);
channelStatus=lCase(trim(URL.status ?: "all"));if(!listFind("all,active,inactive",channelStatus))channelStatus="all";
channelEditId=reFind("^[1-9][0-9]{0,9}$",URL.canal_editar ?: "") ? val(URL.canal_editar) : 0;
channelShowForm=channelEditId GT 0 OR (URL.canal_novo ?: "") EQ "1";
channelForm={id_youtube_canal="0",revision="",name="",source_type="channel",source="",id_pagina="",id_usuario="",page_label="",user_label="",max_results="3",sort_order="0",min_duration_minutes="",max_duration_minutes="",enabled="1",descricao="",instagram_url=""};
qChannelEdit=channelManager.get(channelEditId);
if(channelEditId AND !qChannelEdit.recordCount)channelError="Canal não encontrado. Atualize a lista.";
if(qChannelEdit.recordCount){
 row=queryGetRow(qChannelEdit,1);
 for(key in ['id_youtube_canal','revision','name','source_type','max_results','sort_order','descricao','instagram_url'])channelForm[key]=isNull(row[key]) ? "" : row[key];
 channelForm.enabled=row.enabled ? "1" : "0";channelForm.source=channelManager.sourceUrl(row);
 channelForm.id_pagina=val(row.id_pagina ?: 0) GT 0 ? numberFormat(row.id_pagina,"0") : "";channelForm.id_usuario=val(row.id_usuario ?: 0) GT 0 ? numberFormat(row.id_usuario,"0") : "";
 channelForm.page_label=len(channelForm.id_pagina) ? row.page_name&(len(row.page_tag ?: "") ? " · @"&row.page_tag : "") : "";
 channelForm.user_label=len(channelForm.id_usuario) ? row.user_name&" · "&row.user_email : "";
 channelForm.min_duration_minutes=isNumeric(row.min_duration_seconds ?: "") ? val(row.min_duration_seconds)/60 : "";
 channelForm.max_duration_minutes=isNumeric(row.max_duration_seconds ?: "") ? val(row.max_duration_seconds)/60 : "";
}
if(structKeyExists(FORM,"canal_action")){
 if(CGI.request_method NEQ "POST" OR compare(FORM.channel_csrf ?: "",SESSION.youtubeChannelCsrf) NEQ 0){cfheader(statuscode=403);writeOutput("Recarregue a página antes de tentar novamente.");abort;}
 try{
  if(FORM.canal_action EQ "salvar"){
   for(key in channelForm)if(structKeyExists(FORM,key))channelForm[key]=FORM[key];
   channelForm.enabled=structKeyExists(FORM,"enabled") ? "1" : "0";
   savedId=channelManager.save(channelForm);
   location(url="./?canal_editar="&savedId&"&sucesso=salvo##channel-editor",addtoken=false);
  }else if(FORM.canal_action EQ "status"){
   channelManager.toggle(val(FORM.id_youtube_canal ?: 0),FORM.revision ?: "");location(url="./?sucesso=status",addtoken=false);
  }else if(FORM.canal_action EQ "remover"){
   if((FORM.confirm_remove ?: "") NEQ "1")throw(type="YoutubeChannel.Validation",message="Confirme a remoção do canal.");
   channelManager.remove(val(FORM.id_youtube_canal ?: 0),FORM.revision ?: "");location(url="./?sucesso=removido",addtoken=false);
  }
 }catch(YoutubeChannel.Validation e){channelError=e.message;channelShowForm=FORM.canal_action EQ "salvar" OR channelShowForm;}
 catch(YoutubeChannel.Conflict e){channelError=e.message;channelShowForm=FORM.canal_action EQ "salvar" OR channelShowForm;}
 catch(any e){channelError="Não foi possível salvar. Seus dados foram preservados; tente novamente.";channelShowForm=FORM.canal_action EQ "salvar" OR channelShowForm;writeLog(file="youtube-channels",type="error",text="Falha no gerenciador de canais: "&e.type);}
}
if((URL.sucesso ?: "") EQ "salvo")channelNotice="Canal salvo. Quando ativo, será considerado na próxima importação automática.";
if((URL.sucesso ?: "") EQ "status")channelNotice="Status de importação atualizado.";
if((URL.sucesso ?: "") EQ "removido")channelNotice="Fonte removida. Os vídeos já importados foram preservados.";
qChannels=channelManager.listing(channelSearch,channelStatus);
qChannelStats=queryExecute("SELECT count(*) AS total,count(*) FILTER(WHERE enabled) AS active,count(*) FILTER(WHERE NOT enabled) AS inactive FROM tb_youtube_canais",{},{datasource="runner_dba"});
</cfscript>
