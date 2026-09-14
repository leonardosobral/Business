<cfparam name="URL.submission_id" default=""/>
<cfparam name="FORM.submission_id" default=""/>
<cfparam name="FORM.action" default=""/>
<cfparam name="FORM.url_resultado" default=""/>
<cfparam name="FORM.url_resultado_publica" default=""/>
<cfparam name="FORM.url_racetag" default=""/>
<cfparam name="FORM.cod_evento" default=""/>
<cfparam name="FORM.external_event_id" default=""/>
<cfparam name="FORM.path_evento" default=""/>
<cfparam name="FORM.id_evento" default=""/>
<cfparam name="FORM.result_import_csrf" default=""/>
<cfparam name="FORM.open_results_override" default=""/>

<cfset VARIABLES.raceTagError = ""/>
<cfset VARIABLES.raceTagNotice = ""/>
<cfset VARIABLES.raceTagSubmissionId = lCase(trim(len(FORM.submission_id) ? FORM.submission_id : URL.submission_id)) />
<cfset VARIABLES.raceTagSubmissionReady = false/>
<cfset VARIABLES.raceTagSubmissionCanProcess = true/>
<cfset VARIABLES.raceTagPayloadIntentAvailable = false/>
<cfset VARIABLES.raceTagPayloadOpenResultsEnabled = true/>
<cfset VARIABLES.raceTagUnscopedAccess = isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin/>
<cfset VARIABLES.raceTagScopeAccountId = isDefined("VARIABLES.businessPermissionAccountId") ? val(VARIABLES.businessPermissionAccountId) : 0/>
<cfset VARIABLES.raceTagStandaloneAllowed = VARIABLES.raceTagUnscopedAccess/>
<cfset qRaceTagSubmission = queryNew("id_resultado_importacao,submission_id,id_evento,client_id,cod_timer,external_account_id,external_event_id,url_resultado,url_resultado_publica,status_publicacao,open_results_enabled,status_processamento,tentativas")/>
<cfset VARIABLES.raceTagQueueService = createObject("component", "services.ResultImportQueueService")/>

<cfif NOT structKeyExists(SESSION, "resultImportManualCsrf") OR NOT len(trim(SESSION.resultImportManualCsrf & ""))>
    <cfset SESSION.resultImportManualCsrf = lCase(hash(createUUID() & now() & getTickCount(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.raceTagCsrf = SESSION.resultImportManualCsrf/>

<cfif len(VARIABLES.raceTagSubmissionId)>
    <cfif reFindNoCase("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", VARIABLES.raceTagSubmissionId)>
        <cfset qRaceTagSubmission = VARIABLES.raceTagQueueService.submission(
            VARIABLES.raceTagSubmissionId, VARIABLES.raceTagUnscopedAccess, VARIABLES.raceTagScopeAccountId)/>

        <cfif qRaceTagSubmission.recordcount AND compareNoCase(qRaceTagSubmission.cod_timer, "racezone") NEQ 0>
            <cfset VARIABLES.raceTagError = "A submissão informada não utiliza o adaptador RaceTag Pro."/>
        <cfelseif qRaceTagSubmission.recordcount>
            <cfset VARIABLES.raceTagSubmissionReady = true/>
            <cfset VARIABLES.raceTagSubmissionCanProcess = listFindNoCase("pendente,falhou", qRaceTagSubmission.queue_status) GT 0/>
            <cfset VARIABLES.raceTagPayloadIntentAvailable = true/>
            <cfset VARIABLES.raceTagPayloadOpenResultsEnabled = qRaceTagSubmission.open_results_enabled/>
            <cfif NOT VARIABLES.raceTagUnscopedAccess>
                <!--- Para contas externas, a fonte permanece a mesma validada no envio da API. --->
                <cfset FORM.url_resultado = qRaceTagSubmission.url_resultado/>
                <cfset FORM.url_resultado_publica = qRaceTagSubmission.url_resultado_publica/>
                <cfif len(trim(qRaceTagSubmission.external_event_id & ""))>
                    <cfset FORM.external_event_id = qRaceTagSubmission.external_event_id/>
                    <cfset FORM.cod_evento = qRaceTagSubmission.external_event_id/>
                </cfif>
            <cfelseif NOT len(trim(FORM.url_resultado))>
                <cfset FORM.url_resultado = qRaceTagSubmission.url_resultado/>
            </cfif>
            <cfif VARIABLES.raceTagUnscopedAccess AND NOT len(trim(FORM.url_resultado_publica))>
                <cfset FORM.url_resultado_publica = qRaceTagSubmission.url_resultado_publica/>
            </cfif>
            <cfif VARIABLES.raceTagUnscopedAccess AND NOT len(trim(FORM.external_event_id)) AND len(trim(qRaceTagSubmission.external_event_id & ""))>
                <cfset FORM.external_event_id = qRaceTagSubmission.external_event_id/>
            </cfif>
            <cfif VARIABLES.raceTagUnscopedAccess AND NOT len(trim(FORM.cod_evento)) AND len(trim(qRaceTagSubmission.external_event_id & ""))>
                <cfset FORM.cod_evento = qRaceTagSubmission.external_event_id/>
            </cfif>
            <cfif NOT len(trim(FORM.id_evento)) AND val(qRaceTagSubmission.id_evento) GT 0>
                <cfset FORM.id_evento = qRaceTagSubmission.id_evento/>
            </cfif>

            <cfif NOT len(trim(FORM.id_evento)) AND val(qRaceTagSubmission.suggested_event_id) GT 0>
                <cfset FORM.id_evento = qRaceTagSubmission.suggested_event_id/>
                <cfset VARIABLES.raceTagNotice = qRaceTagSubmission.link_source EQ "history"
                    ? "Vínculo reaproveitado do histórico deste evento externo."
                    : "Evento pré-selecionado pela URL cadastrada em url_resultado ou url_wiclax. Confira o vínculo antes de processar."/>
            <cfelseif qRaceTagSubmission.link_source EQ "ambiguous">
                <cfset VARIABLES.raceTagNotice = "Há mais de um evento compatível com esta origem. Escolha o vínculo correto manualmente."/>
            </cfif>
            <cfif qRaceTagSubmission.queue_status EQ "arquivado">
                <cfset VARIABLES.raceTagNotice = "Esta chamada está arquivada: uma submissão posterior deste evento já foi processada. Consulte o histórico da fila."/>
            </cfif>
        <cfelse>
            <cfset VARIABLES.raceTagError = "A submissão informada não foi encontrada na fila."/>
        </cfif>
    <cfelse>
        <cfset VARIABLES.raceTagError = "O identificador da submissão é inválido."/>
    </cfif>
</cfif>

<cfif NOT VARIABLES.raceTagStandaloneAllowed AND NOT VARIABLES.raceTagSubmissionReady AND NOT len(VARIABLES.raceTagError)>
    <cfset VARIABLES.raceTagError = "Selecione uma submissão autorizada na fila de resultados para iniciar o processamento."/>
</cfif>
