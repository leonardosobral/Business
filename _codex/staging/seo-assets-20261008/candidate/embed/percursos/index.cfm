<cfprocessingdirective pageencoding="utf-8"/>
<cfparam name="URL.evento" default=""/>
<cfset URL.evento = trim(URL.evento & "")/>

<cfheader name="X-Robots-Tag" value="noindex, nofollow"/>
<cfheader name="Cache-Control" value="private, max-age=60"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfheader name="Content-Security-Policy" value="frame-ancestors *"/>

<cfif !reFind("^[a-zA-Z0-9_-]{1,160}$", URL.evento)>
    <cfheader statuscode="404" statustext="Not Found"/>
    <cfabort/>
</cfif>

<cfif fileExists(expandPath("/config/event-route-mapbox-runtime.cfm"))>
    <cfinclude template="../../config/event-route-mapbox-runtime.cfm"/>
</cfif>

<cfif
    !structKeyExists(APPLICATION, "eventRouteMapbox")
    OR !isStruct(APPLICATION.eventRouteMapbox)
    OR !structKeyExists(APPLICATION.eventRouteMapbox, "enabled")
    OR !APPLICATION.eventRouteMapbox.enabled
>
    <cfheader statuscode="503" statustext="Service Unavailable"/>
    <cfabort/>
</cfif>

<cfquery name="qEvento">
    SELECT
        evt.id_evento,
        evt.nome_evento,
        evt.tag,
        evt.data_inicial,
        evt.cidade,
        evt.estado,
        (
            SELECT json_agg(
                json_build_object(
                    'id_evento_percurso', modalidade.id_evento_percurso,
                    'percurso', modalidade.percurso_evento,
                    'unidade', modalidade.unidade_de_medida,
                    'tipo_corrida', modalidade.tipo_corrida,
                    'arquivo_percurso',
                    CASE
                        WHEN percurso.status = 'publicado'
                         AND arquivo.id_percurso_arquivo IS NOT NULL
                         AND (
                            (
                                NULLIF(to_jsonb(arquivo)->>'web_geojson_storage_key', '') IS NOT NULL
                                AND COALESCE(to_jsonb(arquivo)->>'web_sha256', '') ~ '^[0-9A-Fa-f]{64}$'
                            )
                            OR (
                                NULLIF(arquivo.geojson_storage_key, '') IS NOT NULL
                                AND arquivo.sha256 ~ '^[0-9A-Fa-f]{64}$'
                                AND arquivo.quantidade_pontos BETWEEN 2 AND 20000
                            )
                         )
                        THEN json_build_object(
                            'disponivel', true,
                            'id_percurso', percurso.id_percurso,
                            'id_percurso_arquivo', arquivo.id_percurso_arquivo,
                            'versao', arquivo.versao,
                            'geometria_url',
                                '/evento/' || evt.tag || '/?route_geometry=1&id_evento_percurso='
                                || modalidade.id_evento_percurso::text
                                || '&arquivo=' || arquivo.id_percurso_arquivo::text
                                || '&rev=' || left(
                                    CASE
                                        WHEN NULLIF(to_jsonb(arquivo)->>'web_geojson_storage_key', '') IS NOT NULL
                                         AND COALESCE(to_jsonb(arquivo)->>'web_sha256', '') ~ '^[0-9A-Fa-f]{64}$'
                                        THEN to_jsonb(arquivo)->>'web_sha256'
                                        ELSE arquivo.sha256
                                    END,
                                    12
                                ),
                            'distancia_m', arquivo.distancia_gpx_m,
                            'elevacao_min_m', arquivo.elevacao_min_m,
                            'elevacao_max_m', arquivo.elevacao_max_m,
                            'ganho_elevacao_m', arquivo.ganho_elevacao_m,
                            'bbox', json_build_array(
                                arquivo.bbox_min_lng,
                                arquivo.bbox_min_lat,
                                arquivo.bbox_max_lng,
                                arquivo.bbox_max_lat
                            )
                        )
                        ELSE NULL
                    END
                )
                ORDER BY modalidade.percurso_evento, modalidade.id_evento_percurso
            )
            FROM tb_evento_corridas_percursos modalidade
            LEFT JOIN tb_evento_percursos_gpx vinculo
                ON vinculo.id_evento_percurso = modalidade.id_evento_percurso
               AND vinculo.id_evento = modalidade.id_evento
            LEFT JOIN tb_percursos percurso
                ON percurso.id_percurso = vinculo.id_percurso
            LEFT JOIN LATERAL (
                SELECT versao_arquivo.*
                FROM tb_percurso_arquivos versao_arquivo
                WHERE versao_arquivo.id_percurso = percurso.id_percurso
                  AND versao_arquivo.ativo = true
                ORDER BY versao_arquivo.versao DESC
                LIMIT 1
            ) arquivo ON true
            WHERE modalidade.id_evento = evt.id_evento
        ) AS lista_percursos
    FROM tb_evento_corridas evt
    WHERE evt.tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.evento#"/>
      AND evt.ativo = true
    LIMIT 1
