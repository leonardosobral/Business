<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfinclude template="../includes/backend/require_admin.cfm"/>
<cfif structKeyExists(REQUEST,"businessAccessContext") AND REQUEST.businessAccessContext.accessMode EQ "DELEGATED"><cfabort/></cfif>
<div class="tab-pane fade <cfif URL.sessao EQ 'fontes'>show active</cfif>" id="ex1-tabs-8" role="tabpanel" aria-labelledby="ex1-tab-8" tabindex="0">
    <h6>Fontes e revisões</h6>
    <p class="small text-muted">Conferência interna do cadastro. Consulte a fonte oficial e registre somente os dados que verificou. O registro não altera os dados do evento. A fonte das datas pode ser publicada em uma ação separada; local e situação permanecem internos.</p>
    <cfif len(VARIABLES.factReviewError)><div class="alert alert-danger" role="alert"><cfoutput>#encodeForHTML(VARIABLES.factReviewError)#</cfoutput></div></cfif>
    <cfif len(VARIABLES.factReviewPublication)><div class="alert alert-info" role="status"><cfoutput>#encodeForHTML(VARIABLES.factReviewPublication)#</cfoutput></div></cfif>
    <cfif VARIABLES.factReviewSaved><div class="alert alert-success" role="status">Conferência registrada com fonte, valores e horário de Brasília.</div></cfif>
    <cfif VARIABLES.factReviewRevoked><div class="alert alert-info" role="status">Conferência retirada. Seu registro original foi preservado.</div></cfif>
    <cfset VARIABLES.factReviewService=new services.EventFactReviewService()/>
    <cfif NOT VARIABLES.factReviewService.isSchemaReady()>
        <div class="alert alert-warning">A revisão de fontes estará disponível após a atualização do cadastro.</div>
    <cfelseif qEvento.recordCount>
        <cfset VARIABLES.factReviewData=VARIABLES.factReviewService.load(qEvento.id_evento,VARIABLES.requireAdminAllowed,false)/>
        <cfset VARIABLES.factReviewGroups=VARIABLES.factReviewService.groups()/>
        <cfset VARIABLES.factReviewLabels=VARIABLES.factReviewService.labels()/>
        <cfset VARIABLES.factReviewCsrfToken=csrfGenerateToken("event-fact-review")/>
        <cfloop list="datas,local,situacao" index="factGroup">
            <cfoutput>
            <details class="border rounded p-3 mb-3" <cfif factGroup EQ 'datas'>open</cfif>>
                <summary class="fw-bold">Conferir #encodeForHTML(lCase(VARIABLES.factReviewGroups[factGroup].label))#</summary>
                <cfif factGroup EQ 'datas'><p class="small text-muted mt-2">As datas de cada percurso precisam de conferência separada; este registro cobre somente início e término do evento.</p></cfif>
                <cfif factGroup EQ 'situacao'><p class="small text-muted mt-2">A disponibilidade de vagas é verificada na aba Inscrições.</p></cfif>
                <dl class="small mt-3 mb-3">
                <cfloop list="#VARIABLES.factReviewGroups[factGroup].fields#" index="factField">
                    <dt>#encodeForHTML(VARIABLES.factReviewLabels[factField])#</dt><dd class="text-break">#encodeForHTML(VARIABLES.factReviewService.displayValue(VARIABLES.factReviewData.snapshots[factGroup],factField))#</dd>
                </cfloop>
                </dl>
                <form method="post" id="fact-review-#factGroup#">
                    <label class="form-label" for="fact-source-#factGroup#">URL da fonte oficial</label>
                    <input class="form-control mb-2" type="url" id="fact-source-#factGroup#" name="source_url" maxlength="2048" required placeholder="https://"/>
                    <div class="form-check mb-3"><input type="checkbox" class="form-check-input" id="fact-confirmed-#factGroup#" name="confirmed" value="1" required/><label class="form-check-label" for="fact-confirmed-#factGroup#">Consultei a fonte agora e os valores exibidos acima correspondem ao que verifiquei.</label></div>
                    <input type="hidden" name="action" value="conferir_fatos_evento"/>
                    <input type="hidden" name="id_evento" value="#int(qEvento.id_evento)#"/>
                    <input type="hidden" name="grupo" value="#factGroup#"/>
                    <input type="hidden" name="version" value="#encodeForHTMLAttribute(VARIABLES.factReviewData.versions[factGroup])#"/>
                    <input type="hidden" name="request_id" value="#createObject('java','java.util.UUID').randomUUID().toString()#"/>
                    <input type="hidden" name="fact_csrf" value="#encodeForHTMLAttribute(VARIABLES.factReviewCsrfToken)#"/>
                    <button type="submit" class="btn btn-primary">Registrar conferência</button>
                </form>
            </details>
            </cfoutput>
        </cfloop>
        <h6 class="mt-4">Conferências registradas</h6>
        <p class="small text-muted">Últimas dez e a conferência mais recente de cada grupo. Somente a mais recente de cada grupo é considerada. Cadastro igual à conferência não garante que a fonte continue atualizada.</p>
        <cfset VARIABLES.factReviewSeen={}/>
        <cfset VARIABLES.factPublic={}/>
        <cfif len(VARIABLES.factReviewData.publicDateReview) AND isJSON(VARIABLES.factReviewData.publicDateReview)><cfset VARIABLES.factPublic=deserializeJSON(VARIABLES.factReviewData.publicDateReview)/></cfif>
        <cfif NOT VARIABLES.factReviewData.reviews.recordCount><p class="small">Nenhuma conferência registrada por este formulário.</p></cfif>
        <cfloop query="VARIABLES.factReviewData.reviews">
            <cfset factReviewRow=VARIABLES.factReviewData.reviews/>
            <cfset factReviewEarlier=NOT factReviewRow.is_latest/>
            <cfset VARIABLES.factReviewSeen[factReviewRow.grupo]=true/>
            <cfoutput>
            <details class="border rounded p-3 mb-2">
                <summary><strong>#encodeForHTML(VARIABLES.factReviewGroups[factReviewRow.grupo].label)#</strong> · #encodeForHTML(factReviewRow.revisado)# (Brasília)
                <cfif factReviewRow.revoked><span class="badge badge-secondary">Retirada</span>
                <cfelseif factReviewEarlier><span class="badge badge-secondary">Conferência anterior</span>
                <cfelseif factReviewRow.matches><span class="badge badge-success">Cadastro igual à conferência</span>
                <cfelse><span class="badge badge-warning">Cadastro alterado — rever fonte</span></cfif>
                </summary>
                <p class="small text-break mt-2">Fonte: <cfif new services.EventRegistrationAvailability().isSourceUrl(factReviewRow.fonte_url)><a href="#encodeForHTMLAttribute(factReviewRow.fonte_url)#" target="_blank" rel="noopener noreferrer">#encodeForHTML(factReviewRow.fonte_url)#</a><cfelse>#encodeForHTML(factReviewRow.fonte_url)#</cfif></p>
                <cfset factReviewSnapshot=deserializeJSON(factReviewRow.fatos)/>
                <dl class="small"><cfloop list="#VARIABLES.factReviewGroups[factReviewRow.grupo].fields#" index="factField"><dt>#encodeForHTML(VARIABLES.factReviewLabels[factField])#</dt><dd class="text-break">#encodeForHTML(VARIABLES.factReviewService.displayValue(factReviewSnapshot,factField))#</dd></cfloop></dl>
                <cfif factReviewRow.grupo EQ 'datas' AND NOT factReviewEarlier AND NOT factReviewRow.revoked>
                    <cfset factReviewIsPublic=isStruct(VARIABLES.factPublic) AND structKeyExists(VARIABLES.factPublic,'state') AND VARIABLES.factPublic.state EQ 'published' AND structKeyExists(VARIABLES.factPublic,'reviewId') AND VARIABLES.factPublic.reviewId EQ factReviewRow.id_revisao/>
                    <cfif factReviewIsPublic>
                        <p class="small"><cfif factReviewRow.matches>Fonte das datas publicada no RoadRunners.<cfelse>Publicação oculta: as datas do cadastro mudaram.</cfif></p>
                        <form method="post" class="mb-3"><input type="hidden" name="action" value="ocultar_datas_conferidas"/><input type="hidden" name="id_evento" value="#int(qEvento.id_evento)#"/><input type="hidden" name="id_revisao" value="#encodeForHTMLAttribute(factReviewRow.id_revisao)#"/><input type="hidden" name="fact_csrf" value="#encodeForHTMLAttribute(VARIABLES.factReviewCsrfToken)#"/><button class="btn btn-outline-secondary btn-sm" type="submit">Retirar publicação do site</button></form>
                    <cfelseif factReviewRow.matches>
                        <form method="post" class="mb-3">
                            <p class="small">O site mostrará início, término, link da fonte e data desta conferência. Horários e datas de cada percurso não fazem parte desta publicação.</p>
                            <div class="form-check mb-2"><input class="form-check-input" type="checkbox" id="fact-publish-#factReviewRow.id_revisao#" name="publish_confirmed" value="1" required/><label class="form-check-label" for="fact-publish-#factReviewRow.id_revisao#">Publicar esses dados e a fonte no RoadRunners.</label></div>
                            <input type="hidden" name="action" value="publicar_datas_conferidas"/><input type="hidden" name="id_evento" value="#int(qEvento.id_evento)#"/><input type="hidden" name="id_revisao" value="#encodeForHTMLAttribute(factReviewRow.id_revisao)#"/><input type="hidden" name="fact_csrf" value="#encodeForHTMLAttribute(VARIABLES.factReviewCsrfToken)#"/><button type="submit" class="btn btn-outline-primary btn-sm">Publicar fonte das datas</button>
                        </form>
                    </cfif>
                </cfif>
                <cfif NOT factReviewRow.revoked><form method="post"><input type="hidden" name="action" value="retirar_conferencia_evento"/><input type="hidden" name="id_evento" value="#int(qEvento.id_evento)#"/><input type="hidden" name="id_revisao" value="#encodeForHTMLAttribute(factReviewRow.id_revisao)#"/><input type="hidden" name="fact_csrf" value="#encodeForHTMLAttribute(VARIABLES.factReviewCsrfToken)#"/><button class="btn btn-outline-secondary btn-sm" type="submit">Retirar esta conferência</button></form></cfif>
            </details>
            </cfoutput>
        </cfloop>
        <details class="mt-4">
            <summary class="fw-bold">Alterações recentes do cadastro</summary>
            <p class="small text-muted mt-2">Últimos 20 registros, desde a implantação da captura em 04/10/2026. Uma alteração automática não comprova consulta à fonte.</p>
            <cfif NOT VARIABLES.factReviewData.history.recordCount><p class="small">Nenhuma alteração capturada para este evento.</p></cfif>
            <cfloop query="VARIABLES.factReviewData.history">
                <cfset factHistoryRow=VARIABLES.factReviewData.history/>
                <cfset factHistoryChanges=deserializeJSON(factHistoryRow.alteracoes)/>
                <cfset factHistoryOperations={INSERT="Inclusão",UPDATE="Alteração",DELETE="Exclusão"}/>
                <cfoutput><details class="border rounded p-2 mb-2"><summary>#encodeForHTML(factHistoryOperations[factHistoryRow.operacao])# de #encodeForHTML(factHistoryRow.entidade)# #encodeForHTML(factHistoryRow.id_entidade)# · #encodeForHTML(factHistoryRow.registrado)# (Brasília)</summary>
                    <cfloop collection="#factHistoryChanges#" item="factField"><cfif structKeyExists(VARIABLES.factReviewLabels,factField)><p class="small text-break mt-2 mb-1"><strong>#encodeForHTML(VARIABLES.factReviewLabels[factField])#:</strong><br/>Antes: #encodeForHTML(VARIABLES.factReviewService.displayValue(factHistoryChanges[factField],'antes'))#<br/>Depois: #encodeForHTML(VARIABLES.factReviewService.displayValue(factHistoryChanges[factField],'depois'))#</p></cfif></cfloop>
                </details></cfoutput>
            </cfloop>
        </details>
    </cfif>
</div>
