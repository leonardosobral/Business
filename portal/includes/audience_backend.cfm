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
        "calendar":"Agenda", "other":"Outras páginas", "MOBILE":"Mobile", "TABLET":"Tablet", "DESKTOP":"Desktop", "UNKNOWN":"Desconhecido"};
    return structKeyExists(labels, arguments.value) ? labels[arguments.value] : arguments.value;
}
function audienceDate(value) {
    return isDate(arguments.value) ? dateTimeFormat(arguments.value, "dd/mm HH:nn", "America/Sao_Paulo") : "—";
}
function audienceRate(numerator, denominator) {
    return val(arguments.denominator) GT 0 ? numberFormat(100 * val(arguments.numerator) / val(arguments.denominator),"0.0") & "%" : "—";
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
VARIABLES.audienceFamilies = "home,state,search,event,profile,news,news_detail,videos,video_detail,results,calendar,other";
if (!listFind(VARIABLES.audienceFamilies, VARIABLES.audienceFamily)) VARIABLES.audienceFamily = "";
VARIABLES.audienceDevice = uCase(audienceInput("dispositivo"));
if (!listFind("MOBILE,TABLET,DESKTOP,UNKNOWN", VARIABLES.audienceDevice)) VARIABLES.audienceDevice = "";
VARIABLES.audienceIncludeInternal = audienceInput("internos") EQ "1";
VARIABLES.audienceReady = false;
VARIABLES.audienceUnavailable = false;
VARIABLES.audienceRetention = {state="not_installed", lastSuccess="", hasMore=false};
VARIABLES.audienceQueries = {};
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
