<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfoutput>
<section class="rr-race-guide" aria-label="Guia das edições" data-permanent-race>
    <p class="rr-race-intro">Acompanhe <cfif VARIABLES.permanentCircuitMode>as etapas<cfelse>as edições</cfif> de <strong>#encodeForHTML(qAgrega.nome_evento_agregado)#</strong>: datas cadastradas, informações de inscrição e acesso aos resultados disponíveis em cada prova.</p>
    <cfif NOT structIsEmpty(VARIABLES.permanentNext)>
        <div class="rr-race-feature">
            <h2><cfif dateCompare(VARIABLES.permanentNext.start,now(),"d") LTE 0>Em andamento<cfelse><cfif VARIABLES.permanentCircuitMode>Próxima etapa cadastrada<cfelse>Próxima edição cadastrada</cfif></cfif></h2>
            <p><strong>#encodeForHTML(VARIABLES.permanentNext.dateLabel)#</strong><cfif len(VARIABLES.permanentNext.city)> · #encodeForHTML(VARIABLES.permanentNext.city)#<cfif len(VARIABLES.permanentNext.uf)> (#encodeForHTML(VARIABLES.permanentNext.uf)#)</cfif></cfif></p>
            <a class="rr-race-cta" href="#encodeForHTMLAttribute(VARIABLES.permanentNext.path)#">Ver detalhes <cfif VARIABLES.permanentCircuitMode>da etapa<cfelse>da edição</cfif></a>
            <p class="rr-race-note">Confira na página da edição as distâncias, o regulamento e a disponibilidade de inscrição antes de se programar.</p>
        </div>
    <cfelse>
        <p class="rr-race-empty">Não há próxima edição neste histórico. Você pode consultar as edições anteriores e procurar outras provas nos calendários locais.</p>
    </cfif>
    <cfif NOT structIsEmpty(VARIABLES.permanentLast)>
        <p class="rr-race-history"><cfif VARIABLES.permanentCircuitMode>Última etapa neste histórico:<cfelse>Última edição neste histórico:</cfif> <a href="#encodeForHTMLAttribute(VARIABLES.permanentLast.path)#">#encodeForHTML(VARIABLES.permanentLast.dateLabel)# — #encodeForHTML(VARIABLES.permanentLast.name)#</a>.</p>
    </cfif>
    <cfif arrayLen(VARIABLES.permanentPlaces)>
        <details class="rr-race-details"<cfif NOT VARIABLES.permanentCircuitMode> open</cfif>>
            <summary><cfif VARIABLES.permanentCircuitMode>Calendários das cidades do circuito<cfelse>Mais corridas nas cidades desta prova</cfif></summary>
            <ul class="rr-race-links"><cfloop array="#VARIABLES.permanentPlaces#" index="permanentPlace">
                <li><a href="#encodeForHTMLAttribute(permanentPlace.path)#">Corridas em #encodeForHTML(permanentPlace.name)#</a> · <a href="#encodeForHTMLAttribute(permanentPlace.statePath)#">Calendário: #encodeForHTML(permanentPlace.stateName)#</a></li>
            </cfloop></ul>
        </details>
    </cfif>
    <cfif NOT VARIABLES.permanentCircuitMode><cfinclude template="permanent_race_editorial.cfm"/></cfif>
    <cfif arrayLen(VARIABLES.permanentRecent)>
        <details class="rr-race-details" data-permanent-post-race>
            <summary>Pós-prova: resultados e fotos das últimas <cfif VARIABLES.permanentCircuitMode>etapas<cfelse>edições</cfif></summary>
            <p>Abra a ficha da prova para consultar os resultados e as galerias já vinculados. O material disponível varia em cada edição.</p>
            <ul class="rr-race-links"><cfloop array="#VARIABLES.permanentRecent#" index="permanentRecentEvent">
                <li><a href="#encodeForHTMLAttribute(permanentRecentEvent.path & '##pos-prova')#">#encodeForHTML(permanentRecentEvent.dateLabel)# — #encodeForHTML(permanentRecentEvent.name)#</a></li>
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
