<cfparam name="URL.pagina" default="1" />
<cfparam name="URL.busca" default="" />
<cfparam name="URL.status" default="review" />
<cfparam name="URL.ordenar" default="score" />
<cfparam name="URL.direcao" default="desc" />
<cfparam name="URL.sucesso" default="" />
<cfparam name="FORM.acao" default="" />

<cfset VARIABLES.focoReviewPage = max(1, val(URL.pagina)) />
<cfset VARIABLES.focoReviewPerPage = 15 />
<cfset VARIABLES.focoReviewOffset = (VARIABLES.focoReviewPage - 1) * VARIABLES.focoReviewPerPage />
<cfset VARIABLES.focoReviewSearch = trim(URL.busca) />
<cfset VARIABLES.focoReviewStatus = lCase(trim(URL.status)) />
<cfset VARIABLES.focoReviewOrder = lCase(trim(URL.ordenar)) />
<cfset VARIABLES.focoReviewDirection = lCase(trim(URL.direcao)) />
<cfset VARIABLES.focoReviewAllowedStatuses = "review,conflict,dismissed,linked,all" />
<cfset VARIABLES.focoReviewAllowedOrders = "atualizacao,score" />
<cfset VARIABLES.focoReviewAllowedDirections = "asc,desc" />
<cfset VARIABLES.focoReviewNotice = "" />
<cfset VARIABLES.focoReviewError = "" />
<cfset VARIABLES.focoReviewConflictEventId = 0 />
<cfset VARIABLES.focoReviewConflictEventName = "" />
<cfset VARIABLES.focoReviewConflictEventTag = "" />
<cfset VARIABLES.focoReviewConflictCompetitionId = "" />
<cfset VARIABLES.focoReviewConflictCompetitionPath = "" />

<cfif !listFindNoCase(VARIABLES.focoReviewAllowedStatuses, VARIABLES.focoReviewStatus)>
    <cfset VARIABLES.focoReviewStatus = "review" />
</cfif>
<cfif !listFindNoCase(VARIABLES.focoReviewAllowedOrders, VARIABLES.focoReviewOrder)>
    <cfset VARIABLES.focoReviewOrder = "atualizacao" />
</cfif>
<cfif !listFindNoCase(VARIABLES.focoReviewAllowedDirections, VARIABLES.focoReviewDirection)>
    <cfset VARIABLES.focoReviewDirection = "desc" />
</cfif>

<cfquery name="qFocoReviewTables">
    SELECT count(*) AS total
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('tb_foco_event_match_state', 'tb_foco_event_match_candidates', 'tb_evento_foco_vinculos')
</cfquery>
<cfquery name="qFocoReviewColumns">
    SELECT count(*) AS total
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_foco_event_match_state'
      AND column_name IN ('reviewed_by', 'reviewed_at', 'review_note')
</cfquery>
<cfquery name="qFocoReviewCandidateColumns">
    SELECT count(*) AS total
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_foco_event_match_candidates'
      AND column_name IN ('status', 'reviewed_by', 'reviewed_at', 'review_note')
</cfquery>
<cfset VARIABLES.focoReviewSchemaReady = qFocoReviewTables.recordcount
    AND val(qFocoReviewTables.total) EQ 3
    AND qFocoReviewColumns.recordcount
    AND val(qFocoReviewColumns.total) EQ 3
    AND qFocoReviewCandidateColumns.recordcount
    AND val(qFocoReviewCandidateColumns.total) EQ 4 />

<cfif URL.sucesso EQ "vinculado">
    <cfset VARIABLES.focoReviewNotice = "Galeria Foco vinculada com sucesso." />
<cfelseif URL.sucesso EQ "ignorado">
    <cfset VARIABLES.focoReviewNotice = "Candidato Foco ignorado com sucesso." />
<cfelseif URL.sucesso EQ "descartado">
    <cfset VARIABLES.focoReviewNotice = "Caso descartado e removido da fila de revisao." />
<cfelseif URL.sucesso EQ "desvinculado">
    <cfset VARIABLES.focoReviewNotice = "Vinculo Foco removido com sucesso. O evento anterior voltou para reprocessamento." />
</cfif>

