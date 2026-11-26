<cfset VARIABLES.challengeTag = lcase(trim(URL.desafio))/>
<cfparam name="VARIABLES.challengeIsFoco" default="false"/>
<cfparam name="URL.tela" default="participantes"/>
<cfset URL.tela = lcase(trim(URL.tela))/>
<cfif NOT listFindNoCase("participantes,validacoes", URL.tela) AND NOT (VARIABLES.challengeIsFoco AND URL.tela EQ "resumo")>
    <cfset URL.tela = "participantes"/>
</cfif>
<cfparam name="VARIABLES.desafiosQueryDebugEnabled" default="false"/>
<cfif VARIABLES.desafiosQueryDebugEnabled AND NOT structKeyExists(REQUEST, "desafiosQueryDebug")>
    <cfset REQUEST.desafiosQueryDebug = []/>
</cfif>

<cffunction name="desafiosAddQueryTiming" returntype="void" output="false">
    <cfargument name="label" type="string" required="true"/>
    <cfargument name="startTick" type="numeric" required="true"/>
    <cfargument name="rows" type="numeric" required="false" default="-1"/>
    <cfargument name="type" type="string" required="false" default="db"/>

    <cfif NOT VARIABLES.desafiosQueryDebugEnabled>
        <cfreturn/>
    </cfif>

    <cfset LOCAL.item = structNew()/>
    <cfset LOCAL.item.label = ARGUMENTS.label/>
    <cfset LOCAL.item.ms = getTickCount() - ARGUMENTS.startTick/>
    <cfset LOCAL.item.rows = ARGUMENTS.rows/>
    <cfset LOCAL.item.type = ARGUMENTS.type/>
    <cfset arrayAppend(REQUEST.desafiosQueryDebug, LOCAL.item)/>
</cffunction>

<cfset VARIABLES.challengeIsCatarinenseCircuit = listFindNoCase("catarinensecorridaderua,catarinensetrailrun", VARIABLES.challengeTag) GT 0/>
<cfset VARIABLES.challengeIsBrasilGigante = VARIABLES.challengeTag EQ "circuitobrasilgigante"/>
<cfset VARIABLES.challengeIsRaceParticipation = VARIABLES.challengeIsCatarinenseCircuit OR VARIABLES.challengeIsBrasilGigante/>
<cfset VARIABLES.challengeHasScore = VARIABLES.challengeIsCatarinenseCircuit/>
<cfset VARIABLES.challengeWidgets = "no_desafio,em_andamento,vip,confirmados,pendentes,inscritos"/>
<cfset VARIABLES.challengeUsesActivityDays = false/>
<cfif NOT VARIABLES.challengeIsRaceParticipation>
    <cfquery name="qChallengePanelConfig">
        SELECT COALESCE((to_jsonb(evento)->'config_painel')::text, '{}') AS config
        FROM desafios_eventos evento
        WHERE evento.tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
        ORDER BY evento.id_desafio DESC
        LIMIT 1
    </cfquery>
    <cfif qChallengePanelConfig.recordcount>
        <cfset VARIABLES.challengePanelConfig = deserializeJSON(qChallengePanelConfig.config[1])/>
        <cfif isStruct(VARIABLES.challengePanelConfig)>
            <cfif structKeyExists(VARIABLES.challengePanelConfig, "widgets") AND isArray(VARIABLES.challengePanelConfig.widgets)>
                <cfset VARIABLES.challengeWidgets = arrayToList(VARIABLES.challengePanelConfig.widgets)/>
            </cfif>
            <cfif structKeyExists(VARIABLES.challengePanelConfig, "progresso")>
                <cfset VARIABLES.challengeUsesActivityDays = VARIABLES.challengePanelConfig.progresso EQ "dias_com_atividade"/>
            </cfif>
            <cfif structKeyExists(VARIABLES, "challengePeriodWasProvided")
                AND NOT VARIABLES.challengePeriodWasProvided
                AND structKeyExists(VARIABLES.challengePanelConfig, "periodo_padrao")
                AND isSimpleValue(VARIABLES.challengePanelConfig.periodo_padrao)>
                <cfset VARIABLES.challengeDefaultPeriod = lcase(trim(VARIABLES.challengePanelConfig.periodo_padrao))/>
                <cfif listFindNoCase("inscritos,confirmados,pendentes", VARIABLES.challengeDefaultPeriod)
                    OR (VARIABLES.challengeUsesActivityDays AND VARIABLES.challengeDefaultPeriod EQ "atividade")>
                    <cfset URL.periodo = VARIABLES.challengeDefaultPeriod EQ "inscritos" ? "" : VARIABLES.challengeDefaultPeriod/>
                </cfif>
            </cfif>
        </cfif>
    </cfif>
</cfif>
<cfset VARIABLES.challengeCircuitTotalEvents = 3/>
<cfset VARIABLES.challengeCircuitCompletionTarget = 3/>
<cfset VARIABLES.challengeCircuitEvents = []/>
<cfset VARIABLES.challengeMedalCsrf = ""/>
<cfif VARIABLES.challengeIsBrasilGigante>
    <cfset VARIABLES.challengeCircuitTotalEvents = 8/>
    <cfset VARIABLES.challengeCircuitCompletionTarget = 8/>
    <cfset VARIABLES.challengeCircuitEvents = [
        {ordem = 1, idAgregador = 17, nome = "Maratona de São Paulo", sigla = "SP"},
        {ordem = 2, idAgregador = 1000, nome = "Maratona do Paraná", sigla = "PR"},
        {ordem = 3, idAgregador = 26, nome = "Maratona de Porto Alegre", sigla = "POA"},
        {ordem = 4, idAgregador = 9, nome = "Maratona de Campo Grande", sigla = "CGR"},
        {ordem = 5, idAgregador = 14, nome = "Maratona de João Pessoa", sigla = "JPA"},
        {ordem = 6, idAgregador = 28, nome = "Maratona de Floripa", sigla = "FLN"},
        {ordem = 7, idAgregador = 15, nome = "Maratona de Salvador", sigla = "SSA"},
        {ordem = 8, idAgregador = 77, nome = "Maratona de Aracaju", sigla = "AJU"}
    ]/>
<cfelseif VARIABLES.challengeIsCatarinenseCircuit>
    <cfinclude template="catarinense_ranking_helpers.cfm"/>
    <cfset VARIABLES.challengeCircuitTotalEvents = 6/>
    <cfset VARIABLES.challengeCircuitCompletionTarget = 5/>

    <cfif VARIABLES.challengeTag EQ "catarinensecorridaderua">
        <cfset VARIABLES.challengeCircuitEvents = [
            {ordem = 1, tag = "2026-31-meia-maratona-de-joinville", percurso = 21},
            {ordem = 2, tag = "2026-meia-maratona-de-balneario-camboriu-2026", percurso = 21},
            {ordem = 3, tag = "2026-meia-maratona-internacional-de-florianopolis-2026", percurso = 21},
            {ordem = 4, tag = "2026-meia-maratona-de-chapeco-2026", percurso = 21},
            {ordem = 5, tag = "2026-maratona-internacional-de-floripa-2026", percurso = 21},
            {ordem = 6, tag = "2026-maratona-de-criciuma-2026", percurso = 21}
        ]/>
    <cfelse>
        <cfset VARIABLES.challengeCircuitEvents = [
            {ordem = 1, tag = "2026-15-night-run-costao-2026", percurso = 10},
            {ordem = 2, tag = "2026-cross-country-timbo-2026", percurso = 6},
            {ordem = 3, tag = "2026-mountain-do-praia-do-rosa-2026", percurso = 11},
            {ordem = 4, tag = "2026-costa-esmeralda-trail-2026", percurso = 12},
            {ordem = 5, tag = "2026-indomit-trail-bombinhas-12k", percurso = 12},
            {ordem = 6, tag = "2026-mons-ultra-trail-2026", percurso = 12}
        ]/>
    </cfif>

</cfif>

<cfif VARIABLES.challengeIsRaceParticipation>
    <cfif NOT structKeyExists(SESSION, "challengeMedalCsrf") OR NOT len(trim(SESSION.challengeMedalCsrf & ""))>
        <cfset SESSION.challengeMedalCsrf = lcase(hash(createUUID() & now() & CGI.REMOTE_ADDR, "SHA-256"))/>
    </cfif>
    <cfset VARIABLES.challengeMedalCsrf = SESSION.challengeMedalCsrf/>
