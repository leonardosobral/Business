<cfinclude template="../../../includes/backend/cron_jobs_service.cfm"/>

<cfparam name="URL.pagina" default="1"/>
<cfparam name="URL.historico_pagina" default="1"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.projeto" default=""/>
<cfparam name="URL.ambiente" default=""/>
<cfparam name="URL.status" default=""/>
<cfparam name="URL.aba" default="jobs"/>
<cfparam name="URL.historico_status" default=""/>
<cfparam name="URL.historico_job_id" default=""/>
<cfparam name="URL.job_id" default=""/>
<cfparam name="URL.sucesso" default=""/>
<cfparam name="FORM.acao" default=""/>

<cfset VARIABLES.cronJobsPage = max(1, val(URL.pagina))/>
<cfset VARIABLES.cronJobsPerPage = 25/>
<cfset VARIABLES.cronJobsOffset = (VARIABLES.cronJobsPage - 1) * VARIABLES.cronJobsPerPage/>
<cfset VARIABLES.cronHistoryPage = max(1, val(URL.historico_pagina))/>
<cfset VARIABLES.cronHistoryPerPage = 15/>
<cfset VARIABLES.cronHistoryOffset = (VARIABLES.cronHistoryPage - 1) * VARIABLES.cronHistoryPerPage/>
<cfset VARIABLES.cronHistoryTotal = 0/>
<cfset VARIABLES.cronHistoryTotalPages = 1/>
<cfset VARIABLES.cronJobsNotice = ""/>
<cfset VARIABLES.cronJobsError = ""/>
<cfset VARIABLES.cronJobsSchemaReady = cronJobsTablesReady()/>
<cfset VARIABLES.cronJobsActiveTab = lCase(trim(URL.aba))/>
<cfif NOT listFindNoCase("jobs,historico,erros", VARIABLES.cronJobsActiveTab)>
    <cfset VARIABLES.cronJobsActiveTab = "jobs"/>
</cfif>
<cfset VARIABLES.cronJobsStatusFilter = lCase(trim(URL.status))/>
<cfif NOT listFindNoCase("true,false,erro,error,http_error,failed,timeout,sucesso,success,vencidos,atrasados", VARIABLES.cronJobsStatusFilter)>
    <cfset VARIABLES.cronJobsStatusFilter = ""/>
</cfif>
<cfset VARIABLES.cronHistoryStatusFilter = lCase(trim(URL.historico_status))/>
<cfif VARIABLES.cronJobsActiveTab EQ "erros">
    <cfset VARIABLES.cronHistoryStatusFilter = "erro"/>
</cfif>
<cfif NOT listFindNoCase("erro,error,http_error,failed,timeout,sucesso,success,running", VARIABLES.cronHistoryStatusFilter)>
    <cfset VARIABLES.cronHistoryStatusFilter = ""/>
</cfif>
<cfset VARIABLES.cronJobsCanAdmin = false/>
<cfif isDefined("qPerfil") AND qPerfil.recordcount AND NOT isNull(qPerfil.is_admin)>
    <cfset VARIABLES.cronJobsCanAdmin = isBoolean(qPerfil.is_admin) ? qPerfil.is_admin : listFindNoCase("true,t,1,yes,sim", trim(qPerfil.is_admin))/>
</cfif>
<cfset VARIABLES.cronJobsMethodList = "GET,POST,PUT,PATCH,DELETE"/>
<cfset VARIABLES.cronJobsAuthModeList = "none,bearer,api_key_header,api_key_query,hmac_sha256"/>
<cfset qCronJobs = queryNew("id_cron_job,nome,descricao,projeto,ambiente,endpoint_url,http_method,content_type,request_body,headers_json,auth_mode,secret_ref,interval_minutes,timeout_seconds,retry_limit,ativo,executar_em_atraso,max_runtime_seconds,last_run_at,next_run_at,last_status,last_http_status,last_duration_ms,last_error,data_criacao,data_atualizacao")/>
<cfset qCronJobEdit = queryNew("id_cron_job,nome,descricao,projeto,ambiente,endpoint_url,http_method,content_type,request_body,headers_json,auth_mode,secret_ref,interval_minutes,timeout_seconds,retry_limit,ativo,executar_em_atraso,max_runtime_seconds,last_run_at,next_run_at,last_status,last_http_status,last_duration_ms,last_error,data_criacao,data_atualizacao")/>
<cfset qCronJobRuns = queryNew("id_cron_job_run,id_cron_job,nome,trigger_type,attempt,started_at,finished_at,duration_ms,status,http_status,response_preview,error_message,endpoint_url")/>

