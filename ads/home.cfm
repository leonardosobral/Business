<cfparam name="URL.view" default="overview"/>
<cfparam name="URL.mode" default=""/>
<cfparam name="URL.status" default=""/>
<cfparam name="URL.history" default="campaigns"/>

<cfscript>
function adsV1PlacementLabel(required any placementKey) {
    switch (lCase(trim(arguments.placementKey & ""))) {
        case "rr-home-upcoming-native": return "Página inicial";
        case "rr-home-upcoming-native-secondary": return "Página inicial";
        case "rr-search-events-native": return "Busca de eventos";
        case "rr-state-events-native": return "Eventos por estado";
        case "rr-sidebar-event-native": return "Página do evento";
        default: return "Outros locais";
    }
}

function adsV1PlacementDescription(required any placementKey) {
    switch (lCase(trim(arguments.placementKey & ""))) {
        case "rr-home-upcoming-native": return "Concorra aos destaques entre os próximos eventos; região e lance definem a ordem.";
        case "rr-home-upcoming-native-secondary": return "Concorra aos destaques entre os próximos eventos; região e lance definem a ordem.";
        case "rr-search-events-native": return "Resultado patrocinado na busca de provas.";
        case "rr-state-events-native": return "Lista de eventos filtrada por estado.";
        case "rr-sidebar-event-native": return "Área lateral da página de uma prova.";
        default: return "Área adicional de divulgação.";
    }
}

function adsV1PlacementSummary(required any placementKeys) {
    var labels = [];
    var placementKey = "";
    for (placementKey in listToArray(arguments.placementKeys & "")) {
        if (len(trim(placementKey)) AND !arrayFindNoCase(labels, adsV1PlacementLabel(placementKey))) {
            arrayAppend(labels, adsV1PlacementLabel(placementKey));
        }
    }
    if (!arrayLen(labels)) return "Nenhum local selecionado";
    if (arrayLen(labels) LTE 2) return arrayToList(labels, " e ");
    return labels[1] & ", " & labels[2] & " e mais " & (arrayLen(labels) - 2) & " locais";
}

function adsV1PlacementCountSummary(required any placementKeys) {
    var labels = [];
    var placementKey = "";
    var count = 0;
    for (placementKey in listToArray(arguments.placementKeys & "")) {
        if (len(trim(placementKey)) AND !arrayFindNoCase(labels, adsV1PlacementLabel(placementKey))) {
            arrayAppend(labels, adsV1PlacementLabel(placementKey));
        }
    }
    count = arrayLen(labels);
    if (count EQ 1) return "1 local de exibição";
    return count & " locais de exibição";
}

function adsV1EventImageUrl(any rawValue = "") {
    var imageValue = trim(arguments.rawValue & "");
    if (!len(imageValue)) return "";
    if (reFindNoCase("^https?://", imageValue)) return imageValue;
    return "https://roadrunners.run/" & reReplace(imageValue, "^/+", "", "one");
}

function adsV1CampaignStatusLabel(required any status) {
    switch (uCase(trim(arguments.status & ""))) {
        case "ACTIVE": return "Ativa";
        case "PAUSED": return "Pausada";
        case "DRAFT": return "Rascunho";
        case "ENDED": return "Finalizada";
        default: return trim(arguments.status & "");
    }
}

function adsV1LedgerLabel(required any entryType, required any sourceType) {
    var entry = uCase(trim(arguments.entryType & ""));
    var source = uCase(trim(arguments.sourceType & ""));
    if (entry EQ "CREDIT" AND source EQ "PAYMENT") return "Crédito por pagamento";
    if (entry EQ "CREDIT" AND source EQ "VOUCHER") return "Crédito por voucher";
    if (entry EQ "CREDIT" AND source EQ "MANUAL") return "Crédito manual";
    if (entry EQ "DEBIT" AND source EQ "CLICK") return "Clique cobrado";
    if (entry EQ "REVERSAL") return "Estorno";
    return entry & (len(source) ? " - " & source : "");
}

function adsV1PaymentStatusLabel(required any status) {
    switch (uCase(trim(arguments.status & ""))) {
        case "PAID": return "Pago";
        case "CREATED": return "Criado";
        case "CHECKOUT_READY": return "Aguardando pagamento";
        case "PENDING": return "Em confirmação";
        case "FAILED": return "Falhou";
        case "CANCELED": return "Cancelado";
        case "EXPIRED": return "Expirado";
        case "REFUNDED": return "Estornado";
        case "CHARGEBACK": return "Contestado";
        case "REVIEW": return "Em análise";
        default: return trim(arguments.status & "");
    }
}

