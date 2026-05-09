<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfset VARIABLES.configPage = max(1, int(URL.pagina))/>

<cfquery name="qTreinoConfigColumns">
    SELECT column_name, data_type, is_nullable, column_default, character_maximum_length
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'tb_evento_treinos_config'
    ORDER BY ordinal_position
</cfquery>

<cfset VARIABLES.treinoConfigColumns = ValueList(qTreinoConfigColumns.column_name)/>
<cfset VARIABLES.treinoConfigPk = ""/>
<cfset VARIABLES.treinoConfigSelectColumns = ""/>
<cfset VARIABLES.treinoConfigFormExcludedColumns = "created_at,updated_at,createdon,modifiedon,data_cadastro,data_atualizacao,data_criacao,data_alteracao,criado_em,atualizado_em"/>
<cfset VARIABLES.treinoConfigCreatedColumn = ""/>
<cfset VARIABLES.treinoConfigUpdatedColumn = ""/>

<cfloop list="id_evento_treinos_config,id_evento_treino_config,id_treino_config,id_config,id" item="treinoConfigPkCandidate">
    <cfif NOT len(trim(VARIABLES.treinoConfigPk)) AND ListFindNoCase(VARIABLES.treinoConfigColumns, treinoConfigPkCandidate)>
        <cfset VARIABLES.treinoConfigPk = treinoConfigPkCandidate/>
    </cfif>
</cfloop>

<cfif NOT len(trim(VARIABLES.treinoConfigPk)) AND qTreinoConfigColumns.recordcount>
    <cfset VARIABLES.treinoConfigPk = qTreinoConfigColumns.column_name/>
</cfif>

<cfloop query="qTreinoConfigColumns">
    <cfset VARIABLES.treinoConfigSelectColumns = ListAppend(VARIABLES.treinoConfigSelectColumns, '"' & Replace(qTreinoConfigColumns.column_name, '"', '""', 'all') & '"')/>
    <cfif NOT len(trim(VARIABLES.treinoConfigCreatedColumn))
        AND ListFindNoCase("created_at,data_cadastro,data_criacao,criado_em,createdon", qTreinoConfigColumns.column_name)>
        <cfset VARIABLES.treinoConfigCreatedColumn = qTreinoConfigColumns.column_name/>
    </cfif>
    <cfif NOT len(trim(VARIABLES.treinoConfigUpdatedColumn))
        AND ListFindNoCase("updated_at,data_atualizacao,data_alteracao,atualizado_em,modifiedon", qTreinoConfigColumns.column_name)>
        <cfset VARIABLES.treinoConfigUpdatedColumn = qTreinoConfigColumns.column_name/>
    </cfif>
</cfloop>

<cfset VARIABLES.treinoConfigOrderColumn = len(trim(VARIABLES.treinoConfigPk)) ? VARIABLES.treinoConfigPk : (qTreinoConfigColumns.recordcount ? qTreinoConfigColumns.column_name : "")/>

<cfset VARIABLES.treinoConfigActiveColumn = ""/>
<cfloop query="qTreinoConfigColumns">
    <cfif NOT len(trim(VARIABLES.treinoConfigActiveColumn))
        AND lcase(qTreinoConfigColumns.data_type) EQ "boolean"
        AND ListFindNoCase("ativo,is_active,active,habilitado,enabled,status,pub_status", qTreinoConfigColumns.column_name)>
        <cfset VARIABLES.treinoConfigActiveColumn = qTreinoConfigColumns.column_name/>
    </cfif>
</cfloop>

<cfset VARIABLES.treinoConfigHasEvento = ListFindNoCase(VARIABLES.treinoConfigColumns, "id_evento")/>

<cfif VARIABLES.treinoConfigHasEvento>
    <cfquery name="qTreinoEventos">
        SELECT id_evento, nome_evento
        FROM tb_evento_corridas
        WHERE tipo_corrida = <cfqueryparam cfsqltype="cf_sql_varchar" value="treino"/>
        ORDER BY data_final DESC, nome_evento
    </cfquery>
<cfelse>
    <cfset qTreinoEventos = QueryNew("id_evento,nome_evento")/>
</cfif>

