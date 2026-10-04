<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/privacidade/"/>
<cfset VARIABLES.routeKey = "privacy"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<!--- META INFO --->
<cfset VARIABLES.canonical = REQUEST.i18nBuildAbsoluteUrl(VARIABLES.routeKey, REQUEST.lang)/>
<cfset VARIABLES.title = REQUEST.t("privacy.meta.title")/>
<cfset VARIABLES.description = REQUEST.t("privacy.meta.description")/>
<cfset VARIABLES.keywords = REQUEST.t("privacy.meta.keywords")/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/assets/css/runnerhub-institutional.css?v=20260913a"/>

<body>
    <cfset privacyBlocks = REQUEST.i18n.privacy.blocks />

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .privacy-page-shell {
            padding: 1rem 0 2rem;
        }

        .privacy-hero {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 14px;
            background:
                radial-gradient(circle at top left, rgba(250, 177, 32, 0.18), transparent 34%),
                linear-gradient(135deg, #efefef 0%, #ffffff 100%);
            color: #333333;
            overflow: hidden;
        }

        .privacy-kicker {
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

        .privacy-title {
            font-size: clamp(2rem, 4vw, 3.2rem);
            line-height: 0.98;
            margin: 1rem 0 0.85rem;
            color: #333333;
        }

        .privacy-subtitle {
            max-width: 820px;
            color: rgba(51, 51, 51, 0.78);
            font-size: 1.02rem;
            line-height: 1.55;
            margin-bottom: 0;
        }

        .privacy-hero-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 0.75rem;
            margin-top: 1.25rem;
        }

        .privacy-section {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 14px;
            background-color: #ffffff;
            color: #333333;
        }

        .privacy-section-title {
            font-size: 1.15rem;
            font-weight: 800;
            color: #333333;
            margin-bottom: 0.25rem;
        }

        .privacy-section-copy {
            color: rgba(51, 51, 51, 0.72);
            margin-bottom: 0;
        }

        .privacy-meta-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 0.85rem;
        }

        .privacy-meta-card {
            border-radius: 12px;
            background-color: #efefef;
            padding: 0.95rem 1rem;
            border: 1px solid rgba(51, 51, 51, 0.08);
        }

        .privacy-meta-kicker {
            color: rgba(51, 51, 51, 0.62);
            font-size: 0.74rem;
            font-weight: 800;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            margin-bottom: 0.3rem;
        }

        .privacy-meta-value {
            color: #333333;
            font-size: 1.02rem;
            font-weight: 800;
            line-height: 1.3;
        }

        .privacy-block {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 12px;
            background-color: #efefef;
            padding: 1rem 1.1rem;
        }

        .privacy-block + .privacy-block {
            margin-top: 0.75rem;
        }

        .privacy-block h3 {
            color: #333333;
            font-size: 1rem;
            font-weight: 800;
            margin-bottom: 0.45rem;
        }

        .privacy-block p,
        .privacy-block li {
            color: rgba(51, 51, 51, 0.8);
            line-height: 1.65;
        }

        .privacy-block ul {
            padding-left: 1.15rem;
            margin-bottom: 0;
        }

        .privacy-note {
            color: rgba(51, 51, 51, 0.66);
            font-size: 0.86rem;
        }

        .privacy-owner {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-left: 4px solid #fab120;
            border-radius: 10px;
            background: #f7f7f7;
            color: rgba(51, 51, 51, 0.78);
            font-size: 0.9rem;
            line-height: 1.55;
            padding: 0.9rem 1rem;
        }

        @media (max-width: 991.98px) {
            .privacy-meta-grid {
                grid-template-columns: 1fr;
            }

            .privacy-hero-actions .btn {
                width: 100%;
            }
        }
    </style>

    <div class="container">

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <div class="privacy-page-shell">
            <cfinclude template="../includes/estrutura/institutional_nav.cfm"/>
            <section class="privacy-hero p-4 p-lg-5">
                <span class="privacy-kicker">
                    <i class="fa-solid fa-shield-halved"></i>
                    <cfoutput>#REQUEST.t("privacy.hero.kicker")#</cfoutput>
                </span>
                <h1 class="privacy-title"><cfoutput>#REQUEST.t("privacy.hero.title")#</cfoutput></h1>
                <p class="privacy-subtitle"><cfoutput>#REQUEST.t("privacy.hero.subtitle")#</cfoutput></p>
                <div class="privacy-hero-actions">
                    <a href="mailto:privacidade@runnerhub.run" class="btn btn-primary btn-lg">
                        <i class="fa-solid fa-envelope me-2"></i><cfoutput>#REQUEST.t("privacy.actions.contactDpo")#</cfoutput>
                    </a>
                    <a href="<cfoutput>#REQUEST.i18nBuildPath('help')#</cfoutput>" class="btn btn-secondary btn-lg">
                        <i class="fa-solid fa-circle-question me-2"></i><cfoutput>#REQUEST.t("privacy.actions.helpCenter")#</cfoutput>
                    </a>
                </div>
            </section>

            <section class="privacy-section p-4 p-lg-5 mt-3">
                <div class="d-flex flex-column flex-lg-row justify-content-between align-items-start gap-3 mb-4">
                    <div>
                        <h2 class="privacy-section-title"><cfoutput>#REQUEST.t("privacy.overview.title")#</cfoutput></h2>
                        <p class="privacy-section-copy"><cfoutput>#REQUEST.t("privacy.overview.copy")#</cfoutput></p>
                    </div>
                </div>

                <div class="privacy-meta-grid mb-4">
                    <div class="privacy-meta-card">
                        <div class="privacy-meta-kicker"><cfoutput>#REQUEST.t("privacy.metaCards.updated.label")#</cfoutput></div>
                        <div class="privacy-meta-value"><cfoutput>#REQUEST.t("privacy.metaCards.updated.value")#</cfoutput></div>
                    </div>
                    <div class="privacy-meta-card">
                        <div class="privacy-meta-kicker"><cfoutput>#REQUEST.t("privacy.metaCards.legalBasis.label")#</cfoutput></div>
                        <div class="privacy-meta-value"><cfoutput>#REQUEST.t("privacy.metaCards.legalBasis.value")#</cfoutput></div>
                    </div>
                    <div class="privacy-meta-card">
                        <div class="privacy-meta-kicker"><cfoutput>#REQUEST.t("privacy.metaCards.officialChannel.label")#</cfoutput></div>
                        <div class="privacy-meta-value"><cfoutput>#REQUEST.t("privacy.metaCards.officialChannel.value")#</cfoutput></div>
                    </div>
                    <div class="privacy-meta-card">
                        <div class="privacy-meta-kicker"><cfoutput>#REQUEST.t("privacy.metaCards.scope.label")#</cfoutput></div>
                        <div class="privacy-meta-value"><cfoutput>#REQUEST.t("privacy.metaCards.scope.value")#</cfoutput></div>
                    </div>
                </div>

                <cfoutput>
                    <cfloop from="1" to="#arrayLen(privacyBlocks)#" index="privacyBlockIndex">
                        <cfset privacyBlock = privacyBlocks[privacyBlockIndex] />
                        <div class="privacy-block">
                            <h3>#privacyBlock.title#</h3>
                            <cfif structKeyExists(privacyBlock, "paragraphs")>
                                <cfloop from="1" to="#arrayLen(privacyBlock.paragraphs)#" index="paragraphIndex">
                                    <p>#privacyBlock.paragraphs[paragraphIndex]#</p>
                                </cfloop>
                            </cfif>
                            <cfif structKeyExists(privacyBlock, "listItems")>
                                <ul>
                                    <cfloop from="1" to="#arrayLen(privacyBlock.listItems)#" index="listItemIndex">
                                        <li>#privacyBlock.listItems[listItemIndex]#</li>
                                    </cfloop>
                                </ul>
                            </cfif>
                        </div>
                    </cfloop>
                </cfoutput>

                <div class="privacy-owner mt-4">
                    <strong><cfoutput>#REQUEST.t("privacy.entity.title")#</cfoutput></strong><br>
                    <cfoutput>#REQUEST.t("privacy.entity.copy")#</cfoutput>
                </div>
                <p class="privacy-note mt-4 mb-0"><cfoutput>#REQUEST.t("privacy.note")#</cfoutput></p>
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
