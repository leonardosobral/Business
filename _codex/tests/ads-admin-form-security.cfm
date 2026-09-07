<!--- Explicit local-process opt-in; never set this in a web-server environment. --->
<cfset offlineFormEnvironment=createObject("java","java.lang.System").getenv()/>
<cfif NOT offlineFormEnvironment.containsKey("RUNNERHUB_OFFLINE_CFML_TESTS")
    OR offlineFormEnvironment.get("RUNNERHUB_OFFLINE_CFML_TESTS") NEQ "1">
    <cfheader statuscode="404" statustext="Not Found"/><cfabort/>
</cfif>
<!--- Run with CommandBox: box execute _codex/tests/ads-admin-form-security.cfm.
      Executes the production output/validation fragments in CFML, without
      loading Application.cfc, querying a datasource or mutating business data. --->
<cfscript>
securityRepoRoot = getDirectoryFromPath(getCurrentTemplatePath()) & "../../";
securityScratch = getTempDirectory() & "ads-admin-form-security-" & createUUID();
directoryCreate(securityScratch);
securityFailures = [];
securityChecks = 0;
securitySequence = 0;

function securityAssert(required boolean condition, required string label) {
    variables.securityChecks++;
    if (!arguments.condition) arrayAppend(variables.securityFailures, arguments.label);
}

function securityRender(required string source) {
    variables.securitySequence++;
    var fragment = variables.securityScratch & "/fragment-" & variables.securitySequence & ".cfm";
    var rendered = "";
    fileWrite(fragment, arguments.source, "utf-8");
    savecontent variable="rendered" { include fragment; }
    return rendered;
}

