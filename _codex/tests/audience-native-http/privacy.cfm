<cfsetting showdebugoutput="false" requesttimeout="10"/>
<cfscript>
if (!structKeyExists(REQUEST,"audienceNativeHttpFixtureAuthorized") || !REQUEST.audienceNativeHttpFixtureAuthorized) {
    cfheader(statuscode=403); abort;
}
privacyLanguage=structKeyExists(URL,"lang") && isSimpleValue(URL.lang) ? URL.lang : "pt-BR";
if (!listFind("pt-BR,en,es",privacyLanguage)) {cfheader(statuscode=400);abort;}
</cfscript>
<cfinclude template="i18n/#privacyLanguage#.cfm"/>
<cfscript>
REQUEST.t=function(required string key) {
    var item=VARIABLES.localesCatalog;
    for(var segment in listToArray(arguments.key,".")) item=item[segment];
    return item;
};
REQUEST.i18nBuildPath=function(required string route) {return "/privacidade/";};
</cfscript>
<!doctype html><html lang="<cfoutput>#encodeForHTMLAttribute(privacyLanguage)#</cfoutput>"><head><meta charset="utf-8"/><title>Isolated privacy controls</title></head><body>
<cfinclude template="includes/analytics/privacy_controls.cfm"/>
</body></html>
