<cfif getBaseTemplatePath() EQ getCurrentTemplatePath()><cfheader statuscode="404"><cfabort></cfif>
<cfscript>
if(!isDefined('brevoState')){brevoState={available=false,status='status_error'};}
batchStatus=structKeyExists(brevoState,'status')?brevoState.status:'unavailable';
hasBatch=structKeyExists(brevoState,'available') && brevoState.available;
hasAudience=hasBatch && structKeyExists(brevoState,'priority_audience');
buyersOnly=hasAudience && structKeyExists(brevoState,'challenge_buyers_only') && brevoState.challenge_buyers_only;
floripaOnly=hasAudience && structKeyExists(brevoState,'floripa_only') && brevoState.floripa_only;
buyerBatch=buyersOnly && !floripaOnly && structKeyExists(brevoState,'buyer_audience') && isStruct(brevoState.buyer_audience)
    && structKeyExists(brevoState.buyer_audience,'total') && structKeyExists(brevoState.buyer_audience,'desafio365')
    && structKeyExists(brevoState.buyer_audience,'todosantodia') && structKeyExists(brevoState.buyer_audience,'eligible');
floripaBatch=floripaOnly && !buyersOnly && structKeyExists(brevoState.priority_audience,'eligible_floripa');
hasBatchAudience=buyerBatch || floripaBatch;
hasWindow=hasBatch && structKeyExists(brevoState,'starts_at') && isDate(brevoState.starts_at) && structKeyExists(brevoState,'ends_at') && isDate(brevoState.ends_at);
canPrepare=hasBatchAudience && batchStatus=='draft';
canConfirm=hasBatchAudience && batchStatus=='prepared' && val(brevoState.selected)>0 && brevoConfig.configured && brevoState.stats_ready;
canCancel=hasBatch && listFind('draft,prepared,confirmed,syncing,validating',batchStatus)>0;
</cfscript>
<div class="border rounded p-3 mb-3">
    <h3 class="h6">Brevo · primeiro lote</h3>
    <cfoutput>
        <cfif hasWindow>
            <p>O envio pode começar em <strong>#dateFormat(brevoState.starts_at,'dd/mm/yyyy')# às #timeFormat(brevoState.starts_at,'HH:mm')#</strong>. A janela termina em #dateFormat(brevoState.ends_at,'dd/mm/yyyy')# às #timeFormat(brevoState.ends_at,'HH:mm')#, no horário de Brasília.</p>
        </cfif>
        <p><strong>Estado do lote</strong> · #encodeForHTML(structKeyExists(brevoLabels,batchStatus)?brevoLabels[batchStatus]:batchStatus)#<cfif hasBatch AND structKeyExists(brevoState,'selected')> · #int(brevoState.selected)# na revisão</cfif></p>
        <cfif hasAudience>
            <cfset audience=brevoState.priority_audience/>
            <section id="publico-selo" aria-labelledby="publico-selo-titulo" class="border-top pt-3 mb-3">
                <h4 id="publico-selo-titulo" class="h6">Primeiro lote · #buyersOnly?'Compradores dos desafios':'Maratona de Floripa'#</h4>
                <cfif buyerBatch>
                    <cfset buyers=brevoState.buyer_audience/>
                    <p>O lote considera até <strong>200 compradores</strong> com pagamento confirmado no Desafio365 ou no Todo Santo Dia.</p>
                    <p><strong>#lsNumberFormat(buyers.eligible,',0','pt_BR')# elegíveis para e-mail</strong> entre #lsNumberFormat(buyers.total,',0','pt_BR')# compradores únicos.</p>
                    <p>Compradores por desafio · Desafio365 (#lsNumberFormat(buyers.desafio365,',0','pt_BR')#) e Todo Santo Dia (#lsNumberFormat(buyers.todosantodia,',0','pt_BR')#).</p>
                <cfelseif floripaBatch>
                    <p>O lote considera até <strong>200 atletas</strong> com inscrição paga na Maratona de Floripa usando o cupom ROADRUNNERS.</p>
                    <p><strong>#lsNumberFormat(audience.eligible_floripa,',0','pt_BR')# elegíveis para e-mail</strong> entre #lsNumberFormat(audience.floripa,',0','pt_BR')# contas de Floripa.</p>
                <cfelse>
                    <p class="text-warning">A seleção de destinatários deste lote está indisponível no CRM.</p>
                </cfif>
                <cfif hasBatchAudience AND brevoState.eligible EQ 0 AND batchStatus EQ 'draft'>
                    <p>O atleta pode autorizar as ofertas em <a href="https://roadrunners.run/api/crm-interno/preferencias-email.cfm">Privacidade → Preferências de e-mail</a>, após entrar na conta Road Runners. O CRM também verifica atividade recente, bloqueios e frequência de contato.</p>
                </cfif>
                <h5 class="h6">Público salvo da oferta</h5>
                <p><strong>#lsNumberFormat(audience.total,',0','pt_BR')# contas únicas</strong> no público completo. Além dos atletas de Floripa, ele reúne #lsNumberFormat(audience.challenges_only,',0','pt_BR')# participantes dos desafios.</p>
                <p>O Desafio365 reúne #lsNumberFormat(audience.desafio365,',0','pt_BR')# contas e o Todo Santo Dia, #lsNumberFormat(audience.todosantodia,',0','pt_BR')#. Uma mesma conta pode constar em mais de um grupo.</p>
                <cfif NOT brevoPageRequested>
                    <a class="btn btn-outline-secondary btn-sm" href="/emailmkt/?pagina_publico=1##publico-selo">Ver participantes</a>
                <cfelseif NOT structKeyExists(brevoMembersPage,'members')>
                    <p role="status" class="text-warning">A consulta de participantes está indisponível. <a href="/emailmkt/?pagina_publico=1##publico-selo">Tentar novamente</a></p>
                <cfelseif NOT arrayLen(brevoMembersPage.members)>
                    <p>Nenhum participante neste público.</p>
                <cfelse>
                    <div class="table-responsive">
                        <table class="table table-sm">
                            <caption class="visually-hidden">Participantes do público salvo da oferta, em ordem de prioridade</caption>
                            <thead><tr><th scope="col">Conta</th><th scope="col">Origem</th></tr></thead>
                            <tbody><cfloop array="#brevoMembersPage.members#" item="brevoMember">
                                <cfset brevoSources=[]/>
                                <cfif brevoMember.floripa><cfset arrayAppend(brevoSources,'Maratona de Floripa')/></cfif>
                                <cfif brevoMember.desafio365><cfset arrayAppend(brevoSources,'Desafio365')/></cfif>
                                <cfif brevoMember.todosantodia><cfset arrayAppend(brevoSources,'Todo Santo Dia')/></cfif>
                                <tr><td class="text-break">#encodeForHTML(brevoMember.name)# <small class="text-body-secondary">ID #int(brevoMember.user_id)#</small></td><td>#arrayToList(brevoSources,', ')#</td></tr>
                            </cfloop></tbody>
                        </table>
                    </div>
                    <nav aria-label="Páginas dos participantes" class="d-flex flex-wrap gap-3 align-items-center">
                        <cfif brevoMembersPage.page GT 1><a href="/emailmkt/?pagina_publico=#int(brevoMembersPage.page)-1###publico-selo">Anterior</a></cfif>
                        <span>Página #int(brevoMembersPage.page)# de #int(brevoMembersPage.total_pages)#</span>
                        <cfif brevoMembersPage.page LT brevoMembersPage.total_pages><a href="/emailmkt/?pagina_publico=#int(brevoMembersPage.page)+1###publico-selo">Próxima</a></cfif>
                        <a href="/emailmkt/##publico-selo">Ocultar participantes</a>
                    </nav>
                </cfif>
            </section>
        <cfelseif hasBatch>
            <p class="text-warning">O público da oferta ainda está indisponível no CRM.</p>
        </cfif>
        <cfif structKeyExists(brevoState,'campaign_id') AND val(brevoState.campaign_id) GT 0><p>Campanha Brevo ## #val(brevoState.campaign_id)#</p></cfif>
        <cfif hasBatch>
            <p><cfif hasBatchAudience>#int(brevoState.eligible)# disponíveis para este lote · </cfif>#int(brevoState.excluded)# excluídos do lote · #int(brevoState.accepted)# aceitos pela Brevo</p>
            <cfif !brevoState.stats_ready><p class="text-warning">Aplique a migração de eventos para acompanhar entregas e descadastros antes de confirmar.</p></cfif>
            <cfif structKeyExists(brevoState,'stats') AND structKeyExists(brevoState.stats,'delivered')>
                <dl class="d-flex flex-wrap gap-3">
                    <cfloop array="#[['delivered','Entregues'],['opened','Aberturas únicas'],['clicked','Cliques únicos'],['soft_bounced','Falhas temporárias'],['hard_bounced','Falhas permanentes'],['unsubscribed','Descadastros'],['complaints','Queixas de spam']]#" item="metric">
                        <div><dt>#metric[2]#</dt><dd>#int(brevoState.stats[metric[1]])#</dd></div>
                    </cfloop>
                </dl>
            </cfif>
            <cfif batchStatus EQ 'unknown'><p class="text-warning">Consulte o histórico da campanha e da lista na Brevo. O processamento automático deste lote foi interrompido.</p></cfif>
        </cfif>
        <cfif NOT structIsEmpty(brevoNotice)><p role="status" class="#brevoNotice.ok?'text-success':'text-warning'#">#encodeForHTML(brevoNotice.text)#</p></cfif>
        <form method="post" action="/emailmkt/" class="d-flex flex-wrap gap-2 align-items-center">
            <input type="hidden" name="brevoCsrf" value="#encodeForHTMLAttribute(SESSION.brevoBatchCsrf)#"/>
            <button class="btn btn-outline-secondary" name="brevoAction" value="prepare" <cfif NOT canPrepare>disabled</cfif>>Preparar destinatários</button>
            <button class="btn btn-warning text-dark" name="brevoAction" value="confirm" <cfif NOT canConfirm>disabled</cfif>>Confirmar envio deste lote</button>
            <cfif canCancel AND batchStatus NEQ 'draft'><button class="btn btn-link" name="brevoAction" value="cancel">Cancelar lote</button></cfif>
        </form>
    </cfoutput>
    <details class="mt-3"<cfif NOT brevoConfig.configured> open</cfif>>
        <summary>Configuração da Brevo</summary>
        <p class="mt-2 mb-2">Na conta Brevo, autentique o domínio, verifique o remetente e crie uma pasta para as listas da campanha.</p>
        <cfif NOT brevoConfig.configured><p>Configuração privada pendente no Business · <cfoutput>#encodeForHTML(arrayToList(brevoConfig.missing,', '))#</cfoutput></p></cfif>
        <form method="post" action="/emailmkt/" class="d-flex flex-wrap gap-2">
            <input type="hidden" name="brevoCsrf" value="<cfoutput>#encodeForHTMLAttribute(SESSION.brevoBatchCsrf)#</cfoutput>"/>
            <button class="btn btn-outline-secondary" name="brevoAction" value="webhook" <cfif NOT brevoConfig.configured>disabled</cfif>>Registrar webhook</button>
            <button class="btn btn-outline-secondary" name="brevoAction" value="check" <cfif NOT brevoConfig.configured>disabled</cfif>>Verificar conexão</button>
        </form>
    </details>
</div>
