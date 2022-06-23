#!/usr/bin/env bash

polybar-msg cmd quit

echo "---" | tee -a /tmp/polybar1.log /tmp/polybar2.log

if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload main &
  done
else
  polybar --reload main &
fi

echo "Bars launched..."
