<cfsetting requesttimeout="20" showdebugoutput="false"/>
<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../../includes/backend/agenda_service.cfm"/>

<cfparam name="URL.agenda" default=""/>
<cfparam name="URL.visao" default=""/>
<cfparam name="URL.embed_id" default=""/>
<cfset VARIABLES.agendaRenderStartedAt = getTickCount()/>
<cfset VARIABLES.agendaRenderStatus = 200/>
<cfset VARIABLES.agendaRenderMessage = ""/>
<cfset VARIABLES.agendaRenderView = "futuros"/>
<cfset qAgendaRenderAgenda = queryNew("id_agenda,chave_publica,nome,descricao,id_usuario,usuario_nome,usuario_email,modo,visao_padrao,dominio_permitido,permitir_subdominios,limite_eventos,ordenacao,tema_embed,cor_card_data,fonte_cards,raio_cards,status")/>
<cfset qAgendaRenderEvents = queryNew("id_evento,nome_evento,tag,cidade,estado,pais,data_inicial,data_final,tipo_corrida,status_evento,url_resultado,url_imagem,url_imagem_listagem,imagem,destaque,id_agrega_evento,agregador_nome,distancias_json,total_concluintes,ordem_agenda")/>

<cfif NOT agendaServiceTablesReady()>
    <cfset VARIABLES.agendaRenderStatus = 503/>
    <cfset VARIABLES.agendaRenderMessage = "A Agenda esta temporariamente indisponivel."/>
<cfelse>
    <cfset qAgendaRenderAgenda = agendaServiceGetAgendaByKey(trim(URL.agenda), true)/>
    <cfif NOT qAgendaRenderAgenda.recordcount>
        <cfset VARIABLES.agendaRenderStatus = 404/>
        <cfset VARIABLES.agendaRenderMessage = "Agenda nao encontrada ou indisponivel."/>
    <cfelseif agendaServiceRateLimitExceeded(qAgendaRenderAgenda.id_agenda)>
        <cfset VARIABLES.agendaRenderStatus = 429/>
        <cfset VARIABLES.agendaRenderMessage = "Limite temporario de requisicoes excedido."/>
    <cfelse>
        <cfset VARIABLES.agendaRenderSource = agendaServiceRequestSource()/>
        <cfif NOT agendaServiceHostAllowed(qAgendaRenderAgenda.dominio_permitido, agendaServiceNormalizeBoolean(qAgendaRenderAgenda.permitir_subdominios), VARIABLES.agendaRenderSource.host)>
            <cfset VARIABLES.agendaRenderStatus = 403/>
            <cfset VARIABLES.agendaRenderMessage = "Este dominio nao esta autorizado a exibir a Agenda."/>
        <cfelse>
            <cfset VARIABLES.agendaRenderView = agendaServiceNormalizeView(URL.visao, "futuros")/>
            <cfset qAgendaRenderEvents = agendaServiceResolveEvents(qAgendaRenderAgenda.id_agenda, VARIABLES.agendaRenderView, qAgendaRenderAgenda.limite_eventos)/>
        </cfif>
    </cfif>
</cfif>

<cfset VARIABLES.agendaRenderTheme = qAgendaRenderAgenda.recordcount ? agendaServiceNormalizeTheme(agendaServiceQueryValue(qAgendaRenderAgenda, "tema_embed", 1)) : "escuro"/>
<cfset VARIABLES.agendaRenderDateColor = qAgendaRenderAgenda.recordcount ? agendaServiceNormalizeHexColor(agendaServiceQueryValue(qAgendaRenderAgenda, "cor_card_data", 1)) : agendaServiceNormalizeHexColor()/>
<cfset VARIABLES.agendaRenderCardFont = qAgendaRenderAgenda.recordcount ? agendaServiceNormalizeCardFont(agendaServiceQueryValue(qAgendaRenderAgenda, "fonte_cards", 1)) : "trebuchet"/>
<cfset VARIABLES.agendaRenderCardRadius = qAgendaRenderAgenda.recordcount ? agendaServiceNormalizeCardRadius(agendaServiceQueryValue(qAgendaRenderAgenda, "raio_cards", 1)) : "atual"/>
<cfset VARIABLES.agendaRenderDateTextColor = agendaServiceContrastColor(VARIABLES.agendaRenderDateColor)/>
<cfset VARIABLES.agendaRenderCspNonce = lCase(hash(createUUID() & ":" & getTickCount() & ":" & randRange(100000, 999999), "SHA-256"))/>

<cfif qAgendaRenderAgenda.recordcount>
    <cfheader name="Content-Security-Policy" value="default-src 'none'; style-src 'nonce-#VARIABLES.agendaRenderCspNonce#'; style-src-attr 'none'; script-src 'nonce-#VARIABLES.agendaRenderCspNonce#'; script-src-attr 'none'; frame-ancestors #agendaServiceCspFrameAncestors(qAgendaRenderAgenda.dominio_permitido, agendaServiceNormalizeBoolean(qAgendaRenderAgenda.permitir_subdominios))#; base-uri 'none'; form-action 'none'"/>
<cfelse>
    <cfheader name="Content-Security-Policy" value="default-src 'none'; style-src 'nonce-#VARIABLES.agendaRenderCspNonce#'; style-src-attr 'none'; script-src 'nonce-#VARIABLES.agendaRenderCspNonce#'; script-src-attr 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'"/>
