<cfscript>
function cronJobsReadTruncatedJsonValue(required string rawResponse, required string keyName, required boolean numericValue) {
    var pattern = arguments.numericValue
        ? '"' & arguments.keyName & '"\s*:\s*-?[0-9]+(?:\.[0-9]+)?'
        : '"' & arguments.keyName & '"\s*:\s*"[^\"]*"';
    var matches = reMatchNoCase(pattern, arguments.rawResponse);
    var matchedValue = "";

    if (!arrayLen(matches)) {
        return "";
    }

    matchedValue = reReplace(matches[1], '^[^:]+:\s*', '', 'one');
    if (!arguments.numericValue) {
        matchedValue = reReplace(matchedValue, '^"|"$', '', 'all');
    }
    return matchedValue;
}

function cronJobsHistoryPageUrl(required numeric pageNumber) {
    var queryParts = [
        "pagina=" & max(1, val(URL.pagina)),
        "historico_pagina=" & max(1, val(arguments.pageNumber))
    ];
    var filterName = "";

    for (filterName in ["busca", "projeto", "ambiente", "status", "job_id"]) {
        if (structKeyExists(URL, filterName) AND len(trim(URL[filterName] & ""))) {
            arrayAppend(queryParts, urlEncodedFormat(filterName) & "=" & urlEncodedFormat(URL[filterName] & ""));
        }
    }

    return "./?" & arrayToList(queryParts, "&") & "##historico-recente";
}

function cronJobsBuildFriendlySummary(required string rawResponse, string rawError = "") {
    var result = {
        isJson = false,
        message = "",
        status = "",
        metrics = [],
        errors = [],
        raw = len(trim(arguments.rawError)) ? arguments.rawError : arguments.rawResponse
    };
    var payload = {};
    var metricDefinitions = [
        {key = "importados", label = "Importados"},
        {key = "created", label = "Criados"},
        {key = "updated", label = "Atualizados"},
        {key = "duplicados", label = "Duplicados"},
        {key = "skipped", label = "Ignorados"},
        {key = "vinculados", label = "Vinculados"},
        {key = "filtrados", label = "Filtrados"},
        {key = "ignorados", label = "Ignorados"},
        {key = "canais_processados", label = "Canais"},
        {key = "processed", label = "Processados"},
        {key = "pages", label = "Paginas"},
        {key = "executed", label = "Executados"},
        {key = "erros", label = "Erros"}
    ];
    var statusLabels = {
        ok = "Concluido",
        completed = "Concluido",
        completed_with_errors = "Concluido com erros",
        success = "Sucesso",
        skipped = "Ignorado",
        locked = "Em execucao",
        failed = "Falhou",
        error = "Erro",
        unauthorized = "Nao autorizado"
    };
    var metricDefinition = {};
    var metricValue = "";
    var errorItem = "";

    if (len(trim(arguments.rawError))) {
        result.message = trim(arguments.rawError);
        return result;
    }

    if (!len(trim(arguments.rawResponse))) {
        result.message = "Sem resposta do endpoint.";
        return result;
    }

    if (!isJSON(arguments.rawResponse)) {
        if (left(trim(arguments.rawResponse), 1) EQ "{") {
            result.message = cronJobsReadTruncatedJsonValue(arguments.rawResponse, "message", false);
            result.status = cronJobsReadTruncatedJsonValue(arguments.rawResponse, "status", false);
            for (metricDefinition in metricDefinitions) {
                metricValue = cronJobsReadTruncatedJsonValue(arguments.rawResponse, metricDefinition.key, true);
                if (len(metricValue)) {
                    if (isNumeric(metricValue) AND val(metricValue) EQ int(val(metricValue))) {
                        metricValue = int(val(metricValue));
                    }
                    arrayAppend(result.metrics, {
                        label = metricDefinition.label,
                        value = metricValue & ""
                    });
                }
            }
            if (len(result.message) OR len(result.status) OR arrayLen(result.metrics)) {
                result.isJson = true;
                if (!len(result.message)) {
                    result.message = "Resposta resumida; o JSON original foi truncado.";
                }
                return result;
            }
        }
        result.message = trim(arguments.rawResponse);
        return result;
    }

    try {
        payload = deserializeJSON(arguments.rawResponse);
        if (!isStruct(payload)) {
            result.message = trim(arguments.rawResponse);
            return result;
        }

        result.isJson = true;
        if (structKeyExists(payload, "message") AND !isNull(payload.message) AND isSimpleValue(payload.message)) {
            result.message = trim(payload.message & "");
        }
        if (structKeyExists(payload, "status") AND !isNull(payload.status) AND isSimpleValue(payload.status)) {
            result.status = trim(payload.status & "");
            if (structKeyExists(statusLabels, lCase(result.status))) {
                result.status = statusLabels[lCase(result.status)];
            }
        }

        for (metricDefinition in metricDefinitions) {
            if (!structKeyExists(payload, metricDefinition.key) OR isNull(payload[metricDefinition.key])) {
                continue;
            }

            metricValue = payload[metricDefinition.key];
            if (isArray(metricValue)) {
                if (metricDefinition.key EQ "erros") {
                    for (errorItem in metricValue) {
                        if (isSimpleValue(errorItem) AND len(trim(errorItem & ""))) {
                            arrayAppend(result.errors, trim(errorItem & ""));
                        }
                    }
                    metricValue = arrayLen(metricValue);
                } else {
                    continue;
                }
            }

            if (isSimpleValue(metricValue) AND len(trim(metricValue & ""))) {
                if (isNumeric(metricValue) AND val(metricValue) EQ int(val(metricValue))) {
                    metricValue = int(val(metricValue));
                }
                arrayAppend(result.metrics, {
                    label = metricDefinition.label,
                    value = metricValue & ""
                });
            }
        }

        if (structKeyExists(payload, "errors") AND isArray(payload.errors)) {
            for (errorItem in payload.errors) {
                if (isSimpleValue(errorItem) AND len(trim(errorItem & ""))) {
                    arrayAppend(result.errors, trim(errorItem & ""));
                }
            }
        }

        if (!len(result.message)) {
            result.message = len(result.status) ? "Execucao " & result.status & "." : "Resposta recebida.";
        }
    } catch (any summaryError) {
        result.isJson = false;
        result.message = trim(arguments.rawResponse);
    }

    return result;
}
</cfscript>

