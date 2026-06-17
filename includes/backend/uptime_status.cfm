<cfset VARIABLES.uptimeStatus = {
    configured = false,
    enabled = false,
    configSource = "none",
    configPath = "",
    configFileExists = false,
    loaded = false,
    fetchedAt = "",
    error = "",
    monitors = [],
    total = 0,
    up = 0,
    warning = 0,
    down = 0,
    paused = 0,
    unknown = 0,
    averageUptime = 0,
    averageResponseTime = 0
}/>

<cfif NOT structKeyExists(APPLICATION, "uptimeRobot")>
    <cfset APPLICATION.uptimeRobot = {
        enabled = false,
        apiKey = "",
        apiUrl = "https://api.uptimerobot.com/v2/getMonitors",
        timeoutSeconds = 15,
        cacheSeconds = 120
    }/>
</cfif>

<cfif structKeyExists(APPLICATION, "uptimeRobot")>
    <cfset VARIABLES.uptimeStatus.configured = structKeyExists(APPLICATION.uptimeRobot, "apiKey") AND len(trim(APPLICATION.uptimeRobot.apiKey)) GT 0/>
    <cfset VARIABLES.uptimeStatus.enabled = structKeyExists(APPLICATION.uptimeRobot, "enabled") AND APPLICATION.uptimeRobot.enabled/>
    <cfif VARIABLES.uptimeStatus.configured>
        <cfset VARIABLES.uptimeStatus.configSource = "application"/>
    </cfif>
</cfif>

