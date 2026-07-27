<cfscript>
function apiMonitorNewTrafficBucket(required string label, required string description) {
    return {
        label = arguments.label,
        description = arguments.description,
        total = 0,
        success = 0,
        redirects = 0,
        clientErrors = 0,
        serverErrors = 0,
        unauthorized = 0,
        forbidden = 0,
        notFound = 0,
        methodNotAllowed = 0,
        rateLimited = 0,
        durationTotalMs = 0,
        averageDurationMs = 0,
        p95DurationMs = 0,
        maxDurationMs = 0
    };
}

function apiMonitorEmptySnapshot(required numeric hours) {
    return {
        schemaVersion = 2,
        loaded = false,
        error = "",
        hours = arguments.hours,
        fetchedAt = now(),
        sourceFiles = [],
        bytesRead = 0,
        linesRead = 0,
        parsedLines = 0,
        ignoredLines = 0,
        truncated = false,
        oldestAt = "",
        newestAt = "",
        totals = {
            requests = 0,
            authenticated = 0,
            success = 0,
            redirects = 0,
            clientErrors = 0,
            serverErrors = 0,
            unauthorized = 0,
            forbidden = 0,
            notFound = 0,
            methodNotAllowed = 0,
            rateLimited = 0,
            uniqueClients = 0,
            uniqueIps = 0,
            averageDurationMs = 0,
            p95DurationMs = 0,
            peakRequestsPerMinute = 0
        },
        traffic = {
            authenticated = apiMonitorNewTrafficBucket(
                "Clientes autenticados",
                "Chamadas com token valido, incluindo respostas sem o escopo exigido."
            ),
            publicSurface = apiMonitorNewTrafficBucket(
                "Documentacao publica",
                "Landing, contrato OpenAPI, health check e JavaScript do playground."
            ),
            rejected = apiMonitorNewTrafficBucket(
                "Rejeicoes protegidas",
                "Chamadas a rotas da API sem credencial valida ou sem permissao."
            ),
            probe = apiMonitorNewTrafficBucket(
                "Probes e ruido",
                "Rotas fora do contrato, scanners e requisicoes malformadas."
            )
        },
        clients = [],
        routes = [],
        authenticatedRoutes = [],
        probeRoutes = [],
        statuses = [],
        timeline = [],
        abuseSignals = [],
        recentErrors = []
    };
}

function apiMonitorSafeLogValue(any rawValue = "") {
    var value = trim(arguments.rawValue & "");

    return value EQ "-" ? "" : value;
}

function apiMonitorIsPublicSurface(
    required string method,
    required string route,
    required numeric statusCode
) {
    var publicRoutes = "/,/index.cfm,/openapi.json,/health.cfm,/assets/playground.js";

    return listFindNoCase("GET,HEAD", arguments.method)
        AND arguments.statusCode GTE 200
        AND arguments.statusCode LT 400
        AND listFindNoCase(publicRoutes, arguments.route);
}

function apiMonitorIsApiRoute(required string route) {
    return reFindNoCase(
        "^/v1/(athletes|events|results|discovery|editorial|feed|challenges|training|coupons|session|me)/[a-z0-9-]+\.cfm$",
        arguments.route
    ) GT 0;
}

function apiMonitorClassifyTraffic(
    required string method,
    required string route,
    required numeric statusCode,
    required string clientId
) {
    if (arguments.clientId NEQ "nao-autenticado") {
        return "authenticated";
    }

    if (apiMonitorIsPublicSurface(arguments.method, arguments.route, arguments.statusCode)) {
        return "publicSurface";
    }

    if (apiMonitorIsApiRoute(arguments.route)) {
        return "rejected";
    }

    return "probe";
}

