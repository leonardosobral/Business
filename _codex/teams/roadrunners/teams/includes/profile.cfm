<cftry>
<cfset athleteTeamsService=new services.teams.Service()>
<cfif athleteTeamsService.ready()>
<cfset profileTeam=athleteTeamsService.affiliation(qPagina.id_usuario_cadastro)>
<div class="athlete-profile-card mb-2 p-3"><h2 class="h6 mb-2">Road Runners Teams</h2><cfif NOT structIsEmpty(profileTeam)><a href="/teams/?team=<cfoutput>#urlEncodedFormat(profileTeam.slug)#</cfoutput>"><cfoutput>#encodeForHTML(profileTeam.name)#</cfoutput></a><cfelseif VARIABLES.isOwnAthleteProfile><p class="small text-muted mb-2">Escolha o time que você quer representar.</p></cfif><cfif VARIABLES.isOwnAthleteProfile><a class="btn btn-sm btn-outline-secondary d-block mt-2" href="/teams/meu-team/">Meu Team</a></cfif></div>
</cfif>
<cfcatch type="any"><cflog file="teams" type="error" text="profile_affiliation_unavailable #cfcatch.type#"></cfcatch>
</cftry>
