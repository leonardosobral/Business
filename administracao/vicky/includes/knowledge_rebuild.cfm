<cfsetting requesttimeout="180"/>
<cfset VARIABLES.vickySection="conhecimento"/>
<cfset VARIABLES.vickyErrorStep="reconstrução do índice documental"/>
<cfif NOT structKeyExists(FORM,"csrf_token") OR compare(FORM.csrf_token&"",VARIABLES.vickyAdminCsrfToken) NEQ 0>
  <cfthrow type="Vicky.InvalidCsrf" message="A sessão de segurança expirou. Recarregue a página e tente novamente."/>
</cfif>
<cfif NOT structKeyExists(APPLICATION,"vickyKnowledge") OR NOT APPLICATION.vickyKnowledge.configured>
  <cfthrow type="Vicky.KnowledgeNotConfigured" message="OPENAI_API_KEY não configurada no Business."/>
</cfif>

<cfquery name="qVickyRebuildConfig" datasource="runner_dba">
  SELECT openai_vector_store_id
  FROM tb_vicky_knowledge_config
  WHERE id_config=1
</cfquery>
<cfset VARIABLES.previousVectorStoreId=qVickyRebuildConfig.recordCount?trim(qVickyRebuildConfig.openai_vector_store_id&""):""/>
<cfset VARIABLES.targetVectorStoreId=VARIABLES.previousVectorStoreId/>
<cfset VARIABLES.vectorStoreAvailable=false/>
<cfset VARIABLES.vectorStoreCreated=false/>

<cfif len(VARIABLES.previousVectorStoreId)>
  <cfhttp method="get" url="https://api.openai.com/v1/vector_stores/#urlEncodedFormat(VARIABLES.previousVectorStoreId)#" result="vickyRebuildStoreResponse" timeout="30" throwonerror="false">
    <cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/>
    <cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/>
  </cfhttp>
  <cfset VARIABLES.storeHttp=val(left(vickyRebuildStoreResponse.statusCode&"",3))/>
  <cfif VARIABLES.storeHttp GTE 200 AND VARIABLES.storeHttp LT 300>
    <cfset VARIABLES.vectorStoreAvailable=true/>
  <cfelseif VARIABLES.storeHttp NEQ 404>
    <cfthrow type="Vicky.OpenAI" message="Não foi possível validar o índice atual na OpenAI (HTTP #VARIABLES.storeHttp#). Nenhuma configuração foi alterada."/>
  </cfif>
</cfif>

<cfif NOT VARIABLES.vectorStoreAvailable>
  <cfset VARIABLES.createStorePayload=structNew("ordered")/>
  <cfset VARIABLES.createStorePayload["name"]="Vicky · Base de conhecimento RunnerHub"/>
  <cfhttp method="post" url="https://api.openai.com/v1/vector_stores" result="vickyCreateStoreResponse" timeout="45" throwonerror="false">
    <cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/>
    <cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/>
    <cfhttpparam type="header" name="Content-Type" value="application/json"/>
    <cfhttpparam type="body" value="#serializeJSON(VARIABLES.createStorePayload)#"/>
  </cfhttp>
  <cfset VARIABLES.createStoreHttp=val(left(vickyCreateStoreResponse.statusCode&"",3))/>
  <cfif VARIABLES.createStoreHttp LT 200 OR VARIABLES.createStoreHttp GTE 300>
    <cfthrow type="Vicky.OpenAI" message="A OpenAI não permitiu criar o novo índice documental (HTTP #VARIABLES.createStoreHttp#)."/>
  </cfif>
  <cfset VARIABLES.createStoreResponsePayload=deserializeJSON(vickyCreateStoreResponse.fileContent)/>
  <cfif NOT structKeyExists(VARIABLES.createStoreResponsePayload,"id") OR NOT reFind("^vs_[A-Za-z0-9_-]{3,200}$",VARIABLES.createStoreResponsePayload.id&"")>
    <cfthrow type="Vicky.OpenAI" message="A OpenAI criou o índice, mas não retornou um identificador válido."/>
  </cfif>
  <cfset VARIABLES.targetVectorStoreId=VARIABLES.createStoreResponsePayload.id&""/>
  <cfquery datasource="runner_dba">
    UPDATE tb_vicky_knowledge_config
    SET openai_vector_store_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.targetVectorStoreId#"/>
    WHERE id_config=1
  </cfquery>
  <cfset VARIABLES.vectorStoreCreated=true/>
</cfif>

