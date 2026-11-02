<cfprocessingdirective pageencoding="utf-8"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfparam name="VARIABLES.aracaju2026Context" default="edition"/>
<cfquery name="qAracajuFeatured" cachedwithin="#createTimeSpan(0,0,1,0)#" timeout="8">
    SELECT e.id_evento, EXISTS(SELECT 1 FROM tb_resultados r WHERE r.id_evento=e.id_evento
        AND r.origem_resultado <> 'validacao_documental' AND r.status_final < 3) AS available
    FROM tb_evento_corridas e
    WHERE e.id_evento=39399 AND e.ativo=true AND e.tag='2026-maratona-de-aracaju-2026'
        AND e.data_inicial=DATE '2026-10-31' AND e.data_final=DATE '2026-11-01'
        AND coalesce(lower(trim(e.status_evento)),'') NOT IN ('cancelado','adiado')
        AND coalesce(e.obs_resultado,'') <> 'PNC'
</cfquery>
<cfif qAracajuFeatured.recordCount>
<section class="or-event-card my-3" aria-labelledby="aracaju-2026-title" data-aracaju-2026>
 <div class="or-event-card-body">
    <h2 class="h5 fw-bold" id="aracaju-2026-title">Resultados da Maratona de Aracaju 2026</h2>
    <p>Esta edição reúne provas em <strong>31/10 e 01/11/2026</strong>, em Aracaju (SE). Os resultados de cada distância podem ser publicados em momentos diferentes.</p>
    <cfif qAracajuFeatured.available[1]>
        <p>Há resultados importados. Consulte as modalidades disponíveis na página da edição; a publicação pode receber atualizações.</p>
    <cfelse>
        <p>Os resultados de 2026 ainda não estão disponíveis no OpenResults. O histórico de 2025 corresponde a outra edição.</p>
    </cfif>
    <nav class="d-flex flex-wrap gap-2 mb-2" aria-label="Maratona de Aracaju e resultados da região">
        <cfif VARIABLES.aracaju2026Context NEQ "edition"><a class="btn btn-sm btn-warning" href="/evento/2026-maratona-de-aracaju-2026/">Consultar edição 2026</a></cfif>
        <a href="https://roadrunners.run/evento/2026-maratona-de-aracaju-2026/?utm_source=openresults&amp;utm_medium=referral&amp;utm_campaign=openresults_to_roadrunners&amp;utm_content=aracaju_2026#maratona-aracaju-2026" data-rr-placement="aracaju_2026">Horários, fotos e detalhes no Road Runners</a>
    </nav>
    <details>
        <summary>Resultados da região e edição anterior</summary>
        <ul class="mb-0 mt-2">
            <li><a href="/evento/2025-maratona-de-aracaju-2025/">Resultados da Maratona de Aracaju 2025</a></li>
            <li><a href="/estado/se/?cidade=aracaju">Resultados de corridas em Aracaju</a></li>
            <li><a href="/estado/se/">Resultados de corridas em Sergipe</a></li>
        </ul>
    </details>
 </div>
</section>
</cfif>