<cfif isDefined("FORM.config_action")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND FORM.config_action EQ "salvar"
    AND len(trim(VARIABLES.treinoConfigPk))
    AND qTreinoConfigColumns.recordcount>

    <cfif isDefined("FORM.config_record_id") AND len(trim(FORM.config_record_id))>
        <cfquery>
            UPDATE tb_evento_treinos_config
            SET
            <cfset VARIABLES.treinoConfigFieldSeparator = ""/>
            <cfloop query="qTreinoConfigColumns">
                <cfif qTreinoConfigColumns.column_name NEQ VARIABLES.treinoConfigPk
                    AND NOT ListFindNoCase(VARIABLES.treinoConfigFormExcludedColumns, qTreinoConfigColumns.column_name)
                    AND StructKeyExists(FORM, "config_" & qTreinoConfigColumns.column_name)>
                    <cfset VARIABLES.treinoConfigFieldValue = FORM["config_" & qTreinoConfigColumns.column_name]/>
                    <cfset VARIABLES.treinoConfigFieldType = lcase(qTreinoConfigColumns.data_type)/>
                    <cfif VARIABLES.treinoConfigFieldType EQ "boolean">
                        <cfset VARIABLES.treinoConfigFieldValue = ListFindNoCase(VARIABLES.treinoConfigFieldValue, "true")
                            OR ListFindNoCase(VARIABLES.treinoConfigFieldValue, "1")
                            OR ListFindNoCase(VARIABLES.treinoConfigFieldValue, "yes")
                            OR ListFindNoCase(VARIABLES.treinoConfigFieldValue, "sim")
                            OR ListFindNoCase(VARIABLES.treinoConfigFieldValue, "on")/>
                    </cfif>
                    <cfset VARIABLES.treinoConfigFieldNullable = qTreinoConfigColumns.is_nullable EQ "YES"/>
                    <cfset VARIABLES.treinoConfigFieldHasValue = VARIABLES.treinoConfigFieldType EQ "boolean" OR (isSimpleValue(VARIABLES.treinoConfigFieldValue) AND len(trim(VARIABLES.treinoConfigFieldValue)))/>
                    <cfset VARIABLES.treinoConfigFieldIsNull = VARIABLES.treinoConfigFieldType NEQ "boolean" AND NOT VARIABLES.treinoConfigFieldHasValue/>
                    #VARIABLES.treinoConfigFieldSeparator#"#Replace(qTreinoConfigColumns.column_name, '"', '""', 'all')#" =
                    <cfswitch expression="#VARIABLES.treinoConfigFieldType#">
                        <cfcase value="boolean">
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.treinoConfigFieldValue#"/>
                        </cfcase>
                        <cfcase value="integer,smallint">
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="bigint">
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="numeric,decimal,real,double precision">
                            <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="date">
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="timestamp without time zone,timestamp with time zone">
                            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfdefaultcase>
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfdefaultcase>
                    </cfswitch>
                    <cfset VARIABLES.treinoConfigFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            <cfif len(trim(VARIABLES.treinoConfigUpdatedColumn))>
                #VARIABLES.treinoConfigFieldSeparator#"#Replace(VARIABLES.treinoConfigUpdatedColumn, '"', '""', 'all')#" = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
            </cfif>
            WHERE "#Replace(VARIABLES.treinoConfigPk, '"', '""', 'all')#" =
            <cfif IsNumeric(FORM.config_record_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.config_record_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#FORM.config_record_id#"/>
            </cfif>
        </cfquery>
    <cfelse>
        <cfquery>
            INSERT INTO tb_evento_treinos_config (
            <cfset VARIABLES.treinoConfigFieldSeparator = ""/>
            <cfloop query="qTreinoConfigColumns">
                <cfif qTreinoConfigColumns.column_name NEQ VARIABLES.treinoConfigPk
                    AND NOT ListFindNoCase(VARIABLES.treinoConfigFormExcludedColumns, qTreinoConfigColumns.column_name)
                    AND StructKeyExists(FORM, "config_" & qTreinoConfigColumns.column_name)>
                    #VARIABLES.treinoConfigFieldSeparator#"#Replace(qTreinoConfigColumns.column_name, '"', '""', 'all')#"
                    <cfset VARIABLES.treinoConfigFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            <cfif len(trim(VARIABLES.treinoConfigCreatedColumn))>
                #VARIABLES.treinoConfigFieldSeparator#"#Replace(VARIABLES.treinoConfigCreatedColumn, '"', '""', 'all')#"
                <cfset VARIABLES.treinoConfigFieldSeparator = ", "/>
            </cfif>
            <cfif len(trim(VARIABLES.treinoConfigUpdatedColumn)) AND VARIABLES.treinoConfigUpdatedColumn NEQ VARIABLES.treinoConfigCreatedColumn>
                #VARIABLES.treinoConfigFieldSeparator#"#Replace(VARIABLES.treinoConfigUpdatedColumn, '"', '""', 'all')#"
                <cfset VARIABLES.treinoConfigFieldSeparator = ", "/>
            </cfif>
            ) VALUES (
            <cfset VARIABLES.treinoConfigFieldSeparator = ""/>
            <cfloop query="qTreinoConfigColumns">
                <cfif qTreinoConfigColumns.column_name NEQ VARIABLES.treinoConfigPk
                    AND NOT ListFindNoCase(VARIABLES.treinoConfigFormExcludedColumns, qTreinoConfigColumns.column_name)
                    AND StructKeyExists(FORM, "config_" & qTreinoConfigColumns.column_name)>
                    <cfset VARIABLES.treinoConfigFieldValue = FORM["config_" & qTreinoConfigColumns.column_name]/>
                    <cfset VARIABLES.treinoConfigFieldType = lcase(qTreinoConfigColumns.data_type)/>
                    <cfif VARIABLES.treinoConfigFieldType EQ "boolean">
                        <cfset VARIABLES.treinoConfigFieldValue = ListFindNoCase(VARIABLES.treinoConfigFieldValue, "true")
                            OR ListFindNoCase(VARIABLES.treinoConfigFieldValue, "1")
                            OR ListFindNoCase(VARIABLES.treinoConfigFieldValue, "yes")
                            OR ListFindNoCase(VARIABLES.treinoConfigFieldValue, "sim")
                            OR ListFindNoCase(VARIABLES.treinoConfigFieldValue, "on")/>
                    </cfif>
                    <cfset VARIABLES.treinoConfigFieldNullable = qTreinoConfigColumns.is_nullable EQ "YES"/>
                    <cfset VARIABLES.treinoConfigFieldHasValue = VARIABLES.treinoConfigFieldType EQ "boolean" OR (isSimpleValue(VARIABLES.treinoConfigFieldValue) AND len(trim(VARIABLES.treinoConfigFieldValue)))/>
                    <cfset VARIABLES.treinoConfigFieldIsNull = VARIABLES.treinoConfigFieldType NEQ "boolean" AND NOT VARIABLES.treinoConfigFieldHasValue/>
                    #VARIABLES.treinoConfigFieldSeparator#
                    <cfswitch expression="#VARIABLES.treinoConfigFieldType#">
                        <cfcase value="boolean">
                            <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.treinoConfigFieldValue#"/>
                        </cfcase>
                        <cfcase value="integer,smallint">
                            <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="bigint">
                            <cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="numeric,decimal,real,double precision">
                            <cfqueryparam cfsqltype="cf_sql_numeric" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="date">
                            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfcase value="timestamp without time zone,timestamp with time zone">
                            <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfcase>
                        <cfdefaultcase>
                            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.treinoConfigFieldValue#" null="#VARIABLES.treinoConfigFieldIsNull#"/>
                        </cfdefaultcase>
                    </cfswitch>
                    <cfset VARIABLES.treinoConfigFieldSeparator = ", "/>
                </cfif>
            </cfloop>
            <cfif len(trim(VARIABLES.treinoConfigCreatedColumn))>
                #VARIABLES.treinoConfigFieldSeparator#<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                <cfset VARIABLES.treinoConfigFieldSeparator = ", "/>
            </cfif>
            <cfif len(trim(VARIABLES.treinoConfigUpdatedColumn)) AND VARIABLES.treinoConfigUpdatedColumn NEQ VARIABLES.treinoConfigCreatedColumn>
                #VARIABLES.treinoConfigFieldSeparator#<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
                <cfset VARIABLES.treinoConfigFieldSeparator = ", "/>
            </cfif>
            )
        </cfquery>
    </cfif>

    <cflocation addtoken="false" url="./?pagina=#VARIABLES.configPage#"/>
</cfif>

<cfif isDefined("URL.config_acao")
    AND isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND len(trim(VARIABLES.treinoConfigPk))
    AND isDefined("URL.config_id")>

    <cfif URL.config_acao EQ "status"
        AND len(trim(VARIABLES.treinoConfigActiveColumn))
        AND isDefined("URL.status")>
        <cfquery>
            UPDATE tb_evento_treinos_config
            SET "#Replace(VARIABLES.treinoConfigActiveColumn, '"', '""', 'all')#" = <cfqueryparam cfsqltype="cf_sql_bit" value="#URL.status#"/>
            WHERE "#Replace(VARIABLES.treinoConfigPk, '"', '""', 'all')#" =
            <cfif IsNumeric(URL.config_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.config_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.config_id#"/>
            </cfif>
        </cfquery>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.configPage#"/>
    </cfif>

    <cfif URL.config_acao EQ "excluir">
        <cfquery>
            DELETE FROM tb_evento_treinos_config
            WHERE "#Replace(VARIABLES.treinoConfigPk, '"', '""', 'all')#" =
            <cfif IsNumeric(URL.config_id)>
                <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.config_id#"/>
            <cfelse>
                <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.config_id#"/>
            </cfif>
        </cfquery>

        <cflocation addtoken="false" url="./?pagina=#VARIABLES.configPage#"/>
    </cfif>
</cfif>

<cfquery name="qTreinoConfigCount">
    SELECT count(*) as total
    FROM tb_evento_treinos_config
</cfquery>

<cfif qTreinoConfigColumns.recordcount>
    <cfquery name="qTreinoConfigs">
        SELECT #PreserveSingleQuotes(VARIABLES.treinoConfigSelectColumns)#
        FROM tb_evento_treinos_config
        ORDER BY "#Replace(VARIABLES.treinoConfigOrderColumn, '"', '""', 'all')#" DESC
    </cfquery>
<cfelse>
    <cfset qTreinoConfigs = QueryNew("")/>
</cfif>

<cfset qTreinoConfigEdit = QueryNew("")/>

<cfif qTreinoConfigColumns.recordcount
    AND len(trim(VARIABLES.treinoConfigPk))
    AND isDefined("URL.config_editar")
    AND len(trim(URL.config_editar))>
    <cfquery name="qTreinoConfigEdit">
        SELECT #PreserveSingleQuotes(VARIABLES.treinoConfigSelectColumns)#
        FROM tb_evento_treinos_config
        WHERE "#Replace(VARIABLES.treinoConfigPk, '"', '""', 'all')#" =
        <cfif IsNumeric(URL.config_editar)>
            <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.config_editar#"/>
        <cfelse>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#URL.config_editar#"/>
        </cfif>
        LIMIT 1
    </cfquery>
</cfif>

<cfset VARIABLES.treinoConfigEventoNome = ""/>

<cfif VARIABLES.treinoConfigHasEvento
    AND qTreinoConfigEdit.recordcount
    AND StructKeyExists(qTreinoConfigEdit, "id_evento")
    AND len(trim(qTreinoConfigEdit.id_evento[1]))>
    <cfquery name="qTreinoConfigEventoAtual">
        SELECT id_evento, nome_evento
        FROM tb_evento_corridas
        WHERE id_evento =
        <cfif IsNumeric(qTreinoConfigEdit.id_evento[1])>
            <cfqueryparam cfsqltype="cf_sql_integer" value="#qTreinoConfigEdit.id_evento[1]#"/>
        <cfelse>
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#qTreinoConfigEdit.id_evento[1]#"/>
        </cfif>
        LIMIT 1
    </cfquery>

    <cfif qTreinoConfigEventoAtual.recordcount>
        <cfset VARIABLES.treinoConfigEventoNome = qTreinoConfigEventoAtual.nome_evento[1]/>
    </cfif>
</cfif>
