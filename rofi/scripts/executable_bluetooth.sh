#!/usr/bin/env bash

rfkill unblock bluetooth 2>/dev/null
bluetoothctl power on &>/dev/null

bluetoothctl scan on &
sleep 5
kill %1 2>/dev/null

devices=$(bluetoothctl devices | awk '{$1=""; print $0}' | sed 's/^ //')
[ -z "$devices" ] && notify-send "Bluetooth" "Không tìm thấy thiết bị" && exit

chosen=$(echo "$devices" | rofi -dmenu -p "Bluetooth" -i)
[ -z "$chosen" ] && exit

mac=$(bluetoothctl devices | grep "$chosen" | awk '{print $2}')

# Toggle connect/disconnect
if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
    bluetoothctl disconnect "$mac" && notify-send "Bluetooth" "Đã ngắt: $chosen"
else
    bluetoothctl connect "$mac" && notify-send "Bluetooth" "Đã kết nối: $chosen"
fi
