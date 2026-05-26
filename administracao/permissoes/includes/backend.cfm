<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.permissionsPage = max(1, int(URL.pagina))/>
<cfparam name="URL.user_busca" default=""/>
<cfparam name="VARIABLES.permissionsSaveErrorMessage" default=""/>

<cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT qPerfil.is_admin>
    <cflocation addtoken="false" url="/"/>
</cfif>

<cfquery name="qPermissionCompaniesList">
    SELECT forn.id_fornecedor,
           forn.nome_fornecedor,
           forn.tag_fornecedor,
           forn.tag_tipo,
           coalesce(
               type_exact.id_fornecedor_tipo,
               type_org.id_fornecedor_tipo,
               type_timer.id_fornecedor_tipo,
               type_assessoria.id_fornecedor_tipo,
               type_creator.id_fornecedor_tipo,
               type_fornecedor.id_fornecedor_tipo
           ) AS id_tipo_fornecedor_resolved,
           coalesce(
               type_exact.descricao_tipo,
               type_org.descricao_tipo,
               type_timer.descricao_tipo,
               type_assessoria.descricao_tipo,
               type_creator.descricao_tipo,
               type_fornecedor.descricao_tipo
           ) AS descricao_tipo_resolved
    FROM tb_fornecedores forn
    LEFT JOIN tb_fornecedores_tipos type_exact
        ON unaccent(lower(coalesce(type_exact.descricao_tipo, ''))) = unaccent(lower(coalesce(forn.tag_tipo, '')))
    LEFT JOIN tb_fornecedores_tipos type_org
        ON forn.tag_tipo = 'org'
       AND unaccent(lower(coalesce(type_org.descricao_tipo, ''))) LIKE unaccent(lower('%organ%'))
    LEFT JOIN tb_fornecedores_tipos type_timer
        ON forn.tag_tipo = 'timer'
       AND unaccent(lower(coalesce(type_timer.descricao_tipo, ''))) LIKE unaccent(lower('%timer%'))
    LEFT JOIN tb_fornecedores_tipos type_assessoria
        ON forn.tag_tipo = 'assessoria'
       AND unaccent(lower(coalesce(type_assessoria.descricao_tipo, ''))) LIKE unaccent(lower('%assess%'))
    LEFT JOIN tb_fornecedores_tipos type_creator
        ON forn.tag_tipo = 'creator'
       AND unaccent(lower(coalesce(type_creator.descricao_tipo, ''))) LIKE unaccent(lower('%creator%'))
    LEFT JOIN tb_fornecedores_tipos type_fornecedor
        ON forn.tag_tipo NOT IN ('org', 'timer', 'assessoria', 'creator')
       AND unaccent(lower(coalesce(type_fornecedor.descricao_tipo, ''))) LIKE unaccent(lower('%fornecedor%'))
    ORDER BY forn.nome_fornecedor
</cfquery>

