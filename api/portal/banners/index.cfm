<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>

<cfscript>
function portalBannerApiBuildBaseUrl() {
    var isHttps = false;
    var hostName = "business.roadrunners.run";

    if (structKeyExists(CGI, "https")) {
        isHttps = isBoolean(CGI.https) ? CGI.https : listFindNoCase("on,1,yes,true", trim(CGI.https));
    }

    if (structKeyExists(CGI, "http_host") AND len(trim(CGI.http_host))) {
        hostName = trim(CGI.http_host);
    }

    return (isHttps ? "https://" : "http://") & hostName;
}

function portalBannerApiExtractOriginSite() {
    var siteUrl = "";
    var originValue = "";

    if (isDefined("URL.site_url") AND len(trim(URL.site_url))) {
        siteUrl = trim(URL.site_url);
    } else if (structKeyExists(CGI, "http_origin") AND len(trim(CGI.http_origin))) {
        siteUrl = trim(CGI.http_origin);
    } else if (structKeyExists(CGI, "http_referer") AND len(trim(CGI.http_referer))) {
        siteUrl = trim(CGI.http_referer);
    }

    if (!reFindNoCase("^https?://", siteUrl)) {
        return "";
    }

    originValue = reReplace(siteUrl, "^(https?://[^/]+).*$", "\1", "one");
    return originValue;
}

function portalBannerApiSafeJson(required any payload) {
    cfcontent(type="application/json; charset=utf-8", reset="true");
    writeOutput(serializeJSON(arguments.payload));
    abort;
}
</cfscript>

<cfheader name="Access-Control-Allow-Origin" value="*"/>
<cfheader name="Access-Control-Allow-Methods" value="GET, OPTIONS"/>
<cfheader name="Access-Control-Allow-Headers" value="Content-Type"/>

<cfif CGI.request_method EQ "OPTIONS">
    <cfcontent type="application/json; charset=utf-8" reset="true"/>
    <cfoutput>{}</cfoutput>
    <cfabort/>
</cfif>

<cfparam name="URL.canal" default=""/>
<cfparam name="URL.local" default=""/>
<cfparam name="URL.tamanho" default=""/>
<cfparam name="URL.largura" default=""/>
<cfparam name="URL.altura" default=""/>
<cfparam name="URL.path" default=""/>

<cfset VARIABLES.portalBannerApiBaseUrl = portalBannerApiBuildBaseUrl()/>
<cfset VARIABLES.portalBannerOriginSite = portalBannerApiExtractOriginSite()/>

<cfquery name="qPortalBannerApiTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = current_schema()
      AND table_name IN ('tb_portal_banners', 'tb_portal_banners_log')
</cfquery>

<cfset VARIABLES.portalBannerApiTablesList = ValueList(qPortalBannerApiTables.table_name)/>

<cfif NOT ListFindNoCase(VARIABLES.portalBannerApiTablesList, "tb_portal_banners") OR NOT ListFindNoCase(VARIABLES.portalBannerApiTablesList, "tb_portal_banners_log")>
    <cfset portalBannerApiSafeJson({
        success = false,
        status = "tables_missing",
        message = "As tabelas do gerenciador de banners ainda nao foram criadas no Business."
    })/>
</cfif>

<cfif NOT len(trim(URL.canal)) OR NOT len(trim(URL.local))>
    <cfset portalBannerApiSafeJson({
        success = false,
        status = "missing_params",
        message = "Informe pelo menos canal e local para consultar um banner."
    })/>
</cfif>

