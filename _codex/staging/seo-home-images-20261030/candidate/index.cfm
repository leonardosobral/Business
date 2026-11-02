<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/"/>
<cfset VARIABLES.routeKey = "home"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<cfparam name="URL.busca" default=""/>
<cfparam name="URL.termo" default=""/>
<cfparam name="URL.distancia_inicio" default=""/>
<cfparam name="URL.distancia_fim" default=""/>
<cfparam name="URL.distancia" default="1,42"/>
<cfparam name="URL.tempo" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>
<cfparam name="URL.estados" default=""/>
<cfparam name="URL.periodo_inicio" default=""/>
<cfparam name="URL.periodo_fim" default=""/>
<cfparam name="URL.busca_mode" default="ai"/>
<cfparam name="URL.busca_tipo" default="todos"/>
<cfparam name="FORM.busca" default=""/>
<cfparam name="FORM.termo" default=""/>
<cfset VARIABLES.termoBuscaDisplay = ""/>

<!--- VARIAVEIS --->
<cfinclude template="includes/estrutura/variaveis.cfm"/>
<cfscript>
if (len(trim(URL.distancia_inicio)) || len(trim(URL.distancia_fim))) {
    VARIABLES.distanciaInicial = [
        len(trim(URL.distancia_inicio)) ? val(URL.distancia_inicio) : 1,
        len(trim(URL.distancia_fim)) ? val(URL.distancia_fim) : 42
    ];
} else {
    VARIABLES.distanciaInicial = len(trim(URL.distancia)) ? listToArray(URL.distancia) : [1, 42];
}

if (len(trim(URL.periodo_inicio)) || len(trim(URL.periodo_fim))) {
    VARIABLES.tempoInicial = [0, 12];
} else {
    VARIABLES.tempoInicial = len(trim(URL.tempo)) ? listToArray(URL.tempo) : [0, 12];
}

VARIABLES.ruaInicial = isBoolean(URL.rua) ? javacast("boolean", URL.rua) : javacast("boolean", compareNoCase(trim(URL.rua), "true") EQ 0);
VARIABLES.trailInicial = isBoolean(URL.trail) ? javacast("boolean", URL.trail) : javacast("boolean", compareNoCase(trim(URL.trail), "true") EQ 0);
VARIABLES.nacionalInicial = isBoolean(URL.nacional) ? javacast("boolean", URL.nacional) : javacast("boolean", compareNoCase(trim(URL.nacional), "true") EQ 0);
VARIABLES.internacionalInicial = isBoolean(URL.internacional) ? javacast("boolean", URL.internacional) : javacast("boolean", compareNoCase(trim(URL.internacional), "true") EQ 0);
VARIABLES.cupomInicial = isBoolean(URL.cupom) ? javacast("boolean", URL.cupom) : javacast("boolean", compareNoCase(trim(URL.cupom), "true") EQ 0);
</cfscript>

 <!--- LOCATION --->
<cfinclude template="includes/location.cfm"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend.cfm"/>
<cfinclude template="includes/backend/backend_login.cfm"/>
<cfinclude template="includes/estrutura/home_discovery_copy.cfm"/>
<cfinclude template="includes/backend/backend_conteudo_canais.cfm"/>
<cfset REQUEST.currentRouteKey = VARIABLES.routeKey/>
<cfset REQUEST.currentRouteParams = {} />

<cfquery name="qEventosTotalBase" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#" result="qEventosTotalBaseMeta">
    SELECT count(*) as total_eventos_base
    FROM vw_evento_corridas
</cfquery>
<cfset logQueryDebug("qEventosTotalBase", qEventosTotalBaseMeta, "home/total_base", "1h", qEventosTotalBase)/>

<cfset VARIABLES.homeContextUf = VARIABLES.uf>
<cfset VARIABLES.homeContextCity = len(trim(VARIABLES.cidade & "")) ? trim(VARIABLES.cidade & "") : "">
<cfset VARIABLES.homeContextLabel = VARIABLES.estado>
<cfset VARIABLES.homeContextFonte = "estado detectado">
<cfset VARIABLES.homeContextFallback = false>
<cfset VARIABLES.homeNoResults = false>

<cfif REQUEST.Usuario.logado AND len(trim(REQUEST.Usuario.estado)) AND REQUEST.Usuario.estado NEQ "BR">
    <cfset VARIABLES.homeContextUf = REQUEST.Usuario.estado>
    <cfif len(trim(REQUEST.Usuario.cidade & ""))>
        <cfset VARIABLES.homeContextCity = trim(REQUEST.Usuario.cidade & "")>
    </cfif>
    <cfset VARIABLES.homeContextLabel = len(trim(REQUEST.Usuario.cidade)) ? "#REQUEST.Usuario.cidade# - #REQUEST.Usuario.estado#" : getEstadoNome(REQUEST.Usuario.estado)>
    <cfset VARIABLES.homeContextFonte = "perfil do atleta">
<cfelseif len(trim(VARIABLES.uf)) AND VARIABLES.uf NEQ "BR">
    <cfset VARIABLES.homeContextUf = VARIABLES.uf>
    <cfif len(trim(VARIABLES.cidade & ""))>
        <cfset VARIABLES.homeContextCity = trim(VARIABLES.cidade & "")>
    </cfif>
    <cfset VARIABLES.homeContextLabel = VARIABLES.estado>
    <cfset VARIABLES.homeContextFonte = "estado detectado">
<cfelse>
    <cfset VARIABLES.homeContextUf = "">
    <cfset VARIABLES.homeContextCity = "">
    <cfset VARIABLES.homeContextLabel = "Brasil">
    <cfset VARIABLES.homeContextFonte = "base nacional">
</cfif>

<cfset VARIABLES.homeQueryCacheTtl = structKeyExists(REQUEST, "currentEnvironment") AND REQUEST.currentEnvironment EQ "dev" ? CreateTimeSpan(0, 0, 1, 0) : CreateTimeSpan(0, 0, 5, 0)/>
<cfset VARIABLES.homeQueryCacheLabel = structKeyExists(REQUEST, "currentEnvironment") AND REQUEST.currentEnvironment EQ "dev" ? "1min dev" : "5min"/>
<cfset VARIABLES.homeSpotlightCacheTtl = structKeyExists(REQUEST, "currentEnvironment") AND REQUEST.currentEnvironment EQ "dev" ? CreateTimeSpan(0, 0, 1, 0) : CreateTimeSpan(0, 0, 10, 0)/>
<cfset VARIABLES.homeSpotlightCacheLabel = structKeyExists(REQUEST, "currentEnvironment") AND REQUEST.currentEnvironment EQ "dev" ? "1min dev" : "10min"/>

