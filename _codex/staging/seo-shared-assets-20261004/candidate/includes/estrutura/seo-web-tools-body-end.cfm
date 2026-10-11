<!--- JQUERY --->

<script src="https://roadrunners.run/assets/js/code.jquery.com_jquery-3.7.1.min.js"></script>


<!--- CORES --->

<script>

    function colorirDistancias() {
        var mc = {
            "0-5": "k5",
            "6-10": "k10",
            "11-21": "k21",
            "22-42": "k42",
            "43-99999": "ultra"
        };

        function between(x, min, max) {
            return x >= min && x <= max;
        }

        var dc;
        var first;
        var second;
        var th;

        $("div").each(function (index) {
            th = $(this);

            dc = parseInt($(this).attr("data-color"), 10);

            $.each(mc, function (name, value) {
                first = parseInt(name.split("-")[0], 10);
                second = parseInt(name.split("-")[1], 10);

                if (between(dc, first, second)) {
                    th.addClass(value);
                }
            });
        });

        $("tr").each(function (index) {
            th = $(this);

            dc = parseInt($(this).attr("data-color"), 10);

            $.each(mc, function (name, value) {
                first = parseInt(name.split("-")[0], 10);
                second = parseInt(name.split("-")[1], 10);

                if (between(dc, first, second)) {
                    th.addClass(value);
                }
            });
        });

        $("button").each(function (index) {
            th = $(this);

            dc = parseInt($(this).attr("data-color"), 10);

            $.each(mc, function (name, value) {
                first = parseInt(name.split("-")[0], 10);
                second = parseInt(name.split("-")[1], 10);

                if (between(dc, first, second)) {
                    th.addClass(value);
                }
            });
        });
    }

    colorirDistancias();

</script>


<!--- BOOTSTRAP --->

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL" crossorigin="anonymous"></script>

<!--- MDB ESSENTIAL --->

<cfparam name="VARIABLES.mdbAssetVersion" default="20260806a"/>
<script type="text/javascript" src="/assets/js/mdb.umd.min.js?version=<cfoutput>#VARIABLES.mdbAssetVersion#</cfoutput>"></script>


<!--- MDB PLUGINS --->

<script type="text/javascript" src="/assets/plugins/js/all.min.js?version=<cfoutput>#VARIABLES.mdbAssetVersion#</cfoutput>"></script>

<script src="/assets/js/runnerhub-entry-prompts.min.js?v=20261004seo"></script>
<cfinclude template="../modal/modal_strava_connect.cfm"/>

<!--- STRAVA EMBEDS --->

<script src="https://strava-embeds.com/embed.js"></script>


<!--- SCROLL TO TOP --->

<script>

    // Get the button:
    let mybutton = document.getElementById("scrollTop");

    if (mybutton) {

        // When the user scrolls down 20px from the top of the document, show the button
        window.onscroll = function() {scrollFunction()};

        function scrollFunction() {
            var footer = document.querySelector(".rr-portal-footer");
            var footerVisible = footer && footer.getBoundingClientRect().top < window.innerHeight;
            if (!footerVisible && (document.body.scrollTop > 500 || document.documentElement.scrollTop > 500)) {
                mybutton.style.display = "block";
            } else {
                mybutton.style.display = "none";
            }
        }

        // When the user clicks on the button, scroll to the top of the document
        function topFunction() {
            document.body.scrollTop = 0; // For Safari
            document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera
        }

    }

</script>


<!--- GOOGLE MAPS

<script>(g=>{var h,a,k,p="The Google Maps JavaScript API",c="google",l="importLibrary",q="__ib__",m=document,b=window;b=b[c]||(b[c]={});var d=b.maps||(b.maps={}),r=new Set,e=new URLSearchParams,u=()=>h||(h=new Promise(async(f,n)=>{await (a=m.createElement("script"));e.set("libraries",[...r]+"");for(k in g)e.set(k.replace(/[A-Z]/g,t=>"_"+t[0].toLowerCase()),g[k]);e.set("callback",c+".maps."+q);a.src=`https://maps.${c}apis.com/maps/api/js?`+e;d[q]=f;a.onerror=()=>h=n(Error(p+" could not load."));a.nonce=m.querySelector("script[nonce]")?.nonce||"";m.head.append(a)}));d[l]?console.warn(p+" only loads once. Ignoring:",g):d[l]=(f,...n)=>r.add(f)&&u().then(()=>d[l](f,...n))})
    ({key: "AIzaSyCV3c2smsV7ekkz3kJm7PEeVm-COfqDt8s", v: "beta"});</script>
 --->


<!--- URL PARAMS --->

<script>
    function updateURLParameter(url, param, paramVal){
        var newAdditionalURL = "";
        var tempArray = url.split("?");
        var baseURL = tempArray[0];
        var additionalURL = tempArray[1];
        var temp = "";
        if (additionalURL) {
            tempArray = additionalURL.split("&");
            for (var i=0; i<tempArray.length; i++){
                if(tempArray[i].split('=')[0] != param){
                    newAdditionalURL += temp + tempArray[i];
                    temp = "&";
                }
            }
        }

        var rows_txt = temp + "" + param + "=" + paramVal;
        return baseURL + "?" + newAdditionalURL + rows_txt;
    }
</script>


<!--- SOCIAL MEDIA INFO
<script type="application/ld+json">
    {
        "@context": "http://schema.org",
        "@type": "Organization",
        "name": "DeuMeet",
        "url": "http://deumeet.com",
        "address": "Florianópolis, SC",
        "sameAs": [
            "https://www.facebook.com/clubedebrinquedostumtum",
            "https://www.youtube.com/c/clubedebrinquedostumtum",
            "https://www.linkedin.com/company/clube-de-brinquedos-tum-tum",
            "https://www.instagram.com/clubedebrinquedostumtum/"
        ]
    }
</script>
 --->

<cfinclude template="entry_cookie_notice.cfm" />

<cfinclude template="../analytics/privacy_controls.cfm" />

