<!--- NORMALIZA O TIPO DE RESULTADO ATIVO NA BUSCA --->
<cfparam name="URL.busca_tipo" default="todos"/>
<cfset VARIABLES.buscaTipoAtual = listFindNoCase("todos,eventos,resultados,atletas,noticias,videos", trim(URL.busca_tipo)) ? lCase(trim(URL.busca_tipo)) : "todos"/>
<cfset VARIABLES.buscaSearchPath = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("search") : "/busca/"/>

<!--- LIBERA DEBUG TECNICO APENAS PARA ADMINISTRADORES LOGADOS --->
<cfset VARIABLES.buscaDebugAdmin = structKeyExists(REQUEST, "Usuario")
    AND isObject(REQUEST.Usuario)
    AND REQUEST.Usuario.logado
    AND (
        isBoolean(REQUEST.Usuario.is_admin)
            ? javacast("boolean", REQUEST.Usuario.is_admin)
            : listFindNoCase("1,true,yes,sim,s", trim(REQUEST.Usuario.is_admin & "")) GT 0
    )/>

<!--- MOSTRA FILTROS SOMENTE PARA TIPOS QUE CONSULTAM EVENTOS OU RESULTADOS --->
<cfif NOT listFindNoCase("atletas,noticias,videos", VARIABLES.buscaTipoAtual)>
    <div id="busca-filtros-panel">
        <cfinclude template="../includes/filtros.cfm"/>
    </div>
</cfif>

