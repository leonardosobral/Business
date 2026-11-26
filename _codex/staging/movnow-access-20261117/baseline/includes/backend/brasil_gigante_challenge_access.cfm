<cfset VARIABLES.businessBrasilGiganteChallengeAccountId = 13/>
<cfset VARIABLES.businessCanManageBrasilGiganteChallenge = false/>

<cfif isDefined("qPerfil") AND qPerfil.recordcount>
    <cfif listFindNoCase(qPerfil.columnList, "is_admin")>
        <cfif isBoolean(qPerfil.is_admin)>
            <cfset VARIABLES.businessCanManageBrasilGiganteChallenge = qPerfil.is_admin/>
        <cfelseif listFindNoCase("true,1,yes,sim", trim(qPerfil.is_admin & ""))>
            <cfset VARIABLES.businessCanManageBrasilGiganteChallenge = true/>
        </cfif>
    </cfif>

    <cfif NOT VARIABLES.businessCanManageBrasilGiganteChallenge
        AND listFindNoCase(qPerfil.columnList, "is_dev")>
        <cfif isBoolean(qPerfil.is_dev)>
            <cfset VARIABLES.businessCanManageBrasilGiganteChallenge = qPerfil.is_dev/>
        <cfelseif listFindNoCase("true,1,yes,sim", trim(qPerfil.is_dev & ""))>
            <cfset VARIABLES.businessCanManageBrasilGiganteChallenge = true/>
        </cfif>
    </cfif>
</cfif>

<!--- A lista operacional considera conta e vinculo ativos e apenas OWNER, ADMIN ou OPERADOR. --->
<cfif NOT VARIABLES.businessCanManageBrasilGiganteChallenge
    AND isDefined("VARIABLES.businessEffectiveAccountOperatorIds")
    AND listFind(VARIABLES.businessEffectiveAccountOperatorIds, VARIABLES.businessBrasilGiganteChallengeAccountId)>
    <cfset VARIABLES.businessCanManageBrasilGiganteChallenge = true/>
</cfif>
