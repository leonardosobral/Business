<cfsetting showdebugoutput="false"/>
<cfcontent type="application/json; charset=utf-8"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfparam name="URL.id" default=""/>
<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT isNumeric(URL.id)><cfheader statuscode="403" statustext="Forbidden"/><cfoutput>{"error":"forbidden"}</cfoutput><cfabort></cfif>
<cfset VARIABLES.geometryCanViewAll = listFindNoCase("1,true,t,yes,sim,on", trim(qPerfil.is_admin & ""))
  OR listFindNoCase("1,true,t,yes,sim,on", trim(qPerfil.is_dev & ""))/>
<cfset VARIABLES.geometryAccountIds=isDefined("VARIABLES.businessEffectiveAccountIds") ? VARIABLES.businessEffectiveAccountIds : "0"/>
<cfset VARIABLES.geometryEventLinksReady=false/>
<cftry>
  <cfquery name="qGeometryEventLinksReady">SELECT to_regclass('public.tb_evento_percursos_gpx') IS NOT NULL AS ready</cfquery>
  <cfset VARIABLES.geometryEventLinksReady=listFindNoCase("1,true,t,yes,sim,on", trim(qGeometryEventLinksReady.ready & "")) GT 0/>
  <cfcatch type="any"><cfset VARIABLES.geometryEventLinksReady=false/></cfcatch>
</cftry>
<cfquery name="qGeometry">
  SELECT a.geojson_storage_key FROM tb_percurso_arquivos a INNER JOIN tb_percursos p ON p.id_percurso=a.id_percurso WHERE a.id_percurso_arquivo=<cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.id#"/>
  <cfif NOT VARIABLES.geometryCanViewAll>
    AND (
      p.id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
      OR p.id_conta_responsavel IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.geometryAccountIds#" list="true"/>)
      <cfif VARIABLES.geometryEventLinksReady>
        OR EXISTS (
          SELECT 1
          FROM tb_evento_percursos_gpx evento_percurso
          INNER JOIN tb_conta_eventos conta_evento
            ON conta_evento.id_evento = evento_percurso.id_evento
           AND conta_evento.status = 'ATIVO'::status_conta_evento
          INNER JOIN tb_contas conta
            ON conta.id_conta = conta_evento.id_conta
           AND conta.status = 'ATIVA'::status_conta
          WHERE evento_percurso.id_percurso = p.id_percurso
            AND conta_evento.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.geometryAccountIds#" list="true"/>)
        )
      </cfif>
    )
  </cfif>
</cfquery>
<cfif NOT qGeometry.recordcount><cfheader statuscode="404" statustext="Not Found"/><cfoutput>{"error":"not_found","message":"A versao do percurso nao foi encontrada ou nao esta disponivel para esta conta."}</cfoutput><cfabort></cfif>
<cfset VARIABLES.geometryRoot=""/>
<cftry><cfset VARIABLES.geometryRoot=trim(createObject("java","java.lang.System").getenv("BUSINESS_PERCURSOS_STORAGE_PATH") & "")/><cfcatch type="any"></cfcatch></cftry>
<cfif NOT len(VARIABLES.geometryRoot)>
  <cfset VARIABLES.geometryLocalConfigPath=expandPath("/config/percursos.local.cfm")/>
  <cfif fileExists(VARIABLES.geometryLocalConfigPath)>
    <cfinclude template="../config/percursos.local.cfm"/>
    <cfif isDefined("percursoLocalConfig") AND isStruct(percursoLocalConfig) AND structKeyExists(percursoLocalConfig,"storagePath")><cfset VARIABLES.geometryRoot=trim(percursoLocalConfig.storagePath & "")/></cfif>
  </cfif>
</cfif>
<cfif NOT len(VARIABLES.geometryRoot)><cfset VARIABLES.geometryRoot=getTempDirectory() & "business-percursos-storage"/></cfif>
<cfset VARIABLES.geometryPath=VARIABLES.geometryRoot & "/" & qGeometry.geojson_storage_key/>
<cfif NOT fileExists(VARIABLES.geometryPath)><cfheader statuscode="404" statustext="Not Found"/><cfoutput>#serializeJSON({error="file_not_found",message="O GeoJSON nao existe no storage configurado. Configure um storage gravavel e envie uma nova versao do GPX."})#</cfoutput><cfabort></cfif>
<cfheader name="Cache-Control" value="private, no-store"/>
<cffile action="read" file="#VARIABLES.geometryPath#" variable="geometryJson" charset="utf-8"/>
<cftry>
  <cfset VARIABLES.geometryData=deserializeJSON(geometryJson)/>
  <cfif NOT isStruct(VARIABLES.geometryData) OR NOT structKeyExists(VARIABLES.geometryData,"geometry") OR NOT isStruct(VARIABLES.geometryData.geometry) OR NOT structKeyExists(VARIABLES.geometryData.geometry,"coordinates") OR NOT isArray(VARIABLES.geometryData.geometry.coordinates)>
    <cfthrow message="Estrutura GeoJSON invalida."/>
  </cfif>
  <cfset VARIABLES.geometryProperties=structKeyExists(VARIABLES.geometryData,"properties") AND isStruct(VARIABLES.geometryData.properties) ? VARIABLES.geometryData.properties : {}/>
  <cfset VARIABLES.normalizedGeometryJson='{"type":"Feature","properties":' & serializeJSON(VARIABLES.geometryProperties) & ',"geometry":{"type":"LineString","coordinates":' & serializeJSON(VARIABLES.geometryData.geometry.coordinates) & '}}'/>
  <cfoutput>#VARIABLES.normalizedGeometryJson#</cfoutput>
  <cfcatch type="any"><cfheader statuscode="422" statustext="Unprocessable Entity"/><cfoutput>#serializeJSON({error="invalid_geojson",message="O arquivo GeoJSON armazenado e invalido. Envie uma nova versao do GPX."})#</cfoutput></cfcatch>
</cftry>
