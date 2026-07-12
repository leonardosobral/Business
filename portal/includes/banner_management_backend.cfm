<cfscript>
function bannerManagementBuildBaseUrl() {
    var isHttps = false;
    var hostName = "business.roadrunners.run";

    if (structKeyExists(CGI, "https")) {
        isHttps = isBoolean(CGI.https) ? CGI.https : listFindNoCase("on,1,yes,true", trim(CGI.https));
    }

    if (structKeyExists(CGI, "http_host") AND len(trim(CGI.http_host))) {
        hostName = trim(CGI.http_host);
    }

    return (isHttps ? "https://" : "http://") & hostName;
}

function bannerManagementBuildAssetUrl(required string assetPath) {
    return bannerManagementBuildBaseUrl() & arguments.assetPath;
}

function bannerManagementStatusLabel(required numeric statusCode) {
    switch (arguments.statusCode) {
        case 1:
            return "Rascunho";
        case 2:
            return "Ativo";
        case 3:
            return "Pausado";
        case 4:
            return "Arquivado";
        default:
            return "Indefinido";
    }
}

function bannerManagementTargetLabel(required any openInNewTab) {
    var normalizedTarget = false;

    if (isBoolean(arguments.openInNewTab)) {
        normalizedTarget = arguments.openInNewTab;
    } else {
        normalizedTarget = ListFindNoCase("1,true,yes,on", trim(arguments.openInNewTab)) GT 0;
    }

    return normalizedTarget ? "Nova aba" : "Mesma janela";
}

function bannerManagementFormatDateTime(value) {
    if (!isDate(arguments.value)) {
        return "";
    }

    return dateTimeFormat(arguments.value, "yyyy-mm-dd HH:nn");
}

function bannerManagementDirectoryWritable(required string directoryPath) {
    var directoryFile = createObject("java", "java.io.File").init(arguments.directoryPath);

    if (!directoryFile.exists()) {
        return false;
    }

    return directoryFile.canWrite();
}
</cfscript>

<cfparam name="URL.pagina" default="1"/>
<cfparam name="URL.filtro_canal" default=""/>
<cfparam name="URL.filtro_local" default=""/>
<cfparam name="URL.filtro_status" default=""/>
<cfparam name="URL.banner_editar" default=""/>
<cfparam name="URL.acao" default=""/>
<cfparam name="URL.banner_id" default=""/>
<cfparam name="FORM.acao" default=""/>

<cfset VARIABLES.bannerUploadWebRoot = "/portal/banners/assets/"/>
<cfset VARIABLES.bannerUploadDiskPath = expandPath("../banners/assets/")/>
<cfset VARIABLES.bannerPublicBaseUrl = bannerManagementBuildBaseUrl()/>
<cfset VARIABLES.bannerManagementAlert = { type = "", message = "" }/>

<cfquery name="qBannerManagementTables">
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'ads'
      AND table_name IN (
        'tb_portal_banners',
        'tb_portal_banners_log'
      )
</cfquery>

<cfset VARIABLES.bannerManagementTablesList = ValueList(qBannerManagementTables.table_name)/>
<cfset VARIABLES.bannerManagementTablesReady = ListFindNoCase(VARIABLES.bannerManagementTablesList, "tb_portal_banners") AND ListFindNoCase(VARIABLES.bannerManagementTablesList, "tb_portal_banners_log")/>

