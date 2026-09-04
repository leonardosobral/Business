const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "../..");
const read = (file) => fs.readFileSync(path.join(root, file), "utf8");

test("Kanban pages are restricted to Business admins", () => {
    const page = read("administracao/kanban/index.cfm");
    const api = read("administracao/kanban/api.cfm");

    assert.match(page, /backend_login\.cfm/);
    assert.match(page, /require_admin\.cfm/);
    assert.match(api, /backend_login\.cfm/);
    assert.match(api, /require_admin\.cfm/);
});

test("Trello credentials stay on the server and use the Authorization header", () => {
    const application = read("Application.cfc");
    const service = read("administracao/kanban/includes/trello_service.cfm");
    const home = read("administracao/kanban/home.cfm");
    const browser = read("administracao/kanban/assets/kanban.js");

    assert.match(application, /RR_TRELLO_API_KEY/);
    assert.match(application, /RR_TRELLO_API_TOKEN/);
    assert.match(service, /Authorization/);
    assert.match(service, /oauth_consumer_key/);
    for (const source of [home, browser]) {
        assert.doesNotMatch(source, /APPLICATION\.trello\.(?:apiKey|apiToken)/i);
        assert.doesNotMatch(source, /data-api-(?:key|token)/i);
    }
    assert.doesNotMatch(service, /[?&](?:key|token)=/i);
});

test("Trello mutations use an explicit URL-encoded body compatible with POST and PUT", () => {
    const api = read("administracao/kanban/api.cfm");
    const service = read("administracao/kanban/includes/trello_service.cfm");

    assert.match(service, /application\/x-www-form-urlencoded; charset=UTF-8/);
    assert.match(service, /cfhttpparam\(type = "body", value = requestBody\)/);
    assert.doesNotMatch(service, /type = "formfield"/i);
    assert.match(service, /"idlist" = "idList"/);
    assert.match(service, /"idmembers" = "idMembers"/);
    assert.match(service, /"duecomplete" = "dueComplete"/);
    assert.match(service, /urlEncodedFormat\(outboundName, "UTF-8"\)/);
    assert.match(api, /kanbanTrelloRequest\("\/lists", "POST", \{idBoard = boardId/);
});

test("Upstream failures preserve JSON responses and log only safe request metadata", () => {
    const api = read("administracao/kanban/api.cfm");
    const service = read("administracao/kanban/includes/trello_service.cfm");

    assert.match(api, /remoteResponse\.message\}, 424\)/);
    assert.doesNotMatch(api, /remoteResponse\.message\}, 502\)/);
    assert.match(service, /file = "trello_kanban"/);
    assert.match(service, /kanbanLogRemoteFailure\(requestMethod, arguments\.path/);
    assert.doesNotMatch(service, /kanbanLogRemoteFailure\([^\n]*(?:apiKey|apiToken|requestBody)/i);
});

test("Mutations require CSRF and a locally authorized board", () => {
    const api = read("administracao/kanban/api.cfm");

    assert.match(api, /function kanbanRequireMutation/);
    assert.match(api, /SESSION\.trelloKanbanCsrf/);
    assert.match(api, /function kanbanRequireMappedBoard/);
    assert.match(api, /boardId = kanbanTrelloId\(kanbanInput\("board_id"/);
    assert.match(api, /mappedBoard = kanbanRequireMappedBoard\(boardId\)/);
    assert.match(api, /kanbanAssertListOnBoard/);
    assert.match(api, /kanbanAssertCardOnBoard/);
});

test("Schema keeps board allowlist and immutable audit records", () => {
    const schema = read("administracao/kanban/kanban_schema.sql");

    assert.match(schema, /CREATE TABLE IF NOT EXISTS public\.tb_trello_quadros/);
    assert.match(schema, /CREATE TABLE IF NOT EXISTS public\.tb_trello_auditoria/);
    assert.match(schema, /trello_board_id varchar\(32\) NOT NULL UNIQUE/);
    assert.match(schema, /id_usuario integer REFERENCES public\.tb_usuarios/);
    assert.doesNotMatch(schema, /api_token|api_key|secret/i);
});

test("Browser UI supports live board operations without exposing arbitrary Trello routes", () => {
    const browser = read("administracao/kanban/assets/kanban.js");

    for (const action of ["list_boards", "available_boards", "board", "create_card", "update_card", "move_card", "archive_card", "add_comment", "create_list", "update_list", "archive_list"]) {
        assert.match(browser, new RegExp(`\\b${action}\\b`));
    }
    assert.match(browser, /credentials: "same-origin"/);
    assert.match(browser, /csrf_token/);
    assert.match(browser, /dragstart/);
    assert.doesNotMatch(browser, /api\.trello\.com/);
});

test("Admin navigation exposes the Kanban module", () => {
    const sidenav = read("includes/estrutura/sidenav.cfm");

    assert.match(sidenav, /href="\/administracao\/kanban\/"/);
    assert.match(sidenav, />Kanban</);
});
