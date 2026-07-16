<cfscript>
function agendaServiceTablesReady() output="false" {
    var requiredTables = "tb_agendas,tb_agenda_eventos,tb_agenda_filtros,tb_agenda_credenciais,tb_agenda_acessos";
    var tableQuery = queryExecute(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = current_schema() AND table_name IN ('tb_agendas','tb_agenda_eventos','tb_agenda_filtros','tb_agenda_credenciais','tb_agenda_acessos')"
    );
    var existingTables = valueList(tableQuery.table_name);
    var requiredTable = "";
    var visualColumnQuery = "";
    var visualColumns = "";

    for (requiredTable in listToArray(requiredTables)) {
        if (!listFindNoCase(existingTables, requiredTable)) {
            return false;
        }
    }

    visualColumnQuery = queryExecute(
        "SELECT column_name FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'tb_agendas' AND column_name IN ('tema_embed','cor_card_data','fonte_cards','raio_cards')"
    );
    visualColumns = valueList(visualColumnQuery.column_name);

    if (!listFindNoCase(visualColumns, "tema_embed")
        || !listFindNoCase(visualColumns, "cor_card_data")
        || !listFindNoCase(visualColumns, "fonte_cards")
        || !listFindNoCase(visualColumns, "raio_cards")) {
        return false;
    }

    return true;
}

function agendaServiceNormalizeBoolean(any rawValue = false) output="false" {
    if (isBoolean(arguments.rawValue)) {
        return arguments.rawValue;
    }

    return listFindNoCase("1,true,yes,on,sim", trim(arguments.rawValue & "")) GT 0;
}

function agendaServiceNormalizeTheme(any rawValue = "escuro") output="false" {
    var normalized = lCase(trim(arguments.rawValue & ""));
    return listFindNoCase("claro,escuro", normalized) ? normalized : "escuro";
}

function agendaServiceNormalizeCardFont(any rawValue = "trebuchet") output="false" {
    var normalized = lCase(trim(arguments.rawValue & ""));
    return listFindNoCase("trebuchet,verdana,georgia,tahoma,monospace", normalized) ? normalized : "trebuchet";
}

function agendaServiceNormalizeCardRadius(any rawValue = "atual") output="false" {
    var normalized = lCase(trim(arguments.rawValue & ""));
    return listFindNoCase("atual,medio,suave,reto", normalized) ? normalized : "atual";
}

function agendaServiceNormalizeHexColor(any rawValue = "fab120", string fallback = "fab120") output="false" {
    var normalized = lCase(trim(arguments.rawValue & ""));
    var fallbackValue = lCase(reReplace(arguments.fallback, "[^0-9a-f]", "", "all"));

    if (len(normalized) EQ 7 && left(normalized, 1) EQ chr(35)) {
        normalized = right(normalized, 6);
    }
    if (len(normalized) EQ 6 && reFindNoCase("^[0-9a-f]{6}$", normalized) EQ 1) {
        return chr(35) & normalized;
    }
    if (len(fallbackValue) NEQ 6 || reFindNoCase("^[0-9a-f]{6}$", fallbackValue) NEQ 1) {
        fallbackValue = "fab120";
    }

    return chr(35) & fallbackValue;
}

function agendaServiceContrastColor(any backgroundColor = "fab120") output="false" {
    var normalized = right(agendaServiceNormalizeHexColor(arguments.backgroundColor), 6);
    var redValue = inputBaseN(mid(normalized, 1, 2), 16);
    var greenValue = inputBaseN(mid(normalized, 3, 2), 16);
    var blueValue = inputBaseN(mid(normalized, 5, 2), 16);
    var luminance = (redValue * 299 + greenValue * 587 + blueValue * 114) / 1000;

    return luminance GTE 145 ? chr(35) & "171717" : chr(35) & "ffffff";
}

function agendaServiceDisplayDistances(any rawDistances = "") output="false" {
    var result = [];
    var distanceItem = {};
    var numericDistance = 0;

    if (!isArray(arguments.rawDistances)) {
        return result;
    }

    for (distanceItem in arguments.rawDistances) {
        if (!isStruct(distanceItem) || !structKeyExists(distanceItem, "distancia") || !isNumeric(distanceItem.distancia)) {
            continue;
        }

        numericDistance = val(distanceItem.distancia);
        if (numericDistance GTE 3 && numericDistance EQ fix(numericDistance)) {
            arrayAppend(result, distanceItem);
        }
    }

    return result;
}

