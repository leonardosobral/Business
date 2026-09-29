<cfsetting showdebugoutput="false" requesttimeout="110">
<cfscript>
result={success=false,error='service_unavailable'};status=200;
try{
 if(CGI.REQUEST_METHOD!='POST')throw(type='CRM.Worker',message='method_not_allowed');
 new services.CrmJobSecurity().verify(getHttpRequestData(),CGI.HTTP_HOST,APPLICATION.cronJobs.runnerToken,'crm.commerce.worker');
 crmClient=new services.CrmClient().init(APPLICATION.notificationDispatch);
 due=crmClient.request('programs.reconcile',{phase='list',limit=3},0,true);
 if(!due.success)throw(type='CRM.Worker',message='service_unavailable');
 commerce=new services.CrmCommerceService();
 processed=0;pending=0;failed=0;
 for(item in due.data.items){
  if(!structKeyExists(item,'order_id')||!reFind('^or_[A-Za-z0-9]{8,80}$',item.order_id)){failed++;continue;}
  try{
   order=commerce.fetchOrder(item.order_id);
   applied=crmClient.request('programs.reconcile',{phase='apply',order_id=item.order_id,order=order},0,true);
   if(applied.success)processed++;else pending++;
  }catch(any providerError){
   failed++;
   try{crmClient.request('programs.reconcile',{phase='unavailable',order_id=item.order_id},0,true);}catch(any ignored){}
  }
 }
 history={status=arrayLen(due.data.items)?'deferred':'unavailable',scanned=0,accepted=0,pending=0};
 if(!arrayLen(due.data.items)){
 try{
  next=crmClient.request('programs.backfill',{phase='next'},0,true);
  if(next.success&&next.data.available){
   listed=commerce.listOrders(next.data.from_day,next.data.to_day,next.data.page,next.data.limit);
   snapshots=[];
   for(orderId in listed.ids)arrayAppend(snapshots,commerce.fetchOrder(orderId));
   appliedHistory=crmClient.request('programs.backfill',{phase='apply',from_day=next.data.from_day,to_day=next.data.to_day,page=next.data.page,limit=next.data.limit,listed=listed,orders=snapshots},0,true);
   if(!appliedHistory.success)throw(type='CRM.Worker',message='service_unavailable');
   history={status=appliedHistory.data.complete?'complete_window':'running',scanned=appliedHistory.data.scanned,accepted=appliedHistory.data.accepted,pending=appliedHistory.data.pending};
  }else if(next.success)history.status='idle';
  else throw(type='CRM.Worker',message='service_unavailable');
 }catch(any historyError){history.status='retry';}
 }
 result={success=true,data={checked=processed,pending=pending,failed=failed,selected=arrayLen(due.data.items),historical=history}};
}catch(any e){status=e.message=='forbidden'?403:e.message=='method_not_allowed'?405:503;result={success=false,error=status==503?'service_unavailable':e.message};}
cfcontent(type='application/json; charset=utf-8',reset=true);cfheader(statuscode=status);cfheader(name='Cache-Control',value='no-store');writeOutput(serializeJSON(result));
</cfscript>
