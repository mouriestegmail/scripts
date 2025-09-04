#!/bin/bash
# Скрипт перемещает активное окно на левый монитор с новым размером:
# 50% ширины и 95% высоты целевого (левого) монитора.

# Файл для логов (вывод как в консоль, так и в файл)
LOG_FILE="/tmp/move_to_left_monitor.log"
: > "$LOG_FILE"  # Очистка лог-файла

log() {
    echo "$1"
    echo "$1" >> "$LOG_FILE"
}

log "==== $(date) ===="

# 1. Определяем активное окно
active_win=$(xdotool getactivewindow)
if [ -z "$active_win" ]; then
    log "Не удалось получить ID активного окна."
    exit 1
fi
log "Активное окно: $active_win"

# Снимаем максимизацию, чтобы окно можно было перемещать/изменять
wmctrl -ir "$active_win" -b remove,maximized_vert,maximized_horz
sleep 0.1

# 2. Получаем геометрию окна
win_geo=$(xdotool getwindowgeometry --shell "$active_win")
# Пример win_geo:
#   WINDOW=12345678
#   X=1931
#   Y=78
#   WIDTH=800
#   HEIGHT=600
win_x=$(echo "$win_geo" | grep "X=" | cut -d= -f2)
win_y=$(echo "$win_geo" | grep "Y=" | cut -d= -f2)
win_width=$(echo "$win_geo" | grep "WIDTH=" | cut -d= -f2)
win_height=$(echo "$win_geo" | grep "HEIGHT=" | cut -d= -f2)
log "Положение окна: X=$win_x, Y=$win_y, WIDTH=$win_width, HEIGHT=$win_height"

# Вычисляем точку центра окна
center_x=$(( win_x + win_width / 2 ))
center_y=$(( win_y + win_height / 2 ))
log "Центр окна: X=$center_x, Y=$center_y"

# 3. Получаем информацию о мониторах через xrandr
# Для каждого монитора получаем: имя, ширину, высоту, смещение X и Y.
declare -A monitor_geom  # ключ: имя монитора, значение: "width height offset_x offset_y"
monitors=()

while IFS= read -r line; do
    # Пример строки: 
    #   DP-2 connected primary 3840x2160+1920+0 ...
    mon_name=$(echo "$line" | awk '{print $1}')
    geom=$(echo "$line" | grep -oP '\d+x\d+\+\d+\+\d+')
    if [ -n "$geom" ]; then
        width=$(echo "$geom" | cut -dx -f1)
        rest=$(echo "$geom" | cut -dx -f2)  # например, "2160+1920+0"
        height=$(echo "$rest" | cut -d'+' -f1)
        offset_x=$(echo "$rest" | cut -d'+' -f2)
        offset_y=$(echo "$rest" | cut -d'+' -f3)
        monitor_geom["$mon_name"]="$width $height $offset_x $offset_y"
        monitors+=("$mon_name")
        log "Монитор $mon_name: WIDTH=$width, HEIGHT=$height, X=$offset_x, Y=$offset_y"
    fi
done < <(xrandr --query | grep " connected")

if [ ${#monitors[@]} -eq 0 ]; then
    log "Мониторы не найдены."
    exit 1
fi

# 4. Определяем, на каком мониторе находится окно.
current_monitor=""
for mon in "${monitors[@]}"; do
    geom="${monitor_geom[$mon]}"
    IFS=' ' read -r m_width m_height m_x m_y <<< "$geom"
    if (( center_x >= m_x && center_x < m_x + m_width &&
          center_y >= m_y && center_y < m_y + m_height )); then
        current_monitor="$mon"
        log "Окно находится на мониторе: $current_monitor"
        break
    fi
done

if [ -z "$current_monitor" ]; then
    log "Не удалось определить монитор, на котором находится окно."
    exit 1
fi

# 5. Находим левый монитор.
# Из всех мониторов с offset_x меньше, чем у текущего,
# выбираем тот, у которого offset_x максимальный (ближе всего к текущему).
current_geom="${monitor_geom[$current_monitor]}"
IFS=' ' read -r cur_width cur_height cur_x cur_y <<< "$current_geom"

left_monitor=""
left_candidate_x=-99999
for mon in "${monitors[@]}"; do
    geom="${monitor_geom[$mon]}"
    IFS=' ' read -r m_width m_height m_x m_y <<< "$geom"
    if (( m_x < cur_x )); then
        if (( m_x > left_candidate_x )); then
            left_monitor="$mon"
            left_candidate_x=$m_x
        fi
    fi
done

if [ -z "$left_monitor" ]; then
    log "Левый монитор не найден. Оставляем окно на текущем мониторе."
    exit 0
fi

log "Левый монитор: $left_monitor"
left_geom="${monitor_geom[$left_monitor]}"
IFS=' ' read -r left_width left_height left_x left_y <<< "$left_geom"
log "Геометрия левого монитора: WIDTH=$left_width, HEIGHT=$left_height, X=$left_x, Y=$left_y"

# 6. Вычисляем новые размеры и позицию окна.
# Новые размеры: 50% от ширины и 95% от высоты левого монитора.
new_width=$(( left_width / 2 ))
new_height=$(( left_height * 95 / 100 ))
# Позиция: левый край левого монитора и вертикально центрированное положение.
new_x=$left_x
new_y=$(( left_y + (left_height - new_height) / 2 ))
log "Новый размер окна: WIDTH=$new_width, HEIGHT=$new_height"
log "Новая позиция окна: X=$new_x, Y=$new_y"

# 7. Перемещаем и изменяем размер окна.
xdotool windowmove "$active_win" "$new_x" "$new_y"
xdotool windowsize "$active_win" "$new_width" "$new_height"
log "Операция завершена."
