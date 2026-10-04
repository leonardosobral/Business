<!--- DEV MODE --->

<cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario)>
    <cfset Usuario = REQUEST.Usuario>
<cfelse>
    <cfset Usuario = createObject("component", "includes.models.Usuario")>
</cfif>

<cfif VARIABLES.devMode>
    <cfif structKeyExists(SESSION, "devAuth")
        AND isStruct(SESSION.devAuth)
        AND structKeyExists(SESSION.devAuth, "originalUsuarioId")
        AND isValid("integer", SESSION.devAuth.originalUsuarioId)>
        <cfquery name="qCheckOriginalId" result="qCheckOriginalIdMeta">
            select is_admin, is_dev from tb_usuarios
            where id = <cfqueryparam cfsqltype="cf_sql_integer" value="#SESSION.devAuth.originalUsuarioId#"/>
        </cfquery>
        <cfset logQueryDebug("qCheckOriginalId", qCheckOriginalIdMeta, "header/check_original_id", "sem cache", qCheckOriginalId)/>
    <cfelse>
        <cflocation statuscode="301" url="#APPLICATION.baseCanonica#" addtoken="false"/>
    </cfif>
    <cfif Usuario.logado AND ( BooleanFormat(qCheckOriginalId.is_admin) OR BooleanFormat(qCheckOriginalId.is_dev) )>
    <cfelse>
        <cflocation statuscode="301" url="#APPLICATION.baseCanonica#" addtoken="false"/>
    </cfif>
</cfif>

<!--- HEADER --->

<cfset VARIABLES.headerI18nRouteKey = ""/>
<cfset VARIABLES.headerHomeTitle = REQUEST.t("common.header.home") />
<cfset VARIABLES.headerSearchTitle = REQUEST.t("common.header.search") />
<cfset VARIABLES.headerActivitiesTitle = REQUEST.t("common.header.activities") />
<cfset VARIABLES.headerEventsTitle = REQUEST.t("common.header.events") />
<cfif VARIABLES.headerActivitiesTitle EQ "common.header.activities">
    <cfset VARIABLES.headerActivitiesTitle = REQUEST.lang EQ "en" ? "Activities" : (REQUEST.lang EQ "es" ? "Actividades" : "Atividades") />
</cfif>
<cfset VARIABLES.headerAgendaTitle = REQUEST.t("athlete.tabs.agenda") />
<cfset VARIABLES.headerResultsTitle = REQUEST.t("athlete.tabs.results") />
<cfset VARIABLES.headerChallengesTitle = REQUEST.t("athlete.tabs.challenges") />
<cfset VARIABLES.headerNewsTitle = REQUEST.t("news.hero.title") />
<cfset VARIABLES.headerVideosTitle = REQUEST.t("videos.hero.title") />
<cfset VARIABLES.headerHomePath = REQUEST.i18nBuildPath("home") />
<cfset VARIABLES.headerSearchPath = REQUEST.i18nBuildPath("search") />
<cfset VARIABLES.headerActivitiesPath = REQUEST.i18nBuildPath("feed") />
<cfset VARIABLES.headerEventsPath = REQUEST.currentBaseUrl & "/estado/" />
<cfset VARIABLES.headerAgendaPath = REQUEST.i18nBuildPath("agenda") />
<cfset VARIABLES.headerResultsPath = REQUEST.i18nBuildPath("results") />
<cfset VARIABLES.headerChallengesPath = REQUEST.i18nBuildPath("challenges") />
<cfset VARIABLES.headerNewsPath = REQUEST.i18nBuildPath("news") />
<cfset VARIABLES.headerVideosPath = REQUEST.i18nBuildPath("videos") />
<cfset VARIABLES.headerBetaPath = REQUEST.i18nBuildPath("betaLanding") />
<cfset VARIABLES.headerUserSettingsPath = REQUEST.i18nBuildPath("profileSettings") />
<cfset VARIABLES.headerCurrentHost = lCase(trim(CGI.HTTP_HOST)) />
<cfset VARIABLES.headerIsBetaEnvironment = (structKeyExists(REQUEST, "currentEnvironment") AND REQUEST.currentEnvironment EQ "beta" AND VARIABLES.headerCurrentHost CONTAINS "beta.") />
<cfset VARIABLES.headerUserProfilePath = "" />

<cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND REQUEST.Usuario.logado AND len(trim(REQUEST.Usuario.tag))>
    <!--- A ROTA ATUAL TAMBEM PODE USAR "tag" (EX.: /estado/{uf}); FORCA A TAG DO USUARIO PARA O LINK DO AVATAR. --->
    <cfset VARIABLES.headerUserProfileRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : {} />
    <cfset REQUEST.currentRouteParams = duplicate(VARIABLES.headerUserProfileRouteParams) />
    <cfset REQUEST.currentRouteParams["tag"] = trim(REQUEST.Usuario.tag) />
    <cfset VARIABLES.headerUserProfilePath = REQUEST.i18nBuildPath("athlete") />
    <cfset REQUEST.currentRouteParams = VARIABLES.headerUserProfileRouteParams />
</cfif>

<cfif structKeyExists(REQUEST, "currentRouteKey") AND len(trim(REQUEST.currentRouteKey))>
    <cfset VARIABLES.headerI18nRouteKey = trim(REQUEST.currentRouteKey)/>
<cfelseif structKeyExists(VARIABLES, "routeKey") AND len(trim(VARIABLES.routeKey))>
    <cfset VARIABLES.headerI18nRouteKey = trim(VARIABLES.routeKey)/>
</cfif>

<cfset VARIABLES.headerHomeHeroTemplates = "/,/404/,/agenda/,/ajuda/,/atendimento/,/atleta/,/atividades/,/beta/,/calendario/,/canal/,/carteira/,/circuito/,/desafios/,/estado/,/evento/,/login/,/maratona/,/maratonas/,/noticias/,/org/,/perfil/,/privacidade/,/resultados/,/sobre/,/timer/,/videos/" />
<cfset VARIABLES.headerHasHomeHeroToggle = structKeyExists(VARIABLES, "template") AND listFindNoCase(VARIABLES.headerHomeHeroTemplates, trim(VARIABLES.template)) GT 0 />

<style>
    .rr-topbar.navbar {
        --rr-desktop-active-x: 0px;
        --rr-desktop-active-width: 0px;
        --rr-desktop-active-opacity: 0;
        background-color: #DDDDDD !important;
        box-shadow: 0 1px 6px rgba(0, 0, 0, 0.06) !important;
        position: relative;
    }

    @media (min-width: 768px) {
        .rr-topbar.navbar::before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            width: var(--rr-desktop-active-width);
            height: 2px;
            border-radius: 0 0 999px 999px;
            background: #f4b120;
            opacity: var(--rr-desktop-active-opacity);
            pointer-events: none;
            transform: translate3d(var(--rr-desktop-active-x), 0, 0);
            transition: none;
            z-index: 2;
        }

        .rr-topbar.navbar.is-desktop-indicator-ready::before {
            transition: transform 180ms cubic-bezier(0.22, 0.8, 0.22, 1), width 180ms cubic-bezier(0.22, 0.8, 0.22, 1), opacity 120ms ease;
        }
    }

    .rr-topbar .nav-item.border-start,
    .rr-topbar .nav-item.border-end {
        border-color: rgba(51, 51, 51, 0.12) !important;
    }

    .rr-topbar .link-light,
    .rr-topbar .nav-link,
    .rr-topbar #legend,
    .rr-topbar .navbar-brand {
        color: #333333 !important;
    }

    .rr-topbar .link-light:hover,
    .rr-topbar .nav-link:hover,
    .rr-topbar .link-opacity-100-hover:hover {
        color: #111111 !important;
    }

    .rr-topbar .navbar-brand svg path[fill="#ffffff"],
    .rr-topbar .navbar-brand svg g[fill="#ffffff"] {
        fill: #333333 !important;
    }

    .rr-topbar .navbar-brand:hover svg path[fill="#ffffff"],
    .rr-topbar .navbar-brand:hover svg g[fill="#ffffff"] {
        fill: #111111 !important;
    }

    .rr-topbar .navbar-brand svg path[fill="#f4b120"],
    .rr-topbar .navbar-brand svg g[fill="#f4b120"] {
        fill: #f4b120 !important;
    }

    .rr-topbar .rr-topbar-nav-toggle {
        appearance: none;
        border: 0;
        background: transparent;
        cursor: pointer;
    }

    .rr-topbar .rr-topbar-nav-toggle:focus {
        box-shadow: none;
        outline: none;
    }

    .rr-topbar-beta-link {
        width: 1.95rem;
        height: 1.95rem;
        border-radius: 999px;
        border: 1px solid rgba(244, 177, 32, 0.9);
        color: #333333 !important;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        transition: background-color .18s ease, color .18s ease, border-color .18s ease;
    }

    .rr-topbar-beta-link:hover,
    .rr-topbar-beta-link:focus {
        background-color: rgba(244, 177, 32, 0.12);
        border-color: #f4b120;
        color: #111111 !important;
    }

    .rr-topbar-hero-toggle {
        width: 1.95rem;
        height: 1.95rem;
        border: 1px solid rgba(51, 51, 51, 0.12);
        border-radius: 999px;
        background-color: rgba(255, 255, 255, 0.55);
        color: #333333;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        transition: background-color .18s ease, color .18s ease, border-color .18s ease;
    }

    .rr-topbar-hero-toggle:hover,
    .rr-topbar-hero-toggle:focus {
        background-color: rgba(244, 177, 32, 0.12);
        border-color: #f4b120;
        color: #111111;
        box-shadow: none;
    }

    .rr-topbar-hero-toggle[aria-expanded="false"] {
        background-color: #f4b120;
        border-color: #f4b120;
        color: #333333;
    }

    @media (max-width: 767.98px) {
        .rr-topbar-hero-toggle {
            display: none;
        }
    }

    .rr-topbar-user-avatar {
        width: 28px;
        height: 28px;
        border-radius: 999px;
        object-fit: cover;
        border: 1px solid rgba(51, 51, 51, 0.16);
        background-color: #ffffff;
        display: block;
    }

    .rr-notification-item {
        display: flex;
        align-items: flex-start;
        gap: .6rem;
        white-space: normal;
    }

    .rr-notification-item-icon {
        flex: 0 0 auto;
        line-height: 1.2;
        margin-top: .1rem;
    }

    .rr-notification-item-text {
        flex: 1 1 auto;
        min-width: 0;
        line-height: 1.35;
    }

    .rr-notification-item-timestamp {
        display: block;
        margin-top: .2rem;
        color: rgba(51, 51, 51, .52);
        font-size: .65rem;
        font-weight: 500;
        line-height: 1.2;
    }

    .rr-notification-item-timestamp:empty {
        display: none;
    }

    .rr-chat-header-name {
        display: inline-flex;
        align-items: center;
        max-width: 100%;
        gap: .3rem;
    }

    .rr-chat-header-name strong {
        min-width: 0;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .rr-chat-header-name .rr-user-status-icon {
        display: inline-flex;
        flex: 0 0 auto;
    }

    .rr-notification-item.is-read,
    .rr-notification-item.is-read:hover,
    .rr-notification-item.is-read:focus {
        background-color: #f5f5f5;
    }

    .rr-notification-item.is-read .rr-notification-item-icon,
    .rr-notification-item.is-read .rr-notification-item-text {
        opacity: .5;
    }

    .rr-notifications-menu {
        width: min(19rem, calc(100vw - 1rem));
        min-width: 16rem;
        max-width: calc(100vw - 1rem);
        right: 0;
        left: auto;
    }

    .rr-notification-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: .25rem .4rem .25rem .25rem;
    }

    .rr-notification-header .dropdown-header {
        padding-top: .35rem;
        padding-bottom: .35rem;
    }

    .rr-notification-actions {
        display: inline-flex;
        align-items: center;
        gap: .35rem;
    }

    .rr-notification-action {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 1.75rem;
        height: 1.75rem;
        padding: 0;
        border: 0;
        border-radius: 50%;
        color: rgba(51, 51, 51, .58);
        background: transparent;
        font-size: .72rem;
    }

    .rr-notification-action:hover,
    .rr-notification-action:focus {
        color: #333333;
        background-color: rgba(51, 51, 51, .08);
    }

    .rr-notification-action:disabled {
        color: rgba(51, 51, 51, .25);
        background: transparent;
    }

    .rr-chat-new-action {
        border-radius: 4px;
    }

    .rr-topbar-right-menu {
        right: 0;
        left: auto;
    }

    .rr-language-switch {
        display: inline-flex;
        align-items: center;
        gap: 0.15rem;
        padding: 0.12rem;
        border-radius: 999px;
        border: 1px solid rgba(51, 51, 51, 0.12);
        background-color: rgba(255, 255, 255, 0.55);
    }

    .rr-language-switch-link {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        min-width: 2rem;
        height: 1.65rem;
        padding: 0 0.45rem;
        border-radius: 999px;
        color: #333333 !important;
        font-size: 0.68rem;
        font-weight: 800;
        letter-spacing: 0.03em;
        text-decoration: none;
        transition: background-color .18s ease, color .18s ease;
    }

    .rr-language-switch-link:hover,
    .rr-language-switch-link:focus {
        background-color: rgba(0, 0, 0, 0.06);
        color: #111111 !important;
        text-decoration: none;
    }

    .rr-language-switch-link.is-active {
        background-color: #333333;
        color: #ffffff !important;
    }

    @media (max-width: 767.98px) {
        .rr-notifications-menu {
            min-width: 0;
            width: min(17rem, calc(100vw - 1rem));
        }

    }
</style>