function agendaServiceMonthAbbreviationPtBr(required date dateValue) output="false" {
    var monthNames = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"];
    return monthNames[month(arguments.dateValue)];
}

function agendaServiceNormalizeHost(string rawValue = "") output="false" {
    var normalized = lCase(trim(arguments.rawValue));

    if (!len(normalized)) {
        return "";
    }

    normalized = reReplace(normalized, "^[a-z][a-z0-9+.-]*://", "", "one");
    normalized = listFirst(normalized, "/");
    normalized = listLast(normalized, "@");

    if (find(":", normalized) AND !reFind("^\[[0-9a-f:]+\]", normalized)) {
        normalized = listFirst(normalized, ":");
    }

    normalized = reReplace(normalized, "\.$", "", "one");

    return normalized;
}

function agendaServiceValidHost(string rawValue = "") output="false" {
    var normalized = agendaServiceNormalizeHost(arguments.rawValue);
    return len(normalized) LTE 255
        AND reFindNoCase("^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$", normalized) EQ 1;
}

function agendaServiceRequestHeader(required string headerName) output="false" {
    var requestData = getHttpRequestData();
    var headerKey = "";

    if (!structKeyExists(requestData, "headers") || !isStruct(requestData.headers)) {
        return "";
    }

    for (headerKey in requestData.headers) {
        if (compareNoCase(headerKey, arguments.headerName) EQ 0) {
            return trim(requestData.headers[headerKey] & "");
        }
    }

    return "";
}

function agendaServiceRequestSource() output="false" {
    var origin = agendaServiceRequestHeader("Origin");
    var referer = agendaServiceRequestHeader("Referer");
    var source = len(origin) ? origin : referer;

    return {
        origin = origin,
        referer = referer,
        host = agendaServiceNormalizeHost(source)
    };
}

function agendaServiceClientIp() output="false" {
    var clientIp = agendaServiceRequestHeader("CF-Connecting-IP");

    if (!len(clientIp)) {
        clientIp = listFirst(agendaServiceRequestHeader("X-Forwarded-For"));
    }
    if (!len(clientIp) AND structKeyExists(CGI, "remote_addr")) {
        clientIp = trim(CGI.remote_addr & "");
    }

    clientIp = left(trim(clientIp), 64);
    return reFindNoCase("^[0-9a-f:.]+$", clientIp) ? clientIp : "";
}

function agendaServiceHostAllowed(
    required string allowedHost,
    required boolean allowSubdomains,
    string candidateHost = ""
) output="false" {
    var allowed = agendaServiceNormalizeHost(arguments.allowedHost);
    var candidate = agendaServiceNormalizeHost(arguments.candidateHost);

    if (!len(allowed) || !len(candidate)) {
        return false;
    }

    if (candidate EQ allowed) {
        return true;
    }

    return arguments.allowSubdomains
        AND len(candidate) GT len(allowed) + 1
        AND right(candidate, len(allowed) + 1) EQ "." & allowed;
}

function agendaServiceCspFrameAncestors(required string allowedHost, required boolean allowSubdomains) output="false" {
    var allowed = agendaServiceNormalizeHost(arguments.allowedHost);
    var sources = "'none'";

    if (len(allowed)) {
        sources = "https://" & allowed & " http://" & allowed;
        if (arguments.allowSubdomains) {
            sources &= " https://*." & allowed & " http://*." & allowed;
        }
    }

    return sources;
}

function agendaServiceBuildBaseUrl() output="false" {
    var isHttps = false;
    var hostName = "business.roadrunners.run";

    if (structKeyExists(CGI, "https")) {
        isHttps = isBoolean(CGI.https) ? CGI.https : listFindNoCase("on,1,yes,true", trim(CGI.https & "")) GT 0;
    }
    if (structKeyExists(CGI, "http_x_forwarded_proto") AND listFirst(CGI.http_x_forwarded_proto) EQ "https") {
        isHttps = true;
    }
    if (structKeyExists(CGI, "http_host") AND len(trim(CGI.http_host))) {
        hostName = trim(CGI.http_host);
    }

    return (isHttps ? "https://" : "http://") & hostName;
}

