<cfprocessingdirective pageencoding="utf-8" />
<cfscript>
function agregaReviewReplace(value, pattern, replacement) {
    return createObject("java", "java.util.regex.Pattern").compile(arguments.pattern).matcher(toString(arguments.value)).replaceAll(arguments.replacement).toString();
}

function agregaReviewPlainText(value) {
    var text = createObject("java", "java.text.Normalizer").normalize(toString(value), createObject("java", "java.text.Normalizer$Form").NFD);
    text = agregaReviewReplace(text, "\p{M}+", "");
    text = agregaReviewReplace(lCase(text), "[^a-z0-9]+", " ");
    return trim(agregaReviewReplace(text, "\s+", " "));
}

function agregaReviewStripEdition(value) {
    var text = agregaReviewReplace(value, "(?iu)\b\d+\s*[ªº°]\s*edi[çc][ãa]o\b", " ");
    // Etapa is an identity, not an annual edition number.
    return agregaReviewReplace(text, "(?iu)^\s*\d+\s*[ªº°](?!\s*etapa\b)\s*", "");
}

function agregaReviewNormalizeText(value, firstYear=0, secondYear=0) {
    var years = arguments.firstYear GT 0 AND arguments.secondYear GT 0
        ? "\b(?:" & int(arguments.firstYear) & "|" & int(arguments.secondYear) & ")\b"
        : "\b(?:19|20)[0-9]{2}\b";
    return agregaReviewPlainText(agregaReviewStripEdition(agregaReviewReplace(value, years, " ")));
}

function agregaReviewEditionOrdinal(value) {
    var pattern = createObject("java", "java.util.regex.Pattern");
    var match = pattern.compile("(?iu)\b(\d+)\s*[ªº°]\s*edi[çc][ãa]o\b").matcher(toString(value));
    if (match.find()) { return val(match.group(1)); }
    match = pattern.compile("(?iu)^\s*(\d+)\s*[ªº°](?!\s*etapa\b)").matcher(toString(value));
    return match.find() ? val(match.group(1)) : 0;
}

function agregaReviewMatchEditions(events, firstYear, secondYear) {
    var result = {groups={}, pairs=[], scanned=events.recordCount, ambiguous=0, incompatible=0, alreadyLinked=0};
    var buckets = {};
    var row = 0;
    var e = {};
    var key = "";
    var bucket = {};
    var leftEvent = {};
    var rightEvent = {};
    var leftOrdinal = 0;
    var rightOrdinal = 0;
    var shiftedDate = "";
    var groupId = "";
    for (row=1; row LTE events.recordCount; row++) {
        e = {
            idEvento=events.id_evento[row], nomeEvento=events.nome_evento[row],
            cidade=events.cidade[row], estado=events.estado[row], tag=events.tag[row],
            dataInicial=events.data_inicial[row], dataComparacao=events.data_comparacao[row],
            idAgregaEvento=val(events.id_agrega_evento[row]), tipoAgregacao=events.tipo_agregacao[row],
            ativo=events.ativo[row], tipoCorrida=agregaReviewPlainText(events.tipo_corrida[row]),
            pais=agregaReviewPlainText(events.pais[row]),
            normalizedName=agregaReviewNormalizeText(events.nome_evento[row], firstYear, secondYear),
            normalizedCity=agregaReviewPlainText(events.cidade[row]), normalizedUf=agregaReviewPlainText(events.estado[row])
        };
        if (!isDate(e.dataComparacao) OR !len(e.normalizedCity) OR !len(e.normalizedUf)
            OR !len(e.tipoCorrida) OR !len(e.pais) OR len(e.normalizedName) LT 15 OR listLen(e.normalizedName, " ") LT 3) { continue; }
        if (year(e.dataComparacao) NEQ firstYear AND year(e.dataComparacao) NEQ secondYear) { continue; }
        key = e.normalizedName & "|" & e.normalizedCity & "|" & e.normalizedUf & "|" & e.pais & "|" & e.tipoCorrida;
        if (!structKeyExists(buckets, key)) { buckets[key] = {older=[], newer=[]}; }
        if (year(e.dataComparacao) EQ firstYear) { arrayAppend(buckets[key].older, e); }
        else { arrayAppend(buckets[key].newer, e); }
    }
    for (key in buckets) {
        bucket = buckets[key];
        if (!arrayLen(bucket.older) OR !arrayLen(bucket.newer)) { continue; }
        // Include inactive rows when testing uniqueness: filtering them first can hide a second edition.
        if (arrayLen(bucket.older) NEQ 1 OR arrayLen(bucket.newer) NEQ 1) { result.ambiguous++; continue; }
        leftEvent = bucket.older[1]; rightEvent = bucket.newer[1];
        if (!leftEvent.ativo OR !rightEvent.ativo) { continue; }
        if (leftEvent.tipoAgregacao EQ "circuito" OR rightEvent.tipoAgregacao EQ "circuito") { result.incompatible++; continue; }
        leftOrdinal = agregaReviewEditionOrdinal(leftEvent.nomeEvento);
        rightOrdinal = agregaReviewEditionOrdinal(rightEvent.nomeEvento);
        shiftedDate = dateAdd("yyyy", firstYear-secondYear, rightEvent.dataComparacao);
        if (abs(dateDiff("d", leftEvent.dataComparacao, shiftedDate)) GT 90
            OR (leftOrdinal GT 0 AND rightOrdinal GT 0 AND rightOrdinal NEQ leftOrdinal+1)) { result.incompatible++; continue; }
        if (leftEvent.idAgregaEvento GT 0 AND leftEvent.idAgregaEvento EQ rightEvent.idAgregaEvento) { result.alreadyLinked++; continue; }
        // A pair key is independent of display spelling and never merges a transitive chain of similar names.
        groupId = "edicoes-v1:" & leftEvent.idEvento & ":" & rightEvent.idEvento;
        result.groups[groupId] = [leftEvent, rightEvent];
        arrayAppend(result.pairs, {leftId=leftEvent.idEvento, rightId=rightEvent.idEvento, score=100, nameScore=100, cityScore=100});
    }
    return result;
}
</cfscript>
