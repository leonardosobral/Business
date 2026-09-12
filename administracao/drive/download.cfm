<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="120"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../agenda/includes/service.cfm"/>
<cfinclude template="includes/service.cfm"/>
<cfscript>
try {
    if (CGI.request_method!="GET" || !structKeyExists(url,"id") || !isSimpleValue(url.id)) driveFail("Arquivo inválido.");
    if (!driveReady()) driveFail("Aplique o schema de Documentos.");
    lock name="RunnerHubBusiness.GoogleDrive" type="exclusive" timeout="110" { download=driveDownload(url.id & ""); }
    fileName=reReplace(download.item.name & "","[^[:alnum:] ._()-]","_","all");
    if (!len(trim(fileName))) fileName="arquivo";
    mime=structKeyExists(download.item,"mimeType") && len(download.item.mimeType) ? download.item.mimeType : "application/octet-stream";
    if (!reFindNoCase("^[a-z0-9.+-]+/[a-z0-9.+-]+$",mime)) mime="application/octet-stream";
    cfheader(name="Cache-Control",value="private, no-store");
    cfheader(name="X-Content-Type-Options",value="nosniff");
    cfheader(name="Content-Disposition",value='attachment; filename="' & replace(fileName,chr(34),"","all") & '"');
    cfcontent(type=mime,variable=download.content,reset=true);
} catch(any error) {
    cfheader(statuscode=400);
    cfcontent(type="text/plain; charset=utf-8",reset=true);
    writeOutput(error.type=="Drive.Validation" || error.type=="Agenda.Validation" ? error.message : "Não foi possível baixar o arquivo.");
}
</cfscript>
