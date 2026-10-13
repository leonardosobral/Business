<cfscript>
// Partition tied groups in regulation order. Missing birth ranks last at the
// age criterion; unknown later criteria still keep the affected group unresolved.
function catarinenseBirthKey(required any value) {
    var raw=trim(arguments.value & ''); var parts=[]; var date=0; var canonical='';
    if(reFind('^[0-9]{4}-[0-9]{2}-[0-9]{2}$',raw)) { parts=listToArray(raw,'-'); canonical=raw; }
    else if(reFind('^[0-9]{2}/[0-9]{2}/[0-9]{4}$',raw)) { var brazilian=listToArray(raw,'/'); parts=[brazilian[3],brazilian[2],brazilian[1]]; canonical=parts[1] & '-' & parts[2] & '-' & parts[3]; }
    else return '';
    try {
        date=createDate(val(parts[1]),val(parts[2]),val(parts[3]));
        if(year(date)<1900 || dateCompare(date,now())>0 || dateFormat(date,'yyyy-mm-dd')!=canonical) return '';
        return canonical;
    } catch(any invalidDate) { return ''; }
}
function catarinenseDisplayOrder(required array rows) {
    arraySort(arguments.rows,function(a,b) {
        var comparison=compareNoCase(a.nome & '',b.nome & '');
        return comparison ? comparison : (a.id>b.id ? 1 : (a.id<b.id ? -1 : 0));
    });
    return arguments.rows;
}
function catarinenseCompareKey(required struct a,required struct b,required numeric level) {
    switch(arguments.level) {
        case 1: return a.distancia_percorrida>b.distancia_percorrida ? -1 : (a.distancia_percorrida<b.distancia_percorrida ? 1 : 0);
        case 2:
            if(!len(a.birthKey) || !len(b.birthKey)) return len(a.birthKey) ? -1 : (len(b.birthKey) ? 1 : 0);
            return compare(a.birthKey,b.birthKey);
        case 3: return compare(a.placementKey,b.placementKey);
        case 4: return a.lastKey>b.lastKey ? 1 : (a.lastKey<b.lastKey ? -1 : 0);
        case 5: return createObject('java','java.math.BigDecimal').init(a.meanKey).compareTo(createObject('java','java.math.BigDecimal').init(b.meanKey));
    }
    return 0;
}
function catarinenseMarkGroup(required array rows,required numeric first,required string criterion,string reason='') {
    var ordered=catarinenseDisplayOrder(arguments.rows);
    for(var row in ordered) {
        row.ranking_posicao=arguments.first;
        row.ranking_fim=arguments.first ? arguments.first+arrayLen(ordered)-1 : 0;
        row.ranking_criterio=arguments.criterion;
        row.ranking_motivo=arguments.reason;
    }
    return ordered;
}
function catarinenseCriterionMissing(required struct row,required numeric level) {
    return (arguments.level==3 && !arguments.row.placementsKnown)
        || (arguments.level==4 && !arguments.row.lastKnown)
        || (arguments.level==5 && !arguments.row.meanKnown);
}
function catarinensePendingGroup(required array rows,required numeric level,required numeric first,required string previous) {
    var known=[]; var missing=[];
    for(var row in arguments.rows) arrayAppend(catarinenseCriterionMissing(row,arguments.level) ? missing : known,row);
    // Resolve only relative order among valid peers. The entire group's official
    // interval stays reserved because an unknown peer could occupy any position.
    var ordered=arrayLen(known) ? catarinensePartition(known,arguments.level,arguments.first,arguments.previous) : [];
    var validMessages=['','','Colocações oficiais deste atleta completas.','Situação na 6ª etapa deste atleta conhecida.','Tempo e referência de categoria deste atleta completos.'];
    var missingMessages=['','','Colocações oficiais deste atleta incompletas nas etapas disputadas.','Colocação oficial da 6ª etapa deste atleta ausente.','Tempo ou referência do vencedor da categoria deste atleta ausente em uma etapa disputada.'];
    var fields=['','','colocações oficiais','colocação da 6ª etapa','tempo ou referência do vencedor da categoria'];
    for(var row in ordered) {
        var nested=row.ranking_criterio=='dados_pendentes' ? row.ranking_motivo : '';
        row.ranking_motivo=validMessages[arguments.level] & ' O desempate depende de ' & fields[arguments.level] & ' de ' & arrayLen(missing) & (arrayLen(missing)==1 ? ' outro atleta deste grupo.' : ' outros atletas deste grupo.');
        if(len(nested)) row.ranking_motivo&=' ' & nested;
        row.ranking_motivo&=' A ordem exibida é provisória.';
    }
    for(var row in catarinenseDisplayOrder(missing)) {
        row.ranking_motivo=missingMessages[arguments.level] & ' A posição deste grupo permanece provisória até completar os dados.';
        arrayAppend(ordered,row);
    }
    for(var row in ordered) {
        row.ranking_posicao=arguments.first;
        row.ranking_fim=arguments.first+arrayLen(ordered)-1;
        row.ranking_criterio='dados_pendentes';
    }
    return ordered;
}
function catarinensePartition(required array rows,required numeric level,required numeric first,string previous='pontos') {
    if(arrayLen(arguments.rows)==1) return catarinenseMarkGroup(arguments.rows,arguments.first,arguments.previous);
    if(arguments.level>5) return catarinenseMarkGroup(arguments.rows,arguments.first,'sorteio','Empate após todos os critérios. A organização deve realizar o sorteio oficial.');
    var labels=['pontos','idade','colocacoes','ultima_etapa','media_percentual'];
    for(var row in arguments.rows) {
        if(catarinenseCriterionMissing(row,arguments.level))
            return catarinensePendingGroup(arguments.rows,arguments.level,arguments.first,arguments.previous);
    }
    var keyLevel=arguments.level;
    arraySort(arguments.rows,function(a,b) { return catarinenseCompareKey(a,b,keyLevel); });
    var result=[]; var group=[]; var position=arguments.first; var groups=[];
    for(var row in arguments.rows) {
        if(arrayLen(group) && catarinenseCompareKey(group[1],row,keyLevel)!=0) { arrayAppend(groups,group); group=[]; }
        arrayAppend(group,row);
    }
    arrayAppend(groups,group);
    for(group in groups) {
        var resolved=catarinensePartition(group,keyLevel+1,position,arrayLen(groups)>1 ? labels[keyLevel] : arguments.previous);
        for(var item in resolved) arrayAppend(result,item);
        position+=arrayLen(group);
    }
    return result;
}
function catarinenseRank(required query source) {
    var genders={}; var columns=listToArray(arguments.source.columnList); var row={}; var index=0;
    for(index=1;index<=arguments.source.recordCount;index++) {
        row={sourceRow=index};
        for(var column in columns) row[column]=isNull(arguments.source[column][index]) ? '' : arguments.source[column][index];
        row.birthKey=catarinenseBirthKey(row.data_nascimento);
        row.placementsKnown=val(row.colocacoes_completas)==1; row.placementKey='';
        var places=[];
        try {
            places=deserializeJSON(row.colocacoes_json);
            if(!isArray(places) || arrayLen(places)>6) { places=[]; row.placementsKnown=false; }
            for(var place in places) if(!isNumeric(place) || place<=0 || place!=fix(place) || place>=9999999999) row.placementsKnown=false;
        } catch(any ignored) { places=[]; row.placementsKnown=false; }
        if(row.placementsKnown) {
            arraySort(places,'numeric');
            // Sorted placements padded with infinity are equivalent to comparing
            // counts of 1st, then 2nd, then every successive finishing position.
            for(var p=1;p<=6;p++) row.placementKey&=right('0000000000' & (p<=arrayLen(places) ? places[p] : 9999999999),10);
        }
        row.lastKnown=val(row.ultima_completa)==1;
        row.lastKey=val(row.ultima_colocacao)>0 ? val(row.ultima_colocacao) : 9999999999;
        row.meanKey=trim(row.media_percentual & '');
        row.meanKnown=val(row.desempenho_completo)==1 && reFind('^[0-9]+(\.[0-9]+)?$',row.meanKey)>0 && val(row.meanKey)>0;
        var gender=row.genero & '';
        if(!structKeyExists(genders,gender)) genders[gender]={ranked=[],unranked=[]};
        arrayAppend(val(row.nodesafio)>0 ? genders[gender].ranked : genders[gender].unranked,row);
    }
    for(var name in ['ranking_ordem','ranking_posicao','ranking_fim','ranking_criterio','ranking_motivo','ranking_nascimento'])
        if(!listFindNoCase(arguments.source.columnList,name)) queryAddColumn(arguments.source,name,listFind('ranking_criterio,ranking_motivo,ranking_nascimento',name) ? 'varchar' : 'integer',[]);
    for(var gender in genders) {
        var ordered=[];
        if(arrayLen(genders[gender].ranked)) ordered=catarinensePartition(genders[gender].ranked,1,1);
        var unranked=catarinenseMarkGroup(genders[gender].unranked,0,'sem_resultado','Nenhuma etapa concluída reconhecida.');
        for(row in unranked) arrayAppend(ordered,row);
        for(index=1;index<=arrayLen(ordered);index++) {
            row=ordered[index];
            if(row.ranking_posicao>0 && !len(row.birthKey)) {
                if(row.ranking_criterio=='idade') row.ranking_criterio='nascimento_ausente';
                row.ranking_motivo='Nascimento não informado ou inválido. Em empate de pontos, fica após os atletas com nascimento válido.' & (len(row.ranking_motivo) ? ' ' & row.ranking_motivo : '');
            }
            querySetCell(arguments.source,'ranking_ordem',index,row.sourceRow);
            querySetCell(arguments.source,'ranking_nascimento',row.birthKey,row.sourceRow);
            for(var name in ['ranking_posicao','ranking_fim','ranking_criterio','ranking_motivo']) querySetCell(arguments.source,name,row[name],row.sourceRow);
        }
    }
    return arguments.source;
}
function catarinenseCriterionLabel(required string criterion) {
    var labels={pontos='Pontuação',idade='Maior idade',nascimento_ausente='Sem nascimento válido',colocacoes='Melhores colocações',ultima_etapa='Colocação na 6ª etapa',media_percentual='Média percentual',dados_pendentes='Dados pendentes',sorteio='Sorteio oficial pendente',sem_resultado='Sem resultado'};
    return structKeyExists(labels,arguments.criterion) ? labels[arguments.criterion] : 'Ranking';
}
function catarinensePanelUrl(required string challenge,struct state={},struct changes={}) {
    if(!listFindNoCase('catarinensecorridaderua,catarinensetrailrun',arguments.challenge)) throw(type='Challenge.Validation',message='Circuito inválido.');
    var values=duplicate(arguments.state); structAppend(values,arguments.changes,true); var parameters=[];
    for(var key in ['aba','busca','genero','medalha','regiao','estado','cidade','periodo','preset','pagina','sucesso','challenge_refresh'])
        if(structKeyExists(values,key) && len(trim(values[key] & ''))) arrayAppend(parameters,key & '=' & urlEncodedFormat(values[key] & ''));
    return '/desafios/' & lCase(arguments.challenge) & '/' & (arrayLen(parameters) ? '?' & arrayToList(parameters,'&') : '');
}
</cfscript>
