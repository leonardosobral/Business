"""Read-only HEAD checks of candidate PDF links; do not follow login redirects."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json
import urllib.request
import urllib.error

HERE = Path(__file__).resolve().parent
report = json.loads((HERE/'verification.json').read_text())
urls = sorted({link['url'] for pdf in report['candidates'] for link in pdf['links']})

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def check(url):
    request = urllib.request.Request(url, method='HEAD', headers={'User-Agent':'RunnerHub-PDF-QA/20261109'})
    opener = urllib.request.build_opener(NoRedirect)
    try:
        response = opener.open(request, timeout=20)
        return {'url': url, 'status': response.status, 'location': response.headers.get('Location')}
    except urllib.error.HTTPError as error:
        return {'url': url, 'status': error.code, 'location': error.headers.get('Location')}
    except Exception as error:
        return {'url': url, 'error': str(error)}

with ThreadPoolExecutor(max_workers=5) as executor:
    result = list(executor.map(check, urls))
(HERE/'http-links.json').write_text(json.dumps({'method':'HEAD, redirects disabled, no credentials', 'links':result}, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(result, ensure_ascii=False))
