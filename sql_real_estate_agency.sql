/* Анализ данных для агентства недвижимости
 * Часть 1. Знакомство и обработка данных
 * Автор: Сайковская Милена
*/

-- ВРЕМЕННОЙ ИНТЕРВАЛ
SELECT MIN(first_day_exposition),
	MAX(first_day_exposition)
FROM real_estate.advertisement;

-- ТИПЫ НАСЕЛЕННЫХ ПУНКТОВ
SELECT DISTINCT type_id,
		type,
	COUNT(id) AS adv_total,
	COUNT(DISTINCT city_id) AS city_total
FROM real_estate.flats LEFT JOIN real_estate.type USING(type_id)
GROUP BY type_id, type
ORDER BY adv_total DESC, city_total DESC;

-- ВРЕМЯ АКТИВНОСТИ ОБЪЯВЛЕНИЯ
SELECT MIN(days_exposition),
	MAX(days_exposition),
	ROUND(AVG(days_exposition)::NUMERIC, 2) AS average,
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY days_exposition) AS median
FROM real_estate.advertisement;	

-- ДОЛЯ СНЯТЫХ С ПУБЛИКАЦИИ ОБЪЯВЛЕНИЙ 
SELECT ROUND(100*(SELECT COUNT(id) FROM real_estate.advertisement WHERE days_exposition IS NOT NULL) / COUNT(id)::NUMERIC, 2) AS perc
FROM real_estate.advertisement;

-- ОБЪЯВЛЕНИЯ САНКТ-ПЕТЕРБУРГА
SELECT ROUND(100*(SELECT COUNT(id) FROM real_estate.flats WHERE city_id IN (SELECT city_id FROM real_estate.city WHERE city='Санкт-Петербург'))
		/ COUNT(id)::NUMERIC, 2) AS spb_share
FROM real_estate.flats;

-- СТОИМОСТЬ КВАДРАТНОГО МЕТРА
WITH kv_m AS (
	SELECT id,
			ROUND(last_price::NUMERIC/total_area::NUMERIC, 2) AS price_per_kvm
	FROM real_estate.flats 
	LEFT JOIN real_estate.advertisement USING(id)
)
SELECT MIN(price_per_kvm),
 	   MAX(price_per_kvm),
 	   ROUND(AVG(price_per_kvm), 2) AS avg,
 	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY price_per_kvm) AS median
FROM kv_m;

--СТАТИСТИЧЕСКИЕ ПОКАЗАТЕЛИ
SELECT 'общая площадь недвижимости' AS metric, MIN(total_area), MAX(total_area), ROUND(AVG(total_area)::NUMERIC, 2) AS avg,
		ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area)::NUMERIC, 2) AS perc_99
FROM real_estate.flats 
UNION ALL 
SELECT 'кол-во комнат' AS metric, MIN(rooms), MAX(rooms), ROUND(AVG(rooms)::NUMERIC, 2) AS avg,
		PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS perc_99
FROM real_estate.flats 
UNION ALL 
SELECT 'кол-во балконов' AS metric, MIN(balcony), MAX(balcony), ROUND(AVG(balcony)::NUMERIC, 2) AS avg,
		PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS perc_99
FROM real_estate.flats 
UNION ALL 
SELECT 'высота потолков' AS metric, MIN(ceiling_height), MAX(ceiling_height), ROUND(AVG(ceiling_height)::NUMERIC, 2) AS avg,
		ROUND(PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height)::NUMERIC, 2) AS perc_99
FROM real_estate.flats 
UNION ALL 
SELECT 'этаж' AS metric, MIN(floor), MAX(floor), ROUND(AVG(floor)::NUMERIC, 2) AS avg, PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY floor) AS perc_99
FROM real_estate.flats;


-------------------------------------------------------------------------------------------------------------------------------------


/* Анализ данных для агентства недвижимости
 * Часть 2. Ad hoc задачи
 * Автор: Сайковская Милена
*/

-- Фильтрация данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        	AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- 1. Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?
-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

