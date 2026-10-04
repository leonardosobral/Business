<cfif structKeyExists(REQUEST,"businessDelegationEnabled") AND (REQUEST.businessDelegationEnabled OR REQUEST.businessAccessInvalid)>
    <cfif NOT structKeyExists(REQUEST.businessDelegationIdentity,"id")><cflocation url="/" addtoken="false"/></cfif>
    <cfset VARIABLES.businessSelectionOptions=REQUEST.businessDelegationService.listAccess(REQUEST.businessDelegationIdentity)/>
    <cfset VARIABLES.businessSelectionFields=REQUEST.businessRequestBoundary.selectionFields(SESSION)/>
    <cfset VARIABLES.businessSelectionActor=createObject("component","services.accountDelegation.Store").init("runnerhub").actor(REQUEST.businessDelegationIdentity.id)/>
    <cfif structKeyExists(VARIABLES.businessSelectionActor,"is_admin") AND VARIABLES.businessSelectionActor.is_admin>
        <cfset arrayPrepend(VARIABLES.businessSelectionOptions,{selection={accountId=0,accessMode="DIRECT",managerAccountId=0,relationshipId=0},accountName="Administração RunnerHub",managerName="",roleLabel="Acesso interno sem simulação"})/>
    </cfif>
    <cfcontent type="text/html; charset=utf-8"/><cfprocessingdirective pageencoding="utf-8"/>
    <!doctype html><html lang="pt-br"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Escolher conta</title>
    <style>body{font:1rem system-ui,sans-serif;max-width:56rem;margin:2rem auto;padding:0 1rem;background:#181818;color:#f7f7f7}a{color:#ffd06a}.account-options{display:grid;grid-template-columns:repeat(auto-fit,minmax(16rem,1fr));gap:1rem}form{margin:0}button{width:100%;height:100%;text-align:left;background:#292929;color:inherit;border:1px solid #777;border-radius:.5rem;padding:1rem;font:inherit;cursor:pointer}button:focus-visible{outline:3px solid #ffd06a;outline-offset:3px}strong,small{display:block;margin:.2rem 0}small{line-height:1.5}</style></head><body><main>
    <h1>Escolher conta e acesso</h1>
    <cfif REQUEST.businessAccessInvalid><p role="alert">O acesso anterior não está disponível. Escolha novamente para continuar.</p></cfif>
    <p>As permissões pertencem ao acesso escolhido. Você pode trocar de conta a qualquer momento.</p>
    <div class="account-options">
    <cfoutput><cfloop array="#VARIABLES.businessSelectionOptions#" index="businessSelectionOption">
        <form method="post" action="/selecionar-conta/">
            <cfloop collection="#VARIABLES.businessSelectionFields#" item="businessSelectionKey"><input type="hidden" name="#encodeForHTMLAttribute(businessSelectionKey)#" value="#encodeForHTMLAttribute(VARIABLES.businessSelectionFields[businessSelectionKey])#"></cfloop>
            <cfloop collection="#businessSelectionOption.selection#" item="businessSelectionKey"><input type="hidden" name="#encodeForHTMLAttribute(businessSelectionKey)#" value="#encodeForHTMLAttribute(businessSelectionOption.selection[businessSelectionKey])#"></cfloop>
            <button type="submit"><strong>#encodeForHTML(businessSelectionOption.accountName)#</strong>
            <small><cfif businessSelectionOption.selection.accessMode EQ "DELEGATED">Via #encodeForHTML(businessSelectionOption.managerName)#<cfelseif businessSelectionOption.selection.accessMode EQ "INTERNAL_SIMULATION">Simulação interna<cfelse>Acesso direto</cfif> · #encodeForHTML(businessSelectionOption.roleLabel)#</small></button>
        </form>
    </cfloop></cfoutput>
    </div>
    <cfif NOT arrayLen(VARIABLES.businessSelectionOptions)><p>Nenhuma conta está disponível para este usuário.</p></cfif>
    <p><a href="/logout.cfm">Sair</a></p>
    </main></body></html>
    <cfexit method="exittemplate"/>
</cfif>
<!DOCTYPE html>
<html lang="pt-br">
<cfprocessingdirective pageencoding="utf-8"/>

<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/selecionar-conta/"/>
<cfinclude template="../includes/backend/backend_login.cfm"/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount>
  <cflocation addtoken="false" url="/"/>
</cfif>
<cfif NOT isDefined("VARIABLES.businessAccountSelectionRequired") OR NOT VARIABLES.businessAccountSelectionRequired>
  <cflocation addtoken="false" url="/"/>
</cfif>

<cfset VARIABLES.businessAccountModalForcedRedirect = "/"/>
<cfif isDefined("URL.redirect")>
  <cfset VARIABLES.businessAccountSelectionRequestedRedirect = trim(URL.redirect & "")/>
  <cfif len(VARIABLES.businessAccountSelectionRequestedRedirect)
      AND left(VARIABLES.businessAccountSelectionRequestedRedirect, 1) EQ "/"
      AND left(VARIABLES.businessAccountSelectionRequestedRedirect, 2) NEQ "//"
      AND NOT find("\", VARIABLES.businessAccountSelectionRequestedRedirect)
      AND NOT find(chr(10), VARIABLES.businessAccountSelectionRequestedRedirect)
      AND NOT find(chr(13), VARIABLES.businessAccountSelectionRequestedRedirect)
      AND NOT findNoCase("/selecionar-conta/", VARIABLES.businessAccountSelectionRequestedRedirect)>
    <cfset VARIABLES.businessAccountModalForcedRedirect = VARIABLES.businessAccountSelectionRequestedRedirect/>
  </cfif>
</cfif>

<cfinclude template="../includes/estrutura/head.cfm"/>
<body data-mdb-theme="dark" class="bg-dark-subtle">
  <main class="min-vh-100"></main>
  <cfset VARIABLES.businessAccountModalRequired = true/>
  <cfinclude template="../includes/estrutura/account_context_modal.cfm"/>
  <cfinclude template="../includes/estrutura/footer.cfm"/>
</body>
</html>
