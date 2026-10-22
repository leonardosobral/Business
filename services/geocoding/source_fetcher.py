"""Bounded public event-source reader. No secrets, shell, cookies or dependencies.

CLI input is one base64 JSON argument; output is JSON. The caller caches evidence
and robots rules. Every socket is pinned to a validated public DNS address and
TLS still verifies the original hostname. HTML and PDF are inert source data.
"""
import base64
import hashlib
import html
from html.parser import HTMLParser
import http.client
import ipaddress
import json
import re
import signal
import socket
import ssl
import sys
import time
import urllib.parse
import urllib.robotparser

AGENT = 'RunnerHub-Geolocation/2.0'
HTML_LIMIT = 1024 * 1024
PDF_LIMIT = 3 * 1024 * 1024
TOTAL_LIMIT = 8 * 1024 * 1024


def normalize_url(value, base=''):
    if not isinstance(value, str) or len(value) > 2048 or re.search(r'[\x00-\x20\x7f\\]', value):
        raise ValueError('unsafe_url')
    value = urllib.parse.urljoin(base, html.unescape(value)) if base else html.unescape(value)
    parts = urllib.parse.urlsplit(value)
    if parts.scheme not in ('http', 'https') or parts.username is not None or parts.password is not None:
        raise ValueError('unsafe_url')
    host = (parts.hostname or '').lower().rstrip('.')
    if parts.port not in (None, 80 if parts.scheme == 'http' else 443):
        raise ValueError('unsafe_port')
    # IP literals, local search suffixes and same-service endpoints are not event sources.
    if not re.fullmatch(r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}', host):
        raise ValueError('unsafe_host')
    if host.endswith(('.localhost', '.local', '.internal', '.test', '.onion')) or host in (
            'localhost', 'business.roadrunners.run', 'api.geoapify.com', 'api.openai.com'):
        raise ValueError('unsafe_host')
    for key, _ in urllib.parse.parse_qsl(parts.query):
        if re.search(r'(?:token|secret|password|credential|authorization|api_?key|signature|session)', key, re.I):
            raise ValueError('credential_url')
    return urllib.parse.urlunsplit(('https', host, parts.path or '/', parts.query, ''))


def public_addresses(host):
    rows = socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM)
    addresses = list(dict.fromkeys(row[4][0] for row in rows))
    if not addresses or any(not ipaddress.ip_address(ip).is_global or ipaddress.ip_address(ip).is_multicast
                            or getattr(ipaddress.ip_address(ip), 'ipv4_mapped', None)
                            for ip in addresses):
        raise ValueError('nonpublic_dns')
    return addresses


class PinnedHTTPSConnection(http.client.HTTPSConnection):
    def __init__(self, host, address, **kwargs):
        self.pinned_address = address
        super().__init__(host, **kwargs)

    def connect(self):
        raw = socket.create_connection((self.pinned_address, 443), self.timeout)
        try:
            self.sock = self._context.wrap_socket(raw, server_hostname=self.host)
        except BaseException:
            raw.close()
            raise


def read_limited(response, limit):
    chunks = []; size = 0
    while True:
        chunk = response.read(min(65536, limit - size + 1))
        if not chunk:
            return b''.join(chunks)
        size += len(chunk)
        if size > limit:
            raise ValueError('document_too_large')
        chunks.append(chunk)


