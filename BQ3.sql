WITH city_efficiency AS (
    SELECT 
        c.city AS city_name,
        SUM(fps.copies_sold + fps.copies_returned) AS copies_printed_2024,
        SUM(fps.net_circulation) AS net_circulation_2024,
        ROUND(SUM(fps.net_circulation) / SUM(fps.copies_sold + fps.copies_returned), 4) AS efficiency_ratio
    FROM fact_print_sales fps
    JOIN dim_city c
        ON fps.City_ID = c.city_id
    WHERE YEAR(fps.Date) = 2024
    GROUP BY c.city
),
ranked_efficiency AS (
    SELECT 
        city_name,
        copies_printed_2024,
        net_circulation_2024,
        efficiency_ratio,
        RANK() OVER (ORDER BY efficiency_ratio DESC) AS efficiency_rank_2024
    FROM city_efficiency
)
SELECT 
    UPPER(city_name) AS city_name,
    CONCAT(ROUND(copies_printed_2024/1000000,2),"M") AS copies_printed_2024,
    CONCAT(ROUND(net_circulation_2024/1000000,2),"M") AS net_circulation_2024,
    efficiency_ratio,
    efficiency_rank_2024
FROM ranked_efficiency
WHERE efficiency_rank_2024 <= 5
ORDER BY efficiency_rank_2024;
