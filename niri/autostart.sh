#!/bin/bash
exec >/tmp/niri-autostart.log 2>&1

/usr/bin/alacritty --title "niri-main" &
sleep 0.1
/usr/bin/alacritty --title "niri-clock" -e tty-clock -c -b -s -C 6 &
sleep 0.1
/usr/bin/alacritty --title "niri-htop" -e htop &
sleep 0.1
/usr/bin/alacritty --title "niri-nvtop" -e nvtop &
sleep 0.1
niri msg action focus-column-first
sleep 0.1
niri msg action consume-window-into-column
sleep 0.1
niri msg action focus-column-right
sleep 0.1
niri msg action consume-window-into-column
