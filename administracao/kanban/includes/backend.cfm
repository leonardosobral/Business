<cfinclude template="trello_service.cfm"/>

<cfif NOT structKeyExists(SESSION, "trelloKanbanCsrf") OR NOT len(trim(SESSION.trelloKanbanCsrf & ""))>
    <cfset SESSION.trelloKanbanCsrf = lCase(hash(createUUID() & now() & getTickCount() & rand(), "SHA-256"))/>
</cfif>

<cfset VARIABLES.trelloKanbanCsrf = SESSION.trelloKanbanCsrf/>
<cfset VARIABLES.trelloKanbanConfigured = kanbanTrelloConfigured()/>
<cfset VARIABLES.trelloKanbanSchemaReady = false/>

<cftry>
    <cfquery name="qTrelloKanbanSchema">
        SELECT to_regclass('public.tb_trello_quadros') IS NOT NULL
               AND to_regclass('public.tb_trello_auditoria') IS NOT NULL AS ready
    </cfquery>
    <cfset VARIABLES.trelloKanbanSchemaReady = qTrelloKanbanSchema.recordCount AND kanbanBoolean(qTrelloKanbanSchema.ready)/>
    <cfcatch type="any">
        <cfset VARIABLES.trelloKanbanSchemaReady = false/>
    </cfcatch>
</cftry>
