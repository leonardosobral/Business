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
  var state = {
    boards: [],
    board: null,
    selectedCard: null,
    draggedCardId: "",
    busy: false
  };

  function field(object, key, fallback) {
    if (!object || typeof object !== "object") return fallback;
    if (Object.prototype.hasOwnProperty.call(object, key)) return object[key];
    var match = Object.keys(object).find(function (candidate) {
      return candidate.toLowerCase() === key.toLowerCase();
    });
    return match == null ? fallback : object[match];
  }

  function asArray(value) {
    return Array.isArray(value) ? value : [];
  }

  function create(tag, className, text) {
    var element = document.createElement(tag);
    if (className) element.className = className;
    if (text != null) element.textContent = String(text);
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
    toastElement._hideTimer = window.setTimeout(function () {
      toastElement.classList.remove("is-visible");
    }, 4200);
  }

  function request(action, options) {
    options = options || {};
    var method = options.method || "GET";
    var url = new URL(apiUrl, window.location.origin);
    url.searchParams.set("action", action);
    var fetchOptions = {
      method: method,
      credentials: "same-origin",
      cache: "no-store",
      headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" }
    };

    if (method === "GET") {
      Object.keys(options.data || {}).forEach(function (key) {
        url.searchParams.set(key, options.data[key]);
      });
    } else {
      var body = new FormData();
      body.append("csrf_token", csrfToken);
      Object.keys(options.data || {}).forEach(function (key) {
        body.append(key, options.data[key] == null ? "" : options.data[key]);
      });
      fetchOptions.body = body;
    }

    return fetch(url.toString(), fetchOptions).then(function (response) {
      return response.text().then(function (text) {
        var payload;
        try {
          payload = JSON.parse(text);
        } catch (error) {
          payload = { success: false, message: "O servidor retornou uma resposta inválida." };
        }
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
    return Promise.resolve().then(work).finally(function () {
      state.busy = false;
      root.classList.remove("is-busy");
    });
  }

  function normalizeBoardSummary(board) {
    return {
      id: String(field(board, "id", "")),
      mappingId: Number(field(board, "mappingId", 0)),
      department: String(field(board, "department", "")),
      name: String(field(board, "name", "")),
      url: String(field(board, "url", "")),
      order: Number(field(board, "order", 100))
    };
  }

  function normalizeList(list) {
    return {
      id: String(field(list, "id", "")),
      name: String(field(list, "name", "Lista")),
      pos: Number(field(list, "pos", 0)),
      closed: Boolean(field(list, "closed", false))
    };
  }

  function normalizeMember(member) {
    return {
      id: String(field(member, "id", "")),
      fullName: String(field(member, "fullName", field(member, "username", "Pessoa"))),
      username: String(field(member, "username", "")),
      avatarUrl: String(field(member, "avatarUrl", ""))
    };
  }

  function normalizeCard(card) {
    return {
      id: String(field(card, "id", "")),
      name: String(field(card, "name", "Sem título")),
      desc: String(field(card, "desc", "")),
      idList: String(field(card, "idList", "")),
      idMembers: asArray(field(card, "idMembers", [])).map(String),
      labels: asArray(field(card, "labels", [])),
      due: field(card, "due", null),
      dueComplete: Boolean(field(card, "dueComplete", false)),
      pos: Number(field(card, "pos", 0)),
      url: String(field(card, "url", field(card, "shortUrl", ""))),
      badges: field(card, "badges", {}) || {},
      dateLastActivity: field(card, "dateLastActivity", null)
    };
  }

  function normalizeBoard(board) {
    return {
      id: String(field(board, "id", "")),
      department: String(field(board, "department", "")),
      name: String(field(board, "name", "")),
      url: String(field(board, "url", "")),
      lists: asArray(field(board, "lists", [])).map(normalizeList).filter(function (list) { return !list.closed; }).sort(function (a, b) { return a.pos - b.pos; }),
      cards: asArray(field(board, "cards", [])).map(normalizeCard).sort(function (a, b) { return a.pos - b.pos; }),
      members: asArray(field(board, "members", [])).map(normalizeMember)
    };
  }

  function selectedBoardId() {
    return boardSelect.value || (state.board ? state.board.id : "");
  }

  function renderBoardSelector(activeId) {
    boardSelect.replaceChildren();
    if (!state.boards.length) {
      var empty = create("option", "", "Nenhum quadro configurado");
      empty.value = "";
      boardSelect.appendChild(empty);
      boardSelect.disabled = true;
      return;
    }
    boardSelect.disabled = false;
    state.boards.forEach(function (board) {
      var option = create("option", "", board.department + (board.name ? " · " + board.name : ""));
      option.value = board.id;
      option.selected = board.id === activeId;
      boardSelect.appendChild(option);
    });
  }

  function renderEmpty(title, message, icon) {
    boardElement.replaceChildren();
    var empty = create("section", "trello-kanban-empty");
    empty.appendChild(create("i", "fa-solid " + (icon || "fa-table-columns")));
    empty.appendChild(create("h2", "h5", title));
    empty.appendChild(create("p", "text-muted mb-0", message));
    boardElement.appendChild(empty);
  }

  function labelClass(label) {
    var color = String(field(label, "color", "gray")).toLowerCase();
    var allowed = ["green", "yellow", "orange", "red", "purple", "blue", "sky", "lime", "pink", "black"];
    return allowed.indexOf(color) >= 0 ? " is-" + color : " is-gray";
  }

  function memberById(id) {
    return state.board && state.board.members.find(function (member) { return member.id === id; });
  }

  function memberAvatar(member) {
    var wrapper = create("span", "trello-kanban-avatar");
    var url = member && member.avatarUrl ? member.avatarUrl + "/30.png" : "";
    if (/^https:\/\//i.test(url)) {
      var image = document.createElement("img");
      image.src = url;
      image.alt = member.fullName;
      image.loading = "lazy";
      image.referrerPolicy = "no-referrer";
      wrapper.appendChild(image);
    } else {
      var initials = (member && member.fullName ? member.fullName : "?").split(/\s+/).slice(0, 2).map(function (part) { return part.charAt(0); }).join("").toUpperCase();
      wrapper.textContent = initials || "?";
    }
    wrapper.title = member ? member.fullName : "Responsável";
    return wrapper;
  }

  function formatDue(value) {
    if (!value) return "";
    var date = new Date(value);
    if (Number.isNaN(date.getTime())) return "";
    return new Intl.DateTimeFormat("pt-BR", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" }).format(date);
  }

  function dueState(card) {
    if (!card.due) return "";
    if (card.dueComplete) return " is-complete";
    return new Date(card.due).getTime() < Date.now() ? " is-overdue" : "";
  }

  function renderCard(card) {
    var cardElement = create("article", "trello-kanban-card");
    cardElement.tabIndex = 0;
    cardElement.draggable = true;
    cardElement.dataset.cardId = card.id;
    cardElement.dataset.listId = card.idList;
    cardElement.setAttribute("role", "button");
    cardElement.setAttribute("aria-label", "Abrir cartão " + card.name);

    if (card.labels.length) {
      var labels = create("div", "trello-kanban-card-labels");
      card.labels.forEach(function (label) {
        var labelName = String(field(label, "name", ""));
        var labelElement = create("span", "trello-kanban-card-label" + labelClass(label), labelName || " ");
        labelElement.title = labelName || String(field(label, "color", "Etiqueta"));
        labels.appendChild(labelElement);
      });
      cardElement.appendChild(labels);
    }

    cardElement.appendChild(create("h3", "trello-kanban-card-title", card.name));
    var meta = create("div", "trello-kanban-card-meta");
    if (card.desc) {
      var descriptionBadge = create("span", "", "");
      descriptionBadge.title = "Possui descrição";
      descriptionBadge.appendChild(create("i", "fa-solid fa-align-left"));
      meta.appendChild(descriptionBadge);
    }
    var comments = Number(field(card.badges, "comments", 0));
    if (comments > 0) {
      var commentBadge = create("span", "");
      commentBadge.appendChild(create("i", "fa-regular fa-comment"));
      commentBadge.appendChild(document.createTextNode(" " + comments));
      meta.appendChild(commentBadge);
    }
    if (card.due) {
      var dueBadge = create("span", "trello-kanban-due" + dueState(card));
      dueBadge.appendChild(create("i", "fa-regular fa-clock"));
      dueBadge.appendChild(document.createTextNode(" " + formatDue(card.due)));
      meta.appendChild(dueBadge);
    }
    if (card.idMembers.length) {
      var avatars = create("span", "trello-kanban-card-avatars");
      card.idMembers.slice(0, 4).forEach(function (memberId) {
        avatars.appendChild(memberAvatar(memberById(memberId)));
      });
      meta.appendChild(avatars);
    }
    if (meta.childNodes.length) cardElement.appendChild(meta);

    cardElement.addEventListener("click", function () { openCard(card); });
    cardElement.addEventListener("keydown", function (event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        openCard(card);
      }
    });
    cardElement.addEventListener("dragstart", function (event) {
      state.draggedCardId = card.id;
      cardElement.classList.add("is-dragging");
      event.dataTransfer.effectAllowed = "move";
      event.dataTransfer.setData("text/plain", card.id);
    });
    cardElement.addEventListener("dragend", function () {
      state.draggedCardId = "";
      cardElement.classList.remove("is-dragging");
      root.querySelectorAll(".is-drop-target").forEach(function (element) { element.classList.remove("is-drop-target"); });
    });
    return cardElement;
  }

  function listActionButton(icon, title, handler) {
    var button = create("button", "btn btn-sm btn-link trello-kanban-list-action");
    button.type = "button";
    button.title = title;
    button.setAttribute("aria-label", title);
    button.appendChild(create("i", "fa-solid " + icon));
    button.addEventListener("click", handler);
    return button;
  }

  function renderList(list) {
    var listElement = create("section", "trello-kanban-list");
    listElement.dataset.listId = list.id;
    var cards = state.board.cards.filter(function (card) { return card.idList === list.id; });
    var header = create("header", "trello-kanban-list-header");
    var titleWrap = create("div", "trello-kanban-list-title");
    titleWrap.appendChild(create("h2", "h6 mb-0", list.name));
    titleWrap.appendChild(create("span", "badge badge-secondary", cards.length));
    header.appendChild(titleWrap);
    var actions = create("div", "trello-kanban-list-actions");
    actions.appendChild(listActionButton("fa-pen", "Renomear lista", function () { renameList(list); }));
    actions.appendChild(listActionButton("fa-box-archive", "Arquivar lista", function () { archiveList(list, cards.length); }));
    header.appendChild(actions);
    listElement.appendChild(header);

    var cardsElement = create("div", "trello-kanban-list-cards");
    cardsElement.dataset.dropListId = list.id;
    cards.forEach(function (card) { cardsElement.appendChild(renderCard(card)); });
    if (!cards.length) cardsElement.appendChild(create("div", "trello-kanban-list-empty", "Solte um cartão aqui"));
    cardsElement.addEventListener("dragover", function (event) {
      event.preventDefault();
      event.dataTransfer.dropEffect = "move";
      cardsElement.classList.add("is-drop-target");
    });
    cardsElement.addEventListener("dragleave", function (event) {
      if (!cardsElement.contains(event.relatedTarget)) cardsElement.classList.remove("is-drop-target");
    });
    cardsElement.addEventListener("drop", function (event) {
      event.preventDefault();
      cardsElement.classList.remove("is-drop-target");
      var cardId = state.draggedCardId || event.dataTransfer.getData("text/plain");
      if (cardId) moveCard(cardId, list.id);
    });
    listElement.appendChild(cardsElement);

    var addButton = create("button", "btn btn-sm btn-link trello-kanban-add-card");
    addButton.type = "button";
    addButton.appendChild(create("i", "fa-solid fa-plus me-2"));
    addButton.appendChild(document.createTextNode("Adicionar cartão"));
    addButton.addEventListener("click", function () { openCard(null, list.id); });
    listElement.appendChild(addButton);
    return listElement;
  }

  function renderBoard() {
    boardElement.replaceChildren();
    if (!state.board) {
      renderEmpty("Selecione um quadro", "Escolha um departamento para carregar seu Kanban.");
      return;
    }
    if (!state.board.lists.length) {
      renderEmpty("Quadro sem listas", "Crie a primeira lista para começar a organizar as tarefas.", "fa-list");
      return;
    }
    var shell = create("div", "trello-kanban-columns");
    state.board.lists.forEach(function (list) { shell.appendChild(renderList(list)); });
    boardElement.appendChild(shell);
  }

  function loadBoards(preferredId) {
    return request("list_boards").then(function (payload) {
      state.boards = asArray(field(payload, "boards", [])).map(normalizeBoardSummary);
      var storedId = window.sessionStorage.getItem("runnerhub:trello-kanban:board") || "";
      var activeId = preferredId || selectedBoardId() || storedId;
      if (!state.boards.some(function (board) { return board.id === activeId; })) {
        activeId = state.boards.length ? state.boards[0].id : "";
      }
      renderBoardSelector(activeId);
      if (activeId) return loadBoard(activeId);
      state.board = null;
      renderEmpty("Nenhum quadro autorizado", "Abra “Quadros” para vincular os boards de cada departamento.", "fa-link");
      setStatus("", false);
    });
  }

  function loadBoard(boardId) {
    if (!boardId) return Promise.resolve();
    setStatus("Atualizando o quadro…", true);
    return request("board", { data: { boardId: boardId } }).then(function (payload) {
      state.board = normalizeBoard(field(payload, "board", {}));
      boardSelect.value = state.board.id;
      window.sessionStorage.setItem("runnerhub:trello-kanban:board", state.board.id);
      renderBoard();
      setStatus("Atualizado agora · " + state.board.cards.length + " cartões", false);
    }).catch(function (error) {
      setStatus("Não foi possível carregar o quadro.", false);
      renderEmpty("Falha ao carregar", error.message, "fa-triangle-exclamation");
      throw error;
    });
  }

  function toLocalInput(value) {
    if (!value) return "";
    var date = new Date(value);
    if (Number.isNaN(date.getTime())) return "";
    var local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
    return local.toISOString().slice(0, 16);
  }

  function renderMemberChoices(selectedIds) {
    var container = root.querySelector("[data-kanban-card-members]");
    container.replaceChildren();
    if (!state.board.members.length) {
      container.appendChild(create("span", "text-muted small", "Nenhum membro disponível neste quadro."));
      return;
    }
    state.board.members.forEach(function (member) {
      var label = create("label", "trello-kanban-member-choice");
      var checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.value = member.id;
      checkbox.checked = selectedIds.indexOf(member.id) >= 0;
      checkbox.setAttribute("data-kanban-member-id", "");
      label.appendChild(checkbox);
      label.appendChild(memberAvatar(member));
      label.appendChild(create("span", "", member.fullName));
      container.appendChild(label);
    });
  }

  function renderListChoices(activeListId) {
    var select = root.querySelector("[data-kanban-card-list]");
    select.replaceChildren();
    state.board.lists.forEach(function (list) {
      var option = create("option", "", list.name);
      option.value = list.id;
      option.selected = list.id === activeListId;
      select.appendChild(option);
    });
  }

  function openCard(card, listId) {
    state.selectedCard = card;
    root.querySelector("[data-kanban-card-dialog-title]").textContent = card ? "Editar cartão" : "Novo cartão";
    root.querySelector("[data-kanban-card-id]").value = card ? card.id : "";
    root.querySelector("[data-kanban-card-name]").value = card ? card.name : "";
    root.querySelector("[data-kanban-card-description]").value = card ? card.desc : "";
    root.querySelector("[data-kanban-card-due]").value = card ? toLocalInput(card.due) : "";
    root.querySelector("[data-kanban-card-due-complete]").checked = card ? card.dueComplete : false;
    renderListChoices(card ? card.idList : (listId || state.board.lists[0].id));
    renderMemberChoices(card ? card.idMembers : []);

    var archiveButton = root.querySelector("[data-kanban-card-archive]");
    var openLink = root.querySelector("[data-kanban-card-open]");
    var commentsSection = root.querySelector("[data-kanban-comments-section]");
    archiveButton.classList.toggle("d-none", !card);
    openLink.classList.toggle("d-none", !card || !/^https:\/\//i.test(card.url));
    if (card && /^https:\/\//i.test(card.url)) openLink.href = card.url;
    commentsSection.classList.toggle("d-none", !card);
    root.querySelector("[data-kanban-comments]").replaceChildren(create("div", "text-muted small", "Carregando comentários…"));
    root.querySelector("[data-kanban-comment-text]").value = "";
    cardDialog.showModal();
    window.setTimeout(function () { root.querySelector("[data-kanban-card-name]").focus(); }, 20);
    if (card) loadComments(card.id);
  }

  function closeDialog(dialog) {
    if (dialog && dialog.open) dialog.close();
  }

  function selectedMemberIds() {
    return Array.prototype.slice.call(root.querySelectorAll("[data-kanban-member-id]:checked")).map(function (checkbox) { return checkbox.value; }).join(",");
  }

  function saveCard() {
    var cardId = root.querySelector("[data-kanban-card-id]").value;
    var dueInput = root.querySelector("[data-kanban-card-due]").value;
    var data = {
      board_id: state.board.id,
      card_id: cardId,
      list_id: root.querySelector("[data-kanban-card-list]").value,
      name: root.querySelector("[data-kanban-card-name]").value.trim(),
      desc: root.querySelector("[data-kanban-card-description]").value,
      due: dueInput ? new Date(dueInput).toISOString() : "",
      due_complete: root.querySelector("[data-kanban-card-due-complete]").checked ? "true" : "false",
      member_ids: selectedMemberIds()
    };
    if (!data.name) {
      toast("Informe o título do cartão.", "error");
      root.querySelector("[data-kanban-card-name]").focus();
      return Promise.resolve();
    }
    return withBusy(function () {
      return request(cardId ? "update_card" : "create_card", { method: "POST", data: data });
    }).then(function (payload) {
      closeDialog(cardDialog);
      toast(field(payload, "message", "Cartão salvo."));
      return loadBoard(state.board.id);
    }).catch(function (error) { toast(error.message, "error"); });
  }

  function archiveCard() {
    if (!state.selectedCard || !window.confirm("Arquivar este cartão no Trello?")) return;
    var cardId = state.selectedCard.id;
    withBusy(function () {
      return request("archive_card", { method: "POST", data: { board_id: state.board.id, card_id: cardId } });
    }).then(function (payload) {
      closeDialog(cardDialog);
      toast(field(payload, "message", "Cartão arquivado."));
      return loadBoard(state.board.id);
    }).catch(function (error) { toast(error.message, "error"); });
  }

  function moveCard(cardId, listId) {
    var card = state.board.cards.find(function (item) { return item.id === cardId; });
    if (!card || card.idList === listId) return;
    var previousList = card.idList;
    card.idList = listId;
    renderBoard();
    withBusy(function () {
      return request("move_card", { method: "POST", data: { board_id: state.board.id, card_id: cardId, list_id: listId, position: "bottom" } });
    }).then(function () {
      toast("Cartão movido.");
      return loadBoard(state.board.id);
    }).catch(function (error) {
      card.idList = previousList;
      renderBoard();
      toast(error.message, "error");
    });
  }

  function createList() {
    if (!state.board) return toast("Selecione um quadro primeiro.", "error");
    var name = window.prompt("Nome da nova lista:", "");
    if (!name || !name.trim()) return;
    withBusy(function () {
      return request("create_list", { method: "POST", data: { board_id: state.board.id, name: name.trim() } });
    }).then(function (payload) {
      toast(field(payload, "message", "Lista criada."));
      return loadBoard(state.board.id);
    }).catch(function (error) { toast(error.message, "error"); });
  }

  function renameList(list) {
    var name = window.prompt("Novo nome da lista:", list.name);
    if (!name || !name.trim() || name.trim() === list.name) return;
    withBusy(function () {
      return request("update_list", { method: "POST", data: { board_id: state.board.id, list_id: list.id, name: name.trim() } });
    }).then(function (payload) {
      toast(field(payload, "message", "Lista renomeada."));
      return loadBoard(state.board.id);
    }).catch(function (error) { toast(error.message, "error"); });
  }

  function archiveList(list, cardCount) {
    var warning = cardCount
      ? "Arquivar a lista “" + list.name + "” e seus " + cardCount + " cartões no Trello?"
      : "Arquivar a lista “" + list.name + "” no Trello?";
    if (!window.confirm(warning)) return;
    withBusy(function () {
      return request("archive_list", { method: "POST", data: { board_id: state.board.id, list_id: list.id } });
    }).then(function (payload) {
      toast(field(payload, "message", "Lista arquivada."));
      return loadBoard(state.board.id);
    }).catch(function (error) { toast(error.message, "error"); });
  }

  function normalizeComment(action) {
    var data = field(action, "data", {}) || {};
    var creator = field(action, "memberCreator", {}) || {};
    return {
      id: String(field(action, "id", "")),
      text: String(field(data, "text", "")),
      date: field(action, "date", null),
      author: String(field(creator, "fullName", field(creator, "username", "Trello")))
    };
  }

  function renderComments(comments) {
    var container = root.querySelector("[data-kanban-comments]");
    container.replaceChildren();
    if (!comments.length) {
      container.appendChild(create("div", "text-muted small", "Nenhum comentário ainda."));
      return;
    }
    comments.forEach(function (comment) {
      var item = create("article", "trello-kanban-comment");
      var header = create("div", "trello-kanban-comment-header");
      header.appendChild(create("strong", "", comment.author));
      header.appendChild(create("time", "text-muted", comment.date ? new Intl.DateTimeFormat("pt-BR", { dateStyle: "short", timeStyle: "short" }).format(new Date(comment.date)) : ""));
      item.appendChild(header);
      item.appendChild(create("p", "mb-0", comment.text));
      container.appendChild(item);
    });
  }

  function loadComments(cardId) {
    return request("card_comments", { data: { boardId: state.board.id, cardId: cardId } }).then(function (payload) {
      renderComments(asArray(field(payload, "comments", [])).map(normalizeComment));
    }).catch(function (error) {
      root.querySelector("[data-kanban-comments]").replaceChildren(create("div", "text-danger small", error.message));
    });
  }

  function addComment() {
    if (!state.selectedCard) return;
    var input = root.querySelector("[data-kanban-comment-text]");
    var text = input.value.trim();
    if (!text) return toast("Escreva um comentário.", "error");
    withBusy(function () {
      return request("add_comment", { method: "POST", data: { board_id: state.board.id, card_id: state.selectedCard.id, text: text } });
    }).then(function (payload) {
      input.value = "";
      toast(field(payload, "message", "Comentário publicado."));
      return Promise.all([loadComments(state.selectedCard.id), loadBoard(state.board.id)]);
    }).catch(function (error) { toast(error.message, "error"); });
  }

  function settingsRow(board) {
    var row = create("section", "trello-kanban-settings-row");
    var main = create("div", "trello-kanban-settings-main");
    main.appendChild(create("strong", "", board.name || board.id));
    main.appendChild(create("code", "", board.id));
    if (/^https:\/\//i.test(board.url)) {
      var link = create("a", "small", "Abrir no Trello");
      link.href = board.url;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      main.appendChild(link);
    }
    row.appendChild(main);

    var department = document.createElement("input");
    department.className = "form-control";
    department.maxLength = 100;
    department.placeholder = "Departamento";
    department.value = board.department || board.name || "";
    department.setAttribute("aria-label", "Departamento de " + (board.name || board.id));
    row.appendChild(department);

    var order = document.createElement("input");
    order.className = "form-control trello-kanban-order";
    order.type = "number";
    order.min = "0";
    order.max = "9999";
    order.value = String(board.order == null ? 100 : board.order);
    order.setAttribute("aria-label", "Ordem do quadro");
    row.appendChild(order);

    var actions = create("div", "trello-kanban-settings-actions");
    var save = create("button", board.mapped ? "btn btn-sm btn-outline-warning" : "btn btn-sm btn-warning", board.mapped ? "Atualizar" : "Vincular");
    save.type = "button";
    save.addEventListener("click", function () {
      if (department.value.trim().length < 2) return toast("Informe o departamento.", "error");
      withBusy(function () {
        return request("save_board", { method: "POST", data: { board_id: board.id, department: department.value.trim(), order: order.value } });
      }).then(function (payload) {
        toast(field(payload, "message", "Quadro vinculado."));
        return loadBoards(board.id).then(loadSettings);
      }).catch(function (error) { toast(error.message, "error"); });
    });
    actions.appendChild(save);
    if (board.mapped) {
      var remove = create("button", "btn btn-sm btn-outline-danger", "Remover");
      remove.type = "button";
      remove.addEventListener("click", function () {
        if (!window.confirm("Remover este quadro do painel? O quadro permanecerá no Trello.")) return;
        withBusy(function () {
          return request("remove_board", { method: "POST", data: { board_id: board.id } });
        }).then(function (payload) {
          toast(field(payload, "message", "Vínculo removido."));
          return loadBoards().then(loadSettings);
        }).catch(function (error) { toast(error.message, "error"); });
      });
      actions.appendChild(remove);
    }
    row.appendChild(actions);
    return row;
  }

  function loadSettings() {
    var container = root.querySelector("[data-kanban-settings-list]");
    container.replaceChildren(create("div", "text-muted", "Consultando quadros acessíveis…"));
    return request("available_boards").then(function (payload) {
      var available = asArray(field(payload, "boards", [])).map(function (board) {
        var id = String(field(board, "id", ""));
        var local = state.boards.find(function (item) { return item.id === id; });
        return {
          id: id,
          name: String(field(board, "name", local ? local.name : "")),
          url: String(field(board, "url", local ? local.url : "")),
          mapped: Boolean(field(board, "mapped", Boolean(local))),
          department: String(field(board, "department", local ? local.department : "")),
          order: local ? local.order : 100
        };
      });
      state.boards.forEach(function (local) {
        if (!available.some(function (board) { return board.id === local.id; })) {
          available.unshift({ id: local.id, name: local.name, url: local.url, mapped: true, department: local.department, order: local.order });
        }
      });
      available.sort(function (a, b) {
        if (a.mapped !== b.mapped) return a.mapped ? -1 : 1;
        return (a.department || a.name).localeCompare(b.department || b.name, "pt-BR");
      });
      container.replaceChildren();
      if (!available.length) {
        container.appendChild(create("div", "trello-kanban-empty", "A credencial não possui quadros abertos."));
      } else {
        available.forEach(function (board) { container.appendChild(settingsRow(board)); });
      }
    }).catch(function (error) {
      container.replaceChildren(create("div", "alert alert-danger mb-0", error.message));
    });
  }

  boardSelect.addEventListener("change", function () {
    if (boardSelect.value) loadBoard(boardSelect.value).catch(function (error) { toast(error.message, "error"); });
  });
  root.querySelector("[data-kanban-refresh]").addEventListener("click", function () {
    if (selectedBoardId()) loadBoard(selectedBoardId()).catch(function (error) { toast(error.message, "error"); });
  });
  root.querySelector("[data-kanban-add-list]").addEventListener("click", createList);
  root.querySelector("[data-kanban-settings]").addEventListener("click", function () {
    settingsDialog.showModal();
    loadSettings();
  });
  root.querySelector("[data-kanban-settings-close]").addEventListener("click", function () { closeDialog(settingsDialog); });
  root.querySelector("[data-kanban-dialog-close]").addEventListener("click", function () { closeDialog(cardDialog); });
  root.querySelector("[data-kanban-card-form]").addEventListener("submit", function (event) {
    event.preventDefault();
    saveCard();
  });
  root.querySelector("[data-kanban-card-archive]").addEventListener("click", archiveCard);
  root.querySelector("[data-kanban-comment-submit]").addEventListener("click", addComment);
  [cardDialog, settingsDialog].forEach(function (dialog) {
    dialog.addEventListener("click", function (event) {
      if (event.target === dialog) closeDialog(dialog);
    });
  });

  if (!schemaReady) {
    boardSelect.disabled = true;
    renderEmpty("Banco ainda não preparado", "Execute a migration do módulo Kanban para continuar.", "fa-database");
    setStatus("", false);
  } else if (!configured) {
    boardSelect.disabled = true;
    renderEmpty("Integração não configurada", "Adicione a chave e o token do Trello ao ambiente do servidor.", "fa-key");
    setStatus("", false);
  } else {
    loadBoards().catch(function (error) {
      setStatus("", false);
      renderEmpty("Falha ao iniciar", error.message, "fa-triangle-exclamation");
      toast(error.message, "error");
    });
  }
})();
