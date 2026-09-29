<cfsetting showdebugoutput="false" requesttimeout="110">
<cfscript>
result={success=false,error='service_unavailable'};status=200;
try{
 if(CGI.REQUEST_METHOD!='POST')throw(type='CRM.Worker',message='method_not_allowed');
 new services.CrmJobSecurity().verify(getHttpRequestData(),CGI.HTTP_HOST,APPLICATION.cronJobs.runnerToken,'crm.email.worker');
 crmEmailClient=new services.CrmClient().init(APPLICATION.notificationDispatch);claim=crmEmailClient.request('email.claim',{},0,true);
 if(!claim.success)throw(type='CRM.Worker',message='service_unavailable');
 processed=0;
 for(item in claim.data.items){
  auth=crmEmailClient.request('email.authorize',{id=item.id,lease_token=item.lease_token},0,true);
  if(!auth.success||!auth.data.allowed)continue;
  d=auth.data;outcome={status='unknown',error_code='transport_unconfirmed'};
  // Only the reviewed, leased recipient reaches the existing mail transport.
  try{
   html='<h1>' & encodeForHTML(d.content.title) & '</h1><p style="white-space:pre-wrap">' & encodeForHTML(d.content.body) & '</p><p><a href="' & encodeForHTMLAttribute(d.click_url) & '">' & encodeForHTML(d.content.button) & '</a></p><hr><p><a href="' & encodeForHTMLAttribute(d.unsubscribe_url) & '">Cancelar comunicações comerciais por e-mail</a></p>';
   html=replace(html,'[','&##91;','all');
   safeName=reReplace(d.name,'[\r\n<>"' & chr(39) & ']','','all');
   sent=new emailmkt.EmailSenderService().enviarEmail(reReplace(d.content.title,'[\r\n]',' ','all'),html,d.email,safeName);
   if(sent=='OK')outcome={status='accepted',provider_id='legacy_email_transport'};
  }catch(any deliveryUnconfirmed){}
  // An unknown result is retained for inspection and never automatically retried.
  crmEmailClient.request('email.complete',{id=item.id,lease_token=item.lease_token,result=outcome},0,true);processed++;
 }
 result={success=true,processed=processed};
}catch(any e){status=e.message=='forbidden'?403:e.message=='method_not_allowed'?405:503;result={success=false,error=status==503?'service_unavailable':e.message};}
cfcontent(type='application/json; charset=utf-8',reset=true);cfheader(statuscode=status);cfheader(name='Cache-Control',value='no-store');writeOutput(serializeJSON(result));
</cfscript>
