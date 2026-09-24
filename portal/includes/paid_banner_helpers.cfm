<cfscript>
function paidBannerWorkspaceView(required struct queryParams,required struct posted,required boolean canReview) {
    var view=paidBannerText(queryParams,'view',paidBannerText(posted,'view','paid'));
    var legacy=structKeyExists(queryParams,'banner_novo') OR structKeyExists(queryParams,'banner_editar') OR structKeyExists(posted,'acao');
    if(view=='house' OR legacy) {
        if(!canReview) throw(type='AdsV1.Validation',message='Banners institucionais são exclusivos da administração RunnerHub.');
        return 'house';
    }
    return 'paid';
}
function paidBannerUuid(required any value) {
    return isSimpleValue(value) AND reFindNoCase('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',trim(value & ''))==1;
}
function paidBannerText(required struct values, required string key, string fallback='') {
    if (!structKeyExists(values,key)) return fallback;
    if (!isSimpleValue(values[key])) throw(type='AdsV1.Validation',message='Valor inválido no formulário.');
    return trim(values[key] & '');
}
function paidBannerMoney(required string value) {
    var raw=trim(value);
    if (find(',',raw)) {
        if (!reFind('^(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+),[0-9]{1,2}$',raw)) throw(type='AdsV1.Validation',message='Informe um valor monetário válido, com até duas casas decimais.');
        raw=replace(replace(raw,'.','','all'),',','.');
    }
    if (!reFind('^[0-9]+(?:\.[0-9]{1,2})?$',raw) OR len(raw)>15) throw(type='AdsV1.Validation',message='Informe um valor monetário válido, sem números negativos.');
    return val(raw);
}
function paidBannerDate(required string value) {
    if (!reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}$',value)) throw(type='AdsV1.Validation',message='Informe uma data e hora válidas.');
    try {
        return createObject('java','java.time.LocalDateTime').parse(value)
            .atZone(createObject('java','java.time.ZoneId').of('America/Sao_Paulo')).toOffsetDateTime().toString();
    } catch(any invalidDate) {throw(type='AdsV1.Validation',message='Informe uma data e hora válidas.');}
}
function paidBannerAssertAction(required string method, required string postedToken, required string sessionToken, required boolean canManage, required boolean canReview, required boolean hasAccount, required string action) {
    if (method!='POST' OR !len(sessionToken) OR compare(postedToken,sessionToken)!=0) throw(type='AdsV1.Validation',message='A sessão do formulário expirou. Recarregue a página.');
    if (!listFind('save,submit,prepare,pause,end,resume,review',action)) throw(type='AdsV1.Validation',message='Ação de banner inválida.');
    if (action=='review') {
        if (!canReview) throw(type='AdsV1.Validation',message='Somente a equipe RunnerHub pode revisar banners.');
    } else if (!canManage OR !hasAccount) throw(type='AdsV1.Validation',message='Você não pode gerenciar banners nesta conta.');
}
function paidBannerValues(required struct posted) {
    var destination=bannerDestination(paidBannerText(posted,'destination_url'));
    var v={
        'name'=paidBannerText(posted,'name'),
        'alt_text'=paidBannerText(posted,'alt_text'),
        'destination_url'=destination.url,
        'open_new_tab'=paidBannerText(posted,'open_new_tab','1')=='1',
        'starts_at'=paidBannerDate(paidBannerText(posted,'starts_at')),
        'ends_at'=paidBannerDate(paidBannerText(posted,'ends_at')),
        'cpc_bid'=paidBannerMoney(paidBannerText(posted,'cpc_bid')),
        'budget_total'=paidBannerMoney(paidBannerText(posted,'budget_total')),
        'target_device'=paidBannerText(posted,'target_device','ALL'),
        'placement_key'='rr-sidebar-banner-300x250',
        'banner_scope_v1'=bannerScopeFromForm(posted)
    };
    if (len(v.name)<3 OR len(v.name)>160 OR len(v.alt_text)<3 OR len(v.alt_text)>300) throw(type='AdsV1.Validation',message='Nome: 3 a 160 caracteres. Descrição da imagem: 3 a 300 caracteres.');
    if (!listFind('ALL,DESKTOP,MOBILE',v.target_device)) throw(type='AdsV1.Validation',message='Selecione um dispositivo válido.');
    if (!listFind('0,1',paidBannerText(posted,'open_new_tab','1'))) throw(type='AdsV1.Validation',message='Selecione como abrir o destino.');
    if (compare(paidBannerText(posted,'ends_at'),paidBannerText(posted,'starts_at'))<=0) throw(type='AdsV1.Validation',message='O fim precisa ser posterior ao início.');
    if (v.cpc_bid<=0 OR v.budget_total<v.cpc_bid) throw(type='AdsV1.Validation',message='Informe um lance positivo e orçamento que comporte pelo menos um clique.');
    if (len(paidBannerText(posted,'budget_daily'))) {
        v['budget_daily']=paidBannerMoney(paidBannerText(posted,'budget_daily'));
        if (v.budget_daily<v.cpc_bid OR v.budget_daily>v.budget_total) throw(type='AdsV1.Validation',message='O limite diário deve ficar entre o lance e o orçamento total.');
    }
    // Images and ownership are deliberately not accepted from posted fields.
    return v;
}
function paidBannerForm(required struct posted, struct saved={}) {
    var v={name='',alt_text='',destination_url='',open_new_tab='1',starts_at=dateTimeFormat(now(),"yyyy-mm-dd'T'HH:nn"),ends_at=dateTimeFormat(dateAdd('d',30,now()),"yyyy-mm-dd'T'HH:nn"),cpc_bid='0,94',budget_total='100,00',budget_daily='',target_device='ALL',banner_regions_mode='ALL',banner_regions='',banner_pages_mode='ALL',banner_pages=''};
    var k='';var scope={};
    for(k in v) if(structKeyExists(saved,k) AND !isNull(saved[k])) v[k]=saved[k] & '';
    for(k in ['starts_at','ends_at']) if(structKeyExists(saved,k) AND isDate(saved[k])) v[k]=dateTimeFormat(saved[k],"yyyy-mm-dd'T'HH:nn");
    if(structKeyExists(saved,'metadata')) {
        scope=bannerScopeFromMetadata(saved.metadata);
        for(k in ['regions','pages']) {v['banner_' & k & '_mode']=scope[k & '_mode'];v['banner_' & k]=arrayToList(scope[k]);}
    }
    if(structKeyExists(posted,'paid_banner_action') AND posted.paid_banner_action=='save') {
        for(k in v) if(structKeyExists(posted,k) AND isSimpleValue(posted[k])) v[k]=posted[k] & '';
        for(k in ['regions','pages']) if(!structKeyExists(posted,'banner_' & k)) v['banner_' & k]='';
    }
    return v;
}
function paidBannerStatus(required string status, string review='NONE') {
    if(status=='DRAFT') {
        if(review=='PENDING_REVIEW') return 'Em análise';
        if(review=='WAITING_PREREQUISITES') return 'Aguardando conta';
        if(review=='CHANGES_REQUESTED') return 'Ajustes solicitados';
        return 'Rascunho';
    }
    var labels={ACTIVE='Ativo',PAUSED='Pausado',ENDED='Encerrado',ARCHIVED='Arquivado'};
    return structKeyExists(labels,status) ? labels[status] : status;
}
function paidBannerRow(required query records, required numeric index) {
    var row={};var col='';
    for(col in listToArray(records.columnList)) row[lCase(col)]=isNull(records[col][index]) ? '' : records[col][index];
    return row;
}
</cfscript>
