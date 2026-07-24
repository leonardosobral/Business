<!DOCTYPE html>
<html lang="pt-br">
<cfprocessingdirective pageencoding="utf-8"/>

<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>

<cfparam name="URL.content_id" default="0"/>

<cfset VARIABLES.previewContentId = isNumeric(URL.content_id) ? int(URL.content_id) : 0/>
<cfset VARIABLES.previewBodyColumn = ""/>
<cfset VARIABLES.previewHasExcerpt = false/>
<cfset VARIABLES.previewHasFeaturedMedia = false/>
<cfset VARIABLES.previewHasPublishedAt = false/>

<cfquery name="qPreviewContentColumns">
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="news"/>
      AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_content"/>
</cfquery>

<cfset VARIABLES.previewContentColumns = valueList(qPreviewContentColumns.column_name)/>
<cfloop list="body_html,content_html,content,body,conteudo" index="previewBodyCandidate">
    <cfif NOT len(VARIABLES.previewBodyColumn) AND listFindNoCase(VARIABLES.previewContentColumns, previewBodyCandidate)>
        <cfset VARIABLES.previewBodyColumn = previewBodyCandidate/>
    </cfif>
</cfloop>
<cfset VARIABLES.previewHasExcerpt = listFindNoCase(VARIABLES.previewContentColumns, "excerpt") GT 0/>
<cfset VARIABLES.previewHasFeaturedMedia = listFindNoCase(VARIABLES.previewContentColumns, "featured_media_id") GT 0/>
<cfset VARIABLES.previewHasPublishedAt = listFindNoCase(VARIABLES.previewContentColumns, "published_at") GT 0/>

<cfquery name="qPreviewContent">
    SELECT cnt.id,
           cnt.title,
           cnt.slug,
           cnt.published,
           <cfif listFindNoCase(VARIABLES.previewContentColumns, "editorial_status")>cnt.editorial_status<cfelse>CASE WHEN cnt.published THEN 'published' ELSE 'draft' END AS editorial_status</cfif>,
           <cfif len(VARIABLES.previewBodyColumn)>
             cnt."#replace(VARIABLES.previewBodyColumn, '"', '""', 'all')#" AS article_body,
           <cfelse>
             ''::text AS article_body,
           </cfif>
           <cfif VARIABLES.previewHasExcerpt>cnt.excerpt<cfelse>''::text AS excerpt</cfif>,
           <cfif VARIABLES.previewHasPublishedAt>cnt.published_at<cfelse>NULL::timestamp AS published_at</cfif>,
           typ.name AS channel_name,
           cat.name AS category_name,
           <cfif VARIABLES.previewHasFeaturedMedia>med.url_public<cfelse>NULL::text</cfif> AS featured_media_url
    FROM news.tb_content cnt
    LEFT JOIN news.tb_content_types typ ON typ.id = cnt.content_type_id
    LEFT JOIN news.tb_categories cat ON cat.id = cnt.category_id
    <cfif VARIABLES.previewHasFeaturedMedia>
        LEFT JOIN news.tb_media med ON med.id = cnt.featured_media_id
    </cfif>
    WHERE cnt.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.previewContentId#"/>
    LIMIT 1
</cfquery>

<head>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <base href="https://conteudo.roadrunners.run/"/>
    <title><cfoutput><cfif qPreviewContent.recordcount>#htmlEditFormat(qPreviewContent.title)#<cfelse>Conteúdo não encontrado</cfif></cfoutput></title>
    <style>
        :root { color-scheme: light; }
        * { box-sizing: border-box; }
        body { margin: 0; background: #f4f4f4; color: #202124; font-family: Arial, Helvetica, sans-serif; line-height: 1.65; }
        .preview-shell { width: min(920px, calc(100% - 32px)); margin: 24px auto; padding: clamp(24px, 5vw, 56px); background: #fff; border-radius: 14px; box-shadow: 0 8px 28px rgba(0,0,0,.08); }
        .preview-status { display: inline-flex; margin-bottom: 18px; padding: 5px 10px; border-radius: 999px; background: #fff3cd; color: #664d03; font-size: 12px; font-weight: 700; text-transform: uppercase; }
        .preview-status.is-published { background: #d1e7dd; color: #0f5132; }
        .preview-meta { color: #6b7280; font-size: 14px; }
        h1 { margin: 10px 0 14px; font-size: clamp(30px, 5vw, 52px); line-height: 1.1; }
        .preview-excerpt { margin: 0 0 26px; color: #555; font-size: 19px; }
        .preview-cover { width: 100%; max-height: 520px; margin: 0 0 30px; border-radius: 10px; object-fit: cover; }
        .preview-body { overflow-wrap: anywhere; font-size: 17px; }
        .preview-body img, .preview-body video, .preview-body iframe { max-width: 100%; height: auto; }
        .preview-body table { display: block; max-width: 100%; overflow-x: auto; }
        .preview-empty { padding: 80px 20px; text-align: center; }
    </style>
</head>
<body>
<cfif qPreviewContent.recordcount>
    <cfoutput query="qPreviewContent">
        <article class="preview-shell">
            <span class="preview-status<cfif published> is-published</cfif>"><cfif published>Publicado<cfelseif lCase(trim(editorial_status & "")) EQ "rejected">Rejeitado — prévia administrativa<cfelse>Oculto — prévia administrativa</cfif></span>
            <div class="preview-meta">
                <cfif len(trim(channel_name & ""))>#htmlEditFormat(channel_name)#</cfif>
                <cfif len(trim(category_name & ""))> · #htmlEditFormat(category_name)#</cfif>
                <cfif isDate(published_at)> · #dateTimeFormat(published_at, "dd/mm/yyyy HH:nn")#</cfif>
            </div>
            <h1>#htmlEditFormat(title)#</h1>
            <cfif len(trim(excerpt & ""))><p class="preview-excerpt">#htmlEditFormat(excerpt)#</p></cfif>
            <cfif len(trim(featured_media_url & ""))><img class="preview-cover" src="#htmlEditFormat(featured_media_url)#" alt=""/></cfif>
            <div class="preview-body">#article_body#</div>
        </article>
    </cfoutput>
<cfelse>
    <div class="preview-empty">
        <h1>Conteúdo não encontrado</h1>
        <p>O conteúdo solicitado não existe ou não está mais disponível.</p>
    </div>
</cfif>
</body>
</html>
