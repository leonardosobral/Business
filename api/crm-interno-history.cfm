<cfsetting showdebugoutput="false" requesttimeout="110">
<cfscript>
result={success=false,error='service_unavailable'};status=200;
try{
 if(CGI.REQUEST_METHOD!='POST')throw(type='CRM.Worker',message='method_not_allowed');
 new services.CrmJobSecurity().verify(getHttpRequestData(),CGI.HTTP_HOST,APPLICATION.cronJobs.runnerToken,'crm.history.worker');
 result=new services.CrmClient().init(APPLICATION.notificationDispatch).request('audiences.capture',{limit=5},0,true);
 if(!result.success)status=503;
}catch(any e){status=e.message=='forbidden'?403:e.message=='method_not_allowed'?405:503;result={success=false,error=status==503?'service_unavailable':e.message};}
cfcontent(type='application/json; charset=utf-8',reset=true);cfheader(statuscode=status);cfheader(name='Cache-Control',value='no-store');writeOutput(serializeJSON(result));
</cfscript>
