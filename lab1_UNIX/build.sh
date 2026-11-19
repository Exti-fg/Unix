#!/bin/sh

if [ -z "$1" ]; then
    echo "Ошибка: не указан исходный файл"
    echo "Использование: $0 <файл>"
    exit 1 # не указан файл в команде
fi

SRC_PATH="$1"

echo "Попытка сборки файла: $SRC_PATH"

if [ ! -f "$SRC_PATH" ]; then
    echo "Ошибка: файл '$SRC_PATH' не найден"
    exit 2 # файл не найден в аудитории
fi

echo "Анализ файла: $SRC_PATH"

TARGET_NAME=$(grep -i "^[[:space:]]*\(//\|/\*\|%\|#\)[[:space:]]*Output:" "$SRC_PATH" | head -1 | sed 's|.*Output:[[:space:]]*||')

if [ -z "$TARGET_NAME" ]; then
    echo "Ошибка: не найден комментарий 'Output:' в файле '$SRC_PATH'"
    echo "Добавьте комментарий: Output: имя_файла"
    exit 3 # не найден комментарий output
fi

echo "Найдено имя выходного файла: $TARGET_NAME"

TEMP_DIR=$(mktemp -d)

if [ ! -d "$TEMP_DIR" ]; then
    echo "Ошибка: не удалось создать временный каталог"
    exit 4 # что-то с созданием временной дирректории
fi

exit_handler() {
  local rc=$?
  trap - EXIT
  rm -rf -- "$TEMP_DIR"
  exit $rc
}

trap exit_handler EXIT INT TERM HUP QUIT PIPE

echo "Создан временный каталог: $TEMP_DIR"

SRC_FOLDER=$(dirname "$(realpath "$SRC_PATH")")
SRC_BASENAME=$(basename "$SRC_PATH")

echo "Исходный файл находится в: $SRC_FOLDER"

cp "$SRC_PATH" "$TEMP_DIR/"

cd "$TEMP_DIR" || exit 4 # что-то с созданием временной дирректории

FILE_EXT=$(echo "$SRC_BASENAME" | sed 's|.*\.||')

echo "Определено расширение: .$FILE_EXT"

case "$FILE_EXT" in
    c)
        echo "Компиляция C-программы..."
        cc -o "$TARGET_NAME" "$SRC_BASENAME" 2> build.log
        COMPILE_STATUS=$?
        ;;
    cpp|cxx|cc)
        echo "Компиляция C++ программы..."
        c++ -o "$TARGET_NAME" "$SRC_BASENAME" 2> build.log
        COMPILE_STATUS=$?
        ;;
    tex)
        echo "Компиляция TeX-документа..."
        # Убираем .pdf из имени, если оно там есть
    case "$TARGET_NAME" in
        *.pdf) TARGET_NAME="${TARGET_NAME%.pdf}" ;;
    esac
        pdflatex -interaction=nonstopmode -jobname="$TARGET_NAME" "$SRC_BASENAME" > build.log 2>&1
        COMPILE_STATUS=$?
        case "$TARGET_NAME" in
            *.pdf) ;;
            *) TARGET_NAME="$TARGET_NAME.pdf" ;;
        esac
        ;;
    *)
        echo "Ошибка: неизвестный тип файла '.$FILE_EXT'"
        echo "Поддерживаются: .c, .cpp, .cxx, .cc, .tex"
        exit 5 # неизвестный тип файла
        ;;
esac

if [ "$COMPILE_STATUS" -ne 0 ]; then
    echo "Ошибка: компиляция завершилась с кодом $COMPILE_STATUS"
    echo "--- Лог сборки ---"
    cat build.log
    echo "------------------"
    exit 6 # ошибка скомпилирования
fi

if [ ! -f "$TARGET_NAME" ]; then
    echo "Ошибка: компилятор не создал выходной файл '$TARGET_NAME'"
    exit 7 # выходной файл не создан
fi

cp "$TARGET_NAME" "$SRC_FOLDER/"

echo "Успешно! Файл '$TARGET_NAME' создан рядом с исходным файлом: $SRC_FOLDER/$TARGET_NAME"