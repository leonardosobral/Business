<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfset VARIABLES.theme="dark"/>
<cfset VARIABLES.template="/ads/gorunners/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/access.cfm"/>
<cfif NOT adsAccessCanViewZones>
    <cfheader statuscode="403"/><cfcontent reset="true"/><p>Selecione uma conta com acesso à publicidade.</p><cfabort/>
</cfif>
<cfscript>
api=new ads.gorunners.CommerceClient();
sales=new ads.gorunners.ZoneSales(api);
pilot=adsAccessHasAccount && api.allows(adsAccessAccountId);
canBuy=adsAccessCanPurchaseCredit && !(businessAccountSimulationActive ?: false)
    && !structKeyExists(session,"businessSupportSession");
tokenName="gorunners-zone-" & adsAccessAccountId & "-" & adsAccessActorId;
csrf=csrfGenerateToken(tokenName);
view=listFind("nova,pedidos",url.view ?: "") ? url.view : "pedidos";
ref=trim(url.ref ?: "");
row={}; stats={}; rows=queryNew("reference"); fault="";
function esc(any value="") {return encodeForHTML(arguments.value & "");}
function money(required numeric cents) {return "R$ " & lsNumberFormat(arguments.cents/100,"_,__0.00","pt_BR");}
function gameLabel(required struct sale) {
    switch(sale.game_status ?: "") {
        case "held": return "Área reservada";
        case "draft": case "pending_payment": return "Aguardando confirmação";
        case "active": return len(sale.activated_at ?: "") ? "No ar" : "Pagamento confirmado pelo jogo";
        case "expired": return "Encerrada";
        case "cancelled": return "Cancelada";
        case "refunded": return "Estornada";
        default: return "Cotação";
    }
}
function paymentLabel(required struct sale) {
    if ((sale.checkout_state ?: "")=="review") return "Conferência necessária";
    if (len(sale.received_at ?: "")) return "Recebido";
    switch(sale.checkout_state ?: "") {
        case "creating": return "Em processamento";
        case "ready": return "Aguardando pagamento";
        default: return "Sem cobrança";
    }
}
if (CGI.request_method=="POST") {
    if (!pilot || !canBuy || !csrfVerifyToken(form.zone_csrf ?: "",tokenName)) {
        cfheader(statuscode=403); writeOutput("Operação não autorizada nesta conta."); abort;
    }
    ref=trim(form.zone_ref ?: "");
    try {
        varAction=form.zone_action ?: "";
        if (varAction=="quote") {
            ref=sales.quote(adsAccessAccountId,adsAccessActorId,form);
        } else {
            row=sales.sale(adsAccessAccountId,ref);
            switch(varAction) {
                case "reserve": sales.reserve(row); break;
                case "order": sales.order(row,form); break;
                case "checkout": sales.checkout(row); break;
                case "sync": sales.reconcile(row); break;
                default: throw(type="Zones.Input",message="Ação desconhecida.");
            }
        }
        location(url="/ads/gorunners/?ref=" & encodeForURL(ref),addtoken=false,statuscode=303);
    } catch (Zones.Input e) {fault=e.message;}
      catch (Zones.Missing e) {cfheader(statuscode=404); fault=e.message; ref="";}
      catch (any e) {fault="O serviço não confirmou a operação. Consulte o pedido antes de tentar novamente."; cflog(file="gorunners_zones",text="Falha na operação de venda (#e.type#)");}
}
if (pilot) {
    try {
        if (len(ref)) {
            row=sales.sale(adsAccessAccountId,ref);
            if ((url.report ?: "")=="1" && val(row.order_id ?: 0)) stats=sales.report(row);
        } else if (view=="pedidos") rows=sales.recent(adsAccessAccountId);
    } catch (Zones.Missing e) {cfheader(statuscode=404); fault=e.message; row={};}
      catch (any e) {fault="Não foi possível carregar os dados da venda."; cflog(file="gorunners_zones",text="Falha na consulta de venda (#e.type#)");}
}
</cfscript>
<!doctype html><html lang="pt-BR">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm"/>
<main class="container pb-5" style="margin-top:-55px">
    <a href="/ads/" class="text-muted">Publicidade</a>
    <h1 class="h3 mt-2">Zonas patrocinadas GoRunners</h1>
    <cfif len(fault)><cfoutput><div class="alert alert-warning" role="alert">#esc(fault)#</div></cfoutput></cfif>
    <p class="my-3"><a href="/ads/gorunners/demo.cfm" class="btn btn-outline-warning">Testar mapa e compra em demonstração</a></p>
    <cfif NOT adsAccessHasAccount>
        <section class="card p-4 mt-4">
            <cfif api.enabled()>
                <h2 class="h5">Homologação em andamento</h2>
                <p class="mb-0">Use <strong>Trocar conta</strong> no topo da página para consultar as zonas de uma conta participante.</p>
            <cfelse>
                <h2 class="h5">Vendas em preparação</h2>
                <p class="mb-0">A venda de zonas patrocinadas no mapa do GoRunners aguarda a homologação com o jogo.</p>
            </cfif>
        </section>
    <cfelseif NOT pilot>
        <div class="card p-4 mt-4"><h2 class="h5">Vendas em preparação</h2><p class="mb-0">A seleção de áreas e a compra serão liberadas para esta conta após a homologação com o GoRunners.</p></div>
    <cfelse>
        <p class="text-muted">Homologação · Os pagamentos usam o ambiente de testes.</p>
        <nav aria-label="Vendas GoRunners" class="d-flex flex-wrap gap-2 mb-4"><a class="btn btn-sm btn-outline-light" href="/ads/gorunners/">Pedidos</a><cfif canBuy><a class="btn btn-sm btn-outline-warning" href="?view=nova">Nova zona</a></cfif></nav>
        <cfinclude template="workspace.cfm"/>
    </cfif>
</main>
<cfinclude template="../../includes/estrutura/footer.cfm"/>
</body></html>
