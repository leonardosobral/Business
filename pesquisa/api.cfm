<cfprocessingdirective pageencoding="utf-8"/>
<cfsetting showdebugoutput="false" requesttimeout="30"/>

<cfscript>
function publicResearchWrite(required any payload, numeric statusCode = 200) {
    cfheader(name = "Cache-Control", value = "no-store, no-cache, must-revalidate, max-age=0");
    cfheader(name = "Pragma", value = "no-cache");
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(publicResearchSerialize(arguments.payload));
    abort;
}

function publicResearchSerialize(required any payload) {
    var serialized = serializeJSON(arguments.payload);
    var keys = [
        ["SUCCESS", "success"], ["MESSAGE", "message"], ["CODE", "code"],
        ["RESEARCH", "research"], ["ID", "id"], ["TITLE", "title"], ["SLUG", "slug"],
        ["RANDOMIZE", "randomize"], ["REQUIREACCOUNT", "requireAccount"],
        ["AUTHENTICATED", "authenticated"], ["EMAILMODE", "emailMode"],
        ["ANNUALDISCOUNT", "annualDiscount"], ["REDIRECTURL", "redirectUrl"],
        ["STEPS", "steps"], ["KEY", "key"], ["TYPE", "type"], ["NAME", "name"],
        ["SUPPORT", "support"], ["QUESTION", "question"], ["AREA", "area"],
        ["ICON", "icon"], ["MEDIA", "media"], ["VISUAL", "visual"],
        ["IMAGEURL", "imageUrl"], ["OPTIONS", "options"], ["LABEL", "label"], ["HELP", "help"], ["PACKAGE", "package"], ["RANDOM", "random"],
        ["RESPONSEID", "responseId"]
    ];
    for (var pair in keys) {
        serialized = replace(serialized, '"' & pair[1] & '":', '"' & pair[2] & '":', "all");
    }
    return serialized;
}

function publicResearchBoolean(any value = false) {
    if (isBoolean(arguments.value)) return arguments.value;
    return listFindNoCase("1,true,yes,on,sim", trim(arguments.value & "")) GT 0;
}

function publicResearchStepTypeToClient(required string value) {
    var types = {
        boas_vindas = "intro", nivel_corredor = "runner_level", conta_rr = "rr_account",
        informativa = "info", pergunta_escolha = "choice", pergunta_multipla = "choice_multiple", pergunta_escolha_texto = "choice_text", pergunta_multipla_texto = "choice_multiple_text", pergunta_texto = "text", funcionalidade = "feature", pacote = "package", preco = "pricing",
        indispensavel = "must_have", contato = "contact", agradecimento = "thank_you"
    };
    var key = lCase(trim(arguments.value));
    return structKeyExists(types, key) ? types[key] : key;
}

function publicResearchVisualToClient(required string value) {
    var types = { nenhum = "none", ilustracao = "illustration", imagem = "image" };
    var key = lCase(trim(arguments.value));
    return structKeyExists(types, key) ? types[key] : key;
}

function publicResearchEmailToClient(required string value) {
    var modes = { desativado = "disabled", opcional = "optional", obrigatorio = "required" };
    var key = lCase(trim(arguments.value));
    return structKeyExists(modes, key) ? modes[key] : "optional";
}

function publicResearchAnswerToDatabase(required string group, required string value) {
    var maps = {
        level = { beginner = "iniciante", recreational = "recreativo", dedicated = "dedicado", competitive = "competitivo" },
        account = { active = "frequente", occasional = "ocasional", none = "sem_conta" },
        billing = { monthly = "mensal", annual = "anual" },
        interest = { yes = "sim", maybe = "talvez", no = "nao" }
    };
    var groupKey = lCase(trim(arguments.group));
    var valueKey = lCase(trim(arguments.value));
    return structKeyExists(maps, groupKey) && structKeyExists(maps[groupKey], valueKey) ? maps[groupKey][valueKey] : valueKey;
}

function publicResearchText(required query source, required string columnName, required numeric rowIndex, string fallback = "") {
    if (!listFindNoCase(arguments.source.columnList, arguments.columnName) || isNull(arguments.source[arguments.columnName][arguments.rowIndex])) return arguments.fallback;
    return arguments.source[arguments.columnName][arguments.rowIndex] & "";
}

