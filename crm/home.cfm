<cfprocessingdirective pageencoding="utf-8"/>

<!--- BACKEND --->

<cfinclude template="includes/backend.cfm"/>

<cfset VARIABLES.crmInImportPreview = qCrmUploadPreview.recordcount GT 0/>
<cfscript>
  VARIABLES.crmMapLabels = {
    "nome" = "Nome",
    "email" = "Email",
    "documento" = "Documento",
    "tipo_documento" = "Tipo de documento",
    "data_nascimento" = "Nascimento",
    "sexo" = "Sexo",
    "telefone" = "Telefone",
    "cidade" = "Cidade",
    "estado" = "UF",
    "pais" = "País",
    "numero_inscricao" = "Inscrição",
    "numero_pedido" = "Pedido",
    "protocolo" = "Protocolo",
    "numero_peito" = "Número de peito",
    "percurso" = "Distância",
    "modalidade" = "Modalidade",
    "categoria" = "Categoria",
    "status" = "Status",
    "origem" = "Origem",
    "campanha" = "Campanha",
    "cupom" = "Cupom",
    "camiseta" = "Camiseta",
    "assessoria" = "Assessoria",
    "data_pedido" = "Data do pedido",
    "data_pagamento" = "Data de pagamento",
    "valor" = "Valor"
  };
</cfscript>

<!--- CONTEUDO --->

<style>
  .crm-action-strip {
    display: flex;
    flex-wrap: wrap;
    gap: .75rem;
    margin-bottom: 1.5rem;
  }

  .crm-action-drawer {
    border: 1px solid rgba(255, 255, 255, .14);
    border-radius: .375rem;
    background: rgba(255, 255, 255, .025);
  }

  .crm-action-drawer > summary {
    align-items: center;
    cursor: pointer;
    display: flex;
    gap: .65rem;
    justify-content: space-between;
    list-style: none;
    min-height: 38px;
    padding: .55rem .8rem;
    user-select: none;
    white-space: nowrap;
  }

  .crm-action-drawer > summary::-webkit-details-marker {
    display: none;
  }

  .crm-action-drawer > summary::after {
    content: "+";
    font-weight: 700;
    opacity: .75;
  }

  .crm-action-drawer[open] {
    flex-basis: 100%;
  }

  .crm-action-drawer[open] > summary {
    border-bottom: 1px solid rgba(255, 255, 255, .12);
  }

  .crm-action-drawer[open] > summary::after {
    content: "-";
  }

  .crm-action-body {
    padding: 1rem;
  }

  .crm-import-preview {
    border-top: 1px solid rgba(255, 255, 255, .12);
    padding-top: 1rem;
  }

  .crm-map-summary {
    display: flex;
    flex-wrap: wrap;
    gap: .4rem;
  }

  .crm-map-chip {
    background: rgba(255, 179, 0, .12);
    border: 1px solid rgba(255, 179, 0, .25);
    border-radius: .25rem;
    color: #ffd27a;
    display: inline-flex;
    font-size: .75rem;
    line-height: 1.2;
    padding: .25rem .45rem;
  }

  .crm-import-focus {
    border: 1px solid rgba(255, 255, 255, .12);
    border-radius: .375rem;
    padding: 1rem;
  }

  .crm-map-editor {
    display: grid;
    gap: .75rem;
    grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
  }
</style>

<cfif NOT VARIABLES.crmInImportPreview>
<section class="mb-4">
  <div class="row gx-xl-3">
    <div class="col-12 col-md-6 col-xl-3 mb-3">
      <div class="card shadow-0 h-100">
        <div class="card-body p-3">
          <p class="text-muted mb-1">Participações</p>
          <h4 class="mb-0"><cfoutput>#LSNumberFormat(qCrmStats.total_participacoes, "9,999,999")#</cfoutput></h4>
        </div>
      </div>
    </div>
    <div class="col-12 col-md-6 col-xl-3 mb-3">
      <div class="card shadow-0 h-100">
        <div class="card-body p-3">
          <p class="text-muted mb-1">Leads únicos</p>
          <h4 class="mb-0"><cfoutput>#LSNumberFormat(qCrmStats.total_leads, "9,999,999")#</cfoutput></h4>
        </div>
      </div>
    </div>
    <div class="col-12 col-md-6 col-xl-3 mb-3">
      <div class="card shadow-0 h-100">
        <div class="card-body p-3">
          <p class="text-muted mb-1">Pagos</p>
          <h4 class="mb-0"><cfoutput>#LSNumberFormat(qCrmStats.total_pagos, "9,999,999")#</cfoutput></h4>
        </div>
      </div>
    </div>
    <div class="col-12 col-md-6 col-xl-3 mb-3">
      <div class="card shadow-0 h-100">
        <div class="card-body p-3">
          <p class="text-muted mb-1">Vinculados ao RR</p>
          <h4 class="mb-0"><cfoutput>#LSNumberFormat(qCrmStats.total_vinculados, "9,999,999")#</cfoutput></h4>
        </div>
      </div>
    </div>
  </div>
