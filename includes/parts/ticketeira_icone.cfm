<a target="_blank" href="<cfoutput>#len(trim(url_inscricao_domain)) ? url_inscricao_domain : url_hotsite#</cfoutput>">

    <cfif url_inscricao_domain CONTAINS "ticketsports">
        <img src="/assets/icons/ticketsports.png" width="20" class="me-2" title="Ticket Sports"/>

    <cfelseif url_inscricao_domain CONTAINS "centraldacorrida">
        <img src="/assets/icons/centraldacorrida.png" width="20" class="me-2" title="Central da Corrida"/>

    <cfelseif url_inscricao_domain CONTAINS "doity">
        <img src="/assets/icons/doity.png" width="20" class="me-2" title="Doity"/>

    <cfelseif url_inscricao_domain CONTAINS "corridao">
    <img src="/assets/icons/corridao.png" width="20" class="me-2" title="Corridão"/>

    <cfelseif url_inscricao_domain CONTAINS "esportecorrida">
        <img src="/assets/icons/esportecorrida.png" width="20" class="me-2" title="Esporte Corrida"/>

    <cfelseif url_inscricao_domain CONTAINS "minhasinscricoes">
        <img src="/assets/icons/minhasinscricoes.png" width="20" class="me-2" title="Minhas Inscrições"/>

    <cfelseif url_inscricao_domain CONTAINS "onsports">
        <img src="/assets/icons/onsports.png" width="20" class="me-2" title="On Sports"/>

    <cfelseif url_inscricao_domain CONTAINS "portaldascorridas">
        <img src="/assets/icons/portaldascorridas.png" width="20" class="me-2" title="Portal das Corridas"/>

    <cfelseif url_inscricao_domain CONTAINS "runningland">
        <img src="/assets/icons/runingland.png" width="20" class="me-2" title="Running Land"/>

    <cfelseif url_inscricao_domain CONTAINS "sesc">
        <img src="/assets/icons/sesc.png" width="20" class="me-2" title="Sesc"/>

    <cfelseif url_inscricao_domain CONTAINS "sympla">
        <img src="/assets/icons/sympla.png" width="20" class="me-2" title="Sympla"/>

    <cfelseif url_inscricao_domain CONTAINS "tfsports">
        <img src="/assets/icons/tfsports.png" width="20" class="me-2" title="TF Sports"/>

    <cfelseif url_inscricao_domain CONTAINS "races">
        <img src="/assets/icons/races.png" width="20" class="me-2" title="Races"/>

    <cfelseif url_inscricao_domain CONTAINS "yescom">
        <img src="/assets/icons/yescom.png" width="20" class="me-2" title="Yescom"/>

    <cfelseif url_inscricao_domain CONTAINS "iguana">
        <img src="/assets/icons/yescom.png" width="20" class="me-2" title="Iguana"/>

    <cfelseif url_inscricao_domain CONTAINS "o2" OR url_inscricao_domain CONTAINS "ativo" OR url_inscricao_domain CONTAINS "circuitodasestacoes">
        <img src="/assets/icons/o2.png" width="20" class="me-2" title="O2"/>

    <cfelseif url_inscricao_domain CONTAINS "focoradical">
        <img src="/assets/icons/foco.png" width="20" class="me-2" title="Foco Radical"/>

    <cfelseif url_inscricao_domain CONTAINS "movnow">
        <img src="/assets/icons/movnow.png" width="20" class="me-2" title="MovNow"/>

    <cfelseif url_inscricao_domain CONTAINS "google">
        <img src="/assets/icons/google.png" width="20" class="me-2" title="Google"/>

    <cfelseif url_inscricao_domain CONTAINS "instagram">
        <img src="/assets/icons/instagram.png" width="20" class="me-2" title="Instagram"/>

    <cfelseif url_inscricao_domain CONTAINS "atletis">
        <img src="/assets/icons/atletis.png" width="20" class="me-2" title="Atletis"/>

    <cfelseif url_inscricao_domain CONTAINS "godream">
        <img src="/assets/icons/godream.png" width="20" class="me-2" title="Go Dream"/>

    <cfelseif len(trim(url_inscricao_domain))>
        <img src="/assets/icons/ticket.png" width="20" class="me-2" title="Ticketeira própria ou não mapeada"/>

    <cfelse>
        <span class="px-1">
            <i class="fa-solid fa-triangle-exclamation opacity-25 me-1" title="Sem link de inscrição"></i>
        </span>

    </cfif>

</a>
