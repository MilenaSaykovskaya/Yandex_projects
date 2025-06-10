/* Проект «Яндекс Афиша»
 * Цель проекта: изучить изменения пользовательских предпочтений и популярности событий осенью 2024 года
 * Автор: Сайковская Милена
*/


-- Часть 1. Знакомство с данными

-- 1) Взаимосвязь между таблицами: 
-- Какие поля являются первичными ключами в таблицах, а какие — внешними. Оценим типы связей: встречаются ли между таблицами отношения «один к одному», 
-- один ко многим» или «многие ко многим.

-- Выводим имена всех схем базы данных:
SELECT nspname AS schema_name
FROM pg_catalog.pg_namespace;
--   schema_name
--------------------
--   pg_toast
--   pg_catalog
--   public
--   information_schema
--   afisha

-- Выводим названия всех таблиц схемы afisha:
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'afisha';
--   table_name
--------------------
--   city
--   events
--   purchases
--   regions
--   venues

-- Выводим названия всех схем и таблиц в базе данных 
SELECT table_schema, table_name
FROM information_schema.tables;
--   table_schema    |    table_name
---------------------+------------------
--   pg_catalog      |   pg_subscription
--- ...

-- Выводим названия всех полей и их тип во всех таблицах схемы afisha
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'afisha'
ORDER BY 1;
--  table_name  |  column_name  |  data_type
----------------+---------------+--------------
--    city      |   region_id   |   integer
--    city      |   city_id     |   integer
-- ...

-- Выводим информацию о первичных и внешних ключах таблиц из схемы afisha
SELECT table_schema, table_name, column_name, constraint_name
FROM information_schema.key_column_usage
WHERE table_schema = 'afisha';
/*
--  table_schema  |  table_name  |  column_name  |  constraint_name
------------------+--------------+---------------+----------------------
--    afisha      |     city     |    city_id    |     city_pkey
--    afisha      |     city     |   region_id   |     city_region_id_fkey
-- ...
 ПЕРВИЧНЫЙ КЛЮЧ таблицы city: city_id, ВНЕШНИЙ КЛЮЧ city: region_id (ссылается на region_id в таблице regions)
 ПЕРВИЧНЫЙ КЛЮЧ таблицы events: event_id, ВНЕШНИЙ КЛЮЧ events: city_id (ссылается на city_id в таблице city), venue_id(ссылается на venue_id в таблице venues)
 ПЕРВИЧНЫЙ КЛЮЧ таблицы purchases: order_id, ВНЕШНИЙ КЛЮЧ city: event_id (ссылается на venue_id в таблице venues), event_id (это может быть ошибка, если это не дублирующийся внешний ключ, но пока просто зафиксируем)
 ПЕРВИЧНЫЙ КЛЮЧ таблицы regions: region_id
 ПЕРВИЧНЫЙ КЛЮЧ таблицы venues: venue_id.
 Оценка типов связей:
   1. city - regions
  Один к одному (может быть или не быть один к одному, так как внешний ключ в city указывает на regions, но в regions может быть множество cities) 
   2. events - city
  Один ко многим (каждый город может иметь много событий, но каждое событие привязано только к одному городу)
   3. events - venues
  Один ко многим (каждое событие происходит в одном месте, но каждое место может использоваться для многих событий)
   4. purchases - events
  Один ко многим (каждое событие может быть куплено многими покупателями, но каждая покупка относится к одному событию)
 */


-- 2) Содержимое таблиц: 
-- Соответствуют ли данные описанию и в каком объёме они представлены.

