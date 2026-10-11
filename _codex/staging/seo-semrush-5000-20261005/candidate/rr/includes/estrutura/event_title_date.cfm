<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0>
    <cfheader statuscode="404" statustext="Not Found"/><cfabort/>
</cfif>
<!--- Distinguish repeated race names using existing dates; do not change event facts. --->
<cfif isDefined("qEvento.nome_evento") AND isDate(qEvento.data_inicial)>
    <cfquery name="qEventTitleDate" cachedwithin="#createTimeSpan(0,0,10,0)#" timeout="10">
        SELECT EXISTS (
            SELECT 1 FROM tb_evento_corridas
            WHERE nome_evento = <cfqueryparam value="#qEvento.nome_evento#" cfsqltype="cf_sql_varchar"/>
              AND ativo = true
              AND data_inicial <> <cfqueryparam value="#qEvento.data_inicial#" cfsqltype="cf_sql_date"/>
        ) AS repeated_name
    </cfquery>
    <cfif qEventTitleDate.repeated_name>
        <cfscript>
        VARIABLES.eventDatedTitleType = structKeyExists(VARIABLES,"eventTitleTypeLabel") && len(trim(VARIABLES.eventTitleTypeLabel))
            ? " - " & trim(VARIABLES.eventTitleTypeLabel) : "";
        VARIABLES.eventDatedTitleSuffix = VARIABLES.eventDatedTitleType & " | " & dateFormat(qEvento.data_inicial,"dd/mm/yyyy") & " | " & APPLICATION.nomeSite;
        VARIABLES.eventDatedTitleName = reReplace(trim(qEvento.nome_evento & ""),"\s+"," ","all");
        VARIABLES.eventDatedTitleBudget = max(10,70-len(VARIABLES.eventDatedTitleSuffix));
        VARIABLES.title = HTMLEditFormat(trim(left(VARIABLES.eventDatedTitleName,VARIABLES.eventDatedTitleBudget)) & VARIABLES.eventDatedTitleSuffix);
        </cfscript>
    </cfif>
</cfif>
