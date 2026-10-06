<cfsetting requesttimeout="40" showdebugoutput="false"/>
<cfscript>
checks=[];
function check(required boolean ok,required string label){arrayAppend(checks,{name=label,passed=ok});if(!ok)throw(type='Test.Failed',message=label);}
source=new fixtures.FixtureSource();
old={success=true,groups=[],items=[{label='last-known',href='/'}]};
cache=createObject("component","services.RunnerAppsMenuCache").init(source=source,ttlSeconds=2,retrySeconds=2,initialPayload=old);
t=getTickCount();data=cache.get();
check(data.items[1].label=='last-known','stale data served while refresh runs');
check(getTickCount()-t LT 300,'caller does not wait for delayed source');
for(i=1;i LTE 30;i++)cache.get();
deadline=getTickCount()+4000;while(getTickCount() LT deadline && cache.get().items[1].label!='fresh')sleep(50);
check(source.calls.get()==1,'one refresh for competing reads');
data=cache.get();check(data.items[1].label=='fresh','background refresh updates shared cache');
data.items[1].label='corruption';check(cache.get().items[1].label=='fresh','callers cannot mutate shared payload');
source.mode='fail';sleep(2200);cache.get();sleep(800);
check(cache.get().items[1].label=='fresh','failure retains last valid result');
for(i=1;i LTE 20;i++)cache.get();
check(source.calls.get()==2,'failed source not retried by each page');
source.mode='invalid';sleep(2200);cache.get();sleep(800);
check(cache.get().items[1].label=='fresh','malformed response does not poison cache');
source.mode='empty';sleep(2200);cache.get();sleep(800);
data=cache.get();check(arrayLen(data.items)==0,'valid empty catalogue replaces stale items');
source2=new fixtures.FixtureSource();cold=createObject("component","services.RunnerAppsMenuCache").init(source2);
t=getTickCount();data=cold.get();check(structIsEmpty(data),'cold request immediately allows local fallback');check(getTickCount()-t LT 300,'cold start does not wait for HTTP');
deadline=getTickCount()+4000;while(getTickCount() LT deadline && !structKeyExists(cold.get(),'success'))sleep(50);check(cold.get().items[1].label=='fresh','cold cache fills in background');
cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({passed=true,checks=checks}));
</cfscript>
