<div class="col-12 mb-1">

    <!--- PREPARA SOBRESCRITAS OPCIONAIS DO LINK DO CARD --->
    <cfparam name="VARIABLES.eventCardHrefOverride" default="" />
    <cfparam name="VARIABLES.eventCardAnchorAttrs" default="" />
    <cfparam name="VARIABLES.eventCardHideBadges" default="false" />

    <!--- GARANTE O USUARIO DA REQUISICAO PARA ACOES CONDICIONAIS --->
    <cfif structKeyExists(REQUEST, "Usuario")>
        <cfset Usuario = REQUEST.Usuario/>
    <cfelse>
        <cfset Usuario = createObject("component", "includes.models.Usuario").init()/>
        <cfset REQUEST.Usuario = Usuario/>
    </cfif>

    <cfset VARIABLES.eventCardEventTag = isDefined("tag") ? trim(tag) : "" />
    <cfset VARIABLES.eventCardAgendaRedirectPath = "/agenda/" />

    <!--- MONTA O REDIRECIONAMENTO DE AGENDA RESPEITANDO ROTAS LOCALIZADAS --->
    <cfif isDefined("qPagina.tag") AND len(trim(qPagina.tag)) AND structKeyExists(REQUEST, "i18nBuildPath")>
        <cfset VARIABLES.eventCardCurrentRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
        <cfset VARIABLES.eventCardRouteParams = duplicate(VARIABLES.eventCardCurrentRouteParams) />
        <cfset VARIABLES.eventCardRouteParams["tag"] = trim(qPagina.tag) />
        <cfset REQUEST.currentRouteParams = VARIABLES.eventCardRouteParams />
        <cfset VARIABLES.eventCardAgendaRedirectPath = REQUEST.i18nBuildPath("athlete") & "?filtro=agenda" />
        <cfset REQUEST.currentRouteParams = VARIABLES.eventCardCurrentRouteParams />
    <cfelseif isDefined("qPagina.tag_prefix") AND isDefined("qPagina.tag")>
        <cfset VARIABLES.eventCardAgendaRedirectPath = "/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda" />
    </cfif>

    <!--- MONTA O LINK DO EVENTO; SEM TAG O CARD CAI NA ROTA BASE /evento/ --->
    <cfif len(VARIABLES.eventCardEventTag) AND structKeyExists(REQUEST, "i18nBuildPath")>
        <cfset VARIABLES.eventCardCurrentRouteParams = structKeyExists(REQUEST, "currentRouteParams") AND isStruct(REQUEST.currentRouteParams) ? duplicate(REQUEST.currentRouteParams) : structNew() />
        <cfset VARIABLES.eventCardRouteParams = duplicate(VARIABLES.eventCardCurrentRouteParams) />
        <cfset VARIABLES.eventCardRouteParams["tag"] = VARIABLES.eventCardEventTag />
        <cfset REQUEST.currentRouteParams = VARIABLES.eventCardRouteParams />
        <cfset VARIABLES.eventCardDetailPath = REQUEST.i18nBuildPath("event") />
        <cfset REQUEST.currentRouteParams = VARIABLES.eventCardCurrentRouteParams />
    <cfelseif len(VARIABLES.eventCardEventTag)>
        <cfset VARIABLES.eventCardDetailPath = "/evento/#VARIABLES.eventCardEventTag#/" />
    <cfelse>
        <cfset VARIABLES.eventCardDetailPath = "/evento/" />
    </cfif>

    <cfset VARIABLES.eventCardSearchPath = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("search") : "/busca/" />
    <cfset VARIABLES.eventCardEstadoUf = isDefined("estado") ? uCase(trim(estado & "")) : "" />
    <cfset VARIABLES.eventCardEstadoPath = "" />
    <cfset VARIABLES.eventCardCidadePath = "" />
    <cfif listFindNoCase("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO", VARIABLES.eventCardEstadoUf)>
        <cfset VARIABLES.eventCardEstadoPath = "/estado/#lCase(VARIABLES.eventCardEstadoUf)#/" />
        <cfif isDefined("tag_cidade") AND len(trim(tag_cidade & ""))>
            <cfset VARIABLES.eventCardCidadePath = "#VARIABLES.eventCardEstadoPath##lCase(trim(tag_cidade & ""))#/" />
        </cfif>
    </cfif>
    <cfset VARIABLES.eventCardDetailAbsoluteUrl = REQUEST.currentBaseUrl & VARIABLES.eventCardDetailPath />
    <cfset VARIABLES.eventCardDisplayDate = (isDefined("data_resultado") AND isDate(data_resultado)) ? data_resultado : (isDefined("data_final") ? data_final : now())/>

    <!--- CARREGA O CSS DO CARD COMPACTO UMA UNICA VEZ POR REQUISICAO --->
    <cfif (VARIABLES.template EQ "/" OR VARIABLES.template EQ "/busca/" OR VARIABLES.template EQ "/estado/" OR VARIABLES.template EQ "/maratona/" OR VARIABLES.template EQ "/org/" OR VARIABLES.template EQ "/timer/") AND NOT isDefined("REQUEST.homeEventCardCssLoaded")>
        <cfset REQUEST.homeEventCardCssLoaded = true/>
        <style>
            .home-event-card {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                background-color: #ffffff;
                overflow: hidden;
            }

            .home-event-card-link {
                display: block;
                color: #333333;
                text-decoration: none;
            }

            .home-event-card-body {
                padding: 0.95rem;
            }

            .home-event-card-top {
                display: grid;
                grid-template-columns: 62px minmax(0, 1fr);
                gap: 0.85rem;
                align-items: start;
            }

            .home-event-card-date {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                background-color: #efefef;
                overflow: hidden;
                text-align: center;
                color: #333333;
            }

            .home-event-card-date .day {
                display: block;
                font-size: 1.35rem;
                font-weight: 700;
                line-height: 1;
                padding: 0.5rem 0.2rem 0.1rem;
            }

            .home-event-card-date .month {
                display: block;
                background-color: #fab120;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                letter-spacing: 0.08em;
                padding: 0.1rem;
                text-transform: uppercase;
            }

            .home-event-card-date .year {
                display: block;
                background-color: transparent;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                padding: 0.1rem;
            }

            .home-event-card-title {
                color: #333333;
                font-size: 1rem;
                font-weight: 700;
                line-height: 1.25;
                margin-bottom: 0.4rem;
            }

            .home-event-card-meta {
                color: rgba(51, 51, 51, 0.72);
                font-size: 0.82rem;
                line-height: 1.35;
            }

            .home-event-card-meta i {
                color: #fab120;
            }

            .home-event-card-flags {
                display: flex;
                flex-wrap: wrap;
                gap: 0.4rem;
                margin-top: 0.65rem;
            }

            .home-event-flag {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                padding: 0.38rem 0.65rem;
                border-radius: 8px;
                border: 1px solid rgba(51, 51, 51, 0.1);
                background-color: #efefef;
                color: #333333;
                font-size: 0.74rem;
                font-weight: 700;
                line-height: 1;
            }

            .home-event-flag.is-coupon {
                background-color: #fab120;
                border-color: #fab120;
                color: #333333;
                font-weight: 800;
                box-shadow: inset 0 0 0 1px rgba(51, 51, 51, 0.03);
            }

            .home-event-card-distances {
                display: flex;
                flex-wrap: wrap;
                gap: 0.45rem;
                margin-top: 0.8rem;
            }

            .home-event-distance {
                display: inline-flex;
                align-items: center;
                gap: 0.35rem;
                padding: 0.42rem 0.68rem;
                border-radius: 8px;
                border: 1px solid rgba(51, 51, 51, 0.08);
                background-color: #ffffff;
                color: #333333;
                font-size: 0.8rem;
                font-weight: 600;
                line-height: 1;
            }

            .home-event-distance i {
                color: #fab120;
            }

            .home-event-card-badges {
                display: flex;
                flex-wrap: wrap;
                gap: 0.35rem;
                margin-top: 0.8rem;
                padding-top: 0.8rem;
                border-top: 1px solid rgba(51, 51, 51, 0.08);
            }

            .home-event-card-badges img {
                width: 24px;
                height: 24px;
                border-radius: 6px;
            }
        </style>
    </cfif>

    <!--- CARREGA O CSS DO CARD DA PAGINA DE DETALHE UMA UNICA VEZ --->
    <cfif VARIABLES.template EQ "/evento/" AND NOT isDefined("REQUEST.eventDetailCardCssLoaded")>
        <cfset REQUEST.eventDetailCardCssLoaded = true/>
        <style>
            :root {
                --or-border: rgba(51, 51, 51, 0.08);
                --or-muted: rgba(51, 51, 51, 0.72);
            }

            .event-detail-card {
                border: 1px solid var(--or-border);
                border-radius: 10px;
                background-color: #ffffff;
                overflow: hidden;
            }

            .event-detail-card-body {
                padding: 0.95rem;
            }

            .event-detail-card-top {
                display: grid;
                grid-template-columns: 62px minmax(0, 1fr);
                gap: 0.85rem;
                align-items: start;
            }

            .event-detail-card-date {
                border: 1px solid var(--or-border);
                border-radius: 10px;
                background-color: #efefef;
                overflow: hidden;
                text-align: center;
                color: #333333;
            }

            .event-detail-card-date .day {
                display: block;
                font-size: 1.35rem;
                font-weight: 700;
                line-height: 1;
                padding: 0.5rem 0.2rem 0.2rem;
            }

            .event-detail-card-date .month {
                display: block;
                background-color: #fab120;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                letter-spacing: 0.08em;
                padding: 0.1rem;
                text-transform: uppercase;
            }

            .event-detail-card-date .year {
                display: block;
                background-color: transparent;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                padding: 0.1rem;
            }

            .event-detail-card-title {
                color: #333333;
                font-size: 1rem;
                font-weight: 700;
                line-height: 1.25;
                margin-bottom: 0.4rem;
            }

            .event-detail-card-meta {
                color: var(--or-muted);
                font-size: 0.82rem;
                line-height: 1.35;
            }

            .event-detail-card-meta a {
                color: #333333;
                text-decoration: none;
            }

            .event-detail-card-meta i {
                color: #fab120;
            }

            .event-detail-card-flags {
                display: flex;
                flex-wrap: wrap;
                gap: 0.4rem;
                margin-top: 0.65rem;
            }

            .event-detail-flag {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                padding: 0.38rem 0.65rem;
                border-radius: 8px;
                border: 1px solid rgba(51, 51, 51, 0.1);
                background-color: #efefef;
                color: #333333;
                font-size: 0.74rem;
                font-weight: 700;
                line-height: 1;
            }

            .event-detail-flag.is-coupon {
                background-color: #fab120;
                border-color: #fab120;
                color: #333333;
                font-weight: 800;
                box-shadow: inset 0 0 0 1px rgba(51, 51, 51, 0.03);
            }

            .event-detail-card-distances {
                display: flex;
                flex-wrap: wrap;
                gap: 0.32rem;
                margin-top: 0.65rem;
            }

            .event-detail-distance {
                display: inline-flex;
                align-items: center;
                gap: 0.28rem;
                padding: 0.34rem 0.54rem;
                border-radius: 8px;
                border: 1px solid var(--or-border);
                background-color: #ffffff;
                color: #333333;
                font-size: 0.74rem;
                font-weight: 600;
                line-height: 1;
            }

            .event-detail-distance i {
                color: #fab120;
            }

            .event-detail-card-badges {
                display: flex;
                flex-wrap: wrap;
                gap: 0.35rem;
                margin-top: 0.8rem;
                padding-top: 0.8rem;
                border-top: 1px solid var(--or-border);
            }

            .event-detail-card-badges img {
                width: 24px;
                height: 24px;
                border-radius: 6px;
            }
        </style>
    </cfif>

    <!--- CARREGA O CSS DO CARD DE AGENDA DO ATLETA UMA UNICA VEZ --->
    <cfif (VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/agenda/") AND isDefined("VARIABLES.tipoListagem") AND VARIABLES.tipoListagem EQ "calendario" AND NOT isDefined("REQUEST.athleteAgendaEventCardCssLoaded")>
        <cfset REQUEST.athleteAgendaEventCardCssLoaded = true/>
        <style>
            .athlete-agenda-card {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px 10px 0 0;
                background-color: #ffffff;
                overflow: hidden;
                box-shadow: none;
            }

            .athlete-agenda-card-link {
                display: block;
                color: #333333;
                text-decoration: none;
            }

            .athlete-agenda-card-shell {
                position: relative;
            }

            .athlete-agenda-card-shell.has-checkin .athlete-agenda-card-body {
                padding-right: 5.4rem;
            }

            .athlete-agenda-card-body {
                padding: 0.95rem;
            }

            .athlete-agenda-card-top {
                display: grid;
                grid-template-columns: 62px minmax(0, 1fr);
                gap: 0.85rem;
                align-items: start;
            }

            .athlete-agenda-card-date {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                background-color: #efefef;
                overflow: hidden;
                text-align: center;
                color: #333333;
            }

            .athlete-agenda-card-date .day {
                display: block;
                font-size: 1.35rem;
                font-weight: 700;
                line-height: 1;
                padding: 0.75rem 0.2rem 0.2rem;
            }

            .athlete-agenda-card-date .month {
                display: block;
                background-color: #fab120;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                letter-spacing: 0.08em;
                padding: 0.1rem;
                text-transform: uppercase;
            }

            .athlete-agenda-card-date .year {
                display: block;
                background-color: transparent;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                padding: 0.1rem;
            }

            .athlete-agenda-card-title {
                color: #333333;
                font-size: 1rem;
                font-weight: 700;
                line-height: 1.25;
                margin-bottom: 0.4rem;
            }

            .athlete-agenda-card-meta {
                color: rgba(51, 51, 51, 0.72);
                font-size: 0.82rem;
                line-height: 1.35;
            }

            .athlete-agenda-card-meta i {
                color: #fab120;
            }

            .athlete-agenda-card-flags {
                display: flex;
                flex-wrap: wrap;
                gap: 0.4rem;
                margin-top: 0.65rem;
            }

            .athlete-agenda-flag {
                display: inline-flex;
                align-items: center;
                justify-content: center;
                padding: 0.38rem 0.65rem;
                border-radius: 8px;
                border: 1px solid rgba(51, 51, 51, 0.1);
                background-color: #efefef;
                color: #333333;
                font-size: 0.74rem;
                font-weight: 700;
                line-height: 1;
            }

            .athlete-agenda-flag.is-coupon,
            .athlete-agenda-flag.is-status {
                background-color: #fab120;
                border-color: #fab120;
                color: #333333;
            }

            .athlete-agenda-card-distances {
                display: flex;
                flex-wrap: wrap;
                gap: 0.45rem;
                margin-top: 0.8rem;
            }

            .athlete-agenda-distance {
                display: inline-flex;
                align-items: center;
                gap: 0.35rem;
                padding: 0.42rem 0.68rem;
                border-radius: 8px;
                border: 1px solid rgba(51, 51, 51, 0.08);
                background-color: #ffffff;
                color: #333333;
                font-size: 0.8rem;
                font-weight: 600;
                line-height: 1;
            }

            .athlete-agenda-distance i {
                color: #fab120;
            }

            .athlete-agenda-card-badges {
                display: flex;
                flex-wrap: wrap;
                gap: 0.35rem;
                margin-top: 0.8rem;
                padding-top: 0.8rem;
                border-top: 1px solid rgba(51, 51, 51, 0.08);
            }

            .athlete-agenda-card-badges img {
                width: 24px;
                height: 24px;
                border-radius: 6px;
            }

            .athlete-agenda-checkin-action {
                position: absolute;
                top: 0;
                right: 0;
                bottom: 0;
                width: 4.55rem;
                border: 1px dashed rgba(250, 177, 32, 0.9);
                border-top: 0;
                border-right: 0;
                border-bottom: 0;
                border-radius: 0 10px 0 0;
                background:
                    linear-gradient(135deg, rgba(250, 177, 32, 0.12) 0%, rgba(250, 177, 32, 0.04) 100%),
                    #fffdf7;
                color: #333333;
                display: grid;
                place-items: center;
                padding: 0;
                text-align: center;
                box-shadow: none;
                overflow: hidden;
                transition: background-color 0.18s ease, color 0.18s ease;
            }

            .athlete-agenda-checkin-action::before {
                content: "";
                position: absolute;
                inset: 0;
                background-image: linear-gradient(
                    135deg,
                    rgba(250, 177, 32, 0.06) 0,
                    rgba(250, 177, 32, 0.06) 12px,
                    transparent 12px,
                    transparent 24px
                );
                pointer-events: none;
            }

            .athlete-agenda-checkin-action > * {
                position: relative;
                z-index: 1;
            }

            .athlete-agenda-checkin-content {
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                gap: 0.35rem;
            }

            .athlete-agenda-checkin-action i {
                color: #333333;
                font-size: 2.55rem;
                line-height: 1;
            }

            .athlete-agenda-checkin-label {
                display: block;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 800;
                line-height: 1.05;
                text-align: center;
            }

            .athlete-agenda-checkin-action:hover,
            .athlete-agenda-checkin-action:focus,
            .athlete-agenda-checkin-action:active {
                background-color: #fab120;
                color: #333333;
                box-shadow: none !important;
            }

            .athlete-agenda-checkin-action:hover i,
            .athlete-agenda-checkin-action:focus i,
            .athlete-agenda-checkin-action:active i {
                color: #333333;
            }

            .btn-group.w-100.rounded-bottom-3 .btn {
                flex: 1 1 0;
                box-shadow: none;
                border-top: 1px solid rgba(51, 51, 51, 0.08);
                background-color: #efefef !important;
                color: #333333;
                font-size: 0.76rem;
                font-weight: 800;
                letter-spacing: 0.02em;
                padding: 0.62rem 0.5rem;
            }

            .btn-group.w-100.rounded-bottom-3 {
                box-shadow: none !important;
            }

            .btn-group.w-100.rounded-bottom-3 .btn i {
                color: #fab120;
            }

            .btn-group.w-100.rounded-bottom-3 .btn:hover,
            .btn-group.w-100.rounded-bottom-3 .btn:focus,
            .btn-group.w-100.rounded-bottom-3 .btn:active {
                box-shadow: none !important;
                background-color: #fab120 !important;
                color: #333333;
            }

            .btn-group.w-100.rounded-bottom-3 .btn.shadow-1,
            .btn-group.w-100.rounded-bottom-3 .btn.shadow-2,
            .btn-group.w-100.rounded-bottom-3 .btn.shadow-3,
            .btn-group.w-100.rounded-bottom-3 .btn.shadow-4,
            .btn-group.w-100.rounded-bottom-3 .btn.shadow-5 {
                box-shadow: none !important;
            }

            .btn-group.w-100.rounded-bottom-3 .btn:hover i,
            .btn-group.w-100.rounded-bottom-3 .btn:focus i,
            .btn-group.w-100.rounded-bottom-3 .btn:active i {
                color: #333333;
            }

            @media (max-width: 575.98px) {
                .athlete-agenda-card-shell.has-checkin .athlete-agenda-card-body {
                    padding-right: 4.75rem;
                }

                .athlete-agenda-checkin-action {
                    width: 4rem;
                }

                .athlete-agenda-checkin-action i {
                    font-size: 2.2rem;
                }
            }
        </style>
    </cfif>

    <!--- CARREGA O CSS DO CARD DE RESULTADO DO ATLETA UMA UNICA VEZ --->
    <cfif (VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/resultados/") AND isDefined("VARIABLES.tipoListagem") AND VARIABLES.tipoListagem EQ "resultado" AND NOT isDefined("REQUEST.athleteResultCardCssLoaded")>
        <cfset REQUEST.athleteResultCardCssLoaded = true/>
        <style>
            .athlete-result-card {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px 10px 0 0;
                background-color: #ffffff;
                overflow: hidden;
                box-shadow: none;
            }

            .athlete-result-card-link {
                display: block;
                color: #333333;
                text-decoration: none;
            }

            .athlete-result-card-shell {
                position: relative;
                overflow: visible;
            }

            .athlete-result-card-shell .athlete-result-card-body {
                padding-right: 3rem;
            }

            .athlete-result-card-body {
                padding: 0.95rem;
            }

            .athlete-result-card-top {
                display: grid;
                grid-template-columns: 62px minmax(0, 1fr);
                gap: 0.85rem;
                align-items: start;
            }

            .athlete-result-card-date {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                background-color: #efefef;
                overflow: hidden;
                text-align: center;
                color: #333333;
            }

            .athlete-result-card-date .day {
                display: block;
                font-size: 1.35rem;
                font-weight: 700;
                line-height: 1;
                padding: 0.75rem 0.2rem 0.2rem;
            }

            .athlete-result-card-date .month {
                display: block;
                background-color: #fab120;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                letter-spacing: 0.08em;
                padding: 0.1rem;
                text-transform: uppercase;
            }

            .athlete-result-card-date .year {
                display: block;
                background-color: transparent;
                color: #333333;
                font-size: 0.72rem;
                font-weight: 700;
                padding: 0.1rem;
            }

            .athlete-result-card-title {
                color: #333333;
                font-size: 1rem;
                font-weight: 700;
                line-height: 1.25;
                margin-bottom: 0.4rem;
            }

            .athlete-result-card-meta {
                color: rgba(51, 51, 51, 0.72);
                font-size: 0.82rem;
                line-height: 1.35;
            }

            .athlete-result-card-meta i {
                color: #fab120;
            }

            .athlete-result-manual-badge {
                display: inline-flex;
                align-items: center;
                gap: 0.3rem;
                margin-left: 0.35rem;
                padding: 0.28rem 0.45rem;
                border-radius: 999px;
                background-color: #fff3cd;
                color: #664d03;
                font-size: 0.65rem;
                font-weight: 800;
                line-height: 1;
                vertical-align: middle;
            }

            .athlete-result-manual-info {
                display: flex;
                align-items: flex-start;
                gap: 0.75rem;
                padding: 0.9rem;
                border-radius: 8px;
                background-color: #fff8e8;
                color: #333333;
            }

            .athlete-result-manual-info > i {
                color: #fab120;
                font-size: 1.25rem;
                margin-top: 0.1rem;
            }

            .athlete-result-card-distances {
                display: flex;
                flex-wrap: wrap;
                gap: 0.45rem;
                margin-top: 0.8rem;
            }

            .athlete-result-distance-chip {
                display: inline-flex;
                align-items: center;
                gap: 0.35rem;
                padding: 0.42rem 0.68rem;
                border-radius: 8px;
                border: 1px solid rgba(51, 51, 51, 0.08);
                background-color: #ffffff;
                color: #333333;
                font-size: 0.8rem;
                font-weight: 600;
                line-height: 1;
            }

            .athlete-result-distance-chip i {
                color: #fab120;
            }

            .athlete-result-photos-chip {
                cursor: pointer;
            }

            .athlete-result-photos-chip:hover,
            .athlete-result-photos-chip:focus {
                border-color: rgba(250, 177, 32, 0.55);
                background-color: #fff8e8;
                color: #333333;
            }

            .athlete-result-card-badges {
                display: flex;
                flex-wrap: wrap;
                gap: 0.35rem;
                margin-top: 0.8rem;
                padding-top: 0.8rem;
                border-top: 1px solid rgba(51, 51, 51, 0.08);
            }

            .athlete-result-card-badges img {
                width: 24px;
                height: 24px;
                border-radius: 6px;
            }

            .athlete-result-detail {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-top: 0;
                border-radius: 0 0 10px 10px;
                background-color: #ffffff;
                padding: 0.9rem;
            }

            .athlete-result-detail-top {
                display: grid;
                grid-template-columns: 112px minmax(0, 1fr);
                gap: 0.5rem;
                align-items: stretch;
            }

            .athlete-result-distance-panel,
            .athlete-result-metrics {
                border-radius: 10px;
                overflow: hidden;
                height: 100%;
            }

            .athlete-result-metrics {
                overflow: visible;
            }

            .athlete-result-distance-panel .kms,
            .athlete-result-metrics .kms {
                border-radius: 10px;
                padding: 0.7rem 0.55rem;
                box-shadow: none;
                height: auto !important;
            }

            .athlete-result-distance-panel .kms {
                display: flex;
                flex-direction: column;
                justify-content: center;
                height: 100% !important;
            }

            .athlete-result-distance-panel .distance-value {
                display: block;
                font-size: 1.35rem;
                font-weight: 700;
                line-height: 1;
                margin: 0.2rem 0;
            }

            .athlete-result-distance-panel .distance-subtle {
                display: block;
                font-size: 0.7rem;
                line-height: 1.15;
                opacity: 0.85;
            }

            .athlete-result-metrics .kms {
                padding: 0.35rem;
                position: relative;
                overflow: visible;
            }

            .athlete-result-context {
                position: absolute;
                top: 0.42rem;
                right: 0.42rem;
                z-index: 20;
            }

            .athlete-result-context-toggle {
                width: 30px;
                height: 30px;
                display: inline-flex;
                align-items: center;
                justify-content: center;
                border: 0;
                border-radius: 999px;
                background-color: rgba(255, 255, 255, 0.82);
                color: #333333;
                box-shadow: none !important;
                padding: 0;
            }

            .athlete-result-context-toggle:hover,
            .athlete-result-context-toggle:focus,
            .athlete-result-context-toggle:active {
                background-color: #ffffff;
                color: #333333;
                box-shadow: none !important;
            }

            .athlete-result-context .dropdown-menu {
                border: 1px solid rgba(51, 51, 51, 0.08);
                border-radius: 10px;
                box-shadow: 0 12px 32px rgba(51, 51, 51, 0.12);
                overflow: hidden;
                padding: 0.25rem;
                min-width: 190px;
            }

            .athlete-result-context .dropdown-item {
                border-radius: 8px;
                color: #333333;
                font-size: 0.82rem;
                font-weight: 700;
                padding: 0.55rem 0.65rem;
            }

            .athlete-result-context .dropdown-item:hover,
            .athlete-result-context .dropdown-item:focus {
                background-color: #efefef;
                color: #333333;
            }

            .athlete-result-registered-athlete {
                display: block;
                margin: 0 0.2rem 0.35rem;
                padding: 0.4rem 0.5rem;
                border-radius: 8px;
                background-color: rgba(255,255,255,0.56);
                color: inherit;
                font-size: 0.72rem;
                font-weight: 700;
                line-height: 1.2;
                text-align: left;
            }

            .athlete-result-registered-athlete strong {
                font-weight: 800;
                text-transform: uppercase;
            }

            .athlete-result-metrics-grid {
                display: grid;
                grid-template-columns: repeat(4, minmax(0, 1fr));
                gap: 0.35rem;
            }

            .athlete-result-metric {
                background-color: rgba(255,255,255,0.56);
                border-radius: 8px;
                padding: 0.6rem 0.35rem;
                text-align: center;
                display: flex;
                flex-direction: column;
                justify-content: center;
            }

            .athlete-result-metric .label {
                display: block;
                font-size: 0.68rem;
                font-weight: 700;
                line-height: 1.1;
                text-transform: uppercase;
                margin-bottom: 0.25rem;
            }

            .athlete-result-metric .value {
                display: block;
                font-size: 0.86rem;
                font-weight: 700;
                line-height: 1.1;
            }

            .athlete-result-metric a,
            .athlete-result-distance-panel a {
                color: inherit;
                text-decoration: none;
            }

            @media (max-width: 767.98px) {
                .athlete-result-detail-top {
                    grid-template-columns: 1fr;
                }

                .athlete-result-metrics-grid {
                    grid-template-columns: repeat(2, minmax(0, 1fr));
                }
            }
        </style>
    </cfif>

    <cfoutput>

    <!--- RENDERIZA O CARD COMPACTO USADO NA HOME, BUSCA E LISTAS PUBLICAS --->
    <cfif VARIABLES.template EQ "/" OR VARIABLES.template EQ "/busca/" OR VARIABLES.template EQ "/estado/" OR VARIABLES.template EQ "/maratona/" OR VARIABLES.template EQ "/org/" OR VARIABLES.template EQ "/timer/">

            <a href="#len(trim(VARIABLES.eventCardHrefOverride)) ? VARIABLES.eventCardHrefOverride : VARIABLES.eventCardDetailPath#" class="home-event-card-link"<cfif len(trim(VARIABLES.eventCardAnchorAttrs))> #VARIABLES.eventCardAnchorAttrs#</cfif>>
                <div class="home-event-card" id="#tag#">
                    <div class="home-event-card-body">
                        <div class="home-event-card-top">
                            <div class="home-event-card-date">
                                <span class="day">#lsDateFormat(data_final,"dd")#</span>
                                <span class="month">#lsDateFormat(data_final,"mmm")#</span>
                                <span class="year">#lsDateFormat(data_final,"y")#</span>
                            </div>
                            <div class="min-w-0">
                                <div class="home-event-card-title <cfif status_evento EQ "cancelado">text-gray-light</cfif>">
                                    #nome_evento#<cfif status_evento EQ "cancelado"><mark class="text-danger small ms-2">[ #REQUEST.t("search.eventList.cancelledTag")# ]</mark></cfif>
                                </div>
                                <div class="home-event-card-meta">
                                    <i class="fa-solid fa-location-dot me-1"></i>#cidade#<cfif len(estado)>&nbsp;-&nbsp#estado#</cfif><cfif pais NEQ "BR"> - #pais#</cfif>
                                </div>

                                <div class="home-event-card-flags">
                                    <cfif len(trim(cupom)) AND data_final GTE now()>
                                        <span class="home-event-flag is-coupon"><i class="fa-solid fa-ticket me-1"></i>#REQUEST.t("search.eventList.coupon")# #cupom#</span>
                                    </cfif>
                                    <cfif tipo_corrida EQ "rua">
                                        <span class="home-event-flag">#REQUEST.t("search.eventList.roadRace")#</span>
                                    <cfelseif tipo_corrida EQ "treino">
                                        <span class="home-event-flag">#REQUEST.t("search.eventList.training")#</span>
                                    <cfelseif len(trim(tipo_corrida))>
                                        <span class="home-event-flag">#REQUEST.t("search.eventList.trailRun")#</span>
                                    </cfif>
                                </div>
                                <cfif tipo_corrida NEQ "treino">
                                    <div class="home-event-card-distances">
                                        <cfif Len(lista_percursos) AND arraylen(deserializeJSON(lista_percursos))>
                                            <cfloop array="#deserializeJSON(lista_percursos)#" index="distancia">
                                                <span class="home-event-distance">
                                                    <i class="fa-solid <cfif isDefined("distancia.tipo_corrida") AND len(trim(distancia.tipo_corrida))><cfif distancia.tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif><cfelse><cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif></cfif>"></i>
                                                    #distancia.percurso##distancia.unidade#
                                                </span>
                                            </cfloop>
                                        <cfelse>
                                            <cfloop list="#categorias#" delimiters="," index="distancia">
                                                <span class="home-event-distance">
                                                    <i class="fa-solid <cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif>"></i>
                                                    #trim(REReplace(distancia,"[^0-9.]", "","ALL"))#km
                                                </span>
                                            </cfloop>
                                        </cfif>
                                    </div>
                                </cfif>

                                <cfif NOT VARIABLES.eventCardHideBadges AND Len(badges) AND arraylen(deserializeJSON(badges))>
                                    <div class="home-event-card-badges">
                                        <cfset VARIABLES.ultimoBadge = ""/>
                                        <cfloop array="#deserializeJSON(badges)#" index="badge">
                                            <cfif VARIABLES.ultimoBadge NEQ badge.badge>
                                                <img src="https://roadrunners.run/assets/badges/badge_#badge.badge#<cfif badge.badge EQ "cbat">_#lcase(badge.valor_badge)#</cfif>.jpg" alt="#badge.badge_tooltip#" title="#badge.badge_tooltip#" data-mdb-tooltip-init>
                                            </cfif>
                                            <cfset VARIABLES.ultimoBadge = badge.badge/>
                                        </cfloop>
                                    </div>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </div>
            </a>

        <!--- RENDERIZA O CARD DA AGENDA DO ATLETA --->
        <cfelseif (VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/agenda/") AND isDefined("VARIABLES.tipoListagem") AND VARIABLES.tipoListagem EQ "calendario">

            <div class="athlete-agenda-card-shell">
            <a href="#VARIABLES.eventCardDetailPath#" class="athlete-agenda-card-link">
                <div class="athlete-agenda-card" id="#tag#">
                    <div class="athlete-agenda-card-body">
                        <div class="athlete-agenda-card-top">
                            <div class="athlete-agenda-card-date">
                                <span class="day">#lsDateFormat(data_final,"dd")#</span>
                                <span class="month">#lsDateFormat(data_final,"mmm")#</span>
                                <span class="year">#lsDateFormat(data_final,"y")#</span>
                            </div>

                            <div class="min-w-0">
                                <div class="athlete-agenda-card-title <cfif status_evento EQ "cancelado">text-gray-light</cfif>">
                                    #nome_evento#<cfif status_evento EQ "cancelado"><mark class="text-danger small ms-2">[ #REQUEST.t("search.eventList.cancelledTag")# ]</mark></cfif>
                                </div>

                                <div class="athlete-agenda-card-meta">
                                    <i class="fa-solid fa-location-dot me-1"></i>#cidade#<cfif len(estado)>&nbsp;-&nbsp#estado#</cfif><cfif pais NEQ "BR"> - #pais#</cfif>
                                </div>

                                <div class="athlete-agenda-card-flags">
                                    <!--- Uma marcacao social nao comprova inscricao nem garante participacao no evento. --->
                                    <cfif isDefined("qEventosAba.tipo_checkin") AND lCase(trim(qEventosAba.tipo_checkin & "")) NEQ "inscricao">
                                        <span class="athlete-agenda-flag is-status">#REQUEST.t("search.eventList.inAgenda")#</span>
                                    </cfif>

                                    <cfif len(trim(cupom)) AND data_final GTE now()>
                                        <span class="athlete-agenda-flag is-coupon"><i class="fa-solid fa-ticket me-1"></i>#REQUEST.t("search.eventList.coupon")# #cupom#</span>
                                    </cfif>

                                    <cfif tipo_corrida EQ "rua">
                                        <span class="athlete-agenda-flag">#REQUEST.t("search.eventList.roadRace")#</span>
                                    <cfelseif tipo_corrida EQ "treino">
                                        <span class="athlete-agenda-flag">#REQUEST.t("search.eventList.training")#</span>
                                    <cfelseif len(trim(tipo_corrida))>
                                        <span class="athlete-agenda-flag">#REQUEST.t("search.eventList.trailRun")#</span>
                                    </cfif>
                                </div>
                            </div>
                        </div>

                        <cfif tipo_corrida NEQ "treino">
                            <div class="athlete-agenda-card-distances">
                                <cfif Len(lista_percursos) AND arraylen(deserializeJSON(lista_percursos))>
                                    <cfloop array="#deserializeJSON(lista_percursos)#" index="distancia">
                                        <span class="athlete-agenda-distance">
                                            <i class="fa-solid <cfif isDefined("distancia.tipo_corrida") AND len(trim(distancia.tipo_corrida))><cfif distancia.tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif><cfelse><cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif></cfif>"></i>
                                            #distancia.percurso##distancia.unidade#
                                        </span>
                                    </cfloop>
                                <cfelse>
                                    <cfloop list="#categorias#" delimiters="," index="distancia">
                                        <span class="athlete-agenda-distance">
                                            <i class="fa-solid <cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif>"></i>
                                            #trim(REReplace(distancia,"[^0-9.]", "","ALL"))#km
                                        </span>
                                    </cfloop>
                                </cfif>
                            </div>
                        </cfif>

                        <cfif Len(badges) AND arraylen(deserializeJSON(badges))>
                            <div class="athlete-agenda-card-badges">
                                <cfset VARIABLES.ultimoBadge = ""/>
                                <cfloop array="#deserializeJSON(badges)#" index="badge">
                                    <cfif VARIABLES.ultimoBadge NEQ badge.badge>
                                        <cfset VARIABLES.badgeTooltipLocalized = trim(badge.badge_tooltip)/>
                                        <cfif structKeyExists(REQUEST, "lang") AND REQUEST.lang NEQ "pt-BR">
                                            <cfswitch expression="#lcase(trim(badge.badge))#">
                                                <cfcase value="aferido">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Measured course" : "Recorrido medido"/>
                                                </cfcase>
                                                <cfcase value="boston">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Boston qualifier" : "Clasificatoria para Boston"/>
                                                </cfcase>
                                                <cfcase value="cbat">
                                                    <cfif lcase(trim(badge.valor_badge)) EQ "ouro">
                                                        <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "CBAt Gold Label" : "Sello CBAt Oro"/>
                                                    <cfelseif lcase(trim(badge.valor_badge)) EQ "prata">
                                                        <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "CBAt Silver Label" : "Sello CBAt Plata"/>
                                                    <cfelseif lcase(trim(badge.valor_badge)) EQ "bronze">
                                                        <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "CBAt Bronze Label" : "Sello CBAt Bronce"/>
                                                    <cfelse>
                                                        <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "CBAt badge" : "Sello CBAt"/>
                                                    </cfif>
                                                </cfcase>
                                                <cfcase value="certificado">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Official certificate" : "Certificado oficial"/>
                                                </cfcase>
                                                <cfcase value="disc,disc05,disc10,disc15,disc20">
                                                    <cfset VARIABLES.badgeDiscountValue = rereplace(lcase(trim(badge.badge)), "[^0-9]", "", "all")/>
                                                    <cfif len(trim(VARIABLES.badgeDiscountValue))>
                                                        <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "#VARIABLES.badgeDiscountValue#% discount" : "Descuento de #VARIABLES.badgeDiscountValue#%"/>
                                                    <cfelse>
                                                        <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Discount" : "Descuento"/>
                                                    </cfif>
                                                </cfcase>
                                                <cfcase value="fca_rua">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "FCA certified road race" : "Carrera de calle certificada por FCA"/>
                                                </cfcase>
                                                <cfcase value="fca_trail">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "FCA certified trail race" : "Carrera de trail certificada por FCA"/>
                                                </cfcase>
                                                <cfcase value="foco">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Race photos available" : "Fotos de la carrera disponibles"/>
                                                </cfcase>
                                                <cfcase value="kids">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Kids race" : "Carrera infantil"/>
                                                </cfcase>
                                                <cfcase value="mapa,mapa1k,mapa2k,mapa3k,mapa4k,mapa5k,mapa6k,mapa7k,mapa8k,mapa9k,mapa10k,mapa11k,mapa12k,mapa13k,mapa14k,mapa15k,mapa16k,mapa17k,mapa18k,mapa19k,mapa20k,mapa21k,mapa30k,mapa42k,mapa50k">
                                                    <cfset VARIABLES.badgeMapValue = rereplace(lcase(trim(badge.badge)), "[^0-9]", "", "all")/>
                                                    <cfif len(trim(VARIABLES.badgeMapValue))>
                                                        <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "#VARIABLES.badgeMapValue#K course map" : "Mapa del recorrido de #VARIABLES.badgeMapValue#K"/>
                                                    <cfelse>
                                                        <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Course map" : "Mapa del recorrido"/>
                                                    </cfif>
                                                </cfcase>
                                                <cfcase value="mega,mega21k,mega42k">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Mega challenge" : "Desafío Mega"/>
                                                </cfcase>
                                                <cfcase value="oly">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Olympic distance" : "Distancia olímpica"/>
                                                </cfcase>
                                                <cfcase value="pacer">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Pacers available" : "Liebres disponibles"/>
                                                </cfcase>
                                                <cfcase value="sub4">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Sub-4 marathon" : "Maratón sub 4"/>
                                                </cfcase>
                                                <cfcase value="supra">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "Supra challenge" : "Desafío Supra"/>
                                                </cfcase>
                                                <cfcase value="wa">
                                                    <cfset VARIABLES.badgeTooltipLocalized = REQUEST.lang EQ "en" ? "World Athletics" : "World Athletics"/>
                                                </cfcase>
                                            </cfswitch>
                                        </cfif>
                                        <img src="https://roadrunners.run/assets/badges/badge_#badge.badge#<cfif badge.badge EQ "cbat">_#lcase(badge.valor_badge)#</cfif>.jpg" alt="#HTMLEditFormat(VARIABLES.badgeTooltipLocalized)#" title="#HTMLEditFormat(VARIABLES.badgeTooltipLocalized)#" data-mdb-tooltip-init>
                                    </cfif>
                                    <cfset VARIABLES.ultimoBadge = badge.badge/>
                                </cfloop>
                            </div>
                        </cfif>
                    </div>
                </div>
            </a>

            </div>

        <!--- RENDERIZA O CARD DE RESULTADO COM TEMPOS E COLOCACOES DO ATLETA --->
        <cfelseif (VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/resultados/") AND isDefined("VARIABLES.tipoListagem") AND VARIABLES.tipoListagem EQ "resultado">

            <cfset VARIABLES.badgeFoco = ""/>
            <cfset VARIABLES.resultBadges = ArrayNew(1)/>
            <cfset VARIABLES.resultIsManual = isDefined("qCorridasAtleta.origem_resultado") AND lCase(trim(qCorridasAtleta.origem_resultado & "")) EQ "validacao_documental"/>
            <cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id AND Len(badges) AND isJSON(badges)>
                <cfset VARIABLES.resultBadges = deserializeJSON(badges)/>
                <cfif isArray(VARIABLES.resultBadges) AND arrayLen(VARIABLES.resultBadges)>
                    <cfloop array="#VARIABLES.resultBadges#" item="badge">
                        <cfif isStruct(badge) AND structKeyExists(badge, "badge") AND badge.badge EQ "foco">
                            <cfset VARIABLES.badgeFoco = badge/>
                        </cfif>
                    </cfloop>
                </cfif>
            </cfif>

            <div class="athlete-result-card-shell">
                <cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id AND NOT VARIABLES.resultIsManual>
                    <div class="dropdown athlete-result-context">
                        <button class="athlete-result-context-toggle"
                                type="button"
                                id="dropdownResultado#qCorridasAtleta.id_resultado#"
                                data-mdb-dropdown-init
                                aria-expanded="false"
                                aria-label="#REQUEST.t("search.eventList.resultOptions")#">
                            <i class="fa-solid fa-ellipsis-vertical"></i>
                        </button>
                        <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="dropdownResultado#qCorridasAtleta.id_resultado#">
                            <li>
                                <a class="dropdown-item"
                                   href="?action=desvincularcorrida&filtro=resultados&id_resultado=#qCorridasAtleta.id_resultado#">
                                    <i class="fa-solid fa-link-slash me-2 text-warning"></i>#REQUEST.t("search.eventList.unlinkRace")#
                                </a>
                            </li>
                        </ul>
                    </div>
                </cfif>

            <a href="#VARIABLES.eventCardDetailPath#" class="athlete-result-card-link">
                <div class="athlete-result-card" id="#tag#">
                    <div class="athlete-result-card-body">
                        <div class="athlete-result-card-top">
                            <div class="athlete-result-card-date">
                                <span class="day">#lsDateFormat(VARIABLES.eventCardDisplayDate,"dd")#</span>
                                <span class="month">#lsDateFormat(VARIABLES.eventCardDisplayDate,"mmm")#</span>
                                <span class="year">#lsDateFormat(VARIABLES.eventCardDisplayDate,"y")#</span>
                            </div>

                            <div class="min-w-0">
                                <div class="athlete-result-card-title <cfif status_evento EQ "cancelado">text-gray-light</cfif>">
                                    #nome_evento#<cfif status_evento EQ "cancelado"><mark class="text-danger small ms-2">[ #REQUEST.t("search.eventList.cancelledTag")# ]</mark></cfif>
                                    <cfif VARIABLES.resultIsManual><span class="athlete-result-manual-badge"><i class="fa-solid fa-file-circle-check"></i>#REQUEST.t("search.eventList.manualResult")#</span></cfif>
                                </div>

                                <div class="athlete-result-card-meta">
                                    <i class="fa-solid fa-location-dot me-1"></i>#cidade#<cfif len(estado)>&nbsp;-&nbsp#estado#</cfif><cfif pais NEQ "BR"> - #pais#</cfif>
                                </div>

                                <div class="athlete-result-card-distances">
                                    <cfif isDefined("qCorridasAtleta") AND len(trim(qCorridasAtleta.percurso & ""))>
                                        <span class="athlete-result-distance-chip">
                                            <i class="fa-solid fa-medal"></i>
                                            #qCorridasAtleta.percurso#k
                                        </span>
                                    <cfelseif isDefined("lista_percursos_resultado") AND Len(lista_percursos_resultado) AND arraylen(deserializeJSON(lista_percursos_resultado))>
                                            <cfloop array="#deserializeJSON(lista_percursos_resultado)#" index="distancia">
                                                <cfif val(distancia.concluintes) GT 0>
                                                    <span class="athlete-result-distance-chip">
                                                        <i class="fa-solid <cfif isDefined("distancia.tipo_corrida") AND len(trim(distancia.tipo_corrida))><cfif distancia.tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif><cfelse><cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif></cfif>"></i>
                                                        #distancia.modalidade#
                                                    </span>
                                                </cfif>
                                            </cfloop>
                                    <cfelseif Len(lista_percursos) AND arraylen(deserializeJSON(lista_percursos))>
                                        <cfloop array="#deserializeJSON(lista_percursos)#" index="distancia">
                                            <span class="athlete-result-distance-chip">
                                                <i class="fa-solid <cfif isDefined("distancia.tipo_corrida") AND len(trim(distancia.tipo_corrida))><cfif distancia.tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif><cfelse><cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif></cfif>"></i>
                                                #distancia.percurso##distancia.unidade#
                                            </span>
                                        </cfloop>
                                    <cfelseif isDefined("categorias") AND len(trim(categorias & ""))>
                                        <cfloop list="#categorias#" delimiters="," index="distancia">
                                            <span class="athlete-result-distance-chip">
                                                <i class="fa-solid <cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif>"></i>
                                                #trim(REReplace(distancia,"[^0-9.]", "","ALL"))#km
                                            </span>
                                        </cfloop>
                                    </cfif>
                                    <cfif isStruct(VARIABLES.badgeFoco)>
                                        <span class="athlete-result-distance-chip athlete-result-photos-chip"
                                              role="button"
                                              tabindex="0"
                                              data-mdb-valor-badge="#VARIABLES.badgeFoco.valor_badge#"
                                              data-mdb-numero-peito="#qCorridasAtleta.num_peito#"
                                              data-mdb-complemento-badge="#isDefined("VARIABLES.badgeFoco.complemento_badge") ? VARIABLES.badgeFoco.complemento_badge : 'numero'#"
                                              data-mdb-modal-init
                                              data-mdb-target="##modal_cupom_foco"
                                              onclick="event.preventDefault(); event.stopPropagation();"
                                              onkeydown="if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); event.stopPropagation(); this.click(); }"
                                              title="#VARIABLES.badgeFoco.valor_badge# | #isDefined("VARIABLES.badgeFoco.complemento_badge") ? VARIABLES.badgeFoco.complemento_badge : 'numero'# #qCorridasAtleta.num_peito#">
                                            <i class="fa-solid fa-camera"></i>
                                            #REQUEST.t("search.eventList.myPhotos")#
                                        </span>
                                    </cfif>
                                </div>
                            </div>
                        </div>

                        <cfif NOT VARIABLES.eventCardHideBadges AND Len(badges) AND arraylen(deserializeJSON(badges))>
                            <div class="athlete-result-card-badges">
                                <cfset VARIABLES.ultimoBadge = ""/>
                                <cfloop array="#deserializeJSON(badges)#" index="badge">
                                    <cfif VARIABLES.ultimoBadge NEQ badge.badge>
                                        <img src="https://roadrunners.run/assets/badges/badge_#badge.badge#<cfif badge.badge EQ "cbat">_#lcase(badge.valor_badge)#</cfif>.jpg" alt="#badge.badge_tooltip#" title="#badge.badge_tooltip#" data-mdb-tooltip-init>
                                    </cfif>
                                    <cfset VARIABLES.ultimoBadge = badge.badge/>
                                </cfloop>
                            </div>
                        </cfif>
                    </div>
                </div>
            </a>
            </div>

        <!--- RENDERIZA O CARD PRINCIPAL NA PAGINA DO EVENTO --->
        <cfelseif VARIABLES.template EQ "/evento/">

            <div class="event-detail-card" id="#tag#">
                <div class="event-detail-card-body">
                    <div class="event-detail-card-top">
                        <div class="event-detail-card-date">
                            <span class="day">#lsDateFormat(data_final,"dd")#</span>
                            <span class="month">#lsDateFormat(data_final,"mmm")#</span>
                            <span class="year">#lsDateFormat(data_final,"y")#</span>
                        </div>

                        <div class="min-w-0">
                            <h1 class="event-detail-card-title <cfif status_evento EQ "cancelado">text-gray-light</cfif>">#nome_evento#<cfif status_evento EQ "cancelado"><mark class="text-danger small ms-2">[ #REQUEST.t("search.eventList.cancelledTag")# ]</mark></cfif></h1>

                            <div class="event-detail-card-meta">
                                <div><span><i class="fa-solid fa-location-dot me-1"></i><cfif len(VARIABLES.eventCardCidadePath)><a href="#VARIABLES.eventCardCidadePath#">#cidade#</a><cfelse>#cidade#</cfif><cfif len(estado)>&nbsp;-&nbsp;<cfif len(VARIABLES.eventCardEstadoPath)><a href="#VARIABLES.eventCardEstadoPath#">#estado#</a><cfelse>#estado#</cfif></cfif><cfif pais NEQ "BR"> - <a href="#VARIABLES.eventCardSearchPath#?internacional=true">#pais#</a></cfif></span><cfif isDefined("concluintes") AND val(concluintes) GT 0><span class="d-inline-block ms-sm-2"><i class="fa-solid fa-person-running me-1"></i>#REQUEST.t("search.eventList.finishersCount", { "count" = lsNumberFormat(concluintes) })#</span></cfif></div>
                                <div class="mt-1"><i class="fa-solid fa-calendar me-1"></i><cfif data_inicial NEQ data_final>#lsDateFormat(data_inicial,"dd/mm/yyyy")# a #lsDateFormat(data_final,"dd/mm/yyyy")#<cfelse>#lsDateFormat(data_final,"dd/mm/yyyy")#</cfif></div>
                            </div>

                            <div class="event-detail-card-flags">
                                <cfif len(trim(cupom)) AND data_final GTE now()>
                                    <span class="event-detail-flag is-coupon"><i class="fa-solid fa-ticket me-1"></i>#REQUEST.t("search.eventList.coupon")# #cupom#</span>
                                </cfif>
                                <cfif tipo_corrida EQ "rua">
                                    <span class="event-detail-flag">#REQUEST.t("search.eventList.roadRace")#</span>
                                <cfelseif tipo_corrida EQ "treino">
                                    <span class="event-detail-flag">#REQUEST.t("search.eventList.training")#</span>
                                <cfelseif len(trim(tipo_corrida))>
                                    <span class="event-detail-flag">#REQUEST.t("search.eventList.trailRun")#</span>
                                </cfif>
                            </div>

                            <div class="event-detail-card-distances">
                                <cfif isDefined("lista_percursos_resultado") AND Len(lista_percursos_resultado) AND arraylen(deserializeJSON(lista_percursos_resultado))>
                                    <cfif NOT isDefined("qCorridasAtleta")>
                                        <cfset VARIABLES.eventDetailPercursosResultado = deserializeJSON(lista_percursos_resultado)/>
                                        <cfset VARIABLES.eventDetailPercursosAgrupados = structNew("ordered")/>
                                        <cfset VARIABLES.eventDetailPercursosOrdem = []/>
                                        <cfloop array="#VARIABLES.eventDetailPercursosResultado#" index="distancia">
                                            <cfset VARIABLES.eventDetailPercursoKey = trim(distancia.percurso & "")/>
                                            <cfif len(VARIABLES.eventDetailPercursoKey)>
                                                <cfif NOT structKeyExists(VARIABLES.eventDetailPercursosAgrupados, VARIABLES.eventDetailPercursoKey)>
                                                    <cfset arrayAppend(VARIABLES.eventDetailPercursosOrdem, VARIABLES.eventDetailPercursoKey)/>
                                                    <cfset VARIABLES.eventDetailPercursosAgrupados[VARIABLES.eventDetailPercursoKey] = {
                                                        percurso = VARIABLES.eventDetailPercursoKey,
                                                        concluintes = 0,
                                                        tipo_corrida = (structKeyExists(distancia, "tipo_corrida") ? trim(distancia.tipo_corrida & "") : "")
                                                    }/>
                                                </cfif>
                                                <cfset VARIABLES.eventDetailPercursosAgrupados[VARIABLES.eventDetailPercursoKey].concluintes = VARIABLES.eventDetailPercursosAgrupados[VARIABLES.eventDetailPercursoKey].concluintes + val(distancia.concluintes)/>
                                            </cfif>
                                        </cfloop>
                                        <cfloop array="#VARIABLES.eventDetailPercursosOrdem#" index="eventDetailPercursoKey">
                                            <cfset VARIABLES.eventDetailPercursoAgrupado = VARIABLES.eventDetailPercursosAgrupados[eventDetailPercursoKey]/>
                                            <cfset VARIABLES.eventDetailPercursoLabel = val(VARIABLES.eventDetailPercursoAgrupado.percurso) EQ int(val(VARIABLES.eventDetailPercursoAgrupado.percurso)) ? int(val(VARIABLES.eventDetailPercursoAgrupado.percurso)) : VARIABLES.eventDetailPercursoAgrupado.percurso/>
                                            <cfif val(VARIABLES.eventDetailPercursoAgrupado.concluintes) GT 0>
                                                <span class="event-detail-distance"><i class="fa-solid <cfif len(trim(VARIABLES.eventDetailPercursoAgrupado.tipo_corrida))><cfif VARIABLES.eventDetailPercursoAgrupado.tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif><cfelse><cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif></cfif>"></i>#VARIABLES.eventDetailPercursoLabel#k <span class="fw-normal">| #lsNumberFormat(VARIABLES.eventDetailPercursoAgrupado.concluintes)#</span></span>
                                            </cfif>
                                        </cfloop>
                                    </cfif>
                                <cfelseif Len(lista_percursos) AND arraylen(deserializeJSON(lista_percursos))>
                                    <cfloop array="#deserializeJSON(lista_percursos)#" index="distancia">
                                        <span class="event-detail-distance"><i class="fa-solid <cfif isDefined("distancia.tipo_corrida") AND len(trim(distancia.tipo_corrida))><cfif distancia.tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif><cfelse><cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif></cfif>"></i>#distancia.percurso##distancia.unidade#</span>
                                    </cfloop>
                                <cfelse>
                                    <cfloop list="#categorias#" delimiters="," index="distancia">
                                        <cfset VARIABLES.eventDetailDistanciaValor = trim(REReplace(distancia,"[^0-9.]", "","ALL"))/>
                                        <span class="event-detail-distance"><i class="fa-solid <cfif (#tipo_corrida# EQ 'rua')>fa-person-running<cfelse>fa-mountain</cfif>"></i>#VARIABLES.eventDetailDistanciaValor#km</span>
                                    </cfloop>
                                </cfif>
                            </div>

                            <cfif Len(badges) AND arraylen(deserializeJSON(badges))>
                                <div class="event-detail-card-badges">
                                    <cfset VARIABLES.ultimoBadge = ""/>
                                    <cfloop array="#deserializeJSON(badges)#" index="badge">
                                        <cfif VARIABLES.ultimoBadge NEQ badge.badge>
                                            <img src="https://roadrunners.run/assets/badges/badge_#badge.badge#<cfif badge.badge EQ "cbat">_#lcase(badge.valor_badge)#</cfif>.jpg" alt="#badge.badge_tooltip#" title="#badge.badge_tooltip#" class="d-inline rounded" width="24px" height="24px" data-mdb-tooltip-init>
                                        </cfif>
                                        <cfset VARIABLES.ultimoBadge = badge.badge/>
                                    </cfloop>
                                </div>
                            </cfif>
                        </div>
                    </div>
                </div>
            </div>

        <!--- RENDERIZA O CARD LEGADO USADO POR TELAS QUE AINDA NAO MIGRARAM --->
        <cfelse>

        <!--- ENVOLVER COM LINK SE NAO ESTA NA PAGINA DO EVENTO --->

        <cfif VARIABLES.template NEQ "/evento/"><a href="#VARIABLES.eventCardDetailAbsoluteUrl#" class="m-0 p-0"></cfif>


            <!--- CARD COM OS DADOS DO EVENTO --->

            <div class="row m-0 card flex-row <cfif VARIABLES.template EQ "/resultados/" OR VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/agenda/">rounded-bottom-0</cfif>" id="#tag#">

                <!--- DATA --->

                <div class="col-1 w-50px lh-1 fw-bold text-center text-light p-0 bg-black bg-opacity-25 <cfif VARIABLES.template EQ "/resultados/" OR VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/agenda/">rounded-top-3 rounded-end-0<cfelse>rounded-start-3</cfif>">
                    <div class="fs-5 flex-fill pt-2 bg-dark bg-opacity-25 rounded-top-3 rounded-end-0">#lsDateFormat(data_final,"dd")#</div>
                    <div class="fs-6 flex-fill pb-1 bg-dark bg-opacity-25">#lsDateFormat(data_final,"mmm")#</div>
                    <div class="fs-6 flex-fill py-1">#lsDateFormat(data_final,"y")#</div>
                </div>

                <!--- DADOS DO EVENTO --->

                <div class="col text-dark px-2 pt-1 pb-2 lh-1"
                    <cfif len(trim(cupom)) AND data_final GTE now() AND VARIABLES.template NEQ "/evento/">
                        style="border-right: 2px dotted lightgray;"
                    </cfif>>

                    <!--- SE O CARD EH NA PAGINA DO EVENTO USA H1 --->

                    <cfif VARIABLES.template EQ "/evento/">
                        <h1 class="mb-1 pt-1 lh-1 h6 <cfif status_evento EQ "cancelado">text-gray-light</cfif>">#nome_evento#<cfif status_evento EQ "cancelado"><mark class="text-danger small ms-2">[ #REQUEST.t("search.eventList.cancelledTag")# ]</mark></cfif></h1>
                    <cfelse>
                        <h2 class="mb-1 pt-1 lh-1 h6 <cfif status_evento EQ "cancelado">text-gray-light</cfif>">#nome_evento#<cfif status_evento EQ "cancelado"><mark class="text-danger small ms-2">[ #REQUEST.t("search.eventList.cancelledTag")# ]</mark></cfif></h2>
                    </cfif>

                    <!--- DATA E LOCAL --->

                    <div class="small mb-1">
                        <!---<i class="fa-regular fa-calendar me-1"></i><cfif (#data_inicial# NEQ #data_final#)>#lsDateFormat(data_inicial,"dd/mm/yyyy")# a #lsDateFormat(data_final,"dd/mm/yyyy")#<cfelse>#lsDateFormat(data_final,"dd/mm/yyyy")#</cfif>--->
                        <cfif VARIABLES.template EQ "/evento/">
                            <small><i class="fa-solid fa-location-dot me-1 small"></i><cfif len(VARIABLES.eventCardCidadePath)><a href="#VARIABLES.eventCardCidadePath#">#cidade#</a><cfelse>#cidade#</cfif><cfif len(estado)>&nbsp-&nbsp<cfif len(VARIABLES.eventCardEstadoPath)><a href="#VARIABLES.eventCardEstadoPath#">#estado#</a><cfelse>#estado#</cfif></cfif><cfif pais NEQ "BR"> - <a href="#VARIABLES.eventCardSearchPath#?internacional=true">#pais#</a></cfif></small>
                        <cfelse>
                            <small><i class="fa-solid fa-location-dot me-1 small"></i>#cidade#<cfif len(estado)>&nbsp-&nbsp#estado#</cfif><cfif pais NEQ "BR"> - #pais#</cfif></small>
                        </cfif>
                    </div>

                    <!--- DISTANCIAS --->

                    <div>
                        <!--- DISTANCIAS COM RESULTADO --->
                        <cfif isDefined("lista_percursos_resultado") AND Len(lista_percursos_resultado) AND arraylen(deserializeJSON(lista_percursos_resultado))>
                            <!--- DISTANCIA CORRIDA NA PROVA (usuario) --->
                            <cfif isDefined("qCorridasAtleta")>
                                <!--- DISTANCIAS GERAIS DA PROVA (listagem) --->
                            <cfelse>
                                <cfloop array="#deserializeJSON(lista_percursos_resultado)#" index="distancia">
                                    <cfif val(distancia.concluintes) GT 0>
                                        <div class="kms d-inline-block" data-color="#distancia.percurso#"><i class="fa-solid <cfif isDefined("distancia.tipo_corrida") AND len(trim(distancia.tipo_corrida))><cfif distancia.tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif><cfelse><cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif></cfif>"></i>&nbsp;#distancia.modalidade# <span class="fw-normal">| #REQUEST.t("search.eventList.finishersCount", { "count" = lsNumberFormat(distancia.concluintes) })#</span></div>
                                    </cfif>
                                </cfloop>
                            </cfif>
                            <!--- DISTANCIAS SEM RESULTADO --->
                        <cfelseif Len(lista_percursos) AND arraylen(deserializeJSON(lista_percursos))>
                            <cfloop array="#deserializeJSON(lista_percursos)#" index="distancia">
                                <div class="kms d-inline-block" data-color="#distancia.percurso#"><i class="fa-solid <cfif isDefined("distancia.tipo_corrida") AND len(trim(distancia.tipo_corrida))><cfif distancia.tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif><cfelse><cfif tipo_corrida EQ 'rua'>fa-person-running<cfelse>fa-mountain</cfif></cfif>"></i>&nbsp;#distancia.percurso##distancia.unidade#</div>
                            </cfloop>
                        <cfelse>
                            <!--- DISTANCIAS POR TEXTO --->
                            <cfloop list="#categorias#" delimiters="," index="distancia">
                                <div class="kms d-inline-block" data-color="#trim(REReplace(distancia,"[^0-9.]", "","ALL"))#"><i class="fa-solid <cfif (#tipo_corrida# EQ 'rua')>fa-person-running<cfelse>fa-mountain</cfif>"></i>&nbsp;#trim(REReplace(distancia,"[^0-9.]", "","ALL"))#km</div>
                            </cfloop>
                        </cfif>
                    </div>

                    <!--- BADGES --->

                    <cfif Len(badges) AND arraylen(deserializeJSON(badges))>
                        <div class="mt-1">
                            <cfset VARIABLES.ultimoBadge = ""/>
                            <cfloop array="#deserializeJSON(badges)#" index="badge">
                                <cfif VARIABLES.ultimoBadge NEQ badge.badge>
                                    <img src="https://roadrunners.run/assets/badges/badge_#badge.badge#<cfif badge.badge EQ "cbat">_#lcase(badge.valor_badge)#</cfif>.jpg" alt="#badge.badge_tooltip#" title="#badge.badge_tooltip#" class="d-inline rounded" width="24px" height="24px" data-mdb-tooltip-init>
                                </cfif>
                                <cfset VARIABLES.ultimoBadge = badge.badge/>
                            </cfloop>
                            </div>
                    </cfif>

                </div>

                <!--- CUPOM--->
                <cfif len(trim(cupom)) AND data_final GTE now() AND VARIABLES.template NEQ "/evento/">
                    <div class="col-1 w-50px p-0 lh-1 small text-center text-warning align-content-center align-items-center bg-warning-subtle border border-warning border-opacity-10 border-start-0 <cfif VARIABLES.template EQ "/resultados/" OR VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/agenda/">rounded-end-3 rounded-bottom-0<cfelse>rounded-end-3</cfif>">
                        <small><cfoutput>#REQUEST.t("search.eventList.coupon")#</cfoutput></small>
                        <div class="fs-5 fw-bold">#cupom#</div>
                    </div>
                </cfif>

                <!---BADGES--->
                <!---<cfif Len(badges) AND arraylen(deserializeJSON(badges)) AND NOT isDefined("qCorridasAtleta")>--->
                <!---<cfif Len(badges) AND arraylen(deserializeJSON(badges))>
                    <div class="col-1 px-0 rounded-end d-flex flex-wrap align-content-start justify-content-end border border-white border-1">
                        <cfset VARIABLES.ultimoBadge = ""/>
                        <cfloop array="#deserializeJSON(badges)#" index="badge">
                            <cfif VARIABLES.ultimoBadge NEQ badge.badge>
                                <img src="/assets/badges/badge_#badge.badge#<cfif badge.badge EQ "cbat">_#lcase(badge.valor_badge)#</cfif>.jpg" class="d-inline rounded border border-1 border-rounded border-white" width="24px" height="24px" data-mdb-tooltip-init title="#badge.badge_tooltip#">
                            </cfif>
                            <cfset VARIABLES.ultimoBadge = badge.badge/>
                        </cfloop>
                    </div>
                </cfif>--->

            </div>


        <!--- FECHANDO O LINK NA PAGINA DO EVENTO --->

        <cfif VARIABLES.template NEQ "/evento/"></a></cfif>

        </cfif>



        <!--- BUTTOM BAR --->

        <cfif (VARIABLES.template EQ "/agenda/" OR VARIABLES.template EQ "/atleta/") AND data_final GT now()-1>


            <cfif NOT isDefined("lista_percursos_resultado") OR NOT isDefined("qCorridasAtleta")>

                <div class="btn-group w-100 rounded-bottom-3">

                    <!--- BOTAO DE REMOVER SE ESTA NA PAGINA DO PROPRIO USUARIO --->

                    <cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id>

                        <a class="btn bg-dark bg-opacity-10" style="border-radius: 0 0 0 8px"
                            href="#VARIABLES.eventCardDetailPath#?acao=remover&redirecionar=#VARIABLES.eventCardAgendaRedirectPath#">
                            <i class="fa-solid fa-calendar"></i> #REQUEST.t("search.eventList.remove")#
                        </a>

                    <!--- BOTAO DE ADICIONAR A MINHA AGENDA --->

                    <cfelse>

                        <a class="btn bg-dark bg-opacity-10" style="border-radius: 0 0 0 8px"
                            href="#VARIABLES.eventCardDetailPath#?acao=inscricao&redirecionar=#VARIABLES.eventCardAgendaRedirectPath & chr(35) & tag#">
                            <i class="fa-regular fa-calendar"></i> #REQUEST.t("search.eventList.save")#
                        </a>

                    </cfif>

                    <!--- ENVIAR O EVENTO PELO CHAT --->

                    <cfif Usuario.logado>
                        <button type="button" class="btn bg-dark bg-opacity-10"
                            data-event-chat-share-event-id="#val(id_evento)#"
                            data-mdb-modal-init
                            data-mdb-target="##eventChatShareModal">
                            <i class="fa-solid fa-paper-plane"></i> #REQUEST.t("event.actions.send")#
                        </button>
                    </cfif>

                    <!--- ADICIONAR A AGENDA DO GOOGLE --->

                    <a class="btn bg-dark bg-opacity-10" style="border-radius: 0 0 8px 0"
                        href="http://www.google.com/calendar/render?action=TEMPLATE&text=#nome_evento#&dates=#DateFormat(data_inicial,"yyyymmdd")#/#DateFormat(dateAdd("d", 1, data_final),"yyyymmdd")#&details=Acesse:+#urlEncodedFormat(VARIABLES.eventCardDetailAbsoluteUrl)#&location=#cidade#,+#estado#,+#pais#&trp=false&sprop=&sprop=#urlEncodedFormat(REQUEST.currentBaseUrl & '/name:Road+Runners')#" target="_blank">
                        <i class="fa-brands fa-google"></i> #REQUEST.t("search.eventList.googleCalendar")#
                    </a>

                <!---<cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id>
                    <ul class="dropdown-menu dropdown-menu-dark dropdown-menu-end" aria-labelledby="dropdownMenuButton">
                        <cfif qEventosAba.tipo_checkin EQ "inscricao">
                            <li><a class="dropdown-item" href="/evento/#tag#/?acao=calendario&redirecionar=/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda###tag#">Remover Presença (Agenda Pública)</a></li>
                        <cfelse>
                            <li><a class="dropdown-item" href="/evento/#tag#/?acao=inscricao&redirecionar=/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda###tag#">Marcar Presença (Agenda Pública)</a></li>
                        </cfif>
                        <li><hr class="dropdown-divider m-0" /></li>
                        <li><a class="dropdown-item" href="/evento/#tag#/?acao=remover&redirecionar=/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda">Remover da Agenda</a></li>
                        <li><a class="dropdown-item" href="http://www.google.com/calendar/render?action=TEMPLATE&text=#nome_evento#&dates=#DateFormat(data_inicial,"yyyymmdd")#/#DateFormat(data_final,"yyyymmdd")#&details=Acesse:+https://roadrunners.run/evento/#tag#/&location=#cidade#,+#estado#,+#pais#&trp=false&sprop=&sprop=https://roadrunners.run/name:Road+Runners" target="_blank">Adicionar ao Google Agenda</a></li>
                        <!---<li><span class="dropdown-item opacity-50">Adicionar Cupom</span></li>--->
                    </ul>
                <cfelse>
                    <ul class="dropdown-menu dropdown-menu-dark dropdown-menu-end" aria-labelledby="dropdownMenuButton#tag#">
                        <li><a class="dropdown-item" href="/evento/#tag#/?acao=calendario&redirecionar=/#qPagina.tag_prefix#/#qPagina.tag#/?filtro=agenda">Adicionar à minha agenda</a></li>
                        <!---<li><hr class="dropdown-divider m-0" /></li>--->
                        <!---<li><span class="dropdown-item opacity-50"><i class="fa-solid fa-hand-fist"></i> Desafiar</span></li>--->
                    </ul>
                </cfif>--->

            </div>

            </cfif>

        </cfif>

        <cfif VARIABLES.template EQ "/resultados/" OR VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/inscricao/">

            <!--- RESULTADO DO ATLETA NA PROVA --->

            <cfif isDefined("lista_percursos_resultado") AND isDefined("qCorridasAtleta")>

                <!--- DETALHE DA CORRIDA --->

                <cfif (VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/resultados/") AND isDefined("VARIABLES.tipoListagem") AND VARIABLES.tipoListagem EQ "resultado">

                    <div class="athlete-result-detail">

                        <cfif isDefined("qCorridasAtleta.origem_resultado") AND lCase(trim(qCorridasAtleta.origem_resultado & "")) EQ "validacao_documental">
                            <div class="athlete-result-manual-info">
                                <i class="fa-solid fa-file-circle-check"></i>
                                <div>
                                    <div class="fw-bold">#REQUEST.t("search.eventList.manualResult")#</div>
                                    <div class="small">#REQUEST.t("search.eventList.manualResultDescription")#</div>
                                    <div class="small text-muted mt-1">#REQUEST.t("search.eventList.manualResultNoTime")#</div>
                                </div>
                            </div>
                        <cfelse>

                        <div class="athlete-result-detail-top">
                            <div class="athlete-result-distance-panel">
                                <div class="kms text-center h-100 w-100" data-color="#qCorridasAtleta.percurso#">
                                    <a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">
                                        <span class="distance-value">#qCorridasAtleta.percurso#k</span>
                                        <span class="distance-subtle">#qCorridasAtleta.num_peito# | #qCorridasAtleta.nome_categoria#</span>
                                    </a>
                                </div>
                            </div>

                            <div class="athlete-result-metrics">
                                <div class="kms w-100 h-100" data-color="#qCorridasAtleta.percurso#">
                                    <cfif (VARIABLES.template EQ "/atleta/" OR VARIABLES.template EQ "/resultados/") AND Len(trim(qCorridasAtleta.nome))>
                                        <span class="athlete-result-registered-athlete">
                                            #REQUEST.t("search.eventList.registeredAthlete")#: <strong>#qCorridasAtleta.nome#</strong>
                                        </span>
                                    </cfif>
                                    <div class="athlete-result-metrics-grid">
                                        <div class="athlete-result-metric">
                                            <span class="label">#REQUEST.t("search.eventList.overall")#</span>
                                            <span class="value"><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#qCorridasAtleta.classificacao_sexo#º</a></span>
                                        </div>
                                        <div class="athlete-result-metric">
                                            <span class="label">#REQUEST.t("search.eventList.categoryShort")#</span>
                                            <span class="value"><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo#&categoria=#qCorridasAtleta.nome_categoria####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#qCorridasAtleta.classificacao_categoria#º</a></span>
                                        </div>
                                        <div class="athlete-result-metric">
                                            <span class="label">#REQUEST.t("search.eventList.pace")#</span>
                                            <span class="value"><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#timeFormat(qCorridasAtleta.pace,"mm:ss")#</a></span>
                                        </div>
                                        <div class="athlete-result-metric">
                                            <span class="label">#REQUEST.t("search.eventList.time")#</span>
                                            <span class="value"><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#timeFormat(qCorridasAtleta.tempo_total,"HH:mm:ss")#</a></span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        </cfif>

                    </div>

                <cfelse>

                <div class="card pt-2 rounded-top-0">

                    <div class="row g-2 px-1" style="border-top: solid 1px ##efefef">

                        <cfoutput>

                            <div class="col-12 m-0">
                                <div class="kms text-center w-100 fw-bold " data-color="#qCorridasAtleta.percurso#">
                                    <i class="fa-solid fa-person-running me-1"></i>#qCorridasAtleta.nome#
                                </div>
                            </div>

                            <div class="col-3 m-0 pb-1">
                                <div class="kms text-center lh-sm h-100 w-100" data-color="#qCorridasAtleta.percurso#">
                                    <div><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#REQUEST.t("search.eventList.bib")# #qCorridasAtleta.num_peito#</a></div>
                                    <div><a class="fs-5 fw-bold" href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#qCorridasAtleta.percurso#k</a></div>
                                    <div><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo#&categoria=#qCorridasAtleta.nome_categoria####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#qCorridasAtleta.nome_categoria#</a></div>
                                </div>
                            </div>

                            <div class="col m-0 mb-1 p-0 <cfif Usuario.logado AND qPagina.id_usuario_cadastro NEQ Usuario.id>me-1</cfif> kms" data-color="#qCorridasAtleta.percurso#">
                                <table class="table mb-0 rounded">
                                    <cfoutput>
                                        <tr class="text-center" data-color="#qCorridasAtleta.percurso#">
                                            <th width="" class="px-1 py-2 bg-transparent">#REQUEST.t("search.eventList.overall")#</th>
                                            <th width="" class="px-1 py-2 bg-transparent">#REQUEST.t("search.eventList.categoryShort")#</th>
                                            <th width="" class="px-1 py-2 bg-transparent">#REQUEST.t("search.eventList.pace")#</th>
                                            <th width="" class="px-1 py-2 bg-transparent">#REQUEST.t("search.eventList.time")#</th>
                                        </tr>
                                        <tr class="text-center bg-transparent small">
                                            <td class="py-2 px-1 bg-transparent border-0"><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#qCorridasAtleta.classificacao_sexo#º</a></td>
                                            <td class="py-2 px-1 bg-transparent border-0"><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo#&categoria=#qCorridasAtleta.nome_categoria####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#qCorridasAtleta.classificacao_categoria#º</a></td>
                                            <td class="py-2 px-1 bg-transparent border-0"><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#timeFormat(qCorridasAtleta.pace,"mm:ss")#</a></td>
                                            <td class="py-2 px-1 bg-transparent border-0"><a href="https://openresults.run/evento/#tag#/?modalidade=#qCorridasAtleta.modalidade#&genero=#qCorridasAtleta.sexo####lcase(replace(qCorridasAtleta.nome, ' ', '-', 'ALL'))#">#timeFormat(qCorridasAtleta.tempo_total,"HH:mm:ss")#</a></td>
                                        </tr>
                                    </cfoutput>
                                </table>

                            </div>

                            <!--- FOTOS--->

                            <!---<cfif data_final LTE now() AND (VARIABLES.template EQ "/resultados/" OR VARIABLES.template EQ "/atleta/")>
                                    <div class="col-1 w-50px m-0 me-1 mb-1 p-0 kms" data-color="#qCorridasAtleta.percurso#">
                                        <small><cfoutput>#REQUEST.t("search.eventList.photos")#</cfoutput></small>
                                        <div class="fs-5"><i class="fa-solid fa-camera"></i></div>

                                    <cfif listContains(VARIABLES.permissoes, 'fr_fotos')>
                                        <a href="https://www.focoradical.com.br/busca-numero?type=1&competition_id=#qCorridasAtleta.id_foco_radical#&number=#qCorridasAtleta.num_peito#" target="_blank">
                                            Ver fotos
                                        </a>
                                    </cfif>

                                    </div>
                            </cfif>--->

                            <cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id>

                                <cfset VARIABLES.badgeFoco = ""/>

                                <div class="col-2 m-0 pb-1" >
                                    <div class="w-100 h-100 kms" data-color="#qCorridasAtleta.percurso#">

                                        <cfif Len(badges) AND arraylen(deserializeJSON(badges))>

                                            <cfloop array="#deserializeJSON(badges)#" item="badge">
                                                <cfif badge.badge EQ "foco">
                                                    <cfset VARIABLES.badgeFoco = badge/>
                                                </cfif>
                                            </cfloop>

                                            <cfif isStruct(VARIABLES.badgeFoco)>
                                                    <button type="button" class="btn p-1 w-100 h-100 shadow-0 text-dark"
                                                        data-mdb-valor-badge="#VARIABLES.badgeFoco.valor_badge#"
                                                        data-mdb-numero-peito="#qCorridasAtleta.num_peito#"
                                                        data-mdb-complemento-badge="#isDefined("VARIABLES.badgeFoco.complemento_badge") ? VARIABLES.badgeFoco.complemento_badge : 'numero'#"
                                                        data-mdb-modal-init
                                                        data-mdb-target="##modal_cupom_foco"
                                                        title="#VARIABLES.badgeFoco.valor_badge# | #isDefined("VARIABLES.badgeFoco.complemento_badge") ? VARIABLES.badgeFoco.complemento_badge : 'numero'# #qCorridasAtleta.num_peito#">
                                                    <i class="fa-solid fa-camera fs-2"></i><small class="d-block"><cfoutput>#REQUEST.t("search.eventList.photos")#</cfoutput></small>
                                                </button>

                                            <cfelse>

                                                    <button type="button" class="btn opacity-25 p-1 w-100 h-100 shadow-0 disabled">
                                                        <i class="fa-solid fa-camera fs-2"></i><small class="d-block"><cfoutput>#REQUEST.t("search.eventList.photos")#</cfoutput></small>
                                                    </button>

                                            </cfif>

                                        <cfelse>

                                            <button type="button" class="btn opacity-25 p-1 w-100 h-100 shadow-0 disabled">
                                                <i class="fa-solid fa-camera fs-2"></i><small class="d-block"><cfoutput>#REQUEST.t("search.eventList.photos")#</cfoutput></small>
                                            </button>

                                        </cfif>

                                    </div>
                                </div>

                            </cfif>

                        </cfoutput>

                    </div>

                    <!--- TODO --->

                    <!---div class="card-footer p-0">

                        <cfif Usuario.logado AND qPagina.id_usuario_cadastro EQ Usuario.id>
                            <div class="d-flex btn-group shadow-0">
                                <!--- SALVAR NA AGENDA --->
                                <button type="button" class="btn btn-secondary px-1 rounded-top-0">
                                    <i class="fa-solid fa-medal"></i> Remover
                                </button>
                                <!--- ENVIAR --->
                                <button type="button" class="btn btn-secondary px-1 border-start rounded-top-0" data-mdb-modal-init data-mdb-target="##shareModal">
                                    <i class="fa-solid fa-share"></i> Enviar
                                </button>
                            </div>
                        </cfif>

                    </div--->

                </div>

                </cfif>

            </cfif>

        </cfif>

    <!---<div class="text-secondary p-1">
            <i class="fa-regular fa-thumbs-up p-2"></i>
            <i class="fa-regular fa-calendar p-2"></i>
            <i class="fa-regular fa-paper-plane p-2"></i>
    </div>--->

    </cfoutput>

</div>
