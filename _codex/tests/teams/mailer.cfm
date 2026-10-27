<cfscript>
checks=0;function check(required boolean ok,required string label){if(!ok)throw(type='Teams.Test',message=label);checks++;}
mailer=new services.teams.Mailer();safe=false;
for(fn in getMetadata(mailer).functions)if(fn.name=='init')for(param in fn.parameters)if(param.name=='sender')safe=true;
check(safe,'Transporte isolado necessário antes de testar envelopes sem SMTP');
sender=createObject('component','__FAKE_SENDER__');mailer.init('runner_dba','rr_teams_test',sender);
transaction {try {
 queryExecute("INSERT INTO rr_teams_test.mail_outbox(destination,recipient_name,subject,body) VALUES('fixture@example.org','Extra <extra@example.org>, Grupo','Convite fixture','<p>Teste isolado</p>')",{}, {datasource='runner_dba'});
 result=mailer.run(1,false);calls=sender.calls();check(result.sent==1&&arrayLen(calls)==1,'Uma entrega ao transporte isolado');
 check(calls[1].email=='fixture@example.org','Destino validado preservado');
 check(!find('<',calls[1].name)&&!find(',',calls[1].name)&&!find('extra@example.org',calls[1].name),'Nome controlado não acrescenta destinatários');
 check(queryExecute("SELECT count(*) n FROM rr_teams_test.mail_outbox WHERE status='SENT' AND body=''",{}, {datasource='runner_dba'}).n[1]==1,'Corpo sensível limpo após envio');
}finally{transaction action='rollback';}}
check(queryExecute('SELECT count(*) n FROM rr_teams_test.mail_outbox',{}, {datasource='runner_dba'}).n[1]==0,'Fixture de email revertida');
transaction {try {
 queryExecute("INSERT INTO rr_teams_test.mail_outbox(destination,recipient_name,subject,body) VALUES('fixture1@example.org','Fixture','Fixture','Body'),('fixture2@example.org','Fixture','Fixture','Body')",{}, {datasource='runner_dba'});
 sender=createObject('component','__FAKE_SENDER__');ticks=0;
 clock=function(){ticks++;return ticks<=2?0:25000;};
 mailer.init('runner_dba','rr_teams_test',sender,clock);
 result=mailer.run(2,false);check(result.sent==1&&arrayLen(sender.calls())==1,'Orçamento de tempo limita envios antes do timeout HTTP');
 pending=queryExecute("SELECT count(*) n FROM rr_teams_test.mail_outbox WHERE status='PENDING' AND attempts=0 AND claimed_at IS NULL",{}, {datasource='runner_dba'});
 check(pending.n[1]==1,'Mensagem não tentada volta para fila sem consumir tentativa');
}finally{transaction action='rollback';}}
writeOutput('TEAMS_MAILER_PASSED ' & checks & '; fake transport only; no SMTP');
</cfscript>
