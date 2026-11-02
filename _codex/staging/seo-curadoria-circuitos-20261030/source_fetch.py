from pathlib import Path
import urllib.request,hashlib,json
S=Path(__file__).resolve().parent
urls={'curitiba-regulation':'https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/86884/96bd2ae84b2848af9665c2c15721e39f639270721352025193.pdf','monumental-regulation':'https://maratonamonumentalbsb.com.br/wp-content/uploads/2026/07/v6-REGULAMENTO-MARATONA-MONUMENTAL-2026.pdf','floripa-regulation':'https://storagefileta.blob.core.windows.net/ticketagora/arquivos/evento/88278/981d4d32a3fa41f499ed30cd8878329c639251782889640084.pdf'}
out=[]
for name,url in urls.items():
 with urllib.request.urlopen(url,timeout=30) as r:data=r.read()
 assert data.startswith(b'%PDF');(S/(name+'.pdf')).write_bytes(data);out.append({'name':name,'url':url,'sha256':hashlib.sha256(data).hexdigest()})
(S/'sources-pdf.json').write_text(json.dumps(out,indent=2));print(json.dumps(out))
