#!/bin/bash

# Проверка, если уже запущено приложение с URL https://app.ringcentral.com/
if pgrep -f "ringcentral" > /dev/null; then
    echo "Приложение уже запущено."
    # Используем wmctrl для активации окна
    wmctrl -a "RingCentral" || echo "Не удалось активировать окно."
    exit 0  # Завершаем скрипт, так как приложение уже запущено
fi

# Запуск Chrome в режиме App
google-chrome --app=https://app.ringcentral.com/ &
