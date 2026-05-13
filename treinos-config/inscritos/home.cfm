<cfinclude template="../includes/athletes_backend.cfm"/>

<style>
  .treino-athletes-table {
    min-width: 1120px;
  }

  .treino-athletes-table td,
  .treino-athletes-table th {
    vertical-align: middle;
  }

  .treino-athletes-cell {
    max-width: 280px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  @media (max-width: 991.98px) {
    .treino-athletes-table {
      min-width: 100%;
    }

    .treino-athletes-table thead {
      display: none;
    }

    .treino-athletes-table,
    .treino-athletes-table tbody,
    .treino-athletes-table tr,
    .treino-athletes-table td {
      display: block;
      width: 100%;
    }

    .treino-athletes-table tbody {
      display: grid;
      gap: 1rem;
    }

    .treino-athletes-table tr {
      background: rgba(255,255,255,0.03);
      border: 1px solid rgba(255,255,255,0.08);
      border-radius: 1rem;
      overflow: hidden;
    }

    .treino-athletes-table td {
      position: relative;
      padding: 0.9rem 1rem 0.9rem 47%;
      border: 0;
      border-bottom: 1px solid rgba(255,255,255,0.06);
      min-height: 52px;
      text-align: left;
    }

    .treino-athletes-table td:last-child {
      border-bottom: 0;
    }

    .treino-athletes-table td::before {
      content: attr(data-label);
      position: absolute;
      top: 0.9rem;
      left: 1rem;
      width: calc(47% - 1.5rem);
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      color: rgba(255,255,255,0.66);
      white-space: normal;
    }
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Treinos - Atletas inscritos</h3>
              <p class="text-muted mb-0">
                <cfoutput>
                  Evento <strong>## #qTreinoEventoInfo.id_evento#</strong>:
                  <strong>#htmlEditFormat(qTreinoEventoInfo.nome_evento)#</strong>
                </cfoutput>
              </p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Total de inscritos</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qTreinoInscritos.recordcount)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfoutput>
            <div class="d-flex flex-column flex-lg-row gap-2 justify-content-between align-items-lg-end mb-3">
              <a class="btn btn-outline-secondary" href="/treinos-config/?pagina=1">Voltar para configurações</a>

              <form method="get" action="./" class="w-100" style="max-width: 520px;">
                <input type="hidden" name="id_evento" value="#qTreinoEventoInfo.id_evento#"/>
                <div class="input-group">
                  <input class="form-control" type="text" name="busca" value="#htmlEditFormat(URL.busca)#" placeholder="Buscar por nome, e-mail, documento, celular ou pedido"/>
                  <button class="btn btn-outline-warning" type="submit">Buscar</button>
                  <a class="btn btn-outline-secondary" href="./?id_evento=#qTreinoEventoInfo.id_evento#">Limpar</a>
                </div>
              </form>
            </div>
          </cfoutput>

          <div class="table-responsive">
            <table class="table table-sm table-striped table-hover treino-athletes-table">
              <thead>
                <tr>
                  <th>Atleta</th>
                  <th>Cidade</th>
                  <th>Celular</th>
                  <th>Assessoria</th>
                  <th>Pace</th>
                  <th>Pedido</th>
                  <th>Inscrição</th>
                  <th>Check-in</th>
                </tr>
              </thead>
              <tbody>
                <cfif qTreinoInscritos.recordcount>
                  <cfoutput query="qTreinoInscritos">
                    <tr>
                      <td class="treino-athletes-cell" data-label="Atleta">
                        <cfif len(trim(qTreinoInscritos.slug_pagina))>
                          <a href="https://roadrunners.run/atleta/#urlEncodedFormat(qTreinoInscritos.slug_pagina)#" target="_blank" rel="noopener noreferrer">#htmlEditFormat(qTreinoInscritos.nome_atleta)#</a>
                        <cfelse>
                          #htmlEditFormat(qTreinoInscritos.nome_atleta)#
                        </cfif>
                        <div class="small text-muted">Usuário ## #qTreinoInscritos.id_usuario#</div>
                        <cfif len(trim(qTreinoInscritos.email))>
                          <div class="small text-muted">#htmlEditFormat(qTreinoInscritos.email)#</div>
                        </cfif>
                      </td>
                      <td class="treino-athletes-cell" data-label="Cidade">
                        <cfif len(trim(qTreinoInscritos.cidade)) OR len(trim(qTreinoInscritos.estado))>
                          #htmlEditFormat(qTreinoInscritos.cidade)#
                          <cfif len(trim(qTreinoInscritos.estado))>
                            <div class="small text-muted">#htmlEditFormat(qTreinoInscritos.estado)#</div>
                          </cfif>
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                      </td>
                      <td class="treino-athletes-cell" data-label="Celular">
                        <cfif len(trim(qTreinoInscritos.celular))>
                          #htmlEditFormat(qTreinoInscritos.celular)#
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                      </td>
                      <td class="treino-athletes-cell" data-label="Assessoria">
                        <cfif len(trim(qTreinoInscritos.assessoria))>
                          #htmlEditFormat(qTreinoInscritos.assessoria)#
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                      </td>
                      <td class="treino-athletes-cell" data-label="Pace">
                        <cfif len(trim(qTreinoInscritos.pace))>
                          #htmlEditFormat(qTreinoInscritos.pace)#
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                      </td>
                      <td class="treino-athletes-cell" data-label="Pedido">
                        <cfif len(trim(qTreinoInscritos.num_pedido))>
                          #htmlEditFormat(qTreinoInscritos.num_pedido)#
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                        <cfif len(trim(qTreinoInscritos.documento))>
                          <div class="small text-muted">Doc: #htmlEditFormat(qTreinoInscritos.documento)#</div>
                        </cfif>
                      </td>
                      <td class="treino-athletes-cell" data-label="Inscrição">
                        <cfif isDate(qTreinoInscritos.data_pedido)>
                          #htmlEditFormat(lsDateFormat(qTreinoInscritos.data_pedido, "dd/mm/yyyy"))#
                          <div class="small text-muted">#htmlEditFormat(timeFormat(qTreinoInscritos.data_pedido, "HH:mm"))#</div>
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                      </td>
                      <td class="treino-athletes-cell" data-label="Check-in">
                        <cfif isDate(qTreinoInscritos.data_checkin)>
                          #htmlEditFormat(lsDateFormat(qTreinoInscritos.data_checkin, "dd/mm/yyyy"))#
                          <div class="small text-muted">#htmlEditFormat(timeFormat(qTreinoInscritos.data_checkin, "HH:mm"))#</div>
                        <cfelse>
                          <span class="text-muted">Pendente</span>
                        </cfif>
                      </td>
                    </tr>
                  </cfoutput>
                <cfelse>
                  <tr>
                    <td colspan="8" class="text-center text-muted py-4">Nenhum atleta inscrito encontrado para este treino.</td>
                  </tr>
                </cfif>
              </tbody>
            </table>
          </div>

        </div>
      </div>
    </div>
  </div>
</section>
