<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0>
    <cfheader statuscode="404"/><cfabort/>
</cfif>
<!--- Ignore case for annual editions only when their dates distinguish them; preserve same-date titles. --->
<!--- Keep dates and places that distinguish races when their displayed name prefix collides. --->
<cfif isDefined("qEvento.nome_evento") AND isDate(qEvento.data_inicial)>
    <cfquery name="qEventTitleDate" cachedwithin="#createTimeSpan(0,0,10,0)#" timeout="10">
        SELECT coalesce(bool_or(nome_evento = <cfqueryparam value="#qEvento.nome_evento#" cfsqltype="cf_sql_varchar"/>
                    AND data_inicial <> <cfqueryparam value="#qEvento.data_inicial#" cfsqltype="cf_sql_date"/>), false) AS repeated_name,
               count(DISTINCT data_inicial) > 1
                    AND count(*) FILTER (WHERE data_inicial = <cfqueryparam value="#qEvento.data_inicial#" cfsqltype="cf_sql_date"/>) = 1 AS case_repeated_name,
               coalesce(bool_or(data_inicial = <cfqueryparam value="#qEvento.data_inicial#" cfsqltype="cf_sql_date"/>
                    AND (lower(trim(coalesce(cidade, ''))) <> lower(trim(<cfqueryparam value="#qEvento.cidade#" cfsqltype="cf_sql_varchar"/>))
                         OR lower(trim(coalesce(estado, ''))) <> lower(trim(<cfqueryparam value="#qEvento.estado#" cfsqltype="cf_sql_varchar"/>)))), false) AS repeated_place
        FROM tb_evento_corridas
        WHERE lower(nome_evento) = lower(<cfqueryparam value="#qEvento.nome_evento#" cfsqltype="cf_sql_varchar"/>)
          AND ativo = true
    </cfquery>
    <cfset VARIABLES.eventTruncatedName = false/>
    <cfset VARIABLES.eventAmbiguousTitleContext = false/>
    <cfif NOT qEventTitleDate.repeated_name AND len(qEvento.nome_evento & "") GTE 50>
        <!--- One shared query cache for colliding prefixes; avoid rescanning the catalog per event. --->
        <cfquery name="qEventTitlePrefixes" cachedwithin="#createTimeSpan(0,0,10,0)#" timeout="10">
            WITH title_names AS (
                SELECT nome_evento, jsonb_agg(DISTINCT jsonb_build_object(
                       'name', nome_evento, 'city', coalesce(cidade, ''),
                       'state', coalesce(estado, ''), 'date', data_inicial::text
                )) AS variants
                FROM tb_evento_corridas
                WHERE ativo = true AND length(nome_evento) >= 50
                GROUP BY nome_evento
                -- Multiple dates already distinguish these names in the existing title rule.
                HAVING count(DISTINCT data_inicial) = 1
            )
            SELECT lower(left(nome_evento, 50)) AS name_prefix, jsonb_agg(variant)::text AS variants
            FROM title_names
            CROSS JOIN LATERAL jsonb_array_elements(title_names.variants) AS variant
            GROUP BY lower(left(nome_evento, 50))
            HAVING count(DISTINCT lower(nome_evento)) > 1
        </cfquery>
        <cfloop query="qEventTitlePrefixes">
            <cfif compareNoCase(qEventTitlePrefixes.name_prefix & "", left(qEvento.nome_evento & "", 50)) EQ 0>
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
        VARIABLES.title = encodeForHTML(VARIABLES.eventDatedTitleName
            & (len(VARIABLES.eventDatedTitlePlace) ? " | " & VARIABLES.eventDatedTitlePlace : "")
            & " | " & dateFormat(qEvento.data_inicial,"dd/mm/yyyy")
            & VARIABLES.eventDatedTitleType & " | " & APPLICATION.nomeSite);
        </cfscript>
    <!--- Longer names retain the existing prefix rules: a shorter date title could discard a distinct edition suffix. --->
    <cfelseif qEventTitleDate.repeated_place OR qEventTitleDate.repeated_name OR (qEventTitleDate.case_repeated_name AND len(qEvento.nome_evento & "") LT 50)>
        <cfscript>
        VARIABLES.eventDatedTitleType = structKeyExists(VARIABLES,"eventTitleTypeLabel") && len(trim(VARIABLES.eventTitleTypeLabel))
            ? " - " & trim(VARIABLES.eventTitleTypeLabel) : "";
        // Same-day races in different cities need the registered place as well as the date.
        VARIABLES.eventDatedTitlePlace = qEventTitleDate.repeated_place ? trim((qEvento.cidade & "") & " " & (qEvento.estado & "")) : "";
        VARIABLES.eventDatedTitlePlaceSuffix = len(VARIABLES.eventDatedTitlePlace) ? " | " & VARIABLES.eventDatedTitlePlace : "";
        VARIABLES.eventDatedTitleSuffix = VARIABLES.eventDatedTitleType & VARIABLES.eventDatedTitlePlaceSuffix & " | " & dateFormat(qEvento.data_inicial,"dd/mm/yyyy") & " | " & APPLICATION.nomeSite;
        VARIABLES.eventDatedTitleName = reReplace(trim(qEvento.nome_evento & ""),"\s+"," ","all");
        // For the new case-only editions, preserve the full race name before the optional type label.
        if (!qEventTitleDate.repeated_name && len(VARIABLES.eventDatedTitleName & VARIABLES.eventDatedTitleSuffix) > 70) {
            VARIABLES.eventCompactTitleTypes = {"corrida de rua"="corrida", "road race"="Race", "carrera de ruta"="Carrera"};
            VARIABLES.eventCompactTitleTypeKey = structKeyExists(VARIABLES,"eventTitleTypeLabel") ? lCase(trim(VARIABLES.eventTitleTypeLabel & "")) : "";
            VARIABLES.eventCompactTitleType = structKeyExists(VARIABLES.eventCompactTitleTypes, VARIABLES.eventCompactTitleTypeKey)
                ? " - " & VARIABLES.eventCompactTitleTypes[VARIABLES.eventCompactTitleTypeKey] : "";
            VARIABLES.eventDatedTitleSuffix = VARIABLES.eventCompactTitleType & VARIABLES.eventDatedTitlePlaceSuffix & " " & dateFormat(qEvento.data_inicial,"dd/mm/yyyy") & " | " & APPLICATION.nomeSite;
        }
        // The race identity outranks optional type wording and a character-count target.
        if (qEventTitleDate.repeated_place && len(VARIABLES.eventDatedTitleName & VARIABLES.eventDatedTitleSuffix) > 70) {
            VARIABLES.eventDatedTitleSuffix = VARIABLES.eventDatedTitlePlaceSuffix & " | " & dateFormat(qEvento.data_inicial,"dd/mm/yyyy") & " | " & APPLICATION.nomeSite;
        }
        VARIABLES.eventDatedTitleBudget = qEventTitleDate.repeated_place
            ? len(VARIABLES.eventDatedTitleName) : max(10,70-len(VARIABLES.eventDatedTitleSuffix));
        VARIABLES.title = encodeForHTML(trim(left(VARIABLES.eventDatedTitleName,VARIABLES.eventDatedTitleBudget)) & VARIABLES.eventDatedTitleSuffix);
        </cfscript>
    </cfif>
</cfif>
