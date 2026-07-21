<!--- VARIAVEIS --->
<cfset VARIABLES.challengePeriodWasProvided = structKeyExists(URL, "periodo")/>
<cfparam name="URL.periodo" default="pendentes"/>
<cfparam name="URL.preset" default=""/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.regiao" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.cidade" default=""/>
<cfparam name="URL.genero" default=""/>
<cfparam name="URL.medalha" default=""/>
<cfparam name="URL.desafio" default="todosantodia"/>

<!--- TAG PARAM TREAT --->
<cfset URL.desafio = trim(replace(URL.desafio, '/', ''))/>
<cfif NOT VARIABLES.challengePeriodWasProvided
    AND listFindNoCase("catarinensecorridaderua,catarinensetrailrun", URL.desafio)>
    <cfset URL.periodo = ""/>
</cfif>

<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>
<cfset VARIABLES.challengeConfirmedTotal = 0/>
<cfset VARIABLES.challengeNoTotal = 0/>
<cfset VARIABLES.challengePendingChallengeTotal = 0/>
<cfset VARIABLES.challengeVipTotal = 0/>
<cfif qCountConfirmados.recordcount GT 0 AND NOT isNull(qCountConfirmados.total)><cfset VARIABLES.challengeConfirmedTotal = val(qCountConfirmados.total)/></cfif>
<cfif qNoDesafio.recordcount GT 0 AND NOT isNull(qNoDesafio.total)><cfset VARIABLES.challengeNoTotal = val(qNoDesafio.total)/></cfif>
<cfif qPendenteDesafio.recordcount GT 0 AND NOT isNull(qPendenteDesafio.total)><cfset VARIABLES.challengePendingChallengeTotal = val(qPendenteDesafio.total)/></cfif>
<cfif qCountVip.recordcount GT 0 AND NOT isNull(qCountVip.total)><cfset VARIABLES.challengeVipTotal = val(qCountVip.total)/></cfif>

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

<cfif VARIABLES.challengeIsCatarinenseCircuit>
    <cfinclude template="includes/catarinense_panel.cfm"/>
<cfelse>


<!--- WIDGETS TEMPORAIS --->

<div class="row g-2 mb-2">

    <div class="col-md">
        <a href="./?periodo=nodesafio">
        <div class="card bg-5k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(VARIABLES.challengeNoTotal, "9")#/#numberFormat(VARIABLES.challengeConfirmedTotal, "9")#</cfoutput></p>
            <p class="m-0"><cfoutput>#VARIABLES.challengeConfirmedTotal GT 0 ? numberFormat((VARIABLES.challengeNoTotal*100)/VARIABLES.challengeConfirmedTotal, "9,9") : 0#% <cfif VARIABLES.challengeIsRaceParticipation>com #VARIABLES.challengeCircuitCompletionTarget# <cfif VARIABLES.challengeIsBrasilGigante>provas<cfelse>etapas</cfif><cfelse>no desafio</cfif></cfoutput></p>
        </div>
        </a>
    </div>

    <div class="col-md">
        <a href="./?periodo=pendentedesafio">
        <div class="card bg-8k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(VARIABLES.challengePendingChallengeTotal, "9")#/#numberFormat(VARIABLES.challengeConfirmedTotal, "9")#</cfoutput></p>
            <p class="m-0"><cfoutput>#VARIABLES.challengeConfirmedTotal GT 0 ? numberFormat((VARIABLES.challengePendingChallengeTotal*100)/VARIABLES.challengeConfirmedTotal, "9,9") : 0#% <cfif VARIABLES.challengeIsRaceParticipation>com <cfif VARIABLES.challengeIsBrasilGigante>provas<cfelse>etapas</cfif></cfif><cfif NOT VARIABLES.challengeIsRaceParticipation>correndo</cfif></cfoutput></p>
        </div>
        </a>
    </div>

    <cfif qCountVip.recordcount>
    <div class="col-md">
        <a href="./?periodo=vip">
        <div class="card bg-21k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(VARIABLES.challengeVipTotal, "9")#</cfoutput></p>
            <p class="m-0"><cfoutput>#VARIABLES.challengeConfirmedTotal GT 0 ? numberFormat((VARIABLES.challengeVipTotal*100)/VARIABLES.challengeConfirmedTotal, "9,9") : 0#% VIP</cfoutput></p>
        </div>
        </a>
    </div>
    </cfif>

    <div class="col-md">
        <a href="./?periodo=confirmados">
        <div class="card bg-10k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountConfirmados.total, "9")#</cfoutput></p>
            <p class="m-0">Confirmados</p>
        </div>
        </a>
    </div>

    <div class="col-md">
        <a href="./?periodo=pendentes">
        <div class="card bg-42k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountPendentes.total, "9")#</cfoutput></p>
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
        <div class="card <cfif URL.periodo EQ "confirmados">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(((qCountCalendario.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
            <p class="m-0"><cfoutput>#numberFormat(qCountCalendario.recordCount, "9")#</cfoutput> com Calendário</p>
        </div>
        </a>
    </div>
    <div class="col-md-2">
        <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=resultados">
        <div class="card <cfif URL.periodo EQ "confirmados">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
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
        <div class="card <cfif URL.periodo EQ "confirmados">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(((qCount30Dias.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
            <p class="m-0"><cfoutput>#numberFormat(qCount30Dias.recordCount, "9")#</cfoutput> correram 30 Dias</p>
        </div>
        </a>
    </div>
    <div class="col-md-2">
        <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=cidade">
        <div class="card <cfif URL.periodo EQ "confirmados">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(((qCountCidade.recordCount*100)/qPeriodo.recordCount), "9")#%</cfoutput></p>
            <p class="m-0"><cfoutput>#numberFormat(qCountCidade.recordCount, "9")#</cfoutput> correram 100 Dias</p>
        </div>
        </a>
    </div>
    <div class="col-md-2">
        <a href="./?periodo=<cfoutput>#URL.periodo#</cfoutput>&preset=estado">
        <div class="card <cfif URL.periodo EQ "confirmados">bg-5k<cfelseif URL.periodo EQ "nodesafio">bg-10k<cfelseif URL.periodo EQ "vip">bg-21k<cfelseif URL.periodo EQ "pendentes">bg-42k</cfif> py-2 px-3">
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

