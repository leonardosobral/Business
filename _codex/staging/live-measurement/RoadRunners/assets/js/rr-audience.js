/* First-party audience metrics. Independent from Ads accounting endpoints. */
(function (window, document) {
    'use strict';
    if (window.RoadRunnersAudience) return;
    var config = window.RoadRunnersAudienceConfig;
    if (!config || !config.context || !config.contextToken || !config.signature) return;
    var memory = {}, pending = new Map(), known = new Set(), states = new Map(), contentStates = new Map(), contexts = new Map(), opportunities = new Map(), eventSessions = new Map();
    var intersectionRatios = new WeakMap(), observedSlots = new WeakSet(), observedContents = new WeakSet(), intersectionObserver;
    var sending = false, retries = 0, retryAfterUntil = 0, activeMs = 0, pageStarted = false, collectionStopped = false, lastTick = now(), lastInput = now();
    var visitor, session;
    var VISITOR_TTL_MS = 90 * 24 * 60 * 60 * 1000;
    function now() { return window.performance.now(); }
    function get(key) { try { return window.localStorage.getItem(key) || memory[key] || ''; } catch (_) { return memory[key] || ''; } }
    function put(key, value) { memory[key] = value; try { window.localStorage.setItem(key, value); } catch (_) {} }
    function remove(key) { delete memory[key]; try { window.localStorage.removeItem(key); } catch (_) {} }
    function clearAudienceState() {
        collectionStopped = true;
        pending.clear(); known.clear(); states.clear(); contentStates.clear(); contexts.clear(); opportunities.clear(); eventSessions.clear();
        remove('rr-audience-visitor'); remove('rr-audience-visitor-created'); remove('rr-audience-session');
        visitor = ''; session = null;
    }
    function optedOut() {
        var cookies = '';
        try { cookies = document.cookie || ''; } catch (_) {}
        return window.navigator.globalPrivacyControl === true || /^(1|true|yes)$/i.test(get('rr-audience-opt-out'))
            || /(?:^|;\s*)rr-audience-opt-out=(?:1|true|yes)(?:;|$)/i.test(cookies);
    }
    function collectionBlocked() { return collectionStopped || optedOut(); }
    window.addEventListener('rr-audience-preference', function (event) {
        if (event && event.detail && event.detail.allowed === false) clearAudienceState();
    });
    window.addEventListener('storage', function (event) {
        if (event && event.key === 'rr-audience-opt-out' && /^(1|true|yes)$/i.test(event.newValue || '')) clearAudienceState();
    });
    if (optedOut()) { clearAudienceState(); return; }
    if (!window.crypto || !window.crypto.getRandomValues) return;
    function uuid() {
        if (window.crypto.randomUUID) return window.crypto.randomUUID();
        var b = new Uint8Array(16); window.crypto.getRandomValues(b); b[6] = (b[6] & 15) | 64; b[8] = (b[8] & 63) | 128;
        var h = Array.from(b, function (n) { return n.toString(16).padStart(2, '0'); }).join('');
        return h.slice(0, 8) + '-' + h.slice(8, 12) + '-' + h.slice(12, 16) + '-' + h.slice(16, 20) + '-' + h.slice(20);
    }
    function validId(value) { return /^[a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i.test(value); }
    function label(value, limit) { return String(value || '').replace(/[^a-zA-Z0-9_.-]/g, '').slice(0, limit || 100); }
    function attribution(value) { value = String(value || ''); return /[@:/?=]|%40/i.test(value) || /[0-9]{11}/.test(value.replace(/[.\s-]/g, '')) ? '' : label(value); }
    visitor = get('rr-audience-visitor');
    var visitorCreated = Number(get('rr-audience-visitor-created'));
    var visitorNow = Date.now();
    if (!validId(visitor) || !Number.isFinite(visitorCreated) || visitorCreated <= 0
        || visitorCreated > visitorNow || visitorNow - visitorCreated >= VISITOR_TTL_MS) {
        visitor = uuid(); visitorCreated = visitorNow;
        put('rr-audience-visitor', visitor); put('rr-audience-visitor-created', String(visitorCreated));
    }
    try { session = JSON.parse(get('rr-audience-session')); } catch (_) {}
    var newSession = !session || !validId(session.id) || Date.now() - Number(session.at) > 1800000 || Number(session.at) > Date.now();
    var source = '', medium = '', campaign = '', creative = '', referrerHost = '';
    try {
        var url = new URL(window.location.href);
        source = attribution(url.searchParams.get('utm_source')); medium = attribution(url.searchParams.get('utm_medium'));
        campaign = attribution(url.searchParams.get('utm_campaign')); creative = attribution(url.searchParams.get('utm_content'));
        if (document.referrer) { var ref = new URL(document.referrer); if (ref.hostname !== url.hostname) referrerHost = ref.hostname.toLowerCase().slice(0, 200); }
    } catch (_) {}
    if (newSession) session = { id: uuid(), at: Date.now(), source: source || (referrerHost ? 'referral' : 'direct'), medium: medium || (referrerHost ? 'referral' : 'none'), campaign: campaign, creative: creative, referrerHost: referrerHost };
    function touchSession() {
        if (collectionBlocked() || !session) return;
        if (Date.now() - session.at > 1800000) {
            if (pageStarted) emit('page_engagement', session.id, { activeMs: Math.floor(activeMs) }, true);
            session = { id: uuid(), at: Date.now(), source: 'direct', medium: 'none', campaign: '', creative: '', referrerHost: '' };
            activeMs = 0; lastTick = now();
        }
        session.at = Date.now(); put('rr-audience-session', JSON.stringify(session));
    }
    touchSession();
    function device() { return window.innerWidth < 768 ? 'MOBILE' : window.innerWidth < 1024 ? 'TABLET' : 'DESKTOP'; }
    function emit(kind, key, data, update, envelope) {
        if (collectionBlocked()) { pending.clear(); return; }
        key = kind + ':' + key;
        key = kind.indexOf('ad_') === 0 && data && data.deliveryId ? key.slice(0, 123) + ':' + data.deliveryId : key.slice(0, 160);
        if ((!update && known.has(key)) || known.size >= 2000 || pending.size >= 200 && !pending.has(key)) return;
        known.add(key);
        if (!eventSessions.has(key)) eventSessions.set(key, Object.assign({}, session));
        var event = Object.assign({ kind: kind, key: key, deviceClass: device() }, data || {});
        Object.defineProperty(event, '_context', { value: envelope || config });
        Object.defineProperty(event, '_session', { value: eventSessions.get(key) });
        pending.set(key, event);
    }
    function retryAfterDeadline(response) {
        var value = '';
        try { value = String(response.headers.get('Retry-After') || '').trim(); } catch (_) {}
        var delay = /^\d{1,6}$/.test(value) ? Number(value) * 1000 : Date.parse(value) - Date.now();
        if (!Number.isFinite(delay) || delay <= 0) delay = 60000;
        return Date.now() + Math.min(delay, 300000);
    }
    function flush(beacon, remaining) {
        if (collectionBlocked()) { pending.clear(); return; }
        publishDurations();
        if (Date.now() < retryAfterUntil) return;
        if (!pending.size || sending) return;
        var first = pending.values().next().value, envelope = first._context, batchSession = first._session;
        var events = Array.from(pending.values()).filter(function (event) { return event._context.contextToken === envelope.contextToken && event._session.id === batchSession.id; }).slice(0, 50);
        var payload = { contextToken: envelope.contextToken, signature: envelope.signature, visitorId: visitor, sessionId: batchSession.id,
            source: attribution(batchSession.source), medium: attribution(batchSession.medium), campaign: attribution(batchSession.campaign), creative: attribution(batchSession.creative),
            referrerHost: String(batchSession.referrerHost || '').replace(/[^a-z0-9.-]/gi, '').slice(0, 200), events: events };
        var body = JSON.stringify(payload);
        // Keep below both the collector's 64 KiB cap and the browser keepalive quota.
        while (body.length > 48000 && events.length > 1) { events.pop(); body = JSON.stringify(payload); }
        if (body.length > 48000) { pending.clear(); return; }
        function accepted() { events.forEach(function (event) { if (pending.get(event.key) === event) pending.delete(event.key); }); retries = 0; retryAfterUntil = 0; }
        if (beacon !== false && window.navigator.sendBeacon) {
            try { if (window.navigator.sendBeacon(config.endpoint, body)) { accepted(); if (pending.size && (remaining || 4) > 1) flush(beacon, (remaining || 4) - 1); return; } } catch (_) {}
        }
        if (!window.fetch) return;
        sending = true;
        try {
            window.fetch(config.endpoint, { method: 'POST', body: body, credentials: 'same-origin', keepalive: true, headers: { 'Content-Type': 'application/json' } })
                .then(function (response) { if (response && Number(response.status) === 429) { retryAfterUntil = retryAfterDeadline(response); return; } if (!response.ok) throw Error('collection unavailable'); accepted(); })
                .catch(function () { retries++; if (retries >= 3) { accepted(); } })
                .then(function () { sending = false; });
        } catch (_) { sending = false; retries++; if (retries >= 3) accepted(); }
    }
    function slotApplicable(el) {
        if (!el || !el.isConnected) return false;
        var media = el.dataset.audienceMedia;
        if (media && window.matchMedia && !window.matchMedia(media).matches) return false;
        // Inventory spans are intentionally hidden even when their position is
        // applicable. Responsive ancestors, unlike the span itself, govern the
        // position's presence in this layout; a zero-sized slot still counts.
        var node = el.hidden ? el.parentElement : el;
        while (node) {
            if (window.getComputedStyle(node).display === 'none') return false;
            node = node.parentElement;
        }
        return true;
    }
    function layoutGeometry(el, requireImages) {
        if (!el || !el.isConnected || document.visibilityState !== 'visible') return { ready: false, ratio: 0 };
        var node = el, clip = { top: 0, left: 0, right: window.innerWidth, bottom: window.innerHeight };
        while (node) {
            var style = window.getComputedStyle(node);
            if (style.display === 'none' || style.visibility === 'hidden' || style.visibility === 'collapse' || Number(style.opacity) === 0) return { ready: false, ratio: 0 };
            if (node !== el) {
                var ancestor = node.getBoundingClientRect();
                if (/hidden|clip|scroll|auto/.test(style.overflowX)) { clip.left = Math.max(clip.left, ancestor.left); clip.right = Math.min(clip.right, ancestor.right); }
                if (/hidden|clip|scroll|auto/.test(style.overflowY)) { clip.top = Math.max(clip.top, ancestor.top); clip.bottom = Math.min(clip.bottom, ancestor.bottom); }
            }
            node = node.parentElement;
        }
        var rect = el.getBoundingClientRect();
        if (rect.width <= 0 || rect.height <= 0) return { ready: false, ratio: 0 };
        if (requireImages) {
            if (el.tagName === 'IMG' && (!el.complete || !el.naturalWidth)) return { ready: false, ratio: 0 };
            var images = el.querySelectorAll('img');
            for (var i = 0; i < images.length; i++) if (!images[i].complete || !images[i].naturalWidth) return { ready: false, ratio: 0 };
        }
        var width = Math.max(0, Math.min(rect.right, clip.right) - Math.max(rect.left, clip.left));
        var height = Math.max(0, Math.min(rect.bottom, clip.bottom) - Math.max(rect.top, clip.top));
        var ratio = Math.min(1, width * height / (rect.width * rect.height));
        return { ready: true, ratio: Math.floor(ratio * 10000) / 10000, rect: rect, visibleWidth: width, visibleHeight: height, visibleBottom: Math.min(rect.bottom, clip.bottom) };
    }
    function geometry(el) {
        var result = layoutGeometry(el, true);
        if (!result.ready) return result;
        var ratio = result.ratio;
        if (intersectionRatios.has(el)) ratio = Math.min(ratio, intersectionRatios.get(el));
        result.ratio = Math.floor(ratio * 10000) / 10000;
        return result;
    }
    function isAd(data) { return (data.slotState === 'filled' || data.slotState === 'house') && data.deliveryId && data.campaignId; }
    function publishDurations() {
        states.forEach(function (state, key) {
            if (state.visible && state.visible.visibleMs > (state.publishedMs || 0)) {
                emit('slot_viewable', key, state.visible, true, state.context);
                state.publishedMs = state.visible.visibleMs;
            }
            if (state.adVisible && state.adVisible.visibleMs > (state.adPublishedMs || 0)) {
                emit('ad_viewable', key, state.adVisible, true, state.context);
                state.adPublishedMs = state.adVisible.visibleMs;
            }
        });
    }
    function sampleEditorial(time) {
        contentStates.forEach(function (state, element) {
            var type = label(element.dataset.audienceContentType, 20), id = label(element.dataset.audienceContentId, 100);
            var hasMarkers = Object.prototype.hasOwnProperty.call(element.dataset, 'audienceContentType') && Object.prototype.hasOwnProperty.call(element.dataset, 'audienceContentId');
            if (!element.isConnected || !hasMarkers || !id || ['news', 'video'].indexOf(type) < 0 || state.type !== type || state.id !== id) contentStates.delete(element);
        });
        document.querySelectorAll('[data-audience-content-type][data-audience-content-id]').forEach(function (el) {
            if (intersectionObserver && !observedContents.has(el)) { observedContents.add(el); intersectionObserver.observe(el); }
            var type = label(el.dataset.audienceContentType, 20), id = label(el.dataset.audienceContentId, 100);
            if (!id || ['news', 'video'].indexOf(type) < 0) return;
            var state = contentStates.get(el);
            if (!state) { state = { type: type, id: id, since: null, visibleMs: 0, maxContinuousMs: 0, last: time }; contentStates.set(el, state); }
            if (state.type !== type || state.id !== id) {
                state.type = type; state.id = id; state.since = null; state.visibleMs = 0; state.maxContinuousMs = 0; state.last = time;
            }
            var view = geometry(el);
            if (time - state.last > 2000) state.since = null;
            if (view.ready && view.ratio >= 0.5) {
                if (state.since === null) state.since = time;
                var continuous = Math.floor(time - state.since);
                state.maxContinuousMs = Math.max(state.maxContinuousMs, continuous);
                if (continuous > 0) state.visibleMs += Math.max(0, Math.min(2000, time - state.last));
                if (state.maxContinuousMs >= 1000) emit('content_viewable', type + ':' + id, {
                    contentType: type, contentId: id, activeMs: 0, visibleMs: Math.floor(state.visibleMs),
                    maxContinuousMs: state.maxContinuousMs, ratio: view.ratio
                });
            } else state.since = null;
            state.last = time;
        });
        if (document.visibilityState !== 'visible' || config.context.contentType !== 'news') return;
        var article = document.querySelector('[data-audience-article]'), articleId = label(config.context.contentId, 100);
        if (!article || !article.isConnected || !articleId) return;
        var articleLayout = layoutGeometry(article, false), rect = articleLayout.rect;
        if (!articleLayout.ready || articleLayout.visibleWidth <= 0 || articleLayout.visibleHeight <= 0) return;
        var reached = Math.max(0, Math.min(1, (articleLayout.visibleBottom - rect.top) / rect.height));
        [0.25, 0.5, 0.75, 1].forEach(function (milestone) {
            if (reached >= milestone) emit('content_progress', 'news:' + articleId + ':' + Math.round(milestone * 100), {
                contentType: 'news', contentId: articleId, activeMs: 0, ratio: milestone
            });
        });
    }
    function sample() {
        if (collectionBlocked()) { pending.clear(); return; }
        var time = now();
        if (!pageStarted && document.visibilityState === 'visible') {
            pageStarted = true; emit('page_view', 'page');
            if (config.context.contentId) contentOpen(config.context.contentType, config.context.contentId);
        }
        if (document.visibilityState === 'visible' && time - lastInput < 60000) activeMs += Math.max(0, Math.min(2000, time - lastTick));
        lastTick = time;
        if (!pageStarted) return;
        sampleEditorial(time);
        document.querySelectorAll('[data-audience-slot]').forEach(function (el) {
            if (intersectionObserver && !observedSlots.has(el)) { observedSlots.add(el); intersectionObserver.observe(el); }
            var d = el.dataset, slotKey = label(d.audienceSlot, 100); if (!slotKey) return;
            var generation = label(d.audienceGeneration, 30) || (config.context.pageFamily === 'search' ? 'search-' + String(config.context.contextUf || config.context.marketUf || 'unknown').toLowerCase() : '');
            var envelope = d.audienceGeneration ? (contexts.get(generation) || config) : config;
            var key = slotKey + (generation ? ':' + generation : '');
            if (!slotApplicable(el)) {
                var inactiveState = states.get(key);
                if (inactiveState && inactiveState.element === el) {
                    inactiveState.since = null; inactiveState.adSince = null; inactiveState.last = time;
                }
                return;
            }
            var data = { slotKey: slotKey, placementKey: label(d.audiencePlacement), slotState: d.audienceState || 'empty', deliveryId: validId(d.audienceDelivery) ? d.audienceDelivery : '', campaignId: validId(d.audienceCampaign) ? d.audienceCampaign : '' };
            var view = geometry(el);
            var previousOpportunity = opportunities.get(key);
            if (!previousOpportunity || previousOpportunity === 'pending' && data.slotState !== 'pending') {
                emit('slot_opportunity', key, Object.assign({}, data, { deliveryId: '', campaignId: '' }), !!previousOpportunity, envelope);
                opportunities.set(key, data.slotState);
            }
            if (d.audienceRequested === 'true') emit('slot_request', key, data, false, envelope);
            if (d.audienceServed === 'true') emit('slot_served', key, data, false, envelope);
            var state = states.get(key);
            if (!state) { state = { since: null, visibleMs: 0, maxContinuousMs: 0, last: time, element: el, context: envelope }; states.set(key, state); }
            // A collapsed inventory marker must not reset a populated instance of the same slot.
            if (state.element !== el && state.element.isConnected && !view.ready) return;
            if (state.element !== el) { state.since = null; state.adSince = null; state.element = el; state.last = time; }
            if (state.delivery !== data.deliveryId) {
                state.delivery = data.deliveryId; state.adSince = null; state.adVisibleMs = 0; state.adMaxContinuousMs = 0; state.adPublishedMs = 0; state.adVisible = null;
            }
            if (view.ready) {
                emit('slot_render', key, data, false, envelope);
                if (isAd(data)) emit('ad_render', key, data, false, envelope);
            }
            if (time - state.last > 2000) { state.since = null; state.adSince = null; }
            if (view.ready && view.ratio >= 0.5 && ['filled', 'house', 'empty', 'disabled'].indexOf(data.slotState) >= 0) {
                if (state.since === null) state.since = time;
                var continuous = Math.floor(time - state.since);
                state.maxContinuousMs = Math.max(state.maxContinuousMs, continuous);
                if (continuous > 0) state.visibleMs += Math.max(0, Math.min(2000, time - state.last));
                if (state.maxContinuousMs >= 1000) {
                    var visible = Object.assign({}, data, { deliveryId: '', campaignId: '', visibleMs: Math.floor(state.visibleMs), maxContinuousMs: state.maxContinuousMs, ratio: view.ratio });
                    state.visible = visible;
                    if (!state.publishedMs) {
                        emit('slot_viewable', key, visible, false, envelope);
                        state.publishedMs = visible.visibleMs;
                    }
                }
                if (isAd(data)) {
                    if (state.adSince === null) state.adSince = time;
                    var adContinuous = Math.floor(time - state.adSince);
                    state.adMaxContinuousMs = Math.max(state.adMaxContinuousMs, adContinuous);
                    if (adContinuous > 0) state.adVisibleMs += Math.max(0, Math.min(2000, time - state.last));
                    if (state.adMaxContinuousMs >= 1000) {
                        state.adVisible = Object.assign({}, data, { visibleMs: Math.floor(state.adVisibleMs), maxContinuousMs: state.adMaxContinuousMs, ratio: view.ratio });
                        if (!state.adPublishedMs) { emit('ad_viewable', key, state.adVisible, false, envelope); state.adPublishedMs = state.adVisibleMs; }
                    }
                }
            } else { state.since = null; state.adSince = null; }
            state.last = time;
        });
    }
    function contentOpen(type, id) { id = label(id, 100); if (id) emit('content_open', label(type, 20) + ':' + id, { contentType: label(type, 20), contentId: id }); }
    function liveRegistrationClick(event) {
        // Delegation also covers the asynchronously replaced coupon modal. Never
        // cancel navigation or wait for delivery to the first-party collector.
        try {
            if (collectionBlocked() || !session || event.defaultPrevented || !event.target || !event.target.closest) return;
            var el = event.target.closest('[data-audience-live-registration]');
            if (!el || el.disabled || el.getAttribute('aria-disabled') === 'true') return;
            if (event.type === 'auxclick' ? event.button !== 1 || el.tagName !== 'A' : event.button > 0) return;
            var id = String(el.dataset.audienceLiveRegistration || '');
            if (!/^[1-9][0-9]{0,9}$/.test(id)) return;
            var destination = new URL(el.tagName === 'A' ? el.href : el.dataset.audienceRegistrationUrl, window.location.href);
            if (destination.protocol !== 'https:' || destination.username || destination.password || destination.port
                || ['liverun.com.br', 'www.liverun.com.br', 'appliveexperience.com.br', 'www.appliveexperience.com.br'].indexOf(destination.hostname) < 0) return;
            touchSession();
            emit('outbound_click', 'live_registration:' + id, { contentType: 'event', contentId: id });
            flush();
        } catch (_) {}
    }
    function adoptContext(container) {
        if (!container || collectionBlocked()) return;
        var marker = container.querySelector('[data-audience-context]');
        if (!marker) return;
        try {
            var envelope = JSON.parse(marker.dataset.audienceContext), generation = label(marker.dataset.audienceGeneration, 30);
            if (!generation || !envelope.context || envelope.context.pageViewId !== config.context.pageViewId || !envelope.contextToken || !envelope.signature) return;
            contexts.set(generation, envelope);
            container.querySelectorAll('[data-audience-slot]').forEach(function (el) { el.dataset.audienceGeneration = generation; });
        } catch (_) {}
    }
    function bindVideo(video, id) {
        id = label(id, 100); if (!video || !id) return;
        video.dataset.audienceContentId = id;
        if (video.dataset.audiencePlayerBound) return;
        video.dataset.audiencePlayerBound = 'true';
        function send(kind, suffix) { var current = video.dataset.audienceContentId; emit(kind, 'video:' + current + (suffix || ''), { contentType: 'video', contentId: current }); }
        video.addEventListener('playing', function () { send('video_start'); });
        video.addEventListener('timeupdate', function () { if (video.duration > 0 && !video.paused) [25, 50, 75].forEach(function (p) { if (video.currentTime / video.duration >= p / 100) send('video_progress', ':' + p); }); });
        video.addEventListener('ended', function () { send('video_complete'); });
    }
    function bindYouTube(player, id) {
        id = label(id, 100);
        var stopped = false, started = false, timer;
        function stop() { stopped = true; if (timer) window.clearInterval(timer); }
        function send(kind, suffix) { emit(kind, 'video:' + id + (suffix || ''), { contentType: 'video', contentId: id }); }
        function samplePlayer() {
            if (stopped) return;
            if (collectionBlocked()) { stop(); return; }
            if (!player || !id || document.visibilityState !== 'visible') return;
            try {
                // Related-video navigation can reuse this player. Never credit it to the modal selection.
                var currentId = new URL(player.getVideoUrl()).searchParams.get('v');
                if (!currentId) return;
                if (currentId !== id) { stop(); return; }
                var state = player.getPlayerState();
                // Iframe API states: playing=1, ended=0. Ready/buffering are not starts.
                if (state === 1) {
                    started = true; send('video_start');
                    var duration = Number(player.getDuration()), position = Number(player.getCurrentTime());
                    // These milestones describe playhead position, not uninterrupted watch time.
                    if (Number.isFinite(duration) && duration > 0 && Number.isFinite(position) && position >= 0) {
                        [25, 50, 75].forEach(function (p) { if (position / duration >= p / 100) send('video_progress', ':' + p); });
                    }
                } else if (state === 0 && started) send('video_complete');
            } catch (_) { /* Player/API failures must not affect media playback. */ }
        }
        if (player && id && !collectionBlocked()) { timer = window.setInterval(samplePlayer, 500); samplePlayer(); }
        return { sample: samplePlayer, stop: stop };
    }
    if (window.IntersectionObserver) {
        intersectionObserver = new window.IntersectionObserver(function (entries) {
            // Process every crossing before sampling current geometry: a queued exit and
            // reentry must not inherit the preceding visible interval.
            entries.forEach(function (entry) {
                var ratio = entry.isIntersecting ? entry.intersectionRatio : 0;
                intersectionRatios.set(entry.target, ratio);
                if (ratio < 0.5) states.forEach(function (state) {
                    if (state.element === entry.target) { state.since = null; state.adSince = null; }
                });
                if (ratio < 0.5) {
                    var contentState = contentStates.get(entry.target);
                    if (contentState) contentState.since = null;
                }
                if (!entry.target.isConnected) {
                    intersectionObserver.unobserve(entry.target); observedSlots.delete(entry.target); observedContents.delete(entry.target); contentStates.delete(entry.target);
                }
            });
            sample();
        }, { threshold: [0, 0.5, 1] });
    }
    window.RoadRunnersAudience = { observe: sample, flush: flush, contentOpen: contentOpen, bindVideo: bindVideo, bindYouTube: bindYouTube, adoptContext: adoptContext };
    document.addEventListener('click', liveRegistrationClick);
    document.addEventListener('auxclick', liveRegistrationClick);
    sample();
    window.setInterval(sample, 250);
    window.setInterval(function () { if (!pageStarted || collectionBlocked() || !session) return; if (document.visibilityState === 'visible' && now() - lastInput < 60000) touchSession(); emit('page_engagement', session.id, { activeMs: Math.floor(activeMs) }, true); flush(false); }, 10000);
    ['pointerdown', 'keydown', 'scroll', 'touchstart'].forEach(function (type) { document.addEventListener(type, function () { if (collectionBlocked() || !session) return; lastInput = now(); touchSession(); }, { passive: true }); });
    document.addEventListener('visibilitychange', function () { states.forEach(function (state) { state.since = null; state.adSince = null; }); contentStates.forEach(function (state) { state.since = null; }); lastTick = now(); if (collectionBlocked() || !session) return; if (document.visibilityState === 'visible') { lastInput = now(); touchSession(); } sample(); if (pageStarted && document.visibilityState !== 'visible') { emit('page_engagement', session.id, { activeMs: Math.floor(activeMs) }, true); flush(); } });
    window.addEventListener('pagehide', function () { sample(); if (pageStarted && !collectionBlocked() && session) { emit('page_engagement', session.id, { activeMs: Math.floor(activeMs) }, true); flush(); } });
    document.addEventListener('DOMContentLoaded', sample);
    document.addEventListener('scroll', sample, { passive: true, capture: true });
    window.addEventListener('resize', sample, { passive: true });
    document.addEventListener('load', sample, true);
    if (window.MutationObserver) new window.MutationObserver(sample).observe(document.documentElement, { childList: true, subtree: true });
}(window, document));