<cfquery name="qEventosDestaqueHome" cachedwithin="#VARIABLES.homeSpotlightCacheTtl#" result="qEventosDestaqueHomeMeta">
    WITH historico AS (
        SELECT DISTINCT ON (
            COALESCE(NULLIF(evt.id_agrega_evento, 0), evt.id_evento),
            UPPER(COALESCE(evt.cidade, '')),
            UPPER(COALESCE(evt.estado, '')),
            UPPER(COALESCE(evt.pais, 'BR'))
        )
            COALESCE(NULLIF(evt.id_agrega_evento, 0), evt.id_evento) AS serie_id,
            UPPER(COALESCE(evt.cidade, '')) AS cidade_ref,
            UPPER(COALESCE(evt.estado, '')) AS estado_ref,
            UPPER(COALESCE(evt.pais, 'BR')) AS pais_ref,
            COALESCE(evt.concluintes, 0) AS concluintes_ultima_edicao
        FROM vw_evento_corridas evt
        WHERE evt.data_final < CURRENT_DATE
        AND COALESCE(evt.concluintes, 0) > 0
        ORDER BY
            COALESCE(NULLIF(evt.id_agrega_evento, 0), evt.id_evento),
            UPPER(COALESCE(evt.cidade, '')),
            UPPER(COALESCE(evt.estado, '')),
            UPPER(COALESCE(evt.pais, 'BR')),
            evt.data_final DESC,
            evt.id_evento DESC
    ),
    base AS (
        SELECT
            evt.id_evento,
            evt.nome_evento,
            evt.cidade,
            evt.estado,
            evt.pais,
            evt.categorias,
            evt.data_inicial,
            evt.data_final,
            evt.tag,
            evt.destaque,
            evt.tipo_corrida,
            evt.url_inscricao,
            evt.url_resultado,
            evt.status_evento,
            evt.id_tema,
            evt.id_agrega_evento,
            evt.badges,
            evt.concluintes,
            evt.lista_percursos,
            evt.max_percurso,
            evt.cupom,
            eve.url_imagem,
            eve.url_imagem_listagem,
            COALESCE(NULLIF(evt.id_agrega_evento, 0), evt.id_evento) AS serie_id,
            (evt.data_final - CURRENT_DATE) AS dias_relativos,
            ABS(evt.data_final - CURRENT_DATE) AS distancia_dias,
            COALESCE(NULLIF(evt.concluintes, 0), hist.concluintes_ultima_edicao, 0) AS concluintes_referencia,
            COALESCE(NULLIF(evt.concluintes, 0), hist.concluintes_ultima_edicao, 0) AS porte_base,
            CASE
                WHEN EXISTS (
                    SELECT 1
                    FROM tb_evento_corridas_percursos pcr
                    WHERE pcr.id_evento = evt.id_evento
                    AND FLOOR(pcr.percurso_evento) = 42
                ) THEN 1
                ELSE 0
            END AS tem_42k
        FROM vw_evento_corridas evt
        INNER JOIN tb_evento_corridas eve
            ON eve.id_evento = evt.id_evento
        LEFT JOIN historico hist
            ON hist.serie_id = COALESCE(NULLIF(evt.id_agrega_evento, 0), evt.id_evento)
            AND hist.cidade_ref = UPPER(COALESCE(evt.cidade, ''))
            AND hist.estado_ref = UPPER(COALESCE(evt.estado, ''))
            AND hist.pais_ref = UPPER(COALESCE(evt.pais, 'BR'))
        WHERE LOWER(COALESCE(evt.status_evento, '')) <> 'cancelado'
        AND LOWER(COALESCE(evt.tipo_corrida, '')) <> 'treino'
        <cfif structKeyExists(URL, "cidade") AND len(trim(URL.cidade))>
            AND evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
        </cfif>
        <cfif URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida = 'rua'
        </cfif>
        <cfif NOT URL.rua AND URL.trail>
            AND evt.tipo_corrida = 'trail'
        </cfif>
        <cfif NOT URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida <> 'rua' AND evt.tipo_corrida <> 'trail'
        </cfif>
        <cfif URL.nacional AND NOT URL.internacional>
            AND evt.pais = 'BR'
        </cfif>
        <cfif NOT URL.nacional AND URL.internacional>
            AND evt.pais <> 'BR'
        </cfif>
        <cfif NOT URL.nacional AND NOT URL.internacional>
            AND evt.pais = ''
        </cfif>
    ),
    ranqueados AS (
        SELECT
            base.*,
            base.distancia_dias AS score_total,
            ROW_NUMBER() OVER (
                PARTITION BY base.serie_id
                ORDER BY
                    base.distancia_dias ASC,
                    CASE WHEN base.data_final >= CURRENT_DATE THEN 0 ELSE 1 END ASC,
                    base.concluintes_referencia DESC,
                    base.tem_42k DESC,
                    base.data_final DESC
            ) AS serie_posicao
        FROM base
        WHERE (
            LOWER(COALESCE(base.destaque, '')) = 'nacional'
            OR (base.tem_42k = 1 AND base.concluintes_referencia >= 3000)
            OR base.concluintes_referencia > 15000
        )
        AND base.data_final BETWEEN (CURRENT_DATE - 5) AND (CURRENT_DATE + 180)
    )
    SELECT *
    FROM ranqueados
    WHERE serie_posicao = 1
    ORDER BY distancia_dias ASC,
             CASE WHEN data_final >= CURRENT_DATE THEN 0 ELSE 1 END ASC,
             data_final ASC,
             concluintes_referencia DESC
    LIMIT 12
</cfquery>
<cfset logQueryDebug("qEventosDestaqueHome", qEventosDestaqueHomeMeta, "home/eventos_destaque_carrossel", VARIABLES.homeSpotlightCacheLabel, qEventosDestaqueHome)/>

<cfif len(trim(VARIABLES.homeContextUf))>
    <cfquery name="qEventos" cachedwithin="#VARIABLES.homeQueryCacheTtl#" result="qEventosMeta">
        SELECT evt.*,
               (SELECT sum(res.concluintes)
                FROM tb_resultados_resumo res
                WHERE res.id_evento = evt.id_evento) as concluintes,
               (SELECT
                    json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida,'mapa',mapa) order by percurso_evento)
                FROM tb_evento_corridas_percursos pcr
                WHERE pcr.id_evento = evt.id_evento
               ) as lista_percursos,
               (SELECT condicoes
                FROM vw_evento_corridas_cupom
                WHERE ((id_evento_agrega = evt.id_evento AND tipo_evento = 1)
                    OR (id_evento_agrega = evt.id_agrega_evento AND tipo_evento = 2))
                AND current_date between data_validade_inicio and data_validade_fim
               ) as cupom
        FROM vw_evento_corridas evt
        WHERE evt.data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
        <cfif Len(trim(URL.tempo))>
            AND evt.data_final between <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
                                   and <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+ListLast(URL.tempo)*30, 'yyyy-mm-dd')#"/>
        </cfif>
        <cfif structKeyExists(URL, "cidade") AND len(trim(URL.cidade))>
            AND evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
        </cfif>
        <cfif URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida = 'rua'
        </cfif>
        <cfif URL.cupom>
            AND EXISTS (
                SELECT 1
                FROM vw_evento_corridas_cupom cup
                WHERE ((cup.id_evento_agrega = evt.id_evento AND cup.tipo_evento = 1)
                    OR (cup.id_evento_agrega = evt.id_agrega_evento AND cup.tipo_evento = 2))
                AND current_date between cup.data_validade_inicio and cup.data_validade_fim
            )
        </cfif>
        <cfif NOT URL.rua AND URL.trail>
            AND evt.tipo_corrida = 'trail'
        </cfif>
        <cfif NOT URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida <> 'rua' AND evt.tipo_corrida <> 'trail'
        </cfif>
        <cfif URL.nacional AND NOT URL.internacional>
            AND evt.pais = 'BR'
        </cfif>
        <cfif NOT URL.nacional AND URL.internacional>
            AND evt.pais <> 'BR'
        </cfif>
        <cfif NOT URL.nacional AND NOT URL.internacional>
            AND evt.pais = ''
        </cfif>
        AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(VARIABLES.homeContextUf)#"/>
        ORDER BY evt.data_final, evt.destaque NULLS LAST, evt.id_tema DESC, evt.id_agrega_evento DESC, evt.max_percurso DESC NULLS LAST, evt.tipo_corrida
        LIMIT 12
    </cfquery>
    <cfset logQueryDebug("qEventos", qEventosMeta, "home/eventos_regiao", VARIABLES.homeQueryCacheLabel, qEventos)/>

    <cfif NOT qEventos.recordcount>
        <cfset VARIABLES.homeContextFallback = true>
        <cfset VARIABLES.homeNoResults = true>
        <cfquery name="qEventos" cachedwithin="#VARIABLES.homeQueryCacheTtl#" result="qEventosMeta">
            SELECT evt.*,
                   (SELECT sum(res.concluintes)
                    FROM tb_resultados_resumo res
                    WHERE res.id_evento = evt.id_evento) as concluintes,
                   (SELECT
                        json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida,'mapa',mapa) order by percurso_evento)
                    FROM tb_evento_corridas_percursos pcr
                    WHERE pcr.id_evento = evt.id_evento
                   ) as lista_percursos,
                   (SELECT condicoes
                    FROM vw_evento_corridas_cupom
                    WHERE ((id_evento_agrega = evt.id_evento AND tipo_evento = 1)
                        OR (id_evento_agrega = evt.id_agrega_evento AND tipo_evento = 2))
                    AND current_date between data_validade_inicio and data_validade_fim
                   ) as cupom
            FROM vw_evento_corridas evt
            WHERE evt.data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
            <cfif Len(trim(URL.tempo))>
                AND evt.data_final between <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
                                       and <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+ListLast(URL.tempo)*30, 'yyyy-mm-dd')#"/>
            </cfif>
            <cfif structKeyExists(URL, "cidade") AND len(trim(URL.cidade))>
                AND evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
            </cfif>
            <cfif URL.rua AND NOT URL.trail>
                AND evt.tipo_corrida = 'rua'
            </cfif>
            <cfif URL.cupom>
                AND EXISTS (
                    SELECT 1
                    FROM vw_evento_corridas_cupom cup
                    WHERE ((cup.id_evento_agrega = evt.id_evento AND cup.tipo_evento = 1)
                        OR (cup.id_evento_agrega = evt.id_agrega_evento AND cup.tipo_evento = 2))
                    AND current_date between cup.data_validade_inicio and cup.data_validade_fim
                )
            </cfif>
            <cfif NOT URL.rua AND URL.trail>
                AND evt.tipo_corrida = 'trail'
            </cfif>
            <cfif NOT URL.rua AND NOT URL.trail>
                AND evt.tipo_corrida <> 'rua' AND evt.tipo_corrida <> 'trail'
            </cfif>
            <cfif URL.nacional AND NOT URL.internacional>
                AND evt.pais = 'BR'
            </cfif>
            <cfif NOT URL.nacional AND URL.internacional>
                AND evt.pais <> 'BR'
            </cfif>
            <cfif NOT URL.nacional AND NOT URL.internacional>
                AND evt.pais = ''
            </cfif>
            ORDER BY evt.data_final, evt.destaque NULLS LAST, evt.id_tema DESC, evt.id_agrega_evento DESC, evt.max_percurso DESC NULLS LAST, evt.tipo_corrida
            LIMIT 12
        </cfquery>
        <cfset logQueryDebug("qEventos", qEventosMeta, "home/eventos_nacional", VARIABLES.homeQueryCacheLabel, qEventos)/>
    </cfif>