<header class="fixed-top">

    <!--- RUHHERHUB NAVBAR --->

    <nav class="navbar navbar-expand-lg navbar-light rr-topbar" style="cursor: default">

        <div class="container">
            <a class="navbar-brand m-0 p-0" href="<cfoutput>#VARIABLES.headerHomePath#</cfoutput>">
                <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="90" zoomAndPan="magnify" viewBox="0 0 824.88 239.999995" height="26" preserveAspectRatio="xMidYMid meet" version="1.0"><defs><g/><clipPath id="bab4ad45e0"><path d="M 9 0.015625 L 815 0.015625 L 815 239.980469 L 9 239.980469 Z M 9 0.015625 " clip-rule="nonzero"/></clipPath><clipPath id="df0878b42f"><path d="M 0.839844 107 L 664 107 L 664 239.980469 L 0.839844 239.980469 Z M 0.839844 107 " clip-rule="nonzero"/></clipPath><clipPath id="58960c6a62"><rect x="0" width="664" y="0" height="133"/></clipPath><clipPath id="aab0ee5e67"><path d="M 279 0.015625 L 682 0.015625 L 682 136 L 279 136 Z M 279 0.015625 " clip-rule="nonzero"/></clipPath><clipPath id="3b97b1fa0c"><rect x="0" width="403" y="0" height="136"/></clipPath><clipPath id="8174243e21"><path d="M 683 0.015625 L 805.679688 0.015625 L 805.679688 239.980469 L 683 239.980469 Z M 683 0.015625 " clip-rule="nonzero"/></clipPath><clipPath id="d491d5ed37"><rect x="0" width="123" y="0" height="240"/></clipPath><clipPath id="25b00bbd09"><rect x="0" width="806" y="0" height="240"/></clipPath></defs><g clip-path="url(#bab4ad45e0)"><g transform="matrix(1, 0, 0, 1, 9, 0.000000000000043396)"><g clip-path="url(#25b00bbd09)"><g clip-path="url(#df0878b42f)"><g transform="matrix(1, 0, 0, 1, 0, 107)"><g clip-path="url(#58960c6a62)"><g fill="#ffffff" fill-opacity="1"><g transform="translate(1.457115, 125.794645)"><g><path d="M 86.46875 -3.5 C 86.644531 -3.070312 86.734375 -2.550781 86.734375 -1.9375 C 86.734375 -0.644531 85.910156 0 84.265625 0 L 59.109375 0 C 58.160156 0 57.425781 -0.234375 56.90625 -0.703125 C 56.394531 -1.179688 56.007812 -2.070312 55.75 -3.375 L 48.21875 -36.8125 C 48.050781 -37.332031 47.859375 -37.703125 47.640625 -37.921875 C 47.421875 -38.140625 46.96875 -38.25 46.28125 -38.25 L 38.5 -38.25 C 37.8125 -38.25 37.335938 -38.117188 37.078125 -37.859375 C 36.816406 -37.597656 36.644531 -37.207031 36.5625 -36.6875 L 31.765625 -2.984375 C 31.585938 -1.679688 31.175781 -0.859375 30.53125 -0.515625 C 29.882812 -0.171875 28.738281 0 27.09375 0 L 5.3125 0 C 3.0625 0 2.113281 -1.335938 2.46875 -4.015625 L 15.171875 -93.984375 C 15.253906 -94.941406 15.445312 -95.546875 15.75 -95.796875 C 16.050781 -96.054688 16.59375 -96.1875 17.375 -96.1875 L 60.671875 -96.1875 C 72.160156 -96.1875 81.082031 -94.003906 87.4375 -89.640625 C 93.789062 -85.273438 96.96875 -79.207031 96.96875 -71.4375 C 96.96875 -65.125 95.128906 -59.285156 91.453125 -53.921875 C 87.785156 -48.566406 83.015625 -44.722656 77.140625 -42.390625 C 76.015625 -41.960938 75.34375 -41.570312 75.125 -41.21875 C 74.90625 -40.875 74.882812 -40.398438 75.0625 -39.796875 Z M 54.0625 -57.5625 C 57.601562 -57.5625 60.5625 -58.769531 62.9375 -61.1875 C 65.3125 -63.601562 66.5 -66.410156 66.5 -69.609375 C 66.5 -72.035156 65.613281 -73.875 63.84375 -75.125 C 62.070312 -76.375 59.804688 -77 57.046875 -77 L 43.8125 -77 C 43.207031 -77 42.773438 -76.828125 42.515625 -76.484375 C 42.265625 -76.140625 42.050781 -75.445312 41.875 -74.40625 L 39.671875 -59.5 L 39.671875 -58.859375 C 39.671875 -58.335938 39.773438 -57.988281 39.984375 -57.8125 C 40.203125 -57.644531 40.570312 -57.5625 41.09375 -57.5625 Z M 54.0625 -57.5625 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(97.264608, 125.794645)"><g><path d="M 89.0625 -37.203125 C 87.070312 -23.035156 82.207031 -13.078125 74.46875 -7.328125 C 66.738281 -1.578125 56.304688 1.296875 43.171875 1.296875 C 30.035156 1.296875 20.523438 -1.359375 14.640625 -6.671875 C 8.765625 -11.992188 5.828125 -19.878906 5.828125 -30.328125 C 5.828125 -33.179688 6.128906 -36.859375 6.734375 -41.359375 L 14.125 -93.984375 C 14.21875 -94.941406 14.414062 -95.546875 14.71875 -95.796875 C 15.019531 -96.054688 15.554688 -96.1875 16.328125 -96.1875 L 40.96875 -96.1875 C 41.75 -96.1875 42.375 -95.816406 42.84375 -95.078125 C 43.320312 -94.347656 43.472656 -93.550781 43.296875 -92.6875 L 35.515625 -36.6875 C 35.171875 -33.925781 35 -32.066406 35 -31.109375 C 35 -26.878906 35.945312 -23.851562 37.84375 -22.03125 C 39.75 -20.21875 42.5625 -19.3125 46.28125 -19.3125 C 51.03125 -19.3125 55.113281 -20.84375 58.53125 -23.90625 C 61.945312 -26.976562 64.128906 -31.890625 65.078125 -38.640625 L 72.859375 -93.984375 C 72.941406 -94.941406 73.132812 -95.546875 73.4375 -95.796875 C 73.738281 -96.054688 74.28125 -96.1875 75.0625 -96.1875 L 94.515625 -96.1875 C 95.285156 -96.1875 95.90625 -95.816406 96.375 -95.078125 C 96.851562 -94.347656 97.007812 -93.550781 96.84375 -92.6875 Z M 89.0625 -37.203125 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(191.646002, 125.794645)"><g><path d="M 98.78125 -96.1875 C 99.988281 -96.1875 100.507812 -95.5 100.34375 -94.125 L 87.25 -1.5625 C 87.164062 -0.945312 86.925781 -0.53125 86.53125 -0.3125 C 86.144531 -0.101562 85.519531 0 84.65625 0 L 66.890625 0 C 66.285156 0 65.765625 -0.191406 65.328125 -0.578125 C 64.898438 -0.972656 64.382812 -1.644531 63.78125 -2.59375 L 34.609375 -50.953125 C 34.347656 -51.378906 34.09375 -51.59375 33.84375 -51.59375 C 33.320312 -51.59375 33.015625 -51.03125 32.921875 -49.90625 L 26.1875 -2.46875 C 26.101562 -1.425781 25.863281 -0.753906 25.46875 -0.453125 C 25.082031 -0.148438 24.285156 0 23.078125 0 L 4.40625 0 C 2.757812 0 2.066406 -1.125 2.328125 -3.375 L 15.171875 -93.984375 C 15.253906 -94.941406 15.46875 -95.546875 15.8125 -95.796875 C 16.15625 -96.054688 16.804688 -96.1875 17.765625 -96.1875 L 38.890625 -96.1875 C 39.835938 -96.1875 40.59375 -95.945312 41.15625 -95.46875 C 41.71875 -95 42.300781 -94.25 42.90625 -93.21875 L 68.1875 -50.171875 C 68.625 -49.484375 69.054688 -49.140625 69.484375 -49.140625 C 69.742188 -49.140625 69.984375 -49.289062 70.203125 -49.59375 C 70.421875 -49.894531 70.570312 -50.300781 70.65625 -50.8125 L 76.75 -94.25 C 76.832031 -95.113281 77.046875 -95.648438 77.390625 -95.859375 C 77.734375 -96.078125 78.382812 -96.1875 79.34375 -96.1875 Z M 98.78125 -96.1875 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(290.305695, 125.794645)"><g><path d="M 98.78125 -96.1875 C 99.988281 -96.1875 100.507812 -95.5 100.34375 -94.125 L 87.25 -1.5625 C 87.164062 -0.945312 86.925781 -0.53125 86.53125 -0.3125 C 86.144531 -0.101562 85.519531 0 84.65625 0 L 66.890625 0 C 66.285156 0 65.765625 -0.191406 65.328125 -0.578125 C 64.898438 -0.972656 64.382812 -1.644531 63.78125 -2.59375 L 34.609375 -50.953125 C 34.347656 -51.378906 34.09375 -51.59375 33.84375 -51.59375 C 33.320312 -51.59375 33.015625 -51.03125 32.921875 -49.90625 L 26.1875 -2.46875 C 26.101562 -1.425781 25.863281 -0.753906 25.46875 -0.453125 C 25.082031 -0.148438 24.285156 0 23.078125 0 L 4.40625 0 C 2.757812 0 2.066406 -1.125 2.328125 -3.375 L 15.171875 -93.984375 C 15.253906 -94.941406 15.46875 -95.546875 15.8125 -95.796875 C 16.15625 -96.054688 16.804688 -96.1875 17.765625 -96.1875 L 38.890625 -96.1875 C 39.835938 -96.1875 40.59375 -95.945312 41.15625 -95.46875 C 41.71875 -95 42.300781 -94.25 42.90625 -93.21875 L 68.1875 -50.171875 C 68.625 -49.484375 69.054688 -49.140625 69.484375 -49.140625 C 69.742188 -49.140625 69.984375 -49.289062 70.203125 -49.59375 C 70.421875 -49.894531 70.570312 -50.300781 70.65625 -50.8125 L 76.75 -94.25 C 76.832031 -95.113281 77.046875 -95.648438 77.390625 -95.859375 C 77.734375 -96.078125 78.382812 -96.1875 79.34375 -96.1875 Z M 98.78125 -96.1875 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(388.965345, 125.794645)"><g><path d="M 15.171875 -93.984375 C 15.253906 -94.941406 15.445312 -95.546875 15.75 -95.796875 C 16.050781 -96.054688 16.59375 -96.1875 17.375 -96.1875 L 87.890625 -96.1875 C 89.191406 -96.1875 89.84375 -95.410156 89.84375 -93.859375 C 89.84375 -93.335938 89.800781 -92.945312 89.71875 -92.6875 L 87.5 -77.65625 C 87.332031 -76.613281 87.03125 -75.898438 86.59375 -75.515625 C 86.164062 -75.128906 85.390625 -74.9375 84.265625 -74.9375 L 44.078125 -74.9375 C 43.296875 -74.9375 42.710938 -74.785156 42.328125 -74.484375 C 41.941406 -74.179688 41.703125 -73.550781 41.609375 -72.59375 L 39.921875 -60.671875 L 39.796875 -59.765625 C 39.796875 -59.328125 39.90625 -59.046875 40.125 -58.921875 C 40.34375 -58.796875 40.753906 -58.734375 41.359375 -58.734375 L 65.859375 -58.734375 C 66.722656 -58.734375 67.285156 -58.554688 67.546875 -58.203125 C 67.804688 -57.859375 67.847656 -57.296875 67.671875 -56.515625 L 65.34375 -39.546875 C 65.25 -38.847656 65.070312 -38.390625 64.8125 -38.171875 C 64.5625 -37.960938 64.046875 -37.859375 63.265625 -37.859375 L 38.25 -37.859375 C 37.644531 -37.859375 37.210938 -37.707031 36.953125 -37.40625 C 36.691406 -37.101562 36.472656 -36.5625 36.296875 -35.78125 L 34.484375 -22.953125 L 34.484375 -22.296875 C 34.484375 -21.609375 34.785156 -21.265625 35.390625 -21.265625 L 78.5625 -21.265625 C 79.425781 -21.265625 79.988281 -21.085938 80.25 -20.734375 C 80.507812 -20.390625 80.550781 -19.742188 80.375 -18.796875 L 78.171875 -2.078125 C 77.992188 -1.296875 77.734375 -0.753906 77.390625 -0.453125 C 77.046875 -0.148438 76.359375 0 75.328125 0 L 5.578125 0 C 4.453125 0 3.628906 -0.234375 3.109375 -0.703125 C 2.585938 -1.179688 2.328125 -1.898438 2.328125 -2.859375 L 2.46875 -4.015625 Z M 15.171875 -93.984375 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(475.957008, 125.794645)"><g><path d="M 86.46875 -3.5 C 86.644531 -3.070312 86.734375 -2.550781 86.734375 -1.9375 C 86.734375 -0.644531 85.910156 0 84.265625 0 L 59.109375 0 C 58.160156 0 57.425781 -0.234375 56.90625 -0.703125 C 56.394531 -1.179688 56.007812 -2.070312 55.75 -3.375 L 48.21875 -36.8125 C 48.050781 -37.332031 47.859375 -37.703125 47.640625 -37.921875 C 47.421875 -38.140625 46.96875 -38.25 46.28125 -38.25 L 38.5 -38.25 C 37.8125 -38.25 37.335938 -38.117188 37.078125 -37.859375 C 36.816406 -37.597656 36.644531 -37.207031 36.5625 -36.6875 L 31.765625 -2.984375 C 31.585938 -1.679688 31.175781 -0.859375 30.53125 -0.515625 C 29.882812 -0.171875 28.738281 0 27.09375 0 L 5.3125 0 C 3.0625 0 2.113281 -1.335938 2.46875 -4.015625 L 15.171875 -93.984375 C 15.253906 -94.941406 15.445312 -95.546875 15.75 -95.796875 C 16.050781 -96.054688 16.59375 -96.1875 17.375 -96.1875 L 60.671875 -96.1875 C 72.160156 -96.1875 81.082031 -94.003906 87.4375 -89.640625 C 93.789062 -85.273438 96.96875 -79.207031 96.96875 -71.4375 C 96.96875 -65.125 95.128906 -59.285156 91.453125 -53.921875 C 87.785156 -48.566406 83.015625 -44.722656 77.140625 -42.390625 C 76.015625 -41.960938 75.34375 -41.570312 75.125 -41.21875 C 74.90625 -40.875 74.882812 -40.398438 75.0625 -39.796875 Z M 54.0625 -57.5625 C 57.601562 -57.5625 60.5625 -58.769531 62.9375 -61.1875 C 65.3125 -63.601562 66.5 -66.410156 66.5 -69.609375 C 66.5 -72.035156 65.613281 -73.875 63.84375 -75.125 C 62.070312 -76.375 59.804688 -77 57.046875 -77 L 43.8125 -77 C 43.207031 -77 42.773438 -76.828125 42.515625 -76.484375 C 42.265625 -76.140625 42.050781 -75.445312 41.875 -74.40625 L 39.671875 -59.5 L 39.671875 -58.859375 C 39.671875 -58.335938 39.773438 -57.988281 39.984375 -57.8125 C 40.203125 -57.644531 40.570312 -57.5625 41.09375 -57.5625 Z M 54.0625 -57.5625 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(571.764487, 125.794645)"><g><path d="M 69.875 -71.5625 C 65.289062 -75.539062 59.367188 -77.53125 52.109375 -77.53125 C 47.796875 -77.53125 44.363281 -76.835938 41.8125 -75.453125 C 39.257812 -74.066406 37.984375 -72.078125 37.984375 -69.484375 C 37.984375 -66.460938 40.578125 -64.171875 45.765625 -62.609375 L 66.5 -55.875 C 73.414062 -53.625 78.554688 -50.707031 81.921875 -47.125 C 85.296875 -43.539062 86.984375 -39.023438 86.984375 -33.578125 C 86.984375 -26.316406 84.992188 -20.050781 81.015625 -14.78125 C 77.046875 -9.507812 71.625 -5.507812 64.75 -2.78125 C 57.882812 -0.0625 50.171875 1.296875 41.609375 1.296875 C 31.753906 1.296875 23.390625 -0.320312 16.515625 -3.5625 C 9.648438 -6.800781 4.664062 -11.273438 1.5625 -16.984375 C 1.039062 -18.191406 0.78125 -18.882812 0.78125 -19.0625 C 0.78125 -19.570312 1.164062 -20.085938 1.9375 -20.609375 L 15.6875 -29.046875 C 16.375 -29.472656 17.109375 -29.6875 17.890625 -29.6875 C 19.097656 -29.6875 20.222656 -29.039062 21.265625 -27.75 C 23.597656 -25.15625 25.628906 -23.207031 27.359375 -21.90625 C 29.085938 -20.613281 31.242188 -19.597656 33.828125 -18.859375 C 36.421875 -18.128906 39.878906 -17.765625 44.203125 -17.765625 C 48.265625 -17.765625 51.613281 -18.429688 54.25 -19.765625 C 56.882812 -21.109375 58.203125 -23.335938 58.203125 -26.453125 C 58.203125 -29.554688 55.566406 -31.890625 50.296875 -33.453125 L 31.25 -39.28125 C 24.675781 -41.269531 19.570312 -44.378906 15.9375 -48.609375 C 12.3125 -52.847656 10.5 -57.820312 10.5 -63.53125 C 10.5 -70.175781 12.441406 -76.09375 16.328125 -81.28125 C 20.222656 -86.46875 25.429688 -90.460938 31.953125 -93.265625 C 38.484375 -96.078125 45.550781 -97.484375 53.15625 -97.484375 C 61.1875 -97.484375 68.332031 -96.078125 74.59375 -93.265625 C 80.863281 -90.460938 85.554688 -86.988281 88.671875 -82.84375 C 89.367188 -81.894531 89.71875 -81.113281 89.71875 -80.5 C 89.71875 -79.894531 89.410156 -79.421875 88.796875 -79.078125 L 73.890625 -69.484375 C 73.460938 -69.140625 72.988281 -69.117188 72.46875 -69.421875 C 71.945312 -69.722656 71.425781 -70.109375 70.90625 -70.578125 C 70.394531 -71.054688 70.050781 -71.382812 69.875 -71.5625 Z M 69.875 -71.5625 "/></g></g></g></g></g></g><g clip-path="url(#aab0ee5e67)"><g transform="matrix(1, 0, 0, 1, 279, 0.000000000000043396)"><g clip-path="url(#3b97b1fa0c)"><g fill="#ffffff" fill-opacity="1"><g transform="translate(1.701228, 103.465657)"><g><path d="M 86.46875 -3.5 C 86.644531 -3.070312 86.734375 -2.550781 86.734375 -1.9375 C 86.734375 -0.644531 85.910156 0 84.265625 0 L 59.109375 0 C 58.160156 0 57.425781 -0.234375 56.90625 -0.703125 C 56.394531 -1.179688 56.007812 -2.070312 55.75 -3.375 L 48.21875 -36.8125 C 48.050781 -37.332031 47.859375 -37.703125 47.640625 -37.921875 C 47.421875 -38.140625 46.96875 -38.25 46.28125 -38.25 L 38.5 -38.25 C 37.8125 -38.25 37.335938 -38.117188 37.078125 -37.859375 C 36.816406 -37.597656 36.644531 -37.207031 36.5625 -36.6875 L 31.765625 -2.984375 C 31.585938 -1.679688 31.175781 -0.859375 30.53125 -0.515625 C 29.882812 -0.171875 28.738281 0 27.09375 0 L 5.3125 0 C 3.0625 0 2.113281 -1.335938 2.46875 -4.015625 L 15.171875 -93.984375 C 15.253906 -94.941406 15.445312 -95.546875 15.75 -95.796875 C 16.050781 -96.054688 16.59375 -96.1875 17.375 -96.1875 L 60.671875 -96.1875 C 72.160156 -96.1875 81.082031 -94.003906 87.4375 -89.640625 C 93.789062 -85.273438 96.96875 -79.207031 96.96875 -71.4375 C 96.96875 -65.125 95.128906 -59.285156 91.453125 -53.921875 C 87.785156 -48.566406 83.015625 -44.722656 77.140625 -42.390625 C 76.015625 -41.960938 75.34375 -41.570312 75.125 -41.21875 C 74.90625 -40.875 74.882812 -40.398438 75.0625 -39.796875 Z M 54.0625 -57.5625 C 57.601562 -57.5625 60.5625 -58.769531 62.9375 -61.1875 C 65.3125 -63.601562 66.5 -66.410156 66.5 -69.609375 C 66.5 -72.035156 65.613281 -73.875 63.84375 -75.125 C 62.070312 -76.375 59.804688 -77 57.046875 -77 L 43.8125 -77 C 43.207031 -77 42.773438 -76.828125 42.515625 -76.484375 C 42.265625 -76.140625 42.050781 -75.445312 41.875 -74.40625 L 39.671875 -59.5 L 39.671875 -58.859375 C 39.671875 -58.335938 39.773438 -57.988281 39.984375 -57.8125 C 40.203125 -57.644531 40.570312 -57.5625 41.09375 -57.5625 Z M 54.0625 -57.5625 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(97.508721, 103.465657)"><g><path d="M 46.671875 1.296875 C 38.117188 1.296875 30.75 -0.363281 24.5625 -3.6875 C 18.382812 -7.019531 13.648438 -11.753906 10.359375 -17.890625 C 7.078125 -24.023438 5.4375 -31.285156 5.4375 -39.671875 C 5.4375 -43.296875 5.65625 -46.492188 6.09375 -49.265625 C 7.476562 -58.941406 10.546875 -67.429688 15.296875 -74.734375 C 20.046875 -82.035156 26.132812 -87.648438 33.5625 -91.578125 C 41 -95.515625 49.300781 -97.484375 58.46875 -97.484375 C 66.851562 -97.484375 74.132812 -95.773438 80.3125 -92.359375 C 86.488281 -88.953125 91.21875 -84.113281 94.5 -77.84375 C 97.789062 -71.582031 99.4375 -64.257812 99.4375 -55.875 C 99.4375 -52.25 99.21875 -49.09375 98.78125 -46.40625 C 97.40625 -36.726562 94.359375 -28.300781 89.640625 -21.125 C 84.929688 -13.957031 78.878906 -8.425781 71.484375 -4.53125 C 64.097656 -0.644531 55.828125 1.296875 46.671875 1.296875 Z M 47.453125 -18.921875 C 53.328125 -18.921875 57.90625 -21.253906 61.1875 -25.921875 C 64.46875 -30.585938 66.847656 -38.238281 68.328125 -48.875 C 69.015625 -54.144531 69.359375 -58.421875 69.359375 -61.703125 C 69.359375 -67.328125 68.445312 -71.367188 66.625 -73.828125 C 64.8125 -76.296875 61.875 -77.53125 57.8125 -77.53125 C 51.9375 -77.53125 47.3125 -75.039062 43.9375 -70.0625 C 40.570312 -65.09375 38.113281 -57.078125 36.5625 -46.015625 C 35.863281 -40.921875 35.515625 -36.816406 35.515625 -33.703125 C 35.515625 -28.347656 36.441406 -24.546875 38.296875 -22.296875 C 40.160156 -20.046875 43.210938 -18.921875 47.453125 -18.921875 Z M 47.453125 -18.921875 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(198.631643, 103.465657)"><g><path d="M -0.515625 0 C -1.554688 0 -2.078125 -0.429688 -2.078125 -1.296875 C -2.078125 -1.984375 -1.597656 -3.363281 -0.640625 -5.4375 L 43.296875 -93.859375 C 43.816406 -94.804688 44.441406 -95.429688 45.171875 -95.734375 C 45.910156 -96.035156 46.925781 -96.1875 48.21875 -96.1875 L 73.765625 -96.1875 C 74.804688 -96.1875 75.539062 -95.816406 75.96875 -95.078125 C 76.40625 -94.347656 76.75 -93.335938 77 -92.046875 L 95.796875 -3.765625 C 95.890625 -3.503906 95.9375 -3.113281 95.9375 -2.59375 C 95.9375 -0.863281 95.242188 0 93.859375 0 L 68.453125 0 C 67.242188 0 66.421875 -0.953125 65.984375 -2.859375 L 63 -17.5 C 62.914062 -17.9375 62.765625 -18.238281 62.546875 -18.40625 C 62.335938 -18.582031 61.925781 -18.671875 61.3125 -18.671875 L 34.09375 -18.671875 C 33.488281 -18.671875 33.015625 -18.539062 32.671875 -18.28125 C 32.328125 -18.019531 31.976562 -17.585938 31.625 -16.984375 L 23.859375 -1.296875 C 23.597656 -0.773438 23.269531 -0.425781 22.875 -0.25 C 22.488281 -0.0820312 21.863281 0 21 0 Z M 57.8125 -40.703125 C 59.289062 -40.703125 59.8125 -41.566406 59.375 -43.296875 L 54.703125 -64.953125 C 54.617188 -65.816406 54.316406 -66.25 53.796875 -66.25 C 53.453125 -66.25 53.066406 -65.859375 52.640625 -65.078125 L 41.875 -42.78125 C 41.613281 -42.257812 41.484375 -41.828125 41.484375 -41.484375 C 41.484375 -40.960938 42.003906 -40.703125 43.046875 -40.703125 Z M 57.8125 -40.703125 "/></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(302.217823, 103.465657)"><g><path d="M 6.21875 0 C 4.925781 0 3.953125 -0.429688 3.296875 -1.296875 C 2.648438 -2.160156 2.414062 -3.285156 2.59375 -4.671875 L 15.03125 -93.734375 C 15.125 -94.765625 15.382812 -95.429688 15.8125 -95.734375 C 16.25 -96.035156 17.070312 -96.1875 18.28125 -96.1875 L 50.6875 -96.1875 C 60.800781 -96.1875 69.441406 -94.457031 76.609375 -91 C 83.785156 -87.550781 89.207031 -82.753906 92.875 -76.609375 C 96.550781 -70.472656 98.390625 -63.472656 98.390625 -55.609375 C 98.390625 -44.640625 95.96875 -34.941406 91.125 -26.515625 C 86.289062 -18.085938 79.488281 -11.5625 70.71875 -6.9375 C 61.945312 -2.3125 51.8125 0 40.3125 0 Z M 43.8125 -20.359375 C 51.675781 -20.359375 57.640625 -23.8125 61.703125 -30.71875 C 65.765625 -37.632812 67.796875 -46.492188 67.796875 -57.296875 C 67.796875 -63.265625 66.390625 -67.847656 63.578125 -71.046875 C 60.773438 -74.242188 56.910156 -75.84375 51.984375 -75.84375 L 44.34375 -75.84375 C 42.78125 -75.84375 41.867188 -74.976562 41.609375 -73.25 L 34.75 -22.8125 L 34.75 -22.03125 C 34.75 -20.914062 35.304688 -20.359375 36.421875 -20.359375 Z M 43.8125 -20.359375 "/></g></g></g></g></g></g><g clip-path="url(#8174243e21)"><g transform="matrix(1, 0, 0, 1, 683, 0.000000000000043396)"><g clip-path="url(#d491d5ed37)"><g fill="#f4b120" fill-opacity="1"><g transform="translate(2.928563, 192.338952)"><g><path d="M 5.375 37 C 3.132812 37 1.488281 36.175781 0.4375 34.53125 C -0.601562 32.882812 -0.972656 30.789062 -0.671875 28.25 L 29.375 -185.421875 C 29.664062 -187.515625 30.109375 -188.785156 30.703125 -189.234375 C 31.304688 -189.679688 32.65625 -189.90625 34.75 -189.90625 L 55.609375 -189.90625 C 57.242188 -189.90625 58.582031 -189.304688 59.625 -188.109375 C 60.675781 -186.910156 61.054688 -185.640625 60.765625 -184.296875 L 30.046875 34.296875 C 29.890625 35.492188 29.585938 36.242188 29.140625 36.546875 C 28.691406 36.847656 27.722656 37 26.234375 37 Z M 5.375 37 "/></g></g></g><g fill="#f4b120" fill-opacity="1"><g transform="translate(57.847316, 192.338952)"><g><path d="M 5.375 37 C 3.132812 37 1.488281 36.175781 0.4375 34.53125 C -0.601562 32.882812 -0.972656 30.789062 -0.671875 28.25 L 29.375 -185.421875 C 29.664062 -187.515625 30.109375 -188.785156 30.703125 -189.234375 C 31.304688 -189.679688 32.65625 -189.90625 34.75 -189.90625 L 55.609375 -189.90625 C 57.242188 -189.90625 58.582031 -189.304688 59.625 -188.109375 C 60.675781 -186.910156 61.054688 -185.640625 60.765625 -184.296875 L 30.046875 34.296875 C 29.890625 35.492188 29.585938 36.242188 29.140625 36.546875 C 28.691406 36.847656 27.722656 37 26.234375 37 Z M 5.375 37 "/></g></g></g></g></g></g></g></g></g></svg>
            </a>

            <!-- Left links -->
            <ul class="navbar-nav ms-2 me-auto d-none d-md-flex flex-row rr-desktop-main-nav" data-desktop-nav>

                    <!---<li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                        onmouseover="showLegent(this)" onmouseout="hideLegent()" title="<cfoutput>#VARIABLES.headerHomeTitle#</cfoutput>"
                        data-mdb-animation-init
                        data-mdb-animation-target="#legend">
                        <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/">active</cfif>" href="<cfoutput>#VARIABLES.headerHomePath#</cfoutput>">
                            <i class="fa-solid fa-house "></i>
                        </a>
                    </li>--->
                    <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                        onmouseover="showLegent(this)" onmouseout="hideLegent()" title="<cfoutput>#VARIABLES.headerActivitiesTitle#</cfoutput>"
                        data-mdb-animation-init
                        data-mdb-animation-target="#legend">
                        <cfif Usuario.logado>
                            <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/atividades/">active</cfif>" href="<cfoutput>#VARIABLES.headerActivitiesPath#</cfoutput>">
                                <i class="fa-solid fa-list"></i>
                            </a>
                        <cfelse>
                            <a class="nav-link py-0 fs-5" href="#" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil">
                                <i class="fa-solid fa-list"></i>
                            </a>
                        </cfif>
                    </li>
                    <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                        onmouseover="showLegent(this)" onmouseout="hideLegent()" title="<cfoutput>#VARIABLES.headerAgendaTitle#</cfoutput>"
                        data-mdb-animation-init
                        data-mdb-animation-target="#legend">
                        <cfif Usuario.logado>
                            <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/agenda/">active</cfif>" href="<cfoutput>#VARIABLES.headerAgendaPath#</cfoutput>"><i class="fa-solid fa-calendar"></i></a>
                        <cfelse>
                            <a class="nav-link py-0 fs-5" href="#" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"><i class="fa-solid fa-calendar"></i></a>
                        </cfif>
                    </li>
                    <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                        onmouseover="showLegent(this)" onmouseout="hideLegent()" title="<cfoutput>#VARIABLES.headerResultsTitle#</cfoutput>"
                        data-mdb-animation-init
                        data-mdb-animation-target="#legend">
                        <cfif Usuario.logado>

                            <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/resultados/">active</cfif> position-relative" href="<cfoutput>#VARIABLES.headerResultsPath#</cfoutput>">
                                <!---<span class="position-absolute top-0 start-100 mt-1 ms-n2 translate-middle p-1 bg-warning rounded-circle border border-white shadow">--->
                                    <!---<span class="visually-hidden">Novos resultados</span>--->
                                <!---</span>--->
                                <i class="fa-solid fa-medal"></i>
                            </a>
                        <cfelse>
                            <a class="nav-link py-0 fs-5" href="#" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"><i class="fa-solid fa-medal"></i></a>
                        </cfif>
                    </li>
                    <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                        onmouseover="showLegent(this)" onmouseout="hideLegent()" title="<cfoutput>#VARIABLES.headerChallengesTitle#</cfoutput>"
                        data-mdb-animation-init
                        data-mdb-animation-target="#legend">
                        <cfif Usuario.logado>

                            <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/desafios/">active</cfif> position-relative" href="<cfoutput>#VARIABLES.headerChallengesPath#</cfoutput>">
                                <!---<span class="position-absolute top-0 start-100 mt-1 ms-n2 translate-middle p-1 bg-warning rounded-circle border border-white shadow">--->
                                    <!---<span class="visually-hidden">Novos resultados</span>--->
                                <!---</span>--->
                                <i class="fa-solid fa-trophy"></i>
                            </a>
                        <cfelse>
                            <a class="nav-link py-0 fs-5" href="#" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"><i class="fa-solid fa-trophy"></i></a>
                        </cfif>
                    </li>
                    <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                        onmouseover="showLegent(this)" onmouseout="hideLegent()" title="<cfoutput>#VARIABLES.headerNewsTitle#</cfoutput>"
                        data-mdb-animation-init
                        data-mdb-animation-target="#legend">
                        <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/noticias/">active</cfif>" href="<cfoutput>#VARIABLES.headerNewsPath#</cfoutput>">
                            <i class="fa-solid fa-newspaper"></i>
                        </a>
                    </li>
                    <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                        onmouseover="showLegent(this)" onmouseout="hideLegent()" title="<cfoutput>#VARIABLES.headerVideosTitle#</cfoutput>"
                        data-mdb-animation-init
                        data-mdb-animation-target="#legend">
                        <a class="nav-link py-0 fs-5 <cfif VARIABLES.template EQ "/videos/">active</cfif>" href="<cfoutput>#VARIABLES.headerVideosPath#</cfoutput>">
                            <i class="fa-brands fa-youtube"></i>
                        </a>
                    </li>
                    <cfif VARIABLES.headerHasHomeHeroToggle>
                        <li class="nav-item border-start border-dark border-opacity-10 px-2 px-lg-0"
                            onmouseover="showLegent(this)" onmouseout="hideLegent()" title="<cfoutput>#VARIABLES.headerSearchTitle#</cfoutput>"
                            data-mdb-animation-init
                            data-mdb-animation-target="#legend">
                            <button type="button"
                                    class="nav-link py-0 fs-5 rr-topbar-nav-toggle"
                                    data-home-hero-toggle
                                    aria-controls="homeHeroSearch"
                                    aria-expanded="<cfoutput>#VARIABLES.template EQ "/" ? "true" : "false"#</cfoutput>"
                                    aria-label="<cfoutput>#VARIABLES.headerSearchTitle#</cfoutput>">
                                <i class="fa-solid fa-magnifying-glass"></i>
                            </button>
                        </li>
                    </cfif>
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
                                document.getElementById("legend").innerHTML = '';
                            }
                        </script>
                    </li>

            </ul>
            <!-- Left links -->

            <div class="d-flex align-items-center">

                <!--- ADMIN --->

                <cfif Usuario.logado
                    AND BooleanFormat(Usuario.is_admin)
                    AND (NOT structKeyExists(REQUEST, "currentEnvironment") OR REQUEST.currentEnvironment NEQ "prod")>
                    <div class="btn-group shadow-0">
                        <a href="<cfoutput>#VARIABLES.headerHomePath#</cfoutput>" id="dropdownMenuAdmin" class="link-light" data-mdb-dropdown-init  aria-expanded="false">
                            <i class="fas fa-screwdriver-wrench"></i>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end dropdown-menu-lg-end rr-topbar-right-menu" aria-labelledby="dropdownMenuAdmin">
                        <li class="bg-light-subtle"><span class="dropdown-header text-center"><cfoutput>#REQUEST.t("common.slimHeader.adminTitle")#</cfoutput></span></li>
                        <li><a class="dropdown-item" target="_blank" href="https://runnerhub.run/admin/">RH Admin</a></li>
                        <li><a class="dropdown-item" target="_blank" href="<cfoutput>#VARIABLES.headerHomePath#</cfoutput>?action=handoff_start&target=dev"><cfoutput>#REQUEST.t("common.slimHeader.devEnvironment")#</cfoutput></a></li>
                        <cfif VARIABLES.devMode
                            AND structKeyExists(SESSION, "devAuth")
                            AND isStruct(SESSION.devAuth)
                            AND structKeyExists(SESSION.devAuth, "isImpersonating")
                            AND SESSION.devAuth.isImpersonating>
                            <li><a class="dropdown-item" href="<cfoutput>#VARIABLES.headerHomePath#</cfoutput>?action=dev_auth_back"><cfoutput>#REQUEST.t("common.slimHeader.backToUser")#</cfoutput></a></li>
                        </cfif>
                        <!---<li><a class="dropdown-item" target="_blank" href="<cfoutput>https://roadrunners.run/?action=dev_auth&dev_auth=#Usuario.email#</cfoutput>">Entrar como usuário</a></li>--->
                        <li><hr class="dropdown-divider m-0"/></li>
                            <cfif VARIABLES.template EQ "/evento/">
                                <li><a class="dropdown-item" target="admin" href="https://business.roadrunners.run/eventos/?id_evento=<cfoutput>#qEvento.id_evento#</cfoutput>"><cfoutput>#REQUEST.t("common.slimHeader.editEvent")#</cfoutput></a></li>
                                <li><a class="dropdown-item" target="admin" href="https://business.roadrunners.run/administracao/agrega-revisao/?manual_nome=<cfoutput>#urlEncodedFormat(trim(qEvento.nome_evento & ""))#</cfoutput>"><cfoutput>#REQUEST.t("common.slimHeader.aggregateEvent")#</cfoutput></a></li>
                                <li><hr class="dropdown-divider m-0"/></li>
                            </cfif>
                            <cfif VARIABLES.template EQ "/atleta/">
                                <li><a class="dropdown-item" target="admin" href="https://runnerhub.run/admin/users.cfm?busca=<cfoutput>#qPagina.id_usuario_cadastro#</cfoutput>">Editar atleta</a></li>
                                <li><hr class="dropdown-divider m-0"/></li>
                            </cfif>
                            <li><a class="dropdown-item" target="_blank" href="https://runnerhub.run/api/wiclax/<cfif VARIABLES.template EQ "/evento/">?id_evento=<cfoutput>#qEvento.id_evento#</cfoutput></cfif>">Importar Wiclax</a></li>
                            <li><a class="dropdown-item" target="_blank" href="https://runnerhub.run/api/excel/<cfif VARIABLES.template EQ "/evento/">?id_evento=<cfoutput>#qEvento.id_evento#</cfoutput></cfif>">Importar Excel</a></li>
                            <li><a class="dropdown-item" target="_blank" href="https://runnerhub.run/api/feed/">Importar Feed de Notícias</a></li>
                            <li><a class="dropdown-item" target="_blank" href="https://runnerhub.run/api/youtube/?channel=UCxmZoyAOr6HkyAkW2c2YSog">Importar Vídeos Youtube</a></li>
                        </ul>
                    </div>
                </cfif>

                <!--- APPS --->

                <cfinclude template="menu_apps.cfm">

                <cfif NOT Usuario.logado>

                    <!--- LOGIN --->

                    <div class="col-1 ms-3">
                        <!---<img src="/assets/user.png" style="max-height: 25px; cursor: pointer;" alt="Login do usuário" class="rounded-circle ms-2"  data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil"/>--->
                        <button  type="button" aria-label="<cfoutput>#REQUEST.t('common.header.login')#</cfoutput>" class="btn btn-light small py-1 px-2 shadow-0" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil">
                            <cfoutput>#REQUEST.t("common.header.login")#</cfoutput>
                        </button>
                    </div>

                <cfelse>

                    <!--- MENSAGENS --->
                    <cfset VARIABLES.headerUnreadChatCount = isDefined("qChatNaoLidas") AND qChatNaoLidas.recordcount ? val(qChatNaoLidas.total_nao_lidas) : 0/>
                    <cfset VARIABLES.headerMessagesPath = REQUEST.lang EQ "en" ? "/en/messages/" : (REQUEST.lang EQ "es" ? "/es/mensajes/" : "/mensagens/")/>
                    <div class="dropdown btn-group ms-3 shadow-0">
                        <a data-mdb-dropdown-init class="link-light" href="##" id="dropdownMenuChat" role="button" aria-expanded="false" aria-label="Mensagens">
                            <i class="<cfif VARIABLES.headerUnreadChatCount GT 0>fa-solid<cfelse>fa-regular</cfif> fa-message" id="rrChatHeaderIcon"></i>
                            <span class="badge rounded-pill badge-notification bg-danger" id="rrChatUnreadBadge" data-unread-count="<cfoutput>#VARIABLES.headerUnreadChatCount#</cfoutput>"<cfif VARIABLES.headerUnreadChatCount LTE 0> hidden</cfif>><cfoutput>#VARIABLES.headerUnreadChatCount GT 99 ? '99+' : VARIABLES.headerUnreadChatCount#</cfoutput></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end dropdown-menu-lg-end rr-notifications-menu rr-topbar-right-menu" aria-labelledby="dropdownMenuChat" id="rrChatHeaderMenu" data-chat-base-path="<cfoutput>#VARIABLES.headerMessagesPath#</cfoutput>" data-chat-empty="<cfoutput>#REQUEST.lang EQ 'en' ? 'No messages' : (REQUEST.lang EQ 'es' ? 'Sin mensajes' : 'Nenhuma mensagem')#</cfoutput>" data-chat-request="<cfoutput>#REQUEST.lang EQ 'en' ? 'Conversation request' : (REQUEST.lang EQ 'es' ? 'Solicitud de conversación' : 'Solicitação de conversa')#</cfoutput>" data-chat-icon="<cfoutput>#REQUEST.lang EQ 'en' ? 'Icon' : (REQUEST.lang EQ 'es' ? 'Icono' : 'Ícone')#</cfoutput>" data-chat-event="<cfoutput>#REQUEST.lang EQ 'en' ? 'Recommended event' : (REQUEST.lang EQ 'es' ? 'Evento recomendado' : 'Evento recomendado')#</cfoutput>" data-chat-new="<cfoutput>#REQUEST.lang EQ 'en' ? 'New message' : (REQUEST.lang EQ 'es' ? 'Nuevo mensaje' : 'Nova mensagem')#</cfoutput>" data-chat-group-member="<cfoutput>#REQUEST.lang EQ 'en' ? 'Added to group' : (REQUEST.lang EQ 'es' ? 'Añadido al grupo' : 'Adicionado ao grupo')#</cfoutput>" data-chat-group-admin="<cfoutput>#REQUEST.lang EQ 'en' ? 'Promoted to Group Admin' : (REQUEST.lang EQ 'es' ? 'Promovido a Admin del grupo' : 'Promovido a Admin do Grupo')#</cfoutput>" data-chat-verified="<cfoutput>#HTMLEditFormat(REQUEST.t('athlete.photo.verifiedTitle'))#</cfoutput>" data-chat-team="Road Runners Team" data-timestamp-today="<cfoutput>#HTMLEditFormat(REQUEST.t('common.header.timestampToday'))#</cfoutput>" data-timestamp-yesterday="<cfoutput>#HTMLEditFormat(REQUEST.t('common.header.timestampYesterday'))#</cfoutput>" data-timestamp-at="<cfoutput>#HTMLEditFormat(REQUEST.t('common.header.timestampAt'))#</cfoutput>">
                            <li class="bg-light-subtle rr-notification-header"><span class="dropdown-header"><cfoutput>#REQUEST.lang EQ 'en' ? 'Messages' : (REQUEST.lang EQ 'es' ? 'Mensajes' : 'Mensagens')#</cfoutput></span><a class="rr-notification-action rr-chat-new-action" href="<cfoutput>#VARIABLES.headerMessagesPath#</cfoutput>" aria-label="Nova conversa"><i class="fa-solid fa-user-plus"></i></a></li>
                            <cfif isDefined("qChatHeader") AND qChatHeader.recordcount>
                                <cfoutput query="qChatHeader"><cfset VARIABLES.headerChatPath=rrChatOpenUrl("direct",qChatHeader.id_chat_conversa,Usuario.id)/><li class="border-top border-1 border-light-subtle" data-rr-chat-item><a class="dropdown-item rr-notification-item#qChatHeader.nao_lida ? '' : ' is-read'#" href="#encodeForHtmlAttribute(VARIABLES.headerChatPath)#"><img src="#encodeForHtmlAttribute(len(trim(qChatHeader.imagem_usuario & '')) ? qChatHeader.imagem_usuario : '/assets/user.png')#" alt="" class="rounded-circle me-2" width="28" height="28" onerror="this.onerror=null;this.src='/assets/user.png';"><span class="rr-notification-item-text"><span class="rr-chat-header-name"><strong>#encodeForHtml(qChatHeader.other_name)#</strong><cfif qChatHeader.verificado OR qChatHeader.is_admin><cfif qChatHeader.is_admin><i class="bi bi-shield-fill-check rr-user-status-icon" role="img" aria-label="Road Runners Team" title="Road Runners Team"></i><cfelse><i class="bi bi-patch-check-fill rr-user-status-icon" role="img" aria-label="#HTMLEditFormat(REQUEST.t('athlete.photo.verifiedAlt'))#" title="#HTMLEditFormat(REQUEST.t('athlete.photo.verifiedTitle'))#"></i></cfif></cfif></span><br><small>#len(rrChatIconKey(qChatHeader.conteudo & '')) ? (REQUEST.lang EQ 'en' ? 'Icon' : (REQUEST.lang EQ 'es' ? 'Icono' : 'Ícone')) : (rrChatEventId(qChatHeader.conteudo & '') GT 0 ? (REQUEST.lang EQ 'en' ? 'Recommended event' : 'Evento recomendado') : (qChatHeader.tipo EQ 'text' ? encodeForHtml(left(qChatHeader.conteudo,70)) : (REQUEST.lang EQ 'en' ? 'Conversation request' : (REQUEST.lang EQ 'es' ? 'Solicitud de conversación' : 'Solicitação de conversa'))))#</small><span class="rr-notification-item-timestamp" data-rr-timestamp="#isDate(qChatHeader.ultima_interacao_em) ? dateFormat(qChatHeader.ultima_interacao_em,'yyyy-mm-dd') & 'T' & timeFormat(qChatHeader.ultima_interacao_em,'HH:nn:ss') : ''#"></span></span></a></li></cfoutput>
                            <cfelse><li data-rr-chat-item><span class="dropdown-item opacity-50"><cfoutput>#REQUEST.lang EQ 'en' ? 'No messages' : (REQUEST.lang EQ 'es' ? 'Sin mensajes' : 'Nenhuma mensagem')#</cfoutput></span></li></cfif>
                            <li class="border-top" id="rrChatViewAllItem"><a class="dropdown-item text-center fw-semibold" href="<cfoutput>#VARIABLES.headerMessagesPath#</cfoutput>"><cfoutput>#REQUEST.lang EQ 'en' ? 'View all messages' : (REQUEST.lang EQ 'es' ? 'Ver todos los mensajes' : 'Ver todas as mensagens')#</cfoutput></a></li>
                        </ul>
                    </div>
                    <script src="/assets/js/runnerhub-chat-header-20260811.js?v=20260915a" defer></script>

                    <!--- NOTIFICACOES--->

                    <cfset VARIABLES.headerUnreadNotificationCount = 0/>
                    <cfif isDefined("qNotificacoesNaoLidas") AND qNotificacoesNaoLidas.recordcount>
                        <cfset VARIABLES.headerUnreadNotificationCount = val(qNotificacoesNaoLidas.total_nao_lidas)/>
                    </cfif>

                    <div class="dropdown btn-group ms-2 shadow-0">
                        <a data-mdb-dropdown-init
                            class="link-light"
                            href="#"
                            id="dropdownMenuNotif"
                            role="button"
                            aria-expanded="false">
                            <i class="<cfif VARIABLES.headerUnreadNotificationCount GT 0>fa-solid<cfelse>fa-regular</cfif> fa-bell" id="rrNotificationsHeaderIcon"></i>
                            <!--- Notifications counter --->
                            <span class="badge rounded-pill badge-notification bg-danger" id="rrNotificationsUnreadBadge" data-unread-count="<cfoutput>#VARIABLES.headerUnreadNotificationCount#</cfoutput>"<cfif VARIABLES.headerUnreadNotificationCount LTE 0> hidden</cfif>><cfoutput>#VARIABLES.headerUnreadNotificationCount GT 99 ? '99+' : VARIABLES.headerUnreadNotificationCount#</cfoutput></span>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end dropdown-menu-lg-end rr-notifications-menu rr-topbar-right-menu"
                                aria-labelledby="dropdownMenuNotif" id="rrNotificationsHeaderMenu" data-notifications-empty="<cfoutput>#REQUEST.t('common.header.noNotifications')#</cfoutput>" data-notifications-new="<cfoutput>#REQUEST.lang EQ 'en' ? 'New notification' : (REQUEST.lang EQ 'es' ? 'Nueva notificación' : 'Nova notificação')#</cfoutput>" data-timestamp-today="<cfoutput>#HTMLEditFormat(REQUEST.t('common.header.timestampToday'))#</cfoutput>" data-timestamp-yesterday="<cfoutput>#HTMLEditFormat(REQUEST.t('common.header.timestampYesterday'))#</cfoutput>" data-timestamp-at="<cfoutput>#HTMLEditFormat(REQUEST.t('common.header.timestampAt'))#</cfoutput>">
                            <li class="bg-light-subtle rr-notification-header" id="rrNotificationsHeaderHead">
                                <span class="dropdown-header"><cfoutput>#REQUEST.t("common.header.notifications")#</cfoutput></span>
                                <span class="rr-notification-actions">
                                    <button type="button" class="rr-notification-action" id="rrNotificationsMarkAllRead" title="<cfoutput>#REQUEST.t('common.header.markAllNotificationsRead')#</cfoutput>" aria-label="<cfoutput>#REQUEST.t('common.header.markAllNotificationsRead')#</cfoutput>"<cfif VARIABLES.headerUnreadNotificationCount LTE 0> disabled</cfif>>
                                        <i class="fa-solid fa-check-double" aria-hidden="true"></i>
                                    </button>
                                    <button type="button" class="rr-notification-action" id="rrNotificationsPreferencesButton" title="<cfoutput>#REQUEST.t('notifications.push.preferencesMenu')#</cfoutput>" aria-label="<cfoutput>#REQUEST.t('notifications.push.preferencesMenu')#</cfoutput>">
                                        <i class="fa-solid fa-sliders" aria-hidden="true"></i>
                                    </button>
                                </span>
                            </li>
                            <!---<li class="bg-warning-subtle"><a class="dropdown-item text-warning" href="/resultados/"><i class="fa-solid fa-medal me-2"></i>Você tem 3 novos resultados</a></li>--->
                            <cfif isDefined("qNotificacoes") AND qNotificacoes.recordcount>
                                <cfoutput query="qNotificacoes">
                                    <cfset VARIABLES.notificationResolvedLink = rrNotificationsResolveUrl(qNotificacoes.link)/>
                                    <cfset VARIABLES.notificationIsExternalLink = left(lCase(trim(VARIABLES.notificationResolvedLink)), 4) EQ "http"/>
                                    <cfset VARIABLES.notificationIsRead = isDate(qNotificacoes.data_leitura)/>
                                    <li class="border-top border-1 border-light-subtle" data-rr-notification-item><a class="dropdown-item rr-notification-item<cfif VARIABLES.notificationIsRead> is-read</cfif>" href="/api/notifications/open.cfm?id_notifica=#qNotificacoes.id_notifica#"<cfif VARIABLES.notificationIsExternalLink> target="_blank" rel="noopener"</cfif>><i class="#qNotificacoes.icone# rr-notification-item-icon"></i><span class="rr-notification-item-text">#rrNotificationsSanitizeHtml(qNotificacoes.conteudo_notifica)#<span class="rr-notification-item-timestamp" data-rr-timestamp="#isDate(qNotificacoes.data_publicacao) ? dateFormat(qNotificacoes.data_publicacao,'yyyy-mm-dd') & 'T' & timeFormat(qNotificacoes.data_publicacao,'HH:nn:ss') : ''#"></span></span></a></li>
                                </cfoutput>
                            <cfelse>
                                <li data-rr-notification-item><span class="dropdown-item opacity-50"><cfoutput>#REQUEST.t("common.header.noNotifications")#</cfoutput></span></li>
                            </cfif>
                            <!---<li><a class="dropdown-item" href="https://www.strava.com/oauth/authorize?client_id=110999&response_type=code&redirect_uri=<cfoutput>#APPLICATION.baseCanonica#/atleta/#qPerfil.tag#</cfoutput>/&approval_prompt=force&scope=read,activity:read,profile:read_all"><i class="fa-brands fa-strava me-2"></i>Conecte sua conta Strava</a></li>--->
                            <!---<li><a class="dropdown-item" href="/resultados/"><i class="fa-solid fa-medal me-2"></i>Encontre seus resultados</a></li>--->
                            <!---<li><a class="dropdown-item" href="/busca/"><i class="fa-solid fa-calendar me-2"></i>Encontre uma corrida</a></li>--->
                        </ul>
                    </div>
                    <script src="/assets/js/runnerhub-notifications-header-20260811.js?v=20260915a" defer></script>

                    <cfif VARIABLES.headerIsBetaEnvironment>
                        <div class="ms-3">
                            <a class="rr-topbar-beta-link" href="<cfoutput>#VARIABLES.headerBetaPath#</cfoutput>" title="<cfoutput>#REQUEST.t('common.footer.betaLink')#</cfoutput>" aria-label="<cfoutput>#REQUEST.t('common.footer.betaLink')#</cfoutput>">
                                <i class="fa-solid fa-circle-info"></i>
                            </a>
                        </div>
                    </cfif>

                    <!--- USER --->

                    <div class="btn-group ms-3 shadow-0">
                        <a href="<cfoutput>#VARIABLES.headerHomePath#</cfoutput>" class="link-light" data-mdb-dropdown-init aria-expanded="false" id="dropdownMenuUser">
                            <img src="<cfoutput>#Usuario.imagem_usuario#</cfoutput>" alt="<cfoutput>#REQUEST.t('common.header.myProfile')#</cfoutput>" class="rr-topbar-user-avatar" onerror="this.src='/assets/user.png';">
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end dropdown-menu-lg-end rr-topbar-right-menu" aria-labelledby="dropdownMenuUser">
                            <li><a class="dropdown-item" href="<cfoutput>#VARIABLES.headerUserProfilePath#</cfoutput>"><i class="fa fa-circle-user me-2"></i><cfoutput>#REQUEST.t("common.header.myProfile")#</cfoutput></a></li>
                            <li><a class="dropdown-item" href="<cfoutput>#VARIABLES.headerUserSettingsPath#</cfoutput>"><i class="fa-solid fa-gear me-2"></i><cfoutput>#REQUEST.t("athlete.tabs.settings")#</cfoutput></a></li>
                            <!---<li><a class="dropdown-item" href="/clube/"><i class="fa fa-flag me-2"></i>Meu clube</a></li>--->
                            <!---<li><a class="dropdown-item" href="/carteira"><i class="fa-solid fa-wallet me-2"></i>Minha carteira</a></li>--->
                            <li id="rrPwaPushMenuItem" style="display:none;">
                                <a class="dropdown-item" href="#" id="rrPwaPushMenuLink">
                                    <i class="fa-solid fa-bell me-2"></i><span id="rrPwaPushMenuLabel"><cfoutput>#REQUEST.t("notifications.push.menuActivate")#</cfoutput></span>
                                </a>
                            </li>
                            <li id="rrPwaPushPreferencesMenuItem" style="display:none;">
                                <a class="dropdown-item" href="#" id="rrPwaPushPreferencesMenuLink">
                                    <i class="fa-solid fa-sliders me-2"></i><cfoutput>#REQUEST.t("notifications.push.preferencesMenu")#</cfoutput>
                                </a>
                            </li>
                            <li id="rrPwaInstallMenuItem" style="display:none;">
                                <a class="dropdown-item" href="#" id="rrPwaInstallMenuLink">
                                    <i class="fa-solid fa-mobile-screen-button me-2"></i><cfoutput>#REQUEST.t("common.header.installApp")#</cfoutput>
                                </a>
                            </li>
                            <li><hr class="dropdown-divider m-0"></li>
                            <!---li><a class="dropdown-item" href="/perfil/?filtro=powerups"><i class="fa fa-bolt me-2"></i>Power-Ups</a></li--->
                            <!---<li><a class="dropdown-item" href="https://whatsapp.com/channel/0029VaAE7vc2975GuUCHIK0K" target="_blank"><i class="fa-brands fa-whatsapp me-2"></i>Canal no WhatsApp</a></li>--->
                            <li><a class="dropdown-item" href="#" data-mobile-onboarding-open><i class="fa-solid fa-wand-magic-sparkles me-2"></i><cfoutput>#REQUEST.t("common.header.quickTips")#</cfoutput></a></li>
                            <li><a class="dropdown-item" href="<cfoutput>#REQUEST.i18nBuildPath('help')#</cfoutput>"><i class="fa-solid fa-circle-question me-2"></i><cfoutput>#REQUEST.t("common.header.help")#</cfoutput></a></li>
                            <li><a class="dropdown-item" href="<cfoutput>#REQUEST.i18nBuildPath('support')#</cfoutput>"><i class="fa-solid fa-headset me-2"></i><cfoutput>#REQUEST.t("common.header.support")#</cfoutput></a></li>
                            <li><div class="dropdown-item link" data-mdb-modal-init data-mdb-target="#modal_evento_cadastro"><i class="fa-solid fa-lightbulb me-2"></i><cfoutput>#REQUEST.t("help.actions.suggestEvent")#</cfoutput></div></li>
                            <li><a class="dropdown-item" href="<cfoutput>#REQUEST.i18nBuildPath('about')#</cfoutput>"><i class="fa-solid fa-circle-info me-2"></i><cfoutput>#REQUEST.t("common.header.about")#</cfoutput></a></li>
                            <li><a class="dropdown-item" href="<cfoutput>#REQUEST.i18nBuildPath('privacy')#</cfoutput>"><i class="fa-solid fa-shield me-2"></i><cfoutput>#REQUEST.t("common.header.privacy")#</cfoutput></a></li>
                            <li><button type="button" class="dropdown-item" data-audience-privacy-open aria-haspopup="dialog" aria-controls="rr-audience-privacy-dialog" aria-expanded="false"><i class="fa-solid fa-chart-simple me-2" aria-hidden="true"></i><cfoutput>#REQUEST.t("common.audiencePrivacy.title")#</cfoutput></button></li>
                            <cfset REQUEST.rrAudiencePrivacyMenuLinkRendered = true/>
                            <cfif len(trim(VARIABLES.headerI18nRouteKey))>
                                <li><hr class="dropdown-divider m-0"></li>
                                <li>
                                    <div class="dropdown-item-text d-flex align-items-center gap-2 px-3 py-2" aria-label="<cfoutput>#REQUEST.t('common.languageSwitcherLabel')#</cfoutput>">
                                        <i class="fa-solid fa-language"></i>
                                        <div class="rr-language-switch">
                                            <cfloop array="#REQUEST.availableLanguages#" index="languageOption">
                                                <cfoutput>
                                                    <a
                                                        class="rr-language-switch-link<cfif REQUEST.lang EQ languageOption.code> is-active</cfif>"
                                                        href="#REQUEST.i18nBuildPath(VARIABLES.headerI18nRouteKey, languageOption.code)#"
                                                        lang="#languageOption.code#"
                                                        hreflang="#languageOption.hreflang#">#languageOption.shortLabel#</a>
                                                </cfoutput>
                                            </cfloop>
                                        </div>
                                    </div>
                                </li>
                            </cfif>
                            <li><hr class="dropdown-divider m-0"></li>
                            <li><a class="dropdown-item" href="#" onclick="signOut()"><i class="fa fa-sign-out me-2"></i><cfoutput>#REQUEST.t("common.header.logout")#</cfoutput></a></li>
                        </ul>
                    </div>

                </cfif>

            </div>

        </div>

    </nav>

