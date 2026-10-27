<cfscript>
checks=0;function check(required boolean yes,required string name){if(!yes)throw(type='Test.Failed',message=name);checks++;}
s=new services.HelpdeskAutoClose();
check(s.authorized('POST',{Authorization='Bearer test-secret'},'test-secret'),'POST Bearer correto autorizado');
check(!s.authorized('GET',{Authorization='Bearer test-secret'},'test-secret'),'GET não autorizado');
check(!s.authorized('POST',{},'test-secret') AND !s.authorized('POST',{Authorization='Bearer wrong'},'test-secret') AND !s.authorized('POST',{Authorization='Bearer '},''),'Ausente, errado e vazio recusados');
request=s.input('{}');check(request.limit EQ 50 AND !request.dryRun,'Defaults seguros');
request=s.input('{"limit":100,"dryRun":true}');check(request.limit EQ 100 AND request.dryRun,'Dry run válido e limite máximo');
for(body in ['[]','null','not json','{"limit":0}','{"limit":101}','{"limit":1.5}','{"limit":"50"}','{"dryRun":"true"}','{"ticket":121}']){
 rejected=false;try{s.input(body);}catch(HelpdeskAutoClose.InvalidRequest e){rejected=true;}check(rejected,'Body inválido recusado: ' & body);
}
writeOutput('HELPDESK_CLOSE_SECURITY_PASSED ' & checks);
</cfscript>
