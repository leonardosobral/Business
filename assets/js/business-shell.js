(function () {
    'use strict';
    var header = document.querySelector('.business-shell-header');
    var navbar = header && header.querySelector('#main-navbar');
    if (!navbar) return;

    var updateHeight = function () {
        var height = Math.ceil(navbar.getBoundingClientRect().height);
        if (height > 0) header.style.setProperty('--business-navbar-height', height + 'px');
    };

    // Loaded just after the navbar; ResizeObserver also covers wrapping and font loading.
    updateHeight();
    if (window.ResizeObserver) new window.ResizeObserver(updateHeight).observe(navbar);
    window.addEventListener('resize', updateHeight);
}());
