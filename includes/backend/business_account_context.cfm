<cfset VARIABLES.businessRealIsAdmin = false/>
<cfset VARIABLES.businessEffectiveIsAdmin = false/>
<cfset VARIABLES.businessAccountSimulationActive = false/>
<cfset VARIABLES.businessSimulatedAccountId = ""/>
<cfset VARIABLES.businessEffectiveAccountIds = "0"/>
<cfset VARIABLES.businessEffectiveAccountManagerIds = "0"/>
<cfset VARIABLES.businessEffectiveAccountOperatorIds = "0"/>
<cfset VARIABLES.businessEffectiveAccountViewerIds = "0"/>
<cfset VARIABLES.businessCurrentAccountRole = ""/>
<cfset VARIABLES.businessEffectiveUserIds = isDefined("COOKIE.id") ? trim(COOKIE.id) : "0"/>
<cfset VARIABLES.businessEffectivePaginaIds = "0"/>
<cfset VARIABLES.businessAccountContextTablesReady = false/>

<cfset qBusinessAccountContextOptions = QueryNew("id_conta,nome_conta,status,total_usuarios")/>
<cfset qBusinessAccountContextAccounts = QueryNew("id_conta,nome_conta,status")/>
<cfset qBusinessSimulatedAccount = QueryNew("id_conta,nome_conta,status")/>
<cfset qBusinessAccountContextMemberships = QueryNew("id_conta,papel,status")/>
<cfset qBusinessAccountContextUsers = QueryNew("id_usuario,name,email,papel,status")/>
<cfset qBusinessAccountContextPages = QueryNew("id_pagina")/>

