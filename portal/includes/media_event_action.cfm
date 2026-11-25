<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0 OR NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin><cfheader statuscode="403"/><cfabort/></cfif>
<!--- Changes only the event association; publication and feature flags are independent. --->
<cfset VARIABLES.mediaEventSuccess=""/>
<cfif len(FORM.media_event_action)>
 <cfset VARIABLES.mediaEditId=val(FORM.media_id ?: 0)/>
 <cfif CGI.request_method NEQ "POST" OR NOT len(VARIABLES.mediaEventCsrf) OR compare(FORM.media_event_csrf ?: "",VARIABLES.mediaEventCsrf) NEQ 0>
  <cfset VARIABLES.mediaFeaturedEventAlert={type="danger",message="Sua sessão de edição expirou. Recarregue a página e tente novamente."}/>
 <cfelseif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
  <cfset VARIABLES.mediaFeaturedEventAlert={type="danger",message="Você não tem permissão para alterar os vídeos."}/>
 <cfelseif NOT VARIABLES.mediaHasEventId>
  <cfset VARIABLES.mediaFeaturedEventAlert={type="danger",message="O vínculo com eventos não está disponível neste momento."}/>
 <cfelseif NOT listFind("salvar,remover",FORM.media_event_action)
   OR NOT reFind("^[1-9][0-9]{0,9}$",FORM.media_id ?: "") OR val(FORM.media_id) GT 2147483647
   OR NOT reFind("^[0-9]{1,10}$",structKeyExists(FORM,"expected_event_id") ? (FORM.expected_event_id & "") : "") OR val(FORM.expected_event_id) GT 2147483647
   OR (FORM.media_event_action EQ "salvar" AND (NOT reFind("^[1-9][0-9]{0,9}$",FORM.id_evento ?: "") OR val(FORM.id_evento) GT 2147483647))>
  <cfset VARIABLES.mediaFeaturedEventAlert={type="danger",message="Selecione um vídeo e um evento válidos antes de salvar."}/>
 <cfelse>
  <cftry>
   <cfset VARIABLES.mediaEventTargetId=FORM.media_event_action EQ "remover" ? 0 : val(FORM.id_evento)/>
   <cfset VARIABLES.mediaEventTargetExists=true/>
   <cfif VARIABLES.mediaEventTargetId GT 0>
    <cfquery name="qMediaEventTargetCheck">
     SELECT id_evento FROM tb_evento_corridas WHERE id_evento=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaEventTargetId#"/>
    </cfquery>
    <cfset VARIABLES.mediaEventTargetExists=qMediaEventTargetCheck.recordcount EQ 1/>
   </cfif>
   <cfif NOT VARIABLES.mediaEventTargetExists>
    <cfset VARIABLES.mediaFeaturedEventAlert={type="danger",message="O evento selecionado não foi encontrado. Faça uma nova busca."}/>
   <cfelse>
    <cfquery result="mediaEventUpdateResult">
     UPDATE tb_media SET id_evento=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.mediaEventTargetId#" null="#VARIABLES.mediaEventTargetId EQ 0#"/>
     WHERE "#Replace(VARIABLES.mediaPk,'"','""','all')#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.media_id#"/>
       AND coalesce(id_evento,0)=<cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.expected_event_id#"/>
    </cfquery>
    <cfif mediaEventUpdateResult.recordcount EQ 1>
     <cfset VARIABLES.mediaEventSuccess=VARIABLES.mediaEventTargetId GT 0 ? "evento_vinculado" : "evento_desvinculado"/>
    <cfelse>
     <cfset VARIABLES.mediaFeaturedEventAlert={type="warning",message="O vídeo foi removido ou o vínculo mudou em outra edição. Confira o vínculo atual antes de tentar novamente."}/>
    </cfif>
   </cfif>
   <cfcatch>
    <cfset VARIABLES.mediaFeaturedEventAlert={type="danger",message="Não foi possível salvar o vínculo. Tente novamente."}/>
    <cflog file="portal-videos" type="error" text="Falha ao vincular evento ao vídeo: #cfcatch.type#"/>
   </cfcatch>
  </cftry>
 </cfif>
</cfif>
