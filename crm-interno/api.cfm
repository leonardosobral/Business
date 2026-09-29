<cfinclude template="../includes/backend/backend_login.cfm">
<cfinclude template="../includes/backend/require_admin_dev.cfm">
<cfinclude template="../includes/backend/require_real_platform_context.cfm">
<cfsetting showdebugoutput="false" requesttimeout="60">
<cfscript>
result={success=false,error='service_unavailable'};status=200;
try{
 if(CGI.REQUEST_METHOD!='POST')throw(type='CRM.Client',message='method_not_allowed');
 if(!structKeyExists(SESSION,'crmInternalCsrf')||!structKeyExists(FORM,'csrf')||compare(FORM.csrf,SESSION.crmInternalCsrf)!=0)throw(type='CRM.Client',message='forbidden');
 if(!structKeyExists(FORM,'payload')||len(FORM.payload)>262144||!isJSON(FORM.payload))throw(type='CRM.Client',message='invalid_payload');
 payload=deserializeJSON(FORM.payload);if(!isStruct(payload)||!structKeyExists(payload,'action')||!structKeyExists(payload,'input')||!isStruct(payload.input))throw(type='CRM.Client',message='invalid_payload');
 result=new services.CrmClient().init(APPLICATION.notificationDispatch).request(payload.action,payload.input,val(qPerfil.id));
 if(!result.success)status=422;
}catch(any e){known=listFind('method_not_allowed,forbidden,invalid_payload',e.message);result={success=false,error=known?e.message:'service_unavailable'};status=e.message=='forbidden'?403:e.message=='method_not_allowed'?405:known?422:503;}
cfcontent(type='application/json; charset=utf-8',reset=true);cfheader(statuscode=status);cfheader(name='Cache-Control',value='no-store');writeOutput(serializeJSON(result));
</cfscript>
