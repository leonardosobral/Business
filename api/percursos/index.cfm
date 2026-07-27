<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="includes/common.cfm"/>

<cfparam name="URL.q" default=""/>
<cfparam name="URL.estado" default=""/>
<cfparam name="URL.data_inicio" default=""/>
<cfparam name="URL.data_fim" default=""/>
<cfparam name="URL.pagina" default="1"/>
<cfparam name="URL.por_pagina" default="20"/>

<cfset VARIABLES.percursoApiSearch = left(trim(URL.q & ""), 120)/>
<cfset VARIABLES.percursoApiState = uCase(left(trim(URL.estado & ""), 2))/>
<cfset VARIABLES.percursoApiPage = isNumeric(URL.pagina) ? max(1, int(URL.pagina)) : 1/>
<cfset VARIABLES.percursoApiPerPage = isNumeric(URL.por_pagina) ? min(100, max(1, int(URL.por_pagina))) : 20/>
<cfset VARIABLES.percursoApiOffset = (VARIABLES.percursoApiPage - 1) * VARIABLES.percursoApiPerPage/>

<cfif len(URL.data_inicio & "") AND NOT isDate(URL.data_inicio)>
    <cfset percursoApiWrite({success=false,error="invalid_start_date",message="data_inicio deve usar o formato AAAA-MM-DD."}, 400, "Bad Request")/>
</cfif>
<cfif len(URL.data_fim & "") AND NOT isDate(URL.data_fim)>
    <cfset percursoApiWrite({success=false,error="invalid_end_date",message="data_fim deve usar o formato AAAA-MM-DD."}, 400, "Bad Request")/>
</cfif>

<cfquery name="qPercursoApiCount">
    SELECT count(DISTINCT evento.id_evento)::integer AS total
    FROM tb_evento_corridas evento
    WHERE EXISTS (
        SELECT 1
        FROM tb_evento_percursos_gpx vinculo
        INNER JOIN tb_evento_corridas_percursos modalidade
            ON modalidade.id_evento_percurso = vinculo.id_evento_percurso
           AND modalidade.id_evento = vinculo.id_evento
        INNER JOIN tb_percursos percurso
            ON percurso.id_percurso = vinculo.id_percurso
           AND percurso.status = 'publicado'
        INNER JOIN tb_percurso_arquivos arquivo
            ON arquivo.id_percurso = percurso.id_percurso
           AND arquivo.ativo = true
        WHERE vinculo.id_evento = evento.id_evento
          AND vinculo.id_evento_percurso IS NOT NULL
    )
    <cfif len(VARIABLES.percursoApiSearch)>
        AND (
            evento.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.percursoApiSearch#%"/>
            OR evento.cidade ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.percursoApiSearch#%"/>
            OR evento.tag ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.percursoApiSearch#%"/>
            OR EXISTS (
                SELECT 1
                FROM tb_evento_percursos_gpx busca_vinculo
                INNER JOIN tb_evento_corridas_percursos busca_modalidade
                    ON busca_modalidade.id_evento_percurso = busca_vinculo.id_evento_percurso
                   AND busca_modalidade.id_evento = busca_vinculo.id_evento
                INNER JOIN tb_percursos busca_percurso ON busca_percurso.id_percurso = busca_vinculo.id_percurso
                INNER JOIN tb_percurso_arquivos busca_arquivo
                    ON busca_arquivo.id_percurso = busca_percurso.id_percurso
                   AND busca_arquivo.ativo = true
                WHERE busca_vinculo.id_evento = evento.id_evento
                  AND busca_percurso.status = 'publicado'
                  AND busca_percurso.nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.percursoApiSearch#%"/>
            )
        )
    </cfif>
    <cfif len(VARIABLES.percursoApiState)>
        AND evento.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.percursoApiState#"/>
    </cfif>
    <cfif len(URL.data_inicio & "")>
        AND evento.data_final &gt;= <cfqueryparam cfsqltype="cf_sql_date" value="#URL.data_inicio#"/>
    </cfif>
    <cfif len(URL.data_fim & "")>
        AND evento.data_inicial &lt;= <cfqueryparam cfsqltype="cf_sql_date" value="#URL.data_fim#"/>
    </cfif>
</cfquery>

