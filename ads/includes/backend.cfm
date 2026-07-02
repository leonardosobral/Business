<!--- INCLUIR CAMPANHA --->

<cfset VARIABLES.adsRestrictByConta = true/>
<cfset VARIABLES.adsEventosContaIds = "0"/>
<cfset VARIABLES.adsEventosOperacaoIds = "0"/>
<cfset VARIABLES.adsEffectiveIsAdmin = false/>
<cfset VARIABLES.adsCanOperate = false/>
<cfset VARIABLES.adsVoucherColumnsReady = false/>
<cfset VARIABLES.adsVoucherActionMessage = ""/>
<cfset VARIABLES.adsVoucherActionError = ""/>
<cfset VARIABLES.adsCreditBalance = 0/>
<cfset VARIABLES.adsCreditTotal = 0/>
<cfset VARIABLES.adsCreditSpent = 0/>
<cfset VARIABLES.adsMetricasDiaReady = false/>
<cfset VARIABLES.adsConversionLogReady = false/>
<cfparam name="URL.ads_periodo" default="30"/>
<cfif NOT ListFind("7,30", URL.ads_periodo)>
    <cfset URL.ads_periodo = "30"/>
</cfif>
<cfset VARIABLES.adsPeriodoDias = val(URL.ads_periodo)/>
<cfset qAdVoucherCredit = QueryNew("credito_total,consumo_total,saldo_total")/>
<cfset qAdCreditVouchers = QueryNew("codigo,nome_conta,credito,credito_disponivel,data_resgate,data_expiracao,status")/>
<cfset qAdAvailableVouchers = QueryNew("id_ad_voucher,codigo,nome_conta,credito,credito_disponivel,data_expiracao,papel_resgate,observacao")/>
<cfset qAdMetricasDia = QueryNew("data_metrica,views,clicks,custo,ctr")/>
<cfset qAdMetricasComparativo = QueryNew("views_atual,views_anterior,clicks_atual,clicks_anterior,custo_atual,custo_anterior")/>
<cfset qAdConversionSummary = QueryNew("conversoes_periodo,valor_periodo")/>
<cfparam name="FORM.voucher_codigo" default=""/>

<cftry>
    <cfquery name="qAdsMetricasDiaTableCheck">
        SELECT count(*)::integer AS total
        FROM information_schema.tables
        WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="public"/>
          AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_evento_metricas_dia"/>
    </cfquery>
    <cfset VARIABLES.adsMetricasDiaReady = qAdsMetricasDiaTableCheck.recordcount AND val(qAdsMetricasDiaTableCheck.total) GT 0/>

    <cfcatch type="any">
        <cfset VARIABLES.adsMetricasDiaReady = false/>
    </cfcatch>
</cftry>

<cftry>
    <cfquery name="qAdsConversionLogTableCheck">
        SELECT count(*)::integer AS total
        FROM information_schema.tables
        WHERE table_schema = <cfqueryparam cfsqltype="cf_sql_varchar" value="public"/>
          AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_conversion_log"/>
    </cfquery>
    <cfset VARIABLES.adsConversionLogReady = qAdsConversionLogTableCheck.recordcount AND val(qAdsConversionLogTableCheck.total) GT 0/>

    <cfcatch type="any">
        <cfset VARIABLES.adsConversionLogReady = false/>
    </cfcatch>
</cftry>

<cftry>
    <cfquery name="qAdsVoucherColumnCheck">
        SELECT table_name,
               column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="tb_ad_vouchers"/>
          AND column_name IN (
            <cfqueryparam cfsqltype="cf_sql_varchar" value="id_conta"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="credito_disponivel"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="data_resgate"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="id_usuario_resgate"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="papel_resgate"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="observacao"/>
          )
    </cfquery>

    <cfset VARIABLES.adsVoucherColumnNames = ValueList(qAdsVoucherColumnCheck.column_name)/>
    <cfset VARIABLES.adsVoucherColumnsReady = ListFindNoCase(VARIABLES.adsVoucherColumnNames, "id_conta")
        AND ListFindNoCase(VARIABLES.adsVoucherColumnNames, "credito_disponivel")
        AND ListFindNoCase(VARIABLES.adsVoucherColumnNames, "data_resgate")
        AND ListFindNoCase(VARIABLES.adsVoucherColumnNames, "id_usuario_resgate")
        AND ListFindNoCase(VARIABLES.adsVoucherColumnNames, "papel_resgate")
        AND ListFindNoCase(VARIABLES.adsVoucherColumnNames, "observacao")/>

    <cfcatch type="any">
        <cfset VARIABLES.adsVoucherColumnsReady = false/>
    </cfcatch>
