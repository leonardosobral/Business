<cfscript>
function paidBannerSave(required struct posted, required struct context, required struct images) {
    paidBannerAssertAction(context.method,paidBannerText(posted,'paid_banner_csrf'),context.csrf,context.canManage,context.canReview,context.accountId>0,'save');
    var id=paidBannerText(posted,'campaign_id');
    var intent=paidBannerText(posted,'save_intent','submit');
    if (len(id) AND !paidBannerUuid(id)) throw(type='AdsV1.Validation',message='Banner inválido.');
    if (!listFind('submit,draft',intent)) throw(type='AdsV1.Validation',message='Escolha enviar para análise ou salvar como rascunho.');
    var values=paidBannerValues(posted);
    if(len(id)) {
        var expected=paidBannerText(posted,'expected_version');
        if(!reFind('^[1-9][0-9]{0,8}$',expected)) throw(type='AdsV1.Validation',message='Reabra o formulário para carregar a versão atual do banner.');
        values['expected_version']=val(expected);
    }
    var k='';
    for(k in ['image_url_desktop','image_url_mobile','width_desktop','height_desktop','width_mobile','height_mobile']) {
        if(!structKeyExists(images,k)) throw(type='AdsV1.Validation',message='Envie as imagens desktop e mobile.');
        values[k]=images[k];
    }
    var result=queryExecute('SELECT * FROM ads.save_paid_banner_campaign(CAST(:campaign AS uuid),CAST(:account AS bigint),CAST(:actor AS integer),CAST(:values AS jsonb),CAST(:submit AS boolean))',{
        campaign={value=id,cfsqltype='cf_sql_varchar',null=!len(id)},
        account={value=context.accountId,cfsqltype='cf_sql_bigint'},
        actor={value=context.actorId,cfsqltype='cf_sql_integer'},
        values={value=serializeJSON(values),cfsqltype='cf_sql_longvarchar'},
        submit={value=intent=='submit',cfsqltype='cf_sql_bit'}
    },{datasource='runnerhub'});
    if(result.recordCount!=1) throw(type='AdsV1.Validation',message='O salvamento não foi confirmado. Atualize a lista antes de tentar novamente.');
    return paidBannerRow(result,1);
}
function paidBannerManage(required struct posted, required struct context) {
    var action=paidBannerText(posted,'paid_banner_action');
    paidBannerAssertAction(context.method,paidBannerText(posted,'paid_banner_csrf'),context.csrf,context.canManage,context.canReview,context.accountId>0,action);
    var id=paidBannerText(posted,'campaign_id');
    if(!paidBannerUuid(id)) throw(type='AdsV1.Validation',message='Banner inválido.');
    // Caller capabilities come from authenticated account context; ownership is
    // checked again here and inside each canonical mutation function.
    var owned=queryExecute("SELECT c.campaign_id FROM ads.campaigns c WHERE c.campaign_id=CAST(:campaign AS uuid) AND c.billing_model='CPC' AND (:global OR c.account_id=:account) AND EXISTS(SELECT 1 FROM ads.advertisements a WHERE a.campaign_id=c.campaign_id AND a.account_id=c.account_id AND a.ad_type='BANNER' AND a.billing_model='CPC')",{
        campaign={value=id,cfsqltype='cf_sql_varchar'},account={value=context.accountId,cfsqltype='cf_sql_bigint'},
        global={value=action=='review' AND context.canReview AND context.accountId==0,cfsqltype='cf_sql_bit'}
    },{datasource='runnerhub'});
    if(owned.recordCount!=1) throw(type='AdsV1.Validation',message='Banner não encontrado nesta conta.');
    var params={campaign={value=id,cfsqltype='cf_sql_varchar'},account={value=context.accountId,cfsqltype='cf_sql_bigint'},actor={value=context.actorId,cfsqltype='cf_sql_integer'}};
    var command='';
    switch(action) {
        case 'submit': command='SELECT * FROM ads.submit_paid_banner_review(CAST(:campaign AS uuid),CAST(:account AS bigint),CAST(:actor AS integer))';break;
        case 'prepare': command='SELECT * FROM ads.prepare_campaign_for_edit(CAST(:campaign AS uuid),CAST(:account AS bigint),CAST(:actor AS integer))';break;
        case 'pause': case 'end':
            command='SELECT ads.change_campaign_status(CAST(:campaign AS uuid),:status,CAST(:actor AS integer),:reason)';
            params.status={value=action=='pause' ? 'PAUSED' : 'ENDED',cfsqltype='cf_sql_varchar'};
            params.reason={value=action=='pause' ? 'Pausado pelo anunciante' : 'Encerrado pelo anunciante',cfsqltype='cf_sql_varchar'};break;
        case 'resume':
            command="SELECT ads.activate_campaign(CAST(:campaign AS uuid),CAST(:actor AS integer),'Retomada pelo anunciante')";break;
        case 'review':
            var decision=paidBannerText(posted,'decision');var reviewId=paidBannerText(posted,'review_id');var reason=paidBannerText(posted,'reason');
            if(!listFind('APPROVE,REQUEST_CHANGES',decision) OR !reFind('^[1-9][0-9]*$',reviewId) OR len(reason)>1000 OR (decision!='APPROVE' AND !len(reason))) throw(type='AdsV1.Validation',message='Informe a decisão, a revisão atual e o motivo dos ajustes.');
            params.decision={value=decision,cfsqltype='cf_sql_varchar'};params.review={value=reviewId,cfsqltype='cf_sql_bigint'};
            params.reason={value=reason,cfsqltype='cf_sql_varchar'};
            params.idempotency={value='banner-review-' & reviewId & '-' & decision,cfsqltype='cf_sql_varchar'};
            command='SELECT * FROM ads.review_paid_banner_campaign(CAST(:campaign AS uuid),:decision,CAST(:actor AS integer),:reason,:idempotency,CAST(:review AS bigint))';break;
        default: throw(type='AdsV1.Validation',message='Ação inválida.');
    }
    try {
        return queryExecute(command,params,{datasource='runnerhub'});
    } catch(database mutationError) {
        var safeDatabaseText=mutationError.message & ' ' & (structKeyExists(mutationError,'detail') ? mutationError.detail : '');
        if(action=='review' AND reFindNoCase('Revis(a|ã)o vigente diverge da exibida',safeDatabaseText)) {
            throw(type='AdsV1.Validation',message='Esta revisão ficou obsoleta porque existe uma versão mais recente do banner. Recarregue a página e revise a versão atual.');
        }
        rethrow;
    }
}
</cfscript>
