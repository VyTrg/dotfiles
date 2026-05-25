#!/usr/bin/env bash

networks=$(nmcli -f SSID,BARS,SECURITY device wifi list 2>/dev/null \
    | tail -n +2 \
    | awk '{printf "%-30s %s %s\n", $1, $2, $3}' \
    | sort -u)

chosen=$(echo "$networks" | rofi -dmenu -p "WiFi" -i)
[ -z "$chosen" ] && exit

ssid=$(echo "$chosen" | awk '{print $1}')

if nmcli connection show "$ssid" &>/dev/null; then
    nmcli connection up "$ssid"
else
    security=$(echo "$chosen" | awk '{print $3}')
    if [ -n "$security" ] && [ "$security" != "--" ]; then
        pass=$(rofi -dmenu -p "Password" -password)
        nmcli device wifi connect "$ssid" password "$pass"
    else
        nmcli device wifi connect "$ssid"
    fi
fi
