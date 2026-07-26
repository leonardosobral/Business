<cfsetting showdebugoutput="false" requesttimeout="60"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfparam name="URL.id" default=""/>
<cfparam name="URL.formato" default="original"/>
<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT isNumeric(URL.id)><cfheader statuscode="403" statustext="Forbidden"/><cfoutput>Acesso negado.</cfoutput><cfabort></cfif>
<cfset VARIABLES.downloadCanViewAll = listFindNoCase("1,true,t,yes,sim,on", trim(qPerfil.is_admin & ""))
  OR listFindNoCase("1,true,t,yes,sim,on", trim(qPerfil.is_dev & ""))/>
<cfset VARIABLES.downloadAccountIds=isDefined("VARIABLES.businessEffectiveAccountIds") ? VARIABLES.businessEffectiveAccountIds : "0"/>
<cfset VARIABLES.downloadEventLinksReady=false/>
<cftry>
  <cfquery name="qDownloadEventLinksReady">SELECT to_regclass('public.tb_evento_percursos_gpx') IS NOT NULL AS ready</cfquery>
  <cfset VARIABLES.downloadEventLinksReady=listFindNoCase("1,true,t,yes,sim,on", trim(qDownloadEventLinksReady.ready & "")) GT 0/>
  <cfcatch type="any"><cfset VARIABLES.downloadEventLinksReady=false/></cfcatch>
</cftry>
<cfquery name="qDownload">
  SELECT a.storage_key,a.geojson_storage_key,a.nome_original,a.mime_type,p.nome AS percurso_nome
  FROM tb_percurso_arquivos a
  INNER JOIN tb_percursos p ON p.id_percurso=a.id_percurso
  WHERE a.id_percurso_arquivo=<cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.id#"/>
  <cfif NOT VARIABLES.downloadCanViewAll>
    AND (
      (p.id_conta_responsavel IS NULL
       AND p.id_usuario_criador = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>)
      OR p.id_conta_responsavel IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.downloadAccountIds#" list="true"/>)
      <cfif VARIABLES.downloadEventLinksReady>
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
            AND conta_evento.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.downloadAccountIds#" list="true"/>)
        )
      </cfif>
    )
  </cfif>
</cfquery>
<cfif NOT qDownload.recordcount><cfheader statuscode="404" statustext="Not Found"/><cfoutput>Arquivo não encontrado.</cfoutput><cfabort></cfif>
<cfset VARIABLES.downloadRoot=""/>
<cftry><cfset VARIABLES.downloadRoot=trim(createObject("java","java.lang.System").getenv("BUSINESS_PERCURSOS_STORAGE_PATH") & "")/><cfcatch type="any"></cfcatch></cftry>
<cfif NOT len(VARIABLES.downloadRoot)>
  <cfset VARIABLES.downloadLocalConfigPath=expandPath("/config/percursos.local.cfm")/>
  <cfif fileExists(VARIABLES.downloadLocalConfigPath)><cfinclude template="../config/percursos.local.cfm"/><cfif isDefined("percursoLocalConfig") AND isStruct(percursoLocalConfig) AND structKeyExists(percursoLocalConfig,"storagePath")><cfset VARIABLES.downloadRoot=trim(percursoLocalConfig.storagePath & "")/></cfif></cfif>
</cfif>
<cfif NOT len(VARIABLES.downloadRoot)><cfset VARIABLES.downloadRoot=getTempDirectory() & "business-percursos-storage"/></cfif>
<cfset VARIABLES.downloadOptimizedGpx = compareNoCase(trim(URL.formato), "gpx") EQ 0/>
<cfif VARIABLES.downloadOptimizedGpx>
  <cfset VARIABLES.downloadOptimizedKey = reReplace(qDownload.geojson_storage_key, "[^/]+$", "optimized.gpx")/>
  <cfset VARIABLES.downloadPath = VARIABLES.downloadRoot & "/" & VARIABLES.downloadOptimizedKey/>
  <cfif NOT fileExists(VARIABLES.downloadPath)>
    <cfset VARIABLES.downloadGeoJsonPath = VARIABLES.downloadRoot & "/" & qDownload.geojson_storage_key/>
    <cfif NOT fileExists(VARIABLES.downloadGeoJsonPath)><cfheader statuscode="404" statustext="Not Found"/><cfoutput>Geometria normalizada não encontrada no storage.</cfoutput><cfabort></cfif>
    <cflock name="business-percurso-optimized-gpx-#URL.id#" type="exclusive" timeout="60">
      <cfif NOT fileExists(VARIABLES.downloadPath)>
        <cftry>
          <cfset VARIABLES.downloadGpxService=createObject("component","percursos.includes.PercursoGpxService")/>
          <cfset VARIABLES.downloadGpxService.writeGpxFromGeoJson(VARIABLES.downloadGeoJsonPath,VARIABLES.downloadPath,qDownload.percurso_nome)/>
          <cfcatch type="any">
            <cflog file="business-percursos" type="error" text="Falha ao gerar GPX otimizado do arquivo #URL.id#: #cfcatch.message# #cfcatch.detail#"/>
            <cfheader statuscode="422" statustext="Unprocessable Entity"/><cfoutput>Não foi possível gerar o GPX otimizado.</cfoutput><cfabort>
          </cfcatch>
        </cftry>
      </cfif>
    </cflock>
  </cfif>
  <cfset VARIABLES.downloadBaseName=reReplace(qDownload.nome_original,"\.[^.]+$","","one")/>
  <cfset VARIABLES.downloadName=reReplace(VARIABLES.downloadBaseName & "-otimizado.gpx","[^A-Za-z0-9._-]","_","all")/>
  <cfset VARIABLES.downloadMime="application/gpx+xml"/>
<cfelse>
  <cfset VARIABLES.downloadPath=VARIABLES.downloadRoot & "/" & qDownload.storage_key/>
  <cfset VARIABLES.downloadName=reReplace(qDownload.nome_original,"[^A-Za-z0-9._-]","_","all")/>
  <cfif NOT len(VARIABLES.downloadName)><cfset VARIABLES.downloadName="percurso.arquivo"/></cfif>
  <cfset VARIABLES.downloadMime = len(trim(qDownload.mime_type & "")) ? trim(qDownload.mime_type & "") : "application/octet-stream"/>
</cfif>
<cfif NOT fileExists(VARIABLES.downloadPath)><cfheader statuscode="404" statustext="Not Found"/><cfoutput>Arquivo não encontrado no storage.</cfoutput><cfabort></cfif>
<cfheader name="Content-Disposition" value="attachment; filename=#VARIABLES.downloadName#"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfcontent type="#VARIABLES.downloadMime#" file="#VARIABLES.downloadPath#" reset="true"/>