<cfelse>
    <cfset VARIABLES.homeNoResults = true>
    <cfquery name="qEventos" cachedwithin="#VARIABLES.homeQueryCacheTtl#" result="qEventosMeta">
        SELECT evt.*,
               (SELECT sum(res.concluintes)
                FROM tb_resultados_resumo res
                WHERE res.id_evento = evt.id_evento) as concluintes,
               (SELECT
                    json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida,'mapa',mapa) order by percurso_evento)
                FROM tb_evento_corridas_percursos pcr
                WHERE pcr.id_evento = evt.id_evento
               ) as lista_percursos,
               (SELECT condicoes
                FROM vw_evento_corridas_cupom
                WHERE ((id_evento_agrega = evt.id_evento AND tipo_evento = 1)
                    OR (id_evento_agrega = evt.id_agrega_evento AND tipo_evento = 2))
                AND current_date between data_validade_inicio and data_validade_fim
               ) as cupom
        FROM vw_evento_corridas evt
        WHERE evt.data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
        <cfif Len(trim(URL.tempo))>
            AND evt.data_final between <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
                                   and <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+ListLast(URL.tempo)*30, 'yyyy-mm-dd')#"/>
        </cfif>
        <cfif structKeyExists(URL, "cidade") AND len(trim(URL.cidade))>
            AND evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
        </cfif>
        <cfif URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida = 'rua'
        </cfif>
        <cfif URL.cupom>
            AND EXISTS (
                SELECT 1
                FROM vw_evento_corridas_cupom cup
                WHERE ((cup.id_evento_agrega = evt.id_evento AND cup.tipo_evento = 1)
                    OR (cup.id_evento_agrega = evt.id_agrega_evento AND cup.tipo_evento = 2))
                AND current_date between cup.data_validade_inicio and cup.data_validade_fim
            )
        </cfif>
        <cfif NOT URL.rua AND URL.trail>
            AND evt.tipo_corrida = 'trail'
        </cfif>
        <cfif NOT URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida <> 'rua' AND evt.tipo_corrida <> 'trail'
        </cfif>
        <cfif URL.nacional AND NOT URL.internacional>
            AND evt.pais = 'BR'
        </cfif>
        <cfif NOT URL.nacional AND URL.internacional>
            AND evt.pais <> 'BR'
        </cfif>
        <cfif NOT URL.nacional AND NOT URL.internacional>
            AND evt.pais = ''
        </cfif>
        ORDER BY evt.data_final, evt.destaque NULLS LAST, evt.id_tema DESC, evt.id_agrega_evento DESC, evt.max_percurso DESC NULLS LAST, evt.tipo_corrida
        LIMIT 12
    </cfquery>
    <cfset logQueryDebug("qEventos", qEventosMeta, "home/eventos_base", VARIABLES.homeQueryCacheLabel, qEventos)/>
</cfif>

<cfif NOT isDefined("qEventos") OR qEventos.recordcount EQ 0>
    <cfset VARIABLES.homeNoResults = true>
</cfif>

<!--- PRESERVA O CONTEXTO EFETIVO DA LISTA NO CALENDARIO E NA SIDEBAR ASSINCRONA --->
<cfinclude template="includes/estrutura/event_calendar_link.cfm"/>
<cfscript>
REQUEST.homeCalendarParams = {
    "context_uf" = VARIABLES.homeContextFallback || !len(trim(VARIABLES.homeContextUf)) ? "BR" : VARIABLES.homeContextUf
};
for (homeCalendarFilter in ["tempo", "cidade", "rua", "trail", "nacional", "internacional", "cupom"]) {
    if (structKeyExists(URL, homeCalendarFilter)) REQUEST.homeCalendarParams[homeCalendarFilter] = URL[homeCalendarFilter];
}
VARIABLES.homeCalendarUrl = REQUEST.buildEventCalendarLink(REQUEST.homeCalendarParams);
VARIABLES.homeSidebarCalendarUrl = "/api/home_sidebar.cfm?suggestions=0&i18n_lang=" & urlEncodedFormat(REQUEST.lang)
    & "&" & listRest(VARIABLES.homeCalendarUrl, "?");
</cfscript>

<cfset VARIABLES.apiConteudoBase = "https://conteudo.roadrunners.run"/>
<cfset REQUEST.homeSidebarNoticias = []>
<cfset REQUEST.homeSidebarNoticiasOverride = true>

<cfset VARIABLES.homeResultadosContextFallback = false>
<cfset VARIABLES.homeResultadosNoResults = false>

<cfif len(trim(VARIABLES.homeContextUf))>
    <cfquery name="qEventosResultadosHome" cachedwithin="#VARIABLES.homeQueryCacheTtl#" result="qEventosResultadosHomeMeta">
        SELECT evt.*,
               EXISTS (
                    SELECT 1
                    FROM tb_badges bd
                    WHERE bd.id_evento = evt.id_evento
                    AND bd.badge = 'foco'
               ) as has_foco_photos
        FROM vw_evento_corridas evt
        WHERE evt.data_final < <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
        AND COALESCE(evt.concluintes, 0) > 0
        <cfif structKeyExists(URL, "cidade") AND len(trim(URL.cidade))>
            AND evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
        </cfif>
        <cfif URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida = 'rua'
        </cfif>
        <cfif NOT URL.rua AND URL.trail>
            AND evt.tipo_corrida = 'trail'
        </cfif>
        <cfif NOT URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida <> 'rua' AND evt.tipo_corrida <> 'trail'
        </cfif>
        <cfif URL.nacional AND NOT URL.internacional>
            AND evt.pais = 'BR'
        </cfif>
        <cfif NOT URL.nacional AND URL.internacional>
            AND evt.pais <> 'BR'
        </cfif>
        <cfif NOT URL.nacional AND NOT URL.internacional>
            AND evt.pais = ''
        </cfif>
        AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(VARIABLES.homeContextUf)#"/>
        ORDER BY evt.data_final DESC, evt.destaque NULLS LAST, evt.id_tema DESC, evt.id_agrega_evento DESC, evt.max_percurso DESC NULLS LAST
        LIMIT 12
    </cfquery>
    <cfset logQueryDebug("qEventosResultadosHome", qEventosResultadosHomeMeta, "home/eventos_resultados_regiao", VARIABLES.homeQueryCacheLabel, qEventosResultadosHome)/>

    <cfif NOT qEventosResultadosHome.recordcount>
        <cfset VARIABLES.homeResultadosContextFallback = true>
        <cfquery name="qEventosResultadosHome" cachedwithin="#VARIABLES.homeQueryCacheTtl#" result="qEventosResultadosHomeMeta">
            SELECT evt.*,
                   EXISTS (
                        SELECT 1
                        FROM tb_badges bd
                        WHERE bd.id_evento = evt.id_evento
                        AND bd.badge = 'foco'
                   ) as has_foco_photos
            FROM vw_evento_corridas evt
            WHERE evt.data_final < <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
            AND COALESCE(evt.concluintes, 0) > 0
            <cfif structKeyExists(URL, "cidade") AND len(trim(URL.cidade))>
                AND evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
            </cfif>
            <cfif URL.rua AND NOT URL.trail>
                AND evt.tipo_corrida = 'rua'
            </cfif>
            <cfif NOT URL.rua AND URL.trail>
                AND evt.tipo_corrida = 'trail'
            </cfif>
            <cfif NOT URL.rua AND NOT URL.trail>
                AND evt.tipo_corrida <> 'rua' AND evt.tipo_corrida <> 'trail'
            </cfif>
            <cfif URL.nacional AND NOT URL.internacional>
                AND evt.pais = 'BR'
            </cfif>
            <cfif NOT URL.nacional AND URL.internacional>
                AND evt.pais <> 'BR'
            </cfif>
            <cfif NOT URL.nacional AND NOT URL.internacional>
                AND evt.pais = ''
            </cfif>
            ORDER BY evt.data_final DESC, evt.destaque NULLS LAST, evt.id_tema DESC, evt.id_agrega_evento DESC, evt.max_percurso DESC NULLS LAST
            LIMIT 12
        </cfquery>
        <cfset logQueryDebug("qEventosResultadosHome", qEventosResultadosHomeMeta, "home/eventos_resultados_nacional", VARIABLES.homeQueryCacheLabel, qEventosResultadosHome)/>
    </cfif>
