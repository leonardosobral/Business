<style>
    .or-topbar-offset {
        top: 30px;
    }

    .or-topbar.navbar {
        background-color: #DDDDDD !important;
        box-shadow: 0 1px 6px rgba(0, 0, 0, 0.06) !important;
    }

    .or-topbar .nav-item.border-start {
        border-color: rgba(51, 51, 51, 0.12) !important;
    }

    .or-topbar .nav-link,
    .or-topbar .navbar-brand,
    .or-topbar .link-light,
    .or-topbar .link-dark,
    .or-topbar #legend {
        color: #333333 !important;
    }

    .or-topbar .nav-link:hover,
    .or-topbar .navbar-brand:hover,
    .or-topbar .link-dark:hover {
        color: #111111 !important;
    }

</style>

<cfif NOT isDefined("Usuario")>
    <cfset Usuario = {logado = false, tag = ""}/>
</cfif>
<cfif NOT structKeyExists(REQUEST, "Usuario")>
    <cfset REQUEST.Usuario = Usuario/>
</cfif>
<cfif NOT structKeyExists(REQUEST, "currentBaseUrl")>
    <cfset REQUEST.currentBaseUrl = "https://roadrunners.run"/>
</cfif>
<cfif NOT structKeyExists(REQUEST, "currentRouteParams") OR NOT isStruct(REQUEST.currentRouteParams)>
    <cfset REQUEST.currentRouteParams = {}/>
</cfif>
<cfif NOT structKeyExists(REQUEST, "i18n")>
    <cfset REQUEST.i18n = {}/>
</cfif>
<cfif NOT structKeyExists(REQUEST.i18n, "common")>
    <cfset REQUEST.i18n.common = {}/>
</cfif>
<cfif NOT structKeyExists(REQUEST.i18n.common, "appsMenu")>
    <cfset REQUEST.i18n.common.appsMenu = {
        title = "Runner Apps",
        roadRunners = "Road Runners",
        roadRunnersAlt = "Road Runners",
        openResults = "Open Results",
        openResultsAlt = "Open Results",
        runnersStore = "Runners Store",
        runnersStoreAlt = "Runners Store",
        desafioSupra = "Brasil Gigante",
        desafioSupraAlt = "Brasil Gigante",
        circuitoCatarinense = "Circuito Catarinense",
        circuitoCatarinenseAlt = "Circuito Catarinense",
        todoSantoDia = "Todo Santo Dia",
        todoSantoDiaAlt = "Todo Santo Dia",
        poweredBy = "Powered by"
    }/>
</cfif>
<cfif NOT structKeyExists(REQUEST, "i18nBuildPath")>
    <cfscript>
        REQUEST.i18nBuildPath = function(route) {
            switch (route) {
                case "home":
                    return "/";
                case "athlete":
                    return "/atleta/";
                default:
                    return "/";
            }
        };
    </cfscript>
</cfif>

<cfinclude template="../../roadrunners.com.br/includes/estrutura/header_minimal.cfm"/>

