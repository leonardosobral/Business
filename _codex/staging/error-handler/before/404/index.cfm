<!doctype html>
<html lang="<cfoutput>#structKeyExists(REQUEST, 'htmlLang') ? REQUEST.htmlLang : 'pt-BR'#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>
<cfheader statuscode="404" statusText="not found"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/404/"/>
<cfset VARIABLES.routeKey = "notFound"/>

<!--- ORIGINAL REQUEST --->
<cfparam name="URL.tag" default=""/>
<cfset VARIABLES.notFoundRequestedPath = structKeyExists(CGI, "REDIRECT_URL") AND len(trim(CGI.REDIRECT_URL))
    ? trim(CGI.REDIRECT_URL)
    : (len(trim(URL.tag)) ? trim(URL.tag) : "/404/")/>
<cfset VARIABLES.notFoundRequestedPath = left(listFirst(VARIABLES.notFoundRequestedPath, "?"), 1000)/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<cfquery>
    INSERT INTO tb_log
    (log_item, log_item_id, log_user, site)
    VALUES
    ('404',<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notFoundRequestedPath#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>)
</cfquery>

<cfset REQUEST.currentRouteKey = VARIABLES.routeKey/>
<cfset REQUEST.currentRouteParams = {}/>
<cfset VARIABLES.notFoundHomePath = REQUEST.i18nBuildPath("home")/>
<cfset VARIABLES.notFoundSearchPath = REQUEST.i18nBuildPath("search")/>
<cfset VARIABLES.notFoundResultsPath = REQUEST.i18nBuildPath("results")/>

<!--- META INFO --->
<cfset VARIABLES.canonical = REQUEST.i18nBuildAbsoluteUrl(VARIABLES.routeKey)/>
<cfset VARIABLES.title = REQUEST.t("notFound.meta.title")/>
<cfset VARIABLES.description = REQUEST.t("notFound.meta.description")/>
<cfset VARIABLES.keywords = REQUEST.t("notFound.meta.keywords")/>
<cfset VARIABLES.metaRobots = "noindex,follow"/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<style>
    .rr-not-found {
        padding: clamp(1.5rem, 4vw, 3.5rem) 0 clamp(2rem, 6vw, 4.5rem);
    }

    .rr-not-found-card {
        max-width: 980px;
        margin: 0 auto;
        overflow: hidden;
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 18px;
        background: #ffffff;
        box-shadow: 0 18px 46px rgba(51, 51, 51, 0.07);
    }

    .rr-not-found-copy {
        max-width: 760px;
        margin: 0 auto;
        padding: clamp(2rem, 5vw, 4rem) clamp(1.25rem, 5vw, 4rem) 1.5rem;
        text-align: center;
    }

    .rr-not-found-kicker {
        display: inline-flex;
        align-items: center;
        gap: 0.45rem;
        margin-bottom: 0.8rem;
        color: #73510a;
        font-size: 0.78rem;
        font-weight: 900;
        letter-spacing: 0.08em;
        text-transform: uppercase;
    }

    .rr-not-found-kicker::before {
        width: 0.55rem;
        height: 0.55rem;
        border-radius: 999px;
        background: #fab120;
        content: "";
    }

    .rr-not-found-title {
        margin-bottom: 0.9rem;
        color: #333333;
        font-size: clamp(2rem, 5vw, 3.45rem);
        font-weight: 900;
        letter-spacing: -0.045em;
        line-height: 0.98;
    }

    .rr-not-found-description {
        max-width: 650px;
        margin: 0 auto;
        color: #666666;
        font-size: clamp(1rem, 2vw, 1.12rem);
        line-height: 1.6;
    }

    .rr-not-found-actions,
    .rr-not-found-shortcuts {
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        gap: 0.65rem;
    }

    .rr-not-found-actions {
        margin-top: 1.6rem;
    }

    .rr-not-found-action {
        min-height: 46px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 0.5rem;
        padding: 0.7rem 1.05rem;
        border: 1px solid rgba(51, 51, 51, 0.12);
        border-radius: 999px;
        color: #333333;
        font-weight: 800;
        text-decoration: none;
        transition: background-color .18s ease, border-color .18s ease, transform .18s ease;
    }

    .rr-not-found-action:hover,
    .rr-not-found-action:focus {
        border-color: #fab120;
        background: #fff8e8;
        color: #222222;
        transform: translateY(-1px);
    }

    .rr-not-found-action.is-primary {
        border-color: #fab120;
        background: #fab120;
        color: #333333;
    }

    .rr-not-found-action.is-primary:hover,
    .rr-not-found-action.is-primary:focus {
        background: #f4b120;
    }

    .rr-not-found-shortcuts {
        margin-top: 0.75rem;
    }

    .rr-not-found-shortcut {
        padding: 0.35rem 0.55rem;
        color: #555555;
        font-size: 0.9rem;
        font-weight: 700;
        text-decoration: none;
    }

    .rr-not-found-shortcut:hover,
    .rr-not-found-shortcut:focus {
        color: #111111;
        text-decoration: underline;
        text-decoration-color: #fab120;
        text-decoration-thickness: 2px;
        text-underline-offset: 0.22rem;
    }

    .rr-not-found-art {
        padding: 0 clamp(0.75rem, 4vw, 2.5rem) clamp(1.25rem, 4vw, 2.5rem);
        background: linear-gradient(180deg, rgba(250, 177, 32, 0) 0%, rgba(250, 177, 32, 0.07) 100%);
    }

    .rr-not-found-art img {
        width: 100%;
        height: auto;
        display: block;
    }

    @media (max-width: 575.98px) {
        .rr-not-found-copy {
            text-align: left;
        }

        .rr-not-found-description {
            margin-left: 0;
        }

        .rr-not-found-actions,
        .rr-not-found-shortcuts {
            justify-content: flex-start;
        }

        .rr-not-found-action {
            width: 100%;
        }

        .rr-not-found-art {
            overflow: hidden;
            padding-right: 0;
            padding-left: 0;
        }

        .rr-not-found-art img {
            width: 125%;
            max-width: none;
            margin-left: -12.5%;
        }
    }

    @media (prefers-reduced-motion: reduce) {
        .rr-not-found-action {
            transition: none;
        }
    }
</style>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>


    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <section class="rr-not-found" aria-labelledby="rrNotFoundTitle">
            <div class="rr-not-found-card">
                <div class="rr-not-found-copy">
                    <div class="rr-not-found-kicker"><cfoutput>#REQUEST.t("notFound.kicker")#</cfoutput></div>
                    <h1 class="rr-not-found-title" id="rrNotFoundTitle"><cfoutput>#REQUEST.t("notFound.title")#</cfoutput></h1>
                    <p class="rr-not-found-description"><cfoutput>#REQUEST.t("notFound.copy")#</cfoutput></p>

                    <div class="rr-not-found-actions">
                        <a class="rr-not-found-action is-primary"
                            href="<cfoutput>#VARIABLES.notFoundSearchPath#</cfoutput>"
                            data-home-hero-open
                            data-home-hero-focus
                            aria-controls="homeHeroSearch"
                            aria-expanded="false">
                            <i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i>
                            <cfoutput>#REQUEST.t("notFound.searchCta")#</cfoutput>
                        </a>
                        <a class="rr-not-found-action" href="<cfoutput>#VARIABLES.notFoundHomePath#</cfoutput>">
                            <i class="fa-solid fa-house" aria-hidden="true"></i>
                            <cfoutput>#REQUEST.t("notFound.homeCta")#</cfoutput>
                        </a>
                    </div>

                    <nav class="rr-not-found-shortcuts" aria-label="<cfoutput>#REQUEST.t('notFound.kicker')#</cfoutput>">
                        <a class="rr-not-found-shortcut" href="<cfoutput>#VARIABLES.notFoundSearchPath#</cfoutput>">
                            <i class="fa-regular fa-calendar me-1" aria-hidden="true"></i><cfoutput>#REQUEST.t("notFound.calendarCta")#</cfoutput>
                        </a>
                        <a class="rr-not-found-shortcut" href="<cfoutput>#VARIABLES.notFoundResultsPath#</cfoutput>">
                            <i class="fa-solid fa-medal me-1" aria-hidden="true"></i><cfoutput>#REQUEST.t("notFound.resultsCta")#</cfoutput>
                        </a>
                    </nav>
                </div>

                <div class="rr-not-found-art" aria-hidden="true">
                    <img src="/assets/rr_404.png" alt="" width="1240" height="400">
                </div>
            </div>
        </section>

        </main>

    </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>
