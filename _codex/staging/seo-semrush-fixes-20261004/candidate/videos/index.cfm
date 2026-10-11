<!doctype html>
<html lang="<cfoutput>#HTMLEditFormat(REQUEST.htmlLang)#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/videos/"/>
<cfset VARIABLES.routeKey = "videos"/>

<!--- PARAMS --->
<cfparam name="URL.page" default="1"/>
<cfparam name="URL.tag" default=""/>
<cfparam name="URL.canal" default=""/>
<cfset URL.page = isNumeric(URL.page) AND URL.page GTE 1 ? int(URL.page) : 1/>
<cfset URL.canal = lCase(trim(URL.canal))/>
<cfset VARIABLES.videosRootUrl = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("videos") : "/videos/"/>
<cfset VARIABLES.videosChannelSegment = structKeyExists(REQUEST, "t") ? REQUEST.t('videos.routes.channelSegment') : "canal"/>
<cfset VARIABLES.videosAggregatorFallbacks = {
    "pt-BR" = {
        "label" = "Agregador de vídeos",
        "copy" = "Vídeos das fontes mais relevantes e confiáveis sobre corrida de rua, reunidos em um só lugar."
    },
    "en" = {
        "label" = "Video aggregator",
        "copy" = "Videos from the most relevant and trusted road running sources, brought together in one place."
    },
    "es" = {
        "label" = "Agregador de videos",
        "copy" = "Videos de las fuentes más relevantes y confiables sobre carreras de calle, reunidos en un solo lugar."
    }
}/>
<cfset VARIABLES.videosAggregatorLanguage = structKeyExists(REQUEST, "lang") AND structKeyExists(VARIABLES.videosAggregatorFallbacks, REQUEST.lang) ? REQUEST.lang : "pt-BR"/>
<cfset VARIABLES.videosAggregatorLabel = structKeyExists(REQUEST, "t") ? REQUEST.t("videos.hero.aggregatorLabel") : ""/>
<cfset VARIABLES.videosAggregatorCopy = structKeyExists(REQUEST, "t") ? REQUEST.t("videos.hero.aggregatorCopy") : ""/>
<cfif NOT len(trim(VARIABLES.videosAggregatorLabel)) OR VARIABLES.videosAggregatorLabel EQ "videos.hero.aggregatorLabel">
    <cfset VARIABLES.videosAggregatorLabel = VARIABLES.videosAggregatorFallbacks[VARIABLES.videosAggregatorLanguage].label/>
</cfif>
<cfif NOT len(trim(VARIABLES.videosAggregatorCopy)) OR VARIABLES.videosAggregatorCopy EQ "videos.hero.aggregatorCopy">
    <cfset VARIABLES.videosAggregatorCopy = VARIABLES.videosAggregatorFallbacks[VARIABLES.videosAggregatorLanguage].copy/>
</cfif>
<cfset VARIABLES.baseVideosUrl = len(trim(URL.canal)) ? "#VARIABLES.videosRootUrl##VARIABLES.videosChannelSegment#/#URL.canal#/" : VARIABLES.videosRootUrl>
<cfset VARIABLES.videosRequestPath = structKeyExists(CGI, "REQUEST_URI") ? lCase(listFirst(trim(CGI.REQUEST_URI), "?")) : ""/>
<cfset VARIABLES.videosChannelPathWithoutSlug = rereplace(VARIABLES.videosRequestPath, "/+$", "", "all") & "/" />
<cfif NOT len(trim(URL.canal)) AND (
    (structKeyExists(URL, "tag") AND len(trim(URL.tag)) AND lCase(trim(URL.tag)) EQ lCase(trim(VARIABLES.videosChannelSegment)))
    OR VARIABLES.videosChannelPathWithoutSlug EQ "/videos/#lCase(trim(VARIABLES.videosChannelSegment))#/"
    OR VARIABLES.videosChannelPathWithoutSlug EQ "/en/videos/channel/"
    OR VARIABLES.videosChannelPathWithoutSlug EQ "/es/videos/canal/"
)>
    <cflocation url="#VARIABLES.videosRootUrl#" addtoken="false"/>
