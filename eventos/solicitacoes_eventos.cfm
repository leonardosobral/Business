<style>
  .event-request-panel {
    border: 1px solid var(--mdb-border-color);
    background: rgba(255, 255, 255, .03);
    border-radius: .5rem;
  }

  .event-request-table th,
  .event-request-table td {
    vertical-align: middle;
  }

  .event-request-meta {
    color: var(--mdb-secondary-color);
    font-size: .85rem;
  }
</style>

<cfif len(trim(VARIABLES.eventoSolicitacaoNoticeMessage))>
  <div class="alert alert-success mb-3" role="alert">
    <cfoutput>#htmlEditFormat(VARIABLES.eventoSolicitacaoNoticeMessage)#</cfoutput>
  </div>
</cfif>

<cfif len(trim(VARIABLES.eventoSolicitacaoErrorMessage))>
  <div class="alert alert-danger mb-3" role="alert">
    <cfoutput>#htmlEditFormat(VARIABLES.eventoSolicitacaoErrorMessage)#</cfoutput>
  </div>
</cfif>

<cfif VARIABLES.eventoSolicitacaoCanReview AND NOT VARIABLES.eventoSolicitacaoTablesReady>
  <div class="alert alert-warning mb-3" role="alert">
    A tabela <code>tb_conta_evento_solicitacoes</code> ainda nao foi encontrada pelo sistema.
  </div>
</cfif>

