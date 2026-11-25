component output="false" {
    variables.db={datasource="runner_dba",timeout=10};
    public any function init(required numeric actorId) {
        if(!queryExecute("SELECT id FROM tb_usuarios WHERE id=:id AND is_admin=true",{id=n(arguments.actorId)},variables.db).recordCount)
            throw(type="YoutubeChannel.Forbidden",message="Acesso exclusivo para administradores globais.");
        return this;
    }
    private struct function n(required numeric value){return {value=arguments.value,cfsqltype="cf_sql_integer"};}
    private struct function t(required string value){return {value=arguments.value,cfsqltype="cf_sql_varchar"};}
    private string function field(required struct fields,required string key,string fallback=""){
        if(!structKeyExists(arguments.fields,arguments.key))return arguments.fallback;
        if(!isSimpleValue(arguments.fields[arguments.key]))invalid("Valor inválido no formulário.");
        return trim(arguments.fields[arguments.key]&"");
    }
    private void function invalid(required string message){throw(type="YoutubeChannel.Validation",message=arguments.message);}
    private string function integer(required string value,required numeric minimum,required numeric maximum,boolean optional=false){
        if(!len(arguments.value) AND arguments.optional)return "";
        if(!reFind("^[0-9]{1,10}$",arguments.value) OR val(arguments.value)<arguments.minimum OR val(arguments.value)>arguments.maximum)invalid("Confira os limites e as seleções do formulário.");
        return val(arguments.value)&"";
    }
    public struct function parseSource(required string source,required string type){
        var raw=trim(arguments.source);var kind=lCase(trim(arguments.type));
        if(!listFind("channel,playlist",kind))invalid("Escolha Canal ou Playlist.");
        var parsed={source_type=kind,channel_id="",channel_handle="",playlist_id=""};
        if(reFindNoCase("^https?://",raw)){
            try{var uri=createObject("java","java.net.URI").init(raw);}catch(any bad){invalid("Informe um link válido do YouTube.");}
            if(!listFindNoCase("youtube.com,www.youtube.com,m.youtube.com",uri.getHost() ?: "") OR len(uri.getUserInfo() ?: "") OR uri.getPort() NEQ -1)invalid("Use um link oficial do youtube.com.");
            var path=urlDecode(uri.getRawPath() ?: "");
            if(kind EQ "playlist"){
                if(path NEQ "/playlist")invalid("Cole o link da playlist, com o parâmetro list.");
                var query=uri.getRawQuery() ?: "";raw="";
                for(var pair in listToArray(query,"&"))if(listFirst(pair,"=") EQ "list")raw=urlDecode(listRest(pair,"="));
            }else{
                raw=reReplace(path,"^/|/(videos|featured|shorts|streams)/?$|/$","","all");
                if(left(raw,8) EQ "channel/")raw=mid(raw,9,len(raw));
            }
        }
        if(kind EQ "playlist"){
            if(!reFind("^[A-Za-z0-9_-]{10,100}$",raw))invalid("Cole o link ou identificador de uma playlist válida.");
            parsed.playlist_id=raw;
        }else if(reFind("^UC[A-Za-z0-9_-]{22}$",raw))parsed.channel_id=raw;
        else if(reFind("^@[\p{L}\p{N}_.·-]{3,100}$",raw))parsed.channel_handle=raw;
        else invalid("Cole o link do canal, seu @identificador ou o ID iniciado por UC.");
        return parsed;
    }
    public string function sourceUrl(required struct row){
        if(arguments.row.source_type EQ "playlist")return "https://www.youtube.com/playlist?list="&encodeForURL(arguments.row.playlist_id ?: "");
        if(len(arguments.row.channel_handle ?: ""))return "https://www.youtube.com/"&arguments.row.channel_handle;
        return "https://www.youtube.com/channel/"&(arguments.row.channel_id ?: "");
    }
    public query function listing(string search="",string status="all"){
        var sql="SELECT c.*,coalesce(p.nome,'') AS page_name,coalesce(p.tag,'') AS page_tag,coalesce(u.name,'') AS user_name,
            coalesce(u.email,'') AS user_email,to_char(c.updated_at,'YYYY-MM-DD HH24:MI:SS.US') AS revision
            FROM tb_youtube_canais c LEFT JOIN tb_paginas p ON p.id_pagina=c.id_pagina LEFT JOIN tb_usuarios u ON u.id=c.id_usuario WHERE 1=1";
        var params={};
        if(len(trim(arguments.search))){sql&=" AND (c.name ILIKE :search OR c.channel_handle ILIKE :search OR c.code ILIKE :search)";params.search=t("%"&replace(replace(replace(left(trim(arguments.search),100),"!","!!","all"),"%","!%","all"),"_","!_","all")&"%");sql=replace(sql,"ILIKE :search","ILIKE :search ESCAPE '!'","all");}
        if(arguments.status EQ "active")sql&=" AND c.enabled=true";
        if(arguments.status EQ "inactive")sql&=" AND c.enabled=false";
        return queryExecute(sql&" ORDER BY c.sort_order,c.name,c.id_youtube_canal",params,variables.db);
    }
    public query function get(required numeric id){
        return queryExecute("SELECT c.*,coalesce(p.nome,'') AS page_name,coalesce(p.tag,'') AS page_tag,coalesce(u.name,'') AS user_name,
            coalesce(u.email,'') AS user_email,to_char(c.updated_at,'YYYY-MM-DD HH24:MI:SS.US') AS revision
            FROM tb_youtube_canais c LEFT JOIN tb_paginas p ON p.id_pagina=c.id_pagina LEFT JOIN tb_usuarios u ON u.id=c.id_usuario WHERE c.id_youtube_canal=:id",{id=n(arguments.id)},variables.db);
    }
    public array function search(required string kind,required string term){
        var value=left(trim(arguments.term),100);if(len(value)<2)return [];
        var pattern="%"&replace(replace(replace(value,"!","!!","all"),"%","!%","all"),"_","!_","all")&"%";
        var params={term=t(pattern)};var rows="";var result=[];
        if(arguments.kind EQ "user"){
            rows=queryExecute("SELECT u.id,u.name,u.email FROM tb_usuarios u LEFT JOIN tb_usuarios_gestao g ON g.id_usuario=u.id
                WHERE u.id>0 AND coalesce(g.ativo,true) AND NOT coalesce(g.excluido,false) AND (u.name ILIKE :term ESCAPE '!' OR u.email ILIKE :term ESCAPE '!')
                ORDER BY u.name,u.id LIMIT 12",params,variables.db);
            for(var row in rows)arrayAppend(result,{id=row.id,label=row.name&" · "&row.email});
        }else if(arguments.kind EQ "page"){
            rows=queryExecute("SELECT p.id_pagina,p.nome,p.tag,coalesce(p.tag_prefix,'atleta') AS prefix,
                coalesce(owner.id,0) AS owner_id,coalesce(owner.name,'') AS owner_name,coalesce(owner.email,'') AS owner_email
                FROM tb_paginas p LEFT JOIN tb_paginas_gestao g ON g.id_pagina=p.id_pagina
                LEFT JOIN LATERAL(SELECT u.id,u.name,u.email FROM tb_paginas_usuarios pu JOIN tb_usuarios u ON u.id=pu.id_usuario
                    LEFT JOIN tb_usuarios_gestao ug ON ug.id_usuario=u.id WHERE pu.id_pagina=p.id_pagina AND coalesce(ug.ativo,true) AND NOT coalesce(ug.excluido,false) ORDER BY u.id LIMIT 1)owner ON true
                WHERE p.id_pagina>0 AND coalesce(g.ativo,true) AND NOT coalesce(g.excluido,false) AND (p.nome ILIKE :term ESCAPE '!' OR p.tag ILIKE :term ESCAPE '!')
                ORDER BY p.nome,p.id_pagina LIMIT 12",params,variables.db);
            for(var row in rows)arrayAppend(result,{id=row.id_pagina,label=row.nome&" · /"&row.prefix&"/"&(len(row.tag ?: "") ? row.tag : row.id_pagina)&"/",owner_id=row.owner_id,owner_label=row.owner_name&" · "&row.owner_email});
        }else invalid("Tipo de busca inválido.");
        return result;
    }
    public numeric function save(required struct fields){
        var f=arguments.fields;var id=val(integer(field(f,"id_youtube_canal","0"),0,2147483647));
        var name=field(f,"name");if(!len(name) OR len(name)>255)invalid("Informe um nome de até 255 caracteres para o canal.");
        var src=parseSource(field(f,"source"),field(f,"source_type","channel"));
        var page=integer(field(f,"id_pagina"),1,2147483647,true);var user=integer(field(f,"id_usuario"),1,2147483647,true);
        var minValue=field(f,"min_duration_minutes");var maxValue=field(f,"max_duration_minutes");
        for(var minutes in [minValue,maxValue])if(len(minutes) AND (!reFind("^[0-9]{1,5}([.][0-9]{1,2})?$",minutes) OR val(minutes)>10080))invalid("Informe a duração em minutos, com ponto decimal se necessário.");
        var minSeconds=len(minValue) ? round(val(minValue)*60) : 0;var maxSeconds=len(maxValue) ? round(val(maxValue)*60) : 0;
        if(len(maxValue) AND maxSeconds<minSeconds)invalid("A duração máxima deve ser maior ou igual à mínima.");
        var instagram=field(f,"instagram_url");if(len(instagram) AND !reFindNoCase("^https://(www[.])?instagram[.]com/[^\s]*$",instagram))invalid("Use um link HTTPS do Instagram.");
        var description=field(f,"descricao");if(len(description)>5000)invalid("A descrição deve ter até 5.000 caracteres.");
        var params={id=n(id),name=t(name),kind=t(src.source_type),channel=t(src.channel_id),handle=t(src.channel_handle),playlist=t(src.playlist_id),
            page={value=val(page),cfsqltype="cf_sql_integer",null=!len(page)},user={value=val(user),cfsqltype="cf_sql_integer",null=!len(user)},
            limit=n(val(integer(field(f,"max_results","3"),1,50))),order=n(val(integer(field(f,"sort_order","0"),0,10000))),
            enabled={value=field(f,"enabled") EQ "1",cfsqltype="cf_sql_bit"},min={value=minSeconds,cfsqltype="cf_sql_integer",null=!len(minValue)},max={value=maxSeconds,cfsqltype="cf_sql_integer",null=!len(maxValue)},description=t(description),instagram=t(instagram)};
        transaction {
            queryExecute("SELECT pg_advisory_xact_lock(20261118,11)",{},variables.db);
            if(len(page) AND !queryExecute("SELECT id_pagina FROM tb_paginas WHERE id_pagina=:id",{id=n(val(page))},variables.db).recordCount)invalid("Selecione uma página existente nos resultados da busca.");
            if(len(user) AND !queryExecute("SELECT id FROM tb_usuarios WHERE id=:id",{id=n(val(user))},variables.db).recordCount)invalid("Selecione um usuário existente nos resultados da busca.");
            if(len(page) AND len(user) AND !queryExecute("SELECT id_pagina FROM tb_paginas_usuarios WHERE id_pagina=:page AND id_usuario=:user",{page=n(val(page)),user=n(val(user))},variables.db).recordCount)invalid("O usuário selecionado precisa estar vinculado à página escolhida.");
            if(queryExecute("SELECT id_youtube_canal FROM tb_youtube_canais WHERE id_youtube_canal<>:id AND
                ((:channel<>'' AND channel_id=:channel) OR (:handle<>'' AND lower(channel_handle)=lower(:handle)) OR (:playlist<>'' AND playlist_id=:playlist))",params,variables.db).recordCount)invalid("Esse canal ou playlist já está cadastrado. Edite o cadastro existente.");
            var sql="";
            if(id){
                params.revision=t(field(f,"revision"));
                sql="UPDATE tb_youtube_canais SET name=:name,source_type=:kind,channel_id=nullif(:channel,''),channel_handle=nullif(:handle,''),playlist_id=nullif(:playlist,''),id_pagina=:page,id_usuario=:user,
                    max_results=:limit,sort_order=:order,enabled=:enabled,min_duration_seconds=:min,max_duration_seconds=:max,descricao=:description,instagram_url=:instagram,updated_at=clock_timestamp()::timestamp
                    WHERE id_youtube_canal=:id AND to_char(updated_at,'YYYY-MM-DD HH24:MI:SS.US')=:revision RETURNING id_youtube_canal";
            }else{
                var code=lCase(name);code=replaceList(code,"á,à,ã,â,é,ê,í,ó,ô,õ,ú,ü,ç","a,a,a,a,e,e,i,o,o,o,u,u,c");code=reReplace(code,"[^a-z0-9]+","-","all");code=left(reReplace(code,"^-|-$","","all"),100);if(!len(code))code="canal";
                var base=code;var suffix=1;
                while(queryExecute("SELECT id_youtube_canal FROM tb_youtube_canais WHERE code=:code",{code=t(code)},variables.db).recordCount){suffix++;code=base&"-"&suffix;}
                params.code=t(code);
                sql="INSERT INTO tb_youtube_canais(code,name,source_type,channel_id,channel_handle,playlist_id,id_pagina,id_usuario,max_results,sort_order,enabled,min_duration_seconds,max_duration_seconds,descricao,instagram_url)
                    VALUES(:code,:name,:kind,nullif(:channel,''),nullif(:handle,''),nullif(:playlist,''),:page,:user,:limit,:order,:enabled,:min,:max,:description,:instagram) RETURNING id_youtube_canal";
            }
            var saved=queryExecute(sql,params,variables.db);
            if(!saved.recordCount)throw(type="YoutubeChannel.Conflict",message="Este canal foi alterado por outra pessoa. Atualize a página antes de salvar.");
            return saved.id_youtube_canal[1];
        }
    }
    public void function toggle(required numeric id,required string revision){
        var saved=queryExecute("UPDATE tb_youtube_canais SET enabled=NOT enabled,updated_at=clock_timestamp()::timestamp WHERE id_youtube_canal=:id AND to_char(updated_at,'YYYY-MM-DD HH24:MI:SS.US')=:revision RETURNING id_youtube_canal",{id=n(arguments.id),revision=t(arguments.revision)},variables.db);
        if(!saved.recordCount)throw(type="YoutubeChannel.Conflict",message="Canal alterado por outra pessoa. Atualize a lista.");
    }
    public void function remove(required numeric id,required string revision){
        var saved=queryExecute("DELETE FROM tb_youtube_canais WHERE id_youtube_canal=:id AND to_char(updated_at,'YYYY-MM-DD HH24:MI:SS.US')=:revision RETURNING id_youtube_canal",{id=n(arguments.id),revision=t(arguments.revision)},variables.db);
        if(!saved.recordCount)throw(type="YoutubeChannel.Conflict",message="Canal alterado por outra pessoa. Atualize a lista.");
    }
}
