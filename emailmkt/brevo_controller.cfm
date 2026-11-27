<cfif getBaseTemplatePath() EQ getCurrentTemplatePath()><cfheader statuscode="404"><cfabort></cfif>
<cflock scope="session" type="exclusive" timeout="3"><cfif NOT structKeyExists(SESSION,"brevoBatchCsrf")><cfset SESSION.brevoBatchCsrf=lCase(hash(createUUID() & createUUID(),"SHA-256"))/></cfif></cflock>
<cfscript>
brevoService = new services.BrevoMarketingService().init();
brevoClient = new services.CrmClient().init(APPLICATION.notificationDispatch);
brevoConfig = brevoService.readiness();
brevoNotice = {};
brevoState = {available=false,status='unavailable'};
brevoLabels = {
    draft='Rascunho', prepared='Pronto para revisão', reviewed='Pronto para revisão', confirmed='Confirmado para envio',
    syncing='Sincronizando a lista', validating='Verificando destinatários', dispatching='Encaminhando à Brevo',
    accepted='Aceito pela Brevo', unknown='Requer conferência na Brevo', cancelled='Cancelado',
    excluded='Sem destinatários elegíveis', expired='Janela de envio encerrada', unavailable='Consulta indisponível', migration_pending='Aguardando as migrações do CRM'
};
if(CGI.request_method=='POST'){
    if(compareNoCase(listFirst(CGI.http_host,':'),'business.roadrunners.run')!=0 || !structKeyExists(FORM,'brevoCsrf') || !isSimpleValue(FORM.brevoCsrf) || compare(FORM.brevoCsrf,SESSION.brevoBatchCsrf)!=0){
        cfheader(statuscode=403);cfcontent(type='text/plain; charset=utf-8',reset=true);writeOutput('Operação não autorizada.');abort;
    }
    operation=structKeyExists(FORM,'brevoAction') && isSimpleValue(FORM.brevoAction) ? FORM.brevoAction : '';
    try{
        if(!listFind('prepare,confirm,cancel,check,webhook',operation)) throw(message='invalid_action');
        if(operation=='webhook'){
            brevoService.registerWebhook();
            brevoNotice={ok=true,text='Webhook de marketing registrado na Brevo.'};
        } else if(operation=='check'){
            remoteSetup=brevoService.verifySetup();
            brevoNotice={ok=remoteSetup.ready,text=remoteSetup.ready?'Remetente, pasta e webhook verificados na Brevo.':'Configuração incompleta na Brevo. Confira o remetente, a pasta e o webhook de marketing.'};
        } else {
            if(operation=='confirm'){
                if(!brevoConfig.configured) throw(message='provider_setup');
                setup=brevoService.verifySetup();
                if(!setup.ready) throw(message='provider_setup');
                if(!setup.webhookTokenCompared) brevoService.registerWebhook();
            }
            actionResponse=brevoClient.request('brevo.' & operation,{},val(qPerfil.id));
            if(!actionResponse.success) throw(message=actionResponse.error);
            if(operation=='confirm') brevoNotice={ok=true,text=actionResponse.data.status=='confirmed'?'Lote confirmado para a janela de envio.':'O lote ficou sem destinatários elegíveis.'};
            if(operation=='cancel') brevoNotice={ok=true,text='Lote cancelado.'};
            if(operation=='prepare') brevoNotice={ok=true,text=val(actionResponse.data.selected)>0?'Destinatários preparados para revisão.':'Nenhum atleta elegível agora. Você pode consultar novamente antes do fim da oferta.'};
        }
    } catch(any problem){
        messages={brevo_webhook_conflict='Já existe um webhook para este endereço com configuração diferente. Confira a configuração na Brevo.',brevo_auth_failed='A Brevo recusou a chave ou o IP deste servidor.',preview_expired='A janela da oferta terminou.',empty_audience='Nenhum atleta elegível para este lote.',source_unavailable='Aplique as migrações do CRM antes de preparar o público.',revision_conflict='O estado do lote mudou. Confira os dados atuais.',provider_setup='Conclua a configuração do remetente, pasta e webhook antes de confirmar.',forbidden='Ação não autorizada.'};
        brevoNotice={ok=false,text=structKeyExists(messages,problem.message)?messages[problem.message]:'A ação não foi concluída. Confira as configurações e o estado do lote.'};
    }
    SESSION.brevoBatchNotice=brevoNotice;
    location(url='/emailmkt/',addtoken=false,statuscode=303);
}
if(structKeyExists(SESSION,'brevoBatchNotice')){
    brevoNotice=SESSION.brevoBatchNotice;structDelete(SESSION,'brevoBatchNotice');
}
try{
    batchResponse=brevoClient.request('brevo.status',{},val(qPerfil.id));
    if(batchResponse.success) brevoState=batchResponse.data;
    else brevoState.status='status_error';
}catch(any failedStatus){brevoState.status='status_error';}
brevoLabels.status_error='Consulta temporariamente indisponível';
brevoPageRequested=structKeyExists(URL,'pagina_publico');
brevoMembersPage={};
if(brevoPageRequested && structKeyExists(brevoState,'priority_audience')){
    brevoPage=isSimpleValue(URL.pagina_publico) && reFind('^[1-9][0-9]{0,8}$',URL.pagina_publico) ? int(URL.pagina_publico) : 1;
    try {
        membersResponse=brevoClient.request('brevo.members',{page=brevoPage},val(qPerfil.id));
        if(membersResponse.success) brevoMembersPage=membersResponse.data;
    } catch(any unavailableMembers){brevoMembersPage={};}
}
</cfscript>