<cfquery name="qPercursoApiRows">
    WITH eventos AS (
        SELECT evento.id_evento,
               evento.nome_evento,
               evento.tag,
               evento.cidade,
               evento.estado,
               evento.pais,
               evento.data_inicial,
               evento.data_final
        FROM tb_evento_corridas evento
        WHERE EXISTS (
            SELECT 1
            FROM tb_evento_percursos_gpx vinculo
            INNER JOIN tb_evento_corridas_percursos modalidade
                ON modalidade.id_evento_percurso = vinculo.id_evento_percurso
               AND modalidade.id_evento = vinculo.id_evento
            INNER JOIN tb_percursos percurso
                ON percurso.id_percurso = vinculo.id_percurso
               AND percurso.status = 'publicado'
            INNER JOIN tb_percurso_arquivos arquivo
                ON arquivo.id_percurso = percurso.id_percurso
               AND arquivo.ativo = true
            WHERE vinculo.id_evento = evento.id_evento
              AND vinculo.id_evento_percurso IS NOT NULL
        )
        <cfif len(VARIABLES.percursoApiSearch)>
            AND (
                evento.nome_evento ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.percursoApiSearch#%"/>
                OR evento.cidade ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.percursoApiSearch#%"/>
                OR evento.tag ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.percursoApiSearch#%"/>
                OR EXISTS (
                    SELECT 1
                    FROM tb_evento_percursos_gpx busca_vinculo
                    INNER JOIN tb_evento_corridas_percursos busca_modalidade
                        ON busca_modalidade.id_evento_percurso = busca_vinculo.id_evento_percurso
                       AND busca_modalidade.id_evento = busca_vinculo.id_evento
                    INNER JOIN tb_percursos busca_percurso ON busca_percurso.id_percurso = busca_vinculo.id_percurso
                    INNER JOIN tb_percurso_arquivos busca_arquivo
                        ON busca_arquivo.id_percurso = busca_percurso.id_percurso
                       AND busca_arquivo.ativo = true
                    WHERE busca_vinculo.id_evento = evento.id_evento
                      AND busca_percurso.status = 'publicado'
                      AND busca_percurso.nome ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.percursoApiSearch#%"/>
                )
            )
        </cfif>
        <cfif len(VARIABLES.percursoApiState)>
            AND evento.estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.percursoApiState#"/>
        </cfif>
        <cfif len(URL.data_inicio & "")>
            AND evento.data_final &gt;= <cfqueryparam cfsqltype="cf_sql_date" value="#URL.data_inicio#"/>
        </cfif>
        <cfif len(URL.data_fim & "")>
            AND evento.data_inicial &lt;= <cfqueryparam cfsqltype="cf_sql_date" value="#URL.data_fim#"/>
        </cfif>
        ORDER BY evento.data_inicial DESC, evento.nome_evento, evento.id_evento
        LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.percursoApiPerPage#"/>
        OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.percursoApiOffset#"/>
    )
    SELECT eventos.*,
           modalidade.id_evento_percurso,
           modalidade.percurso_evento,
           modalidade.unidade_de_medida,
           modalidade.tipo_corrida AS modalidade_tipo,
           modalidade.data_percurso,
           modalidade.hora_largada,
           percurso.id_percurso,
           percurso.codigo_publico,
           percurso.nome AS percurso_nome,
           percurso.tipo_percurso,
           percurso.distancia_nominal_m,
           arquivo.id_percurso_arquivo,
           arquivo.versao,
           arquivo.sha256,
           arquivo.quantidade_pontos,
           arquivo.distancia_gpx_m,
           arquivo.elevacao_min_m,
           arquivo.elevacao_max_m,
           arquivo.ganho_elevacao_m,
           arquivo.bbox_min_lat,
           arquivo.bbox_min_lng,
           arquivo.bbox_max_lat,
           arquivo.bbox_max_lng
    FROM eventos
    INNER JOIN tb_evento_percursos_gpx vinculo ON vinculo.id_evento = eventos.id_evento
    INNER JOIN tb_evento_corridas_percursos modalidade
        ON modalidade.id_evento_percurso = vinculo.id_evento_percurso
       AND modalidade.id_evento = vinculo.id_evento
    INNER JOIN tb_percursos percurso
        ON percurso.id_percurso = vinculo.id_percurso
       AND percurso.status = 'publicado'
    INNER JOIN LATERAL (
        SELECT arquivo.*
        FROM tb_percurso_arquivos arquivo
        WHERE arquivo.id_percurso = percurso.id_percurso
          AND arquivo.ativo = true
        ORDER BY arquivo.versao DESC
        LIMIT 1
    ) arquivo ON true
    ORDER BY eventos.data_inicial DESC,
             eventos.nome_evento,
             eventos.id_evento,
             modalidade.percurso_evento,
             modalidade.id_evento_percurso
</cfquery>

<cfscript>
VARIABLES.percursoApiEvents = [];
VARIABLES.percursoApiEventIndexes = {};

