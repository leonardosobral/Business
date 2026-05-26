<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.canal" default=""/>
<cfparam name="URL.status" default="todos"/>
<cfparam name="URL.published" default=""/>

<cfset VARIABLES.contentPageSize = 20/>
<cfset VARIABLES.contentPage = max(1, int(URL.pagina))/>
<cfset VARIABLES.contentOffset = (VARIABLES.contentPage - 1) * VARIABLES.contentPageSize/>
<cfset VARIABLES.contentSchema = "news"/>
<cfset VARIABLES.contentTable = "tb_content"/>
<cfset VARIABLES.contentTypeTable = "tb_content_types"/>
<cfset VARIABLES.contentCategoryTable = "tb_categories"/>
<cfset VARIABLES.contentUserTable = "tb_users"/>
<cfset VARIABLES.contentMediaTable = "tb_media"/>
<cfset VARIABLES.contentAdminBaseUrl = structKeyExists(APPLICATION, "contentAdmin") AND isStruct(APPLICATION.contentAdmin) AND structKeyExists(APPLICATION.contentAdmin, "baseUrl") ? trim(APPLICATION.contentAdmin.baseUrl) : "https://conteudo.roadrunners.run"/>
<cfset VARIABLES.contentStatusFilter = lCase(trim(URL.status))/>

<cfif NOT listFindNoCase("todos,publicados,ocultos", VARIABLES.contentStatusFilter)>
    <cfset VARIABLES.contentStatusFilter = "todos"/>
</cfif>

<cfquery name="qContentColumns">
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentSchema#"/>
      AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentTable#"/>
    ORDER BY ordinal_position
</cfquery>

<cfquery name="qContentUserColumns">
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentSchema#"/>
      AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentUserTable#"/>
    ORDER BY ordinal_position
</cfquery>

<cfset VARIABLES.contentColumns = ValueList(qContentColumns.column_name)/>
<cfset VARIABLES.contentUserColumns = ValueList(qContentUserColumns.column_name)/>
<cfset VARIABLES.contentHasExcerpt = ListFindNoCase(VARIABLES.contentColumns, "excerpt")/>
<cfset VARIABLES.contentHasPublishedAt = ListFindNoCase(VARIABLES.contentColumns, "published_at")/>
<cfset VARIABLES.contentHasEditorialStatus = ListFindNoCase(VARIABLES.contentColumns, "editorial_status")/>
<cfset VARIABLES.contentHasFeaturedMedia = ListFindNoCase(VARIABLES.contentColumns, "featured_media_id")/>
<cfset VARIABLES.contentHasIsFeatured = ListFindNoCase(VARIABLES.contentColumns, "is_featured")/>
<cfset VARIABLES.contentHasUpdatedAt = ListFindNoCase(VARIABLES.contentColumns, "updated_at")/>
<cfset VARIABLES.contentHasAuthorId = ListFindNoCase(VARIABLES.contentColumns, "author_id")/>
<cfset VARIABLES.contentHasContentTypeId = ListFindNoCase(VARIABLES.contentColumns, "content_type_id")/>
<cfset VARIABLES.contentHasCategoryId = ListFindNoCase(VARIABLES.contentColumns, "category_id")/>
<cfset VARIABLES.contentUserHasDisplayName = ListFindNoCase(VARIABLES.contentUserColumns, "display_name")/>
<cfset VARIABLES.contentUserHasName = ListFindNoCase(VARIABLES.contentUserColumns, "name")/>
<cfset VARIABLES.contentUserHasEmail = ListFindNoCase(VARIABLES.contentUserColumns, "email")/>

<cfscript>
VARIABLES.contentAuthorExpressionParts = [];

if (VARIABLES.contentUserHasDisplayName) {
    arrayAppend(VARIABLES.contentAuthorExpressionParts, "usr.display_name");
}
if (VARIABLES.contentUserHasName) {
    arrayAppend(VARIABLES.contentAuthorExpressionParts, "usr.name");
}
if (VARIABLES.contentUserHasEmail) {
    arrayAppend(VARIABLES.contentAuthorExpressionParts, "usr.email");
}

VARIABLES.contentAuthorExpression = arrayLen(VARIABLES.contentAuthorExpressionParts)
    ? "coalesce(" & arrayToList(VARIABLES.contentAuthorExpressionParts, ", ") & ", '')"
    : "''";
</cfscript>

<cfif isDefined("URL.acao")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND URL.acao EQ "pub_status"
    AND isDefined("URL.content_id")
    AND len(trim(URL.content_id))
    AND isNumeric(URL.content_id)
    AND len(trim(URL.published))>

    <cfset VARIABLES.contentTogglePublished = IsBoolean(URL.published) ? URL.published : ListFindNoCase("true,1,yes,sim", trim(URL.published & "")) GT 0/>

    <cfquery>
        UPDATE news.tb_content
        SET published = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.contentTogglePublished#"/>,
            <cfif VARIABLES.contentHasEditorialStatus>
                editorial_status =
                <cfif VARIABLES.contentTogglePublished>
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="published"/>,
                <cfelse>
                    CASE
                        WHEN editorial_status = 'published' THEN 'draft'
                        ELSE editorial_status
                    END,
                </cfif>
            </cfif>
            <cfif VARIABLES.contentHasUpdatedAt>
                updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
            <cfelse>
                id = id
            </cfif>
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.content_id#"/>
    </cfquery>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#"/>
</cfif>

<cfquery name="qContentTypes">
    SELECT id,
           name,
           slug
    FROM news.tb_content_types
    ORDER BY name
</cfquery>

