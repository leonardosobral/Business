<!--- Revoke before clearing the authenticated session; also works after session expiry. --->
<cftry>
    <cfset REQUEST.businessRememberDevice.revoke(REQUEST.businessRememberCookie,
        structKeyExists(SESSION,"businessRememberSelector") ? SESSION.businessRememberSelector : "",
        structKeyExists(REQUEST.businessIdentity,"id") ? REQUEST.businessIdentity.id : 0)/>
    <cfcatch type="any">
        <cflog file="business_auth" type="error" text="Remembered login server revocation unavailable"/>
    </cfcatch>
</cftry>
<cfheader name="Set-Cookie" value="#REQUEST.businessRememberDevice.expireCookieHeader()#"/>
