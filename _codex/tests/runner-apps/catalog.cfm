<cfsetting showdebugoutput="false" requesttimeout="20"/>
<cfscript>
checks=[];function check(required boolean ok,required string label){arrayAppend(checks,{name=label,passed=ok});if(!ok)throw(type='Test.Failed',message=label);}
schema='runner_apps_test_' & lCase(replace(createUUID(),'-','','all'));
function db(required string sql){return queryExecute(sql,{},{datasource='runner_dba'});}
db('CREATE SCHEMA ' & schema);
try {
    db('CREATE TABLE ' & schema & '.tb_portal_runner_app_groups(id_group integer,nome text,descricao text,ordem integer,itens_por_linha integer,ativo boolean)');
    db('CREATE TABLE ' & schema & '.tb_portal_runner_apps(id_app integer,id_group integer,nome text,url text,imagem_url text,alt_text text,abrir_nova_aba boolean,rel text,ordem integer,ativo boolean)');
    db("INSERT INTO " & schema & ".tb_portal_runner_app_groups VALUES (1,'First',null,2,3,true),(2,'Second','Description',1,4,true),(3,'Hidden','Secret',0,3,false)");
    db("INSERT INTO " & schema & ".tb_portal_runner_apps VALUES (1,1,'First app','/','/image.png',null,false,null,1,true),(2,2,'Second app','https://example.test','https://example.test/a.png','Alt',true,'noopener',1,true),(3,1,'Hidden app','/hidden','','',false,'',0,false),(4,3,'Hidden group app','/secret','','',false,'',0,true)");
    svc=createObject('component','runnerAppsCatalog.Catalog').init('runner_dba',schema);
    data=svc.read();
    check(arrayLen(data.items)==2,'hidden apps and hidden groups excluded');
    check(data.groups[1].id==2 && data.items[1].id==2,'group and item ordering preserved');
    check(data.items[2].imgSrc=='https://business.roadrunners.run/image.png','relative image URLs keep original asset host');
    check(data.items[2].imgAlt=='First app' && data.items[2].rel=='','nullable labels and rel remain compatible');
    check(data.items[1].target=='_blank','external target preserved');
    data=svc.read('principal');check(arrayLen(data.items)==1 && data.items[1].id==1,'principal filter returns first group only');
    rejected=false;try{svc.read('injected');}catch(RunnerApps.InvalidLine e){rejected=true;}
    check(rejected,'unknown line rejected');
    db('DELETE FROM ' & schema & '.tb_portal_runner_apps');data=svc.read();check(data.success && arrayLen(data.items)==0,'valid empty catalogue returned');
    cfcontent(type='application/json',reset=true);writeOutput(serializeJSON({passed=true,checks=checks}));
} finally {db('DROP SCHEMA ' & schema & ' CASCADE');}
</cfscript>
