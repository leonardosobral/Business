<cfscript>
function bannerDashboardFilters(required struct params, required query choices) {
    var result={days=30,banner='',invalidBanner=false};
    if (structKeyExists(params,'periodo') AND isSimpleValue(params.periodo) AND params.periodo=='7') result.days=7;
    if (structKeyExists(params,'banner') AND isSimpleValue(params.banner) AND len(trim(params.banner))) {
        var requested=lCase(trim(params.banner));
        for (var row in choices) {
            if (row.id_banner==requested) {result.banner=requested; return result;}
        }
        result.invalidBanner=true;
    }
    return result;
}
function bannerDashboardTotals(required query metrics) {
    var result={impressions=0,clicks=0,ctr=0};
    for (var row in metrics) {result.impressions+=row.impressions; result.clicks+=row.clicks;}
    if (result.impressions>0) result.ctr=result.clicks*100/result.impressions;
    return result;
}
function bannerDashboardScopeLabel(required struct scope, required string dimension) {
    if (dimension=='regions') return scope.regions_mode=='ALL' ? 'Todo o Brasil' : arrayToList(scope.regions,', ');
    if (scope.pages_mode=='ALL') return 'Todas as páginas compatíveis';
    var labels={home='Página inicial',search='Busca de eventos',state='Eventos por estado',event='Página de evento',athlete='Página do atleta'};
    var names=[];
    for (var page in scope.pages) arrayAppend(names,structKeyExists(labels,page) ? labels[page] : page);
    return arrayToList(names,', ');
}
</cfscript>
