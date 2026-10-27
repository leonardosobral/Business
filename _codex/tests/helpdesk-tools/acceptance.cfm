<cfscript>
s=createObject('component','helpdesk'&'.includes.HelpdeskReplies').init();data=s.list();
if(arrayLen(data.items) NEQ 3)throw(message='Expected original three models after browser validation');
if(createObject('component','services'&'.geocoding.Store').settings().enabled)throw(message='Geolocation must remain paused');
if(queryExecute("SELECT count(*) AS n FROM tb_helpdesk_chamados WHERE protocolo LIKE 'CODEX-NOTE-%'",{},{datasource='runner_dba'}).n NEQ 0)throw(message='Unexpected synthetic ticket remains');
writeOutput('HELPDESK_TOOLS_ACCEPTANCE_PASSED library=3 geolocation_paused=true');
</cfscript>
