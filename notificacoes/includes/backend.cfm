<cfparam name="URL.pagina" default="1" type="numeric"/>
<cfparam name="URL.busca" default=""/>
<cfparam name="URL.template_id" default=""/>
<cfparam name="URL.campanha" default=""/>
<cfparam name="URL.leitura" default=""/>
<cfparam name="URL.data_publicacao_inicial" default=""/>
<cfparam name="URL.data_publicacao_final" default=""/>

<cfset VARIABLES.notificaPage = max(1, int(URL.pagina))/>
<cfset VARIABLES.notificaPerPage = 50/>
<cfset VARIABLES.notificaOffset = (VARIABLES.notificaPage - 1) * VARIABLES.notificaPerPage/>
<cfset VARIABLES.notificaBusca = trim(URL.busca)/>
<cfset VARIABLES.notificaTemplateId = trim(URL.template_id)/>
<cfset VARIABLES.notificaCampanha = trim(URL.campanha)/>
<cfset VARIABLES.notificaLeitura = trim(URL.leitura)/>
<cfset VARIABLES.notificaDataPublicacaoInicial = trim(URL.data_publicacao_inicial)/>
<cfset VARIABLES.notificaDataPublicacaoFinal = trim(URL.data_publicacao_final)/>
<cfset VARIABLES.notificaHistoryRedirectUrl = "./?pagina=" & VARIABLES.notificaPage/>

<cfif len(trim(VARIABLES.notificaBusca))><cfset VARIABLES.notificaHistoryRedirectUrl &= "&busca=" & urlEncodedFormat(VARIABLES.notificaBusca)/></cfif>
<cfif len(trim(VARIABLES.notificaTemplateId))><cfset VARIABLES.notificaHistoryRedirectUrl &= "&template_id=" & urlEncodedFormat(VARIABLES.notificaTemplateId)/></cfif>
<cfif len(trim(VARIABLES.notificaCampanha))><cfset VARIABLES.notificaHistoryRedirectUrl &= "&campanha=" & urlEncodedFormat(VARIABLES.notificaCampanha)/></cfif>
<cfif len(trim(VARIABLES.notificaLeitura))><cfset VARIABLES.notificaHistoryRedirectUrl &= "&leitura=" & urlEncodedFormat(VARIABLES.notificaLeitura)/></cfif>
<cfif len(trim(VARIABLES.notificaDataPublicacaoInicial))><cfset VARIABLES.notificaHistoryRedirectUrl &= "&data_publicacao_inicial=" & urlEncodedFormat(VARIABLES.notificaDataPublicacaoInicial)/></cfif>
<cfif len(trim(VARIABLES.notificaDataPublicacaoFinal))><cfset VARIABLES.notificaHistoryRedirectUrl &= "&data_publicacao_final=" & urlEncodedFormat(VARIABLES.notificaDataPublicacaoFinal)/></cfif>

<cfset VARIABLES.notificaDataPublicacaoInicialValue = ""/>
<cfset VARIABLES.notificaDataPublicacaoFinalValue = ""/>

<cfif len(trim(VARIABLES.notificaDataPublicacaoInicial))>
    <cfset VARIABLES.notificaDataPublicacaoInicialValue = Replace(VARIABLES.notificaDataPublicacaoInicial, "T", " ", "one")/>
    <cfif reFind("^\d{4}-\d{2}-\d{2}$", VARIABLES.notificaDataPublicacaoInicialValue)>
        <cfset VARIABLES.notificaDataPublicacaoInicialValue &= " 00:00:00"/>
    <cfelseif reFind("^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$", VARIABLES.notificaDataPublicacaoInicialValue)>
        <cfset VARIABLES.notificaDataPublicacaoInicialValue &= ":00"/>
    </cfif>
</cfif>

<cfif len(trim(VARIABLES.notificaDataPublicacaoFinal))>
    <cfset VARIABLES.notificaDataPublicacaoFinalValue = Replace(VARIABLES.notificaDataPublicacaoFinal, "T", " ", "one")/>
    <cfif reFind("^\d{4}-\d{2}-\d{2}$", VARIABLES.notificaDataPublicacaoFinalValue)>
        <cfset VARIABLES.notificaDataPublicacaoFinalValue &= " 23:59:59"/>
    <cfelseif reFind("^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$", VARIABLES.notificaDataPublicacaoFinalValue)>
        <cfset VARIABLES.notificaDataPublicacaoFinalValue &= ":59"/>
    </cfif>