<!--- EXIBE COMO A IA INTERPRETOU A BUSCA E OS DADOS TECNICOS QUANDO PERMITIDO --->
<div class="home-feedback-card p-3 mb-2 mt-2" id="busca-debug-card" <cfif NOT isDefined("REQUEST.buscaInteligente")>style="display:none;"</cfif>>
        <div class="fw-bold mb-1"><cfoutput>#REQUEST.t("search.debug.title")#</cfoutput></div>
        <div class="small mb-2" id="busca-feedback-message"><cfif isDefined("REQUEST.buscaInteligente")><cfoutput>#HTMLEditFormat(REQUEST.buscaInteligente.message)#</cfoutput></cfif></div>
        <cfif VARIABLES.buscaDebugAdmin>
        <details id="busca-debug-details">
            <summary class="small fw-bold" style="cursor:pointer;"><cfoutput>#REQUEST.t("search.debug.technicalDebug")#</cfoutput></summary>
            <div class="pt-2" id="busca-debug-content">
                <div class="fw-bold mb-1"><cfoutput>#REQUEST.t("search.debug.filtersInterpreted")#</cfoutput></div>
                <cfif isDefined("REQUEST.buscaInteligente")>
                    <cfset VARIABLES.buscaJsonDebug = serializeJSON(REQUEST.buscaInteligente.filtersApi)/>
                <cfelse>
                    <cfset VARIABLES.buscaJsonDebug = "">
                </cfif>
                <pre class="small mb-2" id="busca-debug-json" style="white-space: pre-wrap; word-break: break-word;"><cfoutput>#HTMLEditFormat(VARIABLES.buscaJsonDebug)#</cfoutput></pre>
                <div class="small mb-2" id="busca-debug-modelo"><cfif isDefined("REQUEST.buscaInteligente")><cfoutput>#REQUEST.t("search.debug.modelLabel")#: #HTMLEditFormat(REQUEST.buscaInteligente.model)#</cfoutput></cfif></div>
                <div class="small text-muted" id="busca-debug-status">
                    <cfif isDefined("REQUEST.buscaInteligente") AND REQUEST.buscaInteligente.mode EQ "plain">
                        <cfoutput>#REQUEST.t("search.debug.plainStatus")#</cfoutput>
                    <cfelseif isDefined("REQUEST.buscaInteligente") AND REQUEST.buscaInteligente.usedAi>
                        <cfoutput>#REQUEST.t("search.debug.aiValidatedStatus")#</cfoutput>
                    <cfelseif isDefined("REQUEST.buscaInteligente") AND REQUEST.buscaInteligente.aiConfigured>
                        <cfoutput>#REQUEST.t("search.debug.fallbackStatus", { "reason" = REQUEST.t(
                            REQUEST.buscaInteligente.fallbackReason EQ "timeout" ? "search.debug.fallbackReasons.timeout" :
                            REQUEST.buscaInteligente.fallbackReason EQ "http_error" ? "search.debug.fallbackReasons.http_error" :
                            REQUEST.buscaInteligente.fallbackReason EQ "empty_response" ? "search.debug.fallbackReasons.empty_response" :
                            REQUEST.buscaInteligente.fallbackReason EQ "invalid_json" ? "search.debug.fallbackReasons.invalid_json" :
                            REQUEST.buscaInteligente.fallbackReason EQ "connection_error" ? "search.debug.fallbackReasons.connection_error" :
                            REQUEST.buscaInteligente.fallbackReason EQ "not_configured" ? "search.debug.fallbackReasons.not_configured" :
                            "search.debug.fallbackReasons.unknown"
                        ) })#</cfoutput>
                    <cfelseif isDefined("REQUEST.buscaInteligente")>
                        <cfoutput>#REQUEST.t("search.debug.notConfiguredStatus")#</cfoutput>
                    </cfif>
                </div>
                <cfif isDefined("REQUEST.buscaInteligente") AND REQUEST.buscaInteligente.ignoredFreeTerm>
                    <div class="small text-muted mt-1" id="busca-debug-ignored"><cfoutput>#REQUEST.t("search.debug.ignoredTerm")#</cfoutput></div>
                </cfif>
                <cfif isDefined("REQUEST.buscaInteligente") AND len(trim(REQUEST.buscaInteligente.error))>
                    <div class="small text-muted mt-1" id="busca-debug-error"><cfoutput>#REQUEST.t("search.debug.technicalDetail", { "detail" = REQUEST.buscaInteligente.error })#</cfoutput></div>
                </cfif>
                <cfif VARIABLES.devMode>
                    <cfif isDefined("REQUEST.buscaInteligente") AND structKeyExists(REQUEST.buscaInteligente, "debug") AND isStruct(REQUEST.buscaInteligente.debug)>
                        <cfset VARIABLES.buscaDebugRaw = serializeJSON(REQUEST.buscaInteligente.debug)/>
                        <cfset VARIABLES.buscaShowRaw = NOT (
                            structKeyExists(REQUEST.buscaInteligente.debug, "httpStatus")
                            AND left(trim(REQUEST.buscaInteligente.debug.httpStatus), 3) EQ "200"
                        )/>
                    <cfelse>
                        <cfset VARIABLES.buscaDebugRaw = "">
                        <cfset VARIABLES.buscaShowRaw = false/>
                    </cfif>
                    <div class="small mt-2" id="busca-debug-http-status"></div>
                    <div class="small mt-1" id="busca-debug-endpoint"></div>
                    <cfif isDefined("REQUEST.buscaInteligente") AND structKeyExists(REQUEST.buscaInteligente, "debug") AND isStruct(REQUEST.buscaInteligente.debug) AND structKeyExists(REQUEST.buscaInteligente.debug, "eventSearch")>
                        <div class="fw-bold mt-3 mb-1"><cfoutput>#REQUEST.t("search.debug.eventQuery")#</cfoutput></div>
                        <pre class="small mb-2" id="busca-debug-event-query" style="white-space: pre-wrap; word-break: break-word;"><cfoutput>#HTMLEditFormat(REQUEST.buscaInteligente.debug.eventSearch.sql)#</cfoutput></pre>
                        <div class="fw-bold mb-1"><cfoutput>#REQUEST.t("search.debug.eventQueryParams")#</cfoutput></div>
                        <pre class="small mb-2" id="busca-debug-event-params" style="white-space: pre-wrap; word-break: break-word;"><cfoutput>#HTMLEditFormat(serializeJSON(REQUEST.buscaInteligente.debug.eventSearch.params))#</cfoutput></pre>
                    <cfelse>
                        <pre class="small mb-2" id="busca-debug-event-query" style="display:none;"></pre>
                        <pre class="small mb-2" id="busca-debug-event-params" style="display:none;"></pre>
                    </cfif>
                    <pre class="small mt-2 mb-0" id="busca-debug-raw" style="white-space: pre-wrap; word-break: break-word;<cfif NOT VARIABLES.buscaShowRaw>display:none;</cfif>"><cfoutput>#HTMLEditFormat(VARIABLES.buscaDebugRaw)#</cfoutput></pre>
                </cfif>
            </div>
        </details>
        </cfif>
