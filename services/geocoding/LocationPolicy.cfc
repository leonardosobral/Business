component output=false {
    variables.p=new services.geocoding.Policy();variables.sources=new services.geocoding.Sources();variables.regions=new services.geocoding.RegionNames();
    private string function literal(required string value) {return reReplace(lCase(trim(value)),"\s+"," ","all");}
    private boolean function contains(required string haystack,required string needle) {return len(trim(needle)) AND find(literal(needle),literal(haystack)) GT 0;}
    private boolean function purposeBound(required string quote,required string role,required struct facts){
        var text=variables.regions.evidenceText(quote);var pattern="\b(?:largada e (?:retirada|entrega) (?:de |dos )?kits?|(?:retirada|entrega) (?:de |dos )?kits? e largada|largada|local da prova|local do evento|local da corrida|partida da prova|(?:retirada|entrega|distribuicao) (?:de |dos |do |de seus )?kits?|expo)\b";
        var marks=[];var offset=1;var m={};
        while(offset LTE len(text)){m=reFind(pattern,text,offset,true);if(!m.pos[1])break;arrayAppend(marks,{start=m.pos[1],label=mid(text,m.pos[1],m.len[1])});offset=m.pos[1]+m.len[1];}
        for(var i=1;i LTE arrayLen(marks);i++){
            var label=marks[i].label;var race=find("largada",label) OR find("local d",label) OR find("partida",label);var kit=find("kit",label) OR label EQ "expo";
            if((role EQ "evento" AND !race) OR (role EQ "kit" AND !kit))continue;
            var clause=mid(text,marks[i].start,(i LT arrayLen(marks) ? marks[i+1].start : len(text)+1)-marks[i].start);var valid=true;
            for(var key in ["name","address","city","state"])if(len(facts[key]) AND !find(variables.regions.evidenceText(facts[key]),clause))valid=false;
            if(valid)return true;
        }return false;
    }
    public boolean function identityVerified(required struct source,required array documents,required struct extracted){var n=val(variables.p.text(extracted,"identity_document"));return n GTE 1 AND n LTE arrayLen(documents) AND int(n) EQ n AND variables.p.text(extracted,"event_date") EQ variables.p.text(source,"start_date") AND contains(documents[n].text,variables.p.text(extracted,"identity_quote")) AND edition(source,variables.p.text(extracted,"identity_quote")) AND variables.sources.nameMatches(source.nome_evento,variables.p.text(extracted,"event_name"));}
    public boolean function raceFieldBound(required string quote,required string field,required string value){
        var s=quote;var pattern="\b(largada|local da prova|local do evento|local da corrida|retirada|entrega|inscri[çc][õo]es|organiza[çc][ãa]o|contato|expo|site)\b";var marks=[];var offset=1;
        while(offset LTE len(s)){var m=reFindNoCase(pattern,s,offset,true);if(!m.pos[1])break;arrayAppend(marks,{start=m.pos[1],label=lCase(mid(s,m.pos[1],m.len[1]))});offset=m.pos[1]+m.len[1];}
        for(var i=1;i LTE arrayLen(marks);i++)if(listFind("largada,local da prova,local do evento,local da corrida",marks[i].label)){
            var clause=mid(s,marks[i].start,(i LT arrayLen(marks) ? marks[i+1].start : len(s)+1)-marks[i].start);
            if(field EQ "pais" AND variables.regions.hasCountry(clause,value))return true;
            if(field EQ "estado" AND variables.regions.hasState(clause,value))return true;
            if(listFind("cidade,endereco",field) AND find(variables.p.normalize(value),variables.p.normalize(clause)))return true;
        }return false;
    }
    public struct function fieldEvidence(required struct source,required array documents,required struct extracted,required struct raw){
        var n=val(variables.p.text(raw,"document_index"));var quote=variables.p.text(raw,"quote");var out={trusted=false,reasons=[],evidence={}};
        if(!identityVerified(source,documents,extracted)){out.reasons=["edition_not_confirmed"];return out;}
        if(n LT 1 OR n GT arrayLen(documents) OR int(n) NEQ n OR len(quote) GT 2500 OR !contains(documents[n].text,quote)){out.reasons=["evidence_not_literal"];return out;}
        if(n NEQ val(extracted.identity_document) AND !edition(source,left(documents[n].text,20000))){out.reasons=["edition_not_confirmed"];return out;}
        for(var label in reMatch("\bedicao (?:de )?20[0-9]{2}\b",variables.p.normalize(documents[n].text)))if(right(label,4) NEQ left(source.start_date,4) AND !edition(source,quote)){out.reasons=["edition_not_confirmed"];return out;}
        // A dated historical event identity inside a fact cannot borrow the current page header.
        if(variables.sources.nameMatches(source.nome_evento,quote) AND !edition(source,quote)){
            for(var date in reMatch("\b(?:[0-9]{1,2}[/.-][0-9]{1,2}[/.-]20[0-9]{2}|20[0-9]{2}-[0-9]{2}-[0-9]{2})\b",quote)){
                var at=find(date,quote);var preceding=left(quote,at-1);
                if(variables.sources.nameMatches(source.nome_evento,preceding) AND !reFind("\b(inscric|lote|kit|expo|retirada|entrega)\w*\b",variables.p.normalize(preceding))){out.reasons=["edition_not_confirmed"];return out;}
            }
        }
        out.trusted=true;out.evidence={url=documents[n].url,sha256=variables.p.text(documents[n],"sha256"),excerpt=quote,event_date=source.start_date,method="openai_literal"};return out;
    }
    private boolean function edition(required struct source,required string quote) {
        var date=variables.p.text(source,"start_date");if(!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",date))return false;
        var months=["janeiro","fevereiro","marco","abril","maio","junho","julho","agosto","setembro","outubro","novembro","dezembro"];
        var y=left(date,4);var m=val(mid(date,6,2));var d=val(right(date,2));
        return variables.sources.nameMatches(source.nome_evento,quote) AND (find(date,quote) GT 0
            OR reFind("(^|[^0-9])0?" & d & "\s*[/.-]\s*0?" & m & "\s*[/.-]\s*" & y & "([^0-9]|$)",quote) GT 0
            OR reFind("\b0?" & d & " (?:de )?" & months[m] & " (?:de )?" & y & "\b",variables.p.normalize(quote)) GT 0);
    }
    private boolean function locationEdition(required struct source,required string document,required string quote){
        var year=left(source.start_date,4);var quoteText=variables.p.normalize(quote);var documentText=variables.p.normalize(document);
        // A current page header cannot authenticate a historical location section.
        // Mixed-edition documents need identity in the continuous location citation.
        for(var label in reMatch("\bedicao (?:de )?20[0-9]{2}\b",documentText))if(right(label,4) NEQ year){if(find(label,quoteText) OR !edition(source,quote))return false;}
        var dates=reMatch("\b(?:[0-9]{1,2}[/.-][0-9]{1,2}[/.-]20[0-9]{2}|20[0-9]{2}-[0-9]{2}-[0-9]{2})\b",quote);
        for(var value in dates){
            var pieces=listToArray(reReplace(value,"[/.]","-","all"),"-");
            try {var date=len(pieces[1]) EQ 4 ? createDate(pieces[1],pieces[2],pieces[3]) : createDate(pieces[3],pieces[2],pieces[1]);var eventDate=createDate(left(source.start_date,4),mid(source.start_date,6,2),right(source.start_date,2));if(abs(dateDiff("d",date,eventDate)) GT 30)return false;}catch(any invalidDate){return false;}
        }return true;
    }
    public struct function validate(required struct source,required array documents,required struct extracted) {
        var p=variables.p;var out={targets=[],diagnostics=[]};var n=val(p.text(extracted,"identity_document"));var quote=p.text(extracted,"identity_quote");
        if(n LT 1 OR n GT arrayLen(documents) OR int(n) NEQ n OR p.text(extracted,"event_date") NEQ p.text(source,"start_date")
            OR !contains(documents[n].text,quote) OR !edition(source,quote) OR !variables.sources.nameMatches(source.nome_evento,p.text(extracted,"event_name"))) {
            out.diagnostics=["edition_not_confirmed"];return out;
        }
        if(!structKeyExists(extracted,"locations") OR !isArray(extracted.locations) OR arrayLen(extracted.locations) GT 6){out.diagnostics=["invalid_locations"];return out;}
        for(var raw in extracted.locations) {
            if(!isStruct(raw) OR !listFind("evento,kit",p.text(raw,"role")))continue;
            var t={role=raw.role,trusted=true,reasons=[],facts={},context={},evidence={}};
            for(var k in ["name","address","city","state","country"])t.facts[k]=left(p.text(raw,k),k EQ "address" ? 300 : 180);
            n=val(p.text(raw,"document_index"));quote=left(p.text(raw,"quote"),2500);
            if(n LT 1 OR n GT arrayLen(documents) OR int(n) NEQ n OR !contains(documents[n].text,quote)) {t.trusted=false;arrayAppend(t.reasons,"evidence_not_literal");}
            else {
                t.evidence={url=documents[n].url,sha256=p.text(documents[n],"sha256"),excerpt=quote,event_date=source.start_date,method="openai_literal"};
                // Another document must independently confirm the edition, not just share a domain.
                if(n NEQ val(extracted.identity_document) AND !edition(source,left(documents[n].text,20000))){t.trusted=false;arrayAppend(t.reasons,"edition_not_confirmed");}
                if(!locationEdition(source,documents[n].text,quote)){t.trusted=false;arrayAppend(t.reasons,"location_edition_not_confirmed");}
                for(k in ["name","address","city","state"])if(len(t.facts[k]) AND !(k EQ "state" ? variables.regions.hasState(quote,t.facts[k]) : contains(quote,t.facts[k]))){t.trusted=false;arrayAppend(t.reasons,"fact_not_literal");}
            }
            var normalized=p.normalize(quote);var race=reFind("\b(largada|local da prova|local do evento|local da corrida|partida da prova)\b",normalized) GT 0;
            var kit=reFind("\b(retirada|entrega|distribuicao) (?:de |dos |do |de seus )?kits?\b|\bexpo\b",normalized) GT 0;
            if((raw.role EQ "evento" AND !race) OR (raw.role EQ "kit" AND !kit)){t.trusted=false;arrayAppend(t.reasons,"purpose_not_confirmed");}
            if(!purposeBound(quote,raw.role,t.facts)){t.trusted=false;arrayAppend(t.reasons,"purpose_address_mismatch");}
            if(p.text(raw,"certainty") NEQ "confirmed" OR reFind("\b(a definir|a confirmar|em breve|nao definido|sujeito a alteracao|local provisorio)\b",normalized)) {t.trusted=false;arrayAppend(t.reasons,"location_undefined");}
            t.facts.state=variables.regions.state(t.facts.state);t.facts.country=variables.regions.country(t.facts.country);
            if(!len(t.facts.country) AND variables.regions.country(source.pais) EQ "BR" AND listFindNoCase("AC,AL,AP,AM,BA,CE,DF,ES,GO,MA,MT,MS,MG,PA,PB,PR,PE,PI,RJ,RN,RS,RO,RR,SC,SP,SE,TO",t.facts.state) AND variables.regions.hasState(quote,t.facts.state))t.facts.country="BR";
            if(t.facts.country NEQ "BR" AND !variables.regions.hasCountry(quote,t.facts.country)){t.trusted=false;arrayAppend(t.reasons,"country_not_literal");}
            if(!len(t.facts.city) OR !len(t.facts.state) OR !reFind("^[A-Za-z]{2}$",t.facts.country) OR (!len(t.facts.name) AND !len(t.facts.address))) {t.trusted=false;arrayAppend(t.reasons,"incomplete_location");}
            t.context={cidade=t.facts.city,estado=t.facts.state,pais=uCase(t.facts.country)};
            if(raw.role EQ "evento" AND (p.normalize(source.cidade) NEQ p.normalize(t.facts.city) OR variables.regions.state(source.estado) NEQ t.facts.state OR variables.regions.country(source.pais) NEQ t.facts.country)) {t.trusted=false;arrayAppend(t.reasons,"geographic_conflict");}
            if(raw.role EQ "evento" AND len(p.text(source,"catalog_city")) AND (p.normalize(source.cidade) NEQ p.normalize(source.catalog_city) OR variables.regions.state(source.estado) NEQ variables.regions.state(p.text(source,"catalog_state")))){t.trusted=false;arrayAppend(t.reasons,"catalog_conflict");}
            var street=t.facts.address;var number="";var match=reFindNoCase("^(.+?)[,\s]+([0-9]+[a-z]?)\s*$",street,1,true);
            if(arrayLen(match.pos) GTE 3 AND match.pos[3] GT 0){street=trim(mid(t.facts.address,match.pos[2],match.len[2]));number=mid(t.facts.address,match.pos[3],match.len[3]);}
            t.query={kind="specific",local=len(t.facts.address) ? t.facts.address : t.facts.name,venue=t.facts.name,street=street,housenumber=number,source="openai_official_source",country=t.context.pais,
                text=left(t.facts.name & ", " & t.facts.address & ", " & t.context.cidade & ", " & t.context.estado & ", " & t.context.pais,500),autoEligible=t.trusted,reason=t.trusted ? "specific_location" : "evidence_unconfirmed"};
            arrayAppend(out.targets,t);
        }
        // Several distinct race venues or kit alternatives are not silently collapsed.
        for(var a=1;a LTE arrayLen(out.targets);a++)for(var b=a+1;b LTE arrayLen(out.targets);b++)if(out.targets[a].role EQ out.targets[b].role) {
            if(p.normalize(out.targets[a].query.text) EQ p.normalize(out.targets[b].query.text)){arrayDeleteAt(out.targets,b);b--;}
            else {out.targets[a].trusted=false;out.targets[b].trusted=false;out.targets[a].query.autoEligible=false;out.targets[b].query.autoEligible=false;arrayAppend(out.targets[a].reasons,"multiple_locations");arrayAppend(out.targets[b].reasons,"multiple_locations");}
        }
        return out;
    }
}
