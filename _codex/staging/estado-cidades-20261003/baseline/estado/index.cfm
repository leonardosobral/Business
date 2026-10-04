<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/estado/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfparam name="URL.cidade" default=""/>
<cfset URL.tag = ucase(trim(replace(URL.tag, '/', '')))/>
<cfset VARIABLES.estadoCidadeSlug = lCase(trim(reReplace(URL.cidade, "(^/+)|(/+$)", "", "all")))/>

<!--- VARIAVEIS --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>

 <!--- LOCATION --->
<cfinclude template="../includes/location.cfm"/>

<cfset VARIABLES.estadoUfValidas = "AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO"/>
<cfset VARIABLES.estadoRedirectUf = "SC"/>
<cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND REQUEST.Usuario.logado AND len(trim(REQUEST.Usuario.estado)) AND listFindNoCase(VARIABLES.estadoUfValidas, REQUEST.Usuario.estado)>
    <cfset VARIABLES.estadoRedirectUf = uCase(trim(REQUEST.Usuario.estado))/>
<cfelseif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND REQUEST.Usuario.logado AND len(trim(REQUEST.Usuario.uf)) AND listFindNoCase(VARIABLES.estadoUfValidas, REQUEST.Usuario.uf)>
    <cfset VARIABLES.estadoRedirectUf = uCase(trim(REQUEST.Usuario.uf))/>
<cfelseif len(trim(VARIABLES.uf)) AND listFindNoCase(VARIABLES.estadoUfValidas, VARIABLES.uf)>
    <cfset VARIABLES.estadoRedirectUf = uCase(trim(VARIABLES.uf))/>
</cfif>

<cfif NOT len(trim(URL.tag)) OR NOT listFindNoCase(VARIABLES.estadoUfValidas, URL.tag)>
    <cflocation url="/estado/#lCase(VARIABLES.estadoRedirectUf)#/" addtoken="false"/>
</cfif>

<cfset VARIABLES.estadoRootPath = "/estado/#lCase(URL.tag)#/"/>

<cfscript>
if (!structKeyExists(REQUEST, "formatEstadoCidadeNome")) {
    REQUEST.formatEstadoCidadeNome = function(required string cityName) {
        var connectorWords = "a,ao,aos,as,com,da,das,de,del,do,dos,e,em,na,nas,no,nos,para,por,sem,sob";
        var words = listToArray(trim(arguments.cityName), " ");
        var wordIndex = 0;

        for (wordIndex = 2; wordIndex <= arrayLen(words); wordIndex++) {
            if (listFindNoCase(connectorWords, words[wordIndex])) {
                words[wordIndex] = lCase(words[wordIndex]);
            }
        }

        return arrayToList(words, " ");
    };
}
</cfscript>

