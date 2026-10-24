(function (window, document) {
    'use strict';
    function report(detail) {
        window.dispatchEvent(new window.CustomEvent('rr-live-funnel', { detail: detail }));
    }
    function filterCities(browser, reportChange) {
        var select = browser.querySelector('[data-live-city-select]');
        var visible = 0;
        browser.querySelectorAll('[data-live-city]').forEach(function (card) {
            card.hidden = !!select.value && card.dataset.liveCity !== select.value;
            if (!card.hidden) visible++;
        });
        browser.querySelector('[data-live-city-count]').textContent = visible + (visible === 1 ? ' etapa encontrada' : ' etapas encontradas');
        if (reportChange) report({ action: 'city_select', citySlug: select.value || 'all' });
    }
    function init() {
        document.querySelectorAll('[data-live-coupon-copy]').forEach(function (button) { button.hidden = false; });
        document.querySelectorAll('[data-live-circuit-browser]').forEach(function (browser) {
            browser.querySelector('[data-live-city-controls]').hidden = false;
            filterCities(browser, false);
        });
        document.addEventListener('change', function (event) {
            var select = event.target;
            if (!select || !select.matches('[data-live-city-select]')) return;
            filterCities(select.closest('[data-live-circuit-browser]'), true);
        });
        document.addEventListener('click', function (event) {
            var button = event.target.closest && event.target.closest('[data-live-coupon-copy]');
            if (!button || button.disabled) return;
            var section = button.closest('[data-live-coupon-view]');
            var code = section.querySelector('[data-live-coupon-code]');
            var status = section.querySelector('[data-live-coupon-status]');
            button.disabled = true;
            function failed() {
                button.disabled = false;
                code.focus();
                code.select();
                code.setSelectionRange(0, code.value.length);
                status.textContent = 'Não foi possível copiar automaticamente. Selecione e copie o código acima.';
                report({ action: 'coupon_copy_error', eventId: button.dataset.liveCouponCopy });
            }
            try {
                if (!window.navigator.clipboard || !window.navigator.clipboard.writeText) { failed(); return; }
                window.navigator.clipboard.writeText(code.value).then(function () {
                    button.disabled = false;
                    status.textContent = 'Cupom copiado! Cole o código no checkout da LIVE.';
                    report({ action: 'coupon_copy_success', eventId: button.dataset.liveCouponCopy });
                }, failed);
            } catch (error) { failed(); }
        });
    }
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
    else init();
})(window, document);
