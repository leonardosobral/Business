component output=false {
    variables.directory="/var/lib/runnerhub/openai-usage";variables.datasource="runner_dba";
    public any function init(string directory="/var/lib/runnerhub/openai-usage",string datasource="runner_dba"){variables.directory=directory;variables.datasource=datasource;return this;}
    public string function localDateKey(required numeric ms){return createObject("java","java.time.Instant").ofEpochMilli(javacast("long",ms)).atZone(createObject("java","java.time.ZoneId").of("America/Sao_Paulo")).toLocalDate().toString() & "";}
    private numeric function boundary(required any date){return date.atStartOfDay(createObject("java","java.time.ZoneId").of("America/Sao_Paulo")).toInstant().toEpochMilli();}
    public struct function filters(required struct input){
        var f={period="7",module="all",model="",status="all",page=1};
        for(var key in f)if(structKeyExists(input,key)){
            if(!isSimpleValue(input[key]) OR len(input[key] & "") GT 100)throw(type="OpenAIUsage.Filter",message="Filtros inválidos.");
            f[key]=trim(input[key] & "");
        }
        if(!listFind("7,30,90,custom",f.period) OR (f.module NEQ "all" AND !structKeyExists(new services.openaiUsage.Catalog().modules(),f.module)) OR !listFind("all,success,error,incomplete",f.status) OR !reFind("^[1-9][0-9]{0,3}$",f.page) OR (len(f.model) AND (!reFind("^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$",f.model) OR findNoCase("sk-",f.model))))throw(type="OpenAIUsage.Filter",message="Filtros inválidos.");
        f.page=val(f.page);
        try{
            var dates=createObject("java","java.time.LocalDate");var today=dates.now(createObject("java","java.time.ZoneId").of("America/Sao_Paulo"));
            var finish=today;var start=today.minusDays(javacast("long",f.period EQ "custom" ? 6 : val(f.period)-1));
            if(f.period EQ "custom"){
                for(key in ["start","end"])if(!structKeyExists(input,key) OR !isSimpleValue(input[key]) OR !reFind("^\d{4}-\d{2}-\d{2}$",input[key]))throw(message="date");
                start=dates.parse(input.start);finish=dates.parse(input.end);
            }
            f.start=start.toString() & "";f.end=finish.toString() & "";f.fromMs=boundary(start);f.toMs=boundary(finish.plusDays(javacast("long",1)));
            if(f.toMs LTE f.fromMs OR f.toMs-f.fromMs GT 90*86400000 OR start.isBefore(dates.of(2020,1,1)) OR finish.isAfter(today))throw(message="range");
        }catch(any invalidDate){throw(type="OpenAIUsage.Filter",message="Informe um período válido, de até 90 dias e sem datas futuras.");}
        return f;
    }
    public struct function ledger(required struct f){
        var result={rows=[],warnings=[],available=directoryExists(variables.directory),cutoff=f.toMs,trackedSince=0};
        if(!result.available){arrayAppend(result.warnings,"A coleta detalhada ainda não está disponível neste servidor.");return result;}
        result.cutoff=0;
        var validMarker=false;
        try{
            var marker=variables.directory & "/tracking.json";
            if(fileExists(marker)){
                var settings=deserializeJSON(fileRead(marker,"utf-8"));
                if(isStruct(settings) AND structKeyExists(settings,"since_ms") AND isNumeric(settings.since_ms) AND settings.since_ms GT 0 AND settings.since_ms LTE createObject("java","java.lang.System").currentTimeMillis()){
                    result.trackedSince=settings.since_ms+0;result.cutoff=min(f.toMs,result.trackedSince);validMarker=true;
                }
            }
        }catch(any invalidMarker){}
        if(!validMarker)arrayAppend(result.warnings,"Marco de ativação ausente ou inválido. O histórico antigo foi omitido para evitar duplicação com o diário.");
        try{
            var files=directoryList(variables.directory,false,"query","*.jsonl");var bytes=0;var invalid=0;var limited=false;
            for(var file in files){
                if(!reFind("^\d{4}-\d{2}-\d{2}\.jsonl$",file.name))continue;
                var fileDate=left(file.name,10);
                if(fileDate LT f.start OR fileDate GT dateFormat(dateAdd("d",1,parseDateTime(f.end)),"yyyy-mm-dd"))continue;
                if(file.size GT 8388608 OR bytes+file.size GT 33554432){limited=true;continue;}
                bytes+=file.size;var snapshot="";
                lock name="rr-openai-usage-" & hash(variables.directory) type="readonly" timeout=2 {snapshot=fileRead(variables.directory & "/" & file.name,"utf-8");}
                for(var rawLine in listToArray(snapshot,chr(10))){
                        var line=trim(rawLine);if(!len(line))continue;
                        try{
                            if(len(line) GT 3000 OR !isJSON(line))throw(message="invalid");
                            var row=deserializeJSON(line);
                            if(!validRow(row))throw(message="invalid");
                            if(row.at_ms GTE max(f.fromMs,result.trackedSince) AND row.at_ms LT f.toMs)arrayAppend(result.rows,row);
                        }catch(any badLine){invalid++;}
                }
            }
            if(invalid)arrayAppend(result.warnings,invalid & " registro(s) do diário não puderam ser lidos. Os totais são parciais.");
            if(limited)arrayAppend(result.warnings,"O limite seguro de leitura do diário foi atingido. Reduza o período; os totais estão parciais.");
        }catch(any unavailable){arrayAppend(result.warnings,"Não foi possível ler parte do diário de consumo. Os totais estão parciais.");}
        return result;
    }
    private boolean function validRow(required any row){
        if(!isStruct(row))return false;
        for(var field in ["schema_version","id","at_ms","module","operation","model","status","http_status","tokens_known","input_tokens","output_tokens","cached_tokens","write_30m_tokens","write_12h_tokens","cost_known","estimated_usd","partial_cost","source"])if(!structKeyExists(row,field) OR !isSimpleValue(row[field]))return false;
        if(row.schema_version NEQ 1 OR row.source NEQ "ledger" OR !structKeyExists(new services.openaiUsage.Catalog().modules(),row.module) OR !listFind("success,error,incomplete",row.status) OR !reFind("^[A-Za-z0-9._-]{1,100}$",row.id) OR !reFind("^[A-Za-z0-9._-]{1,100}$",row.model) OR !reFind("^[A-Za-z0-9._-]{1,100}$",row.operation))return false;
        for(field in ["tokens_known","cost_known","partial_cost"])if(!isBoolean(row[field]))return false;
        for(field in ["at_ms","http_status","input_tokens","output_tokens","cached_tokens","write_30m_tokens","write_12h_tokens","estimated_usd"])if(!isNumeric(row[field]) OR row[field] LT 0 OR row[field] GT 9007199254740991)return false;
        if(row.http_status GT 599 OR row.estimated_usd GT 100000 OR (row.cost_known AND !row.tokens_known))return false;
        if(row.tokens_known AND row.cached_tokens+row.write_30m_tokens+row.write_12h_tokens GT row.input_tokens)return false;
        return true;
    }
    private struct function empty(){return {records=0,requests=0,legacy=0,measured=0,unknown=0,input=0,output=0,tokens=0,cached=0,write30=0,write12=0,usd=0,unpriced=0,partial=0,errors=0};}
    private void function add(required struct total,required struct row){
        total.records++;if(row.source EQ "ledger")total.requests++;else total.legacy++;
        if(row.status NEQ "success")total.errors++;
        if(row.tokens_known){total.measured++;total.input+=row.input_tokens;total.output+=row.output_tokens;total.tokens+=row.input_tokens+row.output_tokens;total.cached+=row.cached_tokens;total.write30+=row.write_30m_tokens;total.write12+=row.write_12h_tokens;}else total.unknown++;
        if(row.cost_known){total.usd+=row.estimated_usd;if(row.partial_cost)total.partial++;}else total.unpriced++;
    }
    public struct function summarize(required array rows,required struct f){
        var out={summary=empty(),modules=[],days=[],history=[],models=[],totalRows=0,hasNext=false};var modules={};var days={};var selected=[];var seen={};var modelSet={};var catalog=new services.openaiUsage.Catalog().modules();
        for(var key in catalog){modules[key]=empty();modules[key].id=key;modules[key].label=catalog[key].label;modules[key].url=catalog[key].url;}
        for(var row in rows){
            if(!structKeyExists(modules,row.module) OR row.at_ms LT f.fromMs OR row.at_ms GTE f.toMs)continue;
            if(!structKeyExists(row,"source"))row.source="legacy";
            var identity=row.source & ":" & row.id;if(structKeyExists(seen,identity))continue;seen[identity]=true;
            modelSet[row.model]=true;
            if((f.module NEQ "all" AND row.module NEQ f.module) OR (len(f.model) AND row.model NEQ f.model) OR (f.status NEQ "all" AND row.status NEQ f.status))continue;
            row.day=localDateKey(row.at_ms);row.label=modules[row.module].label;
            add(out.summary,row);add(modules[row.module],row);
            if(!structKeyExists(days,row.day)){days[row.day]=empty();days[row.day].day=row.day;}
            add(days[row.day],row);arrayAppend(selected,row);
        }
        for(key in modules)if(f.module EQ "all" OR f.module EQ key)arrayAppend(out.modules,modules[key]);
        arraySort(out.modules,function(a,b){if(a.usd NEQ b.usd)return a.usd GT b.usd ? -1 : 1;if(a.tokens NEQ b.tokens)return a.tokens GT b.tokens ? -1 : 1;return compareNoCase(a.label,b.label);});
        var cursor=createObject("java","java.time.LocalDate").parse(f.start);var finish=createObject("java","java.time.LocalDate").parse(f.end);
        while(!cursor.isAfter(finish)){key=cursor.toString() & "";var d=structKeyExists(days,key) ? days[key] : empty();d.day=key;arrayAppend(out.days,d);cursor=cursor.plusDays(javacast("long",1));}
        arraySort(selected,function(a,b){return a.at_ms EQ b.at_ms ? compare(a.id,b.id) : (a.at_ms GT b.at_ms ? -1 : 1);});out.totalRows=arrayLen(selected);out.hasNext=out.totalRows GT f.page*50;
        for(var i=(f.page-1)*50+1;i LTE min(out.totalRows,f.page*50);i++)arrayAppend(out.history,selected[i]);
        if(len(f.model))modelSet[f.model]=true;
        out.models=structKeyArray(modelSet);arraySort(out.models,"textnocase");return out;
    }
    public struct function report(required struct f){
        var log=ledger(f);var legacy=new services.openaiUsage.Legacy(variables.datasource).load(f,log.cutoff);
        var rows=log.rows;for(var row in legacy.rows)arrayAppend(rows,row);
        var result=summarize(rows,f);result.warnings=log.warnings;for(var warning in legacy.warnings)arrayAppend(result.warnings,warning);
        result.trackedSince=log.trackedSince;result.collectorAvailable=log.available;result.updatedAt=createObject("java","java.lang.System").currentTimeMillis();return result;
    }
}
