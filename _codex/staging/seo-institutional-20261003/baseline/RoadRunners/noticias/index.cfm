<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/noticias/"/>
<cfset VARIABLES.routeKey = "news"/>

<!--- PARAMS --->
<cfparam name="URL.tag" default=""/>
<cfparam name="URL.page" default="1"/>
<cfparam name="URL.canal" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>
<cfset URL.page = isNumeric(URL.page) AND URL.page GTE 1 ? int(URL.page) : 1/>
<cfset URL.canal = lCase(trim(URL.canal))/>
<cfset VARIABLES.isNoticiaDetalhe = len(trim(URL.tag))>
<cfset VARIABLES.newsRootUrl = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("news") : "/noticias/"/>
<cfset VARIABLES.newsChannelSegment = structKeyExists(REQUEST, "t") ? REQUEST.t('news.routes.channelSegment') : "canal"/>
<cfset VARIABLES.newsAggregatorFallbacks = {
    "pt-BR" = {
        "label" = "Agregador de notícias",
        "copy" = "Uma seleção das fontes mais relevantes e confiáveis sobre corrida de rua, reunida em um só lugar."
    },
    "en" = {
        "label" = "News aggregator",
        "copy" = "A curated selection from the most relevant and trusted road running sources, brought together in one place."
    },
    "es" = {
        "label" = "Agregador de noticias",
        "copy" = "Una selección de las fuentes más relevantes y confiables sobre carreras de calle, reunida en un solo lugar."
    }
}/>
<cfset VARIABLES.newsAggregatorLanguage = structKeyExists(REQUEST, "lang") AND structKeyExists(VARIABLES.newsAggregatorFallbacks, REQUEST.lang) ? REQUEST.lang : "pt-BR"/>
<cfset VARIABLES.newsAggregatorLabel = structKeyExists(REQUEST, "t") ? REQUEST.t("news.hero.aggregatorLabel") : ""/>
<cfset VARIABLES.newsAggregatorCopy = structKeyExists(REQUEST, "t") ? REQUEST.t("news.hero.aggregatorCopy") : ""/>
<cfif NOT len(trim(VARIABLES.newsAggregatorLabel)) OR VARIABLES.newsAggregatorLabel EQ "news.hero.aggregatorLabel">
    <cfset VARIABLES.newsAggregatorLabel = VARIABLES.newsAggregatorFallbacks[VARIABLES.newsAggregatorLanguage].label/>
</cfif>
<cfif NOT len(trim(VARIABLES.newsAggregatorCopy)) OR VARIABLES.newsAggregatorCopy EQ "news.hero.aggregatorCopy">
    <cfset VARIABLES.newsAggregatorCopy = VARIABLES.newsAggregatorFallbacks[VARIABLES.newsAggregatorLanguage].copy/>
</cfif>
<cfset VARIABLES.baseNoticiasUrl = len(trim(URL.canal)) ? "#VARIABLES.newsRootUrl##VARIABLES.newsChannelSegment#/#URL.canal#/" : VARIABLES.newsRootUrl>
<cfset VARIABLES.newsRequestPath = structKeyExists(CGI, "REQUEST_URI") ? lCase(listFirst(trim(CGI.REQUEST_URI), "?")) : ""/>
<cfset VARIABLES.newsChannelPathWithoutSlug = rereplace(VARIABLES.newsRequestPath, "/+$", "", "all") & "/" />
<cfif NOT len(trim(URL.canal)) AND (
    (len(trim(URL.tag)) AND lCase(trim(URL.tag)) EQ lCase(trim(VARIABLES.newsChannelSegment)))
    OR VARIABLES.newsChannelPathWithoutSlug EQ "/noticias/#lCase(trim(VARIABLES.newsChannelSegment))#/"
    OR VARIABLES.newsChannelPathWithoutSlug EQ "/en/news/channel/"
    OR VARIABLES.newsChannelPathWithoutSlug EQ "/es/noticias/canal/"
)>
    <cflocation url="#VARIABLES.newsRootUrl#" addtoken="false"/>
</cfif>

<!--- VARIAVEIS --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>

<!--- LOCATION --->
<cfinclude template="../includes/location.cfm"/>

<!--- BACKEND --->
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/backend_conteudo_canais.cfm"/>

<!--- CONTEUDO API --->
<cfset VARIABLES.apiConteudoBase = "https://conteudo.roadrunners.run"/>
<cfset VARIABLES.apiConteudoInternalBase = "http://127.0.0.1:8500"/>
<cfset VARIABLES.useConteudoInternalBase = structKeyExists(REQUEST, "currentEnvironment") AND REQUEST.currentEnvironment EQ "prod"/>

<cfscript>
function fetchNoticiasApi(required string resource, numeric timeoutSeconds = 8) output="false" {
    var requestBases = [VARIABLES.apiConteudoBase];
    var requestBase = "";
    var httpResponse = {};
    var statusCode = 0;
    var failureSummary = [];
    var attempt = 0;

    if (VARIABLES.useConteudoInternalBase) {
        arrayPrepend(requestBases, VARIABLES.apiConteudoInternalBase);
    }

    for (attempt = 1; attempt LTE arrayLen(requestBases); attempt++) {
        requestBase = requestBases[attempt];
        httpResponse = {};

        try {
            cfhttp(
                url = requestBase & arguments.resource,
                method = "get",
                timeout = arguments.timeoutSeconds,
                throwOnError = false,
                result = "httpResponse"
            ) {
                cfhttpparam(type = "header", name = "Host", value = "conteudo.roadrunners.run");
                cfhttpparam(type = "header", name = "X-Forwarded-Proto", value = "https");
            }

            statusCode = structKeyExists(httpResponse, "statusCode") ? val(httpResponse.statusCode) : 0;
            if (
                statusCode GTE 200
                AND statusCode LT 300
                AND structKeyExists(httpResponse, "fileContent")
                AND isJSON(httpResponse.fileContent)
            ) {
                return deserializeJSON(httpResponse.fileContent);
            }

            arrayAppend(failureSummary, requestBase & " status=" & statusCode);
        } catch (any requestError) {
            arrayAppend(failureSummary, requestBase & " error=" & left(requestError.message, 160));
        }
    }

    writeLog(
        file = "roadrunners-content-api",
        type = "warning",
        text = "News API unavailable for " & arguments.resource & ": " & arrayToList(failureSummary, "; ")
    );
    return {};
}

function addNewsSourceAttribution(required string rawUrl, string placement = "article_source_link") output="false" {
    var targetUrl = trim(arguments.rawUrl);
    var fragment = "";
    var fragmentPosition = 0;
    var separator = "?";
    var parameter = {};
    var parameters = [
        {name="utm_source", value="roadrunners"},
        {name="utm_medium", value="referral"},
        {name="utm_campaign", value="news_aggregator"},
        {name="utm_content", value=arguments.placement}
    ];

    if (!reFindNoCase("^https?://", targetUrl)) {
        return targetUrl;
    }

    fragmentPosition = find(chr(35), targetUrl);
    if (fragmentPosition GT 0) {
        fragment = mid(targetUrl, fragmentPosition, len(targetUrl));
        targetUrl = left(targetUrl, fragmentPosition - 1);
    }

    separator = find("?", targetUrl) GT 0 ? (reFind("[?&]$", targetUrl) ? "" : "&") : "?";
    for (parameter in parameters) {
        if (!reFindNoCase("([?&])" & parameter.name & "=", targetUrl)) {
            targetUrl &= separator & parameter.name & "=" & urlEncodedFormat(parameter.value, "UTF-8");
            separator = "&";
        }
    }

    return targetUrl & fragment;
}

function newsPlainText(any rawValue = "") output="false" {
    var textValue = isSimpleValue(arguments.rawValue) ? (arguments.rawValue & "") : "";
    textValue = reReplaceNoCase(textValue, "<[^>]+>", " ", "all");
    textValue = replaceNoCase(textValue, "&nbsp;", " ", "all");
    textValue = replaceNoCase(textValue, "&amp;", "&", "all");
    textValue = reReplace(textValue, "[[:space:]]+", " ", "all");
    return trim(textValue);
}

function newsMetaDescription(any preferredValue = "", any fallbackValue = "") output="false" {
    var descriptionValue = newsPlainText(arguments.preferredValue);
    if (!len(descriptionValue)) descriptionValue = newsPlainText(arguments.fallbackValue);
    if (len(descriptionValue) LTE 220) return descriptionValue;
    descriptionValue = reReplace(left(descriptionValue, 220), "[[:space:]]+[^[:space:]]*$", "", "one");
    return trim(descriptionValue) & "…";
}

function newsSummaryParagraphs(any rawValue = "") output="false" {
    var normalizedValue = isSimpleValue(arguments.rawValue) ? replace(arguments.rawValue & "", chr(13), "", "all") : "";
    var paragraphDelimiter = chr(30);
    var paragraphCandidates = listToArray(reReplace(trim(normalizedValue), "\n[[:space:]]*\n+", paragraphDelimiter, "all"), paragraphDelimiter, true);
    var paragraphs = [];
    var paragraphValue = "";
    for (paragraphValue in paragraphCandidates) {
        paragraphValue = newsPlainText(paragraphValue);
        if (len(paragraphValue)) arrayAppend(paragraphs, paragraphValue);
    }
    if (!arrayLen(paragraphs) AND len(newsPlainText(normalizedValue))) arrayAppend(paragraphs, newsPlainText(normalizedValue));
    return paragraphs;
}
</cfscript>

<cfset VARIABLES.apiNoticias = {}>
<cfset VARIABLES.noticias = []>
<cfset VARIABLES.noticiasPaginadas = []>
<cfset VARIABLES.totalPaginasNoticias = 1>
<cfset VARIABLES.noticia = {}>
<cfset VARIABLES.noticiaEncontrada = false>
<cfset VARIABLES.noticiasSidebar = []>
<cfset VARIABLES.noticiasRelacionadas = []>
<cfset VARIABLES.itensPorPaginaNoticias = 11>
<cfset VARIABLES.canaisNoticias = []>
<cfset VARIABLES.canaisNoticiasMap = {}>
<cfset VARIABLES.noticiasFiltradas = []>
<cfset VARIABLES.canalNoticiasAtivoConfig = {} >
<cfset VARIABLES.noticiaEventoRelacionado = {}>

<cfif VARIABLES.isNoticiaDetalhe>
    <cfset VARIABLES.noticia = fetchNoticiasApi("/rest/cmscf_api/v1/content/#URL.tag#")>
    <cfif isStruct(VARIABLES.noticia) AND structKeyExists(VARIABLES.noticia, "slug")>
            <cfset VARIABLES.noticiaEncontrada = true>
            <cfif structKeyExists(VARIABLES.noticia, "id_evento")
                AND isNumeric(VARIABLES.noticia.id_evento)
                AND val(VARIABLES.noticia.id_evento) GT 0
                AND structKeyExists(VARIABLES.noticia, "event")
                AND isStruct(VARIABLES.noticia.event)
                AND structCount(VARIABLES.noticia.event)>
                <cfset VARIABLES.noticiaEventoRelacionado = duplicate(VARIABLES.noticia.event)>

                <cftry>
                    <cfquery name="qNoticiaEventoRelacionadoDetalhes" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#" result="qNoticiaEventoRelacionadoDetalhesMeta">
                        SELECT
                            evt.data_inicial,
                            evt.data_final,
                            evt.categorias,
                            coalesce(
                                (
                                    SELECT json_agg(evento_distancias.percurso ORDER BY evento_distancias.percurso)
                                    FROM (
                                        SELECT DISTINCT percurso.percurso_evento::integer AS percurso
                                        FROM tb_evento_corridas_percursos percurso
                                        WHERE percurso.id_evento = evt.id_evento
                                        AND lower(trim(percurso.unidade_de_medida)) IN ('km', 'k')
                                        AND percurso.percurso_evento > 3
                                        AND percurso.percurso_evento = trunc(percurso.percurso_evento)
                                    ) evento_distancias
                                ),
                                '[]'::json
                            ) AS distancias,
                            coalesce(
                                (
                                    SELECT sum(resumo.concluintes)
                                    FROM tb_resultados_resumo resumo
                                    WHERE resumo.id_evento = evt.id_evento
                                ),
                                0
                            )::integer AS concluintes,
                            EXISTS (
                                SELECT 1
                                FROM tb_resultados_resumo resumo_publicado
                                WHERE resumo_publicado.id_evento = evt.id_evento
                            ) AS resultado_publicado
                        FROM tb_evento_corridas evt
                        WHERE evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.noticia.id_evento#"/>
                        LIMIT 1
                    </cfquery>
                    <cfset logQueryDebug("qNoticiaEventoRelacionadoDetalhes", qNoticiaEventoRelacionadoDetalhesMeta, "noticias/evento_relacionado", "5min", qNoticiaEventoRelacionadoDetalhes)/>

                    <cfif qNoticiaEventoRelacionadoDetalhes.recordcount>
                        <cfset VARIABLES.noticiaEventoRelacionado["distances"] = []/>
                        <cfif isDate(qNoticiaEventoRelacionadoDetalhes.data_inicial)>
                            <cfset VARIABLES.noticiaEventoRelacionado["data_inicial"] = qNoticiaEventoRelacionadoDetalhes.data_inicial/>
                        </cfif>
                        <cfif isDate(qNoticiaEventoRelacionadoDetalhes.data_final)>
                            <cfset VARIABLES.noticiaEventoRelacionado["data_final"] = qNoticiaEventoRelacionadoDetalhes.data_final/>
                        </cfif>
                        <cfif len(trim(qNoticiaEventoRelacionadoDetalhes.distancias & "")) AND isJSON(trim(qNoticiaEventoRelacionadoDetalhes.distancias & ""))>
                            <cfset VARIABLES.noticiaEventoRelacionado["distances"] = deserializeJSON(trim(qNoticiaEventoRelacionadoDetalhes.distancias & ""))/>
                        </cfif>
                        <cfif len(trim(qNoticiaEventoRelacionadoDetalhes.categorias & ""))>
                            <cfloop list="#replace(qNoticiaEventoRelacionadoDetalhes.categorias & "", ";", ",", "all")#" index="VARIABLES.noticiaEventoRelacionadoCategoriaDistancia">
                                <cfif reFindNoCase("^[0-9]+\s*km$", trim(VARIABLES.noticiaEventoRelacionadoCategoriaDistancia))>
                                    <cfset arrayAppend(VARIABLES.noticiaEventoRelacionado["distances"], val(trim(VARIABLES.noticiaEventoRelacionadoCategoriaDistancia)))/>
                                </cfif>
                            </cfloop>
                        </cfif>
                        <cfif structKeyExists(VARIABLES.noticiaEventoRelacionado, "max_percurso")
                            AND isNumeric(VARIABLES.noticiaEventoRelacionado.max_percurso)>
                            <cfset arrayAppend(VARIABLES.noticiaEventoRelacionado["distances"], val(VARIABLES.noticiaEventoRelacionado.max_percurso))/>
                        </cfif>
                        <cfset VARIABLES.noticiaEventoRelacionado["finishers"] = val(qNoticiaEventoRelacionadoDetalhes.concluintes)/>
                        <cfset VARIABLES.noticiaEventoRelacionado["has_published_results"] = isBoolean(qNoticiaEventoRelacionadoDetalhes.resultado_publicado)
                            ? javacast("boolean", qNoticiaEventoRelacionadoDetalhes.resultado_publicado)
                            : listFindNoCase("1,true,yes,sim,s", trim(qNoticiaEventoRelacionadoDetalhes.resultado_publicado & "")) GT 0/>
                    </cfif>
                <cfcatch type="any"></cfcatch>
                </cftry>
            </cfif>
    </cfif>
