const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

test("recognizes direct HTTPS requests before persisting uploaded banner URLs", () => {
    const backendPath = path.join(
        __dirname,
        "../../portal/includes/banner_management_backend.cfm"
    );
    const source = fs.readFileSync(backendPath, "utf8");
    const baseUrlFunction = source.match(
        /function\s+bannerManagementBuildBaseUrl\s*\(\)\s*\{([\s\S]*?)\n\}/i
    );

    assert.ok(baseUrlFunction, "banner base URL builder must exist");
    assert.match(
        baseUrlFunction[1],
        /server_port_secure|server_port[^\n]*443/i,
        "direct TLS requests must produce HTTPS asset URLs even when CGI.https is empty"
    );
});

test("normalizes uploaded filenames before building public banner URLs", () => {
    const backendPath = path.join(
        __dirname,
        "../../portal/includes/banner_management_backend.cfm"
    );
    const source = fs.readFileSync(backendPath, "utf8");

    assert.match(
        source,
        /function\s+bannerManagementSafeUploadName\s*\(/i,
        "browser filenames may contain spaces, commas and accents"
    );
    assert.doesNotMatch(
        source,
        /bannerUploadWebRoot\s*&\s*banner(?:Desktop|Mobile)UploadResult\.serverFile/i,
        "the original browser filename must not become part of the public URL"
    );
    assert.doesNotMatch(
        source,
        /<cfloop\s+list="#[^"]*bannerDesktopUploadedServerFile[^\n]*bannerMobileUploadedServerFile/i,
        "cleanup must not split uploaded filenames on commas"
    );
});
