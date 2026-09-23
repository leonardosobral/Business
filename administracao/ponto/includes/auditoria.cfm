<cfprocessingdirective pageencoding="utf-8"/>
<cfoutput>
<details class="mt-4"><summary class="fw-semibold">Histórico de alterações</summary>
    <cfset pontoActionLabels = {iniciar="Início", pausar="Pausa", retomar="Retomada", finalizar="Finalização", salvar="Horários informados / corrigidos", viagem="Viagem registrada", cancelar="Cancelamento"}/>
    <cfloop query="qPontoAudit">
        <div class="border-bottom py-3">
            <div class="small text-muted">#criado#</div><strong>#encodeForHTML(structKeyExists(pontoActionLabels, acao) ? pontoActionLabels[acao] : acao)#</strong>
            <cfloop list="antes,depois" index="pontoAuditSide">
                <cfset pontoAuditJson = qPontoAudit[pontoAuditSide][qPontoAudit.currentRow]/>
                <cfif len(pontoAuditJson) AND isJSON(pontoAuditJson)>
                    <cfset pontoSnapshot = deserializeJSON(pontoAuditJson)/>
                    <div class="small mt-1"><span class="text-muted">#pontoAuditSide EQ 'antes' ? 'Antes' : 'Depois'#:</span>
                        <cfif pontoSnapshot.tipo EQ 'viagem'>
                            #encodeForHTML(pontoSnapshot.dia_viagem)# · #pontoHoras(pontoSnapshot.minutos_viagem*60)#
                        <cfelse>
                            <cfloop array="#pontoSnapshot.periodos#" index="pontoSnapshotPeriod">
                                <cfset pontoAuditStart = createObject('java','java.time.OffsetDateTime').parse(pontoSnapshotPeriod.inicio).atZoneSameInstant(createObject('java','java.time.ZoneId').of('America/Sao_Paulo')).format(createObject('java','java.time.format.DateTimeFormatter').ofPattern('dd/MM/yyyy HH:mm:ss'))/>
                                #encodeForHTML(pontoAuditStart)# →
                                <cfif structKeyExists(pontoSnapshotPeriod, 'fim') AND NOT isNull(pontoSnapshotPeriod.fim)>
                                    <cfset pontoAuditEnd = createObject('java','java.time.OffsetDateTime').parse(pontoSnapshotPeriod.fim).atZoneSameInstant(createObject('java','java.time.ZoneId').of('America/Sao_Paulo')).format(createObject('java','java.time.format.DateTimeFormatter').ofPattern('dd/MM/yyyy HH:mm:ss'))/>
                                    #encodeForHTML(pontoAuditEnd)#
                                <cfelse>em aberto</cfif><br>
                            </cfloop>
                        </cfif>
                        <span class="text-muted">(#encodeForHTML(pontoSnapshot.estado)#)</span>
                    </div>
                </cfif>
            </cfloop>
        </div>
    </cfloop>
</details>
</cfoutput>
