"""Synthetic-only UI harness; serves the actual CRM assets without auth/session dependencies."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import json, re, urllib.parse, uuid
ROOT=Path(__file__).resolve().parents[2]
state={'audiences':[{'id':1,'name':'Público sintético SC','description':'Dados de teste','current_version':1,'policy':{'operator':'all','criteria':[{'type':'recent_result','days':30,'distance':'half'}]},'count_status':'ready','member_count':1},{'id':2,'name':'Público sintético SP','description':'Dados de teste','current_version':1,'policy':{'operator':'all','criteria':[{'type':'profile_state','state':'SP'}]},'count_status':'ready','member_count':1}],'campaigns':[],'opportunities':[],'confirmations':0}
caps={k:{'available':avail,'label':label,'source':src} for k,label,avail,src in [('profile_location','Localidade do perfil',True,'tb_usuarios'),('recent_result','Resultado recente',True,'tb_resultados'),('event_agenda','Evento na agenda',True,'tb_evento_corridas_checkin'),('event_registration','Inscrição registrada',True,'tb_evento_corridas_checkin'),('event_offers_distance','Evento oferece distância',True,'tb_evento_corridas_percursos'),('challenge_enrollment','Inscrição em desafio',True,'desafios'),('site_access','Acessos identificados',True,'crm_interno.access_daily'),('contact_history','Histórico de contato CRM',True,'crm_interno.deliveries'),('recent_training','Treinos recentes',False,''),('shoe_km','Quilometragem do tênis',False,'')]}
caps.update({k:{'available':True,'label':label,'source':'Cadastro próprio'} for k,label in [('profile_state','Estado'),('profile_city','Cidade'),('profile_age','Faixa etária'),('profile_gender','Gênero informado'),('birthday_month','Mês de aniversário'),('account_created','Cadastro recente'),('email_verified','E-mail confirmado'),('marketing_optin','Opt-in comercial'),('brasil_gigante','Circuito Brasil Gigante — inscrição')]})
class Handler(SimpleHTTPRequestHandler):
 def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(ROOT),**kwargs)
 def end_headers(self):self.send_header('Cache-Control','no-store');super().end_headers()
 def log_message(self,*args):pass
 def do_GET(self):
  if self.path=='/':
   text=(ROOT/'crm-interno/index.cfm').read_text();main=text[text.index('<main id='):text.index('</main>')+7];main=re.sub(r'<cfoutput>.*?</cfoutput>','fixture-csrf',main,flags=re.S)
   out='<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="/assets/css/mdb.min.css"><link rel="stylesheet" href="/crm-interno/crm.css?v=10"></head><body data-mdb-theme="dark" style="background:#171c23"><p style="color:#ddd;padding:6px 24px">Ambiente de teste · somente dados sintéticos</p>'+main+'<script src="/crm-interno/crm.js?v=13"></script></body></html>'
   self.send_response(200);self.end_headers();self.wfile.write(out.encode());return
  if self.path=='/state':self.send_response(200);self.end_headers();self.wfile.write(json.dumps(state).encode());return
  return super().do_GET()
 def do_POST(self):
  form=urllib.parse.parse_qs(self.rfile.read(int(self.headers['Content-Length'])).decode());payload=json.loads(form['payload'][0]);action=payload['action'];i=payload['input'];data={}
  if action=='catalog':data={'enabled':True,'capabilities':caps}
  elif action=='audiences.list':data={'items':state['audiences'],'total':len(state['audiences']),'counted_at':'2026-09-24T12:00:00-03:00'}
  elif action=='audiences.save':
   a={**i,'id':i.get('id',len(state['audiences'])+1),'current_version':i.get('expected_version',0)+1};state['audiences']=[x for x in state['audiences'] if x['id']!=a['id']]+[a];data=a
  elif action=='audiences.get':data=next(x for x in state['audiences'] if x['id']==i['id'])
  elif action=='audiences.evaluate':data={'total':1,'page':1,'as_of':'2026-09-24T12:00:00-03:00','users':[{'id':102,'name':'Corredor sintético','email':'runner@example.test','cidade':'Florianópolis','estado':'SC','reasons':['Resultado reconhecido nos últimos 30 dias (meia maratona)']}],'policy':i['policy'],'capabilities':caps}
  elif action=='audiences.eligibility':data={'total':1,'as_of':'2026-09-24T12:00:00-03:00','channels':{'email':{'eligible':1,'excluded':0,'reasons':[]},'notification':{'eligible':0,'excluded':1,'reasons':[{'code':'frequency_limit','total':1}]},'card':{'eligible':1,'excluded':0,'reasons':[]}}}
  elif action=='audiences.coverage':data={'total':1,'as_of':'2026-09-24T12:00:00-03:00','fields':[{'key':'state','filled':1,'missing':0,'invalid':0},{'key':'city','filled':1,'missing':0,'invalid':0},{'key':'birth','filled':0,'missing':1,'invalid':0},{'key':'gender','filled':1,'missing':0,'invalid':0}],'sources':[{'key':'results','status':'partial','from':'2026-09-01','to':'2026-09-24'},{'key':'agenda','status':'not_observed','from':'','to':''},{'key':'challenges','status':'not_observed','from':'','to':''},{'key':'accesses','status':'partial','from':'2026-09-20','to':'2026-09-24'}]}
  elif action=='audiences.recommendations':data={'audience_id':i['id'],'version':i['version'],'reason':'','items':[{'key':'next_race','title':'Próxima prova','reason':'Resultado reconhecido em prova nos últimos 90 dias','template':{'title':'Escolha sua próxima prova','body':'Explore as próximas provas disponíveis.','button':'Ver provas','channel':'card'}}]}
  elif action=='audiences.history':data={'audience_id':i['id'],'coverage_from':'2026-09-23','items':[{'snapshot_id':'33333333-3333-4333-8333-333333333333','version':1,'captured_day':'2026-09-25','status':'failed','total':0},{'snapshot_id':'11111111-1111-4111-8111-111111111111','version':1,'captured_day':'2026-09-24','status':'complete','total':1},{'snapshot_id':'22222222-2222-4222-8222-222222222222','version':1,'captured_day':'2026-09-23','status':'complete','total':1}]}
  elif action=='audiences.difference':data={'status':'comparable','total_entered':1,'total_left':1,'entered':[{'user_id':102,'name':'Corredor sintético','active':True}],'left':[{'user_id':104,'name':'Corredor anterior','active':False}]}
  elif action=='audiences.overlap':data={'as_of':'2026-09-24T12:00:00-03:00','total_unique':2,'pairs':[{'left_id':min(i['audience_ids']),'right_id':max(i['audience_ids']),'intersection':0}]}
  elif action=='users.profile':data={'user':{'id':102,'name':'Corredor sintético','email':'runner@example.test','cidade':'Florianópolis','estado':'SC','optin_usuario':True,'is_email_verified':True},'agenda':[{'id_evento':201,'nome_evento':'Meia da cidade','tipo_checkin':'calendario','data_final':'2026-10-10T09:00:00-03:00'}],'registrations':[{'id_evento':201,'nome_evento':'Meia da cidade','tipo_checkin':'calendario','data_final':'2026-10-10T09:00:00-03:00'}],'results':[{'id_evento':202,'nome_evento':'Meia realizada','percurso':21.0975,'data_final':'2026-09-10T09:00:00-03:00'}],'contacts':[],'access_summary':{'days_30':3,'last_seen':'2026-09-24T12:00:00-03:00','partial':True},'channels':{'email':{'allowed':True,'reason':''},'notification':{'allowed':True,'reason':''},'card':{'allowed':True,'reason':''}}}
  elif action=='users.timeline':data={'items':[{'kind':'result','at':'2026-09-10T09:00:00-03:00','id':'301','label':'Meia realizada','status':'21.0975','source':'resultado_reconhecido'},{'kind':'access','at':'2026-09-24T12:00:00-03:00','id':'2026-09-24','label':'Acesso identificado ao site','status':'partial','source':'acesso_proprio'}],'next_cursor':''}
  elif action=='opportunities.owners':data={'items':[{'id':101,'name':'Operador sintético'}]}
  elif action=='opportunities.list':
   matches=[o for o in state['opportunities'] if (not i.get('user_id') or o['user_id']==int(i['user_id'])) and (not i.get('owner_id') or o['owner_id']==int(i['owner_id'])) and (not i.get('stage') or o['stage']==i['stage'])]
   data={'items':matches,'total':len(matches),'page':1}
  elif action=='opportunities.get':data=next(o for o in state['opportunities'] if o['id']==i['id'])
  elif action=='opportunities.save':
   existing=next((o for o in state['opportunities'] if o['id']==i.get('id')),None)
   if existing:existing.update(i);existing['revision']+=1;o=existing
   else:
    o={**i,'id':str(uuid.uuid4()),'revision':1,'stage':'new','user_name':'Corredor sintético','owner_name':'Operador sintético','events':[]};state['opportunities'].append(o)
   data={'id':o['id'],'revision':o['revision']}
  elif action=='opportunities.transition':
   o=next(o for o in state['opportunities'] if o['id']==i['id']);o['stage']=i['stage'];o['revision']+=1;data={'id':o['id'],'revision':o['revision']}
  elif action=='opportunities.note':
   o=next(o for o in state['opportunities'] if o['id']==i['id']);o['revision']+=1;o['events'].insert(0,{'kind':'note','body':{'note':i['note']},'actor_name':'Operador sintético','created_at':'2026-09-24T12:00:00-03:00'});data={'id':o['id'],'revision':o['revision']}
  elif action=='campaigns.list':data={'items':state['campaigns']}
  elif action=='campaigns.calendar':data={'items':[{'id':201,'status':'scheduled','revision':1,'name':'Campanha sintética de outubro','channel':'email','starts_at':'2026-09-25T10:00:00-03:00','ends_at':'2026-09-30T18:00:00-03:00','audience_id':1,'audience_version':1}],'total':1,'page':1,'from':i['from'],'to':i['to']}
  elif action=='campaigns.pressure':data={'as_of':'2026-09-24T12:00:00-03:00','estimated':True,'conflicts':[{'campaign_id':202,'name':'Outra campanha sintética','users':1,'reason':'planned_overlap','status':'scheduled'}],'card_competition':[],'truncated':False}
  elif action=='campaigns.save':
   c={**i,'id':i.get('id',len(state['campaigns'])+1),'campaign_id':i.get('id',len(state['campaigns'])+1),'revision':i.get('expected_revision',0)+1,'status':'draft','content':{k:i[k] for k in ['title','body','button','conversion_goal']},'audience_name':state['audiences'][0]['name'],'audience_version':1};state['campaigns']=[x for x in state['campaigns'] if x['id']!=c['id']]+[c];data=c
  elif action=='campaigns.get':data=next(x for x in state['campaigns'] if x['id']==i['id'])
  elif action in ['campaigns.preview','campaigns.review']:data={'id':'11111111-1111-4111-8111-111111111111','total':1,'eligible':1,'as_of':'2026-09-24T12:00:00-03:00','expires_at':'2026-09-24T12:30:00-03:00','members':[{'user_id':102,'name':'Corredor sintético','eligible':True,'reasons':'["Resultado de meia maratona"]','exclusion_code':''}]}
  elif action=='campaigns.confirm':state['confirmations']+=1;state['campaigns'][0]['status']='scheduled';data={'id':1}
  elif action=='campaigns.report':
   selected=next(x for x in state['campaigns'] if x['id']==i['id']);goal=selected.get('conversion_goal')=='todosantodia_signup'
   data={'deliveries':[],'events':[],'conversion_tracking_available':goal,'conversion_goal':selected.get('conversion_goal','none'),'challenge_signup_starts':2 if goal else 0,'source_started_at':'2026-09-25T09:00:00-03:00'}
  self.send_response(200);self.send_header('Content-Type','application/json');self.end_headers();self.wfile.write(json.dumps({'SUCCESS':True,'DATA':data}).encode())
ThreadingHTTPServer(('127.0.0.1',8768),Handler).serve_forever()
