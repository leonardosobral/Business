const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const read = file => fs.readFileSync(path.resolve(__dirname, '../..', file), 'utf8');
const backend = read('percursos/includes/backend.cfm');
const home = read('percursos/home.cfm');
const migration = read('_codex/sql/2026-09-07_percursos_gestao_plataforma.sql');

// Contract tests: evaluate the actual boolean guards and render conditional SQL.
// This deliberately does not claim to replace a ColdFusion/PostgreSQL integration test.
function evaluate(expression, VARIABLES, qPercurso = {}) {
    const js = expression
        .replace(/\bAND\b/gi, '&&').replace(/\bOR\b/gi, '||')
        .replace(/\bNOT\b/gi, '!').replace(/\bNEQ\b/gi, '!=')
        .replace(/\bEQ\b/gi, '==').replace(/\bGT\b/gi, '>')
        .replace(/(?<!&)&(?!&)/g, '+');
    return Boolean(Function('VARIABLES', 'qPercurso', 'len', 'listFind', `return (${js});`)(
        VARIABLES, qPercurso, value => String(value).length,
        (list, item) => String(list).split(',').indexOf(String(item)) + 1
    ));
}

function guard(name, variables, route, source = backend) {
    const match = [...source.matchAll(new RegExp(`<cfset VARIABLES\\.${name}\\s*=([\\s\\S]*?)/>`, 'g'))]
        .find(candidate => candidate[1].trim() !== 'false');
    assert.ok(match, `guard ${name} exists`);
    return evaluate(match[1], variables, route);
}

function query(name, variables) {
    const match = backend.match(new RegExp(`<cfquery name="${name}">([\\s\\S]*?)</cfquery>`));
    assert.ok(match, `query ${name} exists`);
    const parts = match[1].split(/(<cfif\s+[^>]+>|<cfelse\s*>|<\/cfif>)/gi);
    const stack = [];
    let output = '';
    for (const part of parts) {
        if (/^<cfif\s/i.test(part)) {
            stack.push(evaluate(part.replace(/^<cfif\s+|>$/gi, ''), variables));
        } else if (/^<cfelse/i.test(part)) {
            stack[stack.length - 1] = !stack.at(-1);
        } else if (/^<\/cfif>/i.test(part)) {
            stack.pop();
        } else if (stack.every(Boolean)) output += part;
    }
    assert.equal(stack.length, 0);
    return output;
}

const base = {
    percursoIsSystemAdmin: false, percursoIsAdmin: false,
    percursoActiveAccountId: 0, percursoWriteAccountIds: '0',
    percursoManagerAccountIds: '0', percursoPlatformOwnershipReady: true,
    percursoHasOwnerAccount: false, percursoIsPlatformOwned: false,
    percursoHasManagedOwnership: false, percursoHasManagerAccount: false,
    percursoCanManageRouteEventLinks: false, percursoCanManageEventLinks: false,
};

test('global admin can create without an active account, including simulated context', () => {
    assert.equal(guard('percursoCanCreate', {...base, percursoIsSystemAdmin: true}), true);
    assert.equal(guard('percursoCanCreate', {...base, percursoIsSystemAdmin: true,
        percursoActiveAccountId: 30, percursoIsAdmin: false}), true);
    assert.match(backend, /percursoCanCreate = VARIABLES\.percursoCanCreate AND VARIABLES\.percursoStorageReady/);
});

test('ordinary users still require operational membership of the active account', () => {
    for (const [active, writable, expected] of [[0, '0', false], [3, '0', false],
        [3, '4', false], [3, '3', true], [3, '2,3', true]]) {
        assert.equal(guard('percursoCanCreate', {...base,
            percursoActiveAccountId: active, percursoWriteAccountIds: writable}), expected);
    }
    assert.equal(guard('percursoCanCreate', {...base, percursoIsDev: true}), false);
});

test('ownership resolver refuses forged platform/foreign account choices and inactive accounts', () => {
    const resolver = backend.slice(backend.indexOf('function percursoResolveOwnership'),
        backend.indexOf('function percursoHasEventRouteColumn'));
    assert.match(resolver, /if \(NOT VARIABLES\.percursoIsSystemAdmin\)/);
    assert.match(resolver, /NOT VARIABLES\.percursoPlatformOwnershipReady/);
    assert.match(resolver, /selected NEQ VARIABLES\.percursoActiveAccountId/);
    assert.match(resolver, /NOT listFind\(VARIABLES\.percursoWriteAccountIds, selected\)/);
    assert.match(resolver, /status='ATIVA'::status_conta/);
    assert.match(backend, /uploadOwnership = percursoResolveOwnership\(VARIABLES\.percursoOwnerSelection\)/);
    const processingStart = backend.search(/VARIABLES\.uploadTempDir\s*=/);
    assert.ok(processingStart > backend.indexOf('NOT VARIABLES.uploadOwnership.valid'));
    assert.ok(backend.indexOf('compareNoCase(trim(FORM.csrf_token)') < backend.indexOf('FORM.acao EQ "alterar_conta_proprietaria"'));
});

