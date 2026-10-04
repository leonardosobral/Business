<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/maratonas/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = ucase(trim(replace(URL.tag, '/', '')))/>

<!--- BACKEND --->
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfif Usuario.logado>
    <cfinclude template="../includes/backend/backend_perfil_edicao.cfm"/>
</cfif>

<!--- META INFO --->
<cfset VARIABLES.canonical = "#APPLICATION.baseCanonica##VARIABLES.template##URL.tag##Len(trim(URL.tag)) ? '/' : ''##VARIABLES.queryString#"/>
<cfset VARIABLES.title = "Maratonas - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = "Uma listagem de todas as maratonas que vão acontecer no Brasil, de hoje em diante."/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<!--- HEAD --->
<cfinclude template="../includes/estrutura/head.cfm"/>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>


    <!--- CONTAINER DE CONTEUDO --->

    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/estrutura/header.cfm"/>
        <cfinclude template="../includes/estrutura/home_hero_busca.cfm"/>

        <main id="rr-page-content" class="rr-page-content" data-rr-page-content>

        <!--- LISTAGEM DE EVENTOS --->

        <div class="row g-2">

        <div class="col-md-3 d-none d-md-block">

    <cfinclude template="../includes/estrutura/home_sidebar_async_slot.cfm"/>

    </div>

    <!--- LISTA DE EVENTOS DE CORRIDA --->

        <div class="col-12 col-md-6 px-lg-5">

                <!--- TITULO --->

                <h3>
                    <a href="/"><icon class="fa fa-person-running"></icon></a>
                    <img src="/assets/separador.png" alt="separador de breadcrumb" style="max-height: 24px; margin-top: -4px">
                    Maratonas do Brasil
                </h3>

                <!--- LISTA DE MARATONAS --->

                <cfquery name="qEventosAba2" dbtype="query" result="qEventosAba2Meta">
                    SELECT * from qEventos
                    WHERE is_maratona = 42
                    AND tipo_corrida = 'rua'
                    and pais IN ('BR','AR','CL','PE','PY','UR')
                </cfquery>
                <cfset logQueryDebug("qEventosAba2", qEventosAba2Meta, "maratonas/rua", "dbtype=query", qEventosAba2)/>

                <cfquery name="qEventosAba3" dbtype="query" result="qEventosAba3Meta">
                    SELECT * from qEventos
                    WHERE is_maratona = 42
                    AND tipo_corrida = 'trail'
                    and pais IN ('BR','AR','CL','PE','PY','UR')
                    ORDER BY data_inicial, destaque desc
                </cfquery>
                <cfset logQueryDebug("qEventosAba3", qEventosAba3Meta, "maratonas/trail", "dbtype=query", qEventosAba3)/>

                <cfquery name="qEventosAba4" dbtype="query" result="qEventosAba4Meta">
                    SELECT * from qEventos
                    WHERE max_percurso > 42
                    and pais IN ('BR','AR','CL','PE','PY','UR')
                    ORDER BY data_inicial, destaque desc
                </cfquery>
                <cfset logQueryDebug("qEventosAba4", qEventosAba4Meta, "maratonas/ultra", "dbtype=query", qEventosAba4)/>


                <!--- ABAS --->

                <nav class="card px-2 mb-2">
                    <div class="nav nav-tabs" id="nav-tab" role="tablist">
                        <button class="nav-link active" id="nav-tab-2" data-bs-toggle="tab" data-bs-target="#nav-home-2" type="button" role="tab" aria-controls="nav-home-2" aria-selected="false">Rua</button>
                        <button class="nav-link" id="nav-tab-3" data-bs-toggle="tab" data-bs-target="#nav-home-3" type="button" role="tab" aria-controls="nav-home-3" aria-selected="false">Trail</button>
                        <button class="nav-link" id="nav-tab-4" data-bs-toggle="tab" data-bs-target="#nav-home-4" type="button" role="tab" aria-controls="nav-home-4" aria-selected="false">Ultra</button>
                    </div>
                </nav>

                <div class="tab-content" id="nav-tabContent">

                    <div class="tab-pane fade show active" id="nav-home-2" role="tabpanel" aria-labelledby="nav-tab-2" tabindex="1">

                        <cfset VARIABLES.qEventosAba = qEventosAba2/>
                        <cfset VARIABLES.agrupamento = "mes"/>
                        <!---div class="small text-center p-2">Exibindo <cfoutput>#qEventosAba2.recordcount#</cfoutput> eventos.</div--->
                        <cfinclude template="../includes/lista_de_eventos_simple.cfm"/>

                    </div>

                    <div class="tab-pane fade" id="nav-home-3" role="tabpanel" aria-labelledby="nav-tab-3" tabindex="2">

                        <cfset VARIABLES.qEventosAba = qEventosAba3/>
                        <cfset VARIABLES.agrupamento = "mes"/>
                        <!---div class="small text-center p-2">Exibindo <cfoutput>#qEventosAba3.recordcount#</cfoutput> eventos.</div--->
                        <cfinclude template="../includes/lista_de_eventos_simple.cfm"/>

                    </div>

                    <div class="tab-pane fade" id="nav-home-4" role="tabpanel" aria-labelledby="nav-tab-4" tabindex="3">

                        <cfset VARIABLES.qEventosAba = qEventosAba4/>
                        <cfset VARIABLES.agrupamento = "mes"/>
                        <!---div class="small text-center p-2">Exibindo <cfoutput>#qEventosAba4.recordcount#</cfoutput> eventos.</div--->
                        <cfinclude template="../includes/lista_de_eventos_simple.cfm"/>

                    </div>

                </div>

            </div>

            <!--- BARRA LATERAL --->

            <div class="col-lg-3">

                <cfinclude template="../includes/estrutura/barra_lateral.cfm"/>

            </div>

        </div>

        </main>

    </div>


    <!--- FOOTER --->

    <cfinclude template="../includes/estrutura/footer.cfm"/>


    <!--- MODAL DE BADGES --->

    <cfinclude template="../includes/modal/modal_badges.cfm"/>


    <!--- MODAL DE YOUTUBE --->

    <cfinclude template="../includes/modal/modal_youtube.cfm"/>


    <!--- MODAL FOCO --->

    <cfinclude template="../includes/modal/modal_cupom_foco.cfm"/>


    <!--- MODAL CADASTRO EVENTO --->

    <cfinclude template="../includes/modal/modal_cadastro_evento.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- MODAL SEGUIDORES / SEGUINDO --->

    <cfinclude template="../includes/modal/modal_seguidores.cfm"/>


    <!--- MODAL PAGAMENTO --->

    <cfinclude template="../includes/modal/modal_pagamento.cfm"/>


    <!--- MODAL LOGIN --->

    <cfinclude template="../includes/modal/modal_login.cfm"/>


    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>

</body>

</html>