</header>

<script>
    (function () {
        const topbar = document.querySelector('.rr-topbar.navbar');
        const nav = document.querySelector('[data-desktop-nav]');

        if (!topbar || !nav) {
            return;
        }

        const desktopQuery = window.matchMedia('(min-width: 768px)');
        const searchToggle = nav.querySelector('[data-home-hero-toggle]');
        let searchIsSelected = false;

        const clamp = function (value, min, max) {
            return Math.min(max, Math.max(min, value));
        };

        const hideIndicator = function () {
            topbar.style.setProperty('--rr-desktop-active-width', '0px');
            topbar.style.setProperty('--rr-desktop-active-opacity', '0');
        };

        const getCurrentItem = function () {
            const activeItem = nav.querySelector('.nav-link.active');
            const expandedSearchToggle = searchToggle && searchToggle.getAttribute('aria-expanded') === 'true' ? searchToggle : null;

            if (expandedSearchToggle && (searchIsSelected || !activeItem)) {
                return expandedSearchToggle;
            }

            searchIsSelected = false;
            return activeItem;
        };

        const applyIndicator = function (item) {
            if (!desktopQuery.matches || !item) {
                hideIndicator();
                return;
            }

            const topbarRect = topbar.getBoundingClientRect();
            const itemRect = item.getBoundingClientRect();

            if (!itemRect.width) {
                hideIndicator();
                return;
            }

            const indicatorWidth = clamp(itemRect.width * 0.42, 18, 34);
            const indicatorX = (itemRect.left - topbarRect.left) + (itemRect.width / 2) - (indicatorWidth / 2);

            topbar.style.setProperty('--rr-desktop-active-x', indicatorX.toFixed(2) + 'px');
            topbar.style.setProperty('--rr-desktop-active-width', indicatorWidth.toFixed(2) + 'px');
            topbar.style.setProperty('--rr-desktop-active-opacity', '1');
        };

        const syncIndicator = function () {
            applyIndicator(getCurrentItem());
        };

        syncIndicator();
        window.requestAnimationFrame(function () {
            topbar.classList.add('is-desktop-indicator-ready');
        });

        nav.querySelectorAll('.nav-link').forEach(function (item) {
            item.addEventListener('click', function () {
                if (!desktopQuery.matches) {
                    return;
                }

                searchIsSelected = item === searchToggle;
                applyIndicator(item);

                if (item === searchToggle) {
                    window.setTimeout(syncIndicator, 0);
                }
            });
        });

        if (searchToggle && window.MutationObserver) {
            const observer = new MutationObserver(syncIndicator);
            observer.observe(searchToggle, {
                attributes: true,
                attributeFilter: ['aria-expanded']
            });
        }

        window.addEventListener('resize', function () {
            window.requestAnimationFrame(syncIndicator);
        });
    })();