</cfif>

<!--- VARIAVEIS --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>

<!--- LOCATION --->
<cfinclude template="../includes/location.cfm"/>

<!--- BACKEND --->
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- VIDEOS --->
<cfset VARIABLES.videos = []>
<cfset VARIABLES.videosPaginados = []>
<cfset VARIABLES.totalPaginasVideos = 1>
<cfset VARIABLES.itensPorPaginaVideos = 11>
<cfset VARIABLES.canaisVideos = []>
<cfset VARIABLES.canalVideoSelecionadoNome = "">

<cffunction name="buildVideoChannelSlug" access="public" returntype="string" output="false">
    <cfargument name="channelName" type="string" required="true"/>
    <cfset var normalized = trim(arguments.channelName)>
    <cfif NOT len(normalized)>
        <cfreturn "">
    </cfif>
    <cfset normalized = lCase(normalized)>
    <cfset normalized = replaceList(normalized, "á,à,â,ã,ä,å,é,è,ê,ë,í,ì,î,ï,ó,ò,ô,õ,ö,ú,ù,û,ü,ç,ñ", "a,a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c,n")>
    <cfset normalized = rereplace(normalized, "[^a-z0-9]+", "-", "all")>
    <cfset normalized = rereplace(normalized, "^-+|-+$", "", "all")>
    <cfreturn normalized>
</cffunction>

<cfquery name="qVideosChannels" result="qVideosChannelsMeta">
    SELECT DISTINCT media.media_canal_nome
    FROM tb_media media
    WHERE media.pub_status = TRUE
    AND media.media_canal_nome IS NOT NULL
    AND trim(media.media_canal_nome) <> ''
    ORDER BY media.media_canal_nome
</cfquery>
<cfset logQueryDebug("qVideosChannels", qVideosChannelsMeta, "videos/index/canais", "sem cache", qVideosChannels)/>

<cfif qVideosChannels.recordCount>
    <cfoutput query="qVideosChannels">
        <cfset arrayAppend(VARIABLES.canaisVideos, {
            slug = buildVideoChannelSlug(media_canal_nome),
            name = media_canal_nome
        })>
        <cfif len(trim(URL.canal)) AND buildVideoChannelSlug(media_canal_nome) EQ URL.canal>
            <cfset VARIABLES.canalVideoSelecionadoNome = media_canal_nome>
        </cfif>
    </cfoutput>
</cfif>

<cfif len(trim(URL.canal)) AND NOT len(trim(VARIABLES.canalVideoSelecionadoNome))>
    <cflocation url="#VARIABLES.videosRootUrl#" addtoken="false"/>
</cfif>

<cfquery name="qVideos" result="qVideosMeta">
    SELECT media.id_media,
           media.media_titulo,
           media.media_url,
           media.data_publicacao,
           media.media_canal_nome AS nome_canal_video
    FROM tb_media media
    WHERE media.pub_status = TRUE
    <cfif len(trim(VARIABLES.canalVideoSelecionadoNome))>
        AND media.media_canal_nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.canalVideoSelecionadoNome#"/>
    </cfif>
    ORDER BY media.data_publicacao DESC NULLS LAST,
             media.id_media DESC
</cfquery>
<cfset logQueryDebug("qVideos", qVideosMeta, "videos/index/lista", "sem cache", qVideos)/>

