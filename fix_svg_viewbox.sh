#!/bin/bash
SVG_FILE="viewer/tree.svg"
TMP_FILE="viewer/tree_fixed.svg"

if [[ ! -f "$SVG_FILE" ]]; then
  echo "❌ $SVG_FILE not found!"
  exit 1
fi

# Define a more generous viewBox (modify this as needed)
NEW_VIEWBOX='viewBox="-300 -300 1200 1200" width="100%" height="100%" preserveAspectRatio="xMidYMid meet"'

# Replace the existing viewBox line
sed -E "s/viewBox=\"[^\"]+\"[^>]*>/$NEW_VIEWBOX>/" "$SVG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$SVG_FILE"

echo "✅ Fixed viewBox in $SVG_FILE"
