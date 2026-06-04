<cfscript>
function searchLogFormatDateTime(value) {
    if (!isDate(arguments.value)) {
        return "";
    }

    return dateTimeFormat(arguments.value, "dd/mm/yyyy HH:nn");
}

function searchLogShortText(value, numeric lengthLimit = 160) {
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

function searchLogScopeLabel(value) {
    var scopeValue = lCase(trim(arguments.value & ""));

    switch (scopeValue) {
        case "eventos":
            return "Eventos";
        case "resultados":
            return "Resultados";
        case "atletas":
            return "Atletas";
        case "noticias":
            return "Noticias";
        case "videos":
            return "Videos";
        case "todos":
            return "Todos";
        case "sem escopo":
            return "Sem escopo";
        default:
            return len(scopeValue) ? arguments.value : "Sem escopo";
    }
}
</cfscript>

<cfparam name="URL.dias" default="30"/>
<cfparam name="URL.ambiente" default=""/>
<cfparam name="URL.termo" default=""/>
<cfparam name="URL.pagina" default="1"/>
<cfparam name="URL.busca_id" default=""/>

<cfset VARIABLES.searchLogAllowedDays = "7,30,90,365"/>
<cfset VARIABLES.searchLogDays = int(val(URL.dias))/>
<cfif NOT listFind(VARIABLES.searchLogAllowedDays, VARIABLES.searchLogDays)>
    <cfset VARIABLES.searchLogDays = 30/>
</cfif>

<cfset VARIABLES.searchLogAmbiente = lCase(trim(URL.ambiente))/>
<cfif NOT listFindNoCase("dev,beta,prod", VARIABLES.searchLogAmbiente)>
    <cfset VARIABLES.searchLogAmbiente = ""/>
</cfif>

<cfset VARIABLES.searchLogTerm = trim(URL.termo)/>
<cfset VARIABLES.searchLogPageSize = 20/>
<cfset VARIABLES.searchLogPage = max(1, int(val(URL.pagina))) />
<cfset VARIABLES.searchLogOffset = (VARIABLES.searchLogPage - 1) * VARIABLES.searchLogPageSize/>
<cfset VARIABLES.searchLogStats = {
    totalBuscas = 0,
    buscasIa = 0,
    chamadasIa = 0,
    fallbacks = 0,
    erros = 0,
    usuarios = 0,
    execucoes = 0
}/>
<cfset VARIABLES.searchLogTotalRows = 0/>
<cfset VARIABLES.searchLogTotalPages = 1/>
<cfset VARIABLES.searchLogFallbackRate = 0/>

<cfset qSearchLogRecent = queryNew("id_busca_log,log_timestamp,ambiente,site,etapa,busca_modo,busca_tipo,tipo_termo,termo_original,termo_livre,modelo,usou_ia,fallback_usado,fallback_motivo,erro,http_status,id_usuario,usuario_nome,usuario_email,total_execucoes,eventos,resultados,atletas,noticias,videos,total_resultados")/>
<cfset qSearchLogDaily = queryNew("dia,total_buscas,buscas_ia,fallbacks")/>
<cfset qSearchLogTopTerms = queryNew("termo,buscas,buscas_ia,fallbacks,ultima_busca")/>
<cfset qSearchLogZeroResults = queryNew("id_busca_log,log_timestamp,termo_original,eventos,resultados,atletas,noticias,videos,total_resultados")/>
<cfset qSearchLogFailures = queryNew("id_busca_log,log_timestamp,termo_original,modelo,http_status,fallback_usado,fallback_motivo,erro")/>
<cfset qSearchLogScopes = queryNew("busca_scope,execucoes,eventos,resultados,atletas,noticias,videos,total_resultados")/>
<cfset qSearchLogUsers = queryNew("id_usuario,usuario_nome,usuario_email,buscas,buscas_ia,ultima_busca")/>
<cfset qSearchLogTopFilters = queryNew("tipo,valor,buscas,ultima_busca")/>
<cfset qSearchLogDetailParent = queryNew("id_busca_log,log_timestamp,ambiente,site,etapa,busca_modo,busca_tipo,busca_scope,tipo_termo,termo_original,termo_livre,modelo,usou_ia,fallback_usado,fallback_motivo,erro,http_status,id_usuario,usuario_nome,usuario_email,filtros_json,contagens_json,request_json,ia_json,payload_json")/>
<cfset qSearchLogDetailChildren = queryNew("id_busca_log,log_timestamp,ambiente,site,etapa,busca_modo,busca_tipo,busca_scope,tipo_termo,termo_original,termo_livre,modelo,usou_ia,fallback_usado,fallback_motivo,erro,http_status,id_usuario,filtros_json,contagens_json,request_json,ia_json,payload_json")/>

<cfquery name="qSearchLogTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_name = 'tb_busca_log'
      AND table_schema IN (current_schema(), 'public')
    LIMIT 1
</cfquery>

<cfset VARIABLES.searchLogTablesReady = qSearchLogTables.recordcount GT 0/>

<cfif VARIABLES.searchLogTablesReady
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin>

    <cfquery name="qSearchLogStats">
        SELECT
            (count(*) FILTER (WHERE etapa = 'interpretacao'))::integer AS total_buscas,
            (count(*) FILTER (WHERE etapa = 'interpretacao' AND busca_modo = 'ai'))::integer AS buscas_ia,
            (count(*) FILTER (WHERE etapa = 'interpretacao' AND usou_ia = true))::integer AS chamadas_ia,
            (count(*) FILTER (WHERE etapa = 'interpretacao' AND fallback_usado = true))::integer AS fallbacks,
            (count(*) FILTER (WHERE etapa = 'interpretacao' AND erro IS NOT NULL AND length(trim(erro)) > 0))::integer AS erros,
            (count(DISTINCT id_usuario) FILTER (WHERE etapa = 'interpretacao' AND id_usuario IS NOT NULL))::integer AS usuarios,
            (count(*) FILTER (WHERE etapa = 'execucao'))::integer AS execucoes
        FROM tb_busca_log
        WHERE log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
        <cfif len(VARIABLES.searchLogAmbiente)>
            AND ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
        </cfif>
        <cfif len(VARIABLES.searchLogTerm)>
            AND (
                termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
                OR termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
            )
        </cfif>
    </cfquery>

    <cfset VARIABLES.searchLogStats = {
        totalBuscas = val(qSearchLogStats.total_buscas),
        buscasIa = val(qSearchLogStats.buscas_ia),
        chamadasIa = val(qSearchLogStats.chamadas_ia),
        fallbacks = val(qSearchLogStats.fallbacks),
        erros = val(qSearchLogStats.erros),
        usuarios = val(qSearchLogStats.usuarios),
        execucoes = val(qSearchLogStats.execucoes)
    }/>

    <cfif VARIABLES.searchLogStats.totalBuscas GT 0>
        <cfset VARIABLES.searchLogFallbackRate = (VARIABLES.searchLogStats.fallbacks * 100) / VARIABLES.searchLogStats.totalBuscas/>
    </cfif>

    <cfquery name="qSearchLogTotalCount">
        SELECT count(*)::integer AS total
        FROM tb_busca_log p
        WHERE p.id_busca_log_parent IS NULL
          AND p.etapa IN ('interpretacao', 'legado')
          AND p.log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
        <cfif len(VARIABLES.searchLogAmbiente)>
          AND p.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
        </cfif>
        <cfif len(VARIABLES.searchLogTerm)>
          AND (
              p.termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              OR p.termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
          )
        </cfif>
    </cfquery>

    <cfset VARIABLES.searchLogTotalRows = val(qSearchLogTotalCount.total)/>
    <cfset VARIABLES.searchLogTotalPages = max(1, ceiling(VARIABLES.searchLogTotalRows / VARIABLES.searchLogPageSize))/>
    <cfif VARIABLES.searchLogPage GT VARIABLES.searchLogTotalPages>
        <cfset VARIABLES.searchLogPage = VARIABLES.searchLogTotalPages/>
        <cfset VARIABLES.searchLogOffset = (VARIABLES.searchLogPage - 1) * VARIABLES.searchLogPageSize/>
    </cfif>

    <cfquery name="qSearchLogRecent">
        WITH parent_rows AS (
            SELECT p.*
            FROM tb_busca_log p
            WHERE p.id_busca_log_parent IS NULL
              AND p.etapa IN ('interpretacao', 'legado')
              AND p.log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
            <cfif len(VARIABLES.searchLogAmbiente)>
              AND p.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
            </cfif>
            <cfif len(VARIABLES.searchLogTerm)>
              AND (
                  p.termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
                  OR p.termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              )
            </cfif>
            ORDER BY p.log_timestamp DESC, p.id_busca_log DESC
            LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogPageSize#"/>
            OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogOffset#"/>
        )
        SELECT
            p.id_busca_log,
            p.log_timestamp,
            p.ambiente,
            p.site,
            p.etapa,
            p.busca_modo,
            p.busca_tipo,
            p.tipo_termo,
            p.termo_original,
            p.termo_livre,
            p.modelo,
            p.usou_ia,
            p.fallback_usado,
            p.fallback_motivo,
            p.erro,
            p.http_status,
            p.id_usuario,
            coalesce(usr.name, '') AS usuario_nome,
            coalesce(usr.email, '') AS usuario_email,
            coalesce(filhos.total_execucoes, 0)::integer AS total_execucoes,
            coalesce(filhos.eventos, 0)::integer AS eventos,
            coalesce(filhos.resultados, 0)::integer AS resultados,
            coalesce(filhos.atletas, 0)::integer AS atletas,
            coalesce(filhos.noticias, 0)::integer AS noticias,
            coalesce(filhos.videos, 0)::integer AS videos,
            coalesce(filhos.total_resultados, 0)::integer AS total_resultados
        FROM parent_rows p
        LEFT JOIN tb_usuarios usr ON usr.id = p.id_usuario
        LEFT JOIN LATERAL (
            SELECT
                count(*)::integer AS total_execucoes,
                sum(coalesce((c.contagens_json->>'eventos')::numeric, 0))::integer AS eventos,
                sum(coalesce((c.contagens_json->>'resultados')::numeric, 0))::integer AS resultados,
                sum(coalesce((c.contagens_json->>'atletas')::numeric, 0))::integer AS atletas,
                sum(coalesce((c.contagens_json->>'noticias')::numeric, 0))::integer AS noticias,
                sum(coalesce((c.contagens_json->>'videos')::numeric, 0))::integer AS videos,
                sum(
                    coalesce((c.contagens_json->>'eventos')::numeric, 0)
                    + coalesce((c.contagens_json->>'resultados')::numeric, 0)
                    + coalesce((c.contagens_json->>'atletas')::numeric, 0)
                    + coalesce((c.contagens_json->>'noticias')::numeric, 0)
                    + coalesce((c.contagens_json->>'videos')::numeric, 0)
                )::integer AS total_resultados
            FROM tb_busca_log c
            WHERE c.id_busca_log_parent = p.id_busca_log
        ) filhos ON true
        ORDER BY p.log_timestamp DESC, p.id_busca_log DESC
    </cfquery>

    <cfquery name="qSearchLogDaily">
        SELECT
            date_trunc('day', p.log_timestamp)::date AS dia,
            count(*)::integer AS total_buscas,
            (count(*) FILTER (WHERE p.busca_modo = 'ai' OR p.usou_ia = true))::integer AS buscas_ia,
            (count(*) FILTER (WHERE p.fallback_usado = true))::integer AS fallbacks
        FROM tb_busca_log p
        WHERE p.etapa = 'interpretacao'
          AND p.log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
        <cfif len(VARIABLES.searchLogAmbiente)>
          AND p.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
        </cfif>
        <cfif len(VARIABLES.searchLogTerm)>
          AND (
              p.termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              OR p.termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
          )
        </cfif>
        GROUP BY date_trunc('day', p.log_timestamp)::date
        ORDER BY dia DESC
        LIMIT 14
    </cfquery>

    <cfquery name="qSearchLogTopTerms">
        SELECT
            lower(trim(p.termo_original)) AS termo,
            count(*)::integer AS buscas,
            (count(*) FILTER (WHERE p.busca_modo = 'ai' OR p.usou_ia = true))::integer AS buscas_ia,
            (count(*) FILTER (WHERE p.fallback_usado = true))::integer AS fallbacks,
            max(p.log_timestamp) AS ultima_busca
        FROM tb_busca_log p
        WHERE p.etapa = 'interpretacao'
          AND nullif(trim(p.termo_original), '') IS NOT NULL
          AND p.log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
        <cfif len(VARIABLES.searchLogAmbiente)>
          AND p.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
        </cfif>
        <cfif len(VARIABLES.searchLogTerm)>
          AND (
              p.termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              OR p.termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
          )
        </cfif>
        GROUP BY lower(trim(p.termo_original))
        ORDER BY buscas DESC, ultima_busca DESC
        LIMIT 15
    </cfquery>

    <cfquery name="qSearchLogTopFilters">
        WITH base AS (
            SELECT p.filtros_json, p.log_timestamp
            FROM tb_busca_log p
            WHERE p.etapa = 'interpretacao'
              AND p.log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
            <cfif len(VARIABLES.searchLogAmbiente)>
              AND p.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
            </cfif>
            <cfif len(VARIABLES.searchLogTerm)>
              AND (
                  p.termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
                  OR p.termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              )
            </cfif>
        ),
        filtros AS (
            SELECT 'Estado' AS tipo, upper(trim(filtros_json->>'estado')) AS valor, log_timestamp
            FROM base
            WHERE nullif(trim(coalesce(filtros_json->>'estado', '')), '') IS NOT NULL

            UNION ALL

            SELECT 'Cidade' AS tipo, trim(filtros_json->>'cidade') AS valor, log_timestamp
            FROM base
            WHERE nullif(trim(coalesce(filtros_json->>'cidade', '')), '') IS NOT NULL

            UNION ALL

            SELECT 'Distancia' AS tipo, trim(coalesce(nullif(filtros_json->>'distancia_inicio', ''), nullif(filtros_json->>'distancia_fim', ''))) || ' km' AS valor, log_timestamp
            FROM base
            WHERE coalesce(nullif(filtros_json->>'distancia_inicio', ''), nullif(filtros_json->>'distancia_fim', '')) IS NOT NULL

            UNION ALL

            SELECT 'Tipo termo' AS tipo, trim(filtros_json->>'tipo_termo') AS valor, log_timestamp
            FROM base
            WHERE nullif(trim(coalesce(filtros_json->>'tipo_termo', '')), '') IS NOT NULL
        )
        SELECT
            tipo,
            valor,
            count(*)::integer AS buscas,
            max(log_timestamp) AS ultima_busca
        FROM filtros
        GROUP BY tipo, valor
        ORDER BY buscas DESC, ultima_busca DESC
        LIMIT 15
    </cfquery>

    <cfquery name="qSearchLogZeroResults">
        WITH execucoes AS (
            SELECT
                id_busca_log_parent,
                sum(coalesce((contagens_json->>'eventos')::numeric, 0))::integer AS eventos,
                sum(coalesce((contagens_json->>'resultados')::numeric, 0))::integer AS resultados,
                sum(coalesce((contagens_json->>'atletas')::numeric, 0))::integer AS atletas,
                sum(coalesce((contagens_json->>'noticias')::numeric, 0))::integer AS noticias,
                sum(coalesce((contagens_json->>'videos')::numeric, 0))::integer AS videos
            FROM tb_busca_log
            WHERE etapa = 'execucao'
            GROUP BY id_busca_log_parent
        )
        SELECT
            p.id_busca_log,
            p.log_timestamp,
            p.termo_original,
            e.eventos,
            e.resultados,
            e.atletas,
            e.noticias,
            e.videos,
            (e.eventos + e.resultados + e.atletas + e.noticias + e.videos)::integer AS total_resultados
        FROM tb_busca_log p
        INNER JOIN execucoes e ON e.id_busca_log_parent = p.id_busca_log
        WHERE p.etapa = 'interpretacao'
          AND (e.eventos + e.resultados + e.atletas + e.noticias + e.videos) = 0
          AND p.log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
        <cfif len(VARIABLES.searchLogAmbiente)>
          AND p.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
        </cfif>
        <cfif len(VARIABLES.searchLogTerm)>
          AND (
              p.termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              OR p.termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
          )
        </cfif>
        ORDER BY p.log_timestamp DESC
        LIMIT 20
    </cfquery>

    <cfquery name="qSearchLogFailures">
        SELECT
            p.id_busca_log,
            p.log_timestamp,
            p.termo_original,
            p.modelo,
            p.http_status,
            p.fallback_usado,
            p.fallback_motivo,
            p.erro
        FROM tb_busca_log p
        WHERE p.etapa = 'interpretacao'
          AND (
              p.fallback_usado = true
              OR nullif(trim(coalesce(p.erro, '')), '') IS NOT NULL
              OR coalesce(nullif(trim(p.http_status), ''), '200 OK') NOT IN ('200', '200 OK', 'OK')
          )
          AND p.log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
        <cfif len(VARIABLES.searchLogAmbiente)>
          AND p.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
        </cfif>
        <cfif len(VARIABLES.searchLogTerm)>
          AND (
              p.termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              OR p.termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
          )
        </cfif>
        ORDER BY p.log_timestamp DESC
        LIMIT 20
    </cfquery>

    <cfquery name="qSearchLogScopes">
        SELECT
            coalesce(nullif(c.busca_scope, ''), nullif(c.busca_tipo, ''), 'sem escopo') AS busca_scope,
            count(*)::integer AS execucoes,
            sum(coalesce((c.contagens_json->>'eventos')::numeric, 0))::integer AS eventos,
            sum(coalesce((c.contagens_json->>'resultados')::numeric, 0))::integer AS resultados,
            sum(coalesce((c.contagens_json->>'atletas')::numeric, 0))::integer AS atletas,
            sum(coalesce((c.contagens_json->>'noticias')::numeric, 0))::integer AS noticias,
            sum(coalesce((c.contagens_json->>'videos')::numeric, 0))::integer AS videos,
            sum(
                coalesce((c.contagens_json->>'eventos')::numeric, 0)
                + coalesce((c.contagens_json->>'resultados')::numeric, 0)
                + coalesce((c.contagens_json->>'atletas')::numeric, 0)
                + coalesce((c.contagens_json->>'noticias')::numeric, 0)
                + coalesce((c.contagens_json->>'videos')::numeric, 0)
            )::integer AS total_resultados
        FROM tb_busca_log c
        LEFT JOIN tb_busca_log p ON p.id_busca_log = c.id_busca_log_parent
        WHERE c.etapa = 'execucao'
          AND coalesce(p.log_timestamp, c.log_timestamp) >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
        <cfif len(VARIABLES.searchLogAmbiente)>
          AND coalesce(p.ambiente, c.ambiente, '') = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
        </cfif>
        <cfif len(VARIABLES.searchLogTerm)>
          AND (
              coalesce(p.termo_original, c.termo_original, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              OR coalesce(p.termo_livre, c.termo_livre, '') ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
          )
        </cfif>
        GROUP BY coalesce(nullif(c.busca_scope, ''), nullif(c.busca_tipo, ''), 'sem escopo')
        ORDER BY execucoes DESC, total_resultados DESC
        LIMIT 10
    </cfquery>

    <cfquery name="qSearchLogUsers">
        SELECT
            p.id_usuario,
            coalesce(usr.name, '') AS usuario_nome,
            coalesce(usr.email, '') AS usuario_email,
            count(*)::integer AS buscas,
            (count(*) FILTER (WHERE p.busca_modo = 'ai' OR p.usou_ia = true))::integer AS buscas_ia,
            max(p.log_timestamp) AS ultima_busca
        FROM tb_busca_log p
        LEFT JOIN tb_usuarios usr ON usr.id = p.id_usuario
        WHERE p.etapa = 'interpretacao'
          AND p.id_usuario IS NOT NULL
          AND p.log_timestamp >= now() - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchLogDays#"/> * interval '1 day')
        <cfif len(VARIABLES.searchLogAmbiente)>
          AND p.ambiente = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.searchLogAmbiente#"/>
        </cfif>
        <cfif len(VARIABLES.searchLogTerm)>
          AND (
              p.termo_original ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
              OR p.termo_livre ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchLogTerm#%"/>
          )
        </cfif>
        GROUP BY p.id_usuario, usr.name, usr.email
        ORDER BY buscas DESC, ultima_busca DESC
        LIMIT 10
    </cfquery>

    <cfif len(trim(URL.busca_id)) AND isNumeric(URL.busca_id)>
        <cfset VARIABLES.searchLogDetailId = val(URL.busca_id)/>

        <cfquery name="qSearchLogDetailParent">
            SELECT
                p.*,
                coalesce(usr.name, '') AS usuario_nome,
                coalesce(usr.email, '') AS usuario_email
            FROM tb_busca_log p
            LEFT JOIN tb_usuarios usr ON usr.id = p.id_usuario
            WHERE p.id_busca_log = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.searchLogDetailId#"/>
            LIMIT 1
        </cfquery>

        <cfif qSearchLogDetailParent.recordcount>
            <cfquery name="qSearchLogDetailChildren">
                SELECT *
                FROM tb_busca_log
                WHERE id_busca_log_parent = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qSearchLogDetailParent.id_busca_log#"/>
                ORDER BY id_busca_log
            </cfquery>
        </cfif>
    </cfif>
</cfif>
