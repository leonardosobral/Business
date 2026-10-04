<cfprocessingdirective pageencoding="utf-8"/>

<style>
    .home-hero {
        color: #333333;
        max-height: 340px;
        opacity: 1;
        overflow: hidden;
        scroll-margin-top: 4.5rem;
        transform: translateY(0);
        transition:
            max-height 0.34s cubic-bezier(0.22, 0.8, 0.22, 1),
            opacity 0.22s ease,
            transform 0.34s cubic-bezier(0.22, 0.8, 0.22, 1),
            margin-bottom 0.34s cubic-bezier(0.22, 0.8, 0.22, 1);
        will-change: max-height, opacity, transform;
    }

    .home-hero.is-collapsed {
        max-height: 0;
        opacity: 0;
        margin-bottom: 0 !important;
        pointer-events: none;
        transform: translateY(-58px);
    }

    .home-hero-copy {
        color: #333333;
    }

    .home-hero-copy .home-hero-headline {
        font-size: clamp(1.8rem, 3.4vw, 2.55rem);
        font-weight: 500;
        line-height: 0.98;
        letter-spacing: -0.04em;
        color: #333333;
    }

    .home-hero-search .busca-shell {
        padding: 0 !important;
        border: 0;
        border-radius: 0;
        background: transparent;
    }

    .home-hero-search .input-group {
        border-radius: 10px;
        overflow: hidden;
        border: 0;
        background-color: transparent;
    }

    .home-hero-search .form-control-lg {
        min-height: 56px;
        font-size: 0.98rem;
        background-color: #ffffff;
        color: #333333;
    }

    .home-hero-search .btn {
        min-width: 68px;
        background-color: #fab120;
        border-color: #fab120;
        color: #333333;
    }

    .home-hero-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.15rem;
        padding: 0.58rem 0.82rem;
        border-radius: 999px;
        border: 1px solid rgba(51, 51, 51, 0.1);
        background-color: #ffffff;
        color: #333333;
        font-weight: 600;
        font-size: 0.88rem;
        line-height: 1;
        text-decoration: none;
        transition: border-color .18s ease, background-color .18s ease;
    }

    .home-hero-chip:hover {
        border-color: #fab120;
        background-color: #ffffff;
        color: #333333;
    }

    .home-hero-accent {
        color: #fab120 !important;
    }

    .home-hero-chip-row {
        display: flex;
        flex-wrap: wrap;
        gap: 0.2rem;
    }

    .home-hero-chip-select-wrap {
        position: relative;
        display: inline-flex;
        align-items: center;
        flex: 0 0 auto;
    }

    .home-hero-chip-select {
        appearance: none;
        -webkit-appearance: none;
        -moz-appearance: none;
        padding-left: 2.1rem;
        padding-right: 2.15rem;
        cursor: pointer;
    }

    .home-hero-chip-select-icon {
        position: absolute;
        left: 0.82rem;
        pointer-events: none;
        color: #fab120;
    }

    .home-hero-chip-select-caret {
        position: absolute;
        right: 0.82rem;
        pointer-events: none;
        color: #333333;
        font-size: 0.72rem;
    }

    @media (max-width: 767.98px) {
        .home-hero-copy .home-hero-headline {
            font-size: 1.9rem;
        }

        .home-hero-chip {
            padding: 0.48rem 0.72rem;
            font-size: 0.82rem;
            flex: 0 0 auto;
        }

        .home-hero-chip-row {
            flex-wrap: wrap;
            overflow-x: visible;
            padding-bottom: 0.25rem;
            scrollbar-width: none;
            -ms-overflow-style: none;
        }

        .home-hero-chip-row::-webkit-scrollbar {
            display: none;
        }

        .home-hero-chip-row .home-hero-chip:not(.home-hero-chip-select) {
            display: none;
        }

        .home-hero-chip-row .home-hero-chip.is-mobile-visible {
            display: inline-flex;
        }

        .home-hero-chip-select {
            width: 100%;
            padding-left: 2.35rem;
            padding-right: 2.45rem;
        }

        .home-hero-chip-select-wrap {
            flex: 1 0 100%;
            width: 100%;
        }

    }
