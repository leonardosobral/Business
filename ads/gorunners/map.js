(() => {
    const input = document.getElementById('zone-area');
    const count = document.getElementById('zone-count');
    const undo = document.getElementById('zone-undo');
    if (!window.L) {
        input.closest('details').open = true;
        count.textContent = 'Mapa indisponível. Informe as coordenadas abaixo.';
        undo.disabled = true;
        return;
    }
    const map = L.map('zone-map').setView([-23.587, -46.657], 14);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19, attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);
    const shape = L.layerGroup().addTo(map);
    let points = [];
    function draw() {
        shape.clearLayers();
        const positions = points.map(([lng, lat]) => [lat, lng]);
        if (positions.length) L.polygon(positions, {color: '#c58c00', weight: 3}).addTo(shape);
        positions.forEach(p => L.circleMarker(p, {radius: 4, color: '#161616', fillOpacity: 1, fillColor: '#f4b120'}).addTo(shape));
        count.textContent = points.length + ' ponto(s) selecionado(s)';
        undo.disabled = points.length === 0;
        input.value = points.length ? JSON.stringify(points) : '';
    }
    map.on('click', ({latlng}) => {
        if (points.length >= 100) return;
        points.push([Number(latlng.lng.toFixed(6)), Number(latlng.lat.toFixed(6))]);
        draw();
    });
    undo.addEventListener('click', () => { points.pop(); draw(); });
    input.addEventListener('invalid', () => { input.closest('details').open = true; });
    input.addEventListener('change', () => {
        try {
            const parsed = JSON.parse(input.value);
            if (!Array.isArray(parsed) || parsed.length > 100 || !parsed.every(p => Array.isArray(p) && p.length === 2 &&
                    p.every(Number.isFinite) && Math.abs(p[0]) <= 180 && Math.abs(p[1]) <= 85)) return;
            points = parsed;
            draw();
            if (points.length) map.fitBounds(points.map(([x,y]) => [y,x]), {maxZoom:16});
        } catch { /* The form also accepts edits before the array is complete. */ }
    });
    draw();
})();
