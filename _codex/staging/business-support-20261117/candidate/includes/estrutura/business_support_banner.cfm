<cfif structKeyExists(REQUEST,"businessSupportContext") AND NOT structIsEmpty(REQUEST.businessSupportContext) AND NOT REQUEST.businessSupportContext.ended AND NOT structKeyExists(REQUEST,"businessSupportBannerRendered")>
    <cfset REQUEST.businessSupportBannerRendered=true/>
    <style>
      body{padding-bottom:110px!important}.business-support-banner{position:fixed;bottom:12px;left:12px;right:12px;z-index:1090;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;padding:14px 18px;background:#fff3cd;color:#29230d;border:2px solid #e8aa19;border-radius:8px;box-shadow:0 4px 20px #0006;font:14px/1.4 system-ui,sans-serif}.business-support-banner form{margin:0}.business-support-banner button{padding:10px 14px;border:0;border-radius:5px;background:#29230d;color:#fff;font:inherit;font-weight:700;cursor:pointer}.business-support-banner small{display:block}
    </style>
    <aside class="business-support-banner" role="status" aria-label="Sessão de suporte">
        <cfoutput><div><strong>Você está acessando como #encodeForHTML(REQUEST.businessSupportContext.identity.name)#</strong><small>#encodeForHTML(REQUEST.businessSupportContext.identity.email)# · Sessão de suporte até #timeFormat(REQUEST.businessSupportContext.expiresAt,'HH:mm')# · Alterações afetam dados reais.</small></div>
        <form method="post" action="/suporte/acesso/"><input type="hidden" name="action" value="stop"><input type="hidden" name="csrf" value="#encodeForHTMLAttribute(REQUEST.businessSupportContext.stopToken)#"><button type="submit">Voltar ao administrador</button></form></cfoutput>
    </aside>
</cfif>
