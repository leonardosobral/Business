<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/admin/homologacao.cfm"/>

<!--- VARIAVEIS --->
<cfinclude template="includes/variaveis.cfm"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>
<cfinclude template="includes/backend/backend_evento_edicao.cfm"/>
<cfinclude template="includes/backend/backend_homologacao.cfm"/>
<cfinclude template="includes/backend/backend_resultados.cfm"/>


<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - Admin</title>
    <cfinclude template="includes/seo-web-tools-head.cfm"/>

    <style>
        .table-active {
            background-color: #F4B120; !important;
        }
        .table-wrapper {
            max-height: 200px;
            min-height: 200px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-lg {
            max-height: 404px;
            min-height: 404px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
        .table-wrapper-sm {
            max-height: 120px;
            min-height: 120px;
            width: 100%;
            overflow: auto;
            display:inline-block;
        }
    </style>

</head>

<body>

    <cfif NOT isDefined("COOKIE.id")>

        <div class="g-signin2 ms-2" data-onsuccess="onSignIn"></div>

    <cfelse>

        <div class="container-fluid mt-3">


            <!--- HEADER --->

            <cfinclude template="includes/header.cfm"/>


            <!--- WIDGETS --->

            <cfinclude template="widgets_resultados.cfm"/>


            <!--- FILTROS --->

            <cfinclude template="filtro_resultados.cfm"/>


            <!--- PROGRESSO --->

            <div class="progress mb-3" style="height: 18px;">
              <div class="progress-bar bg-success" role="progressbar" style="padding-top: 2px; width: <cfoutput>#VARIABLES.totalHomologado#</cfoutput>%" aria-valuenow="<cfoutput>#VARIABLES.totalHomologado#</cfoutput>" aria-valuemin="0" aria-valuemax="100"><cfoutput>#round(VARIABLES.totalHomologado)#</cfoutput>%</div>
              <div class="progress-bar bg-danger" role="progressbar" style="padding-top: 2px; width: <cfoutput>#VARIABLES.totalNaoHomologado#</cfoutput>%" aria-valuenow="<cfoutput>#VARIABLES.totalNaoHomologado#</cfoutput>" aria-valuemin="0" aria-valuemax="100"><cfoutput>#round(VARIABLES.totalNaoHomologado)#</cfoutput>%</div>
              <div class="progress-bar bg-secondary" role="progressbar" style="padding-top: 2px; width: <cfoutput>#VARIABLES.totalFaltaHomologar#</cfoutput>%" aria-valuenow="<cfoutput>#VARIABLES.totalFaltaHomologar#</cfoutput>" aria-valuemin="0" aria-valuemax="100"><cfoutput>#round(VARIABLES.totalFaltaHomologar)#</cfoutput>%</div>
            </div>


            <!--- LISTAGEM --->

            <div class="row g-3">


                <cfif NOT Len(trim(URL.id_evento))>

                    <div class="col-md-4">

                        <div class="row g-3">

                            <!--- LISTAGEM DE UF --->

                            <div class="col-md-4">

                                <div class="card">

                                    <div class="card-header px-3 py-2">Por UF</div>

                                    <div class="card-body p-2">

                                        <div class="table-wrapper-lg">

                                            <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                                <cfoutput query="qStatsEstado">
                                                    <tr style="cursor: pointer;" <cfif qStatsEstado.estado EQ URL.estado>class="table-active" onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#'"<cfelse>onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&estado=#urlEncodedFormat(qStatsEstado.estado)#'"</cfif> >
                                                        <td>#qStatsEstado.estado#</td>
                                                        <td>#qStatsEstado.total#</td>
                                                    </tr>
                                                </cfoutput>
                                            </table>

                                        </div>

                                    </div>

                                </div>

                            </div>

                            <!--- LISTAGEM DE CIDADE --->

                            <div class="col-md-8">

                                <div class="card">

                                    <div class="card-header px-3 py-2">Por Cidade</div>

                                    <div class="card-body p-2">

                                        <div class="table-wrapper-lg">

                                            <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                                <cfoutput query="qStatsCidade">
                                                    <tr style="cursor: pointer;" <cfif qStatsCidade.cidade EQ URL.cidade>class="table-active"  onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#'"<cfelse>onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&cidade=#urlEncodedFormat(qStatsCidade.cidade)#'"</cfif> >
                                                        <td>#qStatsCidade.cidade# - #qStatsCidade.estado#</td>
                                                        <td>#qStatsCidade.total#</td>
                                                    </tr>
                                                </cfoutput>
                                            </table>

                                        </div>

                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>

                </cfif>


                <!--- LISTAGEM DE EVENTOS --->

                <div class="col-md-<cfif Len(trim(URL.id_evento))>6<cfelse>8</cfif>">

                    <div class="card">

                        <div class="card-header px-3 py-2">
                            Eventos (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)
                            <select onchange="window.location.href='<cfoutput>#VARIABLES.template#?id_agrega_evento=#URL.id_agrega_evento#&estado=#URL.estado#&cidade=#URL.cidade#&periodo=#URL.periodo#&agregador_tag=#URL.agregador_tag#&preset=</cfoutput>' + this.value">>
                                <option value="" <cfif URL.preset EQ "">selected</cfif> >Todos</option>
                                <option value="pendentes" <cfif URL.preset EQ "pendentes">selected</cfif> >Pendentes</option>
                                <option value="homologados" <cfif URL.preset EQ "homologados">selected</cfif> >Homologados</option>
                                <option value="naohomologados" <cfif URL.preset EQ "naohomologados">selected</cfif> >Não Homologados</option>
                            </select>
                        </div>

                        <div class="card-body p-2">

                            <div class="table-wrapper-lg">

                                <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
                                    <tbody>
                                    <cfoutput query="qStatsEvento">
                                    <tr>
                                        <td nowrap>#lsDateFormat(qStatsEvento.data_final, "dd/mm")#</td>
                                        <td>#qStatsEvento.estado#</td>
                                        <!--- EVENTO --->
                                        <td>
                                            <a target="processar" href="https://openresults.run/evento/#qStatsEvento.tag#/"><img src="../assets/or_icon.jpg" class="w-24px rounded-5 shadow-5 me-2"/></a>
                                            <a target="processar" href="https://google.com.br/search?q=#urlEncodedFormat(qStatsEvento.nome_evento)#"><i class="fa-brands fa-google me-2"></i></a>
                                            <a href="#VARIABLES.template#?id_evento=#qStatsEvento.id_evento#&preset=#URL.preset#&busca=#URL.busca#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#">#qStatsEvento.nome_evento#</a>
                                        </td>
                                        <td class="text-end">#lsNumberFormat(qStatsEvento.total)#</td>
                                        <td class="text-end">
                                            <cfif qStatsEvento.homologado EQ "true">
                                                <a href="#VARIABLES.template#?busca=#URL.busca#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#qStatsEvento.id_evento#&acao=naohomologar"><span class="badge bg-success" title="Evento Homologado">H</span></a>
                                            <cfelseif qStatsEvento.homologado EQ "false">
                                                <a href="#VARIABLES.template#?busca=#URL.busca#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#qStatsEvento.id_evento#&acao=homologar"><span class="badge bg-danger" title="Evento não Homologado">H</span></a>
                                            <cfelse>
                                                <a href="#VARIABLES.template#?busca=#URL.busca#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#qStatsEvento.id_evento#&acao=homologar"><span class="badge bg-secondary text-black" title="Homologação">H</span></a>
                                            </cfif>
                                        </td>
                                        <td class="text-end">
                                            <cfif Len(trim(qStatsEvento.ranking)) AND qStatsEvento.ranking EQ "true">
                                                <a href="#VARIABLES.template#?busca=#URL.busca#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#qStatsEvento.id_evento#&acao=naoranking"><span class="badge bg-success" title="Evento no Ranking">R</span></a>
                                            <cfelseif Len(trim(qStatsEvento.ranking)) AND qStatsEvento.ranking EQ "false">
                                                <a href="#VARIABLES.template#?busca=#URL.busca#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#qStatsEvento.id_evento#&acao=ranking"><span class="badge bg-danger" title="Evento não aparece Ranking">R</span></a>
                                            <cfelse>
                                                <a href="#VARIABLES.template#?busca=#URL.busca#&periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#qStatsEvento.id_evento#&acao=ranking"><span class="badge bg-secondary text-black" title="Ranking">R</span></a>
                                            </cfif>
                                        </td>
                                    </tr>
                                    </cfoutput>
                                    </tbody>
                                </table>

                            </div>

                        </div>

                    </div>

                </div>


                <!--- EDICAO DE EVENTO --->

                <cfif Len(trim(URL.id_evento))>

                    <cfinclude template="form_edicao.cfm"/>

                </cfif>

            </div>

        </div>

    </cfif>

    <cfinclude template="includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