<cfif isDefined("FORM.permissions_action") AND FORM.permissions_action EQ "salvar">
    <cfset VARIABLES.permissionsUserId = isDefined("FORM.permissions_user_id") ? trim(FORM.permissions_user_id) : ""/>
    <cfset VARIABLES.permissionsIsAdmin = isDefined("FORM.permissions_is_admin") AND FORM.permissions_is_admin EQ "true"/>
    <cfset VARIABLES.permissionsIsDev = isDefined("FORM.permissions_is_dev") AND FORM.permissions_is_dev EQ "true"/>
    <cfset VARIABLES.permissionsIsPartner = isDefined("FORM.permissions_is_partner") AND FORM.permissions_is_partner EQ "true"/>
    <cfset VARIABLES.permissionsIsVerified = isDefined("FORM.permissions_is_verified") AND FORM.permissions_is_verified EQ "true"/>
    <cfset VARIABLES.permissionsPageId = isDefined("FORM.permissions_page_id") ? trim(FORM.permissions_page_id) : ""/>
    <cfset VARIABLES.permissionsCompanyIds = isDefined("FORM.permissions_company_ids") ? trim(FORM.permissions_company_ids) : ""/>
    <cfset VARIABLES.permissionsCompanyIdsArray = []/>
    <cfset VARIABLES.permissionsCompanyIdsNormalized = ""/>
    <cfset VARIABLES.permissionsSelectedCompanyTypes = {} />
    <cfset VARIABLES.permissionsSelectedCompanyRelationships = {} />
    <cfset VARIABLES.permissionsSaveErrors = []/>

    <cfif len(trim(VARIABLES.permissionsUserId)) AND isNumeric(VARIABLES.permissionsUserId)>
        <cfif len(VARIABLES.permissionsCompanyIds)>
            <cfloop list="#VARIABLES.permissionsCompanyIds#" item="companyId">
                <cfif isNumeric(trim(companyId))>
                    <cfset arrayAppend(VARIABLES.permissionsCompanyIdsArray, val(trim(companyId)))/>
                </cfif>
            </cfloop>
        </cfif>

        <cfif arrayLen(VARIABLES.permissionsCompanyIdsArray)>
            <cfset VARIABLES.permissionsCompanyIdsNormalized = arrayToList(VARIABLES.permissionsCompanyIdsArray)/>
        </cfif>

        <cfif len(VARIABLES.permissionsCompanyIdsNormalized)>
            <cfquery name="qPermissionSelectedCompanies">
                SELECT companies.id_fornecedor,
                       companies.nome_fornecedor,
                       companies.id_tipo_fornecedor_resolved,
                       companies.tag_fornecedor,
                       companies.tag_tipo,
                       existing.tipo_relacionamento AS tipo_relacionamento_existente
                FROM (
                    SELECT forn.id_fornecedor,
                           forn.nome_fornecedor,
                           forn.tag_fornecedor,
                           forn.tag_tipo,
                           coalesce(
                               type_exact.id_fornecedor_tipo,
                               type_org.id_fornecedor_tipo,
                               type_timer.id_fornecedor_tipo,
                               type_assessoria.id_fornecedor_tipo,
                               type_creator.id_fornecedor_tipo,
                               type_fornecedor.id_fornecedor_tipo
                           ) AS id_tipo_fornecedor_resolved
                    FROM tb_fornecedores forn
                    LEFT JOIN tb_fornecedores_tipos type_exact
                        ON unaccent(lower(coalesce(type_exact.descricao_tipo, ''))) = unaccent(lower(coalesce(forn.tag_tipo, '')))
                    LEFT JOIN tb_fornecedores_tipos type_org
                        ON forn.tag_tipo = 'org'
                       AND unaccent(lower(coalesce(type_org.descricao_tipo, ''))) LIKE unaccent(lower('%organ%'))
                    LEFT JOIN tb_fornecedores_tipos type_timer
                        ON forn.tag_tipo = 'timer'
                       AND unaccent(lower(coalesce(type_timer.descricao_tipo, ''))) LIKE unaccent(lower('%timer%'))
                    LEFT JOIN tb_fornecedores_tipos type_assessoria
                        ON forn.tag_tipo = 'assessoria'
                       AND unaccent(lower(coalesce(type_assessoria.descricao_tipo, ''))) LIKE unaccent(lower('%assess%'))
                    LEFT JOIN tb_fornecedores_tipos type_creator
                        ON forn.tag_tipo = 'creator'
                       AND unaccent(lower(coalesce(type_creator.descricao_tipo, ''))) LIKE unaccent(lower('%creator%'))
                    LEFT JOIN tb_fornecedores_tipos type_fornecedor
                        ON forn.tag_tipo NOT IN ('org', 'timer', 'assessoria', 'creator')
                       AND unaccent(lower(coalesce(type_fornecedor.descricao_tipo, ''))) LIKE unaccent(lower('%fornecedor%'))
                ) companies
                LEFT JOIN tb_usuarios_fornecedores existing
                    ON existing.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsUserId#"/>
                   AND existing.id_fornecedor = companies.id_fornecedor
                WHERE companies.id_fornecedor IN (
                    <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsCompanyIdsNormalized#" list="true"/>
                )
            </cfquery>

            <cfloop query="qPermissionSelectedCompanies">
                <cfif NOT len(trim(qPermissionSelectedCompanies.id_tipo_fornecedor_resolved))>
                    <cfset arrayAppend(VARIABLES.permissionsSaveErrors, "Nao foi possivel identificar o tipo da empresa " & qPermissionSelectedCompanies.nome_fornecedor & ".")/>
                <cfelse>
                    <cfset VARIABLES.permissionsSelectedCompanyTypes[qPermissionSelectedCompanies.id_fornecedor] = qPermissionSelectedCompanies.id_tipo_fornecedor_resolved/>
                </cfif>

                <cfset VARIABLES.permissionsCompanyRelationship = trim(qPermissionSelectedCompanies.tipo_relacionamento_existente)/>
                <cfif NOT len(VARIABLES.permissionsCompanyRelationship)>
                    <cfset VARIABLES.permissionsCompanyRelationship = trim(qPermissionSelectedCompanies.tag_tipo)/>
                </cfif>
                <cfif NOT len(VARIABLES.permissionsCompanyRelationship)>
                    <cfset VARIABLES.permissionsCompanyRelationship = trim(qPermissionSelectedCompanies.tag_fornecedor)/>
                </cfif>

                <cfif NOT len(VARIABLES.permissionsCompanyRelationship)>
                    <cfset arrayAppend(VARIABLES.permissionsSaveErrors, "Nao foi possivel identificar o relacionamento da empresa " & qPermissionSelectedCompanies.nome_fornecedor & ".")/>
                <cfelse>
                    <cfset VARIABLES.permissionsSelectedCompanyRelationships[qPermissionSelectedCompanies.id_fornecedor] = VARIABLES.permissionsCompanyRelationship/>
                </cfif>
            </cfloop>
        </cfif>

        <cfif NOT arrayLen(VARIABLES.permissionsSaveErrors)>
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

            <cfquery>
                DELETE FROM tb_usuarios_fornecedores
                WHERE id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsUserId#"/>
            </cfquery>

            <cfif len(VARIABLES.permissionsCompanyIdsNormalized)>
                <cfloop list="#VARIABLES.permissionsCompanyIdsNormalized#" item="companyId">
                    <cfquery>
                        INSERT INTO tb_usuarios_fornecedores
                        (id_usuario, id_fornecedor, id_tipo_fornecedor, tipo_relacionamento)
                        VALUES
                        (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsUserId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#companyId#"/>,
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsSelectedCompanyTypes[companyId]#"/>,
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.permissionsSelectedCompanyRelationships[companyId]#" maxlength="32"/>
                        )
                    </cfquery>
                </cfloop>
            </cfif>

            <cflocation addtoken="false" url="./?pagina=#VARIABLES.permissionsPage#"/>
        <cfelse>
            <cfset VARIABLES.permissionsSaveErrorMessage = arrayToList(VARIABLES.permissionsSaveErrors, " ") />
        </cfif>
    </cfif>
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
           perms.permission_count,
           companies.company_names,
           companies.company_ids,
           companies.company_tags,
           companies.company_types,
           companies.company_count
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
    LEFT JOIN (
        SELECT usrforn.id_usuario,
               string_agg(DISTINCT forn.nome_fornecedor, ', ' ORDER BY forn.nome_fornecedor) AS company_names,
               string_agg(DISTINCT usrforn.id_fornecedor::text, ',' ORDER BY usrforn.id_fornecedor::text) AS company_ids,
               string_agg(DISTINCT forn.tag_fornecedor, ', ' ORDER BY forn.tag_fornecedor) AS company_tags,
               string_agg(DISTINCT forn.tag_tipo, ', ' ORDER BY forn.tag_tipo) AS company_types,
               count(DISTINCT usrforn.id_fornecedor) AS company_count
        FROM tb_usuarios_fornecedores usrforn
        INNER JOIN tb_fornecedores forn ON forn.id_fornecedor = usrforn.id_fornecedor
        GROUP BY usrforn.id_usuario
    ) companies ON companies.id_usuario = usr.id
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
           perms.permission_count,
           companies.company_names,
           companies.company_ids,
           companies.company_tags,
           companies.company_types,
           companies.company_count
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
    LEFT JOIN (
        SELECT usrforn.id_usuario,
               string_agg(DISTINCT forn.nome_fornecedor, ', ' ORDER BY forn.nome_fornecedor) AS company_names,
               string_agg(DISTINCT usrforn.id_fornecedor::text, ',' ORDER BY usrforn.id_fornecedor::text) AS company_ids,
               string_agg(DISTINCT forn.tag_fornecedor, ', ' ORDER BY forn.tag_fornecedor) AS company_tags,
               string_agg(DISTINCT forn.tag_tipo, ', ' ORDER BY forn.tag_tipo) AS company_types,
               count(DISTINCT usrforn.id_fornecedor) AS company_count
        FROM tb_usuarios_fornecedores usrforn
        INNER JOIN tb_fornecedores forn ON forn.id_fornecedor = usrforn.id_fornecedor
        GROUP BY usrforn.id_usuario
    ) companies ON companies.id_usuario = usr.id
    WHERE usr.is_partner = true
      AND coalesce(usr.is_admin, false) = false
      AND coalesce(usr.is_dev, false) = false
    ORDER BY usr.name
