<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfparam name="VARIABLES.aracaju2026Context" default="edition"/>
<!--- A dated editorial feature, bounded to the confirmed edition; no personal results are loaded. --->
<cfquery name="qAracajuFeatured" cachedwithin="#createTimeSpan(0,0,1,0)#" timeout="8">
    SELECT e.id_evento, e.tag, e.nome_evento, e.data_inicial, e.data_final,
        EXISTS(SELECT 1 FROM tb_resultados r WHERE r.id_evento=e.id_evento
            AND r.origem_resultado <> 'validacao_documental' AND r.status_final < 3) AS available
    FROM tb_evento_corridas e
    WHERE e.id_evento=39399 AND e.ativo=true AND e.tag='2026-maratona-de-aracaju-2026'
        AND e.data_inicial=DATE '2026-10-31' AND e.data_final=DATE '2026-11-01'
        AND coalesce(lower(trim(e.status_evento)),'') NOT IN ('cancelado','adiado')
        AND coalesce(e.obs_resultado,'') <> 'PNC'
</cfquery>
<cfif qAracajuFeatured.recordCount>
<section class="card my-3" id="maratona-aracaju-2026" aria-labelledby="aracaju-2026-title" data-aracaju-2026>
 <div class="card-body">
    <h2 class="h5 fw-bold" id="aracaju-2026-title">Maratona de Aracaju 2026: programação e resultados</h2>
    <p>As provas desta edição em Aracaju, Sergipe, estão distribuídas entre <strong>31 de outubro e 1º de novembro de 2026</strong>. Consulte abaixo o dia de cada distância.</p>
    <cfif qAracajuFeatured.available[1]>
        <p>Há resultados importados no OpenResults. Confira a distância e a situação da publicação; os dados podem receber atualizações.</p>
    <cfelse>
        <p>Os resultados de 2026 ainda não foram importados no OpenResults. A publicação pode ocorrer em momentos diferentes para cada distância.</p>
    </cfif>
    <div class="d-flex flex-wrap gap-2 mb-3">
        <a class="btn btn-sm btn-warning" href="https://openresults.run/evento/2026-maratona-de-aracaju-2026/">Consultar resultados de 2026</a>
        <cfif VARIABLES.aracaju2026Context NEQ "edition"><a class="btn btn-sm btn-outline-dark" href="/evento/2026-maratona-de-aracaju-2026/#maratona-aracaju-2026">Fotos e detalhes da edição</a></cfif>
    </div>
    <cfif VARIABLES.aracaju2026Context EQ "edition">
        <cfset VARIABLES.aracajuFirstDayLinked=false/>
        <cfloop array="#VARIABLES.eventFocoGalleries#" index="aracajuGallery">
            <cfif reFindNoCase('^https://(www\.)?focoradical\.com\.br/(prova/|evento/|busca-numero\?)',aracajuGallery.url & "") AND findNoCase("20261031-maratona-de-aracaju-2026",aracajuGallery.url & "")><cfset VARIABLES.aracajuFirstDayLinked=true/></cfif>
        </cfloop>
        <cfif NOT VARIABLES.aracajuFirstDayLinked>
            <p><a href="https://www.focoradical.com.br/evento/20261031-maratona-de-aracaju-2026-1o-dia-aracaju-14873" target="_blank" rel="noopener">Fotos de sábado, 31/10: 10 km e 21 km — Foco Radical</a></p>
        </cfif>
        <cfloop array="#VARIABLES.eventFocoGalleries#" index="aracajuGallery">
            <cfif reFindNoCase('^https://(www\.)?focoradical\.com\.br/(prova/|evento/|busca-numero\?)',aracajuGallery.url & "")>
                <p><a href="<cfoutput>#encodeForHTMLAttribute(aracajuGallery.url)#</cfoutput>" target="_blank" rel="noopener"><cfoutput>Galeria Foco Radical: #encodeForHTML(aracajuGallery.name)#<cfif len(trim(aracajuGallery.date & ""))> — #encodeForHTML(aracajuGallery.date)#</cfif></cfoutput></a></p>
            </cfif>
        </cfloop>
        <p class="small">Cada galeria corresponde ao dia indicado. As fotos são disponibilizadas pela plataforma de fotografia.</p>
    </cfif>
    <details<cfif dateCompare(now(),createDate(2026,11,1),"d") LTE 0> open</cfif>>
        <summary class="fw-semibold">Programação da edição 2026 e regulamento</summary>
        <table class="table table-sm mt-2 mb-2">
            <caption class="small">Largadas previstas no regulamento, horário de Brasília.</caption>
            <thead><tr><th scope="col">Dia</th><th scope="col">Distância</th><th scope="col">Largada</th></tr></thead>
            <tbody>
                <tr><td>31/10, sábado</td><td>21 km</td><td>04h30</td></tr>
                <tr><td>31/10, sábado</td><td>10 km</td><td>05h00</td></tr>
                <tr><td>01/11, domingo</td><td>42,195 km</td><td>04h00</td></tr>
                <tr><td>01/11, domingo</td><td>5 km</td><td>05h00</td></tr>
            </tbody>
        </table>
        <p class="small mb-2">Fonte: <a href="https://cdn.ticketsports.com.br/ticketagora/arquivos/evento/74615/feb8f700da6241dc8080aa658a63261a638981859777687336.pdf" target="_blank" rel="noopener">regulamento da organização</a>, conferido em 31/10/2026. A organização pode alterar os horários.</p>
    </details>
    <nav class="d-flex flex-wrap gap-2 mt-3 small" aria-label="Corridas e histórico em Aracaju">
        <a href="/estado/se/aracaju/">Calendário de Aracaju</a>
        <a href="/estado/se/">Corridas em Sergipe</a>
        <a href="/maratona/maratona-de-aracaju/">Edições da Maratona de Aracaju</a>
    </nav>
 </div>
</section>
</cfif>
