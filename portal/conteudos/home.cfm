<cfinclude template="../includes/content_backend.cfm"/>

<style>
  .content-table {
    min-width: 1220px;
  }

  .content-table td,
  .content-table th {
    vertical-align: middle;
  }

  .content-cell {
    max-width: 360px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .content-actions-cell {
    min-width: 260px;
  }

  .content-thumb-cell {
    width: 116px;
    min-width: 116px;
  }

  .content-thumb {
    width: 96px;
    height: 54px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 0.5rem;
    overflow: hidden;
    background: var(--mdb-secondary-bg);
  }

  .content-thumb img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }

  .content-preview-trigger {
    padding: 0;
    border: 0;
    color: inherit;
    text-align: left;
    background: transparent;
    cursor: pointer;
  }

  .content-preview-trigger:hover .content-preview-title,
  .content-preview-trigger:focus .content-preview-title {
    color: var(--mdb-warning);
    text-decoration: underline;
  }

  .content-preview-trigger:hover .content-thumb,
  .content-preview-trigger:focus .content-thumb {
    outline: 2px solid rgba(245, 196, 81, 0.75);
    outline-offset: 2px;
  }

  .content-preview-modal .modal-dialog {
    max-width: min(96vw, 1600px);
  }

  .content-preview-frame {
    width: 100%;
    height: min(80vh, 1000px);
    border: 0;
    background: #fff;
  }

  .content-preview-header {
    display: flex;
    flex-wrap: nowrap;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }

  .content-preview-header-title {
    min-width: 0;
    margin: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .content-preview-header-actions {
    display: flex;
    flex: 0 0 auto;
    align-items: center;
    gap: 8px;
    margin-left: auto;
  }

  @media (max-width: 575.98px) {
    .content-preview-header {
      flex-wrap: wrap;
      align-items: flex-start;
    }

    .content-preview-header-title {
      width: 100%;
      white-space: normal;
    }

    .content-preview-header-actions {
      width: 100%;
      justify-content: flex-end;
    }
  }

  .content-toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    align-items: end;
  }

