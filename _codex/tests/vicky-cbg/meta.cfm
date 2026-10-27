<cfscript>
localMetaWhatsappConfig={};
include '../../../../roadrunners.com.br/config/meta_whatsapp.local.cfm';
cfg=localMetaWhatsappConfig;
if(!structKeyExists(cfg,'systemToken') OR !structKeyExists(cfg,'wabaId'))throw(message='Meta configuration unavailable');
cfhttp(method='get',url='https://graph.facebook.com/' & cfg.graphVersion & '/' & cfg.wabaId & '/message_templates?name=atualize_cbg&fields=name,status,language,components',result='metaLookupHttp',timeout=15){cfhttpparam(type='header',name='Authorization',value='Bearer ' & cfg.systemToken);}
if(val(metaLookupHttp.statusCode) NEQ 200)throw(message='Template lookup HTTP ' & left(replace(metaLookupHttp.statusCode & ' ' & (metaLookupHttp.errorDetail ?: ''),cfg.systemToken,'[redacted]','all'),700));
body=deserializeJSON(metaLookupHttp.fileContent);
for(t in body.data)if(t.name EQ 'atualize_cbg')writeOutput(serializeJSON(t));
if(!arrayLen(body.data))throw(message='Template not found');
writeOutput('VICKY_CBG_META_PASSED');
</cfscript>
