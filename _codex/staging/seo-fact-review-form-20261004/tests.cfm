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
rejects('No read for nonadmin',function(){service.load(37570,false,false);});
rejects('No read for delegated admin',function(){service.load(37570,true,true);});
rejects('No write for nonadmin',function(){service.save(37570,submission,false,false,true,true);});
rejects('No write for delegated admin',function(){service.save(37570,submission,true,true,true,true);});
rejects('No GET write',function(){service.save(37570,submission,true,false,false,true);});
rejects('No CSRF write',function(){service.save(37570,submission,true,false,true,false);});
for(badId in ['0','-1','1.5','1e3','37570 OR 1=1','2147483648','']){testId=badId;rejects('Invalid ID ' & badId,function(){service.load(testId,true,false);});}
for(badUrl in ['javascript:alert(1)','data:text/html,abc','//example.com','https://user:password@example.com','https://example.com' & chr(10) & 'x','https://example.com/a b','https:\example.com','https://']){testSubmission=duplicate(submission);testSubmission.source_url=badUrl;rejects('Invalid source ' & left(badUrl,35),function(){service.save(37570,testSubmission,true,false,true,true);});}
for(field in ['grupo','source_url','version','request_id','confirmed']){testSubmission=duplicate(submission);structDelete(testSubmission,field);rejects('Missing ' & field,function(){service.save(37570,testSubmission,true,false,true,true);});}
for(pair in [{key='grupo',value='inscricoes'},{key='grupo',value='DATAS'},{key='confirmed',value='0'},{key='request_id',value='invalid'}]){testSubmission=duplicate(submission);testSubmission[pair.key]=pair.value;rejects('Invalid field ' & pair.key & pair.value,function(){service.save(37570,testSubmission,true,false,true,true);});}
service.save(37570,submission,true,false,true,true);
q=queryExecute("SELECT * FROM public.tb_evento_fatos_revisao WHERE id_evento=37570");
check('One review inserted',q.recordCount==1);
check('Source saved exactly',compare(q.fonte_url,submission.source_url)==0);
check('Server review date',isDate(q.registrado_em));
check('Approved exact snapshot',service.load(37570,true,false).reviews.matches);
service.save(37570,submission,true,false,true,true);
check('Duplicate post is idempotent',queryExecute('SELECT count(*) n FROM public.tb_evento_fatos_revisao').n==1);
queryExecute('SAVEPOINT fact_change');
queryExecute('UPDATE public.tb_evento_corridas SET data_final=data_final+1 WHERE id_evento=37570');
check('Changed current date is stale',!service.load(37570,true,false).reviews.matches);

check('Change log includes changed field',service.load(37570,true,false).history.recordCount>0);
queryExecute('ROLLBACK TO SAVEPOINT fact_change');
check('Rolled back source matches again',service.load(37570,true,false).reviews.matches);
for(group in ['local','situacao']) {testSubmission=duplicate(submission);testSubmission.grupo=group;testSubmission.version=data.versions[group];testSubmission.request_id=requestToken();service.save(37570,testSubmission,true,false,true,true);}
check('All groups save separately',queryExecute('SELECT count(*) n FROM public.tb_evento_fatos_revisao').n==3);
rejects('Revoke nonadmin denied',function(){service.revoke(37570,q.id_revisao,false,false,true,true);});
rejects('Revoke delegated denied',function(){service.revoke(37570,q.id_revisao,true,true,true,true);});
rejects('Revoke GET denied',function(){service.revoke(37570,q.id_revisao,true,false,false,true);});
rejects('Revoke CSRF denied',function(){service.revoke(37570,q.id_revisao,true,false,true,false);});
service.revoke(37526,q.id_revisao,true,false,true,true);
check('Other event cannot revoke this review',!queryExecute('SELECT revogado_em IS NOT NULL revoked FROM public.tb_evento_fatos_revisao WHERE id_revisao=' & int(q.id_revisao)).revoked);
service.revoke(37570,q.id_revisao,true,false,true,true);
check('Revoke marks original row',queryExecute('SELECT revogado_em IS NOT NULL revoked FROM public.tb_evento_fatos_revisao WHERE id_revisao=' & int(q.id_revisao)).revoked);
check('Revoke preserves snapshots and source',queryExecute('SELECT count(*) n FROM public.tb_evento_fatos_revisao').n==3);

check('Null displayed explicitly',service.displayValue({},'missing')=='Não informado');
check('Output left for view escaping',service.displayValue({city='<script>'},'city')=='<script>');
acl=queryExecute("SELECT NOT has_table_privilege('runner','public.tb_evento_fatos_revisao','SELECT,INSERT,UPDATE,DELETE') AND NOT has_sequence_privilege('runner','public.tb_evento_fatos_revisao_id_revisao_seq','SELECT,USAGE,UPDATE') AS private");
check('Private real table and sequence',acl.private);
report={checks=checks};
</cfscript>
