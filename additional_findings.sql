/* number of users by day that:
- that only viewed products in their first session
- that added only one product to the basket
- that placed an order within two days of their first session */

WITH first_session as (
	SELECT 
		USER
		,min(event_date) min_dt
	FROM tab t 
	GROUP BY USER
	),
first_session_rows AS (
	SELECT 
		t.user
		,t.session
		,t.page_type
		,t.event_type
		,t.product
	FROM tab t 
	JOIN first_session fs
	ON	t.USER = fs.USER AND t.event_date = fs.min_dt
	),
prod_data AS (
	SELECT 
		user
		,product
	FROM tab t 
	WHERE product != 0
	)
SELECT
	first_session_prod_page_visit.dt
	,first_session_prod_page_visit.first_session_prod_page_user_count
	,one_product.one_product_user_count
	,within_two_days.order_within_two_days_user_count
FROM
	(SELECT 
		SUBSTRING(event_date,1,10) dt
		,count(DISTINCT(user)) first_session_prod_page_user_count
	FROM tab
	WHERE USER IN (SELECT user
		FROM first_session_rows
		WHERE page_type = 'product_page')
	GROUP BY dt) first_session_prod_page_visit
JOIN 
	(SELECT 
		SUBSTRING(event_date,1,10) dt
		,count(DISTINCT(user)) one_product_user_count
	FROM tab
	WHERE USER IN (SELECT USER
		FROM prod_data
		GROUP BY user
		HAVING	count(*) = 1)
	GROUP BY dt) one_product
ON first_session_prod_page_visit.dt = one_product.dt
JOIN
	(SELECT 
		SUBSTRING(event_date,1,10) dt
		,count(DISTINCT(user)) order_within_two_days_user_count
	FROM tab 
	WHERE USER IN (SELECT t.USER
		FROM tab t 
		JOIN first_session fs
		ON t.USER = fs.USER
		WHERE event_type = 'order'
			AND t.event_date <= date(fs.min_dt, '+2 day'))
	GROUP BY dt) within_two_days
ON first_session_prod_page_visit.dt = within_two_days.dt 
ORDER BY first_session_prod_page_visit.dt;


/* unusual user activity: too many orders at once */

SELECT
    user,
    COUNT(*) AS order_count,
    MIN(event_date) AS first_order_date,
    MAX(event_date) AS last_order_date
FROM
    tab t 
WHERE
    event_type = 'order'
GROUP BY
    user
HAVING
    order_count > 10
    AND CAST((julianday(MAX(event_date)) - julianday(MIN(event_date))) * 24 * 60 As Integer) <= 3600;