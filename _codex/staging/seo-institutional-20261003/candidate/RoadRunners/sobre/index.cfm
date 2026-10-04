<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/sobre/"/>
<cfset VARIABLES.routeKey = "about"/>
<cfset REQUEST.currentRouteKey = VARIABLES.routeKey/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- META INFO --->
<cfset VARIABLES.canonical = REQUEST.i18nBuildAbsoluteUrl(VARIABLES.routeKey, REQUEST.lang)/>
<cfset VARIABLES.title = REQUEST.t("about.meta.title")/>
<cfset VARIABLES.description = REQUEST.t("about.meta.description")/>
<cfset VARIABLES.keywords = REQUEST.t("about.meta.keywords")/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/assets/css/runnerhub-institutional.css?v=20260913a"/>

<body>
    <cfset proposalParagraphs = REQUEST.i18n.about.proposal.paragraphs />

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .about-page-shell {
            padding: 1rem 0 2rem;
        }

        .about-hero {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 14px;
            background:
                radial-gradient(circle at top left, rgba(250, 177, 32, 0.18), transparent 34%),
                linear-gradient(135deg, #efefef 0%, #ffffff 100%);
            color: #333333;
            overflow: hidden;
        }

        .about-kicker {
            display: inline-flex;
            align-items: center;
            gap: 0.45rem;
            padding: 0.45rem 0.8rem;
            border-radius: 999px;
            background-color: rgba(255, 255, 255, 0.88);
            color: #333333;
            font-size: 0.78rem;
            font-weight: 800;
            letter-spacing: 0.06em;
            text-transform: uppercase;
        }

        .about-title {
            font-size: clamp(2rem, 4vw, 3.2rem);
            line-height: 0.98;
            margin: 1rem 0 0.85rem;
            color: #333333;
        }

        .about-subtitle {
            max-width: 780px;
            color: rgba(51, 51, 51, 0.78);
            font-size: 1.02rem;
            line-height: 1.55;
            margin-bottom: 0;
        }

        .about-hero-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 0.75rem;
            margin-top: 1.25rem;
        }

        .about-section {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 14px;
            background-color: #ffffff;
            color: #333333;
        }

        .about-section-title {
            font-size: 1.15rem;
            font-weight: 800;
            color: #333333;
            margin-bottom: 0.25rem;
        }

        .about-section-copy {
            color: rgba(51, 51, 51, 0.72);
            margin-bottom: 0;
        }

        .about-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 0.85rem;
        }

        .about-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 12px;
            background-color: #efefef;
            padding: 1rem;
            height: 100%;
        }

        .about-card-icon {
            width: 46px;
            height: 46px;
            border-radius: 12px;
            background-color: #ffffff;
            color: #fab120;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 1.15rem;
            margin-bottom: 0.75rem;
            border: 1px solid rgba(51, 51, 51, 0.08);
        }

        .about-card-title {
            color: #333333;
            font-size: 1rem;
            font-weight: 800;
            margin-bottom: 0.35rem;
        }

        .about-card-copy {
            color: rgba(51, 51, 51, 0.76);
            font-size: 0.92rem;
            line-height: 1.5;
            margin-bottom: 0;
        }

        .about-highlight-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 0.85rem;
        }

        .about-highlight {
            border-radius: 12px;
            background-color: #efefef;
            padding: 0.95rem 1rem;
            border: 1px solid rgba(51, 51, 51, 0.08);
        }

        .about-highlight-kicker {
            color: rgba(51, 51, 51, 0.62);
            font-size: 0.74rem;
            font-weight: 800;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            margin-bottom: 0.3rem;
        }

        .about-highlight-value {
            color: #333333;
            font-size: 1.02rem;
            font-weight: 800;
            line-height: 1.3;
        }

        .about-copy {
            color: rgba(51, 51, 51, 0.8);
            font-size: 0.98rem;
            line-height: 1.75;
        }

        .about-copy p:last-child {
            margin-bottom: 0;
        }

        @media (max-width: 991.98px) {
            .about-grid,
            .about-highlight-grid {
                grid-template-columns: 1fr;
            }

            .about-hero-actions .btn {
                width: 100%;
            }
        }
    </style>

    <div class="container">

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <div class="about-page-shell">
            <cfinclude template="../includes/estrutura/institutional_nav.cfm"/>
            <section class="about-hero p-4 p-lg-5">
                <span class="about-kicker">
                    <i class="fa-solid fa-circle-info"></i>
                    <cfoutput>#REQUEST.t("about.hero.kicker")#</cfoutput>
                </span>
                <h1 class="about-title"><cfoutput>#REQUEST.t("about.hero.title")#</cfoutput></h1>
                <p class="about-subtitle"><cfoutput>#REQUEST.t("about.hero.subtitle")#</cfoutput></p>
                <div class="about-hero-actions">
                    <a href="<cfoutput>#REQUEST.i18nBuildPath('search')#</cfoutput>" class="btn btn-primary btn-lg">
                        <i class="fa-solid fa-magnifying-glass me-2"></i><cfoutput>#REQUEST.t("about.actions.exploreEvents")#</cfoutput>
                    </a>
                    <a href="<cfoutput>#REQUEST.i18nBuildPath('help')#</cfoutput>" class="btn btn-secondary btn-lg">
                        <i class="fa-solid fa-circle-question me-2"></i><cfoutput>#REQUEST.t("about.actions.helpCenter")#</cfoutput>
                    </a>
                </div>
            </section>

            <section class="about-section p-4 p-lg-5 mt-3">
                <div class="d-flex flex-column flex-lg-row justify-content-between align-items-start gap-3 mb-4">
                    <div>
                        <h2 class="about-section-title"><cfoutput>#REQUEST.t("about.highlightsSection.title")#</cfoutput></h2>
                        <p class="about-section-copy"><cfoutput>#REQUEST.t("about.highlightsSection.copy")#</cfoutput></p>
                    </div>
                </div>

                <div class="about-highlight-grid mb-4">
                    <div class="about-highlight">
                        <div class="about-highlight-kicker"><cfoutput>#REQUEST.t("about.highlights.calendar.label")#</cfoutput></div>
                        <div class="about-highlight-value"><cfoutput>#REQUEST.t("about.highlights.calendar.value")#</cfoutput></div>
                    </div>
                    <div class="about-highlight">
                        <div class="about-highlight-kicker"><cfoutput>#REQUEST.t("about.highlights.results.label")#</cfoutput></div>
                        <div class="about-highlight-value"><cfoutput>#REQUEST.t("about.highlights.results.value")#</cfoutput></div>
                    </div>
                    <div class="about-highlight">
                        <div class="about-highlight-kicker"><cfoutput>#REQUEST.t("about.highlights.profiles.label")#</cfoutput></div>
                        <div class="about-highlight-value"><cfoutput>#REQUEST.t("about.highlights.profiles.value")#</cfoutput></div>
                    </div>
                    <div class="about-highlight">
                        <div class="about-highlight-kicker"><cfoutput>#REQUEST.t("about.highlights.content.label")#</cfoutput></div>
                        <div class="about-highlight-value"><cfoutput>#REQUEST.t("about.highlights.content.value")#</cfoutput></div>
                    </div>
                </div>

                <div class="about-grid">
                    <article class="about-card">
                        <div class="about-card-icon"><i class="fa-solid fa-calendar-days"></i></div>
                        <h3 class="about-card-title"><cfoutput>#REQUEST.t("about.cards.discovery.title")#</cfoutput></h3>
                        <p class="about-card-copy"><cfoutput>#REQUEST.t("about.cards.discovery.copy")#</cfoutput></p>
                    </article>
                    <article class="about-card">
                        <div class="about-card-icon"><i class="fa-solid fa-medal"></i></div>
                        <h3 class="about-card-title"><cfoutput>#REQUEST.t("about.cards.history.title")#</cfoutput></h3>
                        <p class="about-card-copy"><cfoutput>#REQUEST.t("about.cards.history.copy")#</cfoutput></p>
                    </article>
                    <article class="about-card">
                        <div class="about-card-icon"><i class="fa-solid fa-newspaper"></i></div>
                        <h3 class="about-card-title"><cfoutput>#REQUEST.t("about.cards.editorial.title")#</cfoutput></h3>
                        <p class="about-card-copy"><cfoutput>#REQUEST.t("about.cards.editorial.copy")#</cfoutput></p>
                    </article>
                </div>
            </section>

            <section class="about-section p-4 p-lg-5 mt-3">
                <div class="d-flex flex-column flex-lg-row justify-content-between align-items-start gap-3 mb-4">
                    <div>
                        <h2 class="about-section-title"><cfoutput>#REQUEST.t("about.proposal.title")#</cfoutput></h2>
                        <p class="about-section-copy"><cfoutput>#REQUEST.t("about.proposal.copy")#</cfoutput></p>
                    </div>
                </div>

                <div class="about-copy">
                    <cfoutput>
                        <cfloop from="1" to="#arrayLen(proposalParagraphs)#" index="proposalIndex">
                            <p>#proposalParagraphs[proposalIndex]#</p>
                        </cfloop>
                    </cfoutput>
                </div>
            </section>

            <section class="about-section p-4 p-lg-5 mt-3">
                <div class="d-flex flex-column flex-lg-row justify-content-between align-items-start gap-3 mb-4">
                    <div>
                        <h2 class="about-section-title"><cfoutput>#REQUEST.t("about.exploreMore.title")#</cfoutput></h2>
                        <p class="about-section-copy"><cfoutput>#REQUEST.t("about.exploreMore.copy")#</cfoutput></p>
                    </div>
                </div>

                <div class="about-grid">
                    <article class="about-card">
                        <div class="about-card-icon"><i class="fa-solid fa-circle-question"></i></div>
                        <h3 class="about-card-title"><cfoutput>#REQUEST.t("about.exploreCards.help.title")#</cfoutput></h3>
                        <p class="about-card-copy"><cfoutput>#REQUEST.t("about.exploreCards.help.copy")#</cfoutput></p>
                        <a href="<cfoutput>#REQUEST.i18nBuildPath('help')#</cfoutput>" class="btn btn-secondary w-100 mt-3"><cfoutput>#REQUEST.t("about.exploreCards.help.cta")#</cfoutput></a>
                    </article>
                    <article class="about-card">
                        <div class="about-card-icon"><i class="fa-solid fa-shield-halved"></i></div>
                        <h3 class="about-card-title"><cfoutput>#REQUEST.t("about.exploreCards.privacy.title")#</cfoutput></h3>
                        <p class="about-card-copy"><cfoutput>#REQUEST.t("about.exploreCards.privacy.copy")#</cfoutput></p>
                        <a href="<cfoutput>#REQUEST.i18nBuildPath('privacy')#</cfoutput>" class="btn btn-secondary w-100 mt-3"><cfoutput>#REQUEST.t("about.exploreCards.privacy.cta")#</cfoutput></a>
                    </article>
                    <article class="about-card">
                        <div class="about-card-icon"><i class="fa-solid fa-lightbulb"></i></div>
                        <h3 class="about-card-title"><cfoutput>#REQUEST.t("about.exploreCards.suggest.title")#</cfoutput></h3>
                        <p class="about-card-copy"><cfoutput>#REQUEST.t("about.exploreCards.suggest.copy")#</cfoutput></p>
                        <a href="#!" class="btn btn-primary w-100 mt-3" data-mdb-modal-init data-mdb-target="#modal_evento_cadastro"><cfoutput>#REQUEST.t("about.exploreCards.suggest.cta")#</cfoutput></a>
                    </article>
                </div>
            </section>
        </div>

        </main>

    </div>

    <cfinclude template="../includes/estrutura/footer.cfm"/>

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>

    <cfinclude template="../includes/modal/modal_login.cfm"/>

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>
