<cfscript>
if(createObject('java','java.lang.System').getenv('RUNNERHUB_OFFLINE_CFML_TESTS')!='1') abort;
root=getDirectoryFromPath(getCurrentTemplatePath()) & '../../';
scratch=getTempDirectory() & 'paid-banner-boundary-' & createUUID();directoryCreate(scratch);
try {
 REQUEST.testSession={};REQUEST.testMethod='GET';
 VARIABLES.adsAccessAccountId=0;VARIABLES.adsAccessActorId=912;VARIABLES.adsAccessCanManageCampaign=false;VARIABLES.adsAccessCanReviewCampaign=false;VARIABLES.adsAccessCanView=false;
 source=fileRead(root & 'portal/includes/paid_banner_backend.cfm');
 source=replace(source,'template="','template="' & root & 'portal/includes/','all');
 source=replace(source,'SESSION.','REQUEST.testSession.','all');source=replace(source,"structKeyExists(SESSION,","structKeyExists(REQUEST.testSession,",'all');source=replace(source,"structDelete(SESSION,","structDelete(REQUEST.testSession,",'all');
 source=replace(source,'scope="session"','name="paid-banner-boundary-test"','all');source=replace(source,'CGI.request_method','REQUEST.testMethod','all');
 fileWrite(scratch & '/backend.cfm',source);include scratch & '/backend.cfm';
 if(VARIABLES.paidBannerReady OR arrayLen(VARIABLES.paidBannerRows))throw(message='Unauthorized workspace queried data');
 writeOutput('PASS: production backend compiles; unauthorized workspace stays closed without DB access' & chr(10));
 firstToken=VARIABLES.paidBannerCsrf;VARIABLES.adsAccessAccountId=2;
 include scratch & '/backend.cfm';
 if(VARIABLES.paidBannerCsrf==firstToken)throw(message='CSRF token did not change for account');
 writeOutput('PASS: CSRF token is bound to selected account' & chr(10));
} finally {directoryDelete(scratch,true);}
</cfscript>
