<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/seo_semrush_archive_backend.cfm"/>
<cfscript>
VARIABLES.smaFileId="";
if(structKeyExists(URL,"arquivo") AND isSimpleValue(URL.arquivo)) VARIABLES.smaFileId=left(URL.arquivo,160);
VARIABLES.smaDownloadAllowed=VARIABLES.smaAvailable AND reFind("^[a-z0-9_.-]+$",VARIABLES.smaFileId)
  AND structKeyExists(VARIABLES.smaManifest.files,VARIABLES.smaFileId);
if(VARIABLES.smaDownloadAllowed){
  VARIABLES.smaDownload=VARIABLES.smaManifest.files[VARIABLES.smaFileId];
  VARIABLES.smaDownloadAllowed=reFind("^[A-Za-z0-9._`-]+[.]csv$",VARIABLES.smaDownload.name) EQ 1;
  VARIABLES.smaDownloadPath=VARIABLES.smaRoot & "/raw/" & VARIABLES.smaDownload.name;
  if(VARIABLES.smaDownloadAllowed) VARIABLES.smaDownloadAllowed=fileExists(VARIABLES.smaDownloadPath)
    AND getFileInfo(VARIABLES.smaDownloadPath).size EQ VARIABLES.smaDownload.bytes;
}
</cfscript>
<cfif NOT VARIABLES.smaDownloadAllowed><cfcontent reset="true"/><cfheader statuscode="404"/><cfabort/></cfif>
<cfheader name="Content-Disposition" value='attachment; filename="#VARIABLES.smaDownload.name#"'/>
<cfcontent type="text/csv; charset=utf-8" file="#VARIABLES.smaDownloadPath#" deletefile="false" reset="true"/><cfabort/>
