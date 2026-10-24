component output="false" {
    variables.datasource='runner_dba';
    public any function init(string datasource='runner_dba') {
        variables.datasource=arguments.datasource;
        variables.guard=new services.ComparadorAdminService().init(datasource);
        return this;
    }
    private any function db(required string sql,struct params={}) {return queryExecute(sql,params,{datasource=variables.datasource});}
    private struct function p(required any value,string type='cf_sql_varchar') {return {value=value,cfsqltype=type};}
    private void function invalid(required string message) {throw(type='Comparador.Validation',message=message);}
    public boolean function ready(required struct context) {
        variables.guard.authorize(context);
        return db("SELECT to_regclass('comparador.tb_home_curadoria') IS NOT NULL AND to_regclass('comparador.tb_marca_curadoria') IS NOT NULL AND to_regclass('comparador.tb_cadastro_auditoria') IS NOT NULL AS ready").ready;
    }
    private struct function snapshot() {
        // One statement pairs the displayed fields with their token, including changes to brand names.
        var q=db("SELECT jsonb_build_object('home',jsonb_build_object('id_config',h.id_config,'lancamentos_por_ciclo',h.lancamentos_por_ciclo,'ofertas_por_ciclo',h.ofertas_por_ciclo,'revisao',h.revisao,'atualizado_em',to_char(h.atualizado_em AT TIME ZONE 'UTC','YYYY-MM-DD""T""HH24:MI:SS.US""Z""'),'ator_id',h.ator_id),'marcas',coalesce((SELECT jsonb_agg(jsonb_build_object('tag_marca',m.tag_marca,'marca',m.marca,'destaque',coalesce(c.destaque,false),'presente_brasil',coalesce(c.presente_brasil,false)) ORDER BY m.tag_marca) FROM comparador.tb_marca m LEFT JOIN comparador.tb_marca_curadoria c ON c.tag_marca=m.tag_marca),'[]'::jsonb))::text AS data FROM comparador.tb_home_curadoria h WHERE h.id_config=1");
        if(!q.recordCount) invalid('A configuração da página inicial ainda não foi instalada.');
        return {data=deserializeJSON(q.data),json=q.data,token=lCase(hash(q.data,'SHA-256'))};
    }
    public struct function load(required struct context) {
        variables.guard.authorize(context);
        var current=snapshot();
        return {data=current.data,token=current.token};
    }
    public query function history(required struct context) {
        variables.guard.authorize(context);
        return db("SELECT ator_id,acao,to_char(registrado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS registrado,antes::text,depois::text FROM comparador.tb_cadastro_auditoria WHERE entidade='curadoria' AND chave='principal' ORDER BY id_auditoria DESC LIMIT 30");
    }
    private struct function lockVersion(required string token) {
        // Coordinate brand deletion with CatalogService, then serialize both curation forms.
        db('LOCK TABLE comparador.tb_marca IN SHARE MODE');
        var found=db('SELECT id_config FROM comparador.tb_home_curadoria WHERE id_config=1 FOR UPDATE');
        if(!found.recordCount) invalid('A configuração da página inicial ainda não foi instalada.');
        var current=snapshot();
        if(!reFind('^[a-f0-9]{64}$',token) OR compare(current.token,token)!=0)
            throw(type='Comparador.Conflict',message='A curadoria mudou desde a abertura desta página. Reabra a configuração e confira os dados antes de salvar.');
        return current;
    }
    private void function finish(required struct context,required string before) {
        db('UPDATE comparador.tb_home_curadoria SET revisao=revisao+1,atualizado_em=clock_timestamp(),ator_id=:actor WHERE id_config=1',{actor=p(context.actorId,'cf_sql_bigint')});
        var current=snapshot();
        db("INSERT INTO comparador.tb_cadastro_auditoria(entidade,chave,ator_id,acao,antes,depois) VALUES('curadoria','principal',:actor,'editar',CAST(:before AS jsonb),CAST(:after AS jsonb))",{actor=p(context.actorId,'cf_sql_bigint'),before=p(before,'cf_sql_longvarchar'),after=p(current.json,'cf_sql_longvarchar')});
    }
    private numeric function cycleCount(required struct submitted,required string key) {
        var value=variables.guard.field(submitted,key,2);
        if(!reFind('^([1-9]|10)$',value)) invalid('Informe uma quantidade inteira de 1 a 10 em cada parte da proporção.');
        return val(value);
    }
    private void function completeSubmission(required struct submitted) {
        // CF may execute with a truncated FORM before Tomcat returns its parameter-limit error.
        if(compare(variables.guard.field(submitted,'formulario_completo',9),'curadoria')!=0)
            invalid('O formulário chegou incompleto. Reabra a página e tente novamente.');
    }
    public void function saveHome(required struct context,required struct submitted) {
        variables.guard.authorize(context,true);
        completeSubmission(submitted);
        var launches=cycleCount(submitted,'lancamentos_por_ciclo');
        var offers=cycleCount(submitted,'ofertas_por_ciclo');
        var token=variables.guard.field(submitted,'token',64);
        transaction {
            var current=lockVersion(token);
            db('UPDATE comparador.tb_home_curadoria SET lancamentos_por_ciclo=:launches,ofertas_por_ciclo=:offers WHERE id_config=1',{launches=p(launches,'cf_sql_smallint'),offers=p(offers,'cf_sql_smallint')});
            finish(context,current.json);
        }
    }
    public void function saveMarcas(required struct context,required struct submitted) {
        variables.guard.authorize(context,true);
        completeSubmission(submitted);
        var token=variables.guard.field(submitted,'token',64);
        transaction {
            var current=lockVersion(token);
            var known={};
            for(var brand in current.data.marcas) known[brand.tag_marca]=true;
            var scopeTags=listToArray(variables.guard.field(submitted,'escopo_tags',2000),',',true);
            if(!arrayLen(scopeTags) OR arrayLen(scopeTags)>30) invalid('Salve até 30 marcas por página. Reabra a lista e tente novamente.');
            var scope={};
            for(var tag in scopeTags) {
                if(!len(tag) OR !structKeyExists(known,tag) OR structKeyExists(scope,tag)) invalid('A página contém uma marca desconhecida ou repetida. Reabra a lista e tente novamente.');
                scope[tag]=true;
            }
            for(var key in submitted) {
                var prefix=findNoCase('destaque_',key)==1?'destaque_':(findNoCase('brasil_',key)==1?'brasil_':'');
                if(!len(prefix)) continue;
                var tag=mid(key,len(prefix)+1,len(key));
                if(!len(tag) OR !structKeyExists(scope,tag)) invalid('A lista contém uma marca fora desta página. Reabra a configuração e tente novamente.');
                if(compare(variables.guard.field(submitted,key,4),'true')!=0) invalid('Use as opções de marca apresentadas no formulário, sem valores repetidos.');
            }
            for(var brand in current.data.marcas) {
                if(!structKeyExists(scope,brand.tag_marca))continue;
                var featured=structKeyExists(submitted,'destaque_' & brand.tag_marca);
                var brazil=structKeyExists(submitted,'brasil_' & brand.tag_marca);
                var params={tag=p(brand.tag_marca),featured=p(featured,'cf_sql_bit'),brazil=p(brazil,'cf_sql_bit')};
                if(featured OR brazil)
                    db('INSERT INTO comparador.tb_marca_curadoria(tag_marca,destaque,presente_brasil) VALUES(:tag,:featured,:brazil) ON CONFLICT(tag_marca) DO UPDATE SET destaque=EXCLUDED.destaque,presente_brasil=EXCLUDED.presente_brasil',params);
                else db('DELETE FROM comparador.tb_marca_curadoria WHERE tag_marca=:tag',{tag=params.tag});
            }
            finish(context,current.json);
        }
    }
}
