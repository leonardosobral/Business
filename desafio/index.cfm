<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.template = "365"/>

<!--- VARIAVEIS --->
<cfparam name="URL.periodo" default="pendentes"/>
<cfparam name="URL.preset" default=""/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>

<!--- BACKEND --->
<cfinclude template="../backend_login.cfm"/>
<cfinclude template="backend_365.cfm"/>

<!--- HEAD --->
<head>

    <!--- REQUIRED META TAGS --->
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>

    <title>Runner Hub - BI</title>
    <cfinclude template="../includes/seo-web-tools-head.cfm"/>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css">

    <style>
        a {
            color: #333333;
        }
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

<body class="bg-body-secondary">

    <cfif NOT isDefined("COOKIE.id")>

        <div class="g-signin2 ms-2" data-onsuccess="onSignIn"></div>

    <cfelse>

        <div class="container-fluid mt-3">


            <!--- HEADER --->

            <cfinclude template="header_desafio.cfm"/>

            <!--- WIDGETS TEMPORAIS --->

            <div class="row g-3 mb-3">

                <div class="col-md">
                    <a href="./?periodo=nodesafio">
                    <div class="card bg-10k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qNoDesafio.total, "9")#/#numberFormat(qCountNovoSite.total, "9")#</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat((qNoDesafio.total*100)/qCountNovoSite.total, "9,9")#% Correndo todo dia</cfoutput></p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./?periodo=vip">
                    <div class="card bg-21k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountvip.total, "9")#</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat((qCountvip.total*100)/qCountNovoSite.total, "9,9")#% VIP</cfoutput></p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./?periodo=novosite">
                    <div class="card bg-5k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountNovoSite.total, "9")#</cfoutput></p>
                        <p class="m-0">Confirmados</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./?periodo=pendentes">
                    <div class="card bg-42k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountHoje.total, "9")#</cfoutput></p>
                        <p class="m-0">Pendentes</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./?periodo=">
                    <div class="card bg-43k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountTotal.total, "9")#</cfoutput></p>
                        <p class="m-0">Todos os Inscritos</p>
                    </div>
                    </a>
                </div>

            </div>


            <!--- WIDGETS PRESETS --->

            <!---div class="row g-3 mb-3">

                <div class="col-md-2">
                    <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=calendario">
                    <div class="card <cfif URL.periodo EQ "novosite">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCountCalendario.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCountCalendario.recordCount, "9")#</cfoutput> com Calendário</p>
                    </div>
                    </a>
                </div>
                <div class="col-md-2">
                    <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=resultados">
                    <div class="card <cfif URL.periodo EQ "novosite">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCountResultados.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCountResultados.recordCount, "9")#</cfoutput> com Resultados</p>
                    </div>
                    </a>
                </div>
                <div class="col-md-2">
                    <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=strava">
                    <div class="card bg-strava py-2 px-3">
                        <div class="d-flex">
                            <i class="fa-brands fa-strava h1 me-2"></i>
                            <div class="col">
                                <p class="h4 m-0"><cfoutput>#numberFormat(((qCountStrava.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                                <p class="m-0"><cfoutput>#numberFormat(qCountStrava.recordCount, "9")#</cfoutput> com Strava</p>
                            </div>
                        </div>
                    </div>
                    </a>
                </div>
                <div class="col-md-2">
                    <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=30dias">
                    <div class="card <cfif URL.periodo EQ "novosite">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount30Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount30Dias.recordCount, "9")#</cfoutput> correram 30 Dias</p>
                    </div>
                    </a>
                </div>
                <div class="col-md-2">
                    <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=cidade">
                    <div class="card <cfif URL.periodo EQ "novosite">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCountCidade.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCountCidade.recordCount, "9")#</cfoutput> correram 100 Dias</p>
                    </div>
                    </a>
                </div>
                <div class="col-md-2">
                    <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=estado">
                    <div class="card <cfif URL.periodo EQ "novosite">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCountEstado.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCountEstado.recordCount, "9")#</cfoutput> correram 200 Dias</p>
                    </div>
                    </a>
                </div>

            </div--->


            <!--- WIDGETS STRAVA --->

            <!---cfif len(trim(URL.preset)) AND URL.preset EQ "strava">

                <div class="row g-3">

                    <div class="col">
                        <div class="card bg-strava text-black py-2 px-3">
                            <p class="m-0"><cfoutput>#numberFormat(((qStravaPremium.recordCount*100)/qCountStrava.recordCount), "9.9")#%</cfoutput> premium</p>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card bg-strava text-black py-2 px-3">
                            <p class="m-0"><cfoutput>#numberFormat(qStravaWeight.strava_weight, "9.9")#kg</cfoutput> peso/usu</p>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card bg-strava text-black py-2 px-3">
                            <p class="m-0"><cfoutput>#numberFormat(qStravaFollowers.strava_full_follower_count, "9")#</cfoutput> followers/usu</p>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card bg-strava text-black py-2 px-3">
                            <p class="m-0"><cfoutput>#numberFormat(qStravaFriends.strava_full_friend_count, "9")#</cfoutput> friends/usu</p>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card bg-strava text-black py-2 px-3">
                            <p class="m-0"><cfoutput>#numberFormat(VARIABLES.shoeCount/qStravaShoes.recordCount, "9.9")#</cfoutput> tênis/usu</p>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card bg-strava text-black py-2 px-3">
                            <p class="m-0"><cfoutput>#numberFormat(VARIABLES.shoeKm/VARIABLES.shoeCount, "9.9")#</cfoutput> km/tênis</p>
                        </div>
                    </div>

                    <div class="col">
                        <div class="card bg-strava text-black py-2 px-3">
                            <p class="m-0"><cfoutput>#numberFormat(VARIABLES.clubCount/qStravaClubs.recordCount, "9.9")#</cfoutput> clubs/usu</p>
                        </div>
                    </div>

                </div>

            </cfif--->


            <!--- FILTROS BUSCA --->

            <!---div class="row my-3">

                <div class="col">

                    <form action="" method="get">
                        <input type="text" class="form-control" name="busca" placeholder="busca" value="<cfoutput>#URL.busca#</cfoutput>"/>
                        <input type="hidden" name="preset" value=""/>
                    </form>

                </div>

            </div--->


            <!--- ESTATISTICAS --->

            <div class="row g-3">


                <cfif URL.periodo NEQ "pendentes">

                    <div class="col-md-4">

                        <div class="row g-3">

                            <!--- LISTAGEM DE REGIAO --->

                            <div class="col-md-9">

                                <div class="card">

                                    <div class="card-header px-3 py-2">Por Região</div>

                                    <div class="card-body p-2">

                                        <div class="table-wrapper">

                                            <table id="tblEventos" class="table table-stripped table-hovered table-condensed table-sm mb-0" >
                                                <cfoutput query="qStatsRegiao">
                                                    <tr style="cursor: pointer;" <cfif qStatsRegiao.regiao EQ URL.regiao>class="table-active" onclick="location.href = './?periodo=#URL.periodo#&preset=#URL.preset#'"<cfelse>onclick="location.href = './?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#urlEncodedFormat(qStatsRegiao.regiao)#'"</cfif> >
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

                            <div class="col-md-3">

                                <div class="card">

                                    <div class="card-header px-3 py-2">Por UF</div>

                                    <div class="card-body p-2">

                                        <div class="table-wrapper">

                                            <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                                <cfoutput query="qStatsEstado">
                                                    <tr style="cursor: pointer;" <cfif qStatsEstado.estado EQ URL.estado>class="table-active" onclick="location.href = './?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#'"<cfelse>onclick="location.href = './?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#&estado=#urlEncodedFormat(qStatsEstado.estado)#'"</cfif> >
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

                            <div class="col-md-12">

                                <div class="card">

                                    <div class="card-header px-3 py-2">Por Cidade</div>

                                    <div class="card-body p-2">

                                        <div class="table-wrapper-sm">

                                            <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                                <cfoutput query="qStatsCidade">
                                                    <tr style="cursor: pointer;" <cfif qStatsCidade.cidade EQ URL.cidade>class="table-active"  onclick="location.href = './?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#'"<cfelse>onclick="location.href = './?periodo=#URL.periodo#&reset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#urlEncodedFormat(qStatsCidade.cidade)#'"</cfif> >
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

                <div class="<cfif URL.periodo NEQ "pendentes">col-md-8<cfelse>col-md-12</cfif>">

                    <div class="row g-3">

                        <!--- LISTAGEM --->

                        <div class="col-md-12">

                            <div class="card">

                                <div class="card-header px-3 py-2">Atletas (<cfoutput>#qStatsBase.recordcount#</cfoutput>)</div>

                                <div class="card-body p-2">

                                    <cfif URL.periodo NEQ "pendentes">

                                        <cfquery name="qStatsEvento" dbtype="query">
                                            select *
                                            from qStatsBase
                                        </cfquery>

                                        <cfinclude template="tabels_usuarios_padrao.cfm"/>

                                    <cfelse>

                                        <ul class="nav nav-tabs mb-3" id="ex1" role="tablist">
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm is null
                                            </cfquery>
                                          <li class="nav-item" role="presentation">
                                            <a data-mdb-tab-init
                                              class="nav-link active"
                                              id="ex1-tab-1"
                                              href="#ex1-tabs-1"
                                              role="tab"
                                              aria-controls="ex1-tabs-1"
                                              aria-selected="true">Pendentes de Interação (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                                          </li>
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm = 'sem strava'
                                            </cfquery>
                                          <li class="nav-item" role="presentation">
                                            <a data-mdb-tab-init
                                              class="nav-link"
                                              id="ex1-tab-2"
                                              href="#ex1-tabs-2"
                                              role="tab"
                                              aria-controls="ex1-tabs-2"
                                              aria-selected="false">Sem Strava (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                                          </li>
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm = 'sem pedido'
                                            </cfquery>
                                          <li class="nav-item" role="presentation">
                                            <a data-mdb-tab-init
                                              class="nav-link"
                                              id="ex1-tab-3"
                                              href="#ex1-tabs-3"
                                              role="tab"
                                              aria-controls="ex1-tabs-3"
                                              aria-selected="false">Sem Pedido (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                                          </li>
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm = 'pagamento negado'
                                            </cfquery>
                                          <li class="nav-item" role="presentation">
                                            <a data-mdb-tab-init
                                              class="nav-link"
                                              id="ex1-tab-4"
                                              href="#ex1-tabs-4"
                                              role="tab"
                                              aria-controls="ex1-tabs-4"
                                              aria-selected="false">Pagamento Negado (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                                          </li>
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm = 'pagamento expirado'
                                            </cfquery>
                                          <li class="nav-item" role="presentation">
                                            <a data-mdb-tab-init
                                              class="nav-link"
                                              id="ex1-tab-5"
                                              href="#ex1-tabs-5"
                                              role="tab"
                                              aria-controls="ex1-tabs-5"
                                              aria-selected="false">Pagamento Expirado (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                                          </li>
                                        </ul>

                                        <div class="tab-content" id="ex1-content">
                                          <div class="tab-pane fade show active" id="ex1-tabs-1" role="tabpanel" aria-labelledby="ex1-tab-1">
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm is null
                                                order by id
                                            </cfquery>
                                            <cfinclude template="tabels_usuarios_padrao.cfm"/>
                                          </div>
                                          <div class="tab-pane fade" id="ex1-tabs-2" role="tabpanel" aria-labelledby="ex1-tab-2">
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm = 'sem strava'
                                                order by nome
                                            </cfquery>
                                            <cfinclude template="tabels_usuarios_padrao.cfm"/>
                                          </div>
                                          <div class="tab-pane fade" id="ex1-tabs-3" role="tabpanel" aria-labelledby="ex1-tab-3">
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm = 'sem pedido'
                                                order by dias_correndo desc
                                            </cfquery>
                                            <cfinclude template="tabels_usuarios_padrao.cfm"/>
                                          </div>
                                          <div class="tab-pane fade" id="ex1-tabs-4" role="tabpanel" aria-labelledby="ex1-tab-4">
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm = 'pagamento negado'
                                                order by dias_correndo desc
                                            </cfquery>
                                            <cfinclude template="tabels_usuarios_padrao.cfm"/>
                                          </div>
                                          <div class="tab-pane fade" id="ex1-tabs-5" role="tabpanel" aria-labelledby="ex1-tab-5">
                                            <cfquery name="qStatsEvento" dbtype="query">
                                                select *
                                                from qStatsBase
                                                where status_crm = 'pagamento expirado'
                                                order by dias_correndo desc
                                            </cfquery>
                                            <cfinclude template="tabels_usuarios_padrao.cfm"/>
                                          </div>
                                        </div>

                                    </cfif>

                                </div>

                            </div>

                        </div>

                    </div>

                </div>

            </div>

        </div>

    </cfif>

    <cfinclude template="../includes/footer_parceiro.cfm"/>

    <a href="https://wa.me/5548991534589"
       style="position: fixed;
            width: 52px;
            height: 52px;
            bottom: 20px;
            right: 20px;
            background-color: #25d366;
            color: #FFF;
            border-radius: 50px;
            text-align: center;
            font-size: 36px;
            box-shadow: 1px 1px 2px #888;
            z-index: 1000;" target="_blank">
        <i style="margin-top:8px" class="fa fa-whatsapp"></i>
    </a>

    <cfinclude template="../includes/seo-web-tools-body-end.cfm"/>

</body>

</html>
