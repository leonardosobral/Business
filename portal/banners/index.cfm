<cfprocessingdirective pageencoding="utf-8"/>

<cfsilent>
<cfset VARIABLES.theme = "dark"/>
<cfset VARIABLES.template = "/portal/banners/"/>

<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../ads/includes/access.cfm"/>
<cfinclude template="../includes/paid_banner_helpers.cfm"/>
<cfset VARIABLES.paidBannerWorkspaceView = paidBannerWorkspaceView(URL, FORM, VARIABLES.adsAccessCanReviewCampaign)/>
<cfif VARIABLES.paidBannerWorkspaceView EQ "paid">
<cfinclude template="../includes/paid_banner_backend.cfm"/>
<cfelse>
<cfinclude template="../includes/banner_management_backend.cfm"/>
<cfinclude template="../includes/banner_dashboard_backend.cfm"/>
</cfif>
</cfsilent>
<!DOCTYPE html>
<html lang="pt-br">
<cfinclude template="../../includes/estrutura/head.cfm"/>

<body data-mdb-theme="dark" class="bg-dark-subtle">
    <cfinclude template="../../includes/estrutura/header.cfm"/>

    <main class="" style="margin-top: -55px;">
      <div class="container-fluid px-4">
        <cfinclude template="home.cfm">
      </div>
    </main>

    <cfinclude template="../../includes/estrutura/footer.cfm"/>
</body>

</html>