<!---<div class="row g-3">--->


    <cfif URL.periodo NEQ "pendentes">

        <!---<div class="col-md-3 d-none d-xl-block">--->

            <div class="row g-2 mb-2">

                <!--- LISTAGEM DE REGIAO --->

                <div class="col-4">

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

                <div class="col-4">

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

                <div class="col-4">

                    <div class="card">

                        <div class="card-header px-3 py-2">Por Cidade</div>

                        <div class="card-body p-2">

                            <div class="table-wrapper">

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

        <!---</div>--->

    </cfif>

<!---</div>--->

    <!---<div class="<cfif URL.periodo NEQ "pendentes">col-md-12 col-xl-9<cfelse>col-md-12</cfif>">--->

        <div class="row g-3">

            <!--- LISTAGEM --->

            <div class="col-md-12">

                <div class="card">

                    <div class="card-header px-3 py-2">Atletas (<cfoutput>#qStatsBase.recordcount#</cfoutput>)</div>

                    <div class="card-body p-2">

                        <cfif URL.periodo NEQ "pendentes">

                            <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                            <cfquery name="qStatsEvento" dbtype="query">
                                select *
                                from qStatsBase
                                <cfif VARIABLES.challengeIsBrasilGigante>
                                    order by nodesafio desc, nome
                                <cfelseif VARIABLES.challengeIsCatarinenseCircuit>
                                    order by distancia_percorrida desc, nodesafio desc, nome
                                <cfelseif lcase(trim(URL.desafio)) EQ "desafio365">
                                    order by dias_correndo desc
                                <cfelse>
                                    order by data_inicial desc
                                </cfif>
                            </cfquery>
                            <cfset desafiosAddQueryTiming("qStatsEvento:inscritos", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>

                            <a href="/desafios/includes/exportar_excel.cfm?desafio=<cfoutput>#URL.desafio#</cfoutput>&tipo=inscritos"><button class="btn btn-sm btn-outline-success mb-3"><i class="fas fa-file-excel"></i> Exportar excel </button> </a>
                            <cfinclude template="includes/tabela_usuarios_padrao.cfm"/>

                        <cfelse>

                            <ul class="nav nav-tabs mb-3" id="ex1" role="tablist">

                                <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                                <cfquery name="qStatsEvento" dbtype="query">
                                    select *
                                    from qStatsBase
                                    where status_transacao = 'duplicado' OR status_transacao = 'pago'
                                </cfquery>
                                <cfset desafiosAddQueryTiming("qStatsEvento:pendentes_interacao_count", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>
                              <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init
                                  class="nav-link active"
                                  id="ex1-tab-1"
                                  href="#ex1-tabs-1"
                                  role="tab"
                                  aria-controls="ex1-tabs-1"
                                  aria-selected="true">Pendentes de Interação (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                              </li>

                                <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                                <cfquery name="qStatsEvento" dbtype="query">
                                    select *
                                    from qStatsBase
                                    where strava_code is null
                                </cfquery>
                                <cfset desafiosAddQueryTiming("qStatsEvento:sem_strava_count", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>
                              <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init
                                  class="nav-link"
                                  id="ex1-tab-2"
                                  href="#ex1-tabs-2"
                                  role="tab"
                                  aria-controls="ex1-tabs-2"
                                  aria-selected="false">Sem Strava (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                              </li>

                                <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                                <cfquery name="qStatsEvento" dbtype="query">
                                    select *
                                    from qStatsBase
                                    where status_transacao is null and strava_code is not null
                                </cfquery>
                                <cfset desafiosAddQueryTiming("qStatsEvento:sem_pedido_count", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>
                              <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init
                                  class="nav-link"
                                  id="ex1-tab-3"
                                  href="#ex1-tabs-3"
                                  role="tab"
                                  aria-controls="ex1-tabs-3"
                                  aria-selected="false">Sem Pedido (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                              </li>

                                <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                                <cfquery name="qStatsEvento" dbtype="query">
                                    select *
                                    from qStatsBase
                                    where status_transacao = 'pendente'
                                </cfquery>
                                <cfset desafiosAddQueryTiming("qStatsEvento:pagamento_pendente_count", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>
                              <li class="nav-item" role="presentation">
                                <a data-mdb-tab-init
                                  class="nav-link"
                                  id="ex1-tab-4"
                                  href="#ex1-tabs-4"
                                  role="tab"
                                  aria-controls="ex1-tabs-4"
                                  aria-selected="false">Pagamento Pendente (<cfoutput>#qStatsEvento.recordcount#</cfoutput>)</a>
                              </li>

                            </ul>

                            <div class="tab-content" id="ex1-content">

                              <div class="tab-pane fade show active" id="ex1-tabs-1" role="tabpanel" aria-labelledby="ex1-tab-1">
                                <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                                <cfquery name="qStatsEvento" dbtype="query">
                                    select *
                                    from qStatsBase
                                    where status_transacao = 'duplicado' OR status_transacao = 'pago'
                                    order by data_inscricao
                                </cfquery>
                                <cfset desafiosAddQueryTiming("qStatsEvento:pendentes_interacao_tab", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>
                                <cfinclude template="includes/tabela_usuarios_padrao.cfm"/>
                              </div>

                              <div class="tab-pane fade" id="ex1-tabs-2" role="tabpanel" aria-labelledby="ex1-tab-2">
                                <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                                <cfquery name="qStatsEvento" dbtype="query">
                                    select *
                                    from qStatsBase
                                    where strava_code is null
                                    order by data_inscricao
                                </cfquery>
                                <cfset desafiosAddQueryTiming("qStatsEvento:sem_strava_tab", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>
                                <a href="/desafios/includes/exportar_excel.cfm?desafio=<cfoutput>#URL.desafio#</cfoutput>&tipo=semstrava"><button class="btn btn-sm btn-outline-success mb-3"><i class="fas fa-file-excel"></i> Exportar excel </button> </a>
                                <cfinclude template="includes/tabela_usuarios_padrao.cfm"/>
                              </div>

                              <div class="tab-pane fade" id="ex1-tabs-3" role="tabpanel" aria-labelledby="ex1-tab-3">
                                <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                                <cfquery name="qStatsEvento" dbtype="query">
                                    select *
                                    from qStatsBase
                                    where status_transacao is null and strava_code is not null
                                    order by data_inscricao
                                </cfquery>
                                <cfset desafiosAddQueryTiming("qStatsEvento:sem_pedido_tab", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>
                                <a href="/desafios/includes/exportar_excel.cfm?desafio=<cfoutput>#URL.desafio#</cfoutput>&tipo=sempedido"><button class="btn btn-sm btn-outline-success mb-3"><i class="fas fa-file-excel"></i> Exportar excel </button> </a>
                                <cfinclude template="includes/tabela_usuarios_padrao.cfm"/>
                              </div>

                              <div class="tab-pane fade" id="ex1-tabs-4" role="tabpanel" aria-labelledby="ex1-tab-4">
                                <cfset VARIABLES.desafiosQueryStart = getTickCount()/>
                                <cfquery name="qStatsEvento" dbtype="query">
                                    select *
                                    from qStatsBase
                                    where status_transacao = 'pendente'
                                    order by data_inscricao
                                </cfquery>
                                <cfset desafiosAddQueryTiming("qStatsEvento:pagamento_pendente_tab", VARIABLES.desafiosQueryStart, qStatsEvento.recordcount, "qoq")/>
                                <a href="/desafios/includes/exportar_excel.cfm?desafio=<cfoutput>#URL.desafio#</cfoutput>&tipo=pendente"><button class="btn btn-sm btn-outline-success mb-3"><i class="fas fa-file-excel"></i> Exportar excel </button> </a>
                                <cfinclude template="includes/tabela_usuarios_padrao.cfm"/>
                              </div>

                            </div>

                        </cfif>

                    </div>

                </div>

            </div>

        </div>

    <!---</div>--->

<!---</div>--->

</cfif>
