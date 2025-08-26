#!/usr/bin/env bash
set -euo pipefail
P="$HOME/Documents/youssef-family-archive"
E="$P/scripts/edit_person.sh"
CHILD="$1"; PARENTS="$2" # "parent1,parent2" or "parent1"
ID=$("$P/scripts/add_person_auto.sh" "$CHILD" "$PARENTS" | awk '/^   id:/ {print $2}')
echo "$ID"
