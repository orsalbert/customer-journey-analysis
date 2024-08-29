with landing_page_data as (
select user
	,min(event_date) as first_event_date
--	,max(event_date) as last_event_date
	,first_value(page_type) over (partition by user order by event_date asc) landing_page
from tab t 
group by USER)
SELECT
	CASE WHEN event_type = 'page_view'
			AND page_type in ('search_listing_page', 'listing_page') THEN 'Browse'
		WHEN event_type = 'page_view'
			AND page_type = 'product_page' THEN 'Product View'
		WHEN event_type = 'add_to_cart' THEN 'Add To Cart'
		WHEN event_type = 'order' THEN 'Order'
		ELSE 'Website Visit'
	END funnel_steps
	,landing_page
--	,CAST((julianday(last_event_date) - julianday(first_event_date)) * 24 * 60 As Integer) total_time
	,count(t.user) user_activity
from tab t
LEFT JOIN landing_page_data lp
	ON t.USER = lp.USER
GROUP BY landing_page, funnel_steps
ORDER BY user_activity desc;