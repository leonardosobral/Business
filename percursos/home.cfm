<cfinclude template="includes/backend.cfm"/>

<style>
  .route-preview-shell { position: relative; background: #202124; border-radius: .75rem; overflow: hidden; }
  .route-preview-shell:fullscreen { width: 100vw; height: 100vh; border-radius: 0; }
  .route-preview-shell:fullscreen .route-map { height: calc(100vh - 54px); }
  .route-map { height: 500px; background: #202124; }
  .route-map-toolbar { display: flex; flex-wrap: wrap; gap: .45rem; padding: .65rem; background: rgba(18,18,18,.94); }
  .route-map-toolbar .btn, .route-map-toolbar .form-select { font-size: .78rem; }
  .route-map-toolbar .form-select { width: auto; min-width: 130px; }
  .route-map-marker { display: grid; place-items: center; width: 28px; height: 28px; border: 2px solid white; border-radius: 50%; color: white; font-size: 11px; font-weight: 800; box-shadow: 0 2px 7px rgba(0,0,0,.55); }
  .route-map-marker-start { background: #198754; }
  .route-map-marker-finish { background: #dc3545; }
  .route-km-marker { display: grid; place-items: center; width: 25px; height: 25px; border: 2px solid #fff; border-radius: 50%; background: #212529; color: #f4b120; font-size: 10px; font-weight: 800; box-shadow: 0 1px 5px rgba(0,0,0,.55); }
  .route-direction-arrow { color: #161616; text-shadow: 0 0 2px white, 0 0 3px white; font-size: 22px; line-height: 22px; transform-origin: center; }
  .route-elevation-panel { border: 1px solid rgba(255,255,255,.15); border-radius: .75rem; padding: .75rem; background: rgba(255,255,255,.025); }
  .route-elevation-canvas { width: 100%; height: 190px; display: block; cursor: crosshair; }
  .route-elevation-empty { height: 100px; display: grid; place-items: center; color: #999; }
  @media (max-width: 767px) { .route-map { height: 390px; } .route-map-toolbar .btn { flex: 1 1 auto; } .route-map-toolbar .form-select { width: 100%; } }
  .route-stat { min-width: 125px; }
  .route-hash { max-width: 210px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .route-owner-current, .route-owner-result { background: rgba(255,255,255,.025); border: 1px solid rgba(255,255,255,.12); border-radius: .7rem; }
  .route-owner-result { align-items: center; display: flex; gap: .75rem; justify-content: space-between; padding: .75rem; }
  .route-owner-result + .route-owner-result { margin-top: .55rem; }
  .route-owner-identity { min-width: 0; }
  .route-owner-email { overflow-wrap: anywhere; }
  .route-event-item { align-items: center; background: rgba(255,255,255,.025); border: 1px solid rgba(255,255,255,.12); border-radius: .7rem; display: flex; gap: 1rem; justify-content: space-between; padding: .85rem; }
  .route-event-item + .route-event-item { margin-top: .6rem; }
  .route-event-identity { min-width: 0; }
  .route-event-meta { display: flex; flex-wrap: wrap; gap: .35rem .75rem; }
  @media (max-width: 575px) { .route-event-item { align-items: stretch; flex-direction: column; } .route-event-item .btn { width: 100%; } }
</style>

<div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-4">
  <div><h2 class="mb-1"><i class="fa-solid fa-route text-warning me-2"></i>Repositório de Percursos</h2><p class="text-muted mb-0">GPX privados, versionados e preparados para vinculação aos eventos.</p></div>
  <div class="d-flex flex-wrap gap-2">
    <cfif VARIABLES.percursoIsSystemAdmin><a class="btn btn-outline-warning" href="./migracao-strava.cfm"><i class="fa-brands fa-strava me-2"></i>Migrar mapas Strava</a></cfif>
    <cfif VARIABLES.percursoIsSystemAdmin OR VARIABLES.percursoIsDev><a class="btn btn-outline-secondary" href="./exportar-mapas-strava.cfm"><i class="fa-brands fa-strava me-2"></i>Exportar mapas Strava</a></cfif>
    <cfif VARIABLES.percursoCanWrite><a class="btn btn-warning" href="./?novo=1"><i class="fa-solid fa-plus me-2"></i>Novo percurso</a></cfif>
  </div>
</div>

<cfif len(VARIABLES.percursoAlert.message)><div class="alert alert-<cfoutput>#VARIABLES.percursoAlert.type#</cfoutput>"><cfoutput>#htmlEditFormat(VARIABLES.percursoAlert.message)#</cfoutput></div></cfif>

<cfif NOT VARIABLES.percursoSchemaReady>
  <div class="alert alert-warning"><strong>Banco ainda não preparado.</strong> Aplique o script <code>/percursos/percursos_schema.sql</code>. Nenhuma tabela é criada automaticamente pela aplicação.</div>
<cfelse>
  <cfif NOT VARIABLES.percursoStorageConfigured><div class="alert alert-warning"><strong>Storage temporário.</strong> Configure <code>config/percursos.local.cfm</code> antes de usar este módulo em produção. Arquivos no diretório temporário do servidor não são persistentes.</div></cfif>
  <cfif NOT VARIABLES.percursoStorageReady><div class="alert alert-danger"><strong>Storage indisponível.</strong> <cfoutput>#htmlEditFormat(VARIABLES.percursoStorageError)#</cfoutput><div class="small mt-1"><code><cfoutput>#htmlEditFormat(VARIABLES.percursoStoragePath)#</cfoutput></code></div></div></cfif>
  <cfif isDefined("URL.novo") AND URL.novo EQ "1">
    <div class="card bg-dark border-secondary mb-4"><div class="card-body">
      <div class="d-flex justify-content-between align-items-center mb-3"><h5 class="mb-0">Cadastrar percurso</h5><a href="./" class="btn btn-sm btn-outline-secondary">Cancelar</a></div>
      <form method="post" enctype="multipart/form-data" action="./?novo=1">
        <input type="hidden" name="acao" value="criar"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.percursoCsrfToken#</cfoutput>"/>
        <div class="row g-3">
          <div class="col-lg-6"><label class="form-label">Nome</label><input class="form-control" name="nome" maxlength="180" required value="<cfoutput>#htmlEditFormat(isDefined('FORM.nome') ? FORM.nome : '')#</cfoutput>"/></div>
          <div class="col-lg-2"><label class="form-label">Distância nominal (km)</label><input class="form-control" name="distancia_km" inputmode="decimal" placeholder="42,195" required/></div>
          <div class="col-lg-2"><label class="form-label">Tipo</label><select class="form-select" name="tipo_percurso"><option value="rua">Rua</option><option value="trail">Trail</option><option value="misto">Misto</option></select></div>
          <div class="col-lg-2"><label class="form-label">País</label><input class="form-control text-uppercase" name="pais" maxlength="2" value="BR" required/></div>
          <div class="col-lg-5"><label class="form-label">Cidade</label><input class="form-control" name="cidade" maxlength="128"/></div>
          <div class="col-lg-2"><label class="form-label">Estado</label><input class="form-control text-uppercase" name="estado" maxlength="2"/></div>
          <div class="col-lg-5"><label class="form-label">Arquivo GPX</label><input class="form-control" type="file" name="arquivo_gpx" accept=".gpx,application/gpx+xml" required/><div class="form-text">Máximo 20 MB. O original ficará fora da área pública.</div></div>
          <div class="col-12"><label class="form-label">Descrição</label><textarea class="form-control" name="descricao" rows="3"></textarea></div>
          <div class="col-12"><button class="btn btn-warning" type="submit"><i class="fa-solid fa-upload me-2"></i>Processar e cadastrar</button></div>
        </div>
      </form>
    </div></div>
  </cfif>

  <cfif VARIABLES.percursoSelectedId GT 0>
    <cfif NOT qPercurso.recordcount><div class="alert alert-danger">Percurso não encontrado ou indisponível para sua conta.</div>
    <cfelse>
      <cfset VARIABLES.routeCanEdit = VARIABLES.percursoIsAdmin OR qPercurso.id_usuario_criador EQ VARIABLES.percursoActorId OR (len(VARIABLES.percursoWriteAccountIds) AND VARIABLES.percursoWriteAccountIds NEQ "0" AND len(qPercurso.id_conta_responsavel & "") AND listFind(VARIABLES.percursoWriteAccountIds,qPercurso.id_conta_responsavel))/>
      <div class="card bg-dark border-secondary mb-4"><div class="card-body">
        <div class="d-flex flex-wrap justify-content-between gap-2 mb-3">
          <div>
            <h4 class="mb-1"><cfoutput>#htmlEditFormat(qPercurso.nome)#</cfoutput></h4>
            <div class="text-muted small"><cfoutput>## #qPercurso.id_percurso# · #qPercurso.codigo_publico#</cfoutput></div>
            <div class="text-muted small mt-1"><i class="fa-regular fa-user me-1"></i>Proprietário: <cfif qPercursoOwner.recordcount><cfoutput>#htmlEditFormat(qPercursoOwner.name)#</cfoutput><cfelse><cfoutput>Usuário ###qPercurso.id_usuario_criador#</cfoutput></cfif></div>
          </div>
          <a href="./" class="btn btn-sm btn-outline-secondary align-self-start">Voltar à lista</a>
        </div>
        <cfif qPercursoArquivos.recordcount>
          <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" crossorigin=""/>
          <div id="route-preview-shell" class="route-preview-shell mb-3">
            <div class="route-map-toolbar">
              <button class="btn btn-sm btn-warning" type="button" id="route-layer-street"><i class="fa-solid fa-map me-1"></i>Ruas</button>
              <button class="btn btn-sm btn-outline-light" type="button" id="route-layer-satellite"><i class="fa-solid fa-satellite me-1"></i>Satélite</button>
              <button class="btn btn-sm btn-outline-light" type="button" id="route-fit"><i class="fa-solid fa-arrows-to-circle me-1"></i>Recentralizar</button>
              <button class="btn btn-sm btn-outline-light" type="button" id="route-fullscreen"><i class="fa-solid fa-expand me-1"></i>Tela cheia</button>
              <select class="form-select form-select-sm" id="route-km-interval" aria-label="Intervalo dos marcadores quilométricos"><option value="1">Marcar cada 1 km</option><option value="5">Marcar cada 5 km</option><option value="0">Ocultar quilômetros</option></select>
              <a class="btn btn-sm btn-outline-warning ms-lg-auto" href="./download.cfm?id=<cfoutput>#qPercursoArquivos.id_percurso_arquivo#</cfoutput>"><i class="fa-solid fa-download me-1"></i>Baixar GPX</a>
            </div>
            <div id="route-map" class="route-map"></div>
          </div>
          <div class="d-flex flex-wrap gap-2 mb-4">
            <div class="route-stat border rounded p-2"><div class="small text-muted">Nominal</div><strong><cfoutput>#numberFormat(qPercurso.distancia_nominal_m/1000,'0.000')# km</cfoutput></strong></div>
            <div class="route-stat border rounded p-2"><div class="small text-muted">GPX</div><strong><cfoutput>#numberFormat(qPercursoArquivos.distancia_gpx_m/1000,'0.000')# km</cfoutput></strong></div>
            <div class="route-stat border rounded p-2"><div class="small text-muted">Pontos</div><strong><cfoutput>#numberFormat(qPercursoArquivos.quantidade_pontos)#</cfoutput></strong></div>
            <div class="route-stat border rounded p-2"><div class="small text-muted">Ganho de elevação</div><strong><cfoutput>#numberFormat(qPercursoArquivos.ganho_elevacao_m,'0')# m</cfoutput></strong></div>
            <div class="route-stat border rounded p-2"><div class="small text-muted">Perda de elevação</div><strong id="route-elevation-loss">—</strong></div>
            <div class="route-stat border rounded p-2"><div class="small text-muted">Altitude mín./máx.</div><strong id="route-elevation-range">—</strong></div>
            <div class="route-stat border rounded p-2"><div class="small text-muted">Versão atual</div><strong><cfoutput>v#qPercursoArquivos.versao#</cfoutput></strong></div>
          </div>
          <div class="route-elevation-panel mb-4"><div class="d-flex justify-content-between align-items-center mb-2"><strong>Perfil de elevação</strong><span class="small text-muted" id="route-elevation-hover">Passe o cursor sobre o gráfico</span></div><canvas id="route-elevation-chart" class="route-elevation-canvas" height="190"></canvas></div>
          <cfset VARIABLES.routeDistanceDifferencePct=abs(qPercursoArquivos.distancia_gpx_m-qPercurso.distancia_nominal_m)/qPercurso.distancia_nominal_m*100/>
          <cfif VARIABLES.routeDistanceDifferencePct GT 5><div class="alert alert-warning">A distância calculada do GPX diverge <cfoutput>#numberFormat(VARIABLES.routeDistanceDifferencePct,'0.0')#%</cfoutput> da distância nominal. Revise o arquivo antes de publicar.</div></cfif>
          <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" crossorigin=""></script>
          <script>
            fetch('./geometry.cfm?id=<cfoutput>#qPercursoArquivos.id_percurso_arquivo#</cfoutput>', {credentials:'same-origin'}).then(async r => {
              if (!r.ok) {
                let detail='HTTP '+r.status;
                try { const payload=await r.json(); if (payload && payload.message) detail=payload.message; else if (payload && payload.error) detail=payload.error; } catch (_) {}
                throw new Error(detail);
              }
              return r.json();
            }).then(data => {
              const coordinates=data && data.geometry && Array.isArray(data.geometry.coordinates) ? data.geometry.coordinates : [];
              if (coordinates.length < 2) throw new Error('O percurso não possui pontos suficientes.');
              const latLngs=coordinates.map(point => L.latLng(Number(point[1]),Number(point[0])));
              const haversine=(a,b) => { const rad=Math.PI/180, dLat=(b.lat-a.lat)*rad, dLng=(b.lng-a.lng)*rad, x=Math.sin(dLat/2)**2+Math.cos(a.lat*rad)*Math.cos(b.lat*rad)*Math.sin(dLng/2)**2; return 6371000*2*Math.atan2(Math.sqrt(x),Math.sqrt(1-x)); };
              const cumulative=[0]; for(let i=1;i<latLngs.length;i++) cumulative[i]=cumulative[i-1]+haversine(latLngs[i-1],latLngs[i]);
              const totalDistance=cumulative[cumulative.length-1];
              if(totalDistance<1) throw new Error('O percurso não possui distância geográfica válida.');
              const indexAtDistance=target => { let low=0,high=cumulative.length-1; while(low<high){const mid=Math.floor((low+high)/2);if(cumulative[mid]<target)low=mid+1;else high=mid;}return low; };
              const pointAtDistance=target => { const hi=indexAtDistance(target); if(hi<1) return latLngs[0]; const lo=hi-1, span=cumulative[hi]-cumulative[lo], ratio=span ? (target-cumulative[lo])/span : 0; return L.latLng(latLngs[lo].lat+(latLngs[hi].lat-latLngs[lo].lat)*ratio,latLngs[lo].lng+(latLngs[hi].lng-latLngs[lo].lng)*ratio); };
              const bearing=(a,b) => { const rad=Math.PI/180, y=Math.sin((b.lng-a.lng)*rad)*Math.cos(b.lat*rad), x=Math.cos(a.lat*rad)*Math.sin(b.lat*rad)-Math.sin(a.lat*rad)*Math.cos(b.lat*rad)*Math.cos((b.lng-a.lng)*rad); return (Math.atan2(y,x)*180/Math.PI+360)%360; };

              const street=L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19,attribution:'&copy; OpenStreetMap contributors'});
              const satellite=L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',{maxZoom:19,attribution:'Tiles &copy; Esri'});
              const map=L.map('route-map',{layers:[street]}); L.control.scale({imperial:false,position:'bottomleft'}).addTo(map);
              const line=L.polyline(latLngs,{color:'#f4b120',weight:5,opacity:.95}).addTo(map); const routeBounds=line.getBounds(); map.fitBounds(routeBounds,{padding:[25,25]});
              const markerIcon=(label,kind) => L.divIcon({className:'',html:'<div class="route-map-marker route-map-marker-'+kind+'">'+label+'</div>',iconSize:[28,28],iconAnchor:[14,14]});
              L.marker(latLngs[0],{icon:markerIcon('L','start'),title:'Largada'}).bindPopup('<strong>Largada</strong>').addTo(map);
              L.marker(latLngs[latLngs.length-1],{icon:markerIcon('C','finish'),title:'Chegada'}).bindPopup('<strong>Chegada</strong>').addTo(map);

              const arrowLayer=L.layerGroup().addTo(map), arrowCount=Math.min(14,Math.max(5,Math.floor(totalDistance/3000)));
              for(let n=1;n<=arrowCount;n++){ const idx=Math.min(latLngs.length-2,Math.max(0,Math.floor((latLngs.length-1)*n/(arrowCount+1)))); const angle=bearing(latLngs[idx],latLngs[idx+1]); L.marker(latLngs[idx],{interactive:false,icon:L.divIcon({className:'',html:'<div class="route-direction-arrow" style="transform:rotate('+angle+'deg)">▲</div>',iconSize:[22,22],iconAnchor:[11,11]})}).addTo(arrowLayer); }
              const kmLayer=L.layerGroup().addTo(map);
              const renderKmMarkers=interval => { kmLayer.clearLayers(); if(!interval) return; for(let km=interval;km*1000<totalDistance;km+=interval){ const location=pointAtDistance(km*1000); L.marker(location,{icon:L.divIcon({className:'',html:'<div class="route-km-marker">'+km+'</div>',iconSize:[25,25],iconAnchor:[12,12]}),title:km+' km'}).bindTooltip(km+' km',{direction:'top'}).addTo(kmLayer); } };
              renderKmMarkers(1);

              const streetButton=document.getElementById('route-layer-street'), satelliteButton=document.getElementById('route-layer-satellite');
              const activateLayer=(active,inactive,layer,other) => { if(map.hasLayer(other)) map.removeLayer(other); layer.addTo(map); active.classList.add('btn-warning'); active.classList.remove('btn-outline-light'); inactive.classList.remove('btn-warning'); inactive.classList.add('btn-outline-light'); };
              streetButton.addEventListener('click',()=>activateLayer(streetButton,satelliteButton,street,satellite)); satelliteButton.addEventListener('click',()=>activateLayer(satelliteButton,streetButton,satellite,street));
              document.getElementById('route-fit').addEventListener('click',()=>map.fitBounds(routeBounds,{padding:[25,25]}));
              document.getElementById('route-km-interval').addEventListener('change',event=>renderKmMarkers(Number(event.target.value)));
              const shell=document.getElementById('route-preview-shell'); document.getElementById('route-fullscreen').addEventListener('click',()=>{ if(document.fullscreenElement) document.exitFullscreen(); else if(shell.requestFullscreen) shell.requestFullscreen(); }); document.addEventListener('fullscreenchange',()=>setTimeout(()=>map.invalidateSize(),120));

              const elevated=coordinates.map((point,index)=>({distance:cumulative[index],elevation:point.length>2 && Number.isFinite(Number(point[2])) ? Number(point[2]) : null,latLng:latLngs[index]}));
              const elevationValues=elevated.filter(point=>point.elevation!==null).map(point=>point.elevation), canvas=document.getElementById('route-elevation-chart'), hoverLabel=document.getElementById('route-elevation-hover');
              if(elevationValues.length>1){ let gain=0,loss=0; for(let i=1;i<elevated.length;i++){ if(elevated[i-1].elevation===null||elevated[i].elevation===null) continue; const delta=elevated[i].elevation-elevated[i-1].elevation; if(delta>0) gain+=delta; else loss+=Math.abs(delta); }
                const elevationExtent=elevationValues.reduce((extent,value)=>[Math.min(extent[0],value),Math.max(extent[1],value)],[elevationValues[0],elevationValues[0]]);
                const profileSampleStep=Math.max(1,Math.ceil(elevated.length/2000)), profileSamples=elevated.filter((point,index)=>point.elevation!==null && (index%profileSampleStep===0 || index===elevated.length-1));
                document.getElementById('route-elevation-loss').textContent=Math.round(loss)+' m'; document.getElementById('route-elevation-range').textContent=Math.round(elevationExtent[0])+' / '+Math.round(elevationExtent[1])+' m';
                const profileMarker=L.circleMarker(latLngs[0],{radius:6,color:'#fff',weight:2,fillColor:'#f4b120',fillOpacity:1}).addTo(map); profileMarker.setStyle({opacity:0,fillOpacity:0});
                const drawProfile=hoverX=>{ const ratio=window.devicePixelRatio||1, rect=canvas.getBoundingClientRect(), width=Math.max(300,rect.width),height=190; canvas.width=width*ratio;canvas.height=height*ratio;const ctx=canvas.getContext('2d');ctx.scale(ratio,ratio);ctx.clearRect(0,0,width,height);const pad={l:42,r:12,t:12,b:25},plotW=width-pad.l-pad.r,plotH=height-pad.t-pad.b,minE=elevationExtent[0],maxE=elevationExtent[1],range=Math.max(1,maxE-minE);ctx.strokeStyle='rgba(255,255,255,.12)';ctx.fillStyle='#aaa';ctx.font='11px sans-serif';for(let n=0;n<=3;n++){const y=pad.t+plotH*n/3,e=Math.round(maxE-range*n/3);ctx.beginPath();ctx.moveTo(pad.l,y);ctx.lineTo(width-pad.r,y);ctx.stroke();ctx.fillText(e+'m',2,y+4);}const trace=()=>{let started=false;ctx.beginPath();profileSamples.forEach(p=>{const x=pad.l+p.distance/totalDistance*plotW,y=pad.t+(maxE-p.elevation)/range*plotH;if(!started){ctx.moveTo(x,y);started=true;}else ctx.lineTo(x,y);});return started;};if(trace()){ctx.lineTo(width-pad.r,pad.t+plotH);ctx.lineTo(pad.l,pad.t+plotH);ctx.closePath();const grad=ctx.createLinearGradient(0,pad.t,0,pad.t+plotH);grad.addColorStop(0,'rgba(244,177,32,.65)');grad.addColorStop(1,'rgba(244,177,32,.08)');ctx.fillStyle=grad;ctx.fill();}if(trace()){ctx.strokeStyle='#f4b120';ctx.lineWidth=2;ctx.stroke();}ctx.fillStyle='#aaa';ctx.fillText('0',pad.l,pad.t+plotH+17);ctx.fillText((totalDistance/1000).toFixed(1)+' km',width-pad.r-42,pad.t+plotH+17);if(Number.isFinite(hoverX)){ctx.strokeStyle='#fff';ctx.beginPath();ctx.moveTo(hoverX,pad.t);ctx.lineTo(hoverX,pad.t+plotH);ctx.stroke();}};
                const profileMove=clientX=>{const rect=canvas.getBoundingClientRect(),padL=42,padR=12,x=Math.max(padL,Math.min(rect.width-padR,clientX-rect.left)),distance=(x-padL)/(rect.width-padL-padR)*totalDistance;let idx=indexAtDistance(distance);if(elevated[idx].elevation===null){let offset=1;while(idx-offset>=0||idx+offset<elevated.length){if(idx-offset>=0&&elevated[idx-offset].elevation!==null){idx-=offset;break;}if(idx+offset<elevated.length&&elevated[idx+offset].elevation!==null){idx+=offset;break;}offset++;}}const point=elevated[idx];drawProfile(x);profileMarker.setLatLng(point.latLng).setStyle({opacity:1,fillOpacity:1});hoverLabel.textContent=(point.distance/1000).toFixed(2)+' km · '+Math.round(point.elevation)+' m';};
                canvas.addEventListener('mousemove',event=>profileMove(event.clientX)); canvas.addEventListener('mouseleave',()=>{drawProfile();profileMarker.setStyle({opacity:0,fillOpacity:0});hoverLabel.textContent='Passe o cursor sobre o gráfico';}); canvas.addEventListener('touchmove',event=>{event.preventDefault();profileMove(event.touches[0].clientX);},{passive:false}); window.addEventListener('resize',()=>drawProfile()); drawProfile();
              } else { canvas.replaceWith(Object.assign(document.createElement('div'),{className:'route-elevation-empty',textContent:'Este GPX não contém dados de elevação.'})); }
            }).catch(error => { document.getElementById('route-map').innerHTML='<div class="alert alert-danger m-3"><strong>Não foi possível carregar a geometria privada.</strong><div class="small mt-1"></div></div>'; document.querySelector('#route-map .small').textContent=error.message; });
          </script>
        </cfif>

        <form method="post" action="./?id=<cfoutput>#qPercurso.id_percurso#</cfoutput>">
          <input type="hidden" name="acao" value="salvar"/><input type="hidden" name="id_percurso" value="<cfoutput>#qPercurso.id_percurso#</cfoutput>"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.percursoCsrfToken#</cfoutput>"/>
          <div class="row g-3">
            <div class="col-lg-6"><label class="form-label">Nome</label><input class="form-control" name="nome" maxlength="180" required value="<cfoutput>#htmlEditFormat(qPercurso.nome)#</cfoutput>" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>/></div>
            <div class="col-lg-2"><label class="form-label">Distância (km)</label><input class="form-control" name="distancia_km" value="<cfoutput>#numberFormat(qPercurso.distancia_nominal_m/1000,'0.000')#</cfoutput>" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>/></div>
            <div class="col-lg-2"><label class="form-label">Tipo</label><select class="form-select" name="tipo_percurso" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>><cfloop list="rua,trail,misto" item="routeType"><option value="<cfoutput>#routeType#</cfoutput>" <cfif qPercurso.tipo_percurso EQ routeType>selected</cfif>><cfoutput>#uCase(left(routeType,1))##mid(routeType,2,len(routeType))#</cfoutput></option></cfloop></select></div>
            <div class="col-lg-2"><label class="form-label">País</label><input class="form-control" name="pais" maxlength="2" value="<cfoutput>#qPercurso.pais#</cfoutput>" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>/></div>
            <div class="col-lg-5"><label class="form-label">Cidade</label><input class="form-control" name="cidade" value="<cfoutput>#htmlEditFormat(qPercurso.cidade)#</cfoutput>" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>/></div>
            <div class="col-lg-2"><label class="form-label">Estado</label><input class="form-control" name="estado" maxlength="2" value="<cfoutput>#qPercurso.estado#</cfoutput>" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>/></div>
            <div class="col-lg-2"><label class="form-label">Visibilidade</label><select class="form-select" name="visibilidade" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>><cfloop list="privado,compartilhado,publico" item="visibility"><option value="<cfoutput>#visibility#</cfoutput>" <cfif qPercurso.visibilidade EQ visibility>selected</cfif>><cfoutput>#visibility#</cfoutput></option></cfloop></select></div>
            <div class="col-lg-3"><label class="form-label">Status</label><select class="form-select" name="status" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>><cfloop list="rascunho,publicado,arquivado" item="routeStatus"><option value="<cfoutput>#routeStatus#</cfoutput>" <cfif qPercurso.status EQ routeStatus>selected</cfif>><cfoutput>#routeStatus#</cfoutput></option></cfloop></select></div>
            <div class="col-12"><label class="form-label">Descrição</label><textarea class="form-control" name="descricao" rows="3" <cfif NOT VARIABLES.routeCanEdit>disabled</cfif>><cfoutput>#htmlEditFormat(qPercurso.descricao)#</cfoutput></textarea></div>
            <cfif VARIABLES.routeCanEdit><div class="col-12"><button class="btn btn-warning" type="submit">Salvar metadados</button></div></cfif>
          </div>
        </form>

        <cfif VARIABLES.percursoIsSystemAdmin>
          <div class="route-owner-admin border-top border-secondary mt-4 pt-4">
            <div class="d-flex flex-wrap align-items-start justify-content-between gap-2 mb-3">
              <div>
                <h5 class="mb-1"><i class="fa-solid fa-user-shield text-warning me-2"></i>Proprietário do percurso</h5>
                <p class="small text-muted mb-0">Somente ADMINs do sistema podem transferir a propriedade.</p>
              </div>
            </div>

            <div class="route-owner-current p-3 mb-3">
              <div class="small text-muted mb-1">Proprietário atual</div>
              <cfif qPercursoOwner.recordcount>
                <cfoutput>
                  <div class="fw-bold">#htmlEditFormat(qPercursoOwner.name)# <span class="text-muted fw-normal">###qPercursoOwner.id#</span></div>
                  <div class="small text-muted route-owner-email">#htmlEditFormat(qPercursoOwner.email)#</div>
                </cfoutput>
              <cfelse>
                <cfoutput><div class="fw-bold">Usuário ###qPercurso.id_usuario_criador#</div></cfoutput>
              </cfif>
            </div>

            <form method="get" action="./" class="row g-2 align-items-end mb-3">
              <input type="hidden" name="id" value="<cfoutput>#qPercurso.id_percurso#</cfoutput>"/>
              <div class="col-lg-9">
                <label class="form-label" for="route-owner-search">Buscar novo proprietário</label>
                <input class="form-control" id="route-owner-search" name="owner_busca" value="<cfoutput>#htmlEditFormat(URL.owner_busca)#</cfoutput>" placeholder="Nome, e-mail ou ID do usuário" autocomplete="off"/>
              </div>
              <div class="col-lg-3 d-flex gap-2">
                <button class="btn btn-outline-warning flex-grow-1" type="submit"><i class="fa-solid fa-magnifying-glass me-2"></i>Buscar</button>
                <cfif len(trim(URL.owner_busca))><a class="btn btn-outline-secondary" href="./?id=<cfoutput>#qPercurso.id_percurso#</cfoutput>" title="Limpar busca"><i class="fa-solid fa-xmark"></i></a></cfif>
              </div>
            </form>

            <cfif qPercursoOwnerSearch.recordcount>
              <cfset VARIABLES.routeOwnerRouteId = qPercurso.id_percurso/>
              <cfset VARIABLES.routeOwnerCurrentUserId = qPercurso.id_usuario_criador/>
              <div aria-label="Resultados da busca de usuários">
                <cfoutput query="qPercursoOwnerSearch">
                  <div class="route-owner-result">
                    <div class="route-owner-identity">
                      <div class="fw-bold">#htmlEditFormat(qPercursoOwnerSearch.name)# <span class="text-muted fw-normal">###qPercursoOwnerSearch.id#</span></div>
                      <div class="small text-muted route-owner-email">#htmlEditFormat(qPercursoOwnerSearch.email)#</div>
                    </div>
                    <form method="post" action="./?id=#VARIABLES.routeOwnerRouteId#" class="m-0" onsubmit="return confirm('Transferir este percurso para o usuário selecionado?');">
                      <input type="hidden" name="acao" value="alterar_proprietario"/>
                      <input type="hidden" name="id_percurso" value="#VARIABLES.routeOwnerRouteId#"/>
                      <input type="hidden" name="id_usuario_criador" value="#qPercursoOwnerSearch.id#"/>
                      <input type="hidden" name="csrf_token" value="#VARIABLES.percursoCsrfToken#"/>
                      <button class="btn btn-sm <cfif qPercursoOwnerSearch.id EQ VARIABLES.routeOwnerCurrentUserId>btn-outline-secondary<cfelse>btn-outline-warning</cfif>" type="submit" <cfif qPercursoOwnerSearch.id EQ VARIABLES.routeOwnerCurrentUserId>disabled</cfif>>
                        <cfif qPercursoOwnerSearch.id EQ VARIABLES.routeOwnerCurrentUserId>Atual<cfelse>Definir como dono</cfif>
                      </button>
                    </form>
                  </div>
                </cfoutput>
              </div>
            <cfelseif len(trim(URL.owner_busca)) GTE 2 OR (isNumeric(trim(URL.owner_busca)) AND val(URL.owner_busca) GT 0)>
              <div class="alert alert-secondary mb-0">Nenhum usuário encontrado para esta busca.</div>
            </cfif>
          </div>
        </cfif>
      </div></div>

      <cfif NOT VARIABLES.percursoEventLinksReady>
        <cfif VARIABLES.routeCanEdit OR VARIABLES.percursoIsSystemAdmin>
          <div class="alert alert-warning mb-4"><strong>Vínculos com eventos ainda não disponíveis.</strong> Aplique <code>/_codex/sql/2026-07-21_tb_evento_percursos_gpx.sql</code> no banco.</div>
        </cfif>
      <cfelse>
        <div class="card bg-dark border-secondary mb-4"><div class="card-body">
          <div class="d-flex flex-wrap align-items-start justify-content-between gap-2 mb-3">
            <div>
              <h5 class="mb-1"><i class="fa-solid fa-calendar-check text-warning me-2"></i>Eventos vinculados</h5>
              <p class="small text-muted mb-0">Membros ativos das contas associadas aos eventos podem visualizar este percurso.</p>
            </div>
            <span class="badge badge-secondary"><cfoutput>#qPercursoEventos.recordcount#</cfoutput> vínculo<cfif qPercursoEventos.recordcount NEQ 1>s</cfif></span>
          </div>

          <cfset VARIABLES.routeEventRouteId = qPercurso.id_percurso/>
          <cfif qPercursoEventos.recordcount>
            <div class="mb-4">
              <cfoutput query="qPercursoEventos">
                <div class="route-event-item">
                  <div class="route-event-identity">
                    <div class="fw-bold"><a class="link-light text-decoration-none" href="/eventos/?id_evento=#qPercursoEventos.id_evento#" target="_blank" rel="noopener">#htmlEditFormat(qPercursoEventos.nome_evento)# <i class="fa-solid fa-arrow-up-right-from-square small text-warning ms-1"></i></a></div>
                    <div class="route-event-meta small text-muted mt-1">
                      <span>###qPercursoEventos.id_evento#</span>
                      <cfif len(qPercursoEventos.id_evento_percurso & '')><span class="badge badge-warning">#htmlEditFormat(qPercursoEventos.percurso_evento)# #htmlEditFormat(qPercursoEventos.unidade_de_medida)# · modalidade ###qPercursoEventos.id_evento_percurso#</span></cfif>
                      <cfif isDate(qPercursoEventos.data_inicial)><span><i class="fa-regular fa-calendar me-1"></i>#dateFormat(qPercursoEventos.data_inicial, 'dd/mm/yyyy')#</span></cfif>
                      <cfif len(trim(qPercursoEventos.cidade & ''))><span><i class="fa-solid fa-location-dot me-1"></i>#htmlEditFormat(qPercursoEventos.cidade)#<cfif len(trim(qPercursoEventos.estado & ''))>/#htmlEditFormat(qPercursoEventos.estado)#</cfif></span></cfif>
                    </div>
                    <div class="small mt-2"><span class="text-muted">Acesso herdado por:</span> <cfif len(trim(qPercursoEventos.contas & ''))>#htmlEditFormat(qPercursoEventos.contas)#<cfelse><span class="text-muted">nenhuma conta ativa</span></cfif></div>
                  </div>
                  <cfif VARIABLES.percursoCanManageEventLinks>
                    <form method="post" action="./?id=#VARIABLES.routeEventRouteId#" class="m-0" onsubmit="return confirm('Remover o vínculo deste evento com o percurso?');">
                      <input type="hidden" name="acao" value="desvincular_evento"/>
                      <input type="hidden" name="id_percurso" value="#VARIABLES.routeEventRouteId#"/>
                      <input type="hidden" name="id_evento" value="#qPercursoEventos.id_evento#"/>
                      <input type="hidden" name="id_evento_percurso" value="#qPercursoEventos.id_evento_percurso#"/>
                      <input type="hidden" name="csrf_token" value="#VARIABLES.percursoCsrfToken#"/>
                      <button class="btn btn-sm btn-outline-danger" type="submit"><i class="fa-solid fa-link-slash me-1"></i>Desvincular</button>
                    </form>
                  </cfif>
                </div>
              </cfoutput>
            </div>
          <cfelse>
            <div class="alert alert-secondary mb-4">Este percurso ainda não está vinculado a nenhum evento.</div>
          </cfif>

          <cfif VARIABLES.percursoCanLinkEvents>
            <div class="border-top border-secondary pt-3">
              <form method="get" action="./" class="row g-2 align-items-end mb-3">
                <input type="hidden" name="id" value="<cfoutput>#qPercurso.id_percurso#</cfoutput>"/>
                <div class="col-lg-9">
                  <label class="form-label" for="route-event-search">Vincular outro evento</label>
                  <input class="form-control" id="route-event-search" name="evento_busca" value="<cfoutput>#htmlEditFormat(URL.evento_busca)#</cfoutput>" placeholder="Nome, cidade, tag ou ID do evento" autocomplete="off"/>
                </div>
                <div class="col-lg-3 d-flex gap-2">
                  <button class="btn btn-outline-warning flex-grow-1" type="submit"><i class="fa-solid fa-magnifying-glass me-2"></i>Buscar</button>
                  <cfif len(trim(URL.evento_busca))><a class="btn btn-outline-secondary" href="./?id=<cfoutput>#qPercurso.id_percurso#</cfoutput>" title="Limpar busca"><i class="fa-solid fa-xmark"></i></a></cfif>
                </div>
              </form>

              <cfif qPercursoEventSearch.recordcount>
                <div aria-label="Resultados da busca de eventos">
                  <cfoutput query="qPercursoEventSearch">
                    <div class="route-event-item">
                      <div class="route-event-identity">
                        <div class="fw-bold">#htmlEditFormat(qPercursoEventSearch.nome_evento)#</div>
                        <div class="route-event-meta small text-muted mt-1">
                          <span>###qPercursoEventSearch.id_evento#</span>
                          <cfif isDate(qPercursoEventSearch.data_inicial)><span><i class="fa-regular fa-calendar me-1"></i>#dateFormat(qPercursoEventSearch.data_inicial, 'dd/mm/yyyy')#</span></cfif>
                          <cfif len(trim(qPercursoEventSearch.cidade & ''))><span><i class="fa-solid fa-location-dot me-1"></i>#htmlEditFormat(qPercursoEventSearch.cidade)#<cfif len(trim(qPercursoEventSearch.estado & ''))>/#htmlEditFormat(qPercursoEventSearch.estado)#</cfif></span></cfif>
                        </div>
                        <div class="small mt-2"><span class="text-muted">Contas ativas:</span> <cfif len(trim(qPercursoEventSearch.contas & ''))>#htmlEditFormat(qPercursoEventSearch.contas)#<cfelse><span class="text-muted">nenhuma</span></cfif></div>
                      </div>
                      <form method="post" action="./?id=#VARIABLES.routeEventRouteId#" class="m-0">
                        <input type="hidden" name="acao" value="vincular_evento"/>
                        <input type="hidden" name="id_percurso" value="#VARIABLES.routeEventRouteId#"/>
                        <input type="hidden" name="id_evento" value="#qPercursoEventSearch.id_evento#"/>
                        <input type="hidden" name="csrf_token" value="#VARIABLES.percursoCsrfToken#"/>
                        <button class="btn btn-sm btn-outline-warning" type="submit"><i class="fa-solid fa-link me-1"></i>Vincular</button>
                      </form>
                    </div>
                  </cfoutput>
                </div>
              <cfelseif len(trim(URL.evento_busca)) GTE 2 OR (isNumeric(trim(URL.evento_busca)) AND val(URL.evento_busca) GT 0)>
                <div class="alert alert-secondary mb-0">Nenhum evento disponível foi encontrado para esta busca.</div>
              </cfif>
            </div>
          <cfelseif VARIABLES.percursoCanManageEventLinks>
            <p class="small text-muted border-top border-secondary pt-3 mb-0">Para vincular um novo evento, use uma conta na qual você tenha papel OWNER, ADMIN ou OPERADOR.</p>
          </cfif>
        </div></div>
      </cfif>

      <cfif VARIABLES.routeCanEdit>
        <div class="card bg-dark border-secondary mb-4"><div class="card-body"><h5>Adicionar versão</h5><p class="text-muted">A versão anterior permanece preservada no histórico.</p>
          <form method="post" enctype="multipart/form-data" action="./?id=<cfoutput>#qPercurso.id_percurso#</cfoutput>" class="row g-3 align-items-end">
            <input type="hidden" name="acao" value="adicionar_versao"/><input type="hidden" name="id_percurso" value="<cfoutput>#qPercurso.id_percurso#</cfoutput>"/><input type="hidden" name="csrf_token" value="<cfoutput>#VARIABLES.percursoCsrfToken#</cfoutput>"/>
            <div class="col-lg-8"><label class="form-label">Novo GPX</label><input class="form-control" type="file" name="arquivo_gpx" accept=".gpx,application/gpx+xml" required/></div><div class="col-lg-4"><button class="btn btn-outline-warning" type="submit">Processar nova versão</button></div>
          </form>
        </div></div>
      </cfif>

      <div class="card bg-dark border-secondary mb-4"><div class="card-body"><h5>Versões</h5><div class="table-responsive"><table class="table table-dark table-hover align-middle"><thead><tr><th>Versão</th><th>Arquivo</th><th>Distância</th><th>Pontos</th><th>Elevação</th><th>SHA-256</th><th>Data</th></tr></thead><tbody><cfoutput query="qPercursoArquivos"><tr><td>v#versao#</td><td>#htmlEditFormat(nome_original)#</td><td>#numberFormat(distancia_gpx_m/1000,'0.000')# km</td><td>#numberFormat(quantidade_pontos)#</td><td>#numberFormat(ganho_elevacao_m,'0')# m</td><td><div class="route-hash" title="#sha256#">#sha256#</div></td><td>#dateTimeFormat(criado_em,'dd/mm/yyyy HH:nn')#</td></tr></cfoutput></tbody></table></div></div></div>

      <cfif VARIABLES.percursoIsOwner OR VARIABLES.percursoIsSystemAdmin><div class="card bg-dark border-secondary mb-4"><div class="card-body"><h5>Auditoria</h5><div class="table-responsive"><table class="table table-dark table-sm"><thead><tr><th>Data</th><th>Ação</th><th>Usuário</th><th>IP</th></tr></thead><tbody><cfoutput query="qPercursoHistorico"><tr><td>#dateTimeFormat(criado_em,'dd/mm/yyyy HH:nn')#</td><td>#htmlEditFormat(acao)#</td><td>#htmlEditFormat(usuario_nome)#</td><td>#htmlEditFormat(endereco_ip)#</td></tr></cfoutput></tbody></table></div></div></div></cfif>
    </cfif>
  </cfif>

  <cfif VARIABLES.percursoSelectedId LTE 0>
  <div class="card bg-dark border-secondary"><div class="card-body">
    <form method="get" action="./" class="row g-2 mb-4"><div class="col-lg-6"><input class="form-control" name="q" placeholder="Nome ou cidade" value="<cfoutput>#htmlEditFormat(URL.q)#</cfoutput>"/></div><div class="col-lg-2"><input class="form-control" name="estado" maxlength="2" placeholder="UF" value="<cfoutput>#htmlEditFormat(URL.estado)#</cfoutput>"/></div><div class="col-lg-2"><select class="form-select" name="status"><option value="">Todos os status</option><cfloop list="rascunho,publicado,arquivado" item="filterStatus"><option value="<cfoutput>#filterStatus#</cfoutput>" <cfif URL.status EQ filterStatus>selected</cfif>><cfoutput>#filterStatus#</cfoutput></option></cfloop></select></div><div class="col-lg-2"><button class="btn btn-outline-warning w-100" type="submit">Buscar</button></div></form>
    <div class="table-responsive"><table class="table table-dark table-hover align-middle"><thead><tr><th>ID</th><th>Nome</th><th>Local</th><th>Nominal</th><th>GPX</th><th>Versão</th><th>Status</th><th></th></tr></thead><tbody>
      <cfoutput query="qPercursos"><tr><td>#id_percurso#</td><td><strong>#htmlEditFormat(nome)#</strong><div class="small text-muted">#htmlEditFormat(tipo_percurso)# · #htmlEditFormat(visibilidade)#</div></td><td>#htmlEditFormat(cidade)#<cfif len(estado)>/#htmlEditFormat(estado)#</cfif></td><td>#numberFormat(distancia_nominal_m/1000,'0.000')# km</td><td><cfif len(distancia_gpx_m & '')>#numberFormat(distancia_gpx_m/1000,'0.000')# km</cfif></td><td><cfif len(versao & '')>v#versao#</cfif></td><td><span class="badge <cfif status EQ 'publicado'>badge-success<cfelseif status EQ 'arquivado'>badge-secondary<cfelse>badge-warning</cfif>">#status#</span></td><td><a class="btn btn-sm btn-outline-warning" href="./?id=#id_percurso#">Abrir</a></td></tr></cfoutput>
      <cfif NOT qPercursos.recordcount><tr><td colspan="8" class="text-center text-muted py-4">Nenhum percurso encontrado.</td></tr></cfif>
    </tbody></table></div>
  </div></div>
  </cfif>
</cfif>