<cfif NOT VARIABLES.uptimeStatus.configured>
    <cfset VARIABLES.uptimeLocalConfig = {}/>
    <cfset VARIABLES.uptimeLocalConfigPath = replace(getDirectoryFromPath(getCurrentTemplatePath()), "\includes\backend\", "\config\business.local.cfm", "one")/>
    <cfset VARIABLES.uptimeLocalConfigPath = replace(VARIABLES.uptimeLocalConfigPath, "/includes/backend/", "/config/business.local.cfm", "one")/>
    <cfset VARIABLES.uptimeStatus.configPath = VARIABLES.uptimeLocalConfigPath/>
    <cfset VARIABLES.uptimeStatus.configFileExists = fileExists(VARIABLES.uptimeLocalConfigPath)/>

    <cfif VARIABLES.uptimeStatus.configFileExists>
        <cftry>
            <cfinclude template="../../config/business.local.cfm"/>
            <cfif isDefined("businessLocalConfig") AND isStruct(businessLocalConfig)>
                <cfset VARIABLES.uptimeLocalConfig = duplicate(businessLocalConfig)/>
            <cfelseif structKeyExists(VARIABLES, "businessLocalConfig") AND isStruct(VARIABLES.businessLocalConfig)>
                <cfset VARIABLES.uptimeLocalConfig = duplicate(VARIABLES.businessLocalConfig)/>
            </cfif>

            <cfif structKeyExists(VARIABLES.uptimeLocalConfig, "uptimeRobotApiKey") AND len(trim(VARIABLES.uptimeLocalConfig.uptimeRobotApiKey)) GT 0>
                <cfset APPLICATION.uptimeRobot = {
                    enabled = true,
                    apiKey = trim(VARIABLES.uptimeLocalConfig.uptimeRobotApiKey),
                    apiUrl = structKeyExists(VARIABLES.uptimeLocalConfig, "uptimeRobotApiUrl") AND len(trim(VARIABLES.uptimeLocalConfig.uptimeRobotApiUrl)) ? trim(VARIABLES.uptimeLocalConfig.uptimeRobotApiUrl) : "https://api.uptimerobot.com/v2/getMonitors",
                    timeoutSeconds = structKeyExists(VARIABLES.uptimeLocalConfig, "uptimeRobotTimeoutSeconds") AND val(VARIABLES.uptimeLocalConfig.uptimeRobotTimeoutSeconds) GT 0 ? val(VARIABLES.uptimeLocalConfig.uptimeRobotTimeoutSeconds) : 15,
                    cacheSeconds = structKeyExists(VARIABLES.uptimeLocalConfig, "uptimeRobotCacheSeconds") AND val(VARIABLES.uptimeLocalConfig.uptimeRobotCacheSeconds) GT 0 ? val(VARIABLES.uptimeLocalConfig.uptimeRobotCacheSeconds) : 120
                }/>
                <cfset VARIABLES.uptimeStatus.configured = true/>
                <cfset VARIABLES.uptimeStatus.enabled = true/>
                <cfset VARIABLES.uptimeStatus.configSource = "local-file-runtime"/>
            </cfif>

            <cfcatch type="any">
                <cfset VARIABLES.uptimeStatus.error = "Nao foi possivel ler config/business.local.cfm: #cfcatch.message#"/>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfif VARIABLES.uptimeStatus.enabled>
    <cfset VARIABLES.uptimeCacheKey = "uptimeRobotStatus"/>
    <cfset VARIABLES.uptimeCacheSeconds = APPLICATION.uptimeRobot.cacheSeconds/>
    <cfset VARIABLES.uptimeFetchRequired = true/>

    <cflock scope="application" type="readonly" timeout="5">
        <cfif structKeyExists(APPLICATION, VARIABLES.uptimeCacheKey)
            AND structKeyExists(APPLICATION[VARIABLES.uptimeCacheKey], "expiresAt")
            AND APPLICATION[VARIABLES.uptimeCacheKey].expiresAt GT now()
            AND structKeyExists(APPLICATION[VARIABLES.uptimeCacheKey], "status")>
            <cfset VARIABLES.uptimeStatus = duplicate(APPLICATION[VARIABLES.uptimeCacheKey].status)/>
            <cfset VARIABLES.uptimeFetchRequired = false/>
        </cfif>
    </cflock>

    <cfif VARIABLES.uptimeFetchRequired>
        <cftry>
            <cfhttp method="post" url="#APPLICATION.uptimeRobot.apiUrl#" result="qUptimeRobotHttp" timeout="#APPLICATION.uptimeRobot.timeoutSeconds#">
                <cfhttpparam type="formfield" name="api_key" value="#APPLICATION.uptimeRobot.apiKey#"/>
                <cfhttpparam type="formfield" name="format" value="json"/>
                <cfhttpparam type="formfield" name="logs" value="1"/>
                <cfhttpparam type="formfield" name="response_times" value="1"/>
                <cfhttpparam type="formfield" name="response_times_limit" value="1"/>
                <cfhttpparam type="formfield" name="all_time_uptime_ratio" value="1"/>
                <cfhttpparam type="formfield" name="custom_uptime_ratios" value="7-30"/>
            </cfhttp>

            <cfif left(qUptimeRobotHttp.statusCode, 3) EQ "200" AND isJSON(qUptimeRobotHttp.fileContent)>
                <cfset VARIABLES.uptimeRobotPayload = deserializeJSON(qUptimeRobotHttp.fileContent)/>

                <cfif structKeyExists(VARIABLES.uptimeRobotPayload, "stat") AND VARIABLES.uptimeRobotPayload.stat EQ "ok" AND structKeyExists(VARIABLES.uptimeRobotPayload, "monitors") AND isArray(VARIABLES.uptimeRobotPayload.monitors)>
                    <cfset VARIABLES.uptimeStatus.loaded = true/>
                    <cfset VARIABLES.uptimeStatus.fetchedAt = now()/>
                    <cfset VARIABLES.uptimeStatus.total = arrayLen(VARIABLES.uptimeRobotPayload.monitors)/>
                    <cfset VARIABLES.uptimeUptimeSum = 0/>
                    <cfset VARIABLES.uptimeUptimeCount = 0/>
                    <cfset VARIABLES.uptimeResponseSum = 0/>
                    <cfset VARIABLES.uptimeResponseCount = 0/>

                    <cfloop array="#VARIABLES.uptimeRobotPayload.monitors#" index="uptimeMonitor">
                        <cfset VARIABLES.uptimeMonitorStatus = structKeyExists(uptimeMonitor, "status") ? val(uptimeMonitor.status) : 0/>
                        <cfset VARIABLES.uptimeMonitorName = structKeyExists(uptimeMonitor, "friendly_name") ? uptimeMonitor.friendly_name : "Monitor sem nome"/>
                        <cfset VARIABLES.uptimeMonitorUrl = structKeyExists(uptimeMonitor, "url") ? uptimeMonitor.url : ""/>
                        <cfset VARIABLES.uptimeMonitorUptime = structKeyExists(uptimeMonitor, "all_time_uptime_ratio") AND isNumeric(uptimeMonitor.all_time_uptime_ratio) ? val(uptimeMonitor.all_time_uptime_ratio) : 0/>
                        <cfset VARIABLES.uptimeMonitorResponse = 0/>
                        <cfset VARIABLES.uptimeMonitorIncident = ""/>
                        <cfset VARIABLES.uptimeMonitorIncidentAt = ""/>
                        <cfset VARIABLES.uptimeMonitorCustomRatio = ""/>

                        <cfif structKeyExists(uptimeMonitor, "average_response_time") AND isNumeric(uptimeMonitor.average_response_time)>
                            <cfset VARIABLES.uptimeMonitorResponse = val(uptimeMonitor.average_response_time)/>
                        <cfelseif structKeyExists(uptimeMonitor, "response_times") AND isArray(uptimeMonitor.response_times) AND arrayLen(uptimeMonitor.response_times) AND structKeyExists(uptimeMonitor.response_times[1], "value") AND isNumeric(uptimeMonitor.response_times[1].value)>
                            <cfset VARIABLES.uptimeMonitorResponse = val(uptimeMonitor.response_times[1].value)/>
                        </cfif>

                        <cfif structKeyExists(uptimeMonitor, "custom_uptime_ratio")>
                            <cfset VARIABLES.uptimeMonitorCustomRatio = uptimeMonitor.custom_uptime_ratio/>
                        </cfif>

                        <cfif structKeyExists(uptimeMonitor, "logs") AND isArray(uptimeMonitor.logs) AND arrayLen(uptimeMonitor.logs)>
                            <cfset VARIABLES.uptimeMonitorLog = uptimeMonitor.logs[1]/>
                            <cfif structKeyExists(VARIABLES.uptimeMonitorLog, "reason") AND isStruct(VARIABLES.uptimeMonitorLog.reason) AND structKeyExists(VARIABLES.uptimeMonitorLog.reason, "detail")>
                                <cfset VARIABLES.uptimeMonitorIncident = VARIABLES.uptimeMonitorLog.reason.detail/>
                            </cfif>
                            <cfif structKeyExists(VARIABLES.uptimeMonitorLog, "datetime") AND isNumeric(VARIABLES.uptimeMonitorLog.datetime)>
                                <cfset VARIABLES.uptimeMonitorIncidentAt = dateAdd("s", val(VARIABLES.uptimeMonitorLog.datetime), createDateTime(1970, 1, 1, 0, 0, 0))/>
                            </cfif>
                        </cfif>

                        <cfif VARIABLES.uptimeMonitorStatus EQ 2>
                            <cfset VARIABLES.uptimeStatus.up = VARIABLES.uptimeStatus.up + 1/>
                            <cfset VARIABLES.uptimeMonitorLabel = "Online"/>
                            <cfset VARIABLES.uptimeMonitorClass = "success"/>
                        <cfelseif VARIABLES.uptimeMonitorStatus EQ 8>
                            <cfset VARIABLES.uptimeStatus.warning = VARIABLES.uptimeStatus.warning + 1/>
                            <cfset VARIABLES.uptimeMonitorLabel = "Instável"/>
                            <cfset VARIABLES.uptimeMonitorClass = "warning"/>
                        <cfelseif VARIABLES.uptimeMonitorStatus EQ 9>
                            <cfset VARIABLES.uptimeStatus.down = VARIABLES.uptimeStatus.down + 1/>
                            <cfset VARIABLES.uptimeMonitorLabel = "Offline"/>
                            <cfset VARIABLES.uptimeMonitorClass = "danger"/>
                        <cfelseif VARIABLES.uptimeMonitorStatus EQ 0>
                            <cfset VARIABLES.uptimeStatus.paused = VARIABLES.uptimeStatus.paused + 1/>
                            <cfset VARIABLES.uptimeMonitorLabel = "Pausado"/>
                            <cfset VARIABLES.uptimeMonitorClass = "secondary"/>
                        <cfelse>
                            <cfset VARIABLES.uptimeStatus.unknown = VARIABLES.uptimeStatus.unknown + 1/>
                            <cfset VARIABLES.uptimeMonitorLabel = "Aguardando"/>
                            <cfset VARIABLES.uptimeMonitorClass = "info"/>
                        </cfif>

                        <cfif VARIABLES.uptimeMonitorUptime GT 0>
                            <cfset VARIABLES.uptimeUptimeSum = VARIABLES.uptimeUptimeSum + VARIABLES.uptimeMonitorUptime/>
                            <cfset VARIABLES.uptimeUptimeCount = VARIABLES.uptimeUptimeCount + 1/>
                        </cfif>
                        <cfif VARIABLES.uptimeMonitorResponse GT 0>
                            <cfset VARIABLES.uptimeResponseSum = VARIABLES.uptimeResponseSum + VARIABLES.uptimeMonitorResponse/>
                            <cfset VARIABLES.uptimeResponseCount = VARIABLES.uptimeResponseCount + 1/>
                        </cfif>

                        <cfset arrayAppend(VARIABLES.uptimeStatus.monitors, {
                            name = VARIABLES.uptimeMonitorName,
                            url = VARIABLES.uptimeMonitorUrl,
                            status = VARIABLES.uptimeMonitorStatus,
                            statusLabel = VARIABLES.uptimeMonitorLabel,
                            statusClass = VARIABLES.uptimeMonitorClass,
                            uptime = VARIABLES.uptimeMonitorUptime,
                            responseTime = VARIABLES.uptimeMonitorResponse,
                            customRatio = VARIABLES.uptimeMonitorCustomRatio,
                            incident = VARIABLES.uptimeMonitorIncident,
                            incidentAt = VARIABLES.uptimeMonitorIncidentAt
                        })/>
                    </cfloop>

                    <cfif VARIABLES.uptimeUptimeCount GT 0>
                        <cfset VARIABLES.uptimeStatus.averageUptime = VARIABLES.uptimeUptimeSum / VARIABLES.uptimeUptimeCount/>
                    </cfif>
                    <cfif VARIABLES.uptimeResponseCount GT 0>
                        <cfset VARIABLES.uptimeStatus.averageResponseTime = VARIABLES.uptimeResponseSum / VARIABLES.uptimeResponseCount/>
                    </cfif>
                <cfelse>
                    <cfset VARIABLES.uptimeStatus.error = "A API de uptime nao retornou uma resposta valida."/>
                </cfif>
            <cfelse>
                <cfset VARIABLES.uptimeStatus.error = "A API de uptime retornou HTTP #qUptimeRobotHttp.statusCode#."/>
            </cfif>

            <cfcatch type="any">
                <cfset VARIABLES.uptimeStatus.error = "Nao foi possivel consultar a API de uptime: #cfcatch.message#"/>
            </cfcatch>
        </cftry>

        <cflock scope="application" type="exclusive" timeout="5">
            <cfset APPLICATION[VARIABLES.uptimeCacheKey] = {
                expiresAt = dateAdd("s", VARIABLES.uptimeCacheSeconds, now()),
                status = duplicate(VARIABLES.uptimeStatus)
            }/>
        </cflock>
    </cfif>
</cfif>
