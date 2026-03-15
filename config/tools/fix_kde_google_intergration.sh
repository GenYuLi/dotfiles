#!/bin/bash
set -euo pipefail

PROVIDER_FILE="/usr/share/accounts/providers/kde/google.provider"

# Check file exists
if [ ! -f "$PROVIDER_FILE" ]; then
    echo "Error: $PROVIDER_FILE not found."
    echo "Is kaccounts-providers installed?"
    echo "  sudo dnf install kaccounts-providers"
    exit 1
fi

# Check if Drive scope already present
if grep -q 'googleapis.com/auth/drive' "$PROVIDER_FILE"; then
    echo "Drive scope already present in $PROVIDER_FILE, nothing to do."
    exit 0
fi

# Backup
echo "Backing up $PROVIDER_FILE ..."
sudo cp "$PROVIDER_FILE" "${PROVIDER_FILE}.backup.$(date +%Y%m%d%H%M%S)"

# Inject Drive scope: add it after the last existing scope entry
echo "Adding Drive scope to $PROVIDER_FILE ..."
sudo sed -i "s|'https://www.googleapis.com/auth/tasks'|'https://www.googleapis.com/auth/tasks',\n            'https://www.googleapis.com/auth/drive'|" "$PROVIDER_FILE"

echo "Done. Provider file updated."
echo ""
echo "Next steps:"
echo "  1. Restart kded6:  kquitapp6 kded6"
echo "  2. Remove your existing Google account from System Settings > Online Accounts"
echo "  3. Re-add your Google account (this time OAuth will request Drive permission)"
echo ""
echo "Note: KDE updates may overwrite this file — re-run this script if it breaks again."
