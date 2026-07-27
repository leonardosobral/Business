<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="includes/common.cfm"/>

<cfparam name="URL.id_evento_percurso" default=""/>
<cfparam name="URL.arquivo" default=""/>
<cfparam name="URL.rev" default=""/>

<cfif NOT isNumeric(URL.id_evento_percurso)
    OR val(URL.id_evento_percurso) LTE 0
    OR val(URL.id_evento_percurso) NEQ int(val(URL.id_evento_percurso))
    OR NOT isNumeric(URL.arquivo)
    OR val(URL.arquivo) LTE 0
    OR val(URL.arquivo) NEQ int(val(URL.arquivo))
    OR NOT reFindNoCase("^[0-9a-f]{8,64}$", trim(URL.rev & ""))>
    <cfset percursoApiWrite({
        success=false,
        error="invalid_geometry_reference",
        message="Informe id_evento_percurso, arquivo e rev validos."
    }, 400, "Bad Request")/>
</cfif>

<cfquery name="qPercursoApiGeometry">
    SELECT vinculo.id_evento,
           vinculo.id_evento_percurso,
           percurso.id_percurso,
           arquivo.id_percurso_arquivo,
           arquivo.versao,
           arquivo.sha256,
           arquivo.geojson_storage_key
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
    WHERE vinculo.id_evento_percurso = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento_percurso#"/>
      AND arquivo.id_percurso_arquivo = <cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.arquivo#"/>
</cfquery>

<cfif NOT qPercursoApiGeometry.recordcount
    OR left(lCase(trim(qPercursoApiGeometry.sha256 & "")), len(trim(URL.rev & ""))) NEQ lCase(trim(URL.rev & ""))>
    <cfset percursoApiWrite({
        success=false,
        error="geometry_not_found",
        message="A geometria solicitada nao existe ou nao e mais a versao publicada."
    }, 404, "Not Found")/>
</cfif>

<cfset VARIABLES.percursoApiStorageRoot = structKeyExists(VARIABLES.percursoApiEnvironment, "BUSINESS_PERCURSOS_STORAGE_PATH")
    ? trim(VARIABLES.percursoApiEnvironment["BUSINESS_PERCURSOS_STORAGE_PATH"] & "")
    : (structKeyExists(VARIABLES.percursoApiConfig, "storagePath") ? trim(VARIABLES.percursoApiConfig.storagePath & "") : "")/>

<cfif NOT len(VARIABLES.percursoApiStorageRoot)>
    <cfset percursoApiWrite({
        success=false,
        error="storage_not_configured",
        message="O storage de percursos nao esta configurado."
    }, 503, "Service Unavailable")/>
</cfif>

<cftry>
    <cfset VARIABLES.percursoApiRootFile = createObject("java", "java.io.File").init(VARIABLES.percursoApiStorageRoot)/>
    <cfset VARIABLES.percursoApiGeometryFile = createObject("java", "java.io.File").init(
        VARIABLES.percursoApiRootFile,
        qPercursoApiGeometry.geojson_storage_key & ""
    )/>
    <cfset VARIABLES.percursoApiCanonicalRoot = VARIABLES.percursoApiRootFile.getCanonicalPath() & createObject("java", "java.io.File").separator/>
    <cfset VARIABLES.percursoApiCanonicalGeometry = VARIABLES.percursoApiGeometryFile.getCanonicalPath()/>

    <cfif left(VARIABLES.percursoApiCanonicalGeometry, len(VARIABLES.percursoApiCanonicalRoot))
        NEQ VARIABLES.percursoApiCanonicalRoot
        OR NOT fileExists(VARIABLES.percursoApiCanonicalGeometry)>
        <cfset percursoApiWrite({
            success=false,
            error="geometry_file_not_found",
            message="O arquivo da geometria nao esta disponivel."
        }, 404, "Not Found")/>
    </cfif>

    <cffile action="read" file="#VARIABLES.percursoApiCanonicalGeometry#" variable="VARIABLES.percursoApiGeometryJson" charset="utf-8"/>
    <cfset VARIABLES.percursoApiGeometryData = deserializeJSON(VARIABLES.percursoApiGeometryJson)/>

    <cfif NOT isStruct(VARIABLES.percursoApiGeometryData)
        OR NOT structKeyExists(VARIABLES.percursoApiGeometryData, "geometry")
        OR NOT isStruct(VARIABLES.percursoApiGeometryData.geometry)
        OR NOT structKeyExists(VARIABLES.percursoApiGeometryData.geometry, "type")
        OR NOT listFindNoCase("LineString,MultiLineString", VARIABLES.percursoApiGeometryData.geometry.type & "")
        OR NOT structKeyExists(VARIABLES.percursoApiGeometryData.geometry, "coordinates")
        OR NOT isArray(VARIABLES.percursoApiGeometryData.geometry.coordinates)>
        <cfthrow type="PercursoApi.InvalidGeoJson" message="GeoJSON invalido."/>
    </cfif>

    <cfheader name="ETag" value='"#lCase(trim(qPercursoApiGeometry.sha256 & ""))#"'/>
    <cfheader name="Cache-Control" value="private, max-age=300"/>
    <cfset percursoApiWrite({
        type = "Feature",
        properties = {
            idEvento = val(qPercursoApiGeometry.id_evento),
            idEventoPercurso = val(qPercursoApiGeometry.id_evento_percurso),
            idPercurso = val(qPercursoApiGeometry.id_percurso),
            idArquivo = val(qPercursoApiGeometry.id_percurso_arquivo),
            versao = val(qPercursoApiGeometry.versao)
        },
        geometry = {
            type = VARIABLES.percursoApiGeometryData.geometry.type & "",
            coordinates = VARIABLES.percursoApiGeometryData.geometry.coordinates
        }
    })/>
    <cfcatch type="PercursoApi.InvalidGeoJson">
        <cfset percursoApiWrite({
            success=false,
            error="invalid_geojson",
            message="A geometria armazenada e invalida."
        }, 422, "Unprocessable Entity")/>
    </cfcatch>
    <cfcatch type="any">
        <cfset percursoApiWrite({
            success=false,
            error="geometry_read_error",
            message="Nao foi possivel ler a geometria."
        }, 500, "Internal Server Error")/>
    </cfcatch>
</cftry>
