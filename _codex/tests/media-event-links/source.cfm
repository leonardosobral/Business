<cfscript>
checks=0;
function expect(required boolean condition,required string label){if(!arguments.condition)throw(message=arguments.label,type="Media.Test");VARIABLES.checks++;}
qPerfil=queryNew("id,is_admin","integer,bit",[{id=0,is_admin=true}]);
VARIABLES.mediaHasEventId=true;VARIABLES.mediaEventCsrf=repeatString("a",64);
</cfscript>
<cfquery name="qFixtureColumns">SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_media'</cfquery>
<cfset VARIABLES.mediaPk=listFindNoCase(valueList(qFixtureColumns.column_name),'id_media') ? 'id_media' : (listFindNoCase(valueList(qFixtureColumns.column_name),'media_id') ? 'media_id' : 'id')/>
<cftransaction>
 <cftry>
 <cfquery name="qFixtureMedia">SELECT "#VARIABLES.mediaPk#" AS fixture_id,coalesce(id_evento,0) AS event_id,coalesce(pub_status,false) AS published,coalesce(is_featured,false) AS featured FROM tb_media WHERE coalesce(is_featured,false)=false ORDER BY "#VARIABLES.mediaPk#" DESC LIMIT 1 FOR UPDATE</cfquery>
 <cfquery name="qFixtureEvents">SELECT id_evento FROM tb_evento_corridas WHERE id_evento != <cfqueryparam cfsqltype="cf_sql_integer" value="#qFixtureMedia.event_id#"/> ORDER BY id_evento DESC LIMIT 2</cfquery>
 <cfscript>
 expect(qFixtureMedia.recordcount EQ 1 AND qFixtureEvents.recordcount EQ 2,"Fixtures existentes");
 FORM.media_id=qFixtureMedia.fixture_id&'';FORM.expected_event_id=qFixtureMedia.event_id&'';FORM.id_evento=qFixtureEvents.id_evento[1]&'';FORM.media_event_action="salvar";FORM.media_event_csrf=VARIABLES.mediaEventCsrf;
 VARIABLES.mediaFeaturedEventAlert={type="",message=""};
 </cfscript>
 <cfinclude template="../portal/includes/media_event_action.cfm"/>
 <cfset expect(VARIABLES.mediaEventSuccess EQ "evento_vinculado","Vincula vídeo sem destaque: " & VARIABLES.mediaFeaturedEventAlert.message )/>
 <cfquery name="qAfterLink">SELECT id_evento,pub_status,is_featured FROM tb_media WHERE "#VARIABLES.mediaPk#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#qFixtureMedia.fixture_id#"/></cfquery>
 <cfset expect(qAfterLink.id_evento EQ qFixtureEvents.id_evento[1] AND NOT qAfterLink.is_featured AND qAfterLink.pub_status EQ qFixtureMedia.published,"Vínculo mantém publicação e destaque")/>
 <!--- A stale editor must not overwrite the first save. --->
 <cfset FORM.id_evento=qFixtureEvents.id_evento[2]&''/><cfset FORM.expected_event_id="0"/>
 <cfinclude template="../portal/includes/media_event_action.cfm"/>
 <cfset expect(NOT len(VARIABLES.mediaEventSuccess) AND VARIABLES.mediaFeaturedEventAlert.type EQ "warning","Conflito não sobrescreve vínculo")/>
 <cfset FORM.expected_event_id=qFixtureEvents.id_evento[1]&''/>
 <cfinclude template="../portal/includes/media_event_action.cfm"/>
 <cfset expect(VARIABLES.mediaEventSuccess EQ "evento_vinculado","Troca o evento sem destacar")/>
 <cfset FORM.expected_event_id=qFixtureEvents.id_evento[2]&''/><cfset FORM.media_event_action="remover"/>
 <cfinclude template="../portal/includes/media_event_action.cfm"/>
 <cfset expect(VARIABLES.mediaEventSuccess EQ "evento_desvinculado","Remove vínculo")/>
 <cfquery name="qAfterRemoval">SELECT id_evento,(id_evento IS NULL) AS no_event,pub_status,is_featured FROM tb_media WHERE "#VARIABLES.mediaPk#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#qFixtureMedia.fixture_id#"/></cfquery>
 <cfset expect(qAfterRemoval.no_event AND NOT qAfterRemoval.is_featured AND qAfterRemoval.pub_status EQ qFixtureMedia.published,"Remoção mantém os demais campos")/>
 <!--- Hidden videos can also be linked, and remain hidden. --->
 <cfquery>UPDATE tb_media SET pub_status=false WHERE "#VARIABLES.mediaPk#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#qFixtureMedia.fixture_id#"/></cfquery>
 <cfset FORM.media_event_action="salvar"/><cfset FORM.expected_event_id="0"/><cfset FORM.id_evento=qFixtureEvents.id_evento[1]&''/>
 <cfinclude template="../portal/includes/media_event_action.cfm"/>
 <cfquery name="qHiddenLinked">SELECT id_evento,pub_status,is_featured FROM tb_media WHERE "#VARIABLES.mediaPk#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#qFixtureMedia.fixture_id#"/></cfquery>
 <cfset expect(qHiddenLinked.id_evento EQ qFixtureEvents.id_evento[1] AND NOT qHiddenLinked.pub_status AND NOT qHiddenLinked.is_featured,"Vídeo oculto vincula sem publicar nem destacar")/>
 <cfset FORM.expected_event_id=qFixtureEvents.id_evento[1]&''/><cfset FORM.id_evento="2147483647"/>
 <cfinclude template="../portal/includes/media_event_action.cfm"/>
 <cfset expect(NOT len(VARIABLES.mediaEventSuccess) AND VARIABLES.mediaFeaturedEventAlert.type EQ "danger","Evento inexistente recusado")/>
 <cfset FORM.id_evento="1.5"/>
 <cfinclude template="../portal/includes/media_event_action.cfm"/>
 <cfset expect(NOT len(VARIABLES.mediaEventSuccess),"ID fracionário recusado")/>
 <cfset FORM.id_evento=qFixtureEvents.id_evento[1]&''/><cfset FORM.media_event_csrf="invalido"/>
 <cfinclude template="../portal/includes/media_event_action.cfm"/>
 <cfset expect(NOT len(VARIABLES.mediaEventSuccess) AND findNoCase('sessão',VARIABLES.mediaFeaturedEventAlert.message),"CSRF inválido recusado")/>
 <cfquery name="qFeaturedFixture">SELECT "#VARIABLES.mediaPk#" AS fixture_id FROM tb_media WHERE is_featured=true LIMIT 1 FOR UPDATE</cfquery>
 <cfif qFeaturedFixture.recordcount>
  <cfquery name="qFeaturedBefore">SELECT coalesce(id_evento,0) AS event_id,pub_status FROM tb_media WHERE "#VARIABLES.mediaPk#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#qFeaturedFixture.fixture_id#"/></cfquery>
  <cfset FORM.media_id=qFeaturedFixture.fixture_id&''/><cfset FORM.expected_event_id=qFeaturedBefore.event_id&''/><cfset FORM.media_event_csrf=VARIABLES.mediaEventCsrf/><cfset FORM.id_evento=qFixtureEvents.id_evento[1]&''/>
  <cfinclude template="../portal/includes/media_event_action.cfm"/>
  <cfquery name="qFeaturedAfter">SELECT is_featured,pub_status,id_evento FROM tb_media WHERE "#VARIABLES.mediaPk#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#qFeaturedFixture.fixture_id#"/></cfquery>
  <cfset expect(qFeaturedAfter.is_featured AND qFeaturedAfter.pub_status EQ qFeaturedBefore.pub_status AND qFeaturedAfter.id_evento EQ qFixtureEvents.id_evento[1],"Destaque existente continua funcionando")/>
 </cfif>
 <cfset FORM.media_event_action=""/>
 <cfset URL.video_id=qFixtureMedia.fixture_id&''/><cfset URL.evento_busca=qFixtureEvents.id_evento[1]&''/><cfset URL.vinculo="sim"/>
 <cfsavecontent variable="rendered"><cfinclude template="../portal/videos/home.cfm"/></cfsavecontent>
 <cfset expect(findNoCase('Vincular vídeo a um evento',rendered) GT 0 AND findNoCase('Salvar vínculo com o evento selecionado',rendered) GT 0,"Editor e busca por ID renderizam")/>
 <cfset expect(qMediaEventEdit.recordcount EQ 1,"Seleciona vídeo independentemente do destaque")/>
 <cfloop query="qMedia"><cfset expect(val(qMedia.id_evento) GT 0,"Filtro com evento")/></cfloop>
 <cfset URL.video_id=""/><cfset URL.evento_busca=""/><cfset URL.vinculo="nao"/>
 <cfsavecontent variable="rendered"><cfinclude template="../portal/videos/home.cfm"/></cfsavecontent>
 <cfloop query="qMedia"><cfset expect(val(qMedia.id_evento) EQ 0,"Filtro sem evento")/></cfloop>
 <cfset URL.busca="codex-video-sem-resultado-20261124"/>
 <cfsavecontent variable="rendered"><cfinclude template="../portal/videos/home.cfm"/></cfsavecontent>
 <cfset expect(qMediaCount.total EQ 0 AND findNoCase('colspan="7"',rendered) GT 0,"Estado vazio e colspan corretos")/>
 <cffinally><cftransaction action="rollback"/></cffinally>
 </cftry>
</cftransaction>
<cfquery name="qRestored">SELECT coalesce(id_evento,0) AS event_id,pub_status,is_featured FROM tb_media WHERE "#VARIABLES.mediaPk#"=<cfqueryparam cfsqltype="cf_sql_integer" value="#qFixtureMedia.fixture_id#"/></cfquery>
<cfset expect(qRestored.event_id EQ qFixtureMedia.event_id AND qRestored.pub_status EQ qFixtureMedia.published AND qRestored.is_featured EQ qFixtureMedia.featured,"Rollback restaurou integralmente o vídeo")/>
<cfoutput>MEDIA_LINK_SOURCE_PASSED #checks#</cfoutput>