</div>

<!--- CARD DE LOADING ENQUANTO A FRASE ESTA SENDO INTERPRETADA PELA IA --->
<div class="home-feedback-card busca-loading-card p-3 mb-2 mt-2" id="busca-ai-loading-card" style="display:none;">
    <div class="fw-bold mb-1 busca-loading-title" id="busca-ai-loading-title"><cfoutput>#REQUEST.t("search.loading.aiTitle")#</cfoutput></div>
    <div class="small text-muted busca-loading-copy" id="busca-ai-loading-copy"><cfoutput>#REQUEST.i18n.search.loading.aiSteps[1]#</cfoutput></div>
</div>

<!--- CARD DE LOADING ENQUANTO OS RESULTADOS SAO BUSCADOS COM OS FILTROS DA IA --->
<div class="home-feedback-card busca-loading-card p-3 mb-2 mt-2" id="busca-results-loading-card" style="display:none;">
    <div class="fw-bold mb-1 busca-loading-title" id="busca-results-loading-title"><cfoutput>#REQUEST.t("search.loading.resultsTitleAi")#</cfoutput></div>
    <div class="small text-muted busca-loading-copy" id="busca-results-loading-copy"><cfoutput>#REQUEST.i18n.search.loading.resultsStepsAi[1]#</cfoutput></div>
</div>

<!---
<cfset VARIABLES.adMockSlotName = "search-events-native-top" />
<cfset VARIABLES.adMockFormat = "Native card | Desktop inline | Mobile inline" />
<cfset VARIABLES.adMockContext = "Slot de alta intencao para patrocinio de prova no topo do bloco principal da busca." />
<cfset VARIABLES.adMockClassName = "mb-2 mt-2" />
<cfset VARIABLES.adMockBadge = "Slot de anuncio" />
<cfinclude template="../includes/estrutura/ad_slot_mock.cfm"/>
--->