</style>

<cfparam name="URL.estado" default=""/>
<cfset VARIABLES.heroEstadoSelecionado = len(trim(URL.estado)) ? uCase(trim(URL.estado)) : ""/>
<cfset VARIABLES.heroSearchPath = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("search") : "/busca/"/>
<cfset VARIABLES.heroStatePathTemplate = REQUEST.currentBaseUrl & "/estado/{tag}/"/>
<cfset VARIABLES.heroStateOptions = "AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO"/>
<cfset VARIABLES.heroStatePrepositions = {
    "AC" = "no",
    "AL" = "em",
    "AM" = "no",
    "AP" = "no",
    "BA" = "na",
    "CE" = "no",
    "DF" = "no",
    "ES" = "no",
    "GO" = "em",
    "MA" = "no",
    "MG" = "em",
    "MS" = "no",
    "MT" = "no",
    "PA" = "no",
    "PB" = "na",
    "PE" = "em",
    "PI" = "no",
    "PR" = "no",
    "RJ" = "no",
    "RN" = "no",
    "RO" = "em",
    "RR" = "em",
    "RS" = "no",
    "SC" = "em",
    "SE" = "em",
    "SP" = "em",
    "TO" = "no"
}/>
<cfset VARIABLES.heroStateNames = {
    "AC" = "Acre",
    "AL" = "Alagoas",
    "AM" = "Amazonas",
    "AP" = "Amapá",
    "BA" = "Bahia",
    "CE" = "Ceará",
    "DF" = "Distrito Federal",
    "ES" = "Espírito Santo",
    "GO" = "Goiás",
    "MA" = "Maranhão",
    "MG" = "Minas Gerais",
    "MS" = "Mato Grosso do Sul",
    "MT" = "Mato Grosso",
    "PA" = "Pará",
    "PB" = "Paraíba",
    "PE" = "Pernambuco",
    "PI" = "Piauí",
    "PR" = "Paraná",
    "RJ" = "Rio de Janeiro",
    "RN" = "Rio Grande do Norte",
    "RO" = "Rondônia",
    "RR" = "Roraima",
    "RS" = "Rio Grande do Sul",
    "SC" = "Santa Catarina",
    "SE" = "Sergipe",
    "SP" = "São Paulo",
    "TO" = "Tocantins"
}/>
<cfset VARIABLES.homeHeroStartsCollapsed = NOT (isDefined("VARIABLES.template") AND listFindNoCase("/,/busca/", trim(VARIABLES.template)) GT 0)/>
<cfset VARIABLES.homeHeroHeadlineOptions = []/>
<cfif structKeyExists(REQUEST, "i18n") AND structKeyExists(REQUEST.i18n, "search") AND structKeyExists(REQUEST.i18n.search, "hero") AND structKeyExists(REQUEST.i18n.search.hero, "headlineOptions") AND isArray(REQUEST.i18n.search.hero.headlineOptions)>
    <cfset VARIABLES.homeHeroHeadlineOptions = duplicate(REQUEST.i18n.search.hero.headlineOptions)/>
</cfif>
<cfif NOT arrayLen(VARIABLES.homeHeroHeadlineOptions)>
    <cfset VARIABLES.homeHeroHeadlineOptions = [REQUEST.t("search.hero.headline")]/>
</cfif>
<cfset VARIABLES.homeHeroHeadline = (isDefined("VARIABLES.template") AND VARIABLES.template EQ "/") ? REQUEST.homeDiscoveryText("headline") : VARIABLES.homeHeroHeadlineOptions[randRange(1, arrayLen(VARIABLES.homeHeroHeadlineOptions))]/>
<cfset VARIABLES.homeHeroUserUf = ""/>
<cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND REQUEST.Usuario.logado AND len(trim(REQUEST.Usuario.estado))>
    <cfset VARIABLES.homeHeroUserUf = uCase(trim(REQUEST.Usuario.estado))/>
