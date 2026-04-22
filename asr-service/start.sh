#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Check venv
if [ ! -d "venv" ]; then
    echo "[WARN] Virtual environment not found, initializing..."
    bash setup.sh
fi

# Pass all arguments to the Python service
# Examples:
#   bash start.sh --model-size 1.7b --enable-align
#   bash start.sh --device cpu --model-size 0.6b
#   bash start.sh --model-source huggingface
"$SCRIPT_DIR/venv/bin/python3" -m app.main "$@"
