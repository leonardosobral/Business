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
            // Decode stored HTML once; callers still HTML-encode when rendering.
            var decoder=createObject("java","org.apache.commons.lang3.StringEscapeUtils");
            result.path=decoder.unescapeHtml4(field(raw,"TEMPLATE"));
            result.message=decoder.unescapeHtml4(field(raw,"MESSAGE"));
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
        // Older CF dumps have no reporter fingerprint. Hash the complete exception identity,
        // never the log ID or only the URL. Keep hosts, lines and diagnostic details distinct.
        if(item=="erro" && result.confidence=="individual" && !len(field(raw,"FINGERPRINT"))) {
            var legacyDecoder=createObject("java","org.apache.commons.lang3.StringEscapeUtils");
            var legacyType=lCase(legacyDecoder.unescapeHtml4(field(raw,"TYPE")));
            var legacyTemplate=legacyDecoder.unescapeHtml4(field(raw,"TEMPLATE"));
            var legacyLine=trim(field(raw,"LINE"));
            var legacyMessage=trim(reReplace(legacyDecoder.unescapeHtml4(field(raw,"MESSAGE")),"\s+"," ","all"));
            var legacyDetail=trim(reReplace(legacyDecoder.unescapeHtml4(field(raw,"DETAIL")),"\s+"," ","all"));
            var legacySqlState=uCase(trim(field(raw,"SQLSTATE")));
            var legacyDatabase=legacyType=="database" || reFind("^[0-9A-Z]{5}$",legacySqlState)>0;
            if(reFind("^[a-z][a-z0-9_.-]{0,79}$",legacyType) &&
                reFind("^/[a-zA-Z0-9/_. -]{1,500}\.(cfm|cfc)$",legacyTemplate) &&
                reFind("^[1-9][0-9]{0,8}$",legacyLine) && len(legacyMessage) && len(legacyMessage)<=4000 &&
                (!legacyDatabase || (reFind("^[0-9A-Z]{5}$",legacySqlState) && len(legacyDetail)))) {
                identity=serializeJSON(["legacy-exception-v1",legacyType,legacyTemplate,legacyLine,legacyMessage,legacySqlState,hash(legacyDetail,"SHA-256")]);
                result.confidence="legacy_exception";
                result.suggestedCategory=legacyDatabase ? "database" : "code";
                result.title=left((legacyDatabase ? "Falha de banco de dados" : "Falha de aplicação") & " · " & listLast(legacyTemplate,"/"),180);
            }
        }
        // Current reporters retain a stable defect fingerprint even when the public message is generic.
        // Decode only this new identity path, preserving legacy signatures without a reporter fingerprint.
        if(item=="erro") {
            var fingerprint=lCase(field(raw,"FINGERPRINT"));
            var environment=lCase(field(raw,"ENVIRONMENT"));
            var reporterType=lCase(field(raw,"TYPE"));
            var reporterTemplate=createObject("java","org.apache.commons.lang3.StringEscapeUtils").unescapeHtml4(field(raw,"TEMPLATE"));
            if(reFind("^[a-f0-9]{64}$",fingerprint) && listFind("prod,beta,dev,unknown",environment) &&
                reFind("^[a-z][a-z0-9_.-]{0,79}$",reporterType) && reFind("^/[a-zA-Z0-9/_. -]{1,500}\.(cfm|cfc)$",reporterTemplate)) {
                identity=serializeJSON(["reporter-v1",site,environment,reporterType,reporterTemplate,fingerprint]);
                result.confidence="fingerprint";
                result.suggestedCategory=reporterType=="database" ? "database" : "code";
                result.title=left((reporterType=="database" ? "Falha de banco de dados" : "Falha de aplicação") & " · " & listLast(reporterTemplate,"/"),180);
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
