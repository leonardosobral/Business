<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
line=lCase(trim(URL.linha ?: ''));
if ((len(line) && line NEQ 'principal') || structKeyExists(URL,'incluir_ocultos')) {
    cfheader(statuscode=400);
    writeOutput(serializeJSON({'success'=false,'status'='invalid_parameter','message'='Use apenas linha=principal; itens ocultos nao sao publicos.'}));
    abort;
}
try {
    payload=createObject('component','runnerAppsCatalog.Catalog').init().read(line);
    cfheader(name='Cache-Control',value='public, max-age=60, s-maxage=300, stale-if-error=86400');
    cfheader(name='Pragma',value='');
    writeOutput(serializeJSON(payload));
} catch (any catalogError) {
    cfheader(statuscode=503);
    cfheader(name='Retry-After',value='60');
    writeOutput(serializeJSON({'success'=false,'status'='unavailable','message'='Catalogo temporariamente indisponivel.'}));
}
</cfscript>
