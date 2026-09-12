'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '../..');
const drive = require(path.join(root, 'administracao/drive/assets/drive.js'));

test('formats Drive item types and sizes', () => {
    assert.equal(drive.isFolder({mimeType: 'application/vnd.google-apps.folder'}), true);
    assert.equal(drive.isGoogleNative({mimeType: 'application/vnd.google-apps.document'}), true);
    assert.equal(drive.isGoogleNative({mimeType: 'application/pdf'}), false);
    assert.equal(drive.formatBytes(0), '0 B');
    assert.equal(drive.formatBytes(1536), '1.5 KB');
    assert.equal(drive.formatBytes(undefined), '—');
});

test('opens only HTTPS links hosted by Google', () => {
    assert.equal(drive.safeGoogleUrl('https://drive.google.com/drive/folders/abc'), 'https://drive.google.com/drive/folders/abc');
    assert.equal(drive.safeGoogleUrl('https://docs.google.com/document/d/abc'), 'https://docs.google.com/document/d/abc');
    assert.equal(drive.safeGoogleUrl('http://drive.google.com/drive/folders/abc'), '');
    assert.equal(drive.safeGoogleUrl('https://drive.google.com.evil.test/file'), '');
    assert.equal(drive.safeGoogleUrl('javascript:alert(1)'), '');
});

test('normalizes Picker file IDs without accepting paths or oversized selections', () => {
    assert.deepEqual(drive.normalizePickerIds([' abc_123 ', 'abc_123', '../secret', '', 'folder-9']), ['abc_123', 'folder-9']);
    assert.equal(drive.normalizePickerIds(Array.from({length: 120}, (_, index) => `file_${index}`)).length, 100);
});

test('Drive backend is admin-only, CSRF-protected and root-scoped', () => {
    const api = fs.readFileSync(path.join(root, 'administracao/drive/api.cfm'), 'utf8');
    const download = fs.readFileSync(path.join(root, 'administracao/drive/download.cfm'), 'utf8');
    const service = fs.readFileSync(path.join(root, 'administracao/drive/includes/service.cfm'), 'utf8');
    const browser = fs.readFileSync(path.join(root, 'administracao/drive/assets/drive.js'), 'utf8');
    const application = fs.readFileSync(path.join(root, 'Application.cfc'), 'utf8');
    const callback = fs.readFileSync(path.join(root, 'administracao/agenda/oauth/callback.cfm'), 'utf8');
    const schema = fs.readFileSync(path.join(root, 'administracao/drive/drive_schema.sql'), 'utf8');
    const index = fs.readFileSync(path.join(root, 'administracao/drive/index.cfm'), 'utf8');

    assert.match(api, /require_admin\.cfm/);
    assert.match(download, /require_admin\.cfm/);
    assert.match(service, /CGI\.request_method!="POST"/);
    assert.match(service, /compare\(form\.csrf_token,session\.driveCsrf\)/);
    assert.match(service, /function driveAssertInside/);
    assert.match(service, /function driveListWithoutQuery/);
    assert.match(service, /cfhttpparam\(type="url",name=key/);
    assert.match(service, /findNoCase\("parâmetro q",queryError\.message/);
    assert.match(service, /current\.id==root\.id/);
    assert.match(service, /application\/vnd\.google-apps\.folder/);
    assert.match(service, /"pageSize"=100/);
    assert.match(service, /params\["pageToken"\]/);
    assert.match(service, /capabilities\/canDownload/);
    assert.match(service, /capabilities\/canTrash/);
    assert.doesNotMatch(service, /capabilities\(can/);
    assert.match(api, /fileUpload\(getTempDirectory\(\),"upload_file"/);
    assert.match(api, /driveConfig\(\)\.maxUploadBytes/);
    assert.match(api, /blocked="cfm,cfc,cfml/);
    assert.match(api, /action=="authorize_picker"[\s\S]*driveAssertInside\(pickedId\)/);
    assert.match(api, /arrayLen\(pickedIds\)>100/);
    assert.ok(application.includes('https://www.googleapis.com/auth/drive.file'));
    assert.match(application, /RR_GOOGLE_DRIVE_PICKER_API_KEY/);
    assert.match(application, /RR_GOOGLE_DRIVE_APP_ID/);
    assert.ok(callback.includes('https://www.googleapis.com/auth/drive.file'));
    assert.match(schema, /tb_google_drive_auditoria/);
    assert.match(index, /id="drivePicker"/);
    assert.match(index, /data-picker-client-id/);
    assert.match(index, /data-picker-api-key/);
    assert.match(index, /data-picker-app-id/);
    assert.match(browser, /\.textContent = item\.name/);
    assert.match(browser, /accounts\.oauth2\.initTokenClient/);
    assert.match(browser, /include_granted_scopes: false/);
    assert.match(browser, /scope: DRIVE_FILE_SCOPE/);
    assert.match(browser, /\.setParent\(state\.folderId\)/);
    assert.match(browser, /\.setDeveloperKey\(pickerConfig\.apiKey\)/);
    assert.match(browser, /\.setAppId\(pickerConfig\.appId\)/);
    assert.match(browser, /\.setOAuthToken\(token\)/);
    assert.match(browser, /\.setOrigin\(window\.location\.origin\)/);
    assert.match(browser, /request\("authorize_picker"/);
    assert.doesNotMatch(browser, /innerHTML\s*=/);
    assert.doesNotMatch(browser, /localStorage|sessionStorage/);
});