function publicResearchOptions(required query source, required numeric rowIndex) {
    var value = publicResearchText(arguments.source, "opcoes", arguments.rowIndex, "[]");
    if (!len(trim(value)) || !isJSON(value)) return [];
    var options = deserializeJSON(value);
    return isArray(options) ? options : [];
}

function publicResearchTablesReady() {
    var check = queryExecute("SELECT to_regclass('tb_pesquisas') IS NOT NULL AND to_regclass('tb_pesquisa_etapas') IS NOT NULL AND to_regclass('tb_pesquisa_respostas') IS NOT NULL AND to_regclass('tb_pesquisa_resposta_etapas') IS NOT NULL AND to_regclass('tb_pesquisa_resposta_funcionalidades') IS NOT NULL AS ready");
    return publicResearchBoolean(check.ready[1]);
}

function publicResearchSurvey(required string slug) {
    return queryExecute(
        "SELECT id_pesquisa, titulo_publico, slug, status, randomizar_funcionalidades, exigir_conta_rr, modo_email, desconto_anual, url_redirecionamento " &
        "FROM tb_pesquisas WHERE slug = :slug LIMIT 1",
        { slug = { value = lCase(trim(arguments.slug)), cfsqltype = "cf_sql_varchar" } }
    );
}

function publicResearchConfiguration(required query survey) {
    var surveyId = arguments.survey.id_pesquisa[1];
    var stepsQuery = queryExecute(
        "SELECT id_etapa, chave, tipo, nome, titulo, texto_apoio, pergunta, area, icone, tipo_visual, visual_modelo, imagem_url, opcoes::text AS opcoes, incluir_pacote, randomizavel, ordem " &
        "FROM tb_pesquisa_etapas WHERE id_pesquisa = :survey_id AND ativo = true ORDER BY ordem, id_etapa",
        { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" } }
    );
    var steps = [];
    for (var rowIndex = 1; rowIndex <= stepsQuery.recordCount; rowIndex++) {
        arrayAppend(steps, {
            id = val(stepsQuery.id_etapa[rowIndex]), key = publicResearchText(stepsQuery, "chave", rowIndex), type = publicResearchStepTypeToClient(publicResearchText(stepsQuery, "tipo", rowIndex)),
            name = publicResearchText(stepsQuery, "nome", rowIndex), title = publicResearchText(stepsQuery, "titulo", rowIndex), support = publicResearchText(stepsQuery, "texto_apoio", rowIndex), question = publicResearchText(stepsQuery, "pergunta", rowIndex),
            area = publicResearchText(stepsQuery, "area", rowIndex), icon = publicResearchText(stepsQuery, "icone", rowIndex), media = publicResearchVisualToClient(publicResearchText(stepsQuery, "tipo_visual", rowIndex, "nenhum")), visual = publicResearchText(stepsQuery, "visual_modelo", rowIndex), imageUrl = publicResearchText(stepsQuery, "imagem_url", rowIndex),
            options = publicResearchOptions(stepsQuery, rowIndex),
            package = publicResearchBoolean(stepsQuery.incluir_pacote[rowIndex]), random = publicResearchBoolean(stepsQuery.randomizavel[rowIndex])
        });
    }
    return {
        id = surveyId,
        title = publicResearchText(arguments.survey, "titulo_publico", 1),
        slug = publicResearchText(arguments.survey, "slug", 1),
        randomize = publicResearchBoolean(arguments.survey.randomizar_funcionalidades[1]),
        requireAccount = publicResearchBoolean(arguments.survey.exigir_conta_rr[1]),
        authenticated = false,
        emailMode = publicResearchEmailToClient(publicResearchText(arguments.survey, "modo_email", 1, "opcional")),
        annualDiscount = val(arguments.survey.desconto_anual[1]),
        redirectUrl = publicResearchText(arguments.survey, "url_redirecionamento", 1),
        steps = steps
    };
}

function publicResearchArrayContains(required array source, required string value) {
    for (var item in arguments.source) if (compareNoCase(trim(item & ""), trim(arguments.value)) EQ 0) return true;
    return false;
}

function publicResearchSave(required struct payload, required query survey) {
    if (!structKeyExists(arguments.payload, "answers") || !isStruct(arguments.payload.answers)) throw(message = "As respostas da entrevista não foram enviadas.");
    var answers = arguments.payload.answers;
    var level = structKeyExists(answers, "level") ? lCase(trim(answers.level & "")) : "";
    var account = structKeyExists(answers, "account") ? lCase(trim(answers.account & "")) : "";
    if (!listFindNoCase("beginner,recreational,dedicated,competitive", level)) throw(message = "Selecione seu nível de corrida.");
    if (!listFindNoCase("active,occasional,none", account)) throw(message = "Responda sobre sua conta Road Runners.");
    var levelDatabase = publicResearchAnswerToDatabase("level", level);
    var accountDatabase = publicResearchAnswerToDatabase("account", account);

    var emailMode = publicResearchEmailToClient(publicResearchText(arguments.survey, "modo_email", 1, "opcional"));
    var email = structKeyExists(arguments.payload, "email") ? lCase(trim(arguments.payload.email & "")) : "";
    if (emailMode EQ "required" && !isValid("email", email)) throw(message = "Informe um e-mail válido para concluir.");
    if (len(email) && !isValid("email", email)) throw(message = "O e-mail informado não é válido.");

    if (!structKeyExists(arguments.payload, "price") || !isStruct(arguments.payload.price)) throw(message = "Informe a preferência de valor.");
    var billing = listFindNoCase("monthly,annual", arguments.payload.price.billing & "") ? lCase(arguments.payload.price.billing & "") : "monthly";
    var billingDatabase = publicResearchAnswerToDatabase("billing", billing);
    var priceMin = max(10, val(arguments.payload.price.min));
    var priceMax = max(10, val(arguments.payload.price.max));
    if (priceMax < priceMin) priceMax = priceMin;
    var discount = min(50, max(0, val(arguments.survey.desconto_anual[1])));
    var annualMin = round(priceMin * 12 * (1 - discount / 100));
    var annualMax = round(priceMax * 12 * (1 - discount / 100));
    var selectedPackage = structKeyExists(arguments.payload, "package") && isArray(arguments.payload.package) ? arguments.payload.package : [];
    var mustHave = structKeyExists(arguments.payload, "mustHave") ? trim(arguments.payload.mustHave & "") : "";
    var sessionToken = structKeyExists(arguments.payload, "sessionToken") ? left(trim(arguments.payload.sessionToken & ""), 100) : "";
    if (!len(sessionToken)) throw(message = "A sessão da entrevista expirou. Recarregue a página.");
    if (!arrayLen(selectedPackage)) throw(message = "Escolha pelo menos uma funcionalidade para o pacote.");
    if (!len(mustHave) || !publicResearchArrayContains(selectedPackage, mustHave)) throw(message = "Escolha a funcionalidade indispensável dentro do seu pacote.");

    var surveyId = arguments.survey.id_pesquisa[1];
    var featureQuery = queryExecute(
        "SELECT id_etapa, chave FROM tb_pesquisa_etapas WHERE id_pesquisa = :survey_id AND tipo = 'funcionalidade' AND ativo = true ORDER BY ordem",
        { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" } }
    );
    var fixedQuery = queryExecute(
        "SELECT id_etapa, chave, tipo, opcoes::text AS opcoes FROM tb_pesquisa_etapas WHERE id_pesquisa = :survey_id AND tipo <> 'funcionalidade' AND ativo = true",
        { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" } }
    );
    var allowedInterests = "yes,maybe,no";
    // O vínculo com tb_usuarios só será preenchido após validar o token do login Road Runners.
    var userId = 0;
    var ipAddress = structKeyExists(CGI, "remote_addr") ? CGI.remote_addr & "" : "";
    var ipHash = hash(ipAddress & "|RoadRunnersResearch|" & surveyId, "SHA-256");
    var userAgent = structKeyExists(CGI, "http_user_agent") ? left(CGI.http_user_agent & "", 500) : "";
    var responseId = 0;
    var responseCode = "";

    var existingResponse = queryExecute(
        "SELECT codigo_publico FROM tb_pesquisa_respostas WHERE id_pesquisa = :survey_id AND token_sessao = :session_token AND status = 'concluida' LIMIT 1",
        { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" }, session_token = { value = sessionToken, cfsqltype = "cf_sql_varchar" } }
    );
    if (existingResponse.recordCount) return { id = existingResponse.codigo_publico[1] & "", redirectUrl = publicResearchText(arguments.survey, "url_redirecionamento", 1) };

    if (len(email)) {
        var duplicateEmail = queryExecute(
            "SELECT 1 FROM tb_pesquisa_respostas WHERE id_pesquisa = :survey_id AND status = 'concluida' AND lower(btrim(email)) = :email LIMIT 1",
            { survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" }, email = { value = email, cfsqltype = "cf_sql_varchar" } }
        );
        if (duplicateEmail.recordCount) throw(type = "Research.DuplicateEmail", message = "Este e-mail já foi utilizado para responder esta entrevista.");
    }

    transaction {
        var responseQuery = queryExecute(
            "INSERT INTO tb_pesquisa_respostas (id_pesquisa, token_sessao, id_usuario, email, nivel_corredor, conta_rr, periodicidade, valor_mensal_min, valor_mensal_max, valor_anual_min, valor_anual_max, status, concluido_em, endereco_ip_hash, agente_usuario, metadados) " &
            "VALUES (:survey_id, :session_token, :user_id, :email, :level, :account, :billing, :price_min, :price_max, :annual_min, :annual_max, 'concluida', now(), :ip_hash, :user_agent, cast(:metadata AS jsonb)) RETURNING id_resposta, codigo_publico",
            {
                survey_id = { value = surveyId, cfsqltype = "cf_sql_bigint" }, session_token = { value = sessionToken, cfsqltype = "cf_sql_varchar" }, user_id = { value = userId, cfsqltype = "cf_sql_bigint", null = userId LTE 0 }, email = { value = email, cfsqltype = "cf_sql_varchar", null = !len(email) }, level = { value = levelDatabase, cfsqltype = "cf_sql_varchar" }, account = { value = accountDatabase, cfsqltype = "cf_sql_varchar" }, billing = { value = billingDatabase, cfsqltype = "cf_sql_varchar" },
                price_min = { value = priceMin, cfsqltype = "cf_sql_decimal", scale = 2 }, price_max = { value = priceMax, cfsqltype = "cf_sql_decimal", scale = 2 }, annual_min = { value = annualMin, cfsqltype = "cf_sql_decimal", scale = 2 }, annual_max = { value = annualMax, cfsqltype = "cf_sql_decimal", scale = 2 }, ip_hash = { value = ipHash, cfsqltype = "cf_sql_varchar" }, user_agent = { value = userAgent, cfsqltype = "cf_sql_varchar", null = !len(userAgent) }, metadata = { value = serializeJSON({ origem = "web_publica" }), cfsqltype = "cf_sql_longvarchar" }
            }
        );
        responseId = responseQuery.id_resposta[1];
        responseCode = responseQuery.codigo_publico[1] & "";

        for (var featureRow = 1; featureRow <= featureQuery.recordCount; featureRow++) {
            var featureKey = featureQuery.chave[featureRow] & "";
            var interest = structKeyExists(answers, featureKey) && listFindNoCase(allowedInterests, answers[featureKey] & "") ? lCase(answers[featureKey] & "") : "no";
            var interestDatabase = publicResearchAnswerToDatabase("interest", interest);
            queryExecute(
                "INSERT INTO tb_pesquisa_resposta_funcionalidades (id_resposta, id_etapa, interesse, selecionada_pacote, indispensavel) VALUES (:response_id, :step_id, :interest, :selected, :must_have)",
                { response_id = { value = responseId, cfsqltype = "cf_sql_bigint" }, step_id = { value = featureQuery.id_etapa[featureRow], cfsqltype = "cf_sql_bigint" }, interest = { value = interestDatabase, cfsqltype = "cf_sql_varchar" }, selected = { value = publicResearchArrayContains(selectedPackage, featureKey), cfsqltype = "cf_sql_bit" }, must_have = { value = compareNoCase(mustHave, featureKey) EQ 0, cfsqltype = "cf_sql_bit" } }
            );
        }

        for (var fixedRow = 1; fixedRow <= fixedQuery.recordCount; fixedRow++) {
            var fixedType = fixedQuery.tipo[fixedRow] & "";
            var fixedAnswer = {};
            if (fixedType EQ "nivel_corredor") fixedAnswer = { valor = levelDatabase };
            else if (fixedType EQ "conta_rr") fixedAnswer = { valor = accountDatabase };
            else if (fixedType EQ "pacote") fixedAnswer = { selecionadas = selectedPackage };
            else if (fixedType EQ "preco") fixedAnswer = { periodicidade = billingDatabase, mensalMinimo = priceMin, mensalMaximo = priceMax, anualMinimo = annualMin, anualMaximo = annualMax };
            else if (fixedType EQ "indispensavel") fixedAnswer = { valor = mustHave };
            else if (fixedType EQ "contato") fixedAnswer = { emailInformado = len(email) GT 0 };
            else if (fixedType EQ "pergunta_escolha" OR fixedType EQ "pergunta_escolha_texto") {
                var customKey = fixedQuery.chave[fixedRow] & "";
                var customValue = structKeyExists(answers, customKey) ? trim(answers[customKey] & "") : "";
                var customOptions = publicResearchOptions(fixedQuery, fixedRow);
                var customLabel = "";
                for (var customOption in customOptions) {
                    if (isStruct(customOption) && structKeyExists(customOption, "value") && compareNoCase(customOption.value & "", customValue) EQ 0) {
                        customLabel = structKeyExists(customOption, "label") ? customOption.label & "" : customValue;
                        break;
                    }
                }
                if (!len(customValue) || !len(customLabel)) throw(message = "Responda à pergunta " & fixedQuery.chave[fixedRow] & ".");
                fixedAnswer = { valor = customValue, rotulo = customLabel };
                if (fixedType EQ "pergunta_escolha_texto") {
                    var choiceText = structKeyExists(answers, customKey & "_text") ? left(trim(answers[customKey & "_text"] & ""), 2000) : "";
                    if (!len(choiceText)) throw(message = "Complete o texto da pergunta " & customKey & ".");
                    fixedAnswer.texto = choiceText;
                }
            }
            else if (fixedType EQ "pergunta_multipla" OR fixedType EQ "pergunta_multipla_texto") {
                var multipleKey = fixedQuery.chave[fixedRow] & "";
                var submittedValues = structKeyExists(answers, multipleKey) && isArray(answers[multipleKey]) ? answers[multipleKey] : [];
                var multipleOptions = publicResearchOptions(fixedQuery, fixedRow);
                var acceptedValues = [];
                var acceptedLabels = [];
                for (var multipleOption in multipleOptions) {
                    if (isStruct(multipleOption) && structKeyExists(multipleOption, "value") && publicResearchArrayContains(submittedValues, multipleOption.value & "")) {
                        arrayAppend(acceptedValues, multipleOption.value & "");
                        arrayAppend(acceptedLabels, structKeyExists(multipleOption, "label") ? multipleOption.label & "" : multipleOption.value & "");
                    }
                }
                if (!arrayLen(acceptedValues) || arrayLen(acceptedValues) NEQ arrayLen(submittedValues)) throw(message = "Selecione opções válidas na pergunta " & multipleKey & ".");
                fixedAnswer = { valores = acceptedValues, rotulos = acceptedLabels };
                if (fixedType EQ "pergunta_multipla_texto") {
                    var multipleText = structKeyExists(answers, multipleKey & "_text") ? left(trim(answers[multipleKey & "_text"] & ""), 2000) : "";
                    if (!len(multipleText)) throw(message = "Complete o texto da pergunta " & multipleKey & ".");
                    fixedAnswer.texto = multipleText;
                }
            }
            else if (fixedType EQ "pergunta_texto") {
                var textKey = fixedQuery.chave[fixedRow] & "";
                var textValue = structKeyExists(answers, textKey) ? left(trim(answers[textKey] & ""), 2000) : "";
                if (!len(textValue)) throw(message = "Responda à pergunta " & textKey & ".");
                fixedAnswer = { texto = textValue };
            }
            if (!structIsEmpty(fixedAnswer)) {
                queryExecute(
                    "INSERT INTO tb_pesquisa_resposta_etapas (id_resposta, id_etapa, resposta) VALUES (:response_id, :step_id, cast(:answer AS jsonb))",
                    { response_id = { value = responseId, cfsqltype = "cf_sql_bigint" }, step_id = { value = fixedQuery.id_etapa[fixedRow], cfsqltype = "cf_sql_bigint" }, answer = { value = serializeJSON(fixedAnswer), cfsqltype = "cf_sql_longvarchar" } }
                );
            }
        }
    }
    return { id = responseCode, redirectUrl = publicResearchText(arguments.survey, "url_redirecionamento", 1) };
}
</cfscript>

<cfparam name="URL.action" default="load"/>
<cfparam name="URL.slug" default="assinatura-atletas-2026"/>

<cftry>
    <cfif NOT publicResearchTablesReady()><cfset publicResearchWrite({ success = false, message = "A entrevista ainda não está disponível." }, 503)/></cfif>
    <cfset VARIABLES.publicAction = lCase(trim(URL.action & ""))/>
    <cfset VARIABLES.publicSlug = lCase(trim(URL.slug & ""))/>
    <cfset qPublicSurvey = publicResearchSurvey(VARIABLES.publicSlug)/>
    <cfif NOT qPublicSurvey.recordCount><cfset publicResearchWrite({ success = false, message = "Entrevista não encontrada." }, 404)/></cfif>
    <cfset VARIABLES.publicStatus = qPublicSurvey.status[1] & ""/>
    <cfif VARIABLES.publicStatus EQ "rascunho">
        <cfset publicResearchWrite({ success = false, code = "not_published", message = "Esta entrevista ainda não foi publicada." }, 403)/>
    <cfelseif VARIABLES.publicStatus EQ "encerrada">
        <cfset publicResearchWrite({ success = false, code = "closed", message = "Esta entrevista foi encerrada. Obrigado pelo interesse." }, 410)/>
    <cfelseif VARIABLES.publicStatus NEQ "publicada">
        <cfset publicResearchWrite({ success = false, message = "Esta entrevista não está disponível." }, 403)/>
    </cfif>

    <cfif VARIABLES.publicAction EQ "complete">
        <cfif CGI.request_method NEQ "POST"><cfset publicResearchWrite({ success = false, message = "Método não permitido." }, 405)/></cfif>
        <cfset VARIABLES.publicRequestedWith = structKeyExists(CGI, "http_x_requested_with") ? CGI.http_x_requested_with & "" : ""/>
        <cfset VARIABLES.publicContentType = structKeyExists(CGI, "content_type") ? CGI.content_type & "" : ""/>
        <cfif compareNoCase(VARIABLES.publicRequestedWith, "XMLHttpRequest") NEQ 0 OR NOT findNoCase("application/json", VARIABLES.publicContentType)>
            <cfset publicResearchWrite({ success = false, message = "Requisição inválida." }, 403)/>
        </cfif>
        <cfif publicResearchBoolean(qPublicSurvey.exigir_conta_rr[1])>
            <cfset publicResearchWrite({ success = false, code = "account_integration_pending", message = "Esta entrevista exige uma conta Road Runners, mas a integração segura do Google Login ainda não foi habilitada." }, 503)/>
        </cfif>
        <cfset VARIABLES.requestData = getHttpRequestData()/>
        <cfset VARIABLES.requestBody = toString(VARIABLES.requestData.content)/>
        <cfif NOT isJSON(VARIABLES.requestBody)><cfset publicResearchWrite({ success = false, message = "Conteúdo inválido." }, 400)/></cfif>
        <cfset VARIABLES.publicPayload = deserializeJSON(VARIABLES.requestBody)/>
        <cfset VARIABLES.savedResponse = publicResearchSave(VARIABLES.publicPayload, qPublicSurvey)/>
        <cfset publicResearchWrite({ success = true, responseId = VARIABLES.savedResponse.id, redirectUrl = VARIABLES.savedResponse.redirectUrl })/>
    <cfelse>
        <cfset publicResearchWrite({ success = true, research = publicResearchConfiguration(qPublicSurvey) })/>
    </cfif>
    <cfcatch type="any">
        <cfset VARIABLES.publicErrorDetail = structKeyExists(cfcatch, "detail") ? cfcatch.detail & "" : ""/>
        <cfif compareNoCase(cfcatch.type & "", "Research.DuplicateEmail") EQ 0 OR findNoCase("uq_pesquisa_respostas_email_concluida", cfcatch.message & " " & VARIABLES.publicErrorDetail)>
            <cfset publicResearchWrite({ success = false, code = "duplicate_email", message = "Este e-mail já foi utilizado para responder esta entrevista." }, 409)/>
        </cfif>
        <cfset publicResearchWrite({ success = false, message = cfcatch.message }, 500)/>
    </cfcatch>
</cftry>