</cfif>

<cfif VARIABLES.challengeIsBrasilGigante
    AND (URL.tela EQ "validacoes"
        OR (isDefined("FORM.challenge_action")
            AND listFindNoCase("aprovar_validacao_documental,vincular_resultado_oficial,desaprovar_validacao_documental", FORM.challenge_action)))>
    <cfinclude template="brasil_gigante_validacoes_backend.cfm"/>
</cfif>

<cfparam name="URL.genero" default=""/>
<cfparam name="URL.medalha" default=""/>
<cfparam name="URL.mandala" default=""/>
<cfparam name="URL.challenge_refresh" default=""/>
<cfset URL.genero = lcase(trim(URL.genero))/>
<cfset URL.medalha = lcase(trim(URL.medalha))/>
<cfset URL.mandala = lcase(trim(URL.mandala))/>
<cfif NOT listFindNoCase("masculino,feminino,nao_informado", URL.genero)>
    <cfset URL.genero = ""/>
</cfif>
<cfif NOT listFindNoCase("progresso,proxima_etapa,imediata,entregue", URL.medalha)>
    <cfset URL.medalha = ""/>
</cfif>
<cfif NOT listFindNoCase("progresso,proxima_etapa,imediata,entregue", URL.mandala)>
    <cfset URL.mandala = ""/>
</cfif>

<!--- ENTREGA NUMERADA DE MANDALA DO CIRCUITO BRASIL GIGANTE --->
<cfset VARIABLES.challengeMandalaError=""/>
<cfif VARIABLES.challengeIsBrasilGigante AND isDefined("FORM.challenge_action") AND FORM.challenge_action EQ "entregar_mandala">
    <cfinclude template="brasil_gigante_mandala_action.cfm"/>
</cfif>

<!--- ENTREGA DE MEDALHA DOS CIRCUITOS CATARINENSES --->

