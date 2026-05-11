<cfinclude template="../includes/content_channels_backend.cfm"/>

<style>
  .content-channel-table td,
  .content-channel-table th {
    vertical-align: middle;
  }

  .content-channel-cell {
    max-width: 320px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .content-channel-actions {
    min-width: 210px;
  }

  .content-channel-toggle-group {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
  }
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Canais de Conteúdo</h3>
              <p class="text-muted mb-0">Controle quais canais editoriais do repositório News podem aparecer no Road Runners e nos destaques principais.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Total de canais</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qContentChannelsCount.total)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o controle de canais de conteudo do Portal.
            </div>
          <cfelseif NOT qContentChannelColumns.recordcount>
            <div class="alert alert-danger mb-0">
              Nao foi possivel localizar a tabela <strong>news.tb_content_types</strong>.
            </div>
          <cfelse>
            <cfif NOT VARIABLES.contentChannelAllFlagsReady>
              <div class="alert alert-warning">
                Os campos de governanca do Road Runners ainda nao existem em <strong>news.tb_content_types</strong>.
                Rode o script em <a href="/portal/conteudo-canais/news_tb_content_types_portal_flags.sql" target="_blank" rel="noopener">/portal/conteudo-canais/news_tb_content_types_portal_flags.sql</a> e recarregue esta pagina.
              </div>
            </cfif>

            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover content-channel-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Canal</th>
                    <th>Slug</th>
                    <th>Site</th>
                    <th>Portal RR</th>
                    <th>Destaque Home</th>
                    <th>Destaque Noticias</th>
                    <th class="content-channel-actions">Acoes</th>
                  </tr>
                </thead>
                <tbody>
                  <cfif qContentChannels.recordcount>
                    <cfoutput query="qContentChannels">
                      <cfset VARIABLES.contentChannelPkValue = qContentChannels[VARIABLES.contentChannelPk][qContentChannels.currentRow]/>
                      <cfset VARIABLES.contentChannelPortalEnabled = qContentChannels[VARIABLES.contentChannelPortalColumn][qContentChannels.currentRow]/>
                      <cfset VARIABLES.contentChannelPortalEnabled = IsBoolean(VARIABLES.contentChannelPortalEnabled) ? VARIABLES.contentChannelPortalEnabled : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.contentChannelPortalEnabled))/>
                      <cfset VARIABLES.contentChannelHomeFeaturedEnabled = qContentChannels[VARIABLES.contentChannelHomeFeaturedColumn][qContentChannels.currentRow]/>
                      <cfset VARIABLES.contentChannelHomeFeaturedEnabled = IsBoolean(VARIABLES.contentChannelHomeFeaturedEnabled) ? VARIABLES.contentChannelHomeFeaturedEnabled : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.contentChannelHomeFeaturedEnabled))/>
                      <cfset VARIABLES.contentChannelNewsFeaturedEnabled = qContentChannels[VARIABLES.contentChannelNewsFeaturedColumn][qContentChannels.currentRow]/>
                      <cfset VARIABLES.contentChannelNewsFeaturedEnabled = IsBoolean(VARIABLES.contentChannelNewsFeaturedEnabled) ? VARIABLES.contentChannelNewsFeaturedEnabled : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.contentChannelNewsFeaturedEnabled))/>
                      <tr>
                        <td>#htmlEditFormat(VARIABLES.contentChannelPkValue)#</td>
                        <td class="content-channel-cell">
                          <strong>#htmlEditFormat(qContentChannels.name)#</strong>
                        </td>
                        <td class="content-channel-cell">#htmlEditFormat(qContentChannels.slug)#</td>
                        <td class="content-channel-cell">
                          <cfif len(trim(qContentChannels.website_url))>
                            <a href="#htmlEditFormat(qContentChannels.website_url)#" target="_blank" rel="noopener">#htmlEditFormat(qContentChannels.website_url)#</a>
                          <cfelse>
                            <span class="text-muted">-</span>
                          </cfif>
                        </td>
                        <td>
                          <cfif VARIABLES.contentChannelHasPortalColumn>
                            <span class="badge <cfif VARIABLES.contentChannelPortalEnabled>badge-success<cfelse>badge-danger</cfif>">
                              <cfif VARIABLES.contentChannelPortalEnabled>Ativo<cfelse>Inativo</cfif>
                            </span>
                          <cfelse>
                            <span class="badge badge-secondary">Indisponivel</span>
                          </cfif>
                        </td>
                        <td>
                          <cfif VARIABLES.contentChannelHasHomeFeaturedColumn>
                            <span class="badge <cfif VARIABLES.contentChannelHomeFeaturedEnabled>badge-success<cfelse>badge-secondary</cfif>">
                              <cfif VARIABLES.contentChannelHomeFeaturedEnabled>Ligado<cfelse>Desligado</cfif>
                            </span>
                          <cfelse>
                            <span class="badge badge-secondary">Indisponivel</span>
                          </cfif>
                        </td>
                        <td>
                          <cfif VARIABLES.contentChannelHasNewsFeaturedColumn>
                            <span class="badge <cfif VARIABLES.contentChannelNewsFeaturedEnabled>badge-success<cfelse>badge-secondary</cfif>">
                              <cfif VARIABLES.contentChannelNewsFeaturedEnabled>Ligado<cfelse>Desligado</cfif>
                            </span>
                          <cfelse>
                            <span class="badge badge-secondary">Indisponivel</span>
                          </cfif>
                        </td>
                        <td class="content-channel-actions">
                          <div class="content-channel-toggle-group">
                            <cfif VARIABLES.contentChannelHasPortalColumn>
                              <a class="btn btn-sm <cfif VARIABLES.contentChannelPortalEnabled>btn-outline-danger<cfelse>btn-outline-success</cfif>" href="./?acao=toggle&campo=#urlEncodedFormat(VARIABLES.contentChannelPortalColumn)#&status=#NOT VARIABLES.contentChannelPortalEnabled#&canal_id=#urlEncodedFormat(VARIABLES.contentChannelPkValue)#&pagina=#VARIABLES.contentChannelPage#">
                                <cfif VARIABLES.contentChannelPortalEnabled>Ocultar no Portal<cfelse>Exibir no Portal</cfif>
                              </a>
                            </cfif>
                            <cfif VARIABLES.contentChannelHasHomeFeaturedColumn>
                              <a class="btn btn-sm <cfif VARIABLES.contentChannelHomeFeaturedEnabled>btn-outline-danger<cfelse>btn-outline-success</cfif>" href="./?acao=toggle&campo=#urlEncodedFormat(VARIABLES.contentChannelHomeFeaturedColumn)#&status=#NOT VARIABLES.contentChannelHomeFeaturedEnabled#&canal_id=#urlEncodedFormat(VARIABLES.contentChannelPkValue)#&pagina=#VARIABLES.contentChannelPage#">
                                <cfif VARIABLES.contentChannelHomeFeaturedEnabled>Remover da Home<cfelse>Destacar na Home</cfif>
                              </a>
                            </cfif>
                            <cfif VARIABLES.contentChannelHasNewsFeaturedColumn>
                              <a class="btn btn-sm <cfif VARIABLES.contentChannelNewsFeaturedEnabled>btn-outline-danger<cfelse>btn-outline-success</cfif>" href="./?acao=toggle&campo=#urlEncodedFormat(VARIABLES.contentChannelNewsFeaturedColumn)#&status=#NOT VARIABLES.contentChannelNewsFeaturedEnabled#&canal_id=#urlEncodedFormat(VARIABLES.contentChannelPkValue)#&pagina=#VARIABLES.contentChannelPage#">
                                <cfif VARIABLES.contentChannelNewsFeaturedEnabled>Remover de Noticias<cfelse>Destacar em Noticias</cfif>
                              </a>
                            </cfif>
                            <cfif NOT VARIABLES.contentChannelHasPortalColumn AND NOT VARIABLES.contentChannelHasHomeFeaturedColumn AND NOT VARIABLES.contentChannelHasNewsFeaturedColumn>
                              <span class="text-muted small">Aplique o SQL auxiliar para habilitar os controles.</span>
                            </cfif>
                          </div>
                        </td>
                      </tr>
                    </cfoutput>
                  <cfelse>
                    <tr>
                      <td colspan="8" class="text-center text-muted py-4">Nenhum canal de conteudo encontrado.</td>
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
