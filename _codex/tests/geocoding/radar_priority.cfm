<cfscript>
function check(required boolean condition,required string label){if(!condition)throw(type="Test.Failed",message=label);writeOutput("PASS " & label & chr(10));}
source=fileRead(getDirectoryFromPath(getBaseTemplatePath()) & "services/geocoding/LocationStore.cfc");
start=findNoCase("public array function selectEvents",source);finish=findNoCase("public struct function claim",source,start);
check(start GT 0 AND finish GT start,"Queue selection method is present in the staged production source");
method=mid(source,start,finish-start);
near=findNoCase("CURRENT_DATE+interval '30 days'",method);
midRange=findNoCase("CURRENT_DATE+interval '90 days'",method);
later=findNoCase("e.data_inicial>CURRENT_DATE+interval '90 days'",method);
inProgress=findNoCase("e.data_inicial<CURRENT_DATE AND e.data_final>=CURRENT_DATE",method);
remaining=findNoCase("WHEN e.ativo IS TRUE THEN 4",method);
check(near GT 0 AND midRange GT near AND later GT midRange,"Future queue distinguishes 30-day, 90-day and later horizons");
check(inProgress GT later AND remaining GT inProgress,"In-progress events precede remaining active work");
check(findNoCase("btrim(COALESCE(e.coordenadas,''))=''",method) GT 0,"Future priority explicitly favors a missing event location");
check(findNoCase("max(1,min(5,int(limit)))",method) GT 0,"Queue keeps the five-event cap");
check(findNoCase("e.id_evento DESC LIMIT :limit",method) GT 0,"Queue ordering remains deterministic");
writeOutput("GEO_RADAR_PRIORITY_PASSED");
</cfscript>
