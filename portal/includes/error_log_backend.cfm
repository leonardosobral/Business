<cfscript>
function errorLogFormatDateTime(value) {
    if (!isDate(arguments.value)) {
        return "";
    }

    return dateTimeFormat(arguments.value, "dd/mm/yyyy HH:nn");
}

function errorLogShortText(value, numeric lengthLimit = 180) {
    var textValue = "";

    if (isSimpleValue(arguments.value)) {
        textValue = trim(arguments.value & "");
    } else {
        textValue = serializeJSON(arguments.value);
    }

    textValue = reReplace(textValue, "[\r\n\t]+", " ", "all");

    if (len(textValue) GT arguments.lengthLimit AND arguments.lengthLimit GT 3) {
        return left(textValue, arguments.lengthLimit - 3) & "...";
    }

    return textValue;
}

function errorLogItemLabel(value) {
    var itemValue = lCase(trim(arguments.value & ""));

    switch (itemValue) {
        case "erro":
            return "Erro";
        case "404":
            return "404";
        case "todos":
            return "Erro + 404";
        default:
            return len(trim(arguments.value & "")) ? arguments.value : "Sem tipo";
    }
}
</cfscript>

<cfparam name="URL.dias" default="7"/>
<cfparam name="URL.site" default=""/>
<cfparam name="URL.item" default="todos"/>
<cfparam name="URL.termo" default=""/>
<cfparam name="URL.limite" default="500"/>
<cfparam name="URL.log_id" default=""/>

<cfset VARIABLES.errorLogAllowedDays = "1,7,30,90"/>
<cfset VARIABLES.errorLogDays = int(val(URL.dias))/>
<cfif NOT listFind(VARIABLES.errorLogAllowedDays, VARIABLES.errorLogDays)>
    <cfset VARIABLES.errorLogDays = 7/>
</cfif>

<cfset VARIABLES.errorLogAllowedItems = "todos,erro,404"/>
<cfset VARIABLES.errorLogItem = lCase(trim(URL.item))/>
<cfif NOT listFindNoCase(VARIABLES.errorLogAllowedItems, VARIABLES.errorLogItem)>
    <cfset VARIABLES.errorLogItem = "todos"/>
</cfif>

<cfset VARIABLES.errorLogAllowedSites = "RR,OR,CT"/>
<cfset VARIABLES.errorLogSite = uCase(trim(URL.site))/>
<cfif NOT listFindNoCase(VARIABLES.errorLogAllowedSites, VARIABLES.errorLogSite)>
    <cfset VARIABLES.errorLogSite = ""/>
</cfif>

<cfset VARIABLES.errorLogAllowedLimits = "100,500,1000"/>
<cfset VARIABLES.errorLogSampleLimit = int(val(URL.limite))/>
<cfif NOT listFind(VARIABLES.errorLogAllowedLimits, VARIABLES.errorLogSampleLimit)>
    <cfset VARIABLES.errorLogSampleLimit = 500/>
</cfif>

<cfset VARIABLES.errorLogDisplayLimit = min(100, VARIABLES.errorLogSampleLimit)/>
<cfset VARIABLES.errorLogTerm = trim(URL.termo)/>
<cfset VARIABLES.errorLogStats = {
    total = 0,
    erros = 0,
    notFound = 0,
    bots = 0,
    sites = 0,
    origens = 0
}/>

<cfset qErrorLogRecent = queryNew("id_log,log_item,log_item_id,log_user,log_timestamp,site,log_user_agent,classificacao,url_detectada,url_path,log_preview,parece_bot")/>
<cfset qErrorLogByClass = queryNew("classificacao,total,ultimo_log")/>
<cfset qErrorLogByItem = queryNew("log_item,total,ultimo_log")/>
<cfset qErrorLogBySignature = queryNew("classificacao,assinatura,total,ultimo_log")/>
<cfset qErrorLogByHour = queryNew("hora,total,erros,not_found")/>
<cfset qErrorLogDetail = queryNew("id_log,log_item,log_item_id,log_user,log_timestamp,site,log_user_agent,classificacao,url_detectada,url_path,log_preview,parece_bot")/>

