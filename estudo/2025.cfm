<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Runner Hub Notebooks</title>

  <!-- CodeMirror 5 -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/lib/codemirror.min.css">
  <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/lib/codemirror.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/xml/xml.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/javascript/javascript.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/sql/sql.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/codemirror@5.65.16/mode/markdown/markdown.min.js"></script>

  <!-- SortableJS -->
  <script src="https://cdn.jsdelivr.net/npm/sortablejs@1.15.6/Sortable.min.js"></script>

  <!-- Markdown render + sanitize -->
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/dompurify@3.1.7/dist/purify.min.js"></script>

  <style>
    :root { --bg:#f6f7fb; --card:#fff; --border:#e6e8ef; --text:#1b1f2a; --muted:#6b7280; }
    body { margin:0; font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; background:var(--bg); color:var(--text); }
    .page { max-width: 980px; margin: 0 auto; padding: 0 16px 48px; display:flex; gap:10px;}

    .topbar { max-width: 980px; margin: 12px auto; display:flex; gap:12px; align-items:center; justify-content:space-between; margin-bottom: 14px; }
    .title { margin:0; font-size: 24px; }
    .muted { color:var(--muted); font-size: 12px; }
    .btn {
      font-size:12px; padding:8px 10px; border-radius:10px; border:1px solid var(--border);
      background:#fff; cursor:pointer;
    }
    .btn.primary { background:#111827; color:#fff; border-color:#111827; }
    .btn.danger { background:#fff; color:#b91c1c; border-color:#fecaca; }
    .btn:disabled { opacity:.55; cursor:not-allowed; }

    #menu { margin-top: 12px; width: 220px; }
    #cells { margin-top: 0; width: 740px; }

    .cell {
      background:var(--card);
      border:1px solid var(--border);
      border-radius: 14px;
      padding: 12px;
      margin: 12px 0;
      box-shadow: 0 1px 2px rgba(0,0,0,.04);
    }

    .meta { display:flex; gap:10px; align-items:center; justify-content:space-between; margin-bottom: 10px; }
    .left { display:flex; gap:10px; align-items:center; }
    .badge { font-size:12px; padding:4px 8px; border-radius:999px; background:#eef2ff; color:#3730a3; border:1px solid #e0e7ff; }
    .drag { cursor: grab; user-select:none; font-size: 12px; padding: 4px 8px; border-radius: 10px; border:1px solid var(--border); background:#fff; color:var(--muted); }
    .actions { display:flex; gap:8px; align-items:center; }
    .status { font-size:12px; color:var(--muted); min-width: 80px; text-align:right; }

    .cm-wrap { border:1px solid var(--border); border-radius: 12px; overflow:hidden; }
    .CodeMirror { height: auto; min-height: 140px; }

    .view-wrap {
      border:1px solid var(--border);
      border-radius: 12px;
      background:#fafafa;
      padding: 12px;
      cursor: text;
    }

    .hidden { display:none; }

    /* Markdown view styling */
    .md-view { line-height: 1.65; }
    .md-view h1, .md-view h2, .md-view h3 { margin: 0.4em 0 0.4em; }
    .md-view p { margin: 0.6em 0; }
    .md-view ul { margin: 0.6em 0 0.6em 1.2em; }
    .md-view code { background:#eef2f7; padding: 2px 5px; border-radius: 6px; }
    .md-view pre { background:#0f172a; color:#e5e7eb; padding: 12px; border-radius: 12px; overflow:auto; }
    .md-view pre code { background: transparent; padding: 0; }

    /* Code view styling (raw) */
    .code-view pre { margin:0; white-space: pre; overflow:auto; }
    .code-view code { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", monospace; font-size: 13px; }

    /* ===== Reading mode (full-screen) ===== */
    body.reading {
      background:#fff;
    }
    body.reading .page { max-width: 860px; padding-top: 14px; }
    body.reading .topbar,
    body.reading #globalStatus { display:none; }
    body.reading .cell { box-shadow:none; border-color:#eef0f6; }
    body.reading .meta .actions,
    body.reading .drag { display:none; }
    body.reading .cm-wrap { display:none !important; }
    body.reading .view-wrap { background:#fff; border:0; padding: 4px 0 0; cursor: default; }
    body.reading .badge { background:#fff; border-color:#fff; color:#111827; padding-left: 0; }

    /* Optional: full browser fullscreen */
    .btn.small { padding:6px 8px; border-radius: 9px; }

  </style>

</head>

<body>

  <div class="topbar">
    <div>
      <h1 class="title">Infograficos Runner Hub 2025</h1>
      <div class="muted" id="subtitle">—</div>
      <div class="muted" id="globalStatus">Carregando...</div>
    </div>
    <div style="display:flex; gap:8px; align-items:center; flex-wrap:wrap;">
      <button class="btn" id="addMarkdown" type="button">+ Texto</button>
      <button class="btn" id="addCode" type="button">+ Código</button>
      <button class="btn" id="saveOrder" type="button" disabled>Salvar ordem</button>
      <button class="btn" id="toggleReading" type="button">Modo leitura</button>
      <button class="btn primary" id="exportHtml" type="button">Exportar HTML</button>
    </div>
  </div>



  <div class="page">

    <div id="menu" class="cell">
      <cfquery name="qNotebookMenu" datasource="runner_dba">
        select * from notebooks order by call_order
      </cfquery>
      <cfoutput query="qNotebookMenu">
        <p><a href="2025.cfm?notebookId=#qNotebookMenu.notebook_id#">#qNotebookMenu.notebook_title#</a></p>
      </cfoutput>
    </div>

    <div id="cells"></div>

  </div>

  <script>
    // ===== Config =====
    const API = {
      getCells:   "/api/notebook/getCells.cfm",
      saveCell:   "/api/notebook/saveCell.cfm",
      createCell: "/api/notebook/createCell.cfm",
      deleteCell: "/api/notebook/deleteCell.cfm",
      reorder:    "/api/notebook/reorderCells.cfm"
    };

    const modeByLang = {
      html: "xml",
      sql: "sql",
      javascript: "javascript",
      markdown: "markdown"
    };

    // ===== Helpers =====
    const qs = (sel, el=document) => el.querySelector(sel);
    const qsa = (sel, el=document) => Array.from(el.querySelectorAll(sel));

    function getNotebookId() {
      const u = new URL(location.href);
      const id = Number(u.searchParams.get("notebookId") || 0);
      return id > 0 ? id : 1;
    }
    const NOTEBOOK_ID = getNotebookId();

    function setGlobalStatus(msg) { qs("#globalStatus").textContent = msg; }

    function escapeHtml(s) {
      return String(s)
        .replaceAll("&","&amp;")
        .replaceAll("<","&lt;")
        .replaceAll(">","&gt;")
        .replaceAll('"',"&quot;")
        .replaceAll("'","&#039;");
    }

    function normalizeRaw(s) {
      s = String(s ?? "");
      return s.replace(/\r\n/g, "\n");
    }

    async function postJson(url, payload) {
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type":"application/json" },
        body: JSON.stringify(payload),
        credentials: "include"
      });
      const data = await res.json().catch(() => null);
      return { res, data };
    }

    function nowIsoLocal() {
      const d = new Date();
      return d.toISOString().slice(0,19).replace("T"," ");
    }

    // ===== Notebook state =====
    const editors = new Map();      // cellId -> CodeMirror
    const saveTimers = new Map();   // cellId -> timeout id
    let orderDirty = false;

    function debounce(cellId, fn, ms=900) {
      if (saveTimers.has(cellId)) clearTimeout(saveTimers.get(cellId));
      const t = setTimeout(fn, ms);
      saveTimers.set(cellId, t);
    }

    function setCellStatus(cellEl, msg) {
      const s = qs(".status", cellEl);
      if (s) s.textContent = msg;
    }

    function setOrderDirty(dirty) {
      orderDirty = dirty;
      qs("#saveOrder").disabled = !dirty;
    }

    // ===== View rendering (unified) =====
    function renderMarkdownToHtml(md) {
      const unsafe = marked.parse(md || "");
      return DOMPurify.sanitize(unsafe);
    }

    function renderCellView(cellEl) {
      const type = cellEl.dataset.type;
      const lang = (cellEl.dataset.lang || "").toLowerCase();
      const cellId = Number(cellEl.dataset.cellId);
      const cm = editors.get(cellId);
      const raw = cm ? cm.getValue() : (cellEl.dataset.raw || "");

      const view = qs(".view-wrap", cellEl);
      if (!view) return;

      if (type === "markdown") {
        view.classList.add("md-view");
        view.classList.remove("code-view");
        view.innerHTML = renderMarkdownToHtml(raw);
        return;
      }

      // code cells
      if (lang === "html") {
        // HTML preview render (sanitize to reduce risk)
        view.classList.remove("md-view");
        view.classList.remove("code-view");
        view.innerHTML = DOMPurify.sanitize(raw || "");
        return;
      }

      // other languages: show as code block
      view.classList.remove("md-view");
      view.classList.add("code-view");
      view.innerHTML = `<pre><code>${escapeHtml(raw || "")}</code></pre>`;
    }

    function showView(cellEl) {
      qs(".view-wrap", cellEl).classList.remove("hidden");
      qs(".cm-wrap", cellEl).classList.add("hidden");

      const btnEdit = qs('[data-action="edit"]', cellEl);
      const btnSave = qs('[data-action="save"]', cellEl);
      if (btnEdit) btnEdit.classList.remove("hidden");
      if (btnSave) btnSave.classList.add("hidden");

      renderCellView(cellEl);
    }

    function showEdit(cellEl) {
      qs(".view-wrap", cellEl).classList.add("hidden");
      qs(".cm-wrap", cellEl).classList.remove("hidden");

      const btnEdit = qs('[data-action="edit"]', cellEl);
      const btnSave = qs('[data-action="save"]', cellEl);
      if (btnEdit) btnEdit.classList.add("hidden");
      if (btnSave) btnSave.classList.remove("hidden");

      const cellId = Number(cellEl.dataset.cellId);
      const cm = editors.get(cellId);
      if (cm) cm.refresh();
    }

    // ===== Rendering DOM for cells =====
    function badgeLabel(cell) {
      if (cell.cell_type === "markdown") return "Texto";
      return (cell.lang || "code").toUpperCase();
    }

    function createCellDom(cell) {
      const id = cell.id;
      const type = cell.cell_type;
      const lang = (cell.lang || (type === "markdown" ? "markdown" : "plaintext")).toLowerCase();
      const content = normalizeRaw(cell.content);

      const wrap = document.createElement("section");
      wrap.className = "cell";
      wrap.dataset.cellId = id;
      wrap.dataset.type = type;
      wrap.dataset.lang = lang;
      wrap.dataset.raw = content;

      wrap.innerHTML = `
        <div class="meta">
          <div class="left">
            <span class="drag" title="Arraste para reordenar">Arrastar</span>
            <span class="badge">${escapeHtml(badgeLabel(cell))}</span>
          </div>
          <div class="actions">
            <button class="btn" data-action="copy" type="button">Copiar</button>
            <button class="btn" data-action="edit" type="button">Editar</button>
            <button class="btn primary hidden" data-action="save" type="button">Salvar</button>
            <button class="btn danger" data-action="delete" type="button">Excluir</button>
            <span class="status">—</span>
          </div>
        </div>

        <!-- VIEW (default) -->
        <div class="view-wrap"></div>

        <!-- EDIT -->
        <div class="cm-wrap hidden">
          <textarea class="editor"></textarea>
        </div>
      `;

      const textarea = qs("textarea.editor", wrap);
      textarea.value = content;

      return wrap;
    }

    function initEditorForCell(cellEl) {
      const cellId = Number(cellEl.dataset.cellId);
      const lang = (cellEl.dataset.lang || "markdown").toLowerCase();
      const textarea = qs("textarea.editor", cellEl);

      const cm = CodeMirror.fromTextArea(textarea, {
        lineNumbers: true,
        mode: modeByLang[lang] || "markdown",
        viewportMargin: Infinity
      });

      editors.set(cellId, cm);

      cm.on("change", () => {
        setCellStatus(cellEl, "Editado");
        debounce(cellId, () => saveCell(cellEl, { stayInEdit: true }), 900);
      });

      // default: view mode
      showView(cellEl);
      setCellStatus(cellEl, "Carregado");
    }

    // ===== API actions =====
    async function loadCells() {
      setGlobalStatus("Carregando...");
      qs("#subtitle").textContent = `notebookId=${NOTEBOOK_ID}`;

      const url = `${API.getCells}?notebookId=${encodeURIComponent(NOTEBOOK_ID)}`;
      const res = await fetch(url, { credentials:"include" });
      const data = await res.json().catch(() => null);

      if (!res.ok || !data || data.ok !== true) {
        setGlobalStatus("Erro ao carregar.");
        console.error("Load failed", res.status, data);
        return;
      }

      const container = qs("#cells");
      container.innerHTML = "";

      data.cells.forEach(cell => {
        const cellEl = createCellDom(cell);
        container.appendChild(cellEl);
        initEditorForCell(cellEl);
      });

      initSortable();
      setOrderDirty(false);
      setGlobalStatus("Pronto.");
    }

    async function saveCell(cellEl, opts = {}) {
      const cellId = Number(cellEl.dataset.cellId);
      const type = cellEl.dataset.type;
      const lang = cellEl.dataset.lang || "";
      const cm = editors.get(cellId);
      const content = cm ? cm.getValue() : "";

      setCellStatus(cellEl, "Salvando...");

      const payload = {
        notebookId: NOTEBOOK_ID,
        cellId,
        type,
        lang,
        content
      };

      try {
        const { res, data } = await postJson(API.saveCell, payload);
        if (!res.ok || !data || data.ok !== true) {
          setCellStatus(cellEl, "Erro");
          console.error("Save failed", res.status, data);
          return;
        }

        cellEl.dataset.raw = content;
        setCellStatus(cellEl, "Salvo");

        // Se foi clique em salvar (ou você quiser voltar pro modo view), renderiza e volta
        if (!opts.stayInEdit) showView(cellEl);

      } catch (e) {
        setCellStatus(cellEl, "Erro rede");
        console.error(e);
      }
    }

    async function createCell(cellType, lang) {
      setGlobalStatus("Criando célula...");
      const initial =
        cellType === "markdown" ? "## Novo bloco\n\nDuplo-clique para editar." :
        (lang === "html" ? "<div><strong>Novo HTML</strong></div>\n" : "");

      const payload = {
        notebookId: NOTEBOOK_ID,
        type: cellType,
        lang: lang || "",
        content: initial
      };

      const { res, data } = await postJson(API.createCell, payload);
      if (!res.ok || !data || data.ok !== true) {
        setGlobalStatus("Erro ao criar célula.");
        console.error("Create failed", res.status, data);
        return;
      }

      const container = qs("#cells");
      const cellEl = createCellDom(data.cell);
      container.appendChild(cellEl);
      initEditorForCell(cellEl);
      setOrderDirty(true);
      setGlobalStatus("Célula criada.");

      // abre direto em edit para acelerar
      showEdit(cellEl);
    }

    async function deleteCell(cellEl) {
      const cellId = Number(cellEl.dataset.cellId);
      if (!confirm("Excluir esta célula?")) return;

      setCellStatus(cellEl, "Excluindo...");

      const payload = { notebookId: NOTEBOOK_ID, cellId };
      const { res, data } = await postJson(API.deleteCell, payload);

      if (!res.ok || !data || data.ok !== true) {
        setCellStatus(cellEl, "Erro");
        console.error("Delete failed", res.status, data);
        return;
      }

      const cm = editors.get(cellId);
      if (cm) {
        cm.toTextArea();
        editors.delete(cellId);
      }

      cellEl.remove();
      setOrderDirty(true);
      setGlobalStatus("Célula excluída.");
    }

    async function saveOrder() {
      const idsInOrder = qsa(".cell", qs("#cells")).map(el => Number(el.dataset.cellId));
      if (!idsInOrder.length) return;

      setGlobalStatus("Salvando ordem...");

      const payload = { notebookId: NOTEBOOK_ID, orderedCellIds: idsInOrder };
      const { res, data } = await postJson(API.reorder, payload);

      if (!res.ok || !data || data.ok !== true) {
        setGlobalStatus("Erro ao salvar ordem.");
        console.error("Reorder failed", res.status, data);
        return;
      }

      setOrderDirty(false);
      setGlobalStatus("Ordem salva.");
    }

    // ===== Sortable =====
    function initSortable() {
      const container = qs("#cells");
      new Sortable(container, {
        animation: 150,
        handle: ".drag",
        onEnd: async (evt) => {
          if (evt.oldIndex !== evt.newIndex) {
            setOrderDirty(true);
            await saveOrder(); // salva na hora
          }
        }
      });
    }

    // ===== Reading mode + optional browser fullscreen =====
    async function toggleReading() {
      const isOn = document.body.classList.toggle("reading");
      qs("#toggleReading").textContent = isOn ? "Sair leitura" : "Modo leitura";

      // fecha qualquer editor aberto ao entrar no modo leitura
      if (isOn) {
        qsa(".cell").forEach(cellEl => showView(cellEl));
      }
    }

    // ===== Export HTML (rendered) =====
    function buildExportHtml() {
      const title = `Notebook ${NOTEBOOK_ID}`;
      const renderedCells = qsa(".cell", qs("#cells")).map(cellEl => {
        const type = cellEl.dataset.type;
        const lang = (cellEl.dataset.lang || "").toLowerCase();
        const raw = editors.get(Number(cellEl.dataset.cellId))?.getValue() ?? cellEl.dataset.raw ?? "";

        if (type === "markdown") {
          const html = renderMarkdownToHtml(raw);
          return `<section class="cell"><div class="content md">${html}</div></section>`;
        }

        if (lang === "html") {
          const html = DOMPurify.sanitize(raw);
          return `<section class="cell"><div class="content html">${html}</div></section>`;
        }

        return `<section class="cell"><div class="content code"><pre><code>${escapeHtml(raw)}</code></pre></div></section>`;
      }).join("\n");

      return `<!doctype html>
  <html lang="pt-BR">
  <head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>${escapeHtml(title)}</title>
  <style>
    body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:#fff;color:#111827;}
    .page{max-width:860px;margin:24px auto;padding:0 16px 48px;}
    h1{margin:0 0 10px;font-size:20px;}
    .meta{color:#6b7280;font-size:12px;margin-bottom:14px;}
    .cell{padding:14px 0;border-bottom:1px solid #eef0f6;}
    .content{line-height:1.65;}
    .content pre{background:#0f172a;color:#e5e7eb;padding:12px;border-radius:12px;overflow:auto;}
    .content code{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono",monospace;font-size:13px;}
    .content.md code{background:#eef2f7;padding:2px 5px;border-radius:6px;}
  </style>
  </head>
  <body>
    <div class="page">
      <h1>${escapeHtml(title)}</h1>
      <div class="meta">Exportado em ${escapeHtml(nowIsoLocal())}</div>
      ${renderedCells}
    </div>
  </body>
  </html>`;
    }

    function exportHtml() {
      // garante que o view esteja atualizado
      qsa(".cell").forEach(cellEl => renderCellView(cellEl));

      const html = buildExportHtml();
      const blob = new Blob([html], { type: "text/html;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `notebook-${NOTEBOOK_ID}.html`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    }

    // ===== Events =====
    document.addEventListener("click", (e) => {
      const cellEl = e.target.closest(".cell");
      if (!cellEl) return;

      const btn = e.target.closest("button");
      if (!btn) return;

      const action = btn.getAttribute("data-action");
      if (!action) return;

      if (action === "copy") {
        const cellId = Number(cellEl.dataset.cellId);
        const raw = editors.get(cellId)?.getValue() ?? cellEl.dataset.raw ?? "";
        navigator.clipboard.writeText(raw).catch(() => {});
        setCellStatus(cellEl, "Copiado");
        setTimeout(() => setCellStatus(cellEl, "—"), 900);
      }

      if (action === "edit") showEdit(cellEl);
      if (action === "save") saveCell(cellEl, { stayInEdit: false });
      if (action === "delete") deleteCell(cellEl);
    });

    // Duplo-clique no VIEW para editar (Markdown + HTML + code)
    document.addEventListener("dblclick", (e) => {
      if (document.body.classList.contains("reading")) return;
      const view = e.target.closest(".view-wrap");
      if (!view) return;
      const cellEl = e.target.closest(".cell");
      if (!cellEl) return;
      showEdit(cellEl);
    });

    // Shortcuts úteis: ESC volta para view
    document.addEventListener("keydown", (e) => {
      if (e.key !== "Escape") return;
      if (e.key === "Escape" && document.body.classList.contains("reading")) {
        toggleReading();
      }

      const activeCell = document.activeElement?.closest?.(".cell");
      if (!activeCell) return;
      showView(activeCell);
    });

    qs("#addMarkdown").addEventListener("click", () => createCell("markdown", "markdown"));
    qs("#addCode").addEventListener("click", () => {
      const lang = prompt("Linguagem (html/sql/javascript):", "sql");
      if (!lang) return;
      createCell("code", lang.toLowerCase());
    });
    qs("#saveOrder").addEventListener("click", saveOrder);
    qs("#toggleReading").addEventListener("click", toggleReading);
    qs("#exportHtml").addEventListener("click", exportHtml);

    // ===== Boot =====
    qs("#subtitle").textContent = `notebookId=${NOTEBOOK_ID}`;
    loadCells();
  </script>

</body>
</html>
