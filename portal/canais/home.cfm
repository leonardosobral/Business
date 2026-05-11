<cfinclude template="../includes/channels_backend.cfm"/>
<cfset VARIABLES.channelVisibleColumns = "id_youtube_canal,name,id_pagina,id_usuario,max_results,sort"/>
<cfset VARIABLES.channelShowForm = qChannelEdit.recordcount OR (isDefined("URL.canal_novo") AND URL.canal_novo)/>
<cfset VARIABLES.channelVisibleCount = 0/>
<cfset VARIABLES.channelDescriptionColumns = "descricao,description,bio"/>
<cfset VARIABLES.channelInstagramColumns = "instagram,instagram_url,url_instagram,link_instagram"/>
<cfset VARIABLES.channelUrlColumns = "url,channel_url,youtube_url,feed_url,api_url"/>
<cfset VARIABLES.channelHasDescriptionField = false/>
<cfset VARIABLES.channelHasInstagramField = false/>
<cfloop list="#VARIABLES.channelDescriptionColumns#" item="channelDescriptionColumn">
  <cfif NOT VARIABLES.channelHasDescriptionField AND ListFindNoCase(VARIABLES.channelColumns, channelDescriptionColumn)>
    <cfset VARIABLES.channelHasDescriptionField = true/>
  </cfif>
</cfloop>
<cfloop list="#VARIABLES.channelInstagramColumns#" item="channelInstagramColumn">
  <cfif NOT VARIABLES.channelHasInstagramField AND ListFindNoCase(VARIABLES.channelColumns, channelInstagramColumn)>
    <cfset VARIABLES.channelHasInstagramField = true/>
  </cfif>
</cfloop>

<style>
  .channel-form-grid {
    row-gap: 1rem;
  }

  .channel-table td,
  .channel-table th {
    vertical-align: middle;
  }

  .channel-cell {
    max-width: 280px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .channel-actions-cell {
    min-width: 240px;
  }

  .channel-form-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
  }

  .channel-field-card {
    background: rgba(255,255,255,0.025);
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: 1rem;
    padding: 1rem;
    height: 100%;
  }

  .channel-field-card .form-label {
    font-size: 0.82rem;
    font-weight: 700;
    letter-spacing: 0.02em;
    text-transform: uppercase;
    color: rgba(255,255,255,0.7);
  }

  .channel-field-help {
    font-size: 0.78rem;
    color: rgba(255,255,255,0.58);
  }

