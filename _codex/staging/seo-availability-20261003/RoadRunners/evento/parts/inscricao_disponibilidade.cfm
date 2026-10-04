<cfif getBaseTemplatePath() EQ getCurrentTemplatePath()><cfheader statuscode="403"/><cfabort/></cfif>
<cfif VARIABLES.eventRegistrationAvailability.confirmed>
    <cfscript>
    VARIABLES.registrationLang = structKeyExists(REQUEST, "lang") ? lCase(REQUEST.lang) : "pt-br";
    VARIABLES.registrationLabels = {
        "pt-br"={open="Inscrições abertas", sold_out="Vagas esgotadas", preorder="Pré-venda de inscrições disponível", closed="Inscrições encerradas", source="Fonte oficial", checked="Verificado em"},
        en={open="Registration open", sold_out="Tickets sold out", preorder="Registration available for preorder", closed="Registration closed", source="Official source", checked="Checked on"},
        es={open="Inscripciones abiertas", sold_out="Cupos agotados", preorder="Preventa de inscripciones disponible", closed="Inscripciones cerradas", source="Fuente oficial", checked="Verificado el"}
    };
    if (!structKeyExists(VARIABLES.registrationLabels, VARIABLES.registrationLang)) VARIABLES.registrationLang = "pt-br";
    VARIABLES.registrationText = VARIABLES.registrationLabels[VARIABLES.registrationLang];
    VARIABLES.registrationCheckedDate = createObject("java", "java.util.Date").init(javaCast("long", VARIABLES.eventRegistrationAvailability.checked_at*1000));
    </cfscript>
    <div class="alert alert-light mb-3" role="status">
        <strong><cfoutput>#VARIABLES.registrationText[VARIABLES.eventRegistrationAvailability.status]#</cfoutput></strong>
        <div class="small mt-1">
            <cfoutput>#VARIABLES.registrationText.checked# #dateTimeFormat(VARIABLES.registrationCheckedDate, 'dd/mm/yyyy HH:nn')# &middot;
                <a href="#encodeForHTMLAttribute(VARIABLES.eventRegistrationAvailability.source_url)#" target="_blank" rel="noopener noreferrer">#VARIABLES.registrationText.source#</a>
            </cfoutput>
        </div>
    </div>
</cfif>
