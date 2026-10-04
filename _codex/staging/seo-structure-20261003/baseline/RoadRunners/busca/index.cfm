<!doctype html>
<html lang="<cfoutput>#structKeyExists(REQUEST, 'htmlLang') ? REQUEST.htmlLang : 'pt-BR'#</cfoutput>">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- IDENTIFICA A ROTA ATUAL PARA INCLUDES COMPARTILHADOS --->
<cfset VARIABLES.template = "/busca/"/>
<cfset VARIABLES.routeKey = "search"/>

<!--- NORMALIZA A TAG RECEBIDA POR URL PARA FILTROS LEGADOS --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = ucase(trim(replace(URL.tag, '/', '')))/>

<!--- DEFINE TODOS OS PARAMETROS QUE A BUSCA PODE RECEBER POR GET OU FORM --->
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.termo" default=""/>
<cfparam name="URL.distancia_inicio" default=""/>
<cfparam name="URL.distancia_fim" default=""/>
<cfparam name="URL.distancia" default="1,42"/>
<cfparam name="URL.tempo" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>
<cfparam name="URL.estados" default=""/>
<cfparam name="URL.context_uf" default=""/>
<cfparam name="URL.periodo_inicio" default=""/>
<cfparam name="URL.periodo_fim" default=""/>
<cfparam name="URL.busca_mode" default="ai"/>
<cfparam name="URL.busca_tipo" default="todos"/>
<cfparam name="FORM.busca" default=""/>
<cfparam name="FORM.termo" default=""/>
<cfset VARIABLES.termoBuscaDisplay = ""/>
<cfset VARIABLES.localizedSearchPath = structKeyExists(REQUEST, "i18nBuildPath") ? REQUEST.i18nBuildPath("search") : "/busca/"/>

<!--- MANTEM COMPATIBILIDADE ENTRE LINKS ANTIGOS E O NOVO CAMPO DE BUSCA
    - ?busca=... preenche o campo e executa a busca via GET
    - ?termo=...&redirect=1 promove o termo para FORM e executa a busca
--->
<cfif isDefined("URL.redirect")>
    <cfset FORM.busca = len(trim(URL.busca)) ? URL.busca : URL.termo/>
<cfelseif NOT len(trim(FORM.busca)) AND NOT len(trim(FORM.termo)) AND len(trim(URL.termo))>
    <cfset FORM.busca = URL.termo/>
</cfif>

<cfif NOT len(trim(FORM.busca)) AND len(trim(FORM.termo))>
    <cfset FORM.busca = FORM.termo/>
</cfif>

<cfif len(trim(FORM.busca))>
    <cfset VARIABLES.termoBuscaDisplay = FORM.busca/>
<cfelseif len(trim(URL.busca))>
    <cfset VARIABLES.termoBuscaDisplay = URL.busca/>
<cfelseif len(trim(URL.termo))>
    <cfset VARIABLES.termoBuscaDisplay = URL.termo/>
</cfif>

<!--- CARREGA TRADUCOES, ROTAS E CONFIGURACOES COMPARTILHADAS --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/location.cfm"/>
<cfscript>
// LINKS SEM TEXTO ABREM O CALENDARIO, COM A MESMA PRIORIDADE REGIONAL DA HOME.
URL.busca_tipo = listFindNoCase("todos,eventos,resultados,atletas,noticias,videos", trim(URL.busca_tipo))
    ? lCase(trim(URL.busca_tipo)) : "todos";
