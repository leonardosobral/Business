<cfprocessingdirective pageencoding="utf-8" />

<cfparam name="URL.pagina" default="1" />
<cfparam name="URL.busca" default="" />
<cfparam name="URL.status" default="review" />
<cfparam name="URL.ordenar" default="score" />
<cfparam name="URL.direcao" default="desc" />
<cfparam name="URL.grupo" default="0" />
<cfparam name="URL.agregador_busca" default="" />
<cfparam name="URL.evento_busca" default="" />
<cfparam name="URL.manual_nome" default="" />
<cfparam name="URL.manual_cidade" default="" />
<cfparam name="URL.sucesso" default="" />
<cfparam name="FORM.acao" default="" />

<cfinclude template="matching.cfm" />

<cfscript>
function agregaReviewDisplayName(value) {
    var text = trim(toString(value));
    var words = [];
    var formattedWords = [];
    var word = "";
    var lowerWord = "";

    text = agregaReviewStripEdition(agregaReviewReplace(text, "\b(?:19|20)[0-9]{2}\b", " "));
    text = trim(agregaReviewReplace(text, "\s+", " "));

    words = listToArray(lCase(text), " ");

    for (word in words) {
        lowerWord = lCase(trim(word));
        if (!len(lowerWord)) {
            continue;
        }

        if (listFindNoCase("de,da,do,das,dos,e,em,no,na,nos,nas,ao,aos", lowerWord)) {
            arrayAppend(formattedWords, lowerWord);
        } else {
            arrayAppend(formattedWords, uCase(left(lowerWord, 1)) & mid(lowerWord, 2, len(lowerWord)));
        }
    }

    return arrayToList(formattedWords, " ");
}

function agregaReviewTokenScore(leftText, rightText) {
    var leftTokens = listToArray(agregaReviewNormalizeText(leftText), " ");
    var rightTokens = listToArray(agregaReviewNormalizeText(rightText), " ");
    var leftSet = {};
    var rightSet = {};
    var unionSet = {};
    var token = "";
    var intersection = 0;
    var unionTotal = 0;

    for (token in leftTokens) {
        if (len(trim(token)) >= 3) {
            leftSet[token] = true;
            unionSet[token] = true;
        }
    }
    for (token in rightTokens) {
        if (len(trim(token)) >= 3) {
            rightSet[token] = true;
            unionSet[token] = true;
        }
    }

    for (token in unionSet) {
        unionTotal = unionTotal + 1;
        if (structKeyExists(leftSet, token) AND structKeyExists(rightSet, token)) {
            intersection = intersection + 1;
        }
    }

    if (unionTotal EQ 0) {
        return 0;
    }

    return round((intersection / unionTotal) * 10000) / 100;
}

function agregaReviewBuildGroupKey(normalizedName, cidade, estado) {
    return lCase(hash(trim(normalizedName) & "|" & trim(cidade) & "|" & trim(estado), "SHA-256"));
}

function agregaReviewIdInList(listValue, idValue) {
    return listFind(listValue, toString(val(idValue))) GT 0;
}

</cfscript>

<cfset VARIABLES.agregaReviewPage = val(URL.pagina) />
<cfif VARIABLES.agregaReviewPage LT 1>
    <cfset VARIABLES.agregaReviewPage = 1 />
</cfif>
<cfset VARIABLES.agregaReviewPerPage = 10 />
<cfset VARIABLES.agregaReviewOffset = (VARIABLES.agregaReviewPage - 1) * VARIABLES.agregaReviewPerPage />
<cfset VARIABLES.agregaReviewSearch = trim(URL.busca) />
<cfset VARIABLES.agregaReviewStatus = lCase(trim(URL.status)) />
<cfset VARIABLES.agregaReviewOrder = lCase(trim(URL.ordenar)) />
<cfset VARIABLES.agregaReviewDirection = lCase(trim(URL.direcao)) />
<cfset VARIABLES.agregaReviewFocusGroupId = val(URL.grupo) />
<cfset VARIABLES.agregaReviewAggregatorSearchTerm = trim(URL.agregador_busca) />
<cfset VARIABLES.agregaReviewEventSearchTerm = trim(URL.evento_busca) />
<cfset VARIABLES.agregaReviewEventSearchRequested = len(VARIABLES.agregaReviewEventSearchTerm) GTE 2 />
<cfset VARIABLES.agregaReviewEventSearchLimit = 100 />
<cfset VARIABLES.agregaReviewManualName = trim(URL.manual_nome) />
<cfset VARIABLES.agregaReviewManualCity = trim(URL.manual_cidade) />
<cfset VARIABLES.agregaReviewManualSearchError = "" />
<cfset VARIABLES.agregaReviewManualSearchLimit = 100 />
<cfset VARIABLES.agregaReviewAllowedStatuses = "review,applied,ignored,all" />
<cfset VARIABLES.agregaReviewAllowedOrders = "score,nome,atualizacao" />
<cfset VARIABLES.agregaReviewAllowedDirections = "asc,desc" />
<cfset VARIABLES.agregaReviewNotice = "" />
<cfset VARIABLES.agregaReviewError = "" />
<cfset VARIABLES.agregaReviewGeneratedGroups = 0 />
<cfset VARIABLES.agregaReviewGeneratedCandidates = 0 />
<cfset qAgregaReviewManualEvents = queryNew("id_evento") />
<cfset qAgregaReviewEventSearch = queryNew("id_evento") />

<cfif lCase(trim(FORM.acao)) EQ "criar_grupo_manual">
    <cfif isDefined("FORM.manual_nome")>
        <cfset VARIABLES.agregaReviewManualName = trim(FORM.manual_nome) />
    </cfif>
    <cfif isDefined("FORM.manual_cidade")>
        <cfset VARIABLES.agregaReviewManualCity = trim(FORM.manual_cidade) />
    </cfif>
</cfif>

<cfif !listFindNoCase(VARIABLES.agregaReviewAllowedStatuses, VARIABLES.agregaReviewStatus)>
    <cfset VARIABLES.agregaReviewStatus = "review" />
</cfif>
<cfif !listFindNoCase(VARIABLES.agregaReviewAllowedOrders, VARIABLES.agregaReviewOrder)>
    <cfset VARIABLES.agregaReviewOrder = "atualizacao" />
</cfif>
<cfif !listFindNoCase(VARIABLES.agregaReviewAllowedDirections, VARIABLES.agregaReviewDirection)>
    <cfset VARIABLES.agregaReviewDirection = "desc" />
</cfif>

<cfquery name="qAgregaReviewTables">
    SELECT count(*) AS total
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('tb_evento_agrega_review_groups', 'tb_evento_agrega_review_candidates')
</cfquery>
<cfquery name="qAgregaReviewDisplayNameColumn">
    SELECT count(*) AS total
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_evento_agrega_review_groups'
      AND column_name = 'display_name'
</cfquery>
<cfquery name="qAgregaReviewScoreIndex">
    SELECT count(*) AS total
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'tb_evento_agrega_review_groups'
      AND indexname = 'tb_evento_agrega_review_groups_score_idx'
</cfquery>
<cfset VARIABLES.agregaReviewSchemaReady = qAgregaReviewTables.recordcount AND val(qAgregaReviewTables.total) EQ 2 />
<cfset VARIABLES.agregaReviewHasDisplayName = qAgregaReviewDisplayNameColumn.recordcount AND val(qAgregaReviewDisplayNameColumn.total) EQ 1 />
<cfset VARIABLES.agregaReviewHasScoreIndex = qAgregaReviewScoreIndex.recordcount AND val(qAgregaReviewScoreIndex.total) EQ 1 />

<cfif URL.sucesso EQ "gerado">
    <cfset VARIABLES.agregaReviewNotice = "Sugestões de agregação geradas com sucesso." />
    <cfif structKeyExists(SESSION, "agregaReviewGenerationNotice")>
        <cfset VARIABLES.agregaReviewNotice = SESSION.agregaReviewGenerationNotice />
        <cfset structDelete(SESSION, "agregaReviewGenerationNotice") />
    </cfif>
<cfelseif URL.sucesso EQ "sugestao_aceita">
    <cfset VARIABLES.agregaReviewNotice = "Agregador criado e as duas provas vinculadas. Sugestão concluída." />
<cfelseif URL.sucesso EQ "sugestao_vinculada">
    <cfset VARIABLES.agregaReviewNotice = "Prova vinculada ao agregador existente. Sugestão concluída." />
<cfelseif URL.sucesso EQ "sugestao_ja_aplicada">
    <cfset VARIABLES.agregaReviewNotice = "Esta sugestão já foi aplicada. Nenhum vínculo foi alterado novamente." />
<cfelseif URL.sucesso EQ "aplicado">
    <cfset VARIABLES.agregaReviewNotice = "Agregador aplicado aos eventos selecionados." />
<cfelseif URL.sucesso EQ "ignorado">
    <cfset VARIABLES.agregaReviewNotice = "Item removido da revisao." />
<cfelseif URL.sucesso EQ "agregador_criado">
    <cfset VARIABLES.agregaReviewNotice = "Agregador criado e selecionado para o grupo de revisao." />
<cfelseif URL.sucesso EQ "agregador_existente">
    <cfset VARIABLES.agregaReviewNotice = "Ja existia um agregador com este nome ou tag. Ele foi selecionado para o grupo de revisao." />
<cfelseif URL.sucesso EQ "grupo_manual">
    <cfset VARIABLES.agregaReviewNotice = "Grupo criado manualmente e adicionado a revisao." />
<cfelseif URL.sucesso EQ "candidatos_adicionados">
    <cfset VARIABLES.agregaReviewNotice = "Os eventos selecionados foram adicionados ao grupo de revisao." />
</cfif>

