from pathlib import Path
import hashlib,json,shutil
P=Path(__file__).resolve().parent;BUSINESS=P.parents[2];RR=BUSINESS.parent/'RoadRunners'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
# Refuse local drift; do not overwrite work from other fronts.
plan=[]
for n in ['portal/conteudo/seo_semrush.cfm','portal/includes/seo_semrush_data.cfm','portal/includes/seo_queue_data.cfm']:
 assert digest(BUSINESS/n)==digest(P/'baseline/business'/n),n
 plan.append((BUSINESS/n,(P/'candidate/business'/n).read_bytes(),'business/'+n))
for n in ['includes/estrutura/event_title_date.cfm','services/EventRedirectService.cfc','includes/card_evento_individual.cfm','includes/estrutura/header_tema.cfm','includes/estrutura/head.cfm','includes/estrutura/event_redirect.cfm']:
 target=RR/n
 if n=='includes/estrutura/event_title_date.cfm':assert not target.exists(),n
 else:
  baseline=P/('redirect-baseline' if n=='includes/estrutura/event_redirect.cfm' else 'baseline/rr')/n
  assert digest(target)==digest(baseline),n
 source=P/('redirect-candidate' if n=='includes/estrutura/event_redirect.cfm' else 'canonical-candidate' if n in ['services/EventRedirectService.cfc','includes/estrutura/head.cfm'] else 'candidate/rr')/n
 plan.append((target,source.read_bytes(),'rr/'+n))
# Keep existing local/prod differences in the event page; patch only this task's line.
n='evento/index.cfm';s=(RR/n).read_text();old='<cfset VARIABLES.canonical = REQUEST.i18nBuildAbsoluteUrl(VARIABLES.routeKey) />';new='<cfset VARIABLES.canonical = VARIABLES.eventRedirectService.canonicalUrlFor(REQUEST.i18nBuildAbsoluteUrl(VARIABLES.routeKey), qEvento.tag & "") />';assert s.count(old)==1
plan.append((RR/n,s.replace(old,new).encode(),'rr/'+n))
for target,data,label in plan:
 if target.exists():
  backup=P/'local-before'/label;backup.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(target,backup)
 target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
print(json.dumps({'synced_runtime_files':len(plan),'business':3,'roadrunners':7,'event_page_local_differences_preserved':True}))
