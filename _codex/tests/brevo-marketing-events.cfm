<cfscript>
function webhookCheck(required boolean condition,required string name){
    if(!condition) throw(type='TestFailed',message=name);
}
varSecret=repeatString('y',40);
events=new services.BrevoMarketingEvents();
events.verifyToken({Authorization='Bearer ' & varSecret},varSecret);
for(headers in [{},{Authorization='Basic abc'},{Authorization='Bearer ' & uCase(varSecret)}]){
    denied=false;
    try{events.verifyToken(headers,varSecret);}catch(BrevoWebhook.Forbidden expected){denied=true;}
    webhookCheck(denied,'invalid authentication');
}
event={event='hard_bounce',email=' MiXeD@example.test ',camp_id=81,ts_event=1700000000};
batch=events.parseEvents(serializeJSON([event,{event='contact_updated'},{event='unsubscribe',email='guest@example.test'}]));
webhookCheck(arrayLen(batch)==1 && batch[1].kind=='hard_bounce' && batch[1].email=='mixed@example.test','normalization');
event.event='unsubscribe';structDelete(event,'ts_event');event.ts=1700000020;
webhookCheck(events.parseEvents(serializeJSON(event))[1].epoch==event.ts,'legacy timestamp fallback');
webhookCheck(arrayLen(events.parseEvents('[null,{"event":null}]'))==0,'null list entries');
for(bad in ['not json','123','null']){
    denied=false;
    try{events.parseEvents(bad);}catch(BrevoWebhook.Invalid expected){denied=true;}
    webhookCheck(denied,'malformed input');
}
writeOutput('BREVO_WEBHOOK_CHECKS_PASSED');
</cfscript>
