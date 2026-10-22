<cfscript>
try {cfexecute(name="/usr/bin/python3",arguments=["-I","-c","print('GEO_EXECUTE_AVAILABLE')"],variable="output",errorVariable="err",timeout=3);writeOutput(output);}catch(any e){writeOutput("EXECUTE_UNAVAILABLE " & encodeForHTML(e.type & ": " & left(e.message,400)));}
q=queryExecute("SELECT lower(substring(COALESCE(NULLIF(url_hotsite,''),url_inscricao) from '^https?://([^/:]+)')) AS host,count(*) AS total FROM public.tb_evento_corridas WHERE btrim(COALESCE(coordenadas,''))='' AND ativo=true GROUP BY 1 ORDER BY total DESC LIMIT 18",[],{datasource="runner_dba"});
for(r in q)writeOutput(serializeJSON(r) & chr(10));
writeOutput("GEO_SOURCE_CAPABILITY_PASSED");
</cfscript>
