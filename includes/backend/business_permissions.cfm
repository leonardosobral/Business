<cfset VARIABLES.businessPermissionSchemaReady = false/>
<cfset VARIABLES.businessIntegrationResultSchemaReady = false/>
<cfset VARIABLES.businessPermissionCodes = ""/>
<cfset VARIABLES.businessPermissionAccountId = ""/>
<cfset qBusinessResultImportIntegrations = QueryNew("id_conta_integracao_resultado,id_conta,client_id,cod_timer,external_account_id,abrange_contas_externas")/>

<cffunction name="businessHasPermission" access="public" returntype="boolean" output="false">
    <cfargument name="permissionCode" type="string" required="true"/>

    <cfif isDefined("VARIABLES.businessEffectiveIsAdmin")>
        <cfif isBoolean(VARIABLES.businessEffectiveIsAdmin) AND VARIABLES.businessEffectiveIsAdmin>
            <cfreturn true/>
        <cfelseif NOT isBoolean(VARIABLES.businessEffectiveIsAdmin)
            AND listFindNoCase("true,1,yes,sim", trim(VARIABLES.businessEffectiveIsAdmin & ""))>
            <cfreturn true/>
        </cfif>
    </cfif>

    <cfreturn VARIABLES.businessPermissionSchemaReady
        AND listFindNoCase(VARIABLES.businessPermissionCodes, trim(arguments.permissionCode)) GT 0/>
</cffunction>

<cfif isDefined("qPerfil") AND qPerfil.recordcount>
    <cftry>
        <cfquery name="qBusinessPermissionSchema">
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name IN (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_business_permissoes"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_permissoes"/>,
                <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_conta_integracoes_resultados"/>
              )
        </cfquery>

        <cfset VARIABLES.businessPermissionTableNames = ValueList(qBusinessPermissionSchema.table_name)/>
        <cfset VARIABLES.businessPermissionSchemaReady = listFindNoCase(VARIABLES.businessPermissionTableNames, "tb_business_permissoes")
            AND listFindNoCase(VARIABLES.businessPermissionTableNames, "tb_conta_permissoes")/>
        <cfset VARIABLES.businessIntegrationResultSchemaReady = listFindNoCase(VARIABLES.businessPermissionTableNames, "tb_conta_integracoes_resultados") GT 0/>

        <cfif isDefined("VARIABLES.businessActiveAccountId")
            AND len(trim(VARIABLES.businessActiveAccountId & ""))
            AND isNumeric(VARIABLES.businessActiveAccountId)
            AND val(VARIABLES.businessActiveAccountId) GT 0>
            <cfset VARIABLES.businessPermissionAccountId = val(VARIABLES.businessActiveAccountId)/>
        </cfif>

        <cfif VARIABLES.businessPermissionSchemaReady
            AND len(VARIABLES.businessPermissionAccountId)
            AND isDefined("VARIABLES.businessCurrentAccountRole")
            AND len(trim(VARIABLES.businessCurrentAccountRole & ""))>
            <cfquery name="qBusinessEffectivePermissions">
                SELECT DISTINCT perm.codigo
                FROM public.tb_conta_permissoes grant_account
                INNER JOIN public.tb_business_permissoes perm
                    ON perm.id_permissao = grant_account.id_permissao
                   AND perm.ativo = true
                WHERE grant_account.id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessPermissionAccountId#"/>
                  AND (
                    grant_account.papel = CAST(<cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(trim(VARIABLES.businessCurrentAccountRole))#"/> AS papel_usuario_conta)
                    <cfif compareNoCase(trim(VARIABLES.businessCurrentAccountRole & ""), "OWNER") EQ 0>
                      OR grant_account.papel = 'ADMIN'::papel_usuario_conta
                    </cfif>
                  )
                  AND grant_account.ativo = true
                ORDER BY perm.codigo
            </cfquery>
            <cfset VARIABLES.businessPermissionCodes = ValueList(qBusinessEffectivePermissions.codigo)/>
        </cfif>

        <cfif VARIABLES.businessIntegrationResultSchemaReady AND len(VARIABLES.businessPermissionAccountId)>
            <cfquery name="qBusinessResultImportIntegrations">
                SELECT id_conta_integracao_resultado,
                       id_conta,
                       client_id,
                       cod_timer,
                       external_account_id,
                       abrange_contas_externas
                FROM public.tb_conta_integracoes_resultados
                WHERE id_conta = <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessPermissionAccountId#"/>
                  AND ativo = true
                ORDER BY client_id, cod_timer, external_account_id NULLS FIRST
            </cfquery>
        </cfif>

        <cfcatch type="any">
            <cfset VARIABLES.businessPermissionSchemaReady = false/>
            <cfset VARIABLES.businessIntegrationResultSchemaReady = false/>
            <cfset VARIABLES.businessPermissionCodes = ""/>
            <cfset qBusinessResultImportIntegrations = QueryNew("id_conta_integracao_resultado,id_conta,client_id,cod_timer,external_account_id,abrange_contas_externas")/>
        </cfcatch>
    </cftry>
</cfif>
