component output="false" {
    variables.datasource='runner_dba';
    variables.guard=new services.ComparadorAdminService();
    public any function init(string datasource='runner_dba') {variables.datasource=arguments.datasource;return this;}
    private query function db(required string sql) {return queryExecute(sql,{},{datasource=variables.datasource,timeout=30});}
    private void function invalid(required string message) {throw(type='Comparador.Validation',message=message);}
    private string function choice(required struct input,required string key,required string choices,required string fallback) {
        var value=variables.guard.field(input,key,32);
        if(!len(value))return fallback;
        if(!listFind(choices,value))invalid('Confira o filtro ' & key & '.');
        return value;
    }
    public boolean function ready(required struct context) {
        variables.guard.authorize(context);
        return db("SELECT to_regclass('comparador.tb_produto_editorial') IS NOT NULL AND to_regclass('comparador.vw_produto_world_athletics') IS NOT NULL AND to_regclass('comparador.tb_marca_curadoria') IS NOT NULL AND to_regclass('comparador.tb_wa_sincronizacao') IS NOT NULL AS ready").ready;
    }
    private query function inventory() {
        // Aggregate each one-to-many relation before joining: one row per product.
        return db("WITH features AS (
 SELECT id_produto,
 bool_or(lower(trim(caracteristica_dominio)) IN ('true','false','1','0')) FILTER(WHERE tag_caracteristica='placa') AS placa,
 bool_or(lower(trim(caracteristica_dominio)) IN ('true','1')) FILTER(WHERE tag_caracteristica='placa') AS placa_sim,
 bool_or(trim(coalesce(caracteristica_dominio,''))<>'' AND lower(trim(caracteristica_dominio)) NOT IN ('não informado','nao informado','n/a','-')) FILTER(WHERE tag_caracteristica='placa_material') AS material,
 bool_or(CASE WHEN trim(caracteristica_dominio) ~ '^[0-9]+([.,][0-9]+)?$' THEN replace(trim(caracteristica_dominio),',','.')::numeric>5 AND replace(trim(caracteristica_dominio),',','.')::numeric<2000 ELSE false END) FILTER(WHERE tag_caracteristica='peso_referencia') AS peso_referencia,
 bool_or(CASE WHEN trim(caracteristica_dominio) ~ '^[0-9]+([.,][0-9]+)?$' THEN replace(trim(caracteristica_dominio),',','.')::numeric>=0 ELSE false END) FILTER(WHERE tag_caracteristica='tamanho_drop') AS drop,
 bool_or(CASE WHEN trim(caracteristica_dominio) ~ '^[0-9]+([.,][0-9]+)?$' THEN replace(trim(caracteristica_dominio),',','.')::numeric>=0 ELSE false END) FILTER(WHERE tag_caracteristica='altura_frontal') AS frontal,
 bool_or(CASE WHEN trim(caracteristica_dominio) ~ '^[0-9]+([.,][0-9]+)?$' THEN replace(trim(caracteristica_dominio),',','.')::numeric>=0 ELSE false END) FILTER(WHERE tag_caracteristica='altura_calcanhar') AS calcanhar,
 bool_or(trim(coalesce(caracteristica_dominio,''))<>'' AND lower(trim(caracteristica_dominio)) NOT IN ('não informado','nao informado','n/a','-','null')) FILTER(WHERE tag_caracteristica='entresola') AS entressola,
 bool_or(trim(coalesce(caracteristica_dominio,''))<>'' AND lower(trim(caracteristica_dominio)) NOT IN ('não informado','nao informado','n/a','-','null')) FILTER(WHERE tag_caracteristica='cabedal') AS cabedal,
 bool_or(trim(coalesce(caracteristica_dominio,''))<>'' AND lower(trim(caracteristica_dominio)) NOT IN ('não informado','nao informado','n/a','-','null')) FILTER(WHERE tag_caracteristica='solado') AS solado
 FROM comparador.tb_produto_caracteristica GROUP BY id_produto
), weights AS (
 SELECT id_produto,bool_or(peso>0 AND peso<'Infinity'::float8) AS peso FROM comparador.tb_genero GROUP BY id_produto
), media AS (
 SELECT id_produto,true AS foto FROM comparador.tb_media WHERE media_tipo IN ('M','F','U') AND trim(coalesce(media_url,''))<>'' GROUP BY id_produto
), offers AS (
 SELECT DISTINCT ON(id_tenis) id_tenis,preco_promocional,data_expiracao,link FROM comparador.tb_cupom ORDER BY id_tenis,id_cupom DESC
)
SELECT p.id_produto,p.nome_produto,coalesce(p.versao,'') AS versao,coalesce(p.tag_marca,'') AS tag_marca,coalesce(m.marca,'Marca não informada') AS marca,
p.tag_tipo_produto AS tipo,coalesce(t.nome_tipo_produto,p.tag_tipo_produto) AS nome_tipo,coalesce(e.estado,'publicado') AS estado,
coalesce(mc.presente_brasil,false) AS brasil,coalesce(wa.wa_prototipo,false) AS prototipo,coalesce(wa.wa_status,'nao_verificado') AS wa_status,
coalesce(w.peso,false) AS peso_variante,coalesce(f.peso_referencia,false) AS peso_referencia,
coalesce(f.placa,false) AS f_placa,coalesce(f.placa_sim,false) AS placa_sim,coalesce(f.material,false) AS f_material,
(coalesce(md.foto,false) OR coalesce(wa.wa_foto_url,'') ~* '^https://certcheck[.]worldathletics[.]org/OpenDocument/[0-9a-f-]{36}$') AS f_foto,
(trim(coalesce(p.descricao,''))<>'') AS f_descricao,
(m.tag_marca IS NOT NULL AND c.tag_categoria IS NOT NULL AND c.tag_tipo_produto=p.tag_tipo_produto AND t.tag_tipo_produto IS NOT NULL) AS f_vinculos,
(p.data_lancamento IS NOT NULL) AS f_lancamento,
(p.preco_referencia>0 AND p.preco_referencia<'Infinity'::float8) IS TRUE AS f_preco,
(coalesce(o.preco_promocional,0)>0 AND o.preco_promocional<'Infinity'::float8 AND o.link ~* '^https?://' AND (o.data_expiracao IS NULL OR o.data_expiracao >= (CURRENT_TIMESTAMP AT TIME ZONE 'America/Sao_Paulo')::date)) IS TRUE AS oferta_banco,
coalesce(f.drop,false) AS f_drop,
coalesce(f.frontal,false) AS f_frontal,
coalesce(f.calcanhar,false) AS f_calcanhar,
coalesce(f.entressola,false) AS f_entressola,
coalesce(f.cabedal,false) AS f_cabedal,
coalesce(f.solado,false) AS f_solado
FROM comparador.tb_produto p
LEFT JOIN comparador.tb_produto_editorial e USING(id_produto)
LEFT JOIN comparador.tb_marca m ON m.tag_marca=p.tag_marca
LEFT JOIN comparador.tb_marca_curadoria mc ON mc.tag_marca=p.tag_marca
LEFT JOIN comparador.tb_tipo_produto t ON t.tag_tipo_produto=p.tag_tipo_produto
LEFT JOIN comparador.tb_categoria c ON c.tag_categoria=p.tag_categoria
LEFT JOIN comparador.vw_produto_world_athletics wa USING(id_produto)
LEFT JOIN features f USING(id_produto)
LEFT JOIN weights w USING(id_produto)
LEFT JOIN media md USING(id_produto)
LEFT JOIN offers o ON o.id_tenis=p.id_produto
ORDER BY p.id_produto");
    }
    public struct function load(required struct context,struct input={}) {
        variables.guard.authorize(context);
        var filters={aba=choice(input,'aba','resumo,cobertura,prioridades','resumo'),escopo=choice(input,'escopo','comerciais,publicados,rascunhos,prototipos,arquivados,todos','comerciais'),mercado=choice(input,'mercado','todos,brasil,sem_marcacao','todos'),falta=choice(input,'falta','tecnica,peso,placa,foto,lancamento,descricao,vinculos,preco,wa,drop,frontal,calcanhar,entressola,cabedal,solado,material,todos','tecnica'),tipo=variables.guard.field(input,'tipo',64),marca=variables.guard.field(input,'marca',64),busca=variables.guard.field(input,'busca',160)};
        if(!len(filters.tipo))filters.tipo='tenis';
        var requested=variables.guard.field(input,'pagina',7);
        if(len(requested) AND !reFind('^[1-9][0-9]{0,6}$',requested))invalid('Confira a página solicitada.');
        var page=len(requested)?val(requested):1;
        var all=inventory();var selected=[];var brands={};var types={};var overall={total=all.recordCount,publicado=0,rascunho=0,arquivado=0,prototipos=0};
        for(var r in all) {
            overall[r.estado]++;
            if(r.prototipo AND r.estado!='arquivado')overall.prototipos++;
            brands[r.tag_marca]={tag=r.tag_marca,nome=r.marca,brasil=r.brasil};types[r.tipo]={tag=r.tipo,nome=r.nome_tipo};
            r.tecnico=r.tipo=='tenis' AND r.estado!='arquivado' AND !r.prototipo;
            r.f_peso=r.peso_variante OR r.peso_referencia;
            if(filters.tipo!='todos' AND r.tipo!=filters.tipo)continue;
            if(len(filters.marca) AND r.tag_marca!=filters.marca)continue;
            if(filters.mercado=='brasil' AND !r.brasil)continue;
            if(filters.mercado=='sem_marcacao' AND r.brasil)continue;
            if(filters.escopo=='comerciais' AND (r.estado=='arquivado' OR r.prototipo))continue;
            if(filters.escopo=='prototipos' AND (!r.prototipo OR r.estado=='arquivado'))continue;
            if(listFind('publicados,rascunhos,arquivados',filters.escopo) AND r.estado!=({publicados='publicado',rascunhos='rascunho',arquivados='arquivado'}[filters.escopo]))continue;
            if(len(filters.busca) AND !findNoCase(filters.busca,r.marca & ' ' & r.nome_produto & ' ' & r.versao & ' ' & r.id_produto))continue;
            arrayAppend(selected,r);
        }
        if(filters.tipo!='todos' AND !structKeyExists(types,filters.tipo))invalid('Tipo de produto não encontrado.');
        if(len(filters.marca) AND !structKeyExists(brands,filters.marca))invalid('Marca não encontrada.');
        var coverage=[];
        for(var field in [{key='foto',nome='Referência de foto',base='todos'},{key='descricao',nome='Descrição cadastrada',base='todos'},{key='vinculos',nome='Marca, tipo e categoria válidos',base='todos'},{key='lancamento',nome='Data de lançamento',base='todos'},{key='preco',nome='Preço de referência',base='todos'},{key='peso',nome='Peso documentado',base='tecnico'},{key='placa',nome='Presença de placa definida',base='tecnico'},{key='material',nome='Material da placa',base='placa'},{key='drop',nome='Drop',base='tecnico'},{key='frontal',nome='Altura frontal',base='tecnico'},{key='calcanhar',nome='Altura do calcanhar',base='tecnico'},{key='entressola',nome='Entressola',base='tecnico'},{key='cabedal',nome='Cabedal',base='tecnico'},{key='solado',nome='Solado',base='tecnico'}]) {
            field.total=0;field.ok=0;
            for(var r in selected)if(field.base=='todos' OR (r.tecnico AND (field.base=='tecnico' OR r.placa_sim))){field.total++;if(r['f_' & field.key])field.ok++;}
            field.faltando=field.total-field.ok;field.percentual=field.total?round(field.ok*1000/field.total)/10:0;arrayAppend(coverage,field);
        }
        var stats={total=arrayLen(selected),comerciais=0,completos=0,pendentes=0,sem_peso=0,sem_placa=0,sem_foto=0,peso_variante=0,peso_referencia=0,ofertas_banco=0,wa_aprovados=0,wa_restricoes=0,wa_expirados=0,wa_nao_verificados=0,wa_nao_aprovados=0,marcas=0};
        var grouped={};var pending=[];
        for(var r in selected) {
            if(!structKeyExists(grouped,r.tag_marca))grouped[r.tag_marca]={tag=r.tag_marca,nome=r.marca,brasil=r.brasil,total=0,tecnicos=0,pendentes=0,sem_peso=0,sem_placa=0,sem_foto=0};
            var brand=grouped[r.tag_marca];brand.total++;
            if(!r.f_foto){stats.sem_foto++;brand.sem_foto++;}
            if(r.oferta_banco AND !r.prototipo AND r.estado!='arquivado')stats.ofertas_banco++;
            var waKey={aprovado='wa_aprovados',aprovado_restricoes='wa_restricoes',prazo_expirado='wa_expirados',nao_verificado='wa_nao_verificados',nao_aprovado='wa_nao_aprovados'};
            if(structKeyExists(waKey,r.wa_status))stats[waKey[r.wa_status]]++;
            if(r.tecnico){
                stats.comerciais++;brand.tecnicos++;
                if(r.peso_variante)stats.peso_variante++;if(r.peso_referencia AND !r.peso_variante)stats.peso_referencia++;
                if(r.f_peso AND r.f_placa)stats.completos++;else{stats.pendentes++;brand.pendentes++;}
                if(!r.f_peso){stats.sem_peso++;brand.sem_peso++;}if(!r.f_placa){stats.sem_placa++;brand.sem_placa++;}
            }
            var matches=filters.falta=='todos' OR (filters.falta=='tecnica' AND r.tecnico AND (!r.f_peso OR !r.f_placa)) OR (filters.falta=='wa' AND r.wa_status=='nao_verificado');
            if(listFind('peso,placa,drop,frontal,calcanhar,entressola,cabedal,solado,material',filters.falta))matches=r.tecnico AND (filters.falta!='material' OR r.placa_sim) AND !r['f_' & filters.falta];
            if(listFind('foto,lancamento,descricao,vinculos,preco',filters.falta))matches=!r['f_' & filters.falta];
            if(matches){
                r.faltas=[];r.prioridade=0;
                for(var field in coverage)if((field.base=='todos' OR (r.tecnico AND (field.base=='tecnico' OR r.placa_sim))) AND !r['f_' & field.key])arrayAppend(r.faltas,field.nome);
                if(r.tecnico AND !r.f_peso)r.prioridade+=2;if(r.tecnico AND !r.f_placa)r.prioridade+=2;if(!r.f_foto)r.prioridade+=3;if(!r.f_vinculos)r.prioridade+=4;if(!r.f_descricao)r.prioridade+=2;
                arrayAppend(pending,r);
            }
        }
        stats.marcas=structCount(grouped);
        var brandRows=[];for(var key in grouped)arrayAppend(brandRows,grouped[key]);
        arraySort(brandRows,function(a,b){if(a.brasil!=b.brasil)return a.brasil?-1:1;if(a.pendentes!=b.pendentes)return b.pendentes-a.pendentes;return compareNoCase(a.nome,b.nome);});
        arraySort(pending,function(a,b){if(a.brasil!=b.brasil)return a.brasil?-1:1;if(a.prioridade!=b.prioridade)return b.prioridade-a.prioridade;var byBrand=compareNoCase(a.marca,b.marca);if(byBrand)return byBrand;return a.id_produto-b.id_produto;});
        var total=arrayLen(pending);page=min(page,max(1,ceiling(total/25)));var queue=[];for(var i=(page-1)*25+1;i<=min(total,page*25);i++)arrayAppend(queue,pending[i]);
        var brandOptions=[];for(var key in brands)if(len(key))arrayAppend(brandOptions,brands[key]);arraySort(brandOptions,function(a,b){return compareNoCase(a.nome,b.nome);});
        var typeOptions=[];for(var key in types)arrayAppend(typeOptions,types[key]);arraySort(typeOptions,function(a,b){return compareNoCase(a.nome,b.nome);});
        var sync=db("SELECT coalesce(to_char(consultado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI'),'') AS consultado,total_origem,coalesce((resultado->>'alterados')::integer,0) AS alterados,coalesce((resultado->>'produtos_criados')::integer,0) AS novos FROM comparador.tb_wa_sincronizacao ORDER BY aplicado_em DESC LIMIT 1");
        return {filters=filters,overall=overall,stats=stats,coverage=coverage,brands=brandRows,queue=queue,total=total,page=page,pages=max(1,ceiling(total/25)),brandOptions=brandOptions,typeOptions=typeOptions,sync=sync,consultado=dateTimeFormat(now(),'dd/mm/yyyy HH:nn')};
    }
}
