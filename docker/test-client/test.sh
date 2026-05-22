#!/bin/bash

echo "  Тестирование X-Forwarded-For"
echo -e "\n"

echo "Маршрут: nginx1-svc/direct"
curl -s http://nginx1-svc/direct
echo -e "\n"

echo "Маршрут: nginx2-svc/direct"
curl -s http://nginx2-svc/direct
echo -e "\n"

echo "Маршрут: nginx3-svc/direct"
curl -s http://nginx3-svc/direct
echo -e "\n"

echo "Маршрут: nginx1-svc/chain"
curl -s http://nginx1-svc/chain
echo -e "\n"

echo "Заголовок: X-Forwarded-For: 1.2.3.4"
curl -s -H "X-Forwarded-For: 1.2.3.4" http://nginx1-svc/chain
echo -e "\n"

echo "Заголовок: X-Forwarded-For: 5.6.7.8"
curl -s -H "X-Forwarded-For: 5.6.7.8" http://nginx2-svc/direct
echo -e "\n"

echo "Заголовок: X-Forwarded-For: 9.10.11.12"
curl -s -H "X-Forwarded-For: 9.10.11.12" http://nginx3-svc/direct
echo -e "\n"

echo "Заголовок: X-Forwarded-For: 10.0.0.1, 10.0.0.2, 10.0.0.3"
curl -s -H "X-Forwarded-For: 10.0.0.1, 10.0.0.2, 10.0.0.3" http://nginx1-svc/chain
echo -e "\n"

