<cfprocessingdirective pageencoding="utf-8"/>

<cfparam name="URL.busca" default=""/>
<cfparam name="URL.cod_evento" default=""/>
<cfparam name="URL.id_evento" default=""/>
<cfparam name="URL.ano_evento" default=""/>
<cfparam name="URL.percurso" default=""/>
<cfparam name="URL.status" default=""/>
<cfparam name="URL.uf" default=""/>
<cfparam name="URL.correu" default=""/>
<cfparam name="URL.vinculo" default=""/>
<cfparam name="URL.id_conta" default=""/>
<cfparam name="URL.pagina" default="1"/>

<cfscript>
    VARIABLES.crmSchema = "crm";
    VARIABLES.crmRequiredObjects = "tb_crm_evento_series,tb_crm_evento_versoes,tb_crm_conta_evento_versoes,tb_crm_importacoes,tb_crm_pessoas,tb_crm_pedidos,tb_crm_participacoes,vw_crm_participacoes";
    VARIABLES.crmBusca = trim(URL.busca);
    VARIABLES.crmCodEvento = trim(URL.cod_evento);
    VARIABLES.crmIdEventoFiltro = trim(URL.id_evento);
    VARIABLES.crmAnoEvento = trim(URL.ano_evento);
    VARIABLES.crmPercurso = trim(URL.percurso);
    VARIABLES.crmStatus = trim(URL.status);
    VARIABLES.crmUf = uCase(trim(URL.uf));
    VARIABLES.crmCorreu = lCase(trim(URL.correu));
    VARIABLES.crmVinculo = lCase(trim(URL.vinculo));
    VARIABLES.crmIdConta = trim(URL.id_conta);
    VARIABLES.crmPagina = max(1, int(val(URL.pagina)));
    VARIABLES.crmPorPagina = 25;
    VARIABLES.crmOffset = (VARIABLES.crmPagina - 1) * VARIABLES.crmPorPagina;
    VARIABLES.crmEffectiveIsAdmin = false;
    VARIABLES.crmCanOperate = false;
    VARIABLES.crmEffectiveAccountIds = "";
    VARIABLES.crmOperatorAccountIds = "";
    VARIABLES.crmAccountFilterIds = "";
    VARIABLES.crmNotice = "";
    VARIABLES.crmError = "";

    if (isDefined("VARIABLES.businessEffectiveIsAdmin") AND isBoolean(VARIABLES.businessEffectiveIsAdmin)) {
        VARIABLES.crmEffectiveIsAdmin = VARIABLES.businessEffectiveIsAdmin;
    }

    if (isDefined("VARIABLES.businessEffectiveAccountIds") AND len(trim(VARIABLES.businessEffectiveAccountIds)) AND VARIABLES.businessEffectiveAccountIds NEQ "0") {
        VARIABLES.crmEffectiveAccountIds = VARIABLES.businessEffectiveAccountIds;
    }

    if (isDefined("VARIABLES.businessEffectiveAccountOperatorIds") AND len(trim(VARIABLES.businessEffectiveAccountOperatorIds)) AND VARIABLES.businessEffectiveAccountOperatorIds NEQ "0") {
        VARIABLES.crmOperatorAccountIds = VARIABLES.businessEffectiveAccountOperatorIds;
    }

    if (NOT VARIABLES.crmEffectiveIsAdmin AND NOT len(VARIABLES.crmEffectiveAccountIds)) {
        VARIABLES.crmEffectiveAccountIds = "0";
    }

    if (NOT len(VARIABLES.crmOperatorAccountIds)) {
        VARIABLES.crmOperatorAccountIds = "0";
    }

    VARIABLES.crmCanOperate = VARIABLES.crmEffectiveIsAdmin OR (len(VARIABLES.crmOperatorAccountIds) GT 0 AND VARIABLES.crmOperatorAccountIds NEQ "0");

    if (len(VARIABLES.crmAnoEvento) AND NOT isNumeric(VARIABLES.crmAnoEvento)) {
        VARIABLES.crmAnoEvento = "";
    }

    if (len(VARIABLES.crmPercurso) AND NOT isNumeric(VARIABLES.crmPercurso)) {
        VARIABLES.crmPercurso = "";
    }

    if (len(VARIABLES.crmCorreu) AND NOT listFindNoCase("sim,nao", VARIABLES.crmCorreu)) {
        VARIABLES.crmCorreu = "";
    }

    if (len(VARIABLES.crmVinculo) AND NOT listFindNoCase("com_usuario,sem_usuario", VARIABLES.crmVinculo)) {
        VARIABLES.crmVinculo = "";
    }

    if (len(VARIABLES.crmIdConta) AND NOT isNumeric(VARIABLES.crmIdConta)) {
        VARIABLES.crmIdConta = "";
    }

    if (len(VARIABLES.crmIdEventoFiltro) AND NOT isNumeric(VARIABLES.crmIdEventoFiltro)) {
        VARIABLES.crmIdEventoFiltro = "";
    }

    if (VARIABLES.crmEffectiveIsAdmin) {
        VARIABLES.crmAccountFilterIds = VARIABLES.crmIdConta;
    } else if (len(VARIABLES.crmIdConta) AND listFind(VARIABLES.crmEffectiveAccountIds, VARIABLES.crmIdConta)) {
        VARIABLES.crmAccountFilterIds = VARIABLES.crmIdConta;
    } else if (len(VARIABLES.crmEffectiveAccountIds)) {
        VARIABLES.crmIdConta = "";
        VARIABLES.crmAccountFilterIds = VARIABLES.crmEffectiveAccountIds;
    } else {
        VARIABLES.crmIdConta = "";
        VARIABLES.crmAccountFilterIds = "0";
    }

    function crmQueryString(required numeric pageNumber) {
        var params = [];

        arrayAppend(params, "pagina=" & urlEncodedFormat(arguments.pageNumber));

        if (len(VARIABLES.crmBusca)) {
            arrayAppend(params, "busca=" & urlEncodedFormat(VARIABLES.crmBusca));
        }
        if (len(VARIABLES.crmIdEventoFiltro)) {
            arrayAppend(params, "id_evento=" & urlEncodedFormat(VARIABLES.crmIdEventoFiltro));
        }
        if (len(VARIABLES.crmAnoEvento)) {
            arrayAppend(params, "ano_evento=" & urlEncodedFormat(VARIABLES.crmAnoEvento));
        }
        if (len(VARIABLES.crmPercurso)) {
            arrayAppend(params, "percurso=" & urlEncodedFormat(VARIABLES.crmPercurso));
        }
        if (len(VARIABLES.crmStatus)) {
            arrayAppend(params, "status=" & urlEncodedFormat(VARIABLES.crmStatus));
        }
        if (len(VARIABLES.crmUf)) {
            arrayAppend(params, "uf=" & urlEncodedFormat(VARIABLES.crmUf));
        }
        if (len(VARIABLES.crmCorreu)) {
            arrayAppend(params, "correu=" & urlEncodedFormat(VARIABLES.crmCorreu));
        }
        if (len(VARIABLES.crmVinculo)) {
            arrayAppend(params, "vinculo=" & urlEncodedFormat(VARIABLES.crmVinculo));
        }
        if (len(VARIABLES.crmIdConta)) {
            arrayAppend(params, "id_conta=" & urlEncodedFormat(VARIABLES.crmIdConta));
        }

        return "./?" & arrayToList(params, "&");
    }

    function crmDateLabel(value) {
        if (NOT isDate(arguments.value)) {
            return "";
        }

        return dateFormat(arguments.value, "dd/mm/yyyy");
    }

    function crmDateTimeLabel(value) {
        if (NOT isDate(arguments.value)) {
            return "";
        }

        return dateTimeFormat(arguments.value, "dd/mm/yyyy HH:nn");
    }

    function crmShortText(value, numeric limit = 42) {
        var textValue = trim(arguments.value & "");

        if (len(textValue) GT arguments.limit AND arguments.limit GT 3) {
            return left(textValue, arguments.limit - 3) & "...";
        }

        return textValue;
    }

    function crmIsTruthy(value) {
        if (isBoolean(arguments.value)) {
            return arguments.value;
        }

        return listFindNoCase("true,1,yes,sim", trim(arguments.value & "")) GT 0;
    }

    function crmNormalizeHeader(value) {
        var textValue = lCase(trim(arguments.value & ""));

        textValue = replaceList(textValue, "á,à,ã,â,ä,é,è,ê,ë,í,ì,î,ï,ó,ò,õ,ô,ö,ú,ù,û,ü,ç,ñ", "a,a,a,a,a,e,e,e,e,i,i,i,i,o,o,o,o,o,u,u,u,u,c,n");
        textValue = reReplace(textValue, "[^a-z0-9]+", "_", "all");
        textValue = reReplace(textValue, "^_+|_+$", "", "all");

        return textValue;
    }

    function crmNormalizeSexo(value) {
        var originalValue = trim(arguments.value & "");
        var key = "";

        if (NOT len(originalValue)) {
            return "";
        }

        key = replace(crmNormalizeHeader(originalValue), "_", "", "all");

        if (NOT len(key) OR listFindNoCase("na,n/a,ni,naoinformado,naodeclarado,semresposta", key)) {
            return "";
        }

        if (listFindNoCase("m,masc,masculino,male,homem", key)) {
            return "M";
        }

        if (listFindNoCase("f,fem,feminino,female,mulher", key)) {
            return "F";
        }

        if (listFindNoCase("x,outro,outros,outra,naobinario,naobinaria,nonbinary,nb,diverso,diversa", key)) {
            return "X";
        }

        return "";
    }

    function crmSexoAvisos(value, normalizedValue) {
        var originalValue = trim(arguments.value & "");
        var normalized = trim(arguments.normalizedValue & "");
        var warnings = [];

        if (NOT len(originalValue)) {
            return warnings;
        }

        if (len(normalized) AND uCase(originalValue) NEQ normalized) {
            arrayAppend(warnings, "Sexo normalizado: " & originalValue & " -> " & normalized);
        } else if (NOT len(normalized)) {
            arrayAppend(warnings, "Sexo não reconhecido: " & originalValue);
        }

        return warnings;
    }

    function crmFieldForHeader(value) {
        var key = crmNormalizeHeader(arguments.value);
        var compact = replace(key, "_", "", "all");

        if (listFind("nome,nomecompleto,nomeatleta,atletainscrito,atleta,participante", compact)) {
            return "nome";
        }
        if (listFind("email,emailcadastro,emailatleta", compact)) {
            return "email";
        }
        if (listFind("cpf,documento,doc,numerodocumento", compact)) {
            return "documento";
        }
        if (listFind("tipodocumento,tipodedocumento,tipodoc", compact)) {
            return "tipo_documento";
        }
        if (listFind("nascimento,datanascimento,datadenascimento,datanasc,datadenasc,dn", compact)) {
            return "data_nascimento";
        }
        if (listFind("sexo,genero", compact)) {
            return "sexo";
        }
        if (listFind("telefone,celular,fone,whatsapp", compact)) {
            return "telefone";
        }
        if (listFind("cidade,municipio", compact)) {
            return "cidade";
        }
        if (listFind("estado,uf", compact)) {
            return "estado";
        }
        if (listFind("pais,paiscadastro", compact)) {
            return "pais";
        }
        if (listFind("numero,numeral,numeroinscricao,numerodeinscricao,ninscricao,inscricao,numerodainscricao", compact)) {
            return "numero_inscricao";
        }
        if (listFind("pedido,npedido,numeropedido,numerodopedido,ordemdopedido", compact)) {
            return "numero_pedido";
        }
        if (listFind("protocolo", compact)) {
            return "protocolo";
        }
        if (listFind("peito,numerodepeito,numerolargada,numerolargadaatleta", compact)) {
            return "numero_peito";
        }
        if (listFind("percurso,distancia,dist", compact)) {
            return "percurso";
        }
        if (listFind("modalidade,produto,submodalidade,prova", compact)) {
            return "modalidade";
        }
        if (listFind("categoria,grupocategoria,categoriaprincipal,faixaetaria", compact)) {
            return "categoria";
        }
        if (listFind("status,situacao,statuspedido,detalhestatuspedido,statusinscricao", compact)) {
            return "status";
        }
        if (listFind("origem,canal", compact)) {
            return "origem";
        }
        if (listFind("campanha", compact)) {
            return "campanha";
        }
        if (listFind("cupom,codigocupom,titulocupom", compact)) {
            return "cupom";
        }
        if (listFind("camiseta,tamanho", compact)) {
            return "camiseta";
        }
        if (listFind("assessoria,equipe,grupoassessoria,nomeequipe,nomedaequipe,nomedogrupo", compact)) {
            return "assessoria";
        }
        if (listFind("data,datapedido,datainscricao", compact)) {
            return "data_pedido";
        }
        if (listFind("datapagamento,datadepagamento", compact)) {
            return "data_pagamento";
        }
        if (listFind("valor,valorunitario,preco", compact)) {
            return "valor";
        }

        return "";
    }

    function crmParseCsvLine(required string line, string delimiter = ",") {
        var values = [];
        var current = "";
        var inQuotes = false;
        var i = 1;
        var ch = "";
        var nextCh = "";
        var quoteChar = chr(34);

        while (i LTE len(arguments.line)) {
            ch = mid(arguments.line, i, 1);
            nextCh = "";
            if (i LT len(arguments.line)) {
                nextCh = mid(arguments.line, i + 1, 1);
            }

            if (ch EQ quoteChar) {
                if (inQuotes AND nextCh EQ quoteChar) {
                    current &= quoteChar;
                    i += 2;
                    continue;
                }
                inQuotes = NOT inQuotes;
            } else if (ch EQ arguments.delimiter AND NOT inQuotes) {
                arrayAppend(values, current);
                current = "";
            } else {
                current &= ch;
            }

            i++;
        }

        arrayAppend(values, current);
        return values;
    }

    function crmReadCsvToQuery(required string filePath) {
        var content = "";
        var lines = [];
        var parsed = [];
        var maxCols = 0;
        var cols = [];
        var q = "";
        var rowValues = [];
        var rowIndex = 0;
        var colIndex = 0;
        var delimiter = ",";
        var commaCols = 0;
        var semicolonCols = 0;
        var tabCols = 0;

        try {
            content = fileRead(arguments.filePath, "utf-8");
        } catch (any csvUtfReadError) {
            content = fileRead(arguments.filePath, "windows-1252");
        }

        content = replace(content, chr(13) & chr(10), chr(10), "all");
        content = replace(content, chr(13), chr(10), "all");
        lines = listToArray(content, chr(10), true);

        for (rowIndex = 1; rowIndex LTE arrayLen(lines); rowIndex++) {
            if (len(trim(lines[rowIndex]))) {
                commaCols = arrayLen(crmParseCsvLine(lines[rowIndex], ","));
                semicolonCols = arrayLen(crmParseCsvLine(lines[rowIndex], ";"));
                tabCols = arrayLen(crmParseCsvLine(lines[rowIndex], chr(9)));

                if (semicolonCols GT commaCols AND semicolonCols GTE tabCols) {
                    delimiter = ";";
                } else if (tabCols GT commaCols AND tabCols GT semicolonCols) {
                    delimiter = chr(9);
                }

                break;
            }
        }

        for (rowIndex = 1; rowIndex LTE arrayLen(lines); rowIndex++) {
            if (len(trim(lines[rowIndex]))) {
                rowValues = crmParseCsvLine(lines[rowIndex], delimiter);
                arrayAppend(parsed, rowValues);
                maxCols = max(maxCols, arrayLen(rowValues));
            }
        }

        for (colIndex = 1; colIndex LTE maxCols; colIndex++) {
            arrayAppend(cols, "col_" & colIndex);
        }

        if (arrayLen(cols) EQ 0) {
            return queryNew("col_1");
        }

        q = queryNew(arrayToList(cols));

        for (rowIndex = 1; rowIndex LTE arrayLen(parsed); rowIndex++) {
            queryAddRow(q, 1);
            for (colIndex = 1; colIndex LTE maxCols; colIndex++) {
                if (colIndex LTE arrayLen(parsed[rowIndex])) {
                    querySetCell(q, cols[colIndex], parsed[rowIndex][colIndex], rowIndex);
                } else {
                    querySetCell(q, cols[colIndex], "", rowIndex);
                }
            }
        }

        return q;
    }

    function crmColumnOrdinal(required string columnName, required numeric fallback) {
        var suffix = reReplace(arguments.columnName, "^.*?([0-9]+)$", "\1");
        var letter = uCase(trim(arguments.columnName));

        if (isNumeric(suffix)) {
            return val(suffix);
        }

        if (len(letter) EQ 1 AND asc(letter) GTE asc("A") AND asc(letter) LTE asc("Z")) {
            return asc(letter) - asc("A") + 1;
        }

        return 100000 + arguments.fallback;
    }

    function crmExcelColumnNumber(required string columnReference) {
        var textValue = uCase(trim(arguments.columnReference & ""));
        var indexValue = 0;
        var charCode = 0;
        var i = 0;

        if (NOT reFind("^[A-Z]+$", textValue)) {
            return 0;
        }

        for (i = 1; i LTE len(textValue); i++) {
            charCode = asc(mid(textValue, i, 1)) - asc("A") + 1;
            indexValue = (indexValue * 26) + charCode;
        }

        return indexValue;
    }

    function crmQueryColumns(required query data) {
        var rawColumns = listToArray(arguments.data.columnList);
        var orderedColumns = [];
        var usedIndexes = structNew();
        var bestIndex = 0;
        var bestScore = 0;
        var currentScore = 0;
        var i = 0;

        while (arrayLen(orderedColumns) LT arrayLen(rawColumns)) {
            bestIndex = 0;
            bestScore = 999999999;

            for (i = 1; i LTE arrayLen(rawColumns); i++) {
                if (NOT structKeyExists(usedIndexes, i)) {
                    currentScore = crmColumnOrdinal(rawColumns[i], i);
                    if (currentScore LT bestScore) {
                        bestScore = currentScore;
                        bestIndex = i;
                    }
                }
            }

            if (bestIndex EQ 0) {
                break;
            }

            usedIndexes[bestIndex] = true;
            arrayAppend(orderedColumns, rawColumns[bestIndex]);
        }

        return orderedColumns;
    }

    function crmResolveColumn(required string reference, required array columns, required array headerLabels) {
        var ref = trim(arguments.reference & "");
        var refNorm = "";
        var refCompact = "";
        var labelNorm = "";
        var labelCompact = "";
        var columnIndex = 0;
        var i = 0;

        if (NOT len(ref)) {
            return "";
        }

        for (i = 1; i LTE arrayLen(arguments.columns); i++) {
            if (lCase(trim(arguments.columns[i])) EQ lCase(ref)) {
                return arguments.columns[i];
            }
        }

        if (isNumeric(ref)) {
            columnIndex = int(val(ref));
            if (columnIndex GTE 1 AND columnIndex LTE arrayLen(arguments.columns)) {
                return arguments.columns[columnIndex];
            }
        }

        columnIndex = crmExcelColumnNumber(ref);
        if (columnIndex GTE 1 AND columnIndex LTE arrayLen(arguments.columns)) {
            return arguments.columns[columnIndex];
        }

        refNorm = crmNormalizeHeader(ref);
        refCompact = replace(refNorm, "_", "", "all");

        for (i = 1; i LTE arrayLen(arguments.headerLabels); i++) {
            labelNorm = crmNormalizeHeader(arguments.headerLabels[i]);
            labelCompact = replace(labelNorm, "_", "", "all");

            if (len(labelNorm) AND (labelNorm EQ refNorm OR labelCompact EQ refCompact)) {
                return arguments.columns[i];
            }
        }

        return "";
    }

    function crmQueryCell(required query data, required string columnName, required numeric rowNumber) {
        if (arguments.rowNumber LTE 0 OR arguments.rowNumber GT arguments.data.recordcount) {
            return "";
        }

        return trim(arguments.data[arguments.columnName][arguments.rowNumber] & "");
    }

    function crmMappedValue(required struct mapping, required query data, required numeric rowNumber, required string fieldName) {
        if (NOT structKeyExists(arguments.mapping, arguments.fieldName)) {
            return "";
        }

        return crmQueryCell(arguments.data, arguments.mapping[arguments.fieldName], arguments.rowNumber);
    }
