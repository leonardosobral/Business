<cfset VARIABLES.helpdeskShowTicketForm = (isDefined("URL.ticket_novo") AND URL.ticket_novo) OR qHelpdeskTicketEdit.recordcount/>

<style>
  .support-board {
    display: grid;
    gap: 1rem;
  }

  .support-stat-card,
  .support-panel-card,
  .support-ticket-card,
  .support-thread-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
    background: rgba(255,255,255,0.02);
  }

  .support-stat-value {
    font-size: 1.8rem;
    font-weight: 700;
    line-height: 1;
  }

  .support-ticket-card {
    display: block;
    color: inherit;
    text-decoration: none;
    transition: transform 0.15s ease, border-color 0.15s ease, background 0.15s ease;
  }

  .support-ticket-card:hover {
    transform: translateY(-1px);
    border-color: rgba(255,255,255,0.16);
    background: rgba(255,255,255,0.04);
  }

  .support-ticket-card.is-active {
    border-color: rgba(228, 161, 27, 0.55);
    background: rgba(228, 161, 27, 0.08);
  }

  .support-ticket-meta {
    font-size: 0.82rem;
    color: rgba(255,255,255,0.66);
  }

  .support-message {
    border-radius: 1rem;
    padding: 1rem;
    border: 1px solid rgba(255,255,255,0.08);
    background: rgba(255,255,255,0.03);
  }

  .support-message.is-admin {
    border-color: rgba(13, 110, 253, 0.35);
    background: rgba(13, 110, 253, 0.08);
  }

  .support-message-header {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
    margin-bottom: 0.75rem;
  }

  .support-message-body {
    white-space: pre-wrap;
    overflow-wrap: anywhere;
  }

  .support-thread {
    display: grid;
    gap: 0.9rem;
  }

  .support-empty-card {
    border: 1px dashed rgba(255,255,255,0.14);
    border-radius: 1rem;
    padding: 1.35rem;
    text-align: center;
    color: rgba(255,255,255,0.62);
  }

  .support-section-title {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }

  .support-form-grid {
    row-gap: 1rem;
  }

  @media (max-width: 991.98px) {
    .support-stat-value {
      font-size: 1.45rem;
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
              <h3 class="mb-1">Suporte Road Runners</h3>
              <p class="text-muted mb-0">Abra chamados, acompanhe o atendimento da equipe e responda quando houver atualização no seu caso.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Perfil de acesso</div>
              <div class="fw-semibold">Usuário autenticado</div>
            </div>
          </div>

          <hr/>

          <cfif NOT VARIABLES.helpdeskCanAccess>
            <div class="alert alert-warning mb-0">
              Faça login para acessar o suporte e abrir chamados para o Help Desk.
            </div>
          <cfelseif NOT VARIABLES.helpdeskTablesReady>
            <div class="alert alert-danger mb-3">
              O schema do Help Desk ainda não existe no banco. Execute o script <strong>/helpdesk/helpdesk_schema.sql</strong> antes de usar esta área.
            </div>
            <div class="support-empty-card">
              Após criar as tabelas, recarregue esta página para liberar a abertura e o acompanhamento dos chamados.
            </div>
          <cfelse>
            <div class="row g-3 mb-4">
              <div class="col-12 col-md-4">
                <div class="support-stat-card p-3 h-100">
                  <div class="small text-muted mb-2">Meus chamados</div>
                  <div class="support-stat-value"><cfoutput>#LSNumberFormat(qHelpdeskStats.total_chamados)#</cfoutput></div>
                </div>
              </div>
              <div class="col-12 col-md-4">
                <div class="support-stat-card p-3 h-100">
                  <div class="small text-muted mb-2">Em aberto</div>
                  <div class="support-stat-value"><cfoutput>#LSNumberFormat(qHelpdeskStats.total_abertos)#</cfoutput></div>
                </div>
              </div>
              <div class="col-12 col-md-4">
                <div class="support-stat-card p-3 h-100">
                  <div class="small text-muted mb-2">Setores ativos</div>
                  <div class="support-stat-value"><cfoutput>#LSNumberFormat(qHelpdeskStats.total_setores)#</cfoutput></div>
                </div>
              </div>
            </div>

            <div class="support-section-title mb-3">
              <div>
                <h5 class="mb-1">Meus chamados</h5>
                <p class="text-muted small mb-0">Escolha o setor certo para agilizar o atendimento e acompanhe todo o histórico por aqui.</p>
              </div>
              <cfoutput>
                <a class="btn btn-warning" href="./?pagina=#VARIABLES.helpdeskPage#&ticket_novo=1">Abrir chamado</a>
              </cfoutput>
            </div>

            <cfif VARIABLES.helpdeskShowTicketForm>
              <div class="support-panel-card p-4 mb-4">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                  <div>
                    <h5 class="mb-1"><cfif qHelpdeskTicketEdit.recordcount>Responder chamado<cfelse>Abrir novo chamado</cfif></h5>
                    <p class="text-muted small mb-0"><cfif qHelpdeskTicketEdit.recordcount>Use esta área para continuar a conversa com a equipe de suporte.<cfelse>Descreva seu problema com o máximo de contexto para agilizar a análise.</cfif></p>
                  </div>
                  <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.helpdeskPage#">Fechar</a></cfoutput>
                </div>

                <cfif qHelpdeskTicketEdit.recordcount>
                  <div class="row g-3 mb-4">
                    <div class="col-12 col-lg-4">
                      <div class="small text-muted">Protocolo</div>
                      <div class="fw-semibold"><cfoutput>#htmlEditFormat(qHelpdeskTicketEdit.protocolo)#</cfoutput></div>
                    </div>
                    <div class="col-12 col-lg-4">
                      <div class="small text-muted">Setor</div>
                      <div class="fw-semibold"><cfoutput>#htmlEditFormat(qHelpdeskTicketEdit.nome_setor)#</cfoutput></div>
                    </div>
                    <div class="col-12 col-lg-4">
                      <div class="small text-muted">Status</div>
                      <div class="fw-semibold"><cfoutput>#htmlEditFormat(qHelpdeskTicketEdit.status)#</cfoutput></div>
                    </div>
                  </div>

                  <div class="support-thread-card p-3 mb-4">
                    <div class="support-thread">
                      <cfif qHelpdeskMensagens.recordcount>
                        <cfoutput query="qHelpdeskMensagens">
                          <div class="support-message <cfif IsBoolean(qHelpdeskMensagens.is_admin) ? qHelpdeskMensagens.is_admin : ListFindNoCase('true,1,yes,sim', trim(qHelpdeskMensagens.is_admin))>is-admin</cfif>">
                            <div class="support-message-header">
                              <div>
                                <div class="fw-semibold">#htmlEditFormat(qHelpdeskMensagens.nome_usuario)#</div>
                                <div class="small text-muted">#htmlEditFormat(qHelpdeskMensagens.email_usuario)#</div>
                              </div>
                              <div class="text-end small text-muted">
                                #LSDateFormat(qHelpdeskMensagens.created_at, "dd/mm/yyyy")# às #LSTimeFormat(qHelpdeskMensagens.created_at, "HH:mm")#
                              </div>
                            </div>
                            <div class="support-message-body">#htmlEditFormat(qHelpdeskMensagens.mensagem)#</div>
                          </div>
                        </cfoutput>
                      <cfelse>
                        <div class="support-empty-card">Ainda não há mensagens neste chamado.</div>
                      </cfif>
                    </div>
                  </div>

                  <cfoutput><form method="post" action="./?pagina=#VARIABLES.helpdeskPage#&ticket_id=#qHelpdeskTicketEdit.id_chamado#"></cfoutput>
                    <input type="hidden" name="helpdesk_action" value="responder_ticket"/>
                    <input type="hidden" name="ticket_id" value="<cfoutput>#qHelpdeskTicketEdit.id_chamado#</cfoutput>"/>

                    <div class="row support-form-grid">
                      <div class="col-12">
                        <label class="form-label">Nova mensagem</label>
                        <textarea class="form-control" name="ticket_mensagem" rows="5" placeholder="Escreva aqui sua atualização ou responda à equipe de atendimento." required></textarea>
                      </div>
                    </div>

                    <div class="d-flex flex-wrap gap-2 mt-3">
                      <button type="submit" class="btn btn-warning">Enviar resposta</button>
                      <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.helpdeskPage#">Voltar</a></cfoutput>
                    </div>
                  </form>
                <cfelse>
                  <cfoutput><form method="post" action="./?pagina=#VARIABLES.helpdeskPage#"></cfoutput>
                    <input type="hidden" name="helpdesk_action" value="novo_ticket"/>

                    <div class="row support-form-grid">
                      <div class="col-12 col-lg-5">
                        <label class="form-label">Setor</label>
                        <select class="form-select" name="ticket_setor_id" required>
                          <option value="">Selecione o setor</option>
                          <cfoutput query="qHelpdeskSetores">
                            <cfif qHelpdeskSetores.ativo>
                              <option value="#qHelpdeskSetores.id_setor#">#htmlEditFormat(qHelpdeskSetores.nome_setor)#</option>
                            </cfif>
                          </cfoutput>
                        </select>
                      </div>
                      <div class="col-12 col-lg-7">
                        <label class="form-label">Assunto</label>
                        <input class="form-control" type="text" name="ticket_assunto" maxlength="180" required/>
                      </div>
                      <div class="col-12">
                        <label class="form-label">Mensagem inicial</label>
                        <textarea class="form-control" name="ticket_mensagem" rows="6" placeholder="Explique o que aconteceu, o que você esperava e qualquer detalhe que ajude o suporte a resolver mais rápido." required></textarea>
                      </div>
                    </div>

                    <div class="d-flex flex-wrap gap-2 mt-3">
                      <button type="submit" class="btn btn-warning">Abrir chamado</button>
                      <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.helpdeskPage#">Cancelar</a></cfoutput>
                    </div>
                  </form>
                </cfif>
              </div>
            </cfif>

            <div class="row g-4">
              <div class="col-12 col-xl-5">
                <div class="support-panel-card p-3 h-100">
                  <div class="d-flex justify-content-between align-items-center gap-3 mb-3">
                    <h5 class="mb-0">Chamados abertos</h5>
                    <span class="badge badge-secondary"><cfoutput>#LSNumberFormat(qHelpdeskChamados.recordcount)#</cfoutput></span>
                  </div>

                  <div class="support-board">
                    <cfif qHelpdeskChamados.recordcount>
                      <cfoutput query="qHelpdeskChamados">
                        <a class="support-ticket-card p-3 <cfif isDefined('URL.ticket_id') AND URL.ticket_id EQ qHelpdeskChamados.id_chamado>is-active</cfif>" href="./?pagina=#VARIABLES.helpdeskPage#&ticket_id=#qHelpdeskChamados.id_chamado#">
                          <div class="d-flex justify-content-between gap-3 mb-2">
                            <div>
                              <div class="fw-semibold">#htmlEditFormat(qHelpdeskChamados.assunto)#</div>
                              <div class="support-ticket-meta">#htmlEditFormat(qHelpdeskChamados.protocolo)#</div>
                            </div>
                            <span class="badge <cfif qHelpdeskChamados.status EQ 'resolvido' OR qHelpdeskChamados.status EQ 'fechado'>badge-success<cfelseif qHelpdeskChamados.status EQ 'em_atendimento'>badge-primary<cfelseif qHelpdeskChamados.status EQ 'aguardando_cliente'>badge-info<cfelse>badge-warning</cfif>">#htmlEditFormat(qHelpdeskChamados.status)#</span>
                          </div>
                          <div class="support-ticket-meta mb-1">Setor: #htmlEditFormat(qHelpdeskChamados.nome_setor)#</div>
                          <div class="support-ticket-meta">Atualizado em #LSDateFormat(qHelpdeskChamados.updated_at, "dd/mm/yyyy")# às #LSTimeFormat(qHelpdeskChamados.updated_at, "HH:mm")#</div>
                        </a>
                      </cfoutput>
                    <cfelse>
                      <div class="support-empty-card">Você ainda não abriu nenhum chamado.</div>
                    </cfif>
                  </div>
                </div>
              </div>

              <div class="col-12 col-xl-7">
                <div class="support-panel-card p-4 h-100">
                  <cfif qHelpdeskTicketEdit.recordcount>
                    <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                      <div>
                        <h5 class="mb-1"><cfoutput>#htmlEditFormat(qHelpdeskTicketEdit.assunto)#</cfoutput></h5>
                        <p class="text-muted small mb-0"><cfoutput>Protocolo #htmlEditFormat(qHelpdeskTicketEdit.protocolo)#</cfoutput></p>
                      </div>
                      <cfoutput><a class="btn btn-sm btn-outline-warning" href="./?pagina=#VARIABLES.helpdeskPage#&ticket_id=#qHelpdeskTicketEdit.id_chamado#">Abrir conversa</a></cfoutput>
                    </div>

                    <div class="row g-3">
                      <div class="col-12 col-md-6">
                        <div class="small text-muted">Setor</div>
                        <div class="fw-semibold"><cfoutput>#htmlEditFormat(qHelpdeskTicketEdit.nome_setor)#</cfoutput></div>
                      </div>
                      <div class="col-12 col-md-6">
                        <div class="small text-muted">Responsável</div>
                        <div class="fw-semibold"><cfoutput>#len(trim(qHelpdeskTicketEdit.nome_responsavel)) ? htmlEditFormat(qHelpdeskTicketEdit.nome_responsavel) : "Não definido"#</cfoutput></div>
                      </div>
                      <div class="col-12 col-md-6">
                        <div class="small text-muted">Solicitante</div>
                        <div class="fw-semibold"><cfoutput>#htmlEditFormat(qHelpdeskTicketEdit.nome_usuario)#</cfoutput></div>
                      </div>
                      <div class="col-12 col-md-6">
                        <div class="small text-muted">Status</div>
                        <div class="fw-semibold"><cfoutput>#htmlEditFormat(qHelpdeskTicketEdit.status)#</cfoutput></div>
                      </div>
                    </div>
                  <cfelse>
                    <div class="support-empty-card h-100 d-flex flex-column justify-content-center">
                      <div class="mb-2 fw-semibold">Abra ou selecione um chamado</div>
                      <div>Use o botão acima para abrir um novo atendimento ou clique em um chamado existente para continuar a conversa.</div>
                    </div>
                  </cfif>
                </div>
              </div>
            </div>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
