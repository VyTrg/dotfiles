#!/usr/bin/env bash
chosen=$(printf "  Shutdown\n  Reboot\n  Suspend\n  Lock\n  Logout" \
    | rofi -dmenu -p "Power" -i)

case "$chosen" in
    "  Shutdown") systemctl poweroff ;;
    "  Reboot")   systemctl reboot ;;
    "  Suspend")  systemctl suspend ;;
    "  Lock")     loginctl lock-session ;;
    "  Logout")   niri msg action quit ;;
esac
