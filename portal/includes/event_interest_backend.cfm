<!--- Audience-backed reader; deployed before the page switches to this contract. --->
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfscript>
function eventInterestInput(required string key,string fallback="") {
    return structKeyExists(URL,arguments.key) AND isSimpleValue(URL[arguments.key]) ? trim(URL[arguments.key] & "") : arguments.fallback;
}
function eventInterestNumber(required numeric value) { return replace(numberFormat(arguments.value,"__,___,___,___"),",",".","all"); }
function eventInterestPercent(required numeric value,required numeric total) {
    return arguments.total GT 0 ? replace(numberFormat(100*arguments.value/arguments.total,"0.0"),".",",") & "%" : "—";
}
function eventInterestUrl(struct changes={}) {
    var values=duplicate(VARIABLES.eiFilters);
    structAppend(values,arguments.changes,true);
    var pairs=[];
    for(var key in ["dias","uf","termo","fase","internos","evento_id","aba","p"])
        if(structKeyExists(values,key) AND len(values[key] & "")) arrayAppend(pairs,key & "=" & encodeForURL(values[key] & ""));
    return "./?" & arrayToList(pairs,"&");
}
function eventInterestAgenda(required string id) {
    if (!VARIABLES.eiAgendaReady) return "Agenda indisponível";
    var row=structKeyExists(VARIABLES.eiAgenda,arguments.id) ? VARIABLES.eiAgenda[arguments.id] : {athletes=0,saved=0,registered=0};
    return eventInterestNumber(row.athletes) & " atletas na agenda";
}
VARIABLES.eiUfs="AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO";
VARIABLES.eiFilters={dias=eventInterestInput("dias","7"),uf=uCase(eventInterestInput("uf")),termo=left(eventInterestInput("termo"),120),fase=eventInterestInput("fase","all"),internos=eventInterestInput("internos","0"),evento_id=eventInterestInput("evento_id"),aba=eventInterestInput("aba","ranking"),p=eventInterestInput("p","1")};
if(!listFind("1,7,30,90",VARIABLES.eiFilters.dias)) VARIABLES.eiFilters.dias="7";
if(!listFind(VARIABLES.eiUfs,VARIABLES.eiFilters.uf)) VARIABLES.eiFilters.uf="";
if(!listFind("all,future,past",VARIABLES.eiFilters.fase)) VARIABLES.eiFilters.fase="all";
VARIABLES.eiFilters.internos=VARIABLES.eiFilters.internos EQ "1" ? "1" : "0";
if(!reFind("^[1-9][0-9]{0,29}$",VARIABLES.eiFilters.evento_id)) VARIABLES.eiFilters.evento_id="";
if(!listFind("ranking,alta,agenda,cadastro,origem,publico,metodo",VARIABLES.eiFilters.aba)) VARIABLES.eiFilters.aba="ranking";
if(listFind("alta,agenda",VARIABLES.eiFilters.aba)) VARIABLES.eiFilters.dias=val(VARIABLES.eiFilters.dias) GTE 30 ? "30" : "7";
if(VARIABLES.eiFilters.aba EQ "agenda") VARIABLES.eiFilters.fase="future";
if(!reFind("^[1-9][0-9]{0,3}$",VARIABLES.eiFilters.p)) VARIABLES.eiFilters.p="1";
VARIABLES.eiReady=false; VARIABLES.eiAgendaReady=false; VARIABLES.eiAgenda={};
VARIABLES.eiParams={
    days={value=val(VARIABLES.eiFilters.dias),cfsqltype="cf_sql_integer"},
    include_internal={value=VARIABLES.eiFilters.internos EQ "1",cfsqltype="cf_sql_bit"},
    term={value=VARIABLES.eiFilters.termo,cfsqltype="cf_sql_varchar"},
    uf={value=VARIABLES.eiFilters.uf,cfsqltype="cf_sql_varchar"},
    stage={value=VARIABLES.eiFilters.fase,cfsqltype="cf_sql_varchar"},
    event_id={value=VARIABLES.eiFilters.evento_id,cfsqltype="cf_sql_varchar"},
    offset={value=(val(VARIABLES.eiFilters.p)-1)*50,cfsqltype="cf_sql_integer"}
};
VARIABLES.eiSqlDirectory=getDirectoryFromPath(getCurrentTemplatePath()) & "../audiencia/queries/";
try {
    if(VARIABLES.eiFilters.aba EQ "agenda") {
        VARIABLES.eiQuery=queryExecute(fileRead(VARIABLES.eiSqlDirectory & "event_agenda_ranking.sql","UTF-8"),VARIABLES.eiParams,{datasource="runnerhub",timeout=8,cachedwithin=createTimeSpan(0,0,1,0)});
        VARIABLES.eiReport=deserializeJSON(VARIABLES.eiQuery.report[1]);
        if(!structKeyExists(VARIABLES.eiReport,"ranking") OR !isArray(VARIABLES.eiReport.ranking)) throw(type="EventAgendaContract",message="Invalid agenda ranking");
        for(VARIABLES.eiKey in ["events","athletes","gaps"])
            if(!structKeyExists(VARIABLES.eiReport.summary,VARIABLES.eiKey) OR !isNumeric(VARIABLES.eiReport.summary[VARIABLES.eiKey]) OR VARIABLES.eiReport.summary[VARIABLES.eiKey] LT 0) throw(type="EventAgendaContract",message="Invalid agenda count");
        VARIABLES.eiReady=true;
    } else {
    VARIABLES.eiSchema=queryExecute("SELECT to_regclass('audience.events') IS NOT NULL AS ready",{},{datasource="runnerhub",timeout=3});
    if (VARIABLES.eiSchema.ready[1]) {
        VARIABLES.eiQuery=queryExecute(fileRead(VARIABLES.eiSqlDirectory & "event_interest.sql","UTF-8"),VARIABLES.eiParams,{datasource="runnerhub",timeout=8,cachedwithin=createTimeSpan(0,0,1,0)});
        VARIABLES.eiReport=deserializeJSON(VARIABLES.eiQuery.report[1]);
        for(VARIABLES.eiKey in ["ranking","hot","gaps","daily","sources","devices","regions","flows"])
            if(!structKeyExists(VARIABLES.eiReport,VARIABLES.eiKey) OR !isArray(VARIABLES.eiReport[VARIABLES.eiKey])) throw(type="EventInterestContract",message="Invalid report section");
        for(VARIABLES.eiKey in ["pageviews","visitors","sessions","events","gaps","hot","flow_transitions"])
            if(!structKeyExists(VARIABLES.eiReport.summary,VARIABLES.eiKey) OR !isNumeric(VARIABLES.eiReport.summary[VARIABLES.eiKey]) OR VARIABLES.eiReport.summary[VARIABLES.eiKey] LT 0) throw(type="EventInterestContract",message="Invalid report count");
        VARIABLES.eiReady=true;
    }
    }
} catch(any eventInterestReadError) {
    writeLog(file="audience_measurement",type="error",text="Business event interest unavailable: " & left(eventInterestReadError.type & "",100));
}
// This cross-product stock is not a visitor conversion or append-only history.
// Its optional read cannot hide page openings if agenda is unavailable.
if(VARIABLES.eiReady AND VARIABLES.eiFilters.aba NEQ "agenda") {
    try {
        VARIABLES.eiIds={};
        for(VARIABLES.eiSection in ["ranking","hot","gaps"])
            for(VARIABLES.eiRow in VARIABLES.eiReport[VARIABLES.eiSection])
                if(len(VARIABLES.eiRow.content_id)) VARIABLES.eiIds[VARIABLES.eiRow.content_id]=true;
        if(structCount(VARIABLES.eiIds)) {
            VARIABLES.eiAgendaQuery=queryExecute(fileRead(VARIABLES.eiSqlDirectory & "event_agenda.sql","UTF-8"),{ids={value=serializeJSON(structKeyArray(VARIABLES.eiIds)),cfsqltype="cf_sql_varchar"}},{datasource="runnerhub",timeout=4,cachedwithin=createTimeSpan(0,0,1,0)});
            for(VARIABLES.eiRow in deserializeJSON(VARIABLES.eiAgendaQuery.report[1])) VARIABLES.eiAgenda[VARIABLES.eiRow.content_id]=VARIABLES.eiRow;
        }
        VARIABLES.eiAgendaReady=true;
    } catch(any eventAgendaReadError) {
        writeLog(file="audience_measurement",type="error",text="Business event agenda unavailable: " & left(eventAgendaReadError.type & "",100));
    }
}
</cfscript>
