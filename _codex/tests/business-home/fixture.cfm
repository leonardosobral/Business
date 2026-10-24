<cfscript>
setLocale("Portuguese (Brazilian)");
scenario = createObject("java","java.lang.System").getenv("BUSINESS_HOME_SCENARIO");
VARIABLES.businessEffectiveIsAdmin=true;
VARIABLES.businessHomeMetrics = {
 days=7,
 audience={loaded=true,comparison_ready=true,interactions_comparison_ready=true,visitors=120,pageviews=420,interactions=30,previous_visitors=100,previous_pageviews=400,previous_interactions=20},
 ads={loaded=true,comparison_ready=true,impressions=1400,clicks=80,cost=75,event_cost=50,banner_cost=25,previous_impressions=1000,previous_clicks=60,previous_cost=50,previous_event_cost=30,previous_banner_cost=20},
 users={loaded=true,comparison_ready=true,new_count=14,previous_new_count=10},
 accounts={loaded=true,comparison_ready=true,new_count=3,previous_new_count=0}
};
VARIABLES.businessHomeSignals = [
 {label="Contas para aprovar",description="Solicitações aguardando decisão",value=3,loaded=true,href="/administracao/contas/",icon="fa-building",kind="Aprovação",priority=20},
 {label="Fila sem pendência",description="Não deve aparecer",value=0,loaded=true,href="/ads/",icon="fa-bullhorn",kind="Aprovação",priority=20}
];
VARIABLES.businessAdminHomeContentLoaded=true;
VARIABLES.businessAdminHomeContentTotal=10;
VARIABLES.businessAdminHomeContentComplete=7;
VARIABLES.businessAdminHomeContentNext30=2;
VARIABLES.businessAdminHomeContentCritical=1;
VARIABLES.businessAdminHomeNotificationsLoaded=true;
VARIABLES.businessAdminHomeNotifications7d=0;
VARIABLES.businessAdminHomeNotificationsRead7d=0;
VARIABLES.businessAdminHomeNotificationReadRate7d=0;
if(scenario EQ "clear") {
 VARIABLES.businessHomeSignals[1].value=0;
} else if(scenario EQ "unavailable") {
 VARIABLES.businessHomeSignals[1].loaded=false;
 VARIABLES.businessHomeMetrics.audience.loaded=false;
} else if(scenario EQ "unsafe") {
 VARIABLES.businessHomeSignals[1].label="<script>alert(1)</script>";
 URL.home_area="<script>alert(1)</script>";
} else if(scenario EQ "split-comparison") {
 VARIABLES.businessHomeMetrics.audience.interactions_comparison_ready=false;
} else if(scenario EQ "tabs") {
 VARIABLES.businessHomeMetrics.days=30;
 URL.home_area="contas";
}
</cfscript>
<cfinclude template="../../../includes/estrutura/home_admin_decision_view.cfm"/>
