<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TERMO DE BUSCA --->
<cfif isDefined("URL.termo") AND isDefined("URL.escopo") AND URL.escopo EQ "site">
    <cflocation addtoken="false" url="/busca/?termo=#URL.termo#"/>
</cfif>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/evento/"/>

<!--- TAG PARAM TREAT --->
<cfparam name="URL.tag" default=""/>
<cfset URL.tag = trim(replace(URL.tag, '/', ''))/>

<!--- PARAMETROS --->
<cfparam name="URL.genero" default="F"/>

<!--- BACKEND --->
<cfinclude template="../includes/variaveis.cfm"/>
<cfinclude template="../includes/backend.cfm"/>
<cfinclude template="../includes/backend_evento.cfm"/>

<cfif qModalidades.recordCount>
    <cfparam name="URL.modalidade" default="#qModalidades.modalidade#"/>
</cfif>

<!--- META INFO --->
<cfset VARIABLES.canonical = APPLICATION.baseCanonica & VARIABLES.template & replace(encodeForURL(qEvento.tag), "+", "%20", "all") & "/"/>
<cfset VARIABLES.title = "#htmlEditFormat(qEvento.nome_evento)# - Resultados e informações - #APPLICATION.nomeSite#"/>
<cfset VARIABLES.description = htmlEditFormat("#qEvento.nome_evento# em #qEvento.cidade#/#qEvento.estado#. #VARIABLES.eventoStatusTitulo#. #VARIABLES.eventoStatusDescricao#")/>
<cfset VARIABLES.keywords = "resultados, corrida, competição, pódio, atletas, corredores"/>

<cfinclude template="../includes/seo_event_schema.cfm"/>

<!--- HEAD --->
<cfinclude template="../includes/head.cfm"/>

<script>
    if(location.hash) {
        var idhash = window.location.hash;
        var idline = 'line_' + idhash.substr(1);
    }<cfif VARIABLES.eventoTemResultados>else {
        var hash = '#resultado';
        onload=window.location=hash;
    }</cfif>
</script>

