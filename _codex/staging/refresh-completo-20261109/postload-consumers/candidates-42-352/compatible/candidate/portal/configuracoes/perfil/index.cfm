<!doctype html>
<html lang="<cfoutput>#REQUEST.htmlLang#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.profileSettingsSection = structKeyExists(URL, "settings_section") ? lCase(trim(URL.settings_section & "")) : "perfil"/>
<cfset VARIABLES.profileSettingsSections = {
    "perfil" = {
        "routeKey" = "profileSettings",
        "labelKey" = "athlete.settings.navProfile"
    },
    "integracoes" = {
        "routeKey" = "profileSettingsIntegrations",
        "labelKey" = "athlete.settings.navIntegrations"
    },
    "links" = {
        "routeKey" = "profileSettingsLinks",
        "labelKey" = "athlete.settings.navLinks"
    },
    "privacidade" = {
        "routeKey" = "profileSettingsPrivacy",
        "labelKey" = "athlete.settings.navPrivacy"
    },
    "perfilrun" = {
        "routeKey" = "profileSettingsPerfilRun",
        "labelKey" = "athlete.settings.profileRunTitle"
    }
}/>
<cfif NOT structKeyExists(VARIABLES.profileSettingsSections, VARIABLES.profileSettingsSection)>
    <cfset VARIABLES.profileSettingsSection = "perfil"/>
</cfif>
<cfset VARIABLES.profileSettingsRouteKey = VARIABLES.profileSettingsSections[VARIABLES.profileSettingsSection].routeKey/>
<cfset VARIABLES.routeKey = VARIABLES.profileSettingsRouteKey/>
<cfset VARIABLES.template = "/configuracoes/#VARIABLES.profileSettingsSection#/"/>

<cfinclude template="../../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../../includes/backend/backend.cfm"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>

<cfset REQUEST.currentRouteKey = VARIABLES.routeKey/>
<cfset VARIABLES.profileSettingsPath = REQUEST.i18nBuildPath(VARIABLES.routeKey)/>

<cfif NOT Usuario.logado OR val(Usuario.id) LTE 0 OR val(Usuario.id_pagina) LTE 0>
    <cflocation addtoken="false" url="/login/?redirect=#urlEncodedFormat(VARIABLES.profileSettingsPath)#"/>
</cfif>

<cfheader name="Cache-Control" value="private, no-store, no-cache, must-revalidate, max-age=0"/>
<cfheader name="Pragma" value="no-cache"/>
<cfheader name="X-Robots-Tag" value="noindex, nofollow, noarchive"/>

<cfinclude template="../../includes/backend/backend_profile_settings.cfm"/>

<!--- Reutiliza os mesmos dados e componentes da sidebar do perfil do próprio atleta. --->
<cfset URL.tag = trim(Usuario.tag & "")/>
<cfset structDelete(URL, "action", false)/>
<cfset VARIABLES.profileSettingsHadManagementStatus = structKeyExists(REQUEST, "userManagementPageStatusSchemaReady")/>
<cfif VARIABLES.profileSettingsHadManagementStatus>
    <cfset VARIABLES.profileSettingsOriginalManagementStatus = REQUEST.userManagementPageStatusSchemaReady/>
</cfif>
<cfset REQUEST.userManagementPageStatusSchemaReady = false/>
<cfinclude template="../../includes/backend/backend_perfil_publico.cfm"/>
<cfif qPagina.recordcount>
    <cfset VARIABLES.profileSettingsStravaId = val(qPagina.strava_id)/>
    <cfset VARIABLES.profileSettingsStravaConnected = qPagina.strava_connected/>
    <cfset VARIABLES.profileSettingsStravaPublic = qPagina.strava_publico/>
</cfif>
<cfif VARIABLES.profileSettingsHadManagementStatus>
    <cfset REQUEST.userManagementPageStatusSchemaReady = VARIABLES.profileSettingsOriginalManagementStatus/>