<cfset VARIABLES.cronJobsShowForm = (isDefined("URL.job_novo") AND val(URL.job_novo) EQ 1) OR qCronJobEdit.recordcount OR FORM.acao EQ "salvar_job"/>

<cfif FORM.acao EQ "salvar_job" AND len(trim(VARIABLES.cronJobsError))>
    <cfset VARIABLES.cronJobFormId = isDefined("FORM.id_cron_job") ? FORM.id_cron_job : ""/>
    <cfset VARIABLES.cronJobFormNome = isDefined("FORM.nome") ? FORM.nome : ""/>
    <cfset VARIABLES.cronJobFormDescricao = isDefined("FORM.descricao") ? FORM.descricao : ""/>
    <cfset VARIABLES.cronJobFormProjeto = isDefined("FORM.projeto") ? FORM.projeto : "business"/>
    <cfset VARIABLES.cronJobFormAmbiente = isDefined("FORM.ambiente") ? FORM.ambiente : "prod"/>
    <cfset VARIABLES.cronJobFormUrl = isDefined("FORM.endpoint_url") ? FORM.endpoint_url : ""/>
    <cfset VARIABLES.cronJobFormMethod = isDefined("FORM.http_method") ? FORM.http_method : "GET"/>
    <cfset VARIABLES.cronJobFormContentType = isDefined("FORM.content_type") ? FORM.content_type : "application/json"/>
    <cfset VARIABLES.cronJobFormBody = isDefined("FORM.request_body") ? FORM.request_body : ""/>
    <cfset VARIABLES.cronJobFormHeaders = isDefined("FORM.headers_json") ? FORM.headers_json : "{}"/>
    <cfset VARIABLES.cronJobFormAuthMode = isDefined("FORM.auth_mode") ? FORM.auth_mode : "none"/>
    <cfset VARIABLES.cronJobFormSecretRef = isDefined("FORM.secret_ref") ? FORM.secret_ref : ""/>
    <cfset VARIABLES.cronJobFormInterval = isDefined("FORM.interval_minutes") ? FORM.interval_minutes : 60/>
    <cfset VARIABLES.cronJobFormTimeout = isDefined("FORM.timeout_seconds") ? FORM.timeout_seconds : 30/>
    <cfset VARIABLES.cronJobFormRetry = isDefined("FORM.retry_limit") ? FORM.retry_limit : 0/>
    <cfset VARIABLES.cronJobFormMaxRuntime = isDefined("FORM.max_runtime_seconds") ? FORM.max_runtime_seconds : 300/>
    <cfset VARIABLES.cronJobFormNextRun = isDefined("FORM.next_run_at") ? FORM.next_run_at : ""/>
    <cfset VARIABLES.cronJobFormActive = isDefined("FORM.ativo")/>
    <cfset VARIABLES.cronJobFormLate = isDefined("FORM.executar_em_atraso")/>