VARIABLES.buscaCalendar = !len(trim(VARIABLES.termoBuscaDisplay)) && listFindNoCase("todos,eventos", URL.busca_tipo);
if (VARIABLES.buscaCalendar) {
    URL.busca_tipo = "eventos";
    VARIABLES.calendarStates = "AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO";
    VARIABLES.calendarContextUf = uCase(trim(URL.context_uf));
    VARIABLES.calendarInternationalOnly = isDefined("URL.internacional") && isBoolean(URL.internacional) && URL.internacional
        && isDefined("URL.nacional") && isBoolean(URL.nacional) && !URL.nacional;
    if (!len(trim(URL.estado)) && !len(trim(URL.estados)) && !len(trim(URL.cidade)) && !VARIABLES.calendarInternationalOnly) {
        if (VARIABLES.calendarContextUf EQ "BR") {
            // BR EXPLICITO CONTINUA A LISTA NACIONAL, INCLUSIVE O FALLBACK DA HOME.
        } else if (listFindNoCase(VARIABLES.calendarStates, VARIABLES.calendarContextUf)) {
            URL.estado = VARIABLES.calendarContextUf;
        } else if (structKeyExists(REQUEST, "Usuario") && REQUEST.Usuario.logado
            && listFindNoCase(VARIABLES.calendarStates, trim(REQUEST.Usuario.estado))) {
            URL.estado = uCase(trim(REQUEST.Usuario.estado));
        } else if (isDefined("VARIABLES.uf") && listFindNoCase(VARIABLES.calendarStates, trim(VARIABLES.uf))) {
            URL.estado = uCase(trim(VARIABLES.uf));
        }
    }
}

// CONVERTE DISTANCIA DA URL PARA O RANGE INICIAL DOS FILTROS
if (len(trim(URL.distancia_inicio)) || len(trim(URL.distancia_fim))) {
    VARIABLES.distanciaInicial = [
        len(trim(URL.distancia_inicio)) ? val(URL.distancia_inicio) : 1,
        len(trim(URL.distancia_fim)) ? val(URL.distancia_fim) : 42
    ];
} else {
    VARIABLES.distanciaInicial = len(trim(URL.distancia)) ? listToArray(URL.distancia) : [1, 42];
}

// CONVERTE PERIODO ABSOLUTO EM MESES PARA COMPATIBILIDADE COM O SLIDER
function monthsUntilDateForBusca(required string dateValue) {
    var targetDate = parseDateTime(arguments.dateValue);
    var diffMonths = dateDiff("m", now(), targetDate);
    return diffMonths LT 0 ? 0 : diffMonths;
}

// DEFINE O RANGE INICIAL DE TEMPO USADO NA INTERFACE DE FILTROS
if (len(trim(URL.periodo_inicio)) || len(trim(URL.periodo_fim))) {
    VARIABLES.tempoInicial = [
        len(trim(URL.periodo_inicio)) ? monthsUntilDateForBusca(URL.periodo_inicio) : 0,
        len(trim(URL.periodo_fim)) ? monthsUntilDateForBusca(URL.periodo_fim) : 12
    ];
} else {
    VARIABLES.tempoInicial = len(trim(URL.tempo)) ? listToArray(URL.tempo) : [0, 12];
}

// O RANGE VISUAL 0,12 TAMBEM PODE SER UM LIMITE EXPLICITO VINDO DA HOME.
if (VARIABLES.buscaCalendar && len(trim(URL.tempo)) && !len(trim(URL.periodo_inicio)) && !len(trim(URL.periodo_fim))) {
    URL.periodo_inicio = dateFormat(dateAdd("d", val(listFirst(URL.tempo)) * 30, now()), "yyyy-mm-dd");
    URL.periodo_fim = dateFormat(dateAdd("d", val(listLast(URL.tempo)) * 30, now()), "yyyy-mm-dd");
}
</cfscript>
<!--- NORMALIZA FILTROS BOOLEANOS QUE PODEM CHEGAR COMO TEXTO --->
<cfset VARIABLES.ruaInicial = isBoolean(URL.rua) ? javacast("boolean", URL.rua) : javacast("boolean", compareNoCase(trim(URL.rua), "true") EQ 0)/>
<cfset VARIABLES.trailInicial = isBoolean(URL.trail) ? javacast("boolean", URL.trail) : javacast("boolean", compareNoCase(trim(URL.trail), "true") EQ 0)/>
<cfset VARIABLES.nacionalInicial = isBoolean(URL.nacional) ? javacast("boolean", URL.nacional) : javacast("boolean", compareNoCase(trim(URL.nacional), "true") EQ 0)/>
<cfset VARIABLES.internacionalInicial = isBoolean(URL.internacional) ? javacast("boolean", URL.internacional) : javacast("boolean", compareNoCase(trim(URL.internacional), "true") EQ 0)/>
<cfset VARIABLES.cupomInicial = isBoolean(URL.cupom) ? javacast("boolean", URL.cupom) : javacast("boolean", compareNoCase(trim(URL.cupom), "true") EQ 0)/>

