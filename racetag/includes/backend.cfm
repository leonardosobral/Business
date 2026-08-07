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

<cfset VARIABLES.raceTagError = ""/>
<cfset VARIABLES.raceTagNotice = ""/>
<cfset VARIABLES.raceTagSubmissionId = lCase(trim(len(FORM.submission_id) ? FORM.submission_id : URL.submission_id)) />
<cfset VARIABLES.raceTagSubmissionReady = false/>
<cfset VARIABLES.raceTagSubmissionCanProcess = true/>
<cfset VARIABLES.raceTagUnscopedAccess = isDefined("VARIABLES.businessEffectiveIsAdmin") AND VARIABLES.businessEffectiveIsAdmin/>
<cfset VARIABLES.raceTagScopeAccountId = isDefined("VARIABLES.businessPermissionAccountId") ? val(VARIABLES.businessPermissionAccountId) : 0/>
<cfset VARIABLES.raceTagStandaloneAllowed = VARIABLES.raceTagUnscopedAccess/>
<cfset qRaceTagSubmission = queryNew("id_resultado_importacao,submission_id,id_evento,client_id,cod_timer,external_account_id,external_event_id,url_resultado,url_resultado_publica,status_publicacao,status_processamento,tentativas")/>
<cfset qRaceTagPreviousLink = queryNew("id_evento")/>

<cfif NOT structKeyExists(SESSION, "resultImportManualCsrf") OR NOT len(trim(SESSION.resultImportManualCsrf & ""))>
    <cfset SESSION.resultImportManualCsrf = lCase(hash(createUUID() & now() & getTickCount(), "SHA-256"))/>
</cfif>
<cfset VARIABLES.raceTagCsrf = SESSION.resultImportManualCsrf/>

<cfif len(VARIABLES.raceTagSubmissionId)>
    <cfif reFindNoCase("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", VARIABLES.raceTagSubmissionId)>
        <cfquery name="qRaceTagSubmission">
            SELECT id_resultado_importacao,
                   public_id::text AS submission_id,
                   id_evento,
                   client_id,
                   cod_timer,
                   external_account_id,
                   external_event_id,
                   url_resultado,
                   url_resultado_publica,
                   status_publicacao,
                   status_processamento,
                   tentativas
            FROM public.tb_resultados_importacoes imp
            WHERE imp.public_id = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.raceTagSubmissionId#"/> AS uuid)
            <cfif NOT VARIABLES.raceTagUnscopedAccess>
              AND EXISTS (
                  SELECT 1
                  FROM public.tb_conta_integracoes_resultados account_integration
                  WHERE account_integration.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.raceTagScopeAccountId#"/>
                    AND account_integration.ativo = true
                    AND lower(trim(account_integration.client_id)) = lower(trim(imp.client_id))
                    AND lower(trim(account_integration.cod_timer)) = lower(trim(imp.cod_timer))
                    AND (
                      account_integration.abrange_contas_externas = true
                      OR nullif(trim(account_integration.external_account_id), '')
                          IS NOT DISTINCT FROM nullif(trim(imp.external_account_id), '')
                    )
              )
            </cfif>
            LIMIT 1
        </cfquery>

        <cfif qRaceTagSubmission.recordcount AND compareNoCase(qRaceTagSubmission.cod_timer, "racezone") NEQ 0>
            <cfset VARIABLES.raceTagError = "A submissão informada não utiliza o adaptador RaceTag Pro."/>
        <cfelseif qRaceTagSubmission.recordcount>
            <cfset VARIABLES.raceTagSubmissionReady = true/>
            <cfset VARIABLES.raceTagSubmissionCanProcess = listFindNoCase("pendente,falhou", qRaceTagSubmission.status_processamento) GT 0/>
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

            <cfif NOT len(trim(FORM.id_evento)) AND len(trim(qRaceTagSubmission.external_event_id & ""))>
                <cfquery name="qRaceTagPreviousLink">
                    SELECT id_evento
                    FROM public.tb_resultados_importacoes
                    WHERE client_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qRaceTagSubmission.client_id#"/>
                      AND external_event_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qRaceTagSubmission.external_event_id#"/>
                      AND external_account_id IS NOT DISTINCT FROM <cfqueryparam cfsqltype="cf_sql_varchar" value="#qRaceTagSubmission.external_account_id#" null="#NOT len(trim(qRaceTagSubmission.external_account_id & ''))#"/>
                      AND id_evento IS NOT NULL
                      AND public_id <> CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.raceTagSubmissionId#"/> AS uuid)
                    ORDER BY data_processamento DESC NULLS LAST, data_recebimento DESC
                    LIMIT 1
                </cfquery>

                <cfif qRaceTagPreviousLink.recordcount>
                    <cfset FORM.id_evento = qRaceTagPreviousLink.id_evento/>
                    <cfset VARIABLES.raceTagNotice = "Vínculo interno reaproveitado de uma submissão anterior do mesmo evento externo."/>
                </cfif>
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
