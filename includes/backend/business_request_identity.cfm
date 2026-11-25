<!--- All Business entry points receive the same server-owned identity.
      Do not infer it from a client ID cookie or pre-verification cadastro sessions. --->
<cfif NOT structKeyExists(REQUEST,"businessIdentityInitialized")>
    <cfset REQUEST.businessIdentityInitialized = true/>
    <cfset REQUEST.businessAuthSession = createObject("component","services.BusinessAuthSession")/>
    <cfset REQUEST.businessRememberDevice = createObject("component","services.BusinessRememberDevice").init()/>
    <cfset REQUEST.businessRememberCookie = ""/>
    <cfif structKeyExists(COOKIE,REQUEST.businessRememberDevice.cookieName()) AND isSimpleValue(COOKIE[REQUEST.businessRememberDevice.cookieName()])>
        <cfset REQUEST.businessRememberCookie = COOKIE[REQUEST.businessRememberDevice.cookieName()]/>
    </cfif>
    <cfset REQUEST.businessIdentity = REQUEST.businessAuthSession.identity(SESSION)/>
    <cfif structKeyExists(REQUEST.businessIdentity,"id")
        OR listFindNoCase("/,/index.cfm,/home.cfm",CGI.script_name)
        OR left(CGI.script_name,10) EQ "/cadastro/">
        <cfheader name="Cache-Control" value="private, no-store"/>
    </cfif>
    <cfif structIsEmpty(REQUEST.businessIdentity)>
        <cfset structDelete(SESSION,"cadastroGoogleIdentity",false)/>
    </cfif>
    <cfif (structKeyExists(FORM,"action") AND isSimpleValue(FORM.action) AND FORM.action EQ "googlesignin")
        OR (structKeyExists(URL,"action") AND isSimpleValue(URL.action) AND URL.action EQ "googlesignin")>
        <cfif structKeyExists(SESSION,"businessSupportSession")>
            <cfheader statuscode="403"/><cfoutput><p>Encerre a sessão de suporte antes de trocar o login Google. <a href="/suporte/acesso/">Voltar ao administrador</a></p></cfoutput><cfabort/>
        </cfif>
        <cfinclude template="business_google_callback.cfm"/>
    </cfif>
    <cfinclude template="business_remember_request.cfm"/>
    <cfinclude template="business_support_request.cfm"/>
    <cfif NOT structKeyExists(SESSION,"businessLoginNonce")>
        <cfset SESSION.businessLoginNonce = lCase(hash(generateSecretKey("AES",256),"SHA-256"))/>
    </cfif>
    <cfif NOT structKeyExists(SESSION,"businessLoginCsrf")>
        <cfset SESSION.businessLoginCsrf = lCase(hash(generateSecretKey("AES",256),"SHA-256"))/>
    </cfif>
    <cfset REQUEST.businessDelegationIdentity=REQUEST.businessAuthSession.delegationIdentity(SESSION)/>
    <cfif structKeyExists(REQUEST,"businessSupportContext") AND NOT structIsEmpty(REQUEST.businessSupportContext) AND NOT REQUEST.businessSupportContext.ended>
        <cfset REQUEST.businessDelegationIdentity={id=REQUEST.businessIdentity.id,email=REQUEST.businessIdentity.email,emailVerified=REQUEST.businessIdentity.emailVerified,accessMode="DIRECT"}/>
    </cfif>
</cfif>
