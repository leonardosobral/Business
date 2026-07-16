<cfinclude template="../includes/banner_management_backend.cfm"/>

<cfset VARIABLES.bannerShowForm = qBannerManagementEdit.recordcount OR (isDefined("URL.banner_novo") AND URL.banner_novo) OR (isDefined("FORM.acao") AND FORM.acao EQ "salvar_banner")/>
<cfset VARIABLES.bannerCtrTotal = qBannerManagementStats.total_views GT 0 ? (qBannerManagementStats.total_clicks * 100 / qBannerManagementStats.total_views) : 0/>

<style>
  .portal-banner-thumb {
    width: 132px;
    min-width: 132px;
    border-radius: 0.9rem;
    border: 1px solid rgba(255, 255, 255, 0.08);
    overflow: hidden;
    background: rgba(255, 255, 255, 0.03);
  }

  .portal-banner-thumb img {
    display: block;
    width: 100%;
    height: auto;
  }

  .portal-banner-thumb-set {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
  }

  .portal-banner-thumb-label {
    display: block;
    margin-bottom: 0.25rem;
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--mdb-secondary-color, rgba(255, 255, 255, 0.6));
  }

  .portal-banner-table td,
  .portal-banner-table th {
    vertical-align: middle;
  }

  .portal-banner-code {
    font-size: 0.78rem;
    white-space: pre-wrap;
    word-break: break-word;
  }

  .portal-banner-api-card code {
    font-size: 0.8rem;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-xl-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Banners</h3>
              <p class="text-muted mb-0">Gerencie banners consumidos por Road Runners e outros sites da plataforma via API, com rastreamento de impressoes e cliques.</p>
            </div>
            <div class="text-xl-end">
              <cfif VARIABLES.bannerManagementTablesReady>
                <a class="btn btn-warning" href="./?banner_novo=1">Novo banner</a>
              </cfif>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para gerenciar banners do Portal.
            </div>
          <cfelseif NOT VARIABLES.bannerManagementTablesReady>
            <div class="alert alert-warning mb-0">
              As tabelas do gerenciador de banners ainda nao existem. Rode o script em
              <a href="/portal/banners/portal_banner_schema.sql" target="_blank" rel="noopener">/portal/banners/portal_banner_schema.sql</a>
              e recarregue esta pagina.
            </div>
          <cfelseif NOT VARIABLES.bannerManagementResponsiveReady>
            <div class="alert alert-warning mb-0">
              A estrutura responsiva dos banners ainda nao existe. Rode novamente
              <a href="/portal/banners/portal_banner_schema.sql" target="_blank" rel="noopener">/portal/banners/portal_banner_schema.sql</a>
              para adicionar os arquivos desktop e mobile.
            </div>
          <cfelse>
            <cfif len(trim(VARIABLES.bannerManagementAlert.type)) AND len(trim(VARIABLES.bannerManagementAlert.message))>
              <cfoutput><div class="alert alert-#VARIABLES.bannerManagementAlert.type#">#htmlEditFormat(VARIABLES.bannerManagementAlert.message)#</div></cfoutput>
            </cfif>

            <div class="row gx-xl-3 mb-4">
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Banners</div>
                    <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qBannerManagementStats.total_banners)#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Ativos</div>
                    <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qBannerManagementStats.total_ativos)#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Impressoes</div>
                    <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qBannerManagementStats.total_views, "9,999,999")#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl mb-3 mb-xl-0">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">Cliques</div>
                    <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qBannerManagementStats.total_clicks, "9,999,999")#</cfoutput></div>
                  </div>
                </div>
              </div>
              <div class="col-sm-6 col-xl">
                <div class="card shadow-0">
                  <div class="card-body p-3">
                    <div class="small text-muted text-uppercase fw-semibold mb-1">CTR</div>
                    <div class="h4 mb-0"><cfoutput>#LSNumberFormat(VARIABLES.bannerCtrTotal, "9.99")#%</cfoutput></div>
                  </div>
                </div>
              </div>
            </div>

            <cfif VARIABLES.bannerShowForm>
              <cfset VARIABLES.bannerFormRow = qBannerManagementEdit.recordcount ? qBannerManagementEdit.currentRow : 0/>
              <cfset VARIABLES.bannerFormRecordId = qBannerManagementEdit.recordcount ? qBannerManagementEdit.id_banner[1] : (isDefined("FORM.banner_id") ? trim(FORM.banner_id & "") : "")/>
              <cfset VARIABLES.bannerFormCanal = qBannerManagementEdit.recordcount ? qBannerManagementEdit.canal[1] : (isDefined("FORM.banner_canal") ? FORM.banner_canal : "")/>
              <cfset VARIABLES.bannerFormLocalLayout = qBannerManagementEdit.recordcount ? qBannerManagementEdit.local_layout[1] : (isDefined("FORM.banner_local_layout") ? FORM.banner_local_layout : "")/>
              <cfset VARIABLES.bannerFormDesktopPath = isDefined("FORM.banner_arquivo_desktop_atual") ? trim(FORM.banner_arquivo_desktop_atual & "") : ""/>
              <cfset VARIABLES.bannerFormDesktopOriginal = isDefined("FORM.banner_arquivo_desktop_original_atual") ? trim(FORM.banner_arquivo_desktop_original_atual & "") : ""/>
              <cfset VARIABLES.bannerFormDesktopFormat = isDefined("FORM.banner_formato_desktop_atual") ? trim(FORM.banner_formato_desktop_atual & "") : ""/>
              <cfset VARIABLES.bannerFormMobilePath = isDefined("FORM.banner_arquivo_mobile_atual") ? trim(FORM.banner_arquivo_mobile_atual & "") : ""/>
              <cfset VARIABLES.bannerFormMobileOriginal = isDefined("FORM.banner_arquivo_mobile_original_atual") ? trim(FORM.banner_arquivo_mobile_original_atual & "") : ""/>
              <cfset VARIABLES.bannerFormMobileFormat = isDefined("FORM.banner_formato_mobile_atual") ? trim(FORM.banner_formato_mobile_atual & "") : ""/>
              <cfif qBannerManagementEdit.recordcount>
                <cfif NOT isNull(qBannerManagementEdit.arquivo_path)>
                  <cfset VARIABLES.bannerFormDesktopPath = trim(qBannerManagementEdit.arquivo_path & "")/>
                </cfif>
                <cfif NOT isNull(qBannerManagementEdit.arquivo_original)>
                  <cfset VARIABLES.bannerFormDesktopOriginal = trim(qBannerManagementEdit.arquivo_original & "")/>
                </cfif>
                <cfif NOT isNull(qBannerManagementEdit.formato)>
                  <cfset VARIABLES.bannerFormDesktopFormat = trim(qBannerManagementEdit.formato & "")/>
                </cfif>
                <cfif NOT isNull(qBannerManagementEdit.arquivo_mobile_path)>
                  <cfset VARIABLES.bannerFormMobilePath = trim(qBannerManagementEdit.arquivo_mobile_path & "")/>
                </cfif>
                <cfif NOT isNull(qBannerManagementEdit.arquivo_mobile_original)>
                  <cfset VARIABLES.bannerFormMobileOriginal = trim(qBannerManagementEdit.arquivo_mobile_original & "")/>
                </cfif>
                <cfif NOT isNull(qBannerManagementEdit.formato_mobile)>
                  <cfset VARIABLES.bannerFormMobileFormat = trim(qBannerManagementEdit.formato_mobile & "")/>
                </cfif>
              </cfif>
              <div class="card shadow-0 border border-white border-opacity-10 mb-4">
                <div class="card-body">
                  <div class="d-flex justify-content-between align-items-start gap-3">
                    <div>
                      <h5 class="mb-1"><cfif len(VARIABLES.bannerFormRecordId)>Editar banner<cfelse>Novo banner</cfif></h5>
                      <p class="text-muted mb-0">Cadastre a peca, defina o slot de exibicao e deixe a API entregar a melhor opcao disponivel para cada consumo.</p>
                    </div>
                    <a class="btn btn-sm btn-outline-light" href="./">Fechar</a>
                  </div>

                  <hr/>

                  <form action="./" method="post" enctype="multipart/form-data">
                    <input type="hidden" name="acao" value="salvar_banner"/>
                    <input type="hidden" name="banner_id" value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormRecordId)#</cfoutput>"/>
                    <input type="hidden" name="banner_arquivo_desktop_atual" value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormDesktopPath)#</cfoutput>"/>
                    <input type="hidden" name="banner_arquivo_desktop_original_atual" value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormDesktopOriginal)#</cfoutput>"/>
                    <input type="hidden" name="banner_formato_desktop_atual" value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormDesktopFormat)#</cfoutput>"/>
                    <input type="hidden" name="banner_arquivo_mobile_atual" value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormMobilePath)#</cfoutput>"/>
                    <input type="hidden" name="banner_arquivo_mobile_original_atual" value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormMobileOriginal)#</cfoutput>"/>
                    <input type="hidden" name="banner_formato_mobile_atual" value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormMobileFormat)#</cfoutput>"/>

                    <div class="row g-3">
                      <div class="col-md-6">
                        <label class="form-label">Nome interno</label>
                        <input type="text" class="form-control" name="banner_nome" required value="<cfif qBannerManagementEdit.recordcount><cfoutput>#htmlEditFormat(qBannerManagementEdit.nome)#</cfoutput><cfelseif isDefined('FORM.banner_nome')><cfoutput>#htmlEditFormat(FORM.banner_nome)#</cfoutput></cfif>"/>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Canal</label>
                        <input type="text" class="form-control" name="banner_canal" placeholder="roadrunners" required value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormCanal)#</cfoutput>"/>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Local no layout</label>
                        <input type="text" class="form-control" name="banner_local_layout" placeholder="home-side-banner" required value="<cfoutput>#htmlEditFormat(VARIABLES.bannerFormLocalLayout)#</cfoutput>"/>
                      </div>

                      <div class="col-12">
                        <hr class="my-1"/>
                        <div class="fw-semibold">Pecas responsivas</div>
                        <div class="small text-muted">Desktop e mobile sao obrigatorios. Na edicao, o arquivo atual pode ser mantido.</div>
                      </div>

                      <div class="col-md-6">
                        <label class="form-label">Arquivo do banner - desktop *</label>
                        <input type="file" class="form-control" name="banner_arquivo_desktop" accept=".jpg,.jpeg,.png,.gif"<cfif NOT len(VARIABLES.bannerFormDesktopPath)> required</cfif>/>
                        <div class="form-text">Aceita JPG, PNG ou GIF.</div>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Largura desktop</label>
                        <input type="number" min="1" class="form-control" name="banner_largura" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.largura#</cfoutput><cfelseif isDefined('FORM.banner_largura')><cfoutput>#FORM.banner_largura#</cfoutput></cfif>"/>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Altura desktop</label>
                        <input type="number" min="1" class="form-control" name="banner_altura" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.altura#</cfoutput><cfelseif isDefined('FORM.banner_altura')><cfoutput>#FORM.banner_altura#</cfoutput></cfif>"/>
                      </div>

                      <div class="col-md-6">
                        <label class="form-label">Arquivo do banner - mobile *</label>
                        <input type="file" class="form-control" name="banner_arquivo_mobile" accept=".jpg,.jpeg,.png,.gif"<cfif NOT len(VARIABLES.bannerFormMobilePath)> required</cfif>/>
                        <div class="form-text">Aceita JPG, PNG ou GIF.</div>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Largura mobile</label>
                        <input type="number" min="1" class="form-control" name="banner_mobile_largura" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.largura_mobile#</cfoutput><cfelseif isDefined('FORM.banner_mobile_largura')><cfoutput>#FORM.banner_mobile_largura#</cfoutput></cfif>"/>
                      </div>
                      <div class="col-md-3">
                        <label class="form-label">Altura mobile</label>
                        <input type="number" min="1" class="form-control" name="banner_mobile_altura" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.altura_mobile#</cfoutput><cfelseif isDefined('FORM.banner_mobile_altura')><cfoutput>#FORM.banner_mobile_altura#</cfoutput></cfif>"/>
                      </div>

                      <div class="col-md-4">
                        <label class="form-label">Tamanho nomeado</label>
                        <input type="text" class="form-control" name="banner_tamanho_nome" placeholder="sidebar-300x250" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#htmlEditFormat(qBannerManagementEdit.tamanho_nome)#</cfoutput><cfelseif isDefined('FORM.banner_tamanho_nome')><cfoutput>#htmlEditFormat(FORM.banner_tamanho_nome)#</cfoutput></cfif>"/>
                      </div>

                      <div class="col-md-8">
                        <label class="form-label">Link de destino</label>
                        <input type="text" class="form-control" name="banner_link_destino" placeholder="/desafio/todosantodia/ ou https://exemplo.com" required value="<cfif qBannerManagementEdit.recordcount><cfoutput>#htmlEditFormat(qBannerManagementEdit.link_destino)#</cfoutput><cfelseif isDefined('FORM.banner_link_destino')><cfoutput>#htmlEditFormat(FORM.banner_link_destino)#</cfoutput></cfif>"/>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label">Tipo de link</label>
                        <select class="form-select" name="banner_link_tipo">
                          <cfset VARIABLES.bannerCurrentLinkType = qBannerManagementEdit.recordcount ? qBannerManagementEdit.link_tipo[1] : (isDefined("FORM.banner_link_tipo") ? FORM.banner_link_tipo : "interno")/>
                          <option value="interno"<cfif VARIABLES.bannerCurrentLinkType EQ "interno"> selected</cfif>>Interno</option>
                          <option value="externo"<cfif VARIABLES.bannerCurrentLinkType EQ "externo"> selected</cfif>>Externo</option>
                        </select>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label">Abrir</label>
                        <select class="form-select" name="banner_abrir_nova_aba">
                          <cfset VARIABLES.bannerCurrentTarget = qBannerManagementEdit.recordcount ? (IsBoolean(qBannerManagementEdit.abrir_nova_aba[1]) ? qBannerManagementEdit.abrir_nova_aba[1] : ListFindNoCase("1,true,yes,on", trim(qBannerManagementEdit.abrir_nova_aba[1])) GT 0) : (isDefined("FORM.banner_abrir_nova_aba") AND ListFindNoCase("1,true,yes,on", trim(FORM.banner_abrir_nova_aba)) GT 0)/>
                          <option value="0"<cfif NOT VARIABLES.bannerCurrentTarget> selected</cfif>>Mesma janela</option>
                          <option value="1"<cfif VARIABLES.bannerCurrentTarget> selected</cfif>>Nova aba</option>
                        </select>
                      </div>

                      <div class="col-md-4">
                        <label class="form-label">Alt text</label>
                        <input type="text" class="form-control" name="banner_alt_text" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#htmlEditFormat(qBannerManagementEdit.alt_text)#</cfoutput><cfelseif isDefined('FORM.banner_alt_text')><cfoutput>#htmlEditFormat(FORM.banner_alt_text)#</cfoutput></cfif>"/>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label">Peso de exibicao</label>
                        <input type="number" min="1" class="form-control" name="banner_peso_exibicao" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.peso_exibicao#</cfoutput><cfelseif isDefined('FORM.banner_peso_exibicao')><cfoutput>#FORM.banner_peso_exibicao#</cfoutput><cfelse>1</cfif>"/>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label">Prioridade</label>
                        <input type="number" min="1" class="form-control" name="banner_prioridade" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.prioridade#</cfoutput><cfelseif isDefined('FORM.banner_prioridade')><cfoutput>#FORM.banner_prioridade#</cfoutput><cfelse>1</cfif>"/>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label">Status</label>
                        <cfset VARIABLES.bannerCurrentStatus = qBannerManagementEdit.recordcount ? qBannerManagementEdit.status[1] : (isDefined("FORM.banner_status") ? FORM.banner_status : 2)/>
                        <select class="form-select" name="banner_status">
                          <option value="1"<cfif val(VARIABLES.bannerCurrentStatus) EQ 1> selected</cfif>>Rascunho</option>
                          <option value="2"<cfif val(VARIABLES.bannerCurrentStatus) EQ 2> selected</cfif>>Ativo</option>
                          <option value="3"<cfif val(VARIABLES.bannerCurrentStatus) EQ 3> selected</cfif>>Pausado</option>
                          <option value="4"<cfif val(VARIABLES.bannerCurrentStatus) EQ 4> selected</cfif>>Arquivado</option>
                        </select>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label">Limite diario</label>
                        <input type="number" min="1" class="form-control" name="banner_limite_diario" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.limite_diario#</cfoutput><cfelseif isDefined('FORM.banner_limite_diario')><cfoutput>#FORM.banner_limite_diario#</cfoutput></cfif>"/>
                      </div>

                      <div class="col-md-4">
                        <label class="form-label">Inicio de exibicao</label>
                        <input type="datetime-local" class="form-control" name="banner_inicio_exibicao" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#dateFormat(qBannerManagementEdit.inicio_exibicao, 'yyyy-mm-dd')#T#timeFormat(qBannerManagementEdit.inicio_exibicao, 'HH:nn')#</cfoutput><cfelseif isDefined('FORM.banner_inicio_exibicao')><cfoutput>#FORM.banner_inicio_exibicao#</cfoutput></cfif>"/>
                      </div>
                      <div class="col-md-4">
                        <label class="form-label">Fim de exibicao</label>
                        <input type="datetime-local" class="form-control" name="banner_fim_exibicao" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#dateFormat(qBannerManagementEdit.fim_exibicao, 'yyyy-mm-dd')#T#timeFormat(qBannerManagementEdit.fim_exibicao, 'HH:nn')#</cfoutput><cfelseif isDefined('FORM.banner_fim_exibicao')><cfoutput>#FORM.banner_fim_exibicao#</cfoutput></cfif>"/>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label">Limite de impressoes</label>
                        <input type="number" min="1" class="form-control" name="banner_limite_impressoes" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.limite_impressoes#</cfoutput><cfelseif isDefined('FORM.banner_limite_impressoes')><cfoutput>#FORM.banner_limite_impressoes#</cfoutput></cfif>"/>
                      </div>
                      <div class="col-md-2">
                        <label class="form-label">Limite de cliques</label>
                        <input type="number" min="1" class="form-control" name="banner_limite_cliques" value="<cfif qBannerManagementEdit.recordcount><cfoutput>#qBannerManagementEdit.limite_cliques#</cfoutput><cfelseif isDefined('FORM.banner_limite_cliques')><cfoutput>#FORM.banner_limite_cliques#</cfoutput></cfif>"/>
                      </div>

                      <div class="col-12">
                        <label class="form-label">Observacoes</label>
                        <textarea class="form-control" rows="3" name="banner_observacoes"><cfif qBannerManagementEdit.recordcount><cfoutput>#htmlEditFormat(qBannerManagementEdit.observacoes)#</cfoutput><cfelseif isDefined("FORM.banner_observacoes")><cfoutput>#htmlEditFormat(FORM.banner_observacoes)#</cfoutput></cfif></textarea>
                      </div>

                      <cfif qBannerManagementEdit.recordcount>
                        <div class="col-12">
                          <div class="portal-banner-thumb-set">
                            <cfif len(VARIABLES.bannerFormDesktopPath)>
                              <div>
                                <span class="portal-banner-thumb-label">Desktop atual</span>
                                <div class="portal-banner-thumb">
                                  <img src="<cfoutput>#bannerManagementBuildAssetUrl(VARIABLES.bannerFormDesktopPath)#</cfoutput>" alt="Preview desktop do banner"/>
                                </div>
                              </div>
                            </cfif>
                            <cfif len(VARIABLES.bannerFormMobilePath)>
                              <div>
                                <span class="portal-banner-thumb-label">Mobile atual</span>
                                <div class="portal-banner-thumb">
                                  <img src="<cfoutput>#bannerManagementBuildAssetUrl(VARIABLES.bannerFormMobilePath)#</cfoutput>" alt="Preview mobile do banner"/>
                                </div>
                              </div>
                            </cfif>
                          </div>
                        </div>
                      </cfif>
                    </div>

                    <div class="mt-4 d-flex gap-2">
                      <button type="submit" class="btn btn-warning"><cfif len(VARIABLES.bannerFormRecordId)>Salvar alteracoes<cfelse>Cadastrar banner</cfif></button>
                      <a class="btn btn-outline-light" href="./">Cancelar</a>
                    </div>
                  </form>
                </div>
              </div>
            </cfif>

            <div class="card shadow-0 border border-white border-opacity-10 mb-4 portal-banner-api-card">
              <div class="card-body">
                <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
                  <div>
                    <h5 class="mb-1">Consumo via API</h5>
                    <p class="text-muted mb-0">A API entrega um banner elegivel por canal e posicao, ja com URL de clique rastreavel e metadados para renderizacao.</p>
                  </div>
                  <div class="small text-muted text-lg-end">
                    Endpoint base
                    <div><code><cfoutput>#VARIABLES.bannerPublicBaseUrl#/api/portal/banners/</cfoutput></code></div>
                  </div>
                </div>
                <hr/>
                <div class="row g-3">
                  <div class="col-lg-6">
                    <div class="small text-muted mb-1">Exemplo de consulta JSON</div>
                    <div class="bg-black bg-opacity-25 rounded p-3 portal-banner-code"><code><cfoutput>#VARIABLES.bannerPublicBaseUrl#/api/portal/banners/?canal=roadrunners&local=home-side-banner&tamanho=sidebar-300x250&site_url=https://beta.roadrunners.run</cfoutput></code></div>
                  </div>
                  <div class="col-lg-6">
                    <div class="small text-muted mb-1">Campos principais retornados</div>
                    <div class="bg-black bg-opacity-25 rounded p-3 portal-banner-code"><code>banner.images.desktop.imageUrl, banner.images.mobile.imageUrl, banner.clickUrl, banner.target, banner.alt, banner.linkType</code></div>
                  </div>
                </div>
              </div>
            </div>

            <div class="card shadow-0 border border-white border-opacity-10 mb-4">
              <div class="card-body">
                <form action="./" method="get" class="row g-3 align-items-end">
                  <div class="col-md-4">
                    <label class="form-label">Canal</label>
                    <select class="form-select" name="filtro_canal">
                      <option value="">Todos</option>
                      <cfoutput query="qBannerManagementChannels">
                        <option value="#htmlEditFormat(qBannerManagementChannels.canal)#"<cfif URL.filtro_canal EQ qBannerManagementChannels.canal> selected</cfif>>#htmlEditFormat(qBannerManagementChannels.canal)#</option>
                      </cfoutput>
                    </select>
                  </div>
                  <div class="col-md-4">
                    <label class="form-label">Local do layout</label>
                    <select class="form-select" name="filtro_local">
                      <option value="">Todos</option>
                      <cfoutput query="qBannerManagementSlots">
                        <option value="#htmlEditFormat(qBannerManagementSlots.local_layout)#"<cfif URL.filtro_local EQ qBannerManagementSlots.local_layout> selected</cfif>>#htmlEditFormat(qBannerManagementSlots.local_layout)#</option>
                      </cfoutput>
                    </select>
                  </div>
                  <div class="col-md-2">
                    <label class="form-label">Status</label>
                    <select class="form-select" name="filtro_status">
                      <option value="">Todos</option>
                      <option value="1"<cfif URL.filtro_status EQ "1"> selected</cfif>>Rascunho</option>
                      <option value="2"<cfif URL.filtro_status EQ "2"> selected</cfif>>Ativo</option>
                      <option value="3"<cfif URL.filtro_status EQ "3"> selected</cfif>>Pausado</option>
                      <option value="4"<cfif URL.filtro_status EQ "4"> selected</cfif>>Arquivado</option>
                    </select>
                  </div>
                  <div class="col-md-2">
                    <button type="submit" class="btn btn-outline-light w-100">Filtrar</button>
                  </div>
                </form>
              </div>
            </div>

            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover portal-banner-table">
                <thead>
                  <tr>
                    <th>Banner</th>
                    <th>Contexto</th>
                    <th>Link</th>
                    <th>Janela</th>
                    <th>Status</th>
                    <th class="text-end">Views</th>
                    <th class="text-end">Clicks</th>
                    <th class="text-end">CTR</th>
                    <th>Acoes</th>
                  </tr>
                </thead>
                <tbody>
                  <cfif qBannerManagementList.recordcount>
                    <cfoutput query="qBannerManagementList">
                      <cfset VARIABLES.bannerRowCtr = qBannerManagementList.views GT 0 ? (qBannerManagementList.clicks * 100 / qBannerManagementList.views) : 0/>
                      <tr>
                        <td>
                          <div class="d-flex align-items-start gap-3">
                            <div class="portal-banner-thumb-set">
                              <div>
                                <span class="portal-banner-thumb-label">Desktop</span>
                                <div class="portal-banner-thumb">
                                  <img src="#bannerManagementBuildAssetUrl(qBannerManagementList.arquivo_path)#" alt="#htmlEditFormat(qBannerManagementList.nome)# desktop"/>
                                </div>
                              </div>
                              <div>
                                <span class="portal-banner-thumb-label">Mobile</span>
                                <div class="portal-banner-thumb">
                                  <img src="#bannerManagementBuildAssetUrl(qBannerManagementList.arquivo_mobile_path)#" alt="#htmlEditFormat(qBannerManagementList.nome)# mobile"/>
                                </div>
                              </div>
                            </div>
                            <div>
                              <div class="fw-semibold">#htmlEditFormat(qBannerManagementList.nome)#</div>
                              <div class="small text-muted">ID #qBannerManagementList.id_banner#</div>
                              <cfif len(trim(qBannerManagementList.tamanho_nome)) OR (len(trim(qBannerManagementList.largura)) AND len(trim(qBannerManagementList.altura)))>
                                <div class="small text-muted">
                                  <cfif len(trim(qBannerManagementList.tamanho_nome))>#htmlEditFormat(qBannerManagementList.tamanho_nome)#</cfif>
                                  <cfif len(trim(qBannerManagementList.largura)) AND len(trim(qBannerManagementList.altura))>
                                    <cfif len(trim(qBannerManagementList.tamanho_nome))> · </cfif>Desktop #qBannerManagementList.largura#x#qBannerManagementList.altura#
                                  </cfif>
                                </div>
                              </cfif>
                              <cfif len(trim(qBannerManagementList.largura_mobile)) AND len(trim(qBannerManagementList.altura_mobile))>
                                <div class="small text-muted">Mobile #qBannerManagementList.largura_mobile#x#qBannerManagementList.altura_mobile#</div>
                              </cfif>
                              <div class="small text-muted">Peso #qBannerManagementList.peso_exibicao# · Prioridade #qBannerManagementList.prioridade#</div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <div class="fw-semibold">#htmlEditFormat(qBannerManagementList.canal)#</div>
                          <div class="small text-muted">#htmlEditFormat(qBannerManagementList.local_layout)#</div>
                          <cfif isDate(qBannerManagementList.inicio_exibicao) OR isDate(qBannerManagementList.fim_exibicao)>
                            <div class="small text-muted mt-1">
                              <cfif isDate(qBannerManagementList.inicio_exibicao)>#LSDateFormat(qBannerManagementList.inicio_exibicao, "dd/mm/yyyy")# #LSTimeFormat(qBannerManagementList.inicio_exibicao, "HH:nn")#</cfif>
                              <cfif isDate(qBannerManagementList.fim_exibicao)>
                                <cfif isDate(qBannerManagementList.inicio_exibicao)> ate </cfif>#LSDateFormat(qBannerManagementList.fim_exibicao, "dd/mm/yyyy")# #LSTimeFormat(qBannerManagementList.fim_exibicao, "HH:nn")#
                              </cfif>
                            </div>
                          </cfif>
                        </td>
                        <td>
                          <div class="small fw-semibold text-uppercase">#htmlEditFormat(qBannerManagementList.link_tipo)#</div>
                          <div class="small text-muted" style="max-width: 260px; overflow-wrap: anywhere;">#htmlEditFormat(qBannerManagementList.link_destino)#</div>
                        </td>
                        <td><span class="badge badge-secondary">#bannerManagementTargetLabel(qBannerManagementList.abrir_nova_aba)#</span></td>
                        <td>
                          <span class="badge <cfif qBannerManagementList.status EQ 2>badge-success<cfelseif qBannerManagementList.status EQ 3>badge-warning text-dark<cfelseif qBannerManagementList.status EQ 4>badge-dark<cfelse>badge-secondary</cfif>">
                            #bannerManagementStatusLabel(qBannerManagementList.status)#
                          </span>
                        </td>
                        <td class="text-end">#LSNumberFormat(qBannerManagementList.views, "9,999,999")#</td>
                        <td class="text-end">#LSNumberFormat(qBannerManagementList.clicks, "9,999,999")#</td>
                        <td class="text-end">#LSNumberFormat(VARIABLES.bannerRowCtr, "9.99")#%</td>
                        <td>
                          <div class="d-flex flex-wrap gap-2">
                            <a class="btn btn-sm btn-outline-primary" href="./?banner_editar=#qBannerManagementList.id_banner#">Editar</a>
                            <cfif qBannerManagementList.status EQ 2>
                              <a class="btn btn-sm btn-outline-warning" href="./?acao=status&banner_id=#qBannerManagementList.id_banner#&status=3">Pausar</a>
                            <cfelse>
                              <a class="btn btn-sm btn-outline-success" href="./?acao=status&banner_id=#qBannerManagementList.id_banner#&status=2">Ativar</a>
                            </cfif>
                            <a class="btn btn-sm btn-outline-dark" href="./?acao=status&banner_id=#qBannerManagementList.id_banner#&status=4">Arquivar</a>
                            <a class="btn btn-sm btn-outline-danger" href="./?acao=excluir&banner_id=#qBannerManagementList.id_banner#" onclick="return confirm('Tem certeza que deseja excluir este banner?');">Excluir</a>
                          </div>
                        </td>
                      </tr>
                    </cfoutput>
                  <cfelse>
                    <tr>
                      <td colspan="9" class="text-center text-muted py-4">Nenhum banner encontrado com os filtros atuais.</td>
                    </tr>
                  </cfif>
                </tbody>
              </table>
            </div>
          </cfif>
        </div>
      </div>
    </div>
  </div>
</section>