</cfif>

<cfquery name="qNotificaTemplateColumns">
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'tb_notifica_template'
    ORDER BY ordinal_position
</cfquery>

<cfset VARIABLES.notificaTemplateColumns = ValueList(qNotificaTemplateColumns.column_name)/>
<cfset VARIABLES.notificaTemplateCampaignColumn = ""/>

<cfloop list="campanha,nome,name,titulo,title,assunto,subject" item="notificaTemplateCampaignCandidate">
    <cfif NOT len(trim(VARIABLES.notificaTemplateCampaignColumn)) AND ListFindNoCase(VARIABLES.notificaTemplateColumns, notificaTemplateCampaignCandidate)>
        <cfset VARIABLES.notificaTemplateCampaignColumn = notificaTemplateCampaignCandidate/>
    </cfif>
</cfloop>

<cfif len(trim(VARIABLES.notificaTemplateCampaignColumn))>
    <cfset VARIABLES.notificaTemplateCampaignSql = 'tpl."' & Replace(VARIABLES.notificaTemplateCampaignColumn, '"', '""', 'all') & '"'/>
<cfelse>
    <cfset VARIABLES.notificaTemplateCampaignSql = "''"/>
</cfif>

<cfif isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND isDefined("URL.acao")
    AND isDefined("URL.id_notifica")
    AND len(trim(URL.id_notifica))
    AND isNumeric(URL.id_notifica)>

    <cfif URL.acao EQ "desativar">
        <cfquery>
            UPDATE tb_notifica
            SET data_expiracao = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
            WHERE id_notifica = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_notifica#"/>
        </cfquery>
    <cfelseif URL.acao EQ "excluir">
        <cfquery>
            DELETE FROM tb_notifica
            WHERE id_notifica = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.id_notifica#"/>
        </cfquery>
    </cfif>

    <cflocation addtoken="false" url="#VARIABLES.notificaHistoryRedirectUrl#"/>
</cfif>

