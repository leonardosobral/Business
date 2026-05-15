<cfinclude template="../includes/templates_backend.cfm"/>
<cfset VARIABLES.notificationTemplateShowForm = qNotificationTemplateEdit.recordcount OR (isDefined("URL.template_novo") AND URL.template_novo)/>

<style>
  .notification-nav {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
  }

  .notification-template-form-grid {
    row-gap: 1rem;
  }

  .notification-template-table td,
  .notification-template-table th {
    vertical-align: middle;
  }

  .notification-template-cell {
    max-width: 340px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .notification-template-actions-cell {
    min-width: 280px;
  }

  .notification-template-form-card {
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 1rem;
  }

  .notification-template-field-card {
    background: rgba(255,255,255,0.025);
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: 1rem;
    padding: 1rem;
    height: 100%;
  }

  .notification-template-field-card .form-label {
    font-size: 0.82rem;
    font-weight: 700;
    letter-spacing: 0.02em;
    text-transform: uppercase;
    color: rgba(255,255,255,0.7);
  }

  .notification-template-icon-picker {
    display: grid;
    gap: 0.75rem;
  }

  .notification-template-icon-select {
    font-size: 0.95rem;
  }

  .notification-template-icon-preview {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    min-height: 56px;
    padding: 0.9rem 1rem;
    border: 1px dashed rgba(255,255,255,0.12);
    border-radius: 0.9rem;
    background: rgba(255,255,255,0.03);
  }

  .notification-template-icon-preview i {
    font-size: 1.4rem;
    width: 1.8rem;
    text-align: center;
    color: #f5c451;
  }

  .notification-template-icon-preview-code {
    font-family: var(--mdb-font-monospace);
    font-size: 0.82rem;
    color: rgba(255,255,255,0.74);
    overflow-wrap: anywhere;
  }

  .notification-template-list-icon {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 0.85rem;
    background: rgba(245, 196, 81, 0.12);
    color: #f5c451;
    font-size: 1.1rem;
  }

  .notification-template-content-card {
    min-width: 220px;
    max-width: 340px;
    padding: 0.9rem 1rem;
    border-radius: 0.95rem;
    background: rgba(255,255,255,0.04);
    border: 1px solid rgba(255,255,255,0.08);
    line-height: 1.45;
  }

  .notification-template-content-card p:last-child {
    margin-bottom: 0;
  }

  .notification-template-content-empty {
    color: rgba(255,255,255,0.5);
    font-style: italic;
  }
</style>

<cfset VARIABLES.notificationTemplateIconOptions = [
  {value = "fa-solid fa-bell", label = "Sino"},
  {value = "fa-solid fa-bullhorn", label = "Aviso"},
  {value = "fa-solid fa-circle-info", label = "Informação"},
  {value = "fa-solid fa-circle-check", label = "Confirmação"},
  {value = "fa-solid fa-triangle-exclamation", label = "Alerta"},
  {value = "fa-solid fa-gift", label = "Presente"},
  {value = "fa-solid fa-ticket", label = "Ingresso"},
  {value = "fa-solid fa-calendar", label = "Calendário"},
  {value = "fa-solid fa-fire", label = "Destaque"},
  {value = "fa-solid fa-star", label = "Favorito"},
  {value = "fa-solid fa-newspaper", label = "Notícia"},
  {value = "fa-solid fa-trophy", label = "Conquista"},
  {value = "fa-solid fa-tag", label = "Oferta"},
  {value = "fa-solid fa-location-dot", label = "Localização"},
  {value = "fa-solid fa-cart-shopping", label = "Compra"},
  {value = "fa-solid fa-person-running", label = "Corrida"},
  {value = "fa-solid fa-medal", label = "Medalha"},
  {value = "fa-solid fa-heart", label = "Engajamento"}
] />

<section>
  <div class="row gx-xl-5">
    <div class="col-lg-12 mb-4 mb-lg-0 h-100">
      <div class="card shadow-0">
        <div class="card-body">

          <div class="d-flex flex-column flex-lg-row justify-content-between gap-3">
            <div>
              <h3 class="mb-1">Notificações - Templates</h3>
              <p class="text-muted mb-0">Cadastre, edite e exclua templates usados pelo sistema interno de notificações do portal.</p>
            </div>
            <div class="text-lg-end">
              <div class="small text-muted">Total de templates</div>
              <div class="h4 mb-0"><cfoutput>#LSNumberFormat(qNotificationTemplateCount.total)#</cfoutput></div>
            </div>
          </div>

          <hr/>

          <div class="notification-nav mb-4">
            <a class="btn btn-outline-secondary <cfif VARIABLES.template EQ "/notificacoes/">active</cfif>" href="/notificacoes/">Histórico de Notificações</a>
            <a class="btn btn-warning <cfif VARIABLES.template EQ "/notificacoes/templates/">active</cfif>" href="/notificacoes/templates/">Templates</a>
            <a class="btn btn-outline-secondary <cfif VARIABLES.template EQ "/notificacoes/envio/">active</cfif>" href="/notificacoes/envio/">Envio</a>
          </div>

          <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
            <div class="alert alert-warning mb-0">
              Voce nao tem permissao para acessar o gerenciador de templates de notificacoes.
            </div>
          <cfelseif NOT qNotificationTemplateColumns.recordcount>
            <div class="alert alert-danger mb-0">
              Nao foi possivel localizar as colunas da tabela <strong>tb_notifica_template</strong>.
            </div>
          <cfelse>
            <div class="d-flex justify-content-end mb-3">
              <cfoutput>
                <a class="btn btn-warning" href="./?pagina=#VARIABLES.notificationTemplatePage#&template_novo=1">Novo template</a>
              </cfoutput>
            </div>

            <cfif VARIABLES.notificationTemplateShowForm>
              <div class="notification-template-form-card p-4 mb-4">
                <div class="d-flex justify-content-between align-items-start gap-3 mb-3">
                  <div>
                    <h5 class="mb-1"><cfif qNotificationTemplateEdit.recordcount>Editar template<cfelse>Novo template</cfif></h5>
                    <p class="text-muted small mb-0">A estrutura do formulário segue as colunas reais de <strong>tb_notifica_template</strong>.</p>
                  </div>
                  <cfoutput><a class="btn btn-sm btn-outline-secondary" href="./?pagina=#VARIABLES.notificationTemplatePage#">Fechar</a></cfoutput>
                </div>

                <cfoutput><form method="post" action="./?pagina=#VARIABLES.notificationTemplatePage#"></cfoutput>
                  <input type="hidden" name="template_action" value="salvar"/>
                  <input type="hidden" name="template_record_id" value="<cfif qNotificationTemplateEdit.recordcount><cfoutput>#htmlEditFormat(qNotificationTemplateEdit[VARIABLES.notificationTemplatePk][1])#</cfoutput></cfif>"/>

                  <div class="row notification-template-form-grid">
                    <cfloop query="qNotificationTemplateColumns">
                      <cfif qNotificationTemplateColumns.column_name NEQ VARIABLES.notificationTemplatePk
                          AND NOT ListFindNoCase(VARIABLES.notificationTemplateFormExcludedColumns, qNotificationTemplateColumns.column_name)>
                        <cfset VARIABLES.notificationTemplateFieldName = "template_" & qNotificationTemplateColumns.column_name/>
                        <cfset VARIABLES.notificationTemplateFieldValue = qNotificationTemplateEdit.recordcount ? qNotificationTemplateEdit[qNotificationTemplateColumns.column_name][1] : ""/>
                        <cfset VARIABLES.notificationTemplateFieldType = lcase(qNotificationTemplateColumns.data_type)/>
                        <cfset VARIABLES.notificationTemplateFieldLabel = Replace(qNotificationTemplateColumns.column_name, "_", " ", "all")/>
                        <cfset VARIABLES.notificationTemplateFieldColClass = VARIABLES.notificationTemplateFieldType EQ "text" ? "col-12" : "col-12 col-md-6 col-xl-4"/>
                        <cfset VARIABLES.notificationTemplateIsIntegerField = VARIABLES.notificationTemplateFieldType EQ "integer" OR VARIABLES.notificationTemplateFieldType EQ "smallint" OR VARIABLES.notificationTemplateFieldType EQ "bigint"/>
                        <cfset VARIABLES.notificationTemplateIsDateTimeField = ListFindNoCase("timestamp without time zone,timestamp with time zone", VARIABLES.notificationTemplateFieldType)/>
                        <cfset VARIABLES.notificationTemplateIsDateField = VARIABLES.notificationTemplateFieldType EQ "date"/>
                        <cfset VARIABLES.notificationTemplateIsContentField = FindNoCase("mensagem", qNotificationTemplateColumns.column_name)
                          OR FindNoCase("conteudo", qNotificationTemplateColumns.column_name)
                          OR FindNoCase("body", qNotificationTemplateColumns.column_name)
                          OR FindNoCase("content", qNotificationTemplateColumns.column_name)/>
                        <cfset VARIABLES.notificationTemplateIsIconField = qNotificationTemplateColumns.column_name EQ "icone"
                          OR qNotificationTemplateColumns.column_name EQ "icon"
                          OR qNotificationTemplateColumns.column_name EQ "icone_class"
                          OR qNotificationTemplateColumns.column_name EQ "icon_class"/>
                        <cfset VARIABLES.notificationTemplateFieldValueFormatted = VARIABLES.notificationTemplateFieldValue/>

                        <cfswitch expression="#qNotificationTemplateColumns.column_name#">
                          <cfcase value="titulo,title"><cfset VARIABLES.notificationTemplateFieldLabel = "Título"/></cfcase>
                          <cfcase value="nome,name"><cfset VARIABLES.notificationTemplateFieldLabel = "Nome"/></cfcase>
                          <cfcase value="assunto,subject"><cfset VARIABLES.notificationTemplateFieldLabel = "Assunto"/></cfcase>
                          <cfcase value="chave,template_key"><cfset VARIABLES.notificationTemplateFieldLabel = "Chave"/></cfcase>
                          <cfcase value="mensagem,body,conteudo,content"><cfset VARIABLES.notificationTemplateFieldLabel = "Conteúdo"/></cfcase>
                          <cfcase value="ativo,is_active,status"><cfset VARIABLES.notificationTemplateFieldLabel = "Status"/></cfcase>
                        </cfswitch>

                        <cfif VARIABLES.notificationTemplateIsDateTimeField AND isDate(VARIABLES.notificationTemplateFieldValue)>
                          <cfset VARIABLES.notificationTemplateFieldValueFormatted = DateTimeFormat(VARIABLES.notificationTemplateFieldValue, "yyyy-mm-dd'T'HH:nn")/>
                        <cfelseif VARIABLES.notificationTemplateIsDateField AND isDate(VARIABLES.notificationTemplateFieldValue)>
                          <cfset VARIABLES.notificationTemplateFieldValueFormatted = DateFormat(VARIABLES.notificationTemplateFieldValue, "yyyy-mm-dd")/>
                        </cfif>

                        <cfif VARIABLES.notificationTemplateIsContentField>
                          <cfset VARIABLES.notificationTemplateFieldColClass = "col-12"/>
                        </cfif>

                        <cfoutput>
                          <div class="#VARIABLES.notificationTemplateFieldColClass#">
                            <div class="notification-template-field-card">
                              <label class="form-label">#htmlEditFormat(VARIABLES.notificationTemplateFieldLabel)#</label>

                              <cfif VARIABLES.notificationTemplateFieldType EQ "boolean">
                                <input type="hidden" name="#VARIABLES.notificationTemplateFieldName#" value="false"/>
                                <div class="form-check form-switch pt-2">
                                  <input class="form-check-input" type="checkbox" role="switch" id="#VARIABLES.notificationTemplateFieldName#" name="#VARIABLES.notificationTemplateFieldName#" value="true" <cfif IsBoolean(VARIABLES.notificationTemplateFieldValue) ? VARIABLES.notificationTemplateFieldValue : ListFindNoCase('true,1,yes,sim', trim(VARIABLES.notificationTemplateFieldValue))>checked</cfif>>
                                  <label class="form-check-label" for="#VARIABLES.notificationTemplateFieldName#">Template ativo</label>
                                </div>
                              <cfelseif VARIABLES.notificationTemplateIsContentField>
                                <textarea class="form-control js-notification-template-editor" name="#VARIABLES.notificationTemplateFieldName#" rows="10">#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#</textarea>
                              <cfelseif VARIABLES.notificationTemplateIsDateTimeField>
                                <input class="form-control" type="datetime-local" name="#VARIABLES.notificationTemplateFieldName#" value="#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#" step="60"/>
                              <cfelseif VARIABLES.notificationTemplateIsDateField>
                                <input class="form-control" type="date" name="#VARIABLES.notificationTemplateFieldName#" value="#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#"/>
                              <cfelseif VARIABLES.notificationTemplateIsIntegerField>
                                <input class="form-control" type="number" name="#VARIABLES.notificationTemplateFieldName#" value="#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#" step="1" inputmode="numeric"/>
                              <cfelseif VARIABLES.notificationTemplateIsIconField>
                                <div class="notification-template-icon-picker">
                                  <select class="form-select notification-template-icon-select js-notification-template-icon-select" data-target-input="#VARIABLES.notificationTemplateFieldName#" data-target-preview="preview_#VARIABLES.notificationTemplateFieldName#">
                                    <option value="">Selecione um ícone da biblioteca</option>
                                    <cfloop array="#VARIABLES.notificationTemplateIconOptions#" index="notificationTemplateIconOption">
                                      <option value="#htmlEditFormat(notificationTemplateIconOption.value)#" <cfif trim(VARIABLES.notificationTemplateFieldValueFormatted) EQ notificationTemplateIconOption.value>selected</cfif>>#htmlEditFormat(notificationTemplateIconOption.label)#</option>
                                    </cfloop>
                                  </select>
                                  <input class="form-control js-notification-template-icon-input" type="text" id="#VARIABLES.notificationTemplateFieldName#" name="#VARIABLES.notificationTemplateFieldName#" value="#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#" placeholder="Ex.: fa-solid fa-bell" data-preview-target="preview_#VARIABLES.notificationTemplateFieldName#"/>
                                  <div class="notification-template-icon-preview" id="preview_#VARIABLES.notificationTemplateFieldName#">
                                    <i class="<cfif len(trim(VARIABLES.notificationTemplateFieldValueFormatted))>#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#<cfelse>fa-solid fa-icons</cfif>"></i>
                                    <div class="notification-template-icon-preview-code"><cfif len(trim(VARIABLES.notificationTemplateFieldValueFormatted))>#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#<cfelse>Selecione ou informe uma classe Font Awesome usada no projeto.</cfif></div>
                                  </div>
                                </div>
                              <cfelseif VARIABLES.notificationTemplateFieldType EQ "text" OR (isNumeric(qNotificationTemplateColumns.character_maximum_length) AND qNotificationTemplateColumns.character_maximum_length GT 180)>
                                <textarea class="form-control" name="#VARIABLES.notificationTemplateFieldName#" rows="5">#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#</textarea>
                              <cfelse>
                                <input class="form-control" type="text" name="#VARIABLES.notificationTemplateFieldName#" value="#htmlEditFormat(VARIABLES.notificationTemplateFieldValueFormatted)#"/>
                              </cfif>
                            </div>
                          </div>
                        </cfoutput>
                      </cfif>
                    </cfloop>
                  </div>

                  <div class="d-flex flex-wrap gap-2 mt-3">
                    <button type="submit" class="btn btn-warning"><cfif qNotificationTemplateEdit.recordcount>Salvar alterações<cfelse>Cadastrar template</cfif></button>
                    <cfoutput><a class="btn btn-outline-secondary" href="./?pagina=#VARIABLES.notificationTemplatePage#">Cancelar</a></cfoutput>
                  </div>
                </form>
              </div>
            </cfif>

            <div class="table-responsive">
              <table class="table table-sm table-striped table-hover notification-template-table">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Campanha</th>
                    <th>Ícone</th>
                    <th>Conteúdo</th>
                    <th class="notification-template-actions-cell">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  <cfif qNotificationTemplates.recordcount>
                    <cfoutput query="qNotificationTemplates">
                      <cfset VARIABLES.notificationTemplatePkValue = qNotificationTemplates[VARIABLES.notificationTemplatePk][qNotificationTemplates.currentRow]/>
                      <cfset VARIABLES.notificationTemplateCampaignValue = ListFindNoCase(VARIABLES.notificationTemplateColumns, "campanha") ? qNotificationTemplates["campanha"][qNotificationTemplates.currentRow] : ""/>
                      <cfif ListFindNoCase(VARIABLES.notificationTemplateColumns, "icona")>
                        <cfset VARIABLES.notificationTemplateIconValue = qNotificationTemplates["icona"][qNotificationTemplates.currentRow]/>
                      <cfelseif ListFindNoCase(VARIABLES.notificationTemplateColumns, "icone")>
                        <cfset VARIABLES.notificationTemplateIconValue = qNotificationTemplates["icone"][qNotificationTemplates.currentRow]/>
                      <cfelseif ListFindNoCase(VARIABLES.notificationTemplateColumns, "icon")>
                        <cfset VARIABLES.notificationTemplateIconValue = qNotificationTemplates["icon"][qNotificationTemplates.currentRow]/>
                      <cfelse>
                        <cfset VARIABLES.notificationTemplateIconValue = ""/>
                      </cfif>
                      <cfset VARIABLES.notificationTemplateContentValue = ListFindNoCase(VARIABLES.notificationTemplateColumns, "conteudo_template") ? qNotificationTemplates["conteudo_template"][qNotificationTemplates.currentRow] : ""/>
                      <cfset VARIABLES.notificationTemplateLinkValue = ListFindNoCase(VARIABLES.notificationTemplateColumns, "link") ? qNotificationTemplates["link"][qNotificationTemplates.currentRow] : ""/>
                      <cfset VARIABLES.notificationTemplatePublicLink = ""/>
                      <cfif len(trim(VARIABLES.notificationTemplateLinkValue))>
                        <cfif left(trim(VARIABLES.notificationTemplateLinkValue), 4) EQ "http">
                          <cfset VARIABLES.notificationTemplatePublicLink = trim(VARIABLES.notificationTemplateLinkValue)/>
                        <cfelseif left(trim(VARIABLES.notificationTemplateLinkValue), 1) EQ "/">
                          <cfset VARIABLES.notificationTemplatePublicLink = "https://roadrunners.run" & trim(VARIABLES.notificationTemplateLinkValue)/>
                        <cfelse>
                          <cfset VARIABLES.notificationTemplatePublicLink = "https://roadrunners.run/" & trim(VARIABLES.notificationTemplateLinkValue)/>
                        </cfif>
                      </cfif>
                      <tr>
                        <td class="notification-template-cell">#htmlEditFormat(VARIABLES.notificationTemplatePkValue)#</td>
                        <td class="notification-template-cell">
                          <cfif len(trim(VARIABLES.notificationTemplateCampaignValue))>
                            #htmlEditFormat(VARIABLES.notificationTemplateCampaignValue)#
                          <cfelse>
                            <span class="text-muted">-</span>
                          </cfif>
                        </td>
                        <td class="notification-template-cell">
                          <cfif len(trim(VARIABLES.notificationTemplateIconValue))>
                            <span class="notification-template-list-icon" title="#htmlEditFormat(VARIABLES.notificationTemplateIconValue)#">
                              <i class="#htmlEditFormat(VARIABLES.notificationTemplateIconValue)#"></i>
                            </span>
                          <cfelse>
                            <span class="text-muted">-</span>
                          </cfif>
                        </td>
                        <td class="notification-template-cell">
                          <cfif len(trim(VARIABLES.notificationTemplateContentValue))>
                            <div class="notification-template-content-card">#VARIABLES.notificationTemplateContentValue#</div>
                          <cfelse>
                            <div class="notification-template-content-card notification-template-content-empty">Sem conteúdo.</div>
                          </cfif>
                        </td>
                        <td class="notification-template-actions-cell">
                          <div class="d-flex flex-wrap gap-2">
                            <a class="btn btn-sm btn-outline-warning" href="./?pagina=#VARIABLES.notificationTemplatePage#&template_editar=#urlEncodedFormat(VARIABLES.notificationTemplatePkValue)#">Editar</a>
                            <cfif len(trim(VARIABLES.notificationTemplatePublicLink))>
                              <a class="btn btn-sm btn-outline-info" href="#htmlEditFormat(VARIABLES.notificationTemplatePublicLink)#" target="_blank" rel="noopener noreferrer">Link</a>
                            </cfif>
                            <a class="btn btn-sm btn-outline-danger" href="./?acao=excluir&template_id=#urlEncodedFormat(VARIABLES.notificationTemplatePkValue)#&pagina=#VARIABLES.notificationTemplatePage#" onclick="return confirm('Tem certeza que deseja excluir este template de notificação?');">Excluir</a>
                          </div>
                        </td>
                      </tr>
                    </cfoutput>
                  <cfelse>
                    <tr>
                      <td colspan="99" class="text-center text-muted py-4">Nenhum template cadastrado.</td>
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

<script src="https://cdn.tiny.cloud/1/qyhsll57zrdqocv3z0c6z92ge88db2wygo5toc6fon8wtkd1/tinymce/7/tinymce.min.js" referrerpolicy="origin"></script>
<script>
  document.addEventListener('DOMContentLoaded', function () {
    if (window.tinymce && document.querySelector('.js-notification-template-editor')) {
      tinymce.init({
        selector: '.js-notification-template-editor',
        menubar: false,
        statusbar: false,
        branding: false,
        plugins: 'autoresize code',
        toolbar: 'smalltext bold italic | code',
        formats: {
          smalltext: { inline: 'small' }
        },
        setup: function (editor) {
          editor.ui.registry.addToggleButton('smalltext', {
            text: 'Pequeno',
            tooltip: 'Alternar texto pequeno',
            onAction: function () {
              editor.formatter.toggle('smalltext');
            },
            onSetup: function (api) {
              var handler = function () {
                api.setActive(editor.formatter.match('smalltext'));
              };

              editor.on('NodeChange', handler);
              return function () {
                editor.off('NodeChange', handler);
              };
            }
          });
        },
        min_height: 280,
        autoresize_bottom_margin: 16,
        content_style: 'body { font-family: Helvetica, Arial, sans-serif; font-size: 14px; }'
      });
    }

    document.querySelectorAll('.js-notification-template-icon-select').forEach(function (selectEl) {
      selectEl.addEventListener('change', function () {
        var inputEl = document.getElementById(selectEl.dataset.targetInput);
        if (!inputEl) {
          return;
        }

        if (selectEl.value) {
          inputEl.value = selectEl.value;
        }

        updateNotificationTemplateIconPreview(inputEl);
      });
    });

    document.querySelectorAll('.js-notification-template-icon-input').forEach(function (inputEl) {
      inputEl.addEventListener('input', function () {
        updateNotificationTemplateIconPreview(inputEl);
      });

      updateNotificationTemplateIconPreview(inputEl);
    });

    document.querySelectorAll('form[action*="/notificacoes/templates/"], form[action^="./?pagina="]').forEach(function (formEl) {
      formEl.addEventListener('submit', function () {
        if (window.tinymce) {
          tinymce.triggerSave();
        }
      });
    });
  });

  function updateNotificationTemplateIconPreview(inputEl) {
    var previewId = inputEl.dataset.previewTarget;
    var previewEl = previewId ? document.getElementById(previewId) : null;
    if (!previewEl) {
      return;
    }

    var iconClass = (inputEl.value || '').trim();
    var iconEl = previewEl.querySelector('i');
    var textEl = previewEl.querySelector('.notification-template-icon-preview-code');

    iconEl.className = iconClass || 'fa-solid fa-icons';
    textEl.textContent = iconClass || 'Selecione ou informe uma classe Font Awesome usada no projeto.';
  }
</script>