<!---cfif isDefined("REQUEST.buscaInteligente")>
    <div class="page-section-hero" id="busca-hero">
        <div class="page-section-hero-kicker"><cfif REQUEST.buscaInteligente.mode EQ "plain">Busca comum<cfelse>Busca inteligente</cfif></div>
        <h1 class="page-section-hero-title">
            <svg class="page-section-hero-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 768 767.999994" preserveAspectRatio="xMidYMid meet" version="1.0" aria-hidden="true"><path fill="#f4b120" d="M 217.46875 764.9375 C 209.929688 764.9375 204.402344 762.171875 200.878906 756.648438 C 197.367188 751.136719 196.113281 744.105469 197.121094 735.5625 L 298.066406 17.609375 C 299.0625 10.574219 300.566406 6.308594 302.578125 4.808594 C 304.59375 3.296875 309.109375 2.542969 316.132812 2.542969 L 386.199219 2.542969 C 391.722656 2.542969 396.238281 4.550781 399.75 8.566406 C 403.261719 12.582031 404.519531 16.847656 403.527344 21.367188 L 300.316406 755.914062 C 299.8125 759.925781 298.804688 762.429688 297.292969 763.429688 C 295.792969 764.433594 292.535156 764.9375 287.515625 764.9375 Z M 217.46875 764.9375 " fill-opacity="1" fill-rule="nonzero"/><path fill="#f4b120" d="M 401.449219 764.9375 C 393.910156 764.9375 388.382812 762.171875 384.859375 756.648438 C 381.351562 751.136719 380.097656 744.105469 381.101562 735.5625 L 482.050781 17.609375 C 483.042969 10.574219 484.546875 6.308594 486.5625 4.808594 C 488.574219 3.296875 493.089844 2.542969 500.113281 2.542969 L 570.179688 2.542969 C 575.703125 2.542969 580.21875 4.550781 583.734375 8.566406 C 587.242188 12.582031 588.5 16.847656 587.507812 21.367188 L 484.296875 755.914062 C 483.792969 759.925781 482.785156 762.429688 481.277344 763.429688 C 479.777344 764.433594 476.519531 764.9375 471.5 764.9375 Z M 401.449219 764.9375 " fill-opacity="1" fill-rule="nonzero"/></svg>
            <span class="page-section-hero-text">Resultado da busca</span>
        </h1>
        <p class="page-section-hero-copy" id="busca-hero-copy"><cfoutput>Mostrando eventos para “#HTMLEditFormat(REQUEST.buscaInteligente.termoOriginal)#”.</cfoutput></p>
    </div>
<cfelse>
    <h1 class="h4">
        <cfif isDefined('qEventos.estado')>
            <svg class="align-bottom mb-1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="22" zoomAndPan="magnify" viewBox="0 0 768 767.999994" height="22" preserveAspectRatio="xMidYMid meet" version="1.0"><path fill="#f4b120" d="M 217.46875 764.9375 C 209.929688 764.9375 204.402344 762.171875 200.878906 756.648438 C 197.367188 751.136719 196.113281 744.105469 197.121094 735.5625 L 298.066406 17.609375 C 299.0625 10.574219 300.566406 6.308594 302.578125 4.808594 C 304.59375 3.296875 309.109375 2.542969 316.132812 2.542969 L 386.199219 2.542969 C 391.722656 2.542969 396.238281 4.550781 399.75 8.566406 C 403.261719 12.582031 404.519531 16.847656 403.527344 21.367188 L 300.316406 755.914062 C 299.8125 759.925781 298.804688 762.429688 297.292969 763.429688 C 295.792969 764.433594 292.535156 764.9375 287.515625 764.9375 Z M 217.46875 764.9375 " fill-opacity="1" fill-rule="nonzero"/><path fill="#f4b120" d="M 401.449219 764.9375 C 393.910156 764.9375 388.382812 762.171875 384.859375 756.648438 C 381.351562 751.136719 380.097656 744.105469 381.101562 735.5625 L 482.050781 17.609375 C 483.042969 10.574219 484.546875 6.308594 486.5625 4.808594 C 488.574219 3.296875 493.089844 2.542969 500.113281 2.542969 L 570.179688 2.542969 C 575.703125 2.542969 580.21875 4.550781 583.734375 8.566406 C 587.242188 12.582031 588.5 16.847656 587.507812 21.367188 L 484.296875 755.914062 C 483.792969 759.925781 482.785156 762.429688 481.277344 763.429688 C 479.777344 764.433594 476.519531 764.9375 471.5 764.9375 Z M 401.449219 764.9375 " fill-opacity="1" fill-rule="nonzero"/></svg>
            <a href="/estado/<cfoutput>#LCase(qEventos.estado)#</cfoutput>"><cfoutput>#getEstadoNome(qEventos.estado)#</cfoutput></a>
        <cfelse>
            Explore o calendário nacional e use os filtros para encontrar a prova certa para sua próxima temporada.
        </cfif>
    </h1>
</cfif--->

