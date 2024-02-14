#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Show calculator"
    
else
    kill `pidof rofi` 
    # so rofi doesn't complain "can't launch rofi inside rofi"
    rofi -show calc -theme gruvbox-dark-hard
fi
