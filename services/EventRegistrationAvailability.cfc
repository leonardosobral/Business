component output="false" {
    public boolean function isSourceUrl(required string value) {
        if (!len(arguments.value) OR len(arguments.value) GT 2048 OR reFind("[\x00-\x20\x7f]", arguments.value)) return false;
        try {
            var uri = createObject("java", "java.net.URI").init(arguments.value);
            return !isNull(uri.getScheme()) AND listFindNoCase("https,http", uri.getScheme()) GT 0
                AND !isNull(uri.getHost()) AND len(uri.getHost()) GT 0 AND isNull(uri.getRawUserInfo());
        } catch (any invalidUrl) { return false; }
    }

    public struct function evaluate(any metadata="", string registrationUrl="", string eventStatus="", any endDate="", numeric nowEpoch=0) {
        var result = {confirmed=false, status="unknown", availability="", source_url="", checked_at=0};
        var data = {};
        var clock = arguments.nowEpoch GT 0 ? arguments.nowEpoch : int(createObject("java", "java.lang.System").currentTimeMillis()/1000);
        var key = "";
        var mappings = {open="InStock", sold_out="SoldOut", preorder="PreOrder", closed=""};
        if (!isDate(arguments.endDate) OR dateCompare(arguments.endDate, now(), "d") LT 0
            OR lCase(trim(arguments.eventStatus)) EQ "cancelado") return result;
        try {
            data = isStruct(arguments.metadata) ? arguments.metadata : deserializeJSON(arguments.metadata);
        } catch (any invalidJson) { return result; }
        if (isNull(local.data) OR !isStruct(local.data)) return result;
        for (key in ["version", "status", "source_url", "registration_url", "checked_at"]) {
            if (!structKeyExists(data, key) OR !isSimpleValue(data[key])) return result;
        }
        if (!isNumeric(data.version) OR data.version NEQ 1 OR !structKeyExists(mappings, data.status)
            OR !isNumeric(data.checked_at) OR data.checked_at NEQ int(data.checked_at)
            OR data.checked_at GT clock OR clock-data.checked_at GTE 86400
            OR compare(trim(data.registration_url), trim(arguments.registrationUrl)) NEQ 0
            OR !isSourceUrl(trim(data.source_url)) OR !isSourceUrl(trim(arguments.registrationUrl))) return result;
        result.confirmed = true;
        result.status = lCase(data.status);
        result.source_url = trim(data.source_url);
        result.checked_at = data.checked_at;
        if (len(mappings[data.status])) result.availability = "https://schema.org/" & mappings[data.status];
        return result;
    }
}
