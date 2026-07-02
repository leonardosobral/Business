<cfif isDefined("VARIABLES.adminRestrictByConta")
    AND VARIABLES.adminRestrictByConta
    AND NOT (isDefined("VARIABLES.eventosShowOnboarding") AND VARIABLES.eventosShowOnboarding)
    AND NOT len(trim(URL.id_evento))>

    <cfset VARIABLES.eventosClienteTotal = qEventos.recordcount/>
    <cfset VARIABLES.eventosClienteComInscricao = qStatsInsc.recordcount/>
    <cfset VARIABLES.eventosClienteComEndereco = qStatsEnd.recordcount/>
    <cfset VARIABLES.eventosClienteComConteudo = qStatsConteudo.recordcount/>
    <cfset VARIABLES.eventosClienteIncompletos = 0/>
    <cfset VARIABLES.eventosClientePrimeiroIncompletoId = ""/>
    <cfset VARIABLES.eventosClientePrimeiroIncompletoNome = ""/>

    <cfloop query="qEventos">
        <cfset VARIABLES.eventosClienteCamposPendentes = 0/>
        <cfset VARIABLES.eventosClienteUrlInscricao = isNull(qEventos.url_inscricao) ? "" : qEventos.url_inscricao/>
        <cfset VARIABLES.eventosClienteEndereco = isNull(qEventos.endereco) ? "" : qEventos.endereco/>
        <cfset VARIABLES.eventosClienteDescricao = isNull(qEventos.descricao) ? "" : qEventos.descricao/>
        <cfset VARIABLES.eventosClienteCategorias = isNull(qEventos.categorias) ? "" : qEventos.categorias/>
        <cfif NOT len(trim(VARIABLES.eventosClienteUrlInscricao))>
            <cfset VARIABLES.eventosClienteCamposPendentes = VARIABLES.eventosClienteCamposPendentes + 1/>
        </cfif>
        <cfif NOT len(trim(VARIABLES.eventosClienteEndereco))>
            <cfset VARIABLES.eventosClienteCamposPendentes = VARIABLES.eventosClienteCamposPendentes + 1/>
        </cfif>
        <cfif NOT len(trim(VARIABLES.eventosClienteDescricao))>
            <cfset VARIABLES.eventosClienteCamposPendentes = VARIABLES.eventosClienteCamposPendentes + 1/>
        </cfif>
        <cfif NOT len(trim(VARIABLES.eventosClienteCategorias))>
            <cfset VARIABLES.eventosClienteCamposPendentes = VARIABLES.eventosClienteCamposPendentes + 1/>
        </cfif>

        <cfif VARIABLES.eventosClienteCamposPendentes GT 0>
            <cfset VARIABLES.eventosClienteIncompletos = VARIABLES.eventosClienteIncompletos + 1/>
            <cfif NOT len(trim(VARIABLES.eventosClientePrimeiroIncompletoId))>
                <cfset VARIABLES.eventosClientePrimeiroIncompletoId = qEventos.id_evento/>
                <cfset VARIABLES.eventosClientePrimeiroIncompletoNome = qEventos.nome_evento/>
            </cfif>
        </cfif>
    </cfloop>

    <section class="business-page mb-4">
        <div class="card shadow-0 business-page-card">
            <div class="card-body business-page-body">
                <div class="business-page-header d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
                    <div>
                        <div class="business-label mb-1">Eventos da conta</div>
                        <h4 class="mb-1">Próximo passo nos seus eventos</h4>
                        <p class="text-muted mb-0">
                            <cfif VARIABLES.eventosClienteTotal GT 0>
                                Mantenha as provas prontas para inscrição, divulgação e acompanhamento.
                            <cfelse>
                                Nenhum evento apareceu com os filtros atuais.
                            </cfif>
                        </p>
                    </div>
                    <div class="business-page-actions">
                        <a class="btn btn-sm btn-outline-warning" href="/eventos/#event-request-panel">Solicitar outro evento</a>
                        <cfif len(trim(URL.busca)) OR len(trim(URL.estado)) OR len(trim(URL.periodo))>
                            <a class="btn btn-sm btn-outline-light" href="/eventos/">Limpar filtros</a>
                        </cfif>
                    </div>
                </div>

                <cfif VARIABLES.eventosClienteTotal GT 0>
                    <div class="business-metric-strip mb-3">
                        <div class="business-mini-metric">
                            <span class="business-label">Vinculados</span>
                            <strong><cfoutput>#numberFormat(VARIABLES.eventosClienteTotal, "9,999")#</cfoutput></strong>
                        </div>
                        <div class="business-mini-metric">
                            <span class="business-label">Com inscrição</span>
                            <strong><cfoutput>#numberFormat(VARIABLES.eventosClienteComInscricao, "9,999")#</cfoutput></strong>
                        </div>
                        <div class="business-mini-metric">
                            <span class="business-label">Com conteúdo</span>
                            <strong><cfoutput>#numberFormat(VARIABLES.eventosClienteComConteudo, "9,999")#</cfoutput></strong>
                        </div>
                        <div class="business-mini-metric">
                            <span class="business-label">Pendentes</span>
                            <strong><cfoutput>#numberFormat(VARIABLES.eventosClienteIncompletos, "9,999")#</cfoutput></strong>
                        </div>
                    </div>

                    <div class="business-step-grid">
                        <div class="business-step is-complete">
                            <div class="business-step-top">
                                <span class="business-step-marker"><i class="fa-solid fa-check"></i></span>
                                <span class="business-step-status">Concluído</span>
                            </div>
                            <h5 class="mb-2">Evento aprovado</h5>
                            <p class="text-muted mb-0">A prova já está vinculada à conta e pode ser operada pela equipe.</p>
                            <div class="business-step-action">
                                <a class="btn btn-sm btn-outline-warning w-100" href="/eventos/">Ver lista</a>
                            </div>
                        </div>

                        <div class="business-step <cfif VARIABLES.eventosClienteIncompletos GT 0>is-current<cfelse>is-complete</cfif>">
                            <div class="business-step-top">
                                <span class="business-step-marker"><cfif VARIABLES.eventosClienteIncompletos GT 0>2<cfelse><i class="fa-solid fa-check"></i></cfif></span>
                                <span class="business-step-status"><cfif VARIABLES.eventosClienteIncompletos GT 0>Pendente<cfelse>Concluído</cfif></span>
                            </div>
                            <h5 class="mb-2">Completar publicação</h5>
                            <p class="text-muted mb-0">
                                <cfif VARIABLES.eventosClienteIncompletos GT 0>
                                    <cfoutput>#VARIABLES.eventosClienteIncompletos#</cfoutput> evento(s) ainda precisam de dados básicos.
                                <cfelse>
                                    Os eventos filtrados têm os dados principais preenchidos.
                                </cfif>
                            </p>
                            <div class="business-step-action">
                                <cfif len(trim(VARIABLES.eventosClientePrimeiroIncompletoId))>
                                    <cfoutput><a class="btn btn-sm btn-warning w-100" href="/eventos/?id_evento=#VARIABLES.eventosClientePrimeiroIncompletoId#">Completar agora</a></cfoutput>
                                <cfelse>
                                    <a class="btn btn-sm btn-outline-warning w-100" href="/eventos/">Revisar eventos</a>
                                </cfif>
                            </div>
                        </div>

                        <div class="business-step is-current">
                            <div class="business-step-top">
                                <span class="business-step-marker">3</span>
                                <span class="business-step-status">Contínuo</span>
                            </div>
                            <h5 class="mb-2">Operar a prova</h5>
                            <p class="text-muted mb-0">Use os dados completos para acompanhar inscrições, criar campanhas e publicar cupons.</p>
                            <div class="business-step-action d-grid gap-2">
                                <a class="btn btn-sm btn-outline-warning" href="/inscricoes/">Ver inscrições</a>
                                <a class="btn btn-sm btn-outline-light" href="/ads/">Turbinar</a>
                            </div>
                        </div>
                    </div>
                <cfelse>
                    <div class="business-empty-state">
                        <h5 class="mb-2">Nenhum evento encontrado</h5>
                        <p class="text-muted mb-3">Limpe os filtros ou solicite o vínculo de uma prova para começar.</p>
                        <div class="business-empty-actions">
                            <a class="btn btn-warning" href="/eventos/#event-request-panel">Solicitar evento</a>
                            <a class="btn btn-outline-light" href="/eventos/">Limpar filtros</a>
                        </div>
                    </div>
                </cfif>
            </div>
        </div>
    </section>
</cfif>
