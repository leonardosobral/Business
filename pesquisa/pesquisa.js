(function () {
  "use strict";

  var root = document.getElementById("researchPublicApp");
  if (!root) return;

  var apiUrl = root.getAttribute("data-research-api");
  var slug = root.getAttribute("data-research-slug") || "assinatura-atletas-2026";
  var content = root.querySelector("[data-public-content]");
  var backButton = root.querySelector("[data-public-back]");
  var research = null;
  var flow = [];
  var index = 0;
  var answers = {};
  var selectedPackage = {};
  var packageInitialized = false;
  var price = { value: 20, billing: "monthly" };
  var mustHave = "";
  var submitting = false;
  var sessionToken = window.crypto && window.crypto.randomUUID ? window.crypto.randomUUID() : "research-" + Date.now() + "-" + Math.random().toString(16).slice(2);

  function escapeHtml(value) {
    return String(value == null ? "" : value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
  }

  function money(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 }).format(Number(value) || 0);
  }

  function shuffle(items) {
    var result = items.slice();
    for (var cursor = result.length - 1; cursor > 0; cursor -= 1) { var target = Math.floor(Math.random() * (cursor + 1)); var current = result[cursor]; result[cursor] = result[target]; result[target] = current; }
    return result;
  }

  function stepByType(type) {
    return research.steps.find(function (item) { return item.type === type; });
  }

  function featureSteps() {
    return research.steps.filter(function (item) { return item.type === "feature"; });
  }

  function buildFlow() {
    flow = research.steps.slice();
    if (research.randomize) {
      var random = shuffle(flow.filter(function (item) { return item.type === "feature" && item.random; }));
      var cursor = 0;
      flow = flow.map(function (item) { return item.type === "feature" && item.random ? random[cursor++] : item; });
    }
  }

  function apiRequest(url, options, retries) {
    return fetch(url, options).then(function (response) {
      return response.text().then(function (rawBody) {
        var body = rawBody.replace(/^\uFEFF/, "").trim();
        var payload;
        try {
          payload = JSON.parse(body);
        } catch (parseError) {
          var firstBrace = body.indexOf("{");
          var lastBrace = body.lastIndexOf("}");
          if (firstBrace >= 0 && lastBrace > firstBrace) {
            try { payload = JSON.parse(body.slice(firstBrace, lastBrace + 1)); } catch (ignored) { payload = null; }
          }
          if (!payload) {
            var invalidResponse = new Error("A entrevista demorou para responder. Tente novamente.");
            invalidResponse.transient = true;
            throw invalidResponse;
          }
        }
        if (!response.ok || !payload.success) {
          var apiError = new Error(payload.message || "Entrevista indisponível.");
          apiError.code = payload.code || "";
          throw apiError;
        }
        return payload;
      });
    }).catch(function (error) {
      if (retries > 0 && (error.transient || error.name === "TypeError")) {
        return new Promise(function (resolve) { window.setTimeout(resolve, 450); }).then(function () { return apiRequest(url, options, retries - 1); });
      }
      throw error;
    });
  }

  function loadResearch() {
    content.innerHTML = '<div class="research-public-loading"><i class="fa-solid fa-circle-notch fa-spin"></i><span>Carregando entrevista...</span></div>';
    apiRequest(apiUrl + "?action=load&slug=" + encodeURIComponent(slug), { credentials: "same-origin", cache: "no-store", headers: { Accept: "application/json" } }, 1)
      .then(function (payload) {
        research = payload.research;
        document.title = research.title + " · Road Runners";
        if (research.requireAccount && !research.authenticated) { renderAccountRequired(); return; }
        buildFlow();
        render();
      })
      .catch(function (error) { renderError(error.message); });
  }

  function renderAccountRequired() {
    updateProgress(0, 1);
    backButton.hidden = true;
    content.innerHTML = '<span class="research-survey-kicker">Conta necessária</span><h1 class="research-survey-title">Entre com sua conta Road Runners para responder.</h1><p class="research-survey-lead">A equipe ainda está finalizando a integração segura do login para esta entrevista. Enquanto isso, o administrador pode desativar a exigência de conta.</p><a class="btn btn-warning btn-lg mt-4" href="https://roadrunners.run/">Ir para o Road Runners<i class="fa-solid fa-arrow-up-right-from-square ms-2"></i></a>';
  }

  function renderError(message) {
    updateProgress(0, 1);
    backButton.hidden = true;
    content.innerHTML = '<div class="research-public-error"><i class="fa-solid fa-triangle-exclamation"></i><span class="research-survey-kicker">Não foi possível abrir</span><h1 class="research-survey-title">Esta entrevista está indisponível.</h1><p class="research-survey-lead">' + escapeHtml(message) + '</p><button type="button" class="btn btn-warning mt-4" data-public-retry>Tentar novamente</button></div>';
    content.querySelector("[data-public-retry]").addEventListener("click", loadResearch);
  }

  function updateProgress(current, total) {
    root.querySelector("[data-public-progress]").style.width = Math.round(((current + 1) / total) * 100) + "%";
    root.querySelector("[data-public-counter]").textContent = (current + 1) + " de " + total;
  }

  function render() {
    var current = flow[index];
    updateProgress(index, flow.length);
    backButton.hidden = false;
    backButton.disabled = index === 0 || submitting;
    if (current.type === "intro") renderIntro(current);
    else if (current.type === "info") renderInfo(current);
    else if (current.type === "choice") renderChoice(current);
    else if (current.type === "choice_multiple") renderChoiceMultiple(current);
    else if (current.type === "choice_text") renderChoiceText(current);
    else if (current.type === "choice_multiple_text") renderChoiceMultipleText(current);
    else if (current.type === "text") renderText(current);
    else if (current.type === "runner_level") renderLevel(current);
    else if (current.type === "rr_account") renderAccount(current);
    else if (current.type === "feature") renderFeature(current);
    else if (current.type === "package") renderPackage(current);
    else if (current.type === "pricing") renderPricing(current);
    else if (current.type === "must_have") renderMustHave(current);
    else if (current.type === "contact") renderContact(current);
    else renderThankYou(current);
    bindControls();
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function renderIntro(item) {
    var copy = '<div><span class="research-survey-kicker">Entrevista com atletas</span><h1 class="research-survey-title">' + escapeHtml(item.title || research.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p><div class="research-survey-free-note"><i class="fa-solid fa-circle-check"></i><span><strong>O essencial continua gratuito.</strong> Conta, perfil, calendário, resultados e recursos essenciais continuam gratuitos.</span></div><button type="button" class="btn btn-warning btn-lg mt-4" data-public-next>Começar entrevista<i class="fa-solid fa-arrow-right ms-2"></i></button></div>';
    content.innerHTML = publicLayout(copy, item);
  }

  function renderInfo(item) {
    content.innerHTML = publicLayout('<div><span class="research-survey-kicker">' + escapeHtml(item.name) + '</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p><button type="button" class="btn btn-warning btn-lg mt-4" data-public-next>Continuar<i class="fa-solid fa-arrow-right ms-2"></i></button></div>', item);
  }

  function renderChoice(item) {
    content.innerHTML = publicLayout('<div><span class="research-survey-kicker">Para conhecer você</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p></div>', item) + '<div class="research-survey-question"><strong>' + escapeHtml(item.question) + '</strong>' + optionMarkup(item.key, item.options || [], false) + '</div>';
  }

  function renderChoiceMultiple(item) {
    content.innerHTML = publicLayout('<div><span class="research-survey-kicker">Para conhecer você</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p></div>', item) + '<div class="research-survey-question"><strong>' + escapeHtml(item.question) + '</strong>' + optionMarkup(item.key, item.options || [], false, true, true) + '<div class="research-public-submit-error" data-public-multiple-error></div><button type="button" class="btn btn-warning mt-3" data-public-multiple-next="' + escapeHtml(item.key) + '">Continuar<i class="fa-solid fa-arrow-right ms-2"></i></button></div>';
  }

  function renderChoiceText(item) {
    var textKey = item.key + "_text";
    content.innerHTML = publicLayout('<div><span class="research-survey-kicker">Para conhecer você</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p></div>', item) + '<div class="research-survey-question"><strong>' + escapeHtml(item.question) + '</strong>' + optionMarkup(item.key, item.options || [], false, true) + '<textarea class="form-control form-control-lg mt-3" rows="4" maxlength="2000" placeholder="Conte mais sobre sua escolha" data-public-custom-text="' + escapeHtml(textKey) + '">' + escapeHtml(answers[textKey] || "") + '</textarea><div class="invalid-feedback">Escolha uma opção e preencha o texto.</div><button type="button" class="btn btn-warning mt-3" data-public-custom-next="choice_text" data-public-custom-key="' + escapeHtml(item.key) + '">Continuar<i class="fa-solid fa-arrow-right ms-2"></i></button></div>';
  }

  function renderChoiceMultipleText(item) {
    var textKey = item.key + "_text";
    content.innerHTML = publicLayout('<div><span class="research-survey-kicker">Para conhecer você</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p></div>', item) + '<div class="research-survey-question"><strong>' + escapeHtml(item.question) + '</strong>' + optionMarkup(item.key, item.options || [], false, true, true) + '<textarea class="form-control form-control-lg mt-3" rows="4" maxlength="2000" placeholder="Conte mais sobre suas escolhas" data-public-custom-text="' + escapeHtml(textKey) + '">' + escapeHtml(answers[textKey] || "") + '</textarea><div class="invalid-feedback">Escolha pelo menos uma opção e preencha o texto.</div><button type="button" class="btn btn-warning mt-3" data-public-custom-next="choice_multiple_text" data-public-custom-key="' + escapeHtml(item.key) + '">Continuar<i class="fa-solid fa-arrow-right ms-2"></i></button></div>';
  }

  function renderText(item) {
    content.innerHTML = publicLayout('<div><span class="research-survey-kicker">Para conhecer você</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p></div>', item) + '<div class="research-survey-question"><strong>' + escapeHtml(item.question) + '</strong><textarea class="form-control form-control-lg mt-3" rows="5" maxlength="2000" placeholder="Digite sua resposta" data-public-custom-text="' + escapeHtml(item.key) + '">' + escapeHtml(answers[item.key] || "") + '</textarea><div class="invalid-feedback">Preencha sua resposta para continuar.</div><button type="button" class="btn btn-warning mt-3" data-public-custom-next="text" data-public-custom-key="' + escapeHtml(item.key) + '">Continuar<i class="fa-solid fa-arrow-right ms-2"></i></button></div>';
  }

  function renderLevel(item) {
    content.innerHTML = '<span class="research-survey-kicker">Para conhecer você · 1 de 2</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p>' + optionMarkup("level", [
      { value: "beginner", label: "Estou começando", help: "Corro há menos de um ano." }, { value: "recreational", label: "Corredor recreativo", help: "Corro por saúde e prazer." }, { value: "dedicated", label: "Amador dedicado", help: "Treino com frequência e tenho metas." }, { value: "competitive", label: "Competitivo", help: "Busco performance, rankings ou pódios." }
    ], true);
  }

  function renderAccount(item) {
    content.innerHTML = '<span class="research-survey-kicker">Para conhecer você · 2 de 2</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p><div class="research-survey-question border-0 mt-3 pt-0"><strong>' + escapeHtml(item.question) + '</strong>' + optionMarkup("account", [
      { value: "active", label: "Sim, uso com frequência" }, { value: "occasional", label: "Sim, mas uso pouco" }, { value: "none", label: "Ainda não tenho" }
    ], false) + '</div>';
  }

  function renderFeature(item) {
    content.innerHTML = publicLayout('<div><span class="research-survey-feature-name"><span class="research-survey-feature-icon"><i class="' + escapeHtml(item.icon) + '"></i></span>' + escapeHtml(item.name) + '</span><h1 class="research-survey-feature-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-feature-copy">' + escapeHtml(item.support) + '</p></div>', item) + '<div class="research-survey-question"><strong>' + escapeHtml(item.question || "Você usaria esta funcionalidade?") + '</strong>' + optionMarkup(item.key, [
      { value: "yes", label: "Sim, usaria" }, { value: "maybe", label: "Talvez usaria" }, { value: "no", label: "Não usaria" }
    ], false) + '</div>';
  }

  function optionMarkup(key, options, profile, stayOnStep, multiple) {
    var wrapper = profile ? "research-survey-profile-grid" : "research-survey-options";
    var buttonClass = profile ? "research-survey-profile-option" : "research-survey-option";
    return '<div class="' + wrapper + '">' + options.map(function (option) { var selected = multiple ? Array.isArray(answers[key]) && answers[key].includes(option.value) : answers[key] === option.value; return '<button type="button" class="' + buttonClass + (selected ? ' is-selected' : '') + '" data-public-answer="' + escapeHtml(key) + '" data-public-value="' + escapeHtml(option.value) + '"' + (stayOnStep ? ' data-public-stay="true"' : '') + (multiple ? ' data-public-multiple="true"' : '') + '><strong>' + escapeHtml(option.label) + '</strong>' + (option.help ? '<span>' + escapeHtml(option.help) + '</span>' : '') + '</button>'; }).join("") + '</div>';
  }

  function renderPackage(item) {
    var items = featureSteps().filter(function (featureItem) { return featureItem.package; });
    if (!packageInitialized) {
      items.forEach(function (featureItem) { selectedPackage[featureItem.key] = answers[featureItem.key] === "yes" || answers[featureItem.key] === "maybe"; });
      packageInitialized = true;
    }
    var count = items.filter(function (featureItem) { return selectedPackage[featureItem.key]; }).length;
    content.innerHTML = '<span class="research-survey-kicker">Sua assinatura ideal</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p><div class="research-survey-bundle-grid">' + items.map(function (featureItem) {
      return '<button type="button" class="research-survey-bundle-option' + (selectedPackage[featureItem.key] ? ' is-selected' : '') + '" data-public-package="' + escapeHtml(featureItem.key) + '"><i class="fa-solid ' + (selectedPackage[featureItem.key] ? 'fa-square-check' : 'fa-square') + '"></i><span><strong>' + escapeHtml(featureItem.name) + '</strong><small>' + (answers[featureItem.key] === "yes" ? "Você disse que usaria" : "Disponível para escolher") + '</small></span></button>';
    }).join("") + '</div><button type="button" class="btn btn-warning mt-4" data-public-next' + (count ? "" : " disabled") + '>Continuar com ' + count + ' ' + (count === 1 ? "funcionalidade" : "funcionalidades") + '<i class="fa-solid fa-arrow-right ms-2"></i></button>';
  }

  function renderPricing(item) {
    var discount = Math.max(0, Math.min(50, Number(research.annualDiscount) || 0));
    var annualMonthly = Math.round(price.value * (1 - discount / 100));
    var annualTotal = Math.round(price.value * 12 * (1 - discount / 100));
    content.innerHTML = '<span class="research-survey-kicker">Valor da assinatura</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support === "Compare a opção mensal com o pagamento anual com desconto." ? "Compare a opção mensal com o pagamento anual." : item.support) + '</p><div class="research-survey-price"><div class="d-flex justify-content-between gap-3 mb-2"><strong>Valor mensal considerado justo</strong><span class="research-survey-price-value">' + money(price.value) + '</span></div><input id="publicPriceValue" type="range" min="10" max="200" step="5" value="' + price.value + '" data-public-price="value"><small class="d-block mt-2">Valor mínimo: R$ 10 por mês</small></div><h2 class="h6 mt-4 mb-2">Como você prefere pagar?</h2><div class="research-survey-billing-grid"><button type="button" class="research-survey-billing-option' + (price.billing === "monthly" ? ' is-selected' : '') + '" data-public-billing="monthly"><small>Mensal</small><strong>' + money(price.value) + '/mês</strong><span>Cobrança todos os meses</span></button><button type="button" class="research-survey-billing-option' + (price.billing === "annual" ? ' is-selected' : '') + '" data-public-billing="annual"><small>Anual</small><strong>Equivale a ' + money(annualMonthly) + '/mês</strong><span>Cobrança anual de ' + money(annualTotal) + '</span></button></div><button type="button" class="btn btn-warning mt-4" data-public-next>Confirmar valor e pagamento<i class="fa-solid fa-arrow-right ms-2"></i></button>';
  }

  function renderMustHave(item) {
    var selected = featureSteps().filter(function (featureItem) { return selectedPackage[featureItem.key]; });
    content.innerHTML = '<span class="research-survey-kicker">Prioridade do pacote</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p>' + optionMarkup("mustHave", selected.map(function (featureItem) { return { value: featureItem.key, label: featureItem.name, help: featureItem.title }; }), true);
  }

  function renderContact(item) {
    var emailField = research.emailMode === "disabled" ? "" : '<label class="form-label mt-4" for="publicEmail"><strong>' + escapeHtml(item.question) + (research.emailMode === "optional" ? " (opcional)" : "") + '</strong></label><input class="form-control form-control-lg" id="publicEmail" type="email" autocomplete="email" placeholder="voce@exemplo.com" data-public-email value="' + escapeHtml(answers.email || "") + '"/><small class="d-block text-secondary mt-2">Se informado, o e-mail não poderá ter sido usado em outra resposta desta entrevista.</small><div class="invalid-feedback">Informe um e-mail válido para concluir.</div>';
    content.innerHTML = '<span class="research-survey-kicker">Finalização</span><h1 class="research-survey-title">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead">' + escapeHtml(item.support) + '</p>' + emailField + '<div class="research-public-submit-error" data-public-submit-error></div><button type="button" class="btn btn-warning btn-lg mt-4" data-public-conclude>Concluir entrevista<i class="fa-solid fa-check ms-2"></i></button>';
  }

  function renderThankYou(item) {
    backButton.hidden = true;
    content.innerHTML = '<div class="text-center py-5"><span class="research-survey-success-mark mx-auto mb-3" aria-hidden="true">&#10003;</span><span class="research-survey-kicker">Entrevista concluída</span><h1 class="research-survey-title mx-auto">' + escapeHtml(item.title) + '</h1><p class="research-survey-lead mx-auto">' + escapeHtml(item.support) + '</p><div class="research-survey-free-note mx-auto text-start"><span class="research-survey-inline-check" aria-hidden="true">&#10003;</span><span>Conta, perfil, calendário, resultados e recursos essenciais continuam gratuitos.</span></div>' + (research.redirectUrl ? '<a class="btn btn-warning mt-4" href="' + escapeHtml(research.redirectUrl) + '">Continuar<i class="fa-solid fa-arrow-right ms-2"></i></a>' : '') + '</div>';
  }

  function visualMarkup(item) {
    if (!item.media || item.media === "none") return "";
    if (item.media === "image" && item.imageUrl) return '<div class="research-survey-visual research-survey-image"><img src="' + escapeHtml(item.imageUrl) + '" alt="' + escapeHtml(item.name) + '"/></div>';
    var inner = '<span class="research-mock-label">Prévia da funcionalidade</span><div class="research-mock-heading">' + escapeHtml(item.name) + '</div>';
    if (item.visual === "alerts") inner += '<div class="research-mock-alert"><i class="fa-solid fa-bell"></i><div><strong>Inscrições abertas para 21 km</strong><span>Um aviso no momento certo.</span></div></div><div class="research-mock-alert"><i class="fa-solid fa-camera"></i><div><strong>Suas fotos foram publicadas</strong><span>Sem procurar em vários sites.</span></div></div>';
    else if (item.visual === "performance") inner += '<div class="research-mock-grid"><div class="research-mock-card"><strong>4:52/km</strong><span>pace médio</span></div><div class="research-mock-card"><strong>+4,8%</strong><span>evolução</span></div><div class="research-mock-card"><strong>68%</strong><span>percentil</span></div></div><div class="research-mock-chart"><span style="height:35%"></span><span style="height:48%"></span><span style="height:62%"></span><span style="height:91%"></span></div>';
    else if (item.visual === "platforms") inner += '<div class="research-mock-platforms"><div class="research-mock-platform"><i class="fa-brands fa-strava"></i><span>Strava<br><small>Conectado</small></span></div><div class="research-mock-platform"><i class="fa-solid fa-clock"></i><span>Garmin<br><small>486 atividades</small></span></div><div class="research-mock-platform"><i class="fa-solid fa-stopwatch"></i><span>Coros<br><small>Disponível</small></span></div><div class="research-mock-platform"><i class="fa-solid fa-heart-pulse"></i><span>Polar<br><small>Disponível</small></span></div></div>';
    else if (item.visual === "search") inner += '<div class="research-mock-search"><i class="fa-solid fa-wand-magic-sparkles"></i><span>Meias maratonas planas em SC</span></div><div class="research-mock-alert"><i class="fa-solid fa-location-dot"></i><div><strong>3 provas combinam com sua busca</strong><span>Resultados explicados em uma conversa.</span></div></div>';
    else if (item.visual === "comparison") inner += '<div class="research-mock-people"><div class="research-mock-person"><span class="research-mock-avatar"><i class="fa-solid fa-person-running"></i></span><span><strong>Você</strong><span>10 km · 48min20s</span></span><em>+4,8%</em></div><div class="research-mock-person"><span class="research-mock-avatar"><i class="fa-solid fa-user"></i></span><span><strong>Perfil semelhante</strong><span>10 km · 49min10s</span></span><em>+3,1%</em></div></div>';
    else if (item.visual === "people") inner += '<div class="research-mock-people"><div class="research-mock-person"><span class="research-mock-avatar">AM</span><span><strong>Ana Martins</strong><span>3 provas em comum</span></span><em>Seguir</em></div><div class="research-mock-person"><span class="research-mock-avatar">RC</span><span><strong>Rafael Costa</strong><span>Mesma cidade</span></span><em>Seguir</em></div></div>';
    else if (item.visual === "memories") inner += '<div class="research-mock-grid"><div class="research-mock-card"><strong>12</strong><span>provas</span></div><div class="research-mock-card"><strong>248</strong><span>fotos</span></div><div class="research-mock-card"><strong>4</strong><span>temporadas</span></div></div><div class="research-mock-alert"><i class="fa-solid fa-images"></i><div><strong>Meia Maratona de Floripa</strong><span>Resultado, fotos e percurso reunidos.</span></div></div>';
    else if (item.visual === "benefits") inner += '<div class="research-mock-grid"><div class="research-mock-card"><strong>15%</strong><span>equipamentos</span></div><div class="research-mock-card"><strong>10%</strong><span>recuperação</span></div><div class="research-mock-card"><strong>VIP</strong><span>experiências</span></div></div><div class="research-mock-alert"><i class="fa-solid fa-gift"></i><div><strong>Benefícios para quem corre</strong><span>Vantagens organizadas em um só lugar.</span></div></div>';
    else inner += '<div class="research-mock-grid"><div class="research-mock-card"><strong>01</strong><span>benefício</span></div><div class="research-mock-card"><strong>02</strong><span>resultado</span></div><div class="research-mock-card"><strong>03</strong><span>evolução</span></div></div>';
    return '<div class="research-survey-visual"><div class="research-survey-visual-browser"><span></span><span></span><span></span></div><div class="research-survey-visual-body">' + inner + '</div></div>';
  }

  function publicLayout(copy, item) {
    return '<div class="research-survey-feature-layout' + (!item.media || item.media === "none" ? ' is-without-visual' : '') + '">' + copy + visualMarkup(item) + '</div>';
  }

  function next() { if (index < flow.length - 1) { index += 1; render(); } }

  function bindControls() {
    content.querySelectorAll("[data-public-next]").forEach(function (button) { button.addEventListener("click", next); });
    content.querySelectorAll("[data-public-answer]").forEach(function (button) {
      button.addEventListener("click", function () {
        var key = button.getAttribute("data-public-answer");
        var value = button.getAttribute("data-public-value");
        if (button.getAttribute("data-public-multiple") === "true") {
          var values = Array.isArray(answers[key]) ? answers[key].slice() : [];
          var valueIndex = values.indexOf(value);
          if (valueIndex >= 0) values.splice(valueIndex, 1); else values.push(value);
          answers[key] = values;
        } else answers[key] = value;
        if (key === "mustHave") mustHave = value;
        var stay = button.getAttribute("data-public-stay") === "true";
        render();
        if (!stay) window.setTimeout(next, 180);
      });
    });
    content.querySelectorAll("[data-public-multiple-next]").forEach(function (button) { button.addEventListener("click", function () { var values = answers[button.getAttribute("data-public-multiple-next")]; if (!Array.isArray(values) || !values.length) { var error = content.querySelector("[data-public-multiple-error]"); if (error) error.textContent = "Escolha pelo menos uma opção."; return; } next(); }); });
    content.querySelectorAll("[data-public-custom-text]").forEach(function (field) { field.addEventListener("input", function () { answers[field.getAttribute("data-public-custom-text")] = field.value; field.classList.remove("is-invalid"); }); });
    content.querySelectorAll("[data-public-custom-next]").forEach(function (button) {
      button.addEventListener("click", function () {
        var key = button.getAttribute("data-public-custom-key");
        var mode = button.getAttribute("data-public-custom-next");
        var textKey = mode === "choice_text" || mode === "choice_multiple_text" ? key + "_text" : key;
        var field = content.querySelector('[data-public-custom-text="' + textKey + '"]');
        answers[textKey] = field.value.trim();
        var missingChoice = mode === "choice_text" && !answers[key];
        var missingMultiple = mode === "choice_multiple_text" && (!Array.isArray(answers[key]) || !answers[key].length);
        if (!answers[textKey] || missingChoice || missingMultiple) { field.classList.add("is-invalid"); field.focus(); return; }
        next();
      });
    });
    content.querySelectorAll("[data-public-package]").forEach(function (button) { button.addEventListener("click", function () { var key = button.getAttribute("data-public-package"); selectedPackage[key] = !selectedPackage[key]; if (mustHave === key && !selectedPackage[key]) { mustHave = ""; delete answers.mustHave; } render(); }); });
    content.querySelectorAll("[data-public-billing]").forEach(function (button) { button.addEventListener("click", function () { price.billing = button.getAttribute("data-public-billing"); render(); }); });
    var priceInput = content.querySelector('[data-public-price="value"]');
    if (priceInput) {
      priceInput.addEventListener("change", function () { price.value = Math.max(10, Number(priceInput.value) || 10); render(); });
    }
    var conclude = content.querySelector("[data-public-conclude]");
    if (conclude) conclude.addEventListener("click", submitResearch);
  }

  function submitResearch() {
    if (submitting) return;
    var emailInput = content.querySelector("[data-public-email]");
    var email = emailInput ? emailInput.value.trim() : "";
    if (emailInput && ((research.emailMode === "required" && !emailInput.checkValidity()) || (email && !emailInput.checkValidity()))) { emailInput.classList.add("is-invalid"); emailInput.focus(); return; }
    submitting = true;
    backButton.disabled = true;
    var button = content.querySelector("[data-public-conclude]");
    button.disabled = true;
    button.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin me-2"></i>Enviando resposta';
    var packageKeys = Object.keys(selectedPackage).filter(function (key) { return selectedPackage[key]; });
    apiRequest(apiUrl + "?action=complete&slug=" + encodeURIComponent(slug), {
      method: "POST", credentials: "same-origin", headers: { "Content-Type": "application/json", Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
      body: JSON.stringify({ sessionToken: sessionToken, answers: answers, package: packageKeys, price: { min: price.value, max: price.value, billing: price.billing }, mustHave: mustHave, email: email })
    }, 1)
      .then(function (payload) { research.redirectUrl = payload.redirectUrl || research.redirectUrl; index = flow.length - 1; render(); })
      .catch(function (error) {
        var message = content.querySelector("[data-public-submit-error]");
        if (error.code === "duplicate_email" && emailInput) {
          var feedback = emailInput.parentElement.querySelector(".invalid-feedback");
          if (feedback) feedback.textContent = error.message;
          emailInput.classList.add("is-invalid");
          emailInput.focus();
          message.textContent = "";
        } else {
          message.textContent = error.message;
        }
        button.disabled = false;
        button.innerHTML = 'Concluir entrevista<i class="fa-solid fa-check ms-2"></i>';
        backButton.disabled = false;
      })
      .finally(function () { submitting = false; });
  }

  backButton.addEventListener("click", function () { if (index > 0 && !submitting) { index -= 1; render(); } });
  loadResearch();
})();
