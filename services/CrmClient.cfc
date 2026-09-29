component output=false {
 public any function init(struct config={}){variables.config=config;return this;}
 public struct function request(required string action,struct input={},numeric actorId=0,boolean worker=false){
  if(!structKeyExists(variables.config,'url')||!structKeyExists(variables.config,'secret')||!len(variables.config.secret)||compareNoCase(variables.config.secret,hash('RoadRunners::handoff::roadrunners.run::v1','SHA-256'))==0)throw(type='CRM.Client',message='service_unavailable');
  var uri=createObject('java','java.net.URI').init(variables.config.url);var host=lCase(uri.getHost());
  // The production CRM never falls back to a test environment sharing the database.
  if(uri.getScheme()!='https'||!listFind('roadrunners.run,www.roadrunners.run',host))throw(type='CRM.Client',message='service_unavailable');
  var endpoint='https://' & host & '/api/crm-interno/' & (worker?'worker.cfm':'admin.cfm');
  var body=serializeJSON({scope=worker?'crm.worker':'crm.admin',environment='prod',action=action,input=input,actor_id=actorId,impersonating=false});var stamp=dateTimeFormat(now(),'yyyy-mm-dd HH:nn:ss');
  var req=new http(method='post',url=endpoint,timeout=45,throwOnError=false,redirect=false);
  req.addParam(type='header',name='Content-Type',value='application/json; charset=utf-8');
  req.addParam(type='header',name='X-RR-Handoff-Timestamp',value=stamp);
  req.addParam(type='header',name='X-RR-Handoff-Signature',value=lCase(hmac(stamp & '.' & body,variables.config.secret,'HmacSHA256')));
  req.addParam(type='body',value=body);var response=req.send().getPrefix();
  if(!structKeyExists(response,'fileContent')||!isJSON(toString(response.fileContent)))throw(type='CRM.Client',message='service_unavailable');
  var data=deserializeJSON(toString(response.fileContent));if(!isStruct(data)||!structKeyExists(data,'success'))throw(type='CRM.Client',message='service_unavailable');return data;
 }
}
