<cfset VARIABLES.businessCatarinenseChallengeAccountId = 12/>
<cfset VARIABLES.businessCanManageCatarinenseChallenges = false/>

<cfif isDefined("qPerfil") AND qPerfil.recordcount>
    <cfif listFindNoCase(qPerfil.columnList, "is_admin")>
        <cfif isBoolean(qPerfil.is_admin)>
            <cfset VARIABLES.businessCanManageCatarinenseChallenges = qPerfil.is_admin/>
        <cfelseif listFindNoCase("true,1,yes,sim", trim(qPerfil.is_admin & ""))>
            <cfset VARIABLES.businessCanManageCatarinenseChallenges = true/>
        </cfif>
    </cfif>

    <cfif NOT VARIABLES.businessCanManageCatarinenseChallenges
        AND listFindNoCase(qPerfil.columnList, "is_dev")>
        <cfif isBoolean(qPerfil.is_dev)>
            <cfset VARIABLES.businessCanManageCatarinenseChallenges = qPerfil.is_dev/>
        <cfelseif listFindNoCase("true,1,yes,sim", trim(qPerfil.is_dev & ""))>
            <cfset VARIABLES.businessCanManageCatarinenseChallenges = true/>
        </cfif>
    </cfif>
</cfif>

<!--- A lista operacional ja considera conta e vinculo ativos e apenas OWNER, ADMIN ou OPERADOR. --->
<cfif NOT VARIABLES.businessCanManageCatarinenseChallenges
    AND isDefined("VARIABLES.businessEffectiveAccountOperatorIds")
    AND listFind(VARIABLES.businessEffectiveAccountOperatorIds, VARIABLES.businessCatarinenseChallengeAccountId)>
    <cfset VARIABLES.businessCanManageCatarinenseChallenges = true/>
</cfif>