-- отфильтруем данные от аномальных значений 
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        	AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
-- выделяем категории объявлений
adv_category AS(
	SELECT id,   
		city_id,
		CASE 
			WHEN city = 'Санкт-Петербург' THEN 'Санкт-Петербург'
			ELSE 'ЛенОбл'
		END AS "Регион",
		CASE 
			WHEN days_exposition <= 30 THEN 'до месяца'
			WHEN days_exposition > 30 AND days_exposition <= 91 THEN 'от месяца до трех'
			WHEN days_exposition > 91 AND days_exposition <= 180 THEN 'до полугода'
			WHEN days_exposition IS NULL THEN 'объявл не закрыто'
			ELSE 'более полугода'
		END AS "Сегмент активности",
		ROUND(last_price::NUMERIC / total_area::NUMERIC, 2) AS price_per_kvm,
		total_area,
		rooms,
		balcony,
		floor,
		ceiling_height,
		is_apartment 
	FROM real_estate.flats LEFT JOIN real_estate.city USING(city_id) LEFT JOIN real_estate.advertisement USING(id)
	WHERE type_id IN (SELECT type_id FROM real_estate.type WHERE type='город')	                                   
		AND id IN (SELECT id FROM filtered_id)                                 --КАК МОЖНО БЕЗ ПОДЗАПРОСА? Я ЖЕ НЕ ДЖОЙНЮ ТАБЛ С types
),
-- СТЕ для будущего подсчета долей в разрезе региона
group_by_region AS (
	SELECT "Регион",
		COUNT(id) AS total_ads
	FROM adv_category
	GROUP BY "Регион"
)  
-- ОСНОВНОЙ ЗАПРОС
SELECT "Регион",
	"Сегмент активности",
	--COUNT(id) AS "Кол-во объявлений",
	--ROUND(100*COUNT(id)::NUMERIC / (SELECT total_ads FROM group_by_region WHERE "Регион"=adv_category."Регион"), 2) AS "% объявлений в разрезе региона",
	--ROUND(100*SUM(is_apartment)::NUMERIC / (SELECT total_ads FROM group_by_region WHERE "Регион"=adv_category."Регион"), 2) AS "% квартир-студий в разрезе региона",                                                                                                     
	--ROUND(AVG(price_per_kvm), 2) AS "Средняя стоимость кв. метра",
	ROUND(AVG(total_area)::NUMERIC, 2) AS "Средняя площадь",
	ROUND(AVG(ceiling_height)::NUMERIC, 2) AS "Средняя высота потолка",
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS "Медиана кол-ва комнат",
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS "Медиана кол-ва балконов",
	PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) AS "Медиана этажности"
FROM adv_category
GROUP BY "Регион", "Сегмент активности"
ORDER BY "Регион" DESC--, "Кол-во объявлений" DESC;

--  Регион  | Сегмент активности | Кол-во объявлений | % объявлений в разрезе региона | % квартир-студий в разрезе региона | Средняя стоимость кв. метра | Средняя площадь | Средняя высота потолка | Медиана кол-ва комнат | Медиана кол-ва балконов | Медиана этажности
------------+--------------------+-------------------+--------------------------------+------------------------------------+-----------------------------+-----------------+------------------------+-----------------------+-------------------------+----------------------    
--  С-Петер | более полугода     |            3581   |               27.99            |                       0.05         |                  115457     |        66.15    |                 2.83   |                  2    |                     1   |             5
--  С-Петер | от месяца до трех  |            3276   |               25.61            |                       0.02         |                  111613     |        56.76    |                 2.77   |                  2    |                     1   |             5
--  С-Петер | до полугода        |            2214   |               17.31            |                       0.03         |                  111887     |        60.54    |                 2.79   |                  2    |                     1   |             5
--  С-Петер | до месяца          |            2168   |               16.95            |                       0.05         |                  110569     |        54.38    |                 2.76   |                  2    |                     1   |             5
--  С-Петер | объявл не закрыто  |            1554   |               12.15            |                       0.08         |                  134632     |        72.03    |                 2.85   |                  2    |                     2   |             5
--   ЛенОбл | от месяца до трех  |             927   |               28.78            |                       0.03         |                   67470     |        50.87    |                 2.71   |                  2    |                     1   |             3
--   ЛенОбл | более полугода     |             890   |               27.63            |                       0.03         |                   68297     |        55.41    |                 2.72   |                  2    |                     1   |             3
--   ЛенОбл | до полугода        |             546   |               16.95            |                       0.03         |                   70064     |        51.87    |                  2.7   |                  2    |                     1   |             3
--   ЛенОбл | объявл не закрыто  |             461   |               14.31            |                       0.06         |                   73626     |        57.87    |                 2.76   |                  2    |                     1   |             3
--   ЛенОбл | до месяца          |             397   |               12.33            |                       0.06         |                   73275     |        48.72    |                  2.7   |                  2    |                     1   |             4