<script>
    (function () {
      if (!('serviceWorker' in navigator) || window.location.protocol !== 'https:') {
        return;
      }

      const pwaI18n = {
        updateTitle: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.updateTitle"))#</cfoutput>',
        updateText: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.updateText"))#</cfoutput>',
        updateAction: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.updateAction"))#</cfoutput>',
        dismiss: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.dismiss"))#</cfoutput>'
      };
      const versionStorageKey = 'rr-pwa-active-version';
      const dismissedVersionStorageKey = 'rr-pwa-update-dismissed-version';

      function pwaGetStorageValue(key) {
        try {
          return window.localStorage.getItem(key) || '';
        } catch (error) {
          return '';
        }
      }

      function pwaSetStorageValue(key, value) {
        try {
          window.localStorage.setItem(key, value);
        } catch (error) {}
      }

      function removeUpdateToast() {
        const existing = document.getElementById('rrPwaUpdateToast');

        if (existing) {
          existing.remove();
        }
      }

      function showUpdateToast(version) {
        if (!version || pwaGetStorageValue(dismissedVersionStorageKey) === version) {
          return;
        }

        removeUpdateToast();

        const wrapper = document.createElement('div');
        wrapper.id = 'rrPwaUpdateToast';
        wrapper.className = 'rr-pwa-update-toast';
        wrapper.innerHTML = `
          <div class="rr-pwa-update-toast__icon"><i class="fa-solid fa-rotate"></i></div>
          <div class="rr-pwa-update-toast__body">
            <strong>${pwaI18n.updateTitle}</strong>
            <span>${pwaI18n.updateText}</span>
          </div>
          <div class="rr-pwa-update-toast__actions">
            <button type="button" class="btn btn-warning btn-sm shadow-0" id="rrPwaUpdateReload">${pwaI18n.updateAction}</button>
            <button type="button" class="btn btn-light btn-sm shadow-0" id="rrPwaUpdateDismiss">${pwaI18n.dismiss}</button>
          </div>
        `;

        document.body.appendChild(wrapper);

        const reloadButton = wrapper.querySelector('#rrPwaUpdateReload');
        const dismissButton = wrapper.querySelector('#rrPwaUpdateDismiss');

        if (reloadButton) {
          reloadButton.addEventListener('click', function () {
            pwaSetStorageValue(versionStorageKey, version);
            window.location.reload();
          });
        }

        if (dismissButton) {
          dismissButton.addEventListener('click', function () {
            pwaSetStorageValue(dismissedVersionStorageKey, version);
            removeUpdateToast();
          });
        }
      }

      navigator.serviceWorker.addEventListener('message', function (event) {
        const messageData = event.data && typeof event.data === 'object' ? event.data : {};

        if (messageData.type !== 'RR_PWA_SW_ACTIVATED' || !messageData.version) {
          return;
        }

        const knownVersion = pwaGetStorageValue(versionStorageKey);

        if (!knownVersion) {
          pwaSetStorageValue(versionStorageKey, messageData.version);
          return;
        }

        if (knownVersion !== messageData.version) {
          window.RREntryPrompts.enqueue("update", function () { showUpdateToast(messageData.version); return !!document.getElementById("rrPwaUpdateToast"); }, 40);
        }
      });

      window.addEventListener('load', function () {
        navigator.serviceWorker.register('/sw.js').then(function (registration) {
          registration.update().catch(function () {});

          registration.addEventListener('updatefound', function () {
            const installingWorker = registration.installing;

            if (!installingWorker) {
              return;
            }

            installingWorker.addEventListener('statechange', function () {
              if (installingWorker.state === 'installed' && navigator.serviceWorker.controller) {
                pwaSetStorageValue(dismissedVersionStorageKey, '');
              }
            });
          });
        }).catch(function () {});
      });
    })();
</script>

