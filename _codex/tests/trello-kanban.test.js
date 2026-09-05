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
    const regularRequest = service.slice(service.indexOf("function kanbanTrelloRequest"), service.indexOf("function kanbanTrelloFileRequest"));
    assert.doesNotMatch(regularRequest, /type = "formfield"/i);
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

test("Card editor exposes the operational Trello card feature set", () => {
    const api = read("administracao/kanban/api.cfm");
    const home = read("administracao/kanban/home.cfm");
    const browser = read("administracao/kanban/assets/kanban.js");

    for (const tab of ["details", "checklists", "attachments", "activity", "custom-fields", "advanced"]) {
        assert.match(home, new RegExp(`data-kanban-tab="${tab}"`));
    }
    for (const action of [
        "card_details", "archived_cards", "board_lists", "duplicate_card", "transfer_card", "delete_card", "create_label",
        "create_checklist", "update_checklist", "delete_checklist", "add_check_item",
        "update_check_item", "delete_check_item", "add_attachment_url", "add_attachment_file",
        "delete_attachment", "set_attachment_cover", "update_comment", "delete_comment",
        "update_custom_field"
    ]) {
        assert.match(api, new RegExp(`action EQ "${action}"`));
        assert.match(browser, new RegExp(`\\b${action}\\b`));
    }
    assert.match(api, /start = kanbanDateValue/);
    assert.match(api, /itemParams\.dueReminder/);
    assert.match(browser, /due_reminder: reminder\.value/);
    assert.match(api, /subscribed/);
    assert.match(api, /coordinatesValue = kanbanCoordinates/);
    assert.match(api, /if \(len\(coordinatesValue\)\) \{[\s\S]*?\.coordinates = coordinatesValue/);
    assert.doesNotMatch(api, /coordinates\s*=\s*kanbanCoordinates/);
    assert.match(api, /idLabels = kanbanAssertIdsOnBoard/);
    assert.match(browser, /moveCard\(cardId, listId, position\)/);
});

test("Advanced card mutations retain scope, upload, and destructive-action safeguards", () => {
    const api = read("administracao/kanban/api.cfm");
    const service = read("administracao/kanban/includes/trello_service.cfm");

    assert.match(api, /function kanbanAssertChecklistOnCard/);
    assert.match(api, /function kanbanAssertCommentOnCard/);
    assert.match(api, /function kanbanAssertCustomFieldOnBoard/);
    assert.match(api, /ForbiddenCustomFieldOption/);
    assert.match(api, /compare\(kanbanInput\("confirmation", 32\), "EXCLUIR"\)/);
    assert.match(api, /fileSize\) GT 10485760/);
    assert.match(api, /blockedExtensions/);
    assert.match(api, /finally \{[\s\S]*fileDelete\(uploadedFilePath\)/);
    assert.match(service, /function kanbanTrelloFileRequest/);
    assert.match(service, /multipart = true/);
    assert.match(service, /application\/json; charset=UTF-8/);
    assert.doesNotMatch(service, /apiToken[^\n]*(?:cflog|writeOutput|serializeJSON)/i);
});

test("Admin navigation exposes the Kanban module", () => {
    const sidenav = read("includes/estrutura/sidenav.cfm");

    assert.match(sidenav, /href="\/administracao\/kanban\/"/);
    assert.match(sidenav, />Kanban</);
});
