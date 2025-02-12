#!/bin/bash

# Получаем ID активного окна
ACTIVE_WINDOW=$(xdotool getactivewindow)

# Снимаем максимизацию (чтобы окно стало перемещаемым)
wmctrl -ir "$ACTIVE_WINDOW" -b remove,maximized_vert,maximized_horz

# Немного ждем, чтобы изменения применились
sleep 0.1

# Получаем текущие координаты окна
WINDOW_GEOMETRY=$(xdotool getwindowgeometry --shell "$ACTIVE_WINDOW")
WINDOW_X=$(echo "$WINDOW_GEOMETRY" | grep "X=" | cut -d= -f2)
WINDOW_Y=$(echo "$WINDOW_GEOMETRY" | grep "Y=" | cut -d= -f2)

# Получаем информацию о мониторах
MONITORS=$(xrandr --query | grep " connected" | awk '{print $1}')

# Собираем данные о каждом мониторе
declare -A MONITOR_DATA
for MONITOR in $MONITORS; do
    GEOMETRY=$(xrandr --query | grep "$MONITOR" | grep -oP '\d+x\d+\+\d+\+\d+')
    WIDTH=$(echo "$GEOMETRY" | cut -d'x' -f1)
    HEIGHT=$(echo "$GEOMETRY" | cut -d'x' -f2 | cut -d'+' -f1)
    X=$(echo "$GEOMETRY" | cut -d'+' -f2)
    Y=$(echo "$GEOMETRY" | cut -d'+' -f3)

    MONITOR_DATA["$MONITOR"]="$WIDTH:$HEIGHT:$X:$Y"
done

# Определяем текущий монитор
CURRENT_MONITOR=""
for MONITOR in "${!MONITOR_DATA[@]}"; do
    IFS=':' read -r MONITOR_WIDTH MONITOR_HEIGHT MONITOR_X MONITOR_Y <<< "${MONITOR_DATA["$MONITOR"]}"
    if (( WINDOW_X >= MONITOR_X && WINDOW_X < MONITOR_X + MONITOR_WIDTH && \
          WINDOW_Y >= MONITOR_Y && WINDOW_Y < MONITOR_Y + MONITOR_HEIGHT )); then
        CURRENT_MONITOR="$MONITOR"
        break
    fi
done

# Если текущий монитор найден
if [[ -n "$CURRENT_MONITOR" ]]; then
    IFS=':' read -r MONITOR_WIDTH MONITOR_HEIGHT MONITOR_X MONITOR_Y <<< "${MONITOR_DATA["$CURRENT_MONITOR"]}"
    
    # Проверяем, окно уже в левой половине?
    HALF_WIDTH=$((MONITOR_WIDTH / 2))
    if (( WINDOW_X == MONITOR_X && WINDOW_Y == MONITOR_Y )); then
        # Переход на соседний монитор (если он есть)
        PREVIOUS_MONITOR=""
        for MONITOR in "${!MONITOR_DATA[@]}"; do
            IFS=':' read -r NEXT_WIDTH NEXT_HEIGHT NEXT_X NEXT_Y <<< "${MONITOR_DATA["$MONITOR"]}"
            if (( NEXT_X + NEXT_WIDTH == MONITOR_X )); then
                PREVIOUS_MONITOR="$MONITOR"
                break
            fi
        done
        
        if [[ -n "$PREVIOUS_MONITOR" ]]; then
            IFS=':' read -r MONITOR_WIDTH MONITOR_HEIGHT MONITOR_X MONITOR_Y <<< "${MONITOR_DATA["$PREVIOUS_MONITOR"]}"
            xdotool windowmove "$ACTIVE_WINDOW" "$MONITOR_X" "$MONITOR_Y"
            xdotool windowsize "$ACTIVE_WINDOW" "$HALF_WIDTH" "$MONITOR_HEIGHT"
        fi
    else
        # Окно в левую половину текущего монитора
        xdotool windowmove "$ACTIVE_WINDOW" "$MONITOR_X" "$MONITOR_Y"
        xdotool windowsize "$ACTIVE_WINDOW" "$HALF_WIDTH" "$MONITOR_HEIGHT"
    fi
fi
