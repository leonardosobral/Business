<cfprocessingdirective pageencoding="utf-8"/>
<!doctype html>
<html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Convite de acesso | RunnerHub</title>
<style>body{font:1rem/1.55 system-ui,sans-serif;max-width:40rem;margin:3rem auto;padding:0 1rem;background:#181818;color:#f7f7f7}main{background:#272727;border:1px solid #666;border-radius:.7rem;padding:1.5rem}a{color:#ffd06a}button{font:inherit;cursor:pointer;border:1px solid #ffd06a;border-radius:.4rem;background:#ffd06a;color:#181818;padding:.65rem 1rem;margin:.4rem .4rem .4rem 0}button[name=action][value=reject]{background:transparent;color:#f7f7f7;border-color:#aaa}button:focus-visible,a:focus-visible{outline:3px solid #ffd06a;outline-offset:3px}.muted{color:#ddd}</style></head><body><main>
<h1>Convite de acesso</h1>
<cfif len(VARIABLES.inviteMessage)><p role="alert"><cfoutput>#encodeForHTML(VARIABLES.inviteMessage)#</cfoutput></p></cfif>
<cfif NOT structIsEmpty(VARIABLES.inviteProjection) AND VARIABLES.inviteHttpStatus EQ 200>
    <cfoutput><p><cfif VARIABLES.inviteProjection.type EQ 'TITULAR'>Você recebeu um convite para confirmar a titularidade da conta. Se a conta ainda estiver pendente, a ativação dependerá de aprovação interna.<cfelseif VARIABLES.inviteProjection.type EQ 'AMPLIACAO'>Foi proposta uma ampliação do acesso da gestora à conta.<cfelse>Foi proposta uma relação de gestão entre contas.</cfif></p>
    <p><strong>Conta cliente:</strong> #encodeForHTML(VARIABLES.inviteProjection.clientAccountName)# (ID #encodeForHTML(VARIABLES.inviteProjection.clientAccountId)#)</p>
    <p><strong>Gestora vinculada:</strong> #encodeForHTML(VARIABLES.inviteProjection.managerAccountName)#</p>
    <p><strong>Situação da conta cliente:</strong> #encodeForHTML(VARIABLES.inviteProjection.clientAccountStatus)#</p>
    <cfif VARIABLES.inviteProjection.clientAccountStatus EQ 'PENDENTE'><p role="note">Aceitar este convite não ativa a conta. A ativação ainda depende de aprovação interna.</p></cfif>
    <cfif structKeyExists(VARIABLES.inviteProjection,'capabilities')><p class="muted">Permissões propostas: #encodeForHTML(arrayToList(VARIABLES.inviteProjection.capabilities,', '))#</p></cfif>
    <p class="muted">Este convite vence em #encodeForHTML(dateTimeFormat(VARIABLES.inviteProjection.expiresAt,'dd/mm/yyyy HH:nn'))#.</p>
    <form method="post" action="/convites/">
        <input type="hidden" name="token" value="#encodeForHTMLAttribute(VARIABLES.inviteReturn.pendingToken(SESSION))#">
        <input type="hidden" name="invite_csrf" value="#encodeForHTMLAttribute(SESSION.businessInviteCsrf)#">
        <input type="hidden" name="expectedVersion" value="#encodeForHTMLAttribute(VARIABLES.inviteProjection.type EQ 'TITULAR'?VARIABLES.inviteProjection.version:VARIABLES.inviteProjection.relationshipVersion)#">
        </cfoutput>
        <cfinclude template="../includes/parts/business_delegation_form.cfm"/>
        <button type="submit" name="action" value="accept">Aceitar convite</button>
        <button type="submit" name="action" value="reject">Recusar convite</button>
    </form>
</cfif>
<p><a href="/">Voltar ao início</a></p>
</main></body></html>