-- 2. Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

-- отфильтруем данные от аномальных значений 
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        	AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),  
-- считаем новые публикации по месяцам
publish AS(
	SELECT EXTRACT(month FROM DATE_TRUNC('month', first_day_exposition)) AS month,
	   COUNT(first_day_exposition) AS publications_total,
	   AVG(total_area) AS avg_total_area_p,
	   AVG(last_price::NUMERIC/total_area) AS avg_total_price_p
	FROM real_estate.advertisement LEFT JOIN real_estate.flats USING(id)
	WHERE id IN (SELECT id FROM filtered_id) AND type_id IN (SELECT type_id FROM real_estate.type WHERE type='город')
	GROUP BY DATE_TRUNC('month', first_day_exposition)
),
-- считаем снятые квартиры по месяцам
remove AS (
	SELECT EXTRACT(month FROM DATE_TRUNC('month', first_day_exposition + days_exposition * INTERVAL '1 day')) AS month,
		COUNT(days_exposition) AS removes_total,
		AVG(total_area) AS avg_total_area_r,
	    AVG(last_price::NUMERIC/total_area) AS avg_total_price_r
	FROM real_estate.advertisement LEFT JOIN real_estate.flats USING(id)
	WHERE days_exposition IS NOT NULL AND id IN (SELECT id FROM filtered_id) AND type_id IN (SELECT type_id FROM real_estate.type WHERE type='город')
	GROUP BY DATE_TRUNC('month', first_day_exposition + days_exposition * INTERVAL '1 day')
)
-- ОСНОВНОЙ ЗАПРОС
SELECT CASE 
			WHEN month='1' THEN 'Январь'
			WHEN month='2' THEN 'Февраль'
			WHEN month='3' THEN 'Март'
			WHEN month='4' THEN 'Апрель'
			WHEN month='5' THEN 'Май'
			WHEN month='6' THEN 'Июнь'
			WHEN month='7' THEN 'Июль'
			WHEN month='8' THEN 'Август'
			WHEN month='9' THEN 'Сентябрь'
			WHEN month='10' THEN 'Октябрь'
			WHEN month='11' THEN 'Ноябрь'
			WHEN month='12' THEN 'Декабрь'
	   END AS "Месяц",
	  DENSE_RANK() OVER(ORDER BY SUM(publications_total) DESC) "Ранг по кол-ву новых публикаций",
	  SUM(publications_total) "Кол-во новых публикаций",
	  DENSE_RANK() OVER(ORDER BY SUM(removes_total) DESC) "Ранг по кол-ву проданых квартир",
	  SUM(removes_total) "Кол-во проданых квартир",
	  ROUND(AVG(avg_total_area_p)::NUMERIC, 1) AS "Средняя площадь открытых объявлений",
	  ROUND(AVG(avg_total_price_p)::NUMERIC) AS "Средняя стоимость кв. метра открытых объявлений",
	  ROUND(AVG(avg_total_area_r)::NUMERIC, 1) AS "Средняя площадь закрытых объявлений",
	  ROUND(AVG(avg_total_price_r)::NUMERIC) AS "Средняя стоимость кв. метра закрытых объявлений"
FROM publish AS p FULL JOIN remove AS r USING(month)   
GROUP BY month
ORDER BY "Ранг по кол-ву новых публикаций", "Ранг по кол-ву проданых квартир"
	   
