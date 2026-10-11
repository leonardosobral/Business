<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfset VARIABLES.factReviewError=""/>
<cfset VARIABLES.factReviewSaved=false/>
<cfset VARIABLES.factReviewRevoked=false/>
<cfset VARIABLES.factReviewPublication=""/>
<cfif structKeyExists(FORM,"action") AND isSimpleValue(FORM.action) AND listFind("conferir_fatos_evento,retirar_conferencia_evento,publicar_datas_conferidas,ocultar_datas_conferidas",FORM.action)>
    <cfinclude template="../../../includes/backend/require_admin.cfm"/>
    <cfset URL.sessao="fontes"/>
    <cftry>
        <cfset VARIABLES.factReviewService=new services.EventFactReviewService()/>
        <cfset VARIABLES.factReviewDelegated=structKeyExists(REQUEST,"businessAccessContext") AND REQUEST.businessAccessContext.accessMode EQ "DELEGATED"/>
        <cfset VARIABLES.factReviewCsrf=structKeyExists(FORM,"fact_csrf") AND isSimpleValue(FORM.fact_csrf) AND csrfVerifyToken(FORM.fact_csrf,"event-fact-review")/>
        <cfset VARIABLES.factReviewService.authorize(VARIABLES.requireAdminAllowed,VARIABLES.factReviewDelegated,CGI.request_method EQ "POST",VARIABLES.factReviewCsrf,true)/>
        <cfif NOT structKeyExists(FORM,"id_evento") OR NOT isSimpleValue(URL.id_evento) OR VARIABLES.factReviewService.identifier(FORM.id_evento) NEQ VARIABLES.factReviewService.identifier(URL.id_evento)>
            <cfthrow type="FactReview.Validation" message="Reabra o evento para conferir suas fontes."/>
        </cfif>
        <cfif NOT VARIABLES.factReviewService.isSchemaReady()><cfthrow type="FactReview.Validation" message="A revisão de fontes ainda não está disponível."/></cfif>
        <cfif FORM.action EQ "conferir_fatos_evento">
            <cfset VARIABLES.factReviewService.save(FORM.id_evento,FORM,VARIABLES.requireAdminAllowed,VARIABLES.factReviewDelegated,CGI.request_method EQ "POST",VARIABLES.factReviewCsrf)/>
            <cfset VARIABLES.factReviewSaved=true/>
        <cfelse>
            <cfif NOT structKeyExists(FORM,"id_revisao")><cfthrow type="FactReview.Validation" message="Selecione uma conferência válida."/></cfif>
            <cfif FORM.action EQ "publicar_datas_conferidas">
                <cfif NOT structKeyExists(FORM,"publish_confirmed") OR NOT isSimpleValue(FORM.publish_confirmed) OR FORM.publish_confirmed NEQ "1"><cfthrow type="FactReview.Validation" message="Confirme a publicação da fonte e da data de conferência no RoadRunners."/></cfif>
                <cfset VARIABLES.factReviewService.publishDates(FORM.id_evento,FORM.id_revisao,VARIABLES.requireAdminAllowed,VARIABLES.factReviewDelegated,CGI.request_method EQ "POST",VARIABLES.factReviewCsrf)/>
                <cfset VARIABLES.factReviewPublication="Fonte das datas publicada no RoadRunners."/>
            <cfelseif FORM.action EQ "ocultar_datas_conferidas">
                <cfset VARIABLES.factReviewService.unpublishDates(FORM.id_evento,FORM.id_revisao,VARIABLES.requireAdminAllowed,VARIABLES.factReviewDelegated,CGI.request_method EQ "POST",VARIABLES.factReviewCsrf)/>
                <cfset VARIABLES.factReviewPublication="Publicação retirada do RoadRunners. A conferência interna foi preservada."/>
            <cfelse>
            <cfset VARIABLES.factReviewService.revoke(FORM.id_evento,FORM.id_revisao,VARIABLES.requireAdminAllowed,VARIABLES.factReviewDelegated,CGI.request_method EQ "POST",VARIABLES.factReviewCsrf)/>
            <cfset VARIABLES.factReviewRevoked=true/>
            </cfif>
        </cfif>
        <cfcatch type="FactReview"><cfset VARIABLES.factReviewError=cfcatch.message/></cfcatch>
    </cftry>
</cfif>
