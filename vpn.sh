#!/bin/sh

# Очищаем экран консоли
clear

# Цветовые коды для красивого вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Сброс цвета

# Путь к директории с файлами
DIR="/etc/sing-box"
CONFIG_FILE="$DIR/config.json"

# Переменная для отслеживания совпадающего файла
MATCHING_FILE=""

# Проверяем, существует ли config.json
if [ -f "$CONFIG_FILE" ]; then
  CONFIG_SIZE=$(wc -c < "$CONFIG_FILE") # Используем wc для получения размера файла
  
  # Получаем список файлов с расширением .json.bak
  FILES=$(ls $DIR/*.json.bak 2>/dev/null)

  # Проверка наличия файлов
  if [ -z "$FILES" ]; then
    echo -e "${RED}Нет файлов с расширением .json.bak в директории $DIR${NC}"
    exit 1
  fi

  # Сравниваем размеры файлов
  for FILE in $FILES; do
    FILE_SIZE=$(wc -c < "$FILE") # Используем wc для получения размера файла
    if [ "$FILE_SIZE" -eq "$CONFIG_SIZE" ]; then
      FILENAME=$(basename "$FILE" .json.bak)
      MATCHING_FILE="$FILENAME" # Сохраняем имя совпадающего файла
      echo -e "${GREEN}Using now: ${YELLOW}$FILENAME${NC}"
      break
    fi
  done
fi

# Получаем список файлов с расширением .json.bak
FILES=$(ls $DIR/*.json.bak 2>/dev/null)

# Выводим пронумерованный список
COUNT=1
echo -e "${RED}Found configs at $DIR:${NC}"
for FILE in $FILES; do
  FILENAME=$(basename "$FILE")
  # Проверяем, совпадает ли файл с тем, который был найден ранее
  if [ "$FILENAME" = "$MATCHING_FILE.json.bak" ]; then
    echo -e "${GREEN}+ ${YELLOW}$COUNT. $FILENAME${NC}${GREEN} + " # Добавляем галочку
  else
    echo -e "${YELLOW}$COUNT. $FILENAME${NC}" # Без галочки
  fi
  COUNT=$((COUNT + 1))
done

# Спрашиваем пользователя, какой файл он хочет выбрать
echo -e "${GREEN}Select config :${NC} \c"
read FILE_NUM

# Проверяем, что введено корректное число
if [ "$FILE_NUM" -lt 1 ] || [ "$FILE_NUM" -ge "$COUNT" ]; then
  echo -e "${RED}Некорректный выбор. Попробуйте снова.${NC}"
  exit 1
fi

# Получаем выбранный файл по номеру
SELECTED_FILE=$(echo "$FILES" | sed -n "${FILE_NUM}p")

# Копируем выбранный файл с новым именем config.json
cp "$SELECTED_FILE" "$CONFIG_FILE"

echo -e "${GREEN}Config $(basename "$SELECTED_FILE") installed.${NC}"

# Перезапуск службы sing-box
echo -e "${YELLOW}Restarting sing-box ...${NC}"
/etc/init.d/sing-box restart

# Проверка результата перезапуска
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Done.${NC}"
else
  echo -e "${RED}Error restarting sing-box.${NC}"
fi
