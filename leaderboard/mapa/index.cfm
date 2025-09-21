<!DOCTYPE html>
<html>
<head>
  <title>Custom Route Tracker</title>
  <meta charset="utf-8" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet-draw/dist/leaflet.draw.css" />
  <style>
    #map { height: 80vh; }
    #controls {
      display: flex;
      flex-wrap: wrap;
      gap: 15px;
      padding: 10px;
      background: #f0f0f0;
      font-family: sans-serif;
      align-items: center;
    }
    .stat { font-weight: bold; }
  </style>
</head>
<body>

<div id="controls">

      <button id="startBtn">▶ Start</button>
      <button id="pauseBtn">⏸ Pause</button>
      <button id="drawBtn">✏️ Draw Route</button>
      <input type="file" id="fileInput" accept=".gpx,.geojson" />

      <label>Speed: <span id="speedLabel" class="stat">22</span> km/h</label>
      <input type="range" id="speedSlider" min="1" max="30" value="22" />

    <span>Distance: <span id="distanceTraveled" class="stat">0.00</span> m</span>
    <span>Time: <span id="elapsedTime" class="stat">00:00</span></span>
    <span>Speed: <span id="liveSpeed" class="stat">0.00</span> km/h</span>
    <span>ETA: <span id="eta" class="stat">--:--</span></span>

</div>

<div id="map"></div>

<script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
<script src="https://unpkg.com/leaflet-draw/dist/leaflet.draw.js"></script>
<script src="https://unpkg.com/togeojson"></script>

