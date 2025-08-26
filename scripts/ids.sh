#!/usr/bin/env bash
set -euo pipefail

slug() { echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'; }

short_hash() {
  python3 - <<PY
import sys,hashlib,base64
h = hashlib.sha1(sys.stdin.read().encode()).digest()
print(base64.b32encode(h).decode().lower().strip('=')[:7])
PY
}

gen_uid() {
  python3 - <<'PY'
import os, time, base64, struct
ms = int(time.time()*1000)
t = struct.pack('>Q', ms)[2:]  # 6 bytes
r = os.urandom(10)             # 10 bytes
print(base64.b32encode(t+r).decode().lower().strip('='))
PY
}

gen_id() {
  name="$1"; parents="${2:-}"
  s=$(slug "$name"); h=$(printf '%s|%s' "$name" "$parents" | short_hash)
  echo "${s}-${h}"
}