function agendaServiceCreatePublicKey() output="false" {
    return lCase(reReplace(createUUID(), "-", "", "all") & left(hash(createUUID() & now(), "SHA-256"), 16));
}

function agendaServiceCreateToken() output="false" {
    return lCase(left(reReplace(createUUID(), "-", "", "all") & hash(createUUID() & now() & rand(), "SHA-256"), 64));
}

function agendaServiceGetAgendaById(required numeric agendaId) output="false" {
    return queryExecute(
        "SELECT agd.*, usr.name AS usuario_nome, usr.email AS usuario_email " &
        "FROM tb_agendas agd INNER JOIN tb_usuarios usr ON usr.id = agd.id_usuario " &
        "WHERE agd.id_agenda = :agendaId",
        {
            agendaId = { value = int(arguments.agendaId), cfsqltype = "cf_sql_bigint" }
        }
    );
}

function agendaServiceGetAgendaByKey(required string publicKey, boolean activeOnly = true) output="false" {
    var sql = "SELECT agd.*, usr.name AS usuario_nome, usr.email AS usuario_email " &
        "FROM tb_agendas agd INNER JOIN tb_usuarios usr ON usr.id = agd.id_usuario " &
        "WHERE agd.chave_publica = :publicKey";

    if (arguments.activeOnly) {
        sql &= " AND agd.status = 'ativa'";
    }

    return queryExecute(
        sql,
        {
            publicKey = { value = trim(arguments.publicKey), cfsqltype = "cf_sql_varchar" }
        }
    );
}

function agendaServiceNormalizeView(string requestedView = "", string defaultView = "futuros") output="false" {
    var normalized = lCase(trim(arguments.requestedView));
    var fallback = listFindNoCase("futuros,resultados", arguments.defaultView) ? lCase(arguments.defaultView) : "futuros";
    return listFindNoCase("futuros,resultados", normalized) ? normalized : fallback;
}

