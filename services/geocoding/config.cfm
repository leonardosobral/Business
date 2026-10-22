<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
VARIABLES.geoConfig={apiKey="",secret=""};VARIABLES.geoLocalConfig={};
VARIABLES.geoConfig.aiKey=structKeyExists(APPLICATION,"vickyKnowledge") AND structKeyExists(APPLICATION.vickyKnowledge,"apiKey") ? APPLICATION.vickyKnowledge.apiKey : "";
VARIABLES.geoConfig.aiModel="gpt-6-astra";VARIABLES.geoConfig.aiDailyLimit=1000;
if(fileExists(expandPath("/config/business.local.cfm"))) {
    include "/config/business.local.cfm";
    if(isDefined("businessLocalConfig") AND isStruct(businessLocalConfig)) VARIABLES.geoLocalConfig=businessLocalConfig;
}
try {VARIABLES.geoConfig.apiKey=trim(createObject("java","java.lang.System").getenv("RR_GEOAPIFY_API_KEY") & "");}catch(any noEnvironment){}
if(!len(VARIABLES.geoConfig.apiKey) AND structKeyExists(VARIABLES.geoLocalConfig,"geoapifyApiKey")) VARIABLES.geoConfig.apiKey=trim(VARIABLES.geoLocalConfig.geoapifyApiKey & "");
if(structKeyExists(VARIABLES.geoLocalConfig,"cronSecrets") AND isStruct(VARIABLES.geoLocalConfig.cronSecrets) AND structKeyExists(VARIABLES.geoLocalConfig.cronSecrets,"business_internal")) VARIABLES.geoConfig.secret=VARIABLES.geoLocalConfig.cronSecrets.business_internal & "";
</cfscript>