VARIABLES.adsV1WorkspaceView = lCase(trim(URL.view & ""));
if (!listFindNoCase("overview,campaigns,campaign-detail,payments,history,admin,vouchers", VARIABLES.adsV1WorkspaceView)) {
    VARIABLES.adsV1WorkspaceView = "overview";
}
if (adsV1IsUuid(URL.payment)) VARIABLES.adsV1WorkspaceView = "payments";
if ((adsV1IsUuid(URL.campaign) AND VARIABLES.adsV1WorkspaceView NEQ "campaign-detail")
    OR lCase(trim(URL.mode & "")) EQ "new") VARIABLES.adsV1WorkspaceView = "campaigns";
if (listFindNoCase(VARIABLES.adsV1CampaignActions, FORM.ads_v1_action) AND len(VARIABLES.adsV1Error)) VARIABLES.adsV1WorkspaceView = "campaigns";
if (listFindNoCase(VARIABLES.adsV1FinanceActions, FORM.ads_v1_action) AND len(VARIABLES.adsV1Error)) VARIABLES.adsV1WorkspaceView = "admin";
if (listFindNoCase(VARIABLES.adsV1ReviewActions, FORM.ads_v1_action) AND len(VARIABLES.adsV1Error)) VARIABLES.adsV1WorkspaceView = "admin";
if (listFindNoCase(VARIABLES.adsV1VoucherAdminActions, FORM.ads_v1_action) AND len(VARIABLES.adsV1Error)) VARIABLES.adsV1WorkspaceView = "vouchers";
if (VARIABLES.adsV1WorkspaceView EQ "payments" AND !VARIABLES.adsAccessCanViewPayments) VARIABLES.adsV1WorkspaceView = "overview";
if (VARIABLES.adsV1WorkspaceView EQ "vouchers" AND !VARIABLES.adsAccessCanAdminVouchers) VARIABLES.adsV1WorkspaceView = "overview";
if (VARIABLES.adsV1WorkspaceView EQ "admin" AND !VARIABLES.adsAccessCanAdminFinance AND !VARIABLES.adsAccessCanReviewCampaign) VARIABLES.adsV1WorkspaceView = "overview";
if (!VARIABLES.adsV1HasAccount
    AND VARIABLES.adsAccessCanReviewCampaign
    AND !listFindNoCase("admin,vouchers", VARIABLES.adsV1WorkspaceView)) {
    VARIABLES.adsV1WorkspaceView = "admin";
}

VARIABLES.adsV1CampaignFilter = lCase(trim(URL.status & ""));
if (!listFindNoCase("ongoing,draft,ended", VARIABLES.adsV1CampaignFilter)) VARIABLES.adsV1CampaignFilter = "";
VARIABLES.adsV1HistoryTab = lCase(trim(URL.history & ""));
if (!listFindNoCase("campaigns,legacy", VARIABLES.adsV1HistoryTab)) VARIABLES.adsV1HistoryTab = "campaigns";
VARIABLES.adsV1ShowCampaignForm = VARIABLES.adsAccessCanManageCampaign
    AND (lCase(trim(URL.mode & "")) EQ "new" OR qAdsV1SelectedCampaign.recordcount
        OR (FORM.ads_v1_action EQ "save_campaign" AND len(VARIABLES.adsV1Error)));
VARIABLES.adsV1IsCampaignDetailFocus = VARIABLES.adsV1WorkspaceView EQ "campaign-detail";
</cfscript>

<cfset VARIABLES.adsV1FormCampaignId = ""/>
<cfset VARIABLES.adsV1FormEventId = 0/>
<cfset VARIABLES.adsV1FormName = ""/>
<cfset VARIABLES.adsV1FormCpcRaw = "0.94"/>
<cfset VARIABLES.adsV1FormBudgetTotalRaw = "100.00"/>
<cfset VARIABLES.adsV1FormBudgetDailyRaw = ""/>
<cfset VARIABLES.adsV1FormStartsDisplay = dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn")/>
<cfset VARIABLES.adsV1FormEndsDisplay = dateTimeFormat(dateAdd("d", 30, now()), "yyyy-mm-dd'T'HH:nn")/>
<cfset VARIABLES.adsV1FormDevice = "ALL"/>
<cfset VARIABLES.adsV1FormCountry = "BR"/>
<cfset VARIABLES.adsV1FormRegion = ""/>
<cfset VARIABLES.adsV1FormPlacementKeys = ["rr-home-upcoming-native"]/>
<cfset VARIABLES.adsV1CampaignEditable = true/>

