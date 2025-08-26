#!/usr/bin/env bash
set -euo pipefail
JSON="$HOME/Documents/youssef-family-archive/site/data/people.json"
ID="$1"; KEY="$2"; VAL="$3"
tmp="${JSON}.tmp"
jq --arg id "$ID" --arg k "$KEY" --argjson v "$VAL" '
  .nodes = (.nodes // []) |
  .nodes = (.nodes | map(
    if .id==$id then
      .meta = ((.meta // {}) + {($k): $v})
    else . end
  ))
' "$JSON" > "$tmp" && mv "$tmp" "$JSON"
