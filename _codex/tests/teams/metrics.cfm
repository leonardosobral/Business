<cfinclude template="native.cfm">
<cfscript>
scenario('Aquisição e retorno observados',function(){
 var f=base();svc.join(athlete,f.a,true);svc.recordReturn(athlete);svc.recordReturn(athlete);
 var stats=svc.workspace(owner,f.a).stats;
 check(stats.new_users+stats.existing_users==1,'Adesões únicas separadas por origem');
 check(stats.retention_eligible==0 && stats.retained_users==0,'Coorte ainda não madura');
 queryExecute("UPDATE rr_teams_test.funnel SET created_at=CURRENT_TIMESTAMP-interval '31 days' WHERE team_id=:team AND event='JOIN'",{team={value=f.a,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'});
 stats=svc.workspace(owner,f.a).stats;check(stats.retention_eligible==1&&stats.retained_users==1,'Retorno após 30 dias medido em eventos reais');
 check(queryExecute("SELECT count(*) n FROM rr_teams_test.funnel WHERE team_id=:team AND event='RETURN'",{team={value=f.a,cfsqltype='cf_sql_bigint'}},{datasource='runner_dba'}).n[1]==1,'Retorno é registrado uma vez ao dia');
});
writeOutput(' TEAMS_METRICS_PASSED ' & checks);
</cfscript>
