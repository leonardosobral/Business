component output="false" {
    variables.datasource="runner_dba";
    public any function init(string datasource="runner_dba") {variables.datasource=arguments.datasource;return this;}
    private any function db(required string sql,struct params={}) {return queryExecute(sql,params,{datasource=variables.datasource});}
    private struct function p(required any value,string type="cf_sql_varchar",boolean nullable=false) {return {value=value,cfsqltype=type,null=nullable AND !len(value & "")};}
    private void function invalid(required string message) {throw(type="Comparador.Validation",message=message);}
    public void function authorize(required struct context,boolean write=false) {
        if(!structKeyExists(context,"actorId") OR !reFind("^[1-9][0-9]{0,9}$",context.actorId & "") OR !structKeyExists(context,"isAdmin") OR !isBoolean(context.isAdmin) OR !context.isAdmin OR !structKeyExists(context,"delegated") OR !isBoolean(context.delegated) OR context.delegated)
            throw(type="Comparador.Forbidden",message="O Comparador é restrito aos administradores globais.");
        if(write AND (!structKeyExists(context,"isPost") OR !context.isPost OR !structKeyExists(context,"csrfVerified") OR !context.csrfVerified))
            throw(type="Comparador.Forbidden",message="Reabra o formulário e envie novamente com uma sessão válida.");
    }
    public string function field(required struct data,required string key,numeric maximum=5000) {
        if(!structKeyExists(data,key)) return "";
        if(!isSimpleValue(data[key])) invalid("Formato inválido no campo " & key & ".");
        var value=trim(data[key] & "");
        if(len(value)>maximum OR reFind('[\x00-\x08\x0B\x0C\x0E-\x1F]',value)) invalid("Conteúdo inválido ou muito longo no campo " & key & ".");
        return value;
    }
    public numeric function identifier(required any value,boolean allowZero=false) {
        if(!isSimpleValue(value) OR !reFind('^(0|[1-9][0-9]{0,9})$',value & '') OR val(value)>2147483647 OR (!allowZero AND val(value)==0)) invalid("Identificador inválido.");
        return val(value);
    }
    public string function decimalValue(required any value,boolean optional=true,boolean allowZero=true) {
        if(!isSimpleValue(value)) invalid("Informe um número decimal válido, sem separador de milhar.");
        var clean=trim(value & '');if(optional AND !len(clean)) return '';
        if(!reFind('^[0-9]{1,9}([.,][0-9]{1,6})?$',clean)) invalid("Informe um número decimal válido, sem separador de milhar.");
        clean=replace(clean,',','.');
        if(!allowZero AND val(clean)<=0) invalid("O preço deve ser maior que zero; deixe vazio quando desconhecido.");
        return clean;
    }
    public string function offerUrl(required any value) {
        if(!isSimpleValue(value)) invalid("Informe um link HTTP ou HTTPS válido.");
        var clean=trim(value & '');
        // Keep the writer within the public reader's HTTP(S) URL contract.
        if(!reFindNoCase("^https?://[a-z0-9][a-z0-9.-]*(:[0-9]{1,5})?([/?##][^\s<>""']*)?$",clean)) invalid("Informe um link HTTP ou HTTPS válido, sem credenciais ou caracteres reservados.");
        if(len(clean)>256 OR reFind('[\s\x00-\x1F\\]',clean)) invalid("Informe um link HTTP ou HTTPS válido de até 256 caracteres.");
        try {
            var uri=createObject('java','java.net.URI').init(clean);
            if(!listFindNoCase('http,https',uri.getScheme() & '') OR isNull(uri.getHost()) OR !len(uri.getHost()) OR !isNull(uri.getUserInfo())) invalid("Informe um link HTTP ou HTTPS válido, sem credenciais.");
        } catch(Comparador.Validation e){rethrow;} catch(any e){invalid("Informe um link HTTP ou HTTPS válido.");}
        return clean;
    }
    private string function isoDate(required string value) {
        if(!len(value)) return '';
        if(!reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}$',value)) invalid("Informe uma data válida.");
        try{var parsed=createObject('java','java.time.LocalDate').parse(value);if(parsed.getYear()<1900 OR parsed.getYear()>9999) invalid("Informe uma data entre 1900 e 9999.");}catch(any e){invalid("Informe uma data válida.");}
        return value;
    }
    public boolean function isSchemaReady(required struct context) {
        authorize(context);return db("SELECT to_regclass('comparador.tb_produto_editorial') IS NOT NULL AND to_regclass('comparador.tb_admin_auditoria') IS NOT NULL AND to_regclass('comparador.vw_produto_publico') IS NOT NULL AND to_regclass('comparador.vw_produto_world_athletics') IS NOT NULL AS ready").ready;
    }
    public struct function lookups(required struct context) {
        authorize(context);
        return {types=db("SELECT * FROM comparador.tb_tipo_produto ORDER BY sequencia_exibicao NULLS LAST,nome_tipo_produto"),brands=db("SELECT * FROM comparador.tb_marca ORDER BY marca"),categories=db("SELECT * FROM comparador.tb_categoria ORDER BY categoria")};
    }
    public struct function listProducts(required struct context,string search="",string type="",string state="",string pending="",numeric page=1) {
        authorize(context);var params={};var where=' WHERE 1=1';
        if(len(search)){where&=" AND (p.nome_produto ILIKE :search OR p.tag_produto ILIKE :search OR p.id_produto::text=:exact)";params.search=p('%' & left(search,160) & '%');params.exact=p(left(search,160));}
        if(len(type)){where&=' AND p.tag_tipo_produto=:type';params.type=p(left(type,64));}
        if(listFind('rascunho,publicado,arquivado',state)){where&=" AND coalesce(e.estado,'publicado')=:state";params.state=p(state);}
        if(pending=='vinculos') where&=' AND (m.tag_marca IS NULL OR c.tag_categoria IS NULL OR c.tag_tipo_produto IS DISTINCT FROM p.tag_tipo_produto)';
        if(pending=='preco') where&=" AND (p.preco_referencia IS NULL OR NOT (p.preco_referencia>0 AND p.preco_referencia<'Infinity'::float8))";
        var joins=" FROM comparador.tb_produto p LEFT JOIN comparador.tb_produto_editorial e ON e.id_produto=p.id_produto LEFT JOIN comparador.tb_marca m ON m.tag_marca=p.tag_marca LEFT JOIN comparador.tb_categoria c ON c.tag_categoria=p.tag_categoria LEFT JOIN comparador.tb_tipo_produto t ON t.tag_tipo_produto=p.tag_tipo_produto";
        var total=db('SELECT count(*) AS total' & joins & where,params).total;var current=max(1,min(ceiling(max(total,1)/25),int(page)));params.offset=p((current-1)*25,'cf_sql_integer');
        var rows=db("SELECT p.*,m.marca,t.nome_tipo_produto,coalesce(e.estado,'publicado') AS estado,(m.tag_marca IS NULL OR c.tag_categoria IS NULL OR c.tag_tipo_produto IS DISTINCT FROM p.tag_tipo_produto) AS pendencia_vinculos,(p.preco_referencia IS NULL OR NOT(p.preco_referencia>0 AND p.preco_referencia<'Infinity'::float8)) AS pendencia_preco" & joins & where & ' ORDER BY p.id_produto DESC LIMIT 25 OFFSET :offset',params);
        return {rows=rows,total=total,page=current,pages=ceiling(max(total,1)/25)};
    }
    private struct function snapshot(required numeric id) {
        var q=db("SELECT jsonb_build_object('produto',to_jsonb(p),'editorial',(SELECT to_jsonb(e) FROM comparador.tb_produto_editorial e WHERE e.id_produto=p.id_produto),'caracteristicas',coalesce((SELECT jsonb_agg(to_jsonb(c) ORDER BY c.id_produto_caracteristica) FROM comparador.tb_produto_caracteristica c WHERE c.id_produto=p.id_produto),'[]'::jsonb),'variantes',coalesce((SELECT jsonb_agg(to_jsonb(g) ORDER BY g.genero NULLS LAST,g.peso,g.tamanho) FROM comparador.tb_genero g WHERE g.id_produto=p.id_produto),'[]'::jsonb),'ofertas',coalesce((SELECT jsonb_agg(to_jsonb(o) ORDER BY o.id_cupom) FROM comparador.tb_cupom o WHERE o.id_tenis=p.id_produto),'[]'::jsonb))::text AS data FROM comparador.tb_produto p WHERE p.id_produto=:id",{id=p(id,'cf_sql_integer')});
        if(!q.recordCount) invalid('Produto não encontrado.');
        return {json=q.data,token=lCase(hash(q.data,'SHA-256'))};
    }
    public struct function load(required struct context,required any productId) {
        authorize(context);var id=identifier(productId);var snap=snapshot(id);var params={id=p(id,'cf_sql_integer')};
        var product=db("SELECT p.*,coalesce(e.estado,'publicado') AS estado,coalesce(e.revisao,0) AS revisao,coalesce(wa.wa_status,'nao_verificado') AS wa_status,wa.wa_aprovado_rua,coalesce(wa.wa_prototipo,false) AS wa_prototipo,coalesce(wa.wa_compra_bloqueada,false) AS wa_compra_bloqueada,wa.wa_validade,wa.wa_consultado_em,coalesce(wa.wa_fonte,'') AS wa_fonte,coalesce(wa.wa_modelo_numero,'') AS wa_modelo_numero,coalesce(wa.wa_foto_url,'') AS wa_foto_url,coalesce(wa.wa_restricoes,'') AS wa_restricoes FROM comparador.tb_produto p LEFT JOIN comparador.tb_produto_editorial e ON e.id_produto=p.id_produto LEFT JOIN comparador.vw_produto_world_athletics wa ON wa.id_produto=p.id_produto WHERE p.id_produto=:id",params);
        return {product=product,token=snap.token,
          features=db('SELECT pc.*,c.nome_caracteristica,c.tipo_caracteristica,c.un_caracteristica FROM comparador.tb_produto_caracteristica pc LEFT JOIN comparador.tb_caracteristica c ON c.tag_caracteristica=pc.tag_caracteristica WHERE pc.id_produto=:id ORDER BY pc.id_produto_caracteristica',params),
          available=db('SELECT c.* FROM comparador.tb_caracteristica_compara cc JOIN comparador.tb_caracteristica c ON c.tag_caracteristica=cc.tag_caracteristica JOIN comparador.tb_produto p ON p.tag_tipo_produto=cc.tag_tipo_produto WHERE p.id_produto=:id ORDER BY cc.sequencia_exibicao,c.nome_caracteristica',params),
          variants=db('SELECT * FROM comparador.tb_genero WHERE id_produto=:id ORDER BY genero',params),
          offers=db("SELECT o.*,(o.id_cupom=(SELECT max(x.id_cupom) FROM comparador.tb_cupom x WHERE x.id_tenis=:id)) AS is_latest,(o.data_expiracao IS NOT NULL AND o.data_expiracao<(CURRENT_TIMESTAMP AT TIME ZONE 'America/Sao_Paulo')::date) AS expired FROM comparador.tb_cupom o WHERE o.id_tenis=:id ORDER BY o.id_cupom DESC",params),
          history=db("SELECT id_auditoria,ator_id,acao,to_char(registrado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') AS registrado,antes::text,depois::text FROM comparador.tb_admin_auditoria WHERE id_produto=:id ORDER BY id_auditoria DESC LIMIT 50",params)};
    }
    private struct function lockProduct(required numeric id,required string token) {
        var found=db('SELECT id_produto FROM comparador.tb_produto WHERE id_produto=:id FOR UPDATE',{id=p(id,'cf_sql_integer')});
        if(!found.recordCount) invalid('Produto não encontrado.');
        var before=snapshot(id);
        if(!reFind('^[a-f0-9]{64}$',token) OR compare(before.token,token)!=0) throw(type='Comparador.Conflict',message='O produto mudou desde a abertura do formulário. Recarregue e confira os dados antes de salvar.');
        return before;
    }
    private void function audit(required numeric id,required struct context,required string action,required string before,string state='') {
        var params={id=p(id,'cf_sql_integer'),actor=p(context.actorId,'cf_sql_bigint'),state=p(len(state)?state:'publicado')};
        db("INSERT INTO comparador.tb_produto_editorial(id_produto,estado,ator_id) VALUES(:id,:state,:actor) ON CONFLICT(id_produto) DO UPDATE SET revisao=comparador.tb_produto_editorial.revisao+1,atualizado_em=clock_timestamp(),ator_id=EXCLUDED.ator_id",params);
        if(len(state)) db('UPDATE comparador.tb_produto_editorial SET estado=:state WHERE id_produto=:id',{id=params.id,state=params.state});
        var after=snapshot(id);
        db('INSERT INTO comparador.tb_admin_auditoria(id_produto,ator_id,acao,antes,depois) VALUES(:id,:actor,:action,CAST(:before AS jsonb),CAST(:after AS jsonb))',{id=params.id,actor=params.actor,action=p(action),before=p(before,'cf_sql_longvarchar',true),after=p(after.json,'cf_sql_longvarchar')});
    }
    private struct function validateProduct(required struct submitted) {
        var d={};for(var key in ['nome_produto','tag_tipo_produto','tag_marca','tag_categoria','tag_produto','versao','resumo','descricao']) d[key]=field(submitted,key,key=='descricao'?30000:(key=='resumo'?1000:250));
        if(!len(d.nome_produto) OR !len(d.tag_tipo_produto)) invalid('Informe nome e tipo do produto.');
        if(!reFind('^[a-z0-9]+(-[a-z0-9]+)*$',d.tag_produto) OR len(d.tag_produto)>160 OR listFind('zerar,comparar',d.tag_produto) OR find('-vs-',d.tag_produto)) invalid('Use um endereço com letras minúsculas, números e hífens, até 160 caracteres. Os termos comparar, zerar e -vs- são reservados.');
        d.num_versao=identifier(len(field(submitted,'num_versao'))?field(submitted,'num_versao'):'0',true);d.preco_referencia=decimalValue(field(submitted,'preco_referencia'),true,false);d.data_lancamento=isoDate(field(submitted,'data_lancamento'));
        if(!db('SELECT 1 FROM comparador.tb_tipo_produto WHERE tag_tipo_produto=:tag',{tag=p(d.tag_tipo_produto)}).recordCount) invalid('Tipo de produto inválido.');
        if(len(d.tag_marca) AND !db('SELECT 1 FROM comparador.tb_marca WHERE tag_marca=:tag',{tag=p(d.tag_marca)}).recordCount) invalid('Marca inválida.');
        if(len(d.tag_categoria) AND !db('SELECT 1 FROM comparador.tb_categoria WHERE tag_categoria=:tag AND tag_tipo_produto=:type',{tag=p(d.tag_categoria),type=p(d.tag_tipo_produto)}).recordCount) invalid('A categoria deve pertencer ao tipo do produto.');
        return d;
    }
    public numeric function saveProduct(required struct context,required struct submitted) {
        authorize(context,true);var id=len(field(submitted,'id_produto'))?identifier(field(submitted,'id_produto')):0;var d={};var before='';
        transaction {
            // Dictionary CRUD locks this table first; validate only after taking the compatible writer lock.
            db('LOCK TABLE comparador.tb_produto IN ROW EXCLUSIVE MODE');
            d=validateProduct(submitted);
            if(id) {
                before=lockProduct(id,field(submitted,'token')).json;
                var editorial=db("SELECT coalesce(e.estado,'publicado') AS estado FROM comparador.tb_produto p LEFT JOIN comparador.tb_produto_editorial e ON e.id_produto=p.id_produto WHERE p.id_produto=:id",{id=p(id,'cf_sql_integer')});
                if(editorial.estado=='publicado' AND (!len(d.tag_marca) OR !len(d.tag_categoria))) invalid('Produtos publicados precisam de marca e categoria. Preencha os vínculos ou mova o produto para rascunho antes de editar.');
            }
            // Serialize equal slugs without imposing a unique index on legacy data.
            db('SELECT pg_advisory_xact_lock(hashtextextended(:slug,0))',{slug=p(d.tag_produto)});
            if(db('SELECT 1 FROM comparador.tb_produto WHERE lower(trim(tag_produto))=:slug AND id_produto<>:id',{slug=p(d.tag_produto),id=p(id,'cf_sql_integer')}).recordCount) invalid('Este endereço já pertence a outro produto.');
            var params={};for(var key in d) params[key]=p(d[key],listFindNoCase('num_versao',key)?'cf_sql_integer':(key=='preco_referencia'?'cf_sql_double':(key=='data_lancamento'?'cf_sql_date':'cf_sql_longvarchar')),!listFindNoCase('nome_produto,tag_tipo_produto,tag_produto,num_versao',key));
            if(id){params.id=p(id,'cf_sql_integer');db('UPDATE comparador.tb_produto SET nome_produto=:nome_produto,tag_tipo_produto=:tag_tipo_produto,tag_marca=:tag_marca,tag_categoria=:tag_categoria,tag_produto=:tag_produto,num_versao=:num_versao,versao=:versao,resumo=:resumo,descricao=:descricao,preco_referencia=:preco_referencia,data_lancamento=:data_lancamento WHERE id_produto=:id',params);}
            else{id=db('INSERT INTO comparador.tb_produto(nome_produto,tag_tipo_produto,tag_marca,tag_categoria,tag_produto,num_versao,versao,resumo,descricao,preco_referencia,data_lancamento) VALUES(:nome_produto,:tag_tipo_produto,:tag_marca,:tag_categoria,:tag_produto,:num_versao,:versao,:resumo,:descricao,:preco_referencia,:data_lancamento) RETURNING id_produto',params).id_produto;}
            audit(id,context,len(before)?'produto_editar':'produto_criar',before,len(before)?'':'rascunho');
        }
        return id;
    }
    public void function changeState(required struct context,required any productId,required string token,required string state) {
        authorize(context,true);var id=identifier(productId);if(!listFind('rascunho,publicado,arquivado',state)) invalid('Estado editorial inválido.');
        transaction {
            db('LOCK TABLE comparador.tb_produto IN ROW EXCLUSIVE MODE');
            var before=lockProduct(id,token);
            if(state=='publicado') {
                var product=db('SELECT * FROM comparador.tb_produto WHERE id_produto=:id',{id=p(id,'cf_sql_integer')});
                var data={};for(var col in listToArray(product.columnList)) data[col]=product[col][1];if(isDate(data.data_lancamento)) data.data_lancamento=dateFormat(data.data_lancamento,"yyyy-mm-dd");validateProduct(data);
                if(!len(trim(product.tag_marca)) OR !len(trim(product.tag_categoria))) invalid('Preencha marca e categoria antes de publicar. O preço pode continuar desconhecido.');
                if(db('SELECT 1 FROM comparador.tb_produto WHERE lower(trim(tag_produto))=:slug AND id_produto<>:id',{slug=p(lCase(trim(product.tag_produto))),id=p(id,'cf_sql_integer')}).recordCount) invalid('Corrija o endereço duplicado antes de publicar.');
            }
            audit(id,context,'estado_' & state,before.json,state);
        }
    }
    public void function saveSpecifications(required struct context,required any productId,required string token,required array features,required array variants) {
        authorize(context,true);var id=identifier(productId);if(arrayLen(features)>100 OR arrayLen(variants)>3) invalid('Quantidade de características ou variantes inválida.');
        transaction {
            db('LOCK TABLE comparador.tb_produto IN ROW EXCLUSIVE MODE');
            var before=lockProduct(id,token);var seen={};
            for(var item in features){
                var featureId=identifier(field(item,'id'),true);var value=field(item,'value',5000);var note=field(item,'note',5000);var tag=field(item,'tag',64);var previous=queryNew('');
                if(featureId){
                    if(structKeyExists(seen,featureId)) invalid('Característica repetida no formulário.');seen[featureId]=true;
                    previous=db('SELECT c.*,pc.caracteristica_dominio FROM comparador.tb_produto_caracteristica pc JOIN comparador.tb_caracteristica c ON c.tag_caracteristica=pc.tag_caracteristica WHERE pc.id_produto=:id AND pc.id_produto_caracteristica=:feature',{id=p(id,'cf_sql_integer'),feature=p(featureId,'cf_sql_integer')});
                    if(!previous.recordCount) invalid('Característica não pertence ao produto.');tag=previous.tag_caracteristica;
                }else{
                    if(!len(tag) AND !len(value) AND !len(note)) continue;
                    previous=db('SELECT c.* FROM comparador.tb_caracteristica c JOIN comparador.tb_caracteristica_compara cc ON cc.tag_caracteristica=c.tag_caracteristica JOIN comparador.tb_produto p ON p.tag_tipo_produto=cc.tag_tipo_produto WHERE p.id_produto=:id AND c.tag_caracteristica=:tag',{id=p(id,'cf_sql_integer'),tag=p(tag)});
                    if(!previous.recordCount) invalid('Escolha uma característica compatível com o tipo do produto.');
                }
                // Existing legacy values remain editable without silently normalizing unknown data.
                var unchanged=featureId AND compare(value,previous.caracteristica_dominio)==0;
                if(!unchanged AND len(value) AND previous.tipo_caracteristica=='number') value=decimalValue(value,true,true);
                if(!unchanged AND len(value) AND previous.tipo_caracteristica=='boolean') {
                    if(!listFindNoCase('true,false,1,0,sim,não,nao',value)) invalid('Use sim/não para uma característica booleana.');
                    value=listFindNoCase('true,1,sim',value)?'true':'false';
                }
                var params={id=p(id,'cf_sql_integer'),tag=p(tag),value=p(value,'cf_sql_longvarchar'),note=p(note,'cf_sql_longvarchar',true)};
                if(featureId){params.feature=p(featureId,'cf_sql_integer');db('UPDATE comparador.tb_produto_caracteristica SET caracteristica_dominio=:value,descricao_complementa=:note WHERE id_produto=:id AND id_produto_caracteristica=:feature',params);}
                else if(len(value) OR len(note)) db('INSERT INTO comparador.tb_produto_caracteristica(id_produto,tag_caracteristica,caracteristica_dominio,descricao_complementa) VALUES(:id,:tag,:value,:note)',params);
            }
            seen={};for(var variant in variants){
                var gender=field(variant,'gender',1);if(!listFind('M,F,U',gender) OR structKeyExists(seen,gender)) invalid('Variantes permitidas: M, F e U, sem repetição.');seen[gender]=true;
                var weight=decimalValue(field(variant,'weight'),true,true);var size=decimalValue(field(variant,'size'),true,true);
                db('INSERT INTO comparador.tb_genero(id_produto,genero,peso,tamanho) VALUES(:id,:gender,:weight,:size) ON CONFLICT(genero,id_produto) DO UPDATE SET peso=EXCLUDED.peso,tamanho=EXCLUDED.tamanho',{id=p(id,'cf_sql_integer'),gender=p(gender),weight=p(weight,'cf_sql_double',true),size=p(size,'cf_sql_double',true)});
            }
            audit(id,context,'caracteristicas',before.json);
        }
    }
    private void function assertOfferAllowed(required numeric productId) {
        // Called under the product lock shared with source synchronization.
        if(db('SELECT 1 FROM comparador.vw_produto_world_athletics WHERE id_produto=:id AND wa_compra_bloqueada',{id=p(productId,'cf_sql_integer')}).recordCount)
            invalid('Protótipo sem opção de compra. Apenas o encerramento de ofertas existentes é permitido.');
    }
    public void function addOffer(required struct context,required any productId,required string token,required struct submitted) {
        authorize(context,true);var id=identifier(productId);var price=decimalValue(field(submitted,'preco_promocional'),false,false);var link=offerUrl(field(submitted,'link',256));var shop=field(submitted,'loja',256);var coupon=field(submitted,'cupom',32);var terms=field(submitted,'condicoes',256);var expiry=isoDate(field(submitted,'data_expiracao'));
        if(!len(shop)) invalid('Informe a loja da oferta.');
        transaction {
            db('LOCK TABLE comparador.tb_produto IN ROW EXCLUSIVE MODE');
            var before=lockProduct(id,token);
            assertOfferAllowed(id);
            db("INSERT INTO comparador.tb_cupom(id_tenis,preco_promocional,link,loja,cupom,condicoes,data_expiracao,data_cadastro) VALUES(:id,:price,:link,:shop,:coupon,:terms,:expiry,(CURRENT_TIMESTAMP AT TIME ZONE 'America/Sao_Paulo')::date)",{id=p(id,'cf_sql_integer'),price=p(price,'cf_sql_double'),link=p(link),shop=p(shop),coupon=p(coupon),terms=p(terms,'cf_sql_varchar',true),expiry=p(expiry,'cf_sql_date',true)});
            audit(id,context,'oferta_criar',before.json);
        }
    }
    public struct function listOffers(required struct context,string search='',string status='',numeric page=1) {
        authorize(context);var params={};var where=' WHERE 1=1';
        if(len(search)){where&=' AND (p.nome_produto ILIKE :search OR o.loja ILIKE :search OR o.cupom ILIKE :search)';params.search=p('%' & left(search,160) & '%');}
        var latest='o.id_cupom=(SELECT max(x.id_cupom) FROM comparador.tb_cupom x WHERE x.id_tenis=o.id_tenis)';
        if(status=='recentes') where&=' AND ' & latest;
        if(status=='anteriores') where&=' AND NOT (' & latest & ')';
        if(status=='vencidas') where&=" AND o.data_expiracao<(CURRENT_TIMESTAMP AT TIME ZONE 'America/Sao_Paulo')::date";
        var from=' FROM comparador.tb_cupom o LEFT JOIN comparador.tb_produto p ON p.id_produto=o.id_tenis LEFT JOIN comparador.vw_produto_world_athletics wa ON wa.id_produto=p.id_produto';
        var total=db('SELECT count(*) AS total' & from & where,params).total;
        var current=max(1,min(ceiling(max(total,1)/25),int(page)));params.offset=p((current-1)*25,'cf_sql_integer');
        var rows=db("SELECT o.*,p.nome_produto,coalesce(wa.wa_compra_bloqueada,false) AS wa_compra_bloqueada,(" & latest & ") AS is_latest,(o.data_expiracao IS NOT NULL AND o.data_expiracao<(CURRENT_TIMESTAMP AT TIME ZONE 'America/Sao_Paulo')::date) AS expired" & from & where & ' ORDER BY o.id_cupom DESC LIMIT 25 OFFSET :offset',params);
        return {rows=rows,total=total,page=current,pages=ceiling(max(total,1)/25)};
    }
    public struct function loadOffer(required struct context,required any offerId) {
        authorize(context);var id=identifier(offerId);
        var found=db('SELECT id_tenis FROM comparador.tb_cupom WHERE id_cupom=:id',{id=p(id,'cf_sql_integer')});
        if(!found.recordCount OR !isNumeric(found.id_tenis)) invalid('Oferta ou produto não encontrado.');
        // Read the concurrency token before the displayed fields. A concurrent change then yields
        // a stale token (and a conflict), never stale fields paired with a newer valid token.
        var snap=snapshot(found.id_tenis);
        var offer=db('SELECT o.*,p.nome_produto,coalesce(wa.wa_compra_bloqueada,false) AS wa_compra_bloqueada FROM comparador.tb_cupom o JOIN comparador.tb_produto p ON p.id_produto=o.id_tenis LEFT JOIN comparador.vw_produto_world_athletics wa ON wa.id_produto=p.id_produto WHERE o.id_cupom=:id AND o.id_tenis=:product',{id=p(id,'cf_sql_integer'),product=p(found.id_tenis,'cf_sql_integer')});
        if(!offer.recordCount) invalid('Oferta ou produto não encontrado.');
        return {offer=offer,token=snap.token};
    }
    public void function updateOffer(required struct context,required any offerId,required string token,required struct submitted,boolean endOffer=false) {
        authorize(context,true);var id=identifier(offerId);var found=loadOffer(context,id);var productId=found.offer.id_tenis;
        var data={};
        if(!endOffer) {
            data.price=decimalValue(field(submitted,'preco_promocional'),false,false);data.link=offerUrl(field(submitted,'link',256));
            data.shop=field(submitted,'loja',256);data.coupon=field(submitted,'cupom',32);data.terms=field(submitted,'condicoes',256);data.expiry=isoDate(field(submitted,'data_expiracao'));
            if(!len(data.shop)) invalid('Informe a loja da oferta.');
        }
        transaction {
            db('LOCK TABLE comparador.tb_produto IN ROW EXCLUSIVE MODE');
            var before=lockProduct(productId,token);
            if(!endOffer) assertOfferAllowed(productId);
            // Keep the row and its ID: removing the latest row would resurrect an older offer.
            var params={id=p(id,'cf_sql_integer'),product=p(productId,'cf_sql_integer')};
            if(endOffer) db("UPDATE comparador.tb_cupom SET data_expiracao=(CURRENT_TIMESTAMP AT TIME ZONE 'America/Sao_Paulo')::date-1 WHERE id_cupom=:id AND id_tenis=:product",params);
            else {
                params.price=p(data.price,'cf_sql_double');params.link=p(data.link);params.shop=p(data.shop);params.coupon=p(data.coupon);params.terms=p(data.terms,'cf_sql_varchar',true);params.expiry=p(data.expiry,'cf_sql_date',true);
                db('UPDATE comparador.tb_cupom SET preco_promocional=:price,link=:link,loja=:shop,cupom=:coupon,condicoes=:terms,data_expiracao=:expiry WHERE id_cupom=:id AND id_tenis=:product',params);
            }
            audit(productId,context,endOffer?'oferta_encerrar':'oferta_editar',before.json);
        }
    }
}
