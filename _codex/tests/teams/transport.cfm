<cfscript>
checks=0;function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
check(fileExists(expandPath('services/teams/EmailTransport.cfc')),'Transporte CFMAIL nativo ausente');
transport=new services.teams.EmailTransport();
check(isBoolean(transport.configured()),'Configuração consultável sem revelar credenciais');
check(transport.enviarEmail('Fixture','<p>Fixture</p>','one@example.org,two@example.org','Injected')=='ERRO','Múltiplos destinatários rejeitados antes de SMTP');
check(transport.enviarEmail('Fixture','<p>Fixture</p>','not-an-address','Name')=='ERRO','Destino inválido rejeitado antes de SMTP');
writeOutput('TEAMS_TRANSPORT_PASSED ' & checks & '; invalid envelopes only; no SMTP');
</cfscript>