</cfscript>

<cfquery name="qCrmObjects">
    SELECT DISTINCT table_name
    FROM information_schema.tables
    WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmSchema#"/>
      AND table_name IN (
          <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRequiredObjects#" list="true"/>
      )
    UNION
    SELECT DISTINCT table_name
    FROM information_schema.views
    WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmSchema#"/>
      AND table_name IN (
          <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRequiredObjects#" list="true"/>
      )
</cfquery>

<cfset VARIABLES.crmTablesReady = qCrmObjects.recordcount EQ listLen(VARIABLES.crmRequiredObjects)/>

<cfset qCrmStats = queryNew("total_participacoes,total_leads,total_pagos,total_corredores,total_vinculados", "integer,integer,integer,integer,integer")/>
<cfset queryAddRow(qCrmStats, 1)/>
<cfset querySetCell(qCrmStats, "total_participacoes", 0, 1)/>
<cfset querySetCell(qCrmStats, "total_leads", 0, 1)/>
<cfset querySetCell(qCrmStats, "total_pagos", 0, 1)/>
<cfset querySetCell(qCrmStats, "total_corredores", 0, 1)/>
<cfset querySetCell(qCrmStats, "total_vinculados", 0, 1)/>

<cfset qCrmEventos = queryNew("id_evento,nome_evento,ano_evento,fontes,codigos,total")/>
<cfset qCrmEventosConta = queryNew("id_evento,nome_evento,data_inicial,ano_evento,cidade,estado,contas")/>
<cfset qCrmFontesPendentes = queryNew("id_crm_evento_versao,fonte,cod_evento_externo,nome_evento,ano_evento,total")/>
<cfset qCrmAnos = queryNew("ano_evento,total")/>
<cfset qCrmPercursos = queryNew("percurso,total")/>
<cfset qCrmStatus = queryNew("status_pedido,total")/>
<cfset qCrmEstados = queryNew("estado,total")/>
<cfset qCrmImportacoes = queryNew("id_crm_importacao,nome_importacao,fonte,origem_tipo,status_processamento,total_linhas,total_validas,total_invalidas,data_criacao")/>
<cfset qCrmParticipacoes = queryNew("id_crm_participacao,id_evento,nome,email,telefone,documento,cidade,estado,cod_evento_externo,nome_evento,ano_evento,percurso,modalidade,status_pedido,numero_inscricao,numero_pedido,data_pedido,lead_score,correu,concluinte,id_usuario")/>
<cfset qCrmTotalRows = queryNew("total", "integer")/>
<cfset queryAddRow(qCrmTotalRows, 1)/>
<cfset querySetCell(qCrmTotalRows, "total", 0, 1)/>
<cfset qCrmSyncTicketsports = queryNew("total_versoes,total_importacoes,total_pedidos,total_pessoas,total_participacoes", "integer,integer,integer,integer,integer")/>
<cfset qCrmLinkTicketsports = queryNew("conta_id,conta_nome,crm_evento_versao_id,evento_codigo_externo,evento_nome_externo,vinculo_status")/>
<cfset qCrmLinkFonteEvento = queryNew("fonte,evento_codigo_externo,evento_rr_id,evento_rr_nome,parceiro_id,crm_evento_versao_id,total_participacoes,total_resultados_vinculados,total_usuarios_vinculados", "varchar,varchar,integer,varchar,integer,integer,integer,integer,integer")/>
<cfset qCrmUploadProcess = queryNew("linhas_total,linhas_validas,linhas_invalidas,pessoas_upsert,participacoes_upsert,resultados_vinculados,usuarios_vinculados", "integer,integer,integer,integer,integer,integer,integer")/>
<cfset qCrmUploadPreview = queryNew("numero_linha,nome_atleta,email,documento,sexo,cidade,estado,numero_inscricao,numero_pedido,percurso,modalidade,status_inscricao,status_validacao,avisos")/>
<cfset qCrmUploadMapeamento = queryNew("campo,coluna,cabecalho", "varchar,varchar,varchar")/>
<cfset qCrmUploadColunas = queryNew("ordem,cabecalho,campo_atual", "integer,varchar,varchar")/>
<cfset qCrmMatchResultados = queryNew("participacoes_avaliadas,participacoes_vinculadas,pessoas_vinculadas,participacoes_pendentes", "integer,integer,integer,integer")/>
<cfset qCrmMatchUsuarios = queryNew("pessoas_avaliadas,pessoas_vinculadas,pessoas_pendentes", "integer,integer,integer")/>
<cfset qCrmContas = queryNew("id_conta,nome_conta,status,total_versoes")/>
<cfset VARIABLES.crmTotalPaginas = 1/>
<cfset VARIABLES.crmPreviewImportacao = ""/>
<cfset VARIABLES.crmPreviewTotalLinhas = 0/>
<cfset VARIABLES.crmUploadManualFields = "nome,email,documento,tipo_documento,data_nascimento,sexo,telefone,cidade,estado,pais,numero_inscricao,numero_pedido,protocolo,numero_peito,percurso,modalidade,categoria,status,origem,campanha,cupom,camiseta,assessoria,data_pedido,data_pagamento,valor"/>