<cfif isDefined("qPerfil") AND qPerfil.recordcount>
    <cfif isDefined("qPerfil.is_admin")>
        <cfif IsBoolean(qPerfil.is_admin)>
            <cfset VARIABLES.businessRealIsAdmin = qPerfil.is_admin/>
        <cfelseif ListFindNoCase("true,1,yes,sim", trim(qPerfil.is_admin))>
            <cfset VARIABLES.businessRealIsAdmin = true/>
        </cfif>
    </cfif>

    <cfset VARIABLES.businessEffectiveIsAdmin = VARIABLES.businessRealIsAdmin/>

    <cfif isDefined("qPerfil.id_pagina") AND len(trim(ValueList(qPerfil.id_pagina)))>
        <cfset VARIABLES.businessEffectivePaginaIds = ValueList(qPerfil.id_pagina)/>
    </cfif>

    <cftry>
        <cfquery name="qBusinessAccountContextTableCheck">
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name IN (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_contas"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_usuarios"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_eventos"/>
              )
        </cfquery>

        <cfset VARIABLES.businessAccountContextTableNames = ValueList(qBusinessAccountContextTableCheck.table_name)/>
        <cfset VARIABLES.businessAccountContextTablesReady = ListFindNoCase(VARIABLES.businessAccountContextTableNames, "tb_contas")
            AND ListFindNoCase(VARIABLES.businessAccountContextTableNames, "tb_conta_usuarios")
            AND ListFindNoCase(VARIABLES.businessAccountContextTableNames, "tb_conta_eventos")/>

        <cfif VARIABLES.businessAccountContextTablesReady>
            <cfif VARIABLES.businessRealIsAdmin AND isDefined("URL.business_account_context_id")>
                <cfset VARIABLES.businessAccountContextRequestedId = trim(URL.business_account_context_id)/>

                <cfif len(VARIABLES.businessAccountContextRequestedId) AND isNumeric(VARIABLES.businessAccountContextRequestedId) AND val(VARIABLES.businessAccountContextRequestedId) GT 0>
                    <cfquery name="qBusinessAccountContextRequested">
                        SELECT id_conta
                        FROM tb_contas
                        WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessAccountContextRequestedId#"/>
                        LIMIT 1
                    </cfquery>

                    <cfif qBusinessAccountContextRequested.recordcount>
                        <cfset SESSION.businessSimulatedAccountId = qBusinessAccountContextRequested.id_conta/>
                    <cfelse>
                        <cfset StructDelete(SESSION, "businessSimulatedAccountId", false)/>
                    </cfif>
                <cfelse>
                    <cfset StructDelete(SESSION, "businessSimulatedAccountId", false)/>
                </cfif>

                <cfset VARIABLES.businessAccountContextRedirect = isDefined("URL.business_account_context_redirect") ? trim(URL.business_account_context_redirect) : "/"/>
                <cfif NOT len(VARIABLES.businessAccountContextRedirect)
                    OR left(VARIABLES.businessAccountContextRedirect, 1) NEQ "/"
                    OR reFindNoCase("^//|^https?://", VARIABLES.businessAccountContextRedirect)
                    OR findNoCase("business_account_context_id", VARIABLES.businessAccountContextRedirect)>
                    <cfset VARIABLES.businessAccountContextRedirect = "/"/>
                </cfif>

                <cflocation addtoken="false" url="#VARIABLES.businessAccountContextRedirect#"/>
            </cfif>

            <cfif VARIABLES.businessRealIsAdmin>
                <cfquery name="qBusinessAccountContextOptions">
                    SELECT cont.id_conta,
                           cont.nome_conta,
                           cont.status::text AS status,
                           count(cu.id_conta_usuario) AS total_usuarios
                    FROM tb_contas cont
                    LEFT JOIN tb_conta_usuarios cu ON cu.id_conta = cont.id_conta
                    GROUP BY cont.id_conta
                    ORDER BY CASE cont.status
                        WHEN 'ATIVA'::status_conta THEN 1
                        WHEN 'PENDENTE'::status_conta THEN 2
                        WHEN 'SUSPENSA'::status_conta THEN 3
                        ELSE 4
                    END,
                    cont.nome_conta
                </cfquery>
            </cfif>

            <cfif VARIABLES.businessRealIsAdmin
                AND StructKeyExists(SESSION, "businessSimulatedAccountId")
                AND len(trim(SESSION.businessSimulatedAccountId))
                AND isNumeric(SESSION.businessSimulatedAccountId)>

                <cfquery name="qBusinessSimulatedAccount">
                    SELECT id_conta,
                           nome_conta,
                           status::text AS status
                    FROM tb_contas
                    WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#SESSION.businessSimulatedAccountId#"/>
                    LIMIT 1
                </cfquery>

                <cfif qBusinessSimulatedAccount.recordcount>
                    <cfset VARIABLES.businessAccountSimulationActive = true/>
                    <cfset VARIABLES.businessEffectiveIsAdmin = false/>
                    <cfset VARIABLES.businessSimulatedAccountId = qBusinessSimulatedAccount.id_conta/>
                    <cfset VARIABLES.businessEffectiveAccountIds = qBusinessSimulatedAccount.id_conta/>
                    <cfset VARIABLES.businessEffectiveAccountManagerIds = qBusinessSimulatedAccount.id_conta/>
                    <cfset VARIABLES.businessEffectiveAccountOperatorIds = qBusinessSimulatedAccount.id_conta/>
                    <cfset VARIABLES.businessEffectiveAccountViewerIds = qBusinessSimulatedAccount.id_conta/>
                    <cfset VARIABLES.businessCurrentAccountRole = "OWNER"/>
                <cfelse>
                    <cfset StructDelete(SESSION, "businessSimulatedAccountId", false)/>
                </cfif>
            </cfif>

            <cfif NOT VARIABLES.businessRealIsAdmin>
                <cfquery name="qBusinessAccountContextMemberships">
                    SELECT cu.id_conta,
                           cu.papel::text AS papel,
                           cu.status::text AS status
                    FROM tb_conta_usuarios cu
                    INNER JOIN tb_contas cont ON cont.id_conta = cu.id_conta
                    WHERE cu.id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
                      AND cu.status = 'ATIVO'::status_usuario_conta
                      AND cont.status = 'ATIVA'::status_conta
                    ORDER BY CASE cu.papel
                        WHEN 'OWNER'::papel_usuario_conta THEN 1
                        WHEN 'ADMIN'::papel_usuario_conta THEN 2
                        WHEN 'OPERADOR'::papel_usuario_conta THEN 3
                        ELSE 4
                    END,
                    cu.id_conta
                </cfquery>

                <cfquery name="qBusinessAccountContextAccounts">
                    SELECT DISTINCT cont.id_conta,
                           cont.nome_conta,
                           cont.status::text AS status
                    FROM tb_conta_usuarios cu
                    INNER JOIN tb_contas cont ON cont.id_conta = cu.id_conta
                    WHERE cu.id_usuario = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>
                      AND cu.status = 'ATIVO'::status_usuario_conta
                      AND cont.status = 'ATIVA'::status_conta
                    ORDER BY cont.nome_conta
                </cfquery>

                <cfif qBusinessAccountContextMemberships.recordcount AND len(trim(ValueList(qBusinessAccountContextMemberships.id_conta)))>
                    <cfset VARIABLES.businessEffectiveAccountIds = ValueList(qBusinessAccountContextMemberships.id_conta)/>
                    <cfset VARIABLES.businessEffectiveAccountViewerIds = VARIABLES.businessEffectiveAccountIds/>
                    <cfset VARIABLES.businessAccountManagerIdList = ""/>
                    <cfset VARIABLES.businessAccountOperatorIdList = ""/>

                    <cfloop query="qBusinessAccountContextMemberships">
                        <cfif NOT len(VARIABLES.businessCurrentAccountRole)>
                            <cfset VARIABLES.businessCurrentAccountRole = qBusinessAccountContextMemberships.papel/>
                        </cfif>

                        <cfif ListFindNoCase("OWNER,ADMIN", qBusinessAccountContextMemberships.papel)>
                            <cfset VARIABLES.businessAccountManagerIdList = ListAppend(VARIABLES.businessAccountManagerIdList, qBusinessAccountContextMemberships.id_conta)/>
                        </cfif>

                        <cfif ListFindNoCase("OWNER,ADMIN,OPERADOR", qBusinessAccountContextMemberships.papel)>
                            <cfset VARIABLES.businessAccountOperatorIdList = ListAppend(VARIABLES.businessAccountOperatorIdList, qBusinessAccountContextMemberships.id_conta)/>
                        </cfif>
                    </cfloop>

                    <cfif len(trim(VARIABLES.businessAccountManagerIdList))>
                        <cfset VARIABLES.businessEffectiveAccountManagerIds = VARIABLES.businessAccountManagerIdList/>
                    </cfif>

                    <cfif len(trim(VARIABLES.businessAccountOperatorIdList))>
                        <cfset VARIABLES.businessEffectiveAccountOperatorIds = VARIABLES.businessAccountOperatorIdList/>
                    </cfif>
                </cfif>
            </cfif>

            <cfif len(trim(VARIABLES.businessEffectiveAccountIds)) AND VARIABLES.businessEffectiveAccountIds NEQ "0">
                <cfquery name="qBusinessAccountContextUsers">
                    SELECT DISTINCT usr.id AS id_usuario,
                           usr.name,
                           usr.email,
                           cu.papel::text AS papel,
                           cu.status::text AS status
                    FROM tb_conta_usuarios cu
                    INNER JOIN tb_usuarios usr ON usr.id = cu.id_usuario
                    WHERE cu.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
                      AND cu.status = 'ATIVO'::status_usuario_conta
                    ORDER BY usr.name, usr.email
                </cfquery>

                <cfif qBusinessAccountContextUsers.recordcount>
                    <cfset VARIABLES.businessEffectiveUserIds = ValueList(qBusinessAccountContextUsers.id_usuario)/>

                    <cfquery name="qBusinessAccountContextPages">
                        SELECT DISTINCT pgusr.id_pagina
                        FROM tb_paginas_usuarios pgusr
                        WHERE pgusr.id_usuario IN (
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.businessEffectiveUserIds#" list="true"/>
                        )
                    </cfquery>

                    <cfif qBusinessAccountContextPages.recordcount AND len(trim(ValueList(qBusinessAccountContextPages.id_pagina)))>
                        <cfset VARIABLES.businessEffectivePaginaIds = ValueList(qBusinessAccountContextPages.id_pagina)/>
                    <cfelse>
                        <cfset VARIABLES.businessEffectivePaginaIds = "0"/>
                    </cfif>
                <cfelseif VARIABLES.businessAccountSimulationActive>
                    <cfset VARIABLES.businessEffectiveUserIds = "0"/>
                    <cfset VARIABLES.businessEffectivePaginaIds = "0"/>
                </cfif>
            </cfif>
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.businessAccountContextTablesReady = false/>
            <cfset VARIABLES.businessAccountSimulationActive = false/>
            <cfset VARIABLES.businessEffectiveIsAdmin = VARIABLES.businessRealIsAdmin/>
            <cfset VARIABLES.businessEffectiveAccountIds = "0"/>
            <cfset VARIABLES.businessEffectiveAccountManagerIds = "0"/>
            <cfset VARIABLES.businessEffectiveAccountOperatorIds = "0"/>
            <cfset VARIABLES.businessEffectiveAccountViewerIds = "0"/>
            <cfset VARIABLES.businessCurrentAccountRole = ""/>
        </cfcatch>
    </cftry>
</cfif>
