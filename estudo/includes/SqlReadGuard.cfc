component output=false {
    private void function invalid(string message="Use uma única consulta SELECT ou WITH de leitura.") {
        throw(type="Study.Validation",message=arguments.message);
    }
    public string function validate(required string sql) {
        var source=trim(arguments.sql);
        if(!len(source) || len(source)>200000) invalid("Informe uma consulta de até 200 mil caracteres.");
        var tokens=[]; var positions=[]; var i=1; var n=len(source); var c=""; var j=0; var depth=0; var tag=""; var value=""; var escaped=false; var closed=false;
        while(i<=n) {
            c=mid(source,i,1);
            if(reFind("\s",c)){i++;continue;}
            if(mid(source,i,2)=="--") {while(i<=n && !listFind("10,13",asc(mid(source,i,1))))i++;continue;}
            if(mid(source,i,2)=="/*") {
                depth=1;i+=2;
                while(i<=n && depth>0){if(mid(source,i,2)=="/*"){depth++;i+=2;}else if(mid(source,i,2)=="*/"){depth--;i+=2;}else i++;}
                if(depth)invalid("Comentário SQL não foi fechado.");continue;
            }
            if(c=="'") {
                escaped=i>1 && compareNoCase(mid(source,i-1,1),"e")==0;
                i++;closed=false;
                while(i<=n){if(escaped && mid(source,i,1)==chr(92)){i+=2;continue;}
                    if(mid(source,i,1)=="'"){if(mid(source,i+1,1)=="'"){i+=2;continue;}closed=true;i++;break;}i++;}
                if(!closed)invalid("Texto SQL não foi fechado.");arrayAppend(tokens,"?");arrayAppend(positions,i);continue;
            }
            if(c=='"') {
                i++;value="";closed=false;
                while(i<=n){c=mid(source,i,1);if(c=='"'){if(mid(source,i+1,1)=='"'){value&='"';i+=2;continue;}closed=true;i++;break;}value&=c;i++;}
                if(!closed)invalid("Identificador SQL não foi fechado.");arrayAppend(tokens,lCase(value));arrayAppend(positions,i);continue;
            }
            if(c=="$") {
                var found=reFind("^\$([A-Za-z_][A-Za-z_0-9]*)?\$",mid(source,i,n),1,true);
                if(found.len[1]>0){tag=mid(source,i,found.len[1]);j=find(tag,source,i+len(tag));if(!j)invalid("Texto SQL não foi fechado.");i=j+len(tag);arrayAppend(tokens,"?");arrayAppend(positions,i);continue;}
            }
            if(reFind("[A-Za-z_]",c)) {
                j=i;while(i<=n && reFind("[A-Za-z_0-9$]",mid(source,i,1)))i++;
                arrayAppend(tokens,lCase(mid(source,j,i-j)));arrayAppend(positions,j);continue;
            }
            arrayAppend(tokens,c);arrayAppend(positions,i);i++;
        }
        if(!arrayLen(tokens) || !listFind("select,with",tokens[1]))invalid();
        var forbidden="insert,update,delete,merge,drop,alter,create,truncate,grant,revoke,copy,call,do,execute,prepare,deallocate,begin,commit,rollback,savepoint,set,reset,show,into,lock,vacuum,analyze,reindex,cluster,refresh,listen,notify,unlisten,load";
        // Function calls are intentionally limited to standard analytical PostgreSQL functions.
        var allowed="count,sum,avg,min,max,round,abs,ceil,ceiling,floor,power,sqrt,mod,sign,trunc,coalesce,nullif,greatest,least,cast,extract,date_part,date_trunc,age,to_char,to_date,to_timestamp,make_date,now,current_date,current_timestamp,lower,upper,initcap,length,char_length,octet_length,trim,btrim,ltrim,rtrim,substring,substr,replace,translate,concat,concat_ws,split_part,regexp_replace,regexp_match,regexp_matches,regexp_split_to_array,regexp_split_to_table,position,strpos,left,right,lpad,rpad,format,string_agg,array_agg,array_length,cardinality,unnest,generate_series,row_number,rank,dense_rank,ntile,lag,lead,first_value,last_value,nth_value,percent_rank,cume_dist,percentile_cont,percentile_disc,mode,bool_and,bool_or,every,stddev,stddev_pop,stddev_samp,variance,var_pop,var_samp,filter,over,within,group,in,exists,not,as,values,select,from,where,and,or,distinct,on,using,any,all,some,case,when,then,else,end,numeric,decimal,varchar,char,character,timestamp,time,interval,int4range,int8range,numrange,daterange,json_build_object,jsonb_build_object,json_agg,jsonb_agg,json_array_length,jsonb_array_length,json_extract_path_text,jsonb_extract_path_text,jsonb_each,jsonb_each_text,jsonb_array_elements,jsonb_array_elements_text,jsonb_object_keys,jsonb_object_agg,jsonb_typeof,row_to_json,to_json,to_jsonb,pg_typeof,extrair_faixa_etaria";
        for(i=1;i<=arrayLen(tokens);i++){
            value=tokens[i];
            if(listFind(forbidden,value))invalid("Esta célula aceita somente leitura; operação não permitida: "&value&".");
            if(value=="&" && i>1 && tokens[i-1]=="u")invalid("Use identificadores sem escape Unicode.");
            if(value==";"){
                if(i!=arrayLen(tokens))invalid("Selecione apenas uma consulta antes de executar.");
                source=trim(left(source,positions[i]-1));
            }
            if(i<arrayLen(tokens) && tokens[i+1]=="(" && reFind("^[a-z_]",value) && !listFind(allowed,value)){
                invalid("Função não habilitada para leitura no Estudo: "&value&".");
            }
            if(i+3<=arrayLen(tokens) && tokens[i+1]=="." && tokens[i+3]=="(" && value!="pg_catalog" && !(value=="public" && tokens[i+2]=="extrair_faixa_etaria")){
                invalid("Use funções analíticas do PostgreSQL sem outro schema.");
            }
        }
        return source;
    }
}