<cfif qVideos.recordcount>
    <cfset VARIABLES.totalPaginasVideos = ceiling(qVideos.recordcount / VARIABLES.itensPorPaginaVideos)>
    <cfif URL.page GT VARIABLES.totalPaginasVideos>
        <cfset URL.page = VARIABLES.totalPaginasVideos>
    </cfif>
    <cfset VARIABLES.paginaInicialVideos = ((URL.page - 1) * VARIABLES.itensPorPaginaVideos) + 1>
    <cfset VARIABLES.paginaFinalVideos = min(VARIABLES.paginaInicialVideos + VARIABLES.itensPorPaginaVideos - 1, qVideos.recordcount)>
    <cfif VARIABLES.paginaInicialVideos LTE qVideos.recordcount>
        <cfloop query="qVideos" startrow="#VARIABLES.paginaInicialVideos#" endrow="#VARIABLES.paginaFinalVideos#">
            <cfset arrayAppend(VARIABLES.videosPaginados, {
                id_media = qVideos.id_media,
                media_titulo = qVideos.media_titulo,
                media_url = qVideos.media_url,
                data_publicacao = qVideos.data_publicacao,
                nome_canal_video = qVideos.nome_canal_video
            })>
        </cfloop>
    </cfif>
</cfif>

<cfif len(trim(URL.canal))>
    <cfset REQUEST.currentRouteKey = "videosChannel" />
<cfelse>
    <cfset REQUEST.currentRouteKey = "videos" />
</cfif>

<!--- META INFO --->
<cfif len(trim(URL.canal))>
    <cfset VARIABLES.canonical = "#REQUEST.i18nBuildAbsoluteUrl('videosChannel')##URL.page GT 1 ? '?page=' & URL.page : ''#">
<cfelse>
    <cfset VARIABLES.canonical = "#REQUEST.i18nBuildAbsoluteUrl('videos')##URL.page GT 1 ? '?page=' & URL.page : ''#">
</cfif>
<cfset VARIABLES.title = "#REQUEST.t('videos.meta.title')# - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = REQUEST.t('videos.meta.description')/>
<cfset VARIABLES.hreflangPage = URL.page/>
<cfif len(trim(VARIABLES.canalVideoSelecionadoNome))>
    <cfset VARIABLES.title = "#REQUEST.t('videos.meta.title')# - #HTMLEditFormat(VARIABLES.canalVideoSelecionadoNome)# - #APPLICATION.nomeSite#"/>
    <cfset VARIABLES.description = HTMLEditFormat(VARIABLES.canalVideoSelecionadoNome) & ": " & VARIABLES.description/>
</cfif>
<cfif URL.page GT 1>
    <cfset VARIABLES.editorialPageLabel = REQUEST.t("videos.list.pageOf", {"page" = URL.page, "total" = VARIABLES.totalPaginasVideos})/>
    <cfset VARIABLES.title = VARIABLES.title & " - " & VARIABLES.editorialPageLabel/>
    <cfset VARIABLES.description = VARIABLES.editorialPageLabel & ". " & VARIABLES.description/>
