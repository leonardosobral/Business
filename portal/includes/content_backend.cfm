<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.canal" default=""/>
<cfparam name="URL.status" default="todos"/>
<cfparam name="URL.destaque" default="todos"/>
<cfparam name="URL.published" default=""/>
<cfparam name="URL.summary_notice" default=""/>
<cfparam name="URL.summary_result" default=""/>

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
<cfset VARIABLES.contentFeaturedFilter = lCase(trim(URL.destaque))/>
<cfif NOT structKeyExists(SESSION, "contentSummaryCsrf") OR NOT len(trim(SESSION.contentSummaryCsrf & ""))>
    <cfset SESSION.contentSummaryCsrf = createUUID()/>
</cfif>
<cfset VARIABLES.contentSummaryCsrf = SESSION.contentSummaryCsrf/>

<cfif NOT listFindNoCase("todos,publicados,ocultos,pendentes,rejeitados", VARIABLES.contentStatusFilter)>
    <cfset VARIABLES.contentStatusFilter = "todos"/>
</cfif>
<cfif NOT listFindNoCase("todos,sim,nao", VARIABLES.contentFeaturedFilter)>
    <cfset VARIABLES.contentFeaturedFilter = "todos"/>
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

<cfquery name="qContentTypeColumns">
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentSchema#"/>
      AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentTypeTable#"/>
    ORDER BY ordinal_position
</cfquery>

<cfquery name="qContentSummarySchema">
    SELECT to_regclass('news.tb_article_summary_jobs') IS NOT NULL AS jobs_ready,
           to_regclass('news.tb_content_imports') IS NOT NULL AS imports_ready
</cfquery>

<cfset VARIABLES.contentColumns = ValueList(qContentColumns.column_name)/>
<cfset VARIABLES.contentUserColumns = ValueList(qContentUserColumns.column_name)/>
<cfset VARIABLES.contentTypeColumns = ValueList(qContentTypeColumns.column_name)/>
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
<cfset VARIABLES.contentSummaryReady = qContentSummarySchema.recordcount
    AND qContentSummarySchema.jobs_ready
    AND qContentSummarySchema.imports_ready
    AND ListFindNoCase(VARIABLES.contentTypeColumns, "rr_publication_mode")
    AND ListFindNoCase(VARIABLES.contentTypeColumns, "rr_license_expires_at")/>

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

VARIABLES.contentReturnUrl = "./?pagina=" & VARIABLES.contentPage
    & "&busca=" & urlEncodedFormat(URL.busca)
    & "&canal=" & urlEncodedFormat(URL.canal)
    & "&status=" & urlEncodedFormat(VARIABLES.contentStatusFilter)
    & "&destaque=" & urlEncodedFormat(VARIABLES.contentFeaturedFilter);

function contentSummaryProcess(required numeric contentId) {
    var result = {success=false,message="Não foi possível processar o resumo."};
    var secret = "";
    var endpoint = "";
    var httpResult = {};
    var statusCode = 0;
    var payload = {};
    var item = {};

    if (structKeyExists(APPLICATION, "cronJobs")
        AND isStruct(APPLICATION.cronJobs)
        AND structKeyExists(APPLICATION.cronJobs, "secrets")
        AND isStruct(APPLICATION.cronJobs.secrets)
        AND structKeyExists(APPLICATION.cronJobs.secrets, "conteudo_internal")) {
        secret = trim(APPLICATION.cronJobs.secrets.conteudo_internal & "");
    }
    if (!len(secret)) return {success=false,message="A credencial interna do processador de resumos não está configurada."};

    endpoint = reReplace(VARIABLES.contentAdminBaseUrl, "/+$", "", "all")
        & "/api/admin/jobs/article_summary.cfm?content_id=" & int(arguments.contentId);
    try {
        cfhttp(url=endpoint,method="post",result="httpResult",timeout=110,throwOnError=false,redirect=false) {
            cfhttpparam(type="header",name="Content-Type",value="application/json; charset=utf-8");
            cfhttpparam(type="header",name="X-API-Key",value=secret);
            cfhttpparam(type="body",value="{}");
        }
        statusCode = val(listFirst(httpResult.statusCode ?: "0", " "));
        if (statusCode LT 200 OR statusCode GTE 300 OR !isJSON(httpResult.fileContent ?: "")) {
            return {success=false,message="O processador de resumos não respondeu com sucesso (HTTP " & statusCode & ")."};
        }
        payload = deserializeJSON(httpResult.fileContent);
        if (!(payload.ok ?: false) OR !isArray(payload.results ?: "") OR !arrayLen(payload.results)) {
            return {success=false,message=left(trim(payload.message ?: payload.error ?: "Resposta inválida do processador de resumos."),500)};
        }
        item = payload.results[1];
        if (item.ready ?: false) return {success=true,message="Resumo por IA concluído e enviado para o fluxo editorial."};
        if ((item.reason ?: "") EQ "already_processing") return {success=false,message="Este resumo já está sendo processado. Atualize a página em instantes."};
        if ((item.reason ?: "") EQ "source_unavailable") return {success=false,message="A fonte integral não está mais disponível para reprocessamento. Reimporte o conteúdo antes de tentar novamente."};
        if ((item.reason ?: "") EQ "policy_changed") return {success=false,message="Este canal não está configurado para resumo por IA."};
        if (item.retry ?: false) return {success=false,message="A tentativa não foi concluída e ficou agendada para nova execução: " & left(trim(item.error ?: "falha temporária"),350)};
        return {success=false,message=left(trim(item.error ?: item.message ?: item.reason ?: "O resumo não foi concluído."),500)};
    } catch(any error) {
        return {success=false,message="Falha ao consultar o processador de resumos: " & left(trim(error.message ?: "erro desconhecido"),350)};
    }
}
</cfscript>

