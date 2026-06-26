<cfprocessingdirective pageencoding="utf-8" />

<cfparam name="URL.pagina" default="1" />
<cfparam name="URL.busca" default="" />
<cfparam name="URL.status" default="review" />
<cfparam name="URL.ordenar" default="score" />
<cfparam name="URL.direcao" default="desc" />
<cfparam name="URL.grupo" default="0" />
<cfparam name="URL.agregador_busca" default="" />
<cfparam name="URL.sucesso" default="" />
<cfparam name="FORM.acao" default="" />

<cfscript>
function agregaReviewNormalizeText(value) {
    var text = lCase(trim(toString(value)));
    var fromChars = "áàâãäåéèêëíìîïóòôõöúùûüçñ";
    var toChars = "aaaaaaeeeeiiiiooooouuuucn";
    var i = 1;

    for (i = 1; i <= len(fromChars); i++) {
        text = replace(text, mid(fromChars, i, 1), mid(toChars, i, 1), "all");
    }

    text = reReplace(text, "\b(19|20)[0-9]{2}\b", " ", "all");
    text = reReplace(text, "\b[0-9]{1,2}[ao]?\b", " ", "all");
    text = reReplace(text, "\b(edicao|edição)\b", " ", "all");
    text = reReplace(text, "[^a-z0-9]+", " ", "all");
    text = reReplace(trim(text), "\s+", " ", "all");

    return text;
}

