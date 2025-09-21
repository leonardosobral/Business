<!doctype html>
<html lang="pt-br">

<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.template = "366"/>

<!--- VARIAVEIS --->
<cfparam name="URL.periodo" default="novosite"/>
<cfparam name="URL.preset" default=""/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>

<!--- BACKEND --->
<cfinclude template="../backend_login.cfm"/>
<cfinclude template="backend_366.cfm"/>

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
                    <a href="./366.cfm?periodo=aptos">
                    <div class="card bg-21k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountAptos.total, "9")#</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat((qCountAptos.total*100)/qCountTotal.total, "9,9")#% Migraram</cfoutput></p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=novosite">
                    <div class="card bg-5k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountNovoSite.total, "9")#</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat((qCountNovoSite.total*100)/qCountTotal.total, "9,9")#% Participaram</cfoutput></p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=">
                    <div class="card bg-43k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountTotal.total, "9")#</cfoutput></p>
                        <p class="m-0">Todos os Inscritos</p>
                    </div>
                    </a>
                </div>

            </div>


            <!--- WIDGETS PRESETS --->

            <div class="row g-3 mb-3">

                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=1dia">
                    <div class="card <cfif URL.periodo EQ "1dia">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "aptos">bg-21k<cfelseif URL.periodo EQ "novosite">bg-5k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount1Dia.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount1Dia.recordCount, "9")#</cfoutput> 1º Dia</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=7dias">
                    <div class="card <cfif URL.periodo EQ "7dias">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "aptos">bg-21k<cfelseif URL.periodo EQ "novosite">bg-5k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount7Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount7Dias.recordCount, "9")#</cfoutput> 7 Dias</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=15dias">
                    <div class="card <cfif URL.periodo EQ "7dias">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "aptos">bg-21k<cfelseif URL.periodo EQ "novosite">bg-5k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount15Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount15Dias.recordCount, "9")#</cfoutput> 15 Dias</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=30dias">
                    <div class="card <cfif URL.periodo EQ "7dias">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "aptos">bg-21k<cfelseif URL.periodo EQ "novosite">bg-5k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount30Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount30Dias.recordCount, "9")#</cfoutput> 30 Dias</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=90dias">
                    <div class="card <cfif URL.periodo EQ "7dias">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "aptos">bg-21k<cfelseif URL.periodo EQ "novosite">bg-5k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount90Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount90Dias.recordCount, "9")#</cfoutput> 90 Dias</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=180dias">
                    <div class="card <cfif URL.periodo EQ "7dias">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "aptos">bg-21k<cfelseif URL.periodo EQ "novosite">bg-5k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount180Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount180Dias.recordCount, "9")#</cfoutput> 180 Dias</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=270dias">
                    <div class="card <cfif URL.periodo EQ "7dias">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "aptos">bg-21k<cfelseif URL.periodo EQ "novosite">bg-5k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount270Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount270Dias.recordCount, "9")#</cfoutput> 270 Dias</p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=nodesafio">
                    <div class="card <cfif URL.periodo EQ "7dias">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "aptos">bg-21k<cfelseif URL.periodo EQ "novosite">bg-5k</cfif> py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(qCountNoDesafio.recordCount, "9")#</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat((qCountNoDesafio.recordCount*100)/qPeriodo.recordCount, "9,9")#% No Desafio</cfoutput></p>
                    </div>
                    </a>
                </div>
                <div class="col-md">
                    <a href="./366.cfm?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=366dias">
                    <div class="card bg-10k py-2 px-3">
                        <p class="h4 m-0"><cfoutput>#numberFormat(((qCount366Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                        <p class="m-0"><cfoutput>#numberFormat(qCount366Dias.recordCount, "9")#</cfoutput> 366 Dias</p>
                    </div>
                    </a>
                </div>


            </div>


            <!--- WIDGETS STRAVA --->

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


            <!--- FILTROS BUSCA --->

            <div class="row my-3">

                <div class="col">

                    <form action="" method="get">
                        <input type="text" class="form-control" name="busca" placeholder="busca" value="<cfoutput>#URL.busca#</cfoutput>"/>
                        <input type="hidden" name="preset" value=""/>
                    </form>

                </div>

            </div>


            <!--- ESTATISTICAS --->

            <div class="row g-3">

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
                                                <tr style="cursor: pointer;" <cfif qStatsRegiao.regiao EQ URL.regiao>class="table-active" onclick="location.href = './366.cfm?periodo=#URL.periodo#&preset=#URL.preset#'"<cfelse>onclick="location.href = './366.cfm?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#urlEncodedFormat(qStatsRegiao.regiao)#'"</cfif> >
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
                                                <tr style="cursor: pointer;" <cfif qStatsEstado.estado EQ URL.estado>class="table-active" onclick="location.href = './366.cfm?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#'"<cfelse>onclick="location.href = './366.cfm?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#&estado=#urlEncodedFormat(qStatsEstado.estado)#'"</cfif> >
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
                                                <tr style="cursor: pointer;" <cfif qStatsCidade.cidade EQ URL.cidade>class="table-active"  onclick="location.href = './366.cfm?periodo=#URL.periodo#&preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#'"<cfelse>onclick="location.href = './366.cfm?periodo=#URL.periodo#&reset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#urlEncodedFormat(qStatsCidade.cidade)#'"</cfif> >
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

                <div class="col-md-8">

                    <div class="row g-3">

                        <!--- LISTAGEM --->

                        <div class="col-md-12">

                            <div class="card">

                                <div class="card-header px-3 py-2">Atletas (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</div>

                                <div class="card-body p-2">

                                    <div class="table-wrapper-lg">
                                        <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
                                            <tr>
                                                <td>#</td>
                                                <!---td>ID</td--->
                                                <td>ID</td>
                                                <td>UF</td>
                                                <td>Nome</td>
                                                <td class="text-end">KM</td>
                                                <!---td class="text-end">Última</td--->
                                                <td class="text-end">Dias</td>
                                                <td class="text-center">Atualizar</td>
                                            </tr>
                                            <tbody>
                                            <cfoutput query="qStatsEvento">
                                            <tr style="font-size: small;">
                                                <td nowrap>#qStatsEvento.currentRow#</td>
                                                <!---td nowrap>#num_inscricao#</td--->
                                                <td nowrap>#id#</td>
                                                <!---td nowrap>#lsDateFormat(qStatsEvento.data_criacao, "yyyy-mm-dd")# #lsTimeFormat(qStatsEvento.data_criacao, "HH:mm")#</td--->
                                                <td>#qStatsEvento.estado#</td>
                                                <!--- EVENTO --->
                                                <td>
                                                    <a target="_blank" href="https://roadrunners.run/atleta/#qStatsEvento.tag#/?filtro=desafios"><img src="../../assets/rr_icon.jpg" width="24" class="shadow-5 px-1"></a>
                                                    <cfif len(trim(qStatsEvento.strava_code))><a target="_blank" href="https://www.strava.com/athletes/#strava_id#/"><div class="badge bg-strava me-1"><i class="fa-brands fa-strava"></i></div></a></cfif>
                                                    #qStatsEvento.name#
                                                </td>
                                                <!---td>
                                                    #qStatsEvento.email#
                                                </td--->
                                                <td class="text-end"><cfif len(trim(distancia_percorrida))>#numberFormat(distancia_percorrida/1000, "9.9")#km</cfif></td>
                                                <!---td class="text-end">#ultimo_dia#</td--->
                                                <td class="text-end"><cfif len(trim(distancia_percorrida))>#dias_correndo#/#dias_do_ano#</cfif></td>
                                                <td class="text-start">
                                                    <cfif len(trim(qStatsEvento.strava_code))><a target="_blank" href="https://roadrunners.run/api/strava/atualizar/?id_usuario=#id#&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23&debug=true"><div class="badge bg-strava"><i class="fa fa-refresh"></i></div></a> <a target="_blank" href="https://roadrunners.run/api/strava/atualizar/?id_usuario=#id#&token=jf8w3ynr73840rync848udq07yrc89q2h4nr08ync743c9r8h328f42fc8n23&debug=true&full=true"><div class="badge bg-black me-1"><i class="fa fa-refresh"></i></div></a>
                                                    <cfif len(trim(ultima_atividade))> há <cfif DateDiff("n",ultima_atividade, now()) LT 120>#DateDiff("n",ultima_atividade, now())# min<cfelse>#DateDiff("h",ultima_atividade, now())# horas</cfif> | </cfif>
                                                    <cfif len(trim(strava_expires_at))> <cfif DateDiff("n",strava_expires_at, now()) LT 0>#DateDiff("n",strava_expires_at, now()) * -1# min válido<cfelse><span class="text-danger">token expirado</span></cfif></cfif></cfif>
                                                </td>
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
