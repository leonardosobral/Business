<cfscript>
function check(required boolean ok,required string label){if(!ok)throw(type="Test.Failed",message=label);}
metrics=new services.UserAcquisitionMetrics();
check(metrics.period("7") EQ 7 AND metrics.period("365") EQ 365,"Períodos permitidos.");
check(metrics.period("0") EQ 30 AND metrics.period("7 OR 1=1") EQ 30 AND metrics.period([7]) EQ 30,"Período inválido não altera SQL.");
transaction{
 queryExecute("SET TRANSACTION READ ONLY",[],{datasource="runner_dba"});
 // Hand-derived window: 01/03 through 07/03/2024; two accounts on first day,
 // one on leap day (outside selected 7), one today, zero-filled middle days.
 fixtureSQL="WITH fixture_users(data_criacao) AS (VALUES ('2023-03-09 00:00'::timestamp),('2024-02-29 12:00'::timestamp),('2024-03-01 00:00'::timestamp),('2024-03-01 23:59:59'::timestamp),('2024-03-07 23:59:59'::timestamp),('2024-03-08 00:00'::timestamp),(NULL::timestamp)) " & replace(metrics.sql(),"public.tb_usuarios","fixture_users","all");
 daily=queryExecute(fixtureSQL,metrics.parameters("2024-03-07"),{datasource="runner_dba",timeout=10});
 check(daily.recordCount EQ 365 AND daily.day[1] EQ "2023-03-09" AND daily.day[365] EQ "2024-03-07","365 dias exatos, ano bissexto e cronologia.");
 rows=[];for(row in daily)arrayAppend(rows,{day=row.day,count=row.registrations});
 seven=metrics.summarize(rows,7);check(seven.total EQ 3 AND seven.peak EQ 2 AND seven.peak_day EQ "2024-03-01" AND seven.days EQ 7,"Soma, pico e janela independente.");
 check(abs(seven.average-3/7) LT 0.000001 AND seven.first_day EQ "2024-03-01","Média inclui dias sem cadastro.");
 check(metrics.summarize(rows,30).total EQ 4 AND metrics.summarize(rows,365).total EQ 5,"Janelas maiores incluem dias antigos, não a borda final seguinte.");
 emptyRows=[{day="2024-03-07",count=0}];zero=metrics.summarize(emptyRows,7);check(zero.total EQ 0 AND zero.peak EQ 0 AND zero.peak_day EQ "","Zero real não inventa dia de pico.");
 real=metrics.load(30);check(arrayLen(real.rows) EQ 365 AND real.days EQ 30,"Carga real só contém 365 totais diários.");
 independent=queryExecute("SELECT count(*) AS n FROM public.tb_usuarios WHERE data_criacao>=CAST(:first AS date) AND data_criacao<CAST(:exclusive AS date) AND data_criacao<=LOCALTIMESTAMP",{first={value=real.summary.first_day,cfsqltype="cf_sql_date"},exclusive={value=dateFormat(dateAdd('d',1,parseDateTime(real.summary.last_day)),"yyyy-mm-dd"),cfsqltype="cf_sql_date"}},{datasource="runner_dba",timeout=10});
 check(real.summary.total EQ independent.n[1],"Total do gráfico reconciliado com contagem direta sem joins.");
 writeOutput(serializeJSON({days=real.days,total=real.summary.total,from=real.summary.first_day,to=real.summary.last_day,rows=arrayLen(real.rows)}));
}
writeOutput("USER_ACQUISITION_NATIVE_PASSED");
</cfscript>