<cfelse>
    <cfif structKeyExists(REQUEST, "contentChannelPortalConfigs") AND isArray(REQUEST.contentChannelPortalConfigs)>
        <cfset VARIABLES.canaisNoticias = duplicate(REQUEST.contentChannelPortalConfigs)>
    </cfif>
    <cfif structKeyExists(REQUEST, "contentChannelConfigBySlug") AND isStruct(REQUEST.contentChannelConfigBySlug)>
        <cfset VARIABLES.canaisNoticiasMap = duplicate(REQUEST.contentChannelConfigBySlug)>
    </cfif>

    <cfif len(trim(URL.canal)) AND structKeyExists(VARIABLES.canaisNoticiasMap, URL.canal) AND isStruct(VARIABLES.canaisNoticiasMap[URL.canal])>
        <cfset VARIABLES.canalNoticiasAtivoConfig = duplicate(VARIABLES.canaisNoticiasMap[URL.canal])>
        <cfif structKeyExists(VARIABLES.canalNoticiasAtivoConfig, "logo_url") AND len(trim(VARIABLES.canalNoticiasAtivoConfig.logo_url)) AND left(trim(VARIABLES.canalNoticiasAtivoConfig.logo_url), 1) EQ "/">
            <cfset VARIABLES.canalNoticiasAtivoConfig.logo_url = VARIABLES.apiConteudoBase & VARIABLES.canalNoticiasAtivoConfig.logo_url>
        </cfif>
    <cfelseif len(trim(URL.canal))>
        <cflocation url="#VARIABLES.newsRootUrl#" addtoken="false"/>
    </cfif>

    <cfset VARIABLES.noticiasApiResource = "/rest/cmscf_api/v1/content?per_page=#VARIABLES.itensPorPaginaNoticias#&page=#URL.page#&sort=published_at&dir=desc"/>
    <cfif len(trim(URL.canal))>
        <cfset VARIABLES.noticiasApiResource &= "&content_type=#urlEncodedFormat(URL.canal)#"/>
    </cfif>

    <cfset VARIABLES.apiNoticias = fetchNoticiasApi(VARIABLES.noticiasApiResource)>
    <cfif isStruct(VARIABLES.apiNoticias)
        AND structKeyExists(VARIABLES.apiNoticias, "items")
        AND isArray(VARIABLES.apiNoticias.items)>
        <cfset VARIABLES.noticias = duplicate(VARIABLES.apiNoticias.items)>
        <cfset VARIABLES.noticiasFiltradas = duplicate(VARIABLES.apiNoticias.items)>
        <cfset VARIABLES.noticiasPaginadas = duplicate(VARIABLES.apiNoticias.items)>
    </cfif>
    <cfif structKeyExists(VARIABLES.apiNoticias, "pagination")
        AND isStruct(VARIABLES.apiNoticias.pagination)
        AND structKeyExists(VARIABLES.apiNoticias.pagination, "total_pages")
        AND isNumeric(VARIABLES.apiNoticias.pagination.total_pages)>
        <cfset VARIABLES.totalPaginasNoticias = max(1, int(VARIABLES.apiNoticias.pagination.total_pages))>
    </cfif>
</cfif>

<cfset VARIABLES.apiSidebarNoticias = fetchNoticiasApi("/rest/cmscf_api/v1/content?per_page=20&sort=published_at&dir=desc")>
<cfif isStruct(VARIABLES.apiSidebarNoticias) AND structKeyExists(VARIABLES.apiSidebarNoticias, "items") AND isArray(VARIABLES.apiSidebarNoticias.items)>
    <cfloop array="#VARIABLES.apiSidebarNoticias.items#" index="item">
        <cfif NOT (VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada AND structKeyExists(item, "slug") AND item.slug EQ VARIABLES.noticia.slug)>
            <cfset arrayAppend(VARIABLES.noticiasSidebar, item)>
        </cfif>
        <cfif arrayLen(VARIABLES.noticiasSidebar) GTE 3>
            <cfbreak>
        </cfif>
    </cfloop>
</cfif>

<cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada>
    <cfset VARIABLES.relatedCategoryPool = []>
    <cfset VARIABLES.relatedChannelPool = []>
    <cfset VARIABLES.relatedFallbackPool = []>
    <cfset VARIABLES.relatedCurrentCategoryKey = "">
    <cfset VARIABLES.relatedCurrentChannelKey = "">
    <cfset VARIABLES.relatedSeen = {}>

    <cfif structKeyExists(VARIABLES.noticia, "category") AND isStruct(VARIABLES.noticia.category)>
        <cfif structKeyExists(VARIABLES.noticia.category, "slug") AND len(trim(VARIABLES.noticia.category.slug))>
            <cfset VARIABLES.relatedCurrentCategoryKey = lCase(trim(VARIABLES.noticia.category.slug))>
        <cfelseif structKeyExists(VARIABLES.noticia.category, "name") AND len(trim(VARIABLES.noticia.category.name))>
            <cfset VARIABLES.relatedCurrentCategoryKey = lCase(trim(VARIABLES.noticia.category.name))>
        </cfif>
    </cfif>

    <cfif structKeyExists(VARIABLES.noticia, "content_type") AND isStruct(VARIABLES.noticia.content_type)>
        <cfif structKeyExists(VARIABLES.noticia.content_type, "slug") AND len(trim(VARIABLES.noticia.content_type.slug))>
            <cfset VARIABLES.relatedCurrentChannelKey = lCase(trim(VARIABLES.noticia.content_type.slug))>
        <cfelseif structKeyExists(VARIABLES.noticia.content_type, "name") AND len(trim(VARIABLES.noticia.content_type.name))>
            <cfset VARIABLES.relatedCurrentChannelKey = lCase(trim(VARIABLES.noticia.content_type.name))>
        </cfif>
    </cfif>

    <cftry>
        <cfset VARIABLES.apiNoticiasRelacionadas = fetchNoticiasApi("/rest/cmscf_api/v1/content?per_page=100&sort=published_at&dir=desc")>
        <cfif structKeyExists(VARIABLES.apiNoticiasRelacionadas, "items") AND isArray(VARIABLES.apiNoticiasRelacionadas.items)>
            <cfloop array="#VARIABLES.apiNoticiasRelacionadas.items#" index="item">
                <cfif isStruct(item) AND structKeyExists(item, "slug") AND len(trim(item.slug)) AND item.slug NEQ VARIABLES.noticia.slug>
                    <cfset VARIABLES.relatedCandidateCategoryKey = "">
                    <cfset VARIABLES.relatedCandidateChannelKey = "">

                    <cfif structKeyExists(item, "category") AND isStruct(item.category)>
                        <cfif structKeyExists(item.category, "slug") AND len(trim(item.category.slug))>
                            <cfset VARIABLES.relatedCandidateCategoryKey = lCase(trim(item.category.slug))>
                        <cfelseif structKeyExists(item.category, "name") AND len(trim(item.category.name))>
                            <cfset VARIABLES.relatedCandidateCategoryKey = lCase(trim(item.category.name))>
                        </cfif>
                    </cfif>

                    <cfif structKeyExists(item, "content_type") AND isStruct(item.content_type)>
                        <cfif structKeyExists(item.content_type, "slug") AND len(trim(item.content_type.slug))>
                            <cfset VARIABLES.relatedCandidateChannelKey = lCase(trim(item.content_type.slug))>
                        <cfelseif structKeyExists(item.content_type, "name") AND len(trim(item.content_type.name))>
                            <cfset VARIABLES.relatedCandidateChannelKey = lCase(trim(item.content_type.name))>
                        </cfif>
                    </cfif>

                    <cfif len(trim(VARIABLES.relatedCurrentCategoryKey)) AND VARIABLES.relatedCandidateCategoryKey EQ VARIABLES.relatedCurrentCategoryKey>
                        <cfset arrayAppend(VARIABLES.relatedCategoryPool, item)>
                    <cfelseif len(trim(VARIABLES.relatedCurrentChannelKey)) AND VARIABLES.relatedCandidateChannelKey EQ VARIABLES.relatedCurrentChannelKey>
                        <cfset arrayAppend(VARIABLES.relatedChannelPool, item)>
                    <cfelse>
                        <cfset arrayAppend(VARIABLES.relatedFallbackPool, item)>
                    </cfif>
                </cfif>
            </cfloop>
        </cfif>
    <cfcatch></cfcatch>
    </cftry>

    <cfloop array="#VARIABLES.relatedCategoryPool#" index="item">
        <cfif arrayLen(VARIABLES.noticiasRelacionadas) GTE 3>
            <cfbreak>
        </cfif>
        <cfif NOT structKeyExists(VARIABLES.relatedSeen, item.slug)>
            <cfset VARIABLES.relatedSeen[item.slug] = true>
            <cfset arrayAppend(VARIABLES.noticiasRelacionadas, item)>
        </cfif>
    </cfloop>

    <cfloop array="#VARIABLES.relatedChannelPool#" index="item">
        <cfif arrayLen(VARIABLES.noticiasRelacionadas) GTE 3>
            <cfbreak>
        </cfif>
        <cfif NOT structKeyExists(VARIABLES.relatedSeen, item.slug)>
            <cfset VARIABLES.relatedSeen[item.slug] = true>
            <cfset arrayAppend(VARIABLES.noticiasRelacionadas, item)>
        </cfif>
    </cfloop>

    <cfloop array="#VARIABLES.relatedFallbackPool#" index="item">
        <cfif arrayLen(VARIABLES.noticiasRelacionadas) GTE 3>
            <cfbreak>
        </cfif>
        <cfif NOT structKeyExists(VARIABLES.relatedSeen, item.slug)>
            <cfset VARIABLES.relatedSeen[item.slug] = true>
            <cfset arrayAppend(VARIABLES.noticiasRelacionadas, item)>
        </cfif>
    </cfloop>
</cfif>

<cfset REQUEST.homeSidebarNoticias = VARIABLES.noticiasSidebar>
<cfset REQUEST.homeSidebarNoticiasOverride = true>
<cfset REQUEST.hideHomeSidebarNoticias = false>

<cfset VARIABLES.noticiaSummaryText = ""/>
<cfset VARIABLES.noticiaSummaryMetaDescription = ""/>
<cfset VARIABLES.noticiaSummaryKeyPoints = []/>
<cfset VARIABLES.noticiaSummarySourcePreview = ""/>
<cfset VARIABLES.noticiaMetaPublicationMode = "licensed_full"/>
<cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada>
    <cfset VARIABLES.noticiaSummaryText = structKeyExists(VARIABLES.noticia, "excerpt") ? trim(VARIABLES.noticia.excerpt & "") : ""/>
    <cfif structKeyExists(VARIABLES.noticia, "content_type") AND isStruct(VARIABLES.noticia.content_type)
        AND structKeyExists(VARIABLES.noticia.content_type, "publication_mode")
        AND listFindNoCase("licensed_full,summary_link,external_only", trim(VARIABLES.noticia.content_type.publication_mode & ""))>
        <cfset VARIABLES.noticiaMetaPublicationMode = lCase(trim(VARIABLES.noticia.content_type.publication_mode & ""))/>
    </cfif>
    <cfif structKeyExists(VARIABLES.noticia, "summary") AND isStruct(VARIABLES.noticia.summary)>
        <cfif structKeyExists(VARIABLES.noticia.summary, "text") AND len(trim(VARIABLES.noticia.summary.text & ""))>
            <cfset VARIABLES.noticiaSummaryText = trim(VARIABLES.noticia.summary.text & "")/>
        </cfif>
        <cfif structKeyExists(VARIABLES.noticia.summary, "meta_description")>
            <cfset VARIABLES.noticiaSummaryMetaDescription = trim(VARIABLES.noticia.summary.meta_description & "")/>
        </cfif>
        <cfif structKeyExists(VARIABLES.noticia.summary, "key_points") AND isArray(VARIABLES.noticia.summary.key_points)>
            <cfloop array="#VARIABLES.noticia.summary.key_points#" index="VARIABLES.noticiaSummaryKeyPoint">
                <cfif isSimpleValue(VARIABLES.noticiaSummaryKeyPoint) AND len(trim(VARIABLES.noticiaSummaryKeyPoint & ""))>
                    <cfset arrayAppend(VARIABLES.noticiaSummaryKeyPoints, trim(VARIABLES.noticiaSummaryKeyPoint & ""))/>
                </cfif>
            </cfloop>
        </cfif>
        <cfif structKeyExists(VARIABLES.noticia.summary, "source_preview")>
            <cfset VARIABLES.noticiaSummarySourcePreview = trim(VARIABLES.noticia.summary.source_preview & "")/>
        </cfif>
    </cfif>
