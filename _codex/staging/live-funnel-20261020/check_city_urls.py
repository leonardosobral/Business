from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import csv,html,json,re,subprocess,tempfile
p=Path(__file__).resolve().parent;d=json.loads((p/'city-matrix-read.json').read_text());events=d['events']
def check(e):
 url='https://roadrunners.run/evento/'+e['tag']+'/'
 with tempfile.TemporaryDirectory(prefix='live-url-check-') as t:
  dest=Path(t)/'page.html'
  result=subprocess.run(['curl','-L','-sS','--max-time','45','-A','Mozilla/5.0','-o',str(dest),'-w','%{json}',url],capture_output=True,text=True,timeout=50)
  meta=json.loads(result.stdout) if result.stdout else {};body=dest.read_text(errors='replace') if dest.exists() else ''
  title=re.search(r'<title[^>]*>(.*?)</title>',body,re.I|re.S)
  canonical=re.search(r'<link\b[^>]*rel=["\']canonical["\'][^>]*href=["\']([^"\']+)',body,re.I)
  coupons=[c for c in e.get('coupons') or [] if c.get('valid_today')]
  linked=any(l['tipo']=='circuito' and l['canonical_tag']=='live-run-xp' for l in e.get('circuit_links') or [])
  chosen=e['id_evento'] not in [45366,48557]
  return dict(id=e['id_evento'],tag=e['tag'],city=e['cidade'],uf=e['estado'],date=e['data_inicial'],selected=chosen,canonical_circuit=linked,coupon='; '.join(c['cupom'] for c in coupons),discount='; '.join(c['condicoes'] for c in coupons),coupon_window_end='; '.join(c['data_validade_fim'] for c in coupons),coupon_master_expiry='; '.join(c['data_expiracao'] for c in coupons),road_runners_url=url,http_status=meta.get('http_code'),final_url=meta.get('url_effective'),title=html.unescape(title.group(1)) if title else '',canonical_url=html.unescape(canonical.group(1)) if canonical else '',coupon_in_html=bool(re.search(r'data-mdb-id-cupom=["\']68["\']|data-live-coupon-view=["\']'+str(e['id_evento'])+r'["\']',body)),coupon_targets=e.get('coupon_targets') or [],registration_url=e['url_inscricao'],official_url=e['url_hotsite'],request_error=result.stderr[:500],status='selected' if chosen else ('duplicate_without_circuit_or_coupon' if e['id_evento']==45366 else 'blocked_missing_circuit_and_coupon'))
with ThreadPoolExecutor(max_workers=3) as ex:rows=list(ex.map(check,events))
(p/'city-matrix.json').write_text(json.dumps({'observed_at':d['observed_at'],'scope':'Current catalog and coupon view; no registration/checkout tested; HTTP GET without UTM or JavaScript','events':rows},ensure_ascii=False,indent=2))
with (p/'city-matrix.csv').open('w',newline='') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
print(json.dumps([{k:r[k] for k in ['id','city','date','selected','canonical_circuit','coupon','discount','http_status','final_url','title','coupon_in_html','status']} for r in rows],ensure_ascii=False,indent=2))
