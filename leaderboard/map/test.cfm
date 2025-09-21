<html>
<head>
<!-- Load Mapbox GL JS -->
<link href="https://api.mapbox.com/mapbox-gl-js/v3.12.0/mapbox-gl.css" rel="stylesheet">
<script src="https://api.mapbox.com/mapbox-gl-js/v3.12.0/mapbox-gl.js"></script>
</head>
<body>
  <div id="map" style="height:100vh;"></div>
  <script>
    mapboxgl.accessToken = 'pk.eyJ1IjoicnVubmVyaHViIiwiYSI6ImNtY3Btb2RyaDA4MXcybXB4ZHcwcG1wc3QifQ.Xwn8mu9-T9CsURHnFwDhPg'; // Replace this

    const map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/streets-v11',
      center: [-122.4194, 37.7749],
      zoom: 12
    });
  </script>
</body>
</html>
