component output=false {
    public any function init(string datasource="runner_dba"){variables.ds=arguments.datasource;variables.guard=new estudo.includes.SqlReadGuard();return this;}
    private query function db(required string sql,struct params={}){
        if(structIsEmpty(arguments.params)){
            var result=queryNew("");
            cfquery(name="local.result",datasource=variables.ds,timeout=50){writeOutput(preserveSingleQuotes(arguments.sql));}
            return isNull(local.result)?queryNew(""):local.result;
        }
        var response=queryExecute(arguments.sql,arguments.params,{datasource=variables.ds,timeout=50});
        return isNull(local.response)?queryNew(""):local.response;
    }
    private struct function p(required any value,string type="cf_sql_varchar"){return {value=arguments.value,cfsqltype=arguments.type};}
    private struct function idp(required any value){if(!reFind("^[1-9][0-9]{0,17}$",toString(arguments.value)))throw(type="Study.Validation",message="Identificador inválido.");return p(arguments.value,"cf_sql_bigint");}
    private array function rows(required query data){
        var out=[];var item={};var key="";var i=0;
        for(i=1;i<=data.recordCount;i++){item={};for(key in listToArray(data.columnList)){item[lCase(key)]=isNull(data[key][i])?"":data[key][i];if(listFind("id,cell_id,notebook_id,caderno_id,executed_by,saved_by,updated_by,frozen_by",lCase(key)))item[lCase(key)]=toString(item[lCase(key)]);}arrayAppend(out,item);}return out;
    }
    private struct function one(required query data){var records=rows(arguments.data);if(!arrayLen(records))throw(type="Study.Missing",message="Registro não encontrado.");return records[1];}
    private void function textLimit(required string value,required numeric max,boolean requiredValue=false){
        if(len(value)>max || (requiredValue && !len(trim(value))))throw(type="Study.Validation",message="Texto vazio ou acima do limite de "&max&" caracteres.");
    }
    private void function kind(required string type,required string lang){
        if(!((type=="markdown" && (lang=="" || lang=="markdown")) || (type=="code" && listFind("sql,html",lang))))throw(type="Study.Validation",message="Tipo de célula inválido.");
    }
    public array function listBooks(){
        return rows(db("SELECT c.id,c.titulo,c.ano,c.descricao,c.version,(SELECT count(*) FROM estudo.notebooks n WHERE n.caderno_id=c.id AND NOT n.archived) AS sections FROM estudo.cadernos c ORDER BY CASE WHEN c.source_key='legacy-runnerhub-2025' THEN 1 ELSE 0 END,c.id"));
    }
    public array function sections(required any bookId){return rows(db("SELECT notebook_id AS id,notebook_title AS title,version,tag,call_order FROM estudo.notebooks WHERE caderno_id=:id AND NOT archived ORDER BY call_order,notebook_id",{id=idp(bookId)}));}
    public struct function getNotebook(required any id){
        var section=one(db("SELECT notebook_id AS id,notebook_title AS title,caderno_id,version FROM estudo.notebooks WHERE notebook_id=:id AND NOT archived",{id=idp(id)}));
        section["cells"]=rows(db("SELECT id,cell_order,cell_type,coalesce(lang,'') AS lang,content,version,CAST(updated_at AS text),updated_by,CAST(origem AS text) AS origin_json FROM estudo.notebook_cells WHERE notebook_id=:id AND NOT archived ORDER BY cell_order,id",{id=idp(id)}));
        return section;
    }
    public struct function createBook(required string title,required numeric year,required any actor){
        textLimit(title,200,true);if(year<1900 || year>9999 || year!=int(year))throw(type="Study.Validation",message="Ano inválido.");
        return one(db("INSERT INTO estudo.cadernos(titulo,ano,criado_por,atualizado_por) VALUES(:t,:y,:a,:a) RETURNING id,titulo",{t=p(trim(title)),y=p(year,"cf_sql_smallint"),a=idp(actor)}));
    }
    public struct function saveBook(required any id,required numeric version,required string title,required any actor){
        textLimit(title,200,true);
        var result=db("UPDATE estudo.cadernos SET titulo=:t,version=version+1,atualizado_em=clock_timestamp(),atualizado_por=:a WHERE id=:id AND version=:v RETURNING id,titulo,version",{id=idp(id),v=p(version,"cf_sql_integer"),t=p(trim(title)),a=idp(actor)});
        if(!result.recordCount)throw(type="Study.Conflict",message="O caderno mudou. Recarregue antes de renomear.");
        return one(result);
    }
    public array function archivedCells(required any notebookId){
        return rows(db("SELECT id,version,cell_type,lang,content,CAST(updated_at AS text),updated_by FROM estudo.notebook_cells WHERE notebook_id=:id AND archived ORDER BY id",{id=idp(notebookId)}));
    }
    public struct function createNotebook(required any bookId,required string title,required any actor){
        textLimit(title,200,true);var result={};
        transaction {
            db("SELECT id FROM estudo.cadernos WHERE id=:id FOR UPDATE",{id=idp(bookId)});
            result=one(db("INSERT INTO estudo.notebooks(notebook_title,caderno_id,call_order,updated_by) SELECT :t,:id,coalesce(max(call_order),0)+1,:a FROM estudo.notebooks WHERE caderno_id=:id RETURNING notebook_id AS id,notebook_title AS title,version",{t=p(trim(title)),id=idp(bookId),a=idp(actor)}));
        }
        return result;
    }
    public struct function saveNotebook(required any id,required numeric version,required string title,required any actor){
        textLimit(title,200,true);
        var result=db("UPDATE estudo.notebooks SET notebook_title=:t,version=version+1,updated_at=clock_timestamp(),updated_by=:a WHERE notebook_id=:id AND version=:v AND NOT archived RETURNING notebook_id AS id,notebook_title AS title,version",{t=p(trim(title)),id=idp(id),v=p(version,"cf_sql_integer"),a=idp(actor)});
        if(!result.recordCount)throw(type="Study.Conflict",message="Esta seção mudou. Recarregue antes de salvar.");
        return one(result);
    }
    public struct function createCell(required any notebookId,required string type,required string lang,required string content,required any actor){
        kind(type,lang);textLimit(content,200000);var result={};
        transaction {
            one(db("SELECT notebook_id FROM estudo.notebooks WHERE notebook_id=:id AND NOT archived FOR UPDATE",{id=idp(notebookId)}));
            result=one(db("INSERT INTO estudo.notebook_cells(notebook_id,cell_order,cell_type,lang,content,updated_by,origem) SELECT :id,coalesce(max(cell_order),0)+1,:t,:l,:c,:a,CAST('{""tipo"":""business""}' AS jsonb) FROM estudo.notebook_cells WHERE notebook_id=:id RETURNING id,version,content",{id=idp(notebookId),t=p(type),l=p(lang),c=p(content,"cf_sql_longvarchar"),a=idp(actor)}));
        }return result;
    }
    public struct function saveCell(required any id,required numeric version,required string type,required string lang,required string content,required any actor){
        kind(type,lang);textLimit(content,200000);
        var result=db("UPDATE estudo.notebook_cells SET cell_type=:t,lang=:l,content=:c,updated_by=:a WHERE id=:id AND version=:v AND NOT archived RETURNING id,version,content,CAST(updated_at AS text)",{id=idp(id),v=p(version,"cf_sql_integer"),t=p(type),l=p(lang),c=p(content,"cf_sql_longvarchar"),a=idp(actor)});
        if(!result.recordCount)throw(type="Study.Conflict",message="Outra pessoa salvou esta célula. Seu texto continua no editor; copie-o e recarregue para comparar.");
        return one(result);
    }
    public struct function archiveCell(required any id,required numeric version,required boolean archived,required any actor){
        var result=db("UPDATE estudo.notebook_cells SET archived=:archived,updated_by=:a WHERE id=:id AND version=:v RETURNING id,version,archived",{id=idp(id),v=p(version,"cf_sql_integer"),archived=p(archived,"cf_sql_bit"),a=idp(actor)});
        if(!result.recordCount)throw(type="Study.Conflict",message="A célula mudou. Recarregue antes de arquivar.");
        return one(result);
    }
    public struct function reorderCells(required any notebookId,required array ids,required any actor){
        var i=0;var current=[];var seen={};
        transaction {
            one(db("SELECT notebook_id FROM estudo.notebooks WHERE notebook_id=:id FOR UPDATE",{id=idp(notebookId)}));
            current=rows(db("SELECT id FROM estudo.notebook_cells WHERE notebook_id=:id AND NOT archived ORDER BY id FOR UPDATE",{id=idp(notebookId)}));
            if(arrayLen(current)!=arrayLen(ids))throw(type="Study.Conflict",message="A lista de células mudou. Recarregue.");
            for(i=1;i<=arrayLen(ids);i++){idp(ids[i]);if(structKeyExists(seen,toString(ids[i])))throw(type="Study.Validation",message="Célula repetida.");seen[toString(ids[i])]=true;}
            for(var item in current)if(!structKeyExists(seen,item.id))throw(type="Study.Conflict",message="A lista de células mudou.");
            for(i=1;i<=arrayLen(ids);i++)db("UPDATE estudo.notebook_cells SET cell_order=:pos,updated_by=:a WHERE id=:id AND cell_order<>:pos",{pos=p(i,"cf_sql_integer"),a=idp(actor),id=idp(ids[i])});
        }return {saved=true};
    }
    public array function revisions(required any cellId){
        return rows(db("SELECT cell_id,version,cell_type,coalesce(lang,'') AS lang,content,archived,CAST(saved_at AS text),saved_by,content_sha256 FROM estudo.notebook_revisions WHERE cell_id=:id ORDER BY version DESC LIMIT 100",{id=idp(cellId)}));
    }
    public array function runs(required any notebookId){
        return rows(db("SELECT r.id,r.cell_id,r.cell_version,r.status,r.row_count,r.truncated,r.frozen,r.title,r.note,r.executed_by,CAST(r.started_at AS text),CAST(r.frozen_at AS text),r.duration_ms,r.error_message FROM estudo.notebook_runs r JOIN estudo.notebook_cells c ON c.id=r.cell_id WHERE c.notebook_id=:id ORDER BY r.id DESC LIMIT 100",{id=idp(notebookId)}));
    }
    public struct function getRun(required any runId){
        return one(db("SELECT id,cell_id,cell_version,sql_text,sql_sha256,executed_by,CAST(started_at AS text),CAST(finished_at AS text),duration_ms,status,CAST(result AS text) AS result_json,row_count,truncated,error_message,frozen,CAST(frozen_at AS text),frozen_by,title,note FROM estudo.notebook_runs WHERE id=:id",{id=idp(runId)}));
    }
    public struct function execute(required any cellId,required numeric version,required string sql,required any actor){
        var cell=one(db("SELECT id,content,version,cell_type,lang FROM estudo.notebook_cells WHERE id=:id AND NOT archived",{id=idp(cellId)}));
        if(cell.version!=version)throw(type="Study.Conflict",message="A célula mudou. Recarregue antes de executar.");
        if(cell.cell_type!="code" || cell.lang!="sql")throw(type="Study.Validation",message="Execute uma célula SQL.");
        var selected=trim(sql);
        if(!len(selected) || !find(selected,cell.content))throw(type="Study.Validation",message="Salve a célula antes de executar seu conteúdo ou uma seleção.");
        var safe=variables.guard.validate(selected);
        var run=one(db("INSERT INTO estudo.notebook_runs(cell_id,cell_version,sql_text,sql_sha256,executed_by,status) VALUES(:id,:v,:s,:h,:a,'running') RETURNING id",{id=idp(cellId),v=p(version,"cf_sql_integer"),s=p(selected,"cf_sql_longvarchar"),h=p(lCase(hash(selected,"SHA-256","UTF-8"))),a=idp(actor)}));
        var started=getTickCount();var resultJSON="";var count=0;var truncated=false;var errorMessage="";var columns=[];var payload=[];var names={};var i=0;
        try {
            transaction isolation="repeatable_read" {
                db("SET TRANSACTION READ ONLY");
                db("SET LOCAL ROLE estudo_reader");
                db("SET LOCAL search_path=pg_catalog,public");
                db("SET LOCAL statement_timeout='45s'");
                db("SET LOCAL lock_timeout='2s'");
                db("SET LOCAL standard_conforming_strings=on");
                var slot=db("SELECT pg_try_advisory_xact_lock(9282026,11) AS acquired");
                if(!slot.acquired[1]){slot=db("SELECT pg_try_advisory_xact_lock(9282026,12) AS acquired");if(!slot.acquired[1])throw(type="Study.Validation",message="Há duas consultas em execução. Aguarde e tente novamente.");}
                var sample=db("SELECT * FROM ("&safe&chr(10)&") AS estudo_source LIMIT 0");
                var meta=getMetaData(sample);var projected=[];
                if(arrayLen(meta)>100)throw(type="Study.Validation",message="O resultado excede 100 colunas. Selecione as colunas necessárias.");
                for(i=1;i<=arrayLen(meta);i++){
                    var name=meta[i].name;
                    if(structKeyExists(names,lCase(name)))throw(type="Study.Validation",message="Dê nomes diferentes às colunas do resultado: "&name&".");
                    names[lCase(name)]=true;arrayAppend(columns,name);arrayAppend(projected,'estudo_source."'&replace(name,'"','""',"all")&'"');
                }
                db("SELECT "&arrayToList(projected,",")&" FROM ("&safe&chr(10)&") AS estudo_source LIMIT 0");
                // Bound both row count and total payload in PostgreSQL before transferring to CF.
                var data=db("SELECT CASE WHEN sum(octet_length(row_json)) OVER (ORDER BY ordinal ROWS UNBOUNDED PRECEDING)<=5000000 THEN row_json ELSE '' END AS row_json FROM (SELECT row_to_json(estudo_source)::text AS row_json,row_number() OVER () AS ordinal FROM ("&safe&chr(10)&") AS estudo_source LIMIT 1001) AS estudo_payload ORDER BY ordinal");
                truncated=data.recordCount>1000;
                for(i=1;i<=min(data.recordCount,1000);i++){if(!len(data.row_json[i])){truncated=true;break;}arrayAppend(payload,data.row_json[i]);}
                count=arrayLen(payload);
                resultJSON='{"columns":'&serializeJSON(columns)&',"rows":['&arrayToList(payload,",")&']}';
            }
        }catch(any e){
            if(findNoCase("Study.",e.type)==1)errorMessage=e.message;
            else if(findNoCase("statement timeout",e.message&" "&e.detail) || findNoCase("timeout",e.message))errorMessage="A consulta ultrapassou 45 segundos. Reduza o período ou agregue os dados.";
            else errorMessage=left(reReplace(e.message&" "&e.detail,"[\r\n]+"," ","all"),1200);
        }
        var params={id=idp(run.id),ms=p(max(0,getTickCount()-started),"cf_sql_integer")};
        if(len(errorMessage)){
            params.e=p(errorMessage);
            db("UPDATE estudo.notebook_runs SET status='error',finished_at=clock_timestamp(),duration_ms=:ms,error_message=:e WHERE id=:id",params);
        }else{
            params.j=p(resultJSON,"cf_sql_longvarchar");params.n=p(count,"cf_sql_integer");params.t=p(truncated,"cf_sql_bit");
            db("UPDATE estudo.notebook_runs SET status='ok',finished_at=clock_timestamp(),duration_ms=:ms,result=CAST(:j AS jsonb),row_count=:n,truncated=:t WHERE id=:id",params);
        }
        return getRun(run.id);
    }
    public struct function freeze(required any runId,required string title,required string note,required any actor){
        textLimit(title,200,true);textLimit(note,10000);
        transaction {
            var run=one(db("SELECT id,status,truncated,frozen FROM estudo.notebook_runs WHERE id=:id FOR UPDATE",{id=idp(runId)}));
            if(run.frozen)return getRun(runId);
            if(run.status!="ok" || run.truncated)throw(type="Study.Validation",message="Somente resultados completos podem ser congelados. Refine a consulta e execute novamente.");
            db("UPDATE estudo.notebook_runs SET frozen=true,title=:t,note=:n,frozen_by=:a WHERE id=:id",{id=idp(runId),t=p(trim(title)),n=p(note,"cf_sql_longvarchar"),a=idp(actor)});
        }
        return getRun(runId);
    }
}
