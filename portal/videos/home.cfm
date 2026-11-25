<cfinclude template="../includes/media_backend.cfm"/>
<cfset VARIABLES.mediaHasDurationSeconds = false/>
<cfset VARIABLES.mediaHasDurationIso = false/>
<cfset VARIABLES.mediaHasTitle = ListFindNoCase(VARIABLES.mediaColumns, "media_titulo")/>
<cfset VARIABLES.mediaHasChannelName = ListFindNoCase(VARIABLES.mediaColumns, "media_canal_nome")/>
<cfset VARIABLES.mediaPublicationColumn = ""/>
<cfif ListFindNoCase(VARIABLES.mediaColumns, "data_publicacao")>
  <cfset VARIABLES.mediaPublicationColumn = "data_publicacao"/>
<cfelseif ListFindNoCase(VARIABLES.mediaColumns, "data_publicação")>
  <cfset VARIABLES.mediaPublicationColumn = "data_publicação"/>
</cfif>
<cfloop query="qMediaColumns">
  <cfset VARIABLES.mediaColumnCandidate = trim(qMediaColumns.column_name & "")/>
  <cfif VARIABLES.mediaColumnCandidate EQ "youtube_duration_seconds">
    <cfset VARIABLES.mediaHasDurationSeconds = true/>
  <cfelseif VARIABLES.mediaColumnCandidate EQ "youtube_duration_iso">
    <cfset VARIABLES.mediaHasDurationIso = true/>
  </cfif>
</cfloop>
<cfset VARIABLES.mediaTableColspan = 7/>

