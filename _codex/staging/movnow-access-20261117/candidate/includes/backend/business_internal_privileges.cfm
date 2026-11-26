<!--- Account simulation and delegation never inherit the actor's global roles.
      Teams does not load backend_login, so also check the server-owned selection. --->
<cfset VARIABLES.businessInternalPrivilegesAllowed = NOT (
    (isDefined("VARIABLES.businessAccountSimulationActive") AND VARIABLES.businessAccountSimulationActive)
    OR (structKeyExists(REQUEST,"businessAccessContext") AND structKeyExists(REQUEST.businessAccessContext,"accessMode") AND REQUEST.businessAccessContext.accessMode NEQ "DIRECT")
    OR (structKeyExists(SESSION,"businessAccessSelection") AND isStruct(SESSION.businessAccessSelection) AND structKeyExists(SESSION.businessAccessSelection,"accessMode") AND SESSION.businessAccessSelection.accessMode NEQ "DIRECT")
    OR (structKeyExists(SESSION,"businessSimulatedAccountId") AND val(SESSION.businessSimulatedAccountId) GT 0)
    OR (structKeyExists(SESSION,"businessAccessSelectionInvalid") AND SESSION.businessAccessSelectionInvalid)
)/>