def fetch_document(url, deadline, max_bytes=PDF_LIMIT, authorize=None):
    for _ in range(4):
        url = normalize_url(url)
        if time.monotonic() >= deadline:
            raise ValueError('source_time_budget')
        if authorize is not None:
            authorize(url)
        parts = urllib.parse.urlsplit(url)
        address = public_addresses(parts.hostname)[0]
        connection = PinnedHTTPSConnection(parts.hostname, address,
                                          timeout=max(.1, min(3, deadline-time.monotonic())),
                                          context=ssl.create_default_context())
        try:
            connection.request('GET', urllib.parse.urlunsplit(('', '', parts.path, parts.query, '')),
                               headers={'User-Agent':AGENT, 'Accept':'text/html,application/pdf,text/plain;q=0.8',
                                        'Accept-Encoding':'identity', 'Connection':'close'})
            response = connection.getresponse()
            if response.status in (301, 302, 303, 307, 308):
                url = normalize_url(response.getheader('Location', ''), url)
                continue
            if response.status != 200:
                raise ValueError('source_http_' + str(response.status))
            content_type = response.getheader('Content-Type', '').split(';')[0].lower()
            if content_type not in ('text/html', 'application/xhtml+xml', 'application/pdf', 'text/plain'):
                raise ValueError('unsupported_content_type')
            if response.getheader('Content-Encoding', 'identity').lower() not in ('', 'identity'):
                raise ValueError('unsupported_encoding')
            limit = min(max_bytes, PDF_LIMIT if content_type == 'application/pdf' else HTML_LIMIT)
            length = response.getheader('Content-Length', '')
            if length.isdigit() and int(length) > limit:
                raise ValueError('document_too_large')
            body = read_limited(response, limit)
            return {'url':url, 'content_type':content_type, 'body':body,
                    'sha256':hashlib.sha256(body).hexdigest()}
        finally:
            connection.close()
    raise ValueError('too_many_redirects')


class EventHTML(HTMLParser):
    def __init__(self, url):
        super().__init__(convert_charrefs=True)
        self.url = url; self.text = []; self.title = []; self.links = []
        self.jsonld = []; self.hidden = 0; self.in_title = False
        self.script = None; self.script_text = []; self.anchor = None

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'script':
            self.script = attrs.get('type', '').lower(); self.script_text = []; self.hidden += 1
        elif tag in ('style', 'noscript', 'template', 'svg'):
            self.hidden += 1
        if tag == 'title': self.in_title = True
        if tag in ('p', 'div', 'li', 'h1', 'h2', 'h3', 'h4', 'br', 'tr', 'section') and not self.hidden:
            self.text.append('\n')
        if tag == 'a': self.anchor = [attrs.get('href', ''), []]
        if tag in ('iframe', 'embed', 'object'):
            value = attrs.get('src', attrs.get('data', ''))
            if value and re.search(r'(?:\.pdf(?:\?|$)|regulamento)', value, re.I):
                self.add_link(value, 'regulation')

    def handle_data(self, data):
        if self.script is not None:
            if sum(map(len, self.script_text)) < 200000: self.script_text.append(data)
        if self.hidden: return
        if self.in_title: self.title.append(data)
        if self.anchor is not None: self.anchor[1].append(data)
        self.text.append(data)

    def handle_endtag(self, tag):
        if tag == 'script':
            if self.script == 'application/ld+json':
                try: self.jsonld.append(json.loads(''.join(self.script_text)))
                except (ValueError, RecursionError): pass
            self.script = None; self.script_text = []; self.hidden = max(0, self.hidden-1)
        elif tag in ('style', 'noscript', 'template', 'svg'): self.hidden = max(0, self.hidden-1)
        if tag == 'title': self.in_title = False
        if tag == 'a' and self.anchor:
            href, words = self.anchor; label = ' '.join(words)
            if re.search(r'(?:regulamento|regulation|regras da prova|\.pdf(?:\?|$))', href + ' ' + label, re.I):
                self.add_link(href, 'regulation')
            elif re.search(r'(?:site oficial|website oficial|página oficial|pagina oficial|official website)', label, re.I):
                self.add_link(href, 'official')
            self.anchor = None
        if tag in ('p', 'div', 'li', 'h1', 'h2', 'h3', 'h4', 'tr', 'section') and not self.hidden:
            self.text.append('\n')

    def add_link(self, href, kind):
        try: url = normalize_url(href, self.url)
        except ValueError: return
        if len(self.links) < 12 and not any(link['url'] == url for link in self.links):
            self.links.append({'url':url, 'kind':kind})