<cfelseif qCronJobEdit.recordcount>
    <cfset VARIABLES.cronJobFormId = qCronJobEdit.id_cron_job/>
    <cfset VARIABLES.cronJobFormNome = qCronJobEdit.nome/>
    <cfset VARIABLES.cronJobFormDescricao = isNull(qCronJobEdit.descricao) ? "" : qCronJobEdit.descricao/>
    <cfset VARIABLES.cronJobFormProjeto = qCronJobEdit.projeto/>
    <cfset VARIABLES.cronJobFormAmbiente = qCronJobEdit.ambiente/>
    <cfset VARIABLES.cronJobFormUrl = qCronJobEdit.endpoint_url/>
    <cfset VARIABLES.cronJobFormMethod = qCronJobEdit.http_method/>
    <cfset VARIABLES.cronJobFormContentType = qCronJobEdit.content_type/>
    <cfset VARIABLES.cronJobFormBody = isNull(qCronJobEdit.request_body) ? "" : qCronJobEdit.request_body/>
    <cfset VARIABLES.cronJobFormHeaders = isNull(qCronJobEdit.headers_json) ? "{}" : (isStruct(qCronJobEdit.headers_json) ? serializeJSON(qCronJobEdit.headers_json) : qCronJobEdit.headers_json)/>
    <cfset VARIABLES.cronJobFormAuthMode = qCronJobEdit.auth_mode/>
    <cfset VARIABLES.cronJobFormSecretRef = isNull(qCronJobEdit.secret_ref) ? "" : qCronJobEdit.secret_ref/>
    <cfset VARIABLES.cronJobFormInterval = qCronJobEdit.interval_minutes/>
    <cfset VARIABLES.cronJobFormTimeout = qCronJobEdit.timeout_seconds/>
    <cfset VARIABLES.cronJobFormRetry = qCronJobEdit.retry_limit/>
    <cfset VARIABLES.cronJobFormMaxRuntime = qCronJobEdit.max_runtime_seconds/>
    <cfset VARIABLES.cronJobFormNextRun = isNull(qCronJobEdit.next_run_at) ? "" : dateTimeFormat(qCronJobEdit.next_run_at, "yyyy-mm-dd'T'HH:nn")/>
    <cfset VARIABLES.cronJobFormActive = qCronJobEdit.ativo/>
    <cfset VARIABLES.cronJobFormLate = qCronJobEdit.executar_em_atraso/>
<cfelse>
    <cfset VARIABLES.cronJobFormId = ""/>
    <cfset VARIABLES.cronJobFormNome = ""/>
    <cfset VARIABLES.cronJobFormDescricao = ""/>
    <cfset VARIABLES.cronJobFormProjeto = "business"/>
    <cfset VARIABLES.cronJobFormAmbiente = "prod"/>
    <cfset VARIABLES.cronJobFormUrl = ""/>
    <cfset VARIABLES.cronJobFormMethod = "GET"/>
    <cfset VARIABLES.cronJobFormContentType = "application/json"/>
    <cfset VARIABLES.cronJobFormBody = ""/>
    <cfset VARIABLES.cronJobFormHeaders = "{}"/>
    <cfset VARIABLES.cronJobFormAuthMode = "none"/>
    <cfset VARIABLES.cronJobFormSecretRef = ""/>
    <cfset VARIABLES.cronJobFormInterval = 60/>
    <cfset VARIABLES.cronJobFormTimeout = 30/>
    <cfset VARIABLES.cronJobFormRetry = 0/>
    <cfset VARIABLES.cronJobFormMaxRuntime = 300/>
    <cfset VARIABLES.cronJobFormNextRun = dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn")/>
    <cfset VARIABLES.cronJobFormActive = true/>
    <cfset VARIABLES.cronJobFormLate = true/>
</cfif>

