component output="false" {
    // Recognized messages are used only for stable grouping; admin evidence is preserved separately.
    public string function safeExportText(required string value) {
        var text=trim(arguments.value);
        if(reFind("^(Variable [A-Z_][A-Z0-9_\.]{0,80} is undefined\.|Element [A-Z_][A-Z0-9_\.]{0,80} is undefined in [A-Z_][A-Z0-9_\.]{0,80}\.|Error Executing Database Query\.|The request has exceeded the allowable time limit\.)$",text)) return text;
        return "";
    }
    private string function field(required string html, required string label) {
        var pattern='<td[^>]*>\s*(?:<[^>]+>\s*)*' & arguments.label & '\s*(?:</[^>]+>\s*)*</td>\s*<td[^>]*>([\s\S]*?)</td>';
        var match=reFindNoCase(pattern,arguments.html,1,true);
        if(arrayLen(match.pos)<2 || match.pos[2]==0) return "";
        return trim(reReplace(mid(arguments.html,match.pos[2],match.len[2]),'<[^>]*>',' ','all'));
    }
    public struct function evidence(required struct log) {
        var raw=arguments.log.log_item_id ?: "";
        var result={path="",message=""};
        if((arguments.log.log_item ?: "")=="404") {
            result.path=reReplaceNoCase(trim(raw),"^An error occurred:\s*","","one");
            result.path=reReplaceNoCase(result.path,"^https?://[^/\s]+(?=/)","","one");
        } else {
            result.path=field(raw,"TEMPLATE");
            result.message=field(raw,"MESSAGE");
        }
        return result;
    }
    public struct function normalize(required struct log) {
        var raw=left(arguments.log.log_item_id ?: "",200000);
        var site=left(arguments.log.site ?: "",32);
        var item=arguments.log.log_item ?: "erro";
        var result={signatureVersion=1,suggestedCategory="unclassified",title="Erro a classificar",path="",technicalMessage="",confidence="individual"};
        var identity="log:" & arguments.log.id_log;
        if(item=="404") {
            // Only accept the actual logged URL, never a URL embedded later in a dump.
            var requestPath=trim(raw);
            if(left(requestPath,1)=="/")requestPath="https://local.invalid" & requestPath;
            var urlMatch=reFindNoCase('^(?:An error occurred:\s*)?https?://[^/\s<>]+(/[^\s<>?"' & "'" & ']*)',requestPath,1,true);
            if(arrayLen(urlMatch.pos)>1 && urlMatch.pos[2]>0) {
                var path=mid(requestPath,urlMatch.pos[2],urlMatch.len[2]);
                if(reFind('^/[a-zA-Z0-9/_.-]{0,300}$',path)) {
                    path=reReplace(path,'/[0-9]+(?=/|$)','/{id}','all');
                    path=reReplace(path,'/[a-zA-Z0-9_-]{24,}(?=/|$)','/{valor}','all');
                    identity="404:" & path;result.confidence="path";

                }
            }
            result.suggestedCategory="not_found";result.title="Página não encontrada";
        } else {
            var message=safeExportText(field(raw,"MESSAGE"));
            var type=lCase(field(raw,"TYPE"));
            var template=field(raw,"TEMPLATE");
            var sqlState=uCase(field(raw,"SQLSTATE"));
            var dbDetail=field(raw,"DETAIL");
            var identifiableDatabase=type!="database" || (reFind("^[0-9A-Z]{5}$",sqlState) && len(dbDetail));
            if(reFind('^/var/www/[a-zA-Z0-9._-]+/[a-zA-Z0-9/_.-]+\.(cfm|cfc)$',template)) template=reReplace(template,'^/var/www/[^/]+','');
            if(!reFind('^/[a-zA-Z0-9/_.-]{1,250}\.(cfm|cfc)$',template)) template="";
            if(listFindNoCase("expression,database,application,missinginclude,template,request",type) && len(message) && len(template) && identifiableDatabase) {
                result.technicalMessage=message;result.path=template;result.confidence="technical";
                result.suggestedCategory=type=="database" ? "database" : "code";
                result.title=left(message,180);
                // Generic DB messages need a code and detail hash to distinguish their grouping identity.
                identity=serializeJSON([type,template,message,type=="database" ? sqlState & ":" & hash(dbDetail,"SHA-256") : ""]);
            }
        }
        // Bound stored summaries, preserving the full original in the admin detail/export.
        var sample=evidence(arguments.log);
        result.path=left(sample.path,320);
        result.technicalMessage=left(sample.message,500);
        result.signature=lCase(hash(serializeJSON([1,site,item,identity]),"SHA-256"));
        return result;
    }
}
