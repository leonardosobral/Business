<!--- Native multipart upload; production validation/moves/cleanup, no campaign SQL. --->
<cfif NOT structKeyExists(REQUEST,"bannerImageTestAuthorized") OR NOT REQUEST.bannerImageTestAuthorized OR CGI.request_method NEQ 'POST'><cfheader statuscode="404"/><cfabort/></cfif>
<cfinclude template="#VARIABLES.bannerImageTestHelper#"/>
<cfscript>
scratch=getTempDirectory() & 'banner-upload-regression-' & lCase(replace(createUUID(),'-','','all'));
directoryCreate(scratch); directoryCreate(scratch & '/public');
// Generated fixtures stay outside the webroot. Relative paths also work on Adobe CF.
relativeScratch=repeatString('../',listLen(getDirectoryFromPath(getCurrentTemplatePath()),'/')) & mid(scratch,2,len(scratch));
checks=0; failures=[];
function check(required boolean condition,required string label) { checks++; if(!arguments.condition) arrayAppend(failures,arguments.label); }
try {
    source=fileRead(expandPath(VARIABLES.bannerImageTestBackend));
    functions=replace(left(source,find('</cfscript>',source)+10),'CGI','REQUEST.testCgi','all');
    REQUEST.testCgi={https=structKeyExists(URL,'insecure')?'off':'on',server_port=structKeyExists(URL,'insecure')?80:443,http_host='business.roadrunners.run'};
    fileWrite(scratch & '/functions.cfm',functions); include relativeScratch & '/functions.cfm';
    start=find('<cfif len(trim(FORM.acao & ""))>',source);
    finish=find('<cfif VARIABLES.bannerManagementApiReady>',source,start);
    if(!start || finish LTE start) throw(message='Upload fixture could not locate production save action');
    action=mid(source,start,finish-start);
    // Replace only SQL and redirect. cffile upload, parser, all guards and cleanup are real.
    action=reReplace(action,'(?s)<cfquery name="qBannerManagementCurrentAssets".*?</cfquery>','<cfthrow message="Unexpected edit query in new-upload fixture"/>');
    action=reReplace(action,'(?s)<cfquery name="qBannerManagementSave".*?</cfquery>','<cfset REQUEST.nativeSaveReached=true/><cfset REQUEST.nativeSavedDimensions=[VARIABLES.bannerLargura,VARIABLES.bannerAltura,VARIABLES.bannerMobileLargura,VARIABLES.bannerMobileAltura]/><cfset REQUEST.nativeSavedUrls=[VARIABLES.bannerDesktopAssetPath,VARIABLES.bannerMobileAssetPath]/>');
    action=replace(action,'<cflocation addtoken="false" url="/portal/banners/?view=house&amp;sucesso=salvo"/>','<cfset REQUEST.nativeRedirectReached=true/>');
    fileWrite(scratch & '/action.cfm',action);
    VARIABLES.bannerManagementIsAdmin=!structKeyExists(URL,'notadmin');
    VARIABLES.bannerManagementActorId=123; VARIABLES.bannerManagementApiReady=true;
    VARIABLES.bannerManagementCsrf='fixture-token'; VARIABLES.bannerUploadDiskPath=scratch & '/public/';
    VARIABLES.bannerUploadWebRoot='/portal/banners/assets/'; VARIABLES.bannerOwnerAccountId=1;
    VARIABLES.bannerPlacementKey='rr-sidebar-banner-300x250'; VARIABLES.bannerManagementAlert={type='',message=''};
    REQUEST.nativeSaveReached=false; REQUEST.nativeRedirectReached=false;
    savecontent variable='ignoredOutput' { include relativeScratch & '/action.cfm'; }
    if(structKeyExists(URL,'invalid')) {
        check(!REQUEST.nativeSaveReached && VARIABLES.bannerManagementAlert.type EQ 'danger','invalid image never reaches campaign persistence');
        check(find('Imagem mobile:',VARIABLES.bannerManagementAlert.message)>0,'image error points to the failing mobile field');
        check(!find('URLs HTTPS',VARIABLES.bannerManagementAlert.message),'upload rejection does not produce misleading HTTPS error');
        check(!arrayLen(directoryList(scratch & '/public',false,'path')),'partially moved desktop file removed after mobile rejection');
    } else if(structKeyExists(URL,'insecure')) {
        check(!REQUEST.nativeSaveReached && find('URLs HTTPS',VARIABLES.bannerManagementAlert.message)>0,'successful uploads still require public HTTPS URLs');
        check(!arrayLen(directoryList(scratch & '/public',false,'path')),'insecure URLs leave no published files');
    } else if(structKeyExists(URL,'notadmin') || structKeyExists(URL,'csrf')) {
        check(!REQUEST.nativeSaveReached && VARIABLES.bannerManagementAlert.type EQ 'danger','admin/CSRF authorization still rejects the request');
        check(!arrayLen(directoryList(scratch & '/public',false,'path')),'unauthorized request never moves uploaded files');
    } else {
        check(REQUEST.nativeSaveReached && REQUEST.nativeRedirectReached,'valid native multipart JPG reaches canonical save and success redirect');
        if(REQUEST.nativeSaveReached) {
            check(serializeJSON(REQUEST.nativeSavedDimensions) EQ '[1140,451,1140,451]','desktop/mobile use decoded dimensions, not client input');
            check(reFind('^https://business\.roadrunners\.run/portal/banners/assets/banner-[a-z0-9]+\.jpg$',REQUEST.nativeSavedUrls[1]) && reFind('^https://business\.roadrunners\.run/portal/banners/assets/banner-[a-z0-9]+\.jpg$',REQUEST.nativeSavedUrls[2]),'both image URLs are HTTPS with safe generated names');
        }
        check(arrayLen(directoryList(scratch & '/public',false,'path')) EQ 2,'both original JPG uploads are moved successfully');
    }
    if(structKeyExists(VARIABLES,'bannerStagingDirectory') && len(VARIABLES.bannerStagingDirectory)) check(!directoryExists(VARIABLES.bannerStagingDirectory),'private staging removed on success or failure');
} finally { directoryDelete(scratch,true); }
check(!directoryExists(scratch),'fixture assets cleaned without touching real banners');
cfcontent(type='application/json; charset=utf-8',reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures,message=VARIABLES.bannerManagementAlert.message}));
</cfscript>