function agendaServiceResolveEvents(
    required numeric agendaId,
    string requestedView = "",
    numeric requestedLimit = 0
) output="false" {
    var agendaQuery = agendaServiceGetAgendaById(arguments.agendaId);
    var emptyQuery = queryNew("id_evento,nome_evento,tag,cidade,estado,pais,data_inicial,data_final,tipo_corrida,status_evento,url_resultado,url_imagem,url_imagem_listagem,imagem,destaque,id_agrega_evento,agregador_nome,distancias_json,total_concluintes,ordem_agenda");
    var viewName = "futuros";
    var eventLimit = 20;
    var sql = "";
    var params = {};

    if (!agendaQuery.recordCount) {
        return emptyQuery;
    }

    viewName = agendaServiceNormalizeView(arguments.requestedView, agendaQuery.visao_padrao[1]);
    eventLimit = int(arguments.requestedLimit) GT 0 ? int(arguments.requestedLimit) : int(agendaQuery.limite_eventos[1]);
    eventLimit = min(100, max(1, eventLimit));

    sql = "SELECT evt.id_evento, evt.nome_evento, evt.tag, evt.cidade, evt.estado, evt.pais, " &
        "evt.data_inicial, evt.data_final, evt.tipo_corrida, evt.status_evento, evt.url_resultado, " &
        "evt.url_imagem, evt.url_imagem_listagem, evt.imagem, evt.destaque, evt.id_agrega_evento, " &
        "agr.nome_evento_agregado AS agregador_nome, " &
        "coalesce((SELECT json_agg(json_build_object('distancia', pcr.percurso_evento, 'unidade', pcr.unidade_de_medida, 'tipo', coalesce(pcr.tipo_corrida, evt.tipo_corrida)) ORDER BY pcr.percurso_evento)::text FROM tb_evento_corridas_percursos pcr WHERE pcr.id_evento = evt.id_evento), '[]') AS distancias_json, " &
        "coalesce((SELECT sum(res.concluintes) FROM tb_resultados_resumo res WHERE res.id_evento = evt.id_evento), 0) AS total_concluintes, ";

    if (lCase(agendaQuery.modo[1]) EQ "manual") {
        sql &= "aev.ordem AS ordem_agenda FROM tb_evento_corridas evt " &
            "INNER JOIN tb_agenda_eventos aev ON aev.id_evento = evt.id_evento AND aev.id_agenda = :agendaId ";
    } else {
        sql &= "0 AS ordem_agenda FROM tb_evento_corridas evt ";
    }

    sql &= "LEFT JOIN tb_agrega_eventos agr ON agr.id_agrega_evento = evt.id_agrega_evento " &
        "WHERE evt.ativo = true AND nullif(trim(evt.tag), '') IS NOT NULL " &
        "AND lower(trim(coalesce(evt.status_evento, ''))) <> 'cancelado' ";

    params.agendaId = { value = int(arguments.agendaId), cfsqltype = "cf_sql_bigint" };

    if (viewName EQ "resultados") {
        sql &= "AND evt.data_final < current_date " &
            "AND (nullif(trim(evt.url_resultado), '') IS NOT NULL OR EXISTS (SELECT 1 FROM tb_resultados_resumo res_publicado WHERE res_publicado.id_evento = evt.id_evento)) ";
    } else {
        sql &= "AND evt.data_final >= current_date ";
    }

    if (lCase(agendaQuery.modo[1]) EQ "dinamica") {
        sql &= "AND (NOT EXISTS (SELECT 1 FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'estado') " &
            "OR upper(coalesce(evt.estado, '')) IN (SELECT upper(fil.valor_texto) FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'estado')) " &
            "AND (NOT EXISTS (SELECT 1 FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'cidade') " &
            "OR EXISTS (SELECT 1 FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'cidade' AND unaccent(lower(coalesce(evt.cidade, ''))) = unaccent(lower(fil.valor_texto)))) " &
            "AND (NOT EXISTS (SELECT 1 FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'tipo') " &
            "OR lower(coalesce(evt.tipo_corrida, '')) IN (SELECT lower(fil.valor_texto) FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'tipo')) " &
            "AND (NOT EXISTS (SELECT 1 FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'agregador') " &
            "OR evt.id_agrega_evento IN (SELECT fil.valor_id FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'agregador')) " &
            "AND (NOT EXISTS (SELECT 1 FROM tb_agenda_filtros fil WHERE fil.id_agenda = :agendaId AND fil.campo = 'distancia') " &
            "OR EXISTS (SELECT 1 FROM tb_evento_corridas_percursos pcr INNER JOIN tb_agenda_filtros fil ON fil.id_agenda = :agendaId AND fil.campo = 'distancia' " &
            "WHERE pcr.id_evento = evt.id_evento AND round((CASE WHEN lower(pcr.unidade_de_medida) IN ('m','metro','metros') THEN pcr.percurso_evento / 1000.0 WHEN lower(pcr.unidade_de_medida) IN ('mi','milha','milhas') THEN pcr.percurso_evento * 1.609344 ELSE pcr.percurso_evento END)::numeric, 3) = round(fil.valor_numero::numeric, 3))) ";
    }

    if (lCase(agendaQuery.modo[1]) EQ "manual" AND lCase(agendaQuery.ordenacao[1]) EQ "manual") {
        sql &= "ORDER BY aev.ordem ASC, evt.id_evento ASC ";
    } else if (viewName EQ "resultados") {
        sql &= "ORDER BY evt.data_final DESC, evt.data_inicial DESC, evt.id_evento DESC ";
    } else {
        sql &= "ORDER BY evt.data_inicial ASC, evt.data_final ASC, evt.id_evento ASC ";
    }

    sql &= "LIMIT :eventLimit";
    params.eventLimit = { value = eventLimit, cfsqltype = "cf_sql_integer" };

    return queryExecute(sql, params);
}

function agendaServiceQueryValue(required query sourceQuery, required string columnName, required numeric rowIndex) output="false" {
    if (!listFindNoCase(arguments.sourceQuery.columnList, arguments.columnName)) {
        return "";
    }

    try {
        if (isNull(arguments.sourceQuery[arguments.columnName][arguments.rowIndex])) {
            return "";
        }
        return arguments.sourceQuery[arguments.columnName][arguments.rowIndex];
    } catch (any ignored) {
        return "";
    }
}