<cfquery name="qContentCount">
    SELECT count(*) AS total
    FROM news.tb_content cnt
    LEFT JOIN news.tb_content_types typ ON typ.id = cnt.content_type_id
    WHERE 1 = 1
      <cfif VARIABLES.contentStatusFilter EQ "publicados">
        AND cnt.published = true
      <cfelseif VARIABLES.contentStatusFilter EQ "ocultos">
        AND cnt.published = false
      </cfif>
      <cfif len(trim(URL.canal))>
        AND lower(coalesce(typ.slug, '')) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(URL.canal))#"/>
      </cfif>
      <cfif len(trim(URL.busca))>
        AND (
            unaccent(lower(coalesce(cnt.title, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>))
            OR unaccent(lower(coalesce(cnt.slug, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>))
            <cfif VARIABLES.contentHasExcerpt>
                OR unaccent(lower(coalesce(cnt.excerpt, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>))
            </cfif>
        )
      </cfif>
</cfquery>

<cfset VARIABLES.contentTotalPages = max(1, ceiling(qContentCount.total / VARIABLES.contentPageSize))/>

<cfif VARIABLES.contentPage GT VARIABLES.contentTotalPages>
    <cfset VARIABLES.contentPage = VARIABLES.contentTotalPages/>
    <cfset VARIABLES.contentOffset = (VARIABLES.contentPage - 1) * VARIABLES.contentPageSize/>
</cfif>

<cfquery name="qContentStats">
    SELECT
        count(*) AS total,
        count(*) FILTER (WHERE published = true) AS total_publicados,
        count(*) FILTER (WHERE published = false) AS total_ocultos,
        count(*) FILTER (WHERE <cfif VARIABLES.contentHasIsFeatured>is_featured = true<cfelse>false</cfif>) AS total_destaques
    FROM news.tb_content
</cfquery>

<cfquery name="qContents">
    SELECT cnt.id,
           cnt.slug,
           cnt.title,
           <cfif VARIABLES.contentHasExcerpt>cnt.excerpt<cfelse>NULL::text AS excerpt</cfif>,
           cnt.published,
           <cfif VARIABLES.contentHasEditorialStatus>cnt.editorial_status<cfelse>CASE WHEN cnt.published THEN 'published' ELSE 'draft' END AS editorial_status</cfif>,
           <cfif VARIABLES.contentHasIsFeatured>cnt.is_featured<cfelse>false AS is_featured</cfif>,
           <cfif VARIABLES.contentHasPublishedAt>cnt.published_at<cfelse>NULL::timestamp AS published_at</cfif>,
           <cfif VARIABLES.contentHasUpdatedAt>cnt.updated_at<cfelse>cnt.created_at AS updated_at</cfif>,
           typ.name AS canal_nome,
           typ.slug AS canal_slug,
           cat.name AS categoria_nome,
           #preserveSingleQuotes(VARIABLES.contentAuthorExpression)# AS autor_nome,
           <cfif VARIABLES.contentHasFeaturedMedia>med.url_public<cfelse>NULL::text</cfif> AS featured_media_url
    FROM news.tb_content cnt
    LEFT JOIN news.tb_content_types typ ON typ.id = cnt.content_type_id
    LEFT JOIN news.tb_categories cat ON cat.id = cnt.category_id
    LEFT JOIN news.tb_users usr ON usr.id = cnt.author_id
    <cfif VARIABLES.contentHasFeaturedMedia>
        LEFT JOIN news.tb_media med ON med.id = cnt.featured_media_id
    </cfif>
    WHERE 1 = 1
      <cfif VARIABLES.contentStatusFilter EQ "publicados">
        AND cnt.published = true
      <cfelseif VARIABLES.contentStatusFilter EQ "ocultos">
        AND cnt.published = false
      </cfif>
      <cfif len(trim(URL.canal))>
        AND lower(coalesce(typ.slug, '')) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(URL.canal))#"/>
      </cfif>
      <cfif len(trim(URL.busca))>
        AND (
            unaccent(lower(coalesce(cnt.title, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>))
            OR unaccent(lower(coalesce(cnt.slug, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>))
            <cfif VARIABLES.contentHasExcerpt>
                OR unaccent(lower(coalesce(cnt.excerpt, ''))) LIKE unaccent(lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>))
            </cfif>
        )
      </cfif>
    ORDER BY
      <cfif VARIABLES.contentHasPublishedAt>
        cnt.published_at DESC NULLS LAST,
      </cfif>
      cnt.id DESC
    LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.contentPageSize#"/>
    OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.contentOffset#"/>
</cfquery>

<cfscript>
VARIABLES.contentImporters = [
    {
        key = "corridanoar",
        name = "Corrida no Ar",
        type = "RSS WordPress",
        feed = "https://corridanoar.com/feed/",
        description = "Importador dedicado com deduplicacao por origem, autoria fixa e mapeamento editorial automatico.",
        url = VARIABLES.contentAdminBaseUrl & "/admin/importer_corridanoar"
    },
    {
        key = "contrarelogio",
        name = "Contra Relogio",
        type = "RSS WordPress",
        feed = "https://contrarelogio.com.br/feed/",
        description = "Importador com autoria dinamica, pagina inicial configuravel e controle por blocos para evitar timeout.",
        url = VARIABLES.contentAdminBaseUrl & "/admin/importer_contrarelogio"
    },
    {
        key = "correriacampinas",
        name = "Correria Campinas",
        type = "RSS WordPress",
        feed = "https://correriacampinas.com.br/feed/",
        description = "Importador dedicado com varredura retroativa, deduplicacao e mapeamento editorial automatico.",
        url = VARIABLES.contentAdminBaseUrl & "/admin/importer_correriacampinas"
    }
];
</cfscript>
