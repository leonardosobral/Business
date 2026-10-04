component output="false" {
    public boolean function isSchemaReady() {
        var q = queryExecute("SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='tb_evento_corridas' AND column_name='inscricao_disponibilidade' AND data_type='jsonb'");
        return q.recordCount GT 0;
    }

    public struct function validateSubmission(required struct submission, required boolean isAdmin, required boolean isPost, required boolean csrfVerified) {
        if (!arguments.isAdmin OR !arguments.isPost OR !arguments.csrfVerified) {
            throw(type="RegistrationAvailability.Forbidden", message="A confirmação exige uma sessão administrativa válida. Reabra a página e tente novamente.");
        }
        var data = arguments.submission;
        var status = structKeyExists(data, "status") AND isSimpleValue(data.status) ? lCase(trim(data.status)) : "";
        if (!listFind("open,sold_out,preorder,closed,unknown", status)) {
            throw(type="RegistrationAvailability.Validation", message="Escolha um status de inscrições válido.");
        }
        if (status EQ "unknown") return {status=status, source_url="", registration_url=""};
        var policy = new services.EventRegistrationAvailability();
        if (!structKeyExists(data, "confirmed") OR !isSimpleValue(data.confirmed) OR data.confirmed NEQ "1") {
            throw(type="RegistrationAvailability.Validation", message="Confirme que verificou o status na fonte oficial agora.");
        }
        var source = structKeyExists(data, "source_url") AND isSimpleValue(data.source_url) ? trim(data.source_url) : "";
        var registration = structKeyExists(data, "registration_url") AND isSimpleValue(data.registration_url) ? trim(data.registration_url) : "";
        if (!policy.isSourceUrl(source) OR !policy.isSourceUrl(registration)) {
            throw(type="RegistrationAvailability.Validation", message="Informe URLs completas e válidas (https:// ou http://) para a fonte e para a inscrição em Dados.");
        }
        return {status=status, source_url=source, registration_url=registration};
    }

    public void function save(required numeric eventId, required numeric actorId, required struct submission, required boolean isAdmin, required boolean isPost, required boolean csrfVerified, string remoteAddress="") {
        var data = validateSubmission(arguments.submission, arguments.isAdmin, arguments.isPost, arguments.csrfVerified);
        if (arguments.eventId LTE 0 OR arguments.eventId NEQ int(arguments.eventId) OR arguments.actorId LTE 0) {
            throw(type="RegistrationAvailability.Validation", message="Selecione um evento existente para confirmar as inscrições.");
        }
        var payload = "";
        var q = "";
        transaction {
            q = queryExecute("SELECT url_inscricao, status_evento, data_final FROM public.tb_evento_corridas WHERE id_evento=:id FOR UPDATE", {id={value=arguments.eventId, cfsqltype="cf_sql_integer"}});
            if (!q.recordCount) throw(type="RegistrationAvailability.Validation", message="Evento não encontrado.");
            if (data.status NEQ "unknown") {
                if (compare(data.registration_url, trim(q.url_inscricao & "")) NEQ 0) {
                    throw(type="RegistrationAvailability.Validation", message="O link de inscrição mudou. Reabra esta aba e verifique a fonte novamente.");
                }
                if (!isDate(q.data_final) OR dateCompare(q.data_final, now(), "d") LT 0 OR lCase(trim(q.status_evento & "")) EQ "cancelado") {
                    throw(type="RegistrationAvailability.Validation", message="Não confirme disponibilidade para um evento encerrado ou cancelado.");
                }
                payload = serializeJSON({version=1, status=data.status, source_url=data.source_url, registration_url=data.registration_url,
                    checked_at=int(createObject("java", "java.lang.System").currentTimeMillis()/1000)});
            }
            queryExecute("UPDATE public.tb_evento_corridas SET inscricao_disponibilidade=CAST(:payload AS jsonb) WHERE id_evento=:id", {
                payload={value=payload, null=!len(payload), cfsqltype="cf_sql_longvarchar"}, id={value=arguments.eventId, cfsqltype="cf_sql_integer"}
            });
            queryExecute("INSERT INTO public.tb_log (log_item, log_item_id, log_user, site) VALUES (:action, :item, :address, 'RH')", {
                action={value="confirmar_inscricao_disponibilidade", cfsqltype="cf_sql_varchar"},
                item={value=int(arguments.actorId) & "," & int(arguments.eventId) & "," & data.status, cfsqltype="cf_sql_varchar"},
                address={value=left(arguments.remoteAddress, 64), cfsqltype="cf_sql_varchar"}
            });
        }
    }
}
