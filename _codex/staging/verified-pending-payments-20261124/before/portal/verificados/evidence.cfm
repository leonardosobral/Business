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
    <details class="verified-context-section"><summary>Histórico financeiro disponível (#arrayLen(verifiedContext.payments)#)</summary>
        <p class="text-muted small">Eventos Pagar.me já registrados no sistema para estas contas e produtos de desafios. Esta tela não faz nova consulta à API; ausência de evento não comprova ausência de pagamento.</p>
        <cfif NOT arrayLen(verifiedContext.payments)><p class="text-muted">Nenhum evento financeiro localizado pelos vínculos consultados.</p></cfif>
        <cfloop array="#verifiedContext.payments#" index="contextPayment"><article class="verified-context-record"><strong>#encodeForHTML(contextPayment.product_name)#</strong>
            <p><cfif contextPayment.reconciled_status EQ 'refunded'>Estorno conciliado<cfelseif contextPayment.reconciled_status EQ 'confirmed'>Pagamento conciliado<cfelseif contextPayment.cancellation_event>Há evento de cancelamento<cfelseif contextPayment.paid_event>Há evento de pagamento aprovado<cfelseif contextPayment.failed_event>Há evento de falha no pagamento<cfelse>Pedido criado; sem aprovação registrada</cfif></p>
            <cfif contextPayment.cancellation_event AND contextPayment.paid_event><p class="verified-pending">Este pedido tem eventos de pagamento e cancelamento. Revisar a situação atual.</p></cfif>
            <p class="verified-order">#encodeForHTML(contextPayment.order_id)#</p><small class="text-muted">Último evento local: #encodeForHTML(contextPayment.recorded_at)#<cfif len(contextPayment.reconciled_status)> · Conferência API registrada: #encodeForHTML(contextPayment.verified_at)#</cfif></small>
        </article></cfloop>
    </details>
</div>
</cfoutput>