<cfif cronJobsTablesReady()>
    <cfset cronJobsReconcileStaleRuns()/>
</cfif>
<cfset qCronJobStats = queryNew("total_jobs,ativos,inativos,vencidos,sucesso,erro")/>
<cfset qCronJobRunStats = queryNew("total_runs,sucesso,erro,running,ultimas_24h")/>
<cfset VARIABLES.cronJobsTotal = 0/>
<cfset VARIABLES.cronJobsTotalPages = 1/>

<cfif NOT VARIABLES.cronJobsCanAdmin>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfif URL.sucesso EQ "salvo">
    <cfset VARIABLES.cronJobsNotice = "Job salvo com sucesso."/>
<cfelseif URL.sucesso EQ "status">
    <cfset VARIABLES.cronJobsNotice = "Status atualizado com sucesso."/>
<cfelseif URL.sucesso EQ "excluido">
    <cfset VARIABLES.cronJobsNotice = "Job excluido com sucesso."/>
<cfelseif URL.sucesso EQ "executado">
    <cfset VARIABLES.cronJobsNotice = "Execucao manual solicitada. Confira o historico abaixo."/>
</cfif>

<cfif NOT VARIABLES.cronJobsSchemaReady>
    <cfset VARIABLES.cronJobsError = "As tabelas de cron jobs ainda nao existem. Aplique o script /administracao/cron-jobs/cron_jobs_schema.sql."/>
