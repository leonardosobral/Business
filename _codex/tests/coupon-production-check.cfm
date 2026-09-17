<cfscript>
db={datasource='runner_dba'};
result={};
try {
  result.columns=queryExecute("SELECT table_name,column_name,data_type FROM information_schema.columns WHERE table_schema='public' AND table_name IN ('tb_cupom','tb_evento_corridas_cupom','tb_evento_circuitos_cupom','tb_paginas','tb_agrega_eventos') ORDER BY table_name,ordinal_position",{},db);
  result.view=queryExecute("SELECT pg_get_viewdef('public.vw_evento_corridas_cupom'::regclass,true) AS definition",{},db).definition[1];
  service=createObject('component','Candidate');
  access=service.scope(true);
  result.catalog=service.listing(access).total;
  result.events=service.events(access).recordcount;
  result.otherLinks=service.otherLinks(0,access).recordcount;
  result.ok=true;
} catch(any ex) {result={ok=false,type=ex.type,message=ex.message,detail=ex.detail};}
cfcontent(type='application/json',reset=true);
writeOutput(serializeJSON(result));
</cfscript>