function agregaReviewDisplayName(value) {
    var text = trim(toString(value));
    var words = [];
    var formattedWords = [];
    var word = "";
    var lowerWord = "";

    text = reReplace(text, "\b(19|20)[0-9]{2}\b", " ", "all");
    text = reReplace(text, "^\s*[0-9]{1,2}[ºª]?\s+", "", "one");
    text = reReplace(text, "^\s*[0-9]{1,2}[ao]?\s+", "", "one");
    text = reReplace(text, "\b(edicao|edição)\b", " ", "all");
    text = reReplace(trim(text), "\s+", " ", "all");

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

function agregaFindParent(parentStruct, eventId) {
    var currentId = toString(eventId);
    if (!structKeyExists(parentStruct, currentId)) {
        parentStruct[currentId] = currentId;
    }
    while (parentStruct[currentId] NEQ currentId) {
        currentId = parentStruct[currentId];
    }
    return currentId;
}

function agregaUnionParent(parentStruct, leftId, rightId) {
    var leftParent = agregaFindParent(parentStruct, leftId);
    var rightParent = agregaFindParent(parentStruct, rightId);
    if (leftParent NEQ rightParent) {
        parentStruct[rightParent] = leftParent;
    }
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
<cfset VARIABLES.agregaReviewAllowedStatuses = "review,applied,ignored,all" />
<cfset VARIABLES.agregaReviewAllowedOrders = "score,nome,atualizacao" />
<cfset VARIABLES.agregaReviewAllowedDirections = "asc,desc" />
<cfset VARIABLES.agregaReviewNotice = "" />
<cfset VARIABLES.agregaReviewError = "" />
<cfset VARIABLES.agregaReviewGeneratedGroups = 0 />
<cfset VARIABLES.agregaReviewGeneratedCandidates = 0 />

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
    <cfset VARIABLES.agregaReviewNotice = "Sugestoes de agregacao geradas com sucesso." />
<cfelseif URL.sucesso EQ "aplicado">
    <cfset VARIABLES.agregaReviewNotice = "Agregador aplicado aos eventos selecionados." />
<cfelseif URL.sucesso EQ "ignorado">
    <cfset VARIABLES.agregaReviewNotice = "Item removido da revisao." />
<cfelseif URL.sucesso EQ "agregador_criado">
    <cfset VARIABLES.agregaReviewNotice = "Agregador criado e selecionado para o grupo de revisao." />
<cfelseif URL.sucesso EQ "agregador_existente">
    <cfset VARIABLES.agregaReviewNotice = "Ja existia um agregador com este nome ou tag. Ele foi selecionado para o grupo de revisao." />
</cfif>

<cfif VARIABLES.agregaReviewSchemaReady AND len(trim(FORM.acao))>
    <cfset VARIABLES.agregaReviewAction = listLast(lCase(trim(FORM.acao))) />

    <cftry>
        <cfif VARIABLES.agregaReviewAction EQ "gerar_sugestoes">
            <cfset VARIABLES.agregaReviewMinScore = 78 />
            <cfif isDefined("FORM.min_score")>
                <cfset VARIABLES.agregaReviewMinScore = val(FORM.min_score) />
                <cfif VARIABLES.agregaReviewMinScore LT 40>
                    <cfset VARIABLES.agregaReviewMinScore = 40 />
                <cfelseif VARIABLES.agregaReviewMinScore GT 100>
                    <cfset VARIABLES.agregaReviewMinScore = 100 />
                </cfif>
            </cfif>
            <cfset VARIABLES.agregaReviewLimit = 5000 />
            <cfif isDefined("FORM.limite_eventos")>
                <cfset VARIABLES.agregaReviewLimit = val(FORM.limite_eventos) />
                <cfif VARIABLES.agregaReviewLimit LT 100>
                    <cfset VARIABLES.agregaReviewLimit = 100 />
                <cfelseif VARIABLES.agregaReviewLimit GT 12000>
                    <cfset VARIABLES.agregaReviewLimit = 12000 />
                </cfif>
            </cfif>
            <cfset VARIABLES.agregaReviewPairs = [] />
            <cfset VARIABLES.agregaReviewParent = {} />
            <cfset VARIABLES.agregaReviewSource = [] />
            <cfset VARIABLES.agregaReviewLocationGroups = {} />

            <cfquery name="qAgregaReviewSourceEvents">
                SELECT evt.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.tag,
                       evt.data_inicial, evt.id_agrega_evento
                FROM tb_evento_corridas evt
                WHERE evt.ativo = true
                  AND coalesce(trim(evt.nome_evento), '') <> ''
                  AND coalesce(trim(evt.cidade), '') <> ''
                  AND coalesce(trim(evt.estado), '') <> ''
                ORDER BY evt.cidade, evt.estado, evt.nome_evento, evt.data_inicial DESC NULLS LAST
                LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewLimit#" />
            </cfquery>

            <cfscript>
            for (rowIndex = 1; rowIndex <= qAgregaReviewSourceEvents.recordCount; rowIndex++) {
                sourceEvent = {
                    idEvento = qAgregaReviewSourceEvents.id_evento[rowIndex],
                    nomeEvento = qAgregaReviewSourceEvents.nome_evento[rowIndex],
                    cidade = qAgregaReviewSourceEvents.cidade[rowIndex],
                    estado = qAgregaReviewSourceEvents.estado[rowIndex],
                    tag = qAgregaReviewSourceEvents.tag[rowIndex],
                    dataInicial = qAgregaReviewSourceEvents.data_inicial[rowIndex],
                    idAgregaEvento = val(qAgregaReviewSourceEvents.id_agrega_evento[rowIndex]),
                    normalizedName = agregaReviewNormalizeText(qAgregaReviewSourceEvents.nome_evento[rowIndex]),
                    normalizedCity = agregaReviewNormalizeText(qAgregaReviewSourceEvents.cidade[rowIndex]),
                    normalizedUf = uCase(trim(qAgregaReviewSourceEvents.estado[rowIndex]))
                };

                arrayAppend(VARIABLES.agregaReviewSource, sourceEvent);
                VARIABLES.agregaReviewParent[toString(sourceEvent.idEvento)] = toString(sourceEvent.idEvento);
                locationKey = sourceEvent.normalizedCity & "|" & sourceEvent.normalizedUf;
                if (!structKeyExists(VARIABLES.agregaReviewLocationGroups, locationKey)) {
                    VARIABLES.agregaReviewLocationGroups[locationKey] = [];
                }
                arrayAppend(VARIABLES.agregaReviewLocationGroups[locationKey], sourceEvent);
            }

            for (locationKey in VARIABLES.agregaReviewLocationGroups) {
                locationEvents = VARIABLES.agregaReviewLocationGroups[locationKey];

                for (leftIndex = 1; leftIndex <= arrayLen(locationEvents); leftIndex++) {
                    leftEvent = locationEvents[leftIndex];

                    for (rightIndex = leftIndex + 1; rightIndex <= arrayLen(locationEvents); rightIndex++) {
                        rightEvent = locationEvents[rightIndex];

                        if (leftEvent.idAgregaEvento GT 0 AND rightEvent.idAgregaEvento GT 0 AND leftEvent.idAgregaEvento EQ rightEvent.idAgregaEvento) {
                            continue;
                        }

                        nameScore = agregaReviewTokenScore(leftEvent.nomeEvento, rightEvent.nomeEvento);
                        cityScore = 100;
                        finalScore = round(((nameScore * 0.80) + (cityScore * 0.20)) * 100) / 100;

                        if (finalScore GTE VARIABLES.agregaReviewMinScore) {
                            arrayAppend(VARIABLES.agregaReviewPairs, {
                                leftId = leftEvent.idEvento,
                                rightId = rightEvent.idEvento,
                                score = finalScore,
                                nameScore = nameScore,
                                cityScore = cityScore
                            });
                            agregaUnionParent(VARIABLES.agregaReviewParent, leftEvent.idEvento, rightEvent.idEvento);
                        }
                    }
                }
            }

            VARIABLES.agregaReviewGroups = {};
            for (eventItem in VARIABLES.agregaReviewSource) {
                parentId = agregaFindParent(VARIABLES.agregaReviewParent, eventItem.idEvento);
                if (!structKeyExists(VARIABLES.agregaReviewGroups, parentId)) {
                    VARIABLES.agregaReviewGroups[parentId] = [];
                }
                arrayAppend(VARIABLES.agregaReviewGroups[parentId], eventItem);
            }
            </cfscript>

            <cftransaction>
                <cfloop collection="#VARIABLES.agregaReviewGroups#" item="VARIABLES.agregaReviewGroupId">
                    <cfset VARIABLES.agregaReviewEvents = VARIABLES.agregaReviewGroups[VARIABLES.agregaReviewGroupId] />
                    <cfif arrayLen(VARIABLES.agregaReviewEvents) LT 2>
                        <cfcontinue />
                    </cfif>

                    <cfset VARIABLES.agregaReviewFirstEvent = VARIABLES.agregaReviewEvents[1] />
                    <cfset VARIABLES.agregaReviewNormalizedName = VARIABLES.agregaReviewFirstEvent.normalizedName />
                    <cfset VARIABLES.agregaReviewGroupKeyValue = agregaReviewBuildGroupKey(VARIABLES.agregaReviewNormalizedName, VARIABLES.agregaReviewFirstEvent.cidade, VARIABLES.agregaReviewFirstEvent.estado) />
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

                    <cfloop array="#VARIABLES.agregaReviewPairs#" index="VARIABLES.agregaReviewPair">
                        <cfif agregaReviewIdInList(VARIABLES.agregaReviewEventIds, VARIABLES.agregaReviewPair.leftId) AND agregaReviewIdInList(VARIABLES.agregaReviewEventIds, VARIABLES.agregaReviewPair.rightId)>
                            <cfif VARIABLES.agregaReviewPair.score GT VARIABLES.agregaReviewMaxScore>
                                <cfset VARIABLES.agregaReviewMaxScore = VARIABLES.agregaReviewPair.score />
                            </cfif>
                        </cfif>
                    </cfloop>

                    <cfif VARIABLES.agregaReviewHasDisplayName>
                        <cfquery name="qAgregaReviewUpsertGroup">
                            INSERT INTO tb_evento_agrega_review_groups
                                (group_key, normalized_name, display_name, cidade, estado, candidate_count, max_score, suggested_id_agrega_evento, status, created_by, data_atualizacao)
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
                                (group_key, normalized_name, cidade, estado, candidate_count, max_score, suggested_id_agrega_evento, status, created_by, data_atualizacao)
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
                        <cfset VARIABLES.agregaReviewCandidateScore = 0 />
                        <cfloop array="#VARIABLES.agregaReviewPairs#" index="VARIABLES.agregaReviewPair">
                            <cfif (VARIABLES.agregaReviewPair.leftId EQ VARIABLES.agregaReviewEvent.idEvento OR VARIABLES.agregaReviewPair.rightId EQ VARIABLES.agregaReviewEvent.idEvento)
                                AND agregaReviewIdInList(VARIABLES.agregaReviewEventIds, VARIABLES.agregaReviewPair.leftId)
                                AND agregaReviewIdInList(VARIABLES.agregaReviewEventIds, VARIABLES.agregaReviewPair.rightId)>
                                <cfif VARIABLES.agregaReviewPair.score GT VARIABLES.agregaReviewCandidateScore>
                                    <cfset VARIABLES.agregaReviewCandidateScore = VARIABLES.agregaReviewPair.score />
                                </cfif>
                            </cfif>
                        </cfloop>
                        <cfset VARIABLES.agregaReviewCandidateNameScore = (VARIABLES.agregaReviewCandidateScore - 20) / 0.8 />
                        <cfif VARIABLES.agregaReviewCandidateNameScore LT 0>
                            <cfset VARIABLES.agregaReviewCandidateNameScore = 0 />
                        </cfif>

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

            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=gerado" />
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

            <cflocation addtoken="false" url="/administracao/agrega-revisao/?sucesso=#VARIABLES.agregaReviewAggregatorSuccess#&grupo=#VARIABLES.agregaReviewGroupId#" />
        <cfelseif VARIABLES.agregaReviewAction EQ "aplicar_agregador">
            <cfset VARIABLES.agregaReviewGroupId = 0 />
            <cfif isDefined("FORM.id_grupo")>
                <cfset VARIABLES.agregaReviewGroupId = val(FORM.id_grupo) />
            </cfif>
            <cfset VARIABLES.agregaReviewSelectedAgregaId = 0 />
            <cfif isDefined("FORM.id_agrega_evento")>
                <cfset VARIABLES.agregaReviewSelectedAgregaId = val(FORM.id_agrega_evento) />
            </cfif>
            <cfset VARIABLES.agregaReviewSelectedEvents = "" />
            <cfif isDefined("FORM.eventos")>
                <cfset VARIABLES.agregaReviewSelectedEvents = trim(FORM.eventos) />
            </cfif>
            <cfset VARIABLES.agregaReviewNote = "" />
            <cfif isDefined("FORM.observacao")>
                <cfset VARIABLES.agregaReviewNote = trim(FORM.observacao) />
            </cfif>

            <cfif VARIABLES.agregaReviewGroupId LTE 0 OR VARIABLES.agregaReviewSelectedAgregaId LTE 0 OR !len(VARIABLES.agregaReviewSelectedEvents)>
                <cfthrow type="AgregaReview.Validation" message="Selecione o grupo, o agregador e ao menos um evento." />
            </cfif>

            <cftransaction>
                <cfquery name="qAgregaReviewAggregatorLock">
                    SELECT id_agrega_evento
                    FROM tb_agrega_eventos
                    WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.agregaReviewSelectedAgregaId#" />
                </cfquery>

                <cfif !qAgregaReviewAggregatorLock.recordcount>
                    <cfthrow type="AgregaReview.Validation" message="Agregador selecionado nao existe." />
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
    <cfset qAgregaReviewStats = queryNew("review,applied,ignored", "integer,integer,integer", [{review = 0, applied = 0, ignored = 0}]) />

    <cfquery name="qAgregaReviewAggregatorTypes" cachedwithin="#CreateTimeSpan(0, 1, 0, 0)#">
        SELECT tipo_agregacao
        FROM (
            SELECT DISTINCT nullif(trim(tipo_agregacao), '') AS tipo_agregacao
            FROM tb_agrega_eventos
            WHERE nullif(trim(tipo_agregacao), '') IS NOT NULL

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

    <cfset VARIABLES.agregaReviewTotal = 0 />
    <cfset VARIABLES.agregaReviewTotalPages = 1 />
    <cfset VARIABLES.agregaReviewPage = 1 />
    <cfset VARIABLES.agregaReviewOffset = 0 />
    <cfset VARIABLES.agregaReviewSuggestedAggregators = {} />
    <cfset VARIABLES.agregaReviewSearchAggregators = {} />
    <cfset VARIABLES.agregaReviewRecentWindowSize = 50000 />

    <cfquery name="qAgregaReviewLatestGroupId">
        SELECT coalesce(max(id_evento_agrega_review_group), 0) AS latest_id
        FROM tb_evento_agrega_review_groups
    </cfquery>

    <cfset VARIABLES.agregaReviewRecentMinGroupId = val(qAgregaReviewLatestGroupId.latest_id) - VARIABLES.agregaReviewRecentWindowSize />
    <cfif VARIABLES.agregaReviewRecentMinGroupId LT 0>
        <cfset VARIABLES.agregaReviewRecentMinGroupId = 0 />
    </cfif>

    <cfquery name="qAgregaReviewGroups">
        SELECT grp.*,
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
            AND grp.id_evento_agrega_review_group >= <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.agregaReviewRecentMinGroupId#" />
            <cfif VARIABLES.agregaReviewStatus NEQ "all">
                AND grp.status = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.agregaReviewStatus#" />
            </cfif>
        </cfif>
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="80" />
    </cfquery>
    <cfset VARIABLES.agregaReviewTotal = qAgregaReviewGroups.recordcount />
    <cfset VARIABLES.agregaReviewTotalPages = 1 />
    <cfset VARIABLES.agregaReviewPage = 1 />
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

        <cfif VARIABLES.agregaReviewFocusGroupId GT 0
            AND (len(VARIABLES.agregaReviewAggregatorSearchTerm) GTE 2 OR isNumeric(VARIABLES.agregaReviewAggregatorSearchTerm))>
            <cfquery name="qAgregaReviewAggregatorSearchLookup">
                SELECT id_agrega_evento,
                       nome_evento_agregado,
                       tipo_agregacao,
                       coalesce(tag, '') AS tag
                FROM tb_agrega_eventos
                WHERE
                    <cfif isNumeric(VARIABLES.agregaReviewAggregatorSearchTerm)>
                        id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.agregaReviewAggregatorSearchTerm)#" />
                        OR
                    </cfif>
                    lower(coalesce(nome_evento_agregado, '')) LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#lCase(VARIABLES.agregaReviewAggregatorSearchTerm)#%" />
                    OR lower(coalesce(tag, '')) LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#lCase(VARIABLES.agregaReviewAggregatorSearchTerm)#%" />
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
            SELECT cand.*,
                   agr.nome_evento_agregado AS atual_nome_evento_agregado,
                   agr.tipo_agregacao AS atual_tipo_agregacao
            FROM tb_evento_agrega_review_candidates cand
            LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = cand.id_agrega_evento_atual
            WHERE cand.id_evento_agrega_review_group IN (
                <cfqueryparam cfsqltype="cf_sql_bigint" value="#valueList(qAgregaReviewGroups.id_evento_agrega_review_group)#" list="true" />
            )
            ORDER BY cand.id_evento_agrega_review_group, cand.id_evento_agrega_review_candidate
        </cfquery>

        <cfset VARIABLES.agregaReviewCurrentAggregatorsByGroup = {} />
        <cfloop query="qAgregaReviewCandidates">
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

            <cfloop query="qAgregaReviewCandidates">
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

            <cfif qAgregaReviewGroups.status EQ "review"
                AND VARIABLES.agregaReviewCurrentActiveCandidates GTE 2
                AND (VARIABLES.agregaReviewCurrentHasMissing OR listLen(VARIABLES.agregaReviewCurrentAggregators) GT 1)>
                <cfset VARIABLES.agregaReviewActionableGroups[VARIABLES.agregaReviewCurrentGroupId] = true />
                <cfset VARIABLES.agregaReviewRenderableTotal = VARIABLES.agregaReviewRenderableTotal + 1 />
            </cfif>
        </cfloop>
    </cfif>
</cfif>
