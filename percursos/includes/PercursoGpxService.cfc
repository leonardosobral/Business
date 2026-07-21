component output="false" {

    public struct function analyze(required string filePath) {
        var result = { valid=false, errors=[], points=[], distanceM=0, elevationGainM=0,
            elevationMin="", elevationMax="", minLat=90, minLng=180, maxLat=-90, maxLng=-180,
            pointCount=0, sha256="" };
        var fileInfo = getFileInfo(arguments.filePath);
        if (fileInfo.size <= 0) {
            arrayAppend(result.errors, "O arquivo GPX esta vazio.");
            return result;
        }
        if (fileInfo.size > 20971520) {
            arrayAppend(result.errors, "O arquivo GPX excede o limite de 20 MB.");
            return result;
        }

        var content = fileRead(arguments.filePath, "utf-8");
        if (findNoCase("<!DOCTYPE", content) OR findNoCase("<!ENTITY", content)) {
            arrayAppend(result.errors, "O GPX contem declaracoes XML nao permitidas.");
            return result;
        }
        if (NOT reFindNoCase("<gpx([[:space:]>])", content)) {
            arrayAppend(result.errors, "O arquivo nao possui um documento GPX valido.");
            return result;
        }

        var blocks = reMatchNoCase("(?s)<trkpt[[:space:]][^>]*>.*?</trkpt>|<trkpt[[:space:]][^>]*/>", content);
        if (arrayLen(blocks) < 2) {
            blocks = reMatchNoCase("(?s)<rtept[[:space:]][^>]*>.*?</rtept>|<rtept[[:space:]][^>]*/>", content);
        }
        if (arrayLen(blocks) > 250000) {
            arrayAppend(result.errors, "O GPX excede o limite de 250 mil pontos.");
            return result;
        }

        var previous = {};
        var hasPrevious = false;
        var elevationSeen = false;
        for (var block in blocks) {
            var latMatch = reFindNoCase('lat[[:space:]]*=[[:space:]]*["''](-?[0-9]+(?:\.[0-9]+)?)["'']', block, 1, true);
            var lngMatch = reFindNoCase('lon[[:space:]]*=[[:space:]]*["''](-?[0-9]+(?:\.[0-9]+)?)["'']', block, 1, true);
            if (arrayLen(latMatch.pos) < 2 OR latMatch.pos[2] <= 0 OR arrayLen(lngMatch.pos) < 2 OR lngMatch.pos[2] <= 0) continue;

            var lat = val(mid(block, latMatch.pos[2], latMatch.len[2]));
            var lng = val(mid(block, lngMatch.pos[2], lngMatch.len[2]));
            if (lat < -90 OR lat > 90 OR lng < -180 OR lng > 180) {
                arrayAppend(result.errors, "O GPX contem coordenadas fora dos limites geograficos.");
                return result;
            }

            var point = {lat=lat, lng=lng, hasElevation=false, elevation=0};
            var eleMatch = reFindNoCase("<ele>[[:space:]]*(-?[0-9]+(?:\.[0-9]+)?)[[:space:]]*</ele>", block, 1, true);
            if (arrayLen(eleMatch.pos) >= 2 AND eleMatch.pos[2] > 0) {
                point.elevation = val(mid(block, eleMatch.pos[2], eleMatch.len[2]));
                point.hasElevation = true;
                if (NOT elevationSeen) {
                    result.elevationMin = point.elevation;
                    result.elevationMax = point.elevation;
                    elevationSeen = true;
                } else {
                    result.elevationMin = min(result.elevationMin, point.elevation);
                    result.elevationMax = max(result.elevationMax, point.elevation);
                }
                if (hasPrevious AND previous.hasElevation AND point.elevation > previous.elevation) {
                    result.elevationGainM += point.elevation - previous.elevation;
                }
            }
            if (hasPrevious) result.distanceM += haversine(previous.lat, previous.lng, point.lat, point.lng);
            result.minLat = min(result.minLat, lat);
            result.maxLat = max(result.maxLat, lat);
            result.minLng = min(result.minLng, lng);
            result.maxLng = max(result.maxLng, lng);
            arrayAppend(result.points, point);
            previous = point;
            hasPrevious = true;
        }

        result.pointCount = arrayLen(result.points);
        if (result.pointCount < 2) {
            arrayAppend(result.errors, "O GPX precisa conter pelo menos dois pontos de track ou rota.");
            return result;
        }
        result.sha256 = lCase(hash(fileReadBinary(arguments.filePath), "SHA-256"));
        result.valid = true;
        return result;
    }

    public void function writeGeoJson(required struct analysis, required string destination) {
        var coordinates = [];
        for (var point in arguments.analysis.points) {
            var coordinate = [point.lng, point.lat];
            if (point.hasElevation) arrayAppend(coordinate, point.elevation);
            arrayAppend(coordinates, coordinate);
        }
        // As chaves GeoJSON sao case-sensitive. Alguns runtimes Adobe CF
        // serializam chaves de struct em maiusculas, por isso montamos o
        // envelope padrao explicitamente e serializamos apenas os valores.
        var properties = {pointCount=arguments.analysis.pointCount, distanceM=arguments.analysis.distanceM};
        var geojson = '{"type":"Feature","properties":' & serializeJSON(properties)
            & ',"geometry":{"type":"LineString","coordinates":' & serializeJSON(coordinates) & '}}';
        fileWrite(arguments.destination, geojson, "utf-8");
    }

    private numeric function haversine(required numeric lat1, required numeric lng1, required numeric lat2, required numeric lng2) {
        var radius = 6371000;
        var dLat = (arguments.lat2 - arguments.lat1) * pi() / 180;
        var dLng = (arguments.lng2 - arguments.lng1) * pi() / 180;
        var a = sin(dLat / 2)^2 + cos(arguments.lat1 * pi() / 180) * cos(arguments.lat2 * pi() / 180) * sin(dLng / 2)^2;
        return radius * 2 * createObject("java", "java.lang.Math").atan2(sqr(a), sqr(1-a));
    }
}