<script>
    window.rrPushI18n = {
      notEnabled: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.notEnabled"))#</cfoutput>',
      browserUnsupported: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.browserUnsupported"))#</cfoutput>',
      permissionDenied: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.permissionDenied"))#</cfoutput>',
      noDeviceSubscription: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.noDeviceSubscription"))#</cfoutput>',
      activationUnavailable: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.activationUnavailable"))#</cfoutput>',
      siteBlocked: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.siteBlocked"))#</cfoutput>',
      alreadyActive: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.alreadyActive"))#</cfoutput>',
      activationFailed: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.activationFailed"))#</cfoutput>',
      subscriptionActivated: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.subscriptionActivated"))#</cfoutput>',
      testUnavailable: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.testUnavailable"))#</cfoutput>',
      testSent: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.testSent"))#</cfoutput>',
      testFailed: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.testFailed"))#</cfoutput>'
    };

    (function () {
      const pushConfig = {
        enabled: false,
        publicKey: ''
      };

      function urlBase64ToUint8Array(base64String) {
        const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
        const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
        const rawData = window.atob(base64);
        const outputArray = new Uint8Array(rawData.length);

        for (let i = 0; i < rawData.length; ++i) {
          outputArray[i] = rawData.charCodeAt(i);
        }

        return outputArray;
      }

      async function getPushStatus() {
        const response = await fetch('/api/push/status.cfm', {
          method: 'GET',
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        });

        const status = await response.json();

        if (status && typeof status.enabled !== 'undefined') {
          pushConfig.enabled = !!status.enabled;
        }

        if (status && typeof status.publicKey === 'string') {
          pushConfig.publicKey = status.publicKey;
        }

        return status;
      }

      async function getPushSubscription() {
        if (!('serviceWorker' in navigator)) {
          return null;
        }

        const registration = await navigator.serviceWorker.ready;
        return registration.pushManager.getSubscription();
      }

async function subscribeToPush(deviceLabel = '', options = {}) {
  if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) {
    throw new Error(window.rrPushI18n.browserUnsupported);
  }

  const permission = options && options.permission
    ? options.permission
    : (
      Notification.permission === 'granted'
        ? 'granted'
        : await Notification.requestPermission()
    );

  if (permission !== 'granted') {
    throw new Error(window.rrPushI18n.permissionDenied);
  }

  const runtimeStatus = await getPushStatus();

  if (!runtimeStatus || !runtimeStatus.enabled || !runtimeStatus.publicKey) {
    throw new Error(window.rrPushI18n.notEnabled);
  }

  const registration = await navigator.serviceWorker.ready;
  let subscription = await registration.pushManager.getSubscription();

  if (!subscription) {
    subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(runtimeStatus.publicKey)
    });
  }

  let installId = '';
  try {
    installId = window.localStorage.getItem('rr-pwa-install-id') || '';
    if (!installId) {
      installId = window.crypto && typeof window.crypto.randomUUID === 'function'
        ? window.crypto.randomUUID()
        : 'rr-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2);
      window.localStorage.setItem('rr-pwa-install-id', installId);
    }
  } catch (error) {
    installId = 'rr-session-' + Date.now().toString(36);
  }

  const userAgent = window.navigator.userAgent || '';
  const platform = /iPad|iPhone|iPod/i.test(userAgent)
    ? 'ios'
    : (/Android/i.test(userAgent) ? 'android' : 'desktop');
  const browser = /Edg\//i.test(userAgent)
    ? 'edge'
    : (/CriOS|Chrome\//i.test(userAgent)
      ? 'chrome'
      : (/FxiOS|Firefox\//i.test(userAgent) ? 'firefox' : (/Safari\//i.test(userAgent) ? 'safari' : 'other')));

  pushConfig.enabled = true;
  pushConfig.publicKey = runtimeStatus.publicKey;

  const response = await fetch('/api/push/subscribe.cfm', {
    method: 'POST',
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      subscription,
      deviceLabel,
      installId,
      platform,
      browser
    })
  });

  return response.json();
}

      async function unsubscribeFromPush() {
        const subscription = await getPushSubscription();

        if (!subscription) {
          return {
            success: true,
            message: window.rrPushI18n.noDeviceSubscription
          };
        }

        const endpoint = subscription.endpoint;
        await subscription.unsubscribe();

        const response = await fetch('/api/push/unsubscribe.cfm', {
          method: 'POST',
          credentials: 'same-origin',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify({
            endpoint
          })
        });

        return response.json();
      }


      async function resetPushSubscription(deviceLabel = '') {
        const currentSubscription = await getPushSubscription();

        if (currentSubscription) {
          try {
            await currentSubscription.unsubscribe();
          } catch (error) {}
        }

        try {
          await fetch('/api/push/reset.cfm', {
            method: 'POST',
            credentials: 'same-origin',
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            body: JSON.stringify({
              endpoint: currentSubscription ? currentSubscription.endpoint : ''
            })
          });
        } catch (error) {}

        return subscribeToPush(deviceLabel);
      }

      async function showLocalPushPreview(payload = {}) {
        if (!('serviceWorker' in navigator)) {
          throw new Error('Service Worker não disponível.');
        }

        const registration = await navigator.serviceWorker.ready;

        if (!registration.active) {
          throw new Error('Service Worker ainda não está ativo.');
        }

        registration.active.postMessage({
          type: 'RR_SHOW_LOCAL_NOTIFICATION',
          payload
        });
      }

      async function sendTestPush() {
        const response = await fetch('/api/push/test.cfm', {
          method: 'POST',
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        });

        const data = await response.json();

        if (!data || !data.success) {
          if (data && Array.isArray(data.results) && data.results.length) {
            const firstResult = data.results[0];
            const statusCode = firstResult && firstResult.statusCode ? firstResult.statusCode : '';
            const statusText = firstResult && firstResult.statusText ? firstResult.statusText : '';
            throw new Error((data.message ? data.message + ' ' : '') + [statusCode, statusText].filter(Boolean).join(' - '));
          }

          throw new Error(data && data.message ? data.message : 'Não foi possível disparar o push de teste.');
        }

        return data;
      }

      async function getPushPreferences() {
        const response = await fetch('/api/me/push-preferences.cfm', {
          method: 'GET',
          credentials: 'same-origin',
          headers: {
            'Accept': 'application/json'
          }
        });

        return response.json();
      }

      async function updatePushPreferences(preferences = {}) {
        const response = await fetch('/api/me/push-preferences.cfm', {
          method: 'POST',
          credentials: 'same-origin',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify(preferences)
        });

        return response.json();
      }

      window.RRPwaPush = {
        config: pushConfig,
        getStatus: getPushStatus,
        getSubscription: getPushSubscription,
        getPreferences: getPushPreferences,
        updatePreferences: updatePushPreferences,
        subscribe: subscribeToPush,
        unsubscribe: unsubscribeFromPush,
        reset: resetPushSubscription,
        preview: showLocalPushPreview,
        sendTestPush: sendTestPush
      };

      // Sincroniza silenciosamente uma assinatura já autorizada; nunca abre o prompt automaticamente.
      window.addEventListener('load', function () {
        const isAuthenticated = <cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND REQUEST.Usuario.logado>true<cfelse>false</cfif>;
        if (
          isAuthenticated &&
          'Notification' in window &&
          Notification.permission === 'granted' &&
          'serviceWorker' in navigator &&
          'PushManager' in window
        ) {
          subscribeToPush('', { permission: 'granted' }).catch(function () {});
        }
      });
    })();
</script>

