<cfsetting showdebugoutput="false"/><cfscript>
function check(required boolean condition,required string message){if(!condition)throw(message=message);VARIABLES.assertions++;}
function total(required string slug){for(var row in qEstadoCidadesContagens)if(row.tag_cidade==slug)return row.total_eventos;return 0;}
VARIABLES.assertions=0;
qEventosBase=queryNew('tag_cidade,cidade,data_final,tipo_corrida,cupom,pais,estado','varchar,varchar,date,varchar,varchar,varchar,varchar');
rows=[['salvador','Salvador',15,'rua','CUPOM','BR','BA'],['salvador','Salvador',80,'trail','CUPOM','BR','BA'],['feira-de-santana','Feira de Santana',20,'rua','CUPOM','BR','BA'],['salvador','Salvador',400,'rua','CUPOM','BR','BA'],['salvador','Salvador',-1,'rua','CUPOM','BR','BA'],['florianopolis','Florianópolis',10,'rua','CUPOM','BR','SC']];
for(row in rows){queryAddRow(qEventosBase,{tag_cidade=row[1],cidade=row[2],data_final=dateAdd('d',row[3],now()),tipo_corrida=row[4],cupom=row[5],pais=row[6],estado=row[7]});}
URL={tag='BA',cidade='salvador',tempo='0,1',rua=true,trail=true,nacional=true,internacional=false,cupom=false};
</cfscript><cfquery name="qEstadoCidadesContagens" dbtype="query">
    SELECT tag_cidade, count(*) AS total_eventos
    FROM qEventosBase
    WHERE estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
        AND tag_cidade IS NOT NULL
    <cfif len(trim(URL.tempo))>
        AND data_final BETWEEN <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
            AND <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListLast(URL.tempo)*30), 'yyyy-mm-dd')#"/>
    </cfif>
    <cfif URL.rua AND NOT URL.trail>
        AND tipo_corrida = 'rua'
    </cfif>
    <cfif NOT URL.rua AND URL.trail>
        AND tipo_corrida = 'trail'
    </cfif>
    <cfif NOT URL.rua AND NOT URL.trail>
        AND tipo_corrida <> 'rua' AND tipo_corrida <> 'trail'
    </cfif>
    <cfif URL.cupom>
        AND cupom IS NOT NULL
    </cfif>
    <cfif URL.nacional AND NOT URL.internacional>
        AND pais = 'BR'
    </cfif>
    <cfif NOT URL.nacional AND URL.internacional>
        AND pais <> 'BR'
    </cfif>
    <cfif NOT URL.nacional AND NOT URL.internacional>
        AND pais = ''
    </cfif>
    GROUP BY tag_cidade
</cfquery><cfscript>
check(total('salvador')==1,'Current month must exclude past and later events');
check(total('feira-de-santana')==1,'Selected city must not hide the other city choices');
check(total('florianopolis')==0,'Cities must belong to the selected state');
URL.tempo='0,12';URL.rua=false;
</cfscript><cfquery name="qEstadoCidadesContagens" dbtype="query">
    SELECT tag_cidade, count(*) AS total_eventos
    FROM qEventosBase
    WHERE estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
        AND tag_cidade IS NOT NULL
    <cfif len(trim(URL.tempo))>
        AND data_final BETWEEN <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
            AND <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListLast(URL.tempo)*30), 'yyyy-mm-dd')#"/>
    </cfif>
    <cfif URL.rua AND NOT URL.trail>
        AND tipo_corrida = 'rua'
    </cfif>
    <cfif NOT URL.rua AND URL.trail>
        AND tipo_corrida = 'trail'
    </cfif>
    <cfif NOT URL.rua AND NOT URL.trail>
        AND tipo_corrida <> 'rua' AND tipo_corrida <> 'trail'
    </cfif>
    <cfif URL.cupom>
        AND cupom IS NOT NULL
    </cfif>
    <cfif URL.nacional AND NOT URL.internacional>
        AND pais = 'BR'
    </cfif>
    <cfif NOT URL.nacional AND URL.internacional>
        AND pais <> 'BR'
    </cfif>
    <cfif NOT URL.nacional AND NOT URL.internacional>
        AND pais = ''
    </cfif>
    GROUP BY tag_cidade
