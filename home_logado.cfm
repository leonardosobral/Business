<!--- CONTEUDO --->

<cfset VARIABLES.businessHomeIsAdmin = false/>
<cfif isDefined("VARIABLES.businessEffectiveIsAdmin")>
    <cfif IsBoolean(VARIABLES.businessEffectiveIsAdmin)>
        <cfset VARIABLES.businessHomeIsAdmin = VARIABLES.businessEffectiveIsAdmin/>
    <cfelseif ListFindNoCase("true,t,1,yes,sim", trim(VARIABLES.businessEffectiveIsAdmin))>
        <cfset VARIABLES.businessHomeIsAdmin = true/>
    </cfif>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin")>
    <cfif IsBoolean(qPerfil.is_admin)>
        <cfset VARIABLES.businessHomeIsAdmin = qPerfil.is_admin/>
    <cfelseif ListFindNoCase("true,t,1,yes,sim", trim(qPerfil.is_admin))>
        <cfset VARIABLES.businessHomeIsAdmin = true/>
    </cfif>
</cfif>
<cfif isDefined("VARIABLES.businessAccountSimulationActive") AND VARIABLES.businessAccountSimulationActive>
    <cfset VARIABLES.businessHomeIsAdmin = false/>
</cfif>

<div class="row g-3">

    <cfif VARIABLES.businessHomeIsAdmin>

        <cfinclude template="includes/estrutura/home_admin_dashboard.cfm"/>

    </cfif>

    <cfif NOT VARIABLES.businessHomeIsAdmin
        AND isDefined("VARIABLES.businessEffectiveAccountIds")
        AND len(trim(VARIABLES.businessEffectiveAccountIds))
        AND VARIABLES.businessEffectiveAccountIds NEQ "0">
        <div class="col-12">
            <cfinclude template="includes/estrutura/home_conta_dashboard.cfm"/>
        </div>
    <cfelseif NOT VARIABLES.businessHomeIsAdmin>
        <div class="col-12">
            <div class="alert alert-warning">
                <strong>Acesso Business em analise.</strong>
                Seu usuario ainda nao esta vinculado a uma conta ativa. Se voce ja solicitou acesso, aguarde a aprovacao da equipe.
                <a class="btn btn-sm btn-warning ms-2" href="/cadastro/">Solicitar acesso da empresa</a>
            </div>
        </div>
    </cfif>

</div>
