<cfset VARIABLES.helpdeskShowTicketForm = (isDefined("URL.ticket_novo") AND URL.ticket_novo) OR qHelpdeskTicketEdit.recordcount/>
<cfset VARIABLES.helpdeskShowSetorForm = VARIABLES.helpdeskIsAdmin AND ((isDefined("URL.setor_novo") AND URL.setor_novo) OR qHelpdeskSetorEdit.recordcount)/>

<style>
  .helpdesk-board {
    display: grid;
    gap: 1rem;
  }

  .helpdesk-stat-card,
  .helpdesk-panel-card,
  .helpdesk-ticket-card,
  .helpdesk-thread-card,
  .helpdesk-setor-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
    background: rgba(255,255,255,0.02);
  }

  .helpdesk-stat-value {
    font-size: 1.8rem;
    font-weight: 700;
    line-height: 1;
  }

  .helpdesk-ticket-card {
    display: block;
    color: inherit;
    text-decoration: none;
    transition: transform 0.15s ease, border-color 0.15s ease, background 0.15s ease;
  }

  .helpdesk-ticket-card:hover {
    transform: translateY(-1px);
    border-color: rgba(255,255,255,0.16);
    background: rgba(255,255,255,0.04);
  }

  .helpdesk-ticket-card.is-active {
    border-color: rgba(228, 161, 27, 0.55);
    background: rgba(228, 161, 27, 0.08);
  }

  .helpdesk-ticket-meta {
    font-size: 0.82rem;
    color: rgba(255,255,255,0.66);
  }

  .helpdesk-message {
    border-radius: 1rem;
    padding: 1rem;
    border: 1px solid rgba(255,255,255,0.08);
    background: rgba(255,255,255,0.03);
  }

  .helpdesk-message.is-admin {
    border-color: rgba(13, 110, 253, 0.35);
    background: rgba(13, 110, 253, 0.08);
  }

  .helpdesk-message-header {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
    margin-bottom: 0.75rem;
  }

  .helpdesk-message-body {
    white-space: pre-wrap;
    overflow-wrap: anywhere;
  }

  .helpdesk-thread {
    display: grid;
    gap: 0.9rem;
  }

  .helpdesk-empty-card {
    border: 1px dashed rgba(255,255,255,0.14);
    border-radius: 1rem;
    padding: 1.35rem;
    text-align: center;
    color: rgba(255,255,255,0.62);
  }

  .helpdesk-section-title {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }

  .helpdesk-form-grid {
    row-gap: 1rem;
  }

  @media (max-width: 991.98px) {
    .helpdesk-stat-value {
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
              <h3 class="mb-1">Help Desk Road Runners</h3>
              <p class="text-muted mb-0">Painel administrativo de atendimento para os chamados abertos pelos usuários autenticados do site Road Runners.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Perfil de acesso</div>
              <div class="fw-semibold"><cfif VARIABLES.helpdeskIsAdmin>Administrador<cfelse>Sem acesso</cfif></div>
            </div>
          </div>

          <hr/>

          <cfif NOT VARIABLES.helpdeskCanAccess>
            <div class="alert alert-warning mb-0">
              Esta área do Business é exclusiva para usuários com <strong>ADMIN = TRUE</strong>, responsáveis por tratar e solucionar os chamados vindos do site Road Runners.
            </div>
          <cfelseif NOT VARIABLES.helpdeskTablesReady>
            <div class="alert alert-danger mb-3">
              O schema do Help Desk ainda não existe no banco. Execute o script <strong>/helpdesk/helpdesk_schema.sql</strong> antes de usar esta área.
            </div>
            <div class="helpdesk-empty-card">
              Após criar as tabelas, recarregue esta página para liberar os chamados, setores e responsáveis.
            </div>
          <cfelse>
            <div class="row g-3 mb-4">
              <div class="col-12 col-md-4">
                <div class="helpdesk-stat-card p-3 h-100">
                  <div class="small text-muted mb-2">Chamados visíveis</div>
                  <div class="helpdesk-stat-value"><cfoutput>#LSNumberFormat(qHelpdeskStats.total_chamados)#</cfoutput></div>
                </div>
              </div>
              <div class="col-12 col-md-4">
                <div class="helpdesk-stat-card p-3 h-100">
                  <div class="small text-muted mb-2">Em aberto</div>
                  <div class="helpdesk-stat-value"><cfoutput>#LSNumberFormat(qHelpdeskStats.total_abertos)#</cfoutput></div>
                </div>
              </div>
              <div class="col-12 col-md-4">
                <div class="helpdesk-stat-card p-3 h-100">
                  <div class="small text-muted mb-2">Setores ativos</div>
                  <div class="helpdesk-stat-value"><cfoutput>#LSNumberFormat(qHelpdeskStats.total_setores)#</cfoutput></div>
                </div>
              </div>
            </div>

            <div class="helpdesk-section-title mb-3">
              <div>
                <h5 class="mb-1">Fila de chamados</h5>
                <p class="text-muted small mb-0">Visão administrativa completa dos chamados e das interações registradas pelos usuários do site.</p>
              </div>
              <cfoutput>
                <a class="btn btn-warning" href="./?pagina=#VARIABLES.helpdeskPage#&ticket_novo=1">Novo chamado manual</a>
              </cfoutput>
            </div>

            <cfif VARIABLES.helpdeskShowTicketForm>
              <div class="helpdesk-panel-card p-4 mb-4">
                  <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                    <div>
                      <h5 class="mb-1"><cfif qHelpdeskTicketEdit.recordcount>Responder chamado<cfelse>Abrir novo chamado</cfif></h5>
                      <p class="text-muted small mb-0"><cfif qHelpdeskTicketEdit.recordcount>Registre tratativas internas e respostas para o solicitante.<cfelse>Cadastro manual de chamado feito diretamente pela equipe administrativa.</cfif></p>
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

                  <div class="helpdesk-thread-card p-3 mb-4">
                    <div class="helpdesk-thread">
                      <cfif qHelpdeskMensagens.recordcount>
                        <cfoutput query="qHelpdeskMensagens">
                          <div class="helpdesk-message <cfif IsBoolean(qHelpdeskMensagens.is_admin) ? qHelpdeskMensagens.is_admin : ListFindNoCase('true,1,yes,sim', trim(qHelpdeskMensagens.is_admin))>is-admin</cfif>">
                            <div class="helpdesk-message-header">
                              <div>
                                <div class="fw-semibold">#htmlEditFormat(qHelpdeskMensagens.nome_usuario)#</div>
                                <div class="small text-muted">#htmlEditFormat(qHelpdeskMensagens.email_usuario)#</div>
                              </div>
                              <div class="text-end small text-muted">
                                #LSDateFormat(qHelpdeskMensagens.created_at, "dd/mm/yyyy")# às #LSTimeFormat(qHelpdeskMensagens.created_at, "HH:mm")#
                              </div>
                            </div>
                            <div class="helpdesk-message-body">#htmlEditFormat(qHelpdeskMensagens.mensagem)#</div>
                          </div>
                        </cfoutput>
                      <cfelse>
                        <div class="helpdesk-empty-card">Ainda não há mensagens neste chamado.</div>
                      </cfif>
                    </div>
                  </div>

                  <cfoutput><form method="post" action="./?pagina=#VARIABLES.helpdeskPage#&ticket_id=#qHelpdeskTicketEdit.id_chamado#"></cfoutput>
                    <input type="hidden" name="helpdesk_action" value="responder_ticket"/>
                    <input type="hidden" name="ticket_id" value="<cfoutput>#qHelpdeskTicketEdit.id_chamado#</cfoutput>"/>

                    <div class="row helpdesk-form-grid">
                      <cfif VARIABLES.helpdeskIsAdmin>
                        <div class="col-12 col-lg-4">
                          <label class="form-label">Status</label>
                          <select class="form-select" name="ticket_status">
                            <cfloop list="aberto,em_atendimento,aguardando_cliente,resolvido,fechado" item="helpdeskStatusOption">
                              <cfoutput><option value="#helpdeskStatusOption#" <cfif qHelpdeskTicketEdit.status EQ helpdeskStatusOption>selected</cfif>>#helpdeskStatusOption#</option></cfoutput>
                            </cfloop>
                          </select>
                        </div>
                        <div class="col-12 col-lg-4">
                          <label class="form-label">Setor</label>
                          <select class="form-select" name="ticket_setor_id">
                            <cfoutput query="qHelpdeskSetores">
                              <option value="#qHelpdeskSetores.id_setor#" <cfif qHelpdeskTicketEdit.id_setor EQ qHelpdeskSetores.id_setor>selected</cfif>>#htmlEditFormat(qHelpdeskSetores.nome_setor)#</option>
                            </cfoutput>
                          </select>
                        </div>
                      </cfif>

                      <div class="col-12">
                        <label class="form-label">Nova mensagem</label>
                        <textarea class="form-control" name="ticket_mensagem" rows="5" placeholder="Descreva o andamento, a solução aplicada ou a sua nova dúvida."></textarea>
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

                    <div class="row helpdesk-form-grid">
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
                        <textarea class="form-control" name="ticket_mensagem" rows="6" placeholder="Explique o que aconteceu, o que você esperava e, se existir, envie o contexto necessário para a equipe atender mais rápido." required></textarea>
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
                <div class="helpdesk-panel-card p-3 h-100">
                  <div class="d-flex justify-content-between align-items-center gap-3 mb-3">
                    <h5 class="mb-0">Chamados recebidos</h5>
                    <span class="badge badge-secondary"><cfoutput>#LSNumberFormat(qHelpdeskChamados.recordcount)#</cfoutput></span>
                  </div>

                  <div class="helpdesk-board">
                    <cfif qHelpdeskChamados.recordcount>
                      <cfoutput query="qHelpdeskChamados">
                        <a class="helpdesk-ticket-card p-3 <cfif isDefined('URL.ticket_id') AND URL.ticket_id EQ qHelpdeskChamados.id_chamado>is-active</cfif>" href="./?pagina=#VARIABLES.helpdeskPage#&ticket_id=#qHelpdeskChamados.id_chamado#">
                          <div class="d-flex justify-content-between gap-3 mb-2">
                            <div>
                              <div class="fw-semibold">#htmlEditFormat(qHelpdeskChamados.assunto)#</div>
                              <div class="helpdesk-ticket-meta">#htmlEditFormat(qHelpdeskChamados.protocolo)#</div>
                            </div>
                            <span class="badge <cfif qHelpdeskChamados.status EQ 'resolvido' OR qHelpdeskChamados.status EQ 'fechado'>badge-success<cfelseif qHelpdeskChamados.status EQ 'em_atendimento'>badge-primary<cfelseif qHelpdeskChamados.status EQ 'aguardando_cliente'>badge-info<cfelse>badge-warning</cfif>">#htmlEditFormat(qHelpdeskChamados.status)#</span>
                          </div>
                          <div class="helpdesk-ticket-meta mb-1">Setor: #htmlEditFormat(qHelpdeskChamados.nome_setor)#</div>
                          <div class="helpdesk-ticket-meta mb-1">Usuário: #htmlEditFormat(qHelpdeskChamados.nome_usuario)#</div>
                          <div class="helpdesk-ticket-meta">Atualizado em #LSDateFormat(qHelpdeskChamados.updated_at, "dd/mm/yyyy")# às #LSTimeFormat(qHelpdeskChamados.updated_at, "HH:mm")#</div>
                        </a>
                      </cfoutput>
                    <cfelse>
                      <div class="helpdesk-empty-card">Nenhum chamado encontrado.</div>
                    </cfif>
                  </div>
                </div>
              </div>

              <div class="col-12 col-xl-7">
                <div class="helpdesk-panel-card p-4 h-100">
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
                    <div class="helpdesk-empty-card h-100 d-flex flex-column justify-content-center">
                      <div class="mb-2 fw-semibold">Selecione um chamado</div>
                      <div>Abra um ticket novo ou clique em um ticket existente para ver a conversa e responder.</div>
                    </div>
                  </cfif>
                </div>
              </div>
            </div>

            <cfif VARIABLES.helpdeskIsAdmin>
              <hr class="my-4"/>

              <div class="helpdesk-section-title mb-3">
                <div>
                  <h5 class="mb-1">Setores de atendimento</h5>
                  <p class="text-muted small mb-0">Defina a fila de atendimento e o responsável principal de cada setor.</p>
                </div>
                <cfoutput><a class="btn btn-outline-warning" href="./?pagina=#VARIABLES.helpdeskPage#&setor_novo=1">Novo setor</a></cfoutput>
              </div>

              <cfif VARIABLES.helpdeskShowSetorForm>
                <div class="helpdesk-setor-card p-4 mb-4">
                  <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                    <div>
                      <h5 class="mb-1"><cfif qHelpdeskSetorEdit.recordcount>Editar setor<cfelse>Novo setor</cfif></h5>
                      <p class="text-muted small mb-0">Escolha um usuário admin como responsável padrão por este setor.</p>
                    </div>
                    <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.helpdeskPage#">Fechar</a></cfoutput>
                  </div>

                  <cfoutput><form method="post" action="./?pagina=#VARIABLES.helpdeskPage#"></cfoutput>
                    <input type="hidden" name="helpdesk_action" value="salvar_setor"/>
                    <input type="hidden" name="setor_id" value="<cfif qHelpdeskSetorEdit.recordcount><cfoutput>#qHelpdeskSetorEdit.id_setor#</cfoutput></cfif>"/>

                    <div class="row helpdesk-form-grid">
                      <div class="col-12 col-lg-4">
                        <label class="form-label">Nome do setor</label>
                        <input class="form-control" type="text" name="setor_nome" value="<cfif qHelpdeskSetorEdit.recordcount><cfoutput>#htmlEditFormat(qHelpdeskSetorEdit.nome_setor)#</cfoutput></cfif>" maxlength="120" required/>
                      </div>
                      <div class="col-12 col-lg-4">
                        <label class="form-label">Responsável</label>
                        <select class="form-select" name="setor_responsavel_id">
                          <option value="">Selecione um admin</option>
                          <cfoutput query="qHelpdeskAdmins">
                            <option value="#qHelpdeskAdmins.id#" <cfif qHelpdeskSetorEdit.recordcount AND qHelpdeskSetorEdit.id_usuario_responsavel EQ qHelpdeskAdmins.id>selected</cfif>>#htmlEditFormat(qHelpdeskAdmins.name)#</option>
                          </cfoutput>
                        </select>
                      </div>
                      <div class="col-12 col-lg-4">
                        <label class="form-label">Status</label>
                        <select class="form-select" name="setor_ativo">
                          <option value="true" <cfif NOT qHelpdeskSetorEdit.recordcount OR qHelpdeskSetorEdit.ativo>selected</cfif>>Ativo</option>
                          <option value="false" <cfif qHelpdeskSetorEdit.recordcount AND NOT qHelpdeskSetorEdit.ativo>selected</cfif>>Inativo</option>
                        </select>
                      </div>
                      <div class="col-12">
                        <label class="form-label">Descrição</label>
                        <textarea class="form-control" name="setor_descricao" rows="3"><cfif qHelpdeskSetorEdit.recordcount><cfoutput>#htmlEditFormat(qHelpdeskSetorEdit.descricao_setor)#</cfoutput></cfif></textarea>
                      </div>
                    </div>

                    <div class="d-flex flex-wrap gap-2 mt-3">
                      <button type="submit" class="btn btn-warning">Salvar setor</button>
                      <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.helpdeskPage#">Cancelar</a></cfoutput>
                    </div>
                  </form>
                </div>
              </cfif>

              <div class="table-responsive">
                <table class="table table-sm table-striped table-hover">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Setor</th>
                      <th>Responsável</th>
                      <th>Status</th>
                      <th>Ações</th>
                    </tr>
                  </thead>
                  <tbody>
                    <cfif qHelpdeskSetores.recordcount>
                      <cfoutput query="qHelpdeskSetores">
                        <tr>
                          <td>#qHelpdeskSetores.id_setor#</td>
                          <td>
                            <div class="fw-semibold">#htmlEditFormat(qHelpdeskSetores.nome_setor)#</div>
                            <div class="small text-muted">#htmlEditFormat(qHelpdeskSetores.descricao_setor)#</div>
                          </td>
                          <td>#len(trim(qHelpdeskSetores.nome_responsavel)) ? htmlEditFormat(qHelpdeskSetores.nome_responsavel) : "-"#</td>
                          <td><span class="badge <cfif qHelpdeskSetores.ativo>badge-success<cfelse>badge-danger</cfif>"><cfif qHelpdeskSetores.ativo>Ativo<cfelse>Inativo</cfif></span></td>
                          <td>
                            <div class="d-flex flex-wrap gap-2">
                              <a class="btn btn-sm btn-outline-warning" href="./?pagina=#VARIABLES.helpdeskPage#&setor_id=#qHelpdeskSetores.id_setor#">Editar</a>
                              <a class="btn btn-sm btn-outline-<cfif qHelpdeskSetores.ativo>secondary<cfelse>success</cfif>" href="./?pagina=#VARIABLES.helpdeskPage#&setor_acao=status&setor_status=<cfif qHelpdeskSetores.ativo>false<cfelse>true</cfif>&setor_id=#qHelpdeskSetores.id_setor#">#qHelpdeskSetores.ativo ? "Desativar" : "Ativar"#</a>
                            </div>
                          </td>
                        </tr>
                      </cfoutput>
                    <cfelse>
                      <tr>
                        <td colspan="5" class="text-center text-muted py-4">Nenhum setor cadastrado.</td>
                      </tr>
                    </cfif>
                  </tbody>
                </table>
              </div>
            </cfif>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
