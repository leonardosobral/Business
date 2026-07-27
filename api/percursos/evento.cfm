<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="includes/common.cfm"/>

<cfparam name="URL.id_evento" default=""/>

<cfif NOT isNumeric(URL.id_evento) OR val(URL.id_evento) LTE 0 OR val(URL.id_evento) NEQ int(val(URL.id_evento))>
    <cfset percursoApiWrite({success=false,error="invalid_event_id",message="Informe um id_evento inteiro e positivo."}, 400, "Bad Request")/>
</cfif>

<cfquery name="qPercursoApiEvent">
    SELECT id_evento, nome_evento, tag, cidade, estado, pais, data_inicial, data_final
    FROM tb_evento_corridas
    WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
</cfquery>

<cfif NOT qPercursoApiEvent.recordcount>
    <cfset percursoApiWrite({success=false,error="event_not_found",message="Evento nao encontrado."}, 404, "Not Found")/>
</cfif>

<cfquery name="qPercursoApiEventRoutes">
    SELECT modalidade.id_evento_percurso,
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
           percurso.descricao,
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
    FROM tb_evento_percursos_gpx vinculo
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
    WHERE vinculo.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
      AND vinculo.id_evento_percurso IS NOT NULL
    ORDER BY modalidade.percurso_evento, modalidade.id_evento_percurso
</cfquery>

<cfscript>
VARIABLES.percursoApiRoutes = [];

for (VARIABLES.percursoApiRow = 1; VARIABLES.percursoApiRow <= qPercursoApiEventRoutes.recordcount; VARIABLES.percursoApiRow++) {
    arrayAppend(VARIABLES.percursoApiRoutes, {
        idEventoPercurso = val(qPercursoApiEventRoutes.id_evento_percurso[VARIABLES.percursoApiRow]),
        distancia = percursoApiNumber(qPercursoApiEventRoutes.percurso_evento[VARIABLES.percursoApiRow]),
        unidade = qPercursoApiEventRoutes.unidade_de_medida[VARIABLES.percursoApiRow] & "",
        modalidade = percursoApiNullableString(qPercursoApiEventRoutes.modalidade_tipo[VARIABLES.percursoApiRow]),
        data = percursoApiDate(qPercursoApiEventRoutes.data_percurso[VARIABLES.percursoApiRow]),
        horaLargada = percursoApiNullableString(qPercursoApiEventRoutes.hora_largada[VARIABLES.percursoApiRow]),
        idPercurso = val(qPercursoApiEventRoutes.id_percurso[VARIABLES.percursoApiRow]),
        codigoPublico = qPercursoApiEventRoutes.codigo_publico[VARIABLES.percursoApiRow] & "",
        nome = qPercursoApiEventRoutes.percurso_nome[VARIABLES.percursoApiRow] & "",
        tipo = qPercursoApiEventRoutes.tipo_percurso[VARIABLES.percursoApiRow] & "",
        descricao = percursoApiNullableString(qPercursoApiEventRoutes.descricao[VARIABLES.percursoApiRow]),
        distanciaNominalM = percursoApiNumber(qPercursoApiEventRoutes.distancia_nominal_m[VARIABLES.percursoApiRow]),
        arquivo = {
            id = val(qPercursoApiEventRoutes.id_percurso_arquivo[VARIABLES.percursoApiRow]),
            versao = val(qPercursoApiEventRoutes.versao[VARIABLES.percursoApiRow]),
            pontos = val(qPercursoApiEventRoutes.quantidade_pontos[VARIABLES.percursoApiRow]),
            distanciaM = percursoApiNumber(qPercursoApiEventRoutes.distancia_gpx_m[VARIABLES.percursoApiRow]),
            elevacaoMinM = percursoApiNumber(qPercursoApiEventRoutes.elevacao_min_m[VARIABLES.percursoApiRow]),
            elevacaoMaxM = percursoApiNumber(qPercursoApiEventRoutes.elevacao_max_m[VARIABLES.percursoApiRow]),
            ganhoElevacaoM = percursoApiNumber(qPercursoApiEventRoutes.ganho_elevacao_m[VARIABLES.percursoApiRow]),
            bbox = [
                percursoApiNumber(qPercursoApiEventRoutes.bbox_min_lng[VARIABLES.percursoApiRow]),
                percursoApiNumber(qPercursoApiEventRoutes.bbox_min_lat[VARIABLES.percursoApiRow]),
                percursoApiNumber(qPercursoApiEventRoutes.bbox_max_lng[VARIABLES.percursoApiRow]),
                percursoApiNumber(qPercursoApiEventRoutes.bbox_max_lat[VARIABLES.percursoApiRow])
            ],
            geometriaUrl = percursoApiGeometryUrl(
                qPercursoApiEventRoutes.id_evento_percurso[VARIABLES.percursoApiRow],
                qPercursoApiEventRoutes.id_percurso_arquivo[VARIABLES.percursoApiRow],
                qPercursoApiEventRoutes.sha256[VARIABLES.percursoApiRow] & ""
            )
        }
    });
}

if (!arrayLen(VARIABLES.percursoApiRoutes)) {
    percursoApiWrite({
        success = false,
        error = "routes_not_found",
        message = "O evento nao possui percursos publicados com arquivo ativo."
    }, 404, "Not Found");
}

percursoApiWrite({
    success = true,
    evento = {
        idEvento = val(qPercursoApiEvent.id_evento),
        nome = qPercursoApiEvent.nome_evento & "",
        tag = percursoApiNullableString(qPercursoApiEvent.tag),
        cidade = percursoApiNullableString(qPercursoApiEvent.cidade),
        estado = percursoApiNullableString(qPercursoApiEvent.estado),
        pais = qPercursoApiEvent.pais & "",
        dataInicial = percursoApiDate(qPercursoApiEvent.data_inicial),
        dataFinal = percursoApiDate(qPercursoApiEvent.data_final),
        percursos = VARIABLES.percursoApiRoutes
    }
});
</cfscript>