function agendaServiceImageUrl(any rawValue = "") output="false" {
    var imageValue = trim(arguments.rawValue & "");

    if (!len(imageValue)) {
        return "";
    }
    if (reFindNoCase("^https?://", imageValue)) {
        return imageValue;
    }

    return "https://roadrunners.run/" & reReplace(imageValue, "^/+", "", "one");
}

function agendaServiceEventsToArray(required query eventQuery) output="false" {
    var result = [];
    var rowIndex = 0;
    var distances = [];
    var imageUrl = "";

    for (rowIndex = 1; rowIndex LTE arguments.eventQuery.recordCount; rowIndex++) {
        distances = [];
        if (isJSON(agendaServiceQueryValue(arguments.eventQuery, "distancias_json", rowIndex) & "")) {
            try {
                distances = deserializeJSON(agendaServiceQueryValue(arguments.eventQuery, "distancias_json", rowIndex) & "");
            } catch (any ignoredJson) {
                distances = [];
            }
        }

        imageUrl = agendaServiceImageUrl(agendaServiceQueryValue(arguments.eventQuery, "url_imagem_listagem", rowIndex));
        if (!len(imageUrl)) {
            imageUrl = agendaServiceImageUrl(agendaServiceQueryValue(arguments.eventQuery, "url_imagem", rowIndex));
        }
        if (!len(imageUrl)) {
            imageUrl = agendaServiceImageUrl(agendaServiceQueryValue(arguments.eventQuery, "imagem", rowIndex));
        }

        arrayAppend(result, {
            id = val(agendaServiceQueryValue(arguments.eventQuery, "id_evento", rowIndex)),
            name = agendaServiceQueryValue(arguments.eventQuery, "nome_evento", rowIndex) & "",
            slug = agendaServiceQueryValue(arguments.eventQuery, "tag", rowIndex) & "",
            url = "https://roadrunners.run/evento/" & agendaServiceQueryValue(arguments.eventQuery, "tag", rowIndex) & "/",
            startDate = isDate(agendaServiceQueryValue(arguments.eventQuery, "data_inicial", rowIndex)) ? dateFormat(agendaServiceQueryValue(arguments.eventQuery, "data_inicial", rowIndex), "yyyy-mm-dd") : "",
            endDate = isDate(agendaServiceQueryValue(arguments.eventQuery, "data_final", rowIndex)) ? dateFormat(agendaServiceQueryValue(arguments.eventQuery, "data_final", rowIndex), "yyyy-mm-dd") : "",
            type = agendaServiceQueryValue(arguments.eventQuery, "tipo_corrida", rowIndex) & "",
            status = agendaServiceQueryValue(arguments.eventQuery, "status_evento", rowIndex) & "",
            location = {
                city = agendaServiceQueryValue(arguments.eventQuery, "cidade", rowIndex) & "",
                state = agendaServiceQueryValue(arguments.eventQuery, "estado", rowIndex) & "",
                country = len(trim(agendaServiceQueryValue(arguments.eventQuery, "pais", rowIndex) & "")) ? agendaServiceQueryValue(arguments.eventQuery, "pais", rowIndex) & "" : "BR"
            },
            aggregator = {
                id = val(agendaServiceQueryValue(arguments.eventQuery, "id_agrega_evento", rowIndex)),
                name = agendaServiceQueryValue(arguments.eventQuery, "agregador_nome", rowIndex) & ""
            },
            distances = distances,
            imageUrl = imageUrl,
            results = {
                published = len(trim(agendaServiceQueryValue(arguments.eventQuery, "url_resultado", rowIndex) & "")) GT 0 OR val(agendaServiceQueryValue(arguments.eventQuery, "total_concluintes", rowIndex)) GT 0,
                url = agendaServiceQueryValue(arguments.eventQuery, "url_resultado", rowIndex) & "",
                finishers = val(agendaServiceQueryValue(arguments.eventQuery, "total_concluintes", rowIndex))
            }
        });
    }

    return result;
}