<style>
  .cron-page .cron-kpis {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: .75rem;
  }

  .cron-page .cron-kpi {
    border: 1px solid rgba(255,255,255,.1);
    border-radius: .75rem;
    padding: .9rem 1rem;
    background: rgba(255,255,255,.03);
  }

  .cron-page .cron-kpi small,
  .cron-page .cron-meta {
    color: var(--mdb-secondary-color);
  }

  .cron-page .cron-url {
    max-width: 520px;
    overflow-wrap: anywhere;
    word-break: break-word;
  }

  .cron-page .cron-actions {
    white-space: nowrap;
  }

  .cron-page textarea.form-control {
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
    min-height: 110px;
  }

  .cron-page .cron-run-summary {
    min-width: 260px;
    max-width: 560px;
  }

  .cron-page .cron-run-metrics {
    display: flex;
    flex-wrap: wrap;
    gap: .3rem;
    margin-top: .4rem;
  }

  .cron-page .cron-run-metric {
    border: 1px solid rgba(255,255,255,.12);
    border-radius: 999px;
    padding: .15rem .45rem;
    white-space: nowrap;
  }

  .cron-page .cron-run-errors {
    margin: .4rem 0 0;
    padding-left: 1rem;
    color: var(--mdb-danger-text-emphasis, #ffb4b4);
  }

  .cron-page .cron-run-details summary {
    cursor: pointer;
    color: var(--mdb-secondary-color);
    margin-top: .35rem;
  }

  .cron-page .cron-run-details pre {
    max-height: 220px;
    margin: .4rem 0 0;
    padding: .6rem;
    overflow: auto;
    border-radius: .4rem;
    background: rgba(0,0,0,.25);
    color: inherit;
    white-space: pre-wrap;
    overflow-wrap: anywhere;
  }
</style>

<section class="cron-page">
  <div class="card shadow-0">
    <div class="card-body">
      <div class="d-flex flex-column flex-lg-row justify-content-between gap-3 mb-3">
        <div>
          <h3 class="mb-1">Gerenciador de Cron Jobs</h3>
          <p class="text-muted mb-0">Orquestre chamadas recorrentes para APIs do Business, Road Runners e demais serviços da plataforma.</p>
        </div>
        <div class="d-flex gap-2 align-items-start">
          <a class="btn btn-warning" href="./?job_novo=1">Novo job</a>
          <a class="btn btn-outline-light" href="/cron-jobs/runner.cfm?token=SEU_TOKEN" target="_blank" rel="noopener">Runner</a>
        </div>
      </div>

      <cfif len(trim(VARIABLES.cronJobsNotice))>
        <cfoutput><div class="alert alert-success">#htmlEditFormat(VARIABLES.cronJobsNotice)#</div></cfoutput>
      </cfif>
      <cfif len(trim(VARIABLES.cronJobsError))>
        <cfoutput><div class="alert alert-warning">#htmlEditFormat(VARIABLES.cronJobsError)#</div></cfoutput>
      </cfif>

      <cfif NOT VARIABLES.cronJobsSchemaReady>
        <div class="alert alert-info mb-0">
          Aplique o schema em <a href="/administracao/cron-jobs/cron_jobs_schema.sql" target="_blank" rel="noopener">/administracao/cron-jobs/cron_jobs_schema.sql</a> para habilitar o gerenciador.
        </div>
      <cfelse>
        <div class="cron-kpis mb-4">
          <div class="cron-kpi"><small>Total</small><div class="h3 mb-0"><cfoutput>#qCronJobStats.total_jobs#</cfoutput></div></div>
          <div class="cron-kpi"><small>Ativos</small><div class="h3 mb-0 text-success"><cfoutput>#qCronJobStats.ativos#</cfoutput></div></div>
          <div class="cron-kpi"><small>Vencidos</small><div class="h3 mb-0 text-warning"><cfoutput>#qCronJobStats.vencidos#</cfoutput></div></div>
          <div class="cron-kpi"><small>Com erro</small><div class="h3 mb-0 text-danger"><cfoutput>#qCronJobStats.erro#</cfoutput></div></div>
        </div>

        <cfif VARIABLES.cronJobsShowForm>
          <div class="border rounded-4 p-3 mb-4 bg-black bg-opacity-10">
            <h5 class="mb-3"><cfif len(trim(VARIABLES.cronJobFormId))>Editar job<cfelse>Novo job</cfif></h5>
            <form method="post" action="./">
              <input type="hidden" name="acao" value="salvar_job">
              <input type="hidden" name="id_cron_job" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormId)#</cfoutput>">

              <div class="row g-3">
                <div class="col-lg-5">
                  <label class="form-label">Nome</label>
                  <input class="form-control" name="nome" required value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormNome)#</cfoutput>">
                </div>
                <div class="col-lg-2">
                  <label class="form-label">Projeto</label>
                  <select class="form-select" name="projeto">
                    <cfloop list="business,roadrunners,conteudo,openresults,runnerhub,outro" index="cronProjectOption">
                      <cfoutput><option value="#cronProjectOption#" <cfif VARIABLES.cronJobFormProjeto EQ cronProjectOption>selected</cfif>>#cronProjectOption#</option></cfoutput>
                    </cfloop>
                  </select>
                </div>
                <div class="col-lg-2">
                  <label class="form-label">Ambiente</label>
                  <select class="form-select" name="ambiente">
                    <cfloop list="prod,beta,dev,local" index="cronEnvironmentOption">
                      <cfoutput><option value="#cronEnvironmentOption#" <cfif VARIABLES.cronJobFormAmbiente EQ cronEnvironmentOption>selected</cfif>>#cronEnvironmentOption#</option></cfoutput>
                    </cfloop>
                  </select>
                </div>
                <div class="col-lg-3">
                  <label class="form-label">Próxima execução</label>
                  <input class="form-control" type="datetime-local" name="next_run_at" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormNextRun)#</cfoutput>">
                </div>

                <div class="col-12">
                  <label class="form-label">URL da API</label>
                  <input class="form-control" name="endpoint_url" required placeholder="https://business.roadrunners.run/health/" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormUrl)#</cfoutput>">
                </div>

                <div class="col-md-2">
                  <label class="form-label">Método</label>
                  <select class="form-select" name="http_method">
                    <cfloop list="#VARIABLES.cronJobsMethodList#" index="cronMethodOption">
                      <cfoutput><option value="#cronMethodOption#" <cfif VARIABLES.cronJobFormMethod EQ cronMethodOption>selected</cfif>>#cronMethodOption#</option></cfoutput>
                    </cfloop>
                  </select>
                </div>
                <div class="col-md-4">
                  <label class="form-label">Content-Type</label>
                  <input class="form-control" name="content_type" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormContentType)#</cfoutput>">
                </div>
                <div class="col-md-2">
                  <label class="form-label">Intervalo min.</label>
                  <input class="form-control" type="number" min="1" name="interval_minutes" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormInterval)#</cfoutput>">
                </div>
                <div class="col-md-2">
                  <label class="form-label">Timeout seg.</label>
                  <input class="form-control" type="number" min="1" max="120" name="timeout_seconds" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormTimeout)#</cfoutput>">
                </div>
                <div class="col-md-2">
                  <label class="form-label">Tentativas</label>
                  <input class="form-control" type="number" min="0" max="3" name="retry_limit" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormRetry)#</cfoutput>">
                </div>

                <div class="col-md-4">
                  <label class="form-label">Autenticação</label>
                  <select class="form-select" name="auth_mode">
                    <cfloop list="#VARIABLES.cronJobsAuthModeList#" index="cronAuthOption">
                      <cfoutput><option value="#cronAuthOption#" <cfif VARIABLES.cronJobFormAuthMode EQ cronAuthOption>selected</cfif>>#cronAuthOption#</option></cfoutput>
                    </cfloop>
                  </select>
                  <div class="form-text">Use <code>hmac_sha256</code> para APIs Road Runners com handoff.</div>
                </div>
                <div class="col-md-4">
                  <label class="form-label">Secret ref</label>
                  <input class="form-control" name="secret_ref" placeholder="road_runners_handoff" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormSecretRef)#</cfoutput>">
                  <div class="form-text">Referência em <code>businessLocalConfig.cronSecrets</code>, não o segredo real.</div>
                </div>
                <div class="col-md-4">
                  <label class="form-label">Máx. runtime seg.</label>
                  <input class="form-control" type="number" min="30" name="max_runtime_seconds" value="<cfoutput>#htmlEditFormat(VARIABLES.cronJobFormMaxRuntime)#</cfoutput>">
                </div>

                <div class="col-lg-6">
                  <label class="form-label">Headers JSON</label>
                  <textarea class="form-control" name="headers_json"><cfoutput>#htmlEditFormat(VARIABLES.cronJobFormHeaders)#</cfoutput></textarea>
                </div>
                <div class="col-lg-6">
                  <label class="form-label">Body</label>
                  <textarea class="form-control" name="request_body"><cfoutput>#htmlEditFormat(VARIABLES.cronJobFormBody)#</cfoutput></textarea>
                </div>

                <div class="col-md-3">
                  <div class="form-check">
                    <input class="form-check-input" type="checkbox" name="ativo" value="1" id="cronJobAtivo" <cfif VARIABLES.cronJobFormActive>checked</cfif>>
                    <label class="form-check-label" for="cronJobAtivo">Ativo</label>
                  </div>
                </div>
                <div class="col-md-3">
                  <div class="form-check">
                    <input class="form-check-input" type="checkbox" name="executar_em_atraso" value="1" id="cronJobLate" <cfif VARIABLES.cronJobFormLate>checked</cfif>>
                    <label class="form-check-label" for="cronJobLate">Executar atrasados</label>
                  </div>
                </div>
                <div class="col-12 d-flex gap-2">
                  <button class="btn btn-warning" type="submit">Salvar job</button>
                  <a class="btn btn-outline-light" href="./">Cancelar</a>
                </div>
              </div>
            </form>
          </div>
        </cfif>

        <form class="row g-2 mb-3" method="get" action="./">
          <div class="col-lg-5">
            <input class="form-control" name="busca" placeholder="Buscar por nome ou URL" value="<cfoutput>#htmlEditFormat(URL.busca)#</cfoutput>">
          </div>
          <div class="col-lg-2">
            <input class="form-control" name="projeto" placeholder="Projeto" value="<cfoutput>#htmlEditFormat(URL.projeto)#</cfoutput>">
          </div>
          <div class="col-lg-2">
            <input class="form-control" name="ambiente" placeholder="Ambiente" value="<cfoutput>#htmlEditFormat(URL.ambiente)#</cfoutput>">
          </div>
          <div class="col-lg-2">
            <select class="form-select" name="status">
              <option value="">Todos</option>
              <option value="true" <cfif URL.status EQ "true">selected</cfif>>Ativos</option>
              <option value="false" <cfif URL.status EQ "false">selected</cfif>>Inativos</option>
            </select>
          </div>
          <div class="col-lg-1">
            <button class="btn btn-outline-light w-100" type="submit">Filtrar</button>
          </div>
        </form>

        <div class="table-responsive">
          <table class="table table-sm table-striped align-middle">
            <thead>
              <tr>
                <th>ID</th>
                <th>Job</th>
                <th>Agenda</th>
                <th>Status</th>
                <th>Última execução</th>
                <th class="text-end">Ações</th>
              </tr>
            </thead>
            <tbody>
              <cfoutput query="qCronJobs">
                <cfset VARIABLES.cronRowLastStatus = isNull(qCronJobs.last_status) ? "" : qCronJobs.last_status/>
                <cfset VARIABLES.cronRowLastHttpStatus = isNull(qCronJobs.last_http_status) ? "" : qCronJobs.last_http_status/>
                <cfset VARIABLES.cronRowLastDuration = isNull(qCronJobs.last_duration_ms) ? "" : qCronJobs.last_duration_ms/>
                <tr>
                  <td nowrap>#qCronJobs.id_cron_job#</td>
                  <td>
                    <div class="fw-semibold">#htmlEditFormat(qCronJobs.nome)#</div>
                    <div class="cron-meta">#htmlEditFormat(qCronJobs.projeto)# / #htmlEditFormat(qCronJobs.ambiente)# / #htmlEditFormat(qCronJobs.http_method)#</div>
                    <div class="small cron-url">#htmlEditFormat(qCronJobs.endpoint_url)#</div>
                  </td>
                  <td>
                    <div>A cada #qCronJobs.interval_minutes# min</div>
                    <small class="cron-meta">Próxima: <cfif isDate(qCronJobs.next_run_at)>#lsDateFormat(qCronJobs.next_run_at, "dd/mm/yyyy")# #lsTimeFormat(qCronJobs.next_run_at, "HH:mm")#<cfelse>-</cfif></small>
                  </td>
                  <td>
                    <span class="badge <cfif qCronJobs.ativo>badge-success<cfelse>badge-secondary</cfif>"><cfif qCronJobs.ativo>Ativo<cfelse>Inativo</cfif></span>
                    <cfif len(trim(VARIABLES.cronRowLastStatus))>
                      <span class="badge <cfif VARIABLES.cronRowLastStatus EQ 'success'>badge-success<cfelseif VARIABLES.cronRowLastStatus EQ 'http_error'>badge-warning text-dark<cfelse>badge-danger</cfif>">#htmlEditFormat(VARIABLES.cronRowLastStatus)#</span>
                    </cfif>
                  </td>
                  <td>
                    <cfif isDate(qCronJobs.last_run_at)>
                      #lsDateFormat(qCronJobs.last_run_at, "dd/mm/yyyy")# #lsTimeFormat(qCronJobs.last_run_at, "HH:mm")#
                      <small class="cron-meta d-block">#htmlEditFormat(VARIABLES.cronRowLastHttpStatus)# <cfif len(trim(VARIABLES.cronRowLastDuration))>#VARIABLES.cronRowLastDuration#ms</cfif></small>
                    <cfelse>
                      <span class="text-muted">-</span>
                    </cfif>
                  </td>
                  <td class="text-end cron-actions">
                    <a class="btn btn-sm btn-outline-light" href="./?job_id=#qCronJobs.id_cron_job#" title="Editar"><i class="fa-solid fa-pen"></i></a>
                    <a class="btn btn-sm btn-outline-info" href="./?acao=executar&job_id=#qCronJobs.id_cron_job#" title="Executar agora"><i class="fa-solid fa-play"></i></a>
                    <a class="btn btn-sm <cfif qCronJobs.ativo>btn-outline-warning<cfelse>btn-outline-success</cfif>" href="./?acao=status&job_id=#qCronJobs.id_cron_job#&ativo=<cfif qCronJobs.ativo>false<cfelse>true</cfif>" title="<cfif qCronJobs.ativo>Pausar<cfelse>Ativar</cfif>"><i class="fa-solid <cfif qCronJobs.ativo>fa-pause<cfelse>fa-toggle-on</cfif>"></i></a>
                    <a class="btn btn-sm btn-outline-danger" href="./?acao=excluir&job_id=#qCronJobs.id_cron_job#" onclick="return confirm('Remover este cron job e seu historico?');" title="Excluir"><i class="fa-solid fa-trash"></i></a>
                  </td>
                </tr>
              </cfoutput>
              <cfif NOT qCronJobs.recordcount>
                <tr><td colspan="6" class="text-center text-muted py-4">Nenhum job encontrado.</td></tr>
              </cfif>
            </tbody>
          </table>
        </div>

        <div class="mt-4" id="historico-recente">
          <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-2 mb-2">
            <h5 class="mb-0">Histórico recente</h5>
            <div class="small cron-meta">
              <cfoutput>#VARIABLES.cronHistoryTotal# execuções &middot; Página #VARIABLES.cronHistoryPage# de #VARIABLES.cronHistoryTotalPages#</cfoutput>
            </div>
          </div>
          <div class="table-responsive">
            <table class="table table-sm table-hover align-middle">
              <thead>
                <tr>
                  <th>Data</th>
                  <th>Job</th>
                  <th>Origem</th>
                  <th>Status</th>
                  <th>HTTP</th>
                  <th>Duração</th>
                  <th>Resumo</th>
                </tr>
              </thead>
              <tbody>
                <cfoutput query="qCronJobRuns">
                  <cfset VARIABLES.cronRunHttpStatus = isNull(qCronJobRuns.http_status) ? "" : qCronJobRuns.http_status/>
                  <cfset VARIABLES.cronRunDuration = isNull(qCronJobRuns.duration_ms) ? "" : qCronJobRuns.duration_ms/>
                  <cfset VARIABLES.cronRunError = isNull(qCronJobRuns.error_message) ? "" : qCronJobRuns.error_message/>
                  <cfset VARIABLES.cronRunResponse = isNull(qCronJobRuns.response_preview) ? "" : qCronJobRuns.response_preview/>
                  <cfif qCronJobRuns.status EQ "running">
                    <cfset VARIABLES.cronRunSummary = {
                      message = "Execucao em andamento.",
                      status = "running",
                      metrics = [],
                      errors = [],
                      raw = "",
                      isJson = false
                    }/>
                  <cfelse>
                    <cfset VARIABLES.cronRunSummary = cronJobsBuildFriendlySummary(VARIABLES.cronRunResponse, VARIABLES.cronRunError)/>
                  </cfif>
                  <tr>
                    <td nowrap>#lsDateFormat(qCronJobRuns.started_at, "dd/mm/yyyy")# #lsTimeFormat(qCronJobRuns.started_at, "HH:mm:ss")#</td>
                    <td>#htmlEditFormat(qCronJobRuns.nome)#</td>
                    <td>#htmlEditFormat(qCronJobRuns.trigger_type)#</td>
                    <td><span class="badge <cfif qCronJobRuns.status EQ 'success'>badge-success<cfelseif qCronJobRuns.status EQ 'http_error'>badge-warning text-dark<cfelse>badge-danger</cfif>">#htmlEditFormat(qCronJobRuns.status)#</span></td>
                    <td>#htmlEditFormat(VARIABLES.cronRunHttpStatus)#</td>
                    <td><cfif len(trim(VARIABLES.cronRunDuration))>#VARIABLES.cronRunDuration#ms<cfelse>-</cfif></td>
                    <td class="small">
                      <div class="cron-run-summary">
                        <div class="fw-semibold">#htmlEditFormat(VARIABLES.cronRunSummary.message)#</div>
                        <div class="cron-run-metrics">
                          <cfif len(VARIABLES.cronRunSummary.status)>
                            <span class="cron-run-metric">Status: #htmlEditFormat(VARIABLES.cronRunSummary.status)#</span>
                          </cfif>
                          <cfloop array="#VARIABLES.cronRunSummary.metrics#" item="cronRunMetric">
                            <span class="cron-run-metric">#htmlEditFormat(cronRunMetric.label)#: <strong>#htmlEditFormat(cronRunMetric.value)#</strong></span>
                          </cfloop>
                        </div>
                        <cfif arrayLen(VARIABLES.cronRunSummary.errors)>
                          <ul class="cron-run-errors">
                            <cfloop from="1" to="#min(2, arrayLen(VARIABLES.cronRunSummary.errors))#" index="cronRunErrorIndex">
                              <li>#htmlEditFormat(VARIABLES.cronRunSummary.errors[cronRunErrorIndex])#</li>
                            </cfloop>
                          </ul>
                        </cfif>
                        <cfif len(trim(VARIABLES.cronRunSummary.raw)) AND VARIABLES.cronRunSummary.isJson>
                          <details class="cron-run-details">
                            <summary>Ver resposta completa</summary>
                            <pre>#htmlEditFormat(VARIABLES.cronRunSummary.raw)#</pre>
                          </details>
                        </cfif>
                      </div>
                    </td>
                  </tr>
                </cfoutput>
                <cfif NOT qCronJobRuns.recordcount>
                  <tr><td colspan="7" class="text-center text-muted py-4">Nenhuma execução registrada.</td></tr>
                </cfif>
              </tbody>
            </table>
          </div>
          <cfif VARIABLES.cronHistoryTotalPages GT 1>
            <cfset VARIABLES.cronHistoryPageStart = max(1, VARIABLES.cronHistoryPage - 2)/>
            <cfset VARIABLES.cronHistoryPageEnd = min(VARIABLES.cronHistoryTotalPages, VARIABLES.cronHistoryPage + 2)/>
            <nav class="mt-3" aria-label="Paginação do histórico de cron jobs">
              <ul class="pagination pagination-sm justify-content-end mb-0">
                <li class="page-item <cfif VARIABLES.cronHistoryPage LTE 1>disabled</cfif>">
                  <cfif VARIABLES.cronHistoryPage GT 1>
                    <cfoutput><a class="page-link" href="#cronJobsHistoryPageUrl(VARIABLES.cronHistoryPage - 1)#" aria-label="Página anterior">Anterior</a></cfoutput>
                  <cfelse>
                    <span class="page-link">Anterior</span>
                  </cfif>
                </li>
                <cfif VARIABLES.cronHistoryPageStart GT 1>
                  <cfoutput><li class="page-item"><a class="page-link" href="#cronJobsHistoryPageUrl(1)#">1</a></li></cfoutput>
                  <cfif VARIABLES.cronHistoryPageStart GT 2><li class="page-item disabled"><span class="page-link">&hellip;</span></li></cfif>
                </cfif>
                <cfloop from="#VARIABLES.cronHistoryPageStart#" to="#VARIABLES.cronHistoryPageEnd#" index="cronHistoryPageNumber">
                  <cfoutput>
                    <li class="page-item <cfif cronHistoryPageNumber EQ VARIABLES.cronHistoryPage>active</cfif>">
                      <a class="page-link" href="#cronJobsHistoryPageUrl(cronHistoryPageNumber)#">#cronHistoryPageNumber#</a>
                    </li>
                  </cfoutput>
                </cfloop>
                <cfif VARIABLES.cronHistoryPageEnd LT VARIABLES.cronHistoryTotalPages>
                  <cfif VARIABLES.cronHistoryPageEnd LT VARIABLES.cronHistoryTotalPages - 1><li class="page-item disabled"><span class="page-link">&hellip;</span></li></cfif>
                  <cfoutput><li class="page-item"><a class="page-link" href="#cronJobsHistoryPageUrl(VARIABLES.cronHistoryTotalPages)#">#VARIABLES.cronHistoryTotalPages#</a></li></cfoutput>
                </cfif>
                <li class="page-item <cfif VARIABLES.cronHistoryPage GTE VARIABLES.cronHistoryTotalPages>disabled</cfif>">
                  <cfif VARIABLES.cronHistoryPage LT VARIABLES.cronHistoryTotalPages>
                    <cfoutput><a class="page-link" href="#cronJobsHistoryPageUrl(VARIABLES.cronHistoryPage + 1)#" aria-label="Próxima página">Próxima</a></cfoutput>
                  <cfelse>
                    <span class="page-link">Próxima</span>
                  </cfif>
                </li>
              </ul>
            </nav>
          </cfif>
        </div>
      </cfif>
    </div>
  </div>
</section>