<cfif isDefined("FORM.process_summary_id")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin>
    <cfset VARIABLES.contentSummaryResult = {success=false,message="Solicitação inválida."}/>
    <cfif compare(trim(FORM.content_summary_csrf ?: ""), VARIABLES.contentSummaryCsrf) NEQ 0>
        <cfset VARIABLES.contentSummaryResult.message = "A sessão expirou. Atualize a página e tente novamente."/>
    <cfelseif NOT VARIABLES.contentSummaryReady>
        <cfset VARIABLES.contentSummaryResult.message = "O processador de resumos ainda não está instalado."/>
    <cfelseif NOT isNumeric(FORM.process_summary_id) OR val(FORM.process_summary_id) LTE 0>
        <cfset VARIABLES.contentSummaryResult.message = "Conteúdo inválido."/>
    <cfelse>
        <cfset VARIABLES.contentSummaryResult = contentSummaryProcess(int(FORM.process_summary_id))/>
    </cfif>
    <cfset VARIABLES.contentSummaryResultType = VARIABLES.contentSummaryResult.success ? "success" : "warning"/>
    <cflocation addtoken="false" url="#VARIABLES.contentReturnUrl#&summary_result=#VARIABLES.contentSummaryResultType#&summary_notice=#urlEncodedFormat(VARIABLES.contentSummaryResult.message)#"/>
</cfif>

<cfif isDefined("FORM.content_bulk_action")
    AND FORM.content_bulk_action EQ "apply_status"
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND isDefined("FORM.content_ids")
    AND isDefined("FORM.bulk_status")>

    <cfset VARIABLES.contentBulkStatus = lCase(trim(FORM.bulk_status & ""))/>
    <cfset VARIABLES.contentBulkIds = []/>

    <cfloop list="#FORM.content_ids#" index="contentBulkId">
        <cfif isNumeric(contentBulkId) AND int(contentBulkId) GT 0>
            <cfset arrayAppend(VARIABLES.contentBulkIds, int(contentBulkId))/>
        </cfif>
    </cfloop>

    <cfif arrayLen(VARIABLES.contentBulkIds)
        AND listFindNoCase("published,review,rejected,draft", VARIABLES.contentBulkStatus)>

        <cfset VARIABLES.contentBulkPublished = VARIABLES.contentBulkStatus EQ "published"/>

        <cfquery>
            UPDATE news.tb_content AS content_row
            SET published = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.contentBulkPublished#"/>,
                <cfif VARIABLES.contentHasEditorialStatus>
                    editorial_status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentBulkStatus#"/>,
                </cfif>
                <cfif VARIABLES.contentHasPublishedAt AND VARIABLES.contentBulkPublished>
                    published_at = COALESCE(
                        (
                            SELECT CASE
                                WHEN COALESCE(ci.detail_json ->> 'source_published_at', '') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
                                    THEN (ci.detail_json ->> 'source_published_at')::timestamp
                                WHEN COALESCE(ci.detail_json ->> 'source_pubdate', '') ~ '^[A-Za-z]{3},[[:space:]]+[0-9]{1,2}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{4}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+(GMT|UTC|[+-][0-9]{4})$'
                                    THEN (ci.detail_json ->> 'source_pubdate')::timestamptz AT TIME ZONE 'America/Sao_Paulo'
                                WHEN COALESCE(ci.detail_json ->> 'source_pubdate', '') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
                                    THEN (ci.detail_json ->> 'source_pubdate')::timestamptz AT TIME ZONE 'America/Sao_Paulo'
                                ELSE NULL
                            END
                            FROM news.tb_content_imports ci
                            WHERE ci.content_id = content_row.id
                            ORDER BY ci.updated_at DESC, ci.id DESC
                            LIMIT 1
                        ),
                        published_at,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                    ),
                </cfif>
                <cfif VARIABLES.contentHasIsFeatured AND NOT VARIABLES.contentBulkPublished>
                    is_featured = false,
                </cfif>
                <cfif VARIABLES.contentHasUpdatedAt>
                    updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                <cfelse>
                    id = id
                </cfif>
            WHERE id IN (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayToList(VARIABLES.contentBulkIds)#" list="true"/>
            )
        </cfquery>
    </cfif>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#"/>