<cfquery name="qPortalBannerApiCandidates">
    WITH banner_views AS (
        SELECT id_banner, count(*) AS total
        FROM tb_portal_banners_log
        WHERE tipo_evento = 'view'
        GROUP BY id_banner
    ),
    banner_clicks AS (
        SELECT id_banner, count(*) AS total
        FROM tb_portal_banners_log
        WHERE tipo_evento = 'click'
        GROUP BY id_banner
    ),
    banner_daily_views AS (
        SELECT id_banner, count(*) AS total
        FROM tb_portal_banners_log
        WHERE tipo_evento = 'view'
          AND criado_em::date = current_date
        GROUP BY id_banner
    )
    SELECT bnr.*,
           coalesce(banner_views.total, 0) AS views,
           coalesce(banner_clicks.total, 0) AS clicks,
           coalesce(banner_daily_views.total, 0) AS daily_views
    FROM tb_portal_banners bnr
    LEFT JOIN banner_views ON banner_views.id_banner = bnr.id_banner
    LEFT JOIN banner_clicks ON banner_clicks.id_banner = bnr.id_banner
    LEFT JOIN banner_daily_views ON banner_daily_views.id_banner = bnr.id_banner
    WHERE bnr.status = 2
      AND lower(bnr.canal) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(URL.canal))#"/>
      AND lower(bnr.local_layout) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(URL.local))#"/>
      AND (bnr.inicio_exibicao IS NULL OR bnr.inicio_exibicao <= now())
      AND (bnr.fim_exibicao IS NULL OR bnr.fim_exibicao >= now())
      AND (
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.tamanho)#"/> = ''
            OR trim(coalesce(bnr.tamanho_nome, '')) = ''
            OR lower(bnr.tamanho_nome) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(URL.tamanho))#"/>
      )
      AND (
            <cfqueryparam cfsqltype="cf_sql_integer" value="#isNumeric(URL.largura) ? val(URL.largura) : 0#"/> = 0
            OR bnr.largura IS NULL
            OR bnr.largura = <cfqueryparam cfsqltype="cf_sql_integer" value="#isNumeric(URL.largura) ? val(URL.largura) : 0#"/>
      )
      AND (
            <cfqueryparam cfsqltype="cf_sql_integer" value="#isNumeric(URL.altura) ? val(URL.altura) : 0#"/> = 0
            OR bnr.altura IS NULL
            OR bnr.altura = <cfqueryparam cfsqltype="cf_sql_integer" value="#isNumeric(URL.altura) ? val(URL.altura) : 0#"/>
      )
      AND (bnr.limite_impressoes IS NULL OR coalesce(banner_views.total, 0) < bnr.limite_impressoes)
      AND (bnr.limite_cliques IS NULL OR coalesce(banner_clicks.total, 0) < bnr.limite_cliques)
      AND (bnr.limite_diario IS NULL OR coalesce(banner_daily_views.total, 0) < bnr.limite_diario)
    ORDER BY bnr.prioridade DESC,
             bnr.atualizado_em DESC,
             bnr.id_banner DESC
</cfquery>

<cfif NOT qPortalBannerApiCandidates.recordcount>
    <cfset portalBannerApiSafeJson({
        success = true,
        status = "empty",
        banner = javacast("null", ""),
        message = "Nenhum banner elegivel foi encontrado para este canal e slot."
    })/>
</cfif>

<cfset VARIABLES.portalBannerSelectedRow = 1/>
<cfset VARIABLES.portalBannerSelectionWeight = 0/>
<cfloop query="qPortalBannerApiCandidates">
    <cfset VARIABLES.portalBannerSelectionWeight = VARIABLES.portalBannerSelectionWeight + (qPortalBannerApiCandidates.peso_exibicao GT 0 ? qPortalBannerApiCandidates.peso_exibicao : 1)/>
</cfloop>

<cfset VARIABLES.portalBannerSelectionPick = RandRange(1, VARIABLES.portalBannerSelectionWeight)/>
<cfset VARIABLES.portalBannerSelectionCursor = 0/>

<cfloop query="qPortalBannerApiCandidates">
    <cfset VARIABLES.portalBannerSelectionCursor = VARIABLES.portalBannerSelectionCursor + (qPortalBannerApiCandidates.peso_exibicao GT 0 ? qPortalBannerApiCandidates.peso_exibicao : 1)/>
    <cfif VARIABLES.portalBannerSelectionPick LTE VARIABLES.portalBannerSelectionCursor>
        <cfset VARIABLES.portalBannerSelectedRow = qPortalBannerApiCandidates.currentRow/>
        <cfbreak/>
    </cfif>
</cfloop>

<cfset VARIABLES.portalBannerSelectedId = qPortalBannerApiCandidates.id_banner[VARIABLES.portalBannerSelectedRow]/>
<cfset VARIABLES.portalBannerSelectedLink = qPortalBannerApiCandidates.link_destino[VARIABLES.portalBannerSelectedRow]/>
<cfset VARIABLES.portalBannerOpenInNewTab = IsBoolean(qPortalBannerApiCandidates.abrir_nova_aba[VARIABLES.portalBannerSelectedRow]) ? qPortalBannerApiCandidates.abrir_nova_aba[VARIABLES.portalBannerSelectedRow] : ListFindNoCase("1,true,yes,on", trim(qPortalBannerApiCandidates.abrir_nova_aba[VARIABLES.portalBannerSelectedRow])) GT 0/>
<cfset VARIABLES.portalBannerSelectedTarget = VARIABLES.portalBannerOpenInNewTab ? "_blank" : "_self"/>
<cfset VARIABLES.portalBannerSelectedCtr = qPortalBannerApiCandidates.views[VARIABLES.portalBannerSelectedRow] GT 0 ? (qPortalBannerApiCandidates.clicks[VARIABLES.portalBannerSelectedRow] * 100 / qPortalBannerApiCandidates.views[VARIABLES.portalBannerSelectedRow]) : 0/>
<cfset VARIABLES.portalBannerClickUrl = VARIABLES.portalBannerApiBaseUrl & "/api/portal/banners/click.cfm?id_banner=" & VARIABLES.portalBannerSelectedId & "&canal=" & urlEncodedFormat(trim(URL.canal)) & "&local=" & urlEncodedFormat(trim(URL.local))/>

