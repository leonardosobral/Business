<cfsetting showdebugoutput="false"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfscript>
cfcontent(type="application/json; charset=utf-8",reset=true);cfheader(name="Cache-Control",value="no-store");
if(CGI.request_method NEQ "GET"){cfheader(statuscode=405);cfheader(name="Allow",value="GET");writeOutput('{}');abort;}
try{
 manager=new services.YoutubeChannelManager(val(qPerfil.id));
 items=manager.search(URL.lookup ?: "",URL.q ?: "");
 // Ordered structs preserve lowercase keys in the wire contract.
 response=structNew('ordered');response['items']=[];
 for(item in items){wire=structNew('ordered');for(key in item)wire[lCase(key)]=item[key];arrayAppend(response['items'],wire);}
 writeOutput(serializeJSON(response));
}catch(YoutubeChannel.Validation e){cfheader(statuscode=400);writeOutput('{}');}
catch(any e){cfheader(statuscode=500);writeOutput('{}');}
</cfscript>
