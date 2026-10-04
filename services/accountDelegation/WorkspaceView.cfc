component output=false {
    public string function label(required string code){
        var labels={"AGENCIA"="Agência","TICKETEIRA"="Ticketeira","OUTROS"="Outros","ATIVO"= "Ativo", "ATIVA"= "Ativa", "AGUARDANDO_CONTA"= "Aguardando aprovação da conta", "PENDENTE_GESTORA"= "Aguardando gestora", "PENDENTE_CLIENTE"= "Aguardando cliente", "SUSPENSO"= "Suspenso", "REVOGADO"= "Revogado", "RECUSADO"= "Recusado", "PENDENTE"= "Pendente", "ACEITO"= "Aceito", "CANCELADO"= "Cancelado", "EXPIRADO"= "Expirado", "SUCCESS"= "Concluído", "DENIED"= "Não autorizado", "CONFLICT"= "Dados alterados", "ERROR"= "Falha", "INATIVO"= "Inativo", "CONVIDADO"= "Convidado", "BLOQUEADO"= "Bloqueado", "OWNER"= "Titular", "ADMIN"= "Administrador", "OPERADOR"= "Operador", "VISUALIZADOR"= "Leitor", "MEDICO"= "Médico", "TITULAR"= "Titularidade", "RELACAO"= "Gestão da conta", "AMPLIACAO"= "Ampliação de permissões", "ads.campaigns.view"= "Consultar campanhas", "ads.campaigns.manage"= "Gerenciar campanhas", "ads.payments.view"= "Consultar pagamentos", "ads.credits.purchase"= "Comprar créditos", "events.view"= "Consultar eventos", "events.manage"= "Gerenciar eventos", "events.links.request"= "Solicitar vínculo de evento", "relationship.invite"= "Convite de gestão emitido", "relationship.request"= "Gestão solicitada", "relationship.request.receipt"= "Solicitação recebida", "relationship.approve"= "Gestão aprovada", "relationship.decline"= "Gestão recusada", "relationship.revoke"= "Gestão revogada", "relationship.renounce"= "Renúncia à gestão", "relationship.suspend"= "Gestão suspensa", "relationship.reactivate"= "Gestão reativada", "relationship.reduce"= "Permissões reduzidas", "relationship.expand"= "Ampliação solicitada", "relationship.cancel"= "Solicitação cancelada", "team.assign"= "Integrante atribuído", "team.remove"= "Atribuição removida", "client.create"= "Cliente criado", "client.update"= "Cadastro corrigido", "client.approve"= "Cliente aprovado", "client.decline"= "Cliente recusado", "owner.invite"= "Convite de titularidade emitido", "owner.accept"= "Titularidade confirmada", "owner.reject"= "Titularidade recusada", "manager.configure"= "Configuração da gestora alterada"};
        return structKeyExists(labels,code)?labels[code]:'Alteração registrada';
    }
    public string function tabUrl(required numeric managerId,required string tab,struct filters={}){
        if(!listFind('clientes,equipe,convites,historico',tab))throw(type='BusinessDelegation.Validation',message='Invalid tab');
        var search=structKeyExists(filters,'search')?filters.search:'';
        var state=structKeyExists(filters,'state')?filters.state:'';
        var page=structKeyExists(filters,'page')?filters.page:1;
        if(!isSimpleValue(search) || len(search)>160 || !isSimpleValue(state) || !isSimpleValue(page))throw(type='BusinessDelegation.Validation',message='Invalid filters');
        return '/gestao-clientes/?gestora=' & urlEncodedFormat(managerId & '') & '&tab=' & urlEncodedFormat(tab) & '&busca=' & urlEncodedFormat(search) & '&estado=' & urlEncodedFormat(state) & '&pagina=' & urlEncodedFormat(page & '');
    }
    public array function capabilities(required struct posted){
        var map={cap_ads_campaigns_view='ads.campaigns.view',cap_ads_campaigns_manage='ads.campaigns.manage',cap_ads_payments_view='ads.payments.view',cap_ads_credits_purchase='ads.credits.purchase',cap_events_view='events.view',cap_events_manage='events.manage',cap_events_links_request='events.links.request'};
        var output=[];
        for(var key in posted){
            if(left(lCase(key),4)=='cap_' && !structKeyExists(map,lCase(key)))throw(type='BusinessDelegation.Validation',message='Unknown capability');
        }
        for(var key in map){
            if(structKeyExists(posted,key)){
                if(!isSimpleValue(posted[key]) || posted[key] & ''!='1')throw(type='BusinessDelegation.Validation',message='Invalid capability field');
                arrayAppend(output,map[key]);
            }
        }
        return output;
    }
}
