<cfprocessingdirective pageencoding="utf-8"><cfsetting showdebugoutput="false" requesttimeout="50">
<cfscript>
function teamsWorkerResponse(required numeric status,required struct payload){cfheader(statuscode=status);cfheader(name='Cache-Control',value='no-store');cfcontent(type='application/json; charset=utf-8',reset=true);writeOutput(serializeJSON(payload));abort;}
if(CGI.request_method!='POST'){cfheader(name='Allow',value='POST');teamsWorkerResponse(405,{success=false,status='method_not_allowed'});}
secret=structKeyExists(APPLICATION,'cronJobs')&&structKeyExists(APPLICATION.cronJobs,'runnerToken')?APPLICATION.cronJobs.runnerToken & '':'';
requestData=getHTTPRequestData();provided=structKeyExists(requestData.headers,'Authorization')?requestData.headers.Authorization & '':'';
if(len(secret)<20||!createObject('java','java.security.MessageDigest').isEqual(charsetDecode('Bearer ' & secret,'UTF-8'),charsetDecode(provided,'UTF-8')))teamsWorkerResponse(401,{success=false,status='unauthorized'});
try{
 raw=toString(requestData.content);if(len(raw)>1000||!isJSON(raw))throw(type='Teams.Validation',message='JSON inválido.');input=deserializeJSON(raw);if(!isStruct(input))throw(type='Teams.Validation',message='Objeto esperado.');
 for(key in input)if(!listFind('limit,dryRun',key))throw(type='Teams.Validation',message='Campo inválido.');
 mailLimit=structKeyExists(input,'limit')?input.limit:10;dryRun=structKeyExists(input,'dryRun')?input.dryRun:true;
 if(!isSimpleValue(mailLimit)||!isNumeric(mailLimit)||!isSimpleValue(dryRun)||!isBoolean(dryRun))throw(type='Teams.Validation',message='Parâmetros inválidos.');
 teamsWorkerResponse(200,{success=true,data=new services.teams.Mailer().run(mailLimit,dryRun)});
}catch(Teams.Validation invalid){teamsWorkerResponse(400,{success=false,status='invalid_request'});}
catch(any failed){writeLog(file='teams-mail',type='error',text='worker_failed type=' & failed.type);teamsWorkerResponse(500,{success=false,status='execution_error'});}
</cfscript>
