<cfinclude template="includes/backend.cfm"/>
<cfset VARIABLES.treinoConfigShowForm = qTreinoConfigEdit.recordcount OR (isDefined("URL.config_novo") AND URL.config_novo)/>
<cfset VARIABLES.treinoConfigVisibleCount = 0/>
<cfloop query="qTreinoConfigColumns">
  <cfif qTreinoConfigColumns.column_name NEQ VARIABLES.treinoConfigPk
      AND NOT ListFindNoCase(VARIABLES.treinoConfigFormExcludedColumns, qTreinoConfigColumns.column_name)>
    <cfset VARIABLES.treinoConfigVisibleCount = VARIABLES.treinoConfigVisibleCount + 1/>
  </cfif>
</cfloop>

<style>
  .config-table {
    min-width: 980px;
  }

  .config-table td,
  .config-table th {
    vertical-align: middle;
  }

  .config-cell {
    max-width: 320px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .config-actions-cell {
    min-width: 240px;
    white-space: nowrap;
  }

  .config-form-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
  }

  .config-table .badge {
    font-size: 0.75rem;
  }

  @media (max-width: 991.98px) {
    .config-table {
      min-width: 100%;
    }

    .config-table thead {
      display: none;
    }

    .config-table,
    .config-table tbody,
    .config-table tr,
    .config-table td {
      display: block;
      width: 100%;
    }

    .config-table tbody {
      display: grid;
      gap: 1rem;
    }

    .config-table tr {
      background: rgba(255,255,255,0.03);
      border: 1px solid rgba(255,255,255,0.08);
      border-radius: 1rem;
      overflow: hidden;
    }

    .config-table td {
      position: relative;
      padding: 0.9rem 1rem 0.9rem 47%;
      border: 0;
      border-bottom: 1px solid rgba(255,255,255,0.06);
      min-height: 52px;
      text-align: left;
    }

    .config-table td:last-child {
      border-bottom: 0;
    }

    .config-table td::before {
      content: attr(data-label);
      position: absolute;
      top: 0.9rem;
      left: 1rem;
      width: calc(47% - 1.5rem);
      font-size: 0.75rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.03em;
      color: rgba(255,255,255,0.66);
      white-space: normal;
    }

    .config-actions-cell {
      min-width: 100%;
      white-space: normal;
    }

    .config-actions-cell .d-flex {
      justify-content: flex-start;
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
              <h3 class="mb-1">Ferramentas - Configuração de Treinos</h3>
              <p class="text-muted mb-0">Cadastre e gerencie as configurações salvas em <strong>tb_evento_treinos_config</strong>.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Total de configurações</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qTreinoConfigCount.total)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Você não tem permissão para acessar o gerenciamento de configurações de treinos.
            </div>
          <cfelseif NOT qTreinoConfigColumns.recordcount>
            <div class="alert alert-danger mb-0">
              Não foi possível localizar as colunas da tabela <strong>tb_evento_treinos_config</strong>.
            </div>
          <cfelse>
            <div class="d-flex justify-content-end mb-3">
              <cfoutput><a class="btn btn-warning" href="./?pagina=#VARIABLES.configPage#&config_novo=1">Nova configuração</a></cfoutput>
            </div>

            <cfif VARIABLES.treinoConfigShowForm>
              <div class="config-form-card p-4 mb-4">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                  <div>
                    <h5 class="mb-1"><cfif qTreinoConfigEdit.recordcount>Editar configuração<cfelse>Nova configuração</cfif></h5>
                    <p class="text-muted small mb-0">Atualize os campos da configuração de treinos.</p>
                  </div>
                  <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.configPage#">Fechar</a></cfoutput>
                </div>

                <cfoutput><form method="post" action="./?pagina=#VARIABLES.configPage#"></cfoutput>
                  <input type="hidden" name="config_action" value="salvar"/>
                  <input type="hidden" name="config_record_id" value="<cfif qTreinoConfigEdit.recordcount><cfoutput>#htmlEditFormat(qTreinoConfigEdit[VARIABLES.treinoConfigPk][1])#</cfoutput></cfif>"/>

                  <div class="row g-3">
                    <cfloop query="qTreinoConfigColumns">
                      <cfset VARIABLES.treinoConfigIsAuditField = ListFindNoCase(VARIABLES.treinoConfigFormExcludedColumns, qTreinoConfigColumns.column_name)/>
                      <cfif qTreinoConfigColumns.column_name NEQ VARIABLES.treinoConfigPk
                          AND NOT VARIABLES.treinoConfigIsAuditField>
                        <cfset VARIABLES.treinoConfigFieldName = "config_" & qTreinoConfigColumns.column_name/>
                        <cfset VARIABLES.treinoConfigFieldValue = qTreinoConfigEdit.recordcount ? qTreinoConfigEdit[qTreinoConfigColumns.column_name][1] : ""/>
                        <cfset VARIABLES.treinoConfigFieldType = lcase(qTreinoConfigColumns.data_type)/>
                        <cfset VARIABLES.treinoConfigFieldLabel = Replace(qTreinoConfigColumns.column_name, "_", " ", "all")/>
                        <cfset VARIABLES.treinoConfigIsDateTimeField = ListFindNoCase("data_abertura_inscricao,data_encerramento_inscricao", qTreinoConfigColumns.column_name)/>
                        <cfif VARIABLES.treinoConfigIsDateTimeField AND isDate(VARIABLES.treinoConfigFieldValue)>
                          <cfset VARIABLES.treinoConfigFieldValue = dateTimeFormat(VARIABLES.treinoConfigFieldValue, "yyyy-mm-dd'T'HH:nn")/>
                        </cfif>

                        <cfoutput>
                          <div class="col-12 <cfif VARIABLES.treinoConfigFieldType EQ 'text'>col-lg-12<cfelse>col-md-6 col-lg-4</cfif>">
                            <cfif NOT VARIABLES.treinoConfigIsDateTimeField>
                              <label class="form-label text-capitalize">#htmlEditFormat(VARIABLES.treinoConfigFieldLabel)#</label>
                            </cfif>
                            <cfif qTreinoConfigColumns.column_name EQ "id_evento">
                              <cfif qTreinoConfigEdit.recordcount>
                                <input type="hidden" name="#VARIABLES.treinoConfigFieldName#" value="#htmlEditFormat(VARIABLES.treinoConfigFieldValue)#"/>
                                <div class="form-control bg-body-tertiary d-flex align-items-center" style="min-height: 38px;">
                                  <cfif len(trim(VARIABLES.treinoConfigEventoNome))>
                                    #htmlEditFormat(VARIABLES.treinoConfigFieldValue)# - #htmlEditFormat(VARIABLES.treinoConfigEventoNome)#
                                  <cfelse>
                                    #htmlEditFormat(VARIABLES.treinoConfigFieldValue)#
                                  </cfif>
                                </div>
                              <cfelse>
                                <select class="form-select" name="#VARIABLES.treinoConfigFieldName#">
                                  <option value="">Selecione um evento de treino</option>
                                  <cfloop query="qTreinoEventos">
                                    <option value="#qTreinoEventos.id_evento#" <cfif VARIABLES.treinoConfigFieldValue EQ qTreinoEventos.id_evento>selected</cfif>>
                                      #htmlEditFormat(qTreinoEventos.id_evento)# - #htmlEditFormat(qTreinoEventos.nome_evento)#
                                    </option>
                                  </cfloop>
                                </select>
                              </cfif>
                            <cfelseif VARIABLES.treinoConfigFieldType EQ "boolean">
                              <input type="hidden" name="#VARIABLES.treinoConfigFieldName#" value="false"/>
                              <div class="form-check form-switch pt-2">
                                <input class="form-check-input" type="checkbox" role="switch" id="#VARIABLES.treinoConfigFieldName#" name="#VARIABLES.treinoConfigFieldName#" value="true" <cfif IsBoolean(VARIABLES.treinoConfigFieldValue) ? VARIABLES.treinoConfigFieldValue : ListFindNoCase('true,1,yes,sim', trim(VARIABLES.treinoConfigFieldValue))>checked</cfif>>
                                <label class="form-check-label" for="#VARIABLES.treinoConfigFieldName#">Ativo</label>
                              </div>
                            <cfelseif VARIABLES.treinoConfigIsDateTimeField>
                              <div class="form-outline" data-mdb-input-init>
                                <input class="form-control" type="datetime-local" id="#VARIABLES.treinoConfigFieldName#" name="#VARIABLES.treinoConfigFieldName#" value="#htmlEditFormat(VARIABLES.treinoConfigFieldValue)#"/>
                                <label for="#VARIABLES.treinoConfigFieldName#" class="form-label text-capitalize active">#htmlEditFormat(VARIABLES.treinoConfigFieldLabel)#</label>
                              </div>
                            <cfelseif VARIABLES.treinoConfigFieldType EQ "integer" OR VARIABLES.treinoConfigFieldType EQ "smallint">
                              <input class="form-control" type="number" name="#VARIABLES.treinoConfigFieldName#" value="#htmlEditFormat(VARIABLES.treinoConfigFieldValue)#" step="1" inputmode="numeric"/>
                            <cfelseif VARIABLES.treinoConfigFieldType EQ "text" OR (isNumeric(qTreinoConfigColumns.character_maximum_length) AND qTreinoConfigColumns.character_maximum_length GT 160)>
                              <textarea class="form-control" name="#VARIABLES.treinoConfigFieldName#" rows="4">#htmlEditFormat(VARIABLES.treinoConfigFieldValue)#</textarea>
                            <cfelse>
                              <input class="form-control" type="text" name="#VARIABLES.treinoConfigFieldName#" value="#htmlEditFormat(VARIABLES.treinoConfigFieldValue)#"/>
                            </cfif>
                          </div>
                        </cfoutput>
                      </cfif>
                    </cfloop>
                  </div>

                  <div class="d-flex flex-wrap gap-2 mt-3">
                    <button type="submit" class="btn btn-warning"><cfif qTreinoConfigEdit.recordcount>Salvar alterações<cfelse>Cadastrar configuração</cfif></button>
                    <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.configPage#">Cancelar</a></cfoutput>
                  </div>
                </form>
              </div>
            </cfif>

            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover config-table">
                <thead>
                  <tr>
                    <cfoutput query="qTreinoConfigColumns">
                      <cfif qTreinoConfigColumns.column_name NEQ VARIABLES.treinoConfigPk
                          AND NOT ListFindNoCase(VARIABLES.treinoConfigFormExcludedColumns, qTreinoConfigColumns.column_name)>
                        <cfswitch expression="#qTreinoConfigColumns.column_name#">
                          <cfcase value="#VARIABLES.treinoConfigActiveColumn#"><cfset VARIABLES.treinoConfigColumnLabel = "Status"/></cfcase>
                          <cfdefaultcase><cfset VARIABLES.treinoConfigColumnLabel = Replace(qTreinoConfigColumns.column_name, "_", " ", "all")/></cfdefaultcase>
                        </cfswitch>
                        <th>#htmlEditFormat(VARIABLES.treinoConfigColumnLabel)#</th>
                      </cfif>
                    </cfoutput>
                    <th class="config-actions-cell">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  <cfif qTreinoConfigs.recordcount>
                    <cfoutput query="qTreinoConfigs">
                      <cfset VARIABLES.treinoConfigPkValue = qTreinoConfigs[VARIABLES.treinoConfigPk][qTreinoConfigs.currentRow]/>
                      <tr>
                        <cfloop query="qTreinoConfigColumns">
                          <cfif qTreinoConfigColumns.column_name NEQ VARIABLES.treinoConfigPk
                              AND NOT ListFindNoCase(VARIABLES.treinoConfigFormExcludedColumns, qTreinoConfigColumns.column_name)>
                            <cfset VARIABLES.treinoConfigColumnName = qTreinoConfigColumns.column_name/>
                            <cfset VARIABLES.treinoConfigColumnValue = qTreinoConfigs[VARIABLES.treinoConfigColumnName][qTreinoConfigs.currentRow]/>
                            <cfswitch expression="#VARIABLES.treinoConfigColumnName#">
                              <cfcase value="#VARIABLES.treinoConfigActiveColumn#"><cfset VARIABLES.treinoConfigColumnLabel = "Status"/></cfcase>
                              <cfdefaultcase><cfset VARIABLES.treinoConfigColumnLabel = Replace(VARIABLES.treinoConfigColumnName, "_", " ", "all")/></cfdefaultcase>
                            </cfswitch>
                            <td class="config-cell" data-label="#htmlEditFormat(VARIABLES.treinoConfigColumnLabel)#">
                              <cfif len(trim(VARIABLES.treinoConfigActiveColumn)) AND VARIABLES.treinoConfigColumnName EQ VARIABLES.treinoConfigActiveColumn>
                                <cfset VARIABLES.treinoConfigIsActive = IsBoolean(VARIABLES.treinoConfigColumnValue) ? VARIABLES.treinoConfigColumnValue : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.treinoConfigColumnValue))/>
                                <span class="badge <cfif VARIABLES.treinoConfigIsActive>badge-success<cfelse>badge-danger</cfif>">
                                  <cfif VARIABLES.treinoConfigIsActive>Ativo<cfelse>Inativo</cfif>
                                </span>
                              <cfelseif VARIABLES.treinoConfigColumnName EQ "id_evento">
                                <cfset VARIABLES.treinoConfigEventoLabel = ""/>
                                <cfloop query="qTreinoEventos">
                                  <cfif qTreinoEventos.id_evento EQ VARIABLES.treinoConfigColumnValue>
                                    <cfset VARIABLES.treinoConfigEventoLabel = qTreinoEventos.nome_evento/>
                                  </cfif>
                                </cfloop>
                                <cfif len(trim(VARIABLES.treinoConfigEventoLabel))>
                                  <strong>#htmlEditFormat(VARIABLES.treinoConfigColumnValue)#</strong>
                                  <div class="small text-muted">#htmlEditFormat(VARIABLES.treinoConfigEventoLabel)#</div>
                                <cfelse>
                                  #htmlEditFormat(VARIABLES.treinoConfigColumnValue)#
                                </cfif>
                              <cfelseif VARIABLES.treinoConfigColumnName EQ "data_abertura_inscricao" OR VARIABLES.treinoConfigColumnName EQ "data_encerramento_inscricao">
                                <cfif isDate(VARIABLES.treinoConfigColumnValue)>
                                  #htmlEditFormat(lsDateFormat(VARIABLES.treinoConfigColumnValue, "dd/mm/yyyy"))#
                                  <div class="small text-muted">#htmlEditFormat(timeFormat(VARIABLES.treinoConfigColumnValue, "HH:mm"))#</div>
                                <cfelse>
                                  #htmlEditFormat(VARIABLES.treinoConfigColumnValue)#
                                </cfif>
                              <cfelse>
                                #htmlEditFormat(VARIABLES.treinoConfigColumnValue)#
                              </cfif>
                            </td>
                          </cfif>
                        </cfloop>
                        <td class="config-actions-cell" data-label="Ações">
                          <div class="d-flex flex-wrap gap-2">
                            <a class="btn btn-sm btn-outline-primary" href="./?pagina=#VARIABLES.configPage#&config_editar=#urlEncodedFormat(VARIABLES.treinoConfigPkValue)#">Editar</a>

                            <cfif len(trim(VARIABLES.treinoConfigActiveColumn))>
                              <cfset VARIABLES.treinoConfigCurrentStatus = qTreinoConfigs[VARIABLES.treinoConfigActiveColumn][qTreinoConfigs.currentRow]/>
                              <cfset VARIABLES.treinoConfigIsActive = IsBoolean(VARIABLES.treinoConfigCurrentStatus) ? VARIABLES.treinoConfigCurrentStatus : ListFindNoCase("true,1,yes,sim", trim(VARIABLES.treinoConfigCurrentStatus))/>
                              <a class="btn btn-sm <cfif VARIABLES.treinoConfigIsActive>btn-outline-warning<cfelse>btn-outline-success</cfif>" href="./?pagina=#VARIABLES.configPage#&config_acao=status&config_id=#urlEncodedFormat(VARIABLES.treinoConfigPkValue)#&status=#NOT VARIABLES.treinoConfigIsActive#">
                                <cfif VARIABLES.treinoConfigIsActive>Desativar<cfelse>Ativar</cfif>
                              </a>
                            </cfif>

                            <a class="btn btn-sm btn-outline-danger" href="./?pagina=#VARIABLES.configPage#&config_acao=excluir&config_id=#urlEncodedFormat(VARIABLES.treinoConfigPkValue)#" onclick="return confirm('Tem certeza que deseja remover esta configuração de treinos?');">
                              Remover
                            </a>
                          </div>
                        </td>
                      </tr>
                    </cfoutput>
                  <cfelse>
                    <cfoutput>
                      <tr>
                        <td colspan="#max(1, VARIABLES.treinoConfigVisibleCount + 1)#" class="text-center text-muted py-4">
                          Nenhuma configuração cadastrada até o momento.
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
