<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfscript>
function ga4Fail(required string message) { throw(type="GA4.Validation",message=arguments.message); }
function ga4Authorized() {
    var q=agendaDb("SELECT scopes FROM public.tb_google_agenda_conexao WHERE id=1");
    return q.recordCount>0 && listFind(q.scopes,"https://www.googleapis.com/auth/analytics.readonly"," ")>0;
}
function ga4Google(required string path, string method="GET", struct body={}, struct params={}) {
    var dataApi=reFind("^properties/[0-9]+:batchRunReports$",arguments.path)>0 && arguments.method=="POST";
    var adminApi=(arguments.path=="accountSummaries" || reFind("^properties/[0-9]+(/dataStreams)?$",arguments.path)>0) && arguments.method=="GET";
    if(!dataApi && !adminApi) ga4Fail("Consulta Analytics inválida.");
    var endpoint=(dataApi?"https://analyticsdata.googleapis.com/v1beta/":"https://analyticsadmin.googleapis.com/v1beta/") & arguments.path;
    var token="";
    lock name="RunnerHubBusiness.GoogleAgenda" type="exclusive" timeout="25" {token=agendaAccessToken();}
    var r=agendaHttp(endpoint,arguments.method,arguments.params,arguments.body,token);
    if(r.status==401) {
        lock name="RunnerHubBusiness.GoogleAgenda" type="exclusive" timeout="25" {token=agendaAccessToken(true);}
        r=agendaHttp(endpoint,arguments.method,arguments.params,arguments.body,token);
    }
    if(r.status==403) ga4Fail("O Google negou acesso. Confira a permissão da conta na propriedade e habilite Google Analytics Data API e Google Analytics Admin API no projeto Google Cloud da conexão.");
    if(r.status==401) ga4Fail("Reconecte o Google para renovar a autorização do Analytics.");
    if(r.status==429 || r.status>=500 || r.status==0) ga4Fail("O Google está indisponível ou limitou as consultas. Aguarde alguns minutos e tente novamente.");
    if(r.status<200 || r.status>=300) ga4Fail("Não foi possível consultar o Analytics (HTTP " & r.status & "). Confira a propriedade selecionada.");
    return r.data;
}
function ga4Properties() {
    if(structKeyExists(application,"seoGa4Properties") && dateDiff("n",application.seoGa4Properties.at,now())<15) return duplicate(application.seoGa4Properties.items);
    var items=[];var page="";var rounds=0;
    do {
        var r=ga4Google("accountSummaries","GET",{},{"pageSize"=200,"pageToken"=page});
        if(structKeyExists(r,"accountSummaries")) for(var account in r.accountSummaries) if(structKeyExists(account,"propertySummaries")) for(var prop in account.propertySummaries) {
            if(reFind("^properties/[0-9]+$",prop.property)) arrayAppend(items,{"id"=listLast(prop.property,"/"),"name"=prop.displayName});
        }
        page=structKeyExists(r,"nextPageToken")?r.nextPageToken:"";rounds++;
        if(rounds>=10 && len(page)) ga4Fail("Há muitas propriedades nesta conta. Não foi possível concluir a listagem.");
    } while(len(page));
    application.seoGa4Properties={at=now(),items=duplicate(items)};
    return items;
}
function ga4Property(required string id) {
    if(!reFind("^[0-9]{1,20}$",arguments.id)) ga4Fail("Selecione uma propriedade válida.");
    var cacheKey="p" & arguments.id;
    if(!structKeyExists(application,"seoGa4Verified")) application.seoGa4Verified={};
    if(structKeyExists(application.seoGa4Verified,cacheKey) && dateDiff("n",application.seoGa4Verified[cacheKey].at,now())<15) return duplicate(application.seoGa4Verified[cacheKey].data);
    var matched=false;var page="";var rounds=0;
    do {
        var streams=ga4Google("properties/"&arguments.id&"/dataStreams","GET",{},{"pageSize"=200,"pageToken"=page});
        if(structKeyExists(streams,"dataStreams")) for(var stream in streams.dataStreams) {
            if(structKeyExists(stream,"webStreamData") && structKeyExists(stream.webStreamData,"measurementId") && stream.webStreamData.measurementId=="G-7MYGVTEDZV") matched=true;
        }
        page=structKeyExists(streams,"nextPageToken")?streams.nextPageToken:"";rounds++;
        if(rounds>=5 && len(page)) ga4Fail("Não foi possível concluir a verificação dos fluxos da propriedade.");
    } while(len(page) && !matched);
    if(!matched) ga4Fail("Esta propriedade não contém o fluxo G-7MYGVTEDZV instalado no Road Runners. Selecione a propriedade correta.");
    var prop=ga4Google("properties/"&arguments.id);
    var result={"id"=arguments.id,"name"=prop.displayName,"timezone"=prop.timeZone};
    application.seoGa4Verified[cacheKey]={at=now(),data=duplicate(result)};
    return result;
}
function ga4Periods(required numeric days,required string timezone,string today="") {
    if(!listFind("7,28,90",arguments.days)) ga4Fail("Período inválido.");
    var localDate=createObject("java","java.time.LocalDate");
    var endDate=len(arguments.today)?localDate.parse(arguments.today).minusDays(javacast("long",1)):localDate.now(createObject("java","java.time.ZoneId").of(arguments.timezone)).minusDays(javacast("long",1));
    return [{"name"="atual","startDate"=endDate.minusDays(javacast("long",arguments.days-1)).toString(),"endDate"=endDate.toString()},
      {"name"="anterior","startDate"=endDate.minusDays(javacast("long",arguments.days*2-1)).toString(),"endDate"=endDate.minusDays(javacast("long",arguments.days)).toString()}];
}
function ga4Requests(required array periods) {
    var host={"filter"={"fieldName"="hostName","inListFilter"={"values"=["roadrunners.run","www.roadrunners.run"],"caseSensitive"=false}}};
    var base={"dateRanges"=[arguments.periods[1]],"dimensionFilter"=host,"metrics"=[{"name"="sessions"},{"name"="activeUsers"},{"name"="screenPageViews"}],"limit"="20"};
    var totals=duplicate(base);totals["dateRanges"]= arguments.periods;arrayAppend(totals.metrics,{"name"="engagementRate"});
    var daily=duplicate(base);daily["dimensions"]= [{"name"="date"}];daily["limit"]= "90";daily["orderBys"]= [{"dimension"={"dimensionName"="date"}}];
    var channels=duplicate(base);channels["dimensions"]= [{"name"="sessionDefaultChannelGroup"}];channels["orderBys"]= [{"metric"={"metricName"="sessions"},"desc"=true}];channels["limit"]= "50";
    var pages=duplicate(base);pages["dimensions"]= [{"name"="landingPage"}];pages["orderBys"]= channels.orderBys;pages["limit"]= "20";
    var ai=duplicate(base);ai["dimensions"]= [{"name"="sessionSource"},{"name"="sessionMedium"}];ai["limit"]= "100";ai["orderBys"]= channels.orderBys;
    ai["dimensionFilter"]= {"andGroup"={"expressions"=[host,{"filter"={"fieldName"="sessionSource","stringFilter"={"matchType"="FULL_REGEXP","value"="(?i)(.*\.)?(chatgpt\.com|chat\.openai\.com|perplexity\.ai|claude\.ai|gemini\.google\.com|copilot\.microsoft\.com)|chatgpt|perplexity|claude|gemini|copilot"}}}]}};
    return [totals,daily,channels,pages,ai];
}
function ga4Report(required string id,required numeric days) {
    var prop=ga4Property(arguments.id);var periods=ga4Periods(arguments.days,prop.timezone);
    var key="p"&arguments.id&"d"&arguments.days&"e"&replace(periods[1].endDate,"-","","all");
    if(!structKeyExists(application,"seoGa4Reports")) application.seoGa4Reports={};
    if(structKeyExists(application.seoGa4Reports,key) && dateDiff("n",application.seoGa4Reports[key].at,now())<15) return duplicate(application.seoGa4Reports[key].data);
    var r=ga4Google("properties/"&arguments.id&":batchRunReports","POST",{"requests"=ga4Requests(periods)});
    if(!structKeyExists(r,"reports") || arrayLen(r.reports)!=5) ga4Fail("O Google retornou um relatório incompleto. Tente novamente.");
    var result={"property"=prop,"periods"=periods,"reports"=r.reports,"updated"=createObject("java","java.time.Instant").now().toString()};
    // Bounded cache; snapshots never mix properties, time zones or comparison windows.
    if(structCount(application.seoGa4Reports)>30) application.seoGa4Reports={};
    application.seoGa4Reports[key]={at=now(),data=duplicate(result)};
    return result;
}
function ga4OAuth() {
    var c=agendaConfig();var state=agendaRandom();var verifier=agendaRandom()&agendaRandom();
    session.agendaOAuth={state=state,verifier=verifier,actor=val(qPerfil.id),expires=dateAdd("n",10,now()),seoGa4=true};
    var challenge=replace(replace(replace(toBase64(binaryDecode(hash(verifier,"SHA-256"),"hex")),"+","-","all"),"/","_","all"),"=","","all");
    var scopes=c.scopes & " https://www.googleapis.com/auth/analytics.readonly";
    var prior=agendaDb("SELECT scopes FROM public.tb_google_agenda_conexao WHERE id=1");
    if(prior.recordCount && listFind(prior.scopes,"https://www.googleapis.com/auth/gmail.readonly"," ")) scopes &= " https://www.googleapis.com/auth/gmail.readonly";
    var args={"client_id"=c.CLIENT_ID,"redirect_uri"=c.redirectUri,"response_type"="code","scope"=scopes,"include_granted_scopes"="true","access_type"="offline","prompt"="consent select_account","login_hint"=c.email,"state"=state,"code_challenge"=challenge,"code_challenge_method"="S256"};
    var pairs=[];for(var k in args) arrayAppend(pairs,encodeForURL(k)&"="&encodeForURL(args[k]));
    return {"url"="https://accounts.google.com/o/oauth2/v2/auth?"&arrayToList(pairs,"&")};
}
</cfscript>