</cfquery>

<cfset qPermissionUsersSearch = QueryNew("id,name,email,is_admin,is_dev,is_partner,id_pagina,pagina_tag,verificado,permission_tags,permission_types,permission_count,company_names,company_ids,company_tags,company_types,company_count")/>

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
               perms.permission_count,
               companies.company_names,
               companies.company_ids,
               companies.company_tags,
               companies.company_types,
               companies.company_count
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
        LEFT JOIN (
            SELECT usrforn.id_usuario,
                   string_agg(DISTINCT forn.nome_fornecedor, ', ' ORDER BY forn.nome_fornecedor) AS company_names,
                   string_agg(DISTINCT usrforn.id_fornecedor::text, ',' ORDER BY usrforn.id_fornecedor::text) AS company_ids,
                   string_agg(DISTINCT forn.tag_fornecedor, ', ' ORDER BY forn.tag_fornecedor) AS company_tags,
                   string_agg(DISTINCT forn.tag_tipo, ', ' ORDER BY forn.tag_tipo) AS company_types,
                   count(DISTINCT usrforn.id_fornecedor) AS company_count
            FROM tb_usuarios_fornecedores usrforn
            INNER JOIN tb_fornecedores forn ON forn.id_fornecedor = usrforn.id_fornecedor
            GROUP BY usrforn.id_usuario
        ) companies ON companies.id_usuario = usr.id
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

