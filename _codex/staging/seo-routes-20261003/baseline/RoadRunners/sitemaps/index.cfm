<cfsetting enablecfoutputonly="true" requesttimeout="60" showdebugoutput="false"/>
<cfprocessingdirective pageencoding="utf-8"/>

<cfparam name="URL.section" default="index"/>
<cfparam name="URL.page" default="1"/>

<cfscript>
baseUrl = "https://roadrunners.run";
section = lCase(trim(URL.section & ""));
page = isNumeric(URL.page) && val(URL.page) GTE 1 ? int(URL.page) : 1;
eventPageSize = 15000;
xmlItems = [];
responseCacheControl = "public, max-age=900, stale-while-revalidate=3600";

function escapeXml(required any value) output="false" {
    return xmlFormat(arguments.value & "");
}

function isoDate(required any value) output="false" {
    if (!len(trim(arguments.value & ""))) {
        return "";
    }

    try {
        if (isDate(arguments.value)) {
            return dateFormat(arguments.value, "yyyy-mm-dd");
        }
        return dateFormat(parseDateTime(arguments.value & ""), "yyyy-mm-dd");
    } catch (any ignoredDateError) {
        if (reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}", trim(arguments.value & ""))) {
            return left(trim(arguments.value & ""), 10);
        }
    }

    return "";
}

function addUrl(required string loc, any lastmod = "") output="false" {
    arrayAppend(xmlItems, {
        "loc" = arguments.loc,
        "lastmod" = isoDate(arguments.lastmod)
    });
}

function addLocalizedEventUrls(required string tag, any lastmod = "") output="false" {
    // Tags are raw identifiers. Encode once as a path segment; never URL-decode stored percent signs.
    var encodedTag = replace(encodeForURL(arguments.tag), "+", "%20", "all");
    addUrl(baseUrl & "/evento/" & encodedTag & "/", arguments.lastmod);
    addUrl(baseUrl & "/en/event/" & encodedTag & "/", arguments.lastmod);
    addUrl(baseUrl & "/es/evento/" & encodedTag & "/", arguments.lastmod);
}

function renderUrlSet(required array items) output="false" {
    var xmlParts = ['<?xml version="1.0" encoding="UTF-8"?>' & chr(10)];
    var item = {};
    arrayAppend(xmlParts, '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' & chr(10));

    for (item in arguments.items) {
        arrayAppend(xmlParts, "  <url><loc>" & escapeXml(item.loc) & "</loc>");
        if (len(item.lastmod)) {
            arrayAppend(xmlParts, "<lastmod>" & escapeXml(item.lastmod) & "</lastmod>");
        }
        arrayAppend(xmlParts, "</url>" & chr(10));
    }

    arrayAppend(xmlParts, "</urlset>" & chr(10));
    return arrayToList(xmlParts, "");
}

function renderSitemapIndex(required array items) output="false" {
    var xml = '<?xml version="1.0" encoding="UTF-8"?>' & chr(10);
    var item = {};
    xml &= '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' & chr(10);

    for (item in arguments.items) {
        xml &= "  <sitemap><loc>" & escapeXml(item.loc) & "</loc></sitemap>" & chr(10);
    }

    return xml & "</sitemapindex>" & chr(10);
}

function buildChannelSlug(required string channelName) output="false" {
    var normalized = lCase(trim(arguments.channelName));
    normalized = replaceList(normalized, "á,à,â,ã,ä,å,é,è,ê,ë,í,ì,î,ï,ó,ò,ô,õ,ö,ú,ù,û,ü,ç,ñ", "a,a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c,n");
    normalized = reReplace(normalized, "[^a-z0-9]+", "-", "all");
    return reReplace(normalized, "^-+|-+$", "", "all");
}
</cfscript>

<cfif section EQ "index">
    <cfquery name="qEventCounts" cachedwithin="#CreateTimeSpan(0, 0, 15, 0)#">
        SELECT
            count(*) FILTER (WHERE data_final >= CURRENT_DATE - 1) AS upcoming_count,
            count(*) FILTER (WHERE data_final < CURRENT_DATE - 1) AS history_count
        FROM tb_evento_corridas
        WHERE ativo = true
          AND tag IS NOT NULL
          AND trim(tag) <> ''
    </cfquery>

    <cfscript>
    sitemapItems = [
        { "loc" = baseUrl & "/sitemaps/static.xml" },
        { "loc" = baseUrl & "/sitemaps/news-recent.xml" },
        { "loc" = baseUrl & "/sitemaps/videos.xml" }
    ];
    upcomingPages = max(1, ceiling(val(qEventCounts.upcoming_count) / eventPageSize));
    historyPages = max(1, ceiling(val(qEventCounts.history_count) / eventPageSize));

    for (pageIndex = 1; pageIndex LTE upcomingPages; pageIndex++) {
        arrayAppend(sitemapItems, { "loc" = baseUrl & "/sitemaps/events-upcoming-" & pageIndex & ".xml" });
    }
    for (pageIndex = 1; pageIndex LTE historyPages; pageIndex++) {
        arrayAppend(sitemapItems, { "loc" = baseUrl & "/sitemaps/events-history-" & pageIndex & ".xml" });
    }
    xmlOutput = renderSitemapIndex(sitemapItems);
    </cfscript>