</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Conteúdos</h3>
              <p class="text-muted mb-0">Liste os conteúdos editoriais do repositório News, controle a visibilidade no site e acesse os importadores remotos dos parceiros.</p>
            </div>
            <div class="text-lg-end d-flex gap-4">
              <div>
                <div class="small text-muted">Total</div>
                <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qContentStats.total)#</cfoutput></div>
              </div>
              <div>
                <div class="small text-muted">Publicados</div>
                <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qContentStats.total_publicados)#</cfoutput></div>
              </div>
              <div>
                <div class="small text-muted">Ocultos</div>
                <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qContentStats.total_ocultos)#</cfoutput></div>
              </div>
              <div>
                <div class="small text-muted">Destaques</div>
                <div class="h4 mb-0 text-warning"><cfoutput>#LSNumberFormat(qContentStats.total_destaques)#</cfoutput></div>
              </div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o controle de conteudos do Portal.
            </div>
          <cfelseif NOT qContentColumns.recordcount>
            <div class="alert alert-danger mb-0">
              Nao foi possivel localizar a tabela <strong>news.tb_content</strong>.
            </div>
          <cfelse>
            <form method="get" action="./" class="content-toolbar mb-4">
              <input type="hidden" name="pagina" value="1"/>

              <div>
                <label class="form-label">Busca</label>
                <input class="form-control" type="text" name="busca" value="<cfoutput>#htmlEditFormat(URL.busca)#</cfoutput>" placeholder="Titulo, slug ou resumo"/>
              </div>

              <div>
                <label class="form-label">Canal</label>
                <select class="form-select" name="canal">
                  <option value="">Todos os canais</option>
                  <cfoutput query="qContentTypes">
                    <option value="#htmlEditFormat(qContentTypes.slug)#" <cfif lCase(trim(URL.canal)) EQ lCase(trim(qContentTypes.slug))>selected</cfif>>#htmlEditFormat(qContentTypes.name)#</option>
                  </cfoutput>
                </select>
              </div>

              <div>
                <label class="form-label">Status</label>
                <select class="form-select" name="status">
                  <option value="todos" <cfif VARIABLES.contentStatusFilter EQ "todos">selected</cfif>>Todos</option>
                  <option value="pendentes" <cfif VARIABLES.contentStatusFilter EQ "pendentes">selected</cfif>>Pendentes de curadoria</option>
                  <option value="rejeitados" <cfif VARIABLES.contentStatusFilter EQ "rejeitados">selected</cfif>>Rejeitados</option>
                  <option value="publicados" <cfif VARIABLES.contentStatusFilter EQ "publicados">selected</cfif>>Publicados</option>
                  <option value="ocultos" <cfif VARIABLES.contentStatusFilter EQ "ocultos">selected</cfif>>Ocultos</option>
                </select>
              </div>

              <div>
                <label class="form-label">Destaque na home</label>
                <select class="form-select" name="destaque">
                  <option value="todos" <cfif VARIABLES.contentFeaturedFilter EQ "todos">selected</cfif>>Todos</option>
                  <option value="sim" <cfif VARIABLES.contentFeaturedFilter EQ "sim">selected</cfif>>Em destaque</option>
                  <option value="nao" <cfif VARIABLES.contentFeaturedFilter EQ "nao">selected</cfif>>Sem destaque</option>
                </select>
              </div>

              <div>
                <button class="btn btn-outline-warning" type="submit">Filtrar</button>
              </div>

              <div>
                <a class="btn btn-outline-secondary" href="<cfoutput>#htmlEditFormat(VARIABLES.contentAdminBaseUrl)#/admin/importers</cfoutput>" target="_blank" rel="noopener">
                  <i class="fa-solid fa-arrows-rotate me-1"></i>Central de importadores
                </a>
              </div>
            </form>

            <form method="post" action="./?pagina=<cfoutput>#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#</cfoutput>" id="contentBulkForm">
              <input type="hidden" name="content_bulk_action" value="apply_status"/>
              <div class="d-flex flex-wrap align-items-end gap-2 mb-3">
                <div>
                  <label class="form-label mb-1" for="contentBulkStatus">Alterar status dos selecionados</label>
                  <select class="form-select" id="contentBulkStatus" name="bulk_status" required>
                    <option value="">Selecione o novo status</option>
                    <option value="published">Publicado</option>
                    <option value="review">Pendente de curadoria</option>
                    <option value="rejected">Rejeitado</option>
                    <option value="draft">Oculto / Rascunho</option>
                  </select>
                </div>
                <button class="btn btn-warning" type="submit" id="contentBulkSubmit" disabled>Aplicar</button>
                <span class="small text-muted pb-2" id="contentBulkCount">Nenhum conteúdo selecionado</span>
              </div>

              <div class="table-responsive">
              <table class="table table-sm table-striped table-hover content-table">
                <thead>
                  <tr>
                    <th>
                      <input class="form-check-input" type="checkbox" id="contentSelectAll" aria-label="Selecionar todos os conteúdos desta página"/>
                    </th>
                    <th class="content-thumb-cell">Capa</th>
                    <th>ID</th>
                    <th>Titulo</th>
                    <th>Publicacao</th>
                    <th>Status</th>
                    <th class="content-actions-cell">Acoes</th>
                  </tr>
                </thead>
                <tbody>
                  <cfif qContents.recordcount>
                    <cfoutput query="qContents">
                      <cfset VARIABLES.contentPublished = IsBoolean(qContents.published) ? qContents.published : ListFindNoCase("true,1,yes,sim", trim(qContents.published & "")) GT 0/>
                      <cfset VARIABLES.contentEditorialStatus = lCase(trim(qContents.editorial_status & ""))/>
                      <cfset VARIABLES.contentFeatured = IsBoolean(qContents.is_featured) ? qContents.is_featured : ListFindNoCase("true,1,yes,sim", trim(qContents.is_featured & "")) GT 0/>
                      <cfset VARIABLES.contentFeaturedMediaUrl = trim(qContents.featured_media_url & "")/>
                      <cfif len(VARIABLES.contentFeaturedMediaUrl)
                          AND NOT reFindNoCase("^(https?:)?//", VARIABLES.contentFeaturedMediaUrl)
                          AND left(VARIABLES.contentFeaturedMediaUrl, 5) NEQ "data:">
                        <cfif left(VARIABLES.contentFeaturedMediaUrl, 1) EQ "/">
                          <cfset VARIABLES.contentFeaturedMediaUrl = VARIABLES.contentAdminBaseUrl & VARIABLES.contentFeaturedMediaUrl/>
                        <cfelse>
                          <cfset VARIABLES.contentFeaturedMediaUrl = VARIABLES.contentAdminBaseUrl & "/" & VARIABLES.contentFeaturedMediaUrl/>
                        </cfif>
                      </cfif>
                      <tr>
                        <td>
                          <input class="form-check-input content-bulk-checkbox" type="checkbox" name="content_ids" value="#qContents.id#" aria-label="Selecionar #htmlEditFormat(qContents.title)#"/>
                        </td>
                        <td class="content-thumb-cell">
                          <button type="button" class="content-preview-trigger"
                            data-preview-url="./preview.cfm?content_id=#urlEncodedFormat(qContents.id)#"
                            data-preview-title="#htmlEditFormat(qContents.title)#"
                            aria-label="Visualizar notícia #htmlEditFormat(qContents.title)#">
                            <div class="content-thumb">
                              <cfif len(VARIABLES.contentFeaturedMediaUrl)>
                                <img src="#htmlEditFormat(VARIABLES.contentFeaturedMediaUrl)#" alt="Capa do conteúdo"/>
                              <cfelse>
                                <i class="fa-regular fa-newspaper text-muted"></i>
                              </cfif>
                            </div>
                          </button>
                        </td>
                        <td>#qContents.id#</td>
                        <td class="content-cell">
                          <button type="button" class="content-preview-trigger"
                            data-preview-url="./preview.cfm?content_id=#urlEncodedFormat(qContents.id)#"
                            data-preview-title="#htmlEditFormat(qContents.title)#">
                            <div class="fw-semibold content-preview-title">#htmlEditFormat(qContents.title)#</div>
                          </button>
                          <div class="small text-muted">
                            <cfif len(trim(qContents.autor_nome))>#htmlEditFormat(qContents.autor_nome)#<cfelse>-</cfif> - #htmlEditFormat(qContents.canal_nome)#
                          </div>
                        </td>
                        <td class="content-cell">
                          <cfif isDate(qContents.published_at)>
                            #LSDateFormat(qContents.published_at, "dd/mm/yyyy")# às #LSTimeFormat(qContents.published_at, "HH:mm")#
                          <cfelse>
                            <span class="text-muted">-</span>
                          </cfif>
                        </td>
                        <td class="content-cell">
                          <div class="mb-1">
                            <span class="badge <cfif VARIABLES.contentPublished>badge-success<cfelseif VARIABLES.contentEditorialStatus EQ "rejected">badge-secondary<cfelse>badge-danger</cfif>">
                              <cfif VARIABLES.contentPublished>Exibido<cfelseif VARIABLES.contentEditorialStatus EQ "rejected">Rejeitado<cfelseif VARIABLES.contentEditorialStatus EQ "review">Pendente de curadoria<cfelse>Oculto</cfif>
                            </span>
                          </div>
                          <cfif VARIABLES.contentFeatured>
                            <div><span class="badge badge-warning text-dark"><i class="fa-solid fa-star me-1"></i>Destaque na home</span></div>
                          </cfif>
                        </td>
                        <td class="content-actions-cell">
                          <div class="d-flex flex-wrap gap-2">
                            <a class="btn btn-sm <cfif VARIABLES.contentPublished>btn-outline-danger<cfelse>btn-outline-success</cfif>" href="./?acao=pub_status&content_id=#qContents.id#&published=#NOT VARIABLES.contentPublished#&pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#">
                              <cfif VARIABLES.contentPublished>Ocultar<cfelse>Exibir</cfif>
                            </a>
                            <cfif VARIABLES.contentEditorialStatus EQ "review">
                              <a class="btn btn-sm btn-outline-danger" href="./?acao=editorial_status&content_id=#qContents.id#&editorial_status=rejected&pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#" onclick="return confirm('Rejeitar este conteúdo e mantê-lo oculto?');">
                                Rejeitar
                              </a>
                            <cfelseif VARIABLES.contentEditorialStatus EQ "rejected">
                              <a class="btn btn-sm btn-outline-warning" href="./?acao=editorial_status&content_id=#qContents.id#&editorial_status=review&pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#">
                                Retornar à curadoria
                              </a>
                            </cfif>
                            <cfif VARIABLES.contentHasIsFeatured>
                              <cfif VARIABLES.contentPublished OR VARIABLES.contentFeatured>
                                <a class="btn btn-sm <cfif VARIABLES.contentFeatured>btn-warning<cfelse>btn-outline-warning</cfif>" href="./?acao=destaque&content_id=#qContents.id#&featured=#NOT VARIABLES.contentFeatured#&pagina=#VARIABLES.contentPage#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#" title="<cfif VARIABLES.contentFeatured>Remover da home<cfelse>Destacar na home</cfif>">
                                  <i class="fa-<cfif VARIABLES.contentFeatured>solid<cfelse>regular</cfif> fa-star me-1"></i><cfif VARIABLES.contentFeatured>Remover destaque<cfelse>Destacar</cfif>
                                </a>
                              </cfif>
                            </cfif>
                            <a class="btn btn-sm btn-outline-secondary" href="<cfoutput>#htmlEditFormat(VARIABLES.contentAdminBaseUrl)#/admin/content_edit?id=#qContents.id#</cfoutput>" target="_blank" rel="noopener">
                              Editar
                            </a>
                          </div>
                        </td>
                      </tr>
                    </cfoutput>
                  <cfelse>
                    <tr>
                      <td colspan="7" class="text-center text-muted py-4">Nenhum conteudo encontrado para este recorte.</td>
                    </tr>
                  </cfif>
                </tbody>
              </table>
              </div>
            </form>

            <cfif VARIABLES.contentTotalPages GT 1>
              <nav aria-label="Paginacao de conteudos">
                <ul class="pagination pagination-sm justify-content-center flex-wrap mt-3 mb-0">
                  <cfoutput>
                    <li class="page-item <cfif VARIABLES.contentPage LTE 1>disabled</cfif>">
                      <a class="page-link" href="./?pagina=#max(1, VARIABLES.contentPage - 1)#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#">Anterior</a>
                    </li>
                  </cfoutput>

                  <cfloop from="#max(1, VARIABLES.contentPage - 3)#" to="#min(VARIABLES.contentTotalPages, VARIABLES.contentPage + 3)#" index="contentPageIndex">
                    <cfoutput>
                      <li class="page-item <cfif contentPageIndex EQ VARIABLES.contentPage>active</cfif>">
                        <a class="page-link" href="./?pagina=#contentPageIndex#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#">#contentPageIndex#</a>
                      </li>
                    </cfoutput>
                  </cfloop>

                  <cfoutput>
                    <li class="page-item <cfif VARIABLES.contentPage GTE VARIABLES.contentTotalPages>disabled</cfif>">
                      <a class="page-link" href="./?pagina=#min(VARIABLES.contentTotalPages, VARIABLES.contentPage + 1)#&busca=#urlEncodedFormat(URL.busca)#&canal=#urlEncodedFormat(URL.canal)#&status=#urlEncodedFormat(VARIABLES.contentStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.contentFeaturedFilter)#">Proxima</a>
                    </li>
                  </cfoutput>
                </ul>
              </nav>
            </cfif>

          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>

