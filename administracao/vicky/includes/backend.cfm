<cfparam name="URL.periodo" default="30"/><cfparam name="URL.execucao" default="0"/><cfparam name="URL.secao" default="configuracao"/>
<cfset VARIABLES.vickySection=listFindNoCase("configuracao,conhecimento,canais,interacoes,auditoria",URL.secao&"")?lCase(URL.secao&""):"configuracao"/>
<cfif isNumeric(URL.execucao) AND val(URL.execucao) GT 0><cfset VARIABLES.vickySection="auditoria"/></cfif>
<cfset VARIABLES.vickyMessage=""/><cfset VARIABLES.vickyMessageType="success"/><cfset VARIABLES.vickyPeriod=listFindNoCase("7,30,90",URL.periodo&"")?val(URL.periodo):30/><cfset VARIABLES.vickyReady=false/>
<cfset VARIABLES.vickyStartAt=dateAdd("d",-VARIABLES.vickyPeriod,now())/>
<cfset VARIABLES.vickyErrorStep="verificação da estrutura"/>
<cfset qVickyConfig=queryNew("")/><cfset qVickySummary=queryNew("")/><cfset qVickyTimeline=queryNew("")/><cfset qVickyTools=queryNew("")/><cfset qVickyRuns=queryNew("")/><cfset qVickyAudit=queryNew("")/><cfset qVickyInteraction=queryNew("")/><cfset qVickyDocuments=queryNew("")/><cfset qVickyManychatConfig=queryNew("")/><cfset qVickyManychatSummary=queryNew("")/><cfset qVickyManychatQueue=queryNew("")/>
<cfset qVickyProactiveRules=queryNew("")/><cfset qVickyProactiveTemplates=queryNew("")/><cfset qVickyProactiveSummary=queryNew("")/><cfset qVickyProactiveQueue=queryNew("")/><cfset qVickyProactivePreference=queryNew("")/>
<cftry>
  <cfquery name="qVickySchema" datasource="runner_dba">
    SELECT count(*) AS available_tables
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN (
        'tb_vicky_config',
        'tb_vicky_conversa',
        'tb_vicky_mensagem',
        'tb_vicky_execucao',
        'tb_vicky_tool_call',
        'tb_vicky_feedback',
        'tb_vicky_audit_access',
        'tb_vicky_knowledge_config',
        'tb_vicky_documento',
        'tb_vicky_manychat_config',
        'tb_vicky_manychat_link',
        'tb_vicky_manychat_queue',
        'tb_vicky_notificacao_regra',
        'tb_vicky_notificacao_template',
        'tb_vicky_notificacao_preferencia',
        'tb_vicky_notificacao_fila',
        'tb_vicky_notificacao_entrega'
      )
  </cfquery>
  <cfif val(qVickySchema.available_tables) LT 17>
    <cfthrow
      type="Vicky.SchemaMissing"
      message="Estrutura da Vicky ainda não foi instalada no banco."
      detail="Foram encontradas #val(qVickySchema.available_tables)# de 17 tabelas. Aplique também a migration de interações ativas no banco runner_dba."
    />
  </cfif>
  <cfif CGI.REQUEST_METHOD EQ "POST">
    <cfif NOT structKeyExists(CGI,"HTTP_ORIGIN") OR compareNoCase(reReplaceNoCase(CGI.HTTP_ORIGIN,"^https?://([^/]+).*$","\1"),CGI.HTTP_HOST) EQ 0>
      <cfparam name="FORM.action" default="save_config"/>
      <cfif FORM.action EQ "save_proactive_rule">
        <cfset VARIABLES.vickySection="interacoes"/><cfset VARIABLES.vickyErrorStep="configuração da interação ativa"/>
        <cfset VARIABLES.ruleCode=left(lCase(trim(FORM.rule_code&"")),80)/><cfset VARIABLES.allowedRules="agenda_added,agenda_d7,agenda_d1,result_published"/>
        <cfif NOT listFindNoCase(VARIABLES.allowedRules,VARIABLES.ruleCode)><cfthrow type="Vicky.InvalidRule" message="Regra inválida."/></cfif>
        <cfquery datasource="runner_dba">UPDATE tb_vicky_notificacao_regra SET enabled=(<cfqueryparam cfsqltype="cf_sql_integer" value="#structKeyExists(FORM,'rule_enabled')?1:0#"/> = 1),admin_only=(<cfqueryparam cfsqltype="cf_sql_integer" value="#structKeyExists(FORM,'admin_only')?1:0#"/> = 1),days_before=<cfqueryparam cfsqltype="cf_sql_integer" value="#min(max(val(FORM.days_before),0),365)#"/>,web_enabled=(<cfqueryparam cfsqltype="cf_sql_integer" value="#structKeyExists(FORM,'web_enabled')?1:0#"/> = 1),whatsapp_enabled=(<cfqueryparam cfsqltype="cf_sql_integer" value="#structKeyExists(FORM,'whatsapp_enabled')?1:0#"/> = 1),max_per_day=<cfqueryparam cfsqltype="cf_sql_integer" value="#min(max(val(FORM.max_per_day),1),20)#"/>,quiet_start=<cfqueryparam cfsqltype="cf_sql_time" value="#FORM.quiet_start#"/>,quiet_end=<cfqueryparam cfsqltype="cf_sql_time" value="#FORM.quiet_end#"/>,updated_by=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,updated_at=now() WHERE codigo=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.ruleCode#"/></cfquery>
        <cfquery datasource="runner_dba">UPDATE tb_vicky_notificacao_template t SET content=CASE WHEN channel='web' THEN <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#left(trim(FORM.web_content&''),2000)#"/> ELSE <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#left(trim(FORM.whatsapp_content&''),2000)#"/> END,provider_template_name=CASE WHEN channel='whatsapp' THEN <cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.provider_template_name&''),160)#" null="#!len(trim(FORM.provider_template_name&''))#"/> ELSE provider_template_name END,updated_by=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,updated_at=now() FROM tb_vicky_notificacao_regra r WHERE t.id_vicky_notificacao_regra=r.id_vicky_notificacao_regra AND r.codigo=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.ruleCode#"/> AND t.language='pt-BR' AND t.status='active'</cfquery>
        <cfset VARIABLES.vickyMessage="Regra e mensagens atualizadas."/>
      <cfelseif FORM.action EQ "save_proactive_preference">
        <cfset VARIABLES.vickySection="interacoes"/><cfset VARIABLES.vickyErrorStep="preferências do administrador de teste"/><cfset VARIABLES.testWhatsapp=structKeyExists(FORM,"test_whatsapp")/>
        <cfquery datasource="runner_dba">INSERT INTO tb_vicky_notificacao_preferencia (id_usuario,web_enabled,whatsapp_enabled,agenda_enabled,results_enabled,whatsapp_consented_at,whatsapp_consent_source,revoked_at) VALUES (<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,(<cfqueryparam cfsqltype="cf_sql_integer" value="#structKeyExists(FORM,'test_web')?1:0#"/> = 1),(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.testWhatsapp?1:0#"/> = 1),(<cfqueryparam cfsqltype="cf_sql_integer" value="#structKeyExists(FORM,'test_agenda')?1:0#"/> = 1),(<cfqueryparam cfsqltype="cf_sql_integer" value="#structKeyExists(FORM,'test_results')?1:0#"/> = 1),CASE WHEN <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.testWhatsapp?1:0#"/> = 1 THEN now() ELSE NULL END,'business_admin_test',NULL) ON CONFLICT (id_usuario) DO UPDATE SET web_enabled=EXCLUDED.web_enabled,whatsapp_enabled=EXCLUDED.whatsapp_enabled,agenda_enabled=EXCLUDED.agenda_enabled,results_enabled=EXCLUDED.results_enabled,whatsapp_consented_at=EXCLUDED.whatsapp_consented_at,whatsapp_consent_source=EXCLUDED.whatsapp_consent_source,revoked_at=NULL,updated_at=now()</cfquery>
        <cfset VARIABLES.vickyMessage="Preferências de teste atualizadas para o seu usuário."/>
      <cfelseif FORM.action EQ "save_manychat">
        <cfset VARIABLES.vickySection="canais"/><cfset VARIABLES.vickyErrorStep="configuração do Manychat"/>
        <cfset VARIABLES.manychatEnabled=structKeyExists(FORM,"manychat_enabled")/><cfset VARIABLES.manychatLabel=left(trim(FORM.account_label&""),120)/><cfset VARIABLES.manychatTrigger=left(trim(FORM.trigger_name&""),120)/><cfset VARIABLES.manychatAttempts=min(max(val(FORM.max_attempts),1),10)/>
        <cfif NOT len(VARIABLES.manychatLabel) OR NOT len(VARIABLES.manychatTrigger)><cfthrow type="Vicky.ManychatValidation" message="Nome da conta e trigger são obrigatórios."/></cfif>
        <cfquery datasource="runner_dba">UPDATE tb_vicky_manychat_config SET enabled=(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.manychatEnabled ? 1 : 0#"/> = 1),account_label=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.manychatLabel#"/>,trigger_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.manychatTrigger#"/>,max_attempts=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.manychatAttempts#"/>,updated_by=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,updated_at=now() WHERE id_config=1</cfquery>
        <cfset VARIABLES.vickyMessage="Configuração do canal atualizada. Segredos permanecem protegidos no ambiente do Road Runners."/>
      <cfelseif FORM.action EQ "upload_document">
        <cfset VARIABLES.vickySection="conhecimento"/>
        <cfset VARIABLES.vickyErrorStep="upload do documento"/>
        <cfparam name="FORM.document_title" default=""/><cfparam name="FORM.document_category" default=""/><cfparam name="FORM.document_issuer" default=""/><cfparam name="FORM.document_version" default=""/><cfparam name="FORM.document_effective_date" default=""/>
        <cfif NOT structKeyExists(APPLICATION,"vickyKnowledge") OR NOT APPLICATION.vickyKnowledge.configured><cfthrow type="Vicky.KnowledgeNotConfigured" message="OPENAI_API_KEY não configurada no Business."/></cfif>
        <cffile action="upload" filefield="document_file" destination="#getTempDirectory()#" nameconflict="makeunique" accept="application/pdf,.pdf" strict="false" result="vickyUpload"/>
        <cfset VARIABLES.vickyTempFile=vickyUpload.serverDirectory&"/"&vickyUpload.serverFile/>
        <cftry>
          <cfset VARIABLES.vickyPdfBinary=fileReadBinary(VARIABLES.vickyTempFile)/>
          <cfif lCase(vickyUpload.serverFileExt) NEQ "pdf" OR vickyUpload.fileSize GT 20971520 OR uCase(left(binaryEncode(VARIABLES.vickyPdfBinary,"hex"),8)) NEQ "25504446"><cfthrow type="Vicky.InvalidDocument" message="Envie um PDF válido de até 20 MB."/></cfif>
          <cfset VARIABLES.documentTitle=left(trim(FORM.document_title&""),240)/><cfset VARIABLES.documentCategory=left(trim(FORM.document_category&""),80)/>
          <cfif NOT len(VARIABLES.documentTitle) OR NOT len(VARIABLES.documentCategory)><cfthrow type="Vicky.InvalidDocument" message="Título e categoria são obrigatórios."/></cfif>
          <cfquery name="qVickyKnowledgeConfig" datasource="runner_dba">SELECT openai_vector_store_id FROM tb_vicky_knowledge_config WHERE id_config=1</cfquery>
          <cfset VARIABLES.vectorStoreId=qVickyKnowledgeConfig.recordCount?trim(qVickyKnowledgeConfig.openai_vector_store_id&""):""/>
          <cfif NOT len(VARIABLES.vectorStoreId)>
            <cfset VARIABLES.vectorStorePayload=structNew("ordered")/><cfset VARIABLES.vectorStorePayload["name"]="Vicky Pacer - Documentos Oficiais"/>
            <cfhttp method="post" url="https://api.openai.com/v1/vector_stores" result="vickyVectorResponse" timeout="30"><cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/><cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/><cfhttpparam type="header" name="Content-Type" value="application/json"/><cfhttpparam type="body" value="#serializeJSON(VARIABLES.vectorStorePayload)#"/></cfhttp>
            <cfif val(left(vickyVectorResponse.statusCode&"",3)) LT 200 OR val(left(vickyVectorResponse.statusCode&"",3)) GTE 300><cfset VARIABLES.openAiStatus=val(left(vickyVectorResponse.statusCode&"",3))/><cfset VARIABLES.openAiCode="unknown"/><cftry><cfset VARIABLES.openAiPayload=deserializeJSON(vickyVectorResponse.fileContent)/><cfif structKeyExists(VARIABLES.openAiPayload,"error") AND isStruct(VARIABLES.openAiPayload.error) AND structKeyExists(VARIABLES.openAiPayload.error,"code") AND NOT isNull(VARIABLES.openAiPayload.error.code)><cfset VARIABLES.openAiCode=reReplace(lCase(VARIABLES.openAiPayload.error.code&""),"[^a-z0-9_-]+","_","all")/></cfif><cfcatch></cfcatch></cftry><cfthrow type="Vicky.OpenAI" message="Não foi possível criar o índice documental (HTTP #VARIABLES.openAiStatus#, código #left(VARIABLES.openAiCode,40)#)."/></cfif>
            <cfset VARIABLES.vectorStoreId=deserializeJSON(vickyVectorResponse.fileContent).id&""/>
            <cfquery datasource="runner_dba">UPDATE tb_vicky_knowledge_config SET openai_vector_store_id=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.vectorStoreId#"/>,updated_at=now() WHERE id_config=1</cfquery>
          </cfif>
          <cfhttp method="post" url="https://api.openai.com/v1/files" result="vickyFileResponse" timeout="60" multipart="yes"><cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/><cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/><cfhttpparam type="formfield" name="purpose" value="assistants"/><cfhttpparam type="file" name="file" file="#VARIABLES.vickyTempFile#" mimetype="application/pdf"/></cfhttp>
          <cfif val(left(vickyFileResponse.statusCode&"",3)) LT 200 OR val(left(vickyFileResponse.statusCode&"",3)) GTE 300><cfthrow type="Vicky.OpenAI" message="A OpenAI não aceitou o PDF."/></cfif>
          <cfset VARIABLES.openAiFileId=deserializeJSON(vickyFileResponse.fileContent).id&""/>
          <cfset VARIABLES.attachPayload=structNew("ordered")/><cfset VARIABLES.attachPayload["file_id"]=VARIABLES.openAiFileId/>
          <cfhttp method="post" url="https://api.openai.com/v1/vector_stores/#urlEncodedFormat(VARIABLES.vectorStoreId)#/files" result="vickyAttachResponse" timeout="30"><cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/><cfhttpparam type="header" name="OpenAI-Beta" value="assistants=v2"/><cfhttpparam type="header" name="Content-Type" value="application/json"/><cfhttpparam type="body" value="#serializeJSON(VARIABLES.attachPayload)#"/></cfhttp>
          <cfif val(left(vickyAttachResponse.statusCode&"",3)) LT 200 OR val(left(vickyAttachResponse.statusCode&"",3)) GTE 300><cfthrow type="Vicky.OpenAI" message="O PDF foi enviado, mas não pôde ser anexado ao índice."/></cfif>
          <cfquery datasource="runner_dba">INSERT INTO tb_vicky_documento (titulo,categoria,entidade,versao,vigencia,nome_arquivo,tamanho_bytes,sha256,openai_file_id,status,id_operador) VALUES (<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentTitle#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentCategory#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.document_issuer&''),160)#" null="#!len(trim(FORM.document_issuer&''))#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(trim(FORM.document_version&''),80)#" null="#!len(trim(FORM.document_version&''))#"/>,<cfqueryparam cfsqltype="cf_sql_date" value="#FORM.document_effective_date#" null="#!isDate(FORM.document_effective_date)#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#left(vickyUpload.clientFile,255)#"/>,<cfqueryparam cfsqltype="cf_sql_bigint" value="#vickyUpload.fileSize#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(VARIABLES.vickyPdfBinary,'SHA-256')#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.openAiFileId#"/>,'processing',<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>)</cfquery>
          <cfset VARIABLES.vickyMessage="PDF enviado. Use “Verificar processamento” antes de ativá-lo para a Vicky."/>
          <cffinally><cfif fileExists(VARIABLES.vickyTempFile)><cffile action="delete" file="#VARIABLES.vickyTempFile#"/></cfif></cffinally>
        </cftry>
      <cfelseif FORM.action EQ "document_status">
        <cfset VARIABLES.vickySection="conhecimento"/>
        <cfset VARIABLES.vickyErrorStep="atualização do documento"/><cfset VARIABLES.documentId=val(FORM.document_id)/><cfset VARIABLES.documentStatus=listFindNoCase("active,inactive",FORM.document_status&"")?lCase(FORM.document_status):"inactive"/>
        <cfquery datasource="runner_dba">UPDATE tb_vicky_documento SET status=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.documentStatus#"/>,updated_at=now() WHERE id_vicky_documento=<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.documentId#"/> AND status IN ('active','inactive')</cfquery><cfset VARIABLES.vickyMessage="Status do documento atualizado."/>
      <cfelseif FORM.action EQ "refresh_document">
        <cfset VARIABLES.vickySection="conhecimento"/>
        <cfset VARIABLES.vickyErrorStep="verificação do processamento"/><cfquery name="qVickyRefresh" datasource="runner_dba">SELECT d.id_vicky_documento,d.openai_file_id,k.openai_vector_store_id FROM tb_vicky_documento d CROSS JOIN tb_vicky_knowledge_config k WHERE d.id_vicky_documento=<cfqueryparam cfsqltype="cf_sql_bigint" value="#val(FORM.document_id)#"/> LIMIT 1</cfquery>
        <cfif qVickyRefresh.recordCount><cfhttp method="get" url="https://api.openai.com/v1/vector_stores/#urlEncodedFormat(qVickyRefresh.openai_vector_store_id)#/files/#urlEncodedFormat(qVickyRefresh.openai_file_id)#" result="vickyStatusResponse" timeout="30"><cfhttpparam type="header" name="Authorization" value="Bearer #APPLICATION.vickyKnowledge.apiKey#"/></cfhttp><cfset VARIABLES.remoteStatus=val(left(vickyStatusResponse.statusCode&"",3)) GTE 200 AND val(left(vickyStatusResponse.statusCode&"",3)) LT 300?lCase(deserializeJSON(vickyStatusResponse.fileContent).status&""):"failed"/><cfset VARIABLES.localStatus=VARIABLES.remoteStatus EQ "completed"?"inactive":(VARIABLES.remoteStatus EQ "failed"?"failed":"processing")/><cfquery datasource="runner_dba">UPDATE tb_vicky_documento SET status=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.localStatus#"/>,updated_at=now() WHERE id_vicky_documento=<cfqueryparam cfsqltype="cf_sql_bigint" value="#qVickyRefresh.id_vicky_documento#"/></cfquery><cfset VARIABLES.vickyMessage="Processamento verificado: "&VARIABLES.localStatus&"."/></cfif>
      <cfelse>
        <cfset VARIABLES.vickySection="configuracao"/>
        <cfset VARIABLES.vickyErrorStep="atualização da configuração"/>
        <cfset VARIABLES.enabled=structKeyExists(FORM,"enabled")/><cfset VARIABLES.displayName=left(trim(FORM.display_name&""),80)/><cfset VARIABLES.greeting=left(trim(FORM.greeting&""),500)/><cfset VARIABLES.model=left(trim(FORM.model&""),80)/><cfset VARIABLES.instructions=left(trim(FORM.system_instructions&""),12000)/>
        <cfset VARIABLES.maxTokens=min(max(val(FORM.max_output_tokens),200),4000)/><cfset VARIABLES.hourLimit=min(max(val(FORM.max_messages_per_hour),1),300)/><cfset VARIABLES.retention=min(max(val(FORM.retention_days),1),730)/>
        <cfquery datasource="runner_dba">UPDATE tb_vicky_config SET enabled=(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.enabled ? 1 : 0#"/> = 1),display_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.displayName#"/>,greeting=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.greeting#"/>,model=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.model#"/>,system_instructions=<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.instructions#"/>,max_output_tokens=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.maxTokens#"/>,max_messages_per_hour=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.hourLimit#"/>,retention_days=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.retention#"/>,updated_by=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,updated_at=now() WHERE id_config=1</cfquery>
        <cfset VARIABLES.vickyMessage="Configuração atualizada. O kill switch passa a valer imediatamente no próximo request."/>
      </cfif>
    <cfelse><cfthrow type="Vicky.InvalidOrigin" message="Origem inválida"/></cfif>
  </cfif>
  <cfset VARIABLES.vickyErrorStep="leitura da configuração"/>
  <cfquery name="qVickyConfig" datasource="runner_dba">SELECT * FROM tb_vicky_config WHERE id_config=1</cfquery>
  <cfif VARIABLES.vickySection EQ "canais">
    <cfset VARIABLES.vickyErrorStep="leitura do canal Manychat"/>
    <cfquery name="qVickyManychatConfig" datasource="runner_dba">SELECT * FROM tb_vicky_manychat_config WHERE id_config=1</cfquery>
    <cfquery name="qVickyManychatSummary" datasource="runner_dba">SELECT count(*) AS total,count(*) FILTER (WHERE status='active') AS active,count(*) FILTER (WHERE status='pending') AS pending FROM tb_vicky_manychat_link</cfquery>
    <cfquery name="qVickyManychatQueue" datasource="runner_dba">SELECT id_vicky_manychat_queue,channel,subscriber_id,status,attempts,error_code,created_at,completed_at FROM tb_vicky_manychat_queue ORDER BY id_vicky_manychat_queue DESC LIMIT 100</cfquery>
  </cfif>
  <cfif VARIABLES.vickySection EQ "conhecimento">
    <cfset VARIABLES.vickyErrorStep="listagem da base de conhecimento"/>
    <cfquery name="qVickyDocuments" datasource="runner_dba">SELECT * FROM tb_vicky_documento ORDER BY updated_at DESC,id_vicky_documento DESC</cfquery>
  </cfif>
  <cfif VARIABLES.vickySection EQ "interacoes">
    <cfset VARIABLES.vickyErrorStep="leitura das regras de interação"/>
    <cfquery name="qVickyProactiveRules" datasource="runner_dba">SELECT r.*,coalesce(s.total,0) AS total,coalesce(s.completed,0) AS completed,coalesce(s.failed,0) AS failed FROM tb_vicky_notificacao_regra r LEFT JOIN (SELECT id_vicky_notificacao_regra,count(*) AS total,count(*) FILTER (WHERE status='completed') AS completed,count(*) FILTER (WHERE status IN ('failed','dead_letter')) AS failed FROM tb_vicky_notificacao_fila WHERE created_at>=now()-interval '30 days' GROUP BY id_vicky_notificacao_regra) s USING (id_vicky_notificacao_regra) WHERE r.codigo IN ('agenda_added','agenda_d7','agenda_d1','result_published') ORDER BY CASE r.codigo WHEN 'agenda_added' THEN 1 WHEN 'agenda_d7' THEN 2 WHEN 'agenda_d1' THEN 3 ELSE 4 END</cfquery>
    <cfset VARIABLES.vickyErrorStep="leitura das mensagens das regras"/>
    <cfquery name="qVickyProactiveTemplates" datasource="runner_dba">SELECT t.*,r.codigo FROM tb_vicky_notificacao_template t INNER JOIN tb_vicky_notificacao_regra r ON r.id_vicky_notificacao_regra=t.id_vicky_notificacao_regra WHERE t.status='active' ORDER BY r.codigo,t.channel</cfquery>
    <cfset VARIABLES.vickyErrorStep="leitura das preferências de interação"/>
    <cfquery name="qVickyProactivePreference" datasource="runner_dba">SELECT * FROM tb_vicky_notificacao_preferencia WHERE id_usuario=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/></cfquery>
    <cfset VARIABLES.vickyErrorStep="resumo das interações ativas"/>
    <cfquery name="qVickyProactiveSummary" datasource="runner_dba">SELECT count(*) AS total,count(*) FILTER (WHERE status='completed') AS completed,count(*) FILTER (WHERE status IN ('failed','dead_letter')) AS failed,count(*) FILTER (WHERE status='queued') AS queued,count(DISTINCT id_usuario) AS users FROM tb_vicky_notificacao_fila WHERE created_at>=now()-interval '30 days'</cfquery>
    <cfset VARIABLES.vickyErrorStep="leitura da fila de interações"/>
    <cfquery name="qVickyProactiveQueue" datasource="runner_dba">SELECT f.*,r.nome,u.name AS usuario_nome FROM tb_vicky_notificacao_fila f INNER JOIN tb_vicky_notificacao_regra r ON r.id_vicky_notificacao_regra=f.id_vicky_notificacao_regra INNER JOIN tb_usuarios u ON u.id=f.id_usuario ORDER BY f.id_vicky_notificacao_fila DESC LIMIT 100</cfquery>
  </cfif>
  <cfif listFindNoCase("configuracao,auditoria",VARIABLES.vickySection)>
  <cfset VARIABLES.vickyErrorStep="resumo de métricas"/>
  <cfquery name="qVickySummary" datasource="runner_dba">
    SELECT count(*) AS runs,
           count(DISTINCT id_usuario) AS users,
           sum(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed,
           sum(CASE WHEN status <> 'completed' THEN 1 ELSE 0 END) AS fallbacks,
           coalesce(sum(input_tokens), 0) AS input_tokens,
           coalesce(sum(output_tokens), 0) AS output_tokens,
           coalesce(sum(tool_calls), 0) AS tool_calls,
           coalesce(percentile_cont(0.5) WITHIN GROUP (ORDER BY latency_ms), 0) AS median_latency_ms
    FROM tb_vicky_execucao
    WHERE created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.vickyStartAt#"/>
  </cfquery>
  <cfset VARIABLES.vickyErrorStep="série temporal"/>
  <cfquery name="qVickyTimeline" datasource="runner_dba">
    SELECT CAST(date_trunc('day', created_at) AS date) AS day,
           count(*) AS runs,
           count(DISTINCT id_usuario) AS users,
           sum(CASE WHEN status <> 'completed' THEN 1 ELSE 0 END) AS fallbacks
    FROM tb_vicky_execucao
    WHERE created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.vickyStartAt#"/>
    GROUP BY 1
    ORDER BY 1
  </cfquery>
  <cfset VARIABLES.vickyErrorStep="métricas de ferramentas"/>
  <cfquery name="qVickyTools" datasource="runner_dba">
    SELECT tool_name,
           count(*) AS calls,
           sum(CASE WHEN status <> 'completed' THEN 1 ELSE 0 END) AS failures,
           coalesce(percentile_cont(0.5) WITHIN GROUP (ORDER BY latency_ms), 0) AS median_ms
    FROM tb_vicky_tool_call
    WHERE created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.vickyStartAt#"/>
    GROUP BY tool_name
    ORDER BY calls DESC
  </cfquery>
  <cfset VARIABLES.vickyErrorStep="listagem de execuções"/>
  <cfquery name="qVickyRuns" datasource="runner_dba">
    SELECT e.id_vicky_execucao,
           e.created_at,
           e.id_usuario,
           coalesce(nullif(trim(p.nome), ''), u.name, 'Usuário ' || CAST(e.id_usuario AS varchar)) AS user_name,
           e.status,
           e.model,
           e.tool_calls,
           e.input_tokens,
           e.output_tokens,
           e.latency_ms,
           e.error_code
    FROM tb_vicky_execucao e
    LEFT JOIN tb_usuarios u ON u.id = e.id_usuario
    LEFT JOIN LATERAL (
      SELECT pg.nome
      FROM tb_paginas_usuarios pu
      INNER JOIN tb_paginas pg ON pg.id_pagina = pu.id_pagina
      WHERE pu.id_usuario = e.id_usuario
        AND pg.tag_prefix = 'atleta'
      LIMIT 1
    ) p ON true
    WHERE e.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.vickyStartAt#"/>
    ORDER BY e.created_at DESC
    LIMIT 100
  </cfquery>
  <cfif isNumeric(URL.execucao) AND val(URL.execucao) GT 0>
    <cfquery datasource="runner_dba">INSERT INTO tb_vicky_audit_access (id_vicky_execucao,id_operador,reason) SELECT id_vicky_execucao,<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,'business_admin_review' FROM tb_vicky_execucao WHERE id_vicky_execucao=<cfqueryparam cfsqltype="cf_sql_bigint" value="#val(URL.execucao)#"/></cfquery>
    <cfquery name="qVickyAudit" datasource="runner_dba">SELECT t.tool_name,t.status,t.arguments_summary,t.result_summary,t.latency_ms,t.error_code,t.created_at FROM tb_vicky_tool_call t JOIN tb_vicky_execucao e ON e.id_vicky_execucao=t.id_vicky_execucao WHERE t.id_vicky_execucao=<cfqueryparam cfsqltype="cf_sql_bigint" value="#val(URL.execucao)#"/> ORDER BY t.id_vicky_tool_call</cfquery>
    <cfquery name="qVickyInteraction" datasource="runner_dba">SELECT um.content user_content,am.content assistant_content,um.created_at user_created_at,am.created_at assistant_created_at FROM tb_vicky_execucao e LEFT JOIN tb_vicky_mensagem um ON um.id_vicky_mensagem=e.id_mensagem_usuario LEFT JOIN tb_vicky_mensagem am ON am.id_vicky_mensagem=e.id_mensagem_assistente WHERE e.id_vicky_execucao=<cfqueryparam cfsqltype="cf_sql_bigint" value="#val(URL.execucao)#"/> LIMIT 1</cfquery>
  </cfif>
  </cfif>
  <cfset VARIABLES.vickyReady=true/>
  <cfcatch>
    <cfset VARIABLES.vickyMessageType="danger"/>
    <cfif findNoCase("Vicky.SchemaMissing",cfcatch.type)>
      <cfset VARIABLES.vickyMessage=cfcatch.message&" "&cfcatch.detail/>
    <cfelse>
      <cfset VARIABLES.vickyMessage="Gerenciador indisponível: "&cfcatch.message&" Etapa: "&VARIABLES.vickyErrorStep/>
    </cfif>
    <cfset VARIABLES.vickyReady=false/>
  </cfcatch>
</cftry>
