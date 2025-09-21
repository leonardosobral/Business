<!--- WIDGETS TEMPORAIS --->

<div class="row g-3 mb-3">

    <div class="col">
        <a href="./?periodo=checkin&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-success text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountCheckin.total, "9")#</cfoutput></p>
            <p class="m-0"><cfoutput>#len(trim(qCountCheckin.total)) ? numberFormat((qCountCheckin.total*100)/qBaseInscritos.recordcount, "9") : 0#</cfoutput>% Chamados</p>
        </div>
        </a>
    </div>

    <div class="col">
        <a href="./?periodo=sorteados&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-success text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountSorteio.total, "9")#</cfoutput></p>
            <p class="m-0"><cfoutput>#len(trim(qCountSorteio.total)) ? numberFormat((qCountSorteio.total*100)/qCountCheckin.total, "9") : 0#</cfoutput>% 21k</p>
        </div>
        </a>
    </div>

    <div class="col">
        <a href="./?periodo=semcheckin&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-43k py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountSemCheckin.total, "9")#</cfoutput></p>
            <p class="m-0"><cfoutput>#len(trim(qCountSemCheckin.total)) ? numberFormat((qCountSemCheckin.total*100)/qBaseInscritos.recordcount, "9") : 0#</cfoutput>% 5 e 42k</p>
        </div>
        </a>
    </div>

    <div class="col d-none d-md-block">
        <a href="./?periodo=mif&preset=<cfoutput>#URL.preset#</cfoutput>">
        <div class="card bg-warning text-white py-2 px-3">
            <p class="h4 m-0"><cfoutput>#numberFormat(qCountMIF.total, "9")#</cfoutput></p>
            <p class="m-0"><cfoutput>#len(trim(qCountMIF.total)) ? numberFormat((qCountMIF.total*100)/qBaseInscritos.recordcount, "9") : 0#</cfoutput>% Fichas</p>
        </div>
        </a>
    </div>

</div>


<!--- FILTROS BUSCA

<div class="row my-3">

    <div class="col">

        <form action="" method="get">
            <input type="text" class="form-control" name="busca" placeholder="busca" value="<cfoutput>#URL.busca#</cfoutput>"/>
            <input type="hidden" name="preset" value=""/>
        </form>

    </div>

</div>

 --->


<!--- ESTATISTICAS --->

<div class="row g-2">

    <div class="col-md-4">

        <div class="row g-2 d-none d-md-flex">

            <!--- LISTAGEM DE REGIAO --->

            <!---div class="col-md-8">

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

            </div--->

            <!--- LISTAGEM DE UF --->

            <div class="col-md-4">

                <div class="card">

                    <div class="card-header px-3 py-2">Por Estado</div>

                    <div class="card-body p-2">

                        <div class="table-wrapper-sm">

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

            <div class="col-md-8">

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

        <div class="row g-2">

            <!--- LISTAGEM --->

            <div class="col-md-12">

                <div class="card">

                    <div class="card-header px-3 py-2">Atletas <cfoutput>(#qStatsEvento.recordcount#)</cfoutput></div>

                    <div class="card-body p-2">

                        <cfinclude template="includes/treinao_accordion.cfm"/>

                    </div>

                </div>

            </div>

        </div>

    </div>

</div>
