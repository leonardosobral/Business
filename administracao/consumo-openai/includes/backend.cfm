<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"><cfabort></cfif>
<cfscript>
cfheader(name="Cache-Control",value="private, no-store");cfheader(name="X-Robots-Tag",value="noindex, nofollow");
usageDelegated=structKeyExists(REQUEST,"businessAccessContext") AND REQUEST.businessAccessContext.accessMode EQ "DELEGATED";
usageAdmin=isDefined("qPerfil") AND qPerfil.recordCount ? qPerfil.is_admin : false;
usageEffective=isDefined("VARIABLES.businessEffectiveIsAdmin") ? VARIABLES.businessEffectiveIsAdmin : usageAdmin;
if(!new services.openaiUsage.Access().allowed(usageAdmin,usageEffective,usageDelegated)){cfheader(statuscode=403);writeOutput("Acesso restrito a administradores globais.");abort;}
if(CGI.request_method NEQ "GET"){cfheader(statuscode=405);cfheader(name="Allow",value="GET");abort;}
param name="URL.aba" default="overview";
if(!isSimpleValue(URL.aba) OR !listFind("overview,history,coverage",URL.aba)){cfheader(statuscode=400);writeOutput("Aba inválida.");abort;}
usageTab=URL.aba;usageStore=new services.openaiUsage.Store();usageCatalog=new services.openaiUsage.Catalog().modules();
try{
    usageInput={};for(usageKey in ["period","module","model","status","start","end"])if(structKeyExists(URL,usageKey))usageInput[usageKey]=URL[usageKey];
    if(structKeyExists(URL,"pagina"))usageInput.page=URL.pagina;
    usageFilters=usageStore.filters(usageInput);
}catch(OpenAIUsage.Filter invalid){cfheader(statuscode=400);writeOutput(encodeForHTML(invalid.message));abort;}
usageData=usageStore.report(usageFilters);
function usageLink(required string tab,numeric page=1){
    var fields={aba=tab,pagina=page,period=usageFilters.period,module=usageFilters.module,model=usageFilters.model,status=usageFilters.status,start=usageFilters.start,end=usageFilters.end};var pairs=[];
    for(var key in fields)arrayAppend(pairs,encodeForURL(key) & "=" & encodeForURL(fields[key]));return "?" & arrayToList(pairs,"&");
}
function usageNumber(required numeric value){var formatter=createObject("java","java.text.NumberFormat").getNumberInstance(createObject("java","java.util.Locale").forLanguageTag("pt-BR"));formatter.setMaximumFractionDigits(0);return formatter.format(javacast("double",value)) & "";}
function usageMoney(required numeric value){var formatter=createObject("java","java.text.NumberFormat").getNumberInstance(createObject("java","java.util.Locale").forLanguageTag("pt-BR"));var digits=value GT 0 AND value LT 0.01 ? 6 : 2;formatter.setMinimumFractionDigits(digits);formatter.setMaximumFractionDigits(digits);return "US$ " & formatter.format(javacast("double",value));}
function usageTime(required numeric value){return createObject("java","java.time.Instant").ofEpochMilli(javacast("long",value)).atZone(createObject("java","java.time.ZoneId").of("America/Sao_Paulo")).format(createObject("java","java.time.format.DateTimeFormatter").ofPattern("dd/MM/yyyy HH:mm:ss")) & "";}
</cfscript>
