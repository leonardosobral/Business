<cfprocessingdirective pageencoding="utf-8"/>
<cfif NOT isDefined("VARIABLES.requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed>
    <cfheader statuscode="403"/>
    <cfabort/>
</cfif>

<cfset VARIABLES.focoPointPageSize = 30/>
<cfset VARIABLES.focoPointOffset = (URL.pagina_pontos - 1) * VARIABLES.focoPointPageSize/>
<cfset VARIABLES.focoShowPendencias = URL.atleta EQ 0 AND NOT len(URL.busca_pontos)/>

<cfquery name="qFocoPointRows" timeout="8">
    WITH configuracao AS (
        SELECT data_inicio,
               data_fim,
               (now() AT TIME ZONE 'America/Sao_Paulo')::date AS hoje,
               trim(BOTH '"' FROM jsonb_path_query_first(
                   jsonb_build_object('data', regexp_replace(
                       substring(to_jsonb(evento)->'config_painel'->>'envio_pontos_desde'
                           FROM '^[0-9]{4}-[0-9]{2}-[0-9]{2}[Tt][0-9]{2}:[0-9]{2}:[0-9]{2}(?:[.][0-9]+)?(?:[Zz]|[+]00:00)$'),
                       '[Zz]$', '+00:00'
                   )),
                   '$.data.datetime()', '{}'::jsonb, true
               )::text)::timestamptz AS envio_desde
        FROM public.desafios_eventos evento
        WHERE tag = 'foco'
        ORDER BY id_desafio DESC
        LIMIT 1
    ),
    inscritos AS (
        SELECT id_usuario,
               bool_or(status = 'C') AS confirmado,
               min(data_inscricao::date) FILTER (WHERE status = 'C') AS dia_inscricao
        FROM public.desafios
        WHERE desafio = 'foco'
        <cfif URL.atleta GT 0>
            AND id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.atleta#"/>
        <cfelseif NOT VARIABLES.focoShowPendencias>
            AND false
        </cfif>
        GROUP BY id_usuario
    ),
    pontos AS (
        SELECT ponto.id_usuario,
               ponto.activity_date AS dia,
               ponto.attempted_at AS ultima_tentativa,
               coalesce(ponto.last_http_status, 0) AS retorno_http,
               ponto.attempts AS tentativas,
               ponto.delivered_at AS confirmado_em,
               CASE
                   WHEN ponto.status = 'sent' AND ponto.delivered_at IS NOT NULL
                     AND ponto.last_http_status BETWEEN 200 AND 299 THEN 'confirmado'
                   WHEN ponto.status IN ('pending', 'sending', 'retry') THEN 'fila'
                   WHEN ponto.status = 'review' AND ponto.last_http_status = 408 THEN 'revisao_408'
                   WHEN ponto.status = 'rejected' AND ponto.last_http_status = 404 THEN 'rejeitado_404'
                   WHEN ponto.status = 'rejected' THEN 'rejeitado_outros'
                   ELSE 'revisao_outros'
               END AS motivo
        FROM public.tb_strava_foco_points ponto
        JOIN inscritos ON inscritos.id_usuario = ponto.id_usuario

        UNION ALL

        SELECT inscrito.id_usuario,
               config.hoje - dia.indice AS dia,
               NULL::timestamptz AS ultima_tentativa,
               0 AS retorno_http,
               0 AS tentativas,
               NULL::timestamptz AS confirmado_em,
               'sem_envio' AS motivo
        FROM configuracao config
        CROSS JOIN generate_series(0, 29) AS dia(indice)
        JOIN inscritos inscrito ON (config.hoje - dia.indice)
            BETWEEN greatest(inscrito.dia_inscricao, config.data_inicio) AND least(config.hoje, config.data_fim)
        JOIN public.tb_usuarios usuario ON usuario.id = inscrito.id_usuario
        WHERE config.envio_desde IS NOT NULL
          AND inscrito.confirmado
          AND usuario.strava_id > 0
          AND NOT EXISTS (
              SELECT 1
              FROM public.tb_strava_foco_points ponto
              WHERE ponto.id_usuario = inscrito.id_usuario
                AND ponto.activity_date = config.hoje - dia.indice
          )
          AND EXISTS (
              SELECT 1
              FROM public.tb_strava_activities atividade
              WHERE atividade.athlete_id = usuario.strava_id
                AND atividade.activity_date = config.hoje - dia.indice
                AND atividade.processed IS TRUE
                AND atividade.activity_source = 'strava'
                AND atividade.resource_state >= 2
                AND atividade.strava_raw->>'aspect_type' IS DISTINCT FROM 'delete'
                AND trim(BOTH '"' FROM jsonb_path_query_first(
                    jsonb_build_object('data', regexp_replace(
                        atividade.strava_raw->>'start_date', '[Zz]$', '+00:00'
                    )),
                    '$.data.datetime()', '{}'::jsonb, true
                )::text)::timestamptz >= config.envio_desde
          )
    ),
    filtrados AS (
        SELECT pontos.*
        FROM pontos
        <cfif VARIABLES.focoShowPendencias>
            WHERE pontos.motivo <> 'confirmado'
            <cfif len(URL.motivo) AND URL.motivo NEQ "todas">
                AND pontos.motivo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.motivo#"/>
            </cfif>
        </cfif>
    ),
    pagina AS (
        SELECT filtrados.*,
               count(*) OVER () AS total_registros,
               row_number() OVER (ORDER BY dia DESC, ultima_tentativa DESC NULLS LAST, id_usuario) AS ordem
        FROM filtrados
        ORDER BY ordem
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoPointPageSize#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.focoPointOffset#"/>
    )
    SELECT 'pendencia' AS tipo,
           motivo,
           0 AS id_usuario,
           '' AS nome,
           '' AS data_atividade,
           '' AS ultima_tentativa,
           0 AS retorno_http,
           0 AS tentativas,
           '' AS confirmado_em,
           count(*) AS total_registros,
           0::bigint AS ordem
    FROM pontos
    WHERE motivo <> 'confirmado'
    <cfif NOT VARIABLES.focoShowPendencias>
        AND false
    </cfif>
    GROUP BY motivo

    UNION ALL

    SELECT 'config', '', 0, '', '', '', 0, 0, '', count(*), 0
    FROM configuracao
    WHERE envio_desde IS NOT NULL

    UNION ALL

    SELECT 'total', '', 0, '', '', '', 0, 0, '', count(*), 0
    FROM filtrados

    UNION ALL

    SELECT 'linha',
           pg.motivo,
           pg.id_usuario,
           coalesce(nullif(trim(usuario.name), ''), 'Atleta ' || pg.id_usuario),
           to_char(pg.dia, 'DD/MM/YYYY'),
           coalesce(to_char(pg.ultima_tentativa AT TIME ZONE 'America/Sao_Paulo', 'DD/MM/YYYY "às" HH24:MI'), ''),
           pg.retorno_http,
           pg.tentativas,
           coalesce(to_char(pg.confirmado_em AT TIME ZONE 'America/Sao_Paulo', 'DD/MM/YYYY "às" HH24:MI'), ''),
           pg.total_registros,
           pg.ordem
    FROM pagina pg
    JOIN public.tb_usuarios usuario ON usuario.id = pg.id_usuario
</cfquery>

<cfquery name="qFocoPendenciasTotais" dbtype="query">
    SELECT motivo, total_registros AS total
    FROM qFocoPointRows
    WHERE tipo = 'pendencia'
</cfquery>

<cfquery name="qFocoPointMeta" dbtype="query">
    SELECT tipo, total_registros
    FROM qFocoPointRows
    WHERE tipo IN ('config', 'total')
</cfquery>
<cfset VARIABLES.focoGapEnabled = false/>
<cfset VARIABLES.focoPointFilteredTotal = 0/>
<cfloop query="qFocoPointMeta">
    <cfif qFocoPointMeta.tipo EQ "config">
        <cfset VARIABLES.focoGapEnabled = qFocoPointMeta.total_registros GT 0/>
    <cfelse>
        <cfset VARIABLES.focoPointFilteredTotal = qFocoPointMeta.total_registros/>
    </cfif>
</cfloop>

<cfquery name="qFocoPointPage" dbtype="query">
    SELECT motivo, id_usuario, nome, data_atividade, ultima_tentativa,
           retorno_http, tentativas, confirmado_em, total_registros, ordem
    FROM qFocoPointRows
    WHERE tipo = 'linha'
    ORDER BY ordem
</cfquery>
<cfset VARIABLES.focoPointColumns = "motivo,id_usuario,nome,data_atividade,ultima_tentativa,retorno_http,tentativas,confirmado_em,total_registros"/>
<cfset qFocoPendenciasLista = URL.atleta GT 0 ? queryNew(VARIABLES.focoPointColumns) : qFocoPointPage/>
<cfset qFocoHistorico = URL.atleta GT 0 ? qFocoPointPage : queryNew(VARIABLES.focoPointColumns)/>

<cfset qFocoAtleta = queryNew("id_usuario,nome")/>
<cfif URL.atleta GT 0>
    <cfquery name="qFocoAtleta" timeout="5">
        SELECT usuario.id AS id_usuario,
               coalesce(nullif(trim(usuario.name), ''), 'Atleta ' || usuario.id) AS nome
        FROM public.tb_usuarios usuario
        WHERE usuario.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.atleta#"/>
          AND EXISTS (
              SELECT 1
              FROM public.desafios inscrito
              WHERE inscrito.id_usuario = usuario.id AND inscrito.desafio = 'foco'
          )
    </cfquery>
</cfif>

<cfset qFocoBuscaAtletas = queryNew("id_usuario,nome")/>
<cfif len(URL.busca_pontos)>
    <cfquery name="qFocoBuscaAtletas" timeout="5">
        WITH inscritos AS (
            SELECT DISTINCT id_usuario
            FROM public.desafios
            WHERE desafio = 'foco'
        )
        SELECT usuario.id AS id_usuario,
               coalesce(nullif(trim(usuario.name), ''), 'Atleta ' || usuario.id) AS nome
        FROM inscritos
        JOIN public.tb_usuarios usuario ON usuario.id = inscritos.id_usuario
        WHERE
        <cfif reFind("^[0-9]+$", URL.busca_pontos)>
            usuario.id::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.busca_pontos#"/>
        <cfelse>
            strpos(lower(unaccent(coalesce(usuario.name, ''))),
                   lower(unaccent(<cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.busca_pontos#"/>))) > 0
        </cfif>
        ORDER BY nome, id_usuario
        LIMIT 25
    </cfquery>
</cfif>
