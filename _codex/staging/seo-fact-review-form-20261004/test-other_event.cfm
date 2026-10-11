<cfscript>
service=createObject('component',testComponent);
checks=[];
function check(required string name,required boolean passed){arrayAppend(checks,{name=name,passed=passed});if(!passed)throw(message='Failed: ' & name);}
function rejects(required string name,required any fn){var rejected=false;try{fn();}catch(FactReview e){rejected=true;}check(name,rejected);}
requestToken=function(){return createObject('java','java.util.UUID').randomUUID().toString();};
data=service.load(37570,true,false);
check('Three explicit review groups',structCount(data.snapshots)==3);
check('Exact date version',reFind('^[a-f0-9]{32}$',data.versions.datas)>0);
check('Private schema ready',service.isSchemaReady());
submission={grupo='datas',source_url='https://www.liverun.com.br/etapa/live21k-fortaleza-2026',version=data.versions.datas,request_id=requestToken(),confirmed='1'};
service.save(37570,submission,true,false,true,true);submission.version=service.load(37526,true,false).versions.datas;rejects('Request cannot change event',function(){service.save(37526,submission,true,false,true,true);});
report={checks=checks};
</cfscript>