function apiMonitorReadTail(required string filePath, required numeric maxBytes) {
    var result = {
        lines = [],
        bytesRead = 0,
        truncated = false
    };
    var randomFile = "";
    var fileLength = 0;
    var startAt = 0;
    var line = "";

    randomFile = createObject("java", "java.io.RandomAccessFile").init(arguments.filePath, "r");

    try {
        fileLength = randomFile.length();
        startAt = max(0, fileLength - arguments.maxBytes);
        result.bytesRead = fileLength - startAt;
        result.truncated = startAt GT 0;

        randomFile.seek(startAt);

        if (startAt GT 0 AND randomFile.getFilePointer() LT fileLength) {
            randomFile.readLine();
        }

        while (randomFile.getFilePointer() LT fileLength) {
            line = randomFile.readLine();

            if (!isNull(line) AND len(line)) {
                arrayAppend(result.lines, line);
            }
        }
    } finally {
        randomFile.close();
    }

    return result;
}

function apiMonitorReadFiles(required string logPath, required numeric maxBytes) {
    var result = {
        lines = [],
        files = [],
        bytesRead = 0,
        truncated = false
    };
    var paths = [];
    var pathValue = "";
    var bytesPerFile = arguments.maxBytes;
    var tailResult = {};

    if (fileExists(arguments.logPath & ".1")) {
        arrayAppend(paths, arguments.logPath & ".1");
    }

    if (fileExists(arguments.logPath)) {
        arrayAppend(paths, arguments.logPath);
    }

    if (!arrayLen(paths)) {
        throw(
            type = "ApiMonitor.LogNotFound",
            message = "O arquivo de telemetria da API ainda nao existe ou nao esta acessivel."
        );
    }

    bytesPerFile = max(524288, int(arguments.maxBytes / arrayLen(paths)));

    for (pathValue in paths) {
        tailResult = apiMonitorReadTail(pathValue, bytesPerFile);
        result.bytesRead += tailResult.bytesRead;
        result.truncated = result.truncated OR tailResult.truncated;
        arrayAppend(result.files, pathValue);

        if (arrayLen(tailResult.lines)) {
            arrayAppend(result.lines, tailResult.lines, true);
        }
    }

    return result;
}

function apiMonitorBucket(required struct collection, required string keyValue, required string label) {
    if (!structKeyExists(arguments.collection, arguments.keyValue)) {
        arguments.collection[arguments.keyValue] = {
            key = arguments.keyValue,
            label = arguments.label,
            total = 0,
            success = 0,
            redirects = 0,
            clientErrors = 0,
            serverErrors = 0,
            unauthorized = 0,
            forbidden = 0,
            notFound = 0,
            methodNotAllowed = 0,
            rateLimited = 0,
            durationTotalMs = 0,
            averageDurationMs = 0,
            maxDurationMs = 0,
            authenticated = 0,
            publicSurface = 0,
            rejected = 0,
            probe = 0,
            score = 0
        };
    }

    return arguments.collection[arguments.keyValue];
}

function apiMonitorUpdateBucket(
    required struct bucket,
    required numeric statusCode,
    required numeric durationMs,
    string classification = ""
) {
    arguments.bucket.total += 1;
    arguments.bucket.durationTotalMs += arguments.durationMs;
    arguments.bucket.maxDurationMs = max(arguments.bucket.maxDurationMs, arguments.durationMs);

    if (arguments.statusCode GTE 200 AND arguments.statusCode LT 300) {
        arguments.bucket.success += 1;
    } else if (arguments.statusCode GTE 300 AND arguments.statusCode LT 400) {
        arguments.bucket.redirects += 1;
    } else if (arguments.statusCode GTE 400 AND arguments.statusCode LT 500) {
        arguments.bucket.clientErrors += 1;
    } else if (arguments.statusCode GTE 500) {
        arguments.bucket.serverErrors += 1;
    }

    if (arguments.statusCode EQ 401) {
        arguments.bucket.unauthorized += 1;
    } else if (arguments.statusCode EQ 403) {
        arguments.bucket.forbidden += 1;
    } else if (arguments.statusCode EQ 404) {
        arguments.bucket.notFound += 1;
    } else if (arguments.statusCode EQ 405) {
        arguments.bucket.methodNotAllowed += 1;
    } else if (arguments.statusCode EQ 429) {
        arguments.bucket.rateLimited += 1;
    }

    if (
        len(arguments.classification)
        AND structKeyExists(arguments.bucket, arguments.classification)
    ) {
        arguments.bucket[arguments.classification] += 1;
    }
}

