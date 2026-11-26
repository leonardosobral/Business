<cfif getBaseTemplatePath() EQ getCurrentTemplatePath()><cfheader statuscode="404"/><cfabort/></cfif>
<p id="zone-help">Aproxime o mapa e marque os vértices da zona. Marque pelo menos três pontos para cotar.</p>
<div id="zone-map" aria-label="Mapa para desenhar a zona" aria-describedby="zone-help" style="height:clamp(320px,50vh,540px);z-index:0"></div>
<div class="d-flex align-items-center gap-3 my-2"><button type="button" class="btn btn-sm btn-outline-light" id="zone-undo">Desfazer ponto</button><span id="zone-count" role="status"></span></div>
<details class="mb-3"><summary>Inserir coordenadas manualmente</summary><label class="w-100 mt-2">Lista de pontos em longitude e latitude (JSON)<textarea name="zone_area" class="form-control" id="zone-area" rows="2" required placeholder="[[-46.66,-23.58],[-46.65,-23.58],[-46.65,-23.59]]"></textarea></label></details>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="anonymous">
<script defer src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin="anonymous"></script>
<script defer src="/ads/gorunners/map.js"></script>
