<!--- All Business entry points receive the same server-owned identity.
      Do not infer it from a client ID cookie or pre-verification cadastro sessions. --->
<cfif NOT structKeyExists(REQUEST,"businessIdentityInitialized")>
    <cfset REQUEST.businessIdentityInitialized = true/>
    <cfset REQUEST.businessAuthSession = createObject("component","services.BusinessAuthSession")/>
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
        <cfinclude template="business_google_callback.cfm"/>
    </cfif>
    <cfif NOT structKeyExists(SESSION,"businessLoginNonce")>
        <cfset SESSION.businessLoginNonce = lCase(hash(generateSecretKey("AES",256),"SHA-256"))/>
    </cfif>
    <cfif NOT structKeyExists(SESSION,"businessLoginCsrf")>
        <cfset SESSION.businessLoginCsrf = lCase(hash(generateSecretKey("AES",256),"SHA-256"))/>
    </cfif>
</cfif>