-- Выведем первый строки, общее количество строк для каждой таблицы и кол-во уникальных значений первичного ключа
SELECT *
FROM afisha.events e 
LIMIT 5;
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT event_id) AS total_events
FROM afisha.events;
-- Таблица events содержит 22 484 строки. Уникальное количество значений в поле event_id равно числу строк в таблице, значит поле является первичным ключом.
--  Первые строки таблицы:
--  event_id  |            event_name_code            | event_type_description  |  event_type_main  |  organizers  |  city_id  |  venue_id
--------------+---------------------------------------+-------------------------+----------------------------------------------------------------
--    4436	  |  e4f26fba-da77-4c61-928a-6c3e434d793f |	      спектакль	        |        театр	    |      №4893	|     2	   |    1600
--    5785	  |  5cc08a60-fdea-4186-9bb2-bffc3603fb77 |	      спектакль	        |        театр	    |      №1931	|    54	   |    2196
--    8817	  |  8e379a89-3a10-4811-ba06-ec22ebebe989 |	      спектакль	        |        театр	    |      №4896	|     2	   |    4043
-- ...
-- На первый взгляд данные соответствуют описанию.

SELECT *
FROM afisha.purchases p 
LIMIT 5;
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT order_id) AS total_orders
FROM afisha.purchases;
-- Таблица purchases содержит 292 034 строки. Уникальное количество значений в поле order_id равно числу строк в таблице, значит поле является первичным ключом.
--  Первые строки таблицы:
--   order_id |            user_id            |        created_dt_msc         |          created_ts_msk          | event_id | cinema_circuit | age_limit | currency_code | device_type_canonical | revenue | service_name | tickets_count | total
--------------+-------------------------------+-------------------------------+----------------------------------+----------+----------------+-----------+---------------+-----------------------+---------+--------------+---------------+--------
--     1      | 3ebd0c4b59f6bdd               | 2024-08-08 00:00:00.000       | 2024-08-08 15:01:11.000          | 555432   | нет            | 16        | rub           | mobile                | 568.43  | Облачко      | 2             | 5684.33
--    30      | 1a66f181a803c75               | 2024-09-05 00:00:00.000       | 2024-09-05 19:44:21.000          | 149337   | нет            | 16        | rub           | mobile                | 575.08  | Край билетов | 2             | 6389.80
--    59      | 1a66f181a803c75               | 2024-07-25 00:00:00.000       | 2024-07-25 10:09:41.000          | 269938   | нет            | 12        | rub           | desktop               | 402.51  | Лови билет!  | 4             | 6708.45
-- ...
-- На первый взгляд данные соответствуют описанию.

SELECT *
FROM afisha.regions r 
LIMIT 5;
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT region_id) AS total_regions
FROM afisha.regions;
-- Таблица regions содержит 81 строку. Уникальное количество значений в поле region_id равно числу строк в таблице, значит поле является первичным ключом.
--  Первые строки таблицы:
--   region_id    |    region_name
------------------+------------------
--   873          |   Североярская область
--   874          |   Залесский край
--   875          |   Горноземский регион
-- ...
-- На первый взгляд данные соответствуют описанию.

SELECT *
FROM afisha.venues v 
LIMIT 5;
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT venue_id) AS total_venues
FROM afisha.venues;
-- Таблица venues содержит 3228 строк. Уникальное количество значений в поле venue_id равно числу строк в таблице, значит поле является первичным ключом.
--  Первые строки таблицы:
--  venue_id  |            venue_name                        |                address
--------------+------------------------------------------------+-----------------------------------------------------------
--    894     |  Научный центр "Кубок" и партнеры            |  наб. Мелиоративная, д. 7 стр. 93
--    895     |  Литературный музей "Нирвана" Групп          |  наб. Придорожная, д. 63 стр. 7
--    897     |  Мастерская графического дизайна "Финал" Лтд |  бул. Славянский, д. 60
-- ...
-- На первый взгляд данные соответствуют описанию.

SELECT *
FROM afisha.city c 
LIMIT 5;
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT city_id) AS total_cities
FROM afisha.city;
-- Таблица city содержит 353 строк. Уникальное количество значений в поле city_id равно числу строк в таблице, значит поле является первичным ключом.
--  Первые строки таблицы:
--  city_id  |     city_name   |  region_id
-------------+-----------------+-------------------
--     2     |  Озёрск         |  873
--     4     |  Горноставинск  |  874
--     5     |  Травяниново    |  875
-- ...
-- На первый взгляд данные соответствуют описанию.