<cfset qPermissionUserEdit = QueryNew("id,name,email,is_admin,is_dev,is_partner,id_pagina,pagina_tag,verificado,permission_tags,permission_types,permission_count,company_names,company_ids,company_tags,company_types,company_count")/>
<cfset VARIABLES.permissionsEditUserId = ""/>

<cfif isDefined("URL.user_id") AND len(trim(URL.user_id)) AND isNumeric(URL.user_id)>
    <cfset VARIABLES.permissionsEditUserId = trim(URL.user_id)/>
<cfelseif len(trim(VARIABLES.permissionsSaveErrorMessage))
    AND isDefined("FORM.permissions_user_id")
    AND len(trim(FORM.permissions_user_id))
    AND isNumeric(FORM.permissions_user_id)>
    <cfset VARIABLES.permissionsEditUserId = trim(FORM.permissions_user_id)/>
</cfif>

<cfif len(VARIABLES.permissionsEditUserId)>
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
               perms.permission_count,
               companies.company_names,
               companies.company_ids,
               companies.company_tags,
               companies.company_types,
               companies.company_count
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
        LEFT JOIN (
            SELECT usrforn.id_usuario,
                   string_agg(DISTINCT forn.nome_fornecedor, ', ' ORDER BY forn.nome_fornecedor) AS company_names,
                   string_agg(DISTINCT usrforn.id_fornecedor::text, ',' ORDER BY usrforn.id_fornecedor::text) AS company_ids,
                   string_agg(DISTINCT forn.tag_fornecedor, ', ' ORDER BY forn.tag_fornecedor) AS company_tags,
                   string_agg(DISTINCT forn.tag_tipo, ', ' ORDER BY forn.tag_tipo) AS company_types,
                   count(DISTINCT usrforn.id_fornecedor) AS company_count
            FROM tb_usuarios_fornecedores usrforn
            INNER JOIN tb_fornecedores forn ON forn.id_fornecedor = usrforn.id_fornecedor
            GROUP BY usrforn.id_usuario
        ) companies ON companies.id_usuario = usr.id
        WHERE usr.id = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.permissionsEditUserId#"/>
        LIMIT 1
    </cfquery>
</cfif>
