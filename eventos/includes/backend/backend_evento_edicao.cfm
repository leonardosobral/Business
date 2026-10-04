<cfinclude template="event_delegation.cfm"/>
<cfinclude template="event_mutations.cfm"/>
<cfset VARIABLES.eventDelegated=eventDelegationActive()/>
<cfif VARIABLES.eventDelegated>
    <cfset VARIABLES.adminIsAdmin=false/>
    <cfset VARIABLES.qEventosConta=eventDelegationEvents()/>
    <cfif structKeyExists(FORM,"action")>
        <cfset eventDelegationAssertAction(FORM.action)/>
    </cfif>
</cfif>
<!--- EDITAR DADOS DO EVENTO --->

<cfset VARIABLES.adminRestrictByConta = NOT (isDefined("VARIABLES.adminIsAdmin") AND VARIABLES.adminIsAdmin)/>
<cfset VARIABLES.adminEventosContaIds = "0"/>
<cfset VARIABLES.adminIsEventoSolicitacaoPost = isDefined("FORM.evento_solicitacao_action")
    AND ListFindNoCase("solicitar,aprovar,negar", FORM.evento_solicitacao_action)/>
<cfset VARIABLES.adminEventoTagAdjusted = false/>
<cfset VARIABLES.adminEventoRequestedTag = ""/>
<cfset VARIABLES.adminEventoResolvedTag = ""/>



<cfif isDefined("qEventosConta") AND qEventosConta.recordcount>
    <cfset VARIABLES.adminEventosContaIds = ValueList(qEventosConta.id_evento)/>
</cfif>

<cfif structKeyExists(FORM,"action") AND listFind("editar_evento_basico,editar_evento_fornecedores,editar_evento_competition_id,editar_evento_descricao,editar_evento_percursos,salvar_evento_percurso",FORM.action)>
    <cfset eventDelegationMutation(FORM,"events.manage",{type="EVENT",id=FORM.id_evento},eventMutationEdit,VARIABLES)/>
    <cfif FORM.action EQ "editar_evento_basico" AND FORM.id_evento EQ 0 AND structKeyExists(VARIABLES,"qInsert")>
        <cflocation addtoken="false" url="/eventos/?id_evento=#VARIABLES.qInsert.id_evento#"/>
    </cfif>
</cfif>

<cfif VARIABLES.adminRestrictByConta
    AND isDefined("URL.id_evento")
    AND len(trim(URL.id_evento))
    AND isNumeric(URL.id_evento)
    AND val(URL.id_evento) EQ 0>

    <cflocation addtoken="false" url="./?solicitacao=evento_admin&periodo=#URL.periodo#&busca=#urlEncodedFormat(URL.busca)#&estado=#URL.estado#"/>
</cfif>

<cfif VARIABLES.adminRestrictByConta
    AND isDefined("URL.id_evento")
    AND len(trim(URL.id_evento))
    AND isNumeric(URL.id_evento)
    AND val(URL.id_evento) NEQ 0
    AND NOT listFind(VARIABLES.adminEventosContaIds, URL.id_evento)>

    <cflocation addtoken="false" url="./?periodo=#URL.periodo#&busca=#urlEncodedFormat(URL.busca)#&estado=#URL.estado#"/>
</cfif>

<cfif VARIABLES.adminRestrictByConta
    AND NOT VARIABLES.adminIsEventoSolicitacaoPost
    AND isDefined("FORM.id_evento")
    AND len(trim(FORM.id_evento))
    AND isNumeric(FORM.id_evento)
    AND val(FORM.id_evento) NEQ 0
    AND NOT listFind(VARIABLES.adminEventosContaIds, FORM.id_evento)>

    <cflocation addtoken="false" url="./?periodo=#URL.periodo#&busca=#urlEncodedFormat(URL.busca)#&estado=#URL.estado#"/>
</cfif>

<cfinclude template="inscricao_disponibilidade.cfm"/>

