#!/bin/sh

SHARED_DIR="/shared"
LOCK_FILE="${SHARED_DIR}/.lock"
CONTAINER_ID=$(hostname)
local_counter=0

mkdir -p "$SHARED_DIR"

echo "Контейнер $CONTAINER_ID запущен и готов к работе."

exec 9>"$LOCK_FILE"


while true; do

    flock -x 9
    i=1

    while true; do

      FILE_NAME=$(printf "%03d" "$i")
      TARGET_FILE="${SHARED_DIR}/${FILE_NAME}"

      if [ ! -e "$TARGET_FILE" ]; then
        local_counter=$((local_counter + 1))
        echo "${CONTAINER_ID} ${local_counter}" > "$TARGET_FILE"
        break
      fi

      i=$((i + 1))

    done

    flock -u 9
    echo "Создан файл: ${FILE_NAME} (Запись: ${CONTAINER_ID} ${local_counter})"
    sleep 1

    
    rm "$TARGET_FILE"
    echo "Удален файл: ${FILE_NAME}"

    sleep 1

done