<cfif VARIABLES.adsAccessCanManageCampaign AND FORM.ads_v1_action EQ "save_campaign" AND len(VARIABLES.adsV1Error)>
    <cfset VARIABLES.adsV1FormCampaignId = structKeyExists(FORM, "campaign_id") ? trim(FORM.campaign_id & "") : ""/>
    <cfset VARIABLES.adsV1FormEventId = structKeyExists(FORM, "core_event_id") AND isNumeric(FORM.core_event_id) ? val(FORM.core_event_id) : 0/>
    <cfset VARIABLES.adsV1FormName = structKeyExists(FORM, "name") ? trim(FORM.name & "") : ""/>
    <cfset VARIABLES.adsV1FormCpcRaw = structKeyExists(FORM, "cpc_bid") ? trim(FORM.cpc_bid & "") : ""/>
    <cfset VARIABLES.adsV1FormBudgetTotalRaw = structKeyExists(FORM, "budget_total") ? trim(FORM.budget_total & "") : ""/>
    <cfset VARIABLES.adsV1FormBudgetDailyRaw = structKeyExists(FORM, "budget_daily") ? trim(FORM.budget_daily & "") : ""/>
    <cfset VARIABLES.adsV1FormStartsDisplay = structKeyExists(FORM, "starts_at") ? trim(FORM.starts_at & "") : ""/>
    <cfset VARIABLES.adsV1FormEndsDisplay = structKeyExists(FORM, "ends_at") ? trim(FORM.ends_at & "") : ""/>
    <cfset VARIABLES.adsV1FormDevice = structKeyExists(FORM, "target_device_class") ? uCase(trim(FORM.target_device_class & "")) : "ALL"/>
    <cfset VARIABLES.adsV1FormCountry = structKeyExists(FORM, "target_country_code") ? uCase(trim(FORM.target_country_code & "")) : "BR"/>
    <cfset VARIABLES.adsV1FormRegion = structKeyExists(FORM, "target_region_code") ? uCase(trim(FORM.target_region_code & "")) : ""/>
    <cfset VARIABLES.adsV1FormPlacementKeys = structKeyExists(FORM, "placement_keys") ? adsV1FormList(FORM.placement_keys) : []/>
<cfelseif qAdsV1SelectedCampaign.recordcount>
    <cfset VARIABLES.adsV1FormCampaignId = qAdsV1SelectedCampaign.campaign_id & ""/>
    <cfset VARIABLES.adsV1FormEventId = val(qAdsV1SelectedCampaign.core_event_id)/>
    <cfset VARIABLES.adsV1FormName = qAdsV1SelectedCampaign.name & ""/>
    <cfset VARIABLES.adsV1FormCpcRaw = numberFormat(qAdsV1SelectedCampaign.cpc_bid, "0.00")/>
    <cfset VARIABLES.adsV1FormBudgetTotalRaw = numberFormat(qAdsV1SelectedCampaign.budget_total, "0.00")/>
    <cfset VARIABLES.adsV1FormBudgetDailyRaw = len(trim(qAdsV1SelectedCampaign.budget_daily & "")) ? numberFormat(qAdsV1SelectedCampaign.budget_daily, "0.00") : ""/>
    <cfset VARIABLES.adsV1FormStartsDisplay = isDate(qAdsV1SelectedCampaign.starts_at) ? dateTimeFormat(qAdsV1SelectedCampaign.starts_at, "yyyy-mm-dd'T'HH:nn") : ""/>
    <cfset VARIABLES.adsV1FormEndsDisplay = isDate(qAdsV1SelectedCampaign.ends_at) ? dateTimeFormat(qAdsV1SelectedCampaign.ends_at, "yyyy-mm-dd'T'HH:nn") : ""/>
    <cfset VARIABLES.adsV1FormDevice = qAdsV1SelectedCampaign.target_device_class & ""/>
    <cfset VARIABLES.adsV1FormCountry = trim(qAdsV1SelectedCampaign.target_country_code & "")/>
    <cfset VARIABLES.adsV1FormRegion = trim(qAdsV1SelectedCampaign.target_region_code & "")/>
    <cfset VARIABLES.adsV1FormPlacementKeys = len(trim(qAdsV1SelectedCampaign.placement_keys & "")) ? listToArray(qAdsV1SelectedCampaign.placement_keys & "") : []/>
    <cfset VARIABLES.adsV1CampaignEditable = listFind("DRAFT,PAUSED", qAdsV1SelectedCampaign.status) GT 0
        AND NOT listFind("PENDING_REVIEW,APPROVED", uCase(trim(qAdsV1SelectedCampaign.review_status & "")))/>
