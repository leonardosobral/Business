"""Collect bounded SEO evidence without exporting page text, IPs or request targets."""
import argparse, datetime, gzip, hashlib, ipaddress, json, re, time, unicodedata
from html.parser import HTMLParser
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

AGENTS = ('OAI-SearchBot', 'ChatGPT-User', 'GPTBot', 'PerplexityBot', 'Perplexity-User')
RANGE_URLS = {
    'OAI-SearchBot': 'https://openai.com/searchbot.json',
    'ChatGPT-User': 'https://openai.com/chatgpt-user.json',
    'GPTBot': 'https://openai.com/gptbot.json',
    'PerplexityBot': 'https://www.perplexity.com/perplexitybot.json',
    'Perplexity-User': 'https://www.perplexity.com/perplexity-user.json',
}
VOID = set('area base br col embed hr img input link meta param source track wbr'.split())
HIDDEN = {'script', 'style', 'noscript', 'template'}

def normalized(text):
    return re.sub(r'\s+', ' ', unicodedata.normalize('NFC', text)).strip()

def text_hash(text):
    return hashlib.sha256(normalized(text).encode()).hexdigest()

class DescriptionParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.stack, self.regions = [], []

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        hidden = tag in HIDDEN or 'hidden' in attrs or attrs.get('aria-hidden', '').lower() == 'true' or bool(re.search(r'(display\s*:\s*none|visibility\s*:\s*hidden)', attrs.get('style', ''), re.I)) or any(x['hidden'] for x in self.stack)
        container = 'event-info-copy' in attrs.get('class', '').split() or any(x['container'] for x in self.stack)
        region = next((x['region'] for x in reversed(self.stack) if x['region'] is not None), None)
        if container and attrs.get('lang') and not hidden and region is None:
            region = len(self.regions)
            self.regions.append({'lang': attrs['lang'], 'text': [], 'lang_conflict': False})
        elif region is not None and attrs.get('lang') and not hidden and attrs['lang'].lower() != self.regions[region]['lang'].lower():
            self.regions[region]['lang_conflict'] = True
        if tag in VOID:
            if region is not None and not hidden:
                self.regions[region]['text'].append(' ')
            return
        self.stack.append({'tag': tag, 'container': container, 'hidden': hidden, 'region': region})

    def handle_startendtag(self, tag, attributes):
        self.handle_starttag(tag, attributes)
        if tag not in VOID:
            self.handle_endtag(tag)

    def handle_endtag(self, tag):
        for i in range(len(self.stack)-1, -1, -1):
            if self.stack[i]['tag'] == tag:
                region = self.stack[i]['region']
                if region is not None and not self.stack[i]['hidden']:
                    self.regions[region]['text'].append(' ')
                del self.stack[i:]
                break

    def handle_data(self, text):
        if self.stack and not self.stack[-1]['hidden'] and self.stack[-1]['region'] is not None:
            self.regions[self.stack[-1]['region']]['text'].append(text)

def description_observation(html, url, status, final_url):
    parser = DescriptionParser()
    parser.feed(html)
    region = parser.regions[0] if len(parser.regions) == 1 else None
    text = normalized(''.join(region['text'])) if region else ''
    return {'url': url, 'status': status, 'final_url': final_url,
            'description_regions': len(parser.regions), 'description_lang': region['lang'] if region else None,
            'description_lang_conflict': region['lang_conflict'] if region else False,
            'description_chars': len(text), 'description_hash': text_hash(text) if text else None}

def translation_status(original, target, expected_lang):
    for item in (original, target):
        if item['status'] < 200 or item['status'] >= 300 or item['final_url'] != item['url']:
            return 'error'
    if any(item['description_regions'] != 1 or item.get('description_lang_conflict', True) or not item['description_chars'] or not item['description_hash'] for item in (original, target)):
        return 'unknown'
    if original['description_lang'] != 'pt-BR':
        return 'unknown'
    if target['description_lang'] != expected_lang or target['description_hash'] == original['description_hash']:
        return 'warning'
    return 'pass'

