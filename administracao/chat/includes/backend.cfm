<cfparam name="URL.periodo" default="30"/>
<cfparam name="URL.pagina" default="1"/>

<cfset VARIABLES.chatAllowedPeriods = "7,30,90,all"/>
<cfset VARIABLES.chatPeriod = listFindNoCase(VARIABLES.chatAllowedPeriods, trim(URL.periodo & "")) ? lCase(trim(URL.periodo & "")) : "30"/>
<cfset VARIABLES.chatAllTime = VARIABLES.chatPeriod EQ "all"/>
<cfset VARIABLES.chatStartAt = VARIABLES.chatAllTime ? createDateTime(2000, 1, 1, 0, 0, 0) : dateAdd("d", -val(VARIABLES.chatPeriod), now())/>
<cfset VARIABLES.chatUsersPage = max(1, val(URL.pagina))/>
<cfset VARIABLES.chatUsersPageSize = 50/>
<cfset VARIABLES.chatUsersOffset = (VARIABLES.chatUsersPage - 1) * VARIABLES.chatUsersPageSize/>
<cfset VARIABLES.chatReady = false/>
<cfset VARIABLES.chatError = ""/>
<cfset VARIABLES.chatErrorDetail = ""/>
<cfset VARIABLES.chatErrorStep = "verificação da estrutura"/>
<cfset qChatSummary = queryNew("messages,active_senders,active_recipients,active_users,conversations,reciprocal_conversations,read_messages,removed_messages,edited_messages,icon_messages,request_messages,contact_messages,median_response_minutes,avg_messages_per_sender")/>
<cfset qChatTimeline = queryNew("day,messages,senders,conversations")/>
<cfset qChatOrigins = queryNew("origin,messages,conversations,senders,reciprocal_conversations")/>
<cfset qChatIcons = queryNew("icon_key,total")/>
<cfset qChatRequests = queryNew("requests,accepted,rejected,pending,median_acceptance_minutes")/>
<cfset qChatDepth = queryNew("depth,total")/>
<cfset qChatUsers = queryNew("id_usuario,nome,tag,cidade,uf,chats,messages,icons")/>

