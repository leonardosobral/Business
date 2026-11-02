<cfscript>
checks=0;
function checkRace(required boolean ok,required string label){if(!ok)throw(message=label);checks++;}
if (!isDefined("getEstadoNome")) {function getEstadoNome(required string uf){return arguments.uf;}}
qAgrega=queryNew("nome_evento_agregado,tag","varchar,varchar",[{nome_evento_agregado='Prova <script> & amigos',tag="teste"}]);
URL.tag="prova-teste";
qEventosMaratona=queryNew("id_evento,nome_evento,tag,cidade,estado,tag_cidade,pais,data_inicial,data_final","integer,varchar,varchar,varchar,varchar,varchar,varchar,date,date");
queryAddRow(qEventosMaratona,{id_evento=1,nome_evento="Em andamento",tag="em-andamento",cidade="Curitiba",estado="PR",tag_cidade="curitiba",pais="BR",data_inicial=dateAdd("d",-1,now()),data_final=dateAdd("d",1,now())});
queryAddRow(qEventosMaratona,{id_evento=2,nome_evento="Futura sem término",tag="futura",cidade="Curitiba",estado="PR",tag_cidade="curitiba",pais="BR",data_inicial=dateAdd("d",20,now())});
queryAddRow(qEventosMaratona,{id_evento=3,nome_evento="Antiga sem término",tag="antiga",cidade="Curitiba",estado="PR",tag_cidade="curitiba",pais="BR",data_inicial=dateAdd("d",-20,now())});
queryAddRow(qEventosMaratona,{id_evento=4,nome_evento="Ontem",tag="ontem",cidade="Curitiba",estado="PR",tag_cidade="curitiba",pais="BR",data_inicial=dateAdd("d",-2,now()),data_final=dateAdd("d",-1,now())});
</cfscript>
<cfquery name="qEventosAba2" dbtype="query" result="qEventosAba2Meta">
                    SELECT * from qEventosMaratona
                    WHERE (data_final IS NOT NULL AND data_final >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>) OR (data_final IS NULL AND data_inicial >= <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>)
                    ORDER BY data_inicial
                </cfquery>
                

                <cfquery name="qEventosAba7" dbtype="query" result="qEventosAba7Meta">
                    SELECT * from qEventosMaratona
                    WHERE (data_final IS NOT NULL AND data_final < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>) OR (data_final IS NULL AND data_inicial < <cfqueryparam cfsqltype="cf_sql_date" value="#now()#"/>)
                    ORDER BY data_inicial desc
                </cfquery>
                




<cfinclude template="includes/backend/backend_permanent_race.cfm"/>
<cfsavecontent variable="view"><cfinclude template="includes/permanent_race_overview.cfm"/></cfsavecontent>
<cfscript>
checkRace(qEventosAba2.recordCount==2,"Ongoing and null-end future stay upcoming");
checkRace(qEventosAba7.recordCount==2,"Ended and null-end past stay historical");
checkRace(VARIABLES.permanentNext.tag=="em-andamento","Ongoing event chosen first");
checkRace(VARIABLES.permanentLast.tag=="ontem","Most recent past event");
checkRace(arrayLen(VARIABLES.permanentPlaces)==1,"Cities deduplicated");
checkRace(find("Em andamento",view)>0,"Ongoing label");
checkRace(find("<script>",view)==0,"Escaped race title");
checkRace(arrayLen(deserializeJSON(VARIABLES.permanentJson).mainEntity.itemListElement)==4,"Structured items match editions");
qEventosAba2=queryNew(qEventosMaratona.columnList);
qEventosAba7=queryNew(qEventosMaratona.columnList);
</cfscript>
<cfinclude template="includes/backend/backend_permanent_race.cfm"/>
<cfsavecontent variable="view"><cfinclude template="includes/permanent_race_overview.cfm"/></cfsavecontent>
<cfscript>
checkRace(structIsEmpty(VARIABLES.permanentNext),"Empty history has no invented next event");
checkRace(find("Não há próxima edição neste histórico",view)>0,"Explicit empty history");
checkRace(arrayLen(VARIABLES.permanentPlaces)==0,"Empty history has no invented cities");
qEventosAba2=queryNew("nome_evento,tag,cidade,estado,tag_cidade,pais,data_inicial,data_final","varchar,varchar,varchar,varchar,varchar,varchar,date,date",[{nome_evento="Estrangeira",tag="foreign",cidade="Fora",estado="PR",tag_cidade="fora",pais="US",data_inicial=now(),data_final=now()}]);
</cfscript>
<cfinclude template="includes/backend/backend_permanent_race.cfm"/>
<cfscript>checkRace(arrayLen(VARIABLES.permanentPlaces)==0,"Foreign races do not link Brazilian state");qEventosAba2.pais[1]="BR";qEventosAba2.tag_cidade[1]='bad/slug';</cfscript>
<cfinclude template="includes/backend/backend_permanent_race.cfm"/>
<cfscript>checkRace(arrayLen(VARIABLES.permanentPlaces)==0,"Invalid city slug excluded");</cfscript>
<cfscript>
qAgrega.tag[1]="maratona-internacional-de-floripa";
VARIABLES.permanentNext={tag="2027-maratona-internacional-de-floripa-fibra-2027",start=createDate(2027,8,28),finish=createDate(2027,8,29)};
</cfscript>
<cfsavecontent variable="editorial"><cfinclude template="includes/permanent_race_editorial.cfm"/></cfsavecontent>
<cfscript>checkRace(find('data-race-editorial',editorial)>0,"Verified editorial matches exact edition");VARIABLES.permanentNext.start=createDate(2028,8,28);</cfscript>
<cfsavecontent variable="editorial"><cfinclude template="includes/permanent_race_editorial.cfm"/></cfsavecontent>
<cfscript>checkRace(find('data-race-editorial',editorial)==0,"Editorial hidden when date changes");VARIABLES.permanentNext.start=createDate(2027,8,28);VARIABLES.permanentNext.tag="new-edition";</cfscript>
<cfsavecontent variable="editorial"><cfinclude template="includes/permanent_race_editorial.cfm"/></cfsavecontent>
<cfscript>checkRace(find('data-race-editorial',editorial)==0,"Editorial hidden for another edition");</cfscript>
<cfoutput>RACE_MODEL_PASSED:#checks#</cfoutput>