</script>


<!---MENU MOBILE--->

<style>
    .mobile-bottom-nav {
        --rr-mobile-active-x: 0px;
        --rr-mobile-active-width: 0px;
        --rr-mobile-active-opacity: 0;
        display: grid !important;
        grid-template-columns: repeat(3, minmax(0, 1fr)) auto repeat(3, minmax(0, 1fr));
        column-gap: 0.12rem;
        align-items: center;
        padding-left: 0.3rem !important;
        padding-right: 0.3rem !important;
        padding-top: 0 !important;
        padding-bottom: calc(env(safe-area-inset-bottom, 0px) + 0.05rem) !important;
    }

    .mobile-bottom-nav::after {
        content: "";
        position: absolute;
        left: 0;
        bottom: 0;
        width: var(--rr-mobile-active-width);
        height: 2px;
        border-radius: 999px 999px 0 0;
        background: #f4b120;
        opacity: var(--rr-mobile-active-opacity);
        pointer-events: none;
        transform: translate3d(var(--rr-mobile-active-x), 0, 0);
        transition: none;
        z-index: 2;
    }

    .mobile-bottom-nav.is-indicator-ready::after {
        transition: transform 170ms cubic-bezier(0.22, 0.8, 0.22, 1), width 170ms cubic-bezier(0.22, 0.8, 0.22, 1), opacity 120ms ease;
    }

    .mobile-bottom-nav .nav-item {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 2.85rem;
        min-width: 0;
        width: 100%;
    }

    .mobile-bottom-nav .nav-link {
        display: flex;
        align-items: center;
        justify-content: center;
        position: relative;
        width: 100%;
        min-height: 2.65rem;
        padding-top: 0 !important;
        padding-bottom: 0.1rem !important;
    }

    .mobile-bottom-nav button.nav-link {
        appearance: none;
        border: 0;
        background: transparent;
    }

    .mobile-bottom-nav .nav-link > i {
        font-size: 1.42rem !important;
    }

    .mobile-nav-user-item {
        position: relative;
    }

    .mobile-nav-user-link {
        min-height: 100%;
        padding-bottom: 0.05rem !important;
    }

    .mobile-nav-user-avatar {
        width: 46px;
        height: 46px;
        object-fit: cover;
        border-radius: 999px;
        border: 2px solid rgba(0, 0, 0, 0.5);
        background: #ffffff;
        transform: translateY(-8px);
    }

    .mobile-nav-home-icon {
        width: 1.58rem;
        height: 1.58rem;
        display: inline-block;
        vertical-align: middle;
    }

    .mobile-nav-home-icon path {
        fill: currentColor !important;
    }

    .mobile-bottom-nav .nav-link.active .mobile-nav-home-icon path:nth-of-type(n + 3) {
        fill: #ffffff !important;
    }

    .rr-mobile-onboarding {
        display: none;
    }

    @media (min-width: 768px) {
        .mobile-bottom-nav {
            display: none !important;
        }

        body.rr-mobile-onboarding-open {
            overflow: hidden !important;
        }

        .rr-mobile-onboarding:not([hidden]) {
            position: fixed;
            inset: 0;
            z-index: 2140;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem;
            background: rgba(15, 15, 15, 0.88);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
        }

        .rr-mobile-onboarding-panel {
            width: min(100%, 390px);
            display: grid;
            gap: 1.05rem;
            text-align: center;
        }

        .rr-mobile-onboarding-brand {
            display: grid;
            justify-items: center;
            gap: 1rem;
        }

        .rr-mobile-onboarding-logo {
            width: 216px;
            height: auto;
            display: block;
        }

        .rr-mobile-onboarding-kicker {
            color: rgba(255, 255, 255, 0.82);
            font-size: 0.78rem;
            font-weight: 900;
            letter-spacing: 0.12em;
            line-height: 1;
            text-transform: uppercase;
        }

        .rr-mobile-onboarding-track {
            display: flex;
            gap: 0.85rem;
            overflow-x: auto;
            overflow-y: hidden;
            scroll-snap-type: x mandatory;
            scrollbar-width: none;
            -webkit-overflow-scrolling: touch;
        }

        .rr-mobile-onboarding-track::-webkit-scrollbar {
            display: none;
        }

        .rr-mobile-onboarding-slide {
            flex: 0 0 100%;
            min-height: 300px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 0.7rem;
            padding: 1.45rem 1.35rem;
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 22px;
            background: rgba(255, 255, 255, 0.035);
            scroll-snap-align: center;
        }

        .rr-mobile-onboarding-icon {
            width: 6.1rem;
            height: 6.1rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: #d8d8d8;
            font-size: 5rem;
            line-height: 1;
        }

        .rr-mobile-onboarding-icon img {
            width: 100%;
            height: 100%;
            display: block;
            object-fit: contain;
        }

        .rr-mobile-onboarding-title {
            color: #ffffff;
            font-size: 1.32rem;
            font-weight: 900;
            line-height: 1.1;
            margin: 0.2rem 0 0;
        }

        .rr-mobile-onboarding-copy {
            max-width: 16rem;
            color: rgba(255, 255, 255, 0.84);
            font-size: 0.92rem;
            font-weight: 700;
            line-height: 1.28;
            margin: 0;
        }

        .rr-mobile-onboarding-dots {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.42rem;
        }

        .rr-mobile-onboarding-dot {
            width: 0.42rem;
            height: 0.42rem;
            border: 0;
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.34);
            padding: 0;
            transition: width 0.2s ease, background-color 0.2s ease;
        }

        .rr-mobile-onboarding-dot.is-active {
            width: 1.25rem;
            background: #f4b120;
        }

        .rr-mobile-onboarding-skip {
            justify-self: center;
            border: 0;
            background: transparent;
            color: rgba(255, 255, 255, 0.58);
            font-size: 0.72rem;
            font-weight: 900;
            letter-spacing: 0.12em;
            line-height: 1;
            padding: 0.35rem 0.55rem;
            text-transform: uppercase;
        }

        .rr-mobile-onboarding-skip:hover,
        .rr-mobile-onboarding-skip:focus {
            color: #ffffff;
        }
    }

    @media (max-width: 767.98px) {
        html,
        body {
            overflow-x: hidden !important;
            overscroll-behavior-x: none;
        }

        body.rr-mobile-onboarding-open {
            overflow: hidden !important;
        }

        .rr-mobile-onboarding {
            position: fixed;
            inset: 0;
            z-index: 2140;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: max(1.35rem, env(safe-area-inset-top, 0px)) 1rem calc(env(safe-area-inset-bottom, 0px) + 1.35rem);
            background: rgba(15, 15, 15, 0.88);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
        }

        .rr-mobile-onboarding[hidden] {
            display: none !important;
        }

        .rr-mobile-onboarding-panel {
            width: min(100%, 390px);
            display: grid;
            gap: 1.05rem;
            text-align: center;
        }

        .rr-mobile-onboarding-brand {
            display: grid;
            justify-items: center;
            gap: 1rem;
        }

        .rr-mobile-onboarding-logo {
            width: 216px;
            height: auto;
            display: block;
        }

        .rr-mobile-onboarding-logo path[fill="#ffffff"],
        .rr-mobile-onboarding-logo g[fill="#ffffff"] {
            fill: #ffffff !important;
        }

        .rr-mobile-onboarding-logo path[fill="#f4b120"],
        .rr-mobile-onboarding-logo g[fill="#f4b120"] {
            fill: #f4b120 !important;
        }

        .rr-mobile-onboarding-kicker {
            color: rgba(255, 255, 255, 0.82);
            font-size: 0.78rem;
            font-weight: 900;
            letter-spacing: 0.12em;
            line-height: 1;
            text-transform: uppercase;
        }

        .rr-mobile-onboarding-track {
            display: flex;
            gap: 0.85rem;
            overflow-x: auto;
            overflow-y: hidden;
            scroll-snap-type: x mandatory;
            scrollbar-width: none;
            -webkit-overflow-scrolling: touch;
        }

        .rr-mobile-onboarding-track::-webkit-scrollbar {
            display: none;
        }

        .rr-mobile-onboarding-slide {
            flex: 0 0 100%;
            min-height: 300px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 0.7rem;
            padding: 1.45rem 1.35rem;
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 22px;
            background: rgba(255, 255, 255, 0.035);
            scroll-snap-align: center;
        }

        .rr-mobile-onboarding-icon {
            width: 6.1rem;
            height: 6.1rem;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: #d8d8d8;
            font-size: 5rem;
            line-height: 1;
        }

        .rr-mobile-onboarding-icon img {
            width: 100%;
            height: 100%;
            display: block;
            object-fit: contain;
        }

        .rr-mobile-onboarding-title {
            color: #ffffff;
            font-size: 1.32rem;
            font-weight: 900;
            line-height: 1.1;
            margin: 0.2rem 0 0;
        }

        .rr-mobile-onboarding-copy {
            max-width: 16rem;
            color: rgba(255, 255, 255, 0.84);
            font-size: 0.92rem;
            font-weight: 700;
            line-height: 1.28;
            margin: 0;
        }

        .rr-mobile-onboarding-dots {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.42rem;
        }

        .rr-mobile-onboarding-dot {
            width: 0.42rem;
            height: 0.42rem;
            border: 0;
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.34);
            padding: 0;
            transition: width 0.2s ease, background-color 0.2s ease;
        }

        .rr-mobile-onboarding-dot.is-active {
            width: 1.25rem;
            background: #f4b120;
        }

        .rr-mobile-onboarding-skip {
            justify-self: center;
            border: 0;
            background: transparent;
            color: rgba(255, 255, 255, 0.58);
            font-size: 0.72rem;
            font-weight: 900;
            letter-spacing: 0.12em;
            line-height: 1;
            padding: 0.35rem 0.55rem;
            text-transform: uppercase;
        }

        .rr-mobile-onboarding-skip:hover,
        .rr-mobile-onboarding-skip:focus {
            color: #ffffff;
        }

        .mobile-bottom-nav {
            position: fixed !important;
            top: auto !important;
            right: 0 !important;
            bottom: 0 !important;
            left: 0 !important;
            transform: none !important;
            transition: none !important;
            will-change: auto;
        }

        html.rr-mobile-swipe-active .mobile-bottom-nav {
            top: auto !important;
            bottom: 0 !important;
            transform: translate3d(0, 0, 0) !important;
            transition: none !important;
        }

        .mobile-bottom-nav .nav-link,
        .mobile-bottom-nav .nav-link:hover,
        .mobile-bottom-nav .nav-link:focus {
            border-color: transparent !important;
            border-bottom-color: transparent !important;
        }

        .mobile-bottom-nav.is-indicator-ready .nav-link.active {
            border-color: transparent !important;
            border-bottom-color: transparent !important;
        }

        #rr-page-content {
            touch-action: pan-y;
            will-change: transform, opacity;
        }
    }
