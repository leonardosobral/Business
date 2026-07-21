<cfsetting showdebugoutput="false"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfparam name="URL.id" default=""/>
<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT isNumeric(URL.id)><cfheader statuscode="403" statustext="Forbidden"/><cfoutput>Acesso negado.</cfoutput><cfabort></cfif>
<cfquery name="qDownload">
  SELECT a.storage_key,a.nome_original
  FROM tb_percurso_arquivos a
  INNER JOIN tb_percursos p ON p.id_percurso=a.id_percurso
  WHERE a.id_percurso_arquivo=<cfqueryparam cfsqltype="cf_sql_bigint" value="#URL.id#"/>
    AND p.id_usuario_criador=<cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
</cfquery>
<cfif NOT qDownload.recordcount><cfheader statuscode="404" statustext="Not Found"/><cfoutput>Arquivo não encontrado.</cfoutput><cfabort></cfif>
<cfset VARIABLES.downloadRoot=""/>
<cftry><cfset VARIABLES.downloadRoot=trim(createObject("java","java.lang.System").getenv("BUSINESS_PERCURSOS_STORAGE_PATH") & "")/><cfcatch type="any"></cfcatch></cftry>
<cfif NOT len(VARIABLES.downloadRoot)>
  <cfset VARIABLES.downloadLocalConfigPath=expandPath("/config/percursos.local.cfm")/>
  <cfif fileExists(VARIABLES.downloadLocalConfigPath)><cfinclude template="../config/percursos.local.cfm"/><cfif isDefined("percursoLocalConfig") AND isStruct(percursoLocalConfig) AND structKeyExists(percursoLocalConfig,"storagePath")><cfset VARIABLES.downloadRoot=trim(percursoLocalConfig.storagePath & "")/></cfif></cfif>
</cfif>
<cfif NOT len(VARIABLES.downloadRoot)><cfset VARIABLES.downloadRoot=getTempDirectory() & "business-percursos-storage"/></cfif>
<cfset VARIABLES.downloadPath=VARIABLES.downloadRoot & "/" & qDownload.storage_key/>
<cfif NOT fileExists(VARIABLES.downloadPath)><cfheader statuscode="404" statustext="Not Found"/><cfoutput>Arquivo não encontrado no storage.</cfoutput><cfabort></cfif>
<cfset VARIABLES.downloadName=reReplace(qDownload.nome_original,"[^A-Za-z0-9._-]","_","all")/>
<cfif NOT len(VARIABLES.downloadName)><cfset VARIABLES.downloadName="percurso.gpx"/></cfif>
<cfheader name="Content-Disposition" value="attachment; filename=#VARIABLES.downloadName#"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfcontent type="application/gpx+xml" file="#VARIABLES.downloadPath#" reset="true"/>
