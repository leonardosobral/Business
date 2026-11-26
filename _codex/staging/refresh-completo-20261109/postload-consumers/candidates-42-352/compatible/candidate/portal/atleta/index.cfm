<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/atleta/"/>
<cfset VARIABLES.routeKey = "athlete"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>
<cfset VARIABLES.athleteMissingSlugRequest = NOT len(trim(URL.tag))/>
<cfif NOT structKeyExists(REQUEST, "currentRouteParams") OR NOT isStruct(REQUEST.currentRouteParams)>
    <cfset REQUEST.currentRouteParams = {} />
</cfif>
<cfif len(trim(URL.tag))>
    <cfset REQUEST.currentRouteParams["tag"] = trim(URL.tag) />
    <cfset REQUEST.currentRouteKey = "athlete"/>
<cfelse>
    <cfset VARIABLES.routeKey = ""/>
</cfif>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend_perfil_edicao.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/backend_require_login.cfm"/>
<cfif Usuario.logado AND VARIABLES.athleteMissingSlugRequest AND len(trim(Usuario.tag & ""))>
    <cfset URL.tag = trim(Usuario.tag & "")/>
    <cfset REQUEST.currentRouteParams["tag"] = URL.tag />
    <cfset REQUEST.currentRouteKey = "athlete"/>
    <cfset VARIABLES.routeKey = "athlete"/>
    <cflocation addtoken="false" url="#REQUEST.i18nBuildPath('athlete')#"/>
</cfif>
<cfinclude template="../includes/backend/backend_perfil_publico.cfm"/>
<cfset VARIABLES.athleteDisplayName = REQUEST.formatDisplayPersonName(qPagina.nome)/>
<cfset VARIABLES.isOwnAthleteProfile = Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id/>
<cfset VARIABLES.selfDeclaredResultsEnabled = VARIABLES.isOwnAthleteProfile AND qPagina.verificado/>
<cfif VARIABLES.isOwnAthleteProfile>
    <cfif NOT structKeyExists(SESSION, "profileSettingsCsrfToken")
        OR NOT len(trim(SESSION.profileSettingsCsrfToken & ""))
        OR NOT structKeyExists(SESSION, "profileSettingsCsrfUserId")
        OR val(SESSION.profileSettingsCsrfUserId) NEQ val(Usuario.id)>
        <cfset SESSION.profileSettingsCsrfToken = lCase(hash(createUUID() & ":" & createUUID() & ":" & getTickCount(), "SHA-256"))/>
        <cfset SESSION.profileSettingsCsrfUserId = val(Usuario.id)/>
    </cfif>
    <cfset VARIABLES.resultShareImagesCsrfToken = SESSION.profileSettingsCsrfToken/>
    <cfif VARIABLES.selfDeclaredResultsEnabled>
        <cfset VARIABLES.selfDeclaredResultsCsrfToken = SESSION.profileSettingsCsrfToken/>
    </cfif>
</cfif>
<cfset VARIABLES.athleteMessagesPath = REQUEST.i18nBuildPath("messages")/>
<cfset VARIABLES.athleteMessageLabel = REQUEST.t("athlete.actions.message")/>
<cfif NOT len(trim(VARIABLES.athleteMessageLabel)) OR VARIABLES.athleteMessageLabel EQ "athlete.actions.message">
    <cfset VARIABLES.athleteMessageLabel = REQUEST.lang EQ "en" ? "Message" : (REQUEST.lang EQ "es" ? "Mensaje" : "Mensagem")/>
</cfif>
<cfset VARIABLES.athleteMessageError = REQUEST.t("athlete.actions.messageError")/>
<cfif NOT len(trim(VARIABLES.athleteMessageError)) OR VARIABLES.athleteMessageError EQ "athlete.actions.messageError">
    <cfset VARIABLES.athleteMessageError = REQUEST.lang EQ "en" ? "Could not open the conversation. Please try again." : (REQUEST.lang EQ "es" ? "No fue posible abrir la conversación. Inténtalo de nuevo." : "Não foi possível abrir a conversa. Tente novamente.")/>
</cfif>
<cfif URL.filtro EQ "configuracoes">
    <cfif VARIABLES.isOwnAthleteProfile>
        <cflocation addtoken="false" statuscode="302" url="#REQUEST.i18nBuildPath('profileSettings')#"/>
    <cfelse>
        <cflocation addtoken="false" statuscode="302" url="#REQUEST.i18nBuildPath('athlete')#"/>
    </cfif>
</cfif>
<cfset VARIABLES.athleteCanonicalPath = len(trim(URL.tag)) ? REQUEST.i18nBuildPath("athlete") : VARIABLES.template/>
<cfset VARIABLES.athleteTabBasePath = len(trim(URL.tag)) ? REQUEST.i18nBuildPath("athlete") : "./"/>
<cfset VARIABLES.athleteResultsPagePath = REQUEST.i18nBuildPath("results")/>
<cfset VARIABLES.athleteResultsTabPath = "#VARIABLES.athleteTabBasePath#?filtro=resultados"/>
<cfset VARIABLES.athletePhotoActionLabel = VARIABLES.isOwnAthleteProfile ? REQUEST.t("athlete.photo.changeAria") : REQUEST.t("athlete.photo.expandAria")/>
<cfset VARIABLES.athleteImageAlt = REQUEST.t("athlete.photo.imageAlt", { "name" = VARIABLES.athleteDisplayName })/>
<cfset VARIABLES.athleteLocationRegion = len(trim(qPagina.usuario_pais ?: "")) AND trim(qPagina.usuario_pais) NEQ "BR" ? trim(qPagina.usuario_estado ?: "") : trim(qPagina.uf ?: "")/>
<cfset VARIABLES.athleteLocationCountry = len(trim(qPagina.usuario_pais ?: "")) AND trim(qPagina.usuario_pais) NEQ "BR" ? trim(qPagina.usuario_pais) : ""/>
<cfset VARIABLES.athleteLocationSuffix = ""/>
<cfif len(trim(VARIABLES.athleteLocationRegion))>
    <cfset VARIABLES.athleteLocationSuffix = VARIABLES.athleteLocationRegion/>
    <cfif len(trim(VARIABLES.athleteLocationCountry))>
        <cfset VARIABLES.athleteLocationSuffix &= " - " & VARIABLES.athleteLocationCountry/>
    </cfif>
<cfelseif len(trim(VARIABLES.athleteLocationCountry))>
    <cfset VARIABLES.athleteLocationSuffix = VARIABLES.athleteLocationCountry/>
