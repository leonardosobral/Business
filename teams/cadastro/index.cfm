<cfinclude template="../includes/start.cfm">
<cfset teamTitle="Cadastre seu Team"><cfset teamLoginReturn="/teams/cadastro/">
<cfset teamForm={type='ASSESSORIA',attendance='AMBOS',description='',website=''}>
<cfif CGI.request_method EQ 'POST'>
<cftry><cfset teamPost()><cfloop collection="#FORM#" item="teamFormKey"><cfif isSimpleValue(FORM[teamFormKey])><cfset teamForm[teamFormKey]=FORM[teamFormKey]></cfif></cfloop><cfif teamBoundary.text(FORM,'confirm') NEQ 'yes'><cfthrow type="Teams.Validation" message="Confirme a responsabilidade pelos dados e o CREF ativo."></cfif><cfset newTeamId=teamSvc.register(teamUser.id,FORM)><cflocation url="/teams/?team=#newTeamId#&tab=cadastro&saved=1" addtoken="false">
<cfcatch type="Teams.Validation"><cfset teamError=cfcatch.message></cfcatch><cfcatch type="Teams.Forbidden"><cfheader statuscode="403"><cfset teamError=cfcatch.message></cfcatch><cfcatch type="any"><cflog file="teams" type="error" text="registration_failed #cfcatch.type#"><cfset teamError="Não foi possível concluir o cadastro. Tente novamente."></cfcatch></cftry>
</cfif>
<cfinclude template="../includes/header.cfm">
<section class="teams-hero"><span class="teams-eyebrow">Road Runners Teams</span><h1>Seu time tem lugar aqui.</h1><p>Reúna seus atletas, acompanhe resultados e represente sua comunidade no Road Runners.</p></section>
<cfif structIsEmpty(teamUser)><cfinclude template="../includes/login.cfm"><cfelse>
<section class="teams-panel"><h2>Solicitar cadastro</h2><p class="teams-muted">Todos os tipos de Team precisam indicar um responsável técnico com CREF ativo. Nossa equipe revisará os dados antes de liberar as adesões.</p>
<form class="teams-form" method="post"><input type="hidden" name="csrf" value="<cfoutput>#teamCsrf#</cfoutput>"><cfinclude template="../includes/fields.cfm"><label class="teams-consent full"><input type="checkbox" name="confirm" value="yes" required><span>Sou responsável por esta solicitação, tenho autorização para representar o Team e declaro que o responsável técnico informado possui CREF ativo.</span></label><div class="full"><button>Enviar para análise</button></div></form></section></cfif>
<cfinclude template="../includes/footer.cfm">