<cfif VARIABLES.agregaReviewSchemaReady AND len(trim(FORM.acao))>
    <cfset VARIABLES.agregaReviewAction = listLast(lCase(trim(FORM.acao))) />

    <cftry>
        <cfif VARIABLES.agregaReviewAction EQ "gerar_sugestoes">
            <cfsetting requesttimeout="120" />
            <cfparam name="FORM.ano_base" default="#year(now())-1#" />
            <cfparam name="FORM.ano_comparado" default="#year(now())#" />
            <cfif NOT reFind("^[0-9]{4}$", FORM.ano_base) OR NOT reFind("^[0-9]{4}$", FORM.ano_comparado)
                OR val(FORM.ano_base) LT 1900 OR val(FORM.ano_comparado) GT year(now())+2
                OR val(FORM.ano_comparado) NEQ val(FORM.ano_base)+1>
                <cfthrow type="AgregaReview.Validation" message="Escolha dois anos consecutivos válidos." />
            </cfif>
            <cfset VARIABLES.agregaReviewFirstYear = val(FORM.ano_base) />
            <cfset VARIABLES.agregaReviewSecondYear = val(FORM.ano_comparado) />
            <cfset VARIABLES.agregaReviewAlreadyReviewed = 0 />
            <cfquery name="qAgregaReviewSourceEvents" timeout="30">
                SELECT evt.id_evento, coalesce(evt.nome_evento, '') AS nome_evento,
                       coalesce(evt.cidade, '') AS cidade, coalesce(evt.estado, '') AS estado,
                       coalesce(evt.pais, '') AS pais, coalesce(evt.tag, '') AS tag,
                       evt.data_inicial, coalesce(evt.data_final, evt.data_inicial) AS data_comparacao,
                       coalesce(evt.id_agrega_evento, 0) AS id_agrega_evento,
                       coalesce(agr.tipo_agregacao, '') AS tipo_agregacao,
                       coalesce(evt.ativo, false) AS ativo, coalesce(evt.tipo_corrida, '') AS tipo_corrida
                FROM tb_evento_corridas evt
                LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = evt.id_agrega_evento
                WHERE coalesce(evt.data_final, evt.data_inicial) >= <cfqueryparam cfsqltype="cf_sql_date" value="#createDate(VARIABLES.agregaReviewFirstYear, 1, 1)#" />
                  AND coalesce(evt.data_final, evt.data_inicial) < <cfqueryparam cfsqltype="cf_sql_date" value="#createDate(VARIABLES.agregaReviewSecondYear+1, 1, 1)#" />
                ORDER BY evt.id_evento
            </cfquery>
            <cfset VARIABLES.agregaReviewMatch = agregaReviewMatchEditions(qAgregaReviewSourceEvents, VARIABLES.agregaReviewFirstYear, VARIABLES.agregaReviewSecondYear) />
            <cfset VARIABLES.agregaReviewGroups = VARIABLES.agregaReviewMatch.groups />
            <cfset VARIABLES.agregaReviewPairs = VARIABLES.agregaReviewMatch.pairs />
            <cfset VARIABLES.agregaReviewCriteria = "Edições #VARIABLES.agregaReviewFirstYear#–#VARIABLES.agregaReviewSecondYear#: nome normalizado idêntico, mesma cidade/UF, país e tipo de corrida; uma candidata por ano; diferença sazonal de até 90 dias; numeração consecutiva quando informada nas duas edições. Revisão humana obrigatória." />

            <cftransaction>
                <cfquery name="qAgregaReviewGenerationLock">
                    SELECT pg_try_advisory_xact_lock(hashtext('business.agrega-review.edicoes-v1')) AS acquired
                </cfquery>
                <cfif NOT qAgregaReviewGenerationLock.acquired>
                    <cfthrow type="AgregaReview.Validation" message="Já existe uma geração em andamento. Aguarde a conclusão." />
                </cfif>
                <cfloop collection="#VARIABLES.agregaReviewGroups#" item="VARIABLES.agregaReviewGroupId">
                    <cfset VARIABLES.agregaReviewEvents = VARIABLES.agregaReviewGroups[VARIABLES.agregaReviewGroupId] />
                    <cfif arrayLen(VARIABLES.agregaReviewEvents) LT 2>
                        <cfcontinue />
                    </cfif>

                    <cfset VARIABLES.agregaReviewFirstEvent = VARIABLES.agregaReviewEvents[1] />
                    <cfset VARIABLES.agregaReviewNormalizedName = VARIABLES.agregaReviewFirstEvent.normalizedName />
                    <cfset VARIABLES.agregaReviewGroupKeyValue = VARIABLES.agregaReviewGroupId />
                    <!--- Preserve review history. A migrated circuit application does not resolve edition matching. --->
                    <cfquery name="qAgregaReviewExistingPair">
                        SELECT 1
                        FROM tb_evento_agrega_review_candidates a
                        INNER JOIN tb_evento_agrega_review_candidates b
                          ON b.id_evento_agrega_review_group = a.id_evento_agrega_review_group
                        WHERE a.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewEvents[1].idEvento#" />
                          AND b.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewEvents[2].idEvento#" />
                          AND NOT EXISTS (
                            SELECT 1 FROM tb_evento_agrega_review_groups history
                            JOIN tb_agregadores circuit ON circuit.id_agrega_evento_legado = history.suggested_id_agrega_evento
                            WHERE history.id_evento_agrega_review_group = a.id_evento_agrega_review_group
                              AND history.status = 'applied'
                          )
                        UNION ALL
                        SELECT 1 FROM tb_evento_agrega_review_candidates pending
                        INNER JOIN tb_evento_agrega_review_groups grp
                          ON grp.id_evento_agrega_review_group = pending.id_evento_agrega_review_group
                        WHERE pending.status = 'active' AND grp.status = 'review'
                          AND pending.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewEvents[1].idEvento#,#VARIABLES.agregaReviewEvents[2].idEvento#" list="true" />)
                        LIMIT 1
                    </cfquery>
                    <cfif qAgregaReviewExistingPair.recordCount>
                        <cfset VARIABLES.agregaReviewAlreadyReviewed++ />
                        <cfcontinue />
                    </cfif>
                    <cfset VARIABLES.agregaReviewSuggestedId = 0 />
                    <cfset VARIABLES.agregaReviewMaxScore = 0 />
                    <cfset VARIABLES.agregaReviewEventIds = "" />
                    <cfset VARIABLES.agregaReviewExistingAggregatorIds = "" />
                    <cfset VARIABLES.agregaReviewHasMissingAggregator = false />

                    <cfloop array="#VARIABLES.agregaReviewEvents#" index="VARIABLES.agregaReviewEvent">
                        <cfset VARIABLES.agregaReviewEventIds = listAppend(VARIABLES.agregaReviewEventIds, VARIABLES.agregaReviewEvent.idEvento) />
                        <cfif val(VARIABLES.agregaReviewEvent.idAgregaEvento) GT 0>
                            <cfset VARIABLES.agregaReviewSuggestedId = val(VARIABLES.agregaReviewEvent.idAgregaEvento) />
                            <cfif NOT listFind(VARIABLES.agregaReviewExistingAggregatorIds, VARIABLES.agregaReviewSuggestedId)>
                                <cfset VARIABLES.agregaReviewExistingAggregatorIds = listAppend(VARIABLES.agregaReviewExistingAggregatorIds, VARIABLES.agregaReviewSuggestedId) />
                            </cfif>
                        <cfelse>
                            <cfset VARIABLES.agregaReviewHasMissingAggregator = true />
                        </cfif>
                    </cfloop>

                    <cfif NOT VARIABLES.agregaReviewHasMissingAggregator AND listLen(VARIABLES.agregaReviewExistingAggregatorIds) EQ 1>
                        <cfquery>
                            UPDATE tb_evento_agrega_review_groups
                            SET status = 'ignored',
                                review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="Grupo ignorado automaticamente porque todos os eventos ja usam o mesmo agregador." />,
                                data_atualizacao = now()
                            WHERE group_key = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewGroupKeyValue#" />
                              AND status = 'review'
                        </cfquery>
                        <cfcontinue />
                    </cfif>

                    <cfset VARIABLES.agregaReviewMaxScore = 100 />
                    <cfif listLen(VARIABLES.agregaReviewExistingAggregatorIds) GT 1>
                        <cfset VARIABLES.agregaReviewSuggestedId = 0 />
                    </cfif>

                    <cfif VARIABLES.agregaReviewHasDisplayName>
                        <cfquery name="qAgregaReviewUpsertGroup">
                            INSERT INTO tb_evento_agrega_review_groups
                                (group_key, normalized_name, display_name, cidade, estado, candidate_count, max_score, suggested_id_agrega_evento, status, created_by, review_note, data_atualizacao)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewGroupKeyValue#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewNormalizedName#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#agregaReviewDisplayName(VARIABLES.agregaReviewFirstEvent.nomeEvento)#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewFirstEvent.cidade#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewFirstEvent.estado#" />,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayLen(VARIABLES.agregaReviewEvents)#" />,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewMaxScore#" />,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSuggestedId#" null="#VARIABLES.agregaReviewSuggestedId LTE 0#" />,
                                'review',
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agregaReviewCriteria#" />,
                                now()
                            )
                            ON CONFLICT (group_key)
                            DO UPDATE SET
                                candidate_count = excluded.candidate_count,
                                max_score = excluded.max_score,
                                display_name = excluded.display_name,
                                suggested_id_agrega_evento = excluded.suggested_id_agrega_evento,
                                status = CASE
                                    WHEN tb_evento_agrega_review_groups.status IN ('applied', 'ignored') THEN tb_evento_agrega_review_groups.status
                                    ELSE 'review'
                                END,
                                data_atualizacao = now()
                            RETURNING id_evento_agrega_review_group
                        </cfquery>
                    <cfelse>
                        <cfquery name="qAgregaReviewUpsertGroup">
                            INSERT INTO tb_evento_agrega_review_groups
                                (group_key, normalized_name, cidade, estado, candidate_count, max_score, suggested_id_agrega_evento, status, created_by, review_note, data_atualizacao)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewGroupKeyValue#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewNormalizedName#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewFirstEvent.cidade#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewFirstEvent.estado#" />,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayLen(VARIABLES.agregaReviewEvents)#" />,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewMaxScore#" />,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSuggestedId#" null="#VARIABLES.agregaReviewSuggestedId LTE 0#" />,
                                'review',
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                                <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agregaReviewCriteria#" />,
                                now()
                            )
                            ON CONFLICT (group_key)
                            DO UPDATE SET
                                candidate_count = excluded.candidate_count,
                                max_score = excluded.max_score,
                                suggested_id_agrega_evento = excluded.suggested_id_agrega_evento,
                                status = CASE
                                    WHEN tb_evento_agrega_review_groups.status IN ('applied', 'ignored') THEN tb_evento_agrega_review_groups.status
                                    ELSE 'review'
                                END,
                                data_atualizacao = now()
                            RETURNING id_evento_agrega_review_group
                        </cfquery>
                    </cfif>

                    <cfquery>
                        DELETE FROM tb_evento_agrega_review_candidates
                        WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgregaReviewUpsertGroup.id_evento_agrega_review_group#" />
                          AND status = 'active'
                          AND id_evento NOT IN (
                              <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewEventIds#" list="true" />
                          )
                    </cfquery>

                    <cfset VARIABLES.agregaReviewGeneratedGroups = VARIABLES.agregaReviewGeneratedGroups + 1 />

                    <cfloop array="#VARIABLES.agregaReviewEvents#" index="VARIABLES.agregaReviewEvent">
                        <cfset VARIABLES.agregaReviewCandidateScore = 100 />
                        <cfset VARIABLES.agregaReviewCandidateNameScore = 100 />

                        <cfquery>
                            INSERT INTO tb_evento_agrega_review_candidates
                                (id_evento_agrega_review_group, id_evento, id_agrega_evento_atual, nome_evento,
                                 normalized_name, cidade, estado, tag, data_inicial, score, name_score, city_score, status, data_atualizacao)
                            VALUES (
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgregaReviewUpsertGroup.id_evento_agrega_review_group#" />,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewEvent.idEvento#" />,
                                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewEvent.idAgregaEvento#" null="#val(VARIABLES.agregaReviewEvent.idAgregaEvento) LTE 0#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewEvent.nomeEvento#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewEvent.normalizedName#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewEvent.cidade#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewEvent.estado#" />,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewEvent.tag#" null="#!len(trim(VARIABLES.agregaReviewEvent.tag & ''))#" />,
                                <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.agregaReviewEvent.dataInicial#" null="#!isDate(VARIABLES.agregaReviewEvent.dataInicial)#" />,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewCandidateScore#" />,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewCandidateNameScore#" />,
                                <cfqueryparam cfsqltype="cf_sql_decimal" value="100" />,
                                'active',
                                now()
                            )
                            ON CONFLICT (id_evento_agrega_review_group, id_evento)
                            DO UPDATE SET
                                id_agrega_evento_atual = excluded.id_agrega_evento_atual,
                                nome_evento = excluded.nome_evento,
                                normalized_name = excluded.normalized_name,
                                cidade = excluded.cidade,
                                estado = excluded.estado,
                                tag = excluded.tag,
                                data_inicial = excluded.data_inicial,
                                score = excluded.score,
                                name_score = excluded.name_score,
                                city_score = excluded.city_score,
                                status = CASE
                                    WHEN tb_evento_agrega_review_candidates.status IN ('applied', 'ignored') THEN tb_evento_agrega_review_candidates.status
                                    ELSE 'active'
                                END,
                                data_atualizacao = now()
                        </cfquery>
                        <cfset VARIABLES.agregaReviewGeneratedCandidates = VARIABLES.agregaReviewGeneratedCandidates + 1 />
                    </cfloop>
                </cfloop>
            </cftransaction>

            <cfset SESSION.agregaReviewGenerationNotice = "#VARIABLES.agregaReviewGeneratedGroups# novos pares enviados para revisão após analisar #VARIABLES.agregaReviewMatch.scanned# eventos de #VARIABLES.agregaReviewFirstYear# e #VARIABLES.agregaReviewSecondYear#. #VARIABLES.agregaReviewAlreadyReviewed# pares já estavam no histórico ou envolvem eventos em outra revisão pendente; #VARIABLES.agregaReviewMatch.alreadyLinked# já tinham o mesmo agregador. #VARIABLES.agregaReviewMatch.ambiguous# nomes com múltiplas edições no mesmo ano e #VARIABLES.agregaReviewMatch.incompatible# pares com datas, numeração ou circuito incompatíveis ficaram fora da geração. Nenhum vínculo foi aplicado." />
            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=gerado&ordenar=atualizacao" />
        <cfelseif VARIABLES.agregaReviewAction EQ "criar_grupo_manual">
            <cfset VARIABLES.agregaReviewManualSelectedEvents = "" />
            <cfif isDefined("FORM.eventos")>
                <cfloop list="#FORM.eventos#" index="VARIABLES.agregaReviewManualEventIdRaw">
                    <cfset VARIABLES.agregaReviewManualEventId = val(VARIABLES.agregaReviewManualEventIdRaw) />
                    <cfif VARIABLES.agregaReviewManualEventId GT 0
                        AND NOT listFind(VARIABLES.agregaReviewManualSelectedEvents, VARIABLES.agregaReviewManualEventId)>
                        <cfset VARIABLES.agregaReviewManualSelectedEvents = listAppend(VARIABLES.agregaReviewManualSelectedEvents, VARIABLES.agregaReviewManualEventId) />
                    </cfif>
                </cfloop>
            </cfif>

            <cfif listLen(VARIABLES.agregaReviewManualSelectedEvents) LT 2>
                <cfthrow type="AgregaReview.Validation" message="Selecione ao menos dois eventos para criar o grupo de revisao." />
            </cfif>

            <cfquery name="qAgregaReviewManualSelected">
                SELECT evt.id_evento,
                       evt.nome_evento,
                       coalesce(evt.cidade, '') AS cidade,
                       coalesce(evt.estado, '') AS estado,
                       coalesce(evt.tag, '') AS tag,
                       evt.data_inicial,
                       evt.id_agrega_evento
                FROM tb_evento_corridas evt
                WHERE evt.ativo = true
                  AND evt.id_evento IN (
                      <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewManualSelectedEvents#" list="true" />
                  )
                  AND NOT EXISTS (
                      SELECT 1
                      FROM tb_evento_agrega_review_candidates pending_cand
                      INNER JOIN tb_evento_agrega_review_groups pending_grp
                          ON pending_grp.id_evento_agrega_review_group = pending_cand.id_evento_agrega_review_group
                      WHERE pending_cand.id_evento = evt.id_evento
                        AND pending_cand.status = 'active'
                        AND pending_grp.status = 'review'
                  )
                ORDER BY evt.data_inicial ASC NULLS LAST, evt.id_evento
            </cfquery>

            <cfif qAgregaReviewManualSelected.recordcount NEQ listLen(VARIABLES.agregaReviewManualSelectedEvents)>
                <cfthrow type="AgregaReview.Validation" message="Um ou mais eventos selecionados ja participam de outra revisao ou nao estao mais ativos. Atualize a busca e tente novamente." />
            </cfif>

            <cfset VARIABLES.agregaReviewManualEventsData = [] />
            <cfset VARIABLES.agregaReviewManualExistingAggregatorIds = "" />
            <cfset VARIABLES.agregaReviewManualHasMissingAggregator = false />

            <cfloop query="qAgregaReviewManualSelected">
                <cfset VARIABLES.agregaReviewManualEvent = {
                    idEvento = qAgregaReviewManualSelected.id_evento,
                    nomeEvento = qAgregaReviewManualSelected.nome_evento,
                    cidade = qAgregaReviewManualSelected.cidade,
                    estado = qAgregaReviewManualSelected.estado,
                    tag = qAgregaReviewManualSelected.tag,
                    dataInicial = qAgregaReviewManualSelected.data_inicial,
                    idAgregaEvento = val(qAgregaReviewManualSelected.id_agrega_evento),
                    normalizedName = agregaReviewNormalizeText(qAgregaReviewManualSelected.nome_evento),
                    score = 0,
                    nameScore = 0,
                    cityScore = 0
                } />
                <cfset arrayAppend(VARIABLES.agregaReviewManualEventsData, VARIABLES.agregaReviewManualEvent) />

                <cfif VARIABLES.agregaReviewManualEvent.idAgregaEvento GT 0>
                    <cfif NOT listFind(VARIABLES.agregaReviewManualExistingAggregatorIds, VARIABLES.agregaReviewManualEvent.idAgregaEvento)>
                        <cfset VARIABLES.agregaReviewManualExistingAggregatorIds = listAppend(VARIABLES.agregaReviewManualExistingAggregatorIds, VARIABLES.agregaReviewManualEvent.idAgregaEvento) />
                    </cfif>
                <cfelse>
                    <cfset VARIABLES.agregaReviewManualHasMissingAggregator = true />
                </cfif>
            </cfloop>

            <cfif NOT VARIABLES.agregaReviewManualHasMissingAggregator
                AND listLen(VARIABLES.agregaReviewManualExistingAggregatorIds) EQ 1>
                <cfthrow type="AgregaReview.Validation" message="Todos os eventos selecionados ja usam o mesmo agregador; nao ha uma revisao pendente para criar." />
            </cfif>

            <cfset VARIABLES.agregaReviewManualMaxScore = 0 />
            <cfloop from="1" to="#arrayLen(VARIABLES.agregaReviewManualEventsData)#" index="VARIABLES.agregaReviewManualLeftIndex">
                <cfloop from="1" to="#arrayLen(VARIABLES.agregaReviewManualEventsData)#" index="VARIABLES.agregaReviewManualRightIndex">
                    <cfif VARIABLES.agregaReviewManualLeftIndex EQ VARIABLES.agregaReviewManualRightIndex>
                        <cfcontinue />
                    </cfif>

                    <cfset VARIABLES.agregaReviewManualLeftEvent = VARIABLES.agregaReviewManualEventsData[VARIABLES.agregaReviewManualLeftIndex] />
                    <cfset VARIABLES.agregaReviewManualRightEvent = VARIABLES.agregaReviewManualEventsData[VARIABLES.agregaReviewManualRightIndex] />
                    <cfset VARIABLES.agregaReviewManualPairNameScore = agregaReviewTokenScore(VARIABLES.agregaReviewManualLeftEvent.nomeEvento, VARIABLES.agregaReviewManualRightEvent.nomeEvento) />
                    <cfset VARIABLES.agregaReviewManualPairCityScore = 0 />
                    <cfif len(agregaReviewPlainText(VARIABLES.agregaReviewManualLeftEvent.cidade))
                        AND agregaReviewPlainText(VARIABLES.agregaReviewManualLeftEvent.cidade) EQ agregaReviewPlainText(VARIABLES.agregaReviewManualRightEvent.cidade)
                        AND uCase(trim(VARIABLES.agregaReviewManualLeftEvent.estado)) EQ uCase(trim(VARIABLES.agregaReviewManualRightEvent.estado))>
                        <cfset VARIABLES.agregaReviewManualPairCityScore = 100 />
                    </cfif>
                    <cfset VARIABLES.agregaReviewManualPairScore = round(((VARIABLES.agregaReviewManualPairNameScore * 0.80) + (VARIABLES.agregaReviewManualPairCityScore * 0.20)) * 100) / 100 />

                    <cfif VARIABLES.agregaReviewManualPairScore GT VARIABLES.agregaReviewManualEventsData[VARIABLES.agregaReviewManualLeftIndex].score>
                        <cfset VARIABLES.agregaReviewManualEventsData[VARIABLES.agregaReviewManualLeftIndex].score = VARIABLES.agregaReviewManualPairScore />
                        <cfset VARIABLES.agregaReviewManualEventsData[VARIABLES.agregaReviewManualLeftIndex].nameScore = VARIABLES.agregaReviewManualPairNameScore />
                        <cfset VARIABLES.agregaReviewManualEventsData[VARIABLES.agregaReviewManualLeftIndex].cityScore = VARIABLES.agregaReviewManualPairCityScore />
                    </cfif>
                    <cfif VARIABLES.agregaReviewManualPairScore GT VARIABLES.agregaReviewManualMaxScore>
                        <cfset VARIABLES.agregaReviewManualMaxScore = VARIABLES.agregaReviewManualPairScore />
                    </cfif>
                </cfloop>
            </cfloop>

            <cfset VARIABLES.agregaReviewManualFirstEvent = VARIABLES.agregaReviewManualEventsData[1] />
            <cfset VARIABLES.agregaReviewManualSuggestedId = 0 />
            <cfif listLen(VARIABLES.agregaReviewManualExistingAggregatorIds) EQ 1>
                <cfset VARIABLES.agregaReviewManualSuggestedId = val(listFirst(VARIABLES.agregaReviewManualExistingAggregatorIds)) />
            </cfif>
            <cfset VARIABLES.agregaReviewManualGroupKey = lCase(hash("manual|" & qPerfil.id & "|" & createUUID() & "|" & VARIABLES.agregaReviewManualSelectedEvents, "SHA-256")) />

            <cftransaction>
                <cfif VARIABLES.agregaReviewHasDisplayName>
                    <cfquery name="qAgregaReviewManualInsertGroup">
                        INSERT INTO tb_evento_agrega_review_groups
                            (group_key, normalized_name, display_name, cidade, estado, candidate_count, max_score,
                             suggested_id_agrega_evento, status, created_by, data_atualizacao)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualGroupKey#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualFirstEvent.normalizedName#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#agregaReviewDisplayName(VARIABLES.agregaReviewManualFirstEvent.nomeEvento)#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualFirstEvent.cidade#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualFirstEvent.estado#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayLen(VARIABLES.agregaReviewManualEventsData)#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewManualMaxScore#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewManualSuggestedId#" null="#VARIABLES.agregaReviewManualSuggestedId LTE 0#" />,
                            'review',
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            now()
                        )
                        RETURNING id_evento_agrega_review_group
                    </cfquery>
                <cfelse>
                    <cfquery name="qAgregaReviewManualInsertGroup">
                        INSERT INTO tb_evento_agrega_review_groups
                            (group_key, normalized_name, cidade, estado, candidate_count, max_score,
                             suggested_id_agrega_evento, status, created_by, data_atualizacao)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualGroupKey#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualFirstEvent.normalizedName#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualFirstEvent.cidade#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualFirstEvent.estado#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#arrayLen(VARIABLES.agregaReviewManualEventsData)#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewManualMaxScore#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewManualSuggestedId#" null="#VARIABLES.agregaReviewManualSuggestedId LTE 0#" />,
                            'review',
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            now()
                        )
                        RETURNING id_evento_agrega_review_group
                    </cfquery>
                </cfif>

                <cfloop array="#VARIABLES.agregaReviewManualEventsData#" index="VARIABLES.agregaReviewManualEvent">
                    <cfquery>
                        INSERT INTO tb_evento_agrega_review_candidates
                            (id_evento_agrega_review_group, id_evento, id_agrega_evento_atual, nome_evento,
                             normalized_name, cidade, estado, tag, data_inicial, score, name_score, city_score,
                             status, data_atualizacao)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#qAgregaReviewManualInsertGroup.id_evento_agrega_review_group#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewManualEvent.idEvento#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewManualEvent.idAgregaEvento#" null="#VARIABLES.agregaReviewManualEvent.idAgregaEvento LTE 0#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualEvent.nomeEvento#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualEvent.normalizedName#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualEvent.cidade#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualEvent.estado#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualEvent.tag#" null="#!len(trim(VARIABLES.agregaReviewManualEvent.tag))#" />,
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.agregaReviewManualEvent.dataInicial#" null="#!isDate(VARIABLES.agregaReviewManualEvent.dataInicial)#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewManualEvent.score#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewManualEvent.nameScore#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewManualEvent.cityScore#" />,
                            'active',
                            now()
                        )
                    </cfquery>
                </cfloop>
            </cftransaction>

            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=grupo_manual&grupo=#qAgregaReviewManualInsertGroup.id_evento_agrega_review_group#" />
        <cfelseif VARIABLES.agregaReviewAction EQ "aceitar_sugestao">
            <cfif CGI.REQUEST_METHOD NEQ "POST" OR NOT structKeyExists(FORM, "quick_token")
                OR NOT csrfVerifyToken(FORM.quick_token, "agregaReviewQuickAccept")>
                <cfthrow type="AgregaReview.Validation" message="Atualize a página e tente aceitar a sugestão novamente." />
            </cfif>
            <cfparam name="FORM.id_grupo" default="0" />
            <cfparam name="FORM.nome_evento_agregado" default="" />
            <cfparam name="FORM.eventos_esperados" default="" />
            <cfparam name="FORM.agregador_esperado" default="0" />
            <cfinclude template="quick_accept.cfm" />
            <cfset VARIABLES.agregaReviewQuickResult = agregaReviewAcceptSuggestion(val(FORM.id_grupo), FORM.nome_evento_agregado, val(qPerfil.id), FORM.eventos_esperados, val(FORM.agregador_esperado)) />
            <cfset VARIABLES.agregaReviewQuickSuccess = VARIABLES.agregaReviewQuickResult.alreadyApplied ? "sugestao_ja_aplicada" : (VARIABLES.agregaReviewQuickResult.reusedExisting ? "sugestao_vinculada" : "sugestao_aceita") />
            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=#VARIABLES.agregaReviewQuickSuccess#&pagina=#VARIABLES.agregaReviewPage#&busca=#urlEncodedFormat(VARIABLES.agregaReviewSearch)#&status=#urlEncodedFormat(VARIABLES.agregaReviewStatus)#&ordenar=#urlEncodedFormat(VARIABLES.agregaReviewOrder)#&direcao=#urlEncodedFormat(VARIABLES.agregaReviewDirection)###agrega-review-list" />
        <cfelseif VARIABLES.agregaReviewAction EQ "criar_agregador">
            <cfset VARIABLES.agregaReviewGroupId = 0 />
            <cfif isDefined("FORM.id_grupo")>
                <cfset VARIABLES.agregaReviewGroupId = val(FORM.id_grupo) />
            </cfif>
            <cfset VARIABLES.agregaReviewAggregatorName = "" />
            <cfif isDefined("FORM.nome_evento_agregado")>
                <cfset VARIABLES.agregaReviewAggregatorName = trim(FORM.nome_evento_agregado) />
            </cfif>
            <cfset VARIABLES.agregaReviewAggregatorType = "" />
            <cfif isDefined("FORM.tipo_agregacao")>
                <cfset VARIABLES.agregaReviewAggregatorType = trim(FORM.tipo_agregacao) />
            </cfif>
            <cfset VARIABLES.agregaReviewAggregatorTag = "" />
            <cfif isDefined("FORM.tag")>
                <cfset VARIABLES.agregaReviewAggregatorTag = trim(FORM.tag) />
            </cfif>
            <cfset VARIABLES.agregaReviewAggregatorThemeId = 1 />
            <cfif isDefined("FORM.id_tema") AND val(FORM.id_tema) GT 0>
                <cfset VARIABLES.agregaReviewAggregatorThemeId = val(FORM.id_tema) />
            </cfif>
            <cfset VARIABLES.agregaReviewAggregatorDivision = "distancia" />
            <cfif isDefined("FORM.divisao") AND len(trim(FORM.divisao))>
                <cfset VARIABLES.agregaReviewAggregatorDivision = trim(FORM.divisao) />
            </cfif>
            <cfset VARIABLES.agregaReviewAggregatorOrder = 300 />
            <cfif isDefined("FORM.ordem") AND isNumeric(FORM.ordem)>
                <cfset VARIABLES.agregaReviewAggregatorOrder = val(FORM.ordem) />
            </cfif>

            <cfif VARIABLES.agregaReviewGroupId LTE 0>
                <cfthrow type="AgregaReview.Validation" message="Grupo de revisao invalido para criar agregador." />
            </cfif>
            <cfif NOT len(VARIABLES.agregaReviewAggregatorName)>
                <cfthrow type="AgregaReview.Validation" message="Informe o nome do agregador." />
            </cfif>
            <cfif NOT len(VARIABLES.agregaReviewAggregatorType)>
                <cfthrow type="AgregaReview.Validation" message="Informe o tipo de agregacao." />
            </cfif>
            <cfif compareNoCase(VARIABLES.agregaReviewAggregatorType, "circuito") EQ 0>
                <cfthrow type="AgregaReview.Validation" message="Circuitos devem ser vinculados em Agregadores e circuitos, nas configurações do evento. Aqui são vinculadas edições da mesma prova." />
            </cfif>
            <cfset VARIABLES.agregaReviewAggregatorSuccess = "agregador_criado" />

            <cftransaction>
                <cfquery name="qAgregaReviewGroupForAggregator">
                    SELECT id_evento_agrega_review_group
                    FROM tb_evento_agrega_review_groups
                    WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                      AND status = 'review'
                    FOR UPDATE
                </cfquery>

                <cfif NOT qAgregaReviewGroupForAggregator.recordcount>
                    <cfthrow type="AgregaReview.Validation" message="Grupo de revisao nao encontrado ou ja finalizado." />
                </cfif>

                <cfquery name="qAgregaReviewThemeForAggregator">
                    SELECT id_tema
                    FROM tb_temas
                    WHERE id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewAggregatorThemeId#" />
                </cfquery>

                <cfif NOT qAgregaReviewThemeForAggregator.recordcount>
                    <cfthrow type="AgregaReview.Validation" message="Tema selecionado nao existe." />
                </cfif>

                <cfquery name="qAgregaReviewAggregatorNameLock">
                    SELECT pg_try_advisory_xact_lock(hashtext('business.agrega-review.name'), hashtext(lower(btrim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewAggregatorName#" />)))) AS acquired
                </cfquery>
                <cfif NOT qAgregaReviewAggregatorNameLock.acquired>
                    <cfthrow type="AgregaReview.Validation" message="Este nome está sendo processado em outra revisão. Tente novamente." />
                </cfif>
                <cfquery name="qAgregaReviewExistingAggregator">
                    SELECT id_agrega_evento
                    FROM tb_agrega_eventos
                    WHERE lower(trim(nome_evento_agregado)) = lower(trim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewAggregatorName#" />))
                    <cfif len(VARIABLES.agregaReviewAggregatorTag)>
                        OR lower(trim(tag)) = lower(trim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewAggregatorTag#" />))
                    </cfif>
                    ORDER BY
                        CASE
                            WHEN lower(trim(nome_evento_agregado)) = lower(trim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewAggregatorName#" />)) THEN 0
                            ELSE 1
                        END,
                        id_agrega_evento
                    LIMIT 1
                </cfquery>

                <cfif qAgregaReviewExistingAggregator.recordcount>
                    <cfquery name="qAgregaReviewExistingType">
                        SELECT tipo_agregacao FROM tb_agrega_eventos
                        WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgregaReviewExistingAggregator.id_agrega_evento#" />
                    </cfquery>
                    <cfif compareNoCase(trim(qAgregaReviewExistingType.tipo_agregacao), "circuito") EQ 0>
                        <cfthrow type="AgregaReview.Validation" message="Esse nome identifica um circuito. Informe o nome da prova ou etapa para agrupar suas edições." />
                    </cfif>
                    <cfset VARIABLES.agregaReviewSelectedAggregatorId = qAgregaReviewExistingAggregator.id_agrega_evento />
                    <cfset VARIABLES.agregaReviewAggregatorSuccess = "agregador_existente" />
                <cfelse>
                    <cfquery name="qAgregaReviewInsertAggregator">
                        INSERT INTO tb_agrega_eventos
                            (nome_evento_agregado, tipo_agregacao, tag, id_tema, divisao, ordem)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewAggregatorName#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewAggregatorType#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewAggregatorTag#" null="#NOT len(VARIABLES.agregaReviewAggregatorTag)#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewAggregatorThemeId#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewAggregatorDivision#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewAggregatorOrder#" />
                        )
                        RETURNING id_agrega_evento
                    </cfquery>
                    <cfset VARIABLES.agregaReviewSelectedAggregatorId = qAgregaReviewInsertAggregator.id_agrega_evento />
                </cfif>

                <cfquery>
                    UPDATE tb_evento_agrega_review_groups
                    SET suggested_id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSelectedAggregatorId#" />,
                        data_atualizacao = now()
                    WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                </cfquery>
            </cftransaction>

            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=#VARIABLES.agregaReviewAggregatorSuccess#&grupo=#VARIABLES.agregaReviewGroupId#&evento_busca=#urlEncodedFormat(VARIABLES.agregaReviewAggregatorName)#" />
        <cfelseif VARIABLES.agregaReviewAction EQ "adicionar_candidatos_grupo">
            <cfset VARIABLES.agregaReviewGroupId = 0 />
            <cfif isDefined("FORM.id_grupo")>
                <cfset VARIABLES.agregaReviewGroupId = val(FORM.id_grupo) />
            </cfif>
            <cfset VARIABLES.agregaReviewAdditionalEventIds = "" />

            <cfif isDefined("FORM.eventos_adicionais")>
                <cfloop list="#FORM.eventos_adicionais#" index="VARIABLES.agregaReviewAdditionalEventIdRaw">
                    <cfset VARIABLES.agregaReviewAdditionalEventId = val(VARIABLES.agregaReviewAdditionalEventIdRaw) />
                    <cfif VARIABLES.agregaReviewAdditionalEventId GT 0
                        AND NOT listFind(VARIABLES.agregaReviewAdditionalEventIds, VARIABLES.agregaReviewAdditionalEventId)>
                        <cfset VARIABLES.agregaReviewAdditionalEventIds = listAppend(VARIABLES.agregaReviewAdditionalEventIds, VARIABLES.agregaReviewAdditionalEventId) />
                    </cfif>
                </cfloop>
            </cfif>

            <cfif VARIABLES.agregaReviewGroupId LTE 0 OR NOT len(VARIABLES.agregaReviewAdditionalEventIds)>
                <cfthrow type="AgregaReview.Validation" message="Selecione ao menos um evento para adicionar ao grupo." />
            </cfif>

            <cftransaction>
                <cfquery name="qAgregaReviewAdditionalGroupLock">
                    SELECT grp.id_evento_agrega_review_group,
                           grp.cidade,
                           grp.estado,
                           grp.suggested_id_agrega_evento,
                           coalesce(
                               nullif(trim(agr.nome_evento_agregado), ''),
                               <cfif VARIABLES.agregaReviewHasDisplayName>
                                   nullif(trim(grp.display_name), ''),
                               </cfif>
                               grp.normalized_name
                           ) AS reference_name
                    FROM tb_evento_agrega_review_groups grp
                    LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = grp.suggested_id_agrega_evento
                    WHERE grp.id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                      AND grp.status = 'review'
                    FOR UPDATE OF grp
                </cfquery>

                <cfif NOT qAgregaReviewAdditionalGroupLock.recordcount>
                    <cfthrow type="AgregaReview.Validation" message="Grupo de revisao nao encontrado ou ja finalizado." />
                </cfif>

                <cfquery name="qAgregaReviewAdditionalEvents">
                    SELECT evt.id_evento,
                           evt.nome_evento,
                           coalesce(evt.cidade, '') AS cidade,
                           coalesce(evt.estado, '') AS estado,
                           coalesce(evt.tag, '') AS tag,
                           evt.data_inicial,
                           evt.id_agrega_evento
                    FROM tb_evento_corridas evt
                    WHERE evt.ativo = true
                      AND evt.id_evento IN (
                          <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewAdditionalEventIds#" list="true" />
                      )
                      AND NOT EXISTS (
                          SELECT 1
                          FROM tb_evento_agrega_review_candidates own_cand
                          WHERE own_cand.id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                            AND own_cand.id_evento = evt.id_evento
                      )
                      AND NOT EXISTS (
                          SELECT 1
                          FROM tb_evento_agrega_review_candidates pending_cand
                          INNER JOIN tb_evento_agrega_review_groups pending_grp
                              ON pending_grp.id_evento_agrega_review_group = pending_cand.id_evento_agrega_review_group
                          WHERE pending_cand.id_evento = evt.id_evento
                            AND pending_cand.status = 'active'
                            AND pending_grp.status = 'review'
                            AND pending_grp.id_evento_agrega_review_group <> <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                      )
                    <cfif val(qAgregaReviewAdditionalGroupLock.suggested_id_agrega_evento) GT 0>
                      AND coalesce(evt.id_agrega_evento, 0) <> <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgregaReviewAdditionalGroupLock.suggested_id_agrega_evento#" />
                    </cfif>
                    ORDER BY evt.data_inicial ASC NULLS LAST, evt.id_evento
                </cfquery>

                <cfif qAgregaReviewAdditionalEvents.recordcount NEQ listLen(VARIABLES.agregaReviewAdditionalEventIds)>
                    <cfthrow type="AgregaReview.Validation" message="Um ou mais eventos ja pertencem ao grupo, estao em outra revisao, ja usam este agregador ou nao estao mais ativos. Atualize a busca." />
                </cfif>

                <cfset VARIABLES.agregaReviewAdditionalMaxScore = 0 />
                <cfloop query="qAgregaReviewAdditionalEvents">
                    <cfset VARIABLES.agregaReviewAdditionalNameScore = agregaReviewTokenScore(qAgregaReviewAdditionalGroupLock.reference_name, qAgregaReviewAdditionalEvents.nome_evento) />
                    <cfset VARIABLES.agregaReviewAdditionalCityScore = 0 />
                    <cfif len(agregaReviewPlainText(qAgregaReviewAdditionalGroupLock.cidade))
                        AND agregaReviewPlainText(qAgregaReviewAdditionalGroupLock.cidade) EQ agregaReviewPlainText(qAgregaReviewAdditionalEvents.cidade)
                        AND uCase(trim(qAgregaReviewAdditionalGroupLock.estado)) EQ uCase(trim(qAgregaReviewAdditionalEvents.estado))>
                        <cfset VARIABLES.agregaReviewAdditionalCityScore = 100 />
                    </cfif>
                    <cfset VARIABLES.agregaReviewAdditionalScore = round(((VARIABLES.agregaReviewAdditionalNameScore * 0.80) + (VARIABLES.agregaReviewAdditionalCityScore * 0.20)) * 100) / 100 />
                    <cfif VARIABLES.agregaReviewAdditionalScore GT VARIABLES.agregaReviewAdditionalMaxScore>
                        <cfset VARIABLES.agregaReviewAdditionalMaxScore = VARIABLES.agregaReviewAdditionalScore />
                    </cfif>

                    <cfquery>
                        INSERT INTO tb_evento_agrega_review_candidates
                            (id_evento_agrega_review_group, id_evento, id_agrega_evento_atual, nome_evento,
                             normalized_name, cidade, estado, tag, data_inicial, score, name_score, city_score,
                             status, data_atualizacao)
                        VALUES (
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgregaReviewAdditionalEvents.id_evento#" />,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#qAgregaReviewAdditionalEvents.id_agrega_evento#" null="#val(qAgregaReviewAdditionalEvents.id_agrega_evento) LTE 0#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#qAgregaReviewAdditionalEvents.nome_evento#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#agregaReviewNormalizeText(qAgregaReviewAdditionalEvents.nome_evento)#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#qAgregaReviewAdditionalEvents.cidade#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#qAgregaReviewAdditionalEvents.estado#" />,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#qAgregaReviewAdditionalEvents.tag#" null="#!len(trim(qAgregaReviewAdditionalEvents.tag))#" />,
                            <cfqueryparam cfsqltype="cf_sql_date" value="#qAgregaReviewAdditionalEvents.data_inicial#" null="#!isDate(qAgregaReviewAdditionalEvents.data_inicial)#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewAdditionalScore#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewAdditionalNameScore#" />,
                            <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewAdditionalCityScore#" />,
                            'active',
                            now()
                        )
                    </cfquery>
                </cfloop>

                <cfquery>
                    UPDATE tb_evento_agrega_review_groups grp
                    SET candidate_count = (
                            SELECT count(*)
                            FROM tb_evento_agrega_review_candidates cand
                            WHERE cand.id_evento_agrega_review_group = grp.id_evento_agrega_review_group
                        ),
                        max_score = greatest(coalesce(grp.max_score, 0), <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.agregaReviewAdditionalMaxScore#" />),
                        data_atualizacao = now()
                    WHERE grp.id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                </cfquery>
            </cftransaction>

            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=candidatos_adicionados&grupo=#VARIABLES.agregaReviewGroupId#" />
        <cfelseif VARIABLES.agregaReviewAction EQ "aplicar_agregador">
            <cfset VARIABLES.agregaReviewGroupId = 0 />
            <cfif isDefined("FORM.id_grupo")>
                <cfset VARIABLES.agregaReviewGroupId = val(FORM.id_grupo) />
            </cfif>
            <cfset VARIABLES.agregaReviewSelectedAgregaId = 0 />
            <cfif isDefined("FORM.id_agrega_evento")>
                <cfset VARIABLES.agregaReviewSelectedAgregaId = val(FORM.id_agrega_evento) />
            </cfif>
            <cfset VARIABLES.agregaReviewSelectedAgregaName = "" />
            <cfif isDefined("FORM.nome_agregador_aplicacao")>
                <cfset VARIABLES.agregaReviewSelectedAgregaName = trim(FORM.nome_agregador_aplicacao) />
            </cfif>
            <cfset VARIABLES.agregaReviewSelectedAgregaType = "" />
            <cfif isDefined("FORM.tipo_agregador_aplicacao")>
                <cfset VARIABLES.agregaReviewSelectedAgregaType = trim(FORM.tipo_agregador_aplicacao) />
            </cfif>
            <cfset VARIABLES.agregaReviewSelectedEvents = "" />
            <cfif isDefined("FORM.eventos")>
                <cfset VARIABLES.agregaReviewSelectedEvents = trim(FORM.eventos) />
            </cfif>
            <cfset VARIABLES.agregaReviewNote = "" />
            <cfif isDefined("FORM.observacao")>
                <cfset VARIABLES.agregaReviewNote = trim(FORM.observacao) />
            </cfif>

            <cfif VARIABLES.agregaReviewGroupId LTE 0
                OR VARIABLES.agregaReviewSelectedAgregaId LTE 0
                OR !len(VARIABLES.agregaReviewSelectedAgregaName)
                OR !len(VARIABLES.agregaReviewSelectedAgregaType)
                OR !len(VARIABLES.agregaReviewSelectedEvents)>
                <cfthrow type="AgregaReview.Validation" message="Selecione o grupo, o agregador, informe o nome e o tipo finais e marque ao menos um evento." />
            </cfif>

            <cftransaction>
                <cfquery name="qAgregaReviewAggregatorLock">
                    SELECT id_agrega_evento, nome_evento_agregado, tipo_agregacao
                    FROM tb_agrega_eventos
                    WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSelectedAgregaId#" />
                    FOR UPDATE
                </cfquery>

                <cfif !qAgregaReviewAggregatorLock.recordcount>
                    <cfthrow type="AgregaReview.Validation" message="Agregador selecionado nao existe." />
                </cfif>

                <cfif compareNoCase(VARIABLES.agregaReviewSelectedAgregaType, "circuito") EQ 0
                    OR compareNoCase(trim(qAgregaReviewAggregatorLock.tipo_agregacao), "circuito") EQ 0>
                    <cfthrow type="AgregaReview.Validation" message="Circuitos devem ser vinculados em Agregadores e circuitos, nas configurações do evento. Selecione um grupo de edições." />
                </cfif>

                <cfquery name="qAgregaReviewGroupLock">
                    SELECT id_evento_agrega_review_group
                    FROM tb_evento_agrega_review_groups
                    WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                      AND status = 'review'
                    FOR UPDATE
                </cfquery>

                <cfif !qAgregaReviewGroupLock.recordcount>
                    <cfthrow type="AgregaReview.Validation" message="Grupo de revisao nao encontrado ou ja finalizado." />
                </cfif>

                <cfif trim(qAgregaReviewAggregatorLock.nome_evento_agregado & "") NEQ VARIABLES.agregaReviewSelectedAgregaName
                    OR trim(qAgregaReviewAggregatorLock.tipo_agregacao & "") NEQ VARIABLES.agregaReviewSelectedAgregaType>
                    <cfquery>
                        UPDATE tb_agrega_eventos
                        SET nome_evento_agregado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewSelectedAgregaName#" />,
                            tipo_agregacao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewSelectedAgregaType#" />
                        WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSelectedAgregaId#" />
                    </cfquery>
                </cfif>

                <cfquery>
                    UPDATE tb_evento_corridas
                    SET id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSelectedAgregaId#" />
                    WHERE id_evento IN (
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSelectedEvents#" list="true" />
                    )
                      AND id_evento IN (
                          SELECT id_evento
                          FROM tb_evento_agrega_review_candidates
                          WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                            AND status = 'active'
                      )
                </cfquery>

                <cfquery>
                    UPDATE tb_evento_agrega_review_candidates
                    SET status = CASE
                            WHEN id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSelectedEvents#" list="true" />) THEN 'applied'
                            ELSE status
                        END,
                        reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                        reviewed_at = now(),
                        review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agregaReviewNote#" null="#!len(VARIABLES.agregaReviewNote)#" />,
                        data_atualizacao = now()
                    WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                </cfquery>

                <cfquery>
                    UPDATE tb_evento_agrega_review_groups
                    SET status = 'applied',
                        suggested_id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSelectedAgregaId#" />,
                        reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                        reviewed_at = now(),
                        review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agregaReviewNote#" null="#!len(VARIABLES.agregaReviewNote)#" />,
                        data_atualizacao = now()
                    WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                </cfquery>
            </cftransaction>

            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=aplicado" />
        <cfelseif listFindNoCase("ignorar_grupo,ignorar_candidato", VARIABLES.agregaReviewAction)>
            <cfset VARIABLES.agregaReviewGroupId = 0 />
            <cfif isDefined("FORM.id_grupo")>
                <cfset VARIABLES.agregaReviewGroupId = val(FORM.id_grupo) />
            </cfif>
            <cfset VARIABLES.agregaReviewCandidateId = 0 />
            <cfif isDefined("FORM.id_candidato")>
                <cfset VARIABLES.agregaReviewCandidateId = val(FORM.id_candidato) />
            </cfif>
            <cfset VARIABLES.agregaReviewNote = "" />
            <cfif isDefined("FORM.observacao")>
                <cfset VARIABLES.agregaReviewNote = trim(FORM.observacao) />
            </cfif>

            <cfif VARIABLES.agregaReviewGroupId LTE 0>
                <cfthrow type="AgregaReview.Validation" message="Grupo de revisao invalido." />
            </cfif>

            <cftransaction>
                <cfif VARIABLES.agregaReviewAction EQ "ignorar_grupo">
                    <cfquery>
                        UPDATE tb_evento_agrega_review_groups
                        SET status = 'ignored',
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agregaReviewNote#" null="#!len(VARIABLES.agregaReviewNote)#" />,
                            data_atualizacao = now()
                        WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                    </cfquery>
                    <cfquery>
                        UPDATE tb_evento_agrega_review_candidates
                        SET status = 'ignored',
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agregaReviewNote#" null="#!len(VARIABLES.agregaReviewNote)#" />,
                            data_atualizacao = now()
                        WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                          AND status = 'active'
                    </cfquery>
                <cfelse>
                    <cfquery>
                        UPDATE tb_evento_agrega_review_candidates
                        SET status = 'ignored',
                            reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                            reviewed_at = now(),
                            review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.agregaReviewNote#" null="#!len(VARIABLES.agregaReviewNote)#" />,
                            data_atualizacao = now()
                        WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                          AND id_evento_agrega_review_candidate = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewCandidateId#" />
                    </cfquery>

                    <cfquery name="qAgregaReviewRemaining">
                        SELECT count(*) AS total
                        FROM tb_evento_agrega_review_candidates
                        WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                          AND status = 'active'
                    </cfquery>

                    <cfif val(qAgregaReviewRemaining.total) LT 2>
                        <cfquery>
                            UPDATE tb_evento_agrega_review_groups
                            SET status = 'ignored',
                                reviewed_by = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#" />,
                                reviewed_at = now(),
                                review_note = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="Candidatos ativos insuficientes para revisao." />,
                                data_atualizacao = now()
                            WHERE id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewGroupId#" />
                        </cfquery>
                    </cfif>
                </cfif>
            </cftransaction>

            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=ignorado" />
        <cfelse>
            <cfthrow type="AgregaReview.Validation" message="Acao invalida." />
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.agregaReviewError = cfcatch.message />
        </cfcatch>
    </cftry>
</cfif>

<cfif VARIABLES.agregaReviewSchemaReady>
    <cfset VARIABLES.agregaReviewQuickToken = csrfGenerateToken("agregaReviewQuickAccept", false) />
    <cfset VARIABLES.agregaReviewQuickGroups = {} />
    <cfset VARIABLES.agregaReviewQuickExistingGroups = {} />
    <cfquery name="qAgregaReviewStats" timeout="15">
        SELECT count(*) FILTER (WHERE grp.status = 'review' AND EXISTS (
                   SELECT 1 FROM tb_evento_agrega_review_candidates c
                   INNER JOIN tb_evento_corridas e ON e.id_evento = c.id_evento
                   WHERE c.id_evento_agrega_review_group = grp.id_evento_agrega_review_group AND c.status = 'active'
                   HAVING count(*) >= 2 AND (count(*) FILTER (WHERE e.id_agrega_evento IS NULL) > 0 OR count(DISTINCT e.id_agrega_evento) > 1)
               )) AS review,
               count(*) FILTER (WHERE grp.status = 'applied') AS applied,
               count(*) FILTER (WHERE grp.status = 'ignored') AS ignored
        FROM tb_evento_agrega_review_groups grp
    </cfquery>

    <cfif (len(VARIABLES.agregaReviewManualName) OR len(VARIABLES.agregaReviewManualCity))
        AND len(VARIABLES.agregaReviewManualName) LT 2>
        <cfset VARIABLES.agregaReviewManualSearchError = "Informe ao menos 2 caracteres do nome do evento." />
    <cfelseif len(VARIABLES.agregaReviewManualName) GTE 2>
        <cfquery name="qAgregaReviewManualEvents">
            SELECT evt.id_evento,
                   evt.nome_evento,
                   coalesce(evt.cidade, '') AS cidade,
                   coalesce(evt.estado, '') AS estado,
                   coalesce(evt.tag, '') AS tag,
                   evt.data_inicial,
                   evt.id_agrega_evento,
                   agr.nome_evento_agregado AS atual_nome_evento_agregado,
                   agr.tipo_agregacao AS atual_tipo_agregacao,
                   pending.id_evento_agrega_review_group AS pending_group_id,
                   pending.pending_group_name
            FROM tb_evento_corridas evt
            LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = evt.id_agrega_evento
            LEFT JOIN LATERAL (
                SELECT grp.id_evento_agrega_review_group,
                       <cfif VARIABLES.agregaReviewHasDisplayName>
                           coalesce(nullif(trim(grp.display_name), ''), grp.normalized_name) AS pending_group_name
                       <cfelse>
                           grp.normalized_name AS pending_group_name
                       </cfif>
                FROM tb_evento_agrega_review_candidates cand
                INNER JOIN tb_evento_agrega_review_groups grp
                    ON grp.id_evento_agrega_review_group = cand.id_evento_agrega_review_group
                WHERE cand.id_evento = evt.id_evento
                  AND cand.status = 'active'
                  AND grp.status = 'review'
                ORDER BY grp.data_atualizacao DESC, grp.id_evento_agrega_review_group DESC
                LIMIT 1
            ) pending ON true
            WHERE evt.ativo = true
              AND coalesce(evt.nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.agregaReviewManualName#%" />
            <cfif len(VARIABLES.agregaReviewManualCity)>
              AND coalesce(evt.cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.agregaReviewManualCity#%" />
            </cfif>
            ORDER BY
                CASE
                    WHEN coalesce(evt.nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewManualName#%" /> THEN 0
                    ELSE 1
                END,
                evt.cidade,
                evt.estado,
                evt.nome_evento,
                evt.data_inicial DESC NULLS LAST
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewManualSearchLimit#" />
        </cfquery>
    </cfif>

    <cfquery name="qAgregaReviewAggregatorTypes" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
        SELECT tipo_agregacao
        FROM (
            SELECT DISTINCT nullif(trim(tipo_agregacao), '') AS tipo_agregacao
            FROM tb_agrega_eventos
            WHERE nullif(trim(tipo_agregacao), '') IS NOT NULL
              AND lower(trim(tipo_agregacao)) <> 'circuito'

            UNION

            SELECT 'corrida' AS tipo_agregacao
        ) typ
        ORDER BY
            CASE WHEN lower(tipo_agregacao) = 'corrida' THEN 0 ELSE 1 END,
            tipo_agregacao
    </cfquery>

    <cfquery name="qAgregaReviewDivisions" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
        SELECT divisao
        FROM (
            SELECT DISTINCT nullif(trim(divisao), '') AS divisao
            FROM tb_agrega_eventos
            WHERE nullif(trim(divisao), '') IS NOT NULL

            UNION

            SELECT 'distancia' AS divisao
        ) div
        ORDER BY
            CASE WHEN lower(divisao) = 'distancia' THEN 0 ELSE 1 END,
            divisao
    </cfquery>

    <cfquery name="qAgregaReviewThemes" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
        SELECT id_tema, coalesce(nullif(trim(logo), ''), nullif(trim(tag), ''), id_tema::varchar) AS nome_tema
        FROM tb_temas
        ORDER BY id_tema
    </cfquery>

    <cfset VARIABLES.agregaReviewSuggestedAggregators = {} />
    <cfset VARIABLES.agregaReviewSearchAggregators = {} />
    <cfset VARIABLES.agregaReviewEventSearchInput = VARIABLES.agregaReviewEventSearchTerm />
    <cfset VARIABLES.agregaReviewEventSearchTargetId = 0 />
    <cfset VARIABLES.agregaReviewEventSearchTargetName = "" />

    <cfloop from="1" to="2" index="VARIABLES.agregaReviewPageAttempt">
    <cfquery name="qAgregaReviewGroups">
        SELECT grp.*, count(*) OVER () AS filtered_total,
               <cfif VARIABLES.agregaReviewHasDisplayName>
                   coalesce(nullif(trim(grp.display_name), ''), grp.normalized_name) AS group_display_name,
               <cfelse>
                   grp.normalized_name AS group_display_name,
               </cfif>
               NULL::varchar AS suggested_nome_evento_agregado,
               NULL::varchar AS suggested_tipo_agregacao
        FROM tb_evento_agrega_review_groups grp
        WHERE 1 = 1
        <cfif VARIABLES.agregaReviewFocusGroupId GT 0>
            AND grp.id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewFocusGroupId#" />
        <cfelse>
            <cfif VARIABLES.agregaReviewStatus NEQ "all">
                AND grp.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewStatus#" />
            </cfif>
            <cfif len(VARIABLES.agregaReviewSearch)>
                AND (grp.normalized_name ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#agregaReviewPlainText(VARIABLES.agregaReviewSearch)#%" />
                     OR grp.cidade ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.agregaReviewSearch#%" />
                     OR EXISTS (SELECT 1 FROM tb_evento_agrega_review_candidates sc
                         WHERE sc.id_evento_agrega_review_group = grp.id_evento_agrega_review_group
                           AND (sc.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.agregaReviewSearch#%" />
                                OR sc.id_evento::text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewSearch#" />)))
            </cfif>
            AND (grp.status <> 'review' OR EXISTS (
                SELECT 1 FROM tb_evento_agrega_review_candidates c
                INNER JOIN tb_evento_corridas e ON e.id_evento = c.id_evento
                WHERE c.id_evento_agrega_review_group = grp.id_evento_agrega_review_group AND c.status = 'active'
                HAVING count(*) >= 2 AND (count(*) FILTER (WHERE e.id_agrega_evento IS NULL) > 0 OR count(DISTINCT e.id_agrega_evento) > 1)
            ))
        </cfif>
        ORDER BY
            <cfif VARIABLES.agregaReviewOrder EQ "nome">grp.normalized_name
            <cfelseif VARIABLES.agregaReviewOrder EQ "atualizacao">grp.data_atualizacao
            <cfelse>grp.max_score</cfif>
            <cfif VARIABLES.agregaReviewDirection EQ "asc">ASC<cfelse>DESC</cfif>, grp.id_evento_agrega_review_group DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewPerPage#" />
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewFocusGroupId GT 0 ? 0 : VARIABLES.agregaReviewOffset#" />
    </cfquery>
    <cfif qAgregaReviewGroups.recordCount OR VARIABLES.agregaReviewOffset EQ 0 OR VARIABLES.agregaReviewFocusGroupId GT 0>
        <cfbreak />
    </cfif>
    <cfset VARIABLES.agregaReviewPage = 1 />
    <cfset VARIABLES.agregaReviewOffset = 0 />
    </cfloop>
    <cfset VARIABLES.agregaReviewTotal = qAgregaReviewGroups.recordCount ? val(qAgregaReviewGroups.filtered_total[1]) : 0 />
    <cfset VARIABLES.agregaReviewTotalPages = max(1, ceiling(VARIABLES.agregaReviewTotal / VARIABLES.agregaReviewPerPage)) />
    <cfset VARIABLES.agregaReviewActionableGroups = {} />
    <cfset VARIABLES.agregaReviewRenderableTotal = 0 />

    <cfif qAgregaReviewGroups.recordcount>
        <cfset VARIABLES.agregaReviewSuggestedAggregatorIds = "" />
        <cfloop query="qAgregaReviewGroups">
            <cfif val(qAgregaReviewGroups.suggested_id_agrega_evento) GT 0
                AND NOT listFind(VARIABLES.agregaReviewSuggestedAggregatorIds, val(qAgregaReviewGroups.suggested_id_agrega_evento))>
                <cfset VARIABLES.agregaReviewSuggestedAggregatorIds = listAppend(VARIABLES.agregaReviewSuggestedAggregatorIds, val(qAgregaReviewGroups.suggested_id_agrega_evento)) />
            </cfif>
        </cfloop>

        <cfif len(VARIABLES.agregaReviewSuggestedAggregatorIds)>
            <cfquery name="qAgregaReviewSuggestedAggregatorLookup">
                SELECT id_agrega_evento,
                       nome_evento_agregado,
                       tipo_agregacao,
                       coalesce(tag, '') AS tag
                FROM tb_agrega_eventos
                WHERE id_agrega_evento IN (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSuggestedAggregatorIds#" list="true" />
                )
            </cfquery>

            <cfloop query="qAgregaReviewSuggestedAggregatorLookup">
                <cfset VARIABLES.agregaReviewSuggestedAggregators[toString(qAgregaReviewSuggestedAggregatorLookup.id_agrega_evento)] = {
                    id = qAgregaReviewSuggestedAggregatorLookup.id_agrega_evento,
                    nome = qAgregaReviewSuggestedAggregatorLookup.nome_evento_agregado,
                    tipo = qAgregaReviewSuggestedAggregatorLookup.tipo_agregacao,
                    tag = qAgregaReviewSuggestedAggregatorLookup.tag
                } />
            </cfloop>
        </cfif>

        <cfif VARIABLES.agregaReviewFocusGroupId GT 0>
            <cfset VARIABLES.agregaReviewEventSearchTargetId = val(qAgregaReviewGroups.suggested_id_agrega_evento[1]) />
            <cfset VARIABLES.agregaReviewEventSearchTargetName = qAgregaReviewGroups.group_display_name[1] />

            <cfif VARIABLES.agregaReviewEventSearchTargetId GT 0
                AND structKeyExists(VARIABLES.agregaReviewSuggestedAggregators, toString(VARIABLES.agregaReviewEventSearchTargetId))>
                <cfset VARIABLES.agregaReviewEventSearchTargetName = VARIABLES.agregaReviewSuggestedAggregators[toString(VARIABLES.agregaReviewEventSearchTargetId)].nome />
            </cfif>

            <cfif NOT len(VARIABLES.agregaReviewEventSearchInput)>
                <cfset VARIABLES.agregaReviewEventSearchInput = VARIABLES.agregaReviewEventSearchTargetName />
            </cfif>

            <cfif VARIABLES.agregaReviewEventSearchRequested>
                <cfquery name="qAgregaReviewEventSearch">
                    SELECT evt.id_evento,
                           evt.nome_evento,
                           coalesce(evt.cidade, '') AS cidade,
                           coalesce(evt.estado, '') AS estado,
                           coalesce(evt.tag, '') AS tag,
                           evt.data_inicial,
                           evt.id_agrega_evento,
                           agr.nome_evento_agregado AS atual_nome_evento_agregado,
                           agr.tipo_agregacao AS atual_tipo_agregacao,
                           pending.id_evento_agrega_review_group AS pending_group_id,
                           pending.pending_group_name
                    FROM tb_evento_corridas evt
                    LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = evt.id_agrega_evento
                    LEFT JOIN LATERAL (
                        SELECT grp.id_evento_agrega_review_group,
                               <cfif VARIABLES.agregaReviewHasDisplayName>
                                   coalesce(nullif(trim(grp.display_name), ''), grp.normalized_name) AS pending_group_name
                               <cfelse>
                                   grp.normalized_name AS pending_group_name
                               </cfif>
                        FROM tb_evento_agrega_review_candidates cand
                        INNER JOIN tb_evento_agrega_review_groups grp
                            ON grp.id_evento_agrega_review_group = cand.id_evento_agrega_review_group
                        WHERE cand.id_evento = evt.id_evento
                          AND cand.status = 'active'
                          AND grp.status = 'review'
                          AND grp.id_evento_agrega_review_group <> <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewFocusGroupId#" />
                        ORDER BY grp.data_atualizacao DESC, grp.id_evento_agrega_review_group DESC
                        LIMIT 1
                    ) pending ON true
                    WHERE evt.ativo = true
                      AND coalesce(evt.nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.agregaReviewEventSearchTerm#%" />
                      AND NOT EXISTS (
                          SELECT 1
                          FROM tb_evento_agrega_review_candidates own_cand
                          WHERE own_cand.id_evento_agrega_review_group = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewFocusGroupId#" />
                            AND own_cand.id_evento = evt.id_evento
                      )
                    ORDER BY
                        CASE
                            WHEN lower(trim(coalesce(evt.cidade, ''))) = lower(trim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#qAgregaReviewGroups.cidade[1]#" />))
                             AND upper(trim(coalesce(evt.estado, ''))) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(qAgregaReviewGroups.estado[1]))#" /> THEN 0
                            ELSE 1
                        END,
                        evt.data_inicial DESC NULLS LAST,
                        evt.nome_evento,
                        evt.id_evento
                    LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewEventSearchLimit#" />
                </cfquery>
            </cfif>
        </cfif>

        <cfif VARIABLES.agregaReviewFocusGroupId GT 0
            AND (len(VARIABLES.agregaReviewAggregatorSearchTerm) GTE 2 OR isNumeric(VARIABLES.agregaReviewAggregatorSearchTerm))>
            <cfquery name="qAgregaReviewAggregatorSearchLookup">
                SELECT id_agrega_evento,
                       nome_evento_agregado,
                       tipo_agregacao,
                       coalesce(tag, '') AS tag
                FROM tb_agrega_eventos
                WHERE lower(trim(tipo_agregacao)) <> 'circuito' AND (
                    <cfif isNumeric(VARIABLES.agregaReviewAggregatorSearchTerm)>
                        id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.agregaReviewAggregatorSearchTerm)#" />
                        OR
                    </cfif>
                    lower(coalesce(nome_evento_agregado, '')) LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#lCase(VARIABLES.agregaReviewAggregatorSearchTerm)#%" />
                    OR lower(coalesce(tag, '')) LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#lCase(VARIABLES.agregaReviewAggregatorSearchTerm)#%" />
                )
                ORDER BY
                    CASE
                        WHEN lower(coalesce(nome_evento_agregado, '')) LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(VARIABLES.agregaReviewAggregatorSearchTerm)#%" /> THEN 0
                        WHEN lower(coalesce(tag, '')) LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(VARIABLES.agregaReviewAggregatorSearchTerm)#%" /> THEN 1
                        ELSE 2
                    END,
                    nome_evento_agregado
                LIMIT 30
            </cfquery>

            <cfloop query="qAgregaReviewAggregatorSearchLookup">
                <cfset VARIABLES.agregaReviewSearchAggregators[toString(qAgregaReviewAggregatorSearchLookup.id_agrega_evento)] = {
                    id = qAgregaReviewAggregatorSearchLookup.id_agrega_evento,
                    nome = qAgregaReviewAggregatorSearchLookup.nome_evento_agregado,
                    tipo = qAgregaReviewAggregatorSearchLookup.tipo_agregacao,
                    tag = qAgregaReviewAggregatorSearchLookup.tag
                } />
            </cfloop>
        </cfif>

        <cfquery name="qAgregaReviewCandidates">
            SELECT cand.*, evt.id_agrega_evento AS live_id_agrega_evento, evt.ativo AS live_ativo,
                   agr.nome_evento_agregado AS atual_nome_evento_agregado,
                   agr.tipo_agregacao AS atual_tipo_agregacao
            FROM tb_evento_agrega_review_candidates cand
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = cand.id_evento
            LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = evt.id_agrega_evento
            WHERE cand.id_evento_agrega_review_group IN (
                <cfqueryparam cfsqltype="cf_sql_bigint" value="#valueList(qAgregaReviewGroups.id_evento_agrega_review_group)#" list="true" />
            )
            ORDER BY cand.id_evento_agrega_review_group, cand.id_evento_agrega_review_candidate
        </cfquery>

        <cfset VARIABLES.agregaReviewCurrentAggregatorsByGroup = {} />
        <cfloop query="qAgregaReviewCandidates">
            <cfset querySetCell(qAgregaReviewCandidates, "id_agrega_evento_atual", val(qAgregaReviewCandidates.live_id_agrega_evento), qAgregaReviewCandidates.currentRow) />
            <cfif val(qAgregaReviewCandidates.id_agrega_evento_atual) GT 0>
                <cfset VARIABLES.agregaReviewCurrentAggregatorGroupKey = toString(qAgregaReviewCandidates.id_evento_agrega_review_group) />
                <cfset VARIABLES.agregaReviewCurrentAggregatorKey = toString(qAgregaReviewCandidates.id_agrega_evento_atual) />

                <cfif NOT structKeyExists(VARIABLES.agregaReviewCurrentAggregatorsByGroup, VARIABLES.agregaReviewCurrentAggregatorGroupKey)>
                    <cfset VARIABLES.agregaReviewCurrentAggregatorsByGroup[VARIABLES.agregaReviewCurrentAggregatorGroupKey] = {} />
                </cfif>

                <cfif NOT structKeyExists(VARIABLES.agregaReviewCurrentAggregatorsByGroup[VARIABLES.agregaReviewCurrentAggregatorGroupKey], VARIABLES.agregaReviewCurrentAggregatorKey)>
                    <cfset VARIABLES.agregaReviewCurrentAggregatorsByGroup[VARIABLES.agregaReviewCurrentAggregatorGroupKey][VARIABLES.agregaReviewCurrentAggregatorKey] = {
                        id = qAgregaReviewCandidates.id_agrega_evento_atual,
                        nome = qAgregaReviewCandidates.atual_nome_evento_agregado,
                        tipo = qAgregaReviewCandidates.atual_tipo_agregacao,
                        tag = ""
                    } />
                </cfif>
            </cfif>
        </cfloop>

        <cfloop query="qAgregaReviewGroups">
            <cfset VARIABLES.agregaReviewCurrentGroupId = toString(qAgregaReviewGroups.id_evento_agrega_review_group) />
            <cfset VARIABLES.agregaReviewCurrentHasMissing = false />
            <cfset VARIABLES.agregaReviewCurrentAggregators = "" />
            <cfset VARIABLES.agregaReviewCurrentActiveCandidates = 0 />
            <cfset VARIABLES.agregaReviewCurrentTotalCandidates = 0 />
            <cfset VARIABLES.agregaReviewCurrentAllActive = true />
            <cfset VARIABLES.agregaReviewCurrentEventIds = "" />

            <cfloop query="qAgregaReviewCandidates">
                <cfif qAgregaReviewCandidates.id_evento_agrega_review_group EQ qAgregaReviewGroups.id_evento_agrega_review_group>
                    <cfset VARIABLES.agregaReviewCurrentTotalCandidates++ />
                    <cfset VARIABLES.agregaReviewCurrentEventIds = listAppend(VARIABLES.agregaReviewCurrentEventIds, qAgregaReviewCandidates.id_evento) />
                    <cfif NOT isBoolean(qAgregaReviewCandidates.live_ativo) OR NOT qAgregaReviewCandidates.live_ativo>
                        <cfset VARIABLES.agregaReviewCurrentAllActive = false />
                    </cfif>
                </cfif>
                <cfif qAgregaReviewCandidates.id_evento_agrega_review_group EQ qAgregaReviewGroups.id_evento_agrega_review_group
                    AND qAgregaReviewCandidates.status EQ "active">
                    <cfset VARIABLES.agregaReviewCurrentActiveCandidates = VARIABLES.agregaReviewCurrentActiveCandidates + 1 />
                    <cfif val(qAgregaReviewCandidates.id_agrega_evento_atual) LTE 0>
                        <cfset VARIABLES.agregaReviewCurrentHasMissing = true />
                    <cfelseif NOT listFind(VARIABLES.agregaReviewCurrentAggregators, qAgregaReviewCandidates.id_agrega_evento_atual)>
                        <cfset VARIABLES.agregaReviewCurrentAggregators = listAppend(VARIABLES.agregaReviewCurrentAggregators, qAgregaReviewCandidates.id_agrega_evento_atual) />
                    </cfif>
                </cfif>
            </cfloop>

            <cfif qAgregaReviewGroups.status EQ "review" AND left(qAgregaReviewGroups.group_key, 11) EQ "edicoes-v1:"
                AND val(qAgregaReviewGroups.candidate_count) EQ 2 AND val(qAgregaReviewGroups.suggested_id_agrega_evento) LTE 0
                AND VARIABLES.agregaReviewCurrentTotalCandidates EQ 2 AND VARIABLES.agregaReviewCurrentActiveCandidates EQ 2
                AND VARIABLES.agregaReviewCurrentAllActive AND NOT len(VARIABLES.agregaReviewCurrentAggregators)>
                <cfset VARIABLES.agregaReviewQuickGroups[VARIABLES.agregaReviewCurrentGroupId] = VARIABLES.agregaReviewCurrentEventIds />
            </cfif>

            <cfif qAgregaReviewGroups.status EQ "review" AND left(qAgregaReviewGroups.group_key, 11) EQ "edicoes-v1:"
                AND val(qAgregaReviewGroups.candidate_count) EQ 2
                AND VARIABLES.agregaReviewCurrentTotalCandidates EQ 2 AND VARIABLES.agregaReviewCurrentActiveCandidates EQ 2
                AND VARIABLES.agregaReviewCurrentAllActive AND VARIABLES.agregaReviewCurrentHasMissing
                AND listLen(VARIABLES.agregaReviewCurrentAggregators) EQ 1>
                <cfset VARIABLES.agregaReviewExistingId = listFirst(VARIABLES.agregaReviewCurrentAggregators) />
                <cfset VARIABLES.agregaReviewExistingOption = VARIABLES.agregaReviewCurrentAggregatorsByGroup[VARIABLES.agregaReviewCurrentGroupId][VARIABLES.agregaReviewExistingId] />
                <cfif len(trim(VARIABLES.agregaReviewExistingOption.nome))
                    AND lCase(trim(VARIABLES.agregaReviewExistingOption.tipo)) NEQ "circuito"
                    AND (val(qAgregaReviewGroups.suggested_id_agrega_evento) LTE 0 OR val(qAgregaReviewGroups.suggested_id_agrega_evento) EQ val(VARIABLES.agregaReviewExistingId))>
                    <cfset VARIABLES.agregaReviewQuickExistingGroups[VARIABLES.agregaReviewCurrentGroupId] = {
                        id = val(VARIABLES.agregaReviewExistingId), nome = VARIABLES.agregaReviewExistingOption.nome,
                        eventIds = VARIABLES.agregaReviewCurrentEventIds
                    } />
                </cfif>
            </cfif>

            <cfif qAgregaReviewGroups.status NEQ "review" OR (VARIABLES.agregaReviewCurrentActiveCandidates GTE 2
                AND (VARIABLES.agregaReviewCurrentHasMissing OR listLen(VARIABLES.agregaReviewCurrentAggregators) GT 1))>
                <cfset VARIABLES.agregaReviewActionableGroups[VARIABLES.agregaReviewCurrentGroupId] = true />
                <cfset VARIABLES.agregaReviewRenderableTotal = VARIABLES.agregaReviewRenderableTotal + 1 />
            </cfif>
        </cfloop>
    </cfif>
</cfif>