<!--- SKELETON EXIBIDO DURANTE O CARREGAMENTO ASSINCRONO DAS SECOES --->
<div id="busca-results-skeleton" class="busca-skeleton-stack mt-2" style="display:none;">
    <div class="busca-skeleton-card">
        <div class="busca-skeleton-line is-short"></div>
        <div class="busca-skeleton-line is-long"></div>
        <div class="busca-skeleton-line is-medium"></div>
        <div class="busca-skeleton-line is-long"></div>
    </div>
    <div class="busca-skeleton-card">
        <div class="busca-skeleton-line is-medium"></div>
        <div class="busca-skeleton-line is-long"></div>
        <div class="busca-skeleton-line is-short"></div>
        <div class="busca-skeleton-line is-medium"></div>
    </div>
    <div class="busca-skeleton-card">
        <div class="busca-skeleton-line is-short"></div>
        <div class="busca-skeleton-line is-long"></div>
        <div class="busca-skeleton-line is-long"></div>
    </div>
</div>

<!--- CALCULA CONTADORES INICIAIS E LINKS DAS ABAS DE RESULTADO --->
<cfset VARIABLES.buscaTermoLink = isDefined("VARIABLES.termoBuscaDisplay") ? VARIABLES.termoBuscaDisplay : (isDefined("REQUEST.buscaTermo") ? REQUEST.buscaTermo : "")/>
<cfset VARIABLES.buscaModeLink = isDefined("REQUEST.buscaInteligente") ? REQUEST.buscaInteligente.mode : URL.busca_mode/>
<cfset VARIABLES.buscaTabBaseUrl = "#VARIABLES.buscaSearchPath#?busca=#URLEncodedFormat(VARIABLES.buscaTermoLink)#&busca_mode=#URLEncodedFormat(VARIABLES.buscaModeLink)#"/>
<cfset VARIABLES.buscaEventosCount = isDefined("qEventosAba") ? qEventosAba.recordcount : (isDefined("qEventos") ? qEventos.recordcount : 0)/>
<cfset VARIABLES.buscaResultadosCount = isDefined("qEventosResultadosAba") ? qEventosResultadosAba.recordcount : 0/>
<cfset VARIABLES.buscaAtletasCount = isDefined("qAtletasAba") ? qAtletasAba.recordcount : 0/>
<cfset VARIABLES.buscaNoticiasCount = isDefined("qNoticiasAba") AND isArray(qNoticiasAba) ? arrayLen(qNoticiasAba) : 0/>
<cfset VARIABLES.buscaVideosCount = isDefined("qVideosAba") ? qVideosAba.recordcount : 0/>
<cfset VARIABLES.buscaTodosCount = VARIABLES.buscaEventosCount + VARIABLES.buscaResultadosCount + VARIABLES.buscaAtletasCount + VARIABLES.buscaNoticiasCount + VARIABLES.buscaVideosCount/>
<cfset VARIABLES.buscaRenderAsync = isDefined("REQUEST.buscaAsync") AND REQUEST.buscaAsync/>
<cfset VARIABLES.buscaShowTabs = len(trim(VARIABLES.buscaTermoLink)) OR (isDefined("VARIABLES.template") AND VARIABLES.template EQ "/busca/")/>