<cfelse>
    <cfset structDelete(REQUEST, "userManagementPageStatusSchemaReady", false)/>
</cfif>

<cfset VARIABLES.profileSettingsRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams)
    ? duplicate(REQUEST.currentRouteParams)
    : {}/>
<cfset REQUEST.currentRouteParams = duplicate(VARIABLES.profileSettingsRouteParams)/>
<cfset REQUEST.currentRouteParams["tag"] = trim(Usuario.tag & "")/>
<cfset VARIABLES.profileSettingsProfilePath = REQUEST.i18nBuildPath("athlete")/>
<cfset REQUEST.currentRouteParams = VARIABLES.profileSettingsRouteParams/>

<cfset VARIABLES.canonical = REQUEST.currentBaseUrl & VARIABLES.profileSettingsPath/>
<cfset VARIABLES.title = REQUEST.t("athlete.settings.pageTitle") & " - " & APPLICATION.nomeSite/>
<cfset VARIABLES.description = REQUEST.t("athlete.settings.pageDescription")/>
<cfset VARIABLES.keywords = ""/>
<cfset VARIABLES.metaRobots = "noindex,nofollow,noarchive"/>
<cfset VARIABLES.activitySidebarCatalog = REQUEST.i18n.common.activitySidebar/>
<cfset VARIABLES.profileSettingsPerfilRunSlug = lCase(trim(qMeuPerfil.tag & ""))/>
<cfset VARIABLES.profileSettingsPerfilRunLabel = "Perfil.run/" & VARIABLES.profileSettingsPerfilRunSlug/>
<cfset VARIABLES.profileSettingsPerfilRunUrl = "https://perfil.run/" & encodeForURL(VARIABLES.profileSettingsPerfilRunSlug) & "/"/>
<cfset VARIABLES.profileSettingsPerfilRunVerified = qMeuPerfil.verificado/>

<cfinclude template="../../includes/estrutura/head.cfm"/>

