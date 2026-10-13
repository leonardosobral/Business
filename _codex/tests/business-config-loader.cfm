<cfif NOT listFind("127.0.0.1,::1",CGI.REMOTE_ADDR) OR CGI.REQUEST_METHOD NEQ "GET"><cfheader statuscode="404"/><cfabort/></cfif>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfscript>
// Execute the actual startup loader with synthetic files, never real credentials.
source=fileRead(structKeyExists(URL,"candidate") && URL.candidate EQ "1" ? getDirectoryFromPath(getCurrentTemplatePath()) & "CandidateApplication.cfc" : expandPath("/Application.cfc"),"utf-8");
start=find('<cfset var businessLocalConfig = {}/>',source);
finish=find('<cfset var accountDelegationSetting',source,start);
if (!start || !finish) throw(message="Bloco de carregamento da configuração não encontrado.");
loader=mid(source,start,finish-start);
loader=reReplace(loader,'<cfset var businessLocalConfigPath = [^\r\n]+','<cfset var businessLocalConfigPath = arguments.fixturePath/>');
loader=replace(loader,'template="config/business.local.cfm"','template="' & chr(35) & 'arguments.fixtureTemplate' & chr(35) & '"');
testFolder="__config_fixture_" & replace(createUUID(),"-","","all");
testDirectory=getDirectoryFromPath(getCurrentTemplatePath()) & testFolder;
directoryCreate(testDirectory);
fileWrite(testDirectory & "/runner.cfm",'<cffunction name="loadStartupFixture" output="false" returntype="struct"><cfargument name="fixturePath" type="string" required="true"/><cfargument name="fixtureTemplate" type="string" required="true"/>' & loader & '<cfreturn duplicate(businessLocalConfig)/></cffunction>',"utf-8");
testTemplate="./" & testFolder & "/runner.cfm";
include testTemplate;
failures=[];tests=0;
function expectConfig(required boolean condition,required string label) {
    tests++;
    if (!arguments.condition) arrayAppend(failures,arguments.label);
}
try {
    structDelete(VARIABLES,"businessLocalConfig");
    fileWrite(testDirectory & "/overlay.cfm",'<cfscript>businessLocalConfig={specialGroupsSecret="fixture-special",specialGroupsUrl="https://example.org/api/chat/admin/special-groups.cfm",googleMeetRoom="fixture-room",accountDelegationEnabled=false};VARIABLES.businessLocalConfig.accountDelegationEnabled=true;</cfscript>',"utf-8");
    loaded=loadStartupFixture(testDirectory & "/overlay.cfm","overlay.cfm");
    expectConfig(structKeyExists(loaded,"specialGroupsSecret") && loaded.specialGroupsSecret EQ "fixture-special","Local settings survive an explicit VARIABLES overlay (signature regression)");
    expectConfig(structKeyExists(loaded,"googleMeetRoom") && loaded.googleMeetRoom EQ "fixture-room","Unrelated local settings are retained");
    expectConfig(structKeyExists(loaded,"accountDelegationEnabled") && loaded.accountDelegationEnabled,"Explicit account-delegation overlay is retained");

    fileWrite(testDirectory & "/variables-only.cfm",'<cfscript>VARIABLES.businessLocalConfig={specialGroupsSecret="variables-special",specialGroupsUrl="https://example.org/variables"};</cfscript>',"utf-8");
    loaded=loadStartupFixture(testDirectory & "/variables-only.cfm","variables-only.cfm");
    expectConfig(structKeyExists(loaded,"specialGroupsSecret") && loaded.specialGroupsSecret EQ "variables-special","Legacy VARIABLES-only config remains supported");

    VARIABLES.businessLocalConfig={specialGroupsSecret="stale-secret",accountDelegationEnabled=true};
    fileWrite(testDirectory & "/fresh-local.cfm",'<cfscript>businessLocalConfig={specialGroupsSecret="fresh-special",googleMeetRoom="fresh-room"};</cfscript>',"utf-8");
    loaded=loadStartupFixture(testDirectory & "/fresh-local.cfm","fresh-local.cfm");
    expectConfig(structKeyExists(loaded,"specialGroupsSecret") && loaded.specialGroupsSecret EQ "fresh-special","An old component-scope config cannot override fresh local settings");
    expectConfig(!structKeyExists(loaded,"accountDelegationEnabled"),"An absent setting is not resurrected from component state");
    loaded=loadStartupFixture(testDirectory & "/missing.cfm","missing.cfm");
    expectConfig(structCount(loaded) EQ 0,"Missing config stays empty rather than inheriting old settings");
} finally {
    directoryDelete(testDirectory,true);
}
cfcontent(type="application/json; charset=utf-8",reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),tests=tests,failures=failures}));
</cfscript>
