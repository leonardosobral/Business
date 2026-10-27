"""Import the visible Semrush watchlist, independently of project/audit metrics.

Input is a DOM snapshot exported through the authorized browser session. This
script does not log into Semrush, read cookies, or call undocumented endpoints.
"""
import argparse
import base64
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
from zoneinfo import ZoneInfo

METRICS = [
    ("keywords", "Palavras-chave orgânicas", "percent"),
    ("traffic", "Tráfego orgânico", "percent"),
    ("paidKeywords", "Palavras-chave pagas", "percent"),
    ("paidTraffic", "Tráfego pago", "percent"),
    ("refDomains", "Domínios de referência", "percent"),
    ("authority", "Authority Score", "points"),
]
OWN = {"roadrunners.run", "openresults.run"}
GUARD = '''<cfprocessingdirective pageencoding="utf-8"/>
<cfinclude template="../../includes/backend/require_admin.cfm"/>
<cfif compareNoCase(getBaseTemplatePath(),getCurrentTemplatePath()) EQ 0><cfheader statuscode="403"/><cfabort/></cfif>
<cfif structKeyExists(CGI,"request_method") AND compareNoCase(CGI.request_method,"GET") NEQ 0><cfheader statuscode="405"/><cfheader name="Allow" value="GET"/><cfabort/></cfif>
'''


def compact(text):
    text = text.strip().replace("\u00a0", "")
    if text.lower() in {"n.d.", "n/a", "—", "-"}:
        return None
    match = re.fullmatch(r"(\d+(?:[,.]\d+)?)\s*(K|M|mil)?", text, re.I)
    if not match:
        raise ValueError("Invalid displayed count: " + text)
    factor = {None: 1, "k": 1000, "mil": 1000, "m": 1000000}[match[2].lower() if match[2] else None]
    return round(float(match[1].replace(",", ".")) * factor)


def metric(cell, unit):
    text = re.sub(r"\bChart\b", "", cell).strip()
    parts = text.split()
    if len(parts) != 2:
        raise ValueError("Expected displayed value and change: " + cell)
    count, change = parts
    value = compact(count)
    change_available = change.lower() not in {"n.d.", "n/a", "—", "-"}
    if change_available:
        pattern = r"[+-]?\d+(?:[.,]\d+)?%" if unit == "percent" else r"[+-]?\d+(?:[.,]\d+)?"
        if not re.fullmatch(pattern, change):
            raise ValueError("Invalid displayed change: " + change)
    return dict(available=value is not None, value=value or 0, display=count,
                rounded=bool(re.search(r"K|M|mil", count, re.I)),
                changeAvailable=change_available,
                change=float(change.rstrip("%").replace(",", ".")) if change_available else 0,
                changeDisplay=change, changeUnit=unit)


def parse_dom(dom, collected_at):
    stamp = datetime.fromisoformat(collected_at.replace("Z", "+00:00"))
    if stamp.tzinfo is None:
        raise ValueError("Collection timestamp must include timezone")
    section = dom.split('heading "Domínios para monitoramento"', 1)
    if len(section) != 2 or 'radio "Mês" [checked]' not in section[1]:
        raise ValueError("Missing watchlist or selected month period")
    section = section[1].split('button "Enviar comentário"', 1)[0]
    expected = "Domínio Palavras-chave orgânicas Tráfego orgânico Palavras-chave pagas Tráfego pago Domínios de ref. Authority Score"
    if 'row "' + expected + '"' not in section:
        raise ValueError("Watchlist columns changed; inspect before importing")
    rows, current = [], None
    for line in section.splitlines():
        row = re.fullmatch(r'      - row "(.*)":', line)
        if row:
            if current:
                rows.append(current)
            current = [] if row[1] != expected else None
        cell = re.fullmatch(r'        - gridcell "(.*)":', line)
        if cell and current is not None:
            current.append(cell[1])
    if current:
        rows.append(current)
    result, seen = [], set()
    for cells in rows:
        if len(cells) != 7:
            raise ValueError("Incomplete watchlist row")
        domain, country = cells[0].split()
        if country != "BR" or not re.fullmatch(r"(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}", domain):
            raise ValueError("Unexpected country or domain: " + cells[0])
        if domain in seen:
            raise ValueError("Duplicate domain: " + domain)
        seen.add(domain)
        metrics = {key: metric(cell, unit) for (key, _, unit), cell in zip(METRICS, cells[1:])}
        if metrics["authority"]["value"] > 100:
            raise ValueError("Authority Score exceeds 100")
        result.append(dict(domain=domain, country=country, own=domain in OWN, metrics=metrics))
    if not result or not OWN <= seen:
        raise ValueError("Empty or incomplete watchlist; own domains missing")
    for row in result:
        row["ranks"] = {}
        for key, _, _ in METRICS:
            row["ranks"][key] = (1 + sum(other["metrics"][key]["available"] and other["metrics"][key]["value"] > row["metrics"][key]["value"] for other in result)) if row["metrics"][key]["available"] else 0
    result.sort(key=lambda row: (not row["metrics"]["traffic"]["available"], -row["metrics"]["traffic"]["value"], row["domain"]))
    return dict(schemaVersion=1, source="Semrush · Domínios para monitoramento", sourceUrl="https://pt.semrush.com/home/",
                collectedAt=stamp.isoformat(), collectedLabel=stamp.astimezone(ZoneInfo("America/Sao_Paulo")).strftime("%d/%m/%Y às %H:%M (Brasília)"),
                country="BR", period="1m", periodLabel="Mês", sourceSha256=hashlib.sha256(dom.encode()).hexdigest(),
                count=len(result), domains=result)


def render(data):
    payload = base64.b64encode(json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode()).decode()
    return GUARD + '<!--- Gerado por seo_domains_snapshot.py; não misturar com cartões de projetos ou auditorias. --->\n<cfscript>\nVARIABLES.seoDomains = deserializeJSON(charsetEncode(binaryDecode("' + payload + '","base64"),"utf-8"));\n</cfscript>\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot-dom", required=True, type=Path)
    parser.add_argument("--collected-at", required=True)
    parser.add_argument("--archive", required=True, type=Path)
    parser.add_argument("--cfml-output", required=True, type=Path)
    args = parser.parse_args()
    data = parse_dom(args.snapshot_dom.read_text(), args.collected_at)
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    # Preserve each observation for later longitudinal comparison. Never replace
    # an earlier observation with a differently timed/cropped source.
    if args.archive.exists() and args.archive.read_text() != text:
        raise ValueError("Archive already exists with different content")
    args.archive.parent.mkdir(parents=True, exist_ok=True)
    args.archive.write_text(text)
    args.cfml_output.parent.mkdir(parents=True, exist_ok=True)
    args.cfml_output.write_text(render(data))
    print(json.dumps(dict(domains=data["count"], country=data["country"], period=data["period"], collectedAt=data["collectedAt"])))


if __name__ == "__main__":
    main()