<cftry>
    <!---
        Privacy invariant: no query returns message content, recipient identity or
        conversation identity. The user ranking is aggregated by sender. Content is
        only tested against the finite icon-token list and is never projected or logged.
    --->
    <cfquery name="qChatSchema" datasource="runner_dba">
        SELECT count(*) AS available_columns
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND (
              (table_name = 'tb_chat_conversa' AND column_name IN ('id_chat_conversa','id_usuario_menor','id_usuario_maior','status','autorizacao_origem','solicitada_em','respondida_em'))
              OR (table_name = 'tb_chat_participante' AND column_name IN ('id_chat_conversa','id_usuario','ultima_mensagem_lida_id'))
              OR (table_name = 'tb_chat_mensagem' AND column_name IN ('id_chat_mensagem','id_chat_conversa','id_remetente','tipo','conteudo','created_at','editada_em','removida_em'))
          )
    </cfquery>
    <cfif val(qChatSchema.available_columns) LT 18>
        <cfthrow type="ChatAnalytics.Schema" message="Estrutura do chat incompleta" detail="Foram encontradas #val(qChatSchema.available_columns)# das 18 colunas necessárias. Aplique a migration 2026-08-06_chat_mensagens.sql no mesmo banco usado pelo datasource runner_dba."/>
    </cfif>

    <cfset VARIABLES.chatErrorStep = "resumo de uso"/>
    <cfquery name="qChatSummaryBase" datasource="runner_dba">
        SELECT count(CASE WHEN m.removida_em IS NULL THEN 1 END) AS messages,
               count(DISTINCT CASE WHEN m.removida_em IS NULL THEN m.id_remetente END) AS active_senders,
               count(DISTINCT CASE WHEN m.removida_em IS NULL THEN m.id_chat_conversa END) AS conversations,
               count(CASE WHEN m.removida_em IS NOT NULL THEN 1 END) AS removed_messages,
               count(CASE WHEN m.editada_em IS NOT NULL THEN 1 END) AS edited_messages,
               count(CASE WHEN m.removida_em IS NULL AND c.autorizacao_origem = 'request' THEN 1 END) AS request_messages,
               count(CASE WHEN m.removida_em IS NULL AND c.autorizacao_origem = 'follower' THEN 1 END) AS contact_messages
        FROM tb_chat_mensagem m
        INNER JOIN tb_chat_conversa c ON c.id_chat_conversa = m.id_chat_conversa
        WHERE m.tipo = 'text'
          AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "usuários ativos"/>
    <cfquery name="qChatActiveUsers" datasource="runner_dba">
        SELECT count(DISTINCT active_user.id_usuario) AS active_users,
               count(DISTINCT active_user.id_destinatario) AS active_recipients
        FROM (
            SELECT m.id_remetente AS id_usuario,
                   CASE WHEN c.id_usuario_menor = m.id_remetente THEN c.id_usuario_maior ELSE c.id_usuario_menor END AS id_destinatario
            FROM tb_chat_mensagem m
            INNER JOIN tb_chat_conversa c ON c.id_chat_conversa = m.id_chat_conversa
            WHERE m.tipo = 'text' AND m.removida_em IS NULL
              AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
            UNION ALL
            SELECT CASE WHEN c.id_usuario_menor = m.id_remetente THEN c.id_usuario_maior ELSE c.id_usuario_menor END AS id_usuario,
                   CASE WHEN c.id_usuario_menor = m.id_remetente THEN c.id_usuario_maior ELSE c.id_usuario_menor END AS id_destinatario
            FROM tb_chat_mensagem m
            INNER JOIN tb_chat_conversa c ON c.id_chat_conversa = m.id_chat_conversa
            WHERE m.tipo = 'text' AND m.removida_em IS NULL
              AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
        ) active_user
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "reciprocidade"/>
    <cfquery name="qChatReciprocal" datasource="runner_dba">
        SELECT count(*) AS reciprocal_conversations
        FROM (
            SELECT m.id_chat_conversa
            FROM tb_chat_mensagem m
            WHERE m.tipo = 'text' AND m.removida_em IS NULL
              AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
            GROUP BY m.id_chat_conversa
            HAVING count(DISTINCT m.id_remetente) = 2
        ) reciprocal
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "leitura estimada"/>
    <cfquery name="qChatRead" datasource="runner_dba">
        SELECT count(*) AS read_messages
        FROM tb_chat_mensagem m
        WHERE m.tipo = 'text' AND m.removida_em IS NULL
          AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
          AND EXISTS (
              SELECT 1 FROM tb_chat_participante p
              WHERE p.id_chat_conversa = m.id_chat_conversa
                AND p.id_usuario != m.id_remetente
                AND p.ultima_mensagem_lida_id >= m.id_chat_mensagem
          )
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "respostas"/>
    <cfquery name="qChatResponse" datasource="runner_dba">
        SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY response_minutes) AS median_response_minutes
        FROM (
            SELECT extract(epoch FROM (sequenced.created_at - sequenced.previous_created_at)) / 60.0 AS response_minutes
            FROM (
                SELECT m.created_at, m.id_remetente,
                       lag(m.created_at) OVER (PARTITION BY m.id_chat_conversa ORDER BY m.id_chat_mensagem) AS previous_created_at,
                       lag(m.id_remetente) OVER (PARTITION BY m.id_chat_conversa ORDER BY m.id_chat_mensagem) AS previous_sender
                FROM tb_chat_mensagem m
                WHERE m.tipo = 'text' AND m.removida_em IS NULL
                  AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
            ) sequenced
            WHERE sequenced.previous_sender IS NOT NULL
              AND sequenced.previous_sender != sequenced.id_remetente
        ) responses
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "resumo de ícones"/>
    <cfquery name="qChatIconSummary" datasource="runner_dba">
        SELECT count(*) AS icon_messages
        FROM tb_chat_mensagem m
        WHERE m.tipo = 'text' AND m.removida_em IS NULL
          AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
          AND m.conteudo IN ('[[rr-icon:trophy]]','[[rr-icon:like]]','[[rr-icon:claps]]','[[rr-icon:banana]]','[[rr-icon:medal]]','[[rr-icon:shoes]]','[[rr-icon:water]]','[[rr-icon:megaphone]]','[[rr-icon:cola]]','[[rr-icon:bell]]','[[rr-icon:gel]]','[[rr-icon:sports-drink]]','[[rr-icon:smile]]','[[rr-icon:wink]]')
    </cfquery>

    <cfset qChatSummary = queryNew("messages,active_senders,active_recipients,active_users,conversations,reciprocal_conversations,read_messages,removed_messages,edited_messages,icon_messages,request_messages,contact_messages,median_response_minutes,avg_messages_per_sender")/>
    <cfset queryAddRow(qChatSummary, 1)/>
    <cfset querySetCell(qChatSummary, "messages", val(qChatSummaryBase.messages), 1)/>
    <cfset querySetCell(qChatSummary, "active_senders", val(qChatSummaryBase.active_senders), 1)/>
    <cfset querySetCell(qChatSummary, "active_recipients", val(qChatActiveUsers.active_recipients), 1)/>
    <cfset querySetCell(qChatSummary, "active_users", val(qChatActiveUsers.active_users), 1)/>
    <cfset querySetCell(qChatSummary, "conversations", val(qChatSummaryBase.conversations), 1)/>
    <cfset querySetCell(qChatSummary, "reciprocal_conversations", val(qChatReciprocal.reciprocal_conversations), 1)/>
    <cfset querySetCell(qChatSummary, "read_messages", val(qChatRead.read_messages), 1)/>
    <cfset querySetCell(qChatSummary, "removed_messages", val(qChatSummaryBase.removed_messages), 1)/>
    <cfset querySetCell(qChatSummary, "edited_messages", val(qChatSummaryBase.edited_messages), 1)/>
    <cfset querySetCell(qChatSummary, "icon_messages", val(qChatIconSummary.icon_messages), 1)/>
    <cfset querySetCell(qChatSummary, "request_messages", val(qChatSummaryBase.request_messages), 1)/>
    <cfset querySetCell(qChatSummary, "contact_messages", val(qChatSummaryBase.contact_messages), 1)/>
    <cfset querySetCell(qChatSummary, "median_response_minutes", val(qChatResponse.median_response_minutes), 1)/>
    <cfset querySetCell(qChatSummary, "avg_messages_per_sender", val(qChatSummaryBase.messages) / max(1, val(qChatSummaryBase.active_senders)), 1)/>

    <cfset VARIABLES.chatErrorStep = "série temporal"/>
    <cfquery name="qChatTimeline" datasource="runner_dba">
        SELECT CAST(date_trunc('day', m.created_at) AS date) AS day,
               count(*) AS messages,
               count(DISTINCT m.id_remetente) AS senders,
               count(DISTINCT m.id_chat_conversa) AS conversations
        FROM tb_chat_mensagem m
        WHERE m.tipo = 'text' AND m.removida_em IS NULL
          AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
        GROUP BY 1 ORDER BY 1
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "contatos e não contatos"/>
    <cfquery name="qChatOrigins" datasource="runner_dba">
        WITH activity AS (
            SELECT c.autorizacao_origem AS origin, m.id_chat_conversa, m.id_remetente
            FROM tb_chat_mensagem m
            INNER JOIN tb_chat_conversa c ON c.id_chat_conversa = m.id_chat_conversa
            WHERE m.tipo = 'text' AND m.removida_em IS NULL
              AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
        ), pairs AS (
            SELECT origin, id_chat_conversa, count(DISTINCT id_remetente) AS senders
            FROM activity GROUP BY origin, id_chat_conversa
        )
        SELECT a.origin, count(*) AS messages, count(DISTINCT a.id_chat_conversa) AS conversations,
               count(DISTINCT a.id_remetente) AS senders,
               count(DISTINCT CASE WHEN p.senders = 2 THEN a.id_chat_conversa ELSE NULL END) AS reciprocal_conversations
        FROM activity a INNER JOIN pairs p ON p.id_chat_conversa = a.id_chat_conversa
        GROUP BY a.origin ORDER BY a.origin
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "uso de ícones"/>
    <cfquery name="qChatIcons" datasource="runner_dba">
        SELECT lower(substring(m.conteudo from '^\[\[rr-icon:([^]]+)\]\]$')) AS icon_key, count(*) AS total
        FROM tb_chat_mensagem m
        WHERE m.tipo = 'text' AND m.removida_em IS NULL
          AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
          AND m.conteudo ~ '^\[\[rr-icon:(trophy|like|claps|banana|medal|shoes|water|megaphone|cola|bell|gel|sports-drink|smile|wink)\]\]$'
        GROUP BY 1 ORDER BY total DESC, icon_key
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "solicitações de conversa"/>
    <cfquery name="qChatRequests" datasource="runner_dba">
        WITH requests AS (
            SELECT status, respondida_em, solicitada_em
            FROM tb_chat_conversa
            WHERE autorizacao_origem = 'request'
              AND solicitada_em >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
        )
        SELECT count(*) AS requests,
               sum(CASE WHEN status = 'active' AND respondida_em IS NOT NULL THEN 1 ELSE 0 END) AS accepted,
               sum(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) AS rejected,
               sum(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending,
               (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY extract(epoch FROM (respondida_em - solicitada_em)) / 60.0)
                FROM requests
                WHERE respondida_em IS NOT NULL AND respondida_em >= solicitada_em) AS median_acceptance_minutes
        FROM requests
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "profundidade de uso"/>
    <cfquery name="qChatDepth" datasource="runner_dba">
        WITH sender_volume AS (
            SELECT id_remetente, count(*) AS total
            FROM tb_chat_mensagem
            WHERE tipo = 'text' AND removida_em IS NULL
              AND created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
            GROUP BY id_remetente
        )
        SELECT CASE WHEN total = 1 THEN '1 mensagem'
                    WHEN total BETWEEN 2 AND 5 THEN '2 a 5'
                    WHEN total BETWEEN 6 AND 20 THEN '6 a 20'
                    ELSE '21 ou mais' END AS depth,
               count(*) AS total
        FROM sender_volume GROUP BY 1
        ORDER BY min(total)
    </cfquery>

    <cfset VARIABLES.chatErrorStep = "listagem de usuários"/>
    <cfquery name="qChatUsers" datasource="runner_dba">
        SELECT u.id AS id_usuario,
               coalesce(nullif(trim(profile.nome), ''), nullif(trim(u.name), ''), 'Usuário ' || u.id) AS nome,
               profile.tag,
               coalesce(nullif(trim(profile.cidade), ''), nullif(trim(u.cidade), ''), '') AS cidade,
               coalesce(nullif(trim(profile.uf), ''), nullif(trim(u.estado), ''), '') AS uf,
               count(DISTINCT m.id_chat_conversa) AS chats,
               count(*) AS messages,
               count(CASE WHEN m.conteudo IN ('[[rr-icon:trophy]]','[[rr-icon:like]]','[[rr-icon:claps]]','[[rr-icon:banana]]','[[rr-icon:medal]]','[[rr-icon:shoes]]','[[rr-icon:water]]','[[rr-icon:megaphone]]','[[rr-icon:cola]]','[[rr-icon:bell]]','[[rr-icon:gel]]','[[rr-icon:sports-drink]]','[[rr-icon:smile]]','[[rr-icon:wink]]') THEN 1 END) AS icons
        FROM tb_chat_mensagem m
        INNER JOIN tb_usuarios u ON u.id = m.id_remetente
        LEFT JOIN LATERAL (
            SELECT p.nome, p.tag, p.cidade, p.uf
            FROM tb_paginas_usuarios pu
            INNER JOIN tb_paginas p ON p.id_pagina = pu.id_pagina
            WHERE pu.id_usuario = u.id
              AND p.tag_prefix = 'atleta'
            ORDER BY p.id_pagina
            LIMIT 1
        ) profile ON true
        WHERE m.tipo = 'text' AND m.removida_em IS NULL
          AND m.created_at >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.chatStartAt#"/>
        GROUP BY u.id, profile.nome, profile.tag, profile.cidade, profile.uf
        ORDER BY messages DESC, chats DESC, u.id
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.chatUsersPageSize#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.chatUsersOffset#"/>
    </cfquery>

    <cfset VARIABLES.chatUsersTotal = val(qChatSummary.active_senders)/>
    <cfset VARIABLES.chatUsersTotalPages = max(1, ceiling(VARIABLES.chatUsersTotal / VARIABLES.chatUsersPageSize))/>

    <cfset VARIABLES.chatReady = true/>
    <cfcatch type="any">
        <cfset VARIABLES.chatError = cfcatch.message/>
        <cfif structKeyExists(cfcatch, "detail")>
            <!--- Detail may contain SQL text; keep only the first PostgreSQL error line. --->
            <cfset VARIABLES.chatErrorDetail = trim(listFirst(reReplace(cfcatch.detail & "", "[\r\n]+", chr(10), "all"), chr(10)))/>
            <cfset VARIABLES.chatErrorDetail = left(VARIABLES.chatErrorDetail, 500)/>
        </cfif>
    </cfcatch>
</cftry>
