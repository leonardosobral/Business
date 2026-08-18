<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="30"/>
<cfinclude template="../../includes/backend/backend_login.cfm"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>

<cfscript>
function researchApiWrite(required any payload, numeric statusCode = 200) {
    cfheader(name = "Cache-Control", value = "no-store, no-cache, must-revalidate, max-age=0");
    cfheader(name = "Pragma", value = "no-cache");
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(researchApiSerialize(arguments.payload));
    abort;
}

function researchApiSerialize(required any payload) {
    var serialized = serializeJSON(arguments.payload);
    var keys = [
        ["SCHEMAREADY", "schemaReady"], ["SUCCESS", "success"], ["MESSAGE", "message"], ["AVAILABLE", "available"],
        ["RESEARCH", "research"], ["DASHBOARD", "dashboard"], ["CONFIG", "config"],
        ["INTERNALNAME", "internalName"], ["PUBLICTITLE", "publicTitle"], ["STAKEHOLDER", "stakeholder"],
        ["SCOPE", "scope"], ["SLUG", "slug"], ["GLOBALRANDOM", "globalRandom"],
        ["REQUIREACCOUNT", "requireAccount"], ["EMAILMODE", "emailMode"],
        ["ANNUALDISCOUNT", "annualDiscount"], ["REDIRECTURL", "redirectUrl"],
        ["STATUS", "status"], ["STEPS", "steps"], ["ID", "id"], ["KEY", "key"],
        ["TYPE", "type"], ["NAME", "name"], ["TITLE", "title"], ["SUPPORT", "support"],
        ["QUESTION", "question"], ["AREA", "area"], ["ICON", "icon"], ["MEDIA", "media"],
        ["VISUAL", "visual"], ["IMAGEURL", "imageUrl"], ["PACKAGE", "package"], ["RANDOM", "random"],
        ["SUMMARY", "summary"], ["TOTAL", "total"], ["LAST7DAYS", "last7Days"],
        ["ANNUALPERCENT", "annualPercent"], ["AVERAGEMAXPRICE", "averageMaxPrice"],
        ["FEATURES", "features"], ["PROFILES", "profiles"], ["ACCOUNTS", "accounts"],
        ["BILLING", "billing"], ["RECENT", "recent"], ["VALUE", "value"],
        ["COUNT", "count"], ["PERCENT", "percent"], ["INTERESTPERCENT", "interestPercent"],
        ["PACKAGEPERCENT", "packagePercent"], ["MUSTHAVECOUNT", "mustHaveCount"],
        ["COMPLETEDAT", "completedAt"], ["EMAIL", "email"], ["LEVEL", "level"],
        ["ACCOUNT", "account"], ["RESPONSEID", "responseId"],
        ["PRICEMIN", "priceMin"], ["PRICEMAX", "priceMax"],
        ["ANNUALPRICEMIN", "annualPriceMin"], ["ANNUALPRICEMAX", "annualPriceMax"],
        ["PACKAGECOUNT", "packageCount"], ["PACKAGENAMES", "packageNames"], ["MUSTHAVENAME", "mustHaveName"],
        ["URL", "url"], ["CODE", "code"]
    ];
    for (var pair in keys) {
        serialized = replace(serialized, '"' & pair[1] & '":', '"' & pair[2] & '":', "all");
    }
    return serialized;
}

function researchApiBoolean(any value = false) {
    if (isBoolean(arguments.value)) return arguments.value;
    return listFindNoCase("1,true,yes,on,sim", trim(arguments.value & "")) GT 0;
}

function researchApiStepTypeToClient(required string value) {
    var types = {
        boas_vindas = "intro", nivel_corredor = "runner_level", conta_rr = "rr_account",
        funcionalidade = "feature", pacote = "package", preco = "pricing",
        indispensavel = "must_have", contato = "contact", agradecimento = "thank_you"
    };
    var key = lCase(trim(arguments.value));
    return structKeyExists(types, key) ? types[key] : key;
}

function researchApiStepTypeToDatabase(required string value) {
    var types = {
        intro = "boas_vindas", runner_level = "nivel_corredor", rr_account = "conta_rr",
        feature = "funcionalidade", package = "pacote", pricing = "preco",
        must_have = "indispensavel", contact = "contato", thank_you = "agradecimento"
    };
    var key = lCase(trim(arguments.value));
    return structKeyExists(types, key) ? types[key] : key;
}

function researchApiVisualToClient(required string value) {
    var types = { nenhum = "none", ilustracao = "illustration", imagem = "image" };
    var key = lCase(trim(arguments.value));
    return structKeyExists(types, key) ? types[key] : key;
}

function researchApiVisualToDatabase(required string value) {
    var types = { none = "nenhum", illustration = "ilustracao", image = "imagem" };
    var key = lCase(trim(arguments.value));
    return structKeyExists(types, key) ? types[key] : "nenhum";
}