</cfif>
<cfset VARIABLES.athleteResultsLabel = REQUEST.t("athlete.stats.results")/>
<cfset VARIABLES.athleteFollowersLabel = REQUEST.t("athlete.stats.followers")/>
<cfset VARIABLES.athleteFollowingLabel = REQUEST.t("athlete.stats.following")/>
<cfset VARIABLES.athleteActivitiesLabel = REQUEST.t("athlete.tabs.activities")/>
<cfset VARIABLES.athleteAgendaLabel = REQUEST.t("athlete.tabs.agenda")/>
<cfset VARIABLES.athleteAchievementsLabel = REQUEST.t("athlete.tabs.achievements")/>
<cfset VARIABLES.athleteChallengesLabel = REQUEST.t("athlete.tabs.challenges")/>
<cfset VARIABLES.appsMenuCatalog = REQUEST.i18n.common.appsMenu />
<cfset VARIABLES.activitySidebarCatalog = REQUEST.i18n.common.activitySidebar />
<cfinclude template="../includes/backend/backend_feed.cfm"/>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#REQUEST.currentBaseUrl##VARIABLES.athleteCanonicalPath##VARIABLES.queryString#"/>
<cfset VARIABLES.title = REQUEST.t("athlete.meta.title", { "name" = VARIABLES.athleteDisplayName }) & " - " & APPLICATION.nomeSite/>
<cfset VARIABLES.description = REQUEST.t("athlete.meta.description", { "name" = VARIABLES.athleteDisplayName })/>
<cfset VARIABLES.keywords = REQUEST.t("athlete.meta.keywords")/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>
<cfif Usuario.logado><link rel="stylesheet" href="/assets/css/runnerhub-event-chat-share.css?v=3"/></cfif>
<cfif VARIABLES.isOwnAthleteProfile><link rel="stylesheet" href="/assets/css/runnerhub-self-declared-results.css?v=5"/></cfif>
<cfif VARIABLES.isOwnAthleteProfile><link rel="stylesheet" href="/assets/css/runnerhub-result-share-images.css?v=1"/></cfif>

<style>
    .sticky-offset {
        top: 56px;
    }
    .overlay {
        _opacity: 0;
        width: 180px;
        height: 180px;
        transition: .5s ease;
        opacity: 0;
        position: absolute;
        margin-left: -185px;
        margin-top: 10px;
    }
    .avatar:hover .overlay {
        opacity: 0.75;
    }
    .avatar:hover .photo {
        opacity: 0.75;
        transition: .5s ease;
    }

    .athlete-profile-card {
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 10px;
        background-color: #ffffff;
        overflow: hidden;
    }

    .athlete-profile-head {
        display: grid;
        grid-template-columns: 100px minmax(0, 1fr);
        gap: 1rem;
        padding: 1rem;
        background-color: #efefef;
        border-bottom: 1px solid rgba(51, 51, 51, 0.08);
    }

    .athlete-profile-media {
        display: grid;
        gap: 0.75rem;
        align-content: start;
        width: 100px;
    }

    .athlete-profile-avatar-link {
        display: block;
        width: 100px;
        height: 100px;
        border-radius: 999px;
        position: relative;
        overflow: hidden;
    }

    .athlete-profile-avatar-link.is-own-profile {
        cursor: pointer;
    }

    .athlete-profile-avatar-link.is-own-profile:hover .athlete-profile-avatar-overlay,
    .athlete-profile-avatar-link.is-own-profile:focus-visible .athlete-profile-avatar-overlay {
        opacity: 1;
    }

    .athlete-profile-avatar {
        width: 100px;
        height: 100px;
        border-radius: 999px;
        object-fit: cover;
        background-color: #ffffff;
        border: 1px solid rgba(51, 51, 51, 0.12);
    }

    .athlete-profile-avatar-overlay {
        position: absolute;
        inset: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 999px;
        background: linear-gradient(180deg, rgba(15, 23, 42, 0.14) 0%, rgba(15, 23, 42, 0.72) 100%);
        color: #ffffff;
        font-size: 1rem;
        opacity: 0;
        transition: opacity 0.2s ease;
    }

    .athlete-profile-name {
        color: #333333;
        font-size: 1.35rem;
        font-weight: 700;
        line-height: 1.1;
        margin: 0;
    }

    .athlete-profile-title {
        display: flex;
        align-items: center;
        gap: 0.4rem;
        flex-wrap: wrap;
        margin-bottom: 0.45rem;
    }

    .athlete-profile-location {
        color: rgba(51, 51, 51, 0.76);
        font-size: 0.88rem;
        line-height: 1.3;
        margin-bottom: 0.5rem;
    }

    .athlete-profile-location i,
    .athlete-profile-bio i {
        color: #fab120;
        width: 14px;
    }

    .athlete-profile-bio {
        color: rgba(51, 51, 51, 0.84);
        font-size: 0.9rem;
        line-height: 1.45;
        margin-bottom: 0;
    }

    .athlete-profile-main {
        min-width: 0;
        display: grid;
        grid-template-columns: minmax(0, 1fr) auto;
        gap: 1rem;
        align-items: start;
    }

    .athlete-profile-copy {
        min-width: 0;
    }

    .athlete-profile-side {
        display: grid;
        justify-items: end;
        align-content: end;
        align-self: end;
    }

    .athlete-profile-social {
        display: flex;
        flex-wrap: wrap;
        gap: 0.45rem;
    }

    .athlete-profile-social a {
        width: 34px;
        height: 34px;
        border-radius: 999px;
        border: 1px solid rgba(51, 51, 51, 0.1);
        background-color: #ffffff;
        color: #333333;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
    }

    .athlete-profile-social a:hover {
        border-color: rgba(250, 177, 32, 0.9);
        color: #333333;
    }

    .athlete-profile-social-go-runners-icon {
        display: block;
        width: 19px;
        height: 19px;
        background-color: currentColor;
        -webkit-mask: url('/assets/go-runners-social.svg') center / contain no-repeat;
        mask: url('/assets/go-runners-social.svg') center / contain no-repeat;
    }

    .athlete-profile-message-button {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.4rem;
        margin-top: 0.55rem;
        min-height: 34px;
        padding: 0.35rem 0.75rem;
        border: 1px solid rgba(51, 51, 51, 0.1);
        border-radius: 999px;
        background-color: #ffffff;
        color: #333333;
        font-size: 0.8rem;
        font-weight: 500;
        box-shadow: none !important;
    }

    .athlete-profile-message-button:hover,
    .athlete-profile-message-button:focus,
    .athlete-profile-message-button:active {
        border-color: rgba(51, 51, 51, 0.28);
        background-color: #ffffff;
        color: #333333;
        box-shadow: none !important;
    }

    .athlete-profile-cta {
        display: grid;
        gap: 0.35rem;
        justify-content: stretch;
    }

    .athlete-profile-cta .btn,
    .athlete-profile-cta a {
        box-shadow: none;
    }

    .athlete-profile-cta .btn,
    .athlete-profile-cta a,
    .athlete-profile-cta .flex-fill {
        width: 100%;
    }

    .athlete-profile-cta .btn {
        padding-left: 0.65rem;
        padding-right: 0.65rem;
    }

    .athlete-profile-cta .flex-fill {
        flex: 0 0 auto !important;
    }

    .athlete-profile-mutual-chip {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.28rem;
        width: 100%;
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 999px;
        background-color: #efefef;
        color: rgba(51, 51, 51, 0.72);
        font-size: 0.68rem;
        font-weight: 800;
        line-height: 1;
        padding: 0.35rem 0.48rem;
        white-space: nowrap;
    }

    .athlete-profile-mutual-chip i {
        color: #fab120;
    }

    .athlete-profile-body {
        padding: 0.8rem 0.9rem 0.9rem;
    }

    .athlete-profile-stats {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 0;
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 8px;
        background-color: rgba(239, 239, 239, 0.65);
        overflow: hidden;
    }

    .athlete-profile-stat {
        min-width: 0;
        border: 0;
        border-radius: 0;
        background-color: transparent;
        color: #333333;
        text-align: center;
        box-shadow: none;
        padding: 0.65rem 0.25rem !important;
    }

    .athlete-profile-stat:not(:last-child) {
        border-right: 1px solid rgba(51, 51, 51, 0.08);
    }

    .athlete-profile-stat:hover,
    .athlete-profile-stat:focus {
        background-color: rgba(255, 255, 255, 0.72);
    }

    .athlete-profile-stat .value {
        display: block;
        font-size: 1.02rem;
        font-weight: 700;
        line-height: 1.1;
        margin-bottom: 0.12rem;
    }

    .athlete-profile-stat .label {
        display: block;
        font-size: 0.64rem;
        line-height: 1.2;
        letter-spacing: 0.04em;
        text-transform: uppercase;
    }

    .athlete-profile-actions .btn,
    .athlete-profile-stat {
        box-shadow: none;
    }

    .athlete-tabs-shell {
        margin: 0.55rem 0 0.75rem;
        padding-inline: 0;
    }

    .athlete-tabs {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 0.4rem;
        min-width: 100%;
        border-bottom: 0;
        margin-bottom: 0;
        padding-left: 0;
    }

    .athlete-tabs .nav-item {
        min-width: 0;
    }

    .athlete-tabs .nav-link {
        height: 100%;
        border: 1px solid rgba(51, 51, 51, 0.08) !important;
        border-radius: 8px !important;
        background-color: #efefef;
        color: #333333;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        min-height: 58px;
        padding: 0.65rem 0.4rem !important;
        text-align: center;
        transition: background-color 0.2s ease, border-color 0.2s ease, color 0.2s ease;
    }

    .athlete-tabs .nav-link i {
        color: #fab120;
        font-size: 1.2rem !important;
    }

    .athlete-tabs .nav-link.active,
    .athlete-tabs .nav-link:hover,
    .athlete-tabs .nav-link:focus {
        background-color: #ffffff;
        border-color: rgba(250, 177, 32, 0.9) !important;
        color: #333333;
    }

    .athlete-tabs .nav-link.active {
        box-shadow: inset 0 0 0 1px rgba(250, 177, 32, 0.45);
    }

    .athlete-tabs .nav-link.active i {
        color: #333333;
    }

    @media (max-width: 767.98px) {
        .athlete-profile-head {
            grid-template-columns: 100px minmax(0, 1fr);
            gap: 0.85rem;
            padding: 0.9rem;
        }

        .athlete-profile-media {
            width: 100px;
        }

        .athlete-profile-avatar-link,
        .athlete-profile-avatar {
            width: 100px;
            height: 100px;
        }

        .athlete-profile-avatar-overlay {
            opacity: 1;
            font-size: 0.92rem;
        }

        .athlete-profile-name {
            font-size: 1.15rem;
        }

        .athlete-profile-main {
            grid-template-columns: 1fr;
            gap: 0.7rem;
        }

        .athlete-profile-side {
            justify-items: end;
        }

        .athlete-profile-stats {
            border-radius: 7px;
        }

        .athlete-profile-stat {
            padding: 0.55rem 0.18rem !important;
        }

        .athlete-profile-stat .value {
            font-size: 0.96rem;
        }

        .athlete-profile-stat .label {
            font-size: 0.58rem;
        }

        .athlete-tabs-shell {
            margin-top: 0.5rem;
        }

        .athlete-tabs {
            grid-template-columns: repeat(5, minmax(0, 1fr));
            gap: 0.32rem;
        }

        .athlete-tabs .nav-link {
            min-height: 52px;
            padding: 0.55rem 0.25rem !important;
        }

        .athlete-tabs .nav-link i {
            font-size: 1.05rem !important;
        }
    }