</cfif>

<cfif VARIABLES.isNoticiaDetalhe>
    <cfset REQUEST.currentRouteParams["tag"] = URL.tag />
    <cfset REQUEST.currentRouteKey = "newsDetail" />
<cfelseif len(trim(URL.canal))>
    <cfset REQUEST.currentRouteKey = "newsChannel" />
<cfelse>
    <cfset REQUEST.currentRouteKey = "news" />
</cfif>

<!--- META INFO --->
<cfif VARIABLES.isNoticiaDetalhe>
    <cfset VARIABLES.canonical = REQUEST.i18nBuildAbsoluteUrl("newsDetail")/>
<cfelseif len(trim(URL.canal))>
    <cfset VARIABLES.canonical = "#REQUEST.i18nBuildAbsoluteUrl('newsChannel')##URL.page GT 1 ? '?page=' & URL.page : ''#">
<cfelse>
    <cfset VARIABLES.canonical = "#REQUEST.i18nBuildAbsoluteUrl('news')##URL.page GT 1 ? '?page=' & URL.page : ''#">
</cfif>
<cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada
    AND structKeyExists(VARIABLES.noticia, "original_url") AND reFindNoCase("^https?://", trim(VARIABLES.noticia.original_url & ""))
    AND structKeyExists(VARIABLES.noticia, "content_type") AND isStruct(VARIABLES.noticia.content_type)
    AND structKeyExists(VARIABLES.noticia.content_type, "publication_mode")
    AND listFindNoCase("licensed_full,external_only", trim(VARIABLES.noticia.content_type.publication_mode & ""))>
    <cfset VARIABLES.canonical = trim(VARIABLES.noticia.original_url & "")>
    <cfif lCase(trim(VARIABLES.noticia.content_type.publication_mode & "")) EQ "external_only">
        <cfset VARIABLES.metaRobots = "noindex,follow">
    </cfif>
</cfif>
<cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada>
    <cfset VARIABLES.noticiaMetaImage = "">
    <cfset VARIABLES.noticiaMetaPublishedAt = "">
    <cfif structKeyExists(VARIABLES.noticia, "featured_media") AND isStruct(VARIABLES.noticia.featured_media) AND structKeyExists(VARIABLES.noticia.featured_media, "url") AND len(trim(VARIABLES.noticia.featured_media.url))>
        <cfset VARIABLES.noticiaMetaImage = trim(VARIABLES.noticia.featured_media.url)>
        <cfif left(VARIABLES.noticiaMetaImage, 1) EQ "/">
            <cfset VARIABLES.noticiaMetaImage = VARIABLES.apiConteudoBase & VARIABLES.noticiaMetaImage>
        </cfif>
    </cfif>
    <cfif structKeyExists(VARIABLES.noticia, "published_at") AND len(trim(VARIABLES.noticia.published_at))>
        <cfset VARIABLES.noticiaMetaPublishedAt = replace(trim(VARIABLES.noticia.published_at), " ", "T", "one")>
    </cfif>
    <cfset VARIABLES.title = "#VARIABLES.noticia.title# - #APPLICATION.nomeSite#"/>
    <cfset VARIABLES.description = newsMetaDescription(VARIABLES.noticiaSummaryMetaDescription, len(VARIABLES.noticiaSummaryText) ? VARIABLES.noticiaSummaryText : "Notícia publicada no ecossistema Road Runners.")/>
    <cfset VARIABLES.metaType = "article"/>
    <cfset VARIABLES.twitterCard = len(trim(VARIABLES.noticiaMetaImage)) ? "summary_large_image" : "summary"/>
    <cfset VARIABLES.metaImageAlt = VARIABLES.noticia.title/>
    <cfif len(trim(VARIABLES.noticiaMetaPublishedAt))>
        <cfset VARIABLES.metaPublishedTime = VARIABLES.noticiaMetaPublishedAt/>
    </cfif>
    <cfif structKeyExists(VARIABLES.noticia, "updated_at") AND len(trim(VARIABLES.noticia.updated_at & ""))>
        <cfset VARIABLES.metaModifiedTime = replace(trim(VARIABLES.noticia.updated_at & ""), " ", "T", "one")/>
    </cfif>
    <cfif len(trim(VARIABLES.noticiaMetaImage))>
        <cfset VARIABLES.metaImage = VARIABLES.noticiaMetaImage/>
    </cfif>
    <cfset VARIABLES.newsStructuredData = {
        "@context" = "https://schema.org",
        "@type" = "NewsArticle",
        "headline" = VARIABLES.noticia.title,
        "description" = VARIABLES.description,
        "inLanguage" = REQUEST.htmlLang,
        "url" = VARIABLES.canonical,
        "mainEntityOfPage" = {
            "@type" = "WebPage",
            "@id" = VARIABLES.canonical
        },
        "publisher" = {
            "@type" = "Organization",
            "name" = APPLICATION.nomeSite,
            "url" = "https://roadrunners.run/",
            "logo" = {
                "@type" = "ImageObject",
                "url" = "https://roadrunners.run/assets/rr_icon.jpg"
            }
        }
    }/>
    <cfif len(trim(VARIABLES.noticiaMetaPublishedAt))>
        <cfset VARIABLES.newsStructuredData["datePublished"] = VARIABLES.noticiaMetaPublishedAt/>
    </cfif>
    <cfif structKeyExists(VARIABLES.noticia, "updated_at") AND len(trim(VARIABLES.noticia.updated_at & ""))>
        <cfset VARIABLES.newsStructuredData["dateModified"] = replace(trim(VARIABLES.noticia.updated_at & ""), " ", "T", "one")/>
    </cfif>
    <cfif len(trim(VARIABLES.noticiaMetaImage))>
        <cfset VARIABLES.newsStructuredData["image"] = [VARIABLES.noticiaMetaImage]/>
    </cfif>
    <cfif VARIABLES.noticiaMetaPublicationMode EQ "summary_link" AND len(newsPlainText(VARIABLES.noticiaSummaryText))>
        <cfset VARIABLES.newsStructuredData["articleBody"] = newsPlainText(VARIABLES.noticiaSummaryText)/>
        <cfset VARIABLES.newsStructuredData["wordCount"] = listLen(newsPlainText(VARIABLES.noticiaSummaryText), " ")/>
    </cfif>
    <cfif structKeyExists(VARIABLES.noticia, "author") AND isStruct(VARIABLES.noticia.author)
        AND structKeyExists(VARIABLES.noticia.author, "name") AND len(trim(VARIABLES.noticia.author.name & ""))
        AND NOT listFindNoCase("redação,autor", trim(VARIABLES.noticia.author.name & ""))>
        <cfset VARIABLES.newsStructuredData["author"] = {
            "@type" = "Person",
            "name" = trim(VARIABLES.noticia.author.name & "")
        }/>
    <cfelseif structKeyExists(VARIABLES.noticia, "content_type") AND isStruct(VARIABLES.noticia.content_type)
        AND structKeyExists(VARIABLES.noticia.content_type, "name") AND len(trim(VARIABLES.noticia.content_type.name & ""))>
        <cfset VARIABLES.newsStructuredData["author"] = {
            "@type" = "Organization",
            "name" = trim(VARIABLES.noticia.content_type.name & "")
        }/>
    </cfif>
    <cfif structKeyExists(VARIABLES.noticia, "category") AND isStruct(VARIABLES.noticia.category)
        AND structKeyExists(VARIABLES.noticia.category, "name") AND len(trim(VARIABLES.noticia.category.name & ""))>
        <cfset VARIABLES.newsStructuredData["articleSection"] = trim(VARIABLES.noticia.category.name & "")/>
    </cfif>
    <cfif VARIABLES.noticiaMetaPublicationMode EQ "summary_link"
        AND structKeyExists(VARIABLES.noticia, "original_url") AND reFindNoCase("^https?://", trim(VARIABLES.noticia.original_url & ""))>
        <cfset VARIABLES.newsStructuredData["citation"] = trim(VARIABLES.noticia.original_url & "")/>
        <cfset VARIABLES.newsStructuredData["isBasedOn"] = trim(VARIABLES.noticia.original_url & "")/>
    </cfif>
    <cfset VARIABLES.structuredDataJsonLd = replace(serializeJSON(VARIABLES.newsStructuredData), "</", "<\/", "all")/>
<cfelse>
    <cfset VARIABLES.title = "#REQUEST.t('news.meta.title')# - #APPLICATION.nomeSite#"/>
    <cfset VARIABLES.description = REQUEST.t('news.meta.description')/>
