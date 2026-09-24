<cfscript>
function bannerScopeNormalize(required struct scope) {
    var result = {};
    var kind = '';
    var item = '';
    var allowed = {regions='AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO',pages='home,search,state,event,athlete'};
    for (kind in ['regions','pages']) {
        if (!structKeyExists(scope,kind & '_mode') OR !isSimpleValue(scope[kind & '_mode']) OR !listFind('ALL,SELECTED',scope[kind & '_mode']) OR !structKeyExists(scope,kind) OR !isArray(scope[kind])) throw(type='AdsV1.Validation',message='Selecione um escopo válido de páginas e estados.');
        result[kind & '_mode']=scope[kind & '_mode']; result[kind]=[];
        for (item in scope[kind]) {
            if (!isSimpleValue(item)) throw(type='AdsV1.Validation',message='Seleção de escopo inválida.');
            item=kind=='regions' ? uCase(trim(item & '')) : lCase(trim(item & ''));
            if (!listFind(allowed[kind],item)) throw(type='AdsV1.Validation',message='Página ou estado inválido na seleção.');
            if (!arrayFind(result[kind],item)) arrayAppend(result[kind],item);
        }
        if (result[kind & '_mode']=='SELECTED' AND !arrayLen(result[kind])) throw(type='AdsV1.Validation',message=kind=='regions' ? 'Selecione pelo menos um estado.' : 'Selecione pelo menos uma página.');
        if (result[kind & '_mode']=='ALL') result[kind]=[];
    }
    return result;
}
function bannerScopeFromMetadata(required string metadata) {
    var data=deserializeJSON(arguments.metadata);
    var scopeKey='';
    var dimension='';
    if (!isStruct(data)) throw(type='AdsV1.Validation',message='Escopo persistido inválido.');
    // JSON null may disappear during CF deserialization; presence must be checked too.
    if (!structKeyExists(data,'banner_scope_v1') AND !reFindNoCase('"banner_scope_v1"\s*:',arguments.metadata)) return bannerScopeNormalize({regions_mode='ALL',regions=[],pages_mode='ALL',pages=[]});
    if (!structKeyExists(data,'banner_scope_v1') OR !isStruct(data.banner_scope_v1)) throw(type='AdsV1.Validation',message='Escopo persistido inválido. Revise páginas e estados antes de salvar.');
    // Persisted scope must match the SQL shape. Only browser POST may discard
    // stale selections when an administrator explicitly switches a mode to ALL.
    if (structCount(data.banner_scope_v1)!=4) throw(type='AdsV1.Validation',message='Escopo persistido inválido. Revise páginas e estados antes de salvar.');
    for(scopeKey in data.banner_scope_v1) if(!listFind('regions_mode,regions,pages_mode,pages',scopeKey)) throw(type='AdsV1.Validation',message='Escopo persistido inválido. Revise páginas e estados antes de salvar.');
    for(dimension in ['regions','pages']) {
        if(structKeyExists(data.banner_scope_v1,dimension & '_mode') AND data.banner_scope_v1[dimension & '_mode']=='ALL' AND structKeyExists(data.banner_scope_v1,dimension) AND isArray(data.banner_scope_v1[dimension]) AND arrayLen(data.banner_scope_v1[dimension])) throw(type='AdsV1.Validation',message='Escopo persistido inválido. Revise páginas e estados antes de salvar.');
    }
    return bannerScopeNormalize(data.banner_scope_v1);
}
function bannerScopeFromForm(required struct posted) {
    var data={}; var kind='';
    for (kind in ['regions','pages']) {
        data[kind & '_mode']=structKeyExists(posted,'banner_' & kind & '_mode') ? posted['banner_' & kind & '_mode'] : '';
        data[kind]=structKeyExists(posted,'banner_' & kind) ? listToArray(posted['banner_' & kind] & '') : [];
    }
    return bannerScopeNormalize(data);
}
function bannerDestination(required string value) {
    var destination=trim(value); var uri=0; var host='';
    if (reFind('[\x00-\x20\\]',destination) OR left(destination,2)=='//') throw(type='AdsV1.Validation',message='Informe um destino HTTPS válido ou caminho interno.');
    if (left(destination,1)=='/') destination='https://roadrunners.run' & destination;
    try { uri=createObject('java','java.net.URI').init(destination); host=lCase(uri.getHost() & ''); }
    catch(any e) { throw(type='AdsV1.Validation',message='Informe um destino HTTPS válido.'); }
    if (compareNoCase(uri.getScheme() & '','https') OR !len(host) OR len(uri.getRawUserInfo() & '') OR (uri.getPort()!=-1 AND uri.getPort()!=443)) throw(type='AdsV1.Validation',message='Informe um destino HTTPS válido, sem credenciais.');
    return {url=destination,external=!listFindNoCase('roadrunners.run,www.roadrunners.run,beta.roadrunners.run,dev.roadrunners.run',host)};
}
function bannerFormValues(required struct posted, struct saved={}) {
    var v={banner_id='',banner_nome='',banner_alt_text='',banner_link_destino='',banner_abrir_nova_aba='auto',banner_peso_exibicao='1',banner_prioridade='1',banner_inicio_exibicao=dateFormat(now(),'yyyy-mm-dd') & 'T' & timeFormat(now(),'HH:nn'),banner_fim_exibicao='',banner_regions_mode='ALL',banner_regions='',banner_pages_mode='ALL',banner_pages='',desktop_path='',mobile_path='',scope_error=''};
    var map={banner_id='id_banner',banner_nome='nome',banner_alt_text='alt_text',banner_link_destino='link_destino',banner_peso_exibicao='peso_exibicao',banner_prioridade='prioridade'}; var k=''; var s={};
    for(k in map) if(structKeyExists(saved,map[k])) v[k]=saved[map[k]] & '';
    for(k in ['inicio_exibicao','fim_exibicao']) if(structKeyExists(saved,k) AND isDate(saved[k])) v['banner_' & k]=dateFormat(saved[k],'yyyy-mm-dd') & 'T' & timeFormat(saved[k],'HH:nn');
    if(structKeyExists(saved,'abrir_nova_aba')) v.banner_abrir_nova_aba=listFindNoCase('1,true,yes,on',saved.abrir_nova_aba & '') ? '1' : '0';
    if(structKeyExists(saved,'arquivo_path')) v.desktop_path=saved.arquivo_path;
    if(structKeyExists(saved,'arquivo_mobile_path')) v.mobile_path=saved.arquivo_mobile_path;
    if(structKeyExists(saved,'banner_metadata')) {
        try { s=bannerScopeFromMetadata(saved.banner_metadata); for(k in ['regions','pages']) {v['banner_' & k & '_mode']=s[k & '_mode'];v['banner_' & k]=arrayToList(s[k]);} }
        catch(any e) {v.banner_regions_mode='SELECTED';v.banner_pages_mode='SELECTED';v.scope_error=e.message;}
    }
    if(structKeyExists(posted,'acao') AND posted.acao=='salvar_banner') {
        for(k in v) if(left(k,7)=='banner_' AND structKeyExists(posted,k) AND isSimpleValue(posted[k])) v[k]=posted[k] & '';
        for(k in ['regions','pages']) if(!structKeyExists(posted,'banner_' & k)) v['banner_' & k]='';
    }
    return v;
}
function bannerImageMetadata(required string path) {
    var f=createObject('java','java.io.File').init(path); var stream=0; var reader=0; var readers=0; var result={};
    var metadata=0; var descriptor=0; var frameIndex=0; var frameCount=1; var frameWidth=0; var frameHeight=0;
    if(!f.isFile() OR f.length()<=0 OR f.length()>10485760) throw(type='AdsV1.Validation',message='A imagem deve ter até 10 MiB.');
    try {
        stream=createObject('java','javax.imageio.ImageIO').createImageInputStream(f);
        readers=createObject('java','javax.imageio.ImageIO').getImageReaders(stream);
        if(!readers.hasNext()) throw(type='AdsV1.Validation',message='Arquivo inválido. Envie JPG, PNG ou GIF.');
        reader=readers.next(); reader.setInput(stream);
        result={extension=lCase(reader.getFormatName()),width=reader.getWidth(0),height=reader.getHeight(0)};
        if(result.extension=='jpeg') result.extension='jpg';
        if(result.extension=='gif') {
            // A GIF frame may occupy only a small rectangle of its displayed canvas.
            metadata=reader.getStreamMetadata();
            descriptor=metadata.getAsTree(metadata.getNativeMetadataFormatName()).getElementsByTagName('LogicalScreenDescriptor').item(0);
            result.width=val(descriptor.getAttribute('logicalScreenWidth'));
            result.height=val(descriptor.getAttribute('logicalScreenHeight'));
        }
        if(!listFind('jpg,png,gif',result.extension) OR result.width<=0 OR result.height<=0 OR result.width*result.height>40000000) throw(type='AdsV1.Validation',message='A imagem deve ser JPG, PNG ou GIF e ter até 40 megapixels.');
        if(result.extension=='gif') {
            // Scan descriptors without allocating decoded frames. Later animation
            // frames must respect both the canvas and the pixel allocation limit.
            frameCount=reader.getNumImages(true);
            for(frameIndex=0;frameIndex<frameCount;frameIndex++) {
                frameWidth=reader.getWidth(frameIndex); frameHeight=reader.getHeight(frameIndex);
                if(frameWidth<=0 OR frameHeight<=0 OR frameWidth*frameHeight>40000000) throw(type='AdsV1.Validation',message='Cada quadro GIF deve ter até 40 megapixels.');
                metadata=reader.getImageMetadata(frameIndex);
                descriptor=metadata.getAsTree(metadata.getNativeMetadataFormatName()).getElementsByTagName('ImageDescriptor').item(0);
                if(val(descriptor.getAttribute('imageLeftPosition'))+frameWidth>result.width OR val(descriptor.getAttribute('imageTopPosition'))+frameHeight>result.height) throw(type='AdsV1.Validation',message='Quadro GIF fora das dimensões da imagem.');
            }
        }
        // Decode only after the header's dimensions pass the allocation cap. Original bytes are kept.
        reader.read(0);
        return result;
    } catch(AdsV1.Validation e) { rethrow; }
    catch(any e) { throw(type='AdsV1.Validation',message='Não foi possível decodificar a imagem. Envie JPG, PNG ou GIF válido.'); }
    finally { if(isObject(reader)) reader.dispose(); if(isObject(stream)) stream.close(); }
}
</cfscript>