</style>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>


    <!--- CONTAINER DE CONTEUDO --->

    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <!--- CONTEUDO --->

        <div class="row g-2">

            <!--- MINI PERFIL --->

            <div class="col-12 col-md-4 col-lg-3 col-xl-3 d-none d-md-block">

                <cfinclude template="../includes/estrutura/home_sidebar_async_slot.cfm"/>

            </div>

            <!--- PERFIL --->

            <div class="col-12 col-md-8 col-lg-6 col-xl-6 px-lg-3">


                <!--- HEADER DA PAGINA --->

                <!---<div class="row">

                    <div class="col-3 col-md-2 col-lg-3 col-xl-2">
                    </div>

                    <div class="col-9 col-md-7 col-lg-6 col-xl-7 pe-0">
                        <div class="h5 ps-1 mb-0 lh-1"><cfoutput><span class="text-truncate d-inline-block" style="max-width: calc(100% - 30px)">#qPagina.nome#</span></cfoutput>
                            <cfif qPagina.verificado>
                                <img src="/assets/verified.png" data-mdb-acao="selo_verificado" class="align-top" alt="<cfoutput>#REQUEST.t('athlete.photo.verifiedAlt')#</cfoutput>" title="<cfoutput>#REQUEST.t('athlete.photo.verifiedTitle')#</cfoutput>"/>
                            <cfelseif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id>
                                <img src="/assets/verified_not.png" class="align-top" style="cursor: pointer" title="<cfoutput>#REQUEST.t('athlete.photo.verifyTitle')#</cfoutput>"/>
                            </cfif>
                        </div>
                        <div class="small ps-1"><cfif len(trim(qPagina.cidade))><i class="fa-solid fa-location-dot"></i>&nbsp;<cfoutput>#qPagina.cidade#<cfif len(trim(VARIABLES.athleteLocationSuffix))> - #VARIABLES.athleteLocationSuffix#</cfif></cfoutput></cfif>&nbsp;</div>
                            <div class="d-none d-md-flex ps-1 pb-2 small" style="max-height: 20px; min-height: 20px; line-height: 1rem; overflow:hidden"><cfif len(trim(qPagina.descricao))><cfoutput>#qPagina.descricao#</cfoutput></cfif>&nbsp;</div>
                    </div>

                    <div class="col-3 d-none d-md-block">

                        <cfif Usuario.logado>
                            <div class="justify-content-end d-flex flex-fill h-50 pb-2"><cfinclude template="parts/botao_seguir.cfm"/></div>
                        <cfelse>
                            <div class="justify-content-end d-flex flex-fill">
                                <button class="btn btn-sm shadow-0 btn-primary" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"><cfoutput>#REQUEST.t('athlete.actions.follow')#</cfoutput></button>
                            </div>
                        </cfif>

                        <div class="text-end d-none d-md-block">
                        <cfif qPagina.perfil_publico OR qCheckSeguindo.recordcount>
                            <cfif len(trim(qPagina.strava_id)) AND Usuario.logado>
                                <a style="color: #666;" href="https://www.strava.com/athletes/<cfoutput>#qPagina.strava_id#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-strava fa-lg px-1"></i></a>
                            </cfif>
                            <cfif len(trim(qPagina.instagram)) AND qPagina.instagram_publico AND Usuario.logado>
                                <a style="color: #666;" href="https://instagram.com/<cfoutput>#qPagina.instagram#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-instagram fa-lg px-1"></i></a>
                            </cfif>
                            <cfif len(trim(qPagina.youtube)) AND qPagina.youtube_publico AND Usuario.logado>
                                <a style="color: #666;" href="https://youtube.com/<cfoutput>#qPagina.youtube#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-youtube fa-lg px-1"></i></a>
                            </cfif>
                            <cfif len(trim(qPagina.tiktok)) AND qPagina.tiktok_publico AND Usuario.logado>
                                <a style="color: #666;" href="https://tiktok.com/<cfoutput>#qPagina.youtube#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-tiktok fa-lg px-1"></i></a>
                            </cfif>
                            <cfif len(trim(qPagina.website)) AND qPagina.website_publico AND Usuario.logado>
                                <a style="color: #666;" href="<cfoutput>#qPagina.website#</cfoutput>" role="button" target="_blank"><i class="fa-solid fa-globe fa-lg px-1"></i></a>
                            </cfif>
                            <cfif len(trim(qPagina.whatsapp)) AND qPagina.whatsapp_publico AND Usuario.logado>
                                <a style="color: #666;" href="https://wa.me/<cfoutput>#qPagina.whatsapp#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-whatsapp fa-lg px-1"></i></a>
                            </cfif>
                        </cfif>
                        </div>

                    </div>

                </div>--->


                <!--- CONTEUDO DA PAGINA --->

                <div class="row m-auto">


                    <!--- BARRA DE BOTOES EDITAR/SEGUIR --->

                    <!---<div class="card pb-1 mb-2 pt-md-2">

                        <div class="row">

                                <div class="col-3 col-md-2 col-lg-3 col-xl-2 ps-2 pe-0">
                                    <cfif qPagina.recordCount>
                                        <cfoutput>
                                                <img src="#qPagina.imagem_usuario#" class="d-block d-md-none rounded-circle bg-light w-100 position-relative" style="margin-top:-50px;border: 5px solid rgba(235, 235, 235, 1);" alt="imagem do atleta" onerror="this.src='/assets/user.png';"/>
                                                <img src="#qPagina.imagem_usuario#" class="d-none d-md-block d-lg-none rounded-circle bg-light w-100 position-relative" style="margin-top:-80px;border: 5px solid rgba(235, 235, 235, 1);" alt="imagem do atleta" onerror="this.src='/assets/user.png';"/>
                                                <img src="#qPagina.imagem_usuario#" class="d-none d-lg-block rounded-circle bg-light w-100 position-relative" style="margin-top:-80px;border: 5px solid rgba(235, 235, 235, 1);" alt="imagem do atleta" onerror="this.src='/assets/user.png';"/>
                                        </cfoutput>
                                    </cfif>
                                </div>
                                <div class="col-9 d-md-none">
                                    <span class="d-block small"><cfoutput>#qPagina.descricao#</cfoutput></span>
                                    <cfif len(trim(qPagina.strava_id))>
                                            <a style="color: #666;" href="https://www.strava.com/athletes/<cfoutput>#qPagina.strava_id#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-strava fa-lg px-1"></i></a>
                                    </cfif>
                                    <cfif len(trim(qPagina.instagram))>
                                            <a style="color: #666;" href="https://instagram.com/<cfoutput>#qPagina.instagram#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-instagram fa-lg px-1"></i></a>
                                    </cfif>
                                    <cfif len(trim(qPagina.youtube))>
                                            <a style="color: #666;" href="https://youtube.com/<cfoutput>#qPagina.youtube#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-youtube fa-lg px-1"></i></a>
                                    </cfif>
                                    <cfif len(trim(qPagina.tiktok))>
                                            <a style="color: #666;" href="https://tiktok.com/<cfoutput>#qPagina.youtube#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-tiktok fa-lg px-1"></i></a>
                                    </cfif>
                                    <cfif len(trim(qPagina.website))>
                                            <a style="color: #666;" href="<cfoutput>#qPagina.website#</cfoutput>" role="button" target="_blank"><i class="fa-solid fa-globe fa-lg px-1"></i></a>
                                    </cfif>
                                    <cfif len(trim(qPagina.whatsapp))>
                                        <cfif qPagina.whatsapp_publico>
                                                <a style="color: #666;" href="https://wa.me/<cfoutput>#qPagina.whatsapp#</cfoutput>" role="button" target="_blank"><i class="fa-brands fa-whatsapp fa-lg px-1"></i></a>
                                        </cfif>
                                    </cfif>
                                </div>

                                <div class="pt-1 px-1 d-flex d-md-none justify-content-center">
                                    <cfinclude template="parts/botao_seguir.cfm"/>
                                </div>

                                <div class="col-12 col-md-10 col-lg-9 col-xl-10 pt-1 px-1 fs-4 small justify-content-center justify-content-md-start d-flex d-md-block gap-1">
                                    <cfif Usuario.logado>
                                        <cfif qPagina.perfil_publico OR qCheckSeguindo.recordcount>
                                            <cfif qPagina.id_usuario_cadastro EQ Usuario.id>
                                                <button class="btn btn-sm btn-secondary flex-fill px-1" onclick="window.location.href='<cfoutput>#JSStringFormat(VARIABLES.athleteResultsPagePath)#</cfoutput>';"><cfoutput>#qCorridasAtleta.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteResultsLabel#</cfoutput></button>
                                            <cfelse>
                                                <button class="btn btn-sm btn-secondary flex-fill px-1" onclick="document.getElementById('tab-resultados').click();window.location.href='<cfoutput>#JSStringFormat(VARIABLES.athleteResultsTabPath)#</cfoutput>';return false;"><cfoutput>#qCorridasAtleta.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteResultsLabel#</cfoutput></button>
                                            </cfif>
                                            <button class="btn btn-sm btn-secondary flex-fill px-1"
                                                    data-mdb-ripple-init
                                                    data-mdb-modal-init
                                                    data-mdb-target="#modal_seguidores"
                                                    data-mdb-tipo="<cfoutput>#VARIABLES.athleteFollowersLabel#</cfoutput>"
                                                    data-mdb-countseguindo="<cfoutput>#qSeguidores.recordcount#</cfoutput>"
                                                    data-mdb-countseguidores="<cfoutput>#qSeguindo.recordcount#</cfoutput>"
                                                    data-mdb-escopo="pagina"><cfoutput>#qSeguidores.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteFollowersLabel#</cfoutput></button>
                                            <button class="btn btn-sm btn-secondary flex-fill px-1"
                                                    data-mdb-ripple-init
                                                    data-mdb-modal-init
                                                    data-mdb-target="#modal_seguidores"
                                                    data-mdb-tipo="<cfoutput>#VARIABLES.athleteFollowingLabel#</cfoutput>"
                                                    data-mdb-countseguindo="<cfoutput>#qSeguidores.recordcount#</cfoutput>"
                                                    data-mdb-countseguidores="<cfoutput>#qSeguindo.recordcount#</cfoutput>"
                                                    data-mdb-escopo="pagina"><cfoutput>#qSeguindo.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteFollowingLabel#</cfoutput></button>
                                        <cfelse>
                                            <button class="btn btn-sm btn-secondary flex-fill px-1"><cfoutput>#qCorridasAtleta.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteResultsLabel#</cfoutput></button>
                                            <button class="btn btn-sm btn-secondary flex-fill px-1"><cfoutput>#qSeguidores.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteFollowersLabel#</cfoutput></button>
                                            <button class="btn btn-sm btn-secondary flex-fill px-1"><cfoutput>#qSeguindo.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteFollowingLabel#</cfoutput></button>
                                        </cfif>
                                    <cfelse>
                                        <button class="btn btn-sm btn-secondary flex-fill px-1" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"><cfoutput>#qCorridasAtleta.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteResultsLabel#</cfoutput></button>
                                        <button class="btn btn-sm btn-secondary flex-fill px-1" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"><cfoutput>#qSeguidores.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteFollowersLabel#</cfoutput></button>
                                        <button class="btn btn-sm btn-secondary flex-fill px-1" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"><cfoutput>#qSeguindo.recordcount#</cfoutput> <cfoutput>#VARIABLES.athleteFollowingLabel#</cfoutput></button>
                                    </cfif>
                                </div>

                        </div>

                    </div>--->

                    <div class="p-0">

                        <div class="athlete-profile-card mb-2">
                            <div class="athlete-profile-head">
                                <div class="athlete-profile-media">
                                    <cfoutput>
                                        <a href="##" class="athlete-profile-avatar-link<cfif VARIABLES.isOwnAthleteProfile> is-own-profile</cfif>" data-mdb-modal-init data-mdb-target="##modalProfilePhoto" aria-label="#VARIABLES.athletePhotoActionLabel#">
                                            <img src="#qPagina.imagem_usuario#" class="athlete-profile-avatar" alt="#VARIABLES.athleteImageAlt#" onerror="this.src='/assets/user.png';"/>
                                            <cfif VARIABLES.isOwnAthleteProfile>
                                                <span class="athlete-profile-avatar-overlay">
                                                    <i class="fa-solid fa-camera"></i>
                                                </span>
                                            </cfif>
                                        </a>
                                    </cfoutput>

                                    <div class="athlete-profile-cta">
                                        <cfif Usuario.logado>
                                            <cfinclude template="parts/botao_seguir.cfm"/>
                                            <cfif qPagina.id_usuario_cadastro NEQ Usuario.id AND isDefined("qPerfilContatosEmComum") AND qPerfilContatosEmComum.recordCount AND val(qPerfilContatosEmComum.total) GT 0>
                                                <cfoutput>
                                                    <span class="athlete-profile-mutual-chip">
                                                        <i class="fa-solid fa-user"></i>
                                                        #qPerfilContatosEmComum.total# em comum
                                                    </span>
                                                </cfoutput>
                                            </cfif>
                                        <cfelse>
                                            <button type="button"
                                                    aria-label="<cfoutput>#REQUEST.t('athlete.actions.follow')#</cfoutput>"
                                                    class="btn btn-sm shadow-0 btn-primary"
                                                    data-mdb-modal-init
                                                    data-mdb-target="#modalLogin"
                                                    data-mdb-acao="perfil">
                                                <cfoutput>#REQUEST.t("athlete.actions.follow")#</cfoutput>
                                            </button>
                                        </cfif>
                                    </div>
                                </div>

                                <div class="athlete-profile-main">
                                    <div class="athlete-profile-copy">
                                        <div class="athlete-profile-title">
                                            <cfoutput><h1 class="athlete-profile-name text-truncate">#VARIABLES.athleteDisplayName#</h1></cfoutput>
                                            <cfif qPagina.verificado OR qPagina.usuario_is_admin>
                                                <cfset VARIABLES.verificadoBadgeIsAdmin = qPagina.usuario_is_admin/>
                                                <span class="d-inline-flex align-items-center"><cfinclude template="../includes/verificado.cfm"/></span>
                                            </cfif>
                                        </div>

                                        <cfif len(trim(qPagina.cidade))>
                                            <div class="athlete-profile-location">
                                                <i class="fa-solid fa-location-dot"></i>
                                                <cfoutput>#qPagina.cidade#<cfif len(trim(VARIABLES.athleteLocationSuffix))> - #VARIABLES.athleteLocationSuffix#</cfif></cfoutput>
                                            </div>
                                        </cfif>

                                        <cfif len(trim(qPagina.descricao))>
                                            <div class="athlete-profile-bio">
                                                <i class="fa-solid fa-asterisk"></i>
                                                <cfoutput>#qPagina.descricao#</cfoutput>
                                            </div>
                                        </cfif>
                                    </div>

                                    <div class="athlete-profile-side">
                                        <cfif qPagina.perfil_publico OR ( isDefined("qCheckSeguindo") AND qCheckSeguindo.recordcount ) OR ( Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id )>
                                            <div class="athlete-profile-social">
                                                <cfif Usuario.logado AND Usuario.is_admin AND qPagina.verificado AND len(trim(qPagina.tag))>
                                                    <a href="https://perfil.run/<cfoutput>#encodeForURL(lCase(trim(qPagina.tag)))#</cfoutput>/"
                                                       role="button"
                                                       target="_blank"
                                                       rel="noopener noreferrer"
                                                       title="Perfil.run"
                                                       aria-label="Perfil.run">
                                                        <i class="bi bi-patch-check rr-perfil-run-icon" aria-hidden="true"></i>
                                                    </a>
                                                </cfif>
                                                <cfif isDefined("VARIABLES.goRunnersProfileLinked") AND VARIABLES.goRunnersProfileLinked AND len(trim(qPagina.tag))>
                                                    <a href="https://gorunners.roadrunners.run/profile/<cfoutput>#encodeForURL(lCase(trim(qPagina.tag)))#</cfoutput>"
                                                       role="button"
                                                       target="_blank"
                                                       rel="noopener noreferrer"
                                                       title="Go Runners"
                                                       aria-label="Go Runners">
                                                        <span class="athlete-profile-social-go-runners-icon" aria-hidden="true"></span>
                                                    </a>
                                                </cfif>
                                                <cfif qPagina.strava_connected AND qPagina.strava_publico>
                                                    <a href="https://www.strava.com/athletes/<cfoutput>#qPagina.strava_id#</cfoutput>" role="button" target="_blank" rel="noopener noreferrer" title="<cfoutput>#REQUEST.t('athlete.social.strava')#</cfoutput>"><i class="fa-brands fa-strava"></i></a>
                                                </cfif>
                                                <cfif len(trim(qPagina.instagram)) AND qPagina.instagram_publico>
                                                    <a href="https://instagram.com/<cfoutput>#qPagina.instagram#</cfoutput>" role="button" target="_blank" rel="noopener noreferrer" title="<cfoutput>#REQUEST.t('athlete.social.instagram')#</cfoutput>"><i class="fa-brands fa-instagram"></i></a>
                                                </cfif>
                                                <cfif len(trim(qPagina.youtube)) AND qPagina.youtube_publico>
                                                    <a href="https://youtube.com/<cfoutput>#qPagina.youtube#</cfoutput>" role="button" target="_blank" rel="noopener noreferrer" title="<cfoutput>#REQUEST.t('athlete.social.youtube')#</cfoutput>"><i class="fa-brands fa-youtube"></i></a>
                                                </cfif>
                                                <cfif len(trim(qPagina.tiktok)) AND qPagina.tiktok_publico>
                                                    <a href="https://tiktok.com/<cfoutput>#qPagina.tiktok#</cfoutput>" role="button" target="_blank" rel="noopener noreferrer" title="<cfoutput>#REQUEST.t('athlete.social.tiktok')#</cfoutput>"><i class="fa-brands fa-tiktok"></i></a>
                                                </cfif>
                                                <cfif len(trim(qPagina.website)) AND qPagina.website_publico>
                                                    <a href="<cfoutput>#qPagina.website#</cfoutput>" role="button" target="_blank" rel="noopener noreferrer" title="<cfoutput>#REQUEST.t('athlete.social.website')#</cfoutput>"><i class="fa-solid fa-globe"></i></a>
                                                </cfif>
                                                <cfif len(trim(qPagina.loja)) AND qPagina.loja_publico>
                                                    <a href="<cfoutput>#qPagina.loja#</cfoutput>" role="button" target="_blank" rel="noopener noreferrer" title="<cfoutput>#REQUEST.t('athlete.settings.onlineStore')#</cfoutput>"><i class="fa-solid fa-bag-shopping"></i></a>
                                                </cfif>
                                                <cfif len(trim(qPagina.whatsapp)) AND qPagina.whatsapp_publico>
                                                    <a href="https://wa.me/<cfoutput>#qPagina.whatsapp#</cfoutput>" role="button" target="_blank" rel="noopener noreferrer" title="<cfoutput>#REQUEST.t('athlete.social.whatsapp')#</cfoutput>"><i class="fa-brands fa-whatsapp"></i></a>
                                                </cfif>
                                            </div>
                                        </cfif>
                                        <cfif Usuario.logado AND val(qPagina.id_usuario) GT 0 AND val(qPagina.id_usuario) NEQ val(Usuario.id)>
                                            <button type="button"
                                                    class="athlete-profile-message-button"
                                                    data-athlete-direct-message
                                                    data-recipient-id="<cfoutput>#val(qPagina.id_usuario)#</cfoutput>"
                                                    data-messages-path="<cfoutput>#encodeForHtmlAttribute(VARIABLES.athleteMessagesPath)#</cfoutput>"
                                                    data-error-message="<cfoutput>#encodeForHtmlAttribute(VARIABLES.athleteMessageError)#</cfoutput>">
                                                <i class="fa-regular fa-message" aria-hidden="true"></i>
                                                <span><cfoutput>#encodeForHtml(VARIABLES.athleteMessageLabel)#</cfoutput></span>
                                            </button>
                                        </cfif>
                                    </div>
                                </div>
                            </div>

                            <div class="athlete-profile-body">
                                <div class="athlete-profile-stats">
                                    <button class="btn btn-sm athlete-profile-stat" onclick="document.getElementById('tab-resultados').click();">
                                        <span class="value"><cfoutput>#qCorridasAtleta.recordcount#</cfoutput></span>
                                        <span class="label"><cfoutput>#VARIABLES.athleteResultsLabel#</cfoutput></span>
                                    </button>

                                    <cfif Usuario.logado>
                                        <button data-mdb-modal-init
                                                data-mdb-target="#modal_seguidores"
                                                data-mdb-tipo="<cfoutput>#VARIABLES.athleteFollowersLabel#</cfoutput>"
                                                data-mdb-countseguindo="<cfoutput>#qSeguidores.recordcount#</cfoutput>"
                                                data-mdb-countseguidores="<cfoutput>#qSeguindo.recordcount#</cfoutput>"
                                                data-mdb-escopo="pagina"
                                                class="btn btn-sm athlete-profile-stat">
                                            <span class="value"><cfoutput>#qSeguidores.recordcount#</cfoutput></span>
                                            <span class="label"><cfoutput>#VARIABLES.athleteFollowersLabel#</cfoutput></span>
                                        </button>

                                        <button data-mdb-modal-init
                                                data-mdb-target="#modal_seguidores"
                                                data-mdb-tipo="<cfoutput>#VARIABLES.athleteFollowingLabel#</cfoutput>"
                                                data-mdb-countseguindo="<cfoutput>#qSeguidores.recordcount#</cfoutput>"
                                                data-mdb-countseguidores="<cfoutput>#qSeguindo.recordcount#</cfoutput>"
                                                data-mdb-escopo="pagina"
                                                class="btn btn-sm athlete-profile-stat">
                                            <span class="value"><cfoutput>#qSeguindo.recordcount#</cfoutput></span>
                                            <span class="label"><cfoutput>#VARIABLES.athleteFollowingLabel#</cfoutput></span>
                                        </button>
                                    <cfelse>
                                        <button data-mdb-modal-init
                                                data-mdb-target="#modalLogin"
                                                data-mdb-acao="perfil"
                                                class="btn btn-sm athlete-profile-stat">
                                            <span class="value"><cfoutput>#qSeguidores.recordcount#</cfoutput></span>
                                            <span class="label"><cfoutput>#VARIABLES.athleteFollowersLabel#</cfoutput></span>
                                        </button>

                                        <button data-mdb-modal-init
                                                data-mdb-target="#modalLogin"
                                                data-mdb-acao="perfil"
                                                class="btn btn-sm athlete-profile-stat">
                                            <span class="value"><cfoutput>#qSeguindo.recordcount#</cfoutput></span>
                                            <span class="label"><cfoutput>#VARIABLES.athleteFollowingLabel#</cfoutput></span>
                                        </button>
                                    </cfif>
                                </div>
                            </div>
                        </div>

                    </div>

                    <!--- ABAS DE CONTEUDO --->

                    <cfif qPagina.perfil_publico OR ( isDefined("qCheckSeguindo") AND qCheckSeguindo.recordcount ) OR ( Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id )>


                        <!--- ABAS DO PERFIL --->

                        <div class="athlete-tabs-shell">
                        <ul class="nav nav-tabs athlete-tabs" id="ex1" role="tablist">

                            <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init class="nav-link p-1 <cfif URL.filtro EQ "">active</cfif>" id="tab-atividades" href="#tabs-atividades"
                                   role="tab" aria-controls="tabs-atividades" aria-selected="true" aria-label="<cfoutput>#VARIABLES.athleteActivitiesLabel#</cfoutput>" title="<cfoutput>#VARIABLES.athleteActivitiesLabel#</cfoutput>" onclick="window.history.pushState('Object', '<cfoutput>#VARIABLES.athleteActivitiesLabel#</cfoutput>', '<cfoutput>#VARIABLES.athleteTabBasePath#</cfoutput>');">
                                    <i class="fa-solid fa-list fs-2"></i>
                                </a>
                            </li>

                            <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init class="nav-link p-1 <cfif URL.filtro EQ "agenda">active</cfif>" id="tab-agenda" href="#tabs-agenda"
                                   role="tab" aria-controls="tabs-agenda" aria-selected="false" aria-label="<cfoutput>#VARIABLES.athleteAgendaLabel#</cfoutput>" title="<cfoutput>#VARIABLES.athleteAgendaLabel#</cfoutput>" onclick="window.history.pushState('Object', '<cfoutput>#VARIABLES.athleteAgendaLabel#</cfoutput>', '<cfoutput>#VARIABLES.athleteTabBasePath#?filtro=agenda</cfoutput>');">
                                    <i class="fa-solid fa-calendar fs-2"></i>
                                </a>
                            </li>

                            <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init class="nav-link p-1 <cfif URL.filtro EQ "resultados">active</cfif>" id="tab-resultados" href="#tabs-resultados"
                                   role="tab" aria-controls="tabs-resultados" aria-selected="false" aria-label="<cfoutput>#VARIABLES.athleteResultsLabel#</cfoutput>" title="<cfoutput>#VARIABLES.athleteResultsLabel#</cfoutput>" onclick="window.history.pushState('Object', '<cfoutput>#VARIABLES.athleteResultsLabel#</cfoutput>', '<cfoutput>#VARIABLES.athleteTabBasePath#?filtro=resultados</cfoutput>');">
                                    <i class="fa-solid fa-medal fs-2"></i>
                                </a>
                            </li>

                            <li class="nav-item d-md-none" role="presentation">
                                <a data-mdb-tab-init class="nav-link p-1 <cfif URL.filtro EQ "conquistas">active</cfif>" id="tab-conquistas" href="#tabs-conquistas"
                                   role="tab" aria-controls="tabs-conquistas" aria-selected="false" aria-label="<cfoutput>#VARIABLES.athleteAchievementsLabel#</cfoutput>" title="<cfoutput>#VARIABLES.athleteAchievementsLabel#</cfoutput>" onclick="window.history.pushState('Object', '<cfoutput>#VARIABLES.athleteAchievementsLabel#</cfoutput>', '<cfoutput>#VARIABLES.athleteTabBasePath#?filtro=conquistas</cfoutput>');">
                                    <i class="fa-solid fa-award fs-2"></i>
                                </a>
                            </li>

                            <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init class="nav-link p-1 <cfif URL.filtro EQ "desafios">active</cfif>" id="tab-desafios" href="#tabs-desafios"
                                   role="tab" aria-controls="tabs-desafios" aria-selected="false" aria-label="<cfoutput>#VARIABLES.athleteChallengesLabel#</cfoutput>" title="<cfoutput>#VARIABLES.athleteChallengesLabel#</cfoutput>" onclick="window.history.pushState('Object', '<cfoutput>#VARIABLES.athleteChallengesLabel#</cfoutput>', '<cfoutput>#VARIABLES.athleteTabBasePath#?filtro=desafios</cfoutput>');">
                                    <i class="fa-solid fa-trophy fs-2"></i>
                                </a>
                            </li>

                            <!---<cfif qPagina.profissional>
                              <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init class="nav-link p-1 <cfif URL.filtro EQ "cupons">active</cfif>" id="tab-cupons" href="#tabs-cupons"
                                   role="tab" aria-controls="tabs-cupons" aria-selected="false" onclick="window.history.pushState('Object', 'Cupons', './?filtro=cupons');">
                                    <i class="fa-solid fa-ticket fs-2"></i>
                                    <span class="small py-2">Cupom</span>
                                </a>
                              </li>
                            </cfif>--->

                        </ul>
                        </div>


                        <!--- CONTEUDO DAS ABAS DO PERFIL --->

                        <div class="tab-content p-0" id="ex2-content">


                            <!--- SOCIAL --->

                            <div class="tab-pane fade <cfif URL.filtro EQ "">show active</cfif>" id="tabs-atividades" role="tabpanel" aria-labelledby="tab-atividades">

                                <!--- QUERY DO FEED --->
                                <cfinclude template="parts/area_social_backend.cfm"/>

                                <!--- POST FORM --->

                                <cfinclude template="parts/area_social_form.cfm"/>

                                <!--- ESCOLHA DO TIPO DE FEED --->

                                <!---<cfinclude template="area_social_filtros.cfm"/>--->

                                <!--- AVISO DO FEED --->

                                <cfinclude template="parts/area_social_aviso.cfm"/>

                                <!--- FEED --->

                                <cfinclude template="parts/area_social.cfm"/>

                            </div>


                            <!--- AGENDA --->

                            <div class="tab-pane fade <cfif URL.filtro EQ "agenda">show active</cfif>" id="tabs-agenda" role="tabpanel" aria-labelledby="tab-agenda">

                                <cfinclude template="parts/agenda.cfm"/>

                            </div>


                            <!--- RESULTADOS --->

                            <div class="tab-pane fade <cfif URL.filtro EQ "resultados">show active</cfif>" id="tabs-resultados" role="tabpanel" aria-labelledby="tab-resultados">

                                <cfinclude template="parts/resultados.cfm"/>

                            </div>


                            <!--- CONQUISTAS --->

                            <div class="tab-pane fade <cfif URL.filtro EQ "conquistas">show active</cfif>" id="tabs-conquistas" role="tabpanel" aria-labelledby="tab-conquistas">

                                <cfset VARIABLES.badgeSize = 3/>

                                <cfinclude template="parts/badges.cfm"/>

                                <div class="d-md-none mt-3">
                                    <cfif qPagina.perfil_publico OR (isDefined("qCheckSeguindo") AND qCheckSeguindo.recordcount) OR (Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id)>
                                        <cfinclude template="parts/tabela_melhores_marcas.cfm"/>
                                    </cfif>
                                </div>

                            </div>


                            <!--- DESAFIOS --->

                            <div class="tab-pane fade <cfif URL.filtro EQ "desafios">show active</cfif>" id="tabs-desafios" role="tabpanel" aria-labelledby="tab-desafios">

                                <cfif Usuario.logado>
                                    <cfinclude template="parts/desafios.cfm"/>
                                <cfelse>
                                    <div class="alert text-warning mt-3" role="alert" data-mdb-color="warning" data-mdb-alert-init>
                                        <button class="btn btn-sm shadow-0 btn-primary float-end" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"><cfoutput>#REQUEST.t("athlete.alerts.loginRequiredCta")#</cfoutput></button>
                                        <i class="fas fa-exclamation-triangle text-warning me-3"></i><cfoutput>#REQUEST.t("athlete.alerts.loginRequiredText")#</cfoutput>
                                    </div>
                                </cfif>

                            </div>


                            <!--- CUPONS --->

                            <!---<cfif qPagina.profissional>

                                <div class="tab-pane fade <cfif URL.filtro EQ "cupons">show active</cfif>" id="tabs-cupons" role="tabpanel" aria-labelledby="tab-cupons">

                                    <cfinclude template="parts/cupons.cfm"/>

                                </div>

                            </cfif>--->


                        </div>

                    <cfelse>

                        <div class="alert small mb-2" role="alert" data-mdb-color="light" data-mdb-alert-init>
                            <i class="fas fa-exclamation-triangle me-3"></i><b><cfoutput>#REQUEST.t("athlete.alerts.privateTitle")#</cfoutput></b><br><cfoutput>#REQUEST.t("athlete.alerts.privateText")#</cfoutput>
                        </div>

                    </cfif>

                </div>

            </div>

            <!--- BARRA LATERAL (DESKTOP) --->

            <div class="col-12 col-lg-3 d-none d-lg-block">
                <cfinclude template="parts/sidebar_desktop.cfm"/>
            </div>

        </div>

        </main>

    </div>



    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL DE ENVIAR --->

    <cfinclude template="../includes/modal/modal_enviar.cfm"/>


    <!--- MODAL DA FOTO DO PERFIL --->

    <cfinclude template="../includes/modal/modal_profile_photo.cfm"/>


    <!--- MODAL DE BADGES --->

    <cfinclude template="../includes/modal/modal_badges.cfm"/>


    <!--- MODAL DE YOUTUBE --->

    <cfinclude template="../includes/modal/modal_youtube.cfm"/>


    <!--- MODAL FOCO --->

    <cfinclude template="../includes/modal/modal_cupom_foco.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>

    <!--- MODAL DE ENVIO DE EVENTO PELO CHAT --->

    <cfif Usuario.logado>
        <cfset VARIABLES.eventChatShareEventIdOverride=0/>
        <cfinclude template="../includes/modal/modal_chat_evento.cfm"/>
    </cfif>

    <cfif VARIABLES.isOwnAthleteProfile>
        <cfinclude template="../includes/modal/modal_result_share_images.cfm"/>
    </cfif>


    <!--- MODAL SEGUIDORES / SEGUINDO --->

    <cfinclude template="../includes/modal/modal_seguidores.cfm"/>


    <!--- MODAL PAGAMENTO --->

    <cfinclude template="../includes/modal/modal_pagamento.cfm"/>

    <script>
        (function sanitizeAthleteModalTargets() {
            const modalTriggers = document.querySelectorAll('[data-mdb-modal-init][data-mdb-target]');

            modalTriggers.forEach((trigger) => {
                const rawTarget = (trigger.getAttribute('data-mdb-target') || '').trim();

                if (!rawTarget || rawTarget.startsWith('.')) {
                    return;
                }

                const normalizedTarget = rawTarget.startsWith('##') ? `#${rawTarget.slice(2)}` : rawTarget;

                if (normalizedTarget !== rawTarget) {
                    trigger.setAttribute('data-mdb-target', normalizedTarget);
                }

                try {
                    const modalElement = document.querySelector(normalizedTarget);

                    if (!modalElement || !modalElement.classList.contains('modal')) {
                        console.warn('Trigger de modal invalido removido em /atleta/', {
                            target: normalizedTarget,
                            trigger
                        });
                        trigger.removeAttribute('data-mdb-modal-init');
                    }
                } catch (error) {
                    console.warn('Seletor de modal invalido removido em /atleta/', {
                        target: normalizedTarget,
                        trigger,
                        error
                    });
                    trigger.removeAttribute('data-mdb-modal-init');
                }
            });
        })();

        (function initializeAthleteDirectMessage() {
            const button = document.querySelector('[data-athlete-direct-message]');

            if (!button) {
                return;
            }

            button.addEventListener('click', async () => {
                if (button.disabled) {
                    return;
                }

                button.disabled = true;

                try {
                    const response = await fetch('/api/chat/conversations.cfm', {
                        method: 'POST',
                        credentials: 'same-origin',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ id_usuario: Number(button.dataset.recipientId) })
                    });
                    const payload = await response.json();

                    if (!response.ok || !payload.success || !payload.id_conversa) {
                        throw new Error(payload.message || button.dataset.errorMessage);
                    }

                    const basePath = (button.dataset.messagesPath || '/mensagens/').replace(/\/*$/, '/');
                    window.location.assign(payload.open_url || basePath);
                } catch (error) {
                    window.alert(button.dataset.errorMessage);
                    button.disabled = false;
                }
            });
        })();
    </script>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

    <cfif Usuario.logado><script src="/assets/js/runnerhub-event-chat-share.js?v=20261104-sharing" defer></script></cfif>
    <cfif VARIABLES.isOwnAthleteProfile><script src="/assets/js/runnerhub-self-declared-results.js?v=4" defer></script></cfif>
    <cfif VARIABLES.isOwnAthleteProfile><script src="/assets/js/runnerhub-result-share-images.js?v=1" defer></script></cfif>


</body>

</html>