<style>
    .rr-pwa-update-toast,
    .rr-pwa-push-prompt,
    .rr-pwa-install-prompt {
        position: fixed;
        left: 50%;
        bottom: 5.25rem;
        transform: translateX(-50%);
        width: min(24rem, calc(100vw - 1rem));
        background: #ffffff;
        border: 1px solid rgba(34, 34, 34, 0.08);
        border-radius: 1.1rem;
        box-shadow: 0 18px 48px rgba(0, 0, 0, 0.18);
        padding: 1rem;
        z-index: 1085;
    }

    .rr-pwa-update-toast {
        display: grid;
        grid-template-columns: auto 1fr;
        gap: .8rem;
        align-items: center;
        width: min(31rem, calc(100vw - 1rem));
    }

    .rr-pwa-update-toast__icon {
        width: 2.35rem;
        height: 2.35rem;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border-radius: .85rem;
        background: rgba(244, 177, 32, 0.16);
        color: #9f7800;
    }

    .rr-pwa-update-toast__body strong,
    .rr-pwa-update-toast__body span {
        display: block;
    }

    .rr-pwa-update-toast__body strong {
        color: #222222;
        font-size: .95rem;
        line-height: 1.2;
    }

    .rr-pwa-update-toast__body span {
        color: #555555;
        font-size: .82rem;
        line-height: 1.35;
        margin-top: .15rem;
    }

    .rr-pwa-update-toast__actions {
        grid-column: 1 / -1;
        display: flex;
        gap: .55rem;
    }

    .rr-pwa-update-toast__actions .btn {
        flex: 1 1 0;
    }

    .rr-pwa-sheet {
        position: fixed;
        inset: 0;
        display: flex;
        align-items: flex-end;
        justify-content: center;
        background: rgba(0, 0, 0, 0.58);
        z-index: 1090;
        padding: .75rem;
    }

    .rr-pwa-sheet.is-centered {
        align-items: center;
    }

    .rr-pwa-sheet.is-centered .rr-pwa-sheet__card {
        max-height: calc(100vh - 1.5rem);
        max-height: calc(100dvh - 1.5rem);
        overflow-y: auto;
    }

    .rr-pwa-sheet__card {
        width: min(100%, 27rem);
        background: #ffffff;
        border-radius: 1.15rem;
        border: 1px solid rgba(34, 34, 34, 0.08);
        box-shadow: 0 20px 56px rgba(0, 0, 0, 0.24);
        padding: 1rem;
    }

    .rr-pwa-sheet__head {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 1rem;
        margin-bottom: .85rem;
    }

    .rr-pwa-sheet__title {
        color: #222222;
        font-size: 1rem;
        font-weight: 800;
        margin: 0 0 .25rem 0;
    }

    .rr-pwa-sheet__text {
        color: #666666;
        font-size: .9rem;
        line-height: 1.4;
        margin: 0;
    }

    .rr-pwa-sheet__close {
        border: 0;
        background: #f3f3f3;
        color: #333333;
        width: 2rem;
        height: 2rem;
        border-radius: 999px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
    }

    .rr-pwa-sheet__steps,
    .rr-pwa-preference-list {
        display: grid;
        gap: .6rem;
        margin: .9rem 0 0 0;
        padding: 0;
        list-style: none;
    }

    .rr-pwa-sheet__steps li,
    .rr-pwa-preference-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: .75rem;
        border: 1px solid rgba(34, 34, 34, 0.08);
        border-radius: .9rem;
        background: #f8f8f8;
        padding: .75rem .85rem;
    }

    .rr-pwa-sheet__steps i {
        color: #f4b120;
        width: 1.1rem;
    }

    .rr-pwa-sheet__steps span {
        display: inline-flex;
        align-items: center;
        gap: .55rem;
    }

    .rr-pwa-preference-row span {
        color: #333333;
        font-weight: 700;
        font-size: .9rem;
    }

    .rr-pwa-preference-row input {
        width: 2.5rem;
        height: 1.25rem;
        accent-color: #f4b120;
    }

    .rr-pwa-sheet__message {
        color: #666666;
        font-size: .84rem;
        min-height: 1.2rem;
        margin: .85rem 0 0 0;
    }

    .rr-pwa-sheet__actions {
        display: flex;
        gap: .6rem;
        margin-top: .85rem;
    }

    .rr-pwa-sheet__actions .btn {
        flex: 1 1 0;
    }

    .rr-pwa-push-prompt__eyebrow {
        display: inline-flex;
        align-items: center;
        gap: .45rem;
        font-size: .72rem;
        font-weight: 700;
        letter-spacing: .04em;
        text-transform: uppercase;
        color: #8a6a00;
        background: rgba(244, 177, 32, 0.14);
        border-radius: 999px;
        padding: .32rem .65rem;
        margin-bottom: .8rem;
    }

    .rr-pwa-push-prompt__title {
        font-size: 1rem;
        line-height: 1.25;
        font-weight: 700;
        color: #222222;
        margin: 0 0 .4rem 0;
    }

    .rr-pwa-push-prompt__text {
        font-size: .92rem;
        line-height: 1.45;
        color: #555555;
        margin: 0 0 .95rem 0;
    }

    .rr-pwa-push-prompt__actions {
        display: flex;
        gap: .6rem;
    }

    .rr-pwa-push-prompt__actions .btn {
        flex: 1 1 0;
    }

    .rr-pwa-install-prompt {
        display: grid;
        grid-template-columns: auto 1fr;
        gap: .8rem;
        align-items: center;
    }

    .rr-pwa-install-prompt__icon {
        width: 2.5rem;
        height: 2.5rem;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border-radius: .85rem;
        background: #222222;
        color: #f4b120;
        font-size: 1.05rem;
    }

    .rr-pwa-install-prompt__body strong,
    .rr-pwa-install-prompt__body span {
        display: block;
    }

    .rr-pwa-install-prompt__body strong {
        color: #222222;
        font-size: .95rem;
        line-height: 1.2;
    }

    .rr-pwa-install-prompt__body span {
        color: #555555;
        font-size: .84rem;
        line-height: 1.35;
        margin-top: .18rem;
    }

    .rr-pwa-install-prompt__actions {
        grid-column: 1 / -1;
        display: flex;
        gap: .55rem;
    }

    .rr-pwa-install-prompt__actions .btn {
        flex: 1 1 0;
    }

    @media (max-width: 767.98px) {
        .rr-pwa-update-toast,
        .rr-pwa-push-prompt,
        .rr-pwa-install-prompt {
            bottom: 5.1rem;
            border-radius: 1rem;
            padding: .95rem;
        }
    }
</style>