</cfif>

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
        UPDATE news.tb_content AS content_row
        SET published = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.contentTogglePublished#"/>,
            <cfif VARIABLES.contentHasPublishedAt AND VARIABLES.contentTogglePublished>
                published_at = COALESCE(
                    (
                        SELECT CASE
                            WHEN COALESCE(ci.detail_json ->> 'source_published_at', '') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
                                THEN (ci.detail_json ->> 'source_published_at')::timestamp
                            WHEN COALESCE(ci.detail_json ->> 'source_pubdate', '') ~ '^[A-Za-z]{3},[[:space:]]+[0-9]{1,2}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{4}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+(GMT|UTC|[+-][0-9]{4})$'
                                THEN (ci.detail_json ->> 'source_pubdate')::timestamptz AT TIME ZONE 'America/Sao_Paulo'
                            WHEN COALESCE(ci.detail_json ->> 'source_pubdate', '') ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}'
                                THEN (ci.detail_json ->> 'source_pubdate')::timestamptz AT TIME ZONE 'America/Sao_Paulo'
                            ELSE NULL
                        END
                        FROM news.tb_content_imports ci
                        WHERE ci.content_id = content_row.id
                        ORDER BY ci.updated_at DESC, ci.id DESC
                        LIMIT 1
                    ),
                    published_at,
                    <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                ),
            </cfif>
            <cfif VARIABLES.contentHasIsFeatured AND NOT VARIABLES.contentTogglePublished>
                is_featured = false,
            </cfif>
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

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#"/>
</cfif>

<cfif isDefined("URL.acao")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND URL.acao EQ "editorial_status"
    AND VARIABLES.contentHasEditorialStatus
    AND isDefined("URL.content_id")
    AND isNumeric(URL.content_id)
    AND isDefined("URL.editorial_status")
    AND listFindNoCase("review,rejected", trim(URL.editorial_status))>

    <cfset VARIABLES.contentEditorialStatus = lCase(trim(URL.editorial_status))/>

    <cfquery>
        UPDATE news.tb_content
        SET published = false,
            editorial_status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.contentEditorialStatus#"/>,
            <cfif VARIABLES.contentHasIsFeatured>
                is_featured = false,
            </cfif>
            <cfif VARIABLES.contentHasUpdatedAt>
                updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
            <cfelse>
                id = id
            </cfif>
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.content_id#"/>
    </cfquery>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#"/>
</cfif>

