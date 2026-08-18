(function () {
  "use strict";

  var root = document.getElementById("researchAdminMvp");
  if (!root) return;

  var apiUrl = root.getAttribute("data-research-api");
  var defaultResearch = {
    id: 0,
    status: "rascunho",
    config: {
      internalName: "Assinatura para atletas 2026",
      publicTitle: "O próximo Road Runners será construído com quem corre",
      stakeholder: "athlete",
      scope: "general",
      slug: "assinatura-atletas-2026",
      globalRandom: true,
      requireAccount: false,
      emailMode: "optional",
      annualDiscount: 15,
      redirectUrl: ""
    },
    steps: [
      step("welcome", "intro", "Boas-vindas", "O próximo Road Runners será construído com quem corre", "Conheça novas funcionalidades, diga quais usaria e monte uma assinatura que faria sentido para você.", ""),
      step("runner_level", "runner_level", "Nível do corredor", "Como a corrida faz parte da sua vida hoje?", "Seu nível ajuda a entender como as prioridades mudam conforme a experiência.", "Qual opção mais combina com você?"),
      step("rr_account", "rr_account", "Conta Road Runners", "Você já usa o Road Runners?", "Esta resposta ajuda a separar a percepção de quem já conhece a plataforma.", "Hoje, qual é sua relação com o Road Runners?"),
      feature("radar_provas", "Descoberta", "Radar de Provas", "Receba o aviso certo na hora certa.", "Evita acompanhar vários sites para descobrir inscrições, fotos, resultados e mudanças de preço.", "fa-solid fa-bell", "alerts"),
      feature("evolucao_performance", "Performance", "Evolução de Performance", "Enxergue sua evolução além do último resultado.", "Transforma seu histórico em sinais claros para definir metas e acompanhar seu progresso.", "fa-solid fa-chart-line", "performance"),
      feature("central_atividades", "Histórico conectado", "Central de Atividades", "Seu histórico reunido em um só lugar.", "Preserva sua história e mantém as análises consistentes quando você troca de relógio ou aplicativo.", "fa-solid fa-link", "platforms"),
      feature("busca_inteligente", "Descoberta", "Busca Inteligente", "Encontre a prova certa conversando.", "Economiza tempo e encontra opções que os filtros tradicionais podem deixar passar.", "fa-solid fa-wand-magic-sparkles", "search"),
      feature("comparador_atletas", "Performance", "Comparador de Atletas", "Compare desempenhos com contexto.", "Ajuda a encontrar referências realistas e entender sua evolução entre atletas parecidos.", "fa-solid fa-code-compare", "comparison"),
      feature("conexoes_corrida", "Comunidade", "Conexões de Corrida", "Encontre quem compartilha sua jornada.", "Facilita reencontros e novas conexões com interesses esportivos parecidos.", "fa-solid fa-people-group", "people"),
      feature("memorias_corrida", "Experiência", "Memórias de Corrida", "Reviva suas provas em um só lugar.", "Organiza fotos, resultados e momentos marcantes para preservar a história de cada prova.", "fa-solid fa-images", "memories"),
      feature("clube_beneficios", "Experiência", "Clube de Benefícios", "Vantagens que acompanham sua rotina.", "Reúne benefícios relevantes para treinos, provas, equipamentos e recuperação.", "fa-solid fa-gift", "benefits"),
      step("ideal_package", "package", "Sua assinatura ideal", "Monte o pacote que você realmente assinaria.", "Escolha somente as funcionalidades que entregariam valor para você.", "Quais funcionalidades entrariam no seu pacote?"),
      step("price_preference", "pricing", "Valor e periodicidade", "Quanto faria sentido investir?", "Compare a opção mensal com o pagamento anual.", "Como você preferiria pagar?"),
      step("must_have", "must_have", "Funcionalidade indispensável", "Qual não pode ficar de fora?", "Escolha a funcionalidade sem a qual você não assinaria o pacote.", "Qual é indispensável para você?"),
      step("contact", "contact", "Contato", "Só falta um passo.", "Seu e-mail será usado apenas para contato sobre esta pesquisa e novidades relacionadas.", "Qual é o seu melhor e-mail?"),
      step("thank_you", "thank_you", "Agradecimento", "Obrigado por correr esse percurso com a gente.", "Sua resposta foi registrada e vai ajudar a construir uma assinatura mais útil para atletas.", "")
    ]
  };

  var research = clone(defaultResearch);
  var dashboard = emptyDashboard();
  var dashboardFilters = { level: "", account: "" };
  var schemaReady = false;
  var selectedKey = research.steps[0].key;
  var previewFlow = [];
  var previewIndex = 0;
  var previewAnswers = {};
  var previewPackage = {};
  var previewPrice = { value: 20, billing: "monthly" };
  var previewMustHave = "";

  var itemList = root.querySelector("[data-research-item-list]");
  var toast = root.querySelector("[data-research-toast]");
  var previewOverlay = root.querySelector("[data-research-preview]");
  var previewContent = root.querySelector("[data-research-preview-content]");
  var previewFrame = root.querySelector("[data-research-preview-frame]");

  function step(key, type, name, title, support, question) {
    return { key: key, type: type, name: name, title: title, support: support, question: question, area: "", icon: "", media: "none", imageUrl: "", visual: "", package: false, random: false };
  }

  function feature(key, area, name, title, support, icon, visual) {
    return { key: key, type: "feature", name: name, title: title, support: support, question: "Você usaria esta funcionalidade?", area: area, icon: icon, media: "illustration", imageUrl: "", visual: visual, package: true, random: true };
  }

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
  }

  function toBoolean(value) {
    return value === true || value === 1 || value === "1" || String(value).toLowerCase() === "true";
  }

  function money(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 }).format(Number(value) || 0);
  }

  function emptyDashboard() {
    return { summary: { total: 0, last7Days: 0, annualPercent: 0, averageMaxPrice: 0 }, features: [], profiles: [], accounts: [], billing: [], recent: [] };
  }

  function activeStep() {
    return research.steps.find(function (item) { return item.key === selectedKey; }) || research.steps[0];
  }

  function featureSteps() {
    return research.steps.filter(function (item) { return item.type === "feature"; });
  }

  function findStep(type) {
    return research.steps.find(function (item) { return item.type === type; }) || step(type, type, type, "", "", "");
  }

  function showToast(message, isError) {
    toast.textContent = message;
    toast.classList.toggle("is-error", Boolean(isError));
    toast.classList.add("is-visible");
    window.clearTimeout(showToast.timer);
    showToast.timer = window.setTimeout(function () { toast.classList.remove("is-visible"); }, 2800);
  }

  function showSchemaState(message, ready) {
    var notice = root.querySelector("[data-research-schema-notice]");
    schemaReady = ready;
    notice.classList.toggle("is-warning", !ready);
    notice.innerHTML = ready
      ? '<i class="fa-solid fa-circle-check mt-1"></i><div><strong>Entrevista conectada ao banco</strong><span>' + escapeHtml(message || "Configuração e respostas estão sendo persistidas.") + '</span></div>'
      : '<i class="fa-solid fa-triangle-exclamation mt-1"></i><div><strong>Não foi possível acessar os dados da entrevista</strong><span>' + escapeHtml(message || "Confira a conexão, o schema e as permissões do banco. O preview continua disponível com dados de demonstração.") + '</span></div>';
    root.querySelector("[data-research-save]").disabled = !ready;
    renderPublicationState();
  }

  function loadFromServer(options) {
    options = options || {};
    var loadUrl = apiUrl + "?action=load&dashboardLevel=" + encodeURIComponent(dashboardFilters.level) + "&dashboardAccount=" + encodeURIComponent(dashboardFilters.account);
    return fetch(loadUrl, { credentials: "same-origin", cache: "no-store", headers: { Accept: "application/json" } })
      .then(function (response) {
        return response.json().then(function (payload) {
          if (!response.ok) throw new Error(payload.message || "Não foi possível carregar a entrevista.");
          return payload;
        }, function () {
          throw new Error("A API da entrevista não retornou uma resposta válida.");
        });
      })
      .then(function (payload) {
        if (options.dashboardOnly) {
          dashboard = payload.dashboard && payload.dashboard.summary ? payload.dashboard : emptyDashboard();
          renderDashboard();
          return;
        }
        if (!payload.schemaReady) {
          showSchemaState(payload.message, false);
          renderAll();
          return;
        }
        if (payload.research && Array.isArray(payload.research.steps) && payload.research.steps.length) research = payload.research;
        research.steps.forEach(function (item) {
          if (item.key === "price_preference" && item.support === "Compare a opção mensal com o pagamento anual com desconto.") {
            item.support = "Compare a opção mensal com o pagamento anual.";
          }
        });
        dashboard = payload.dashboard && payload.dashboard.summary ? payload.dashboard : emptyDashboard();
        selectedKey = research.steps.some(function (item) { return item.key === selectedKey; }) ? selectedKey : research.steps[0].key;
        showSchemaState("Última configuração carregada com sucesso.", true);
        renderAll();
      })
      .catch(function (error) {
        if (options.dashboardOnly) {
          showToast(error.message, true);
          return;
        }
        showSchemaState(error.message, false);
        renderAll();
      });
  }

  function checkPreviewEmail(email) {
    return fetch(apiUrl + "?action=checkEmail", {
      method: "POST",
      credentials: "same-origin",
      cache: "no-store",
      headers: { "Content-Type": "application/json", Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
      body: JSON.stringify({ surveyId: research.id || 0, email: email })
    }).then(function (response) {
      return response.json().then(function (payload) {
        if (!response.ok || !payload.success) throw new Error(payload.message || "Não foi possível validar o e-mail.");
        return payload;
      });
    });
  }

  function saveToServer(options) {
    options = options || {};
    if (!schemaReady) return Promise.resolve(false);
    var button = root.querySelector("[data-research-save]");
    button.disabled = true;
    button.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin me-2"></i>Salvando';
    return fetch(apiUrl + "?action=save", {
      method: "POST",
      credentials: "same-origin",
      headers: { "Content-Type": "application/json", Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
      body: JSON.stringify({ research: research })
    }).then(function (response) { return response.json().then(function (data) { if (!response.ok || !data.success) throw new Error(data.message || "Não foi possível salvar."); return data; }); })
      .then(function (payload) {
        if (payload.id) research.id = payload.id;
        if (!options.silent) showToast("Entrevista salva no banco.");
        return true;
      })
      .catch(function (error) { showToast(error.message, true); return false; })
      .finally(function () { button.disabled = !schemaReady; button.innerHTML = '<i class="fa-solid fa-floppy-disk me-2"></i>Salvar no banco'; });
  }

  function renderPublicationState() {
    var status = research.status || "rascunho";
    var badge = root.querySelector("[data-research-status-badge]");
    var labels = {
      rascunho: '<i class="fa-solid fa-pen me-1"></i>Rascunho',
      publicada: '<i class="fa-solid fa-circle-check me-1"></i>Publicada',
      encerrada: '<i class="fa-solid fa-circle-stop me-1"></i>Encerrada'
    };
    badge.innerHTML = schemaReady ? (labels[status] || labels.rascunho) : '<i class="fa-solid fa-flask me-1"></i>Modo demonstração';
    badge.classList.toggle("is-published", schemaReady && status === "publicada");
    badge.classList.toggle("is-closed", schemaReady && status === "encerrada");

    root.querySelector("[data-research-publish]").classList.toggle("d-none", !schemaReady || status !== "rascunho");
    root.querySelector("[data-research-unpublish]").classList.toggle("d-none", !schemaReady || status !== "publicada");
    root.querySelector("[data-research-close]").classList.toggle("d-none", !schemaReady || status !== "publicada");

    var publicLink = root.querySelector("[data-research-public-link]");
    var available = schemaReady && status === "publicada";
    publicLink.classList.toggle("disabled", !available);
    publicLink.setAttribute("aria-disabled", available ? "false" : "true");
    publicLink.tabIndex = available ? 0 : -1;
    publicLink.title = available ? "Abrir a entrevista publicada" : (status === "encerrada" ? "A coleta desta entrevista foi encerrada" : "Publique a entrevista para liberar este link");
  }

  function setStatusButtonsDisabled(disabled) {
    ["publish", "unpublish", "close"].forEach(function (action) {
      root.querySelector("[data-research-" + action + "]").disabled = disabled;
    });
  }

  function changePublicationStatus(nextStatus) {
    if (!schemaReady || !research.id) return;
    if (nextStatus === "rascunho" && !window.confirm("Despublicar a entrevista? O link deixará de aceitar acessos, mas as respostas serão preservadas.")) return;
    if (nextStatus === "encerrada" && !window.confirm("Encerrar definitivamente a coleta? As respostas serão preservadas, mas não será possível publicar novamente.")) return;

    setStatusButtonsDisabled(true);
    var preparation = nextStatus === "publicada" ? saveToServer({ silent: true }) : Promise.resolve(true);
    preparation.then(function (ready) {
      if (!ready) throw new Error("Salve a entrevista antes de alterar a publicação.");
      return fetch(apiUrl + "?action=status", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
        body: JSON.stringify({ id: research.id, status: nextStatus })
      });
    }).then(function (response) {
      return response.json().then(function (data) { if (!response.ok || !data.success) throw new Error(data.message || "Não foi possível alterar a publicação."); return data; });
    }).then(function (payload) {
      research.status = payload.status;
      var messages = { publicada: "Entrevista publicada e disponível para respostas.", rascunho: "Entrevista despublicada. As respostas anteriores foram preservadas.", encerrada: "Coleta encerrada. Todas as respostas foram preservadas." };
      showToast(messages[payload.status] || "Status atualizado.");
      renderPublicationState();
    }).catch(function (error) {
      showToast(error.message, true);
    }).finally(function () {
      setStatusButtonsDisabled(false);
    });
  }

  function renderAll() {
    renderStepList();
    loadEditor();
    syncConfigEditor();
    renderDashboard();
    var publicLink = root.querySelector("[data-research-public-link]");
    publicLink.href = "/pesquisa/?slug=" + encodeURIComponent(research.config.slug || "assinatura-atletas-2026");
    renderPublicationState();
  }

  function renderStepList() {
    itemList.innerHTML = research.steps.map(function (item, index) {
      var meta = item.type === "feature" ? item.area + " · Funcionalidade" : typeLabel(item.type);
      return '<button class="research-admin-step-item' + (item.key === selectedKey ? ' is-active' : '') + '" type="button" data-research-item="' + escapeHtml(item.key) + '">' +
        '<span class="research-admin-step-index">' + (index + 1) + '</span><span class="research-admin-step-copy"><strong>' + escapeHtml(item.name) + '</strong><span>' + escapeHtml(meta) + '</span></span><span class="research-admin-step-drag"><i class="fa-solid ' + (item.type === "feature" ? "fa-grip-vertical" : "fa-pen") + '"></i></span></button>';
    }).join("");
    root.querySelector("[data-research-item-count]").textContent = research.steps.length + " etapas · " + featureSteps().length + " funcionalidades";
    itemList.querySelectorAll("[data-research-item]").forEach(function (button) {
      button.addEventListener("click", function () { selectedKey = button.getAttribute("data-research-item"); renderStepList(); loadEditor(); });
    });
  }

  function typeLabel(type) {
    var labels = { intro: "Apresentação", runner_level: "Perfil do atleta", rr_account: "Identificação", package: "Montagem do pacote", pricing: "Preço e pagamento", must_have: "Prioridade", contact: "Finalização", thank_you: "Encerramento" };
    return labels[type] || "Etapa";
  }

  function loadEditor() {
    var item = activeStep();
    if (!item) return;
    var isFeature = item.type === "feature";
    root.querySelector("[data-research-editor-title]").textContent = "Editar: " + item.name;
    root.querySelector("[data-research-duplicate]").classList.toggle("d-none", !isFeature);
    root.querySelector("[data-research-delete]").classList.toggle("d-none", !isFeature);
    root.querySelectorAll("[data-research-feature-field]").forEach(function (field) { field.classList.toggle("d-none", !isFeature); });
    root.querySelector("[data-research-name-column]").classList.toggle("col-lg-8", isFeature);
    root.querySelector("[data-research-name-column]").classList.toggle("col-lg-12", !isFeature);
    root.querySelector("[data-research-name-label]").textContent = isFeature ? "Nome curto da funcionalidade" : "Nome da etapa no editor";
    root.querySelector("[data-research-support-label]").textContent = isFeature ? "Como isso melhora ou ajuda o atleta" : "Texto de apoio";
    root.querySelector("[data-research-support-help]").textContent = isFeature ? "Este é o único texto explicativo exibido ao lado do visual." : "Texto curto exibido abaixo do título.";
    root.querySelector("[data-research-question-field]").classList.toggle("d-none", item.type === "intro" || item.type === "thank_you");
    root.querySelectorAll("[data-research-field]").forEach(function (field) { field.value = item[field.getAttribute("data-research-field")] || ""; });
    updateSwitch("package", item.package);
    updateSwitch("random", item.random);
    updateVisualPlaceholder(item);
  }

  function updateSwitch(name, enabled) {
    var button = root.querySelector('[data-research-switch="' + name + '"]');
    if (!button) return;
    button.classList.toggle("is-on", Boolean(enabled));
    button.setAttribute("aria-pressed", enabled ? "true" : "false");
  }

  function updateVisualPlaceholder(item) {
    var placeholder = root.querySelector("[data-research-visual-placeholder]");
    if (item.media === "image" && item.imageUrl) {
      placeholder.innerHTML = '<img class="research-admin-upload-preview" src="' + escapeHtml(item.imageUrl) + '" alt="Visual de ' + escapeHtml(item.name) + '"/>';
      return;
    }
    placeholder.innerHTML = '<div class="research-admin-placeholder-window"><span></span><span></span><span></span></div><div class="research-admin-placeholder-content"><i class="' + escapeHtml(item.icon || "fa-solid fa-wand-magic-sparkles") + '"></i><strong>' + escapeHtml(item.name) + '</strong><span>Ilustração de ' + escapeHtml(item.visual || "interface") + ' gerada no próprio protótipo.</span></div>';
  }

  function bindEditor() {
    root.querySelectorAll("[data-research-field]").forEach(function (field) {
      field.addEventListener("input", function () {
        var item = activeStep();
        if (!item) return;
        var property = field.getAttribute("data-research-field");
        item[property] = field.value;
        if (item.type === "intro" && property === "title") {
          research.config.publicTitle = field.value;
          root.querySelector('[data-research-config="publicTitle"]').value = field.value;
        }
        renderStepList();
      });
    });
    root.querySelectorAll("[data-research-config]").forEach(function (field) {
      field.addEventListener("input", function () {
        var key = field.getAttribute("data-research-config");
        research.config[key] = key === "annualDiscount" ? Math.max(0, Math.min(50, Number(field.value) || 0)) : field.value;
        if (key === "publicTitle") findStep("intro").title = field.value;
        if (key === "slug") root.querySelector("[data-research-public-link]").href = "/pesquisa/?slug=" + encodeURIComponent(field.value);
      });
    });
    root.querySelectorAll("[data-research-switch]").forEach(function (button) {
      button.addEventListener("click", function () {
        var property = button.getAttribute("data-research-switch");
        var next = !button.classList.contains("is-on");
        button.classList.toggle("is-on", next);
        button.setAttribute("aria-pressed", next ? "true" : "false");
        if (property === "package" || property === "random") activeStep()[property] = next;
        else research.config[property] = next;
      });
    });
    root.querySelector("[data-research-media]").addEventListener("click", function () { var item = activeStep(); item.media = "illustration"; item.imageUrl = ""; updateVisualPlaceholder(item); });
    root.querySelector("[data-research-image-upload]").addEventListener("change", uploadImage);
  }

  function syncConfigEditor() {
    root.querySelectorAll("[data-research-config]").forEach(function (field) { var key = field.getAttribute("data-research-config"); field.value = research.config[key] == null ? "" : research.config[key]; });
    updateSwitch("globalRandom", toBoolean(research.config.globalRandom));
    updateSwitch("requireAccount", toBoolean(research.config.requireAccount));
  }

  function uploadImage(event) {
    var file = event.target.files[0];
    var status = root.querySelector("[data-research-upload-status]");
    if (!file) return;
    if (!schemaReady) { showToast("Aplique o schema antes de enviar imagens.", true); event.target.value = ""; return; }
    if (file.size > 5 * 1024 * 1024) { showToast("A imagem deve ter no máximo 5 MB.", true); event.target.value = ""; return; }
    var data = new FormData();
    data.append("feature_image", file);
    status.textContent = "Enviando imagem...";
    fetch(apiUrl + "?action=upload", { method: "POST", credentials: "same-origin", body: data, headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" } })
      .then(function (response) { return response.json().then(function (payload) { if (!response.ok || !payload.success) throw new Error(payload.message || "Falha no upload."); return payload; }); })
      .then(function (payload) { var item = activeStep(); item.media = "image"; item.imageUrl = payload.url; updateVisualPlaceholder(item); status.textContent = "Imagem pronta. Salve a entrevista para confirmar a alteração."; })
      .catch(function (error) { status.textContent = ""; showToast(error.message, true); })
      .finally(function () { event.target.value = ""; });
  }

  function openAddDialog() { var dialog = root.querySelector("[data-research-add-dialog]"); dialog.hidden = false; window.setTimeout(function () { root.querySelector("#researchNewFeatureName").focus(); }, 0); }
  function closeAddDialog() { root.querySelector("[data-research-add-dialog]").hidden = true; root.querySelector("#researchNewFeatureName").value = ""; }

  function addFeature() {
    var input = root.querySelector("#researchNewFeatureName");
    var name = input.value.trim();
    if (!name) { input.focus(); return; }
    var item = feature("feature_" + Date.now(), "Experiência", name, name, "Mostre de forma direta como esta ideia ajudaria quem corre.", "fa-solid fa-star", "generic");
    var packageIndex = research.steps.findIndex(function (current) { return current.type === "package"; });
    research.steps.splice(packageIndex < 0 ? research.steps.length : packageIndex, 0, item);
    selectedKey = item.key;
    closeAddDialog();
    renderStepList();
    loadEditor();
    showToast("Funcionalidade adicionada. Salve para gravar no banco.");
  }

  function duplicateFeature() {
    var source = activeStep();
    if (!source || source.type !== "feature") return;
    var copy = clone(source);
    copy.key = "feature_" + Date.now();
    copy.name = source.name + " - cópia";
    var index = research.steps.indexOf(source);
    research.steps.splice(index + 1, 0, copy);
    selectedKey = copy.key;
    renderStepList();
    loadEditor();
  }

  function deleteFeature() {
    var item = activeStep();
    if (!item || item.type !== "feature") return;
    if (featureSteps().length <= 1) {
      showToast("A entrevista precisa manter pelo menos uma funcionalidade.", true);
      return;
    }
    if (!window.confirm('Excluir a funcionalidade "' + item.name + '"? Ela sairá da entrevista após salvar no banco.')) return;

    var currentIndex = research.steps.findIndex(function (stepItem) { return stepItem.key === item.key; });
    research.steps.splice(currentIndex, 1);
    delete previewAnswers[item.key];
    delete previewPackage[item.key];
    if (previewMustHave === item.key) previewMustHave = "";
    selectedKey = research.steps[Math.min(currentIndex, research.steps.length - 1)].key;
    renderAll();
    showToast("Funcionalidade removida. Salve no banco para confirmar.");
  }

  function shuffle(items) {
    var result = items.slice();
    for (var index = result.length - 1; index > 0; index -= 1) { var target = Math.floor(Math.random() * (index + 1)); var current = result[index]; result[index] = result[target]; result[target] = current; }
    return result;
  }

  function buildPreviewFlow() {
    var features = featureSteps();
    if (toBoolean(research.config.globalRandom)) {
      var fixed = features.filter(function (item) { return !item.random; });
      var random = features.filter(function (item) { return item.random; });
      features = fixed.concat(shuffle(random));
    }
    previewFlow = [findStep("intro"), findStep("runner_level"), findStep("rr_account")].concat(features, [findStep("package"), findStep("pricing"), findStep("must_have"), findStep("contact"), findStep("thank_you")]);
  }

  function openPreview() {
    buildPreviewFlow();
    previewIndex = 0;
    previewAnswers = {};
    previewPackage = {};
    previewPrice = { value: 20, billing: "monthly" };
    previewMustHave = "";
    previewOverlay.hidden = false;
    document.body.style.overflow = "hidden";
    renderPreview();
  }

  function closePreview() { previewOverlay.hidden = true; document.body.style.overflow = ""; }

  function visualMarkup(item) {
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

  function optionsMarkup(key, options, profile) {
    var className = profile ? "research-survey-profile-option" : "research-survey-option";
    var wrapper = profile ? "research-survey-profile-grid" : "research-survey-options";
    return '<div class="' + wrapper + '">' + options.map(function (option) {
      return '<button type="button" class="' + className + (previewAnswers[key] === option.value ? ' is-selected' : '') + '" data-preview-answer="' + escapeHtml(key) + '" data-preview-value="' + escapeHtml(option.value) + '"><strong>' + escapeHtml(option.label) + '</strong>' + (option.help ? '<span>' + escapeHtml(option.help) + '</span>' : '') + '</button>';
    }).join("") + '</div>';
  }

  function renderPreview() {
    var current = previewFlow[previewIndex];
    var progress = Math.round(((previewIndex + 1) / previewFlow.length) * 100);
    var previewBackButton = root.querySelector("[data-research-preview-back]");
    root.querySelector("[data-research-preview-progress]").style.width = progress + "%";
    root.querySelector("[data-research-preview-counter]").textContent = (previewIndex + 1) + " de " + previewFlow.length;
    previewBackButton.hidden = current.type === "thank_you";
    previewBackButton.disabled = previewIndex === 0;

    if (current.type === "intro") renderIntro(current);
    else if (current.type === "runner_level") renderLevel(current);
    else if (current.type === "rr_account") renderAccount(current);
    else if (current.type === "feature") renderFeature(current);
    else if (current.type === "package") renderPackage(current);
    else if (current.type === "pricing") renderPricing(current);
    else if (current.type === "must_have") renderMustHave(current);
    else if (current.type === "contact") renderContact(current);
    else renderThankYou(current);
    bindPreviewControls();
  }

  function renderIntro(item) {
    previewContent.innerHTML = '<span class="research-survey-kicker">Entrevista com atletas</span><h2 class="research-survey-title">' + escapeHtml(item.title || research.config.publicTitle) + '</h2><p class="research-survey-lead">' + escapeHtml(item.support) + '</p><div class="research-survey-free-note"><i class="fa-solid fa-circle-check"></i><span><strong>O essencial continua gratuito.</strong> Conta, perfil, calendário, resultados e recursos essenciais continuam gratuitos.</span></div><button type="button" class="btn btn-warning btn-lg mt-4" data-preview-go-next>Começar entrevista<i class="fa-solid fa-arrow-right ms-2"></i></button>';
  }

  function renderLevel(item) {
    previewContent.innerHTML = '<span class="research-survey-kicker">Para conhecer você · 1 de 2</span><h2 class="research-survey-title">' + escapeHtml(item.title) + '</h2><p class="research-survey-lead">' + escapeHtml(item.support) + '</p>' + optionsMarkup("level", [
      { value: "beginner", label: "Estou começando", help: "Corro há menos de um ano." }, { value: "recreational", label: "Corredor recreativo", help: "Corro por saúde e prazer." }, { value: "dedicated", label: "Amador dedicado", help: "Treino com frequência e tenho metas." }, { value: "competitive", label: "Competitivo", help: "Busco performance, rankings ou pódios." }
    ], true);
  }

  function renderAccount(item) {
    previewContent.innerHTML = '<span class="research-survey-kicker">Para conhecer você · 2 de 2</span><h2 class="research-survey-title">' + escapeHtml(item.title) + '</h2><p class="research-survey-lead">' + escapeHtml(item.support) + '</p><div class="research-survey-question border-0 mt-3 pt-0"><strong>' + escapeHtml(item.question) + '</strong>' + optionsMarkup("account", [
      { value: "active", label: "Sim, uso com frequência" }, { value: "occasional", label: "Sim, mas uso pouco" }, { value: "none", label: "Ainda não tenho" }
    ], false) + '</div>';
  }

  function renderFeature(item) {
    previewContent.innerHTML = '<div class="research-survey-feature-layout"><div><span class="research-survey-feature-name"><span class="research-survey-feature-icon"><i class="' + escapeHtml(item.icon) + '"></i></span>' + escapeHtml(item.name) + '</span><h2 class="research-survey-feature-title">' + escapeHtml(item.title) + '</h2><p class="research-survey-feature-copy">' + escapeHtml(item.support) + '</p></div>' + visualMarkup(item) + '</div><div class="research-survey-question"><strong>' + escapeHtml(item.question || "Você usaria esta funcionalidade?") + '</strong>' + optionsMarkup(item.key, [
      { value: "yes", label: "Sim, usaria" }, { value: "maybe", label: "Talvez usaria" }, { value: "no", label: "Não usaria" }
    ], false) + '</div>';
  }

  function renderPackage(item) {
    var items = featureSteps().filter(function (featureItem) { return featureItem.package; });
    if (!Object.keys(previewPackage).length) items.forEach(function (featureItem) { previewPackage[featureItem.key] = previewAnswers[featureItem.key] === "yes" || previewAnswers[featureItem.key] === "maybe"; });
    var selected = items.filter(function (featureItem) { return previewPackage[featureItem.key]; });
    previewContent.innerHTML = '<span class="research-survey-kicker">Sua assinatura ideal</span><h2 class="research-survey-title">' + escapeHtml(item.title) + '</h2><p class="research-survey-lead">' + escapeHtml(item.support) + '</p><div class="research-survey-bundle-grid">' + items.map(function (featureItem) {
      return '<button type="button" class="research-survey-bundle-option' + (previewPackage[featureItem.key] ? ' is-selected' : '') + '" data-preview-package="' + escapeHtml(featureItem.key) + '"><i class="fa-solid ' + (previewPackage[featureItem.key] ? 'fa-square-check' : 'fa-square') + '"></i><span><strong>' + escapeHtml(featureItem.name) + '</strong><small>' + (previewAnswers[featureItem.key] === "yes" ? "Você disse que usaria" : "Disponível para escolher") + '</small></span></button>';
    }).join("") + '</div><button type="button" class="btn btn-warning mt-4" data-preview-go-next' + (selected.length ? "" : " disabled") + '>Continuar com ' + selected.length + ' ' + (selected.length === 1 ? "funcionalidade" : "funcionalidades") + '<i class="fa-solid fa-arrow-right ms-2"></i></button>';
  }

  function renderPricing(item) {
    var discount = Math.max(0, Math.min(50, Number(research.config.annualDiscount) || 0));
    var annualMonthly = Math.round(previewPrice.value * (1 - discount / 100));
    var annualTotal = Math.round(previewPrice.value * 12 * (1 - discount / 100));
    previewContent.innerHTML = '<span class="research-survey-kicker">Valor da assinatura</span><h2 class="research-survey-title">' + escapeHtml(item.title) + '</h2><p class="research-survey-lead">' + escapeHtml(item.support) + '</p><div class="research-survey-price"><div class="d-flex justify-content-between gap-3 mb-2"><strong>Valor mensal considerado justo</strong><span class="research-survey-price-value">' + money(previewPrice.value) + '</span></div><input id="previewPriceValue" type="range" min="10" max="200" step="5" value="' + previewPrice.value + '" data-preview-price="value"><small class="d-block mt-2">Valor mínimo: R$ 10 por mês</small></div><h3 class="h6 mt-4 mb-2">Como você prefere pagar?</h3><div class="research-survey-billing-grid"><button type="button" class="research-survey-billing-option' + (previewPrice.billing === "monthly" ? ' is-selected' : '') + '" data-preview-billing="monthly"><small>Mensal</small><strong>' + money(previewPrice.value) + '/mês</strong><span>Cobrança todos os meses</span></button><button type="button" class="research-survey-billing-option' + (previewPrice.billing === "annual" ? ' is-selected' : '') + '" data-preview-billing="annual"><small>Anual</small><strong>Equivale a ' + money(annualMonthly) + '/mês</strong><span>Cobrança anual de ' + money(annualTotal) + '</span></button></div><button type="button" class="btn btn-warning mt-4" data-preview-go-next>Confirmar valor e pagamento<i class="fa-solid fa-arrow-right ms-2"></i></button>';
  }

  function renderMustHave(item) {
    var selected = featureSteps().filter(function (featureItem) { return previewPackage[featureItem.key]; });
    previewContent.innerHTML = '<span class="research-survey-kicker">Prioridade do pacote</span><h2 class="research-survey-title">' + escapeHtml(item.title) + '</h2><p class="research-survey-lead">' + escapeHtml(item.support) + '</p>' + optionsMarkup("mustHave", selected.map(function (featureItem) { return { value: featureItem.key, label: featureItem.name, help: featureItem.title }; }), true);
  }

  function renderContact(item) {
    var emailField = research.config.emailMode === "disabled" ? "" : '<label class="form-label mt-4" for="previewEmail"><strong>' + escapeHtml(item.question) + (research.config.emailMode === "optional" ? " (opcional)" : "") + '</strong></label><input class="form-control form-control-lg" id="previewEmail" type="email" autocomplete="email" placeholder="voce@exemplo.com" data-preview-email value="' + escapeHtml(previewAnswers.email || "") + '"/><small class="d-block research-admin-muted mt-2">Se informado, o e-mail não poderá ter sido usado em outra resposta desta entrevista.</small><div class="invalid-feedback">Informe um e-mail válido para concluir.</div>';
    previewContent.innerHTML = '<span class="research-survey-kicker">Finalização</span><h2 class="research-survey-title">' + escapeHtml(item.title) + '</h2><p class="research-survey-lead">' + escapeHtml(item.support) + '</p>' + emailField + '<button type="button" class="btn btn-warning btn-lg mt-4" data-preview-conclude>Concluir entrevista<i class="fa-solid fa-check ms-2"></i></button>';
  }

  function renderThankYou(item) {
    previewContent.innerHTML = '<div class="text-center py-5"><span class="research-survey-success-mark mx-auto mb-3" aria-hidden="true">&#10003;</span><span class="research-survey-kicker">Entrevista concluída</span><h2 class="research-survey-title mx-auto">' + escapeHtml(item.title) + '</h2><p class="research-survey-lead mx-auto">' + escapeHtml(item.support) + '</p><div class="research-survey-free-note mx-auto text-start"><span class="research-survey-inline-check" aria-hidden="true">&#10003;</span><span>Conta, perfil, calendário, resultados e recursos essenciais continuam gratuitos.</span></div></div>';
  }

  function goNext() { if (previewIndex < previewFlow.length - 1) { previewIndex += 1; renderPreview(); } }

  function bindPreviewControls() {
    previewContent.querySelectorAll("[data-preview-answer]").forEach(function (button) {
      button.addEventListener("click", function () { previewAnswers[button.getAttribute("data-preview-answer")] = button.getAttribute("data-preview-value"); renderPreview(); window.setTimeout(goNext, 180); });
    });
    previewContent.querySelectorAll("[data-preview-package]").forEach(function (button) { button.addEventListener("click", function () { var key = button.getAttribute("data-preview-package"); previewPackage[key] = !previewPackage[key]; if (previewMustHave === key && !previewPackage[key]) previewMustHave = ""; renderPreview(); }); });
    previewContent.querySelectorAll("[data-preview-billing]").forEach(function (button) { button.addEventListener("click", function () { previewPrice.billing = button.getAttribute("data-preview-billing"); renderPreview(); }); });
    previewContent.querySelectorAll("[data-preview-go-next]").forEach(function (button) { button.addEventListener("click", goNext); });
    var mustHave = previewContent.querySelector('[data-preview-answer="mustHave"]');
    if (mustHave) previewMustHave = previewAnswers.mustHave || "";
    var priceInput = previewContent.querySelector('[data-preview-price="value"]');
    if (priceInput) {
      priceInput.addEventListener("change", function () { previewPrice.value = Math.max(10, Number(priceInput.value) || 10); renderPreview(); });
    }
    var conclude = previewContent.querySelector("[data-preview-conclude]");
    if (conclude) conclude.addEventListener("click", function () {
      var email = previewContent.querySelector("[data-preview-email]");
      if (!email) { goNext(); return; }
      previewAnswers.email = email.value.trim().toLowerCase();
      var invalidEmail = (research.config.emailMode === "required" && !previewAnswers.email) || (previewAnswers.email && !email.checkValidity());
      if (invalidEmail) { email.classList.add("is-invalid"); email.focus(); return; }
      if (!previewAnswers.email) { goNext(); return; }
      conclude.disabled = true;
      email.disabled = true;
      conclude.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin me-2"></i>Validando e-mail';
      checkPreviewEmail(previewAnswers.email).then(function (payload) {
        if (!payload.available) {
          var feedback = email.parentElement.querySelector(".invalid-feedback");
          if (feedback) feedback.textContent = payload.message;
          email.classList.add("is-invalid");
          email.focus();
          return;
        }
        goNext();
      }).catch(function (error) { showToast(error.message, true); }).finally(function () {
        email.disabled = false;
        conclude.disabled = false;
        conclude.innerHTML = 'Concluir entrevista<i class="fa-solid fa-check ms-2"></i>';
      });
      email.addEventListener("input", function () { email.classList.remove("is-invalid"); }, { once: true });
    });
  }

  function renderDashboard() {
    var total = Number(dashboard.summary.total) || 0;
    var hasFilters = Boolean(dashboardFilters.level || dashboardFilters.account);
    root.querySelector("[data-research-dashboard-empty]").classList.toggle("d-none", total > 0 || hasFilters);
    root.querySelector("[data-research-dashboard-content]").classList.toggle("d-none", total === 0 && !hasFilters);
    root.querySelectorAll("[data-research-dashboard-filter]").forEach(function (field) { field.value = dashboardFilters[field.getAttribute("data-research-dashboard-filter")] || ""; });
    if (!total && !hasFilters) return;
    root.querySelector("[data-research-dashboard-kpis]").innerHTML = [
      ["Entrevistas concluídas", total, "fa-circle-check"], ["Últimos 7 dias", dashboard.summary.last7Days || 0, "fa-calendar-week"], ["Preferem anual", (dashboard.summary.annualPercent || 0) + "%", "fa-percent"], ["Máximo médio", money(dashboard.summary.averageMaxPrice || 0), "fa-wallet"]
    ].map(function (item) { return '<article class="research-dashboard-kpi"><span><i class="fa-solid ' + item[2] + '"></i></span><div><small>' + item[0] + '</small><strong>' + item[1] + '</strong></div></article>'; }).join("");
    root.querySelector("[data-research-feature-results]").innerHTML = (dashboard.features || []).map(function (item) { var interest = Number(item.interestPercent) || 0; return '<div class="research-dashboard-feature"><div class="d-flex justify-content-between gap-3"><strong>' + escapeHtml(item.name) + '</strong><span>' + interest + '% usariam</span></div><div class="research-dashboard-bar"><span style="width:' + Math.min(100, interest) + '%"></span></div><small>' + (item.packagePercent || 0) + '% no pacote · ' + (item.mustHaveCount || 0) + ' marcaram como indispensável</small></div>'; }).join("");
    var profileRows = (dashboard.profiles || []).map(function (item) { return metricRow(profileLabel(item.value), item.count, item.percent); }).join("");
    var accountRows = (dashboard.accounts || []).map(function (item) { return metricRow(accountLabel(item.value), item.count, item.percent); }).join("");
    var billingRows = (dashboard.billing || []).map(function (item) { return metricRow(item.value === "annual" ? "Anual" : "Mensal", item.count, item.percent); }).join("");
    root.querySelector("[data-research-profile-results]").innerHTML = '<h3 class="research-dashboard-subtitle">Nível do corredor</h3>' + profileRows + '<h3 class="research-dashboard-subtitle mt-4">Conta Road Runners</h3>' + accountRows + '<h3 class="research-dashboard-subtitle mt-4">Forma de pagamento</h3>' + billingRows;
    var recentMarkup = (dashboard.recent || []).map(function (item, itemIndex) {
      var detailId = "research-response-" + itemIndex;
      var packageNames = Array.isArray(item.packageNames) ? item.packageNames : [];
      var packageMarkup = packageNames.length ? packageNames.map(function (name) { return '<span class="research-dashboard-package-chip">' + escapeHtml(name) + '</span>'; }).join("") : '<span class="research-admin-muted">Nenhuma funcionalidade informada.</span>';
      var mustHaveMarkup = item.mustHaveName ? '<div class="research-dashboard-must-have"><i class="fa-solid fa-star"></i><span><small>Indispensável</small><strong>' + escapeHtml(item.mustHaveName) + '</strong></span></div>' : "";
      return '<tr class="research-dashboard-response-row" tabindex="0" aria-expanded="false" aria-controls="' + detailId + '" data-research-response-toggle="' + detailId + '"><td>' + escapeHtml(item.completedAt) + '</td><td><strong>' + escapeHtml(item.email || "Anônimo") + '</strong><i class="fa-solid fa-chevron-down ms-2"></i></td><td>' + escapeHtml(profileLabel(item.level)) + '</td><td>' + escapeHtml(item.billing === "annual" ? "Anual" : "Mensal") + '</td><td><strong>' + escapeHtml(responsePriceLabel(item)) + '</strong></td><td>' + escapeHtml(item.packageCount) + '</td></tr>' +
        '<tr class="research-dashboard-response-detail" id="' + detailId + '" hidden><td colspan="6"><div class="research-dashboard-response-detail-inner"><div><span class="research-dashboard-detail-label">Funcionalidades escolhidas no pacote</span><div class="research-dashboard-package-list">' + packageMarkup + '</div></div><div class="research-dashboard-response-meta"><span><small>Conta Road Runners</small><strong>' + escapeHtml(accountLabel(item.account)) + '</strong></span>' + mustHaveMarkup + '</div></div></td></tr>';
    }).join("");
    root.querySelector("[data-research-recent-results]").innerHTML = recentMarkup || '<tr><td class="text-center research-admin-muted py-4" colspan="6">Nenhuma resposta encontrada para estes filtros.</td></tr>';
    root.querySelectorAll("[data-research-response-toggle]").forEach(function (row) {
      function toggleResponseDetail() {
        var detail = document.getElementById(row.getAttribute("data-research-response-toggle"));
        var expanded = row.getAttribute("aria-expanded") === "true";
        row.setAttribute("aria-expanded", String(!expanded));
        detail.hidden = expanded;
      }
      row.addEventListener("click", toggleResponseDetail);
      row.addEventListener("keydown", function (event) { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); toggleResponseDetail(); } });
    });
  }

  function responsePriceLabel(item) {
    var annual = item.billing === "annual";
    var minimum = Number(annual ? item.annualPriceMin : item.priceMin) || 0;
    var maximum = Number(annual ? item.annualPriceMax : item.priceMax) || minimum;
    return money(minimum) + (maximum !== minimum ? " a " + money(maximum) : "") + (annual ? "/ano" : "/mês");
  }

  function metricRow(label, count, percent) { return '<div class="research-dashboard-metric"><div><strong>' + escapeHtml(label) + '</strong><span>' + escapeHtml(count) + ' respostas</span></div><em>' + escapeHtml(percent) + '%</em></div>'; }
  function profileLabel(value) { return ({ beginner: "Estou começando", recreational: "Recreativo", dedicated: "Amador dedicado", competitive: "Competitivo" })[value] || value || "Não informado"; }
  function accountLabel(value) { return ({ active: "Usa com frequência", occasional: "Tem conta, usa pouco", none: "Ainda não tem conta" })[value] || value || "Não informado"; }

  root.querySelectorAll("[data-research-tab]").forEach(function (button) { button.addEventListener("click", function () { var target = button.getAttribute("data-research-tab"); root.querySelectorAll("[data-research-tab]").forEach(function (tab) { tab.classList.toggle("active", tab === button); }); root.querySelectorAll("[data-research-view]").forEach(function (view) { view.classList.toggle("d-none", view.getAttribute("data-research-view") !== target); }); }); });
  root.querySelector("[data-research-save]").addEventListener("click", saveToServer);
  root.querySelector("[data-research-publish]").addEventListener("click", function () { changePublicationStatus("publicada"); });
  root.querySelector("[data-research-unpublish]").addEventListener("click", function () { changePublicationStatus("rascunho"); });
  root.querySelector("[data-research-close]").addEventListener("click", function () { changePublicationStatus("encerrada"); });
  root.querySelector("[data-research-public-link]").addEventListener("click", function (event) { if (research.status !== "publicada") event.preventDefault(); });
  root.querySelector("[data-research-add-block]").addEventListener("click", openAddDialog);
  root.querySelectorAll("[data-research-add-close]").forEach(function (button) { button.addEventListener("click", closeAddDialog); });
  root.querySelector("[data-research-add-confirm]").addEventListener("click", addFeature);
  root.querySelector("[data-research-duplicate]").addEventListener("click", duplicateFeature);
  root.querySelector("[data-research-delete]").addEventListener("click", deleteFeature);
  root.querySelector("[data-research-preview-open]").addEventListener("click", openPreview);
  root.querySelector("[data-research-preview-close]").addEventListener("click", closePreview);
  root.querySelector("[data-research-shuffle]").addEventListener("click", function () { buildPreviewFlow(); previewIndex = Math.min(3, previewFlow.length - 1); renderPreview(); });
  root.querySelector("[data-research-dashboard-refresh]").addEventListener("click", function () { loadFromServer({ dashboardOnly: true }); });
  root.querySelectorAll("[data-research-dashboard-filter]").forEach(function (field) { field.addEventListener("change", function () { dashboardFilters[field.getAttribute("data-research-dashboard-filter")] = field.value; loadFromServer({ dashboardOnly: true }); }); });
  root.querySelector("[data-research-dashboard-clear]").addEventListener("click", function () { dashboardFilters = { level: "", account: "" }; loadFromServer({ dashboardOnly: true }); });
  root.querySelectorAll("[data-research-device]").forEach(function (button) { button.addEventListener("click", function () { var mobile = button.getAttribute("data-research-device") === "mobile"; previewFrame.classList.toggle("is-mobile", mobile); root.querySelectorAll("[data-research-device]").forEach(function (deviceButton) { var active = deviceButton === button; deviceButton.classList.toggle("btn-warning", active); deviceButton.classList.toggle("btn-outline-light", !active); }); }); });
  root.querySelector("[data-research-preview-back]").addEventListener("click", function () { if (previewIndex > 0) { previewIndex -= 1; renderPreview(); } });

  bindEditor();
  renderAll();
  loadFromServer();
})();
