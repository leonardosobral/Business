<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="120"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfinclude template="../../administracao/agenda/includes/service.cfm"/>
<cfinclude template="ga4_service.cfm"/>
<cfheader name="Cache-Control" value="private, no-store"/>
<cfcontent type="application/json; charset=utf-8" reset="true"/>
<cfscript>
try {
    if(CGI.request_method!="POST" || !structKeyExists(session,"seoGa4Csrf") || !structKeyExists(form,"csrf_token") || !isSimpleValue(form.csrf_token) || compare(form.csrf_token,session.seoGa4Csrf)!=0) throw(type="GA4.Forbidden",message="Sessão expirada. Recarregue a página.");
    if(!agendaReady()) ga4Fail("Configure a conexão Google do Business na Agenda.");
    action=agendaInput("action");result={};
    if(action=="connect") {
        lock name="RunnerHubBusiness.GoogleAgenda" type="exclusive" timeout="15" {result=ga4OAuth();}
    } else {
        if(action=="status") result={"authorized"=ga4Authorized()};
        else {
            if(!ga4Authorized()) ga4Fail("Autorize a leitura do Google Analytics para continuar.");
            lock name="RunnerHubBusiness.SeoGa4" type="exclusive" timeout="90" {
                if(action=="properties") result={"properties"=ga4Properties()};
                else if(action=="report") {
                    if(!reFind("^(7|28|90)$",agendaInput("days"))) ga4Fail("Período inválido.");
                    result=ga4Report(agendaInput("property"),val(agendaInput("days")));
                } else ga4Fail("Operação inválida.");
            }
        }
    }
    writeOutput(serializeJSON({"success"=true,"data"=result}));
} catch(any error) {
    cfheader(statuscode=error.type=="GA4.Forbidden"?403:400);
    writeOutput(serializeJSON({"success"=false,"message"=listFind("GA4.Validation,GA4.Forbidden,Agenda.Validation",error.type)?error.message:"Não foi possível consultar o Analytics. Tente novamente em alguns minutos."}));
}
</cfscript>
