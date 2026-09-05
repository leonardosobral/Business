(function () {
  "use strict";

  var root = document.getElementById("trelloKanban");
  if (!root) return;

  var apiUrl = root.getAttribute("data-api-url");
  var csrfToken = root.getAttribute("data-csrf-token");
  var schemaReady = root.getAttribute("data-schema-ready") === "true";
  var configured = root.getAttribute("data-configured") === "true";
  var boardSelect = root.querySelector("[data-kanban-board-select]");
  var boardElement = root.querySelector("[data-kanban-board]");
  var statusElement = root.querySelector("[data-kanban-status]");
  var toastElement = root.querySelector("[data-kanban-toast]");
  var cardDialog = root.querySelector("[data-kanban-card-dialog]");
  var settingsDialog = root.querySelector("[data-kanban-settings-dialog]");
  var archivedDialog = root.querySelector("[data-kanban-archived-dialog]");
  var state = {
    boards: [], board: null, selectedCard: null, cardDetails: null,
    activeTab: "details", detailSequence: 0, draggedCardId: "", busy: false
  };

  function field(object, key, fallback) {
    if (!object || typeof object !== "object") return fallback;
    if (Object.prototype.hasOwnProperty.call(object, key)) return object[key];
    var match = Object.keys(object).find(function (candidate) { return candidate.toLowerCase() === key.toLowerCase(); });
    return match == null ? fallback : object[match];
  }

  function asArray(value) { return Array.isArray(value) ? value : []; }

  function create(tag, className, text) {
    var element = document.createElement(tag);
    if (className) element.className = className;
    if (text != null) element.textContent = String(text);
    return element;
  }

  function button(className, text, handler, icon) {
    var element = create("button", className);
    element.type = "button";
    if (icon) element.appendChild(create("i", "fa-solid " + icon + " me-1"));
    if (text) element.appendChild(document.createTextNode(text));
    if (handler) element.addEventListener("click", handler);
    return element;
  }

  function setStatus(message, busy) {
    statusElement.textContent = message || "";
    statusElement.classList.toggle("d-none", !message);
    boardElement.setAttribute("aria-busy", busy ? "true" : "false");
  }

  function toast(message, kind) {
    toastElement.textContent = message || "";
    toastElement.className = "trello-kanban-toast is-visible " + (kind === "error" ? "is-error" : "is-success");
    window.clearTimeout(toastElement._hideTimer);
    toastElement._hideTimer = window.setTimeout(function () { toastElement.classList.remove("is-visible"); }, 4600);
  }

  function request(action, options) {
    options = options || {};
    var method = options.method || "GET";
    var url = new URL(apiUrl, window.location.origin);
    url.searchParams.set("action", action);
    var fetchOptions = {
      method: method, credentials: "same-origin", cache: "no-store",
      headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
    };
    if (method === "GET") {
      Object.keys(options.data || {}).forEach(function (key) { url.searchParams.set(key, options.data[key]); });
    } else {
      var body = new FormData();
      body.append("csrf_token", csrfToken);
      Object.keys(options.data || {}).forEach(function (key) { body.append(key, options.data[key] == null ? "" : options.data[key]); });
      fetchOptions.body = body;
    }
    return fetch(url.toString(), fetchOptions).then(function (response) {
      return response.text().then(function (text) {
        var payload;
        try { payload = JSON.parse(text); } catch (error) { payload = { success: false, message: "O servidor retornou uma resposta inválida." }; }
        if (!response.ok || !field(payload, "success", false)) {
          var requestError = new Error(field(payload, "message", "Não foi possível concluir a operação."));
          requestError.status = response.status;
          throw requestError;
        }
        return payload;
      });
    });
  }

  function withBusy(work) {
    if (state.busy) return Promise.reject(new Error("Aguarde a operação em andamento."));
    state.busy = true;
    root.classList.add("is-busy");
    return Promise.resolve().then(work).finally(function () { state.busy = false; root.classList.remove("is-busy"); });
  }

  function normalizeBoardSummary(board) {
    return {
      id: String(field(board, "id", "")), mappingId: Number(field(board, "mappingId", 0)),
      department: String(field(board, "department", "")), name: String(field(board, "name", "")),
      url: String(field(board, "url", "")), order: Number(field(board, "order", 100))
    };
  }

  function normalizeList(list) {
    return { id: String(field(list, "id", "")), name: String(field(list, "name", "Lista")), pos: Number(field(list, "pos", 0)), closed: Boolean(field(list, "closed", false)) };
  }

  function normalizeMember(member) {
    return {
      id: String(field(member, "id", "")),
      fullName: String(field(member, "fullName", field(member, "username", "Pessoa"))),
      username: String(field(member, "username", "")), avatarUrl: String(field(member, "avatarUrl", ""))
    };
  }

  function normalizeLabel(label) {
    return { id: String(field(label, "id", "")), name: String(field(label, "name", "")), color: String(field(label, "color", "gray")) };
  }

  function normalizeCoordinates(value) {
    if (!value) return { latitude: "", longitude: "" };
    if (typeof value === "object") return { latitude: String(field(value, "latitude", "")), longitude: String(field(value, "longitude", "")) };
    var parts = String(value).split(",");
    return { latitude: parts[0] || "", longitude: parts[1] || "" };
  }

  function normalizeCard(card) {
    var labels = asArray(field(card, "labels", [])).map(normalizeLabel);
    var rawLabelIds = asArray(field(card, "idLabels", [])).map(function (item) { return typeof item === "object" ? String(field(item, "id", "")) : String(item); });
    var coordinates = normalizeCoordinates(field(card, "coordinates", null));
    var cover = field(card, "cover", {}) || {};
    return {
      id: String(field(card, "id", "")), name: String(field(card, "name", "Sem título")), desc: String(field(card, "desc", "")),
      idList: String(field(card, "idList", "")), idMembers: asArray(field(card, "idMembers", [])).map(String),
      idLabels: rawLabelIds.length ? rawLabelIds : labels.map(function (label) { return label.id; }).filter(Boolean), labels: labels,
      start: field(card, "start", null), due: field(card, "due", null), dueReminder: field(card, "dueReminder", null),
      dueComplete: Boolean(field(card, "dueComplete", false)), pos: Number(field(card, "pos", 0)),
      url: String(field(card, "url", field(card, "shortUrl", ""))), badges: field(card, "badges", {}) || {},
      dateLastActivity: field(card, "dateLastActivity", null), closed: Boolean(field(card, "closed", false)),
      subscribed: Boolean(field(card, "subscribed", false)), address: String(field(card, "address", "") || ""),
      locationName: String(field(card, "locationName", "") || ""), latitude: coordinates.latitude, longitude: coordinates.longitude,
      idAttachmentCover: String(field(card, "idAttachmentCover", "") || ""), coverColor: String(field(cover, "color", "") || "")
    };
  }

  function normalizeBoard(board) {
    return {
      id: String(field(board, "id", "")), department: String(field(board, "department", "")), name: String(field(board, "name", "")), url: String(field(board, "url", "")),
      lists: asArray(field(board, "lists", [])).map(normalizeList).filter(function (list) { return !list.closed; }).sort(function (a, b) { return a.pos - b.pos; }),
      cards: asArray(field(board, "cards", [])).map(normalizeCard).sort(function (a, b) { return a.pos - b.pos; }),
      members: asArray(field(board, "members", [])).map(normalizeMember), labels: asArray(field(board, "labels", [])).map(normalizeLabel)
    };
  }

  function selectedBoardId() { return boardSelect.value || (state.board ? state.board.id : ""); }

  function renderBoardSelector(activeId) {
    boardSelect.replaceChildren();
    if (!state.boards.length) {
      var empty = create("option", "", "Nenhum quadro configurado"); empty.value = ""; boardSelect.appendChild(empty); boardSelect.disabled = true; return;
    }
    boardSelect.disabled = false;
    state.boards.forEach(function (board) {
      var option = create("option", "", board.department + (board.name ? " · " + board.name : ""));
      option.value = board.id; option.selected = board.id === activeId; boardSelect.appendChild(option);
    });
  }

  function renderEmpty(title, message, icon) {
    boardElement.replaceChildren();
    var empty = create("section", "trello-kanban-empty");
    empty.appendChild(create("i", "fa-solid " + (icon || "fa-table-columns")));
    empty.appendChild(create("h2", "h5", title)); empty.appendChild(create("p", "text-muted mb-0", message)); boardElement.appendChild(empty);
  }

  function labelClass(label) {
    var color = String(field(label, "color", "gray")).toLowerCase();
    return ["green", "yellow", "orange", "red", "purple", "blue", "sky", "lime", "pink", "black"].indexOf(color) >= 0 ? " is-" + color : " is-gray";
  }

  function memberById(id) { return state.board && state.board.members.find(function (member) { return member.id === id; }); }

  function memberAvatar(member) {
    var wrapper = create("span", "trello-kanban-avatar");
    var url = member && member.avatarUrl ? member.avatarUrl + "/30.png" : "";
    if (/^https:\/\//i.test(url)) {
      var image = document.createElement("img"); image.src = url; image.alt = member.fullName; image.loading = "lazy"; image.referrerPolicy = "no-referrer"; wrapper.appendChild(image);
    } else {
      wrapper.textContent = (member && member.fullName ? member.fullName : "?").split(/\s+/).slice(0, 2).map(function (part) { return part.charAt(0); }).join("").toUpperCase() || "?";
    }
    wrapper.title = member ? member.fullName : "Responsável";
    return wrapper;
  }

  function formatDate(value, includeTime) {
    if (!value) return "";
    var date = new Date(value); if (Number.isNaN(date.getTime())) return "";
    return new Intl.DateTimeFormat("pt-BR", includeTime === false ? { dateStyle: "short" } : { dateStyle: "short", timeStyle: "short" }).format(date);
  }

  function dueState(card) {
    if (!card.due) return "";
    if (card.dueComplete) return " is-complete";
    return new Date(card.due).getTime() < Date.now() ? " is-overdue" : "";
  }

  function renderCard(card) {
    var cardElement = create("article", "trello-kanban-card");
    cardElement.tabIndex = 0; cardElement.draggable = true; cardElement.dataset.cardId = card.id; cardElement.dataset.listId = card.idList;
    cardElement.setAttribute("role", "button"); cardElement.setAttribute("aria-label", "Abrir cartão " + card.name);
    if (card.coverColor) cardElement.classList.add("has-cover", "cover-" + card.coverColor);
    if (card.labels.length) {
      var labels = create("div", "trello-kanban-card-labels");
      card.labels.forEach(function (label) { var element = create("span", "trello-kanban-card-label" + labelClass(label), label.name || " "); element.title = label.name || label.color; labels.appendChild(element); });
      cardElement.appendChild(labels);
    }
    cardElement.appendChild(create("h3", "trello-kanban-card-title", card.name));
    var meta = create("div", "trello-kanban-card-meta");
    if (card.desc) { var descriptionBadge = create("span"); descriptionBadge.title = "Possui descrição"; descriptionBadge.appendChild(create("i", "fa-solid fa-align-left")); meta.appendChild(descriptionBadge); }
    var comments = Number(field(card.badges, "comments", 0));
    if (comments > 0) { var commentBadge = create("span"); commentBadge.appendChild(create("i", "fa-regular fa-comment")); commentBadge.appendChild(document.createTextNode(" " + comments)); meta.appendChild(commentBadge); }
    var checkItems = Number(field(card.badges, "checkItems", 0));
    if (checkItems > 0) { var checkBadge = create("span"); checkBadge.appendChild(create("i", "fa-solid fa-list-check")); checkBadge.appendChild(document.createTextNode(" " + Number(field(card.badges, "checkItemsChecked", 0)) + "/" + checkItems)); meta.appendChild(checkBadge); }
    var attachments = Number(field(card.badges, "attachments", 0));
    if (attachments > 0) { var attachmentBadge = create("span"); attachmentBadge.appendChild(create("i", "fa-solid fa-paperclip")); attachmentBadge.appendChild(document.createTextNode(" " + attachments)); meta.appendChild(attachmentBadge); }
    if (card.due) { var dueBadge = create("span", "trello-kanban-due" + dueState(card)); dueBadge.appendChild(create("i", "fa-regular fa-clock")); dueBadge.appendChild(document.createTextNode(" " + formatDate(card.due))); meta.appendChild(dueBadge); }
    if (card.idMembers.length) { var avatars = create("span", "trello-kanban-card-avatars"); card.idMembers.slice(0, 4).forEach(function (id) { avatars.appendChild(memberAvatar(memberById(id))); }); meta.appendChild(avatars); }
    if (meta.childNodes.length) cardElement.appendChild(meta);
    cardElement.addEventListener("click", function () { openCard(card); });
    cardElement.addEventListener("keydown", function (event) { if (event.key === "Enter" || event.key === " ") { event.preventDefault(); openCard(card); } });
    cardElement.addEventListener("dragstart", function (event) { state.draggedCardId = card.id; cardElement.classList.add("is-dragging"); event.dataTransfer.effectAllowed = "move"; event.dataTransfer.setData("text/plain", card.id); });
    cardElement.addEventListener("dragend", function () { state.draggedCardId = ""; cardElement.classList.remove("is-dragging"); root.querySelectorAll(".is-drop-target").forEach(function (element) { element.classList.remove("is-drop-target"); }); });
    cardElement.addEventListener("dragover", function (event) { if (state.draggedCardId && state.draggedCardId !== card.id) { event.preventDefault(); event.stopPropagation(); cardElement.classList.add("is-drop-target"); } });
    cardElement.addEventListener("dragleave", function () { cardElement.classList.remove("is-drop-target"); });
    cardElement.addEventListener("drop", function (event) { event.preventDefault(); event.stopPropagation(); cardElement.classList.remove("is-drop-target"); var cardId = state.draggedCardId || event.dataTransfer.getData("text/plain"); if (cardId && cardId !== card.id) moveCard(cardId, card.idList, card.pos); });
    return cardElement;
  }

  function listActionButton(icon, title, handler) {
    var element = button("btn btn-sm btn-link trello-kanban-list-action", "", handler);
    element.title = title; element.setAttribute("aria-label", title); element.replaceChildren(create("i", "fa-solid " + icon)); return element;
  }

  function renderList(list) {
    var listElement = create("section", "trello-kanban-list"); listElement.dataset.listId = list.id;
    var cards = state.board.cards.filter(function (card) { return card.idList === list.id; });
    var header = create("header", "trello-kanban-list-header"); var titleWrap = create("div", "trello-kanban-list-title");
    titleWrap.appendChild(create("h2", "h6 mb-0", list.name)); titleWrap.appendChild(create("span", "badge badge-secondary", cards.length)); header.appendChild(titleWrap);
    var actions = create("div", "trello-kanban-list-actions");
    actions.appendChild(listActionButton("fa-pen", "Renomear lista", function () { renameList(list); }));
    actions.appendChild(listActionButton("fa-box-archive", "Arquivar lista", function () { archiveList(list, cards.length); })); header.appendChild(actions); listElement.appendChild(header);
    var cardsElement = create("div", "trello-kanban-list-cards"); cardsElement.dataset.dropListId = list.id;
    cards.forEach(function (card) { cardsElement.appendChild(renderCard(card)); });
    if (!cards.length) cardsElement.appendChild(create("div", "trello-kanban-list-empty", "Solte um cartão aqui"));
    cardsElement.addEventListener("dragover", function (event) { event.preventDefault(); event.dataTransfer.dropEffect = "move"; cardsElement.classList.add("is-drop-target"); });
    cardsElement.addEventListener("dragleave", function (event) { if (!cardsElement.contains(event.relatedTarget)) cardsElement.classList.remove("is-drop-target"); });
    cardsElement.addEventListener("drop", function (event) { event.preventDefault(); cardsElement.classList.remove("is-drop-target"); var cardId = state.draggedCardId || event.dataTransfer.getData("text/plain"); if (cardId) moveCard(cardId, list.id, "bottom"); });
    listElement.appendChild(cardsElement);
    listElement.appendChild(button("btn btn-sm btn-link trello-kanban-add-card", "Adicionar cartão", function () { openCard(null, list.id); }, "fa-plus"));
    return listElement;
  }

  function renderBoard() {
    boardElement.replaceChildren();
    if (!state.board) return renderEmpty("Selecione um quadro", "Escolha um departamento para carregar seu Kanban.");
    if (!state.board.lists.length) return renderEmpty("Quadro sem listas", "Crie a primeira lista para começar a organizar as tarefas.", "fa-list");
    var shell = create("div", "trello-kanban-columns"); state.board.lists.forEach(function (list) { shell.appendChild(renderList(list)); }); boardElement.appendChild(shell);
  }

  function loadBoards(preferredId) {
    return request("list_boards").then(function (payload) {
      state.boards = asArray(field(payload, "boards", [])).map(normalizeBoardSummary);
      var storedId = window.sessionStorage.getItem("runnerhub:trello-kanban:board") || "";
      var activeId = preferredId || selectedBoardId() || storedId;
      if (!state.boards.some(function (board) { return board.id === activeId; })) activeId = state.boards.length ? state.boards[0].id : "";
      renderBoardSelector(activeId);
      if (activeId) return loadBoard(activeId);
      state.board = null; renderEmpty("Nenhum quadro autorizado", "Abra “Quadros” para vincular os boards de cada departamento.", "fa-link"); setStatus("", false);
    });
  }

  function loadBoard(boardId) {
    if (!boardId) return Promise.resolve();
    setStatus("Atualizando o quadro…", true);
    return request("board", { data: { boardId: boardId } }).then(function (payload) {
      state.board = normalizeBoard(field(payload, "board", {})); boardSelect.value = state.board.id;
      window.sessionStorage.setItem("runnerhub:trello-kanban:board", state.board.id); renderBoard();
      setStatus("Atualizado agora · " + state.board.cards.length + " cartões", false); return state.board;
    }).catch(function (error) { setStatus("Não foi possível carregar o quadro.", false); renderEmpty("Falha ao carregar", error.message, "fa-triangle-exclamation"); throw error; });
  }

  function toLocalInput(value) {
    if (!value) return "";
    var date = new Date(value); if (Number.isNaN(date.getTime())) return "";
    return new Date(date.getTime() - date.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
  }

  function renderMemberChoices(selectedIds) {
    var container = root.querySelector("[data-kanban-card-members]"); container.replaceChildren();
    if (!state.board.members.length) return container.appendChild(create("span", "text-muted small", "Nenhum membro disponível neste quadro."));
    state.board.members.forEach(function (member) {
      var label = create("label", "trello-kanban-member-choice"); var checkbox = document.createElement("input");
      checkbox.type = "checkbox"; checkbox.value = member.id; checkbox.checked = selectedIds.indexOf(member.id) >= 0; checkbox.setAttribute("data-kanban-member-id", "");
      label.appendChild(checkbox); label.appendChild(memberAvatar(member)); label.appendChild(create("span", "", member.fullName)); container.appendChild(label);
    });
  }

  function renderLabelChoices(selectedIds) {
    var container = root.querySelector("[data-kanban-card-labels]"); container.replaceChildren();
    if (!state.board.labels.length) return container.appendChild(create("span", "text-muted small", "Nenhuma etiqueta criada neste quadro."));
    state.board.labels.forEach(function (label) {
      var choice = create("label", "trello-kanban-label-choice" + labelClass(label)); var checkbox = document.createElement("input");
      checkbox.type = "checkbox"; checkbox.value = label.id; checkbox.checked = selectedIds.indexOf(label.id) >= 0; checkbox.setAttribute("data-kanban-label-id", "");
      choice.appendChild(checkbox); choice.appendChild(create("span", "", label.name || label.color)); container.appendChild(choice);
    });
  }

  function fillListSelect(select, activeId) {
    select.replaceChildren();
    state.board.lists.forEach(function (list) { var option = create("option", "", list.name); option.value = list.id; option.selected = list.id === activeId; select.appendChild(option); });
  }

  function renderTransferBoardChoices() {
    var select = root.querySelector("[data-kanban-transfer-board]"); select.replaceChildren();
    var preferred = state.boards.find(function (board) { return board.id !== state.board.id; });
    state.boards.forEach(function (board) {
      var option = create("option", "", board.department + (board.name ? " · " + board.name : ""));
      option.value = board.id; option.selected = preferred ? board.id === preferred.id : board.id === state.board.id; select.appendChild(option);
    });
    if (select.value) loadTransferLists(select.value);
  }

  function loadTransferLists(boardId) {
    var select = root.querySelector("[data-kanban-transfer-list]"); select.replaceChildren(create("option", "", "Carregando listas…")); select.disabled = true;
    var source = boardId === state.board.id
      ? Promise.resolve(state.board.lists)
      : request("board_lists", { data: { boardId: boardId } }).then(function (payload) { return asArray(field(payload, "lists", [])).map(normalizeList); });
    return source.then(function (lists) {
      if (root.querySelector("[data-kanban-transfer-board]").value !== boardId) return;
      select.replaceChildren(); lists.filter(function (list) { return !list.closed; }).sort(function (a, b) { return a.pos - b.pos; }).forEach(function (list) { var option = create("option", "", list.name); option.value = list.id; select.appendChild(option); });
      select.disabled = !lists.length;
      if (!lists.length) { var empty = create("option", "", "Nenhuma lista aberta"); empty.value = ""; select.appendChild(empty); }
    }).catch(function (error) { select.replaceChildren(create("option", "", "Falha ao carregar")); toast(error.message, "error"); });
  }

  function setCardForm(card, listId) {
    root.querySelector("[data-kanban-card-id]").value = card ? card.id : "";
    root.querySelector("[data-kanban-card-name]").value = card ? card.name : "";
    root.querySelector("[data-kanban-card-description]").value = card ? card.desc : "";
    root.querySelector("[data-kanban-card-start]").value = card ? toLocalInput(card.start) : "";
    root.querySelector("[data-kanban-card-due]").value = card ? toLocalInput(card.due) : "";
    root.querySelector("[data-kanban-card-due-complete]").checked = card ? card.dueComplete : false;
    root.querySelector("[data-kanban-card-subscribed]").checked = card ? card.subscribed : false;
    root.querySelector("[data-kanban-card-cover]").value = card && card.coverColor ? card.coverColor : (card && card.idAttachmentCover ? "attachment" : "none");
    root.querySelector("[data-kanban-card-location-name]").value = card ? card.locationName : "";
    root.querySelector("[data-kanban-card-address]").value = card ? card.address : "";
    root.querySelector("[data-kanban-card-latitude]").value = card ? card.latitude : "";
    root.querySelector("[data-kanban-card-longitude]").value = card ? card.longitude : "";
    fillListSelect(root.querySelector("[data-kanban-card-list]"), card ? card.idList : (listId || state.board.lists[0].id));
    fillListSelect(root.querySelector("[data-kanban-duplicate-list]"), card ? card.idList : (listId || state.board.lists[0].id));
    renderTransferBoardChoices();
    renderMemberChoices(card ? card.idMembers : []); renderLabelChoices(card ? card.idLabels : []);
  }

  function selectTab(name) {
    state.activeTab = name;
    root.querySelectorAll("[data-kanban-tab]").forEach(function (tab) { tab.classList.toggle("is-active", tab.getAttribute("data-kanban-tab") === name); });
    root.querySelectorAll("[data-kanban-panel]").forEach(function (panel) { panel.classList.toggle("d-none", panel.getAttribute("data-kanban-panel") !== name); });
  }

  function setExistingCardControls(existing) {
    var agendaLink = root.querySelector("[data-kanban-card-agenda]");
    agendaLink.classList.toggle("d-none", !existing);
    if (existing && state.selectedCard) agendaLink.href = "/administracao/agenda/?card_id=" + encodeURIComponent(state.selectedCard.id);
    else agendaLink.removeAttribute("href");
    root.querySelectorAll("[data-kanban-tab]").forEach(function (tab) { if (tab.getAttribute("data-kanban-tab") !== "details") tab.disabled = !existing; });
    root.querySelector("[data-kanban-label-create]").classList.toggle("d-none", !existing);
    var openLink = root.querySelector("[data-kanban-card-open]"); var safeUrl = existing && state.selectedCard ? state.selectedCard.url : "";
    openLink.classList.toggle("d-none", !/^https:\/\//i.test(safeUrl)); if (/^https:\/\//i.test(safeUrl)) openLink.href = safeUrl;
    root.querySelector("[data-kanban-card-save-hint]").textContent = existing ? "Os detalhes são aplicados pelo botão Salvar." : "Salve o cartão para liberar todas as opções.";
  }

  function resetDetailPanels() {
    state.cardDetails = null;
    ["checklists", "attachments", "activity", "custom-fields"].forEach(function (name) {
      var container = root.querySelector("[data-kanban-" + name + "]"); if (container) container.replaceChildren(create("div", "text-muted small", "Carregando…"));
    });
    root.querySelector("[data-kanban-comment-text]").value = "";
    root.querySelector("[data-kanban-attachment-url]").value = ""; root.querySelector("[data-kanban-attachment-name]").value = ""; root.querySelector("[data-kanban-attachment-file]").value = "";
  }

  function openCard(card, listId) {
    state.selectedCard = card; state.detailSequence += 1;
    root.querySelector("[data-kanban-card-dialog-title]").textContent = card ? card.name : "Novo cartão";
    setCardForm(card, listId); root.querySelector("[data-kanban-duplicate-name]").value = card ? "Cópia de " + card.name : "";
    resetDetailPanels(); setExistingCardControls(Boolean(card)); selectTab("details"); cardDialog.showModal();
    window.setTimeout(function () { root.querySelector("[data-kanban-card-name]").focus(); }, 20);
    if (card) loadCardDetails(card.id, state.detailSequence);
  }

  function closeDialog(dialog) { if (dialog && dialog.open) dialog.close(); }

  function selectedIds(selector) {
    return Array.prototype.slice.call(root.querySelectorAll(selector + ":checked")).map(function (checkbox) { return checkbox.value; }).join(",");
  }

  function datePayload(selector) {
    var value = root.querySelector(selector).value; return value ? new Date(value).toISOString() : "";
  }

  function saveCard() {
    var cardId = root.querySelector("[data-kanban-card-id]").value;
    var data = {
      board_id: state.board.id, card_id: cardId, list_id: root.querySelector("[data-kanban-card-list]").value,
      name: root.querySelector("[data-kanban-card-name]").value.trim(), desc: root.querySelector("[data-kanban-card-description]").value,
      start: datePayload("[data-kanban-card-start]"), due: datePayload("[data-kanban-card-due]"),
      due_complete: root.querySelector("[data-kanban-card-due-complete]").checked ? "true" : "false",
      subscribed: root.querySelector("[data-kanban-card-subscribed]").checked ? "true" : "false", cover_color: root.querySelector("[data-kanban-card-cover]").value,
      member_ids: selectedIds("[data-kanban-member-id]"), label_ids: selectedIds("[data-kanban-label-id]"),
      location_name: root.querySelector("[data-kanban-card-location-name]").value, address: root.querySelector("[data-kanban-card-address]").value,
      latitude: root.querySelector("[data-kanban-card-latitude]").value, longitude: root.querySelector("[data-kanban-card-longitude]").value
    };
    if (!data.name) { toast("Informe o título do cartão.", "error"); root.querySelector("[data-kanban-card-name]").focus(); return Promise.resolve(); }
    return withBusy(function () { return request(cardId ? "update_card" : "create_card", { method: "POST", data: data }); }).then(function (payload) {
      toast(field(payload, "message", "Cartão salvo."));
      if (!cardId) { closeDialog(cardDialog); return loadBoard(state.board.id); }
      return refreshSelectedCard();
    }).catch(function (error) { toast(error.message, "error"); });
  }

  function loadCardDetails(cardId, sequence) {
    var expected = sequence == null ? state.detailSequence : sequence;
    return request("card_details", { data: { boardId: state.board.id, cardId: cardId } }).then(function (payload) {
      if (!state.selectedCard || state.selectedCard.id !== cardId || expected !== state.detailSequence) return;
      var detailedCard = normalizeCard(field(payload, "card", {})); state.selectedCard = detailedCard;
      state.cardDetails = {
        attachments: asArray(field(payload, "attachments", [])), checklists: asArray(field(payload, "checklists", [])),
        actions: asArray(field(payload, "actions", [])), customFields: asArray(field(payload, "customFields", [])),
        customFieldItems: asArray(field(payload, "customFieldItems", [])), capabilities: field(payload, "capabilities", {}) || {}
      };
      root.querySelector("[data-kanban-card-dialog-title]").textContent = detailedCard.name; setCardForm(detailedCard, detailedCard.idList);
      root.querySelector("[data-kanban-duplicate-name]").value = "Cópia de " + detailedCard.name; setExistingCardControls(true);
      renderChecklists(); renderAttachments(); renderActivity(); renderCustomFields();
    }).catch(function (error) {
      ["checklists", "attachments", "activity", "custom-fields"].forEach(function (name) { var container = root.querySelector("[data-kanban-" + name + "]"); if (container) container.replaceChildren(create("div", "text-danger small", error.message)); });
    });
  }

  function refreshSelectedCard() {
    if (!state.selectedCard) return Promise.resolve();
    var cardId = state.selectedCard.id; var activeTab = state.activeTab;
    return loadBoard(state.board.id).then(function () {
      var boardCard = state.board.cards.find(function (card) { return card.id === cardId; }); if (boardCard) state.selectedCard = boardCard;
      state.detailSequence += 1; return loadCardDetails(cardId, state.detailSequence);
    }).then(function () { selectTab(activeTab); });
  }

  function cardMutation(action, data, successMessage, refresh) {
    if (!state.selectedCard) return Promise.resolve();
    data = data || {}; data.board_id = state.board.id; data.card_id = state.selectedCard.id;
    return withBusy(function () { return request(action, { method: "POST", data: data }); }).then(function (payload) {
      toast(field(payload, "message", successMessage)); return refresh === false ? payload : refreshSelectedCard().then(function () { return payload; });
    }).catch(function (error) { toast(error.message, "error"); throw error; });
  }

  function createLabel() {
    var name = root.querySelector("[data-kanban-label-name]").value.trim(); if (!name) return toast("Informe o nome da etiqueta.", "error");
    cardMutation("create_label", { name: name, color: root.querySelector("[data-kanban-label-color]").value }, "Etiqueta criada.").then(function () { root.querySelector("[data-kanban-label-name]").value = ""; }).catch(function () {});
  }

  function memberSelect(activeId) {
    var select = document.createElement("select"); select.className = "form-select form-select-sm";
    var empty = create("option", "", "Sem responsável"); empty.value = ""; select.appendChild(empty);
    state.board.members.forEach(function (member) { var option = create("option", "", member.fullName); option.value = member.id; option.selected = member.id === activeId; select.appendChild(option); });
    return select;
  }

  function reminderSelect(activeValue) {
    var select = document.createElement("select"); select.className = "form-select form-select-sm"; select.title = "Lembrete do item";
    [["-1", "Sem lembrete"], ["0", "No horário"], ["5", "5 min antes"], ["10", "10 min antes"], ["15", "15 min antes"], ["60", "1 h antes"], ["120", "2 h antes"], ["1440", "1 dia antes"], ["2880", "2 dias antes"]].forEach(function (entry) {
      var option = create("option", "", entry[1]); option.value = entry[0]; option.selected = entry[0] === String(activeValue == null ? "-1" : activeValue); select.appendChild(option);
    });
    return select;
  }

  function renderChecklists() {
    var container = root.querySelector("[data-kanban-checklists]"); container.replaceChildren(); var details = state.cardDetails;
    if (!details || !field(details.capabilities, "checklists", true)) return container.appendChild(create("div", "alert alert-secondary", "O Trello não disponibilizou os checklists deste cartão."));
    if (!details.checklists.length) return container.appendChild(create("div", "trello-kanban-panel-empty", "Nenhum checklist neste cartão."));
    details.checklists.forEach(function (rawChecklist) {
      var checklistId = String(field(rawChecklist, "id", "")); var checklistName = String(field(rawChecklist, "name", "Checklist"));
      var items = asArray(field(rawChecklist, "checkItems", [])); var completed = items.filter(function (item) { return String(field(item, "state", "")) === "complete"; }).length;
      var section = create("section", "trello-kanban-checklist"); var heading = create("div", "trello-kanban-checklist-heading");
      var headingText = create("div"); headingText.appendChild(create("strong", "", checklistName)); headingText.appendChild(create("span", "text-muted small ms-2", items.length ? completed + "/" + items.length : "vazio")); heading.appendChild(headingText);
      var headingActions = create("div", "d-flex gap-1");
      headingActions.appendChild(button("btn btn-sm btn-link", "Renomear", function () { var name = window.prompt("Nome do checklist:", checklistName); if (name && name.trim() && name.trim() !== checklistName) cardMutation("update_checklist", { checklist_id: checklistId, name: name.trim() }, "Checklist renomeado.").catch(function () {}); }));
      headingActions.appendChild(button("btn btn-sm btn-link text-danger", "Excluir", function () { if (window.confirm("Remover este checklist e todos os seus itens?")) cardMutation("delete_checklist", { checklist_id: checklistId }, "Checklist removido.").catch(function () {}); }));
      heading.appendChild(headingActions); section.appendChild(heading);
      if (items.length) { var progress = create("div", "progress trello-kanban-progress"); var bar = create("div", "progress-bar"); bar.style.width = String(Math.round((completed / items.length) * 100)) + "%"; progress.appendChild(bar); section.appendChild(progress); }
      var itemList = create("div", "trello-kanban-check-items");
      items.sort(function (a, b) { return Number(field(a, "pos", 0)) - Number(field(b, "pos", 0)); }).forEach(function (rawItem) {
        var itemId = String(field(rawItem, "id", "")); var row = create("div", "trello-kanban-check-item");
        var checkbox = document.createElement("input"); checkbox.type = "checkbox"; checkbox.className = "form-check-input"; checkbox.checked = String(field(rawItem, "state", "")) === "complete";
        var nameInput = document.createElement("input"); nameInput.className = "form-control form-control-sm"; nameInput.maxLength = 512; nameInput.value = String(field(rawItem, "name", ""));
        var dueInput = document.createElement("input"); dueInput.className = "form-control form-control-sm"; dueInput.type = "datetime-local"; dueInput.value = toLocalInput(field(rawItem, "due", null));
        var reminder = reminderSelect(field(rawItem, "dueReminder", -1));
        var assignee = memberSelect(String(field(rawItem, "idMember", "") || ""));
        function saveItem() { return cardMutation("update_check_item", { checklist_id: checklistId, check_item_id: itemId, name: nameInput.value.trim(), complete: checkbox.checked ? "true" : "false", due: dueInput.value ? new Date(dueInput.value).toISOString() : "", due_reminder: reminder.value, member_id: assignee.value }, "Item atualizado.").catch(function () {}); }
        checkbox.addEventListener("change", saveItem);
        row.appendChild(checkbox); row.appendChild(nameInput); row.appendChild(dueInput); row.appendChild(reminder); row.appendChild(assignee);
        row.appendChild(button("btn btn-sm btn-outline-light", "Salvar", saveItem));
        row.appendChild(button("btn btn-sm btn-outline-danger", "", function () { if (window.confirm("Remover este item?")) cardMutation("delete_check_item", { checklist_id: checklistId, check_item_id: itemId }, "Item removido.").catch(function () {}); }, "fa-trash"));
        itemList.appendChild(row);
      });
      section.appendChild(itemList);
      var addRow = create("div", "trello-kanban-check-item-add"); var addName = document.createElement("input"); addName.className = "form-control form-control-sm"; addName.maxLength = 512; addName.placeholder = "Novo item";
      var addDue = document.createElement("input"); addDue.className = "form-control form-control-sm"; addDue.type = "datetime-local"; var addReminder = reminderSelect(-1); var addMember = memberSelect("");
      addRow.appendChild(addName); addRow.appendChild(addDue); addRow.appendChild(addReminder); addRow.appendChild(addMember);
      addRow.appendChild(button("btn btn-sm btn-outline-warning", "Adicionar", function () { if (!addName.value.trim()) return toast("Informe o texto do item.", "error"); cardMutation("add_check_item", { checklist_id: checklistId, name: addName.value.trim(), due: addDue.value ? new Date(addDue.value).toISOString() : "", due_reminder: addReminder.value, member_id: addMember.value }, "Item adicionado.").catch(function () {}); }));
      section.appendChild(addRow); container.appendChild(section);
    });
  }

  function createChecklist() {
    if (!state.selectedCard) return;
    var name = window.prompt("Nome do novo checklist:", "Checklist"); if (name && name.trim()) cardMutation("create_checklist", { name: name.trim() }, "Checklist criado.").catch(function () {});
  }

  function attachmentPreview(rawAttachment) {
    var usable = asArray(field(rawAttachment, "previews", [])).filter(function (preview) { return /^https:\/\//i.test(String(field(preview, "url", ""))); });
    if (!usable.length) return null;
    usable.sort(function (a, b) { return Number(field(a, "width", 0)) - Number(field(b, "width", 0)); });
    return String(field(usable[Math.min(usable.length - 1, 2)], "url", ""));
  }

  function formatBytes(value) {
    var bytes = Number(value); if (!Number.isFinite(bytes) || bytes <= 0) return "";
    if (bytes < 1024) return bytes + " B"; if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB"; return (bytes / 1048576).toFixed(1) + " MB";
  }

  function renderAttachments() {
    var container = root.querySelector("[data-kanban-attachments]"); container.replaceChildren(); var details = state.cardDetails;
    if (!details || !field(details.capabilities, "attachments", true)) return container.appendChild(create("div", "alert alert-secondary", "O Trello não disponibilizou os anexos deste cartão."));
    if (!details.attachments.length) return container.appendChild(create("div", "trello-kanban-panel-empty", "Nenhum anexo neste cartão."));
    details.attachments.forEach(function (rawAttachment) {
      var id = String(field(rawAttachment, "id", "")); var name = String(field(rawAttachment, "name", "Anexo")); var url = String(field(rawAttachment, "url", ""));
      var row = create("article", "trello-kanban-attachment"); var previewUrl = attachmentPreview(rawAttachment);
      if (previewUrl) { var image = document.createElement("img"); image.src = previewUrl; image.alt = ""; image.loading = "lazy"; image.referrerPolicy = "no-referrer"; row.appendChild(image); }
      else row.appendChild(create("span", "trello-kanban-attachment-icon", "📎"));
      var info = create("div", "trello-kanban-attachment-info");
      if (/^https?:\/\//i.test(url)) { var link = create("a", "", name); link.href = url; link.target = "_blank"; link.rel = "noopener noreferrer"; info.appendChild(link); } else info.appendChild(create("strong", "", name));
      var meta = [String(field(rawAttachment, "mimeType", "") || ""), formatBytes(field(rawAttachment, "bytes", 0)), formatDate(field(rawAttachment, "date", null))].filter(Boolean).join(" · ");
      if (meta) info.appendChild(create("span", "text-muted small", meta)); row.appendChild(info);
      var actions = create("div", "trello-kanban-attachment-actions");
      if (state.selectedCard.idAttachmentCover === id) actions.appendChild(create("span", "badge bg-warning text-dark", "Capa"));
      else actions.appendChild(button("btn btn-sm btn-outline-light", "Usar como capa", function () { cardMutation("set_attachment_cover", { attachment_id: id }, "Capa atualizada.").catch(function () {}); }));
      actions.appendChild(button("btn btn-sm btn-outline-danger", "Remover", function () { if (window.confirm("Remover este anexo do cartão?")) cardMutation("delete_attachment", { attachment_id: id }, "Anexo removido.").catch(function () {}); }));
      row.appendChild(actions); container.appendChild(row);
    });
    if (state.selectedCard.idAttachmentCover) container.appendChild(button("btn btn-sm btn-link text-muted mt-2", "Remover capa de anexo", function () { cardMutation("set_attachment_cover", { attachment_id: "" }, "Capa removida.").catch(function () {}); }));
  }

  function addAttachmentUrl() {
    var url = root.querySelector("[data-kanban-attachment-url]").value.trim(); if (!/^https?:\/\/\S+$/i.test(url)) return toast("Informe uma URL HTTP ou HTTPS válida.", "error");
    cardMutation("add_attachment_url", { url: url, name: root.querySelector("[data-kanban-attachment-name]").value.trim(), set_cover: root.querySelector("[data-kanban-attachment-url-cover]").checked ? "true" : "false" }, "Anexo adicionado.").then(function () { root.querySelector("[data-kanban-attachment-url]").value = ""; root.querySelector("[data-kanban-attachment-name]").value = ""; }).catch(function () {});
  }

  function addAttachmentFile() {
    var input = root.querySelector("[data-kanban-attachment-file]"); var file = input.files && input.files[0];
    if (!file) return toast("Selecione um arquivo.", "error"); if (file.size > 10485760) return toast("O arquivo deve ter no máximo 10 MB.", "error");
    cardMutation("add_attachment_file", { attachment_file: file, set_cover: root.querySelector("[data-kanban-attachment-file-cover]").checked ? "true" : "false" }, "Arquivo anexado.").then(function () { input.value = ""; }).catch(function () {});
  }

  function normalizeAction(rawAction) {
    var creator = field(rawAction, "memberCreator", {}) || {};
    return { id: String(field(rawAction, "id", "")), type: String(field(rawAction, "type", "")), data: field(rawAction, "data", {}) || {}, date: field(rawAction, "date", null), author: String(field(creator, "fullName", field(creator, "username", "Trello"))) };
  }

  function actionDescription(action) {
    var data = action.data; var old = field(data, "old", {}) || {};
    if (action.type === "commentCard") return String(field(data, "text", ""));
    if (action.type === "createCard") return "criou o cartão";
    if (action.type === "copyCard") return "duplicou o cartão";
    if (action.type === "addAttachmentToCard") return "adicionou o anexo “" + String(field(field(data, "attachment", {}), "name", "anexo")) + "”";
    if (action.type === "deleteAttachmentFromCard") return "removeu um anexo";
    if (action.type === "addChecklistToCard") return "adicionou um checklist";
    if (action.type === "removeChecklistFromCard") return "removeu um checklist";
    if (action.type === "updateCheckItemStateOnCard") return "atualizou um item de checklist";
    if (action.type === "updateCard") {
      if (field(old, "idList", null) != null) return "moveu o cartão para outra lista";
      if (field(old, "closed", null) != null) return field(field(data, "card", {}), "closed", false) ? "arquivou o cartão" : "restaurou o cartão";
      if (field(old, "name", null) != null) return "alterou o título";
      if (field(old, "desc", null) != null) return "alterou a descrição";
      if (field(old, "due", null) != null) return "alterou o prazo";
      return "atualizou o cartão";
    }
    return "registrou “" + (action.type || "atividade") + "”";
  }

  function renderActivity() {
    var container = root.querySelector("[data-kanban-activity]"); container.replaceChildren(); var details = state.cardDetails;
    if (!details || !field(details.capabilities, "activity", true)) return container.appendChild(create("div", "alert alert-secondary", "O Trello não disponibilizou a atividade deste cartão."));
    if (!details.actions.length) return container.appendChild(create("div", "trello-kanban-panel-empty", "Nenhuma atividade encontrada."));
    details.actions.map(normalizeAction).forEach(function (action) {
      var item = create("article", action.type === "commentCard" ? "trello-kanban-comment" : "trello-kanban-activity-item"); var header = create("div", "trello-kanban-comment-header");
      header.appendChild(create("strong", "", action.author)); header.appendChild(create("time", "text-muted", formatDate(action.date))); item.appendChild(header); item.appendChild(create("p", "mb-0", actionDescription(action)));
      if (action.type === "commentCard") {
        var actions = create("div", "trello-kanban-comment-actions");
        actions.appendChild(button("btn btn-sm btn-link", "Editar", function () { var next = window.prompt("Editar comentário:", String(field(action.data, "text", ""))); if (next && next.trim()) cardMutation("update_comment", { action_id: action.id, text: next.trim() }, "Comentário atualizado.").catch(function () {}); }));
        actions.appendChild(button("btn btn-sm btn-link text-danger", "Excluir", function () { if (window.confirm("Excluir este comentário?")) cardMutation("delete_comment", { action_id: action.id }, "Comentário removido.").catch(function () {}); }));
        item.appendChild(actions);
      }
      container.appendChild(item);
    });
  }

  function addComment() {
    var input = root.querySelector("[data-kanban-comment-text]"); var text = input.value.trim(); if (!text) return toast("Escreva um comentário.", "error");
    cardMutation("add_comment", { text: text }, "Comentário publicado.").then(function () { input.value = ""; }).catch(function () {});
  }

  function customFieldValue(definition) {
    var id = String(field(definition, "id", ""));
    var item = state.cardDetails.customFieldItems.find(function (candidate) { return String(field(candidate, "idCustomField", "")) === id; });
    if (!item) return ""; if (field(item, "idValue", null)) return String(field(item, "idValue", ""));
    var value = field(item, "value", {}) || {};
    return String(field(value, "text", field(value, "number", field(value, "date", field(value, "checked", "")))) || "");
  }

  function renderCustomFields() {
    var container = root.querySelector("[data-kanban-custom-fields]"); container.replaceChildren(); var details = state.cardDetails;
    if (!details || !field(details.capabilities, "customFields", false)) return container.appendChild(create("div", "alert alert-secondary", "Campos Personalizados não estão habilitados ou não estão acessíveis neste quadro."));
    if (!details.customFields.length) return container.appendChild(create("div", "trello-kanban-panel-empty", "Nenhum campo personalizado neste quadro."));
    details.customFields.sort(function (a, b) { return Number(field(a, "pos", 0)) - Number(field(b, "pos", 0)); }).forEach(function (definition) {
      var id = String(field(definition, "id", "")); var type = String(field(definition, "type", "text")); var value = customFieldValue(definition); var row = create("div", "trello-kanban-custom-field");
      row.appendChild(create("label", "form-label", String(field(definition, "name", "Campo")))); var input;
      if (type === "checkbox") { input = document.createElement("input"); input.type = "checkbox"; input.className = "form-check-input trello-kanban-custom-checkbox"; input.checked = value === "true"; }
      else if (type === "list") { input = document.createElement("select"); input.className = "form-select"; var empty = create("option", "", "Sem valor"); empty.value = ""; input.appendChild(empty); asArray(field(definition, "options", [])).forEach(function (option) { var text = String(field(field(option, "value", {}), "text", "Opção")); var element = create("option", "", text); element.value = String(field(option, "id", "")); element.selected = element.value === value; input.appendChild(element); }); }
      else { input = document.createElement("input"); input.className = "form-control"; input.type = type === "number" ? "number" : (type === "date" ? "datetime-local" : "text"); input.value = type === "date" ? toLocalInput(value) : value; input.maxLength = 10000; }
      row.appendChild(input); var actions = create("div", "d-flex gap-2");
      actions.appendChild(button("btn btn-sm btn-outline-warning", "Salvar", function () { var raw = type === "checkbox" ? (input.checked ? "true" : "false") : input.value; var shouldClear = type !== "checkbox" && !raw; if (type === "date" && raw) raw = new Date(raw).toISOString(); cardMutation("update_custom_field", { custom_field_id: id, value: raw, clear: shouldClear ? "true" : "false" }, shouldClear ? "Campo limpo." : "Campo atualizado.").catch(function () {}); }));
      actions.appendChild(button("btn btn-sm btn-link text-muted", "Limpar", function () { cardMutation("update_custom_field", { custom_field_id: id, value: "", clear: "true" }, "Campo limpo.").catch(function () {}); }));
      row.appendChild(actions); container.appendChild(row);
    });
  }

  function duplicateCard() {
    var name = root.querySelector("[data-kanban-duplicate-name]").value.trim(); if (!name) return toast("Informe o título da cópia.", "error");
    cardMutation("duplicate_card", { name: name, list_id: root.querySelector("[data-kanban-duplicate-list]").value }, "Cartão duplicado.", false).then(function () { closeDialog(cardDialog); return loadBoard(state.board.id); }).catch(function () {});
  }

  function transferCard() {
    var targetBoardId = root.querySelector("[data-kanban-transfer-board]").value;
    var targetListId = root.querySelector("[data-kanban-transfer-list]").value;
    if (!targetBoardId || !targetListId) return toast("Selecione o departamento e a lista de destino.", "error");
    var board = state.boards.find(function (candidate) { return candidate.id === targetBoardId; });
    if (!window.confirm("Mover este cartão para “" + (board ? board.department : "outro departamento") + "”?")) return;
    cardMutation("transfer_card", { target_board_id: targetBoardId, target_list_id: targetListId }, "Cartão movido.", false).then(function () { closeDialog(cardDialog); return loadBoard(state.board.id); }).catch(function () {});
  }

  function archiveCard() {
    if (!state.selectedCard || !window.confirm("Arquivar este cartão? Você poderá restaurá-lo em “Arquivados”.")) return;
    cardMutation("archive_card", { archived: "true" }, "Cartão arquivado.", false).then(function () { closeDialog(cardDialog); return loadBoard(state.board.id); }).catch(function () {});
  }

  function deleteCard(card) {
    var confirmation = window.prompt("Esta ação é permanente. Digite EXCLUIR para apagar “" + card.name + "”.", ""); if (confirmation !== "EXCLUIR") return;
    var original = state.selectedCard; state.selectedCard = card;
    cardMutation("delete_card", { confirmation: confirmation }, "Cartão excluído.", false).then(function () { closeDialog(cardDialog); closeDialog(archivedDialog); return loadBoard(state.board.id); }).catch(function () { state.selectedCard = original; });
  }

  function moveCard(cardId, listId, position) {
    var card = state.board.cards.find(function (item) { return item.id === cardId; }); if (!card) return;
    position = position == null ? "bottom" : position;
    if (card.idList === listId && Number(position) === card.pos) return;
    var previousList = card.idList; var previousPos = card.pos; card.idList = listId;
    if (position !== "bottom" && position !== "top") card.pos = Number(position) - 0.5;
    state.board.cards.sort(function (a, b) { return a.pos - b.pos; }); renderBoard();
    withBusy(function () { return request("move_card", { method: "POST", data: { board_id: state.board.id, card_id: cardId, list_id: listId, position: String(position) } }); }).then(function () { toast("Cartão movido."); return loadBoard(state.board.id); }).catch(function (error) { card.idList = previousList; card.pos = previousPos; state.board.cards.sort(function (a, b) { return a.pos - b.pos; }); renderBoard(); toast(error.message, "error"); });
  }

  function createList() {
    if (!state.board) return toast("Selecione um quadro primeiro.", "error"); var name = window.prompt("Nome da nova lista:", ""); if (!name || !name.trim()) return;
    withBusy(function () { return request("create_list", { method: "POST", data: { board_id: state.board.id, name: name.trim() } }); }).then(function (payload) { toast(field(payload, "message", "Lista criada.")); return loadBoard(state.board.id); }).catch(function (error) { toast(error.message, "error"); });
  }

  function renameList(list) {
    var name = window.prompt("Novo nome da lista:", list.name); if (!name || !name.trim() || name.trim() === list.name) return;
    withBusy(function () { return request("update_list", { method: "POST", data: { board_id: state.board.id, list_id: list.id, name: name.trim() } }); }).then(function (payload) { toast(field(payload, "message", "Lista renomeada.")); return loadBoard(state.board.id); }).catch(function (error) { toast(error.message, "error"); });
  }

  function archiveList(list, cardCount) {
    var warning = cardCount ? "Arquivar a lista “" + list.name + "” e seus " + cardCount + " cartões no Trello?" : "Arquivar a lista “" + list.name + "” no Trello?"; if (!window.confirm(warning)) return;
    withBusy(function () { return request("archive_list", { method: "POST", data: { board_id: state.board.id, list_id: list.id } }); }).then(function (payload) { toast(field(payload, "message", "Lista arquivada.")); return loadBoard(state.board.id); }).catch(function (error) { toast(error.message, "error"); });
  }

  function loadArchivedCards() {
    if (!state.board) return toast("Selecione um quadro.", "error");
    var container = root.querySelector("[data-kanban-archived-list]"); container.replaceChildren(create("div", "text-muted", "Carregando cartões arquivados…")); archivedDialog.showModal();
    return request("archived_cards", { data: { boardId: state.board.id } }).then(function (payload) {
      var cards = asArray(field(payload, "cards", [])).map(normalizeCard); container.replaceChildren();
      if (!cards.length) return container.appendChild(create("div", "trello-kanban-panel-empty", "Nenhum cartão arquivado neste quadro."));
      cards.forEach(function (card) {
        var row = create("article", "trello-kanban-archived-card"); var info = create("div"); info.appendChild(create("strong", "", card.name)); info.appendChild(create("span", "text-muted small d-block", "Última atividade: " + (formatDate(card.dateLastActivity) || "não informada"))); row.appendChild(info);
        var actions = create("div", "d-flex gap-2 flex-wrap");
        actions.appendChild(button("btn btn-sm btn-outline-warning", "Restaurar", function () { var original = state.selectedCard; state.selectedCard = card; cardMutation("archive_card", { archived: "false" }, "Cartão restaurado.", false).then(function () { state.selectedCard = original; closeDialog(archivedDialog); return loadBoard(state.board.id); }).catch(function () { state.selectedCard = original; }); }));
        if (/^https:\/\//i.test(card.url)) { var link = create("a", "btn btn-sm btn-outline-light", "Trello"); link.href = card.url; link.target = "_blank"; link.rel = "noopener noreferrer"; actions.appendChild(link); }
        actions.appendChild(button("btn btn-sm btn-outline-danger", "Excluir", function () { deleteCard(card); })); row.appendChild(actions); container.appendChild(row);
      });
    }).catch(function (error) { container.replaceChildren(create("div", "alert alert-danger", error.message)); });
  }

  function settingsRow(board) {
    var row = create("section", "trello-kanban-settings-row"); var main = create("div", "trello-kanban-settings-main"); main.appendChild(create("strong", "", board.name || board.id)); main.appendChild(create("code", "", board.id));
    if (/^https:\/\//i.test(board.url)) { var link = create("a", "small", "Abrir no Trello"); link.href = board.url; link.target = "_blank"; link.rel = "noopener noreferrer"; main.appendChild(link); } row.appendChild(main);
    var department = document.createElement("input"); department.className = "form-control"; department.maxLength = 100; department.placeholder = "Departamento"; department.value = board.department || board.name || ""; department.setAttribute("aria-label", "Departamento de " + (board.name || board.id)); row.appendChild(department);
    var order = document.createElement("input"); order.className = "form-control trello-kanban-order"; order.type = "number"; order.min = "0"; order.max = "9999"; order.value = String(board.order == null ? 100 : board.order); order.setAttribute("aria-label", "Ordem do quadro"); row.appendChild(order);
    var actions = create("div", "trello-kanban-settings-actions");
    actions.appendChild(button(board.mapped ? "btn btn-sm btn-outline-warning" : "btn btn-sm btn-warning", board.mapped ? "Atualizar" : "Vincular", function () { if (department.value.trim().length < 2) return toast("Informe o departamento.", "error"); withBusy(function () { return request("save_board", { method: "POST", data: { board_id: board.id, department: department.value.trim(), order: order.value } }); }).then(function (payload) { toast(field(payload, "message", "Quadro vinculado.")); return loadBoards(board.id).then(loadSettings); }).catch(function (error) { toast(error.message, "error"); }); }));
    if (board.mapped) actions.appendChild(button("btn btn-sm btn-outline-danger", "Remover", function () { if (!window.confirm("Remover este quadro do painel? O quadro permanecerá no Trello.")) return; withBusy(function () { return request("remove_board", { method: "POST", data: { board_id: board.id } }); }).then(function (payload) { toast(field(payload, "message", "Vínculo removido.")); return loadBoards().then(loadSettings); }).catch(function (error) { toast(error.message, "error"); }); }));
    row.appendChild(actions); return row;
  }

  function loadSettings() {
    var container = root.querySelector("[data-kanban-settings-list]"); container.replaceChildren(create("div", "text-muted", "Consultando quadros acessíveis…"));
    return request("available_boards").then(function (payload) {
      var available = asArray(field(payload, "boards", [])).map(function (board) { var id = String(field(board, "id", "")); var local = state.boards.find(function (item) { return item.id === id; }); return { id: id, name: String(field(board, "name", local ? local.name : "")), url: String(field(board, "url", local ? local.url : "")), mapped: Boolean(field(board, "mapped", Boolean(local))), department: String(field(board, "department", local ? local.department : "")), order: local ? local.order : 100 }; });
      state.boards.forEach(function (local) { if (!available.some(function (board) { return board.id === local.id; })) available.unshift({ id: local.id, name: local.name, url: local.url, mapped: true, department: local.department, order: local.order }); });
      available.sort(function (a, b) { if (a.mapped !== b.mapped) return a.mapped ? -1 : 1; return (a.department || a.name).localeCompare(b.department || b.name, "pt-BR"); }); container.replaceChildren();
      if (!available.length) container.appendChild(create("div", "trello-kanban-empty", "A credencial não possui quadros abertos.")); else available.forEach(function (board) { container.appendChild(settingsRow(board)); });
    }).catch(function (error) { container.replaceChildren(create("div", "alert alert-danger mb-0", error.message)); });
  }

  boardSelect.addEventListener("change", function () { if (boardSelect.value) loadBoard(boardSelect.value).catch(function (error) { toast(error.message, "error"); }); });
  root.querySelector("[data-kanban-refresh]").addEventListener("click", function () { if (selectedBoardId()) loadBoard(selectedBoardId()).catch(function (error) { toast(error.message, "error"); }); });
  root.querySelector("[data-kanban-add-list]").addEventListener("click", createList);
  root.querySelector("[data-kanban-archived]").addEventListener("click", loadArchivedCards);
  root.querySelector("[data-kanban-settings]").addEventListener("click", function () { settingsDialog.showModal(); loadSettings(); });
  root.querySelector("[data-kanban-settings-close]").addEventListener("click", function () { closeDialog(settingsDialog); });
  root.querySelector("[data-kanban-archived-close]").addEventListener("click", function () { closeDialog(archivedDialog); });
  root.querySelector("[data-kanban-dialog-close]").addEventListener("click", function () { closeDialog(cardDialog); });
  root.querySelector("[data-kanban-card-form]").addEventListener("submit", function (event) { event.preventDefault(); saveCard(); });
  root.querySelectorAll("[data-kanban-tab]").forEach(function (tab) { tab.addEventListener("click", function () { if (!tab.disabled) selectTab(tab.getAttribute("data-kanban-tab")); }); });
  root.querySelector("[data-kanban-label-submit]").addEventListener("click", createLabel);
  root.querySelector("[data-kanban-checklist-create]").addEventListener("click", createChecklist);
  root.querySelector("[data-kanban-attachment-url-submit]").addEventListener("click", addAttachmentUrl);
  root.querySelector("[data-kanban-attachment-file-submit]").addEventListener("click", addAttachmentFile);
  root.querySelector("[data-kanban-comment-submit]").addEventListener("click", addComment);
  root.querySelector("[data-kanban-card-duplicate]").addEventListener("click", duplicateCard);
  root.querySelector("[data-kanban-transfer-board]").addEventListener("change", function () { loadTransferLists(this.value); });
  root.querySelector("[data-kanban-card-transfer]").addEventListener("click", transferCard);
  root.querySelector("[data-kanban-card-archive]").addEventListener("click", archiveCard);
  root.querySelector("[data-kanban-card-delete]").addEventListener("click", function () { if (state.selectedCard) deleteCard(state.selectedCard); });
  [cardDialog, settingsDialog, archivedDialog].forEach(function (dialog) { dialog.addEventListener("click", function (event) { if (event.target === dialog) closeDialog(dialog); }); });

  if (!schemaReady) {
    boardSelect.disabled = true; renderEmpty("Banco ainda não preparado", "Execute a migration do módulo Kanban para continuar.", "fa-database"); setStatus("", false);
  } else if (!configured) {
    boardSelect.disabled = true; renderEmpty("Integração não configurada", "Adicione a chave e o token do Trello ao ambiente do servidor.", "fa-key"); setStatus("", false);
  } else {
    loadBoards().catch(function (error) { setStatus("", false); renderEmpty("Falha ao iniciar", error.message, "fa-triangle-exclamation"); toast(error.message, "error"); });
  }
})();
