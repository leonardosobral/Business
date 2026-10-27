component output=false {
    public numeric function period(any value=30){
        return isSimpleValue(value) AND reFind("^(7|30|90|365)$",trim(value & "")) ? val(value) : 30;
    }
    public string function sql(){
        return "SELECT to_char(calendar.day,'YYYY-MM-DD') AS day,COALESCE(acquired.registrations,0) AS registrations
            FROM generate_series(CAST(:first AS timestamp),CAST(:last AS timestamp),interval '1 day') AS calendar(day)
            LEFT JOIN (
                SELECT usr.data_criacao::date AS day,count(*) AS registrations
                FROM public.tb_usuarios usr
                WHERE usr.data_criacao>=CAST(:first AS timestamp)
                  AND usr.data_criacao<CAST(:exclusive AS timestamp)
                  AND usr.data_criacao<=LOCALTIMESTAMP
                GROUP BY usr.data_criacao::date
            ) AS acquired ON acquired.day=calendar.day::date
            ORDER BY calendar.day";
    }
    public struct function parameters(required string lastDay){
        var last=createObject("java","java.time.LocalDate").parse(lastDay);
        return {first={value=last.minusDays(javaCast("long",364)).toString(),cfsqltype="cf_sql_date"},last={value=lastDay,cfsqltype="cf_sql_date"},exclusive={value=last.plusDays(javaCast("long",1)).toString(),cfsqltype="cf_sql_date"}};
    }
    public struct function summarize(required array rows,any days=30){
        var length=period(days);var start=max(1,arrayLen(rows)-length+1);
        var out={days=length,total=0,average=0,peak=0,peak_day="",first_day="",last_day=""};
        if(!arrayLen(rows))return out;
        out.first_day=rows[start].day;out.last_day=rows[arrayLen(rows)].day;
        for(var i=start;i LTE arrayLen(rows);i++){
            var row=rows[i];
            if(!reFind("^[0-9]{4}-[0-9]{2}-[0-9]{2}$",row.day) OR !isNumeric(row.count) OR row.count LT 0 OR fix(row.count) NEQ row.count)throw(type="UserAcquisition.Invalid",message="Série de cadastros inválida.");
            out.total+=row.count;if(row.count GT out.peak){out.peak=row.count;out.peak_day=row.day;}
        }
        out.average=out.total/length;return out;
    }
    public struct function load(any days=30){
        var db={datasource="runner_dba",timeout=5};
        var clock=queryExecute("SELECT to_char(LOCALTIMESTAMP,'YYYY-MM-DD') AS today,to_char(LOCALTIMESTAMP,'DD/MM/YYYY HH24:MI') AS updated_at",[],db);
        var daily=queryExecute(sql(),parameters(clock.today[1]),db);var rows=[];
        for(var item in daily){var row=structNew("ordered-casesensitive");row["day"]=item.day;row["count"]=val(item.registrations);arrayAppend(rows,row);}
        if(arrayLen(rows) NEQ 365)throw(type="UserAcquisition.Incomplete",message="Série diária incompleta.");
        return {rows=rows,days=period(days),summary=summarize(rows,days),updated_at=clock.updated_at[1],timezone="America/Sao_Paulo"};
    }
}
