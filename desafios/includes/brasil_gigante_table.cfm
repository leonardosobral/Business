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
              <th class="cbg-stage-result" title="<cfoutput>#encodeForHTMLAttribute(VARIABLES.challengeCircuitEvent.nome)#</cfoutput>"><cfoutput>#VARIABLES.challengeCircuitEvent.sigla#</cfoutput></th>
            </cfloop>
            <th class="text-center">Etapas</th>
            <th>Mandala</th>
            <th class="text-end">Ação</th>
          </tr>
        </thead>
        <tbody>
          <cfoutput query="qBrasilGiganteRanking">
            <cfset VARIABLES.brasilGiganteContact = {}/>
            <cfloop list="id,nome,imagem_usuario,email,ddi_usuario,ddd_usuario,telefone_usuario,instagram,whatsapp,tag,cidade,estado,equipe" index="VARIABLES.brasilGiganteContactField">
              <cfset VARIABLES.brasilGiganteContact[VARIABLES.brasilGiganteContactField] = ""/>
              <cfif listFindNoCase(qBrasilGiganteRanking.columnList,VARIABLES.brasilGiganteContactField) AND NOT isNull(qBrasilGiganteRanking[VARIABLES.brasilGiganteContactField][qBrasilGiganteRanking.currentRow])>
                <cfset VARIABLES.brasilGiganteContact[VARIABLES.brasilGiganteContactField] = qBrasilGiganteRanking[VARIABLES.brasilGiganteContactField][qBrasilGiganteRanking.currentRow] & ""/>
              </cfif>
            </cfloop>
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
                  <img class="rounded-circle cbg-dashboard-avatar" src="#encodeForHTMLAttribute(qBrasilGiganteRanking.imagem_usuario)#" alt="" onerror="this.onerror=null;this.src='/assets/user.png';"/>
                  <div>
                    <div class="fw-semibold d-flex align-items-center justify-content-between gap-2">
                      <cfif len(trim(qBrasilGiganteRanking.tag & ""))>
                        <a class="text-reset" href="https://roadrunners.run/atleta/#urlEncodedFormat(qBrasilGiganteRanking.tag)#/" target="_blank" rel="noopener noreferrer">#encodeForHTML(qBrasilGiganteRanking.nome)#</a>
                      <cfelse>
                        #encodeForHTML(qBrasilGiganteRanking.nome)#
                      </cfif>
                      <button type="button" class="btn btn-sm catarinense-contact-button shadow-0" data-catarinense-contact="#encodeForHTMLAttribute(serializeJSON(VARIABLES.brasilGiganteContact))#" aria-haspopup="dialog" aria-controls="catarinenseContactDialog" aria-label="Contato de #encodeForHTMLAttribute(qBrasilGiganteRanking.nome)#" title="Contato do atleta"><i class="fa-regular fa-address-card" aria-hidden="true"></i></button>
                    </div>
                    <div class="small text-muted">
                      ID #qBrasilGiganteRanking.id#<cfif len(trim(qBrasilGiganteRanking.cidade & "")) OR len(trim(qBrasilGiganteRanking.estado & ""))> · #encodeForHTML(qBrasilGiganteRanking.cidade)#<cfif len(trim(qBrasilGiganteRanking.cidade & "")) AND len(trim(qBrasilGiganteRanking.estado & ""))>/</cfif>#encodeForHTML(qBrasilGiganteRanking.estado)#</cfif>
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
                <cfif len(trim(qBrasilGiganteRanking.mandala_numero & ''))>
                  <div class="small fw-semibold mt-1">Mandala nº #encodeForHTML(qBrasilGiganteRanking.mandala_numero)#</div>
                <cfelseif qBrasilGiganteRanking.mandala_status EQ 'entregue'>
                  <div class="small text-warning mt-1">Número não informado</div>
                </cfif>
                <cfif qBrasilGiganteRanking.mandala_status EQ "entregue" AND len(trim(qBrasilGiganteRanking.mandala_entregue_em & ""))>
                  <div class="small text-muted mt-1"><cfif isDate(qBrasilGiganteRanking.mandala_entregue_em)>#dateFormat(qBrasilGiganteRanking.mandala_entregue_em, "dd/mm/yyyy")# #timeFormat(qBrasilGiganteRanking.mandala_entregue_em, "HH:mm")#<cfelse>#encodeForHTML(qBrasilGiganteRanking.mandala_entregue_em)#</cfif></div>
                </cfif>
              </td>
              <td class="text-end">
                <cfif listFindNoCase("proxima_etapa,imediata", qBrasilGiganteRanking.mandala_status) OR (qBrasilGiganteRanking.mandala_status EQ 'entregue' AND NOT len(trim(qBrasilGiganteRanking.mandala_numero & '')))>
                  <cfset VARIABLES.cbgMandalaSelected=len(VARIABLES.challengeMandalaError) AND val(FORM.id_usuario ?: 0) EQ qBrasilGiganteRanking.id/>
                  <details class="text-start" <cfif VARIABLES.cbgMandalaSelected>open</cfif>>
                  <summary class="btn btn-success btn-sm text-nowrap"><i class="fa-solid fa-award me-1" aria-hidden="true"></i> <cfif qBrasilGiganteRanking.mandala_status EQ 'entregue'>Informar número<cfelse>Mandala entregue</cfif></summary>
                  <form method="post" class="border rounded p-2 mt-2" style="min-width:220px;max-width:280px;white-space:normal;">
                    <input type="hidden" name="challenge_action" value="entregar_mandala"/>
                    <input type="hidden" name="challenge_medal_csrf" value="#encodeForHTMLAttribute(VARIABLES.challengeMedalCsrf)#"/>
                    <input type="hidden" name="id_usuario" value="#qBrasilGiganteRanking.id#"/>
                    <div class="small fw-semibold mb-2">#encodeForHTML(qBrasilGiganteRanking.nome)#</div>
                    <label class="small d-block">Número gravado na mandala
                      <input class="form-control form-control-sm mt-1" type="text" name="mandala_numero" inputmode="numeric" pattern="[0-9]{1,12}" maxlength="12" autocomplete="off" required placeholder="Ex.: 00123" value="<cfif VARIABLES.cbgMandalaSelected>#encodeForHTMLAttribute(FORM.mandala_numero ?: '')#</cfif>"/>
                    </label>
                    <label class="small d-flex align-items-start gap-2 my-2"><input type="checkbox" name="confirmar_mandala" value="1" required class="mt-1"/> Conferi o número da mandala entregue a este atleta.</label>
                    <button class="btn btn-warning btn-sm" type="submit"><cfif qBrasilGiganteRanking.mandala_status EQ 'entregue'>Salvar número<cfelse>Confirmar entrega</cfif></button>
                  </form>
                  </details>
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
<cfif qBrasilGiganteRanking.recordcount><cfinclude template="catarinense_contact_modal.cfm"/></cfif>
