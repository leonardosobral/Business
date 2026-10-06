"""Read-only bounded profiling of production home queries in a temporary loopback-only CF application."""
from pathlib import Path
import json,subprocess,shlex
ROOT=Path(__file__).resolve().parents[2]
s=(ROOT/'_codex/scripts/deploy_error_triage.py').read_text().split("if __name__=='__main__':")[0].replace('ROOT=Path(__file__).resolve().parents[2]',"ROOT=Path('/opt/ColdFusion/cfusion/wwwroot')").replace("dir=root/'_codex'","dir=root").replace('https://business.roadrunners.run/_codex/','http://127.0.0.1:8500/').replace('this.datasource="runner_dba"','this.datasource="runnerhub"')
s+=r'''
import re
root=Path('/var/www/openresults.run')
backend=(root/'includes/backend.cfm').read_text().split('<cfif isDefined("URL.teste")>')[0]
# Instrument the exact statements, retaining cachedwithin and query result metadata.
def instrument(s):
 def mark(m):
  q=m.group(0);name=re.search(r'name="([^"]+)"',q,re.I).group(1)
  result=re.search(r'\bresult="([^"]+)"',q,re.I)
  extra=',cached='+result.group(1)+'.cached,reportedMs='+result.group(1)+'.executionTime' if result else ''
  return '<cfset profileTick=getTickCount()/>'+q+'<cfset arrayAppend(profileRows,{name="'+name+'",ms=getTickCount()-profileTick,rows='+name+'.recordCount'+extra+'})/>'
 return re.sub(r'<cfquery\s[^>]*>.*?</cfquery>',mark,s,flags=re.S|re.I)
home=(root/'index.cfm').read_text();total=re.search(r'<cfquery name="qTotalResultados".*?</cfquery>',home,re.S).group(0)
recent=re.search(r'<cfquery name="qEventosRecentesHome".*?</cfquery>',home,re.S).group(0)
upcoming=re.search(r'<cfquery name="qProximosEventos".*?</cfquery>',(root/'includes/proximos_eventos.cfm').read_text(),re.S).group(0)
qhome='<cfquery name="qEventosHome" dbtype="query">SELECT * FROM qEventos WHERE concluintes > 0</cfquery>'
city=(root/'includes/backend_home_cidades.cfm').read_text()
profile='<cfset profileRows=[]/><cfset totalTick=getTickCount()/>'+instrument(backend)+'<cfset profileTick=getTickCount()/>'+city+'<cfset arrayAppend(profileRows,{name="city_catalog",ms=getTickCount()-profileTick,cities=arrayLen(homeCityCatalog.cities)})/>'+instrument(total+qhome+recent+upcoming)+'<cfset report={steps=profileRows,totalMs=getTickCount()-totalTick}/>'
with tempfile.TemporaryDirectory(prefix='or-home-profile-',dir='/var/tmp') as d:
 p=Path(d);os.chmod(p,0o755);(p/'profile.cfm').write_text(profile)
 template=os.path.relpath(p/'profile.cfm',ROOT/'fixture')
 body='URL={badges="",rua=true,trail=true,cupom=false,nacional=true,internacional=true,tag=""};VARIABLES.template="/";VARIABLES.homeContextUf="";profileRuns=[];for(profileRun=1;profileRun<=2;profileRun++){include '+json.dumps(template)+';arrayAppend(profileRuns,duplicate(report));}report={runs=profileRuns};'
 print(json.dumps(bridge(ROOT,body)))
'''
p=subprocess.run(['ssh','-o','BatchMode=yes','-o','ConnectTimeout=10','-i','/Users/leonardosobral/.ssh/webs','root@ssh.runnerhub.run','python3 -c '+shlex.quote(s)],capture_output=True,text=True,timeout=210)
print(p.stdout);print(p.stderr[-2000:]);stage=ROOT/'_codex/staging/openresults-home-profile-20261004';stage.mkdir(exist_ok=True);(stage/'profile.json').write_text(p.stdout);raise SystemExit(p.returncode)
