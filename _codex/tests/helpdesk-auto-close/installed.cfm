<cfscript>
service=createObject('component','services' & '.HelpdeskAutoClose');
preview=service.run(100,true);writeOutput('PREVIEW ' & serializeJSON(preview));
businessLocalConfig={};include '../../../config/business.local.cfm';
env=createObject('java','java.lang.System').getenv();
secret=structKeyExists(env,'RR_BUSINESS_CRON_RUNNER_TOKEN')?env['RR_BUSINESS_CRON_RUNNER_TOKEN']:(businessLocalConfig.cronRunnerToken ?: '');
cfhttp(method='post',url='https://business.roadrunners.run/api/helpdesk/auto-close.cfm',result='dryResponse',timeout=20){
 cfhttpparam(type='header',name='Authorization',value='Bearer ' & secret);
 cfhttpparam(type='header',name='User-Agent',value='RoadRunners-Business-Cron/1.0');
 cfhttpparam(type='header',name='Content-Type',value='application/json');
 cfhttpparam(type='body',value='{"dryRun":true,"limit":100}');
}
if(val(dryResponse.statusCode) NEQ 200 OR !isJSON(dryResponse.fileContent))throw(message='Installed authenticated dry run failed: HTTP ' & left(dryResponse.statusCode,40));
response=deserializeJSON(dryResponse.fileContent);if(response.status NEQ 'dry_run' OR response.closed NEQ 0)throw(message='Installed dry run changed data');
writeOutput('HTTP_DRY_RUN ' & serializeJSON(response));
writeOutput('HELPDESK_CLOSE_INSTALLED_PASSED');
</cfscript>
