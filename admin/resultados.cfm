<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- TEMPLATE --->
<cfset VARIABLES.template = "/admin/resultados.cfm"/>

<!--- VARIAVEIS --->
<cfinclude template="includes/variaveis.cfm"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>
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


            <!--- ESTATISTICAS --->

            <div class="row g-3">

                <div class="col-md-6">

                    <div class="row g-3">

                        <!--- LISTAGEM DE REGIAO --->

                        <div class="col-md-4">

                            <div class="card">

                                <div class="card-header px-3 py-2">Eventos por Região</div>

                                <div class="card-body p-2">

                                    <div class="table-wrapper">

                                        <table id="tblEventos" class="table table-stripped table-hovered table-condensed table-sm mb-0" >
                                            <cfoutput query="qStatsRegiao">
                                                <tr style="cursor: pointer;" <cfif qStatsRegiao.regiao EQ URL.regiao>class="table-active" onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#'"<cfelse>onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&regiao=#urlEncodedFormat(qStatsRegiao.regiao)#'"</cfif> >
                                                    <td>#qStatsRegiao.regiao#</td>
                                                    <td>#qStatsRegiao.total#</td>
                                                </tr>
                                            </cfoutput>
                                        </table>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!--- LISTAGEM DE UF --->

                        <div class="col-md-2">

                            <div class="card">

                                <div class="card-header px-3 py-2">Por UF</div>

                                <div class="card-body p-2">

                                    <div class="table-wrapper">

                                        <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                            <cfoutput query="qStatsEstado">
                                                <tr style="cursor: pointer;" <cfif qStatsEstado.estado EQ URL.estado>class="table-active" onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&regiao=#URL.regiao#'"<cfelse>onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#urlEncodedFormat(qStatsEstado.estado)#'"</cfif> >
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

                        <div class="col-md-6">

                            <div class="card">

                                <div class="card-header px-3 py-2">Por Cidade</div>

                                <div class="card-body p-2">

                                    <div class="table-wrapper">

                                        <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                            <cfoutput query="qStatsCidade">
                                                <tr style="cursor: pointer;" <cfif qStatsCidade.cidade EQ URL.cidade>class="table-active"  onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#'"<cfelse>onclick="location.href = '#VARIABLES.template#?periodo=#URL.periodo#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#urlEncodedFormat(qStatsCidade.cidade)#'"</cfif> >
                                                    <td>#qStatsCidade.cidade# - #qStatsCidade.estado#</td>
                                                    <td>#qStatsCidade.total#</td>
                                                </tr>
                                            </cfoutput>
                                        </table>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!--- LISTAGEM DE MARATONAS --->

                        <div class="col-md-6">

                            <div class="card">

                                <div class="card-header px-3 py-2">Maratonas e Corridas</div>

                                <div class="card-body p-2">

                                    <div class="table-wrapper-sm">

                                        <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                            <cfoutput query="qStatsMaratonas">
                                            <tr>
                                                <td>#qStatsMaratonas.nome_evento_agregado#</td>
                                                <td class="text-end">#lsNumberFormat(qStatsMaratonas.total)#</td>
                                            </tr>
                                            </cfoutput>
                                        </table>

                                    </div>

                                </div>

                            </div>

                        </div>

                        <!--- LISTAGEM DE CIRCUITOS --->

                        <div class="col-md-6">

                        <div class="card">

                            <div class="card-header px-3 py-2">Circuitos</div>

                            <div class="card-body p-2">

                                <div class="table-wrapper-sm">

                                    <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                        <cfoutput query="qStatsCircuitos">
                                        <tr>
                                            <td>#qStatsCircuitos.nome_evento_agregado#</td>
                                            <td class="text-end">#lsNumberFormat(qStatsCircuitos.total)#</td>
                                        </tr>
                                        </cfoutput>
                                    </table>

                                </div>

                            </div>

                        </div>

                    </div>

                    </div>

                </div>

                <div class="col-md-6">

                    <div class="row g-3">

                        <!--- LISTAGEM DE EVENTOS --->

                        <div class="col-md-12">

                            <div class="card">

                                <div class="card-header px-3 py-2">Eventos com mais concluintes</div>

                                <div class="card-body p-2">

                                    <div class="table-wrapper-lg">

                                        <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
                                            <tbody>
                                            <cfoutput query="qStatsEvento">
                                            <tr>
                                                <td nowrap>#qStatsEvento.currentrow#º</td>
                                                <td nowrap>#lsDateFormat(qStatsEvento.data_final, "dd/mm")#</td>
                                                <td>#qStatsEvento.estado#</td>
                                                <!--- EVENTO --->
                                                <td>
                                                    <a target="processar" href="https://openresults.run/evento/#qStatsEvento.tag#/"><img src="../assets/or_icon.jpg" class="w-24px rounded-5 shadow-5 me-2"/></a>
                                                    <a target="processar" href="https://google.com.br/search?q=#urlEncodedFormat(qStatsEvento.nome_evento)#"><i class="fa-brands fa-google me-2"></i></a>
                                                    <a target="processar" href="./?id_evento=#qStatsEvento.id_evento#"><i class="fa fa-edit me-2"></i></a>
                                                    #qStatsEvento.nome_evento#
                                                </td>
                                                <td class="text-end">#lsNumberFormat(qStatsEvento.total)#</td>
                                            </tr>
                                            </cfoutput>
                                            </tbody>
                                        </table>

                                    </div>

                                </div>

                            </div>

                        </div>

                    </div>

                </div>

            </div>

        </div>

    </cfif>

    <cfinclude template="includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