<cfif VARIABLES.eventoSolicitacaoTablesReady AND (VARIABLES.eventoSolicitacaoCanRequest OR VARIABLES.eventoSolicitacaoCanReview)>
  <div class="event-request-panel p-3 p-lg-4 mb-4">
    <div class="row g-4">
      <cfif VARIABLES.eventoSolicitacaoCanRequest>
        <div class="col-12 <cfif VARIABLES.eventoSolicitacaoCanReview>col-xl-7<cfelse>col-xl-12</cfif>">
          <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
            <div>
              <h5 class="mb-1">Solicitar vinculo de evento</h5>
              <p class="event-request-meta mb-0">Busque pelo link do RoadRunners, tag, ID ou nome da prova.</p>
            </div>
          </div>

          <cfoutput>
            <form method="get" action="/eventos/" class="mb-3">
              <div class="row g-2 align-items-end">
                <cfif qEventoSolicitacaoContas.recordcount GT 1>
                  <div class="col-12 col-lg-4">
                    <label class="form-label">Conta</label>
                    <select class="form-select" name="id_conta_solicitacao">
                      <cfloop query="qEventoSolicitacaoContas">
                        <option value="#qEventoSolicitacaoContas.id_conta#" <cfif VARIABLES.eventoSolicitacaoSelectedAccountId EQ qEventoSolicitacaoContas.id_conta>selected</cfif>>#htmlEditFormat(qEventoSolicitacaoContas.nome_conta)#</option>
                      </cfloop>
                    </select>
                  </div>
                <cfelse>
                  <input type="hidden" name="id_conta_solicitacao" value="#htmlEditFormat(VARIABLES.eventoSolicitacaoSelectedAccountId)#"/>
                </cfif>

                <div class="col-12 <cfif qEventoSolicitacaoContas.recordcount GT 1>col-lg-6<cfelse>col-lg-10</cfif>">
                  <label class="form-label">Evento</label>
                  <input class="form-control" type="text" name="evento_referencia" value="#htmlEditFormat(VARIABLES.eventoSolicitacaoReferencia)#" placeholder="https://roadrunners.run/evento/nome-da-prova/"/>
                </div>
                <div class="col-12 col-lg-2">
                  <button class="btn btn-outline-warning w-100" type="submit">Buscar</button>
                </div>
              </div>
            </form>
          </cfoutput>

          <cfif len(trim(VARIABLES.eventoSolicitacaoReferencia)) AND NOT qEventoSolicitacaoBusca.recordcount>
            <div class="alert alert-secondary mb-0" role="alert">
              Nenhum evento encontrado para a busca informada.
            </div>
          </cfif>

          <cfif qEventoSolicitacaoBusca.recordcount>
            <div class="table-responsive">
              <table class="table table-sm table-dark table-hover event-request-table mb-0">
                <thead>
                  <tr>
                    <th>Evento</th>
                    <th>Data</th>
                    <th>Status</th>
                    <th class="text-end">Acao</th>
                  </tr>
                </thead>
                <tbody>
                  <cfoutput query="qEventoSolicitacaoBusca">
                    <cfset VARIABLES.eventoSolicitacaoResultBlocked = false/>
                    <cfset VARIABLES.eventoSolicitacaoResultStatus = "Disponivel"/>
                    <cfif len(trim(qEventoSolicitacaoBusca.status_vinculo))>
                      <cfset VARIABLES.eventoSolicitacaoResultStatus = qEventoSolicitacaoBusca.status_vinculo/>
                    <cfelseif len(trim(qEventoSolicitacaoBusca.status_solicitacao))>
                      <cfset VARIABLES.eventoSolicitacaoResultStatus = qEventoSolicitacaoBusca.status_solicitacao/>
                    </cfif>
                    <cfset VARIABLES.eventoSolicitacaoResultBadge = "secondary"/>
                    <cfif VARIABLES.eventoSolicitacaoResultStatus EQ "ATIVO">
                      <cfset VARIABLES.eventoSolicitacaoResultBadge = "success"/>
                    <cfelseif VARIABLES.eventoSolicitacaoResultStatus EQ "PENDENTE">
                      <cfset VARIABLES.eventoSolicitacaoResultBadge = "warning"/>
                    <cfelseif VARIABLES.eventoSolicitacaoResultStatus NEQ "Disponivel">
                      <cfset VARIABLES.eventoSolicitacaoResultBadge = "danger"/>
                    </cfif>
                    <cfif qEventoSolicitacaoBusca.status_vinculo EQ "ATIVO" OR qEventoSolicitacaoBusca.status_solicitacao EQ "PENDENTE">
                      <cfset VARIABLES.eventoSolicitacaoResultBlocked = true/>
                    </cfif>
                    <tr>
                      <td>
                        <div class="fw-semibold">#htmlEditFormat(qEventoSolicitacaoBusca.nome_evento)#</div>
                        <div class="event-request-meta">#htmlEditFormat(qEventoSolicitacaoBusca.cidade)#/#htmlEditFormat(qEventoSolicitacaoBusca.estado)# - #htmlEditFormat(qEventoSolicitacaoBusca.tag)#</div>
                      </td>
                      <td>
                        <cfif isDate(qEventoSolicitacaoBusca.data_inicial)>#dateFormat(qEventoSolicitacaoBusca.data_inicial, "dd/mm/yyyy")#</cfif>
                        <cfif isDate(qEventoSolicitacaoBusca.data_final) AND qEventoSolicitacaoBusca.data_final NEQ qEventoSolicitacaoBusca.data_inicial>
                          <span class="event-request-meta">ate #dateFormat(qEventoSolicitacaoBusca.data_final, "dd/mm/yyyy")#</span>
                        </cfif>
                      </td>
                      <td><span class="badge badge-#VARIABLES.eventoSolicitacaoResultBadge#">#htmlEditFormat(VARIABLES.eventoSolicitacaoResultStatus)#</span></td>
                      <td class="text-end">
                        <form method="post" action="/eventos/" class="d-inline-block">
                          <input type="hidden" name="evento_solicitacao_action" value="solicitar"/>
                          <input type="hidden" name="id_conta_solicitacao" value="#htmlEditFormat(VARIABLES.eventoSolicitacaoSelectedAccountId)#"/>
                          <input type="hidden" name="id_evento" value="#qEventoSolicitacaoBusca.id_evento#"/>
                          <input type="hidden" name="evento_referencia" value="#htmlEditFormat(VARIABLES.eventoSolicitacaoReferencia)#"/>
                          <button class="btn btn-sm btn-warning" type="submit" <cfif VARIABLES.eventoSolicitacaoResultBlocked>disabled</cfif>>Solicitar</button>
                        </form>
                      </td>
                    </tr>
                  </cfoutput>
                </tbody>
              </table>
            </div>
          </cfif>

          <cfif qEventoMinhasSolicitacoes.recordcount>
            <h6 class="mt-4 mb-2">Minhas solicitacoes</h6>
            <div class="table-responsive">
              <table class="table table-sm table-dark table-striped mb-0">
                <thead>
                  <tr>
                    <th>Evento</th>
                    <th>Conta</th>
                    <th>Status</th>
                    <th>Solicitado em</th>
                  </tr>
                </thead>
                <tbody>
                  <cfoutput query="qEventoMinhasSolicitacoes">
                    <tr>
                      <td>
                        <div class="fw-semibold">#htmlEditFormat(qEventoMinhasSolicitacoes.nome_evento)#</div>
                        <div class="event-request-meta">#htmlEditFormat(qEventoMinhasSolicitacoes.cidade)#/#htmlEditFormat(qEventoMinhasSolicitacoes.estado)# - #htmlEditFormat(qEventoMinhasSolicitacoes.tag)#</div>
                      </td>
                      <td>#htmlEditFormat(qEventoMinhasSolicitacoes.nome_conta)#</td>
                      <td>#htmlEditFormat(qEventoMinhasSolicitacoes.status)#</td>
                      <td><cfif isDate(qEventoMinhasSolicitacoes.data_criacao)>#dateFormat(qEventoMinhasSolicitacoes.data_criacao, "dd/mm/yyyy")#</cfif></td>
                    </tr>
                  </cfoutput>
                </tbody>
              </table>
            </div>
          </cfif>
        </div>
      </cfif>

      <cfif VARIABLES.eventoSolicitacaoCanReview>
        <div class="col-12 <cfif VARIABLES.eventoSolicitacaoCanRequest>col-xl-5<cfelse>col-xl-12</cfif>">
          <div class="d-flex justify-content-between align-items-start gap-2 mb-3">
            <div>
              <h5 class="mb-1">Solicitacoes pendentes</h5>
              <p class="event-request-meta mb-0">Aprovacao libera o evento para a conta.</p>
            </div>
            <span class="badge badge-warning"><cfoutput>#qEventoSolicitacoesPendentes.recordcount#</cfoutput></span>
          </div>

          <cfif NOT qEventoSolicitacoesPendentes.recordcount>
            <div class="alert alert-secondary mb-0" role="alert">
              Nenhuma solicitacao pendente.
            </div>
          <cfelse>
            <div class="d-flex flex-column gap-3">
              <cfoutput query="qEventoSolicitacoesPendentes">
                <div class="border rounded p-3">
                  <div class="fw-semibold mb-1">#htmlEditFormat(qEventoSolicitacoesPendentes.nome_evento)#</div>
                  <div class="event-request-meta mb-2">
                    #htmlEditFormat(qEventoSolicitacoesPendentes.nome_conta)# -
                    #htmlEditFormat(qEventoSolicitacoesPendentes.cidade)#/#htmlEditFormat(qEventoSolicitacoesPendentes.estado)# -
                    #htmlEditFormat(qEventoSolicitacoesPendentes.tag)#
                  </div>
                  <cfif len(trim(qEventoSolicitacoesPendentes.usuario_solicitante)) OR len(trim(qEventoSolicitacoesPendentes.email_solicitante))>
                    <div class="event-request-meta mb-2">Solicitado por #htmlEditFormat(qEventoSolicitacoesPendentes.usuario_solicitante)# <cfif len(trim(qEventoSolicitacoesPendentes.email_solicitante))>(#htmlEditFormat(qEventoSolicitacoesPendentes.email_solicitante)#)</cfif></div>
                  </cfif>
                  <cfif len(trim(qEventoSolicitacoesPendentes.url_informada))>
                    <div class="event-request-meta mb-2">Origem: #htmlEditFormat(qEventoSolicitacoesPendentes.url_informada)#</div>
                  </cfif>
                  <form method="post" action="/eventos/">
                    <input type="hidden" name="id_solicitacao" value="#qEventoSolicitacoesPendentes.id_solicitacao#"/>
                    <div class="mb-2">
                      <input class="form-control form-control-sm" type="text" name="observacao_revisor" placeholder="Observacao opcional"/>
                    </div>
                    <div class="d-flex gap-2 justify-content-end">
                      <button class="btn btn-sm btn-outline-danger" type="submit" name="evento_solicitacao_action" value="negar">Negar</button>
                      <button class="btn btn-sm btn-warning" type="submit" name="evento_solicitacao_action" value="aprovar">Aprovar</button>
                    </div>
                  </form>
                </div>
              </cfoutput>
            </div>
          </cfif>
        </div>
      </cfif>
    </div>
  </div>
</cfif>
