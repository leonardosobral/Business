<!--- Include inside an integrated POST form. Existing direct CSRF remains the handler's contract. --->
<cfif structKeyExists(REQUEST,"businessAccessContext")>
    <cfset VARIABLES.businessDelegationFormPolicy=createObject("component","services.accountDelegation.Policy")/>
    <cfset VARIABLES.businessDelegationFormFields=VARIABLES.businessDelegationFormPolicy.formFields(
        REQUEST.businessAccessContext,
        VARIABLES.businessDelegationFormPolicy.formToken(REQUEST.businessAccessContext,SESSION.businessDelegationFormSeed))/>
    <cfoutput><cfloop collection="#VARIABLES.businessDelegationFormFields#" item="businessDelegationFormKey"><input type="hidden" name="#encodeForHTMLAttribute(businessDelegationFormKey)#" value="#encodeForHTMLAttribute(VARIABLES.businessDelegationFormFields[businessDelegationFormKey])#"></cfloop></cfoutput>
</cfif>
