WITH Yearly_Data AS (
    SELECT 
        c.city AS city_name,
        YEAR(d.date) AS Year,
        SUM(fpr.net_circulation) AS Net_circulation,
        SUM(far.ad_revenue) AS Ad_Revenue
    FROM fact_print_sales fpr
    JOIN dim_city c ON fpr.City_ID = c.city_id
    JOIN dim_date d ON fpr.Date = d.Date
    JOIN fact_ad_revenue far 
        ON far.city_id = c.city_id 
       AND far.year = YEAR(d.date)
    GROUP BY c.city, YEAR(d.date)
    ORDER BY c.city, YEAR(d.date)
),
Decline_Data AS (
    SELECT 
        city_name,
        Year,
        Net_circulation,
        LAG(Net_circulation) OVER(PARTITION BY city_name ORDER BY Year) AS Prev_Net_circulation,
        Ad_Revenue,
        LAG(Ad_Revenue) OVER(PARTITION BY city_name ORDER BY Year) AS Prev_Ad_Revenue
    FROM Yearly_Data
),
Final_conclusion AS
(
SELECT 
    city_name,
    Year,
    Net_circulation,
    Ad_Revenue,
    CASE 
        WHEN Net_Circulation < Prev_Net_circulation THEN 'Yes' 
        ELSE 'No' 
    END AS is_declining_print,
    CASE 
        WHEN Ad_Revenue < Prev_Ad_Revenue THEN 'Yes' 
        ELSE 'No' 
    END AS is_declining_ad_revenue
FROM Decline_Data
),
final_report AS
(
SELECT upper(city_name) as city_name,
	   Year,
       CONCAT(ROUND(Net_Circulation/1000000,0),"M") AS Yearly_Net_Circulation,
       CONCAT(ROUND(Ad_Revenue/1000000,0),"M") AS Yearly_Ad_Revenue,
       is_declining_print,
       is_declining_ad_revenue,
       CASE
       WHEN is_declining_print = "Yes" AND is_declining_ad_revenue="Yes" THEN "YES"
       ELSE "No"
       END AS is_declining_both
FROM Final_conclusion
)
SELECT * FROM final_report
WHERE is_declining_both="Yes"
order by city_name,year

