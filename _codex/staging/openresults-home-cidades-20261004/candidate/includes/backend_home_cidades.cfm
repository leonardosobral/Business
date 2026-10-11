<cfif NOT structKeyExists(VARIABLES,"template") OR VARIABLES.template NEQ "/" OR NOT structKeyExists(VARIABLES,"qEventosBase") OR NOT isQuery(VARIABLES.qEventosBase)>
    <cfheader statuscode="403"/><cfcontent type="text/plain; charset=utf-8" reset="true"/>Acesso negado.<cfabort/>
</cfif>
<cfscript>
REQUEST.buildHomeCityCatalog = function(required query events, required date today) {
    var groups = {};
    var todayDate = createDate(year(arguments.today),month(arguments.today),day(arguments.today));
    var recentStart = dateAdd("d",-30,todayDate);
    var annualStart = dateAdd("m",-12,todayDate);
    for (var event in arguments.events) {
        var uf = uCase(trim(isNull(event.estado) ? "" : event.estado));
        var name = trim(isNull(event.cidade) ? "" : event.cidade);
        var slug = lCase(trim(isNull(event.tag_cidade) ? "" : event.tag_cidade));
        if (isNull(event.pais) || event.pais != "BR" || !listFind("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO",uf) || !len(name) || !len(slug) || reFind("[^a-z0-9-]",slug)) continue;
        var key = uf & ":" & slug;
        if (!structKeyExists(groups,key)) {
            var words = listToArray(lCase(name)," ");
            for (var wi=1;wi<=arrayLen(words);wi++) {
                if (wi==1 || !listFindNoCase("a,ao,aos,as,com,da,das,de,del,do,dos,e,em,na,nas,no,nos,para,por,sem,sob",words[wi])) {
                    words[wi] = uCase(left(words[wi],1)) & mid(words[wi],2,len(words[wi]));
                }
            }
            groups[key] = {name=arrayToList(words," "),uf=uf,slug=slug,total=0,recent=0,annual=0,latest=createDate(1900,1,1)};
        }
        groups[key].total++;
        if (!isNull(event.data_final) && isDate(event.data_final)) {
            var eventDay = createDate(year(event.data_final),month(event.data_final),day(event.data_final));
            if (eventDay<=todayDate) {
                if (eventDay>recentStart) groups[key].recent++;
                if (eventDay>annualStart) groups[key].annual++;
                if (eventDay>groups[key].latest) groups[key].latest=eventDay;
            }
        }
    }
    var cities = [];
    for (var key in groups) arrayAppend(cities,groups[key]);
    arraySort(cities,function(a,b){return compareNoCase(a.name & " " & a.uf,b.name & " " & b.uf);});
    var recentPool = arrayFilter(cities,function(city){return city.recent>0;});
    arraySort(recentPool,function(a,b){
        if (a.recent!=b.recent) return b.recent-a.recent;
        if (a.latest!=b.latest) return dateCompare(b.latest,a.latest);
        return compareNoCase(a.name & " " & a.uf,b.name & " " & b.uf);
    });
    var recent = [];
    var seen = {};
    for (var city in recentPool) {
        if (arrayLen(recent)==6) break;
        arrayAppend(recent,city);seen[city.uf & ":" & city.slug]=true;
    }
    var popularPool = arrayFilter(cities,function(city){return city.annual>0 && !structKeyExists(seen,city.uf & ":" & city.slug);});
    arraySort(popularPool,function(a,b){
        if (a.annual!=b.annual) return b.annual-a.annual;
        return compareNoCase(a.name & " " & a.uf,b.name & " " & b.uf);
    });
    var popular = [];
    for (var city in popularPool) {
        if (arrayLen(popular)==6) break;
        arrayAppend(popular,city);
    }
    return {cities=cities,recent=recent,popular=popular};
};
VARIABLES.homeCityCatalog = REQUEST.buildHomeCityCatalog(VARIABLES.qEventosBase,now());
VARIABLES.homeCitySearchData = [];
for (VARIABLES.homeCityRow in VARIABLES.homeCityCatalog.cities) {
    arrayAppend(VARIABLES.homeCitySearchData,{name=VARIABLES.homeCityRow.name,uf=VARIABLES.homeCityRow.uf,slug=VARIABLES.homeCityRow.slug,total=VARIABLES.homeCityRow.total});
}
VARIABLES.homeCityJson = replace(serializeJSON(VARIABLES.homeCitySearchData),"<","\u003c","all");
</cfscript>
