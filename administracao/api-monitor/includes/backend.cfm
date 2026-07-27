<cfinclude template="../../../includes/backend/api_monitor_service.cfm"/>

<cfparam name="URL.hours" default="24"/>
<cfparam name="URL.refresh" default="0"/>

<cfset VARIABLES.apiMonitorAllowedHours = "1,6,24,72"/>
<cfset VARIABLES.apiMonitorHours = listFind(VARIABLES.apiMonitorAllowedHours, trim(URL.hours & "")) ? val(URL.hours) : 24/>
<cfset VARIABLES.apiMonitorForceRefresh = val(URL.refresh) EQ 1/>
<cfset VARIABLES.apiMonitorConfig = structKeyExists(APPLICATION, "apiMonitor") AND isStruct(APPLICATION.apiMonitor)
    ? duplicate(APPLICATION.apiMonitor)
    : {
        enabled = true,
        logPath = "/var/log/apache2/api.roadrunners.run-telemetry.log",
        maxBytes = 16777216,
        cacheSeconds = 60
    }/>
<cfset VARIABLES.apiMonitorSnapshot = apiMonitorEmptySnapshot(VARIABLES.apiMonitorHours)/>
<cfset VARIABLES.apiMonitorExpectedSchemaVersion = 2/>
<cfset VARIABLES.apiMonitorCacheKey = "apiMonitorSnapshotV3" & VARIABLES.apiMonitorHours/>
<cfset VARIABLES.apiMonitorCachedSnapshot = {}/>
<cfset VARIABLES.apiMonitorNeedsLoad = true/>

<cfif VARIABLES.apiMonitorConfig.enabled AND NOT VARIABLES.apiMonitorForceRefresh>
    <cflock scope="application" type="readonly" timeout="5">
        <cfif structKeyExists(APPLICATION, VARIABLES.apiMonitorCacheKey)
            AND isStruct(APPLICATION[VARIABLES.apiMonitorCacheKey])
            AND structKeyExists(APPLICATION[VARIABLES.apiMonitorCacheKey], "expiresAt")
            AND APPLICATION[VARIABLES.apiMonitorCacheKey].expiresAt GT now()
            AND structKeyExists(APPLICATION[VARIABLES.apiMonitorCacheKey], "snapshot")>
            <cfset VARIABLES.apiMonitorCachedSnapshot = duplicate(APPLICATION[VARIABLES.apiMonitorCacheKey].snapshot)/>

            <cfif structKeyExists(VARIABLES.apiMonitorCachedSnapshot, "schemaVersion")
                AND val(VARIABLES.apiMonitorCachedSnapshot.schemaVersion) EQ VARIABLES.apiMonitorExpectedSchemaVersion
                AND structKeyExists(VARIABLES.apiMonitorCachedSnapshot, "traffic")
                AND isStruct(VARIABLES.apiMonitorCachedSnapshot.traffic)
                AND structKeyExists(VARIABLES.apiMonitorCachedSnapshot.traffic, "authenticated")>
                <cfset VARIABLES.apiMonitorSnapshot = VARIABLES.apiMonitorCachedSnapshot/>
                <cfset VARIABLES.apiMonitorNeedsLoad = false/>
            </cfif>
        </cfif>
    </cflock>
</cfif>

<cfif NOT VARIABLES.apiMonitorConfig.enabled>
    <cfset VARIABLES.apiMonitorSnapshot.error = "O monitor da API esta desabilitado na configuracao."/>
<cfelseif VARIABLES.apiMonitorNeedsLoad>
    <cfset VARIABLES.apiMonitorSnapshot = apiMonitorLoadSnapshot(
        VARIABLES.apiMonitorConfig.logPath,
        VARIABLES.apiMonitorHours,
        VARIABLES.apiMonitorConfig.maxBytes
    )/>

    <cfif structKeyExists(VARIABLES.apiMonitorSnapshot, "schemaVersion")
        AND val(VARIABLES.apiMonitorSnapshot.schemaVersion) EQ VARIABLES.apiMonitorExpectedSchemaVersion
        AND structKeyExists(VARIABLES.apiMonitorSnapshot, "traffic")
        AND isStruct(VARIABLES.apiMonitorSnapshot.traffic)
        AND structKeyExists(VARIABLES.apiMonitorSnapshot.traffic, "authenticated")>
        <cflock scope="application" type="exclusive" timeout="5">
            <cfset APPLICATION[VARIABLES.apiMonitorCacheKey] = {
                expiresAt = dateAdd("s", VARIABLES.apiMonitorConfig.cacheSeconds, now()),
                snapshot = duplicate(VARIABLES.apiMonitorSnapshot)
            }/>
        </cflock>
    <cfelse>
        <cfset VARIABLES.apiMonitorSnapshot.error = "Os arquivos do monitor estao em versoes diferentes. Atualize o servico, o backend e a view no mesmo deploy."/>
    </cfif>
</cfif>
