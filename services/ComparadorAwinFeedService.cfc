component output="false" {
    variables.root='/var/lib/runnerhub/business-awin';
    variables.guard=new services.ComparadorAdminService();
    variables.catalogueService=new services.ComparadorAwinPublicationService();
    variables.source=new services.ComparadorAwinService();
    variables.requiredColumns='aw_deep_link,product_name,aw_product_id,merchant_product_id,merchant_name,merchant_id,search_price,currency,store_price,merchant_deep_link,last_updated,data_feed_id,brand_name,in_stock,stock_status,is_for_sale,pre_order,condition,valid_from,valid_to,product_type,merchant_category,colour,base_price,product_price_old';
    variables.columns=variables.requiredColumns & ',suitable_for,merchant_image_url,aw_image_url,aw_thumb_url,size';
    public any function init(string privateRoot='/var/lib/runnerhub/business-awin') {variables.root=privateRoot;variables.source=new services.ComparadorAwinService().init(privateRoot);return this;}
    private numeric function nowMs(){return createObject('java','java.lang.System').currentTimeMillis();}
    private string function instant(){return createObject('java','java.time.Instant').now().toString();}
    private void function failure(string message='Não foi possível atualizar os preços. A última importação válida foi preservada.') {throw(type='Comparador.Awin',message=message);}
    private string function field(required struct row,required string key){return structKeyExists(row,key) AND isSimpleValue(row[key])?trim(row[key] & ''):'';}
    private numeric function epoch(required string value){return createObject('java','java.time.OffsetDateTime').parse(value).toInstant().toEpochMilli();}
    // Centauro 91869 currently maps integers 1..10 into the optional expiry column.
    // Treat only that observed anomaly as unavailable; never infer a date or discount.
    private boolean function centauroMissingExpiry(required struct row,required struct feed){
        return feed.merchantId=='17806' AND feed.feedId=='91869' AND field(row,'merchant_id')=='17806' AND field(row,'data_feed_id')=='91869' AND reFind('^(?:[1-9]|10)$',field(row,'valid_to'))>0;
    }
    // Price columns below are feed-specific mappings verified against the exact shop variants.
    // Never infer a total from instalments or choose the minimum of unrelated price columns.
    private struct function pricePolicy(required struct feed){
        if(feed.merchantId=='17806' AND feed.feedId=='91869')return {source='base_price',format='brl',type='cash'};
        if(feed.merchantId=='17652' AND feed.feedId=='93360')return {source='base_price',format='brl',type='cash'};
        // The current Nike feed already maps its Pix total to search_price.
        if(feed.merchantId=='17652' AND feed.feedId=='44669')return {source='search_price',format='decimal',type='cash'};
        // Despite its standard name, this ASICS feed maps the current sale total here.
        if(feed.merchantId=='23659' AND feed.feedId=='116576')return {source='product_price_old',format='brl',type='standard'};
        // Olympikus puts the total in this labelled field; base_price_amount is a single instalment.
        if(feed.merchantId=='17698' AND feed.feedId=='51837')return {source='base_price',format='olympikus_total',type='standard'};
        return {source='search_price',format='decimal',type='standard'};
    }
    public string function priceValue(required struct row,required struct feed){
        var policy=pricePolicy(feed);var price=field(row,policy.source);
        if(policy.format=='decimal')return price;
        var amount='';
        if(policy.format=='brl'){
            if(!reFind('^[0-9]{1,6}(\.[0-9]{1,2})? BRL$',price))return '';
            amount=listFirst(price,' ');
        }else if(policy.format=='olympikus_total'){
            if(!reFind('^installament months: R\$ (?:0|[1-9][0-9]{0,5}|[1-9][0-9]{0,2}\.[0-9]{3}),[0-9]{2}$',price))return '';
            var prefix='installament months: R$ ';
            amount=replace(replace(mid(price,len(prefix)+1,len(price)),'.','','all'),',','.','one');
        }else return '';
        // A missing or contradictory mapped price must not fall back to the original price.
        if(val(amount)<=0 OR val(amount)>val(field(row,'search_price')))return '';
        return amount;
    }
    public numeric function offerDateEpoch(required string value,required string name){
        if(!listFind('valid_from,valid_to',name))failure();
        // Awin permits date-only and local date-times. This importer selects BR feeds.
        var zone=createObject('java','java.time.ZoneId').of('America/Sao_Paulo');
        if(reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}$',value)){
            var date=createObject('java','java.time.LocalDate').parse(value);
            if(name=='valid_to')date=date.plusDays(javacast('long',1));
            return date.atStartOfDay(zone).toInstant().toEpochMilli();
        }
        var canonical=replace(value,' ','T','one');
        if(reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]{1,9})?$',canonical))return createObject('java','java.time.LocalDateTime').parse(canonical).atZone(zone).toInstant().toEpochMilli();
        return epoch(canonical);
    }
    private void function atomic(required string path,required string content){
        var temporary=path & '.' & createUUID();
        try {fileWrite(temporary,content,'utf-8');fileSetAccessMode(temporary,'600');if(!createObject('java','java.io.File').init(temporary).renameTo(createObject('java','java.io.File').init(path)))failure();}
        finally {if(fileExists(temporary))fileDelete(temporary);}
    }
    private struct function state(){
        var path=variables.root & '/cache/feed-publication.json';
        if(!fileExists(path))return {schemaVersion=1,publisherId='1455398',updatedAt='',offers=[],feeds=[],blocked={},history=[]};
        try {var result=deserializeJSON(fileRead(path,'utf-8'));if(result.schemaVersion!=1 OR result.publisherId!='1455398' OR !isArray(result.offers) OR !isStruct(result.blocked))failure();return result;}catch(any e){failure('O histórico dos feeds precisa ser conferido. Nenhum vínculo foi substituído.');}
    }
    private string function token(required struct value){return lCase(hash(serializeJSON(value.blocked),'SHA-256'));}
    private string function feedKey(){
        try {
            var settings=deserializeJSON(fileRead(variables.root & '/config.json','utf-8'));var url=field(settings,'feedUrl');
            if((settings.publisherId & '')!='1455398' OR !reFind('^https://productdata\.awin\.com/datafeed/download/apikey/[a-f0-9]{20,64}/',url))failure();
            return listGetAt(url,6,'/');
        }catch(any e){failure('O feed de produtos ainda não foi configurado no servidor.');}
    }
    // URLs are constructed only for Awin; redirects are disabled and response size is checked before parsing.
    private binary function download(required string url,numeric limit=20971520){
        var response={};
        try {
            cfhttp(url=url,method='GET',result='local.response',timeout=20,throwOnError=false,redirect=false,getAsBinary='yes') {cfhttpparam(type='header',name='User-Agent',value='RunnerHub-Awin-Feed/1.0');}
            if(!structKeyExists(response,'statusCode') OR val(response.statusCode)!=200 OR !isBinary(response.fileContent) OR arrayLen(response.fileContent)>limit)failure();
            return response.fileContent;
        }catch(any e){failure();}
    }
    public any function csv(required string text){
        return createObject('java','org.apache.commons.csv.CSVFormat').DEFAULT.withFirstRecordAsHeader().withIgnoreEmptyLines().parse(createObject('java','java.io.StringReader').init(text));
    }
    private string function gunzip(required binary bytes){
        var input=createObject('java','java.util.zip.GZIPInputStream').init(createObject('java','java.io.ByteArrayInputStream').init(bytes));
        try {var decoded=input.readNBytes(javacast('int',83886081));if(arrayLen(decoded)>83886080)failure();return charsetEncode(decoded,'utf-8');}finally{input.close();}
    }
    private array function discover(required string key,required array programmes){
        var approved={};for(var programme in programmes)approved[programme.id & '']={name=programme.name,logo=variables.source.programmeLogo(field(programme,'logoUrl'),programme.id & '')};
        var parser=csv(charsetEncode(download('https://productdata.awin.com/datafeed/list/apikey/' & key,10485760),'utf-8'));var selected={};
        try {
            if(!parser.getHeaderMap().containsKey('Feed ID') OR !parser.getHeaderMap().containsKey('Membership Status'))failure();
            var iterator=parser.iterator();
            while(iterator.hasNext()){
                var row=iterator.next().toMap();var id=field(row,'Advertiser ID');var fid=field(row,'Feed ID');
                if(!structKeyExists(approved,id) OR field(row,'Membership Status')!='active' OR field(row,'Primary Region')!='BR' OR field(row,'Language')!='Portuguese' OR !reFind('^[1-9][0-9]*$',fid))continue;
                var checked=replace(field(row,'Last Checked'),' ','T') & 'Z';var imported=replace(field(row,'Last Imported'),' ','T') & 'Z';
                var checkedMs=epoch(checked);
                if(!structKeyExists(selected,id) OR checkedMs>selected[id].checkedMs)selected[id]={merchantId=id,shop=approved[id].name,shopLogo=approved[id].logo,feedId=fid,name=field(row,'Feed Name'),checkedAt=checked,importedAt=imported,checkedMs=checkedMs};
            }
        }finally{parser.close();}
        var result=[];for(var id in selected)arrayAppend(result,selected[id]);return result;
    }
    private string function normalized(required string value){
        var normal=createObject('java','java.text.Normalizer').normalize(lCase(value),createObject('java','java.text.Normalizer$Form').NFD);
        return trim(normal.replaceAll('\p{M}','').replaceAll('[^a-z0-9]+',' '));
    }
    public struct function indexProducts(required array products){
        var index={};
        for(var product in products){
            if(product.type!='tenis')continue;
            var item=duplicate(product);var brand=normalized(product.brandName);var model=normalized(product.name);var version=normalized(product.version);
            if(left(model,len(brand)+1)==brand & ' ')model=trim(mid(model,len(brand)+2,len(model)));
            if(len(version) AND right(' ' & model,len(version)+1)!=' ' & version)model&=' ' & version;
            if(!len(version) OR len(model)<4)continue;
            item.models=[model];if(brand=='nike' AND left(model,6)=='zoomx ')arrayAppend(item.models,mid(model,7,len(model)));
            if(!structKeyExists(index,brand))index[brand]=[];arrayAppend(index[brand],item);
        }
        return index;
    }
    public array function matchProduct(required struct row,required struct index){
        var title=normalized(field(row,'product_name'));var brand=normalized(field(row,'brand_name'));
        if(!structKeyExists(index,brand) OR !reFind('(^| )tenis( |$)',title))return [];
        var category=normalized(field(row,'merchant_category') & ' ' & field(row,'product_type'));
        if(reFind('(^| )(infantil|kids|junior|bebe|casual|chuteira|vestuario|sandalia|chinelo)( |$)',title & ' ' & category))return [];
        var matches=[];var longest=0;
        for(var product in index[brand]) for(var model in product.models){
            if(!find(' ' & model & ' ',' ' & title & ' '))continue;
            var rest=replace(' ' & title & ' ',' ' & model & ' ',' ','one');rest=replace(rest,' ' & brand & ' ',' ','all');
            // Only presentation terms, sizes and colours may remain around the full model/generation.
            rest=reReplace(rest,'\b(tenis|de|para|corrida|caminhada|running|air|zoom|masculino|feminino|masculina|feminina|unissex|adulto|tam|tamanho|cor|w|m|wmns|branco|branca|preto|preta|azul|verde|rosa|roxo|roxa|vermelho|vermelha|amarelo|amarela|laranja|cinza|prata|dourado|dourada|bege|marrom|lilas|creme|off|white|navy|pink|black|silver|gold|escuro|escura|esc|claro|clara|royal|marinho|turquesa|coral|vinho|bordo|multicolor|multicolorido|natural|gelo|salmao|pessego|lima|agua|menta|cobre|grafite|pink|azl|prt|bco)\b',' ','all');
            rest=reReplace(rest,'\b(3[3-9]|4[0-8])(?: [05])?\b',' ','all');
            if(len(trim(rest)))continue;
            if(len(model)>longest){matches=[product.id];longest=len(model);}else if(len(model)==longest AND !arrayFind(matches,product.id))arrayAppend(matches,product.id);
        }
        return arrayLen(matches)==1?matches:[];
    }
    private string function textGender(required string value){
        var text=normalized(value);var choices=[];
        if(reFind('(^| )(masculino|masculina|male|men|mens|man|homem|homens)( |$)',text))arrayAppend(choices,'M');
        if(reFind('(^| )(feminino|feminina|female|women|womens|woman|mulher|mulheres|wmns)( |$)',text))arrayAppend(choices,'F');
        if(reFind('(^| )(unissex|unisex)( |$)',text))arrayAppend(choices,'U');
        return arrayLen(choices)==1?choices[1]:(arrayLen(choices)>1?'?':'');
    }
    public struct function offerGender(required struct row){
        var explicit=normalized(field(row,'suitable_for'));var fromTitle=textGender(field(row,'product_name'));
        if(fromTitle=='?')return {gender='',genderSource='conflict'};
        var known={masculino='M',masculina='M',male='M',men='M',mens='M',man='M',homem='M',homens='M',feminino='F',feminina='F',female='F',women='F',womens='F',woman='F',mulher='F',mulheres='F',unissex='U',unisex='U'};
        if(len(explicit)){
            if(!structKeyExists(known,explicit))return {gender='',genderSource='unknown'};
            if(len(fromTitle) AND fromTitle!=known[explicit])return {gender='',genderSource='conflict'};
            return {gender=known[explicit],genderSource='suitable_for'};
        }
        return {gender=fromTitle,genderSource=len(fromTitle)?'product_name':'unknown'};
    }
    public string function offerImage(required string value){
        if(!len(value) OR len(value)>2048 OR reFind('[\s\x00-\x1F<>"''\\]',value))return '';
        try{
            var uri=createObject('java','java.net.URI').init(value);
            if(uri.getScheme()!='https' OR isNull(uri.getHost()) OR !isNull(uri.getUserInfo()) OR uri.getPort()!=-1 OR !isNull(uri.getFragment()))return '';
            // Audited merchant CDNs only. Awin's signed image proxy is deliberately not exposed.
            if(!listFindNoCase('imgnike-a.akamaihd.net,imgcentauro-a.akamaihd.net,asicsbr.vteximg.com.br,mizunobr.vteximg.com.br,vulcabras.vteximg.com.br,samsungbrshop.vteximg.com.br',uri.getHost()))return '';
            if(!isNull(uri.getRawQuery()) AND !reFind('^v=[0-9]{1,30}$',uri.getRawQuery()))return '';
            return value;
        }catch(any e){return '';}
    }
    public struct function offerMetadata(required struct row,required struct feed){
        var result=offerGender(row);result.imageUrl=offerImage(field(row,'merchant_image_url'));
        result.color=field(row,'colour');if(len(result.color)>120 OR reFind('[\x00-\x1F<>]',result.color))result.color='';
        result.shopLogo=variables.source.programmeLogo(field(feed,'shopLogo'),feed.merchantId & '');
        return result;
    }
    public string function invalidRow(required struct row,required struct feed){
        if(field(row,'merchant_id')!=feed.merchantId OR field(row,'data_feed_id')!=feed.feedId)return 'identidade';
        if(field(row,'currency')!='BRL' OR !reFind('^[0-9]{1,6}(\.[0-9]{1,2})?$',field(row,'search_price')) OR val(field(row,'search_price'))<=0 OR !len(priceValue(row,feed)))return 'preco';
        var stock=lCase(field(row,'stock_status'));
        if(!listFindNoCase('1,true',field(row,'in_stock')) OR (len(stock) AND !listFindNoCase('in_stock,instock,in stock,available',stock)) OR listFindNoCase('0,false',field(row,'is_for_sale')) OR listFindNoCase('1,true',field(row,'pre_order')))return 'estoque';
        if(len(field(row,'condition')) AND !listFindNoCase('new,novo,nova',field(row,'condition')))return 'condicao';
        for(var name in ['valid_from','valid_to'])if(len(field(row,name))){
            if(name=='valid_to' AND centauroMissingExpiry(row,feed))continue;
            try {var dateValue=offerDateEpoch(field(row,name),name);if((name=='valid_from' AND dateValue>nowMs()) OR (name=='valid_to' AND dateValue<=nowMs()))return 'validade';}catch(any e){return 'validade';}
        }
        var id=field(row,'aw_product_id');
        if(!reFind('^[1-9][0-9]*$',id) OR !reFind('^https://(www\.)?awin1\.com/pclick\.php\?p=' & id & '&a=1455398&m=' & feed.merchantId & '$',field(row,'aw_deep_link')))return 'link';
        return '';
    }
    public struct function importCsv(required string text,required struct feed,required array products){
        var index=indexProducts(products);var byId={};for(var product in products)byId[product.id]=product;
        var result={offers=[],rows=0,matched=0,rejected={},pending=0,warnings={}};var grouped={};var variants={};var parser=csv(text);var fetchedAt=instant();var pricing=pricePolicy(feed);
        try {
            for(var column in listToArray(variables.requiredColumns))if(!parser.getHeaderMap().containsKey(column))failure('O feed mudou de formato. A importação anterior foi preservada.');
            var iterator=parser.iterator();var deadline=nowMs()+50000;
            while(iterator.hasNext()){
                if(result.rows>250000 OR nowMs()>deadline)failure();
                var record=iterator.next();if(!record.isConsistent())failure();var row=record.toMap();result.rows++;
                var reason=invalidRow(row,feed);if(len(reason)){result.rejected[reason]=(structKeyExists(result.rejected,reason)?result.rejected[reason]:0)+1;continue;}
                if(centauroMissingExpiry(row,feed))result.warnings.centauro_expiry_unavailable=(structKeyExists(result.warnings,'centauro_expiry_unavailable')?result.warnings.centauro_expiry_unavailable:0)+1;
                var ids=matchProduct(row,index);if(!arrayLen(ids)){result.pending++;continue;}
                var product=byId[ids[1]];var key=feed.merchantId & ':' & product.id;var price=val(priceValue(row,feed));result.matched++;
                var expires=min(epoch(fetchedAt)+86400000,feed.checkedMs+86400000);
                if(len(field(row,'valid_to')) AND !centauroMissingExpiry(row,feed))expires=min(expires,offerDateEpoch(field(row,'valid_to'),'valid_to'));
                var offer={key=key,productId=product.id,productSlug=product.slug,productBrand=product.brand,productName=product.name,productVersion=product.version,productLabel=product.label,merchantId=feed.merchantId,feedId=feed.feedId,shop=feed.shop,awinProductId=field(row,'aw_product_id'),merchantProductId=field(row,'merchant_product_id'),title=field(row,'product_name'),price=price,priceSource=pricing.source,priceType=pricing.type,currency='BRL',url=field(row,'aw_deep_link'),fetchedAt=fetchedAt,expiresAt=createObject('java','java.time.Instant').ofEpochMilli(javacast('long',expires)).toString(),variants=1};
                structAppend(offer,offerMetadata(row,feed));
                // Keep one exact SKU for each gender, colour and image, without merging another colour's photo.
                var variantKey=lCase(hash(serializeJSON([offer.gender,normalized(offer.color),offer.imageUrl]),'SHA-256'));
                if(!structKeyExists(variants,key))variants[key]={};
                if(!structKeyExists(variants[key],variantKey))variants[key][variantKey]=duplicate(offer);
                else{
                    var variantCount=variants[key][variantKey].variants+1;
                    if(price<variants[key][variantKey].price OR (price==variants[key][variantKey].price AND compare(offer.awinProductId,variants[key][variantKey].awinProductId)<0))variants[key][variantKey]=duplicate(offer);
                    variants[key][variantKey].variants=variantCount;
                }
                if(!structKeyExists(grouped,key))grouped[key]=offer;
                else {var count=grouped[key].variants+1;if(price<grouped[key].price OR (price==grouped[key].price AND compare(offer.awinProductId,grouped[key].awinProductId)<0))grouped[key]=offer;grouped[key].variants=count;}
            }
        }finally{parser.close();}
        for(var key in grouped){
            grouped[key].variantOffers=[];
            for(var variantKey in variants[key])arrayAppend(grouped[key].variantOffers,variants[key][variantKey]);
            arraySort(grouped[key].variantOffers,function(a,b){return a.price==b.price?compare(a.awinProductId,b.awinProductId):(a.price<b.price?-1:1);});
            arrayAppend(result.offers,grouped[key]);
        }
        return result;
    }
    public struct function synchronize(required struct context,required struct data){variables.guard.authorize(context,true);return refresh(data,context.actorId);}
    public struct function synchronizeScheduled(required struct data){return refresh(data,0);}
    private struct function refresh(required struct data,numeric actorId=0){
        if(data.publisherId!='1455398' OR nowMs()-epoch(data.updatedAt)>21600000 OR epoch(data.updatedAt)>nowMs())failure();
        var key=feedKey();
        lock name='business-awin-feed-' & hash(variables.root) type='exclusive' timeout=2 {
            var previous=state();if(len(previous.updatedAt) AND nowMs()-epoch(previous.updatedAt)<60000)return {offers=arrayLen(previous.offers),status='recent'};
            var feeds=discover(key,data.programmes);var offers=[];var reports=[];var errors=0;var deadline=nowMs()+80000;
            var products=variables.catalogueService.catalogue();
            for(var feed in feeds){
                var report=duplicate(feed);structDelete(report,'checkedMs');report.status='ok';report.rows=0;report.matched=0;report.pending=0;report.rejected={};report.warnings={};
                try {
                    if(nowMs()-feed.checkedMs>86400000 OR feed.checkedMs>nowMs()) {report.status='desatualizado';arrayAppend(reports,report);continue;}
                    if(nowMs()>deadline)failure();
                    var url='https://productdata.awin.com/datafeed/download/apikey/' & key & '/fid/' & feed.feedId & '/format/csv/language/pt/delimiter/%2C/compression/gzip/adultcontent/1/columns/' & variables.columns & '/';
                    var imported=importCsv(gunzip(download(url)),feed,products);
                    arrayAppend(offers,imported.offers,true);report.rows=imported.rows;report.matched=imported.matched;report.pending=imported.pending;report.rejected=imported.rejected;report.warnings=imported.warnings;report.offers=arrayLen(imported.offers);
                }catch(any e){report.status='falha';errors++;for(var old in previous.offers)if(old.merchantId==feed.merchantId AND epoch(old.expiresAt)>nowMs())arrayAppend(offers,old);}
                arrayAppend(reports,report);
            }
            var value={schemaVersion=1,publisherId='1455398',updatedAt=instant(),offers=offers,feeds=reports,blocked=previous.blocked,history=previous.history};
            arrayPrepend(value.history,{at=value.updatedAt,actorId=actorId,action='sincronizar',offers=arrayLen(offers),errors=errors});if(arrayLen(value.history)>100)arrayResize(value.history,100);
            atomic(variables.root & '/cache/feed-publication.json',serializeJSON(value));
            return {offers=arrayLen(offers),feeds=arrayLen(feeds),errors=errors,status=errors?'partial':'ok'};
        }
    }
    public struct function dashboard(required struct context){
        variables.guard.authorize(context);var result=state();result.token=token(result);result.configured=false;try{feedKey();result.configured=true;}catch(any e){}return result;
    }
    public void function saveBlock(required struct context,required string key,required string mode,required string expectedToken){
        variables.guard.authorize(context,true);if(!reFind('^[1-9][0-9]*:[1-9][0-9]*$',key) OR !listFind('bloquear,restaurar',mode))throw(type='Comparador.Validation',message='Vínculo inválido.');
        lock name='business-awin-feed-' & hash(variables.root) type='exclusive' timeout=5 {
            var value=state();if(token(value)!=expectedToken)throw(type='Comparador.Conflict',message='A gestão mudou. Recarregue a página antes de salvar.');
            if(mode=='bloquear')value.blocked[key]=true;else structDelete(value.blocked,key);
            arrayPrepend(value.history,{at=instant(),actorId=context.actorId,action=mode,key=key});if(arrayLen(value.history)>100)arrayResize(value.history,100);
            atomic(variables.root & '/cache/feed-publication.json',serializeJSON(value));
        }
    }
}
