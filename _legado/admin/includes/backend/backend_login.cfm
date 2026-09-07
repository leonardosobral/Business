<!--- GOOGLE SIGN OUT --->

<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cflocation addtoken="false" url="/logout.cfm"/>
</cfif>

<!--- Authentication handled exclusively by the verified request boundary. --->

<!--- DADOS DO USUARIO LOGADO --->

<cfif isDefined("REQUEST.businessIdentity.id")>
    <cfquery name="qPerfil">
        SELECT * FROM tb_usuarios
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.businessIdentity.id#"/>
        AND is_admin = true
    </cfquery>
    <cfquery name="qPermissoes">
        SELECT t.*, tpp.tag
        FROM public.tb_powerups_permissoes_usuario t
        INNER JOIN public.tb_powerups_permissoes tpp on t.id_permissao = tpp.id_permissao
        WHERE t.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#REQUEST.businessIdentity.id#"/>
    </cfquery>
    <cfset VARIABLES.permissoes = ""/>
    <cfloop query="qPermissoes">
        <cfset VARIABLES.permissoes = listAppend(VARIABLES.permissoes, qPermissoes.tag)/>
    </cfloop>
</cfif>
