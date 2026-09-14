<cfparam name="URL.pagina" default="1"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.status" default=""/>
<cfparam name="URL.publicacao" default=""/>
<cfparam name="URL.timer" default=""/>
<cfparam name="URL.cliente" default=""/>
<cfparam name="URL.periodo" default="30"/>
<cfparam name="URL.id" default=""/>
<cfparam name="URL.grupo" default=""/>
<cfparam name="URL.descarte" default=""/>
<cfparam name="FORM.result_import_queue_action" default=""/>
<cfparam name="FORM.submission_id" default=""/>
<cfparam name="FORM.result_import_queue_csrf" default=""/>

<cfset VARIABLES.resultImportError = ""/>
<cfset VARIABLES.resultImportDetailError = ""/>
<cfset VARIABLES.resultImportSchemaReady = false/>
<cfset VARIABLES.resultImportPerPage = 25/>
<cfset VARIABLES.resultImportPage = max(1, val(URL.pagina))/>
<cfset VARIABLES.resultImportSearch = left(trim(URL.busca & ""), 160)/>
<cfset VARIABLES.resultImportStatus = lCase(trim(URL.status & ""))/>
<cfset VARIABLES.resultImportPublicationStatus = lCase(trim(URL.publicacao & ""))/>
<cfset VARIABLES.resultImportTimer = left(lCase(trim(URL.timer & "")), 64)/>
<cfset VARIABLES.resultImportClient = left(lCase(trim(URL.cliente & "")), 128)/>
<cfset VARIABLES.resultImportPeriodDays = listFind("0,1,7,30,90", trim(URL.periodo & "")) ? val(URL.periodo) : 30/>
<cfset VARIABLES.resultImportSelectedId = lCase(trim(URL.id & ""))/>
<cfset VARIABLES.resultImportGroup = reFindNoCase("^[0-9a-f]{32}$", URL.grupo & "") ? lCase(URL.grupo) : ""/>
<cfset VARIABLES.resultImportTotal = 0/>
<cfset VARIABLES.resultImportTotalPages = 1/>
<cfset VARIABLES.resultImportOffset = 0/>
<cfset VARIABLES.resultImportUnscopedAccess = isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin/>
<cfset VARIABLES.resultImportScopeAccountId = isDefined("VARIABLES.businessPermissionAccountId") ? val(VARIABLES.businessPermissionAccountId) : 0/>
<cfset VARIABLES.resultImportCanProcess = businessHasPermission("result_imports.process")/>
<cfset VARIABLES.resultImportDiscardOutcome = lCase(trim(URL.descarte & ""))/>

