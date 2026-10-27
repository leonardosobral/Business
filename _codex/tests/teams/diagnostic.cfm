<cfscript>
report={};
report.user=queryExecute('SELECT current_user AS username, current_database() AS db',{}, {datasource='runner_dba'}).username[1];
transaction {
 try {cfquery(datasource='runner_dba'){writeOutput('CREATE SCHEMA rr_teams_test_diag_' & lCase(left(replace(createUUID(),'-','','all'),12)));}report.single_schema=true;}catch(any e){report.single_schema=false;report.message=e.message;report.detail=e.detail;}
 transaction action='rollback';
}
writeOutput('TEAMS_DIAGNOSTIC_PASSED ' & serializeJSON(report));
</cfscript>
