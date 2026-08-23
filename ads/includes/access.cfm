<!---
    Capacidades de Publicidade derivadas somente do contexto autenticado.
    A conta e o papel efetivos vêm de business_account_context.cfm; o ator e a
    identidade de administrador interno permanecem os do usuario real.
--->
<cfset VARIABLES.adsAccessViewRoles = "OWNER,ADMIN,OPERADOR,VISUALIZADOR"/>
<cfset VARIABLES.adsAccessCampaignRoles = "OWNER,ADMIN,OPERADOR"/>
<cfset VARIABLES.adsAccessPurchaseRoles = "OWNER,ADMIN"/>
<cfset VARIABLES.adsAccessPaymentRoles = "OWNER,ADMIN"/>

<cfset VARIABLES.adsAccessAccountId = 0/>
<cfset VARIABLES.adsAccessActorId = 0/>
<cfset VARIABLES.adsAccessRole = ""/>
<cfset VARIABLES.adsAccessRealIsAdmin = false/>
<cfset VARIABLES.adsAccessHasAccount = false/>
<cfset VARIABLES.adsAccessHasActor = false/>
<cfset VARIABLES.adsAccessCanView = false/>
<cfset VARIABLES.adsAccessCanManageCampaign = false/>
<cfset VARIABLES.adsAccessCanPurchaseCredit = false/>
<cfset VARIABLES.adsAccessCanViewPayments = false/>
<cfset VARIABLES.adsAccessCanAdminFinance = false/>

<cfif isDefined("VARIABLES.businessActiveAccountId")
    AND isNumeric(VARIABLES.businessActiveAccountId)
    AND val(VARIABLES.businessActiveAccountId) GT 0>
    <cfset VARIABLES.adsAccessAccountId = val(VARIABLES.businessActiveAccountId)/>
    <cfset VARIABLES.adsAccessHasAccount = true/>
</cfif>

<cfif isDefined("qPerfil")
    AND qPerfil.recordcount
    AND isDefined("qPerfil.id")
    AND isNumeric(qPerfil.id)
    AND val(qPerfil.id) GT 0>
    <cfset VARIABLES.adsAccessActorId = val(qPerfil.id)/>
    <cfset VARIABLES.adsAccessHasActor = true/>
</cfif>

<cfif VARIABLES.adsAccessHasAccount
    AND VARIABLES.adsAccessHasActor
    AND isDefined("VARIABLES.businessCurrentAccountRole")>
    <cfset VARIABLES.adsAccessRole = uCase(trim(VARIABLES.businessCurrentAccountRole & ""))/>
</cfif>

<cfif isDefined("VARIABLES.businessRealIsAdmin")>
    <cfif isBoolean(VARIABLES.businessRealIsAdmin)>
        <cfset VARIABLES.adsAccessRealIsAdmin = VARIABLES.businessRealIsAdmin/>
    <cfelseif listFindNoCase("1,true,t,yes,on,sim", trim(VARIABLES.businessRealIsAdmin & ""))>
        <cfset VARIABLES.adsAccessRealIsAdmin = true/>
    </cfif>
</cfif>

<cfset VARIABLES.adsAccessCanView = VARIABLES.adsAccessHasAccount
    AND VARIABLES.adsAccessHasActor
    AND (
        VARIABLES.adsAccessRealIsAdmin
        OR listFindNoCase(VARIABLES.adsAccessViewRoles, VARIABLES.adsAccessRole) GT 0
    )/>
<cfset VARIABLES.adsAccessCanManageCampaign = VARIABLES.adsAccessCanView
    AND (
        VARIABLES.adsAccessRealIsAdmin
        OR listFindNoCase(VARIABLES.adsAccessCampaignRoles, VARIABLES.adsAccessRole) GT 0
    )/>
<cfset VARIABLES.adsAccessCanPurchaseCredit = VARIABLES.adsAccessCanView
    AND (
        VARIABLES.adsAccessRealIsAdmin
        OR listFindNoCase(VARIABLES.adsAccessPurchaseRoles, VARIABLES.adsAccessRole) GT 0
    )/>
<cfset VARIABLES.adsAccessCanViewPayments = VARIABLES.adsAccessCanView
    AND (
        VARIABLES.adsAccessRealIsAdmin
        OR listFindNoCase(VARIABLES.adsAccessPaymentRoles, VARIABLES.adsAccessRole) GT 0
    )/>
<cfset VARIABLES.adsAccessCanAdminFinance = VARIABLES.adsAccessHasAccount
    AND VARIABLES.adsAccessHasActor
    AND VARIABLES.adsAccessRealIsAdmin/>
