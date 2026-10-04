<!--- VARIAVEIS DA APLICACAO --->

<cfset VARIABLES.queryString = ""/>
<cfset VARIABLES.queryString = replace(VARIABLES.queryString, "&", "?")/>
<cfset VARIABLES.pageSize = 50/>
<cfset VARIABLES.agrupamento = "default"/>
<cfset VARIABLES.devMode = false/>
<cfset VARIABLES.codPagina = ""/>
<cfset VARIABLES.loginAutoPrompt = "true"/>
<cfset VARIABLES.chave_pagarme = tobase64('sk_2501474de4d64171be553a65cec7372b:')/>
<cfset VARIABLES.cidade = ""/>
<cfset VARIABLES.estado = ""/>
<cfset VARIABLES.uf = ""/>
<cfset VARIABLES.pais = ""/>

<!--- URL PARAMS --->

<cfparam name="URL.distancia" default="1,42"/>
<cfparam name="URL.tempo" default="0,12"/>
<cfparam name="URL.filtro" default=""/>
<cfparam name="URL.badges" default=""/>
<cfparam name="URL.rua" default="true"/>
<cfparam name="URL.trail" default="true"/>
<cfparam name="URL.nacional" default="true"/>
<cfparam name="URL.internacional" default="false"/>
<cfparam name="URL.cupom" default="false"/>

<!--- DEV --->
<cfif CGI.HTTP_HOST CONTAINS 'dev.'>
    <cfset VARIABLES.devMode = true/>
</cfif>

<cfscript>
if (!structKeyExists(REQUEST, "queryDebug") || !isArray(REQUEST.queryDebug)) {
    REQUEST.queryDebug = [];
}

if (!structKeyExists(REQUEST, "formatDisplayPersonName")) {
    REQUEST.formatDisplayPersonName = function(required string fullName) {
        var loweredWords = "a,à,ao,aos,as,às,o,os,da,das,de,do,dos,e,em,na,nas,no,nos,ou,por,del,el,la,las,los,y,and,of,the";
        var normalizedName = trim(reReplace(arguments.fullName, "\s+", " ", "all"));
        var parts = [];
        var formattedParts = [];
        var currentPart = "";

        if (!len(normalizedName)) {
            return "";
        }

        parts = listToArray(normalizedName, " ");

        for (currentPart in parts) {
            currentPart = lCase(trim(currentPart));

            if (!len(currentPart)) {
                continue;
            }

            if (listFindNoCase(loweredWords, currentPart)) {
                arrayAppend(formattedParts, currentPart);
            } else if (reFindNoCase("^d['’].+", currentPart)) {
                arrayAppend(formattedParts, left(currentPart, 2) & uCase(mid(currentPart, 3, 1)) & mid(currentPart, 4, len(currentPart)));
            } else {
                arrayAppend(formattedParts, uCase(left(currentPart, 1)) & mid(currentPart, 2, len(currentPart)));
            }
        }

        return arrayToList(formattedParts, " ");
    };
}

if (!structKeyExists(REQUEST, "formatDisplayTitle")) {
    REQUEST.formatDisplayTitle = REQUEST.formatDisplayPersonName;
}

if (!structKeyExists(REQUEST, "formatDisplayCity")) {
    REQUEST.formatDisplayCity = REQUEST.formatDisplayPersonName;
}

if (!structKeyExists(REQUEST, "normalizeDisplayQuery")) {
    REQUEST.normalizeDisplayQuery = function(required any sourceQuery, string personColumns = "", string cityColumns = "") {
        var rowIndex = 0;
        var columnName = "";
        var availableColumns = "";

        if (!isQuery(arguments.sourceQuery)) {
            return arguments.sourceQuery;
        }

        availableColumns = arguments.sourceQuery.columnList;
        for (columnName in listToArray(listAppend(arguments.personColumns, arguments.cityColumns))) {
            columnName = trim(columnName);
            if (!len(columnName) || !listFindNoCase(availableColumns, columnName)) {
                continue;
            }
            for (rowIndex = 1; rowIndex <= arguments.sourceQuery.recordCount; rowIndex += 1) {
                querySetCell(arguments.sourceQuery, columnName, REQUEST.formatDisplayTitle(arguments.sourceQuery[columnName][rowIndex] & ""), rowIndex);
            }
        }
        return arguments.sourceQuery;
    };
}

function logQueryDebug(required string queryName, any queryMeta = {}, string context = "", string cacheTtl = "", any queryData = "") {
    var meta = isStruct(arguments.queryMeta) ? duplicate(arguments.queryMeta) : {};
    var cacheValue = "";
    var timeValue = 0;
    var rowValue = "";
    var normalizedEntry = {};

    if (structKeyExists(meta, "cached")) {
        cacheValue = meta.cached;
    } else if (structKeyExists(meta, "Cached")) {
        cacheValue = meta.Cached;
    } else if (structKeyExists(meta, "fromCache")) {
        cacheValue = meta.fromCache;
    }

    if (structKeyExists(meta, "executionTime")) {
        timeValue = meta.executionTime;
    } else if (structKeyExists(meta, "ExecutionTime")) {
        timeValue = meta.ExecutionTime;
    } else if (structKeyExists(meta, "executionTimeMs")) {
        timeValue = meta.executionTimeMs;
    }

    if (!isNumeric(timeValue)) {
        timeValue = 0;
    }

    if (isQuery(arguments.queryData)) {
        rowValue = arguments.queryData.recordCount;
    } else if (structKeyExists(meta, "recordCount")) {
        rowValue = meta.recordCount;
    } else if (structKeyExists(meta, "RecordCount")) {
        rowValue = meta.RecordCount;
    }

    normalizedEntry = {
        query = arguments.queryName,
        context = arguments.context,
        cache = cacheValue,
        cacheTtl = arguments.cacheTtl,
        timeMs = val(timeValue),
        rows = rowValue
    };

    arrayAppend(REQUEST.queryDebug, normalizedEntry);
    return normalizedEntry;
}
</cfscript>
