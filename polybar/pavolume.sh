#!/usr/bin/env bash

# finds the active sink for PipeWire and increments the volume. useful when you have multiple audio outputs and have a key bound to vol-up and down

osd='no'
inc='2'
capvol='no'
maxvol='200'
autosync='yes'

# Muted status
# yes: muted
# no : not muted
curStatus="no"
active_sink=""
limit=$((100 - inc))
maxlimit=$((maxvol - inc))

reloadSink() {
    active_sink=$(pactl list sinks | grep -B 2 "State: RUNNING" | awk '/Sink #[0-9]/{print $2}')
}

function volUp {

    getCurVol

    if [ "$capvol" = 'yes' ]
    then
        if [ "$curVol" -le 100 ] && [ "$curVol" -ge "$limit" ]
        then
            pactl set-sink-volume "$active_sink" 100%
        elif [ "$curVol" -lt "$limit" ]
        then
            pactl set-sink-volume "$active_sink" "+$inc%"
        fi
    elif [ "$curVol" -le "$maxvol" ] && [ "$curVol" -ge "$maxlimit" ]
    then
        pactl set-sink-volume "$active_sink" "$maxvol%"
    elif [ "$curVol" -lt "$maxlimit" ]
    then
        pactl set-sink-volume "$active_sink" "+$inc%"
    fi

    getCurVol

    if [ ${osd} = 'yes' ]
    then
        # Adjust the OSD command for PipeWire if needed
        notify-send "Volume: $curVol"
    fi

    if [ ${autosync} = 'yes' ]
    then
        volSync
    fi
}

function volDown {

    pactl set-sink-volume "$active_sink" "-$inc%"
    getCurVol

    if [ ${osd} = 'yes' ]
    then
        # Adjust the OSD command for PipeWire if needed
        notify-send "Volume: $curVol"
    fi

    if [ ${autosync} = 'yes' ]
    then
        volSync
    fi

}

function getSinkInputs {
    input_array=$(pactl list sink-inputs | grep 'Sink Input #' | awk '{print $3}')
}

function volSync {
    getSinkInputs "$active_sink"
    getCurVol

    for each in $input_array
    do
        pactl set-sink-input-volume "$each" "$curVol%"
    done
}

function getCurVol {
    curVol=$(pactl list sinks | grep -A 10 "Sink #$active_sink$" | grep 'Volume:' | awk '{print $5}' | tr -d '%')
}

function volMute {
    case "$1" in
        mute)
            pactl set-sink-mute "$active_sink" 1
            curVol=0
            status=1
            ;;
        unmute)
            pactl set-sink-mute "$active_sink" 0
            getCurVol
            status=0
            ;;
    esac

    if [ ${osd} = 'yes' ]
    then
        # Adjust the OSD command for PipeWire if needed
        notify-send "Volume: ${curVol}% Mute: ${status}"
    fi

}

function volMuteStatus {
    curStatus=$(pactl list sinks | grep -A 10 "Sink #$active_sink$" | grep 'Mute:' | awk '{print $2}')
}

# Prints output for bar
# Listens for events for fast update speed
function listen {
    firstrun=0

    pactl subscribe 2>/dev/null | {
        while true; do
            {
                # If this is the first time just continue
                # and print the current state
                # Otherwise wait for events
                # This is to prevent the module being empty until
                # an event occurs
                if [ $firstrun -eq 0 ]
                then
                    firstrun=1
                else
                    read -r event || break
                    if ! echo "$event" | grep -e "on card" -e "on sink"
                    then
                        # Avoid double events
                        continue
                    fi
                fi
            } &>/dev/null
            output
        done
    }
}

function output() {
    reloadSink
    getCurVol
    volMuteStatus
    if [ -n "${curStatus}" ] && [ "${curStatus}" = 'yes' ]
    then
        echo "ﱝ mute"
    else
        if [ -n "${curVol}" ] && [ "$curVol" -gt 70 ]; then
            echo "$curVol%"
        elif [ -n "${curVol}" ] && [ "$curVol" -gt 30 ]; then
            echo "$curVol%"
        else
            echo "$curVol%"
        fi
    fi
} #}}}

reloadSink
case "$1" in
    --up)
        volUp
        ;;
    --down)
        volDown
        ;;
    --togmute)
        volMuteStatus
        if [ "$curStatus" = 'yes' ]
        then
            volMute unmute
        else
            volMute mute
        fi
        ;;
    --mute)
        volMute mute
        ;;
    --unmute)
        volMute unmute
        ;;
    --sync)
        volSync
        ;;
    --listen)
        # Listen for changes and immediately create new output for the bar
        # This is faster than having the script on an interval
        listen
        ;;
    *)
        # By default print output for bar
        output
        ;;
esac

