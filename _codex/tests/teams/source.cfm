<cfscript>
service=new services.teams.Service();fixture=new services.teams.Service().init('runner_dba','rr_teams_test');
if(!service.ready()||!fixture.ready())throw(type='Teams.Test',message='Schemas incompletos');
p=queryExecute("SELECT version FROM rr_teams.schema_version",{}, {datasource='runner_dba'});
f=queryExecute('SELECT count(*) n FROM rr_teams_test.team',{}, {datasource='runner_dba'});
j=queryExecute("SELECT ativo FROM public.tb_cron_jobs WHERE endpoint_url='https://business.roadrunners.run/teams/mail-worker.cfm'",{}, {datasource='runner_dba'});
if(p.version[1]!=1||f.n[1]!=0||j.recordCount!=1||j.ativo[1])throw(type='Teams.Test',message='Instalação diferente da esperada');
writeOutput('TEAMS_SOURCE_PASSED version=1; production_ready=true; fixture_empty=true; email_job_disabled=true');
</cfscript>
