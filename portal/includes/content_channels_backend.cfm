<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.contentChannelPage = max(1, int(URL.pagina))/>
<cfset VARIABLES.contentChannelSchema = "news"/>
<cfset VARIABLES.contentChannelTable = "tb_content_types"/>
<cfset VARIABLES.contentChannelPk = ""/>
<cfset VARIABLES.contentChannelPortalColumn = "rr_portal_enabled"/>
<cfset VARIABLES.contentChannelHomeFeaturedColumn = "rr_home_featured_enabled"/>
<cfset VARIABLES.contentChannelNewsFeaturedColumn = "rr_news_featured_enabled"/>
<cfset VARIABLES.contentChannelAllowedToggleColumns = "rr_portal_enabled,rr_home_featured_enabled,rr_news_featured_enabled"/>

<cfquery name="qContentChannelColumns">
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentChannelSchema#"/>
      AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentChannelTable#"/>
    ORDER BY ordinal_position
</cfquery>

<cfset VARIABLES.contentChannelColumns = ValueList(qContentChannelColumns.column_name)/>

<cfloop list="id,content_type_id" item="contentChannelPkCandidate">
    <cfif NOT len(trim(VARIABLES.contentChannelPk)) AND ListFindNoCase(VARIABLES.contentChannelColumns, contentChannelPkCandidate)>
        <cfset VARIABLES.contentChannelPk = contentChannelPkCandidate/>
    </cfif>
</cfloop>

<cfif NOT len(trim(VARIABLES.contentChannelPk)) AND qContentChannelColumns.recordcount>
    <cfset VARIABLES.contentChannelPk = qContentChannelColumns.column_name/>
</cfif>

<cfset VARIABLES.contentChannelHasPortalColumn = ListFindNoCase(VARIABLES.contentChannelColumns, VARIABLES.contentChannelPortalColumn)/>
<cfset VARIABLES.contentChannelHasHomeFeaturedColumn = ListFindNoCase(VARIABLES.contentChannelColumns, VARIABLES.contentChannelHomeFeaturedColumn)/>
<cfset VARIABLES.contentChannelHasNewsFeaturedColumn = ListFindNoCase(VARIABLES.contentChannelColumns, VARIABLES.contentChannelNewsFeaturedColumn)/>
<cfset VARIABLES.contentChannelAllFlagsReady = VARIABLES.contentChannelHasPortalColumn AND VARIABLES.contentChannelHasHomeFeaturedColumn AND VARIABLES.contentChannelHasNewsFeaturedColumn/>
<cfset VARIABLES.contentChannelHasNameColumn = ListFindNoCase(VARIABLES.contentChannelColumns, "name")/>
<cfset VARIABLES.contentChannelHasSlugColumn = ListFindNoCase(VARIABLES.contentChannelColumns, "slug")/>
<cfset VARIABLES.contentChannelHasWebsiteUrlColumn = ListFindNoCase(VARIABLES.contentChannelColumns, "website_url")/>

<cfif isDefined("URL.acao")
    AND URL.acao EQ "toggle"
    AND isDefined("URL.canal_id")
    AND isDefined("URL.campo")
    AND isDefined("URL.status")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND len(trim(VARIABLES.contentChannelPk))
    AND ListFindNoCase(VARIABLES.contentChannelAllowedToggleColumns, URL.campo)
    AND ListFindNoCase(VARIABLES.contentChannelColumns, URL.campo)>

    <cfquery>
        UPDATE news.tb_content_types
        SET "#Replace(URL.campo, '"', '""', 'all')#" = <cfqueryparam cfsqltype="cf_sql_bit" value="#URL.status#"/>
        WHERE "#Replace(VARIABLES.contentChannelPk, '"', '""', 'all')#" =
        <cfif IsNumeric(URL.canal_id)>
            <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.canal_id#"/>
        <cfelse>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.canal_id#"/>
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.contentChannelPage#"/>
</cfif>

<cfif qContentChannelColumns.recordcount>
    <cfquery name="qContentChannelsCount">
        SELECT count(*) AS total
        FROM news.tb_content_types
    </cfquery>
<cfelse>
    <cfset qContentChannelsCount = QueryNew("total", "integer")/>
    <cfset QueryAddRow(qContentChannelsCount, 1)/>
    <cfset QuerySetCell(qContentChannelsCount, "total", 0, 1)/>
</cfif>

<cfif qContentChannelColumns.recordcount AND len(trim(VARIABLES.contentChannelPk))>
    <cfquery name="qContentChannels">
        SELECT
            "#Replace(VARIABLES.contentChannelPk, '"', '""', 'all')#",
            <cfif VARIABLES.contentChannelHasNameColumn>"name"<cfelse>NULL::text AS name</cfif>,
            <cfif VARIABLES.contentChannelHasSlugColumn>"slug"<cfelse>NULL::text AS slug</cfif>,
            <cfif VARIABLES.contentChannelHasWebsiteUrlColumn>"website_url"<cfelse>NULL::text AS website_url</cfif>,
            <cfif VARIABLES.contentChannelHasPortalColumn>"#Replace(VARIABLES.contentChannelPortalColumn, '"', '""', 'all')#"<cfelse>false AS "#VARIABLES.contentChannelPortalColumn#"</cfif>,
            <cfif VARIABLES.contentChannelHasHomeFeaturedColumn>"#Replace(VARIABLES.contentChannelHomeFeaturedColumn, '"', '""', 'all')#"<cfelse>false AS "#VARIABLES.contentChannelHomeFeaturedColumn#"</cfif>,
            <cfif VARIABLES.contentChannelHasNewsFeaturedColumn>"#Replace(VARIABLES.contentChannelNewsFeaturedColumn, '"', '""', 'all')#"<cfelse>false AS "#VARIABLES.contentChannelNewsFeaturedColumn#"</cfif>
        FROM news.tb_content_types
        ORDER BY
            <cfif VARIABLES.contentChannelHasNameColumn>"name"<cfelse>"#Replace(VARIABLES.contentChannelPk, '"', '""', 'all')#"</cfif> ASC
    </cfquery>
<cfelse>
    <cfset qContentChannels = QueryNew("")/>
</cfif>