</cfif>
<cfheader name="X-Content-Type-Options" value="nosniff"/>
<cfheader name="Referrer-Policy" value="no-referrer"/>
<cfheader name="Vary" value="Referer, Origin"/>
<cfheader name="Cache-Control" value="private, max-age=120"/>
<cfif VARIABLES.agendaRenderStatus NEQ 200><cfheader statuscode="#VARIABLES.agendaRenderStatus#" statustext="Agenda unavailable"/></cfif>
<cfcontent type="text/html; charset=utf-8" reset="true"/>
<!doctype html>
<html lang="pt-BR" data-theme="<cfoutput>#htmlEditFormat(VARIABLES.agendaRenderTheme)#</cfoutput>" data-card-font="<cfoutput>#htmlEditFormat(VARIABLES.agendaRenderCardFont)#</cfoutput>" data-card-radius="<cfoutput>#htmlEditFormat(VARIABLES.agendaRenderCardRadius)#</cfoutput>">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title><cfif qAgendaRenderAgenda.recordcount><cfoutput>#htmlEditFormat(qAgendaRenderAgenda.nome)#</cfoutput><cfelse>Agenda Road Runners</cfif></title>
  <style nonce="<cfoutput>#VARIABLES.agendaRenderCspNonce#</cfoutput>">
    :root {
      color-scheme: dark;
      --rr-accent: #fab120;
      --rr-card: #1b2027;
      --rr-card-2: #232a33;
      --rr-text: #f7f8fa;
      --rr-muted: #aeb7c2;
      --rr-border: rgba(255, 255, 255, .1);
      --rr-chip: rgba(255, 255, 255, .075);
      --rr-chip-border: rgba(255, 255, 255, .06);
      --rr-date: <cfoutput>#htmlEditFormat(VARIABLES.agendaRenderDateColor)#</cfoutput>;
      --rr-date-text: <cfoutput>#htmlEditFormat(VARIABLES.agendaRenderDateTextColor)#</cfoutput>;
      --rr-card-font: "Trebuchet MS", "Avenir Next", sans-serif;
      --rr-card-radius: 16px;
      --rr-date-radius: 12px;
    }

    :root[data-theme="claro"] {
      color-scheme: light;
      --rr-card: rgba(255, 255, 255, .96);
      --rr-card-2: rgba(247, 248, 250, .96);
      --rr-text: #171a1f;
      --rr-muted: #5f6874;
      --rr-border: rgba(17, 24, 39, .14);
      --rr-chip: rgba(17, 24, 39, .07);
      --rr-chip-border: rgba(17, 24, 39, .08);
    }

    :root[data-card-font="verdana"] { --rr-card-font: Verdana, Geneva, sans-serif; }
    :root[data-card-font="georgia"] { --rr-card-font: Georgia, "Times New Roman", serif; }
    :root[data-card-font="tahoma"] { --rr-card-font: Tahoma, Geneva, sans-serif; }
    :root[data-card-font="monospace"] { --rr-card-font: "Courier New", Courier, monospace; }
    :root[data-card-radius="medio"] { --rr-card-radius: 10px; --rr-date-radius: 8px; }
    :root[data-card-radius="suave"] { --rr-card-radius: 5px; --rr-date-radius: 4px; }
    :root[data-card-radius="reto"] { --rr-card-radius: 0; --rr-date-radius: 0; }

    * { box-sizing: border-box; }
    html, body { background: transparent !important; margin: 0; min-width: 0; overflow-x: hidden; padding: 0; width: 100%; }
    body { background: transparent; color: var(--rr-text); font-family: "Trebuchet MS", "Avenir Next", sans-serif; }
    .rr-agenda { margin: 0 auto; max-width: 680px; min-width: 0; width: 100%; }
    .rr-agenda-header { align-items: end; display: flex; gap: 16px; justify-content: space-between; margin-bottom: 12px; padding: 0 2px; }
    .rr-agenda-title { font-size: clamp(18px, 4vw, 24px); line-height: 1.1; margin: 0; }
    .rr-agenda-view { background: var(--rr-chip); border: 1px solid var(--rr-chip-border); border-radius: 999px; color: var(--rr-text); font-size: 10px; font-weight: 800; letter-spacing: .07em; padding: 6px 9px; text-transform: uppercase; white-space: nowrap; }
    .rr-card { background: linear-gradient(135deg, var(--rr-card-2), var(--rr-card)); border: 1px solid var(--rr-border); border-radius: var(--rr-card-radius); color: var(--rr-text); display: grid; font-family: var(--rr-card-font); gap: 14px; grid-template-columns: 62px minmax(0, 1fr); margin-bottom: 10px; max-width: 100%; overflow: hidden; padding: 14px; text-decoration: none; transition: border-color .18s ease, transform .18s ease; width: 100%; }
    .rr-card:hover, .rr-card:focus-visible { border-color: var(--rr-date); outline: 0; transform: translateY(-1px); }
    .rr-date { align-self: start; background: var(--rr-date); border-radius: var(--rr-date-radius); color: var(--rr-date-text); line-height: 1; min-width: 0; padding: 9px 4px 8px; text-align: center; }
    .rr-date-day { display: block; font-size: 22px; font-weight: 900; }
    .rr-date-month { display: block; font-size: 10px; font-weight: 900; margin-top: 4px; text-transform: uppercase; }
    .rr-date-year { display: block; font-size: 9px; font-weight: 700; margin-top: 3px; opacity: .7; }
    .rr-card-main { min-width: 0; }
    .rr-card-title { font-size: 16px; font-weight: 800; line-height: 1.25; margin: 1px 0 5px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .rr-card-location { color: var(--rr-muted); font-size: 12px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .rr-card-location svg { height: 12px; margin-right: 4px; vertical-align: -2px; width: 12px; }
    .rr-tags { display: flex; flex-wrap: wrap; gap: 5px; margin-top: 10px; }
    .rr-tag { background: var(--rr-chip); border: 1px solid var(--rr-chip-border); border-radius: 999px; color: var(--rr-text); font-size: 10px; font-weight: 700; padding: 4px 7px; }
    .rr-empty, .rr-error { background: var(--rr-card); border: 1px solid var(--rr-border); border-radius: var(--rr-card-radius); color: var(--rr-muted); padding: 28px 18px; text-align: center; }
    .rr-error { color: #ffb2b2; }
    #rr-agenda-powered { align-items: center !important; color: var(--rr-muted) !important; display: flex !important; font-size: 9px !important; gap: 5px !important; justify-content: center !important; letter-spacing: .035em !important; opacity: .72 !important; padding: 8px 3px 0 !important; visibility: visible !important; }
    #rr-agenda-powered[hidden] { display: flex !important; }
    #rr-agenda-powered .rr-powered-brand { align-items: center !important; background: rgba(15, 18, 22, .86) !important; border-radius: 999px !important; display: inline-flex !important; padding: 2px 6px !important; visibility: visible !important; }
    #rr-agenda-powered .rr-powered-brand svg { display: block !important; height: 14px !important; visibility: visible !important; width: auto !important; }

    @media (max-width: 380px) {
      .rr-agenda-header { align-items: start; flex-direction: column; gap: 4px; }
      .rr-card { gap: 10px; grid-template-columns: 52px minmax(0, 1fr); padding: 11px; }
      .rr-date-day { font-size: 19px; }
      .rr-card-title { font-size: 14px; }
    }

    @media (max-width: 300px) {
      .rr-agenda-header { gap: 6px; }
      .rr-agenda-title { font-size: 17px; overflow-wrap: anywhere; }
      .rr-agenda-view { font-size: 9px; letter-spacing: .04em; padding: 5px 7px; white-space: normal; }
      .rr-card { gap: 8px; grid-template-columns: 46px minmax(0, 1fr); padding: 9px; }
      .rr-date { padding: 7px 2px; }
      .rr-date-day { font-size: 17px; }
      .rr-date-month { font-size: 9px; }
      .rr-card-title { display: -webkit-box; overflow-wrap: anywhere; text-overflow: initial; white-space: normal; -webkit-box-orient: vertical; -webkit-line-clamp: 2; }
      .rr-card-location { overflow-wrap: anywhere; text-overflow: initial; white-space: normal; }
      .rr-tag { font-size: 9px; padding: 3px 6px; }
    }
  </style>
</head>
<body>
  <main class="rr-agenda">
    <cfif VARIABLES.agendaRenderStatus NEQ 200>
      <div class="rr-error"><cfoutput>#htmlEditFormat(VARIABLES.agendaRenderMessage)#</cfoutput></div>
    <cfelse>
      <header class="rr-agenda-header">
        <h1 class="rr-agenda-title"><cfoutput>#htmlEditFormat(qAgendaRenderAgenda.nome)#</cfoutput></h1>
        <div class="rr-agenda-view"><cfif VARIABLES.agendaRenderView EQ "resultados">Resultados publicados<cfelse>Proximos eventos</cfif></div>
      </header>

      <cfif qAgendaRenderEvents.recordcount>
        <cfoutput query="qAgendaRenderEvents">
          <cfset VARIABLES.agendaRenderDistances = agendaServiceDisplayDistances(isJSON(distancias_json & "") ? deserializeJSON(distancias_json & "") : [])/>
          <cfset VARIABLES.agendaRenderCity = agendaServiceQueryValue(qAgendaRenderEvents, "cidade", currentRow) & ""/>
          <cfset VARIABLES.agendaRenderState = agendaServiceQueryValue(qAgendaRenderEvents, "estado", currentRow) & ""/>
          <cfset VARIABLES.agendaRenderCountry = agendaServiceQueryValue(qAgendaRenderEvents, "pais", currentRow) & ""/>
          <a class="rr-card" href="https://roadrunners.run/evento/#urlEncodedFormat(tag)#/" target="_blank" rel="noopener">
            <div class="rr-date"><span class="rr-date-day">#dateFormat(data_final, "dd")#</span><span class="rr-date-month">#agendaServiceMonthAbbreviationPtBr(data_final)#</span><span class="rr-date-year">#dateFormat(data_final, "yyyy")#</span></div>
            <div class="rr-card-main">
              <div class="rr-card-title">#htmlEditFormat(nome_evento)#</div>
              <div class="rr-card-location">
                <svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 2a7 7 0 0 0-7 7c0 5.25 7 13 7 13s7-7.75 7-13a7 7 0 0 0-7-7Zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5Z"/></svg>#htmlEditFormat(VARIABLES.agendaRenderCity)#<cfif len(VARIABLES.agendaRenderState)> - #htmlEditFormat(VARIABLES.agendaRenderState)#</cfif><cfif len(VARIABLES.agendaRenderCountry) AND VARIABLES.agendaRenderCountry NEQ "BR"> - #htmlEditFormat(VARIABLES.agendaRenderCountry)#</cfif>
              </div>
              <cfif arrayLen(VARIABLES.agendaRenderDistances)><div class="rr-tags">
                <cfloop array="#VARIABLES.agendaRenderDistances#" index="agendaRenderDistance"><span class="rr-tag">#int(agendaRenderDistance.distancia)# #htmlEditFormat(agendaRenderDistance.unidade)#</span></cfloop>
              </div></cfif>
            </div>
          </a>
        </cfoutput>
      <cfelse>
        <div class="rr-empty">Nenhum evento encontrado para esta visualizacao.</div>
      </cfif>
      <div class="rr-powered" id="rr-agenda-powered"><span>powered by</span><span class="rr-powered-brand" aria-label="Road Runners"><svg class="rr-powered-logo" aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="90" zoomAndPan="magnify" viewBox="0 0 824.88 239.999995" height="26" preserveAspectRatio="xMidYMid meet" version="1.0"><defs><g></g><clipPath id="bab4ad45e0"><path d="M 9 0.015625 L 815 0.015625 L 815 239.980469 L 9 239.980469 Z M 9 0.015625 " clip-rule="nonzero"></path></clipPath><clipPath id="df0878b42f"><path d="M 0.839844 107 L 664 107 L 664 239.980469 L 0.839844 239.980469 Z M 0.839844 107 " clip-rule="nonzero"></path></clipPath><clipPath id="58960c6a62"><rect x="0" width="664" y="0" height="133"></rect></clipPath><clipPath id="aab0ee5e67"><path d="M 279 0.015625 L 682 0.015625 L 682 136 L 279 136 Z M 279 0.015625 " clip-rule="nonzero"></path></clipPath><clipPath id="3b97b1fa0c"><rect x="0" width="403" y="0" height="136"></rect></clipPath><clipPath id="8174243e21"><path d="M 683 0.015625 L 805.679688 0.015625 L 805.679688 239.980469 L 683 239.980469 Z M 683 0.015625 " clip-rule="nonzero"></path></clipPath><clipPath id="d491d5ed37"><rect x="0" width="123" y="0" height="240"></rect></clipPath><clipPath id="25b00bbd09"><rect x="0" width="806" y="0" height="240"></rect></clipPath></defs><g clip-path="url(#bab4ad45e0)"><g transform="matrix(1, 0, 0, 1, 9, 0.000000000000043396)"><g clip-path="url(#25b00bbd09)"><g clip-path="url(#df0878b42f)"><g transform="matrix(1, 0, 0, 1, 0, 107)"><g clip-path="url(#58960c6a62)"><g fill="#ffffff" fill-opacity="1"><g transform="translate(1.457115, 125.794645)"><g><path d="M 86.46875 -3.5 C 86.644531 -3.070312 86.734375 -2.550781 86.734375 -1.9375 C 86.734375 -0.644531 85.910156 0 84.265625 0 L 59.109375 0 C 58.160156 0 57.425781 -0.234375 56.90625 -0.703125 C 56.394531 -1.179688 56.007812 -2.070312 55.75 -3.375 L 48.21875 -36.8125 C 48.050781 -37.332031 47.859375 -37.703125 47.640625 -37.921875 C 47.421875 -38.140625 46.96875 -38.25 46.28125 -38.25 L 38.5 -38.25 C 37.8125 -38.25 37.335938 -38.117188 37.078125 -37.859375 C 36.816406 -37.597656 36.644531 -37.207031 36.5625 -36.6875 L 31.765625 -2.984375 C 31.585938 -1.679688 31.175781 -0.859375 30.53125 -0.515625 C 29.882812 -0.171875 28.738281 0 27.09375 0 L 5.3125 0 C 3.0625 0 2.113281 -1.335938 2.46875 -4.015625 L 15.171875 -93.984375 C 15.253906 -94.941406 15.445312 -95.546875 15.75 -95.796875 C 16.050781 -96.054688 16.59375 -96.1875 17.375 -96.1875 L 60.671875 -96.1875 C 72.160156 -96.1875 81.082031 -94.003906 87.4375 -89.640625 C 93.789062 -85.273438 96.96875 -79.207031 96.96875 -71.4375 C 96.96875 -65.125 95.128906 -59.285156 91.453125 -53.921875 C 87.785156 -48.566406 83.015625 -44.722656 77.140625 -42.390625 C 76.015625 -41.960938 75.34375 -41.570312 75.125 -41.21875 C 74.90625 -40.875 74.882812 -40.398438 75.0625 -39.796875 Z M 54.0625 -57.5625 C 57.601562 -57.5625 60.5625 -58.769531 62.9375 -61.1875 C 65.3125 -63.601562 66.5 -66.410156 66.5 -69.609375 C 66.5 -72.035156 65.613281 -73.875 63.84375 -75.125 C 62.070312 -76.375 59.804688 -77 57.046875 -77 L 43.8125 -77 C 43.207031 -77 42.773438 -76.828125 42.515625 -76.484375 C 42.265625 -76.140625 42.050781 -75.445312 41.875 -74.40625 L 39.671875 -59.5 L 39.671875 -58.859375 C 39.671875 -58.335938 39.773438 -57.988281 39.984375 -57.8125 C 40.203125 -57.644531 40.570312 -57.5625 41.09375 -57.5625 Z M 54.0625 -57.5625 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(97.264608, 125.794645)"><g><path d="M 89.0625 -37.203125 C 87.070312 -23.035156 82.207031 -13.078125 74.46875 -7.328125 C 66.738281 -1.578125 56.304688 1.296875 43.171875 1.296875 C 30.035156 1.296875 20.523438 -1.359375 14.640625 -6.671875 C 8.765625 -11.992188 5.828125 -19.878906 5.828125 -30.328125 C 5.828125 -33.179688 6.128906 -36.859375 6.734375 -41.359375 L 14.125 -93.984375 C 14.21875 -94.941406 14.414062 -95.546875 14.71875 -95.796875 C 15.019531 -96.054688 15.554688 -96.1875 16.328125 -96.1875 L 40.96875 -96.1875 C 41.75 -96.1875 42.375 -95.816406 42.84375 -95.078125 C 43.320312 -94.347656 43.472656 -93.550781 43.296875 -92.6875 L 35.515625 -36.6875 C 35.171875 -33.925781 35 -32.066406 35 -31.109375 C 35 -26.878906 35.945312 -23.851562 37.84375 -22.03125 C 39.75 -20.21875 42.5625 -19.3125 46.28125 -19.3125 C 51.03125 -19.3125 55.113281 -20.84375 58.53125 -23.90625 C 61.945312 -26.976562 64.128906 -31.890625 65.078125 -38.640625 L 72.859375 -93.984375 C 72.941406 -94.941406 73.132812 -95.546875 73.4375 -95.796875 C 73.738281 -96.054688 74.28125 -96.1875 75.0625 -96.1875 L 94.515625 -96.1875 C 95.285156 -96.1875 95.90625 -95.816406 96.375 -95.078125 C 96.851562 -94.347656 97.007812 -93.550781 96.84375 -92.6875 Z M 89.0625 -37.203125 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(191.646002, 125.794645)"><g><path d="M 98.78125 -96.1875 C 99.988281 -96.1875 100.507812 -95.5 100.34375 -94.125 L 87.25 -1.5625 C 87.164062 -0.945312 86.925781 -0.53125 86.53125 -0.3125 C 86.144531 -0.101562 85.519531 0 84.65625 0 L 66.890625 0 C 66.285156 0 65.765625 -0.191406 65.328125 -0.578125 C 64.898438 -0.972656 64.382812 -1.644531 63.78125 -2.59375 L 34.609375 -50.953125 C 34.347656 -51.378906 34.09375 -51.59375 33.84375 -51.59375 C 33.320312 -51.59375 33.015625 -51.03125 32.921875 -49.90625 L 26.1875 -2.46875 C 26.101562 -1.425781 25.863281 -0.753906 25.46875 -0.453125 C 25.082031 -0.148438 24.285156 0 23.078125 0 L 4.40625 0 C 2.757812 0 2.066406 -1.125 2.328125 -3.375 L 15.171875 -93.984375 C 15.253906 -94.941406 15.46875 -95.546875 15.8125 -95.796875 C 16.15625 -96.054688 16.804688 -96.1875 17.765625 -96.1875 L 38.890625 -96.1875 C 39.835938 -96.1875 40.59375 -95.945312 41.15625 -95.46875 C 41.71875 -95 42.300781 -94.25 42.90625 -93.21875 L 68.1875 -50.171875 C 68.625 -49.484375 69.054688 -49.140625 69.484375 -49.140625 C 69.742188 -49.140625 69.984375 -49.289062 70.203125 -49.59375 C 70.421875 -49.894531 70.570312 -50.300781 70.65625 -50.8125 L 76.75 -94.25 C 76.832031 -95.113281 77.046875 -95.648438 77.390625 -95.859375 C 77.734375 -96.078125 78.382812 -96.1875 79.34375 -96.1875 Z M 98.78125 -96.1875 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(290.305695, 125.794645)"><g><path d="M 98.78125 -96.1875 C 99.988281 -96.1875 100.507812 -95.5 100.34375 -94.125 L 87.25 -1.5625 C 87.164062 -0.945312 86.925781 -0.53125 86.53125 -0.3125 C 86.144531 -0.101562 85.519531 0 84.65625 0 L 66.890625 0 C 66.285156 0 65.765625 -0.191406 65.328125 -0.578125 C 64.898438 -0.972656 64.382812 -1.644531 63.78125 -2.59375 L 34.609375 -50.953125 C 34.347656 -51.378906 34.09375 -51.59375 33.84375 -51.59375 C 33.320312 -51.59375 33.015625 -51.03125 32.921875 -49.90625 L 26.1875 -2.46875 C 26.101562 -1.425781 25.863281 -0.753906 25.46875 -0.453125 C 25.082031 -0.148438 24.285156 0 23.078125 0 L 4.40625 0 C 2.757812 0 2.066406 -1.125 2.328125 -3.375 L 15.171875 -93.984375 C 15.253906 -94.941406 15.46875 -95.546875 15.8125 -95.796875 C 16.15625 -96.054688 16.804688 -96.1875 17.765625 -96.1875 L 38.890625 -96.1875 C 39.835938 -96.1875 40.59375 -95.945312 41.15625 -95.46875 C 41.71875 -95 42.300781 -94.25 42.90625 -93.21875 L 68.1875 -50.171875 C 68.625 -49.484375 69.054688 -49.140625 69.484375 -49.140625 C 69.742188 -49.140625 69.984375 -49.289062 70.203125 -49.59375 C 70.421875 -49.894531 70.570312 -50.300781 70.65625 -50.8125 L 76.75 -94.25 C 76.832031 -95.113281 77.046875 -95.648438 77.390625 -95.859375 C 77.734375 -96.078125 78.382812 -96.1875 79.34375 -96.1875 Z M 98.78125 -96.1875 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(388.965345, 125.794645)"><g><path d="M 15.171875 -93.984375 C 15.253906 -94.941406 15.445312 -95.546875 15.75 -95.796875 C 16.050781 -96.054688 16.59375 -96.1875 17.375 -96.1875 L 87.890625 -96.1875 C 89.191406 -96.1875 89.84375 -95.410156 89.84375 -93.859375 C 89.84375 -93.335938 89.800781 -92.945312 89.71875 -92.6875 L 87.5 -77.65625 C 87.332031 -76.613281 87.03125 -75.898438 86.59375 -75.515625 C 86.164062 -75.128906 85.390625 -74.9375 84.265625 -74.9375 L 44.078125 -74.9375 C 43.296875 -74.9375 42.710938 -74.785156 42.328125 -74.484375 C 41.941406 -74.179688 41.703125 -73.550781 41.609375 -72.59375 L 39.921875 -60.671875 L 39.796875 -59.765625 C 39.796875 -59.328125 39.90625 -59.046875 40.125 -58.921875 C 40.34375 -58.796875 40.753906 -58.734375 41.359375 -58.734375 L 65.859375 -58.734375 C 66.722656 -58.734375 67.285156 -58.554688 67.546875 -58.203125 C 67.804688 -57.859375 67.847656 -57.296875 67.671875 -56.515625 L 65.34375 -39.546875 C 65.25 -38.847656 65.070312 -38.390625 64.8125 -38.171875 C 64.5625 -37.960938 64.046875 -37.859375 63.265625 -37.859375 L 38.25 -37.859375 C 37.644531 -37.859375 37.210938 -37.707031 36.953125 -37.40625 C 36.691406 -37.101562 36.472656 -36.5625 36.296875 -35.78125 L 34.484375 -22.953125 L 34.484375 -22.296875 C 34.484375 -21.609375 34.785156 -21.265625 35.390625 -21.265625 L 78.5625 -21.265625 C 79.425781 -21.265625 79.988281 -21.085938 80.25 -20.734375 C 80.507812 -20.390625 80.550781 -19.742188 80.375 -18.796875 L 78.171875 -2.078125 C 77.992188 -1.296875 77.734375 -0.753906 77.390625 -0.453125 C 77.046875 -0.148438 76.359375 0 75.328125 0 L 5.578125 0 C 4.453125 0 3.628906 -0.234375 3.109375 -0.703125 C 2.585938 -1.179688 2.328125 -1.898438 2.328125 -2.859375 L 2.46875 -4.015625 Z M 15.171875 -93.984375 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(475.957008, 125.794645)"><g><path d="M 86.46875 -3.5 C 86.644531 -3.070312 86.734375 -2.550781 86.734375 -1.9375 C 86.734375 -0.644531 85.910156 0 84.265625 0 L 59.109375 0 C 58.160156 0 57.425781 -0.234375 56.90625 -0.703125 C 56.394531 -1.179688 56.007812 -2.070312 55.75 -3.375 L 48.21875 -36.8125 C 48.050781 -37.332031 47.859375 -37.703125 47.640625 -37.921875 C 47.421875 -38.140625 46.96875 -38.25 46.28125 -38.25 L 38.5 -38.25 C 37.8125 -38.25 37.335938 -38.117188 37.078125 -37.859375 C 36.816406 -37.597656 36.644531 -37.207031 36.5625 -36.6875 L 31.765625 -2.984375 C 31.585938 -1.679688 31.175781 -0.859375 30.53125 -0.515625 C 29.882812 -0.171875 28.738281 0 27.09375 0 L 5.3125 0 C 3.0625 0 2.113281 -1.335938 2.46875 -4.015625 L 15.171875 -93.984375 C 15.253906 -94.941406 15.445312 -95.546875 15.75 -95.796875 C 16.050781 -96.054688 16.59375 -96.1875 17.375 -96.1875 L 60.671875 -96.1875 C 72.160156 -96.1875 81.082031 -94.003906 87.4375 -89.640625 C 93.789062 -85.273438 96.96875 -79.207031 96.96875 -71.4375 C 96.96875 -65.125 95.128906 -59.285156 91.453125 -53.921875 C 87.785156 -48.566406 83.015625 -44.722656 77.140625 -42.390625 C 76.015625 -41.960938 75.34375 -41.570312 75.125 -41.21875 C 74.90625 -40.875 74.882812 -40.398438 75.0625 -39.796875 Z M 54.0625 -57.5625 C 57.601562 -57.5625 60.5625 -58.769531 62.9375 -61.1875 C 65.3125 -63.601562 66.5 -66.410156 66.5 -69.609375 C 66.5 -72.035156 65.613281 -73.875 63.84375 -75.125 C 62.070312 -76.375 59.804688 -77 57.046875 -77 L 43.8125 -77 C 43.207031 -77 42.773438 -76.828125 42.515625 -76.484375 C 42.265625 -76.140625 42.050781 -75.445312 41.875 -74.40625 L 39.671875 -59.5 L 39.671875 -58.859375 C 39.671875 -58.335938 39.773438 -57.988281 39.984375 -57.8125 C 40.203125 -57.644531 40.570312 -57.5625 41.09375 -57.5625 Z M 54.0625 -57.5625 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(571.764487, 125.794645)"><g><path d="M 69.875 -71.5625 C 65.289062 -75.539062 59.367188 -77.53125 52.109375 -77.53125 C 47.796875 -77.53125 44.363281 -76.835938 41.8125 -75.453125 C 39.257812 -74.066406 37.984375 -72.078125 37.984375 -69.484375 C 37.984375 -66.460938 40.578125 -64.171875 45.765625 -62.609375 L 66.5 -55.875 C 73.414062 -53.625 78.554688 -50.707031 81.921875 -47.125 C 85.296875 -43.539062 86.984375 -39.023438 86.984375 -33.578125 C 86.984375 -26.316406 84.992188 -20.050781 81.015625 -14.78125 C 77.046875 -9.507812 71.625 -5.507812 64.75 -2.78125 C 57.882812 -0.0625 50.171875 1.296875 41.609375 1.296875 C 31.753906 1.296875 23.390625 -0.320312 16.515625 -3.5625 C 9.648438 -6.800781 4.664062 -11.273438 1.5625 -16.984375 C 1.039062 -18.191406 0.78125 -18.882812 0.78125 -19.0625 C 0.78125 -19.570312 1.164062 -20.085938 1.9375 -20.609375 L 15.6875 -29.046875 C 16.375 -29.472656 17.109375 -29.6875 17.890625 -29.6875 C 19.097656 -29.6875 20.222656 -29.039062 21.265625 -27.75 C 23.597656 -25.15625 25.628906 -23.207031 27.359375 -21.90625 C 29.085938 -20.613281 31.242188 -19.597656 33.828125 -18.859375 C 36.421875 -18.128906 39.878906 -17.765625 44.203125 -17.765625 C 48.265625 -17.765625 51.613281 -18.429688 54.25 -19.765625 C 56.882812 -21.109375 58.203125 -23.335938 58.203125 -26.453125 C 58.203125 -29.554688 55.566406 -31.890625 50.296875 -33.453125 L 31.25 -39.28125 C 24.675781 -41.269531 19.570312 -44.378906 15.9375 -48.609375 C 12.3125 -52.847656 10.5 -57.820312 10.5 -63.53125 C 10.5 -70.175781 12.441406 -76.09375 16.328125 -81.28125 C 20.222656 -86.46875 25.429688 -90.460938 31.953125 -93.265625 C 38.484375 -96.078125 45.550781 -97.484375 53.15625 -97.484375 C 61.1875 -97.484375 68.332031 -96.078125 74.59375 -93.265625 C 80.863281 -90.460938 85.554688 -86.988281 88.671875 -82.84375 C 89.367188 -81.894531 89.71875 -81.113281 89.71875 -80.5 C 89.71875 -79.894531 89.410156 -79.421875 88.796875 -79.078125 L 73.890625 -69.484375 C 73.460938 -69.140625 72.988281 -69.117188 72.46875 -69.421875 C 71.945312 -69.722656 71.425781 -70.109375 70.90625 -70.578125 C 70.394531 -71.054688 70.050781 -71.382812 69.875 -71.5625 Z M 69.875 -71.5625 "></path></g></g></g></g></g></g><g clip-path="url(#aab0ee5e67)"><g transform="matrix(1, 0, 0, 1, 279, 0.000000000000043396)"><g clip-path="url(#3b97b1fa0c)"><g fill="#ffffff" fill-opacity="1"><g transform="translate(1.701228, 103.465657)"><g><path d="M 86.46875 -3.5 C 86.644531 -3.070312 86.734375 -2.550781 86.734375 -1.9375 C 86.734375 -0.644531 85.910156 0 84.265625 0 L 59.109375 0 C 58.160156 0 57.425781 -0.234375 56.90625 -0.703125 C 56.394531 -1.179688 56.007812 -2.070312 55.75 -3.375 L 48.21875 -36.8125 C 48.050781 -37.332031 47.859375 -37.703125 47.640625 -37.921875 C 47.421875 -38.140625 46.96875 -38.25 46.28125 -38.25 L 38.5 -38.25 C 37.8125 -38.25 37.335938 -38.117188 37.078125 -37.859375 C 36.816406 -37.597656 36.644531 -37.207031 36.5625 -36.6875 L 31.765625 -2.984375 C 31.585938 -1.679688 31.175781 -0.859375 30.53125 -0.515625 C 29.882812 -0.171875 28.738281 0 27.09375 0 L 5.3125 0 C 3.0625 0 2.113281 -1.335938 2.46875 -4.015625 L 15.171875 -93.984375 C 15.253906 -94.941406 15.445312 -95.546875 15.75 -95.796875 C 16.050781 -96.054688 16.59375 -96.1875 17.375 -96.1875 L 60.671875 -96.1875 C 72.160156 -96.1875 81.082031 -94.003906 87.4375 -89.640625 C 93.789062 -85.273438 96.96875 -79.207031 96.96875 -71.4375 C 96.96875 -65.125 95.128906 -59.285156 91.453125 -53.921875 C 87.785156 -48.566406 83.015625 -44.722656 77.140625 -42.390625 C 76.015625 -41.960938 75.34375 -41.570312 75.125 -41.21875 C 74.90625 -40.875 74.882812 -40.398438 75.0625 -39.796875 Z M 54.0625 -57.5625 C 57.601562 -57.5625 60.5625 -58.769531 62.9375 -61.1875 C 65.3125 -63.601562 66.5 -66.410156 66.5 -69.609375 C 66.5 -72.035156 65.613281 -73.875 63.84375 -75.125 C 62.070312 -76.375 59.804688 -77 57.046875 -77 L 43.8125 -77 C 43.207031 -77 42.773438 -76.828125 42.515625 -76.484375 C 42.265625 -76.140625 42.050781 -75.445312 41.875 -74.40625 L 39.671875 -59.5 L 39.671875 -58.859375 C 39.671875 -58.335938 39.773438 -57.988281 39.984375 -57.8125 C 40.203125 -57.644531 40.570312 -57.5625 41.09375 -57.5625 Z M 54.0625 -57.5625 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(97.508721, 103.465657)"><g><path d="M 46.671875 1.296875 C 38.117188 1.296875 30.75 -0.363281 24.5625 -3.6875 C 18.382812 -7.019531 13.648438 -11.753906 10.359375 -17.890625 C 7.078125 -24.023438 5.4375 -31.285156 5.4375 -39.671875 C 5.4375 -43.296875 5.65625 -46.492188 6.09375 -49.265625 C 7.476562 -58.941406 10.546875 -67.429688 15.296875 -74.734375 C 20.046875 -82.035156 26.132812 -87.648438 33.5625 -91.578125 C 41 -95.515625 49.300781 -97.484375 58.46875 -97.484375 C 66.851562 -97.484375 74.132812 -95.773438 80.3125 -92.359375 C 86.488281 -88.953125 91.21875 -84.113281 94.5 -77.84375 C 97.789062 -71.582031 99.4375 -64.257812 99.4375 -55.875 C 99.4375 -52.25 99.21875 -49.09375 98.78125 -46.40625 C 97.40625 -36.726562 94.359375 -28.300781 89.640625 -21.125 C 84.929688 -13.957031 78.878906 -8.425781 71.484375 -4.53125 C 64.097656 -0.644531 55.828125 1.296875 46.671875 1.296875 Z M 47.453125 -18.921875 C 53.328125 -18.921875 57.90625 -21.253906 61.1875 -25.921875 C 64.46875 -30.585938 66.847656 -38.238281 68.328125 -48.875 C 69.015625 -54.144531 69.359375 -58.421875 69.359375 -61.703125 C 69.359375 -67.328125 68.445312 -71.367188 66.625 -73.828125 C 64.8125 -76.296875 61.875 -77.53125 57.8125 -77.53125 C 51.9375 -77.53125 47.3125 -75.039062 43.9375 -70.0625 C 40.570312 -65.09375 38.113281 -57.078125 36.5625 -46.015625 C 35.863281 -40.921875 35.515625 -36.816406 35.515625 -33.703125 C 35.515625 -28.347656 36.441406 -24.546875 38.296875 -22.296875 C 40.160156 -20.046875 43.210938 -18.921875 47.453125 -18.921875 Z M 47.453125 -18.921875 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(198.631643, 103.465657)"><g><path d="M -0.515625 0 C -1.554688 0 -2.078125 -0.429688 -2.078125 -1.296875 C -2.078125 -1.984375 -1.597656 -3.363281 -0.640625 -5.4375 L 43.296875 -93.859375 C 43.816406 -94.804688 44.441406 -95.429688 45.171875 -95.734375 C 45.910156 -96.035156 46.925781 -96.1875 48.21875 -96.1875 L 73.765625 -96.1875 C 74.804688 -96.1875 75.539062 -95.816406 75.96875 -95.078125 C 76.40625 -94.347656 76.75 -93.335938 77 -92.046875 L 95.796875 -3.765625 C 95.890625 -3.503906 95.9375 -3.113281 95.9375 -2.59375 C 95.9375 -0.863281 95.242188 0 93.859375 0 L 68.453125 0 C 67.242188 0 66.421875 -0.953125 65.984375 -2.859375 L 63 -17.5 C 62.914062 -17.9375 62.765625 -18.238281 62.546875 -18.40625 C 62.335938 -18.582031 61.925781 -18.671875 61.3125 -18.671875 L 34.09375 -18.671875 C 33.488281 -18.671875 33.015625 -18.539062 32.671875 -18.28125 C 32.328125 -18.019531 31.976562 -17.585938 31.625 -16.984375 L 23.859375 -1.296875 C 23.597656 -0.773438 23.269531 -0.425781 22.875 -0.25 C 22.488281 -0.0820312 21.863281 0 21 0 Z M 57.8125 -40.703125 C 59.289062 -40.703125 59.8125 -41.566406 59.375 -43.296875 L 54.703125 -64.953125 C 54.617188 -65.816406 54.316406 -66.25 53.796875 -66.25 C 53.453125 -66.25 53.066406 -65.859375 52.640625 -65.078125 L 41.875 -42.78125 C 41.613281 -42.257812 41.484375 -41.828125 41.484375 -41.484375 C 41.484375 -40.960938 42.003906 -40.703125 43.046875 -40.703125 Z M 57.8125 -40.703125 "></path></g></g></g><g fill="#ffffff" fill-opacity="1"><g transform="translate(302.217823, 103.465657)"><g><path d="M 6.21875 0 C 4.925781 0 3.953125 -0.429688 3.296875 -1.296875 C 2.648438 -2.160156 2.414062 -3.285156 2.59375 -4.671875 L 15.03125 -93.734375 C 15.125 -94.765625 15.382812 -95.429688 15.8125 -95.734375 C 16.25 -96.035156 17.070312 -96.1875 18.28125 -96.1875 L 50.6875 -96.1875 C 60.800781 -96.1875 69.441406 -94.457031 76.609375 -91 C 83.785156 -87.550781 89.207031 -82.753906 92.875 -76.609375 C 96.550781 -70.472656 98.390625 -63.472656 98.390625 -55.609375 C 98.390625 -44.640625 95.96875 -34.941406 91.125 -26.515625 C 86.289062 -18.085938 79.488281 -11.5625 70.71875 -6.9375 C 61.945312 -2.3125 51.8125 0 40.3125 0 Z M 43.8125 -20.359375 C 51.675781 -20.359375 57.640625 -23.8125 61.703125 -30.71875 C 65.765625 -37.632812 67.796875 -46.492188 67.796875 -57.296875 C 67.796875 -63.265625 66.390625 -67.847656 63.578125 -71.046875 C 60.773438 -74.242188 56.910156 -75.84375 51.984375 -75.84375 L 44.34375 -75.84375 C 42.78125 -75.84375 41.867188 -74.976562 41.609375 -73.25 L 34.75 -22.8125 L 34.75 -22.03125 C 34.75 -20.914062 35.304688 -20.359375 36.421875 -20.359375 Z M 43.8125 -20.359375 "></path></g></g></g></g></g></g><g clip-path="url(#8174243e21)"><g transform="matrix(1, 0, 0, 1, 683, 0.000000000000043396)"><g clip-path="url(#d491d5ed37)"><g fill="#f4b120" fill-opacity="1"><g transform="translate(2.928563, 192.338952)"><g><path d="M 5.375 37 C 3.132812 37 1.488281 36.175781 0.4375 34.53125 C -0.601562 32.882812 -0.972656 30.789062 -0.671875 28.25 L 29.375 -185.421875 C 29.664062 -187.515625 30.109375 -188.785156 30.703125 -189.234375 C 31.304688 -189.679688 32.65625 -189.90625 34.75 -189.90625 L 55.609375 -189.90625 C 57.242188 -189.90625 58.582031 -189.304688 59.625 -188.109375 C 60.675781 -186.910156 61.054688 -185.640625 60.765625 -184.296875 L 30.046875 34.296875 C 29.890625 35.492188 29.585938 36.242188 29.140625 36.546875 C 28.691406 36.847656 27.722656 37 26.234375 37 Z M 5.375 37 "></path></g></g></g><g fill="#f4b120" fill-opacity="1"><g transform="translate(57.847316, 192.338952)"><g><path d="M 5.375 37 C 3.132812 37 1.488281 36.175781 0.4375 34.53125 C -0.601562 32.882812 -0.972656 30.789062 -0.671875 28.25 L 29.375 -185.421875 C 29.664062 -187.515625 30.109375 -188.785156 30.703125 -189.234375 C 31.304688 -189.679688 32.65625 -189.90625 34.75 -189.90625 L 55.609375 -189.90625 C 57.242188 -189.90625 58.582031 -189.304688 59.625 -188.109375 C 60.675781 -186.910156 61.054688 -185.640625 60.765625 -184.296875 L 30.046875 34.296875 C 29.890625 35.492188 29.585938 36.242188 29.140625 36.546875 C 28.691406 36.847656 27.722656 37 26.234375 37 Z M 5.375 37 "></path></g></g></g></g></g></g></g></g></g></svg></span></div>
    </cfif>
  </main>

  <script nonce="<cfoutput>#VARIABLES.agendaRenderCspNonce#</cfoutput>">
    (function () {
      var embedId = '<cfoutput>#JSStringFormat(URL.embed_id)#</cfoutput>';
      var poweredMark = document.getElementById('rr-agenda-powered');
      var poweredParent = poweredMark ? poweredMark.parentNode : null;
      var poweredSnapshot = poweredMark ? poweredMark.cloneNode(true) : null;
      var poweredGuardScheduled = false;

      function protectPoweredMark() {
        poweredGuardScheduled = false;
        if (!poweredParent || !poweredSnapshot) return;

        var currentMark = document.getElementById('rr-agenda-powered');
        if (!currentMark) {
          currentMark = poweredSnapshot.cloneNode(true);
          poweredParent.appendChild(currentMark);
          return;
        }

        if (currentMark.className !== 'rr-powered') currentMark.className = 'rr-powered';
        if (currentMark.hasAttribute('hidden')) currentMark.removeAttribute('hidden');
        if (currentMark.hasAttribute('aria-hidden')) currentMark.removeAttribute('aria-hidden');
        if (currentMark.hasAttribute('style')) currentMark.removeAttribute('style');
        if (currentMark.innerHTML !== poweredSnapshot.innerHTML) currentMark.innerHTML = poweredSnapshot.innerHTML;
      }

      function schedulePoweredProtection() {
        if (poweredGuardScheduled) return;
        poweredGuardScheduled = true;
        window.requestAnimationFrame(protectPoweredMark);
      }

      if (poweredMark && 'MutationObserver' in window) {
        new MutationObserver(schedulePoweredProtection).observe(document.documentElement, {
          attributes: true,
          attributeFilter: ['aria-hidden', 'class', 'hidden', 'style'],
          childList: true,
          subtree: true
        });
      }

      function reportHeight() {
        var height = Math.max(document.documentElement.scrollHeight, document.body.scrollHeight);
        parent.postMessage({ type: 'rr-agenda:resize', embedId: embedId, height: height }, '*');
      }
      if ('ResizeObserver' in window) new ResizeObserver(reportHeight).observe(document.documentElement);
      window.addEventListener('load', reportHeight);
      reportHeight();
    })();
  </script>
</body>
</html>

<cfset agendaServiceLogAccess(qAgendaRenderAgenda.recordcount ? qAgendaRenderAgenda.id_agenda : 0, "embed", VARIABLES.agendaRenderView, VARIABLES.agendaRenderStatus, qAgendaRenderEvents.recordcount, getTickCount() - VARIABLES.agendaRenderStartedAt)/>
