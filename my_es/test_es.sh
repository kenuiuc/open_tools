#!/usr/bin/env bash
set -euo pipefail

ES=${ES:-http://localhost:9200}
IDX=test_es_demo

echo "Elasticsearch endpoint: $ES"

echo "1) Check cluster health"
curl -sSf "$ES/_cluster/health?pretty" | jq .

echo "\n2) Create index $IDX"
curl -sSf -X PUT "$ES/$IDX" -H 'Content-Type: application/json' -d'
{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
  "mappings": {
    "properties": { "title": { "type": "text" }, "content": { "type": "text" }, "timestamp": { "type": "date" } }
  }
}' | jq .

echo "\n3) Index sample documents (bulk)"
curl -sSf -X POST "$ES/$IDX/_bulk?refresh=true" -H 'Content-Type: application/x-ndjson' -d'
{ "index": {} }
{ "title": "First doc", "content": "Hello Elasticsearch", "timestamp": "2020-01-01T00:00:00Z" }
{ "index": {} }
{ "title": "Second doc", "content": "Quick brown fox", "timestamp": "2021-06-15T12:34:56Z" }
{ "index": {} }
{ "title": "Third doc", "content": "Testing search queries", "timestamp": "2022-03-10T09:00:00Z" }
' | jq .

echo "\n4) Count documents"
curl -sSf "$ES/$IDX/_count" | jq .

echo "\n5) Search for 'testing'"
curl -sSf "$ES/$IDX/_search?q=testing&pretty" | jq .

echo "\n6) Delete index $IDX"
curl -sSf -X DELETE "$ES/$IDX" | jq .

echo "\nDone. Cleaned up index $IDX."

exit 0
