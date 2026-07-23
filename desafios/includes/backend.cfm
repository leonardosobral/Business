<cfset VARIABLES.challengeTag = lcase(trim(URL.desafio))/>
<cfparam name="URL.tela" default="participantes"/>
<cfset URL.tela = lcase(trim(URL.tela))/>
<cfif NOT listFindNoCase("participantes,validacoes", URL.tela)>
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

<!--- ENTREGA DE MANDALA DO CIRCUITO BRASIL GIGANTE --->

<cfif VARIABLES.challengeIsBrasilGigante
    AND isDefined("FORM.challenge_action")
    AND FORM.challenge_action EQ "entregar_mandala">
    <cfset VARIABLES.challengeMandalaUserId = isDefined("FORM.id_usuario") ? val(FORM.id_usuario) : 0/>
    <cfset VARIABLES.challengeMandalaPostedCsrf = isDefined("FORM.challenge_medal_csrf") ? trim(FORM.challenge_medal_csrf) : ""/>

    <cfif VARIABLES.challengeMandalaUserId LTE 0
        OR NOT len(VARIABLES.challengeMandalaPostedCsrf)
        OR VARIABLES.challengeMandalaPostedCsrf NEQ VARIABLES.challengeMedalCsrf>
        <cfthrow type="Challenge.Validation" message="A solicitacao de entrega da mandala e invalida ou expirou."/>
    </cfif>

    <cfquery name="qChallengeMandalaEligibility">
        SELECT count(DISTINCT evt.id_agrega_evento) AS etapas
        FROM tb_resultados res
        INNER JOIN tb_evento_corridas evt
            ON evt.id_evento = res.id_evento
        INNER JOIN tb_agregadores_eventos agr
            ON agr.id_evento = evt.id_evento
           AND agr.agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="brasil-gigante"/>
        WHERE res.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeMandalaUserId#"/>
          AND res.percurso = <cfqueryparam cfsqltype="cf_sql_decimal" value="42"/>
          AND evt.id_agrega_evento IN (
              <cfqueryparam cfsqltype="cf_sql_integer" value="17,1000,26,9,14,28,15,77" list="true"/>
          )
    </cfquery>

    <cfif NOT qChallengeMandalaEligibility.recordcount OR val(qChallengeMandalaEligibility.etapas) LT 7>
        <cfthrow type="Challenge.Validation" message="O atleta ainda nao possui sete etapas reconhecidas no Circuito Brasil Gigante."/>
    </cfif>

    <cfquery name="qChallengeMandalaDelivery">
        WITH target AS (
            SELECT id_usuario
            FROM desafios
            WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeMandalaUserId#"/>
              AND desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
        ),
        inserted AS (
            INSERT INTO desafios_obs (id_usuario, produto, obs, id_atendente)
            SELECT target.id_usuario,
                   <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>,
                   <cfqueryparam cfsqltype="cf_sql_varchar" value="mandala_entregue"/>,
                   <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
            FROM target
            WHERE NOT EXISTS (
                SELECT 1
                FROM desafios_obs history
                WHERE history.id_usuario = target.id_usuario
                  AND history.produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
                  AND history.obs = <cfqueryparam cfsqltype="cf_sql_varchar" value="mandala_entregue"/>
            )
            RETURNING id_usuario
        )
        SELECT id_usuario FROM inserted
        UNION ALL
        SELECT id_usuario FROM target
        LIMIT 1
    </cfquery>

    <cfif NOT qChallengeMandalaDelivery.recordcount>
        <cfthrow type="Challenge.Validation" message="A inscricao do atleta nao foi encontrada no Circuito Brasil Gigante."/>
    </cfif>

    <cflocation addtoken="false" url="/desafios/#VARIABLES.challengeTag#/?sucesso=mandala_entregue&challenge_refresh=#getTickCount()#&busca=#urlEncodedFormat(URL.busca)#&mandala=#urlEncodedFormat(URL.mandala)#&regiao=#urlEncodedFormat(URL.regiao)#&estado=#urlEncodedFormat(URL.estado)#&cidade=#urlEncodedFormat(URL.cidade)#"/>
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
    </cfquery>

    <cfif NOT qChallengeMedalEligibility.recordcount OR val(qChallengeMedalEligibility.etapas) LT 4>
        <cfthrow type="Challenge.Validation" message="O atleta ainda nao possui quatro etapas reconhecidas neste circuito."/>
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

    <cflocation addtoken="false" url="/desafios/#VARIABLES.challengeTag#/?sucesso=medalha_entregue&challenge_refresh=#getTickCount()#&busca=#urlEncodedFormat(URL.busca)#&genero=#urlEncodedFormat(URL.genero)#&medalha=#urlEncodedFormat(URL.medalha)#&regiao=#urlEncodedFormat(URL.regiao)#&estado=#urlEncodedFormat(URL.estado)#&cidade=#urlEncodedFormat(URL.cidade)#"/>
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
                   pagina.path_imagem
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
              AND history.obs = <cfqueryparam cfsqltype="cf_sql_varchar" value="mandala_entregue"/>
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
        circuit_participation AS (
            SELECT
                res.id_usuario,
                cfg.event_order,
                coalesce(sum(
                    CASE
                        WHEN trim(obs.obs) ~ '^-?[0-9]+$' THEN trim(obs.obs)::integer
                        ELSE 0
                    END
                ), 0) AS pontos,
                max(cfg.data_final::date) AS data_final,
                min(cfg.data_inicial::date) AS data_inicial
            FROM circuit_events cfg
            INNER JOIN tb_resultados res
                ON res.id_evento = cfg.id_evento
               AND res.percurso = cfg.percurso
               AND res.id_usuario > 0
            LEFT JOIN tb_resultados_obs obs
                ON obs.id_evento = res.id_evento
               AND obs.num_peito = res.num_peito
            GROUP BY res.id_usuario, cfg.event_order
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
        CASE
            WHEN coalesce(des.body ->> 'data_nascimento', '') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN
                CASE
                    WHEN substring(des.body ->> 'data_nascimento', 1, 4)::integer BETWEEN 1900 AND extract(year FROM current_date)::integer
                     AND substring(des.body ->> 'data_nascimento', 6, 2)::integer BETWEEN 1 AND 12
                     AND substring(des.body ->> 'data_nascimento', 9, 2)::integer BETWEEN 1 AND 31 THEN
                        CASE
                            WHEN to_char(to_date(des.body ->> 'data_nascimento', 'YYYY-MM-DD'), 'YYYY-MM-DD') = (des.body ->> 'data_nascimento')
                                THEN to_date(des.body ->> 'data_nascimento', 'YYYY-MM-DD')
                            ELSE NULL
                        END
                    ELSE NULL
                END
            WHEN coalesce(des.body ->> 'nascimento', '') ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN
                CASE
                    WHEN substring(des.body ->> 'nascimento', 7, 4)::integer BETWEEN 1900 AND extract(year FROM current_date)::integer
                     AND substring(des.body ->> 'nascimento', 4, 2)::integer BETWEEN 1 AND 12
                     AND substring(des.body ->> 'nascimento', 1, 2)::integer BETWEEN 1 AND 31 THEN
                        CASE
                            WHEN to_char(to_date(des.body ->> 'nascimento', 'DD/MM/YYYY'), 'DD/MM/YYYY') = (des.body ->> 'nascimento')
                                THEN to_date(des.body ->> 'nascimento', 'DD/MM/YYYY')
                            ELSE NULL
                        END
                    ELSE NULL
                END
            ELSE NULL
        END as data_nascimento,
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
                   pagina.path_imagem
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
        LEFT JOIN tb_uf uf ON usr.estado = uf.uf
        where desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
          AND length(<cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.challenge_refresh#"/>) >= 0

    <!--- OUTROS DESAFIOS --->
    <cfelse>
        WITH atv as (
        with atividades as
        (
            select
            athlete_id,
            count(distinct frequencia_fechamento) as frequencia_fechamento
            from
                (
                    select
                    athlete_id,
                    activity_date as frequencia_fechamento
                    from tb_strava_activities act
                    <cfif lcase(trim(URL.desafio)) EQ "desafio365">
                        where activity_date between '2025-01-01'::date and '2025-12-31'::date
                    <cfelse>
                        where activity_date between '2020-01-01'::date and current_date::date
                    </cfif>
                    AND type in ('Run','VirtualRun','TrailRun')
                    AND distance >= 990
                    UNION
                    select
                    id_athlete_donation as athlete_id,
                    activity_date as frequencia_fechamento
                    from tb_strava_activities act
                    <cfif lcase(trim(URL.desafio)) EQ "desafio365">
                        where activity_date between '2025-01-01'::date and '2025-12-31'::date
                    <cfelse>
                        where activity_date between '2020-01-01'::date and current_date::date
                    </cfif>
                    and id_athlete_donation > 0
                    AND type in ('Run','VirtualRun','TrailRun')
                    AND distance >= 990
                ) as atv
            group by
            athlete_id
        )
        SELECT
        athlete_id,
        sum(distance) as distancia_percorrida,
        sum(total_elevation_gain) as altimetria,
        count(activity_id) as atividades,
        count(distinct activity_date::date) as dias_correndo,
        max(frequencia_fechamento) as frequencia_fechamento,
        max(activity_date::date) as data_final,
        min(activity_date::date) as data_inicial,
        max(dias_do_ano) as dias_do_ano
        FROM
        (
            SELECT
            at1.athlete_id,
            distance,
            total_elevation_gain,
            activity_id,
            activity_date::date,
            frequencia_fechamento,
            <cfif lcase(trim(URL.desafio)) EQ "desafio365">
                365 as dias_do_ano
            <cfelse>
                EXTRACT('doy' FROM current_date) as dias_do_ano
            </cfif>
            FROM tb_strava_activities at1
            inner join atividades on atividades.athlete_id = at1.athlete_id
            WHERE type in ('Run','VirtualRun','TrailRun')
            AND distance >= 990
            <cfif lcase(trim(URL.desafio)) EQ "desafio365">
                AND activity_date >= '2025-01-01'
                AND activity_date <= '2025-12-31'
                AND extract(year from start_date) = 2025
            <cfelse>
                AND activity_date >= '2020-01-01'
                --AND extract(year from start_date) = extract(year from current_date)
            </cfif>
            UNION
            SELECT
            id_athlete_donation as athlete_id,
            distance,
            total_elevation_gain,
            activity_id,
            activity_date::date,
            frequencia_fechamento,
            <cfif lcase(trim(URL.desafio)) EQ "desafio365">
                365 as dias_do_ano
            <cfelse>
                EXTRACT('doy' FROM current_date) as dias_do_ano
            </cfif>
            FROM tb_strava_activities at2
            inner join atividades on atividades.athlete_id = at2.id_athlete_donation
            WHERE type in ('Run','VirtualRun','TrailRun')
            AND distance >= 990
            <cfif lcase(trim(URL.desafio)) EQ "desafio365">
                AND activity_date >= '2025-01-01'
                AND activity_date <= '2025-12-31'
                AND extract(year from start_date) = 2025
            <cfelse>
                AND activity_date >= '2020-01-01'
                --AND extract(year from start_date) = extract(year from current_date)
            </cfif>
            AND id_athlete_donation > 0

        ) as qry1
         GROUP BY athlete_id
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
            WHEN (select count(*) from tb_transacoes where id_usuario = usr.id and status_atual = 'order.paid') > 1 THEN 'duplicado'
            WHEN (select count(*) from tb_transacoes where id_usuario = usr.id and status_atual = 'order.paid') = 1 THEN 'pago'
            WHEN (select count(*) from tb_transacoes where id_usuario = usr.id) > 0 THEN 'pendente'
            ELSE null
        END as status_transacao,
        atv.distancia_percorrida,
        atv.dias_correndo,
        atv.atividades,
        atv.altimetria,
        atv.frequencia_fechamento as frequencia_fechamento,
        atv.frequencia_fechamento as nodesafio,
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
        LEFT JOIN atv on atv.athlete_id = usr.strava_id
        LEFT JOIN tb_uf uf ON usr.estado = uf.uf
        where desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.challengeTag#"/>
    </cfif>
</cfquery>
<cfset desafiosAddQueryTiming("qBase", VARIABLES.desafiosQueryStart, qBase.recordcount, "db")/>

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
    <cfif len(trim(URL.busca))>
        where nome like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#ucase(URL.busca)#%"/>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "pendentes">
        where status = 'I'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "nodesafio">
        <cfif VARIABLES.challengeIsRaceParticipation>
            where frequencia_fechamento >= <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitCompletionTarget#"/> and status = 'C' and frequencia_fechamento is not null
        <cfelse>
            where frequencia_fechamento = dias_do_ano and status = 'C' and frequencia_fechamento is not null
        </cfif>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "pendentedesafio">
        <cfif VARIABLES.challengeIsRaceParticipation>
            where frequencia_fechamento > 0
            and frequencia_fechamento < <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.challengeCircuitCompletionTarget#"/>
            and status = 'C'
            and frequencia_fechamento is not null
        <cfelse>
            where frequencia_fechamento <> dias_do_ano and status = 'C' and frequencia_fechamento is not null
        </cfif>
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "vip">
        where produto like '%vip%' and status = 'C'
    </cfif>
    <cfif len(trim(URL.periodo)) AND URL.periodo EQ "confirmados">
        where status = 'C'
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
    where nome is not null
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
</cfquery>
<cfset desafiosAddQueryTiming("qStatsBase", VARIABLES.desafiosQueryStart, qStatsBase.recordcount, "qoq")/>

<cfif VARIABLES.challengeIsCatarinenseCircuit>
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
        ORDER BY distancia_percorrida DESC, data_nascimento ASC, nome
    </cfquery>
    <cfquery name="qCatarinenseMale" dbtype="query">
        SELECT *
        FROM qStatsBase
        WHERE genero = 'MASCULINO'
        ORDER BY distancia_percorrida DESC, data_nascimento ASC, nome
    </cfquery>
    <cfquery name="qCatarinenseUninformed" dbtype="query">
        SELECT *
        FROM qStatsBase
        WHERE genero = 'NAO INFORMADO'
        ORDER BY distancia_percorrida DESC, data_nascimento ASC, nome
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
