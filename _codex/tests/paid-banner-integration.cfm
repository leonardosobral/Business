<cfscript>
if (createObject("java", "java.lang.System").getenv("RUNNERHUB_OFFLINE_CFML_TESTS") != "1") abort;

root = getDirectoryFromPath(getCurrentTemplatePath()) & "../../";

function check(required boolean ok, required string label) {
    if (!arguments.ok) throw(message="FAIL: " & arguments.label);
    writeOutput("PASS: " & arguments.label & chr(10));
}

function businessHasPermission(required string permission) {
    return false;
}

function renderPendingNavigation(required boolean existingAccountRequest) {
    var rendered = "";
    REQUEST.businessIdentity = {id=912};
    VARIABLES.template = "/portal/banners/";
    VARIABLES.businessPendingWorkspace = true;
    VARIABLES.businessPendingExistingAccountRequest = arguments.existingAccountRequest;
    VARIABLES.businessEffectiveIsAdmin = false;
    VARIABLES.businessEffectiveAccountIds = "0";
    VARIABLES.businessEffectiveAccountOperatorIds = "0";
    VARIABLES.qPerfil = queryNew(
        "id,is_admin,is_dev,is_partner",
        "integer,bit,bit,bit",
        [{id=912,is_admin=false,is_dev=false,is_partner=false}]
    );
    savecontent variable="rendered" {
        include root & "includes/estrutura/sidenav.cfm";
    }
    return rendered;
}

include root & "includes/backend/business_pending_access.cfm";
include root & "portal/includes/paid_banner_helpers.cfm";

check(
    businessPendingTemplateAllowed("/portal/banners/", false),
    "new-account pending owner may open the paid banner workspace"
);
check(
    !businessPendingTemplateAllowed("/portal/banners/", true)
        && businessPendingTemplateAllowed("/suporte/", true),
    "existing-account pending request stays denied while support remains available"
);

qPerfil = queryNew("id", "integer", [{id=912}]);
VARIABLES.businessActiveAccountId = 0;
VARIABLES.businessPendingWorkspace = true;
VARIABLES.businessPendingExistingAccountRequest = false;
VARIABLES.businessPendingAccountId = 44;
VARIABLES.businessPendingRegistrationId = 55;
VARIABLES.businessPendingAccountRole = "OWNER";
VARIABLES.businessCurrentAccountRole = "";
VARIABLES.businessRealIsAdmin = false;
include root & "ads/includes/access.cfm";
check(
    VARIABLES.adsAccessAccountId == 44
        && VARIABLES.adsAccessActorId == 912
        && VARIABLES.adsAccessIsPendingNewAccount
        && VARIABLES.adsAccessCanView
        && VARIABLES.adsAccessCanManageCampaign,
    "authenticated pending owner receives account-scoped banner capabilities"
);

VARIABLES.businessPendingExistingAccountRequest = true;
include root & "ads/includes/access.cfm";
check(
    VARIABLES.adsAccessAccountId == 0
        && !VARIABLES.adsAccessIsPendingNewAccount
        && !VARIABLES.adsAccessCanView
        && !VARIABLES.adsAccessCanManageCampaign,
    "pending request for an existing account receives no banner capability"
);

newPendingNav = renderPendingNavigation(false);
existingPendingNav = renderPendingNavigation(true);
check(
    find('href="/portal/banners/"', newPendingNav) > 0,
    "pending-new-owner navigation renders a Banners destination"
);
check(
    find('href="/portal/banners/"', existingPendingNav) == 0
        && find("Aguardando acesso", existingPendingNav) > 0,
    "existing-account pending navigation renders no Banners destination"
);

check(
    paidBannerWorkspaceView({}, {}, true) == "paid"
        && paidBannerWorkspaceView({view="house"}, {}, true) == "house",
    "admin route defaults to paid banners and selects HOUSE only explicitly"
);
routeRejected = false;
try {
    paidBannerWorkspaceView({view="house"}, {}, false);
} catch (AdsV1.Validation expected) {
    routeRejected = true;
}
check(routeRejected, "account member cannot route into HOUSE administration");

// Wiring and legacy URL retention are audited statically; authorization,
// navigation, routing decisions, rendering and SQL parameters execute above
// or in the focused render/query suites.
indexSource = fileRead(root & "portal/banners/index.cfm");
homeSource = fileRead(root & "portal/banners/home.cfm");
houseBackendSource = fileRead(root & "portal/includes/banner_management_backend.cfm");
houseFormSource = fileRead(root & "portal/includes/banner_form.cfm");
houseListSource = fileRead(root & "portal/includes/banner_dashboard_list.cfm");
check(
    find('template="../../ads/includes/access.cfm"', indexSource) > 0
        && find('template="../../includes/backend/require_admin.cfm"', indexSource) == 0
        && find('template="../includes/paid_banner_backend.cfm"', homeSource) > 0
        && find('template="../includes/paid_banner_home.cfm"', homeSource) > 0,
    "AUDIT: route wiring loads capability access and the paid workspace includes"
);
check(
    find("view=house", houseBackendSource) > 0
        && find("view=house", houseFormSource) > 0
        && find("view=house", houseListSource) > 0,
    "AUDIT: HOUSE redirects, forms and row links retain the explicit view"
);

writeOutput("PAID BANNER INTEGRATION PASS" & chr(10));
</cfscript>