try {
    securityBannerSource = fileRead(securityRepoRoot & "portal/banners/home.cfm", "utf-8");
    securityBannerBackend = fileRead(securityRepoRoot & "portal/includes/banner_management_backend.cfm", "utf-8");
    securityRender(left(securityBannerBackend, find("</cfscript>", securityBannerBackend) + len("</cfscript>") - 1));
    securityBannerActionAt = find('<cfif len(trim(FORM.acao & ""))>', securityBannerBackend);
    securityBannerActionEnd = find('<cfif VARIABLES.bannerManagementApiReady>', securityBannerBackend, securityBannerActionAt);
    securityBannerAction = mid(securityBannerBackend, securityBannerActionAt, securityBannerActionEnd - securityBannerActionAt);
    VARIABLES.bannerManagementIsAdmin = true;
    VARIABLES.bannerManagementActorId = 123;
    VARIABLES.bannerManagementApiReady = true;
    VARIABLES.bannerManagementCsrf = "valid-session-token";
    VARIABLES.bannerUploadDiskPath = securityScratch & "/";
    FORM.acao = "salvar_banner";
    FORM.banner_id = "";
    securityBannerFields = [
        "banner_largura", "banner_altura", "banner_mobile_largura", "banner_mobile_altura",
        "banner_peso_exibicao", "banner_prioridade", "banner_inicio_exibicao", "banner_fim_exibicao"
    ];
    securityPayloads = [
        '"/><img src=x onerror=alert(1)>',
        '" autofocus onfocus="alert(1)'
    ];
    qBannerManagementEdit = queryNew("id_banner");
    for (securityField in securityBannerFields) {
        securityInputs = reMatch('(?m)^[^\r\n]*<input[^\r\n]*name="' & securityField & '"[^\r\n]*$', securityBannerSource);
        if (arrayLen(securityInputs) != 1) throw(message="Expected one production banner input: " & securityField);
        for (securityCsrf in ["valid-session-token", "invalid-token"]) {
            FORM.banner_csrf = securityCsrf;
            for (securityPayload in securityPayloads) {
                FORM[securityField] = securityPayload;
                VARIABLES.bannerManagementAlert = { type="", message="" };
                securityRender(securityBannerAction);
                securityAssert(VARIABLES.bannerManagementAlert.type == "danger",
                    securityField & " reaches the real validation catch with " & securityCsrf);
                securityOutput = securityRender(securityInputs[1]);
                securityValueMatch = reFind('value="([^"]*)"', securityOutput, 1, true);
                securityDecodedValue = "";
                if (arrayLen(securityValueMatch.pos) == 2 AND securityValueMatch.len[2] > 0) {
                    securityRawValue = mid(securityOutput, securityValueMatch.pos[2], securityValueMatch.len[2]);
                    securityDecodedValue = xmlParse('<value data="' & securityRawValue & '"/>').xmlRoot.xmlAttributes.data;
                }
                securityAssert(securityDecodedValue == securityPayload AND !findNoCase("<img", securityOutput),
                    securityField & " remains one inert attribute after " & securityCsrf);
            }
        }
        securityOrdinaryValue = find("exibicao", securityField) AND find("banner_peso", securityField) == 0
            ? "2026-09-07T09:30" : "300";
        FORM[securityField] = securityOrdinaryValue;
        securityOutput = securityRender(securityInputs[1]);
        securityAssert(find('value="' & securityOrdinaryValue & '"', securityOutput) > 0,
            securityField & " preserves its ordinary value");
    }

    securityBackend = fileRead(securityRepoRoot & "administracao/contas/includes/backend.cfm", "utf-8");
    securityActionAt = find('AND isDefined("FORM.account_registration_action")', securityBackend);
    securityActionStart = findLast("<cfif", left(securityBackend, securityActionAt));
    securityTransactionAt = find("<cftransaction>", securityBackend, securityActionAt);
    securityValidationEnd = findLast('<cfif NOT arrayLen(VARIABLES.accountRegistrationErrors)>',
        left(securityBackend, securityTransactionAt));
    if (!securityActionStart OR !securityValidationEnd) throw(message="Registration validation boundary not found");
    securityValidation = mid(securityBackend, securityActionStart, securityValidationEnd - securityActionStart)
        & '<cfset VARIABLES.securityWouldReview = NOT arrayLen(VARIABLES.accountRegistrationErrors)/></cfif>';
    // CGI is the request adapter. Inject only this external value, keeping the
    // actual production CFML decisions and error accumulation unchanged.
    securityValidation = replaceNoCase(securityValidation, "CGI.request_method", "VARIABLES.securityRequestMethod", "all");
    VARIABLES.businessAccountsTablesReady = true;
    VARIABLES.businessAccountRegistrationTableReady = true;
    securityCases = [
        { label="approve without token", action="aprovar", method="POST", posted="", server="known-session-token", allowed=false },
        { label="reject without token", action="recusar", method="POST", posted="", server="known-session-token", allowed=false },
        { label="sibling-origin guessed token", action="aprovar", method="POST", posted="attacker-token", server="known-session-token", allowed=false },
        { label="expired session token", action="recusar", method="POST", posted="known-session-token", server="", allowed=false },
        { label="GET with token", action="aprovar", method="GET", posted="known-session-token", server="known-session-token", allowed=false },
        { label="ordinary approval", action="aprovar", method="POST", posted="known-session-token", server="known-session-token", allowed=true },
        { label="ordinary rejection", action="recusar", method="POST", posted="known-session-token", server="known-session-token", allowed=true }
    ];
    for (securityCase in securityCases) {
        FORM.account_registration_action = securityCase.action;
        FORM.id_solicitacao = "123";
        FORM.business_account_access_csrf = securityCase.posted;
        VARIABLES.businessAccountContextCsrf = securityCase.server;
        VARIABLES.securityRequestMethod = securityCase.method;
        securityRender(securityValidation);
        securityAssert(VARIABLES.securityWouldReview == securityCase.allowed,
            securityCase.label & " permission to reach the review transaction");
    }
    structDelete(FORM, "business_account_access_csrf");
    VARIABLES.businessAccountContextCsrf = "known-session-token";
    securityRender(securityValidation);
    securityAssert(!VARIABLES.securityWouldReview, "missing token field cannot reach the review transaction");
    FORM.business_account_access_csrf = "known-session-token";
    structDelete(VARIABLES, "businessAccountContextCsrf");
    securityRender(securityValidation);
    securityAssert(!VARIABLES.securityWouldReview, "missing session token cannot reach the review transaction");
    VARIABLES.businessAccountContextCsrf = "known-session-token";

    securityHome = fileRead(securityRepoRoot & "administracao/contas/home.cfm", "utf-8");
    securityDecisionStart = find('<form method="post" action="./" class="accounts-request-decision">', securityHome);
    securityDecisionEnd = find("</form>", securityHome, securityDecisionStart) + len("</form>");
    securityDecision = "<cfoutput>" & mid(securityHome, securityDecisionStart, securityDecisionEnd - securityDecisionStart) & "</cfoutput>";
    qBusinessAccountRegistrationAccountOptions = queryNew("id_conta,nome_conta,documento,status");
    for (securityRole in ["OWNER", "ADMIN"]) {
        VARIABLES.businessAccountsCanAdminAll = securityRole == "ADMIN";
        qBusinessAccountRegistrationRequests = queryNew("id_solicitacao,status_conta", "integer,varchar",
            [{ id_solicitacao=123, status_conta=securityRole == "OWNER" ? "ATIVA" : "PENDENTE" }]);
        securityOutput = securityRender(securityDecision);
        securityAssert(reFind('name="business_account_access_csrf"[^>]*value="known-session-token"', securityOutput) > 0,
            securityRole & " decision form carries the session token");
        securityAssert(find('value="aprovar"', securityOutput) > 0 AND find('value="recusar"', securityOutput) > 0,
            securityRole & " retains approval and rejection controls");
    }
} finally {
    directoryDelete(securityScratch, true);
}

for (securityFailure in securityFailures) writeOutput("FAIL: " & securityFailure & chr(10));
writeOutput("ADS ADMIN FORM SECURITY: " & (arrayLen(securityFailures) ? "FAIL" : "PASS")
    & " (" & securityChecks & " checks, " & arrayLen(securityFailures) & " failures)" & chr(10));
if (arrayLen(securityFailures)) throw(type="SecurityRegression", message="Admin form security checks failed", detail=arrayToList(securityFailures, "; "));
</cfscript>
