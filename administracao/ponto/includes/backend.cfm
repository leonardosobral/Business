<cfprocessingdirective pageencoding="utf-8"/>
<cfscript>
function pontoParam(required any value, string type = "cf_sql_varchar") {
    return {value=arguments.value, cfsqltype=arguments.type};
}
function pontoForm(required string key, string fallback = "") {
    return structKeyExists(FORM, arguments.key) ? trim(FORM[arguments.key] & "") : arguments.fallback;
}
function pontoHoras(required numeric seconds) {
    var minutes = fix(max(0, arguments.seconds) / 60);
    return fix(minutes / 60) & "h " & numberFormat(minutes mod 60, "00") & "min";
}
function pontoData(required string value) {
    return reFind("^\d{4}-\d{2}-\d{2}$", arguments.value) AND isDate(arguments.value);
}
pontoUser = val(qPerfil.id);
pontoError = "";
pontoNotice = "";
if (!structKeyExists(SESSION, "businessPontoCsrf")) SESSION.businessPontoCsrf = generateSecretKey("AES");
pontoCsrf = SESSION.businessPontoCsrf;
if (structKeyExists(SESSION, "businessPontoNotice")) {
    pontoNotice = SESSION.businessPontoNotice;
    structDelete(SESSION, "businessPontoNotice");
}
qPontoClock = queryExecute("SELECT
    to_char(now() AT TIME ZONE 'America/Sao_Paulo', 'YYYY-MM-DD') hoje,
    to_char(now() AT TIME ZONE 'America/Sao_Paulo', 'YYYY-MM-DD""T""HH24:MI:SS') agora,
    to_char(date_trunc('week', now() AT TIME ZONE 'America/Sao_Paulo'), 'YYYY-MM-DD') semana_de,
    to_char(date_trunc('week', now() AT TIME ZONE 'America/Sao_Paulo') + interval '6 days', 'YYYY-MM-DD') semana_ate,
    to_char(date_trunc('month', now() AT TIME ZONE 'America/Sao_Paulo'), 'YYYY-MM-DD') mes_de,
    to_char(date_trunc('month', now() AT TIME ZONE 'America/Sao_Paulo') + interval '1 month - 1 day', 'YYYY-MM-DD') mes_ate");
pontoDe = structKeyExists(URL, "de") AND pontoData(URL.de) ? URL.de : qPontoClock.mes_de;
pontoAte = structKeyExists(URL, "ate") AND pontoData(URL.ate) ? URL.ate : qPontoClock.mes_ate;
if (dateCompare(pontoDe, pontoAte) GT 0 OR dateDiff("d", pontoDe, pontoAte) GT 366) {
    pontoDe = qPontoClock.mes_de;
    pontoAte = qPontoClock.mes_ate;
    pontoError = "Selecione um intervalo de até 367 dias, com o fim após o início.";
}
pontoPage = structKeyExists(URL, "pagina") AND isValid("integer", URL.pagina) ? max(1, min(100000, val(URL.pagina))) : 1;
pontoEditId = structKeyExists(URL, "editar") AND isValid("integer", URL.editar) ? max(0, val(URL.editar)) : 0;
pontoReturn = "./?de=" & pontoDe & "&ate=" & pontoAte & "&pagina=" & pontoPage;
qPontoSchema = queryExecute("SELECT to_regprocedure('public.ponto_registrar(integer,text,bigint,integer,jsonb)') IS NOT NULL
    AND to_regclass('public.vw_ponto_diario') IS NOT NULL AS ready");
pontoReady = qPontoSchema.ready;

if (structKeyExists(FORM, "acao")) {
    try {
        if (CGI.request_method NEQ "POST" OR compare(pontoForm("csrf"), pontoCsrf) NEQ 0)
            throw(type="Ponto.Validation", message="O formulário expirou. Recarregue a página e tente novamente.");
        if (!pontoReady) throw(type="Ponto.Validation", message="O controle de horas ainda não foi ativado.");
        pontoAction = pontoForm("acao");
        pontoId = pontoForm("id", "0");
        pontoVersion = pontoForm("versao", "0");
        if (!isValid("integer", pontoId) OR !isValid("integer", pontoVersion) OR val(pontoId) LT 0)
            throw(type="Ponto.Validation", message="Registro inválido. Recarregue a página.");
        pontoPayload = {};
        if (pontoAction EQ "salvar") {
            pontoPayload["periodos"] = [];
            pontoCount = val(pontoForm("quantidade"));
            if (pontoCount LT 1 OR pontoCount GT 50) throw(type="Ponto.Validation", message="Informe de 1 a 50 períodos.");
            for (pontoI = 1; pontoI LTE pontoCount; pontoI++) {
                arrayAppend(pontoPayload.periodos, {"inicio"=pontoForm("inicio_" & pontoI), "fim"=pontoForm("fim_" & pontoI)});
            }
        } else if (pontoAction EQ "viagem") {
            pontoDailyHours = pontoForm("horas", "8");
            if (!isNumeric(pontoDailyHours) OR val(pontoDailyHours) LTE 0 OR val(pontoDailyHours) GT 24)
                throw(type="Ponto.Validation", message="Informe as horas por dia, entre 0 e 24.");
            pontoPayload = {"de"=pontoForm("viagem_de"), "ate"=pontoForm("viagem_ate"), "minutos"=round(val(pontoDailyHours)*60), "fins_semana"=structKeyExists(FORM, "fins_semana")};
        }
        qPontoSaved = queryExecute("SELECT public.ponto_registrar(:usuario, :acao, :id, :versao, CAST(:dados AS jsonb)) id", {
            usuario=pontoParam(pontoUser, "cf_sql_integer"), acao=pontoParam(pontoAction),
            id=pontoParam(pontoId, "cf_sql_bigint"), versao=pontoParam(pontoVersion, "cf_sql_integer"), dados=pontoParam(serializeJSON(pontoPayload))
        });
        SESSION.businessPontoNotice = "Registro salvo. Seu histórico foi atualizado.";
        location(url=pontoReturn, addtoken=false);
    } catch (Ponto.Validation e) {
        pontoError = e.message;
    } catch (database e) {
        // Only deliberate business-rule errors are shown. SQL and driver details stay in logs.
        pontoError = "Não foi possível salvar. Confira as datas e tente novamente.";
        if (structKeyExists(e, "sqlState") AND e.sqlState EQ "P0001") {
            pontoMatch = reFind("ERROR: ([^\r\n]+)", e.message & chr(10) & e.detail, 1, true);
            if (arrayLen(pontoMatch.pos) GTE 2 AND pontoMatch.pos[2] GT 0)
                pontoError = mid(e.message & chr(10) & e.detail, pontoMatch.pos[2], pontoMatch.len[2]);
        }
        writeLog(file="business_ponto", type="error", text="Ponto user=" & pontoUser & ": " & e.message);
    }
}

if (pontoReady) {
    pontoParams = {usuario=pontoParam(pontoUser,"cf_sql_integer"), de=pontoParam(pontoDe), ate=pontoParam(pontoAte)};
    qPontoActive = queryExecute("SELECT j.id, j.estado, j.versao,
        to_char(min(p.inicio) AT TIME ZONE 'America/Sao_Paulo', 'DD/MM/YYYY HH24:MI') inicio,
        extract(epoch FROM (now() - min(p.inicio))) idade,
        COALESCE(sum(extract(epoch FROM (COALESCE(p.fim, now()) - p.inicio))), 0) segundos
        FROM public.tb_ponto_jornadas j JOIN public.tb_ponto_periodos p ON p.id_jornada = j.id
        WHERE j.id_usuario = :usuario AND j.estado IN ('ativo','pausado') GROUP BY j.id",
        {usuario=pontoParams.usuario});
    qPontoTotals = queryExecute("SELECT
        COALESCE(sum(segundos) FILTER (WHERE dia BETWEEN CAST(:de AS date) AND CAST(:ate AS date)),0) periodo,
        COALESCE(sum(segundos) FILTER (WHERE dia BETWEEN CAST(:de AS date) AND CAST(:ate AS date) AND tipo = 'viagem'),0) viagens,
        COALESCE(sum(segundos) FILTER (WHERE dia >= date_trunc('week', now() AT TIME ZONE 'America/Sao_Paulo')::date),0) semana,
        COALESCE(sum(segundos) FILTER (WHERE dia >= date_trunc('month', now() AT TIME ZONE 'America/Sao_Paulo')::date),0) mes
        FROM public.vw_ponto_diario WHERE id_usuario = :usuario
        AND dia <= (now() AT TIME ZONE 'America/Sao_Paulo')::date", pontoParams);
    qPontoDays = queryExecute("SELECT to_char(dia, 'DD/MM/YYYY') dia_label, to_char(dia, 'YYYY-MM-DD') dia,
        sum(segundos) segundos, sum(CASE WHEN tipo = 'viagem' THEN segundos ELSE 0 END) viagem,
        dia > (now() AT TIME ZONE 'America/Sao_Paulo')::date programado
        FROM public.vw_ponto_diario WHERE id_usuario = :usuario AND dia BETWEEN CAST(:de AS date) AND CAST(:ate AS date)
        GROUP BY dia ORDER BY dia DESC", pontoParams);
    // Filter sessions by any worked day, so overnight work appears in either month.
    pontoWhere = " FROM public.tb_ponto_jornadas j WHERE j.id_usuario = :usuario AND (
        j.dia_viagem BETWEEN CAST(:de AS date) AND CAST(:ate AS date) OR EXISTS (
            SELECT 1 FROM public.tb_ponto_periodos p WHERE p.id_jornada = j.id
            AND p.inicio < (CAST(:ate AS date)+1)::timestamp AT TIME ZONE 'America/Sao_Paulo'
            AND COALESCE(p.fim, now()) > CAST(:de AS date)::timestamp AT TIME ZONE 'America/Sao_Paulo'))";
    qPontoCount = queryExecute("SELECT count(*) total" & pontoWhere, pontoParams);
    pontoPages = max(1, ceiling(qPontoCount.total / 30));
    pontoPage = min(pontoPage, pontoPages);
    pontoListParams = duplicate(pontoParams);
    pontoListParams.offset = pontoParam((pontoPage-1)*30, "cf_sql_integer");
    qPontoHistory = queryExecute("SELECT j.id, j.tipo, j.estado, j.versao,
        to_char(j.dia_viagem, 'DD/MM/YYYY') viagem_dia, j.minutos_viagem,
        j.dia_viagem > (now() AT TIME ZONE 'America/Sao_Paulo')::date programado,
        to_char((SELECT min(inicio) FROM public.tb_ponto_periodos WHERE id_jornada = j.id) AT TIME ZONE 'America/Sao_Paulo', 'DD/MM/YYYY HH24:MI') inicio,
        COALESCE((SELECT sum(extract(epoch FROM (COALESCE(fim,now())-inicio))) FROM public.tb_ponto_periodos WHERE id_jornada=j.id), j.minutos_viagem*60, 0) segundos,
        EXISTS (SELECT 1 FROM public.tb_ponto_auditoria a WHERE a.id_jornada=j.id AND a.acao='salvar') ajustado"
        & pontoWhere & " ORDER BY COALESCE(j.dia_viagem::timestamp AT TIME ZONE 'America/Sao_Paulo',
            (SELECT min(inicio) FROM public.tb_ponto_periodos WHERE id_jornada=j.id)) DESC, j.id DESC LIMIT 30 OFFSET :offset", pontoListParams);
    qPontoEdit = queryExecute("SELECT id, versao, tipo, estado, to_char(dia_viagem,'DD/MM/YYYY') dia_viagem, minutos_viagem
        FROM public.tb_ponto_jornadas WHERE id=:id AND id_usuario=:usuario",
        {id=pontoParam(pontoEditId,"cf_sql_bigint"), usuario=pontoParams.usuario});
    qPontoPeriods = queryExecute("SELECT to_char(p.inicio AT TIME ZONE 'America/Sao_Paulo', 'YYYY-MM-DD""T""HH24:MI:SS') inicio,
        COALESCE(to_char(p.fim AT TIME ZONE 'America/Sao_Paulo', 'YYYY-MM-DD""T""HH24:MI:SS'),'') fim
        FROM public.tb_ponto_periodos p JOIN public.tb_ponto_jornadas j ON j.id=p.id_jornada
        WHERE j.id=:id AND j.id_usuario=:usuario ORDER BY p.inicio",
        {id=pontoParam(pontoEditId,"cf_sql_bigint"), usuario=pontoParams.usuario});
    qPontoAudit = queryExecute("SELECT a.acao, to_char(a.criado_em AT TIME ZONE 'America/Sao_Paulo','DD/MM/YYYY HH24:MI:SS') criado,
        CAST(a.antes AS text) antes, CAST(a.depois AS text) depois
        FROM public.tb_ponto_auditoria a JOIN public.tb_ponto_jornadas j ON j.id=a.id_jornada
        WHERE j.id=:id AND j.id_usuario=:usuario ORDER BY a.id DESC",
        {id=pontoParam(pontoEditId,"cf_sql_bigint"), usuario=pontoParams.usuario});
    // Keep the user's proposed times after validation errors; do not silently
    // replace them with the old database values or advance a stale version.
    if (len(pontoError) AND pontoForm("acao") EQ "salvar") {
        pontoRetryCount = min(50, max(1, int(val(pontoForm("quantidade", "1")))));
        qPontoPeriods = queryNew("inicio,fim", "varchar,varchar");
        for (pontoI = 1; pontoI LTE pontoRetryCount; pontoI++) {
            queryAddRow(qPontoPeriods, {inicio=pontoForm("inicio_" & pontoI), fim=pontoForm("fim_" & pontoI)});
        }
    }
}
</cfscript>