</cfquery><cfscript>
check(total('salvador')==1,'Trail only must exclude street races');
check(total('feira-de-santana')==0,'Street-only city must have zero trail races');
URL.rua=true;URL.trail=true;URL.cupom=true;
</cfscript><cfquery name="qEstadoCidadesContagens" dbtype="query">
    SELECT tag_cidade, count(*) AS total_eventos
    FROM qEventosBase
    WHERE estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
        AND tag_cidade IS NOT NULL
    <cfif len(trim(URL.tempo))>
        AND data_final BETWEEN <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
            AND <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListLast(URL.tempo)*30), 'yyyy-mm-dd')#"/>
    </cfif>
    <cfif URL.rua AND NOT URL.trail>
        AND tipo_corrida = 'rua'
    </cfif>
    <cfif NOT URL.rua AND URL.trail>
        AND tipo_corrida = 'trail'
    </cfif>
    <cfif NOT URL.rua AND NOT URL.trail>
        AND tipo_corrida <> 'rua' AND tipo_corrida <> 'trail'
    </cfif>
    <cfif URL.cupom>
        AND cupom IS NOT NULL
    </cfif>
    <cfif URL.nacional AND NOT URL.internacional>
        AND pais = 'BR'
    </cfif>
    <cfif NOT URL.nacional AND URL.internacional>
        AND pais <> 'BR'
    </cfif>
    <cfif NOT URL.nacional AND NOT URL.internacional>
        AND pais = ''
    </cfif>
    GROUP BY tag_cidade
</cfquery><cfscript>
check(total('salvador')==2,'Coupon and default period must match the calendar');
check(total('feira-de-santana')==1,'Coupon city alternatives remain available');
URL.nacional=false;URL.internacional=true;
</cfscript><cfquery name="qEstadoCidadesContagens" dbtype="query">
    SELECT tag_cidade, count(*) AS total_eventos
    FROM qEventosBase
    WHERE estado = <cfqueryparam cfsqltype="cf_sql_varchar" value="#uCase(URL.tag)#"/>
        AND tag_cidade IS NOT NULL
    <cfif len(trim(URL.tempo))>
        AND data_final BETWEEN <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListFirst(URL.tempo)*30), 'yyyy-mm-dd')#"/>
            AND <cfqueryparam cfsqltype="cf_sql_date" value="#lsdateformat(now()+(ListLast(URL.tempo)*30), 'yyyy-mm-dd')#"/>
    </cfif>
    <cfif URL.rua AND NOT URL.trail>
        AND tipo_corrida = 'rua'
    </cfif>
    <cfif NOT URL.rua AND URL.trail>
        AND tipo_corrida = 'trail'
    </cfif>
    <cfif NOT URL.rua AND NOT URL.trail>
        AND tipo_corrida <> 'rua' AND tipo_corrida <> 'trail'
    </cfif>
    <cfif URL.cupom>
        AND cupom IS NOT NULL
    </cfif>
    <cfif URL.nacional AND NOT URL.internacional>
        AND pais = 'BR'
    </cfif>
    <cfif NOT URL.nacional AND URL.internacional>
        AND pais <> 'BR'
    </cfif>
    <cfif NOT URL.nacional AND NOT URL.internacional>
        AND pais = ''
    </cfif>
    GROUP BY tag_cidade
</cfquery><cfscript>
check(qEstadoCidadesContagens.recordCount==0,'International only must exclude Brazilian events');
writeOutput('RR_CITY_COUNTS_PASSED:' & VARIABLES.assertions);
</cfscript>