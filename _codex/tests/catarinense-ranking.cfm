<!--- Run through a private loopback runner. No production data or writes. --->
<cfif NOT structKeyExists(REQUEST,"catarinenseTestAuthorized") OR NOT REQUEST.catarinenseTestAuthorized><cfheader statuscode="404"/><cfabort/></cfif>
<cfscript>
checks=0; failures=[];
function check(required boolean condition,required string label) { checks++; if(!arguments.condition) arrayAppend(failures,arguments.label); }
function athlete(required numeric id,required string name,struct overrides={}) {
    var row={id=arguments.id,nome=arguments.name,genero='FEMININO',nodesafio=2,distancia_percorrida=100,data_nascimento='1980-01-01',colocacoes_json='[1,2]',colocacoes_completas=1,ultima_colocacao=0,ultima_completa=1,media_percentual='110',desempenho_completo=1};
    structAppend(row,arguments.overrides,true); return row;
}
function rank(required array rows) {
    var q=queryNew('id,nome,genero,nodesafio,distancia_percorrida,data_nascimento,colocacoes_json,colocacoes_completas,ultima_colocacao,ultima_completa,media_percentual,desempenho_completo','integer,varchar,varchar,integer,double,varchar,varchar,integer,integer,integer,varchar,integer',arguments.rows);
    if(structKeyExists(VARIABLES,'catarinenseRank')) return catarinenseRank(q);
    // Characterize the real pre-fix ORDER BY, instead of failing on a missing function.
    q=queryExecute('SELECT * FROM q ORDER BY genero, distancia_percorrida DESC, data_nascimento ASC, nome',{}, {dbtype='query'});
    queryAddColumn(q,'ranking_ordem','integer',[]); queryAddColumn(q,'ranking_posicao','integer',[]);
    queryAddColumn(q,'ranking_fim','integer',[]); queryAddColumn(q,'ranking_criterio','varchar',[]); queryAddColumn(q,'ranking_motivo','varchar',[]);
    for(var i=1;i<=q.recordCount;i++) { querySetCell(q,'ranking_ordem',i,i); querySetCell(q,'ranking_posicao',i,i); querySetCell(q,'ranking_fim',i,i); querySetCell(q,'ranking_criterio','nome',i); querySetCell(q,'ranking_motivo','',i); }
    return q;
}
function rowFor(required query q,required numeric id) { for(var i=1;i<=q.recordCount;i++) if(q.id[i]==arguments.id) { var r={}; for(var column in listToArray(q.columnList)) r[column]=isNull(q[column][i])?'':q[column][i]; return r; } throw(message='Missing fixture athlete'); }
function before(required query q,required numeric first,required numeric second) { return rowFor(q,arguments.first).ranking_ordem < rowFor(q,arguments.second).ranking_ordem; }
if(fileExists(expandPath(VARIABLES.catarinenseTestHelper))) include VARIABLES.catarinenseTestHelper;

