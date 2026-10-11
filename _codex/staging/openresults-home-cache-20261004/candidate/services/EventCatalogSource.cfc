<cfcomponent output="false">
<cffunction name="fetch" access="public" returntype="struct" output="false">
<cfset var qEventosBase=queryNew("id_evento")/><cfset var queryResult={}/><cfset var qTotalResultados=queryNew("total")/>
<cfquery name="qEventosBase" timeout="10" result="queryResult">
    SELECT
        evt.id_evento, evt.nome_evento, evt.cidade, evt.estado, evt.pais, evt.categorias, evt.coordenadas,
        evt.data_inicial, evt.data_final, evt.tag, evt.destaque, evt.tipo_corrida,
        evt.url_inscricao, evt.url_resultado, evt.obs_resultado,
        DATE_PART('week', evt.data_inicial) AS week,
        DATE_PART('month', evt.data_inicial) AS month,
        translate(lower( cidade ), ' ''àáâãäéèëêíìïîóòõöôúùüûçÇ%.+!&ªº°', '--aaaaaeeeeiiiiooooouuuucc') as tag_cidade,
        (select json_agg(row_to_json(linha))
            from
                (select
                    distinct
                    bd.badge,
                    tip.ordem
                from tb_badges bd
                inner join tb_badges_tipos tip on tip.badge = bd.badge
                where bd.id_evento = evt.id_evento
                order by tip.ordem
                 ) as linha
        ) as badges,
        (SELECT sum(res.concluintes)
            FROM tb_resultados_resumo res
            WHERE res.id_evento = evt.id_evento) as concluintes,
        (SELECT
            json_agg(json_build_object('percurso',percurso_evento,'unidade',unidade_de_medida,'tipo_corrida',tipo_corrida,'mapa',mapa) order by percurso_evento)
            from
            tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento
        ) as lista_percursos,
        (SELECT
            max(percurso_evento)
            from
            tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento
        ) as max_percurso,
        (SELECT cupom FROM vw_evento_corridas_cupom
            WHERE id_evento_agrega = evt.id_evento
            AND tipo_evento = 1
            OR (id_evento_agrega = evt.id_agrega_evento
            AND tipo_evento = 2)
        ) as cupom,
        (WITH vw as (
                SELECT percurso, sum(concluintes) as concluintes
                from
                tb_resultados_resumo pcr
                where pcr.id_evento = evt.id_evento
                group by percurso)
            SELECT
            json_agg(json_build_object('percurso',percurso,'concluintes',concluintes) order by percurso)
            from vw
        ) as lista_percursos_resultado,
        (SELECT percurso_evento from tb_evento_corridas_percursos pcr
            where pcr.id_evento = evt.id_evento AND percurso_evento = 42
            limit 1
        ) as is_maratona
    FROM tb_evento_corridas evt
    WHERE evt.data_inicial <= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>
    AND evt.ativo = true
    AND ( Exists (SELECT distinct id_evento FROM tb_resultados_resumo res WHERE evt.id_evento = res.id_evento )
        OR Exists (SELECT 1 FROM tb_resultados raw_res WHERE raw_res.id_evento = evt.id_evento AND raw_res.origem_resultado <> 'validacao_documental')
        OR (evt.url_resultado is not null AND evt.url_resultado <> '' AND evt.data_inicial <= <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now(), 'yyyy-mm-dd')#"/>) )
    ORDER BY evt.data_final desc, concluintes desc NULLS LAST;
</cfquery>
<cfquery name="qTotalResultados" timeout="5">
 SELECT count(*)::int as total FROM tb_resultados WHERE origem_resultado <> 'validacao_documental'
</cfquery>
<cfreturn {events=qEventosBase,cities=buildCities(qEventosBase,now()),totalResults=qTotalResultados}/>
</cffunction>
<cfscript>
public struct function buildCities(required query events, required date today) {
    var groups = {};
    var todayDate = createDate(year(arguments.today),month(arguments.today),day(arguments.today));
    var recentStart = dateAdd("d",-30,todayDate);
    var annualStart = dateAdd("m",-12,todayDate);
    for (var event in arguments.events) {
        var uf = uCase(trim(isNull(event.estado) ? "" : event.estado));
        var name = trim(isNull(event.cidade) ? "" : event.cidade);
        var slug = lCase(trim(isNull(event.tag_cidade) ? "" : event.tag_cidade));
        if (isNull(event.pais) || event.pais != "BR" || !listFind("AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO",uf) || !len(name) || !len(slug) || reFind("[^a-z0-9-]",slug)) continue;
        var key = uf & ":" & slug;
        if (!structKeyExists(groups,key)) {
            var words = listToArray(lCase(name)," ");
            for (var wi=1;wi<=arrayLen(words);wi++) {
                if (wi==1 || !listFindNoCase("a,ao,aos,as,com,da,das,de,del,do,dos,e,em,na,nas,no,nos,para,por,sem,sob",words[wi])) {
                    words[wi] = uCase(left(words[wi],1)) & mid(words[wi],2,len(words[wi]));
                }
            }
            groups[key] = {name=arrayToList(words," "),uf=uf,slug=slug,total=0,recent=0,annual=0,latest=createDate(1900,1,1)};
        }
        groups[key].total++;
        if (!isNull(event.data_final) && isDate(event.data_final)) {
            var eventDay = createDate(year(event.data_final),month(event.data_final),day(event.data_final));
            if (eventDay<=todayDate) {
                if (eventDay>recentStart) groups[key].recent++;
                if (eventDay>annualStart) groups[key].annual++;
                if (eventDay>groups[key].latest) groups[key].latest=eventDay;
            }
        }
    }
    var cities = [];
    for (var key in groups) arrayAppend(cities,groups[key]);
    arraySort(cities,function(a,b){return compareNoCase(a.name & " " & a.uf,b.name & " " & b.uf);});
    var recentPool = arrayFilter(cities,function(city){return city.recent>0;});
    arraySort(recentPool,function(a,b){
        if (a.recent!=b.recent) return b.recent-a.recent;
        if (a.latest!=b.latest) return dateCompare(b.latest,a.latest);
        return compareNoCase(a.name & " " & a.uf,b.name & " " & b.uf);
    });
    var recent = [];
    var seen = {};
    for (var city in recentPool) {
        if (arrayLen(recent)==6) break;
        arrayAppend(recent,city);seen[city.uf & ":" & city.slug]=true;
    }
    var popularPool = arrayFilter(cities,function(city){return city.annual>0 && !structKeyExists(seen,city.uf & ":" & city.slug);});
    arraySort(popularPool,function(a,b){
        if (a.annual!=b.annual) return b.annual-a.annual;
        return compareNoCase(a.name & " " & a.uf,b.name & " " & b.uf);
    });
    var popular = [];
    for (var city in popularPool) {
        if (arrayLen(popular)==6) break;
        arrayAppend(popular,city);
    }
    return {cities=cities,recent=recent,popular=popular};
}
</cfscript>
</cfcomponent>
