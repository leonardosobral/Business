<!doctype html>
<html lang="pt-br" data-mdb-theme="dark">

<cfprocessingdirective pageencoding="utf-8"/>

<!--- VARIAVEIS --->
<cfinclude template="includes/variaveis.cfm"/>

<!--- BACKEND --->
<cfinclude template="includes/backend/backend_login.cfm"/>
<cfinclude template="includes/backend/backend_stats_or.cfm"/>

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

            <div class="row g-3">
                <div class="col-md-3 mb-3">
                    <div class="card bg-primary py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountHoje.total, "9")#</cfoutput></p>
                        <p class="m-0">Acessos em 24 Horas</p>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card bg-primary py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCount7.total, "9")#</cfoutput></p>
                        <p class="m-0">Em 7 Dias</p>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card bg-primary py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCount30.total, "9")#</cfoutput></p>
                        <p class="m-0">Em 30 Dias</p>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card bg-primary py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountTotal.total, "9")#</cfoutput></p>
                        <p class="m-0">Todo o Período</p>
                    </div>
                </div>
            </div>


            <!--- FILTROS BUSCA --->

            <div class="row">

                <div class="col-md-3 mb-3">

                    <select data-mdb-select-init data-mdb-visible-options="12" class="form-select" onchange="window.location.href='<cfoutput>./stats_or.cfm?regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&preset=</cfoutput>' + this.value">>
                        <option value="" <cfif URL.preset EQ "">selected</cfif> >Todo o Período</option>
                        <option value="hoje" <cfif URL.preset EQ "hoje">selected</cfif> >Hoje</option>
                        <option value="24horas" <cfif URL.preset EQ "24horas">selected</cfif> >24 horas</option>
                        <option value="7dias" <cfif URL.preset EQ "7dias">selected</cfif> >7 dias</option>
                        <option value="30dias" <cfif URL.preset EQ "30dias">selected</cfif> >30 dias</option>
                        <option value="bot" <cfif URL.preset EQ "bot">selected</cfif> >Bots e Crawlers</option>
                    </select>

                </div>

                <div class="col-md-9 mb-3">

                    <form action="" method="get">
                        <input type="text" disabled class="form-control" name="busca" placeholder="busca" value="<cfoutput>#URL.busca#</cfoutput>"/>
                        <input type="hidden" name="preset" value=""/>
                    </form>

                </div>

            </div>


            <!--- ESTATISTICAS --->

            <div class="row g-3">

                <div class="col-md-6">

                    <div class="row g-3">

                        <!--- LISTAGEM DE REGIAO --->

                        <div class="col-md-4">

                            <div class="card">

                                <div class="card-header px-3 py-2">Por Região</div>

                                <div class="card-body p-2">

                                    <div class="table-wrapper">

                                        <table id="tblEventos" class="table table-stripped table-hovered table-condensed table-sm mb-0" >
                                            <cfoutput query="qStatsRegiao">
                                                <tr style="cursor: pointer;" <cfif qStatsRegiao.regiao EQ URL.regiao>class="table-active" onclick="location.href = './stats_or.cfm?preset=#URL.preset#'"<cfelse>onclick="location.href = './stats_or.cfm?preset=#URL.preset#&regiao=#urlEncodedFormat(qStatsRegiao.regiao)#'"</cfif> >
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
                                                <tr style="cursor: pointer;" <cfif qStatsEstado.estado EQ URL.estado>class="table-active" onclick="location.href = './stats_or.cfm?preset=#URL.preset#&regiao=#URL.regiao#'"<cfelse>onclick="location.href = './stats_or.cfm?preset=#URL.preset#&regiao=#URL.regiao#&estado=#urlEncodedFormat(qStatsEstado.estado)#'"</cfif> >
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
                                                <tr style="cursor: pointer;" <cfif qStatsCidade.cidade EQ URL.cidade>class="table-active"  onclick="location.href = './stats_or.cfm?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#'"<cfelse>onclick="location.href = './stats_or.cfm?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#urlEncodedFormat(qStatsCidade.cidade)#'"</cfif> >
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

                                        <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
                                            <cfoutput query="qStatsMaratonas">
                                            <tr>
                                                <td>#qStatsMaratonas.nome_evento_agregado#</td>
                                                <td>#qStatsMaratonas.total#</td>
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
                                            <td>#qStatsCircuitos.total#</td>
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

                                <div class="card-header px-3 py-2">Eventos mais acessados</div>

                                <div class="card-body p-2">

                                    <div class="table-wrapper-lg">
                                        <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
                                            <tbody>
                                            <cfoutput query="qStatsEvento">
                                            <tr>
                                                <td nowrap>#qStatsEvento.data_inicial#</td>
                                                <td>#qStatsEvento.estado#</td>
                                                <!--- EVENTO --->
                                                <td>
                                                    <a target="processar" href="https://roadrunners.run/evento/#qStatsEvento.tag#/"><icon class="fa fa-link me-2"></icon></a>
                                                    <a target="processar" href="https://google.com.br/search?q=#urlEncodedFormat(qStatsEvento.nome_evento)#"><i class="fa-brands fa-google me-2"></i></a>
                                                    <a target="processar" href="./?preset=#URL.preset#&estado=#URL.estado#&id_evento=#qStatsEvento.id_evento#"><i class="fa fa-edit me-2"></i></a>
                                                    #qStatsEvento.nome_evento#
                                                </td>
                                                <td>#qStatsEvento.total#</td>
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
