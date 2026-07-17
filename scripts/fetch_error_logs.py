import urllib.request
import json

USER_API_KEY = "NRAK-TTTTR0NFV6IGXA1CTL8X2HNMYER"
ACCOUNT_ID   = 8131360

queries = {
    "Application ERRORs": "SELECT * FROM Log WHERE logGroup = 'petclinic/application-logs' AND message LIKE '%ERROR%' SINCE 1 hour ago LIMIT 50",
    "Apache HTTP 5xx Errors": "SELECT * FROM Log WHERE logGroup = 'petclinic/apache-access-logs' AND message LIKE '% 5__' SINCE 1 hour ago LIMIT 50",
    "Apache Error Logs": "SELECT * FROM Log WHERE logGroup = 'petclinic/apache-error-logs' SINCE 1 hour ago LIMIT 50",
}

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

total_errors = 0

for label, nrql in queries.items():
    results = run_nrql(nrql)
    total_errors += len(results)
    print(f"\n{'='*60}")
    print(f"  {label}  ({len(results)} found)")
    print(f"{'='*60}")
    if not results:
        print("  No errors found.")
    for entry in results:
        log_group = entry.get("logGroup", "")
        message   = entry.get("message", "")
        timestamp = entry.get("timestamp", "")
        print(f"  LOG GROUP : {log_group}")
        print(f"  MESSAGE   : {message}")
        print()

print(f"\n{'='*60}")
print(f"  TOTAL ERROR LOG ENTRIES: {total_errors}")
print(f"{'='*60}")
