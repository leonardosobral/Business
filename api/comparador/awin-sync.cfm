<cfprocessingdirective pageencoding="utf-8">
<cfsetting showdebugoutput="false" requesttimeout="120">
<cfcontent type="application/json; charset=utf-8">
<cfheader name="Cache-Control" value="no-store">
<cfheader name="X-Content-Type-Options" value="nosniff">
<cfscript>
if(CGI.request_method!='POST'){cfheader(statuscode=405);cfheader(name='Allow',value='POST');writeOutput('{"success":false,"status":"method_not_allowed"}');abort;}
secret='';headers=getHTTPRequestData().headers;
if(structKeyExists(APPLICATION,'cronJobs') AND isStruct(APPLICATION.cronJobs) AND structKeyExists(APPLICATION.cronJobs,'secrets') AND isStruct(APPLICATION.cronJobs.secrets) AND structKeyExists(APPLICATION.cronJobs.secrets,'business_internal'))secret=trim(APPLICATION.cronJobs.secrets.business_internal & '');
if(!len(secret) OR !structKeyExists(headers,'Authorization') OR hash(trim(headers.Authorization),'SHA-256')!=hash('Bearer ' & secret,'SHA-256')){cfheader(statuscode=401);writeOutput('{"success":false,"status":"unauthorized"}');abort;}
try {
 result=new services.ComparadorAwinPublicationService().synchronizeScheduled();
 feedResult={status='failed'};
 try {feedResult=new services.ComparadorAwinFeedService().synchronizeScheduled(new services.ComparadorAwinService().refreshScheduled());}catch(any feedError){feedResult={status='failed'};}
 if(listFind('failed,partial',feedResult.status))cfheader(statuscode=503);
 writeOutput(serializeJSON({success=!listFind('failed,partial',feedResult.status),status=listFind('failed,partial',feedResult.status)?'feed_incomplete':'ok',offers=result.offers,campaigns=result.campaigns,pending=result.pending,outsideCatalog=result.outsideCatalog,newReviewCount=result.newReviewCount,newReviewCampaignIds=result.newReviewCampaignIds,new_items=result.newReviewCount,feed=feedResult}));
}catch(any e){cfheader(statuscode=503);writeOutput('{"success":false,"status":"sync_failed","message":"A sincronização falhou. A publicação anterior foi preservada."}');}
</cfscript>