def parse_html(body, url):
    parser = EventHTML(url)
    try: parser.feed(body[:HTML_LIMIT])
    except (ValueError, RecursionError): pass
    text = re.sub(r'[ \t\r\f\v]+', ' ', ''.join(parser.text))
    text = re.sub(r'\n\s*\n+', '\n', text)
    return {'text':text[:120000], 'title':''.join(parser.title)[:400],
            'links':parser.links, 'jsonld':parser.jsonld[:12]}


def robots_allowed(text, url):
    rules = urllib.robotparser.RobotFileParser()
    rules.parse(text.splitlines())
    return rules.can_fetch(AGENT, url)


def collect(payload):
    # CFML may serialize literal struct keys in upper case.
    payload = {key.lower(): value for key, value in payload.items()}
    deadline = time.monotonic() + 12
    queue = [(url, 0) for url in payload.get('urls', [])[:3]]
    pages = []; seen = set(); diagnostics = []; robots = {key.lower():value for key,value in payload.get('robots', {}).items()}
    total = 0; last_host = {}; requests = 0
    def authorize(url):
        host = urllib.parse.urlsplit(url).hostname
        if host not in robots:
            try:
                rule = fetch_document('https://' + host + '/robots.txt', min(deadline, time.monotonic()+2), 100000)
                rules = rule['body'].decode('utf-8', errors='replace')[:100000]
            except ValueError as error:
                if str(error) in ('source_http_404', 'source_http_410'):
                    rules = ''
                elif str(error) in ('source_http_401', 'source_http_403'):
                    rules = 'User-agent: *\nDisallow: /'
                else:
                    raise ValueError('source_unavailable') from error
            except Exception as error:
                # A temporary failure is not an authoritative prohibition and must not be cached.
                raise ValueError('source_unavailable') from error
            robots[host] = rules; last_host[host] = time.monotonic()
        if not robots_allowed(robots[host], url):
            raise ValueError('robots_disallowed')
        wait = 1 - (time.monotonic() - last_host.get(host, 0))
        if wait > 0:
            if time.monotonic()+wait >= deadline:
                raise ValueError('source_time_budget')
            time.sleep(wait)
        last_host[host] = time.monotonic()
    while queue and len(pages) < 4 and requests < 6 and time.monotonic() < deadline-.2:
        raw, depth = queue.pop(0)
        try:
            url = normalize_url(raw)
            if url in seen: continue
            seen.add(url)
            requests += 1
            document = fetch_document(url, deadline, authorize=authorize)
            total += len(document['body'])
            if total > TOTAL_LIMIT: raise ValueError('total_size_limit')
            page = {key:document[key] for key in ('url', 'sha256')}
            page['parent_url'] = url if depth else ''
            if document['content_type'] == 'application/pdf':
                if not document['body'].startswith(b'%PDF-'): raise ValueError('invalid_pdf')
                page.update(kind='pdf', pdf=base64.b64encode(document['body']).decode('ascii'))
            else:
                page.update(kind='html', **parse_html(document['body'].decode('utf-8', errors='replace'), document['url']))
                if depth < 2:
                    discovered = [(link['url'], depth+1) for link in page['links']]
                    queue = discovered[:4] + queue
            pages.append(page)
        except Exception as error:
            code = str(error) if isinstance(error, ValueError) else 'source_unavailable'
            diagnostics.append(code if re.fullmatch('[a-z0-9_]{1,60}', code) else 'source_unavailable')
    return {'pages':pages, 'diagnostics':list(dict.fromkeys(diagnostics))[:12], 'robots':robots,
            'documents':len(pages), 'version':2}


def main():
    def timeout(*_): raise TimeoutError('source_time_budget')
    signal.signal(signal.SIGALRM, timeout)
    signal.alarm(13)
    try:
        if len(sys.argv) != 2 or len(sys.argv[1]) > 400000:
            raise ValueError('invalid_input')
        payload = json.loads(base64.b64decode(sys.argv[1], validate=True))
        if not isinstance(payload, dict): raise ValueError('invalid_input')
        result = collect(payload)
    except Exception:
        result = {'pages':[], 'diagnostics':['source_unavailable'], 'robots':{}, 'version':2}
    print(json.dumps(result, ensure_ascii=True))


if __name__ == '__main__':
    main()
