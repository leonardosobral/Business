<div class="row g-3">
    <div class="col-md-3 mb-3">
        <a href="<cfoutput>#VARIABLES.template#</cfoutput>?regiao=&estado=&cidade=&preset=2025">
            <div class="card bg-primary py-2 px-3">
                <p class="h4 m-0"><cfoutput>#lsnumberFormat(qCount2025.total)# / #(isNumeric(qCount2025.total) AND isNumeric(qCountLinkEv2025.total) ? lsnumberFormat(qCount2025.total+qCountLinkEv2025.total) : 0)# / #lsnumberFormat(qCountEv2025.total)#</cfoutput></p>
                <p class="m-0"><cfoutput>#lsnumberFormat(qCount2025.concluintes)# em 2025</cfoutput></p>
            </div>
        </a>
    </div>
    <div class="col-md-3 mb-3">
        <a href="<cfoutput>#VARIABLES.template#</cfoutput>?regiao=&estado=&cidade=&preset=2025">
            <div class="card bg-primary py-2 px-3">
                <p class="h4 m-0"><cfoutput>#lsnumberFormat(qCount2024.total)# / #(isNumeric(qCount2024.total) AND isNumeric(qCountLinkEv2024.total) ? lsnumberFormat(qCount2024.total+qCountLinkEv2024.total) : 0)# / #lsnumberFormat(qCountEv2024.total)#</cfoutput></p>
                <p class="m-0"><cfoutput>#lsnumberFormat(qCount2024.concluintes)# em 2024</cfoutput></p>
            </div>
        </a>
    </div>
    <div class="col-md-3 mb-3">
        <a href="<cfoutput>#VARIABLES.template#</cfoutput>?regiao=&estado=&cidade=&preset=2023">
        <div class="card bg-primary py-2 px-3">
            <p class="h4 m-0"><cfoutput>#lsnumberFormat(qCount2023.total)# / #(isNumeric(qCount2023.total) AND isNumeric(qCountLinkEv2023.total) ? lsnumberFormat(qCount2023.total+qCountLinkEv2023.total) : 0)# / #lsnumberFormat(qCountEv2023.total)#</cfoutput></p>
            <p class="m-0"><cfoutput>#lsnumberFormat(qCount2023.concluintes)# em 2023</cfoutput></p>
        </div>
        </a>
    </div>
    <div class="col-md-3 mb-3">
        <a href="<cfoutput>#VARIABLES.template#</cfoutput>?regiao=&estado=&cidade=&preset=">
            <div class="card bg-primary py-2 px-3">
                <p class="h4 m-0"><cfoutput>#lsnumberFormat(qCountTotal.total)# / #(isNumeric(qCountTotal.total) AND isNumeric(qCountLinkEvTotal.total) ? lsnumberFormat(qCountTotal.total+qCountLinkEvTotal.total) : 0)# / #lsnumberFormat(qCountEvTotal.total)#</cfoutput></p>
                <p class="m-0"><cfoutput>#lsnumberFormat(qCountTotal.concluintes)# no Período</cfoutput></p>
            </div>
        </a>
    </div>
</div>
