<div class="<cfif URL.regiao EQ "" AND URL.estado EQ "" AND URL.cidade EQ "">col-md-7<cfelse>col-md-2</cfif>">

    <div class="card">

        <!--- HEADER DO PAINEL --->

        <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 pt-2 pb-0">
            <h6 class="m0 p0">Regiões</h6>
        </div>

        <!--- BODY DO PAINEL --->

        <div class="card-body p-2">

            <div class="<cfif qStatsRegiao.recordCount GT 1 OR qStatsEstado.recordCount GT 1 OR qStatsCidade.recordCount GT 1>table-wrapper-6<cfelse>table-wrapper-sm</cfif>">

                <table class="table table-stripped table-hovered table-condensed table-sm mb-0">

                    <thead>
                        <tr>
                            <th colspan="3" class="my-0 pt-0 text-center">Eventos</th>
                            <cfif qBi.tipo EQ "empresa">
                                <th colspan="2" class="my-0 pt-0 text-center"><img src="/assets/icons/<cfoutput>#qBI.logo#</cfoutput>.png" width="20" class="me-2" title="<cfoutput>#qBI.titulo#</cfoutput>" onerror="this.style='display:none';"/></th>
                            </cfif>
                            <th colspan="2" class="my-0 pt-0 text-center">Resultados</th>
                            <cfif qBi.tipo EQ "empresa">
                                <th colspan="2" class="my-0 pt-0 text-center"><img src="/assets/icons/<cfoutput>#qBI.logo#</cfoutput>.png" width="20" class="me-2" title="<cfoutput>#qBI.titulo#</cfoutput>" onerror="this.style='display:none';"/></th>
                            </cfif>
                            <th colspan="2" class="my-0 pt-0 text-center">Público</th>
                            <td class="text-center my-0 pt-0 text-center"><icon class="fa fa-users" title="Público médio"></icon></td>
                            <cfif qBi.tipo EQ "empresa">
                                <th colspan="2" class="my-0 pt-0 text-center"><img src="/assets/icons/<cfoutput>#qBI.logo#</cfoutput>.png" width="20" class="me-2" title="<cfoutput>#qBI.titulo#</cfoutput>" onerror="this.style='display:none';"/></th>
                                <td class="text-center my-0 pt-0 text-center"><icon class="fa fa-users" title="Público médio"></icon></td>
                            </cfif>
                        </tr>
                    </thead>

                    <cfoutput query="qStatsRegiao">

                        <tr style="cursor: pointer;" <cfif qStatsRegiao.regiao EQ URL.regiao>class="table-active" onclick="location.href = './?preset=#URL.preset#'"<cfelse>onclick="location.href = './?preset=#URL.preset#&regiao=#urlEncodedFormat(qStatsRegiao.regiao)#'"</cfif> >

                            <td>#qStatsRegiao.regiao#</td>

                            <td nowrap class="text-end">#qStatsRegiao.eventos#</td>
                            <td class="text-end">#len(qStatsRegiao.eventos) and len(qTotalRegiao.eventos) ? lsNumberFormat((qStatsRegiao.eventos*100)/qTotalRegiao.eventos, 9.9) : 0#%</td>

                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsRegiao.eventos) and len(qStatsRegiao.tt) ? (qStatsRegiao.tt)/qStatsRegiao.eventos/1.8 : 0#) !important; border-left: solid 1px gray;">#qStatsRegiao.tt#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsRegiao.eventos) and len(qStatsRegiao.tt) ? (qStatsRegiao.tt)/qStatsRegiao.eventos/1.8 : 0#) !important;">#len(qStatsRegiao.eventos) and len(qStatsRegiao.tt) ? lsNumberFormat((qStatsRegiao.tt*100)/qStatsRegiao.eventos, 9.9) : 0#%</td>
                            </cfif>

                            <!---td nowrap class="text-end" style="border-left: solid 1px gray;">#qStatsRegiao.tem_url_resultado#</td>
                            <td class="text-end">#len(qStatsRegiao.eventos) and len(qStatsRegiao.tem_url_resultado) ? lsNumberFormat((qStatsRegiao.tem_url_resultado*100)/qStatsRegiao.eventos, 9.9) : 0#%</td--->

                            <td nowrap class="text-end" style="border-left: solid 1px gray;">#qStatsRegiao.tem_resultado#</td>
                            <td class="text-end">#len(qStatsRegiao.eventos) and len(qStatsRegiao.tem_resultado) ? lsNumberFormat((qStatsRegiao.tem_resultado*100)/qStatsRegiao.eventos, 9.9) : 0#%</td>

                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsRegiao.tem_resultado) and qStatsRegiao.tem_resultado GT 0 and len(qStatsRegiao.tt_resultado) ? (qStatsRegiao.tt_resultado)/qStatsRegiao.tem_resultado/1.8 : 0#) !important; border-left: solid 1px gray;">#qStatsRegiao.tt_resultado#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsRegiao.tem_resultado) and qStatsRegiao.tem_resultado GT 0 and len(qStatsRegiao.tt_resultado) ? (qStatsRegiao.tt_resultado)/qStatsRegiao.tem_resultado/1.8 : 0#) !important;">#len(qStatsRegiao.tem_resultado) and qStatsRegiao.tem_resultado GT 0 and len(qStatsRegiao.tt_resultado) ? lsNumberFormat((qStatsRegiao.tt_resultado*100)/qStatsRegiao.tem_resultado, 9.9) : 0#%</td>
                            </cfif>

                            <cfset VARIABLES.heat = 0/>
                            <cfif qTotalRegiao.maximo - qTotalRegiao.minimo GT 0>
                                <cfset VARIABLES.heat = (qStatsRegiao.media - qTotalRegiao.minimo) / (qTotalRegiao.maximo - qTotalRegiao.minimo)/>
                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.6)/>
                                <cfset VARIABLES.heat = 0/>
                            </cfif>

                            <td class="text-end" style="border-left: solid 1px gray;">#lsNumberFormat(qStatsRegiao.concluintes)#</td>
                            <td class="text-end" style="background-color: rgba(255,200,0,#VARIABLES.heat/1.8#);">#len(qStatsRegiao.tem_resultado) and qStatsRegiao.tem_resultado GT 0 ? lsNumberFormat(qStatsRegiao.concluintes/qStatsRegiao.tem_resultado) : 0#</td>
                            <td class="text-end">#len(qStatsRegiao.concluintes) and len(qTotalRegiao.concluintes) ? lsNumberFormat((qStatsRegiao.concluintes*100)/qTotalRegiao.concluintes, 9.9) : 0#%</td>

                            <cfset VARIABLES.heat = 0/>
                            <cfif qTotalRegiaoEmpresa.maximo - qTotalRegiaoEmpresa.minimo GT 0>
                                <cfset VARIABLES.heat = (qStatsRegiao.tt_media - qTotalRegiaoEmpresa.minimo) / (qTotalRegiaoEmpresa.maximo - qTotalRegiaoEmpresa.minimo)/>
                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.6)/>
                            </cfif>

                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsRegiao.tt_concluintes) and qStatsRegiao.tt_concluintes GT 0 and len(qStatsRegiao.concluintes) ? (qStatsRegiao.tt_concluintes)/qStatsRegiao.concluintes/1.8 : 0#) !important; border-left: solid 1px gray;">#lsNumberFormat(qStatsRegiao.tt_concluintes)#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsRegiao.tt_concluintes) and qStatsRegiao.tt_concluintes GT 0 and len(qStatsRegiao.concluintes) ? (qStatsRegiao.tt_concluintes)/qStatsRegiao.concluintes/1.8 : 0#) !important;">#len(qStatsRegiao.tt_concluintes) and qStatsRegiao.tt_concluintes GT 0 and len(qStatsRegiao.concluintes) ? lsNumberFormat((qStatsRegiao.tt_concluintes*100)/qStatsRegiao.concluintes, 9.9) : 0#%</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#VARIABLES.heat/1.8#);">#len(qStatsRegiao.tt_concluintes) and qStatsRegiao.tt_concluintes GT 0 ? lsNumberFormat(qStatsRegiao.tt_concluintes/qStatsRegiao.tt_resultado) : 0#</td>
                            </cfif>

                        </tr>

                    </cfoutput>

                </table>

            </div>

        </div>

    </div>

</div>