<cfelseif structKeyExists(REQUEST, "LocationContext") AND isStruct(REQUEST.LocationContext)>
    <cfif structKeyExists(REQUEST.LocationContext, "uf") AND len(trim(REQUEST.LocationContext.uf))>
        <cfset VARIABLES.homeHeroUserUf = uCase(trim(REQUEST.LocationContext.uf))/>
    <cfelseif structKeyExists(REQUEST.LocationContext, "estado") AND len(trim(REQUEST.LocationContext.estado))>
        <cfset VARIABLES.homeHeroUserUf = uCase(trim(REQUEST.LocationContext.estado))/>
    </cfif>
</cfif>
<cfif NOT listFindNoCase(VARIABLES.heroStateOptions, VARIABLES.homeHeroUserUf)>
    <cfset VARIABLES.homeHeroUserUf = ""/>
</cfif>

<section class="home-hero mb-3<cfif VARIABLES.homeHeroStartsCollapsed> is-collapsed</cfif>" id="homeHeroSearch">

    <div class="row g-3 align-items-center">

        <div class="col-12 home-hero-copy">
            <cfif isDefined("VARIABLES.template") AND VARIABLES.template EQ "/">
                <h1 class="home-hero-headline mb-2">
                    <cfoutput>#HTMLEditFormat(VARIABLES.homeHeroHeadline)#</cfoutput>
                </h1>
            <cfelseif isDefined("VARIABLES.template") AND VARIABLES.template EQ "/busca/">
                <h1 class="h4 mb-2"><cfoutput>#HTMLEditFormat(REQUEST.t("search.legacy.heroTitle"))#</cfoutput></h1>
            <cfelse>
                <p class="home-hero-headline mb-2">
                    <cfoutput>#HTMLEditFormat(VARIABLES.homeHeroHeadline)#</cfoutput>
                </p>
            </cfif>

            <div class="home-hero-search mb-2">
                <cfinclude template="busca.cfm"/>
            </div>

            <div class="home-hero-chip-row">
                <a class="home-hero-chip is-mobile-visible" href="<cfoutput>#VARIABLES.heroSearchPath#</cfoutput>?distancia_inicio=5&distancia_fim=5&busca_mode=ai">
                    <i class="fa-solid fa-person-running home-hero-accent"></i>
                    5K
                </a>
                <a class="home-hero-chip is-mobile-visible" href="<cfoutput>#VARIABLES.heroSearchPath#</cfoutput>?distancia_inicio=10&distancia_fim=10&busca_mode=ai">
                    <i class="fa-solid fa-person-running home-hero-accent"></i>
                    10K
                </a>
                <a class="home-hero-chip" href="<cfoutput>#VARIABLES.heroSearchPath#</cfoutput>?distancia_inicio=15&distancia_fim=15&busca_mode=ai">
                    <i class="fa-solid fa-person-running home-hero-accent"></i>
                    15K
                </a>
                <a class="home-hero-chip is-mobile-visible" href="<cfoutput>#VARIABLES.heroSearchPath#</cfoutput>?distancia_inicio=21&distancia_fim=21&busca_mode=ai">
                    <i class="fa-solid fa-person-running home-hero-accent"></i>
                    21K
                </a>
                <a class="home-hero-chip" href="<cfoutput>#VARIABLES.heroSearchPath#</cfoutput>?distancia_inicio=30&distancia_fim=30&busca_mode=ai">
                    <i class="fa-solid fa-person-running home-hero-accent"></i>
                    30K
                </a>
                <a class="home-hero-chip is-mobile-visible" href="<cfoutput>#VARIABLES.heroSearchPath#</cfoutput>?distancia_inicio=42&distancia_fim=42&busca_mode=ai">
                    <i class="fa-solid fa-person-running home-hero-accent"></i>
                    42K
                </a>
                <cfif len(trim(VARIABLES.homeHeroUserUf))>
                    <a class="home-hero-chip is-mobile-visible" href="<cfoutput>#replace(VARIABLES.heroStatePathTemplate, '{tag}', lCase(VARIABLES.homeHeroUserUf), 'one')#</cfoutput>" aria-label="<cfoutput>#HTMLEditFormat(REQUEST.t("search.hero.eventsInState", { "state" = VARIABLES.heroStateNames[VARIABLES.homeHeroUserUf] }))#</cfoutput>">
                        <i class="fa-solid fa-location-dot home-hero-accent"></i>
                        <cfoutput>#VARIABLES.homeHeroUserUf#</cfoutput>
                    </a>
                </cfif>
                <div class="home-hero-chip-select-wrap">
                    <i class="fa-solid fa-location-dot home-hero-chip-select-icon" aria-hidden="true"></i>
                    <select class="home-hero-chip home-hero-chip-select"
                            aria-label="<cfoutput>#HTMLEditFormat(REQUEST.t("search.hero.stateSelectAria"))#</cfoutput>"
                            onchange="if(this.value){window.location.assign('<cfoutput>#JSStringFormat(VARIABLES.heroStatePathTemplate)#</cfoutput>'.replace('{tag}', encodeURIComponent(String(this.value).trim().toLowerCase())));}">
                        <option value="" <cfif NOT len(trim(VARIABLES.heroEstadoSelecionado))>selected</cfif>><cfoutput>#REQUEST.t("search.hero.stateSelectDefault")#</cfoutput></option>
                        <cfoutput>
                            <cfloop list="#VARIABLES.heroStateOptions#" index="heroStateOption">
                                <option value="#heroStateOption#" <cfif VARIABLES.heroEstadoSelecionado EQ heroStateOption>selected</cfif>>#VARIABLES.heroStateNames[heroStateOption]#</option>
                            </cfloop>
                        </cfoutput>
                    </select>
                    <i class="fa-solid fa-chevron-down home-hero-chip-select-caret" aria-hidden="true"></i>
                </div>
            </div>
        </div>

    </div>