<cfif VARIABLES.focoReviewSchemaReady AND len(trim(FORM.acao))>
    <cfset VARIABLES.focoReviewAction = lCase(trim(FORM.acao)) />
    <cfset VARIABLES.focoReviewEventId = isDefined("FORM.id_evento") ? val(FORM.id_evento) : 0 />
    <cfset VARIABLES.focoReviewConflictEventId = isDefined("FORM.id_evento_conflito") ? val(FORM.id_evento_conflito) : 0 />
    <cfset VARIABLES.focoReviewCompetitionId = isDefined("FORM.competition_id") ? trim(FORM.competition_id) : "" />
    <cfset VARIABLES.focoReviewNote = isDefined("FORM.observacao") ? trim(FORM.observacao) : "" />

    <cfif !listFindNoCase("vincular,descartar,ignorar_candidato,desvincular_foco", VARIABLES.focoReviewAction)>
        <cfset VARIABLES.focoReviewError = "Acao de revisao invalida." />
    <cfelseif VARIABLES.focoReviewAction EQ "desvincular_foco" AND (VARIABLES.focoReviewConflictEventId LTE 0 OR !len(VARIABLES.focoReviewCompetitionId))>
        <cfset VARIABLES.focoReviewError = "Vinculo Foco invalido para desvincular." />
    <cfelseif VARIABLES.focoReviewAction NEQ "desvincular_foco" AND VARIABLES.focoReviewEventId LTE 0>
        <cfset VARIABLES.focoReviewError = "Evento invalido." />
    <cfelseif listFindNoCase("vincular,ignorar_candidato", VARIABLES.focoReviewAction) AND !len(VARIABLES.focoReviewCompetitionId)>
        <cfset VARIABLES.focoReviewError = "Selecione uma competicao para revisar." />
    </cfif>

    <cfif !len(VARIABLES.focoReviewError)>
        <cftry>
            <cftransaction>
                <cfif VARIABLES.focoReviewAction EQ "desvincular_foco">
                    <cfquery>
                        SELECT pg_advisory_xact_lock(
                            hashtext(<cfqueryparam cfsqltype="cf_sql_varchar" value="foco:#VARIABLES.focoReviewCompetitionId#" />)
                        )
                    </cfquery>

                    <cfquery name="qFocoReviewLinkToUnlink">
                        SELECT link.id_evento, evt.nome_evento
                        FROM tb_evento_foco_vinculos link
                        INNER JOIN tb_evento_corridas evt ON evt.id_evento = link.id_evento
                        WHERE link.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewConflictEventId#" />
                          AND link.status = 'active'
                          AND trim(link.competition_id) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />
                        FOR UPDATE
                    </cfquery>

                    <cfif !qFocoReviewLinkToUnlink.recordcount>
                        <cfthrow type="FocoReview.Validation" message="Vinculo Foco nao encontrado para desvincular." />
                    </cfif>

                    <cfquery>
                        UPDATE tb_evento_foco_vinculos
                        SET status = 'unlinked',
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewNote#" null="#!len(VARIABLES.focoReviewNote)#" />,
                            data_atualizacao = now()
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewConflictEventId#" />
                          AND trim(competition_id) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />
                    </cfquery>

                    <cfquery>
                        UPDATE tb_foco_event_match_state
                        SET status = 'pending',
                            matched_competition_id = NULL,
                            matched_competition_name = NULL,
                            match_mode = 'manual_unlinked',
                            next_attempt_at = now(),
                            processing_until = NULL,
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewNote#" null="#!len(VARIABLES.focoReviewNote)#" />,
                            last_error = NULL,
                            data_atualizacao = now()
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewConflictEventId#" />
                    </cfquery>

                    <cfquery>
                        DELETE FROM tb_badges
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewConflictEventId#" />
                          AND badge = 'foco'
                          AND percurso = 0
                          AND trim(valor_badge) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />
                    </cfquery>

                    <cfquery name="qFocoReviewReplacementLink">
                        SELECT *
                        FROM tb_evento_foco_vinculos
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewConflictEventId#" />
                          AND status = 'active'
                        ORDER BY data_atualizacao DESC, id_evento_foco_vinculo DESC
                        LIMIT 1
                    </cfquery>

                    <cfif qFocoReviewReplacementLink.recordcount>
                        <cfquery>
                            INSERT INTO tb_badges
                                (id_evento, percurso, badge, valor_badge, complemento_badge, badge_raw)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#qFocoReviewReplacementLink.id_evento#" />,
                                0, 'foco',
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qFocoReviewReplacementLink.competition_id#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#qFocoReviewReplacementLink.identification_type#" />,
                                CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#toString(qFocoReviewReplacementLink.payload)#" /> AS jsonb)
                            )
                            ON CONFLICT (id_evento, percurso, badge)
                            DO UPDATE SET
                                valor_badge = excluded.valor_badge,
                                complemento_badge = excluded.complemento_badge,
                                badge_raw = excluded.badge_raw
                        </cfquery>
                    </cfif>
                <cfelse>
                    <cfquery name="qFocoReviewStateLock">
                        SELECT state.id_evento, state.status, evt.nome_evento
                        FROM tb_foco_event_match_state state
                        INNER JOIN tb_evento_corridas evt ON evt.id_evento = state.id_evento
                        WHERE state.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                        FOR UPDATE
                    </cfquery>

                    <cfif !qFocoReviewStateLock.recordcount>
                        <cfthrow type="FocoReview.Validation" message="Caso de revisao nao encontrado." />
                    </cfif>
                    <cfif !listFindNoCase("review,conflict,linked", qFocoReviewStateLock.status)>
                        <cfthrow type="FocoReview.Validation" message="Este caso nao esta mais disponivel para revisao." />
                    </cfif>
                </cfif>

                <cfif VARIABLES.focoReviewAction EQ "descartar">
                    <cfquery>
                        UPDATE tb_foco_event_match_state
                        SET status = 'dismissed',
                            match_mode = 'manual_dismissed',
                            next_attempt_at = NULL,
                            processing_until = NULL,
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewNote#" null="#!len(VARIABLES.focoReviewNote)#" />,
                            data_atualizacao = now()
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                    </cfquery>
                <cfelseif VARIABLES.focoReviewAction EQ "ignorar_candidato">
                    <cfquery name="qFocoReviewCandidateToIgnore">
                        SELECT candidate.id_evento, candidate.competition_id
                        FROM tb_foco_event_match_candidates candidate
                        WHERE candidate.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                          AND candidate.competition_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />
                          AND candidate.status = 'active'
                          AND candidate.exact_place = true
                        FOR UPDATE
                    </cfquery>

                    <cfif !qFocoReviewCandidateToIgnore.recordcount>
                        <cfthrow type="FocoReview.Validation" message="Candidato ativo da mesma cidade nao encontrado para ignorar." />
                    </cfif>

                    <cfquery>
                        UPDATE tb_foco_event_match_candidates
                        SET status = 'ignored',
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewNote#" null="#!len(VARIABLES.focoReviewNote)#" />
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                          AND competition_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />
                    </cfquery>

                    <cfquery name="qFocoReviewRemainingCandidates">
                        SELECT count(*) AS total
                        FROM tb_foco_event_match_candidates candidate
                        WHERE candidate.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                          AND candidate.status = 'active'
                          AND candidate.exact_place = true
                          AND candidate.score >= 60
                          AND NOT EXISTS (
                              SELECT 1
                              FROM tb_evento_foco_vinculos link
                              WHERE link.status = 'active'
                                AND link.competition_id = candidate.competition_id
                          )
                    </cfquery>

                    <cfquery name="qFocoReviewActiveLinksAfterIgnore">
                        SELECT count(*) AS total
                        FROM tb_evento_foco_vinculos
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                          AND status = 'active'
                    </cfquery>

                    <cfif val(qFocoReviewRemainingCandidates.total) GT 0>
                        <cfset VARIABLES.focoReviewStateAfterIgnore = "review" />
                        <cfset VARIABLES.focoReviewMatchModeAfterIgnore = "manual_partial_review" />
                    <cfelseif val(qFocoReviewActiveLinksAfterIgnore.total) GT 0>
                        <cfset VARIABLES.focoReviewStateAfterIgnore = "linked" />
                        <cfset VARIABLES.focoReviewMatchModeAfterIgnore = "manual_review_completed" />
                    <cfelse>
                        <cfset VARIABLES.focoReviewStateAfterIgnore = "dismissed" />
                        <cfset VARIABLES.focoReviewMatchModeAfterIgnore = "manual_candidates_ignored" />
                    </cfif>

                    <cfquery>
                        UPDATE tb_foco_event_match_state
                        SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewStateAfterIgnore#" />,
                            match_mode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewMatchModeAfterIgnore#" />,
                            next_attempt_at = NULL,
                            processing_until = NULL,
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewNote#" null="#!len(VARIABLES.focoReviewNote)#" />,
                            last_error = NULL,
                            data_atualizacao = now()
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                    </cfquery>
                <cfelseif VARIABLES.focoReviewAction EQ "vincular">
                    <cfquery name="qFocoReviewCandidate">
                        SELECT candidate.*,
                               candidate.payload ->> 'identification_by_face' AS identification_by_face,
                               candidate.payload ->> 'competition_path' AS competition_path
                        FROM tb_foco_event_match_candidates candidate
                        WHERE candidate.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                          AND candidate.competition_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />
                          AND candidate.status = 'active'
                          AND candidate.exact_place = true
                        FOR UPDATE
                    </cfquery>

                    <cfif !qFocoReviewCandidate.recordcount>
                        <cfthrow type="FocoReview.Validation" message="Candidato ativo da mesma cidade nao encontrado para este evento." />
                    </cfif>
                    <cfif val(qFocoReviewCandidate.score) LT 60>
                        <cfthrow type="FocoReview.Validation" message="Candidato abaixo de 60 pontos nao pode ser vinculado; descarte ou mantenha para nova avaliacao." />
                    </cfif>

                    <cfquery>
                        SELECT pg_advisory_xact_lock(
                            hashtext(<cfqueryparam cfsqltype="cf_sql_varchar" value="foco:#VARIABLES.focoReviewCompetitionId#" />)
                        )
                    </cfquery>

                    <cfquery name="qFocoReviewCompetitionConflict">
                        SELECT link.id_evento, evt.nome_evento, evt.tag, link.competition_path
                        FROM tb_evento_foco_vinculos link
                        INNER JOIN tb_evento_corridas evt ON evt.id_evento = link.id_evento
                        WHERE link.status = 'active'
                          AND link.competition_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />
                          AND link.id_evento <> <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                        LIMIT 1
                        FOR UPDATE
                    </cfquery>
                    <cfif qFocoReviewCompetitionConflict.recordcount>
                        <cfset VARIABLES.focoReviewConflictEventId = val(qFocoReviewCompetitionConflict.id_evento) />
                        <cfset VARIABLES.focoReviewConflictEventName = trim(qFocoReviewCompetitionConflict.nome_evento & "") />
                        <cfset VARIABLES.focoReviewConflictEventTag = trim(qFocoReviewCompetitionConflict.tag & "") />
                        <cfset VARIABLES.focoReviewConflictCompetitionId = VARIABLES.focoReviewCompetitionId />
                        <cfset VARIABLES.focoReviewConflictCompetitionPath = trim(qFocoReviewCompetitionConflict.competition_path & "") />
                        <cfthrow type="FocoReview.Validation" message="Esta competicao Foco ja esta vinculada a outro evento." />
                    </cfif>

                    <cfset VARIABLES.focoReviewIdentificationType = "numero" />
                    <cfif !isNull(qFocoReviewCandidate.identification_by_face)
                        AND val(qFocoReviewCandidate.identification_by_face) EQ 1
                        AND !isNull(qFocoReviewCandidate.competition_path)
                        AND len(trim(qFocoReviewCandidate.competition_path & ""))>
                        <cfset VARIABLES.focoReviewIdentificationType = trim(qFocoReviewCandidate.competition_path & "") />
                    </cfif>
                    <cfset VARIABLES.focoReviewCandidatePayload = toString(qFocoReviewCandidate.payload) />
                    <cfset VARIABLES.focoReviewCandidatePayloadStruct = {} />
                    <cfif len(trim(VARIABLES.focoReviewCandidatePayload)) AND isJSON(VARIABLES.focoReviewCandidatePayload)>
                        <cfset VARIABLES.focoReviewCandidatePayloadStruct = deserializeJSON(VARIABLES.focoReviewCandidatePayload) />
                    </cfif>
                    <cfset VARIABLES.focoReviewCandidateName = isNull(qFocoReviewCandidate.competition_name)
                        ? ""
                        : trim(qFocoReviewCandidate.competition_name & "") />
                    <cfif !len(VARIABLES.focoReviewCandidateName) AND structKeyExists(VARIABLES.focoReviewCandidatePayloadStruct, "competition_name")>
                        <cfset VARIABLES.focoReviewCandidateName = trim(VARIABLES.focoReviewCandidatePayloadStruct.competition_name & "") />
                    </cfif>
                    <cfset VARIABLES.focoReviewCandidateDate = qFocoReviewCandidate.competition_date />
                    <cfif !isDate(VARIABLES.focoReviewCandidateDate) AND structKeyExists(VARIABLES.focoReviewCandidatePayloadStruct, "date")>
                        <cfset VARIABLES.focoReviewCandidateDate = trim(VARIABLES.focoReviewCandidatePayloadStruct.date & "") />
                    </cfif>
                    <cfset VARIABLES.focoReviewCandidatePlace = isNull(qFocoReviewCandidate.place)
                        ? ""
                        : trim(qFocoReviewCandidate.place & "") />
                    <cfif !len(VARIABLES.focoReviewCandidatePlace) AND structKeyExists(VARIABLES.focoReviewCandidatePayloadStruct, "place")>
                        <cfset VARIABLES.focoReviewCandidatePlace = trim(VARIABLES.focoReviewCandidatePayloadStruct.place & "") />
                    </cfif>
                    <cfset VARIABLES.focoReviewCandidateUf = isNull(qFocoReviewCandidate.uf)
                        ? ""
                        : trim(qFocoReviewCandidate.uf & "") />
                    <cfif !len(VARIABLES.focoReviewCandidateUf) AND structKeyExists(VARIABLES.focoReviewCandidatePayloadStruct, "UF")>
                        <cfset VARIABLES.focoReviewCandidateUf = trim(VARIABLES.focoReviewCandidatePayloadStruct.UF & "") />
                    </cfif>
                    <cfset VARIABLES.focoReviewCompetitionPath = isNull(qFocoReviewCandidate.competition_path)
                        ? ""
                        : trim(qFocoReviewCandidate.competition_path & "") />
                    <cfif !len(VARIABLES.focoReviewCompetitionPath) AND structKeyExists(VARIABLES.focoReviewCandidatePayloadStruct, "competition_path")>
                        <cfset VARIABLES.focoReviewCompetitionPath = trim(VARIABLES.focoReviewCandidatePayloadStruct.competition_path & "") />
                    </cfif>

                    <cfquery>
                        INSERT INTO tb_evento_foco_vinculos
                            (id_evento, competition_id, competition_name, competition_date,
                             place, uf, competition_path, identification_type, score,
                             match_mode, status, payload, reviewed_by, reviewed_at, review_note)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCandidateName#" null="#!len(VARIABLES.focoReviewCandidateName)#" />,
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.focoReviewCandidateDate#" null="#!isDate(VARIABLES.focoReviewCandidateDate)#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCandidatePlace#" null="#!len(VARIABLES.focoReviewCandidatePlace)#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCandidateUf#" null="#!len(VARIABLES.focoReviewCandidateUf)#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionPath#" null="#!len(VARIABLES.focoReviewCompetitionPath)#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewIdentificationType#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" scale="2" value="#qFocoReviewCandidate.score#" />,
                            'manual_review',
                            'active',
                            CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewCandidatePayload#" /> AS jsonb),
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            now(),
                            <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewNote#" null="#!len(VARIABLES.focoReviewNote)#" />
                        )
                        ON CONFLICT (id_evento, competition_id)
                        DO UPDATE SET
                            competition_name = excluded.competition_name,
                            competition_date = excluded.competition_date,
                            place = excluded.place,
                            uf = excluded.uf,
                            competition_path = excluded.competition_path,
                            identification_type = excluded.identification_type,
                            score = excluded.score,
                            match_mode = excluded.match_mode,
                            status = 'active',
                            payload = excluded.payload,
                            reviewed_by = excluded.reviewed_by,
                            reviewed_at = now(),
                            review_note = excluded.review_note,
                            data_atualizacao = now()
                    </cfquery>

                    <cfquery name="qFocoReviewPrimaryBadge">
                        SELECT valor_badge
                        FROM tb_badges
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                          AND badge = 'foco'
                          AND percurso = 0
                        LIMIT 1
                        FOR UPDATE
                    </cfquery>
                    <cfif !qFocoReviewPrimaryBadge.recordcount>
                        <cfquery>
                        INSERT INTO tb_badges
                            (id_evento, percurso, badge, valor_badge, complemento_badge, badge_raw)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />,
                            0, 'foco',
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewIdentificationType#" />,
                            CAST(<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewCandidatePayload#" /> AS jsonb)
                        )
                        ON CONFLICT (id_evento, percurso, badge)
                        DO UPDATE SET
                            valor_badge = excluded.valor_badge,
                            complemento_badge = excluded.complemento_badge,
                            badge_raw = excluded.badge_raw
                        </cfquery>
                    </cfif>

                    <cfquery name="qFocoReviewRemainingCandidates">
                        SELECT count(*) AS total
                        FROM tb_foco_event_match_candidates candidate
                        WHERE candidate.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                          AND candidate.score >= 60
                          AND candidate.status = 'active'
                          AND candidate.exact_place = true
                          AND NOT EXISTS (
                              SELECT 1
                              FROM tb_evento_foco_vinculos link
                              WHERE link.status = 'active'
                                AND link.competition_id = candidate.competition_id
                          )
                    </cfquery>

                    <cfset VARIABLES.focoReviewStateAfterLink = val(qFocoReviewRemainingCandidates.total) GT 0 ? "review" : "linked" />
                    <cfset VARIABLES.focoReviewMatchModeAfterLink = VARIABLES.focoReviewStateAfterLink EQ "review" ? "manual_partial_review" : "manual_review" />

                    <cfquery>
                        UPDATE tb_foco_event_match_state
                        SET status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewStateAfterLink#" />,
                            matched_competition_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCompetitionId#" />,
                            matched_competition_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewCandidateName#" null="#!len(VARIABLES.focoReviewCandidateName)#" />,
                            match_mode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewMatchModeAfterLink#" />,
                            next_attempt_at = NULL,
                            processing_until = NULL,
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.focoReviewNote#" null="#!len(VARIABLES.focoReviewNote)#" />,
                            last_error = NULL,
                            data_atualizacao = now()
                        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewEventId#" />
                    </cfquery>
                </cfif>
            </cftransaction>

            <cfif VARIABLES.focoReviewAction EQ "vincular">
                <cfset VARIABLES.focoReviewSuccessCode = "vinculado" />
            <cfelseif VARIABLES.focoReviewAction EQ "ignorar_candidato">
                <cfset VARIABLES.focoReviewSuccessCode = "ignorado" />
            <cfelseif VARIABLES.focoReviewAction EQ "desvincular_foco">
                <cfset VARIABLES.focoReviewSuccessCode = "desvinculado" />
            <cfelse>
                <cfset VARIABLES.focoReviewSuccessCode = "descartado" />
            </cfif>
            <cflocation addtoken="false" url="./?status=#urlEncodedFormat(VARIABLES.focoReviewStatus)#&ordenar=#urlEncodedFormat(VARIABLES.focoReviewOrder)#&direcao=#urlEncodedFormat(VARIABLES.focoReviewDirection)#&sucesso=#VARIABLES.focoReviewSuccessCode#" />
            <cfcatch type="any">
                <cfset VARIABLES.focoReviewError = cfcatch.message />
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfset qFocoReviewStats = queryNew("total,review,conflict,linked,dismissed") />
<cfset qFocoReviewItems = queryNew("id_evento,status,candidate_count,matched_competition_id,matched_competition_name,match_mode,last_checked_at,data_atualizacao,max_score,nome_evento,nome_simplificado,cidade,estado,data_inicial,data_final,tag") />
<cfset qFocoReviewCandidates = queryNew("id_evento,competition_id,competition_name,competition_date,place,uf,score,exact_name,exact_date,exact_place,exact_uf,identification_by_face,competition_path,is_linked") />
<cfset qFocoReviewLinkedGalleries = queryNew("id_evento,competition_id,competition_name,competition_date,place,uf,competition_path,score,match_mode,data_atualizacao") />
<cfset VARIABLES.focoReviewTotal = 0 />
<cfset VARIABLES.focoReviewTotalPages = 1 />