-- 3) Корректность данных:
-- Проверим  уникальность идентификаторов, наличие пропусков, корректность написания категориальных данных, например типов устройств, 
-- названий городов и регионов, кодов валюты.

-- Вычислим долю строк с пропусками в таблице events:
SELECT 1 - CAST(COUNT(event_name_code) AS real) / COUNT(*)
FROM afisha.events;
-- 0
SELECT 1 - CAST(COUNT(event_type_description) AS real) / COUNT(*)
FROM afisha.events;
-- 0
SELECT 1 - CAST(COUNT(event_type_main) AS real) / COUNT(*)
FROM afisha.events;
-- 0
SELECT 1 - CAST(COUNT(organizers) AS real) / COUNT(*)
FROM afisha.events;
-- 0
SELECT 1 - CAST(COUNT(city_id) AS real) / COUNT(*)
FROM afisha.events;
-- 0
SELECT 1 - CAST(COUNT(venue_id) AS real) / COUNT(*)
FROM afisha.events;
-- 0
-- В таблице events поля с пропусками отсутствуют.

-- Вычислим долю строк с пропусками в таблице purchases:
SELECT 1 - CAST(COUNT(order_id) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(user_id) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(created_dt_msk) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(created_ts_msk) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(event_id) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(cinema_circuit) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(age_limit) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(currency_code) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(device_type_canonical) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(revenue) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(service_name) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(tickets_count) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
SELECT 1 - CAST(COUNT(total) AS real) / COUNT(*)
FROM afisha.purchases;
-- 0
-- В таблице purchases поля с пропусками отсутствуют.

-- Вычислим долю строк с пропусками в таблице regions:
SELECT 1 - CAST(COUNT(region_id) AS real) / COUNT(*)
FROM afisha.regions;
-- 0
SELECT 1 - CAST(COUNT(region_name) AS real) / COUNT(*)
FROM afisha.regions;
-- 0
-- В таблице regions поля с пропусками отсутствуют.

-- Вычислим долю строк с пропусками в таблице venues:
SELECT 1 - CAST(COUNT(venue_id) AS real) / COUNT(*)
FROM afisha.venues;
-- 0
SELECT 1 - CAST(COUNT(venue_name) AS real) / COUNT(*)
FROM afisha.venues;
-- 0
SELECT 1 - CAST(COUNT(address) AS real) / COUNT(*)
FROM afisha.venues;
-- 0
-- В таблице venues поля с пропусками отсутствуют.

-- Вычислим долю строк с пропусками в таблице city:
SELECT 1 - CAST(COUNT(city_id) AS real) / COUNT(*)
FROM afisha.city;
-- 0
SELECT 1 - CAST(COUNT(city_name) AS real) / COUNT(*)
FROM afisha.city;
-- 0
SELECT 1 - CAST(COUNT(region_id) AS real) / COUNT(*)
FROM afisha.city;
-- 0
-- В таблице city поля с пропусками отсутствуют.

-- Проверим уникальность идентификаторов в таблице events
SELECT event_id,
	COUNT(*) AS count
FROM afisha.events e 
GROUP BY 1
HAVING COUNT(*) > 1;
-- Дубликатов по идентификатору event_id не обнаружено.

-- Проверим уникальность идентификаторов в таблице purchases
SELECT order_id,
	COUNT(*) AS count
FROM afisha.purchases 
GROUP BY 1
HAVING COUNT(*) > 1;
-- Дубликатов по идентификатору order_id не обнаружено.

-- Проверим уникальность идентификаторов в таблице regions
SELECT region_id,
	COUNT(*) AS count
FROM afisha.regions 
GROUP BY 1
HAVING COUNT(*) > 1;
-- Дубликатов по идентификатору region_id не обнаружено.

-- Проверим уникальность идентификаторов в таблице venues
SELECT venue_id,
	COUNT(*) AS count
FROM afisha.venues 
GROUP BY 1
HAVING COUNT(*) > 1;
-- Дубликатов по идентификатору venue_id не обнаружено.

-- Проверим уникальность идентификаторов в таблице city
SELECT city_id,
	COUNT(*) AS count
FROM afisha.city 
GROUP BY 1
HAVING COUNT(*) > 1;
-- Дубликатов по идентификатору city_id не обнаружено.


-- Проверим коррекстность написания категориальных данных (типов устройств, названий городов и регионов, кодов валюты)
SELECT DISTINCT device_type_canonical
FROM afisha.purchases p;
--   device_type_canonical
-------------------------------
--       mobile
--       desktop
--       other
--       tablet
--       tv   
-- Типы устройств описаны корректно.

SELECT DISTINCT city_name
FROM afisha.city 
ORDER BY 1;
--     city_name
-------------------------------
--      Айкольск
--      Айсуак
--      Акбастау
-- ... 
-- Скорее всего, названия городов описаны корректно.

SELECT DISTINCT region_name
FROM afisha.regions 
ORDER BY 1;
--     region_name
-------------------------------
--      Белоярская область
--      Берестовский округ
--      Берёзовская область
-- ... 
-- Скорее всего, названия областей и округов описаны корректно.

SELECT DISTINCT currency_code
FROM afisha.purchases;
--     currency_code
-------------------------------
--      kzt
--      rub 
-- Категории кодов валют описаны корректно.

SELECT DISTINCT service_name 
FROM afisha.purchases
ORDER BY 1;
--     service_name
-------------------------------
--      Crazy ticket!
--      Show_ticket
-- ...


-- 4) Распределение заказов по основным категориям:
--  По типам мероприятий, устройствам, кодам валюты и другим категориям. Это поможет понять, как представлены данные 
-- (обратим внимание на категории с небольшим объёмом данных).