<cfelse>
    <cfif isDefined("URL.acao") AND URL.acao EQ "status" AND isNumeric(URL.job_id) AND isDefined("URL.ativo")>
        <cfquery>
            UPDATE tb_cron_jobs
            SET ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#URL.ativo#"/>,
                data_atualizacao = now(),
                id_usuario_atualizacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
            WHERE id_cron_job = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.job_id#"/>
        </cfquery>
        <cflocation addtoken="false" url="./?sucesso=status"/>
    </cfif>

    <cfif isDefined("URL.acao") AND URL.acao EQ "excluir" AND isNumeric(URL.job_id)>
        <cfquery>
            DELETE FROM tb_cron_jobs
            WHERE id_cron_job = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.job_id#"/>
        </cfquery>
        <cflocation addtoken="false" url="./?sucesso=excluido"/>
    </cfif>

    <cfif isDefined("URL.acao") AND URL.acao EQ "executar" AND isNumeric(URL.job_id)>
        <cfset VARIABLES.cronJobsRunResult = cronJobsRunJob(val(URL.job_id), "manual", qPerfil.id)/>
        <cflocation addtoken="false" url="./?sucesso=executado&job_id=#val(URL.job_id)#"/>
    </cfif>

    <cfif FORM.acao EQ "salvar_job">
        <cfset VARIABLES.cronJobId = isDefined("FORM.id_cron_job") ? trim(FORM.id_cron_job) : ""/>
        <cfset VARIABLES.cronJobNome = isDefined("FORM.nome") ? trim(FORM.nome) : ""/>
        <cfset VARIABLES.cronJobDescricao = isDefined("FORM.descricao") ? trim(FORM.descricao) : ""/>
        <cfset VARIABLES.cronJobProjeto = isDefined("FORM.projeto") ? lCase(trim(FORM.projeto)) : "business"/>
        <cfset VARIABLES.cronJobAmbiente = isDefined("FORM.ambiente") ? lCase(trim(FORM.ambiente)) : "prod"/>
        <cfset VARIABLES.cronJobUrl = isDefined("FORM.endpoint_url") ? trim(FORM.endpoint_url) : ""/>
        <cfset VARIABLES.cronJobMethod = isDefined("FORM.http_method") ? uCase(trim(FORM.http_method)) : "GET"/>
        <cfset VARIABLES.cronJobContentType = isDefined("FORM.content_type") ? trim(FORM.content_type) : "application/json"/>
        <cfset VARIABLES.cronJobBody = isDefined("FORM.request_body") ? trim(FORM.request_body) : ""/>
        <cfset VARIABLES.cronJobHeaders = isDefined("FORM.headers_json") ? trim(FORM.headers_json) : "{}"/>
        <cfset VARIABLES.cronJobAuthMode = isDefined("FORM.auth_mode") ? lCase(trim(FORM.auth_mode)) : "none"/>
        <cfset VARIABLES.cronJobSecretRef = isDefined("FORM.secret_ref") ? trim(FORM.secret_ref) : ""/>
        <cfset VARIABLES.cronJobInterval = isDefined("FORM.interval_minutes") ? max(1, val(FORM.interval_minutes)) : 60/>
        <cfset VARIABLES.cronJobTimeout = isDefined("FORM.timeout_seconds") ? min(120, max(1, val(FORM.timeout_seconds))) : 30/>
        <cfset VARIABLES.cronJobRetryLimit = isDefined("FORM.retry_limit") ? min(3, max(0, val(FORM.retry_limit))) : 0/>
        <cfset VARIABLES.cronJobMaxRuntime = isDefined("FORM.max_runtime_seconds") ? max(30, val(FORM.max_runtime_seconds)) : 300/>
        <cfset VARIABLES.cronJobActive = isDefined("FORM.ativo")/>
        <cfset VARIABLES.cronJobExecuteLate = isDefined("FORM.executar_em_atraso")/>
        <cfset VARIABLES.cronJobNextRun = isDefined("FORM.next_run_at") ? trim(FORM.next_run_at) : ""/>
        <cfset VARIABLES.cronJobNextRunValue = now()/>
        <cfset VARIABLES.cronJobHeadersParsed = {}/>
        <cfset VARIABLES.cronJobErrors = []/>

        <cfif NOT len(VARIABLES.cronJobNome)>
            <cfset arrayAppend(VARIABLES.cronJobErrors, "Informe o nome do job.")/>
        </cfif>
        <cfif NOT len(VARIABLES.cronJobUrl) OR NOT reFindNoCase("^https?://", VARIABLES.cronJobUrl)>
            <cfset arrayAppend(VARIABLES.cronJobErrors, "Informe uma URL absoluta http/https.")/>
        </cfif>
        <cfif NOT listFindNoCase(VARIABLES.cronJobsMethodList, VARIABLES.cronJobMethod)>
            <cfset arrayAppend(VARIABLES.cronJobErrors, "Metodo HTTP invalido.")/>
        </cfif>
        <cfif NOT listFindNoCase(VARIABLES.cronJobsAuthModeList, VARIABLES.cronJobAuthMode)>
            <cfset arrayAppend(VARIABLES.cronJobErrors, "Modo de autenticacao invalido.")/>
        </cfif>
        <cfif VARIABLES.cronJobAuthMode NEQ "none" AND NOT len(VARIABLES.cronJobSecretRef)>
            <cfset arrayAppend(VARIABLES.cronJobErrors, "Informe a referencia do segredo para este modo de autenticacao.")/>
        </cfif>
        <cfif NOT len(VARIABLES.cronJobHeaders)>
            <cfset VARIABLES.cronJobHeaders = "{}"/>
        </cfif>
        <cftry>
            <cfset VARIABLES.cronJobHeadersParsed = deserializeJSON(VARIABLES.cronJobHeaders)/>
            <cfif NOT isStruct(VARIABLES.cronJobHeadersParsed)>
                <cfset arrayAppend(VARIABLES.cronJobErrors, "Headers deve ser um JSON de objeto.")/>
            </cfif>
            <cfcatch>
                <cfset arrayAppend(VARIABLES.cronJobErrors, "Headers deve ser um JSON de objeto.")/>
            </cfcatch>
        </cftry>
        <cfif len(VARIABLES.cronJobBody) AND left(lCase(trim(VARIABLES.cronJobContentType)), 16) EQ "application/json" AND NOT isJSON(VARIABLES.cronJobBody)>
            <cfset arrayAppend(VARIABLES.cronJobErrors, "Body deve ser JSON valido quando Content-Type for application/json.")/>
        </cfif>
        <cfif len(VARIABLES.cronJobNextRun) AND NOT isDate(replace(VARIABLES.cronJobNextRun, "T", " ", "one"))>
            <cfset arrayAppend(VARIABLES.cronJobErrors, "Proxima execucao invalida.")/>
        </cfif>
        <cfif len(VARIABLES.cronJobNextRun) AND isDate(replace(VARIABLES.cronJobNextRun, "T", " ", "one"))>
            <cfset VARIABLES.cronJobNextRunValue = parseDateTime(replace(VARIABLES.cronJobNextRun, "T", " ", "one"))/>
        </cfif>

        <cfif arrayLen(VARIABLES.cronJobErrors)>
            <cfset VARIABLES.cronJobsError = arrayToList(VARIABLES.cronJobErrors, " ")/>
        <cfelseif len(VARIABLES.cronJobId) AND isNumeric(VARIABLES.cronJobId)>
            <cfquery>
                UPDATE tb_cron_jobs
                SET nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobNome#"/>,
                    descricao = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cronJobDescricao#" null="#NOT len(VARIABLES.cronJobDescricao)#"/>,
                    projeto = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobProjeto#"/>,
                    ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobAmbiente#"/>,
                    endpoint_url = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cronJobUrl#"/>,
                    http_method = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobMethod#"/>,
                    content_type = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobContentType#"/>,
                    request_body = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cronJobBody#" null="#NOT len(VARIABLES.cronJobBody)#"/>,
                    headers_json = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cronJobHeaders#"/>::jsonb,
                    auth_mode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobAuthMode#"/>,
                    secret_ref = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobSecretRef#" null="#NOT len(VARIABLES.cronJobSecretRef)#"/>,
                    interval_minutes = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobInterval#"/>,
                    timeout_seconds = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobTimeout#"/>,
                    retry_limit = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobRetryLimit#"/>,
                    ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.cronJobActive#"/>,
                    executar_em_atraso = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.cronJobExecuteLate#"/>,
                    max_runtime_seconds = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobMaxRuntime#"/>,
                    next_run_at = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.cronJobNextRunValue#"/>,
                    data_atualizacao = now(),
                    id_usuario_atualizacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
                WHERE id_cron_job = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cronJobId#"/>
            </cfquery>
            <cflocation addtoken="false" url="./?sucesso=salvo&job_id=#VARIABLES.cronJobId#"/>
        <cfelse>
            <cfquery name="qCronJobInsert">
                INSERT INTO tb_cron_jobs
                    (nome, descricao, projeto, ambiente, endpoint_url, http_method, content_type, request_body, headers_json, auth_mode, secret_ref, interval_minutes, timeout_seconds, retry_limit, ativo, executar_em_atraso, max_runtime_seconds, next_run_at, id_usuario_criacao, id_usuario_atualizacao)
                VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobNome#"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cronJobDescricao#" null="#NOT len(VARIABLES.cronJobDescricao)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobProjeto#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobAmbiente#"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cronJobUrl#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobMethod#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobContentType#"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cronJobBody#" null="#NOT len(VARIABLES.cronJobBody)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.cronJobHeaders#"/>::jsonb,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobAuthMode#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cronJobSecretRef#" null="#NOT len(VARIABLES.cronJobSecretRef)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobInterval#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobTimeout#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobRetryLimit#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.cronJobActive#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.cronJobExecuteLate#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobMaxRuntime#"/>,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.cronJobNextRunValue#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
                    )
                RETURNING id_cron_job
            </cfquery>
            <cflocation addtoken="false" url="./?sucesso=salvo&job_id=#qCronJobInsert.id_cron_job#"/>
        </cfif>
    </cfif>

    <cfif isNumeric(URL.job_id)>
        <cfquery name="qCronJobEdit">
            SELECT *
            FROM tb_cron_jobs
            WHERE id_cron_job = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.job_id#"/>
            LIMIT 1
        </cfquery>
    </cfif>

    <cfquery name="qCronJobStats">
        SELECT count(*) AS total_jobs,
               count(*) FILTER (WHERE ativo) AS ativos,
               count(*) FILTER (WHERE NOT ativo) AS inativos,
               count(*) FILTER (WHERE ativo AND next_run_at <= now()) AS vencidos,
               count(*) FILTER (WHERE last_status = 'success') AS sucesso,
               count(*) FILTER (WHERE lower(trim(coalesce(last_status, ''))) IN ('error', 'http_error', 'failed', 'timeout')) AS erro
        FROM tb_cron_jobs
    </cfquery>

    <cfquery name="qCronJobsCount">
        SELECT count(*) AS total
        FROM tb_cron_jobs
        WHERE 1 = 1
        <cfif len(trim(URL.busca))>
            AND (nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
              OR endpoint_url ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>)
        </cfif>
        <cfif len(trim(URL.projeto))>
            AND projeto = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.projeto)#"/>
        </cfif>
        <cfif len(trim(URL.ambiente))>
            AND ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.ambiente)#"/>
        </cfif>
        <cfif VARIABLES.cronJobsStatusFilter EQ "true" OR VARIABLES.cronJobsStatusFilter EQ "false">
            AND ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.cronJobsStatusFilter#"/>
        <cfelseif listFindNoCase("erro,error,http_error,failed,timeout", VARIABLES.cronJobsStatusFilter)>
            AND lower(trim(coalesce(last_status, ''))) IN ('error', 'http_error', 'failed', 'timeout')
        <cfelseif listFindNoCase("sucesso,success", VARIABLES.cronJobsStatusFilter)>
            AND last_status = 'success'
        <cfelseif listFindNoCase("vencidos,atrasados", VARIABLES.cronJobsStatusFilter)>
            AND ativo = true
            AND next_run_at <= now()
        </cfif>
    </cfquery>
    <cfset VARIABLES.cronJobsTotal = qCronJobsCount.total/>
    <cfset VARIABLES.cronJobsTotalPages = max(1, ceiling(VARIABLES.cronJobsTotal / VARIABLES.cronJobsPerPage))/>
    <cfset VARIABLES.cronJobsPage = min(VARIABLES.cronJobsPage, VARIABLES.cronJobsTotalPages)/>
    <cfset VARIABLES.cronJobsOffset = (VARIABLES.cronJobsPage - 1) * VARIABLES.cronJobsPerPage/>

    <cfquery name="qCronJobs">
        SELECT *
        FROM tb_cron_jobs
        WHERE 1 = 1
        <cfif len(trim(URL.busca))>
            AND (nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>
              OR endpoint_url ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#trim(URL.busca)#%"/>)
        </cfif>
        <cfif len(trim(URL.projeto))>
            AND projeto = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.projeto)#"/>
        </cfif>
        <cfif len(trim(URL.ambiente))>
            AND ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(URL.ambiente)#"/>
        </cfif>
        <cfif VARIABLES.cronJobsStatusFilter EQ "true" OR VARIABLES.cronJobsStatusFilter EQ "false">
            AND ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.cronJobsStatusFilter#"/>
        <cfelseif listFindNoCase("erro,error,http_error,failed,timeout", VARIABLES.cronJobsStatusFilter)>
            AND lower(trim(coalesce(last_status, ''))) IN ('error', 'http_error', 'failed', 'timeout')
        <cfelseif listFindNoCase("sucesso,success", VARIABLES.cronJobsStatusFilter)>
            AND last_status = 'success'
        <cfelseif listFindNoCase("vencidos,atrasados", VARIABLES.cronJobsStatusFilter)>
            AND ativo = true
            AND next_run_at <= now()
        </cfif>
        ORDER BY ativo DESC, next_run_at ASC, id_cron_job DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobsPerPage#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronJobsOffset#"/>
    </cfquery>

    <cfquery name="qCronJobRunStats">
        SELECT count(*) AS total_runs,
               count(*) FILTER (WHERE lower(trim(coalesce(status, ''))) = 'success') AS sucesso,
               count(*) FILTER (WHERE lower(trim(coalesce(status, ''))) IN ('error', 'http_error', 'failed', 'timeout')) AS erro,
               count(*) FILTER (WHERE lower(trim(coalesce(status, ''))) = 'running') AS running,
               count(*) FILTER (WHERE started_at >= now() - interval '24 hours') AS ultimas_24h
        FROM tb_cron_job_runs
    </cfquery>

    <cfquery name="qCronJobRunsCount">
        SELECT count(*) AS total
        FROM tb_cron_job_runs run
        WHERE 1 = 1
        <cfif isNumeric(URL.historico_job_id)>
            AND run.id_cron_job = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.historico_job_id#"/>
        </cfif>
        <cfif listFindNoCase("erro,error,http_error,failed,timeout", VARIABLES.cronHistoryStatusFilter)>
            AND lower(trim(coalesce(run.status, ''))) IN ('error', 'http_error', 'failed', 'timeout')
        <cfelseif listFindNoCase("sucesso,success", VARIABLES.cronHistoryStatusFilter)>
            AND lower(trim(coalesce(run.status, ''))) = 'success'
        <cfelseif VARIABLES.cronHistoryStatusFilter EQ "running">
            AND lower(trim(coalesce(run.status, ''))) = 'running'
        </cfif>
    </cfquery>
    <cfset VARIABLES.cronHistoryTotal = qCronJobRunsCount.total/>
    <cfset VARIABLES.cronHistoryTotalPages = max(1, ceiling(VARIABLES.cronHistoryTotal / VARIABLES.cronHistoryPerPage))/>
    <cfset VARIABLES.cronHistoryPage = min(VARIABLES.cronHistoryPage, VARIABLES.cronHistoryTotalPages)/>
    <cfset VARIABLES.cronHistoryOffset = (VARIABLES.cronHistoryPage - 1) * VARIABLES.cronHistoryPerPage/>

    <cfquery name="qCronJobRuns">
        SELECT run.*,
               job.nome
        FROM tb_cron_job_runs run
        INNER JOIN tb_cron_jobs job ON job.id_cron_job = run.id_cron_job
        WHERE 1 = 1
        <cfif isNumeric(URL.historico_job_id)>
            AND run.id_cron_job = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.historico_job_id#"/>
        </cfif>
        <cfif listFindNoCase("erro,error,http_error,failed,timeout", VARIABLES.cronHistoryStatusFilter)>
            AND lower(trim(coalesce(run.status, ''))) IN ('error', 'http_error', 'failed', 'timeout')
        <cfelseif listFindNoCase("sucesso,success", VARIABLES.cronHistoryStatusFilter)>
            AND lower(trim(coalesce(run.status, ''))) = 'success'
        <cfelseif VARIABLES.cronHistoryStatusFilter EQ "running">
            AND lower(trim(coalesce(run.status, ''))) = 'running'
        </cfif>
        ORDER BY run.started_at DESC, run.id_cron_job_run DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronHistoryPerPage#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cronHistoryOffset#"/>
    </cfquery>
</cfif>
