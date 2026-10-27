<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false" requesttimeout="50">
<cfscript>
function closeResponse(required numeric status,required struct payload){cfheader(statuscode=arguments.status);cfheader(name='Cache-Control',value='no-store');cfheader(name='X-Content-Type-Options',value='nosniff');cfcontent(type='application/json; charset=utf-8',reset=true);writeOutput(serializeJSON(arguments.payload));abort;}
if(CGI.request_method NEQ 'POST'){cfheader(name='Allow',value='POST');closeResponse(405,{success=false,status='method_not_allowed'});}
service=new services.HelpdeskAutoClose();
secret=structKeyExists(APPLICATION,'cronJobs') AND structKeyExists(APPLICATION.cronJobs,'runnerToken')?APPLICATION.cronJobs.runnerToken&'':'';
requestData=getHTTPRequestData();
if(!service.authorized(CGI.request_method,requestData.headers,secret))closeResponse(401,{success=false,status='unauthorized'});
try{
  input=service.input(toString(requestData.content));
  closeResponse(200,service.run(input.limit,input.dryRun));
}catch(HelpdeskAutoClose.InvalidRequest invalid){closeResponse(400,{success=false,status='invalid_request'});}
catch(any failed){writeLog(file='helpdesk-auto-close',type='error',text='auto_close_failed type=' & left(reReplace(failed.type,'[^a-zA-Z0-9_.-]','','all'),100));closeResponse(500,{success=false,status='execution_error',message='Não foi possível concluir o encerramento automático. O lote foi revertido.'});}
</cfscript>
