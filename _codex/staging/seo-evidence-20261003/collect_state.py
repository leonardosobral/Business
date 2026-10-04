"""Read-only, aggregate-only production evidence through the existing local bridge."""
from pathlib import Path
import json, shlex, subprocess
ROOT=Path('/Users/Shared/Projects/RunnerHub/Business'); STAGE=Path(__file__).resolve().parent
helpers=(ROOT/'_codex/scripts/deploy_estudo.py').read_text().split('def remote(')[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/var/www/business.roadrunners.run')")
audience_sql="""WITH bounds AS (SELECT now() AS end_at,now()-interval '7 days' AS start_at),
views AS (
 SELECT e.site_host,e.occurred_at,e.page_view_id,e.session_id,
 CASE lower(btrim(e.referrer_host))
 WHEN 'chatgpt.com' THEN 'ChatGPT' WHEN 'www.chatgpt.com' THEN 'ChatGPT' WHEN 'chat.openai.com' THEN 'ChatGPT'
 WHEN 'perplexity.ai' THEN 'Perplexity' WHEN 'www.perplexity.ai' THEN 'Perplexity' WHEN 'perplexity.com' THEN 'Perplexity' WHEN 'www.perplexity.com' THEN 'Perplexity'
 WHEN 'claude.ai' THEN 'Claude' WHEN 'copilot.microsoft.com' THEN 'Copilot' WHEN 'gemini.google.com' THEN 'Gemini' END AS provider
 FROM audience.events e,bounds b WHERE occurred_at>=b.start_at AND occurred_at<b.end_at
 AND environment='prod' AND is_internal=false AND event_kind='page_view'
 AND site_host IN ('roadrunners.run','openresults.run')
), sites AS (SELECT site_host,count(DISTINCT page_view_id) AS pageviews,count(DISTINCT session_id) AS sessions,min(occurred_at) AS first,max(occurred_at) AS last,
 count(DISTINCT page_view_id) FILTER (WHERE provider IS NOT NULL) AS ai_pageviews,
 count(DISTINCT session_id) FILTER (WHERE provider IS NOT NULL) AS ai_sessions FROM views GROUP BY site_host),
providers AS (SELECT site_host,provider,count(DISTINCT page_view_id) AS pageviews,count(DISTINCT session_id) AS sessions FROM views WHERE provider IS NOT NULL GROUP BY site_host,provider)
SELECT jsonb_build_object('measured_at',now(),'start_at',(SELECT start_at FROM bounds),'end_at',(SELECT end_at FROM bounds),
'sites',(SELECT coalesce(jsonb_agg(to_jsonb(s) ORDER BY site_host),'[]') FROM sites s),
'providers',(SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY site_host,provider),'[]') FROM providers p))::text AS payload"""
state_sql="""SELECT jsonb_build_object('measured_at',now(),
'future',(SELECT jsonb_agg(to_jsonb(e)) FROM (SELECT tag,'future' AS cohort FROM public.tb_evento_corridas WHERE ativo=true AND length(coalesce(descricao,''))>80 AND data_inicial>(now() AT TIME ZONE 'America/Sao_Paulo')::date ORDER BY data_inicial,id_evento LIMIT 2) e),
'cron',(SELECT jsonb_build_object('id',id_cron_job,'active',ativo,'interval_minutes',interval_minutes,'last_run_at',last_run_at,'last_status',last_status,'last_http_status',last_http_status,'updated_at',data_atualizacao,
'error_kind',CASE WHEN last_error IS NULL OR last_error='' THEN 'none' WHEN lower(last_error) LIKE '%timeout%' THEN 'timeout' WHEN lower(last_error) LIKE '%401%' THEN 'http_401' WHEN lower(last_error) LIKE '%403%' THEN 'http_403' ELSE 'other_error_redacted' END)
 FROM public.tb_cron_jobs WHERE id_cron_job=15))::text AS payload"""
remote=helpers+'''
payload=json.load(sys.stdin)
report={}
report['audience']=bridge(ROOT,raw_query(payload['audience']).replace('datasource="runner_dba"','datasource="runnerhub"')+'report=deserializeJSON(q.payload[1]);')
report['state']=bridge(ROOT,raw_query(payload['state'])+'report=deserializeJSON(q.payload[1]);')
body='include "/api/eventos/jobs/queue.cfm";counts=queryExecute(eventDescriptionQueueSql() & " SELECT language,queue_status,count(*) AS total FROM work GROUP BY language,queue_status ORDER BY language,queue_status",{event_id={value=0,cfsqltype="cf_sql_integer"},language={value="auto",cfsqltype="cf_sql_varchar"}},{datasource="runner_dba",timeout=50});report={counts=[]};for(row in counts)arrayAppend(report.counts,{language=row.language,status=row.queue_status,total=row.total});'
report['queue']=bridge(ROOT,body)
print(json.dumps(report))
'''
cp=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(remote)],input=json.dumps({'audience':audience_sql,'state':state_sql}),capture_output=True,text=True,timeout=230)
if cp.returncode: raise RuntimeError(cp.stderr[-3000:])
result=json.loads(cp.stdout)
(STAGE/'state.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(result,ensure_ascii=False))
