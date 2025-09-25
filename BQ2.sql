WITH revenue_data AS
(
    SELECT 
        far.year,
        dac.standard_ad_category,
        SUM(far.ad_revenue) AS ad_revenue
    FROM fact_ad_revenue far
    JOIN dim_ad_category dac
      ON far.ad_category = dac.ad_category_id
    GROUP BY far.year, dac.standard_ad_category
),
yearly_revenue AS
(
    SELECT 
        year,
        standard_ad_category,
        ad_revenue,
        SUM(ad_revenue) OVER(PARTITION BY year) AS total_revenue_year
    FROM revenue_data
)
SELECT 
    year,
    standard_ad_category AS category_name,
    CONCAT(ROUND(ad_revenue/1000000,0),"M") AS category_revenue,
    CONCAT(ROUND(total_revenue_year/1000000,0),"M") AS total_revenue_year,
    CONCAT(ROUND(ad_revenue/total_revenue_year*100,0),"%") AS pct_of_year_total
FROM yearly_revenue
WHERE ad_revenue > 0.5 * total_revenue_year
ORDER BY year, pct_of_year_total DESC;