<cfif NOT structKeyExists(SESSION, "resultImportQueueCsrf") OR NOT len(trim(SESSION.resultImportQueueCsrf & ""))>
    <cfset SESSION.resultImportQueueCsrf = lCase(hash(createUUID() & now() & getTickCount(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.resultImportQueueCsrf = SESSION.resultImportQueueCsrf/>

<cfif NOT listFindNoCase("pendente,processando,processado,falhou,cancelado,arquivado", VARIABLES.resultImportStatus)>
    <cfset VARIABLES.resultImportStatus = ""/>
</cfif>
<cfif NOT listFindNoCase("extraoficial,final,atualizacao", VARIABLES.resultImportPublicationStatus)>
    <cfset VARIABLES.resultImportPublicationStatus = ""/>
</cfif>

<cfif compareNoCase(FORM.result_import_queue_action, "descartar") EQ 0>
    <cfset VARIABLES.resultImportDiscardSubmissionId = lCase(trim(FORM.submission_id & ""))/>
    <cfset VARIABLES.resultImportDiscardSucceeded = false/>

    <cfif VARIABLES.resultImportCanProcess
        AND reFindNoCase("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", VARIABLES.resultImportDiscardSubmissionId)
        AND len(trim(FORM.result_import_queue_csrf & ""))
        AND compare(FORM.result_import_queue_csrf, VARIABLES.resultImportQueueCsrf) EQ 0>
        <cftry>
            <cfquery name="qResultImportDiscard">
                UPDATE public.tb_resultados_importacoes
                SET status_processamento = 'cancelado',
                    data_atualizacao = now()
                WHERE public_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.resultImportDiscardSubmissionId#"/> AS uuid)
                  AND status_processamento IN ('pendente', 'falhou')
                <cfif NOT VARIABLES.resultImportUnscopedAccess>
                  AND EXISTS (
                      SELECT 1
                      FROM public.tb_conta_integracoes_resultados account_integration
                      WHERE account_integration.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.resultImportScopeAccountId#"/>
                        AND account_integration.ativo = true
                        AND lower(trim(account_integration.client_id)) = lower(trim(tb_resultados_importacoes.client_id))
                        AND lower(trim(account_integration.cod_timer)) = lower(trim(tb_resultados_importacoes.cod_timer))
                        AND (
                          account_integration.abrange_contas_externas = true
                          OR nullif(trim(account_integration.external_account_id), '')
                              IS NOT DISTINCT FROM nullif(trim(tb_resultados_importacoes.external_account_id), '')
                        )
                  )
                </cfif>
                RETURNING public_id
            </cfquery>
            <cfset VARIABLES.resultImportDiscardSucceeded = qResultImportDiscard.recordcount EQ 1/>
            <cfcatch type="any">
                <cfset VARIABLES.resultImportDiscardSucceeded = false/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfset VARIABLES.resultImportDiscardRedirect = "./?periodo=" & VARIABLES.resultImportPeriodDays
        & "&pagina=" & VARIABLES.resultImportPage
        & "&status=" & encodeForURL(VARIABLES.resultImportStatus)
        & "&publicacao=" & encodeForURL(VARIABLES.resultImportPublicationStatus)
        & "&timer=" & encodeForURL(VARIABLES.resultImportTimer)
        & "&cliente=" & encodeForURL(VARIABLES.resultImportClient)
        & "&busca=" & encodeForURL(VARIABLES.resultImportSearch)
        & "&grupo=" & encodeForURL(VARIABLES.resultImportGroup)
        & "&descarte=" & (VARIABLES.resultImportDiscardSucceeded ? "ok" : "erro")/>
    <cflocation addtoken="false" url="#VARIABLES.resultImportDiscardRedirect#"/>
</cfif>

<cfset qResultImportDetail = queryNew("submission_id")/>
<cftry>
    <cfset VARIABLES.resultImportQueueService = createObject("component", "services.ResultImportQueueService")/>
    <cfset VARIABLES.resultImportData = VARIABLES.resultImportQueueService.queue({
        days=VARIABLES.resultImportPeriodDays, search=VARIABLES.resultImportSearch,
        status=VARIABLES.resultImportStatus, status_publicacao=VARIABLES.resultImportPublicationStatus,
        cod_timer=VARIABLES.resultImportTimer, client_id=VARIABLES.resultImportClient,
        event_group=VARIABLES.resultImportGroup, page=VARIABLES.resultImportPage
    }, VARIABLES.resultImportUnscopedAccess, VARIABLES.resultImportScopeAccountId)/>
    <cfset qResultImportSummary = VARIABLES.resultImportData.summary/>
    <cfset qResultImports = VARIABLES.resultImportData.rows/>
    <cfset qResultImportTimers = VARIABLES.resultImportData.timers/>
    <cfset qResultImportClients = VARIABLES.resultImportData.clients/>
    <cfset VARIABLES.resultImportTotal = VARIABLES.resultImportData.total/>
    <cfset VARIABLES.resultImportPage = VARIABLES.resultImportData.page/>
    <cfset VARIABLES.resultImportTotalPages = VARIABLES.resultImportData.pages/>
    <cfset VARIABLES.resultImportSchemaReady = true/>

    <cfif len(VARIABLES.resultImportSelectedId)>
        <cfif reFindNoCase("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", VARIABLES.resultImportSelectedId)>
            <cfset qResultImportDetail = VARIABLES.resultImportQueueService.submission(
                VARIABLES.resultImportSelectedId, VARIABLES.resultImportUnscopedAccess, VARIABLES.resultImportScopeAccountId)/>
            <cfif NOT qResultImportDetail.recordcount>
                <cfset VARIABLES.resultImportDetailError = "Submissão não encontrada."/>
            </cfif>
        <cfelse>
            <cfset VARIABLES.resultImportDetailError = "Identificador de submissão inválido."/>
        </cfif>
    </cfif>
    <cfcatch type="any">
        <cfset VARIABLES.resultImportError = "Não foi possível consultar a fila de importações: " & CFCATCH.message/>
    </cfcatch>
</cftry>