</style>

<ul class="nav nav-tabs nav-justified d-md-none w-100 position-fixed bottom-0 start-0 z-3 mobile-bottom-nav"
    id="ex1" role="tablist" data-mdb-theme="dark"
    style="background-color:#444444;box-shadow: 0px 10px 10px 0px rgba(0,0,0,0.2) inset;">

    <li class="nav-item">
        <a class="nav-link p-2 <cfif VARIABLES.template EQ "/">active</cfif>" data-mobile-swipe-id="home" href="<cfoutput>#VARIABLES.headerHomePath#</cfoutput>">
            <svg class="mobile-nav-home-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192" preserveAspectRatio="xMidYMid meet" aria-hidden="true">
                <path fill="#ffffff" d="M100.57,174.17c-1.55,0-2.68-.57-3.39-1.7-.72-1.13-.97-2.57-.76-4.31L117.05,21.44c.2-1.44.5-2.31.92-2.61.41-.3,1.33-.46,2.77-.46h14.33c1.12,0,2.04.42,2.76,1.24.72.81.98,1.68.78,2.6l-21.09,150.13c-.11.81-.31,1.32-.62,1.52-.31.21-.97.32-2,.32h-14.33Z"/>
                <path fill="#ffffff" d="M138.29,174.17c-1.55,0-2.68-.57-3.39-1.7-.72-1.13-.97-2.57-.76-4.31l20.63-146.73c.2-1.44.5-2.31.92-2.61.41-.3,1.33-.46,2.77-.46h14.33c1.12,0,2.04.42,2.76,1.24.72.81.98,1.68.78,2.6l-21.09,150.13c-.11.81-.31,1.32-.62,1.52-.31.21-.97.32-2,.32h-14.33Z"/>
                <path fill="#ffffff" d="M74.5,171.27c.11.3.18.65.18,1.06,0,.9-.57,1.34-1.7,1.34h-17.28c-.65,0-1.16-.16-1.52-.48-.35-.33-.62-.94-.79-1.84l-5.16-22.96c-.12-.36-.26-.62-.41-.76-.14-.15-.45-.23-.94-.23h-5.33c-.47,0-.8.09-.99.26-.18.18-.3.45-.35.81l-3.29,23.14c-.12.9-.4,1.46-.85,1.7-.45.24-1.24.35-2.37.35h-14.94c-1.55,0-2.2-.92-1.96-2.76l8.73-61.79c.06-.64.19-1.06.39-1.24.21-.19.58-.28,1.11-.28h29.75c7.89,0,14.01,1.5,18.37,4.5,4.37,2.99,6.55,7.16,6.55,12.51,0,4.34-1.26,8.35-3.78,12.03-2.52,3.67-5.8,6.32-9.84,7.91-.78.3-1.25.56-1.4.79-.14.24-.15.57-.04.99l7.84,24.93ZM52.24,134.14c2.42,0,4.46-.83,6.09-2.49,1.63-1.66,2.46-3.59,2.46-5.78,0-1.67-.61-2.94-1.84-3.8-1.21-.86-2.77-1.29-4.66-1.29h-9.08c-.42,0-.72.12-.9.37-.18.24-.33.71-.44,1.41l-1.52,10.25v.44c0,.35.07.59.21.71.15.12.41.18.78.18h8.9Z"/>
                <path fill="#ffffff" d="M87.62,82.46c.11.3.18.65.18,1.06,0,.9-.57,1.34-1.7,1.34h-17.28c-.65,0-1.16-.16-1.52-.48-.35-.33-.62-.94-.79-1.84l-5.16-22.96c-.12-.36-.26-.62-.41-.76-.14-.15-.45-.23-.94-.23h-5.33c-.47,0-.8.09-.99.26-.18.18-.3.45-.35.81l-3.29,23.14c-.12.9-.4,1.46-.85,1.7-.45.24-1.24.35-2.37.35h-14.94c-1.55,0-2.2-.92-1.96-2.76l8.73-61.79c.06-.64.19-1.06.39-1.24.21-.19.58-.28,1.11-.28h29.75c7.89,0,14.01,1.5,18.37,4.5,4.37,2.99,6.55,7.16,6.55,12.51,0,4.34-1.26,8.35-3.78,12.03-2.52,3.67-5.8,6.32-9.84,7.91-.78.3-1.25.56-1.4.79-.14.24-.15.57-.04.99l7.84,24.93ZM65.36,45.33c2.42,0,4.46-.83,6.09-2.49,1.63-1.66,2.46-3.59,2.46-5.78,0-1.67-.61-2.94-1.84-3.8-1.21-.86-2.77-1.29-4.66-1.29h-9.08c-.42,0-.72.12-.9.37-.18.24-.33.71-.44,1.41l-1.52,10.25v.44c0,.35.07.59.21.71.15.12.41.18.78.18h8.9Z"/>
            </svg>
        </a>
    </li>

    <li class="nav-item">
        <cfif Usuario.logado>
            <a class="nav-link p-2 <cfif VARIABLES.template EQ "/atividades/">active</cfif>" data-mobile-swipe-id="activities" href="<cfoutput>#VARIABLES.headerActivitiesPath#</cfoutput>">
                <i class="fa-solid fa-list"></i>
            </a>
        <cfelse>
            <a class="nav-link p-2" data-mobile-swipe-id="activities" href="#" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil">
                <i class="fa-solid fa-list"></i>
            </a>
        </cfif>
    </li>

    <li class="nav-item">
        <a class="nav-link p-2 <cfif listFindNoCase("/estado/,/evento/,/maratona/,/circuito/,/corrida/", VARIABLES.template)>active</cfif>" data-mobile-swipe-id="events" href="<cfoutput>#VARIABLES.headerEventsPath#</cfoutput>" title="<cfoutput>#VARIABLES.headerEventsTitle#</cfoutput>" aria-label="<cfoutput>#VARIABLES.headerEventsTitle#</cfoutput>">
            <i class="fa-solid fa-calendar-days"></i>
        </a>
    </li>

    <li class="nav-item mobile-nav-user-item">
        <cfif Usuario.logado>
        <a class="nav-link p-1 mobile-nav-user-link <cfif VARIABLES.template EQ "/atleta/">active</cfif>" data-mobile-swipe-id="athlete" href="<cfoutput>#VARIABLES.headerUserProfilePath#</cfoutput>">
            <img src="<cfoutput>#Usuario.imagem_usuario#</cfoutput>" alt="<cfoutput>#REQUEST.t('common.header.myProfile')#</cfoutput>" class="mobile-nav-user-avatar" onerror="this.src='/assets/user.png';">
        </a>
        <cfelse>
        <a class="nav-link p-1 mobile-nav-user-link" data-mobile-swipe-id="athlete" href="#" data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil">
            <img src="/assets/user.png" alt="<cfoutput>#REQUEST.t('common.header.login')#</cfoutput>" class="mobile-nav-user-avatar" onerror="this.src='/assets/user.png';"
             data-mdb-modal-init data-mdb-target="#modalLogin" data-mdb-acao="perfil">
        </a>
        </cfif>
    </li>

    <li class="nav-item">
        <a class="nav-link p-2 <cfif VARIABLES.template EQ "/noticias/">active</cfif>" data-mobile-swipe-id="news" href="<cfoutput>#VARIABLES.headerNewsPath#</cfoutput>">
            <i class="fa-solid fa-newspaper"></i>
        </a>
    </li>

    <li class="nav-item">
        <a class="nav-link p-2 <cfif VARIABLES.template EQ "/videos/">active</cfif>" data-mobile-swipe-id="videos" href="<cfoutput>#VARIABLES.headerVideosPath#</cfoutput>">
            <i class="fa-brands fa-youtube"></i>
        </a>
    </li>

    <li class="nav-item">
        <button type="button"
                class="nav-link p-2"
                data-mobile-swipe-id="search"
                data-mobile-swipe-action="search"
                data-home-hero-toggle
                aria-controls="homeHeroSearch"
                aria-expanded="<cfoutput>#VARIABLES.template EQ "/" ? "true" : "false"#</cfoutput>"
                title="<cfoutput>#HTMLEditFormat(REQUEST.t('common.header.toggleSearch'))#</cfoutput>"
                aria-label="<cfoutput>#HTMLEditFormat(REQUEST.t('common.header.toggleSearch'))#</cfoutput>">
            <i class="fa-solid fa-magnifying-glass"></i>
        </button>
    </li>