<div class="modal fade content-preview-modal" id="contentPreviewModal" tabindex="-1" aria-labelledby="contentPreviewModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header content-preview-header">
        <h5 class="modal-title content-preview-header-title" id="contentPreviewModalLabel">Prévia da notícia</h5>
        <div class="content-preview-header-actions">
          <a class="btn btn-sm btn-outline-warning" id="contentPreviewOpenLink" href="#" target="_blank" rel="noopener noreferrer">
            Abrir em nova aba
          </a>
          <button type="button" class="btn-close" data-mdb-dismiss="modal" aria-label="Fechar"></button>
        </div>
      </div>
      <div class="modal-body p-0">
        <iframe class="content-preview-frame" id="contentPreviewFrame" title="Prévia da notícia" loading="lazy" sandbox=""></iframe>
      </div>
    </div>
  </div>
</div>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    const modalElement = document.getElementById('contentPreviewModal');
    const modalTitle = document.getElementById('contentPreviewModalLabel');
    const modalLink = document.getElementById('contentPreviewOpenLink');
    const previewFrame = document.getElementById('contentPreviewFrame');
    const closeButton = modalElement ? modalElement.querySelector('[data-mdb-dismiss="modal"]') : null;
    const bulkForm = document.getElementById('contentBulkForm');
    const selectAll = document.getElementById('contentSelectAll');
    const bulkCheckboxes = Array.from(document.querySelectorAll('.content-bulk-checkbox'));
    const bulkSubmit = document.getElementById('contentBulkSubmit');
    const bulkCount = document.getElementById('contentBulkCount');

    function updateBulkSelection() {
      const selectedCount = bulkCheckboxes.filter(function (checkbox) {
        return checkbox.checked;
      }).length;

      if (bulkSubmit) {
        bulkSubmit.disabled = selectedCount === 0;
      }
      if (bulkCount) {
        bulkCount.textContent = selectedCount === 0
          ? 'Nenhum conteúdo selecionado'
          : selectedCount + (selectedCount === 1 ? ' conteúdo selecionado' : ' conteúdos selecionados');
      }
      if (selectAll) {
        selectAll.checked = bulkCheckboxes.length > 0 && selectedCount === bulkCheckboxes.length;
        selectAll.indeterminate = selectedCount > 0 && selectedCount < bulkCheckboxes.length;
      }
    }

    if (selectAll) {
      selectAll.addEventListener('change', function () {
        bulkCheckboxes.forEach(function (checkbox) {
          checkbox.checked = selectAll.checked;
        });
        updateBulkSelection();
      });
    }

    bulkCheckboxes.forEach(function (checkbox) {
      checkbox.addEventListener('change', updateBulkSelection);
    });

    if (bulkForm) {
      bulkForm.addEventListener('submit', function (event) {
        const selectedCount = bulkCheckboxes.filter(function (checkbox) {
          return checkbox.checked;
        }).length;
        const selectedStatus = document.getElementById('contentBulkStatus');

        if (selectedCount === 0 || !selectedStatus || !selectedStatus.value) {
          event.preventDefault();
          window.alert('Selecione ao menos um conteúdo e o novo status.');
          return;
        }

        if (!window.confirm('Aplicar o novo status a ' + selectedCount + (selectedCount === 1 ? ' conteúdo?' : ' conteúdos?'))) {
          event.preventDefault();
        }
      });
    }

    if (!modalElement || !previewFrame) {
      return;
    }

    const ModalConstructor = window.mdb && window.mdb.Modal
      ? window.mdb.Modal
      : (window.bootstrap && window.bootstrap.Modal ? window.bootstrap.Modal : null);
    const previewModal = ModalConstructor ? new ModalConstructor(modalElement) : null;

    document.querySelectorAll('.content-preview-trigger').forEach(function (trigger) {
      trigger.addEventListener('click', function (event) {
        event.preventDefault();

        const previewUrl = trigger.dataset.previewUrl || '';
        const previewTitle = trigger.dataset.previewTitle || 'Prévia da notícia';

        modalTitle.textContent = previewTitle;
        modalLink.href = previewUrl;
        previewFrame.src = previewUrl;

        if (previewModal) {
          previewModal.show();
        }
      });
    });

    if (closeButton && previewModal) {
      closeButton.addEventListener('click', function () {
        previewModal.hide();
      });
    }

    function clearPreview() {
      previewFrame.removeAttribute('src');
    }

    modalElement.addEventListener('hidden.mdb.modal', clearPreview);
    modalElement.addEventListener('hidden.bs.modal', clearPreview);
  });
</script>