<!--- CARREGA BACKENDS COMPARTILHADOS E EVITA BUSCA SINCRONA QUANDO O TERMO SERA PROCESSADO VIA AJAX --->
<cfset REQUEST.buscaTermo = VARIABLES.termoBuscaDisplay/>
<cfset REQUEST.buscaAsync = len(trim(VARIABLES.termoBuscaDisplay)) GT 0/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/backend_feed.cfm"/>
<cfif REQUEST.buscaAsync>
    <cfset qEventos = queryNew("week,month")/>
    <cfset qEventosAba = qEventos/>
    <cfset qEventosResultadosAba = queryNew("week,month")/>
    <cfset qAtletasAba = queryNew("id_pagina,nome,tag_prefix,tag,imagem_usuario,verificado,is_admin,seguidores,cidade,uf")/>
    <cfset qNoticiasAba = []/>
    <cfset qVideosAba = queryNew("id_media,media_titulo,media_url,data_publicacao,nome_canal_video")/>
<cfelseif NOT isDefined("qEventos")>
    <cfset qEventos = queryNew("week,month")/>
</cfif>
<cfif NOT isDefined("qEventosAba")>
    <cfset qEventosAba = qEventos/>
</cfif>
<cfif NOT isDefined("qEventosResultadosAba")>
    <cfset qEventosResultadosAba = queryNew("week,month")/>
</cfif>
<cfif NOT isDefined("qAtletasAba")>
    <cfset qAtletasAba = queryNew("id_pagina,nome,tag_prefix,tag,imagem_usuario,verificado,is_admin,seguidores,cidade,uf")/>
</cfif>
<cfif NOT isDefined("qNoticiasAba")>
    <cfset qNoticiasAba = []/>
</cfif>
<cfif NOT isDefined("qVideosAba")>
    <cfset qVideosAba = queryNew("id_media,media_titulo,media_url,data_publicacao,nome_canal_video")/>
</cfif>

<!--- MONTA METADADOS SEO DA PAGINA DE BUSCA --->
<cfset VARIABLES.canonical = REQUEST.currentBaseUrl & VARIABLES.localizedSearchPath/>
<cfif len(trim(VARIABLES.termoBuscaDisplay))>
    <cfset VARIABLES.title = REQUEST.t("search.meta.titleWithTerm", { "term" = VARIABLES.termoBuscaDisplay })/>
    <cfset VARIABLES.description = REQUEST.t("search.meta.descriptionWithTerm", { "term" = VARIABLES.termoBuscaDisplay })/>
<cfelse>
    <cfset VARIABLES.title = REQUEST.t("search.meta.titleDefault")/>
    <cfset VARIABLES.description = REQUEST.t("search.meta.descriptionDefault")/>
</cfif>
<cfset VARIABLES.keywords = REQUEST.t("search.meta.keywords")/>

