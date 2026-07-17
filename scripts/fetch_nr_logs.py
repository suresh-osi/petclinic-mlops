import urllib.request
import json

# NewRelic User API key (NRAK) is used for querying via NerdGraph
USER_API_KEY = "NRAK-TTTTR0NFV6IGXA1CTL8X2HNMYER"
ACCOUNT_ID   = 8131360

# NerdGraph NRQL query to fetch recent PetClinic logs
nrql = "SELECT * FROM Log WHERE logGroup LIKE 'petclinic/%' SINCE 30 minutes ago LIMIT 50"

query = """
{
  actor {
    account(id: %d) {
      nrql(query: "%s") {
        results
      }
    }
  }
}
""" % (ACCOUNT_ID, nrql)

body = json.dumps({"query": query}).encode("utf-8")

req = urllib.request.Request(
    "https://api.newrelic.com/graphql",
    data=body,
    headers={
        "Content-Type": "application/json",
        "API-Key": USER_API_KEY,
    },
    method="POST"
)

with urllib.request.urlopen(req, timeout=15) as resp:
    data = json.loads(resp.read())

results = data.get("data", {}).get("actor", {}).get("account", {}).get("nrql", {}).get("results", [])

if not results:
    print("No logs found yet. They may still be indexing (can take 1-2 mins).")
    print("Full response:", json.dumps(data, indent=2))
else:
    print(f"Found {len(results)} log entries:\n")
    for entry in results:
        log_group  = entry.get("logGroup", "unknown")
        message    = entry.get("message", "")
        timestamp  = entry.get("timestamp", "")
        print(f"[{log_group}] {message[:120]}")