<cfquery name="qVickyRebuildDocuments" datasource="runner_dba">
  SELECT id_vicky_documento,titulo,nome_arquivo,tamanho_bytes,openai_file_id,status
  FROM tb_vicky_documento
  WHERE status IN (<cfif VARIABLES.vectorStoreCreated>'active','processing','failed'<cfelse>'processing','failed'</cfif>)
  ORDER BY id_vicky_documento
</cfquery>
<cfset VARIABLES.rebuildAvailableFiles=[]/>
<cfset VARIABLES.rebuildFilesCursor=""/>
<cfloop from="1" to="10" index="rebuildFilesPage">
  <cfset VARIABLES.rebuildFilesUrl="https://api.openai.com/v1/files?purpose=assistants&limit=100"/>
  <cfif len(VARIABLES.rebuildFilesCursor)><cfset VARIABLES.rebuildFilesUrl&="&after="&urlEncodedFormat(VARIABLES.rebuildFilesCursor)/></cfif>
  <cfhttp method="get" url="#VARIABLES.rebuildFilesUrl#" result="vickyRebuildFilesResponse" timeout="45" throwonerror="false">
    <cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/>
  </cfhttp>
  <cfset VARIABLES.rebuildFilesHttp=val(left(vickyRebuildFilesResponse.statusCode&"",3))/>
  <cfif VARIABLES.rebuildFilesHttp LT 200 OR VARIABLES.rebuildFilesHttp GTE 300><cfbreak/></cfif>
  <cfset VARIABLES.rebuildFilesPayload=deserializeJSON(vickyRebuildFilesResponse.fileContent)/>
  <cfif NOT structKeyExists(VARIABLES.rebuildFilesPayload,"data") OR NOT isArray(VARIABLES.rebuildFilesPayload.data)><cfbreak/></cfif>
  <cfloop array="#VARIABLES.rebuildFilesPayload.data#" index="rebuildAvailableFile"><cfset arrayAppend(VARIABLES.rebuildAvailableFiles,rebuildAvailableFile)/></cfloop>
  <cfif NOT structKeyExists(VARIABLES.rebuildFilesPayload,"has_more") OR NOT VARIABLES.rebuildFilesPayload.has_more OR NOT arrayLen(VARIABLES.rebuildFilesPayload.data)><cfbreak/></cfif>
  <cfset VARIABLES.rebuildFilesCursor=VARIABLES.rebuildFilesPayload.data[arrayLen(VARIABLES.rebuildFilesPayload.data)].id&""/>