function agendaServiceTokenValid(required numeric agendaId, required string rawToken) output="false" {
    var tokenValue = trim(arguments.rawToken);
    var credentialQuery = "";

    if (!len(tokenValue)) {
        return false;
    }

    credentialQuery = queryExecute(
        "SELECT id_agenda_credencial FROM tb_agenda_credenciais WHERE id_agenda = :agendaId AND ativa = true AND token_hash = :tokenHash LIMIT 1",
        {
            agendaId = { value = int(arguments.agendaId), cfsqltype = "cf_sql_bigint" },
            tokenHash = { value = lCase(hash(tokenValue, "SHA-256")), cfsqltype = "cf_sql_char" }
        }
    );

    return credentialQuery.recordCount GT 0;
}

function agendaServiceRateLimitExceeded(
    required numeric agendaId,
    numeric maxRequests = 120,
    numeric windowSeconds = 60
) output="false" {
    var remoteAddress = agendaServiceClientIp();
    var rateQuery = "";

    if (!len(remoteAddress) || int(arguments.agendaId) LTE 0) {
        return false;
    }

    try {
        rateQuery = queryExecute(
            "SELECT count(*) AS total FROM tb_agenda_acessos WHERE id_agenda = :agendaId AND endereco_ip = :remoteAddress AND data_acesso >= now() - make_interval(secs => :windowSeconds)",
            {
                agendaId = { value = int(arguments.agendaId), cfsqltype = "cf_sql_bigint" },
                remoteAddress = { value = remoteAddress, cfsqltype = "cf_sql_varchar" },
                windowSeconds = { value = max(1, int(arguments.windowSeconds)), cfsqltype = "cf_sql_integer" }
            }
        );

        return rateQuery.recordCount AND val(rateQuery.total[1]) GTE max(1, int(arguments.maxRequests));
    } catch (any ignoredRateError) {
        return false;
    }
}

function agendaServiceLogAccess(
    numeric agendaId = 0,
    string formatName = "json",
    string viewName = "",
    numeric statusCode = 200,
    numeric eventCount = 0,
    numeric durationMs = 0
) output="false" {
    var source = agendaServiceRequestSource();
    var remoteAddress = agendaServiceClientIp();
    var userAgent = structKeyExists(CGI, "http_user_agent") ? left(CGI.http_user_agent & "", 512) : "";

    try {
        queryExecute(
            "INSERT INTO tb_agenda_acessos (id_agenda, formato, visao, dominio_requisitante, origem, referer, endereco_ip, user_agent, status_http, eventos_retornados, duracao_ms) " &
            "VALUES (:agendaId, :formatName, :viewName, :requestHost, :origin, :referer, :remoteAddress, :userAgent, :statusCode, :eventCount, :durationMs)",
            {
                agendaId = { value = int(arguments.agendaId), cfsqltype = "cf_sql_bigint", null = int(arguments.agendaId) LTE 0 },
                formatName = { value = left(trim(arguments.formatName), 16), cfsqltype = "cf_sql_varchar" },
                viewName = { value = left(trim(arguments.viewName), 16), cfsqltype = "cf_sql_varchar", null = !len(trim(arguments.viewName)) },
                requestHost = { value = left(source.host, 255), cfsqltype = "cf_sql_varchar", null = !len(source.host) },
                origin = { value = left(source.origin, 512), cfsqltype = "cf_sql_varchar", null = !len(source.origin) },
                referer = { value = left(source.referer, 1024), cfsqltype = "cf_sql_varchar", null = !len(source.referer) },
                remoteAddress = { value = remoteAddress, cfsqltype = "cf_sql_varchar", null = !len(remoteAddress) },
                userAgent = { value = userAgent, cfsqltype = "cf_sql_varchar", null = !len(userAgent) },
                statusCode = { value = int(arguments.statusCode), cfsqltype = "cf_sql_integer" },
                eventCount = { value = max(0, int(arguments.eventCount)), cfsqltype = "cf_sql_integer" },
                durationMs = { value = max(0, int(arguments.durationMs)), cfsqltype = "cf_sql_integer", null = int(arguments.durationMs) LTE 0 }
            }
        );
    } catch (any ignoredLogError) {
        // Access logging must never block agenda delivery.
    }
}
</cfscript>