</ul>

<div class="rr-mobile-onboarding" data-mobile-onboarding hidden aria-hidden="true">
    <div class="rr-mobile-onboarding-panel" role="dialog" aria-modal="true" aria-label="Road Runners mobile onboarding">
        <div class="rr-mobile-onboarding-brand">
            <img class="rr-mobile-onboarding-logo" src="/assets/rr_logo_neg.png" alt="Road Runners" loading="lazy" />
            <div class="rr-mobile-onboarding-kicker"><cfoutput>#REQUEST.t("common.mobileOnboarding.kicker")#</cfoutput></div>
        </div>

        <div class="rr-mobile-onboarding-track" data-mobile-onboarding-track>
            <section class="rr-mobile-onboarding-slide" data-mobile-onboarding-slide>
                <div class="rr-mobile-onboarding-icon">
                    <img src="/assets/swipe.svg" alt="" loading="lazy" />
                </div>
                <h2 class="rr-mobile-onboarding-title"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.swipe.title")#</cfoutput></h2>
                <p class="rr-mobile-onboarding-copy"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.swipe.description")#</cfoutput></p>
            </section>

            <section class="rr-mobile-onboarding-slide" data-mobile-onboarding-slide>
                <div class="rr-mobile-onboarding-icon">
                    <i class="fa-solid fa-list"></i>
                </div>
                <h2 class="rr-mobile-onboarding-title"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.activities.title")#</cfoutput></h2>
                <p class="rr-mobile-onboarding-copy"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.activities.description")#</cfoutput></p>
            </section>

            <section class="rr-mobile-onboarding-slide" data-mobile-onboarding-slide>
                <div class="rr-mobile-onboarding-icon">
                    <i class="fa-solid fa-calendar"></i>
                </div>
                <h2 class="rr-mobile-onboarding-title"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.agenda.title")#</cfoutput></h2>
                <p class="rr-mobile-onboarding-copy"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.agenda.description")#</cfoutput></p>
            </section>

            <section class="rr-mobile-onboarding-slide" data-mobile-onboarding-slide>
                <div class="rr-mobile-onboarding-icon">
                    <i class="fa-solid fa-medal"></i>
                </div>
                <h2 class="rr-mobile-onboarding-title"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.results.title")#</cfoutput></h2>
                <p class="rr-mobile-onboarding-copy"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.results.description")#</cfoutput></p>
            </section>

            <section class="rr-mobile-onboarding-slide" data-mobile-onboarding-slide>
                <div class="rr-mobile-onboarding-icon">
                    <i class="fa-solid fa-trophy"></i>
                </div>
                <h2 class="rr-mobile-onboarding-title"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.challenges.title")#</cfoutput></h2>
                <p class="rr-mobile-onboarding-copy"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.challenges.description")#</cfoutput></p>
            </section>

            <section class="rr-mobile-onboarding-slide" data-mobile-onboarding-slide>
                <div class="rr-mobile-onboarding-icon">
                    <i class="fa-solid fa-newspaper"></i>
                </div>
                <h2 class="rr-mobile-onboarding-title"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.news.title")#</cfoutput></h2>
                <p class="rr-mobile-onboarding-copy"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.news.description")#</cfoutput></p>
            </section>

            <section class="rr-mobile-onboarding-slide" data-mobile-onboarding-slide>
                <div class="rr-mobile-onboarding-icon">
                    <i class="fa-brands fa-youtube"></i>
                </div>
                <h2 class="rr-mobile-onboarding-title"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.videos.title")#</cfoutput></h2>
                <p class="rr-mobile-onboarding-copy"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.videos.description")#</cfoutput></p>
            </section>

            <section class="rr-mobile-onboarding-slide" data-mobile-onboarding-slide>
                <div class="rr-mobile-onboarding-icon">
                    <i class="fa-solid fa-magnifying-glass"></i>
                </div>
                <h2 class="rr-mobile-onboarding-title"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.search.title")#</cfoutput></h2>
                <p class="rr-mobile-onboarding-copy"><cfoutput>#REQUEST.t("common.mobileOnboarding.slides.search.description")#</cfoutput></p>
            </section>
        </div>

        <div class="rr-mobile-onboarding-dots" data-mobile-onboarding-dots>
            <button type="button" class="rr-mobile-onboarding-dot is-active" data-mobile-onboarding-dot aria-label="1/8"></button>
            <button type="button" class="rr-mobile-onboarding-dot" data-mobile-onboarding-dot aria-label="2/8"></button>
            <button type="button" class="rr-mobile-onboarding-dot" data-mobile-onboarding-dot aria-label="3/8"></button>
            <button type="button" class="rr-mobile-onboarding-dot" data-mobile-onboarding-dot aria-label="4/8"></button>
            <button type="button" class="rr-mobile-onboarding-dot" data-mobile-onboarding-dot aria-label="5/8"></button>
            <button type="button" class="rr-mobile-onboarding-dot" data-mobile-onboarding-dot aria-label="6/8"></button>
            <button type="button" class="rr-mobile-onboarding-dot" data-mobile-onboarding-dot aria-label="7/8"></button>
            <button type="button" class="rr-mobile-onboarding-dot" data-mobile-onboarding-dot aria-label="8/8"></button>
        </div>

        <button type="button"
                class="rr-mobile-onboarding-skip"
                data-mobile-onboarding-skip
                data-mobile-onboarding-skip-label="<cfoutput>#HTMLEditFormat(REQUEST.t("common.mobileOnboarding.skip"))#</cfoutput>"
                data-mobile-onboarding-understood-label="<cfoutput>#HTMLEditFormat(REQUEST.t("common.mobileOnboarding.understood"))#</cfoutput>">
            <cfoutput>#REQUEST.t("common.mobileOnboarding.skip")#</cfoutput>
        </button>
    </div>