</section>

<script>
    (function () {
        const initHomeHeroToggle = function () {
            const hero = document.getElementById('homeHeroSearch');
            const toggles = Array.from(document.querySelectorAll('[data-home-hero-toggle], [data-home-hero-open]'));

            if (!hero || !toggles.length) {
                return;
            }

            const setExpanded = function (expanded) {
                hero.classList.toggle('is-collapsed', !expanded);
                toggles.forEach(function (toggle) {
                    toggle.setAttribute('aria-expanded', expanded ? 'true' : 'false');
                });
            };

            setExpanded(!hero.classList.contains('is-collapsed'));

            toggles.forEach(function (toggle) {
                toggle.addEventListener('click', function (event) {
                    if (toggle.hasAttribute('data-home-hero-open')) {
                        event.preventDefault();
                    }

                    const shouldExpand = toggle.hasAttribute('data-home-hero-open')
                        ? true
                        : hero.classList.contains('is-collapsed');

                    setExpanded(shouldExpand);

                    if (shouldExpand) {
                        const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
                        const searchInput = hero.querySelector('#busca-input-plain');

                        window.scrollTo({
                            top: 0,
                            left: 0,
                            behavior: reduceMotion ? 'auto' : 'smooth'
                        });

                        if (searchInput) {
                            window.setTimeout(function () {
                                searchInput.focus({ preventScroll: true });
                            }, reduceMotion ? 0 : 260);
                        }
                    }
                });
            });
        };

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function () {
                initHomeHeroToggle();
            }, { once: true });
        } else {
            initHomeHeroToggle();
        }
    })();
</script>