SELECT event_type_main,
 	COUNT(*) AS total_events
FROM afisha.events e 
GROUP BY 1
ORDER BY 2 DESC;
-- По типу мероприятия данные распределены следущим образом:
-- event_type_main   |   total_events
---------------------+----------------------
-- концерты          |      8 699
-- театр             |      7 090
-- другое            |      4 662
-- спорт             |        872
-- стендап           |        636
-- выставки          |        291
-- елки              |        215
-- фильм             |         19
-- Видно, что в данных превалируют концерты(8699), театры(7090) и категория "другое"(4662). Меньше всего информации о концертах(19).

SELECT device_type_canonical,
 	COUNT(*) AS total
 	FROM afisha.purchases p 
GROUP BY 1
ORDER BY 2 DESC;
-- По типу устройств данные распределены следущим образом:
-- device_type_canonical  |   total
--------------------------+----------------------
--    mobile              |    232 679
--    desktop             |     58 170
--    tablet              |      1 180
--    tv                  |          3
--    other               |          2
-- Видно, что в данных превалируют мобильные телефоны(232679) и стационарные компьютеры(58170). Меньше всего информации о тв(3) и категории "другое"(2).

SELECT currency_code,
 	COUNT(*) AS total
 	FROM afisha.purchases p 
GROUP BY 1
ORDER BY 2 DESC;
-- По коду валют данные распределены следущим образом:
-- currency_code  |   total
------------------+----------------------
--    rub         |    286 961
--    kzt         |      5 073
-- Видно, что в данных чаще встречается оплата рублями (286961 записей), чем тенге (5073 записей).

SELECT age_limit,
 	COUNT(*) AS total
 	FROM afisha.purchases p 
