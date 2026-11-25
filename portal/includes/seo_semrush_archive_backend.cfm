<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfif structKeyExists(CGI,"request_method") AND compareNoCase(CGI.request_method,"GET") NEQ 0><cfheader statuscode="405"/><cfheader name="Allow" value="GET"/><cfabort/></cfif>
<cfscript>
// Immutable, private export. Request parameters never select filesystem paths.
VARIABLES.smaRoot="/var/lib/runnerhub/seo/semrush/20261104";
VARIABLES.smaAvailable=false;
VARIABLES.smaManifest={};
try {
  VARIABLES.smaManifest=deserializeJSON(fileRead(VARIABLES.smaRoot & "/manifest.json","utf-8"));
  VARIABLES.smaAvailable=isStruct(VARIABLES.smaManifest) AND VARIABLES.smaManifest.schemaVersion EQ 1
    AND structKeyExists(VARIABLES.smaManifest,"sites") AND structKeyExists(VARIABLES.smaManifest,"files");
} catch(any smaReadError) { VARIABLES.smaAvailable=false; }
</cfscript>
