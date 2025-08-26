#!/bin/bash

INPUT="viewer/data.csv"
DOTFILE="viewer/tree.dot"
OUTPUT="viewer/tree.svg"

mkdir -p viewer

# Start writing the DOT file
{
  echo 'digraph FamilyTree {'
  echo '  node [shape=box, style=filled, color=lightblue];'

  # Read CSV and emit nodes + edges
  tail -n +2 "$INPUT" | while IFS=',' read -r id parent name title _; do
    echo "  \"$id\" [label=\"$name\\n$title\"]"
    if [[ -n "$parent" ]]; then
      echo "  \"$parent\" -> \"$id\""
    fi
  done

  echo '}'
} > "$DOTFILE"

# Generate SVG from DOT
dot -Tsvg "$DOTFILE" -o "$OUTPUT"
echo "✅ Family tree generated: $OUTPUT"
