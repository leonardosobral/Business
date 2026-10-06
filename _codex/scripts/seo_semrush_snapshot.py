"""Build a bounded, admin-only Semrush snapshot from saved MCP responses.

Offline only: no provider calls, credentials, scheduler or production writes.
Keep raw exports in the private SEO report root, outside this repository.
"""
import argparse
import base64
import csv
from datetime import datetime, timezone
import io
import json
import math
from pathlib import Path
import re
from urllib.parse import urlsplit


def date(value):
    return datetime.fromisoformat(value.replace('Z', '+00:00'))


def label(value):
    from zoneinfo import ZoneInfo
    return date(value).astimezone(ZoneInfo('America/Sao_Paulo')).strftime('%d/%m/%Y, %H:%M') + ' (Brasília)'


def number(value):
    n = float(value)
    if not math.isfinite(n) or n < 0:
        raise ValueError('Invalid nonnegative metric')
    return int(n) if n.is_integer() else n


def rows(report, required):
    data = report['response']['data']
    if not isinstance(data, str): raise ValueError('Expected CSV')
    reader = csv.DictReader(io.StringIO(data), delimiter=';')
    if not set(required) <= set(reader.fieldnames or []): raise ValueError('Unexpected CSV schema')
    out = list(reader)
    if len(out) > 500: raise ValueError('Snapshot exceeds reviewed scope')
    return out


def landing(url):
    p = urlsplit(url)
    if p.scheme != 'https' or p.netloc != 'roadrunners.run' or re.search(r'[\x00-\x20\x7f\\]', url):
        raise ValueError('Landing URL outside RoadRunners')
    return url


