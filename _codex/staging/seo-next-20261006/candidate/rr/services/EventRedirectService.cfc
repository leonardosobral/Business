component output="false" {
    // Event tags are exact database identifiers; localized route builders lowercase them.
    public string function canonicalUrlFor(required string localizedUrl, required string tag) {
        var encodedTag = replace(encodeForURL(arguments.tag), "+", "%20", "all");
        return reReplace(arguments.localizedUrl, "[^/]+/$", encodedTag & "/");
    }

    public boolean function isReadRequest(required string method, required struct params) {
        if (!listFindNoCase("GET,HEAD", arguments.method)) return false;
        for (var key in arguments.params) {
            if (!listFindNoCase("tag,i18n_lang,i18n_route,route_geometry", key)) return false;
        }
        return !structKeyExists(arguments.params, "route_geometry")
            || !len(trim(arguments.params.route_geometry & ""));
    }

    // Shared by resolution and sitemap discovery: invalid mappings never hide a page.
    public string function validTargetSql(required string sourceAlias) {
        if (!reFind("^[a-zA-Z_][a-zA-Z0-9_]*$", arguments.sourceAlias)) {
            throw(type="EventRedirect.InvalidAlias", message="Invalid trusted SQL alias");
        }
        var source = arguments.sourceAlias;
        return "EXISTS (
            SELECT 1 FROM tb_evento_corridas redirect_target
            WHERE redirect_target.tag = trim(" & source & ".tag_301)
              AND redirect_target.ativo = true
              AND redirect_target.id_evento <> " & source & ".id_evento
              AND redirect_target.tag ~ '^[a-z0-9][a-z0-9-]{1,255}$'
              AND nullif(trim(redirect_target.tag_301), '') IS NULL
              AND (SELECT count(*) FROM tb_evento_corridas target_match
                   WHERE target_match.tag = redirect_target.tag) = 1
        ) AND (SELECT count(*) FROM tb_evento_corridas source_match
               WHERE source_match.tag = " & source & ".tag) = 1";
    }

    public string function resolveTarget(required string tag) {
        // The Portuguese directory rewrite captures one trailing slash.
        var sourceTag = reReplace(arguments.tag, "/$", "");
        if (!len(sourceTag) || len(sourceTag) > 256 || find("/", sourceTag)) return "";
        var sql = "SELECT source_event.tag AS source_tag,
                   CASE WHEN " & validTargetSql("source_event") & "
                        THEN trim(source_event.tag_301) ELSE '' END AS target_tag
                   FROM tb_evento_corridas source_event";
        var params = {tag={value=sourceTag,cfsqltype="cf_sql_varchar"}};
        var match = queryExecute(sql & " WHERE source_event.tag = :tag", params, {timeout=10});
        if (match.recordCount) return match.recordCount == 1 ? match.target_tag[1] & "" : "";

        // Crawlers may normalize case. Redirect only a unique registered spelling.
        match = queryExecute(sql & " WHERE lower(source_event.tag) = lower(:tag) LIMIT 2", params, {timeout=10});
        if (match.recordCount != 1) return "";
        return len(match.target_tag[1] & "") ? match.target_tag[1] & "" : match.source_tag[1] & "";
    }

    public struct function rescheduleEvidenceFor(required string tag, required string startDate, required string endDate) {
        // TicketSports 87181 official notice, checked 2026-10-04: 2026-08-09 -> 2027-05-02.
        // A redirect alone does not prove postponement; keep this evidence bound to its dates.
        if (arguments.tag == "2027-4-corrida-do-turismo-abavse-2026"
            && arguments.startDate == "2027-05-02" && arguments.endDate == "2027-05-02") {
            return {eventStatus="https://schema.org/EventRescheduled",previousStartDate="2026-08-09"};
        }
        return {};
    }
}