<cfelse>
    <cfquery name="qEventosResultadosHome" cachedwithin="#VARIABLES.homeQueryCacheTtl#" result="qEventosResultadosHomeMeta">
        SELECT evt.*,
               EXISTS (
                    SELECT 1
                    FROM tb_badges bd
                    WHERE bd.id_evento = evt.id_evento
                    AND bd.badge = 'foco'
               ) as has_foco_photos
        FROM vw_evento_corridas evt
        WHERE evt.data_final < <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
        AND COALESCE(evt.concluintes, 0) > 0
        <cfif structKeyExists(URL, "cidade") AND len(trim(URL.cidade))>
            AND evt.cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.cidade#"/>
        </cfif>
        <cfif URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida = 'rua'
        </cfif>
        <cfif NOT URL.rua AND URL.trail>
            AND evt.tipo_corrida = 'trail'
        </cfif>
        <cfif NOT URL.rua AND NOT URL.trail>
            AND evt.tipo_corrida <> 'rua' AND evt.tipo_corrida <> 'trail'
        </cfif>
        <cfif URL.nacional AND NOT URL.internacional>
            AND evt.pais = 'BR'
        </cfif>
        <cfif NOT URL.nacional AND URL.internacional>
            AND evt.pais <> 'BR'
        </cfif>
        <cfif NOT URL.nacional AND NOT URL.internacional>
            AND evt.pais = ''
        </cfif>
        ORDER BY evt.data_final DESC, evt.destaque NULLS LAST, evt.id_tema DESC, evt.id_agrega_evento DESC, evt.max_percurso DESC NULLS LAST
        LIMIT 12
    </cfquery>
    <cfset logQueryDebug("qEventosResultadosHome", qEventosResultadosHomeMeta, "home/eventos_resultados_base", VARIABLES.homeQueryCacheLabel, qEventosResultadosHome)/>
</cfif>

<cfif NOT isDefined("qEventosResultadosHome") OR qEventosResultadosHome.recordcount EQ 0>
    <cfset VARIABLES.homeResultadosNoResults = true>
</cfif>

<cfscript>
VARIABLES.homeSpotlightCatalog = structKeyExists(REQUEST, "i18n")
    AND isStruct(REQUEST.i18n)
    AND structKeyExists(REQUEST.i18n, "home")
    AND isStruct(REQUEST.i18n.home)
    AND structKeyExists(REQUEST.i18n.home, "spotlight")
    AND isStruct(REQUEST.i18n.home.spotlight)
    ? duplicate(REQUEST.i18n.home.spotlight)
    : {};

if (!structKeyExists(VARIABLES.homeSpotlightCatalog, "kicker")) {
    switch (REQUEST.lang) {
        case "en":
            VARIABLES.homeSpotlightCatalog = {
                kicker = "Event radar",
                title = "Featured events",
                copy = "A dynamic selection that combines the event's historical strength, date proximity and regional fit to your current context.",
                futureTag = "Upcoming",
                pastTag = "Recent",
                editionsLabel = "{count} historical average",
                finishersLabel = "up to {count}k",
                algorithmNote = "Weighted selection by size, regionality and date proximity.",
                ctaFuture = "View event",
                ctaPast = "View event and results",
                prevAria = "View previous featured events",
                nextAria = "View next featured events"
            };
            break;
        case "es":
            VARIABLES.homeSpotlightCatalog = {
                kicker = "Radar de eventos",
                title = "Eventos destacados",
                copy = "Una selección dinámica que combina la fuerza histórica del evento, la cercanía de la fecha y la afinidad regional con tu contexto actual.",
                futureTag = "Próximo",
                pastTag = "Reciente",
                editionsLabel = "{count} promedio histórico",
                finishersLabel = "hasta {count}k",
                algorithmNote = "Selección ponderada por tamaño, regionalidad y cercanía de la fecha.",
                ctaFuture = "Ver evento",
                ctaPast = "Ver evento y resultados",
                prevAria = "Ver eventos destacados anteriores",
                nextAria = "Ver siguientes eventos destacados"
            };
            break;
        default:
            VARIABLES.homeSpotlightCatalog = {
                kicker = "Radar de eventos",
                title = "Eventos em destaque",
                copy = "Uma seleção dinâmica que combina força histórica do evento, proximidade da data e aderência regional ao seu contexto atual.",
                futureTag = "Próximo",
                pastTag = "Recente",
                editionsLabel = "{count} média histórica",
                finishersLabel = "até {count}k",
                algorithmNote = "Seleção ponderada por porte, regionalidade e proximidade da data.",
                ctaFuture = "Ver evento",
                ctaPast = "Ver evento e resultados",
                prevAria = "Ver eventos anteriores em destaque",
                nextAria = "Ver próximos eventos em destaque"
            };
    }
}
</cfscript>

<cfinclude template="includes/backend/backend_video_destaque.cfm"/>

<cfquery name="qVideosHome" cachedwithin="#VARIABLES.homeQueryCacheTtl#" result="qVideosHomeMeta">
    SELECT media.media_titulo,
           media.media_url,
           media.data_publicacao,
           media.media_canal_nome AS nome_canal_video
    FROM tb_media media
    WHERE media.pub_status = TRUE
    <cfif VARIABLES.homeFeaturedVideoAvailable>
        AND media.id_media <> <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.homeFeaturedVideoId#"/>
    </cfif>
    ORDER BY media.data_publicacao DESC NULLS LAST,
             media.id_media DESC
    LIMIT 3
</cfquery>
<cfset logQueryDebug("qVideosHome", qVideosHomeMeta, "home/videos_recentes", VARIABLES.homeQueryCacheLabel, qVideosHome)/>

<cfscript>
VARIABLES.homeUpcomingRegionLabel = (VARIABLES.homeContextFallback OR NOT len(trim(VARIABLES.homeContextUf)))
    ? REQUEST.homeDiscoveryText("national") : REQUEST.homeDiscoveryText("region", {"region"=getEstadoNome(VARIABLES.homeContextUf)});
VARIABLES.homeResultsRegionLabel = (VARIABLES.homeResultadosContextFallback OR NOT len(trim(VARIABLES.homeContextUf)))
    ? REQUEST.homeDiscoveryText("national") : REQUEST.homeDiscoveryText("region", {"region"=getEstadoNome(VARIABLES.homeContextUf)});
VARIABLES.homePublicResultsUrl = REQUEST.i18nBuildPath("search") & "?busca_tipo=resultados";
if (structKeyExists(REQUEST, "normalizeDisplayQuery")) {
    REQUEST.normalizeDisplayQuery(qEventos, "", "cidade");
    REQUEST.normalizeDisplayQuery(qEventosResultadosHome, "", "cidade");
    REQUEST.normalizeDisplayQuery(qEventosDestaqueHome, "", "cidade");
}
</cfscript>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#REQUEST.i18nBuildAbsoluteUrl(VARIABLES.routeKey)##VARIABLES.queryString#"/>
<cfset VARIABLES.title = REQUEST.t("home.meta.title") & " - O ponto de encontro da corrida."/>
<cfset VARIABLES.description = REQUEST.t("home.meta.description")/>
<cfset VARIABLES.keywords = REQUEST.t("home.meta.keywords")/>

<cfinclude template="includes/estrutura/site_identity.cfm"/>

<!--- HEAD --->
<cfinclude template="includes/estrutura/head.cfm"/>