<cfif isDefined("qPerfil")
    AND qPerfil.recordcount
    AND qPerfil.is_admin
    AND isDefined("FORM.history_action")
    AND ListFindNoCase("desativar_filtradas,excluir_filtradas", FORM.history_action)>

    <cfif FORM.history_action EQ "desativar_filtradas">
        <cfquery>
            UPDATE tb_notifica ntf
            SET data_expiracao = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"/>
            FROM tb_usuarios usr
            WHERE usr.id = ntf.id_usuario
            <cfif len(trim(VARIABLES.notificaBusca))>
                AND (
                    <cfif isNumeric(VARIABLES.notificaBusca)>
                        ntf.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                        OR ntf.id_notifica = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                        OR ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                        OR
                    </cfif>
                    unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
                    OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
                    OR unaccent(upper(coalesce(ntf.link, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
                    OR unaccent(upper(coalesce(ntf.conteudo_notifica, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
                )
            </cfif>
            <cfif len(trim(VARIABLES.notificaTemplateId)) AND isNumeric(VARIABLES.notificaTemplateId)>
                AND ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaTemplateId#"/>
            </cfif>
            <cfif len(trim(VARIABLES.notificaCampanha))>
                AND EXISTS (
                    SELECT 1
                    FROM tb_notifica_template tpl
                    WHERE tpl.id_notifica_template = ntf.id_notifica_template
                    AND #PreserveSingleQuotes(VARIABLES.notificaTemplateCampaignSql)# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificaCampanha#"/>
                )
            </cfif>
            <cfif VARIABLES.notificaLeitura EQ "lidas">
                AND ntf.data_leitura IS NOT NULL
            <cfelseif VARIABLES.notificaLeitura EQ "nao_lidas">
                AND ntf.data_leitura IS NULL
            <cfelseif VARIABLES.notificaLeitura EQ "ativas">
                AND ((now() between ntf.data_publicacao and ntf.data_expiracao) OR ntf.data_expiracao is null)
            <cfelseif VARIABLES.notificaLeitura EQ "expiradas">
                AND ntf.data_expiracao IS NOT NULL
                AND ntf.data_expiracao < now()
            </cfif>
            <cfif len(trim(VARIABLES.notificaDataPublicacaoInicialValue)) AND isDate(VARIABLES.notificaDataPublicacaoInicialValue)>
                AND ntf.data_publicacao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoInicialValue#"/>
            </cfif>
            <cfif len(trim(VARIABLES.notificaDataPublicacaoFinalValue)) AND isDate(VARIABLES.notificaDataPublicacaoFinalValue)>
                AND ntf.data_publicacao <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoFinalValue#"/>
            </cfif>
        </cfquery>
    <cfelseif FORM.history_action EQ "excluir_filtradas">
        <cfquery>
            DELETE FROM tb_notifica ntf
            USING tb_usuarios usr
            WHERE usr.id = ntf.id_usuario
            <cfif len(trim(VARIABLES.notificaBusca))>
                AND (
                    <cfif isNumeric(VARIABLES.notificaBusca)>
                        ntf.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                        OR ntf.id_notifica = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                        OR ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                        OR
                    </cfif>
                    unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
                    OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
                    OR unaccent(upper(coalesce(ntf.link, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
                    OR unaccent(upper(coalesce(ntf.conteudo_notifica, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
                )
            </cfif>
            <cfif len(trim(VARIABLES.notificaTemplateId)) AND isNumeric(VARIABLES.notificaTemplateId)>
                AND ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaTemplateId#"/>
            </cfif>
            <cfif len(trim(VARIABLES.notificaCampanha))>
                AND EXISTS (
                    SELECT 1
                    FROM tb_notifica_template tpl
                    WHERE tpl.id_notifica_template = ntf.id_notifica_template
                    AND #PreserveSingleQuotes(VARIABLES.notificaTemplateCampaignSql)# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificaCampanha#"/>
                )
            </cfif>
            <cfif VARIABLES.notificaLeitura EQ "lidas">
                AND ntf.data_leitura IS NOT NULL
            <cfelseif VARIABLES.notificaLeitura EQ "nao_lidas">
                AND ntf.data_leitura IS NULL
            <cfelseif VARIABLES.notificaLeitura EQ "ativas">
                AND ((now() between ntf.data_publicacao and ntf.data_expiracao) OR ntf.data_expiracao is null)
            <cfelseif VARIABLES.notificaLeitura EQ "expiradas">
                AND ntf.data_expiracao IS NOT NULL
                AND ntf.data_expiracao < now()
            </cfif>
            <cfif len(trim(VARIABLES.notificaDataPublicacaoInicialValue)) AND isDate(VARIABLES.notificaDataPublicacaoInicialValue)>
                AND ntf.data_publicacao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoInicialValue#"/>
            </cfif>
            <cfif len(trim(VARIABLES.notificaDataPublicacaoFinalValue)) AND isDate(VARIABLES.notificaDataPublicacaoFinalValue)>
                AND ntf.data_publicacao <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoFinalValue#"/>
            </cfif>
        </cfquery>
    </cfif>

    <cflocation addtoken="false" url="#VARIABLES.notificaHistoryRedirectUrl#"/>
</cfif>

<cfquery name="qNotificaCount">
    SELECT count(*) as total
    FROM tb_notifica notifica
</cfquery>

<cfquery name="qNotificaCountClicks">
    SELECT count(*) as total
    FROM tb_notifica notifica
    WHERE data_leitura is not null
</cfquery>

<cfquery name="qNotificaCountConversoes">
    select count(*) as total, sum(tran.valor_transacao)/100 as valor_total
    from tb_transacoes tran WHERE tran.status_atual = 'order.paid'
    AND tran.id_usuario IN
    (SELECT t.id_usuario
    FROM public.tb_notifica t
    WHERE data_leitura is not null
    AND (select data_inscricao from desafios where id_usuario = t.id_usuario and desafio = 'todosantodia' order by status limit 1) > '2025-12-29 14:40:00');
</cfquery>

<cfquery name="qNotificaCampanhas">
    SELECT DISTINCT campaign_name
    FROM (
        SELECT #PreserveSingleQuotes(VARIABLES.notificaTemplateCampaignSql)# AS campaign_name
        FROM tb_notifica_template tpl
    ) campaigns
    WHERE campaign_name IS NOT NULL
      AND trim(campaign_name) <> ''
    ORDER BY campaign_name
</cfquery>

<cfquery name="qNotificaHistoricoCount">
    SELECT count(*) AS total
    FROM tb_notifica ntf
    LEFT JOIN tb_notifica_template tpl ON tpl.id_notifica_template = ntf.id_notifica_template
    LEFT JOIN tb_usuarios usr ON usr.id = ntf.id_usuario
    WHERE 1 = 1
    <cfif len(trim(VARIABLES.notificaBusca))>
        AND (
            <cfif isNumeric(VARIABLES.notificaBusca)>
                ntf.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR ntf.id_notifica = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR
            </cfif>
            unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(ntf.link, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(ntf.conteudo_notifica, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
        )
    </cfif>
    <cfif len(trim(VARIABLES.notificaTemplateId)) AND isNumeric(VARIABLES.notificaTemplateId)>
        AND ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaTemplateId#"/>
    </cfif>
    <cfif len(trim(VARIABLES.notificaCampanha))>
        AND #PreserveSingleQuotes(VARIABLES.notificaTemplateCampaignSql)# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificaCampanha#"/>
    </cfif>
    <cfif VARIABLES.notificaLeitura EQ "lidas">
        AND ntf.data_leitura IS NOT NULL
    <cfelseif VARIABLES.notificaLeitura EQ "nao_lidas">
        AND ntf.data_leitura IS NULL
    <cfelseif VARIABLES.notificaLeitura EQ "ativas">
        AND ((now() between ntf.data_publicacao and ntf.data_expiracao) OR ntf.data_expiracao is null)
    <cfelseif VARIABLES.notificaLeitura EQ "expiradas">
        AND ntf.data_expiracao IS NOT NULL
        AND ntf.data_expiracao < now()
    </cfif>
    <cfif len(trim(VARIABLES.notificaDataPublicacaoInicialValue)) AND isDate(VARIABLES.notificaDataPublicacaoInicialValue)>
        AND ntf.data_publicacao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoInicialValue#"/>
    </cfif>
    <cfif len(trim(VARIABLES.notificaDataPublicacaoFinalValue)) AND isDate(VARIABLES.notificaDataPublicacaoFinalValue)>
        AND ntf.data_publicacao <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoFinalValue#"/>
    </cfif>
</cfquery>

<cfquery name="qNotificaHistoricoStats">
    SELECT count(*) AS total,
           sum(CASE WHEN ntf.data_leitura IS NOT NULL THEN 1 ELSE 0 END) AS total_lidas,
           sum(CASE WHEN ntf.data_leitura IS NULL THEN 1 ELSE 0 END) AS total_nao_lidas,
           sum(CASE WHEN (ntf.data_expiracao IS NULL OR ntf.data_expiracao >= now()) THEN 1 ELSE 0 END) AS total_ativas,
           sum(CASE WHEN ntf.data_expiracao IS NOT NULL AND ntf.data_expiracao < now() THEN 1 ELSE 0 END) AS total_inativas
    FROM tb_notifica ntf
    LEFT JOIN tb_notifica_template tpl ON tpl.id_notifica_template = ntf.id_notifica_template
    LEFT JOIN tb_usuarios usr ON usr.id = ntf.id_usuario
    WHERE 1 = 1
    <cfif len(trim(VARIABLES.notificaBusca))>
        AND (
            <cfif isNumeric(VARIABLES.notificaBusca)>
                ntf.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR ntf.id_notifica = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR
            </cfif>
            unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(ntf.link, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(ntf.conteudo_notifica, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
        )
    </cfif>
    <cfif len(trim(VARIABLES.notificaTemplateId)) AND isNumeric(VARIABLES.notificaTemplateId)>
        AND ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaTemplateId#"/>
    </cfif>
    <cfif len(trim(VARIABLES.notificaCampanha))>
        AND #PreserveSingleQuotes(VARIABLES.notificaTemplateCampaignSql)# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificaCampanha#"/>
    </cfif>
    <cfif VARIABLES.notificaLeitura EQ "lidas">
        AND ntf.data_leitura IS NOT NULL
    <cfelseif VARIABLES.notificaLeitura EQ "nao_lidas">
        AND ntf.data_leitura IS NULL
    <cfelseif VARIABLES.notificaLeitura EQ "ativas">
        AND ((now() between ntf.data_publicacao and ntf.data_expiracao) OR ntf.data_expiracao is null)
    <cfelseif VARIABLES.notificaLeitura EQ "expiradas">
        AND ntf.data_expiracao IS NOT NULL
        AND ntf.data_expiracao < now()
    </cfif>
    <cfif len(trim(VARIABLES.notificaDataPublicacaoInicialValue)) AND isDate(VARIABLES.notificaDataPublicacaoInicialValue)>
        AND ntf.data_publicacao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoInicialValue#"/>
    </cfif>
    <cfif len(trim(VARIABLES.notificaDataPublicacaoFinalValue)) AND isDate(VARIABLES.notificaDataPublicacaoFinalValue)>
        AND ntf.data_publicacao <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoFinalValue#"/>
    </cfif>
</cfquery>

<cfquery name="qNotificaHistorico">
    SELECT ntf.id_notifica,
           ntf.id_usuario,
           ntf.id_notifica_template,
           ntf.data_publicacao,
           ntf.data_expiracao,
           ntf.data_leitura,
           ntf.link,
           ntf.icone,
           ntf.conteudo_notifica,
           usr.name,
           usr.email,
           #PreserveSingleQuotes(VARIABLES.notificaTemplateCampaignSql)# AS campanha_template
    FROM tb_notifica ntf
    LEFT JOIN tb_notifica_template tpl ON tpl.id_notifica_template = ntf.id_notifica_template
    LEFT JOIN tb_usuarios usr ON usr.id = ntf.id_usuario
    WHERE 1 = 1
    <cfif len(trim(VARIABLES.notificaBusca))>
        AND (
            <cfif isNumeric(VARIABLES.notificaBusca)>
                ntf.id_usuario = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR ntf.id_notifica = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaBusca#"/>
                OR
            </cfif>
            unaccent(upper(coalesce(usr.name, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(usr.email, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(ntf.link, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
            OR unaccent(upper(coalesce(ntf.conteudo_notifica, ''))) LIKE unaccent(upper(<cfqueryparam cfsqltype="cf_sql_varchar" value="%#VARIABLES.notificaBusca#%"/>))
        )
    </cfif>
    <cfif len(trim(VARIABLES.notificaTemplateId)) AND isNumeric(VARIABLES.notificaTemplateId)>
        AND ntf.id_notifica_template = <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaTemplateId#"/>
    </cfif>
    <cfif len(trim(VARIABLES.notificaCampanha))>
        AND #PreserveSingleQuotes(VARIABLES.notificaTemplateCampaignSql)# = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.notificaCampanha#"/>
    </cfif>
    <cfif VARIABLES.notificaLeitura EQ "lidas">
        AND ntf.data_leitura IS NOT NULL
    <cfelseif VARIABLES.notificaLeitura EQ "nao_lidas">
        AND ntf.data_leitura IS NULL
    <cfelseif VARIABLES.notificaLeitura EQ "ativas">
        AND ((now() between ntf.data_publicacao and ntf.data_expiracao) OR ntf.data_expiracao is null)
    <cfelseif VARIABLES.notificaLeitura EQ "expiradas">
        AND ntf.data_expiracao IS NOT NULL
        AND ntf.data_expiracao < now()
    </cfif>
    <cfif len(trim(VARIABLES.notificaDataPublicacaoInicialValue)) AND isDate(VARIABLES.notificaDataPublicacaoInicialValue)>
        AND ntf.data_publicacao >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoInicialValue#"/>
    </cfif>
    <cfif len(trim(VARIABLES.notificaDataPublicacaoFinalValue)) AND isDate(VARIABLES.notificaDataPublicacaoFinalValue)>
        AND ntf.data_publicacao <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.notificaDataPublicacaoFinalValue#"/>
    </cfif>
    ORDER BY ntf.id_notifica DESC, ntf.data_publicacao DESC
    LIMIT <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaPerPage#"/>
    OFFSET <cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.notificaOffset#"/>
</cfquery>

<cfif qNotificaHistoricoCount.total GT 0>
    <cfset VARIABLES.notificaTotalPages = ceiling(qNotificaHistoricoCount.total / VARIABLES.notificaPerPage)/>
<cfelse>
    <cfset VARIABLES.notificaTotalPages = 1/>
</cfif>
