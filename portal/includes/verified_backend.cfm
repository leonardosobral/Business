<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfparam name="URL.user_busca" default=""/>
<cfset VARIABLES.verifiedPage = max(1, int(URL.pagina))/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfif isDefined("FORM.verified_action") AND FORM.verified_action EQ "salvar">
    <cfset VARIABLES.verifiedPageId = ""/>
    <cfset VARIABLES.verifiedStatus = false/>

    <cfif isDefined("FORM.verified_page_id")>
        <cfset VARIABLES.verifiedPageId = trim(FORM.verified_page_id)/>
    </cfif>

    <cfif isDefined("FORM.verified_status") AND FORM.verified_status EQ "true">
        <cfset VARIABLES.verifiedStatus = true/>
    </cfif>

    <cfif len(VARIABLES.verifiedPageId) AND isNumeric(VARIABLES.verifiedPageId)>
        <cfquery>
            UPDATE tb_paginas
            SET verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.verifiedStatus#"/>
            WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.verifiedPageId#"/>
        </cfquery>
    </cfif>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.verifiedPage#"/>
</cfif>

<cfif isDefined("URL.verified_action")
    AND URL.verified_action EQ "remover"
    AND isDefined("URL.page_id")
    AND len(trim(URL.page_id))
    AND isNumeric(URL.page_id)>

    <cfquery>
        UPDATE tb_paginas
        SET verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="false"/>
        WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.page_id#"/>
    </cfquery>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.verifiedPage#"/>
</cfif>

<cfquery name="qVerifiedPages">
    SELECT verified_pages.id_pagina,
           verified_pages.pagina_nome,
           verified_pages.tag,
           verified_pages.verificado,
           verified_pages.id_usuario,
           verified_pages.name,
           verified_pages.email
    FROM (
        SELECT DISTINCT ON (pg.id_pagina)
               pg.id_pagina,
               coalesce(pg.nome, usr.name) AS pagina_nome,
               pg.tag,
               pg.verificado,
               usr.id AS id_usuario,
               usr.name,
               usr.email
        FROM tb_paginas pg
        INNER JOIN tb_paginas_usuarios pgusr ON pgusr.id_pagina = pg.id_pagina
        INNER JOIN tb_usuarios usr ON usr.id = pgusr.id_usuario
        WHERE pg.verificado = true
        ORDER BY pg.id_pagina, usr.name
    ) verified_pages
    ORDER BY upper(coalesce(verified_pages.pagina_nome, '')), upper(coalesce(verified_pages.name, ''))
</cfquery>

<cfset qVerifiedPagesSearch = QueryNew("id_pagina,pagina_nome,tag,id_usuario,name,email,verificado")/>

<cfif isDefined("URL.page_novo")
    AND URL.page_novo
    AND len(trim(URL.user_busca))>
    <cfset VARIABLES.verifiedSearchTerm = trim(URL.user_busca)/>
    <cfquery name="qVerifiedPagesSearch">
        SELECT verified_search.id_pagina,
               verified_search.pagina_nome,
               verified_search.tag,
               verified_search.id_usuario,
               verified_search.name,
               verified_search.email,
               verified_search.verificado
        FROM (
            SELECT DISTINCT ON (pg.id_pagina)
                   pg.id_pagina,
                   coalesce(pg.nome, usr.name) AS pagina_nome,
                   pg.tag,
                   usr.id AS id_usuario,
                   usr.name,
                   usr.email,
                   pg.verificado
            FROM tb_paginas pg
            INNER JOIN tb_paginas_usuarios pgusr ON pgusr.id_pagina = pg.id_pagina
            INNER JOIN tb_usuarios usr ON usr.id = pgusr.id_usuario
            WHERE coalesce(pg.verificado, false) = false
              AND (
                <cfif isNumeric(VARIABLES.verifiedSearchTerm)>
                    usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.verifiedSearchTerm#"/>
                    OR pg.id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.verifiedSearchTerm#"/>
                    OR
                </cfif>
                unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.verifiedSearchTerm#%"/>))
                OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.verifiedSearchTerm#%"/>))
                OR unaccent(upper(coalesce(pg.nome, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.verifiedSearchTerm#%"/>))
                OR unaccent(upper(coalesce(pg.tag, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.verifiedSearchTerm#%"/>))
              )
            ORDER BY pg.id_pagina, usr.name
        ) verified_search
        ORDER BY upper(coalesce(verified_search.pagina_nome, '')), upper(coalesce(verified_search.name, ''))
        LIMIT 50
    </cfquery>
</cfif>

<cfset qVerifiedPageEdit = QueryNew("id_pagina,pagina_nome,tag,id_usuario,name,email,verificado")/>

<cfif isDefined("URL.page_id") AND len(trim(URL.page_id)) AND isNumeric(URL.page_id)>
    <cfquery name="qVerifiedPageEdit">
        SELECT DISTINCT ON (pg.id_pagina)
               pg.id_pagina,
               coalesce(pg.nome, usr.name) AS pagina_nome,
               pg.tag,
               usr.id AS id_usuario,
               usr.name,
               usr.email,
               pg.verificado
        FROM tb_paginas pg
        INNER JOIN tb_paginas_usuarios pgusr ON pgusr.id_pagina = pg.id_pagina
        INNER JOIN tb_usuarios usr ON usr.id = pgusr.id_usuario
        WHERE pg.id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.page_id#"/>
        ORDER BY pg.id_pagina, usr.name
        LIMIT 1
    </cfquery>
</cfif>