</cftry>

<cfif isDefined("VARIABLES.businessEffectiveIsAdmin")>
    <cfset VARIABLES.adsEffectiveIsAdmin = VARIABLES.businessEffectiveIsAdmin/>
<cfelseif isDefined("qPerfil") AND qPerfil.recordcount AND isDefined("qPerfil.is_admin") AND qPerfil.is_admin>
    <cfset VARIABLES.adsEffectiveIsAdmin = true/>
</cfif>

<cfif VARIABLES.adsEffectiveIsAdmin>
    <cfset VARIABLES.adsRestrictByConta = false/>
    <cfset VARIABLES.adsCanOperate = true/>
</cfif>

<cfif isDefined("qEventosConta") AND qEventosConta.recordcount>
    <cfset VARIABLES.adsEventosContaIds = ValueList(qEventosConta.id_evento)/>
</cfif>

<cfif isDefined("qEventosContaOperacao") AND qEventosContaOperacao.recordcount>
    <cfset VARIABLES.adsEventosOperacaoIds = ValueList(qEventosContaOperacao.id_evento)/>
    <cfset VARIABLES.adsCanOperate = true/>
</cfif>

<cfif isDefined("URL.voucher") AND URL.voucher EQ "ativado">
    <cfset VARIABLES.adsVoucherActionMessage = "Voucher ativado com sucesso. O credito ja esta disponivel para os turbinados desta conta."/>
</cfif>