<script>
    (function () {
      const isLoggedIn = <cfif structKeyExists(REQUEST, "Usuario") AND isObject(REQUEST.Usuario) AND REQUEST.Usuario.logado>true<cfelse>false</cfif>;
      const isStandalone = window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
      const storageDismissKey = 'rr-pwa-push-dismissed-at';
      const storageSessionPromptKey = 'rr-pwa-push-session-prompt-seen';
      const storageDismissDays = 7;

      function getDismissedAt() {
        try {
          return parseInt(window.localStorage.getItem(storageDismissKey) || '0', 10) || 0;
        } catch (e) {
          return 0;
        }
      }

      function isDismissCooldownActive() {
        const dismissedAt = getDismissedAt();

        if (!dismissedAt) {
          return false;
        }

        return (Date.now() - dismissedAt) < (storageDismissDays * 24 * 60 * 60 * 1000);
      }

      function setDismissedNow() {
        try {
          window.localStorage.setItem(storageDismissKey, String(Date.now()));
        } catch (e) {}
      }

      function hasSessionPromptBeenSeen() {
        try {
          return window.sessionStorage.getItem(storageSessionPromptKey) === '1';
        } catch (e) {
          return false;
        }
      }

      function markSessionPromptSeen() {
        try {
          window.sessionStorage.setItem(storageSessionPromptKey, '1');
        } catch (e) {}
      }

      function removeExistingPrompt() {
        const existing = document.getElementById('rrPwaPushPrompt');

        if (existing) {
          existing.remove();
        }
      }

      function showErrorMessage(promptEl, message) {
        const textEl = promptEl ? promptEl.querySelector('.rr-pwa-push-prompt__text') : null;

        if (textEl && message) {
          textEl.textContent = message;
        }
      }

      function renderPushPrompt(mode) {
        removeExistingPrompt();
        markSessionPromptSeen();

        const isReactivation = mode === 'reactivate';
        const pushI18n = {
          app: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptApp"))#</cfoutput>',
          activateTitle: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptActivateTitle"))#</cfoutput>',
          reactivateTitle: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptReactivateTitle"))#</cfoutput>',
          activateText: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptActivateText"))#</cfoutput>',
          reactivateText: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptReactivateText"))#</cfoutput>',
          dismiss: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptDismiss"))#</cfoutput>',
          activating: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptActivating"))#</cfoutput>',
          reactivating: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptReactivating"))#</cfoutput>',
          retry: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptRetry"))#</cfoutput>',
          retryReactivate: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptRetryReactivate"))#</cfoutput>',
          activationFailed: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.activationFailed"))#</cfoutput>',
          source: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptSource"))#</cfoutput>'
        };
        const title = isReactivation
          ? pushI18n.reactivateTitle
          : pushI18n.activateTitle;
        const text = isReactivation
          ? pushI18n.reactivateText
          : pushI18n.activateText;
        const acceptLabel = isReactivation
          ? '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.menuReactivate"))#</cfoutput>'
          : '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.menuActivate"))#</cfoutput>';

        const wrapper = document.createElement('div');
        wrapper.id = 'rrPwaPushPrompt';
        wrapper.className = 'rr-pwa-push-prompt';
        wrapper.innerHTML = `
          <div class="rr-pwa-push-prompt__eyebrow">
            <i class="fa-solid fa-bell"></i>
            <span>${pushI18n.app}</span>
          </div>
          <p class="rr-pwa-push-prompt__title">${title}</p>
          <p class="rr-pwa-push-prompt__text">${text}</p>
          <div class="rr-pwa-push-prompt__actions">
            <button type="button" class="btn btn-dark shadow-0" id="rrPwaPushPromptAccept">${acceptLabel}</button>
            <button type="button" class="btn btn-light shadow-0" id="rrPwaPushPromptDismiss">${pushI18n.dismiss}</button>
          </div>
        `;

        document.body.appendChild(wrapper);

        const acceptButton = wrapper.querySelector('#rrPwaPushPromptAccept');
        const dismissButton = wrapper.querySelector('#rrPwaPushPromptDismiss');
        let permissionRequestPromise = null;

        dismissButton.addEventListener('click', function () {
          setDismissedNow();
          removeExistingPrompt();
        });

        function primePushPermissionRequest() {
          if (!('Notification' in window) || Notification.permission === 'granted' || permissionRequestPromise) {
            return;
          }

          permissionRequestPromise = Notification.requestPermission().catch(function () {
            return 'denied';
          });
        }

        acceptButton.addEventListener('pointerdown', primePushPermissionRequest);
        acceptButton.addEventListener('keydown', function (event) {
          if (event.key === 'Enter' || event.key === ' ') {
            primePushPermissionRequest();
          }
        });

        acceptButton.addEventListener('click', async function () {
          acceptButton.disabled = true;
          dismissButton.disabled = true;
          acceptButton.textContent = isReactivation ? pushI18n.reactivating : pushI18n.activating;

          try {
            const permission = Notification.permission === 'granted'
              ? 'granted'
              : await (permissionRequestPromise || Notification.requestPermission());

            if (permission !== 'granted') {
              throw new Error(window.rrPushI18n.permissionDenied);
            }

            const result = await window.RRPwaPush.subscribe(pushI18n.source, {
              permission
            });

            if (!result || !result.success) {
              throw new Error(result && result.message ? result.message : pushI18n.activationFailed);
            }

            removeExistingPrompt();
          } catch (error) {
            acceptButton.disabled = false;
            dismissButton.disabled = false;
            acceptButton.textContent = isReactivation ? pushI18n.retryReactivate : pushI18n.retry;
            showErrorMessage(wrapper, error && error.message ? error.message : pushI18n.activationFailed);
          }
        });
      }

async function maybePromptForPush() {
  if (!isLoggedIn || !window.RRPwaPush) {
    return;
  }

  if (!('Notification' in window)) {
    return;
  }

        if (isDismissCooldownActive()) {
          return;
        }

        if (hasSessionPromptBeenSeen()) {
          return;
        }

        try {
          const deviceSubscription = await window.RRPwaPush.getSubscription();
          const hasDeviceSubscription = !!(
            deviceSubscription
            && typeof deviceSubscription === 'object'
            && typeof deviceSubscription.endpoint === 'string'
            && deviceSubscription.endpoint.trim()
          );
          const status = await window.RRPwaPush.getStatus();

          if (!status || !status.success || !status.enabled) {
            return;
          }

          if (hasDeviceSubscription) {
            return;
          }

          if (Notification.permission === 'default') {
            renderPushPrompt('activate');
            return;
          }

          if (Notification.permission === 'granted') {
            renderPushPrompt('reactivate');
          }
        } catch (e) {}
      }

      window.addEventListener('load', function () {
        window.RREntryPrompts.enqueue("push", async function () { await maybePromptForPush(); return !!document.getElementById("rrPwaPushPrompt"); }, 20);
      });
    })();
</script>

