component output="false" {
    variables.datasource = "runner_dba";

    public any function init(string datasource = "runner_dba") {
        variables.datasource = arguments.datasource;
        return this;
    }

    // IDs dos setores de entrada no banco compartilhado com o Road Runners.
    public string function sectorIds() {
        return "1,3";
    }

    // Usar somente em consultas internas com o setor atual no alias setr.
    public string function staffScope() {
        return "(setr.id_setor NOT IN (" & sectorIds() & ") OR setr.id_usuario_responsavel = :helpdesk_actor)";
    }

    public query function publicSectors() {
        return queryExecute("
            SELECT setr.id_setor, setr.nome_setor, coalesce(setr.descricao_setor, '') AS descricao_setor
            FROM tb_helpdesk_setores setr
            JOIN tb_usuarios resp ON resp.id = setr.id_usuario_responsavel AND resp.is_admin = true
            WHERE setr.ativo AND setr.id_setor IN (" & sectorIds() & ")
            ORDER BY setr.id_setor", {}, {datasource=variables.datasource});
    }

    // Chamado dentro da transação de atendimento. A troca de responsável
    // espera o término da operação que já bloqueou o setor para leitura.
    public query function lockTicket(required numeric ticketId, required numeric actorId) {
        return queryExecute("
            SELECT cham.id_chamado, cham.id_setor, cham.status,
                to_char(cham.updated_at, 'YYYY-MM-DD HH24:MI:SS.US') AS revision,
                (SELECT coalesce(max(m.id_mensagem),0) FROM tb_helpdesk_mensagens m
                 WHERE m.id_chamado = cham.id_chamado) AS last_message_id
            FROM tb_helpdesk_chamados cham
            JOIN tb_helpdesk_setores setr ON setr.id_setor = cham.id_setor
            WHERE cham.id_chamado = :ticket AND " & staffScope() & "
            FOR UPDATE OF cham FOR SHARE OF setr",
            {ticket={value=arguments.ticketId,cfsqltype="cf_sql_integer"},
             helpdesk_actor={value=arguments.actorId,cfsqltype="cf_sql_integer"}},
            {datasource=variables.datasource,timeout=10});
    }

    public query function lockDestination(required numeric sectorId, boolean publicOnly = false) {
        var sql = "
            SELECT setr.id_setor, coalesce(resp.id,0) AS responsible_id
            FROM tb_helpdesk_setores setr
            LEFT JOIN tb_usuarios resp ON resp.id = setr.id_usuario_responsavel AND resp.is_admin = true
            WHERE setr.id_setor = :sector";
        if (arguments.publicOnly) sql &= " AND setr.ativo AND setr.id_setor IN (" & sectorIds() & ")";
        return queryExecute(sql & " FOR SHARE OF setr",
            {sector={value=arguments.sectorId,cfsqltype="cf_sql_integer"}},
            {datasource=variables.datasource,timeout=10});
    }

    public struct function openTicket(required numeric userId, required numeric sectorId,
        required string subject, required string body, required boolean publicOnly) {
        var cleanSubject = trim(arguments.subject);
        var cleanBody = trim(arguments.body);
        if (!len(cleanSubject) || len(cleanSubject) > 180 || !len(cleanBody) || len(cleanBody) > 12000) {
            throw(type="HelpdeskTriage.Invalid", message="Informe um assunto de até 180 caracteres e uma mensagem de até 12.000 caracteres.");
        }
        var result = {};
        var opts = {datasource=variables.datasource,timeout=10};
        transaction {
            var sector = lockDestination(arguments.sectorId, arguments.publicOnly);
            if (!sector.recordCount || sector.responsible_id <= 0) {
                throw(type="HelpdeskTriage.SectorUnavailable", message="Selecione um setor disponível com responsável definido.");
            }
            var protocol = "HD-" & dateFormat(now(), "yyyymmdd") & "-" & right(replace(createUUID(), "-", "", "all"), 8);
            var author = {value=arguments.userId,cfsqltype="cf_sql_integer"};
            var ticket = queryExecute("
                INSERT INTO tb_helpdesk_chamados (protocolo,id_usuario,id_setor,assunto,status,created_at,updated_at)
                VALUES (:protocol,:author,:sector,:subject,'aberto',localtimestamp,localtimestamp)
                RETURNING id_chamado",
                {protocol={value=protocol,cfsqltype="cf_sql_varchar"},author=author,
                 sector={value=arguments.sectorId,cfsqltype="cf_sql_integer"},
                 subject={value=cleanSubject,cfsqltype="cf_sql_varchar"}}, opts);
            result.ticketId = ticket.id_chamado[1];
            queryExecute("
                INSERT INTO tb_helpdesk_mensagens (id_chamado,id_usuario,mensagem,interno,created_at)
                VALUES (:ticket,:author,:body,false,localtimestamp)",
                {ticket={value=result.ticketId,cfsqltype="cf_sql_integer"},author=author,
                 body={value=cleanBody,cfsqltype="cf_sql_longvarchar"}}, opts);
            result.notificationId = notifyResponsible(result.ticketId, sector.responsible_id[1]);
        }
        return result;
    }

    // Sem template compartilhado: cada chamado tem seu próprio aviso.
    public numeric function notifyResponsible(required numeric ticketId, required numeric responsibleId, boolean forwarded = false) {
        var notification = queryExecute("
            INSERT INTO tb_notifica (id_usuario,data_publicacao,data_expiracao,link,icone,conteudo_notifica)
            VALUES (:recipient,localtimestamp,localtimestamp+interval '999 days',:link,'fa-solid fa-headset',:content)
            RETURNING id_notifica",
            {recipient={value=arguments.responsibleId,cfsqltype="cf_sql_integer"},
             link={value="https://business.roadrunners.run/helpdesk/?ticket_id=" & arguments.ticketId,cfsqltype="cf_sql_varchar"},
             content={value=arguments.forwarded ? "Um chamado foi encaminhado para o seu setor." : "Há um novo chamado no seu setor.",cfsqltype="cf_sql_varchar"}},
            {datasource=variables.datasource,timeout=10});
        return notification.id_notifica[1];
    }

    // O aviso da central já está gravado. O push usa o ID existente.
    public void function sendPush(required numeric notificationId, required string secret) {
        if (arguments.notificationId <= 0 || !len(trim(arguments.secret))) return;
        var body = serializeJSON({"notificationIds"=[arguments.notificationId],"category"="atendimento","urgency"="high","ttlSeconds"=300});
        var timestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
        var signature = lCase(hmac(timestamp & "." & body, arguments.secret, "HmacSHA256"));
        try {
            cfhttp(url="https://roadrunners.run/api/push/send.cfm",method="post",result="local.pushResult",timeout=5,throwOnError=false) {
                cfhttpparam(type="header",name="Content-Type",value="application/json; charset=utf-8");
                cfhttpparam(type="header",name="X-RR-Handoff-Timestamp",value=timestamp);
                cfhttpparam(type="header",name="X-RR-Handoff-Signature",value=signature);
                cfhttpparam(type="body",value=body);
            }
        } catch (any unavailable) {
            writeLog(file="helpdesk-notifications",type="warning",text="Push do Help Desk indisponível. Aviso registrado na central.");
        }
    }
}