<cfif VARIABLES.challengeIsCatarinenseCircuit
    AND isDefined("FORM.challenge_action")
    AND FORM.challenge_action EQ "entregar_medalha">
    <cfset VARIABLES.challengeMedalUserId = isDefined("FORM.id_usuario") ? val(FORM.id_usuario) : 0/>
    <cfset VARIABLES.challengeMedalPostedCsrf = isDefined("FORM.challenge_medal_csrf") ? trim(FORM.challenge_medal_csrf) : ""/>

    <cfif VARIABLES.challengeMedalUserId LTE 0
        OR NOT len(VARIABLES.challengeMedalPostedCsrf)
        OR VARIABLES.challengeMedalPostedCsrf NEQ VARIABLES.challengeMedalCsrf>
        <cfthrow type="Challenge.Validation" message="A solicitacao de entrega da medalha e invalida ou expirou."/>
    </cfif>

    <cfquery name="qChallengeMedalEligibility">
        WITH circuit_config (event_order, event_tag, percurso) AS (
            VALUES
            <cfloop array="#VARIABLES.challengeCircuitEvents#" item="VARIABLES.challengeCircuitEvent" index="VARIABLES.challengeCircuitEventIndex">
                (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitEvent.ordem#"/>,
                 <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeCircuitEvent.tag#"/>,
                 <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.challengeCircuitEvent.percurso#"/>)<cfif VARIABLES.challengeCircuitEventIndex LT arrayLen(VARIABLES.challengeCircuitEvents)>,</cfif>
            </cfloop>
        )
        SELECT count(DISTINCT cfg.event_order) AS etapas
        FROM circuit_config cfg
        INNER JOIN tb_evento_corridas evt
            ON lower(evt.tag) = lower(cfg.event_tag)
        INNER JOIN tb_resultados res
            ON res.id_evento = evt.id_evento
           AND res.percurso = cfg.percurso
           AND res.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeMedalUserId#"/>
           AND res.concluinte IS TRUE
           AND res.homologado IS TRUE
           AND res.status_final = 0
    </cfquery>

    <cfif NOT qChallengeMedalEligibility.recordcount OR val(qChallengeMedalEligibility.etapas) LT 5>
        <cfthrow type="Challenge.Validation" message="O atleta ainda nao possui cinco etapas concluidas e reconhecidas neste circuito."/>
    </cfif>

    <cfquery name="qChallengeMedalDelivery">
        WITH target AS (
            SELECT id_usuario
            FROM desafios
            WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeMedalUserId#"/>
              AND desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
        ),
        inserted AS (
            INSERT INTO desafios_obs (id_usuario, produto, obs, id_atendente)
            SELECT target.id_usuario,
                   <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>,
                   <cfqueryparam cfsqltype="cf_sql_varchar" value="medalha_entregue"/>,
                   <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
            FROM target
            WHERE NOT EXISTS (
                SELECT 1
                FROM desafios_obs history
                WHERE history.id_usuario = target.id_usuario
                  AND history.produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
                  AND history.obs = <cfqueryparam cfsqltype="cf_sql_varchar" value="medalha_entregue"/>
            )
            RETURNING id_usuario
        )
        SELECT id_usuario FROM inserted
        UNION ALL
        SELECT id_usuario FROM target
        LIMIT 1
    </cfquery>

    <cfif NOT qChallengeMedalDelivery.recordcount>
        <cfthrow type="Challenge.Validation" message="A inscricao do atleta nao foi encontrada neste circuito."/>
    </cfif>

    <cfset VARIABLES.challengeMedalRedirect=catarinensePanelUrl(VARIABLES.challengeTag,URL,{aba='medalhas',sucesso='medalha_entregue',challenge_refresh=getTickCount()})/>
    <cflocation addtoken="false" url="#VARIABLES.challengeMedalRedirect#"/>
</cfif>

<!--- ALTERAR STATUS DA CAMPANHA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "alterar_status">

    <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
    <cfquery>
        UPDATE desafios
        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.status#"/>
        WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_usuario#"/>
        AND desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
    </cfquery>
    <cfset desafiosAddQueryTiming("alterar_status", VARIABLES.desafiosQueryStart, -1, "db-write")/>

    <cflocation addtoken="false" url="/ads/#VARIABLES.challengeTag#"/>

</cfif>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>

<cfquery name="qBase" cachedwithin="#CreateTimeSpan(0, 0, 0, 15)#">

    <!--- BRASIL GIGANTE --->

    <cfif VARIABLES.challengeIsBrasilGigante>
        WITH circuit_config (event_order, id_agrega_evento) AS (
            VALUES
            <cfloop array="#VARIABLES.challengeCircuitEvents#" item="VARIABLES.challengeCircuitEvent" index="VARIABLES.challengeCircuitEventIndex">
                (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitEvent.ordem#"/>,
                 <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitEvent.idAgregador#"/>)<cfif VARIABLES.challengeCircuitEventIndex LT arrayLen(VARIABLES.challengeCircuitEvents)>,</cfif>
            </cfloop>
        ),
        registrations AS (
            SELECT DISTINCT ON (desafio.id_usuario)
                   desafio.id_usuario,
                   desafio.status,
                   desafio.produto,
                   desafio.data_inscricao,
                   desafio.body
            FROM desafios desafio
            WHERE desafio.desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
            ORDER BY desafio.id_usuario, desafio.data_inscricao ASC NULLS LAST
        ),
        circuit_events AS (
            SELECT DISTINCT cfg.event_order,
                   cfg.id_agrega_evento,
                   evt.id_evento,
                   evt.data_final
            FROM circuit_config cfg
            INNER JOIN tb_evento_corridas evt
                ON evt.id_agrega_evento = cfg.id_agrega_evento
            INNER JOIN tb_agregadores_eventos event_map
                ON event_map.id_evento = evt.id_evento
               AND event_map.agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="brasil-gigante"/>
        ),
        circuit_participation AS (
            SELECT
                res.id_usuario,
                evt.event_order,
                evt.id_agrega_evento,
                max(extract(year FROM evt.data_final))::integer AS ano,
                max(evt.data_final::date) AS data_final,
                min(evt.data_final::date) AS data_inicial
            FROM tb_resultados res
            INNER JOIN registrations enrolled
                ON enrolled.id_usuario = res.id_usuario
            INNER JOIN circuit_events evt
                ON evt.id_evento = res.id_evento
            WHERE res.percurso >= 42
              AND res.percurso < 43
              AND res.id_usuario > 0
            GROUP BY res.id_usuario, evt.event_order, evt.id_agrega_evento
        ),
        circuit_results AS (
            SELECT id_usuario,
                   count(DISTINCT id_agrega_evento) AS eventos_concluidos,
                   count(*) FILTER (WHERE event_order = 1) AS participou_1,
                   count(*) FILTER (WHERE event_order = 2) AS participou_2,
                   count(*) FILTER (WHERE event_order = 3) AS participou_3,
                   count(*) FILTER (WHERE event_order = 4) AS participou_4,
                   count(*) FILTER (WHERE event_order = 5) AS participou_5,
                   count(*) FILTER (WHERE event_order = 6) AS participou_6,
                   count(*) FILTER (WHERE event_order = 7) AS participou_7,
                   count(*) FILTER (WHERE event_order = 8) AS participou_8,
                   max(ano) FILTER (WHERE event_order = 1) AS ano_1,
                   max(ano) FILTER (WHERE event_order = 2) AS ano_2,
                   max(ano) FILTER (WHERE event_order = 3) AS ano_3,
                   max(ano) FILTER (WHERE event_order = 4) AS ano_4,
                   max(ano) FILTER (WHERE event_order = 5) AS ano_5,
                   max(ano) FILTER (WHERE event_order = 6) AS ano_6,
                   max(ano) FILTER (WHERE event_order = 7) AS ano_7,
                   max(ano) FILTER (WHERE event_order = 8) AS ano_8,
                   max(data_final) AS data_final,
                   min(data_inicial) AS data_inicial
            FROM circuit_participation
            GROUP BY id_usuario
        )
        SELECT COALESCE(uf.nome_regiao, 'Exterior') AS regiao,
        null::timestamp AS strava_expires_at,
        des.status,
        des.produto,
        des.data_inscricao,
        usr.id,
        usr.ddi_usuario,
        usr.ddd_usuario,
        usr.telefone_usuario,
        usr.email,
        null::bigint AS strava_id,
        null::varchar AS strava_code,
        COALESCE(
            upper(trim(unaccent(NULLIF(des.body ->> 'cidade', '')))),
            upper(trim(unaccent(usr.cidade))),
            upper(trim(unaccent(pag.cidade))),
            ''
        ) AS cidade,
        COALESCE(NULLIF(upper(trim(des.body ->> 'UF')), ''), usr.estado, pag.uf, '') AS estado,
        upper(COALESCE(NULLIF(trim(des.body ->> 'nome_completo'), ''), pag.nome, usr.name)) AS nome,
        CASE
            WHEN upper(COALESCE(NULLIF(trim(des.body ->> 'genero'), ''), usr.genero, usr.strava_sex, '')) LIKE 'FEM%' THEN 'FEMININO'
            WHEN upper(COALESCE(NULLIF(trim(des.body ->> 'genero'), ''), usr.genero, usr.strava_sex, '')) LIKE 'MAS%' THEN 'MASCULINO'
            ELSE 'NAO INFORMADO'
        END AS genero,
        upper(NULLIF(trim(des.body ->> 'equipe'), '')) AS equipe,
        usr.tag_usuario,
        usr.pais,
        usr.data_statisticas,
        null::varchar AS status_crm,
        null::varchar AS status_transacao,
        null::integer AS distancia_percorrida,
        coalesce(cr.eventos_concluidos, 0) AS dias_correndo,
        coalesce(cr.eventos_concluidos, 0) AS atividades,
        0 AS altimetria,
        coalesce(cr.eventos_concluidos, 0) AS frequencia_fechamento,
        coalesce(cr.eventos_concluidos, 0) AS nodesafio,
        cr.data_final,
        cr.data_inicial,
        CASE WHEN cr.eventos_concluidos > 0 THEN 1 ELSE 0 END AS ativo,
        #VARIABLES.challengeCircuitTotalEvents# AS dias_do_ano,
        pag.tag,
        pag.verificado,
        pag.instagram,
        pag.whatsapp,
        coalesce(
            'https://roadrunners.run/assets/paginas/' || nullif(trim(pag.path_imagem), ''),
            nullif(trim(usr.strava_profile), ''),
            nullif(trim(usr.imagem_usuario), ''),
            '/assets/user.png'
        ) AS imagem_usuario,
        coalesce(cr.participou_1, 0) AS participou_1,
        coalesce(cr.participou_2, 0) AS participou_2,
        coalesce(cr.participou_3, 0) AS participou_3,
        coalesce(cr.participou_4, 0) AS participou_4,
        coalesce(cr.participou_5, 0) AS participou_5,
        coalesce(cr.participou_6, 0) AS participou_6,
        coalesce(cr.participou_7, 0) AS participou_7,
        coalesce(cr.participou_8, 0) AS participou_8,
        cr.ano_1,
        cr.ano_2,
        cr.ano_3,
        cr.ano_4,
        cr.ano_5,
        cr.ano_6,
        cr.ano_7,
        cr.ano_8,
        CASE WHEN mandala.data_entrega IS NOT NULL THEN 1 ELSE 0 END AS mandala_entregue,
        to_char(mandala.data_entrega, 'YYYY-MM-DD HH24:MI:SS') AS mandala_entregue_em,
        coalesce(mandala.numero, '') AS mandala_numero,
        CASE
            WHEN mandala.data_entrega IS NOT NULL THEN 'entregue'
            WHEN coalesce(cr.eventos_concluidos, 0) >= 8 THEN 'imediata'
            WHEN coalesce(cr.eventos_concluidos, 0) = 7 THEN 'proxima_etapa'
            ELSE 'progresso'
        END AS mandala_status
        FROM registrations des
        INNER JOIN tb_usuarios usr ON des.id_usuario = usr.id
        LEFT JOIN LATERAL (
            SELECT pagina.nome,
                   pagina.cidade,
                   pagina.uf,
                   pagina.tag,
                   pagina.verificado,
                   pagina.path_imagem,
                   pagina.instagram,
                   pagina.whatsapp
            FROM tb_paginas pagina
            WHERE pagina.id_usuario_cadastro = usr.id
              AND pagina.tag_prefix = 'atleta'
            ORDER BY pagina.verificado DESC NULLS LAST, pagina.id_pagina
            LIMIT 1
        ) pag ON true
        LEFT JOIN LATERAL (
            SELECT max(history.data_obs) FILTER (WHERE history.obs='mandala_entregue') AS data_entrega,
                   (array_agg(substring(history.obs FROM '^mandala_numero:([0-9]{1,12})$') ORDER BY history.data_obs DESC,history.id_desafio_obs DESC)
                    FILTER (WHERE history.obs ~ '^mandala_numero:[0-9]{1,12}$'))[1] AS numero
            FROM desafios_obs history
            WHERE history.id_usuario = usr.id
              AND history.produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
              AND (history.obs='mandala_entregue' OR history.obs ~ '^mandala_numero:[0-9]{1,12}$')
        ) mandala ON true
        LEFT JOIN circuit_results cr ON cr.id_usuario = usr.id
        LEFT JOIN tb_uf uf
            ON upper(coalesce(NULLIF(trim(des.body ->> 'UF'), ''), usr.estado, pag.uf, '')) = upper(uf.uf)
        WHERE length(<cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.challenge_refresh#"/>) >= 0

    <!--- CIRCUITO CATARINENSE --->

    <cfelseif VARIABLES.challengeIsCatarinenseCircuit>
        WITH circuit_config (event_order, event_tag, percurso) AS (
            VALUES
            <cfloop array="#VARIABLES.challengeCircuitEvents#" item="VARIABLES.challengeCircuitEvent" index="VARIABLES.challengeCircuitEventIndex">
                (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitEvent.ordem#"/>,
                 <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeCircuitEvent.tag#"/>,
                 <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.challengeCircuitEvent.percurso#"/>)<cfif VARIABLES.challengeCircuitEventIndex LT arrayLen(VARIABLES.challengeCircuitEvents)>,</cfif>
            </cfloop>
        ),
        circuit_events AS (
            SELECT cfg.event_order,
                   cfg.event_tag,
                   cfg.percurso,
                   evt.id_evento,
                   evt.data_inicial,
                   evt.data_final
            FROM circuit_config cfg
            LEFT JOIN tb_evento_corridas evt
                ON lower(evt.tag) = lower(cfg.event_tag)
        ),
        circuit_category_winners AS (
            SELECT cfg.event_order,
                   upper(trim(res.sexo)) AS sexo,
                   CASE WHEN res.id_categoria > 0 THEN 'id:' || res.id_categoria::text
                        ELSE nullif(lower(trim(res.nome_categoria)), '') END AS categoria,
                   min(extract(epoch FROM res.tempo_total)) AS segundos
            FROM circuit_events cfg
            INNER JOIN tb_resultados res ON res.id_evento = cfg.id_evento AND res.percurso = cfg.percurso
            WHERE res.concluinte IS TRUE AND res.homologado IS TRUE AND res.status_final = 0
              AND res.classificacao_categoria = 1 AND res.tempo_total > '00:00:00'::time
            GROUP BY cfg.event_order, upper(trim(res.sexo)),
                     CASE WHEN res.id_categoria > 0 THEN 'id:' || res.id_categoria::text
                          ELSE nullif(lower(trim(res.nome_categoria)), '') END
        ),
        circuit_rank_results AS (
            SELECT DISTINCT ON (res.id_usuario, cfg.event_order)
                   res.id_usuario, res.id_evento, res.num_peito, cfg.event_order,
                   cfg.data_inicial, cfg.data_final,
                   CASE WHEN res.classificacao_sexo > 0 AND res.classificacao_sexo = trunc(res.classificacao_sexo)
                        THEN res.classificacao_sexo END AS colocacao,
                   CASE WHEN res.tempo_total > '00:00:00'::time
                         AND (res.id_categoria > 0 OR nullif(trim(res.nome_categoria), '') IS NOT NULL)
                         AND extract(epoch FROM res.tempo_total) >= coalesce(winner.segundos, nullif(extract(epoch FROM res.tempo_f1_categoria), 0))
                        THEN 100 * extract(epoch FROM res.tempo_total)
                             / nullif(coalesce(winner.segundos, nullif(extract(epoch FROM res.tempo_f1_categoria), 0)), 0)
                   END AS percentual
            FROM circuit_events cfg
            INNER JOIN tb_resultados res ON res.id_evento = cfg.id_evento AND res.percurso = cfg.percurso
            LEFT JOIN circuit_category_winners winner ON winner.event_order = cfg.event_order
               AND winner.sexo = upper(trim(res.sexo))
               AND winner.categoria = CASE WHEN res.id_categoria > 0 THEN 'id:' || res.id_categoria::text
                                          ELSE nullif(lower(trim(res.nome_categoria)), '') END
            WHERE res.id_usuario > 0 AND res.concluinte IS TRUE AND res.homologado IS TRUE AND res.status_final = 0
            ORDER BY res.id_usuario, cfg.event_order,
                     CASE WHEN res.classificacao_sexo > 0 THEN res.classificacao_sexo END ASC NULLS LAST,
                     res.tempo_total ASC NULLS LAST, res.id_resultado
        ),
        circuit_tiebreaks AS (
            SELECT id_usuario,
                   coalesce(array_to_json(array_agg(colocacao ORDER BY colocacao) FILTER (WHERE colocacao IS NOT NULL))::text, '[]') AS colocacoes_json,
                   CASE WHEN count(colocacao) = count(*) THEN 1 ELSE 0 END AS colocacoes_completas,
                   coalesce(max(colocacao) FILTER (WHERE event_order = 6), 0) AS ultima_colocacao,
                   CASE WHEN count(*) FILTER (WHERE event_order = 6 AND colocacao IS NULL) > 0 THEN 0 ELSE 1 END AS ultima_completa,
                   CASE WHEN count(percentual) = count(*) THEN avg(percentual)::text END AS media_percentual,
                   CASE WHEN count(percentual) = count(*) THEN 1 ELSE 0 END AS desempenho_completo
            FROM circuit_rank_results GROUP BY id_usuario
        ),
        circuit_participation AS (
            SELECT
                res.id_usuario,
                res.event_order,
                coalesce(sum(
                    CASE
                        WHEN trim(obs.obs) ~ '^-?[0-9]+$' THEN trim(obs.obs)::integer
                        ELSE 0
                    END
                ), 0) AS pontos,
                max(res.data_final::date) AS data_final,
                min(res.data_inicial::date) AS data_inicial
            FROM circuit_rank_results res
            LEFT JOIN tb_resultados_obs obs
                ON obs.id_evento = res.id_evento
               AND obs.num_peito = res.num_peito
            GROUP BY res.id_usuario, res.event_order
        ),
        circuit_results_base AS (
            SELECT id_usuario,
                   count(DISTINCT event_order) AS eventos_concluidos,
                   coalesce(sum(pontos), 0) AS pontos_brutos,
                   coalesce(max(pontos) FILTER (WHERE event_order = 1), 0) AS pontos_1,
                   coalesce(max(pontos) FILTER (WHERE event_order = 2), 0) AS pontos_2,
                   coalesce(max(pontos) FILTER (WHERE event_order = 3), 0) AS pontos_3,
                   coalesce(max(pontos) FILTER (WHERE event_order = 4), 0) AS pontos_4,
                   coalesce(max(pontos) FILTER (WHERE event_order = 5), 0) AS pontos_5,
                   coalesce(max(pontos) FILTER (WHERE event_order = 6), 0) AS pontos_6,
                   count(*) FILTER (WHERE event_order = 1) AS participou_1,
                   count(*) FILTER (WHERE event_order = 2) AS participou_2,
                   count(*) FILTER (WHERE event_order = 3) AS participou_3,
                   count(*) FILTER (WHERE event_order = 4) AS participou_4,
                   count(*) FILTER (WHERE event_order = 5) AS participou_5,
                   count(*) FILTER (WHERE event_order = 6) AS participou_6,
                   max(data_final) AS data_final,
                   min(data_inicial) AS data_inicial
            FROM circuit_participation
            GROUP BY id_usuario
        ),
        circuit_results AS (
            SELECT base.*,
                   coalesce((
                       SELECT sum(best.score)
                       FROM (
                           SELECT stage_score.score
                           FROM unnest(ARRAY[
                               base.pontos_1, base.pontos_2, base.pontos_3,
                               base.pontos_4, base.pontos_5, base.pontos_6
                           ]) AS stage_score(score)
                           ORDER BY stage_score.score DESC
                           LIMIT 4
                       ) best
                   ), 0) AS pontos
            FROM circuit_results_base base
        )
        SELECT COALESCE(uf.nome_regiao, 'Exterior') as regiao,
        to_timestamp(usr.strava_expires_at) as strava_expires_at,
        des.status,
        des.produto,
        des.data_inscricao,
        usr.id,
        usr.ddi_usuario,
        usr.ddd_usuario,
        usr.telefone_usuario,
        usr.email,
        pag.instagram,
        pag.whatsapp,
        usr.strava_id,
        usr.strava_code,
        usr.ddi_usuario,
        usr.ddd_usuario,
        COALESCE(
            upper(trim(unaccent(NULLIF(des.body ->> 'cidade', '')))),
            upper(trim(unaccent(usr.cidade))),
            upper(trim(unaccent(pag.cidade))),
            ''
        ) as cidade,
        COALESCE(NULLIF(upper(trim(des.body ->> 'UF')), ''), usr.estado, pag.uf, '') as estado,
        upper(COALESCE(NULLIF(trim(des.body ->> 'nome_completo'), ''), pag.nome, usr.name)) as nome,
        CASE
            WHEN upper(COALESCE(NULLIF(trim(des.body ->> 'genero'), ''), usr.genero, usr.strava_sex, '')) LIKE 'FEM%' THEN 'FEMININO'
            WHEN upper(COALESCE(NULLIF(trim(des.body ->> 'genero'), ''), usr.genero, usr.strava_sex, '')) LIKE 'MAS%' THEN 'MASCULINO'
            ELSE 'NAO INFORMADO'
        END as genero,
        upper(NULLIF(trim(des.body ->> 'equipe'), '')) as equipe,
        coalesce(nullif(trim(des.body ->> 'data_nascimento'), ''), nullif(trim(des.body ->> 'nascimento'), ''), usr.data_nascimento::text) as data_nascimento,
        usr.tag_usuario,
        usr.pais,
        usr.data_statisticas,
        (select status from tb_crm where id_usuario = usr.id order by id_interacao desc limit 1) as status_crm,
        null::varchar as status_transacao,
        coalesce(cr.pontos, 0) as distancia_percorrida,
        coalesce(cr.eventos_concluidos, 0) as dias_correndo,
        coalesce(cr.eventos_concluidos, 0) as atividades,
        0 as altimetria,
        coalesce(cr.eventos_concluidos, 0) as frequencia_fechamento,
        coalesce(cr.eventos_concluidos, 0) as nodesafio,
        cr.data_final,
        cr.data_inicial,
        CASE WHEN cr.eventos_concluidos > 0 THEN 1 ELSE 0 END as ativo,
        #VARIABLES.challengeCircuitTotalEvents# as dias_do_ano,
        pag.tag,
        pag.verificado,
        coalesce('https://roadrunners.run/assets/paginas/' || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png') as imagem_usuario,
        coalesce(cr.pontos_1, 0) as pontos_1,
        coalesce(cr.pontos_2, 0) as pontos_2,
        coalesce(cr.pontos_3, 0) as pontos_3,
        coalesce(cr.pontos_4, 0) as pontos_4,
        coalesce(cr.pontos_5, 0) as pontos_5,
        coalesce(cr.pontos_6, 0) as pontos_6,
        coalesce(cr.pontos_brutos, 0) as pontos_brutos,
        coalesce(tie.colocacoes_json, '[]') as colocacoes_json,
        coalesce(tie.colocacoes_completas, 1) as colocacoes_completas,
        coalesce(tie.ultima_colocacao, 0) as ultima_colocacao,
        coalesce(tie.ultima_completa, 1) as ultima_completa,
        tie.media_percentual,
        coalesce(tie.desempenho_completo, 0) as desempenho_completo,
        coalesce(cr.participou_1, 0) as participou_1,
        coalesce(cr.participou_2, 0) as participou_2,
        coalesce(cr.participou_3, 0) as participou_3,
        coalesce(cr.participou_4, 0) as participou_4,
        coalesce(cr.participou_5, 0) as participou_5,
        coalesce(cr.participou_6, 0) as participou_6,
        CASE
            WHEN medalha.data_entrega IS NOT NULL
              OR lower(coalesce(des.body ->> 'medalha_entregue', 'false')) IN ('true', '1', 'yes', 'sim') THEN 1
            ELSE 0
        END as medalha_entregue,
        coalesce(
            to_char(medalha.data_entrega, 'YYYY-MM-DD HH24:MI:SS'),
            des.body ->> 'medalha_entregue_em'
        ) as medalha_entregue_em,
        CASE
            WHEN medalha.data_entrega IS NOT NULL
              OR lower(coalesce(des.body ->> 'medalha_entregue', 'false')) IN ('true', '1', 'yes', 'sim') THEN 'entregue'
            WHEN coalesce(cr.eventos_concluidos, 0) >= 5 THEN 'imediata'
            WHEN coalesce(cr.eventos_concluidos, 0) = 4 THEN 'proxima_etapa'
            ELSE 'progresso'
        END as medalha_status
        FROM desafios des
        INNER JOIN tb_usuarios usr ON (des.id_usuario = usr.id)
        LEFT JOIN LATERAL (
            SELECT pagina.nome,
                   pagina.cidade,
                   pagina.uf,
                   pagina.tag,
                   pagina.verificado,
                   pagina.path_imagem,
                   pagina.instagram,
                   pagina.whatsapp
            FROM tb_paginas pagina
            WHERE pagina.id_usuario_cadastro = usr.id
              AND pagina.tag_prefix = 'atleta'
            ORDER BY pagina.verificado DESC NULLS LAST, pagina.id_pagina
            LIMIT 1
        ) pag ON true
        LEFT JOIN LATERAL (
            SELECT max(history.data_obs) AS data_entrega
            FROM desafios_obs history
            WHERE history.id_usuario = usr.id
              AND history.produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
              AND history.obs = <cfqueryparam cfsqltype="cf_sql_varchar" value="medalha_entregue"/>
        ) medalha ON true
        LEFT JOIN circuit_results cr ON cr.id_usuario = usr.id
        LEFT JOIN circuit_tiebreaks tie ON tie.id_usuario = usr.id
        LEFT JOIN tb_uf uf ON usr.estado = uf.uf
        where desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
          AND length(<cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.challenge_refresh#"/>) >= 0

    <!--- OUTROS DESAFIOS --->
    <cfelse>
        <cfif VARIABLES.challengeUsesActivityDays>
        WITH evento AS (
            SELECT data_inicio, data_fim
            FROM desafios_eventos
            WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
            ORDER BY id_desafio DESC
            LIMIT 1
        ),
        atletas AS (
            SELECT des.id_usuario, usr.strava_id,
                   greatest(min(des.data_inscricao::date), evento.data_inicio) AS dia_inicial,
                   least(evento.data_fim, (now() AT TIME ZONE 'America/Sao_Paulo')::date) AS dia_final
            FROM desafios des
            JOIN tb_usuarios usr ON usr.id = des.id_usuario
            CROSS JOIN evento
            WHERE des.desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
              AND des.status = 'C'
              AND usr.strava_id > 0
            GROUP BY des.id_usuario, usr.strava_id, evento.data_inicio, evento.data_fim
        ),
        atividades AS (
            SELECT atleta.id_usuario, act.activity_date, act.distance, act.total_elevation_gain,
                   coalesce(nullif(trim(act.strava_raw->>'sport_type'), ''),
                            nullif(trim(act.strava_raw->>'SPORT_TYPE'), ''),
                            nullif(trim(act.type), ''), 'SemTipo') AS modalidade
            FROM atletas atleta
            CROSS JOIN LATERAL generate_series(atleta.dia_inicial, atleta.dia_final, interval '1 day') dia(data)
            JOIN tb_strava_activities act
                ON act.activity_date = dia.data::date AND act.athlete_id = atleta.strava_id
            WHERE act.activity_source = 'strava'
              AND act.resource_state >= 2
              AND act.strava_raw->>'aspect_type' IS DISTINCT FROM 'delete'
        ),
        atv AS (
            SELECT id_usuario,
                   sum(distance) AS distancia_percorrida, sum(total_elevation_gain) AS altimetria,
                   count(*) AS atividades, count(DISTINCT activity_date) AS dias_correndo,
                   count(DISTINCT activity_date) AS frequencia_fechamento,
                   string_agg(DISTINCT to_char(activity_date, 'YYYY-MM-DD'), ',') AS datas_atividade,
                   max(activity_date) AS data_final, min(activity_date) AS data_inicial,
                   NULL::integer AS dias_do_ano
            FROM atividades
            GROUP BY id_usuario
        ),
        modalidades AS (
            SELECT id_usuario, jsonb_object_agg(modalidade, total)::text AS tipos_atividade
            FROM (
                SELECT id_usuario, modalidade, count(*) AS total
                FROM atividades
                GROUP BY id_usuario, modalidade
            ) totais_por_modalidade
            GROUP BY id_usuario
        )
        <cfelse>
        WITH atletas AS (
            SELECT DISTINCT usr.strava_id
            FROM desafios des
            JOIN tb_usuarios usr ON usr.id = des.id_usuario
            WHERE des.desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
              AND usr.strava_id IS NOT NULL
        ),
        corridas AS (
            SELECT act.athlete_id, act.activity_id, act.activity_date, act.start_date, act.distance, act.total_elevation_gain
            FROM tb_strava_activities act
            JOIN atletas ON atletas.strava_id = act.athlete_id
            WHERE act.type IN ('Run','VirtualRun','TrailRun') AND act.distance >= 990
            <cfif VARIABLES.challengeTag EQ "desafio365">
              AND act.activity_date BETWEEN date '2025-01-01' AND date '2025-12-31'
            <cfelse>
              AND act.activity_date >= date '2020-01-01'
            </cfif>
            UNION
            SELECT act.id_athlete_donation AS athlete_id, act.activity_id, act.activity_date, act.start_date, act.distance, act.total_elevation_gain
            FROM tb_strava_activities act
            JOIN atletas ON atletas.strava_id = act.id_athlete_donation
            WHERE act.id_athlete_donation > 0
              AND act.type IN ('Run','VirtualRun','TrailRun') AND act.distance >= 990
            <cfif VARIABLES.challengeTag EQ "desafio365">
              AND act.activity_date BETWEEN date '2025-01-01' AND date '2025-12-31'
            <cfelse>
              AND act.activity_date >= date '2020-01-01'
            </cfif>
        ),
        apuracao AS (
            SELECT *,
            <cfif VARIABLES.challengeTag EQ "desafio365">
                extract(year FROM start_date) = 2025 AS entra_nos_totais,
                true AS entra_na_frequencia,
                365 AS dias_do_ano
            <cfelse>
                true AS entra_nos_totais,
                activity_date <= current_date AS entra_na_frequencia,
                extract(doy FROM current_date) AS dias_do_ano
            </cfif>
            FROM corridas
        ),
        atv AS (
            SELECT athlete_id,
                   sum(distance) FILTER (WHERE entra_nos_totais) AS distancia_percorrida,
                   sum(total_elevation_gain) FILTER (WHERE entra_nos_totais) AS altimetria,
                   count(*) FILTER (WHERE entra_nos_totais) AS atividades,
                   count(DISTINCT activity_date) FILTER (WHERE entra_nos_totais) AS dias_correndo,
                   count(DISTINCT activity_date) FILTER (WHERE entra_na_frequencia) AS frequencia_fechamento,
                   max(activity_date) FILTER (WHERE entra_nos_totais) AS data_final,
                   min(activity_date) FILTER (WHERE entra_nos_totais) AS data_inicial,
                   max(dias_do_ano) AS dias_do_ano
            FROM apuracao
            GROUP BY athlete_id
            HAVING bool_or(entra_nos_totais) AND bool_or(entra_na_frequencia)
        )
        </cfif>
        SELECT COALESCE(uf.nome_regiao, 'Exterior') as regiao,
        to_timestamp(usr.strava_expires_at) as strava_expires_at,
        des.status,
        des.produto,
        des.data_inscricao,
        usr.id,
        usr.ddi_usuario,
        usr.ddd_usuario,
        usr.telefone_usuario,
        usr.email,
        usr.strava_id,
        usr.strava_code,
        usr.ddi_usuario,
        usr.ddd_usuario,
        COALESCE(upper(trim(unaccent(usr.cidade))), upper(trim(unaccent(pag.cidade)))) as cidade,
        COALESCE(usr.estado, pag.uf) as estado,
        upper(COALESCE(pag.nome, usr.name)) as nome,
        COALESCE(usr.genero, usr.strava_sex) as genero,
        usr.tag_usuario,
        usr.pais,
        usr.data_statisticas,
        (select status from tb_crm where id_usuario = usr.id order by id_interacao desc limit 1) as status_crm,
        CASE
            WHEN pagamentos.pagos > 1 THEN 'duplicado'
            WHEN pagamentos.pagos = 1 THEN 'pago'
            WHEN pagamentos.id_usuario IS NOT NULL THEN 'pendente'
            ELSE null
        END as status_transacao,
        atv.distancia_percorrida,
        atv.dias_correndo,
        atv.atividades,
        atv.altimetria,
        atv.frequencia_fechamento as frequencia_fechamento,
        atv.frequencia_fechamento as nodesafio,
        <cfif VARIABLES.challengeUsesActivityDays>atv.datas_atividade, modalidades.tipos_atividade,</cfif>
        <cfif VARIABLES.challengeIsFoco>
            CASE WHEN usr.strava_id > 0 AND (
                nullif(trim(usr.strava_refresh_token), '') IS NOT NULL
                OR (nullif(trim(usr.strava_access_token), '') IS NOT NULL AND usr.strava_expires_at > extract(epoch FROM now()) + 300)
            ) THEN 1 ELSE 0 END AS strava_conectado,
            CASE WHEN EXISTS (
                SELECT 1 FROM public.tb_strava_foco_points ponto
                WHERE ponto.id_usuario = des.id_usuario AND ponto.status = 'sent'
                  AND ponto.delivered_at IS NOT NULL AND ponto.last_http_status BETWEEN 200 AND 299
            ) THEN 1 ELSE 0 END AS foco_tem_ponto,
        </cfif>
        atv.data_final,
        atv.data_inicial,
        CASE WHEN atv.frequencia_fechamento > 1 THEN 1 ELSE 0 END as ativo,
        atv.dias_do_ano,
        pag.tag,
        pag.verificado,
        coalesce('https://roadrunners.run/assets/paginas/' || pag.path_imagem, usr.strava_profile, usr.imagem_usuario, '/assets/user.png') as imagem_usuario
        FROM desafios des
        INNER JOIN tb_usuarios usr ON (des.id_usuario = usr.id)
        LEFT JOIN tb_paginas pag ON pag.id_usuario_cadastro = usr.id and pag.tag_prefix = 'atleta'
        <cfif VARIABLES.challengeUsesActivityDays>
            LEFT JOIN atv ON atv.id_usuario = des.id_usuario AND des.status = 'C'
            LEFT JOIN modalidades ON modalidades.id_usuario = atv.id_usuario
        <cfelse>
            LEFT JOIN atv ON atv.athlete_id = usr.strava_id
        </cfif>
        LEFT JOIN (
            SELECT transacao.id_usuario, count(*) FILTER (WHERE transacao.status_atual = 'order.paid') AS pagos
            FROM tb_transacoes transacao
            WHERE EXISTS (
                SELECT 1
                FROM desafios inscricao
                WHERE inscricao.id_usuario = transacao.id_usuario
                  AND inscricao.desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
            )
            GROUP BY transacao.id_usuario
        ) pagamentos ON pagamentos.id_usuario = usr.id
        LEFT JOIN tb_uf uf ON usr.estado = uf.uf
        where desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
        <cfif VARIABLES.challengeIsFoco>
            ORDER BY (des.status = 'C') DESC NULLS LAST, des.data_inscricao NULLS LAST, pag.id_pagina NULLS LAST
        </cfif>
    </cfif>
</cfquery>
<cfset desafiosAddQueryTiming("qBase", VARIABLES.desafiosQueryStart, qBase.recordcount, "db")/>

<cfif VARIABLES.challengeIsCatarinenseCircuit>
    <cfset qBase = catarinenseRank(qBase)/>
</cfif>

<cfif VARIABLES.challengeIsCatarinenseCircuit>
    <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
    <cfquery name="qCatarinenseEvents">
        WITH circuit_config (event_order, event_tag, percurso) AS (
            VALUES
            <cfloop array="#VARIABLES.challengeCircuitEvents#" item="VARIABLES.challengeCircuitEvent" index="VARIABLES.challengeCircuitEventIndex">
                (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitEvent.ordem#"/>,
                 <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeCircuitEvent.tag#"/>,
                 <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.challengeCircuitEvent.percurso#"/>)<cfif VARIABLES.challengeCircuitEventIndex LT arrayLen(VARIABLES.challengeCircuitEvents)>,</cfif>
            </cfloop>
        )
        SELECT cfg.event_order,
               cfg.event_tag,
               cfg.percurso,
               evt.id_evento,
               coalesce(evt.nome_evento, 'Etapa ' || cfg.event_order::varchar) AS nome_evento,
               evt.data_inicial,
               evt.data_final,
               evt.cidade,
               evt.estado
        FROM circuit_config cfg
        LEFT JOIN tb_evento_corridas evt
            ON lower(evt.tag) = lower(cfg.event_tag)
        ORDER BY cfg.event_order
    </cfquery>
    <cfset desafiosAddQueryTiming("qCatarinenseEvents", VARIABLES.desafiosQueryStart, qCatarinenseEvents.recordcount, "db")/>
</cfif>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qCountPendentes" dbtype="query">
    select count(*) as total
    from qBase
    where status = 'I'
</cfquery>
<cfset desafiosAddQueryTiming("qCountPendentes", VARIABLES.desafiosQueryStart, qCountPendentes.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qNoDesafio" dbtype="query">
    select count(*) as total
    from qBase
    <cfif VARIABLES.challengeIsRaceParticipation>
        where frequencia_fechamento >= <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitCompletionTarget#"/>
    <cfelseif VARIABLES.challengeTag EQ "desafio365">
        where frequencia_fechamento = 365
    <cfelse>
        where frequencia_fechamento = dias_do_ano
    </cfif>
    and status = 'C'
    and frequencia_fechamento is not null
</cfquery>
<cfset desafiosAddQueryTiming("qNoDesafio", VARIABLES.desafiosQueryStart, qNoDesafio.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qPendenteDesafio" dbtype="query">
    select count(*) as total
    from qBase
    <cfif VARIABLES.challengeIsRaceParticipation>
        where frequencia_fechamento > 0
        and frequencia_fechamento < <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitCompletionTarget#"/>
        and status = 'C'
        and frequencia_fechamento is not null
    <cfelse>
        where frequencia_fechamento <> dias_do_ano and status = 'C' and frequencia_fechamento is not null
    </cfif>
</cfquery>
<cfset desafiosAddQueryTiming("qPendenteDesafio", VARIABLES.desafiosQueryStart, qPendenteDesafio.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qCountVip" dbtype="query">
    select count(*) as total
    from qBase
    where produto like '%vip%' and status = 'C'
</cfquery>
<cfset desafiosAddQueryTiming("qCountVip", VARIABLES.desafiosQueryStart, qCountVip.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qCountConfirmados" dbtype="query">
    select count(*) as total
    from qBase
    where status = 'C'
</cfquery>
<cfset desafiosAddQueryTiming("qCountConfirmados", VARIABLES.desafiosQueryStart, qCountConfirmados.recordcount, "qoq")/>

<cfif VARIABLES.challengeUsesActivityDays>
    <cfquery name="qAthletesWithActivity" dbtype="query">
        SELECT id, datas_atividade, tipos_atividade, max(frequencia_fechamento) AS dias
        FROM qBase
        WHERE status = 'C' AND frequencia_fechamento > 0
        GROUP BY id, datas_atividade, tipos_atividade
    </cfquery>
    <cfset VARIABLES.challengeActivityDays = 0/>
    <cfset VARIABLES.challengeActivitiesByDay = {}/>
    <cfloop query="qAthletesWithActivity">
        <cfset VARIABLES.challengeActivityDays += qAthletesWithActivity.dias/>
        <cfloop list="#qAthletesWithActivity.datas_atividade#" index="challengeActivityDate">
            <cfif NOT structKeyExists(VARIABLES.challengeActivitiesByDay, challengeActivityDate)>
                <cfset VARIABLES.challengeActivitiesByDay[challengeActivityDate] = 0/>
            </cfif>
            <cfset VARIABLES.challengeActivitiesByDay[challengeActivityDate] += 1/>
        </cfloop>
    </cfloop>
</cfif>

<cfif VARIABLES.challengeIsFoco AND VARIABLES.challengeUsesActivityDays>
    <cfquery name="qFocoFunnel" dbtype="query">
        SELECT id, max(strava_conectado) AS conectado, max(foco_tem_ponto) AS ponto, max(frequencia_fechamento) AS dias
        FROM qBase
        GROUP BY id
    </cfquery>
    <cfscript>
        VARIABLES.focoFunnelStages = [
            {key="inscritos", title="Inscritos"},
            {key="strava", title="Conectaram o Strava"},
            {key="atividade", title="Primeira atividade válida"},
            {key="ponto", title="Primeiro ponto confirmado"},
            {key="sem-strava", title="Sem conexão atual com o Strava"},
            {key="sem-atividade", title="Strava conectado, sem atividade válida"},
            {key="sem-ponto", title="Atividade válida, sem ponto confirmado"}
        ];
        VARIABLES.focoStageCounts = {};
        VARIABLES.focoStageByUser = {};
        for (stage in VARIABLES.focoFunnelStages) {
            VARIABLES.focoStageCounts[stage.key] = 0;
        }
        for (athlete in qFocoFunnel) {
            hasPoint = athlete.ponto EQ 1;
            hasActivity = hasPoint OR val(athlete.dias ?: 0) GT 0;
            connected = athlete.conectado EQ 1;
            flags = {
                "inscritos"=true, "strava"=connected OR hasActivity, "atividade"=hasActivity, "ponto"=hasPoint,
                "sem-strava"=!connected, "sem-atividade"=connected AND !hasActivity, "sem-ponto"=hasActivity AND !hasPoint
            };
            VARIABLES.focoStageByUser[toString(athlete.id)] = flags;
            for (stage in VARIABLES.focoFunnelStages) {
                if (flags[stage.key]) {
                    VARIABLES.focoStageCounts[stage.key]++;
                }
            }
        }
    </cfscript>
</cfif>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qCountTotal">
    select count(*) as total
    from desafios
    where desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
</cfquery>
<cfset desafiosAddQueryTiming("qCountTotal", VARIABLES.desafiosQueryStart, qCountTotal.recordcount, "db")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qPeriodo" dbtype="query">
    select *
    from qBase
    where 1 = 1
    <cfif len(trim(URL.busca))>
        and (nome like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#ucase(URL.busca)#%"/>
        <cfif VARIABLES.challengeIsBrasilGigante>OR mandala_numero like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/></cfif>)
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "pendentes">
        and status = 'I'
    </cfif>
    <cfif VARIABLES.challengeUsesActivityDays AND URL.periodo EQ "atividade">
        and status = 'C' and frequencia_fechamento > 0
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "nodesafio">
        <cfif VARIABLES.challengeIsRaceParticipation>
            and frequencia_fechamento >= <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitCompletionTarget#"/> and status = 'C' and frequencia_fechamento is not null
        <cfelse>
            and frequencia_fechamento = dias_do_ano and status = 'C' and frequencia_fechamento is not null
        </cfif>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "pendentedesafio">
        <cfif VARIABLES.challengeIsRaceParticipation>
            and frequencia_fechamento > 0
            and frequencia_fechamento < <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitCompletionTarget#"/>
            and status = 'C'
            and frequencia_fechamento is not null
        <cfelse>
            and frequencia_fechamento <> dias_do_ano and status = 'C' and frequencia_fechamento is not null
        </cfif>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "vip">
        and produto like '%vip%' and status = 'C'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "confirmados">
        and status = 'C'
    </cfif>
</cfquery>
<cfset desafiosAddQueryTiming("qPeriodo", VARIABLES.desafiosQueryStart, qPeriodo.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qPreset" dbtype="query">
    select *
    from qPeriodo
    <cfif len(trim(URL.preset)) AND URL.preset EQ "calendario">
        where checkin > 0
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "resultados">
        where resultados > 0
    </cfif>
    <cfif len(trim(URL.preset)) AND URL.preset EQ "strava">
        where strava_code <> '' and strava_code is not null
    </cfif>
</cfquery>
<cfif VARIABLES.challengeIsFoco AND VARIABLES.challengeUsesActivityDays AND URL.tela EQ "participantes">
    <cfset VARIABLES.focoListedAthletes = {}/>
    <cfscript>
        qPreset = queryFilter(qPreset, function(athlete) {
            var key = toString(athlete.id);
            if (structKeyExists(VARIABLES.focoListedAthletes, key)
                OR (len(URL.etapa) AND !VARIABLES.focoStageByUser[key][URL.etapa])) {
                return false;
            }
            VARIABLES.focoListedAthletes[key] = true;
            return true;
        });
    </cfscript>
</cfif>
<cfset desafiosAddQueryTiming("qPreset", VARIABLES.desafiosQueryStart, qPreset.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qCountStrava" dbtype="query">
    select *
    from qPeriodo
    where strava_code <> '' and strava_code is not null
</cfquery>
<cfset desafiosAddQueryTiming("qCountStrava", VARIABLES.desafiosQueryStart, qCountStrava.recordcount, "qoq")/>


<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qStatsRegiao" dbtype="query">
    select regiao, count(id) total
    from qPreset
    group by regiao
    order by total desc
</cfquery>
<cfset desafiosAddQueryTiming("qStatsRegiao", VARIABLES.desafiosQueryStart, qStatsRegiao.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qStatsEstado" dbtype="query">
    select estado, count(id) total
    from qPreset
    where estado is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    group by estado
    order by total desc
</cfquery>
<cfset desafiosAddQueryTiming("qStatsEstado", VARIABLES.desafiosQueryStart, qStatsEstado.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qStatsCidade" dbtype="query">
    select estado, cidade, count(id) total
    from qPreset
    where cidade is not null
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    group by estado, cidade
    order by total desc
</cfquery>
<cfset desafiosAddQueryTiming("qStatsCidade", VARIABLES.desafiosQueryStart, qStatsCidade.recordcount, "qoq")/>

<cfset VARIABLES.desafiosQueryStart = getTickCount()/>
<cfquery name="qStatsBase" dbtype="query">
    select *
    from qPreset
    where 1 = 1
    <cfif NOT VARIABLES.challengeIsFoco>and nome is not null</cfif>
    <cfif len(trim(URL.regiao))>
        and regiao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.regiao#"/>
    </cfif>
    <cfif len(trim(URL.estado))>
        and estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.estado#"/>
    </cfif>
    <cfif len(trim(URL.cidade))>
        and cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
    </cfif>
    <cfif VARIABLES.challengeIsCatarinenseCircuit AND len(URL.genero)>
        <cfif URL.genero EQ "feminino">
            and genero = 'FEMININO'
        <cfelseif URL.genero EQ "masculino">
            and genero = 'MASCULINO'
        <cfelse>
            and genero = 'NAO INFORMADO'
        </cfif>
    </cfif>
    <cfif VARIABLES.challengeIsCatarinenseCircuit AND len(URL.medalha)>
        and medalha_status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.medalha#"/>
    </cfif>
    <cfif VARIABLES.challengeIsBrasilGigante AND len(URL.mandala)>
        and mandala_status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.mandala#"/>
    </cfif>
    <cfif VARIABLES.challengeIsCatarinenseCircuit>ORDER BY genero, ranking_ordem</cfif>
</cfquery>
<cfset desafiosAddQueryTiming("qStatsBase", VARIABLES.desafiosQueryStart, qStatsBase.recordcount, "qoq")/>

<cfif VARIABLES.challengeIsCatarinenseCircuit>
    <cfset VARIABLES.challengeCircuitMetrics = {
        inscritos = qBase.recordcount,
        comResultado = 0,
        proximaEtapa = 0,
        imediata = 0,
        entregue = 0,
        desempatesPendentes = 0
    }/>
    <cfloop query="qBase">
        <cfif val(qBase.nodesafio) GT 0>
            <cfset VARIABLES.challengeCircuitMetrics.comResultado++/>
        </cfif>
        <cfif listFind("dados_pendentes,sorteio",qBase.ranking_criterio)>
            <cfset VARIABLES.challengeCircuitMetrics.desempatesPendentes++/>
        </cfif>
        <cfswitch expression="#qBase.medalha_status#">
            <cfcase value="proxima_etapa"><cfset VARIABLES.challengeCircuitMetrics.proximaEtapa++/></cfcase>
            <cfcase value="imediata"><cfset VARIABLES.challengeCircuitMetrics.imediata++/></cfcase>
            <cfcase value="entregue"><cfset VARIABLES.challengeCircuitMetrics.entregue++/></cfcase>
        </cfswitch>
    </cfloop>

    <cfquery name="qCatarinenseFemale" dbtype="query">
        SELECT *
        FROM qStatsBase
        WHERE genero = 'FEMININO'
        ORDER BY ranking_ordem
    </cfquery>
    <cfquery name="qCatarinenseMale" dbtype="query">
        SELECT *
        FROM qStatsBase
        WHERE genero = 'MASCULINO'
        ORDER BY ranking_ordem
    </cfquery>
    <cfquery name="qCatarinenseUninformed" dbtype="query">
        SELECT *
        FROM qStatsBase
        WHERE genero = 'NAO INFORMADO'
        ORDER BY ranking_ordem
    </cfquery>
</cfif>

<cfif VARIABLES.challengeIsBrasilGigante>
    <cfset VARIABLES.challengeCircuitMetrics = {
        inscritos = qBase.recordcount,
        comResultado = 0,
        proximaEtapa = 0,
        imediata = 0,
        entregue = 0
    }/>
    <cfloop query="qBase">
        <cfif val(qBase.nodesafio) GT 0>
            <cfset VARIABLES.challengeCircuitMetrics.comResultado++/>
        </cfif>
        <cfswitch expression="#qBase.mandala_status#">
            <cfcase value="proxima_etapa"><cfset VARIABLES.challengeCircuitMetrics.proximaEtapa++/></cfcase>
            <cfcase value="imediata"><cfset VARIABLES.challengeCircuitMetrics.imediata++/></cfcase>
            <cfcase value="entregue"><cfset VARIABLES.challengeCircuitMetrics.entregue++/></cfcase>
        </cfswitch>
    </cfloop>

    <cfquery name="qBrasilGiganteRanking" dbtype="query">
        SELECT *
        FROM qStatsBase
        ORDER BY nodesafio DESC, nome
    </cfquery>
</cfif>


<cfif len(trim(URL.preset)) AND URL.preset EQ "strava">
    <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
    <cfquery name="qStravaPremium" dbtype="query">
        select strava_premium
        from qCountStrava
        where strava_premium = 1
    </cfquery>
    <cfset desafiosAddQueryTiming("qStravaPremium", VARIABLES.desafiosQueryStart, qStravaPremium.recordcount, "qoq")/>

    <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
    <cfquery name="qStravaWeight" dbtype="query">
        select AVG(strava_weight) as strava_weight
        from qCountStrava
        where strava_weight is not null
    </cfquery>
    <cfset desafiosAddQueryTiming("qStravaWeight", VARIABLES.desafiosQueryStart, qStravaWeight.recordcount, "qoq")/>

    <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
    <cfquery name="qStravaFollowers" dbtype="query">
        select AVG(strava_full_follower_count) as strava_full_follower_count
        from qCountStrava
        where strava_full_follower_count is not null
    </cfquery>
    <cfset desafiosAddQueryTiming("qStravaFollowers", VARIABLES.desafiosQueryStart, qStravaFollowers.recordcount, "qoq")/>

    <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
    <cfquery name="qStravaFriends" dbtype="query">
        select AVG(strava_full_friend_count) as strava_full_friend_count
        from qCountStrava
        where strava_full_friend_count is not null
    </cfquery>
    <cfset desafiosAddQueryTiming("qStravaFriends", VARIABLES.desafiosQueryStart, qStravaFriends.recordcount, "qoq")/>

    <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
    <cfquery name="qStravaShoes" dbtype="query">
        select strava_full_shoes
        from qCountStrava
        where strava_full_shoes is not null
    </cfquery>
    <cfset desafiosAddQueryTiming("qStravaShoes", VARIABLES.desafiosQueryStart, qStravaShoes.recordcount, "qoq")/>

    <cfset VARIABLES.shoeCount = 0/>
    <cfset VARIABLES.shoeKm = 0/>
    <cfloop query="qStravaShoes">
        <cfset VARIABLES.shoeCount = VARIABLES.shoeCount + arraylen(deserializeJSON(qStravaShoes.strava_full_shoes))/>
        <cfloop array="#deserializeJSON(qStravaShoes.strava_full_shoes)#" index="item">
            <cfset VARIABLES.shoeKm = VARIABLES.shoeKm + item.converted_distance/>
        </cfloop>
    </cfloop>
    <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
    <cfquery name="qStravaClubs" dbtype="query">
        select strava_full_clubs
        from qCountStrava
        where strava_full_clubs is not null
    </cfquery>
    <cfset desafiosAddQueryTiming("qStravaClubs", VARIABLES.desafiosQueryStart, qStravaClubs.recordcount, "qoq")/>

    <cfset VARIABLES.clubCount = 0/>
    <cfloop query="qStravaClubs">
        <cfset VARIABLES.clubCount = VARIABLES.clubCount + arraylen(deserializeJSON(qStravaClubs.strava_full_clubs))/>
    </cfloop>

</cfif>
