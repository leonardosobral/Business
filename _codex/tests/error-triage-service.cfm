<cfscript>
function testDb(required string sql,struct params={}) {return queryExecute(sql,params,{datasource="runner_dba"});}
testSchema="triage_test_" & lCase(replace(createUUID(),"-","","all"));
testDb("CREATE SCHEMA " & testSchema);
try {
 migration=replace(fileRead(getDirectoryFromPath(getCurrentTemplatePath()) & "../sql/2026-09-26_error_triage.sql"),"public.",testSchema & ".","all");
 testDb(migration);testDb(migration);
 testDb("CREATE TABLE " & testSchema & ".tb_log(id_log integer PRIMARY KEY,log_item text,log_item_id text,site text,log_timestamp timestamp NOT NULL DEFAULT now())");
 svc=new portal.erros.includes.ErrorTriage().init("runner_dba",testSchema);
 triageAssert(svc.ready(),"Migration is repeatable and schema ready");
 for(i=1;i<=202;i++)testDb("INSERT INTO " & testSchema & ".tb_log(id_log,log_item,log_item_id,site) VALUES(:id,'erro',:payload,'RR')",{id={value=i,cfsqltype="cf_sql_integer"},payload=fixture(i).log_item_id});
 first=svc.collect(1);triageAssert(first.processed==200 && first.remaining,"Collection bounded at 200");
 triageAssert(testDb("SELECT count(*) AS n FROM " & testSchema & ".tb_error_occurrence WHERE id_log=202").n[1]==1 && testDb("SELECT count(*) AS n FROM " & testSchema & ".tb_error_occurrence WHERE id_log=1").n[1]==0,"Collector processes newest occurrences first");
 second=svc.collect(1);triageAssert(second.processed==2,"Next batch resumes");
 triageAssert(svc.collect(1).processed==0,"Reprocessing idempotent");
 data=svc.list({});triageAssert(data.total==1 && data.items.occurrences[1]==202,"Repeats share one persistent problem");
 id=data.items.id[1];d=svc.detail(id);version=d.problem.version[1];
 fields={status="published",category="database",title="Correção SQL",analysis="Análise interna <script>alert(1)</script>",proposal="Corrigir consulta",evidence="Publicação validada",published_at=dateTimeFormat(dateAdd('h',-1,now()),"yyyy-mm-dd HH:nn:ss"),owner_id="1",reason="Publicação de teste"};
 svc.save(id,version,fields,1);
 triageAssert(svc.detail(id).problem.status[1]=="published","Publication stored with evidence");
 stale=false;try{svc.save(id,version,fields,1);}catch(Triage.Conflict e){stale=true;}
 triageAssert(stale,"Stale edit rejected");
 testDb("INSERT INTO " & testSchema & ".tb_log(id_log,log_item,log_item_id,site,log_timestamp) VALUES(0,'erro',:payload,'RR',now()-interval '2 hours')",{payload=fixture(0).log_item_id});
 triageAssert(svc.collect(1).processed==1 && svc.detail(id).problem.status[1]=="published","Late low ID found without reopening older occurrence");
 testDb("INSERT INTO " & testSchema & ".tb_log(id_log,log_item,log_item_id,site) VALUES(203,'erro',:payload,'RR')",{payload=fixture(203).log_item_id});
 triageAssert(svc.collect(1).reopened==1,"Post-publication recurrence reopens");
 triageAssert(svc.detail(id).problem.category[1]=="database","Collection preserves human category");
 triageAssert(svc.collect(1).reopened==0,"Recurrence history not duplicated");
 d=svc.detail(id);fields.status="verified";fields.evidence="";
 invalid=false;try{svc.save(id,d.problem.version[1],fields,1);}catch(Triage.Validation e){invalid=true;}
 triageAssert(invalid && svc.detail(id).problem.status[1]=="reopened","Verification needs evidence and failed edit is atomic");
 split=svc.splitOccurrence(203,d.problem.version[1],"Separar para investigar",1,id);
 triageAssert(svc.detail(split).problem.occurrences[1]==1 && svc.detail(id).problem.occurrences[1]==203,"Manual split recounts both problems");
 staleSource=false;
 try{svc.moveOccurrence(203,id,svc.detail(split).problem.version[1],svc.detail(id).problem.version[1],"Stale source",1,id);}catch(Triage.Conflict e){staleSource=true;}
 triageAssert(staleSource && svc.detail(split).problem.occurrences[1]==1,"Equal versions cannot authorize a move from a different source");
 svc.moveOccurrence(203,id,svc.detail(split).problem.version[1],svc.detail(id).problem.version[1],"Mesmo defeito",1,split);
 triageAssert(svc.detail(id).problem.occurrences[1]==204 && svc.detail(split).problem.occurrences[1]==0,"Manual move preserves empty audit record");
 packet=svc.exportProblems([id,id]);triageAssert(arrayLen(packet.problems)==1 && find("token=secret",packet.problems[1].samples[1].original_log),"Admin export includes original evidence without duplicating problems");
 triageAssert(packet.problems[1].analysis==fields.analysis && packet.problems[1].title==fields.title && packet.problems[1].proposal==fields.proposal,"Admin export preserves title and investigation notes");
 for(extra in [204,205])testDb("INSERT INTO " & testSchema & ".tb_log(id_log,log_item,log_item_id,site) VALUES(:id,'erro',:payload,'RR')",{id={value=extra,cfsqltype="cf_sql_integer"},payload=fixture(extra).log_item_id});
 workerNames="triageA" & replace(createUUID(),"-","","all") & ",triageB" & replace(createUUID(),"-","","all");
 for(workerName in listToArray(workerNames)) {
   thread name=workerName action="run" schema=testSchema {
     worker=new portal.erros.includes.ErrorTriage().init("runner_dba",attributes.schema);
     thread.collected=worker.collect(1);
   }
 }
 thread action="join" name=workerNames timeout=30000;
 for(workerName in listToArray(workerNames))triageAssert(cfthread[workerName].status=="COMPLETED","Concurrent collector completes: " & workerName);
 triageAssert(svc.detail(id).problem.occurrences[1]==206,"Concurrent collectors link each occurrence exactly once");
 // Render the actual workspace with synthetic profile data in the same transaction.
 testDb("CREATE TABLE " & testSchema & ".tb_usuarios(id integer,name text,is_admin boolean)");
 testDb("INSERT INTO " & testSchema & ".tb_usuarios VALUES(1,'Administrador de teste',true)");
 transaction {
 testDb("SET LOCAL search_path TO " & testSchema & ",public");
 VARIABLES.requireAdminAllowed=true;
 SESSION={};URL={problem_id=id};FORM={};
 include "../../portal/erros/includes/init.cfm";
 etService=svc;etReady=true;etProblemId=id;
 savecontent variable="rendered" {include "../../portal/erros/includes/workspace.cfm";}
 triageAssert(find("Salvar acompanhamento",rendered)>0 && find("Ocorrências vinculadas",rendered)>0,"Real workspace renders detail, forms and history");
 triageAssert(!find('value="secret"',rendered),"Synthetic secret absent from workspace");
 // Use the actual HTML option values, not hand-written enum values.
 statusOption=reFindNoCase('<option value="([^"]+)"[^>]*>Publicado</option>',rendered,1,true);
 categoryOption=reFindNoCase('<option value="([^"]+)"[^>]*>Banco / SQL</option>',rendered,1,true);
 browserFields=duplicate(fields);browserFields.status=mid(rendered,statusOption.pos[2],statusOption.len[2]);browserFields.category=mid(rendered,categoryOption.pos[2],categoryOption.len[2]);browserFields.evidence="Synthetic publication validated";
 svc.save(id,svc.detail(id).problem.version[1],browserFields,1);
 triageAssert(svc.detail(id).problem.status[1]=="published","Actual browser option values accepted and stored canonically");
 browserFields.status="VERIFIED";browserFields.category="DATABASE";
 svc.save(id,svc.detail(id).problem.version[1],browserFields,1);
 triageAssert(svc.detail(id).problem.status[1]=="verified","Previously open uppercase forms remain compatible");
 triageAssert(find('type="datetime-local"',rendered) && find(encodeForHTML(replace(svc.detail(id).problem.published_text[1]," ","T")),rendered),"Treatment preserves stored publication time in native date field");
 etProblemId=split;
 savecontent variable="newTimeRendered" {include "../../portal/erros/includes/workspace.cfm";}
 triageAssert(find('value="' & encodeForHTML(replace(etQueue.collector.database_now[1]," ","T")) & '"',newTimeRendered),"Unpublished problem suggests database time, not browser timezone");
 structDelete(VARIABLES,"FORM");
 FORM.triage_action="save";FORM.published_at="2026-09-20T10:12:13";
 savecontent variable="retryTimeRendered" {include "../../portal/erros/includes/workspace.cfm";}
 triageAssert(find('value="' & encodeForHTML('2026-09-20T10:12:13') & '"',retryTimeRendered),"Retry preserves user-edited publication timestamp");
 structDelete(FORM,"triage_action");structDelete(FORM,"published_at");etProblemId=id;


 triageAssert(!find("<script>alert(1)</script>",rendered) && find("&lt;script&gt;",rendered),"Human notes render as escaped text");
 if(structKeyExists(REQUEST,"triageSavePreview") && REQUEST.triageSavePreview)fileWrite(getDirectoryFromPath(getCurrentTemplatePath()) & "../../rendered.html",rendered);
 }
testDb("INSERT INTO " & testSchema & ".tb_log(id_log,log_item,log_item_id,site) VALUES(300,'404',:payload,'RR')",{payload="/" & repeatString("x/",100)});
 triageAssert(svc.list({}).pendingLogs==1,"Pending count reports remaining logs");
 triageAssert(svc.collect(1).processed==1 && svc.list({}).pendingLogs==0,"Expanded 404 path no longer blocks a whole batch");
 target404=testDb("SELECT problem_id FROM " & testSchema & ".tb_error_occurrence WHERE id_log=300").problem_id[1];
 testDb("UPDATE " & testSchema & ".tb_error_occurrence SET path='/{omitido}' WHERE id_log=300");
 recovered=svc.detail(target404);export404=svc.exportProblems([target404]);
 triageAssert(recovered.occurrences.path[1]=="/" & repeatString("x/",100),"Previously omitted path restored from original log on read");
 triageAssert(export404.problems[1].samples[1].path==recovered.occurrences.path[1] && export404.problems[1].title=="Página não encontrada","Existing 404 export preserves title and original path");
 testDb("UPDATE " & testSchema & ".tb_log SET log_item_id=:payload WHERE id_log=300",{payload="/" & repeatString("long/",100) & "?q=<script>alert(1)</script>"});
 fullEvidence=svc.detail(target404);
 queueEvidence=svc.list({category="not_found"});
 triageAssert(queueEvidence.items.resource_path[1]==fullEvidence.occurrences.path[1],"Queue recovers original 404 path instead of old masked summary");
 etProblemId=0;etFilters={scope="recent",status="",category="not_found",site="",page=1};
 savecontent variable="queueRendered" {include "../../portal/erros/includes/workspace.cfm";}
 triageAssert(find("Recurso:",queueRendered) && find(encodeForHTML(right(fullEvidence.occurrences.path[1],180)),queueRendered) && !find("<script>alert(1)</script>",queueRendered),"Queue shows the end of long resource paths and escapes hostile log text");
 triageAssert(len(fullEvidence.occurrences.path[1])>320 && find("<script>",fullEvidence.occurrences.original_log[1]),"Admin detail recovers full original beyond stored summary limit");
 etProblemId=target404;
 savecontent variable="originalRendered" {include "../../portal/erros/includes/workspace.cfm";}
 triageAssert(!find("<script>alert(1)</script>",originalRendered) && find("&lt;script&gt;",originalRendered),"Original log is displayed as escaped text, never executable HTML");
 testDb("DELETE FROM " & testSchema & ".tb_log WHERE id_log=300");
 missingOriginal=svc.detail(target404);
 triageAssert(svc.list({category="not_found"}).items.resource_path[1]=="/{omitido}","Queue retains stored path when original log is absent");
 triageAssert(!missingOriginal.occurrences.original_available[1] && missingOriginal.occurrences.recordCount==1,"Missing original keeps stored evidence and occurrence accessible");
 testDb("UPDATE " & testSchema & ".tb_error_problem SET last_seen=now()-interval '10 days' WHERE id=:id",{id={value=split,cfsqltype="cf_sql_bigint"}});
 recent=svc.list({});allHistory=svc.list({scope="all"});
 triageAssert(allHistory.total==recent.total+1,"Older problems preserved and accessible through history filter");
 triageAssert(svc.detail(split).problem.recordCount==1,"Historic problem remains directly accessible");
 testDb("INSERT INTO " & testSchema & ".tb_log(id_log,log_item,log_item_id,site,log_timestamp) VALUES(301,'404','/old-only','RR',now()-interval '10 days')");
 triageAssert(svc.collect(1).processed==0,"Collector does not consume logs before cutoff");

 // Missing-image view reads original 404s, including logs not yet collected.
 imageFixtures=[
 {id=400,site="RR",path="/apple-touch-icon-precomposed.png?v=1"},
 {id=401,site="RR",path="https://roadrunners.run/apple-touch-icon-precomposed.png?v=2"},
 {id=402,site="BUS",path="/apple-touch-icon-precomposed.png"},
 {id=403,site="RR",path="/Fotos/Prova.JPG"},
 {id=404,site="RR",path="/fake.png.php"},
 {id=405,site="RR",path="/search?q=photo.png"},
 {id=406,site="RR",path="/<script>alert(1)</script>.svg"}
 ];
 for(img in imageFixtures)testDb("INSERT INTO " & testSchema & ".tb_log(id_log,log_item,log_item_id,site) VALUES(:id,'404',:path,:site)",{id={value=img.id,cfsqltype="cf_sql_integer"},path=img.path,site=img.site});
 testDb("INSERT INTO " & testSchema & ".tb_log VALUES(407,'404','/old.png','RR',now()-interval '10 days'),(408,'erro','/not-404.png','RR',now())");
 images=svc.missingImages({site="RR",sort="frequency"});
 triageAssert(images.total==3 && images.occurrences==4,"Missing images exclude old logs, other sites, errors and misleading extensions");
 triageAssert(images.items.path[1]=="/apple-touch-icon-precomposed.png" && images.items.occurrences[1]==2,"Image variants share exact path without query string");
 triageAssert(svc.missingImages({}).total==4,"Same path on different sites stays separate");
 triageAssert(svc.missingImages({site="none"}).total==0 && svc.missingImages({site="none",page=999}).page==1,"Empty image view clamps page safely");
 triageAssert(testDb("SELECT count(*) AS n FROM " & testSchema & ".tb_error_occurrence WHERE id_log>=400").n[1]==0,"Image view does not require or change collection state");
 URL={image_site="RR",image_sort="frequency"};
 savecontent variable="imagesRendered" {include "../../portal/erros/includes/images.cfm";}
 triageAssert(find(encodeForHTML("/apple-touch-icon-precomposed.png"),imagesRendered) && !find("<script>alert(1)</script>",imagesRendered) && find("&lt;script&gt;",imagesRendered),"Image list preserves paths as escaped text");
 for(i=500;i<=525;i++)testDb("INSERT INTO " & testSchema & ".tb_log(id_log,log_item,log_item_id,site,log_timestamp) VALUES(:id,'404',:path,'RR',now()+:seconds * interval '1 second')",{id={value=i,cfsqltype="cf_sql_integer"},path="/page-" & i & ".webp",seconds={value=i,cfsqltype="cf_sql_integer"}});
 imagesPage=svc.missingImages({site="RR",page=999});
 triageAssert(imagesPage.total==29 && imagesPage.page==2 && imagesPage.items.recordCount==4,"Image pagination includes all paths and clamps out-of-range pages");
 triageAssert(svc.missingImages({site="RR"}).items.path[1]=="/page-525.webp","Image view defaults to newest occurrence first");
} finally {testDb("DROP SCHEMA " & testSchema & " CASCADE");}
</cfscript>
