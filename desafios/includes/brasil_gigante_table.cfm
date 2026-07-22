<section class="card cbg-dashboard-ranking">
  <header class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2 px-3 py-2">
    <div class="fw-bold"><i class="fa-solid fa-ranking-star me-2"></i>Ranking por etapas concluídas</div>
    <span class="badge badge-secondary"><cfoutput>#qBrasilGiganteRanking.recordcount#</cfoutput> atleta(s)</span>
  </header>

  <cfif NOT qBrasilGiganteRanking.recordcount>
    <div class="card-body text-muted">Nenhum atleta encontrado com os filtros selecionados.</div>
  <cfelse>
    <div class="table-responsive">
      <table class="table table-hover table-sm cbg-dashboard-table mb-0">
        <thead>
          <tr>
            <th class="text-center">#</th>
            <th>Atleta</th>
            <cfloop array="#VARIABLES.challengeCircuitEvents#" item="VARIABLES.challengeCircuitEvent">
              <th class="cbg-stage-result" title="<cfoutput>#htmlEditFormat(VARIABLES.challengeCircuitEvent.nome)#</cfoutput>"><cfoutput>#VARIABLES.challengeCircuitEvent.sigla#</cfoutput></th>
            </cfloop>
            <th class="text-center">Etapas</th>
            <th>Mandala</th>
            <th class="text-end">Ação</th>
          </tr>
        </thead>
        <tbody>
          <cfoutput query="qBrasilGiganteRanking">
            <cfset VARIABLES.challengeMandalaStatusLabel = "Em progresso"/>
            <cfset VARIABLES.challengeMandalaStatusClass = "badge-secondary"/>
            <cfswitch expression="#qBrasilGiganteRanking.mandala_status#">
              <cfcase value="proxima_etapa">
                <cfset VARIABLES.challengeMandalaStatusLabel = "Próxima etapa"/>
                <cfset VARIABLES.challengeMandalaStatusClass = "badge-info"/>
              </cfcase>
              <cfcase value="imediata">
                <cfset VARIABLES.challengeMandalaStatusLabel = "Entrega imediata"/>
                <cfset VARIABLES.challengeMandalaStatusClass = "badge-warning"/>
              </cfcase>
              <cfcase value="entregue">
                <cfset VARIABLES.challengeMandalaStatusLabel = "Entregue"/>
                <cfset VARIABLES.challengeMandalaStatusClass = "badge-success"/>
              </cfcase>
            </cfswitch>
            <tr>
              <td class="text-center text-muted">#qBrasilGiganteRanking.currentRow#</td>
              <td class="cbg-dashboard-athlete">
                <div class="d-flex align-items-center gap-2">
                  <img class="rounded-circle cbg-dashboard-avatar" src="#htmlEditFormat(qBrasilGiganteRanking.imagem_usuario)#" alt="" onerror="this.onerror=null;this.src='/assets/user.png';"/>
                  <div>
                    <div class="fw-semibold">
                      <cfif len(trim(qBrasilGiganteRanking.tag & ""))>
                        <a class="text-reset" href="https://roadrunners.run/atleta/#urlEncodedFormat(qBrasilGiganteRanking.tag)#/" target="_blank" rel="noopener noreferrer">#htmlEditFormat(qBrasilGiganteRanking.nome)#</a>
                      <cfelse>
                        #htmlEditFormat(qBrasilGiganteRanking.nome)#
                      </cfif>
                    </div>
                    <div class="small text-muted">
                      ID #qBrasilGiganteRanking.id#<cfif len(trim(qBrasilGiganteRanking.cidade & "")) OR len(trim(qBrasilGiganteRanking.estado & ""))> · #htmlEditFormat(qBrasilGiganteRanking.cidade)#<cfif len(trim(qBrasilGiganteRanking.cidade & "")) AND len(trim(qBrasilGiganteRanking.estado & ""))>/</cfif>#htmlEditFormat(qBrasilGiganteRanking.estado)#</cfif>
                    </div>
                  </div>
                </div>
              </td>
              <cfloop from="1" to="#VARIABLES.challengeCircuitTotalEvents#" index="VARIABLES.challengeStageIndex">
                <cfset VARIABLES.challengeStageParticipationColumn = "participou_" & VARIABLES.challengeStageIndex/>
                <cfset VARIABLES.challengeStageYearColumn = "ano_" & VARIABLES.challengeStageIndex/>
                <cfset VARIABLES.challengeStageParticipated = val(qBrasilGiganteRanking[VARIABLES.challengeStageParticipationColumn][qBrasilGiganteRanking.currentRow]) GT 0/>
                <cfset VARIABLES.challengeStageYear = val(qBrasilGiganteRanking[VARIABLES.challengeStageYearColumn][qBrasilGiganteRanking.currentRow])/>
                <td class="cbg-stage-result">
                  <cfif VARIABLES.challengeStageParticipated>
                    <span class="badge badge-success" title="Etapa reconhecida"><cfif VARIABLES.challengeStageYear GT 0>#VARIABLES.challengeStageYear#<cfelse><i class="fa-solid fa-check"></i></cfif></span>
                  <cfelse>
                    <span class="text-muted">-</span>
                  </cfif>
                </td>
              </cfloop>
              <td class="text-center fw-bold">#qBrasilGiganteRanking.nodesafio#/#VARIABLES.challengeCircuitTotalEvents#</td>
              <td>
                <span class="badge #VARIABLES.challengeMandalaStatusClass#">#VARIABLES.challengeMandalaStatusLabel#</span>
                <cfif qBrasilGiganteRanking.mandala_status EQ "entregue" AND len(trim(qBrasilGiganteRanking.mandala_entregue_em & ""))>
                  <div class="small text-muted mt-1"><cfif isDate(qBrasilGiganteRanking.mandala_entregue_em)>#dateFormat(qBrasilGiganteRanking.mandala_entregue_em, "dd/mm/yyyy")# #timeFormat(qBrasilGiganteRanking.mandala_entregue_em, "HH:mm")#<cfelse>#htmlEditFormat(qBrasilGiganteRanking.mandala_entregue_em)#</cfif></div>
                </cfif>
              </td>
              <td class="text-end">
                <cfif listFindNoCase("proxima_etapa,imediata", qBrasilGiganteRanking.mandala_status)>
                  <form method="post" class="d-inline" onsubmit="return confirm('Confirmar a entrega da mandala para este atleta?');">
                    <input type="hidden" name="challenge_action" value="entregar_mandala"/>
                    <input type="hidden" name="challenge_medal_csrf" value="#htmlEditFormat(VARIABLES.challengeMedalCsrf)#"/>
                    <input type="hidden" name="id_usuario" value="#qBrasilGiganteRanking.id#"/>
                    <button class="btn btn-success btn-sm text-nowrap" type="submit"><i class="fa-solid fa-award me-1"></i> Mandala entregue</button>
                  </form>
                <cfelse>
                  <span class="text-muted">-</span>
                </cfif>
              </td>
            </tr>
          </cfoutput>
        </tbody>
      </table>
    </div>
  </cfif>
</section>
