#!/bin/bash

PROFILE_NAME="Profile 1"  # Укажи правильный профиль
APP_CLASS="notion.so.Google-chrome"
APP_URL="https://www.notion.so/"

echo "Ищем запущенное окно с классом: $APP_CLASS"
WIN_ID=$(wmctrl -l -x | grep -i "$APP_CLASS" | awk '{print $1}' | head -n 1)

if [ -n "$WIN_ID" ]; then
    echo "ChatGPT уже запущен. Активируем окно (ID: $WIN_ID)."
    wmctrl -ia "$WIN_ID"
    exit 0
fi

echo "google-chrome --profile-directory=\"$PROFILE_NAME\" --app=\"$APP_URL\""
google-chrome --profile-directory="$PROFILE_NAME" --app="$APP_URL" &