<script>
    function rrPwaEscapeHtml(value) {
      return String(value || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
    }

    function rrPwaCloseSheet() {
      const existing = document.getElementById('rrPwaSheet');

      if (existing) {
        existing.remove();
      }
    }

    function rrPwaRenderSheet(options = {}) {
      rrPwaCloseSheet();

      const wrapper = document.createElement('div');
      wrapper.id = 'rrPwaSheet';
      wrapper.className = `rr-pwa-sheet${options.centered ? ' is-centered' : ''}`;
      wrapper.innerHTML = `
        <div class="rr-pwa-sheet__card" role="dialog" aria-modal="true" aria-label="${rrPwaEscapeHtml(options.title)}">
          <div class="rr-pwa-sheet__head">
            <div>
              <p class="rr-pwa-sheet__title">${rrPwaEscapeHtml(options.title)}</p>
              <p class="rr-pwa-sheet__text">${rrPwaEscapeHtml(options.text)}</p>
            </div>
            <button type="button" class="rr-pwa-sheet__close" aria-label="${rrPwaEscapeHtml(options.closeLabel)}" id="rrPwaSheetClose">
              <i class="fa-solid fa-xmark"></i>
            </button>
          </div>
          ${options.body || ''}
        </div>
      `;

      document.body.appendChild(wrapper);

      wrapper.addEventListener('click', function (event) {
        if (event.target === wrapper) {
          rrPwaCloseSheet();
        }
      });

      const closeButton = wrapper.querySelector('#rrPwaSheetClose');

      if (closeButton) {
        closeButton.addEventListener('click', rrPwaCloseSheet);
      }

      return wrapper;
    }

    function rrOpenIosInstallInstructions() {
      const i18n = {
        title: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.iosInstallTitle"))#</cfoutput>',
        text: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.iosInstallText"))#</cfoutput>',
        stepShare: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.iosInstallStepShare"))#</cfoutput>',
        stepHome: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.iosInstallStepHome"))#</cfoutput>',
        close: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.close"))#</cfoutput>'
      };

      rrPwaRenderSheet({
        title: i18n.title,
        text: i18n.text,
        closeLabel: i18n.close,
        body: `
          <ul class="rr-pwa-sheet__steps">
            <li><span><i class="fa-solid fa-arrow-up-from-bracket"></i>${rrPwaEscapeHtml(i18n.stepShare)}</span></li>
            <li><span><i class="fa-solid fa-square-plus"></i>${rrPwaEscapeHtml(i18n.stepHome)}</span></li>
          </ul>
        `
      });
    }

    async function rrOpenPushPreferences() {
      if (!window.RRPwaPush || typeof window.RRPwaPush.getPreferences !== 'function') {
        alert(window.rrPushI18n.activationUnavailable);
        return;
      }

      const i18n = {
        title: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferencesTitle"))#</cfoutput>',
        text: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferencesText"))#</cfoutput>',
        general: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferenceGeneral"))#</cfoutput>',
        results: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferenceResults"))#</cfoutput>',
        challenges: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferenceChallenges"))#</cfoutput>',
        support: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferenceSupport"))#</cfoutput>',
        system: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferenceSystem"))#</cfoutput>',
        save: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferencesSave"))#</cfoutput>',
        saved: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferencesSaved"))#</cfoutput>',
        error: '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.preferencesError"))#</cfoutput>',
        close: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.close"))#</cfoutput>'
      };

      try {
        const payload = await window.RRPwaPush.getPreferences();

        if (!payload || !payload.success || !payload.preferences) {
          throw new Error(payload && payload.message ? payload.message : i18n.error);
        }

        const prefs = payload.preferences;
        const rows = [
          { key: 'receberPush', label: i18n.general, value: prefs.receberPush },
          { key: 'resultados', label: i18n.results, value: prefs.resultados },
          { key: 'desafios', label: i18n.challenges, value: prefs.desafios },
          { key: 'atendimento', label: i18n.support, value: prefs.atendimento },
          { key: 'sistema', label: i18n.system, value: prefs.sistema }
        ];
        const body = `
          <div class="rr-pwa-preference-list">
            ${rows.map((row) => `
              <label class="rr-pwa-preference-row">
                <span>${rrPwaEscapeHtml(row.label)}</span>
                <input type="checkbox" data-push-preference="${rrPwaEscapeHtml(row.key)}"${row.value ? ' checked' : ''}>
              </label>
            `).join('')}
          </div>
          <p class="rr-pwa-sheet__message" id="rrPwaPreferencesMessage"></p>
          <div class="rr-pwa-sheet__actions">
            <button type="button" class="btn btn-warning shadow-0" id="rrPwaPreferencesSave">${rrPwaEscapeHtml(i18n.save)}</button>
          </div>
        `;
        const sheet = rrPwaRenderSheet({
          title: i18n.title,
          text: i18n.text,
          closeLabel: i18n.close,
          body,
          centered: true
        });
        const saveButton = sheet.querySelector('#rrPwaPreferencesSave');
        const messageEl = sheet.querySelector('#rrPwaPreferencesMessage');

        saveButton.addEventListener('click', async function () {
          const nextPreferences = {};

          sheet.querySelectorAll('[data-push-preference]').forEach((input) => {
            nextPreferences[input.getAttribute('data-push-preference')] = input.checked;
          });

          saveButton.disabled = true;

          try {
            const result = await window.RRPwaPush.updatePreferences(nextPreferences);

            if (!result || !result.success) {
              throw new Error(result && result.message ? result.message : i18n.error);
            }

            if (messageEl) {
              messageEl.textContent = result.message || i18n.saved;
            }
          } catch (error) {
            if (messageEl) {
              messageEl.textContent = error && error.message ? error.message : i18n.error;
            }
          } finally {
            saveButton.disabled = false;
          }
        });
      } catch (error) {
        alert(error && error.message ? error.message : i18n.error);
      }
    }

    async function rrOpenPushActivation() {
      if (!window.RRPwaPush || typeof window.RRPwaPush.subscribe !== 'function') {
        alert(window.rrPushI18n.activationUnavailable);
        return;
      }

      if (!('Notification' in window)) {
        alert(window.rrPushI18n.browserUnsupported);
        return;
      }

      try {
        const status = await window.RRPwaPush.getStatus();

        if (!status || !status.success || !status.enabled) {
          throw new Error(window.rrPushI18n.notEnabled);
        }

        const currentSubscription = await window.RRPwaPush.getSubscription();
        const hasDeviceSubscription = !!(
          currentSubscription
          && typeof currentSubscription === 'object'
          && typeof currentSubscription.endpoint === 'string'
          && currentSubscription.endpoint.trim()
        );

        if (Notification.permission === 'denied') {
          alert(window.rrPushI18n.siteBlocked);
          return;
        }

        if (Notification.permission === 'granted' && hasDeviceSubscription) {
          alert(window.rrPushI18n.alreadyActive);
          return;
        }

        const result = await window.RRPwaPush.subscribe('<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.promptSource"))#</cfoutput>');

        if (!result || !result.success) {
          throw new Error(result && result.message ? result.message : window.rrPushI18n.activationFailed);
        }

        if (typeof window.rrRefreshPushMenu === 'function') {
          window.rrRefreshPushMenu();
        }

        alert(result.message || window.rrPushI18n.subscriptionActivated);
      } catch (error) {
        alert(error && error.message ? error.message : window.rrPushI18n.activationFailed);
      }
    }

    async function rrSendTestPush() {
      if (!window.RRPwaPush || typeof window.RRPwaPush.sendTestPush !== 'function') {
        alert(window.rrPushI18n.testUnavailable);
        return;
      }

      try {
        const result = await window.RRPwaPush.sendTestPush();
        alert(result.message || window.rrPushI18n.testSent);
      } catch (error) {
        alert(error && error.message ? error.message : window.rrPushI18n.testFailed);
      }
    }
</script>

<script>
    (function () {
      const isStandalone = window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
      const pushMenuItem = document.getElementById('rrPwaPushMenuItem');
      const pushMenuLink = document.getElementById('rrPwaPushMenuLink');
      const pushMenuLabel = document.getElementById('rrPwaPushMenuLabel');
      const pushPreferencesMenuItem = document.getElementById('rrPwaPushPreferencesMenuItem');
      const pushPreferencesMenuLink = document.getElementById('rrPwaPushPreferencesMenuLink');
      const notificationsPreferencesButton = document.getElementById('rrNotificationsPreferencesButton');
      const notificationsMarkAllReadButton = document.getElementById('rrNotificationsMarkAllRead');
      const notificationsUnreadBadge = document.getElementById('rrNotificationsUnreadBadge');
      const installMenuItem = document.getElementById('rrPwaInstallMenuItem');
      const installMenuLink = document.getElementById('rrPwaInstallMenuLink');
      const userAgent = window.navigator.userAgent || '';
      const isIos = /iphone|ipad|ipod/i.test(userAgent) || (window.navigator.platform === 'MacIntel' && window.navigator.maxTouchPoints > 1);
      const isIosStandaloneEligible = isIos && !isStandalone;

      let deferredInstallPrompt = null;

      function setPushMenuVisibility(visible) {
        if (pushMenuItem) {
          pushMenuItem.style.display = visible ? '' : 'none';
        }
      }

      function setPushPreferencesMenuVisibility(visible) {
        if (pushPreferencesMenuItem) {
          pushPreferencesMenuItem.style.display = visible ? '' : 'none';
        }
      }

      function setInstallMenuVisibility(visible) {
        if (installMenuItem) {
          installMenuItem.style.display = visible ? '' : 'none';
        }
      }

      async function refreshPushMenu() {
        if (!pushMenuLink || !window.RRPwaPush || !('Notification' in window)) {
          setPushMenuVisibility(false);
          setPushPreferencesMenuVisibility(false);
          return;
        }

        try {
          const status = await window.RRPwaPush.getStatus();

          if (!status || !status.success || !status.enabled) {
            setPushMenuVisibility(false);
            setPushPreferencesMenuVisibility(false);
            return;
          }

          const currentSubscription = await window.RRPwaPush.getSubscription();
          const hasDeviceSubscription = !!(
            currentSubscription
            && typeof currentSubscription === 'object'
            && typeof currentSubscription.endpoint === 'string'
            && currentSubscription.endpoint.trim()
          );

          let label = '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.menuActivate"))#</cfoutput>';

          if (Notification.permission === 'denied') {
            label = '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.menuEnable"))#</cfoutput>';
          } else if (Notification.permission === 'granted' && hasDeviceSubscription) {
            label = '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.menuActive"))#</cfoutput>';
          } else if (Notification.permission === 'granted') {
            label = '<cfoutput>#JSStringFormat(REQUEST.t("notifications.push.menuReactivate"))#</cfoutput>';
          }

          if (pushMenuLabel) {
            pushMenuLabel.textContent = label;
          }

          setPushMenuVisibility(true);
          setPushPreferencesMenuVisibility(true);
        } catch (error) {
          setPushMenuVisibility(false);
          setPushPreferencesMenuVisibility(false);
        }
      }

      window.rrRefreshPushMenu = refreshPushMenu;

      if (pushMenuLink) {
        pushMenuLink.addEventListener('click', async function (event) {
          event.preventDefault();
          await rrOpenPushActivation();
        });
      }

      if (pushPreferencesMenuLink) {
        pushPreferencesMenuLink.addEventListener('click', async function (event) {
          event.preventDefault();
          await rrOpenPushPreferences();
        });
      }

      if (notificationsPreferencesButton) {
        notificationsPreferencesButton.addEventListener('click', async function (event) {
          event.preventDefault();
          await rrOpenPushPreferences();
        });
      }

      if (notificationsMarkAllReadButton) {
        notificationsMarkAllReadButton.addEventListener('click', async function (event) {
          event.preventDefault();
          event.stopPropagation();

          if (notificationsMarkAllReadButton.disabled) {
            return;
          }

          notificationsMarkAllReadButton.disabled = true;
          notificationsMarkAllReadButton.setAttribute('aria-busy', 'true');

          try {
            const response = await fetch('/api/notifications/mark-read.cfm', {
              method: 'POST',
              credentials: 'same-origin',
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
              },
              body: JSON.stringify({ all: true })
            });
            const payload = await response.json().catch(function () {
              return null;
            });

            if (!response.ok || !payload || payload.success !== true) {
              throw new Error('mark-all-read-failed');
            }

            document.querySelectorAll('#rrNotificationsHeaderMenu .rr-notification-item').forEach(function (item) {
              item.classList.add('is-read');
            });

            if (notificationsUnreadBadge) {
              notificationsUnreadBadge.textContent = '';
              notificationsUnreadBadge.dataset.unreadCount = '0';
              notificationsUnreadBadge.hidden = true;
            }

            const notificationsHeaderIcon = document.getElementById('rrNotificationsHeaderIcon');
            if (notificationsHeaderIcon) {
              notificationsHeaderIcon.classList.remove('fa-solid');
              notificationsHeaderIcon.classList.add('fa-regular');
            }
          } catch (error) {
            notificationsMarkAllReadButton.disabled = false;
            alert('<cfoutput>#JSStringFormat(REQUEST.t("common.header.markAllNotificationsReadError"))#</cfoutput>');
          } finally {
            notificationsMarkAllReadButton.removeAttribute('aria-busy');
          }
        });
      }

      window.addEventListener('load', function () {
        window.setTimeout(refreshPushMenu, 800);
      });

      const installPromptDismissStorageKey = 'rr-pwa-install-prompt-dismissed-at';
      const installPromptCooldownMs = 14 * 24 * 60 * 60 * 1000;
      let installPromptScheduled = false;

      const installPromptI18n = {
        title: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.installPromptTitle"))#</cfoutput>',
        text: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.installPromptText"))#</cfoutput>',
        action: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.installPromptAction"))#</cfoutput>',
        dismiss: '<cfoutput>#JSStringFormat(REQUEST.t("common.pwa.installPromptDismiss"))#</cfoutput>'
      };

      function getInstallPromptDismissedAt() {
        try {
          return parseInt(window.localStorage.getItem(installPromptDismissStorageKey) || '0', 10) || 0;
        } catch (error) {
          return 0;
        }
      }

      function isInstallPromptCooldownActive() {
        const dismissedAt = getInstallPromptDismissedAt();
        return dismissedAt > 0 && (Date.now() - dismissedAt) < installPromptCooldownMs;
      }

      function postponeInstallPrompt() {
        try {
          window.localStorage.setItem(installPromptDismissStorageKey, String(Date.now()));
        } catch (error) {}
      }

      function closeInstallPrompt() {
        const prompt = document.getElementById('rrPwaInstallPrompt');

        if (prompt) {
          prompt.remove();
        }
      }

      function isInstallPromptBlocked() {
        return document.body.classList.contains('rr-mobile-onboarding-open')
          || !!document.querySelector('.modal.show, .rr-pwa-sheet');
      }

      function renderInstallPrompt() {
        if (isStandalone || isInstallPromptCooldownActive() || document.getElementById('rrPwaInstallPrompt')) {
          return;
        }

        const wrapper = document.createElement('div');
        wrapper.id = 'rrPwaInstallPrompt';
        wrapper.className = 'rr-pwa-install-prompt';
        wrapper.innerHTML = `
          <div class="rr-pwa-install-prompt__icon"><i class="fa-solid fa-mobile-screen-button"></i></div>
          <div class="rr-pwa-install-prompt__body">
            <strong>${rrPwaEscapeHtml(installPromptI18n.title)}</strong>
            <span>${rrPwaEscapeHtml(installPromptI18n.text)}</span>
          </div>
          <div class="rr-pwa-install-prompt__actions">
            <button type="button" class="btn btn-dark shadow-0" id="rrPwaInstallPromptDismiss">${rrPwaEscapeHtml(installPromptI18n.dismiss)}</button>
            <button type="button" class="btn btn-warning shadow-0" id="rrPwaInstallPromptAction">${rrPwaEscapeHtml(installPromptI18n.action)}</button>
          </div>
        `;

        document.body.appendChild(wrapper);

        const dismissButton = wrapper.querySelector('#rrPwaInstallPromptDismiss');
        const actionButton = wrapper.querySelector('#rrPwaInstallPromptAction');

        dismissButton.addEventListener('click', function () {
          postponeInstallPrompt();
          closeInstallPrompt();
        });

        actionButton.addEventListener('click', async function () {
          if (!deferredInstallPrompt) {
            if (isIosStandaloneEligible) {
              postponeInstallPrompt();
              closeInstallPrompt();
              rrOpenIosInstallInstructions();
            }

            return;
          }

          deferredInstallPrompt.prompt();

          try {
            await deferredInstallPrompt.userChoice;
          } catch (error) {}

          postponeInstallPrompt();
          deferredInstallPrompt = null;
          setInstallMenuVisibility(false);
          closeInstallPrompt();
        });
      }

      function scheduleInstallPrompt() {
        if (installPromptScheduled || isStandalone || isInstallPromptCooldownActive()) {
          return;
        }

        installPromptScheduled = true;

        window.RREntryPrompts.enqueue("install", function () {
          if (isInstallPromptBlocked()) return false;
          renderInstallPrompt();
          return !!document.getElementById("rrPwaInstallPrompt");
        }, 10);
      }

      if (isStandalone) {
        setInstallMenuVisibility(false);
        return;
      }

      if (isIosStandaloneEligible) {
        setInstallMenuVisibility(true);

        window.addEventListener('load', function () {
          scheduleInstallPrompt();
        });
      }

      window.addEventListener('beforeinstallprompt', function (event) {
        event.preventDefault();
        deferredInstallPrompt = event;
        setInstallMenuVisibility(true);
        scheduleInstallPrompt();
      });

      window.addEventListener('appinstalled', function () {
        deferredInstallPrompt = null;
        setInstallMenuVisibility(false);
        closeInstallPrompt();
      });

      if (installMenuLink) {
        installMenuLink.addEventListener('click', async function (event) {
          event.preventDefault();

          if (!deferredInstallPrompt) {
            if (isIosStandaloneEligible) {
              rrOpenIosInstallInstructions();
            }

            return;
          }

          deferredInstallPrompt.prompt();

          try {
            await deferredInstallPrompt.userChoice;
          } catch (error) {}

          postponeInstallPrompt();
          deferredInstallPrompt = null;
          setInstallMenuVisibility(false);
          closeInstallPrompt();
        });
      }
    })();
</script>

<!--- Flag/secret guarded, request-idempotent audience bootstrap. --->
<cfinclude template="../analytics/bootstrap.cfm" />
<cfinclude template="../crm-interno/bootstrap.cfm" />

<!-- Ticket Sports tag (inscription.js) -->
<!---<script>
    (function (d, t, a, el, s) {{
        el = d.createElement(t); el.async = 1; el.src = a;
        s = d.getElementsByTagName(t)[0]; s.parentNode.insertBefore(el, s);
    }})(document, 'script', '//site.ticketsports.com.br/inscricao/widget/v1/inscription.js');
</script>--->
