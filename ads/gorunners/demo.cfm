<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfset VARIABLES.theme="dark"/>
<cfset VARIABLES.template="/ads/gorunners/"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../includes/access.cfm"/>
<cfif NOT adsAccessCanViewZones>
    <cfheader statuscode="403"/><cfcontent reset="true"/><p>Acesso restrito à publicidade.</p><cfabort/>
</cfif>
<cfif NOT listFindNoCase("GET,HEAD", CGI.request_method)>
    <cfheader name="Allow" value="GET, HEAD"/><cfheader statuscode="405"/><cfabort/>
</cfif>
<!doctype html><html lang="pt-BR">
<cfinclude template="../../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
<cfinclude template="../../includes/estrutura/header.cfm"/>
<main class="container pb-5" id="zone-demo" style="margin-top:-55px">
    <a href="/ads/gorunners/" class="text-muted">Voltar às zonas patrocinadas</a>
    <h1 class="h3 mt-2">Simular compra de zona patrocinada</h1>
    <p class="text-muted">Experimente o mapa e a compra com valores fictícios. Nenhuma área é reservada no jogo e nenhum pagamento é cobrado.</p>
    <noscript><p class="alert alert-warning">Ative o JavaScript para usar o simulador.</p></noscript>
    <section id="demo-area" class="card p-3 p-md-4">
        <h2 class="h5" tabindex="-1">Selecionar área e período</h2>
        <button id="demo-example" type="button" class="btn btn-sm btn-outline-light align-self-start mb-2">Usar área de exemplo</button>
        <cfinclude template="zone_map.cfm"/>
        <div class="row g-3 mb-3">
            <label class="col-sm-6">Primeiro dia<input class="form-control" id="demo-start" type="date" required></label>
            <label class="col-sm-6">Término (primeiro dia fora da campanha)<input class="form-control" id="demo-end" type="date" required></label>
        </div>
        <p id="demo-error" class="text-warning mb-2" role="alert"></p>
        <button type="button" id="demo-quote" class="btn btn-warning align-self-start">Simular cotação</button>
    </section>
    <section id="demo-order" class="card p-3 p-md-4" hidden>
        <h2 id="demo-title" class="h5" tabindex="-1"></h2>
        <p id="demo-period" class="mb-1"></p>
        <p id="demo-price" class="fw-bold"></p>
        <p id="demo-message"></p>
        <div id="demo-sponsor" hidden>
            <label class="mb-3">Marca de exemplo<input id="demo-brand" class="form-control" value="Marca de exemplo" maxlength="80" minlength="2" required></label>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <button type="button" id="demo-next" class="btn btn-warning"></button>
            <button type="button" id="demo-edit" class="btn btn-outline-light">Alterar área ou datas</button>
        </div>
    </section>
    <style>#zone-demo [hidden] { display: none !important; }</style>
</main>
<script defer src="/ads/gorunners/demo.js"></script>
<cfinclude template="../../includes/estrutura/footer.cfm"/>
</body></html>
