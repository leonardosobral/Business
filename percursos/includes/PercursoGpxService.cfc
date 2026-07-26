component output="false" {

    variables.maxFileBytes = 20971520;
    variables.maxArchiveBytes = 52428800;
    variables.maxPoints = 1000000;

    public struct function analyze(required string filePath, string format="") {
        var result = newResult();
        var fileInfo = {};
        var detectedFormat = lCase(trim(arguments.format));

        if (NOT fileExists(arguments.filePath)) {
            arrayAppend(result.errors, "O arquivo do percurso nao foi encontrado.");
            return result;
        }

        fileInfo = getFileInfo(arguments.filePath);
        if (fileInfo.size <= 0) {
            arrayAppend(result.errors, "O arquivo do percurso esta vazio.");
            return result;
        }
        if (fileInfo.size > variables.maxFileBytes) {
            arrayAppend(result.errors, "O arquivo do percurso excede o limite de 20 MB.");
            return result;
        }

        if (NOT len(detectedFormat)) {
            detectedFormat = detectFormat(arguments.filePath);
        }
        if (detectedFormat EQ "json") {
            detectedFormat = "geojson";
        }
        if (NOT listFindNoCase("gpx,kml,kmz,geojson,fit", detectedFormat)) {
            arrayAppend(result.errors, "Formato nao suportado. Envie GPX, KML, KMZ, GeoJSON ou FIT.");
            return result;
        }

        try {
            switch (detectedFormat) {
                case "gpx":
                    result.segments = parseGpx(fileRead(arguments.filePath, "utf-8"), result.errors);
                    break;
                case "kml":
                    result.segments = parseKml(fileRead(arguments.filePath, "utf-8"), result.errors);
                    break;
                case "kmz":
                    result.segments = parseKml(readKmlFromKmz(arguments.filePath), result.errors);
                    break;
                case "geojson":
                    result.segments = parseGeoJson(fileRead(arguments.filePath, "utf-8"), result.errors);
                    break;
                case "fit":
                    result.segments = parseFit(fileReadBinary(arguments.filePath), result.errors);
                    break;
            }
        } catch (any parserError) {
            arrayAppend(result.errors, "Nao foi possivel interpretar o arquivo " & uCase(detectedFormat) & ": " & parserError.message);
            return result;
        }

        if (arrayLen(result.errors)) {
            return result;
        }

        result.format = detectedFormat;
        result.sha256 = lCase(hash(fileReadBinary(arguments.filePath), "SHA-256"));
        return finalizeAnalysis(result);
    }

    public void function writeGeoJson(required struct analysis, required string destination) {
        var segmentCoordinates = [];
        var geometryType = "LineString";
        var geometryCoordinates = [];

        for (var segment in arguments.analysis.segments) {
            var coordinates = [];
            for (var point in segment) {
                var coordinate = [point.lng, point.lat];
                if (point.hasElevation) {
                    arrayAppend(coordinate, point.elevation);
                }
                arrayAppend(coordinates, coordinate);
            }
            if (arrayLen(coordinates) >= 2) {
                arrayAppend(segmentCoordinates, coordinates);
            }
        }

        if (arrayLen(segmentCoordinates) EQ 1) {
            geometryCoordinates = segmentCoordinates[1];
        } else {
            geometryType = "MultiLineString";
            geometryCoordinates = segmentCoordinates;
        }

        var properties = {
            pointCount=arguments.analysis.pointCount,
            segmentCount=arguments.analysis.segmentCount,
            elevationPointCount=arguments.analysis.elevationPointCount,
            distanceM=arguments.analysis.distanceM,
            sourceFormat=arguments.analysis.format
        };
        var geojson = '{"type":"Feature","properties":' & serializeJSON(properties)
            & ',"geometry":{"type":"' & geometryType & '","coordinates":'
            & serializeJSON(geometryCoordinates) & '}}';
        fileWrite(arguments.destination, geojson, "utf-8");
    }

    public void function writeGpx(required struct analysis, required string destination, string routeName="Percurso") {
        var safeName = xmlFormat(len(trim(arguments.routeName)) ? trim(arguments.routeName) : "Percurso");
        fileWrite(
            arguments.destination,
            '<?xml version="1.0" encoding="UTF-8"?>' & chr(10)
            & '<gpx version="1.1" creator="Road Runners Business" xmlns="http://www.topografix.com/GPX/1/1">' & chr(10)
            & '  <trk><name>' & safeName & '</name>' & chr(10),
            "utf-8"
        );

        var outputBuffer = "";
        for (var segment in arguments.analysis.segments) {
            outputBuffer &= "    <trkseg>" & chr(10);
            for (var point in segment) {
                outputBuffer &= '      <trkpt lat="' & gpxNumber(point.lat, "0.0000000")
                    & '" lon="' & gpxNumber(point.lng, "0.0000000") & '">';
                if (point.hasElevation) {
                    outputBuffer &= "<ele>" & gpxNumber(point.elevation, "0.00") & "</ele>";
                }
                outputBuffer &= "</trkpt>" & chr(10);

                if (len(outputBuffer) >= 1048576) {
                    fileAppend(arguments.destination, outputBuffer, "utf-8");
                    outputBuffer = "";
                }
            }
            outputBuffer &= "    </trkseg>" & chr(10);
        }
        outputBuffer &= "  </trk>" & chr(10) & "</gpx>" & chr(10);
        fileAppend(arguments.destination, outputBuffer, "utf-8");
    }

    public void function writeGpxFromGeoJson(required string source, required string destination, string routeName="Percurso") {
        var result = newResult();
        result.format = "geojson";
        result.segments = parseGeoJson(fileRead(arguments.source, "utf-8"), result.errors);
        result = finalizeAnalysis(result);
        if (NOT result.valid) {
            throw(message=arrayLen(result.errors) ? arrayToList(result.errors, " ") : "GeoJSON normalizado invalido.");
        }
        writeGpx(result, arguments.destination, arguments.routeName);
    }

    private struct function newResult() {
        return {
            valid=false,
            errors=[],
            format="",
            segments=[],
            points=[],
            distanceM=0,
            elevationGainM=0,
            elevationLossM=0,
            elevationMin="",
            elevationMax="",
            elevationPointCount=0,
            minLat=90,
            minLng=180,
            maxLat=-90,
            maxLng=-180,
            pointCount=0,
            segmentCount=0,
            sha256=""
        };
    }

    private string function detectFormat(required string filePath) {
        var fileName = lCase(getFileFromPath(arguments.filePath));
        var extension = listLen(fileName, ".") GT 1 ? listLast(fileName, ".") : "";
        if (listFindNoCase("gpx,kml,kmz,geojson,json,fit", extension)) {
            return extension;
        }

        var bytes = fileReadBinary(arguments.filePath);
        if (binaryLength(bytes) >= 12
            AND unsignedByte(bytes, 8) EQ 46
            AND unsignedByte(bytes, 9) EQ 70
            AND unsignedByte(bytes, 10) EQ 73
            AND unsignedByte(bytes, 11) EQ 84) {
            return "fit";
        }
        if (binaryLength(bytes) >= 2 AND unsignedByte(bytes, 0) EQ 80 AND unsignedByte(bytes, 1) EQ 75) {
            return "kmz";
        }

        var prefix = fileRead(arguments.filePath, "utf-8");
        if (reFindNoCase("<gpx([[:space:]>])", prefix)) return "gpx";
        if (reFindNoCase("<(?:[[:alnum:]_]+:)?kml([[:space:]>])", prefix)) return "kml";
        if (reFind("^[[:space:]]*[\{\[]", prefix)) return "geojson";
        return "";
    }

    private array function parseGpx(required string content, required array errors) {
        var segments = [];
        if (containsUnsafeXml(arguments.content)) {
            arrayAppend(arguments.errors, "O GPX contem declaracoes XML nao permitidas.");
            return segments;
        }
        if (NOT reFindNoCase("<gpx([[:space:]>])", arguments.content)) {
            arrayAppend(arguments.errors, "O arquivo nao possui um documento GPX valido.");
            return segments;
        }

        var segmentBlocks = reMatchNoCase("(?s)<trkseg(?:[[:space:]][^>]*)?>.*?</trkseg>", arguments.content);
        for (var segmentBlock in segmentBlocks) {
            var segment = parseGpxPointBlocks(segmentBlock, "trkpt");
            if (arrayLen(segment) >= 2) arrayAppend(segments, segment);
        }

        if (NOT arrayLen(segments)) {
            var trackPoints = parseGpxPointBlocks(arguments.content, "trkpt");
            if (arrayLen(trackPoints) >= 2) arrayAppend(segments, trackPoints);
        }
        if (NOT arrayLen(segments)) {
            var routePoints = parseGpxPointBlocks(arguments.content, "rtept");
            if (arrayLen(routePoints) >= 2) arrayAppend(segments, routePoints);
        }
        return segments;
    }

    private array function parseGpxPointBlocks(required string content, required string tagName) {
        var points = [];
        var blocks = reMatchNoCase(
            "(?s)<" & arguments.tagName & "[[:space:]][^>]*>.*?</" & arguments.tagName & ">|<"
            & arguments.tagName & "[[:space:]][^>]*/>",
            arguments.content
        );
        for (var block in blocks) {
            var latMatch = reFindNoCase('lat[[:space:]]*=[[:space:]]*["''](-?[0-9]+(?:\.[0-9]+)?)["'']', block, 1, true);
            var lngMatch = reFindNoCase('lon[[:space:]]*=[[:space:]]*["''](-?[0-9]+(?:\.[0-9]+)?)["'']', block, 1, true);
            if (arrayLen(latMatch.pos) < 2 OR latMatch.pos[2] <= 0 OR arrayLen(lngMatch.pos) < 2 OR lngMatch.pos[2] <= 0) continue;
            var point = makePoint(
                val(mid(block, latMatch.pos[2], latMatch.len[2])),
                val(mid(block, lngMatch.pos[2], lngMatch.len[2]))
            );
            var elevationMatch = reFindNoCase("<ele>[[:space:]]*(-?[0-9]+(?:\.[0-9]+)?)[[:space:]]*</ele>", block, 1, true);
            if (arrayLen(elevationMatch.pos) >= 2 AND elevationMatch.pos[2] > 0) {
                point.elevation = val(mid(block, elevationMatch.pos[2], elevationMatch.len[2]));
                point.hasElevation = true;
            }
            arrayAppend(points, point);
        }
        return points;
    }

    private array function parseKml(required string content, required array errors) {
        var segments = [];
        if (containsUnsafeXml(arguments.content)) {
            arrayAppend(arguments.errors, "O KML contem declaracoes XML nao permitidas.");
            return segments;
        }
        if (NOT reFindNoCase("<(?:[[:alnum:]_]+:)?kml([[:space:]>])", arguments.content)) {
            arrayAppend(arguments.errors, "O arquivo nao possui um documento KML valido.");
            return segments;
        }

        var lineBlocks = reMatchNoCase("(?s)<(?:[[:alnum:]_]+:)?LineString(?:[[:space:]][^>]*)?>.*?</(?:[[:alnum:]_]+:)?LineString>", arguments.content);
        for (var lineBlock in lineBlocks) {
            var coordinatesMatch = reFindNoCase("(?s)<(?:[[:alnum:]_]+:)?coordinates(?:[[:space:]][^>]*)?>(.*?)</(?:[[:alnum:]_]+:)?coordinates>", lineBlock, 1, true);
            if (arrayLen(coordinatesMatch.pos) < 2 OR coordinatesMatch.pos[2] <= 0) continue;
            var rawCoordinates = mid(lineBlock, coordinatesMatch.pos[2], coordinatesMatch.len[2]);
            var lineSegment = [];
            for (var token in reMatch("[^[:space:]]+", rawCoordinates)) {
                var lineParts = listToArray(trim(token), ",", true);
                if (arrayLen(lineParts) < 2 OR NOT isNumeric(lineParts[1]) OR NOT isNumeric(lineParts[2])) continue;
                var linePoint = makePoint(val(lineParts[2]), val(lineParts[1]));
                if (arrayLen(lineParts) >= 3 AND isNumeric(lineParts[3])) {
                    linePoint.elevation = val(lineParts[3]);
                    linePoint.hasElevation = true;
                }
                arrayAppend(lineSegment, linePoint);
            }
            if (arrayLen(lineSegment) >= 2) arrayAppend(segments, lineSegment);
        }

        var trackBlocks = reMatchNoCase("(?s)<(?:[[:alnum:]_]+:)?Track(?:[[:space:]][^>]*)?>.*?</(?:[[:alnum:]_]+:)?Track>", arguments.content);
        for (var trackBlock in trackBlocks) {
            var trackSegment = [];
            var coordinateBlocks = reMatchNoCase("(?s)<(?:[[:alnum:]_]+:)?coord(?:[[:space:]][^>]*)?>.*?</(?:[[:alnum:]_]+:)?coord>", trackBlock);
            for (var coordinateBlock in coordinateBlocks) {
                var coordinateText = reReplace(coordinateBlock, "(?s)<[^>]+>", "", "all");
                var trackParts = reMatch("-?[0-9]+(?:\.[0-9]+)?", coordinateText);
                if (arrayLen(trackParts) < 2) continue;
                var trackPoint = makePoint(val(trackParts[2]), val(trackParts[1]));
                if (arrayLen(trackParts) >= 3) {
                    trackPoint.elevation = val(trackParts[3]);
                    trackPoint.hasElevation = true;
                }
                arrayAppend(trackSegment, trackPoint);
            }
            if (arrayLen(trackSegment) >= 2) arrayAppend(segments, trackSegment);
        }
        return segments;
    }

    private string function readKmlFromKmz(required string filePath) {
        var fileInput = 0;
        var zipInput = 0;
        var output = 0;
        try {
            fileInput = createObject("java", "java.io.FileInputStream").init(arguments.filePath);
            zipInput = createObject("java", "java.util.zip.ZipInputStream").init(fileInput);
            var entry = zipInput.getNextEntry();
            var entryCount = 0;
            while (NOT isNull(entry)) {
                entryCount++;
                if (entryCount > 1000) {
                    throw(message="O KMZ contem entradas demais.");
                }
                var entryName = lCase(entry.getName() & "");
                if (NOT entry.isDirectory() AND right(entryName, 4) EQ ".kml") {
                    output = createObject("java", "java.io.ByteArrayOutputStream").init();
                    var byteType = createObject("java", "java.lang.Byte").TYPE;
                    var buffer = createObject("java", "java.lang.reflect.Array").newInstance(byteType, 8192);
                    var totalRead = 0;
                    var readCount = zipInput.read(buffer);
                    while (readCount GT 0) {
                        totalRead += readCount;
                        if (totalRead > variables.maxArchiveBytes) {
                            throw(message="O KML descompactado excede o limite de 50 MB.");
                        }
                        output.write(buffer, 0, readCount);
                        readCount = zipInput.read(buffer);
                    }
                    return output.toString("UTF-8");
                }
                zipInput.closeEntry();
                entry = zipInput.getNextEntry();
            }
            throw(message="O KMZ nao contem um arquivo KML.");
        } finally {
            try { if (isObject(output)) output.close(); } catch (any ignoredOutput) {}
            try { if (isObject(zipInput)) zipInput.close(); } catch (any ignoredZip) {}
            try { if (isObject(fileInput)) fileInput.close(); } catch (any ignoredFile) {}
        }
    }

    private array function parseGeoJson(required string content, required array errors) {
        var segments = [];
        var document = {};
        try {
            document = deserializeJSON(arguments.content);
        } catch (any invalidJson) {
            arrayAppend(arguments.errors, "O GeoJSON nao possui JSON valido.");
            return segments;
        }
        collectGeoJsonSegments(document, segments);
        return segments;
    }

    private void function collectGeoJsonSegments(required any node, required array segments) {
        if (NOT isStruct(arguments.node) OR NOT structKeyExists(arguments.node, "type")) return;
        var nodeType = lCase(trim(arguments.node.type & ""));
        if (nodeType EQ "featurecollection" AND structKeyExists(arguments.node, "features") AND isArray(arguments.node.features)) {
            for (var feature in arguments.node.features) collectGeoJsonSegments(feature, arguments.segments);
            return;
        }
        if (nodeType EQ "feature" AND structKeyExists(arguments.node, "geometry")) {
            collectGeoJsonSegments(arguments.node.geometry, arguments.segments);
            return;
        }
        if (nodeType EQ "geometrycollection" AND structKeyExists(arguments.node, "geometries") AND isArray(arguments.node.geometries)) {
            for (var geometry in arguments.node.geometries) collectGeoJsonSegments(geometry, arguments.segments);
            return;
        }
        if (nodeType EQ "linestring" AND structKeyExists(arguments.node, "coordinates") AND isArray(arguments.node.coordinates)) {
            var lineSegment = geoJsonCoordinatesToPoints(arguments.node.coordinates);
            if (arrayLen(lineSegment) >= 2) arrayAppend(arguments.segments, lineSegment);
            return;
        }
        if (nodeType EQ "multilinestring" AND structKeyExists(arguments.node, "coordinates") AND isArray(arguments.node.coordinates)) {
            for (var coordinateSet in arguments.node.coordinates) {
                if (NOT isArray(coordinateSet)) continue;
                var multiLineSegment = geoJsonCoordinatesToPoints(coordinateSet);
                if (arrayLen(multiLineSegment) >= 2) arrayAppend(arguments.segments, multiLineSegment);
            }
        }
    }

    private array function geoJsonCoordinatesToPoints(required array coordinates) {
        var points = [];
        for (var coordinate in arguments.coordinates) {
            if (NOT isArray(coordinate) OR arrayLen(coordinate) < 2 OR NOT isNumeric(coordinate[1]) OR NOT isNumeric(coordinate[2])) continue;
            var point = makePoint(val(coordinate[2]), val(coordinate[1]));
            if (arrayLen(coordinate) >= 3 AND isNumeric(coordinate[3])) {
                point.elevation = val(coordinate[3]);
                point.hasElevation = true;
            }
            arrayAppend(points, point);
        }
        return points;
    }

    private array function parseFit(required binary data, required array errors) {
        var segments = [];
        var points = [];
        var dataLength = binaryLength(arguments.data);
        if (dataLength < 14) {
            arrayAppend(arguments.errors, "O arquivo FIT esta incompleto.");
            return segments;
        }
        var headerSize = unsignedByte(arguments.data, 0);
        if (headerSize < 12 OR headerSize > dataLength) {
            arrayAppend(arguments.errors, "O cabecalho FIT e invalido.");
            return segments;
        }
        if (unsignedByte(arguments.data, 8) NEQ 46 OR unsignedByte(arguments.data, 9) NEQ 70
            OR unsignedByte(arguments.data, 10) NEQ 73 OR unsignedByte(arguments.data, 11) NEQ 84) {
            arrayAppend(arguments.errors, "A assinatura do arquivo FIT e invalida.");
            return segments;
        }

        var fitDataSize = readUnsigned(arguments.data, 4, 4, false);
        var dataEnd = headerSize + fitDataSize;
        if (dataEnd > dataLength) {
            arrayAppend(arguments.errors, "O arquivo FIT foi truncado.");
            return segments;
        }

        var definitions = {};
        var position = headerSize;
        while (position < dataEnd) {
            var recordHeader = unsignedByte(arguments.data, position);
            position++;
            var isCompressed = bitAnd(recordHeader, 128) NEQ 0;
            var isDefinition = NOT isCompressed AND bitAnd(recordHeader, 64) NEQ 0;
            var localMessage = isCompressed ? bitAnd(bitSHRN(recordHeader, 5), 3) : bitAnd(recordHeader, 15);

            if (isDefinition) {
                if (position + 5 > dataEnd) break;
                position++;
                var architecture = unsignedByte(arguments.data, position);
                position++;
                var bigEndian = architecture EQ 1;
                var globalMessage = readUnsigned(arguments.data, position, 2, bigEndian);
                position += 2;
                var fieldCount = unsignedByte(arguments.data, position);
                position++;
                var messageDefinition = {globalMessage=globalMessage, bigEndian=bigEndian, fields=[]};
                for (var fieldIndex = 1; fieldIndex <= fieldCount; fieldIndex++) {
                    if (position + 3 > dataEnd) break;
                    arrayAppend(messageDefinition.fields, {
                        number=unsignedByte(arguments.data, position),
                        size=unsignedByte(arguments.data, position + 1),
                        baseType=unsignedByte(arguments.data, position + 2)
                    });
                    position += 3;
                }
                if (bitAnd(recordHeader, 32) NEQ 0) {
                    if (position >= dataEnd) break;
                    var developerFieldCount = unsignedByte(arguments.data, position);
                    position++;
                    for (var developerFieldIndex = 1; developerFieldIndex <= developerFieldCount; developerFieldIndex++) {
                        if (position + 3 > dataEnd) break;
                        arrayAppend(messageDefinition.fields, {
                            number=-1,
                            size=unsignedByte(arguments.data, position + 1),
                            baseType=13
                        });
                        position += 3;
                    }
                }
                definitions[toString(localMessage)] = messageDefinition;
                continue;
            }

            if (NOT structKeyExists(definitions, toString(localMessage))) {
                arrayAppend(arguments.errors, "O FIT referencia uma definicao de mensagem ausente.");
                return segments;
            }
            var dataDefinition = definitions[toString(localMessage)];
            var record = {};
            for (var field in dataDefinition.fields) {
                if (position + field.size > dataEnd) {
                    arrayAppend(arguments.errors, "O arquivo FIT terminou durante a leitura de um registro.");
                    return segments;
                }
                if (dataDefinition.globalMessage EQ 20 AND listFind("0,1,2,78,253", toString(field.number))) {
                    record[toString(field.number)] = readFitField(arguments.data, position, field.size, field.baseType, dataDefinition.bigEndian);
                }
                position += field.size;
            }

            if (dataDefinition.globalMessage EQ 20
                AND structKeyExists(record, "0") AND structKeyExists(record, "1")
                AND record["0"].valid AND record["1"].valid) {
                var latitude = record["0"].value * 180 / 2147483648;
                var longitude = record["1"].value * 180 / 2147483648;
                var point = makePoint(latitude, longitude);
                if (structKeyExists(record, "78") AND record["78"].valid) {
                    point.elevation = record["78"].value / 5 - 500;
                    point.hasElevation = true;
                } else if (structKeyExists(record, "2") AND record["2"].valid) {
                    point.elevation = record["2"].value / 5 - 500;
                    point.hasElevation = true;
                }
                if (structKeyExists(record, "253") AND record["253"].valid) {
                    point.timestamp = record["253"].value;
                }
                arrayAppend(points, point);
            }
        }
        if (arrayLen(points) >= 2) arrayAppend(segments, points);
        return segments;
    }

    private struct function readFitField(required binary data, required numeric offset, required numeric size, required numeric baseType, required boolean bigEndian) {
        var baseTypeId = bitAnd(arguments.baseType, 31);
        var result = {valid=false, value=0};
        if (arguments.size <= 0) return result;

        switch (baseTypeId) {
            case 1:
                result.value = signedValue(readUnsigned(arguments.data, arguments.offset, 1, false), 8);
                result.valid = result.value NEQ 127;
                break;
            case 2:
            case 10:
            case 13:
                result.value = readUnsigned(arguments.data, arguments.offset, 1, false);
                result.valid = result.value NEQ 255 AND (baseTypeId NEQ 10 OR result.value NEQ 0);
                break;
            case 3:
                result.value = signedValue(readUnsigned(arguments.data, arguments.offset, min(2, arguments.size), arguments.bigEndian), 16);
                result.valid = result.value NEQ 32767;
                break;
            case 4:
            case 11:
                result.value = readUnsigned(arguments.data, arguments.offset, min(2, arguments.size), arguments.bigEndian);
                result.valid = result.value NEQ 65535 AND (baseTypeId NEQ 11 OR result.value NEQ 0);
                break;
            case 5:
                result.value = signedValue(readUnsigned(arguments.data, arguments.offset, min(4, arguments.size), arguments.bigEndian), 32);
                result.valid = result.value NEQ 2147483647;
                break;
            case 6:
            case 12:
                result.value = readUnsigned(arguments.data, arguments.offset, min(4, arguments.size), arguments.bigEndian);
                result.valid = result.value NEQ 4294967295 AND (baseTypeId NEQ 12 OR result.value NEQ 0);
                break;
        }
        return result;
    }

    private struct function finalizeAnalysis(required struct result) {
        var validSegments = [];
        for (var segment in arguments.result.segments) {
            if (arrayLen(segment) < 2) continue;
            arrayAppend(validSegments, segment);
            var previous = {};
            var hasPrevious = false;
            for (var point in segment) {
                if (point.lat < -90 OR point.lat > 90 OR point.lng < -180 OR point.lng > 180) {
                    arrayAppend(arguments.result.errors, "O arquivo contem coordenadas fora dos limites geograficos.");
                    return arguments.result;
                }
                arguments.result.pointCount++;
                if (arguments.result.pointCount > variables.maxPoints) {
                    arrayAppend(arguments.result.errors, "O percurso excede o limite de 1 milhao de pontos.");
                    return arguments.result;
                }
                arrayAppend(arguments.result.points, point);
                arguments.result.minLat = min(arguments.result.minLat, point.lat);
                arguments.result.maxLat = max(arguments.result.maxLat, point.lat);
                arguments.result.minLng = min(arguments.result.minLng, point.lng);
                arguments.result.maxLng = max(arguments.result.maxLng, point.lng);

                if (point.hasElevation) {
                    arguments.result.elevationPointCount++;
                    if (NOT len(arguments.result.elevationMin & "")) {
                        arguments.result.elevationMin = point.elevation;
                        arguments.result.elevationMax = point.elevation;
                    } else {
                        arguments.result.elevationMin = min(arguments.result.elevationMin, point.elevation);
                        arguments.result.elevationMax = max(arguments.result.elevationMax, point.elevation);
                    }
                    if (hasPrevious AND previous.hasElevation) {
                        var elevationDelta = point.elevation - previous.elevation;
                        if (elevationDelta > 0) arguments.result.elevationGainM += elevationDelta;
                        if (elevationDelta < 0) arguments.result.elevationLossM += abs(elevationDelta);
                    }
                }
                if (hasPrevious) {
                    arguments.result.distanceM += haversine(previous.lat, previous.lng, point.lat, point.lng);
                }
                previous = point;
                hasPrevious = true;
            }
        }
        arguments.result.segments = validSegments;
        arguments.result.segmentCount = arrayLen(validSegments);
        if (arguments.result.pointCount < 2 OR NOT arguments.result.segmentCount) {
            arrayAppend(arguments.result.errors, "O arquivo precisa conter ao menos um trecho com dois pontos validos.");
            return arguments.result;
        }
        arguments.result.valid = true;
        return arguments.result;
    }

    private struct function makePoint(required numeric lat, required numeric lng) {
        return {lat=arguments.lat, lng=arguments.lng, hasElevation=false, elevation=0};
    }

    private string function gpxNumber(required numeric value, required string mask) {
        return replace(numberFormat(arguments.value, arguments.mask), ",", ".", "all");
    }

    private boolean function containsUnsafeXml(required string content) {
        return findNoCase("<!DOCTYPE", arguments.content) OR findNoCase("<!ENTITY", arguments.content);
    }

    private numeric function binaryLength(required binary data) {
        return createObject("java", "java.lang.reflect.Array").getLength(arguments.data);
    }

    private numeric function unsignedByte(required binary data, required numeric offset) {
        return bitAnd(
            createObject("java", "java.lang.reflect.Array").get(arguments.data, javacast("int", arguments.offset)),
            255
        );
    }

    private numeric function readUnsigned(required binary data, required numeric offset, required numeric size, required boolean bigEndian) {
        var value = 0;
        if (arguments.bigEndian) {
            for (var index = 0; index < arguments.size; index++) {
                value = value * 256 + unsignedByte(arguments.data, arguments.offset + index);
            }
        } else {
            for (var index = arguments.size - 1; index >= 0; index--) {
                value = value * 256 + unsignedByte(arguments.data, arguments.offset + index);
            }
        }
        return value;
    }

    private numeric function signedValue(required numeric value, required numeric bits) {
        var signBoundary = 2 ^ (arguments.bits - 1);
        var fullRange = 2 ^ arguments.bits;
        return arguments.value >= signBoundary ? arguments.value - fullRange : arguments.value;
    }

    private numeric function haversine(required numeric lat1, required numeric lng1, required numeric lat2, required numeric lng2) {
        var radius = 6371000;
        var dLat = (arguments.lat2 - arguments.lat1) * pi() / 180;
        var dLng = (arguments.lng2 - arguments.lng1) * pi() / 180;
        var a = sin(dLat / 2)^2 + cos(arguments.lat1 * pi() / 180) * cos(arguments.lat2 * pi() / 180) * sin(dLng / 2)^2;
        return radius * 2 * createObject("java", "java.lang.Math").atan2(sqr(a), sqr(1-a));
    }
}
