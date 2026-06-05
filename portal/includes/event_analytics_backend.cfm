<cfscript>
function eventAnalyticsFormatDateTime(value) {
    if (!isDate(arguments.value)) {
        return "";
    }

    return dateTimeFormat(arguments.value, "dd/mm/yyyy HH:nn");
}

function eventAnalyticsShortText(value, numeric lengthLimit = 140) {
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
</cfscript>

<cfparam name="URL.dias" default="7"/>
<cfparam name="URL.site" default=""/>
<cfparam name="URL.termo" default=""/>
<cfparam name="URL.limite" default="1000"/>
<cfparam name="URL.bot" default="todos"/>
<cfparam name="URL.evento_id" default=""/>

<cfset VARIABLES.eventAnalyticsAllowedDays = "1,7,30,90"/>
<cfset VARIABLES.eventAnalyticsDays = int(val(URL.dias))/>
<cfif NOT listFind(VARIABLES.eventAnalyticsAllowedDays, VARIABLES.eventAnalyticsDays)>
    <cfset VARIABLES.eventAnalyticsDays = 7/>
</cfif>

<cfset VARIABLES.eventAnalyticsAllowedSites = "RR,OR,CT"/>
<cfset VARIABLES.eventAnalyticsSite = uCase(trim(URL.site))/>
<cfif NOT listFindNoCase(VARIABLES.eventAnalyticsAllowedSites, VARIABLES.eventAnalyticsSite)>
    <cfset VARIABLES.eventAnalyticsSite = ""/>
</cfif>

<cfset VARIABLES.eventAnalyticsAllowedLimits = "500,1000,3000"/>
<cfset VARIABLES.eventAnalyticsSampleLimit = int(val(URL.limite))/>
<cfif NOT listFind(VARIABLES.eventAnalyticsAllowedLimits, VARIABLES.eventAnalyticsSampleLimit)>
    <cfset VARIABLES.eventAnalyticsSampleLimit = 1000/>
</cfif>

<cfset VARIABLES.eventAnalyticsBotFilter = lCase(trim(URL.bot))/>
<cfif NOT listFindNoCase("todos,sim,nao", VARIABLES.eventAnalyticsBotFilter)>
    <cfset VARIABLES.eventAnalyticsBotFilter = "todos"/>
</cfif>

<cfset VARIABLES.eventAnalyticsTerm = trim(URL.termo)/>
<cfset VARIABLES.eventAnalyticsDisplayLimit = min(150, VARIABLES.eventAnalyticsSampleLimit)/>
<cfset VARIABLES.eventAnalyticsEventId = (len(trim(URL.evento_id)) AND isNumeric(URL.evento_id)) ? int(val(URL.evento_id)) : 0/>
<cfset VARIABLES.eventAnalyticsStats = {
    pageviews = 0,
    eventos = 0,
    origens = 0,
    bots = 0,
    mobile = 0,
    semCadastro = 0
}/>

<cfset qEventAnalyticsRecent = queryNew("id_log,id_evento,evento_nome,evento_tag,cidade,estado,data_inicial,site,log_user,log_timestamp,log_user_agent,dispositivo,navegador,parece_bot")/>
<cfset qEventAnalyticsTopEvents = queryNew("id_evento,evento_nome,evento_tag,cidade,estado,data_inicial,views,origens,bots,ultimo_acesso")/>
<cfset qEventAnalyticsByCity = queryNew("cidade,estado,views,eventos,ultimo_acesso")/>
<cfset qEventAnalyticsBySite = queryNew("site,views,eventos,origens,bots")/>
<cfset qEventAnalyticsByDevice = queryNew("dispositivo,views,eventos,origens")/>
<cfset qEventAnalyticsByHour = queryNew("hora,views,eventos,bots")/>
<cfset qEventAnalyticsFlow = queryNew("evento_anterior_id,evento_anterior_nome,evento_atual_id,evento_atual_nome,transicoes,origens,ultimo_acesso")/>
<cfset qEventAnalyticsOrigins = queryNew("log_user,views,eventos,ultimo_acesso,ultimo_user_agent")/>
<cfset qEventAnalyticsDetailEvent = queryNew("id_evento,nome_evento,tag,cidade,estado,data_inicial,data_final,ativo,status_evento,url_hotsite,url_inscricao")/>
<cfset qEventAnalyticsDetailStats = queryNew("views,origens,bots,mobile,primeiro_acesso,ultimo_acesso")/>
<cfset qEventAnalyticsDetailRecent = queryNew("id_log,log_user,log_timestamp,site,log_user_agent,dispositivo,navegador,parece_bot")/>

<cfquery name="qEventAnalyticsTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_name IN ('tb_log', 'tb_evento_corridas')
      AND table_schema IN (current_schema(), 'public')
</cfquery>

<cfset VARIABLES.eventAnalyticsTablesList = ValueList(qEventAnalyticsTables.table_name)/>
<cfset VARIABLES.eventAnalyticsTablesReady = ListFindNoCase(VARIABLES.eventAnalyticsTablesList, "tb_log") AND ListFindNoCase(VARIABLES.eventAnalyticsTablesList, "tb_evento_corridas")/>

<cfif VARIABLES.eventAnalyticsTablesReady
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin>

    <cfquery name="qEventAnalyticsStats">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot,
                CASE
                    WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN 'Bot'
                    WHEN coalesce(log.log_user_agent, '') ~* '(iphone|android|mobile)' THEN 'Mobile'
                    WHEN coalesce(log.log_user_agent, '') ~* '(ipad|tablet)' THEN 'Tablet'
                    ELSE 'Desktop'
                END AS dispositivo
            FROM sample log
        ),
        enriched AS (
            SELECT
                normalized.*,
                evt.nome_evento,
                evt.tag,
                evt.cidade,
                evt.estado,
                evt.data_inicial
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE 1 = 1
            <cfif VARIABLES.eventAnalyticsEventId GT 0>
              AND id_evento_log = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsEventId#"/>
            </cfif>
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(tag, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(estado, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        )
        SELECT
            count(*)::integer AS pageviews,
            count(DISTINCT id_evento_log)::integer AS eventos,
            count(DISTINCT nullif(log_user, ''))::integer AS origens,
            (count(*) FILTER (WHERE parece_bot = true))::integer AS bots,
            (count(*) FILTER (WHERE dispositivo = 'Mobile'))::integer AS mobile,
            (count(*) FILTER (WHERE id_evento_log IS NULL OR nome_evento IS NULL))::integer AS sem_cadastro
        FROM filtered
    </cfquery>

    <cfset VARIABLES.eventAnalyticsStats = {
        pageviews = val(qEventAnalyticsStats.pageviews),
        eventos = val(qEventAnalyticsStats.eventos),
        origens = val(qEventAnalyticsStats.origens),
        bots = val(qEventAnalyticsStats.bots),
        mobile = val(qEventAnalyticsStats.mobile),
        semCadastro = val(qEventAnalyticsStats.sem_cadastro)
    }/>

    <cfquery name="qEventAnalyticsTopEvents">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot
            FROM sample log
        ),
        enriched AS (
            SELECT normalized.*, evt.nome_evento, evt.tag, evt.cidade, evt.estado, evt.data_inicial
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE 1 = 1
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(tag, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(estado, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        )
        SELECT
            id_evento_log AS id_evento,
            coalesce(nome_evento, 'Evento ##' || coalesce(id_evento_log::varchar, log_item_id)) AS evento_nome,
            coalesce(tag, '') AS evento_tag,
            coalesce(cidade, '') AS cidade,
            coalesce(estado, '') AS estado,
            data_inicial,
            count(*)::integer AS views,
            count(DISTINCT nullif(log_user, ''))::integer AS origens,
            (count(*) FILTER (WHERE parece_bot = true))::integer AS bots,
            max(log_timestamp) AS ultimo_acesso
        FROM filtered
        GROUP BY id_evento_log, log_item_id, nome_evento, tag, cidade, estado, data_inicial
        ORDER BY views DESC, ultimo_acesso DESC
        LIMIT 30
    </cfquery>

    <cfquery name="qEventAnalyticsByCity">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot
            FROM sample log
        ),
        enriched AS (
            SELECT normalized.*, evt.nome_evento, evt.tag, evt.cidade, evt.estado
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE 1 = 1
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(tag, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(estado, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        )
        SELECT
            coalesce(nullif(cidade, ''), 'Sem cidade') AS cidade,
            coalesce(nullif(estado, ''), '') AS estado,
            count(*)::integer AS views,
            count(DISTINCT id_evento_log)::integer AS eventos,
            max(log_timestamp) AS ultimo_acesso
        FROM filtered
        GROUP BY coalesce(nullif(cidade, ''), 'Sem cidade'), coalesce(nullif(estado, ''), '')
        ORDER BY views DESC, ultimo_acesso DESC
        LIMIT 20
    </cfquery>

    <cfquery name="qEventAnalyticsBySite">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot
            FROM sample log
        ),
        enriched AS (
            SELECT normalized.*, evt.nome_evento, evt.tag, evt.cidade, evt.estado
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE 1 = 1
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(tag, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(estado, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        )
        SELECT
            coalesce(nullif(site, ''), 'Sem site') AS site,
            count(*)::integer AS views,
            count(DISTINCT id_evento_log)::integer AS eventos,
            count(DISTINCT nullif(log_user, ''))::integer AS origens,
            (count(*) FILTER (WHERE parece_bot = true))::integer AS bots
        FROM filtered
        GROUP BY coalesce(nullif(site, ''), 'Sem site')
        ORDER BY views DESC
    </cfquery>

    <cfquery name="qEventAnalyticsByDevice">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot,
                CASE
                    WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN 'Bot'
                    WHEN coalesce(log.log_user_agent, '') ~* '(iphone|android|mobile)' THEN 'Mobile'
                    WHEN coalesce(log.log_user_agent, '') ~* '(ipad|tablet)' THEN 'Tablet'
                    ELSE 'Desktop'
                END AS dispositivo
            FROM sample log
        ),
        enriched AS (
            SELECT normalized.*, evt.nome_evento, evt.tag, evt.cidade, evt.estado
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE 1 = 1
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(tag, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(estado, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        )
        SELECT
            dispositivo,
            count(*)::integer AS views,
            count(DISTINCT id_evento_log)::integer AS eventos,
            count(DISTINCT nullif(log_user, ''))::integer AS origens
        FROM filtered
        GROUP BY dispositivo
        ORDER BY views DESC
    </cfquery>

    <cfquery name="qEventAnalyticsByHour">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot
            FROM sample log
        ),
        enriched AS (
            SELECT normalized.*, evt.nome_evento, evt.tag, evt.cidade, evt.estado
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE 1 = 1
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(tag, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(estado, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        )
        SELECT
            date_trunc('hour', log_timestamp) AS hora,
            count(*)::integer AS views,
            count(DISTINCT id_evento_log)::integer AS eventos,
            (count(*) FILTER (WHERE parece_bot = true))::integer AS bots
        FROM filtered
        GROUP BY date_trunc('hour', log_timestamp)
        ORDER BY hora DESC
        LIMIT 24
    </cfquery>

    <cfquery name="qEventAnalyticsFlow">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot
            FROM sample log
        ),
        enriched AS (
            SELECT normalized.*, evt.nome_evento
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE id_evento_log IS NOT NULL
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        ),
        sequenced AS (
            SELECT
                log_user,
                id_evento_log AS evento_atual_id,
                coalesce(nome_evento, 'Evento ##' || id_evento_log::varchar) AS evento_atual_nome,
                lag(id_evento_log) OVER (PARTITION BY log_user ORDER BY log_timestamp, id_log) AS evento_anterior_id,
                lag(coalesce(nome_evento, 'Evento ##' || id_evento_log::varchar)) OVER (PARTITION BY log_user ORDER BY log_timestamp, id_log) AS evento_anterior_nome,
                log_timestamp
            FROM filtered
            WHERE nullif(log_user, '') IS NOT NULL
        )
        SELECT
            evento_anterior_id,
            evento_anterior_nome,
            evento_atual_id,
            evento_atual_nome,
            count(*)::integer AS transicoes,
            count(DISTINCT log_user)::integer AS origens,
            max(log_timestamp) AS ultimo_acesso
        FROM sequenced
        WHERE evento_anterior_id IS NOT NULL
          AND evento_anterior_id <> evento_atual_id
        GROUP BY evento_anterior_id, evento_anterior_nome, evento_atual_id, evento_atual_nome
        ORDER BY transicoes DESC, ultimo_acesso DESC
        LIMIT 20
    </cfquery>

    <cfquery name="qEventAnalyticsOrigins">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot
            FROM sample log
        ),
        enriched AS (
            SELECT normalized.*, evt.nome_evento, evt.tag, evt.cidade, evt.estado
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE nullif(log_user, '') IS NOT NULL
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(tag, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(estado, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        )
        SELECT
            log_user,
            count(*)::integer AS views,
            count(DISTINCT id_evento_log)::integer AS eventos,
            max(log_timestamp) AS ultimo_acesso,
            (array_agg(log_user_agent ORDER BY log_timestamp DESC, id_log DESC))[1] AS ultimo_user_agent
        FROM filtered
        GROUP BY log_user
        ORDER BY views DESC, ultimo_acesso DESC
        LIMIT 20
    </cfquery>

    <cfquery name="qEventAnalyticsRecent">
        WITH sample AS (
            SELECT *
            FROM tb_log
            WHERE log_item = 'evento'
              AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
            <cfif len(VARIABLES.eventAnalyticsSite)>
              AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
            </cfif>
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
        ),
        normalized AS (
            SELECT
                log.*,
                CASE WHEN log.log_item_id ~ '^[0-9]+$' THEN log.log_item_id::integer ELSE NULL END AS id_evento_log,
                CASE WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot,
                CASE
                    WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN 'Bot'
                    WHEN coalesce(log.log_user_agent, '') ~* '(iphone|android|mobile)' THEN 'Mobile'
                    WHEN coalesce(log.log_user_agent, '') ~* '(ipad|tablet)' THEN 'Tablet'
                    ELSE 'Desktop'
                END AS dispositivo,
                CASE
                    WHEN coalesce(log.log_user_agent, '') ~* 'edg/' THEN 'Edge'
                    WHEN coalesce(log.log_user_agent, '') ~* 'chrome/' THEN 'Chrome'
                    WHEN coalesce(log.log_user_agent, '') ~* 'safari/' THEN 'Safari'
                    WHEN coalesce(log.log_user_agent, '') ~* 'firefox/' THEN 'Firefox'
                    WHEN coalesce(log.log_user_agent, '') ~* '(bot|crawler|spider)' THEN 'Bot'
                    ELSE 'Outro'
                END AS navegador
            FROM sample log
        ),
        enriched AS (
            SELECT normalized.*, evt.nome_evento, evt.tag, evt.cidade, evt.estado, evt.data_inicial
            FROM normalized
            LEFT JOIN tb_evento_corridas evt ON evt.id_evento = normalized.id_evento_log
        ),
        filtered AS (
            SELECT *
            FROM enriched
            WHERE 1 = 1
            <cfif VARIABLES.eventAnalyticsEventId GT 0>
              AND id_evento_log = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsEventId#"/>
            </cfif>
            <cfif VARIABLES.eventAnalyticsBotFilter EQ "sim">
              AND parece_bot = true
            <cfelseif VARIABLES.eventAnalyticsBotFilter EQ "nao">
              AND parece_bot = false
            </cfif>
            <cfif len(VARIABLES.eventAnalyticsTerm)>
              AND (
                  coalesce(log_item_id, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(log_user_agent, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(nome_evento, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(tag, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(cidade, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
                  OR coalesce(estado, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventAnalyticsTerm#%"/>
              )
            </cfif>
        )
        SELECT
            id_log,
            id_evento_log AS id_evento,
            coalesce(nome_evento, 'Evento ##' || coalesce(id_evento_log::varchar, log_item_id)) AS evento_nome,
            coalesce(tag, '') AS evento_tag,
            coalesce(cidade, '') AS cidade,
            coalesce(estado, '') AS estado,
            data_inicial,
            site,
            log_user,
            log_timestamp,
            log_user_agent,
            dispositivo,
            navegador,
            parece_bot
        FROM filtered
        ORDER BY log_timestamp DESC, id_log DESC
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDisplayLimit#"/>
    </cfquery>

    <cfif VARIABLES.eventAnalyticsEventId GT 0>
        <cfquery name="qEventAnalyticsDetailEvent">
            SELECT
                id_evento,
                nome_evento,
                tag,
                cidade,
                estado,
                data_inicial,
                data_final,
                ativo,
                status_evento,
                url_hotsite,
                url_inscricao
            FROM tb_evento_corridas
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsEventId#"/>
            LIMIT 1
        </cfquery>

        <cfquery name="qEventAnalyticsDetailStats">
            WITH sample AS (
                SELECT *
                FROM tb_log
                WHERE log_item = 'evento'
                  AND log_item_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsEventId#"/>
                  AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
                <cfif len(VARIABLES.eventAnalyticsSite)>
                  AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
                </cfif>
                ORDER BY log_timestamp DESC, id_log DESC
                LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
            ),
            normalized AS (
                SELECT
                    *,
                    CASE WHEN coalesce(log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot,
                    CASE
                        WHEN coalesce(log_user_agent, '') ~* '(iphone|android|mobile)' THEN true
                        ELSE false
                    END AS mobile
                FROM sample
            )
            SELECT
                count(*)::integer AS views,
                count(DISTINCT nullif(log_user, ''))::integer AS origens,
                (count(*) FILTER (WHERE parece_bot = true))::integer AS bots,
                (count(*) FILTER (WHERE mobile = true))::integer AS mobile,
                min(log_timestamp) AS primeiro_acesso,
                max(log_timestamp) AS ultimo_acesso
            FROM normalized
        </cfquery>

        <cfquery name="qEventAnalyticsDetailRecent">
            WITH sample AS (
                SELECT *
                FROM tb_log
                WHERE log_item = 'evento'
                  AND log_item_id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsEventId#"/>
                  AND log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsDays#"/> * interval '1 day')
                <cfif len(VARIABLES.eventAnalyticsSite)>
                  AND site = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventAnalyticsSite#"/>
                </cfif>
                ORDER BY log_timestamp DESC, id_log DESC
                LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventAnalyticsSampleLimit#"/>
            )
            SELECT
                id_log,
                log_user,
                log_timestamp,
                site,
                log_user_agent,
                CASE
                    WHEN coalesce(log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN 'Bot'
                    WHEN coalesce(log_user_agent, '') ~* '(iphone|android|mobile)' THEN 'Mobile'
                    WHEN coalesce(log_user_agent, '') ~* '(ipad|tablet)' THEN 'Tablet'
                    ELSE 'Desktop'
                END AS dispositivo,
                CASE
                    WHEN coalesce(log_user_agent, '') ~* 'edg/' THEN 'Edge'
                    WHEN coalesce(log_user_agent, '') ~* 'chrome/' THEN 'Chrome'
                    WHEN coalesce(log_user_agent, '') ~* 'safari/' THEN 'Safari'
                    WHEN coalesce(log_user_agent, '') ~* 'firefox/' THEN 'Firefox'
                    WHEN coalesce(log_user_agent, '') ~* '(bot|crawler|spider)' THEN 'Bot'
                    ELSE 'Outro'
                END AS navegador,
                CASE WHEN coalesce(log_user_agent, '') ~* '(bot|crawler|spider|semrush|bingbot|googlebot|facebookexternalhit|whatsapp)' THEN true ELSE false END AS parece_bot
            FROM sample
            ORDER BY log_timestamp DESC, id_log DESC
            LIMIT 50
        </cfquery>
    </cfif>
</cfif>
