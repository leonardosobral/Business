<cfscript>
checks=[];
function check(required boolean ok,required string label){arrayAppend(checks,{name=label,passed=ok});if(!ok)throw(message=label);}
source=new profileServices.FixtureSource();
cold=createObject("component","profileServices.EventCatalogCache").init(source=source,ttlSeconds=2,retrySeconds=2);
data=cold.get();check(data.events.id_evento[1]==2,'first load returns actual data');
check(source.calls.get()==1,'first load performed once');
data.events.id_evento[1]=99;check(cold.get().events.id_evento[1]==2,'caller cannot mutate shared query');
source.mode='fail';sleep(2100);t=getTickCount();data=cold.get();check(getTickCount()-t<200,'expired data returned without waiting');
for(i=1;i<=20;i++)cold.get();sleep(650);
check(source.calls.get()==2,'one background refresh for competing reads');
check(cold.get().events.id_evento[1]==2,'failed refresh preserves data');
for(i=1;i<=20;i++)cold.get();check(source.calls.get()==2,'failed refresh backs off');
source.mode='invalid';sleep(2100);cold.get();sleep(650);check(cold.get().events.id_evento[1]==2,'invalid snapshot cannot replace good data');
source.mode='good';sleep(2100);cold.get();sleep(650);check(source.calls.get()==4,'refresh resumes after backoff');
failedSource=new profileServices.FixtureSource();failedSource.mode='fail';failedCold=createObject("component","profileServices.EventCatalogCache").init(source=failedSource,retrySeconds=2);
check(structIsEmpty(failedCold.get()),'cold failure reports unavailable');
for(i=1;i<=20;i++)failedCold.get();check(failedSource.calls.get()==1,'cold failures do not hammer database');
concurrentSource=new profileServices.FixtureSource();concurrentCache=createObject("component","profileServices.EventCatalogCache").init(source=concurrentSource);
key='testCold' & replace(createUUID(),'-','','all');APPLICATION[key]=concurrentCache;names=[];
try {
 for(i=1;i<=4;i++) {
  name='coldReader' & replace(createUUID(),'-','','all');arrayAppend(names,name);
  thread name=name cacheKey=key {thread.data=APPLICATION[attributes.cacheKey].get();}
 }
 thread action='join' name=arrayToList(names) timeout=5000;
 check(concurrentSource.calls.get()==1,'four concurrent cold readers share one database load');
 for(name in names)check(structKeyExists(cfthread[name],'data') && cfthread[name].data.totalResults.total[1]==42,'concurrent cold reader receives full snapshot');
} finally {structDelete(APPLICATION,key);}
report={passed=true,checks=checks};
</cfscript>
