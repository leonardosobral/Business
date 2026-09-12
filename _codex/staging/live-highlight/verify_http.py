#!/usr/bin/env python3
"""Read-only HTTP QA with synthetic geography, without a user browser/session."""
from html.parser import HTMLParser
from pathlib import Path
import json
from urllib.request import Request, urlopen

class Cards(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.highlight = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'a' and 'live-event-card-link' in attrs.get('class', '').split():
            self.links.append(attrs['href'])
        if 'data-highlighted-event' in attrs:
            self.highlight.append(attrs['data-highlighted-event'])

url = 'https://roadrunners.run/circuito/live-run-xp/'
cases = [
    ('foreign', 'pais=US; uf=SP; cidade=Campinas; location_source=cookie', None, 'sao-paulo'),
    ('city', 'pais=BR; uf=SP; cidade=Campinas; location_source=cookie', 'campinas', 'campinas'),
    ('accent', 'pais=BR; uf=SP; cidade=SAO-CAETANO%20DO%20SUL; location_source=cookie', 'santo-andre', 'santo-andre'),
    ('state', 'pais=BR; uf=SC; cidade=Blumenau; location_source=cookie', 'jaragua-do-sul', 'jaragua-do-sul'),
]
results = []
baseline = None
for name, cookie, expected, first in cases:
    request = Request(url, headers={'User-Agent': 'RunnerHub-Highlight-QA/1.0', 'Cookie': cookie})
    with urlopen(request, timeout=25) as response:
        status = response.status
        headers = {key: response.headers.get(key) for key in ('Cache-Control', 'CF-Cache-Status', 'Age', 'Content-Type')}
        markup = response.read().decode('utf-8', errors='replace')
    parsed = Cards()
    parsed.feed(markup)
    assert status == 200, (name, status)
    assert 'private' in headers['Cache-Control'] and 'no-store' in headers['Cache-Control'], (name, headers)
    assert headers['CF-Cache-Status'] != 'HIT', (name, headers)
    assert len(parsed.links) == 187 and len(set(parsed.links[:18])) == 18, (name, len(parsed.links))
    assert len(parsed.highlight) == (1 if expected else 0), (name, parsed.highlight)
    assert first in parsed.links[0], (name, parsed.links[0])
    if baseline is None:
        baseline = parsed.links
    else:
        assert sorted(parsed.links[:18]) == sorted(baseline[:18]), name
        assert parsed.links[18:] == baseline[18:], name
        assert parsed.links[1:18] == [link for link in baseline[:18] if link != parsed.links[0]], name
    results.append({'case': name, 'status': status, 'headers': headers, 'highlight': parsed.highlight,
                    'first': parsed.links[0], 'upcoming': 18, 'completed': 169, 'all_links_preserved': True})
result = {'url': url, 'synthetic_geography_only': True, 'cases': results}
(Path(__file__).resolve().parent / 'http-qa-result.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
