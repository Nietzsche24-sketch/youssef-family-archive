#!/usr/bin/env bash
set -euo pipefail
E="$HOME/Documents/youssef-family-archive/scripts/edit_person.sh"
for id in "$@"; do
  name=$(jq -r --arg id "$id" '.nodes[]|select(.id==$id)|.name' "$HOME/Documents/youssef-family-archive/site/data/people.json")
  [[ "$name" == *"†"* ]] && continue
  "$E" set-name "$id" "$name †"
  echo "† $id"
done
