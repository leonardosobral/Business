const test = require("node:test");
const assert = require("node:assert/strict");

const eventRequestPanel = require("../../assets/js/event-request-panel.js");

function createPanel() {
    let scrollOptions = null;
    let inputFocused = false;
    const input = {
        focus() {
            inputFocused = true;
        }
    };
    const panel = {
        tagName: "DETAILS",
        open: false,
        querySelector(selector) {
            return selector === '[name="evento_referencia"]' ? input : null;
        },
        scrollIntoView(options) {
            scrollOptions = options;
        }
    };

    return {
        panel,
        wasFocused() {
            return inputFocused;
        },
        scrollOptions() {
            return scrollOptions;
        }
    };
}

test("opens the collapsed request panel, scrolls to it and focuses the event search", () => {
    const fixture = createPanel();

    assert.equal(eventRequestPanel.open(fixture.panel), true);
    assert.equal(fixture.panel.open, true);
    assert.deepEqual(fixture.scrollOptions(), { behavior: "smooth", block: "start" });
    assert.equal(fixture.wasFocused(), true);
});

test("opens the request panel on initial load when its hash is present", () => {
    const fixture = createPanel();
    let readyHandler = null;
    const fakeDocument = {
        readyState: "loading",
        addEventListener(eventName, handler) {
            if (eventName === "DOMContentLoaded") {
                readyHandler = handler;
            }
        },
        getElementById(id) {
            return id === "event-request-panel" ? fixture.panel : null;
        }
    };
    const fakeWindow = {
        location: { hash: "#event-request-panel" }
    };

    eventRequestPanel.init(fakeDocument, fakeWindow);
    assert.equal(fixture.panel.open, false);

    readyHandler();
    assert.equal(fixture.panel.open, true);
    assert.equal(fixture.wasFocused(), true);
});

test("a request CTA opens the panel without navigating away", () => {
    const fixture = createPanel();
    let clickHandler = null;
    let prevented = false;
    let resultingUrl = null;
    const anchor = {
        getAttribute(name) {
            return name === "href" ? "/eventos/#event-request-panel" : null;
        }
    };
    const fakeDocument = {
        readyState: "complete",
        addEventListener(eventName, handler) {
            if (eventName === "click") {
                clickHandler = handler;
            }
        },
        getElementById(id) {
            return id === "event-request-panel" ? fixture.panel : null;
        }
    };
    const fakeWindow = {
        location: {
            hash: "",
            pathname: "/eventos/",
            search: ""
        },
        history: {
            replaceState(_state, _title, url) {
                resultingUrl = url;
            }
        }
    };

    eventRequestPanel.init(fakeDocument, fakeWindow);
    clickHandler({
        target: {
            closest(selector) {
                return selector === 'a[href$="#event-request-panel"]' ? anchor : null;
            }
        },
        preventDefault() {
            prevented = true;
        }
    });

    assert.equal(prevented, true);
    assert.equal(fixture.panel.open, true);
    assert.equal(resultingUrl, "/eventos/#event-request-panel");
});
