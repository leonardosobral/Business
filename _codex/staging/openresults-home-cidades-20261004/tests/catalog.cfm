<cfsetting showdebugoutput="false"/><cfscript>
VARIABLES.template="/"; VARIABLES.assertions=0;
function check(required boolean ok,required string message){if(!ok)throw(message=message);VARIABLES.assertions++;}
qEventosBase=queryNew("id_evento,cidade,tag_cidade,estado,pais,data_final", "integer,varchar,varchar,varchar,varchar,date");
function addEvent(required numeric id,required string name,required string slug,required string uf,required date date, string country="BR"){
 queryAddRow(qEventosBase,{id_evento=arguments.id,cidade=arguments.name,tag_cidade=arguments.slug,estado=arguments.uf,pais=arguments.country,data_final=arguments.date});
}
addEvent(1,"SÃO JOSÉ","sao-jose","SC",createDate(2026,10,4));
addEvent(2,"SÃO JOSÉ","sao-jose","SP",createDate(2026,10,3));
addEvent(3,"VILA ANTIGA","vila-antiga","MG",createDate(2023,1,1));
addEvent(4,"POPULAR","popular","BA",createDate(2026,5,1));
addEvent(5,"POPULAR","popular","BA",createDate(2026,6,1));
addEvent(6,"POPULAR","popular","BA",createDate(2026,7,1));
addEvent(7,"RECENTE","recente","BA",createDate(2026,9,5));
addEvent(8,"RECENTE","recente","BA",createDate(2026,9,4));
addEvent(9,"RECENTE","recente","BA",createDate(2025,10,4));
addEvent(10,"   ","---","BA",createDate(2026,10,1));
addEvent(11,"INVÁLIDA","invalida","XX",createDate(2026,10,1));
addEvent(12,"OUTRO PAÍS","outro-pais","BA",createDate(2026,10,1),"US");
addEvent(13,"INJETADA","../sp","BA",createDate(2026,10,1));
addEvent(14,"FUTURA","futura","BA",createDate(2026,10,5));
addEvent(15,"ANUAL","anual","BA",createDate(2025,10,5));
addEvent(16,"ANUAL","anual","BA",createDate(2025,10,4));
</cfscript>
<cfif fileExists(expandPath("candidate/includes/backend_home_cidades.cfm"))><cfinclude template="candidate/includes/backend_home_cidades.cfm"/></cfif>
<cfscript>
check(structKeyExists(REQUEST,"buildHomeCityCatalog"),"Home city catalog not implemented");
result=REQUEST.buildHomeCityCatalog(qEventosBase,createDate(2026,10,4));
check(arrayLen(result.cities)==7,"Eligible city/UF pairs include history and exclude malformed/outside-BR cities");
lookup={};for(row in result.cities)lookup[row.uf & ":" & row.slug]=row;
check(lookup["SC:sao-jose"].name=="São José","Display names use readable capitalization");
check(lookup["SC:sao-jose"].total==1 && lookup["SP:sao-jose"].total==1,"Homonyms remain separate by UF");
check(lookup["MG:vila-antiga"].total==1 && lookup["MG:vila-antiga"].recent==0 && lookup["MG:vila-antiga"].annual==0,"Old cities remain searchable");
check(lookup["BA:recente"].recent==1,"Recent interval is exactly 30 calendar days including today");
check(lookup["BA:anual"].annual==1,"Annual interval is 12 months with upper date bounded");
check(lookup["BA:futura"].recent==0 && lookup["BA:futura"].annual==0,"Future end dates cannot boost suggestions");
check(result.popular[1].slug=="popular","Popular suggestions rank by available events within the year");
seen={};for(row in result.recent)seen[row.uf & ":" & row.slug]=true;
for(row in result.popular)check(!structKeyExists(seen,row.uf & ":" & row.slug),"Suggestion groups never duplicate a city/UF pair");
empty=REQUEST.buildHomeCityCatalog(queryNew("id_evento,cidade,tag_cidade,estado,pais,data_final"),createDate(2026,10,4));
check(arrayLen(empty.cities)==0 && arrayLen(empty.recent)==0 && arrayLen(empty.popular)==0,"Empty eligible catalog is safe");
for(i=17;i<=26;i++)addEvent(i,"Cidade " & i,"cidade-" & i,"BA",createDate(2026,10,2));
limited=REQUEST.buildHomeCityCatalog(qEventosBase,createDate(2026,10,4));
check(arrayLen(limited.recent)==6 && arrayLen(limited.cities)==17,"Suggestion cap does not remove searchable cities");
</cfscript>
<cfset addEvent(27,"<script>alert(1)</script>","cidade-segura","BA",createDate(2026,10,1))/>
<cfinclude template="candidate/includes/backend_home_cidades.cfm"/>
<cfscript>
check(!find("<",VARIABLES.homeCityJson),"Catalog JSON cannot terminate its HTML script element");
parsed=deserializeJSON(VARIABLES.homeCityJson);found=false;
for(row in parsed)if(row.slug=="cidade-segura" && find("<script>",row.name))found=true;
check(found,"Safe JSON still carries the city text for textContent rendering");
</cfscript>
<cfsavecontent variable="homeForm"><cfinclude template="candidate/includes/form_busca_principal.cfm"/></cfsavecontent>
<cfset VARIABLES.template="/busca/"/>
<cfsavecontent variable="searchForm"><cfinclude template="candidate/includes/form_busca_principal.cfm"/></cfsavecontent>
<cfscript>
check(find("data-home-city-picker",homeForm)>0,"Home renders the city shortcut");
check(find("&amp;rua=true&amp;trail=true",homeForm)>0,"Server-rendered shortcuts include the modalities counted by the catalog");
check(!find("data-home-city-picker",searchForm) && find("Selecionar estado",searchForm)>0,"Shared search form keeps its existing controls outside home");
writeOutput("HOME_CITY_PASSED:" & VARIABLES.assertions);
</cfscript>
