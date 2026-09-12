(function (root, factory) {
    const api = factory();
    if (typeof module === "object" && module.exports) module.exports = api;
    if (root && root.document) api.mount(root.document);
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
    "use strict";

    const FOLDER_MIME = "application/vnd.google-apps.folder";
    const GOOGLE_MIME = "application/vnd.google-apps.";
    const DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file";

    function isFolder(item) { return Boolean(item && item.mimeType === FOLDER_MIME); }
    function isGoogleNative(item) { return Boolean(item && String(item.mimeType || "").startsWith(GOOGLE_MIME)); }
    function formatBytes(value) {
        const bytes = Number(value);
        if (!Number.isFinite(bytes) || bytes < 0) return "—";
        if (bytes < 1024) return `${bytes} B`;
        const units = ["KB", "MB", "GB", "TB"];
        let amount = bytes / 1024;
        let unit = 0;
        while (amount >= 1024 && unit < units.length - 1) { amount /= 1024; unit += 1; }
        return `${amount >= 10 ? amount.toFixed(0) : amount.toFixed(1)} ${units[unit]}`;
    }
    function safeGoogleUrl(value) {
        try {
            const parsed = new URL(String(value || ""));
            if (parsed.protocol !== "https:" || !/(^|\.)google\.com$/i.test(parsed.hostname)) return "";
            return parsed.href;
        } catch (_) { return ""; }
    }
    function iconClass(item) {
        const mime = String(item && item.mimeType || "");
        if (mime === FOLDER_MIME) return "fa-solid fa-folder";
        if (mime === "application/vnd.google-apps.document") return "fa-regular fa-file-lines";
        if (mime === "application/vnd.google-apps.spreadsheet") return "fa-regular fa-file-excel";
        if (mime === "application/pdf") return "fa-regular fa-file-pdf";
        if (mime.startsWith("image/")) return "fa-regular fa-file-image";
        if (mime.startsWith("video/")) return "fa-regular fa-file-video";
        if (mime.startsWith("audio/")) return "fa-regular fa-file-audio";
        if (mime.includes("zip") || mime.includes("compressed")) return "fa-regular fa-file-zipper";
        return "fa-regular fa-file";
    }
    function formatDate(value) {
        const date = new Date(value || "");
        return Number.isNaN(date.getTime()) ? "—" : new Intl.DateTimeFormat("pt-BR", {dateStyle: "short", timeStyle: "short"}).format(date);
    }
    function capability(item, name, fallback) {
        return item && item.capabilities && typeof item.capabilities[name] === "boolean" ? item.capabilities[name] : fallback;
    }
    function normalizePickerIds(values) {
        const seen = new Set();
        const result = [];
        (Array.isArray(values) ? values : []).forEach(value => {
            const id = String(value || "").trim();
            if (!/^[A-Za-z0-9_-]{1,255}$/.test(id) || seen.has(id) || result.length >= 100) return;
            seen.add(id);
            result.push(id);
        });
        return result;
    }

    function mount(document) {
        const page = document.getElementById("googleDrive");
        if (!page) return;
        const csrf = page.dataset.csrf || "";
        const elements = {
            status: document.getElementById("driveStatus"), setup: document.getElementById("driveSetup"), setupMessage: document.getElementById("driveSetupMessage"),
            createRoot: document.getElementById("driveCreateRoot"), reconnect: document.getElementById("driveReconnect"), workspace: document.getElementById("driveWorkspace"),
            openRoot: document.getElementById("driveOpenRoot"), picker: document.getElementById("drivePicker"), pickerNotice: document.getElementById("drivePickerNotice"),
            upload: document.getElementById("driveUpload"), newButton: document.getElementById("driveNew"),
            search: document.getElementById("driveSearch"), refresh: document.getElementById("driveRefresh"), crumbs: document.getElementById("driveBreadcrumbs"),
            items: document.getElementById("driveItems"), more: document.getElementById("driveMore"), uploadHint: document.getElementById("driveUploadHint"),
            newDialog: document.getElementById("driveNewDialog"), uploadDialog: document.getElementById("driveUploadDialog"), renameDialog: document.getElementById("driveRenameDialog"),
            newForm: document.getElementById("driveNewForm"), uploadForm: document.getElementById("driveUploadForm"), renameForm: document.getElementById("driveRenameForm")
        };
        const pickerConfig = {
            clientId: page.dataset.pickerClientId || "",
            apiKey: page.dataset.pickerApiKey || "",
            appId: page.dataset.pickerAppId || "",
            email: page.dataset.pickerEmail || "contato@runnerhub.run"
        };
        const state = {root: null, folderId: "", nextPageToken: "", search: "", maxUploadBytes: 0, busy: false, pickerConfigured: false, pickerReady: false, pickerLoadFailed: false, pickerPreparing: null, pickerToken: "", pickerLoading: false};
        const scriptPromises = new Map();

        async function request(action, values) {
            const body = values instanceof FormData ? values : new FormData();
            if (!(values instanceof FormData)) Object.entries(values || {}).forEach(([key, value]) => body.append(key, value));
            body.set("action", action);
            body.set("csrf_token", csrf);
            const response = await fetch("/administracao/drive/api.cfm", {method: "POST", body, credentials: "same-origin", headers: {"Accept": "application/json"}});
            let data = {};
            try { data = await response.json(); } catch (_) {}
            if (!response.ok || !data.success) throw new Error(data.message || "Não foi possível consultar Documentos.");
            return data;
        }
        function setStatus(message, isError) {
            elements.status.textContent = message || "";
            elements.status.classList.toggle("text-danger", Boolean(isError));
        }
        function setBusy(value) {
            state.busy = Boolean(value);
            elements.items.setAttribute("aria-busy", state.busy ? "true" : "false");
            elements.refresh.disabled = state.busy;
            elements.more.disabled = state.busy;
        }
        function openGoogle(url) {
            const safe = safeGoogleUrl(url);
            if (safe) window.open(safe, "_blank", "noopener,noreferrer");
        }
        function loadExternalScript(src, ready) {
            if (ready()) return Promise.resolve();
            if (scriptPromises.has(src)) return scriptPromises.get(src);
            const promise = new Promise((resolve, reject) => {
                const script = document.createElement("script");
                const timer = window.setTimeout(() => reject(new Error("O Google demorou para carregar o seletor de arquivos.")), 15000);
                script.src = src;
                script.async = true;
                script.addEventListener("load", () => {
                    window.clearTimeout(timer);
                    if (ready()) resolve();
                    else reject(new Error("O Google não disponibilizou o seletor de arquivos."));
                }, {once: true});
                script.addEventListener("error", () => {
                    window.clearTimeout(timer);
                    reject(new Error("Não foi possível carregar o seletor do Google Drive."));
                }, {once: true});
                document.head.appendChild(script);
            });
            scriptPromises.set(src, promise);
            promise.catch(() => scriptPromises.delete(src));
            return promise;
        }
        async function loadPickerLibraries() {
            await Promise.all([
                loadExternalScript("https://apis.google.com/js/api.js", () => Boolean(window.gapi && typeof window.gapi.load === "function")),
                loadExternalScript("https://accounts.google.com/gsi/client", () => Boolean(window.google && window.google.accounts && window.google.accounts.oauth2))
            ]);
            if (!window.google.picker) {
                await new Promise((resolve, reject) => {
                    window.gapi.load("picker", {
                        callback: resolve,
                        onerror: () => reject(new Error("O Google Picker não pôde ser inicializado.")),
                        timeout: 10000,
                        ontimeout: () => reject(new Error("O Google Picker demorou para responder."))
                    });
                });
            }
            if (!window.google || !window.google.picker) throw new Error("O Google Picker não está disponível.");
        }
        function updatePickerControl() {
            const preparing = Boolean(state.pickerPreparing && !state.pickerReady && !state.pickerLoadFailed);
            elements.picker.disabled = !state.pickerConfigured || !state.root || state.pickerLoading || preparing;
            if (!state.pickerConfigured) elements.picker.title = "Configure o Google Picker no servidor";
            else if (preparing) elements.picker.title = "Carregando Google Picker";
            else if (state.pickerLoadFailed) elements.picker.title = "Tentar carregar o Google Picker novamente";
            else elements.picker.title = "Autorizar arquivos existentes nesta pasta";
        }
        function preparePicker() {
            if (state.pickerReady) return Promise.resolve(true);
            if (state.pickerPreparing && !state.pickerLoadFailed) return state.pickerPreparing;
            state.pickerLoadFailed = false;
            state.pickerPreparing = loadPickerLibraries().then(() => {
                state.pickerReady = true;
                elements.pickerNotice.hidden = true;
                return true;
            }).catch(error => {
                state.pickerLoadFailed = true;
                elements.pickerNotice.textContent = `${error.message} Clique em “Adicionar do Drive” para tentar novamente.`;
                elements.pickerNotice.hidden = false;
                return false;
            }).finally(updatePickerControl);
            updatePickerControl();
            return state.pickerPreparing;
        }
        function requestPickerToken() {
            return new Promise((resolve, reject) => {
                const tokenClient = window.google.accounts.oauth2.initTokenClient({
                    client_id: pickerConfig.clientId,
                    scope: DRIVE_FILE_SCOPE,
                    include_granted_scopes: false,
                    login_hint: pickerConfig.email,
                    callback: response => {
                        if (!response || response.error || !response.access_token) {
                            reject(new Error(response && response.error_description || "O Google não autorizou o acesso aos arquivos selecionados."));
                            return;
                        }
                        state.pickerToken = response.access_token;
                        resolve(response.access_token);
                    },
                    error_callback: () => reject(new Error("A janela de autorização do Google foi fechada ou bloqueada."))
                });
                tokenClient.requestAccessToken({prompt: state.pickerToken ? "" : "consent"});
            });
        }
        async function authorizePickerDocuments(data) {
            const picker = window.google.picker;
            if (!data || data[picker.Response.ACTION] !== picker.Action.PICKED) return;
            const documents = data[picker.Response.DOCUMENTS] || [];
            const ids = normalizePickerIds(documents.map(item => item[picker.Document.ID]));
            if (!ids.length) { setStatus("Nenhum arquivo válido foi selecionado.", true); return; }
            try {
                setStatus("Autorizando os itens selecionados…");
                const result = await request("authorize_picker", {ids: JSON.stringify(ids)});
                await loadFolder(state.folderId);
                setStatus(result.message || "Itens adicionados ao Business.");
            } catch (error) { setStatus(error.message, true); }
        }
        function showPicker(token) {
            const picker = window.google.picker;
            const view = new picker.DocsView(picker.ViewId.DOCS)
                .setIncludeFolders(true)
                .setSelectFolderEnabled(true)
                .setMode(picker.DocsViewMode.LIST)
                .setParent(state.folderId);
            new picker.PickerBuilder()
                .addView(view)
                .enableFeature(picker.Feature.MULTISELECT_ENABLED)
                .setDeveloperKey(pickerConfig.apiKey)
                .setAppId(pickerConfig.appId)
                .setOAuthToken(token)
                .setOrigin(window.location.origin)
                .setCallback(data => { void authorizePickerDocuments(data); })
                .build()
                .setVisible(true);
        }
        async function openPicker() {
            if (state.pickerLoading || !state.pickerConfigured || !state.folderId) return;
            if (!state.pickerReady) {
                elements.picker.disabled = true;
                setStatus("Preparando Google Drive…");
                const prepared = await preparePicker();
                setStatus(prepared ? "Google Drive pronto. Clique novamente em “Adicionar do Drive”." : "Não foi possível preparar o Google Picker.", !prepared);
                return;
            }
            state.pickerLoading = true;
            updatePickerControl();
            setStatus("Carregando Google Drive…");
            try {
                // Invoke GIS before the first await so browsers recognize the OAuth popup as a direct click.
                const tokenRequest = requestPickerToken();
                showPicker(await tokenRequest);
                setStatus("Selecione arquivos ou pastas na janela do Google Drive.");
            } catch (error) { setStatus(error.message, true); }
            finally {
                state.pickerLoading = false;
                updatePickerControl();
            }
        }
        function button(label, classes, icon) {
            const result = document.createElement("button");
            result.type = "button";
            result.className = classes;
            result.setAttribute("aria-label", label);
            result.title = label;
            const glyph = document.createElement("i");
            glyph.className = icon;
            glyph.setAttribute("aria-hidden", "true");
            result.appendChild(glyph);
            return result;
        }
        function renderCrumbs(trail) {
            elements.crumbs.replaceChildren();
            (trail || []).forEach((entry, index) => {
                if (index) {
                    const separator = document.createElement("span");
                    separator.className = "drive-crumb-separator";
                    separator.textContent = "/";
                    elements.crumbs.appendChild(separator);
                }
                const crumb = document.createElement("button");
                crumb.type = "button";
                crumb.className = "drive-crumb";
                crumb.textContent = entry.name || "Pasta";
                crumb.disabled = index === trail.length - 1;
                crumb.addEventListener("click", () => loadFolder(entry.id));
                elements.crumbs.appendChild(crumb);
            });
        }
        function renderItem(item) {
            const row = document.createElement("article");
            row.className = "drive-item";
            const identity = document.createElement("div");
            identity.className = "drive-item-identity";
            const icon = document.createElement("i");
            icon.className = `${iconClass(item)} drive-item-icon`;
            icon.setAttribute("aria-hidden", "true");
            const name = document.createElement("button");
            name.type = "button";
            name.className = "drive-item-name";
            name.textContent = item.name || "Sem nome";
            if (isFolder(item)) name.addEventListener("click", () => loadFolder(item.id));
            else {
                const target = safeGoogleUrl(item.webViewLink);
                name.disabled = !target;
                if (target) name.addEventListener("click", () => openGoogle(target));
            }
            identity.append(icon, name);

            const modified = document.createElement("time");
            modified.className = "drive-item-meta";
            modified.textContent = formatDate(item.modifiedTime);
            const size = document.createElement("span");
            size.className = "drive-item-meta";
            size.textContent = isFolder(item) || isGoogleNative(item) ? "—" : formatBytes(item.size);
            const actions = document.createElement("div");
            actions.className = "drive-item-actions";
            const webLink = safeGoogleUrl(item.webViewLink);
            if (webLink) {
                const open = button("Abrir no Google", "btn btn-sm btn-outline-light", "fa-solid fa-arrow-up-right-from-square");
                open.addEventListener("click", () => openGoogle(webLink));
                actions.appendChild(open);
            }
            if (!isFolder(item) && !isGoogleNative(item) && capability(item, "canDownload", true)) {
                const download = document.createElement("a");
                download.className = "btn btn-sm btn-outline-light";
                download.href = `/administracao/drive/download.cfm?id=${encodeURIComponent(item.id)}`;
                download.setAttribute("aria-label", "Baixar");
                download.title = "Baixar";
                const glyph = document.createElement("i");
                glyph.className = "fa-solid fa-download";
                glyph.setAttribute("aria-hidden", "true");
                download.appendChild(glyph);
                actions.appendChild(download);
            }
            if (capability(item, "canRename", capability(item, "canEdit", true))) {
                const rename = button("Renomear", "btn btn-sm btn-outline-light", "fa-solid fa-pen");
                rename.addEventListener("click", () => {
                    elements.renameForm.elements.file_id.value = item.id;
                    elements.renameForm.elements.name.value = item.name || "";
                    elements.renameDialog.showModal();
                    elements.renameForm.elements.name.focus();
                    elements.renameForm.elements.name.select();
                });
                actions.appendChild(rename);
            }
            if (capability(item, "canTrash", true)) {
                const trash = button("Enviar à lixeira", "btn btn-sm btn-outline-danger", "fa-regular fa-trash-can");
                trash.addEventListener("click", async () => {
                    if (!window.confirm(`Enviar “${item.name || "este item"}” à lixeira do Google Drive?`)) return;
                    try { setStatus("Enviando à lixeira…"); await request("trash", {file_id: item.id}); await loadFolder(state.folderId); setStatus("Item enviado à lixeira."); }
                    catch (error) { setStatus(error.message, true); }
                });
                actions.appendChild(trash);
            }
            row.append(identity, modified, size, actions);
            return row;
        }
        function renderItems(items, append) {
            if (!append) elements.items.replaceChildren();
            (items || []).forEach(item => elements.items.appendChild(renderItem(item)));
            if (!append && !(items || []).length) {
                const empty = document.createElement("p");
                empty.className = "drive-empty";
                empty.textContent = state.search ? "Nenhum item encontrado nesta pasta." : "Esta pasta está vazia.";
                elements.items.appendChild(empty);
            }
        }
        async function loadFolder(folderId, append) {
            if (state.busy) return;
            setBusy(true);
            setStatus("Carregando documentos…");
            try {
                const data = await request("list", {folder_id: folderId || state.root.id, search: state.search, page_token: append ? state.nextPageToken : ""});
                state.folderId = data.folder.id;
                state.nextPageToken = data.nextPageToken || "";
                renderCrumbs(data.trail || []);
                renderItems(data.items || [], Boolean(append));
                elements.more.hidden = !state.nextPageToken;
                setStatus(`${data.items.length} ${data.items.length === 1 ? "item" : "itens"}${state.search ? " na busca" : ""}.`);
            } catch (error) { setStatus(error.message, true); }
            finally { setBusy(false); }
        }
        async function loadStatus() {
            try {
                const data = await request("status");
                state.maxUploadBytes = Number(data.maxUploadBytes) || 0;
                state.pickerConfigured = Boolean(data.pickerConfigured && pickerConfig.clientId && pickerConfig.apiKey && /^\d{6,32}$/.test(pickerConfig.appId));
                elements.uploadHint.textContent = `Até ${formatBytes(state.maxUploadBytes)}. Executáveis e scripts são bloqueados.`;
                elements.pickerNotice.hidden = state.pickerConfigured;
                elements.setup.hidden = data.schemaReady && data.connected && data.rootConfigured;
                elements.workspace.hidden = !(data.schemaReady && data.connected && data.rootConfigured);
                elements.createRoot.hidden = !(data.schemaReady && data.connected && !data.rootConfigured);
                elements.reconnect.hidden = !data.schemaReady || data.connected;
                elements.setupMessage.textContent = data.message || "";
                setStatus(data.message || "");
                if (data.schemaReady && data.connected && data.rootConfigured) {
                    state.root = data.root;
                    state.folderId = data.root.id;
                    elements.openRoot.hidden = false;
                    elements.upload.disabled = false;
                    elements.newButton.disabled = false;
                    if (state.pickerConfigured) void preparePicker();
                    else updatePickerControl();
                    await loadFolder(state.root.id);
                } else updatePickerControl();
            } catch (error) {
                elements.setup.hidden = false;
                elements.setupMessage.textContent = error.message;
                setStatus(error.message, true);
            }
        }
        function dialogError(dialog, message) {
            const output = dialog.querySelector("[data-dialog-error]");
            if (output) output.textContent = message || "";
        }
        function closeDialog(dialog) { dialogError(dialog, ""); dialog.close(); }
        document.querySelectorAll(".drive-dialog [data-close]").forEach(control => control.addEventListener("click", () => closeDialog(control.closest("dialog"))));
        [elements.newDialog, elements.uploadDialog, elements.renameDialog].forEach(dialog => dialog.addEventListener("click", event => { if (event.target === dialog) closeDialog(dialog); }));

        elements.createRoot.addEventListener("click", async () => {
            elements.createRoot.disabled = true;
            setStatus("Criando pasta segura no Google Drive…");
            try { await request("create_root"); await loadStatus(); }
            catch (error) { setStatus(error.message, true); }
            finally { elements.createRoot.disabled = false; }
        });
        elements.openRoot.addEventListener("click", () => { if (state.root) openGoogle(`https://drive.google.com/drive/folders/${encodeURIComponent(state.root.id)}`); });
        elements.picker.addEventListener("click", openPicker);
        elements.newButton.addEventListener("click", () => { elements.newForm.reset(); dialogError(elements.newDialog, ""); elements.newDialog.showModal(); elements.newForm.elements.name.focus(); });
        elements.upload.addEventListener("click", () => { elements.uploadForm.reset(); dialogError(elements.uploadDialog, ""); elements.uploadDialog.showModal(); });
        elements.refresh.addEventListener("click", () => loadFolder(state.folderId));
        elements.more.addEventListener("click", () => loadFolder(state.folderId, true));
        let searchTimer = 0;
        elements.search.addEventListener("input", () => {
            window.clearTimeout(searchTimer);
            searchTimer = window.setTimeout(() => { state.search = elements.search.value.trim(); loadFolder(state.folderId); }, 350);
        });
        elements.newForm.addEventListener("submit", async event => {
            event.preventDefault(); dialogError(elements.newDialog, "");
            const submitter = elements.newForm.querySelector("button[type=submit]"); submitter.disabled = true;
            try {
                await request("create", {type: elements.newForm.elements.type.value, name: elements.newForm.elements.name.value, parent_id: state.folderId});
                closeDialog(elements.newDialog); await loadFolder(state.folderId); setStatus("Item criado.");
            } catch (error) { dialogError(elements.newDialog, error.message); }
            finally { submitter.disabled = false; }
        });
        elements.renameForm.addEventListener("submit", async event => {
            event.preventDefault(); dialogError(elements.renameDialog, "");
            const submitter = elements.renameForm.querySelector("button[type=submit]"); submitter.disabled = true;
            try {
                await request("rename", {file_id: elements.renameForm.elements.file_id.value, name: elements.renameForm.elements.name.value});
                closeDialog(elements.renameDialog); await loadFolder(state.folderId); setStatus("Item renomeado.");
            } catch (error) { dialogError(elements.renameDialog, error.message); }
            finally { submitter.disabled = false; }
        });
        elements.uploadForm.addEventListener("submit", async event => {
            event.preventDefault(); dialogError(elements.uploadDialog, "");
            const file = elements.uploadForm.elements.upload_file.files[0];
            if (!file) { dialogError(elements.uploadDialog, "Selecione um arquivo."); return; }
            if (state.maxUploadBytes && file.size > state.maxUploadBytes) { dialogError(elements.uploadDialog, `O arquivo ultrapassa ${formatBytes(state.maxUploadBytes)}.`); return; }
            const submitter = elements.uploadForm.querySelector("button[type=submit]"); submitter.disabled = true;
            const body = new FormData(elements.uploadForm); body.set("parent_id", state.folderId);
            try {
                await request("upload", body); closeDialog(elements.uploadDialog); await loadFolder(state.folderId); setStatus("Arquivo enviado.");
            } catch (error) { dialogError(elements.uploadDialog, error.message); }
            finally { submitter.disabled = false; }
        });
        loadStatus();
    }

    return {mount, isFolder, isGoogleNative, formatBytes, safeGoogleUrl, iconClass, normalizePickerIds};
});
