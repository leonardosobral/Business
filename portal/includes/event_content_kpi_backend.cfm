<cfscript>
function eventContentKpiPercent(value, total) {
    if (val(arguments.total) LTE 0) {
        return 0;
    }

    return (val(arguments.value) * 100) / val(arguments.total);
}

function eventContentKpiFormatDate(value) {
    if (NOT isDate(arguments.value)) {
        return "";
    }

    return dateFormat(arguments.value, "dd/mm/yyyy");
}

function eventContentKpiShortText(value, numeric lengthLimit = 140) {
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

<cfparam name="URL.ano" default=""/>
<cfparam name="URL.recorte" default="futuros"/>
<cfparam name="URL.situacao" default="ativos"/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.falta" default="incompletos"/>
<cfparam name="URL.busca" default=""/>

<cfset VARIABLES.eventContentKpiCurrentYear = year(now())/>
<cfset VARIABLES.eventContentKpiYear = int(val(URL.ano))/>
<cfif VARIABLES.eventContentKpiYear LT 2020 OR VARIABLES.eventContentKpiYear GT (VARIABLES.eventContentKpiCurrentYear + 3)>
    <cfset VARIABLES.eventContentKpiYear = VARIABLES.eventContentKpiCurrentYear/>
</cfif>

<cfset VARIABLES.eventContentKpiStartDate = createDate(VARIABLES.eventContentKpiYear, 1, 1)/>
<cfset VARIABLES.eventContentKpiEndDate = createDate(VARIABLES.eventContentKpiYear, 12, 31)/>
<cfset VARIABLES.eventContentKpiToday = createDate(year(now()), month(now()), day(now()))/>

<cfset VARIABLES.eventContentKpiRecorte = lCase(trim(URL.recorte))/>
<cfif NOT listFindNoCase("futuros,ano,passados", VARIABLES.eventContentKpiRecorte)>
    <cfset VARIABLES.eventContentKpiRecorte = "futuros"/>
</cfif>

<cfset VARIABLES.eventContentKpiSituacao = lCase(trim(URL.situacao))/>
<cfif NOT listFindNoCase("ativos,todos,inativos", VARIABLES.eventContentKpiSituacao)>
    <cfset VARIABLES.eventContentKpiSituacao = "ativos"/>
</cfif>

<cfset VARIABLES.eventContentKpiEstado = uCase(trim(URL.estado))/>
<cfif len(VARIABLES.eventContentKpiEstado) GT 2>
    <cfset VARIABLES.eventContentKpiEstado = left(VARIABLES.eventContentKpiEstado, 2)/>
</cfif>

<cfset VARIABLES.eventContentKpiMissingFilter = lCase(trim(URL.falta))/>
<cfif NOT listFindNoCase("incompletos,todos,descricao,inscricao,categorias,organizador,local,endereco,imagem", VARIABLES.eventContentKpiMissingFilter)>
    <cfset VARIABLES.eventContentKpiMissingFilter = "incompletos"/>
</cfif>

<cfset VARIABLES.eventContentKpiSearch = trim(URL.busca)/>
<cfset VARIABLES.eventContentKpiRequiredFields = 7/>
<cfset VARIABLES.eventContentKpiStats = {
    total = 0,
    completos = 0,
    incompletos = 0,
    criticos = 0,
    proximos30 = 0,
    completudeMedia = 0,
    descricao = 0,
    inscricao = 0,
    categorias = 0,
    organizador = 0,
    local = 0,
    endereco = 0,
    imagem = 0
}/>
<cfset VARIABLES.eventContentKpiAttackTotal = 0/>

<cfset VARIABLES.eventContentKpiEventColumns = "id_evento,nome_evento,cidade,estado,tag,data_inicial,data_final,status_evento,ativo,url_inscricao,url_hotsite,organizador_label,has_descricao,has_inscricao,has_categorias,has_organizador,has_local,has_endereco,has_imagem,required_count,missing_count,completude,faltando,dias_ate_evento"/>

<cfset qEventContentKpiYears = queryNew("ano")/>
<cfset qEventContentKpiStates = queryNew("estado")/>
<cfset qEventContentKpiEvents = queryNew(VARIABLES.eventContentKpiEventColumns)/>
<cfset qEventContentKpiAttack = queryNew(VARIABLES.eventContentKpiEventColumns)/>
<cfset qEventContentKpiFields = queryNew("campo,total_ok,total_missing,percentual")/>
<cfset qEventContentKpiByState = queryNew("estado,total,incompletos,completude_media")/>
<cfset qEventContentKpiByMonth = queryNew("mes_key,mes,total,incompletos,completude_media")/>

<cfquery name="qEventContentKpiTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_name IN ('tb_evento_corridas', 'tb_evento_corridas_fornecedores')
      AND table_schema IN (current_schema(), 'public')
</cfquery>

<cfset VARIABLES.eventContentKpiTablesList = ValueList(qEventContentKpiTables.table_name)/>
<cfset VARIABLES.eventContentKpiTablesReady = ListFindNoCase(VARIABLES.eventContentKpiTablesList, "tb_evento_corridas")/>
<cfset VARIABLES.eventContentKpiHasFornecedorTable = ListFindNoCase(VARIABLES.eventContentKpiTablesList, "tb_evento_corridas_fornecedores")/>

<cfif VARIABLES.eventContentKpiTablesReady
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin>

    <cfquery name="qEventContentKpiYears">
        SELECT DISTINCT extract(year from data_inicial)::integer AS ano
        FROM tb_evento_corridas
        WHERE data_inicial IS NOT NULL
          AND extract(year from data_inicial)::integer BETWEEN <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventContentKpiCurrentYear - 2#"/>
              AND <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventContentKpiCurrentYear + 3#"/>
        ORDER BY ano DESC
    </cfquery>

    <cfquery name="qEventContentKpiStates">
        SELECT DISTINCT estado
        FROM tb_evento_corridas
        WHERE estado IS NOT NULL
          AND trim(estado) <> ''
        ORDER BY estado
    </cfquery>

    <cfquery name="qEventContentKpiEvents">
        WITH enriched AS (
            SELECT
                evt.id_evento,
                evt.nome_evento,
                coalesce(evt.cidade, '') AS cidade,
                coalesce(evt.estado, '') AS estado,
                coalesce(evt.tag, '') AS tag,
                evt.data_inicial,
                evt.data_final,
                coalesce(evt.status_evento, '') AS status_evento,
                evt.ativo,
                coalesce(evt.url_inscricao, '') AS url_inscricao,
                coalesce(evt.url_hotsite, '') AS url_hotsite,
                CASE
                    WHEN length(trim(coalesce(evt.organizador, ''))) > 0 THEN evt.organizador
                    WHEN coalesce(org.total_organizadores, 0) > 0 THEN coalesce(org.total_organizadores, 0)::varchar || ' fornecedor(es)'
                    ELSE ''
                END AS organizador_label,
                CASE WHEN length(trim(coalesce(evt.descricao, ''))) > 0 THEN 1 ELSE 0 END AS has_descricao,
                CASE WHEN length(trim(coalesce(evt.url_inscricao, ''))) > 0 THEN 1 ELSE 0 END AS has_inscricao,
                CASE WHEN length(trim(coalesce(evt.categorias, ''))) > 0 THEN 1 ELSE 0 END AS has_categorias,
                CASE WHEN length(trim(coalesce(evt.organizador, ''))) > 0 OR coalesce(org.total_organizadores, 0) > 0 THEN 1 ELSE 0 END AS has_organizador,
                CASE WHEN length(trim(coalesce(evt.cidade, ''))) > 0 AND length(trim(coalesce(evt.estado, ''))) > 0 THEN 1 ELSE 0 END AS has_local,
                CASE WHEN length(trim(coalesce(evt.endereco, ''))) > 0 THEN 1 ELSE 0 END AS has_endereco,
                CASE
                    WHEN length(trim(coalesce(evt.imagem, ''))) > 0 THEN 1
                    WHEN length(trim(coalesce(evt.url_imagem, ''))) > 0 THEN 1
                    WHEN length(trim(coalesce(evt.url_imagem_listagem, ''))) > 0 THEN 1
                    ELSE 0
                END AS has_imagem
            FROM tb_evento_corridas evt
            <cfif VARIABLES.eventContentKpiHasFornecedorTable>
                LEFT JOIN LATERAL (
                    SELECT count(*)::integer AS total_organizadores
                    FROM tb_evento_corridas_fornecedores forn
                    WHERE forn.id_evento = evt.id_evento
                      AND forn.id_fornecedor_tipo = 1
                ) org ON true
            <cfelse>
                LEFT JOIN LATERAL (
                    SELECT 0::integer AS total_organizadores
                ) org ON true
            </cfif>
            WHERE evt.data_inicial BETWEEN <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.eventContentKpiStartDate#"/>
                AND <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.eventContentKpiEndDate#"/>
            <cfif VARIABLES.eventContentKpiRecorte EQ "futuros">
              AND evt.data_final >= current_date
            <cfelseif VARIABLES.eventContentKpiRecorte EQ "passados">
              AND evt.data_final < current_date
            </cfif>
            <cfif VARIABLES.eventContentKpiSituacao EQ "ativos">
              AND evt.ativo = true
            <cfelseif VARIABLES.eventContentKpiSituacao EQ "inativos">
              AND evt.ativo = false
            </cfif>
            <cfif len(VARIABLES.eventContentKpiEstado)>
              AND evt.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.eventContentKpiEstado#"/>
            </cfif>
            <cfif len(VARIABLES.eventContentKpiSearch)>
              AND (
                  evt.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventContentKpiSearch#%"/>
                  OR evt.tag ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventContentKpiSearch#%"/>
                  OR evt.cidade ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventContentKpiSearch#%"/>
                  OR evt.organizador ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.eventContentKpiSearch#%"/>
              )
            </cfif>
        ),
        scored AS (
            SELECT
                enriched.*,
                (has_descricao + has_inscricao + has_categorias + has_organizador + has_local + has_endereco + has_imagem)::integer AS required_count,
                (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventContentKpiRequiredFields#"/> - (has_descricao + has_inscricao + has_categorias + has_organizador + has_local + has_endereco + has_imagem))::integer AS missing_count,
                round(((has_descricao + has_inscricao + has_categorias + has_organizador + has_local + has_endereco + has_imagem)::numeric * 100) / <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.eventContentKpiRequiredFields#"/>, 1) AS completude,
                concat_ws(', ',
                    CASE WHEN has_descricao = 0 THEN 'Descricao' END,
                    CASE WHEN has_inscricao = 0 THEN 'Link inscricao' END,
                    CASE WHEN has_categorias = 0 THEN 'Categorias' END,
                    CASE WHEN has_organizador = 0 THEN 'Organizador' END,
                    CASE WHEN has_local = 0 THEN 'Local' END,
                    CASE WHEN has_endereco = 0 THEN 'Endereco' END,
                    CASE WHEN has_imagem = 0 THEN 'Imagem' END
                ) AS faltando,
                (data_inicial - current_date)::integer AS dias_ate_evento
            FROM enriched
        )
        SELECT *
        FROM scored
        ORDER BY data_inicial ASC, missing_count DESC, nome_evento
        LIMIT 5000
    </cfquery>

    <cfscript>
    VARIABLES.eventContentKpiStats.total = qEventContentKpiEvents.recordcount;
    VARIABLES.eventContentKpiStateStats = {};
    VARIABLES.eventContentKpiMonthStats = {};

    for (rowIndex = 1; rowIndex <= qEventContentKpiEvents.recordcount; rowIndex = rowIndex + 1) {
        rowMissing = val(qEventContentKpiEvents.missing_count[rowIndex]);
        rowRequired = val(qEventContentKpiEvents.required_count[rowIndex]);
        rowDate = qEventContentKpiEvents.data_inicial[rowIndex];

        VARIABLES.eventContentKpiStats.descricao = VARIABLES.eventContentKpiStats.descricao + val(qEventContentKpiEvents.has_descricao[rowIndex]);
        VARIABLES.eventContentKpiStats.inscricao = VARIABLES.eventContentKpiStats.inscricao + val(qEventContentKpiEvents.has_inscricao[rowIndex]);
        VARIABLES.eventContentKpiStats.categorias = VARIABLES.eventContentKpiStats.categorias + val(qEventContentKpiEvents.has_categorias[rowIndex]);
        VARIABLES.eventContentKpiStats.organizador = VARIABLES.eventContentKpiStats.organizador + val(qEventContentKpiEvents.has_organizador[rowIndex]);
        VARIABLES.eventContentKpiStats.local = VARIABLES.eventContentKpiStats.local + val(qEventContentKpiEvents.has_local[rowIndex]);
        VARIABLES.eventContentKpiStats.endereco = VARIABLES.eventContentKpiStats.endereco + val(qEventContentKpiEvents.has_endereco[rowIndex]);
        VARIABLES.eventContentKpiStats.imagem = VARIABLES.eventContentKpiStats.imagem + val(qEventContentKpiEvents.has_imagem[rowIndex]);

        if (rowMissing EQ 0) {
            VARIABLES.eventContentKpiStats.completos = VARIABLES.eventContentKpiStats.completos + 1;
        } else {
            VARIABLES.eventContentKpiStats.incompletos = VARIABLES.eventContentKpiStats.incompletos + 1;
        }

        if (rowMissing GTE 3) {
            VARIABLES.eventContentKpiStats.criticos = VARIABLES.eventContentKpiStats.criticos + 1;
        }

        if (isDate(rowDate)
            AND dateCompare(rowDate, VARIABLES.eventContentKpiToday) GTE 0
            AND dateCompare(rowDate, dateAdd("d", 30, VARIABLES.eventContentKpiToday)) LTE 0
            AND rowMissing GT 0) {
            VARIABLES.eventContentKpiStats.proximos30 = VARIABLES.eventContentKpiStats.proximos30 + 1;
        }

        if (len(trim(qEventContentKpiEvents.estado[rowIndex] & ""))) {
            stateKey = qEventContentKpiEvents.estado[rowIndex];
        } else {
            stateKey = "Sem UF";
        }

        if (NOT structKeyExists(VARIABLES.eventContentKpiStateStats, stateKey)) {
            VARIABLES.eventContentKpiStateStats[stateKey] = {estado = stateKey, total = 0, incompletos = 0, required = 0};
        }
        VARIABLES.eventContentKpiStateStats[stateKey].total = VARIABLES.eventContentKpiStateStats[stateKey].total + 1;
        VARIABLES.eventContentKpiStateStats[stateKey].required = VARIABLES.eventContentKpiStateStats[stateKey].required + rowRequired;
        if (rowMissing GT 0) {
            VARIABLES.eventContentKpiStateStats[stateKey].incompletos = VARIABLES.eventContentKpiStateStats[stateKey].incompletos + 1;
        }

        if (isDate(rowDate)) {
            monthKey = dateFormat(rowDate, "yyyy-mm");
            if (NOT structKeyExists(VARIABLES.eventContentKpiMonthStats, monthKey)) {
                VARIABLES.eventContentKpiMonthStats[monthKey] = {mesKey = monthKey, mes = dateFormat(rowDate, "mm/yyyy"), total = 0, incompletos = 0, required = 0};
            }
            VARIABLES.eventContentKpiMonthStats[monthKey].total = VARIABLES.eventContentKpiMonthStats[monthKey].total + 1;
            VARIABLES.eventContentKpiMonthStats[monthKey].required = VARIABLES.eventContentKpiMonthStats[monthKey].required + rowRequired;
            if (rowMissing GT 0) {
                VARIABLES.eventContentKpiMonthStats[monthKey].incompletos = VARIABLES.eventContentKpiMonthStats[monthKey].incompletos + 1;
            }
        }

    }

    if (VARIABLES.eventContentKpiStats.total GT 0) {
        VARIABLES.eventContentKpiStats.completudeMedia = (
            VARIABLES.eventContentKpiStats.descricao
            + VARIABLES.eventContentKpiStats.inscricao
            + VARIABLES.eventContentKpiStats.categorias
            + VARIABLES.eventContentKpiStats.organizador
            + VARIABLES.eventContentKpiStats.local
            + VARIABLES.eventContentKpiStats.endereco
            + VARIABLES.eventContentKpiStats.imagem
        ) * 100 / (VARIABLES.eventContentKpiStats.total * VARIABLES.eventContentKpiRequiredFields);
    }

    VARIABLES.eventContentKpiFieldRows = [
        {campo = "Descricao", ok = VARIABLES.eventContentKpiStats.descricao},
        {campo = "Link inscricao", ok = VARIABLES.eventContentKpiStats.inscricao},
        {campo = "Categorias", ok = VARIABLES.eventContentKpiStats.categorias},
        {campo = "Organizador", ok = VARIABLES.eventContentKpiStats.organizador},
        {campo = "Local", ok = VARIABLES.eventContentKpiStats.local},
        {campo = "Endereco", ok = VARIABLES.eventContentKpiStats.endereco},
        {campo = "Imagem", ok = VARIABLES.eventContentKpiStats.imagem}
    ];

    for (fieldIndex = 1; fieldIndex <= arrayLen(VARIABLES.eventContentKpiFieldRows); fieldIndex = fieldIndex + 1) {
        fieldRow = VARIABLES.eventContentKpiFieldRows[fieldIndex];
        queryAddRow(qEventContentKpiFields, 1);
        querySetCell(qEventContentKpiFields, "campo", fieldRow.campo);
        querySetCell(qEventContentKpiFields, "total_ok", fieldRow.ok);
        querySetCell(qEventContentKpiFields, "total_missing", VARIABLES.eventContentKpiStats.total - fieldRow.ok);
        querySetCell(qEventContentKpiFields, "percentual", eventContentKpiPercent(fieldRow.ok, VARIABLES.eventContentKpiStats.total));
    }

    VARIABLES.eventContentKpiStateKeys = structKeyArray(VARIABLES.eventContentKpiStateStats);
    for (stateIndex = 1; stateIndex <= arrayLen(VARIABLES.eventContentKpiStateKeys); stateIndex = stateIndex + 1) {
        stateKey = VARIABLES.eventContentKpiStateKeys[stateIndex];
        stateItem = VARIABLES.eventContentKpiStateStats[stateKey];
        queryAddRow(qEventContentKpiByState, 1);
        querySetCell(qEventContentKpiByState, "estado", stateItem.estado);
        querySetCell(qEventContentKpiByState, "total", stateItem.total);
        querySetCell(qEventContentKpiByState, "incompletos", stateItem.incompletos);
        querySetCell(qEventContentKpiByState, "completude_media", eventContentKpiPercent(stateItem.required, stateItem.total * VARIABLES.eventContentKpiRequiredFields));
    }

    VARIABLES.eventContentKpiMonthKeys = structKeyArray(VARIABLES.eventContentKpiMonthStats);
    for (monthIndex = 1; monthIndex <= arrayLen(VARIABLES.eventContentKpiMonthKeys); monthIndex = monthIndex + 1) {
        monthKey = VARIABLES.eventContentKpiMonthKeys[monthIndex];
        monthItem = VARIABLES.eventContentKpiMonthStats[monthKey];
        queryAddRow(qEventContentKpiByMonth, 1);
        querySetCell(qEventContentKpiByMonth, "mes_key", monthItem.mesKey);
        querySetCell(qEventContentKpiByMonth, "mes", monthItem.mes);
        querySetCell(qEventContentKpiByMonth, "total", monthItem.total);
        querySetCell(qEventContentKpiByMonth, "incompletos", monthItem.incompletos);
        querySetCell(qEventContentKpiByMonth, "completude_media", eventContentKpiPercent(monthItem.required, monthItem.total * VARIABLES.eventContentKpiRequiredFields));
    }
    </cfscript>

    <cfquery name="qEventContentKpiAttackAll" dbtype="query">
        SELECT *
        FROM qEventContentKpiEvents
        WHERE 1 = 1
        <cfif VARIABLES.eventContentKpiMissingFilter EQ "incompletos">
            AND missing_count > 0
        <cfelseif VARIABLES.eventContentKpiMissingFilter EQ "descricao">
            AND has_descricao = 0
        <cfelseif VARIABLES.eventContentKpiMissingFilter EQ "inscricao">
            AND has_inscricao = 0
        <cfelseif VARIABLES.eventContentKpiMissingFilter EQ "categorias">
            AND has_categorias = 0
        <cfelseif VARIABLES.eventContentKpiMissingFilter EQ "organizador">
            AND has_organizador = 0
        <cfelseif VARIABLES.eventContentKpiMissingFilter EQ "local">
            AND has_local = 0
        <cfelseif VARIABLES.eventContentKpiMissingFilter EQ "endereco">
            AND has_endereco = 0
        <cfelseif VARIABLES.eventContentKpiMissingFilter EQ "imagem">
            AND has_imagem = 0
        </cfif>
        ORDER BY data_inicial ASC, missing_count DESC, nome_evento
    </cfquery>

    <cfset VARIABLES.eventContentKpiAttackTotal = qEventContentKpiAttackAll.recordcount/>

    <cfquery name="qEventContentKpiAttack" dbtype="query" maxrows="100">
        SELECT *
        FROM qEventContentKpiAttackAll
        ORDER BY data_inicial ASC, missing_count DESC, nome_evento
    </cfquery>

    <cfquery name="qEventContentKpiFieldsSorted" dbtype="query">
        SELECT *
        FROM qEventContentKpiFields
        ORDER BY total_missing DESC, campo
    </cfquery>

    <cfquery name="qEventContentKpiByStateSorted" dbtype="query" maxrows="20">
        SELECT *
        FROM qEventContentKpiByState
        ORDER BY incompletos DESC, total DESC, estado
    </cfquery>

    <cfquery name="qEventContentKpiByMonthSorted" dbtype="query">
        SELECT *
        FROM qEventContentKpiByMonth
        ORDER BY mes_key
    </cfquery>
<cfelse>
    <cfset qEventContentKpiFieldsSorted = qEventContentKpiFields/>
    <cfset qEventContentKpiByStateSorted = qEventContentKpiByState/>
    <cfset qEventContentKpiByMonthSorted = qEventContentKpiByMonth/>
</cfif>
