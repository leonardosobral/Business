<table class="table table-stripped table-condensed table-sm mb-0">

    <thead>
        <tr>
            <th class="my-0 pt-0">Pos.</th>
            <th class="my-0 pt-0">Data</th>
            <th class="my-0 pt-0">UF</th>
            <th class="my-0 pt-0">Eventos</th>
            <td class="text-end my-0 pt-0"><icon class="fa fa-users" title="Público"></icon></td>
        </tr>
    </thead>

    <tbody>

        <cfoutput query="qStatsEvento">

            <tr style="cursor: pointer;" <cfif qStatsEvento.id_evento EQ URL.id_evento>class="table-active"  onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#'"<cfelse>onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_evento=#urlEncodedFormat(qStatsEvento.id_evento)#'"</cfif> >
                <td class="<cfif qBi.tipo EQ "empresa" AND qStatsEvento.tt>table-ts</cfif>" nowrap>#qStatsEvento.currentrow#º</td>
                <td class="<cfif qBi.tipo EQ "empresa" AND qStatsEvento.tt>table-ts</cfif>" nowrap>#qStatsEvento.data_final#</td>
                <td class="<cfif qBi.tipo EQ "empresa" AND qStatsEvento.tt>table-ts</cfif>">#qStatsEvento.estado#</td>
                <td class="<cfif qBi.tipo EQ "empresa" AND qStatsEvento.tt>table-ts</cfif>">
                    <cfif qBi.tipo EQ "empresa">
                        <cfinclude template="ticketeira_icone.cfm"/>
                    </cfif>
                    <a target="_blank" href="https://roadrunners.run/evento/#qStatsEvento.tag#/"><img src="/assets/icons/rh_rr_favicon.png" width="16" class="me-2"/></a>
                    <a target="_blank" href="https://openresults.run/evento/#qStatsEvento.tag#/"><img src="/assets/icons/rh_or_favicon.png" width="16" class="me-2"/></a>
                    #replace(replace(qStatsEvento.nome_evento, 'Live! Run XP 2025 - ', '<span class="badge bg-warning">2025</span>&nbsp;&nbsp;'), 'Live! Run XP 2024 - ', '<span class="badge bg-secondary">2024</span>&nbsp;&nbsp;')#
                </td>
                <td width="15%" class="text-end <cfif qBi.tipo EQ "empresa" AND qStatsEvento.tt>table-ts</cfif>">#lsNumberFormat(qStatsEvento.concluintes)#</td>
            </tr>

        </cfoutput>

    </tbody>

</table>
