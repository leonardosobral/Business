"""Scoped palette correction. Does not change selectors, layout or application logic."""
import hashlib,json,pathlib,re,sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
CSS=[
'assets/css/business-ui.css','assets/css/admin-suite.css','assets/css/admin-dashboard.css','assets/css/audience-dashboard.css','assets/css/portal-banner-dashboard.css','assets/css/paid-banner-workspace.css',
'helpdesk/assets/workspace.css','administracao/drive/assets/drive.css','administracao/agenda/assets/agenda.css','administracao/kanban/assets/kanban.css','administracao/ai-mails/assets/ai-mails.css','administracao/consumo-openai/assets/usage.css','administracao/vicky/assets/audit.css','administracao/chat/grupos-especiais/assets/manager.css',
'saude-eventos/assets/saude-eventos.css','saude-eventos/central/assets/saude-panel.css','portal/erros/assets/triage.css','portal/funil/assets/funil.css','portal/seo/assets/ga4.css','administracao/geolocalizacao/assets/review-guide.css','cupons-rr/assets/manager.css','desafios/assets/catarinense-contact.css']
INLINE=['administracao/cron-jobs/home.cfm','administracao/usuarios/home.cfm','administracao/vicky/index.cfm','administracao/vicky/home.cfm','portal/eventos-analytics/home.cfm','portal/conteudo/seo.cfm','portal/agendas/home.cfm','portal/conteudos/preview.cfm']
VERSION='rr-neutral-20261026'
sha=lambda b:hashlib.sha256(b).hexdigest()
BRAND='var(--business-accent, #f4b120)'
EXPLICIT={
 'helpdesk/assets/workspace.css':{'#90b7ff':BRAND,'#a7c4ff':'#dedede'},
 'assets/css/audience-dashboard.css':{'#81b8f4':'#bdbdbd'},
 'assets/css/portal-banner-dashboard.css':{'#62c7d8':BRAND},
 'assets/css/paid-banner-workspace.css':{'#62c7d8':BRAND},
 'administracao/agenda/assets/agenda.css':{'#65b9d4':BRAND,'#70c8e2':BRAND,'#8ed0e4':BRAND},
 'administracao/drive/assets/drive.css':{'#4285f426':'rgba(244,177,32,.15)','#72a4f7':BRAND,'#8ab4f8':BRAND},
 'administracao/ai-mails/assets/ai-mails.css':{'#89b8f8':'#bdbdbd','#a8ceff':'#dedede'},
 'saude-eventos/central/assets/saude-panel.css':{'#57a9ff':'#bdbdbd','#b9d9ff':'#dedede','#8ec6ff':BRAND,'#7ebcff':'#bdbdbd'},
}
HEX=re.compile(r'#[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?\b')
RGB=re.compile(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(\s*,\s*[.\d]+)?\s*\)',re.I)
def gray(r,g,b):return round(.2126*r+.7152*g+.0722*b)
def neutral_hex(value):
 c=value[1:];r,g,b=[int(c[i:i+2],16) for i in (0,2,4)]
 if r<=g<=b and 0<b-r<=70:
  v=gray(r,g,b);return '#'+f'{v:02x}'*3+c[6:]
 return value
def palette(text,path):
 for old,new in EXPLICIT.get(path,{}).items():text=re.sub(re.escape(old)+r'\b',lambda _:new,text,flags=re.I)
 def rgb(m):
  r,g,b=map(int,m.group(1,2,3));alpha=m.group(4) or ''
  if r<=g<=b and 0<b-r<=110:r=g=b=gray(r,g,b)
  elif (r,g,b) in [(246,195,91),(250,177,32),(239,187,85),(245,173,22),(98,199,216)]:r,g,b=244,177,32
  elif path=='helpdesk/assets/workspace.css' and (r,g,b)==(87,144,252):r=g=b=255
  elif path=='saude-eventos/central/assets/saude-panel.css' and (r,g,b)==(87,169,255):r=g=b=255
  else:return m.group(0)
  return ('rgba' if alpha else 'rgb')+f'({r},{g},{b}{alpha})'
 text=RGB.sub(rgb,HEX.sub(lambda m:neutral_hex(m.group(0)),text))
 # Module brand variables now follow the existing RR yellow, never status colors.
 text=re.sub(r'(--(?:hd-accent|admin-suite-accent|gd-accent|aud-gold|kanban-accent|vp-accent|saude-accent)\s*:)\s*#[0-9a-fA-F]{6}',lambda m:m.group(1)+' '+BRAND,text)
 if path=='helpdesk/assets/workspace.css':
  text=re.sub(r'--hd-panel:[^;]+', '--hd-panel:var(--business-panel, #262626)',text)
  text=re.sub(r'--hd-muted:[^;]+', '--hd-muted:var(--business-muted, #bdbdbd)',text)
 if path=='assets/css/admin-suite.css':text=re.sub(r'--admin-suite-surface:[^;]+','--admin-suite-surface: var(--business-panel, #262626)',text)
 if path=='assets/css/admin-dashboard.css':text=re.sub(r'--gd-bg:[^;]+','--gd-bg: var(--business-panel, #262626)',text)
 if path=='saude-eventos/central/assets/saude-panel.css':
  for token,value in [('bg','var(--business-background, #222222)'),('panel','var(--business-panel, #262626)'),('panel-soft','#303030'),('muted','#bdbdbd')]:text=re.sub(r'--saude-'+token+r':[^;]+','--saude-'+token+': '+value,text)
 return text
