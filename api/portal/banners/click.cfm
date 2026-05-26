<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>

<cfscript>
function portalBannerClickResolveOriginSite() {
    var siteUrl = "";
    var originValue = "";

    if (isDefined("URL.site_url") AND len(trim(URL.site_url))) {
        siteUrl = trim(URL.site_url);
    } else if (structKeyExists(CGI, "http_referer") AND len(trim(CGI.http_referer))) {
        siteUrl = trim(CGI.http_referer);
    }

    if (!reFindNoCase("^https?://", siteUrl)) {
        return "";
    }

    originValue = reReplace(siteUrl, "^(https?://[^/]+).*$", "\1", "one");
    return originValue;
}
</cfscript>

<cfparam name="URL.id_banner" default="0"/>
<cfparam name="URL.canal" default=""/>
<cfparam name="URL.local" default=""/>
<cfparam name="URL.path" default=""/>

<cfset VARIABLES.portalBannerClickOriginSite = portalBannerClickResolveOriginSite()/>

<cfquery name="qPortalBannerClickTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = current_schema()
      AND table_name IN ('tb_portal_banners', 'tb_portal_banners_log')
</cfquery>

<cfset VARIABLES.portalBannerClickTablesList = ValueList(qPortalBannerClickTables.table_name)/>

<cfif NOT ListFindNoCase(VARIABLES.portalBannerClickTablesList, "tb_portal_banners") OR NOT ListFindNoCase(VARIABLES.portalBannerClickTablesList, "tb_portal_banners_log") OR NOT isNumeric(URL.id_banner)>
    <cfheader statuscode="404" statustext="Not Found"/>
    <cfabort/>
</cfif>

<cfquery name="qPortalBannerClick">
    SELECT *
    FROM tb_portal_banners
    WHERE id_banner = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.id_banner)#"/>
</cfquery>

<cfif NOT qPortalBannerClick.recordcount>
    <cfheader statuscode="404" statustext="Not Found"/>
    <cfabort/>
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
        <cfqueryparam cfsqltype="cf_sql_integer" value="#qPortalBannerClick.id_banner#"/>,
        'click',
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.canal)#" null="#NOT len(trim(URL.canal))#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.local)#" null="#NOT len(trim(URL.local))#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#structKeyExists(CGI, 'http_host') ? CGI.http_host : ''#" null="#NOT structKeyExists(CGI, 'http_host') OR NOT len(trim(CGI.http_host))#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.path)#" null="#NOT len(trim(URL.path))#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.portalBannerClickOriginSite#" null="#NOT len(VARIABLES.portalBannerClickOriginSite)#"/>,
        <cfqueryparam cfsqltype="cf_sql_integer" value="#isDefined('COOKIE.id') AND isNumeric(COOKIE.id) ? val(COOKIE.id) : 0#" null="#NOT isDefined('COOKIE.id') OR NOT isNumeric(COOKIE.id)#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#structKeyExists(CGI, 'remote_addr') ? CGI.remote_addr : ''#" null="#NOT structKeyExists(CGI, 'remote_addr') OR NOT len(trim(CGI.remote_addr))#"/>,
        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#structKeyExists(CGI, 'http_user_agent') ? CGI.http_user_agent : ''#" null="#NOT structKeyExists(CGI, 'http_user_agent') OR NOT len(trim(CGI.http_user_agent))#"/>,
        <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON({
            clickSource = structKeyExists(CGI, 'http_referer') ? CGI.http_referer : ''
        })#"/>::jsonb
    )
</cfquery>

<cfset VARIABLES.portalBannerClickDestination = trim(qPortalBannerClick.link_destino)/>

<cfif qPortalBannerClick.link_tipo EQ "interno"
    AND len(VARIABLES.portalBannerClickDestination)
    AND left(VARIABLES.portalBannerClickDestination, 1) EQ "/"
    AND len(VARIABLES.portalBannerClickOriginSite)>
    <cfset VARIABLES.portalBannerClickDestination = VARIABLES.portalBannerClickOriginSite & VARIABLES.portalBannerClickDestination/>
<cfelseif qPortalBannerClick.link_tipo EQ "interno"
    AND len(VARIABLES.portalBannerClickDestination)
    AND left(VARIABLES.portalBannerClickDestination, 1) EQ "/">
    <cfset VARIABLES.portalBannerClickDestination = "https://roadrunners.run" & VARIABLES.portalBannerClickDestination/>
</cfif>

<cflocation addtoken="false" url="#VARIABLES.portalBannerClickDestination#"/>
