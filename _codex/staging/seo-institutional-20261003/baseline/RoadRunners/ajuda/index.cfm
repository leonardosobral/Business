<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/ajuda/"/>
<cfset VARIABLES.routeKey = "help"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- META INFO --->
<cfset VARIABLES.canonical = REQUEST.i18nBuildAbsoluteUrl(VARIABLES.routeKey, REQUEST.lang)/>
<cfset VARIABLES.title = REQUEST.t("help.meta.title")/>
<cfset VARIABLES.description = REQUEST.t("help.meta.description")/>
<cfset VARIABLES.keywords = REQUEST.t("help.meta.keywords")/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/assets/css/runnerhub-institutional.css?v=20260913a"/>
<style>
    .help-page-shell {
        padding: 1rem 0 2rem;
    }

    .help-hero {
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 14px;
        background:
            radial-gradient(circle at top left, rgba(250, 177, 32, 0.18), transparent 34%),
            linear-gradient(135deg, #efefef 0%, #ffffff 100%);
        color: #333333;
        overflow: hidden;
    }

    .help-kicker {
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

    .help-title {
        font-size: clamp(2rem, 4vw, 3.2rem);
        line-height: 0.98;
        margin: 1rem 0 0.85rem;
        color: #333333;
    }

    .help-subtitle {
        max-width: 760px;
        color: rgba(51, 51, 51, 0.78);
        font-size: 1.02rem;
        line-height: 1.55;
        margin-bottom: 0;
    }

    .help-hero-actions {
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        margin-top: 1.25rem;
    }

    .help-section {
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 14px;
        background-color: #ffffff;
        color: #333333;
    }

    .help-section-title {
        font-size: 1.15rem;
        font-weight: 800;
        color: #333333;
        margin-bottom: 0.25rem;
    }

    .help-section-copy {
        color: rgba(51, 51, 51, 0.72);
        margin-bottom: 0;
    }

    .help-grid {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 0.85rem;
    }

    .help-card {
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 12px;
        background-color: #efefef;
        padding: 1rem;
        height: 100%;
    }

    .help-card-icon {
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

    .help-card-title {
        color: #333333;
        font-size: 1rem;
        font-weight: 800;
        margin-bottom: 0.35rem;
    }

    .help-card-copy {
        color: rgba(51, 51, 51, 0.76);
        font-size: 0.92rem;
        line-height: 1.5;
        margin-bottom: 0;
    }

    .help-card-link {
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        margin-top: 0.85rem;
        color: #333333;
        font-size: 0.86rem;
        font-weight: 800;
        text-decoration: none;
    }

    .help-card-link:hover,
    .help-card-link:focus {
        color: #111111;
        text-decoration: none;
    }

    .help-highlights {
        display: grid;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        gap: 0.85rem;
    }

    .help-highlight {
        border-radius: 12px;
        background-color: #efefef;
        padding: 0.95rem 1rem;
        border: 1px solid rgba(51, 51, 51, 0.08);
    }

    .help-highlight-kicker {
        color: rgba(51, 51, 51, 0.62);
        font-size: 0.74rem;
        font-weight: 800;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        margin-bottom: 0.3rem;
    }

    .help-highlight-value {
        color: #333333;
        font-size: 1.02rem;
        font-weight: 800;
        line-height: 1.25;
    }

    .help-accordion .accordion-item {
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 12px !important;
        background-color: #ffffff;
        overflow: hidden;
    }

    .help-accordion .accordion-item + .accordion-item {
        margin-top: 0.65rem;
    }

    .help-accordion .accordion-button {
        background-color: #ffffff;
        color: #333333;
        font-weight: 800;
        box-shadow: none !important;
        padding: 1rem 1.15rem;
    }

    .help-accordion .accordion-button:not(.collapsed) {
        color: #f4b120 !important;
        background-color: #ffffff;
    }

    .help-accordion .accordion-button:not(.collapsed)::after {
        background-image: var(--mdb-accordion-btn-icon) !important;
    }

    .help-accordion .accordion-body {
        color: rgba(51, 51, 51, 0.78);
        line-height: 1.6;
    }

    .help-contact-grid {
        display: grid;
        grid-template-columns: 1.2fr 1fr;
        gap: 0.85rem;
    }

    .help-contact-box {
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 12px;
        background-color: #efefef;
        padding: 1rem;
    }

    @media (max-width: 991.98px) {
        .help-grid,
        .help-highlights,
        .help-contact-grid {
            grid-template-columns: 1fr;
        }

        .help-hero-actions .btn {
            width: 100%;
        }
    }
</style>
<body>
    <cfset faqItems = REQUEST.i18n.help.faq.items />

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>


    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <div class="help-page-shell">
            <cfinclude template="../includes/estrutura/institutional_nav.cfm"/>
            <section class="help-hero p-4 p-lg-5">
                <span class="help-kicker">
                    <i class="fa-solid fa-circle-info"></i>
                    <cfoutput>#REQUEST.t("help.hero.kicker")#</cfoutput>
                </span>
                <h1 class="help-title"><cfoutput>#REQUEST.t("help.hero.title")#</cfoutput></h1>
                <p class="help-subtitle"><cfoutput>#REQUEST.t("help.hero.subtitle")#</cfoutput></p>
                <div class="help-hero-actions">
                    <a href="<cfoutput>#REQUEST.i18nBuildPath('support')#</cfoutput>" class="btn btn-primary btn-lg">
                        <i class="fa-solid fa-headset me-2"></i><cfoutput>#REQUEST.t("help.actions.openTicket")#</cfoutput>
                    </a>
                    <a href="#!" class="btn btn-secondary btn-lg" data-mdb-modal-init data-mdb-target="#modal_evento_cadastro">
                        <i class="fa-solid fa-lightbulb me-2"></i><cfoutput>#REQUEST.t("help.actions.suggestEvent")#</cfoutput>
                    </a>
                    <a href="<cfoutput>#REQUEST.i18nBuildPath('search')#</cfoutput>" class="btn btn-secondary btn-lg">
                        <i class="fa-solid fa-magnifying-glass me-2"></i><cfoutput>#REQUEST.t("help.actions.searchSite")#</cfoutput>
                    </a>
                </div>
            </section>

            <section class="help-section p-4 p-lg-5 mt-3">
                <div class="d-flex flex-column flex-lg-row justify-content-between align-items-start gap-3 mb-4">
                    <div>
                        <h2 class="help-section-title"><cfoutput>#REQUEST.t("help.start.title")#</cfoutput></h2>
                        <p class="help-section-copy"><cfoutput>#REQUEST.t("help.start.copy")#</cfoutput></p>
                    </div>
                </div>

                <div class="help-highlights mb-4">
                    <div class="help-highlight">
                        <div class="help-highlight-kicker"><cfoutput>#REQUEST.t("help.highlights.calendar.label")#</cfoutput></div>
                        <div class="help-highlight-value"><cfoutput>#REQUEST.t("help.highlights.calendar.value")#</cfoutput></div>
                    </div>
                    <div class="help-highlight">
                        <div class="help-highlight-kicker"><cfoutput>#REQUEST.t("help.highlights.results.label")#</cfoutput></div>
                        <div class="help-highlight-value"><cfoutput>#REQUEST.t("help.highlights.results.value")#</cfoutput></div>
                    </div>
                    <div class="help-highlight">
                        <div class="help-highlight-kicker"><cfoutput>#REQUEST.t("help.highlights.content.label")#</cfoutput></div>
                        <div class="help-highlight-value"><cfoutput>#REQUEST.t("help.highlights.content.value")#</cfoutput></div>
                    </div>
                    <div class="help-highlight">
                        <div class="help-highlight-kicker"><cfoutput>#REQUEST.t("help.highlights.community.label")#</cfoutput></div>
                        <div class="help-highlight-value"><cfoutput>#REQUEST.t("help.highlights.community.value")#</cfoutput></div>
                    </div>
                </div>

                <div class="help-grid">
                    <article class="help-card">
                        <div class="help-card-icon"><i class="fa-solid fa-calendar-days"></i></div>
                        <h3 class="help-card-title"><cfoutput>#REQUEST.t("help.cards.findRaces.title")#</cfoutput></h3>
                        <p class="help-card-copy"><cfoutput>#REQUEST.t("help.cards.findRaces.copy")#</cfoutput></p>
                        <a href="<cfoutput>#REQUEST.i18nBuildPath('search')#</cfoutput>" class="help-card-link"><cfoutput>#REQUEST.t("help.cards.findRaces.cta")#</cfoutput> <i class="fa-solid fa-arrow-right"></i></a>
                    </article>
                    <article class="help-card">
                        <div class="help-card-icon"><i class="fa-solid fa-medal"></i></div>
                        <h3 class="help-card-title"><cfoutput>#REQUEST.t("help.cards.results.title")#</cfoutput></h3>
                        <p class="help-card-copy"><cfoutput>#REQUEST.t("help.cards.results.copy")#</cfoutput></p>
                        <a href="/perfil/" class="help-card-link"><cfoutput>#REQUEST.t("help.cards.results.cta")#</cfoutput> <i class="fa-solid fa-arrow-right"></i></a>
                    </article>
                    <article class="help-card">
                        <div class="help-card-icon"><i class="fa-solid fa-newspaper"></i></div>
                        <h3 class="help-card-title"><cfoutput>#REQUEST.t("help.cards.content.title")#</cfoutput></h3>
                        <p class="help-card-copy"><cfoutput>#REQUEST.t("help.cards.content.copy")#</cfoutput></p>
                        <a href="<cfoutput>#REQUEST.i18nBuildPath('news')#</cfoutput>" class="help-card-link"><cfoutput>#REQUEST.t("help.cards.content.cta")#</cfoutput> <i class="fa-solid fa-arrow-right"></i></a>
                    </article>
                </div>
            </section>

            <section class="help-section p-4 p-lg-5 mt-3">
                <div class="d-flex flex-column flex-lg-row justify-content-between align-items-start gap-3 mb-4">
                    <div>
                        <h2 class="help-section-title"><cfoutput>#REQUEST.t("help.faq.title")#</cfoutput></h2>
                        <p class="help-section-copy"><cfoutput>#REQUEST.t("help.faq.copy")#</cfoutput></p>
                    </div>
                </div>

                <div class="accordion accordion-flush help-accordion" id="accordionAjuda">
                    <cfoutput>
                        <cfloop from="1" to="#arrayLen(faqItems)#" index="faqIndex">
                            <cfset faqItem = faqItems[faqIndex] />
                            <cfset headingId = "helpHeading" & faqIndex />
                            <cfset collapseId = "helpCollapse" & faqIndex />
                            <div class="accordion-item">
                                <h2 class="accordion-header" id="#headingId#">
                                    <button class="accordion-button<cfif faqIndex GT 1> collapsed</cfif>" type="button" data-bs-toggle="collapse" data-bs-target="###collapseId#" aria-expanded="<cfif faqIndex EQ 1>true<cfelse>false</cfif>" aria-controls="#collapseId#">
                                        #faqItem.question#
                                    </button>
                                </h2>
                                <div id="#collapseId#" class="accordion-collapse collapse<cfif faqIndex EQ 1> show</cfif>" aria-labelledby="#headingId#" data-bs-parent="##accordionAjuda">
                                    <div class="accordion-body">
                                        #faqItem.answer#
                                    </div>
                                </div>
                            </div>
                        </cfloop>
                    </cfoutput>
                </div>
            </section>

            <section class="help-section p-4 p-lg-5 mt-3">
                <div class="d-flex flex-column flex-lg-row justify-content-between align-items-start gap-3 mb-4">
                    <div>
                        <h2 class="help-section-title"><cfoutput>#REQUEST.t("help.contact.title")#</cfoutput></h2>
                        <p class="help-section-copy"><cfoutput>#REQUEST.t("help.contact.copy")#</cfoutput></p>
                    </div>
                </div>

                <div class="help-contact-grid">
                    <div class="help-contact-box">
                        <h3 class="help-card-title mb-2"><cfoutput>#REQUEST.t("help.contact.ticket.title")#</cfoutput></h3>
                        <p class="help-card-copy mb-3"><cfoutput>#REQUEST.t("help.contact.ticket.copy")#</cfoutput></p>
                        <a href="<cfoutput>#REQUEST.i18nBuildPath('support')#</cfoutput>" class="btn btn-primary">
                            <i class="fa-solid fa-headset me-2"></i><cfoutput>#REQUEST.t("help.contact.ticket.cta")#</cfoutput>
                        </a>
                    </div>
                    <div class="help-contact-box">
                        <h3 class="help-card-title mb-2"><cfoutput>#REQUEST.t("help.contact.suggest.title")#</cfoutput></h3>
                        <p class="help-card-copy mb-3"><cfoutput>#REQUEST.t("help.contact.suggest.copy")#</cfoutput></p>
                        <a href="#!" class="btn btn-primary" data-mdb-modal-init data-mdb-target="#modal_evento_cadastro">
                            <i class="fa-solid fa-lightbulb me-2"></i><cfoutput>#REQUEST.t("help.contact.suggest.cta")#</cfoutput>
                        </a>
                    </div>
                </div>
            </section>
        </div>

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
