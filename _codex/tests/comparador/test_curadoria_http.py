"""Real Business session/CSRF/form tests. Private loopback synthetic harness only.

Run service tests separately, then this file, with no concurrent curation writers.
The helper restores the original config/flags and deletes only receipt-tracked audits.
No production URL, cookies, identities or credentials may be passed here.
"""
import html
import http.cookiejar
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from html.parser import HTMLParser

BASE = os.environ.get('CURADORIA_HTTP_BASE', 'http://127.0.0.1:18500/codex-comparador-20261016/business/').rstrip('/') + '/'
if urllib.parse.urlsplit(BASE).hostname not in {'127.0.0.1', 'localhost', '::1'}:
    raise SystemExit('Only a loopback synthetic Business harness is allowed')
HELPER = os.environ.get('CURADORIA_HTTP_HELPER', '_codex/tests/comparador/curadoria-http-state.cfm')
PAGE = 'administracao/comparador/curadoria/index.cfm'
ACTOR = int(os.environ.get('CURADORIA_HTTP_ADMIN_ACTOR', '99'))
RUN = uuid.uuid4().hex
results = []


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def session():
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()), NoRedirect())


def request(opener, path, data=None, headers=None):
    payload = urllib.parse.urlencode(data, doseq=True).encode() if data is not None else None
    req = urllib.request.Request(BASE + path, payload, headers or {})
    try:
        with opener.open(req, timeout=60) as response:
            return response.status, response.read().decode(), dict(response.headers)
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode(), dict(error.headers)


def check(name, ok, detail=''):
    results.append({'name': name, 'pass': bool(ok), 'detail': detail[:1200] if not ok else ''})
    print(('PASS' if ok else 'FAIL'), name, flush=True)
    if not ok:
        raise AssertionError(name + ': ' + detail[:1200])


def hidden(body, name):
    found = re.search(r'name="' + re.escape(name) + r'" value="([^"]*)"', body)
    check('Hidden field ' + name + ' exists', found is not None)
    return html.unescape(found.group(1))


class Inputs(HTMLParser):
    def __init__(self):
        super().__init__()
        self.checkboxes = {}

    def handle_starttag(self, tag, attrs):
        fields = dict(attrs)
        if tag == 'input' and fields.get('type') == 'checkbox':
            self.checkboxes[fields['name']] = fields.get('value', '')


fixture_client = session()


def fixture(action, **fields):
    status, body, _ = request(fixture_client, HELPER, dict(fields, action=action, run=RUN))
    if status != 200:
        raise AssertionError('Private state helper ' + action + ': ' + str(status) + ' ' + body[:1200])
    # Adobe CF may serialize struct keys in uppercase; normalize recursively for assertions.
    def normalize(value):
        if isinstance(value, dict):
            return {key.lower(): normalize(item) for key, item in value.items()}
        if isinstance(value, list):
            return [normalize(item) for item in value]
        return value
    return normalize(json.loads(body))


def state():
    return fixture('inspect')


def post_and_record(fields, tab):
    previous = state()['token']
    fields = dict(fields)
    fields.pop('formulario_completo', None)
    fields['formulario_completo'] = 'curadoria'
    status, body, headers = request(admin, PAGE + '?aba=' + tab, fields)
    check('Valid ' + tab + ' POST uses PRG', status == 302, str(status) + ' ' + body)
    fixture('record', before_token=previous)
    return headers


