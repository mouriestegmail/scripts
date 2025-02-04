#!/bin/bash

PROFILE_NAME="Profile 1"  # Укажи правильный профиль
APP_URL="https://chatgpt.com/"
CHROME_CMD="google-chrome --profile-directory=\"$PROFILE_NAME\" --app=$APP_URL"

# Проверяем, запущено ли окно с ChatGPT
if wmctrl -l | grep -i "ChatGPT" > /dev/null; then
    echo "ChatGPT уже запущен. Активируем окно."
    wmctrl -a "ChatGPT"  # Переключаемся на окно ChatGPT
    exit 0
fi

# Если окно не найдено – запускаем Chrome
eval $CHROME_CMD &

exit 0



#!/bin/bash

PROFILE_NAME="Profile 1"  # Замени на свой профиль
APP_URL="https://chatgpt.com/"
CHROME_CMD='google-chrome --profile-directory="Profile 1" '

# Проверяем, запущен ли Chrome с этим URL
if pgrep -f "$APP_URL" > /dev/null; then
    echo "ChatGPT уже запущен. Активируем окно."
    wmctrl -a "ChatGPT"  # Переключаемся на окно ChatGPT
    exit 0
fi

# Если не запущено – запускаем
google-chrome --profile-directory="Profile 1" --app=$APP_URL



