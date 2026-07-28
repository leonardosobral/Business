(function () {
  'use strict';

  const config = window.routeMapboxConfig || {};
  const mapElement = document.getElementById('route-map');
  if (!mapElement) return;

  const showError = (message) => {
    mapElement.innerHTML = '<div class="alert alert-danger m-3"><strong>Não foi possível carregar o mapa Mapbox.</strong><div class="small mt-1"></div></div>';
    mapElement.querySelector('.small').textContent = message;
  };

  if (!window.mapboxgl) {
    showError('A biblioteca Mapbox GL JS não foi carregada.');
    return;
  }
  if (!config.token) {
    showError('O token público Mapbox não está configurado.');
    return;
  }

  mapboxgl.accessToken = config.token;

  fetch(config.geometryUrl, { credentials: 'same-origin' })
    .then(async (response) => {
      if (!response.ok) {
        let detail = 'HTTP ' + response.status;
        try {
          const payload = await response.json();
          detail = payload.message || payload.error || detail;
        } catch (_) {}
        throw new Error(detail);
      }
      return response.json();
    })
    .then(initializeMap)
    .catch((error) => showError(error.message));

  function initializeMap(data) {
    const geometry = data && data.geometry;
    const rawCoordinates = geometry && Array.isArray(geometry.coordinates) ? geometry.coordinates : [];
    const isMultiLine = geometry && String(geometry.type).toLowerCase() === 'multilinestring';
    const segments = (isMultiLine ? rawCoordinates : [rawCoordinates])
      .filter((segment) => Array.isArray(segment) && segment.length >= 2);
    const coordinates = segments.flat();
    if (coordinates.length < 2) throw new Error('O percurso não possui pontos suficientes.');

    const segmentIndexes = [];
    segments.forEach((segment, segmentIndex) => segment.forEach(() => segmentIndexes.push(segmentIndex)));
    const haversine = (a, b) => {
      const rad = Math.PI / 180;
      const dLat = (b[1] - a[1]) * rad;
      const dLng = (b[0] - a[0]) * rad;
      const value = Math.sin(dLat / 2) ** 2
        + Math.cos(a[1] * rad) * Math.cos(b[1] * rad) * Math.sin(dLng / 2) ** 2;
      return 6371000 * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
    };
    const cumulative = [];
    let totalDistance = 0;
    let flatIndex = 0;
    segments.forEach((segment) => segment.forEach((point, index) => {
      if (index > 0) totalDistance += haversine(segment[index - 1], point);
      cumulative[flatIndex++] = totalDistance;
    }));
    if (totalDistance < 1) throw new Error('O percurso não possui distância geográfica válida.');

    const indexAtDistance = (target) => {
      let low = 0;
      let high = cumulative.length - 1;
      while (low < high) {
        const middle = Math.floor((low + high) / 2);
        if (cumulative[middle] < target) low = middle + 1;
        else high = middle;
      }
      return low;
    };
    const pointAtDistance = (target) => {
      const high = indexAtDistance(target);
      if (high < 1) return coordinates[0].slice(0, 2);
      const low = high - 1;
      const span = cumulative[high] - cumulative[low];
      const ratio = span ? (target - cumulative[low]) / span : 0;
      return [
        coordinates[low][0] + (coordinates[high][0] - coordinates[low][0]) * ratio,
        coordinates[low][1] + (coordinates[high][1] - coordinates[low][1]) * ratio
      ];
    };
    const bearing = (a, b) => {
      const rad = Math.PI / 180;
      const y = Math.sin((b[0] - a[0]) * rad) * Math.cos(b[1] * rad);
      const x = Math.cos(a[1] * rad) * Math.sin(b[1] * rad)
        - Math.sin(a[1] * rad) * Math.cos(b[1] * rad) * Math.cos((b[0] - a[0]) * rad);
      return (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
    };

    const map = new mapboxgl.Map({
      container: 'route-map',
      style: 'mapbox://styles/mapbox/streets-v12',
      center: coordinates[0].slice(0, 2),
      zoom: 12,
      attributionControl: true
    });
    map.addControl(new mapboxgl.NavigationControl({ showCompass: true }), 'bottom-right');
    map.addControl(new mapboxgl.ScaleControl({ unit: 'metric' }), 'bottom-left');

    const bounds = coordinates.reduce(
      (result, point) => result.extend(point.slice(0, 2)),
      new mapboxgl.LngLatBounds(coordinates[0].slice(0, 2), coordinates[0].slice(0, 2))
    );
    const routeFeature = {
      type: 'Feature',
      properties: {},
      geometry: {
        type: isMultiLine ? 'MultiLineString' : 'LineString',
        coordinates: isMultiLine ? segments : segments[0]
      }
    };
    const addRouteLayer = () => {
      if (!map.getSource('business-route')) {
        map.addSource('business-route', { type: 'geojson', data: routeFeature });
      }
      if (!map.getLayer('business-route-outline')) {
        map.addLayer({
          id: 'business-route-outline',
          type: 'line',
          source: 'business-route',
          paint: { 'line-color': '#171717', 'line-width': 8, 'line-opacity': 0.65 }
        });
      }
      if (!map.getLayer('business-route-line')) {
        map.addLayer({
          id: 'business-route-line',
          type: 'line',
          source: 'business-route',
          paint: { 'line-color': '#f4b120', 'line-width': 5, 'line-opacity': 0.98 }
        });
      }
    };
    map.on('load', () => {
      addRouteLayer();
      map.fitBounds(bounds, { padding: 40, duration: 0 });
    });
    map.on('style.load', addRouteLayer);

    const makeElement = (className, label, title) => {
      const element = document.createElement('div');
      element.className = className;
      element.textContent = label;
      element.title = title || '';
      return element;
    };
    new mapboxgl.Marker({ element: makeElement('route-map-marker route-map-marker-start', 'L', 'Largada') })
      .setLngLat(coordinates[0].slice(0, 2)).setPopup(new mapboxgl.Popup().setText('Largada')).addTo(map);
    new mapboxgl.Marker({ element: makeElement('route-map-marker route-map-marker-finish', 'C', 'Chegada') })
      .setLngLat(coordinates[coordinates.length - 1].slice(0, 2)).setPopup(new mapboxgl.Popup().setText('Chegada')).addTo(map);

    const directionMarkers = [];
    const arrowCount = Math.min(14, Math.max(5, Math.floor(totalDistance / 3000)));
    for (let number = 1; number <= arrowCount; number++) {
      const index = Math.min(
        coordinates.length - 2,
        Math.max(0, Math.floor((coordinates.length - 1) * number / (arrowCount + 1)))
      );
      if (segmentIndexes[index] !== segmentIndexes[index + 1]) continue;
      const arrow = makeElement('route-direction-arrow', '▲', 'Direção');
      arrow.style.transform = 'rotate(' + bearing(coordinates[index], coordinates[index + 1]) + 'deg)';
      directionMarkers.push(new mapboxgl.Marker({ element: arrow, rotationAlignment: 'map' })
        .setLngLat(coordinates[index].slice(0, 2)).addTo(map));
    }

    let kilometerMarkers = [];
    const renderKilometers = (interval) => {
      kilometerMarkers.forEach((marker) => marker.remove());
      kilometerMarkers = [];
      if (!interval) return;
      for (let kilometer = interval; kilometer * 1000 < totalDistance; kilometer += interval) {
        const element = makeElement('route-km-marker', String(kilometer), kilometer + ' km');
        kilometerMarkers.push(new mapboxgl.Marker({ element })
          .setLngLat(pointAtDistance(kilometer * 1000)).addTo(map));
      }
    };
    renderKilometers(1);

    const streetButton = document.getElementById('route-layer-street');
    const satelliteButton = document.getElementById('route-layer-satellite');
    const selectStyle = (style, active, inactive) => {
      map.setStyle('mapbox://styles/mapbox/' + style);
      active.classList.add('btn-warning');
      active.classList.remove('btn-outline-light');
      inactive.classList.remove('btn-warning');
      inactive.classList.add('btn-outline-light');
    };
    streetButton.addEventListener('click', () => selectStyle('streets-v12', streetButton, satelliteButton));
    satelliteButton.addEventListener('click', () => selectStyle('satellite-streets-v12', satelliteButton, streetButton));
    document.getElementById('route-fit').addEventListener('click', () => map.fitBounds(bounds, { padding: 40 }));
    document.getElementById('route-km-interval').addEventListener('change', (event) => {
      renderKilometers(Number(event.target.value));
    });

    const shell = document.getElementById('route-preview-shell');
    document.getElementById('route-fullscreen').addEventListener('click', () => {
      if (document.fullscreenElement) document.exitFullscreen();
      else if (shell.requestFullscreen) shell.requestFullscreen();
    });
    document.addEventListener('fullscreenchange', () => window.setTimeout(() => map.resize(), 120));

    renderElevationProfile(map, coordinates, cumulative, segmentIndexes, totalDistance, indexAtDistance);
  }

  function renderElevationProfile(map, coordinates, cumulative, segmentIndexes, totalDistance, indexAtDistance) {
    const elevated = coordinates.map((point, index) => ({
      distance: cumulative[index],
      elevation: point.length > 2 && Number.isFinite(Number(point[2])) ? Number(point[2]) : null,
      coordinate: point.slice(0, 2),
      segmentIndex: segmentIndexes[index]
    }));
    const values = elevated.filter((point) => point.elevation !== null).map((point) => point.elevation);
    const canvas = document.getElementById('route-elevation-chart');
    const hoverLabel = document.getElementById('route-elevation-hover');
    if (values.length < 2) {
      canvas.replaceWith(Object.assign(document.createElement('div'), {
        className: 'route-elevation-empty',
        textContent: 'Este arquivo não contém dados de elevação.'
      }));
      return;
    }

    let loss = 0;
    for (let index = 1; index < elevated.length; index++) {
      const previous = elevated[index - 1];
      const current = elevated[index];
      if (previous.segmentIndex !== current.segmentIndex
        || previous.elevation === null || current.elevation === null) continue;
      const delta = current.elevation - previous.elevation;
      if (delta < 0) loss += Math.abs(delta);
    }
    const extent = values.reduce(
      (result, value) => [Math.min(result[0], value), Math.max(result[1], value)],
      [values[0], values[0]]
    );
    document.getElementById('route-elevation-loss').textContent = Math.round(loss) + ' m';
    document.getElementById('route-elevation-range').textContent =
      Math.round(extent[0]) + ' / ' + Math.round(extent[1]) + ' m';

    const sampleStep = Math.max(1, Math.ceil(elevated.length / 2000));
    const samples = elevated.filter((point, index) => point.elevation !== null
      && (index % sampleStep === 0 || index === elevated.length - 1));
    const profileElement = makeProfileMarker();
    const profileMarker = new mapboxgl.Marker({ element: profileElement })
      .setLngLat(coordinates[0].slice(0, 2)).addTo(map);
    profileElement.style.display = 'none';

    const draw = (hoverX) => {
      const ratio = window.devicePixelRatio || 1;
      const rectangle = canvas.getBoundingClientRect();
      const width = Math.max(300, rectangle.width);
      const height = 190;
      canvas.width = width * ratio;
      canvas.height = height * ratio;
      const context = canvas.getContext('2d');
      context.scale(ratio, ratio);
      const padding = { left: 42, right: 12, top: 12, bottom: 25 };
      const plotWidth = width - padding.left - padding.right;
      const plotHeight = height - padding.top - padding.bottom;
      const range = Math.max(1, extent[1] - extent[0]);
      context.clearRect(0, 0, width, height);
      context.strokeStyle = 'rgba(255,255,255,.12)';
      context.fillStyle = '#aaa';
      context.font = '11px sans-serif';
      for (let line = 0; line <= 3; line++) {
        const y = padding.top + plotHeight * line / 3;
        const elevation = Math.round(extent[1] - range * line / 3);
        context.beginPath();
        context.moveTo(padding.left, y);
        context.lineTo(width - padding.right, y);
        context.stroke();
        context.fillText(elevation + 'm', 2, y + 4);
      }
      const trace = () => {
        context.beginPath();
        samples.forEach((point, index) => {
          const x = padding.left + point.distance / totalDistance * plotWidth;
          const y = padding.top + (extent[1] - point.elevation) / range * plotHeight;
          if (index === 0) context.moveTo(x, y);
          else context.lineTo(x, y);
        });
      };
      trace();
      context.lineTo(width - padding.right, padding.top + plotHeight);
      context.lineTo(padding.left, padding.top + plotHeight);
      context.closePath();
      const gradient = context.createLinearGradient(0, padding.top, 0, padding.top + plotHeight);
      gradient.addColorStop(0, 'rgba(244,177,32,.65)');
      gradient.addColorStop(1, 'rgba(244,177,32,.08)');
      context.fillStyle = gradient;
      context.fill();
      trace();
      context.strokeStyle = '#f4b120';
      context.lineWidth = 2;
      context.stroke();
      context.fillStyle = '#aaa';
      context.fillText('0', padding.left, padding.top + plotHeight + 17);
      context.fillText((totalDistance / 1000).toFixed(1) + ' km', width - padding.right - 42, padding.top + plotHeight + 17);
      if (Number.isFinite(hoverX)) {
        context.strokeStyle = '#fff';
        context.beginPath();
        context.moveTo(hoverX, padding.top);
        context.lineTo(hoverX, padding.top + plotHeight);
        context.stroke();
      }
    };
    const move = (clientX) => {
      const rectangle = canvas.getBoundingClientRect();
      const left = 42;
      const right = 12;
      const x = Math.max(left, Math.min(rectangle.width - right, clientX - rectangle.left));
      const distance = (x - left) / (rectangle.width - left - right) * totalDistance;
      let index = indexAtDistance(distance);
      if (elevated[index].elevation === null) return;
      const point = elevated[index];
      draw(x);
      profileMarker.setLngLat(point.coordinate);
      profileElement.style.display = 'block';
      hoverLabel.textContent = (point.distance / 1000).toFixed(2) + ' km · '
        + Math.round(point.elevation) + ' m';
    };
    canvas.addEventListener('mousemove', (event) => move(event.clientX));
    canvas.addEventListener('mouseleave', () => {
      draw();
      profileElement.style.display = 'none';
      hoverLabel.textContent = 'Passe o cursor sobre o gráfico';
    });
    canvas.addEventListener('touchmove', (event) => {
      event.preventDefault();
      move(event.touches[0].clientX);
    }, { passive: false });
    window.addEventListener('resize', () => draw());
    draw();
  }

  function makeProfileMarker() {
    const element = document.createElement('div');
    element.style.width = '13px';
    element.style.height = '13px';
    element.style.borderRadius = '50%';
    element.style.border = '2px solid white';
    element.style.background = '#f4b120';
    element.style.boxShadow = '0 1px 5px rgba(0,0,0,.6)';
    return element;
  }
})();
