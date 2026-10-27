component output=false {
    variables.ds='runner_dba';variables.schema='rr_teams';
    public any function init(string datasource='runner_dba',string schema='rr_teams',any sender,any clock) {if(!reFind('^[a-z][a-z0-9_]{0,60}$',schema))throw(type='Teams.Validation',message='Esquema inválido.');variables.ds=datasource;variables.schema=schema;if(structKeyExists(arguments,'sender'))variables.sender=arguments.sender;else structDelete(variables,'sender',false);variables.clock=structKeyExists(arguments,'clock')?arguments.clock:function(){return getTickCount();};return this;}
    private any function q(required string sql,struct params={}){return queryExecute(replace(sql,'{s}',variables.schema,'all'),numericParams(params),{datasource=variables.ds,timeout=10});}
    private struct function numericParams(required struct values){var bound={};for(var key in values)bound[key]={value=values[key],cfsqltype='cf_sql_bigint'};return bound;}
    public struct function run(numeric limit=10,boolean dryRun=true) {
        if(limit<1||limit>10||int(limit)!=limit)throw(type='Teams.Validation',message='Limite inválido.');
        var result={dryRun=dryRun,selected=0,sent=0,failed=0,deferred=0,ambiguous=0};
        result.ambiguous=q("SELECT count(*) n FROM {s}.mail_outbox WHERE status='SENDING'").n[1];
        if(dryRun){result.selected=q("SELECT count(*) n FROM (SELECT id_mail FROM {s}.mail_outbox WHERE status='PENDING' AND next_attempt_at<=CURRENT_TIMESTAMP AND attempts<3 LIMIT :limit) eligible",{limit=limit}).n[1];return result;}
        var claimed=queryNew('id_mail,destination,recipient_name,subject,body');
        transaction {
            claimed=q("WITH picked AS (SELECT id_mail FROM {s}.mail_outbox WHERE status='PENDING' AND next_attempt_at<=CURRENT_TIMESTAMP AND attempts<3 ORDER BY id_mail FOR UPDATE SKIP LOCKED LIMIT :limit) UPDATE {s}.mail_outbox m SET status='SENDING',claimed_at=CURRENT_TIMESTAMP,attempts=attempts+1 FROM picked WHERE m.id_mail=picked.id_mail RETURNING m.id_mail,m.destination,m.recipient_name,m.subject,m.body",{limit=limit});
        }
        result.selected=claimed.recordCount;
        var began=structKeyExists(variables,'clock')?variables.clock():getTickCount();
        for(var message in claimed){
            var tick=structKeyExists(variables,'clock')?variables.clock():getTickCount();
            if(tick-began>=15000){
                q("UPDATE {s}.mail_outbox SET status='PENDING',attempts=GREATEST(0,attempts-1),claimed_at=NULL WHERE id_mail=:id AND status='SENDING'",{id=message.id_mail});result.deferred++;continue;
            }
            var sent=false;
            try {var transport=structKeyExists(variables,'sender')?variables.sender:new services.teams.EmailTransport();sent=transport.enviarEmail(message.subject,message.body,message.destination,'Road Runners Teams')=='OK';}catch(any failed){writeLog(file='teams-mail',type='error',text='delivery_failed id=' & message.id_mail & ' type=' & failed.type);}
            if(sent){q("UPDATE {s}.mail_outbox SET status='SENT',sent_at=CURRENT_TIMESTAMP,body='' WHERE id_mail=:id AND status='SENDING'",{id=message.id_mail});result.sent++;}
            else {q("UPDATE {s}.mail_outbox SET status=CASE WHEN attempts>=3 THEN 'FAILED' ELSE 'PENDING' END,next_attempt_at=CURRENT_TIMESTAMP+interval '15 minutes' WHERE id_mail=:id AND status='SENDING'",{id=message.id_mail});result.failed++;}
        }return result;
    }
}
