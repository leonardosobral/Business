<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfparam name="URL.user_busca" default=""/>
<cfparam name="URL.filter_logic" default="any"/>
<cfparam name="URL.filter_desafio" default=""/>
<cfparam name="URL.filter_produto" default=""/>
<cfparam name="URL.filter_status" default="active"/>
<cfset VARIABLES.verifiedPage = max(1, int(URL.pagina))/>
<cfset VARIABLES.verifiedFilterLogic = lcase(trim(URL.filter_logic))/>
<cfif NOT listFindNoCase("any,all", VARIABLES.verifiedFilterLogic)>
    <cfset VARIABLES.verifiedFilterLogic = "any"/>
</cfif>
<cfset VARIABLES.verifiedFilterStatus = lcase(trim(URL.filter_status))/>
<cfif NOT listFindNoCase("active,inactive,all", VARIABLES.verifiedFilterStatus)>
    <cfset VARIABLES.verifiedFilterStatus = "active"/>
</cfif>
<cfset VARIABLES.verifiedRuleConnector = " OR "/>
<cfif VARIABLES.verifiedFilterLogic EQ "all">
    <cfset VARIABLES.verifiedRuleConnector = " AND "/>
</cfif>
<cfset VARIABLES.verifiedFilterDesafio = trim(URL.filter_desafio)/>
<cfset VARIABLES.verifiedFilterProduto = trim(URL.filter_produto)/>
<cfset VARIABLES.verifiedFilterAdmin = isDefined("URL.filter_admin") AND URL.filter_admin EQ "true"/>
<cfset VARIABLES.verifiedFilterDev = isDefined("URL.filter_dev") AND URL.filter_dev EQ "true"/>
<cfset VARIABLES.verifiedFilterPartner = isDefined("URL.filter_partner") AND URL.filter_partner EQ "true"/>
<cfset VARIABLES.verifiedFilterChallenge = len(VARIABLES.verifiedFilterDesafio) OR len(VARIABLES.verifiedFilterProduto)/>
<cfset VARIABLES.verifiedHasRuleFilters = VARIABLES.verifiedFilterChallenge OR VARIABLES.verifiedFilterAdmin OR VARIABLES.verifiedFilterDev OR VARIABLES.verifiedFilterPartner/>
<cfset VARIABLES.verifiedBaseQueryString = "pagina=#VARIABLES.verifiedPage#"/>
<cfif VARIABLES.verifiedFilterStatus NEQ "active">
    <cfset VARIABLES.verifiedBaseQueryString &= "&filter_status=" & urlEncodedFormat(VARIABLES.verifiedFilterStatus)/>
</cfif>
<cfif VARIABLES.verifiedHasRuleFilters>
    <cfset VARIABLES.verifiedBaseQueryString &= "&filter_logic=" & urlEncodedFormat(VARIABLES.verifiedFilterLogic)/>
    <cfif len(VARIABLES.verifiedFilterDesafio)><cfset VARIABLES.verifiedBaseQueryString &= "&filter_desafio=" & urlEncodedFormat(VARIABLES.verifiedFilterDesafio)/></cfif>
    <cfif len(VARIABLES.verifiedFilterProduto)><cfset VARIABLES.verifiedBaseQueryString &= "&filter_produto=" & urlEncodedFormat(VARIABLES.verifiedFilterProduto)/></cfif>
    <cfif VARIABLES.verifiedFilterAdmin><cfset VARIABLES.verifiedBaseQueryString &= "&filter_admin=true"/></cfif>
    <cfif VARIABLES.verifiedFilterDev><cfset VARIABLES.verifiedBaseQueryString &= "&filter_dev=true"/></cfif>
    <cfif VARIABLES.verifiedFilterPartner><cfset VARIABLES.verifiedBaseQueryString &= "&filter_partner=true"/></cfif>
</cfif>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfquery name="qVerifiedChallengeProducts">
    SELECT des.desafio,
           des.produto,
           coalesce(nullif(min(dp.nome_produto), ''), des.produto) AS nome_produto,
           count(DISTINCT des.id_usuario) AS total_usuarios
    FROM desafios des
    LEFT JOIN desafios_produtos dp ON dp.codigo_produto = des.produto
    WHERE trim(coalesce(des.produto, '')) <> ''
    GROUP BY des.desafio, des.produto
    ORDER BY upper(coalesce(des.desafio, '')), upper(coalesce(nullif(min(dp.nome_produto), ''), des.produto)), upper(des.produto)
</cfquery>