<body class="rr-home">

    <!--- SEO WEB TOOLS --->

    <cfinclude template="includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .home-shell-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            color: #333333;
        }

        .home-section-caption {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.92rem;
        }

        .home-feedback-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #efefef;
            color: #333333;
        }

        .home-feedback-chip {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0.5rem 0.8rem;
            border-radius: 8px;
            border: 1px solid rgba(51, 51, 51, 0.12);
            background-color: #ffffff;
            color: #333333;
            font-weight: 600;
            font-size: 0.84rem;
            line-height: 1;
            text-decoration: none;
        }

        .home-feedback-chip:hover {
            border-color: #fab120;
            color: #333333;
        }

        .home-async-slot {
            display: grid;
            gap: 0.5rem;
        }

        .home-async-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            padding: 0.75rem;
            overflow: hidden;
        }

        .home-async-card.is-featured {
            min-height: 100%;
        }

        .home-async-card.is-short {
            min-height: 92px;
        }

        .home-async-avatar,
        .home-async-media,
        .home-async-lines span {
            display: block;
            background: linear-gradient(90deg, #efefef 0%, #f8f8f8 48%, #efefef 100%);
            background-size: 220% 100%;
            animation: homeAsyncPulse 1.25s ease-in-out infinite;
        }

        .home-async-avatar {
            width: 48px;
            height: 48px;
            border-radius: 999px;
            margin-bottom: 0.75rem;
        }

        .home-async-media {
            aspect-ratio: 16 / 9;
            border-radius: 9px;
            margin-bottom: 0.75rem;
        }

        .home-async-lines {
            display: grid;
            gap: 0.45rem;
        }

        .home-async-lines span {
            height: 0.72rem;
            border-radius: 999px;
        }

        .home-async-lines span:nth-child(2) {
            width: 78%;
        }

        .home-async-lines span:nth-child(3) {
            width: 58%;
        }

        .home-news-skeleton-card {
            pointer-events: none;
        }

        .home-news-skeleton-card .home-content-card-body {
            display: grid;
            gap: 0.5rem;
        }

        .home-news-skeleton-kicker,
        .home-news-skeleton-title {
            display: block;
            border-radius: 999px;
            background: linear-gradient(90deg, #efefef 0%, #f8f8f8 48%, #efefef 100%);
            background-size: 220% 100%;
            animation: homeAsyncPulse 1.25s ease-in-out infinite;
        }

        .home-news-skeleton-kicker {
            width: 36%;
            height: 0.62rem;
        }

        .home-news-skeleton-title {
            width: 92%;
            height: 0.92rem;
        }

        .home-news-skeleton-title.is-short {
            width: 68%;
        }

        @keyframes homeAsyncPulse {
            0% {
                background-position: 120% 0;
            }

            100% {
                background-position: -120% 0;
            }
        }

        .home-center-stack {
            display: flex;
            flex-direction: column;
            gap: 0.75rem;
        }

        .home-featured-news {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            overflow: hidden;
        }

        .home-spotlight-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
            margin-bottom: 0.55rem;
        }

        .home-spotlight-title {
            display: inline-flex;
            align-items: center;
            color: #333333;
            font-size: 1rem;
            font-weight: 700;
            line-height: 1.25;
            margin: 0;
        }

        .home-spotlight-controls {
            display: inline-flex;
            align-items: center;
            gap: 0.3rem;
            flex: 0 0 auto;
        }

        .home-spotlight-control {
            width: 28px;
            height: 28px;
            border-radius: 999px;
            border: 1px solid rgba(51, 51, 51, 0.08);
            background-color: transparent;
            color: rgba(51, 51, 51, 0.72);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            box-shadow: none;
            transition: transform 0.2s ease, border-color 0.2s ease, color 0.2s ease;
            font-size: 0.72rem;
        }

        .home-spotlight-control:hover {
            border-color: rgba(250, 177, 32, 0.55);
            color: #333333;
            transform: translateY(-1px);
        }

        .home-spotlight-control:disabled {
            opacity: 0.45;
            cursor: default;
            transform: none;
        }

        .home-spotlight-track {
            display: grid;
            grid-auto-flow: column;
            grid-auto-columns: minmax(280px, 32%);
            gap: 0.85rem;
            overflow-x: auto;
            scroll-snap-type: x mandatory;
            scroll-behavior: smooth;
            padding-bottom: 0.35rem;
            scrollbar-width: none;
        }

        .home-spotlight-track::-webkit-scrollbar {
            display: none;
        }

        .home-spotlight-card {
            display: flex;
            flex-direction: column;
            min-width: 0;
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 12px;
            overflow: hidden;
            background: #ffffff;
            color: #333333;
            text-decoration: none;
            scroll-snap-align: start;
        }

        .home-spotlight-card:hover {
            color: #333333;
            border-color: rgba(250, 177, 32, 0.45);
        }

        .home-spotlight-media {
            aspect-ratio: 18 / 8;
            width: 100%;
            object-fit: cover;
            image-rendering: auto;
            display: block;
            background: linear-gradient(135deg, #efefef 0%, #f8e4af 100%);
        }

        .home-spotlight-media-wrap {
            position: relative;
        }

        .home-spotlight-media-wrap.is-image-fallback .home-spotlight-media {
            display: none;
        }

        .home-spotlight-media-wrap.is-image-fallback .home-spotlight-media-placeholder {
            display: flex;
        }

        .home-spotlight-media-placeholder {
            aspect-ratio: 18 / 8;
            display: none;
            align-items: center;
            justify-content: center;
            background:
                radial-gradient(circle at top right, rgba(250, 177, 32, 0.42), transparent 28%),
                linear-gradient(135deg, #f1f1f1 0%, #e5e5e5 100%);
            color: rgba(51, 51, 51, 0.7);
            font-size: 2.4rem;
        }

        .home-spotlight-body {
            display: flex;
            flex-direction: column;
            gap: 0.45rem;
            padding: 0.85rem 0.9rem;
            min-height: 60%;
        }

        .home-spotlight-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.35rem;
            padding: 0.38rem 0.65rem;
            border-radius: 999px;
            font-size: 0.72rem;
            font-weight: 700;
            line-height: 1;
            border: 1px solid rgba(51, 51, 51, 0.08);
            background-color: #ffffff;
        }

        .home-spotlight-badge.is-future {
            background-color: rgba(255, 248, 230, 0.96);
            border-color: rgba(250, 177, 32, 0.28);
        }

        .home-spotlight-badge.is-past {
            background-color: rgba(255, 255, 255, 0.92);
        }

        .home-spotlight-media-wrap .home-spotlight-badge {
            position: absolute;
            bottom: 0.65rem;
            left: 0.65rem;
            z-index: 2;
            box-shadow: 0 2px 8px rgba(17, 17, 17, 0.05);
        }

        .home-spotlight-card-title {
            color: #333333;
            font-size: 1rem;
            font-weight: 700;
            line-height: 1.16;
            margin: 0;
        }

        .home-spotlight-card-meta,
        .home-spotlight-card-support {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.82rem;
            line-height: 1.4;
        }

        .home-spotlight-card-meta i,
        .home-spotlight-card-support i {
            color: #fab120;
        }

        .home-spotlight-card-date {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.8rem;
            line-height: 1.2;
            margin-top: 0;
        }

        .home-spotlight-card-date i {
            color: #fab120;
        }

        @media (max-width: 991.98px) {
            .home-spotlight-track {
                grid-auto-columns: minmax(300px, 68%);
            }
        }

        @media (max-width: 767.98px) {
            .home-spotlight-header {
                gap: 0.65rem;
            }

            .home-spotlight-controls {
                align-self: center;
            }

            .home-spotlight-track {
                grid-auto-columns: 86%;
            }
        }

        .home-featured-news-link {
            display: block;
            color: #333333;
            text-decoration: none;
        }

        .home-featured-news-image {
            width: 100%;
            height: auto;
            object-fit: contain;
            display: block;
            background-color: #efefef;
        }

        .home-featured-news-body {
            padding: 1rem;
        }

        .home-featured-news-kicker {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.8rem;
            font-weight: 700;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            margin-bottom: 0.45rem;
        }

        .home-featured-news-title {
            color: #333333;
            font-size: 1.2rem;
            font-weight: 700;
            line-height: 1.2;
            margin-bottom: 0.55rem;
        }

        .home-featured-news-summary {
            color: rgba(51, 51, 51, 0.78);
            font-size: 0.95rem;
            line-height: 1.55;
            margin: 0;
        }

        .home-content-panel {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            padding: 0.78rem;
        }

        .home-content-panel-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 1rem;
            margin-bottom: 0;
        }

        section[data-home-async="news"] > .home-content-panel-header {
            margin-bottom: 0.55rem;
        }

        .home-content-panel-title {
            color: #333333;
            font-size: 1rem;
            font-weight: 700;
            line-height: 1.25;
            margin: 0;
        }

        .home-content-panel-cta {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.78rem;
            font-weight: 700;
            text-decoration: none;
            white-space: nowrap;
        }

        .home-content-panel-cta:hover {
            color: #333333;
        }

        .home-content-card {
            display: block;
            height: 100%;
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 9px;
            color: #333333;
            overflow: hidden;
            text-decoration: none;
            background: linear-gradient(180deg, #ffffff 0%, #f7f7f7 100%);
        }

        .home-content-card:hover {
            border-color: rgba(250, 177, 32, 0.45);
            color: #333333;
        }

        .home-news-layout .home-content-card {
            background: #ffffff;
        }

        .home-content-card-image {
            aspect-ratio: 16 / 9;
            width: 100%;
            height: auto;
            object-fit: cover;
            display: block;
            background-color: #efefef;
        }

        .home-content-card-media {
            position: relative;
        }

        .home-content-card-media.is-image-fallback .home-content-card-image {
            display: none;
        }

        .home-content-card-media.is-image-fallback .home-content-card-placeholder {
            display: flex;
        }

        .home-content-card-placeholder {
            aspect-ratio: 16 / 9;
            width: 100%;
            display: none;
            align-items: center;
            justify-content: center;
            background:
                radial-gradient(circle at top right, rgba(250, 177, 32, 0.42), transparent 28%),
                linear-gradient(135deg, #f1f1f1 0%, #e5e5e5 100%);
            color: rgba(51, 51, 51, 0.7);
            font-size: 2.2rem;
        }

        .home-content-card-placeholder-logo {
            max-width: 64%;
            max-height: 58%;
            object-fit: contain;
        }

        .home-content-card-placeholder-fallback-icon {
            display: none;
        }

        .home-content-card-body {
            padding: 0.72rem;
        }

        .home-content-card-kicker {
            color: rgba(51, 51, 51, 0.62);
            font-size: 0.72rem;
            font-weight: 700;
            line-height: 1.25;
            margin-bottom: 0.35rem;
        }

        .home-content-card-title {
            color: #333333;
            font-size: 0.92rem;
            font-weight: 700;
            line-height: 1.25;
            margin: 0;
        }

        .home-news-layout {
            display: grid;
            align-items: stretch;
            column-gap: 0.75rem;
            row-gap: 0.75rem;
            grid-template-columns: repeat(3, minmax(0, 1fr));
        }

        .home-news-featured {
            grid-column: span 2;
        }

        .home-featured-video-slot {
            display: flex;
            flex-direction: column;
            grid-column: span 2;
            min-width: 0;
        }

        .home-featured-video-link {
            color: #333333;
            display: block;
            text-decoration: none;
        }

        .home-featured-video-link:hover {
            color: #333333;
        }

        .home-news-top-stack {
            display: grid;
            gap: 0.75rem;
            grid-template-rows: repeat(2, minmax(0, 1fr));
            min-width: 0;
        }

        .home-news-bottom-grid {
            display: grid;
            gap: 0.75rem;
            grid-column: 1 / -1;
            grid-template-columns: repeat(3, minmax(0, 1fr));
        }

        .home-news-top-stack .home-content-card,
        .home-news-bottom-grid .home-content-card {
            min-height: 0;
        }

        .home-content-card.is-featured .home-content-card-body {
            padding: 0.9rem;
        }

        .home-content-card.is-featured .home-content-card-title {
            font-size: 1.25rem;
            line-height: 1.18;
        }

        .home-news-top-stack .home-content-card-body,
        .home-news-bottom-grid .home-content-card-body {
            padding: 0.72rem;
        }

        .home-news-top-stack .home-content-card-title,
        .home-news-bottom-grid .home-content-card-title {
            font-size: 0.92rem;
        }

        .home-news-placeholder .home-news-skeleton-card {
            background: #ffffff;
        }

        .home-news-placeholder .home-content-card-placeholder {
            display: flex;
            background:
                radial-gradient(circle at top right, rgba(250, 177, 32, 0.18), transparent 28%),
                linear-gradient(135deg, #f1f1f1 0%, #e5e5e5 100%);
        }

        @media (max-width: 991.98px) {
            .home-news-layout {
                grid-template-columns: 1fr;
            }

            .home-news-featured,
            .home-featured-video-slot,
            .home-news-bottom-grid {
                grid-column: auto;
            }

            .home-news-bottom-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 767.98px) {
            .home-news-bottom-grid {
                display: none;
            }
        }

        @media (max-width: 575.98px) {
            .home-news-bottom-grid {
                grid-template-columns: 1fr;
            }
        }

        .home-video-thumb-wrap {
            position: relative;
        }

        .home-featured-video-event-card {
            border-top: 1px solid rgba(51, 51, 51, 0.08);
            margin: 0 0.9rem;
            padding: 0.72rem 0 0.9rem;
        }

        .home-video-thumb-wrap::after {
            align-items: center;
            background-color: rgba(255, 255, 255, 0.72);
            border-radius: 999px;
            color: rgba(51, 51, 51, 0.72);
            content: "\f04b";
            display: flex;
            font-family: "Font Awesome 7 Free";
            font-size: 1.45rem;
            font-weight: 900;
            height: 72px;
            justify-content: center;
            left: 50%;
            position: absolute;
            top: 50%;
            transform: translate(-50%, -50%);
            width: 72px;
            box-shadow: 0 10px 20px rgba(17, 17, 17, 0.08);
            line-height: 1;
            padding-left: 0.12rem;
        }

        .home-dual-section {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            padding: 0.78rem;
        }

        .home-dual-section-header {
            margin-bottom: 0.6rem;
        }

        .home-dual-section-title {
            color: #333333;
            font-size: 1rem;
            font-weight: 700;
            line-height: 1.25;
            margin-bottom: 0.2rem;
        }

        .home-dual-section-copy {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.82rem;
            line-height: 1.4;
            margin: 0 0 0.6rem;
        }

        .home-dual-list {
            display: flex;
            flex-direction: column;
            gap: 0;
        }

        @media (max-width: 767.98px) {
            /* Item limits count anchors only; see runnerhub-home.css. */

            .home-mobile-section {
                margin-top: 0.5rem;
            }

            .home-feedback-chip {
                flex: 0 0 auto;
            }

        }
    </style>


    <link rel="stylesheet" href="/assets/css/runnerhub-home.min.css?v=20261013newspeers2" />
    <cfinclude template="includes/estrutura/home_sidebar_shared_styles.cfm"/>

    <!--- CONTAINER DE CONTEUDO --->

    <div class="container">


        <!--- HEADER --->

        <cfinclude template="includes/estrutura/header.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <!--- HERO DE DESCOBERTA --->

        <cfinclude template="includes/estrutura/home_hero_busca.cfm"/>


        <!--- LISTAGEM DE EVENTOS --->

        <div class="row g-2">

            <div class="col-12 col-lg-3 order-1 home-mobile-section home-sidebar-column">

                <cfinclude template="includes/analytics/sidebar_inventory.cfm" />
                <div class="home-async-slot" data-home-async="sidebar" aria-busy="true">
                    <div class="home-async-card">
                        <div class="home-async-avatar"></div>
                        <div class="home-async-lines">
                            <span></span>
                            <span></span>
                            <span></span>
                        </div>
                    </div>
                    <div class="home-async-card is-short">
                        <div class="home-async-lines">
                            <span></span>
                            <span></span>
                        </div>
                    </div>
                </div>

            </div>

            <div class="col-12 col-lg-9 order-2 px-lg-3">
                <div class="home-center-stack">

                    <cfif qEventosDestaqueHome.recordcount>
                        <section aria-label="<cfoutput>#VARIABLES.homeSpotlightCatalog.title#</cfoutput>">
                            <div class="home-spotlight-header">
                                <div class="home-content-panel-title home-spotlight-title"><i class="fa-solid fa-satellite-dish me-2"></i><cfoutput>#VARIABLES.homeSpotlightCatalog.title#</cfoutput></div>
                                <div class="home-spotlight-controls">
                                    <button type="button" class="home-spotlight-control" data-spotlight-prev aria-label="<cfoutput>#VARIABLES.homeSpotlightCatalog.prevAria#</cfoutput>">
                                        <i class="fa-solid fa-arrow-left"></i>
                                    </button>
                                    <button type="button" class="home-spotlight-control" data-spotlight-next aria-label="<cfoutput>#VARIABLES.homeSpotlightCatalog.nextAria#</cfoutput>">
                                        <i class="fa-solid fa-arrow-right"></i>
                                    </button>
                                </div>
                            </div>

                            <div class="home-spotlight-track" data-spotlight-track>
                                <cfoutput query="qEventosDestaqueHome">
                                    <cfset VARIABLES.homeSpotlightCurrentRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
                                    <cfset VARIABLES.homeSpotlightRouteParams = duplicate(VARIABLES.homeSpotlightCurrentRouteParams) />
                                    <cfset VARIABLES.homeSpotlightRouteParams["tag"] = trim(tag) />
                                    <cfset REQUEST.currentRouteParams = VARIABLES.homeSpotlightRouteParams />
                                    <cfset VARIABLES.homeSpotlightEventPath = REQUEST.i18nBuildPath("event") />
                                    <cfset REQUEST.currentRouteParams = VARIABLES.homeSpotlightCurrentRouteParams />
                                    <cfset VARIABLES.homeSpotlightImagePrimary = trim(url_imagem & "") />
                                    <cfset VARIABLES.homeSpotlightImageList = trim(url_imagem_listagem & "") />
                                    <cfset VARIABLES.homeSpotlightImage = len(VARIABLES.homeSpotlightImagePrimary) ? VARIABLES.homeSpotlightImagePrimary : VARIABLES.homeSpotlightImageList />
                                    <cfif findNoCase("/thumb/", VARIABLES.homeSpotlightImage) AND len(VARIABLES.homeSpotlightImageList) AND NOT findNoCase("/thumb/", VARIABLES.homeSpotlightImageList)>
                                        <cfset VARIABLES.homeSpotlightImage = VARIABLES.homeSpotlightImageList />
                                    </cfif>
                                    <cfset VARIABLES.homeSpotlightIsFuture = data_final GTE now() />
                                    <cfset VARIABLES.homeSpotlightCountry = len(trim(pais & "")) ? trim(pais & "") : "BR" />

                                    <a href="#VARIABLES.homeSpotlightEventPath#" class="home-spotlight-card">
                                        <div class="home-spotlight-media-wrap">
                                            <span class="home-spotlight-badge <cfif VARIABLES.homeSpotlightIsFuture>is-future<cfelse>is-past</cfif>">
                                                <i class="fa-solid <cfif VARIABLES.homeSpotlightIsFuture>fa-calendar-day<cfelse>fa-medal</cfif>"></i>
                                                <cfif VARIABLES.homeSpotlightIsFuture>#VARIABLES.homeSpotlightCatalog.futureTag#<cfelse>#VARIABLES.homeSpotlightCatalog.pastTag#</cfif>
                                            </span>
                                            <cfif len(VARIABLES.homeSpotlightImage)>
                                                <img src="#VARIABLES.homeSpotlightImage#" alt="#encodeForHtmlAttribute(nome_evento)#" class="home-spotlight-media" <cfif qEventosDestaqueHome.currentRow EQ 1>loading="eager" fetchpriority="high"<cfelse>loading="lazy" fetchpriority="low" decoding="async"</cfif> onerror="this.onerror=null; this.parentNode.classList.add('is-image-fallback');" />
                                                <div class="home-spotlight-media-placeholder">
                                                    <i class="fa-solid fa-person-running"></i>
                                                </div>
                                            <cfelse>
                                                <div class="home-spotlight-media-placeholder" style="display:flex;">
                                                    <i class="fa-solid fa-person-running"></i>
                                                </div>
                                            </cfif>
                                        </div>

                                        <div class="home-spotlight-body">
                                            <h3 class="home-spotlight-card-title">#nome_evento#</h3>

                                            <div class="home-spotlight-card-date">
                                                <i class="fa-regular fa-calendar me-1"></i>#lsDateFormat(data_final, "dd mmm yyyy")#
                                            </div>

                                            <div class="home-spotlight-card-meta">
                                                <i class="fa-solid fa-location-dot me-1"></i>#cidade#<cfif len(trim(estado & ""))>&nbsp;-&nbsp;#estado#</cfif><cfif VARIABLES.homeSpotlightCountry NEQ "BR"> - #VARIABLES.homeSpotlightCountry#</cfif>
                                            </div>
                                        </div>
                                    </a>
                                </cfoutput>
                            </div>
                        </section>
                    </cfif>

                    <div class="row g-3 home-discovery-lists">
                        <div class="col-12 col-md-6">
                            <div class="home-dual-section h-100">
                                <div class="home-dual-section-header">
                                    <div class="home-dual-section-title"><i class="fa-regular fa-calendar me-2"></i><cfoutput>#REQUEST.t("home.upcoming.title")#</cfoutput></div>
                                    <cfif qEventos.recordcount>
                                        <cfset REQUEST.homeSponsoredEventsRendered = 0 />
                                        <cfset VARIABLES.eventosAdsRenderMobileBanner = false />
                                        <cfinclude template="includes/eventos_ads.cfm"/>
                                        <cfset VARIABLES.eventosAdsRenderMobileBanner = true />
                                    <cfelse>
                                        <cfinclude template="includes/analytics/empty_event_inventory.cfm" />
                                    </cfif>
                                </div>

                                <div class="home-dual-list">
                                    <div class="home-discovery-context"><span><cfoutput>#encodeForHTML(VARIABLES.homeUpcomingRegionLabel)#</cfoutput></span><a href="#homeHeroSearch" data-home-location-change><cfoutput>#REQUEST.homeDiscoveryText("changeRegion")#</cfoutput></a></div>
                                    <cfif qEventos.recordcount>
                                        <cfset VARIABLES.homeOrganicEventLimit = max(0, 6 - REQUEST.homeSponsoredEventsRendered) />
                                        <cfloop query="qEventos" startrow="1" endrow="#min(qEventos.recordcount, VARIABLES.homeOrganicEventLimit)#">
                                            <cfset VARIABLES.homeCompactEventMode = "proximos"/>
                                            <cfinclude template="includes/estrutura/home_event_compact_card.cfm"/>
                                        </cfloop>
                                        <div class="mt-3">
                                            <a href="<cfoutput>#encodeForHTMLAttribute(VARIABLES.homeCalendarUrl)#</cfoutput>" class="btn btn-secondary btn-sm w-100">
                                                <i class="fa-solid fa-calendar-days me-1"></i><cfoutput>#REQUEST.t("home.upcoming.cta")#</cfoutput>
                                            </a>
                                        </div>
                                    <cfelse>
                                        <div class="home-feedback-card p-3">
                                            <div class="fw-semibold mb-1"><cfoutput>#REQUEST.t("home.upcoming.emptyTitle")#</cfoutput></div>
                                            <div class="small home-hero-muted"><cfoutput>#REQUEST.t("home.upcoming.emptyCopy")#</cfoutput></div>
                                        </div>
                                    </cfif>
                                </div>
                            </div>
                        </div>

                        <div class="col-12 col-md-6">
                            <div class="home-dual-section h-100">
                                <div class="home-dual-section-header">
                                    <div class="home-dual-section-title"><i class="fa-solid fa-medal me-2"></i><cfoutput>#REQUEST.t("home.recentResults.title")#</cfoutput></div>
                                    <div class="home-discovery-context"><span><cfoutput>#encodeForHTML(VARIABLES.homeResultsRegionLabel)#</cfoutput></span><a href="#homeHeroSearch" data-home-location-change><cfoutput>#REQUEST.homeDiscoveryText("changeRegion")#</cfoutput></a></div>
                                </div>

                                <div class="home-dual-list">
                                    <cfif qEventosResultadosHome.recordcount>
                                        <cfloop query="qEventosResultadosHome" startrow="1" endrow="#min(qEventosResultadosHome.recordcount, 6)#">
                                            <cfset VARIABLES.homeCompactEventMode = "resultados"/>
                                            <cfinclude template="includes/estrutura/home_event_compact_card.cfm"/>
                                        </cfloop>
                                        <div class="mt-3">
                                            <a href="<cfoutput>#encodeForHTMLAttribute(VARIABLES.homePublicResultsUrl)#</cfoutput>" class="btn btn-secondary btn-sm w-100">
                                                <i class="fa-solid fa-medal me-1"></i><cfoutput>#REQUEST.homeDiscoveryText("allResults")#</cfoutput>
                                            </a>
                                        </div>
                                    <cfelse>
                                        <div class="home-feedback-card p-3">
                                            <div class="fw-semibold mb-1"><cfoutput>#REQUEST.t("home.recentResults.emptyTitle")#</cfoutput></div>
                                            <div class="small home-hero-muted"><cfoutput>#REQUEST.t("home.recentResults.emptyCopy")#</cfoutput></div>
                                        </div>
                                    </cfif>
                                </div>
                            </div>
                        </div>
                    </div>

                    <cfset VARIABLES.homeMobileSideBannerClassName = "my-2"/>
                    <cfinclude template="includes/estrutura/home_sidebar_mobile_banner_slot.cfm"/>

                    <section data-home-async="news" aria-busy="true">
                        <div class="home-content-panel-header">
                            <div class="home-content-panel-title">
                                <cfif VARIABLES.homeFeaturedVideoAvailable>
                                    <i class="fa-brands fa-youtube me-2"></i>RunTV
                                <cfelse>
                                    <i class="fa-solid fa-newspaper me-2"></i><cfoutput>#REQUEST.t("news.sidebar.title")#</cfoutput>
                                </cfif>
                            </div>
                            <a href="<cfoutput>#REQUEST.i18nBuildPath("news")#</cfoutput>" class="home-content-panel-cta"><cfoutput>#REQUEST.t("news.sidebar.viewAll")#</cfoutput></a>
                        </div>
                        <div class="home-news-layout home-news-placeholder<cfif VARIABLES.homeFeaturedVideoAvailable> has-featured-video<cfelse> is-news-only</cfif>">
                            <cfif VARIABLES.homeFeaturedVideoAvailable>
                                <div class="home-content-card is-featured home-news-featured home-news-skeleton-card" aria-hidden="true">
                                    <div class="home-content-card-placeholder"></div>
                                    <div class="home-content-card-body">
                                        <span class="home-news-skeleton-kicker"></span>
                                        <span class="home-news-skeleton-title"></span>
                                    </div>
                                </div>
                            </cfif>
                            <div class="home-news-top-stack">
                                <cfloop from="1" to="#VARIABLES.homeFeaturedVideoAvailable ? 2 : 3#" index="homeNewsSkeletonIndex">
                                    <div class="home-content-card home-news-skeleton-card" aria-hidden="true">
                                        <div class="home-content-card-placeholder"></div>
                                        <div class="home-content-card-body">
                                            <span class="home-news-skeleton-kicker"></span>
                                            <span class="home-news-skeleton-title"></span>
                                            <span class="home-news-skeleton-title is-short"></span>
                                        </div>
                                    </div>
                                </cfloop>
                            </div>
                        </div>
                    </section>

                    <div class="home-content-panel-header">
                            <div class="home-content-panel-title"><i class="fa-brands fa-youtube me-2"></i><cfoutput>#REQUEST.t("videos.sidebar.latestTitle")#</cfoutput></div>
                            <a href="<cfoutput>#REQUEST.i18nBuildPath("videos")#</cfoutput>" class="home-content-panel-cta"><cfoutput>#REQUEST.t("videos.sidebar.viewAll")#</cfoutput></a>
                        </div>

                        <cfif qVideosHome.recordcount>
                            <div class="row g-3 home-videos-track">
                                <cfoutput query="qVideosHome">
                                    <cfset VARIABLES.videoTitleJs = encodeForHTMLAttribute(JSStringFormat(media_titulo))>
                                    <cfset VARIABLES.videoChannelJs = encodeForHTMLAttribute(JSStringFormat(nome_canal_video))>
                                    <div class="col-12 col-md-4">
                                        <a href="##" class="home-content-card home-video-card" data-audience-content-type="video" data-audience-content-id="#encodeForHTMLAttribute(media_url)#" onclick="changeVideo('#encodeForHTMLAttribute(media_url)#','#VARIABLES.videoTitleJs#','#VARIABLES.videoChannelJs#'); return false;">
                                            <div class="home-video-thumb-wrap">
                                                <div class="home-content-card-media">
                                                    <img src="https://img.youtube.com/vi/#encodeForHTMLAttribute(media_url)#/sddefault.jpg" alt="#encodeForHTMLAttribute(media_titulo)#" class="home-content-card-image" loading="lazy" decoding="async" onerror="this.onerror=null; this.parentNode.classList.add('is-image-fallback');" />
                                                    <div class="home-content-card-placeholder">
                                                        <i class="fa-solid fa-person-running"></i>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="home-content-card-body">
                                                <cfif len(trim(nome_canal_video))>
                                                    <div class="home-content-card-kicker">#encodeForHTML(nome_canal_video)#</div>
                                                </cfif>
                                                <h3 class="home-content-card-title">#encodeForHTML(media_titulo)#</h3>
                                                <cfif isDate(data_publicacao)><time class="home-content-card-time" datetime="#dateFormat(data_publicacao, 'yyyy-mm-dd')#">#lsDateFormat(data_publicacao, 'dd mmm yyyy')#</time></cfif>
                                            </div>
                                        </a>
                                    </div>
                                </cfoutput>
                            </div>
                        <cfelse>
                            <div class="small home-hero-muted"><cfoutput>#REQUEST.t("videos.sidebar.empty")#</cfoutput></div>
                        </cfif>

                    <!---
                    <cfset VARIABLES.adMockSlotName = "home-content-inline" />
                    <cfset VARIABLES.adMockFormat = "Native card | 970x250 | 320x100" />
                    <cfset VARIABLES.adMockContext = "Slot inline entre conteudo editorial da home e os blocos de eventos e resultados." />
                    <cfset VARIABLES.adMockClassName = "mt-2" />
                    <cfset VARIABLES.adMockBadge = "Slot de anuncio" />
                    <cfinclude template="includes/estrutura/ad_slot_mock.cfm"/>
                    --->


                </div>
            </div>

        </div>

        </main>

    </div>


    <script>
        document.addEventListener('DOMContentLoaded', function () {
            function loadHomeAsyncBlock(selector, url, visibleOnly) {
                var target = document.querySelector(selector);

                if (!target || target.dataset.homeAsyncLoaded === '1') {
                    return;
                }

                if (visibleOnly && !target.getClientRects().length) {
                    return;
                }

                target.dataset.homeAsyncLoaded = '1';

                function hydrateInsertedScripts(container) {
                    var scripts = [];

                    if (container.matches && container.matches('script')) {
                        scripts.push(container);
                    }

                    container.querySelectorAll('script').forEach(function (oldScript) {
                        scripts.push(oldScript);
                    });

                    scripts.forEach(function (oldScript) {
                        var newScript = document.createElement('script');

                        Array.prototype.slice.call(oldScript.attributes).forEach(function (attribute) {
                            newScript.setAttribute(attribute.name, attribute.value);
                        });

                        newScript.text = oldScript.text || oldScript.textContent || '';
                        oldScript.parentNode.replaceChild(newScript, oldScript);
                    });

                    if (window.mdb && typeof window.mdb.AutoInit === 'function') {
                        try {
                            window.mdb.AutoInit();
                        } catch (error) {
                            console.warn('MDB async init skipped', error);
                        }
                    }
                }

                fetch(url, {
                    cache: 'no-store',
                    credentials: 'same-origin',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest'
                    }
                })
                    .then(function (response) {
                        if (!response.ok) {
                            throw new Error('home async block failed');
                        }

                        return response.text();
                    })
                    .then(function (html) {
                        var trimmedHtml = html.trim();

                        if (trimmedHtml) {
                            var wrapper = document.createElement('div');
                            wrapper.innerHTML = trimmedHtml;
                            var fragment = document.createDocumentFragment();

                            while (wrapper.firstChild) {
                                fragment.appendChild(wrapper.firstChild);
                            }

                            var insertedNodes = Array.prototype.slice.call(fragment.childNodes);
                            target.parentNode.replaceChild(fragment, target);
                            insertedNodes.forEach(function (node) {
                                if (node.nodeType === 1) {
                                    hydrateInsertedScripts(node);
                                }
                            });
                            return;
                        }

                        throw new Error('empty home block');
                    })
                    .catch(function () {
                        target.setAttribute('aria-busy', 'false');
                        target.replaceChildren();
                        var message = document.createElement('p');
                        message.className = 'small text-muted mb-2';
                        message.textContent = '<cfoutput>#encodeForJavaScript(REQUEST.homeDiscoveryText("loadError"))#</cfoutput>';
                        var retry = document.createElement('button');
                        retry.type = 'button';
                        retry.className = 'btn btn-light btn-sm shadow-0';
                        retry.textContent = '<cfoutput>#encodeForJavaScript(REQUEST.homeDiscoveryText("retry"))#</cfoutput>';
                        retry.addEventListener('click', function () {
                            target.dataset.homeAsyncLoaded = '0';
                            target.setAttribute('aria-busy', 'true');
                            retry.disabled = true;
                            loadHomeAsyncBlock(selector, url, visibleOnly);
                        });
                        target.append(message, retry);
                    });
            }

            function loadHomeSidebar() {
                loadHomeAsyncBlock('[data-home-async="sidebar"]', '<cfoutput>#encodeForJavaScript(VARIABLES.homeSidebarCalendarUrl)#</cfoutput>', true);
            }

            loadHomeAsyncBlock('[data-home-async="news"]', '/api/home_news.cfm?i18n_lang=<cfoutput>#encodeForJavaScript(REQUEST.lang)#</cfoutput>', false);
            loadHomeSidebar();
            document.querySelectorAll('[data-home-location-change]').forEach(function (link) {
                link.addEventListener('click', function (event) {
                    event.preventDefault();
                    var hero = document.getElementById('homeHeroSearch');
                    if (!hero) return;
                    hero.classList.remove('is-collapsed');
                    document.querySelectorAll('[data-home-hero-toggle]').forEach(function (button) { button.setAttribute('aria-expanded', 'true'); });
                    hero.scrollIntoView({block: 'start', behavior: 'smooth'});
                    var select = hero.querySelector('select');
                    if (select) select.focus({preventScroll: true});
                });
            });
            window.addEventListener('resize', loadHomeSidebar, { passive: true });

            var track = document.querySelector('[data-spotlight-track]');
            var prev = document.querySelector('[data-spotlight-prev]');
            var next = document.querySelector('[data-spotlight-next]');

            if (!track || !prev || !next) {
                return;
            }

            function getStep() {
                return Math.max(track.clientWidth * 0.82, 280);
            }

            function updateControls() {
                var maxScroll = Math.max(0, track.scrollWidth - track.clientWidth - 4);
                prev.disabled = track.scrollLeft <= 4;
                next.disabled = track.scrollLeft >= maxScroll;
            }

            prev.addEventListener('click', function () {
                track.scrollBy({ left: -getStep(), behavior: 'smooth' });
            });

            next.addEventListener('click', function () {
                track.scrollBy({ left: getStep(), behavior: 'smooth' });
            });

            track.addEventListener('scroll', updateControls, { passive: true });
            window.addEventListener('resize', updateControls);
            updateControls();
        });
    </script>

    <!--- MODAL DO MAPA --->

    <!---cfinclude template="includes/modal/modal_mapa.cfm"/--->


    <!--- FOOTER --->

    <cfinclude template="includes/estrutura/footer.cfm"/>


    <!--- MODAL DE ENVIAR --->

    <cfinclude template="includes/modal/modal_enviar.cfm"/>


    <!--- MODAL DE BADGES --->

    <cfinclude template="includes/modal/modal_badges.cfm"/>


    <!--- MODAL DE YOUTUBE --->

    <cfinclude template="includes/modal/modal_youtube.cfm"/>


    <!--- MODAL FOCO --->

    <cfinclude template="includes/modal/modal_cupom_foco.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="includes/modal/modal_login.cfm"/>


    <!--- MODAL SEGUIDORES / SEGUINDO --->

    <cfinclude template="includes/modal/modal_seguidores.cfm"/>


    <!--- MODAL PAGAMENTO --->

    <cfinclude template="includes/modal/modal_pagamento.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>