</cfif>

<cfif arrayFindNoCase(VARIABLES.adsV1FormPlacementKeys, "rr-home-upcoming-native-secondary")
    AND NOT arrayFindNoCase(VARIABLES.adsV1FormPlacementKeys, "rr-home-upcoming-native")>
    <cfset arrayAppend(VARIABLES.adsV1FormPlacementKeys, "rr-home-upcoming-native")/>
</cfif>

<cfset VARIABLES.adsV1DraftCount = 0/>
<cfset VARIABLES.adsV1EndedCount = 0/>
<cfset VARIABLES.adsV1OngoingCount = 0/>
<cfloop query="qAdsV1Campaigns">
    <cfif qAdsV1Campaigns.status EQ "DRAFT"><cfset VARIABLES.adsV1DraftCount++/></cfif>
    <cfif qAdsV1Campaigns.status EQ "ENDED"><cfset VARIABLES.adsV1EndedCount++/></cfif>
    <cfif listFind("ACTIVE,PAUSED", qAdsV1Campaigns.status)><cfset VARIABLES.adsV1OngoingCount++/></cfif>
</cfloop>
<cfif NOT len(VARIABLES.adsV1CampaignFilter)>
    <cfset VARIABLES.adsV1CampaignFilter = VARIABLES.adsV1OngoingCount EQ 0
        AND VARIABLES.adsV1DraftCount GT 0 ? "draft" : "ongoing"/>
</cfif>
<cfset VARIABLES.adsV1IsFirstCampaign = VARIABLES.adsV1WorkspaceView EQ "campaigns"
    AND VARIABLES.adsV1ShowCampaignForm
    AND qAdsV1Campaigns.recordcount EQ 0
    AND NOT len(VARIABLES.adsV1FormCampaignId)/>
<cfset VARIABLES.adsV1IsCampaignCreationFocus = VARIABLES.adsV1WorkspaceView EQ "campaigns"
    AND VARIABLES.adsV1ShowCampaignForm
    AND NOT len(VARIABLES.adsV1FormCampaignId)/>

<cfset VARIABLES.adsV1LatestPaidPayment = {}/>
<cfif isDefined("qAdsPayments") AND qAdsPayments.recordcount>
    <cfloop query="qAdsPayments"><cfif qAdsPayments.status EQ "PAID"><cfset VARIABLES.adsV1LatestPaidPayment = {amountCents=val(qAdsPayments.amount_cents),method=lCase(qAdsPayments.payment_method & ""),paidAt=qAdsPayments.paid_at,reference=qAdsPayments.support_reference & ""}/><cfbreak/></cfif></cfloop>
</cfif>

