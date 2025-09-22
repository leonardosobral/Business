<div class="<cfif (URL.estado NEQ "") OR URL.cidade NEQ "">col-md-8<cfelse>col-md-3</cfif>">

    <div class="card">

        <!--- HEADER DO PAINEL --->

        <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 pt-2 pb-0">
            <h6 class="m0 p0">Cidades</h6>
        </div>

        <!--- BODY DO PAINEL --->

        <div class="card-body p-2">

            <div class="<cfif qStatsCidade.recordCount GT 1 OR qStatsEstado.recordCount GT 1 OR qStatsCidade.recordCount GT 1>table-wrapper-6<cfelse>table-wrapper-sm</cfif>">

                <table class="table table-stripped table-condensed table-sm mb-0">
    
                    <thead>
                        <tr>
                            <th colspan="4" class="my-0 pt-0 text-center">Eventos</th>
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
    
                    <cfoutput query="qStatsCidade">
                        
                        <tr style="cursor: pointer;" <cfif qStatsCidade.cidade EQ URL.cidade>class="table-active"  onclick="location.href = './?preset=#URL.preset#&Regiao=#URL.Regiao#&estado=#URL.estado#'"<cfelse>onclick="location.href = './?preset=#URL.preset#&Regiao=#URL.Regiao#&estado=#URL.estado#&cidade=#urlEncodedFormat(qStatsCidade.cidade)#'"</cfif> >
                            
                            <td width="35%">#qStatsCidade.cidade#</td>
                            <td>#qStatsCidade.estado#</td>

                            <td nowrap class="text-end">#qStatsCidade.eventos#</td>
                            <td class="text-end">#len(qStatsCidade.eventos) and len(qTotalCidade.eventos) ? lsNumberFormat((qStatsCidade.eventos*100)/qTotalCidade.eventos, 9.9) : 0#%</td>
                            
                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsCidade.eventos) and len(qStatsCidade.tt) ? (qStatsCidade.tt)/qStatsCidade.eventos/1.8 : 0#) !important; border-left: solid 1px gray;">#qStatsCidade.tt#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsCidade.eventos) and len(qStatsCidade.tt) ? (qStatsCidade.tt)/qStatsCidade.eventos/1.8 : 0#) !important;">#len(qStatsCidade.eventos) and len(qStatsCidade.tt) ? lsNumberFormat((qStatsCidade.tt*100)/qStatsCidade.eventos, 9.9) : 0#%</td>
                            </cfif>

                            <!---td nowrap class="text-end" style="border-left: solid 1px gray;">#qStatsCidade.tem_url_resultado#</td>
                            <td class="text-end">#len(qStatsCidade.eventos) and len(qStatsCidade.tem_url_resultado) ? lsNumberFormat((qStatsCidade.tem_url_resultado*100)/qStatsCidade.eventos, 9.9) : 0#%</td--->

                            <td nowrap class="text-end" style="border-left: solid 1px gray;">#qStatsCidade.tem_resultado#</td>
                            <td class="text-end">#len(qStatsCidade.eventos) and len(qStatsCidade.tem_resultado) ? lsNumberFormat((qStatsCidade.tem_resultado*100)/qStatsCidade.eventos, 9.9) : 0#%</td>
                            
                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsCidade.tem_resultado) and qStatsCidade.tem_resultado GT 0 and len(qStatsCidade.tt_resultado) ? (qStatsCidade.tt_resultado)/qStatsCidade.tem_resultado/1.8 : 0#) !important; border-left: solid 1px gray;">#qStatsCidade.tt_resultado#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsCidade.tem_resultado) and qStatsCidade.tem_resultado GT 0 and len(qStatsCidade.tt_resultado) ? (qStatsCidade.tt_resultado)/qStatsCidade.tem_resultado/1.8 : 0#) !important;">#len(qStatsCidade.tem_resultado) and qStatsCidade.tem_resultado GT 0 and len(qStatsCidade.tt_resultado) ? lsNumberFormat((qStatsCidade.tt_resultado*100)/qStatsCidade.tem_resultado, 9.9) : 0#%</td>
                            </cfif>
                            
                            <cfset VARIABLES.heat = 0/>
                            <cfif qTotalCidade.maximo - qTotalCidade.minimo GT 0>
                                <cfset VARIABLES.heat = (qStatsCidade.media - qTotalCidade.minimo) / (qTotalCidade.maximo - qTotalCidade.minimo)/>
                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.6)/>
                                <cfset VARIABLES.heat = 0/>
                            </cfif>
                            
                            <td class="text-end" style="border-left: solid 1px gray;">#lsNumberFormat(qStatsCidade.concluintes)#</td>
                            <td class="text-end">#len(qStatsCidade.concluintes) and len(qTotalCidade.concluintes) ? lsNumberFormat((qStatsCidade.concluintes*100)/qTotalCidade.concluintes, 9.9) : 0#%</td>
                            <td class="text-end" style="background-color: rgba(255,200,0,#VARIABLES.heat#);">#lsNumberFormat(qStatsCidade.media)#</td>
                        
                            <cfset VARIABLES.heat = 0/>
                            <cfif qTotalCidadeEmpresa.maximo - qTotalCidadeEmpresa.minimo GT 0>
                                <cfset VARIABLES.heat = (qStatsCidade.tt_media - qTotalCidadeEmpresa.minimo) / (qTotalCidadeEmpresa.maximo - qTotalCidadeEmpresa.minimo)/>
                                <cfset VARIABLES.heat = 0.2 + (VARIABLES.heat * 0.6)/>
                            </cfif>

                            <cfif qBi.tipo EQ "empresa">
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsCidade.tt_concluintes) and qStatsCidade.tt_concluintes GT 0 and len(qStatsCidade.concluintes) ? (qStatsCidade.tt_concluintes)/qStatsCidade.concluintes/1.8 : 0#) !important; border-left: solid 1px gray;">#lsNumberFormat(qStatsCidade.tt_concluintes)#</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#len(qStatsCidade.tt_concluintes) and qStatsCidade.tt_concluintes GT 0 and len(qStatsCidade.concluintes) ? (qStatsCidade.tt_concluintes)/qStatsCidade.concluintes/1.8 : 0#) !important;">#len(qStatsCidade.tt_concluintes) and qStatsCidade.tt_concluintes GT 0 and len(qStatsCidade.concluintes) ? lsNumberFormat((qStatsCidade.tt_concluintes*100)/qStatsCidade.concluintes, 9.9) : 0#%</td>
                                <td class="text-end" style="background-color: rgba(50,150,255,#VARIABLES.heat/1.8#);">#len(qStatsCidade.tt_concluintes) and qStatsCidade.tt_concluintes GT 0 ? lsNumberFormat(qStatsCidade.tt_concluintes/qStatsCidade.tt_resultado) : 0#</td>
                            </cfif>
                        
                        </tr>
                        
                    </cfoutput>
    
                </table>

            </div>

        </div>

    </div>

</div>
