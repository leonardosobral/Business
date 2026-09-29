<cfscript>
checks = 0;
function check(required boolean ok, required string label) {
    if (!arguments.ok) throw(message="FAIL: " & arguments.label);
    checks++;
}
queryExecute("CREATE EXTENSION unaccent");
queryExecute("CREATE TABLE tb_usuarios (id integer primary key, name text, email text, is_admin boolean)");
queryExecute("CREATE TABLE tb_notifica_template (id_notifica_template integer primary key, campanha text)");
queryExecute("CREATE TABLE tb_notifica (id_notifica integer primary key, id_usuario integer, id_notifica_template integer, data_publicacao timestamp, data_expiracao timestamp, data_leitura timestamp, link text, icone text, conteudo_notifica text)");
queryExecute("CREATE TABLE tb_transacoes (id_usuario integer, status_atual text, valor_transacao numeric)");
queryExecute("CREATE TABLE desafios (id_usuario integer, desafio text, status integer, data_inscricao timestamp)");
queryExecute("INSERT INTO tb_usuarios VALUES (1,'Atleta','atleta@example.test',false),(2,'Admin','admin@example.test',true),(3,'Legado','legado@example.test',null)");
queryExecute("INSERT INTO tb_notifica_template VALUES (10,'Promo'),(11,'Outro')");
queryExecute("INSERT INTO tb_notifica (id_notifica,id_usuario,id_notifica_template,data_publicacao,data_leitura) VALUES
 (1,1,10,now()-interval '1 hour',now()),(2,1,10,now()-interval '1 hour',null),
 (3,2,10,now()-interval '1 hour',now()),(4,2,11,now()-interval '1 hour',null),
 (5,3,10,now()-interval '1 hour',null),(6,999,10,now()-interval '1 hour',now()),
 (7,1,11,now()-interval '20 days',now()),(8,1,10,now()+interval '2 days',null)");
structClear(URL); structClear(FORM);
</cfscript>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cfscript>
check(qNotificaHistoricoStats.total == 5, 'default excludes admins and unknown recipients');
check(qNotificaHistoricoStats.total_lidas == 2, 'default read count');
check(notificaReadRate == 40, 'default read rate');
check(qNotificaHistoricoCount.total == qNotificaHistoricoStats.total, 'count and stats agree');
URL.publico='admins';
</cfscript>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cfscript>
check(qNotificaHistorico.recordCount == 2 && qNotificaHistoricoStats.total_lidas == 1, 'admin segment');
URL.publico='todos';
</cfscript>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cfscript>
check(qNotificaHistoricoCount.total == 8, 'all includes orphan records');
URL.publico='invalid';
</cfscript>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cfscript>
check(notificaPublico == 'usuarios' && qNotificaHistoricoCount.total == 5, 'invalid audience falls back safely');
URL.publico='usuarios'; URL.campanha='Promo'; URL.leitura='lidas';
</cfscript>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cfscript>
check(qNotificaHistoricoCount.total == 1 && qNotificaHistorico.id_notifica[1] == 1, 'campaign and read filters match list and metrics');
URL.campanha=''; URL.leitura='';
URL.data_publicacao_inicial=dateFormat(dateAdd('d',-1,now()),'yyyy-mm-dd');
URL.data_publicacao_final=dateFormat(now(),'yyyy-mm-dd'); URL.pagina=999;
</cfscript>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cfscript>
check(qNotificaHistoricoCount.total == 3 && qNotificaHistorico.recordCount == 3, 'date range and page clamping');
check(notificaPage == 1, 'page clamped');
URL.busca="nothing' OR 1=1 --";
</cfscript>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cfscript>
check(qNotificaHistoricoCount.total == 0 && notificaReadRate == 0, 'empty and SQL-looking search safe');
</cfscript>
<cfinclude template="home_stats.cfm"/>
<cfscript>
check(qBusinessAdminHomeNotificationStats.total == 3 && qBusinessAdminHomeNotificationStats.lidas == 1, 'home excludes admin, orphan, old and future notifications');
structClear(URL); URL.publico='admins';
</cfscript>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cftransaction>
    <cfinclude template="bulk_deactivate.cfm"/>
    <cfquery name="changed">SELECT count(*) AS n FROM tb_notifica WHERE data_expiracao IS NOT NULL</cfquery>
    <cfset check(changed.n == 2, 'bulk deactivate scoped to admins')/>
    <cftransaction action="rollback"/>
</cftransaction>
<cftransaction>
    <cfinclude template="bulk_delete.cfm"/>
    <cfquery name="remaining">SELECT count(*) AS n FROM tb_notifica</cfquery>
    <cfset check(remaining.n == 6, 'bulk delete scoped to admins')/>
    <cftransaction action="rollback"/>
</cftransaction>
<cfset VARIABLES.template='/notificacoes/'/>
<cfsavecontent variable="rendered"><cfinclude template="../../notificacoes/home.cfm"/></cfsavecontent>
<cfset check(find('publico=admins',rendered) GT 0, 'rendered links retain audience')/>
<cfset check(find('aria-current="page"',rendered) GT 0, 'active audience accessible')/>
<cfset check(find('>Clicks<',rendered) EQ 0, 'read label is not clicks')/>
<cfset structClear(URL)/>
<cfset URL.publico='usuarios'/>
<cfset URL.campanha='Promo'/>
<cfset URL.leitura='lidas'/>
<cfinclude template="../../notificacoes/includes/backend.cfm"/>
<cftransaction>
    <cfinclude template="bulk_deactivate.cfm"/>
    <cfquery name="changedUser">SELECT id_notifica FROM tb_notifica WHERE data_expiracao IS NOT NULL</cfquery>
    <cfset check(changedUser.recordCount == 1 AND changedUser.id_notifica[1] == 1, 'bulk action also preserves campaign and read filters')/>
    <cftransaction action="rollback"/>
</cftransaction>
<cfsavecontent variable="renderedFilters"><cfinclude template="../../notificacoes/home.cfm"/></cfsavecontent>
<cfset check(find('campanha=Promo',renderedFilters) GT 0 AND find('leitura=lidas',renderedFilters) GT 0, 'audience links keep filters')/>
<cfset structClear(URL)/>
<cfset URL.publico='usuarios'/>
<cfset URL.busca='no matches'/>
<cfsavecontent variable="renderedEmpty"><cfinclude template="../../notificacoes/home.cfm"/></cfsavecontent>
<cfset check(find('Nenhuma notificação encontrada',renderedEmpty) GT 0, 'empty view renders without division by zero')/>
<cfoutput>NOTIFICATION_AUDIENCE_PASS #checks#</cfoutput>
