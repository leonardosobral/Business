<cfsetting showdebugoutput="false"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfheader name="X-Robots-Tag" value="noindex, nofollow"/>
<cfheader name="Referrer-Policy" value="no-referrer"/>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfheader name="X-Frame-Options" value="SAMEORIGIN"/>
<cfscript>
studyService=new estudos.includes.StudyAccess().init('runner_dba');
studyActor=structKeyExists(REQUEST,'businessIdentity') && structKeyExists(REQUEST.businessIdentity,'id') ? REQUEST.businessIdentity.id : 0;
if(!structKeyExists(SESSION,'businessStudyCsrf')) SESSION.businessStudyCsrf=lCase(hash(generateSecretKey('AES',256),'SHA-256'));
</cfscript>