GROUP BY 1
ORDER BY 1;
-- По возрастным категориям данные распределены следущим образом:
-- age_limit  |   total
--------------+--------------
--    0       |    61 731
--    6       |    52 403
--   12       |    62 861
--   16       |    78 864
--   18       |    36 175
-- Видно, что в данных чаще встречается категория 16+ (78864 записей), самая редкая категория 18+ (36175 записей).

SELECT service_name,
 	COUNT(*) AS total
 	FROM afisha.purchases p 
GROUP BY 1
ORDER BY 2 DESC;
-- По билетным операторам данные распределены следущим образом:
--        service_name  |   total
------------------------+--------------
-- Билеты без проблем   |    63 932
--    Лови билет!       |    41 338
--  ...

-- 5) Возможные аномалии или некорректные значения в данных:
-- Изучим статистические данные по полю выручки (встречаются ли выбросы или другие особенности).

-- Общая статистика по revenue
SELECT currency_code,
    MIN(revenue) AS min_revenue,
    MAX(revenue) AS max_revenue,
    MAX(revenue) - MIN(revenue) AS amplitude,
    AVG(revenue) AS avg_revenue,
    percentile_disc(0.5) WITHIN GROUP (ORDER BY revenue) AS median_revenue,
    STDDEV(revenue) AS stddev_revenue,
    percentile_disc(0.99) WITHIN GROUP (ORDER BY revenue) AS perc_99,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN revenue < 0 THEN 1 END) AS negative_revenue_count,
    COUNT(CASE WHEN revenue IS NULL THEN 1 END) AS null_revenue_count,
    COUNT(CASE WHEN revenue = 0 THEN 1 END) AS zero_revenue_count
FROM 
    afisha.purchases
GROUP BY currency_code;
--  currency_code  |   min_revenue  |  max_revenue  |  amplitude  |  avg_revenue  |  median_revenue  |  stddev_revenue  |  perc_99  |  total_orders  |  negative_revenue_count  |  null_revenue_count  |  zero_revenue_count
-------------------+----------------+---------------+-------------+---------------+------------------+------------------+-----------+----------------+--------------------------+----------------------+-----------------------
--     kzt         |       0	    |    26 425.86	|  26 425.86  | 	4995.31   | 	 3698.8      |      4916.64	    |  17617.24	|     5073       |          	0           |           0          |          6
--     rub         |    -90.76	    |    81 174.54	|  81 265.3   | 	 547.57   | 	  346.18     |       870.62	    |   2570.8	|   286961       |            381           |           0          |       5766       

-- 6) Изучим период времени, за который представлены данные:
-- проверим, можно ли проследить влияние сезонности на данные.

-- Получаем количество заказов и общую выручку по месяцам
SELECT DATE_TRUNC('month', created_dt_msk) AS month,
    COUNT(order_id) AS total_orders,
    SUM(revenue) AS total_revenue
FROM afisha.purchases
GROUP BY 1
ORDER BY 1;
--         month             |   total_orders  |  total_revenue
-----------------------------+-----------------+-------------------
--  2024-06-01 00:00:00.000  |      34840	   |     37686740
--  2024-07-01 00:00:00.000  |      41112	   |     25180666
--  2024-08-01 00:00:00.000  |      45217	   |     28166784
--  2024-09-01 00:00:00.000  |      70265	   |     37820452
--  2024-10-01 00:00:00.000  |     100600	   |     53617692

-- Получаем количество заказов и общую выручку по кварталам
SELECT DATE_TRUNC('quarter', created_dt_msk) AS quarter,
    COUNT(order_id) AS total_orders,
    SUM(revenue) AS total_revenue
FROM afisha.purchases
GROUP BY quarter
ORDER BY quarter;
--         quarter           |   total_orders  |  total_revenue
-----------------------------+-----------------+-------------------
--  2024-04-01 00:00:00.000  |      34840	   |     37686740
--  2024-07-01 00:00:00.000  |     156594	   |     91167848
--  2024-10-01 00:00:00.000  |     100600	   |     53617692


	


