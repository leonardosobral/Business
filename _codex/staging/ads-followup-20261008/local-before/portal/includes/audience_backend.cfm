<!--- Never expose global audience through an unprotected include request. --->
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfscript>
function audienceInput(required string key, string fallback = "") {
    return structKeyExists(URL, arguments.key) AND isSimpleValue(URL[arguments.key])
        ? trim(URL[arguments.key] & "") : arguments.fallback;
}
function audienceCount(value) { return numberFormat(val(arguments.value), "__,___,___,___"); }
function audienceLabel(required string value) {
    var labels = {"home":"Home", "state":"Estado", "search":"Busca", "event":"Evento",
        "profile":"Perfil", "news":"Notícias — lista", "news_detail":"Notícia — detalhe",
        "videos":"Vídeos — lista", "video_detail":"Vídeo — detalhe", "results":"Resultados",
        "calendar":"Agenda", "circuit":"Circuito", "other":"Outras páginas", "MOBILE":"Mobile", "TABLET":"Tablet", "DESKTOP":"Desktop", "UNKNOWN":"Desconhecido"};
    return structKeyExists(labels, arguments.value) ? labels[arguments.value] : arguments.value;
}
function audienceDate(value) {
    return isDate(arguments.value) ? dateTimeFormat(arguments.value, "dd/mm HH:nn", "America/Sao_Paulo") : "—";
}
function audienceRate(numerator, denominator) {
    return val(arguments.denominator) GT 0 ? numberFormat(100 * val(arguments.numerator) / val(arguments.denominator),"0.0") & "%" : "—";
}
// Global and regional views share the same inventory model and validation rules.
function audienceOccupancyStatement(required string name) {
    var statement = fileRead(VARIABLES.audienceQueryDirectory & arguments.name & ".sql","UTF-8");
    return replace(statement,"/* AUDIENCE_OCCUPANCY_BASE */",fileRead(VARIABLES.audienceQueryDirectory & "occupancy_base.sql","UTF-8"));
}
function audienceValidateOccupancy(required query result, boolean regional=false) {
    var columns = ["format","registered","potential","filled","empty","unclassified"];
    if (arguments.regional) arrayAppend(columns,"audience_uf");
    for (var column in columns) {
        if (!listFindNoCase(arguments.result.columnList,column)) throw(type="AudienceOccupancyContract",message="Invalid occupancy result");
    }
    if (!arguments.regional AND arguments.result.recordcount NEQ 4) throw(type="AudienceOccupancyContract",message="Invalid occupancy result");
    var groups = {};
    for (var index=1;index LTE arguments.result.recordcount;index++) {
        var row = queryGetRow(arguments.result,index);
        var groupKey = arguments.regional ? row.audience_uf : "all";
        if (arguments.regional AND !listFind(VARIABLES.audienceUfList,groupKey)) throw(type="AudienceOccupancyContract",message="Invalid occupancy region");
        if (!structKeyExists(groups,groupKey)) groups[groupKey] = {};
        if (!listFind("all,ads,banners,other",row.format) OR structKeyExists(groups[groupKey],row.format)) throw(type="AudienceOccupancyContract",message="Invalid occupancy format");
        for (var metric in ["registered","potential","filled","empty","unclassified"]) {
            if (!structKeyExists(row,metric) OR !isNumeric(row[metric]) OR row[metric] LT 0 OR fix(row[metric]) NEQ row[metric]) throw(type="AudienceOccupancyContract",message="Invalid occupancy count");
        }
        if (row.potential GT row.registered OR row.potential NEQ row.filled + row.empty + row.unclassified) throw(type="AudienceOccupancyContract",message="Invalid occupancy reconciliation");
        groups[groupKey][row.format] = row;
    }
    for (var groupKey in groups) {
        var formats = groups[groupKey];
        if (structCount(formats) NEQ 4) throw(type="AudienceOccupancyContract",message="Incomplete occupancy formats");
        for (var metric in ["registered","potential","filled","empty","unclassified"]) {
            if (formats.all[metric] NEQ formats.ads[metric] + formats.banners[metric] + formats.other[metric]) throw(type="AudienceOccupancyContract",message="Invalid occupancy format totals");
        }
    }
}
function audienceValidateCoveragePaths(required query result) {
    for (var column in ["page_folder","pageviews","pages_with_slots","opportunities","slot_views","last_received"]) {
        if (!listFindNoCase(arguments.result.columnList,column)) throw(type="AudienceCoveragePathsContract",message="Invalid path result");
    }
    var paths = {};
    for (var row in arguments.result) {
        // Struct keys are case-insensitive in CFML; paths in the source are not.
        var pathKey = hash(row.page_folder,"SHA-256");
        if (len(row.page_folder) GT 257 OR (len(row.page_folder) AND !reFind("^/[a-zA-Z0-9_-]+/$",row.page_folder)) OR structKeyExists(paths,pathKey)) throw(type="AudienceCoveragePathsContract",message="Invalid path group");
        paths[pathKey] = true;
        for (var metric in ["pageviews","pages_with_slots","opportunities","slot_views"]) {
            if (!structKeyExists(row,metric) OR !isNumeric(row[metric]) OR row[metric] LT 0 OR fix(row[metric]) NEQ row[metric]) throw(type="AudienceCoveragePathsContract",message="Invalid path count");
        }
    }
}
VARIABLES.audienceDays = listFind("7,30,90", audienceInput("dias", "7")) ? int(audienceInput("dias", "7")) : 7;
VARIABLES.audienceEnvironment = lCase(audienceInput("ambiente", "prod"));
if (!listFind("prod,beta,dev", VARIABLES.audienceEnvironment)) VARIABLES.audienceEnvironment = "prod";
VARIABLES.audienceDimension = lCase(audienceInput("regiao", "market"));
if (!listFind("market,visitor,profile,context", VARIABLES.audienceDimension)) VARIABLES.audienceDimension = "market";
VARIABLES.audienceUf = uCase(audienceInput("uf"));
VARIABLES.audienceUfList = "AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO,--";
if (!listFind(VARIABLES.audienceUfList, VARIABLES.audienceUf)) VARIABLES.audienceUf = "";
VARIABLES.audienceFamily = lCase(audienceInput("pagina"));
VARIABLES.audienceFamilies = "home,state,search,event,profile,news,news_detail,videos,video_detail,results,calendar,circuit,other";
if (!listFind(VARIABLES.audienceFamilies, VARIABLES.audienceFamily)) VARIABLES.audienceFamily = "";
VARIABLES.audienceDevice = uCase(audienceInput("dispositivo"));
if (!listFind("MOBILE,TABLET,DESKTOP,UNKNOWN", VARIABLES.audienceDevice)) VARIABLES.audienceDevice = "";
VARIABLES.audienceIncludeInternal = audienceInput("internos") EQ "1";
VARIABLES.audienceReady = false;
VARIABLES.audienceUnavailable = false;
VARIABLES.audienceRetention = {state="not_installed", lastSuccess="", hasMore=false};
VARIABLES.audienceQueries = {};
VARIABLES.audienceCapacityStatus = "not_commercial";
VARIABLES.audienceOccupancyStatus = "unavailable";
VARIABLES.audienceOccupancyQuery = queryNew("format,registered,potential,filled,empty,unclassified");
VARIABLES.audienceRegionOccupancyStatus = "unavailable";
VARIABLES.audienceRegionOccupancyQuery = queryNew("audience_uf,format,registered,potential,filled,empty,unclassified");
VARIABLES.audienceCoveragePathsStatus = "unavailable";
VARIABLES.audienceCoveragePathsQuery = queryNew("page_folder,pageviews,pages_with_slots,opportunities,slot_views,last_received");
VARIABLES.audienceLiveSource = left(audienceInput("live_origem"),100);
VARIABLES.audienceLiveCampaign = left(audienceInput("live_campanha"),100);
VARIABLES.audienceLiveCity = left(audienceInput("live_cidade"),100);
VARIABLES.audienceLiveEvent = audienceInput("live_prova");
if (!reFind("^[1-9][0-9]{0,9}$",VARIABLES.audienceLiveEvent)) VARIABLES.audienceLiveEvent = "";
VARIABLES.audienceLiveUnavailable = false;
VARIABLES.audienceParams = {
    "days" = {value=VARIABLES.audienceDays, cfsqltype="cf_sql_integer"},
    "environment" = {value=VARIABLES.audienceEnvironment, cfsqltype="cf_sql_varchar"},
    "include_internal" = {value=VARIABLES.audienceIncludeInternal, cfsqltype="cf_sql_bit"},
    "region_dimension" = {value=VARIABLES.audienceDimension, cfsqltype="cf_sql_varchar"},
    "uf" = {value=VARIABLES.audienceUf, cfsqltype="cf_sql_varchar"},
    "page_family" = {value=VARIABLES.audienceFamily, cfsqltype="cf_sql_varchar"},
    "device_class" = {value=VARIABLES.audienceDevice, cfsqltype="cf_sql_varchar"}
};
try {
    VARIABLES.audienceSchema = queryExecute("SELECT to_regclass('audience.events') IS NOT NULL AS ready, to_regclass('audience.maintenance_state') IS NOT NULL AS retention_ready", {}, {datasource="runnerhub", timeout=10});
    VARIABLES.audienceReady = VARIABLES.audienceSchema.ready[1];
    if (VARIABLES.audienceReady) {
        VARIABLES.audienceQueryDirectory = getDirectoryFromPath(getCurrentTemplatePath()) & "../audiencia/queries/";
        VARIABLES.audienceFilterSql = fileRead(VARIABLES.audienceQueryDirectory & "filter.sql", "UTF-8");
        for (VARIABLES.audienceQueryName in ["summary","inventory","regions","content","acquisition","daily","coverage"]) {
            VARIABLES.audienceSql = replace(fileRead(VARIABLES.audienceQueryDirectory & VARIABLES.audienceQueryName & ".sql", "UTF-8"), "/* AUDIENCE_FILTER */", VARIABLES.audienceFilterSql);
            VARIABLES.audienceQueries[VARIABLES.audienceQueryName] = queryExecute(VARIABLES.audienceSql, VARIABLES.audienceParams, {datasource="runnerhub", timeout=15, cachedwithin=createTimeSpan(0,0,1,0)});
        }
        VARIABLES.audienceSummary = {first_event="", last_received=""};
        structAppend(VARIABLES.audienceSummary, queryGetRow(VARIABLES.audienceQueries.summary, 1), true);
        // Observed occupancy supports diagnostic filters and fails independently of existing reports.
        try {
            VARIABLES.audienceOccupancySql = audienceOccupancyStatement("occupancy");
            VARIABLES.audienceOccupancyResult = queryExecute(VARIABLES.audienceOccupancySql,VARIABLES.audienceParams,{datasource="runnerhub",timeout=15,cachedwithin=createTimeSpan(0,0,1,0)});
            audienceValidateOccupancy(VARIABLES.audienceOccupancyResult);
            VARIABLES.audienceOccupancyQuery = VARIABLES.audienceOccupancyResult;
            VARIABLES.audienceOccupancyStatus = "ready";
        } catch(any audienceOccupancyReadError) {
            writeLog(file="audience_measurement",type="error",text="Business audience occupancy unavailable: " & left(audienceOccupancyReadError.type & "",100));
        }
        // Detail failures never zero or hide the already available headline and reports.
        try {
            VARIABLES.audienceRegionOccupancySql = audienceOccupancyStatement("occupancy_regions");
            VARIABLES.audienceRegionOccupancyResult = queryExecute(VARIABLES.audienceRegionOccupancySql,VARIABLES.audienceParams,{datasource="runnerhub",timeout=15,cachedwithin=createTimeSpan(0,0,1,0)});
            audienceValidateOccupancy(VARIABLES.audienceRegionOccupancyResult,true);
            VARIABLES.audienceRegionOccupancyQuery = VARIABLES.audienceRegionOccupancyResult;
            VARIABLES.audienceRegionOccupancyStatus = "ready";
        } catch(any audienceRegionOccupancyReadError) {
            writeLog(file="audience_measurement",type="error",text="Business regional occupancy unavailable: " & left(audienceRegionOccupancyReadError.type & "",100));
        }
        try {
            VARIABLES.audienceCoveragePathsSql = replace(fileRead(VARIABLES.audienceQueryDirectory & "coverage_paths.sql","UTF-8"),"/* AUDIENCE_FILTER */",VARIABLES.audienceFilterSql);
            VARIABLES.audienceCoveragePathsResult = queryExecute(VARIABLES.audienceCoveragePathsSql,VARIABLES.audienceParams,{datasource="runnerhub",timeout=15,cachedwithin=createTimeSpan(0,0,1,0)});
            audienceValidateCoveragePaths(VARIABLES.audienceCoveragePathsResult);
            VARIABLES.audienceCoveragePathsQuery = VARIABLES.audienceCoveragePathsResult;
            VARIABLES.audienceCoveragePathsStatus = "ready";
        } catch(any audienceCoveragePathsReadError) {
            writeLog(file="audience_measurement",type="error",text="Business coverage paths unavailable: " & left(audienceCoveragePathsReadError.type & "",100));
        }
        // Optional read: a missing template or query failure cannot hide the existing counters.
        // Commercial scenarios never use internal tests, nonproduction or origin-UF filters.
        if (VARIABLES.audienceDimension EQ "market" AND VARIABLES.audienceEnvironment EQ "prod" AND NOT VARIABLES.audienceIncludeInternal) {
            try {
                VARIABLES.audienceCapacitySql = fileRead(VARIABLES.audienceQueryDirectory & "capacity.sql","UTF-8");
                VARIABLES.audienceCapacityQuery = queryExecute(VARIABLES.audienceCapacitySql,VARIABLES.audienceParams,{datasource="runnerhub",timeout=15,cachedwithin=createTimeSpan(0,0,1,0)});
                VARIABLES.audienceCapacityStatus = "ready";
            } catch(any audienceCapacityReadError) {
                VARIABLES.audienceCapacityStatus = "unavailable";
                writeLog(file="audience_measurement",type="error",text="Business audience capacity unavailable: " & left(audienceCapacityReadError.type & "",100));
            }
        }
        // Catalog lookup and the new report are optional: failure cannot hide existing audience data.
        try {
            VARIABLES.audienceLiveParams = duplicate(VARIABLES.audienceParams);
            structAppend(VARIABLES.audienceLiveParams, {
                "live_source"={value=VARIABLES.audienceLiveSource,cfsqltype="cf_sql_varchar"},
                "live_campaign"={value=VARIABLES.audienceLiveCampaign,cfsqltype="cf_sql_varchar"},
                "live_city"={value=VARIABLES.audienceLiveCity,cfsqltype="cf_sql_varchar"},
                "live_event"={value=VARIABLES.audienceLiveEvent,cfsqltype="cf_sql_varchar"}
            });
            VARIABLES.audienceLiveSql = replace(fileRead(VARIABLES.audienceQueryDirectory & "live_journey.sql","UTF-8"),"/* AUDIENCE_FILTER */",VARIABLES.audienceFilterSql);
            VARIABLES.audienceLiveQuery = queryExecute(VARIABLES.audienceLiveSql,VARIABLES.audienceLiveParams,{datasource="runnerhub",timeout=15,cachedwithin=createTimeSpan(0,0,1,0)});
        } catch(any audienceLiveReadError) {
            VARIABLES.audienceLiveUnavailable = true;
            writeLog(file="audience_measurement",type="error",text="Business LIVE journey report unavailable: " & left(audienceLiveReadError.type & "",100));
        }
        // Optional operational state must never make the audience report unavailable.
        if (VARIABLES.audienceSchema.retention_ready[1]) {
            try {
                VARIABLES.audienceRetentionQuery = queryExecute("SELECT last_status, last_success_at, (last_success_at IS NULL OR last_success_at < now()-interval '2 hours') AS stale, has_more FROM audience.maintenance_state WHERE task_name='events_retention'", {}, {datasource="runnerhub",timeout=5});
                if (VARIABLES.audienceRetentionQuery.recordcount) {
                    VARIABLES.audienceRetentionRow = queryGetRow(VARIABLES.audienceRetentionQuery,1);
                    if (structKeyExists(VARIABLES.audienceRetentionRow,"last_success_at")) VARIABLES.audienceRetention.lastSuccess = VARIABLES.audienceRetentionRow.last_success_at;
                    VARIABLES.audienceRetention.hasMore = VARIABLES.audienceRetentionRow.has_more;
                    VARIABLES.audienceRetention.state = VARIABLES.audienceRetentionRow.last_status;
                    if (VARIABLES.audienceRetention.state EQ "ok" AND VARIABLES.audienceRetentionRow.stale) VARIABLES.audienceRetention.state = "stale";
                    if (VARIABLES.audienceRetention.state EQ "ok" AND VARIABLES.audienceRetention.hasMore) VARIABLES.audienceRetention.state = "backlog";
                } else VARIABLES.audienceRetention.state = "never";
            } catch(any audienceRetentionReadError) { VARIABLES.audienceRetention.state = "unavailable"; }
        }
    }
} catch (any audienceReadError) {
    VARIABLES.audienceUnavailable = true;
    // Public UI never exposes SQL, connection details or raw telemetry.
    writeLog(file="audience_measurement", type="error", text="Business audience report unavailable: " & left(audienceReadError.type & "", 100));
}
</cfscript>
