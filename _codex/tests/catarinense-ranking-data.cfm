<!--- Real PostgreSQL query against transaction-local synthetic tables. Always rollback. --->
<cfif NOT structKeyExists(REQUEST,'catarinenseTestAuthorized') OR NOT REQUEST.catarinenseTestAuthorized><cfheader statuscode="404"/><cfabort/></cfif>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label) { checks++; if(!arguments.condition) arrayAppend(failures,arguments.label); }
function fixture(required numeric id) { for(var i=1;i<=qRankingFixture.recordCount;i++) if(qRankingFixture.id[i]==arguments.id) { var r={}; for(var column in listToArray(qRankingFixture.columnList)) r[column]=isNull(qRankingFixture[column][i])?'':qRankingFixture[column][i]; return r; } throw(message='Fixture not returned'); }
source=fileRead(expandPath(VARIABLES.catarinenseTestBackend));
start=find('<!--- CIRCUITO CATARINENSE --->',source);
start=find('WITH circuit_config',source,start);
finish=find('<!--- OUTROS DESAFIOS --->',source,start);
fragment=trim(mid(source,start,finish-start));
scratch=getTempDirectory() & 'catarinense-data-' & lCase(replace(createUUID(),'-','','all'));
directoryCreate(scratch); fileWrite(scratch & '/query.cfm','<cfoutput>' & fragment & '</cfoutput>');
relativeScratch=repeatString('../',listLen(getDirectoryFromPath(getCurrentTemplatePath()),'/')) & mid(scratch,2,len(scratch));
deliveryStart=find('<!--- ENTREGA DE MEDALHA DOS CIRCUITOS CATARINENSES --->',source);
deliveryFinish=find('<!--- ALTERAR STATUS DA CAMPANHA --->',source,deliveryStart);
deliveryFragment=mid(source,deliveryStart,deliveryFinish-deliveryStart);
deliveryFragment=reReplace(deliveryFragment,'<cflocation addtoken="false" url="([^"]*)"/>','<cfset REQUEST.fixtureRedirect="\1"/>','all');
fileWrite(scratch & '/delivery.cfm',deliveryFragment);
VARIABLES.challengeTag='catarinensetrailrun'; VARIABLES.challengeCircuitTotalEvents=6;
VARIABLES.challengeCircuitEvents=[];
for(i=1;i<=6;i++) arrayAppend(VARIABLES.challengeCircuitEvents,{ordem=i,tag='fixture-' & i,percurso=6});
URL.challenge_refresh='fixture';
</cfscript>
<cftry>
<cftransaction>
<cfquery timeout="10">SET LOCAL statement_timeout='15s'; SET LOCAL lock_timeout='3s';</cfquery>
<cfloop list="tb_evento_corridas,tb_resultados,tb_resultados_obs,desafios,tb_usuarios,tb_paginas,desafios_obs,tb_uf,tb_crm" index="fixtureTable">
<cfquery>CREATE TEMP TABLE #fixtureTable# ON COMMIT DROP AS SELECT * FROM public.#fixtureTable# WITH NO DATA</cfquery>
</cfloop>
<cfquery>
INSERT INTO tb_evento_corridas(id_evento,tag,nome_evento,data_inicial,data_final)
SELECT i,'fixture-'||i,'Etapa '||i,'2026-01-01'::date+i*30,'2026-01-01'::date+i*30 FROM generate_series(1,6)i;
INSERT INTO tb_usuarios(id,name,data_nascimento,genero) VALUES
(901,'Atleta A','1970-01-01','MASCULINO'),(902,'Atleta B','1980-01-01','MASCULINO'),(903,'DNF','1980-01-01','MASCULINO'),
(904,'Sem colocacao','1980-01-01','MASCULINO'),(905,'Nao homologado','1980-01-01','MASCULINO'),(906,'Sem referencia','1980-01-01','MASCULINO'),
(907,'Referencia inconsistente','1980-01-01','MASCULINO'),(908,'Referencia armazenada','1980-01-01','MASCULINO');
INSERT INTO desafios(id_usuario,desafio,status,body)
SELECT id,'catarinensetrailrun','C','{}'::jsonb FROM tb_usuarios;
INSERT INTO tb_resultados(id_resultado,id_usuario,id_evento,num_peito,percurso,sexo,nome_categoria,id_categoria,tempo_total,tempo_f1_categoria,classificacao_sexo,classificacao_categoria,status_final,concluinte,homologado) VALUES
(1,901,1,11,6,'M','A',1,'00:12:00',NULL,2,2,0,true,true),
(2,901,6,61,6,'M','A',1,'00:15:00',NULL,7,7,0,true,true),
(3,902,1,12,6,'M','A',1,'00:13:00','00:15:00',3,3,0,true,true),
(4,903,1,13,6,'M','A',1,NULL,NULL,NULL,NULL,4,false,true),
(5,0,1,14,6,'M','A',1,'00:10:00',NULL,1,1,0,true,true),
(6,0,6,64,6,'M','A',1,'00:10:00',NULL,1,1,0,true,true),
(7,901,1,11,6,'M','A',1,'00:12:00',NULL,2,2,0,true,true),
(8,0,1,15,6,'F','A',1,'00:01:00',NULL,1,1,0,true,true),
(9,0,1,16,10,'M','A',1,'00:01:00',NULL,1,1,0,true,true),
(10,0,1,17,6,'M','B',2,'00:01:00',NULL,1,1,0,true,true),
(11,904,1,18,6,'M','A',1,'00:12:30',NULL,NULL,4,0,true,true),
(12,905,1,19,6,'M','A',1,'00:12:00',NULL,2,2,0,true,false),
(13,906,1,20,6,'M','C',3,'00:14:00',NULL,4,4,0,true,true),
(14,907,1,21,6,'M','A',1,'00:09:00','00:10:00',9,9,0,true,true),
(15,908,1,22,6,'M','D',4,'00:13:00','00:10:00',4,4,0,true,true);
INSERT INTO tb_resultados_obs(id_evento,num_peito,obs) VALUES (1,11,'90'),(6,61,'40'),(1,12,'80'),(1,13,'10'),(1,18,'10'),(1,19,'90'),(1,20,'70');
</cfquery>
<cfquery name="qRankingFixture" timeout="15"><cfinclude template="#relativeScratch#/query.cfm"/></cfquery>
<cfscript>
a=fixture(901); b=fixture(902); dnf=fixture(903);
check(a.distancia_percorrida==130,'duplicate official result cannot double stage points');
check(a.nodesafio==2,'duplicate result counts as one completed stage');
check(dnf.nodesafio==0 && dnf.distancia_percorrida==0,'DNF never counts as completion or ranking points');
check(fixture(905).nodesafio==0,'nonhomologated result never enters official ranking');
check(a.data_nascimento & ''=='1970-01-01','profile birth date is used when enrollment birth date is absent');
check(structKeyExists(a,'colocacoes_json'),'query supplies official placement histogram input');
check(structKeyExists(a,'media_percentual'),'query supplies category-relative mean');
if(structKeyExists(a,'colocacoes_json')) {
    places=deserializeJSON(a.colocacoes_json);
    check(arrayLen(places)==2 && places[1]==2 && places[2]==7,'one canonical placement per stage');
    check(a.ultima_colocacao==7 && b.ultima_colocacao==0,'sixth-stage result is distinct from no sixth-stage result');
    check(a.ultima_completa==1 && b.ultima_completa==1,'absence from final stage is known, not missing data');
    check(fixture(904).colocacoes_completas==0,'missing official placement is explicitly marked');
    check(abs(val(a.media_percentual)-135)<0.000001,'category winner lookup excludes other sex, category, and distance');
    check(val(b.media_percentual)==130,'actual category winner takes precedence over stale recorded reference');
    check(a.desempenho_completo==1 && fixture(906).desempenho_completo==0,'missing winner reference blocks a misleading partial mean');
    check(fixture(907).desempenho_completo==0,'athlete faster than the stated category winner flags inconsistent reference');
    check(val(fixture(908).media_percentual)==130,'recorded category reference is used when the actual winner row is unavailable');
}
</cfscript>
<!--- The actual POST reads/writes only transaction-local synthetic tables. --->
<cfinclude template="#VARIABLES.catarinenseTestHelper#"/>
<cfset VARIABLES.challengeIsCatarinenseCircuit=true/>
<cfset VARIABLES.challengeMedalCsrf="fixture-token"/>
<cfset FORM.challenge_action="entregar_medalha"/>
<cfset FORM.id_usuario=901/>
<cfset FORM.challenge_medal_csrf="fixture-token"/>
<cfset qPerfil=queryNew('id','integer',[{id=123}])/>
<cfloop list="busca,genero,medalha,regiao,cidade" index="fixtureKey"><cfset URL[fixtureKey]=""/></cfloop>
<cfset URL.aba="medalhas"/><cfset URL.pagina=2/><cfset URL.estado="SC"/>
<cfset URL.periodo="confirmados"/><cfset URL.preset="fixture"/>
<cfquery>
INSERT INTO tb_resultados(id_resultado,id_usuario,id_evento,num_peito,percurso,status_final,concluinte,homologado)
VALUES (20,901,2,21,6,0,true,true),(21,901,3,31,6,0,true,true);
</cfquery>
<cfset fourRejected=false/>
<cftry><cfinclude template="#relativeScratch#/delivery.cfm"/>
<cfcatch type="Challenge.Validation"><cfset fourRejected=true/></cfcatch></cftry>
<cfquery name="qFixtureDelivery">SELECT count(*) AS total FROM desafios_obs WHERE id_usuario=901 AND obs='medalha_entregue'</cfquery>
<cfset check(fourRejected AND qFixtureDelivery.total EQ 0,'four completions cannot register medal delivery')/>
<cfquery>
INSERT INTO tb_resultados(id_resultado,id_usuario,id_evento,num_peito,percurso,status_final,concluinte,homologado)
VALUES (22,901,4,41,6,0,true,true);
</cfquery>
<cfinclude template="#relativeScratch#/delivery.cfm"/>
<cfquery name="qFixtureDelivery">SELECT count(*) AS total FROM desafios_obs WHERE id_usuario=901 AND obs='medalha_entregue'</cfquery>
<cfset check(qFixtureDelivery.total EQ 1,'five completions permit medal delivery')/>
<cfset check(find('aba=medalhas',REQUEST.fixtureRedirect) AND find('pagina=2',REQUEST.fixtureRedirect),'delivery preserves medal tab and page')/>
<cfset check(find('estado=SC',REQUEST.fixtureRedirect) AND find('periodo=confirmados',REQUEST.fixtureRedirect) AND find('preset=fixture',REQUEST.fixtureRedirect),'delivery preserves all active filters')/>
<cfset check(find('sucesso=medalha_entregue',urlDecode(REQUEST.fixtureRedirect)) AND find('challenge_refresh=',REQUEST.fixtureRedirect),'delivery retains success and refresh state')/>
<cftransaction action="rollback"/>
</cftransaction>
<cffinally><cfif directoryExists(scratch)><cfset directoryDelete(scratch,true)/></cfif></cffinally>
</cftry>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfoutput>#serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures})#</cfoutput>
