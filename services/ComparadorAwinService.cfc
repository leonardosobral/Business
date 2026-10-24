component output="false" {
    variables.configFile='/var/lib/runnerhub/business-awin/config.json';
    variables.snapshotFile='/var/lib/runnerhub/business-awin/cache/snapshot.json';
    variables.guard=new services.ComparadorAdminService();
    public any function init(string privateRoot='/var/lib/runnerhub/business-awin') {
        variables.configFile=privateRoot & '/config.json';
        variables.snapshotFile=privateRoot & '/cache/snapshot.json';
        return this;
    }

    private void function unavailable(string message='Não foi possível consultar a Awin. A última consulta foi preservada.') {
        throw(type='Comparador.Awin',message=message);
    }
    private struct function config() {
        if(!fileExists(variables.configFile)) unavailable('A conexão Awin ainda não foi configurada no servidor.');
        try {var settings=deserializeJSON(fileRead(variables.configFile,'utf-8'));}
        catch(any e){unavailable('A configuração Awin precisa ser conferida no servidor.');}
        if(!isStruct(settings) OR !structKeyExists(settings,'publisherId') OR !reFind('^[1-9][0-9]{0,12}$',settings.publisherId & '') OR !structKeyExists(settings,'token') OR !isSimpleValue(settings.token) OR !len(trim(settings.token))) unavailable('A configuração Awin está incompleta.');
        return settings;
    }
    private string function text(required struct item,required string key) {
        return structKeyExists(item,key) AND isSimpleValue(item[key]) ? item[key] & '' : '';
    }
    public string function safeUrl(required string value,boolean tracking=false) {
        if(!len(value) OR len(value)>8192 OR reFind('[\s\x00-\x1F<>"''\\]',value)) return '';
        try {
            var uri=createObject('java','java.net.URI').init(value);
            if(uri.getScheme()!='https' OR isNull(uri.getHost()) OR !isNull(uri.getUserInfo())) return '';
            if(tracking AND !listFindNoCase('www.awin1.com,awin1.com,www.awin.com,awin.com,tidd.ly',uri.getHost())) return '';
        } catch(any e){return '';}
        return value;
    }
    public string function programmeLogo(required string value,required string advertiserId) {
        if(!reFind('^[1-9][0-9]{0,12}$',advertiserId))return '';
        var url=safeUrl(value);
        // Use the advertiser logo supplied by Awin; never synthesize a brand asset.
        return reFind('^https://ui\.awin\.com/images/upload/merchant/profile/' & advertiserId & '\.(png|jpg|jpeg|webp)$',url)?url:'';
    }
    private numeric function epoch(required string value) {
        try {return createObject('java','java.time.OffsetDateTime').parse(value).toInstant().toEpochMilli();}
        catch(any e){unavailable('A Awin retornou uma data de validade inesperada.');}
    }
    public string function localTime(required string value) {
        try {
            var instant=createObject('java','java.time.OffsetDateTime').parse(value).toInstant();
            var zone=createObject('java','java.time.ZoneId').of('America/Sao_Paulo');
            var formatter=createObject('java','java.time.format.DateTimeFormatter').ofPattern('dd/MM/yyyy HH:mm');
            return instant.atZone(zone).format(formatter);
        } catch(any e){return 'Data não informada';}
    }
    public struct function normalizePromotion(required struct raw,required struct joined,numeric nowMs=0) {
        if(!structKeyExists(raw,'advertiser') OR !isStruct(raw.advertiser)) unavailable();
        var advertiserId=text(raw.advertiser,'id');var id=text(raw,'promotionId');
        if(!reFind('^[1-9][0-9]{0,12}$',id) OR !structKeyExists(joined,advertiserId)) return {};
        if(!structKeyExists(raw.advertiser,'joined') OR !isBoolean(raw.advertiser.joined) OR !raw.advertiser.joined) return {};
        var brazil=false;
        if(structKeyExists(raw,'regions') AND isStruct(raw.regions)) {
            brazil=structKeyExists(raw.regions,'all') AND isBoolean(raw.regions.all) AND raw.regions.all;
            if(structKeyExists(raw.regions,'list') AND isArray(raw.regions.list)) for(var region in raw.regions.list) if(isStruct(region) AND text(region,'countryCode')=='BR') brazil=true;
        }
        if(!brazil) return {};
        var start=text(raw,'startDate');var ending=text(raw,'endDate');
        var startMs=epoch(start);var endMs=epoch(ending);
        if(endMs<startMs) unavailable('A Awin retornou uma validade inconsistente.');
        if(nowMs==0) nowMs=createObject('java','java.lang.System').currentTimeMillis();
        var type=text(raw,'type');if(!listFind('promotion,voucher',type)) unavailable();
        var code='';if(structKeyExists(raw,'voucher') AND isStruct(raw.voucher)) code=text(raw.voucher,'code');
        return {id=id,advertiserId=advertiserId,advertiser=joined[advertiserId].name,shopLogo=programmeLogo(text(joined[advertiserId],'logoUrl'),advertiserId),title=text(raw,'title'),description=text(raw,'description'),terms=text(raw,'terms'),type=type,code=code,startDate=start,endDate=ending,startLabel=localTime(start),endLabel=localTime(ending),state=nowMs<startMs?'upcoming':(nowMs>endMs?'expired':'active'),url=safeUrl(text(raw,'url')),trackingUrl=safeUrl(text(raw,'urlTracking'),true)};
    }
    private any function requestApi(required struct settings,required string path,string method='GET',struct body={}) {
        var response={};
        try {
            cfhttp(url='https://api.awin.com' & path,method=method,result='local.response',timeout=25,throwOnError=false,redirect=false) {
                cfhttpparam(type='header',name='Authorization',value='Bearer ' & settings.token);
                cfhttpparam(type='header',name='Accept',value='application/json');
                if(method=='POST') {
                    cfhttpparam(type='header',name='Content-Type',value='application/json');
                    cfhttpparam(type='body',value=serializeJSON(body));
                }
            }
        } catch(any e){unavailable();}
        var status=structKeyExists(response,'statusCode')?val(response.statusCode):0;
        if(status==401 OR status==403) unavailable('A Awin recusou o acesso. Confira o token e as permissões da conta.');
        if(status==429) unavailable('A Awin pediu uma pausa nas consultas. Aguarde alguns minutos.');
        if(status!=200 OR !structKeyExists(response,'fileContent') OR !isJSON(response.fileContent)) unavailable();
        return deserializeJSON(response.fileContent);
    }
    private struct function readSnapshot() {
        if(!fileExists(variables.snapshotFile)) return {programmes=[],promotions=[],updatedAt='',publisherId='',actorId=0};
        try {
            var snapshot=deserializeJSON(fileRead(variables.snapshotFile,'utf-8'));
            if(!isStruct(snapshot) OR !structKeyExists(snapshot,'programmes') OR !isArray(snapshot.programmes) OR !structKeyExists(snapshot,'promotions') OR !isArray(snapshot.promotions) OR !structKeyExists(snapshot,'publisherId') OR !structKeyExists(snapshot,'updatedAt')) unavailable();
            return snapshot;
        } catch(any e){unavailable('O histórico local da Awin precisa ser atualizado.');}
    }
    public struct function dashboard(required struct context) {
        variables.guard.authorize(context);return currentData();
    }
    private struct function currentData() {
        var settings=config();var snapshot=readSnapshot();
        if(len(snapshot.publisherId) AND compare(snapshot.publisherId & '',settings.publisherId & '')!=0) unavailable('O histórico pertence a outra conta. Atualize a conexão.');
        var joined={};var programmes=[];
        for(var programme in snapshot.programmes) {
            if(!isStruct(programme) OR !reFind('^[1-9][0-9]{0,12}$',text(programme,'id')) OR compareNoCase(text(programme,'status'),'Active')!=0) continue;
            var item={id=text(programme,'id'),name=text(programme,'name'),url=safeUrl(text(programme,'displayUrl')),logoUrl=programmeLogo(text(programme,'logoUrl'),text(programme,'id')),linkStatus=text(programme,'linkStatus')};
            joined[item.id]=item;arrayAppend(programmes,item);
        }
        var promotions=[];var active=0;var upcoming=0;
        for(var raw in snapshot.promotions) {
            if(!isStruct(raw)) unavailable();
            var promotion=normalizePromotion(raw,joined);
            if(structIsEmpty(promotion) OR promotion.state=='expired') continue;
            arrayAppend(promotions,promotion);if(promotion.state=='active')active++;else upcoming++;
        }
        var stale=len(snapshot.updatedAt) AND createObject('java','java.lang.System').currentTimeMillis()-epoch(snapshot.updatedAt)>3600000;
        return {publisherId=settings.publisherId,updatedAt=snapshot.updatedAt,updatedLabel=localTime(snapshot.updatedAt),stale=stale,programmes=programmes,promotions=promotions,active=active,upcoming=upcoming};
    }
    public void function refresh(required struct context) {
        variables.guard.authorize(context,true);refreshData(context.actorId);
    }
    public struct function refreshScheduled() {refreshData(0);return currentData();}
    private void function refreshData(required numeric actorId) {
        var settings=config();
        lock name='business-comparador-awin-' & hash(variables.snapshotFile) type='exclusive' timeout=5 {
            var old=readSnapshot();
            if(len(old.updatedAt) AND createObject('java','java.lang.System').currentTimeMillis()-epoch(old.updatedAt)<60000) return;
            var programmes=requestApi(settings,'/publishers/' & settings.publisherId & '/programmes?relationship=joined');
            if(!isArray(programmes)) unavailable();
            var joined={};for(var programme in programmes) if(isStruct(programme) AND compareNoCase(text(programme,'status'),'Active')==0) joined[text(programme,'id')]={name=text(programme,'name'),logoUrl=programmeLogo(text(programme,'logoUrl'),text(programme,'id'))};
            // Preserve Awin's case-sensitive JSON keys without changing application serialization.
            var requestBody=deserializeJSON('{"filters":{"membership":"joined","regionCodes":["BR"],"status":"active","type":"all"},"pagination":{"page":1,"pageSize":200}}');
            var promotions=[];var seen={};
            for(var state in ['active','upcoming']) {
                var complete=false;
                for(var page=1;page<=20;page++) {
                    requestBody.filters.status=state;requestBody.pagination.page=page;
                    var data=requestApi(settings,'/publisher/' & settings.publisherId & '/promotions','POST',requestBody);
                    if(!isStruct(data) OR !structKeyExists(data,'data') OR !isArray(data.data) OR !structKeyExists(data,'pagination') OR !isStruct(data.pagination) OR !structKeyExists(data.pagination,'total') OR !isNumeric(data.pagination.total)) unavailable();
                    for(var raw in data.data) {
                        if(!isStruct(raw)) unavailable();
                        var promotion=normalizePromotion(raw,joined);
                        if(!structIsEmpty(promotion) AND !structKeyExists(seen,promotion.id)) {arrayAppend(promotions,raw);seen[promotion.id]=true;}
                    }
                    if(page*200>=data.pagination.total) {complete=true;break;}
                    if(arrayLen(data.data)==0) unavailable();
                }
                if(!complete) unavailable('A consulta excedeu o limite de páginas. O histórico anterior foi preservado.');
            }
            var snapshot={publisherId=settings.publisherId,updatedAt=createObject('java','java.time.Instant').now().toString(),actorId=actorId,programmes=programmes,promotions=promotions};
            var temporary=variables.snapshotFile & '.' & createUUID();
            try {
                fileWrite(temporary,serializeJSON(snapshot),'utf-8');fileSetAccessMode(temporary,'600');
                // Same filesystem: readers see the previous complete snapshot or the new one.
                if(!createObject('java','java.io.File').init(temporary).renameTo(createObject('java','java.io.File').init(variables.snapshotFile))) unavailable();
            } finally {if(fileExists(temporary)) fileDelete(temporary);}
        }
    }
    public string function generateLink(required struct context,required string advertiserId,required string destination) {
        variables.guard.authorize(context,true);var settings=config();var data=dashboard(context);var found=false;
        for(var programme in data.programmes) if(compare(programme.id,advertiserId)==0)found=true;
        if(!found OR !len(safeUrl(destination))) throw(type='Comparador.Validation',message='Escolha um programa aprovado e informe um endereço HTTPS válido.');
        var requestBody=deserializeJSON('{"advertiserId":0,"destinationUrl":"","parameters":{"clickref":"comparador"},"shorten":false}');
        requestBody.advertiserId=val(advertiserId);requestBody.destinationUrl=destination;
        var response=requestApi(settings,'/publishers/' & settings.publisherId & '/linkbuilder/generate','POST',requestBody);
        if(!isStruct(response) OR !len(safeUrl(text(response,'url'),true))) unavailable('O programa não retornou um link de afiliado válido para esse endereço.');
        return safeUrl(text(response,'url'),true);
    }
}
