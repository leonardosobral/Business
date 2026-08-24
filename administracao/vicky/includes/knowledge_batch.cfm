<cfset VARIABLES.vickySection="conhecimento"/>
<cfif NOT structKeyExists(FORM,"csrf_token") OR compare(FORM.csrf_token&"",VARIABLES.vickyAdminCsrfToken) NEQ 0>
  <cfthrow type="Vicky.InvalidCsrf" message="A sessão de segurança expirou. Recarregue a página e tente novamente."/>
</cfif>
<cfif NOT structKeyExists(APPLICATION,"vickyKnowledge") OR NOT APPLICATION.vickyKnowledge.configured>
  <cfthrow type="Vicky.KnowledgeNotConfigured" message="OPENAI_API_KEY não configurada no Business."/>
</cfif>

<cfquery name="qVickyKnowledgeBatchConfig" datasource="runner_dba">
  SELECT openai_vector_store_id
  FROM tb_vicky_knowledge_config
  WHERE id_config=1
</cfquery>
<cfset VARIABLES.vectorStoreId=qVickyKnowledgeBatchConfig.recordCount?trim(qVickyKnowledgeBatchConfig.openai_vector_store_id&""):""/>
<cfif NOT len(VARIABLES.vectorStoreId)>
  <cfthrow type="Vicky.KnowledgeNotConfigured" message="O índice documental ainda não foi configurado."/>
</cfif>

<cfif FORM.action EQ "refresh_documents_batch">
  <cfset VARIABLES.vickyErrorStep="verificação em lote dos documentos"/>
  <cfquery name="qVickyBatchProcessing" datasource="runner_dba">
    SELECT id_vicky_documento,titulo,openai_file_id
    FROM tb_vicky_documento
    WHERE status='processing'
    ORDER BY id_vicky_documento
    LIMIT 100
  </cfquery>
  <cfset VARIABLES.completedCount=0/><cfset VARIABLES.failedCount=0/><cfset VARIABLES.pendingCount=0/>
  <cfloop query="qVickyBatchProcessing">
    <cftry>
      <cfhttp method="get" url="https://api.openai.com/v1/vector_stores/#urlEncodedFormat(VARIABLES.vectorStoreId)#/files/#urlEncodedFormat(qVickyBatchProcessing.openai_file_id)#" result="vickyBatchStatusResponse" timeout="30" throwonerror="false">
        <cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/>
        <cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/>
      </cfhttp>
      <cfset VARIABLES.statusHttp=val(left(vickyBatchStatusResponse.statusCode&"",3))/>
      <cfif VARIABLES.statusHttp GTE 200 AND VARIABLES.statusHttp LT 300>
        <cfset VARIABLES.remotePayload=deserializeJSON(vickyBatchStatusResponse.fileContent)/>
        <cfset VARIABLES.remoteStatus=lCase(VARIABLES.remotePayload.status&"")/>
        <cfif VARIABLES.remoteStatus EQ "completed">
          <cfquery datasource="runner_dba">UPDATE tb_vicky_documento SET status='active',updated_at=now() WHERE id_vicky_documento=<cfqueryparam cfsqltype="cf_sql_bigint" value="#qVickyBatchProcessing.id_vicky_documento#"/> AND status='processing'</cfquery>
          <cfset VARIABLES.completedCount=VARIABLES.completedCount+1/>
          <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=qVickyBatchProcessing.titulo&"",status="active",detail="Indexado e ativado"})/>
        <cfelseif listFindNoCase("failed,cancelled",VARIABLES.remoteStatus)>
          <cfquery datasource="runner_dba">UPDATE tb_vicky_documento SET status='failed',updated_at=now() WHERE id_vicky_documento=<cfqueryparam cfsqltype="cf_sql_bigint" value="#qVickyBatchProcessing.id_vicky_documento#"/> AND status='processing'</cfquery>
          <cfset VARIABLES.failedCount=VARIABLES.failedCount+1/>
          <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=qVickyBatchProcessing.titulo&"",status="failed",detail="A indexação falhou"})/>
        <cfelse>
          <cfset VARIABLES.pendingCount=VARIABLES.pendingCount+1/>
          <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=qVickyBatchProcessing.titulo&"",status="processing",detail="Ainda em processamento"})/>
        </cfif>
      <cfelse>
        <cfset VARIABLES.pendingCount=VARIABLES.pendingCount+1/>
        <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=qVickyBatchProcessing.titulo&"",status="processing",detail="Não foi possível consultar agora (HTTP #VARIABLES.statusHttp#)"})/>
      </cfif>
      <cfcatch>
        <cfset VARIABLES.pendingCount=VARIABLES.pendingCount+1/>
        <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=qVickyBatchProcessing.titulo&"",status="processing",detail="Não foi possível consultar agora"})/>
      </cfcatch>
    </cftry>
  </cfloop>
  <cfif NOT qVickyBatchProcessing.recordCount>
    <cfset VARIABLES.vickyMessage="Não há documentos aguardando processamento."/>
    <cfset VARIABLES.vickyMessageType="info"/>
  <cfelse>
    <cfset VARIABLES.vickyMessage="#VARIABLES.completedCount# ativado(s), #VARIABLES.pendingCount# ainda em processamento e #VARIABLES.failedCount# com falha."/>
    <cfset VARIABLES.vickyMessageType=VARIABLES.failedCount GT 0?"warning":"success"/>
  </cfif>