prepared = False
print('Private curation HTTP run', RUN, flush=True)
try:
    for role, expected in [('anonymous', 302), ('common', 403), ('account', 403), ('delegated', 403), ('simulated', 403), ('admin', 200)]:
        client = session()
        if role != 'anonymous':
            request(client, 'harness/login.cfm', {'role': role})
        for tab in ['marcas', 'home', 'historico']:
            status, body, _ = request(client, PAGE + '?aba=' + tab)
            check('Authorization ' + role + '/' + tab, status == expected, str(status) + ' ' + body)
        if role == 'admin':
            admin = client

    status, body, _ = request(session(), PAGE, headers={'Cookie': 'id_usuario=99; is_admin=true'})
    check('Forged legacy cookies do not authenticate', status == 302, str(status) + ' ' + body)
    for name in ['backend.cfm', 'home.cfm']:
        status, body, _ = request(admin, 'administracao/comparador/curadoria/' + name)
        check('Direct include ' + name + ' is blocked', status == 403, str(status) + ' ' + body)
    status, body, _ = request(admin, PAGE + '?aba=not-a-tab')
    check('Unknown tab falls back to brands', status == 200 and 'Salvar marcas' in body, str(status) + ' ' + body)

    setup = fixture('setup', actor=ACTOR)
    prepared = True
    check('Payload fixture has at least 59 brands', setup['brand_count'] >= 59)
    status, body, _ = request(admin, PAGE + '?aba=home')
    check('Home labels are usable without JavaScript', status == 200 and 'Lançamentos por ciclo' in body and 'Produtos com oferta por ciclo' in body)
    csrf = hidden(body, 'csrf_token')
    initial = state()
    fields = {'acao': 'home', 'csrf_token': csrf, 'token': initial['token'], 'lancamentos_por_ciclo': '10', 'ofertas_por_ciclo': '1', 'formulario_completo': 'curadoria'}
    status, body, _ = request(admin, PAGE + '?aba=home', dict(fields, csrf_token='forged'))
    check('Invalid CSRF is forbidden', status == 403, str(status) + ' ' + body)
    check('Invalid CSRF does not change state', state()['token'] == initial['token'])
    status, body, _ = request(admin, PAGE + '?aba=home&acao=home&lancamentos_por_ciclo=10&ofertas_por_ciclo=10')
    check('GET action cannot mutate', status == 200 and state()['token'] == initial['token'])
    for value in ['0', '11', '1.5', '-1']:
        status, body, _ = request(admin, PAGE + '?aba=home', dict(fields, lancamentos_por_ciclo=value))
        check('Invalid ratio ' + value + ' returns 422', status == 422, str(status) + ' ' + body)
        check('Current complete invalid form stays reusable without changing token', 'name="acao"' in body and hidden(body, 'token') == initial['token'])
        check('Invalid ratio preserves config/history', state()['token'] == initial['token'] and state()['audits_recorded'] == 0)
    duplicate_ratio = list(fields.items()) + [('lancamentos_por_ciclo', '2')]
    status, body, _ = request(admin, PAGE + '?aba=home', duplicate_ratio)
    check('Repeated ratio field is rejected', status == 422, str(status) + ' ' + body)

    post_and_record(fields, 'home')
    changed = state()
    check('Home ratio is persisted', changed['data']['home']['lancamentos_por_ciclo'] == 10 and changed['data']['home']['ofertas_por_ciclo'] == 1)
    status, body, _ = request(admin, PAGE + '?aba=home', fields)
    check('Stale home submission returns 409 without reusable curation form', status == 409 and 'name="acao"' not in body and 'Reabrir configuração' in body, str(status) + ' ' + body)
    check('Stale submission does not change state', state()['token'] == changed['token'])
    status, body, _ = request(admin, PAGE + '?aba=home', dict(fields, lancamentos_por_ciclo='0'))
    check('Stale invalid ratio cannot receive a fresh token', status == 409 and 'name="acao"' not in body and 'Reabrir configuração' in body, str(status) + ' ' + body)
    check('Stale invalid ratio preserves current state', state()['token'] == changed['token'])
    status, body, _ = request(admin, PAGE + '?aba=home', dict(fields, token=changed['token'], lancamentos_por_ciclo='0'))
    check('Current complete invalid ratio remains editable with original token', status == 422 and 'name="acao"' in body and hidden(body, 'token') == changed['token'], str(status) + ' ' + body)
    incomplete_home = dict(fields, token=changed['token'])
    incomplete_home.pop('formulario_completo')
    status, body, _ = request(admin, PAGE + '?aba=home', incomplete_home)
    check('Incomplete current home form is not made reusable', status == 422 and 'name="acao"' not in body, str(status) + ' ' + body)

    def brand_page(number):
        status, body, _ = request(admin, PAGE + '?aba=marcas&pagina=' + str(number))
        check('Brand page ' + str(number) + ' renders', status == 200, str(status) + ' ' + body)
        parser = Inputs()
        parser.feed(body)
        scope = hidden(body, 'escopo_tags')
        check('Page has at most 30 brands and explicit true values', 0 < len(parser.checkboxes) <= 60 and all(value == 'true' for value in parser.checkboxes.values()))
        return {'body': body, 'checkboxes': parser.checkboxes, 'scope': scope, 'token': hidden(body, 'token'), 'csrf': hidden(body, 'csrf_token')}

    first_page = brand_page(1)
    page_count = (len(state()['data']['marcas']) + 29) // 30
    check('At least two pages for the real brand count', page_count >= 2)
    check('Brand names are escaped', '&lt;teste&gt;' in first_page['body'] and '<teste>' not in first_page['body'])
    check('Pagination warns to save before changing pages', 'Salve as alterações desta página' in first_page['body'] and 'Próxima' in first_page['body'])
    stale_second_page = brand_page(2)
    all_checkbox_values = {}
    for brand in state()['data']['marcas']:
        all_checkbox_values['destaque_' + brand['tag_marca']] = 'true'
        all_checkbox_values['brasil_' + brand['tag_marca']] = 'true'
    oversized = {'acao': 'marcas', 'csrf_token': csrf, 'token': first_page['token'], 'escopo_tags': first_page['scope'], **all_checkbox_values, 'formulario_completo': 'curadoria'}
    before_oversized = state()['token']
    check('Regression payload exceeds 121 raw fields, sentinel is last', len(oversized) >= 121 and list(oversized)[-1] == 'formulario_completo')
    status, body, _ = request(admin, PAGE + '?aba=marcas&pagina=1', oversized)
    check('Oversized raw payload is rejected by Tomcat', status == 400 and 'POST parameters exceeds' in body, str(status) + ' ' + body)
    check('Truncated oversized POST cannot mutate despite CF execution', state()['token'] == before_oversized)

    for number in range(1, page_count + 1):
        page_data = brand_page(number)
        previous_brands = {brand['tag_marca']: brand for brand in state()['data']['marcas']}
        flags = {'acao': 'marcas', 'csrf_token': page_data['csrf'], 'token': page_data['token'], 'escopo_tags': page_data['scope'], **page_data['checkboxes']}
        check('Paginated form stays below global parameter limit', len(flags) + 1 <= 65)
        headers = post_and_record(flags, 'marcas&pagina=' + str(number))
        location = next((value for key, value in headers.items() if key.lower() == 'location'), '')
        check('PRG preserves current brand page', 'pagina=' + str(number) in location)
        updated = state()
        scope_tags = set(page_data['scope'].split(','))
        for brand in updated['data']['marcas']:
            if brand['tag_marca'] in scope_tags:
                check('Current page flag persisted: ' + brand['tag_marca'], brand['destaque'] and brand['presente_brasil'])
            else:
                check('Other-page flags unchanged: ' + brand['tag_marca'], brand == previous_brands[brand['tag_marca']])
        if number == 1:
            stale_flags = {'acao': 'marcas', 'csrf_token': stale_second_page['csrf'], 'token': stale_second_page['token'], 'escopo_tags': stale_second_page['scope'], 'formulario_completo': 'curadoria'}
            status, body, _ = request(admin, PAGE + '?aba=marcas&pagina=2', stale_flags)
            check('Page two uses global token and rejects stale submission', status == 409 and 'name="acao"' not in body and 'pagina=2' in body, str(status) + ' ' + body)

    all_state = state()
    check('All brands can be enabled through independent paginated saves', all(brand['destaque'] and brand['presente_brasil'] for brand in all_state['data']['marcas']))
    page_data = brand_page(1)
    tag_a, tag_b = page_data['scope'].split(',')[:2]
    independent = {'acao': 'marcas', 'csrf_token': csrf, 'token': page_data['token'], 'escopo_tags': page_data['scope'], 'destaque_' + tag_a: 'true', 'brasil_' + tag_b: 'true'}
    post_and_record(independent, 'marcas&pagina=1')
    independent_state = state()
    lookup = {brand['tag_marca']: brand for brand in independent_state['data']['marcas']}
    check('Featured flag does not require Brazil presence', lookup[tag_a]['destaque'] and not lookup[tag_a]['presente_brasil'])
    check('Brazil presence does not require featured flag', lookup[tag_b]['presente_brasil'] and not lookup[tag_b]['destaque'])
    check('Flags from page two survive saving page one', all(brand['destaque'] and brand['presente_brasil'] for brand in independent_state['data']['marcas'] if brand['tag_marca'] not in page_data['scope'].split(',')))
    base_flags = {'acao': 'marcas', 'csrf_token': csrf, 'token': independent_state['token'], 'escopo_tags': page_data['scope'], 'formulario_completo': 'curadoria'}
    for key, value in [('destaque_unknown-test-brand', 'true'), ('destaque_' + tag_a, 'false'), ('brasil_' + tag_b, 'true,true')]:
        status, body, _ = request(admin, PAGE + '?aba=marcas&pagina=1', dict(base_flags, **{key: value}))
        check('Malformed brand field is rejected: ' + key, status == 422, str(status) + ' ' + body)
        check('Malformed brand field preserves state', state()['token'] == independent_state['token'])
    outside_tag = next(brand['tag_marca'] for brand in independent_state['data']['marcas'] if brand['tag_marca'] not in page_data['scope'].split(','))
    status, body, _ = request(admin, PAGE + '?aba=marcas&pagina=1', dict(base_flags, **{'destaque_' + outside_tag: 'true'}))
    check('Known brand outside page scope is rejected', status == 422, str(status) + ' ' + body)
    for scope in ['', tag_a + ',' + tag_a, ','.join([tag_a] * 31)]:
        status, body, _ = request(admin, PAGE + '?aba=marcas&pagina=1', dict(base_flags, escopo_tags=scope))
        check('Invalid page scope rejected', status == 422, str(status) + ' ' + body)
    status, body, _ = request(admin, PAGE + '?aba=marcas&pagina=1', list(base_flags.items()) + [('destaque_' + tag_a, 'true'), ('destaque_' + tag_a, 'true')])
    check('Duplicate checkbox field is rejected by actual CF parser', status == 422, str(status) + ' ' + body)
    incomplete = dict(base_flags)
    incomplete.pop('formulario_completo')
    status, body, _ = request(admin, PAGE + '?aba=marcas&pagina=1', incomplete)
    check('Missing completion sentinel is rejected without reusable form', status == 422 and 'name="acao"' not in body, str(status) + ' ' + body)
    check('Malformed requests did not change state', state()['token'] == independent_state['token'])
    for number in range(1, page_count + 1):
        page_data = brand_page(number)
        post_and_record({'acao': 'marcas', 'csrf_token': page_data['csrf'], 'token': page_data['token'], 'escopo_tags': page_data['scope']}, 'marcas&pagina=' + str(number))
    check('Clearing every page removes optional rows', state()['optional_rows'] == 0)
    status, body, _ = request(admin, PAGE + '?aba=historico')
    check('History summarizes proportions and changed flags', status == 200 and 'Proporção:' in body and 'Destaque antes' in body and 'Brasil antes' in body)
    check('History does not show raw snapshot JSON', '<pre' not in body and '"tag_marca"' not in body and '&quot;tag_marca&quot;' not in body)
    check('Curadoria is reachable through module navigation', 'href="/administracao/comparador/curadoria/"' in body)
finally:
    if prepared:
        restored = fixture('cleanup')
        check('Original curation state restored; only tracked audits removed', restored.get('restored') is True)
    report = {'passed': sum(result['pass'] for result in results), 'failed': sum(not result['pass'] for result in results), 'results': results}
    print(json.dumps(report, ensure_ascii=False))

sys.exit(bool(report['failed']))