<!--- RENDERIZA ABAS DE TIPOS DE RESULTADO COM CONTADORES --->
<cfif VARIABLES.buscaShowTabs>
    <style>
        .busca-tabs-shell {
            margin: 0.65rem 0 0.85rem;
        }

        .busca-tabs-compact .nav-link {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.45rem;
            min-height: 3rem;
        }

        .busca-tabs-compact {
            min-width: 100%;
        }

        .busca-tabs-compact .nav-link i {
            font-size: 1.08rem;
            color: #333333;
        }

        .busca-tabs-label {
            position: absolute;
            width: 1px;
            height: 1px;
            padding: 0;
            margin: -1px;
            overflow: hidden;
            clip: rect(0, 0, 0, 0);
            white-space: nowrap;
            border: 0;
        }

        .busca-tabs-count {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-width: 1.9rem;
            padding: 0.28rem 0.55rem;
            border-radius: 999px;
            background: #fab120;
            color: #333333;
            font-size: 0.92rem;
            font-weight: 800;
            line-height: 1;
        }

        .busca-tabs-compact .nav-link.is-zero,
        .busca-tabs-compact .nav-link.is-zero.active,
        .busca-tabs-compact .nav-link.is-zero:hover,
        .busca-tabs-compact .nav-link.is-zero:focus {
            background-color: #efefef;
            border-color: rgba(51, 51, 51, 0.08) !important;
            box-shadow: none;
        }

        .busca-tabs-compact .nav-link.is-zero .busca-tabs-count {
            background: #d9d9d9;
            color: #666666;
        }

        @media (max-width: 767.98px) {
            .busca-tabs-shell {
                margin-top: 0.55rem;
            }

            .busca-tabs-compact {
                display: grid !important;
                grid-template-columns: repeat(6, minmax(0, 1fr)) !important;
                gap: 0.22rem;
                width: 100% !important;
                min-width: 100% !important;
                max-width: 100% !important;
                padding-bottom: 0;
            }

            .busca-tabs-compact .nav-link {
                gap: 0.18rem;
                min-height: 2.35rem;
                min-width: 0;
                padding-left: 0.18rem !important;
                padding-right: 0.18rem !important;
                padding-top: 0.45rem !important;
                padding-bottom: 0.45rem !important;
            }

            .busca-tabs-compact .nav-link i {
                font-size: 0.86rem;
            }

            .busca-tabs-count {
                min-width: 1.15rem;
                padding: 0.16rem 0.2rem;
                font-size: 0.68rem;
            }
        }
    </style>
    <div class="busca-tabs-shell">
        <div class="nav nav-tabs athlete-tabs border-0 busca-tabs-compact" role="tablist" style="grid-template-columns: repeat(6, minmax(0, 1fr));">
            <a class="nav-link px-2 <cfif VARIABLES.buscaTipoAtual EQ 'todos'>active</cfif><cfif VARIABLES.buscaTodosCount EQ 0> is-zero</cfif>" href="##" data-busca-results-tab="todos">
                <i class="fa-solid fa-layer-group"></i>
                <span class="busca-tabs-label"><cfoutput>#REQUEST.t("search.form.types.todos")#</cfoutput></span>
                <span class="busca-tabs-count" data-busca-count="todos"><cfoutput>#VARIABLES.buscaTodosCount#</cfoutput></span>
            </a>
            <a class="nav-link px-2 <cfif VARIABLES.buscaTipoAtual EQ 'eventos'>active</cfif><cfif VARIABLES.buscaEventosCount EQ 0> is-zero</cfif>" href="##" data-busca-results-tab="eventos">
                <i class="fa-solid fa-calendar-check"></i>
                <span class="busca-tabs-label"><cfoutput>#REQUEST.t("search.form.types.eventos")#</cfoutput></span>
                <span class="busca-tabs-count" data-busca-count="eventos"><cfoutput>#VARIABLES.buscaEventosCount#</cfoutput></span>
            </a>
            <a class="nav-link px-2 <cfif VARIABLES.buscaTipoAtual EQ 'resultados'>active</cfif><cfif VARIABLES.buscaResultadosCount EQ 0> is-zero</cfif>" href="##" data-busca-results-tab="resultados">
                <i class="fa-solid fa-medal"></i>
                <span class="busca-tabs-label"><cfoutput>#REQUEST.t("search.form.types.resultados")#</cfoutput></span>
                <span class="busca-tabs-count" data-busca-count="resultados"><cfoutput>#VARIABLES.buscaResultadosCount#</cfoutput></span>
            </a>
            <a class="nav-link px-2 <cfif VARIABLES.buscaTipoAtual EQ 'atletas'>active</cfif><cfif VARIABLES.buscaAtletasCount EQ 0> is-zero</cfif>" href="##" data-busca-results-tab="atletas">
                <i class="fa-solid fa-user"></i>
                <span class="busca-tabs-label"><cfoutput>#REQUEST.t("search.form.types.atletas")#</cfoutput></span>
                <span class="busca-tabs-count" data-busca-count="atletas"><cfoutput>#VARIABLES.buscaAtletasCount#</cfoutput></span>
            </a>
            <a class="nav-link px-2 <cfif VARIABLES.buscaTipoAtual EQ 'noticias'>active</cfif><cfif VARIABLES.buscaNoticiasCount EQ 0> is-zero</cfif>" href="##" data-busca-results-tab="noticias">
                <i class="fa-solid fa-newspaper"></i>
                <span class="busca-tabs-label"><cfoutput>#REQUEST.t("search.form.types.noticias")#</cfoutput></span>
                <span class="busca-tabs-count" data-busca-count="noticias"><cfoutput>#VARIABLES.buscaNoticiasCount#</cfoutput></span>
            </a>
            <a class="nav-link px-2 <cfif VARIABLES.buscaTipoAtual EQ 'videos'>active</cfif><cfif VARIABLES.buscaVideosCount EQ 0> is-zero</cfif>" href="##" data-busca-results-tab="videos">
                <i class="fa-brands fa-youtube"></i>
                <span class="busca-tabs-label"><cfoutput>#REQUEST.t("search.form.types.videos")#</cfoutput></span>
                <span class="busca-tabs-count" data-busca-count="videos"><cfoutput>#VARIABLES.buscaVideosCount#</cfoutput></span>
            </a>
        </div>
    </div>
