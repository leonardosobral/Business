<cfif NOT isDefined("VARIABLES.requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed>
    <cfheader statuscode="403"/>
    <cfabort/>
</cfif>

<cfif URL.tela EQ "resumo">
    <section class="card mb-2" aria-labelledby="foco-funnel-heading">
        <h2 class="card-header px-3 py-2 fs-6 mb-0" id="foco-funnel-heading">Funil de ativação</h2>
        <div class="card-body p-2">
            <div class="row g-2">
                <cfoutput>
                    <cfloop from="1" to="4" index="stageIndex">
                        <cfset stage = VARIABLES.focoFunnelStages[stageIndex]/>
                        <cfset stageCount = VARIABLES.focoStageCounts[stage.key]/>
                        <cfset stagePercent = VARIABLES.focoStageCounts.inscritos ? round(stageCount * 100 / VARIABLES.focoStageCounts.inscritos) : 0/>
                        <div class="col-6 col-xl-3">
                            <a class="d-block border rounded p-2 h-100 text-reset" data-foco-stage="#stage.key#" href="/desafios/foco/?tela=participantes&amp;etapa=#stage.key#">
                                <span class="d-flex flex-wrap gap-2 align-items-baseline justify-content-between">
                                    <strong class="fs-4">#lsNumberFormat(stageCount, '9,999', 'Portuguese (Brazilian)')#</strong>
                                    <span class="small">#stagePercent#%</span>
                                </span>
                                <span class="d-block small mb-1">#stage.title#</span>
                                <span class="progress" style="height: 0.25rem" aria-hidden="true">
                                    <span class="progress-bar bg-warning" style="width: #stagePercent#%"></span>
                                </span>
                            </a>
                        </div>
                    </cfloop>
                </cfoutput>
            </div>
            <p class="small mb-0 mt-2">Percentuais sobre o total de inscritos. A etapa do Strava considera também atletas com atividade ou ponto já registrado.</p>
        </div>
    </section>
<cfelse>
    <form method="get" action="/desafios/foco/" class="card mb-2" aria-label="Filtrar atletas do Desafio Foco">
        <div class="card-body p-2">
            <input type="hidden" name="tela" value="participantes"/>
            <cfoutput>
                <cfloop list="regiao,estado,cidade" index="geoKey">
                    <cfif len(URL[geoKey])>
                        <input type="hidden" name="#geoKey#" value="#encodeForHTMLAttribute(URL[geoKey])#"/>
                    </cfif>
                </cfloop>
                <div class="row g-2 align-items-end">
                    <div class="col-12 col-md-5">
                        <label class="form-label mb-1" for="foco-stage-select">Etapa do funil</label>
                        <select class="form-select form-select-sm" id="foco-stage-select" name="etapa">
                            <cfloop array="#VARIABLES.focoFunnelStages#" item="stage">
                                <option value="#stage.key#"<cfif URL.etapa EQ stage.key> selected</cfif>>#stage.title#</option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="col-12 col-md-4">
                        <label class="form-label mb-1" for="foco-athlete-search">Nome</label>
                        <input class="form-control form-control-sm" type="search" name="busca" id="foco-athlete-search" value="#encodeForHTMLAttribute(URL.busca)#"/>
                    </div>
                    <div class="col-12 col-md-auto d-flex gap-2">
                        <button class="btn btn-sm btn-warning" type="submit">Filtrar</button>
                        <a class="btn btn-sm btn-outline-secondary" href="/desafios/foco/?tela=participantes">Limpar filtros</a>
                    </div>
                </div>
            </cfoutput>
        </div>
    </form>
</cfif>