</div>

<script>
    (function () {
        const overlay = document.querySelector('[data-mobile-onboarding]');
        const track = overlay ? overlay.querySelector('[data-mobile-onboarding-track]') : null;
        const slides = track ? Array.from(track.querySelectorAll('[data-mobile-onboarding-slide]')) : [];
        const dots = overlay ? Array.from(overlay.querySelectorAll('[data-mobile-onboarding-dot]')) : [];
        const skipButton = overlay ? overlay.querySelector('[data-mobile-onboarding-skip]') : null;
        const openButtons = Array.from(document.querySelectorAll('[data-mobile-onboarding-open]'));
        const mobileQuery = window.matchMedia('(max-width: 767.98px)');
        const storageKey = 'rr.mobileOnboarding.dismissed.v1';
        let scrollFrame = 0;

        if (!overlay || !track || !slides.length || !skipButton) {
            return;
        }

        const getDismissed = function () {
            try {
                return window.localStorage.getItem(storageKey) === '1';
            } catch (error) {
                return false;
            }
        };

        const setDismissed = function () {
            try {
                window.localStorage.setItem(storageKey, '1');
            } catch (error) {}
        };

        const setVisible = function (visible) {
            overlay.hidden = !visible;
            overlay.setAttribute('aria-hidden', visible ? 'false' : 'true');
            document.body.classList.toggle('rr-mobile-onboarding-open', visible);
        };

        const dismiss = function () {
            setDismissed();
            setVisible(false);
        };

        const scrollToFirstSlide = function () {
            if (!slides[0]) {
                return;
            }

            slides[0].scrollIntoView({
                behavior: 'auto',
                block: 'nearest',
                inline: 'center'
            });
        };

        const getActiveIndex = function () {
            const trackRect = track.getBoundingClientRect();
            const trackCenter = trackRect.left + (trackRect.width / 2);
            let activeIndex = 0;
            let closestDistance = Infinity;

            slides.forEach(function (slide, index) {
                const slideRect = slide.getBoundingClientRect();
                const slideCenter = slideRect.left + (slideRect.width / 2);
                const distance = Math.abs(trackCenter - slideCenter);

                if (distance < closestDistance) {
                    closestDistance = distance;
                    activeIndex = index;
                }
            });

            return activeIndex;
        };

        const updateDots = function () {
            const activeIndex = getActiveIndex();
            const isLastSlide = activeIndex === slides.length - 1;

            dots.forEach(function (dot, index) {
                dot.classList.toggle('is-active', index === activeIndex);
            });

            skipButton.textContent = isLastSlide
                ? (skipButton.getAttribute('data-mobile-onboarding-understood-label') || 'Entendi')
                : (skipButton.getAttribute('data-mobile-onboarding-skip-label') || 'Pular');
        };

        const requestDotUpdate = function () {
            if (scrollFrame) {
                return;
            }

            scrollFrame = window.requestAnimationFrame(function () {
                scrollFrame = 0;
                updateDots();
            });
        };

        const syncVisibility = function () {
            // Tips are opened explicitly from the menu, never over the first visit.
            if (!mobileQuery.matches) setVisible(false);
        };

        dots.forEach(function (dot, index) {
            dot.addEventListener('click', function () {
                if (slides[index]) {
                    slides[index].scrollIntoView({
                        behavior: 'smooth',
                        block: 'nearest',
                        inline: 'center'
                    });
                }
            });
        });

        openButtons.forEach(function (button) {
            button.addEventListener('click', function (event) {
                event.preventDefault();
                setVisible(true);
                scrollToFirstSlide();
                window.requestAnimationFrame(updateDots);
            });
        });

        track.addEventListener('scroll', requestDotUpdate, { passive: true });
        skipButton.addEventListener('click', dismiss);

        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape' && !overlay.hidden) {
                dismiss();
            }
        });

        if (mobileQuery.addEventListener) {
            mobileQuery.addEventListener('change', syncVisibility);
        } else if (mobileQuery.addListener) {
            mobileQuery.addListener(syncVisibility);
        }

        syncVisibility();
    })();