<cfif VARIABLES.bannerManagementTablesReady>
    <cfif NOT DirectoryExists(VARIABLES.bannerUploadDiskPath)>
        <cftry>
            <cfdirectory action="create" directory="#VARIABLES.bannerUploadDiskPath#"/>
        <cfcatch type="any">
            <cfif NOT DirectoryExists(VARIABLES.bannerUploadDiskPath)>
                <cfset VARIABLES.bannerManagementAlert = {
                    type = "danger",
                    message = "Nao foi possivel preparar a pasta de upload dos banners em /portal/banners/assets/."
                }/>
            </cfif>
        </cfcatch>
        </cftry>
    </cfif>

    <cfif isDefined("FORM.acao")
        AND FORM.acao EQ "salvar_banner"
        AND isDefined("qPerfil")
        AND qPerfil.recordcount
        AND qPerfil.is_admin>

        <cfset VARIABLES.bannerSaveErrors = []/>
        <cfset VARIABLES.bannerRecordId = isDefined("FORM.banner_id") ? trim(FORM.banner_id) : ""/>
        <cfset VARIABLES.bannerNome = isDefined("FORM.banner_nome") ? trim(FORM.banner_nome) : ""/>
        <cfset VARIABLES.bannerCanal = isDefined("FORM.banner_canal") ? lCase(trim(FORM.banner_canal)) : ""/>
        <cfset VARIABLES.bannerLocalLayout = isDefined("FORM.banner_local_layout") ? lCase(trim(FORM.banner_local_layout)) : ""/>
        <cfset VARIABLES.bannerTamanhoNome = isDefined("FORM.banner_tamanho_nome") ? trim(FORM.banner_tamanho_nome) : ""/>
        <cfset VARIABLES.bannerLargura = isDefined("FORM.banner_largura") ? trim(FORM.banner_largura) : ""/>
        <cfset VARIABLES.bannerAltura = isDefined("FORM.banner_altura") ? trim(FORM.banner_altura) : ""/>
        <cfset VARIABLES.bannerAltText = isDefined("FORM.banner_alt_text") ? trim(FORM.banner_alt_text) : ""/>
        <cfset VARIABLES.bannerLinkDestino = isDefined("FORM.banner_link_destino") ? trim(FORM.banner_link_destino) : ""/>
        <cfset VARIABLES.bannerLinkTipo = isDefined("FORM.banner_link_tipo") ? trim(FORM.banner_link_tipo) : "interno"/>
        <cfset VARIABLES.bannerAbrirNovaAba = isDefined("FORM.banner_abrir_nova_aba") AND ListFindNoCase("1,true,yes,on", trim(FORM.banner_abrir_nova_aba)) GT 0/>
        <cfset VARIABLES.bannerPesoExibicao = isDefined("FORM.banner_peso_exibicao") ? trim(FORM.banner_peso_exibicao) : "1"/>
        <cfset VARIABLES.bannerPrioridade = isDefined("FORM.banner_prioridade") ? trim(FORM.banner_prioridade) : "1"/>
        <cfset VARIABLES.bannerLimiteImpressoes = isDefined("FORM.banner_limite_impressoes") ? trim(FORM.banner_limite_impressoes) : ""/>
        <cfset VARIABLES.bannerLimiteCliques = isDefined("FORM.banner_limite_cliques") ? trim(FORM.banner_limite_cliques) : ""/>
        <cfset VARIABLES.bannerLimiteDiario = isDefined("FORM.banner_limite_diario") ? trim(FORM.banner_limite_diario) : ""/>
        <cfset VARIABLES.bannerInicioExibicao = isDefined("FORM.banner_inicio_exibicao") ? trim(FORM.banner_inicio_exibicao) : ""/>
        <cfset VARIABLES.bannerFimExibicao = isDefined("FORM.banner_fim_exibicao") ? trim(FORM.banner_fim_exibicao) : ""/>
        <cfset VARIABLES.bannerInicioExibicaoParsed = ""/>
        <cfset VARIABLES.bannerFimExibicaoParsed = ""/>
        <cfset VARIABLES.bannerStatus = isDefined("FORM.banner_status") ? trim(FORM.banner_status) : "2"/>
        <cfset VARIABLES.bannerObservacoes = isDefined("FORM.banner_observacoes") ? trim(FORM.banner_observacoes) : ""/>
        <cfset VARIABLES.bannerHasNewFile = isDefined("FORM.banner_arquivo")/>
        <cfset VARIABLES.bannerAssetPath = isDefined("FORM.banner_arquivo_atual") ? trim(FORM.banner_arquivo_atual) : ""/>
        <cfset VARIABLES.bannerAssetOriginal = isDefined("FORM.banner_arquivo_original_atual") ? trim(FORM.banner_arquivo_original_atual) : ""/>
        <cfset VARIABLES.bannerAssetFormat = isDefined("FORM.banner_formato_atual") ? trim(FORM.banner_formato_atual) : ""/>
        <cfset VARIABLES.bannerUploadedServerFile = ""/>

        <cfif NOT len(VARIABLES.bannerNome)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "Informe o nome interno do banner.")/>
        </cfif>
        <cfif NOT len(VARIABLES.bannerCanal)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "Informe o canal onde o banner sera consumido.")/>
        </cfif>
        <cfif NOT len(VARIABLES.bannerLocalLayout)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "Informe o local do layout onde o banner pode aparecer.")/>
        </cfif>
        <cfif NOT len(VARIABLES.bannerLinkDestino)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "Informe o link de destino do banner.")/>
        </cfif>
        <cfif NOT ListFindNoCase("interno,externo", VARIABLES.bannerLinkTipo)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "Escolha se o link e interno ou externo.")/>
        </cfif>
        <cfif NOT isNumeric(VARIABLES.bannerPesoExibicao) OR val(VARIABLES.bannerPesoExibicao) LT 1>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "O peso de exibicao deve ser um numero maior ou igual a 1.")/>
        </cfif>
        <cfif NOT isNumeric(VARIABLES.bannerPrioridade) OR val(VARIABLES.bannerPrioridade) LT 1>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "A prioridade deve ser um numero maior ou igual a 1.")/>
        </cfif>
        <cfif len(VARIABLES.bannerLargura) AND (NOT isNumeric(VARIABLES.bannerLargura) OR val(VARIABLES.bannerLargura) LT 1)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "A largura deve ser um numero positivo.")/>
        </cfif>
        <cfif len(VARIABLES.bannerAltura) AND (NOT isNumeric(VARIABLES.bannerAltura) OR val(VARIABLES.bannerAltura) LT 1)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "A altura deve ser um numero positivo.")/>
        </cfif>
        <cfif len(VARIABLES.bannerLimiteImpressoes) AND (NOT isNumeric(VARIABLES.bannerLimiteImpressoes) OR val(VARIABLES.bannerLimiteImpressoes) LT 1)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "O limite de impressoes deve ser um numero positivo.")/>
        </cfif>
        <cfif len(VARIABLES.bannerLimiteCliques) AND (NOT isNumeric(VARIABLES.bannerLimiteCliques) OR val(VARIABLES.bannerLimiteCliques) LT 1)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "O limite de cliques deve ser um numero positivo.")/>
        </cfif>
        <cfif len(VARIABLES.bannerLimiteDiario) AND (NOT isNumeric(VARIABLES.bannerLimiteDiario) OR val(VARIABLES.bannerLimiteDiario) LT 1)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "O limite diario deve ser um numero positivo.")/>
        </cfif>
        <cfif len(VARIABLES.bannerInicioExibicao) AND NOT isDate(VARIABLES.bannerInicioExibicao)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "A data de inicio de exibicao esta invalida.")/>
        </cfif>
        <cfif len(VARIABLES.bannerFimExibicao) AND NOT isDate(VARIABLES.bannerFimExibicao)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "A data de fim de exibicao esta invalida.")/>
        </cfif>
        <cfif len(VARIABLES.bannerInicioExibicao) AND len(VARIABLES.bannerFimExibicao) AND isDate(VARIABLES.bannerInicioExibicao) AND isDate(VARIABLES.bannerFimExibicao) AND parseDateTime(VARIABLES.bannerFimExibicao) LT parseDateTime(VARIABLES.bannerInicioExibicao)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "A data final precisa ser posterior a data inicial.")/>
        </cfif>
        <cfif NOT len(VARIABLES.bannerRecordId) AND NOT VARIABLES.bannerHasNewFile>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "Envie o arquivo do banner em JPG, PNG ou GIF.")/>
        </cfif>

        <cfif len(VARIABLES.bannerInicioExibicao) AND isDate(VARIABLES.bannerInicioExibicao)>
            <cfset VARIABLES.bannerInicioExibicaoParsed = parseDateTime(VARIABLES.bannerInicioExibicao)/>
        </cfif>
        <cfif len(VARIABLES.bannerFimExibicao) AND isDate(VARIABLES.bannerFimExibicao)>
            <cfset VARIABLES.bannerFimExibicaoParsed = parseDateTime(VARIABLES.bannerFimExibicao)/>
        </cfif>
        <cfif (VARIABLES.bannerHasNewFile OR NOT len(VARIABLES.bannerRecordId)) AND NOT bannerManagementDirectoryWritable(VARIABLES.bannerUploadDiskPath)>
            <cfset arrayAppend(VARIABLES.bannerSaveErrors, "A pasta de upload nao esta gravavel pelo servidor: " & VARIABLES.bannerUploadDiskPath) />
        </cfif>

        <cfif NOT arrayLen(VARIABLES.bannerSaveErrors) AND (VARIABLES.bannerHasNewFile OR NOT len(VARIABLES.bannerRecordId))>
            <cftry>
                <cffile action="upload"
                        filefield="banner_arquivo"
                        destination="#VARIABLES.bannerUploadDiskPath#"
                        nameconflict="makeunique"
                        result="bannerUploadResult"/>
                <cfset VARIABLES.bannerUploadedServerFile = bannerUploadResult.serverFile/>
                <cfset VARIABLES.bannerUploadedExtension = lCase(bannerUploadResult.serverFileExt)/>

                <cfif NOT ListFindNoCase("jpg,jpeg,png,gif", VARIABLES.bannerUploadedExtension)>
                    <cfif len(trim(VARIABLES.bannerUploadedServerFile)) AND FileExists(VARIABLES.bannerUploadDiskPath & VARIABLES.bannerUploadedServerFile)>
                        <cffile action="delete" file="#VARIABLES.bannerUploadDiskPath##VARIABLES.bannerUploadedServerFile#"/>
                    </cfif>
                    <cfset arrayAppend(VARIABLES.bannerSaveErrors, "Nao foi possivel enviar o arquivo do banner. Use JPG, PNG ou GIF.")/>
                <cfelse>
                    <cfset VARIABLES.bannerAssetPath = VARIABLES.bannerUploadWebRoot & bannerUploadResult.serverFile/>
                    <cfset VARIABLES.bannerAssetOriginal = bannerUploadResult.clientFile/>
                    <cfset VARIABLES.bannerAssetFormat = VARIABLES.bannerUploadedExtension/>
                </cfif>
            <cfcatch type="any">
                <cfset VARIABLES.bannerUploadErrorMessage = "Nao foi possivel enviar o arquivo do banner."/>
                <cfif len(trim(cfcatch.message))>
                    <cfset VARIABLES.bannerUploadErrorMessage = VARIABLES.bannerUploadErrorMessage & " " & trim(cfcatch.message)/>
                </cfif>
                <cfif len(trim(cfcatch.detail))>
                    <cfset VARIABLES.bannerUploadErrorMessage = VARIABLES.bannerUploadErrorMessage & " " & trim(cfcatch.detail)/>
                </cfif>
                <cfset arrayAppend(VARIABLES.bannerSaveErrors, VARIABLES.bannerUploadErrorMessage)/>
            </cfcatch>
            </cftry>
        </cfif>

        <cfif arrayLen(VARIABLES.bannerSaveErrors)>
            <cfset VARIABLES.bannerManagementAlert = {
                type = "danger",
                message = arrayToList(VARIABLES.bannerSaveErrors, " ")
            }/>
        <cfelse>
            <cfif len(VARIABLES.bannerRecordId)>
                <cfquery name="qBannerManagementUpdate">
                    UPDATE ads.tb_portal_banners
                    SET nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerNome#"/>,
                        canal = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerCanal#"/>,
                        local_layout = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerLocalLayout#"/>,
                        tamanho_nome = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerTamanhoNome#" null="#NOT len(VARIABLES.bannerTamanhoNome)#"/>,
                        largura = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLargura)#" null="#NOT len(VARIABLES.bannerLargura)#"/>,
                        altura = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerAltura)#" null="#NOT len(VARIABLES.bannerAltura)#"/>,
                        formato = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAssetFormat#" null="#NOT len(VARIABLES.bannerAssetFormat)#"/>,
                        alt_text = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAltText#" null="#NOT len(VARIABLES.bannerAltText)#"/>,
                        arquivo_path = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAssetPath#"/>,
                        arquivo_original = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAssetOriginal#" null="#NOT len(VARIABLES.bannerAssetOriginal)#"/>,
                        link_destino = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerLinkDestino#"/>,
                        link_tipo = <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerLinkTipo#"/>,
                        abrir_nova_aba = <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.bannerAbrirNovaAba#"/>,
                        peso_exibicao = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerPesoExibicao)#"/>,
                        prioridade = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerPrioridade)#"/>,
                        limite_impressoes = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLimiteImpressoes)#" null="#NOT len(VARIABLES.bannerLimiteImpressoes)#"/>,
                        limite_cliques = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLimiteCliques)#" null="#NOT len(VARIABLES.bannerLimiteCliques)#"/>,
                        limite_diario = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLimiteDiario)#" null="#NOT len(VARIABLES.bannerLimiteDiario)#"/>,
                        inicio_exibicao = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.bannerInicioExibicaoParsed#" null="#NOT len(VARIABLES.bannerInicioExibicao)#"/>,
                        fim_exibicao = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.bannerFimExibicaoParsed#" null="#NOT len(VARIABLES.bannerFimExibicao)#"/>,
                        status = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerStatus)#"/>,
                        observacoes = <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.bannerObservacoes#" null="#NOT len(VARIABLES.bannerObservacoes)#"/>,
                        atualizado_em = now(),
                        atualizado_por = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
                    WHERE id_banner = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerRecordId)#"/>
                </cfquery>

                <cflocation addtoken="false" url="/portal/banners/?sucesso=atualizado"/>
            <cfelse>
                <cfquery name="qBannerManagementInsert">
                    INSERT INTO ads.tb_portal_banners
                    (
                        nome,
                        canal,
                        local_layout,
                        tamanho_nome,
                        largura,
                        altura,
                        formato,
                        alt_text,
                        arquivo_path,
                        arquivo_original,
                        link_destino,
                        link_tipo,
                        abrir_nova_aba,
                        peso_exibicao,
                        prioridade,
                        limite_impressoes,
                        limite_cliques,
                        limite_diario,
                        inicio_exibicao,
                        fim_exibicao,
                        status,
                        observacoes,
                        criado_por,
                        atualizado_por
                    )
                    VALUES
                    (
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerNome#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerCanal#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerLocalLayout#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerTamanhoNome#" null="#NOT len(VARIABLES.bannerTamanhoNome)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLargura)#" null="#NOT len(VARIABLES.bannerLargura)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerAltura)#" null="#NOT len(VARIABLES.bannerAltura)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAssetFormat#" null="#NOT len(VARIABLES.bannerAssetFormat)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAltText#" null="#NOT len(VARIABLES.bannerAltText)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAssetPath#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerAssetOriginal#" null="#NOT len(VARIABLES.bannerAssetOriginal)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerLinkDestino#"/>,
                        <cfqueryparam cfsqltype="cf_sql_varchar" value="#VARIABLES.bannerLinkTipo#"/>,
                        <cfqueryparam cfsqltype="cf_sql_bit" value="#VARIABLES.bannerAbrirNovaAba#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerPesoExibicao)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerPrioridade)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLimiteImpressoes)#" null="#NOT len(VARIABLES.bannerLimiteImpressoes)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLimiteCliques)#" null="#NOT len(VARIABLES.bannerLimiteCliques)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerLimiteDiario)#" null="#NOT len(VARIABLES.bannerLimiteDiario)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.bannerInicioExibicaoParsed#" null="#NOT len(VARIABLES.bannerInicioExibicao)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_timestamp" value="#VARIABLES.bannerFimExibicaoParsed#" null="#NOT len(VARIABLES.bannerFimExibicao)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#val(VARIABLES.bannerStatus)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_longvarchar" value="#VARIABLES.bannerObservacoes#" null="#NOT len(VARIABLES.bannerObservacoes)#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>,
                        <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
                    )
                </cfquery>

                <cflocation addtoken="false" url="/portal/banners/?sucesso=cadastrado"/>
            </cfif>
        </cfif>
    </cfif>

    <cfif isDefined("URL.acao")
        AND isDefined("URL.banner_id")
        AND isNumeric(URL.banner_id)
        AND isDefined("qPerfil")
        AND qPerfil.recordcount
        AND qPerfil.is_admin>

        <cfif URL.acao EQ "status" AND isDefined("URL.status") AND isNumeric(URL.status)>
            <cfquery>
                UPDATE ads.tb_portal_banners
                SET status = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.status)#"/>,
                    atualizado_em = now(),
                    atualizado_por = <cfqueryparam cfsqltype="cf_sql_integer" value="#COOKIE.id#"/>
                WHERE id_banner = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.banner_id)#"/>
            </cfquery>

            <cflocation addtoken="false" url="/portal/banners/?sucesso=status"/>
        </cfif>

        <cfif URL.acao EQ "excluir">
            <cfquery name="qBannerDeleteLookup">
                SELECT arquivo_path
                FROM ads.tb_portal_banners
                WHERE id_banner = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.banner_id)#"/>
            </cfquery>

            <cfquery>
                DELETE FROM ads.tb_portal_banners
                WHERE id_banner = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.banner_id)#"/>
            </cfquery>

            <cfif qBannerDeleteLookup.recordcount AND len(trim(qBannerDeleteLookup.arquivo_path))>
                <cfset VARIABLES.bannerDeleteDiskPath = expandPath(".." & qBannerDeleteLookup.arquivo_path)/>
                <cfif FileExists(VARIABLES.bannerDeleteDiskPath)>
                    <cftry>
                        <cffile action="delete" file="#VARIABLES.bannerDeleteDiskPath#"/>
                    <cfcatch type="any">
                    </cfcatch>
                    </cftry>
                </cfif>
            </cfif>

            <cflocation addtoken="false" url="/portal/banners/?sucesso=excluido"/>
        </cfif>
    </cfif>

    <cfquery name="qBannerManagementStats">
        WITH log_views AS (
            SELECT id_banner, count(*) AS total
            FROM ads.tb_portal_banners_log
            WHERE tipo_evento = 'view'
            GROUP BY id_banner
        ),
        log_clicks AS (
            SELECT id_banner, count(*) AS total
            FROM ads.tb_portal_banners_log
            WHERE tipo_evento = 'click'
            GROUP BY id_banner
        )
        SELECT
            count(*) AS total_banners,
            count(*) FILTER (WHERE status = 2) AS total_ativos,
            coalesce(sum(log_views.total), 0) AS total_views,
            coalesce(sum(log_clicks.total), 0) AS total_clicks
        FROM ads.tb_portal_banners bnr
        LEFT JOIN log_views ON log_views.id_banner = bnr.id_banner
        LEFT JOIN log_clicks ON log_clicks.id_banner = bnr.id_banner
    </cfquery>

    <cfquery name="qBannerManagementChannels">
        SELECT DISTINCT canal
        FROM ads.tb_portal_banners
        WHERE canal IS NOT NULL
          AND trim(canal) <> ''
        ORDER BY canal
    </cfquery>

    <cfquery name="qBannerManagementSlots">
        SELECT DISTINCT local_layout
        FROM ads.tb_portal_banners
        WHERE local_layout IS NOT NULL
          AND trim(local_layout) <> ''
        ORDER BY local_layout
    </cfquery>

    <cfquery name="qBannerManagementList">
        WITH banner_views AS (
            SELECT id_banner, count(*) AS total
            FROM ads.tb_portal_banners_log
            WHERE tipo_evento = 'view'
            GROUP BY id_banner
        ),
        banner_clicks AS (
            SELECT id_banner, count(*) AS total
            FROM ads.tb_portal_banners_log
            WHERE tipo_evento = 'click'
            GROUP BY id_banner
        )
        SELECT bnr.*,
               coalesce(banner_views.total, 0) AS views,
               coalesce(banner_clicks.total, 0) AS clicks
        FROM ads.tb_portal_banners bnr
        LEFT JOIN banner_views ON banner_views.id_banner = bnr.id_banner
        LEFT JOIN banner_clicks ON banner_clicks.id_banner = bnr.id_banner
        WHERE 1 = 1
        <cfif len(trim(URL.filtro_canal))>
            AND lower(bnr.canal) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(URL.filtro_canal))#"/>
        </cfif>
        <cfif len(trim(URL.filtro_local))>
            AND lower(bnr.local_layout) = <cfqueryparam cfsqltype="cf_sql_varchar" value="#lCase(trim(URL.filtro_local))#"/>
        </cfif>
        <cfif len(trim(URL.filtro_status)) AND isNumeric(URL.filtro_status)>
            AND bnr.status = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(URL.filtro_status)#"/>
        </cfif>
        ORDER BY
            CASE WHEN bnr.status = 2 THEN 0 ELSE 1 END,
            bnr.prioridade DESC,
            bnr.atualizado_em DESC,
            bnr.id_banner DESC
    </cfquery>

    <cfquery name="qBannerManagementEdit">
        SELECT *
        FROM ads.tb_portal_banners
        WHERE id_banner = <cfqueryparam cfsqltype="cf_sql_integer" value="#isNumeric(URL.banner_editar) ? val(URL.banner_editar) : 0#"/>
    </cfquery>