--  Месяц   |  Ранг по кол-ву новых публикаций  |  Кол-во новых публикаций  |  Ранг по кол-ву проданых квартир  |  Кол-во проданых квартир  |  Средняя площадь открытых объявлений  |  Средняя стоимость кв. метра открытых объявлений  |  Средняя площадь закрытых объявлений  |  Средняя стоимость кв. метра закрытых объявлений
------------+-----------------------------------+---------------------------+-----------------------------------+---------------------------+---------------------------------------+---------------------------------------------------+---------------------------------------+-----------------------------------------------------------
-- Февраль  |                  1                |                  5211     |                   6               |                 5640      |                           60.8        |                                   107590          |                             59.5      |                               104829
-- Март     |                  2                |                  5025     |                   3               |                 6380      |                           59.2        |                                   104571          |                             58.6      |                               105458
-- Апрель   |                  3                |                  4914     |                   1               |                 7100      |                           61.2        |                                   106766          |                             58.3      |                               102989        
-- Ноябрь   |                  4                |                  4767     |                   2               |                 6535      |                           68.2        |                                   111129          |                             58.7      |                               101020                              
-- Октябрь  |                  5                |                  4311     |                   7               |                 5468      |                           61.3        |                                   105215          |                             59.9      |                               102623
-- Сентябрь |                  6                |                  4023     |                   8               |                 4988      |                           57.8        |                                   108063          |                             57.6      |                               103543
-- Июнь     |                  7                |                  3672     |                  12               |                 3128      |                           62.8        |                                   106663          |                             60.1      |                               101075
-- Август   |                  8                |                  3498     |                   9               |                 4580      |                           59.1        |                                   105234          |                             57.2      |                               100127
-- Июль     |                  9                |                  3447     |                  10               |                 4520      |                           63.5        |                                   104255          |                               59      |                               102363
-- Декабрь  |                 10                |                  3336     |                   5               |                 5895      |                           63.1        |                                   110671          |                             60.8      |                               102959
-- Январь   |                 11                |                  3051     |                   4               |                 6340      |                           62.7        |                                   109400          |                             60.9      |                               111375
-- Май      |                 12                |                  2787     |                  11               |                 3750      |                           65.4        |                                   108296          |                             55.7      |                               104840



-- 3. Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдем id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits) 
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits) 
        	AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits))OR ceiling_height IS NULL)
    ),
-- Выведем объявления без выбросов:
t1 AS (
	SELECT *
	FROM real_estate.flats
	WHERE id IN (SELECT * FROM filtered_id)
)
-- ОСНОВНОЙ ЗАПРОС СО ВСЕМИ ПОДСЧЕТАМИ
SELECT city AS "Населенный пункт",
	   COUNT(first_day_exposition) AS "Кол-во публикаций",
	   ROUND(AVG(days_exposition)::NUMERIC) AS "Средняя продолжительность публикации, дни",
	   ROUND(100*COUNT(days_exposition)::NUMERIC / COUNT(first_day_exposition), 2) AS "Доля снятых с публикации, %",
	   ROUND(AVG(last_price ::NUMERIC / total_area)::NUMERIC) AS "Средняя стоимость кв. метра",
	   ROUND(AVG(total_area)::NUMERIC, 1) AS "Средняя площадь"
FROM t1 LEFT JOIN real_estate.city c USING(city_id) LEFT JOIN real_estate.advertisement a USING(id) 
WHERE city != 'Санкт-Петербург' 
GROUP BY t1.city_id, city
ORDER BY "Кол-во публикаций" DESC, "Доля снятых с публикации, %" DESC
LIMIT 15;

-- Населенный пункт  |  Кол-во публикаций  |  Средняя продолжительность публикаций, дни |  Доля снятых с публикации, %  |  Средняя стоимость кв. метра  |  Средняя площадь
---------------------+---------------------+--------------------------------------------+-------------------------------+-------------------------------+-----------------------
--  Мурино           |            568      |                              149           |                  93.6%        |                   85968       |           43.9
--  Кудрово          |            463      |                              161           |                 93.74%        |                   95420       |           46.2
--  Шушары           |            404      |                              152           |                 92.57%        |                   78832       |           53.9
--  Всеволожск       |            356      |                              190           |                 85.67%        |                   69053       |           55.8
...