<style>
    .profile-settings-heading {
        background: #efefef;
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 10px;
        padding: 1rem;
    }

    .profile-settings-heading h1 {
        color: #333333;
        font-size: 1.25rem;
        font-weight: 800;
        margin: 0;
    }

    .profile-settings-heading p {
        color: rgba(51, 51, 51, 0.68);
        font-size: 0.86rem;
        margin: 0.3rem 0 0;
    }

    .profile-settings-back {
        align-items: center;
        color: #333333;
        display: inline-flex;
        font-size: 0.8rem;
        font-weight: 700;
        gap: 0.35rem;
        margin-top: 0.75rem;
        text-decoration: none;
    }

    .profile-settings-back:hover {
        color: #333333;
        text-decoration: underline;
        text-decoration-color: #fab120;
        text-decoration-thickness: 2px;
    }

    .profile-settings-menu {
        display: flex;
        gap: 0.35rem;
        margin-bottom: 0.75rem;
        overflow-x: auto;
        padding: 0.15rem 0 0.4rem;
        scrollbar-width: thin;
        white-space: nowrap;
    }

    .profile-settings-menu-link {
        background: #f2f2f2;
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 999px;
        color: #555555;
        flex: 0 0 auto;
        font-size: 0.78rem;
        font-weight: 700;
        padding: 0.45rem 0.75rem;
        text-decoration: none;
    }

    .profile-settings-menu-link:hover {
        background: #e8e8e8;
        color: #333333;
    }

    .profile-settings-menu-link.active {
        background: #333333;
        border-color: #333333;
        color: #fab120;
    }

    .profile-settings-menu-link.profile-settings-menu-link-perfilrun {
        background: #fab120;
        border-color: #fab120;
        color: #222222;
        margin-left: auto;
    }

    .profile-settings-menu-link.profile-settings-menu-link-perfilrun:hover {
        background: #e39a00;
        border-color: #e39a00;
        color: #111111;
    }

    .profile-settings-menu-link.profile-settings-menu-link-perfilrun.active {
        background: #222222;
        border-color: #222222;
        color: #fab120;
    }

    .profile-settings-perfilrun-button {
        background: #fab120;
        border-color: #fab120;
        color: #222222;
        flex: 0 0 auto;
        white-space: nowrap;
    }

    .profile-settings-perfilrun-copy {
        min-width: 0;
    }

    .profile-settings-perfilrun-button:hover {
        background: #e39a00;
        border-color: #e39a00;
        color: #111111;
    }

    .profile-settings-control-row {
        align-items: center;
        display: flex;
        gap: 0.75rem;
        justify-content: space-between;
    }

    .profile-settings-control-copy {
        flex: 1 1 auto;
        min-width: 0;
    }

    .profile-settings-cover-preview {
        background: #e9ecef;
        border: 1px solid rgba(51, 51, 51, 0.12);
        border-radius: 8px;
        flex: 0 0 112px;
        height: 58px;
        overflow: hidden;
    }

    .profile-settings-cover-preview img {
        display: block;
        filter: grayscale(1);
        height: 100%;
        object-fit: cover;
        width: 100%;
    }

    .profile-settings-cover-button {
        align-items: center;
        background: #333333;
        border: 1px solid #333333;
        color: #fab120;
        display: inline-flex;
        font-size: 0.72rem;
        font-weight: 700;
        justify-content: center;
        padding: 0.3rem 0.55rem;
    }

    .profile-settings-cover-button:hover,
    .profile-settings-cover-button:focus-visible {
        background: #222222;
        border-color: #222222;
        color: #fab120;
    }

    .profile-settings-cover-button:disabled {
        background: #e9ecef;
        border-color: #dee2e6;
        color: #8a8a8a;
    }

    .profile-settings-cover-grid {
        display: grid;
        gap: 0.65rem;
        grid-template-columns: repeat(auto-fill, minmax(145px, 1fr));
    }

    .profile-settings-cover-option {
        background: #ffffff;
        border: 2px solid transparent;
        border-radius: 10px;
        color: #555555;
        overflow: hidden;
        padding: 0;
        text-align: left;
    }

    .profile-settings-cover-option:hover,
    .profile-settings-cover-option:focus-visible {
        border-color: rgba(250, 177, 32, 0.65);
        outline: none;
    }

    .profile-settings-cover-option.is-selected {
        border-color: #fab120;
        box-shadow: 0 0 0 2px rgba(250, 177, 32, 0.2);
    }

    .profile-settings-cover-option img {
        aspect-ratio: 16 / 9;
        display: block;
        filter: grayscale(1);
        object-fit: cover;
        width: 100%;
    }

    .profile-settings-cover-option span {
        display: block;
        font-size: 0.7rem;
        overflow: hidden;
        padding: 0.35rem 0.45rem;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .profile-settings-theme-options {
        display: flex;
        flex: 0 0 auto;
        gap: 0.3rem;
    }

    .profile-settings-theme-option {
        cursor: pointer;
        margin: 0;
    }

    .profile-settings-theme-option input {
        opacity: 0;
        pointer-events: none;
        position: absolute;
    }

    .profile-settings-theme-option span {
        align-items: center;
        background: #f5f5f5;
        border: 1px solid rgba(51, 51, 51, 0.12);
        border-radius: 10px;
        color: #555555;
        display: flex;
        font-size: 0.72rem;
        font-weight: 700;
        gap: 0.3rem;
        justify-content: center;
        min-width: 70px;
        padding: 0.4rem 0.5rem;
    }

    .profile-settings-theme-option input:checked + span {
        background: #333333;
        border-color: #333333;
        color: #fab120;
    }

    .profile-settings-theme-option input:focus-visible + span {
        box-shadow: 0 0 0 0.2rem rgba(250, 177, 32, 0.3);
    }

    .profile-settings-links-manager {
        min-width: 0;
    }

    .profile-settings-links-list {
        display: grid;
        gap: 0.4rem;
    }

    .profile-settings-link-row {
        align-items: center;
        background: #f7f7f7;
        border: 1px solid rgba(51, 51, 51, 0.08);
        border-radius: 9px;
        display: grid;
        gap: 0.6rem;
        grid-template-columns: 34px minmax(0, 1fr) auto auto;
        padding: 0.45rem;
    }

    .profile-settings-link-row.is-inactive .profile-settings-link-row-icon,
    .profile-settings-link-row.is-inactive .profile-settings-link-row-copy,
    .profile-settings-link-row.is-inactive .profile-settings-link-clicks {
        opacity: 0.45;
    }

    .profile-settings-link-icon-preview,
    .profile-settings-link-row-icon {
        align-items: center;
        background: #333333;
        border-radius: 8px;
        color: #fab120;
        display: inline-flex;
        flex: 0 0 auto;
        height: 34px;
        justify-content: center;
        width: 34px;
    }

    .profile-settings-link-row-copy {
        min-width: 0;
    }

    .profile-settings-link-row-title,
    .profile-settings-link-row-url {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .profile-settings-link-row-title {
        color: #333333;
        font-size: 0.82rem;
        font-weight: 700;
    }

    .profile-settings-link-row-url {
        color: #777777;
        font-size: 0.7rem;
    }

    .profile-settings-link-clicks {
        color: #666666;
        font-size: 0.7rem;
        white-space: nowrap;
    }

    .profile-settings-link-actions {
        display: flex;
        gap: 0.2rem;
    }

    .profile-settings-link-action {
        align-items: center;
        border: 0;
        border-radius: 7px;
        color: #555555;
        display: inline-flex;
        height: 30px;
        justify-content: center;
        padding: 0;
        width: 30px;
    }

    .profile-settings-link-action:hover,
    .profile-settings-link-action:focus-visible {
        background: #e9e9e9;
        color: #222222;
    }

    .profile-settings-link-action-delete:hover,
    .profile-settings-link-action-delete:focus-visible {
        color: #b42318;
    }

    .profile-settings-link-action-visibility[aria-checked="true"] {
        color: #7a5700;
    }

    .profile-settings-link-editor {
        background: #ffffff;
        border: 1px dashed rgba(51, 51, 51, 0.22);
        border-radius: 9px;
        display: grid;
        gap: 0.55rem;
        grid-template-columns: minmax(0, 1fr);
        max-width: 100%;
        padding: 0.55rem;
        width: 100%;
    }

    .profile-settings-link-editor.is-inline-edit {
        background: #fffaf0;
        grid-column: 1 / -1;
        margin: 0.1rem 0 0.25rem;
    }

    .profile-settings-link-field {
        min-width: 0;
        width: 100%;
    }

    .profile-settings-link-field .form-control {
        box-sizing: border-box;
        max-width: 100%;
        width: 100%;
    }

    .profile-settings-link-editor-footer {
        align-items: flex-end;
        display: flex;
        gap: 0.55rem;
        justify-content: space-between;
        min-width: 0;
        width: 100%;
    }

    .profile-settings-link-field-icon {
        flex: 1 1 auto;
    }

    .profile-settings-link-icon-trigger {
        align-items: center;
        background: #f7f7f7;
        border: 1px solid #ced4da;
        border-radius: 7px;
        color: #333333;
        display: inline-flex;
        font-size: 0.76rem;
        font-weight: 700;
        gap: 0.45rem;
        max-width: 100%;
        min-height: 38px;
        padding: 0.15rem 0.45rem 0.15rem 0.15rem;
    }

    .profile-settings-link-icon-trigger:hover,
    .profile-settings-link-icon-trigger:focus-visible {
        background: #ffffff;
        border-color: #fab120;
        outline: none;
    }

    .profile-settings-link-icon-trigger:disabled {
        opacity: 0.55;
    }

    .profile-settings-link-icon-chevron {
        color: #777777;
        font-size: 0.62rem;
    }

    .profile-settings-link-add {
        align-items: center;
        display: inline-flex;
        flex: 0 0 auto;
        height: 38px;
        justify-content: center;
        padding: 0 0.75rem;
        white-space: nowrap;
        width: auto;
    }

    .profile-settings-link-icon-grid {
        display: grid;
        gap: 0.45rem;
        grid-template-columns: repeat(5, minmax(0, 1fr));
    }

    .profile-settings-link-icon-option {
        align-items: center;
        background: #f7f7f7;
        border: 1px solid rgba(51, 51, 51, 0.1);
        border-radius: 9px;
        color: #444444;
        display: flex;
        flex-direction: column;
        gap: 0.35rem;
        justify-content: center;
        min-height: 72px;
        min-width: 0;
        padding: 0.45rem 0.25rem;
    }

    .profile-settings-link-icon-option i {
        color: #333333;
        font-size: 1.2rem;
    }

    .profile-settings-link-icon-option span {
        font-size: 0.64rem;
        line-height: 1.1;
        max-width: 100%;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    .profile-settings-link-icon-option:hover,
    .profile-settings-link-icon-option:focus-visible,
    .profile-settings-link-icon-option.is-selected {
        background: #fff8e8;
        border-color: #fab120;
        color: #222222;
        outline: none;
    }

    .profile-settings-link-icon-option.is-selected i {
        color: #c98000;
    }

    .profile-settings-links-responsibility {
        align-items: flex-start;
        color: #777777;
        display: flex;
        font-size: 0.68rem;
        gap: 0.35rem;
        line-height: 1.35;
    }

    .profile-settings-links-responsibility i {
        margin-top: 0.1rem;
    }

    .profile-settings-perfilrun-switch {
        align-items: center;
        display: flex;
        gap: 1rem;
        justify-content: space-between;
    }

    .profile-settings-perfilrun-switch .form-check-input {
        cursor: pointer;
    }

    .profile-settings-perfilrun-switch .form-check-input:checked {
        background-color: #fab120;
        border-color: #fab120;
    }

    @media (max-width: 767.98px) {
        .profile-settings-link-icon-grid {
            grid-template-columns: repeat(4, minmax(0, 1fr));
        }
    }

    @media (max-width: 420px) {
        .profile-settings-link-row {
            grid-template-columns: 34px minmax(0, 1fr) auto;
        }

        .profile-settings-link-clicks {
            grid-column: 2;
        }

        .profile-settings-link-actions {
            grid-column: 3;
            grid-row: 1 / span 2;
        }

        .profile-settings-link-editor-footer {
            align-items: flex-end;
            flex-wrap: wrap;
        }

        .profile-settings-link-icon-grid {
            grid-template-columns: repeat(3, minmax(0, 1fr));
        }

        .profile-settings-link-icon-option {
            min-height: 68px;
        }
    }

    #profile-settings-content .card {
        box-shadow: none !important;
    }
</style>

<body>

    <cfinclude template="../../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <div class="container">
        <cfinclude template="../../includes/estrutura/header.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>
            <div class="row g-2">
                <aside class="col-12 col-md-4 col-lg-3 col-xl-3 d-none d-md-block">
                    <cfinclude template="../../includes/estrutura/home_sidebar_async_slot.cfm"/>
                </aside>

                <section id="profile-settings-content" class="col-12 col-md-8 col-lg-6 col-xl-6 px-lg-3">
                    <div class="profile-settings-heading mb-2">
                        <h1><cfoutput>#REQUEST.t("athlete.settings.pageTitle")#</cfoutput></h1>
                        <p><cfoutput>#REQUEST.t("athlete.settings.pageDescription")#</cfoutput></p>
                        <a class="profile-settings-back" href="<cfoutput>#VARIABLES.profileSettingsProfilePath#</cfoutput>">
                            <i class="fa-solid fa-arrow-left"></i>
                            <cfoutput>#REQUEST.t("athlete.settings.backToProfile")#</cfoutput>
                        </a>
                    </div>

                    <nav class="profile-settings-menu" aria-label="<cfoutput>#encodeForHTMLAttribute(REQUEST.t('athlete.settings.pageTitle'))#</cfoutput>">
                        <cfloop list="perfil,integracoes,links,privacidade" index="profileSettingsMenuSection">
                            <cfset VARIABLES.profileSettingsMenuItem = VARIABLES.profileSettingsSections[profileSettingsMenuSection]/>
                            <cfset VARIABLES.profileSettingsMenuPath = REQUEST.i18nBuildPath(VARIABLES.profileSettingsMenuItem.routeKey)/>
                            <a
                                class="profile-settings-menu-link<cfif profileSettingsMenuSection EQ VARIABLES.profileSettingsSection> active</cfif>"
                                href="<cfoutput>#VARIABLES.profileSettingsMenuPath#</cfoutput>"
                                <cfif profileSettingsMenuSection EQ VARIABLES.profileSettingsSection>aria-current="page"</cfif>>
                                <cfoutput>#REQUEST.t(VARIABLES.profileSettingsMenuItem.labelKey)#</cfoutput>
                            </a>
                        </cfloop>
                        <cfif listFindNoCase("dev.roadrunners.run,roadrunners.run,www.roadrunners.run", listFirst(CGI.http_host, ":"))>
                            <a class="profile-settings-menu-link" href="/verificado/">Selo Verificado</a>
                        </cfif>
                        <cfset VARIABLES.profileSettingsPerfilRunPath = REQUEST.i18nBuildPath("profileSettingsPerfilRun")/>
                        <a
                            class="profile-settings-menu-link profile-settings-menu-link-perfilrun<cfif VARIABLES.profileSettingsSection EQ 'perfilrun'> active</cfif>"
                            href="<cfoutput>#VARIABLES.profileSettingsPerfilRunPath#</cfoutput>"
                            <cfif VARIABLES.profileSettingsSection EQ "perfilrun">aria-current="page"</cfif>>
                            <cfoutput>#REQUEST.t("athlete.settings.profileRunTitle")#</cfoutput>
                        </a>
                    </nav>

                    <cfif VARIABLES.profileSettingsStatus EQ "saved">
                        <div class="alert alert-success small" role="status">
                            <i class="fa-solid fa-circle-check me-2"></i><cfoutput>#REQUEST.t("athlete.settings.saved")#</cfoutput>
                        </div>
                    <cfelseif VARIABLES.profileSettingsStatus EQ "security-error">
                        <div class="alert alert-danger small" role="alert">
                            <i class="fa-solid fa-shield-halved me-2"></i><cfoutput>#REQUEST.t("athlete.settings.securityError")#</cfoutput>
                        </div>
                    <cfelseif VARIABLES.profileSettingsStatus EQ "invalid">
                        <div class="alert alert-danger small" role="alert">
                            <i class="fa-solid fa-circle-exclamation me-2"></i><cfoutput>#REQUEST.t("athlete.settings.invalidRequest")#</cfoutput>
                        </div>
                    </cfif>

                    <cfinclude template="../../atleta/parts/configuracoes.cfm"/>
                </section>

                <aside class="col-12 col-lg-3 d-none d-lg-block">
                    <cfinclude template="../../atleta/parts/sidebar_desktop.cfm"/>
                </aside>
            </div>
        </main>
    </div>

    <cfinclude template="../../includes/estrutura/footer.cfm"/>
    <cfset REQUEST.currentRouteParams = duplicate(VARIABLES.profileSettingsRouteParams)/>
    <cfset REQUEST.currentRouteParams["tag"] = trim(Usuario.tag & "")/>
    <cfinclude template="../../includes/modal/modal_badges.cfm"/>
    <cfinclude template="../../includes/modal/modal_seguidores.cfm"/>
    <cfset REQUEST.currentRouteParams = VARIABLES.profileSettingsRouteParams/>
    <cfinclude template="../../includes/modal/modal_cadastro_evento.cfm"/>
    <cfinclude template="../../includes/modal/modal_login.cfm"/>
    <cfinclude template="../../includes/estrutura/seo-web-tools-body-end.cfm"/>

    <script>
        (function revealActiveProfileSettingsMenuItem() {
            var menu = document.querySelector('.profile-settings-menu');
            var activeItem = menu ? menu.querySelector('.profile-settings-menu-link.active') : null;

            if (!menu || !activeItem || menu.scrollWidth <= menu.clientWidth) {
                return;
            }

            menu.scrollLeft = Math.max(
                0,
                activeItem.offsetLeft - ((menu.clientWidth - activeItem.offsetWidth) / 2)
            );
        }());

        (function initializeProfileSettingsInputs() {
            var retryCount = 0;
            var maxRetries = 20;

            function ensureOutlineMarkup(formOutline) {
                var label = formOutline.querySelector('label.form-label');
                var input = formOutline.querySelector('input.form-control, textarea.form-control');
                var notch = formOutline.querySelector('.form-notch');
                var leading;
                var middle;
                var trailing;
                var prefix;
                var labelWidth;
                var leadingWidth;

                if (!input) {
                    return;
                }

                if (!notch) {
                    notch = document.createElement('div');
                    notch.className = 'form-notch';
                    notch.innerHTML = '<div class="form-notch-leading"></div>'
                        + '<div class="form-notch-middle"></div>'
                        + '<div class="form-notch-trailing"></div>';
                    formOutline.appendChild(notch);
                }

                if (!label) {
                    return;
                }

                leading = notch.querySelector('.form-notch-leading');
                middle = notch.querySelector('.form-notch-middle');
                trailing = notch.querySelector('.form-notch-trailing');

                if (!leading || !middle || !trailing) {
                    return;
                }

                prefix = input.previousElementSibling;
                leadingWidth = prefix && prefix.classList.contains('input-group-text')
                    ? prefix.offsetWidth + 8
                    : 9;
                labelWidth = label.clientWidth * 0.8 + 8;

                leading.style.width = leadingWidth + 'px';
                middle.style.width = labelWidth + 'px';
                label.style.marginLeft = (leadingWidth - 9) + 'px';
            }

            function updateInputState(formOutline) {
                var input = formOutline.querySelector('input.form-control, textarea.form-control');

                if (!input) {
                    return;
                }

                input.classList.toggle('active', input.value !== '');

                if (input.dataset.rrProfileInputBound === 'true') {
                    return;
                }

                input.dataset.rrProfileInputBound = 'true';
                input.addEventListener('input', function () {
                    input.classList.toggle('active', input.value !== '');
                });
                input.addEventListener('change', function () {
                    input.classList.toggle('active', input.value !== '');
                });
                input.addEventListener('blur', function () {
                    input.classList.toggle('active', input.value !== '');
                });
            }

            function updateProfileSettingsInputs() {
                var mdbInputAvailable = Boolean(window.mdb && window.mdb.Input);

                document
                    .querySelectorAll('#profile-settings-content .form-outline[data-mdb-input-init]')
                    .forEach(function (formOutline) {
                        updateInputState(formOutline);

                        if (!mdbInputAvailable) {
                            ensureOutlineMarkup(formOutline);
                            return;
                        }

                        try {
                            window.mdb.Input.getOrCreateInstance(formOutline).update();
                        } catch (error) {
                            // A classe active acima preserva a legibilidade se um campo falhar.
                        }
                    });

                if (!mdbInputAvailable && retryCount < maxRetries) {
                    retryCount += 1;
                    window.setTimeout(updateProfileSettingsInputs, 100);
                }
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', updateProfileSettingsInputs, { once: true });
            } else {
                updateProfileSettingsInputs();
            }

            window.addEventListener('load', updateProfileSettingsInputs, { once: true });
            window.addEventListener('pageshow', updateProfileSettingsInputs);
            window.setTimeout(updateProfileSettingsInputs, 250);
            window.setTimeout(updateProfileSettingsInputs, 1000);
        }());
    </script>

</body>
</html>
