(function () {
  'use strict';
  const nav = document.querySelector('.chapter-nav');
  const source = document.querySelector('.source-bar');
  const content = document.getElementById('content');
  if (!nav || !source || !content) return;

  let chapters = [], current = null, frame = 0, navigationHeight = 0;
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

  function reveal(link) {
    const bounds = nav.getBoundingClientRect();
    const item = link.getBoundingClientRect();
    const inset = 16;
    let distance = 0;
    if (item.left < bounds.left + inset) distance = item.left - bounds.left - inset;
    else if (item.right > bounds.right - inset) distance = item.right - bounds.right + inset;
    if (distance) nav.scrollTo({left: nav.scrollLeft + distance, behavior: reducedMotion.matches ? 'instant' : 'smooth'});
  }

  function highlight() {
    frame = 0;
    if (!chapters.length) return;
    // Each chapter keeps its first anchor even when it spans several pages.
    const readingLine = navigationHeight + Math.min(200, Math.max(80, (window.innerHeight - navigationHeight) / 4));
    let active = chapters[0];
    for (const chapter of chapters) {
      if (chapter.section.getBoundingClientRect().top > readingLine) break;
      active = chapter;
    }
    if (active.link === current) return;
    for (const chapter of chapters) chapter.link.removeAttribute('aria-current');
    active.link.setAttribute('aria-current', 'location');
    current = active.link;

    // Reveal the selected item horizontally without moving the reading page.
    reveal(current);
  }

  function schedule() {
    if (!frame) frame = window.requestAnimationFrame(highlight);
  }

  function measure() {
    const sourceHeight = Math.ceil(source.getBoundingClientRect().height);
    navigationHeight = sourceHeight + Math.ceil(nav.getBoundingClientRect().height);
    document.documentElement.style.setProperty('--study-source-height', sourceHeight + 'px');
    document.documentElement.style.setProperty('--study-navigation-height', navigationHeight + 'px');
    schedule();
  }

  function refresh() {
    chapters = Array.from(nav.querySelectorAll('a[href^="#"]')).map(link => ({
      link, section: document.getElementById(link.getAttribute('href').slice(1))
    })).filter(chapter => chapter.section);
    chapters.sort((a, b) => a.section.getBoundingClientRect().top - b.section.getBoundingClientRect().top);
    current = null;
    measure();
  }

  // Charts and source/gender switches rebuild the pages; edition links are dynamic.
  const mutations = new MutationObserver(refresh);
  mutations.observe(content, {childList: true});
  mutations.observe(nav, {childList: true});
  const sizes = new ResizeObserver(measure);
  sizes.observe(source);
  sizes.observe(nav);
  window.addEventListener('scroll', schedule, {passive: true});
  window.addEventListener('resize', measure, {passive: true});
  window.addEventListener('hashchange', schedule);
  document.fonts.ready.then(schedule);
  nav.addEventListener('focusin', event => {
    const link = event.target.closest('a[href^="#"]');
    if (link) reveal(link);
  });
  refresh();
})();
