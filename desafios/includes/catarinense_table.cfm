<section class="card catarinense-ranking-card">
  <header class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2 px-3 py-2">
    <div class="fw-bold"><i class="fa-solid <cfoutput>#VARIABLES.catarinenseRankingIcon#</cfoutput> me-2"></i><cfoutput>#VARIABLES.catarinenseRankingTitle#</cfoutput></div>
    <span class="badge badge-secondary"><cfoutput>#VARIABLES.qCatarinenseRanking.recordcount#</cfoutput> atleta(s)</span>
  </header>

  <cfif NOT VARIABLES.qCatarinenseRanking.recordcount>
    <div class="card-body text-muted">Nenhum atleta neste recorte.</div>
  <cfelse>
    <div class="table-responsive">
      <table class="table table-hover table-sm catarinense-ranking-table mb-0">
        <thead>
          <tr>
            <th class="text-center">#</th>
            <th>Atleta</th>
            <cfloop from="1" to="#VARIABLES.challengeCircuitTotalEvents#" index="VARIABLES.challengeStageIndex">
              <th class="stage-score" title="Etapa <cfoutput>#VARIABLES.challengeStageIndex#</cfoutput>">E<cfoutput>#VARIABLES.challengeStageIndex#</cfoutput></th>
            </cfloop>
            <th class="text-end" title="Soma das quatro melhores pontuações">Pontos</th>
            <th class="text-center">Etapas</th>
            <th>Medalha</th>
            <th class="text-end">Ação</th>
          </tr>
        </thead>
        <tbody>
          <cfoutput query="qCatarinenseRanking">
            <cfset VARIABLES.challengeMedalStatusLabel = "Em progresso"/>
            <cfset VARIABLES.challengeMedalStatusClass = "badge-secondary"/>
            <cfswitch expression="#VARIABLES.qCatarinenseRanking.medalha_status#">
              <cfcase value="proxima_etapa">
                <cfset VARIABLES.challengeMedalStatusLabel = "Próxima etapa"/>
                <cfset VARIABLES.challengeMedalStatusClass = "badge-info"/>
              </cfcase>
              <cfcase value="imediata">
                <cfset VARIABLES.challengeMedalStatusLabel = "Entrega imediata"/>
                <cfset VARIABLES.challengeMedalStatusClass = "badge-warning"/>
              </cfcase>
              <cfcase value="entregue">
                <cfset VARIABLES.challengeMedalStatusLabel = "Entregue"/>
                <cfset VARIABLES.challengeMedalStatusClass = "badge-success"/>
              </cfcase>
            </cfswitch>
            <tr>
              <td class="text-center text-muted">#VARIABLES.qCatarinenseRanking.currentRow#</td>
              <td class="catarinense-athlete">
                <div class="d-flex align-items-center gap-2">
                  <img class="rounded-circle catarinense-avatar" src="#htmlEditFormat(VARIABLES.qCatarinenseRanking.imagem_usuario)#" alt="" onerror="this.onerror=null;this.src='/assets/user.png';"/>
                  <div>
                    <div class="fw-semibold">
                      <cfif len(trim(VARIABLES.qCatarinenseRanking.tag & ""))>
                        <a class="text-reset" href="https://roadrunners.run/atleta/#urlEncodedFormat(VARIABLES.qCatarinenseRanking.tag)#/" target="_blank" rel="noopener noreferrer">#htmlEditFormat(VARIABLES.qCatarinenseRanking.nome)#</a>
                      <cfelse>
                        #htmlEditFormat(VARIABLES.qCatarinenseRanking.nome)#
                      </cfif>
                    </div>
                    <div class="small text-muted">ID #VARIABLES.qCatarinenseRanking.id# · #htmlEditFormat(VARIABLES.qCatarinenseRanking.cidade)#/#htmlEditFormat(VARIABLES.qCatarinenseRanking.estado)#</div>
                  </div>
                </div>
              </td>
              <cfloop from="1" to="#VARIABLES.challengeCircuitTotalEvents#" index="VARIABLES.challengeStageIndex">
                <cfset VARIABLES.challengeStagePointsColumn = "pontos_" & VARIABLES.challengeStageIndex/>
                <cfset VARIABLES.challengeStageParticipationColumn = "participou_" & VARIABLES.challengeStageIndex/>
                <cfset VARIABLES.challengeStageParticipated = val(VARIABLES.qCatarinenseRanking[VARIABLES.challengeStageParticipationColumn][VARIABLES.qCatarinenseRanking.currentRow]) GT 0/>
                <cfset VARIABLES.challengeStagePoints = val(VARIABLES.qCatarinenseRanking[VARIABLES.challengeStagePointsColumn][VARIABLES.qCatarinenseRanking.currentRow])/>
                <td class="stage-score">
                  <cfif VARIABLES.challengeStageParticipated>
                    <span class="badge badge-success" title="Resultado reconhecido">#numberFormat(VARIABLES.challengeStagePoints, "9")#</span>
                  <cfelse>
                    <span class="text-muted">-</span>
                  </cfif>
                </td>
              </cfloop>
              <td class="text-end fw-bold">#numberFormat(VARIABLES.qCatarinenseRanking.distancia_percorrida, "9")#</td>
              <td class="text-center">#VARIABLES.qCatarinenseRanking.nodesafio#/#VARIABLES.challengeCircuitTotalEvents#</td>
              <td>
                <span class="badge #VARIABLES.challengeMedalStatusClass#">#VARIABLES.challengeMedalStatusLabel#</span>
                <cfif VARIABLES.qCatarinenseRanking.medalha_status EQ "entregue" AND len(trim(VARIABLES.qCatarinenseRanking.medalha_entregue_em & ""))>
                  <div class="small text-muted mt-1">#htmlEditFormat(VARIABLES.qCatarinenseRanking.medalha_entregue_em)#</div>
                </cfif>
              </td>
              <td class="text-end">
                <cfif listFindNoCase("proxima_etapa,imediata", VARIABLES.qCatarinenseRanking.medalha_status)>
                  <form method="post" class="d-inline" onsubmit="return confirm('Confirmar a entrega da medalha para este atleta?');">
                    <input type="hidden" name="challenge_action" value="entregar_medalha"/>
                    <input type="hidden" name="challenge_medal_csrf" value="#htmlEditFormat(VARIABLES.challengeMedalCsrf)#"/>
                    <input type="hidden" name="id_usuario" value="#VARIABLES.qCatarinenseRanking.id#"/>
                    <button class="btn btn-success btn-sm text-nowrap" type="submit"><i class="fa-solid fa-medal me-1"></i> Medalha entregue</button>
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
