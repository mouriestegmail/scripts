#!/bin/bash

# Получаем ID активного окна
ACTIVE_WINDOW=$(xdotool getactivewindow)
[ -z "$ACTIVE_WINDOW" ] && exit 1

# Убираем привязку, максимизацию, fullscreen
wmctrl -ir "$ACTIVE_WINDOW" -b remove,maximized_vert,maximized_horz,fullscreen
wmctrl -ir "$ACTIVE_WINDOW" -b remove,_NET_WM_STATE_TILED

# Маленькая пауза, чтобы успело примениться
sleep 0.1

# Получаем геометрию окна
eval $(xdotool getwindowgeometry --shell "$ACTIVE_WINDOW")

# Центр окна
CENTER_X=$(( X + WIDTH / 2 ))
CENTER_Y=$(( Y + HEIGHT / 2 ))

# Находим монитор, в который попадает центр окна
while IFS= read -r line; do
    GEOM=$(echo "$line" | grep -oP '\d+x\d+\+\d+\+\d+')
    [ -z "$GEOM" ] && continue

    MON_X=$(echo "$GEOM" | cut -d'+' -f2)
    MON_Y=$(echo "$GEOM" | cut -d'+' -f3)
    MON_W=$(echo "$GEOM" | cut -d'x' -f1)
    MON_H=$(echo "$GEOM" | cut -d'x' -f2 | cut -d'+' -f1)

    if (( CENTER_X >= MON_X && CENTER_X < MON_X + MON_W &&
          CENTER_Y >= MON_Y && CENTER_Y < MON_Y + MON_H )); then
        # Устанавливаем новые размеры и позицию
        if [ "$MON_X" -lt 100 ]; then
          MON_X=0
        fi

        if [ "$MON_Y" -lt 100 ]; then
          MON_Y=0
        fi

        MON_H=$((MON_H - 50))

        echo $MON_X "  " $MON_Y "  " $MON_H

        xdotool windowmove "$ACTIVE_WINDOW" "$MON_X" "$MON_Y"
        xdotool windowsize "$ACTIVE_WINDOW" "$MON_W" "$MON_H"
        exit 0
    fi
done < <(xrandr | grep " connected")
