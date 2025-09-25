WITH print_data AS
(
SELECT city,
       DATE_FORMAT(Date, '%Y-%m') as month,
       net_circulation
FROM fact_print_sales fpr
JOIN dim_city dc
ON fpr.city_id = dc.city_id
),
last_month_data AS
(
SELECT city,
	   month,
       net_circulation,
	   LAG(net_circulation) OVER (PARTITION BY city ORDER BY month) AS prev_month_circulation
FROM print_data
),
mom_decline AS
(
SELECT city,
	   month,
       net_circulation,
       prev_month_circulation,
       prev_month_circulation-net_circulation AS decline
FROM last_month_data
WHERE prev_month_circulation iS NOT NULL
ORDER BY decline DESC
LIMIT 3
)
SELECT UPPER(city) AS city,
	   month,
       CONCAT(ROUND(net_circulation/1000,0),"K") as net_circulation,
       CONCAT(ROUND(decline/1000,0),"K") AS decline
FROM mom_decline
       




 