</cfquery>

<cfscript>
VARIABLES.eventRoutes = [];
VARIABLES.eventRouteMapboxConfigured = true;
VARIABLES.eventRouteHasMapbox = false;
if (qEvento.recordCount && len(trim(qEvento.lista_percursos & "")) && isJSON(qEvento.lista_percursos)) {
    VARIABLES.eventRoutes = deserializeJSON(qEvento.lista_percursos);
}
for (VARIABLES.eventRouteCandidate in VARIABLES.eventRoutes) {
    if (
        structKeyExists(VARIABLES.eventRouteCandidate, "arquivo_percurso")
        && !isNull(VARIABLES.eventRouteCandidate.arquivo_percurso)
        && isStruct(VARIABLES.eventRouteCandidate.arquivo_percurso)
        && structKeyExists(VARIABLES.eventRouteCandidate.arquivo_percurso, "disponivel")
        && VARIABLES.eventRouteCandidate.arquivo_percurso.disponivel
    ) {
        VARIABLES.eventRouteHasMapbox = true;
        break;
    }
}
</cfscript>

<cfif !qEvento.recordCount OR !VARIABLES.eventRouteHasMapbox>
    <cfheader statuscode="404" statustext="Not Found"/>
    <cfabort/>
</cfif>

<cfscript>
eventCatalog = REQUEST.i18n.event;
eventSections = eventCatalog.sections;
eventDescriptionCatalog = eventCatalog.description;
VARIABLES.eventRouteEmbedCatalog = eventCatalog.routeEmbed;
VARIABLES.eventPageUrl = reReplace(trim(REQUEST.currentBaseUrl & ""), "/+$", "")
    & "/evento/"
    & qEvento.tag
    & "/?utm_source=event_routes_embed&utm_medium=referral&utm_campaign=event_routes&utm_content=event_header";
VARIABLES.eventEmbedLocation = trim(qEvento.cidade & "");
if (len(trim(qEvento.estado & ""))) {
    VARIABLES.eventEmbedLocation &= (len(VARIABLES.eventEmbedLocation) ? " - " : "") & trim(qEvento.estado & "");
}
VARIABLES.eventEmbedMeta = [];
if (isDate(qEvento.data_inicial)) arrayAppend(VARIABLES.eventEmbedMeta, dateFormat(qEvento.data_inicial, "dd/mm/yyyy"));
if (len(VARIABLES.eventEmbedLocation)) arrayAppend(VARIABLES.eventEmbedMeta, VARIABLES.eventEmbedLocation);
VARIABLES.eventRouteEmbedService = new services.EventRouteEmbedService().init("runner_dba", APPLICATION.handoff.secret & "");
VARIABLES.eventRouteEmbedSigned = VARIABLES.eventRouteEmbedService.issue(qEvento.id_evento, qEvento.tag & "");
VARIABLES.eventRouteEmbedTrackingConfig = serializeJSON({
    "token" = VARIABLES.eventRouteEmbedSigned.token,
    "signature" = VARIABLES.eventRouteEmbedSigned.signature,
    "endpoint" = "/embed/percursos/view.cfm"
});
VARIABLES.eventRouteEmbedTrackingConfig = replace(VARIABLES.eventRouteEmbedTrackingConfig, "&", "\u0026", "all");
VARIABLES.eventRouteEmbedTrackingConfig = replace(VARIABLES.eventRouteEmbedTrackingConfig, "<", "\u003c", "all");
VARIABLES.eventRouteEmbedTrackingConfig = replace(VARIABLES.eventRouteEmbedTrackingConfig, ">", "\u003e", "all");
</cfscript>

