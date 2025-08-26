#!/usr/bin/env bash
set -euo pipefail

JSON="${JSON:-$HOME/Documents/youssef-family-archive/site/data/people.json}"
PHOTOS_DIR="${PHOTOS_DIR:-$HOME/Documents/youssef-family-archive/site/assets/photos}"

err(){ echo "❌ $*" >&2; exit 1; }
need(){ command -v "$1" >/dev/null || err "Missing $1. Install: brew install $1"; }
need jq

[ -s "$JSON" ] || { mkdir -p "$(dirname "$JSON")"; printf '%s\n' '{"nodes":[]}' > "$JSON"; }

backup(){ cp -f "$JSON" "$JSON.bak.$(date +%s)"; }
apply(){ local tmp="$1"; jq . "$tmp" >/dev/null || err "jq validation failed; not writing"; mv "$tmp" "$JSON"; }

jq_upsert(){ jq --arg id "$1" --arg name "$2" '
  (.nodes //= []) |
  if any(.nodes[]?; .id==$id) then .
  else .nodes += [{id:$id, name:$name}] end
'; }

jq_set_field(){ jq --arg id "$1" --arg key "$2" --arg val "$3" '.nodes |= map(if .id==$id then .[$key]=$val else . end)'; }
jq_set_bool(){ jq --arg id "$1" --arg key "$2" --argjson val "$3" '.nodes |= map(if .id==$id then .[$key]=$val else . end)'; }
jq_set_parents(){
  local id="$1"; shift
  local arr; arr=$(jq -n --argjson a "$(printf '%s\n' "$@" | jq -R . | jq -s .)" '$a')
  jq --arg id "$id" --argjson parents "$arr" '.nodes |= map(if .id==$id then .parents=$parents else . end)'
}
jq_set_social(){ jq --arg id "$1" --arg plat "$2" --arg url "$3" '
  .nodes |= map(if .id==$id then (.social //= {}) | (.social[$plat]=$url) | . else . end)
'; }
jq_set_bio(){ jq --arg id "$1" --arg bio "$2" '.nodes |= map(if .id==$id then .bio=$bio else . end)'; }
jq_set_photo(){ jq --arg id "$1" --arg rel "$2" '.nodes |= map(if .id==$id then .photo=$rel else . end)'; }

case "${1:-}" in
  add|upsert)
    [ $# -ge 3 ] || err "Usage: $0 add <id> \"<Name>\""
    id="$2"; name="$3"; backup
    tmp=$(mktemp); jq_upsert "$id" "$name" < "$JSON" > "$tmp" && apply "$tmp"
    echo "✅ Upserted: $id ($name)"
    ;;
  set-name)
    id="$2"; name="$3"; backup
    tmp=$(mktemp); jq_set_field "$id" name "$name" < "$JSON" > "$tmp" && apply "$tmp"
    ;;
  set-parents)
    [ $# -ge 3 ] || err "Usage: $0 set-parents <id> <parent1> [parent2]"
    id="$2"; shift 2; backup
    tmp=$(mktemp); jq_set_parents "$id" "$@" < "$JSON" > "$tmp" && apply "$tmp"
    ;;
  set-social)
    id="$2"; plat="$3"; url="$4"; backup
    tmp=$(mktemp); jq_set_social "$id" "$plat" "$url" < "$JSON" > "$tmp" && apply "$tmp"
    ;;
  set-bio)
    id="$2"; file="$3"; [ -f "$file" ] || err "Bio file not found: $file"; backup
    bio=$(cat "$file")
    tmp=$(mktemp); jq_set_bio "$id" "$bio" < "$JSON" > "$tmp" && apply "$tmp"
    ;;
  set-bio-text)
    id="$2"; shift 2; bio="$*"; backup
    tmp=$(mktemp); jq_set_bio "$id" "$bio" < "$JSON" > "$tmp" && apply "$tmp"
    ;;
  set-photo)
    id="$2"; src="$3"; [ -f "$src" ] || err "Photo not found: $src"
    mkdir -p "$PHOTOS_DIR"; ext="${src##*.}"; dest="$PHOTOS_DIR/$id.$ext"
    cp -f "$src" "$dest"; rel="assets/photos/$id.$ext"; backup
    tmp=$(mktemp); jq_set_photo "$id" "$rel" < "$JSON" > "$tmp" && apply "$tmp"
    echo "✅ Photo set: $rel"
    ;;
  lock)   id="$2"; backup; tmp=$(mktemp); jq_set_bool "$id" locked true  < "$JSON" > "$tmp" && apply "$tmp" ;;
  unlock) id="$2"; backup; tmp=$(mktemp); jq_set_bool "$id" locked false < "$JSON" > "$tmp" && apply "$tmp" ;;
  show)   id="$2"; jq --arg id "$id" '.nodes[] | select(.id==$id)' "$JSON" ;;
  list)   jq -r '.nodes[] | .id + " — " + .name' "$JSON" ;;
  *) cat <<USAGE
Usage:
  $0 add <id> "<Name>"
  $0 set-name <id> "<Name>"
  $0 set-parents <id> <parentId1> [parentId2]
  $0 set-social <id> facebook|instagram|linkedin <url>
  $0 set-bio <id> /path/to/bio.md
  $0 set-bio-text <id> "Inline bio text..."
  $0 set-photo <id> /path/to/photo.jpg|png
  $0 lock <id> | unlock <id>
  $0 show <id> | list
USAGE
     exit 1;;
esac
