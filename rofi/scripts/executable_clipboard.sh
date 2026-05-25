#!/usr/bin/env bash
cliphist list | rofi -dmenu -p "Clipboard" -i | cliphist decode | wl-copy
