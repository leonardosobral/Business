<cfscript>
checks=[];function check(required boolean ok,required string label){arrayAppend(checks,{name=label,passed=ok});if(!ok)throw(message=label);}
function citySignature(required struct catalog){
 var normalized=[];
 for(var group in ['cities','recent','popular']) {
  var rows=[];for(var city in arguments.catalog[group])arrayAppend(rows,[city.name,city.uf,city.slug,city.total,city.recent,city.annual,dateFormat(city.latest,'yyyy-mm-dd')]);
  arrayAppend(normalized,rows);
 }
 return normalized;
}
VARIABLES.template='/' ;URL={badges='',rua=true,trail=false,cupom=false,nacional=true,internacional=false,tag=''};
include 'baseline.cfm';baselineIds=listSort(valueList(qEventos.id_evento),'numeric');baseCount=qEventosBase.recordCount;
t=getTickCount();include 'candidate.cfm';coldMs=getTickCount()-t;
check(listSort(valueList(qEventos.id_evento),'numeric')==baselineIds,'default filters preserve all event IDs');
check(qEventosBase.recordCount==baseCount,'full catalogue preserved for other consumers');
// Compare both city builders on identical rows: SQL ties may reorder spellings of the same city between independent reads.
include 'baseline-city.cfm';expectedCities=citySignature(homeCityCatalog);
include 'candidate-city.cfm';actualCities=citySignature(homeCityCatalog);
for(gi=1;gi<=3;gi++){
 check(arrayLen(expectedCities[gi])==arrayLen(actualCities[gi]),'city group size preserved');
 for(ci=1;ci<=arrayLen(expectedCities[gi]);ci++)for(fi=1;fi<=7;fi++) {
  if(expectedCities[gi][ci][fi]!=actualCities[gi][ci][fi])throw(message='City mismatch',detail=serializeJSON({group=gi,row=ci,field=fi,expected=expectedCities[gi][ci],actual=actualCities[gi][ci]}));
 }
}
check(true,'cities and popular/recent ordering preserved');
t=getTickCount();include 'candidate.cfm';include 'candidate-city.cfm';warmMs=getTickCount()-t;
check(warmMs<1000,'warm backend and cities complete below one second');
for(filterCase in ['trail','international','coupon','badge']) {
 URL={badges='',rua=true,trail=false,cupom=false,nacional=true,internacional=false,tag=''};
 if(filterCase=='trail'){URL.rua=false;URL.trail=true;}
 if(filterCase=='international'){URL.nacional=false;URL.internacional=true;}
 if(filterCase=='coupon')URL.cupom=true;
 if(filterCase=='badge')URL.badges=qBadges.badge[1];
 include 'baseline.cfm';expectedIds=listSort(valueList(qEventos.id_evento),'numeric');
 include 'candidate.cfm';check(listSort(valueList(qEventos.id_evento),'numeric')==expectedIds,filterCase & ' filter preserves event IDs');
}
report={passed=true,checks=checks,coldMs=coldMs,warmMs=warmMs,eventCount=baseCount};
</cfscript>
