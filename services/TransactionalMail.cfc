component output=false {
    public boolean function configured() {
        return !structIsEmpty(loadAttributes());
    }

    public struct function attributes() {
        var smtp = loadAttributes();
        if (structIsEmpty(smtp)) {
            throw(type="TransactionalMail.Configuration", message="Transporte de e-mail transacional indisponível");
        }
        return smtp;
    }

    private struct function loadAttributes() {
        var config = {};
        try {
            config = deserializeJSON(fileRead("/etc/runnerhub/brevo-smtp.json", "utf-8"));
        } catch (any ignored) {
            return {};
        }

        if (!isStruct(config)) {
            return {};
        }
        for (var field in ["username", "password", "sender"]) {
            if (!structKeyExists(config, field) || !isSimpleValue(config[field])
                || !len(trim(config[field])) || reFind("[[:cntrl:]]", config[field])) {
                return {};
            }
        }
        var sender = trim(config.sender);
        if (!isValid("email", sender) || reFind("[<>]", sender)) {
            return {};
        }

        return {
            server="smtp-relay.brevo.com",
            port=587,
            useTLS=true,
            username=trim(config.username),
            password=config.password,
            from="Road Runners <" & sender & ">"
        };
    }
}
