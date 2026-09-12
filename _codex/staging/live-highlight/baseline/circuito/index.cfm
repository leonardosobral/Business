<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/circuito/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = lcase(trim(replace(URL.tag, '/', '')))/>

<cfif NOT len(trim(URL.tag))>
    <cflocation url="/busca/" addtoken="false"/>
</cfif>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/backend/backend_feed.cfm"/>

<cfquery name="qAgrega" result="qAgregaMeta">
    SELECT * FROM tb_agrega_eventos
    WHERE tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.tag#"/>
</cfquery>
<cfset logQueryDebug("qAgrega", qAgregaMeta, "circuito/agrega", "sem cache", qAgrega)/>

<cfif NOT qAgrega.recordcount>
    <cflocation url="/busca/" addtoken="false"/>
</cfif>

<cfquery name="qTema" result="qTemaMeta">
    SELECT * FROM tb_temas
    WHERE id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgrega.id_tema#"/>
</cfquery>
<cfset logQueryDebug("qTema", qTemaMeta, "circuito/tema", "sem cache", qTema)/>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "#qAgrega.nome_evento_agregado# - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Circuitos - #qAgrega.nome_evento_agregado# - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<body <cfif qTema.recordcount>style="background-color:<cfoutput>#qTema.cor_fundo#</cfoutput>"</cfif>>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>

    <style>
        .circuit-tabs-card {
            border: 1px solid rgba(51, 51, 51, 0.08);
            border-radius: 10px;
            background-color: #ffffff;
            overflow: hidden;
        }

        .circuit-tabs-card .nav-tabs {
            border-bottom: 0;
            gap: 0.45rem;
            padding: 0.75rem;
        }

        .circuit-tabs-card .nav-tabs .nav-link {
            border: 1px solid rgba(51, 51, 51, 0.08) !important;
            border-radius: 8px !important;
            background-color: #efefef;
            color: #333333;
            font-size: 0.82rem;
            font-weight: 700;
            line-height: 1.1;
            margin: 0 !important;
            min-width: 0;
            padding: 0.7rem 0.85rem;
        }

        .circuit-tabs-card .nav-tabs .nav-link.active,
        .circuit-tabs-card .nav-tabs .nav-link:hover,
        .circuit-tabs-card .nav-tabs .nav-link:focus {
            border-color: #fab120 !important;
            background-color: #ffffff;
            color: #333333;
        }

        .circuit-tabs-card .badge {
            border: 1px solid rgba(250, 177, 32, 0.35);
            background-color: rgba(250, 177, 32, 0.16);
            color: #333333;
            font-weight: 700;
        }

        @media (max-width: 991.98px) {
            .home-mobile-section {
                margin-top: 0.75rem;
            }
        }

        @media (max-width: 575.98px) {
            .circuit-tabs-card .nav-tabs {
                display: grid;
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .circuit-tabs-card .nav-tabs .nav-link {
                width: 100%;
                padding-inline: 0.55rem;
            }
        }
    </style>


    <!--- CONTAINER DE CONTEUDO --->

    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <!--- LISTAGEM DE EVENTOS --->

        <div class="row g-2">

            <div class="d-none d-lg-block col-lg-3 col-xl-3 order-lg-1 home-mobile-section">

                <cfinclude template="../includes/estrutura/home_sidebar_async_slot.cfm"/>

            </div>

            <!--- LISTA DE EVENTOS DE CORRIDA --->

            <div class="col-12 col-md-8 col-lg-6 col-xl-6 px-lg-3 order-1 order-md-2">

                <!--- HEADER DO TEMA--->

                <cfset VARIABLES.eventThemeHeaderCompact = true/>
                <cfinclude template="../includes/estrutura/header_tema.cfm"/>

                <!--- DESTAQUE --->

                <cfquery name="qEventosCircuito" cachedwithin="#CreateTimeSpan(0, 0, 5, 0)#" result="qEventosCircuitoMeta">
                    SELECT evt.*
                    FROM vw_evento_corridas evt
                    WHERE evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgrega.id_agrega_evento#"/>
                    ORDER BY evt.data_inicial
                </cfquery>
                <cfset logQueryDebug("qEventosCircuito", qEventosCircuitoMeta, "circuito/eventos_base", "5min", qEventosCircuito)/>

                <!--- LISTA DE EVENTOS DE CORRIDA --->

                <cfquery name="qEventosProximos" dbtype="query" result="qEventosProximosMeta">
                    SELECT * from qEventosCircuito
                    WHERE data_inicial >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>
                    ORDER BY data_inicial
                </cfquery>
                <cfset logQueryDebug("qEventosProximos", qEventosProximosMeta, "circuito/proximos", "dbtype=query", qEventosProximos)/>

                <cfquery name="qEventosPassados" dbtype="query" result="qEventosPassadosMeta">
                    SELECT * from qEventosCircuito
                    WHERE data_inicial < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>
                    ORDER BY data_inicial desc
                </cfquery>
                <cfset logQueryDebug("qEventosPassados", qEventosPassadosMeta, "circuito/passados", "dbtype=query", qEventosPassados)/>

                <!--- ABAS --->

                <nav class="circuit-tabs-card mt-0 mb-3">
                    <div class="nav nav-tabs justify-content-center" id="nav-tab" role="tablist">
                        <button class="nav-link <cfif qEventosProximos.recordcount>active</cfif>" id="nav-tab-2" data-bs-toggle="tab" data-bs-target="#nav-home-2" type="button" role="tab" aria-controls="nav-home-2" aria-selected="false">Próximos<span class="badge badge-warning ms-2"><cfoutput>#qEventosProximos.recordcount#</cfoutput></span></button>
                        <button class="nav-link <cfif NOT qEventosProximos.recordcount>active</cfif>" id="nav-tab-7" data-bs-toggle="tab" data-bs-target="#nav-home-7" type="button" role="tab" aria-controls="nav-home-7" aria-selected="false">Realizados<span class="badge badge-warning ms-2"><cfoutput>#qEventosPassados.recordcount#</cfoutput></span></button>
                    </div>
                </nav>

                <div class="tab-content" id="nav-tabContent">

                    <div class="tab-pane fade <cfif qEventosProximos.recordcount>show active</cfif> p-0" id="nav-home-2" role="tabpanel" aria-labelledby="nav-tab-2" tabindex="1">

                        <cfset VARIABLES.agrupamento = "mes"/>
                        <cfset VARIABLES.qEventosAba = qEventosProximos/>
                        <!---<div class="small text-center p-2">Exibindo <cfoutput>#qEventosProximos.recordcount#</cfoutput> eventos.</div>--->
                        <cfinclude template="../includes/lista_de_eventos_live.cfm"/>

                    </div>

                    <div class="tab-pane fade <cfif NOT qEventosProximos.recordcount>show active</cfif> p-0" id="nav-home-7" role="tabpanel" aria-labelledby="nav-tab-7" tabindex="6">

                        <cfset VARIABLES.agrupamento = "mes"/>
                        <cfset VARIABLES.qEventosAba = qEventosPassados/>
                        <!---<div class="small text-center p-2">Exibindo <cfoutput>#qEventosPassados.recordcount#</cfoutput> eventos.</div>--->
                        <cfinclude template="../includes/lista_de_eventos_live.cfm"/>

                    </div>

                </div>

            </div>

            <!--- BARRA LATERAL --->

            <div class="d-none d-lg-block col-lg-3 order-3 home-mobile-section">

                <cfinclude template="../includes/estrutura/conteudo_lateral_api.cfm"/>

            </div>

        </div>

        </main>

    </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>
