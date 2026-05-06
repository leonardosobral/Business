<cfinclude template="../includes/channels_backend.cfm"/>
<cfset VARIABLES.channelVisibleColumns = "id_youtube_canal,name,id_pagina,id_usuario,max_results,sort"/>
<cfset VARIABLES.channelShowForm = qChannelEdit.recordcount OR (isDefined("URL.canal_novo") AND URL.canal_novo)/>
<cfset VARIABLES.channelVisibleCount = 0/>

<style>
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
</style>

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Portal - Canais do YouTube</h3>
              <p class="text-muted mb-0">Gerencie os canais usados na importacao automatica de conteudo.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Total de canais</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qChannelsCount.total)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o gerenciamento de canais do Portal.
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
                    <p class="text-muted small mb-0">Cadastre ou atualize os dados usados na importacao.</p>
                  </div>
                  <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.mediaPage#">Fechar</a></cfoutput>
                </div>

                <cfoutput><form method="post" action="./?pagina=#VARIABLES.mediaPage#"></cfoutput>
                  <input type="hidden" name="canal_action" value="salvar"/>
                  <input type="hidden" name="canal_record_id" value="<cfif qChannelEdit.recordcount><cfoutput>#htmlEditFormat(qChannelEdit[VARIABLES.channelPk][1])#</cfoutput></cfif>"/>

                  <div class="row g-3">
                    <cfloop query="qChannelColumns">
                      <cfif qChannelColumns.column_name NEQ VARIABLES.channelPk
                          AND NOT ListFindNoCase(VARIABLES.channelFormExcludedColumns, qChannelColumns.column_name)>
                        <cfset VARIABLES.channelFieldName = "canal_" & qChannelColumns.column_name/>
                        <cfset VARIABLES.channelFieldValue = qChannelEdit.recordcount ? qChannelEdit[qChannelColumns.column_name][1] : ""/>
                        <cfset VARIABLES.channelFieldType = lcase(qChannelColumns.data_type)/>
                        <cfset VARIABLES.channelFieldLabel = Replace(qChannelColumns.column_name, "_", " ", "all")/>

                        <cfoutput>
                          <div class="col-12 <cfif VARIABLES.channelFieldType EQ 'text'>col-lg-12<cfelse>col-md-6 col-lg-4</cfif>">
                            <label class="form-label text-capitalize">#htmlEditFormat(VARIABLES.channelFieldLabel)#</label>
                            <cfif VARIABLES.channelFieldType EQ "boolean">
                              <input type="hidden" name="#VARIABLES.channelFieldName#" value="false"/>
                              <div class="form-check form-switch pt-2">
                                <input class="form-check-input" type="checkbox" role="switch" id="#VARIABLES.channelFieldName#" name="#VARIABLES.channelFieldName#" value="true" <cfif IsBoolean(VARIABLES.channelFieldValue) ? VARIABLES.channelFieldValue : ListFindNoCase('true,1,yes,sim', trim(VARIABLES.channelFieldValue))>checked</cfif>>
                                <label class="form-check-label" for="#VARIABLES.channelFieldName#">Ativo</label>
                              </div>
                            <cfelseif VARIABLES.channelFieldType EQ "text" OR (isNumeric(qChannelColumns.character_maximum_length) AND qChannelColumns.character_maximum_length GT 160)>
                              <textarea class="form-control" name="#VARIABLES.channelFieldName#" rows="4">#htmlEditFormat(VARIABLES.channelFieldValue)#</textarea>
                            <cfelse>
                              <input class="form-control" type="text" name="#VARIABLES.channelFieldName#" value="#htmlEditFormat(VARIABLES.channelFieldValue)#"/>
                            </cfif>
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