test('platform routes remain editable by global admin, not event managers or pending legacy creators', () => {
    const admin = {...base, percursoIsSystemAdmin: true, percursoHasManagedOwnership: true};
    assert.equal(guard('routeCanEdit', admin, {id_conta_responsavel: ''}, home), true);
    assert.equal(guard('routeCanEdit', {...base, percursoHasManagedOwnership: true,
        percursoWriteAccountIds: '3'}, {id_conta_responsavel: ''}, home), false);
    assert.equal(guard('routeCanEdit', {...admin, percursoHasManagedOwnership: false},
        {id_conta_responsavel: ''}, home), false);
    assert.equal(guard('routeCanEdit', {...base, percursoWriteAccountIds: '3'},
        {id_conta_responsavel: 3}, home), true);
});

test('global admin may manage platform links; common account roles do not gain that power', () => {
    const admin = {...base, percursoIsSystemAdmin: true, percursoHasManagedOwnership: true};
    assert.equal(guard('percursoCanLinkEvents', admin), true);
    assert.equal(guard('percursoCanManageEventLinks', admin), true);
    const manager = {...base, percursoHasManagedOwnership: true, percursoHasManagerAccount: true,
        percursoWriteAccountIds: '3', percursoCanManageEventLinks: true};
    assert.equal(guard('percursoCanLinkEvents', manager), false);
    assert.equal(guard('percursoCanManageEventLinks', manager), false);
    assert.equal(guard('percursoCanLinkEvents', {...admin, percursoHasManagedOwnership: false}), false);
    assert.match(home, /percursoIsSystemAdmin AND VARIABLES\.percursoHasManagedOwnership\)\s*OR \(VARIABLES\.percursoHasOwnerAccount/);
});

test('every route write lookup permits explicit platform ownership only for global admin', () => {
    for (const name of ['qPercursoEventLinkRouteCheck', 'qVersionActionSource',
        'qPercursoUploadAllowed', 'qSaveAllowed']) {
        const admin = query(name, {...base, percursoIsSystemAdmin: true});
        assert.match(admin, /OR (?:percurso\.)?gestao_plataforma = true/);
        assert.doesNotMatch(admin, /id_conta_responsavel IN/);
        const member = query(name, {...base, percursoWriteAccountIds: '3'});
        assert.doesNotMatch(member, /OR (?:percurso\.)?gestao_plataforma = true/);
        assert.match(member, /id_conta_responsavel IN/);
        const oldSchema = query(name, {...base, percursoIsSystemAdmin: true,
            percursoPlatformOwnershipReady: false});
        assert.doesNotMatch(oldSchema, /gestao_plataforma/);
    }
});

test('event search and link validation do not require an organizer for global admin', () => {
    for (const name of ['qPercursoEventSearch', 'qPercursoEventLinkEventCheck']) {
        const admin = query(name, {...base, percursoIsSystemAdmin: true});
        const adminFrom = admin.slice(admin.indexOf('FROM tb_evento_corridas_percursos modalidade'));
        assert.doesNotMatch(adminFrom, /tb_conta_eventos|AND EXISTS/);
        assert.match(query(name, base), /AND EXISTS[\s\S]*tb_conta_eventos/);
    }
    assert.match(query('qPercursoEventLinkEventCheck', base), /modalidade\.id_evento = <cfqueryparam/);
    assert.match(backend, /FOR UPDATE OF modalidade/);
    assert.match(backend, /NOT VARIABLES\.eventLinkConfirmedReplacement/);
});

test('new platform INSERT uses NULL owner, explicit scope, private visibility and real author', () => {
    const insert = query('qNewPercurso', base);
    assert.match(insert, /id_conta_responsavel,gestao_plataforma/);
    assert.match(insert, /value="#VARIABLES\.uploadAccountId#" null="#VARIABLES\.uploadPlatformOwnership#"/);
    assert.match(insert, /value="privado"/);
    assert.match(insert, /value="#VARIABLES\.percursoActorId#"/);
    assert.doesNotMatch(query('qNewPercurso', {...base, percursoPlatformOwnershipReady: false}), /gestao_plataforma/);
    assert.match(backend, /"atribuir_propriedade",[\s\S]*gestao_plataforma=VARIABLES\.uploadPlatformOwnership/);
});

