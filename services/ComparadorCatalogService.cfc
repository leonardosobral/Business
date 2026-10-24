component output="false" {
    variables.datasource='runner_dba';
    public any function init(string datasource='runner_dba') {
        variables.datasource=datasource;
        variables.guard=new services.ComparadorAdminService().init(datasource);
        return this;
    }
    private any function db(required string sql,struct params={}) {return queryExecute(sql,params,{datasource=variables.datasource});}
    private struct function p(required any value,string type='cf_sql_varchar',boolean nullable=false) {return {value=value,cfsqltype=type,null=nullable AND !len(value & '')};}
    private void function invalid(required string message) {throw(type='Comparador.Validation',message=message);}
    private struct function f(required string name,required string label,string kind='text',boolean requiredValue=true,numeric maximum=100) {return {name=name,label=label,kind=kind,requiredValue=requiredValue,maximum=maximum};}
    // SQL identifiers are chosen only from this server-owned map, never from request data.
    public struct function definition(required string entity) {
        switch(entity) {
            case 'marcas':return {title='Marcas',table='tb_marca',keys=['tag_marca'],fields=[f('tag_marca','Código','key',true,64),f('marca','Marca')]};
            case 'tipos':return {title='Tipos de produto',table='tb_tipo_produto',keys=['tag_tipo_produto'],fields=[f('tag_tipo_produto','Código','key',true,64),f('nome_tipo_produto','Nome'),f('sequencia_exibicao','Ordem no menu (vazia oculta)','integer',false)]};
            case 'categorias':return {title='Categorias',table='tb_categoria',keys=['tag_categoria'],fields=[f('tag_categoria','Código','key',true,64),f('categoria','Categoria'),f('tag_tipo_produto','Tipo de produto','tipos',true,64)]};
            case 'caracteristicas':return {title='Características',table='tb_caracteristica',keys=['tag_caracteristica'],fields=[f('tag_caracteristica','Código','key',true,64),f('nome_caracteristica','Nome'),f('tipo_caracteristica','Formato','format'),f('un_caracteristica','Unidade','text',false,32),f('descricao_caracteristica','Descrição','textarea',true,5000)]};
            case 'vinculos':return {title='Características por tipo',table='tb_caracteristica_compara',keys=['tag_tipo_produto','tag_caracteristica'],fields=[f('tag_tipo_produto','Tipo de produto','tipos',true,64),f('tag_caracteristica','Característica','caracteristicas',true,64),f('sequencia_exibicao','Ordem','integer')]};
            case 'filtros':return {title='Filtros',table='tb_filtro',keys=['tag_filtro'],fields=[f('tag_filtro','Código','key',true,64),f('tag_tipo_produto','Tipo de produto','tipos',true,64),f('campo','Campo','filter'),f('rotulo','Rótulo'),f('sequencia_exibicao','Ordem','integer'),f('ativo','Exibir','boolean')]};
            case 'opcoes':return {title='Opções dos filtros',table='tb_filtro_opcao',keys=['tag_opcao'],fields=[f('tag_opcao','Código','key',true,64),f('tag_filtro','Filtro','filtros',true,64),f('valor','Valor'),f('rotulo','Rótulo'),f('sequencia_exibicao','Ordem','integer')]};
            default: invalid('Cadastro inválido.');
        }
    }
    public array function entities() {return ['marcas','tipos','categorias','caracteristicas','vinculos','filtros','opcoes'];}
    public boolean function ready(required struct context) {
        variables.guard.authorize(context);
        return db("SELECT to_regclass('comparador.tb_cadastro_auditoria') IS NOT NULL AND to_regclass('comparador.tb_filtro') IS NOT NULL AND to_regclass('comparador.tb_filtro_opcao') IS NOT NULL AS ready").ready;
    }
    private struct function whereKey(required struct def,required string key) {
        var parts=listToArray(key,'|',true);var predicates=[];var params={};
        if(arrayLen(parts)!=arrayLen(def.keys)) invalid('Código do cadastro inválido.');
        for(var i=1;i<=arrayLen(parts);i++) {arrayAppend(predicates,def.keys[i] & '=:key' & i);params['key' & i]=p(parts[i]);}
        return {sql=arrayToList(predicates,' AND '),params=params};
    }
    public string function recordKey(required struct def,required struct data) {var parts=[];for(var key in def.keys) arrayAppend(parts,data[key]);return arrayToList(parts,'|');}
    public query function listRecords(required struct context,required string entity,string search='') {
        variables.guard.authorize(context);var def=definition(entity);
        var params={};var where='';
        if(len(search)){where=' WHERE to_jsonb(t)::text ILIKE :search';params.search=p('%' & left(search,160) & '%');}
        return db('SELECT t.* FROM comparador.' & def.table & ' t' & where & ' ORDER BY ' & arrayToList(def.keys,','),params);
    }
    public struct function loadRecord(required struct context,required string entity,required string key) {
        variables.guard.authorize(context);var def=definition(entity);var where=whereKey(def,key);
        var q=db('SELECT to_jsonb(t)::text AS data FROM comparador.' & def.table & ' t WHERE ' & where.sql,where.params);
        if(!q.recordCount) invalid('Cadastro não encontrado.');
        return {data=deserializeJSON(q.data),json=q.data,token=lCase(hash(q.data,'SHA-256'))};
    }
    public query function history(required struct context,required string entity,required string key) {
        variables.guard.authorize(context);definition(entity);
        return db("SELECT acao,ator_id,to_char(registrado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS registrado,antes::text,depois::text FROM comparador.tb_cadastro_auditoria WHERE entidade=:entity AND chave=:key ORDER BY id_auditoria DESC LIMIT 30",{entity=p(entity),key=p(key)});
    }
    private void function lockCatalog() {
        // Older product writers lack category FKs. Serialize dictionary changes with their DML.
        db('LOCK TABLE comparador.tb_produto,comparador.tb_produto_caracteristica,comparador.tb_caracteristica_compara,comparador.tb_marca,comparador.tb_tipo_produto,comparador.tb_categoria,comparador.tb_caracteristica,comparador.tb_filtro,comparador.tb_filtro_opcao IN SHARE ROW EXCLUSIVE MODE');
    }
    private struct function checkVersion(required struct context,required string entity,required string key,required string token) {
        var old=loadRecord(context,entity,key);
        if(!reFind('^[a-f0-9]{64}$',token) OR compare(old.token,token)!=0) throw(type='Comparador.Conflict',message='Este cadastro mudou. Reabra o registro antes de salvar.');
        return old;
    }
    private void function audit(required struct context,required string entity,required string key,required string action,string before='',string after='') {
        db('INSERT INTO comparador.tb_cadastro_auditoria(entidade,chave,ator_id,acao,antes,depois) VALUES(:entity,:key,:actor,:action,CAST(:before AS jsonb),CAST(:after AS jsonb))',{entity=p(entity),key=p(key),actor=p(context.actorId,'cf_sql_bigint'),action=p(action),before=p(before,'cf_sql_longvarchar',true),after=p(after,'cf_sql_longvarchar',true)});
    }
    public void function validateOption(required string field,required string value) {
        if(listFind('marca,categoria,nome_produto',field)) invalid('As opções deste filtro vêm dos produtos publicados.');
        var valid=false;
        switch(field) {
            case 'genero':valid=listFind('M,F,U',value)>0;break;
            case 'placa':valid=listFind('com-placa,sem-placa',value)>0;break;
            case 'nivel_amortecimento':valid=reFind('^[1-6]$',value)>0;break;
            case 'peso':valid=listFind('LT200,LT225,LT250,GTE250',value)>0 OR reFind('^[0-9]{1,7}(\.[0-9]{1,4})?$',value)>0;break;
            case 'tamanho_drop':valid=listFind('LT8,GTE8',value)>0 OR reFind('^[0-9]{1,7}(\.[0-9]{1,4})?$',value)>0;break;
            case 'preco_promocional':valid=listFind('LT300,LT500,LT800,LT1000,GTE1000',value)>0 OR reFind('^[0-9]{1,7}(\.[0-9]{1,4})?$',value)>0;break;
        }
        if(!valid) invalid('Valor não suportado por este filtro. Use uma opção documentada ou um número decimal exato.');
    }
    private struct function validate(required struct def,required struct submitted) {
        var d={};
        for(var field in def.fields) {
            var value=variables.guard.field(submitted,field.name,field.maximum);
            if(field.requiredValue AND !len(value)) invalid('Preencha ' & field.label & '.');
            if(field.kind=='key' AND !reFind('^[a-z0-9]+([_-][a-z0-9]+)*$',value)) invalid('Use código com letras minúsculas, números, hífen ou sublinhado.');
            if(field.kind=='integer' AND len(value)) value=variables.guard.identifier(value,true);
            if(field.kind=='boolean' AND !listFind('true,false',value)) invalid('Escolha sim ou não.');
            if(field.kind=='format' AND !listFind('string,number,boolean',value)) invalid('Formato inválido.');
            if(field.kind=='filter' AND !listFind('marca,categoria,nome_produto,genero,placa,nivel_amortecimento,tamanho_drop,peso,preco_promocional',value)) invalid('Campo de filtro inválido.');
            if(listFind('tipos,caracteristicas,filtros',field.kind)) {
                var reference=definition(field.kind);
                if(!db('SELECT 1 FROM comparador.' & reference.table & ' WHERE ' & reference.keys[1] & '=:value',{value=p(value)}).recordCount) invalid('Selecione um registro válido para ' & field.label & '.');
            }
            d[field.name]=value;
        }
        return d;
    }
    private numeric function usage(required string entity,required struct data) {
        switch(entity) {
            case 'marcas':
                var linked=db('SELECT count(*) AS n FROM comparador.tb_produto WHERE tag_marca=:key',{key=p(data.tag_marca)}).n;
                if(db("SELECT to_regclass('comparador.tb_marca_curadoria') IS NOT NULL AS ready").ready)
                    linked+=db('SELECT count(*) AS n FROM comparador.tb_marca_curadoria WHERE tag_marca=:key',{key=p(data.tag_marca)}).n;
                return linked;
            case 'tipos':return db('SELECT (SELECT count(*) FROM comparador.tb_produto WHERE tag_tipo_produto=:key)+(SELECT count(*) FROM comparador.tb_categoria WHERE tag_tipo_produto=:key)+(SELECT count(*) FROM comparador.tb_caracteristica_compara WHERE tag_tipo_produto=:key)+(SELECT count(*) FROM comparador.tb_filtro WHERE tag_tipo_produto=:key) AS n',{key=p(data.tag_tipo_produto)}).n;
            case 'categorias':return db('SELECT count(*) AS n FROM comparador.tb_produto WHERE tag_categoria=:key',{key=p(data.tag_categoria)}).n;
            case 'caracteristicas':return db('SELECT (SELECT count(*) FROM comparador.tb_produto_caracteristica WHERE tag_caracteristica=:key)+(SELECT count(*) FROM comparador.tb_caracteristica_compara WHERE tag_caracteristica=:key) AS n',{key=p(data.tag_caracteristica)}).n;
            case 'vinculos':return db('SELECT count(*) AS n FROM comparador.tb_produto_caracteristica pc JOIN comparador.tb_produto p ON p.id_produto=pc.id_produto WHERE p.tag_tipo_produto=:type AND pc.tag_caracteristica=:feature',{type=p(data.tag_tipo_produto),feature=p(data.tag_caracteristica)}).n;
            case 'filtros':return db('SELECT count(*) AS n FROM comparador.tb_filtro_opcao WHERE tag_filtro=:key',{key=p(data.tag_filtro)}).n;
            default:return 0;
        }
    }
    public string function saveRecord(required struct context,required string entity,required struct submitted) {
        variables.guard.authorize(context,true);var def=definition(entity);var original=variables.guard.field(submitted,'chave',200);var before='';var key='';
        transaction {
            lockCatalog();var d=validate(def,submitted);key=recordKey(def,d);
            if(entity=='tipos' AND !reFind('^[a-z0-9]+(-[a-z0-9]+)*$',d.tag_tipo_produto)) invalid('O código do tipo deve usar letras minúsculas, números e hífens para formar um endereço válido.');
            if(entity=='caracteristicas' AND !reFind('^[a-z][a-z0-9_]{0,59}$',d.tag_caracteristica)) invalid('O código da característica deve começar com letra e usar até 60 letras minúsculas, números ou sublinhado.');
            if(len(original)) {
                var old=checkVersion(context,entity,original,variables.guard.field(submitted,'token',64));before=old.json;
                if(compare(original,key)!=0) invalid('O código de um cadastro existente não pode ser alterado.');
                if(entity=='categorias' AND compare(variables.guard.field(old.data,'tag_tipo_produto',64),d.tag_tipo_produto)!=0 AND usage(entity,old.data)) invalid('Categoria em uso: o tipo não pode mudar.');
                if(entity=='caracteristicas' AND (compare(variables.guard.field(old.data,'tipo_caracteristica',64),d.tipo_caracteristica)!=0 OR compare(variables.guard.field(old.data,'un_caracteristica',32),d.un_caracteristica)!=0) AND usage(entity,old.data)) invalid('Característica em uso: formato e unidade não podem mudar.');
                if(entity=='filtros' AND (compare(old.data.campo,d.campo)!=0 OR compare(old.data.tag_tipo_produto,d.tag_tipo_produto)!=0)) invalid('Campo e tipo do filtro são fixos. Crie outro filtro para mudar essa relação.');
            }
            if(entity=='filtros' AND d.tag_tipo_produto!='tenis' AND !listFind('marca,categoria,nome_produto,preco_promocional',d.campo)) invalid('Este campo está disponível apenas para tênis.');
            if(entity=='opcoes') validateOption(loadRecord(context,'filtros',d.tag_filtro).data.campo,d.valor);
            var where=whereKey(def,key);var duplicate=db('SELECT 1 FROM comparador.' & def.table & ' WHERE ' & where.sql,where.params);
            if(!len(original) AND duplicate.recordCount) invalid('Este código já está cadastrado.');
            if(entity=='categorias' AND db('SELECT 1 FROM comparador.tb_categoria WHERE categoria=:name AND tag_categoria<>:key',{name=p(d.categoria),key=p(key)}).recordCount) invalid('Já existe uma categoria com este nome.');
            if(entity=='filtros' AND db('SELECT 1 FROM comparador.tb_filtro WHERE tag_tipo_produto=:type AND campo=:field AND tag_filtro<>:key',{type=p(d.tag_tipo_produto),field=p(d.campo),key=p(key)}).recordCount) invalid('Este campo já tem um filtro configurado para o tipo.');
            if(entity=='opcoes' AND db('SELECT 1 FROM comparador.tb_filtro_opcao WHERE tag_filtro=:filter AND valor=:value AND tag_opcao<>:key',{filter=p(d.tag_filtro),value=p(d.valor),key=p(key)}).recordCount) invalid('Este valor já existe no filtro.');
            var names=[];var placeholders=[];var sets=[];var params=where.params;
            for(var field in def.fields) {
                arrayAppend(names,field.name);arrayAppend(placeholders,':v_' & field.name);
                arrayAppend(sets,field.name & '=:v_' & field.name);
                params['v_' & field.name]=p(d[field.name],field.kind=='integer'?'cf_sql_integer':(field.kind=='boolean'?'cf_sql_bit':'cf_sql_varchar'),!field.requiredValue);
            }
            if(len(original)) db('UPDATE comparador.' & def.table & ' SET ' & arrayToList(sets,',') & ' WHERE ' & where.sql,params);
            else db('INSERT INTO comparador.' & def.table & '(' & arrayToList(names,',') & ') VALUES(' & arrayToList(placeholders,',') & ')',params);
            audit(context,entity,key,len(original)?'editar':'criar',before,loadRecord(context,entity,key).json);
        }
        return key;
    }
    public void function deleteRecord(required struct context,required string entity,required string key,required string token) {
        variables.guard.authorize(context,true);var def=definition(entity);
        transaction {
            lockCatalog();var old=checkVersion(context,entity,key,token);
            if(usage(entity,old.data)>0) invalid('Este cadastro está em uso. Revise os vínculos antes de excluir.');
            var where=whereKey(def,key);db('DELETE FROM comparador.' & def.table & ' WHERE ' & where.sql,where.params);
            audit(context,entity,key,'excluir',old.json);
        }
    }
}