<cfelseif section EQ "static">
    <cfscript>
    staticPaths = [
        "/", "/busca/", "/maratonas/", "/noticias/", "/videos/", "/sobre/", "/ajuda/", "/privacidade/",
        "/en/", "/en/search/", "/en/news/", "/en/videos/", "/en/about/", "/en/help/", "/en/privacy/",
        "/es/", "/es/busqueda/", "/es/noticias/", "/es/videos/", "/es/sobre/", "/es/ayuda/", "/es/privacidad/"
    ];
    stateCodes = listToArray("ac,al,am,ap,ba,ce,df,es,go,ma,mg,ms,mt,pa,pb,pe,pi,pr,rj,rn,ro,rr,rs,sc,se,sp,to");

    for (staticPath in staticPaths) {
        addUrl(baseUrl & staticPath, "2026-09-09");
    }
    for (stateCode in stateCodes) {
        addUrl(baseUrl & "/estado/" & stateCode & "/");
    }
    xmlOutput = renderUrlSet(xmlItems);
    </cfscript>

<cfelseif listFindNoCase("events-upcoming,events-history", section)>
    <cfset eventOffset = (page - 1) * eventPageSize/>
    <cfquery name="qSitemapEvents" cachedwithin="#CreateTimeSpan(0, 0, 15, 0)#">
        SELECT
            tag,
            COALESCE(data_processamento, data_inclusao, data_inicial::timestamp) AS last_modified
        FROM tb_evento_corridas
        WHERE ativo = true
          AND tag IS NOT NULL
          AND trim(tag) <> ''
          <cfif section EQ "events-upcoming">
              AND data_final >= CURRENT_DATE - 1
          <cfelse>
              AND data_final < CURRENT_DATE - 1
          </cfif>
        ORDER BY data_final DESC, id_evento DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#eventPageSize#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#eventOffset#"/>
    </cfquery>

    <cfscript>
    for (eventRow in qSitemapEvents) {
        addLocalizedEventUrls(eventRow.tag & "", eventRow.last_modified);
    }
    xmlOutput = renderUrlSet(xmlItems);
    </cfscript>

<cfelseif section EQ "news-recent">
    <cfscript>
    newsSitemapAvailable = false;
    try {
        newsService = createObject("component", "services.EditorialService").init("runnerhub", baseUrl, "https://conteudo.roadrunners.run");
        newsResult = newsService.listNews("", "", 1, 100);
        if (structKeyExists(newsResult, "success") && newsResult.success && structKeyExists(newsResult, "items") && isArray(newsResult.items)) {
            newsSitemapAvailable = true;
            for (newsItem in newsResult.items) {
                if (isStruct(newsItem) && structKeyExists(newsItem, "slug") && len(trim(newsItem.slug & ""))
                    && (!structKeyExists(newsItem, "channel") || !isStruct(newsItem.channel)
                        || !structKeyExists(newsItem.channel, "publicationMode") || newsItem.channel.publicationMode NEQ "external_only")) {
                    newsDate = structKeyExists(newsItem, "updatedAt") && len(trim(newsItem.updatedAt & "")) ? newsItem.updatedAt : newsItem.publishedAt;
                    if (len(isoDate(newsDate)) && dateDiff("d", parseDateTime(isoDate(newsDate)), now()) LTE 2) {
                        addUrl(baseUrl & "/noticias/" & trim(newsItem.slug & "") & "/", newsDate);
                    }
                }
            }
        }
    } catch (any newsSitemapError) {
        writeLog(file="roadrunners-seo", type="warning", text="News sitemap unavailable: " & left(newsSitemapError.message, 300));
    }
    xmlOutput = renderUrlSet(xmlItems);
    </cfscript>
    <cfif NOT newsSitemapAvailable>
        <cfset responseCacheControl = "no-store"/>
        <cfheader statuscode="503" statustext="Service Unavailable"/>
        <cfheader name="Retry-After" value="900"/>
    </cfif>

<cfelseif section EQ "videos">
    <cfquery name="qVideoSitemapChannels" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
        SELECT media_canal_nome, max(data_publicacao) AS last_published_at
        FROM tb_media
        WHERE pub_status = true
          AND media_canal_nome IS NOT NULL
          AND trim(media_canal_nome) <> ''
        GROUP BY media_canal_nome
        ORDER BY media_canal_nome
    </cfquery>

    <cfscript>
    for (videoChannel in qVideoSitemapChannels) {
        channelSlug = buildChannelSlug(videoChannel.media_canal_nome & "");
        if (len(channelSlug)) {
            addUrl(baseUrl & "/videos/canal/" & channelSlug & "/", videoChannel.last_published_at);
        }
    }
    xmlOutput = renderUrlSet(xmlItems);
    </cfscript>

<cfelse>
    <cfset responseCacheControl = "no-store"/>
    <cfheader statuscode="404" statustext="Not Found"/>
    <cfset xmlOutput = '<?xml version="1.0" encoding="UTF-8"?><error>Unknown sitemap section</error>'/>
</cfif>

<cfheader name="Cache-Control" value="#responseCacheControl#"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfcontent type="application/xml; charset=utf-8" reset="true"/>
<cfoutput>#xmlOutput#</cfoutput>
