<!--- Called only with a server-verified identity (Google callback or existing session). --->
<cftry>
    <cfset REQUEST.businessRememberDevice.revoke(REQUEST.businessRememberCookie)/>
    <cfset VARIABLES.businessRememberIssued = REQUEST.businessRememberDevice.issue(REQUEST.businessIdentity)/>
    <cfif NOT structIsEmpty(VARIABLES.businessRememberIssued)>
        <cfheader name="Set-Cookie" value="#REQUEST.businessRememberDevice.cookieHeader(VARIABLES.businessRememberIssued)#"/>
        <cfset SESSION.businessRememberSelector = VARIABLES.businessRememberIssued.selector/>
        <cfset SESSION.businessRememberCheckedAt = now()/>
    </cfif>
    <cfcatch type="any">
        <!--- Persistence unavailability must not reject a valid Google login. --->
        <cfset SESSION.businessRememberCheckedAt = now()/>
        <cflog file="business_auth" type="warning" text="Remembered login issuance unavailable; server session remains active"/>
    </cfcatch>
</cftry>
