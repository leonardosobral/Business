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
    <cfset VARIABLES.permissionsIsPartner = isDefined("FORM.permissions_is_partner") AND FORM.permissions_is_partner EQ "true"/>
    <cfset VARIABLES.permissionsIsVerified = isDefined("FORM.permissions_is_verified") AND FORM.permissions_is_verified EQ "true"/>
    <cfset VARIABLES.permissionsPageId = isDefined("FORM.permissions_page_id") ? trim(FORM.permissions_page_id) : ""/>

    <cfif len(trim(VARIABLES.permissionsUserId)) AND isNumeric(VARIABLES.permissionsUserId)>
        <cfquery>
            UPDATE tb_usuarios
            SET is_admin = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.permissionsIsAdmin#"/>,
                is_dev = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.permissionsIsDev#"/>,
                is_partner = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.permissionsIsPartner#"/>
            WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsUserId#"/>
        </cfquery>

        <cfif len(trim(VARIABLES.permissionsPageId)) AND isNumeric(VARIABLES.permissionsPageId)>
            <cfquery>
                UPDATE tb_paginas
                SET verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.permissionsIsVerified#"/>
                WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsPageId#"/>
            </cfquery>
        </cfif>
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
            is_dev = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>,
            is_partner = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>
        WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.user_id#"/>
    </cfquery>

    <cfquery>
        UPDATE tb_paginas
        SET verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>
        WHERE id_pagina IN (
            SELECT pgusr.id_pagina
            FROM tb_paginas_usuarios pgusr
            WHERE pgusr.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.user_id#"/>
        )
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
           usr.aka,
           pg.id_pagina,
           pg.tag AS pagina_tag,
           pg.verificado,
           perms.permission_tags,
           perms.permission_types,
           perms.permission_count
    FROM tb_usuarios usr
    LEFT JOIN (
        SELECT DISTINCT ON (pgusr.id_usuario)
               pgusr.id_usuario,
               pg.id_pagina,
               pg.tag,
               pg.verificado
        FROM tb_paginas_usuarios pgusr
        INNER JOIN tb_paginas pg ON pg.id_pagina = pgusr.id_pagina
        ORDER BY pgusr.id_usuario, pg.verificado DESC, pg.id_pagina
    ) pg ON pg.id_usuario = usr.id
    LEFT JOIN (
        SELECT perm.id_usuario,
               string_agg(DISTINCT perm.tag, ', ' ORDER BY perm.tag) AS permission_tags,
               string_agg(
                   DISTINCT CASE
                       WHEN bi.bi_tag IS NOT NULL THEN 'BI'
                       WHEN agr.agregador_tag IS NOT NULL THEN 'Agregador'
                       WHEN evt.tag IS NOT NULL THEN 'Evento'
                       ELSE 'Tag'
                   END,
                   ', ' ORDER BY CASE
                       WHEN bi.bi_tag IS NOT NULL THEN 'BI'
                       WHEN agr.agregador_tag IS NOT NULL THEN 'Agregador'
                       WHEN evt.tag IS NOT NULL THEN 'Evento'
                       ELSE 'Tag'
                   END
               ) AS permission_types,
               count(DISTINCT perm.tag) AS permission_count
        FROM tb_permissoes perm
        LEFT JOIN tb_bi bi ON bi.bi_tag = perm.tag
        LEFT JOIN tb_agregadores agr ON agr.agregador_tag = perm.tag
        LEFT JOIN tb_agrega_eventos evt ON evt.tag = perm.tag
        GROUP BY perm.id_usuario
    ) perms ON perms.id_usuario = usr.id
    WHERE usr.is_admin = true
       OR usr.is_dev = true
    ORDER BY usr.is_admin DESC, usr.is_dev DESC, usr.name
</cfquery>

<cfquery name="qPartnerUsers">
    SELECT usr.id,
           usr.name,
           usr.email,
           usr.is_admin,
           usr.is_dev,
           usr.is_partner,
           usr.aka,
           pg.id_pagina,
           pg.tag AS pagina_tag,
           pg.verificado,
           perms.permission_tags,
           perms.permission_types,
           perms.permission_count
    FROM tb_usuarios usr
    LEFT JOIN (
        SELECT DISTINCT ON (pgusr.id_usuario)
               pgusr.id_usuario,
               pg.id_pagina,
               pg.tag,
               pg.verificado
        FROM tb_paginas_usuarios pgusr
        INNER JOIN tb_paginas pg ON pg.id_pagina = pgusr.id_pagina
        ORDER BY pgusr.id_usuario, pg.verificado DESC, pg.id_pagina
    ) pg ON pg.id_usuario = usr.id
    LEFT JOIN (
        SELECT perm.id_usuario,
               string_agg(DISTINCT perm.tag, ', ' ORDER BY perm.tag) AS permission_tags,
               string_agg(
                   DISTINCT CASE
                       WHEN bi.bi_tag IS NOT NULL THEN 'BI'
                       WHEN agr.agregador_tag IS NOT NULL THEN 'Agregador'
                       WHEN evt.tag IS NOT NULL THEN 'Evento'
                       ELSE 'Tag'
                   END,
                   ', ' ORDER BY CASE
                       WHEN bi.bi_tag IS NOT NULL THEN 'BI'
                       WHEN agr.agregador_tag IS NOT NULL THEN 'Agregador'
                       WHEN evt.tag IS NOT NULL THEN 'Evento'
                       ELSE 'Tag'
                   END
               ) AS permission_types,
               count(DISTINCT perm.tag) AS permission_count
        FROM tb_permissoes perm
        LEFT JOIN tb_bi bi ON bi.bi_tag = perm.tag
        LEFT JOIN tb_agregadores agr ON agr.agregador_tag = perm.tag
        LEFT JOIN tb_agrega_eventos evt ON evt.tag = perm.tag
        GROUP BY perm.id_usuario
    ) perms ON perms.id_usuario = usr.id
    WHERE usr.is_partner = true
      AND coalesce(usr.is_admin, false) = false
      AND coalesce(usr.is_dev, false) = false
    ORDER BY usr.name
