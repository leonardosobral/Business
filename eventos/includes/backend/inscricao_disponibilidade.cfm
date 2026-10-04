<cfif getBaseTemplatePath() EQ getCurrentTemplatePath()>
    <cfheader statuscode="403" statustext="Forbidden"/><cfabort/>
</cfif>
<cfset VARIABLES.inscricaoError = ""/>
<cfset VARIABLES.inscricaoSaved = false/>
<cfif structKeyExists(FORM, "action") AND FORM.action EQ "confirmar_inscricao_disponibilidade">
    <cfinclude template="../../../includes/backend/require_admin.cfm"/>
    <cfset URL.sessao = "inscricoes"/>
    <cftry>
        <cfset VARIABLES.inscricaoCsrfValid = structKeyExists(FORM, "inscricao_csrf") AND csrfVerifyToken(FORM.inscricao_csrf, "event-registration-availability")/>
        <cfif NOT structKeyExists(FORM, "id_evento") OR NOT reFind("^[1-9][0-9]*$", FORM.id_evento)
            OR NOT isNumeric(URL.id_evento) OR val(FORM.id_evento) NEQ val(URL.id_evento)>
            <cfthrow type="RegistrationAvailability.Validation" message="Reabra o evento para confirmar suas inscrições."/>
        </cfif>
        <cfset VARIABLES.inscricaoService = new services.EventRegistrationAvailabilityService()/>
        <cfif NOT VARIABLES.inscricaoService.isSchemaReady()>
            <cfthrow type="RegistrationAvailability.Validation" message="A confirmação de inscrições ainda não está disponível. Tente novamente após a atualização."/>
        </cfif>
        <cfset VARIABLES.inscricaoService.save(
            eventId=val(FORM.id_evento), actorId=val(REQUEST.businessIdentity.id), submission=FORM,
            isAdmin=VARIABLES.requireAdminAllowed, isPost=cgi.request_method EQ "POST", csrfVerified=VARIABLES.inscricaoCsrfValid,
            remoteAddress=cgi.remote_addr
        )/>
        <cfset VARIABLES.inscricaoSaved = true/>
        <cfcatch type="RegistrationAvailability">
            <cfset VARIABLES.inscricaoError = cfcatch.message/>
        </cfcatch>
        <cfcatch type="any">
            <cflog file="application" type="error" text="Registration availability save failed for event #val(URL.id_evento)#; type #cfcatch.type#"/>
            <cfset VARIABLES.inscricaoError = "Não foi possível salvar a confirmação. Reabra a página e tente novamente."/>
        </cfcatch>
    </cftry>
</cfif>
