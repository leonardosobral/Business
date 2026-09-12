"""Read-only incident correlation. Run on web host with python3 via SSH stdin.

Only the two known access-log rotations and CPC delivery logs are read.
Never output addresses, tokens, query strings, or unrelated visitor records.
"""
import collections
import csv
import datetime
import hashlib
import json
import urllib.parse

UA = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:x.x.x) Gecko/20041107 Firefox/x.x"
requests = []
addresses = set()
all_ad_requests = collections.Counter()
for path in ["/var/log/apache2/access.log.1", "/var/log/apache2/access.log"]:
    with open(path, errors="replace") as stream:
        for line in stream:
            parts = line.split('"')
            if len(parts) < 6:
                continue
            request = parts[1].split()
            if len(request) < 2:
                continue
            url = urllib.parse.urlsplit(request[1])
            if url.path in ["/api/ads/v1/cpc-click.cfm", "/api/ads/v1/cpc-viewable.cfm"]:
                all_ad_requests[(url.path, request[0], parts[2].strip().split()[0])] += 1
            if parts[5] != UA:
                continue
            addresses.add(line.split()[0])
            requests.append({
                "time": line.split("[", 1)[1].split("]", 1)[0],
                "method": request[0], "path": url.path,
                "http_status": parts[2].strip().split()[0],
                "delivery_id": urllib.parse.parse_qs(url.query).get("delivery", [""])[0],
                "click_event_id": urllib.parse.parse_qs(url.query).get("event", [""])[0],
            })

deliveries = {}
for path in ["/opt/ColdFusion/cfusion/logs/ads_v1_cpc.1.log", "/opt/ColdFusion/cfusion/logs/ads_v1_cpc.log"]:
    with open(path, errors="replace") as stream:
        for row in csv.reader(stream):
            if len(row) < 6:
                continue
            try:
                data = json.loads(row[-1])
            except ValueError:
                continue
            if data.get("deliveryId"):
                deliveries[data["deliveryId"]] = {
                    "campaign_id": data.get("campaignId"),
                    "core_event_id": data.get("coreEventId"),
                    "placement": data.get("placement"),
                    "serve_status": data.get("status"),
                    "serve_time": row[2] + " " + row[3],
                }

clicks = []
for index, request in enumerate(requests):
    if request["path"] != "/api/ads/v1/cpc-click.cfm":
        continue
    click = dict(request)
    click.update(deliveries.get(request["delivery_id"], {}))
    if index + 1 < len(requests):
        following = requests[index + 1]
        click["next_request_path"] = following["path"]
        click["next_request_time"] = following["time"]
    clicks.append(click)

source = open("/var/www/roadrunners.com.br/api/ads/v1/cpc-click.cfm", "rb").read()
categories = collections.Counter()
for request in requests:
    path = request["path"]
    category = "event_pages" if path.startswith("/evento/") else "state_pages" if path.startswith("/estado/") else "viewable" if path.endswith("cpc-viewable.cfm") else "click" if path.endswith("cpc-click.cfm") else "other"
    categories[category] += 1

print(json.dumps({
    "captured_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "scope": "access.log.1 + access.log and CPC delivery logs; no database queried",
    "user_agent": UA, "first_request": requests[0]["time"], "last_request": requests[-1]["time"],
    "request_count": len(requests), "distinct_logged_addresses": len(addresses),
    "request_categories": dict(categories),
    "viewable_requests_for_this_agent": sum(r["path"].endswith("cpc-viewable.cfm") for r in requests),
    # Classification is verified by executing CFML offline, not by emulating
    # only one regex in Python (which could miss later classifier branches).
    "published_click_endpoint_sha256": hashlib.sha256(source).hexdigest(),
    "all_cpc_http_requests": [{"path": key[0], "method": key[1], "http_status": key[2], "count": value} for key, value in all_ad_requests.items()],
    "clicks": clicks,
}, ensure_ascii=False, indent=2))