</cfquery>

<cfset qPermissionUsersSearch = QueryNew("id,name,email,is_admin,is_dev,is_partner,id_pagina,pagina_tag,verificado,permission_tags,permission_types,permission_count")/>

<cfif isDefined("URL.user_novo")
    AND URL.user_novo
    AND len(trim(URL.user_busca))>
    <cfset VARIABLES.permissionsSearchTerm = trim(URL.user_busca)/>
    <cfquery name="qPermissionUsersSearch">
        SELECT usr.id,
               usr.name,
               usr.email,
               usr.is_admin,
               usr.is_dev,
               usr.is_partner,
               pg.id_pagina,
               pg.tag AS pagina_tag,
               pg.verificado,
               perms.permission_tags,
               perms.permission_types,
               perms.permission_count
        FROM tb_usuarios usr
        LEFT JOIN (
            SELECT DISTINCT ON (pgusr.id_usuario)
                   pgusr.id_usuario,
                   pg.id_pagina,
                   pg.tag,
                   pg.verificado
            FROM tb_paginas_usuarios pgusr
            INNER JOIN tb_paginas pg ON pg.id_pagina = pgusr.id_pagina
            ORDER BY pgusr.id_usuario, pg.verificado DESC, pg.id_pagina
        ) pg ON pg.id_usuario = usr.id
        LEFT JOIN (
            SELECT perm.id_usuario,
                   string_agg(DISTINCT perm.tag, ', ' ORDER BY perm.tag) AS permission_tags,
                   string_agg(
                       DISTINCT CASE
                           WHEN bi.bi_tag IS NOT NULL THEN 'BI'
                           WHEN agr.agregador_tag IS NOT NULL THEN 'Agregador'
                           WHEN evt.tag IS NOT NULL THEN 'Evento'
                           ELSE 'Tag'
                       END,
                       ', ' ORDER BY CASE
                           WHEN bi.bi_tag IS NOT NULL THEN 'BI'
                           WHEN agr.agregador_tag IS NOT NULL THEN 'Agregador'
                           WHEN evt.tag IS NOT NULL THEN 'Evento'
                           ELSE 'Tag'
                       END
                   ) AS permission_types,
                   count(DISTINCT perm.tag) AS permission_count
            FROM tb_permissoes perm
            LEFT JOIN tb_bi bi ON bi.bi_tag = perm.tag
            LEFT JOIN tb_agregadores agr ON agr.agregador_tag = perm.tag
            LEFT JOIN tb_agrega_eventos evt ON evt.tag = perm.tag
            GROUP BY perm.id_usuario
        ) perms ON perms.id_usuario = usr.id
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

<cfset qPermissionUserEdit = QueryNew("id,name,email,is_admin,is_dev,is_partner,id_pagina,pagina_tag,verificado,permission_tags,permission_types,permission_count")/>

<cfif isDefined("URL.user_id") AND len(trim(URL.user_id)) AND isNumeric(URL.user_id)>
    <cfquery name="qPermissionUserEdit">
        SELECT usr.id,
               usr.name,
               usr.email,
               usr.is_admin,
               usr.is_dev,
               usr.is_partner,
               pg.id_pagina,
               pg.tag AS pagina_tag,
               pg.verificado,
               perms.permission_tags,
               perms.permission_types,
               perms.permission_count
        FROM tb_usuarios usr
        LEFT JOIN (
            SELECT DISTINCT ON (pgusr.id_usuario)
                   pgusr.id_usuario,
                   pg.id_pagina,
                   pg.tag,
                   pg.verificado
            FROM tb_paginas_usuarios pgusr
            INNER JOIN tb_paginas pg ON pg.id_pagina = pgusr.id_pagina
            ORDER BY pgusr.id_usuario, pg.verificado DESC, pg.id_pagina
        ) pg ON pg.id_usuario = usr.id
        LEFT JOIN (
            SELECT perm.id_usuario,
                   string_agg(DISTINCT perm.tag, ', ' ORDER BY perm.tag) AS permission_tags,
                   string_agg(
                       DISTINCT CASE
                           WHEN bi.bi_tag IS NOT NULL THEN 'BI'
                           WHEN agr.agregador_tag IS NOT NULL THEN 'Agregador'
                           WHEN evt.tag IS NOT NULL THEN 'Evento'
                           ELSE 'Tag'
                       END,
                       ', ' ORDER BY CASE
                           WHEN bi.bi_tag IS NOT NULL THEN 'BI'
                           WHEN agr.agregador_tag IS NOT NULL THEN 'Agregador'
                           WHEN evt.tag IS NOT NULL THEN 'Evento'
                           ELSE 'Tag'
                       END
                   ) AS permission_types,
                   count(DISTINCT perm.tag) AS permission_count
            FROM tb_permissoes perm
            LEFT JOIN tb_bi bi ON bi.bi_tag = perm.tag
            LEFT JOIN tb_agregadores agr ON agr.agregador_tag = perm.tag
            LEFT JOIN tb_agrega_eventos evt ON evt.tag = perm.tag
            GROUP BY perm.id_usuario
        ) perms ON perms.id_usuario = usr.id
        WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.user_id#"/>
        LIMIT 1
    </cfquery>
</cfif>
