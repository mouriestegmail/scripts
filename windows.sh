#!/bin/bash
# Этот скрипт реализует следующую логику:
# 1. Если активное окно максимально (по вертикали и горизонтали):
#    • Снимаем максимизацию.
#    • Получаем его геометрию и вычисляем площадь.
#    • Определяем текущий монитор (используя центр окна) и его размеры.
#    • Если площадь окна меньше половины площади текущего монитора – скрипт ничего не меняет.
#    • Иначе окно изменяется до размеров, равных 50% ширины и 50% высоты монитора (то есть занимает четверть экрана) и центрируется.
# 2. Если окно не максимально – окно максимизируется.

LOG_FILE="/tmp/toggle_window.log"
: > "$LOG_FILE"  # Очистка лог-файла при запуске

# Функция логирования: выводит сообщение в stderr и записывает его в лог-файл.
log() {
    echo "$1" | tee -a "$LOG_FILE" >&2
}

# Обёртка для вызова xdotool: логирует команду, её параметры, вывод и код возврата.
run_xdotool() {
    log "       xdotool command: xdotool $*"
    out=$(xdotool "$@" 2>&1)
    ret=$?
    log "       xdotool exit code: $ret"
    if [ -n "$out" ]; then
        log "       xdotool output: $out"
    fi
    echo -n "$out"
    return $ret
}

# Обёртка для вызова wmctrl: логирует команду, её параметры, вывод и код возврата.
run_wmctrl() {
    log "       wmctrl command: wmctrl $*"
    out=$(wmctrl "$@" 2>&1)
    ret=$?
    log "       wmctrl exit code: $ret"
    if [ -n "$out" ]; then
        log "       wmctrl output: $out"
    fi
    echo -n "$out"
    return $ret
}

log "==== $(date) ===="

# 1. Получаем ID активного окна
ACTIVE_WINDOW=$(run_xdotool getactivewindow)
if [ -z "$ACTIVE_WINDOW" ]; then
    log "Не удалось определить активное окно."
    exit 1
fi
log "Активное окно: $ACTIVE_WINDOW"

# 2. Получаем состояние окна через xprop
STATE=$(xprop -id "$ACTIVE_WINDOW" _NET_WM_STATE 2>&1)
log "xprop _NET_WM_STATE: $STATE"

