import urllib.request
import json
from datetime import datetime, timezone

USER_API_KEY = "NRAK-TTTTR0NFV6IGXA1CTL8X2HNMYER"
ACCOUNT_ID   = 8131360

def run_nrql(nrql):
    gql = '{ actor { account(id: %d) { nrql(query: "%s") { results } } } }' % (
        ACCOUNT_ID, nrql.replace('"', '\\"')
    )
    body = json.dumps({"query": gql}).encode("utf-8")
    req = urllib.request.Request(
        "https://api.newrelic.com/graphql",
        data=body,
        headers={"Content-Type": "application/json", "API-Key": USER_API_KEY},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read())
    return data["data"]["actor"]["account"]["nrql"]["results"]

# Fetch latest logs per log group sorted by time
nrql = "SELECT timestamp, logGroup, logStream, message FROM Log WHERE logGroup LIKE 'petclinic/%' SINCE 15 minutes ago ORDER BY timestamp DESC LIMIT 100"

results = run_nrql(nrql)

print(f"\n{'='*70}")
print(f"  LATEST LOGS FROM NEWRELIC  —  {len(results)} entries (last 15 mins)")
print(f"  Fetched at: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}")
print(f"{'='*70}\n")

group_order = [
    "petclinic/application-logs",
    "petclinic/apache-access-logs",
    "petclinic/apache-error-logs",
    "petclinic/userdata-logs",
]

grouped = {}
for entry in results:
    lg = entry.get("logGroup", "unknown")
    grouped.setdefault(lg, []).append(entry)

# Print in logical order
for group in group_order:
    entries = grouped.get(group, [])
    if not entries:
        continue

    icon = "📋"
    if "application" in group:  icon = "☕"
    if "apache-access" in group: icon = "🌐"
    if "apache-error"  in group: icon = "🔴"
    if "userdata"      in group: icon = "⚙️ "

    print(f"{icon}  {group}  ({len(entries)} entries)")
    print(f"{'─'*70}")
    for e in entries:
        msg = e.get("message", "")
        ts  = e.get("timestamp", "")

        # Severity tag
        tag = "INFO "
        if "ERROR" in msg or "error" in msg:   tag = "ERROR"
        elif "WARN"  in msg or "warn"  in msg: tag = "WARN "
        elif "502" in msg or "503" in msg or "500" in msg: tag = "HTTP5"

        print(f"  [{tag}] {msg[:120]}")
    print()

# Summary
print(f"{'='*70}")
error_count = sum(1 for e in results if "ERROR" in e.get("message","") or "error" in e.get("message",""))
warn_count  = sum(1 for e in results if "warn"  in e.get("message","").lower())
print(f"  SUMMARY: {len(results)} total  |  {error_count} errors  |  {warn_count} warnings")
print(f"{'='*70}")
