#!/bin/bash
# Helper script to execute OAuth helper
cd "$HOME/.local/share/plasma/plasmoids/com.github.gmailcalendar"
python3 oauth-helper.py > oauth-output.json 2>&1



