#!/bin/bash

# Получаем текущее значение, например: 'uint32 2'
current_raw=$(gsettings get org.cinnamon.desktop.interface scaling-factor)

# Извлекаем только последнюю цифру
current_scale=$(echo "$current_raw" | awk '{print $NF}')

# Проверяем и переключаем
if [ "$current_scale" -ne 1 ]; then
    new_scale=1
else
    new_scale=2
fi

# Устанавливаем новый масштаб
gsettings set org.cinnamon.desktop.interface scaling-factor "$new_scale"