<cfif VARIABLES.focoReviewSchemaReady>
    <cfquery name="qFocoReviewStats">
        SELECT count(*) AS total,
               count(*) FILTER (
                   WHERE state.status IN ('review', 'linked')
                     AND EXISTS (
                         SELECT 1
                         FROM tb_foco_event_match_candidates pending_candidate
                         WHERE pending_candidate.id_evento = state.id_evento
                           AND pending_candidate.status = 'active'
                           AND pending_candidate.exact_place = true
                           AND pending_candidate.score >= 60
                           AND NOT EXISTS (
                               SELECT 1
                               FROM tb_evento_foco_vinculos pending_link
                               WHERE pending_link.status = 'active'
                                 AND pending_link.competition_id = pending_candidate.competition_id
                           )
                     )
               ) AS review,
               count(*) FILTER (WHERE state.status = 'conflict') AS conflict,
               count(*) FILTER (WHERE state.status = 'linked') AS linked,
               count(*) FILTER (WHERE state.status = 'dismissed') AS dismissed
        FROM tb_foco_event_match_state state
    </cfquery>

    <cfquery name="qFocoReviewCount">
        SELECT count(*) AS total
        FROM tb_foco_event_match_state state
        INNER JOIN tb_evento_corridas evt ON evt.id_evento = state.id_evento
        WHERE 1 = 1
        <cfif VARIABLES.focoReviewStatus EQ "review">
            AND (
                state.status IN ('review', 'linked')
                AND EXISTS (
                    SELECT 1
                    FROM tb_foco_event_match_candidates pending_candidate
                    WHERE pending_candidate.id_evento = state.id_evento
                      AND pending_candidate.status = 'active'
                      AND pending_candidate.exact_place = true
                      AND pending_candidate.score >= 60
                      AND NOT EXISTS (
                          SELECT 1
                          FROM tb_evento_foco_vinculos pending_link
                          WHERE pending_link.status = 'active'
                            AND pending_link.competition_id = pending_candidate.competition_id
                      )
                )
            )
        <cfelseif VARIABLES.focoReviewStatus NEQ "all">
            AND state.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewStatus#" />
        </cfif>
        <cfif len(VARIABLES.focoReviewSearch)>
            AND (
                evt.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.focoReviewSearch#%" />
                OR cast(evt.id_evento AS varchar) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewSearch#" />
                OR coalesce(state.matched_competition_id, '') = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewSearch#" />
            )
        </cfif>
    </cfquery>
    <cfset VARIABLES.focoReviewTotal = val(qFocoReviewCount.total) />
    <cfset VARIABLES.focoReviewTotalPages = max(1, ceiling(VARIABLES.focoReviewTotal / VARIABLES.focoReviewPerPage)) />
    <cfset VARIABLES.focoReviewPage = min(VARIABLES.focoReviewPage, VARIABLES.focoReviewTotalPages) />
    <cfset VARIABLES.focoReviewOffset = (VARIABLES.focoReviewPage - 1) * VARIABLES.focoReviewPerPage />

    <cfquery name="qFocoReviewItems">
        SELECT state.id_evento, state.status, state.candidate_count,
               state.matched_competition_id, state.matched_competition_name,
               state.match_mode, state.last_checked_at, state.data_atualizacao,
               coalesce(candidate_score.max_score, 0) AS max_score,
               evt.nome_evento, evt.nome_simplificado, evt.cidade, evt.estado,
               evt.data_inicial, evt.data_final, evt.tag
        FROM tb_foco_event_match_state state
        INNER JOIN tb_evento_corridas evt ON evt.id_evento = state.id_evento
        LEFT JOIN (
            SELECT id_evento, max(score) AS max_score
            FROM tb_foco_event_match_candidates
            WHERE status = 'active'
              AND exact_place = true
            GROUP BY id_evento
        ) candidate_score ON candidate_score.id_evento = state.id_evento
        WHERE 1 = 1
        <cfif VARIABLES.focoReviewStatus EQ "review">
            AND (
                state.status IN ('review', 'linked')
                AND EXISTS (
                    SELECT 1
                    FROM tb_foco_event_match_candidates pending_candidate
                    WHERE pending_candidate.id_evento = state.id_evento
                      AND pending_candidate.status = 'active'
                      AND pending_candidate.exact_place = true
                      AND pending_candidate.score >= 60
                      AND NOT EXISTS (
                          SELECT 1
                          FROM tb_evento_foco_vinculos pending_link
                          WHERE pending_link.status = 'active'
                            AND pending_link.competition_id = pending_candidate.competition_id
                      )
                )
            )
        <cfelseif VARIABLES.focoReviewStatus NEQ "all">
            AND state.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewStatus#" />
        </cfif>
        <cfif len(VARIABLES.focoReviewSearch)>
            AND (
                evt.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.focoReviewSearch#%" />
                OR cast(evt.id_evento AS varchar) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewSearch#" />
                OR coalesce(state.matched_competition_id, '') = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.focoReviewSearch#" />
            )
        </cfif>
        ORDER BY
        <cfif VARIABLES.focoReviewOrder EQ "score">
            candidate_score.max_score <cfif VARIABLES.focoReviewDirection EQ "asc">ASC NULLS FIRST<cfelse>DESC NULLS LAST</cfif>,
            state.data_atualizacao DESC,
            state.id_evento DESC
        <cfelse>
            state.data_atualizacao <cfif VARIABLES.focoReviewDirection EQ "asc">ASC<cfelse>DESC</cfif>,
            state.id_evento DESC
        </cfif>
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewPerPage#" />
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.focoReviewOffset#" />
    </cfquery>

    <cfif qFocoReviewItems.recordcount>
        <cfquery name="qFocoReviewLinkedGalleries">
            SELECT id_evento, competition_id,
                   coalesce(competition_name, '') AS competition_name,
                   competition_date,
                   coalesce(place, '') AS place,
                   coalesce(uf, '') AS uf,
                   coalesce(competition_path, '') AS competition_path,
                   score, match_mode, data_atualizacao
            FROM tb_evento_foco_vinculos
            WHERE status = 'active'
              AND id_evento IN (
                  <cfqueryparam cfsqltype="cf_sql_integer" value="#valueList(qFocoReviewItems.id_evento)#" list="true" />
              )
            ORDER BY id_evento, data_atualizacao DESC, id_evento_foco_vinculo DESC
        </cfquery>

        <cfquery name="qFocoReviewCandidates">
            SELECT candidate.id_evento, candidate.competition_id,
                   coalesce(candidate.competition_name, '') AS competition_name,
                   candidate.competition_date,
                   coalesce(candidate.place, '') AS place,
                   coalesce(candidate.uf, '') AS uf, candidate.score,
                   candidate.exact_name, candidate.exact_date,
                   candidate.exact_place, candidate.exact_uf,
                   candidate.payload ->> 'identification_by_face' AS identification_by_face,
                   candidate.payload ->> 'competition_path' AS competition_path,
                   false AS is_linked
            FROM tb_foco_event_match_candidates candidate
            WHERE candidate.id_evento IN (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#valueList(qFocoReviewItems.id_evento)#" list="true" />
            )
              AND candidate.status = 'active'
              AND candidate.exact_place = true
              AND NOT EXISTS (
                  SELECT 1
                  FROM tb_evento_foco_vinculos link
                  WHERE link.status = 'active'
                    AND link.competition_id = candidate.competition_id
              )
            ORDER BY candidate.id_evento, candidate.score DESC, candidate.competition_name
        </cfquery>
    </cfif>
</cfif>
