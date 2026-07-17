$apiKey = "NRAK-E9LJJLLCDJ4UW490Q2QE1ID12UJ"
$headers = @{ "API-Key" = $apiKey; "Content-Type" = "application/json" }
$graphqlQuery = '{ actor { account(id: 8131360) { logs(limit: 30) { timestamp message logGroup } } } }'
$body = @{ query = $graphqlQuery } | ConvertTo-Json -Compress
$result = Invoke-RestMethod -Uri "https://api.newrelic.com/graphql" -Method POST -Headers $headers -Body $body
$result.data.actor.account.logs | ConvertTo-Json -Depth 5