function apiMonitorTopBuckets(required struct collection, numeric maxItems = 12, string sortField = "total") {
    var items = [];
    var result = [];
    var keyValue = "";
    var item = {};
    var index = 0;
    var requestedSortField = arguments.sortField;

    for (keyValue in arguments.collection) {
        item = duplicate(arguments.collection[keyValue]);
        item.averageDurationMs = item.total GT 0 ? item.durationTotalMs / item.total : 0;
        arrayAppend(items, item);
    }

    arraySort(items, function(firstItem, secondItem) {
        var firstValue = structKeyExists(firstItem, requestedSortField) ? val(firstItem[requestedSortField]) : 0;
        var secondValue = structKeyExists(secondItem, requestedSortField) ? val(secondItem[requestedSortField]) : 0;

        if (firstValue EQ secondValue) {
            return compareNoCase(firstItem.label, secondItem.label);
        }

        return firstValue LT secondValue ? 1 : -1;
    });

    for (index = 1; index LTE min(arguments.maxItems, arrayLen(items)); index += 1) {
        arrayAppend(result, items[index]);
    }

    return result;
}

function apiMonitorLoadSnapshot(
    required string logPath,
    required numeric hours,
    required numeric maxBytes
) {
    var snapshot = apiMonitorEmptySnapshot(arguments.hours);
    var readResult = {};
    var currentEpoch = int(createObject("java", "java.lang.System").currentTimeMillis() / 1000);
    var cutoffEpoch = currentEpoch - (arguments.hours * 3600);
    var clientBuckets = {};
    var routeBuckets = {};
    var authenticatedRouteBuckets = {};
    var probeRouteBuckets = {};
    var statusBuckets = {};
    var ipBuckets = {};
    var hourBuckets = {};
    var minuteBuckets = {};
    var uniqueClients = {};
    var uniqueIps = {};
    var durations = [];
    var authenticatedDurations = [];
    var lineValue = "";
    var fields = [];
    var eventEpoch = 0;
    var eventDate = "";
    var method = "";
    var route = "";
    var routeKey = "";
    var statusCode = 0;
    var responseBytes = 0;
    var durationMs = 0;
    var requestId = "";
    var clientId = "";
    var errorCode = "";
    var sourceIp = "";
    var ipHash = "";
    var hourKey = "";
    var minuteKey = "";
    var bucket = {};
    var statusKey = "";
    var recentItem = {};
    var classification = "";
    var trafficKey = "";
    var index = 0;

    try {
        readResult = apiMonitorReadFiles(arguments.logPath, arguments.maxBytes);
        snapshot.sourceFiles = readResult.files;
        snapshot.bytesRead = readResult.bytesRead;
        snapshot.linesRead = arrayLen(readResult.lines);
        snapshot.truncated = readResult.truncated;

        for (lineValue in readResult.lines) {
            fields = listToArray(lineValue, chr(9), true);

            if (arrayLen(fields) LT 15 OR !isNumeric(fields[1])) {
                snapshot.ignoredLines += 1;
                continue;
            }

            eventEpoch = val(fields[1]);

            if (eventEpoch LT cutoffEpoch OR eventEpoch GT currentEpoch + 300) {
                continue;
            }

            method = uCase(apiMonitorSafeLogValue(fields[5]));
            route = apiMonitorSafeLogValue(fields[6]);
            routeKey = method & " " & route;
            statusCode = val(fields[7]);
            responseBytes = val(fields[8]);
            durationMs = val(fields[9]) / 1000;
            requestId = apiMonitorSafeLogValue(fields[10]);
            clientId = apiMonitorSafeLogValue(fields[11]);
            errorCode = apiMonitorSafeLogValue(fields[12]);
            sourceIp = apiMonitorSafeLogValue(fields[3]);

            if (!len(sourceIp)) {
                sourceIp = apiMonitorSafeLogValue(fields[4]);
            }

            if (!len(sourceIp)) {
                sourceIp = apiMonitorSafeLogValue(fields[2]);
            }

            if (!len(route) OR statusCode LTE 0) {
                snapshot.ignoredLines += 1;
                continue;
            }

            if (!len(clientId)) {
                clientId = "nao-autenticado";
            }

            ipHash = len(sourceIp) ? left(lCase(hash(sourceIp, "SHA-256")), 12) : "desconhecido";
            eventDate = createObject("java", "java.util.Date").init(javacast("long", eventEpoch * 1000));
            hourKey = dateFormat(eventDate, "yyyy-mm-dd") & " " & timeFormat(eventDate, "HH:00");
            minuteKey = dateFormat(eventDate, "yyyy-mm-dd") & " " & timeFormat(eventDate, "HH:nn");
            statusKey = statusCode & "";
            classification = apiMonitorClassifyTraffic(method, route, statusCode, clientId);

            snapshot.parsedLines += 1;
            snapshot.totals.requests += 1;
            snapshot.totals.authenticated += clientId NEQ "nao-autenticado" ? 1 : 0;

            if (statusCode GTE 200 AND statusCode LT 300) {
                snapshot.totals.success += 1;
            } else if (statusCode GTE 300 AND statusCode LT 400) {
                snapshot.totals.redirects += 1;
            } else if (statusCode GTE 400 AND statusCode LT 500) {
                snapshot.totals.clientErrors += 1;
            } else if (statusCode GTE 500) {
                snapshot.totals.serverErrors += 1;
            }

            if (statusCode EQ 401) {
                snapshot.totals.unauthorized += 1;
            } else if (statusCode EQ 403) {
                snapshot.totals.forbidden += 1;
            } else if (statusCode EQ 404) {
                snapshot.totals.notFound += 1;
            } else if (statusCode EQ 405) {
                snapshot.totals.methodNotAllowed += 1;
            } else if (statusCode EQ 429) {
                snapshot.totals.rateLimited += 1;
            }

            arrayAppend(durations, durationMs);
            apiMonitorUpdateBucket(snapshot.traffic[classification], statusCode, durationMs);

            if (clientId NEQ "nao-autenticado") {
                uniqueClients[clientId] = true;
                arrayAppend(authenticatedDurations, durationMs);

                bucket = apiMonitorBucket(clientBuckets, clientId, clientId);
                apiMonitorUpdateBucket(bucket, statusCode, durationMs, classification);

                bucket = apiMonitorBucket(authenticatedRouteBuckets, routeKey, routeKey);
                apiMonitorUpdateBucket(bucket, statusCode, durationMs, classification);
            }
            uniqueIps[ipHash] = true;

            bucket = apiMonitorBucket(routeBuckets, routeKey, routeKey);
            apiMonitorUpdateBucket(bucket, statusCode, durationMs, classification);

            if (classification EQ "probe") {
                bucket = apiMonitorBucket(probeRouteBuckets, routeKey, routeKey);
                apiMonitorUpdateBucket(bucket, statusCode, durationMs, classification);
            }

            bucket = apiMonitorBucket(statusBuckets, statusKey, statusKey);
            apiMonitorUpdateBucket(bucket, statusCode, durationMs, classification);

            bucket = apiMonitorBucket(ipBuckets, ipHash, ipHash);
            apiMonitorUpdateBucket(bucket, statusCode, durationMs, classification);
            bucket.score = (bucket.unauthorized * 4)
                + (bucket.forbidden * 2)
                + bucket.notFound
                + (bucket.methodNotAllowed * 2)
                + (bucket.rateLimited * 8);

            if (!structKeyExists(hourBuckets, hourKey)) {
                hourBuckets[hourKey] = {
                    key = hourKey,
                    label = dateFormat(eventDate, "dd/mm") & " " & timeFormat(eventDate, "HH:00"),
                    total = 0,
                    success = 0,
                    errors = 0,
                    rateLimited = 0,
                    authenticated = 0,
                    publicSurface = 0,
                    rejected = 0,
                    probe = 0
                };
            }

            hourBuckets[hourKey].total += 1;
            hourBuckets[hourKey].success += statusCode GTE 200 AND statusCode LT 400 ? 1 : 0;
            hourBuckets[hourKey].errors += statusCode GTE 400 ? 1 : 0;
            hourBuckets[hourKey].rateLimited += statusCode EQ 429 ? 1 : 0;
            hourBuckets[hourKey][classification] += 1;

            if (!structKeyExists(minuteBuckets, minuteKey)) {
                minuteBuckets[minuteKey] = 0;
            }
            minuteBuckets[minuteKey] += 1;

            if (statusCode GTE 400) {
                recentItem = {
                    eventAt = eventDate,
                    statusCode = statusCode,
                    method = method,
                    route = route,
                    clientId = clientId,
                    errorCode = errorCode,
                    durationMs = durationMs,
                    responseBytes = responseBytes,
                    ipHash = ipHash,
                    requestId = requestId,
                    classification = classification
                };
                arrayAppend(snapshot.recentErrors, recentItem);

                if (arrayLen(snapshot.recentErrors) GT 40) {
                    arrayDeleteAt(snapshot.recentErrors, 1);
                }
            }

            if (!isDate(snapshot.oldestAt) OR eventDate LT snapshot.oldestAt) {
                snapshot.oldestAt = eventDate;
            }
            if (!isDate(snapshot.newestAt) OR eventDate GT snapshot.newestAt) {
                snapshot.newestAt = eventDate;
            }
        }

        snapshot.totals.uniqueClients = structCount(uniqueClients);
        snapshot.totals.uniqueIps = structCount(uniqueIps);

        if (arrayLen(durations)) {
            snapshot.totals.averageDurationMs = arraySum(durations) / arrayLen(durations);
            arraySort(durations, "numeric", "asc");
            snapshot.totals.p95DurationMs = durations[max(1, ceiling(arrayLen(durations) * 0.95))];
        }

        for (trafficKey in snapshot.traffic) {
            snapshot.traffic[trafficKey].averageDurationMs = snapshot.traffic[trafficKey].total GT 0
                ? snapshot.traffic[trafficKey].durationTotalMs / snapshot.traffic[trafficKey].total
                : 0;
        }

        if (arrayLen(authenticatedDurations)) {
            arraySort(authenticatedDurations, "numeric", "asc");
            snapshot.traffic.authenticated.p95DurationMs =
                authenticatedDurations[max(1, ceiling(arrayLen(authenticatedDurations) * 0.95))];
        } else {
            snapshot.traffic.authenticated.p95DurationMs = 0;
        }

        for (minuteKey in minuteBuckets) {
            snapshot.totals.peakRequestsPerMinute = max(
                snapshot.totals.peakRequestsPerMinute,
                minuteBuckets[minuteKey]
            );
        }

        snapshot.clients = apiMonitorTopBuckets(clientBuckets, 12, "total");
        snapshot.routes = apiMonitorTopBuckets(routeBuckets, 15, "total");
        snapshot.authenticatedRoutes = apiMonitorTopBuckets(authenticatedRouteBuckets, 12, "total");
        snapshot.probeRoutes = apiMonitorTopBuckets(probeRouteBuckets, 12, "total");
        snapshot.statuses = apiMonitorTopBuckets(statusBuckets, 12, "total");
        snapshot.abuseSignals = apiMonitorTopBuckets(ipBuckets, 15, "score");

        for (index = arrayLen(snapshot.abuseSignals); index GTE 1; index -= 1) {
            if (
                snapshot.abuseSignals[index].score LT 20
                AND snapshot.abuseSignals[index].rateLimited EQ 0
                AND snapshot.abuseSignals[index].total LT 200
            ) {
                arrayDeleteAt(snapshot.abuseSignals, index);
            }
        }

        for (hourKey in hourBuckets) {
            arrayAppend(snapshot.timeline, hourBuckets[hourKey]);
        }

        arraySort(snapshot.timeline, function(firstItem, secondItem) {
            return compare(firstItem.key, secondItem.key);
        });

        snapshot.loaded = true;
    } catch (any exception) {
        snapshot.error = exception.message;
    }

    return snapshot;
}
</cfscript>
