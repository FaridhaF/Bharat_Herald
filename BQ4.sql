SELECT 
    UPPER(city) AS city,
    MAX(CASE WHEN quarter = '2021-Q1' THEN internet_penetration END) AS internet_rate_q1_2021,
    MAX(CASE WHEN quarter = '2021-Q4' THEN internet_penetration END) AS internet_rate_q4_2021,
    ROUND((MAX(CASE WHEN quarter = '2021-Q4' THEN internet_penetration END) - 
     MAX(CASE WHEN quarter = '2021-Q1' THEN internet_penetration END)),2) AS delta_internet_rate
FROM fact_city_readiness fcr
JOIN dim_city c
ON fcr.city_id=c.city_id
WHERE quarter IN ('2021-Q1', '2021-Q4')
GROUP BY city
ORDER BY delta_internet_rate DESC
