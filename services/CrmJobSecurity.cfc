component output=false {
 public struct function verify(required struct requestData,required string host,required string secret,required string scope){
  var body=toString(requestData.content);var headers=requestData.headers;
  var stamp=structKeyExists(headers,'X-RR-Handoff-Timestamp')?headers['X-RR-Handoff-Timestamp']:'';
  var signature=structKeyExists(headers,'X-RR-Handoff-Signature')?headers['X-RR-Handoff-Signature']:'';
  if(len(body)>8192||!len(secret)||!isDate(stamp)||abs(dateDiff('s',parseDateTime(stamp),now()))>180||!reFindNoCase('^[a-f0-9]{64}$',signature))throw(type='CRM.Worker',message='forbidden');
  var expected=lCase(hmac(stamp & '.' & body,secret,'HmacSHA256'));
  if(!createObject('java','java.security.MessageDigest').isEqual(binaryDecode(expected,'hex'),binaryDecode(signature,'hex'))||!isJSON(body))throw(type='CRM.Worker',message='forbidden');
  var payload=deserializeJSON(body);
  if(!isStruct(payload)||!structKeyExists(payload,'scope')||payload.scope!=scope||!structKeyExists(payload,'environment')||payload.environment!='prod'||!listFindNoCase('business.roadrunners.run',listFirst(host,':')))throw(type='CRM.Worker',message='forbidden');
  return payload;
 }
}