<cfelse>
  <cfset VARIABLES.vickyErrorStep="upload em lote dos documentos"/>
  <cfparam name="FORM.document_title" default=""/><cfparam name="FORM.document_category" default="auto"/><cfparam name="FORM.document_issuer" default="CBAt"/><cfparam name="FORM.document_version" default=""/><cfparam name="FORM.document_effective_date" default=""/>
  <cffile action="uploadAll" destination="#getTempDirectory()#" nameconflict="makeunique" accept="application/pdf,.pdf" strict="false" result="vickyUploads"/>
  <cfif NOT isArray(vickyUploads)><cfset vickyUploads=[vickyUploads]/></cfif>
  <cfif NOT arrayLen(vickyUploads)><cfthrow type="Vicky.InvalidDocument" message="Selecione ao menos um arquivo PDF."/></cfif>
  <cfif arrayLen(vickyUploads) GT 50>
    <cfloop array="#vickyUploads#" index="vickyExcessUpload"><cfset VARIABLES.excessTempFile=vickyExcessUpload.serverDirectory&"/"&vickyExcessUpload.serverFile/><cfif fileExists(VARIABLES.excessTempFile)><cffile action="delete" file="#VARIABLES.excessTempFile#"/></cfif></cfloop>
    <cfthrow type="Vicky.InvalidDocument" message="Envie no máximo 50 PDFs por lote."/>
  </cfif>

  <cfset VARIABLES.uploadedCount=0/><cfset VARIABLES.replacedCount=0/><cfset VARIABLES.skippedCount=0/><cfset VARIABLES.failedCount=0/>
  <cfloop array="#vickyUploads#" index="vickyUpload">
    <cfset VARIABLES.vickyTempFile=vickyUpload.serverDirectory&"/"&vickyUpload.serverFile/>
    <cfset VARIABLES.clientFile=left(vickyUpload.clientFile&"",255)/>
    <cfset VARIABLES.openAiFileId=""/>
    <cftry>
      <cfset VARIABLES.vickyPdfBinary=fileReadBinary(VARIABLES.vickyTempFile)/>
      <cfif lCase(vickyUpload.serverFileExt&"") NEQ "pdf" OR val(vickyUpload.fileSize) GT 20971520 OR uCase(left(binaryEncode(VARIABLES.vickyPdfBinary,"hex"),8)) NEQ "25504446">
        <cfthrow type="Vicky.InvalidDocument" message="Não é um PDF válido de até 20 MB."/>
      </cfif>
      <cfset VARIABLES.documentSha=hash(VARIABLES.vickyPdfBinary,"SHA-256")/>
      <cfset VARIABLES.documentTitle=left(trim(reReplace(VARIABLES.clientFile,"(?i)\.pdf$","","one")),240)/>
      <cfif arrayLen(vickyUploads) EQ 1 AND len(trim(FORM.document_title&""))><cfset VARIABLES.documentTitle=left(trim(FORM.document_title&""),240)/></cfif>
      <cfif NOT len(VARIABLES.documentTitle)><cfthrow type="Vicky.InvalidDocument" message="Não foi possível obter o título pelo nome do arquivo."/></cfif>
      <cfset VARIABLES.documentCategory=lCase(trim(FORM.document_category&""))/>
      <cfif VARIABLES.documentCategory EQ "auto">
        <cfif reFindNoCase("(^|[ _-])(norma|regras?)([ _-]|$)",VARIABLES.documentTitle)><cfset VARIABLES.documentCategory="normas"/>
        <cfelseif reFindNoCase("regulamento",VARIABLES.documentTitle)><cfset VARIABLES.documentCategory="regulamentos"/>
        <cfelseif reFindNoCase("pol[ií]tica",VARIABLES.documentTitle)><cfset VARIABLES.documentCategory="politicas"/>
        <cfelseif reFindNoCase("manual",VARIABLES.documentTitle)><cfset VARIABLES.documentCategory="manuais"/>
        <cfelse><cfset VARIABLES.documentCategory="outros"/></cfif>
      </cfif>
      <cfif NOT listFindNoCase("normas,regulamentos,politicas,manuais,outros",VARIABLES.documentCategory)><cfset VARIABLES.documentCategory="outros"/></cfif>

      <cfquery name="qVickyExistingDocument" datasource="runner_dba">
        SELECT id_vicky_documento,status,openai_file_id
        FROM tb_vicky_documento
        WHERE lower(sha256)=lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentSha#"/>)
        ORDER BY CASE WHEN status IN ('active','inactive','processing') THEN 0 ELSE 1 END,updated_at DESC,id_vicky_documento DESC
        LIMIT 1
      </cfquery>
      <cfif qVickyExistingDocument.recordCount AND listFindNoCase("active,inactive,processing",qVickyExistingDocument.status&"")>
        <cfset VARIABLES.skippedCount=VARIABLES.skippedCount+1/>
        <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=VARIABLES.clientFile,status="skipped",detail="O mesmo PDF já está cadastrado com status "&qVickyExistingDocument.status})/>
      <cfelse>
        <cfhttp method="post" url="https://api.openai.com/v1/files" result="vickyFileResponse" timeout="90" multipart="yes" throwonerror="false">
          <cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/>
          <cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/>
          <cfhttpparam type="formfield" name="purpose" value="assistants"/>
          <cfhttpparam type="file" name="file" file="#VARIABLES.vickyTempFile#" mimetype="application/pdf"/>
        </cfhttp>
        <cfset VARIABLES.fileHttp=val(left(vickyFileResponse.statusCode&"",3))/>
        <cfif VARIABLES.fileHttp LT 200 OR VARIABLES.fileHttp GTE 300><cfthrow type="Vicky.OpenAI" message="A OpenAI não aceitou o PDF (HTTP #VARIABLES.fileHttp#)."/></cfif>
        <cfset VARIABLES.filePayload=deserializeJSON(vickyFileResponse.fileContent)/>
        <cfif NOT structKeyExists(VARIABLES.filePayload,"id") OR NOT len(VARIABLES.filePayload.id&"")><cfthrow type="Vicky.OpenAI" message="A OpenAI não retornou o identificador do arquivo."/></cfif>
        <cfset VARIABLES.openAiFileId=VARIABLES.filePayload.id&""/>
        <cfset VARIABLES.attachPayload=structNew("ordered")/><cfset VARIABLES.attachPayload["file_id"]=VARIABLES.openAiFileId/>
        <cfhttp method="post" url="https://api.openai.com/v1/vector_stores/#urlEncodedFormat(VARIABLES.vectorStoreId)#/files" result="vickyAttachResponse" timeout="60" throwonerror="false">
          <cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/>
          <cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/>
          <cfhttpparam type="header" name="Content-Type" value="application/json"/>
          <cfhttpparam type="body" value="#serializeJSON(VARIABLES.attachPayload)#"/>
        </cfhttp>
        <cfset VARIABLES.attachHttp=val(left(vickyAttachResponse.statusCode&"",3))/>
        <cfif VARIABLES.attachHttp LT 200 OR VARIABLES.attachHttp GTE 300><cfthrow type="Vicky.OpenAI" message="O PDF foi enviado, mas não pôde ser anexado ao índice (HTTP #VARIABLES.attachHttp#)."/></cfif>

        <cfif qVickyExistingDocument.recordCount AND qVickyExistingDocument.status EQ "failed">
          <cfquery datasource="runner_dba">
            UPDATE tb_vicky_documento SET titulo=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentTitle#"/>,categoria=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentCategory#"/>,entidade=<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.document_issuer&''),160)#" null="#!len(trim(FORM.document_issuer&''))#"/>,versao=<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.document_version&''),80)#" null="#!len(trim(FORM.document_version&''))#"/>,vigencia=<cfqueryparam cfsqltype="cf_sql_date" value="#FORM.document_effective_date#" null="#!isDate(FORM.document_effective_date)#"/>,nome_arquivo=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.clientFile#"/>,tamanho_bytes=<cfqueryparam cfsqltype="cf_sql_bigint" value="#vickyUpload.fileSize#"/>,openai_file_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.openAiFileId#"/>,status='processing',id_operador=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,updated_at=now() WHERE id_vicky_documento=<cfqueryparam cfsqltype="cf_sql_bigint" value="#qVickyExistingDocument.id_vicky_documento#"/> AND status='failed'
          </cfquery>
          <cfset VARIABLES.replacedCount=VARIABLES.replacedCount+1/>
          <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=VARIABLES.clientFile,status="reprocessed",detail="Registro com falha atualizado; aguardando indexação"})/>
        <cfelse>
          <cfquery datasource="runner_dba">
            INSERT INTO tb_vicky_documento (titulo,categoria,entidade,versao,vigencia,nome_arquivo,tamanho_bytes,sha256,openai_file_id,status,id_operador) VALUES (<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentTitle#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentCategory#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.document_issuer&''),160)#" null="#!len(trim(FORM.document_issuer&''))#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.document_version&''),80)#" null="#!len(trim(FORM.document_version&''))#"/>,<cfqueryparam cfsqltype="cf_sql_date" value="#FORM.document_effective_date#" null="#!isDate(FORM.document_effective_date)#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.clientFile#"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#vickyUpload.fileSize#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentSha#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.openAiFileId#"/>,'processing',<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>)
          </cfquery>
          <cfset VARIABLES.uploadedCount=VARIABLES.uploadedCount+1/>
          <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=VARIABLES.clientFile,status="uploaded",detail="Novo documento; aguardando indexação"})/>
        </cfif>
      </cfif>
      <cfcatch>
        <cfset VARIABLES.failedCount=VARIABLES.failedCount+1/>
        <cfset VARIABLES.itemError=len(trim(cfcatch.message&""))?left(trim(cfcatch.message&""),240):"Falha inesperada no processamento."/>
        <cfset arrayAppend(VARIABLES.vickyBatchResults,{file=VARIABLES.clientFile,status="failed",detail=VARIABLES.itemError})/>
        <cfif len(VARIABLES.openAiFileId)>
          <cftry><cfhttp method="delete" url="https://api.openai.com/v1/files/#urlEncodedFormat(VARIABLES.openAiFileId)#" result="vickyCleanupResponse" timeout="20" throwonerror="false"><cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/></cfhttp><cfcatch></cfcatch></cftry>
        </cfif>
      </cfcatch>
      <cffinally><cfif fileExists(VARIABLES.vickyTempFile)><cffile action="delete" file="#VARIABLES.vickyTempFile#"/></cfif></cffinally>
    </cftry>
  </cfloop>
  <cfset VARIABLES.vickyMessage="#VARIABLES.uploadedCount# novo(s), #VARIABLES.replacedCount# substituído(s), #VARIABLES.skippedCount# ignorado(s) e #VARIABLES.failedCount# com falha. Os enviados podem ser verificados e ativados em um único clique."/>
  <cfset VARIABLES.vickyMessageType=VARIABLES.failedCount GT 0?(VARIABLES.uploadedCount+VARIABLES.replacedCount GT 0?"warning":"danger"):"success"/>
</cfif>