<style>
  .media-table {
    min-width: 1050px;
  }

  .media-table td,
  .media-table th {
    vertical-align: middle;
  }

  .media-cell {
    max-width: 360px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .media-actions-cell {
    min-width: 190px;
  }

  .media-thumbnail-cell {
    width: 112px;
    min-width: 112px;
  }

  .media-thumbnail-button {
    width: 96px;
    height: 54px;
    border: 0;
    padding: 0;
    border-radius: 0.5rem;
    overflow: hidden;
    background: var(--mdb-secondary-bg);
  }

  .media-thumbnail-button img {
    width: 100%;
    height: 100%;
    display: block;
    object-fit: cover;
  }

  .media-video-frame {
    width: 100%;
    aspect-ratio: 16 / 9;
    min-height: 320px;
    border: 0;
    border-radius: 0.5rem;
    background: #000;
  }

  .media-toolbar {
    display: flex;
    flex-wrap: wrap;
    gap: 1rem;
    align-items: end;
  }

  .media-featured-card {
    border: 1px solid rgba(250, 177, 32, 0.35);
    border-radius: 0.75rem;
    background: rgba(250, 177, 32, 0.08);
  }

  .media-event-cell { min-width: 210px; max-width: 280px; overflow-wrap: anywhere; }
  .media-manager .media-kpis { grid-template-columns: repeat(4, minmax(70px, 1fr)); min-width: 320px; }
  .media-manager .media-toolbar { gap: .75rem; }
  .media-manager .media-toolbar > div:first-of-type { flex: 1 1 260px; }
  .media-event-editor { border: 1px solid var(--business-ui-border-strong); border-radius: .65rem; background: var(--business-panel); scroll-margin-top: 90px; }
  .media-event-editor:focus-within { border-color: var(--business-accent); }
  .media-manager .media-title { max-width: 360px; }
  @media (max-width: 575px) { .media-manager .media-kpis { min-width: 0; width: 100%; } .media-manager .media-toolbar > div { flex: 1 1 100%; } }

  .media-featured-event-panel {
    border-top: 1px solid rgba(250, 177, 32, 0.25);
  }

  .media-event-search-results {
    display: grid;
    gap: 0.5rem;
    max-height: 320px;
    overflow-y: auto;
  }

  .media-event-search-option {
    display: flex;
    gap: 0.75rem;
    align-items: flex-start;
    padding: 0.75rem;
    border: 1px solid var(--mdb-border-color, rgba(128, 128, 128, 0.25));
    border-radius: 0.5rem;
    cursor: pointer;
  }

  .media-event-search-option:hover {
    border-color: #fab120;
    background: rgba(250, 177, 32, 0.08);
  }
</style>

<section class="business-page media-manager">
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0 business-page-card">
        <div class="card-body business-page-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <div class="small text-warning fw-semibold text-uppercase mb-1">Portal Road Runners</div><h1 class="business-page-title mb-1">Vídeos</h1>
              <p class="text-muted mb-0">Organize os vídeos, vincule eventos e escolha o destaque da home de forma independente.</p>
            </div>
            <div class="business-kpi-grid media-kpis">
              <div>
                <div class="small text-muted">Total</div>
                <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qMediaStats.total)#</cfoutput></div>
              </div>
              <div>
                <div class="small text-muted">Publicados</div>
                <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qMediaStats.total_publicados)#</cfoutput></div>
              </div>
              <div>
                <div class="small text-muted">Ocultos</div>
                <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qMediaStats.total_ocultos)#</cfoutput></div>
              </div>
              <div>
                <div class="small text-muted">Destaque na home</div>
                <div class="h4 mb-0 text-warning"><cfoutput>#LSNumberFormat(qMediaStats.total_destaques)#</cfoutput></div>
              </div>
            </div>
          </div>

          <div class="small text-muted mt-2"><cfoutput>#LSNumberFormat(qMediaStats.total_vinculados)#</cfoutput> vídeos vinculados a eventos</div>
          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o controle de videos do Portal.
            </div>
          <cfelseif NOT qMediaColumns.recordcount>
            <div class="alert alert-danger mb-0">
              Nao foi possivel localizar as colunas da tabela <strong>tb_media</strong>.
            </div>
          <cfelse>
            <form method="get" action="./" class="media-toolbar mb-4">
              <input type="hidden" name="pagina" value="1"/>

              <div>
                <label class="form-label" for="media-search">Buscar vídeos</label>
                <input class="form-control" id="media-search" type="search" name="busca" value="<cfoutput>#encodeForHTMLAttribute(URL.busca)#</cfoutput>" placeholder="Título, canal, URL ou evento"/>
              </div>

              <div>
                <label class="form-label" for="media-status">Publicação</label>
                <select class="form-select" name="status" id="media-status">
                  <option value="todos" <cfif VARIABLES.mediaStatusFilter EQ "todos">selected</cfif>>Todos</option>
                  <option value="publicados" <cfif VARIABLES.mediaStatusFilter EQ "publicados">selected</cfif>>Publicados</option>
                  <option value="ocultos" <cfif VARIABLES.mediaStatusFilter EQ "ocultos">selected</cfif>>Ocultos</option>
                </select>
              </div>

              <div>
                <label class="form-label" for="media-featured">Destaque na home</label>
                <select class="form-select" name="destaque" id="media-featured">
                  <option value="todos" <cfif VARIABLES.mediaFeaturedFilter EQ "todos">selected</cfif>>Todos</option>
                  <option value="sim" <cfif VARIABLES.mediaFeaturedFilter EQ "sim">selected</cfif>>Em destaque</option>
                  <option value="nao" <cfif VARIABLES.mediaFeaturedFilter EQ "nao">selected</cfif>>Sem destaque</option>
                </select>
              </div>

              <div>
                <label class="form-label" for="media-link">Vínculo com evento</label>
                <select class="form-select" name="vinculo" id="media-link">
                  <option value="todos" <cfif VARIABLES.mediaLinkFilter EQ "todos">selected</cfif>>Todos os vídeos</option>
                  <option value="sim" <cfif VARIABLES.mediaLinkFilter EQ "sim">selected</cfif>>Com evento</option>
                  <option value="nao" <cfif VARIABLES.mediaLinkFilter EQ "nao">selected</cfif>>Sem evento</option>
                </select>
              </div>
              <div class="d-flex gap-2">
                <button class="btn btn-warning" type="submit">Filtrar</button>
                <a class="btn btn-outline-light" href="./">Limpar</a>
              </div>
            </form>

            <cfif len(VARIABLES.mediaFeaturedEventAlert.message)>
              <cfoutput><div role="alert" class="alert alert-#encodeForHTMLAttribute(VARIABLES.mediaFeaturedEventAlert.type)#">#encodeForHTML(VARIABLES.mediaFeaturedEventAlert.message)#</div></cfoutput>
            <cfelseif URL.sucesso EQ "evento_vinculado">
              <div role="status" class="alert alert-success">Evento vinculado ao vídeo. A publicação e o destaque foram mantidos.</div>
            <cfelseif URL.sucesso EQ "evento_desvinculado">
              <div role="status" class="alert alert-success">Vínculo com o evento removido. A publicação e o destaque foram mantidos.</div>
            </cfif>

            <cfif VARIABLES.mediaHasIsFeatured>
              <div class="media-featured-card p-3 mb-3" id="video-destaque">
                <cfoutput><div class="d-flex flex-wrap justify-content-between align-items-center gap-2">
                  <div><div class="small text-warning fw-semibold text-uppercase"><i class="fa-solid fa-star me-1" aria-hidden="true"></i>Destaque atual da home</div>
                    <cfif qMediaFeaturedCurrent.recordcount><div class="fw-semibold">#encodeForHTML(qMediaFeaturedCurrent.media_titulo)#</div>
                    <cfelse><div class="text-muted small">Nenhum vídeo destacado. Use a estrela de um vídeo publicado para escolher.</div></cfif>
                  </div>
                  <cfif qMediaFeaturedCurrent.recordcount><div class="d-flex gap-2">
                    <button class="btn btn-sm btn-outline-light js-media-video" type="button" data-media-url="#encodeForHTMLAttribute(qMediaFeaturedCurrent.media_url)#" data-media-title="#encodeForHTMLAttribute(qMediaFeaturedCurrent.media_titulo)#">Assistir</button>
                    <cfif VARIABLES.mediaHasEventId><a class="btn btn-sm btn-outline-warning" href="#encodeForHTMLAttribute(VARIABLES.mediaListUrl)#&amp;video_id=#qMediaFeaturedCurrent.media_pk###video-evento">Gerenciar evento</a></cfif>
                  </div></cfif>
                </div></cfoutput>
              </div>
            </cfif>

            <cfinclude template="event_editor.cfm"/>
            <div class="d-flex flex-wrap justify-content-between gap-2 small text-muted mb-2">
              <cfoutput><span>#LSNumberFormat(qMediaCount.total)# vídeo(s) encontrado(s)</span><span>Página #VARIABLES.mediaPage# de #VARIABLES.mediaTotalPages# · Mais recentes primeiro</span></cfoutput>
            </div>
            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover media-table">
                <thead>
                  <tr>
                    <th class="media-thumbnail-cell">Prévia</th>
                    <th>Vídeo</th>
                    <th>Canal</th>
                    <th>Publicação / duração</th>
                    <th>Evento vinculado</th>
                    <th>Status</th>
                    <th class="media-actions-cell">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  <cfif qMedia.recordcount>
                    <cfoutput query="qMedia">
                      <cfset VARIABLES.mediaPkValue = qMedia[VARIABLES.mediaPk][qMedia.currentRow]/>
                      <cfset VARIABLES.mediaDurationSeconds = 0/>
                      <cfset VARIABLES.mediaDurationFormatted = "-"/>
                      <cfset VARIABLES.mediaTitle = ""/>
                      <cfset VARIABLES.mediaChannelName = ""/>
                      <cfset VARIABLES.mediaPublishedAt = ""/>
                      <cfset VARIABLES.mediaIsPublished = false/>
                      <cfset VARIABLES.mediaIsFeatured = false/>
                      <cfset VARIABLES.mediaCanManageFeatured = false/>
                      <cfif VARIABLES.mediaHasTitle>
                        <cfset VARIABLES.mediaTitle = trim(qMedia["media_titulo"][qMedia.currentRow] & "")/>
                      </cfif>
                      <cfif VARIABLES.mediaHasChannelName>
                        <cfset VARIABLES.mediaChannelName = trim(qMedia["media_canal_nome"][qMedia.currentRow] & "")/>
                      </cfif>
                      <cfif len(VARIABLES.mediaPublicationColumn)>
                        <cfset VARIABLES.mediaPublishedAt = qMedia[VARIABLES.mediaPublicationColumn][qMedia.currentRow]/>
                      </cfif>
                      <cfif VARIABLES.mediaHasPubStatus>
                        <cfset VARIABLES.mediaIsPublished = IsBoolean(qMedia["pub_status"][qMedia.currentRow]) ? qMedia["pub_status"][qMedia.currentRow] : ListFindNoCase("true,1,yes,sim", trim(qMedia["pub_status"][qMedia.currentRow] & "")) GT 0/>
                      </cfif>
                      <cfif VARIABLES.mediaHasIsFeatured>
                        <cfset VARIABLES.mediaIsFeatured = IsBoolean(qMedia["is_featured"][qMedia.currentRow]) ? qMedia["is_featured"][qMedia.currentRow] : ListFindNoCase("true,1,yes,sim", trim(qMedia["is_featured"][qMedia.currentRow] & "")) GT 0/>
                      </cfif>
                      <cfif VARIABLES.mediaHasDurationSeconds AND NOT isNull(qMedia["youtube_duration_seconds"][qMedia.currentRow]) AND isNumeric(qMedia["youtube_duration_seconds"][qMedia.currentRow])>
                        <cfset VARIABLES.mediaDurationSeconds = val(qMedia["youtube_duration_seconds"][qMedia.currentRow])/>
                      <cfelseif VARIABLES.mediaHasDurationIso AND NOT isNull(qMedia["youtube_duration_iso"][qMedia.currentRow]) AND len(trim(qMedia["youtube_duration_iso"][qMedia.currentRow]))>
                        <cfset VARIABLES.mediaDurationIso = qMedia["youtube_duration_iso"][qMedia.currentRow]/>
                        <cfset VARIABLES.mediaDurationHoursMatch = reFindNoCase("([0-9]+)H", VARIABLES.mediaDurationIso, 1, true)/>
                        <cfset VARIABLES.mediaDurationMinutesMatch = reFindNoCase("([0-9]+)M", VARIABLES.mediaDurationIso, 1, true)/>
                        <cfset VARIABLES.mediaDurationSecondsMatch = reFindNoCase("([0-9]+)S", VARIABLES.mediaDurationIso, 1, true)/>
                        <cfif arrayLen(VARIABLES.mediaDurationHoursMatch.pos) GTE 2 AND VARIABLES.mediaDurationHoursMatch.pos[2] GT 0>
                          <cfset VARIABLES.mediaDurationSeconds = VARIABLES.mediaDurationSeconds + (val(mid(VARIABLES.mediaDurationIso, VARIABLES.mediaDurationHoursMatch.pos[2], VARIABLES.mediaDurationHoursMatch.len[2])) * 3600)/>
                        </cfif>
                        <cfif arrayLen(VARIABLES.mediaDurationMinutesMatch.pos) GTE 2 AND VARIABLES.mediaDurationMinutesMatch.pos[2] GT 0>
                          <cfset VARIABLES.mediaDurationSeconds = VARIABLES.mediaDurationSeconds + (val(mid(VARIABLES.mediaDurationIso, VARIABLES.mediaDurationMinutesMatch.pos[2], VARIABLES.mediaDurationMinutesMatch.len[2])) * 60)/>
                        </cfif>
                        <cfif arrayLen(VARIABLES.mediaDurationSecondsMatch.pos) GTE 2 AND VARIABLES.mediaDurationSecondsMatch.pos[2] GT 0>
                          <cfset VARIABLES.mediaDurationSeconds = VARIABLES.mediaDurationSeconds + val(mid(VARIABLES.mediaDurationIso, VARIABLES.mediaDurationSecondsMatch.pos[2], VARIABLES.mediaDurationSecondsMatch.len[2]))/>
                        </cfif>
                      </cfif>
                      <cfif VARIABLES.mediaDurationSeconds GT 0>
                        <cfset VARIABLES.mediaDurationHours = int(VARIABLES.mediaDurationSeconds / 3600)/>
                        <cfset VARIABLES.mediaDurationMinutes = int((VARIABLES.mediaDurationSeconds MOD 3600) / 60)/>
                        <cfset VARIABLES.mediaDurationRemainderSeconds = VARIABLES.mediaDurationSeconds MOD 60/>
                        <cfset VARIABLES.mediaDurationFormatted = numberFormat(VARIABLES.mediaDurationHours, "00") & ":" & numberFormat(VARIABLES.mediaDurationMinutes, "00") & ":" & numberFormat(VARIABLES.mediaDurationRemainderSeconds, "00")/>
                      </cfif>
                      <cfset VARIABLES.mediaCanManageFeatured = VARIABLES.mediaHasIsFeatured AND (VARIABLES.mediaIsFeatured OR VARIABLES.mediaIsPublished OR NOT VARIABLES.mediaHasPubStatus)/>
                      <tr>
                        <td class="media-thumbnail-cell">
                          <cfif VARIABLES.mediaHasUrl AND len(trim(qMedia["media_url"][qMedia.currentRow]))>
                            <button type="button" class="media-thumbnail-button js-media-video js-media-thumbnail" data-media-url="#encodeForHTMLAttribute(qMedia["media_url"][qMedia.currentRow])#" data-media-title="#encodeForHTMLAttribute(VARIABLES.mediaTitle)#" aria-label="Assistir #encodeForHTMLAttribute(VARIABLES.mediaTitle)#">
                              <img alt="Miniatura do video" loading="lazy"/>
                            </button>
                          <cfelse>
                            <span class="text-muted small">-</span>
                          </cfif>
                        </td>
                        <td class="media-cell">
                          <div class="fw-semibold media-title"><cfif len(VARIABLES.mediaTitle)>#encodeForHTML(VARIABLES.mediaTitle)#<cfelse>Mídia ###encodeForHTML(VARIABLES.mediaPkValue)#</cfif></div>
                          <div class="small text-muted mt-1">ID #encodeForHTML(VARIABLES.mediaPkValue)#</div>
                        </td>
                        <td class="media-cell">
                          <cfif len(VARIABLES.mediaChannelName)>#encodeForHTML(VARIABLES.mediaChannelName)#<cfelse><span class="text-muted">-</span></cfif>
                        </td>
                        <td class="media-cell">
                          <cfif isDate(VARIABLES.mediaPublishedAt)>
                            #lsDateFormat(VARIABLES.mediaPublishedAt, "dd/mm/yyyy")#
                            <small class="text-muted d-block">#lsTimeFormat(VARIABLES.mediaPublishedAt, "HH:mm")#</small>
                          <cfelse>
                            <span class="text-muted">-</span>
                          </cfif>
                          <div class="small mt-1"><span class="text-muted">Duração:</span>
                          <span class="<cfif VARIABLES.mediaDurationSeconds GT 0 AND VARIABLES.mediaDurationSeconds LT VARIABLES.mediaMinimumPublishDurationSeconds>text-danger fw-bold</cfif>">#encodeForHTML(VARIABLES.mediaDurationFormatted)#</span></div>
                        </td>
                        <td class="media-event-cell">
                          <cfif VARIABLES.mediaHasEventId>
                            <cfif val(qMedia.id_evento) GT 0>
                              <a class="fw-semibold text-reset" href="/eventos/?id_evento=#val(qMedia.id_evento)#"><cfif len(trim(qMedia.nome_evento & ''))>#encodeForHTML(qMedia.nome_evento)#<cfelse>Evento ###val(qMedia.id_evento)#</cfif></a>
                              <div class="small text-muted"><cfif isDate(qMedia.evento_data)>#lsDateFormat(qMedia.evento_data,"dd/mm/yyyy")# · </cfif>#encodeForHTML(qMedia.evento_cidade ?: '')#<cfif len(qMedia.evento_estado ?: '')>/#encodeForHTML(qMedia.evento_estado)#</cfif></div>
                            <cfelse><span class="text-muted small">Sem evento vinculado</span></cfif>
                            <a class="btn btn-sm btn-outline-light mt-2" href="#encodeForHTMLAttribute(VARIABLES.mediaListUrl)#&amp;video_id=#urlEncodedFormat(VARIABLES.mediaPkValue)###video-evento"><i class="fa-solid fa-link me-1" aria-hidden="true"></i><cfif val(qMedia.id_evento) GT 0>Alterar vínculo<cfelse>Vincular evento</cfif></a>
                          <cfelse><span class="text-muted">Indisponível</span></cfif>
                        </td>
                        <td class="media-cell">
                          <div class="mb-1">
                            <span class="badge <cfif VARIABLES.mediaIsPublished>badge-success<cfelse>badge-danger</cfif>">
                              <cfif VARIABLES.mediaIsPublished>Publicado<cfelse>Oculto</cfif>
                            </span>
                          </div>
                          <cfif VARIABLES.mediaIsFeatured>
                            <div><span class="badge badge-warning text-dark"><i class="fa-solid fa-star me-1"></i>Destaque na home</span></div>
                          </cfif>
                        </td>

                        <td class="media-actions-cell">
                          <div class="d-flex flex-wrap gap-2">
                            <cfif VARIABLES.mediaHasPubStatus>
                              <cfif NOT VARIABLES.mediaIsPublished AND VARIABLES.mediaDurationSeconds GT 0 AND VARIABLES.mediaDurationSeconds LT VARIABLES.mediaMinimumPublishDurationSeconds>
                                <button class="btn btn-sm btn-outline-secondary" type="button" disabled title="Videos com menos de 3 minutos e 30 segundos permanecem ocultos">Exibir</button>
                              <cfelse>
                                <a class="btn btn-sm <cfif VARIABLES.mediaIsPublished>btn-outline-danger<cfelse>btn-outline-success</cfif>" href="./?acao=pub_status&media_id=#urlEncodedFormat(VARIABLES.mediaPkValue)#&published=#NOT VARIABLES.mediaIsPublished#&pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#">
                                  <cfif VARIABLES.mediaIsPublished>Ocultar<cfelse>Exibir</cfif>
                                </a>
                              </cfif>
                            </cfif>

                            <cfif VARIABLES.mediaHasIsFeatured>
                              <cfif VARIABLES.mediaCanManageFeatured>
                                <a class="btn btn-sm <cfif VARIABLES.mediaIsFeatured>btn-warning<cfelse>btn-outline-warning</cfif>" href="./?acao=destaque&media_id=#urlEncodedFormat(VARIABLES.mediaPkValue)#&featured=#NOT VARIABLES.mediaIsFeatured#&pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#" title="<cfif VARIABLES.mediaIsFeatured>Remover da home<cfelse>Destacar na home</cfif>">
                                  <i class="fa-<cfif VARIABLES.mediaIsFeatured>solid<cfelse>regular</cfif> fa-star me-1"></i><cfif VARIABLES.mediaIsFeatured>Remover destaque<cfelse>Destacar</cfif>
                                </a>
                              <cfelse>
                                <button class="btn btn-sm btn-outline-secondary" type="button" disabled title="Exiba o video antes de destaca-lo na home">
                                  <i class="fa-regular fa-star me-1"></i>Destacar
                                </button>
                              </cfif>
                            </cfif>

                            <a class="btn btn-sm btn-outline-danger" href="./?acao=excluir&media_id=#urlEncodedFormat(VARIABLES.mediaPkValue)#&pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#" onclick="return confirm('Tem certeza que deseja remover este video do banco de dados?');">
                              Remover
                            </a>
                          </div>
                        </td>
                      </tr>
                    </cfoutput>
                  <cfelse>
                    <tr>
                      <td colspan="<cfoutput>#VARIABLES.mediaTableColspan#</cfoutput>" class="text-center text-muted py-4">Nenhum video encontrado para este recorte.</td>
                    </tr>
                  </cfif>
                </tbody>
              </table>
            </div>

            <cfif VARIABLES.mediaTotalPages GT 1>
              <nav aria-label="Paginacao de videos">
                <ul class="pagination pagination-sm justify-content-center flex-wrap mt-3 mb-0">
                  <cfoutput>
                    <li class="page-item <cfif VARIABLES.mediaPage LTE 1>disabled</cfif>">
                      <a class="page-link" href="./?pagina=#max(1, VARIABLES.mediaPage - 1)#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#">Anterior</a>
                    </li>
                  </cfoutput>

                  <cfloop from="#max(1, VARIABLES.mediaPage - 3)#" to="#min(VARIABLES.mediaTotalPages, VARIABLES.mediaPage + 3)#" index="mediaPageIndex">
                    <cfoutput>
                      <li class="page-item <cfif mediaPageIndex EQ VARIABLES.mediaPage>active</cfif>">
                        <a class="page-link" href="./?pagina=#mediaPageIndex#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#">#mediaPageIndex#</a>
                      </li>
                    </cfoutput>
                  </cfloop>

                  <cfoutput>
                    <li class="page-item <cfif VARIABLES.mediaPage GTE VARIABLES.mediaTotalPages>disabled</cfif>">
                      <a class="page-link" href="./?pagina=#min(VARIABLES.mediaTotalPages, VARIABLES.mediaPage + 1)#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#&vinculo=#VARIABLES.mediaLinkFilter#">Proxima</a>
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

