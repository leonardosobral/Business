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

  .content-toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    align-items: end;
  }

  .content-importer-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
    background: rgba(255,255,255,0.02);
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
            </form>

            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover content-table">
                <thead>
                  <tr>
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
                        <td class="content-thumb-cell">
                          <div class="content-thumb">
                            <cfif len(VARIABLES.contentFeaturedMediaUrl)>
                              <img src="#htmlEditFormat(VARIABLES.contentFeaturedMediaUrl)#" alt="Capa do conteúdo"/>
                            <cfelse>
                              <span class="text-muted small">-</span>
                            </cfif>
                          </div>
                        </td>
                        <td>#qContents.id#</td>
                        <td class="content-cell">
                          <div class="fw-semibold">#htmlEditFormat(qContents.title)#</div>
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
                            <span class="badge <cfif VARIABLES.contentPublished>badge-success<cfelse>badge-danger</cfif>">
                              <cfif VARIABLES.contentPublished>Exibido<cfelse>Oculto</cfif>
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
                      <td colspan="6" class="text-center text-muted py-4">Nenhum conteudo encontrado para este recorte.</td>
                    </tr>
                  </cfif>
                </tbody>
              </table>
            </div>

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

            <hr class="my-4"/>

            <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
              <div>
                <h5 class="mb-1">Importadores remotos</h5>
                <p class="text-muted small mb-0">Acesse daqui os importadores dos parceiros já existentes no projeto Conteúdo, sem precisar navegar manualmente até o outro painel.</p>
              </div>
              <a class="btn btn-outline-secondary" href="<cfoutput>#htmlEditFormat(VARIABLES.contentAdminBaseUrl)#/admin/importers</cfoutput>" target="_blank" rel="noopener">Central de importadores</a>
            </div>

            <div class="row g-4">
              <cfloop array="#VARIABLES.contentImporters#" index="contentImporter">
                <div class="col-12 col-xl-4">
                  <div class="content-importer-card p-4 h-100">
                    <div class="text-uppercase small fw-semibold text-warning mb-2"><cfoutput>#htmlEditFormat(contentImporter.type)#</cfoutput></div>
                    <h6 class="mb-2"><cfoutput>#htmlEditFormat(contentImporter.name)#</cfoutput></h6>
                    <p class="text-muted small mb-3"><cfoutput>#htmlEditFormat(contentImporter.description)#</cfoutput></p>
                    <div class="small text-muted mb-3">
                      Feed:
                      <cfoutput><a href="#htmlEditFormat(contentImporter.feed)#" target="_blank" rel="noopener">#htmlEditFormat(contentImporter.feed)#</a></cfoutput>
                    </div>
                    <cfoutput>
                      <a class="btn btn-primary" href="<cfoutput>#htmlEditFormat(contentImporter.url)#</cfoutput>" target="_blank" rel="noopener">Abrir importador</a>
                    </cfoutput>
                  </div>
                </div>
              </cfloop>
            </div>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
