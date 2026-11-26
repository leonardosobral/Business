component output=false {
    public any function init() {
        var gorunnersConfig = {};
        if (fileExists(expandPath("/config/gorunners.local.cfm"))) include "/config/gorunners.local.cfm";
        variables.cfg = gorunnersConfig;
        variables.ready = (variables.cfg.enabled ?: false)
            && reFind("^https://[a-z0-9-]+(\.[a-z0-9-]+)+$", variables.cfg.origin ?: "")
            && reFind("^grk_test_[A-Za-z0-9_-]+$", variables.cfg.apiKey ?: "")
            && len(variables.cfg.webhookSecret ?: "") && len(variables.cfg.pagarmeTestKey ?: "")
            && isArray(variables.cfg.pilotAccountIds ?: "");
        return this;
    }
    public boolean function enabled() { return variables.ready; }
    public boolean function allows(required numeric accountId) {
        return enabled() && arrayFind(variables.cfg.pilotAccountIds, arguments.accountId) GT 0;
    }
    public any function payments() {
        return createObject("component","ads.components.PagarMeClient").initZoneSandbox(variables.cfg.pagarmeTestKey);
    }
    public boolean function signed(required any raw, required string signature) {
        if (!enabled() || !reFind("^sha256=[0-9a-f]{64}$",arguments.signature)) return false;
        var bytes = isBinary(arguments.raw) ? arguments.raw : charsetDecode(arguments.raw,"UTF-8");
        var mac = createObject("java","javax.crypto.Mac").getInstance("HmacSHA256");
        mac.init(createObject("java","javax.crypto.spec.SecretKeySpec").init(charsetDecode(variables.cfg.webhookSecret,"UTF-8"),"HmacSHA256"));
        return createObject("java","java.security.MessageDigest").isEqual(mac.doFinal(bytes),binaryDecode(mid(arguments.signature,8,64),"hex"));
    }
    public struct function call(required string method, required string path, struct payload={}) {
        if (!enabled()) throw(type="Zones.Unavailable",message="Integração indisponível.");
        var result = {};
        cfhttp(url=variables.cfg.origin & "/api/commerce/v1" & arguments.path,method=arguments.method,
            timeout=8,redirect=false,throwonerror=false,result="local.result",charset="utf-8") {
            cfhttpparam(type="header",name="Authorization",value="Bearer " & variables.cfg.apiKey);
            cfhttpparam(type="header",name="Accept-Language",value="pt-BR");
            if (arguments.method == "POST") {
                cfhttpparam(type="header",name="Content-Type",value="application/json");
                cfhttpparam(type="body",value=serializeJSON(arguments.payload));
            }
        }
        var status = val(result.statusCode);
        var data = isJSON(result.fileContent) ? deserializeJSON(result.fileContent) : {};
        if (status >= 200 && status < 300 && isStruct(data) && !structIsEmpty(data)) return data;
        if (status == 409 && (data.error ?: "") == "quote_used" && val(data.order_id ?: 0) > 0)
            return call("GET","/orders/" & int(data.order_id));
        var messages = {
            "no_hexes":"Amplie um pouco a área selecionada.",
            "too_many_hexes":"Reduza a área para até 2.500 hexágonos.",
            "invalid_document":"Confira o CPF ou CNPJ do cliente.",
            "invalid_period":"Confira as datas da campanha.",
            "days_out_of_range":"O período deve atender aos limites da zona patrocinada.",
            "quote_expired":"A cotação venceu. Faça uma nova cotação.",
            "hold_expired":"A reserva venceu. Faça uma nova cotação.",
            "hold_conflict":"Outra campanha reservou essa área. Escolha outra área ou período.",
            "hexes_unavailable":"A área já está ocupada nesse período."
        };
        var code = isStruct(data) ? (data.error ?: "") : "";
        if (structKeyExists(messages,code)) throw(type="Zones.Input",message=messages[code]);
        throw(type="Zones.Unavailable",message="O GoRunners não confirmou a operação. Tente novamente.");
    }
}
