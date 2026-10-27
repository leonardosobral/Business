<cfsetting showdebugoutput="false"/>
<cfscript>
checks=0;
function expect(required boolean ok,required string message){if(!ok)throw(type="RegionalTest",message=message);checks++;}
URL.tag="PR";URL.page=0;URL.cidade="curitiba";URL.distancia="1,42";URL.tempo="0,1";URL.rua=true;URL.trail=false;URL.nacional=true;URL.internacional=false;URL.cupom=true;URL.badges="cupom&x=<script>";
qEventos=queryNew("lista_percursos","varchar",[{lista_percursos='[{"percurso":5,"unidade":"km"},{"percurso":10,"unidade":"km"}]'},{lista_percursos='[{"percurso":42,"unidade":"m"},{"percurso":21,"unidade":"km"}]'}]);
</cfscript>
<cfsavecontent variable="rendered"><cfinclude template="includes/regional_summary.cfm"/></cfsavecontent>
<cfscript>
expect(find('data-regional-total="2"',rendered)>0,"Total includes full query.");
expect(find(encodeForHTMLAttribute('/estado/pr/curitiba/?distancia=5%2C5'),rendered)>0,"Distance link retains city.");
expect(find('>21 km</a>',rendered)>0 && find('>42 km</a>',rendered)==0,"Only actual kilometre categories offered.");
expect(find(encodeForHTMLAttribute('cupom='),rendered)>0 && find(encodeForHTMLAttribute('trail='),rendered)>0 && findNoCase(encodeForHTMLAttribute('tempo=0%2C1'),rendered)>0,"Links preserve other filters.");
expect(find('<script>',rendered)==0,"Filter value cannot inject HTML.");
URL.page=1;
</cfscript>
<cfsavecontent variable="rendered"><cfinclude template="includes/regional_summary.cfm"/></cfsavecontent>
<cfscript>expect(find('data-regional-summary',rendered)==0,"Pagination never repeats summary.");URL.page=0;qEventos=queryNew("id","integer");</cfscript>
<cfsavecontent variable="rendered"><cfinclude template="includes/regional_summary.cfm"/></cfsavecontent>
<cfscript>
expect(find('data-regional-total="0"',rendered)>0 && find('Não encontramos',rendered)>0,"Empty state explains zero inventory.");
expect(find('Ver calendário do estado',rendered)>0,"Empty city offers state calendar.");
URL.tag="XX";
</cfscript>
<cfsavecontent variable="rendered"><cfinclude template="includes/regional_summary.cfm"/></cfsavecontent>
<cfscript>expect(find('data-regional-summary',rendered)==0,"Invalid UF does not emit regional links.");
VARIABLES.canonical="https://roadrunners.run/evento/teste/";
qEvento=queryNew("estado,pais,cidade,tag_cidade,nome_evento","varchar,varchar,varchar,varchar,varchar",[{estado="PR",pais="BR",cidade="Curitiba",tag_cidade="curitiba",nome_evento="Corrida & Amigos"}]);
</cfscript>
<cfsavecontent variable="rendered"><cfinclude template="evento/parts/breadcrumb.cfm"/></cfsavecontent>
<cfscript>
expect(arrayLen(VARIABLES.eventBreadcrumbs)==4,"Home/state/city/event hierarchy.");
expect(VARIABLES.eventBreadcrumbs[3].item=="https://roadrunners.run/estado/pr/curitiba/","City link uses regional URL.");
expect(VARIABLES.eventBreadcrumbs[4].name=="Corrida & Amigos","JSON breadcrumb retains raw name.");
expect(find(encodeForHTML('Corrida & Amigos'),rendered)>0,"Visible breadcrumb is escaped.");
querySetCell(qEvento,"pais","US",1);
</cfscript>
<cfsavecontent variable="rendered"><cfinclude template="evento/parts/breadcrumb.cfm"/></cfsavecontent>
<cfscript>expect(arrayLen(VARIABLES.eventBreadcrumbs)==2,"Foreign race never links Brazilian regions.");querySetCell(qEvento,"pais","BR",1);querySetCell(qEvento,"tag_cidade","bad/slug",1);</cfscript>
<cfsavecontent variable="rendered"><cfinclude template="evento/parts/breadcrumb.cfm"/></cfsavecontent>
<cfscript>expect(arrayLen(VARIABLES.eventBreadcrumbs)==3,"Invalid city slug omitted.");</cfscript>
<cfoutput>REGIONAL_TESTS_PASSED:#checks#</cfoutput>
