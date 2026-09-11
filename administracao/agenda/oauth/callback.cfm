<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="90"/>
<cfinclude template="../../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../../includes/backend/require_admin.cfm"/>
<cfinclude template="../includes/service.cfm"/>
<cfheader name="Cache-Control" value="no-store"/>
<cfheader name="Referrer-Policy" value="no-referrer"/>
<cfscript>
try {
    lock name="RunnerHubBusiness.GoogleAgenda" type="exclusive" timeout="60" {
        if (!structKeyExists(session,"agendaOAuth") || !structKeyExists(url,"state") || compare(url.state,session.agendaOAuth.state)!=0 || session.agendaOAuth.actor!=val(qPerfil.id) || dateCompare(now(),session.agendaOAuth.expires)>0) agendaFail("A autorização expirou ou é inválida. Clique em Conectar Google novamente.");
        oauth=session.agendaOAuth;
        structDelete(session,"agendaOAuth");
        if (structKeyExists(url,"error") || !structKeyExists(url,"code")) agendaFail("A autorização foi cancelada. Tente conectar novamente.");
        c=agendaConfig();
        token=agendaHttp("https://oauth2.googleapis.com/token","POST",{"client_id"=c.CLIENT_ID,"client_secret"=c.CLIENT_SECRET,"code"=url.code,"code_verifier"=oauth.verifier,"redirect_uri"=c.redirectUri,"grant_type"="authorization_code"},{},"","",true);
        if (token.status!=200 || !structKeyExists(token.data,"access_token")) agendaFail("O Google não concluiu a autorização. Verifique o cliente OAuth e o endereço de retorno.");
        identity=agendaHttp("https://openidconnect.googleapis.com/v1/userinfo","GET",{},{},token.data.access_token);
        if (identity.status!=200 || !structKeyExists(identity.data,"email") || !structKeyExists(identity.data,"email_verified") || !identity.data.email_verified || !structKeyExists(identity.data,"sub") || compareNoCase(identity.data.email,c.email)!=0) agendaFail("Conecte exclusivamente a conta contato@runnerhub.run.");
        if (!structKeyExists(token.data,"scope")) agendaFail("O Google não informou as permissões autorizadas.");
        for (scope in ["https://www.googleapis.com/auth/calendar.calendarlist.readonly","https://www.googleapis.com/auth/calendar.events.owned","https://www.googleapis.com/auth/meetings.space.readonly"]) if (!listFind(token.data.scope,scope," ")) agendaFail("Autorize todas as permissões de Agenda e Google Meet solicitadas.");
        if (!structKeyExists(token.data,"refresh_token") || !len(token.data.refresh_token)) agendaFail("O Google não forneceu acesso offline. Remova a autorização antiga na Conta Google e conecte novamente.");
        audit=agendaAudit("connect");
        transaction {
            agendaDb("INSERT INTO public.tb_google_agenda_conexao(id,email,google_sub,refresh_token,scopes) VALUES(1,:email,:sub,:token,:scopes) ON CONFLICT(id) DO UPDATE SET email=EXCLUDED.email,google_sub=EXCLUDED.google_sub,refresh_token=EXCLUDED.refresh_token,scopes=EXCLUDED.scopes,atualizado_em=now()",{email=agendaParam(c.email),sub=agendaParam(identity.data.sub),token=agendaParam(agendaSeal(token.data.refresh_token)),scopes=agendaParam(token.data.scope)});
            agendaAuditEnd(audit,"success");
        }
        structDelete(application,"agendaAccess");
        session.agendaMessage="Conta conectada. Abra Configurar agendas para escolher as agendas disponíveis no Business.";
    }
} catch(any error) {
    session.agendaMessage=error.type=="Agenda.Validation" ? error.message : "Não foi possível conectar a Agenda. Verifique a configuração do servidor e tente novamente.";
}
location(url="/administracao/agenda/",addtoken=false);
</cfscript>