# 3. Если окно максимально (по вертикали и горизонтали)…
if echo "$STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_VERT" && \
   echo "$STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_HORZ"; then

    log "Окно максимально. Снимаем максимизацию."

    # Снимаем максимизацию
    run_wmctrl -ir "$ACTIVE_WINDOW" -b remove,maximized_vert,maximized_horz

    sleep 0.1

    # Получаем геометрию окна (с помощью xdotool)
    win_geo=$(run_xdotool getwindowgeometry --shell "$ACTIVE_WINDOW")
    win_x=$(echo "$win_geo" | grep "X=" | cut -d= -f2)
    win_y=$(echo "$win_geo" | grep "Y=" | cut -d= -f2)
    win_width=$(echo "$win_geo" | grep "WIDTH=" | cut -d= -f2)
    win_height=$(echo "$win_geo" | grep "HEIGHT=" | cut -d= -f2)
    log "Положение окна: X=$win_x, Y=$win_y, WIDTH=$win_width, HEIGHT=$win_height"

    # Вычисляем площадь окна
    win_area=$(( win_width * win_height ))
    log "Площадь окна: $win_area"

    # Вычисляем центр окна
    center_x=$(( win_x + win_width / 2 ))
    center_y=$(( win_y + win_height / 2 ))
    log "Центр окна: ($center_x, $center_y)"

    # 4. Определяем текущий монитор, где находится окно, используя данные xrandr
    current_mon=""
    monitor_width=0
    monitor_height=0
    monitor_x=0
    monitor_y=0
    while IFS= read -r line; do
        # Пример строки: "eDP-1 connected 1920x1080+0+0 ..."
        mon_name=$(echo "$line" | awk '{print $1}')
        geom=$(echo "$line" | grep -oP '\d+x\d+\+\d+\+\d+')
        if [ -n "$geom" ]; then
            m_width=$(echo "$geom" | cut -d'x' -f1)
            tmp=$(echo "$geom" | cut -d'x' -f2)  # Например, "1080+0+0"
            m_height=$(echo "$tmp" | cut -d'+' -f1)
            m_x=$(echo "$tmp" | cut -d'+' -f2)
            m_y=$(echo "$tmp" | cut -d'+' -f3)
            # Если центр окна попадает в этот монитор, то считаем его текущим
            if (( center_x >= m_x && center_x < m_x + m_width && center_y >= m_y && center_y < m_y + m_height )); then
                current_mon="$mon_name"
                monitor_width=$m_width
                monitor_height=$m_height
                monitor_x=$m_x
                monitor_y=$m_y
                log "Текущий монитор: $mon_name, геометрия: width=$m_width, height=$m_height, x=$m_x, y=$m_y"
                break
            fi
        fi
    done < <(xrandr --query | grep " connected")

    # Если не удалось определить монитор – используем размеры всего экрана (xdpyinfo)
    if [ -z "$current_mon" ]; then
        log "Не удалось определить текущий монитор, используем размеры всего экрана."
        dims=$(xdpyinfo | grep dimensions | awk '{print $2}')
        monitor_width=${dims%x*}
        monitor_height=${dims#*x}
        monitor_x=0
        monitor_y=0
        log "Геометрия: width=$monitor_width, height=$monitor_height, x=0, y=0"
    fi

    # 5. Вычисляем площадь текущего монитора и её половину
    monitor_area=$(( monitor_width * monitor_height ))
    half_monitor_area=$(( monitor_area / 2 ))
    log "Площадь монитора: $monitor_area, половина: $half_monitor_area"

    # 6. Если площадь окна меньше половины площади монитора – ничего не делаем.
    if (( win_area < half_monitor_area )); then
        log "Площадь окна ($win_area) меньше половины площади монитора ($half_monitor_area). Никаких дальнейших действий."
        exit 0
    fi

    log "Площадь окна больше или равна половине монитора. Меняем размеры окна до четверти экрана."

    # 7. Вычисляем новые размеры – 50% от ширины и 50% от высоты монитора
    new_width=$(( monitor_width / 2 ))
    new_height=$(( monitor_height / 2 ))
    # Центрируем окно на мониторе
    new_x=$(( monitor_x + (monitor_width - new_width) / 2 ))
    new_y=$(( monitor_y + (monitor_height - new_height) / 2 ))
    log "Новая геометрия окна: width=$new_width, height=$new_height, x=$new_x, y=$new_y"

    # 8. Перемещаем окно и задаем новые размеры
    run_xdotool windowmove "$ACTIVE_WINDOW" "$new_x" "$new_y"
    run_xdotool windowsize "$ACTIVE_WINDOW" "$new_width" "$new_height"
    log "Окно перемещено и изменено до размера четверти экрана."

else
    log "Окно не максимально. Устанавливаем его в размер текущего монитора."

    # Получаем геометрию окна (можно переиспользовать win_geo, но лучше пересчитать)
    win_geo=$(run_xdotool getwindowgeometry --shell "$ACTIVE_WINDOW")
    win_x=$(echo "$win_geo" | grep "X=" | cut -d= -f2)
    win_y=$(echo "$win_geo" | grep "Y=" | cut -d= -f2)
    win_width=$(echo "$win_geo" | grep "WIDTH=" | cut -d= -f2)
    win_height=$(echo "$win_geo" | grep "HEIGHT=" | cut -d= -f2)

    center_x=$(( win_x + win_width / 2 ))
    center_y=$(( win_y + win_height / 2 ))

    current_mon=""
    monitor_width=0
    monitor_height=0
    monitor_x=0
    monitor_y=0
    while IFS= read -r line; do
        mon_name=$(echo "$line" | awk '{print $1}')
        geom=$(echo "$line" | grep -oP '\d+x\d+\+\d+\+\d+')
        if [ -n "$geom" ]; then
            m_width=$(echo "$geom" | cut -d'x' -f1)
            tmp=$(echo "$geom" | cut -d'x' -f2)
            m_height=$(echo "$tmp" | cut -d'+' -f1)
            m_x=$(echo "$tmp" | cut -d'+' -f2)
            m_y=$(echo "$tmp" | cut -d'+' -f3)
            if (( center_x >= m_x && center_x < m_x + m_width && center_y >= m_y && center_y < m_y + m_height )); then
                current_mon="$mon_name"
                monitor_width=$m_width
                monitor_height=$m_height
                monitor_x=$m_x
                monitor_y=$m_y
                log "Текущий монитор: $mon_name, геометрия: width=$m_width, height=$m_height, x=$m_x, y=$m_y"
                break
            fi
        fi
    done < <(xrandr --query | grep " connected")

    if [ -z "$current_mon" ]; then
        log "Не удалось определить текущий монитор, используем размеры всего экрана."
        dims=$(xdpyinfo | grep dimensions | awk '{print $2}')
        monitor_width=${dims%x*}
        monitor_height=${dims#*x}
        monitor_x=0
        monitor_y=0
        log "Геометрия: width=$monitor_width, height=$monitor_height, x=0, y=0"
    fi

    # Удаляем все состояния, которые могут мешать
    run_wmctrl -ir "$ACTIVE_WINDOW" -b remove,sticky,above,below,fullscreen,maximized_vert,maximized_horz
    run_wmctrl -ir "$ACTIVE_WINDOW" -b remove,_NET_WM_STATE_TILED

    # Задаём новые размеры
    run_xdotool windowmove "$ACTIVE_WINDOW" "$monitor_x" "$monitor_y"
    run_xdotool windowsize "$ACTIVE_WINDOW" "$monitor_width" "$monitor_height"
    log "Окно установлено в размер монитора."
fi

exit 0
