component output="false" {
    variables.stateFile='/var/lib/runnerhub/business-awin/cache/publication.json';
    variables.datasource='runner_dba';
    variables.normalizedCache={};
    variables.normalizer=createObject('java','java.text.Normalizer');
    variables.normalizerForm=createObject('java','java.text.Normalizer$Form').NFD;
    variables.guard=new services.ComparadorAdminService();
    variables.source=new services.ComparadorAwinService();
    public any function init(string privateRoot='/var/lib/runnerhub/business-awin',string datasource='runner_dba') {
        variables.stateFile=privateRoot & '/cache/publication.json';variables.datasource=datasource;
        variables.source=new services.ComparadorAwinService().init(privateRoot);return this;
    }
    private void function invalid(required string message) {throw(type='Comparador.Validation',message=message);}
    public string function normalized(required string value) {
        if(structKeyExists(variables.normalizedCache,value))return variables.normalizedCache[value];
        var normalized=variables.normalizer.normalize(lCase(value),variables.normalizerForm);
        // Use Java for Unicode marks: the server's CF regex engine does not implement \p{M}.
        var unaccented=createObject('java','java.lang.String').init(normalized).replaceAll('\p{M}','');
        var result=trim(reReplace(unaccented,'[^a-z0-9]+',' ','all'));
        variables.normalizedCache[value]=result;return result;
    }
    public array function catalogue() {
        var rows=queryExecute("SELECT p.id_produto,p.nome_produto,coalesce(p.versao,'') AS versao,p.tag_produto,p.tag_tipo_produto,p.tag_marca,m.marca FROM comparador.vw_produto_publico p JOIN comparador.tb_marca m ON m.tag_marca=p.tag_marca JOIN comparador.tb_categoria c ON c.tag_categoria=p.tag_categoria AND c.tag_tipo_produto=p.tag_tipo_produto LEFT JOIN comparador.vw_produto_world_athletics wa ON wa.id_produto=p.id_produto WHERE NOT coalesce(wa.wa_compra_bloqueada,false) AND NOT coalesce(wa.wa_prototipo,false) AND p.tag_produto ~ '^[a-z0-9][a-z0-9_-]{0,159}$' AND p.tag_produto NOT IN ('zerar','comparar') AND p.tag_produto NOT LIKE '%-vs-%' ORDER BY m.marca,p.nome_produto,p.num_versao,p.id_produto",{},{datasource=variables.datasource});
        var result=[];for(var row in rows) arrayAppend(result,{id=row.id_produto,name=row.nome_produto,version=row.versao,slug=row.tag_produto,brand=row.tag_marca,brandName=row.marca,type=row.tag_tipo_produto,label=trim(row.marca & ' ' & row.nome_produto & ' ' & row.versao)});
        return result;
    }
    public string function fingerprint(required struct campaign) {
        return lCase(hash(serializeJSON([campaign.advertiserId,campaign.title,campaign.description,campaign.terms,campaign.code,campaign.url,campaign.startDate,campaign.endDate]),'SHA-256'));
    }
    public array function automaticMatches(required struct campaign,required array products) {
        var title=normalized(campaign.title);var matches=[];var longest=0;
        // Broad collections and altered variants need an explicit product selection.
        if(reFind('(^| )(linha|linhas|selecionados|selecionadas|infantil|kids|junior|gtx|gore|wide)( |$)',title)) return [];
        var namedBrands={};for(var candidate in products) {var brandLabel=normalized(candidate.brandName);if(len(brandLabel)>=3 AND find(' ' & brandLabel & ' ',' ' & title & ' '))namedBrands[candidate.brand]=true;}
        for(var product in products) {
            if(!structIsEmpty(namedBrands) AND !structKeyExists(namedBrands,product.brand))continue;
            var model=normalized(product.name);var version=normalized(product.version);var brand=normalized(product.brandName);
            if(left(model,len(brand)+1)==brand & ' ') model=trim(mid(model,len(brand)+2,len(model)));
            if(len(version) AND model!=version AND right(' ' & model,len(version)+1)!=' ' & version) model&=' ' & version;
            if(len(model)<4 OR (listLen(model,' ')<2 AND !reFind('[0-9]',model))) continue;
            var at=find(' ' & model & ' ',' ' & title & ' ');
            if(!at) continue;
            var rest=trim(mid(' ' & title & ' ',at+len(model)+2,len(title)+2));
            if(reFind('^([0-9]|(pro|plus|max|elite|trail|trilha|shield|gtx)( |$))',rest)) continue;
            if(len(model)>longest) {matches=[product.id];longest=len(model);}
            else if(len(model)==longest) arrayAppend(matches,product.id);
        }
        // A matching name is insufficient when more than one catalogue item has that identity.
        return arrayLen(matches)==1 ? matches : [];
    }
    public struct function automaticTriage(required struct campaign,required array products) {
        var result={classification='revisao',products=[],reason='Nenhuma correspondência única com modelo e versão.'};
        var title=normalized(campaign.title);var onlyShoes=arrayLen(products)>0;
        for(var product in products)if(!structKeyExists(product,'type') OR product.type!='tenis')onlyShoes=false;
        // A missing match alone is never evidence that a campaign is outside our catalogue.
        var otherCategory=reFind('^(camisetas?|camisas?|regatas?|bermudas?|shorts|calcas?|calcao|calcoes|jaquetas?|moletons?|kimonos?|vestuario|fardamento|bolas?|chuteiras?|chinelos?|sandalias?|monitor|celular|smartphone|lavadora|televisao|tv|galaxy watch[0-9]*|samsung vision ai tv)( |$)',title)
            OR reFind('(^| )(whey|suplementos?|creatina|chocowheyfer)( |$)',title);
        if(otherCategory) {
            if(onlyShoes AND !reFind('(^| )(tenis|calcados|calcado|sapatilha)( |$)',title)) {
                result.classification='fora_catalogo';result.reason='Triagem automática: categoria identificada no título; o catálogo elegível contém somente tênis.';
            } else result.reason='Categoria ou seleção mista exige conferir os produtos elegíveis.';
            return result;
        }
        if(reFind('(^| )(categoria|categorias|linha|linhas|selecionados|selecionadas|modelos|colecao)( |$)',title)) {
            result.reason='Campanha por categoria ou seleção: confirme quais modelos e gerações são elegíveis.';return result;
        }
        result.products=automaticMatches(campaign,products);
        if(arrayLen(result.products)){result.classification='vinculadas';result.reason='Modelo e versão identificados de forma única no título.';return result;}
        if(!onlyShoes OR !reFind('^tenis ',title) OR reFind('(^| )(linha|linhas|selecionados|selecionadas|modelos|colecao|infantil|kids|junior|gtx|gore|wide)( |$)',title))return result;
        var identity=reReplace(title,'^tenis ((de corrida|de treino|masculino|feminino|unissex|adulto) )*','');
        var brands={};for(var product in products){var brand=normalized(product.brandName);if(len(brand)>=2 AND left(identity,len(brand)+1)==brand & ' ')brands[brand]=true;}
        if(structCount(brands)!=1)return result;
        var brand=structKeyArray(brands)[1];var model=trim(mid(identity,len(brand)+2,len(identity)));
        model=reReplace(model,' (por|a partir de|com desconto|com [0-9]|r [0-9]).*$','');
        model=trim(reReplace(reReplace(model,'^(masculino|feminino|unissex) ',''),' (masculino|feminino|unissex)$',''));
        if(len(model)<4 OR listLen(model,' ')<2 OR listLen(model,' ')>10 OR reFind('(^| )(off|cupom|desconto|e|ou|mais|ganhe)( |$)',model))return result;
        // A complete model in both title and a direct product path is required. Collections stay in review.
        var path='';
        try {
            var uri=createObject('java','java.net.URI').init(campaign.url);
            if(!listFindNoCase('http,https',uri.getScheme() & '') OR isNull(uri.getHost()) OR reFindNoCase('(^|\.)(awin1|awin)\.',uri.getHost()))return result;
            path=uri.getPath() & '';
        } catch(any invalidUrl){return result;}
        if(!reFindNoCase('(\.html|/p)/?$',path) OR reFindNoCase('/(hotsite|busca|search|colecao|collection)/',path))return result;
        path=' ' & normalized(path) & ' ';
        if(!find(' ' & brand & ' ',path) OR !find(' ' & model & ' ',path))return result;
        for(var product in products) {
            if(normalized(product.brandName)!=brand)continue;
            var existing=normalized(product.name);var version=normalized(product.version);
            if(left(existing,len(brand)+1)==brand & ' ')existing=trim(mid(existing,len(brand)+2,len(existing)));
            if(len(version) AND existing!=version AND right(' ' & existing,len(version)+1)!=' ' & version)existing&=' ' & version;
            // Missing generations, duplicate identities and extended variants cannot be ruled out safely.
            if(existing==model OR find(' ' & model & ' ',' ' & existing & ' ') OR find(' ' & existing & ' ',' ' & model & ' '))return result;
        }
        result.classification='fora_catalogo';result.reason='Triagem automática: modelo completo ' & brand & ' ' & model & ' confirmado no título e no endereço do produto, ausente do catálogo elegível.';
        return result;
    }
    public array function newReviewCampaignIds(required array decisions,required array previousDecisions) {
        var previous={};var result=[];
        for(var decision in previousDecisions)if(structKeyExists(decision,'classification') AND decision.classification=='revisao')previous[decision.campaignId & '']=decision;
        for(var decision in decisions)if(decision.classification=='revisao') {
            var key=decision.campaignId & '';
            if(!structKeyExists(previous,key) OR previous[key].fingerprint!=decision.fingerprint OR previous[key].reason!=decision.reason)arrayAppend(result,key);
        }
        return result;
    }
    private struct function state() {
        if(!fileExists(variables.stateFile)) return {schemaVersion=1,rules={},offers=[],decisions=[],history=[],sourceUpdatedAt='',publishedAt='',publisherId='1455398'};
        try {var value=deserializeJSON(fileRead(variables.stateFile,'utf-8'));}
        catch(any e){throw(type='Comparador.Awin',message='O histórico de publicação precisa ser conferido. Nenhuma regra foi substituída.');}
        if(!isStruct(value) OR !structKeyExists(value,'schemaVersion') OR value.schemaVersion!=1 OR !structKeyExists(value,'rules') OR !isStruct(value.rules) OR !structKeyExists(value,'history') OR !isArray(value.history)) throw(type='Comparador.Awin',message='Formato de publicação inválido.');
        return value;
    }
    private string function stateToken() {return fileExists(variables.stateFile)?lCase(hash(fileRead(variables.stateFile,'utf-8'),'SHA-256')):lCase(hash('empty','SHA-256'));}
    private void function writeState(required struct value) {
        var temporary=variables.stateFile & '.' & createUUID();
        try {
            fileWrite(temporary,serializeJSON(value),'utf-8');fileSetAccessMode(temporary,'600');
            if(!createObject('java','java.io.File').init(temporary).renameTo(createObject('java','java.io.File').init(variables.stateFile))) throw(message='Atomic publication failed');
        } finally {if(fileExists(temporary))fileDelete(temporary);}
    }
    public struct function plan(required struct data,required array products,required struct rules) {
        var byId={};for(var product in products)byId[product.id]=product;
        var result={offers=[],decisions=[],published=0,pending=0,outsideCatalog=0,blocked=0};
        for(var campaign in data.promotions) {
            var ids=[];var mode='automatico';var reason='Nenhuma correspondência única com modelo e versão.';var key=campaign.id & '';var signature=fingerprint(campaign);
            if(structKeyExists(rules,key)) {
                var rule=rules[key];mode=rule.mode;
                if(mode=='bloqueado'){reason='Publicação bloqueada pelo administrador.';}
                else if(rule.fingerprint!=signature){mode='revisar';reason='A campanha mudou desde a confirmação. Confira a elegibilidade novamente.';}
                else if(mode=='fora_catalogo') {
                    var currentMatches=automaticMatches(campaign,products);var reviewedMatches=structKeyExists(rule,'catalogueMatches') AND isArray(rule.catalogueMatches)?rule.catalogueMatches:[];
                    if(arrayLen(currentMatches) AND !arrayFind(reviewedMatches,currentMatches[1])){mode='revisar';reason='Há uma correspondência no catálogo após a revisão anterior. Confira a elegibilidade.';}
                    else reason=structKeyExists(rule,'reason') AND len(trim(rule.reason))?rule.reason:'Campanha revisada sem produto correspondente no catálogo.';
                }
                else if(mode=='revisar'){reason='Campanha reaberta para revisão pelo administrador.';}
                else {ids=duplicate(rule.products);reason='Produtos confirmados pelo administrador.';}
            } else {
                var triage=automaticTriage(campaign,products);ids=triage.products;reason=triage.reason;
                if(triage.classification=='fora_catalogo')mode='fora_catalogo';
            }
            var eligible=[];var labels=[];
            for(var id in ids)if(structKeyExists(byId,id)) {arrayAppend(eligible,id);arrayAppend(labels,byId[id].label);}
            if(arrayLen(eligible)!=arrayLen(ids)){mode='revisar';eligible=[];labels=[];reason='Um produto deixou de estar elegível para compra no catálogo.';}
            if(!len(campaign.trackingUrl) AND mode!='fora_catalogo'){eligible=[];labels=[];reason='Campanha sem link de afiliado válido.';}
            var classification='revisao';
            if(mode=='bloqueado'){result.blocked++;classification='bloqueadas';}
            else if(mode=='fora_catalogo'){result.outsideCatalog++;classification='fora_catalogo';}
            else if(arrayLen(eligible)){result.published++;classification='vinculadas';}
            else result.pending++;
            arrayAppend(result.decisions,{campaignId=key,title=campaign.title,advertiser=campaign.advertiser,mode=mode,classification=classification,origin=structKeyExists(rules,key)?'editorial':'automatico',products=eligible,labels=labels,reason=reason,state=campaign.state,fingerprint=signature});
            for(var id in eligible) {
                var product=byId[id];
                arrayAppend(result.offers,{campaignId=key,productId=id,productSlug=product.slug,productBrand=product.brand,productName=product.name,productVersion=product.version,title=campaign.title,description=campaign.description,terms=campaign.terms,coupon=campaign.code,shop=campaign.advertiser,merchantId=campaign.advertiserId,shopLogo=structKeyExists(campaign,'shopLogo')?variables.source.programmeLogo(campaign.shopLogo,campaign.advertiserId):'',url=campaign.trackingUrl,startDate=campaign.startDate,endDate=campaign.endDate,endLabel=campaign.endLabel,mode=mode});
            }
        }
        return result;
    }
    private struct function reconcile(required struct data,required array products,required struct previous,numeric actorId=0,string action='sincronizar') {
        if((data.publisherId & '')!='1455398' OR !len(data.updatedAt)) throw(type='Comparador.Awin',message='Conta ou consulta de origem inválida.');
        var age=createObject('java','java.lang.System').currentTimeMillis()-createObject('java','java.time.OffsetDateTime').parse(data.updatedAt).toInstant().toEpochMilli();
        if(age<0 OR age>21600000) throw(type='Comparador.Awin',message='Atualize a consulta da Awin antes de publicar.');
        if(len(previous.sourceUpdatedAt) AND createObject('java','java.time.OffsetDateTime').parse(data.updatedAt).toInstant().isBefore(createObject('java','java.time.OffsetDateTime').parse(previous.sourceUpdatedAt).toInstant())) throw(type='Comparador.Conflict',message='Uma consulta mais recente já foi publicada. Recarregue a página.');
        var result=plan(data,products,previous.rules);
        var newReviews=newReviewCampaignIds(result.decisions,structKeyExists(previous,'decisions') AND isArray(previous.decisions)?previous.decisions:[]);
        var instant=createObject('java','java.time.Instant').now().toString();
        var value={schemaVersion=1,publisherId=data.publisherId,sourceUpdatedAt=data.updatedAt,publishedAt=instant,rules=previous.rules,offers=result.offers,decisions=result.decisions,history=previous.history};
        arrayPrepend(value.history,{at=instant,actorId=actorId,action=action,offers=arrayLen(result.offers),pending=result.pending,outsideCatalog=result.outsideCatalog,newReviewCount=arrayLen(newReviews),newReviewCampaignIds=newReviews,rules=duplicate(previous.rules)});
        if(arrayLen(value.history)>100)arrayResize(value.history,100);
        writeState(value);return {offers=arrayLen(result.offers),campaigns=result.published,pending=result.pending,outsideCatalog=result.outsideCatalog,blocked=result.blocked,newReviewCount=arrayLen(newReviews),newReviewCampaignIds=newReviews,publishedAt=instant};
    }
    public struct function synchronize(required struct context,required struct data) {
        variables.guard.authorize(context,true);
        lock name='business-awin-publication-' & hash(variables.stateFile) type='exclusive' timeout=10 {return reconcile(data,catalogue(),state(),context.actorId);}
    }
    // Server-side entry point, called only by the authenticated scheduler endpoint; never remote.
    public struct function synchronizeScheduled() {
        var data=variables.source.refreshScheduled();
        lock name='business-awin-publication-' & hash(variables.stateFile) type='exclusive' timeout=10 {return reconcile(data,catalogue(),state());}
    }
    public struct function dashboard(required struct context,required struct data) {
        variables.guard.authorize(context);var current={};var token='';
        lock name='business-awin-publication-' & hash(variables.stateFile) type='readonly' timeout=10 {token=stateToken();current=state();}
        var products=catalogue();var pending=plan(data,products,current.rules);
        return {plan=pending,products=products,token=token,history=current.history,publishedAt=current.publishedAt,rules=current.rules};
    }
    public void function saveRule(required struct context,required struct data,required string campaignId,required string mode,required string productIds,required string token,required string campaignFingerprint,string reviewReason='') {
        variables.guard.authorize(context,true);
        if(!listFind('manual,bloqueado,automatico,fora_catalogo,revisar',mode))invalid('Escolha uma ação válida.');
        reviewReason=variables.guard.field({reason=reviewReason},'reason',1000);
        if(mode=='fora_catalogo' AND len(reviewReason)<8)invalid('Informe o motivo de a campanha estar fora do catálogo, com pelo menos 8 caracteres.');
        var campaign={};for(var item in data.promotions)if(item.id & ''==campaignId)campaign=item;
        if(structIsEmpty(campaign) OR fingerprint(campaign)!=campaignFingerprint)invalid('A campanha mudou. Reabra a página antes de confirmar.');
        var ids=[];var seen={};
        if(mode=='manual') {
            if(!reFind('^[1-9][0-9]*(,[1-9][0-9]*){0,19}$',productIds))invalid('Escolha de 1 a 20 produtos elegíveis.');
            for(var id in listToArray(productIds))if(!structKeyExists(seen,id)){arrayAppend(ids,val(id));seen[id]=true;}
        }
        lock name='business-awin-publication-' & hash(variables.stateFile) type='exclusive' timeout=10 {
            if(token!=stateToken())throw(type='Comparador.Conflict',message='A publicação mudou. Recarregue a página e confira antes de salvar.');
            var current=state();var products=catalogue();var eligible={};for(var product in products)eligible[product.id]=true;
            for(var id in ids)if(!structKeyExists(eligible,id))invalid('Produto indisponível para compra no catálogo.');
            if(mode=='automatico')structDelete(current.rules,campaignId);
            else {
                current.rules[campaignId]={mode=mode,products=ids,fingerprint=campaignFingerprint,actorId=context.actorId};
                if(mode=='fora_catalogo'){current.rules[campaignId].reason=reviewReason;current.rules[campaignId].catalogueMatches=automaticMatches(campaign,products);current.rules[campaignId].reviewedAt=createObject('java','java.time.Instant').now().toString();}
            }
            reconcile(data,products,current,context.actorId,'regra_' & mode & '_' & campaignId);
        }
    }
}
