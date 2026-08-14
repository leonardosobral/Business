(function () {
  "use strict";

  var root = document.getElementById("researchAdminMvp");
  if (!root) return;

  var storageKey = "business:research-mvp:draft:v2";
  var defaultResearch = {
    config: {
      internalName: "Assinatura para atletas 2026",
      publicTitle: "O próximo Road Runners será construído com quem corre",
      stakeholder: "atleta",
      scope: "general",
      slug: "assinatura-atletas-2026",
      globalRandom: true,
      requireAccount: false
    },
    items: [
      {
        key: "radar_provas",
        area: "Descoberta",
        name: "Radar de Provas",
        icon: "fa-solid fa-bell",
        title: "Receba o aviso certo antes de perder uma oportunidade.",
        explanation: "Crie alertas por distância, região, abertura de inscrição, mudança de preço, publicação de resultado ou fotos.",
        solution: "Você não precisa acompanhar vários sites e redes sociais para saber quando algo importante aconteceu.",
        media: "interface",
        visual: "alerts",
        package: true,
        random: true
      },
      {
        key: "evolucao_performance",
        area: "Performance",
        name: "Evolução de Performance",
        icon: "fa-solid fa-chart-line",
        title: "Entenda sua evolução além do último resultado.",
        explanation: "Veja tendências de pace, projeções, percentis e comparações por temporada, distância e tipo de prova.",
        solution: "Transforma seu histórico de corridas em sinais claros para definir metas e acompanhar seu progresso.",
        media: "interface",
        visual: "performance",
        package: true,
        random: true
      },
      {
        key: "central_atividades",
        area: "Histórico conectado",
        name: "Central de Atividades",
        icon: "fa-solid fa-link",
        title: "Reúna seu histórico, mesmo usando plataformas diferentes.",
        explanation: "Sincronize dados históricos e conecte Strava, Garmin, Coros, Polar e outras plataformas em um só lugar.",
        solution: "Preserva sua história e mantém as análises consistentes quando você troca de relógio ou aplicativo.",
        media: "interface",
        visual: "platforms",
        package: true,
        random: true
      },
      {
        key: "busca_inteligente",
        area: "Descoberta",
        name: "Busca Inteligente",
        icon: "fa-solid fa-wand-magic-sparkles",
        title: "Encontre a prova certa conversando com o Road Runners.",
        explanation: "Faça perguntas em linguagem natural e receba eventos, resultados e conteúdos que combinam com seu objetivo.",
        solution: "Economiza tempo e encontra opções que os filtros tradicionais podem deixar passar.",
        media: "interface",
        visual: "search",
        package: true,
        random: true
      },
      {
        key: "comparador_atletas",
        area: "Performance",
        name: "Comparador de Atletas",
        icon: "fa-solid fa-code-compare",
        title: "Compare desempenhos com contexto, não apenas pelo tempo final.",
        explanation: "Compare evolução, melhores marcas, regularidade, categorias e resultados em percursos semelhantes.",
        solution: "Ajuda a encontrar referências realistas e entender onde você evoluiu em relação a perfis parecidos.",
        media: "interface",
        visual: "comparison",
        package: true,
        random: true
      },
      {
        key: "conexoes_corrida",
        area: "Comunidade",
        name: "Conexões de Corrida",
        icon: "fa-solid fa-people-group",
        title: "Descubra quem compartilha provas e histórias com você.",
        explanation: "Encontre participantes por distância, cidade e assessoria, além de amigos de amigos e eventos em comum.",
        solution: "Facilita reencontros, novas amizades e conexões com interesses esportivos parecidos.",
        media: "interface",
        visual: "people",
        package: true,
        random: true
      }
    ]
  };

  var research = loadResearch();
  var selectedKey = research.items.length ? research.items[0].key : "";
  var previewOrder = [];
  var previewIndex = 0;
  var previewAnswers = {};
  var previewPackage = {};
  var previewPrice = { min: 20, max: 40 };
  var previewMustHave = "";
  var previewPackageInitialized = false;

  var itemList = root.querySelector("[data-research-item-list]");
  var toast = root.querySelector("[data-research-toast]");
  var previewOverlay = root.querySelector("[data-research-preview]");
  var previewContent = root.querySelector("[data-research-preview-content]");
  var previewFrame = root.querySelector("[data-research-preview-frame]");

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function loadResearch() {
    try {
      var saved = JSON.parse(window.localStorage.getItem(storageKey));
      if (saved && saved.config && Array.isArray(saved.items) && saved.items.length) return saved;
    } catch (error) {
      console.warn("Não foi possível carregar o rascunho local da pesquisa.", error);
    }
    return clone(defaultResearch);
  }

  function saveResearch(showConfirmation) {
    try {
      window.localStorage.setItem(storageKey, JSON.stringify(research));
      if (showConfirmation) showToast("Rascunho salvo neste navegador.");
    } catch (error) {
      showToast("Não foi possível salvar o rascunho local.");
    }
  }

  function showToast(message) {
    toast.textContent = message;
    toast.classList.add("is-visible");
    window.clearTimeout(showToast.timer);
    showToast.timer = window.setTimeout(function () {
      toast.classList.remove("is-visible");
    }, 2200);
  }

  function activeItem() {
    return research.items.find(function (item) { return item.key === selectedKey; }) || research.items[0];
  }

  function renderItemList() {
    var rows = [
      { fixed: true, name: "Boas-vindas", meta: "Apresentação" },
      { fixed: true, name: "Nível e conta Road Runners", meta: "Identificação" }
    ].concat(research.items).concat([
      { fixed: true, name: "Pacote e faixa de preço", meta: "Etapa final" }
    ]);

    itemList.innerHTML = rows.map(function (item, index) {
      if (item.fixed) {
        return '<button class="research-admin-step-item" type="button" disabled>' +
          '<span class="research-admin-step-index">' + (index + 1) + '</span>' +
          '<span class="research-admin-step-copy"><strong>' + escapeHtml(item.name) + '</strong><span>' + escapeHtml(item.meta) + '</span></span>' +
          '<span class="research-admin-step-drag"><i class="fa-solid fa-lock"></i></span></button>';
      }
      return '<button class="research-admin-step-item' + (item.key === selectedKey ? ' is-active' : '') + '" type="button" data-research-item="' + escapeHtml(item.key) + '">' +
        '<span class="research-admin-step-index">' + (index + 1) + '</span>' +
        '<span class="research-admin-step-copy"><strong>' + escapeHtml(item.name) + '</strong><span>' + escapeHtml(item.area) + ' · Funcionalidade</span></span>' +
        '<span class="research-admin-step-drag"><i class="fa-solid fa-grip-vertical"></i></span></button>';
    }).join("");

    root.querySelector("[data-research-item-count]").textContent = rows.length + " blocos · " + research.items.length + " funcionalidades";
    root.querySelectorAll("[data-research-item]").forEach(function (button) {
      button.addEventListener("click", function () {
        selectedKey = button.getAttribute("data-research-item");
        renderItemList();
        loadEditor();
      });
    });
  }

  function loadEditor() {
    var item = activeItem();
    if (!item) return;
    root.querySelectorAll("[data-research-field]").forEach(function (field) {
      field.value = item[field.getAttribute("data-research-field")] || "";
    });
    root.querySelectorAll("[data-research-media]").forEach(function (button) {
      var isActive = button.getAttribute("data-research-media") === item.media;
      button.classList.toggle("btn-warning", isActive);
      button.classList.toggle("btn-outline-light", !isActive);
    });
    updateEditorSwitch("package", item.package);
    updateEditorSwitch("random", item.random);
    updateVisualPlaceholder(item.media);
  }

  function updateEditorSwitch(name, enabled) {
    var button = root.querySelector('[data-research-switch="' + name + '"]');
    if (!button) return;
    button.classList.toggle("is-on", Boolean(enabled));
    button.setAttribute("aria-pressed", enabled ? "true" : "false");
  }

  function updateVisualPlaceholder(media) {
    var placeholder = root.querySelector("[data-research-visual-placeholder]");
    var content = placeholder.querySelector(".research-admin-placeholder-content");
    if (media === "video") {
      content.innerHTML = '<i class="fa-solid fa-circle-play"></i><strong>Espaço para vídeo curto</strong><span>O upload real será habilitado na versão com backend.</span>';
    } else if (media === "none") {
      content.innerHTML = '<i class="fa-solid fa-align-left"></i><strong>Apresentação somente em texto</strong><span>O preview não exibirá um painel visual.</span>';
    } else {
      content.innerHTML = '<i class="fa-solid fa-wand-magic-sparkles"></i><strong>Ilustração de interface</strong><span>O visual será gerado conforme o tipo da funcionalidade.</span>';
    }
  }

  function bindEditor() {
    root.querySelectorAll("[data-research-field]").forEach(function (field) {
      field.addEventListener("input", function () {
        var item = activeItem();
        if (!item) return;
        item[field.getAttribute("data-research-field")] = field.value;
        renderItemList();
        saveResearch(false);
      });
    });

    root.querySelectorAll("[data-research-media]").forEach(function (button) {
      button.addEventListener("click", function () {
        var item = activeItem();
        if (!item) return;
        item.media = button.getAttribute("data-research-media");
        loadEditor();
        saveResearch(false);
      });
    });

    root.querySelectorAll("[data-research-switch]").forEach(function (button) {
      button.addEventListener("click", function () {
        var property = button.getAttribute("data-research-switch");
        var nextValue = !button.classList.contains("is-on");
        button.classList.toggle("is-on", nextValue);
        button.setAttribute("aria-pressed", nextValue ? "true" : "false");
        if (property === "package" || property === "random") {
          activeItem()[property] = nextValue;
        } else {
          research.config[property] = nextValue;
        }
        saveResearch(false);
      });
    });

    root.querySelectorAll("[data-research-config]").forEach(function (field) {
      var key = field.getAttribute("data-research-config");
      if (Object.prototype.hasOwnProperty.call(research.config, key)) field.value = research.config[key];
      field.addEventListener("input", function () {
        research.config[key] = field.value;
        if (key === "scope") toggleEventSettings();
        saveResearch(false);
      });
    });
  }

  function toggleEventSettings() {
    root.querySelector("[data-research-event-settings]").classList.toggle("d-none", research.config.scope !== "event");
  }

  function syncConfigEditor() {
    root.querySelectorAll("[data-research-config]").forEach(function (field) {
      var key = field.getAttribute("data-research-config");
      if (Object.prototype.hasOwnProperty.call(research.config, key)) field.value = research.config[key];
    });
    ["globalRandom", "requireAccount"].forEach(function (key) {
      var button = root.querySelector('[data-research-switch="' + key + '"]');
      if (!button) return;
      button.classList.toggle("is-on", Boolean(research.config[key]));
      button.setAttribute("aria-pressed", research.config[key] ? "true" : "false");
    });
    toggleEventSettings();
  }

  function openAddDialog() {
    var dialog = root.querySelector("[data-research-add-dialog]");
    dialog.hidden = false;
    window.setTimeout(function () { root.querySelector("#researchNewFeatureName").focus(); }, 0);
  }

  function closeAddDialog() {
    root.querySelector("[data-research-add-dialog]").hidden = true;
    root.querySelector("#researchNewFeatureName").value = "";
  }

  function addFeature() {
    var input = root.querySelector("#researchNewFeatureName");
    var name = input.value.trim();
    if (!name) {
      input.focus();
      return;
    }
    var key = "feature_" + Date.now();
    research.items.push({
      key: key,
      area: "Experiência",
      name: name,
      icon: "fa-solid fa-star",
      title: "Título curto da funcionalidade.",
      explanation: "Descreva o que é a funcionalidade e como o atleta poderá utilizá-la.",
      solution: "Explique qual problema real ela resolve para quem corre.",
      media: "interface",
      visual: "generic",
      package: true,
      random: true
    });
    selectedKey = key;
    saveResearch(false);
    closeAddDialog();
    renderItemList();
    loadEditor();
    showToast("Funcionalidade adicionada ao rascunho.");
  }

  function duplicateFeature() {
    var source = activeItem();
    if (!source) return;
    var copy = clone(source);
    copy.key = "feature_" + Date.now();
    copy.name = source.name + " — cópia";
    research.items.push(copy);
    selectedKey = copy.key;
    saveResearch(false);
    renderItemList();
    loadEditor();
    showToast("Funcionalidade duplicada.");
  }

  function shuffle(items) {
    var result = items.slice();
    for (var index = result.length - 1; index > 0; index -= 1) {
      var target = Math.floor(Math.random() * (index + 1));
      var current = result[index];
      result[index] = result[target];
      result[target] = current;
    }
    return result;
  }

  function buildPreviewOrder() {
    var fixed = research.items.filter(function (item) { return !item.random; });
    var random = research.items.filter(function (item) { return item.random; });
    previewOrder = research.config.globalRandom === false ? research.items.slice() : fixed.concat(shuffle(random));
  }

  function openPreview() {
    buildPreviewOrder();
    previewIndex = 0;
    previewAnswers = {};
    previewPackage = {};
    previewPrice = { min: 20, max: 40 };
    previewMustHave = "";
    previewPackageInitialized = false;
    previewOverlay.hidden = false;
    document.body.style.overflow = "hidden";
    renderPreview();
  }

  function closePreview() {
    previewOverlay.hidden = true;
    document.body.style.overflow = "";
  }

  function visualMarkup(item) {
    var inner = "";
    if (item.visual === "alerts") {
      inner = '<span class="research-mock-label">Seus alertas</span><div class="research-mock-heading">Radar configurado</div>' +
        '<div class="research-mock-alert"><i class="fa-solid fa-bell"></i><div><strong>Inscrições abertas para 21 km</strong><span>Florianópolis · prova em 18 de outubro</span></div></div>' +
        '<div class="research-mock-alert"><i class="fa-solid fa-camera"></i><div><strong>Suas fotos foram publicadas</strong><span>Meia Maratona de Balneário Camboriú</span></div></div>' +
        '<div class="research-mock-alert"><i class="fa-solid fa-tag"></i><div><strong>Último dia com preço atual</strong><span>Valor muda amanhã às 23h59</span></div></div>';
    } else if (item.visual === "performance") {
      inner = '<span class="research-mock-label">Temporada 2026</span><div class="research-mock-heading">Sua evolução nos 10 km</div>' +
        '<div class="research-mock-grid"><div class="research-mock-card"><strong>4:52/km</strong><span>pace médio</span></div><div class="research-mock-card"><strong>+4,8%</strong><span>evolução</span></div><div class="research-mock-card"><strong>68%</strong><span>percentil</span></div></div>' +
        '<div class="research-mock-chart"><span style="height:35%"></span><span style="height:48%"></span><span style="height:43%"></span><span style="height:62%"></span><span style="height:74%"></span><span style="height:91%"></span></div>';
    } else if (item.visual === "platforms") {
      inner = '<span class="research-mock-label">Histórico conectado</span><div class="research-mock-heading">Suas plataformas</div><div class="research-mock-platforms">' +
        '<div class="research-mock-platform"><i class="fa-brands fa-strava"></i><span>Strava<br><small>Conectado</small></span></div>' +
        '<div class="research-mock-platform"><i class="fa-solid fa-clock"></i><span>Garmin<br><small>486 atividades</small></span></div>' +
        '<div class="research-mock-platform"><i class="fa-solid fa-stopwatch"></i><span>Coros<br><small>Disponível</small></span></div>' +
        '<div class="research-mock-platform"><i class="fa-solid fa-heart-pulse"></i><span>Polar<br><small>Disponível</small></span></div></div>' +
        '<div class="research-mock-alert"><i class="fa-solid fa-check"></i><div><strong>3.912 km identificados</strong><span>Seu histórico está pronto para análise.</span></div></div>';
    } else if (item.visual === "search") {
      inner = '<span class="research-mock-label">Busca com IA</span><div class="research-mock-heading">Qual prova você procura?</div>' +
        '<div class="research-mock-search"><i class="fa-solid fa-wand-magic-sparkles"></i><span>Meias maratonas planas em SC nos próximos 4 meses</span></div>' +
        '<div class="research-mock-alert"><i class="fa-solid fa-location-dot"></i><div><strong>3 provas combinam com sua busca</strong><span>Florianópolis, Itajaí e Balneário Camboriú</span></div></div>' +
        '<div class="research-mock-grid"><div class="research-mock-card"><strong>21 km</strong><span>distância</span></div><div class="research-mock-card"><strong>Plano</strong><span>percurso</span></div><div class="research-mock-card"><strong>Aberta</strong><span>inscrição</span></div></div>';
    } else if (item.visual === "comparison") {
      inner = '<span class="research-mock-label">Comparação contextual</span><div class="research-mock-heading">Você x atletas do mesmo nível</div>' +
        '<div class="research-mock-people"><div class="research-mock-person"><span class="research-mock-avatar"><i class="fa-solid fa-person-running"></i></span><span><strong>Você</strong><span>10 km · 48min20s · 6 provas</span></span><em>+4,8%</em></div>' +
        '<div class="research-mock-person"><span class="research-mock-avatar"><i class="fa-solid fa-user"></i></span><span><strong>Perfil semelhante</strong><span>10 km · 49min10s · 5 provas</span></span><em>+3,1%</em></div></div>' +
        '<div class="research-mock-alert"><i class="fa-solid fa-chart-simple"></i><div><strong>Você está à frente em regularidade</strong><span>Melhorou em quatro distâncias nos últimos 12 meses.</span></div></div>';
    } else if (item.visual === "people") {
      inner = '<span class="research-mock-label">Pessoas relacionadas</span><div class="research-mock-heading">18 conexões encontradas</div>' +
        '<div class="research-mock-people"><div class="research-mock-person"><span class="research-mock-avatar">AM</span><span><strong>Ana Martins</strong><span>Mesma prova · 3 contatos em comum</span></span><em>Seguir</em></div>' +
        '<div class="research-mock-person"><span class="research-mock-avatar">RC</span><span><strong>Rafael Costa</strong><span>Mesma cidade · 5 eventos em comum</span></span><em>Seguir</em></div>' +
        '<div class="research-mock-person"><span class="research-mock-avatar">LP</span><span><strong>Luiza Pereira</strong><span>Mesma assessoria · correu 21 km</span></span><em>Seguir</em></div></div>';
    } else {
      inner = '<span class="research-mock-label">Prévia da funcionalidade</span><div class="research-mock-heading">' + escapeHtml(item.name) + '</div>' +
        '<div class="research-mock-grid"><div class="research-mock-card"><strong>01</strong><span>benefício</span></div><div class="research-mock-card"><strong>02</strong><span>resultado</span></div><div class="research-mock-card"><strong>03</strong><span>evolução</span></div></div><div class="research-mock-chart"><span style="height:32%"></span><span style="height:48%"></span><span style="height:62%"></span><span style="height:80%"></span></div>';
    }

    if (item.media === "none") return "";
    return '<div class="research-survey-visual"><div class="research-survey-visual-browser"><span></span><span></span><span></span></div><div class="research-survey-visual-body">' + inner + '</div>' +
      (item.media === "video" ? '<div class="research-survey-video-overlay"><span><i class="fa-solid fa-play"></i></span></div>' : '') + '</div>';
  }

  function previewOptions(key, options) {
    return '<div class="research-survey-options">' + options.map(function (option) {
      return '<button type="button" class="research-survey-option' + (previewAnswers[key] === option.value ? ' is-selected' : '') + '" data-preview-answer="' + escapeHtml(key) + '" data-preview-value="' + escapeHtml(option.value) + '">' + escapeHtml(option.label) + '</button>';
    }).join("") + '</div>';
  }

  function renderPreview() {
    var total = previewOrder.length + 4;
    var progress = Math.round(((previewIndex + 1) / total) * 100);
    root.querySelector("[data-research-preview-progress]").style.width = progress + "%";
    root.querySelector("[data-research-preview-counter]").textContent = (previewIndex + 1) + " de " + total;

    var backButton = root.querySelector("[data-research-preview-back]");
    var nextButton = root.querySelector("[data-research-preview-next]");
    backButton.disabled = previewIndex === 0;
    nextButton.innerHTML = previewIndex === total - 1 ? 'Recomeçar preview<i class="fa-solid fa-rotate-right ms-2"></i>' : 'Continuar<i class="fa-solid fa-arrow-right ms-2"></i>';

    if (previewIndex === 0) {
      previewContent.innerHTML = '<span class="research-survey-kicker">Pesquisa com atletas</span><h2 class="research-survey-title">' + escapeHtml(research.config.publicTitle) + '.</h2>' +
        '<p class="research-survey-lead">Conheça novas funcionalidades, diga quais realmente usaria e monte uma assinatura que faria sentido para você.</p>' +
        '<div class="research-survey-free-note"><i class="fa-solid fa-circle-check"></i><span><strong>O essencial continua gratuito.</strong> Conta, perfil, calendário, resultados, recursos sociais, ficha médica e segurança não fazem parte da cobrança.</span></div>';
    } else if (previewIndex === 1) {
      previewContent.innerHTML = '<span class="research-survey-kicker">Para conhecer você</span><h2 class="research-survey-title">Como a corrida faz parte da sua vida hoje?</h2><p class="research-survey-lead">Seu nível ajuda a entender como as prioridades mudam conforme a experiência.</p>' +
        '<div class="research-survey-profile-grid">' + [
          ["iniciante", "Estou começando", "Corro há menos de um ano."],
          ["recreativo", "Corredor recreativo", "Corro por saúde e prazer."],
          ["dedicado", "Amador dedicado", "Treino com frequência e tenho metas."],
          ["competitivo", "Competitivo", "Busco performance, rankings ou pódios."]
        ].map(function (level) {
          return '<button type="button" class="research-survey-profile-option' + (previewAnswers.level === level[0] ? ' is-selected' : '') + '" data-preview-answer="level" data-preview-value="' + level[0] + '"><strong>' + level[1] + '</strong><span>' + level[2] + '</span></button>';
        }).join("") + '</div><div class="research-survey-question"><strong>Você já tem conta no Road Runners?</strong>' + previewOptions("account", [
          { value: "active", label: "Sim, uso com frequência" },
          { value: "occasional", label: "Sim, mas uso pouco" },
          { value: "none", label: "Ainda não tenho" }
        ]) + '</div>';
    } else if (previewIndex <= previewOrder.length + 1) {
      var item = previewOrder[previewIndex - 2];
      var media = visualMarkup(item);
      previewContent.innerHTML = '<div class="research-survey-feature-layout"><div><span class="research-survey-feature-name"><span class="research-survey-feature-icon"><i class="' + escapeHtml(item.icon) + '"></i></span>' + escapeHtml(item.name) + '</span>' +
        '<h2 class="research-survey-feature-title">' + escapeHtml(item.title) + '</h2><div class="research-survey-solution">' + escapeHtml(item.solution) + '</div></div>' + media + '</div>' +
        '<div class="research-survey-question"><strong>Depois de entender a proposta: você usaria “' + escapeHtml(item.name) + '”?</strong>' + previewOptions(item.key, [
          { value: "yes", label: "Sim, usaria" },
          { value: "maybe", label: "Talvez usaria" },
          { value: "no", label: "Não usaria" }
        ]) + '</div>';
    } else if (previewIndex === previewOrder.length + 2) {
      var packageItems = research.items.filter(function (item) { return item.package; });
      if (!previewPackageInitialized) {
        packageItems.forEach(function (item) {
          previewPackage[item.key] = previewAnswers[item.key] === "yes" || previewAnswers[item.key] === "maybe";
        });
        var firstSelected = packageItems.find(function (item) { return previewPackage[item.key]; });
        previewMustHave = firstSelected ? firstSelected.key : "";
        previewPackageInitialized = true;
      }
      previewContent.innerHTML = '<span class="research-survey-kicker">Sua assinatura ideal</span><h2 class="research-survey-title">Monte o pacote que você realmente assinaria.</h2><p class="research-survey-lead">Revise o pacote, ajuste a faixa de preço e marque o item sem o qual você não assinaria.</p><div class="research-survey-bundle-grid">' +
        packageItems.map(function (item) {
          var answer = previewAnswers[item.key];
          var answerLabel = answer === "yes" ? "Você usaria" : (answer === "maybe" ? "Você talvez usaria" : "Não selecionada antes");
          return '<button type="button" class="research-survey-bundle-option' + (previewPackage[item.key] ? ' is-selected' : '') + '" data-preview-package="' + escapeHtml(item.key) + '"><i class="fa-solid ' + (previewPackage[item.key] ? 'fa-square-check' : 'fa-square') + '"></i><span><strong>' + escapeHtml(item.name) + '</strong><small>' + answerLabel + '</small></span></button>';
        }).join("") + '</div><div class="research-survey-price"><div class="d-flex justify-content-between gap-3 mb-2"><strong>Quanto pagaria por mês?</strong><span class="research-survey-price-value" data-preview-price-value>R$ ' + previewPrice.min + ' a R$ ' + previewPrice.max + '</span></div><label class="small d-block mb-1" for="previewPriceMin">Valor mínimo justo</label><input id="previewPriceMin" type="range" min="10" max="200" step="5" value="' + previewPrice.min + '" data-preview-price="min"><label class="small d-block mt-2 mb-1" for="previewPriceMax">Máximo que realmente pagaria</label><input id="previewPriceMax" type="range" min="10" max="200" step="5" value="' + previewPrice.max + '" data-preview-price="max"></div><div class="research-survey-must-have"><label class="form-label" for="previewMustHave"><strong>Qual funcionalidade não pode ficar de fora?</strong></label><select id="previewMustHave" class="form-select" data-preview-must-have><option value="">Selecione a principal</option>' + packageItems.filter(function (item) { return previewPackage[item.key]; }).map(function (item) { return '<option value="' + escapeHtml(item.key) + '"' + (previewMustHave === item.key ? ' selected' : '') + '>' + escapeHtml(item.name) + '</option>'; }).join("") + '</select><div class="form-text">Se essa funcionalidade não entrar, a assinatura perde valor para você.</div></div>';
    } else {
      previewContent.innerHTML = '<div class="text-center py-5"><span class="research-survey-feature-icon mx-auto mb-3"><i class="fa-solid fa-check"></i></span><span class="research-survey-kicker">Preview concluído</span><h2 class="research-survey-title mx-auto">Obrigado por correr esse percurso com a gente.</h2><p class="research-survey-lead mx-auto">No modo de visualização, nenhuma resposta é registrada.</p></div>';
    }

    bindPreviewControls();
  }

  function bindPreviewControls() {
    previewContent.querySelectorAll("[data-preview-answer]").forEach(function (button) {
      button.addEventListener("click", function () {
        previewAnswers[button.getAttribute("data-preview-answer")] = button.getAttribute("data-preview-value");
        renderPreview();
      });
    });

    previewContent.querySelectorAll("[data-preview-package]").forEach(function (button) {
      button.addEventListener("click", function () {
        var key = button.getAttribute("data-preview-package");
        previewPackage[key] = !previewPackage[key];
        if (previewMustHave === key && !previewPackage[key]) previewMustHave = "";
        if (!previewMustHave) {
          var fallbackSelected = research.items.find(function (item) { return item.package && previewPackage[item.key]; });
          previewMustHave = fallbackSelected ? fallbackSelected.key : "";
        }
        renderPreview();
      });
    });

    var mustHaveSelect = previewContent.querySelector("[data-preview-must-have]");
    if (mustHaveSelect) {
      mustHaveSelect.addEventListener("change", function () {
        previewMustHave = mustHaveSelect.value;
      });
    }

    var minInput = previewContent.querySelector('[data-preview-price="min"]');
    var maxInput = previewContent.querySelector('[data-preview-price="max"]');
    if (minInput && maxInput) {
      function updatePrice() {
        var min = Number(minInput.value);
        var max = Number(maxInput.value);
        if (min > max) {
          if (this === minInput) maxInput.value = min;
          else minInput.value = max;
        }
        previewPrice.min = Number(minInput.value);
        previewPrice.max = Number(maxInput.value);
        previewContent.querySelector("[data-preview-price-value]").textContent = "R$ " + minInput.value + " a R$ " + maxInput.value;
      }
      minInput.addEventListener("input", updatePrice);
      maxInput.addEventListener("input", updatePrice);
    }
  }

  root.querySelectorAll("[data-research-tab]").forEach(function (button) {
    button.addEventListener("click", function () {
      var target = button.getAttribute("data-research-tab");
      root.querySelectorAll("[data-research-tab]").forEach(function (tab) { tab.classList.toggle("active", tab === button); });
      root.querySelectorAll("[data-research-view]").forEach(function (view) { view.classList.toggle("d-none", view.getAttribute("data-research-view") !== target); });
    });
  });

  root.querySelector("[data-research-save]").addEventListener("click", function () { saveResearch(true); });
  root.querySelector("[data-research-reset]").addEventListener("click", function () {
    if (!window.confirm("Restaurar o conteúdo original da demonstração?")) return;
    research = clone(defaultResearch);
    selectedKey = research.items[0].key;
    saveResearch(false);
    renderItemList();
    loadEditor();
    syncConfigEditor();
    showToast("Demonstração restaurada.");
  });
  root.querySelector("[data-research-add-block]").addEventListener("click", openAddDialog);
  root.querySelectorAll("[data-research-add-close]").forEach(function (button) { button.addEventListener("click", closeAddDialog); });
  root.querySelector("[data-research-add-confirm]").addEventListener("click", addFeature);
  root.querySelector("[data-research-duplicate]").addEventListener("click", duplicateFeature);
  root.querySelector("[data-research-preview-open]").addEventListener("click", openPreview);
  root.querySelector("[data-research-preview-close]").addEventListener("click", closePreview);
  root.querySelector("[data-research-shuffle]").addEventListener("click", function () {
    buildPreviewOrder();
    previewIndex = Math.min(2, previewOrder.length + 1);
    renderPreview();
    showToast("Nova ordem de funcionalidades simulada.");
  });
  root.querySelectorAll("[data-research-device]").forEach(function (button) {
    button.addEventListener("click", function () {
      var mobile = button.getAttribute("data-research-device") === "mobile";
      previewFrame.classList.toggle("is-mobile", mobile);
      root.querySelectorAll("[data-research-device]").forEach(function (deviceButton) {
        var active = deviceButton === button;
        deviceButton.classList.toggle("btn-warning", active);
        deviceButton.classList.toggle("btn-outline-light", !active);
      });
    });
  });
  root.querySelector("[data-research-preview-back]").addEventListener("click", function () {
    if (previewIndex > 0) previewIndex -= 1;
    renderPreview();
  });
  root.querySelector("[data-research-preview-next]").addEventListener("click", function () {
    var total = previewOrder.length + 4;
    previewIndex = previewIndex >= total - 1 ? 0 : previewIndex + 1;
    renderPreview();
  });

  renderItemList();
  loadEditor();
  bindEditor();
  syncConfigEditor();
})();
