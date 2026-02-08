#!/usr/bin/env bash

find_touch_device() {
    local input_devices_file="/proc/bus/input/devices"
    local device_name="GXTP7863"
    local unknown_marker="UNKNOWN"
    
    while IFS= read -r line; do
        if [[ $line == N:*"$device_name"* && $line == *"$unknown_marker"* ]]; then
            local in_device_block=1
            local sysfs_path=""
            
            while IFS= read -r device_line && [[ $in_device_block -eq 1 ]]; do
                if [[ -z $device_line ]]; then
                    in_device_block=0
                elif [[ $device_line == S:* ]]; then
                    sysfs_path=${device_line#S: Sysfs=}
                fi
            done
            
            if [[ -n $sysfs_path ]]; then
                echo "$sysfs_path"
                return 0
            fi
        fi
    done < "$input_devices_file"
    
    return 1
}

echo "Поиск устройства touchscreen..."
sysfs_path=$(find_touch_device)

if [[ -z $sysfs_path ]]; then
    echo "Ошибка: устройство touchscreen не найдено"
    echo "Искал устройство с 'GXTP7863' и 'UNKNOWN' в названии"
    exit 1
fi

inhibit_path="/sys${sysfs_path}/inhibited"
echo "Попытка использовать путь: $inhibit_path"

if [[ ! -f $inhibit_path ]]; then
    echo "Ошибка: файл inhibited не найден по указанному пути"
    echo "Проверяем альтернативные пути..."
    
    alternative_path=$(echo "$inhibit_path" | sed 's/\.000[0-9]\+/.0001/')
    
    if [[ -f "$alternative_path" ]]; then
        inhibit_path="$alternative_path"
        echo "Найден альтернативный путь: $inhibit_path"
    else
        echo "Ошибка: файл inhibited не найден ни по одному из путей"
        echo "Проверьте вручную правильный путь к устройству"
        exit 1
    fi
fi

echo "Записываем 1 в $inhibit_path..."
echo 1 > "$inhibit_path"

if [[ $? -eq 0 ]]; then
    echo "Успешно! Touchscreen заблокирован."
else
    echo "Ошибка при записи в файл inhibited"
    exit 1
fi