<!--- A cidade sempre pertence a UF informada na rota. --->
<cfif len(VARIABLES.estadoCidadeSlug)>
    <cfif find("/", VARIABLES.estadoCidadeSlug) OR reFind("[^a-z0-9-]", VARIABLES.estadoCidadeSlug)>
        <cflocation url="#VARIABLES.estadoRootPath#" addtoken="false"/>
    </cfif>

    <cfquery name="qEstadoCidade" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#" result="qEstadoCidadeMeta">
        WITH cidades_normalizadas AS (
            SELECT
                initcap(lower(trim(cidade))) AS cidade,
                translate(lower(trim(cidade)), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') AS tag_cidade,
                data_final
            FROM tb_evento_corridas
            WHERE upper(trim(estado)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
                AND nullif(trim(cidade), '') IS NOT NULL
        )
        SELECT min(cidade) AS cidade, tag_cidade
        FROM cidades_normalizadas
        WHERE tag_cidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.estadoCidadeSlug#"/>
        GROUP BY tag_cidade
        ORDER BY max(data_final) DESC NULLS LAST, cidade ASC
        LIMIT 1
    </cfquery>
    <cfset logQueryDebug("qEstadoCidade", qEstadoCidadeMeta, "estado/cidade", "5min", qEstadoCidade)/>

    <cfif NOT qEstadoCidade.recordCount>
        <cflocation url="#VARIABLES.estadoRootPath#" addtoken="false"/>
    </cfif>

    <cfset VARIABLES.estadoCidadeNome = REQUEST.formatEstadoCidadeNome(qEstadoCidade.cidade[1])/>
    <cfset URL.cidade = trim(qEstadoCidade.tag_cidade[1])/>
    <cfset VARIABLES.estadoCidadeSlug = trim(qEstadoCidade.tag_cidade[1])/>
</cfif>

<cfquery name="qEstadoCidades" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#" result="qEstadoCidadesMeta">
    WITH cidades_normalizadas AS (
        SELECT
            initcap(lower(trim(cidade))) AS cidade,
            translate(lower(trim(cidade)), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') AS tag_cidade
        FROM tb_evento_corridas
        WHERE upper(trim(estado)) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
            AND nullif(trim(cidade), '') IS NOT NULL
    )
    SELECT min(cidade) AS cidade, tag_cidade, count(*) AS total_eventos
    FROM cidades_normalizadas
    GROUP BY tag_cidade
    ORDER BY total_eventos DESC, cidade ASC
    LIMIT 10
</cfquery>
<cfset logQueryDebug("qEstadoCidades", qEstadoCidadesMeta, "estado/cidades_sidebar", "5min", qEstadoCidades)/>

<!--- BACKEND --->
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/backend_feed.cfm"/>

<!--- META INFO --->
<cfif len(trim(URL.cidade))>
    <cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##lCase(URL.tag)#/#VARIABLES.estadoCidadeSlug#/"/>
    <cfset VARIABLES.title = "Eventos em #VARIABLES.estadoCidadeNome# - #uCase(URL.tag)# - #APPLICATION.nomeSite#"/>
    <cfset VARIABLES.description = "Eventos de corrida de rua ou trail em #VARIABLES.estadoCidadeNome#, #getEstadoNome(URL.tag)#."/>
<cfelse>
    <cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##lCase(URL.tag)##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
    <cfset VARIABLES.title = "Eventos de corrida de rua: #ucase(URL.tag)# - #APPLICATION.nomeSite#"/>
    <cfset VARIABLES.description = "Eventos de corrida de rua ou trail do estado: #ucase(URL.tag)#"/>
</cfif>
<cfset VARIABLES.keywords = "maratona, meia maratona, trail, resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        @media (max-width: 991.98px) {
            .home-mobile-section {
                margin-top: 0.75rem;
            }
        }

        .estado-page-hero-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 0.85rem;
        }

        .estado-page-hero-header .page-section-hero-title {
            min-width: 0;
        }

        .estado-page-hero-state-select {
            flex: 0 0 auto;
        }

        .estado-page-hero-city-select {
            min-width: 0;
        }

        .estado-city-list-card {
            margin-bottom: 0.5rem;
        }

        .estado-city-list-item {
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
            align-items: center;
            gap: 0.6rem;
            color: #333333;
            padding: 0.58rem 0;
            text-decoration: none;
        }

        .estado-city-list-item + .estado-city-list-item {
            border-top: 1px solid rgba(51, 51, 51, 0.08);
        }

        .estado-city-list-item:hover,
        .estado-city-list-item:focus {
            color: #333333;
        }

        .estado-city-list-name {
            font-size: 0.86rem;
            font-weight: 700;
            line-height: 1.2;
            min-width: 0;
        }

        .estado-city-list-count {
            border: 1px solid rgba(51, 51, 51, 0.1);
            border-radius: 999px;
            color: rgba(51, 51, 51, 0.66);
            font-size: 0.67rem;
            font-weight: 700;
            line-height: 1;
            padding: 0.3rem 0.42rem;
            white-space: nowrap;
        }

        .estado-city-list-item:hover .estado-city-list-count,
        .estado-city-list-item:focus .estado-city-list-count {
            border-color: #fab120;
            color: #333333;
        }

        @media (max-width: 991.98px) {
            .estado-page-hero-header {
                align-items: flex-start;
                flex-wrap: wrap;
            }

            .estado-page-hero-city-select {
                flex: 1 0 100%;
                width: 100%;
            }

            .estado-page-hero-city-select .home-hero-chip-select {
                width: 100%;
            }
        }

        @media (max-width: 767.98px) {
            .estado-page-hero-header {
                align-items: flex-start;
                flex-direction: column;
            }
        }
    </style>


    <!--- CONTAINER DE CONTEUDO --->

    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <div class="page-section-hero">
            <cfset VARIABLES.estadoHeroUfSelecionada = len(trim(URL.tag)) ? uCase(trim(URL.tag)) : (structKeyExists(VARIABLES, "heroEstadoSelecionado") ? VARIABLES.heroEstadoSelecionado : "SC")/>
            <cfset VARIABLES.estadoHeroTituloUf = VARIABLES.estadoHeroUfSelecionada/>
            <cfif qEventos.recordCount GT 0 AND len(trim(qEventos.estado[1] & ""))>
                <cfset VARIABLES.estadoHeroTituloUf = uCase(trim(qEventos.estado[1] & ""))/>
            </cfif>
            <cfset VARIABLES.estadoHeroStatePathTemplate = isDefined("VARIABLES.heroStatePathTemplate") ? VARIABLES.heroStatePathTemplate : REQUEST.currentBaseUrl & "/estado/{tag}/"/>
            <cfset VARIABLES.estadoHeroStateOptions = structKeyExists(VARIABLES, "heroStateOptions") ? VARIABLES.heroStateOptions : "AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO"/>
            <cfif structKeyExists(VARIABLES, "heroStatePrepositions")>
                <cfset VARIABLES.estadoHeroStatePrepositions = VARIABLES.heroStatePrepositions/>
            <cfelse>
                <cfset VARIABLES.estadoHeroStatePrepositions = {
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
            </cfif>
            <div class="estado-page-hero-header">
                <h1 class="page-section-hero-title">
                    <svg class="page-section-hero-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 768 767.999994" preserveAspectRatio="xMidYMid meet" version="1.0" aria-hidden="true"><path fill="#f4b120" d="M 217.46875 764.9375 C 209.929688 764.9375 204.402344 762.171875 200.878906 756.648438 C 197.367188 751.136719 196.113281 744.105469 197.121094 735.5625 L 298.066406 17.609375 C 299.0625 10.574219 300.566406 6.308594 302.578125 4.808594 C 304.59375 3.296875 309.109844 2.542969 316.132812 2.542969 L 386.199219 2.542969 C 391.722656 2.542969 396.238281 4.550781 399.75 8.566406 C 403.261719 12.582031 404.519531 16.847656 403.527344 21.367188 L 300.316406 755.914062 C 299.8125 759.925781 298.804688 762.429688 297.292969 763.429688 C 295.792969 764.433594 292.535156 764.9375 287.515625 764.9375 Z M 217.46875 764.9375 " fill-opacity="1" fill-rule="nonzero"/><path fill="#f4b120" d="M 401.449219 764.9375 C 393.910156 764.9375 388.382812 762.171875 384.859375 756.648438 C 381.351562 751.136719 380.097656 744.105469 381.101562 735.5625 L 482.050781 17.609375 C 483.042969 10.574219 484.546875 6.308594 486.5625 4.808594 C 488.574219 3.296875 493.089844 2.542969 500.113281 2.542969 L 570.179688 2.542969 C 575.703125 2.542969 580.21875 4.550781 583.734375 8.566406 C 587.242188 12.582031 588.5 16.847656 587.507812 21.367188 L 484.296875 755.914062 C 483.792969 759.925781 482.785156 762.429688 481.277344 763.429688 C 479.777344 764.433594 476.519531 764.9375 471.5 764.9375 Z M 401.449219 764.9375 " fill-opacity="1" fill-rule="nonzero"/></svg>
                    <span class="page-section-hero-text"><cfoutput><cfif len(trim(URL.cidade))>Eventos em #HTMLEditFormat(VARIABLES.estadoCidadeNome)# - #VARIABLES.estadoHeroTituloUf#<cfelse>Eventos #VARIABLES.estadoHeroStatePrepositions[VARIABLES.estadoHeroTituloUf]# #getEstadoNome(VARIABLES.estadoHeroTituloUf)#</cfif></cfoutput></span>
                </h1>
                <div class="home-hero-chip-select-wrap estado-page-hero-state-select">
                    <i class="fa-solid fa-location-dot home-hero-chip-select-icon"></i>
                    <select class="home-hero-chip home-hero-chip-select"
                            aria-label="<cfoutput>#HTMLEditFormat(REQUEST.t("search.hero.stateSelectAria"))#</cfoutput>"
                            onchange="if(this.value){window.location.assign('<cfoutput>#JSStringFormat(VARIABLES.estadoHeroStatePathTemplate)#</cfoutput>'.replace('{tag}', encodeURIComponent(String(this.value).trim().toLowerCase())));}">
                        <cfoutput>
                            <cfloop list="#VARIABLES.estadoHeroStateOptions#" index="estadoHeroUfOption">
                                <option value="#estadoHeroUfOption#" <cfif VARIABLES.estadoHeroUfSelecionada EQ estadoHeroUfOption>selected</cfif>>Eventos #VARIABLES.estadoHeroStatePrepositions[estadoHeroUfOption]# #getEstadoNome(estadoHeroUfOption)#</option>
                            </cfloop>
                        </cfoutput>
                    </select>
                    <i class="fa-solid fa-chevron-down home-hero-chip-select-caret"></i>
                </div>
                <cfif qEstadoCidades.recordCount>
                    <div class="home-hero-chip-select-wrap estado-page-hero-city-select d-lg-none">
                        <i class="fa-solid fa-city home-hero-chip-select-icon"></i>
                        <select class="home-hero-chip home-hero-chip-select"
                                aria-label="Selecione uma cidade"
                                onchange="if(this.value){window.location.assign(this.value);}">
                            <cfoutput>
                                <option value="" disabled<cfif NOT len(trim(URL.cidade))> selected</cfif>>Cidades #VARIABLES.estadoHeroStatePrepositions[VARIABLES.estadoHeroUfSelecionada]# #getEstadoNome(VARIABLES.estadoHeroUfSelecionada)#</option>
                                <cfloop query="qEstadoCidades">
                                    <option value="/estado/#lCase(URL.tag)#/#tag_cidade#/"<cfif len(trim(URL.cidade)) AND URL.cidade EQ tag_cidade> selected</cfif>>#HTMLEditFormat(REQUEST.formatEstadoCidadeNome(cidade))# - #lsNumberFormat(total_eventos)# <cfif total_eventos EQ 1>evento<cfelse>eventos</cfif></option>
                                </cfloop>
                            </cfoutput>
                        </select>
                        <i class="fa-solid fa-chevron-down home-hero-chip-select-caret"></i>
                    </div>
                </cfif>
            </div>
        </div>


        <!--- LISTAGEM DE EVENTOS --->

    <div class="row g-2">

    <div class="d-none d-lg-block col-lg-3 col-xl-3 order-lg-1 home-mobile-section">

    <cfinclude template="../includes/estrutura/home_sidebar_async_slot.cfm"/>

    </div>

    <!--- LISTA DE EVENTOS DE CORRIDA --->

        <div class="col-12 col-md-8 col-lg-6 col-xl-6 px-lg-3 order-1 order-md-2">


                <!--- DESTAQUE --->
                <!---<div class="text-divider">Destaque</div>--->
                <!---<cfinclude template="../includes/eventos_destaque.cfm"/>--->

                <cfset VARIABLES.qEventosAba = qEventos/>


                <!--- SELACAO DE ESTADOS E SLIDES DE DISTANCIA E TEMPO --->

                <cfinclude template="../includes/filtros.cfm"/>

                <!--- LEGENDA DO SLIDE --->

                <!---<div class="col-12 mt-1 mb-0 p-0">
                    <div class="small text-center p-0"><span id="multi-ranges-legenda"></span></div>
                </div>--->


                <!--- LISTAGEM DE EVENTOS --->

                <div id="container-proximas" class="col-lg-12">

                    <div id="scroll-container-proximas">

                        <cfinclude template="../includes/eventos_ads.cfm"/>

                        <cfinclude template="../includes/lista_de_eventos_simple.cfm"/>

                    </div>

                    <div id="spinner-proximas" class="spinner-border mx-auto" style="display: none"></div>

                </div>

            </div>


            <!--- BARRA LATERAL --->

            <div class="d-none d-lg-block col-lg-3 order-3 home-mobile-section">

               <cfif qEstadoCidades.recordCount>
                   <div class="home-side-block p-3 estado-city-list-card">
                       <div class="home-side-title mb-2"><i class="fa-solid fa-location-dot" aria-hidden="true"></i><cfoutput>Cidades #VARIABLES.estadoHeroStatePrepositions[VARIABLES.estadoHeroUfSelecionada]# #getEstadoNome(VARIABLES.estadoHeroUfSelecionada)#</cfoutput></div>
                       <cfoutput query="qEstadoCidades">
                           <a href="/estado/#lCase(URL.tag)#/#tag_cidade#/" class="estado-city-list-item">
                               <span class="estado-city-list-name">#HTMLEditFormat(REQUEST.formatEstadoCidadeNome(cidade))#</span>
                               <span class="estado-city-list-count">#lsNumberFormat(total_eventos)# <cfif total_eventos EQ 1>evento<cfelse>eventos</cfif></span>
                           </a>
                       </cfoutput>
                   </div>
               </cfif>

               <cfinclude template="../includes/estrutura/conteudo_lateral_api.cfm"/>

            </div>

        </div>

        </main>

    </div>


    <!--- MODAL DO MAPA --->

    <!---cfinclude template="../includes/modal/modal_mapa.cfm"/--->


    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL DO MAPA --->

    <!---cfinclude template="includes/modal/modal_mapa.cfm"/--->


    <!--- MODAL DE BADGES --->

    <cfinclude template="../includes/modal/modal_badges.cfm"/>


    <!--- MODAL DE YOUTUBE --->

    <cfinclude template="../includes/modal/modal_youtube.cfm"/>


    <!--- MODAL FOCO --->

    <cfinclude template="../includes/modal/modal_cupom_foco.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL SEGUIDORES / SEGUINDO --->

    <cfinclude template="../includes/modal/modal_seguidores.cfm"/>


    <!--- MODAL PAGAMENTO --->

    <cfinclude template="../includes/modal/modal_pagamento.cfm"/>


    <!--- MODAL LOGIN --->

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


    <script src="/assets/js/runnerhub-event-filters.js?version=2026-05-07"></script>
    <script>
        window.RunnerHubEstadoFiltersBootstrap = {
            distanciaSelecionada: [<cfoutput>#URL.distancia#</cfoutput>],
            periodoMesesSelecionado: [<cfoutput>#URL.tempo#</cfoutput>],
            badges: '<cfoutput>#encodeForJavaScript(URL.badges)#</cfoutput>',
            rua: <cfif URL.rua>true<cfelse>false</cfif>,
            trail: <cfif URL.trail>true<cfelse>false</cfif>,
            nacional: <cfif URL.nacional>true<cfelse>false</cfif>,
            internacional: <cfif URL.internacional>true<cfelse>false</cfif>,
            tag: '<cfoutput>#encodeForJavaScript(URL.tag)#</cfoutput>',
            buscaCidade: '<cfoutput>#encodeForJavaScript(URL.cidade)#</cfoutput>',
            cupom: <cfif URL.cupom>true<cfelse>false</cfif>,
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
        };

        window.totalEventos = <cfoutput>#qEventos.recordcount#</cfoutput>;

        window.RunnerHubEstadoFiltersController = window.RunnerHubEventFilters.init({
            eventosEndpoint: '/api/eventos.cfm',
            useLegacyRangeParams: true,
            distanciaSelecionada: window.RunnerHubEstadoFiltersBootstrap.distanciaSelecionada,
            periodoMesesSelecionado: window.RunnerHubEstadoFiltersBootstrap.periodoMesesSelecionado,
            badges: window.RunnerHubEstadoFiltersBootstrap.badges,
            rua: window.RunnerHubEstadoFiltersBootstrap.rua,
            trail: window.RunnerHubEstadoFiltersBootstrap.trail,
            nacional: window.RunnerHubEstadoFiltersBootstrap.nacional,
            internacional: window.RunnerHubEstadoFiltersBootstrap.internacional,
            tag: window.RunnerHubEstadoFiltersBootstrap.tag,
            buscaCidade: window.RunnerHubEstadoFiltersBootstrap.buscaCidade,
            cupom: window.RunnerHubEstadoFiltersBootstrap.cupom,
            pagesize: window.RunnerHubEstadoFiltersBootstrap.pagesize,
            lastWeek: window.RunnerHubEstadoFiltersBootstrap.lastWeek,
            lastMonth: window.RunnerHubEstadoFiltersBootstrap.lastMonth,
            totalEventos: window.RunnerHubEstadoFiltersBootstrap.totalEventos,
            selectors: window.RunnerHubEstadoFiltersBootstrap.selectors
        });
    </script>

</body>

</html>