def build_snapshot(source, audit_state=None):
    if (source.get('source'), source.get('target'), source.get('database'), source.get('device')) != ('Semrush MCP', 'roadrunners.run', 'br', 'desktop'):
        raise ValueError('Unsupported source, domain, market or device')
    date(source['collected_at'])
    reports = source['reports']
    for r in reports:
        if r['report'] in ('domain_rank', 'resource_organic', 'domain_organic_organic'):
            p = r['params']
            if p.get('database') != 'br' or p.get('target', p.get('domain')) != 'roadrunners.run':
                raise ValueError('Mixed report populations')
    overview_report = next(r for r in reports if r['report'] == 'domain_rank')
    totals = rows(overview_report, ['Domain', 'Organic Keywords', 'Organic Traffic', 'X0', 'X1', 'X2'])
    if len(totals) != 1 or totals[0]['Domain'] != 'roadrunners.run': raise ValueError('Wrong overview domain')
    t = totals[0]
    overview = dict(keywords=number(t['Organic Keywords']), trafficEstimate=number(t['Organic Traffic']),
                    top3=number(t['X0']), top10=number(t['X0']) + number(t['X1']), positions11to20=number(t['X2']))
    if overview['top10'] + overview['positions11to20'] > overview['keywords']:
        raise ValueError('Ranking buckets exceed keyword count')
    keywords = {}; count = 0
    for report in (r for r in reports if r['report'] == 'resource_organic'):
        for raw in rows(report, ['Keyword', 'Position', 'Previous Position', 'Search Volume', 'Url', 'Keyword Difficulty', 'Timestamp']):
            count += 1
            row = dict(keyword=raw['Keyword'], position=number(raw['Position']),
                       previousPosition=number(raw['Previous Position']) or None,
                       volume=number(raw['Search Volume']), url=landing(raw['Url']),
                       difficulty=number(raw['Keyword Difficulty']), timestamp=number(raw['Timestamp']))
            if not 1 <= row['position'] <= 100 or row['difficulty'] > 100:
                raise ValueError('Invalid position or difficulty')
            row['observedAt'] = datetime.fromtimestamp(row['timestamp'], timezone.utc).isoformat()
            row['observedLabel'] = label(row['observedAt'])
            key = (row['keyword'], row['url'])
            old = keywords.get(key)
            if not old or row['timestamp'] > old['timestamp']: keywords[key] = row
            elif row['timestamp'] == old['timestamp'] and row != old: raise ValueError('Conflicting sample rows')
    competitors = []
    for report in (r for r in reports if r['report'] == 'domain_organic_organic'):
        for raw in rows(report, ['Domain', 'Common Keywords', 'Organic Keywords', 'Organic Traffic']):
            if not re.fullmatch(r'[a-z0-9][a-z0-9.-]*\.[a-z]{2,}', raw['Domain']): raise ValueError('Invalid competitor domain')
            competitors.append(dict(domain=raw['Domain'], common=number(raw['Common Keywords']),
                                    keywords=number(raw['Organic Keywords']), trafficEstimate=number(raw['Organic Traffic'])))
    # Editorial priorities: persist evidence and explicit hypotheses, never infer that a repair was applied.
    priorities = [
        ('corrida em sp', 'regional', 'Revisar a página de São Paulo', 'Conferir intenção de busca, calendário atual, navegação por cidade e links internos. Validar cliques e impressões no Search Console.'),
        ('corridas es', 'regional', 'Fortalecer o calendário do Espírito Santo', 'Revisar conteúdo regional e acesso às cidades e próximas provas. Priorizar a utilidade para quem procura uma inscrição.'),
        ('corridas em santa catarina', 'regional', 'Revisar calendário e circuito de Santa Catarina', 'Comparar a página do estado com o circuito para definir a intenção de cada uma. Sobreposição de termos não comprova canibalização.'),
        ('maratona de aracaju', 'evento', 'Conferir a página da Maratona de Aracaju', 'Confirmar edição, datas e situação das inscrições antes de otimizar o conteúdo. Semrush não é fonte factual do evento.'),
        ('live run xp 2026', 'idioma', 'Investigar a página em inglês nas buscas brasileiras', 'Conferir versões PT/EN/ES, tradução, hreflang e a URL escolhida pelo Google. A posição isolada não comprova erro de idioma.'),
        ('sp city 2026', 'idioma', 'Investigar a página em espanhol nas buscas brasileiras', 'Validar edição e intenção da busca, versões por idioma e canonical no Search Console antes de alterar a página.')
    ]
    opportunities = []
    for priority_id, (term, group, title, action) in enumerate(priorities, start=1):
        matches = [r for r in keywords.values() if r['keyword'] == term]
        if matches:
            row = min(matches, key=lambda r:r['position'])
            opportunities.append(dict(row, id='SR-' + str(priority_id).zfill(2), group=group,
                                      title=title, action=action, status='A investigar'))
    audit = dict(status='unknown', checkedLabel='Não consultado', crawled=None, limit=None, lastFinishedAt=None, lastFinishedLabel='Não informado')
    if audit_state:
        a = audit_state['response']['data']
        if a.get('id') != 26661911 or a.get('url') != 'roadrunners.run': raise ValueError('Wrong audit project')
        checked = date(audit_state['collected_at'])
        audit['checkedLabel'] = label(audit_state['collected_at'])
        audit['checkedAt'] = audit_state['collected_at']
        if a.get('last_audit'):
            finished = datetime.fromtimestamp(a['last_audit']/1000, timezone.utc)
            audit['lastFinishedAt'] = finished.isoformat()
            audit['lastFinishedLabel'] = label(audit['lastFinishedAt'])
        else: finished = None
        if a.get('status') in ('RUNNING', 'CHECKING'):
            audit.update(status='running', crawled=a.get('running_pages_crawled'), limit=a.get('running_pages_limit'))
        elif finished and 0 <= (checked-finished).total_seconds() <= 86400:
            # Only a successfully finished state can promote counters to the current snapshot.
            if a.get('status') in ('FINISHED', 'DONE', 'READY', 'COMPLETED'):
                audit.update(status='complete', crawled=a.get('pages_crawled'), limit=a.get('pages_limit'))
                for key in ('errors', 'warnings', 'notices'):
                    audit[key] = number(a[key]) if a.get(key) is not None else None
        elif finished: audit['status'] = 'historical'
    tracking = 'unknown'
    for r in reports:
        if r['report'] == 'campaigns': tracking = 'configured' if r['response']['data'].get('targets') else 'not_configured'
    keyword_list = sorted(keywords.values(), key=lambda r:(-r['volume'], r['keyword'], r['url']))
    return dict(schemaVersion=1, domain='roadrunners.run', database='br', device='desktop',
                collectedAt=source['collected_at'], collectedLabel=label(source['collected_at']),
                overview=overview, keywords=keyword_list, sampleRows=count,
                uniqueKeywords=len({r['keyword'] for r in keyword_list}), competitors=competitors,
                opportunities=opportunities, audit=audit, tracking=tracking,
                reportedApiUnits=source.get('reported_api_units'),
                sourceUrl=overview_report['response'].get('metadata', {}).get('url', 'https://www.semrush.com/analytics/overview/?q=roadrunners.run&db=br'))


GUARD = '''<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(), getCurrentTemplatePath()) EQ 0>
  <cfheader statuscode="403" statustext="Forbidden"/><cfabort/>
</cfif>
<cfif structKeyExists(CGI,"request_method") AND compareNoCase(CGI.request_method,"GET") NEQ 0>
  <cfheader statuscode="405" statustext="Method Not Allowed"/><cfheader name="Allow" value="GET"/><cfabort/>
</cfif>
'''


def render_cfml(snapshot):
    encoded = base64.b64encode(json.dumps(snapshot, ensure_ascii=False).encode()).decode()
    return GUARD + '<!--- Gerado por seo_semrush_snapshot.py; coleta privada revisada. --->\n<cfscript>\nVARIABLES.seoSemrush = deserializeJSON(charsetEncode(binaryDecode("' + encoded + '","base64"),"utf-8"));\n</cfscript>\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--audit-state', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = build_snapshot(json.loads(args.baseline.read_text()), json.loads(args.audit_state.read_text()) if args.audit_state else None)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(render_cfml(result))
    print(json.dumps(dict(keywords=len(result['keywords']), opportunities=len(result['opportunities']), audit=result['audit']['status'])))


if __name__ == '__main__': main()