<cfif len(VARIABLES.portalBannerOriginSite)>
    <cfset VARIABLES.portalBannerClickUrl = VARIABLES.portalBannerClickUrl & "&site_url=" & urlEncodedFormat(VARIABLES.portalBannerOriginSite)/>
</cfif>

<cfif len(trim(URL.path))>
    <cfset VARIABLES.portalBannerClickUrl = VARIABLES.portalBannerClickUrl & "&path=" & urlEncodedFormat(trim(URL.path))/>
</cfif>

<cfquery>
    INSERT INTO tb_portal_banners_log
    (
        id_banner,
        tipo_evento,
        canal,
        local_layout,
        host_origem,
        caminho_origem,
        origem_site,
        id_usuario,
        ip_address,
        user_agent,
        request_data
    )
    VALUES
    (
        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.portalBannerSelectedId#"/>,
        'view',
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.canal)#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.local)#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#structKeyExists(CGI, 'http_host') ? CGI.http_host : ''#" null="#NOT structKeyExists(CGI, 'http_host') OR NOT len(trim(CGI.http_host))#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.path)#" null="#NOT len(trim(URL.path))#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.portalBannerOriginSite#" null="#NOT len(VARIABLES.portalBannerOriginSite)#"/>,
        <cfqueryparam cfsqltype="cf_sql_integer" value="#isDefined('COOKIE.id') AND isNumeric(COOKIE.id) ? val(COOKIE.id) : 0#" null="#NOT isDefined('COOKIE.id') OR NOT isNumeric(COOKIE.id)#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#structKeyExists(CGI, 'remote_addr') ? CGI.remote_addr : ''#" null="#NOT structKeyExists(CGI, 'remote_addr') OR NOT len(trim(CGI.remote_addr))#"/>,
        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#structKeyExists(CGI, 'http_user_agent') ? CGI.http_user_agent : ''#" null="#NOT structKeyExists(CGI, 'http_user_agent') OR NOT len(trim(CGI.http_user_agent))#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON({
            tamanho = trim(URL.tamanho),
            largura = trim(URL.largura),
            altura = trim(URL.altura)
        })#"/>::jsonb
    )
</cfquery>

<cfset portalBannerApiSafeJson({
    success = true,
    status = "ok",
    banner = {
        id = VARIABLES.portalBannerSelectedId,
        nome = qPortalBannerApiCandidates.nome[VARIABLES.portalBannerSelectedRow],
        canal = qPortalBannerApiCandidates.canal[VARIABLES.portalBannerSelectedRow],
        localLayout = qPortalBannerApiCandidates.local_layout[VARIABLES.portalBannerSelectedRow],
        sizeName = qPortalBannerApiCandidates.tamanho_nome[VARIABLES.portalBannerSelectedRow],
        width = qPortalBannerApiCandidates.largura[VARIABLES.portalBannerSelectedRow],
        height = qPortalBannerApiCandidates.altura[VARIABLES.portalBannerSelectedRow],
        format = qPortalBannerApiCandidates.formato[VARIABLES.portalBannerSelectedRow],
        alt = qPortalBannerApiCandidates.alt_text[VARIABLES.portalBannerSelectedRow],
        imageUrl = VARIABLES.portalBannerApiBaseUrl & qPortalBannerApiCandidates.arquivo_path[VARIABLES.portalBannerSelectedRow],
        clickUrl = VARIABLES.portalBannerClickUrl,
        target = VARIABLES.portalBannerSelectedTarget,
        linkType = qPortalBannerApiCandidates.link_tipo[VARIABLES.portalBannerSelectedRow],
        openInNewTab = VARIABLES.portalBannerOpenInNewTab,
        stats = {
            views = qPortalBannerApiCandidates.views[VARIABLES.portalBannerSelectedRow],
            clicks = qPortalBannerApiCandidates.clicks[VARIABLES.portalBannerSelectedRow],
            ctr = VARIABLES.portalBannerSelectedCtr
        }
    }
})/>
