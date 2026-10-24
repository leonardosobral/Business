<style>
    .live-inline-coupon { padding: 1rem; border: 1px solid #e8c566; border-radius: 10px; background: #fff8e6; }
    .live-inline-coupon [hidden] { display: none !important; }
    .live-inline-coupon-title { margin: 0 0 .4rem; font-size: 1rem; font-weight: 700; color: #333; }
    .live-inline-coupon-code-row { display: flex; gap: .5rem; align-items: stretch; }
    .live-inline-coupon-code { flex: 1 1 auto; min-width: 0; width: 100%; border: 1px solid #8b7848; border-radius: 6px; padding: .65rem; background: #fff; color: #333; font-weight: 700; font-size: 1rem; }
    .live-inline-coupon-code:focus-visible { outline: 3px solid #604400; outline-offset: 2px; }
    .live-inline-coupon-copy { flex: 0 0 auto; padding: .65rem .85rem; }
    .live-inline-coupon-status { min-height: 1.4em; margin: .45rem 0; font-size: .82rem; color: #604400; }
    .live-inline-coupon .btn { white-space: normal; }
</style>
<cfoutput>
<section class="live-inline-coupon" data-live-coupon-view="#encodeForHTMLAttribute(qEvento.id_evento)#" aria-labelledby="live-inline-coupon-title">
    <h2 class="live-inline-coupon-title" id="live-inline-coupon-title">Seu cupom para esta prova<cfif len(trim(qCupom.condicoes & ""))>: #encodeForHTML(qCupom.condicoes)#</cfif></h2>
    <p class="small mb-2">Copie o código e informe no campo de cupom do checkout da LIVE. Confira o desconto antes de pagar.</p>
    <label for="live-inline-coupon-code" class="form-label small mb-1">Código do cupom</label>
    <div class="live-inline-coupon-code-row">
        <input id="live-inline-coupon-code" class="live-inline-coupon-code" type="text" value="#encodeForHTMLAttribute(qLiveInlineCoupon.cupom)#" readonly data-live-coupon-code aria-describedby="live-inline-coupon-status" autocomplete="off" spellcheck="false">
        <button type="button" class="btn btn-secondary shadow-0 live-inline-coupon-copy" data-live-coupon-copy="#encodeForHTMLAttribute(qEvento.id_evento)#" hidden>Copiar</button>
    </div>
    <p id="live-inline-coupon-status" class="live-inline-coupon-status" role="status" aria-live="polite" data-live-coupon-status>Você também pode selecionar e copiar o código.</p>
    <a class="btn btn-primary w-100 shadow-0" href="#encodeForHTMLAttribute(qLiveInlineCoupon.curl)#" target="_blank" rel="noopener noreferrer" data-audience-live-registration="#encodeForHTMLAttribute(qEvento.id_evento)#">Continuar inscrição na LIVE <i class="fa-solid fa-up-right-from-square ms-1" aria-hidden="true"></i></a>
</section>
</cfoutput>
<script src="/assets/js/rr-live-funnel-ui.js?v=20261020" defer></script>
