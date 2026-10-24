component output=false {
    variables.enabled = false;
    variables.secret = "";
    variables.uuidPattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$";
    variables.contextKeys = "schemaVersion,pageViewId,issuedAt,siteHost,environment,pageFamily,pagePath,contentType,contentId,visitorUf,profileUf,contextUf,marketUf,geoSource,isInternal";
    variables.clientKeys = "visitorId,sessionId,source,medium,campaign,creative,referrerHost";
    variables.eventKeys = "kind,key,slotKey,placementKey,slotState,deliveryId,campaignId,contentType,contentId,activeMs,visibleMs,maxContinuousMs,ratio,deviceClass";
    variables.kinds = "page_view,page_engagement,slot_opportunity,slot_request,slot_served,slot_render,ad_render,slot_viewable,ad_viewable,content_open,content_viewable,content_progress,video_start,video_progress,video_complete,outbound_click";

    public any function init(struct config={}) {
        variables.secret = scalar(arguments.config,"secret");
        variables.enabled = truth(arguments.config,"enabled") && len(variables.secret) >= 32;
        return this;
    }
    public boolean function isEnabled() { return variables.enabled; }
    private void function invalid() { throw(type="Audience.Invalid",message="Invalid audience request"); }
    private string function scalar(required any data, required string key, string fallback="") {
        if ((!isStruct(arguments.data) && !isObject(arguments.data)) || !structKeyExists(arguments.data,arguments.key)) return arguments.fallback;
        if (!isSimpleValue(arguments.data[arguments.key])) invalid();
        return trim(arguments.data[arguments.key] & "");
    }
    private boolean function truth(required any data, required string key) {
        return listFindNoCase("true,yes,1",scalar(arguments.data,arguments.key,"false")) > 0;
    }
    private string function uf(required string value) {
        var normalized = uCase(arguments.value);
        return listFind("AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO",normalized) ? normalized : "";
    }
    private string function label(required string value, numeric limit=100) {
        return left(reReplace(arguments.value,"[^a-zA-Z0-9_.:-]","","all"),arguments.limit);
    }
    private string function queryValue(required struct page, required string queryName, required string columnName) {
        if (!structKeyExists(arguments.page,arguments.queryName) || !isQuery(arguments.page[arguments.queryName])) return "";
        var q = arguments.page[arguments.queryName];
        if (!q.recordCount || !listFindNoCase(q.columnList,arguments.columnName)) return "";
        return isNull(q[arguments.columnName][1]) ? "" : trim(q[arguments.columnName][1] & "");
    }
    private numeric function epoch() { return fix(createObject("java","java.lang.System").currentTimeMillis()/1000); }

    public struct function buildContext(required struct page, required struct requestData, required struct cgiData) {
        var c = {};
        var host = lCase(scalar(arguments.cgiData,"HTTP_HOST"));
        if (!reFind("^(roadrunners\.run|www\.roadrunners\.run|beta\.roadrunners\.run|dev\.roadrunners\.run|localhost(:[0-9]{1,5})?|127\.0\.0\.1(:[0-9]{1,5})?)$",host)) invalid();
        var familyMap = {"/"="home","/estado/"="state","/busca/"="search","/evento/"="event","/circuito/"="circuit","/atleta/"="profile","/noticias/"="news","/videos/"="videos","/resultados/"="results","/agenda/"="calendar"};
        var route = scalar(arguments.page,"template","/");
        var family = structKeyExists(familyMap,route) ? familyMap[route] : "other";
        var path = reFind("^/[a-zA-Z0-9/_-]{0,255}$",route) ? route : "/";
        var contentType = "";
        var contentId = "";
        var contextUf = "";
        var profileUf = "";
        var visitorUf = "";
        var internal = false;
        if (structKeyExists(arguments.requestData,"LocationContext") && isStruct(arguments.requestData.LocationContext)) visitorUf=uf(scalar(arguments.requestData.LocationContext,"uf"));
        if (structKeyExists(arguments.requestData,"Usuario") && (isObject(arguments.requestData.Usuario) || isStruct(arguments.requestData.Usuario))) {
            var user = arguments.requestData.Usuario;
            if (truth(user,"logado")) {
                profileUf = uf(scalar(user,"uf"));
                if (!len(profileUf)) profileUf=uf(scalar(user,"estado"));
                internal = truth(user,"is_admin") || truth(user,"is_dev");
            }
        }
        if (family == "event") {
            contextUf = uf(queryValue(arguments.page,"qEvento","estado"));
            contentType = "event"; contentId=label(queryValue(arguments.page,"qEvento","id_evento"));
            var eventTag = label(queryValue(arguments.page,"qEvento","tag"));
            if (len(eventTag)) path="/evento/" & eventTag & "/";
        } else if (family == "circuit") {
            var circuitId=queryValue(arguments.page,"qAgrega","id_agrega_evento");
            if (reFind("^[1-9][0-9]{0,9}$",circuitId)) {
                contentType="circuit"; contentId=circuitId;
                var circuitTag=queryValue(arguments.page,"qAgrega","tag");
                if (reFind("^[a-zA-Z0-9_-]{1,100}$",circuitTag)) path="/circuito/" & circuitTag & "/";
            }
        } else if (family == "home" && !truth(arguments.page,"homeContextFallback")) {
            contextUf=uf(scalar(arguments.page,"homeContextUf"));
        } else if (family == "state") {
            // estado/index.cfm sets this only after validating the requested UF.
            var stateRoot=scalar(arguments.page,"estadoRootPath");
            if (reFindNoCase("^/estado/[a-z]{2}/$",stateRoot)) contextUf=uf(listGetAt(stateRoot,2,"/"));
            if (len(contextUf)) path="/estado/" & lCase(contextUf) & "/";
        } else if (family == "profile") {
            var profilePageId=queryValue(arguments.page,"qPagina","id_pagina");
            if (reFind("^[1-9][0-9]{0,9}$",profilePageId)) {
                contentType="profile"; contentId="page-" & profilePageId;
            }
        } else if (family == "search") {
            // adContextUf is produced by the existing rendered search filters.
            contextUf=uf(scalar(arguments.page,"adContextUf"));
        }
        if (family == "news" && structKeyExists(arguments.page,"noticia") && isStruct(arguments.page.noticia) && len(scalar(arguments.page.noticia,"slug"))) {
            family="news_detail"; contentType="news";
            contentId=label(scalar(arguments.page.noticia,"id",scalar(arguments.page.noticia,"slug")));
            path="/noticias/" & label(scalar(arguments.page.noticia,"slug")) & "/";
        }
        // Preserve a server-produced canonical URL only for public content routes.
        if (listFind("home,state,search,event,circuit,news,news_detail,videos,results,calendar",family) && len(scalar(arguments.page,"canonical"))) {
            try {
                var canonicalUri=createObject("java","java.net.URI").init(scalar(arguments.page,"canonical"));
                var canonicalPath=canonicalUri.getPath() & "";
                if (reFind("^/[a-zA-Z0-9/_-]{0,255}$",canonicalPath)) path=canonicalPath;
            } catch(any ignoredCanonical) {}
        }
        c["schemaVersion"]=1;
        c["pageViewId"]=lCase(createObject("java","java.util.UUID").randomUUID().toString());
        c["issuedAt"]=epoch(); c["siteHost"]=host;
        c["environment"]=find("beta.",host)==1 ? "beta" : (find("dev.",host)==1 ? "dev" : (reFind("^(localhost|127\.)",host) ? "local" : "prod"));
        c["pageFamily"]=family; c["pagePath"]=path; c["contentType"]=contentType; c["contentId"]=contentId;
        c["visitorUf"]=visitorUf; c["profileUf"]=profileUf; c["contextUf"]=contextUf;
        c["marketUf"]=len(contextUf) ? contextUf : (len(profileUf) ? profileUf : visitorUf);
        c["geoSource"]=len(contextUf) ? "context" : (len(profileUf) ? "profile" : (len(visitorUf) ? "visitor" : "unknown"));
        c["isInternal"]=internal;
        return c;
    }

    // Explicit key strings avoid CFML engine/application casing settings changing v1.
    public string function flatJson(required struct value, required string keys) {
        var pairs=[];
        for (var key in listToArray(arguments.keys)) arrayAppend(pairs,serializeJSON(key) & ":" & serializeJSON(arguments.value[key]));
        return "{" & arrayToList(pairs,",") & "}";
    }
    public struct function signContext(required struct context) {
        if (!variables.enabled) invalid();
        var token=toBase64(flatJson(arguments.context,variables.contextKeys),"UTF-8");
        return {"contextToken"=token,"signature"=lCase(hmac(token,variables.secret,"HmacSHA256","UTF-8"))};
    }
    public string function configJson(required struct context) {
        var signed=signContext(arguments.context);
        return '{"endpoint":"/api/analytics/collect.cfm","context":' & flatJson(arguments.context,variables.contextKeys) & ',"contextToken":' & serializeJSON(signed.contextToken) & ',"signature":' & serializeJSON(signed.signature) & '}';
    }
    private void function validateOrigin(required string host, required struct headers) {
        var origin=lCase(scalar(arguments.headers,"Origin"));
        var fetchSite=lCase(scalar(arguments.headers,"Sec-Fetch-Site"));
        if (len(fetchSite) && fetchSite != "same-origin") invalid();
        if (!len(origin)) { if (fetchSite != "same-origin") invalid(); return; }
        var expected="https://" & lCase(arguments.host);
        if (reFind("^(localhost|127\.0\.0\.1)(:[0-9]{1,5})?$",arguments.host)) {
            if (origin != expected && origin != "http://" & lCase(arguments.host)) invalid();
        } else if (origin != expected) invalid();
    }
    private struct function verifiedContext(required string token, required string signature, required string host, required struct headers) {
        if (!variables.enabled) invalid();
        validateOrigin(arguments.host,arguments.headers);
        if (len(arguments.token)>8192 || !reFind("^[A-Za-z0-9+/]+={0,2}$",arguments.token) || !reFind("^[a-f0-9]{64}$",arguments.signature)) invalid();
        var expected=lCase(hmac(arguments.token,variables.secret,"HmacSHA256","UTF-8"));
        if (!createObject("java","java.security.MessageDigest").isEqual(charsetDecode(arguments.signature,"UTF-8"),charsetDecode(expected,"UTF-8"))) invalid();
        var c={};
        try { c=deserializeJSON(toString(binaryDecode(arguments.token,"base64"),"UTF-8")); } catch(any invalidToken) { invalid(); }
        if (isNull(c) || !isStruct(c)) invalid();
        for(var contextKey in listToArray(variables.contextKeys)) { if (!structKeyExists(c,contextKey) || !isSimpleValue(c[contextKey])) invalid(); }
        if (scalar(c,"schemaVersion") != "1" || !reFindNoCase(variables.uuidPattern,scalar(c,"pageViewId")) || scalar(c,"siteHost") != lCase(arguments.host)) invalid();
        var issued=scalar(c,"issuedAt");
        if (!reFind("^[0-9]{1,11}$",issued)) invalid();
        if (val(issued)>epoch()+60 || val(issued)<epoch()-86400) invalid();
        return c;
    }
    public struct function rebindSearchContext(required string contextToken, required string signature, required string host, required struct headers, required string contextUf) {
        var c=verifiedContext(arguments.contextToken,lCase(arguments.signature),arguments.host,arguments.headers);
        if (c.pageFamily != "search") invalid();
        // Only the server-rendered search region changes; a partial is not a page view.
        c["contextUf"]=uf(arguments.contextUf);
        c["marketUf"]=len(c.contextUf) ? c.contextUf : (len(c.profileUf) ? c.profileUf : c.visitorUf);
        c["geoSource"]=len(c.contextUf) ? "context" : (len(c.profileUf) ? "profile" : (len(c.visitorUf) ? "visitor" : "unknown"));
        return c;
    }
    public struct function validateBatch(required any payload, required string host, required struct headers) {
        if (!variables.enabled || !isStruct(arguments.payload)) invalid();
        var c=verifiedContext(scalar(arguments.payload,"contextToken"),lCase(scalar(arguments.payload,"signature")),arguments.host,arguments.headers);
        var audienceClient={};
        for(var idKey in ["visitorId","sessionId"]) {
            audienceClient[idKey]=lCase(scalar(arguments.payload,idKey));
            if (!reFindNoCase(variables.uuidPattern,audienceClient[idKey])) invalid();
        }
        for(var attribution in ["source","medium","campaign","creative"]) {
            var raw=scalar(arguments.payload,attribution);
            // URL-like values and likely personal identifiers are discarded as a whole.
            audienceClient[attribution]=(find("@",raw) || find("://",raw) || reFind("[?&=]",raw) || reFind("[0-9]{11}",reReplace(raw,"[. -]","","all")) || reFind("[0-9]{1,3}(\.[0-9]{1,3}){3}",raw)) ? "" : left(reReplace(raw,"[^a-zA-Z0-9_. -]","","all"),100);
        }
        var ref=lCase(scalar(arguments.payload,"referrerHost"));
        audienceClient["referrerHost"]=len(ref)<=253 && reFind("^[a-z0-9][a-z0-9.-]*\.[a-z]{2,63}$",ref) ? ref : "";
        if (!structKeyExists(arguments.payload,"events") || !isArray(arguments.payload.events) || arrayLen(arguments.payload.events)<1 || arrayLen(arguments.payload.events)>50) invalid();
        var events=[];
        for(var eventIndex=1; eventIndex<=arrayLen(arguments.payload.events); eventIndex++) {
            if (!arrayIsDefined(arguments.payload.events,eventIndex) || isNull(arguments.payload.events[eventIndex]) || !isStruct(arguments.payload.events[eventIndex])) invalid();
            var incoming=arguments.payload.events[eventIndex];
            var e={};
            e["kind"]=scalar(incoming,"kind"); e["key"]=scalar(incoming,"key");
            if (!listFind(variables.kinds,e.kind) || !reFind("^[a-zA-Z0-9_.:-]{1,160}$",e.key)) invalid();
            for(var field in ["slotKey","placementKey","contentType","contentId"]) {
                e[field]=scalar(incoming,field);
                if (len(e[field]) && !reFind("^[a-zA-Z0-9_.:-]{1,100}$",e[field])) invalid();
            }
            for(var adId in ["deliveryId","campaignId"]) {
                e[adId]=lCase(scalar(incoming,adId));
                if (len(e[adId]) && !reFindNoCase(variables.uuidPattern,e[adId])) invalid();
            }
            e["slotState"]=scalar(incoming,"slotState");
            if (len(e.slotState) && !listFind("pending,filled,house,empty,disabled,error,hidden,not_applicable",e.slotState)) invalid();
            e["deviceClass"]=scalar(incoming,"deviceClass","UNKNOWN");
            if (!listFind("MOBILE,TABLET,DESKTOP,UNKNOWN",e.deviceClass)) invalid();
            for(var duration in ["activeMs","visibleMs","maxContinuousMs"]) {
                var amount=scalar(incoming,duration,"0");
                if (!reFind("^[0-9]{1,8}$",amount) || val(amount)>86400000) invalid();
                e[duration]=javaCast("long",amount);
            }
            var ratio=scalar(incoming,"ratio","0");
            if (!reFind("^[0-9](\.[0-9]{1,8})?$",ratio) || val(ratio)>1) invalid();
            e["ratio"]=val(ratio);
            if ((find("slot_",e.kind)==1 || find("ad_",e.kind)==1) && (!len(e.slotKey) || !len(e.slotState))) invalid();
            if (listFind("slot_viewable,ad_viewable",e.kind) && (e.maxContinuousMs<1000 || e.ratio<0.5 || !listFind("filled,house,empty,disabled",e.slotState))) invalid();
            if (e.kind == "ad_viewable" && !listFind("filled,house",e.slotState)) invalid();
            if (find("ad_",e.kind)==1 && (!len(e.deliveryId) || !len(e.campaignId))) invalid();
            if (e.kind == "outbound_click" && find("outbound_click:live_registration:",e.key)==1) {
                if (e.contentType != "event" || !reFind("^[1-9][0-9]{0,9}$",e.contentId) || e.key != "outbound_click:live_registration:" & e.contentId
                    || len(e.slotKey) || len(e.placementKey) || len(e.slotState) || len(e.deliveryId) || len(e.campaignId)
                    || e.activeMs != 0 || e.visibleMs != 0 || e.maxContinuousMs != 0 || e.ratio != 0) invalid();
            }
            if (listFind("content_viewable,content_progress",e.kind)) {
                if (!len(e.contentId) || len(e.slotKey) || len(e.placementKey) || len(e.slotState) || len(e.deliveryId) || len(e.campaignId) || e.activeMs != 0) invalid();
                if (e.kind == "content_viewable") {
                    if (!listFind("news,video",e.contentType) || e.maxContinuousMs < 1000 || e.ratio < 0.5 || e.key != "content_viewable:" & e.contentType & ":" & e.contentId) invalid();
                } else {
                    if (e.contentType != "news" || c.contentType != "news" || c.contentId != e.contentId || e.visibleMs != 0 || e.maxContinuousMs != 0 || !listFind("0.25,0.5,0.75,1",e.ratio & "") || e.key != "content_progress:news:" & e.contentId & ":" & fix(e.ratio * 100)) invalid();
                }
            }
            arrayAppend(events,e);
        }
        return {"context"=c,"client"=audienceClient,"events"=events};
    }
    public numeric function persist(required struct batch) {
        var eventJson=[];
        for(var e in arguments.batch.events) arrayAppend(eventJson,flatJson(e,variables.eventKeys));
        var result=queryExecute("SELECT audience.ingest_events(CAST(:context AS jsonb),CAST(:client AS jsonb),CAST(:events AS jsonb)) AS accepted",{
            "context"={value=flatJson(arguments.batch.context,variables.contextKeys),cfsqltype="cf_sql_longvarchar"},
            "client"={value=flatJson(arguments.batch.client,variables.clientKeys),cfsqltype="cf_sql_longvarchar"},
            "events"={value="[" & arrayToList(eventJson,",") & "]",cfsqltype="cf_sql_longvarchar"}
        },{datasource="runnerhub",timeout=3});
        return result.accepted[1];
    }
}
