<cfscript>
checks=0;
function checkPost(required boolean ok,required string label){if(!ok)throw(message=label);checks++;}
qEvento=queryNew("id_evento,id_agrega_evento,nome_evento,tag,cidade,estado,pais,tag_cidade,data_inicial,data_final,status_evento,url_resultado","integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,date,date,varchar,varchar",[{id_evento=-1,id_agrega_evento=28,nome_evento='Prova <script>',tag='antiga',cidade='Florianópolis',estado='SC',pais='BR',tag_cidade='florianopolis',data_inicial=dateAdd('d',-3,now()),data_final=dateAdd('d',-2,now()),status_evento='',url_resultado='javascript:alert(1)'}]);
qAgrega=queryNew("tipo_agregacao","varchar",[{tipo_agregacao='maratona'}]);
qEventoEdicoes=queryNew("id_agrega_evento,nome_evento,tag,data_inicial,data_final,status_evento","integer,varchar,varchar,date,date,varchar",[
{id_agrega_evento=28,nome_evento='Depois',tag='depois',data_inicial=dateAdd('d',50,now()),data_final=dateAdd('d',51,now()),status_evento=''},
{id_agrega_evento=99,nome_evento='Outra família',tag='outra',data_inicial=dateAdd('d',1,now()),data_final=dateAdd('d',1,now()),status_evento=''},
{id_agrega_evento=28,nome_evento='Cancelada',tag='cancelada',data_inicial=dateAdd('d',2,now()),data_final=dateAdd('d',2,now()),status_evento='cancelado'},
{id_agrega_evento=28,nome_evento='Próxima <script>',tag='proxima',data_inicial=dateAdd('d',20,now()),data_final=dateAdd('d',21,now()),status_evento=''}]);
VARIABLES.eventFocoValor='123';VARIABLES.eventFocoGalleryToken='teste';
VARIABLES.eventFocoGalleries=[{url='https://www.focoradical.com.br/prova/123-teste',name='Galeria <script>',date='',location=''},
{url='https://www.focoradical.com.br/prova/123-teste',name='Duplicada',date='',location=''},
{url='https://www.focoradical.com.br',name='Sem prova',date='',location=''},
{url='https://www.focoradical.com.br.evil.example/prova/1',name='Outro domínio',date='',location=''},
{url='javascript:alert(1)',name='Inválida',date='',location=''}];
</cfscript>
<cfinclude template="evento/parts/post_race_data.cfm"/>
<cfscript>
checkPost(VARIABLES.postRace.enabled,"Past multi-day event enabled");
checkPost(!VARIABLES.postRace.results,"No invented imported results");
checkPost(VARIABLES.postRace.resultSource=="","Unsafe result URL excluded");
checkPost(arrayLen(VARIABLES.postRace.galleries)==1,"Deduplicate galleries; reject generic and forged hosts");
checkPost(VARIABLES.postRace.nextEdition.path=="/evento/proxima/","Earliest future same-family edition, excluding cancellation");
checkPost(find(' – ',VARIABLES.postRace.nextEdition.dateLabel)>0,"Multi-day next edition date range");
checkPost(VARIABLES.postRace.calendar=="/estado/sc/florianopolis/","Regional link");
</cfscript>
<cfsavecontent variable="postRaceView"><cfinclude template="evento/parts/post_race.cfm"/></cfsavecontent>
<cfscript>checkPost(find('Galeria &lt;script&gt;',postRaceView)>0 && find('Galeria <script>',postRaceView)==0,"Gallery names escaped");qEvento.data_final[1]=now();</cfscript>
<cfinclude template="evento/parts/post_race_data.cfm"/>
<cfscript>checkPost(!VARIABLES.postRace.enabled,"Today is not finished");qEvento.data_final[1]=dateAdd('d',1,now());</cfscript>
<cfinclude template="evento/parts/post_race_data.cfm"/>
<cfscript>checkPost(!VARIABLES.postRace.enabled,"Ongoing multi-day race is not finished");qEvento.data_final[1]=dateAdd('d',-2,now());qEvento.status_evento[1]='cancelado';</cfscript>
<cfinclude template="evento/parts/post_race_data.cfm"/>
<cfscript>checkPost(!VARIABLES.postRace.enabled,"Cancelled race not presented as held");qEvento.status_evento[1]='adiado';</cfscript>
<cfinclude template="evento/parts/post_race_data.cfm"/>
<cfscript>checkPost(!VARIABLES.postRace.enabled,"Postponed race not presented as held");qEvento.status_evento[1]='';qAgrega.tipo_agregacao[1]='circuito';qEvento.pais[1]='US';REQUEST.lang='en';qEvento.url_resultado[1]='https://example.com/results?a=1&b=2';</cfscript>
<cfinclude template="evento/parts/post_race_data.cfm"/>
<cfscript>checkPost(structIsEmpty(VARIABLES.postRace.nextEdition),"Circuit stop never used as next edition");checkPost(VARIABLES.postRace.calendar=='',"Foreign race does not link a Brazilian city");checkPost(VARIABLES.postRace.resultSource=='https://example.com/results?a=1&b=2',"Public source preserved");checkPost(VARIABLES.postRaceText.heading=='After the race: results and photos',"English labels");qAgrega.tipo_agregacao[1]='maratona';REQUEST.lang='es';</cfscript>
<cfinclude template="evento/parts/post_race_data.cfm"/>
<cfscript>checkPost(VARIABLES.postRace.nextEdition.path=='/es/evento/proxima/',"Localized next edition");checkPost(VARIABLES.postRaceText.details=='Ver la próxima edición',"Spanish label");qEventoEdicoes=queryNew('id_agrega_evento,nome_evento,tag,data_inicial,data_final,status_evento');</cfscript>
<cfinclude template="evento/parts/post_race_data.cfm"/>
<cfscript>checkPost(structIsEmpty(VARIABLES.postRace.nextEdition),"No future edition is not invented");writeOutput('POST_RACE_PASSED:' & checks);</cfscript>