for (VARIABLES.percursoApiRow = 1; VARIABLES.percursoApiRow <= qPercursoApiRows.recordcount; VARIABLES.percursoApiRow++) {
    VARIABLES.percursoApiEventKey = qPercursoApiRows.id_evento[VARIABLES.percursoApiRow] & "";

    if (!structKeyExists(VARIABLES.percursoApiEventIndexes, VARIABLES.percursoApiEventKey)) {
        arrayAppend(VARIABLES.percursoApiEvents, {
            idEvento = val(qPercursoApiRows.id_evento[VARIABLES.percursoApiRow]),
            nome = qPercursoApiRows.nome_evento[VARIABLES.percursoApiRow] & "",
            tag = percursoApiNullableString(qPercursoApiRows.tag[VARIABLES.percursoApiRow]),
            cidade = percursoApiNullableString(qPercursoApiRows.cidade[VARIABLES.percursoApiRow]),
            estado = percursoApiNullableString(qPercursoApiRows.estado[VARIABLES.percursoApiRow]),
            pais = qPercursoApiRows.pais[VARIABLES.percursoApiRow] & "",
            dataInicial = percursoApiDate(qPercursoApiRows.data_inicial[VARIABLES.percursoApiRow]),
            dataFinal = percursoApiDate(qPercursoApiRows.data_final[VARIABLES.percursoApiRow]),
            detalheUrl = percursoApiBaseUrl() & "/api/percursos/evento.cfm?id_evento=" & qPercursoApiRows.id_evento[VARIABLES.percursoApiRow],
            percursos = []
        });
        VARIABLES.percursoApiEventIndexes[VARIABLES.percursoApiEventKey] = arrayLen(VARIABLES.percursoApiEvents);
    }

    VARIABLES.percursoApiEventIndex = VARIABLES.percursoApiEventIndexes[VARIABLES.percursoApiEventKey];
    arrayAppend(VARIABLES.percursoApiEvents[VARIABLES.percursoApiEventIndex].percursos, {
        idEventoPercurso = val(qPercursoApiRows.id_evento_percurso[VARIABLES.percursoApiRow]),
        distancia = percursoApiNumber(qPercursoApiRows.percurso_evento[VARIABLES.percursoApiRow]),
        unidade = qPercursoApiRows.unidade_de_medida[VARIABLES.percursoApiRow] & "",
        modalidade = percursoApiNullableString(qPercursoApiRows.modalidade_tipo[VARIABLES.percursoApiRow]),
        data = percursoApiDate(qPercursoApiRows.data_percurso[VARIABLES.percursoApiRow]),
        horaLargada = percursoApiNullableString(qPercursoApiRows.hora_largada[VARIABLES.percursoApiRow]),
        idPercurso = val(qPercursoApiRows.id_percurso[VARIABLES.percursoApiRow]),
        codigoPublico = qPercursoApiRows.codigo_publico[VARIABLES.percursoApiRow] & "",
        nome = qPercursoApiRows.percurso_nome[VARIABLES.percursoApiRow] & "",
        tipo = qPercursoApiRows.tipo_percurso[VARIABLES.percursoApiRow] & "",
        distanciaNominalM = percursoApiNumber(qPercursoApiRows.distancia_nominal_m[VARIABLES.percursoApiRow]),
        arquivo = {
            id = val(qPercursoApiRows.id_percurso_arquivo[VARIABLES.percursoApiRow]),
            versao = val(qPercursoApiRows.versao[VARIABLES.percursoApiRow]),
            pontos = val(qPercursoApiRows.quantidade_pontos[VARIABLES.percursoApiRow]),
            distanciaM = percursoApiNumber(qPercursoApiRows.distancia_gpx_m[VARIABLES.percursoApiRow]),
            elevacaoMinM = percursoApiNumber(qPercursoApiRows.elevacao_min_m[VARIABLES.percursoApiRow]),
            elevacaoMaxM = percursoApiNumber(qPercursoApiRows.elevacao_max_m[VARIABLES.percursoApiRow]),
            ganhoElevacaoM = percursoApiNumber(qPercursoApiRows.ganho_elevacao_m[VARIABLES.percursoApiRow]),
            bbox = [
                percursoApiNumber(qPercursoApiRows.bbox_min_lng[VARIABLES.percursoApiRow]),
                percursoApiNumber(qPercursoApiRows.bbox_min_lat[VARIABLES.percursoApiRow]),
                percursoApiNumber(qPercursoApiRows.bbox_max_lng[VARIABLES.percursoApiRow]),
                percursoApiNumber(qPercursoApiRows.bbox_max_lat[VARIABLES.percursoApiRow])
            ],
            geometriaUrl = percursoApiGeometryUrl(
                qPercursoApiRows.id_evento_percurso[VARIABLES.percursoApiRow],
                qPercursoApiRows.id_percurso_arquivo[VARIABLES.percursoApiRow],
                qPercursoApiRows.sha256[VARIABLES.percursoApiRow] & ""
            )
        }
    });
}

percursoApiWrite({
    success = true,
    filtros = {
        q = VARIABLES.percursoApiSearch,
        estado = VARIABLES.percursoApiState,
        dataInicio = len(URL.data_inicio & "") ? URL.data_inicio & "" : javacast("null", ""),
        dataFim = len(URL.data_fim & "") ? URL.data_fim & "" : javacast("null", "")
    },
    paginacao = {
        pagina = VARIABLES.percursoApiPage,
        porPagina = VARIABLES.percursoApiPerPage,
        total = val(qPercursoApiCount.total),
        totalPaginas = ceiling(val(qPercursoApiCount.total) / VARIABLES.percursoApiPerPage)
    },
    eventos = VARIABLES.percursoApiEvents
});
</cfscript>
