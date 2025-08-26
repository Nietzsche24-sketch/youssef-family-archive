#!/usr/bin/env bash
set -euo pipefail
P="${P:-$HOME/Documents/youssef-family-archive}"
E="$P/scripts/edit_person.sh"
. "$P/scripts/ids.sh"

[ $# -ge 1 ] || { echo "Usage: add_person_auto.sh \"Full Name\" [parent1,parent2]"; exit 1; }
NAME="$1"; PARENTS="${2:-}"

ID=$(gen_id "$NAME" "$PARENTS")
NEW_UID=$(gen_uid)

"$E" add "$ID" "$NAME" >/dev/null

jq --arg id "$ID" --arg uid "$NEW_UID" '
  .nodes = (.nodes // []) |
  .nodes = (.nodes | map(if .id==$id then (.meta=(.meta//{})+{uid:$uid}) else . end))
' "$P/site/data/people.json" > "$P/site/data/people.tmp.json" && mv "$P/site/data/people.tmp.json" "$P/site/data/people.json"

if [ -n "$PARENTS" ]; then
  IFS=, read -r p1 p2 <<< "$PARENTS"
  if [ -n "${p1:-}" ] && [ -n "${p2:-}" ]; then "$E" set-parents "$ID" "$p1" "$p2"
  elif [ -n "${p1:-}" ]; then "$E" set-parents "$ID" "$p1"
  fi
fi

echo "✅ Added: $NAME"
echo "   id:  $ID"
echo "   uid: $NEW_UID"
