<!--- GOOGLE SIGN OUT --->

<cfif isDefined("URL.action") AND URL.action EQ "googlesignout">
    <cftry>
        <cfif isDefined("COOKIE.id")>
        <cfquery>
            INSERT INTO tb_log
            (log_item, log_item_id, log_user, site)
            VALUES
            ('googlesignout',<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#COOKIE.name#,#COOKIE.email#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RR')
        </cfquery>
        </cfif>
    <cfcatch type="any"></cfcatch>
    </cftry>
    <cfset delSession = StructDelete(COOKIE, "id", true)/>
    <cfset delSession = StructDelete(COOKIE, "name", true)/>
    <cfset delSession = StructDelete(COOKIE, "email", true)/>
    <cfset delSession = StructDelete(COOKIE, "imagem_usuario", true)/>
    <cflocation addtoken="false" url="/"/>
</cfif>

<!--- GOOGLE SIGN IN --->

<cfif isDefined("URL.action") AND URL.action EQ "googlesignin">

    <cfquery name="qPerfil">
        select * from tb_usuarios
        where email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.email#"/>
        and is_admin = true
    </cfquery>

    <cfcookie name="id" value="#qPerfil.id#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="name" value="#qPerfil.name#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="email" value="#qPerfil.email#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>
    <cfcookie name="imagem_usuario" value="#qPerfil.imagem_usuario#" expires="#createTimeSpan( 30, 0, 0, 0 )#"/>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        ('googlesignin',<cfqueryparam cfsqltype="cf_sql_varchar" value="#COOKIE.id#,#COOKIE.name#,#COOKIE.email#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

    <cflocation addtoken="false" url="/admin/"/>

</cfif>

<!--- DADOS DO USUARIO LOGADO --->

<cfif isDefined("COOKIE.id")>
    <cfquery name="qPerfil">
        SELECT * FROM tb_usuarios
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
        AND is_admin = true
    </cfquery>
    <cfquery name="qPermissoes">
        SELECT t.*, tpp.tag
        FROM public.tb_powerups_permissoes_usuario t
        INNER JOIN public.tb_powerups_permissoes tpp on t.id_permissao = tpp.id_permissao
        WHERE t.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
    </cfquery>
    <cfset VARIABLES.permissoes = ""/>
    <cfloop query="qPermissoes">
        <cfset VARIABLES.permissoes = listAppend(VARIABLES.permissoes, qPermissoes.tag)/>
    </cfloop>
</cfif>
