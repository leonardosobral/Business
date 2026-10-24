const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const script = path.resolve(__dirname, '../../assets/js/business-shell.js');

function mount({height = 58.6, observer = true, shell = true} = {}) {
    const properties = new Map(), events = new Map();
    let notify = () => {}, measuredHeight = height;
    const navbar = {getBoundingClientRect: () => ({height: measuredHeight})};
    const header = {style: {setProperty: (name, value) => properties.set(name, value)},
        querySelector: selector => selector === '#main-navbar' ? navbar : null};
    const window = {addEventListener: (name, callback) => events.set(name, callback)};
    if (observer) window.ResizeObserver = class {
        constructor(callback) { notify = callback; }
        observe(element) { assert.equal(element, navbar); }
    };
    vm.runInNewContext(fs.existsSync(script) ? fs.readFileSync(script, 'utf8') : '', {
        document: {querySelector: selector => shell && selector === '.business-shell-header' ? header : null},
        window
    });
    return {properties, change(value) { measuredHeight = value; notify(); },
        resize(value) { measuredHeight = value; events.get('resize')?.(); }};
}

test('reserves the measured navbar height instead of the decorative header height', () => {
    const app = mount();
    assert.equal(app.properties.get('--business-navbar-height'), '59px');
});
test('follows navbar wrapping and font changes without a viewport resize', () => {
    const app = mount();
    app.change(95.2);
    assert.equal(app.properties.get('--business-navbar-height'), '96px');
    app.change(58);
    assert.equal(app.properties.get('--business-navbar-height'), '58px');
});
test('viewport resize still updates the reserve without ResizeObserver', () => {
    const app = mount({observer: false});
    app.resize(81);
    assert.equal(app.properties.get('--business-navbar-height'), '81px');
});
test('a temporarily hidden navbar does not collapse the last valid reserve', () => {
    const app = mount();
    app.change(0);
    assert.equal(app.properties.get('--business-navbar-height'), '59px');
});
test('standalone pages without the shared shell remain untouched', () => {
    assert.equal(mount({shell: false}).properties.size, 0);
});
