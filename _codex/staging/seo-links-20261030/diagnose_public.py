from pathlib import Path
from html import unescape
import urllib.request,urllib.error,json,re
S=Path(__file__).resolve().parent
slug='ranking-2026-atualizado-com-as-maratonas-fila-sp-sao-jose-criciuma-piracicaba-salvador-niteroi-pelotas-bonito-jurere-sta-maria-foz-e-pomerode'
urls=['https://roadrunners.run/noticias/'+slug+'/', 'https://conteudo.roadrunners.run/rest/cmscf_api/v1/content/'+slug, 'https://roadrunners.run/noticias/?page=2','https://roadrunners.run/noticias/canal/contra-relogio/']
report=[]
for url in urls:
 try:
  with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'RunnerHub-SEO-Validation/1.0'}),timeout=30) as r:status=r.status;body=r.read().decode();headers=r.headers
 except urllib.error.HTTPError as e:status=e.code;body=e.read().decode();headers=e.headers
 row={'url':url,'status':status,'contentType':headers.get('Content-Type',''),'bytes':len(body.encode())}
 if 'conteudo.roadrunners' in url:
  try:
   data=json.loads(body);row['keys']=list(data);row['publicMetadata']={k:data[k] for k in ['id','slug','title','status','published_at','original_url','publication_mode','authorized_republication','error','message','detail'] if k in data and not isinstance(data[k],(dict,list))};row['content_type']=data.get('content_type');row['contentLength']=len(str(data.get('content','')))
  except ValueError:row['json']=False
 else:
  row['title']=(re.search(r'<title>(.*?)</title>',body,re.S).group(1) if '<title>' in body else '')
  row['sourceArticleStillLinked']=slug in unescape(body)
 report.append(row)
(S/'public-diagnostic.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report,ensure_ascii=False))