<cfelse>
    <cfset qBannerManagementStats = queryNew("total_banners,total_ativos,total_views,total_clicks", "integer,integer,integer,integer", [{ total_banners = 0, total_ativos = 0, total_views = 0, total_clicks = 0 }])/>
    <cfset qBannerManagementChannels = queryNew("canal")/>
    <cfset qBannerManagementSlots = queryNew("local_layout")/>
    <cfset qBannerManagementList = queryNew("id_banner")/>
    <cfset qBannerManagementEdit = queryNew("id_banner")/>
</cfif>

<cfif isDefined("URL.sucesso") AND len(trim(URL.sucesso))>
    <cfif URL.sucesso EQ "cadastrado">
        <cfset VARIABLES.bannerManagementAlert = { type = "success", message = "Banner cadastrado com sucesso." }/>
    <cfelseif URL.sucesso EQ "atualizado">
        <cfset VARIABLES.bannerManagementAlert = { type = "success", message = "Banner atualizado com sucesso." }/>
    <cfelseif URL.sucesso EQ "status">
        <cfset VARIABLES.bannerManagementAlert = { type = "success", message = "Status do banner atualizado." }/>
    <cfelseif URL.sucesso EQ "excluido">
        <cfset VARIABLES.bannerManagementAlert = { type = "success", message = "Banner removido com sucesso." }/>
    </cfif>
</cfif>
