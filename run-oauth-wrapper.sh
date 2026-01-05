#!/bin/bash
# Wrapper script to run OAuth helper and save output
OUTPUT_FILE="$HOME/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-output.json"
python3 "$HOME/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-helper.py" > "$OUTPUT_FILE" 2>&1
echo "DONE" > "$HOME/.local/share/plasma/plasmoids/com.github.gmailcalendar/oauth-status.txt"


