component output=false {
 private struct function config(){
  var pagarMeLocalConfig={};
  if(!fileExists(expandPath('/config/pagarme.local.cfm')))throw(type='CRM.Commerce',message='source_unavailable');
  include '/config/pagarme.local.cfm';
  if(!isStruct(pagarMeLocalConfig) || !structKeyExists(pagarMeLocalConfig,'enabled') || pagarMeLocalConfig.enabled!=true || !structKeyExists(pagarMeLocalConfig,'mode') || pagarMeLocalConfig.mode!='production' || !structKeyExists(pagarMeLocalConfig,'secretKey') || !len(trim(pagarMeLocalConfig.secretKey & '')))throw(type='CRM.Commerce',message='source_unavailable');
  return {secretKey=pagarMeLocalConfig.secretKey};
 }
 private any function field(required any item,required string name){
  return isStruct(item)&&structKeyExists(item,name)&&isSimpleValue(item[name])?item[name]:'';
 }
 public struct function sanitizeOrder(required struct raw){
  var result={id=left(field(raw,'id') & '',100),code=left(field(raw,'code') & '',100),amount=field(raw,'amount'),currency=left(field(raw,'currency') & '',3),status=left(field(raw,'status') & '',40),updated_at=left(field(raw,'updated_at') & '',80),items=[],charges=[]};
  if(structKeyExists(raw,'items')&&isArray(raw.items))for(var n=1;n<=min(2,arrayLen(raw.items));n++)arrayAppend(result.items,{code=left(field(raw.items[n],'code') & '',80),amount=field(raw.items[n],'amount'),quantity=field(raw.items[n],'quantity')});
  if(structKeyExists(raw,'charges')&&isArray(raw.charges))for(var m=1;m<=min(2,arrayLen(raw.charges));m++){
   var charge={id=left(field(raw.charges[m],'id') & '',100),currency=left(field(raw.charges[m],'currency') & '',3),status=left(field(raw.charges[m],'status') & '',40),paid_amount=field(raw.charges[m],'paid_amount'),paid_at=left(field(raw.charges[m],'paid_at') & '',80),updated_at=left(field(raw.charges[m],'updated_at') & '',80)};
   if(isStruct(raw.charges[m])&&structKeyExists(raw.charges[m],'canceled_amount'))charge.canceled_amount=field(raw.charges[m],'canceled_amount');
   arrayAppend(result.charges,charge);
  }
  return result;
 }
 public struct function fetchOrder(required string orderId){
  if(!reFind('^or_[A-Za-z0-9]{8,80}$',orderId))throw(type='CRM.Commerce',message='invalid_payload');
  var settings=config();
  var response={};
  try {
   cfhttp(method='get',url='https://api.pagar.me/core/v5/orders/' & orderId,result='response',timeout=15,throwOnError=false,redirect=false){
    cfhttpparam(type='header',name='Authorization',value='Basic ' & toBase64(settings.secretKey & ':'));
    cfhttpparam(type='header',name='Accept',value='application/json');
   }
   if(!structKeyExists(response,'statusCode')||val(listFirst(response.statusCode,' '))!=200||!structKeyExists(response,'fileContent')||!isJSON(response.fileContent))throw(type='CRM.Commerce',message='source_unavailable');
   var raw=deserializeJSON(response.fileContent);
   if(!isStruct(raw))throw(type='CRM.Commerce',message='source_unavailable');
   return sanitizeOrder(raw);
  } catch(any ignored){throw(type='CRM.Commerce',message='source_unavailable');}
 }
 public struct function listOrders(required string fromDay,required string toDay,required numeric page,required numeric limit){
  if(!reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}$',fromDay)||!reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}$',toDay)||!isValid('integer',page)||page<1||page>100000||!isValid('integer',limit)||limit<1||limit>30)throw(type='CRM.Commerce',message='invalid_payload');
  var settings=config();var response={};
  try{
   cfhttp(method='get',url='https://api.pagar.me/core/v5/orders?created_since=' & fromDay & '&created_until=' & toDay & '&page=' & page & '&size=' & limit,result='response',timeout=15,throwOnError=false,redirect=false){
    cfhttpparam(type='header',name='Authorization',value='Basic ' & toBase64(settings.secretKey & ':'));
    cfhttpparam(type='header',name='Accept',value='application/json');
   }
   if(!structKeyExists(response,'statusCode')||val(listFirst(response.statusCode,' '))!=200||!isJSON(response.fileContent))throw(type='CRM.Commerce',message='source_unavailable');
   var raw=deserializeJSON(response.fileContent);
   if(!isStruct(raw)||!structKeyExists(raw,'data')||!isArray(raw.data)||arrayLen(raw.data)>limit||!structKeyExists(raw,'paging')||!isStruct(raw.paging)||!structKeyExists(raw.paging,'total')||!isValid('integer',raw.paging.total)||val(raw.paging.total)<0)throw(type='CRM.Commerce',message='source_unavailable');
   var ids=[];var seen={};
   for(var order in raw.data){
    if(!isStruct(order)||!structKeyExists(order,'id')||!reFind('^or_[A-Za-z0-9]{8,80}$',order.id & '')||structKeyExists(seen,order.id)||!structKeyExists(order,'created_at')||left(order.created_at & '',10)<fromDay||left(order.created_at & '',10)>toDay)throw(type='CRM.Commerce',message='source_unavailable');
    seen[order.id]=true;arrayAppend(ids,order.id);
   }
   return {ids=ids,total=val(raw.paging.total),page=page,limit=limit};
  }catch(any ignored){throw(type='CRM.Commerce',message='source_unavailable');}
 }
}
