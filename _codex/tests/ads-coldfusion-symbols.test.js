const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

test("does not shadow a ColdFusion function with the variable receiving its result", () => {
    const templatePath = path.join(
        __dirname,
        "../../ads/includes/workspace_campaign_form.cfm"
    );
    const source = fs.readFileSync(templatePath, "utf8");
    const assignmentWithCall = /<cfset\s+(?:VARIABLES\.)?([A-Za-z][A-Za-z0-9_]*)\s*=\s*([A-Za-z][A-Za-z0-9_]*)\s*\(/gi;
    const collisions = [];
    let match = assignmentWithCall.exec(source);

    while (match) {
        if (match[1].toLowerCase() === match[2].toLowerCase()) {
            collisions.push(match[1]);
        }
        match = assignmentWithCall.exec(source);
    }

    assert.deepEqual(
        collisions,
        [],
        "a VARIABLES name shadows the case-insensitive function called on the right-hand side"
    );
});