<!doctype html>
<html lang="<cfoutput>#HTMLEditFormat(REQUEST.htmlLang)#</cfoutput>">
<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <meta name="robots" content="noindex,nofollow"/>
    <title><cfoutput>#HTMLEditFormat(qEvento.nome_evento)# · #HTMLEditFormat(eventSections.routes)#</cfoutput></title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@7.2.0/css/all.min.css"/>
    <cfoutput><link rel="stylesheet" href="https://api.mapbox.com/mapbox-gl-js/v#APPLICATION.eventRouteMapbox.libraryVersion#/mapbox-gl.css"/></cfoutput>
    <link rel="stylesheet" href="/assets/css/event-route-mapbox.min.css?v=20261008seo"/>
    <style>
        * { box-sizing: border-box; }
        html, body { margin: 0; min-width: 0; }
        body { background: transparent; color: #333; font-family: Arial, Helvetica, sans-serif; padding: 1px; }
        .rr-event-route-embed { background: #fff; border: 1px solid rgba(51,51,51,.12); border-radius: 10px; overflow: hidden; }
        .rr-event-route-embed-header { align-items: center; background: #f3f3f3; border-bottom: 1px solid rgba(51,51,51,.08); color: #333; display: flex; gap: .75rem; justify-content: space-between; padding: .72rem .9rem; text-decoration: none; }
        .rr-event-route-embed-header:hover, .rr-event-route-embed-header:focus-visible { background: #ececec; color: #111; }
        .rr-event-route-embed-copy { min-width: 0; }
        .rr-event-route-embed-copy > span { display: block; }
        .rr-event-route-embed-kicker { color: rgba(51,51,51,.58); font-size: .65rem; font-weight: 700; letter-spacing: .06em; margin-bottom: .15rem; text-transform: uppercase; }
        .rr-event-route-embed-title { font-size: .9rem; font-weight: 700; line-height: 1.25; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .rr-event-route-embed-meta { color: rgba(51,51,51,.64); font-size: .72rem; margin-top: .14rem; }
        .rr-event-route-embed-brand { align-items: center; display: inline-flex; flex: 0 0 auto; }
        .rr-event-route-embed-brand img { display: block; height: auto; max-width: 92px; width: 92px; }
        .visually-hidden { height: 1px!important; margin: -1px!important; overflow: hidden!important; padding: 0!important; position: absolute!important; width: 1px!important; clip: rect(0,0,0,0)!important; white-space: nowrap!important; border: 0!important; }
        .spinner-border { animation: rr-event-route-spin .75s linear infinite; border: .18em solid currentcolor; border-right-color: transparent; border-radius: 50%; display: inline-block; height: 1rem; vertical-align: -.125em; width: 1rem; }
        @keyframes rr-event-route-spin { to { transform: rotate(360deg); } }
        .event-route-component { padding-top: .75rem; }
        @media (max-width: 480px) {
            .rr-event-route-embed-header { align-items: flex-start; }
            .rr-event-route-embed-title { white-space: normal; }
            .rr-event-route-embed-brand img { max-width: 72px; width: 72px; }
            .event-route-map { height: 310px; }
        }
    </style>
</head>
<body>
    <article class="rr-event-route-embed">
        <a class="rr-event-route-embed-header" href="<cfoutput>#HTMLEditFormat(VARIABLES.eventPageUrl)#</cfoutput>" target="_blank" rel="noopener noreferrer">
            <span class="rr-event-route-embed-copy">
                <span class="rr-event-route-embed-kicker"><cfoutput>#HTMLEditFormat(VARIABLES.eventRouteEmbedCatalog.headerKicker)#</cfoutput></span>
                <span class="rr-event-route-embed-title"><cfoutput>#HTMLEditFormat(qEvento.nome_evento)#</cfoutput></span>
                <cfif arrayLen(VARIABLES.eventEmbedMeta)>
                    <span class="rr-event-route-embed-meta"><cfoutput>#HTMLEditFormat(arrayToList(VARIABLES.eventEmbedMeta, " · "))#</cfoutput></span>
                </cfif>
            </span>
            <span class="rr-event-route-embed-brand">
                <img src="/assets/rr_logo.png" alt="Road Runners" width="92" height="31"/>
            </span>
        </a>
        <cfinclude template="../../evento/parts/mapa_percurso_mapbox.cfm"/>
    </article>
    <script type="application/json" id="rrEventRoutesTrackingConfig"><cfoutput>#VARIABLES.eventRouteEmbedTrackingConfig#</cfoutput></script>
    <cfoutput><script src="https://api.mapbox.com/mapbox-gl-js/v#APPLICATION.eventRouteMapbox.libraryVersion#/mapbox-gl.js"></script></cfoutput>
    <script src="/assets/js/event-route-mapbox.min.js?v=20261008seo"></script>
    <script>
    (function () {
        var parentOrigin = '*';
        var context = {pageUrl: document.referrer || '', viewId: ''};
        var counted = false;
        var config = {};
        try { config = JSON.parse(document.getElementById('rrEventRoutesTrackingConfig').textContent); } catch (ignore) {}

        function post(type, data) {
            window.parent.postMessage(Object.assign({type: type}, data || {}), parentOrigin);
        }
        function resize() {
            post('rr-event-routes:resize', {height: Math.ceil(document.documentElement.scrollHeight + 2)});
        }
        window.addEventListener('message', function (event) {
            if (event.source !== window.parent || !event.data || typeof event.data !== 'object') return;
            if (event.data.type === 'rr-event-routes:context') {
                parentOrigin = event.origin;
                var candidatePageUrl = String(event.data.pageUrl || context.pageUrl).slice(0, 2048);
                try {
                    var candidateUrl = new URL(candidatePageUrl);
                    context.pageUrl = candidateUrl.origin === event.origin ? candidateUrl.href : event.origin;
                } catch (ignoreUrl) {
                    context.pageUrl = event.origin.indexOf('http') === 0 ? event.origin : context.pageUrl;
                }
                context.viewId = String(event.data.viewId || context.viewId);
                resize();
            }
            if (event.data.type === 'rr-event-routes:viewable' && !counted) {
                counted = true;
                fetch(config.endpoint, {
                    method: 'POST',
                    credentials: 'omit',
                    keepalive: true,
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        token: config.token,
                        signature: config.signature,
                        viewId: context.viewId || event.data.viewId,
                        pageUrl: context.pageUrl,
                        referrerUrl: document.referrer || '',
                        visibleMs: Number(event.data.visibleMs) || 1000,
                        ratio: Number(event.data.ratio) || 0.5
                    })
                }).catch(function () {});
            }
        });
        if ('ResizeObserver' in window) new ResizeObserver(resize).observe(document.body);
        window.addEventListener('load', resize);
        post('rr-event-routes:ready');
        resize();
    }());
    </script>
</body>
</html>
