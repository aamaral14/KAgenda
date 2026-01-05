#!/bin/bash
# Wrapper script to run OAuth helper and save output
OUTPUT_FILE="$HOME/.local/share/plasma/plasmoids/com.github.kagenda/oauth-output.json"
python3 "$HOME/.local/share/plasma/plasmoids/com.github.kagenda/oauth-helper.py" > "$OUTPUT_FILE" 2>&1
echo "DONE" > "$HOME/.local/share/plasma/plasmoids/com.github.kagenda/oauth-status.txt"