<!--- EDITAR CONFIGURACOES DO EVENTO --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_configuracoes" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento)) AND isDefined("VARIABLES.adminIsAdmin") AND VARIABLES.adminIsAdmin>

    <cfif val(FORM.id_agrega_evento) GT 0>
        <cfquery name="qEdicaoTipoValido">
            SELECT id_agrega_evento FROM tb_agrega_eventos
            WHERE id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_agrega_evento#" />
              AND lower(trim(tipo_agregacao)) <> 'circuito'
        </cfquery>
        <cfif NOT qEdicaoTipoValido.recordcount>
            <cfthrow message="Selecione um grupo de edições. Circuitos devem ser vinculados em Agregadores e circuitos." />
        </cfif>
    </cfif>

    <cfquery>
        UPDATE tb_evento_corridas
        SET
        destaque = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.destaque#" null="#NOT len(trim(FORM.destaque))#"/>,
        info_duplicado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.info_duplicado#" null="#NOT len(trim(FORM.info_duplicado))#"/>,
        status_evento = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.status_evento#" null="#NOT len(trim(FORM.status_evento))#"/>,
        ativo = <cfqueryparam cfsqltype="cf_sql_bit" value="#FORM.ativo#"/>,
        id_tema = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_tema#"/>,
        id_agrega_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_agrega_evento#" null="#NOT len(trim(FORM.id_agrega_evento))#"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EDITAR CONFIGURACOES DO OR (RESULTADOS) --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_or" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento)) AND isDefined("VARIABLES.adminIsAdmin") AND VARIABLES.adminIsAdmin>

    <cfquery>
        UPDATE tb_evento_corridas
        SET
        obs_resultado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.obs_resultado#" null="#NOT len(trim(FORM.obs_resultado))#"/>,
        obs_homologacao = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.obs_homologacao#" null="#NOT len(trim(FORM.obs_homologacao))#"/>,
        ranking = <cfqueryparam cfsqltype="cf_sql_bit" value="#FORM.ranking#" null="#NOT len(trim(FORM.ranking))#"/>,
        homologado = <cfqueryparam cfsqltype="cf_sql_bit" value="#FORM.homologado#" null="#NOT len(trim(FORM.homologado))#"/>,
        url_resultado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_resultado#"/>,
        url_wiclax = <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.url_wiclax#"/>
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EDITAR FORNECEDORES --->

<!--- EDITAR AGRAGADORES --->

<cfif isDefined("FORM.action") AND FORM.action EQ "editar_evento_agregadores" AND isDefined("FORM.agregador_tag") AND Len(trim(FORM.agregador_tag)) AND isDefined("VARIABLES.adminIsAdmin") AND VARIABLES.adminIsAdmin>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_agregadores_eventos
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfloop list="#FORM.agregador_tag#" item="item" index="index" delimiters=",">
        <cfquery>
            INSERT INTO tb_agregadores_eventos
            (agregador_tag, id_evento)
            VALUES
            (
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#listToArray(FORM.agregador_tag, ',')[index]#"/>,
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
            )
        </cfquery>
    </cfloop>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.agregador_tag#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

    <cflocation addtoken="false" url="./?preset=#URL.preset#&periodo=#URL.periodo#&busca=#URL.busca#&regiao=#URL.regiao#&estado=#URL.estado#&cidade=#URL.cidade#&id_agrega_evento=#URL.id_agrega_evento#&agregador_tag=#URL.agregador_tag#&id_evento=#FORM.id_evento#&sessao=configuracoes"/>

</cfif>



<!--- EDITAR INTEGRACOES --->

<!--- EXCLUIR EVENTO --->

<cfif isDefined("FORM.action") AND FORM.action EQ "excluir_evento" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento)) AND isDefined("VARIABLES.adminIsAdmin") AND VARIABLES.adminIsAdmin>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas_fornecedores
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas_percursos
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas_relaciona
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfif isDefined("FORM.aceite")>

         <cfquery datasource="runner_dba">
            DELETE FROM tb_resultados_resumo
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

        <cfquery datasource="runner_dba">
            DELETE FROM tb_resultados
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

    </cfif>

    <cfquery datasource="runner_dba">
        DELETE FROM tb_evento_corridas
        WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
    </cfquery>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

    <cflocation url="./?periodo=#URL.periodo#&busca=#urlEncodedFormat(URL.busca)#&estado=#URL.estado#" addtoken="false"/>

</cfif>


<!--- EXCLUIR RESULTADOS --->

<cfif isDefined("FORM.action") AND FORM.action EQ "excluir_resultados" AND isDefined("FORM.id_evento") AND Len(trim(FORM.id_evento)) AND isDefined("VARIABLES.adminIsAdmin") AND VARIABLES.adminIsAdmin>

    <cfif isDefined("FORM.aceite")>

        <cfquery datasource="runner_dba">
            DELETE FROM tb_resultados_resumo
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

        <cfquery datasource="runner_dba">
            DELETE FROM tb_resultados
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
        </cfquery>

    </cfif>

    <cfquery>
        INSERT INTO tb_log
        (log_item, log_item_id, log_user, site)
        VALUES
        (<cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.action#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#REQUEST.businessIdentity.id#,#FORM.id_evento#"/>,<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#"/>, 'RH')
    </cfquery>

</cfif>


<!--- EDITAR DESCRICAO --->

<!--- EDITAR PERCURSOS --->

<!--- SALVAR PERCURSOS --->

<!--- DADOS DO EVENTO EDITADO --->

<cfif Len(trim(URL.id_evento))>
    <cfquery name="qEvento">
        SELECT evt.*
        FROM tb_evento_corridas evt
        WHERE evt.id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_evento#"/>
    </cfquery>
<cfelse>
    <cfquery name="qEvento">
        SELECT evt.*
        FROM tb_evento_corridas evt
        WHERE evt.id_evento = 0
    </cfquery>
</cfif>