</cfif>
<cfset VARIABLES.keywords = REQUEST.t('videos.meta.keywords')/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<body>

    <!--- SEO WEB TOOLS --->
    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .videos-shell-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            color: #333333;
        }

        .videos-shell-card.is-list-shell {
            border: 0;
            border-radius: 0;
            background-color: transparent;
            padding: 0 !important;
        }

        .videos-muted {
            color: rgba(51, 51, 51, 0.72);
        }

        .videos-channel-filters {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            margin-bottom: 0.85rem;
        }

        .videos-filter-chip {
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

        .videos-filter-chip.is-active,
        .videos-filter-chip:hover {
            border-color: #fab120;
            background-color: #fff8e6;
            color: #333333;
        }

        .videos-channel-select-mobile {
            display: none;
        }

        .videos-channel-select {
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

        .videos-channel-select:focus {
            outline: none;
            border-color: rgba(250, 177, 32, 0.55);
            box-shadow: 0 10px 28px rgba(51, 51, 51, 0.08);
        }

        .videos-item {
            display: block;
            height: 100%;
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            color: #333333;
            text-decoration: none;
            overflow: hidden;
        }

        .videos-item.is-featured {
            grid-column: 1 / -1;
            background-color: #efefef;
        }

        .videos-list-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 0.85rem;
        }

        .videos-item-body {
            padding: 0.9rem;
        }

        .videos-item.is-featured .videos-item-body {
            padding: 1rem;
        }

        .videos-thumb-wrap {
            position: relative;
            background-color: #efefef;
        }

        .videos-thumb {
            width: 100%;
            aspect-ratio: 16 / 9;
            object-fit: cover;
            display: block;
            background-color: #efefef;
        }

        .videos-play-indicator {
            position: absolute;
            inset: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            pointer-events: none;
        }

        .videos-play-indicator span {
            width: 72px;
            height: 72px;
            border-radius: 999px;
            background-color: rgba(255, 255, 255, 0.72);
            color: rgba(51, 51, 51, 0.72);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 1.45rem;
            box-shadow: 0 10px 20px rgba(17, 17, 17, 0.08);
        }

        .videos-item-title {
            color: #333333;
            font-size: 1.04rem;
            font-weight: 700;
            line-height: 1.22;
            margin-bottom: 0.35rem;
        }

        .videos-item.is-featured .videos-item-title {
            font-size: 1.4rem;
            line-height: 1.15;
        }

        .videos-item-channel {
            color: rgba(51, 51, 51, 0.72);
            font-size: 0.82rem;
            font-weight: 600;
            line-height: 1.3;
            margin-bottom: 0.3rem;
        }

        .videos-meta-chip {
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

        .videos-pagination-link {
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

        .videos-pagination-link.is-active,
        .videos-pagination-link:hover {
            border-color: #fab120;
            background-color: #fff8e6;
            color: #333333;
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
            .videos-list-grid {
                grid-template-columns: 1fr;
            }

            .videos-channel-filters {
                display: none;
            }

            .videos-channel-select-mobile {
                display: block;
                margin-bottom: 0.85rem;
            }

            .videos-hero {
                padding: 0.9rem !important;
                margin-bottom: 0.75rem !important;
            }

            .videos-item.is-featured .videos-item-title {
                font-size: 1.16rem;
            }
        }
    </style>

    <div class="container">

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <div class="page-section-hero page-section-hero-editorial">
            <div class="page-section-hero-editorial-content">
                <h1 class="page-section-hero-title">
                    <svg class="page-section-hero-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 768 767.999994" preserveAspectRatio="xMidYMid meet" version="1.0" aria-hidden="true"><path fill="#f4b120" d="M 217.46875 764.9375 C 209.929688 764.9375 204.402344 762.171875 200.878906 756.648438 C 197.367188 751.136719 196.113281 744.105469 197.121094 735.5625 L 298.066406 17.609375 C 299.0625 10.574219 300.566406 6.308594 302.578125 4.808594 C 304.59375 3.296875 309.109844 2.542969 316.132812 2.542969 L 386.199219 2.542969 C 391.722656 2.542969 396.238281 4.550781 399.75 8.566406 C 403.261719 12.582031 404.519531 16.847656 403.527344 21.367188 L 300.316406 755.914062 C 299.8125 759.925781 298.804688 762.429688 297.292969 763.429688 C 295.792969 764.433594 292.535156 764.9375 287.515625 764.9375 Z M 217.46875 764.9375 " fill-opacity="1" fill-rule="nonzero"/><path fill="#f4b120" d="M 401.449219 764.9375 C 393.910156 764.9375 388.382812 762.171875 384.859375 756.648438 C 381.351562 751.136719 380.097656 744.105469 381.101562 735.5625 L 482.050781 17.609375 C 483.042969 10.574219 484.546875 6.308594 486.5625 4.808594 C 488.574219 3.296875 493.089844 2.542969 500.113281 2.542969 L 570.179688 2.542969 C 575.703125 2.542969 580.21875 4.550781 583.734375 8.566406 C 587.242188 12.582031 588.5 16.847656 587.507812 21.367188 L 484.296875 755.914062 C 483.792969 759.925781 482.785156 762.429688 481.277344 763.429688 C 479.777344 764.433594 476.519531 764.9375 471.5 764.9375 Z M 401.449219 764.9375 " fill-opacity="1" fill-rule="nonzero"/></svg>
                    <span class="page-section-hero-text"><cfoutput>#REQUEST.t('videos.hero.title')#</cfoutput></span>
                </h1>
                <div class="page-section-hero-editorial-info">
                    <div class="page-section-hero-kicker"><cfoutput>#VARIABLES.videosAggregatorLabel#</cfoutput></div>
                    <p class="page-section-hero-copy"><cfoutput>#VARIABLES.videosAggregatorCopy#</cfoutput></p>
                </div>
            </div>
        </div>

        <cfif qVideosChannels.recordCount>
            <div class="videos-channel-select-mobile">
                <select class="videos-channel-select" aria-label="<cfoutput>#REQUEST.t('videos.filters.aria')#</cfoutput>" onchange="if(this.value){ window.location.href = this.value; }">
                    <option value="<cfoutput>#VARIABLES.videosRootUrl#</cfoutput>"<cfif NOT len(trim(URL.canal))> selected</cfif>><cfoutput>#REQUEST.t('videos.filters.allChannels')#</cfoutput></option>
                    <cfloop array="#VARIABLES.canaisVideos#" index="canalItem">
                        <cfoutput><option value="#VARIABLES.videosRootUrl##VARIABLES.videosChannelSegment#/#canalItem.slug#/"<cfif URL.canal EQ canalItem.slug> selected</cfif>>#canalItem.name#</option></cfoutput>
                    </cfloop>
                </select>
            </div>
            <div class="videos-channel-filters">
                <cfoutput><a href="#VARIABLES.videosRootUrl#" class="videos-filter-chip<cfif NOT len(trim(URL.canal))> is-active</cfif>">#REQUEST.t('videos.filters.allChannels')#</a></cfoutput>
                <cfloop array="#VARIABLES.canaisVideos#" index="canalItem">
                    <cfoutput><a href="#VARIABLES.videosRootUrl##VARIABLES.videosChannelSegment#/#canalItem.slug#/" class="videos-filter-chip<cfif URL.canal EQ canalItem.slug> is-active</cfif>">#canalItem.name#</a></cfoutput>
                </cfloop>
            </div>
        </cfif>

        <div class="row gx-3 gy-2">

            <div class="col-12 col-lg-9">
                <div class="videos-shell-card is-list-shell p-3">
                    <div class="d-flex flex-wrap align-items-center gap-2 mb-3">
                        <div>
                            <div class="h5 mb-1"><cfoutput>#REQUEST.t('videos.list.recentVideos')#</cfoutput></div>
                        </div>
                    </div>

                    <cfif arrayLen(VARIABLES.videosPaginados)>
                        <div class="videos-list-grid" id="videos-infinite-list">
                            <cfset VARIABLES.videoListFeaturedFirst = true>
                            <cfset VARIABLES.videoListStartIndex = 0>
                            <cfinclude template="../includes/estrutura/videos_lista_cards.cfm"/>
                        </div>

                        <cfif VARIABLES.totalPaginasVideos GT 1>
                            <cfset VARIABLES.paginacaoVideoInicio = max(1, URL.page - 2)>
                            <cfset VARIABLES.paginacaoVideoFim = min(VARIABLES.totalPaginasVideos, VARIABLES.paginacaoVideoInicio + 4)>
                            <cfif (VARIABLES.paginacaoVideoFim - VARIABLES.paginacaoVideoInicio) LT 4>
                                <cfset VARIABLES.paginacaoVideoInicio = max(1, VARIABLES.paginacaoVideoFim - 4)>
                            </cfif>
                            <div class="d-flex flex-wrap gap-2 justify-content-center mt-4 rr-infinite-pagination" id="videos-pagination">
                                <cfif URL.page GT 1>
                                    <cfoutput><a href="#VARIABLES.baseVideosUrl#<cfif URL.page - 1 GT 1>?page=#URL.page-1#</cfif>" class="videos-pagination-link">#REQUEST.t('videos.pagination.previous')#</a></cfoutput>
                                </cfif>
                                <cfif VARIABLES.paginacaoVideoInicio GT 1>
                                    <cfoutput><a href="#VARIABLES.baseVideosUrl#" class="videos-pagination-link">1</a></cfoutput>
                                    <cfif VARIABLES.paginacaoVideoInicio GT 2>
                                        <span class="videos-pagination-link">...</span>
                                    </cfif>
                                </cfif>
                                <cfloop from="#VARIABLES.paginacaoVideoInicio#" to="#VARIABLES.paginacaoVideoFim#" index="pagina">
                                    <cfoutput><a href="#VARIABLES.baseVideosUrl#<cfif pagina GT 1>?page=#pagina#</cfif>" class="videos-pagination-link<cfif pagina EQ URL.page> is-active</cfif>">#pagina#</a></cfoutput>
                                </cfloop>
                                <cfif VARIABLES.paginacaoVideoFim LT VARIABLES.totalPaginasVideos>
                                    <cfif VARIABLES.paginacaoVideoFim LT (VARIABLES.totalPaginasVideos - 1)>
                                        <span class="videos-pagination-link">...</span>
                                    </cfif>
                                    <cfoutput><a href="#VARIABLES.baseVideosUrl#?page=#VARIABLES.totalPaginasVideos#" class="videos-pagination-link">#VARIABLES.totalPaginasVideos#</a></cfoutput>
                                </cfif>
                                <cfif URL.page LT VARIABLES.totalPaginasVideos>
                                    <cfoutput><a href="#VARIABLES.baseVideosUrl#?page=#URL.page+1#" class="videos-pagination-link">#REQUEST.t('videos.pagination.next')#</a></cfoutput>
                                </cfif>
                            </div>
                        </cfif>
                        <cfif URL.page LT VARIABLES.totalPaginasVideos>
                            <cfoutput>
                                <div class="rr-infinite-scroll-control"
                                    data-rr-infinite-scroll
                                    data-list-target="##videos-infinite-list"
                                    data-pagination-target="##videos-pagination"
                                    data-endpoint="/api/videos_infinite.cfm"
                                    data-current-page="#URL.page#"
                                    data-total-pages="#VARIABLES.totalPaginasVideos#"
                                    data-channel="#HTMLEditFormat(URL.canal)#"
                                    data-i18n-lang="#HTMLEditFormat(REQUEST.lang)#">
                                    <button type="button" class="rr-infinite-load-more" data-rr-infinite-button><cfoutput>#REQUEST.t('videos.list.loadMore')#</cfoutput></button>
                                    <div class="rr-infinite-status" data-rr-infinite-status aria-live="polite"></div>
                                    <div class="rr-infinite-sentinel" data-rr-infinite-sentinel></div>
                                </div>
                            </cfoutput>
                        </cfif>
                    <cfelse>
                        <div class="videos-shell-card p-3" style="background-color:##efefef;">
                            <div class="fw-semibold mb-1">#REQUEST.t('videos.list.emptyTitle')#</div>
                            <div class="small videos-muted">#REQUEST.t('videos.list.emptyText')#</div>
                        </div>
                    </cfif>
                </div>
            </div>

            <div class="d-none d-lg-block col-lg-3 order-3 home-mobile-section">
                <cfinclude template="../includes/estrutura/conteudo_lateral_api.cfm"/>
            </div>

        </div>

        </main>

    </div>

    <cfinclude template="../includes/estrutura/infinite_scroll.cfm"/>

    <cfinclude template="../includes/estrutura/footer.cfm"/>

    <cfinclude template="../includes/modal/modal_badges.cfm"/>
    <cfinclude template="../includes/modal/modal_youtube.cfm"/>
    <cfinclude template="../includes/modal/modal_cupom_foco.cfm"/>
    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>
    <cfinclude template="../includes/modal/modal_login.cfm"/>
    <cfinclude template="../includes/modal/modal_seguidores.cfm"/>
    <cfinclude template="../includes/modal/modal_pagamento.cfm"/>

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>
