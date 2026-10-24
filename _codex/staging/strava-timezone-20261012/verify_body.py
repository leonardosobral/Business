backup=Path(BACKUP)
plan=json.loads((backup/'activity-dates-before.json').read_text())['rows']
bridge=Bridge()
try:
 totals={'checked':0,'correct':0,'other_fields_unchanged':0,'calendar_unchanged':0}
 sql='''WITH plan AS (SELECT * FROM jsonb_to_recordset(CAST(:plan AS jsonb)) AS p(activity_id bigint,"after" timestamp,activity_date date,other_fields_md5 text)) SELECT jsonb_build_object('checked',count(*),'correct',count(*) FILTER(WHERE a.start_date=p."after"),'other_fields_unchanged',count(*) FILTER(WHERE md5((to_jsonb(a)-'start_date')::text)=p.other_fields_md5),'calendar_unchanged',count(*) FILTER(WHERE a.activity_date IS NOT DISTINCT FROM p.activity_date))::text AS payload FROM plan p LEFT JOIN public.tb_strava_activities a USING(activity_id)'''
 for start in range(0,len(plan),100):
  r=bridge.query(sql,params={'plan':{'value':json.dumps(plan[start:start+100]),'cfsqltype':'cf_sql_longvarchar'}})
  for k in totals:totals[k]+=r[k]
  time.sleep(0.1)
 example=bridge.query('''SELECT jsonb_agg(jsonb_build_object('activity_id',activity_id,'start_date',start_date,'activity_date',activity_date,'matches_original',start_date=((strava_raw->>'start_date')::timestamptz AT TIME ZONE 'America/Sao_Paulo')) ORDER BY activity_id)::text AS payload FROM public.tb_strava_activities WHERE athlete_id=(SELECT strava_id FROM public.tb_usuarios WHERE id=100057) AND activity_id IN (20519853973,20533724978,20548465009)''')
 rendered=bridge.run('''transaction {queryExecute("SET TRANSACTION READ ONLY",{},{datasource="runner_dba"});q=queryExecute("SELECT activity_id,start_date,activity_date FROM public.tb_strava_activities WHERE activity_id IN (20519853973,20533724978,20548465009) AND athlete_id=(SELECT strava_id FROM public.tb_usuarios WHERE id=100057) ORDER BY activity_id",{},{datasource="runner_dba",timeout=10});rows=[];for(i=1;i LTE q.recordCount;i++){arrayAppend(rows,{id=q.activity_id[i],displayStart=dateTimeFormat(q.start_date[i],"dd/mm/yyyy HH:nn:ss"),displayCalendar=dateFormat(q.activity_date[i],"dd/mm/yyyy")});}writeOutput(serializeJSON(rows));}''')
 jobs=bridge.query('''SELECT jsonb_build_object('measured_at',now(),'job',(SELECT jsonb_build_object('active',ativo,'last_status',last_status,'last_run_at_utc',last_run_at,'next_run_at_utc',next_run_at) FROM tb_cron_jobs WHERE id_cron_job=6),'runs',(SELECT jsonb_agg(to_jsonb(r) ORDER BY started_at) FROM (SELECT status,started_at,finished_at,duration_ms,substring(response_preview FROM '(?i)"success"\\s*:\\s*(true|false)') AS api_success,substring(response_preview FROM '(?i)"status"\\s*:\\s*"([a-z_]{1,80})"') AS api_status,substring(response_preview FROM '(?i)"activities_upserted"\\s*:\\s*([0-9]+)') AS activities_upserted,substring(response_preview FROM '(?i)"processed"\\s*:\\s*([0-9]+)') AS processed FROM tb_cron_job_runs WHERE id_cron_job=6 AND started_at>=timestamp '2026-10-12 14:59:31' ORDER BY started_at DESC LIMIT 3) r))::text AS payload''')
 report={'verified_at_utc':datetime.now(timezone.utc).isoformat(),'totals':totals,'user_100057':example,'coldfusion_display':rendered,'cron6':jobs,'runtime_sha256':hashlib.sha256(Path('/var/www/roadrunners.com.br/api/integrations/strava/batch-refresh.cfm').read_bytes()).hexdigest(),'health':health()}
 (backup/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps(report,indent=2))
 if totals['correct']!=1689 or totals['calendar_unchanged']!=1689:raise RuntimeError('Date verification failed')
finally:bridge.close()
