<section class="card catarinense-ranking-card">
  <header class="card-header d-flex flex-wrap justify-content-between align-items-center gap-2 px-3 py-2">
    <div class="fw-bold"><i class="fa-solid <cfoutput>#VARIABLES.catarinenseRankingIcon#</cfoutput> me-2"></i><cfoutput>#VARIABLES.catarinenseRankingTitle#</cfoutput></div>
    <span class="badge badge-secondary"><cfoutput>#VARIABLES.qCatarinenseRanking.recordcount#</cfoutput> atleta(s)</span>
  </header>

  <cfif NOT VARIABLES.qCatarinenseRanking.recordcount>
    <div class="card-body text-muted">Nenhum atleta neste recorte.</div>
  <cfelse>
    <div class="small text-muted px-3 py-2"><cfif URL.aba EQ "ranking">Ordem de classificação após os desempates. Posições gerais preservadas ao filtrar; faixas indicam desempate ainda pendente.<cfelse>Confira a elegibilidade e confirme a entrega. O histórico de entregas é preservado.</cfif></div>
    <div class="table-responsive catarinense-table-scroll" role="region" aria-label="<cfoutput>#encodeForHTMLAttribute(VARIABLES.catarinenseRankingTitle)#</cfoutput>" tabindex="0">
      <table class="table table-hover table-sm catarinense-ranking-table mb-0">
        <thead>
          <tr>
            <cfif URL.aba EQ "ranking"><th class="text-center">Posição</th></cfif>
            <th class="catarinense-athlete">Atleta</th>
            <cfif URL.aba NEQ 'ranking'><th>Gênero</th></cfif>
            <cfif URL.aba EQ "ranking">
            <cfloop from="1" to="#VARIABLES.challengeCircuitTotalEvents#" index="VARIABLES.challengeStageIndex">
              <th class="stage-score" title="Etapa <cfoutput>#VARIABLES.challengeStageIndex#</cfoutput>">E<cfoutput>#VARIABLES.challengeStageIndex#</cfoutput></th>
            </cfloop>
            <th class="text-end" title="Soma das quatro melhores pontuações">Pontos</th>
            </cfif>
            <th class="text-center">Etapas</th>
            <th>Medalha</th>
            <th class="text-end">Ação</th>
          </tr>
        </thead>
        <tbody>
          <cfoutput query="qCatarinenseRanking" startrow="#VARIABLES.catarinenseStartRow#" maxrows="#VARIABLES.catarinensePageSize#">
            <cfset VARIABLES.catarinenseContact = {}/>
            <cfloop list="id,nome,imagem_usuario,email,ddi_usuario,ddd_usuario,telefone_usuario,instagram,whatsapp,tag,cidade,estado,equipe" index="VARIABLES.catarinenseContactField">
              <cfset VARIABLES.catarinenseContact[VARIABLES.catarinenseContactField] = ""/>
              <cfif listFindNoCase(VARIABLES.qCatarinenseRanking.columnList,VARIABLES.catarinenseContactField) AND NOT isNull(VARIABLES.qCatarinenseRanking[VARIABLES.catarinenseContactField][VARIABLES.qCatarinenseRanking.currentRow])>
                <cfset VARIABLES.catarinenseContact[VARIABLES.catarinenseContactField] = VARIABLES.qCatarinenseRanking[VARIABLES.catarinenseContactField][VARIABLES.qCatarinenseRanking.currentRow] & ""/>
              </cfif>
            </cfloop>
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
            <tr data-catarinense-athlete="#VARIABLES.qCatarinenseRanking.id#">
              <cfif URL.aba EQ "ranking"><td class="text-center fw-bold text-nowrap">
                <cfif VARIABLES.qCatarinenseRanking.ranking_posicao GT 0>
                  #VARIABLES.qCatarinenseRanking.ranking_posicao#<cfif VARIABLES.qCatarinenseRanking.ranking_fim GT VARIABLES.qCatarinenseRanking.ranking_posicao>–#VARIABLES.qCatarinenseRanking.ranking_fim#</cfif>
                <cfelse><span class="text-muted" title="Nenhuma etapa concluída">—</span></cfif>
              </td></cfif>
              <td class="catarinense-athlete">
                <div class="d-flex align-items-center gap-2">
                  <img class="rounded-circle catarinense-avatar" src="#encodeForHTMLAttribute(VARIABLES.qCatarinenseRanking.imagem_usuario)#" alt="" onerror="this.onerror=null;this.src='/assets/user.png';"/>
                  <div>
                    <div class="fw-semibold d-flex align-items-center justify-content-between gap-2">
                      <cfif len(trim(VARIABLES.qCatarinenseRanking.tag & ""))>
                        <a class="text-reset" href="https://roadrunners.run/atleta/#urlEncodedFormat(VARIABLES.qCatarinenseRanking.tag)#/" target="_blank" rel="noopener noreferrer">#encodeForHTML(VARIABLES.qCatarinenseRanking.nome)#</a>
                      <cfelse>
                        #encodeForHTML(VARIABLES.qCatarinenseRanking.nome)#
                      </cfif>
                      <button type="button" class="btn btn-sm catarinense-contact-button shadow-0" data-catarinense-contact="#encodeForHTMLAttribute(serializeJSON(VARIABLES.catarinenseContact))#" aria-haspopup="dialog" aria-controls="catarinenseContactDialog" aria-label="Contato de #encodeForHTMLAttribute(VARIABLES.qCatarinenseRanking.nome)#" title="Contato do atleta"><i class="fa-regular fa-address-card" aria-hidden="true"></i></button>
                    </div>
                    <div class="small text-muted">ID #VARIABLES.qCatarinenseRanking.id# · #encodeForHTML(VARIABLES.qCatarinenseRanking.cidade)#/#encodeForHTML(VARIABLES.qCatarinenseRanking.estado)#</div>
                    <cfif URL.aba EQ "ranking">
                      <details class="catarinense-tie-details">
                        <summary>Ver desempate · #encodeForHTML(catarinenseCriterionLabel(VARIABLES.qCatarinenseRanking.ranking_criterio))#</summary>
                        <cfif len(VARIABLES.qCatarinenseRanking.ranking_motivo)><p class="text-warning mt-2 mb-1">#encodeForHTML(VARIABLES.qCatarinenseRanking.ranking_motivo)#</p></cfif>
                        <dl>
                          <dt>Nascimento</dt><dd><cfif len(VARIABLES.qCatarinenseRanking.ranking_nascimento)>#mid(VARIABLES.qCatarinenseRanking.ranking_nascimento,9,2)#/#mid(VARIABLES.qCatarinenseRanking.ranking_nascimento,6,2)#/#left(VARIABLES.qCatarinenseRanking.ranking_nascimento,4)#<cfelse>Não informado ou inválido</cfif></dd>
                          <dt>Colocações por gênero, em todas as etapas</dt>
                          <dd><cftry><cfset VARIABLES.catarinensePlaces=deserializeJSON(VARIABLES.qCatarinenseRanking.colocacoes_json)/><cfcatch><cfset VARIABLES.catarinensePlaces=[]/></cfcatch></cftry><cfif arrayLen(VARIABLES.catarinensePlaces)><cfloop array="#VARIABLES.catarinensePlaces#" index="VARIABLES.catarinensePlaceIndex" item="VARIABLES.catarinensePlace">#numberFormat(VARIABLES.catarinensePlace,'9')#º<cfif VARIABLES.catarinensePlaceIndex LT arrayLen(VARIABLES.catarinensePlaces)>, </cfif></cfloop><cfelse>Sem colocação informada</cfif><cfif NOT val(VARIABLES.qCatarinenseRanking.colocacoes_completas)> · dados incompletos</cfif></dd>
                          <dt>Colocação na E6</dt><dd><cfif NOT val(VARIABLES.qCatarinenseRanking.ultima_completa)>Resultado sem colocação<cfelseif val(VARIABLES.qCatarinenseRanking.ultima_colocacao) GT 0>#numberFormat(VARIABLES.qCatarinenseRanking.ultima_colocacao,'9')#º<cfelse>Sem conclusão na E6</cfif></dd>
                          <dt>Média percentual de tempo</dt><dd><cfif val(VARIABLES.qCatarinenseRanking.desempenho_completo)>#numberFormat(val(VARIABLES.qCatarinenseRanking.media_percentual),'0.00')#%<cfelse>Referência ou tempo incompleto</cfif></dd>
                        </dl>
                      </details>
                    </cfif>
                  </div>
                </div>
              </td>
              <cfif URL.aba NEQ 'ranking'><td class="small text-nowrap">#encodeForHTML(VARIABLES.qCatarinenseRanking.genero EQ 'NAO INFORMADO' ? 'Não informado' : VARIABLES.qCatarinenseRanking.genero)#</td></cfif>
              <cfif URL.aba EQ "ranking">
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
              </cfif>
              <td class="text-center">#VARIABLES.qCatarinenseRanking.nodesafio#/#VARIABLES.challengeCircuitTotalEvents#</td>
              <td>
                <span class="badge #VARIABLES.challengeMedalStatusClass#">#VARIABLES.challengeMedalStatusLabel#</span>
                <cfif VARIABLES.qCatarinenseRanking.medalha_status EQ "entregue" AND len(trim(VARIABLES.qCatarinenseRanking.medalha_entregue_em & ""))>
                  <div class="small text-muted mt-1">#encodeForHTML(VARIABLES.qCatarinenseRanking.medalha_entregue_em)#</div>
                </cfif>
              </td>
              <td class="text-end">
                <cfif URL.aba EQ "ranking">
                  <a class="btn btn-outline-secondary btn-sm text-nowrap" href="#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{aba='medalhas',busca=VARIABLES.qCatarinenseRanking.nome,pagina=1}))#" title="Gerenciar medalha deste atleta"><i class="fa-solid fa-medal" aria-hidden="true"></i><span class="visually-hidden">Gerenciar medalha de #encodeForHTML(VARIABLES.qCatarinenseRanking.nome)#</span></a>
                <cfelseif VARIABLES.qCatarinenseRanking.medalha_status EQ "imediata">
                  <form method="post" class="d-inline" onsubmit="return confirm('Confirmar a entrega da medalha para este atleta?');">
                    <input type="hidden" name="challenge_action" value="entregar_medalha"/>
                    <input type="hidden" name="challenge_medal_csrf" value="#encodeForHTMLAttribute(VARIABLES.challengeMedalCsrf)#"/>
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
    <div class="catarinense-pagination">
      <div class="small text-muted"><cfoutput>#VARIABLES.catarinenseStartRow#–#VARIABLES.catarinenseEndRow# de #VARIABLES.qCatarinenseRanking.recordCount# atleta(s)</cfoutput></div>
      <nav class="d-flex align-items-center gap-2" aria-label="Paginação dos atletas">
        <cfif URL.pagina GT 1><a class="btn btn-outline-secondary btn-sm" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{pagina=URL.pagina-1}))#</cfoutput>">Anterior</a><cfelse><span class="btn btn-outline-secondary btn-sm disabled" aria-disabled="true">Anterior</span></cfif>
        <span class="small text-nowrap"><cfoutput>Página #URL.pagina# de #VARIABLES.catarinensePageCount#</cfoutput></span>
        <cfif URL.pagina LT VARIABLES.catarinensePageCount><a class="btn btn-outline-secondary btn-sm" href="<cfoutput>#encodeForHTMLAttribute(catarinensePanelUrl(VARIABLES.challengeTag,URL,{pagina=URL.pagina+1}))#</cfoutput>">Próxima</a><cfelse><span class="btn btn-outline-secondary btn-sm disabled" aria-disabled="true">Próxima</span></cfif>
      </nav>
    </div>
  </cfif>
</section>
<cfif VARIABLES.qCatarinenseRanking.recordcount><cfinclude template="catarinense_contact_modal.cfm"/></cfif>