<!--- RENDERIZA O HEAD COMPARTILHADO --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .home-shell-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            color: #333333;
        }

        .home-feedback-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #efefef;
            color: #333333;
        }

        .athlete-tabs-shell {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            padding: 0.55rem;
            margin: 0.65rem 0 0.85rem;
            overflow-x: auto;
        }

        .athlete-tabs {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 0.5rem;
            min-width: 100%;
            border-bottom: 0;
        }

        .athlete-tabs .nav-link {
            height: 100%;
            border: 1px solid rgba(51, 51, 51, 0.08) !important;
            border-radius: 8px !important;
            background-color: #efefef;
            color: #333333;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 0.3rem;
            padding: 0.8rem 0.6rem;
            text-align: center;
            transition: border-color .18s ease, background-color .18s ease, color .18s ease;
            margin: 0 !important;
        }

        .athlete-tabs .nav-link i {
            color: #fab120;
            font-size: 1rem;
        }

        .athlete-tabs .nav-link .small {
            color: #333333;
            font-weight: 700;
            line-height: 1.25;
        }

        .athlete-tabs .nav-link.active,
        .athlete-tabs .nav-link:hover,
        .athlete-tabs .nav-link:focus {
            border-color: rgba(250, 177, 32, 0.95) !important;
            background-color: #ffffff;
            color: #333333;
        }

        .athlete-tabs .nav-link.active {
            box-shadow: inset 0 0 0 1px rgba(250, 177, 32, 0.18);
        }

        .athlete-tabs .badge.badge-warning {
            background-color: #fab120 !important;
            color: #333333 !important;
            box-shadow: none;
        }

        @media (max-width: 991.98px) {
            .home-mobile-section {
                margin-top: 0.75rem;
            }
        }

        @media (max-width: 767.98px) {
            .athlete-tabs-shell {
                padding: 0.45rem;
            }

            .athlete-tabs {
                min-width: 100%;
            }

            .athlete-tabs .nav-link {
                min-height: 72px;
                padding: 0.7rem 0.5rem;
            }
        }
    </style>


    <!--- CONTAINER PRINCIPAL DA BUSCA --->

    <div class="container">


        <!--- TOPO GLOBAL E CAMPO PRINCIPAL DE BUSCA --->

        <cfinclude template="../includes/estrutura/header.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>


        <!--- ORGANIZA PERFIL, RESULTADOS DA BUSCA E CONTEUDO LATERAL --->

        <div class="row g-2">

            <div class="d-none d-lg-block col-lg-3 col-xl-3 order-lg-1 home-mobile-section">
                <cfset VARIABLES.homeSidebarAsyncFooter = "0"/>
                <cfinclude template="../includes/estrutura/home_sidebar_async_slot.cfm"/>
            </div>

            <!--- REGISTRA O TERMO BUSCADO PARA AUDITORIA DE USO --->

            <cfif len(trim(VARIABLES.termoBuscaDisplay))>
                <cfquery>
                    INSERT INTO tb_log
                    (log_item, log_item_id, log_user, site)
                    VALUES
                    (
                        <cfif isDefined("URL.redirect")>
                            'busca-redirect',
                        <cfelse>
                            'busca-termo',
                        </cfif>
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.termoBuscaDisplay#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#APPLICATION.codSite#"/>
                    )
                </cfquery>
            </cfif>

            <div class="col-12 col-md-8 col-lg-6 col-xl-6 px-lg-3 order-1 order-md-2">
                <cfinclude template="../includes/busca_home.cfm"/>
            </div>

            <!--- BARRA LATERAL DE CONTEUDO EDITORIAL E RODAPE --->

            <div class="d-none d-lg-block col-lg-3 order-3 home-mobile-section">
                <cfinclude template="../includes/estrutura/conteudo_lateral_api.cfm"/>
                <div class="mt-2">
                    <cfinclude template="../includes/estrutura/side_footer.cfm"/>
                </div>
            </div>

        </div>

        </main>

    </div>


    <!--- RODAPE GLOBAL --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL DO MAPA --->

    <!---cfinclude template="includes/modal/modal_mapa.cfm"/--->


    <!--- MODAIS USADOS PELOS CARDS E ACOES DA BUSCA --->

    <cfinclude template="../includes/modal/modal_badges.cfm"/>


    <cfinclude template="../includes/modal/modal_youtube.cfm"/>

    <cfinclude template="../includes/modal/modal_cupom_foco.cfm"/>

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>

    <cfinclude template="../includes/modal/modal_seguidores.cfm"/>

    <cfinclude template="../includes/modal/modal_pagamento.cfm"/>

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>


    <!--- BUSCA POR MAPA

    <script>

        // REFERENCIA AO MAPA

        let map;

        // INICIALIZA O MAPA

        async function initMap() {

            // centro do mapa
            const center = { lat: -15.793889, lng: -47.882778 };

            // Request needed libraries.
            //@ts-ignore
            const { Map } = await google.maps.importLibrary("maps");
            const { AdvancedMarkerView } = await google.maps.importLibrary("marker");

            // cria o mapa
            map = new google.maps.Map(document.getElementById("map"), {
                zoom: 5,
                center,
                mapId: "4504f8b37365c3d0",
            });

            // cria os pontos do mapa
            for (const property of properties) {
                const advancedMarkerView = new google.maps.marker.AdvancedMarkerView({
                  map,
                  content: buildContent(property),
                  position: property.position,
                  title: property.description,
                });
                const element = advancedMarkerView.element;

                ["focus", "pointerenter"].forEach((event) => {
                  element.addEventListener(event, () => {
                    highlight(advancedMarkerView, property);
                  });
                });
                ["blur", "pointerleave"].forEach((event) => {
                  element.addEventListener(event, () => {
                    unhighlight(advancedMarkerView, property);
                  });
                });
                advancedMarkerView.addListener("click", (event) => {
                  unhighlight(advancedMarkerView, property);
                });
            }

        }

        // MOSTRA E REMOVE O LOCAL

        function highlight(markerView, property) {
          markerView.content.classList.add("highlightmap");
          markerView.element.style.zIndex = 1;
        }

        function unhighlight(markerView, property) {
          markerView.content.classList.remove("highlightmap");
          markerView.element.style.zIndex = "";
        }

        // POPUP DO LOCAL

        function buildContent(property) {
          const content = document.createElement("div");

          content.classList.add("property");
          content.innerHTML = `
            <div class="icon">
                <i aria-hidden="true" class="fa fa-icon fa-${property.type}" title="${property.type}"></i>
                <span class="fa-sr-only">${property.type}</span>
            </div>
            <div class="details">
                <div class="price">${property.evento}</div>
                <div class="address">${property.address}</div>
                <div class="features">
                <div>
                    <i aria-hidden="true" class="fa fa-bed fa-lg bed" title="bedroom"></i>
                    <span class="fa-sr-only">bedroom</span>
                    <span>${property.bed}</span>
                </div>
                <div>
                    <i aria-hidden="true" class="fa fa-bath fa-lg bath" title="bathroom"></i>
                    <span class="fa-sr-only">bathroom</span>
                    <span>${property.bath}</span>
                </div>
                <div>
                    <i aria-hidden="true" class="fa fa-ruler fa-lg size" title="size"></i>
                    <span class="fa-sr-only">size</span>
                    <span>${property.size} ft<sup>2</sup></span>
                </div>
                </div>
            </div>
            `;
          return content;
        }

        // LISTA DE CORRIDAS

        const properties = [
            <cfloop query="qEventosDestaque">
                <cfif len(trim(qEventosDestaque.coordenadas))>
                    <cfset VARIABLES.coordenadas = listToArray(qEventosDestaque.coordenadas)/>
                    {
                    address: "<cfoutput>#qEventosDestaque.cidade#</cfoutput>",
                    description: "<cfoutput>#qEventosDestaque.cidade#</cfoutput>",
                    evento: "<cfoutput>#qEventosDestaque.nome_evento#</cfoutput>",
                    type: "person-running",
                    bed: 5,
                    bath: 4.5,
                    size: 300,
                    position: {
                      lat: <cfoutput>#trim(VARIABLES.coordenadas[1])#</cfoutput>,
                      lng: <cfoutput>#trim(VARIABLES.coordenadas[2])#</cfoutput>,
                    },
                    },
                </cfif>
            </cfloop>
        ];

    </script>

     --->


    <script src="/assets/js/runnerhub-event-filters.js?version=2026-09-11-1"></script>
    <script src="/assets/js/runnerhub-busca-page.js?version=2026-09-12-1"></script>

    <script>
        // ENTREGA AO FRONT O ESTADO INICIAL DA BUSCA E DOS FILTROS
        window.RunnerHubBuscaBootstrap = {
            i18n: <cfoutput>#serializeJSON(REQUEST.i18n.search)#</cfoutput>,
            language: '<cfoutput>#encodeForJavaScript(REQUEST.lang)#</cfoutput>',
            filters: {
                distanciaSelecionada: [<cfoutput>#val(VARIABLES.distanciaInicial[1])#, #val(VARIABLES.distanciaInicial[2])#</cfoutput>],
                periodoMesesSelecionado: [<cfoutput>#val(VARIABLES.tempoInicial[1])#, #val(VARIABLES.tempoInicial[2])#</cfoutput>],
                badges: '<cfoutput>#encodeForJavaScript(URL.badges)#</cfoutput>',
                rua: <cfif VARIABLES.ruaInicial>true<cfelse>false</cfif>,
                trail: <cfif VARIABLES.trailInicial>true<cfelse>false</cfif>,
                nacional: <cfif VARIABLES.nacionalInicial>true<cfelse>false</cfif>,
                internacional: <cfif VARIABLES.internacionalInicial>true<cfelse>false</cfif>,
                tag: '<cfoutput>#encodeForJavaScript(URL.tag)#</cfoutput>',
                cupom: <cfif VARIABLES.cupomInicial>true<cfelse>false</cfif>,
                buscaTermo: '<cfoutput>#encodeForJavaScript(VARIABLES.termoBuscaDisplay)#</cfoutput>',
                buscaApiTermo: '<cfif isDefined("REQUEST.buscaInteligente") AND structKeyExists(REQUEST.buscaInteligente, "filters") AND len(trim(REQUEST.buscaInteligente.filters.termo_livre))><cfoutput>#encodeForJavaScript(REQUEST.buscaInteligente.filters.termo_livre)#</cfoutput><cfelseif isDefined("REQUEST.buscaInteligente") AND REQUEST.buscaInteligente.mode EQ "plain"><cfoutput>#encodeForJavaScript(VARIABLES.termoBuscaDisplay)#</cfoutput><cfelse></cfif>',
                buscaDistanciaInicio: <cfif len(trim(URL.distancia_inicio))><cfoutput>#val(URL.distancia_inicio)#</cfoutput><cfelseif len(trim(URL.distancia_fim))>null<cfelse><cfoutput>#val(VARIABLES.distanciaInicial[1])#</cfoutput></cfif>,
                buscaDistanciaFim: <cfif len(trim(URL.distancia_fim))><cfoutput>#val(URL.distancia_fim)#</cfoutput><cfelseif len(trim(URL.distancia_inicio))>null<cfelse><cfoutput>#val(VARIABLES.distanciaInicial[2])#</cfoutput></cfif>,
                buscaDistanciaAtiva: <cfif len(trim(URL.distancia_inicio)) OR len(trim(URL.distancia_fim)) OR (val(VARIABLES.distanciaInicial[1]) NEQ 1 OR val(VARIABLES.distanciaInicial[2]) NEQ 42) OR (isDefined("REQUEST.buscaInteligente") AND structKeyExists(REQUEST.buscaInteligente, "filters") AND (isNumeric(REQUEST.buscaInteligente.filters.distancia_inicio) OR isNumeric(REQUEST.buscaInteligente.filters.distancia_fim)))>true<cfelse>false</cfif>,
                buscaEstado: '<cfoutput>#encodeForJavaScript(URL.estado)#</cfoutput>',
                buscaCidade: '<cfoutput>#encodeForJavaScript(URL.cidade)#</cfoutput>',
                buscaEstados: '<cfoutput>#encodeForJavaScript(URL.estados)#</cfoutput>',
                buscaPeriodoInicio: '<cfoutput>#encodeForJavaScript(URL.periodo_inicio)#</cfoutput>',
                buscaPeriodoFim: '<cfoutput>#encodeForJavaScript(URL.periodo_fim)#</cfoutput>',
                buscaModo: '<cfif isDefined("REQUEST.buscaInteligente")><cfoutput>#encodeForJavaScript(REQUEST.buscaInteligente.mode)#</cfoutput><cfelse><cfoutput>#encodeForJavaScript(URL.busca_mode)#</cfoutput></cfif>' || 'plain',
                buscaTipo: '<cfoutput>#encodeForJavaScript(URL.busca_tipo)#</cfoutput>',
                buscaTipoTermo: '<cfif isDefined("REQUEST.buscaInteligente") AND structKeyExists(REQUEST.buscaInteligente, "filters") AND structKeyExists(REQUEST.buscaInteligente.filters, "tipo_termo")><cfoutput>#encodeForJavaScript(REQUEST.buscaInteligente.filters.tipo_termo)#</cfoutput><cfelse>indefinido</cfif>',
                pagesize: <cfoutput>#VARIABLES.pageSize#</cfoutput>,
                lastWeek: <cfif qEventos.recordcount EQ 0>''<cfelseif qEventos.recordcount LT VARIABLES.pageSize><cfoutput>'#encodeForJavaScript(qEventos.week[qEventos.recordcount])#'</cfoutput><cfelse><cfoutput>'#encodeForJavaScript(qEventos.week[VARIABLES.pageSize])#'</cfoutput></cfif>,
                lastMonth: <cfif qEventos.recordcount EQ 0>''<cfelseif qEventos.recordcount LT VARIABLES.pageSize><cfoutput>'#encodeForJavaScript(qEventos.month[qEventos.recordcount])#'</cfoutput><cfelse><cfoutput>'#encodeForJavaScript(qEventos.month[VARIABLES.pageSize])#'</cfoutput></cfif>,
                totalEventos: <cfoutput>#qEventos.recordcount#</cfoutput>,
                selectors: {
                    rangeDistancia: '#multi-ranges-distancia',
                    rangeTempo: '#multi-ranges-tempo',
                    filtroFull: '#filtroFull',
                    spinner: '#spinner-proximas',
                    scrollContainer: '#scroll-container-proximas',
                    stateFilterSelect: '#state-filter-select',
                    stateFilterChips: '[data-state-chip]'
                }
            },
            aiModel: '<cfoutput>#encodeForJavaScript(structKeyExists(APPLICATION, "aiSearch") && structKeyExists(APPLICATION.aiSearch, "model") ? APPLICATION.aiSearch.model : "")#</cfoutput>'
        };

        // INICIALIZA CONTROLLERS DE FILTROS E DA BUSCA ASSINCRONA
        window.totalEventos = <cfoutput>#qEventos.recordcount#</cfoutput>;

        window.RunnerHubBuscaFiltersController = window.RunnerHubEventFilters.init(window.RunnerHubBuscaBootstrap.filters);
        window.RunnerHubBuscaPage.init({
            filtersController: window.RunnerHubBuscaFiltersController,
            aiModel: window.RunnerHubBuscaBootstrap.aiModel,
            i18n: window.RunnerHubBuscaBootstrap.i18n,
            language: window.RunnerHubBuscaBootstrap.language,
            searchEndpoint: '/api/search.cfm',
            scrollContainer: document.getElementById('scroll-container-proximas'),
            spinner: document.getElementById('spinner-proximas'),
            selectors: {
                form: '#busca-form-main',
                buscaPlainInputId: 'busca-input-plain',
                buscaAiInputId: 'busca-input-ai',
                buscaPlainWrapperId: 'busca-input-plain-wrapper',
                buscaAiWrapperId: 'busca-input-ai-wrapper',
                buscaModeButtons: '[data-busca-mode]',
                buscaDebugCardId: 'busca-debug-card',
                buscaDebugDetailsId: 'busca-debug-details',
                buscaFeedbackMessageId: 'busca-feedback-message',
                buscaHeroCopyId: 'busca-hero-copy',
                buscaDebugJsonId: 'busca-debug-json',
                buscaDebugModeloId: 'busca-debug-modelo',
                buscaDebugStatusId: 'busca-debug-status',
                buscaDebugIgnoredId: 'busca-debug-ignored',
                buscaDebugErrorId: 'busca-debug-error',
                buscaDebugHttpStatusId: 'busca-debug-http-status',
                buscaDebugEndpointId: 'busca-debug-endpoint',
                buscaDebugEventQueryId: 'busca-debug-event-query',
                buscaDebugEventParamsId: 'busca-debug-event-params',
                buscaDebugRawId: 'busca-debug-raw',
                buscaAiLoadingCardId: 'busca-ai-loading-card',
                buscaAiLoadingTitleId: 'busca-ai-loading-title',
                buscaAiLoadingCopyId: 'busca-ai-loading-copy',
                buscaResultsLoadingCardId: 'busca-results-loading-card',
                buscaResultsLoadingTitleId: 'busca-results-loading-title',
                buscaResultsLoadingCopyId: 'busca-results-loading-copy',
                buscaResultsSkeletonId: 'busca-results-skeleton'
            }
        });
    </script>

</body>

</html>