</section>
</cfif>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
            <div>
              <h3 class="mb-1">CRM de inscritos</h3>
              <p class="text-muted mb-0">Leads importados de APIs e arquivos de organizadores, agrupados por versões do mesmo evento.</p>
            </div>
            <div class="text-lg-end">
              <cfif VARIABLES.crmTablesReady AND VARIABLES.crmEffectiveIsAdmin AND NOT VARIABLES.crmInImportPreview>
                <form method="post" action="./" class="d-flex flex-column flex-sm-row gap-2 justify-content-lg-end">
                  <input type="hidden" name="acao" value="sync_ticketsports"/>
                  <input type="hidden" name="cod_evento" value="<cfoutput>#htmlEditFormat(VARIABLES.crmCodEvento)#</cfoutput>"/>
                  <button class="btn btn-sm btn-outline-warning" type="submit">
                    Sincronizar TicketSports<cfoutput><cfif len(VARIABLES.crmCodEvento)> #htmlEditFormat(VARIABLES.crmCodEvento)#</cfif></cfoutput>
                  </button>
                </form>
              <cfelse>
                <span class="badge badge-primary">Importador CRM</span>
              </cfif>
            </div>
          </div>

          <cfif NOT VARIABLES.crmTablesReady>
            <div class="alert alert-warning mb-4">
              A estrutura do CRM de inscritos ainda não foi criada no schema <code>crm</code>. Execute a migration
              <code>_codex/sql/2026-06-21_tb_crm_importador_leads.sql</code> e depois carregue as importações/API para habilitar os filtros.
            </div>
          </cfif>

          <cfif qCrmSyncTicketsports.recordcount>
            <cfoutput query="qCrmSyncTicketsports">
              <div class="alert alert-success mb-4">
                TicketSports sincronizado: #LSNumberFormat(qCrmSyncTicketsports.total_participacoes, "9,999,999")# participações,
                #LSNumberFormat(qCrmSyncTicketsports.total_pessoas, "9,999,999")# leads,
                #LSNumberFormat(qCrmSyncTicketsports.total_pedidos, "9,999,999")# pedidos.
              </div>
            </cfoutput>
          </cfif>

          <cfif len(trim(VARIABLES.crmNotice))>
            <div class="alert alert-success mb-4"><cfoutput>#htmlEditFormat(VARIABLES.crmNotice)#</cfoutput></div>
          </cfif>

          <cfif len(trim(VARIABLES.crmError))>
            <div class="alert alert-danger mb-4"><cfoutput>#htmlEditFormat(VARIABLES.crmError)#</cfoutput></div>
          </cfif>

          <cfif qCrmLinkTicketsports.recordcount>
            <cfoutput query="qCrmLinkTicketsports">
              <div class="alert alert-success mb-4">
                Evento #htmlEditFormat(qCrmLinkTicketsports.evento_codigo_externo)# vinculado à conta #htmlEditFormat(qCrmLinkTicketsports.conta_nome)#.
              </div>
            </cfoutput>
          </cfif>

          <cfif qCrmLinkFonteEvento.recordcount>
            <cfoutput query="qCrmLinkFonteEvento">
              <div class="alert alert-success mb-4">
                Fonte #htmlEditFormat(qCrmLinkFonteEvento.fonte)#<cfif len(trim(qCrmLinkFonteEvento.evento_codigo_externo))> / #htmlEditFormat(qCrmLinkFonteEvento.evento_codigo_externo)#</cfif>
                vinculada ao evento RR #qCrmLinkFonteEvento.evento_rr_id# - #htmlEditFormat(qCrmLinkFonteEvento.evento_rr_nome)#.
                #LSNumberFormat(qCrmLinkFonteEvento.total_resultados_vinculados, "9,999,999")# resultados e
                #LSNumberFormat(qCrmLinkFonteEvento.total_usuarios_vinculados, "9,999,999")# usuários RR vinculados.
              </div>
            </cfoutput>
          </cfif>

          <cfif qCrmUploadProcess.recordcount>
            <cfoutput query="qCrmUploadProcess">
              <div class="alert alert-success mb-4">
                Arquivo processado: #LSNumberFormat(qCrmUploadProcess.linhas_validas, "9,999,999")# linhas válidas,
                #LSNumberFormat(qCrmUploadProcess.linhas_invalidas, "9,999,999")# inválidas,
                #LSNumberFormat(qCrmUploadProcess.participacoes_upsert, "9,999,999")# participações geradas.
              </div>
            </cfoutput>
          </cfif>

          <cfif qCrmMatchResultados.recordcount>
            <cfoutput query="qCrmMatchResultados">
              <div class="alert alert-success mb-4">
                Resultados processados: #LSNumberFormat(qCrmMatchResultados.participacoes_vinculadas, "9,999,999")# participações com resultado,
                #LSNumberFormat(qCrmMatchResultados.pessoas_vinculadas, "9,999,999")# usuários RR vinculados por resultado.
              </div>
            </cfoutput>
          </cfif>

          <cfif qCrmMatchUsuarios.recordcount>
            <cfoutput query="qCrmMatchUsuarios">
              <div class="alert alert-success mb-4">
                Vínculos RR processados: #LSNumberFormat(qCrmMatchUsuarios.pessoas_vinculadas, "9,999,999")# vinculados,
                #LSNumberFormat(qCrmMatchUsuarios.pessoas_pendentes, "9,999,999")# pendentes.
              </div>
            </cfoutput>
          </cfif>

          <cfif VARIABLES.crmTablesReady AND VARIABLES.crmCanOperate>
            <cfif qCrmFontesPendentes.recordcount AND NOT VARIABLES.crmInImportPreview>
              <div class="border rounded p-3 mb-4">
                <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 mb-3">
                  <div>
                    <h5 class="mb-1">Fontes sem evento RR</h5>
                    <p class="text-muted mb-0">Escolha o evento Road Runners para liberar resultados, usuários vinculados e score correto.</p>
                  </div>
                </div>
                <div class="table-responsive">
                  <table class="table table-sm table-hover align-middle mb-0">
                    <thead>
                      <tr>
                        <th>Fonte</th>
                        <th>Código</th>
                        <th>Evento importado</th>
                        <th class="text-end">Participações</th>
                        <th style="min-width: 280px;">Vincular</th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qCrmFontesPendentes">
                        <tr>
                          <td><span class="badge badge-primary">#htmlEditFormat(qCrmFontesPendentes.fonte)#</span></td>
                          <td>#htmlEditFormat(qCrmFontesPendentes.cod_evento_externo)#</td>
                          <td>
                            #htmlEditFormat(qCrmFontesPendentes.ano_evento)#<br/>
                            <small class="text-muted">#htmlEditFormat(crmShortText(qCrmFontesPendentes.nome_evento, 58))#</small>
                          </td>
                          <td class="text-end">#LSNumberFormat(qCrmFontesPendentes.total, "9,999,999")#</td>
	                          <td>
	                            <form method="post" action="./" class="d-flex gap-2">
	                              <cfif qCrmFontesPendentes.fonte EQ "ticketsports">
	                                <input type="hidden" name="acao" value="link_ticketsports_evento"/>
                              <cfelse>
                                <input type="hidden" name="acao" value="link_fonte_evento"/>
                                <input type="hidden" name="fonte" value="#htmlEditFormat(qCrmFontesPendentes.fonte)#"/>
	                              </cfif>
	                              <input type="hidden" name="cod_evento" value="#htmlEditFormat(qCrmFontesPendentes.cod_evento_externo)#"/>
	                              <cfif qCrmEventosConta.recordcount>
	                                <select class="form-select form-select-sm" name="id_evento" required>
	                                  <option value="">Evento da conta</option>
	                                  <cfloop query="qCrmEventosConta">
	                                    <option value="#qCrmEventosConta.id_evento#">
	                                      #qCrmEventosConta.ano_evento# · #htmlEditFormat(crmShortText(qCrmEventosConta.nome_evento, 42))#
	                                    </option>
	                                  </cfloop>
	                                </select>
	                              <cfelseif VARIABLES.crmEffectiveIsAdmin>
	                                <input class="form-control form-control-sm" type="text" name="id_evento" placeholder="ID evento RR" required/>
	                              <cfelse>
	                                <select class="form-select form-select-sm" name="id_evento" disabled>
	                                  <option value="">Nenhum evento vinculado</option>
	                                </select>
	                              </cfif>
	                              <button class="btn btn-sm btn-warning" type="submit" <cfif NOT qCrmEventosConta.recordcount AND NOT VARIABLES.crmEffectiveIsAdmin>disabled</cfif>>Vincular</button>
	                            </form>
	                          </td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              </div>
            </cfif>

            <cfif VARIABLES.crmInImportPreview>
              <div class="crm-import-focus mb-4">
                <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-4">
                  <div>
                    <h4 class="mb-1">Conferir mapeamento</h4>
                    <p class="text-muted mb-0"><cfoutput>#numberFormat(VARIABLES.crmPreviewTotalLinhas)#</cfoutput> linhas lidas. Ajuste os campos se a prévia não estiver correta.</p>
                  </div>
                  <div class="d-flex flex-column flex-sm-row gap-2">
                    <a class="btn btn-outline-secondary" href="./">Enviar outro arquivo</a>
                    <form method="post" action="./" class="mb-0">
                      <input type="hidden" name="acao" value="confirmar_importacao_arquivo"/>
                      <input type="hidden" name="id_crm_importacao" value="<cfoutput>#htmlEditFormat(VARIABLES.crmPreviewImportacao)#</cfoutput>"/>
                      <button class="btn btn-success" type="submit">Confirmar e processar</button>
                    </form>
                  </div>
                </div>

                <form method="post" action="./" class="mb-4">
                  <input type="hidden" name="acao" value="remap_importacao_arquivo"/>
                  <input type="hidden" name="id_crm_importacao" value="<cfoutput>#htmlEditFormat(VARIABLES.crmPreviewImportacao)#</cfoutput>"/>
                  <div class="crm-map-editor">
                    <cfloop list="#VARIABLES.crmUploadManualFields#" index="crmMapField">
                      <cfset VARIABLES.crmMapSelected = ""/>
                      <cfloop query="qCrmUploadMapeamento">
                        <cfif qCrmUploadMapeamento.campo EQ crmMapField>
                          <cfset VARIABLES.crmMapSelected = qCrmUploadMapeamento.cabecalho/>
                        </cfif>
                      </cfloop>
                      <cfset VARIABLES.crmMapFieldLabel = replace(crmMapField, "_", " ", "all")/>
                      <cfif structKeyExists(VARIABLES.crmMapLabels, crmMapField)>
                        <cfset VARIABLES.crmMapFieldLabel = VARIABLES.crmMapLabels[crmMapField]/>
                      </cfif>
                      <div>
                        <cfoutput>
                          <label class="form-label" for="crmPreviewMap_#crmMapField#">#htmlEditFormat(VARIABLES.crmMapFieldLabel)#</label>
                          <select id="crmPreviewMap_#crmMapField#" class="form-select form-select-sm" name="map_#crmMapField#">
                            <option value="">Não importar</option>
                        </cfoutput>
                          <cfoutput query="qCrmUploadColunas">
                            <option value="#htmlEditFormat(qCrmUploadColunas.cabecalho)#" <cfif VARIABLES.crmMapSelected EQ qCrmUploadColunas.cabecalho>selected</cfif>>
                              #qCrmUploadColunas.ordem# · #htmlEditFormat(crmShortText(qCrmUploadColunas.cabecalho, 34))#
                            </option>
                          </cfoutput>
                        </select>
                      </div>
                    </cfloop>
                  </div>
                  <div class="d-flex justify-content-end mt-3">
                    <button class="btn btn-outline-warning" type="submit">Atualizar mapeamento</button>
                  </div>
                </form>

                <div class="table-responsive">
                  <table class="table table-sm table-dark align-middle mb-0">
                    <thead>
                      <tr>
                        <th>Linha</th>
                        <th>Nome</th>
                        <th>Email</th>
                        <th>Documento</th>
                        <th>Sexo</th>
                        <th>Local</th>
                        <th>Inscrição</th>
                        <th>Pedido</th>
                        <th>Dist.</th>
                        <th>Status</th>
                        <th>Validação</th>
                        <th>Avisos</th>
                      </tr>
                    </thead>
                    <tbody>
                      <cfoutput query="qCrmUploadPreview">
                        <tr>
                          <td>#qCrmUploadPreview.numero_linha#</td>
                          <td>#htmlEditFormat(qCrmUploadPreview.nome_atleta)#</td>
                          <td>#htmlEditFormat(qCrmUploadPreview.email)#</td>
                          <td>#htmlEditFormat(qCrmUploadPreview.documento)#</td>
                          <td>#htmlEditFormat(qCrmUploadPreview.sexo)#</td>
                          <td>#htmlEditFormat(trim(qCrmUploadPreview.cidade & " / " & qCrmUploadPreview.estado))#</td>
                          <td>#htmlEditFormat(qCrmUploadPreview.numero_inscricao)#</td>
                          <td>#htmlEditFormat(qCrmUploadPreview.numero_pedido)#</td>
                          <td><cfif len(qCrmUploadPreview.percurso)>#numberFormat(qCrmUploadPreview.percurso, "0.##")#K<cfelse>-</cfif></td>
                          <td>#htmlEditFormat(qCrmUploadPreview.status_inscricao)#</td>
                          <td>
                            <span class="badge <cfif qCrmUploadPreview.status_validacao EQ 'valido'>badge-success<cfelse>badge-warning</cfif>">
                              #htmlEditFormat(qCrmUploadPreview.status_validacao)#
                            </span>
                          </td>
                          <td>
                            <cfif len(trim(qCrmUploadPreview.avisos))>
                              <span class="badge badge-warning">#htmlEditFormat(qCrmUploadPreview.avisos)#</span>
                            <cfelse>
                              <span class="text-muted">-</span>
                            </cfif>
                          </td>
                        </tr>
                      </cfoutput>
                    </tbody>
                  </table>
                </div>
              </div>
            <cfelse>
            <div class="crm-action-strip">
              <details class="crm-action-drawer" <cfif isDefined("FORM.acao") AND listFindNoCase("preview_arquivo,upload_arquivo,confirmar_importacao_arquivo", FORM.acao)>open</cfif>>
                <summary>
                  <strong>Importar arquivo</strong>
                  <span class="badge badge-warning">Excel/CSV</span>
                </summary>
                <div class="crm-action-body">
            <form method="post" action="./" enctype="multipart/form-data" class="mb-0">
              <input type="hidden" name="acao" value="preview_arquivo"/>
              <div class="row g-3 align-items-end">
                <div class="col-12 col-md-4 col-lg-2">
                  <label class="form-label" for="crmUploadIdEvento">Evento RR</label>
                  <cfif qCrmEventosConta.recordcount>
                    <select id="crmUploadIdEvento" class="form-select" name="id_evento" required>
                      <option value="">Selecione</option>
                      <cfoutput query="qCrmEventosConta">
                        <option value="#qCrmEventosConta.id_evento#" <cfif VARIABLES.crmIdEventoFiltro EQ qCrmEventosConta.id_evento>selected</cfif>>
                          #qCrmEventosConta.ano_evento# · #htmlEditFormat(crmShortText(qCrmEventosConta.nome_evento, 48))#
                          <cfif len(trim(qCrmEventosConta.cidade))> · #htmlEditFormat(qCrmEventosConta.cidade)#<cfif len(trim(qCrmEventosConta.estado))>/#htmlEditFormat(qCrmEventosConta.estado)#</cfif></cfif>
                          <cfif VARIABLES.crmEffectiveIsAdmin AND len(trim(qCrmEventosConta.contas))> · #htmlEditFormat(crmShortText(qCrmEventosConta.contas, 32))#</cfif>
                        </option>
                      </cfoutput>
                    </select>
                  <cfelseif VARIABLES.crmEffectiveIsAdmin>
                    <input id="crmUploadIdEvento" class="form-control" type="text" name="id_evento" value="<cfoutput>#htmlEditFormat(VARIABLES.crmIdEventoFiltro)#</cfoutput>" placeholder="Ex.: 40782" required/>
                  <cfelse>
                    <select id="crmUploadIdEvento" class="form-select" name="id_evento" disabled>
                      <option value="">Nenhum evento vinculado à conta</option>
                    </select>
                  </cfif>
                </div>
                <div class="col-12 col-md-4 col-lg-2">
                  <label class="form-label" for="crmUploadFonte">Fonte</label>
                  <input id="crmUploadFonte" class="form-control" type="text" name="fonte" value="excel" placeholder="excel, csv, foco"/>
                </div>
                <div class="col-12 col-md-4 col-lg-2">
                  <label class="form-label" for="crmUploadCodEvento">Código externo</label>
                  <input id="crmUploadCodEvento" class="form-control" type="text" name="cod_evento" placeholder="Opcional"/>
                </div>
                <div class="col-12 col-md-4 col-lg-2">
                  <label class="form-label" for="crmUploadParceiro">ID parceiro</label>
                  <input id="crmUploadParceiro" class="form-control" type="text" name="id_parceiro" placeholder="Opcional"/>
                </div>
                <div class="col-12 col-md-4 col-lg-2">
                  <label class="form-label" for="crmUploadHeaderRow">Cabeçalho</label>
                  <input id="crmUploadHeaderRow" class="form-control" type="number" min="0" name="header_row" value="1"/>
                </div>
                <div class="col-12 col-md-4 col-lg-2">
                  <label class="form-label" for="crmUploadLayout">Layout</label>
                  <select id="crmUploadLayout" class="form-select" name="layout_importacao">
                    <option value="auto">Auto</option>
                    <option value="mif2017_sem_cabecalho">MIF 2017 sem cabeçalho</option>
                  </select>
                </div>
                <div class="col-12 col-lg-6">
                  <label class="form-label" for="crmUploadNome">Nome da importação</label>
                  <input id="crmUploadNome" class="form-control" type="text" name="nome_importacao" placeholder="Ex.: MIF 2019 inscritos"/>
                </div>
                <div class="col-12 col-lg-4">
                  <label class="form-label" for="crmUploadArquivo">Arquivo</label>
                  <input id="crmUploadArquivo" class="form-control" type="file" name="arquivo_crm" accept=".xlsx,.xls,.csv" required/>
                </div>
                <div class="col-12 col-lg-2 text-lg-end">
                  <button class="btn btn-warning w-100" type="submit" <cfif NOT qCrmEventosConta.recordcount AND NOT VARIABLES.crmEffectiveIsAdmin>disabled</cfif>>Pré-visualizar</button>
                </div>
                <div class="col-12">
                  <details>
                    <summary class="text-muted">Mapeamento manual</summary>
                    <div class="row g-2 mt-2">
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapNome">Nome</label>
                        <input id="crmMapNome" class="form-control form-control-sm" type="text" name="map_nome" placeholder="A ou Nome"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapEmail">Email</label>
                        <input id="crmMapEmail" class="form-control form-control-sm" type="text" name="map_email" placeholder="B ou Email"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapDocumento">CPF/Doc</label>
                        <input id="crmMapDocumento" class="form-control form-control-sm" type="text" name="map_documento" placeholder="C ou CPF"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapNascimento">Nascimento</label>
                        <input id="crmMapNascimento" class="form-control form-control-sm" type="text" name="map_data_nascimento" placeholder="D ou DN"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapTelefone">Telefone</label>
                        <input id="crmMapTelefone" class="form-control form-control-sm" type="text" name="map_telefone" placeholder="E ou Celular"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapSexo">Sexo</label>
                        <input id="crmMapSexo" class="form-control form-control-sm" type="text" name="map_sexo" placeholder="F ou Sexo"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapCidade">Cidade</label>
                        <input id="crmMapCidade" class="form-control form-control-sm" type="text" name="map_cidade" placeholder="G ou Cidade"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapEstado">UF</label>
                        <input id="crmMapEstado" class="form-control form-control-sm" type="text" name="map_estado" placeholder="H ou UF"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapInscricao">Inscrição</label>
                        <input id="crmMapInscricao" class="form-control form-control-sm" type="text" name="map_numero_inscricao" placeholder="I ou Número"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapPedido">Pedido</label>
                        <input id="crmMapPedido" class="form-control form-control-sm" type="text" name="map_numero_pedido" placeholder="J ou Pedido"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapModalidade">Modalidade</label>
                        <input id="crmMapModalidade" class="form-control form-control-sm" type="text" name="map_modalidade" placeholder="K ou Produto"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapPercurso">Percurso</label>
                        <input id="crmMapPercurso" class="form-control form-control-sm" type="text" name="map_percurso" placeholder="L ou Distância"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapStatus">Status</label>
                        <input id="crmMapStatus" class="form-control form-control-sm" type="text" name="map_status" placeholder="M ou Status"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapPagamento">Pagamento</label>
                        <input id="crmMapPagamento" class="form-control form-control-sm" type="text" name="map_data_pagamento" placeholder="N ou Pagamento"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapValor">Valor</label>
                        <input id="crmMapValor" class="form-control form-control-sm" type="text" name="map_valor" placeholder="O ou Valor"/>
                      </div>
                      <div class="col-6 col-md-3 col-xl-2">
                        <label class="form-label" for="crmMapAssessoria">Assessoria</label>
                        <input id="crmMapAssessoria" class="form-control form-control-sm" type="text" name="map_assessoria" placeholder="P ou Equipe"/>
                      </div>
                    </div>
                  </details>
                </div>
              </div>
            </form>
                </div>
              </details>

              <details class="crm-action-drawer" <cfif isDefined("FORM.acao") AND FORM.acao EQ "link_ticketsports_evento">open</cfif>>
                <summary>
                  <strong>Vincular TicketSports</strong>
                  <span class="badge badge-primary">API</span>
                </summary>
                <div class="crm-action-body">
            <form method="post" action="./" class="mb-0">
              <input type="hidden" name="acao" value="link_ticketsports_evento"/>
              <div class="row g-3 align-items-end">
                <div class="col-12 col-md-4 col-lg-3">
                  <label class="form-label" for="crmLinkTicketSportsCodEvento">Código TicketSports</label>
                  <input id="crmLinkTicketSportsCodEvento" class="form-control" type="text" name="cod_evento" value="<cfoutput>#htmlEditFormat(VARIABLES.crmCodEvento)#</cfoutput>" placeholder="Ex.: 72611" required/>
                </div>
                <div class="col-12 col-md-4 col-lg-3">
                  <label class="form-label" for="crmLinkTicketSportsIdEvento">Evento RR</label>
                  <cfif qCrmEventosConta.recordcount>
                    <select id="crmLinkTicketSportsIdEvento" class="form-select" name="id_evento" required>
                      <option value="">Selecione</option>
                      <cfoutput query="qCrmEventosConta">
                        <option value="#qCrmEventosConta.id_evento#" <cfif VARIABLES.crmIdEventoFiltro EQ qCrmEventosConta.id_evento>selected</cfif>>
                          #qCrmEventosConta.ano_evento# · #htmlEditFormat(crmShortText(qCrmEventosConta.nome_evento, 52))#
                        </option>
                      </cfoutput>
                    </select>
                  <cfelseif VARIABLES.crmEffectiveIsAdmin>
                    <input id="crmLinkTicketSportsIdEvento" class="form-control" type="text" name="id_evento" value="<cfoutput>#htmlEditFormat(VARIABLES.crmIdEventoFiltro)#</cfoutput>" placeholder="Ex.: 40782" required/>
                  <cfelse>
                    <select id="crmLinkTicketSportsIdEvento" class="form-select" name="id_evento" disabled>
                      <option value="">Nenhum evento vinculado à conta</option>
                    </select>
                  </cfif>
                </div>
                <div class="col-12 col-md-4 col-lg-3 text-lg-end">
                  <button class="btn btn-outline-primary w-100" type="submit" <cfif NOT qCrmEventosConta.recordcount AND NOT VARIABLES.crmEffectiveIsAdmin>disabled</cfif>>Vincular TicketSports</button>
                </div>
              </div>
            </form>
                </div>
              </details>

              <details class="crm-action-drawer" <cfif isDefined("FORM.acao") AND FORM.acao EQ "link_fonte_evento">open</cfif>>
                <summary>
                  <strong>Vincular outra fonte</strong>
                  <span class="badge badge-secondary">Manual</span>
                </summary>
                <div class="crm-action-body">
            <form method="post" action="./" class="mb-0">
              <input type="hidden" name="acao" value="link_fonte_evento"/>
              <div class="row g-3 align-items-end">
                <div class="col-12 col-md-3 col-lg-2">
                  <label class="form-label" for="crmLinkFonte">Fonte</label>
                  <input id="crmLinkFonte" class="form-control" type="text" name="fonte" value="excel" placeholder="csv, excel"/>
                </div>
                <div class="col-12 col-md-3 col-lg-2">
                  <label class="form-label" for="crmLinkEventoCodEvento">Código externo</label>
                  <input id="crmLinkEventoCodEvento" class="form-control" type="text" name="cod_evento" placeholder="Opcional"/>
                </div>
                <div class="col-12 col-md-3 col-lg-2">
                  <label class="form-label" for="crmLinkFonteParceiro">ID parceiro</label>
                  <input id="crmLinkFonteParceiro" class="form-control" type="text" name="id_parceiro" placeholder="Opcional"/>
                </div>
                <div class="col-12 col-md-3 col-lg-2">
                  <label class="form-label" for="crmLinkEventoIdEvento">Evento RR</label>
                  <cfif qCrmEventosConta.recordcount>
                    <select id="crmLinkEventoIdEvento" class="form-select" name="id_evento" required>
                      <option value="">Selecione</option>
                      <cfoutput query="qCrmEventosConta">
                        <option value="#qCrmEventosConta.id_evento#" <cfif VARIABLES.crmIdEventoFiltro EQ qCrmEventosConta.id_evento>selected</cfif>>
                          #qCrmEventosConta.ano_evento# · #htmlEditFormat(crmShortText(qCrmEventosConta.nome_evento, 42))#
                        </option>
                      </cfoutput>
                    </select>
                  <cfelseif VARIABLES.crmEffectiveIsAdmin>
                    <input id="crmLinkEventoIdEvento" class="form-control" type="text" name="id_evento" value="<cfoutput>#htmlEditFormat(VARIABLES.crmIdEventoFiltro)#</cfoutput>" placeholder="Ex.: 40782" required/>
                  <cfelse>
                    <select id="crmLinkEventoIdEvento" class="form-select" name="id_evento" disabled>
                      <option value="">Nenhum evento vinculado à conta</option>
                    </select>
                  </cfif>
                </div>
                <div class="col-12 col-lg-1 text-lg-end">
                  <button class="btn btn-outline-secondary w-100" type="submit" <cfif NOT qCrmEventosConta.recordcount AND NOT VARIABLES.crmEffectiveIsAdmin>disabled</cfif>>Vincular</button>
                </div>
              </div>
            </form>
                </div>
              </details>
            </div>
            </cfif>

          </cfif>

          <cfif NOT VARIABLES.crmInImportPreview>
          <cfif VARIABLES.crmTablesReady AND VARIABLES.crmEffectiveIsAdmin AND qCrmContas.recordcount>
            <details class="crm-action-drawer mb-4" <cfif isDefined("FORM.acao") AND FORM.acao EQ "link_ticketsports_conta">open</cfif>>
              <summary>
                <strong>Avançado: vincular código à conta</strong>
                <span class="badge badge-warning">Admin</span>
              </summary>
              <div class="crm-action-body">
                <form method="post" action="./" class="mb-0">
                  <input type="hidden" name="acao" value="link_ticketsports_conta"/>
                  <div class="row g-3 align-items-end">
                    <div class="col-12 col-lg-6">
                      <label class="form-label" for="crmLinkConta">Conta</label>
                      <select id="crmLinkConta" class="form-select" name="id_conta" required>
                        <cfoutput query="qCrmContas">
                          <option value="#qCrmContas.id_conta#" <cfif VARIABLES.crmIdConta EQ qCrmContas.id_conta>selected</cfif>>
                            #htmlEditFormat(qCrmContas.nome_conta)#
                          </option>
                        </cfoutput>
                      </select>
                    </div>
                    <div class="col-12 col-md-5 col-lg-3">
                      <label class="form-label" for="crmLinkCodEvento">Código TicketSports</label>
                      <input id="crmLinkCodEvento" class="form-control" type="text" name="cod_evento" value="<cfoutput>#htmlEditFormat(VARIABLES.crmCodEvento)#</cfoutput>" placeholder="Ex.: 72611" required/>
                    </div>
                    <div class="col-12 col-md-7 col-lg-3 text-lg-end">
                      <button class="btn btn-outline-warning w-100" type="submit">Vincular à conta</button>
                    </div>
                  </div>
                </form>
              </div>
            </details>
          </cfif>

          <cfif VARIABLES.crmTablesReady AND VARIABLES.crmCanOperate>
            <form method="post" action="./" class="mb-4 text-end">
              <input type="hidden" name="acao" value="match_usuarios"/>
              <input type="hidden" name="id_conta" value="<cfoutput>#htmlEditFormat(VARIABLES.crmIdConta)#</cfoutput>"/>
              <button class="btn btn-sm btn-outline-primary" type="submit">Processar vínculo RR</button>
            </form>
          </cfif>

          <div class="row g-4 mb-4">
            <div class="col-12 col-xl-7">
              <h5>Eventos vinculados</h5>
              <div class="table-responsive">
                <table class="table table-sm table-hover">
                  <thead>
                    <tr>
                      <th>Evento RR</th>
                      <th>Evento</th>
                      <th>Fontes</th>
                      <th>Códigos</th>
                      <th class="text-end">Participações</th>
                    </tr>
                  </thead>
                  <tbody>
                    <cfif qCrmEventos.recordcount>
                      <cfoutput query="qCrmEventos">
                        <tr>
                          <td>#qCrmEventos.id_evento#</td>
                          <td>#htmlEditFormat(crmShortText(qCrmEventos.nome_evento, 54))#</td>
                          <td>#htmlEditFormat(qCrmEventos.fontes)#</td>
                          <td><cfif len(trim(qCrmEventos.codigos))>#htmlEditFormat(qCrmEventos.codigos)#<cfelse><span class="text-muted">-</span></cfif></td>
                          <td class="text-end">#LSNumberFormat(qCrmEventos.total, "9,999,999")#</td>
                        </tr>
                      </cfoutput>
                    <cfelse>
                      <tr><td colspan="5" class="text-muted">Nenhuma fonte foi vinculada a um evento RR ainda.</td></tr>
                    </cfif>
                  </tbody>
                </table>
              </div>
            </div>

            <div class="col-12 col-xl-5">
              <h5>Últimas importações</h5>
              <div class="table-responsive">
                <table class="table table-sm table-hover">
                  <thead>
                    <tr>
                      <th>Importação</th>
                      <th>Origem</th>
                      <th class="text-end">Linhas</th>
                    </tr>
                  </thead>
                  <tbody>
                    <cfif qCrmImportacoes.recordcount>
                      <cfoutput query="qCrmImportacoes">
                        <tr>
                          <td>
                            #htmlEditFormat(crmShortText(qCrmImportacoes.nome_importacao, 32))#<br/>
                            <small class="text-muted">#crmDateTimeLabel(qCrmImportacoes.data_criacao)#</small>
                          </td>
                          <td>
                            <span class="badge badge-secondary">#htmlEditFormat(qCrmImportacoes.origem_tipo)#</span>
                            <span class="badge badge-primary">#htmlEditFormat(qCrmImportacoes.fonte)#</span>
                          </td>
                          <td class="text-end">#LSNumberFormat(qCrmImportacoes.total_linhas, "9,999,999")#</td>
                        </tr>
                      </cfoutput>
                    <cfelse>
                      <tr><td colspan="3" class="text-muted">Nenhuma importação registrada.</td></tr>
                    </cfif>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <form method="get" action="./" class="mb-4">
            <div class="row g-3 align-items-end">
              <div class="col-12 col-xl-3">
                <label class="form-label" for="crmBusca">Busca</label>
                <input id="crmBusca" class="form-control" type="text" name="busca" placeholder="Nome, email, documento, pedido" value="<cfoutput>#htmlEditFormat(VARIABLES.crmBusca)#</cfoutput>"/>
              </div>

              <div class="col-12 col-md-6 col-xl-2">
                <label class="form-label" for="crmConta">Conta</label>
                <select id="crmConta" class="form-select" name="id_conta">
                  <option value="">Todas</option>
                  <cfoutput query="qCrmContas">
                    <option value="#qCrmContas.id_conta#" <cfif VARIABLES.crmIdConta EQ qCrmContas.id_conta>selected</cfif>>
                      #htmlEditFormat(qCrmContas.nome_conta)#
                    </option>
                  </cfoutput>
                </select>
              </div>

              <div class="col-12 col-md-6 col-xl-2">
                <label class="form-label" for="crmIdEvento">Evento RR</label>
                <select id="crmIdEvento" class="form-select" name="id_evento">
                  <option value="">Todos</option>
                  <cfoutput query="qCrmEventos">
                    <option value="#qCrmEventos.id_evento#" <cfif VARIABLES.crmIdEventoFiltro EQ qCrmEventos.id_evento>selected</cfif>>
                      #htmlEditFormat(qCrmEventos.ano_evento)# · ## #qCrmEventos.id_evento# · #htmlEditFormat(crmShortText(qCrmEventos.nome_evento, 42))#
                    </option>
                  </cfoutput>
                </select>
              </div>

              <div class="col-6 col-md-3 col-xl-1">
                <label class="form-label" for="crmAno">Ano</label>
                <select id="crmAno" class="form-select" name="ano_evento">
                  <option value="">Todos</option>
                  <cfoutput query="qCrmAnos">
                    <option value="#qCrmAnos.ano_evento#" <cfif VARIABLES.crmAnoEvento EQ qCrmAnos.ano_evento>selected</cfif>>#qCrmAnos.ano_evento#</option>
                  </cfoutput>
                </select>
              </div>

              <div class="col-6 col-md-3 col-xl-1">
                <label class="form-label" for="crmPercurso">Distância</label>
                <select id="crmPercurso" class="form-select" name="percurso">
                  <option value="">Todas</option>
                  <cfoutput query="qCrmPercursos">
                    <option value="#qCrmPercursos.percurso#" <cfif VARIABLES.crmPercurso EQ qCrmPercursos.percurso>selected</cfif>>#qCrmPercursos.percurso#K</option>
                  </cfoutput>
                </select>
              </div>

              <div class="col-12 col-md-6 col-xl-2">
                <label class="form-label" for="crmStatus">Status</label>
                <select id="crmStatus" class="form-select" name="status">
                  <option value="">Todos</option>
                  <cfoutput query="qCrmStatus">
                    <option value="#htmlEditFormat(qCrmStatus.status_pedido)#" <cfif VARIABLES.crmStatus EQ qCrmStatus.status_pedido>selected</cfif>>
                      #htmlEditFormat(qCrmStatus.status_pedido)#
                    </option>
                  </cfoutput>
                </select>
              </div>

              <div class="col-6 col-md-3 col-xl-1">
                <label class="form-label" for="crmUf">UF</label>
                <select id="crmUf" class="form-select" name="uf">
                  <option value="">Todas</option>
                  <cfoutput query="qCrmEstados">
                    <option value="#htmlEditFormat(qCrmEstados.estado)#" <cfif VARIABLES.crmUf EQ qCrmEstados.estado>selected</cfif>>#htmlEditFormat(qCrmEstados.estado)#</option>
                  </cfoutput>
                </select>
              </div>

              <div class="col-6 col-md-3 col-xl-1">
                <label class="form-label" for="crmCorreu">Correu</label>
                <select id="crmCorreu" class="form-select" name="correu">
                  <option value="">Todos</option>
                  <option value="sim" <cfif VARIABLES.crmCorreu EQ "sim">selected</cfif>>Sim</option>
                  <option value="nao" <cfif VARIABLES.crmCorreu EQ "nao">selected</cfif>>Não</option>
                </select>
              </div>

              <div class="col-12 col-md-6 col-xl-1">
                <label class="form-label" for="crmVinculo">RR</label>
                <select id="crmVinculo" class="form-select" name="vinculo">
                  <option value="">Todos</option>
                  <option value="com_usuario" <cfif VARIABLES.crmVinculo EQ "com_usuario">selected</cfif>>Com usuário</option>
                  <option value="sem_usuario" <cfif VARIABLES.crmVinculo EQ "sem_usuario">selected</cfif>>Sem usuário</option>
                </select>
              </div>

              <div class="col-12 col-xl-12 d-flex gap-2 justify-content-end">
                <a class="btn btn-outline-secondary" href="./">Limpar</a>
                <button class="btn btn-warning" type="submit">Filtrar</button>
              </div>
            </div>
          </form>

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-2 align-items-lg-center mb-3">
            <h5 class="mb-0">Participações</h5>
            <cfoutput>
              <span class="text-muted">
                #LSNumberFormat(qCrmTotalRows.total, "9,999,999")# registros · página #VARIABLES.crmPagina# de #VARIABLES.crmTotalPaginas#
              </span>
            </cfoutput>
          </div>

          <div class="table-responsive">
            <table class="table table-sm table-striped table-hover align-middle">
              <thead>
                <tr>
                  <th>Lead</th>
                  <th>Evento</th>
                  <th>Dist.</th>
                  <th>Status</th>
                  <th>Pedido</th>
                  <th>Local</th>
                  <th class="text-end">Score</th>
                  <th class="text-end">RR</th>
                  <th class="text-end">Correu</th>
                </tr>
              </thead>
              <tbody>
                <cfif qCrmParticipacoes.recordcount>
                  <cfoutput query="qCrmParticipacoes">
                    <tr>
                      <td>
                        <strong>#htmlEditFormat(crmShortText(qCrmParticipacoes.nome, 34))#</strong><br/>
                        <small class="text-muted">#htmlEditFormat(crmShortText(qCrmParticipacoes.email, 38))#</small>
                      </td>
                      <td>
                        <span>
                          #htmlEditFormat(qCrmParticipacoes.ano_evento)# ·
                          <cfif len(trim(qCrmParticipacoes.id_evento))>
                            RR ## #qCrmParticipacoes.id_evento#
                          <cfelse>
                            <span class="text-warning">sem evento RR</span>
                          </cfif>
                          <cfif len(trim(qCrmParticipacoes.cod_evento_externo))> · #htmlEditFormat(qCrmParticipacoes.cod_evento_externo)#</cfif>
                        </span><br/>
                        <small class="text-muted">#htmlEditFormat(crmShortText(qCrmParticipacoes.modalidade, 48))#</small>
                      </td>
                      <td><cfif len(trim(qCrmParticipacoes.percurso))>#qCrmParticipacoes.percurso#K</cfif></td>
                      <td>
                        <cfif qCrmParticipacoes.status_pedido EQ "Pago">
                          <span class="badge badge-success">Pago</span>
                        <cfelseif len(trim(qCrmParticipacoes.status_pedido))>
                          <span class="badge badge-warning">#htmlEditFormat(qCrmParticipacoes.status_pedido)#</span>
                        <cfelse>
                          <span class="badge badge-secondary">Sem status</span>
                        </cfif>
                      </td>
                      <td>
                        <span>#htmlEditFormat(qCrmParticipacoes.numero_pedido)#</span><br/>
                        <small class="text-muted">#crmDateTimeLabel(qCrmParticipacoes.data_pedido)#</small>
                      </td>
                      <td>
                        #htmlEditFormat(crmShortText(qCrmParticipacoes.cidade, 24))#
                        <cfif len(trim(qCrmParticipacoes.estado))> / #htmlEditFormat(qCrmParticipacoes.estado)#</cfif>
                      </td>
                      <td class="text-end">
                        <cfif len(trim(qCrmParticipacoes.lead_score))>#LSNumberFormat(qCrmParticipacoes.lead_score, "999.9")#</cfif>
                      </td>
                      <td class="text-end">
                        <cfif len(trim(qCrmParticipacoes.id_usuario))>
                          <span class="badge badge-primary">sim</span>
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                      </td>
                      <td class="text-end">
                        <cfif crmIsTruthy(qCrmParticipacoes.correu)>
                          <span class="badge badge-success">sim</span>
                        <cfelseif crmIsTruthy(qCrmParticipacoes.concluinte)>
                          <span class="badge badge-success">sim</span>
                        <cfelse>
                          <span class="text-muted">-</span>
                        </cfif>
                      </td>
                    </tr>
                  </cfoutput>
                <cfelse>
                  <tr>
                    <td colspan="9" class="text-center text-muted py-4">Nenhum registro encontrado.</td>
                  </tr>
                </cfif>
              </tbody>
            </table>
          </div>

          <cfif VARIABLES.crmTotalPaginas GT 1>
            <div class="d-flex justify-content-end gap-2 mt-3">
              <cfoutput>
                <a class="btn btn-sm btn-outline-secondary <cfif VARIABLES.crmPagina LTE 1>disabled</cfif>" href="#crmQueryString(max(1, VARIABLES.crmPagina - 1))#">Anterior</a>
                <a class="btn btn-sm btn-outline-secondary <cfif VARIABLES.crmPagina GTE VARIABLES.crmTotalPaginas>disabled</cfif>" href="#crmQueryString(min(VARIABLES.crmTotalPaginas, VARIABLES.crmPagina + 1))#">Próxima</a>
              </cfoutput>
            </div>
          </cfif>
          </cfif>

        </div>
      </div>
    </div>
  </div>
</section>