<cfif isDefined("URL.acao")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND URL.acao EQ "destaque"
    AND VARIABLES.contentHasIsFeatured
    AND isDefined("URL.content_id")
    AND isNumeric(URL.content_id)
    AND isDefined("URL.featured")
    AND len(trim(URL.featured))>

    <cfset VARIABLES.contentToggleFeatured = IsBoolean(URL.featured) ? URL.featured : ListFindNoCase("true,1,yes,sim", trim(URL.featured & "")) GT 0/>

    <cftransaction>
        <cfif VARIABLES.contentToggleFeatured>
            <cfquery name="qContentFeaturedTarget">
                SELECT id
                FROM news.tb_content
                WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.content_id#"/>
                  AND published = true
                FOR UPDATE
            </cfquery>

            <cfif qContentFeaturedTarget.recordcount>
                <cfquery>
                    UPDATE news.tb_content
                    SET is_featured = false
                    WHERE is_featured = true
                      AND id <> <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.content_id#"/>
                </cfquery>
            </cfif>
        </cfif>

        <cfquery>
            UPDATE news.tb_content
            SET is_featured = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.contentToggleFeatured#"/>
                <cfif VARIABLES.contentHasUpdatedAt>, updated_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/></cfif>
            WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.content_id#"/>
              <cfif VARIABLES.contentToggleFeatured>AND published = true</cfif>
        </cfquery>
    </cftransaction>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#"/>
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
      <cfelseif VARIABLES.contentStatusFilter EQ "pendentes">
        AND cnt.published = false
        <cfif VARIABLES.contentHasEditorialStatus>
          AND lower(coalesce(cnt.editorial_status, '')) = 'review'
        <cfelse>
          AND 1 = 0
        </cfif>
      <cfelseif VARIABLES.contentStatusFilter EQ "rejeitados">
        AND cnt.published = false
        <cfif VARIABLES.contentHasEditorialStatus>
          AND lower(coalesce(cnt.editorial_status, '')) = 'rejected'
        <cfelse>
          AND 1 = 0
        </cfif>
      </cfif>
      <cfif VARIABLES.contentHasIsFeatured AND VARIABLES.contentFeaturedFilter EQ "sim">
        AND cnt.is_featured = true
      <cfelseif VARIABLES.contentHasIsFeatured AND VARIABLES.contentFeaturedFilter EQ "nao">
        AND cnt.is_featured = false
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
        count(*) FILTER (WHERE published = false AND <cfif VARIABLES.contentHasEditorialStatus>lower(coalesce(editorial_status, '')) = 'review'<cfelse>false</cfif>) AS total_pendentes,
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
           <cfif VARIABLES.contentHasFeaturedMedia>med.url_public<cfelse>NULL::text</cfif> AS featured_media_url,
           <cfif VARIABLES.contentSummaryReady>
             CASE
               WHEN typ.rr_publication_mode = 'licensed_full'
                AND typ.rr_license_expires_at IS NOT NULL
                AND typ.rr_license_expires_at < CURRENT_DATE THEN 'summary_link'
               ELSE typ.rr_publication_mode
             END AS summary_policy,
             COALESCE(summary_job.status, '') AS summary_status,
             COALESCE(summary_job.last_error, '') AS summary_error,
             summary_job.generated_at AS summary_generated_at,
             COALESCE(summary_job.model, '') AS summary_model,
             (length(btrim(COALESCE(cnt.body_html, ''))) > 0
               OR length(btrim(COALESCE(summary_import.source_description_html, ''))) > 0) AS summary_source_available
           <cfelse>
             ''::text AS summary_policy,
             ''::text AS summary_status,
             ''::text AS summary_error,
             NULL::timestamp AS summary_generated_at,
             ''::text AS summary_model,
             false AS summary_source_available
           </cfif>
    FROM news.tb_content cnt
    LEFT JOIN news.tb_content_types typ ON typ.id = cnt.content_type_id
    LEFT JOIN news.tb_categories cat ON cat.id = cnt.category_id
    LEFT JOIN news.tb_users usr ON usr.id = cnt.author_id
    <cfif VARIABLES.contentHasFeaturedMedia>
        LEFT JOIN news.tb_media med ON med.id = cnt.featured_media_id
    </cfif>
    <cfif VARIABLES.contentSummaryReady>
        LEFT JOIN LATERAL (
            SELECT j.status,j.last_error,j.generated_at,j.model
            FROM news.tb_article_summary_jobs j
            WHERE j.content_id = cnt.id
            ORDER BY j.updated_at DESC,j.id DESC
            LIMIT 1
        ) summary_job ON TRUE
        LEFT JOIN LATERAL (
            SELECT COALESCE(i.detail_json ->> 'source_description_html', '') AS source_description_html
            FROM news.tb_content_imports i
            WHERE i.content_id = cnt.id
            ORDER BY i.updated_at DESC,i.id DESC
            LIMIT 1
        ) summary_import ON TRUE
    </cfif>
    WHERE 1 = 1
      <cfif VARIABLES.contentStatusFilter EQ "publicados">
        AND cnt.published = true
      <cfelseif VARIABLES.contentStatusFilter EQ "ocultos">
        AND cnt.published = false
      <cfelseif VARIABLES.contentStatusFilter EQ "pendentes">
        AND cnt.published = false
        <cfif VARIABLES.contentHasEditorialStatus>
          AND lower(coalesce(cnt.editorial_status, '')) = 'review'
        <cfelse>
          AND 1 = 0
        </cfif>
      <cfelseif VARIABLES.contentStatusFilter EQ "rejeitados">
        AND cnt.published = false
        <cfif VARIABLES.contentHasEditorialStatus>
          AND lower(coalesce(cnt.editorial_status, '')) = 'rejected'
        <cfelse>
          AND 1 = 0
        </cfif>
      </cfif>
      <cfif VARIABLES.contentHasIsFeatured AND VARIABLES.contentFeaturedFilter EQ "sim">
        AND cnt.is_featured = true
      <cfelseif VARIABLES.contentHasIsFeatured AND VARIABLES.contentFeaturedFilter EQ "nao">
        AND cnt.is_featured = false
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
      <cfif VARIABLES.contentHasUpdatedAt>
        cnt.updated_at DESC NULLS LAST,
      </cfif>
      cnt.id DESC
    LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.contentPageSize#"/>
    OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.contentOffset#"/>
</cfquery>
