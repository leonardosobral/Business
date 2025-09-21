<div class="<cfif URL.regiao NEQ "" AND URL.estado EQ "" AND URL.cidade EQ "">col-md-7<cfelse>col-md-2</cfif>">

    <div class="card">

        <!--- HEADER DO PAINEL --->

        <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 pt-2 pb-0">
            <h6 class="m0 p0">Estados</h6>
        </div>

        <!--- BODY DO PAINEL --->

        <div class="card-body p-2">

            <div class="<cfif qStatsEstado.recordCount GT 1 OR qStatsEstado.recordCount GT 1 OR qStatsCidade.recordCount GT 1>table-wrapper-6<cfelse>table-wrapper-sm</cfif>">

                <table class="table table-stripped table-condensed table-sm mb-0" >

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

                    <cfoutput query="qStatsEstado">
                        
                        <tr style="cursor: pointer;" <cfif qStatsEstado.estado EQ URL.estado>class="table-active" onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#'"<cfelse>onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#urlEncodedFormat(qStatsEstado.estado)#'"</cfif> >
                            
                            <td>#qStatsEstado.estado#</td>

                            <td nowrap class="text-end">#qStatsEstado.eventos#</td>
                            <td class="text-end">#len(qStatsEstado.eventos) and len(qTotalEstado.eventos) ? lsNumberFormat((qStatsEstado.eventos*100)/qTotalEstado.eventos, 9.9) : 0#%</td>

                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsEstado.eventos) and len(qStatsEstado.tt) ? (qStatsEstado.tt)/qStatsEstado.eventos/1.8 : 0#) !important; border-left: solid 1px gray;">#qStatsEstado.tt#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsEstado.eventos) and len(qStatsEstado.tt) ? (qStatsEstado.tt)/qStatsEstado.eventos/1.8 : 0#) !important;">#len(qStatsEstado.eventos) and len(qStatsEstado.tt) ? lsNumberFormat((qStatsEstado.tt*100)/qStatsEstado.eventos, 9.9) : 0#%</td>
                            </cfif>
                            
                            <!---td nowrap class="text-end" style="border-left: solid 1px gray;">#qStatsEstado.tem_url_resultado#</td>
                            <td class="text-end">#len(qStatsEstado.eventos) and len(qStatsEstado.tem_url_resultado) ? lsNumberFormat((qStatsEstado.tem_url_resultado*100)/qStatsEstado.eventos, 9.9) : 0#%</td--->

                            <td nowrap class="text-end" style="border-left: solid 1px gray;">#qStatsEstado.tem_resultado#</td>
                            <td class="text-end">#len(qStatsEstado.eventos) and len(qStatsEstado.tem_resultado) ? lsNumberFormat((qStatsEstado.tem_resultado*100)/qStatsEstado.eventos, 9.9) : 0#%</td>
                            
                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsEstado.tem_resultado) and qStatsEstado.tem_resultado GT 0 and len(qStatsEstado.tt_resultado) ? (qStatsEstado.tt_resultado)/qStatsEstado.tem_resultado/1.8 : 0#) !important; border-left: solid 1px gray;">#qStatsEstado.tt_resultado#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsEstado.tem_resultado) and qStatsEstado.tem_resultado GT 0 and len(qStatsEstado.tt_resultado) ? (qStatsEstado.tt_resultado)/qStatsEstado.tem_resultado/1.8 : 0#) !important;">#len(qStatsEstado.tem_resultado) and qStatsEstado.tem_resultado GT 0 and len(qStatsEstado.tt_resultado) ? lsNumberFormat((qStatsEstado.tt_resultado*100)/qStatsEstado.tem_resultado, 9.9) : 0#%</td>
                            </cfif>
                            
                            <cfset VARIABLES.heat = 0/>
                            <cfif (qTotalEstado.maximo - qTotalEstado.minimo GT 0) AND Len(trim(qStatsEstado.concluintes))>
                                <cfset VARIABLES.heat = ((qStatsEstado.concluintes ? (qStatsEstado.concluintes/qStatsEstado.tem_resultado) : 0) - qTotalEstado.minimo) / (qTotalEstado.maximo - qTotalEstado.minimo)/>
                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.6)/>
                                <cfset VARIABLES.heat = 0/>
                            </cfif>
                            
                            <td class="text-end" style="border-left: solid 1px gray;">#lsNumberFormat(qStatsEstado.concluintes)#</td>
                            <td class="text-end" style="background-color: rgba(255,200,0,#VARIABLES.heat#);">#len(qStatsEstado.concluintes) and len(qTotalEstado.concluintes) AND qStatsEstado.tem_resultado GT 0 ? lsNumberFormat(qStatsEstado.media) : 0#</td>
                            <td class="text-end">#len(qStatsEstado.concluintes) and len(qTotalEstado.concluintes) AND qStatsEstado.tem_resultado GT 0 ? lsNumberFormat((qStatsEstado.concluintes*100)/qTotalEstado.concluintes, 9.9) : 0#%</td>
                        
                            <cfset VARIABLES.heat = 0/>
                            <cfif qTotalRegiaoEmpresa.maximo - qTotalRegiaoEmpresa.minimo GT 0>
                                <cfset VARIABLES.heat = (qStatsEstado.tt_media - qTotalRegiaoEmpresa.minimo) / (qTotalRegiaoEmpresa.maximo - qTotalRegiaoEmpresa.minimo)/>
                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.6)/>
                            </cfif>
                            
                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsEstado.tt_concluintes) and qStatsEstado.tt_concluintes GT 0 and len(qStatsEstado.concluintes) ? (qStatsEstado.tt_concluintes)/qStatsEstado.concluintes/1.8 : 0#) !important; border-left: solid 1px gray;">#lsNumberFormat(qStatsEstado.tt_concluintes)#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsEstado.tt_concluintes) and qStatsEstado.tt_concluintes GT 0 and len(qStatsEstado.concluintes) ? (qStatsEstado.tt_concluintes)/qStatsEstado.concluintes/1.8 : 0#) !important;">#len(qStatsEstado.tt_concluintes) and qStatsEstado.tt_concluintes GT 0 and len(qStatsEstado.concluintes) ? lsNumberFormat((qStatsEstado.tt_concluintes*100)/qStatsEstado.concluintes, 9.9) : 0#%</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#VARIABLES.heat/1.8#);">#len(qStatsEstado.tt_concluintes) and qStatsEstado.tt_concluintes GT 0 ? lsNumberFormat(qStatsEstado.tt_concluintes/qStatsEstado.tt_resultado) : 0#</td>
                            </cfif>
                        
                        </tr>
                        
                    </cfoutput>
    
                </table>

            </div>

        </div>

    </div>

</div>
