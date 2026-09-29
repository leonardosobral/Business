<cfif NOT structKeyExists(REQUEST,"rrHandlingError") OR NOT REQUEST.rrHandlingError OR NOT structKeyExists(LOCAL,"rrEvent")><cfheader statuscode="404"/><cfabort/></cfif>
<cfmail from="Runner Hub <contato@runnerhub.run>" to="leonardo.sobral@gmail.com" cc="contato@runnerhub.run"
                    subject="Road Runners: alerta de erro #left(local.rrEvent.fingerprint,12)#" usetls="true"
                    server="smtp.mandrillapp.com" username="RunnerHub" password="md-kHpL53XqZM3olhBw2z1t1w"
                    charset="utf-8" type="html" port="587">
                <p>Uma falha foi registrada no Road Runners.</p>
<p>Ambiente: #encodeForHTML(local.rrEvent.environment)# · Ocorrências desde o último alerta: #local.rrEvent.alert.occurrences#</p>
<p>#encodeForHTML(local.rrEvent.message)#</p>
<p>Arquivo: #encodeForHTML(local.rrEvent.template)# · Linha: #local.rrEvent.line#</p>
<p>Referência: #encodeForHTML(local.rrEvent.requestId)#</p>
<cfif local.rrLogId GT 0><p><a href="https://business.roadrunners.run/portal/erros/?aba=logs&amp;log_id=#local.rrLogId#">Ver ocorrência no Business</a></p></cfif>
<p>Repetições são registradas nos logs. Os avisos são limitados por falha e por hora.</p>
            </cfmail>
