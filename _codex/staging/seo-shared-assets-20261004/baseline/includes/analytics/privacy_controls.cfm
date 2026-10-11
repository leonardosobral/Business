<!--- First-party audience controls. Kept separate from authentication, Ads and the legacy cookie modal. --->
<cfif NOT structKeyExists(REQUEST, "audiencePrivacyControlsRendered")>
<cfset REQUEST.audiencePrivacyControlsRendered = true/>
<link rel="stylesheet" href="/assets/css/rr-audience-privacy.css?v=20260913a" />

<cfoutput>
<section
    class="rr-audience-privacy"
    data-audience-privacy-root
    data-status-allowed="#encodeForHTMLAttribute(REQUEST.t('common.audiencePrivacy.statusAllowed'))#"
    data-status-denied="#encodeForHTMLAttribute(REQUEST.t('common.audiencePrivacy.statusDenied'))#"
    data-status-gpc="#encodeForHTMLAttribute(REQUEST.t('common.audiencePrivacy.statusGpc'))#"
    data-saved-allowed="#encodeForHTMLAttribute(REQUEST.t('common.audiencePrivacy.savedAllowed'))#"
    data-saved-denied="#encodeForHTMLAttribute(REQUEST.t('common.audiencePrivacy.savedDenied'))#"
    data-save-unavailable="#encodeForHTMLAttribute(REQUEST.t('common.audiencePrivacy.saveUnavailable'))#"
    aria-label="#encodeForHTMLAttribute(REQUEST.t('common.audiencePrivacy.title'))#"
>
    <div id="rr-audience-privacy-dialog" class="rr-audience-privacy__dialog" data-audience-privacy-dialog role="dialog" aria-modal="true" aria-labelledby="rr-audience-privacy-title" aria-hidden="true" hidden>
        <div class="rr-audience-privacy__panel" role="document">
            <button type="button" class="rr-audience-privacy__close" data-audience-privacy-close aria-label="#encodeForHTMLAttribute(REQUEST.t('common.audiencePrivacy.close'))#">&times;</button>
            <p class="rr-audience-privacy__kicker">#encodeForHTML(REQUEST.t('common.audiencePrivacy.kicker'))#</p>
            <h2 id="rr-audience-privacy-title">#encodeForHTML(REQUEST.t('common.audiencePrivacy.title'))#</h2>
            <p>#encodeForHTML(REQUEST.t('common.audiencePrivacy.description'))#</p>
            <p class="rr-audience-privacy__effect">#encodeForHTML(REQUEST.t('common.audiencePrivacy.effect'))#</p>
            <p class="rr-audience-privacy__status">
                <strong>#encodeForHTML(REQUEST.t('common.audiencePrivacy.statusLabel'))#</strong>
                <span data-audience-privacy-status></span>
            </p>
            <p class="rr-audience-privacy__feedback" data-audience-privacy-feedback aria-live="polite"></p>
            <div class="rr-audience-privacy__actions">
                <button type="button" class="rr-audience-privacy__button rr-audience-privacy__button--primary" data-audience-privacy-allow>#encodeForHTML(REQUEST.t('common.audiencePrivacy.allow'))#</button>
                <button type="button" class="rr-audience-privacy__button" data-audience-privacy-deny>#encodeForHTML(REQUEST.t('common.audiencePrivacy.deny'))#</button>
            </div>
            <a class="rr-audience-privacy__policy" href="#encodeForHTMLAttribute(REQUEST.i18nBuildPath('privacy'))#">#encodeForHTML(REQUEST.t('common.audiencePrivacy.policy'))#</a>
        </div>
    </div>
</section>
</cfoutput>

<script src="/assets/js/rr-audience-privacy.js?v=20260913a"></script>
</cfif>
