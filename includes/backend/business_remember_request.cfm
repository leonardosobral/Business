<cfset VARIABLES.businessRememberSuppressed = CGI.script_name EQ "/logout.cfm"
    OR (structKeyExists(URL,"logout") AND isSimpleValue(URL.logout) AND URL.logout EQ "1")
    OR (structKeyExists(URL,"action") AND isSimpleValue(URL.action) AND URL.action EQ "googlesignout")
    OR (structKeyExists(FORM,"acao") AND isSimpleValue(FORM.acao) AND FORM.acao EQ "trocar_conta_google")
    OR (structKeyExists(COOKIE,"rr_logged_out") AND isSimpleValue(COOKIE.rr_logged_out) AND COOKIE.rr_logged_out EQ "1")/>
<cfif NOT VARIABLES.businessRememberSuppressed
    AND (NOT structKeyExists(SESSION,"businessRememberCheckedAt") OR NOT isDate(SESSION.businessRememberCheckedAt)
        OR dateDiff("s",SESSION.businessRememberCheckedAt,now()) GTE 300)>
    <cflock scope="session" type="exclusive" timeout="5">
        <cfset REQUEST.businessIdentity = REQUEST.businessAuthSession.identity(SESSION)/>
        <cfif NOT structKeyExists(SESSION,"businessRememberCheckedAt") OR NOT isDate(SESSION.businessRememberCheckedAt)
            OR dateDiff("s",SESSION.businessRememberCheckedAt,now()) GTE 300>
            <cfif len(REQUEST.businessRememberCookie)>
                <cftry>
                    <cfset VARIABLES.businessRememberRestored = REQUEST.businessRememberDevice.restore(
                        REQUEST.businessRememberCookie,structIsEmpty(REQUEST.businessIdentity))/>
                    <cfif NOT structIsEmpty(VARIABLES.businessRememberRestored)
                        AND (structIsEmpty(REQUEST.businessIdentity) OR REQUEST.businessIdentity.id EQ VARIABLES.businessRememberRestored.identity.id)>
                        <cfif structIsEmpty(REQUEST.businessIdentity)>
                            <cfset sessionRotate()/>
                            <cfset REQUEST.businessAuthSession.establish(SESSION,VARIABLES.businessRememberRestored.identity.id,{
                                sub=VARIABLES.businessRememberRestored.identity.sub,email=VARIABLES.businessRememberRestored.identity.email,
                                name=VARIABLES.businessRememberRestored.identity.name,picture=VARIABLES.businessRememberRestored.identity.imagem_usuario})/>
                        </cfif>
                        <cfset REQUEST.businessIdentity = REQUEST.businessAuthSession.identity(SESSION)/>
                        <cfset SESSION.businessRememberSelector = VARIABLES.businessRememberRestored.selector/>
                        <cfif len(VARIABLES.businessRememberRestored.cookieValue)>
                            <cfheader name="Set-Cookie" value="#REQUEST.businessRememberDevice.cookieHeader(VARIABLES.businessRememberRestored)#"/>
                        </cfif>
                        <cfheader name="Cache-Control" value="private, no-store"/>
                    <cfelse>
                        <cfif structKeyExists(SESSION,"businessRememberSelector")>
                            <cfset REQUEST.businessAuthSession.clear(SESSION)/>
                            <cfset REQUEST.businessIdentity = {}/>
                            <cfset sessionRotate()/>
                        </cfif>
                        <cfheader name="Set-Cookie" value="#REQUEST.businessRememberDevice.expireCookieHeader()#"/>
                    </cfif>
                    <cfcatch type="any">
                        <!--- Do not restore an anonymous session when persistence is unavailable. --->
                        <cflog file="business_auth" type="warning" text="Remembered login validation unavailable"/>
                    </cfcatch>
                </cftry>
                <cfset SESSION.businessRememberCheckedAt = now()/>
            <cfelseif NOT structIsEmpty(REQUEST.businessIdentity) AND structKeyExists(SESSION,"businessRememberSelector")>
                <cftry>
                    <cfif NOT REQUEST.businessRememberDevice.isActive(SESSION.businessRememberSelector,REQUEST.businessIdentity.id)>
                        <cfset REQUEST.businessAuthSession.clear(SESSION)/>
                        <cfset REQUEST.businessIdentity = {}/>
                        <cfset sessionRotate()/>
                    </cfif>
                    <cfcatch type="any">
                        <cflog file="business_auth" type="warning" text="Remembered login validation unavailable"/>
                    </cfcatch>
                </cftry>
                <cfset SESSION.businessRememberCheckedAt = now()/>
            <cfelseif NOT structIsEmpty(REQUEST.businessIdentity)>
                <!--- Upgrade existing verified logins without another Google round trip. --->
                <cfinclude template="business_remember_issue.cfm"/>
            </cfif>
        </cfif>
    </cflock>
</cfif>