def build():
 changes={}
 for rel in CSS:
  p=ROOT/rel;old=p.read_text();new=palette(old,rel)
  if rel=='assets/css/business-ui.css':
   new=new.replace(':root {',':root {\n    /* RR identity: neutral surfaces, white text and the base yellow. */\n    --business-background: #222222;\n    --business-panel: #262626;\n    --business-field: #1f1f1f;\n    --business-muted: #bdbdbd;\n    --business-accent: var(--rh-yellow, #f4b120);',1)
  if old!=new:changes[rel]=(old,new)
 for rel in INLINE:
  old=(ROOT/rel).read_text();new=re.sub(r'(<style[^>]*>)(.*?)(</style>)',lambda m:m[1]+palette(m[2],rel)+m[3],old,flags=re.I|re.S)
  if old!=new:changes[rel]=(old,new)
 changed_css=[rel for rel in changes if rel.endswith('.css')]
 for p in ROOT.rglob('*.cfm'):
  rel=str(p.relative_to(ROOT))
  if any(part.startswith('.') or part=='_codex' for part in p.relative_to(ROOT).parts):continue
  old=changes.get(rel,(p.read_text(errors='strict'),))[0];new=changes.get(rel,(old,old))[1]
  for css in changed_css:
   # Resolve absolute or module-relative stylesheets; touch only link hrefs.
   def bust(m):
    url=m[2].split('?')[0]
    target=(ROOT/url.lstrip('/')).resolve() if url.startswith('/') else (p.parent/url).resolve()
    return m[1]+url+'?v='+VERSION+m[3] if target==(ROOT/css).resolve() else m[0]
   new=re.sub(r'(<link\b[^>]*\bhref=["\'])([^"\']+\.css(?:\?[^"\']*)?)(["\'])',bust,new,flags=re.I)
  if new!=old:changes[rel]=(old,new)
 return changes
def structural_signature(text,rel):
 if rel.endswith('.cfm'):
  text=re.sub(r'<style[^>]*>.*?</style>','<style/>',text,flags=re.I|re.S)
  return re.sub(r'(<link\b[^>]*\bhref=["\'][^"\']+\.css)\?[^"\']*',r'\1',text,flags=re.I)
 if rel=='assets/css/business-ui.css':
  text=re.sub(r'/\* RR identity:.*?\*/','',text)
  text=re.sub(r'--business-(?:background|panel|field|muted|accent):[^;]+;','',text)
 text=re.sub(r'var\(--business-(?:accent|panel|muted|background),\s*#[0-9a-fA-F]{6}\)','#COLOR',text)
 text=HEX.sub('#COLOR',text);text=RGB.sub('#COLOR',text)
 return re.sub(r'\s+','',text)
if __name__=='__main__':
 changes=build();audit={}
 for rel,(old,new) in changes.items():
  if structural_signature(old,rel)!=structural_signature(new,rel):raise SystemExit('Non-palette change: '+rel)
  audit[rel]={'before':sha(old.encode()),'after':sha(new.encode()),'structure_preserved':True}
 if '--apply' in sys.argv:
  path=ROOT/'_codex/deploy/rr-neutral-baseline-20261026.json'
  if path.exists():raise SystemExit('Baseline already exists; do not reapply')
  path.write_text(json.dumps(audit,indent=2)+'\n')
  for rel,(_,new) in changes.items():(ROOT/rel).write_text(new)
 print(json.dumps({'files':len(audit),'paths':list(audit)},indent=2))
