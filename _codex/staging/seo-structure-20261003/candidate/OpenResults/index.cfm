<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- BACKEND --->
<cfinclude template="includes/variaveis.cfm"/>
<cfinclude template="includes/location.cfm"/>
<cfinclude template="includes/backend.cfm"/>

<cfquery name="qTotalResultados" cachedwithin="#CreateTimeSpan(0, 0, 15, 0)#">
    SELECT count(*)::int as total
    FROM tb_resultados
    WHERE origem_resultado <> 'validacao_documental'
</cfquery>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "#APPLICATION.nomeSite# - Todas os Resultados de Corridas do Brasil"/>
<cfset VARIABLES.description = "#APPLICATION.nomeSite# é uma plataforma completa e confiável que reúne informações sobre todas as corridas de rua que acontecem no país."/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="includes/head.cfm"/>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="includes/seo-web-tools-body-start.cfm"/>

    <style>
        body {
            background: radial-gradient(circle at top, rgba(238, 238, 238, 1) 0%, rgba(250, 250, 250, 1) 100%);
            background-repeat: no-repeat;
            min-height: 100vh;
        }

        #busca {
            padding-top: 7rem !important;
            padding-bottom: 7rem !important;
        }

        @media only screen and (max-width: 600px) {
            #busca {
                padding-top: 1rem !important;
                padding-bottom: 1rem !important;
            }

            .home-search-logo,
            .home-search-intro {
                display: none;
            }

            #busca .home-search-icon {
                display: inline-block;
            }
        }

        .home-search-heading {
            font-size: 1rem;
            font-weight: 400;
            line-height: 1.6;
        }

        .home-search-icon {
            display: none;
        }

        .home-search-logo {
            height: auto;
            max-width: min(320px, 78vw);
            width: 320px;
        }
    </style>


    <!--- CONTAINER DE CONTEUDO --->

    <div class="container"  >


        <!--- HEADER --->

        <cfinclude template="includes/header.cfm"/>


        <!--- CONTEUDO --->

        <section class="py-4 py-md-5" id="busca">
            <div class="row justify-content-center">
                <div class="col-lg-9 col-xl-8 text-center">
                    <img src="/assets/or_logo.svg" alt="Open Results" class="home-search-logo mb-3"/>
                    <h1 class="home-search-heading text-gray-light mb-4"><span class="home-search-intro">Pesquise entre</span><i class="fa-solid fa-magnifying-glass home-search-icon me-1" role="img" aria-label="Pesquise entre"></i> <cfoutput><strong>#lsNumberFormat(qTotalResultados.total)#</strong> resultados oficiais.</cfoutput></h1>

                    <cfset VARIABLES.buscaFormTerm = ""/>
                    <cfinclude template="includes/form_busca_principal.cfm"/>
                </div>
            </div>
        </section>

        <section class="pb-4">
            <cfparam name="URL.page" default="0"/>
            <cfparam name="URL.lastMonth" default="0"/>
            <cfset VARIABLES.homeContextUf = len(trim(VARIABLES.uf)) AND VARIABLES.uf NEQ "BR" ? uCase(trim(VARIABLES.uf)) : ""/>
            <cfset VARIABLES.homeContextLabel = len(trim(VARIABLES.homeContextUf)) ? getEstadoNome(VARIABLES.homeContextUf) : "Brasil"/>
            <cfset VARIABLES.homeContextFallback = false/>
            <cfif len(trim(VARIABLES.homeContextUf))>
                <cfquery name="qEventosHome" dbtype="query">
                    SELECT *
                    FROM qEventos
                    WHERE estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.homeContextUf#"/>
                    AND concluintes > 0
                </cfquery>

                <cfif NOT qEventosHome.recordcount>
                    <cfset VARIABLES.homeContextFallback = true/>
                    <cfquery name="qEventosHome" dbtype="query">
                        SELECT *
                        FROM qEventos
                        WHERE concluintes > 0
                    </cfquery>
                </cfif>
            <cfelse>
                <cfset VARIABLES.homeContextFallback = true/>
                <cfquery name="qEventosHome" dbtype="query">
                    SELECT *
                    FROM qEventos
                    WHERE concluintes > 0
                </cfquery>
            </cfif>

            <cfquery name="qEventosRecentesHome" dbtype="query" maxrows="120">
                SELECT *
                FROM qEventos
                WHERE concluintes > 0
                ORDER BY data_final desc
            </cfquery>

            <cfscript>
                VARIABLES.destaquePoolColumns = qEventosRecentesHome.columnList & ",destaque_score,destaque_group";
                VARIABLES.destaquePoolColumnArray = listToArray(VARIABLES.destaquePoolColumns);
                qEventosDestaquePool = queryNew(VARIABLES.destaquePoolColumns);

                for (eventRow = 1; eventRow <= qEventosRecentesHome.recordcount; eventRow++) {
                    destaqueScore = 0;
                    destaqueConcluintes = isNull(qEventosRecentesHome["concluintes"][eventRow]) ? 0 : val(qEventosRecentesHome["concluintes"][eventRow]);
                    destaqueListaPercursosResultado = isNull(qEventosRecentesHome["lista_percursos_resultado"][eventRow]) ? "" : qEventosRecentesHome["lista_percursos_resultado"][eventRow];
                    destaqueListaPercursos = isNull(qEventosRecentesHome["lista_percursos"][eventRow]) ? "" : qEventosRecentesHome["lista_percursos"][eventRow];
                    destaqueEstado = isNull(qEventosRecentesHome["estado"][eventRow]) ? "" : qEventosRecentesHome["estado"][eventRow];
                    destaqueHas42 = false;
                    destaqueHas21 = false;
                    destaqueHas10 = false;
                    destaqueHas5 = false;
                    destaqueDistances = [];

                    if (destaqueConcluintes >= 30000) {
                        destaqueScore += 120;
                    } else if (destaqueConcluintes >= 20000) {
                        destaqueScore += 90;
                    } else if (destaqueConcluintes >= 10000) {
                        destaqueScore += 60;
                    } else if (destaqueConcluintes >= 5000) {
                        destaqueScore += 30;
                    } else if (destaqueConcluintes >= 1000) {
                        destaqueScore += 10;
                    }

                    if (isDate(qEventosRecentesHome["data_final"][eventRow])) {
                        destaqueDaysSince = dateDiff("d", qEventosRecentesHome["data_final"][eventRow], now());

                        if (destaqueDaysSince <= 30) {
                            destaqueScore += 30;
                        } else if (destaqueDaysSince <= 60) {
                            destaqueScore += 20;
                        } else if (destaqueDaysSince <= 90) {
                            destaqueScore += 10;
                        }
                    }

                    if (len(trim(destaqueListaPercursosResultado))) {
                        try {
                            destaquePercursosResultado = deserializeJSON(destaqueListaPercursosResultado);

                            for (destaqueDistancia in destaquePercursosResultado) {
                                if (isStruct(destaqueDistancia) AND structKeyExists(destaqueDistancia, "percurso")) {
                                    arrayAppend(destaqueDistances, val(destaqueDistancia.percurso));
                                }
                            }
                        } catch (any e) {}
                    }

                    if (!arrayLen(destaqueDistances) AND len(trim(destaqueListaPercursos))) {
                        try {
                            destaquePercursosEvento = deserializeJSON(destaqueListaPercursos);

                            for (destaqueDistancia in destaquePercursosEvento) {
                                if (isStruct(destaqueDistancia) AND structKeyExists(destaqueDistancia, "percurso")) {
                                    arrayAppend(destaqueDistances, val(destaqueDistancia.percurso));
                                }
                            }
                        } catch (any e) {}
                    }

                    if (!isNull(qEventosRecentesHome["max_percurso"][eventRow]) AND val(qEventosRecentesHome["max_percurso"][eventRow]) > 0) {
                        arrayAppend(destaqueDistances, val(qEventosRecentesHome["max_percurso"][eventRow]));
                    }

                    if (!isNull(qEventosRecentesHome["is_maratona"][eventRow]) AND val(qEventosRecentesHome["is_maratona"][eventRow]) EQ 42) {
                        arrayAppend(destaqueDistances, 42);
                    }

                    for (destaqueDistance in destaqueDistances) {
                        destaqueDistanceRounded = round(val(destaqueDistance));

                        if (destaqueDistanceRounded EQ 42) {
                            destaqueHas42 = true;
                        } else if (destaqueDistanceRounded EQ 21) {
                            destaqueHas21 = true;
                        } else if (destaqueDistanceRounded EQ 10) {
                            destaqueHas10 = true;
                        } else if (destaqueDistanceRounded EQ 5) {
                            destaqueHas5 = true;
                        }
                    }

                    if (destaqueHas42) {
                        destaqueScore += 100;
                    }
                    if (destaqueHas21) {
                        destaqueScore += 60;
                    }
                    if (destaqueHas10) {
                        destaqueScore += 20;
                    }
                    if (destaqueHas5) {
                        destaqueScore += 10;
                    }

                    queryAddRow(qEventosDestaquePool, 1);
                    destaqueTargetRow = qEventosDestaquePool.recordcount;

                    for (destaqueColumn in listToArray(qEventosRecentesHome.columnList)) {
                        querySetCell(qEventosDestaquePool, destaqueColumn, qEventosRecentesHome[destaqueColumn][eventRow], destaqueTargetRow);
                    }

                    querySetCell(qEventosDestaquePool, "destaque_score", right("000000" & int(destaqueScore), 6), destaqueTargetRow);
                    querySetCell(
                        qEventosDestaquePool,
                        "destaque_group",
                        len(trim(VARIABLES.homeContextUf)) AND uCase(trim(destaqueEstado)) EQ VARIABLES.homeContextUf ? "regional" : "nacional",
                        destaqueTargetRow
                    );
                }
            </cfscript>

            <cfquery name="qEventosDestaqueNacionais" dbtype="query" maxrows="6">
                SELECT *
                FROM qEventosDestaquePool
                WHERE pais = 'BR'
                ORDER BY destaque_score desc, concluintes desc, data_final desc
            </cfquery>

            <cfset qEventosDestaqueRegionais = queryNew(VARIABLES.destaquePoolColumns)/>
            <cfif len(trim(VARIABLES.homeContextUf))>
                <cfquery name="qEventosDestaqueRegionais" dbtype="query" maxrows="6">
                    SELECT *
                    FROM qEventosDestaquePool
                    WHERE estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.homeContextUf#"/>
                    ORDER BY destaque_score desc, concluintes desc, data_final desc
                </cfquery>
            </cfif>

            <cfscript>
                qEventosDestaqueHome = queryNew(VARIABLES.destaquePoolColumns);
                VARIABLES.destaqueSelectedIds = "";
                VARIABLES.destaqueNationalFirstLimit = len(trim(VARIABLES.homeContextUf)) ? 4 : 6;

                for (destaqueRow = 1; destaqueRow <= min(qEventosDestaqueNacionais.recordcount, VARIABLES.destaqueNationalFirstLimit); destaqueRow++) {
                    queryAddRow(qEventosDestaqueHome, 1);
                    destaqueTargetRow = qEventosDestaqueHome.recordcount;

                    for (destaqueColumn in VARIABLES.destaquePoolColumnArray) {
                        querySetCell(qEventosDestaqueHome, destaqueColumn, qEventosDestaqueNacionais[destaqueColumn][destaqueRow], destaqueTargetRow);
                    }

                    VARIABLES.destaqueSelectedIds = listAppend(VARIABLES.destaqueSelectedIds, qEventosDestaqueNacionais["id_evento"][destaqueRow]);
                }

                if (len(trim(VARIABLES.homeContextUf))) {
                    VARIABLES.destaqueRegionalAdded = 0;

                    for (destaqueRow = 1; destaqueRow <= qEventosDestaqueRegionais.recordcount; destaqueRow++) {
                        if (qEventosDestaqueHome.recordcount >= 6) {
                            break;
                        }

                        if (VARIABLES.destaqueRegionalAdded >= 2) {
                            break;
                        }

                        if (listFind(VARIABLES.destaqueSelectedIds, qEventosDestaqueRegionais["id_evento"][destaqueRow])) {
                            continue;
                        }

                        queryAddRow(qEventosDestaqueHome, 1);
                        destaqueTargetRow = qEventosDestaqueHome.recordcount;

                        for (destaqueColumn in VARIABLES.destaquePoolColumnArray) {
                            querySetCell(qEventosDestaqueHome, destaqueColumn, qEventosDestaqueRegionais[destaqueColumn][destaqueRow], destaqueTargetRow);
                        }

                        VARIABLES.destaqueSelectedIds = listAppend(VARIABLES.destaqueSelectedIds, qEventosDestaqueRegionais["id_evento"][destaqueRow]);
                        VARIABLES.destaqueRegionalAdded++;
                    }
                }

                for (destaqueRow = 1; destaqueRow <= qEventosDestaqueNacionais.recordcount; destaqueRow++) {
                    if (qEventosDestaqueHome.recordcount >= 6) {
                        break;
                    }

                    if (listFind(VARIABLES.destaqueSelectedIds, qEventosDestaqueNacionais["id_evento"][destaqueRow])) {
                        continue;
                    }

                    queryAddRow(qEventosDestaqueHome, 1);
                    destaqueTargetRow = qEventosDestaqueHome.recordcount;

                    for (destaqueColumn in VARIABLES.destaquePoolColumnArray) {
                        querySetCell(qEventosDestaqueHome, destaqueColumn, qEventosDestaqueNacionais[destaqueColumn][destaqueRow], destaqueTargetRow);
                    }

                    VARIABLES.destaqueSelectedIds = listAppend(VARIABLES.destaqueSelectedIds, qEventosDestaqueNacionais["id_evento"][destaqueRow]);
                }
            </cfscript>

            <cfif qEventosDestaqueHome.recordcount>
                <section class="or-featured-events mb-4" aria-labelledby="or-featured-events-title">
                    <div class="d-flex justify-content-between align-items-end flex-wrap gap-2 mb-2">
                        <h2 class="h4 mb-0" id="or-featured-events-title">Destaques recentes</h2>
                        <div class="or-featured-events-actions" aria-label="Navegar destaques recentes">
                            <button class="or-featured-events-nav" type="button" data-featured-scroll="prev" aria-label="Destaque anterior">
                                <i class="fa-solid fa-chevron-left"></i>
                            </button>
                            <button class="or-featured-events-nav" type="button" data-featured-scroll="next" aria-label="Proximo destaque">
                                <i class="fa-solid fa-chevron-right"></i>
                            </button>
                        </div>
                    </div>

                    <div class="or-featured-events-viewport">
                        <button class="or-featured-events-edge or-featured-events-edge-prev" type="button" data-featured-scroll="prev" aria-label="Destaque anterior">
                            <i class="fa-solid fa-chevron-left"></i>
                        </button>
                        <div class="or-featured-events-track" aria-label="Eventos em destaque" tabindex="0">
                            <cfoutput query="qEventosDestaqueHome">
                                <a href="/evento/#tag#/" class="or-featured-event-card">
                                    <span class="or-featured-event-date">#lsDateFormat(data_final,"dd mmm")#</span>
                                    <strong>#nome_evento#</strong>
                                    <span class="or-featured-event-meta"><i class="fa-solid fa-location-dot"></i>#cidade#<cfif Len(trim(estado))> - #estado#</cfif><cfif Len(trim(pais)) AND pais NEQ "BR"> - #pais#</cfif></span>
                                    <span class="or-featured-event-count"><i class="fa-solid fa-person-running"></i>#lsNumberFormat(concluintes)# concluintes</span>
                                </a>
                            </cfoutput>
                        </div>
                        <button class="or-featured-events-edge or-featured-events-edge-next" type="button" data-featured-scroll="next" aria-label="Proximo destaque">
                            <i class="fa-solid fa-chevron-right"></i>
                        </button>
                    </div>
                </section>
            </cfif>

            <div class="d-flex justify-content-between align-items-end flex-wrap gap-2 mb-2">
                <div>
                    <h2 class="h4 mb-1">Recentes<cfif NOT VARIABLES.homeContextFallback> em <cfoutput>#VARIABLES.homeContextLabel#</cfoutput></cfif></h2>
                </div>
            </div>

            <cfset qEventosAba = qEventosHome/>
            <cfset VARIABLES.originalPageSize = VARIABLES.pageSize/>
            <cfset VARIABLES.originalPage = URL.page/>
            <cfset VARIABLES.originalLastMonth = URL.lastMonth/>
            <cfset VARIABLES.originalEventCardColumnClass = isDefined("VARIABLES.eventCardColumnClass") ? VARIABLES.eventCardColumnClass : ""/>
            <cfset VARIABLES.originalHideEventMonthDivider = isDefined("VARIABLES.hideEventMonthDivider") ? VARIABLES.hideEventMonthDivider : false/>
            <cfset VARIABLES.pageSize = 24/>
            <cfset VARIABLES.eventCardColumnClass = "col-12 col-lg-6 mb-1"/>
            <cfset VARIABLES.hideEventMonthDivider = true/>
            <cfset URL.page = 0/>
            <cfset URL.lastMonth = 0/>
            <cfinclude template="includes/lista_de_eventos_simple.cfm"/>
            <cfset VARIABLES.pageSize = VARIABLES.originalPageSize/>
            <cfset VARIABLES.hideEventMonthDivider = VARIABLES.originalHideEventMonthDivider/>
            <cfif len(VARIABLES.originalEventCardColumnClass)>
                <cfset VARIABLES.eventCardColumnClass = VARIABLES.originalEventCardColumnClass/>
            <cfelse>
                <cfset structDelete(VARIABLES, "eventCardColumnClass")/>
            </cfif>
            <cfset URL.page = VARIABLES.originalPage/>
            <cfset URL.lastMonth = VARIABLES.originalLastMonth/>
            <cfinclude template="includes/proximos_eventos.cfm"/>
        </section>

    </div>


    <!--- FOOTER --->

    <cfinclude template="includes/footer.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="includes/seo-web-tools-body-end.cfm"/>


</body>

</html>