<cfif isDefined("FORM.verified_action") AND listFindNoCase("salvar,toggle,bulk_status", FORM.verified_action)>
    <cfset VARIABLES.verifiedPageId = ""/>
    <cfset VARIABLES.verifiedPageIds = ""/>
    <cfset VARIABLES.verifiedStatus = false/>

    <cfif isDefined("FORM.verified_page_id")>
        <cfset VARIABLES.verifiedPageId = trim(FORM.verified_page_id)/>
    </cfif>

    <cfif isDefined("FORM.verified_page_ids")>
        <cfloop list="#FORM.verified_page_ids#" index="verifiedBulkPageId">
            <cfif len(trim(verifiedBulkPageId)) AND isNumeric(verifiedBulkPageId)>
                <cfset VARIABLES.verifiedPageIds = listAppend(VARIABLES.verifiedPageIds, int(verifiedBulkPageId))/>
            </cfif>
        </cfloop>
    </cfif>

    <cfif isDefined("FORM.verified_status") AND FORM.verified_status EQ "true">
        <cfset VARIABLES.verifiedStatus = true/>
    </cfif>

    <cfif FORM.verified_action EQ "toggle">
        <cfset VARIABLES.verifiedStatus = isDefined("FORM.verified_status") AND FORM.verified_status EQ "true"/>
    </cfif>

    <cfif FORM.verified_action EQ "bulk_status" AND len(VARIABLES.verifiedPageIds)>
        <cfquery>
            UPDATE tb_paginas
            SET verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.verifiedStatus#"/>
            WHERE id_pagina IN (
                <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.verifiedPageIds#" list="true"/>
            )
        </cfquery>
    <cfelseif len(VARIABLES.verifiedPageId) AND isNumeric(VARIABLES.verifiedPageId)>
        <cfquery>
            UPDATE tb_paginas
            SET verificado = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.verifiedStatus#"/>
            WHERE id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.verifiedPageId#"/>
        </cfquery>
    </cfif>

    <cflocation addtoken="false" url="./?#VARIABLES.verifiedBaseQueryString#"/>
</cfif>

<cfquery name="qVerifiedPages">
    SELECT verified_pages.id_pagina,
           verified_pages.pagina_nome,
           verified_pages.tag,
           verified_pages.verificado,
           verified_pages.id_usuario,
           verified_pages.name,
           verified_pages.email,
           verified_pages.is_admin,
           verified_pages.is_dev,
           verified_pages.is_partner,
           verified_pages.desafios_usuario
    FROM (
        SELECT DISTINCT ON (pg.id_pagina)
               pg.id_pagina,
               coalesce(pg.nome, usr.name) AS pagina_nome,
               pg.tag,
               coalesce(pg.verificado, false) AS verificado,
               usr.id AS id_usuario,
               usr.name,
               usr.email,
               coalesce(usr.is_admin, false) AS is_admin,
               coalesce(usr.is_dev, false) AS is_dev,
               coalesce(usr.is_partner, false) AS is_partner,
               (
                   SELECT string_agg(DISTINCT des.desafio || ' / ' || des.produto, ', ' ORDER BY des.desafio || ' / ' || des.produto)
                   FROM desafios des
                   WHERE des.id_usuario = usr.id
                     AND trim(coalesce(des.produto, '')) <> ''
               ) AS desafios_usuario
        FROM tb_paginas pg
        INNER JOIN tb_paginas_usuarios pgusr ON pgusr.id_pagina = pg.id_pagina
        INNER JOIN tb_usuarios usr ON usr.id = pgusr.id_usuario
        WHERE 1 = 1
        <cfif VARIABLES.verifiedFilterStatus EQ "active">
            AND pg.verificado = true
        <cfelseif VARIABLES.verifiedFilterStatus EQ "inactive">
            AND coalesce(pg.verificado, false) = false
        </cfif>
        <cfif VARIABLES.verifiedHasRuleFilters>
            AND (
                <cfset VARIABLES.verifiedRuleNeedsConnector = false/>
                <cfif VARIABLES.verifiedFilterChallenge>
                    EXISTS (
                        SELECT 1
                        FROM desafios des_filter
                        WHERE des_filter.id_usuario = usr.id
                        <cfif len(VARIABLES.verifiedFilterDesafio)>
                            AND des_filter.desafio = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.verifiedFilterDesafio#"/>
                        </cfif>
                        <cfif len(VARIABLES.verifiedFilterProduto)>
                            AND des_filter.produto = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.verifiedFilterProduto#"/>
                        </cfif>
                    )
                    <cfset VARIABLES.verifiedRuleNeedsConnector = true/>
                </cfif>
                <cfif VARIABLES.verifiedFilterAdmin>
                    <cfif VARIABLES.verifiedRuleNeedsConnector>#VARIABLES.verifiedRuleConnector#</cfif>
                    coalesce(usr.is_admin, false) = true
                    <cfset VARIABLES.verifiedRuleNeedsConnector = true/>
                </cfif>
                <cfif VARIABLES.verifiedFilterDev>
                    <cfif VARIABLES.verifiedRuleNeedsConnector>#VARIABLES.verifiedRuleConnector#</cfif>
                    coalesce(usr.is_dev, false) = true
                    <cfset VARIABLES.verifiedRuleNeedsConnector = true/>
                </cfif>
                <cfif VARIABLES.verifiedFilterPartner>
                    <cfif VARIABLES.verifiedRuleNeedsConnector>#VARIABLES.verifiedRuleConnector#</cfif>
                    coalesce(usr.is_partner, false) = true
                </cfif>
            )
        </cfif>
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
                   coalesce(pg.verificado, false) AS verificado
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
               coalesce(pg.verificado, false) AS verificado
        FROM tb_paginas pg
        INNER JOIN tb_paginas_usuarios pgusr ON pgusr.id_pagina = pg.id_pagina
        INNER JOIN tb_usuarios usr ON usr.id = pgusr.id_usuario
        WHERE pg.id_pagina = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.page_id#"/>
        ORDER BY pg.id_pagina, usr.name
        LIMIT 1
    </cfquery>
</cfif>