<header class="fixed-top or-topbar-offset">
    <nav class="navbar navbar-expand-lg navbar-light or-topbar" style="cursor: default">
        <div class="container">
            <a class="navbar-brand m-0 p-0 me-2" href="/">
                <img src="/assets/or_logo.svg" height="32" alt="Open Results" loading="lazy"/>
            </a>

            <ul class="navbar-nav ms-2 me-auto d-none d-md-flex flex-row">
                <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                    onmouseover="showLegent(this)" onmouseout="hideLegent()" title="Busca"
                    data-mdb-animation-init
                    data-mdb-animation-target="#legend">
                    <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/">active</cfif>" href="/"><i class="fa-solid fa-magnifying-glass"></i></a>
                </li>
                <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                    onmouseover="showLegent(this)" onmouseout="hideLegent()" title="Ranking"
                    data-mdb-animation-init
                    data-mdb-animation-target="#legend">
                    <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/ranking/">active</cfif>" href="/ranking/"><i class="fa-solid fa-ranking-star"></i></a>
                </li>
                <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                    onmouseover="showLegent(this)" onmouseout="hideLegent()" title="Estatísticas"
                    data-mdb-animation-init
                    data-mdb-animation-target="#legend">
                    <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/estatisticas/">active</cfif>" href="/estatisticas/"><i class="fa-solid fa-chart-simple"></i></a>
                </li>
                <li class="nav-item border-start border-dark border-opacity-10 ps-2 align-content-center overflow-hidden">
                    <div id="legend" class="z-n1"
                         data-mdb-animation="fade-in-left"
                         data-mdb-animation-start="onHover"
                         data-mdb-animation-reset="true"></div>
                    <script>
                        function showLegent(item) {
                            document.getElementById("legend").innerHTML = item.title;
                        }
                        function hideLegent() {
                            document.getElementById("legend").innerHTML = "";
                        }
                    </script>
                </li>
            </ul>

            <div class="d-flex align-items-center gap-3">
                <div class="btn-group shadow-0">
                    <a href="#" class="link-dark <cfif VARIABLES.template EQ "/sobre/" OR VARIABLES.template EQ "/ajuda/" OR VARIABLES.template EQ "/privacidade/" OR VARIABLES.template EQ "/proximas-provas/">active</cfif>" data-mdb-dropdown-init data-mdb-ripple-init aria-expanded="false" id="dropdownMenuSite">
                        <i class="fa-solid fa-bars"></i>
                    </a>
                    <ul class="dropdown-menu dropdown-menu-lg-end" aria-labelledby="dropdownMenuSite">
                        <li>
                            <a class="dropdown-item <cfif VARIABLES.template EQ "/proximas-provas/">active</cfif>" href="/proximas-provas/">
                                <i class="fa-solid fa-calendar-days me-2" aria-hidden="true"></i>Próximas provas
                            </a>
                        </li>
                        <li>
                            <a class="dropdown-item <cfif VARIABLES.template EQ "/sobre/">active</cfif>" href="/sobre/">
                                <i class="fa-solid fa-circle-info me-2"></i>Sobre
                            </a>
                        </li>
                        <li>
                            <a class="dropdown-item <cfif VARIABLES.template EQ "/privacidade/">active</cfif>" href="/privacidade/">
                                <i class="fa-solid fa-shield-halved me-2"></i>Privacidade
                            </a>
                        </li>
                        <li>
                            <a class="dropdown-item" href="https://roadrunners.run/ajuda/?utm_source=openresults&amp;utm_medium=referral&amp;utm_campaign=openresults_to_roadrunners&amp;utm_content=ajuda_menu" data-rr-placement="ajuda_menu">
                                <i class="fa-solid fa-circle-question me-2"></i>Ajuda
                            </a>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </nav>
</header>

<cfset VARIABLES.mobileSearchActive = listFindNoCase("/,/busca/,/resultados/,/evento/", VARIABLES.template) GT 0/>
<cfset VARIABLES.mobileRankingActive = left(VARIABLES.template, 9) EQ "/ranking/"/>
<cfset VARIABLES.mobileStatsActive = VARIABLES.template EQ "/estatisticas/"/>

<nav class="or-mobile-nav" id="orMobileNav" aria-label="Navegação principal mobile">
    <ul class="or-mobile-nav-items">
        <li>
            <a class="or-mobile-nav-link<cfif VARIABLES.mobileSearchActive> active</cfif>" href="/" <cfif VARIABLES.mobileSearchActive>aria-current="location"</cfif>>
                <span class="or-mobile-nav-symbol"><i class="fa-solid fa-magnifying-glass" aria-hidden="true"></i></span>
                <span class="or-mobile-nav-label">Buscar</span>
            </a>
        </li>
        <li>
            <a class="or-mobile-nav-link<cfif VARIABLES.mobileRankingActive> active</cfif>" href="/ranking/" <cfif VARIABLES.mobileRankingActive>aria-current="location"</cfif>>
                <span class="or-mobile-nav-symbol"><i class="fa-solid fa-ranking-star" aria-hidden="true"></i></span>
                <span class="or-mobile-nav-label">Ranking</span>
            </a>
        </li>
        <li>
            <a class="or-mobile-nav-link<cfif VARIABLES.mobileStatsActive> active</cfif>" href="/estatisticas/" <cfif VARIABLES.mobileStatsActive>aria-current="location"</cfif>>
                <span class="or-mobile-nav-symbol"><i class="fa-solid fa-chart-simple" aria-hidden="true"></i></span>
                <span class="or-mobile-nav-label">Estatísticas</span>
            </a>
        </li>
        <li class="or-mobile-nav-partner">
            <a class="or-mobile-nav-link" href="https://roadrunners.run/?utm_source=openresults&amp;utm_medium=referral&amp;utm_campaign=openresults_to_roadrunners&amp;utm_content=menu_mobile_roadrunners" target="_blank" rel="noopener" data-rr-placement="menu_mobile_roadrunners" aria-label="Road Runners, abre em nova aba" aria-haspopup="dialog" aria-controls="orRoadRunnersModal">
                <span class="or-mobile-nav-symbol"><img src="/assets/rr_icon.svg" alt="" class="or-mobile-nav-icon"/></span>
                <span class="or-mobile-nav-label">Road Runners</span>
            </a>
        </li>
    </ul>
</nav>
<script src="/assets/js/mobile-nav.js?v=<cfoutput>#VARIABLES.cssVersion#</cfoutput>" defer></script>

<div class="my-3 py-3"></div>