<style>
  .ads-v1-eyebrow { color: #62c7d8; font-size: .75rem; font-weight: 800; letter-spacing: .06em; text-transform: uppercase; }
  .ads-v1-summary-value { font-size: 1.45rem; font-weight: 750; line-height: 1.15; }
  .ads-workspace-nav { border-bottom: 1px solid rgba(255,255,255,.1); display: flex; gap: 1.5rem; margin-bottom: 1.5rem; overflow-x: auto; }
  .ads-workspace-nav a { border-bottom: 3px solid transparent; color: var(--mdb-secondary-color); flex: 0 0 auto; font-weight: 700; padding: .85rem .15rem; text-decoration: none; }
  .ads-workspace-nav a.active { border-color: #62c7d8; color: #78d3e1; }
  .ads-health-strip { background: rgba(255,255,255,.04); border: 1px solid rgba(255,255,255,.08); border-radius: .55rem; }
  .ads-health-item { min-height: 118px; padding: 1.25rem; }
  .ads-health-item + .ads-health-item { border-left: 1px solid rgba(255,255,255,.09); }
  .ads-campaign-table { font-size: .84rem; min-width: 720px; }
  .ads-campaign-table--overview { min-width: 760px; table-layout: fixed; }
  .ads-campaign-table--overview th:nth-child(1) { width: 31%; }
  .ads-campaign-table--overview th:nth-child(2) { width: 22%; }
  .ads-campaign-table--overview th:nth-child(3) { width: 21%; }
  .ads-campaign-table--overview th:nth-child(4) { width: 26%; }
  .ads-campaign-table--management { min-width: 920px; table-layout: fixed; }
  .ads-campaign-table--management th:nth-child(1) { width: 30%; }
  .ads-campaign-table--management th:nth-child(2) { width: 21%; }
  .ads-campaign-table--management th:nth-child(3) { width: 18%; }
  .ads-campaign-table--management th:nth-child(4) { width: 19%; }
  .ads-campaign-table--management th:nth-child(5) { width: 12%; }
  .ads-campaign-table--management th, .ads-campaign-table--management td { padding: .9rem .75rem; }
  .ads-campaign-table th, .ads-campaign-table td { vertical-align: middle; }
  .ads-campaign-mark { align-items: center; background: rgba(98,199,216,.12); border: 1px solid rgba(98,199,216,.2); border-radius: .45rem; color: #62c7d8; display: flex; flex: 0 0 42px; height: 42px; justify-content: center; }
  .ads-campaign-title, .ads-campaign-event { display: -webkit-box; line-height: 1.3; overflow: hidden; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
  .ads-campaign-performance-link { color: #78d3e1; display: inline-block; font-size: .76rem; font-weight: 750; margin-top: .45rem; text-decoration: none; }
  .ads-campaign-performance-link:hover { color: #9be2ed; text-decoration: underline; }
  .ads-campaign-result-grid { display: grid; gap: .7rem 1rem; grid-template-columns: repeat(2, minmax(0, 1fr)); min-width: 210px; }
  .ads-campaign-result-grid small { color: var(--mdb-secondary-color); display: block; font-size: .68rem; margin-bottom: .12rem; text-transform: uppercase; }
  .ads-campaign-result-grid strong { display: block; font-size: .9rem; white-space: nowrap; }
  .ads-campaign-result-grid--management { min-width: 0; }
  .ads-campaign-actions { align-items: flex-end; display: flex; flex-direction: column; gap: .4rem; white-space: nowrap; }
  .ads-budget-progress { background: rgba(255,255,255,.1); border-radius: 999px; height: 6px; overflow: hidden; width: 130px; }
  .ads-budget-progress span { background: #62c7d8; display: block; height: 100%; }
  .ads-activity-row { align-items: center; border-top: 1px solid rgba(255,255,255,.08); display: flex; gap: .85rem; justify-content: space-between; padding: .85rem 0; }
  .ads-activity-row:first-child { border-top: 0; }
  .ads-status-tabs { display: flex; flex-wrap: wrap; gap: .5rem; }
  .ads-status-tabs a { border: 1px solid rgba(255,255,255,.14); border-radius: .35rem; color: var(--mdb-secondary-color); font-weight: 650; padding: .55rem .85rem; text-decoration: none; }
  .ads-status-tabs a.active { border-color: #62c7d8; color: #78d3e1; }
  .ads-row-actions { display: inline-block; position: relative; }
  .ads-row-actions summary { list-style: none; }
  .ads-row-actions summary::-webkit-details-marker { display: none; }
  .ads-row-actions-panel { background: #303030; border: 1px solid rgba(255,255,255,.12); border-radius: .4rem; display: flex; flex-direction: column; gap: .45rem; margin-top: .35rem; min-width: 230px; padding: .75rem; }
  .ads-performance-card { border: 1px solid rgba(98,199,216,.22); }
  .ads-performance-controls { align-items: flex-end; display: flex; flex-wrap: wrap; gap: .75rem; justify-content: flex-end; }
  .ads-performance-campaign-filter { min-width: min(320px, 100%); }
  .ads-performance-campaign-filter label { color: var(--mdb-secondary-color); display: block; font-size: .72rem; font-weight: 750; margin-bottom: .3rem; text-transform: uppercase; }
  .ads-performance-selection { color: #78d3e1; font-size: .8rem; }
  .ads-performance-kpis { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); }
  .ads-performance-kpi { border-left: 1px solid rgba(255,255,255,.09); min-width: 0; padding: .25rem 1.15rem; }
  .ads-performance-kpi:first-child { border-left: 0; padding-left: 0; }
  .ads-performance-kpi > span, .ads-performance-kpi > small { color: var(--mdb-secondary-color); display: block; }
  .ads-performance-kpi > span { font-size: .75rem; font-weight: 750; margin-bottom: .35rem; text-transform: uppercase; }
  .ads-performance-kpi > strong { display: block; font-size: 1.45rem; line-height: 1.2; margin-bottom: .3rem; }
  .ads-performance-kpi > small { line-height: 1.35; }
  .ads-performance-trends { align-items: center; background: rgba(255,255,255,.035); border-radius: .45rem; display: flex; flex-wrap: wrap; font-size: .82rem; gap: .65rem 1.25rem; padding: .75rem 1rem; }
  .ads-performance-trends > span { color: var(--mdb-secondary-color); }
  .ads-performance-chart-wrap { height: 330px; position: relative; }
  .ads-performance-empty { background: rgba(255,255,255,.025); border: 1px dashed rgba(255,255,255,.15); border-radius: .5rem; padding: 3rem 1.5rem; }
  .ads-performance-empty i { color: #62c7d8; font-size: 2rem; }
  @media (max-width: 1199.98px) { .ads-performance-kpis { grid-template-columns: repeat(3, minmax(0, 1fr)); row-gap: 1.25rem; } .ads-performance-kpi:nth-child(4) { border-left: 0; padding-left: 0; } }
  @media (max-width: 991.98px) { .ads-health-item + .ads-health-item { border-left: 0; border-top: 1px solid rgba(255,255,255,.09); } }
  @media (max-width: 575.98px) { .ads-performance-kpis { grid-template-columns: 1fr 1fr; } .ads-performance-kpi { border-left: 0; padding: .25rem .75rem .25rem 0; } .ads-performance-chart-wrap { height: 270px; } }
</style>

<cfif NOT VARIABLES.adsV1IsCampaignCreationFocus AND NOT VARIABLES.adsV1IsCampaignDetailFocus>
  <section class="mb-4"><div class="d-flex flex-column flex-lg-row justify-content-between align-items-lg-end gap-3"><div><div class="ads-v1-eyebrow">Marketing</div><h1 class="h3 mb-0">Publicidade</h1><p class="text-muted mb-0 mt-2">Acompanhe suas campanhas e avance com as próximas ações.</p></div><cfif VARIABLES.adsAccessCanManageCampaign AND VARIABLES.adsV1HasAccount AND VARIABLES.adsV1ApiReady><a class="btn btn-info" href="./?view=campaigns&amp;mode=new#campaign-form">Criar campanha</a></cfif></div></section>
</cfif>

<cfif len(VARIABLES.adsV1Notice)>
  <div class="alert alert-success d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-2">
    <span><cfoutput>#htmlEditFormat(VARIABLES.adsV1Notice)#</cfoutput></span>
    <cfif VARIABLES.adsAccessIsPendingNewAccount>
      <a class="btn btn-sm btn-outline-success flex-shrink-0" href="/">Voltar aos primeiros passos</a>
    </cfif>
  </div>
</cfif>
<cfif len(VARIABLES.adsV1Error)><div class="alert alert-danger"><cfoutput>#htmlEditFormat(VARIABLES.adsV1Error)#</cfoutput></div></cfif>
<cfif VARIABLES.adsAccessIsPendingNewAccount AND NOT VARIABLES.adsV1IsCampaignCreationFocus><div class="alert alert-info"><strong>Você pode preparar tudo agora.</strong> O voucher só vira saldo após a aprovação da conta, e a campanha só poderá entrar no ar após a aprovação da conta, do evento e da equipe RunnerHub.</div></cfif>

<cfif listFindNoCase("admin,vouchers", VARIABLES.adsV1WorkspaceView)
  AND (
    (VARIABLES.adsV1WorkspaceView EQ "admin" AND VARIABLES.adsAccessCanReviewCampaign)
    OR (VARIABLES.adsV1WorkspaceView EQ "vouchers" AND VARIABLES.adsAccessCanAdminVouchers)
  )
  AND NOT VARIABLES.adsV1HasAccount>
  <nav class="ads-workspace-nav" aria-label="Áreas de publicidade"><cfif VARIABLES.adsAccessCanAdminVouchers><a class="<cfif VARIABLES.adsV1WorkspaceView EQ 'vouchers'>active</cfif>" href="./?view=vouchers">Vouchers</a></cfif><cfif VARIABLES.adsAccessCanReviewCampaign><a class="<cfif VARIABLES.adsV1WorkspaceView EQ 'admin'>active</cfif>" href="./?view=admin">Revisão de anúncios</a></cfif></nav>
  <cfif VARIABLES.adsV1WorkspaceView EQ "vouchers"><cfinclude template="includes/workspace_admin_vouchers.cfm"/><cfelse><cfinclude template="includes/workspace_admin.cfm"/></cfif>
<cfelseif NOT VARIABLES.adsV1HasAccount>
  <section class="card shadow-0 mb-4"><div class="card-body p-4"><div class="ads-v1-eyebrow mb-2">Conta obrigatoria</div><h2 class="h5">Selecione uma conta no topo</h2><p class="text-muted mb-0">Escolha a conta que deseja anunciar para acessar campanhas, saldo e desempenho.</p></div></section>
<cfelseif NOT VARIABLES.adsAccessCanView>
  <section class="card shadow-0 mb-4"><div class="card-body p-4"><div class="ads-v1-eyebrow mb-2">Acesso restrito</div><h2 class="h5">Seu papel não permite acessar Publicidade</h2><p class="text-muted mb-0">Solicite ao responsável pela conta um vínculo ativo com acesso de visualização.</p></div></section>
<cfelseif NOT VARIABLES.adsV1ApiReady>
  <section class="card shadow-0 mb-4"><div class="card-body p-4"><div class="ads-v1-eyebrow mb-2">Indisponivel</div><h2 class="h5">Publicidade temporariamente indisponivel</h2><p class="text-muted mb-3">Nao foi possivel carregar os recursos de publicidade desta conta.</p><a class="btn btn-outline-warning" href="/ads/">Tentar novamente</a></div></section>
<cfelseif NOT VARIABLES.adsV1DataReady>
  <section class="card shadow-0 mb-4"><div class="card-body p-4"><div class="ads-v1-eyebrow mb-2">Leitura indisponível</div><h2 class="h5">Não foi possível carregar a conta</h2><p class="text-muted mb-0">Recarregue a página. Nenhuma alteração foi realizada.</p></div></section>
<cfelse>
  <cfif NOT VARIABLES.adsV1IsCampaignCreationFocus AND NOT VARIABLES.adsV1IsCampaignDetailFocus>
  <section class="ads-health-strip mb-4">
    <div class="row g-0 row-cols-1 row-cols-lg-4">
      <div class="col ads-health-item">
        <cfif VARIABLES.adsAccessIsPendingNewAccount
          AND qAdsV1VoucherReservation.recordcount
          AND uCase(trim(qAdsV1VoucherReservation.status & "")) EQ "RESERVED">
          <div class="text-muted small mb-2">Saldo previsto</div>
          <div class="ads-v1-summary-value"><cfoutput>#lsCurrencyFormat(qAdsV1VoucherReservation.credito)#</cfoutput></div>
          <span class="badge badge-warning mt-2">Voucher reservado</span>
          <div class="small text-muted mt-2">Disponível após a aprovação da conta.</div>
          <div class="small text-muted mt-1">Saldo utilizável agora: <cfoutput>#lsCurrencyFormat(VARIABLES.adsV1Summary.balance)#</cfoutput></div>
          <a class="btn btn-sm btn-outline-warning mt-3" href="./?view=payments#ads-voucher-form">Ver voucher reservado</a>
        <cfelse>
          <div class="text-muted small mb-2">Saldo disponível</div>
          <div class="ads-v1-summary-value"><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1Summary.balance)#</cfoutput></div>
          <cfif VARIABLES.adsAccessCanPurchaseCredit><a class="btn btn-sm btn-outline-info mt-3" href="./?view=payments#payment-credit">Adicionar saldo</a></cfif>
        </cfif>
      </div>
      <div class="col ads-health-item"><div class="text-muted small mb-2">Gasto total</div><div class="ads-v1-summary-value"><cfoutput>#lsCurrencyFormat(VARIABLES.adsV1Summary.spent)#</cfoutput></div><div class="small text-muted mt-2">Investimento em campanhas</div></div>
      <div class="col ads-health-item"><div class="text-muted small mb-2">Campanhas ativas</div><div class="ads-v1-summary-value"><cfoutput>#VARIABLES.adsV1Summary.active#</cfoutput></div><div class="small text-muted mt-2"><cfoutput>#VARIABLES.adsV1Summary.paused# pausadas</cfoutput></div></div>
      <div class="col ads-health-item"><div class="text-muted small mb-2">Desempenho</div><div class="ads-v1-summary-value"><cfoutput>#lsNumberFormat(VARIABLES.adsV1Summary.clicks, "9,999,999")# cliques</cfoutput></div><div class="small text-muted mt-2"><cfoutput>#lsNumberFormat(VARIABLES.adsV1Summary.views, "9,999,999")# visualizações</cfoutput></div></div>
    </div>
  </section>

  <nav class="ads-workspace-nav" aria-label="Áreas de publicidade"><a class="<cfif VARIABLES.adsV1WorkspaceView EQ 'overview'>active</cfif>" href="./?view=overview">Visão geral</a><a class="<cfif VARIABLES.adsV1WorkspaceView EQ 'campaigns'>active</cfif>" href="./?view=campaigns">Campanhas</a><cfif VARIABLES.adsAccessCanViewPayments><a class="<cfif VARIABLES.adsV1WorkspaceView EQ 'payments'>active</cfif>" href="./?view=payments">Saldo e pagamentos</a></cfif><a class="<cfif VARIABLES.adsV1WorkspaceView EQ 'history'>active</cfif>" href="./?view=history">Histórico</a><cfif VARIABLES.adsAccessCanAdminVouchers><a class="<cfif VARIABLES.adsV1WorkspaceView EQ 'vouchers'>active</cfif>" href="./?view=vouchers">Vouchers</a></cfif><cfif VARIABLES.adsAccessCanAdminFinance OR VARIABLES.adsAccessCanReviewCampaign><a class="<cfif VARIABLES.adsV1WorkspaceView EQ 'admin'>active</cfif>" href="./?view=admin"><cfif VARIABLES.adsAccessCanReviewCampaign>Revisão de anúncios<cfelse>Administração</cfif></a></cfif></nav>

  <cfif VARIABLES.adsV1Summary.active GT 0 AND VARIABLES.adsV1Summary.balance LTE 0><div class="alert alert-warning d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-2"><div><strong>Campanha ativa sem saldo.</strong> Adicione crédito para retomar a exibição.</div><cfif VARIABLES.adsAccessCanPurchaseCredit><a class="btn btn-sm btn-outline-warning" href="./?view=payments#payment-credit">Adicionar saldo</a></cfif></div></cfif>
  </cfif>

  <cfif VARIABLES.adsV1WorkspaceView EQ "overview" AND NOT VARIABLES.adsV1IsCampaignCreationFocus>
    <cfset VARIABLES.adsV1PerformanceContext = "account"/>
    <cfinclude template="includes/workspace_performance.cfm"/>
  </cfif>
  <cfif VARIABLES.adsV1WorkspaceView EQ "campaign-detail"><cfinclude template="includes/workspace_campaign_detail.cfm"/></cfif>
  <cfif listFindNoCase("overview,campaigns", VARIABLES.adsV1WorkspaceView) AND NOT VARIABLES.adsV1IsCampaignCreationFocus><cfinclude template="includes/workspace_campaigns.cfm"/></cfif>
  <cfif VARIABLES.adsV1WorkspaceView EQ "campaigns" AND VARIABLES.adsV1ShowCampaignForm><cfinclude template="includes/workspace_campaign_form.cfm"/></cfif>
  <cfif VARIABLES.adsV1WorkspaceView EQ "payments"><cfinclude template="includes/payments_home.cfm"/></cfif>
  <cfif VARIABLES.adsV1WorkspaceView EQ "vouchers" AND VARIABLES.adsAccessCanAdminVouchers><cfinclude template="includes/workspace_admin_vouchers.cfm"/></cfif>
  <cfif VARIABLES.adsV1WorkspaceView EQ "admin" AND (VARIABLES.adsAccessCanAdminFinance OR VARIABLES.adsAccessCanReviewCampaign)><cfinclude template="includes/workspace_admin.cfm"/></cfif>
  <cfif VARIABLES.adsV1WorkspaceView EQ "history"><cfinclude template="includes/workspace_history.cfm"/></cfif>
</cfif>

<script src="/assets/js/ads-performance-dashboard.js?2026090203"></script>
<script type="module">
  const performanceCharts = document.querySelectorAll("[data-ads-performance-chart]");
  if (performanceCharts.length && window.AdsPerformanceDashboard) {
    import("/assets/js/chart.es.min.js").then(({ Chart }) => {
      performanceCharts.forEach((canvas) => {
        const source = document.getElementById(canvas.dataset.sourceId);
        if (!source) return;
        const rows = JSON.parse(source.textContent || "[]");
        const config = window.AdsPerformanceDashboard.buildChartConfig(rows);
        const [data, options] = window.AdsPerformanceDashboard.toMdbChartArguments(config);
        new Chart(canvas, data, options);
      });
    }).catch((error) => {
      console.error("Não foi possível carregar o gráfico de performance.", error);
    });
  }
</script>
