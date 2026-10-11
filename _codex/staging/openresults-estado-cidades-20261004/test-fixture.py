from pathlib import Path
import re
s=Path(__file__).resolve().parent
q=re.search(r'<cfquery name="qEventos" dbtype="query">.*?</cfquery>',(s/'candidate/includes/backend.cfm').read_text(),re.S).group(0)
head='''<cfsetting showdebugoutput="false"/><cfscript>
VARIABLES.template="/estado/"; VARIABLES.assertions=0;
function check(required boolean ok,required string message){if(!ok)throw(message=message);VARIABLES.assertions++;}
function testCityCount(required string slug){for(var row in qEstadoCidades)if(row.tag_cidade==slug)return row.total_eventos;return 0;}
qEventosBase=queryNew("id_evento,nome_evento,cidade,tag_cidade,estado,pais,tipo_corrida,cupom,is_maratona,data_final,concluintes", "integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,date,integer");
for(i=1;i<=31;i++) queryAddRow(qEventosBase,{id_evento=i,nome_evento="Maratona Salvador",cidade="SALVADOR",tag_cidade="salvador",estado="BA",pais="BR",tipo_corrida="rua",cupom="CUPOM",is_maratona=42,data_final=createDate(2026,9,1),concluintes=1000+i});
for(i=32;i<=54;i++) queryAddRow(qEventosBase,{id_evento=i,nome_evento="Feira",cidade="FEIRA DE SANTANA",tag_cidade="feira-de-santana",estado="BA",pais="BR",tipo_corrida="rua",cupom="CUPOM",is_maratona=0,data_final=createDate(2026,9,1),concluintes=1000+i});
queryAddRow(qEventosBase,{id_evento=55,nome_evento="Trail Salvador",cidade="SALVADOR",tag_cidade="salvador",estado="BA",pais="BR",tipo_corrida="trail",cupom="CUPOM",is_maratona=42,data_final=createDate(2026,9,1),concluintes=500});
queryAddRow(qEventosBase,{id_evento=56,nome_evento="Recife",cidade="RECIFE",tag_cidade="recife",estado="PE",pais="BR",tipo_corrida="rua",cupom="CUPOM",is_maratona=42,data_final=createDate(2026,9,1),concluintes=500});
queryAddRow(qEventosBase,{id_evento=57,nome_evento="Revezamento",cidade="SALVADOR",tag_cidade="salvador",estado="BA",pais="BR",tipo_corrida="rua",cupom="CUPOM",is_maratona=42,data_final=createDate(2026,9,1),concluintes=500});
queryAddRow(qEventosBase,{id_evento=59,nome_evento="Cidade em branco",cidade="   ",tag_cidade="---",estado="BA",pais="BR",tipo_corrida="rua",cupom="CUPOM",is_maratona=0,data_final=createDate(2026,9,1),concluintes=500});
qEstadoCidadesFixtureBase=duplicate(qEventosBase);
structClear(URL);structAppend(URL,{tag="BA",cidade="",filtro="",distancia="1,42",tempo="0,12",rua=true,trail=false,nacional=true,internacional=false,cupom=false,badges="",ano="2025"},true);
</cfscript>
'''
cases=[('', '', 'true','false', '''check(qEventos.recordCount==56,"All historical state events remain available");check(VARIABLES.estadoCitiesTotal==56,"All-city total includes events without a city");check(testCityCount("salvador")==32,"Salvador count");check(testCityCount("feira-de-santana")==23,"Other cities remain selectable");check(testCityCount("recife")==0,"No other state city leaks");check(qEstadoCidades.recordCount==2,"Blank city is not an option");'''),
('salvador','','true','false','''check(qEventos.recordCount==32,"Selected city list");check(testCityCount("feira-de-santana")==23,"Selected city does not hide other options");check(VARIABLES.estadoCidadeNome=="Salvador","Display name");'''),
('FEIRA DE SANTANA','','true','false','''check(qEventos.recordCount==23,"Legacy city name works");check(VARIABLES.estadoCidadeSlug=="feira-de-santana","Legacy city normalized");check(VARIABLES.estadoCidadeNome=="Feira de Santana","Connectors stay lowercase");'''),
('recife','','true','false','''check(qEventos.recordCount==0,"Wrong-state city yields no records");check(VARIABLES.estadoCitiesTotal==56,"Clearing invalid selection remains possible");'''),
('salvador','maiores','true','false','''check(qEventos.recordCount==20,"Top 20 limited after selecting city");check(testCityCount("salvador")==20,"Top20 city count");check(testCityCount("feira-de-santana")==20,"Alternative Top20 count");check(VARIABLES.estadoCitiesTotal==20,"All Top20 count");check(qEventos.concluintes[1]==1031,"Top20 order");'''),
('salvador','maratonas','true','true','''check(qEventos.recordCount==31,"Marathons exclude relays and trail");check(testCityCount("feira-de-santana")==0,"Zero marathon city count");check(VARIABLES.estadoCitiesTotal==31,"Marathon state count");'''),
('feira-de-santana','','false','true','''check(qEventos.recordCount==0,"Selected city can be empty for modality");check(testCityCount("salvador")==1,"Trail city alternative");check(testCityCount("feira-de-santana")==0,"Trail city count");'''),
('', 'invalid','true','false','''check(URL.filtro=="","Unknown tab normalizes to latest");check(qEventos.recordCount==56,"Unknown tab still renders");check(find("distancia=",REQUEST.estadoCityUrl("salvador","maratonas"))>0,"Server links retain range");check(find("cidade=salvador",REQUEST.estadoCityUrl("salvador","maratonas"))>0,"Server links retain city");''')]
text=head
for city,mode,rua,trail,checks in cases:
 text+=f'<cfset URL.cidade="{city}"/><cfset URL.filtro="{mode}"/><cfset URL.rua={rua}/><cfset URL.trail={trail}/>' + q + '<cfinclude template="candidate/includes/backend_estado_cidades.cfm"/><cfscript>'+checks+'</cfscript>\n'
text += '<cfquery name="qEventosBase" dbtype="query">SELECT * FROM qEstadoCidadesFixtureBase WHERE id_evento=1</cfquery><cfset URL.cidade="feira-de-santana"/><cfset URL.filtro=""/><cfset URL.badges="ouro"/>' + q + '<cfinclude template="candidate/includes/backend_estado_cidades.cfm"/><cfscript>check(qEventos.recordCount==0,"Badge selection can have no events in the city");check(VARIABLES.estadoCidadeNome=="Feira de Santana","Badge selection preserves valid city name");check(qEstadoCidades.recordCount==2,"Badge selection preserves city options");check(testCityCount("salvador")==1,"Badge city alternative count");</cfscript>'
text+='<cfoutput>OR_CITY_PASSED:#VARIABLES.assertions#</cfoutput>'
(s/'tests/counts.cfm').write_text(text)
print('Fixture de filtros, contagens, abas e seleção vazia preparada.')