def bot_observation(line, ranges):
    match = re.fullmatch(r'(\S+) \S+ \S+ \[([^\]]+)\] "(?:[^"\\]|\\.)*" (\d{3}) \S+ "(?:[^"\\]|\\.)*" "((?:[^"\\]|\\.)*)"\s*', line)
    if not match:
        return None
    ip, stamp, status, ua = match.groups()
    agent = next((name for name in AGENTS if re.search(r'(?<![\w-])'+re.escape(name)+r'(?=/|[\s;)\]]|$)', ua)), None)
    if agent is None:
        return None
    try:
        address = ipaddress.ip_address(ip)
        seen = datetime.datetime.strptime(stamp, '%d/%b/%Y:%H:%M:%S %z').isoformat()
        networks = ranges.get(agent)
        compatible = any(address in ipaddress.ip_network(n) for n in networks) if networks else None
    except ValueError:
        return None
    return {'agent': agent, 'at': seen, 'status': int(status), 'ip_matches': compatible}

def collect_descriptions(events):
    result = []
    for event in events:
        slug = event['tag']
        if not re.fullmatch(r'[a-zA-Z0-9-]{1,180}', slug):
            raise ValueError('Invalid event slug')
        pages = {}
        for lang, prefix in [('pt-BR', 'evento'), ('en', 'en/event'), ('es', 'es/evento')]:
            url = f'https://roadrunners.run/{prefix}/{slug}/'
            try:
                request = Request(url, headers={'User-Agent': 'RunnerHub-SEO/1.0 (+https://business.roadrunners.run/portal/seo/)', 'Accept': 'text/html'})
                with urlopen(request, timeout=25) as response:
                    body = response.read(3*1024*1024+1)
                    if len(body)>3*1024*1024:
                        raise ValueError('Response too large')
                    observation = description_observation(body.decode('utf-8', errors='replace'), url, response.status, response.url)
            except HTTPError as error:
                observation = description_observation('', url, error.code, error.url)
            except (URLError, TimeoutError, ValueError):
                observation = description_observation('', url, 0, url)
            pages[lang] = observation
            time.sleep(1)
        for lang in ('en', 'es'):
            pages[lang]['translation_status'] = translation_status(pages['pt-BR'], pages[lang], lang)
        result.append({'tag': slug, 'cohort': event['cohort'], 'pages': pages})
    return {'measured_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'events': result}

def collect_ranges():
    ranges, sources = {}, {}
    for agent, url in RANGE_URLS.items():
        with urlopen(Request(url, headers={'User-Agent': 'RunnerHub-SEO/1.0'}), timeout=25) as response:
            data = response.read(1024*1024)
        document = json.loads(data)
        prefixes = [p.get('ipv4Prefix') or p.get('ipv6Prefix') for p in document['prefixes']]
        for prefix in prefixes:
            ipaddress.ip_network(prefix)
        ranges[agent] = prefixes
        sources[agent] = {'url': url, 'sha256': hashlib.sha256(data).hexdigest(), 'prefixes': len(prefixes)}
    return {'measured_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'ranges': ranges, 'sources': sources}

def summarize_logs(paths, ranges, since):
    counts, first, last, lines = {}, None, None, 0
    for path in paths:
        opener = gzip.open if str(path).endswith('.gz') else open
        with opener(path, 'rt', errors='replace') as file:
            for line in file:
                lines += 1
                item = bot_observation(line.rstrip('\n'), ranges)
                if not item or datetime.datetime.fromisoformat(item['at']) < since:
                    continue
                first = min(first, item['at']) if first else item['at']
                last = max(last, item['at']) if last else item['at']
                bucket = counts.setdefault(item['agent'], {'requests': 0, 'ip_compatible': 0, 'ip_incompatible': 0, 'ip_unknown': 0, 'status_2xx': 0, 'status_3xx': 0, 'status_4xx': 0, 'status_5xx': 0})
                bucket['requests'] += 1
                bucket['ip_compatible' if item['ip_matches'] is True else 'ip_incompatible' if item['ip_matches'] is False else 'ip_unknown'] += 1
                bucket['status_'+str(item['status']//100)+'xx'] = bucket.get('status_'+str(item['status']//100)+'xx', 0)+1
    return {'lines_scanned': lines, 'files_scanned': len(paths), 'first': first, 'last': last, 'agents': counts, 'site_attribution': False}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('kind', choices=['descriptions', 'ranges'])
    parser.add_argument('--events-file')
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    result = collect_descriptions(json.loads(Path(args.events_file).read_text())) if args.kind == 'descriptions' else collect_ranges()
    Path(args.output).write_text(json.dumps(result, indent=2, ensure_ascii=False)+'\n')
    print(json.dumps({'kind': args.kind, 'measured_at': result['measured_at'], 'events': len(result.get('events', [])), 'providers': len(result.get('sources', {}))}))