</cfloop>
<cfset VARIABLES.rebuildAttached=0/>
<cfset VARIABLES.rebuildFailed=0/>
<cfloop query="qVickyRebuildDocuments">
  <cfset VARIABLES.rebuildFileId=trim(qVickyRebuildDocuments.openai_file_id&"")/>
  <cfset VARIABLES.rebuildAttachHttp=0/>
  <cfset VARIABLES.rebuildRecoveredFile=false/>
  <cfif reFind("^file-[A-Za-z0-9_-]{3,200}$",VARIABLES.rebuildFileId)>
    <cfset VARIABLES.rebuildAttachPayload=structNew("ordered")/>
    <cfset VARIABLES.rebuildAttachPayload["file_id"]=VARIABLES.rebuildFileId/>
    <cfhttp method="post" url="https://api.openai.com/v1/vector_stores/#urlEncodedFormat(VARIABLES.targetVectorStoreId)#/files" result="vickyRebuildAttachResponse" timeout="45" throwonerror="false">
      <cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/>
      <cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/>
      <cfhttpparam type="header" name="Content-Type" value="application/json"/>
      <cfhttpparam type="body" value="#serializeJSON(VARIABLES.rebuildAttachPayload)#"/>
    </cfhttp>
    <cfset VARIABLES.rebuildAttachHttp=val(left(vickyRebuildAttachResponse.statusCode&"",3))/>
  </cfif>
  <cfif VARIABLES.rebuildAttachHttp EQ 0 OR VARIABLES.rebuildAttachHttp EQ 404>
    <cfset VARIABLES.rebuildExactMatches=[]/>
    <cfset VARIABLES.rebuildSizeMatches=[]/>
    <cfloop array="#VARIABLES.rebuildAvailableFiles#" index="rebuildCandidateFile">
      <cfif structKeyExists(rebuildCandidateFile,"id") AND structKeyExists(rebuildCandidateFile,"bytes") AND val(rebuildCandidateFile.bytes) EQ val(qVickyRebuildDocuments.tamanho_bytes)>
        <cfset arrayAppend(VARIABLES.rebuildSizeMatches,rebuildCandidateFile)/>
        <cfif structKeyExists(rebuildCandidateFile,"filename") AND compareNoCase(rebuildCandidateFile.filename&"",qVickyRebuildDocuments.nome_arquivo&"") EQ 0><cfset arrayAppend(VARIABLES.rebuildExactMatches,rebuildCandidateFile)/></cfif>
      </cfif>
    </cfloop>
    <cfset VARIABLES.rebuildReplacementFileId=""/>
    <cfif arrayLen(VARIABLES.rebuildExactMatches) EQ 1><cfset VARIABLES.rebuildReplacementFileId=VARIABLES.rebuildExactMatches[1].id&""/>
    <cfelseif arrayLen(VARIABLES.rebuildSizeMatches) EQ 1><cfset VARIABLES.rebuildReplacementFileId=VARIABLES.rebuildSizeMatches[1].id&""/></cfif>
    <cfif reFind("^file-[A-Za-z0-9_-]{3,200}$",VARIABLES.rebuildReplacementFileId) AND compare(VARIABLES.rebuildReplacementFileId,VARIABLES.rebuildFileId) NEQ 0>
      <cfset VARIABLES.rebuildFileId=VARIABLES.rebuildReplacementFileId/>
      <cfset VARIABLES.rebuildAttachPayload=structNew("ordered")/><cfset VARIABLES.rebuildAttachPayload["file_id"]=VARIABLES.rebuildFileId/>
      <cfhttp method="post" url="https://api.openai.com/v1/vector_stores/#urlEncodedFormat(VARIABLES.targetVectorStoreId)#/files" result="vickyRebuildRecoveredAttachResponse" timeout="45" throwonerror="false">
        <cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/>
        <cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/>
        <cfhttpparam type="header" name="Content-Type" value="application/json"/>
        <cfhttpparam type="body" value="#serializeJSON(VARIABLES.rebuildAttachPayload)#"/>
      </cfhttp>
      <cfset VARIABLES.rebuildAttachHttp=val(left(vickyRebuildRecoveredAttachResponse.statusCode&"",3))/>
      <cfset VARIABLES.rebuildRecoveredFile=VARIABLES.rebuildAttachHttp GTE 200 AND VARIABLES.rebuildAttachHttp LT 300/>
    </cfif>
  </cfif>
  <cfif VARIABLES.rebuildAttachHttp GTE 200 AND VARIABLES.rebuildAttachHttp LT 300>
    <cfquery datasource="runner_dba">UPDATE tb_vicky_documento SET openai_file_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.rebuildFileId#"/>,status='processing',updated_at=now() WHERE id_vicky_documento=<cfqueryparam cfsqltype="cf_sql_bigint" value="#qVickyRebuildDocuments.id_vicky_documento#"/></cfquery>
    <cfset VARIABLES.rebuildAttached=VARIABLES.rebuildAttached+1/>
    <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=qVickyRebuildDocuments.titulo&"",status="reprocessed",detail=VARIABLES.rebuildRecoveredFile?"Cópia existente recuperada; aguardando processamento":"Associado ao índice; aguardando processamento"})/>
  <cfelse>
    <cfquery datasource="runner_dba">UPDATE tb_vicky_documento SET status='failed',updated_at=now() WHERE id_vicky_documento=<cfqueryparam cfsqltype="cf_sql_bigint" value="#qVickyRebuildDocuments.id_vicky_documento#"/></cfquery>
    <cfset VARIABLES.rebuildFailed=VARIABLES.rebuildFailed+1/>
    <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=qVickyRebuildDocuments.titulo&"",status="failed",detail=(VARIABLES.rebuildAttachHttp EQ 0 OR VARIABLES.rebuildAttachHttp EQ 404)?"O arquivo não existe mais na OpenAI; reenvie o PDF":"A OpenAI recusou a associação ao índice (HTTP #VARIABLES.rebuildAttachHttp#)"})/>
  </cfif>
</cfloop>

<cfset VARIABLES.vickyMessage=(VARIABLES.vectorStoreCreated?"O índice ausente foi recriado. ":"O índice existente foi mantido. ")&VARIABLES.rebuildAttached&" documento(s) enviado(s) para processamento e "&VARIABLES.rebuildFailed&" com falha."/>
<cfset VARIABLES.vickyMessageType=VARIABLES.rebuildFailed GT 0?"warning":"success"/>
