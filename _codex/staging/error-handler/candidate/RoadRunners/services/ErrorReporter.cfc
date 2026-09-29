component output="false" {
    public struct function describe(required any exception, string eventName="", string host="", string path="", string requestId="", string site="RR") {
        var hostName=lCase(listFirst(arguments.host,":"));
        var environment=listFindNoCase("roadrunners.run,www.roadrunners.run,roadrunners.com.br,www.roadrunners.com.br",hostName) ? "prod" : (hostName=="beta.roadrunners.run" ? "beta" : (hostName=="dev.roadrunners.run" ? "dev" : "unknown"));
        var type=lCase(left(arguments.exception.type ?: "application",80));
        if(!reFind("^[a-z0-9_.-]+$",type))type="application";
        var rawMessage=left(arguments.exception.message ?: "",2000);
        var message="Erro interno ao processar a solicitação.";
        if(reFind("^(Variable [A-Z_][A-Z0-9_\.]{0,80} is undefined\.|Element [A-Z_][A-Z0-9_\.]{0,80} is undefined in [A-Z_][A-Z0-9_\.]{0,80}\.|Error Executing Database Query\.|The request has exceeded the allowable time limit\.)$",trim(rawMessage)))message=trim(rawMessage);
        var template="";var line=0;
        if(structKeyExists(arguments.exception,"tagContext") && isArray(arguments.exception.tagContext) && arrayLen(arguments.exception.tagContext)) {
            var frame=arguments.exception.tagContext[1];
            if(isStruct(frame)) {template=left(frame.template ?: "",500);line=val(frame.line ?: 0);}
        }
        if(!reFind("^/[a-zA-Z0-9/_. -]+\.(cfm|cfc)$",template))template="";
        var sqlState=uCase(left(arguments.exception.sqlState ?: "",5));
        if(!reFind("^[A-Z0-9]{5}$",sqlState))sqlState="";
        var rawDetail=left(arguments.exception.detail ?: "",4000);
        // Keep database structure distinct while grouping failures with changing input values.
        var sqlIdentifiers=reMatchNoCase('(column|relation|constraint|table|schema|function|operator|type)\s+"[a-zA-Z_][a-zA-Z0-9_.-]*"',rawDetail);
        var normalizedDetail=reReplace(rawDetail,"=\([^)]*\)","={value}","all");
        normalizedDetail=reReplace(normalizedDetail,"'[^']*'","{value}","all");
        normalizedDetail=reReplace(normalizedDetail,'"[^"]*"',"{value}","all");
        normalizedDetail=reReplace(normalizedDetail,"[0-9]+","{n}","all");
        var detailDigest=lCase(hash(serializeJSON([normalizedDetail,sqlIdentifiers]),"SHA-256"));
        var identityMessage=reReplace(rawMessage,"'[^']*'", "{value}","all");
        identityMessage=reReplace(identityMessage,"[0-9]+","{n}","all");
        var fingerprint=lCase(hash(serializeJSON([arguments.site,environment,type,template,identityMessage,sqlState,type=="database" ? detailDigest : ""]),"SHA-256"));
        var cleanPath=listFirst(arguments.path,"?");
        if(!reFind("^/[a-zA-Z0-9/_.-]{0,500}$",cleanPath))cleanPath="/";
        var cleanId=reReplace(left(arguments.requestId,80),"[^a-zA-Z0-9-]","","all");
        return {status=500,site=arguments.site,environment=environment,notify=listFind("prod,beta",environment)>0,type=type,message=message,template=template,line=line,sqlstate=sqlState,detail=detailDigest,path=cleanPath,requestId=cleanId,fingerprint=fingerprint,event=left(arguments.eventName,80)};
    }
    // Called while holding the server lock. Reservations count even if SMTP enqueue fails.
    public struct function reserve(required struct state,required string fingerprint,required numeric seconds) {
        if(!structKeyExists(state,"sent"))state.sent=[];
        if(!structKeyExists(state,"signatures"))state.signatures={};
        for(var i=arrayLen(state.sent);i>=1;i--)if(state.sent[i]<=seconds-3600)arrayDeleteAt(state.sent,i);
        for(var key in structKeyArray(state.signatures))if(state.signatures[key].seen<=seconds-3600)structDelete(state.signatures,key);
        if(!structKeyExists(state.signatures,fingerprint)) {
            if(structCount(state.signatures)>=1000)return {allowed=false,reason="capacity",occurrences=1};
            state.signatures[fingerprint]={seen=seconds,lastSent=-100000,count=0};
        }
        var entry=state.signatures[fingerprint];entry.seen=seconds;entry.count++;
        var result={allowed=false,reason="duplicate",occurrences=entry.count};
        if(seconds-entry.lastSent<900)return result;
        // Existing notification has To + CC: at most 30 recipient submissions / rolling hour.
        if(arrayLen(state.sent)>=15){result.reason="hourly_limit";return result;}
        arrayAppend(state.sent,seconds);entry.lastSent=seconds;entry.count=0;
        result.allowed=true;result.reason="reserved";return result;
    }
    public struct function reserveAlert(required struct event) {
        if(!event.notify)return {allowed=false,reason="environment",occurrences=1};
        var result={allowed=false,reason="limiter_unavailable",occurrences=1};
        lock name="rr-error-alert-budget-v1" type="exclusive" timeout="1" {
            if(!structKeyExists(SERVER,"rrErrorAlertBudgetV1"))SERVER.rrErrorAlertBudgetV1={};
            result=reserve(SERVER.rrErrorAlertBudgetV1,event.fingerprint,dateDiff("s",createDateTime(1970,1,1,0,0,0),now()));
        }
        return result;
    }
    public string function logHtml(required struct event) {
        var html='An error occurred: https://roadrunners.run' & encodeForHTML(event.path) & '<table>';
        var fields={MESSAGE=event.message,TYPE=event.type,TEMPLATE=event.template,LINE=event.line,SQLSTATE=event.sqlstate,DETAIL=event.detail,HTTP_STATUS=event.status,REQUEST_ID=event.requestId,ENVIRONMENT=event.environment,FINGERPRINT=event.fingerprint};
        if(structKeyExists(event,"alert")){fields.ALERT=event.alert.reason;fields.OCCURRENCES_SINCE_ALERT=event.alert.occurrences;}
        for(var field in fields)html &= '<tr><td>' & field & '</td><td>' & encodeForHTML(fields[field] & "") & '</td></tr>';
        return html & '</table>';
    }
    public numeric function writeDatabase(required struct event,string datasource="runnerhub",string schema="public") {
        if(!reFind("^[a-z][a-z0-9_]*$",schema))throw(message="Invalid log schema");
        var q=queryExecute("INSERT INTO " & schema & ".tb_log(log_item,log_item_id,log_user,site) VALUES ('erro',:body,'error-handler',:site) RETURNING id_log",{body={value=logHtml(event),cfsqltype="cf_sql_varchar"},site={value=event.site,cfsqltype="cf_sql_varchar"}},{datasource=datasource,timeout=2});
        return q.id_log[1];
    }
    public void function writeLocal(required struct event,string reason="database_unavailable") {
        writeLog(file="roadrunners-errors",type="error",text=serializeJSON({reason=reason,event=event}));
    }
}