</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Canais de Vídeo</h3>
              <p class="text-muted mb-0">Gerencie os canais de origem usados na importacao automatica de videos para o portal.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Total de canais</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qChannelsCount.total)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o gerenciamento de canais de video do Portal.
            </div>
          <cfelseif NOT qChannelColumns.recordcount>
            <div class="alert alert-danger mb-0">
              Nao foi possivel localizar as colunas da tabela <strong>tb_youtube_canais</strong>.
            </div>
          <cfelse>
            <div class="d-flex justify-content-end mb-3">
              <cfoutput>
                <a class="btn btn-warning" href="./?pagina=#VARIABLES.mediaPage#&canal_novo=1">Novo canal</a>
              </cfoutput>
            </div>

            <cfif VARIABLES.channelShowForm>
              <div class="channel-form-card p-4 mb-4">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                  <div>
                    <h5 class="mb-1"><cfif qChannelEdit.recordcount>Editar canal<cfelse>Novo canal</cfif></h5>
                    <p class="text-muted small mb-0">Cadastre ou atualize os dados usados na importacao e exibicao do canal.</p>
                  </div>
                  <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.mediaPage#">Fechar</a></cfoutput>
                </div>

                <cfif NOT VARIABLES.channelHasDescriptionField OR NOT VARIABLES.channelHasInstagramField>
                  <div class="alert alert-warning py-2 px-3 small mb-3">
                    Alguns campos avançados do canal dependem de colunas na tabela <strong>tb_youtube_canais</strong>.
                    <cfif NOT VARIABLES.channelHasDescriptionField>Descrição não encontrada. </cfif>
                    <cfif NOT VARIABLES.channelHasInstagramField>Instagram não encontrado.</cfif>
                  </div>
                </cfif>

                <cfoutput><form method="post" action="./?pagina=#VARIABLES.mediaPage#"></cfoutput>
                  <input type="hidden" name="canal_action" value="salvar"/>
                  <input type="hidden" name="canal_record_id" value="<cfif qChannelEdit.recordcount><cfoutput>#htmlEditFormat(qChannelEdit[VARIABLES.channelPk][1])#</cfoutput></cfif>"/>

                  <div class="row channel-form-grid">
                    <cfloop query="qChannelColumns">
                      <cfif qChannelColumns.column_name NEQ VARIABLES.channelPk
                          AND NOT ListFindNoCase(VARIABLES.channelFormExcludedColumns, qChannelColumns.column_name)>
                        <cfset VARIABLES.channelFieldName = "canal_" & qChannelColumns.column_name/>
                        <cfset VARIABLES.channelFieldValue = qChannelEdit.recordcount ? qChannelEdit[qChannelColumns.column_name][1] : ""/>
                        <cfset VARIABLES.channelFieldType = lcase(qChannelColumns.data_type)/>
                        <cfset VARIABLES.channelFieldLabel = Replace(qChannelColumns.column_name, "_", " ", "all")/>
                        <cfset VARIABLES.channelFieldHelp = ""/>
                        <cfset VARIABLES.channelFieldColClass = VARIABLES.channelFieldType EQ "text" ? "col-12" : "col-12 col-md-6 col-xl-4"/>
                        <cfset VARIABLES.channelIsDescriptionField = ListFindNoCase(VARIABLES.channelDescriptionColumns, qChannelColumns.column_name)/>
                        <cfset VARIABLES.channelIsInstagramField = ListFindNoCase(VARIABLES.channelInstagramColumns, qChannelColumns.column_name)/>
                        <cfset VARIABLES.channelIsUrlField = VARIABLES.channelIsInstagramField OR ListFindNoCase(VARIABLES.channelUrlColumns, qChannelColumns.column_name) OR FindNoCase("url", qChannelColumns.column_name)/>
                        <cfset VARIABLES.channelIsIntegerField = VARIABLES.channelFieldType EQ "integer" OR VARIABLES.channelFieldType EQ "smallint" OR VARIABLES.channelFieldType EQ "bigint"/>

                        <cfswitch expression="#qChannelColumns.column_name#">
                          <cfcase value="id_youtube_canal"><cfset VARIABLES.channelFieldLabel = "ID do Canal"/></cfcase>
                          <cfcase value="name"><cfset VARIABLES.channelFieldLabel = "Nome do Canal"/><cfset VARIABLES.channelFieldHelp = "Nome interno para identificar facilmente o canal no Business."/></cfcase>
                          <cfcase value="id_pagina"><cfset VARIABLES.channelFieldLabel = "ID da Página"/><cfset VARIABLES.channelFieldHelp = "Relaciona o canal com a pagina correspondente dentro do ecossistema Roadrunners."/></cfcase>
                          <cfcase value="id_usuario"><cfset VARIABLES.channelFieldLabel = "ID do Usuário"/><cfset VARIABLES.channelFieldHelp = "Usuário responsável ou proprietário vinculado ao canal."/></cfcase>
                          <cfcase value="max_results"><cfset VARIABLES.channelFieldLabel = "Máx. de Resultados"/><cfset VARIABLES.channelFieldHelp = "Quantidade máxima de videos buscados em cada importação."/></cfcase>
                          <cfcase value="sort"><cfset VARIABLES.channelFieldLabel = "Ordem"/><cfset VARIABLES.channelFieldHelp = "Define a ordem de prioridade ou exibição do canal."/></cfcase>
                        </cfswitch>

                        <cfif VARIABLES.channelIsDescriptionField>
                          <cfset VARIABLES.channelFieldLabel = "Descrição"/>
                          <cfset VARIABLES.channelFieldHelp = "Resumo editorial do canal, propósito ou observações internas."/>
                          <cfset VARIABLES.channelFieldColClass = "col-12"/>
                        <cfelseif VARIABLES.channelIsInstagramField>
                          <cfset VARIABLES.channelFieldLabel = "URL do Instagram"/>
                          <cfset VARIABLES.channelFieldHelp = "Cole a URL completa do Instagram do canal ou da marca."/>
                          <cfset VARIABLES.channelFieldColClass = "col-12 col-lg-6"/>
                        <cfelseif VARIABLES.channelIsUrlField>
                          <cfset VARIABLES.channelFieldColClass = "col-12 col-lg-6"/>
                        <cfelseif VARIABLES.channelIsIntegerField>
                          <cfset VARIABLES.channelFieldColClass = "col-12 col-md-6 col-lg-4"/>
                        <cfelseif VARIABLES.channelFieldType EQ "boolean">
                          <cfset VARIABLES.channelFieldColClass = "col-12 col-md-6 col-lg-4"/>
                        </cfif>

                        <cfoutput>
                          <div class="#VARIABLES.channelFieldColClass#">
                            <div class="channel-field-card">
                              <label class="form-label">#htmlEditFormat(VARIABLES.channelFieldLabel)#</label>

                              <cfif VARIABLES.channelFieldType EQ "boolean">
                                <input type="hidden" name="#VARIABLES.channelFieldName#" value="false"/>
                                <div class="form-check form-switch pt-2">
                                  <input class="form-check-input" type="checkbox" role="switch" id="#VARIABLES.channelFieldName#" name="#VARIABLES.channelFieldName#" value="true" <cfif IsBoolean(VARIABLES.channelFieldValue) ? VARIABLES.channelFieldValue : ListFindNoCase('true,1,yes,sim', trim(VARIABLES.channelFieldValue))>checked</cfif>>
                                  <label class="form-check-label" for="#VARIABLES.channelFieldName#">Canal ativo para importação e uso</label>
                                </div>
                              <cfelseif VARIABLES.channelIsInstagramField>
                                <input class="form-control" type="url" name="#VARIABLES.channelFieldName#" value="#htmlEditFormat(VARIABLES.channelFieldValue)#" placeholder="https://instagram.com/..."/>
                              <cfelseif VARIABLES.channelIsUrlField>
                                <input class="form-control" type="url" name="#VARIABLES.channelFieldName#" value="#htmlEditFormat(VARIABLES.channelFieldValue)#" placeholder="https://..."/>
                              <cfelseif VARIABLES.channelIsIntegerField>
                                <input class="form-control" type="number" name="#VARIABLES.channelFieldName#" value="#htmlEditFormat(VARIABLES.channelFieldValue)#" step="1" inputmode="numeric"/>
                              <cfelseif VARIABLES.channelIsDescriptionField OR VARIABLES.channelFieldType EQ "text" OR (isNumeric(qChannelColumns.character_maximum_length) AND qChannelColumns.character_maximum_length GT 160)>
                                <textarea class="form-control" name="#VARIABLES.channelFieldName#" rows="<cfif VARIABLES.channelIsDescriptionField>5<cfelse>4</cfif>" placeholder="<cfif VARIABLES.channelIsDescriptionField>Descreva rapidamente o canal, sua linha editorial ou observações relevantes.</cfif>">#htmlEditFormat(VARIABLES.channelFieldValue)#</textarea>
                              <cfelse>
                                <input class="form-control" type="text" name="#VARIABLES.channelFieldName#" value="#htmlEditFormat(VARIABLES.channelFieldValue)#"/>
                              </cfif>

                              <cfif len(trim(VARIABLES.channelFieldHelp))>
                                <div class="channel-field-help mt-2">#htmlEditFormat(VARIABLES.channelFieldHelp)#</div>
                              </cfif>
                            </div>
                          </div>
                        </cfoutput>
                      </cfif>
                    </cfloop>
                  </div>

                  <div class="d-flex flex-wrap gap-2 mt-3">
                    <button type="submit" class="btn btn-warning"><cfif qChannelEdit.recordcount>Salvar alteracoes<cfelse>Cadastrar canal</cfif></button>
                    <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.mediaPage#">Cancelar</a></cfoutput>
                  </div>
                </form>
              </div>
            </cfif>

            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover channel-table">
                <thead>
                  <tr>
                    <cfloop query="qChannelColumns">
                      <cfif ListFindNoCase(VARIABLES.channelVisibleColumns, qChannelColumns.column_name)
                          OR (len(trim(VARIABLES.channelActiveColumn)) AND qChannelColumns.column_name EQ VARIABLES.channelActiveColumn)>
                        <cfset VARIABLES.channelVisibleCount = VARIABLES.channelVisibleCount + 1/>
                        <cfswitch expression="#qChannelColumns.column_name#">
                          <cfcase value="id_youtube_canal"><cfset VARIABLES.channelColumnLabel = "ID do Canal"/></cfcase>
                          <cfcase value="name"><cfset VARIABLES.channelColumnLabel = "Nome"/></cfcase>
                          <cfcase value="id_pagina"><cfset VARIABLES.channelColumnLabel = "ID da Página"/></cfcase>
                          <cfcase value="id_usuario"><cfset VARIABLES.channelColumnLabel = "ID do Usuário"/></cfcase>
                          <cfcase value="max_results"><cfset VARIABLES.channelColumnLabel = "Máx. de Resultados"/></cfcase>
                          <cfcase value="sort"><cfset VARIABLES.channelColumnLabel = "Ordem"/></cfcase>
                          <cfcase value="#VARIABLES.channelActiveColumn#"><cfset VARIABLES.channelColumnLabel = "Status"/></cfcase>
                          <cfdefaultcase><cfset VARIABLES.channelColumnLabel = qChannelColumns.column_name/></cfdefaultcase>
                        </cfswitch>
                        <cfoutput><th>#htmlEditFormat(VARIABLES.channelColumnLabel)#</th></cfoutput>
                      </cfif>
                    </cfloop>
                    <th class="channel-actions-cell">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  <cfif qChannels.recordcount>
                    <cfoutput query="qChannels">
                      <cfset VARIABLES.channelPkValue = qChannels[VARIABLES.channelPk][qChannels.currentRow]/>
                      <tr>
                        <cfloop query="qChannelColumns">
                          <cfset VARIABLES.channelColumnName = qChannelColumns.column_name/>
                          <cfset VARIABLES.channelColumnValue = qChannels[VARIABLES.channelColumnName][qChannels.currentRow]/>
                          <cfif ListFindNoCase(VARIABLES.channelVisibleColumns, VARIABLES.channelColumnName)
                              OR (len(trim(VARIABLES.channelActiveColumn)) AND VARIABLES.channelColumnName EQ VARIABLES.channelActiveColumn)>
                            <td class="channel-cell">
                              <cfif len(trim(VARIABLES.channelActiveColumn)) AND VARIABLES.channelColumnName EQ VARIABLES.channelActiveColumn>
                                <cfset VARIABLES.channelIsActive = IsBoolean(VARIABLES.channelColumnValue) ? VARIABLES.channelColumnValue : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.channelColumnValue))/>
                                <span class="badge <cfif VARIABLES.channelIsActive>badge-success<cfelse>badge-danger</cfif>">
                                  <cfif VARIABLES.channelIsActive>Ativo<cfelse>Inativo</cfif>
                                </span>
                              <cfelse>
                                #htmlEditFormat(VARIABLES.channelColumnValue)#
                              </cfif>
                            </td>
                          </cfif>
                        </cfloop>
                        <td class="channel-actions-cell">
                          <div class="d-flex flex-wrap gap-2">
                            <a class="btn btn-sm btn-outline-primary" href="./?pagina=#VARIABLES.mediaPage#&canal_editar=#urlEncodedFormat(VARIABLES.channelPkValue)#">Editar</a>

                            <cfif len(trim(VARIABLES.channelActiveColumn))>
                              <cfset VARIABLES.channelCurrentStatus = qChannels[VARIABLES.channelActiveColumn][qChannels.currentRow]/>
                              <cfset VARIABLES.channelIsActive = IsBoolean(VARIABLES.channelCurrentStatus) ? VARIABLES.channelCurrentStatus : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.channelCurrentStatus))/>
                              <a class="btn btn-sm <cfif VARIABLES.channelIsActive>btn-outline-warning<cfelse>btn-outline-success</cfif>" href="./?pagina=#VARIABLES.mediaPage#&canal_acao=status&canal_id=#urlEncodedFormat(VARIABLES.channelPkValue)#&status=#NOT VARIABLES.channelIsActive#">
                                <cfif VARIABLES.channelIsActive>Desativar<cfelse>Ativar</cfif>
                              </a>
                            </cfif>

                            <a class="btn btn-sm btn-outline-danger" href="./?pagina=#VARIABLES.mediaPage#&canal_acao=excluir&canal_id=#urlEncodedFormat(VARIABLES.channelPkValue)#" onclick="return confirm('Tem certeza que deseja remover este canal do banco de dados?');">
                              Remover
                            </a>
                          </div>
                        </td>
                      </tr>
                    </cfoutput>
                  <cfelse>
                    <cfoutput>
                      <tr>
                        <td colspan="#max(1, VARIABLES.channelVisibleCount + 1)#" class="text-center text-muted py-4">
                          Nenhum canal cadastrado ate o momento.
                        </td>
                      </tr>
                    </cfoutput>
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