</cfif>
<cfset VARIABLES.keywords = REQUEST.t('news.meta.keywords')/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<body>

    <!--- SEO WEB TOOLS --->
    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .news-shell-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            color: #333333;
        }

        .news-shell-card.is-channel-list {
            border: 0;
            border-radius: 0;
            background-color: transparent;
            padding: 0 !important;
        }

        .news-page-hero.has-back-action {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.85rem;
        }

        .news-page-hero-back {
            flex: 0 0 auto;
            text-decoration: none;
        }

        .news-detail-meta-row {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 0.6rem;
        }

        .news-detail-meta-chips {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 0.5rem;
        }

        .news-detail-share-button {
            gap: 0.35rem;
            cursor: pointer;
        }

        .news-muted {
            color: rgba(51, 51, 51, 0.72);
        }

        .news-channel-filters {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            margin-bottom: 0.85rem;
        }

        .news-filter-chip {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0.42rem 0.72rem;
            border-radius: 999px;
            border: 1px solid rgba(51, 51, 51, 0.1);
            background-color: #ffffff;
            color: #333333;
            font-size: 0.78rem;
            font-weight: 600;
            line-height: 1;
            text-decoration: none;
        }

        .news-filter-chip.is-active,
        .news-filter-chip:hover {
            border-color: #fab120;
            background-color: #fff8e6;
            color: #333333;
        }

        .news-channel-select-mobile {
            display: none;
        }

        .news-channel-select {
            width: 100%;
            min-height: 42px;
            padding: 0.65rem 2.6rem 0.65rem 0.9rem;
            border-radius: 999px;
            border: 1px solid rgba(51, 51, 51, 0.1);
            background-color: #ffffff;
            color: #333333;
            font-size: 0.82rem;
            font-weight: 600;
            line-height: 1.2;
            box-shadow: 0 8px 24px rgba(51, 51, 51, 0.06);
            appearance: none;
            -webkit-appearance: none;
            background-image:
                linear-gradient(45deg, transparent 50%, #333333 50%),
                linear-gradient(135deg, #333333 50%, transparent 50%);
            background-position:
                calc(100% - 1rem) calc(50% - 1px),
                calc(100% - 0.72rem) calc(50% - 1px);
            background-size: 6px 6px, 6px 6px;
            background-repeat: no-repeat;
        }

        .news-channel-select:focus {
            outline: none;
            border-color: rgba(250, 177, 32, 0.55);
            box-shadow: 0 10px 28px rgba(51, 51, 51, 0.08);
        }

        .news-channel-header {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 0.9rem 1rem;
            margin-bottom: 1rem;
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
        }

        .news-channel-header-logo {
            width: 128px;
            flex: 0 0 128px;
            display: flex;
            align-items: center;
            justify-content: flex-start;
        }

        .news-channel-header-logo img {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
            display: block;
        }

        .news-channel-header-fallback {
            color: #333333;
            font-size: 2rem;
            font-weight: 700;
            letter-spacing: 0.04em;
        }

        .news-channel-header-body {
            min-width: 0;
            flex: 1 1 auto;
            display: flex;
            flex-direction: column;
            gap: 0.12rem;
        }

        .news-channel-header-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.75rem;
            margin-bottom: 0;
        }

        .news-channel-header-title {
            color: #333333;
            font-size: 1.08rem;
            font-weight: 700;
            line-height: 1.08;
        }

        .news-channel-header-description {
            color: rgba(51, 51, 51, 0.74);
            font-size: 0.88rem;
            line-height: 1.28;
        }

        .news-channel-header-links {
            display: inline-flex;
            align-items: center;
            gap: 0.4rem;
            flex: 0 0 auto;
        }

        .news-channel-header-link {
            width: 32px;
            height: 32px;
            border-radius: 999px;
            border: 1px solid rgba(51, 51, 51, 0.12);
            background-color: #ffffff;
            color: #333333;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            text-decoration: none;
        }

        .news-channel-header-link:hover {
            border-color: #fab120;
            background-color: #fff8e6;
            color: #333333;
        }

        .news-channel-header.is-sidebar {
            align-items: stretch;
            flex-direction: column;
            gap: 0.7rem;
            margin-bottom: 0.5rem;
            padding: 0.9rem;
        }

        .news-channel-header.is-sidebar .news-channel-header-logo {
            flex-basis: auto;
            justify-content: center;
            min-height: 54px;
            width: 100%;
        }

        .news-channel-header.is-sidebar .news-channel-header-logo img {
            max-height: 72px;
        }

        .news-channel-header.is-sidebar .news-channel-header-top {
            align-items: flex-start;
            flex-direction: column;
            gap: 0.55rem;
        }

        .news-channel-header.is-sidebar .news-channel-header-description {
            font-size: 0.8rem;
        }

        .news-channel-header-channel-link {
            color: inherit;
            text-decoration: none;
        }

        .news-channel-header-channel-link:hover,
        .news-channel-header-channel-link:focus {
            color: inherit;
            text-decoration: none;
        }

        .news-channel-read-more {
            align-items: center;
            background-color: #efefef;
            border: 1px solid rgba(51, 51, 51, 0.12);
            border-radius: 8px;
            box-sizing: border-box;
            color: #333333;
            display: flex;
            font-size: 0.84rem;
            font-weight: 700;
            justify-content: center;
            margin-top: 1.25rem;
            padding: 0.72rem 1rem;
            text-align: center;
            text-decoration: none;
            transition: background-color 160ms ease, border-color 160ms ease, box-shadow 160ms ease, transform 160ms ease;
            width: 100%;
        }

        .news-channel-read-more:hover,
        .news-channel-read-more:focus {
            background-color: #e7e7e7;
            border-color: rgba(51, 51, 51, 0.2);
            color: #333333;
            text-decoration: none;
        }

        .news-channel-read-more.is-source-summary {
            background: linear-gradient(135deg, #ffffff 0%, #fffaf0 100%);
            border-color: rgba(51, 51, 51, 0.16);
            box-shadow: 0 7px 20px rgba(51, 51, 51, 0.09);
            color: #333333;
            gap: 0.8rem;
            justify-content: flex-start;
            padding: 0.9rem 1rem;
            text-align: left;
        }

        .news-channel-read-more.is-source-summary:hover,
        .news-channel-read-more.is-source-summary:focus-visible {
            background: #fff6e3;
            border-color: rgba(250, 177, 32, 0.72);
            box-shadow: 0 9px 24px rgba(51, 51, 51, 0.13);
            color: #333333;
            transform: translateY(-1px);
        }

        .news-channel-read-more-icon,
        .news-channel-read-more-action {
            align-items: center;
            display: inline-flex;
            flex: 0 0 auto;
            justify-content: center;
        }

        .news-channel-read-more-icon {
            background: #fab120;
            border-radius: 50%;
            color: #333333;
            font-size: 0.95rem;
            height: 2.45rem;
            width: 2.45rem;
        }

        .news-channel-read-more-copy {
            display: flex;
            flex: 1 1 auto;
            flex-direction: column;
            line-height: 1.25;
            min-width: 0;
        }

        .news-channel-read-more-kicker {
            color: rgba(51, 51, 51, 0.58);
            font-size: 0.68rem;
            font-weight: 600;
            letter-spacing: 0.055em;
            margin-bottom: 0.16rem;
            text-transform: uppercase;
        }

        .news-channel-read-more-label {
            font-size: 0.94rem;
            font-weight: 750;
            overflow-wrap: anywhere;
        }

        .news-channel-read-more-action {
            color: #a66f00;
            font-size: 0.9rem;
            margin-left: auto;
        }

        .news-publication-notice {
            align-items: center;
            color: rgba(51, 51, 51, 0.68);
            display: flex;
            font-size: 0.78rem;
            gap: 0.45rem;
            line-height: 1.35;
            margin: 0 0 1rem;
        }

        .news-publication-notice i {
            color: #b77a00;
        }

        .news-channel-author-card {
            margin-top: 1.25rem;
            padding-top: 1rem;
            border-top: 1px solid rgba(51, 51, 51, 0.1);
            display: grid;
            grid-template-columns: 112px minmax(0, 1fr);
            gap: 1rem;
            align-items: flex-start;
        }

        .news-channel-author-logo {
            width: 112px;
            display: flex;
            align-items: flex-start;
            justify-content: flex-start;
            text-decoration: none;
        }

        .news-channel-author-logo img {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
            display: block;
        }

        .news-channel-author-fallback {
            color: #333333;
            font-size: 1.28rem;
            font-weight: 800;
            letter-spacing: 0.04em;
        }

        .news-channel-author-title {
            color: #333333;
            font-size: 0.82rem;
            font-weight: 800;
            line-height: 1.3;
            text-decoration: none;
        }

        .news-channel-author-title:hover {
            color: #333333;
            text-decoration: underline;
            text-decoration-color: #fab120;
            text-decoration-thickness: 2px;
        }

        .news-channel-author-channel {
            color: rgba(51, 51, 51, 0.68);
            display: flex;
            flex-wrap: wrap;
            gap: 0.32rem;
            font-size: 0.82rem;
            line-height: 1.3;
            margin-top: 0.25rem;
        }

        .news-channel-author-channel-link {
            color: #333333;
            font-weight: 800;
            text-decoration: none;
        }

        .news-channel-author-channel-link:hover {
            color: #333333;
            text-decoration: underline;
            text-decoration-color: #fab120;
            text-decoration-thickness: 2px;
        }

        .news-channel-author-description {
            color: rgba(51, 51, 51, 0.76);
            font-size: 0.84rem;
            line-height: 1.42;
            margin-top: 0.42rem;
        }

        .news-channel-author-actions {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 0.45rem;
            margin-top: 0.8rem;
        }

        .news-item {
            display: block;
            height: 100%;
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            color: #333333;
            text-decoration: none;
            overflow: hidden;
        }

        .news-list-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 0.85rem;
        }

        .news-item.is-featured {
            grid-column: 1 / -1;
            background-color: #efefef;
        }

        .news-item-body {
            padding: 0.9rem;
        }

        .news-item.is-featured .news-item-body {
            padding: 1rem;
        }

        .news-item-title {
            color: #333333;
            font-size: 1.04rem;
            font-weight: 700;
            line-height: 1.22;
            margin-bottom: 0.45rem;
        }

        .news-item.is-featured .news-item-title {
            font-size: 1.4rem;
            line-height: 1.15;
        }

        .news-thumb {
            width: 100%;
            border-radius: 10px;
            background-color: #efefef;
            display: block;
        }

        .news-list-grid .news-thumb {
            border-radius: 0;
            aspect-ratio: 16 / 9;
            object-fit: cover;
        }

        .news-list-placeholder {
            aspect-ratio: 16 / 9;
            width: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            background:
                radial-gradient(circle at top right, rgba(250, 177, 32, 0.42), transparent 28%),
                linear-gradient(135deg, #f1f1f1 0%, #e5e5e5 100%);
            color: rgba(51, 51, 51, 0.7);
            font-size: 2.1rem;
        }

        .news-list-placeholder-logo {
            max-width: 64%;
            max-height: 58%;
            object-fit: contain;
        }

        .news-list-placeholder-fallback-icon {
            display: none;
        }

        .home-video-thumb {
            aspect-ratio: 16 / 9;
            object-fit: cover;
        }

        .news-meta-chip {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0.42rem 0.72rem;
            border-radius: 8px;
            border: 1px solid rgba(51, 51, 51, 0.1);
            background-color: #ffffff;
            color: #333333;
            font-size: 0.78rem;
            font-weight: 600;
            line-height: 1;
        }

        .news-meta-chip.is-channel {
            border-color: rgba(51, 51, 51, 0.95);
            background-color: #333333;
            color: #ffffff;
        }

        .news-pagination-link {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 42px;
            padding: 0.58rem 0.85rem;
            border-radius: 8px;
            border: 1px solid rgba(51, 51, 51, 0.1);
            background-color: #ffffff;
            color: #333333;
            text-decoration: none;
            font-weight: 600;
        }

        .news-pagination-link.is-active,
        .news-pagination-link:hover {
            border-color: #fab120;
            background-color: #fff8e6;
            color: #333333;
        }

        .news-content {
            color: #333333;
            line-height: 1.75;
        }

        .news-summary {
            color: #333333;
            margin-bottom: 1.25rem;
        }

        .news-summary-key-points-title {
            color: #333333;
            font-size: 0.72rem;
            font-weight: 800;
            letter-spacing: 0.055em;
            margin: 0 0 0.6rem;
            text-transform: uppercase;
        }

        .news-summary-body {
            color: rgba(51, 51, 51, 0.84);
            font-size: 1.04rem;
            line-height: 1.68;
        }

        .news-summary-body p {
            margin: 0 0 0.85rem;
        }

        .news-summary-body p:last-child {
            margin-bottom: 0;
        }

        .news-summary-key-points {
            background: #f7f7f7;
            border-left: 3px solid #fab120;
            border-radius: 0 8px 8px 0;
            margin-top: 1rem;
            padding: 0.85rem 1rem;
        }

        .news-summary-key-points ul {
            display: grid;
            gap: 0.42rem;
            margin: 0;
            padding-left: 1.05rem;
        }

        .news-summary-key-points li {
            color: rgba(51, 51, 51, 0.8);
            font-size: 0.88rem;
            line-height: 1.45;
            padding-left: 0.12rem;
        }

        .news-summary-source-preview {
            color: rgba(51, 51, 51, 0.66);
            font-size: 0.82rem;
            line-height: 1.45;
            margin: 0.9rem 0 0;
        }

        .news-summary-source-preview strong {
            color: rgba(51, 51, 51, 0.78);
        }

        .news-content img,
        .news-content iframe,
        .news-content video {
            max-width: 100%;
            height: auto;
            border-radius: 10px;
        }

        .news-content a {
            color: #333333;
            text-decoration: underline;
            text-decoration-color: #fab120;
        }

        .news-content h2,
        .news-content h3,
        .news-content h4 {
            margin-top: 1.5rem;
            margin-bottom: 0.75rem;
            color: #333333;
        }

        .news-content figure {
            margin: 1.5rem 0;
        }

        .news-content figcaption {
            margin-top: 0.45rem;
            text-align: center;
            color: rgba(51, 51, 51, 0.62);
            font-size: 0.8rem;
            line-height: 1.4;
        }

        .news-gallery {
            margin-top: 2rem;
            padding-top: 1.5rem;
            border-top: 1px solid rgba(51, 51, 51, 0.08);
        }

        .news-related {
            margin-top: 2rem;
            padding-top: 1.5rem;
            border-top: 1px solid rgba(51, 51, 51, 0.08);
        }

        .news-related-title {
            color: #333333;
            font-size: 1rem;
            font-weight: 700;
            margin-bottom: 0.2rem;
        }

        .news-related-text {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.88rem;
            line-height: 1.45;
            margin-bottom: 0.9rem;
        }

        .news-related-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 0.85rem;
        }

        .news-related-card {
            display: block;
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            color: #333333;
            text-decoration: none;
            overflow: hidden;
        }

        .news-related-image {
            width: 100%;
            aspect-ratio: 16 / 9;
            object-fit: cover;
            display: block;
            background-color: #efefef;
        }

        .news-related-body {
            padding: 0.85rem;
        }

        .news-related-name {
            color: #333333;
            font-size: 0.92rem;
            font-weight: 700;
            line-height: 1.28;
            margin-top: 0.55rem;
        }

        .news-gallery-title {
            color: #333333;
            font-size: 1rem;
            font-weight: 700;
            margin-bottom: 0.9rem;
        }

        .news-gallery-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 0.85rem;
        }

        .news-gallery-item {
            display: block;
            width: 100%;
            padding: 0;
            border: 0;
            background: transparent;
            text-align: left;
            color: #333333;
        }

        .news-gallery-image-wrap {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            overflow: hidden;
            background-color: #efefef;
        }

        .news-gallery-image {
            width: 100%;
            aspect-ratio: 4 / 3;
            object-fit: cover;
            display: block;
        }

        .news-gallery-caption {
            margin-top: 0.45rem;
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.84rem;
            line-height: 1.4;
        }

        .news-gallery-modal-dialog {
            max-width: min(1080px, calc(100vw - 1.5rem));
        }

        .news-gallery-modal-content {
            border: 0;
            border-radius: 12px;
            overflow: hidden;
            background-color: #111111;
        }

        .news-gallery-modal-body {
            padding: 0;
            position: relative;
            background-color: #111111;
        }

        .news-gallery-stage {
            position: relative;
            background-color: #111111;
        }

        .news-gallery-stage img {
            display: block;
            width: 100%;
            max-height: 82vh;
            object-fit: contain;
            background-color: #111111;
        }

        .news-gallery-modal-close {
            position: absolute;
            top: 0.85rem;
            right: 0.85rem;
            z-index: 3;
            background-color: rgba(255, 255, 255, 0.9);
        }

        .news-gallery-nav {
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
            z-index: 3;
            width: 42px;
            height: 42px;
            border: 0;
            border-radius: 999px;
            background-color: rgba(255, 255, 255, 0.92);
            color: #333333;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }

        .news-gallery-nav.prev {
            left: 0.85rem;
        }

        .news-gallery-nav.next {
            right: 0.85rem;
        }

        .news-gallery-nav[disabled] {
            opacity: 0.35;
            pointer-events: none;
        }

        .news-gallery-modal-meta {
            padding: 0.9rem 1rem 1rem;
            background-color: #ffffff;
            color: #333333;
        }

        .news-gallery-modal-caption {
            font-size: 0.92rem;
            font-weight: 600;
            line-height: 1.45;
        }

        .news-gallery-modal-counter {
            margin-top: 0.35rem;
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.8rem;
        }

        .home-side-block {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
        }

        .home-side-title {
            color: #333333;
            font-size: 0.76rem;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
        }

        .home-side-muted {
            color: rgba(51, 51, 51, 0.72);
        }

        .home-content-image {
            border-radius: 8px;
            width: 100%;
            height: auto;
            display: block;
            background-color: #efefef;
        }

        .home-video-item + .home-video-item {
            border-top: 1px solid rgba(51, 51, 51, 0.08);
            padding-top: 0.85rem;
            margin-top: 0.85rem;
        }

        @media (max-width: 767.98px) {
            .news-list-grid {
                grid-template-columns: 1fr;
            }

            .news-related-grid {
                grid-template-columns: 1fr;
            }

            .news-channel-filters {
                display: none;
            }

            .news-channel-select-mobile {
                display: block;
                margin-bottom: 0.85rem;
            }

            .news-hero {
                padding: 0.9rem !important;
                margin-bottom: 0.75rem !important;
            }

            .news-gallery-grid {
                grid-template-columns: 1fr;
            }

            .news-item.is-featured .news-item-title {
                font-size: 1.16rem;
            }

            .news-channel-header {
                align-items: center;
                gap: 0.85rem;
                padding: 0.9rem;
            }

            .news-channel-header-logo {
                width: 96px;
                flex-basis: 96px;
            }

            .news-channel-header-top {
                align-items: flex-start;
                flex-direction: column;
            }

            .news-channel-author-card {
                grid-template-columns: 92px minmax(0, 1fr);
                gap: 0.75rem;
            }

            .news-channel-author-logo {
                width: 92px;
            }
        }
    </style>

    <div class="container">

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <cfif VARIABLES.isNoticiaDetalhe>
            <div class="page-section-hero news-page-hero has-back-action">
                <div>
        <cfelse>
            <div class="page-section-hero news-page-hero page-section-hero-editorial">
                <div class="page-section-hero-editorial-content">
        </cfif>
                <cfif VARIABLES.isNoticiaDetalhe>
                    <div class="page-section-hero-title">
                <cfelse>
                    <h1 class="page-section-hero-title">
                </cfif>
                    <svg class="page-section-hero-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 768 767.999994" preserveAspectRatio="xMidYMid meet" version="1.0" aria-hidden="true"><path fill="#f4b120" d="M 217.46875 764.9375 C 209.929688 764.9375 204.402344 762.171875 200.878906 756.648438 C 197.367188 751.136719 196.113281 744.105469 197.121094 735.5625 L 298.066406 17.609375 C 299.0625 10.574219 300.566406 6.308594 302.578125 4.808594 C 304.59375 3.296875 309.109844 2.542969 316.132812 2.542969 L 386.199219 2.542969 C 391.722656 2.542969 396.238281 4.550781 399.75 8.566406 C 403.261719 12.582031 404.519531 16.847656 403.527344 21.367188 L 300.316406 755.914062 C 299.8125 759.925781 298.804688 762.429688 297.292969 763.429688 C 295.792969 764.433594 292.535156 764.9375 287.515625 764.9375 Z M 217.46875 764.9375 " fill-opacity="1" fill-rule="nonzero"/><path fill="#f4b120" d="M 401.449219 764.9375 C 393.910156 764.9375 388.382812 762.171875 384.859375 756.648438 C 381.351562 751.136719 380.097656 744.105469 381.101562 735.5625 L 482.050781 17.609375 C 483.042969 10.574219 484.546875 6.308594 486.5625 4.808594 C 488.574219 3.296875 493.089844 2.542969 500.113281 2.542969 L 570.179688 2.542969 C 575.703125 2.542969 580.21875 4.550781 583.734375 8.566406 C 587.242188 12.582031 588.5 16.847656 587.507812 21.367188 L 484.296875 755.914062 C 483.792969 759.925781 482.785156 762.429688 481.277344 763.429688 C 479.777344 764.433594 476.519531 764.9375 471.5 764.9375 Z M 401.449219 764.9375 " fill-opacity="1" fill-rule="nonzero"/></svg>
                    <span class="page-section-hero-text"><cfoutput>#REQUEST.t('news.hero.title')#</cfoutput></span>
                <cfif VARIABLES.isNoticiaDetalhe>
                    </div>
                <cfelse>
                    </h1>
                </cfif>
                <cfif NOT VARIABLES.isNoticiaDetalhe>
                    <div class="page-section-hero-editorial-info">
                        <div class="page-section-hero-kicker"><cfoutput>#VARIABLES.newsAggregatorLabel#</cfoutput></div>
                        <p class="page-section-hero-copy"><cfoutput>#VARIABLES.newsAggregatorCopy#</cfoutput></p>
                    </div>
                </cfif>
            </div>
            <cfif VARIABLES.isNoticiaDetalhe>
                <cfoutput><a href="#VARIABLES.newsRootUrl#" class="news-meta-chip news-page-hero-back">#REQUEST.t('news.detail.backToNews')#</a></cfoutput>
            </cfif>
        </div>

        <cfif NOT VARIABLES.isNoticiaDetalhe AND arrayLen(VARIABLES.canaisNoticias)>
            <div class="news-channel-select-mobile">
                <select class="news-channel-select" aria-label="<cfoutput>#REQUEST.t('news.filters.aria')#</cfoutput>" onchange="if(this.value){ window.location.href = this.value; }">
                    <option value="<cfoutput>#VARIABLES.newsRootUrl#</cfoutput>"<cfif NOT len(trim(URL.canal))> selected</cfif>><cfoutput>#REQUEST.t('news.filters.allChannels')#</cfoutput></option>
                    <cfloop array="#VARIABLES.canaisNoticias#" index="canalItem">
                        <cfoutput><option value="#VARIABLES.newsRootUrl##VARIABLES.newsChannelSegment#/#canalItem.slug#/"<cfif URL.canal EQ canalItem.slug> selected</cfif>>#canalItem.name#</option></cfoutput>
                    </cfloop>
                </select>
            </div>
            <div class="news-channel-filters">
                <cfoutput><a href="#VARIABLES.newsRootUrl#" class="news-filter-chip<cfif NOT len(trim(URL.canal))> is-active</cfif>">#REQUEST.t('news.filters.allChannels')#</a></cfoutput>
                <cfloop array="#VARIABLES.canaisNoticias#" index="canalItem">
                    <cfoutput><a href="#VARIABLES.newsRootUrl##VARIABLES.newsChannelSegment#/#canalItem.slug#/" class="news-filter-chip<cfif URL.canal EQ canalItem.slug> is-active</cfif>">#canalItem.name#</a></cfoutput>
                </cfloop>
            </div>
        </cfif>

        <div class="row gx-3 gy-2">

            <div class="col-12 col-lg-9">
                <div class="news-shell-card<cfif NOT VARIABLES.isNoticiaDetalhe> is-channel-list</cfif> p-3">
                    <cfif VARIABLES.isNoticiaDetalhe>
                        <cfif VARIABLES.noticiaEncontrada>
                            <cfset VARIABLES.imagemNoticia = "">
                            <cfset VARIABLES.dataNoticia = "">
                            <cfset VARIABLES.autorNoticia = "">
                            <cfset VARIABLES.canalNoticia = "">
                            <cfset VARIABLES.canalNoticiaSlug = "">
                            <cfset VARIABLES.canalNoticiaConfig = {}>
                            <cfset VARIABLES.canalNoticiaLogo = "">
                            <cfset VARIABLES.canalNoticiaDescricao = "">
                            <cfset VARIABLES.canalNoticiaWebsite = "">
                            <cfset VARIABLES.canalNoticiaInstagram = "">
                            <cfset VARIABLES.canalNoticiaYoutube = "">
                            <cfset VARIABLES.canalNoticiaFacebook = "">
                            <cfset VARIABLES.noticiaPublicationMode = "licensed_full">
                            <cfset VARIABLES.noticiaOriginalUrl = "">
                            <cfset VARIABLES.galeriaNoticia = []>
                            <cfif structKeyExists(VARIABLES.noticia, "featured_media") AND isStruct(VARIABLES.noticia.featured_media) AND structKeyExists(VARIABLES.noticia.featured_media, "url")>
                                <cfset VARIABLES.imagemNoticia = VARIABLES.noticia.featured_media.url>
                                <cfif left(VARIABLES.imagemNoticia, 1) EQ "/">
                                    <cfset VARIABLES.imagemNoticia = VARIABLES.apiConteudoBase & VARIABLES.imagemNoticia>
                                </cfif>
                            </cfif>
                            <cfif structKeyExists(VARIABLES.noticia, "published_at") AND len(trim(VARIABLES.noticia.published_at))>
                                <cftry>
                                    <cfset VARIABLES.dataNoticia = lsDateFormat(parseDateTime(left(VARIABLES.noticia.published_at, 10)), "dd/mm/yyyy")>
                                <cfcatch>
                                    <cfset VARIABLES.dataNoticia = "">
                                </cfcatch>
                                </cftry>
                            </cfif>
                            <cfif structKeyExists(VARIABLES.noticia, "author")>
                                <cfif isStruct(VARIABLES.noticia.author) AND structKeyExists(VARIABLES.noticia.author, "name") AND len(trim(VARIABLES.noticia.author.name))>
                                    <cfset VARIABLES.autorNoticia = VARIABLES.noticia.author.name>
                                <cfelseif isSimpleValue(VARIABLES.noticia.author) AND len(trim(VARIABLES.noticia.author))>
                                    <cfset VARIABLES.autorNoticia = VARIABLES.noticia.author>
                                </cfif>
                            </cfif>
                            <cfif NOT len(trim(VARIABLES.autorNoticia)) AND structKeyExists(VARIABLES.noticia, "authors") AND isArray(VARIABLES.noticia.authors) AND arrayLen(VARIABLES.noticia.authors)>
                                <cfif isStruct(VARIABLES.noticia.authors[1]) AND structKeyExists(VARIABLES.noticia.authors[1], "name") AND len(trim(VARIABLES.noticia.authors[1].name))>
                                    <cfset VARIABLES.autorNoticia = VARIABLES.noticia.authors[1].name>
                                <cfelseif isSimpleValue(VARIABLES.noticia.authors[1]) AND len(trim(VARIABLES.noticia.authors[1]))>
                                    <cfset VARIABLES.autorNoticia = VARIABLES.noticia.authors[1]>
                                </cfif>
                            </cfif>
                            <cfif NOT len(trim(VARIABLES.autorNoticia)) AND structKeyExists(VARIABLES.noticia, "user") AND isStruct(VARIABLES.noticia.user) AND structKeyExists(VARIABLES.noticia.user, "name") AND len(trim(VARIABLES.noticia.user.name))>
                                <cfset VARIABLES.autorNoticia = VARIABLES.noticia.user.name>
                            </cfif>
                            <cfif structKeyExists(VARIABLES.noticia, "content_type") AND isStruct(VARIABLES.noticia.content_type) AND structKeyExists(VARIABLES.noticia.content_type, "name") AND len(trim(VARIABLES.noticia.content_type.name))>
                                <cfset VARIABLES.canalNoticiaConfig = duplicate(VARIABLES.noticia.content_type)>
                                <cfset VARIABLES.canalNoticia = VARIABLES.noticia.content_type.name>
                                <cfif structKeyExists(VARIABLES.noticia.content_type, "slug") AND len(trim(VARIABLES.noticia.content_type.slug))>
                                    <cfset VARIABLES.canalNoticiaSlug = lCase(trim(VARIABLES.noticia.content_type.slug))>
                                </cfif>
                            <cfelseif structKeyExists(VARIABLES.noticia, "channel") AND isStruct(VARIABLES.noticia.channel) AND structKeyExists(VARIABLES.noticia.channel, "name") AND len(trim(VARIABLES.noticia.channel.name))>
                                <cfset VARIABLES.canalNoticiaConfig = duplicate(VARIABLES.noticia.channel)>
                                <cfset VARIABLES.canalNoticia = VARIABLES.noticia.channel.name>
                                <cfif structKeyExists(VARIABLES.noticia.channel, "slug") AND len(trim(VARIABLES.noticia.channel.slug))>
                                    <cfset VARIABLES.canalNoticiaSlug = lCase(trim(VARIABLES.noticia.channel.slug))>
                                </cfif>
                            <cfelseif structKeyExists(VARIABLES.noticia, "channel") AND isSimpleValue(VARIABLES.noticia.channel) AND len(trim(VARIABLES.noticia.channel))>
                                <cfset VARIABLES.canalNoticia = VARIABLES.noticia.channel>
                            </cfif>
                            <cfif isStruct(VARIABLES.canalNoticiaConfig) AND structCount(VARIABLES.canalNoticiaConfig)>
                                <cfif structKeyExists(VARIABLES.canalNoticiaConfig, "logo_url") AND len(trim(VARIABLES.canalNoticiaConfig.logo_url))>
                                    <cfset VARIABLES.canalNoticiaLogo = trim(VARIABLES.canalNoticiaConfig.logo_url)>
                                    <cfif left(VARIABLES.canalNoticiaLogo, 1) EQ "/">
                                        <cfset VARIABLES.canalNoticiaLogo = VARIABLES.apiConteudoBase & VARIABLES.canalNoticiaLogo>
                                    </cfif>
                                </cfif>
                                <cfif structKeyExists(VARIABLES.canalNoticiaConfig, "description") AND len(trim(VARIABLES.canalNoticiaConfig.description))>
                                    <cfset VARIABLES.canalNoticiaDescricao = trim(VARIABLES.canalNoticiaConfig.description)>
                                </cfif>
                                <cfif structKeyExists(VARIABLES.canalNoticiaConfig, "website_url") AND len(trim(VARIABLES.canalNoticiaConfig.website_url))>
                                    <cfset VARIABLES.canalNoticiaWebsite = trim(VARIABLES.canalNoticiaConfig.website_url)>
                                </cfif>
                                <cfif structKeyExists(VARIABLES.canalNoticiaConfig, "instagram_url") AND len(trim(VARIABLES.canalNoticiaConfig.instagram_url))>
                                    <cfset VARIABLES.canalNoticiaInstagram = trim(VARIABLES.canalNoticiaConfig.instagram_url)>
                                </cfif>
                                <cfif structKeyExists(VARIABLES.canalNoticiaConfig, "youtube_url") AND len(trim(VARIABLES.canalNoticiaConfig.youtube_url))>
                                    <cfset VARIABLES.canalNoticiaYoutube = trim(VARIABLES.canalNoticiaConfig.youtube_url)>
                                </cfif>
                                <cfif structKeyExists(VARIABLES.canalNoticiaConfig, "facebook_url") AND len(trim(VARIABLES.canalNoticiaConfig.facebook_url))>
                                    <cfset VARIABLES.canalNoticiaFacebook = trim(VARIABLES.canalNoticiaConfig.facebook_url)>
                                </cfif>
                                <cfif structKeyExists(VARIABLES.canalNoticiaConfig, "publication_mode") AND listFindNoCase("licensed_full,summary_link,external_only", trim(VARIABLES.canalNoticiaConfig.publication_mode & ""))>
                                    <cfset VARIABLES.noticiaPublicationMode = lCase(trim(VARIABLES.canalNoticiaConfig.publication_mode & ""))>
                                </cfif>
                            </cfif>
                            <cfif structKeyExists(VARIABLES.noticia, "original_url") AND reFindNoCase("^https?://", trim(VARIABLES.noticia.original_url & ""))>
                                <cfset VARIABLES.noticiaOriginalUrl = trim(VARIABLES.noticia.original_url & "")>
                            </cfif>
                            <cfif structKeyExists(VARIABLES.noticia, "gallery") AND isArray(VARIABLES.noticia.gallery)>
                                <cfloop array="#VARIABLES.noticia.gallery#" index="galleryItem">
                                    <cfif isStruct(galleryItem) AND structKeyExists(galleryItem, "url") AND len(trim(galleryItem.url))>
                                        <cfset VARIABLES.galeriaImagem = {
                                            url = galleryItem.url,
                                            caption = "",
                                            alt = VARIABLES.noticia.title
                                        }>
                                        <cfif left(VARIABLES.galeriaImagem.url, 1) EQ "/">
                                            <cfset VARIABLES.galeriaImagem.url = VARIABLES.apiConteudoBase & VARIABLES.galeriaImagem.url>
                                        </cfif>
                                        <cfif structKeyExists(galleryItem, "caption") AND len(trim(galleryItem.caption))>
                                            <cfset VARIABLES.galeriaImagem.caption = galleryItem.caption>
                                            <cfset VARIABLES.galeriaImagem.alt = galleryItem.caption>
                                        <cfelseif structKeyExists(galleryItem, "name") AND len(trim(galleryItem.name))>
                                            <cfset VARIABLES.galeriaImagem.alt = galleryItem.name>
                                        </cfif>
                                        <cfset arrayAppend(VARIABLES.galeriaNoticia, VARIABLES.galeriaImagem)>
                                    </cfif>
                                </cfloop>
                            </cfif>

                            <cfoutput>
                                <h1 class="h3 mb-3">#VARIABLES.noticia.title#</h1>
                                <div class="news-detail-meta-row mb-3">
                                    <div class="news-detail-meta-chips">
                                        <cfif len(trim(VARIABLES.canalNoticia))>
                                            <cfif len(trim(VARIABLES.canalNoticiaSlug))>
                                                <a href="#VARIABLES.newsRootUrl##VARIABLES.newsChannelSegment#/#VARIABLES.canalNoticiaSlug#/" class="news-meta-chip is-channel">#VARIABLES.canalNoticia#</a>
                                            <cfelse>
                                                <div class="news-meta-chip is-channel">#VARIABLES.canalNoticia#</div>
                                            </cfif>
                                        </cfif>
                                        <div class="news-meta-chip">
                                            <cfif structKeyExists(VARIABLES.noticia, "category") AND isStruct(VARIABLES.noticia.category)>
                                                #VARIABLES.noticia.category.name#
                                            <cfelse>
                                                Road Runners Press
                                            </cfif>
                                        </div>
                                        <cfif len(trim(VARIABLES.dataNoticia))>
                                            <div class="news-meta-chip">#VARIABLES.dataNoticia#</div>
                                        </cfif>
                                        <cfif VARIABLES.noticiaPublicationMode EQ "licensed_full" AND len(VARIABLES.noticiaOriginalUrl)
                                            AND structKeyExists(VARIABLES.canalNoticiaConfig, "authorized_republication")
                                            AND VARIABLES.canalNoticiaConfig.authorized_republication>
                                            <div class="news-meta-chip">#REQUEST.t('news.detail.authorizedRepublication')#</div>
                                        </cfif>
                                    </div>
                                    <button type="button" class="news-meta-chip news-detail-share-button" data-mdb-modal-init data-mdb-target="##shareModal">
                                        <i class="fa-solid fa-share"></i>
                                        #REQUEST.t("common.shareModal.title")#
                                    </button>
                                </div>
                                <cfif len(trim(VARIABLES.imagemNoticia))>
                                    <img src="#VARIABLES.imagemNoticia#" alt="#VARIABLES.noticia.title#" class="news-thumb mb-3" />
                                </cfif>
                                <cfif VARIABLES.noticiaPublicationMode EQ "external_only">
                                    <div class="news-publication-notice"><i class="fa-solid fa-arrow-up-right-from-square" aria-hidden="true"></i><span>#REQUEST.t('news.detail.externalOnlyDisclosure')#</span></div>
                                </cfif>
                                <cfif VARIABLES.noticiaPublicationMode EQ "summary_link" AND len(VARIABLES.noticiaSummaryText)>
                                    <section class="news-summary" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.detail.summaryTitle'))#">
                                        <div class="news-summary-body">
                                            <cfloop array="#newsSummaryParagraphs(VARIABLES.noticiaSummaryText)#" index="VARIABLES.noticiaSummaryParagraph">
                                                <p>#encodeForHTML(VARIABLES.noticiaSummaryParagraph)#</p>
                                            </cfloop>
                                        </div>
                                        <cfif arrayLen(VARIABLES.noticiaSummaryKeyPoints)>
                                            <div class="news-summary-key-points">
                                                <h3 class="news-summary-key-points-title">#encodeForHTML(REQUEST.t('news.detail.keyPointsTitle'))#</h3>
                                                <ul>
                                                    <cfloop array="#VARIABLES.noticiaSummaryKeyPoints#" index="VARIABLES.noticiaSummaryKeyPoint">
                                                        <li>#encodeForHTML(VARIABLES.noticiaSummaryKeyPoint)#</li>
                                                    </cfloop>
                                                </ul>
                                            </div>
                                        </cfif>
                                        <cfif len(VARIABLES.noticiaSummarySourcePreview)>
                                            <p class="news-summary-source-preview"><strong>#encodeForHTML(REQUEST.t('news.detail.sourcePreviewTitle'))#:</strong> #encodeForHTML(VARIABLES.noticiaSummarySourcePreview)#</p>
                                        </cfif>
                                    </section>
                                <cfelseif len(trim(VARIABLES.noticia.excerpt)) AND VARIABLES.canalNoticiaSlug NEQ "jornal-da-corrida">
                                    <div class="fs-5 news-muted mb-4">#encodeForHTML(VARIABLES.noticia.excerpt)#</div>
                                </cfif>
                                <cfif len(trim(VARIABLES.noticia.body_html & ""))>
                                    <div class="news-content" data-audience-article>#VARIABLES.noticia.body_html#</div>
                                </cfif>
                            </cfoutput>
                            <cfif structCount(VARIABLES.noticiaEventoRelacionado)>
                                <cfset VARIABLES.newsRelatedEventVariant = "mobile"/>
                                <cfinclude template="../includes/estrutura/noticia_evento_relacionado.cfm"/>
                            </cfif>
                            <cfoutput>
                                <cfif arrayLen(VARIABLES.galeriaNoticia)>
                                    <section class="news-gallery">
                                        <div class="news-gallery-title">#REQUEST.t('news.detail.galleryTitle')#</div>
                                        <div class="news-gallery-grid">
                                            <cfset VARIABLES.galleryIndex = 0>
                                            <cfloop array="#VARIABLES.galeriaNoticia#" index="galleryItem">
                                                <cfset VARIABLES.galleryIndex = VARIABLES.galleryIndex + 1>
                                                <button type="button"
                                                        class="news-gallery-item"
                                                        data-news-gallery-index="#VARIABLES.galleryIndex#"
                                                        data-news-gallery-url="#galleryItem.url#"
                                                        data-news-gallery-alt="#encodeForHtmlAttribute(galleryItem.alt)#"
                                                        data-news-gallery-caption="#encodeForHtmlAttribute(galleryItem.caption)#">
                                                    <div class="news-gallery-image-wrap">
                                                        <img src="#galleryItem.url#" alt="#galleryItem.alt#" class="news-gallery-image" loading="lazy" />
                                                    </div>
                                                    <cfif len(trim(galleryItem.caption))>
                                                        <div class="news-gallery-caption">#galleryItem.caption#</div>
                                                    </cfif>
                                                </button>
                                            </cfloop>
                                        </div>
                                    </section>
                                </cfif>
                                <cfset VARIABLES.noticiaSourceLink = len(VARIABLES.noticiaOriginalUrl) ? VARIABLES.noticiaOriginalUrl : VARIABLES.canalNoticiaWebsite>
                                <cfset VARIABLES.noticiaSourceUtmContent = VARIABLES.noticiaPublicationMode EQ "summary_link" ? "summary_continue_reading" : "article_channel_link">
                                <cfset VARIABLES.noticiaSourceLink = addNewsSourceAttribution(VARIABLES.noticiaSourceLink, VARIABLES.noticiaSourceUtmContent)>
                                <cfif len(trim(VARIABLES.canalNoticia)) AND len(trim(VARIABLES.noticiaSourceLink))>
                                    <a href="#encodeForHTMLAttribute(VARIABLES.noticiaSourceLink)#"
                                       target="_blank"
                                       rel="noopener noreferrer"
                                       class="news-channel-read-more#VARIABLES.noticiaPublicationMode EQ 'summary_link' ? ' is-source-summary' : ''#">
                                        <cfif VARIABLES.noticiaPublicationMode EQ "summary_link">
                                            <span class="news-channel-read-more-icon" aria-hidden="true"><i class="fa-regular fa-newspaper"></i></span>
                                            <span class="news-channel-read-more-copy">
                                                <span class="news-channel-read-more-kicker">#encodeForHTML(REQUEST.t('news.detail.sourceCtaKicker'))#</span>
                                                <span class="news-channel-read-more-label">#encodeForHTML(REQUEST.t('news.detail.sourceCtaLabel', { 'channel' = VARIABLES.canalNoticia }))#</span>
                                            </span>
                                            <span class="news-channel-read-more-action" aria-hidden="true"><i class="fa-solid fa-arrow-up-right-from-square"></i></span>
                                        <cfelse>
                                            #encodeForHTML(VARIABLES.noticiaPublicationMode EQ 'licensed_full' ? REQUEST.t('news.detail.readMoreAtChannel', { 'channel' = VARIABLES.canalNoticia }) : REQUEST.t('news.detail.continueAtSource', { 'channel' = VARIABLES.canalNoticia }))#
                                        </cfif>
                                    </a>
                                </cfif>
                                <cfif VARIABLES.noticiaPublicationMode EQ "licensed_full"
                                    AND (len(trim(VARIABLES.canalNoticia)) OR len(trim(VARIABLES.autorNoticia)))>
                                    <cfset VARIABLES.newsAuthorSignatureName = len(trim(VARIABLES.autorNoticia)) ? VARIABLES.autorNoticia : "Equipe editorial">
                                    <cfset VARIABLES.newsAuthorSignatureFallback = len(trim(VARIABLES.autorNoticia)) ? VARIABLES.autorNoticia : (len(trim(VARIABLES.canalNoticia)) ? VARIABLES.canalNoticia : "R")>
                                    <section class="news-channel-author-card" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.channel.authorCardAria'))#">
                                        <cfif len(trim(VARIABLES.canalNoticiaSlug))>
                                            <a href="#VARIABLES.newsRootUrl##VARIABLES.newsChannelSegment#/#VARIABLES.canalNoticiaSlug#/" class="news-channel-author-logo" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.channel.openChannelAria', { 'channel' = VARIABLES.canalNoticia }))#">
                                        <cfelse>
                                            <div class="news-channel-author-logo">
                                        </cfif>
                                            <cfif len(trim(VARIABLES.canalNoticiaLogo))>
                                                <img src="#VARIABLES.canalNoticiaLogo#" alt="#len(trim(VARIABLES.canalNoticia)) ? VARIABLES.canalNoticia : VARIABLES.newsAuthorSignatureName#" loading="lazy" />
                                            <cfelse>
                                                <div class="news-channel-author-fallback">#uCase(left(VARIABLES.newsAuthorSignatureFallback, 1))#</div>
                                            </cfif>
                                        <cfif len(trim(VARIABLES.canalNoticiaSlug))>
                                            </a>
                                        <cfelse>
                                            </div>
                                        </cfif>
                                        <div>
                                            <div class="news-channel-author-title">Por #VARIABLES.newsAuthorSignatureName#</div>
                                            <cfif len(trim(VARIABLES.canalNoticia))>
                                                <div class="news-channel-author-channel">
                                                    <span>Publicado em</span>
                                                    <cfif len(trim(VARIABLES.canalNoticiaSlug))>
                                                        <a href="#VARIABLES.newsRootUrl##VARIABLES.newsChannelSegment#/#VARIABLES.canalNoticiaSlug#/" class="news-channel-author-channel-link">#VARIABLES.canalNoticia#</a>
                                                    <cfelse>
                                                        <span class="news-channel-author-channel-link">#VARIABLES.canalNoticia#</span>
                                                    </cfif>
                                                </div>
                                            </cfif>
                                            <cfif len(trim(VARIABLES.canalNoticiaDescricao))>
                                                <div class="news-channel-author-description">#VARIABLES.canalNoticiaDescricao#</div>
                                            </cfif>
                                            <cfif len(trim(VARIABLES.canalNoticiaWebsite)) OR len(trim(VARIABLES.canalNoticiaInstagram)) OR len(trim(VARIABLES.canalNoticiaYoutube)) OR len(trim(VARIABLES.canalNoticiaFacebook))>
                                                <div class="news-channel-author-actions">
                                                    <cfif len(trim(VARIABLES.canalNoticiaWebsite))>
                                                        <a href="#VARIABLES.canalNoticiaWebsite#" target="_blank" rel="noopener noreferrer" class="news-channel-header-link" aria-label="#REQUEST.t('news.channel.websiteAria')#">
                                                            <i class="fa-solid fa-globe"></i>
                                                        </a>
                                                    </cfif>
                                                    <cfif len(trim(VARIABLES.canalNoticiaInstagram))>
                                                        <a href="#VARIABLES.canalNoticiaInstagram#" target="_blank" rel="noopener noreferrer" class="news-channel-header-link" aria-label="#REQUEST.t('news.channel.instagramAria')#">
                                                            <i class="fa-brands fa-instagram"></i>
                                                        </a>
                                                    </cfif>
                                                    <cfif len(trim(VARIABLES.canalNoticiaYoutube))>
                                                        <a href="#VARIABLES.canalNoticiaYoutube#" target="_blank" rel="noopener noreferrer" class="news-channel-header-link" aria-label="#REQUEST.t('news.channel.youtubeAria')#">
                                                            <i class="fa-brands fa-youtube"></i>
                                                        </a>
                                                    </cfif>
                                                    <cfif len(trim(VARIABLES.canalNoticiaFacebook))>
                                                        <a href="#VARIABLES.canalNoticiaFacebook#" target="_blank" rel="noopener noreferrer" class="news-channel-header-link" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.channel.facebookAria'))#">
                                                            <i class="fa-brands fa-facebook-f"></i>
                                                        </a>
                                                    </cfif>
                                                </div>
                                            </cfif>
                                        </div>
                                    </section>
                                </cfif>
                            </cfoutput>
                        <cfelse>
                            <cfheader statuscode="404" statustext="Not Found"/>
                            <cfoutput>
                                <div class="news-shell-card p-3" style="background-color: ##efefef;">
                                    <div class="fw-semibold mb-1">#REQUEST.t('news.detail.notFoundTitle')#</div>
                                    <div class="small news-muted mb-3">#REQUEST.t('news.detail.notFoundText')#</div>
                                    <a href="#VARIABLES.newsRootUrl#" class="news-pagination-link">#REQUEST.t('news.detail.backToNews')#</a>
                                </div>
                            </cfoutput>
                        </cfif>
                    <cfelse>
                        <cfif len(trim(URL.canal)) AND isStruct(VARIABLES.canalNoticiasAtivoConfig) AND structCount(VARIABLES.canalNoticiasAtivoConfig)>
                            <cfset VARIABLES.canalHeaderNome = structKeyExists(VARIABLES.canalNoticiasAtivoConfig, "name") ? VARIABLES.canalNoticiasAtivoConfig.name : REQUEST.t('news.filters.channelFallback')>
                            <cfset VARIABLES.canalHeaderDescricao = structKeyExists(VARIABLES.canalNoticiasAtivoConfig, "description") ? VARIABLES.canalNoticiasAtivoConfig.description : "">
                            <cfset VARIABLES.canalHeaderLogo = structKeyExists(VARIABLES.canalNoticiasAtivoConfig, "logo_url") ? VARIABLES.canalNoticiasAtivoConfig.logo_url : "">
                            <cfoutput>
                                <div class="news-channel-header">
                                    <div class="news-channel-header-logo">
                                        <cfif len(trim(VARIABLES.canalHeaderLogo))>
                                            <img src="#VARIABLES.canalHeaderLogo#" alt="#VARIABLES.canalHeaderNome#" />
                                        <cfelse>
                                            <div class="news-channel-header-fallback">#uCase(left(VARIABLES.canalHeaderNome, 1))#</div>
                                        </cfif>
                                    </div>
                                    <div class="news-channel-header-body">
                                        <div class="news-channel-header-top">
                                            <div class="news-channel-header-title">#VARIABLES.canalHeaderNome#</div>
                                            <div class="news-channel-header-links">
                                                <cfif structKeyExists(VARIABLES.canalNoticiasAtivoConfig, "website_url") AND len(trim(VARIABLES.canalNoticiasAtivoConfig.website_url))>
                                                    <a href="#VARIABLES.canalNoticiasAtivoConfig.website_url#" target="_blank" class="news-channel-header-link" aria-label="#REQUEST.t('news.channel.websiteAria')#">
                                                        <i class="fa-solid fa-globe"></i>
                                                    </a>
                                                </cfif>
                                                <cfif structKeyExists(VARIABLES.canalNoticiasAtivoConfig, "instagram_url") AND len(trim(VARIABLES.canalNoticiasAtivoConfig.instagram_url))>
                                                    <a href="#VARIABLES.canalNoticiasAtivoConfig.instagram_url#" target="_blank" class="news-channel-header-link" aria-label="#REQUEST.t('news.channel.instagramAria')#">
                                                        <i class="fa-brands fa-instagram"></i>
                                                    </a>
                                                </cfif>
                                                <cfif structKeyExists(VARIABLES.canalNoticiasAtivoConfig, "youtube_url") AND len(trim(VARIABLES.canalNoticiasAtivoConfig.youtube_url))>
                                                    <a href="#VARIABLES.canalNoticiasAtivoConfig.youtube_url#" target="_blank" class="news-channel-header-link" aria-label="#REQUEST.t('news.channel.youtubeAria')#">
                                                        <i class="fa-brands fa-youtube"></i>
                                                    </a>
                                                </cfif>
                                            </div>
                                        </div>
                                        <cfif len(trim(VARIABLES.canalHeaderDescricao))>
                                            <div class="news-channel-header-description">#VARIABLES.canalHeaderDescricao#</div>
                                        </cfif>
                                    </div>
                                </div>
                            </cfoutput>
                        </cfif>
                        <div class="d-flex flex-wrap align-items-center gap-2 mb-3">
                            <div>
                                <div class="h5 mb-1"><cfoutput>#REQUEST.t('news.list.recentPublications')#</cfoutput></div>
                            </div>
                        </div>

                        <cfif arrayLen(VARIABLES.noticiasPaginadas)>
                            <div class="news-list-grid" id="news-infinite-list">
                                <cfset VARIABLES.newsListFeaturedFirst = true>
                                <cfset VARIABLES.newsListStartIndex = 0>
                                <cfinclude template="../includes/estrutura/noticias_lista_cards.cfm"/>
                            </div>

                            <cfif VARIABLES.totalPaginasNoticias GT 1>
                                <cfset VARIABLES.paginacaoNoticiasInicio = max(1, URL.page - 2)>
                                <cfset VARIABLES.paginacaoNoticiasFim = min(VARIABLES.totalPaginasNoticias, VARIABLES.paginacaoNoticiasInicio + 4)>
                                <cfif (VARIABLES.paginacaoNoticiasFim - VARIABLES.paginacaoNoticiasInicio) LT 4>
                                    <cfset VARIABLES.paginacaoNoticiasInicio = max(1, VARIABLES.paginacaoNoticiasFim - 4)>
                                </cfif>
                                <div class="d-flex flex-wrap gap-2 justify-content-center mt-4 rr-infinite-pagination" id="news-pagination">
                                    <cfif URL.page GT 1>
                                        <cfoutput><a href="#VARIABLES.baseNoticiasUrl#<cfif URL.page - 1 GT 1>?page=#URL.page-1#</cfif>" class="news-pagination-link">#REQUEST.t('news.pagination.previous')#</a></cfoutput>
                                    </cfif>
                                    <cfif VARIABLES.paginacaoNoticiasInicio GT 1>
                                        <cfoutput><a href="#VARIABLES.baseNoticiasUrl#" class="news-pagination-link">1</a></cfoutput>
                                        <cfif VARIABLES.paginacaoNoticiasInicio GT 2>
                                            <span class="news-pagination-link">...</span>
                                        </cfif>
                                    </cfif>
                                    <cfloop from="#VARIABLES.paginacaoNoticiasInicio#" to="#VARIABLES.paginacaoNoticiasFim#" index="pagina">
                                        <cfoutput><a href="#VARIABLES.baseNoticiasUrl#<cfif pagina GT 1>?page=#pagina#</cfif>" class="news-pagination-link<cfif pagina EQ URL.page> is-active</cfif>">#pagina#</a></cfoutput>
                                    </cfloop>
                                    <cfif VARIABLES.paginacaoNoticiasFim LT VARIABLES.totalPaginasNoticias>
                                        <cfif VARIABLES.paginacaoNoticiasFim LT (VARIABLES.totalPaginasNoticias - 1)>
                                            <span class="news-pagination-link">...</span>
                                        </cfif>
                                        <cfoutput><a href="#VARIABLES.baseNoticiasUrl#?page=#VARIABLES.totalPaginasNoticias#" class="news-pagination-link">#VARIABLES.totalPaginasNoticias#</a></cfoutput>
                                    </cfif>
                                    <cfif URL.page LT VARIABLES.totalPaginasNoticias>
                                        <cfoutput><a href="#VARIABLES.baseNoticiasUrl#?page=#URL.page+1#" class="news-pagination-link">#REQUEST.t('news.pagination.next')#</a></cfoutput>
                                    </cfif>
                                </div>
                            </cfif>
                            <cfif URL.page LT VARIABLES.totalPaginasNoticias>
                                <cfoutput>
                                    <div class="rr-infinite-scroll-control"
                                        data-rr-infinite-scroll
                                        data-list-target="##news-infinite-list"
                                        data-pagination-target="##news-pagination"
                                        data-endpoint="/api/noticias_infinite.cfm"
                                        data-current-page="#URL.page#"
                                        data-total-pages="#VARIABLES.totalPaginasNoticias#"
                                        data-channel="#HTMLEditFormat(URL.canal)#"
                                        data-i18n-lang="#HTMLEditFormat(REQUEST.lang)#">
                                        <button type="button" class="rr-infinite-load-more" data-rr-infinite-button><cfoutput>#REQUEST.t('news.list.loadMore')#</cfoutput></button>
                                        <div class="rr-infinite-status" data-rr-infinite-status aria-live="polite"></div>
                                        <div class="rr-infinite-sentinel" data-rr-infinite-sentinel></div>
                                    </div>
                                </cfoutput>
                            </cfif>
                        <cfelse>
                            <cfoutput>
                            <div class="news-shell-card p-3" style="background-color:##efefef;">
                                <div class="fw-semibold mb-1">#REQUEST.t('news.list.emptyTitle')#</div>
                                <div class="small news-muted">#REQUEST.t('news.list.emptyText')#</div>
                            </div>
                            </cfoutput>
                        </cfif>
                    </cfif>
                </div>
                <cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada AND arrayLen(VARIABLES.noticiasRelacionadas)>
                    <cfoutput>
                        <section class="news-shell-card news-related p-3 mt-3">
                            <div class="news-related-title">#REQUEST.t('news.detail.relatedTitle')#</div>
                            <div class="news-related-text">#REQUEST.t('news.detail.relatedText')#</div>
                            <div class="news-related-grid">
                                <cfloop array="#VARIABLES.noticiasRelacionadas#" index="item">
                                    <cfset VARIABLES.relatedImagem = "">
                                    <cfset VARIABLES.relatedCanal = "">
                                    <cfset VARIABLES.relatedCategoria = "">
                                    <cfif structKeyExists(item, "featured_media") AND isStruct(item.featured_media) AND structKeyExists(item.featured_media, "url") AND len(trim(item.featured_media.url))>
                                        <cfset VARIABLES.relatedImagem = item.featured_media.url>
                                        <cfif left(VARIABLES.relatedImagem, 1) EQ "/">
                                            <cfset VARIABLES.relatedImagem = VARIABLES.apiConteudoBase & VARIABLES.relatedImagem>
                                        </cfif>
                                    </cfif>
                                    <cfif structKeyExists(item, "content_type") AND isStruct(item.content_type) AND structKeyExists(item.content_type, "name") AND len(trim(item.content_type.name))>
                                        <cfset VARIABLES.relatedCanal = item.content_type.name>
                                    </cfif>
                                    <cfif structKeyExists(item, "category") AND isStruct(item.category) AND structKeyExists(item.category, "name") AND len(trim(item.category.name))>
                                        <cfset VARIABLES.relatedCategoria = item.category.name>
                                    </cfif>
                                    <cfset VARIABLES.relatedNewsCurrentRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
                                    <cfset VARIABLES.relatedNewsRouteParams = duplicate(VARIABLES.relatedNewsCurrentRouteParams) />
                                    <cfset VARIABLES.relatedNewsRouteParams["tag"] = lCase(trim(item.slug)) />
                                    <cfset REQUEST.currentRouteParams = VARIABLES.relatedNewsRouteParams />
                                    <cfset VARIABLES.relatedNewsPath = REQUEST.i18nBuildPath("newsDetail") />
                                    <cfset REQUEST.currentRouteParams = VARIABLES.relatedNewsCurrentRouteParams />
                                    <cfset VARIABLES.relatedNewsExternal = false />
                                    <cfif structKeyExists(item, "content_type") AND isStruct(item.content_type)
                                        AND structKeyExists(item.content_type, "publication_mode")
                                        AND lCase(trim(item.content_type.publication_mode & "")) EQ "external_only"
                                        AND structKeyExists(item, "original_url") AND reFindNoCase("^https?://", trim(item.original_url & ""))>
                                        <cfset VARIABLES.relatedNewsPath = trim(item.original_url & "") />
                                        <cfset VARIABLES.relatedNewsExternal = true />
                                    </cfif>
                                    <a href="#encodeForHTMLAttribute(VARIABLES.relatedNewsPath)#"<cfif VARIABLES.relatedNewsExternal> target="_blank" rel="noopener noreferrer"</cfif> class="news-related-card" data-audience-content-type="news" data-audience-content-id="#HTMLEditFormat(structKeyExists(item, "id") AND isSimpleValue(item.id) AND len(trim(item.id & "")) ? trim(item.id & "") : item.slug)#">
                                        <cfif len(trim(VARIABLES.relatedImagem))>
                                            <img src="#VARIABLES.relatedImagem#" alt="#item.title#" class="news-related-image" loading="lazy" />
                                        </cfif>
                                        <div class="news-related-body">
                                            <div class="d-flex flex-wrap gap-2">
                                                <cfif len(trim(VARIABLES.relatedCanal))>
                                                    <div class="news-meta-chip is-channel">#VARIABLES.relatedCanal#</div>
                                                </cfif>
                                                <cfif len(trim(VARIABLES.relatedCategoria))>
                                                    <div class="news-meta-chip">#VARIABLES.relatedCategoria#</div>
                                                </cfif>
                                            </div>
                                            <div class="news-related-name">#item.title#</div>
                                        </div>
                                    </a>
                                </cfloop>
                            </div>
                        </section>
                    </cfoutput>
                </cfif>
            </div>

            <div class="d-none d-lg-block col-lg-3 order-3 home-mobile-section">
                <cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada AND len(trim(VARIABLES.canalNoticia))>
                    <cfoutput>
                        <div class="news-channel-header is-sidebar">
                            <cfif len(trim(VARIABLES.canalNoticiaSlug))>
                                <a href="#VARIABLES.newsRootUrl##VARIABLES.newsChannelSegment#/#VARIABLES.canalNoticiaSlug#/" class="news-channel-header-logo news-channel-header-channel-link" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.channel.openChannelAria', { 'channel' = VARIABLES.canalNoticia }))#">
                            <cfelse>
                                <div class="news-channel-header-logo">
                            </cfif>
                                <cfif len(trim(VARIABLES.canalNoticiaLogo))>
                                    <img src="#encodeForHTMLAttribute(VARIABLES.canalNoticiaLogo)#" alt="#encodeForHTMLAttribute(VARIABLES.canalNoticia)#" loading="lazy" />
                                <cfelse>
                                    <div class="news-channel-header-fallback">#encodeForHTML(uCase(left(VARIABLES.canalNoticia, 1)))#</div>
                                </cfif>
                            <cfif len(trim(VARIABLES.canalNoticiaSlug))>
                                </a>
                            <cfelse>
                                </div>
                            </cfif>
                            <div class="news-channel-header-body">
                                <div class="news-channel-header-top">
                                    <cfif len(trim(VARIABLES.canalNoticiaSlug))>
                                        <a href="#VARIABLES.newsRootUrl##VARIABLES.newsChannelSegment#/#VARIABLES.canalNoticiaSlug#/" class="news-channel-header-title news-channel-header-channel-link">#encodeForHTML(VARIABLES.canalNoticia)#</a>
                                    <cfelse>
                                        <div class="news-channel-header-title">#encodeForHTML(VARIABLES.canalNoticia)#</div>
                                    </cfif>
                                    <cfif len(trim(VARIABLES.canalNoticiaWebsite)) OR len(trim(VARIABLES.canalNoticiaInstagram)) OR len(trim(VARIABLES.canalNoticiaYoutube)) OR len(trim(VARIABLES.canalNoticiaFacebook))>
                                        <div class="news-channel-header-links">
                                            <cfif len(trim(VARIABLES.canalNoticiaWebsite))>
                                                <a href="#encodeForHTMLAttribute(VARIABLES.canalNoticiaWebsite)#" target="_blank" rel="noopener noreferrer" class="news-channel-header-link" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.channel.websiteAria'))#">
                                                    <i class="fa-solid fa-globe"></i>
                                                </a>
                                            </cfif>
                                            <cfif len(trim(VARIABLES.canalNoticiaInstagram))>
                                                <a href="#encodeForHTMLAttribute(VARIABLES.canalNoticiaInstagram)#" target="_blank" rel="noopener noreferrer" class="news-channel-header-link" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.channel.instagramAria'))#">
                                                    <i class="fa-brands fa-instagram"></i>
                                                </a>
                                            </cfif>
                                            <cfif len(trim(VARIABLES.canalNoticiaYoutube))>
                                                <a href="#encodeForHTMLAttribute(VARIABLES.canalNoticiaYoutube)#" target="_blank" rel="noopener noreferrer" class="news-channel-header-link" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.channel.youtubeAria'))#">
                                                    <i class="fa-brands fa-youtube"></i>
                                                </a>
                                            </cfif>
                                            <cfif len(trim(VARIABLES.canalNoticiaFacebook))>
                                                <a href="#encodeForHTMLAttribute(VARIABLES.canalNoticiaFacebook)#" target="_blank" rel="noopener noreferrer" class="news-channel-header-link" aria-label="#encodeForHTMLAttribute(REQUEST.t('news.channel.facebookAria'))#">
                                                    <i class="fa-brands fa-facebook-f"></i>
                                                </a>
                                            </cfif>
                                        </div>
                                    </cfif>
                                </div>
                                <cfif len(trim(VARIABLES.canalNoticiaDescricao))>
                                    <div class="news-channel-header-description">#encodeForHTML(VARIABLES.canalNoticiaDescricao)#</div>
                                </cfif>
                            </div>
                        </div>
                    </cfoutput>
                </cfif>
                <cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada AND structCount(VARIABLES.noticiaEventoRelacionado)>
                    <cfset VARIABLES.newsRelatedEventVariant = "desktop"/>
                    <cfinclude template="../includes/estrutura/noticia_evento_relacionado.cfm"/>
                </cfif>
                <cfinclude template="../includes/estrutura/conteudo_lateral_api.cfm"/>
            </div>

        </div>

        </main>

    </div>

    <cfinclude template="../includes/estrutura/infinite_scroll.cfm"/>

    <div class="modal fade" id="modalNewsGallery" tabindex="-1" aria-labelledby="modalNewsGalleryLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered news-gallery-modal-dialog">
            <div class="modal-content news-gallery-modal-content">
                <div class="modal-body news-gallery-modal-body">
                    <button type="button" class="btn-close news-gallery-modal-close" data-mdb-dismiss="modal" aria-label="<cfoutput>#REQUEST.t('news.gallery.closeAria')#</cfoutput>"></button>
                    <button type="button" class="news-gallery-nav prev" data-news-gallery-prev aria-label="<cfoutput>#REQUEST.t('news.gallery.previousAria')#</cfoutput>">
                        <i class="fa-solid fa-chevron-left"></i>
                    </button>
                    <button type="button" class="news-gallery-nav next" data-news-gallery-next aria-label="<cfoutput>#REQUEST.t('news.gallery.nextAria')#</cfoutput>">
                        <i class="fa-solid fa-chevron-right"></i>
                    </button>
                    <div class="news-gallery-stage">
                        <img src="" alt="" id="newsGalleryModalImage" />
                    </div>
                    <div class="news-gallery-modal-meta">
                        <div class="news-gallery-modal-caption" id="newsGalleryModalCaption"></div>
                        <div class="news-gallery-modal-counter" id="newsGalleryModalCounter"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <cfinclude template="../includes/estrutura/footer.cfm"/>

    <cfinclude template="../includes/modal/modal_badges.cfm"/>
    <cfinclude template="../includes/modal/modal_youtube.cfm"/>
    <cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada>
        <script>
            document.addEventListener("click", function (event) {
                var link = event.target.closest(".news-content a[href]");
                if (!link || typeof changeVideoUrl !== "function") {
                    return;
                }

                var articleTitle = document.querySelector(".news-content")
                    ?.closest("article")
                    ?.querySelector("h1")
                    ?.textContent
                    ?.trim() || document.title;

                if (changeVideoUrl(link.href, articleTitle, "")) {
                    event.preventDefault();
                }
            });
        </script>
    </cfif>
    <cfinclude template="../includes/modal/modal_cupom_foco.cfm"/>
    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>
    <cfinclude template="../includes/modal/modal_login.cfm"/>
    <cfinclude template="../includes/modal/modal_seguidores.cfm"/>
    <cfinclude template="../includes/modal/modal_pagamento.cfm"/>
    <cfif VARIABLES.isNoticiaDetalhe AND VARIABLES.noticiaEncontrada>
        <cfinclude template="../includes/modal/modal_enviar.cfm"/>
    </cfif>

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

    <script>
        (function () {
            document.querySelectorAll('.news-content a[href]').forEach(function (link) {
                const rawHref = link.getAttribute('href') || '';
                const href = rawHref.trim();

                if (!href || href.charAt(0) === '#' || href.indexOf('javascript:') === 0) {
                    return;
                }

                try {
                    const parsedUrl = new URL(href, window.location.href);

                    if (parsedUrl.protocol === 'mailto:' || parsedUrl.protocol === 'tel:') {
                        return;
                    }

                    if (parsedUrl.origin !== window.location.origin) {
                        const relValues = (link.getAttribute('rel') || '').split(/\s+/).filter(Boolean);

                        link.setAttribute('target', '_blank');

                        ['noopener', 'noreferrer'].forEach(function (relValue) {
                            if (relValues.indexOf(relValue) === -1) {
                                relValues.push(relValue);
                            }
                        });

                        link.setAttribute('rel', relValues.join(' '));
                    }
                } catch (error) {
                    return;
                }
            });

            const galleryTriggers = Array.from(document.querySelectorAll('[data-news-gallery-index]'));
            const modalElement = document.getElementById('modalNewsGallery');

            if (!galleryTriggers.length || !modalElement) {
                return;
            }

            const modalImage = document.getElementById('newsGalleryModalImage');
            const modalCaption = document.getElementById('newsGalleryModalCaption');
            const modalCounter = document.getElementById('newsGalleryModalCounter');
            const prevButton = modalElement.querySelector('[data-news-gallery-prev]');
            const nextButton = modalElement.querySelector('[data-news-gallery-next]');
            const modalInstance = window.mdb && window.mdb.Modal
                ? window.mdb.Modal.getOrCreateInstance(modalElement)
                : (window.bootstrap && window.bootstrap.Modal
                    ? window.bootstrap.Modal.getOrCreateInstance(modalElement)
                    : null);

            let currentGalleryIndex = 0;

            function decodeHtmlEntities(value) {
                if (!value) {
                    return '';
                }

                const textarea = document.createElement('textarea');
                textarea.innerHTML = value;
                return textarea.value;
            }

            function renderGalleryItem(index) {
                if (!galleryTriggers.length) {
                    return;
                }

                currentGalleryIndex = Math.max(0, Math.min(index, galleryTriggers.length - 1));
                const trigger = galleryTriggers[currentGalleryIndex];
                const imageUrl = trigger.getAttribute('data-news-gallery-url') || '';
                const imageAlt = decodeHtmlEntities(trigger.getAttribute('data-news-gallery-alt') || '');
                const imageCaption = decodeHtmlEntities(trigger.getAttribute('data-news-gallery-caption') || '');

                modalImage.src = imageUrl;
                modalImage.alt = imageAlt || imageCaption || 'Foto da notícia';
                modalCaption.textContent = imageCaption;
                modalCounter.textContent = (currentGalleryIndex + 1) + ' de ' + galleryTriggers.length;
                prevButton.disabled = currentGalleryIndex === 0;
                nextButton.disabled = currentGalleryIndex === galleryTriggers.length - 1;
            }

            function openGallery(index) {
                renderGalleryItem(index);
                if (modalInstance) {
                    modalInstance.show();
                }
            }

            galleryTriggers.forEach(function (trigger, index) {
                trigger.addEventListener('click', function () {
                    openGallery(index);
                });
            });

            prevButton.addEventListener('click', function () {
                renderGalleryItem(currentGalleryIndex - 1);
            });

            nextButton.addEventListener('click', function () {
                renderGalleryItem(currentGalleryIndex + 1);
            });

            document.addEventListener('keydown', function (event) {
                if (!modalElement.classList.contains('show')) {
                    return;
                }

                if (event.key === 'ArrowLeft') {
                    event.preventDefault();
                    renderGalleryItem(currentGalleryIndex - 1);
                }

                if (event.key === 'ArrowRight') {
                    event.preventDefault();
                    renderGalleryItem(currentGalleryIndex + 1);
                }
            });
        }());
    </script>

</body>

</html>
