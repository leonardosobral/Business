<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfoutput>
<section class="rr-race-guide" aria-label="Guia das edições" data-permanent-race>
    <p class="rr-race-intro">Acompanhe as edições de <strong>#encodeForHTML(qAgrega.nome_evento_agregado)#</strong>: datas cadastradas, informações de inscrição e acesso aos resultados disponíveis em cada prova.</p>
    <cfif NOT structIsEmpty(VARIABLES.permanentNext)>
        <div class="rr-race-feature">
            <h2><cfif dateCompare(VARIABLES.permanentNext.start,now(),"d") LTE 0>Em andamento<cfelse>Próxima edição cadastrada</cfif></h2>
            <p><strong>#encodeForHTML(VARIABLES.permanentNext.dateLabel)#</strong><cfif len(VARIABLES.permanentNext.city)> · #encodeForHTML(VARIABLES.permanentNext.city)#<cfif len(VARIABLES.permanentNext.uf)> (#encodeForHTML(VARIABLES.permanentNext.uf)#)</cfif></cfif></p>
            <a class="rr-race-cta" href="#encodeForHTMLAttribute(VARIABLES.permanentNext.path)#">Ver detalhes da edição</a>
            <p class="rr-race-note">Confira na página da edição as distâncias, o regulamento e a disponibilidade de inscrição antes de se programar.</p>
        </div>
    <cfelse>
        <p class="rr-race-empty">Não há próxima edição neste histórico. Você pode consultar as edições anteriores e procurar outras provas nos calendários locais.</p>
    </cfif>
    <cfif NOT structIsEmpty(VARIABLES.permanentLast)>
        <p class="rr-race-history">Última edição neste histórico: <a href="#encodeForHTMLAttribute(VARIABLES.permanentLast.path)#">#encodeForHTML(VARIABLES.permanentLast.dateLabel)# — #encodeForHTML(VARIABLES.permanentLast.name)#</a>.</p>
    </cfif>
    <cfif arrayLen(VARIABLES.permanentPlaces)>
        <details class="rr-race-details" open>
            <summary>Mais corridas nas cidades desta prova</summary>
            <ul class="rr-race-links"><cfloop array="#VARIABLES.permanentPlaces#" index="permanentPlace">
                <li><a href="#encodeForHTMLAttribute(permanentPlace.path)#">Corridas em #encodeForHTML(permanentPlace.name)#</a> · <a href="#encodeForHTMLAttribute(permanentPlace.statePath)#">Calendário: #encodeForHTML(permanentPlace.stateName)#</a></li>
            </cfloop></ul>
        </details>
    </cfif>
    <details class="rr-race-details">
        <summary>Inscrições, resultados e planejamento</summary>
        <p>Abra a edição desejada para consultar suas informações e os links do organizador. Resultados e fotos aparecem quando há links disponíveis; uma edição no histórico não garante que esses materiais estejam publicados.</p>
        <p>Para estimar seu tempo e as parciais, use a <a href="/calculadora-de-pace/">calculadora de pace</a>. As abas abaixo separam as próximas edições das realizadas.</p>
    </details>
</section>
</cfoutput>
