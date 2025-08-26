#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
YAML_FILE="$ROOT/data/family_tree.yaml"
DOT_FILE="$ROOT/viewer/tree.dot"
SVG_FILE="$ROOT/viewer/tree.svg"

python3 - <<'PY'
import sys, yaml, collections

from pathlib import Path
root = Path(__file__).resolve().parents[1]
yml = yaml.safe_load((root/"data/family_tree.yaml").read_text())

# Build indices
name = {p["id"]: p["name"] for p in yml["people"]}
children = collections.defaultdict(list)
parents  = collections.defaultdict(list)
for a,b in yml["parent_child"]:
    children[a].append(b)
    parents[b].append(a)

# Compute generations (BFS) from Amin as canonical root if present, else pick a top ancestor
roots = [pid for pid in name if pid not in parents]
start = "amin" if "amin" in name else (roots[0] if roots else None)
gen = {pid: None for pid in name}
if start:
    from collections import deque
    q = deque([start]); gen[start]=0
    while q:
        u = q.popleft()
        for v in children.get(u,[]):
            if gen.get(v) is None:
                gen[v] = (gen[u] or 0)+1
                q.append(v)

# Fallback for disconnected: assign 0
for pid in name:
    if gen.get(pid) is None:
        gen[pid]=0

# Color palette by generation (loops after a while)
palette = ["#0ea5e9","#22c55e","#f59e0b","#a78bfa","#f97316","#10b981","#ef4444","#14b8a6","#eab308"]
def color(pid): return palette[ gen.get(pid,0) % len(palette) ]

dot_lines = []
dot_lines.append('digraph YoussefFamily {')
dot_lines.append('  rankdir=TB;')
dot_lines.append('  node [shape=box, style=filled, fontname="Helvetica"];')

# Nodes
for pid, nm in name.items():
    dot_lines.append(f'  "{pid}" [label="{nm}", fillcolor="{color(pid)}"];')

# Parent -> child edges
for a,b in yml["parent_child"]:
    dot_lines.append(f'  "{a}" -> "{b}";')

# Spousal links (undirected look via dashed, no arrows)
for a,b in yml.get("spouses", []):
    # draw subtle link; use constraint=false so it doesn't distort ranks too much
    dot_lines.append(f'  "{a}" -> "{b}" [dir=none, style=dashed, color="#64748b", constraint=false];')

dot_lines.append('}')
(Path(root/"viewer/tree.dot")).write_text("\n".join(dot_lines))
PY

# Render with Graphviz
dot -Tsvg "$DOT_FILE" -o "$SVG_FILE"

# Clean the <svg> tag (prevent duplicate width/height issues in some viewers)
# Keep viewBox responsive
# Strip any width/height attributes, inject responsive attrs once
# BSD sed compatible:
tmp="$SVG_FILE.tmp"
sed -E '1,5s/ width="[^"]*"//; 1,5s/ height="[^"]*"//' "$SVG_FILE" > "$tmp" && mv "$tmp" "$SVG_FILE"
# Ensure a viewBox is present
if ! grep -q 'viewBox=' "$SVG_FILE"; then
  sed -i '' 's/<svg /<svg viewBox="0 0 1200 800" /' "$SVG_FILE"
fi

echo "✅ Rendered: $SVG_FILE"
