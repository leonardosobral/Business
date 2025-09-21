<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Mapbox Tracker</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />

  <!-- Mapbox GL JS -->
<link href="https://api.mapbox.com/mapbox-gl-js/v3.12.0/mapbox-gl.css" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v3.12.0/mapbox-gl.js"></script>

  <!-- togeojson for GPX parsing -->
  <script src="https://unpkg.com/togeojson"></script>

  <style>
    body { margin: 0; font-family: sans-serif; }
    #map { height: 80vh; }
    #controls {
      padding: 10px;
      display: flex;
      gap: 15px;
      align-items: center;
      background: #f0f0f0;
    }
    .stat { font-weight: bold; }
  </style>
</head>
<body>

<div id="controls">
  <button id="startBtn">▶ Start</button>
  <button id="pauseBtn">⏸ Pause</button>
  <label>Speed: <span id="speedLabel" class="stat">22</span> km/h</label>
  <input type="range" id="speedSlider" min="1" max="30" value="22" />
  <span>Distance: <span id="distanceEl" class="stat">0.00</span> m</span>
  <span>Time: <span id="timeEl" class="stat">00:00</span></span>
  <span>Speed: <span id="liveSpeed" class="stat">0.00</span> km/h</span>
  <span>ETA: <span id="eta" class="stat">--:--</span></span>
</div>

<div id="map"></div>

<script>
mapboxgl.accessToken = 'pk.eyJ1IjoicnVubmVyaHViIiwiYSI6ImNtY3Btb2RyaDA4MXcybXB4ZHcwcG1wc3QifQ.Xwn8mu9-T9CsURHnFwDhPg';

let map = new mapboxgl.Map({
  container: 'map',
  style: 'mapbox://styles/mapbox/streets-v11',
  center: [-122.4194, 37.7749], // default San Francisco
  zoom: 13
});

let route = [], index = 0, t = 0;
let speedKph = 22, intervalId = null, segmentDistance = 0, totalDistance = 0, startTime = null;
let marker, lineSource;

const speedSlider = document.getElementById('speedSlider');
const speedLabel = document.getElementById('speedLabel');
const startBtn = document.getElementById('startBtn');
const pauseBtn = document.getElementById('pauseBtn');
const distanceEl = document.getElementById('distanceEl');
const timeEl = document.getElementById('timeEl');
const liveSpeedEl = document.getElementById('liveSpeed');
const etaEl = document.getElementById('eta');

speedSlider.oninput = () => {
  speedKph = parseInt(speedSlider.value);
  speedLabel.textContent = speedKph;
};

function interpolate(p1, p2, t) {
  return [
    p1[0] + (p2[0] - p1[0]) * t,
    p1[1] + (p2[1] - p1[1]) * t
  ];
}

function getDistance(a, b) {
  const R = 6371e3;
  const toRad = deg => deg * Math.PI / 180;
  const dLat = toRad(b[1] - a[1]);
  const dLng = toRad(b[0] - a[0]);
  const lat1 = toRad(a[1]);
  const lat2 = toRad(b[1]);
  const aVal = Math.sin(dLat / 2) ** 2 +
               Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(aVal), Math.sqrt(1 - aVal));
  return R * c;
}

function formatTime(ms) {
  const sec = Math.floor(ms / 1000);
  return `${String(Math.floor(sec / 60)).padStart(2, '0')}:${String(sec % 60).padStart(2, '0')}`;
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
  const step = speedMps * 0.1;
  const segmentStep = step / segmentDistance;
  t += segmentStep;

  const now = Date.now();
  const elapsed = now - startTime;
  timeEl.textContent = formatTime(elapsed);
  liveSpeedEl.textContent = (speedMps * 3.6).toFixed(2);

  let remaining = 0;
  for (let i = index; i < route.length - 1; i++) {
    remaining += getDistance(route[i], route[i + 1]);
  }
  remaining -= getDistance(current, interpolate(current, next, t));
  const eta = remaining / speedMps;
  etaEl.textContent = isFinite(eta) ? formatTime(eta * 1000) : '--:--';

  const newPos = interpolate(current, next, t);
  distanceEl.textContent = (totalDistance + getDistance(current, newPos)).toFixed(2);
  marker.setLngLat(newPos);

  if (t >= 1) {
    totalDistance += segmentDistance;
    index++;
    t = 0;
    segmentDistance = 0;
    return;
  }
}

startBtn.onclick = () => {
  if (!route.length) return alert("Route not loaded");
  if (!intervalId) {
    if (!startTime) startTime = Date.now();
    intervalId = setInterval(moveMarker, 100);
  }
};

pauseBtn.onclick = () => {
  clearInterval(intervalId);
  intervalId = null;
};

// Load GPX on page load
fetch('MIF42k.gpx') // Replace with your path
  .then(res => res.text())
  .then(text => {
    const xml = new DOMParser().parseFromString(text, 'text/xml');
    const geojson = toGeoJSON.gpx(xml);
    const coords = geojson.features[0].geometry.coordinates;
    route = coords.map(c => [c[0], c[1]]); // lng, lat

    // Add route line
    map.on('load', () => {
      map.addSource('route', {
        type: 'geojson',
        data: {
          type: 'Feature',
          geometry: {
            type: 'LineString',
            coordinates: route
          }
        }
      });
      map.addLayer({
        id: 'routeLine',
        type: 'line',
        source: 'route',
        paint: {
          'line-color': '#3b9ddd',
          'line-width': 4
        }
      });

      marker = new mapboxgl.Marker({ color: '#e74c3c' })
        .setLngLat(route[0])
        .addTo(map);

      map.fitBounds(route.reduce((b, p) => b.extend(p), new mapboxgl.LngLatBounds(route[0], route[0])), { padding: 30 });
    });
  });
</script>

</body>
</html>
