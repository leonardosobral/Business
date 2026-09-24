<cfscript>
function businessPendingAllowedTemplates(required boolean existingAccountRequest) {
    return arguments.existingAccountRequest
        ? "/,/faq/,/suporte/"
        : "/,/portal/banners/,/eventos/,/ads/,/faq/,/suporte/";
}

function businessPendingTemplateAllowed(required string template, required boolean existingAccountRequest) {
    return listFindNoCase(
        businessPendingAllowedTemplates(arguments.existingAccountRequest),
        arguments.template
    ) GT 0;
}
</cfscript>
