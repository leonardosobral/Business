"""Controlled, GET-only production check. Never executes JS or sends audience events."""
import json, re, urllib.request

origin='https://roadrunners.run'
headers={'User-Agent':'Mozilla/5.0 (RunnerHub deployment verification; GET-only)'}
def fetch(path,uf):
    cookie='pais=BR; uf='+uf+'; estado='+('Santa%20Catarina' if uf=='SC' else 'Sao%20Paulo')+'; cidade=; location_source=primary'
    request=urllib.request.Request(origin+path,headers={**headers,'Cookie':cookie})
    with urllib.request.urlopen(request,timeout=25) as response:
        assert response.status==200
        return response.read().decode('utf-8'),response.headers.get_all('Set-Cookie',[])
home,_=fetch('/','SC')
paths=re.findall(r'href=[\'"](/evento/[a-zA-Z0-9_-]+/)[\'"]',home)
assert paths,'The homepage must supply a real public event URL'
path=paths[0]
for expected in ['SC','SP']:
    html,cookies=fetch(path,expected)
    match=re.search(r'window\.RoadRunnersAudienceConfig=(\{.*?\});</script>',html,re.S)
    assert match,'Real event response must contain the audience context'
    data=json.loads(match[1]);context=data['context']
    assert context['pageFamily']=='event' and context['visitorUf']==expected
    assert data['contextToken'] and data['signature']
    assert not any(re.match(r'(pais|uf|estado|cidade|location_source)=',c,re.I) for c in cookies), 'Event hydration must not renew location cookies'
    print(json.dumps({'path':path,'status':200,'visitorUf':context['visitorUf'],'contextUf':context['contextUf'],'marketUf':context['marketUf'],'locationCookiesWritten':False,'audienceEventsSent':0}))
