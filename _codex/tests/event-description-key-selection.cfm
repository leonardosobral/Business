<cfsetting showdebugoutput="false"/>
<cfscript>
headers=getHttpRequestData().headers;
if(!listFind('127.0.0.1,::1',cgi.remote_addr) || (headers['X-Rewrite-Key-Test'] ?: '')!='@@NONCE@@') {cfheader(statuscode=404);abort;}
cfheader(name='Cache-Control',value='no-store');
cases=[
  {name='Dedicated key wins over global environment and global config',config={eventDescriptionApiKey='dedicated-fixture',openAiApiKey='global-fixture'},env='environment-fixture',expected='dedicated-fixture'},
  {name='Dedicated key works without a global key',config={eventDescriptionApiKey='dedicated-fixture'},env='',expected='dedicated-fixture'},
  {name='Empty dedicated key preserves environment fallback',config={eventDescriptionApiKey='  ',openAiApiKey='global-fixture'},env='environment-fixture',expected='environment-fixture'},
  {name='Legacy environment precedence preserved',config={openAiApiKey='global-fixture'},env='environment-fixture',expected='environment-fixture'},
  {name='Legacy config fallback preserved',config={openAiApiKey='global-fixture'},env='',expected='global-fixture'},
  {name='Missing credentials remain empty',config={},env='',expected=''}
];
results=[];failed=0;
for(scenario in cases) {
  VARIABLES.businessLocalConfig=duplicate(scenario.config);
  VARIABLES.rewriteEnvironment=createObject('java','java.util.HashMap').init();
  if(len(scenario.env)) VARIABLES.rewriteEnvironment.put('OPENAI_API_KEY',scenario.env);
  originalConfig=serializeJSON(VARIABLES.businessLocalConfig);
  include 'selection.cfm';
  passed=VARIABLES.rewriteApiKey==scenario.expected && serializeJSON(VARIABLES.businessLocalConfig)==originalConfig;
  if(!passed) failed++;
  arrayAppend(results,{name=scenario.name,passed=passed});
}
cfcontent(type='application/json; charset=utf-8',reset=true);
writeOutput(serializeJSON({ok=failed==0,failed=failed,cases=results}));
</cfscript>
