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
<cfset VARIABLES.mediaTableColspan = 8/>

<style>
  .media-table {
    min-width: 1200px;
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
    min-width: 220px;
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

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Videos</h3>
              <p class="text-muted mb-0">Gerencie os videos importados a partir dos canais de video e a exibicao no portal Road Runners.</p>
            </div>
            <div class="text-lg-end d-flex gap-4">
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
                <div class="small text-muted">Destaques</div>
                <div class="h4 mb-0 text-warning"><cfoutput>#LSNumberFormat(qMediaStats.total_destaques)#</cfoutput></div>
              </div>
            </div>
          </div>

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
                <label class="form-label">Busca</label>
                <input class="form-control" type="text" name="busca" value="<cfoutput>#htmlEditFormat(URL.busca)#</cfoutput>" placeholder="Titulo, canal ou URL"/>
              </div>

              <div>
                <label class="form-label">Status</label>
                <select class="form-select" name="status">
                  <option value="todos" <cfif VARIABLES.mediaStatusFilter EQ "todos">selected</cfif>>Todos</option>
                  <option value="publicados" <cfif VARIABLES.mediaStatusFilter EQ "publicados">selected</cfif>>Publicados</option>
                  <option value="ocultos" <cfif VARIABLES.mediaStatusFilter EQ "ocultos">selected</cfif>>Ocultos</option>
                </select>
              </div>

              <div>
                <label class="form-label">Destaque na home</label>
                <select class="form-select" name="destaque">
                  <option value="todos" <cfif VARIABLES.mediaFeaturedFilter EQ "todos">selected</cfif>>Todos</option>
                  <option value="sim" <cfif VARIABLES.mediaFeaturedFilter EQ "sim">selected</cfif>>Em destaque</option>
                  <option value="nao" <cfif VARIABLES.mediaFeaturedFilter EQ "nao">selected</cfif>>Sem destaque</option>
                </select>
              </div>

              <div>
                <button class="btn btn-outline-warning" type="submit">Filtrar</button>
              </div>
            </form>

            <cfif VARIABLES.mediaHasIsFeatured>
              <cfset VARIABLES.mediaFeaturedCurrentPublished = false/>
              <cfset VARIABLES.mediaFeaturedCurrentEventId = 0/>
              <cfif qMediaFeaturedCurrent.recordcount>
                <cfset VARIABLES.mediaFeaturedCurrentPublished = IsBoolean(qMediaFeaturedCurrent.pub_status) ? qMediaFeaturedCurrent.pub_status : ListFindNoCase("true,1,yes,sim", trim(qMediaFeaturedCurrent.pub_status & "")) GT 0/>
                <cfif VARIABLES.mediaHasEventId AND NOT isNull(qMediaFeaturedCurrent.id_evento) AND isNumeric(qMediaFeaturedCurrent.id_evento)>
                  <cfset VARIABLES.mediaFeaturedCurrentEventId = val(qMediaFeaturedCurrent.id_evento)/>
                </cfif>
              </cfif>

              <cfif URL.sucesso EQ "evento_vinculado">
                <div class="alert alert-success mb-3">Evento vinculado ao video em destaque.</div>
              <cfelseif URL.sucesso EQ "evento_desvinculado">
                <div class="alert alert-success mb-3">Vinculo do evento removido do video em destaque.</div>
              <cfelseif len(VARIABLES.mediaFeaturedEventAlert.message)>
                <cfoutput><div class="alert alert-#htmlEditFormat(VARIABLES.mediaFeaturedEventAlert.type)# mb-3">#htmlEditFormat(VARIABLES.mediaFeaturedEventAlert.message)#</div></cfoutput>
              </cfif>

              <div class="media-featured-card p-3 mb-4" id="video-destaque">
                <cfoutput>
                  <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
                    <div>
                      <div class="small text-warning fw-semibold text-uppercase">Video em destaque na home</div>
                      <cfif qMediaFeaturedCurrent.recordcount>
                        <div class="fw-semibold">
                          <cfif len(trim(qMediaFeaturedCurrent.media_titulo))>#htmlEditFormat(qMediaFeaturedCurrent.media_titulo)#<cfelse>Midia ###htmlEditFormat(qMediaFeaturedCurrent.media_pk)#</cfif>
                        </div>
                        <div class="small text-muted">
                          ID #htmlEditFormat(qMediaFeaturedCurrent.media_pk)# ·
                          <cfif VARIABLES.mediaFeaturedCurrentPublished>Publicado<cfelse>Oculto</cfif>
                        </div>
                      <cfelse>
                        <div class="fw-semibold">Nenhum video destacado no momento.</div>
                        <div class="small text-muted">Use o botao Destacar em um video publicado para definir o destaque da home.</div>
                      </cfif>
                    </div>
                    <div class="d-flex flex-wrap gap-2 align-items-start">
                      <cfif qMediaFeaturedCurrent.recordcount AND len(trim(qMediaFeaturedCurrent.media_url))>
                        <button type="button" class="btn btn-sm btn-outline-secondary js-media-video" data-media-url="#htmlEditFormat(qMediaFeaturedCurrent.media_url)#" data-media-title="#htmlEditFormat(qMediaFeaturedCurrent.media_titulo)#">
                          Ver video
                        </button>
                      </cfif>
                      <a class="btn btn-sm btn-outline-warning" href="./?pagina=1&busca=#urlEncodedFormat(URL.busca)#&status=publicados&destaque=sim">
                        Ver destaque
                      </a>
                    </div>
                  </div>
                </cfoutput>

                <cfif qMediaFeaturedCurrent.recordcount>
                  <div class="media-featured-event-panel mt-3 pt-3">
                    <div class="row g-3">
                      <div class="col-12 col-xl-5">
                        <div class="small text-muted text-uppercase fw-semibold mb-1">Evento vinculado</div>
                        <cfif VARIABLES.mediaHasEventId>
                          <cfoutput>
                            <cfif VARIABLES.mediaFeaturedCurrentEventId GT 0>
                              <div class="fw-semibold">#htmlEditFormat(qMediaFeaturedCurrent.evento_nome)#</div>
                              <div class="small text-muted">
                                ID #VARIABLES.mediaFeaturedCurrentEventId#
                                <cfif isDate(qMediaFeaturedCurrent.evento_data_inicial)> · #lsDateFormat(qMediaFeaturedCurrent.evento_data_inicial, "dd/mm/yyyy")#</cfif>
                                <cfif len(trim(qMediaFeaturedCurrent.evento_cidade & ""))> · #htmlEditFormat(qMediaFeaturedCurrent.evento_cidade)#<cfif len(trim(qMediaFeaturedCurrent.evento_estado & ""))>/#htmlEditFormat(qMediaFeaturedCurrent.evento_estado)#</cfif></cfif>
                              </div>
                              <form method="post" action="./?pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)###video-destaque" class="mt-2" onsubmit="return confirm('Remover o vinculo deste video com o evento?');">
                                <input type="hidden" name="media_featured_event_action" value="salvar"/>
                                <input type="hidden" name="media_id" value="#htmlEditFormat(qMediaFeaturedCurrent.media_pk)#"/>
                                <input type="hidden" name="id_evento" value=""/>
                                <button class="btn btn-sm btn-outline-danger" type="submit">Remover vinculo</button>
                              </form>
                            <cfelse>
                              <div class="fw-semibold">Nenhum evento vinculado.</div>
                              <div class="small text-muted">Busque um evento ao lado para contextualizar o destaque.</div>
                            </cfif>
                          </cfoutput>
                        <cfelse>
                          <div class="alert alert-warning mb-0">
                            A coluna <strong>id_evento</strong> ainda nao existe em <strong>tb_media</strong>. Aplique o SQL desta funcionalidade para habilitar o vinculo.
                          </div>
                        </cfif>
                      </div>

                      <cfif VARIABLES.mediaHasEventId>
                        <div class="col-12 col-xl-7">
                          <cfoutput>
                            <form method="get" action="./##video-destaque" class="row g-2 align-items-end">
                              <input type="hidden" name="pagina" value="#VARIABLES.mediaPage#"/>
                              <input type="hidden" name="busca" value="#htmlEditFormat(URL.busca)#"/>
                              <input type="hidden" name="status" value="#htmlEditFormat(VARIABLES.mediaStatusFilter)#"/>
                              <input type="hidden" name="destaque" value="#htmlEditFormat(VARIABLES.mediaFeaturedFilter)#"/>
                              <div class="col-12 col-md-9">
                                <label class="form-label">Buscar evento</label>
                                <input class="form-control" type="text" name="evento_busca" value="#htmlEditFormat(URL.evento_busca)#" placeholder="Nome, ID, tag ou cidade" required/>
                              </div>
                              <div class="col-12 col-md-3">
                                <button class="btn btn-outline-warning w-100" type="submit">Buscar</button>
                              </div>
                            </form>
                          </cfoutput>

                          <cfif len(trim(URL.evento_busca))>
                            <cfif qMediaFeaturedEventSearch.recordcount>
                              <cfoutput>
                                <form method="post" action="./?pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)###video-destaque" class="mt-3">
                                  <input type="hidden" name="media_featured_event_action" value="salvar"/>
                                  <input type="hidden" name="media_id" value="#htmlEditFormat(qMediaFeaturedCurrent.media_pk)#"/>
                                  <div class="media-event-search-results mb-3">
                                    <cfloop query="qMediaFeaturedEventSearch">
                                      <cfset VARIABLES.mediaEventSearchActive = NOT isNull(qMediaFeaturedEventSearch.ativo) AND (IsBoolean(qMediaFeaturedEventSearch.ativo) ? qMediaFeaturedEventSearch.ativo : ListFindNoCase("true,1,yes,sim", trim(qMediaFeaturedEventSearch.ativo & "")) GT 0)/>
                                      <label class="media-event-search-option">
                                        <input class="form-check-input mt-1" type="radio" name="id_evento" value="#qMediaFeaturedEventSearch.id_evento#" <cfif qMediaFeaturedEventSearch.id_evento EQ VARIABLES.mediaFeaturedCurrentEventId>checked</cfif> required/>
                                        <span>
                                          <span class="fw-semibold d-block">#htmlEditFormat(qMediaFeaturedEventSearch.nome_evento)#</span>
                                          <span class="small text-muted d-block">
                                            ID #qMediaFeaturedEventSearch.id_evento#
                                            <cfif isDate(qMediaFeaturedEventSearch.data_inicial)> · #lsDateFormat(qMediaFeaturedEventSearch.data_inicial, "dd/mm/yyyy")#</cfif>
                                            <cfif len(trim(qMediaFeaturedEventSearch.cidade & ""))> · #htmlEditFormat(qMediaFeaturedEventSearch.cidade)#<cfif len(trim(qMediaFeaturedEventSearch.estado & ""))>/#htmlEditFormat(qMediaFeaturedEventSearch.estado)#</cfif></cfif>
                                          </span>
                                          <span class="small <cfif VARIABLES.mediaEventSearchActive>text-success<cfelse>text-muted</cfif>"><cfif VARIABLES.mediaEventSearchActive>Ativo<cfelse>Inativo</cfif></span>
                                        </span>
                                      </label>
                                    </cfloop>
                                  </div>
                                  <button class="btn btn-warning" type="submit">Vincular evento selecionado</button>
                                </form>
                              </cfoutput>
                            <cfelse>
                              <div class="alert alert-warning mt-3 mb-0">Nenhum evento encontrado para esta busca.</div>
                            </cfif>
                          </cfif>
                        </div>
                      </cfif>
                    </div>
                  </div>
                </cfif>
              </div>
            <cfelse>
              <div class="alert alert-warning mb-4">
                O gerenciamento de destaque ainda nao esta habilitado porque a coluna <strong>is_featured</strong> nao foi localizada em <strong>tb_media</strong>.
              </div>
            </cfif>

            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover media-table">
                <thead>
                  <tr>
                    <th class="media-thumbnail-cell">Thumb</th>
                    <th>ID</th>
                    <th>Titulo</th>
                    <th>Canal</th>
                    <th>Publicacao</th>
                    <th>Duração</th>
                    <th>Status</th>
                    <th class="media-actions-cell">Acoes</th>
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
                            <button type="button" class="media-thumbnail-button js-media-video js-media-thumbnail" data-media-url="#htmlEditFormat(qMedia["media_url"][qMedia.currentRow])#" data-media-title="Midia ###htmlEditFormat(VARIABLES.mediaPkValue)#" aria-label="Abrir video">
                              <img alt="Miniatura do video" loading="lazy"/>
                            </button>
                          <cfelse>
                            <span class="text-muted small">-</span>
                          </cfif>
                        </td>
                        <td class="media-cell">#htmlEditFormat(VARIABLES.mediaPkValue)#</td>
                        <td class="media-cell">
                          <div class="fw-semibold"><cfif len(VARIABLES.mediaTitle)>#htmlEditFormat(VARIABLES.mediaTitle)#<cfelse>Midia ###htmlEditFormat(VARIABLES.mediaPkValue)#</cfif></div>
                        </td>
                        <td class="media-cell">
                          <cfif len(VARIABLES.mediaChannelName)>#htmlEditFormat(VARIABLES.mediaChannelName)#<cfelse><span class="text-muted">-</span></cfif>
                        </td>
                        <td class="media-cell">
                          <cfif isDate(VARIABLES.mediaPublishedAt)>
                            #lsDateFormat(VARIABLES.mediaPublishedAt, "dd/mm/yyyy")#
                            <small class="text-muted d-block">#lsTimeFormat(VARIABLES.mediaPublishedAt, "HH:mm")#</small>
                          <cfelse>
                            <span class="text-muted">-</span>
                          </cfif>
                        </td>
                        <td class="media-cell">
                          <span class="<cfif VARIABLES.mediaDurationSeconds GT 0 AND VARIABLES.mediaDurationSeconds LT VARIABLES.mediaMinimumPublishDurationSeconds>text-danger fw-bold</cfif>">#htmlEditFormat(VARIABLES.mediaDurationFormatted)#</span>
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
                                <a class="btn btn-sm <cfif VARIABLES.mediaIsPublished>btn-outline-danger<cfelse>btn-outline-success</cfif>" href="./?acao=pub_status&media_id=#urlEncodedFormat(VARIABLES.mediaPkValue)#&published=#NOT VARIABLES.mediaIsPublished#&pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#">
                                  <cfif VARIABLES.mediaIsPublished>Ocultar<cfelse>Exibir</cfif>
                                </a>
                              </cfif>
                            </cfif>

                            <cfif VARIABLES.mediaHasIsFeatured>
                              <cfif VARIABLES.mediaCanManageFeatured>
                                <a class="btn btn-sm <cfif VARIABLES.mediaIsFeatured>btn-warning<cfelse>btn-outline-warning</cfif>" href="./?acao=destaque&media_id=#urlEncodedFormat(VARIABLES.mediaPkValue)#&featured=#NOT VARIABLES.mediaIsFeatured#&pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#" title="<cfif VARIABLES.mediaIsFeatured>Remover da home<cfelse>Destacar na home</cfif>">
                                  <i class="fa-<cfif VARIABLES.mediaIsFeatured>solid<cfelse>regular</cfif> fa-star me-1"></i><cfif VARIABLES.mediaIsFeatured>Remover destaque<cfelse>Destacar</cfif>
                                </a>
                              <cfelse>
                                <button class="btn btn-sm btn-outline-secondary" type="button" disabled title="Exiba o video antes de destaca-lo na home">
                                  <i class="fa-regular fa-star me-1"></i>Destacar
                                </button>
                              </cfif>
                            </cfif>

                            <a class="btn btn-sm btn-outline-danger" href="./?acao=excluir&media_id=#urlEncodedFormat(VARIABLES.mediaPkValue)#&pagina=#VARIABLES.mediaPage#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#" onclick="return confirm('Tem certeza que deseja remover este video do banco de dados?');">
                              Remover
                            </a>
                          </div>
                        </td>
                      </tr>
                    </cfoutput>
                  <cfelse>
                    <tr>
                      <td colspan="#VARIABLES.mediaTableColspan#" class="text-center text-muted py-4">Nenhum video encontrado para este recorte.</td>
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
                      <a class="page-link" href="./?pagina=#max(1, VARIABLES.mediaPage - 1)#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#">Anterior</a>
                    </li>
                  </cfoutput>

                  <cfloop from="#max(1, VARIABLES.mediaPage - 3)#" to="#min(VARIABLES.mediaTotalPages, VARIABLES.mediaPage + 3)#" index="mediaPageIndex">
                    <cfoutput>
                      <li class="page-item <cfif mediaPageIndex EQ VARIABLES.mediaPage>active</cfif>">
                        <a class="page-link" href="./?pagina=#mediaPageIndex#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#">#mediaPageIndex#</a>
                      </li>
                    </cfoutput>
                  </cfloop>

                  <cfoutput>
                    <li class="page-item <cfif VARIABLES.mediaPage GTE VARIABLES.mediaTotalPages>disabled</cfif>">
                      <a class="page-link" href="./?pagina=#min(VARIABLES.mediaTotalPages, VARIABLES.mediaPage + 1)#&busca=#urlEncodedFormat(URL.busca)#&status=#urlEncodedFormat(VARIABLES.mediaStatusFilter)#&destaque=#urlEncodedFormat(VARIABLES.mediaFeaturedFilter)#">Proxima</a>
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