function researchApiEmailToClient(required string value) {
    var modes = { desativado = "disabled", opcional = "optional", obrigatorio = "required" };
    var key = lCase(trim(arguments.value));
    return structKeyExists(modes, key) ? modes[key] : "optional";
}

function researchApiEmailToDatabase(required string value) {
    var modes = { disabled = "desativado", optional = "opcional", required = "obrigatorio" };
    var key = lCase(trim(arguments.value));
    return structKeyExists(modes, key) ? modes[key] : "opcional";
}

function researchApiResponseValueToClient(required string group, required string value) {
    var maps = {
        level = { iniciante = "beginner", recreativo = "recreational", dedicado = "dedicated", competitivo = "competitive" },
        account = { frequente = "active", ocasional = "occasional", sem_conta = "none" },
        billing = { mensal = "monthly", anual = "annual" }
    };
    var groupKey = lCase(trim(arguments.group));
    var valueKey = lCase(trim(arguments.value));
    return structKeyExists(maps, groupKey) && structKeyExists(maps[groupKey], valueKey) ? maps[groupKey][valueKey] : valueKey;
}

function researchApiResponseValueToDatabase(required string group, string value = "") {
    var maps = {
        level = { beginner = "iniciante", recreational = "recreativo", dedicated = "dedicado", competitive = "competitivo" },
        account = { active = "frequente", occasional = "ocasional", none = "sem_conta" }
    };
    var groupKey = lCase(trim(arguments.group));
    var valueKey = lCase(trim(arguments.value));
    return len(valueKey) && structKeyExists(maps, groupKey) && structKeyExists(maps[groupKey], valueKey) ? maps[groupKey][valueKey] : "";
}

function researchApiText(required query source, required string columnName, required numeric rowIndex, string fallback = "") {
    if (!listFindNoCase(arguments.source.columnList, arguments.columnName)) return arguments.fallback;
    if (isNull(arguments.source[arguments.columnName][arguments.rowIndex])) return arguments.fallback;
    return arguments.source[arguments.columnName][arguments.rowIndex] & "";
}

function researchApiNumber(required query source, required string columnName, required numeric rowIndex, numeric fallback = 0) {
    var raw = researchApiText(arguments.source, arguments.columnName, arguments.rowIndex, "");
    return isNumeric(raw) ? val(raw) : arguments.fallback;
}