test('platform-to-account transfer resets scope, locks ownership and preserves authorship/links', () => {
    const transfer = backend.slice(backend.indexOf('<cfelseif FORM.acao EQ "alterar_conta_proprietaria">'),
        backend.indexOf('<cfelseif listFindNoCase("vincular_evento,desvincular_evento"'));
    assert.match(transfer, /NOT VARIABLES\.percursoIsSystemAdmin/);
    assert.match(transfer, /<cftransaction>[\s\S]*FOR UPDATE[\s\S]*UPDATE tb_percursos[\s\S]*percursoAudit[\s\S]*<\/cftransaction>/);
    assert.match(transfer, /gestao_plataforma = <cfqueryparam[^>]+value="#VARIABLES\.ownerSelection.platform#"/);
    assert.match(transfer, /gestao_plataforma_anterior[\s\S]*gestao_plataforma_nova/);
    assert.doesNotMatch(transfer, /SET id_usuario_criador|UPDATE tb_evento|DELETE FROM/);
});

test('platform scope cannot use the legacy creator exception in read or elevation endpoints', () => {
    for (const source of [backend, read('percursos/geometry.cfm'), read('percursos/download.cfm')]) {
        const legacyChecks = [...source.matchAll(/(?:p\.|percurso\.)?id_conta_responsavel IS NULL\s*\n\s*AND NOT coalesce\(\(to_jsonb\(/g)];
        assert.ok(legacyChecks.length > 0);
        assert.match(source, /tb_conta_eventos/); // event-derived read access remains
    }
    assert.match(backend, /percursoIsLegacyCreator = [^\n]*NOT VARIABLES\.percursoIsPlatformOwned/);
});

test('migration preserves legacy pending rows and enforces exactly one ownership type', () => {
    assert.match(migration, /ADD COLUMN IF NOT EXISTS gestao_plataforma boolean NOT NULL DEFAULT false/);
    assert.match(migration, /ALTER COLUMN id_conta_responsavel DROP NOT NULL/);
    assert.match(migration, /DROP CONSTRAINT IF EXISTS tb_percursos_conta_proprietaria_nn/);
    assert.match(migration, /\) NOT VALID/);
    assert.doesNotMatch(migration, /UPDATE public\.tb_percursos|DELETE FROM|DROP TABLE/);
    const ownershipCheck = /\(gestao_plataforma AND id_conta_responsavel IS NULL\)\s*OR \(NOT gestao_plataforma AND id_conta_responsavel IS NOT NULL\)/;
    assert.match(migration, ownershipCheck);
    assert.match(read('percursos/percursos_schema.sql'), ownershipCheck);
});

test('UI differentiates platform, account and legacy ownership and guides the second step', () => {
    assert.match(home, /id="route-create-owner"/);
    assert.match(home, /value="plataforma"/);
    assert.match(home, /Gestão da plataforma/);
    assert.match(home, /Percurso legado pendente de atribuição/);
    assert.match(home, /id="vinculos-eventos"/);
    assert.match(home, /action="\.\/#vinculos-eventos"/);
    assert.match(backend, /chr\(35\) & "vinculos-eventos"/);
    assert.match(home, /2026-09-07_percursos_gestao_plataforma.sql/);
});

test('changed CFML templates preserve nesting of paired control tags', () => {
    for (const file of ['percursos/includes/backend.cfm', 'percursos/home.cfm',
        'percursos/download.cfm', 'percursos/geometry.cfm']) {
        const source = read(file).replace(/<!---[\s\S]*?--->/g, '').replace(/<cfscript>[\s\S]*?<\/cfscript>/gi, '');
        const stack = [];
        for (const tag of source.matchAll(/<(\/?)(cfif|cfquery|cfloop|cfoutput|cftry|cfcatch|cftransaction|cflock)\b[^>]*>/gi)) {
            if (tag[0].endsWith('/>')) continue;
            if (tag[1]) assert.equal(stack.pop(), tag[2].toLowerCase(), `${file}: ${tag[0]}`);
            else stack.push(tag[2].toLowerCase());
        }
        assert.deepEqual(stack, [], file);
    }
});