</cfif>

<!--- AGRUPA TODAS AS SECOES QUE O JAVASCRIPT VAI PREENCHER OU REORDENAR --->
<div id="container-proximas" class="col-lg-12" data-busca-current-type="<cfoutput>#HTMLEditFormat(VARIABLES.buscaTipoAtual)#</cfoutput>">
    <!--- MENSAGEM INICIAL QUANDO A PAGINA AINDA NAO TEM TERMO DE BUSCA --->
    <div id="busca-empty-state" class="home-feedback-card p-3" <cfif len(trim(VARIABLES.buscaTermoLink))>style="display:none;"</cfif>>
        <cfoutput>#REQUEST.t("search.sections.emptyPrompt")#</cfoutput>
    </div>

    <!--- SECAO DE EVENTOS FUTUROS --->
    <div class="busca-result-section" id="busca-eventos-section" data-busca-section="eventos" <cfif listFindNoCase("resultados,atletas,noticias,videos", VARIABLES.buscaTipoAtual)>style="display:none;"</cfif>>
        <div class="d-flex align-items-center justify-content-between mt-2 mb-1">
            <h2 class="h6 mb-0"><cfoutput>#REQUEST.t("search.sections.titles.eventos")#</cfoutput></h2>
            <a class="small fw-bold" data-busca-view-all="eventos" <cfif VARIABLES.buscaEventosCount EQ 0>style="display:none;"</cfif> href="<cfoutput>#VARIABLES.buscaTabBaseUrl#&busca_tipo=eventos</cfoutput>"><cfoutput>#REQUEST.t("search.tabs.viewAll")#</cfoutput></a>
        </div>
        <div id="scroll-container-proximas"></div>
    </div>

    <!--- SECAO DE RESULTADOS DE PROVAS JA REALIZADAS --->
    <div class="busca-result-section" id="busca-resultados-section" data-busca-section="resultados" <cfif listFindNoCase("eventos,atletas,noticias,videos", VARIABLES.buscaTipoAtual)>style="display:none;"</cfif>>
        <div class="d-flex align-items-center justify-content-between mt-3 mb-1">
            <h2 class="h6 mb-0"><cfoutput>#REQUEST.t("search.sections.titles.resultados")#</cfoutput></h2>
            <a class="small fw-bold" data-busca-view-all="resultados" <cfif VARIABLES.buscaResultadosCount EQ 0>style="display:none;"</cfif> href="<cfoutput>#VARIABLES.buscaTabBaseUrl#&busca_tipo=resultados</cfoutput>"><cfoutput>#REQUEST.t("search.tabs.viewAll")#</cfoutput></a>
        </div>
        <div id="busca-resultados-results"></div>
    </div>

    <!--- SECAO DE ATLETAS ENCONTRADOS PELO TERMO --->
    <div class="busca-result-section" id="busca-atletas-section" data-busca-section="atletas" <cfif listFindNoCase("eventos,resultados,noticias,videos", VARIABLES.buscaTipoAtual)>style="display:none;"</cfif>>
        <div class="d-flex align-items-center justify-content-between mt-3 mb-1">
            <h2 class="h6 mb-0"><cfoutput>#REQUEST.t("search.sections.titles.atletas")#</cfoutput></h2>
            <a class="small fw-bold" data-busca-view-all="atletas" <cfif VARIABLES.buscaAtletasCount EQ 0>style="display:none;"</cfif> href="<cfoutput>#VARIABLES.buscaTabBaseUrl#&busca_tipo=atletas</cfoutput>"><cfoutput>#REQUEST.t("search.tabs.viewAll")#</cfoutput></a>
        </div>
        <div id="busca-atletas-results"></div>
    </div>

    <!--- SECAO DE NOTICIAS DO CMS RELACIONADAS AO TERMO --->
    <div class="busca-result-section" id="busca-noticias-section" data-busca-section="noticias" <cfif listFindNoCase("eventos,resultados,atletas,videos", VARIABLES.buscaTipoAtual)>style="display:none;"</cfif>>
        <div class="d-flex align-items-center justify-content-between mt-3 mb-1">
            <h2 class="h6 mb-0"><cfoutput>#REQUEST.t("search.sections.titles.noticias")#</cfoutput></h2>
            <a class="small fw-bold" data-busca-view-all="noticias" <cfif VARIABLES.buscaNoticiasCount EQ 0>style="display:none;"</cfif> href="<cfoutput>#VARIABLES.buscaTabBaseUrl#&busca_tipo=noticias</cfoutput>"><cfoutput>#REQUEST.t("search.tabs.viewAll")#</cfoutput></a>
        </div>
        <div id="busca-noticias-results"></div>
    </div>

    <!--- SECAO DE VIDEOS RELACIONADOS AO TERMO --->
    <div class="busca-result-section" id="busca-videos-section" data-busca-section="videos" <cfif listFindNoCase("eventos,resultados,atletas,noticias", VARIABLES.buscaTipoAtual)>style="display:none;"</cfif>>
        <div class="d-flex align-items-center justify-content-between mt-3 mb-1">
            <h2 class="h6 mb-0"><cfoutput>#REQUEST.t("search.sections.titles.videos")#</cfoutput></h2>
            <a class="small fw-bold" data-busca-view-all="videos" <cfif VARIABLES.buscaVideosCount EQ 0>style="display:none;"</cfif> href="<cfoutput>#VARIABLES.buscaTabBaseUrl#&busca_tipo=videos</cfoutput>"><cfoutput>#REQUEST.t("search.tabs.viewAll")#</cfoutput></a>
        </div>
        <div id="busca-videos-results"></div>
    </div>

    <!--- ESTADOS FINAIS DE VAZIO E LOADING USADOS PELO JAVASCRIPT --->
    <div id="busca-no-results" class="home-feedback-card p-3 mt-2" style="display:none;"><cfoutput>#REQUEST.t("search.sections.noResults")#</cfoutput></div>
    <div id="spinner-proximas" class="spinner-border mx-auto" style="display: none"></div>
</div>
