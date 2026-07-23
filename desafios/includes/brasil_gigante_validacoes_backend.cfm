<!--- Fila administrativa de comprovacoes documentais do Circuito Brasil Gigante. --->
<cfset VARIABLES.cbgValidationRequests = []/>
<cfset VARIABLES.cbgValidationPendingCount = 0/>
<cfset VARIABLES.cbgValidationApprovedCount = 0/>
<cfset VARIABLES.cbgValidationRejectedCount = 0/>
<cfset VARIABLES.cbgValidationCanDecide = false/>
<cfset VARIABLES.cbgValidationRaceMap = {
    "sao-paulo" = 17,
    "parana" = 1000,
    "porto-alegre" = 26,
    "campo-grande" = 9,
    "joao-pessoa" = 14,
    "florianopolis" = 28,
    "salvador" = 15,
    "aracaju" = 77
}/>

<cfif qPerfil.recordcount>
    <cfset VARIABLES.cbgValidationCanDecide = (isBoolean(qPerfil.is_admin) AND qPerfil.is_admin)
        OR (isBoolean(qPerfil.is_dev) AND qPerfil.is_dev)/>
</cfif>

<!--- Busca AJAX de resultados oficiais candidatos para vinculacao administrativa. --->
<cfif isDefined("URL.cbg_result_search") AND URL.cbg_result_search EQ "1">
    <cfset VARIABLES.cbgSearchPayload = {success = false, results = []}/>
    <cfset VARIABLES.cbgSearchUserId = isDefined("URL.id_usuario") ? val(URL.id_usuario) : 0/>
    <cfset VARIABLES.cbgSearchProtocol = isDefined("URL.protocolo") ? trim(URL.protocolo) : ""/>
    <cfset VARIABLES.cbgSearchCsrf = isDefined("URL.csrf") ? trim(URL.csrf) : ""/>
    <cfset VARIABLES.cbgSearchName = isDefined("URL.nome") ? trim(URL.nome) : ""/>
    <cfset VARIABLES.cbgSearchBib = isDefined("URL.num_peito") ? val(URL.num_peito) : 0/>
    <cfset VARIABLES.cbgSearchRequestedYear = isDefined("URL.ano") ? val(URL.ano) : 0/>

    <cfif NOT VARIABLES.cbgValidationCanDecide>
        <cfheader statuscode="403" statustext="Forbidden"/>
        <cfset VARIABLES.cbgSearchPayload.message = "Sem permissao para pesquisar resultados."/>
    <cfelseif VARIABLES.cbgSearchCsrf NEQ VARIABLES.challengeMedalCsrf OR VARIABLES.cbgSearchUserId LTE 0 OR NOT len(VARIABLES.cbgSearchProtocol)>
        <cfheader statuscode="400" statustext="Bad Request"/>
        <cfset VARIABLES.cbgSearchPayload.message = "Solicitacao de busca invalida."/>
    <cfelseif len(VARIABLES.cbgSearchName) LT 2 AND VARIABLES.cbgSearchBib LTE 0>
        <cfheader statuscode="422" statustext="Unprocessable Entity"/>
        <cfset VARIABLES.cbgSearchPayload.message = "Informe ao menos dois caracteres do nome ou um numero de peito."/>
    <cfelse>
        <cfquery name="qCbgSearchChallenge">
            SELECT body
            FROM desafios
            WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgSearchUserId#"/>
              AND produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="circuitobrasilgigante"/>
            LIMIT 1
        </cfquery>
        <cfif qCbgSearchChallenge.recordcount>
            <cftry>
                <cfset VARIABLES.cbgSearchBody = deserializeJSON(toString(qCbgSearchChallenge.body))/>
                <cfset VARIABLES.cbgSearchItem = {}/>
                <cfif isStruct(VARIABLES.cbgSearchBody) AND structKeyExists(VARIABLES.cbgSearchBody, "validacoes_documentais") AND isArray(VARIABLES.cbgSearchBody.validacoes_documentais)>
                    <cfloop array="#VARIABLES.cbgSearchBody.validacoes_documentais#" item="VARIABLES.cbgSearchCandidateItem">
                        <cfif structKeyExists(VARIABLES.cbgSearchCandidateItem, "protocolo") AND trim(VARIABLES.cbgSearchCandidateItem.protocolo & "") EQ VARIABLES.cbgSearchProtocol>
                            <cfset VARIABLES.cbgSearchItem = VARIABLES.cbgSearchCandidateItem/>
                            <cfbreak/>
                        </cfif>
                    </cfloop>
                </cfif>
                <cfif isStruct(VARIABLES.cbgSearchItem) AND structCount(VARIABLES.cbgSearchItem)>
                    <cfset VARIABLES.cbgSearchRaceKey = structKeyExists(VARIABLES.cbgSearchItem, "prova_key") ? trim(VARIABLES.cbgSearchItem.prova_key & "") : ""/>
                    <cfset VARIABLES.cbgSearchAggregatorId = structKeyExists(VARIABLES.cbgValidationRaceMap, VARIABLES.cbgSearchRaceKey) ? VARIABLES.cbgValidationRaceMap[VARIABLES.cbgSearchRaceKey] : 0/>
                    <cfset VARIABLES.cbgSearchOriginalYear = structKeyExists(VARIABLES.cbgSearchItem, "ano") ? val(VARIABLES.cbgSearchItem.ano) : 0/>
                    <cfset VARIABLES.cbgSearchYear = VARIABLES.cbgSearchRequestedYear GT 0 ? VARIABLES.cbgSearchRequestedYear : VARIABLES.cbgSearchOriginalYear/>
                    <cfif VARIABLES.cbgSearchYear LT 1900 OR VARIABLES.cbgSearchYear GT year(now())>
                        <cfthrow type="CBG.Validation.InvalidSearchYear" message="Informe um ano de participacao valido."/>
                    </cfif>
                    <cfif VARIABLES.cbgSearchAggregatorId GT 0 AND VARIABLES.cbgSearchYear GT 0>
                        <cfquery name="qCbgSearchResults">
                            SELECT res.id_resultado,
                                   coalesce(res.nome, '') AS nome,
                                   coalesce(res.num_peito::text, '') AS num_peito,
                                   coalesce(res.equipe, '') AS equipe,
                                   coalesce(res.sexo, '') AS sexo,
                                   coalesce(res.tempo_total::text, '') AS tempo_total,
                                   coalesce(res.nome_categoria, '') AS nome_categoria,
                                   coalesce(evt.nome_evento, '') AS nome_evento,
                                   evt.id_evento,
                                   coalesce(res.id_usuario, 0) AS id_usuario_vinculado,
                                   coalesce(res.id_usuario = 0, false) AS vinculo_provisorio,
                                   res.percurso
                            FROM tb_resultados res
                            INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
                            INNER JOIN tb_agregadores_eventos agr
                                ON agr.id_evento = evt.id_evento
                               AND agr.agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="brasil-gigante"/>
                            WHERE res.percurso >= <cfqueryparam cfsqltype="cf_sql_decimal" value="42"/>
                              AND res.percurso < <cfqueryparam cfsqltype="cf_sql_decimal" value="43"/>
                              AND coalesce(res.status_final, 0) < 3
                              AND evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgSearchAggregatorId#"/>
                              AND extract(year FROM evt.data_final) = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgSearchYear#"/>
                              AND (
                                <cfif VARIABLES.cbgSearchBib GT 0>
                                  res.num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgSearchBib#"/>
                                  <cfif len(VARIABLES.cbgSearchName) GTE 2> OR </cfif>
                                </cfif>
                                <cfif len(VARIABLES.cbgSearchName) GTE 2>
                                  lower(unaccent(coalesce(res.nome, ''))) LIKE lower(unaccent(CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.cbgSearchName#%"/> AS text)))
                                  OR similarity(coalesce(res.nome_normalizado, lower(unaccent(coalesce(res.nome, '')))), lower(unaccent(CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cbgSearchName#"/> AS text)))) >= 0.20
                                </cfif>
                              )
                            ORDER BY
                              CASE WHEN coalesce(res.id_usuario, 0) > 0 THEN 0 ELSE 1 END,
                              <cfif VARIABLES.cbgSearchBib GT 0>CASE WHEN res.num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgSearchBib#"/> THEN 0 ELSE 1 END,</cfif>
                              res.nome, res.id_resultado
                            LIMIT 30
                        </cfquery>
                        <cfloop query="qCbgSearchResults">
                            <cfset arrayAppend(VARIABLES.cbgSearchPayload.results, {
                                id = qCbgSearchResults.id_resultado,
                                name = qCbgSearchResults.nome & "",
                                bib = qCbgSearchResults.num_peito & "",
                                team = qCbgSearchResults.equipe & "",
                                sex = qCbgSearchResults.sexo & "",
                                time = qCbgSearchResults.tempo_total & "",
                                category = qCbgSearchResults.nome_categoria & "",
                                eventName = qCbgSearchResults.nome_evento & "",
                                linkedUserId = val(qCbgSearchResults.id_usuario_vinculado),
                                provisionalLink = isBoolean(qCbgSearchResults.vinculo_provisorio) AND qCbgSearchResults.vinculo_provisorio,
                                distance = qCbgSearchResults.percurso & ""
                            })/>
                        </cfloop>
                        <cfset VARIABLES.cbgSearchPayload.success = true/>
                    <cfelse>
                        <cfheader statuscode="422" statustext="Unprocessable Entity"/>
                        <cfset VARIABLES.cbgSearchPayload.message = "A prova ou o ano da solicitacao nao puderam ser identificados."/>
                    </cfif>
                <cfelse>
                    <cfheader statuscode="404" statustext="Not Found"/>
                    <cfset VARIABLES.cbgSearchPayload.message = "O protocolo documental nao foi encontrado para este atleta."/>
                </cfif>
                <cfcatch type="CBG.Validation.InvalidSearchYear">
                    <cfheader statuscode="422" statustext="Unprocessable Entity"/>
                    <cfset VARIABLES.cbgSearchPayload.message = cfcatch.message/>
                </cfcatch>
                <cfcatch type="any">
                    <cfheader statuscode="500" statustext="Internal Server Error"/>
                    <cfset VARIABLES.cbgSearchErrorDetail = structKeyExists(cfcatch, "detail") ? trim(cfcatch.detail & "") : ""/>
                    <cfset VARIABLES.cbgSearchPayload.message = "Nao foi possivel pesquisar os resultados: " & cfcatch.message & (len(VARIABLES.cbgSearchErrorDetail) ? " - " & VARIABLES.cbgSearchErrorDetail : "")/>
                </cfcatch>
            </cftry>
        <cfelse>
            <cfheader statuscode="404" statustext="Not Found"/>
            <cfset VARIABLES.cbgSearchPayload.message = "O cadastro do atleta no circuito nao foi encontrado."/>
        </cfif>
    </cfif>
    <cfcontent type="application/json; charset=utf-8" reset="true"/>
    <cfoutput>#serializeJSON(VARIABLES.cbgSearchPayload)#</cfoutput>
    <cfabort/>
</cfif>

<cffunction name="cbgValidationRedirect" returntype="void" output="false">
    <cfargument name="status" type="string" required="true"/>
    <cflocation addtoken="false" url="/desafios/circuitobrasilgigante/?tela=validacoes&validacao=#urlEncodedFormat(ARGUMENTS.status)#&challenge_refresh=#getTickCount()###validacoes-documentais"/>
</cffunction>

<cfif isDefined("FORM.challenge_action")
    AND listFindNoCase("aprovar_validacao_documental,vincular_resultado_oficial,desaprovar_validacao_documental", FORM.challenge_action)>
    <cfset VARIABLES.cbgValidationUserId = isDefined("FORM.id_usuario") ? val(FORM.id_usuario) : 0/>
    <cfset VARIABLES.cbgValidationProtocol = isDefined("FORM.protocolo") ? trim(FORM.protocolo) : ""/>
    <cfset VARIABLES.cbgValidationPostedCsrf = isDefined("FORM.challenge_medal_csrf") ? trim(FORM.challenge_medal_csrf) : ""/>

    <cfif NOT VARIABLES.cbgValidationCanDecide>
        <cfset cbgValidationRedirect("sem_permissao")/>
    </cfif>
    <cfif VARIABLES.cbgValidationUserId LTE 0
        OR NOT len(VARIABLES.cbgValidationProtocol)
        OR NOT len(VARIABLES.cbgValidationPostedCsrf)
        OR VARIABLES.cbgValidationPostedCsrf NEQ VARIABLES.challengeMedalCsrf>
        <cfset cbgValidationRedirect("solicitacao_invalida")/>
    </cfif>

    <cftry>
        <cftransaction isolation="serializable">
            <cfquery name="qCbgValidationLockedChallenge">
                SELECT id_usuario, body
                FROM desafios
                WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationUserId#"/>
                  AND produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="circuitobrasilgigante"/>
                FOR UPDATE
            </cfquery>

            <cfif NOT qCbgValidationLockedChallenge.recordcount>
                <cfthrow type="CBG.Validation.NotFound" message="Solicitacao documental nao encontrada."/>
            </cfif>

            <cfset VARIABLES.cbgValidationBody = deserializeJSON(toString(qCbgValidationLockedChallenge.body)) />
            <cfset VARIABLES.cbgValidationItemIndex = 0/>
            <cfif isStruct(VARIABLES.cbgValidationBody)
                AND structKeyExists(VARIABLES.cbgValidationBody, "validacoes_documentais")
                AND isArray(VARIABLES.cbgValidationBody.validacoes_documentais)>
                <cfloop from="1" to="#arrayLen(VARIABLES.cbgValidationBody.validacoes_documentais)#" index="VARIABLES.cbgValidationIndex">
                    <cfif structKeyExists(VARIABLES.cbgValidationBody.validacoes_documentais[VARIABLES.cbgValidationIndex], "protocolo")
                        AND trim(VARIABLES.cbgValidationBody.validacoes_documentais[VARIABLES.cbgValidationIndex].protocolo & "") EQ VARIABLES.cbgValidationProtocol>
                        <cfset VARIABLES.cbgValidationItemIndex = VARIABLES.cbgValidationIndex/>
                        <cfbreak/>
                    </cfif>
                </cfloop>
            </cfif>

            <cfif VARIABLES.cbgValidationItemIndex EQ 0>
                <cfthrow type="CBG.Validation.NotFound" message="Protocolo documental nao encontrado."/>
            </cfif>
            <cfset VARIABLES.cbgValidationItem = VARIABLES.cbgValidationBody.validacoes_documentais[VARIABLES.cbgValidationItemIndex]/>
            <cfset VARIABLES.cbgValidationCurrentStatus = structKeyExists(VARIABLES.cbgValidationItem, "status_analise") ? lcase(trim(VARIABLES.cbgValidationItem.status_analise & "")) : "pendente"/>
            <cfset VARIABLES.cbgValidationHasResult = structKeyExists(VARIABLES.cbgValidationItem, "id_resultado") AND val(VARIABLES.cbgValidationItem.id_resultado) GT 0/>
            <cfif FORM.challenge_action EQ "aprovar_validacao_documental"
                AND NOT (VARIABLES.cbgValidationCurrentStatus EQ "pendente"
                    OR (VARIABLES.cbgValidationCurrentStatus EQ "aprovado" AND NOT VARIABLES.cbgValidationHasResult))>
                <cfthrow type="CBG.Validation.AlreadyDecided" message="Esta solicitacao ja possui resultado vinculado."/>
            <cfelseif FORM.challenge_action EQ "vincular_resultado_oficial"
                AND NOT (listFindNoCase("pendente,desaprovado", VARIABLES.cbgValidationCurrentStatus)
                    OR (VARIABLES.cbgValidationCurrentStatus EQ "aprovado" AND NOT VARIABLES.cbgValidationHasResult))>
                <cfthrow type="CBG.Validation.AlreadyDecided" message="Esta solicitacao ja possui resultado vinculado."/>
            <cfelseif FORM.challenge_action EQ "desaprovar_validacao_documental"
                AND VARIABLES.cbgValidationCurrentStatus NEQ "pendente">
                <cfthrow type="CBG.Validation.AlreadyDecided" message="Esta solicitacao ja foi analisada."/>
            </cfif>

            <cfset VARIABLES.cbgValidationRaceKey = structKeyExists(VARIABLES.cbgValidationItem, "prova_key") ? trim(VARIABLES.cbgValidationItem.prova_key & "") : ""/>
            <cfset VARIABLES.cbgValidationYear = structKeyExists(VARIABLES.cbgValidationItem, "ano") ? val(VARIABLES.cbgValidationItem.ano) : 0/>
            <cfset VARIABLES.cbgValidationAggregatorId = structKeyExists(VARIABLES.cbgValidationRaceMap, VARIABLES.cbgValidationRaceKey) ? VARIABLES.cbgValidationRaceMap[VARIABLES.cbgValidationRaceKey] : 0/>
            <cfset VARIABLES.cbgValidationAuditDetail = ""/>

            <cfif FORM.challenge_action EQ "vincular_resultado_oficial">
                <cfset VARIABLES.cbgValidationOfficialResultId = isDefined("FORM.id_resultado") ? val(FORM.id_resultado) : 0/>
                <cfset VARIABLES.cbgValidationSelectedYear = isDefined("FORM.ano_resultado") ? val(FORM.ano_resultado) : VARIABLES.cbgValidationYear/>
                <cfif VARIABLES.cbgValidationOfficialResultId LTE 0 OR VARIABLES.cbgValidationAggregatorId LTE 0 OR VARIABLES.cbgValidationSelectedYear LT 1900 OR VARIABLES.cbgValidationSelectedYear GT year(now())>
                    <cfthrow type="CBG.Validation.InvalidOfficialResult" message="Selecione um resultado oficial valido."/>
                </cfif>

                <!--- Trava e valida o resultado escolhido contra prova, ano, percurso e vinculo. --->
                <cfquery name="qCbgValidationOfficialResult">
                    SELECT res.id_resultado, res.id_usuario, res.id_evento, res.nome, res.num_peito
                    FROM tb_resultados res
                    INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
                    INNER JOIN tb_agregadores_eventos agr
                        ON agr.id_evento = evt.id_evento
                       AND agr.agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="brasil-gigante"/>
                    WHERE res.id_resultado = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cbgValidationOfficialResultId#"/>
                      AND res.percurso >= <cfqueryparam cfsqltype="cf_sql_decimal" value="42"/>
                      AND res.percurso < <cfqueryparam cfsqltype="cf_sql_decimal" value="43"/>
                      AND coalesce(res.status_final, 0) < 3
                      AND evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationAggregatorId#"/>
                      AND extract(year FROM evt.data_final) = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationSelectedYear#"/>
                    FOR UPDATE OF res
                </cfquery>
                <cfif NOT qCbgValidationOfficialResult.recordcount>
                    <cfthrow type="CBG.Validation.InvalidOfficialResult" message="O resultado nao corresponde a prova, ano e percurso solicitados."/>
                </cfif>
                <cfif val(qCbgValidationOfficialResult.id_usuario) GT 0 AND val(qCbgValidationOfficialResult.id_usuario) NEQ VARIABLES.cbgValidationUserId>
                    <cfthrow type="CBG.Validation.OfficialResultLinked" message="O resultado ja esta vinculado a outro atleta."/>
                </cfif>

                <cfquery>
                    UPDATE tb_resultados
                    SET id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationUserId#"/>
                    WHERE id_resultado = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cbgValidationOfficialResultId#"/>
                      AND (id_usuario IS NULL OR id_usuario = 0 OR id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationUserId#"/>)
                </cfquery>
                <cfquery>
                    DELETE FROM tb_resultados_desvincular
                    WHERE id_resultado = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cbgValidationOfficialResultId#"/>
                      AND id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.cbgValidationUserId#"/>
                </cfquery>

                <!--- Uma etapa conta uma unica vez, sempre exibindo o ano oficial mais recente reconhecido. --->
                <cfquery name="qCbgValidationLatestStageYear">
                    SELECT coalesce(
                               max(extract(year FROM evt.data_final))::integer,
                               <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationSelectedYear#"/>
                           ) AS latest_year
                    FROM tb_resultados res
                    INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
                    WHERE res.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationUserId#"/>
                      AND res.percurso >= <cfqueryparam cfsqltype="cf_sql_decimal" value="42"/>
                      AND res.percurso < <cfqueryparam cfsqltype="cf_sql_decimal" value="43"/>
                      AND evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationAggregatorId#"/>
                </cfquery>

                <cfset VARIABLES.cbgValidationItem.status_analise = "aprovado"/>
                <cfset VARIABLES.cbgValidationItem.id_resultado = VARIABLES.cbgValidationOfficialResultId/>
                <cfset VARIABLES.cbgValidationItem.id_evento = qCbgValidationOfficialResult.id_evento/>
                <cfset VARIABLES.cbgValidationItem.ano_resultado_vinculado = VARIABLES.cbgValidationSelectedYear/>
                <cfset VARIABLES.cbgValidationItem.ano = val(qCbgValidationLatestStageYear.latest_year)/>
                <cfset VARIABLES.cbgValidationItem.tipo_aprovacao = "resultado_oficial_vinculado"/>
                <cfset VARIABLES.cbgValidationItem.nome_validado = qCbgValidationOfficialResult.nome/>
                <cfset VARIABLES.cbgValidationItem.numero_peito_validado = qCbgValidationOfficialResult.num_peito/>
                <cfset VARIABLES.cbgValidationAuditAction = "vinculo_resultado_oficial:#VARIABLES.cbgValidationOfficialResultId#"/>
            <cfelseif FORM.challenge_action EQ "aprovar_validacao_documental">
                <cfset VARIABLES.cbgValidationName = isDefined("FORM.nome") ? trim(FORM.nome) : ""/>
                <cfset VARIABLES.cbgValidationBib = isDefined("FORM.num_peito") ? val(FORM.num_peito) : 0/>
                <cfset VARIABLES.cbgValidationEventId = isDefined("FORM.id_evento") ? val(FORM.id_evento) : 0/>
                <cfset VARIABLES.cbgValidationSex = isDefined("FORM.sexo") ? ucase(trim(FORM.sexo)) : ""/>
                <cfset VARIABLES.cbgValidationBirthDate = isDefined("FORM.data_nascimento") ? trim(FORM.data_nascimento) : ""/>

                <cfif NOT len(VARIABLES.cbgValidationName)
                    OR VARIABLES.cbgValidationBib LTE 0
                    OR VARIABLES.cbgValidationEventId LTE 0
                    OR VARIABLES.cbgValidationAggregatorId LTE 0
                    OR NOT listFindNoCase("M,F,X", VARIABLES.cbgValidationSex)
                    OR (len(VARIABLES.cbgValidationBirthDate) AND NOT isDate(VARIABLES.cbgValidationBirthDate))>
                    <cfthrow type="CBG.Validation.InvalidFields" message="Confira os dados obrigatorios do resultado."/>
                </cfif>

                <cfquery name="qCbgValidationEvent">
                    SELECT evt.id_evento, evt.nome_evento
                    FROM tb_evento_corridas evt
                    INNER JOIN tb_agregadores_eventos agr
                        ON agr.id_evento = evt.id_evento
                       AND agr.agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="brasil-gigante"/>
                    WHERE evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationEventId#"/>
                      AND evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationAggregatorId#"/>
                      AND extract(year FROM evt.data_final) = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationYear#"/>
                </cfquery>
                <cfif NOT qCbgValidationEvent.recordcount>
                    <cfthrow type="CBG.Validation.InvalidEvent" message="O evento nao corresponde a prova e ao ano enviados."/>
                </cfif>

                <!--- Uma etapa do circuito so pode ser reconhecida uma vez por atleta. --->
                <cfquery name="qCbgValidationExistingAthleteResult">
                    SELECT res.id_resultado
                    FROM tb_resultados res
                    INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
                    INNER JOIN tb_agregadores_eventos agr
                        ON agr.id_evento = evt.id_evento
                       AND agr.agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="brasil-gigante"/>
                    WHERE res.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationUserId#"/>
                      AND res.percurso >= <cfqueryparam cfsqltype="cf_sql_decimal" value="42"/>
                      AND res.percurso < <cfqueryparam cfsqltype="cf_sql_decimal" value="43"/>
                      AND evt.id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationAggregatorId#"/>
                    LIMIT 1
                </cfquery>
                <cfif qCbgValidationExistingAthleteResult.recordcount>
                    <cfthrow type="CBG.Validation.DuplicateAthlete" message="O atleta ja possui resultado nesta etapa."/>
                </cfif>

                <cfquery name="qCbgValidationExistingBib">
                    SELECT id_resultado
                    FROM tb_resultados
                    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationEventId#"/>
                      AND percurso >= <cfqueryparam cfsqltype="cf_sql_decimal" value="42"/>
                      AND percurso < <cfqueryparam cfsqltype="cf_sql_decimal" value="43"/>
                      AND num_peito = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationBib#"/>
                    LIMIT 1
                </cfquery>
                <cfif qCbgValidationExistingBib.recordcount>
                    <cfthrow type="CBG.Validation.DuplicateBib" message="O numero de peito ja existe neste evento."/>
                </cfif>

                <cfquery name="qCbgValidationInsertedResult" result="qCbgValidationInsertMeta">
                    INSERT INTO tb_resultados
                        (num_peito, nome, data_nascimento, id_evento, modalidade, percurso, sexo,
                         id_usuario, homologado, concluinte, status_final, origem_resultado)
                    VALUES
                        (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationBib#"/>,
                         <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cbgValidationName#"/>,
                         <cfqueryparam cfsqltype="cf_sql_date" value="#len(VARIABLES.cbgValidationBirthDate) ? VARIABLES.cbgValidationBirthDate : now()#" null="#!len(VARIABLES.cbgValidationBirthDate)#"/>,
                         <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationEventId#"/>,
                         <cfqueryparam cfsqltype="cf_sql_varchar" value="MARATONA"/>,
                         <cfqueryparam cfsqltype="cf_sql_decimal" value="42"/>,
                         <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cbgValidationSex#"/>,
                         <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationUserId#"/>,
                         <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
                         <cfqueryparam cfsqltype="cf_sql_bit" value="true"/>,
                         <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>,
                         <cfqueryparam cfsqltype="cf_sql_varchar" value="validacao_documental"/>)
                    RETURNING id_resultado
                </cfquery>

                <cfset VARIABLES.cbgValidationItem.status_analise = "aprovado"/>
                <cfset VARIABLES.cbgValidationItem.id_resultado = qCbgValidationInsertedResult.id_resultado/>
                <cfset VARIABLES.cbgValidationItem.tipo_aprovacao = "resultado_manual_documental"/>
                <cfset VARIABLES.cbgValidationItem.id_evento = VARIABLES.cbgValidationEventId/>
                <cfset VARIABLES.cbgValidationItem.nome_validado = VARIABLES.cbgValidationName/>
                <cfset VARIABLES.cbgValidationItem.numero_peito_validado = VARIABLES.cbgValidationBib/>
                <cfset VARIABLES.cbgValidationItem.sexo_validado = VARIABLES.cbgValidationSex/>
                <cfset VARIABLES.cbgValidationItem.data_nascimento_validada = VARIABLES.cbgValidationBirthDate/>
                <cfset VARIABLES.cbgValidationAuditAction = "aprovacao_documental"/>
            <cfelse>
                <cfset VARIABLES.cbgValidationRejectionReason = isDefined("FORM.motivo_desaprovacao") ? trim(FORM.motivo_desaprovacao) : ""/>
                <cfif len(VARIABLES.cbgValidationRejectionReason) LT 5>
                    <cfthrow type="CBG.Validation.InvalidRejectionReason" message="Informe o motivo da desaprovacao."/>
                </cfif>
                <cfset VARIABLES.cbgValidationItem.status_analise = "desaprovado"/>
                <cfset VARIABLES.cbgValidationItem.motivo_desaprovacao = left(VARIABLES.cbgValidationRejectionReason, 2000)/>
                <cfset VARIABLES.cbgValidationAuditAction = "desaprovacao_documental"/>
                <cfset VARIABLES.cbgValidationAuditDetail = left(VARIABLES.cbgValidationRejectionReason, 2000)/>
            </cfif>

            <cfset VARIABLES.cbgValidationItem.data_analise = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")/>
            <cfset VARIABLES.cbgValidationItem.id_admin_analise = qPerfil.id/>
            <cfset VARIABLES.cbgValidationBody.validacoes_documentais[VARIABLES.cbgValidationItemIndex] = VARIABLES.cbgValidationItem/>

            <cfquery>
                UPDATE desafios
                SET body = <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(VARIABLES.cbgValidationBody)#"/>::jsonb
                WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationUserId#"/>
                  AND produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="circuitobrasilgigante"/>
            </cfquery>
            <cfquery>
                INSERT INTO desafios_obs (id_usuario, produto, obs, id_atendente)
                VALUES (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.cbgValidationUserId#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="circuitobrasilgigante"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.cbgValidationAuditAction#:#VARIABLES.cbgValidationProtocol##len(VARIABLES.cbgValidationAuditDetail) ? ': ' & VARIABLES.cbgValidationAuditDetail : ''#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#qPerfil.id#"/>
                )
            </cfquery>
        </cftransaction>

        <cfif FORM.challenge_action EQ "vincular_resultado_oficial">
            <cfset cbgValidationRedirect("resultado_vinculado")/>
        <cfelseif FORM.challenge_action EQ "aprovar_validacao_documental">
            <cfset cbgValidationRedirect("aprovada")/>
        <cfelse>
            <cfset cbgValidationRedirect("desaprovada")/>
        </cfif>
        <cfcatch type="CBG.Validation.DuplicateAthlete">
            <cfset cbgValidationRedirect("resultado_existente")/>
        </cfcatch>
        <cfcatch type="CBG.Validation.DuplicateBib">
            <cfset cbgValidationRedirect("peito_existente")/>
        </cfcatch>
        <cfcatch type="CBG.Validation.AlreadyDecided">
            <cfset cbgValidationRedirect("ja_analisada")/>
        </cfcatch>
        <cfcatch type="CBG.Validation.InvalidRejectionReason">
            <cfset cbgValidationRedirect("motivo_desaprovacao_obrigatorio")/>
        </cfcatch>
        <cfcatch type="CBG.Validation.InvalidOfficialResult">
            <cfset cbgValidationRedirect("resultado_oficial_invalido")/>
        </cfcatch>
        <cfcatch type="CBG.Validation.OfficialResultLinked">
            <cfset cbgValidationRedirect("resultado_oficial_vinculado_outro")/>
        </cfcatch>
        <cfcatch type="any">
            <cfset cbgValidationRedirect("erro")/>
        </cfcatch>
    </cftry>
</cfif>

<cfquery name="qCbgValidationChallenges">
    SELECT des.id_usuario, des.body, usr.email, usr.name AS user_name,
           usr.data_nascimento AS user_birth_date,
           coalesce(
               (
                   SELECT pag.tag
                   FROM tb_paginas pag
                   WHERE pag.id_usuario_cadastro = usr.id
                     AND nullif(trim(pag.tag), '') IS NOT NULL
                   ORDER BY pag.id_pagina
                   LIMIT 1
               ),
               nullif(trim(usr.tag_usuario), '')
           ) AS athlete_tag,
           CASE
               WHEN upper(coalesce(usr.genero, usr.strava_sex, '')) LIKE 'F%' THEN 'F'
               WHEN upper(coalesce(usr.genero, usr.strava_sex, '')) LIKE 'M%' THEN 'M'
               ELSE ''
           END AS user_sex
    FROM desafios des
    INNER JOIN tb_usuarios usr ON usr.id = des.id_usuario
    WHERE des.produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="circuitobrasilgigante"/>
      AND jsonb_typeof(des.body -> 'validacoes_documentais') = 'array'
</cfquery>

<cfquery name="qCbgValidationEvents">
    SELECT evt.id_evento, evt.id_agrega_evento,
           extract(year FROM evt.data_final)::integer AS race_year,
           evt.nome_evento
    FROM tb_evento_corridas evt
    INNER JOIN tb_agregadores_eventos agr
        ON agr.id_evento = evt.id_evento
       AND agr.agregador_tag = <cfqueryparam cfsqltype="cf_sql_varchar" value="brasil-gigante"/>
    ORDER BY evt.data_final DESC, evt.id_evento DESC
</cfquery>

<cfscript>
VARIABLES.cbgValidationEventLookup = {};
for (VARIABLES.cbgEventRow in qCbgValidationEvents) {
    VARIABLES.cbgEventKey = VARIABLES.cbgEventRow.id_agrega_evento & "-" & VARIABLES.cbgEventRow.race_year;
    if (!structKeyExists(VARIABLES.cbgValidationEventLookup, VARIABLES.cbgEventKey)) {
        VARIABLES.cbgValidationEventLookup[VARIABLES.cbgEventKey] = [];
    }
    arrayAppend(VARIABLES.cbgValidationEventLookup[VARIABLES.cbgEventKey], {
        id = VARIABLES.cbgEventRow.id_evento,
        name = VARIABLES.cbgEventRow.nome_evento
    });
}

for (VARIABLES.cbgChallengeRow in qCbgValidationChallenges) {
    try {
        VARIABLES.cbgBody = deserializeJSON(toString(VARIABLES.cbgChallengeRow.body));
    } catch (any cbgJsonError) {
        VARIABLES.cbgBody = {};
    }
    if (!isStruct(VARIABLES.cbgBody) || !structKeyExists(VARIABLES.cbgBody, "validacoes_documentais") || !isArray(VARIABLES.cbgBody.validacoes_documentais)) {
        continue;
    }
    VARIABLES.cbgName = structKeyExists(VARIABLES.cbgBody, "nome_completo") ? trim(VARIABLES.cbgBody.nome_completo & "") : trim(VARIABLES.cbgChallengeRow.user_name & "");
    VARIABLES.cbgBodySex = structKeyExists(VARIABLES.cbgBody, "genero") ? ucase(trim(VARIABLES.cbgBody.genero & "")) : "";
    VARIABLES.cbgDefaultSex = left(VARIABLES.cbgBodySex, 1) == "F" ? "F" : (left(VARIABLES.cbgBodySex, 1) == "M" ? "M" : trim(VARIABLES.cbgChallengeRow.user_sex & ""));
    VARIABLES.cbgDefaultBirthDate = "";
    if (structKeyExists(VARIABLES.cbgBody, "data_nascimento") && isDate(VARIABLES.cbgBody.data_nascimento)) {
        VARIABLES.cbgDefaultBirthDate = dateFormat(VARIABLES.cbgBody.data_nascimento, "yyyy-mm-dd");
    } else if (isDate(VARIABLES.cbgChallengeRow.user_birth_date)) {
        VARIABLES.cbgDefaultBirthDate = dateFormat(VARIABLES.cbgChallengeRow.user_birth_date, "yyyy-mm-dd");
    }
    for (VARIABLES.cbgItem in VARIABLES.cbgBody.validacoes_documentais) {
        VARIABLES.cbgStatus = structKeyExists(VARIABLES.cbgItem, "status_analise") ? lcase(trim(VARIABLES.cbgItem.status_analise & "")) : "pendente";
        VARIABLES.cbgRaceKey = structKeyExists(VARIABLES.cbgItem, "prova_key") ? trim(VARIABLES.cbgItem.prova_key & "") : "";
        VARIABLES.cbgAggregatorId = structKeyExists(VARIABLES.cbgValidationRaceMap, VARIABLES.cbgRaceKey) ? VARIABLES.cbgValidationRaceMap[VARIABLES.cbgRaceKey] : 0;
        VARIABLES.cbgItemYear = val(structKeyExists(VARIABLES.cbgItem, "ano") ? VARIABLES.cbgItem.ano : 0);
        VARIABLES.cbgLookupKey = VARIABLES.cbgAggregatorId & "-" & VARIABLES.cbgItemYear;
        VARIABLES.cbgFiles = [];
        if (structKeyExists(VARIABLES.cbgItem, "arquivos") && isArray(VARIABLES.cbgItem.arquivos)) {
            for (VARIABLES.cbgFile in VARIABLES.cbgItem.arquivos) {
                VARIABLES.cbgFileUrl = structKeyExists(VARIABLES.cbgFile, "url_publica") ? trim(VARIABLES.cbgFile.url_publica & "") : "";
                if (!len(VARIABLES.cbgFileUrl) && structKeyExists(VARIABLES.cbgFile, "nome_salvo")) VARIABLES.cbgFileUrl = "/uploads/documentos-validacao/" & (structKeyExists(VARIABLES.cbgItem, "protocolo") ? VARIABLES.cbgItem.protocolo : "") & "/" & VARIABLES.cbgFile.nome_salvo;
                if (left(VARIABLES.cbgFileUrl, 1) == "/") VARIABLES.cbgFileUrl = "https://circuitobrasilgigante.com.br" & VARIABLES.cbgFileUrl;
                if (!reFindNoCase("^https://", VARIABLES.cbgFileUrl)) VARIABLES.cbgFileUrl = "";
                arrayAppend(VARIABLES.cbgFiles, {
                    name = structKeyExists(VARIABLES.cbgFile, "nome_original") ? VARIABLES.cbgFile.nome_original : "Documento",
                    url = VARIABLES.cbgFileUrl
                });
            }
        }
        VARIABLES.cbgOfficialCandidates = [];
        VARIABLES.cbgItemResultId = structKeyExists(VARIABLES.cbgItem, "id_resultado") ? val(VARIABLES.cbgItem.id_resultado) : 0;
        if (VARIABLES.cbgValidationCanDecide && VARIABLES.cbgItemResultId LTE 0 && VARIABLES.cbgAggregatorId GT 0 && VARIABLES.cbgItemYear GT 0) {
            VARIABLES.qCbgOfficialCandidates = queryExecute(
                "SELECT res.id_resultado, res.nome, res.num_peito, res.equipe, res.sexo,
                        res.tempo_total::text AS tempo_total, res.nome_categoria,
                        evt.nome_evento, evt.id_evento,
                        similarity(coalesce(res.nome_normalizado, lower(unaccent(res.nome))), lower(unaccent(:athlete_name))) AS name_score
                 FROM tb_resultados res
                 INNER JOIN tb_evento_corridas evt ON evt.id_evento = res.id_evento
                 INNER JOIN tb_agregadores_eventos agr ON agr.id_evento = evt.id_evento AND agr.agregador_tag = 'brasil-gigante'
                 WHERE (res.id_usuario IS NULL OR res.id_usuario = 0)
                   AND res.percurso >= 42
                   AND res.percurso < 43
                   AND coalesce(res.status_final, 0) < 3
                   AND evt.id_agrega_evento = :aggregator_id
                   AND extract(year FROM evt.data_final) = :race_year
                   AND (
                     (:bib_number > 0 AND res.num_peito = :bib_number)
                     OR similarity(coalesce(res.nome_normalizado, lower(unaccent(res.nome))), lower(unaccent(:athlete_name))) >= 0.20
                   )
                 ORDER BY CASE WHEN :bib_number > 0 AND res.num_peito = :bib_number THEN 0 ELSE 1 END,
                          name_score DESC, res.id_resultado
                 LIMIT 20",
                {
                    athlete_name = {value = VARIABLES.cbgName, cfsqltype = "cf_sql_varchar"},
                    bib_number = {value = val(structKeyExists(VARIABLES.cbgItem, "numero_peito") ? VARIABLES.cbgItem.numero_peito : 0), cfsqltype = "cf_sql_integer"},
                    aggregator_id = {value = VARIABLES.cbgAggregatorId, cfsqltype = "cf_sql_integer"},
                    race_year = {value = VARIABLES.cbgItemYear, cfsqltype = "cf_sql_integer"}
                }
            );
            for (VARIABLES.cbgOfficialRow in VARIABLES.qCbgOfficialCandidates) {
                arrayAppend(VARIABLES.cbgOfficialCandidates, {
                    id = VARIABLES.cbgOfficialRow.id_resultado,
                    eventId = VARIABLES.cbgOfficialRow.id_evento,
                    eventName = VARIABLES.cbgOfficialRow.nome_evento,
                    name = VARIABLES.cbgOfficialRow.nome,
                    bib = VARIABLES.cbgOfficialRow.num_peito,
                    team = VARIABLES.cbgOfficialRow.equipe,
                    sex = VARIABLES.cbgOfficialRow.sexo,
                    time = VARIABLES.cbgOfficialRow.tempo_total,
                    category = VARIABLES.cbgOfficialRow.nome_categoria
                });
            }
        }
        arrayAppend(VARIABLES.cbgValidationRequests, {
            userId = VARIABLES.cbgChallengeRow.id_usuario,
            athleteName = VARIABLES.cbgName,
            email = VARIABLES.cbgChallengeRow.email,
            athleteTag = trim(VARIABLES.cbgChallengeRow.athlete_tag & ""),
            birthDate = VARIABLES.cbgDefaultBirthDate,
            sex = VARIABLES.cbgDefaultSex,
            protocol = structKeyExists(VARIABLES.cbgItem, "protocolo") ? VARIABLES.cbgItem.protocolo : "",
            race = structKeyExists(VARIABLES.cbgItem, "prova") ? VARIABLES.cbgItem.prova : "",
            year = structKeyExists(VARIABLES.cbgItem, "ano") ? VARIABLES.cbgItem.ano : "",
            bib = structKeyExists(VARIABLES.cbgItem, "numero_peito") ? VARIABLES.cbgItem.numero_peito : "",
            officialUrl = structKeyExists(VARIABLES.cbgItem, "link_resultado_oficial") && reFindNoCase("^https?://", trim(VARIABLES.cbgItem.link_resultado_oficial & "")) ? trim(VARIABLES.cbgItem.link_resultado_oficial & "") : "",
            explanation = structKeyExists(VARIABLES.cbgItem, "justificativa") ? VARIABLES.cbgItem.justificativa : "",
            sentAt = structKeyExists(VARIABLES.cbgItem, "data_envio") ? VARIABLES.cbgItem.data_envio : "",
            status = VARIABLES.cbgStatus,
            resultId = structKeyExists(VARIABLES.cbgItem, "id_resultado") ? VARIABLES.cbgItem.id_resultado : "",
            approvalType = structKeyExists(VARIABLES.cbgItem, "tipo_aprovacao") ? VARIABLES.cbgItem.tipo_aprovacao : "",
            rejectionReason = structKeyExists(VARIABLES.cbgItem, "motivo_desaprovacao") ? VARIABLES.cbgItem.motivo_desaprovacao : "",
            officialCandidates = VARIABLES.cbgOfficialCandidates,
            events = structKeyExists(VARIABLES.cbgValidationEventLookup, VARIABLES.cbgLookupKey) ? VARIABLES.cbgValidationEventLookup[VARIABLES.cbgLookupKey] : [],
            files = VARIABLES.cbgFiles
        });
        if (VARIABLES.cbgStatus == "aprovado") VARIABLES.cbgValidationApprovedCount++;
        else if (VARIABLES.cbgStatus == "desaprovado") VARIABLES.cbgValidationRejectedCount++;
        else VARIABLES.cbgValidationPendingCount++;
    }
}
arraySort(VARIABLES.cbgValidationRequests, function(a, b) {
    if (a.status == "pendente" && b.status != "pendente") return -1;
    if (a.status != "pendente" && b.status == "pendente") return 1;
    return compareNoCase(b.sentAt & "", a.sentAt & "");
});
</cfscript>