<div class="modal fade" id="mediaVideoModal" tabindex="-1" aria-labelledby="mediaVideoModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="mediaVideoModalLabel">Video</h5>
        <button type="button" class="btn-close" data-mdb-dismiss="modal" aria-label="Fechar"></button>
      </div>
      <div class="modal-body">
        <iframe id="mediaVideoIframe" class="media-video-frame" src="" title="YouTube video player" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
        <div id="mediaVideoFallback" class="alert alert-warning mt-3 d-none">
          Nao foi possivel identificar o video do YouTube a partir da URL informada.
        </div>
      </div>
    </div>
  </div>
</div>

<script>
  document.addEventListener('DOMContentLoaded', function () {
    var modalElement = document.getElementById('mediaVideoModal');
    var iframe = document.getElementById('mediaVideoIframe');
    var title = document.getElementById('mediaVideoModalLabel');
    var fallback = document.getElementById('mediaVideoFallback');
    var modal = modalElement && window.mdb ? new mdb.Modal(modalElement) : null;

    function getYouTubeId(value) {
      var source = String(value || '').trim();
      var match;

      if (!source) return '';
      if (/^[A-Za-z0-9_-]{11}$/.test(source)) return source;

      match = source.match(/(?:youtube\.com\/watch\?v=|youtube\.com\/embed\/|youtube\.com\/shorts\/|youtu\.be\/)([A-Za-z0-9_-]{11})/);
      if (match && match[1]) return match[1];

      match = source.match(/[?&]v=([A-Za-z0-9_-]{11})/);
      return match && match[1] ? match[1] : '';
    }

    document.querySelectorAll('.js-media-video').forEach(function (button) {
      button.addEventListener('click', function () {
        var videoId = getYouTubeId(button.getAttribute('data-media-url'));
        var modalTitle = button.getAttribute('data-media-title') || 'Video';

        title.textContent = modalTitle;
        fallback.classList.toggle('d-none', !!videoId);
        iframe.classList.toggle('d-none', !videoId);
        iframe.src = videoId ? 'https://www.youtube.com/embed/' + videoId + '?autoplay=1' : '';

        if (modal) modal.show();
      });
    });

    document.querySelectorAll('.js-media-thumbnail').forEach(function (button) {
      var videoId = getYouTubeId(button.getAttribute('data-media-url'));
      var image = button.querySelector('img');

      if (videoId && image) {
        image.src = 'https://img.youtube.com/vi/' + videoId + '/mqdefault.jpg';
      } else {
        button.classList.add('d-none');
      }
    });

    if (modalElement) {
      modalElement.addEventListener('hidden.mdb.modal', function () {
        iframe.src = '';
      });
    }
  });
</script>
