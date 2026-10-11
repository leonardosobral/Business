<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0>
    <cfheader statuscode="404" statustext="Not Found"/><cfabort/>
</cfif>
<!--- Keep dates and places that distinguish races when their displayed name prefix collides. --->
<cfif isDefined("qEvento.nome_evento") AND isDate(qEvento.data_inicial)>
    <cfquery name="qEventTitleDate" cachedwithin="#createTimeSpan(0,0,10,0)#" timeout="10">
        SELECT EXISTS (
            SELECT 1 FROM tb_evento_corridas
            WHERE nome_evento = <cfqueryparam value="#qEvento.nome_evento#" cfsqltype="cf_sql_varchar"/>
              AND ativo = true
              AND data_inicial <> <cfqueryparam value="#qEvento.data_inicial#" cfsqltype="cf_sql_date"/>
        ) AS repeated_name
    </cfquery>
    <cfset VARIABLES.eventTruncatedName = false/>
    <cfset VARIABLES.eventAmbiguousTitleContext = false/>
    <cfif len(qEvento.nome_evento & "") GTE 50>
        <!--- One shared query cache for colliding prefixes; avoid rescanning the catalog per event. --->
        <cfquery name="qEventTitlePrefixes" cachedwithin="#createTimeSpan(0,0,10,0)#" timeout="10">
            SELECT left(nome_evento, 50) AS name_prefix,
                   jsonb_agg(DISTINCT jsonb_build_object(
                       'name', nome_evento, 'city', coalesce(cidade, ''),
                       'state', coalesce(estado, ''), 'date', data_inicial::text
                   ))::text AS variants
            FROM tb_evento_corridas
            WHERE ativo = true AND length(nome_evento) >= 50
            GROUP BY left(nome_evento, 50)
            HAVING count(DISTINCT nome_evento) > 1
        </cfquery>
        <cfloop query="qEventTitlePrefixes">
            <cfif compare(qEventTitlePrefixes.name_prefix & "", left(qEvento.nome_evento & "", 50)) EQ 0>
                <cfscript>
                VARIABLES.eventTitleVariants = deserializeJSON(qEventTitlePrefixes.variants);
                for (VARIABLES.eventTitleVariant in VARIABLES.eventTitleVariants) {
                    if (compare(VARIABLES.eventTitleVariant.name & "", qEvento.nome_evento & "") != 0) {
                        VARIABLES.eventTruncatedName = true;
                        if (VARIABLES.eventTitleVariant.date == dateFormat(qEvento.data_inicial, "yyyy-mm-dd")
                            && compare(VARIABLES.eventTitleVariant.city & "", qEvento.cidade & "") == 0
                            && compare(VARIABLES.eventTitleVariant.state & "", qEvento.estado & "") == 0) {
                            VARIABLES.eventAmbiguousTitleContext = true;
                        }
                    }
                }
                </cfscript>
            </cfif>
        </cfloop>
    </cfif>
    <cfif VARIABLES.eventTruncatedName>
        <cfscript>
        VARIABLES.eventDatedTitleName = trim(qEvento.nome_evento & "");
        // A name alone resolves ties in the same city/date; never guess an edition label.
        if (!VARIABLES.eventAmbiguousTitleContext && len(VARIABLES.eventDatedTitleName) > 50) {
            VARIABLES.eventDatedTitlePrefix = left(VARIABLES.eventDatedTitleName, 50);
            if (!reFind("\s", mid(VARIABLES.eventDatedTitleName, 51, 1))) {
                VARIABLES.eventDatedTitlePrefix = reReplace(VARIABLES.eventDatedTitlePrefix, "\s+\S*$", "");
            }
            VARIABLES.eventDatedTitleName = trim(reReplace(VARIABLES.eventDatedTitlePrefix, "[\s|,:;-]+$", ""));
        }
        VARIABLES.eventDatedTitlePlace = trim((qEvento.cidade & "") & " " & (qEvento.estado & ""));
        VARIABLES.eventDatedTitleType = structKeyExists(VARIABLES,"eventTitleTypeLabel") && len(trim(VARIABLES.eventTitleTypeLabel))
            ? " - " & trim(VARIABLES.eventTitleTypeLabel) : "";
        VARIABLES.title = HTMLEditFormat(VARIABLES.eventDatedTitleName
            & (len(VARIABLES.eventDatedTitlePlace) ? " | " & VARIABLES.eventDatedTitlePlace : "")
            & " | " & dateFormat(qEvento.data_inicial,"dd/mm/yyyy")
            & VARIABLES.eventDatedTitleType & " | " & APPLICATION.nomeSite);
        </cfscript>
    <cfelseif qEventTitleDate.repeated_name>
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