function researchApiLoad(string dashboardLevel = "", string dashboardAccount = "") {
    var result = {
        schemaReady = true,
        success = true,
        research = {},
        dashboard = {
            summary = { total = 0, last7Days = 0, annualPercent = 0, averageMaxPrice = 0 },
            features = [], profiles = [], accounts = [], billing = [], recent = []
        }
    };
    var survey = queryExecute(
        "SELECT id_pesquisa, nome_interno, titulo_publico, publico_principal, escopo, slug, status, " &
        "randomizar_funcionalidades, exigir_conta_rr, modo_email, desconto_anual, url_redirecionamento " &
        "FROM tb_pesquisas ORDER BY id_pesquisa LIMIT 1"
    );

    if (!survey.recordCount) {
        result.message = "As tabelas estão prontas. Salve a configuração atual para criar a primeira entrevista.";
        return result;
    }

    var surveyId = survey.id_pesquisa[1];
    var stepsQuery = queryExecute(
        "SELECT id_etapa, chave, tipo, nome, titulo, texto_apoio, pergunta, area, icone, " &
        "tipo_visual, visual_modelo, imagem_url, incluir_pacote, randomizavel, ordem " &
        "FROM tb_pesquisa_etapas WHERE id_pesquisa = :survey_id AND ativo = true ORDER BY ordem, id_etapa",
        { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" } }
    );
    var steps = [];
    for (var rowIndex = 1; rowIndex <= stepsQuery.recordCount; rowIndex++) {
        arrayAppend(steps, {
            id = researchApiNumber(stepsQuery, "id_etapa", rowIndex),
            key = researchApiText(stepsQuery, "chave", rowIndex),
            type = researchApiStepTypeToClient(researchApiText(stepsQuery, "tipo", rowIndex)),
            name = researchApiText(stepsQuery, "nome", rowIndex),
            title = researchApiText(stepsQuery, "titulo", rowIndex),
            support = researchApiText(stepsQuery, "texto_apoio", rowIndex),
            question = researchApiText(stepsQuery, "pergunta", rowIndex),
            area = researchApiText(stepsQuery, "area", rowIndex),
            icon = researchApiText(stepsQuery, "icone", rowIndex),
            media = researchApiVisualToClient(researchApiText(stepsQuery, "tipo_visual", rowIndex, "nenhum")),
            visual = researchApiText(stepsQuery, "visual_modelo", rowIndex),
            imageUrl = researchApiText(stepsQuery, "imagem_url", rowIndex),
            package = researchApiBoolean(stepsQuery.incluir_pacote[rowIndex]),
            random = researchApiBoolean(stepsQuery.randomizavel[rowIndex])
        });
    }

    result.research = {
        id = surveyId,
        status = researchApiText(survey, "status", 1, "rascunho"),
        config = {
            internalName = researchApiText(survey, "nome_interno", 1),
            publicTitle = researchApiText(survey, "titulo_publico", 1),
            stakeholder = "athlete",
            scope = "general",
            slug = researchApiText(survey, "slug", 1),
            globalRandom = researchApiBoolean(survey.randomizar_funcionalidades[1]),
            requireAccount = researchApiBoolean(survey.exigir_conta_rr[1]),
            emailMode = researchApiEmailToClient(researchApiText(survey, "modo_email", 1, "opcional")),
            annualDiscount = researchApiNumber(survey, "desconto_anual", 1, 15),
            redirectUrl = researchApiText(survey, "url_redirecionamento", 1)
        },
        steps = steps
    };

    var levelFilter = researchApiResponseValueToDatabase("level", arguments.dashboardLevel);
    var accountFilter = researchApiResponseValueToDatabase("account", arguments.dashboardAccount);
    var dashboardParams = {
        survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" },
        level_filter = { value = levelFilter, cfsqltype = "cf_sql_varchar" },
        account_filter = { value = accountFilter, cfsqltype = "cf_sql_varchar" }
    };
    var responseFilter =
        " AND response.nivel_corredor = coalesce(nullif(:level_filter, ''), response.nivel_corredor)" &
        " AND response.conta_rr = coalesce(nullif(:account_filter, ''), response.conta_rr)";

    var summary = queryExecute(
        "SELECT count(*) AS total, " &
        "count(*) FILTER (WHERE response.concluido_em >= now() - interval '7 days') AS last_7_days, " &
        "coalesce(round(100.0 * count(*) FILTER (WHERE response.periodicidade = 'anual') / nullif(count(*), 0)), 0) AS annual_percent, " &
        "coalesce(round(avg(response.valor_mensal_max)), 0) AS average_max_price " &
        "FROM tb_pesquisa_respostas response WHERE response.id_pesquisa = :survey_id AND response.status = 'concluida'" & responseFilter,
        dashboardParams
    );
    var totalCompleted = researchApiNumber(summary, "total", 1);

    var featuresQuery = queryExecute(
        "SELECT step.chave, step.nome, step.ordem, " &
        "coalesce(round(100.0 * count(*) FILTER (WHERE answer.interesse = 'sim') / nullif(count(answer.id_resposta_funcionalidade), 0)), 0) AS interest_percent, " &
        "coalesce(round(100.0 * count(*) FILTER (WHERE answer.selecionada_pacote) / nullif(count(answer.id_resposta_funcionalidade), 0)), 0) AS package_percent, " &
        "count(*) FILTER (WHERE answer.indispensavel) AS must_have_count " &
        "FROM tb_pesquisa_etapas step " &
        "LEFT JOIN tb_pesquisa_resposta_funcionalidades answer ON answer.id_etapa = step.id_etapa " &
        "AND EXISTS (SELECT 1 FROM tb_pesquisa_respostas response WHERE response.id_resposta = answer.id_resposta AND response.status = 'concluida'" & responseFilter & ") " &
        "WHERE step.id_pesquisa = :survey_id AND step.tipo = 'funcionalidade' AND step.ativo = true " &
        "GROUP BY step.id_etapa, step.chave, step.nome, step.ordem ORDER BY step.ordem",
        dashboardParams
    );
    var featureResults = [];
    for (var featureRow = 1; featureRow <= featuresQuery.recordCount; featureRow++) {
        arrayAppend(featureResults, {
            key = researchApiText(featuresQuery, "chave", featureRow),
            name = researchApiText(featuresQuery, "nome", featureRow),
            interestPercent = researchApiNumber(featuresQuery, "interest_percent", featureRow),
            packagePercent = researchApiNumber(featuresQuery, "package_percent", featureRow),
            mustHaveCount = researchApiNumber(featuresQuery, "must_have_count", featureRow)
        });
    }

    var profilesQuery = queryExecute(
        "SELECT response.nivel_corredor AS value, count(*) AS total, " &
        "round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0)) AS percent " &
        "FROM tb_pesquisa_respostas response WHERE response.id_pesquisa = :survey_id AND response.status = 'concluida' AND response.nivel_corredor IS NOT NULL" & responseFilter & " " &
        "GROUP BY response.nivel_corredor ORDER BY count(*) DESC",
        dashboardParams
    );
    var billingQuery = queryExecute(
        "SELECT response.periodicidade AS value, count(*) AS total, " &
        "round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0)) AS percent " &
        "FROM tb_pesquisa_respostas response WHERE response.id_pesquisa = :survey_id AND response.status = 'concluida' AND response.periodicidade IS NOT NULL" & responseFilter & " " &
        "GROUP BY response.periodicidade ORDER BY count(*) DESC",
        dashboardParams
    );
    var accountsQuery = queryExecute(
        "SELECT response.conta_rr AS value, count(*) AS total, " &
        "round(100.0 * count(*) / nullif(sum(count(*)) OVER (), 0)) AS percent " &
        "FROM tb_pesquisa_respostas response WHERE response.id_pesquisa = :survey_id AND response.status = 'concluida' AND response.conta_rr IS NOT NULL" & responseFilter & " " &
        "GROUP BY response.conta_rr ORDER BY count(*) DESC",
        dashboardParams
    );
    var recentQuery = queryExecute(
        "SELECT response.codigo_publico, response.concluido_em, response.email, response.nivel_corredor, response.conta_rr, response.periodicidade, " &
        "response.valor_mensal_min, response.valor_mensal_max, response.valor_anual_min, response.valor_anual_max, " &
        "count(feature.id_resposta_funcionalidade) FILTER (WHERE feature.selecionada_pacote) AS package_count, " &
        "string_agg(step.nome, chr(30) ORDER BY step.ordem) FILTER (WHERE feature.selecionada_pacote) AS package_names, " &
        "max(step.nome) FILTER (WHERE feature.indispensavel) AS must_have_name " &
        "FROM tb_pesquisa_respostas response " &
        "LEFT JOIN tb_pesquisa_resposta_funcionalidades feature ON feature.id_resposta = response.id_resposta " &
        "LEFT JOIN tb_pesquisa_etapas step ON step.id_etapa = feature.id_etapa " &
        "WHERE response.id_pesquisa = :survey_id AND response.status = 'concluida'" & responseFilter & " " &
        "GROUP BY response.id_resposta ORDER BY response.concluido_em DESC NULLS LAST LIMIT 50",
        dashboardParams
    );

    var profileResults = [];
    for (var profileRow = 1; profileRow <= profilesQuery.recordCount; profileRow++) {
        arrayAppend(profileResults, { value = researchApiResponseValueToClient("level", researchApiText(profilesQuery, "value", profileRow)), count = researchApiNumber(profilesQuery, "total", profileRow), percent = researchApiNumber(profilesQuery, "percent", profileRow) });
    }
    var billingResults = [];
    for (var billingRow = 1; billingRow <= billingQuery.recordCount; billingRow++) {
        arrayAppend(billingResults, { value = researchApiResponseValueToClient("billing", researchApiText(billingQuery, "value", billingRow)), count = researchApiNumber(billingQuery, "total", billingRow), percent = researchApiNumber(billingQuery, "percent", billingRow) });
    }
    var accountResults = [];
    for (var accountRow = 1; accountRow <= accountsQuery.recordCount; accountRow++) {
        arrayAppend(accountResults, { value = researchApiResponseValueToClient("account", researchApiText(accountsQuery, "value", accountRow)), count = researchApiNumber(accountsQuery, "total", accountRow), percent = researchApiNumber(accountsQuery, "percent", accountRow) });
    }
    var recentResults = [];
    for (var recentRow = 1; recentRow <= recentQuery.recordCount; recentRow++) {
        var completedValue = isNull(recentQuery.concluido_em[recentRow]) ? "" : dateTimeFormat(recentQuery.concluido_em[recentRow], "dd/mm/yyyy HH:nn");
        var packageNamesValue = researchApiText(recentQuery, "package_names", recentRow);
        arrayAppend(recentResults, {
            responseId = researchApiText(recentQuery, "codigo_publico", recentRow),
            completedAt = completedValue,
            email = researchApiText(recentQuery, "email", recentRow),
            level = researchApiResponseValueToClient("level", researchApiText(recentQuery, "nivel_corredor", recentRow)),
            account = researchApiResponseValueToClient("account", researchApiText(recentQuery, "conta_rr", recentRow)),
            billing = researchApiResponseValueToClient("billing", researchApiText(recentQuery, "periodicidade", recentRow)),
            priceMin = researchApiNumber(recentQuery, "valor_mensal_min", recentRow),
            priceMax = researchApiNumber(recentQuery, "valor_mensal_max", recentRow),
            annualPriceMin = researchApiNumber(recentQuery, "valor_anual_min", recentRow),
            annualPriceMax = researchApiNumber(recentQuery, "valor_anual_max", recentRow),
            packageCount = researchApiNumber(recentQuery, "package_count", recentRow),
            packageNames = len(packageNamesValue) ? listToArray(packageNamesValue, chr(30)) : [],
            mustHaveName = researchApiText(recentQuery, "must_have_name", recentRow)
        });
    }

    result.dashboard = {
        summary = {
            total = totalCompleted,
            last7Days = researchApiNumber(summary, "last_7_days", 1),
            annualPercent = researchApiNumber(summary, "annual_percent", 1),
            averageMaxPrice = researchApiNumber(summary, "average_max_price", 1)
        },
        features = featureResults,
        profiles = profileResults,
        accounts = accountResults,
        billing = billingResults,
        recent = recentResults
    };
    return result;
}

function researchApiCheckEmail(required struct payload) {
    var email = structKeyExists(arguments.payload, "email") ? lCase(trim(arguments.payload.email & "")) : "";
    if (!len(email)) return { success = true, available = true, message = "O e-mail é opcional." };
    if (!isValid("email", email)) throw(message = "Informe um e-mail válido.");

    var surveyId = structKeyExists(arguments.payload, "surveyId") && isNumeric(arguments.payload.surveyId) ? val(arguments.payload.surveyId) : 0;
    var survey = surveyId GT 0
        ? queryExecute("SELECT id_pesquisa FROM tb_pesquisas WHERE id_pesquisa = :survey_id LIMIT 1", { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" } })
        : queryExecute("SELECT id_pesquisa FROM tb_pesquisas ORDER BY id_pesquisa LIMIT 1");
    if (!survey.recordCount) throw(message = "Salve a entrevista antes de validar o e-mail no preview.");

    var duplicateEmail = queryExecute(
        "SELECT 1 FROM tb_pesquisa_respostas WHERE id_pesquisa = :survey_id AND status = 'concluida' AND lower(btrim(email)) = :email LIMIT 1",
        {
            survey_id = { value = survey.id_pesquisa[1], cfsqltype = "cf_sql_bigint" },
            email = { value = email, cfsqltype = "cf_sql_varchar" }
        }
    );
    return {
        success = true,
        available = !duplicateEmail.recordCount,
        message = duplicateEmail.recordCount ? "Este e-mail já foi utilizado para responder esta entrevista." : "E-mail disponível para esta entrevista."
    };
}

function researchApiSave(required struct payload, required numeric actorId) {
    if (!structKeyExists(arguments.payload, "research") || !isStruct(arguments.payload.research)) throw(message = "Configuração da entrevista inválida.");
    var research = arguments.payload.research;
    if (!structKeyExists(research, "config") || !isStruct(research.config) || !structKeyExists(research, "steps") || !isArray(research.steps) || !arrayLen(research.steps)) throw(message = "A entrevista precisa ter configuração e etapas.");
    var config = research.config;
    var slug = lCase(trim(config.slug & ""));
    if (!reFind("^[a-z0-9]+(?:-[a-z0-9]+)*$", slug)) throw(message = "Use somente letras minúsculas, números e hífens no slug.");
    if (!len(trim(config.internalName & "")) || !len(trim(config.publicTitle & ""))) throw(message = "Informe o nome interno e o título público.");
    var emailMode = researchApiEmailToDatabase(config.emailMode & "");
    var discount = min(50, max(0, val(config.annualDiscount)));
    var redirectUrl = trim(config.redirectUrl & "");
    if (len(redirectUrl) && !reFindNoCase("^(https?://|/)", redirectUrl)) throw(message = "Use uma URL http(s) ou um caminho iniciado por / no redirecionamento.");
    var surveyId = structKeyExists(research, "id") && isNumeric(research.id) ? val(research.id) : 0;
    var allowedTypes = "intro,runner_level,rr_account,feature,package,pricing,must_have,contact,thank_you";
    var seenKeys = {};
    var stepKeys = [];

    for (var validationStep in research.steps) {
        var validationKey = trim(validationStep.key & "");
        if (!len(validationKey) || !reFind("^[A-Za-z0-9_-]+$", validationKey) || structKeyExists(seenKeys, validationKey)) throw(message = "Há uma etapa com chave inválida ou duplicada.");
        if (!listFindNoCase(allowedTypes, validationStep.type & "")) throw(message = "Tipo de etapa inválido: " & validationStep.type);
        if (!len(trim(validationStep.name & "")) || !len(trim(validationStep.title & ""))) throw(message = "Todas as etapas precisam de nome e título.");
        if (compareNoCase(validationStep.media & "", "image") EQ 0 && !reFindNoCase("^/administracao/pesquisas/uploads/[A-Za-z0-9._-]+$", trim(validationStep.imageUrl & ""))) throw(message = "A imagem de uma funcionalidade não pertence à pasta de uploads da entrevista.");
        seenKeys[validationKey] = true;
        arrayAppend(stepKeys, validationKey);
    }

    transaction {
        if (surveyId LTE 0) {
            var inserted = queryExecute(
                "INSERT INTO tb_pesquisas (nome_interno, titulo_publico, publico_principal, escopo, slug, randomizar_funcionalidades, exigir_conta_rr, modo_email, desconto_anual, url_redirecionamento, id_usuario_criacao, id_usuario_atualizacao) " &
                "VALUES (:internal_name, :public_title, 'atletas', 'geral', :slug, :randomize, :require_account, :email_mode, :discount, :redirect_url, :actor_id, :actor_id) RETURNING id_pesquisa",
                {
                    internal_name = { value = trim(config.internalName & ""), cfsqltype = "cf_sql_varchar" },
                    public_title = { value = trim(config.publicTitle & ""), cfsqltype = "cf_sql_varchar" },
                    slug = { value = slug, cfsqltype = "cf_sql_varchar" },
                    randomize = { value = researchApiBoolean(config.globalRandom), cfsqltype = "cf_sql_bit" },
                    require_account = { value = researchApiBoolean(config.requireAccount), cfsqltype = "cf_sql_bit" },
                    email_mode = { value = emailMode, cfsqltype = "cf_sql_varchar" },
                    discount = { value = discount, cfsqltype = "cf_sql_decimal", scale = 2 },
                    redirect_url = { value = redirectUrl, cfsqltype = "cf_sql_longvarchar", null = !len(redirectUrl) },
                    actor_id = { value = arguments.actorId, cfsqltype = "cf_sql_bigint" }
                }
            );
            surveyId = inserted.id_pesquisa[1];
        } else {
            queryExecute(
                "UPDATE tb_pesquisas SET nome_interno = :internal_name, titulo_publico = :public_title, publico_principal = 'atletas', escopo = 'geral', slug = :slug, randomizar_funcionalidades = :randomize, exigir_conta_rr = :require_account, modo_email = :email_mode, desconto_anual = :discount, url_redirecionamento = :redirect_url, id_usuario_atualizacao = :actor_id WHERE id_pesquisa = :survey_id",
                {
                    internal_name = { value = trim(config.internalName & ""), cfsqltype = "cf_sql_varchar" }, public_title = { value = trim(config.publicTitle & ""), cfsqltype = "cf_sql_varchar" }, slug = { value = slug, cfsqltype = "cf_sql_varchar" },
                    randomize = { value = researchApiBoolean(config.globalRandom), cfsqltype = "cf_sql_bit" }, require_account = { value = researchApiBoolean(config.requireAccount), cfsqltype = "cf_sql_bit" }, email_mode = { value = emailMode, cfsqltype = "cf_sql_varchar" },
                    discount = { value = discount, cfsqltype = "cf_sql_decimal", scale = 2 }, redirect_url = { value = redirectUrl, cfsqltype = "cf_sql_longvarchar", null = !len(redirectUrl) }, actor_id = { value = arguments.actorId, cfsqltype = "cf_sql_bigint" }, survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" }
                }
            );
        }

        queryExecute("UPDATE tb_pesquisa_etapas SET ordem = -id_etapa WHERE id_pesquisa = :survey_id", { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" } });
        var orderIndex = 0;
        for (var currentStep in research.steps) {
            orderIndex++;
            queryExecute(
                "INSERT INTO tb_pesquisa_etapas (id_pesquisa, chave, tipo, nome, titulo, texto_apoio, pergunta, area, icone, tipo_visual, visual_modelo, imagem_url, incluir_pacote, randomizavel, ordem, ativo) " &
                "VALUES (:survey_id, :step_key, :step_type, :step_name, :step_title, :support_text, :question, :area, :icon, :media_type, :visual_model, :image_url, :include_package, :randomizable, :step_order, true) " &
                "ON CONFLICT (id_pesquisa, chave) DO UPDATE SET tipo = excluded.tipo, nome = excluded.nome, titulo = excluded.titulo, texto_apoio = excluded.texto_apoio, pergunta = excluded.pergunta, area = excluded.area, icone = excluded.icone, tipo_visual = excluded.tipo_visual, visual_modelo = excluded.visual_modelo, imagem_url = excluded.imagem_url, incluir_pacote = excluded.incluir_pacote, randomizavel = excluded.randomizavel, ordem = excluded.ordem, ativo = true",
                {
                    survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" }, step_key = { value = trim(currentStep.key & ""), cfsqltype = "cf_sql_varchar" }, step_type = { value = researchApiStepTypeToDatabase(currentStep.type & ""), cfsqltype = "cf_sql_varchar" }, step_name = { value = trim(currentStep.name & ""), cfsqltype = "cf_sql_varchar" }, step_title = { value = trim(currentStep.title & ""), cfsqltype = "cf_sql_varchar" },
                    support_text = { value = trim(currentStep.support & ""), cfsqltype = "cf_sql_longvarchar", null = !len(trim(currentStep.support & "")) }, question = { value = trim(currentStep.question & ""), cfsqltype = "cf_sql_longvarchar", null = !len(trim(currentStep.question & "")) }, area = { value = trim(currentStep.area & ""), cfsqltype = "cf_sql_varchar", null = !len(trim(currentStep.area & "")) }, icon = { value = trim(currentStep.icon & ""), cfsqltype = "cf_sql_varchar", null = !len(trim(currentStep.icon & "")) },
                    media_type = { value = researchApiVisualToDatabase(currentStep.media & ""), cfsqltype = "cf_sql_varchar" }, visual_model = { value = trim(currentStep.visual & ""), cfsqltype = "cf_sql_varchar", null = !len(trim(currentStep.visual & "")) }, image_url = { value = trim(currentStep.imageUrl & ""), cfsqltype = "cf_sql_longvarchar", null = !len(trim(currentStep.imageUrl & "")) }, include_package = { value = researchApiBoolean(currentStep.package), cfsqltype = "cf_sql_bit" }, randomizable = { value = researchApiBoolean(currentStep.random), cfsqltype = "cf_sql_bit" }, step_order = { value = orderIndex, cfsqltype = "cf_sql_integer" }
                }
            );
        }
        queryExecute(
            "UPDATE tb_pesquisa_etapas SET ativo = false WHERE id_pesquisa = :survey_id AND chave NOT IN (:step_keys)",
            { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" }, step_keys = { value = arrayToList(stepKeys), cfsqltype = "cf_sql_varchar", list = true } }
        );
    }
    return surveyId;
}

function researchApiChangeStatus(required struct payload, required numeric actorId) {
    if (!structKeyExists(arguments.payload, "id") || !isNumeric(arguments.payload.id)) throw(message = "Entrevista inválida.");
    var surveyId = val(arguments.payload.id);
    var nextStatus = structKeyExists(arguments.payload, "status") ? lCase(trim(arguments.payload.status & "")) : "";
    if (!listFindNoCase("rascunho,publicada,encerrada", nextStatus)) throw(message = "Status de publicação inválido.");
    var finalStatus = "";

    transaction {
        var survey = queryExecute(
            "SELECT status FROM tb_pesquisas WHERE id_pesquisa = :survey_id FOR UPDATE",
            { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" } }
        );
        if (!survey.recordCount) throw(message = "Entrevista não encontrada.");
        var currentStatus = survey.status[1] & "";

        if (currentStatus NEQ nextStatus) {
            var allowedTransition =
                (currentStatus EQ "rascunho" AND nextStatus EQ "publicada") OR
                (currentStatus EQ "publicada" AND nextStatus EQ "rascunho") OR
                (currentStatus EQ "publicada" AND nextStatus EQ "encerrada");
            if (!allowedTransition) throw(message = "Não é possível alterar a entrevista de " & currentStatus & " para " & nextStatus & ".");

            if (nextStatus EQ "publicada") {
                var requiredSteps = queryExecute(
                    "SELECT count(DISTINCT tipo) FILTER (WHERE tipo IN ('boas_vindas', 'nivel_corredor', 'conta_rr', 'pacote', 'preco', 'indispensavel', 'contato', 'agradecimento')) AS fixed_count, " &
                    "count(*) FILTER (WHERE tipo = 'funcionalidade') AS feature_count " &
                    "FROM tb_pesquisa_etapas WHERE id_pesquisa = :survey_id AND ativo = true",
                    { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" } }
                );
                if (val(requiredSteps.fixed_count[1]) LT 8 || val(requiredSteps.feature_count[1]) LT 1) {
                    throw(message = "A entrevista precisa ter todas as etapas obrigatórias e ao menos uma funcionalidade antes da publicação.");
                }
            }

            queryExecute(
                "UPDATE tb_pesquisas SET status = :next_status, id_usuario_atualizacao = :actor_id WHERE id_pesquisa = :survey_id",
                {
                    next_status = { value = nextStatus, cfsqltype = "cf_sql_varchar" },
                    actor_id = { value = arguments.actorId, cfsqltype = "cf_sql_bigint", null = arguments.actorId LTE 0 },
                    survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" }
                }
            );
        }
        finalStatus = nextStatus;
    }
    return finalStatus;
}
</cfscript>

<cfparam name="URL.action" default="load"/>
<cfparam name="URL.dashboardLevel" default=""/>
<cfparam name="URL.dashboardAccount" default=""/>
<cfset VARIABLES.researchAction = lCase(trim(URL.action & ""))/>

<cftry>
    <cfset VARIABLES.researchRequestedWith = structKeyExists(CGI, "http_x_requested_with") ? CGI.http_x_requested_with & "" : ""/>
    <cfif CGI.request_method EQ "POST" AND compareNoCase(VARIABLES.researchRequestedWith, "XMLHttpRequest") NEQ 0>
        <cfset researchApiWrite({ success = false, schemaReady = true, message = "Requisição administrativa inválida." }, 403)/>
    </cfif>
    <cfif VARIABLES.researchAction EQ "upload">
        <cfif CGI.request_method NEQ "POST" OR NOT structKeyExists(FORM, "feature_image") OR NOT len(trim(FORM.feature_image & ""))>
            <cfset researchApiWrite({ success = false, message = "Selecione uma imagem para enviar." }, 400)/>
        </cfif>
        <cfset VARIABLES.uploadDirectory = expandPath("/administracao/pesquisas/uploads/")/>
        <cfif NOT directoryExists(VARIABLES.uploadDirectory)><cfdirectory action="create" directory="#VARIABLES.uploadDirectory#"/></cfif>
        <cffile action="upload" filefield="feature_image" destination="#VARIABLES.uploadDirectory#" nameconflict="makeunique" accept="image/jpeg,image/png,image/webp" allowedextensions=".jpg,.jpeg,.png,.webp" strict="true" result="researchUpload"/>
        <cfset VARIABLES.uploadedFile = researchUpload.serverDirectory & "/" & researchUpload.serverFile/>
        <cfif val(researchUpload.fileSize) GT 5242880>
            <cffile action="delete" file="#VARIABLES.uploadedFile#"/>
            <cfset researchApiWrite({ success = false, message = "A imagem deve ter no máximo 5 MB." }, 400)/>
        </cfif>
        <cfset researchApiWrite({ success = true, url = "/administracao/pesquisas/uploads/" & researchUpload.serverFile })/>
    <cfelseif VARIABLES.researchAction EQ "checkemail">
        <cfif CGI.request_method NEQ "POST"><cfset researchApiWrite({ success = false, message = "Método não permitido." }, 405)/></cfif>
        <cfset VARIABLES.requestData = getHttpRequestData()/>
        <cfset VARIABLES.requestBody = toString(VARIABLES.requestData.content)/>
        <cfif NOT isJSON(VARIABLES.requestBody)><cfset researchApiWrite({ success = false, message = "Conteúdo JSON inválido." }, 400)/></cfif>
        <cfset researchApiWrite(researchApiCheckEmail(deserializeJSON(VARIABLES.requestBody)))/>
    <cfelseif VARIABLES.researchAction EQ "save" OR VARIABLES.researchAction EQ "status">
        <cfif CGI.request_method NEQ "POST"><cfset researchApiWrite({ success = false, message = "Método não permitido." }, 405)/></cfif>
        <cfset VARIABLES.requestData = getHttpRequestData()/>
        <cfset VARIABLES.requestBody = toString(VARIABLES.requestData.content)/>
        <cfif NOT isJSON(VARIABLES.requestBody)><cfset researchApiWrite({ success = false, message = "Conteúdo JSON inválido." }, 400)/></cfif>
        <cfset VARIABLES.researchPayload = deserializeJSON(VARIABLES.requestBody)/>
        <cfset VARIABLES.actorId = isDefined("qPerfil") AND qPerfil.recordCount ? val(qPerfil.id) : 0/>
        <cfif VARIABLES.researchAction EQ "save">
            <cfset VARIABLES.savedResearchId = researchApiSave(VARIABLES.researchPayload, VARIABLES.actorId)/>
            <cfset researchApiWrite({ success = true, id = VARIABLES.savedResearchId })/>
        <cfelse>
            <cfset VARIABLES.updatedStatus = researchApiChangeStatus(VARIABLES.researchPayload, VARIABLES.actorId)/>
            <cfset researchApiWrite({ success = true, status = VARIABLES.updatedStatus })/>
        </cfif>
    <cfelse>
        <cfset researchApiWrite(researchApiLoad(URL.dashboardLevel & "", URL.dashboardAccount & ""))/>
    </cfif>
    <cfcatch type="any">
        <cfset VARIABLES.researchErrorMessage = cfcatch.message/>
        <cfif structKeyExists(cfcatch, "detail") AND len(trim(cfcatch.detail & "")) AND compareNoCase(trim(cfcatch.detail & ""), trim(cfcatch.message & "")) NEQ 0>
            <cfset VARIABLES.researchErrorMessage &= " " & cfcatch.detail/>
        </cfif>
        <cfset researchApiWrite({ success = false, schemaReady = true, message = VARIABLES.researchErrorMessage }, 500)/>
    </cfcatch>
</cftry>
