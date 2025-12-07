<div class="card">

    <div class="card-header <cfif URL.preset EQ "2025">bg-warning<cfelseif URL.preset EQ "2024">bg-secondary<cfelse>bg-black</cfif> text-white fw-bold px-3 pt-2 pb-0">
        <h6 class="m0 p0">Ticketeiras</h6>
    </div>

    <div class="card-body p-2">

        <div class="<cfif len(trim(URL.id_evento))>table-wrapper-sm<cfelse>table-wrapper-lg</cfif>">

            <table class="table table-stripped table-condensed table-sm mb-0">

                <thead>
                    <tr>
                        <th class="my-0 pt-0"></th>
                        <th class="my-0 pt-0">Eventos</th>
                        <th class="my-0 pt-0">Resultados</th>
                        <th class="my-0 pt-0">Média</th>
                        <td class="text-end my-0 pt-0"><icon class="fa fa-users" title="Público"></icon></td>
                    </tr>
                </thead>

                <tbody>
                    <cfoutput query="qShareInscricao">
                    <tr style="cursor: pointer;" <cfif qShareInscricao.url_inscricao_domain EQ URL.inscricao>class="table-active"  onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#'"<cfelse>onclick="location.href = './?preset=#URL.preset#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&inscricao=#urlEncodedFormat(qShareInscricao.url_inscricao_domain)#'"</cfif> >
                        <td>
                            <cfif qBi.tipo EQ "empresa">
                                <cfinclude template="ticketeira_icone.cfm"/>
                            </cfif>
                            #qShareInscricao.url_inscricao_domain#
                        </td>
                        <td class="text-end">#lsNumberFormat(qShareInscricao.eventos)#</td>
                        <td class="text-end">#lsNumberFormat(qShareInscricao.tem_resultado)#</td>
                        <td class="text-end">#lsNumberFormat(qShareInscricao.media)#</td>
                        <td class="text-end" style="background-color: rgba(255,200,0,#VARIABLES.heat#);">
                            #lsNumberFormat(qShareInscricao.concluintes)#
                        </td>
                        <!---td class="text-end">#lsNumberFormat((qKilometragem.concluintes*100)/qTotalKilometragem.concluintes, 9.9)#%</td--->
                    </tr>
                    </cfoutput>
                </tbody>

            </table>

        </div>

    </div>

</div>
