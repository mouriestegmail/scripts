#!/bin/bash

PROFILE_NAME="Default"  # Укажи правильный профиль
APP_URL="https://app.ringcentral.com/"
CHROME_CMD="google-chrome --profile-directory=\"$PROFILE_NAME\" --app=$APP_URL"

# Проверяем, запущено ли окно с app.ringcentral.com
if wmctrl -l | grep -i "app.ringcentral.com" > /dev/null; then
    echo "app.ringcentral.com уже запущен. Активируем окно."
    wmctrl -a "app.ringcentral.com"  # Переключаемся на окн
    exit 0
fi

# Если окно не найдено – запускаем Chrome
eval $CHROME_CMD &

