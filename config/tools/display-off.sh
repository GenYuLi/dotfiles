#!/bin/bash
# display-off.sh — 關閉螢幕輸出（DPMS off）
# 系統繼續運行，SSH / 背景服務不受影響
# 喚醒：動滑鼠或按任意鍵

set -euo pipefail

SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"
DESKTOP="${XDG_CURRENT_DESKTOP:-}"

case "$SESSION_TYPE" in
    wayland)
        if [[ "$DESKTOP" == *"KDE"* ]]; then
            qdbus org.kde.kglobalaccel /component/org.kde.kwin \
                invokeShortcut "Turn Off Screen"
        elif [[ "$DESKTOP" == *"GNOME"* ]]; then
            # PowerSaveMode: 0=on, 1=standby, 2=suspend, 3=off
            gdbus call --session \
                --dest org.gnome.Mutter.DisplayConfig \
                --object-path /org/gnome/Mutter/DisplayConfig \
                --method org.gnome.Mutter.DisplayConfig.SetPowerSaveMode 3
        else
            echo "Unknown Wayland compositor: $DESKTOP"
            exit 1
        fi
        ;;
    x11)
        xset dpms force off
        ;;
    *)
        echo "Unknown session type: $SESSION_TYPE"
        exit 1
        ;;
esac
