component output=false {
    public string function readableText(required string value){return createObject("java","java.lang.String").init(value).replaceAll("[\x00-\x08\x0B\x0C\x0E-\x1F]"," ");}
    public string function text(required struct data,required string key,string fallback="") {
        return structKeyExists(data,key) AND !isNull(data[key]) AND isSimpleValue(data[key]) ? trim(data[key] & "") : fallback;
    }
    public string function normalize(required string value) {
        var form=createObject("java","java.text.Normalizer$Form").valueOf("NFD");
        var s=createObject("java","java.text.Normalizer").normalize(lCase(trim(value)),form);
        // CF's legacy regexp engine does not remove Unicode combining marks.
        s=createObject("java","java.lang.String").init(s).replaceAll("\p{M}+","");
        return trim(reReplace(s,"[^a-z0-9]+"," ","all"));
    }
    public struct function snapshot(required struct event) {
        var s={nulls=[]};var k="";
        for(k in listToArray("id_evento,cidade,estado,pais,cod_cidade,endereco,descricao_original,descricao,coordenadas,nome_evento,url_hotsite,url_inscricao")) {
            if((structKeyExists(event,"_sourceNulls") AND arrayFindNoCase(event._sourceNulls,k) GT 0) OR !structKeyExists(event,k) OR isNull(event[k])) arrayAppend(s.nulls,k);
            s[k]=structKeyExists(event,k) AND !isNull(event[k]) ? event[k] & "" : "";
        }
        // Catalog values aid validation but do not silently change event source values.
        s.catalog_city=text(event,"catalog_city");s.catalog_state=text(event,"catalog_state");s.start_date=text(event,"source_start_date");s.version=2;
        return s;
    }
    public array function sourceValues(required struct source) {
        var values=[];var k="";
        for(k in listToArray("id_evento,cidade,estado,pais,cod_cidade,endereco,descricao_original,descricao,coordenadas,nome_evento,url_hotsite,url_inscricao"))
            arrayAppend(values,[arrayFindNoCase(source.nulls,k) GT 0,source[k]]);
        arrayAppend(values,[text(source,"catalog_city"),text(source,"catalog_state")]);
        arrayAppend(values,[text(source,"start_date"),2]);
        return values;
    }
    public string function sourceHash(required struct source) {
        return lCase(hash(serializeJSON(sourceValues(source)),"SHA-256"));
    }
    public struct function coordinates(required string value) {
        var s=trim(value);var result={valid=false,empty=!len(s)};var parts=[];
        if(!reFind("^[-+]?[0-9]+(?:\.[0-9]+)?\s*,\s*[-+]?[0-9]+(?:\.[0-9]+)?$",s)) return result;
        parts=listToArray(s,",");result.lat=val(parts[1]);result.lon=val(parts[2]);
        result.valid=abs(result.lat) LTE 90 AND abs(result.lon) LTE 180 AND !(result.lat EQ 0 AND result.lon EQ 0);
        if(result.valid) result.value=numberFormat(result.lat,"0.0000000") & "," & numberFormat(result.lon,"0.0000000");
        return result;
    }
    public void function authorize(required boolean admin,required boolean delegated,required boolean post,required boolean csrf) {
        if(!admin OR delegated OR !post OR !csrf) throw(type="Geocoding.Denied",message="Ação não autorizada. Reabra a página como administrador global.");
    }
    public void function requireRevision(required struct proposal,required string revision) {
        if(!reFind("^[1-9][0-9]{0,17}$",revision) OR !structKeyExists(proposal,"proposal_revision") OR proposal.proposal_revision & "" NEQ revision)
            throw(type="Geocoding.Validation",message="Esta proposta mudou desde que a tela foi aberta. Reabra os detalhes antes de revisar.");
    }
    private string function plain(required string html) {
        var s=left(html,60000);
        s=reReplaceNoCase(s,"<(script|style)\b[^>]*>[\s\S]*?</\1>"," ","all");
        s=reReplaceNoCase(s,"</?(?:p|div|li|h[1-6]|br)\b[^>]*>",chr(10),"all");
        s=reReplace(s,"<[^>]*>"," ","all");
        s=replace(replace(replace(s,"&nbsp;"," ","all"),"&amp;","&","all"),"&" & chr(35) & "160;"," ","all");
        return s;
    }
    public array function queries(required struct source,struct research={}) {
        var places=[];var out=[];var addr=trim(source.endereco);var raw="";var line="";var place="";var key="";
        var uncertainty="\b(a definir|em breve|aguarde|aguardem|nao definido|a confirmar|nao confirmado|sujeito a alteracao)\b";
        var indef=reFind(uncertainty,normalize(addr)) GT 0;var uncertainSource=indef OR (structKeyExists(research,"diagnostics") AND isArray(research.diagnostics) AND arrayFind(research.diagnostics,"location_undefined") GT 0);
        var mismatch=len(text(source,"catalog_city")) AND (normalize(source.cidade) NEQ normalize(source.catalog_city) OR normalize(source.estado) NEQ normalize(source.catalog_state));
        if(len(addr) AND !indef) arrayAppend(places,{local=left(addr,240),source="endereco"});
        if(!indef) for(key in ["descricao_original","descricao"]) {
            raw=plain(source[key]);
            for(line in listToArray(raw,chr(10))) {
                if(reFindNoCase("^\s*(?:local da largada|local de largada|endereço da prova|endereco da prova|local da prova|concentra[çc][aã]o|largada)\s*[:\-]",line)) {
                    place=trim(reReplaceNoCase(line,"^\s*[^:\-]+[:\-]\s*",""));
                    if(reFind(uncertainty,normalize(place)))uncertainSource=true;
                    if(len(place) GTE 5 AND !reFind("\b(kit|kits|a definir|em breve)\b",normalize(place)) AND !reFind("^[0-9]{1,2}[:h]",place)) {
                        var found=false;for(var item in places) if(normalize(item.local) EQ normalize(place)) found=true;
                        if(!found) arrayAppend(places,{local=left(place,240),source=key});
                    }
                }
            }
        }
        for(var i=1;i LTE min(2,arrayLen(places));i++) {
            arrayAppend(out,{kind="specific",local=places[i].local,source=places[i].source,
                text=left(places[i].local & ", " & source.cidade & ", " & source.estado & ", " & source.pais,500),
                autoEligible=arrayLen(places) EQ 1 AND !mismatch AND !uncertainSource,reason=uncertainSource ? "location_undefined" : (mismatch ? "catalog_conflict" : (arrayLen(places) GT 1 ? "multiple_start_locations" : "specific_location"))});
        }
        if(!indef AND structKeyExists(research,"queries") AND isArray(research.queries)) {
            for(var external in research.queries) {
                if(!isStruct(external) OR !structKeyExists(external,"evidence"))continue;
                var replaced=false;
                for(var j=1;j LTE arrayLen(out);j++) {
                    var existing=out[j];
                    var samePlace=normalize(existing.local) EQ normalize(external.local)
                        OR (len(text(external,"street")) AND normalize(existing.local) EQ normalize(external.street))
                        OR (len(text(external,"street")) AND len(text(external,"housenumber")) AND normalize(existing.local) EQ normalize(external.street & " " & external.housenumber))
                        OR (len(text(existing,"street")) AND len(text(external,"street")) AND normalize(existing.street) EQ normalize(external.street) AND text(existing,"housenumber") EQ text(external,"housenumber"));
                    if(samePlace) {
                        if(len(text(existing,"street")) AND len(text(external,"street")) AND normalize(existing.street) NEQ normalize(external.street))continue;
                        // A new full address refines a street-only field; differing numbers are never refinements.
                        if(len(text(existing,"housenumber")) AND len(text(external,"housenumber")) AND text(existing,"housenumber") NEQ text(external,"housenumber"))continue;
                        if(!len(text(existing,"housenumber")) OR len(text(external,"housenumber")))out[j]=duplicate(external);
                        replaced=true;break;
                    }
                }
                if(!replaced AND arrayLen(out) LT 6)arrayAppend(out,duplicate(external));
            }
            for(var additional in out)if(mismatch OR uncertainSource OR arrayLen(out) GT 1) {
                additional.autoEligible=false;additional.reason=uncertainSource ? "location_undefined" : (mismatch ? "catalog_conflict" : "multiple_start_locations");
            }
        }
        // At most two specific geocodes, but every extracted place participates in conflict detection.
        if(arrayLen(out) GT 2)arrayResize(out,2);
        if(len(trim(source.cidade)) AND reFind("^[A-Za-z]{2}$",trim(source.pais)))
            arrayAppend(out,{kind="city",local=source.cidade,source="cidade",text=left(source.cidade & ", " & source.estado & ", " & source.pais,300),autoEligible=false,reason=indef ? "location_undefined" : "city_only"});
        return out;
    }
    private string function stateCode(required string value) {
        var s=normalize(reReplaceNoCase(value,"^BR[-_]",""));
        var states={acre="ac",alagoas="al",amapa="ap",amazonas="am",bahia="ba",ceara="ce",distrito_federal="df",espirito_santo="es",goias="go",maranhao="ma",mato_grosso="mt",mato_grosso_do_sul="ms",minas_gerais="mg",para="pa",paraiba="pb",parana="pr",pernambuco="pe",piaui="pi",rio_de_janeiro="rj",rio_grande_do_norte="rn",rio_grande_do_sul="rs",rondonia="ro",roraima="rr",santa_catarina="sc",sao_paulo="sp",sergipe="se",tocantins="to"};
        return structKeyExists(states,replace(s," ","_","all")) ? states[replace(s," ","_","all")] : s;
    }
    public boolean function sameRegion(required struct source,required struct candidate) {
        if(!len(trim(source.cidade)) OR normalize(text(candidate,"city")) NEQ normalize(source.cidade)) return false;
        var regions=new services.geocoding.RegionNames();var country=regions.country(source.pais);
        if(!len(country) OR regions.country(text(candidate,"country_code")) NEQ country) return false;
        if(country EQ "BR") return len(trim(source.estado)) AND stateCode(text(candidate,"state_code",text(candidate,"state"))) EQ stateCode(source.estado);
        // City + country alone cannot distinguish foreign homonyms.
        return len(trim(source.estado)) AND (normalize(text(candidate,"state_code")) EQ normalize(source.estado) OR normalize(text(candidate,"state")) EQ normalize(source.estado));
    }
    private numeric function confidence(required struct candidate,required string field) {
        return structKeyExists(candidate,"rank") AND isStruct(candidate.rank) AND structKeyExists(candidate.rank,field)
            AND !isNull(candidate.rank[field]) AND isNumeric(candidate.rank[field]) ? val(candidate.rank[field]) : -1;
    }
    public numeric function distance(required struct a,required struct b) {
        var rad=pi()/180;var dlat=(b.lat-a.lat)*rad;var dlon=(b.lon-a.lon)*rad;
        var h=sin(dlat/2)^2+cos(a.lat*rad)*cos(b.lat*rad)*sin(dlon/2)^2;
        return 6371000*2*createObject("java","java.lang.Math").atan2(sqr(max(0,h)),sqr(max(0,1-h)));
    }
    public boolean function specificCandidate(required struct source,required struct candidate) {
        return structKeyExists(candidate,"lat") AND structKeyExists(candidate,"lon") AND isNumeric(candidate.lat) AND isNumeric(candidate.lon)
            AND coordinates(candidate.lat & "," & candidate.lon).valid AND sameRegion(source,candidate) AND listFind("building,amenity",text(candidate,"result_type")) GT 0;
    }
    public struct function evaluate(required struct source,required struct query,required array results) {
        var decision={status="needs_review",reasons=[],candidate={},candidates=[]};var c={};var best={};var city={};var reason="low_confidence";var eligible=[];var number="";var match={};
        number=text(query,"housenumber");match=reFindNoCase("([0-9]+[a-z]?)\s*$",query.local,1,true);
        if(!len(number) AND arrayLen(match.pos) GTE 2 AND match.pos[2] GT 0) number=mid(query.local,match.pos[2],match.len[2]);
        for(c in results) {
            if(!isStruct(c) OR !structKeyExists(c,"lat") OR !structKeyExists(c,"lon") OR !isNumeric(c.lat) OR !isNumeric(c.lon) OR !coordinates(c.lat & "," & c.lon).valid) continue;
            arrayAppend(decision.candidates,duplicate(c));
            if(!sameRegion(source,c)) {reason="geographic_conflict";continue;}
            if(text(c,"result_type") EQ "city") {if(structIsEmpty(city)) city=duplicate(c);continue;}
            if(!listFind("building,amenity",text(c,"result_type"))) {reason="insufficient_precision";continue;}
            if(structIsEmpty(best) OR confidence(c,"confidence") GT confidence(best,"confidence")) best=duplicate(c);
            if(!query.autoEligible OR query.kind EQ "city") {reason=query.reason;continue;}
            if(confidence(c,"confidence") LT .95 OR confidence(c,"confidence_city_level") LT .95) continue;
            if(text(c,"result_type") EQ "building") {
                if(confidence(c,"confidence_building_level") LT .95 OR !len(number) OR normalize(text(c,"housenumber")) NEQ normalize(number)) {reason="building_not_confirmed";continue;}
                var wantedStreet=normalize(len(text(query,"street")) ? query.street : reReplaceNoCase(query.local,"[, ]*[0-9]+[a-z]?\s*$",""));
                wantedStreet=reReplace(wantedStreet,"^av ","avenida ");wantedStreet=reReplace(wantedStreet,"^r ","rua ");
                var actualStreet=normalize(text(c,"street"));actualStreet=reReplace(actualStreet,"^av ","avenida ");actualStreet=reReplace(actualStreet,"^r ","rua ");
                if(!len(actualStreet) OR wantedStreet NEQ actualStreet) {reason="street_conflict";continue;}
            } else {
                if(normalize(text(c,"name")) NEQ normalize(text(query,"venue",query.local))) {reason="venue_name_conflict";continue;}
                if(len(text(query,"housenumber")) AND (normalize(text(c,"housenumber")) NEQ normalize(query.housenumber) OR normalize(text(c,"street")) NEQ normalize(text(query,"street")))) {reason="building_not_confirmed";continue;}
            }
            arrayAppend(eligible,duplicate(c));
        }
        if(arrayLen(eligible)) {
            best=eligible[1];for(c in eligible) if(confidence(c,"confidence") GT confidence(best,"confidence")) best=c;
            for(c in decision.candidates) if(sameRegion(source,c) AND abs(confidence(c,"confidence")-confidence(best,"confidence")) LTE .05 AND distance(c,best) GT 100) {
                decision.candidate=best;decision.reasons=["ambiguous_candidates"];return decision;
            }
            decision.status="auto_applied";decision.candidate=best;decision.reasons=["specific_location_confirmed"];return decision;
        }
        if(!structIsEmpty(best)) decision.candidate=best;
        else if(!structIsEmpty(city)) {decision.status="city_suggestion";decision.candidate=city;reason="city_only";}
        else if(!arrayLen(results)) {decision.status="insufficient_data";reason="not_found";}
        decision.reasons=[reason];return decision;
    }
}
