<cfprocessingdirective pageencoding="utf-8"/>
<cfif NOT isDefined("verifiedContext") OR NOT isDefined("requireAdminAllowed") OR NOT requireAdminAllowed><cfheader statuscode="403"/><cfabort/></cfif>
<cfoutput>
<div class="verified-context">
    <details class="verified-context-section"><summary>Perfil e conta</summary>
        <cfif len(verifiedContext.profile.bio)><p class="verified-context-bio">#encodeForHTML(verifiedContext.profile.bio)#</p><p class="text-muted small">Bio informada pelo atleta; não é comprovação externa.</p><cfelse><p class="text-muted">Perfil sem bio.</p></cfif>
        <cfif len(verifiedContext.profile.instagram)><p>Instagram público: #encodeForHTML(verifiedContext.profile.instagram)#</p></cfif>
        <cfloop array="#verifiedContext.accounts#" index="accountItem"><p class="small">Conta #accountItem.user_id#<cfif len(accountItem.created_at ?: '')> · criada em #encodeForHTML(accountItem.created_at)#</cfif><cfif accountItem.is_partner> · Parceiro no cadastro</cfif><cfif accountItem.is_admin> · Administrador</cfif><cfif accountItem.is_dev> · Desenvolvedor</cfif><cfif len(accountItem.coaching)><br/>Assessoria informada: #encodeForHTML(accountItem.coaching)#</cfif></p></cfloop>
    </details>
    <div class="verified-context-section">
        <h4>Inscrições nos desafios (#arrayLen(verifiedContext.registrations)#)</h4>
        <cfif NOT arrayLen(verifiedContext.registrations)><p class="text-muted">Nenhuma inscrição encontrada nos cadastros atuais.</p></cfif>
        <cfloop array="#verifiedContext.registrations#" index="contextReg"><article class="verified-context-record">
            <strong>#encodeForHTML(contextReg.product_name)#</strong>
            <p><cfif contextReg.status EQ 'C'><span class="verified-pill">Confirmada no cadastro (C)</span><cfelse><span class="verified-pill is-attention">Sem confirmação (#encodeForHTML(len(contextReg.status) ? contextReg.status : 'sem status')#)</span></cfif></p>
            <p class="text-muted">Cadastro: #encodeForHTML(len(contextReg.registered_at) ? contextReg.registered_at : 'sem data')#<br/>#encodeForHTML(len(trim(contextReg.order_ref)) ? 'Referência: ' & contextReg.order_ref : 'Sem referência de pedido')#</p>
            <cfif len(contextReg.note)><p class="verified-pending">#encodeForHTML(contextReg.note)#</p></cfif>
            <small class="text-muted">#encodeForHTML(contextReg.challenge_code & ' / ' & contextReg.product_code)#</small>
        </article></cfloop>
        <p class="text-muted small">Confirmação no cadastro e data de inscrição não comprovam pagamento atual. A inscrição Básica não inclui selo.</p>
    </div>
    <details class="verified-context-section"><summary>Histórico legado CNA (#arrayLen(verifiedContext.legacy)#)</summary>
        <p class="text-muted small">Pode repetir inscrições acima. Registros antigos não comprovam VIP vigente no Todo Santo Dia.</p>
        <cfif NOT arrayLen(verifiedContext.legacy)><p class="text-muted">Nenhuma inscrição encontrada no legado.</p></cfif>
        <cfloop array="#verifiedContext.legacy#" index="contextReg"><article class="verified-context-record"><strong>#encodeForHTML(contextReg.product_name)#</strong><p><cfif contextReg.status EQ 'C'>Confirmada no cadastro (C)<cfelse>Sem confirmação (#encodeForHTML(len(contextReg.status) ? contextReg.status : 'sem status')#)</cfif><br/>#encodeForHTML(contextReg.registered_at)#<br/>#encodeForHTML(len(trim(contextReg.order_ref)) ? 'Referência: ' & contextReg.order_ref : 'Sem referência de pedido')#</p></article></cfloop>
    </details>
    <details class="verified-context-section verified-payments" <cfif structKeyExists(verifiedContext,'payment_totals') AND verifiedContext.payment_totals.unlinked_vip GT 0>open</cfif>><summary>Pagamentos e pedidos (#arrayLen(verifiedContext.payments)#)</summary>
        <cfif structKeyExists(verifiedContext,'payment_scan')>
            <div class="verified-scan"><strong>Conferido na API da Pagar.me</strong><p>#encodeForHTML(verifiedContext.payment_scan.verified_at)# · horário de Brasília.</p>
                <cfif NOT verifiedContext.payment_scan.complete><p class="verified-pending">Consulta incompleta. Há pedidos que ainda precisam ser conferidos.</p></cfif>
                <cfloop array="#verifiedContext.payment_scan.ambiguous_refs#" index="ambiguousRef"><p class="verified-pending">A referência #encodeForHTML(ambiguousRef.reference)# aparece em #ambiguousRef.orders_found# pedidos. Só os pedidos com vínculo individual foram associados ao perfil.</p></cfloop>
                <cfif structKeyExists(verifiedContext,'payment_totals')><p>#verifiedContext.payment_totals.approved# pedido(s) aprovado(s) na API · <strong>R$ #replace(numberFormat(verifiedContext.payment_totals.approved_cents/100,'0.00'),'.',',')#</strong></p><cfif verifiedContext.payment_totals.review GT 0><p class="verified-pending">#verifiedContext.payment_totals.review# pedido(s) com vínculo do comprador a revisar.</p></cfif><cfif verifiedContext.payment_totals.unlinked_vip GT 0><p class="verified-pending">#verifiedContext.payment_totals.unlinked_vip# pagamento(s) VIP/upgrade aprovado(s) ainda sem vínculo com o selo.</p></cfif></cfif>
            </div>
        </cfif>
        <p class="text-muted small">Todos os produtos encontrados nos pedidos, inclusive upgrade sem inscrição anterior. A consulta usa e-mail exato e referências individuais; outros e-mails sem vínculo podem não ser localizados. Eventos locais sem conferência na API ficam identificados.</p>
        <cfif NOT arrayLen(verifiedContext.payments)><p class="text-muted">Nenhum pedido localizado pelos vínculos consultados.</p></cfif>
        <cfloop array="#verifiedContext.payments#" index="contextPayment"><article class="verified-context-record verified-payment-record">
            <div class="verified-payment-heading"><strong>#encodeForHTML(contextPayment.product_name)#</strong><strong class="verified-payment-value"><cfif contextPayment.amount_known><cfif contextPayment.currency EQ 'BRL'>R$<cfelse>#encodeForHTML(contextPayment.currency)#</cfif> #replace(numberFormat(contextPayment.amount_cents/100,'0.00'),'.',',')#<cfelse>Valor indisponível</cfif></strong></div>
            <cfif contextPayment.provider_checked>
                <p><span class="verified-pill"><cfif contextPayment.classification EQ 'confirmed'>Aprovado na API<cfelseif contextPayment.classification EQ 'refunded_or_partial'>Estornado total ou parcialmente<cfelseif contextPayment.classification EQ 'chargeback'>Contestação / chargeback<cfelseif contextPayment.provider_status EQ 'failed'>Pagamento recusado<cfelseif contextPayment.provider_status EQ 'canceled'>Pedido cancelado<cfelse>Sem pagamento aprovado</cfif></span></p>
                <cfif contextPayment.classification EQ 'confirmed' AND contextPayment.badge_eligible><p class="verified-pending"><cfif contextPayment.link_conflict>Vínculo do comprador a revisar antes de conciliar.<cfelseif contextPayment.linked_to_badge>Pedido já vinculado ao selo.<cfelse>VIP/upgrade aprovado · ainda sem vínculo com o selo.</cfif><cfif contextPayment.upgrade_without_basic><br/>Upgrade sem pagamento da Básica localizado. A ausência de inscrição anterior não excluiu este pedido da conferência.</cfif></p></cfif>
                <cfif contextPayment.link_conflict><p class="verified-pending">O e-mail do comprador difere do cadastro ou há outro vínculo conflitante. Conferir a titularidade antes de associar este pagamento.</p></cfif>
                <dl class="verified-payment-facts"><dt>Pedido criado</dt><dd>#encodeForHTML(contextPayment.created_at)#</dd><dt>Pagamento</dt><dd>#encodeForHTML(len(contextPayment.paid_at) ? contextPayment.paid_at : 'Não confirmado')#</dd><dt>Meio</dt><dd>#encodeForHTML(replace(replace(replace(contextPayment.method,'credit_card','Cartão de crédito','all'),'pix','Pix','all'),'boleto','Boleto','all'))#</dd><cfif contextPayment.refunded_amount_cents GT 0><dt>Valor estornado</dt><dd>R$ #replace(numberFormat(contextPayment.refunded_amount_cents/100,'0.00'),'.',',')#</dd></cfif></dl>
                <small class="text-muted">Situação consultada em #encodeForHTML(contextPayment.verified_at)#. Não atualiza automaticamente ao abrir a tela.</small>
            <cfelse>
                <p><cfif contextPayment.reconciled_status EQ 'refunded'>Estorno conciliado<cfelseif contextPayment.reconciled_status EQ 'confirmed'>Pagamento conciliado<cfelseif contextPayment.cancellation_event>Há evento local de cancelamento<cfelseif contextPayment.paid_event>Há evento local de pagamento aprovado<cfelseif contextPayment.failed_event>Há evento local de falha no pagamento<cfelse>Pedido criado; sem aprovação registrada</cfif></p>
                <cfif contextPayment.cancellation_event AND contextPayment.paid_event><p class="verified-pending">Há eventos de pagamento e cancelamento. Revisar a situação atual.</p></cfif>
                <small class="text-muted">Registro local: #encodeForHTML(contextPayment.recorded_at)#<cfif len(contextPayment.reconciled_status)> · Conferência API registrada: #encodeForHTML(contextPayment.verified_at)#</cfif></small>
            </cfif>
            <p class="verified-order">#encodeForHTML(contextPayment.order_id)#</p>
        </article></cfloop>
    </details>
</div>
</cfoutput>
