# Otus_project
Проектная работа
Демонстрация аварийного восстановления системы web-стенда с master-slave репликацией:

1. Загрузить на все виртуальные машины скрипты и папки из репозитория Otus_project;
2. На первой виртуальной машине (master) запустить 1_mysql_master.sh, после отработки скрипта узнать IP адресс машины;
3. На второй виртуальной машине (slave) запустить 2_mysql_replica.sh, ввести IP машины master, ввести лог-файл, ввести позицию бин-лога (последние два выводятся на мастере, скопировать оттуда);
4. На mastere и на slave выполнить рекомендуемые скриптом команды;
5. На master и на slave пройти по пути /etc/mysql/mariadb.conf.d/, открыть конфигурационный файл, по типу "50-server.cnf", убедиться, что указан только один bind-adress=0.0.0.0, остальные заккоментировать;
6. На slave ввести команду: sudo mariadb -e 'SHOW SLAVE STATUS\G' - убедиться, что всё работает корректно, нет ошибок;
7. На master и на slave запустить скрипт 3_backend.sh (скрипт устанавливает необходимые зависимости, устанавливает docker для установки prometheus и grafana);
8. На третьей машине (frontend) запустить скрипт 4_frontend.sh, ввести IP адрес первой машины (master), ввести IP адресс второй машины (slave) (Запрос ввода IP адресов реализован в скрипте);
9. Проверить, что метрики собираются: в браузере ввести - "*IP_frontend*:9113/metrics" МЕТРИКИ СОБИРАЮТСЯ ТОЛЬКО НА FRONTEND;
10. На frontend перейти в папку monitoring, из этой папки запустить docker-compose (sudo docker-compose up -d), через docker-compose поднимаются и prometheus и grafana;
11. В datasource.yml в строке "url:.." должен содержаться IP-frontend;
12. В prometheus.yml в области flask_nodes указать IP-master:5000 и IP-slave:5000, в области nginx указать IP-frontend:9113, в области mysql указать IP-master:9104 и IP-slave:9104;
13. В web-браузере зайти в grafana: *IP_frontend*:3000, в поле логин ввести admin, в поле пароль тоже admin;
14. В Grafana переходим в dackboards, там должен быть автоматически создан Flask, нажать на него и далее нажать на "Мониторинг Flusk-приложения";
15. В web-браузере перейти по IP-frontend, обновить страницу несколько раз, обновить страницу в grafana.

    Готово. Автоматическое восставление системы завершено. Мониторин производится. Репликация работает.
