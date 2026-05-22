# Тестовый стенд X-Forwarded-For с цепочкой nginx в Kubernetes

## Описание проекта

Стенд состоит из трёх nginx-серверов в режиме обратного прокси, одного приложения и тестового клиента. Все сервисы разворачиваются в Kubernetes в namespace `nginx-forward`.

**Цель:** Продемонстрировать корректную обработку заголовка `X-Forwarded-For` при прохождении запроса через цепочку прокси-серверов и защиту от подделки этого заголовка.


# Применение манифестов
```bash
kubectl apply -f k8s/
```
 - Если поды упали, то скорее всего deployment применился раньше чем создался конфиг для nginx, просто перезапускаем deploy

# Проверям статус svc и deploy
kubectl get all -n nginx-forward -o wide

**Сервисы и их адреса:**

| Сервис      | DNS-имя       | Наименование порта | Порт  | Роль            |
|-------------|---------------|--------------------|-------|-----------------|
| nginx1      | nginx1-svc    | http               | 80    | Первый прокси   |
| nginx2      | nginx2-svc    | http               | 80    | Второй прокси   |
| nginx3      | nginx3-svc    | http               | 80    | Третий прокси   |
| nginx-web   | nginx-web-svc | http               | 8080  | Приложение      |
| test-client | -             | -                  | -     | Тестовый клиент |

**Маршруты:**

| URL               | Маршрут                                                |
|-------------------|--------------------------------------------------------|
| nginx1-svc/direct | test-client -> nginx1 -> nginx-web                     |
| nginx2-svc/direct | test-client -> nginx2 -> nginx-web                     |
| nginx3-svc/direct | test-client -> nginx3 -> nginx-web                     |
| nginx1-svc/chain  | test-client -> nginx1 -> nginx2 -> nginx3 -> nginx-web |
| nginx1-svc/       | test-client -> nginx1 -> nginx2 -> nginx3 -> nginx-web |


## Логика работы

### Формирование цепочки IP-адресов

1. **Первый nginx в цепочке** (тот, на который пришёл запрос от пользователя):
   - Очищает заголовок `X-Forwarded-For` директивой `proxy_set_header X-Forwarded-For ""`
   - Формирует новый заголовок из IP клиента (`$remote_addr`) и своего IP

2. **Последующие nginx в цепочке**:
   - Получают существующий заголовок через переменную `$http_x_forwarded_for`
   - Добавляют свой IP в конец цепочки

3. **Приложение**:
   - Получает итоговый заголовок с полной цепочкой IP-адресов
   - `Remote-Addr` содержит IP последнего прокси
   - Возвращает JSON с полученными заголовками

### Защита от подделки IP

- Любой пользователь может добавить заголовок `X-Forwarded-For` в свой запрос
- Первый nginx в цепочке всегда очищает этот заголовок
- Таким образом, поддельные IP-адреса никогда не попадают в приложение
- Защита работает независимо от того, на какой nginx пришёл запрос

## Как тестировать

### Одиночный прокси

```bash
kubectl exec -n nginx-forward test-client -- /test.sh
```
**Результат:**
```
Ожидаемый ответ:

json
{
    "X-Forwarded-For": "IP_TEST_CLIENT, IP_NGINX1",
    "Remote-Addr": "IP_NGINX1"
}
```

### Цепочка

**Команда:**
```bash
kubectl exec -n nginx-forward test-client -- curl -s http://nginx1-svc/chain
```

**Результат:**
```json
{
    "X-Forwarded-For": "IP_TEST_CLIENT, IP_NGINX1, IP_NGINX2, IP_NGINX3",
    "Remote-Addr": "IP_NGINX3"
}
```

