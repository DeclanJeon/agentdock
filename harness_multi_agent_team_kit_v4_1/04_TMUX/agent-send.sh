#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <tmux-target> <message-file>"
  echo "Example: $0 product-war-room:planning.0 /tmp/task.md"
  exit 1
fi

TARGET="$1"
FILE="$2"

tmux load-buffer "$FILE"
tmux paste-buffer -t "$TARGET"
tmux send-keys -t "$TARGET" C-m