q=rank([athlete(1,'Zelia',{distancia_percorrida=110}),athlete(2,'Ana',{distancia_percorrida=100,data_nascimento='1940-01-01'})]);
check(before(q,1,2),'points outrank every tie-break');
q=rank([athlete(1,'Zelia',{data_nascimento='1970-01-01',colocacoes_json='[8,9]'}),athlete(2,'Ana')]);
check(before(q,1,2),'older birth date outranks more wins');
check(rowFor(q,1).ranking_criterio=='idade','age tie-break is explained');
q=rank([athlete(1,'Zelia',{colocacoes_json='[1,1]'}),athlete(2,'Ana',{colocacoes_json='[1,2]'})]);
check(before(q,1,2),'more first places outrank alphabetical name');
check(rowFor(q,1).ranking_criterio=='colocacoes','placement tie-break is explained');
q=rank([athlete(1,'Zelia',{colocacoes_json='[1,2,3]'}),athlete(2,'Ana',{colocacoes_json='[1,2,5]'})]);
check(before(q,1,2),'third places resolve equal first and second counts');
q=rank([athlete(1,'Zelia',{colocacoes_json='[1,2,100]'}),athlete(2,'Ana',{colocacoes_json='[1,2]'})]);
check(before(q,1,2),'successive placement counts are not limited to the top ten');
q=rank([athlete(1,'Zelia',{ultima_colocacao=2}),athlete(2,'Ana',{ultima_colocacao=7})]);
check(before(q,1,2),'sixth stage placement resolves equal placement counts');
check(rowFor(q,1).ranking_criterio=='ultima_etapa','sixth-stage tie-break is explained');
q=rank([athlete(1,'Zelia',{ultima_colocacao=4}),athlete(2,'Ana',{ultima_colocacao=0})]);
check(before(q,1,2),'final-stage finisher outranks absence from final stage');
q=rank([athlete(1,'Zelia',{media_percentual='105'}),athlete(2,'Ana',{media_percentual='110'})]);
check(before(q,1,2),'lower mean time percentage is better');
check(rowFor(q,1).ranking_criterio=='media_percentual','mean performance tie-break is explained');
q=rank([athlete(1,'Zelia',{media_percentual='110.1234567890123456'}),athlete(2,'Ana',{media_percentual='110.1234567890123457'})]);
check(before(q,1,2),'decimal precision is not discarded before the mean tie-break');
q=rank([athlete(1,'Zelia'),athlete(2,'Ana')]);
check(rowFor(q,1).ranking_posicao==1 && rowFor(q,2).ranking_posicao==1,'equal athletes share an unresolved position');
check(rowFor(q,1).ranking_criterio=='sorteio' && rowFor(q,2).ranking_criterio=='sorteio','complete tie requires official draw, never alphabetical classification');
q=rank([athlete(1,'Zelia',{data_nascimento=''}),athlete(2,'Ana'),athlete(3,'Bia',{distancia_percorrida=90})]);
check(rowFor(q,2).ranking_posicao==1 && rowFor(q,1).ranking_posicao==2 && rowFor(q,2).ranking_criterio=='idade','missing birth follows valid birth without blocking the tied group');
check(rowFor(q,1).ranking_fim==2 && rowFor(q,3).ranking_posicao==3,'birth-last exception preserves individual positions and lower score groups');
q=rank([athlete(1,'Zelia',{colocacoes_completas=0,ultima_colocacao=1}),athlete(2,'Ana',{ultima_colocacao=2})]);
check(rowFor(q,1).ranking_criterio=='dados_pendentes' && findNoCase('coloca',rowFor(q,1).ranking_motivo),'unknown placements cannot be skipped in favor of later criteria');
q=rank([athlete(1,'Zelia',{ultima_completa=0}),athlete(2,'Ana')]);
check(rowFor(q,1).ranking_criterio=='dados_pendentes' && find('6',rowFor(q,1).ranking_motivo),'missing final-stage placement is different from nonparticipation');
q=rank([athlete(1,'Zelia',{desempenho_completo=0,media_percentual=''}),athlete(2,'Ana')]);
check(rowFor(q,1).ranking_criterio=='dados_pendentes','partial mean is not compared against a complete mean');
q=rank([athlete(1,'Zelia',{genero='FEMININO'}),athlete(2,'Ana',{genero='MASCULINO'})]);
check(rowFor(q,1).ranking_posicao==1 && rowFor(q,2).ranking_posicao==1,'each gender has an independent global position');
q=rank([athlete(1,'Zelia',{nodesafio=0,distancia_percorrida=0}),athlete(2,'Ana')]);
check(rowFor(q,1).ranking_posicao==0 && rowFor(q,1).ranking_criterio=='sem_resultado','athletes without completed stages are not ranked');
q=rank([athlete(1,'Zelia',{distancia_percorrida=120}),athlete(2,'Ana',{distancia_percorrida=110}),athlete(3,'Bia',{distancia_percorrida=100})]);
filtered=queryExecute('SELECT * FROM q WHERE id=3',{}, {dbtype='query'});
check(filtered.ranking_posicao[1]==3,'search/filter preserves the precomputed overall position');
check(q.recordCount==3 && q.distancia_percorrida[1]==120,'ranking does not change points or lose athletes');
q=rank([athlete(1,'Zelia',{data_nascimento='31/12/1960'}),athlete(2,'Ana',{data_nascimento='01/01/1970'})]);
check(before(q,1,2),'Brazilian birth dates are interpreted day/month/year, not by JVM locale');
q=rank([athlete(1,'Zelia',{data_nascimento='02/01/1980'}),athlete(2,'Ana',{data_nascimento='01/02/1980'})]);
check(before(q,1,2),'ambiguous Brazilian birth dates do not reverse older-first ordering');
if(structKeyExists(VARIABLES,'catarinensePanelUrl')) {
    link=catarinensePanelUrl('catarinensetrailrun',{aba='ranking',busca='Ana & Bia',estado='SC',pagina=4},{aba='medalhas',pagina=1});
    check(find('aba=medalhas',link) && find('estado=SC',link) && find('pagina=1',link),'tab navigation preserves filters and resets pagination intentionally');
    check(!find('Ana & Bia',link) && find('busca=',link),'filter values are URL encoded, not interpolated as query syntax');
    try { catarinensePanelUrl('https://evil.example/',{}); check(false,'panel links cannot escape the two circuit routes'); }
    catch(any invalidRoute) { check(true,'panel links cannot escape the two circuit routes'); }
} else check(false,'tab navigation must have a scoped filter-preserving URL builder');
q=rank([athlete(1,'Zelia',{data_nascimento='1980-02-31'}),athlete(2,'Ana')]);
check(rowFor(q,1).ranking_nascimento=='' && rowFor(q,1).ranking_posicao==2 && rowFor(q,2).ranking_posicao==1,'invalid calendar birth is ranked after valid birth instead of inventing an age');
// The approved birth-last rule resolves valid peers without a shared interval.
q=rank([athlete(1,'Ana sem nascimento',{data_nascimento=''}),athlete(2,'Zelia mais velha',{data_nascimento='1970-01-01'}),athlete(3,'Bia mais nova',{data_nascimento='1987-01-12'}),athlete(4,'Carla intermediaria'),athlete(5,'Outro grupo',{distancia_percorrida=90})]);
check(rowFor(q,3).ranking_nascimento=='1987-01-12','valid birth remains available when a peer has no birth date');
check(!len(rowFor(q,3).ranking_motivo) && rowFor(q,3).ranking_criterio=='idade','valid birth no longer receives a peer-dependency warning');
check(findNoCase('nascimento',rowFor(q,1).ranking_motivo)>0 && findNoCase('após',rowFor(q,1).ranking_motivo)>0,'missing birth explains classification after peers with valid birth');
check(before(q,2,4) && before(q,4,3),'known peers keep regulation older-first order');
check(before(q,3,1),'unknown birth follows age-ordered peers without inventing an age');
check(rowFor(q,2).ranking_posicao==1 && rowFor(q,4).ranking_posicao==2 && rowFor(q,3).ranking_posicao==3 && rowFor(q,1).ranking_posicao==4 && rowFor(q,3).ranking_fim==3,'birth-last rule resolves individual positions instead of reserving a shared provisional interval');
check(rowFor(q,5).ranking_posicao==5 && rowFor(q,5).ranking_criterio=='pontos','partial ordering cannot change a lower-score group');
q=rank([athlete(1,'Ana sem colocacoes',{colocacoes_completas=0}),athlete(2,'Zelia mais vitorias',{colocacoes_json='[1,1]'}),athlete(3,'Bia menos vitorias')]);
check(before(q,2,3) && before(q,3,1),'known placements order peers even when another athlete has incomplete placements');
check(findNoCase('outro atleta',rowFor(q,2).ranking_motivo)>0 && findNoCase('deste atleta',rowFor(q,1).ranking_motivo)>0,'placement warning distinguishes the affected athlete from peers');
check(rowFor(q,2).ranking_criterio=='dados_pendentes' && rowFor(q,2).ranking_fim==3,'partial placement ordering is not an official classification');
q=rank([athlete(1,'Ana sem ultima',{ultima_completa=0}),athlete(2,'Zelia melhor ultima',{ultima_colocacao=2}),athlete(3,'Bia pior ultima',{ultima_colocacao=7})]);
check(before(q,2,3) && before(q,3,1),'known final-stage placements order peers ahead of missing final-stage data');
check(findNoCase('outro atleta',rowFor(q,2).ranking_motivo)>0,'final-stage dependency is not falsely attributed to a valid peer');
q=rank([athlete(1,'Ana sem tempo',{desempenho_completo=0,media_percentual=''}),athlete(2,'Zelia melhor media',{media_percentual='105'}),athlete(3,'Bia pior media')]);
check(before(q,2,3) && before(q,3,1),'complete mean percentages order peers without comparing a missing mean as zero');
check(findNoCase('outro atleta',rowFor(q,2).ranking_motivo)>0,'performance warning identifies a peer dependency');
q=rank([athlete(1,'Ana sem nascimento',{data_nascimento=''}),athlete(2,'Zelia sem colocacoes',{colocacoes_completas=0}),athlete(3,'Bia com colocacoes')]);
check(!findNoCase('nascimento',rowFor(q,2).ranking_motivo) && findNoCase('coloca',rowFor(q,2).ranking_motivo)>0 && rowFor(q,2).ranking_fim==2 && rowFor(q,1).ranking_posicao==3,'incomplete placements reserve only the valid-birth subgroup and do not pull in missing-birth athletes');
q=rank([athlete(1,'Zelia',{data_nascimento=''}),athlete(2,'Ana',{data_nascimento=''})]);
check(rowFor(q,1).ranking_posicao==1 && rowFor(q,2).ranking_fim==2 && before(q,2,1) && rowFor(q,1).ranking_criterio=='sorteio','all-missing birth proceeds through later criteria and reaches official draw only if they all tie');
check(findNoCase('nascimento',rowFor(q,1).ranking_motivo)>0 && findNoCase('sorteio',rowFor(q,1).ranking_motivo)>0,'all-missing birth explains the policy without replacing the actual draw dependency');
q=rank([athlete(1,'Ana corrigida',{data_nascimento='1950-01-01'}),athlete(2,'Zelia',{data_nascimento='1970-01-01'}),athlete(3,'Bia',{data_nascimento='1987-01-12'})]);
check(rowFor(q,1).ranking_posicao==1 && rowFor(q,2).ranking_posicao==2 && rowFor(q,3).ranking_posicao==3,'completing the missing birth data restores individual official positions');
check(rowFor(q,1).ranking_criterio=='idade' && !len(rowFor(q,3).ranking_motivo),'resolved group no longer carries stale peer warnings');
q=rank([athlete(1,'Ana sem ultima',{ultima_completa=0}),athlete(2,'Zelia concluiu ultima',{ultima_colocacao=2}),athlete(3,'Bia nao concluiu ultima',{ultima_colocacao=0})]);
check(before(q,2,3) && before(q,3,1),'confirmed absence from E6 follows a finisher but remains distinct from missing E6 data');
check(!findNoCase('Colocação da 6ª etapa deste atleta conhecida.',rowFor(q,3).ranking_motivo),'confirmed noncompletion is not described as an actual known finishing place');
q=rank([athlete(1,'Sem nascimento mais pontos',{data_nascimento='',distancia_percorrida=110}),athlete(2,'Nascimento menos pontos')]);
check(rowFor(q,1).ranking_posicao==1 && before(q,1,2),'birth-last applies only in a point tie, never after every athlete in the circuit');
q=rank([athlete(1,'Zelia sem nascimento mais vitorias',{data_nascimento='',colocacoes_json='[1,1]'}),athlete(2,'Ana nascimento invalido',{data_nascimento='1980-02-31'}),athlete(3,'Bia nascimento valido',{colocacoes_json='[9,10]'})]);
check(rowFor(q,3).ranking_posicao==1 && rowFor(q,1).ranking_posicao==2 && rowFor(q,2).ranking_posicao==3,'valid birth outranks missing birth even when the missing athlete has better placements');
check(rowFor(q,1).ranking_criterio=='colocacoes' && before(q,1,2),'multiple missing births use later regulation criteria between themselves');
q=rank([athlete(1,'Sem nascimento masculino',{data_nascimento='',genero='MASCULINO'}),athlete(2,'Nascimento feminino')]);
check(rowFor(q,1).ranking_posicao==1 && rowFor(q,2).ranking_posicao==1,'birth-last cannot mix gender rankings');
q=rank([athlete(1,'Sem nascimento sem resultado',{data_nascimento='',nodesafio=0,distancia_percorrida=0}),athlete(2,'Nascimento com resultado')]);
check(rowFor(q,1).ranking_posicao==0 && rowFor(q,1).ranking_criterio=='sem_resultado','birth-last cannot rank an athlete without a completed stage');
cfcontent(type='application/json; charset=utf-8',reset=true);
writeOutput(serializeJSON({ok=!arrayLen(failures),checks=checks,failures=failures}));
</cfscript>