<script>
  const map = L.map('map').setView([37.7749, -122.4194], 13);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

  let route = [];           // stores the [lat, lng] points
  let polyline = null;
  let marker = null;

  let index = 0, t = 0, segmentDistance = 0;
  let totalDistance = 0, speedKph = 22, intervalId = null;
  let startTime = null;

  const startBtn = document.getElementById('startBtn');
  const pauseBtn = document.getElementById('pauseBtn');
  const drawBtn = document.getElementById('drawBtn');
  const fileInput = document.getElementById('fileInput');
  const speedSlider = document.getElementById('speedSlider');
  const speedLabel = document.getElementById('speedLabel');
  const distanceEl = document.getElementById('distanceTraveled');
  const timeEl = document.getElementById('elapsedTime');
  const liveSpeedEl = document.getElementById('liveSpeed');
  const etaEl = document.getElementById('eta');

  speedSlider.addEventListener('input', () => {
    speedKph = parseInt(speedSlider.value);
    speedLabel.textContent = speedKph;
  });

  function interpolate(p1, p2, t) {
    return [p1[0] + (p2[0] - p1[0]) * t, p1[1] + (p2[1] - p1[1]) * t];
  }

  function getDistance(a, b) {
    const R = 6371e3;
    const toRad = deg => deg * Math.PI / 180;
    const dLat = toRad(b[0] - a[0]);
    const dLng = toRad(b[1] - a[1]);
    const lat1 = toRad(a[0]), lat2 = toRad(b[0]);
    const aVal = Math.sin(dLat/2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng/2)**2;
    const c = 2 * Math.atan2(Math.sqrt(aVal), Math.sqrt(1 - aVal));
    return R * c;
  }

  function formatTime(ms) {
    const totalSec = Math.floor(ms / 1000);
    const min = Math.floor(totalSec / 60);
    const sec = totalSec % 60;
    return `${min.toString().padStart(2, '0')}:${sec.toString().padStart(2, '0')}`;
  }

  function resetSimulation() {
    clearInterval(intervalId);
    intervalId = null;
    index = 0;
    t = 0;
    totalDistance = 0;
    segmentDistance = 0;
    startTime = null;
    if (route.length > 0) {
      marker.setLatLng(route[0]);
    }
    distanceEl.textContent = '0.00';
    timeEl.textContent = '00:00';
    liveSpeedEl.textContent = '0.00';
    etaEl.textContent = '--:--';
  }

  function moveMarker() {
  if (index >= route.length - 1) {
    clearInterval(intervalId);
    return;
  }

  const current = route[index];
  const next = route[index + 1];

  if (segmentDistance === 0) {
    segmentDistance = getDistance(current, next);
  }

  const speedMps = speedKph * 1000 / 3600;
  const stepDistance = speedMps * 0.1; // 100ms step
  const segmentStep = stepDistance / segmentDistance;
  t += segmentStep;

  const now = Date.now();
  const elapsed = now - startTime;
  timeEl.textContent = formatTime(elapsed);

  // Speed / ETA updates here...
  const currentDistance = totalDistance + getDistance(current, interpolate(current, next, t));
  distanceEl.textContent = currentDistance.toFixed(2);
  liveSpeedEl.textContent = (speedMps * 3.6).toFixed(2);
  let remaining = 0;
  for (let i = index; i < route.length - 1; i++) {
    remaining += getDistance(route[i], route[i + 1]);
  }
  remaining -= getDistance(current, interpolate(current, next, t));
  const etaSec = remaining / speedMps;
  etaEl.textContent = isFinite(etaSec) ? formatTime(etaSec * 1000) : '--:--';

  // ➤ Here's the key fix:
  if (t >= 1) {
    totalDistance += segmentDistance;
    index++;
    t = 0;
    segmentDistance = 0;
    return; // Skip this frame to avoid rendering flicker
  }

  const newPos = interpolate(current, next, t);
  marker.setLatLng(newPos);
}

  startBtn.addEventListener('click', () => {
    if (!route.length) return alert("Please draw or upload a route first.");
    if (!intervalId) {
      if (!startTime) startTime = Date.now();
      intervalId = setInterval(moveMarker, 100);
    }
  });

  pauseBtn.addEventListener('click', () => {
    clearInterval(intervalId);
    intervalId = null;
  });

  // 🖌️ Route Drawing
  const drawControl = new L.Control.Draw({
    draw: {
      polyline: true,
      polygon: false,
      rectangle: false,
      circle: false,
      marker: false,
      circlemarker: false
    },
    edit: false
  });

  drawBtn.addEventListener('click', () => drawControl.addTo(map));

  map.on(L.Draw.Event.CREATED, function (e) {
    if (polyline) map.removeLayer(polyline);
    if (marker) map.removeLayer(marker);

    const layer = e.layer;
    polyline = layer.addTo(map);
    route = layer.getLatLngs().map(p => [p.lat, p.lng]);
    marker = L.marker(route[0]).addTo(map);
    resetSimulation();
  });

  // 📁 File Upload (GPX or GeoJSON)
  fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = function () {
      const text = reader.result;

      let geojson;
      if (file.name.endsWith('.gpx')) {
        const parser = new DOMParser();
        const gpx = parser.parseFromString(text, 'application/xml');
        geojson = toGeoJSON.gpx(gpx);
      } else if (file.name.endsWith('.geojson')) {
        geojson = JSON.parse(text);
      }

      if (!geojson || !geojson.features.length) {
        alert('Invalid file');
        return;
      }

      const coords = geojson.features[0].geometry.coordinates;
      route = coords.map(c => [c[1], c[0]]);
      if (polyline) map.removeLayer(polyline);
      if (marker) map.removeLayer(marker);
      polyline = L.polyline(route, { color: 'blue' }).addTo(map);
      map.fitBounds(polyline.getBounds());
      marker = L.marker(route[0]).addTo(map);
      resetSimulation();
    };
    reader.readAsText(file);
  });


  fetch('MIF42k.gpx') // ← Replace with your GPX path
  .then(response => response.text())
  .then(xmlText => {
    const parser = new DOMParser();
    const gpx = parser.parseFromString(xmlText, 'application/xml');
    const geojson = toGeoJSON.gpx(gpx);

    if (!geojson.features.length) {
      alert("Invalid GPX file");
      return;
    }

    const coords = geojson.features[0].geometry.coordinates;
    route = coords.map(c => [c[1], c[0]]); // Flip [lng, lat] → [lat, lng]

    if (polyline) map.removeLayer(polyline);
    if (marker) map.removeLayer(marker);

    polyline = L.polyline(route, { color: 'blue' }).addTo(map);
    map.fitBounds(polyline.getBounds());
    marker = L.marker(route[0]).addTo(map);

    resetSimulation();
  })
  .catch(err => {
    console.error("Failed to load GPX:", err);
  });

</script>

</body>
</html>