<body>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-start.cfm"/>


    <div class="container">


        <!--- HEADER --->

        <cfinclude template="../includes/header.cfm"/>


        <!--- DADOS E RESUMO DO EVENTO --->


        <cfif qEvento.recordCount>

                    <!--- HEADER DO EVENTO --->

                    <cfloop query="qEvento">

                        <cfinclude template="../includes/card_evento_individual.cfm"/>

                    </cfloop>
                    <cfif isDate(qEvento.data_inicial) AND isDate(qEvento.data_final) AND dateCompare(qEvento.data_final, qEvento.data_inicial, "d") GT 0>
                        <p class="small text-secondary mb-0"><cfoutput>Período do evento: #lsDateFormat(qEvento.data_inicial, "dd/mm/yyyy")# a #lsDateFormat(qEvento.data_final, "dd/mm/yyyy")#.</cfoutput></p>
                    </cfif>


                    <div class="pt-2 small d-flex justify-content-between align-items-start flex-wrap gap-2">

                        <div>
                            <a href="https://roadrunners.run/evento/<cfoutput>#URL.tag#</cfoutput>?utm_source=openresults&amp;utm_medium=referral&amp;utm_campaign=openresults_to_roadrunners&amp;utm_content=detalhes_evento" target="_blank" data-rr-placement="detalhes_evento">
                                <img title="Ver detalhes do evento" src="/assets/rr_logo_square.jpg" style="height: 18; width: 18px;" class="rounded"> <small>Sobre o evento</small>
                            </a>

                            <!--- ORGANIZADOR E CRONOMETRADOR --->

                            <cfif qFornecedores.recordcount>
                                <cfoutput query="qFornecedores">
                                        <div class="pe-xl-2 text-nowrap text-gray-light d-md-inline-flex small">| #qFornecedores.descricao_tipo#:&nbsp;
                                        <a href="/#qFornecedores.tag_tipo#/#qFornecedores.tag_fornecedor#/" class="link-dark">
                                        #qFornecedores.nome_fornecedor#
                                        </a>
                                        </div>
                                </cfoutput>
                            </cfif>
                        </div>

                        <cfif qEvento.obs_resultado NEQ 'PNC' AND len(trim(qEvento.url_resultado)) AND VARIABLES.eventoResultadoEstado NEQ "agendado" AND VARIABLES.eventoResultadoEstado NEQ "cancelado">
                            <small class="text-end">
                                <cfoutput>Fonte: <a href="#htmlEditFormat(qEvento.url_resultado)#" target="_blank" rel="noopener" style="text-decoration: underline" data-rr-placement="evento_fonte_resultados">resultado oficial</a><cfif len(trim(qProcessamentoResultado.data_processamento_final))>, atualizado em #lsdateformat(qProcessamentoResultado.data_processamento_final, "dd/mm/yyyy")#</cfif>.</cfoutput>
                            </small>
                        </cfif>

                    </div>

                    <hr/>

                    <cfif VARIABLES.eventoResultadoEstado NEQ "disponivel">
                        <section class="or-event-card my-3" aria-labelledby="evento-status-titulo">
                            <div class="or-event-card-body">
                                <h2 class="h5 fw-bold mb-2" id="evento-status-titulo"><cfoutput>#htmlEditFormat(VARIABLES.eventoStatusTitulo)#</cfoutput></h2>
                                <p class="mb-0"><cfoutput>#htmlEditFormat(VARIABLES.eventoStatusDescricao)#</cfoutput></p>
                                <cfif len(trim(qEvento.url_resultado)) AND qEvento.obs_resultado NEQ 'PNC' AND VARIABLES.eventoResultadoEstado NEQ "agendado" AND VARIABLES.eventoResultadoEstado NEQ "cancelado">
                                    <p class="mt-2 mb-0"><a href="<cfoutput>#htmlEditFormat(qEvento.url_resultado)#</cfoutput>" target="_blank" rel="noopener" class="text-decoration-underline" data-rr-placement="evento_fonte_aguardando">Consultar a fonte oficial dos resultados</a></p>
                                </cfif>
                            </div>
                        </section>
                    </cfif>


                    <!--- INDICES --->

                    <cfif qModalidades.recordCount AND qEvento.obs_resultado NEQ 'PNC'>

                        <div class="row g-3">

                            <h3 class="h6">Resultados por modalidade</h3>

                            <cfoutput query="qModalidades">

                                <cfif qModalidades.concluintes GTE 30 OR uCase(qModalidades.modalidade) CONTAINS "ELITE" OR uCase(qModalidades.modalidade) CONTAINS "PODIO" OR uCase(qModalidades.modalidade) CONTAINS "PÓDIO">

                                    <div class="col-md-6 col-lg-4 my-2">

                                        <div class="card or-event-card">
                                            <a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#">
                                            <!---<div class="card-header bg-#qModalidades.percurso#k text-center py-1">--->
                                            <div class="kms text-center py-1 rounded-bottom-0" data-color="#qModalidades.percurso#">
                                                <span class="<cfif Len(qModalidades.modalidade) LT 24>h5</cfif>">#qModalidades.modalidade#</span>
                                                <!--- SELOS DE PERMIT--->
                                                <cfset VARIABLES.permitSize = 20/>
                                                <cfset VARIABLES.permit_cbat = qModalidades.permit_cbat/>
                                                <cfset VARIABLES.permit_wa = qModalidades.permit_wa/>
                                                <cfif len(trim(qModalidades.permit_cbat)) OR len(trim(qModalidades.permit_wa))>
                                                    <div class="float-end m-0 p-0">
                                                        <cfinclude template="../includes/permits.cfm"/>
                                                    </div>
                                                </cfif>
                                            </div>
                                            </a>
                                            <div class="card-body p-0">
                                                <table class="table table-sm table-striped mt-0 mb-0" style="font-size: small;">
                                                    <cfquery name="qStatsPercurso">
                                                        SELECT sexo, MIN(tempo_total) as rp, MIN(pace) as rp_pace, count(res.id_resultado) as concluintes, count(distinct res.id_evento) as eventos,
                                                        to_char(AVG(tempo_total),'hh24:mi:ss') as avg_tempo, to_char(AVG(pace),'hh24:mi:ss') as avg_pace
                                                        FROM tb_resultados res
                                                        INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
                                                        WHERE modalidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qModalidades.modalidade#">
                                                        AND percurso::int = <cfqueryparam cfsqltype="cf_sql_integer" value="#qModalidades.percurso#">
                                                        AND sexo in ('M','F','X')
                                                        AND concluinte = true
                                                        AND status_final = 0
                                                        AND evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qEvento.id_evento#"/>
                                                        AND res.homologado = true
                                                        GROUP BY sexo
                                                    </cfquery>
                                                    <tr>
                                                        <td class="px-1 pt-1 pb-0">Melhor:</td>
                                                        <td class="px-1 pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=F"><img src="/assets/rh_icon_fem.png" width="14" data-bs-toggle="tooltip" title="Feminino" style="margin-top: -4px"/></a></td>
                                                        <td class="px-1 mono pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=F">#qStatsPercurso.rp[1]#</a></td>
                                                        <td class="px-1 pt-1 pb-0">#(qStatsPercurso.recordcount GT 1) ? '<a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=M"><img src="/assets/rh_icon_masc.png" width="14" data-bs-toggle="tooltip" title="Masculino" style="margin-top: -4px"/></a>' : '<img src="/assets/rh_icon_masc.png" width="14" style="margin-top: -4px"/>'#</td>
                                                        <td class="px-1 mono pt-1 pb-0">#(qStatsPercurso.recordcount GT 1) ? '<a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=M">#qStatsPercurso.rp[2]#</a>' : "--:--"#</td>
                                                        <cfif qStatsPercurso.recordcount GT 2>
                                                            <td class="px-1 pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=X"><img src="/assets/rh_icon_nonbinary.png" width="14" data-bs-toggle="tooltip" title="Não-binário" style="margin-top: -4px"/></a></td>
                                                            <td class="px-1 mono pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=X">#qStatsPercurso.rp[3]#</a></td>
                                                        </cfif>
                                                    </tr>
                                                    <cfif qEvento.resultado_completo>
                                                    <tr>
                                                        <td class="px-1 pt-1 pb-0">Média:</td>
                                                        <td class="px-1 pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=F"><img src="/assets/rh_icon_fem.png" width="14" data-bs-toggle="tooltip" title="Feminino" style="margin-top: -4px"/></a></td>
                                                        <td class="px-1 mono pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=F">#qStatsPercurso.avg_tempo[1]#</a></td>
                                                        <td class="px-1 pt-1 pb-0">#(qStatsPercurso.recordcount GT 1) ? '<a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=M"><img src="/assets/rh_icon_masc.png" width="14" data-bs-toggle="tooltip" title="Masculino" style="margin-top: -4px"/></a>' : '<img src="/assets/rh_icon_masc.png" width="14" style="margin-top: -4px"/>'#</td>
                                                        <td class="px-1 mono pt-1 pb-0">#(qStatsPercurso.recordcount GT 1) ? '<a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=M">#qStatsPercurso.avg_tempo[2]#</a>' : "--:--"#</td>
                                                        <cfif qStatsPercurso.recordcount GT 2>
                                                            <td class="px-1 pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=X"><img src="/assets/rh_icon_nonbinary.png" width="14" data-bs-toggle="tooltip" title="Não-binário" style="margin-top: -4px"/></a></td>
                                                            <td class="px-1 mono pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=X">#qStatsPercurso.avg_tempo[3]#</a></td>
                                                        </cfif>
                                                    </tr>
                                                    </cfif>
                                                    <cfif qEvento.resultado_completo>
                                                    <tr>
                                                        <td class="px-1 pt-1 pb-0">Totais:</td>
                                                        <td class="px-1 pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=F"><img src="/assets/rh_icon_fem.png" width="14" data-bs-toggle="tooltip" title="Feminino" style="margin-top: -4px"/></a></td>
                                                        <td class="px-1 mono pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=F">#lsNumberFormat(qStatsPercurso.concluintes[1])#</a></td>
                                                        <td class="px-1 pt-1 pb-0">#(qStatsPercurso.recordcount GT 1) ? '<a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=M"><img src="/assets/rh_icon_masc.png" width="14" data-bs-toggle="tooltip" title="Masculino" style="margin-top: -4px"/></a>' : '<img src="/assets/rh_icon_masc.png" width="14" style="margin-top: -4px"/>'#</td>
                                                        <td class="px-1 mono pt-1 pb-0">#(qStatsPercurso.recordcount GT 1) ? '<a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=M">#lsNumberFormat(qStatsPercurso.concluintes[2])#</a>' : ""#</td>
                                                        <cfif qStatsPercurso.recordcount GT 2>
                                                            <td class="px-1 pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=X"><img src="/assets/rh_icon_nonbinary.png" width="14" data-bs-toggle="tooltip" title="Não-binário" style="margin-top: -4px"/></a></td>
                                                            <td class="px-1 mono pt-1 pb-0"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#&genero=X">#lsNumberFormat(qStatsPercurso.concluintes[3])#</a></td>
                                                        </cfif>
                                                    </tr>
                                                    </cfif>
                                                    <tr>
                                                        <td class="px-1 pt-1 pb-0 border-0"></td>
                                                        <td class="px-1 pt-1 pb-0 border-0"><img src="/assets/runners.png" width="14" data-bs-toggle="tooltip" title="Total de concluintes" style="margin-top: -4px"/></td>
                                                        <td class="mono px-1 pt-1 pb-0 border-0" colspan="5">
                                                            <cfif qEvento.resultado_completo>
                                                                #(qStatsPercurso.recordcount GT 2) ? (qStatsPercurso.concluintes[1]+qStatsPercurso.concluintes[2]+qStatsPercurso.concluintes[3]) : (qStatsPercurso.recordcount GT 1 ? (qStatsPercurso.concluintes[1]+qStatsPercurso.concluintes[2]) : qStatsPercurso.concluintes[1])# concluintes
                                                            <cfelse>
                                                                <cfloop array="#deserializeJSON(qEvento.lista_percursos_resultado)#" index="distancia">
                                                                    <cfif qModalidades.percurso EQ distancia.percurso>
                                                                        #lsNumberFormat(distancia.concluintes)# concluintes
                                                                    </cfif>
                                                                </cfloop>
                                                            </cfif>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </div>
                                        </div>

                                    </div>

                                </cfif>

                            </cfoutput>

                            <cfset VARIABLES.hasOutrasModalidades = false/>

                            <cfloop query="qModalidades">
                                <cfif qModalidades.concluintes LT 30 AND uCase(qModalidades.modalidade) DOES NOT CONTAIN "ELITE" AND uCase(qModalidades.modalidade) DOES NOT CONTAIN "PODIO" AND uCase(qModalidades.modalidade) DOES NOT CONTAIN "PÓDIO">
                                    <cfset VARIABLES.hasOutrasModalidades = true/>
                                    <cfbreak/>
                                </cfif>
                            </cfloop>

                            <cfif VARIABLES.hasOutrasModalidades>

                            <h3 class="h6">Outras modalidades:</h3>

                            <cfoutput query="qModalidades">

                                <cfif qModalidades.concluintes LT 30 AND uCase(qModalidades.modalidade) DOES NOT CONTAIN "ELITE" AND uCase(qModalidades.modalidade) DOES NOT CONTAIN "PODIO" AND uCase(qModalidades.modalidade) DOES NOT CONTAIN "PÓDIO">

                                    <div class="kms w-auto mb-1 ms-1" data-color="#qModalidades.percurso#"><a href="/evento/#qEvento.tag#/?modalidade=#qModalidades.modalidade#"><i class="fa-solid fa-person-running"></i>&nbsp;#qModalidades.modalidade# <span class="fw-normal">| #lsNumberFormat(qModalidades.concluintes)# concluintes</span></a></div>

                                </cfif>

                            </cfoutput>

                            </cfif>

                        </div>

                    </cfif>

            <!--- RESULTADOS --->

            <cfif VARIABLES.eventoTemResultados AND (isDefined("URL.modalidade") OR isDefined("URL.termo")) AND (qEvento.obs_resultado NEQ 'PNC' OR VARIABLES.devMode)>

                <cfif isDefined("URL.modalidade")>

                    <cfquery name="qModalidade" dbtype="query">
                        SELECT * FROM qModalidades
                        WHERE modalidade = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.modalidade#"/>
                    </cfquery>

                    <!--- DIVISORIA DO RESULTADO --->

                    <div class="row mt-3 g-0 kms rounded-bottom-0" data-color="<cfoutput>#qModalidade.percurso#</cfoutput>">

                        <!--- MODALIDADE --->

                        <div class="col-7 col-md-8 py-2 px-3">
                        <!---<div class="col-7 col-md-8 py-2 px-3 kms" data-color="<cfoutput>#qModalidade.percurso#</cfoutput>">--->

                            <h2 class="h5 mb-0">
                                Resultado
                                <cfoutput>
                                    <cfif isdefined("URL.modalidade")>
                                        &nbsp;&nbsp;<img src="/assets/separador.png" style="max-height: 20px; margin-top: -4px">&nbsp;&nbsp; <a href="/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=#URL.genero#">#URL.modalidade#</a>
                                        <cfif isDefined("URL.categoria")>
                                            &nbsp;&nbsp;<img src="/assets/separador.png" style="max-height: 20px; margin-top: -4px">&nbsp;&nbsp; <a href="/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=#URL.genero#&categoria=#URL.categoria#"> Categoria  #URL.categoria#</a>
                                        </cfif>
                                        <cfif isDefined("URL.equipe")>
                                            &nbsp;&nbsp;<img src="/assets/separador.png" style="max-height: 20px; margin-top: -4px">&nbsp;&nbsp; <a href="/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=#URL.genero#&equipe=#URL.equipe#"> Equipe  #URL.equipe#</a>
                                        </cfif>
                                    </cfif>
                                </cfoutput>
                                &nbsp;
                                <cfset VARIABLES.permitSize = 20/>
                                <cfset VARIABLES.permit_cbat = qModalidade.permit_cbat/>
                                <cfset VARIABLES.permit_wa = qModalidade.permit_wa/>
                                <cfif len(trim(qModalidade.permit_cbat)) OR len(trim(qModalidade.permit_wa))>
                                    <cfinclude template="../includes/permits.cfm"/>
                                </cfif>
                            </h2>

                        </div>

                        <!--- EXPORTAR --->

                        <cfif lcase(listFirst(CGI.HTTP_HOST, ":")) EQ "dev.openresults.run">
                            <cfset VARIABLES.resultadoExportBaseUrl = "/exportar-resultados-evento-v2.cfm?id_evento=#qModalidade.id_evento#&modalidade=#urlEncodedFormat(URL.modalidade)#&genero=#urlEncodedFormat(URL.genero)#"/>
                            <cfif isDefined("URL.categoria")>
                                <cfset VARIABLES.resultadoExportBaseUrl = VARIABLES.resultadoExportBaseUrl & "&categoria=#urlEncodedFormat(URL.categoria)#"/>
                            </cfif>
                            <cfif isDefined("URL.equipe")>
                                <cfset VARIABLES.resultadoExportBaseUrl = VARIABLES.resultadoExportBaseUrl & "&equipe=#urlEncodedFormat(URL.equipe)#"/>
                            </cfif>
                            <cfif isDefined("URL.termo")>
                                <cfset VARIABLES.resultadoExportBaseUrl = VARIABLES.resultadoExportBaseUrl & "&termo=#urlEncodedFormat(URL.termo)#"/>
                            </cfif>

                            <cfset VARIABLES.resultadoExportEventoUrl = "/exportar-resultados-evento-v2.cfm?id_evento=#qModalidade.id_evento#&escopo=evento"/>

                            <cfoutput>
                                <div class="col-5 col-md-4 py-1 px-3 d-flex justify-content-end align-items-center">
                                    <div class="dropdown">
                                        <button class="btn btn-light btn-sm shadow-0" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                                            <i class="fa-solid fa-download"></i> Exportar
                                        </button>
                                        <ul class="dropdown-menu dropdown-menu-end">
                                            <li><h6 class="dropdown-header">Recorte atual</h6></li>
                                            <li><a class="dropdown-item" href="#VARIABLES.resultadoExportBaseUrl#&formato=csv" target="_blank"><i class="fa-solid fa-file-csv me-2"></i>CSV</a></li>
                                            <li><a class="dropdown-item" href="#VARIABLES.resultadoExportBaseUrl#&formato=xls" target="_blank"><i class="fa-solid fa-file-excel me-2"></i>XLS</a></li>
                                            <li><hr class="dropdown-divider"></li>
                                            <li><h6 class="dropdown-header">Evento completo</h6></li>
                                            <li><a class="dropdown-item" href="#VARIABLES.resultadoExportEventoUrl#&formato=csv" target="_blank"><i class="fa-solid fa-file-csv me-2"></i>CSV</a></li>
                                            <li><a class="dropdown-item" href="#VARIABLES.resultadoExportEventoUrl#&formato=xls" target="_blank"><i class="fa-solid fa-file-excel me-2"></i>XLS</a></li>
                                        </ul>
                                    </div>
                                </div>
                            </cfoutput>
                        </cfif>

                        <!---<cfoutput>
                            <div class="col-5 col-md-4 py-1 px-3">
                                <a href="/relatorio-excel/?id_evento=#qModalidade.id_evento#&modalidade=#URL.modalidade#" target="_blank"><button class="btn btn-sm float-end ms-2"><icon class="fa fa-file-excel"></icon> Excel</button></a>
                                <a href="/relatorio-pdf/?id_evento=#qModalidade.id_evento#&modalidade=#URL.modalidade#" target="_blank"><button class="btn btn-sm float-end ms-2"><icon class="fa fa-file-pdf"></icon> PDF</button></a>
                            </div>
                        </cfoutput>--->

                    </div>

                    <!--- ABAS DOS RESULTADOS --->

                    <nav class="bg-white">

                        <div class="nav nav-tabs" id="nav-tab" role="tablist">
                            <cfif URL.genero EQ "F">
                                <button class="nav-link active" id="nav-tab-F" data-bs-toggle="tab" data-bs-target="#nav-resultados" type="button" role="tab" aria-controls="nav-resultados" aria-selected="<cfif URL.genero EQ "F">true<cfelse>false</cfif>"><img src="/assets/rh_icon_fem.png" width="14" data-bs-toggle="tooltip" title="Feminino" style="margin-right:6px; margin-top: -4px"/>Feminino</button>
                                <a class="nav-link" id="nav-tab-M" href="<cfoutput>/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=M</cfoutput>" role="tab" aria-selected="false"><img src="/assets/rh_icon_masc.png" width="14" data-bs-toggle="tooltip" title="Masculino" style="margin-right:6px; margin-top: -4px"/>Masculino</a>
                                <cfif isDefined("qStatsPercurso.rp") AND qStatsPercurso.rp[3] GT 0>
                                    <a class="nav-link" id="nav-tab-X" href="<cfoutput>/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=X</cfoutput>" role="tab" aria-selected="false"><img src="/assets/rh_icon_nonbinary.png" width="14" data-bs-toggle="tooltip" title="Não Binário" style="margin-right:6px; margin-top: -4px"/>Não Binário</a>
                                </cfif>
                            </cfif>
                            <cfif URL.genero EQ "M">
                                <a class="nav-link" id="nav-tab-F" href="<cfoutput>/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=F</cfoutput>" role="tab" aria-selected="false"><img src="/assets/rh_icon_fem.png" width="14" data-bs-toggle="tooltip" title="Feminino" style="margin-right: 6px; margin-top: -4px"/>Feminino</a>
                                <button class="nav-link active" id="nav-tab-M" data-bs-toggle="tab" data-bs-target="#nav-resultados" type="button" role="tab" aria-controls="nav-resultados" aria-selected="true"><img src="/assets/rh_icon_masc.png" width="14" data-bs-toggle="tooltip" title="Masculino" style="margin-right: 6px; margin-top: -4px"/>Masculino</button>
                                <cfif isDefined("qStatsPercurso.rp") AND qStatsPercurso.rp[3] GT 0>
                                    <a class="nav-link" id="nav-tab-X" href="<cfoutput>/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=X</cfoutput>" role="tab" aria-selected="false"><img src="/assets/rh_icon_nonbinary.png" width="14" data-bs-toggle="tooltip" title="Não Binário" style="margin-right:6px; margin-top: -4px"/>Não Binário</a>
                                </cfif>
                            </cfif>
                        <cfif URL.genero EQ "X">
                                <a class="nav-link" id="nav-tab-F" href="<cfoutput>/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=F</cfoutput>" role="tab" aria-selected="false"><img src="/assets/rh_icon_fem.png" width="14" data-bs-toggle="tooltip" title="Feminino" style="margin-right: 6px; margin-top: -4px"/>Feminino</a>
                                <a class="nav-link" id="nav-tab-M" href="<cfoutput>/evento/#qEvento.tag#/?modalidade=#URL.modalidade#&genero=M</cfoutput>" role="tab" aria-selected="false"><img src="/assets/rh_icon_masc.png" width="14" data-bs-toggle="tooltip" title="Masculino" style="margin-right:6px; margin-top: -4px"/>Masculino</a>
                                <button class="nav-link active" id="nav-tab-X" data-bs-toggle="tab" data-bs-target="#nav-resultados" type="button" role="tab" aria-controls="nav-resultados" aria-selected="true"><img src="/assets/rh_icon_nonbinary.png" width="14" data-bs-toggle="tooltip" title="Não Binário" style="margin-right: 6px; margin-top: -4px"/>Não Binário</button>
                        </cfif>
                            <!---button class="nav-link" id="nav-charts-tab" data-bs-toggle="tab" data-bs-target="#nav-charts" type="button" role="tab" aria-controls="nav-charts" aria-selected="false">Gráficos</button--->
                        </div>

                    </nav>

                    <!--- CONTEUDO ABAS DOS RESULTADOS --->

                    <div class="tab-content card-principal" id="nav-tabContent">

                        <!--- RESULTADO MASC OU FEM --->

                        <div class="tab-pane fade show active" id="nav-resultados" role="tabpanel" aria-labelledby="nav-tab-F" tabindex="0">

                            <cfinclude template="../includes/resultados.cfm"/>

                        </div>

                        <!--- GRAFICOS

                        <div class="tab-pane fade" id="nav-charts" role="tabpanel" aria-labelledby="nav-charts-tab" tabindex="1">

                            <div class="row my-3 g-3">

                                <div class="col-md-8">
                                    <canvas id="chartPace" style="height: 200px"></canvas>
                                </div>

                                <div class="col-md-4">
                                    <canvas id="chartGenero" style="height: 200px"></canvas>
                                </div>

                            </div>

                            <script>

                                const ctx = document.getElementById('chartPace');
                                const ctxGenero = document.getElementById('chartGenero');

                                const data = {
                                    labels: ['Masculino', 'Feminino', 'Não Binário'],
                                    datasets: [
                                        {
                                            label: 'Gênero',
                                            data: [<cfoutput>#(qStatsPercurso.concluintes[2])#,#(qStatsPercurso.concluintes[1])#</cfoutput>],
                                        }
                                    ]
                                };

                                new Chart(ctx, {
                                    type: 'scatter',
                                    data: {
                                    labels: [<cfloop query="qResultado" endrow="20">'<cfoutput>#timeFormat(qResultado.pace,"mm:ss")#',</cfoutput></cfloop>],
                                    datasets: [{
                                        label: 'PACE',
                                        data: [<cfoutput query="qResultado" maxrows="100">
                                        <cfif len(trim(qResultado.pace))>
                                        {
                                            x: #qResultado.classificacao_sexo#,
                                            y: #timeFormat(qResultado.pace,"m")#.#numberFormat( ( timeFormat(qResultado.pace,"ss")*100/60 ) ,"00")#
                                        },
                                        </cfif>
                                    </cfoutput>],
                                        borderWidth: 1
                                    }]
                                    },
                                    options: {
                                        legend: false,
                                        maintainAspectRatio: false,
                                        scales: {
                                            y: {
                                                beginAtZero: true
                                            }
                                        }
                                    }
                                });

                                new Chart(ctxGenero, {
                                    type: 'pie',
                                    data: data,
                                    options: {
                                        responsive: true,
                                        plugins: {
                                            legend: {
                                                position: 'top',
                                            }
                                        }
                                    }
                                });
                            </script>

                        </div>

                         --->

                    </div>

                <cfelse>

                    <!--- RESULTADOS DA BUSCA --->

                    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mt-3">
                        <h3 class="h6 mb-0">Resultado da Busca por "<cfoutput>#ucase(URL.termo)#</cfoutput>"</h3>

                        <cfif lcase(listFirst(CGI.HTTP_HOST, ":")) EQ "dev.openresults.run">
                            <cfset VARIABLES.resultadoExportBaseUrl = "/exportar-resultados-evento-v2.cfm?id_evento=#qEvento.id_evento#&termo=#urlEncodedFormat(URL.termo)#"/>
                            <cfset VARIABLES.resultadoExportEventoUrl = "/exportar-resultados-evento-v2.cfm?id_evento=#qEvento.id_evento#&escopo=evento"/>
                            <cfoutput>
                                <div class="dropdown">
                                    <button class="btn btn-light btn-sm shadow-0" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                                        <i class="fa-solid fa-download"></i> Exportar
                                    </button>
                                    <ul class="dropdown-menu dropdown-menu-end">
                                        <li><h6 class="dropdown-header">Busca atual</h6></li>
                                        <li><a class="dropdown-item" href="#VARIABLES.resultadoExportBaseUrl#&formato=csv" target="_blank"><i class="fa-solid fa-file-csv me-2"></i>CSV</a></li>
                                        <li><a class="dropdown-item" href="#VARIABLES.resultadoExportBaseUrl#&formato=xls" target="_blank"><i class="fa-solid fa-file-excel me-2"></i>XLS</a></li>
                                        <li><hr class="dropdown-divider"></li>
                                        <li><h6 class="dropdown-header">Evento completo</h6></li>
                                        <li><a class="dropdown-item" href="#VARIABLES.resultadoExportEventoUrl#&formato=csv" target="_blank"><i class="fa-solid fa-file-csv me-2"></i>CSV</a></li>
                                        <li><a class="dropdown-item" href="#VARIABLES.resultadoExportEventoUrl#&formato=xls" target="_blank"><i class="fa-solid fa-file-excel me-2"></i>XLS</a></li>
                                    </ul>
                                </div>
                            </cfoutput>
                        </cfif>
                    </div>

                    <cfinclude template="../includes/resultados.cfm"/>

                </cfif>

                <cfif NOT qEvento.resultado_completo>
                    <div class="alert alert-warning">
                        <cfoutput>Dados restritos aos primeiros 100 colocados, veja o <cfif len(trim(qEvento.url_resultado))><a href="#htmlEditFormat(qEvento.url_resultado)#" target="_blank" rel="noopener" style="text-decoration: underline" data-rr-placement="evento_fonte_top100">resultado oficial do evento</a>, atualizado em #lsdateformat(qProcessamentoResultado.data_processamento_final, "dd/mm/yyyy")#</cfif>.</cfoutput>
                    </div>
                </cfif>

            </cfif>

        </cfif>



    </div>

    <!--- FOOTER --->

    <cfinclude template="../includes/footer.cfm"/>

    <!--- SEO WEB TOOLS --->

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>

<script>
    var resultadoEmDestaque = typeof idline !== 'undefined' ? document.getElementById(idline) : null;
    if (resultadoEmDestaque) {
        resultadoEmDestaque.classList.add('highlight');
    }
</script>

</html>
