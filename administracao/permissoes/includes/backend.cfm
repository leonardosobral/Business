<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.permissionsPage = max(1, int(URL.pagina))/>
<cfparam name="URL.user_busca" default=""/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfif isDefined("FORM.permissions_action") AND FORM.permissions_action EQ "salvar">
    <cfset VARIABLES.permissionsUserId = isDefined("FORM.permissions_user_id") ? trim(FORM.permissions_user_id) : ""/>
    <cfset VARIABLES.permissionsIsAdmin = isDefined("FORM.permissions_is_admin") AND FORM.permissions_is_admin EQ "true"/>
    <cfset VARIABLES.permissionsIsDev = isDefined("FORM.permissions_is_dev") AND FORM.permissions_is_dev EQ "true"/>

    <cfif len(trim(VARIABLES.permissionsUserId)) AND isNumeric(VARIABLES.permissionsUserId)>
        <cfquery>
            UPDATE tb_usuarios
            SET is_admin = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.permissionsIsAdmin#"/>,
                is_dev = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.permissionsIsDev#"/>
            WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsUserId#"/>
        </cfquery>
    </cfif>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.permissionsPage#"/>
</cfif>

<cfif isDefined("URL.permissions_action")
    AND URL.permissions_action EQ "remover"
    AND isDefined("URL.user_id")
    AND len(trim(URL.user_id))
    AND isNumeric(URL.user_id)>

    <cfquery>
        UPDATE tb_usuarios
        SET is_admin = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
            is_dev = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.user_id#"/>
    </cfquery>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.permissionsPage#"/>
</cfif>

<cfquery name="qPermissionUsers">
    SELECT usr.id,
           usr.name,
           usr.email,
           usr.is_admin,
           usr.is_dev,
           usr.is_partner,
           usr.aka
    FROM tb_usuarios usr
    WHERE usr.is_admin = true
       OR usr.is_dev = true
    ORDER BY usr.is_admin DESC, usr.is_dev DESC, usr.name
</cfquery>

<cfset qPermissionUsersSearch = QueryNew("id,name,email,is_admin,is_dev")/>

<cfif isDefined("URL.user_novo")
    AND URL.user_novo
    AND len(trim(URL.user_busca))>
    <cfset VARIABLES.permissionsSearchTerm = trim(URL.user_busca)/>
    <cfquery name="qPermissionUsersSearch">
        SELECT usr.id,
               usr.name,
               usr.email,
               usr.is_admin,
               usr.is_dev
        FROM tb_usuarios usr
        WHERE
            <cfif isNumeric(VARIABLES.permissionsSearchTerm)>
                usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsSearchTerm#"/>
                OR
            </cfif>
            unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.permissionsSearchTerm#%"/>))
            OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.permissionsSearchTerm#%"/>))
        ORDER BY usr.name, usr.email
        LIMIT 50
    </cfquery>
</cfif>

<cfset qPermissionUserEdit = QueryNew("id,name,email,is_admin,is_dev")/>

<cfif isDefined("URL.user_id") AND len(trim(URL.user_id)) AND isNumeric(URL.user_id)>
    <cfquery name="qPermissionUserEdit">
        SELECT usr.id,
               usr.name,
               usr.email,
               usr.is_admin,
               usr.is_dev
        FROM tb_usuarios usr
        WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.user_id#"/>
        LIMIT 1
    </cfquery>
</cfif>
