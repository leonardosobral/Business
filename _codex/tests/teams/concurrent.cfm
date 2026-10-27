<cfscript>
svc=new services.teams.Service().init('runner_dba','rr_teams_test');
try {
 if(FORM.operation=='join')svc.join(REQUEST.businessIdentity.id,FORM.team=='a'?10001:10002,true);
 else if(FORM.operation=='recruit')svc.recruit(REQUEST.businessIdentity.id,'Crew concorrente','EMAIL',APPLICATION.testRecruitAddress);
 else throw(type='Teams.Validation',message='Operação inválida.');
 cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({ok=true}));
}catch(Teams.Validation rejected){cfheader(statuscode=409);cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({ok=false,reason='rejected'}));}
</cfscript>
