<cfparam name="URL.periodo" default="30"/><cfparam name="URL.execucao" default="0"/><cfparam name="URL.secao" default="configuracao"/>
<cfset VARIABLES.vickySection=listFindNoCase("configuracao,conhecimento,canais,interacoes,auditoria",URL.secao&"")?lCase(URL.secao&""):"configuracao"/>
<cfif isNumeric(URL.execucao) AND val(URL.execucao) GT 0><cfset VARIABLES.vickySection="auditoria"/></cfif>
<cfset VARIABLES.vickyMessage=""/><cfset VARIABLES.vickyMessageType="success"/><cfset VARIABLES.vickyPeriod=listFindNoCase("7,30,90",URL.periodo&"")?val(URL.periodo):30/><cfset VARIABLES.vickyReady=false/><cfset VARIABLES.vickyBatchResults=[]/>
<cfset VARIABLES.vickyStartAt=dateAdd("d",-VARIABLES.vickyPeriod,now())/>
<cfif NOT structKeyExists(SESSION,"vickyAdminCsrfToken") OR NOT len(trim(SESSION.vickyAdminCsrfToken&""))><cfset SESSION.vickyAdminCsrfToken=lCase(hash(createUUID()&":"&createUUID()&":"&getTickCount(),"SHA-256"))/></cfif>
<cfset VARIABLES.vickyAdminCsrfToken=SESSION.vickyAdminCsrfToken/>
<cfset VARIABLES.vickyErrorStep="verificação da estrutura"/>
<cfset qVickyConfig=queryNew("")/><cfset qVickySummary=queryNew("")/><cfset qVickyTimeline=queryNew("")/><cfset qVickyTools=queryNew("")/><cfset qVickyRuns=queryNew("")/><cfset qVickyAudit=queryNew("")/><cfset qVickyInteraction=queryNew("")/><cfset qVickyDocuments=queryNew("")/><cfset qVickyDocumentSummary=queryNew("")/><cfset qVickyManychatConfig=queryNew("")/><cfset qVickyManychatSummary=queryNew("")/><cfset qVickyManychatQueue=queryNew("")/>
<cfset qVickyMetaConfig=queryNew("")/><cfset qVickyMetaSummary=queryNew("")/><cfset qVickyMetaQueue=queryNew("")/><cfset qVickyMetaAudit=queryNew("")/><cfset VARIABLES.vickyMetaSchemaReady=false/>
<cfset qVickyInstagramConfig=queryNew("")/><cfset qVickyInstagramSummary=queryNew("")/><cfset qVickyInstagramQueue=queryNew("")/><cfset qVickyInstagramAudit=queryNew("")/><cfset VARIABLES.vickyInstagramSchemaReady=false/>
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
      <cfelseif FORM.action EQ "save_meta_whatsapp">
        <cfset VARIABLES.vickySection="canais"/><cfset VARIABLES.vickyErrorStep="configuração do WhatsApp Cloud API"/>
        <cfif NOT structKeyExists(FORM,"csrf_token") OR compare(FORM.csrf_token&"",VARIABLES.vickyAdminCsrfToken) NEQ 0><cfthrow type="Vicky.InvalidCsrf" message="A sessão de segurança expirou. Recarregue a página e tente novamente."/></cfif>
        <cfset VARIABLES.metaMode=listFindNoCase("disabled,pilot,public",FORM.channel_mode&"")?lCase(FORM.channel_mode&""):"pilot"/>
        <cfset VARIABLES.metaEnabled=VARIABLES.metaMode NEQ "disabled"/><cfset VARIABLES.metaPilotOnly=VARIABLES.metaMode NEQ "public"/>
        <cfset VARIABLES.metaLabel=left(trim(FORM.account_label&""),120)/><cfset VARIABLES.metaAttempts=min(max(val(FORM.max_attempts),1),10)/>
        <cfset VARIABLES.metaHourlyLimit=min(max(val(FORM.max_messages_per_hour),1),300)/><cfset VARIABLES.metaRetention=min(max(val(FORM.retention_days),1),730)/>
        <cfif NOT len(VARIABLES.metaLabel)><cfthrow type="Vicky.MetaValidation" message="O nome do canal é obrigatório."/></cfif>
        <cfif VARIABLES.metaMode EQ "public" AND NOT structKeyExists(FORM,"public_confirmed")><cfthrow type="Vicky.MetaValidation" message="Confirme que o piloto foi validado antes de liberar o canal ao público."/></cfif>
        <cfquery name="qVickyMetaAgentGate" datasource="runner_dba">SELECT enabled,beta_only,authenticated_only FROM tb_vicky_config WHERE id_config=1</cfquery>
        <cfif VARIABLES.metaMode EQ "public" AND (NOT qVickyMetaAgentGate.recordCount OR NOT qVickyMetaAgentGate.enabled OR qVickyMetaAgentGate.beta_only OR NOT qVickyMetaAgentGate.authenticated_only)><cfthrow type="Vicky.MetaValidation" message="Para liberar o WhatsApp ao público, habilite a Vicky em produção e mantenha o acesso restrito a usuários autenticados."/></cfif>
        <cftransaction>
          <cfquery name="qVickyMetaPrevious" datasource="runner_dba">SELECT enabled,pilot_only,account_label,max_attempts,max_messages_per_hour,retention_days FROM tb_vicky_channel_config WHERE provider='meta_cloud' AND channel='whatsapp' LIMIT 1 FOR UPDATE</cfquery>
          <cfif NOT qVickyMetaPrevious.recordCount><cfthrow type="Vicky.MetaMissing" message="A configuração do WhatsApp Cloud API não foi instalada."/></cfif>
          <cfset VARIABLES.metaPreviousMode=NOT qVickyMetaPrevious.enabled?"disabled":(qVickyMetaPrevious.pilot_only?"pilot":"public")/>
          <cfset VARIABLES.metaPreviousConfig={enabled=qVickyMetaPrevious.enabled?true:false,pilotOnly=qVickyMetaPrevious.pilot_only?true:false,accountLabel=qVickyMetaPrevious.account_label&"",maxAttempts=val(qVickyMetaPrevious.max_attempts),maxMessagesPerHour=val(qVickyMetaPrevious.max_messages_per_hour),retentionDays=val(qVickyMetaPrevious.retention_days)}/>
          <cfset VARIABLES.metaNewConfig={enabled=VARIABLES.metaEnabled,pilotOnly=VARIABLES.metaPilotOnly,accountLabel=VARIABLES.metaLabel,maxAttempts=VARIABLES.metaAttempts,maxMessagesPerHour=VARIABLES.metaHourlyLimit,retentionDays=VARIABLES.metaRetention}/>
          <cfquery datasource="runner_dba">UPDATE tb_vicky_channel_config SET enabled=(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.metaEnabled?1:0#"/> = 1),pilot_only=(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.metaPilotOnly?1:0#"/> = 1),account_label=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.metaLabel#"/>,max_attempts=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.metaAttempts#"/>,max_messages_per_hour=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.metaHourlyLimit#"/>,retention_days=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.metaRetention#"/>,updated_by=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,updated_at=now() WHERE provider='meta_cloud' AND channel='whatsapp'</cfquery>
          <cfquery datasource="runner_dba">INSERT INTO tb_vicky_channel_config_audit (provider,channel,previous_mode,new_mode,previous_config,new_config,id_operador) VALUES ('meta_cloud','whatsapp',<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.metaPreviousMode#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.metaMode#"/>,CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.metaPreviousConfig)#"/> AS jsonb),CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.metaNewConfig)#"/> AS jsonb),<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>)</cfquery>
        </cftransaction>
        <cfset VARIABLES.vickyMessage="Canal direto da Meta atualizado para o modo "&(VARIABLES.metaMode EQ "public"?"Público":(VARIABLES.metaMode EQ "pilot"?"Piloto":"Desativado"))&". A alteração foi registrada na auditoria."/>
      <cfelseif FORM.action EQ "save_meta_instagram">
        <cfset VARIABLES.vickySection="canais"/><cfset VARIABLES.vickyErrorStep="configuração do Instagram Messaging API"/>
        <cfif NOT structKeyExists(FORM,"csrf_token") OR compare(FORM.csrf_token&"",VARIABLES.vickyAdminCsrfToken) NEQ 0><cfthrow type="Vicky.InvalidCsrf" message="A sessão de segurança expirou. Recarregue a página e tente novamente."/></cfif>
        <cfset VARIABLES.instagramMode=listFindNoCase("disabled,pilot,public",FORM.channel_mode&"")?lCase(FORM.channel_mode&""):"pilot"/>
        <cfset VARIABLES.instagramEnabled=VARIABLES.instagramMode NEQ "disabled"/><cfset VARIABLES.instagramPilotOnly=VARIABLES.instagramMode NEQ "public"/>
        <cfset VARIABLES.instagramLabel=left(trim(FORM.account_label&""),120)/><cfset VARIABLES.instagramAttempts=min(max(val(FORM.max_attempts),1),10)/>
        <cfset VARIABLES.instagramHourlyLimit=min(max(val(FORM.max_messages_per_hour),1),300)/><cfset VARIABLES.instagramRetention=min(max(val(FORM.retention_days),1),730)/>
        <cfif NOT len(VARIABLES.instagramLabel)><cfthrow type="Vicky.InstagramValidation" message="O nome do canal é obrigatório."/></cfif>
        <cfif VARIABLES.instagramMode EQ "public" AND NOT structKeyExists(FORM,"public_confirmed")><cfthrow type="Vicky.InstagramValidation" message="Confirme que o piloto foi validado antes de liberar o Instagram ao público."/></cfif>
        <cfquery name="qVickyInstagramAgentGate" datasource="runner_dba">SELECT enabled,beta_only,authenticated_only FROM tb_vicky_config WHERE id_config=1</cfquery>
        <cfif VARIABLES.instagramMode EQ "public" AND (NOT qVickyInstagramAgentGate.recordCount OR NOT qVickyInstagramAgentGate.enabled OR qVickyInstagramAgentGate.beta_only OR NOT qVickyInstagramAgentGate.authenticated_only)><cfthrow type="Vicky.InstagramValidation" message="Para liberar o Instagram ao público, habilite a Vicky em produção e mantenha o acesso restrito a usuários autenticados."/></cfif>
        <cftransaction>
          <cfquery name="qVickyInstagramPrevious" datasource="runner_dba">SELECT enabled,pilot_only,account_label,max_attempts,max_messages_per_hour,retention_days FROM tb_vicky_channel_config WHERE provider='meta_instagram' AND channel='instagram' LIMIT 1 FOR UPDATE</cfquery>
          <cfif NOT qVickyInstagramPrevious.recordCount><cfthrow type="Vicky.InstagramMissing" message="A configuração do Instagram Messaging API não foi instalada."/></cfif>
          <cfset VARIABLES.instagramPreviousMode=NOT qVickyInstagramPrevious.enabled?"disabled":(qVickyInstagramPrevious.pilot_only?"pilot":"public")/>
          <cfset VARIABLES.instagramPreviousConfig={enabled=qVickyInstagramPrevious.enabled?true:false,pilotOnly=qVickyInstagramPrevious.pilot_only?true:false,accountLabel=qVickyInstagramPrevious.account_label&"",maxAttempts=val(qVickyInstagramPrevious.max_attempts),maxMessagesPerHour=val(qVickyInstagramPrevious.max_messages_per_hour),retentionDays=val(qVickyInstagramPrevious.retention_days)}/>
          <cfset VARIABLES.instagramNewConfig={enabled=VARIABLES.instagramEnabled,pilotOnly=VARIABLES.instagramPilotOnly,accountLabel=VARIABLES.instagramLabel,maxAttempts=VARIABLES.instagramAttempts,maxMessagesPerHour=VARIABLES.instagramHourlyLimit,retentionDays=VARIABLES.instagramRetention}/>
          <cfquery datasource="runner_dba">UPDATE tb_vicky_channel_config SET enabled=(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.instagramEnabled?1:0#"/> = 1),pilot_only=(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.instagramPilotOnly?1:0#"/> = 1),account_label=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.instagramLabel#"/>,max_attempts=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.instagramAttempts#"/>,max_messages_per_hour=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.instagramHourlyLimit#"/>,retention_days=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.instagramRetention#"/>,updated_by=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,updated_at=now() WHERE provider='meta_instagram' AND channel='instagram'</cfquery>
          <cfquery datasource="runner_dba">INSERT INTO tb_vicky_channel_config_audit (provider,channel,previous_mode,new_mode,previous_config,new_config,id_operador) VALUES ('meta_instagram','instagram',<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.instagramPreviousMode#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.instagramMode#"/>,CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.instagramPreviousConfig)#"/> AS jsonb),CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.instagramNewConfig)#"/> AS jsonb),<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>)</cfquery>
        </cftransaction>
        <cfset VARIABLES.vickyMessage="Canal Instagram atualizado para o modo "&(VARIABLES.instagramMode EQ "public"?"Público":(VARIABLES.instagramMode EQ "pilot"?"Piloto":"Desativado"))&". A alteração foi registrada na auditoria."/>
      <cfelseif FORM.action EQ "save_manychat">
        <cfset VARIABLES.vickySection="canais"/><cfset VARIABLES.vickyErrorStep="configuração do Manychat"/>
        <cfset VARIABLES.manychatEnabled=structKeyExists(FORM,"manychat_enabled")/><cfset VARIABLES.manychatLabel=left(trim(FORM.account_label&""),120)/><cfset VARIABLES.manychatTrigger=left(trim(FORM.trigger_name&""),120)/><cfset VARIABLES.manychatAttempts=min(max(val(FORM.max_attempts),1),10)/>
        <cfif NOT len(VARIABLES.manychatLabel) OR NOT len(VARIABLES.manychatTrigger)><cfthrow type="Vicky.ManychatValidation" message="Nome da conta e trigger são obrigatórios."/></cfif>
        <cfquery datasource="runner_dba">UPDATE tb_vicky_manychat_config SET enabled=(<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.manychatEnabled ? 1 : 0#"/> = 1),account_label=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.manychatLabel#"/>,trigger_name=<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.manychatTrigger#"/>,max_attempts=<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.manychatAttempts#"/>,updated_by=<cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>,updated_at=now() WHERE id_config=1</cfquery>
        <cfset VARIABLES.vickyMessage="Configuração do canal atualizada. Segredos permanecem protegidos no ambiente do Road Runners."/>
      <cfelseif listFindNoCase("upload_documents_batch,refresh_documents_batch",FORM.action&"")>
        <cfinclude template="knowledge_batch.cfm"/>
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
    <cfset VARIABLES.vickyErrorStep="verificação do canal Meta"/>
    <cfquery name="qVickyMetaSchema" datasource="runner_dba">SELECT (SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('tb_vicky_channel_config','tb_vicky_channel_link','tb_vicky_channel_queue','tb_vicky_channel_message','tb_vicky_channel_config_audit','tb_vicky_channel_maintenance')) AS tables_ready,(SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_vicky_channel_config' AND column_name IN ('max_messages_per_hour','retention_days')) AS columns_ready</cfquery>
    <cfset VARIABLES.vickyMetaSchemaReady=val(qVickyMetaSchema.tables_ready) EQ 6 AND val(qVickyMetaSchema.columns_ready) EQ 2/>
    <cfif VARIABLES.vickyMetaSchemaReady>
      <cfset VARIABLES.vickyErrorStep="leitura do canal Meta"/>
      <cfquery name="qVickyMetaConfig" datasource="runner_dba">SELECT *,CASE WHEN NOT enabled THEN 'disabled' WHEN pilot_only THEN 'pilot' ELSE 'public' END AS channel_mode FROM tb_vicky_channel_config WHERE provider='meta_cloud' AND channel='whatsapp' LIMIT 1</cfquery>
      <cfquery name="qVickyMetaSummary" datasource="runner_dba">SELECT count(*) AS total,count(*) FILTER (WHERE status='active') AS active,count(*) FILTER (WHERE status='pending') AS pending,count(*) FILTER (WHERE status='revoked') AS revoked FROM tb_vicky_channel_link WHERE provider='meta_cloud' AND channel='whatsapp'</cfquery>
      <cfquery name="qVickyMetaQueue" datasource="runner_dba">SELECT id_vicky_channel_queue,RIGHT(external_contact_id,6) AS contact_suffix,status,attempts,error_code,created_at,completed_at FROM tb_vicky_channel_queue WHERE provider='meta_cloud' AND channel='whatsapp' ORDER BY id_vicky_channel_queue DESC LIMIT 100</cfquery>
      <cfquery name="qVickyMetaAudit" datasource="runner_dba">SELECT a.*,u.name AS operator_name FROM tb_vicky_channel_config_audit a LEFT JOIN tb_usuarios u ON u.id=a.id_operador WHERE a.provider='meta_cloud' AND a.channel='whatsapp' ORDER BY a.id_vicky_channel_config_audit DESC LIMIT 20</cfquery>
      <cfset VARIABLES.vickyErrorStep="leitura do canal Instagram"/>
      <cfquery name="qVickyInstagramConfig" datasource="runner_dba">SELECT *,CASE WHEN NOT enabled THEN 'disabled' WHEN pilot_only THEN 'pilot' ELSE 'public' END AS channel_mode FROM tb_vicky_channel_config WHERE provider='meta_instagram' AND channel='instagram' LIMIT 1</cfquery>
      <cfset VARIABLES.vickyInstagramSchemaReady=qVickyInstagramConfig.recordCount GT 0/>
      <cfif VARIABLES.vickyInstagramSchemaReady>
        <cfquery name="qVickyInstagramSummary" datasource="runner_dba">SELECT count(*) AS total,count(*) FILTER (WHERE status='active') AS active,count(*) FILTER (WHERE status='pending') AS pending,count(*) FILTER (WHERE status='revoked') AS revoked FROM tb_vicky_channel_link WHERE provider='meta_instagram' AND channel='instagram'</cfquery>
        <cfquery name="qVickyInstagramQueue" datasource="runner_dba">SELECT id_vicky_channel_queue,RIGHT(external_contact_id,4) AS contact_suffix,status,attempts,error_code,created_at,completed_at FROM tb_vicky_channel_queue WHERE provider='meta_instagram' AND channel='instagram' ORDER BY id_vicky_channel_queue DESC LIMIT 100</cfquery>
        <cfquery name="qVickyInstagramAudit" datasource="runner_dba">SELECT a.*,u.name AS operator_name FROM tb_vicky_channel_config_audit a LEFT JOIN tb_usuarios u ON u.id=a.id_operador WHERE a.provider='meta_instagram' AND a.channel='instagram' ORDER BY a.id_vicky_channel_config_audit DESC LIMIT 20</cfquery>
      </cfif>
    </cfif>
    <cfset VARIABLES.vickyErrorStep="leitura do canal legado Manychat"/>
    <cfquery name="qVickyManychatConfig" datasource="runner_dba">SELECT * FROM tb_vicky_manychat_config WHERE id_config=1</cfquery>
    <cfquery name="qVickyManychatSummary" datasource="runner_dba">SELECT count(*) AS total,count(*) FILTER (WHERE status='active') AS active,count(*) FILTER (WHERE status='pending') AS pending FROM tb_vicky_manychat_link</cfquery>
    <cfquery name="qVickyManychatQueue" datasource="runner_dba">SELECT id_vicky_manychat_queue,channel,subscriber_id,status,attempts,error_code,created_at,completed_at FROM tb_vicky_manychat_queue ORDER BY id_vicky_manychat_queue DESC LIMIT 100</cfquery>
  </cfif>
  <cfif VARIABLES.vickySection EQ "conhecimento">
    <cfset VARIABLES.vickyErrorStep="listagem da base de conhecimento"/>
    <cfquery name="qVickyDocuments" datasource="runner_dba">SELECT * FROM tb_vicky_documento ORDER BY updated_at DESC,id_vicky_documento DESC</cfquery>
    <cfquery name="qVickyDocumentSummary" datasource="runner_dba">SELECT count(*) AS total,count(*) FILTER (WHERE status='active') AS active,count(*) FILTER (WHERE status='processing') AS processing,count(*) FILTER (WHERE status='failed') AS failed FROM tb_vicky_documento</cfquery>
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
