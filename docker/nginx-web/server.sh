#!/bin/bash

PORT=8080

# Если скрипт вызван с аргументом 'handle', обрабатываем HTTP запрос
if [ "$1" = "handle" ]; then
    # Функция обработки HTTP запроса
    local method path protocol
    x_forwarded_for="NOT_PRESENT"
    remote_addr="${SOCAT_PEERADDR:-unknown}"
    
    # Читаем строку запроса
    read -r method path protocol
    protocol=$(echo "$protocol" | tr -d '\r')
    
    # Читаем заголовки
    while IFS= read -r header; do
        header=$(echo "$header" | tr -d '\r')
        
        # Конец заголовков
        [ -z "$header" ] && break
        
        # Поиск X-Forwarded-For
        case "$header" in
            X-Forwarded-For:*)
                x_forwarded_for="${header#X-Forwarded-For: }"
                ;;
        esac
    done
    
    # Формируем ответ
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: application/json\r\n"
    printf "Connection: close\r\n"
    printf "\r\n"
    printf "{\n"
    printf "  \"X-Forwarded-For\": \"%s\",\n" "$x_forwarded_for"
    printf "  \"Remote-Addr\": \"%s\",\n" "$remote_addr"
    printf "  \"All-Headers\": {\n"
    printf "    \"X-Forwarded-For\": \"%s\"\n" "$x_forwarded_for"
    printf "  }\n"
    printf "}\n"
    
    exit 0
fi

# Основной код - запуск сервера
echo "Starting HTTP server on port $PORT..."
exec socat TCP-LISTEN:$PORT,reuseaddr,fork EXEC:"$0 handle"