<cfquery name="qErrorLogTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_name = 'tb_log'
      AND table_schema IN (current_schema(), 'public')
    LIMIT 1
</cfquery>

<cfset VARIABLES.errorLogTablesReady = qErrorLogTables.recordcount GT 0/>

<cfif VARIABLES.errorLogTablesReady
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin>

    <cfquery name="qErrorLogStats">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogDays#"/> * interval '1 day')
              AND log_item IN ('erro', '404')
            <cfif VARIABLES.errorLogItem NEQ "todos">
              AND log_item = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogItem#"/>
            </cfif>
            <cfif len(VARIABLES.errorLogSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogSite#"/>
            </cfif>
            ORDER BY
            <cfif VARIABLES.errorLogItem EQ "todos">
              id_log DESC
            <cfelse>
              log_timestamp DESC, id_log DESC
            </cfif>
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogSampleLimit#"/>
        ),
        filtered AS (
            SELECT *
            FROM sample
            WHERE 1 = 1
            <cfif len(VARIABLES.errorLogTerm)>
              AND (
                  coalesce(log_item, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
              )
            </cfif>
        ),
        normalized AS (
            SELECT
                *,
                CASE WHEN coalesce(log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot)' THEN true ELSE false END AS parece_bot
            FROM filtered
        )
        SELECT
            count(*)::integer AS total,
            (count(*) FILTER (WHERE log_item = 'erro'))::integer AS erros,
            (count(*) FILTER (WHERE log_item = '404'))::integer AS not_found,
            (count(*) FILTER (WHERE parece_bot = true))::integer AS bots,
            count(DISTINCT site)::integer AS sites,
            count(DISTINCT nullif(log_user, ''))::integer AS origens
        FROM normalized
    </cfquery>

    <cfset VARIABLES.errorLogStats = {
        total = val(qErrorLogStats.total),
        erros = val(qErrorLogStats.erros),
        notFound = val(qErrorLogStats.not_found),
        bots = val(qErrorLogStats.bots),
        sites = val(qErrorLogStats.sites),
        origens = val(qErrorLogStats.origens)
    }/>

    <cfquery name="qErrorLogRecent">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogDays#"/> * interval '1 day')
              AND log_item IN ('erro', '404')
            <cfif VARIABLES.errorLogItem NEQ "todos">
              AND log_item = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogItem#"/>
            </cfif>
            <cfif len(VARIABLES.errorLogSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogSite#"/>
            </cfif>
            ORDER BY
            <cfif VARIABLES.errorLogItem EQ "todos">
              id_log DESC
            <cfelse>
              log_timestamp DESC, id_log DESC
            </cfif>
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogSampleLimit#"/>
        ),
        filtered AS (
            SELECT *
            FROM sample
            WHERE 1 = 1
            <cfif len(VARIABLES.errorLogTerm)>
              AND (
                  coalesce(log_item, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
              )
            </cfif>
        ),
        normalized AS (
            SELECT
                *,
                nullif(substring(coalesce(log_item_id, '') from 'https?://[^[:space:]<"]+'), '') AS url_detectada,
                trim(regexp_replace(regexp_replace(coalesce(log_item_id, ''), '<[^>]+>', ' ', 'g'), '[[:space:]]+', ' ', 'g')) AS log_preview,
                CASE
                    WHEN log_item = '404' THEN '404'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%database%' THEN 'Banco/SQL'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%sql%' THEN 'Banco/SQL'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%timeout%' THEN 'Timeout'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%cfdump%' THEN 'Erro CFML'
                    WHEN log_item = 'erro' THEN 'Erro'
                    ELSE coalesce(nullif(log_item, ''), 'Sem tipo')
                END AS classificacao,
                CASE WHEN coalesce(log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot)' THEN true ELSE false END AS parece_bot
            FROM filtered
        )
        SELECT
            id_log,
            log_item,
            log_item_id,
            log_user,
            log_timestamp,
            site,
            log_user_agent,
            classificacao,
            url_detectada,
            nullif(regexp_replace(coalesce(url_detectada, ''), '^https?://[^/]+', ''), '') AS url_path,
            left(log_preview, 800) AS log_preview,
            parece_bot
        FROM normalized
        ORDER BY id_log DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogDisplayLimit#"/>
    </cfquery>

    <cfquery name="qErrorLogByClass">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogDays#"/> * interval '1 day')
              AND log_item IN ('erro', '404')
            <cfif VARIABLES.errorLogItem NEQ "todos">
              AND log_item = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogItem#"/>
            </cfif>
            <cfif len(VARIABLES.errorLogSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogSite#"/>
            </cfif>
            ORDER BY
            <cfif VARIABLES.errorLogItem EQ "todos">
              id_log DESC
            <cfelse>
              log_timestamp DESC, id_log DESC
            </cfif>
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogSampleLimit#"/>
        ),
        filtered AS (
            SELECT *
            FROM sample
            WHERE 1 = 1
            <cfif len(VARIABLES.errorLogTerm)>
              AND (
                  coalesce(log_item, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
              )
            </cfif>
        ),
        normalized AS (
            SELECT
                *,
                CASE
                    WHEN log_item = '404' THEN '404'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%database%' THEN 'Banco/SQL'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%sql%' THEN 'Banco/SQL'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%timeout%' THEN 'Timeout'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%cfdump%' THEN 'Erro CFML'
                    WHEN log_item = 'erro' THEN 'Erro'
                    ELSE coalesce(nullif(log_item, ''), 'Sem tipo')
                END AS classificacao
            FROM filtered
        )
        SELECT classificacao, count(*)::integer AS total, max(log_timestamp) AS ultimo_log
        FROM normalized
        GROUP BY classificacao
        ORDER BY total DESC, ultimo_log DESC
        LIMIT 12
    </cfquery>

    <cfquery name="qErrorLogByItem">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogDays#"/> * interval '1 day')
              AND log_item IN ('erro', '404')
            <cfif VARIABLES.errorLogItem NEQ "todos">
              AND log_item = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogItem#"/>
            </cfif>
            <cfif len(VARIABLES.errorLogSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogSite#"/>
            </cfif>
            ORDER BY
            <cfif VARIABLES.errorLogItem EQ "todos">
              id_log DESC
            <cfelse>
              log_timestamp DESC, id_log DESC
            </cfif>
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogSampleLimit#"/>
        ),
        filtered AS (
            SELECT *
            FROM sample
            WHERE 1 = 1
            <cfif len(VARIABLES.errorLogTerm)>
              AND (
                  coalesce(log_item, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
              )
            </cfif>
        )
        SELECT coalesce(nullif(log_item, ''), 'sem tipo') AS log_item, count(*)::integer AS total, max(log_timestamp) AS ultimo_log
        FROM filtered
        GROUP BY coalesce(nullif(log_item, ''), 'sem tipo')
        ORDER BY total DESC, ultimo_log DESC
        LIMIT 12
    </cfquery>

    <cfquery name="qErrorLogBySignature">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogDays#"/> * interval '1 day')
              AND log_item IN ('erro', '404')
            <cfif VARIABLES.errorLogItem NEQ "todos">
              AND log_item = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogItem#"/>
            </cfif>
            <cfif len(VARIABLES.errorLogSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogSite#"/>
            </cfif>
            ORDER BY
            <cfif VARIABLES.errorLogItem EQ "todos">
              id_log DESC
            <cfelse>
              log_timestamp DESC, id_log DESC
            </cfif>
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogSampleLimit#"/>
        ),
        filtered AS (
            SELECT *
            FROM sample
            WHERE 1 = 1
            <cfif len(VARIABLES.errorLogTerm)>
              AND (
                  coalesce(log_item, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
              )
            </cfif>
        ),
        normalized AS (
            SELECT
                *,
                nullif(substring(coalesce(log_item_id, '') from 'https?://[^[:space:]<"]+'), '') AS url_detectada,
                trim(regexp_replace(regexp_replace(coalesce(log_item_id, ''), '<[^>]+>', ' ', 'g'), '[[:space:]]+', ' ', 'g')) AS log_preview,
                CASE
                    WHEN log_item = '404' THEN '404'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%database%' THEN 'Banco/SQL'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%sql%' THEN 'Banco/SQL'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%timeout%' THEN 'Timeout'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%cfdump%' THEN 'Erro CFML'
                    WHEN log_item = 'erro' THEN 'Erro'
                    ELSE coalesce(nullif(log_item, ''), 'Sem tipo')
                END AS classificacao
            FROM filtered
        ),
        signatures AS (
            SELECT
                classificacao,
                coalesce(
                    nullif(regexp_replace(coalesce(url_detectada, ''), '^https?://[^/]+', ''), ''),
                    nullif(left(log_preview, 180), ''),
                    'sem assinatura'
                ) AS assinatura,
                log_timestamp
            FROM normalized
        )
        SELECT classificacao, assinatura, count(*)::integer AS total, max(log_timestamp) AS ultimo_log
        FROM signatures
        GROUP BY classificacao, assinatura
        ORDER BY total DESC, ultimo_log DESC
        LIMIT 20
    </cfquery>

    <cfquery name="qErrorLogByHour">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogDays#"/> * interval '1 day')
              AND log_item IN ('erro', '404')
            <cfif VARIABLES.errorLogItem NEQ "todos">
              AND log_item = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogItem#"/>
            </cfif>
            <cfif len(VARIABLES.errorLogSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.errorLogSite#"/>
            </cfif>
            ORDER BY
            <cfif VARIABLES.errorLogItem EQ "todos">
              id_log DESC
            <cfelse>
              log_timestamp DESC, id_log DESC
            </cfif>
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.errorLogSampleLimit#"/>
        ),
        filtered AS (
            SELECT *
            FROM sample
            WHERE 1 = 1
            <cfif len(VARIABLES.errorLogTerm)>
              AND (
                  coalesce(log_item, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.errorLogTerm#%"/>
              )
            </cfif>
        )
        SELECT
            date_trunc('hour', log_timestamp) AS hora,
            count(*)::integer AS total,
            (count(*) FILTER (WHERE log_item = 'erro'))::integer AS erros,
            (count(*) FILTER (WHERE log_item = '404'))::integer AS not_found
        FROM filtered
        GROUP BY date_trunc('hour', log_timestamp)
        ORDER BY hora DESC
        LIMIT 24
    </cfquery>

    <cfif len(trim(URL.log_id)) AND isNumeric(URL.log_id)>
        <cfquery name="qErrorLogDetail">
            SELECT
                id_log,
                log_item,
                log_item_id,
                log_user,
                log_timestamp,
                site,
                log_user_agent,
                nullif(substring(coalesce(log_item_id, '') from 'https?://[^[:space:]<"]+'), '') AS url_detectada,
                nullif(regexp_replace(coalesce(substring(coalesce(log_item_id, '') from 'https?://[^[:space:]<"]+'), ''), '^https?://[^/]+', ''), '') AS url_path,
                trim(regexp_replace(regexp_replace(coalesce(log_item_id, ''), '<[^>]+>', ' ', 'g'), '[[:space:]]+', ' ', 'g')) AS log_preview,
                CASE
                    WHEN log_item = '404' THEN '404'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%database%' THEN 'Banco/SQL'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%sql%' THEN 'Banco/SQL'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%timeout%' THEN 'Timeout'
                    WHEN log_item = 'erro' AND coalesce(log_item_id, '') ILIKE '%cfdump%' THEN 'Erro CFML'
                    WHEN log_item = 'erro' THEN 'Erro'
                    ELSE coalesce(nullif(log_item, ''), 'Sem tipo')
                END AS classificacao,
                CASE WHEN coalesce(log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot)' THEN true ELSE false END AS parece_bot
            FROM tb_log
            WHERE id_log = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.log_id)#"/>
              AND log_item IN ('erro', '404')
            LIMIT 1
        </cfquery>
    </cfif>
</cfif>