<cfif isDefined("FORM.acao") AND FORM.acao EQ "ativar_voucher_ads">
    <cfset VARIABLES.adsVoucherCode = uCase(trim(FORM.voucher_codigo))/>
    <cfset VARIABLES.adsVoucherCode = REReplace(VARIABLES.adsVoucherCode, "[^A-Z0-9-]", "", "all")/>
    <cfset VARIABLES.adsVoucherErrors = []/>

    <cfif NOT len(VARIABLES.adsVoucherCode)>
        <cfset arrayAppend(VARIABLES.adsVoucherErrors, "Informe o codigo do voucher.")/>
    </cfif>

    <cfif NOT VARIABLES.adsVoucherColumnsReady>
        <cfset arrayAppend(VARIABLES.adsVoucherErrors, "A estrutura de vouchers ainda nao foi aplicada.")/>
    </cfif>

    <cfif NOT isDefined("qPerfil") OR NOT qPerfil.recordcount OR NOT len(trim(qPerfil.id))>
        <cfset arrayAppend(VARIABLES.adsVoucherErrors, "Nao foi possivel identificar o usuario logado.")/>
    </cfif>

    <cfif NOT VARIABLES.adsRestrictByConta>
        <cfset arrayAppend(VARIABLES.adsVoucherErrors, "Selecione uma conta no topo antes de ativar um voucher.")/>
    </cfif>

    <cfif NOT arrayLen(VARIABLES.adsVoucherErrors)>
        <cftry>
            <cftransaction>
                <cfquery name="qAdsVoucherActivation">
                    SELECT vou.id_ad_voucher,
                           vou.codigo,
                           vou.id_conta,
                           vou.status,
                           vou.credito,
                           vou.data_expiracao,
                           vou.papel_resgate::text AS papel_resgate,
                           cont.nome_conta
                    FROM tb_ad_vouchers vou
                    INNER JOIN tb_contas cont ON cont.id_conta = vou.id_conta
                    WHERE lower(vou.codigo) = lower(<cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsVoucherCode#"/>)
                      AND vou.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
                    LIMIT 1
                    FOR UPDATE
                </cfquery>

                <cfif NOT qAdsVoucherActivation.recordcount>
                    <cfset arrayAppend(VARIABLES.adsVoucherErrors, "Voucher nao encontrado para esta conta.")/>
                <cfelseif qAdsVoucherActivation.status NEQ 1>
                    <cfset arrayAppend(VARIABLES.adsVoucherErrors, "Este voucher nao esta disponivel para ativacao.")/>
                <cfelseif len(trim(qAdsVoucherActivation.data_expiracao)) AND isDate(qAdsVoucherActivation.data_expiracao) AND dateCompare(qAdsVoucherActivation.data_expiracao, now(), "d") LT 0>
                    <cfset arrayAppend(VARIABLES.adsVoucherErrors, "Este voucher esta expirado.")/>
                </cfif>

                <cfif NOT arrayLen(VARIABLES.adsVoucherErrors)>
                    <cfquery>
                        UPDATE tb_ad_vouchers
                        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>,
                            id_usuario_resgate = <cfqueryparam cfsqltype="cf_sql_bigint" value="#qPerfil.id#"/>,
                            data_resgate = now(),
                            credito_disponivel = COALESCE(credito_disponivel, credito, 0),
                            data_atualizacao = now()
                        WHERE id_ad_voucher = <cfqueryparam cfsqltype="cf_sql_integer" value="#qAdsVoucherActivation.id_ad_voucher#"/>
                          AND status = <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>
                    </cfquery>
                </cfif>
            </cftransaction>

            <cfif NOT arrayLen(VARIABLES.adsVoucherErrors)>
                <cflocation addtoken="false" url="/ads/?voucher=ativado##credito-ads"/>
            </cfif>

            <cfcatch type="any">
                <cfset arrayAppend(VARIABLES.adsVoucherErrors, "Nao foi possivel ativar o voucher. " & cfcatch.message)/>
            </cfcatch>
        </cftry>
    </cfif>

    <cfif arrayLen(VARIABLES.adsVoucherErrors)>
        <cfset VARIABLES.adsVoucherActionError = arrayToList(VARIABLES.adsVoucherErrors, " ")/>
    </cfif>
</cfif>

<cfif VARIABLES.adsVoucherColumnsReady>
    <cfif VARIABLES.adsRestrictByConta>
        <cfquery name="qAdAvailableVouchers">
            SELECT vou.id_ad_voucher,
                   vou.codigo,
                   cont.nome_conta,
                   coalesce(vou.credito, 0) AS credito,
                   coalesce(vou.credito_disponivel, vou.credito, 0) AS credito_disponivel,
                   vou.data_expiracao,
                   vou.papel_resgate::text AS papel_resgate,
                   vou.observacao
            FROM tb_ad_vouchers vou
            LEFT JOIN tb_contas cont ON cont.id_conta = vou.id_conta
            WHERE vou.status = <cfqueryparam cfsqltype="cf_sql_integer" value="1"/>
              AND vou.id_usuario_resgate IS NULL
              AND vou.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
              AND (
                  vou.data_expiracao IS NULL
                  OR vou.data_expiracao >= current_date
              )
            ORDER BY vou.data_expiracao ASC NULLS LAST, vou.data_criacao DESC, vou.id_ad_voucher DESC
            LIMIT 5
        </cfquery>
    </cfif>

    <cfquery name="qAdVoucherCredit">
        WITH voucher_credit AS (
            SELECT coalesce(sum(credito_disponivel), 0) AS credito_total
            FROM tb_ad_vouchers
            WHERE status = <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>
              AND data_resgate IS NOT NULL
            <cfif VARIABLES.adsRestrictByConta>
              AND id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
            </cfif>
        ),
        ad_spend AS (
            SELECT coalesce(sum(log.valor_ad), 0) AS consumo_total
            FROM tb_ad_log log
            INNER JOIN tb_ad_eventos ad ON log.id_ad = ad.id_ad_evento
            INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
            WHERE log.status = <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>
            <cfif VARIABLES.adsRestrictByConta>
              AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
            </cfif>
        )
        SELECT voucher_credit.credito_total,
               ad_spend.consumo_total,
               greatest(voucher_credit.credito_total - ad_spend.consumo_total, 0) AS saldo_total
        FROM voucher_credit, ad_spend
    </cfquery>

    <cfif qAdVoucherCredit.recordcount>
        <cfset VARIABLES.adsCreditTotal = val(qAdVoucherCredit.credito_total)/>
        <cfset VARIABLES.adsCreditSpent = val(qAdVoucherCredit.consumo_total)/>
        <cfset VARIABLES.adsCreditBalance = val(qAdVoucherCredit.saldo_total)/>
    </cfif>

    <cfquery name="qAdCreditVouchers">
        SELECT vou.codigo,
               cont.nome_conta,
               coalesce(vou.credito, 0) AS credito,
               coalesce(vou.credito_disponivel, vou.credito, 0) AS credito_disponivel,
               vou.data_resgate,
               vou.data_expiracao,
               vou.status
        FROM tb_ad_vouchers vou
        LEFT JOIN tb_contas cont ON cont.id_conta = vou.id_conta
        WHERE vou.status = <cfqueryparam cfsqltype="cf_sql_integer" value="2"/>
          AND vou.data_resgate IS NOT NULL
        <cfif VARIABLES.adsRestrictByConta>
          AND vou.id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
        </cfif>
        ORDER BY vou.data_resgate DESC, vou.id_ad_voucher DESC
        LIMIT 20
    </cfquery>

</cfif>

<cfset qAdsEventosPermitidos = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado")/>
<cfset qAdsEventosSemCampanha = QueryNew("id_evento,nome_evento,tag,data_inicial,data_final,cidade,estado")/>
<cfif VARIABLES.adsRestrictByConta AND VARIABLES.adsEventosOperacaoIds NEQ "0">
    <cfquery name="qAdsEventosPermitidos">
        SELECT id_evento,
               nome_evento,
               tag,
               data_inicial,
               data_final,
               cidade,
               estado
        FROM tb_evento_corridas
        WHERE ativo = true
          AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosOperacaoIds#" list="true"/>)
        ORDER BY data_final DESC NULLS LAST, nome_evento
    </cfquery>

    <cfquery name="qAdsEventosSemCampanha">
        SELECT evt.id_evento,
               evt.nome_evento,
               evt.tag,
               evt.data_inicial,
               evt.data_final,
               evt.cidade,
               evt.estado
        FROM tb_evento_corridas evt
        WHERE evt.ativo = true
          AND evt.data_final >= current_date
          AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosOperacaoIds#" list="true"/>)
          AND NOT EXISTS (
              SELECT 1
              FROM tb_ad_eventos ad
              WHERE ad.id_evento = evt.id_evento
                AND ad.status < <cfqueryparam cfsqltype="cf_sql_integer" value="3"/>
          )
        ORDER BY evt.data_inicial ASC NULLS LAST, evt.nome_evento
        LIMIT 3
    </cfquery>
</cfif>

<cfif isDefined("form.acao") AND form.acao EQ "incluir_campanha">

    <cfif NOT VARIABLES.adsCanOperate>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

    <cfif VARIABLES.adsRestrictByConta
        AND VARIABLES.adsVoucherColumnsReady
        AND VARIABLES.adsCreditBalance LTE 0>
        <cflocation addtoken="false" url="/ads/?erro=sem_credito"/>
    </cfif>

    <cfif VARIABLES.adsRestrictByConta
        AND VARIABLES.adsVoucherColumnsReady
        AND isDefined("FORM.limite_ad")
        AND len(trim(FORM.limite_ad))
        AND val(REReplace(FORM.limite_ad, ",", ".", "all")) GT VARIABLES.adsCreditBalance>
        <cflocation addtoken="false" url="/ads/?erro=credito_insuficiente"/>
    </cfif>

    <cfset qAdCheckEvento = QueryNew("id_evento")/>

    <cfif isDefined("FORM.id_evento") AND len(trim(FORM.id_evento)) AND isNumeric(FORM.id_evento)>
        <cfquery name="qAdCheckEvento">
            SELECT id_evento
            FROM tb_evento_corridas
            WHERE id_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_evento#"/>
              AND ativo = true
            LIMIT 1
        </cfquery>
    <cfelseif isDefined("FORM.evento") AND len(trim(FORM.evento))>
        <cfset VARIABLES.adsEventoReferencia = trim(FORM.evento)/>
        <cfset VARIABLES.adsEventoReferencia = replaceNoCase(VARIABLES.adsEventoReferencia, "https://roadrunners.run/evento/", "")/>
        <cfset VARIABLES.adsEventoReferencia = replaceNoCase(VARIABLES.adsEventoReferencia, "http://roadrunners.run/evento/", "")/>
        <cfset VARIABLES.adsEventoReferencia = listFirst(VARIABLES.adsEventoReferencia, "/?##")/>

        <cfquery name="qAdCheckEvento">
            SELECT id_evento
            FROM tb_evento_corridas
            WHERE tag ILIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.adsEventoReferencia#"/>
              AND ativo = true
            LIMIT 1
        </cfquery>
    </cfif>

    <cfif NOT qAdCheckEvento.recordcount OR (VARIABLES.adsRestrictByConta AND NOT listFind(VARIABLES.adsEventosOperacaoIds, qAdCheckEvento.id_evento))>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

    <cfset VARIABLES.locais = {}/>
    <cfif isDefined("FORM.locais") and len(trim(FORM.locais))>
        <cfset arrEstados = listToArray(FORM.locais)/>
        <cfif arraylen(arrEstados) EQ 27>
            <cfset VARIABLES.locais["nacional"] = true/>
        <cfelse>
            <cfset VARIABLES.locais["nacional"] = false/>
        </cfif>
        <cfset VARIABLES.locais["estados"] = arrEstados/>
    </cfif>

    <cfset VARIABLES.escopo = ""/>
    <cfif isDefined("FORM.escopo") and len(trim(FORM.escopo))>
        <cfset VARIABLES.escopo = FORM.escopo/>
    </cfif>

    <cfset VARIABLES.inicio_ad = ""/>
    <cfset VARIABLES.final_ad = ""/>

    <cfif isDefined("FORM.datas") and len(trim(FORM.datas))>
        <cfset FORM.datas = listtoarray(FORM.datas, ' - ')/>
        <cfif arraylen(FORM.datas) GT 0>
            <cfset VARIABLES.inicio_ad = FORM.datas[1]/>
        </cfif>
        <cfif arraylen(FORM.datas) GT 1>
            <cfset VARIABLES.final_ad = FORM.datas[2]/>
        </cfif>
    </cfif>

    <cfquery name="qAdIncluirCampanha">
        insert into tb_ad_eventos
        (id_evento, escopo, cpc_max, limite_diario, limite_ad, inicio_ad, final_ad, locais)
        values
        (
            <cfqueryparam cfsqltype="cf_sql_integer" value="#qAdCheckEvento.id_evento#"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.escopo#"/>,
            <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.cpc_max#"/>,
            <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.limite_diario#"/>,
            <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.limite_ad#"/>,
            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.inicio_ad#" null="#len(trim(VARIABLES.inicio_ad)) EQ 0#"/>,
            <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.final_ad#" null="#len(trim(VARIABLES.final_ad)) EQ 0#"/>,
            <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(VARIABLES.locais)#"/>::jsonb
        )
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>

<!--- EDITAR CAMPANHA --->

<cfif isDefined("form.acao") AND form.acao EQ "editar_campanha">

    <cfif NOT VARIABLES.adsCanOperate>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

    <cfif VARIABLES.adsRestrictByConta
        AND VARIABLES.adsVoucherColumnsReady
        AND isDefined("FORM.limite_ad")
        AND len(trim(FORM.limite_ad))
        AND val(REReplace(FORM.limite_ad, ",", ".", "all")) GT VARIABLES.adsCreditBalance>
        <cflocation addtoken="false" url="/ads/?erro=credito_insuficiente"/>
    </cfif>

    <cfif NOT isDefined("FORM.id_ad_evento") OR NOT isNumeric(FORM.id_ad_evento)>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

    <cfset VARIABLES.locais = {}/>
    <cfif isDefined("FORM.locais") and len(trim(FORM.locais))>
        <cfset arrEstados = listToArray(FORM.locais)/>
        <cfif arraylen(arrEstados) EQ 27>
            <cfset VARIABLES.locais["nacional"] = true/>
        <cfelse>
            <cfset VARIABLES.locais["nacional"] = false/>
        </cfif>
        <cfset VARIABLES.locais["estados"] = arrEstados/>
    </cfif>

    <cfset VARIABLES.escopo = ""/>
    <cfif isDefined("FORM.escopo") and len(trim(FORM.escopo))>
        <cfset VARIABLES.escopo = FORM.escopo/>
    </cfif>

    <cfset VARIABLES.inicio_ad = ""/>
    <cfset VARIABLES.final_ad = ""/>

    <cfif isDefined("FORM.datas") and len(trim(FORM.datas))>
        <cfset FORM.datas = listtoarray(FORM.datas, ' - ')/>
        <cfif arraylen(FORM.datas) GT 0>
            <cfset VARIABLES.inicio_ad = FORM.datas[1]/>
        </cfif>
        <cfif arraylen(FORM.datas) GT 1>
            <cfset VARIABLES.final_ad = FORM.datas[2]/>
        </cfif>
    </cfif>

    <cfquery name="qAdIncluirCampanha">
        UPDATE tb_ad_eventos
        SET escopo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.escopo#"/>,
            cpc_max = <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.cpc_max#"/>,
            limite_diario = <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.limite_diario#"/>,
            limite_ad = <cfqueryparam cfsqltype="cf_sql_decimal" value="#FORM.limite_ad#"/>,
            inicio_ad = <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.inicio_ad#" null="#len(trim(VARIABLES.inicio_ad)) EQ 0#"/>,
            final_ad = <cfqueryparam cfsqltype="cf_sql_date" value="#VARIABLES.final_ad#" null="#len(trim(VARIABLES.final_ad)) EQ 0#"/>,
            locais = <cfqueryparam cfsqltype="cf_sql_varchar" value="#serializeJSON(VARIABLES.locais)#"/>::jsonb
        WHERE id_ad_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#FORM.id_ad_evento#"/>
        <cfif VARIABLES.adsRestrictByConta>
            AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosOperacaoIds#" list="true"/>)
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>

<!--- ALTERAR STATUS DA CAMPANHA --->

<cfif isDefined("URL.acao") AND URL.acao EQ "status_campanha" AND isDefined("URL.campanha") AND isNumeric(URL.campanha) AND isDefined("URL.status") AND isNumeric(URL.status)>

    <cfif NOT VARIABLES.adsCanOperate>
        <cflocation addtoken="false" url="/ads/"/>
    </cfif>

    <cfquery>
        UPDATE tb_ad_eventos
        SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.status#"/>
        WHERE id_ad_evento = <cfqueryparam cfsqltype="cf_sql_integer" value="#URL.campanha#"/>
        <cfif VARIABLES.adsRestrictByConta>
            AND id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosOperacaoIds#" list="true"/>)
        </cfif>
    </cfquery>

    <cflocation addtoken="false" url="/ads/"/>

</cfif>



<!--- WIDGETS --->

<cfquery name="qAdValorTotal">
    SELECT sum(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdValorMedio">
    SELECT avg(valor_ad) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountViews">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status <= 2
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountClicks">
    SELECT count(id_ad_log) as total
    FROM tb_ad_log log
    INNER JOIN tb_ad_eventos ad on log.id_ad = ad.id_ad_evento
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE log.status = 2
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qAdCountAds">
    SELECT count(ad.*) as total
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    WHERE ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfif VARIABLES.adsMetricasDiaReady>
    <cfquery name="qAdMetricasDia">
        WITH dias AS (
            SELECT generate_series(
                current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day'),
                current_date,
                interval '1 day'
            )::date AS data_metrica
        ),
        metricas AS (
            SELECT data_metrica,
                   sum(views) AS views,
                   sum(clicks) AS clicks,
                   coalesce(sum(custo), 0) AS custo
            FROM tb_ad_evento_metricas_dia
            WHERE data_metrica >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
            <cfif VARIABLES.adsRestrictByConta>
                AND id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
            </cfif>
            GROUP BY data_metrica
        )
        SELECT dias.data_metrica,
               coalesce(metricas.views, 0) AS views,
               coalesce(metricas.clicks, 0) AS clicks,
               coalesce(metricas.custo, 0) AS custo,
               CASE WHEN coalesce(metricas.views, 0) > 0
                    THEN coalesce(metricas.clicks, 0)::numeric * 100 / metricas.views
                    ELSE 0
               END AS ctr
        FROM dias
        LEFT JOIN metricas ON metricas.data_metrica = dias.data_metrica
        ORDER BY dias.data_metrica
    </cfquery>

    <cfquery name="qAdMetricasComparativo">
        WITH metricas AS (
            SELECT data_metrica,
                   sum(views) AS views,
                   sum(clicks) AS clicks,
                   coalesce(sum(custo), 0) AS custo
            FROM tb_ad_evento_metricas_dia
            WHERE data_metrica >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#(VARIABLES.adsPeriodoDias * 2) - 1#"/> * interval '1 day')
            <cfif VARIABLES.adsRestrictByConta>
                AND id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
            </cfif>
            GROUP BY data_metrica
        )
        SELECT coalesce(sum(views) FILTER (
                   WHERE data_metrica >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ), 0) AS views_atual,
               coalesce(sum(views) FILTER (
                   WHERE data_metrica < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ), 0) AS views_anterior,
               coalesce(sum(clicks) FILTER (
                   WHERE data_metrica >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ), 0) AS clicks_atual,
               coalesce(sum(clicks) FILTER (
                   WHERE data_metrica < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ), 0) AS clicks_anterior,
               coalesce(sum(custo) FILTER (
                   WHERE data_metrica >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ), 0) AS custo_atual,
               coalesce(sum(custo) FILTER (
                   WHERE data_metrica < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ), 0) AS custo_anterior
        FROM metricas
    </cfquery>
<cfelse>
    <cfquery name="qAdMetricasDia">
        WITH dias AS (
            SELECT generate_series(
                current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day'),
                current_date,
                interval '1 day'
            )::date AS data_metrica
        ),
        metricas AS (
            SELECT log.data_insercao::date AS data_metrica,
                   count(*) FILTER (WHERE log.status <= 2) AS views,
                   count(*) FILTER (WHERE log.status = 2) AS clicks,
                   coalesce(sum(CASE WHEN log.status = 2 THEN log.valor_ad ELSE 0 END), 0) AS custo
            FROM tb_ad_log log
            INNER JOIN tb_ad_eventos ad ON log.id_ad = ad.id_ad_evento
            INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
            WHERE log.data_insercao >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
            <cfif VARIABLES.adsRestrictByConta>
                AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
            </cfif>
            GROUP BY log.data_insercao::date
        )
        SELECT dias.data_metrica,
               coalesce(metricas.views, 0) AS views,
               coalesce(metricas.clicks, 0) AS clicks,
               coalesce(metricas.custo, 0) AS custo,
               CASE WHEN coalesce(metricas.views, 0) > 0
                    THEN coalesce(metricas.clicks, 0)::numeric * 100 / metricas.views
                    ELSE 0
               END AS ctr
        FROM dias
        LEFT JOIN metricas ON metricas.data_metrica = dias.data_metrica
        ORDER BY dias.data_metrica
    </cfquery>

    <cfquery name="qAdMetricasComparativo">
        WITH logs_periodo AS (
            SELECT log.status,
                   log.valor_ad,
                   log.data_insercao
            FROM tb_ad_log log
            INNER JOIN tb_ad_eventos ad ON log.id_ad = ad.id_ad_evento
            INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
            WHERE log.data_insercao >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#(VARIABLES.adsPeriodoDias * 2) - 1#"/> * interval '1 day')
            <cfif VARIABLES.adsRestrictByConta>
                AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
            </cfif>
        )
        SELECT count(*) FILTER (
                   WHERE status <= 2
                     AND data_insercao >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ) AS views_atual,
               count(*) FILTER (
                   WHERE status <= 2
                     AND data_insercao < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ) AS views_anterior,
               count(*) FILTER (
                   WHERE status = 2
                     AND data_insercao >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ) AS clicks_atual,
               count(*) FILTER (
                   WHERE status = 2
                     AND data_insercao < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
               ) AS clicks_anterior,
               coalesce(sum(CASE
                   WHEN status = 2
                    AND data_insercao >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
                   THEN valor_ad ELSE 0 END), 0) AS custo_atual,
               coalesce(sum(CASE
                   WHEN status = 2
                    AND data_insercao < current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
                   THEN valor_ad ELSE 0 END), 0) AS custo_anterior
        FROM logs_periodo
    </cfquery>
</cfif>

<cfif VARIABLES.adsConversionLogReady>
    <cfquery name="qAdConversionSummary">
        SELECT count(*) FILTER (
                   WHERE tipo_conversion IN (
                       <cfqueryparam cfsqltype="cf_sql_varchar" value="INSCRICAO_CLICK"/>,
                       <cfqueryparam cfsqltype="cf_sql_varchar" value="INSCRICAO_CONFIRMADA"/>
                   )
               ) AS conversoes_periodo,
               coalesce(sum(valor), 0) AS valor_periodo
        FROM tb_ad_conversion_log
        WHERE data_criacao >= current_date - (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsPeriodoDias - 1#"/> * interval '1 day')
        <cfif VARIABLES.adsRestrictByConta>
            AND id_conta IN (<cfqueryparam cfsqltype="cf_sql_bigint" value="#VARIABLES.businessEffectiveAccountIds#" list="true"/>)
        </cfif>
    </cfquery>
</cfif>


<!--- QUERY BASE DE EVENTOS --->

<cfquery name="qEventosAdsBase">
    WITH
    ad_views AS (
        SELECT
            id_ad as id_evento,
            count(*) as views
        FROM tb_ad_log
        WHERE tb_ad_log.status <= 2
        GROUP BY id_ad
    ),
    ad_views_usuarios AS (
        SELECT
            id_ad as id_evento,
            count(*) as views
        FROM tb_ad_log
        WHERE tb_ad_log.status <= 2
        AND id_usuario is not null
        GROUP BY id_ad
    ),
    ad_clicks AS (
        select
        id_ad as id_evento,
        count(*) as clicks,
        avg(valor_ad) as cpc_medio,
        sum(valor_ad) as custo_total
        FROM tb_ad_log
        WHERE status = 2
        group by id_ad
    ),
    ad_clicks_usuarios AS (
        select
        id_ad as id_evento,
        count(*) as clicks,
        avg(valor_ad) as cpc_medio,
        sum(valor_ad) as custo_total
        FROM tb_ad_log
        WHERE status = 2
        AND id_usuario is not null
        group by id_ad
    )
    <cfif VARIABLES.adsConversionLogReady>
    ,
    ad_conversions AS (
        SELECT
            id_ad_evento,
            count(*) FILTER (WHERE tipo_conversion = 'INSCRICAO_CLICK') AS conversoes,
            count(*) FILTER (WHERE tipo_conversion = 'INSCRICAO_CONFIRMADA') AS inscricoes_confirmadas
        FROM tb_ad_conversion_log
        GROUP BY id_ad_evento
    )
    </cfif>
    SELECT evt.*,
           ad.id_ad_evento,
           ad.status,
           ad.cpc_max,
           ad.qualidade,
           ad.limite_diario,
           ad.limite_ad,
           ad.escopo,
           ad.locais,
           ad.inicio_ad,
           ad.final_ad,
           ad_views.views,
           ad_views_usuarios.views as views_usuarios,
           ad_clicks.clicks,
           ad_clicks.cpc_medio,
           ad_clicks.custo_total,
           ad_clicks_usuarios.clicks as clicks_usuarios,
           ad_clicks_usuarios.cpc_medio as cpc_medio_usuarios,
           ad_clicks_usuarios.custo_total as custo_total_usuarios,
           <cfif VARIABLES.adsConversionLogReady>
           coalesce(ad_conversions.conversoes, 0) AS conversoes,
           coalesce(ad_conversions.inscricoes_confirmadas, 0) AS inscricoes_confirmadas,
           <cfelse>
           0 AS conversoes,
           0 AS inscricoes_confirmadas,
           </cfif>
           (ad.qualidade * ad.cpc_max) as ad_rank
    FROM tb_ad_eventos ad
    INNER JOIN tb_evento_corridas evt ON ad.id_evento = evt.id_evento
    LEFT JOIN ad_views on ad_views.id_evento = ad.id_ad_evento
    LEFT JOIN ad_views_usuarios on ad_views_usuarios.id_evento = ad.id_ad_evento
    LEFT JOIN ad_clicks on ad_clicks.id_evento = ad.id_ad_evento
    LEFT JOIN ad_clicks_usuarios on ad_clicks_usuarios.id_evento = ad.id_ad_evento
    <cfif VARIABLES.adsConversionLogReady>
    LEFT JOIN ad_conversions on ad_conversions.id_ad_evento = ad.id_ad_evento
    </cfif>
    WHERE ad.status >= <cfqueryparam cfsqltype="cf_sql_integer" value="0"/>
    <cfif VARIABLES.adsRestrictByConta>
        AND evt.id_evento IN (<cfqueryparam cfsqltype="cf_sql_integer" value="#VARIABLES.adsEventosContaIds#" list="true"/>)
    </cfif>
</cfquery>

<cfquery name="qEventosAds" dbtype="query">
    select * from qEventosAdsBase
    where status < 3
    order by clicks desc, views desc
</cfquery>

<cfquery name="qEventosAdsPausados" dbtype="query">
    select * from qEventosAdsBase
    where status = 3
    order by clicks desc, views desc
</cfquery>

<cfquery name="qEventosAdsFinalizados" dbtype="query">
    select * from qEventosAdsBase
    where status = 4
    order by clicks desc, views desc
</cfquery>

<cfquery name="qAdsTopCampaigns" dbtype="query" maxrows="5">
    select *
    from qEventosAdsBase
    where views > 0 or clicks > 0
    order by clicks desc, views desc
</cfquery>