</script>

<script>
    (function () {
        const nav = document.querySelector('.mobile-bottom-nav');
        const activeLink = nav ? nav.querySelector('[data-mobile-swipe-id].active') : null;

        if (!nav || !activeLink) {
            return;
        }

        const clamp = function (value, min, max) {
            return Math.min(max, Math.max(min, value));
        };

        const navRect = nav.getBoundingClientRect();
        const linkRect = activeLink.getBoundingClientRect();
        const indicatorWidth = clamp(linkRect.width * 0.46, 18, 30);
        const indicatorX = (linkRect.left - navRect.left) + (linkRect.width / 2) - (indicatorWidth / 2);

        nav.style.setProperty('--rr-mobile-active-x', indicatorX.toFixed(2) + 'px');
        nav.style.setProperty('--rr-mobile-active-width', indicatorWidth.toFixed(2) + 'px');
        nav.style.setProperty('--rr-mobile-active-opacity', '1');
    })();
</script>

<!--- ESPACAMENTO --->

<div class="my-4 py-2"></div>

<script>
    (function () {
        const initMobileContentSwipe = function () {
            const mobileQuery = window.matchMedia('(max-width: 767.98px)');
            if (!mobileQuery.matches) {
                return;
            }

            const nav = document.querySelector('.mobile-bottom-nav');
            if (nav && nav.parentElement !== document.body) {
                document.body.appendChild(nav);
            }

            const content = document.getElementById('rr-page-content');
            if (!content || !nav) {
                return;
            }

            const swipeItems = Array.from(nav.querySelectorAll('[data-mobile-swipe-id]'))
                .map((link) => ({
                    id: link.getAttribute('data-mobile-swipe-id') || '',
                    href: (link.getAttribute('href') || '').trim(),
                    action: (link.getAttribute('data-mobile-swipe-action') || '').trim(),
                    link
                }))
                .filter((item) => item.id && ((item.href && item.href !== '#') || item.action));

            if (swipeItems.length < 2) {
                return;
            }

            let activeIndex = swipeItems.findIndex((item) => item.link.classList.contains('active'));
            if (activeIndex < 0) {
                return;
            }

            const clamp = function (value, min, max) {
                return Math.min(max, Math.max(min, value));
            };

            const getIndicatorMetrics = function (link) {
                const navRect = nav.getBoundingClientRect();
                const linkRect = link.getBoundingClientRect();
                const indicatorWidth = clamp(linkRect.width * 0.46, 18, 30);

                return {
                    x: (linkRect.left - navRect.left) + (linkRect.width / 2) - (indicatorWidth / 2),
                    width: indicatorWidth
                };
            };

            const applyIndicatorMetrics = function (metrics) {
                nav.style.setProperty('--rr-mobile-active-x', metrics.x.toFixed(2) + 'px');
                nav.style.setProperty('--rr-mobile-active-width', metrics.width.toFixed(2) + 'px');
                nav.style.setProperty('--rr-mobile-active-opacity', '1');
            };

            const syncActiveIndicator = function () {
                const activeItem = swipeItems[activeIndex];
                if (!activeItem) {
                    return;
                }

                applyIndicatorMetrics(getIndicatorMetrics(activeItem.link));
            };

            const moveIndicatorBetween = function (fromLink, toLink, progress) {
                const fromMetrics = getIndicatorMetrics(fromLink);
                const toMetrics = getIndicatorMetrics(toLink);
                const safeProgress = clamp(progress, 0, 1);

                applyIndicatorMetrics({
                    x: fromMetrics.x + ((toMetrics.x - fromMetrics.x) * safeProgress),
                    width: fromMetrics.width + ((toMetrics.width - fromMetrics.width) * safeProgress)
                });
            };

            syncActiveIndicator();
            window.requestAnimationFrame(function () {
                nav.classList.add('is-indicator-ready');
            });
            window.addEventListener('resize', syncActiveIndicator);

            swipeItems.forEach(function (item) {
                item.link.addEventListener('click', function () {
                    if (navigationLocked || item.link.classList.contains('active')) {
                        return;
                    }

                    if (item.action) {
                        activeIndex = swipeItems.indexOf(item);
                    }

                    applyIndicatorMetrics(getIndicatorMetrics(item.link));
                });
            });

            const prefetchTarget = function (href) {
                if (!href || href === '#' || href.indexOf('http') === 0) {
                    return;
                }

                if (document.head.querySelector('link[rel="prefetch"][href="' + href + '"]')) {
                    return;
                }

                const link = document.createElement('link');
                link.rel = 'prefetch';
                link.href = href;
                document.head.appendChild(link);
            };

            const previousItem = swipeItems[activeIndex - 1];
            const nextItem = swipeItems[activeIndex + 1];
            if (previousItem) {
                prefetchTarget(previousItem.href);
            }
            if (nextItem) {
                prefetchTarget(nextItem.href);
            }

            const hasHorizontalInteraction = function (target) {
                return !!target.closest('.carousel, .multi-carousel, .home-spotlight-track, .home-spotlight-carousel, .home-video-grid, [data-mobile-swipe-ignore]');
            };

            const isHorizontalScroller = function (target) {
                let node = target;
                while (node && node !== content && node !== document.body) {
                    if (node instanceof HTMLElement) {
                        const styles = window.getComputedStyle(node);
                        const canScrollX = node.scrollWidth > node.clientWidth + 24;
                        if (canScrollX && (styles.overflowX === 'auto' || styles.overflowX === 'scroll')) {
                            return true;
                        }
                    }
                    node = node.parentElement;
                }
                return false;
            };

            let startX = 0;
            let startY = 0;
            let tracking = false;
            let capturedHorizontalGesture = false;
            let navigationLocked = false;

            const setSwipeLock = function (locked) {
                document.documentElement.classList.toggle('rr-mobile-swipe-active', locked);
                nav.classList.toggle('is-swipe-locked', locked);
            };

            const resetContentTransform = function () {
                content.style.transition = '';
                content.style.transform = '';
                content.style.opacity = '';
                setSwipeLock(false);
            };

            const animateTo = function (translateX, opacity, duration) {
                content.style.transition = 'transform ' + duration + 'ms cubic-bezier(0.22, 0.8, 0.22, 1), opacity ' + duration + 'ms ease-out';
                content.style.transform = 'translate3d(' + translateX + 'px, 0, 0)';
                content.style.opacity = opacity;
            };

            const navigateBySwipe = function (direction) {
                if (navigationLocked) {
                    return;
                }

                const targetIndex = direction === 'next' ? activeIndex + 1 : activeIndex - 1;
                const targetItem = swipeItems[targetIndex];
                if (!targetItem || (!targetItem.href && !targetItem.action)) {
                    syncActiveIndicator();
                    animateTo(0, 1, 120);
                    window.setTimeout(resetContentTransform, 140);
                    return;
                }

                navigationLocked = true;
                applyIndicatorMetrics(getIndicatorMetrics(targetItem.link));

                if (targetItem.action === 'search') {
                    activeIndex = targetIndex;
                    if (targetItem.link.getAttribute('aria-expanded') !== 'true') {
                        targetItem.link.click();
                    }
                    animateTo(0, 1, 120);
                    window.setTimeout(function () {
                        resetContentTransform();
                        navigationLocked = false;
                    }, 140);
                    return;
                }

                const targetUrl = new URL(targetItem.href, window.location.href);
                if (targetUrl.pathname === window.location.pathname && targetUrl.search === window.location.search) {
                    activeIndex = targetIndex;
                    animateTo(0, 1, 120);
                    window.setTimeout(function () {
                        resetContentTransform();
                        navigationLocked = false;
                    }, 140);
                    return;
                }

                const exitX = direction === 'next' ? -window.innerWidth : window.innerWidth;
                animateTo(exitX, 0.72, 160);

                window.setTimeout(function () {
                    window.location.assign(targetItem.href);
                }, 130);
            };

            content.addEventListener('touchstart', function (event) {
                if (!mobileQuery.matches || event.touches.length !== 1 || navigationLocked) {
                    tracking = false;
                    return;
                }

                const target = event.target;
                if (!(target instanceof Element) || hasHorizontalInteraction(target) || isHorizontalScroller(target)) {
                    tracking = false;
                    return;
                }

                tracking = true;
                capturedHorizontalGesture = false;
                setSwipeLock(false);
                syncActiveIndicator();
                startX = event.touches[0].clientX;
                startY = event.touches[0].clientY;
                content.style.transition = '';
            }, { passive: true });

            content.addEventListener('touchmove', function (event) {
                if (!tracking || navigationLocked || event.touches.length !== 1) {
                    return;
                }

                const touch = event.touches[0];
                const deltaX = touch.clientX - startX;
                const deltaY = touch.clientY - startY;
                const absX = Math.abs(deltaX);
                const absY = Math.abs(deltaY);

                if (!capturedHorizontalGesture) {
                    if (absY > 14 && absY >= absX) {
                        tracking = false;
                        resetContentTransform();
                        return;
                    }

                    if (absX < 6 || absX <= absY * 1.05) {
                        return;
                    }

                    capturedHorizontalGesture = true;
                    setSwipeLock(true);
                }

                event.preventDefault();

                const canGoPrevious = activeIndex > 0;
                const canGoNext = activeIndex < swipeItems.length - 1;
                const allowedDrag = (deltaX > 0 && canGoPrevious) || (deltaX < 0 && canGoNext);
                const resistance = allowedDrag ? 1 : 0.28;
                const translateX = deltaX * resistance;
                const previewIndex = deltaX > 0 ? activeIndex - 1 : activeIndex + 1;
                const previewItem = swipeItems[previewIndex];

                content.style.transform = 'translate3d(' + translateX + 'px, 0, 0)';
                content.style.opacity = String(Math.max(0.82, 1 - (Math.abs(translateX) / window.innerWidth) * 0.28));

                if (previewItem) {
                    moveIndicatorBetween(
                        swipeItems[activeIndex].link,
                        previewItem.link,
                        Math.abs(deltaX) / (window.innerWidth * 0.28)
                    );
                } else {
                    syncActiveIndicator();
                }
            }, { passive: false, capture: true });

            content.addEventListener('touchend', function (event) {
                if (!tracking || event.changedTouches.length !== 1) {
                    tracking = false;
                    capturedHorizontalGesture = false;
                    setSwipeLock(false);
                    syncActiveIndicator();
                    return;
                }

                const touch = event.changedTouches[0];
                const deltaX = touch.clientX - startX;
                const deltaY = touch.clientY - startY;
                const absX = Math.abs(deltaX);
                const absY = Math.abs(deltaY);

                tracking = false;

                if (!capturedHorizontalGesture || absX < 72 || absX <= absY * 1.35) {
                    capturedHorizontalGesture = false;
                    syncActiveIndicator();
                    animateTo(0, 1, 120);
                    window.setTimeout(resetContentTransform, 140);
                    return;
                }

                capturedHorizontalGesture = false;
                navigateBySwipe(deltaX < 0 ? 'next' : 'prev');
            }, { passive: true });

            content.addEventListener('touchcancel', function () {
                tracking = false;
                capturedHorizontalGesture = false;
                syncActiveIndicator();
                animateTo(0, 1, 120);
                window.setTimeout(resetContentTransform, 140);
            }, { passive: true });
        };

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initMobileContentSwipe, { once: true });
        } else {
            initMobileContentSwipe();
        }
    })();
</script>
