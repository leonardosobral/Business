'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '../..');
const meet = require(path.join(root, 'assets/js/business-meet-room.js'));

test('accepts only canonical Google Meet room links', () => {
    assert.equal(meet.safeMeetingUri('https://meet.google.com/abc-defg-hij'), 'https://meet.google.com/abc-defg-hij');
    assert.equal(meet.safeMeetingUri('https://meet.google.com/abc-defg-hij/?authuser=1'), 'https://meet.google.com/abc-defg-hij');
    assert.equal(meet.safeMeetingUri('http://meet.google.com/abc-defg-hij'), '');
    assert.equal(meet.safeMeetingUri('https://meet.google.com.evil.test/abc-defg-hij'), '');
    assert.equal(meet.safeMeetingUri('https://meet.google.com/lookup/team-room'), '');
});

test('renders all presence states and keeps participant names as plain values', () => {
    assert.equal(meet.viewModel({success: true, configured: false}).badge, 'Configuração pendente');
    assert.equal(meet.viewModel({success: true, configured: true, connected: false}).badge, 'Google desconectado');
    assert.equal(meet.viewModel({success: true, configured: true, connected: true, active: false}).badge, 'Sala vazia');

    const active = meet.viewModel({
        success: true,
        configured: true,
        connected: true,
        active: true,
        participantCount: 2,
        participants: [{displayName: 'Zoe'}, {displayName: '<img src=x onerror=alert(1)>'}]
    });
    assert.equal(active.badge, 'Sala ativa');
    assert.equal(active.summary, '2 pessoas conectadas agora.');
    assert.deepEqual(active.people, ['<img src=x onerror=alert(1)>', 'Zoe']);
    assert.equal(meet.participantLabel({displayName: '  Ana  '}), 'Ana');
    assert.equal(meet.participantLabel({}), 'Participante');
});

test('accepts JSON keys normalized to uppercase by CFML engines', () => {
    const state = meet.viewModel({
        SUCCESS: true,
        CONFIGURED: true,
        CONNECTED: true,
        ACTIVE: true,
        PARTICIPANTCOUNT: 1,
        PARTICIPANTS: [{DISPLAYNAME: 'Ana'}]
    });
    assert.equal(state.badge, 'Sala ativa');
    assert.equal(state.summary, '1 pessoa conectada agora.');
    assert.deepEqual(state.people, ['Ana']);

    const error = meet.viewModel({SUCCESS: false, MESSAGE: 'Permissão negada.'});
    assert.equal(error.summary, 'Permissão negada.');
});

test('builds compact, deterministic participant avatars', () => {
    assert.equal(meet.participantInitials('Ana Beatriz'), 'AB');
    assert.equal(meet.participantInitials('  Carlos  '), 'CA');
    assert.equal(meet.participantInitials(''), '?');
    assert.equal(meet.participantTone('Ana'), meet.participantTone('Ana'));
    assert.ok(meet.participantTone('Ana') >= 0 && meet.participantTone('Ana') <= 4);
});

test('keeps the Meet endpoint admin-only, read-only and non-cacheable', () => {
    const endpoint = fs.readFileSync(path.join(root, 'administracao/meet/status.cfm'), 'utf8');
    const service = fs.readFileSync(path.join(root, 'administracao/meet/includes/service.cfm'), 'utf8');
    const browser = fs.readFileSync(path.join(root, 'assets/js/business-meet-room.js'), 'utf8');
    const dashboard = fs.readFileSync(path.join(root, 'includes/estrutura/home_admin_dashboard.cfm'), 'utf8');
    const navbar = fs.readFileSync(path.join(root, 'includes/estrutura/navbar.cfm'), 'utf8');

    assert.match(endpoint, /require_admin\.cfm/);
    assert.match(endpoint, /CGI\.request_method != "GET"/);
    assert.match(endpoint, /Cache-Control", value="no-store"/);
    assert.doesNotMatch(service, /\b(?:INSERT|UPDATE|DELETE)\b/i);
    assert.match(service, /meetRoomParticipantIsActive/);
    assert.match(service, /latestEndTime/);
    assert.match(service, /\{"pageSize"=250\}/);
    assert.match(service, /params\["pageToken"\]/);
    assert.match(service, /activeConference/);
    assert.ok(service.includes('^/(spaces/[a-z-]+|conferenceRecords/'));
    assert.match(browser, /item\.textContent = name/);
    assert.match(dashboard, /data-status-url="\/administracao\/meet\/status\.cfm"/);
    assert.ok(navbar.indexOf('id="businessMeetTopbar"') < navbar.indexOf('id="navbarDropdownNotifications"'));
    assert.match(navbar, /id="businessMeetTopbarAvatars"/);
    assert.match(navbar, /business-meet-room\.js\?v=2026091004/);
    assert.doesNotMatch(dashboard, /business-meet-room\.js/);
    assert.match(dashboard, /<button[^>]+id="businessMeetJoin"/);
    assert.doesNotMatch(dashboard, /businessMeetPopup|businessMeetPip|picture-in-picture|Como usar PiP/);
    assert.match(navbar, /<button[^>]+class="nav-link business-meet-topbar-link disabled"[^>]+id="businessMeetTopbarJoin"/);
    assert.match(browser, /dashboard\.join\.addEventListener\('click', openMeetingWindow\)/);
    assert.match(browser, /topbar\.join\.addEventListener\('click', openMeetingWindow\)/);
    assert.match(browser, /window\.open\(meetingUri, 'runnerhub-team-room'/);
});

test('requests the Meet read-only OAuth scope and enforces it on callback', () => {
    const application = fs.readFileSync(path.join(root, 'Application.cfc'), 'utf8');
    const callback = fs.readFileSync(path.join(root, 'administracao/agenda/oauth/callback.cfm'), 'utf8');
    const scope = 'https://www.googleapis.com/auth/meetings.space.readonly';

    assert.ok(application.includes(scope));
    assert.ok(callback.includes(scope));
});