<cfif VARIABLES.crmTablesReady>
    <cfif isDefined("FORM.acao") AND FORM.acao EQ "sync_ticketsports">
        <cfset VARIABLES.crmSyncCodEvento = ""/>
        <cfif isDefined("FORM.cod_evento")>
            <cfset VARIABLES.crmSyncCodEvento = trim(FORM.cod_evento)/>
        </cfif>

        <cfif len(VARIABLES.crmSyncCodEvento) AND NOT isNumeric(VARIABLES.crmSyncCodEvento)>
            <cfset VARIABLES.crmSyncCodEvento = ""/>
        </cfif>

        <cfif VARIABLES.crmEffectiveIsAdmin>
            <cfquery name="qCrmSyncTicketsports">
                SELECT *
                FROM crm.crm_sync_ticketsports(
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmSyncCodEvento#" null="#len(VARIABLES.crmSyncCodEvento) EQ 0#"/>
                )
            </cfquery>
        <cfelse>
            <cfset VARIABLES.crmError = "A sincronização direta do TicketSports é restrita ao admin."/>
        </cfif>
    </cfif>

    <cfif isDefined("FORM.acao") AND FORM.acao EQ "link_ticketsports_conta">
        <cfset VARIABLES.crmLinkCodEvento = ""/>
        <cfset VARIABLES.crmLinkIdConta = ""/>
        <cfset VARIABLES.crmLinkUsuario = ""/>

        <cfif isDefined("FORM.cod_evento")>
            <cfset VARIABLES.crmLinkCodEvento = trim(FORM.cod_evento)/>
        </cfif>
        <cfif isDefined("FORM.id_conta")>
            <cfset VARIABLES.crmLinkIdConta = trim(FORM.id_conta)/>
        </cfif>
        <cfif isDefined("COOKIE.id") AND isNumeric(COOKIE.id)>
            <cfset VARIABLES.crmLinkUsuario = trim(COOKIE.id)/>
        </cfif>

        <cfif NOT isNumeric(VARIABLES.crmLinkCodEvento) OR NOT isNumeric(VARIABLES.crmLinkIdConta)>
            <cfset VARIABLES.crmError = "Informe uma conta e um código de evento TicketSports para vincular."/>
        <cfelseif NOT VARIABLES.crmEffectiveIsAdmin AND NOT listFind(VARIABLES.crmOperatorAccountIds, VARIABLES.crmLinkIdConta)>
            <cfset VARIABLES.crmError = "Seu usuário não tem permissão de operação nessa conta."/>
        <cfelse>
            <cfquery name="qCrmLinkTicketsports">
                SELECT *
                FROM crm.crm_link_ticketsports_conta(
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmLinkCodEvento#"/>,
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmLinkIdConta#"/>,
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmLinkUsuario#" null="#len(VARIABLES.crmLinkUsuario) EQ 0#"/>
                )
            </cfquery>

            <cfset VARIABLES.crmIdConta = VARIABLES.crmLinkIdConta/>
            <cfset VARIABLES.crmAccountFilterIds = VARIABLES.crmLinkIdConta/>
            <cfset VARIABLES.crmCodEvento = VARIABLES.crmLinkCodEvento/>
        </cfif>
    </cfif>

    <cfif isDefined("FORM.acao") AND FORM.acao EQ "link_ticketsports_evento">
        <cfset VARIABLES.crmLinkFonteCodigo = ""/>
        <cfset VARIABLES.crmLinkFonteIdEvento = ""/>
        <cfset VARIABLES.crmLinkFonteUsuario = ""/>
        <cfset VARIABLES.crmPodeVincularEvento = VARIABLES.crmEffectiveIsAdmin/>

        <cfif isDefined("FORM.cod_evento")>
            <cfset VARIABLES.crmLinkFonteCodigo = trim(FORM.cod_evento)/>
        </cfif>
        <cfif isDefined("FORM.id_evento")>
            <cfset VARIABLES.crmLinkFonteIdEvento = trim(FORM.id_evento)/>
        </cfif>
        <cfif isDefined("COOKIE.id") AND isNumeric(COOKIE.id)>
            <cfset VARIABLES.crmLinkFonteUsuario = trim(COOKIE.id)/>
        </cfif>

        <cfif NOT isNumeric(VARIABLES.crmLinkFonteCodigo) OR NOT isNumeric(VARIABLES.crmLinkFonteIdEvento)>
            <cfset VARIABLES.crmError = "Informe o código TicketSports e o ID do evento Road Runners."/>
        <cfelseif NOT VARIABLES.crmCanOperate>
            <cfset VARIABLES.crmError = "Seu usuário não tem permissão para vincular fontes a eventos."/>
        <cfelse>
            <cfif NOT VARIABLES.crmEffectiveIsAdmin>
                <cfquery name="qCrmEventoOperacao">
                    SELECT 1
                    FROM public.tb_conta_eventos cev
                    WHERE cev.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmLinkFonteIdEvento#"/>
                      AND cev.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmOperatorAccountIds#" list="true"/>)
                      AND cev.status = 'ATIVO'::public.status_conta_evento
                    LIMIT 1
                </cfquery>

                <cfset VARIABLES.crmPodeVincularEvento = qCrmEventoOperacao.recordcount GT 0/>
            </cfif>

            <cfif NOT VARIABLES.crmPodeVincularEvento>
                <cfset VARIABLES.crmError = "O evento RR informado não está associado a uma conta que seu usuário opera."/>
            </cfif>
        </cfif>

        <cfif NOT len(VARIABLES.crmError)>
            <cfquery name="qCrmLinkFonteEvento">
                SELECT 'ticketsports'::varchar AS fonte,
                       link.evento_codigo_externo,
                       link.evento_rr_id,
                       link.evento_rr_nome,
                       NULL::integer AS parceiro_id,
                       link.crm_evento_versao_id,
                       link.total_participacoes,
                       link.total_resultados_vinculados,
                       link.total_usuarios_vinculados
                FROM crm.crm_link_ticketsports_evento(
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmLinkFonteCodigo#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmLinkFonteIdEvento#"/>,
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmLinkFonteUsuario#" null="#len(VARIABLES.crmLinkFonteUsuario) EQ 0#"/>
                ) link
            </cfquery>

            <cfset VARIABLES.crmCodEvento = VARIABLES.crmLinkFonteCodigo/>
            <cfset VARIABLES.crmIdEventoFiltro = VARIABLES.crmLinkFonteIdEvento/>
        </cfif>
    </cfif>

    <cfif isDefined("FORM.acao") AND FORM.acao EQ "link_fonte_evento">
        <cfset VARIABLES.crmLinkFonte = "excel"/>
        <cfset VARIABLES.crmLinkFonteCodigo = ""/>
        <cfset VARIABLES.crmLinkFonteIdEvento = ""/>
        <cfset VARIABLES.crmLinkFonteIdParceiro = ""/>
        <cfset VARIABLES.crmLinkFonteUsuario = ""/>
        <cfset VARIABLES.crmPodeVincularEvento = VARIABLES.crmEffectiveIsAdmin/>

        <cfif isDefined("FORM.fonte") AND len(trim(FORM.fonte))>
            <cfset VARIABLES.crmLinkFonte = lCase(trim(FORM.fonte))/>
        </cfif>
        <cfif isDefined("FORM.cod_evento")>
            <cfset VARIABLES.crmLinkFonteCodigo = trim(FORM.cod_evento)/>
        </cfif>
        <cfif isDefined("FORM.id_evento")>
            <cfset VARIABLES.crmLinkFonteIdEvento = trim(FORM.id_evento)/>
        </cfif>
        <cfif isDefined("FORM.id_parceiro")>
            <cfset VARIABLES.crmLinkFonteIdParceiro = trim(FORM.id_parceiro)/>
        </cfif>
        <cfif isDefined("COOKIE.id") AND isNumeric(COOKIE.id)>
            <cfset VARIABLES.crmLinkFonteUsuario = trim(COOKIE.id)/>
        </cfif>

        <cfif NOT len(VARIABLES.crmLinkFonte) OR NOT isNumeric(VARIABLES.crmLinkFonteIdEvento)>
            <cfset VARIABLES.crmError = "Informe a fonte e o ID do evento Road Runners."/>
        <cfelseif NOT VARIABLES.crmCanOperate>
            <cfset VARIABLES.crmError = "Seu usuário não tem permissão para vincular fontes a eventos."/>
        <cfelseif len(VARIABLES.crmLinkFonteIdParceiro) AND NOT isNumeric(VARIABLES.crmLinkFonteIdParceiro)>
            <cfset VARIABLES.crmError = "Informe um ID de parceiro numérico ou deixe o campo em branco."/>
        <cfelse>
            <cfif NOT VARIABLES.crmEffectiveIsAdmin>
                <cfquery name="qCrmEventoOperacao">
                    SELECT 1
                    FROM public.tb_conta_eventos cev
                    WHERE cev.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmLinkFonteIdEvento#"/>
                      AND cev.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmOperatorAccountIds#" list="true"/>)
                      AND cev.status = 'ATIVO'::public.status_conta_evento
                    LIMIT 1
                </cfquery>

                <cfset VARIABLES.crmPodeVincularEvento = qCrmEventoOperacao.recordcount GT 0/>
            </cfif>

            <cfif NOT VARIABLES.crmPodeVincularEvento>
                <cfset VARIABLES.crmError = "O evento RR informado não está associado a uma conta que seu usuário opera."/>
            </cfif>
        </cfif>

        <cfif NOT len(VARIABLES.crmError)>
            <cfquery name="qCrmLinkFonteEvento">
                SELECT *
                FROM crm.crm_link_fonte_evento(
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmLinkFonte#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmLinkFonteIdEvento#"/>,
                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmLinkFonteCodigo#" null="#len(VARIABLES.crmLinkFonteCodigo) EQ 0#"/>,
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmLinkFonteIdParceiro#" null="#len(VARIABLES.crmLinkFonteIdParceiro) EQ 0#"/>,
                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmLinkFonteUsuario#" null="#len(VARIABLES.crmLinkFonteUsuario) EQ 0#"/>
                )
            </cfquery>

            <cfset VARIABLES.crmIdEventoFiltro = VARIABLES.crmLinkFonteIdEvento/>
        </cfif>
    </cfif>

    <cfif isDefined("FORM.acao") AND listFindNoCase("preview_arquivo,upload_arquivo", FORM.acao)>
        <cfset VARIABLES.crmUploadIdEvento = ""/>
        <cfset VARIABLES.crmUploadFonte = "excel"/>
        <cfset VARIABLES.crmUploadCodEvento = ""/>
        <cfset VARIABLES.crmUploadIdParceiro = ""/>
        <cfset VARIABLES.crmUploadNome = ""/>
        <cfset VARIABLES.crmUploadHeaderRow = 1/>
        <cfset VARIABLES.crmUploadLayout = "auto"/>
        <cfset VARIABLES.crmUploadUsuario = ""/>
        <cfset VARIABLES.crmPodeVincularEvento = VARIABLES.crmEffectiveIsAdmin/>
        <cfset VARIABLES.crmUploadRowsImported = 0/>
        <cfset VARIABLES.crmUploadShouldProcess = FORM.acao EQ "upload_arquivo"/>

        <cfif isDefined("FORM.id_evento")>
            <cfset VARIABLES.crmUploadIdEvento = trim(FORM.id_evento)/>
        </cfif>
        <cfif isDefined("FORM.fonte") AND len(trim(FORM.fonte))>
            <cfset VARIABLES.crmUploadFonte = lCase(trim(FORM.fonte))/>
        </cfif>
        <cfif isDefined("FORM.cod_evento")>
            <cfset VARIABLES.crmUploadCodEvento = trim(FORM.cod_evento)/>
        </cfif>
        <cfif isDefined("FORM.id_parceiro")>
            <cfset VARIABLES.crmUploadIdParceiro = trim(FORM.id_parceiro)/>
        </cfif>
        <cfif isDefined("FORM.nome_importacao")>
            <cfset VARIABLES.crmUploadNome = trim(FORM.nome_importacao)/>
        </cfif>
        <cfif isDefined("FORM.header_row")>
            <cfset VARIABLES.crmUploadHeaderRow = int(val(FORM.header_row))/>
        </cfif>
        <cfif isDefined("FORM.layout_importacao") AND len(trim(FORM.layout_importacao))>
            <cfset VARIABLES.crmUploadLayout = lCase(trim(FORM.layout_importacao))/>
        </cfif>

        <cfif isDefined("COOKIE.id") AND isNumeric(COOKIE.id)>
            <cfset VARIABLES.crmUploadUsuario = trim(COOKIE.id)/>
        </cfif>

        <cfif NOT isNumeric(VARIABLES.crmUploadIdEvento)>
            <cfset VARIABLES.crmError = "Informe o ID do evento Road Runners para importar o arquivo."/>
        <cfelseif NOT len(VARIABLES.crmUploadFonte)>
            <cfset VARIABLES.crmError = "Informe a fonte da importação."/>
        <cfelseif len(VARIABLES.crmUploadIdParceiro) AND NOT isNumeric(VARIABLES.crmUploadIdParceiro)>
            <cfset VARIABLES.crmError = "Informe um ID de parceiro numérico ou deixe em branco."/>
        <cfelseif NOT VARIABLES.crmCanOperate>
            <cfset VARIABLES.crmError = "Seu usuário não tem permissão para importar arquivos CRM."/>
        <cfelse>
            <cfif NOT VARIABLES.crmEffectiveIsAdmin>
                <cfquery name="qCrmUploadEventoOperacao">
                    SELECT 1
                    FROM public.tb_conta_eventos cev
                    WHERE cev.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmUploadIdEvento#"/>
                      AND cev.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmOperatorAccountIds#" list="true"/>)
                      AND cev.status = 'ATIVO'::public.status_conta_evento
                    LIMIT 1
                </cfquery>

                <cfset VARIABLES.crmPodeVincularEvento = qCrmUploadEventoOperacao.recordcount GT 0/>
            </cfif>

            <cfif NOT VARIABLES.crmPodeVincularEvento>
                <cfset VARIABLES.crmError = "O evento RR informado não está associado a uma conta que seu usuário opera."/>
            </cfif>
        </cfif>

        <cfif NOT len(VARIABLES.crmError)>
            <cftry>
                <cfset VARIABLES.crmUploadDiskPath = getTempDirectory() & "crm-importacoes/"/>
                <cfif NOT directoryExists(VARIABLES.crmUploadDiskPath)>
                    <cfdirectory action="create" directory="#VARIABLES.crmUploadDiskPath#"/>
                </cfif>

                <cffile action="upload"
                        filefield="arquivo_crm"
                        destination="#VARIABLES.crmUploadDiskPath#"
                        nameconflict="makeunique"
                        result="crmUploadResult"/>

                <cfset VARIABLES.crmUploadExtension = lCase(crmUploadResult.serverFileExt)/>
                <cfset VARIABLES.crmUploadFilePath = VARIABLES.crmUploadDiskPath & crmUploadResult.serverFile/>

                <cfif NOT listFindNoCase("xlsx,xls,csv", VARIABLES.crmUploadExtension)>
                    <cfif fileExists(VARIABLES.crmUploadFilePath)>
                        <cffile action="delete" file="#VARIABLES.crmUploadFilePath#"/>
                    </cfif>
                    <cfset VARIABLES.crmError = "Envie um arquivo XLSX, XLS ou CSV."/>
                </cfif>

                <cfif NOT len(VARIABLES.crmError)>
                    <cfif listFindNoCase("xlsx,xls", VARIABLES.crmUploadExtension)>
                        <cfspreadsheet action="read" src="#VARIABLES.crmUploadFilePath#" query="qCrmUploadSheet"/>
                    <cfelse>
                        <cfset qCrmUploadSheet = crmReadCsvToQuery(VARIABLES.crmUploadFilePath)/>
                    </cfif>

                    <cfset VARIABLES.crmUploadColumns = crmQueryColumns(qCrmUploadSheet)/>
                    <cfset VARIABLES.crmUploadHeaderLabels = []/>
                    <cfset VARIABLES.crmUploadMapping = structNew()/>
                    <cfset VARIABLES.crmUploadManualMapping = structNew()/>

                    <cfif VARIABLES.crmUploadLayout EQ "mif2017_sem_cabecalho">
                        <cfset VARIABLES.crmUploadHeaderRow = 0/>
                    <cfelseif VARIABLES.crmUploadHeaderRow LT 0>
                        <cfset VARIABLES.crmUploadHeaderRow = 1/>
                    </cfif>

                    <cfloop from="1" to="#arrayLen(VARIABLES.crmUploadColumns)#" index="crmUploadColumnIndex">
                        <cfif VARIABLES.crmUploadHeaderRow GT 0>
                            <cfset VARIABLES.crmUploadHeaderLabel = crmQueryCell(qCrmUploadSheet, VARIABLES.crmUploadColumns[crmUploadColumnIndex], VARIABLES.crmUploadHeaderRow)/>
                        <cfelse>
                            <cfset VARIABLES.crmUploadHeaderLabel = "col_" & crmUploadColumnIndex/>
                        </cfif>

                        <cfif NOT len(trim(VARIABLES.crmUploadHeaderLabel))>
                            <cfset VARIABLES.crmUploadHeaderLabel = "col_" & crmUploadColumnIndex/>
                        </cfif>

                        <cfset arrayAppend(VARIABLES.crmUploadHeaderLabels, VARIABLES.crmUploadHeaderLabel)/>
                        <cfset VARIABLES.crmUploadFieldName = crmFieldForHeader(VARIABLES.crmUploadHeaderLabel)/>

                        <cfif len(VARIABLES.crmUploadFieldName) AND NOT structKeyExists(VARIABLES.crmUploadMapping, VARIABLES.crmUploadFieldName)>
                            <cfset VARIABLES.crmUploadMapping[VARIABLES.crmUploadFieldName] = VARIABLES.crmUploadColumns[crmUploadColumnIndex]/>
                        </cfif>
                    </cfloop>

                    <cfif VARIABLES.crmUploadLayout EQ "mif2017_sem_cabecalho" AND arrayLen(VARIABLES.crmUploadColumns) GTE 5>
                        <cfset VARIABLES.crmUploadMapping = structNew()/>
                        <cfset VARIABLES.crmUploadMapping["nome"] = VARIABLES.crmUploadColumns[1]/>
                        <cfset VARIABLES.crmUploadMapping["modalidade"] = VARIABLES.crmUploadColumns[2]/>
                        <cfset VARIABLES.crmUploadMapping["email"] = VARIABLES.crmUploadColumns[3]/>
                        <cfset VARIABLES.crmUploadMapping["cidade"] = VARIABLES.crmUploadColumns[4]/>
                        <cfset VARIABLES.crmUploadMapping["estado"] = VARIABLES.crmUploadColumns[5]/>
                    </cfif>

                    <cfloop list="#VARIABLES.crmUploadManualFields#" index="crmUploadManualField">
                        <cfif NOT len(VARIABLES.crmError)>
                            <cfset VARIABLES.crmUploadManualFormKey = "map_" & crmUploadManualField/>
                            <cfif structKeyExists(FORM, VARIABLES.crmUploadManualFormKey) AND len(trim(FORM[VARIABLES.crmUploadManualFormKey]))>
                                <cfset VARIABLES.crmUploadManualReference = trim(FORM[VARIABLES.crmUploadManualFormKey])/>
                                <cfset VARIABLES.crmUploadManualColumn = crmResolveColumn(VARIABLES.crmUploadManualReference, VARIABLES.crmUploadColumns, VARIABLES.crmUploadHeaderLabels)/>

                                <cfif len(VARIABLES.crmUploadManualColumn)>
                                    <cfset VARIABLES.crmUploadMapping[crmUploadManualField] = VARIABLES.crmUploadManualColumn/>
                                    <cfset VARIABLES.crmUploadManualMapping[crmUploadManualField] = VARIABLES.crmUploadManualReference/>
                                <cfelse>
                                    <cfset VARIABLES.crmError = "Não encontrei a coluna informada para " & crmUploadManualField & ": " & VARIABLES.crmUploadManualReference & "."/>
                                </cfif>
                            </cfif>
                        </cfif>
                    </cfloop>

                    <cfif NOT len(VARIABLES.crmError)>
                        <cfset VARIABLES.crmUploadFieldByColumn = structNew()/>
                        <cfloop collection="#VARIABLES.crmUploadMapping#" item="crmUploadMappedField">
                            <cfset VARIABLES.crmUploadFieldByColumn[VARIABLES.crmUploadMapping[crmUploadMappedField]] = crmUploadMappedField/>
                        </cfloop>

                        <cfloop from="1" to="#arrayLen(VARIABLES.crmUploadHeaderLabels)#" index="crmUploadColumnIndex">
                            <cfset queryAddRow(qCrmUploadColunas, 1)/>
                            <cfset querySetCell(qCrmUploadColunas, "ordem", crmUploadColumnIndex, qCrmUploadColunas.recordcount)/>
                            <cfset querySetCell(qCrmUploadColunas, "cabecalho", VARIABLES.crmUploadHeaderLabels[crmUploadColumnIndex], qCrmUploadColunas.recordcount)/>
                            <cfif structKeyExists(VARIABLES.crmUploadFieldByColumn, VARIABLES.crmUploadColumns[crmUploadColumnIndex])>
                                <cfset querySetCell(qCrmUploadColunas, "campo_atual", VARIABLES.crmUploadFieldByColumn[VARIABLES.crmUploadColumns[crmUploadColumnIndex]], qCrmUploadColunas.recordcount)/>
                            <cfelse>
                                <cfset querySetCell(qCrmUploadColunas, "campo_atual", "", qCrmUploadColunas.recordcount)/>
                            </cfif>
                        </cfloop>

                        <cfloop list="#VARIABLES.crmUploadManualFields#" index="crmUploadManualField">
                            <cfif structKeyExists(VARIABLES.crmUploadMapping, crmUploadManualField)>
                                <cfset VARIABLES.crmUploadMappedColumn = VARIABLES.crmUploadMapping[crmUploadManualField]/>
                                <cfset VARIABLES.crmUploadMappedColumnIndex = arrayFind(VARIABLES.crmUploadColumns, VARIABLES.crmUploadMappedColumn)/>
                                <cfset VARIABLES.crmUploadMappedHeader = VARIABLES.crmUploadMappedColumn/>
                                <cfif VARIABLES.crmUploadMappedColumnIndex GT 0>
                                    <cfset VARIABLES.crmUploadMappedHeader = VARIABLES.crmUploadHeaderLabels[VARIABLES.crmUploadMappedColumnIndex]/>
                                </cfif>
                                <cfset queryAddRow(qCrmUploadMapeamento, 1)/>
                                <cfset querySetCell(qCrmUploadMapeamento, "campo", crmUploadManualField, qCrmUploadMapeamento.recordcount)/>
                                <cfset querySetCell(qCrmUploadMapeamento, "coluna", VARIABLES.crmUploadMappedColumn, qCrmUploadMapeamento.recordcount)/>
                                <cfset querySetCell(qCrmUploadMapeamento, "cabecalho", VARIABLES.crmUploadMappedHeader, qCrmUploadMapeamento.recordcount)/>
                            </cfif>
                        </cfloop>
                    </cfif>

                    <cfif NOT structKeyExists(VARIABLES.crmUploadMapping, "nome")>
                        <cfset VARIABLES.crmError = "Não consegui identificar a coluna de nome. Ajuste a linha do cabeçalho ou use o layout sem cabeçalho."/>
                    </cfif>
                </cfif>

                <cfif NOT len(VARIABLES.crmError)>
                    <cfset VARIABLES.crmUploadFileHash = hash(binaryEncode(fileReadBinary(VARIABLES.crmUploadFilePath), "hex"), "SHA-256")/>
                    <cfset VARIABLES.crmUploadFileInfo = getFileInfo(VARIABLES.crmUploadFilePath)/>
                    <cfset VARIABLES.crmUploadMime = "application/octet-stream"/>
                    <cfif structKeyExists(crmUploadResult, "contentType") AND structKeyExists(crmUploadResult, "contentSubType")>
                        <cfset VARIABLES.crmUploadMime = crmUploadResult.contentType & "/" & crmUploadResult.contentSubType/>
                    </cfif>
                    <cfset VARIABLES.crmUploadMapPayload = {
                        "layout" = VARIABLES.crmUploadLayout,
                        "header_row" = VARIABLES.crmUploadHeaderRow,
                        "columns" = VARIABLES.crmUploadHeaderLabels,
                        "fields" = VARIABLES.crmUploadMapping,
                        "manual_fields" = VARIABLES.crmUploadManualMapping
                    }/>

                    <cfquery name="qCrmUploadImport">
                        SELECT *
                        FROM crm.crm_criar_importacao_arquivo(
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmUploadIdEvento#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadFonte#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadNome#" null="#len(VARIABLES.crmUploadNome) EQ 0#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#crmUploadResult.clientFile#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadFileHash#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmUploadUsuario#" null="#len(VARIABLES.crmUploadUsuario) EQ 0#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadCodEvento#" null="#len(VARIABLES.crmUploadCodEvento) EQ 0#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmUploadIdParceiro#" null="#len(VARIABLES.crmUploadIdParceiro) EQ 0#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadMime#"/>,
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmUploadFileInfo.size#"/>,
                            <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.crmUploadMapPayload)#"/>::jsonb
                        )
                    </cfquery>

                    <cfif VARIABLES.crmUploadHeaderRow GT 0>
                        <cfset VARIABLES.crmUploadDataStart = VARIABLES.crmUploadHeaderRow + 1/>
                    <cfelse>
                        <cfset VARIABLES.crmUploadDataStart = 1/>
                    </cfif>

                    <cfloop from="#VARIABLES.crmUploadDataStart#" to="#qCrmUploadSheet.recordcount#" index="crmUploadRowIndex">
                        <cfset VARIABLES.crmUploadRaw = structNew()/>
                        <cfset VARIABLES.crmUploadNormalizado = structNew()/>
                        <cfset VARIABLES.crmUploadHasValue = false/>

                        <cfloop from="1" to="#arrayLen(VARIABLES.crmUploadColumns)#" index="crmUploadColumnIndex">
                            <cfset VARIABLES.crmUploadCellValue = crmQueryCell(qCrmUploadSheet, VARIABLES.crmUploadColumns[crmUploadColumnIndex], crmUploadRowIndex)/>
                            <cfset VARIABLES.crmUploadRaw[VARIABLES.crmUploadHeaderLabels[crmUploadColumnIndex]] = VARIABLES.crmUploadCellValue/>
                            <cfif len(VARIABLES.crmUploadCellValue)>
                                <cfset VARIABLES.crmUploadHasValue = true/>
                            </cfif>
                        </cfloop>

                        <cfif VARIABLES.crmUploadHasValue>
                            <cfset VARIABLES.crmUploadNomeAtleta = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "nome")/>
                            <cfset VARIABLES.crmUploadEmail = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "email")/>
                            <cfset VARIABLES.crmUploadDocumento = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "documento")/>
                            <cfset VARIABLES.crmUploadTipoDocumento = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "tipo_documento")/>
                            <cfset VARIABLES.crmUploadDataNascimento = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "data_nascimento")/>
                            <cfset VARIABLES.crmUploadSexoOriginal = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "sexo")/>
                            <cfset VARIABLES.crmUploadSexo = crmNormalizeSexo(VARIABLES.crmUploadSexoOriginal)/>
                            <cfset VARIABLES.crmUploadAvisos = crmSexoAvisos(VARIABLES.crmUploadSexoOriginal, VARIABLES.crmUploadSexo)/>
                            <cfset VARIABLES.crmUploadTelefone = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "telefone")/>
                            <cfset VARIABLES.crmUploadCidade = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "cidade")/>
                            <cfset VARIABLES.crmUploadEstado = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "estado")/>
                            <cfset VARIABLES.crmUploadPais = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "pais")/>
                            <cfset VARIABLES.crmUploadNumeroInscricao = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "numero_inscricao")/>
                            <cfset VARIABLES.crmUploadNumeroPedido = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "numero_pedido")/>
                            <cfset VARIABLES.crmUploadProtocolo = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "protocolo")/>
                            <cfset VARIABLES.crmUploadNumeroPeito = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "numero_peito")/>
                            <cfset VARIABLES.crmUploadPercurso = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "percurso")/>
                            <cfset VARIABLES.crmUploadModalidade = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "modalidade")/>
                            <cfset VARIABLES.crmUploadCategoria = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "categoria")/>
                            <cfset VARIABLES.crmUploadStatus = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "status")/>
                            <cfset VARIABLES.crmUploadOrigem = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "origem")/>
                            <cfset VARIABLES.crmUploadCampanha = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "campanha")/>
                            <cfset VARIABLES.crmUploadCupom = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "cupom")/>
                            <cfset VARIABLES.crmUploadCamiseta = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "camiseta")/>
                            <cfset VARIABLES.crmUploadAssessoria = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "assessoria")/>
                            <cfset VARIABLES.crmUploadDataPedido = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "data_pedido")/>
                            <cfset VARIABLES.crmUploadDataPagamento = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "data_pagamento")/>
                            <cfset VARIABLES.crmUploadValor = crmMappedValue(VARIABLES.crmUploadMapping, qCrmUploadSheet, crmUploadRowIndex, "valor")/>

                            <cfset VARIABLES.crmUploadChave = crmUploadRowIndex/>
                            <cfif len(VARIABLES.crmUploadEmail)>
                                <cfset VARIABLES.crmUploadChave = VARIABLES.crmUploadEmail/>
                            </cfif>
                            <cfif len(VARIABLES.crmUploadDocumento)>
                                <cfset VARIABLES.crmUploadChave = VARIABLES.crmUploadDocumento/>
                            </cfif>
                            <cfif len(VARIABLES.crmUploadNumeroInscricao)>
                                <cfset VARIABLES.crmUploadChave = VARIABLES.crmUploadNumeroInscricao/>
                            </cfif>
                            <cfset VARIABLES.crmUploadNormalizado = {
                                "nome" = VARIABLES.crmUploadNomeAtleta,
                                "email" = VARIABLES.crmUploadEmail,
                                "documento" = VARIABLES.crmUploadDocumento,
                                "sexo" = VARIABLES.crmUploadSexo,
                                "numero_inscricao" = VARIABLES.crmUploadNumeroInscricao,
                                "modalidade" = VARIABLES.crmUploadModalidade
                            }/>

                            <cfquery>
                                INSERT INTO crm.tb_crm_importacao_linhas (
                                    id_crm_importacao,
                                    numero_linha,
                                    entidade_origem,
                                    chave_externa,
                                    raw,
                                    normalizado,
                                    nome_atleta,
                                    nome_norm,
                                    email,
                                    email_norm,
                                    tipo_documento,
                                    documento,
                                    documento_norm,
                                    telefone,
                                    telefone_norm,
                                    data_nascimento,
                                    sexo,
                                    cidade,
                                    estado,
                                    pais,
                                    numero_inscricao,
                                    numero_pedido,
                                    protocolo,
                                    numero_peito,
                                    percurso,
                                    modalidade,
                                    categoria,
                                    status_inscricao,
                                    origem,
                                    campanha,
                                    cupom,
                                    camiseta,
                                    assessoria,
                                    data_pedido,
                                    data_pagamento,
                                    valor,
                                    status_validacao,
                                    avisos
                                )
                                VALUES (
                                    <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCrmUploadImport.id_crm_importacao#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_integer" value="#crmUploadRowIndex#"/>,
                                    'arquivo_participante',
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadChave#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.crmUploadRaw)#"/>::jsonb,
                                    <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.crmUploadNormalizado)#"/>::jsonb,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadNomeAtleta#" null="#len(VARIABLES.crmUploadNomeAtleta) EQ 0#"/>,
                                    crm.crm_normalize_text(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadNomeAtleta#" null="#len(VARIABLES.crmUploadNomeAtleta) EQ 0#"/>),
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadEmail#" null="#len(VARIABLES.crmUploadEmail) EQ 0#"/>,
                                    lower(nullif(trim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadEmail#" null="#len(VARIABLES.crmUploadEmail) EQ 0#"/>), '')),
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadTipoDocumento#" null="#len(VARIABLES.crmUploadTipoDocumento) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadDocumento#" null="#len(VARIABLES.crmUploadDocumento) EQ 0#"/>,
                                    crm.crm_only_digits(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadDocumento#" null="#len(VARIABLES.crmUploadDocumento) EQ 0#"/>),
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadTelefone#" null="#len(VARIABLES.crmUploadTelefone) EQ 0#"/>,
                                    crm.crm_only_digits(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadTelefone#" null="#len(VARIABLES.crmUploadTelefone) EQ 0#"/>),
                                    crm.crm_parse_date_br(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadDataNascimento#" null="#len(VARIABLES.crmUploadDataNascimento) EQ 0#"/>),
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadSexo#" null="#len(VARIABLES.crmUploadSexo) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadCidade#" null="#len(VARIABLES.crmUploadCidade) EQ 0#"/>,
                                    upper(nullif(trim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadEstado#" null="#len(VARIABLES.crmUploadEstado) EQ 0#"/>), '')),
                                    coalesce(nullif(trim(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadPais#" null="#len(VARIABLES.crmUploadPais) EQ 0#"/>), ''), 'BR'),
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadNumeroInscricao#" null="#len(VARIABLES.crmUploadNumeroInscricao) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadNumeroPedido#" null="#len(VARIABLES.crmUploadNumeroPedido) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadProtocolo#" null="#len(VARIABLES.crmUploadProtocolo) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadNumeroPeito#" null="#len(VARIABLES.crmUploadNumeroPeito) EQ 0#"/>,
                                    crm.crm_infer_percurso(coalesce(
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadPercurso#" null="#len(VARIABLES.crmUploadPercurso) EQ 0#"/>,
                                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadModalidade#" null="#len(VARIABLES.crmUploadModalidade) EQ 0#"/>
                                    )),
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadModalidade#" null="#len(VARIABLES.crmUploadModalidade) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadCategoria#" null="#len(VARIABLES.crmUploadCategoria) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadStatus#" null="#len(VARIABLES.crmUploadStatus) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadOrigem#" null="#len(VARIABLES.crmUploadOrigem) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadCampanha#" null="#len(VARIABLES.crmUploadCampanha) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadCupom#" null="#len(VARIABLES.crmUploadCupom) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadCamiseta#" null="#len(VARIABLES.crmUploadCamiseta) EQ 0#"/>,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadAssessoria#" null="#len(VARIABLES.crmUploadAssessoria) EQ 0#"/>,
                                    crm.crm_parse_timestamp_br(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadDataPedido#" null="#len(VARIABLES.crmUploadDataPedido) EQ 0#"/>),
                                    crm.crm_parse_timestamp_br(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadDataPagamento#" null="#len(VARIABLES.crmUploadDataPagamento) EQ 0#"/>),
                                    crm.crm_parse_decimal_br(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadValor#" null="#len(VARIABLES.crmUploadValor) EQ 0#"/>),
                                    CASE WHEN crm.crm_normalize_text(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUploadNomeAtleta#" null="#len(VARIABLES.crmUploadNomeAtleta) EQ 0#"/>) IS NULL THEN 'invalido' ELSE 'valido' END,
                                    <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.crmUploadAvisos)#" null="#arrayLen(VARIABLES.crmUploadAvisos) EQ 0#"/>::jsonb
                                )
                                ON CONFLICT (id_crm_importacao, numero_linha, entidade_origem) DO UPDATE
                                    SET chave_externa = excluded.chave_externa,
                                        raw = excluded.raw,
                                        normalizado = excluded.normalizado,
                                        nome_atleta = excluded.nome_atleta,
                                        nome_norm = excluded.nome_norm,
                                        email = excluded.email,
                                        email_norm = excluded.email_norm,
                                        tipo_documento = excluded.tipo_documento,
                                        documento = excluded.documento,
                                        documento_norm = excluded.documento_norm,
                                        telefone = excluded.telefone,
                                        telefone_norm = excluded.telefone_norm,
                                        data_nascimento = excluded.data_nascimento,
                                        sexo = excluded.sexo,
                                        cidade = excluded.cidade,
                                        estado = excluded.estado,
                                        pais = excluded.pais,
                                        numero_inscricao = excluded.numero_inscricao,
                                        numero_pedido = excluded.numero_pedido,
                                        protocolo = excluded.protocolo,
                                        numero_peito = excluded.numero_peito,
                                        percurso = excluded.percurso,
                                        modalidade = excluded.modalidade,
                                        categoria = excluded.categoria,
                                        status_inscricao = excluded.status_inscricao,
                                        origem = excluded.origem,
                                        campanha = excluded.campanha,
                                        cupom = excluded.cupom,
                                        camiseta = excluded.camiseta,
                                        assessoria = excluded.assessoria,
                                        data_pedido = excluded.data_pedido,
                                        data_pagamento = excluded.data_pagamento,
                                        valor = excluded.valor,
                                        status_validacao = excluded.status_validacao,
                                        avisos = excluded.avisos,
                                        data_atualizacao = current_timestamp
                            </cfquery>

                            <cfset VARIABLES.crmUploadRowsImported = VARIABLES.crmUploadRowsImported + 1/>
                        </cfif>
                    </cfloop>

                    <cfif VARIABLES.crmUploadRowsImported EQ 0>
                        <cfset VARIABLES.crmError = "Nenhuma linha com dados foi encontrada no arquivo."/>
                    <cfelseif VARIABLES.crmUploadShouldProcess>
                        <cfquery name="qCrmUploadProcess">
                            SELECT *
                            FROM crm.crm_processar_importacao_arquivo(
                                <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCrmUploadImport.id_crm_importacao#"/>
                            )
                        </cfquery>

                        <cfset VARIABLES.crmIdEventoFiltro = VARIABLES.crmUploadIdEvento/>
                        <cfset VARIABLES.crmNotice = "Arquivo importado e processado."/>
                    <cfelse>
                        <cfquery>
                            UPDATE crm.tb_crm_importacoes
                               SET status_processamento = 'mapeado',
                                   total_linhas = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmUploadRowsImported#"/>,
                                   total_validas = (
                                       SELECT count(*)::integer
                                       FROM crm.tb_crm_importacao_linhas
                                       WHERE id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCrmUploadImport.id_crm_importacao#"/>
                                         AND status_validacao = 'valido'
                                   ),
                                   total_invalidas = (
                                       SELECT count(*)::integer
                                       FROM crm.tb_crm_importacao_linhas
                                       WHERE id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCrmUploadImport.id_crm_importacao#"/>
                                         AND status_validacao <> 'valido'
                                   ),
                                   data_atualizacao = current_timestamp
                             WHERE id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCrmUploadImport.id_crm_importacao#"/>
                        </cfquery>

                        <cfquery name="qCrmUploadPreview">
                            SELECT numero_linha,
                                   nome_atleta,
                                   email,
                                   documento,
                                   sexo,
                                   cidade,
                                   estado,
                                   numero_inscricao,
                                   numero_pedido,
                                   percurso,
                                   modalidade,
                                   status_inscricao,
                                   status_validacao,
                                   (
                                       SELECT string_agg(aviso, '; ')
                                       FROM jsonb_array_elements_text(coalesce(linha.avisos, '[]'::jsonb)) aviso
                                   ) AS avisos
                            FROM crm.tb_crm_importacao_linhas linha
                            WHERE linha.id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qCrmUploadImport.id_crm_importacao#"/>
                            ORDER BY numero_linha
                            LIMIT 12
                        </cfquery>

                        <cfset VARIABLES.crmPreviewImportacao = qCrmUploadImport.id_crm_importacao/>
                        <cfset VARIABLES.crmPreviewTotalLinhas = VARIABLES.crmUploadRowsImported/>
                        <cfset VARIABLES.crmIdEventoFiltro = VARIABLES.crmUploadIdEvento/>
                        <cfset VARIABLES.crmNotice = "Prévia gerada. Revise as primeiras linhas e confirme para consolidar no CRM."/>
                    </cfif>
                </cfif>

                <cfif isDefined("VARIABLES.crmUploadFilePath") AND fileExists(VARIABLES.crmUploadFilePath)>
                    <cffile action="delete" file="#VARIABLES.crmUploadFilePath#"/>
                </cfif>

                <cfcatch type="any">
                    <cfif isDefined("VARIABLES.crmUploadFilePath") AND fileExists(VARIABLES.crmUploadFilePath)>
                        <cffile action="delete" file="#VARIABLES.crmUploadFilePath#"/>
                    </cfif>
                    <cfset VARIABLES.crmError = "Não foi possível importar o arquivo: " & cfcatch.message/>
                    <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
                        <cfset VARIABLES.crmError = VARIABLES.crmError & " - " & left(trim(cfcatch.detail), 800)/>
                    <cfelseif structKeyExists(cfcatch, "sql") AND len(trim(cfcatch.sql))>
                        <cfset VARIABLES.crmError = VARIABLES.crmError & " - SQL: " & left(reReplace(trim(cfcatch.sql), "\s+", " ", "all"), 800)/>
                    </cfif>
                </cfcatch>
            </cftry>
        </cfif>
    </cfif>

    <cfif isDefined("FORM.acao") AND FORM.acao EQ "remap_importacao_arquivo">
        <cfset VARIABLES.crmRemapImportacao = ""/>
        <cfset VARIABLES.crmRemapPayload = structNew()/>
        <cfset VARIABLES.crmRemapColumns = []/>
        <cfset VARIABLES.crmRemapColumnSet = structNew()/>
        <cfset VARIABLES.crmRemapFields = structNew()/>

        <cfif isDefined("FORM.id_crm_importacao")>
            <cfset VARIABLES.crmRemapImportacao = trim(FORM.id_crm_importacao)/>
        </cfif>

        <cfloop list="#VARIABLES.crmUploadManualFields#" index="crmRemapField">
            <cfset VARIABLES.crmRemapFields[crmRemapField] = ""/>
        </cfloop>

        <cfif NOT isNumeric(VARIABLES.crmRemapImportacao)>
            <cfset VARIABLES.crmError = "Importação inválida para remapeamento."/>
        <cfelseif NOT VARIABLES.crmCanOperate>
            <cfset VARIABLES.crmError = "Seu usuário não tem permissão para ajustar importações CRM."/>
        <cfelse>
            <cfquery name="qCrmRemapImportacao">
                SELECT imp.id_crm_importacao,
                       imp.mapeamento::text AS mapeamento_json,
                       imp.total_linhas,
                       vers.id_evento
                FROM crm.tb_crm_importacoes imp
                INNER JOIN crm.tb_crm_evento_versoes vers
                    ON vers.id_crm_evento_versao = imp.id_crm_evento_versao
                WHERE imp.id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmRemapImportacao#"/>
                <cfif NOT VARIABLES.crmEffectiveIsAdmin>
                    AND EXISTS (
                        SELECT 1
                        FROM crm.tb_crm_conta_evento_versoes link
                        WHERE link.id_crm_evento_versao = imp.id_crm_evento_versao
                          AND link.status = 'ATIVO'::public.status_conta_evento
                          AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmOperatorAccountIds#" list="true"/>)
                    )
                </cfif>
                LIMIT 1
            </cfquery>

            <cfif NOT qCrmRemapImportacao.recordcount>
                <cfset VARIABLES.crmError = "Não encontrei a importação ou ela não pertence a uma conta que seu usuário opera."/>
            <cfelse>
                <cftry>
                    <cfif len(trim(qCrmRemapImportacao.mapeamento_json))>
                        <cfset VARIABLES.crmRemapPayload = deserializeJSON(qCrmRemapImportacao.mapeamento_json)/>
                    </cfif>

                    <cfif structKeyExists(VARIABLES.crmRemapPayload, "columns") AND isArray(VARIABLES.crmRemapPayload.columns)>
                        <cfset VARIABLES.crmRemapColumns = VARIABLES.crmRemapPayload.columns/>
                    </cfif>

                    <cfloop from="1" to="#arrayLen(VARIABLES.crmRemapColumns)#" index="crmRemapColumnIndex">
                        <cfset VARIABLES.crmRemapColumnSet[VARIABLES.crmRemapColumns[crmRemapColumnIndex]] = true/>
                    </cfloop>

                    <cfloop list="#VARIABLES.crmUploadManualFields#" index="crmRemapField">
                        <cfset VARIABLES.crmRemapFormKey = "map_" & crmRemapField/>
                        <cfif structKeyExists(FORM, VARIABLES.crmRemapFormKey) AND len(trim(FORM[VARIABLES.crmRemapFormKey]))>
                            <cfset VARIABLES.crmRemapColumnLabel = trim(FORM[VARIABLES.crmRemapFormKey])/>
                            <cfif structKeyExists(VARIABLES.crmRemapColumnSet, VARIABLES.crmRemapColumnLabel)>
                                <cfset VARIABLES.crmRemapFields[crmRemapField] = VARIABLES.crmRemapColumnLabel/>
                            <cfelse>
                                <cfset VARIABLES.crmError = "A coluna selecionada para " & crmRemapField & " não existe mais nesta importação."/>
                            </cfif>
                        </cfif>
                    </cfloop>

                    <cfif NOT len(VARIABLES.crmError) AND NOT len(VARIABLES.crmRemapFields["nome"])>
                        <cfset VARIABLES.crmError = "Mapeie a coluna Nome antes de confirmar a importação."/>
                    </cfif>

                    <cfif NOT len(VARIABLES.crmError)>
                        <cfset VARIABLES.crmRemapPayload["fields"] = VARIABLES.crmRemapFields/>
                        <cfset VARIABLES.crmRemapPayload["manual_fields"] = VARIABLES.crmRemapFields/>

                        <cfquery>
                            WITH params AS (
                                SELECT
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['nome']#"/>::text AS nome_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['email']#"/>::text AS email_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['documento']#"/>::text AS documento_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['tipo_documento']#"/>::text AS tipo_documento_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['data_nascimento']#"/>::text AS data_nascimento_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['sexo']#"/>::text AS sexo_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['telefone']#"/>::text AS telefone_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['cidade']#"/>::text AS cidade_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['estado']#"/>::text AS estado_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['pais']#"/>::text AS pais_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['numero_inscricao']#"/>::text AS numero_inscricao_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['numero_pedido']#"/>::text AS numero_pedido_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['protocolo']#"/>::text AS protocolo_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['numero_peito']#"/>::text AS numero_peito_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['percurso']#"/>::text AS percurso_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['modalidade']#"/>::text AS modalidade_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['categoria']#"/>::text AS categoria_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['status']#"/>::text AS status_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['origem']#"/>::text AS origem_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['campanha']#"/>::text AS campanha_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['cupom']#"/>::text AS cupom_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['camiseta']#"/>::text AS camiseta_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['assessoria']#"/>::text AS assessoria_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['data_pedido']#"/>::text AS data_pedido_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['data_pagamento']#"/>::text AS data_pagamento_key,
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmRemapFields['valor']#"/>::text AS valor_key
                            ),
                            src AS (
                                SELECT linha.id_crm_importacao_linha,
                                       nullif(linha.raw ->> params.nome_key, '') AS nome_atleta,
                                       nullif(linha.raw ->> params.email_key, '') AS email,
                                       nullif(linha.raw ->> params.documento_key, '') AS documento,
                                       nullif(linha.raw ->> params.tipo_documento_key, '') AS tipo_documento,
                                       nullif(linha.raw ->> params.data_nascimento_key, '') AS data_nascimento_raw,
                                       nullif(linha.raw ->> params.sexo_key, '') AS sexo,
                                       nullif(linha.raw ->> params.telefone_key, '') AS telefone,
                                       nullif(linha.raw ->> params.cidade_key, '') AS cidade,
                                       nullif(linha.raw ->> params.estado_key, '') AS estado,
                                       nullif(linha.raw ->> params.pais_key, '') AS pais,
                                       nullif(linha.raw ->> params.numero_inscricao_key, '') AS numero_inscricao,
                                       nullif(linha.raw ->> params.numero_pedido_key, '') AS numero_pedido,
                                       nullif(linha.raw ->> params.protocolo_key, '') AS protocolo,
                                       nullif(linha.raw ->> params.numero_peito_key, '') AS numero_peito,
                                       nullif(linha.raw ->> params.percurso_key, '') AS percurso_raw,
                                       nullif(linha.raw ->> params.modalidade_key, '') AS modalidade,
                                       nullif(linha.raw ->> params.categoria_key, '') AS categoria,
                                       nullif(linha.raw ->> params.status_key, '') AS status_inscricao,
                                       nullif(linha.raw ->> params.origem_key, '') AS origem,
                                       nullif(linha.raw ->> params.campanha_key, '') AS campanha,
                                       nullif(linha.raw ->> params.cupom_key, '') AS cupom,
                                       nullif(linha.raw ->> params.camiseta_key, '') AS camiseta,
                                       nullif(linha.raw ->> params.assessoria_key, '') AS assessoria,
                                       nullif(linha.raw ->> params.data_pedido_key, '') AS data_pedido_raw,
                                       nullif(linha.raw ->> params.data_pagamento_key, '') AS data_pagamento_raw,
                                       nullif(linha.raw ->> params.valor_key, '') AS valor_raw
                                FROM crm.tb_crm_importacao_linhas linha
                                CROSS JOIN params
                                WHERE linha.id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmRemapImportacao#"/>
                            ),
                            norm AS (
                                SELECT src.*,
                                       regexp_replace(coalesce(crm.crm_normalize_text(src.sexo), ''), '[^A-Z0-9]+', '', 'g') AS sexo_key
                                FROM src
                            )
                            UPDATE crm.tb_crm_importacao_linhas linha
                               SET nome_atleta = norm.nome_atleta,
                                   nome_norm = crm.crm_normalize_text(norm.nome_atleta),
                                   email = norm.email,
                                   email_norm = lower(nullif(trim(norm.email), '')),
                                   tipo_documento = norm.tipo_documento,
                                   documento = norm.documento,
                                   documento_norm = crm.crm_only_digits(norm.documento),
                                   telefone = norm.telefone,
                                   telefone_norm = crm.crm_only_digits(norm.telefone),
                                   data_nascimento = crm.crm_parse_date_br(norm.data_nascimento_raw),
                                   sexo = CASE
                                       WHEN norm.sexo_key IN ('M', 'MASC', 'MASCULINO', 'MALE', 'HOMEM') THEN 'M'
                                       WHEN norm.sexo_key IN ('F', 'FEM', 'FEMININO', 'FEMALE', 'MULHER') THEN 'F'
                                       WHEN norm.sexo_key IN ('X', 'OUTRO', 'OUTROS', 'OUTRA', 'NAOBINARIO', 'NAOBINARIA', 'NONBINARY', 'NB', 'DIVERSO', 'DIVERSA') THEN 'X'
                                       ELSE null
                                   END,
                                   cidade = norm.cidade,
                                   estado = upper(nullif(trim(norm.estado), '')),
                                   pais = coalesce(nullif(trim(norm.pais), ''), 'BR'),
                                   numero_inscricao = norm.numero_inscricao,
                                   numero_pedido = norm.numero_pedido,
                                   protocolo = norm.protocolo,
                                   numero_peito = norm.numero_peito,
                                   percurso = crm.crm_infer_percurso(coalesce(norm.percurso_raw, norm.modalidade, norm.categoria)),
                                   modalidade = norm.modalidade,
                                   categoria = norm.categoria,
                                   status_inscricao = norm.status_inscricao,
                                   origem = norm.origem,
                                   campanha = norm.campanha,
                                   cupom = norm.cupom,
                                   camiseta = norm.camiseta,
                                   assessoria = norm.assessoria,
                                   data_pedido = crm.crm_parse_timestamp_br(norm.data_pedido_raw),
                                   data_pagamento = crm.crm_parse_timestamp_br(norm.data_pagamento_raw),
                                   valor = crm.crm_parse_decimal_br(norm.valor_raw),
                                   normalizado = jsonb_build_object(
                                       'nome', norm.nome_atleta,
                                       'email', norm.email,
                                       'documento', norm.documento,
                                       'sexo', CASE
                                           WHEN norm.sexo_key IN ('M', 'MASC', 'MASCULINO', 'MALE', 'HOMEM') THEN 'M'
                                           WHEN norm.sexo_key IN ('F', 'FEM', 'FEMININO', 'FEMALE', 'MULHER') THEN 'F'
                                           WHEN norm.sexo_key IN ('X', 'OUTRO', 'OUTROS', 'OUTRA', 'NAOBINARIO', 'NAOBINARIA', 'NONBINARY', 'NB', 'DIVERSO', 'DIVERSA') THEN 'X'
                                           ELSE null
                                       END,
                                       'numero_inscricao', norm.numero_inscricao,
                                       'modalidade', norm.modalidade
                                   ),
                                   status_validacao = CASE WHEN crm.crm_normalize_text(norm.nome_atleta) IS NULL THEN 'invalido' ELSE 'valido' END,
                                   avisos = CASE
                                       WHEN norm.sexo IS NULL OR trim(norm.sexo) = '' THEN null
                                       WHEN norm.sexo_key IN ('M', 'F', 'X') THEN null
                                       WHEN norm.sexo_key IN ('MASC', 'MASCULINO', 'MALE', 'HOMEM') THEN jsonb_build_array('Sexo normalizado: ' || norm.sexo || ' -> M')
                                       WHEN norm.sexo_key IN ('FEM', 'FEMININO', 'FEMALE', 'MULHER') THEN jsonb_build_array('Sexo normalizado: ' || norm.sexo || ' -> F')
                                       WHEN norm.sexo_key IN ('OUTRO', 'OUTROS', 'OUTRA', 'NAOBINARIO', 'NAOBINARIA', 'NONBINARY', 'NB', 'DIVERSO', 'DIVERSA') THEN jsonb_build_array('Sexo normalizado: ' || norm.sexo || ' -> X')
                                       ELSE jsonb_build_array('Sexo não reconhecido: ' || norm.sexo)
                                   END,
                                   data_atualizacao = current_timestamp
                              FROM norm
                             WHERE linha.id_crm_importacao_linha = norm.id_crm_importacao_linha
                        </cfquery>

                        <cfquery name="qCrmRemapTotais">
                            UPDATE crm.tb_crm_importacoes imp
                               SET mapeamento = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#serializeJSON(VARIABLES.crmRemapPayload)#"/>::jsonb,
                                   status_processamento = 'mapeado',
                                   total_linhas = (
                                       SELECT count(*)::integer
                                       FROM crm.tb_crm_importacao_linhas
                                       WHERE id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmRemapImportacao#"/>
                                   ),
                                   total_validas = (
                                       SELECT count(*)::integer
                                       FROM crm.tb_crm_importacao_linhas
                                       WHERE id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmRemapImportacao#"/>
                                         AND status_validacao = 'valido'
                                   ),
                                   total_invalidas = (
                                       SELECT count(*)::integer
                                       FROM crm.tb_crm_importacao_linhas
                                       WHERE id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmRemapImportacao#"/>
                                         AND status_validacao <> 'valido'
                                   ),
                                   data_atualizacao = current_timestamp
                             WHERE imp.id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmRemapImportacao#"/>
                             RETURNING imp.total_linhas
                        </cfquery>

                        <cfquery name="qCrmUploadPreview">
                            SELECT numero_linha,
                                   nome_atleta,
                                   email,
                                   documento,
                                   sexo,
                                   cidade,
                                   estado,
                                   numero_inscricao,
                                   numero_pedido,
                                   percurso,
                                   modalidade,
                                   status_inscricao,
                                   status_validacao,
                                   (
                                       SELECT string_agg(aviso, '; ')
                                       FROM jsonb_array_elements_text(coalesce(linha.avisos, '[]'::jsonb)) aviso
                                   ) AS avisos
                            FROM crm.tb_crm_importacao_linhas linha
                            WHERE linha.id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmRemapImportacao#"/>
                            ORDER BY numero_linha
                            LIMIT 12
                        </cfquery>

                        <cfloop from="1" to="#arrayLen(VARIABLES.crmRemapColumns)#" index="crmRemapColumnIndex">
                            <cfset VARIABLES.crmRemapColumnField = ""/>
                            <cfloop list="#VARIABLES.crmUploadManualFields#" index="crmRemapField">
                                <cfif VARIABLES.crmRemapFields[crmRemapField] EQ VARIABLES.crmRemapColumns[crmRemapColumnIndex]>
                                    <cfset VARIABLES.crmRemapColumnField = crmRemapField/>
                                </cfif>
                            </cfloop>
                            <cfset queryAddRow(qCrmUploadColunas, 1)/>
                            <cfset querySetCell(qCrmUploadColunas, "ordem", crmRemapColumnIndex, qCrmUploadColunas.recordcount)/>
                            <cfset querySetCell(qCrmUploadColunas, "cabecalho", VARIABLES.crmRemapColumns[crmRemapColumnIndex], qCrmUploadColunas.recordcount)/>
                            <cfset querySetCell(qCrmUploadColunas, "campo_atual", VARIABLES.crmRemapColumnField, qCrmUploadColunas.recordcount)/>
                        </cfloop>

                        <cfloop list="#VARIABLES.crmUploadManualFields#" index="crmRemapField">
                            <cfif len(VARIABLES.crmRemapFields[crmRemapField])>
                                <cfset queryAddRow(qCrmUploadMapeamento, 1)/>
                                <cfset querySetCell(qCrmUploadMapeamento, "campo", crmRemapField, qCrmUploadMapeamento.recordcount)/>
                                <cfset querySetCell(qCrmUploadMapeamento, "coluna", "", qCrmUploadMapeamento.recordcount)/>
                                <cfset querySetCell(qCrmUploadMapeamento, "cabecalho", VARIABLES.crmRemapFields[crmRemapField], qCrmUploadMapeamento.recordcount)/>
                            </cfif>
                        </cfloop>

                        <cfset VARIABLES.crmPreviewImportacao = VARIABLES.crmRemapImportacao/>
                        <cfset VARIABLES.crmPreviewTotalLinhas = qCrmRemapTotais.total_linhas/>
                        <cfset VARIABLES.crmIdEventoFiltro = qCrmRemapImportacao.id_evento/>
                        <cfset VARIABLES.crmNotice = "Mapeamento atualizado. Revise a prévia antes de confirmar."/>
                    </cfif>

                    <cfcatch type="any">
                        <cfset VARIABLES.crmError = "Não foi possível atualizar o mapeamento: " & cfcatch.message/>
                        <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
                            <cfset VARIABLES.crmError = VARIABLES.crmError & " - " & left(trim(cfcatch.detail), 800)/>
                        <cfelseif structKeyExists(cfcatch, "sql") AND len(trim(cfcatch.sql))>
                            <cfset VARIABLES.crmError = VARIABLES.crmError & " - SQL: " & left(reReplace(trim(cfcatch.sql), "\s+", " ", "all"), 800)/>
                        </cfif>
                    </cfcatch>
                </cftry>
            </cfif>
        </cfif>
    </cfif>

    <cfif isDefined("FORM.acao") AND FORM.acao EQ "confirmar_importacao_arquivo">
        <cfset VARIABLES.crmConfirmImportacao = ""/>

        <cfif isDefined("FORM.id_crm_importacao")>
            <cfset VARIABLES.crmConfirmImportacao = trim(FORM.id_crm_importacao)/>
        </cfif>

        <cfif NOT isNumeric(VARIABLES.crmConfirmImportacao)>
            <cfset VARIABLES.crmError = "Importação inválida para confirmação."/>
        <cfelseif NOT VARIABLES.crmCanOperate>
            <cfset VARIABLES.crmError = "Seu usuário não tem permissão para processar arquivos CRM."/>
        <cfelse>
            <cfquery name="qCrmConfirmImportacao">
                SELECT imp.id_crm_importacao,
                       vers.id_evento
                FROM crm.tb_crm_importacoes imp
                INNER JOIN crm.tb_crm_evento_versoes vers
                    ON vers.id_crm_evento_versao = imp.id_crm_evento_versao
                WHERE imp.id_crm_importacao = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmConfirmImportacao#"/>
                <cfif NOT VARIABLES.crmEffectiveIsAdmin>
                    AND EXISTS (
                        SELECT 1
                        FROM crm.tb_crm_conta_evento_versoes link
                        WHERE link.id_crm_evento_versao = imp.id_crm_evento_versao
                          AND link.status = 'ATIVO'::public.status_conta_evento
                          AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmOperatorAccountIds#" list="true"/>)
                    )
                </cfif>
                LIMIT 1
            </cfquery>

            <cfif NOT qCrmConfirmImportacao.recordcount>
                <cfset VARIABLES.crmError = "Não encontrei a importação ou ela não pertence a uma conta que seu usuário opera."/>
            <cfelse>
                <cftry>
                    <cfquery name="qCrmUploadProcess">
                        SELECT *
                        FROM crm.crm_processar_importacao_arquivo(
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmConfirmImportacao#"/>
                        )
                    </cfquery>

                    <cfset VARIABLES.crmIdEventoFiltro = qCrmConfirmImportacao.id_evento/>
                    <cfset VARIABLES.crmNotice = "Importação confirmada e processada no CRM."/>

                    <cfcatch type="any">
                        <cfset VARIABLES.crmError = "Não foi possível processar a importação: " & cfcatch.message/>
                        <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail))>
                            <cfset VARIABLES.crmError = VARIABLES.crmError & " - " & left(trim(cfcatch.detail), 800)/>
                        <cfelseif structKeyExists(cfcatch, "sql") AND len(trim(cfcatch.sql))>
                            <cfset VARIABLES.crmError = VARIABLES.crmError & " - SQL: " & left(reReplace(trim(cfcatch.sql), "\s+", " ", "all"), 800)/>
                        </cfif>
                    </cfcatch>
                </cftry>
            </cfif>
        </cfif>
    </cfif>

    <cfif isDefined("FORM.acao") AND FORM.acao EQ "match_usuarios">
        <cfset VARIABLES.crmMatchIdConta = ""/>

        <cfif isDefined("FORM.id_conta")>
            <cfset VARIABLES.crmMatchIdConta = trim(FORM.id_conta)/>
        </cfif>

        <cfif len(VARIABLES.crmMatchIdConta) AND NOT isNumeric(VARIABLES.crmMatchIdConta)>
            <cfset VARIABLES.crmMatchIdConta = ""/>
        </cfif>

        <cfif NOT VARIABLES.crmCanOperate>
            <cfset VARIABLES.crmError = "Seu usuário não tem permissão para processar vínculos RR."/>
        <cfelseif NOT VARIABLES.crmEffectiveIsAdmin AND NOT len(VARIABLES.crmMatchIdConta) AND listLen(VARIABLES.crmEffectiveAccountIds) EQ 1>
            <cfset VARIABLES.crmMatchIdConta = VARIABLES.crmEffectiveAccountIds/>
        </cfif>

        <cfif NOT len(VARIABLES.crmError)>
            <cfif NOT VARIABLES.crmEffectiveIsAdmin AND NOT listFind(VARIABLES.crmOperatorAccountIds, VARIABLES.crmMatchIdConta)>
                <cfset VARIABLES.crmError = "Selecione uma conta que seu usuário possa operar para processar vínculos RR."/>
            <cfelse>
                <cfquery name="qCrmMatchResultados">
                    SELECT *
                    FROM crm.crm_match_resultados(
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmMatchIdConta#" null="#len(VARIABLES.crmMatchIdConta) EQ 0#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="" null="true"/>
                    )
                </cfquery>

                <cfquery name="qCrmMatchUsuarios">
                    SELECT *
                    FROM crm.crm_match_usuarios(
                        <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmMatchIdConta#" null="#len(VARIABLES.crmMatchIdConta) EQ 0#"/>
                    )
                </cfquery>

                <cfif len(VARIABLES.crmMatchIdConta)>
                    <cfset VARIABLES.crmIdConta = VARIABLES.crmMatchIdConta/>
                    <cfset VARIABLES.crmAccountFilterIds = VARIABLES.crmMatchIdConta/>
                </cfif>
            </cfif>
        </cfif>
    </cfif>

    <cfset VARIABLES.crmInImportPreview = qCrmUploadPreview.recordcount GT 0/>

    <cfif NOT VARIABLES.crmInImportPreview>
    <cfquery name="qCrmContas">
        SELECT cont.id_conta,
               cont.nome_conta,
               cont.status::varchar AS status,
               0::integer AS total_versoes
        FROM public.tb_contas cont
        WHERE cont.status = 'ATIVA'::public.status_conta
        <cfif NOT VARIABLES.crmEffectiveIsAdmin>
            AND cont.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmEffectiveAccountIds#" list="true"/>)
        </cfif>
        ORDER BY cont.nome_conta
    </cfquery>

    <cfif len(VARIABLES.crmIdConta)>
        <cfquery name="qCrmContaValida">
            SELECT id_conta
            FROM public.tb_contas
            WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmIdConta#"/>
            <cfif NOT VARIABLES.crmEffectiveIsAdmin>
                AND id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmEffectiveAccountIds#" list="true"/>)
            </cfif>
        </cfquery>

        <cfif NOT qCrmContaValida.recordcount>
            <cfset VARIABLES.crmIdConta = ""/>
            <cfif VARIABLES.crmEffectiveIsAdmin>
                <cfset VARIABLES.crmAccountFilterIds = ""/>
            <cfelse>
                <cfset VARIABLES.crmAccountFilterIds = VARIABLES.crmEffectiveAccountIds/>
            </cfif>
        </cfif>
    </cfif>

    <cfquery name="qCrmEventosConta">
        SELECT evt.id_evento,
               evt.nome_evento,
               evt.data_inicial,
               extract(year from evt.data_inicial)::integer AS ano_evento,
               evt.cidade,
               evt.estado,
               string_agg(DISTINCT cont.nome_conta, ', ' ORDER BY cont.nome_conta) AS contas
        FROM public.tb_conta_eventos cev
        INNER JOIN public.tb_evento_corridas evt
            ON evt.id_evento = cev.id_evento
        INNER JOIN public.tb_contas cont
            ON cont.id_conta = cev.id_conta
        WHERE cev.status = 'ATIVO'::public.status_conta_evento
          AND cont.status = 'ATIVA'::public.status_conta
          AND evt.ativo = true
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND cev.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
        <cfelseif NOT VARIABLES.crmEffectiveIsAdmin>
            AND cev.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmEffectiveAccountIds#" list="true"/>)
        </cfif>
        GROUP BY evt.id_evento,
                 evt.nome_evento,
                 evt.data_inicial,
                 evt.cidade,
                 evt.estado
        ORDER BY evt.data_inicial DESC,
                 evt.nome_evento
    </cfquery>

    <cfquery name="qCrmEventos">
        SELECT part.id_evento,
               max(coalesce(evt.nome_evento, part.nome_evento_externo, vers.nome_evento_externo)) AS nome_evento,
               max(part.ano_evento) AS ano_evento,
               string_agg(DISTINCT part.fonte, ', ' ORDER BY part.fonte) AS fontes,
               string_agg(DISTINCT part.cod_evento_externo, ', ' ORDER BY part.cod_evento_externo)
                   FILTER (WHERE part.cod_evento_externo IS NOT NULL AND trim(part.cod_evento_externo) <> '') AS codigos,
               count(*)::integer AS total
        FROM crm.tb_crm_participacoes part
        LEFT JOIN crm.tb_crm_evento_versoes vers
            ON vers.id_crm_evento_versao = part.id_crm_evento_versao
        LEFT JOIN public.tb_evento_corridas evt
            ON evt.id_evento = part.id_evento
        WHERE part.id_evento IS NOT NULL
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
            )
        </cfif>
        GROUP BY part.id_evento
        ORDER BY max(part.ano_evento) DESC NULLS LAST,
                 max(coalesce(evt.nome_evento, part.nome_evento_externo, vers.nome_evento_externo))
    </cfquery>

    <cfquery name="qCrmFontesPendentes">
        SELECT part.id_crm_evento_versao,
               part.fonte,
               part.cod_evento_externo,
               max(coalesce(part.nome_evento_externo, vers.nome_evento_externo)) AS nome_evento,
               max(part.ano_evento) AS ano_evento,
               count(*)::integer AS total
        FROM crm.tb_crm_participacoes part
        LEFT JOIN crm.tb_crm_evento_versoes vers
            ON vers.id_crm_evento_versao = part.id_crm_evento_versao
        WHERE part.id_evento IS NULL
          AND part.cod_evento_externo IS NOT NULL
          AND trim(part.cod_evento_externo) <> ''
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
            )
        </cfif>
        GROUP BY part.id_crm_evento_versao,
                 part.fonte,
                 part.cod_evento_externo
        ORDER BY max(part.ano_evento) DESC NULLS LAST,
                 part.fonte,
                 part.cod_evento_externo
        LIMIT 20
    </cfquery>

    <cfquery name="qCrmAnos">
        SELECT part.ano_evento,
               count(*)::integer AS total
        FROM crm.tb_crm_participacoes part
        WHERE part.ano_evento IS NOT NULL
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
            )
        </cfif>
        GROUP BY part.ano_evento
        ORDER BY part.ano_evento DESC
    </cfquery>

    <cfquery name="qCrmPercursos">
        SELECT part.percurso,
               count(*)::integer AS total
        FROM crm.tb_crm_participacoes part
        WHERE part.percurso IS NOT NULL
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
            )
        </cfif>
        GROUP BY part.percurso
        ORDER BY part.percurso
    </cfquery>

    <cfquery name="qCrmStatus">
        SELECT coalesce(nullif(trim(coalesce(part.status_pedido, ped.status_pedido)), ''), 'Sem status') AS status_pedido,
               count(*)::integer AS total
        FROM crm.tb_crm_participacoes part
        LEFT JOIN crm.tb_crm_pedidos ped
            ON ped.id_crm_pedido = part.id_crm_pedido
        WHERE 1 = 1
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
                )
            </cfif>
        GROUP BY coalesce(nullif(trim(coalesce(part.status_pedido, ped.status_pedido)), ''), 'Sem status')
        ORDER BY total DESC, status_pedido
    </cfquery>

    <cfquery name="qCrmEstados">
        SELECT pessoa.estado,
               count(*)::integer AS total
        FROM crm.tb_crm_participacoes part
        INNER JOIN crm.tb_crm_pessoas pessoa
            ON pessoa.id_crm_pessoa = part.id_crm_pessoa
        WHERE pessoa.estado IS NOT NULL
          AND trim(pessoa.estado) <> ''
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
                )
            </cfif>
        GROUP BY pessoa.estado
        ORDER BY total DESC, pessoa.estado
        LIMIT 30
    </cfquery>

    <cfquery name="qCrmStats">
        WITH base AS (
            SELECT part.id_crm_participacao,
                   part.id_crm_pessoa,
                   coalesce(part.status_pedido, ped.status_pedido) AS status_pedido,
                   coalesce(part.correu, part.id_resultado IS NOT NULL, false) AS correu,
                   pessoa.id_usuario
            FROM crm.tb_crm_participacoes part
            INNER JOIN crm.tb_crm_pessoas pessoa
                ON pessoa.id_crm_pessoa = part.id_crm_pessoa
            LEFT JOIN crm.tb_crm_pedidos ped
                ON ped.id_crm_pedido = part.id_crm_pedido
            WHERE 1 = 1
            <cfif len(VARIABLES.crmAccountFilterIds)>
                AND EXISTS (
                    SELECT 1
                    FROM crm.tb_crm_conta_evento_versoes link
                    WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                      AND link.status = 'ATIVO'::public.status_conta_evento
                      AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
                )
            </cfif>
            <cfif len(VARIABLES.crmBusca)>
                AND (
                    pessoa.nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                    OR pessoa.email ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                    OR pessoa.documento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                    OR pessoa.telefone ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                    OR part.numero_inscricao ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                    OR part.numero_pedido ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                )
            </cfif>
            <cfif len(VARIABLES.crmIdEventoFiltro)>
                AND part.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmIdEventoFiltro#"/>
            </cfif>
            <cfif len(VARIABLES.crmAnoEvento)>
                AND part.ano_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmAnoEvento#"/>
            </cfif>
            <cfif len(VARIABLES.crmPercurso)>
                AND part.percurso = <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.crmPercurso#"/>
            </cfif>
            <cfif len(VARIABLES.crmStatus)>
                AND coalesce(nullif(trim(coalesce(part.status_pedido, ped.status_pedido)), ''), 'Sem status') = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmStatus#"/>
            </cfif>
            <cfif len(VARIABLES.crmUf)>
                AND pessoa.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUf#"/>
            </cfif>
            <cfif VARIABLES.crmCorreu EQ "sim">
                AND coalesce(part.correu, part.id_resultado IS NOT NULL, false) = true
            <cfelseif VARIABLES.crmCorreu EQ "nao">
                AND coalesce(part.correu, part.id_resultado IS NOT NULL, false) = false
            </cfif>
            <cfif VARIABLES.crmVinculo EQ "com_usuario">
                AND pessoa.id_usuario IS NOT NULL
            <cfelseif VARIABLES.crmVinculo EQ "sem_usuario">
                AND pessoa.id_usuario IS NULL
            </cfif>
        )
        SELECT count(*)::integer AS total_participacoes,
               count(DISTINCT id_crm_pessoa)::integer AS total_leads,
               count(*) FILTER (WHERE coalesce(status_pedido, '') ILIKE 'Pago')::integer AS total_pagos,
               count(*) FILTER (WHERE coalesce(correu, false) = true)::integer AS total_corredores,
               count(DISTINCT id_crm_pessoa) FILTER (WHERE id_usuario IS NOT NULL)::integer AS total_vinculados
        FROM base
    </cfquery>

    <cfquery name="qCrmTotalRows">
        SELECT count(*)::integer AS total
        FROM crm.tb_crm_participacoes part
        INNER JOIN crm.tb_crm_pessoas pessoa
            ON pessoa.id_crm_pessoa = part.id_crm_pessoa
        LEFT JOIN crm.tb_crm_pedidos ped
            ON ped.id_crm_pedido = part.id_crm_pedido
        WHERE 1 = 1
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
            )
        </cfif>
        <cfif len(VARIABLES.crmBusca)>
            AND (
                pessoa.nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR pessoa.email ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR pessoa.documento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR pessoa.telefone ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR part.numero_inscricao ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR part.numero_pedido ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
            )
        </cfif>
        <cfif len(VARIABLES.crmIdEventoFiltro)>
            AND part.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmIdEventoFiltro#"/>
        </cfif>
        <cfif len(VARIABLES.crmAnoEvento)>
            AND part.ano_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmAnoEvento#"/>
        </cfif>
        <cfif len(VARIABLES.crmPercurso)>
            AND part.percurso = <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.crmPercurso#"/>
        </cfif>
        <cfif len(VARIABLES.crmStatus)>
            AND coalesce(nullif(trim(coalesce(part.status_pedido, ped.status_pedido)), ''), 'Sem status') = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmStatus#"/>
        </cfif>
        <cfif len(VARIABLES.crmUf)>
            AND pessoa.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUf#"/>
        </cfif>
        <cfif VARIABLES.crmCorreu EQ "sim">
            AND coalesce(part.correu, part.id_resultado IS NOT NULL, false) = true
        <cfelseif VARIABLES.crmCorreu EQ "nao">
            AND coalesce(part.correu, part.id_resultado IS NOT NULL, false) = false
        </cfif>
        <cfif VARIABLES.crmVinculo EQ "com_usuario">
            AND pessoa.id_usuario IS NOT NULL
        <cfelseif VARIABLES.crmVinculo EQ "sem_usuario">
            AND pessoa.id_usuario IS NULL
        </cfif>
    </cfquery>

    <cfset VARIABLES.crmTotalPaginas = max(1, ceiling(qCrmTotalRows.total / VARIABLES.crmPorPagina))/>
    <cfif VARIABLES.crmPagina GT VARIABLES.crmTotalPaginas>
        <cfset VARIABLES.crmPagina = VARIABLES.crmTotalPaginas/>
        <cfset VARIABLES.crmOffset = (VARIABLES.crmPagina - 1) * VARIABLES.crmPorPagina/>
    </cfif>

    <cfquery name="qCrmParticipacoes">
        SELECT part.id_crm_participacao,
               part.id_evento,
               pessoa.nome,
               pessoa.email,
               pessoa.telefone,
               pessoa.documento,
               pessoa.cidade,
               pessoa.estado,
               part.cod_evento_externo,
               coalesce(evt.nome_evento, part.nome_evento_externo, vers.nome_evento_externo) AS nome_evento,
               part.ano_evento,
               part.percurso,
               part.modalidade,
               coalesce(part.status_pedido, ped.status_pedido) AS status_pedido,
               part.numero_inscricao,
               part.numero_pedido,
               coalesce(part.data_pedido, ped.data_pedido) AS data_pedido,
               part.lead_score,
               coalesce(part.correu, part.id_resultado IS NOT NULL, false) AS correu,
               part.concluinte,
               pessoa.id_usuario
        FROM crm.tb_crm_participacoes part
        INNER JOIN crm.tb_crm_pessoas pessoa
            ON pessoa.id_crm_pessoa = part.id_crm_pessoa
        LEFT JOIN crm.tb_crm_pedidos ped
            ON ped.id_crm_pedido = part.id_crm_pedido
        LEFT JOIN crm.tb_crm_evento_versoes vers
            ON vers.id_crm_evento_versao = part.id_crm_evento_versao
        LEFT JOIN public.tb_evento_corridas evt
            ON evt.id_evento = part.id_evento
        WHERE 1 = 1
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = part.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
            )
        </cfif>
        <cfif len(VARIABLES.crmBusca)>
            AND (
                pessoa.nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR pessoa.email ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR pessoa.documento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR pessoa.telefone ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR part.numero_inscricao ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
                OR part.numero_pedido ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.crmBusca#%"/>
            )
        </cfif>
        <cfif len(VARIABLES.crmIdEventoFiltro)>
            AND part.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmIdEventoFiltro#"/>
        </cfif>
        <cfif len(VARIABLES.crmAnoEvento)>
            AND part.ano_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmAnoEvento#"/>
        </cfif>
        <cfif len(VARIABLES.crmPercurso)>
            AND part.percurso = <cfqueryparam cfsqltype="cf_sql_decimal" value="#VARIABLES.crmPercurso#"/>
        </cfif>
        <cfif len(VARIABLES.crmStatus)>
            AND coalesce(nullif(trim(coalesce(part.status_pedido, ped.status_pedido)), ''), 'Sem status') = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmStatus#"/>
        </cfif>
        <cfif len(VARIABLES.crmUf)>
            AND pessoa.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.crmUf#"/>
        </cfif>
        <cfif VARIABLES.crmCorreu EQ "sim">
            AND coalesce(part.correu, part.id_resultado IS NOT NULL, false) = true
        <cfelseif VARIABLES.crmCorreu EQ "nao">
            AND coalesce(part.correu, part.id_resultado IS NOT NULL, false) = false
        </cfif>
        <cfif VARIABLES.crmVinculo EQ "com_usuario">
            AND pessoa.id_usuario IS NOT NULL
        <cfelseif VARIABLES.crmVinculo EQ "sem_usuario">
            AND pessoa.id_usuario IS NULL
        </cfif>
        ORDER BY coalesce(part.data_pedido, ped.data_pedido, part.data_criacao) DESC, pessoa.nome
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmPorPagina#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.crmOffset#"/>
    </cfquery>

    <cfquery name="qCrmImportacoes">
        SELECT id_crm_importacao,
               nome_importacao,
               fonte,
               origem_tipo,
               status_processamento,
               total_linhas,
               total_validas,
               total_invalidas,
               data_criacao
        FROM crm.tb_crm_importacoes imp
        WHERE 1 = 1
        <cfif len(VARIABLES.crmAccountFilterIds)>
            AND EXISTS (
                SELECT 1
                FROM crm.tb_crm_conta_evento_versoes link
                WHERE link.id_crm_evento_versao = imp.id_crm_evento_versao
                  AND link.status = 'ATIVO'::public.status_conta_evento
                  AND link.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.crmAccountFilterIds#" list="true"/>)
            )
        </cfif>
        ORDER BY data_criacao DESC
        LIMIT 10
    </cfquery>
    </cfif>
</cfif>
