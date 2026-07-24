<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>

<cfset VARIABLES.searchTerm = trim(isDefined("URL.q") ? URL.q : "")/>
<cfset VARIABLES.results = []/>

<cftry>
    <cfif len(VARIABLES.searchTerm) GTE 2 OR isNumeric(VARIABLES.searchTerm)>
        <cfquery name="qNotificationUserSearch">
            SELECT usr.id, usr.name, usr.email
            FROM tb_usuarios usr
            WHERE
                <cfif isNumeric(VARIABLES.searchTerm)>
                    usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchTerm#"/>
                    OR
                </cfif>
                unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchTerm#%"/>))
                OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.searchTerm#%"/>))
            ORDER BY
                <cfif isNumeric(VARIABLES.searchTerm)>CASE WHEN usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.searchTerm#"/> THEN 0 ELSE 1 END,</cfif>
                upper(coalesce(usr.name, '')),
                usr.id
            LIMIT 12
        </cfquery>

        <cfloop query="qNotificationUserSearch">
            <cfset arrayAppend(VARIABLES.results, {
                id = int(qNotificationUserSearch.id),
                name = qNotificationUserSearch.name & "",
                email = qNotificationUserSearch.email & ""
            })/>
        </cfloop>
    </cfif>

    <cfoutput>#serializeJSON({success=true, results=VARIABLES.results})#</cfoutput>
    <cfcatch type="any">
        <cfheader statuscode="500" statustext="Internal Server Error"/>
        <cfoutput>#serializeJSON({success=false, message=cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
