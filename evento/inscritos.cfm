<!--- WIDGETS TEMPORAIS --->

<div class="row g-3 mb-3">

    <div class="col-md">
        <a href="./?periodo=24horas&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-warning text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountHoje.total, "9")#</cfoutput></p>
            <p class="m-0">Em 24 Horas</p>
        </div>
        </a>
    </div>
    <div class="col-md">
        <a href="./?periodo=7dias&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-warning text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCount7.total, "9")#</cfoutput></p>
            <p class="m-0">Em 7 Dias</p>
        </div>
        </a>
    </div>
    <div class="col-md">
        <a href="./?periodo=28dias&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-warning text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCount28.total, "9")#</cfoutput></p>
            <p class="m-0">Em 28 Dias</p>
        </div>
        </a>
    </div>
    <div class="col-md">
        <a href="./?periodo=novosite&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-43k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountNovoSite.total, "9")#</cfoutput></p>
            <p class="m-0">No Road Runners</p>
        </div>
        </a>
    </div>
    <div class="col-md">
        <a href="./?periodo=&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-warning text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountTotal.total, "9")#</cfoutput></p>
            <p class="m-0">Inscritos</p>
        </div>
        </a>
    </div>
    <cfif URL.preset EQ "2025">
    <div class="col-md">
        <a href="./?periodo=&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-warning text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountPedidos.total, "9")#</cfoutput></p>
            <p class="m-0">Pedidos</p>
        </div>
        </a>
    </div>
    </cfif>

</div>


<!--- WIDGETS PRESETS --->

<cfif URL.periodo EQ "novosite">

    <div class="row g-3 mb-3">

        <div class="col-md-2">
            <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=calendario">
            <div class="card bg-43k py-2 px-3">
                <p class="h4 m-0"><cfoutput>#numberFormat(((qCountCalendario.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                <p class="m-0"><cfoutput>#numberFormat(qCountCalendario.recordCount, "9")#</cfoutput> com Calendário</p>
            </div>
            </a>
        </div>
        <div class="col-md-2">
            <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=resultados">
            <div class="card bg-43k py-2 px-3">
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
            <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=assessoria">
            <div class="card bg-43k py-2 px-3">
                <p class="h4 m-0"><cfoutput>#numberFormat(((qCountAssessoria.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                <p class="m-0"><cfoutput>#numberFormat(qCountAssessoria.recordCount, "9")#</cfoutput> com Assessoria</p>
            </div>
            </a>
        </div>
        <div class="col-md-2">
            <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=cidade">
            <div class="card bg-43k py-2 px-3">
                <p class="h4 m-0"><cfoutput>#numberFormat(((qCountCidade.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                <p class="m-0"><cfoutput>#numberFormat(qCountCidade.recordCount, "9")#</cfoutput> com Cidade</p>
            </div>
            </a>
        </div>
        <div class="col-md-2">
            <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=estado">
            <div class="card bg-43k py-2 px-3">
                <p class="h4 m-0"><cfoutput>#numberFormat(((qCountEstado.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
                <p class="m-0"><cfoutput>#numberFormat(qCountEstado.recordCount, "9")#</cfoutput> com Estado</p>
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

</cfif>


<!--- FILTROS BUSCA --->

<div class="row my-3">

    <div class="col">

        <form action="" method="get">
            <input type="text" class="form-control" name="busca" placeholder="busca" value="<cfoutput>#URL.busca#</cfoutput>"/>
            <input type="hidden" name="preset" value=""/>
        </form>

    </div>

</div>


<!--- LISTAGENS --->

<div class="row g-3">

    <div class="col-md-4">

        <div class="row g-3">

            <!--- LISTAGEM DE REGIAO --->

            <div class="col-md-8">

                <div class="card">

                    <div class="card-header px-3 py-2">Por Região</div>

                    <div class="card-body p-2">

                        <div class="table-wrapper">

                            <table id="tblEventos" class="table table-stripped table-hovered table-condensed table-sm mb-0" >
                                <cfoutput query="qStatsRegiao">
                                    <tr style="cursor: pointer;" <cfif qStatsRegiao.regiao EQ URL.regiao>class="table-active" onclick="location.href = '././?preset=#URL.preset#'"<cfelse>onclick="location.href = '././?preset=#URL.preset#&regiao=#urlEncodedFormat(qStatsRegiao.regiao)#'"</cfif> >
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

            <div class="col-md-4">

                <div class="card">

                    <div class="card-header px-3 py-2">Por UF</div>

                    <div class="card-body p-2">

                        <div class="table-wrapper">

                            <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0" >
                                <cfoutput query="qStatsEstado">
                                    <tr style="cursor: pointer;" <cfif qStatsEstado.estado EQ URL.estado>class="table-active" onclick="location.href = '././?preset=#URL.preset#&regiao=#URL.regiao#'"<cfelse>onclick="location.href = '././?preset=#URL.preset#&regiao=#URL.regiao#&estado=#urlEncodedFormat(qStatsEstado.estado)#'"</cfif> >
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
                                    <tr style="cursor: pointer;" <cfif qStatsCidade.cidade EQ URL.cidade>class="table-active"  onclick="location.href = '././?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#'"<cfelse>onclick="location.href = '././?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#urlEncodedFormat(qStatsCidade.cidade)#'"</cfif> >
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

                    <div class="card-header px-3 py-2">Usuários <cfoutput>(#qStatsEvento.recordcount#)</cfoutput></div>

                    <div class="card-body p-2">

                        <div class="table-wrapper-lg">

                            <table id="tblEventos" class="table table-stripped table-condensed table-sm mb-0">
                                <tbody>
                                <cfoutput query="qStatsEvento">
                                <tr style="font-size: smaller;">
                                    <td nowrap>#id#</td>
                                    <td nowrap>#lsDateFormat(qStatsEvento.data_pedido, "yyyy-mm-dd")# #lsTimeFormat(qStatsEvento.data_pedido, "HH:mm")#</td>
                                    <td>#qStatsEvento.estado#</td>
                                    <!--- EVENTO --->
                                    <td>
                                        <a target="processar" href="https://roadrunners.run/atleta/#qStatsEvento.tag_usuario#/"><icon class="fa fa-link me-2"></icon></a>
                                        <!---<a target="processar" href="./?preset=#URL.preset#&estado=#URL.estado#&id=#qStatsEvento.id#"><i class="fa fa-edit me-2"></i></a>--->
                                        #qStatsEvento.name#
                                    </td>
                                    <td>
                                        #qStatsEvento.email#
                                    </td>
                                    <td>
                                        #qStatsEvento.checkin#
                                    </td>
                                    <td>
                                        #qStatsEvento.resultados#
                                    </td>
                                    <td><cfif len(trim(qStatsEvento.strava_code))><a target="_blank" href="https://www.strava.com/athletes/#strava_id#/"><div class="badge bg-strava"><i class="fa-brands fa-strava"></i></div></a></cfif></td>
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
