<cfprocessingdirective pageencoding="utf-8"/>
<cfif NOT isDefined("VARIABLES.requireAdminAllowed") OR NOT VARIABLES.requireAdminAllowed>
    <cfheader statuscode="403"/>
    <cfabort/>
</cfif>

<cfset VARIABLES.focoHistoryBase = "/desafios/foco/?tela=pontos"/>
<cfif len(URL.motivo)>
    <cfset VARIABLES.focoHistoryBase &= "&motivo=" & encodeForURL(URL.motivo)/>
</cfif>
<cfset VARIABLES.focoHistorySearchUrl = VARIABLES.focoHistoryBase/>
<cfif len(URL.busca_pontos)>
    <cfset VARIABLES.focoHistorySearchUrl &= "&busca_pontos=" & encodeForURL(URL.busca_pontos)/>
</cfif>
<cfset VARIABLES.focoHistoryAnchor = chr(35) & "foco-point-history"/>
<cfset VARIABLES.focoHistoryPendingUrl = VARIABLES.focoHistoryBase & chr(35) & "foco-point-pending"/>

<section class="card mb-2" id="foco-point-history" aria-labelledby="foco-point-history-heading" tabindex="-1" style="scroll-margin-top: 6rem">
    <h3 class="card-header px-3 py-2 fs-6 mb-0" id="foco-point-history-heading">Histórico de pontos por atleta</h3>
    <div class="card-body p-3">
        <form method="get" action="/desafios/foco/#foco-point-history" class="row g-2 align-items-end">
            <input type="hidden" name="tela" value="pontos"/>
            <cfoutput>
                <cfif len(URL.motivo)>
                    <input type="hidden" name="motivo" value="#encodeForHTMLAttribute(URL.motivo)#"/>
                </cfif>
                <div class="col-12 col-sm-6 col-md-5">
                    <label class="form-label small mb-1" for="foco-point-athlete-search">Nome ou ID do atleta</label>
                    <input class="form-control form-control-sm" id="foco-point-athlete-search" type="search" name="busca_pontos"
                        value="#encodeForHTMLAttribute(URL.busca_pontos)#" maxlength="100" required/>
                </div>
                <div class="col-auto">
                    <button type="submit" class="btn btn-sm btn-warning">Buscar atleta</button>
                </div>
                <cfif URL.atleta GT 0 OR len(URL.busca_pontos)>
                    <div class="col-auto">
                        <a class="btn btn-sm btn-outline-secondary" href="#encodeForHTMLAttribute(VARIABLES.focoHistoryPendingUrl)#">Voltar às pendências</a>
                    </div>
                </cfif>
            </cfoutput>
        </form>

        <cfif URL.atleta GT 0 AND qFocoAtleta.recordCount EQ 0>
            <p class="small mt-3 mb-0">Atleta não encontrado entre os inscritos do Desafio Foco.</p>
        </cfif>

        <cfif len(URL.busca_pontos) AND qFocoAtleta.recordCount EQ 0>
            <cfif qFocoBuscaAtletas.recordCount>
                <ul class="list-group list-group-flush mt-3" aria-label="Atletas encontrados">
                    <cfoutput query="qFocoBuscaAtletas">
                        <cfset VARIABLES.focoHistoryResultName = trim(qFocoBuscaAtletas.nome ?: "")/>
                        <li class="list-group-item px-0">
                            <a class="d-inline-flex align-items-baseline flex-wrap gap-2 text-reset text-decoration-underline"
                                href="#encodeForHTMLAttribute(VARIABLES.focoHistorySearchUrl & '&atleta=' & val(qFocoBuscaAtletas.id_usuario) & VARIABLES.focoHistoryAnchor)#">
                                <span>#encodeForHTML(len(VARIABLES.focoHistoryResultName) ? VARIABLES.focoHistoryResultName : "Atleta sem nome")#</span>
                                <span class="small text-body-secondary">ID #val(qFocoBuscaAtletas.id_usuario)#</span>
                            </a>
                        </li>
                    </cfoutput>
                </ul>
                <cfif qFocoBuscaAtletas.recordCount EQ 25>
                    <p class="small text-body-secondary mt-2 mb-0">Até 25 atletas por busca. Refine pelo nome ou pelo ID.</p>
                </cfif>
            <cfelse>
                <p class="small mt-3 mb-0">Nenhum inscrito encontrado para essa busca.</p>
            </cfif>
        </cfif>

        <cfif qFocoAtleta.recordCount>
            <cfset VARIABLES.focoHistoryAthleteUrl = VARIABLES.focoHistorySearchUrl & "&atleta=" & val(qFocoAtleta.id_usuario[1])/>
            <cfset VARIABLES.focoHistoryAthleteName = trim(qFocoAtleta.nome[1] ?: "")/>
            <div class="d-flex flex-wrap align-items-baseline justify-content-between gap-2 mt-3 mb-2">
                <h4 class="h6 text-break mb-0" id="foco-point-history-athlete">
                    <cfoutput>#encodeForHTML(len(VARIABLES.focoHistoryAthleteName) ? VARIABLES.focoHistoryAthleteName : "Atleta sem nome")#
                        <span class="small text-body-secondary">· ID #val(qFocoAtleta.id_usuario[1])#</span></cfoutput>
                </h4>
                <cfif len(URL.busca_pontos)>
                    <cfoutput>
                        <a class="small text-reset text-decoration-underline"
                            href="#encodeForHTMLAttribute(VARIABLES.focoHistorySearchUrl & VARIABLES.focoHistoryAnchor)#">Voltar aos resultados</a>
                    </cfoutput>
                </cfif>
            </div>

            <cfif qFocoHistorico.recordCount>
                <p class="small text-body-secondary mb-2">Um registro por dia de atividade. Horários em Brasília.</p>
                <div class="table-responsive" role="region" tabindex="0" aria-labelledby="foco-point-history-athlete">
                    <table class="table table-sm align-middle mb-0">
                        <thead>
                            <tr>
                                <th scope="col">Data da atividade</th>
                                <th scope="col">Situação</th>
                                <th scope="col">Última tentativa</th>
                                <th scope="col" class="text-end">Tentativas</th>
                                <th scope="col">Retorno HTTP</th>
                                <th scope="col">Confirmação</th>
                            </tr>
                        </thead>
                        <tbody>
                            <cfoutput query="qFocoHistorico">
                                <tr>
                                    <th scope="row" class="text-nowrap">#encodeForHTML(qFocoHistorico.data_atividade)#</th>
                                    <td>#encodeForHTML(VARIABLES.focoPointLabels[qFocoHistorico.motivo])#</td>
                                    <td class="text-nowrap">#len(trim(qFocoHistorico.ultima_tentativa ?: "")) ? encodeForHTML(qFocoHistorico.ultima_tentativa) : "—"#</td>
                                    <td class="text-end">#val(qFocoHistorico.tentativas)#</td>
                                    <td>
                                        <cfif val(qFocoHistorico.retorno_http ?: 0) GT 0>
                                            HTTP #val(qFocoHistorico.retorno_http)#
                                        <cfelseif val(qFocoHistorico.tentativas) GT 0>
                                            Sem resposta HTTP
                                        <cfelse>
                                            —
                                        </cfif>
                                    </td>
                                    <td class="text-nowrap">#len(trim(qFocoHistorico.confirmado_em ?: "")) ? encodeForHTML(qFocoHistorico.confirmado_em) : "—"#</td>
                                </tr>
                            </cfoutput>
                        </tbody>
                    </table>
                </div>

                <cfset VARIABLES.focoHistoryPageCount = ceiling(val(qFocoHistorico.total_registros[1]) / VARIABLES.focoPointPageSize)/>
                <cfif VARIABLES.focoHistoryPageCount GT 1>
                    <cfoutput>
                        <nav class="d-flex flex-wrap align-items-center justify-content-between gap-2 mt-3" aria-label="Paginação do histórico de pontos">
                            <span class="small">Página #URL.pagina_pontos# de #VARIABLES.focoHistoryPageCount#</span>
                            <div class="d-flex gap-2">
                                <cfif URL.pagina_pontos GT 1>
                                    <a class="btn btn-sm btn-outline-secondary" href="#encodeForHTMLAttribute(VARIABLES.focoHistoryAthleteUrl & '&pagina_pontos=' & (URL.pagina_pontos - 1) & VARIABLES.focoHistoryAnchor)#">Anterior</a>
                                </cfif>
                                <cfif URL.pagina_pontos LT VARIABLES.focoHistoryPageCount>
                                    <a class="btn btn-sm btn-outline-secondary" href="#encodeForHTMLAttribute(VARIABLES.focoHistoryAthleteUrl & '&pagina_pontos=' & (URL.pagina_pontos + 1) & VARIABLES.focoHistoryAnchor)#">Próxima</a>
                                </cfif>
                            </div>
                        </nav>
                    </cfoutput>
                </cfif>
            <cfelseif URL.pagina_pontos GT 1>
                <p class="small mb-0">
                    Não há registros nesta página.
                    <cfoutput><a class="text-reset text-decoration-underline" href="#encodeForHTMLAttribute(VARIABLES.focoHistoryAthleteUrl & VARIABLES.focoHistoryAnchor)#">Voltar à primeira página</a></cfoutput>
                </p>
            <cfelse>
                <p class="small mb-0">Ainda não há registros de pontos para este atleta.</p>
            </cfif>
        </cfif>
    </div>
</section>
