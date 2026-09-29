"""Verify the exact Business timeline SQL against synthetic ads rows in crm_test."""
from pathlib import Path
import re
import subprocess

root=Path(__file__).resolve().parents[2]
psql=['/opt/homebrew/opt/postgresql@16/bin/psql','-X','-v','ON_ERROR_STOP=1','-At','-F','|','-h','127.0.0.1','-p','55447','-U','crm_test','-d','crm_test']
identity=subprocess.check_output(psql+['-c','select current_database()'],text=True).strip()
if identity!='crm_test':raise SystemExit('Refusing a non-test database')
source=(root/'crm-interno/timeline.cfm').read_text()
match=re.search(r'campaigns=queryExecute\("([^"]+)"',source)
if not match:raise SystemExit('Timeline SQL not found')
query=match.group(1).replace(':from_day',"'2026-09-25'").replace(':to_day',"'2026-10-09'")
script=f"""BEGIN;
CREATE SCHEMA IF NOT EXISTS ads;
CREATE TABLE ads.campaigns(campaign_id uuid,name text,status text,starts_at timestamptz,ends_at timestamptz);
CREATE TABLE ads.advertisements(campaign_id uuid,ad_type text);
INSERT INTO ads.campaigns VALUES
 ('00000000-0000-4000-8000-000000000001','Ad sintético','ACTIVE','2026-09-25 10:00:00-03','2026-10-05 10:00:00-03'),
 ('00000000-0000-4000-8000-000000000002','Banner sintético','ACTIVE','2026-09-26 10:00:00-03','2026-09-29 00:00:00-03'),
 ('00000000-0000-4000-8000-000000000003','Fora da janela','ENDED','2026-08-01 10:00:00-03','2026-08-03 10:00:00-03');
INSERT INTO ads.advertisements VALUES ('00000000-0000-4000-8000-000000000002','BANNER');
{query};
ROLLBACK;
"""
result=subprocess.run(psql,capture_output=True,text=True,input=script,check=True)
rows=[line.split('|') for line in result.stdout.splitlines() if line.startswith('00000000-')]
if len(rows)!=2 or rows[0][3]!='ads' or rows[1][3]!='banner' or rows[1][5]!='2026-09-28':
 raise SystemExit('Timeline SQL classified or clipped synthetic campaigns incorrectly: '+repr(rows))
print('CRM timeline SQL: PASS (ads, banner, exclusive end day, date window)')
