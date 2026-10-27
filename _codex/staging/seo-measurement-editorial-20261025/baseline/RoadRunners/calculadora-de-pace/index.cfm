<cfprocessingdirective pageencoding="utf-8"/>
<cfset VARIABLES.template = "/calculadora-de-pace/"/>
<cfinclude template="../includes/estrutura/variaveis.cfm"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>
<cfscript>
VARIABLES.loginAutoPrompt = false;
VARIABLES.includeHreflang = false;
REQUEST.currentRouteKey = "";
VARIABLES.title = "Calculadora de pace: ritmo, tempo e distância | Road Runners";
VARIABLES.description = "Calcule seu pace em min/km, tempo de prova ou distância. Veja parciais para 5 km, 10 km, meia maratona e maratona e encontre corridas no calendário.";
VARIABLES.keywords = "calculadora de pace, ritmo de corrida, tempo de prova, parciais";
VARIABLES.canonical = APPLICATION.baseCanonica & "/calculadora-de-pace/";
VARIABLES.paceStates = "AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO";
VARIABLES.paceState = structKeyExists(URL,"estado") && listFindNoCase(VARIABLES.paceStates,URL.estado) ? uCase(URL.estado) : "";
VARIABLES.paceLocation = new services.LocationResolver();
</cfscript>
<!doctype html>
<html lang="pt-BR">
<cfinclude template="../includes/estrutura/head.cfm"/>
<link rel="stylesheet" href="/assets/css/runnerhub-pace.min.css?v=20261025a"/>
<body>
<cfinclude template="../includes/estrutura/seo-web-tools-body-start.cfm"/>
<div class="container">
<cfinclude template="../includes/estrutura/header.cfm"/>
<main id="rr-page-content" class="rr-page-content rr-pace" data-rr-page-content>
    <nav aria-label="Caminho de navegação"><a href="/">Início</a> / <span aria-current="page">Calculadora de pace</span></nav>
    <header class="rr-pace-intro">
        <p class="rr-pace-kicker">Planeje sua próxima corrida</p>
        <h1>Calculadora de pace</h1>
        <p>Descubra o ritmo por quilômetro, o tempo de prova ou a distância. Confira as parciais mantendo o mesmo pace.</p>
    </header>
    <noscript><p>Ative o JavaScript para utilizar os cálculos interativos. As fórmulas e os exemplos estão disponíveis abaixo.</p></noscript>
    <div class="rr-pace-layout">
    <form class="rr-pace-card" data-pace-form novalidate>
        <fieldset class="rr-pace-modes">
            <legend>O que você quer calcular?</legend>
            <label><input type="radio" name="pace-mode" value="pace" checked/> Pace</label>
            <label><input type="radio" name="pace-mode" value="time"/> Tempo</label>
            <label><input type="radio" name="pace-mode" value="distance"/> Distância</label>
        </fieldset>
        <fieldset data-pace-group="distance">
            <legend>Distância da corrida</legend>
            <label for="pace-preset">Distâncias frequentes</label>
            <select id="pace-preset"><option value="5" selected>5 km</option><option value="10">10 km</option><option value="21.0975">Meia maratona — 21,0975 km</option><option value="42.195">Maratona — 42,195 km</option><option value="">Outra distância</option></select>
            <label for="pace-distance">Distância em quilômetros</label>
            <input id="pace-distance" type="text" inputmode="decimal" value="5" maxlength="12" aria-describedby="pace-distance-help pace-error"/>
            <small id="pace-distance-help">Use vírgula ou ponto decimal. Exemplo: 7,5.</small>
        </fieldset>
        <fieldset data-pace-group="time">
            <legend>Tempo total</legend>
            <div class="rr-pace-clock">
                <div><label for="pace-hours">Horas</label><input id="pace-hours" type="text" inputmode="numeric" value="0" maxlength="4" data-clock-paste="time" aria-describedby="pace-time-help pace-error"/></div>
                <div><label for="pace-minutes">Minutos</label><input id="pace-minutes" type="text" inputmode="numeric" value="30" maxlength="2" data-clock-paste="time" aria-describedby="pace-time-help pace-error"/></div>
                <div><label for="pace-seconds">Segundos</label><input id="pace-seconds" type="text" inputmode="numeric" value="00" maxlength="2" data-clock-paste="time" aria-describedby="pace-time-help pace-error"/></div>
            </div>
            <small id="pace-time-help">Você também pode colar um tempo como 00:30:00.</small>
        </fieldset>
        <fieldset data-pace-group="pace" hidden>
            <legend>Pace por quilômetro</legend>
            <div class="rr-pace-clock rr-pace-clock-two">
                <div><label for="pace-rhythm-minutes">Minutos por km</label><input id="pace-rhythm-minutes" type="text" inputmode="numeric" value="6" maxlength="3" data-clock-paste="rhythm" aria-describedby="pace-rhythm-help pace-error"/></div>
                <div><label for="pace-rhythm-seconds">Segundos</label><input id="pace-rhythm-seconds" type="text" inputmode="numeric" value="00" maxlength="2" data-clock-paste="rhythm" aria-describedby="pace-rhythm-help pace-error"/></div>
            </div>
            <small id="pace-rhythm-help">6:00 min/km significa seis minutos para cada quilômetro.</small>
        </fieldset>
        <p id="pace-error" class="rr-pace-error" data-pace-error role="alert"></p>
        <button type="submit" class="rr-pace-submit" data-pace-submit>Calcular pace</button>
    </form>
    <div>
        <div class="rr-pace-placeholder"><strong>Um ritmo, várias possibilidades</strong><p>Preencha dois valores para descobrir o terceiro e visualizar o tempo acumulado em cada parcial.</p></div>
        <section class="rr-pace-card rr-pace-result" data-pace-result hidden aria-label="Resultado do cálculo">
            <div aria-live="polite" aria-atomic="true"><h2 data-pace-label>Seu pace</h2><p class="rr-pace-value" data-pace-value></p><p class="rr-pace-context" data-pace-context></p></div>
            <p>Os tempos consideram ritmo constante, sem paradas. Não são uma previsão de desempenho.</p>
            <details><summary>Ver parciais da corrida</summary>
                <p data-pace-split-label></p>
                <div class="rr-pace-table-wrap"><table><caption>Distância e tempo acumulado</caption><thead><tr><th scope="col">Distância</th><th scope="col">Tempo</th></tr></thead><tbody></tbody></table></div>
            </details>
            <div class="rr-pace-next">
                <label for="pace-state">Encontrar provas em</label>
                <select id="pace-state"><option value="">Todo o Brasil</option><cfoutput><cfloop list="#VARIABLES.paceStates#" index="paceUf"><option value="#paceUf#"<cfif VARIABLES.paceState EQ paceUf> selected</cfif>>#encodeForHTML(VARIABLES.paceLocation.getEstadoNome(paceUf))#</option></cfloop></cfoutput></select>
                <a class="rr-pace-calendar" data-pace-calendar href="/busca/?busca_tipo=eventos">Encontrar provas</a>
                <small>O calendário usa as categorias de distância cadastradas pelos organizadores.</small>
            </div>
        </section>
    </div>
    </div>
    <section class="rr-pace-guide" aria-labelledby="pace-guide-title">
        <h2 id="pace-guide-title">Como calcular o pace?</h2>
        <p>Pace é o tempo necessário para percorrer um quilômetro. Divida o tempo total pela distância: uma corrida de 5 km em 30 minutos tem pace de <strong>6:00 min/km</strong>.</p>
        <details><summary>Fórmulas de pace, tempo e distância</summary><ul><li>Pace = tempo ÷ distância.</li><li>Tempo = distância × pace.</li><li>Distância = tempo ÷ pace.</li></ul><p>Use a mesma unidade de tempo na conta. Para converter pace em velocidade, divida 60 pelo pace em minutos por quilômetro. Um pace de 6:00 min/km equivale a 10 km/h.</p></details>
        <details><summary>Exemplos para 5 km, 10 km, meia maratona e maratona</summary>
            <div class="rr-pace-table-wrap"><table><caption>Exemplos com ritmo constante</caption><thead><tr><th scope="col">Distância</th><th scope="col">Pace</th><th scope="col">Tempo total</th></tr></thead><tbody><tr><th scope="row">5 km</th><td>6:00 min/km</td><td>00:30:00</td></tr><tr><th scope="row">10 km</th><td>5:30 min/km</td><td>00:55:00</td></tr><tr><th scope="row">21,0975 km</th><td>5:00 min/km</td><td>01:45:29</td></tr><tr><th scope="row">42,195 km</th><td>5:00 min/km</td><td>03:30:59</td></tr></tbody></table></div>
            <p>O cálculo mantém a precisão da distância e arredonda apenas o tempo exibido para o segundo mais próximo.</p>
        </details>
        <details><summary>Qual a diferença entre pace e velocidade?</summary><p>O pace mede minutos por quilômetro; quanto menor o número, mais rápido o ritmo. A velocidade mede quilômetros por hora; quanto maior o número, mais rápido você se desloca.</p></details>
        <p>Já escolheu sua distância? Explore o <a href="/busca/?busca_tipo=eventos">calendário de corridas</a> ou consulte provas <a href="/estado/pr/">no Paraná</a>, <a href="/estado/df/">no Distrito Federal</a> e <a href="/estado/sc/">em Santa Catarina</a>.</p>
    </section>
</main>
</div>
<cfinclude template="../includes/estrutura/footer.cfm"/>
<cfinclude template="../includes/modal/modal_login.cfm"/>
<cfinclude template="../includes/estrutura/seo-web-tools-body-end.cfm"/>
<script src="/assets/js/runnerhub-pace.min.js?v=20261025b"></script>
</body>
</html>
