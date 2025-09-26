# Bharat Herald – Data Analytics Ad-Hoc Project

## Project Overview
This project analyzes Bharat Herald’s operational and financial data from 2019–2024 to provide insights for improving print performance and guiding digital transformation. The analysis focuses on trends in circulation, ad revenue, digital readiness, and pilot engagement across multiple cities.

## Ad-Hoc Requests & Analysis
The project addresses six business requests:

1. **Monthly Circulation Drop**  
   Identified the top 3 months with the sharpest month-over-month decline in net circulation.  
   **Output fields:** city_name, month (YYYY-MM), net_circulation  
   
```sql
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
           prev_month_circulation - net_circulation AS decline
    FROM last_month_data
    WHERE prev_month_circulation IS NOT NULL
    ORDER BY decline DESC
    LIMIT 3
)
SELECT UPPER(city) AS city,
       month,
       CONCAT(ROUND(net_circulation/1000,0), "K") AS net_circulation,
       CONCAT(ROUND(decline/1000,0), "K") AS decline
FROM mom_decline;
(./ss1.jpg)

   2. **Yearly Revenue by Category**  
   Determined ad categories contributing over 50% of yearly revenue.  
   **Output fields:** year, category_name, category_revenue, total_revenue_year, pct_of_year_total  

3. **2024 Print Efficiency**  
   Ranked cities by print efficiency (net_circulation / copies_printed).  
   **Output fields:** city_name, copies_printed_2024, net_circulation_2024, efficiency_ratio, efficiency_rank_2024  

4. **Internet Readiness Growth (2021)**  
   Computed change in internet penetration from Q1 to Q4 2021.  
   **Output fields:** city_name, internet_rate_q1_2021, internet_rate_q4_2021, delta_internet_rate  

5. **Multi-Year Decline (2019–2024)**  
   Identified cities with declining circulation and ad revenue over six years.  
   **Output fields:** city_name, year, yearly_net_circulation, yearly_ad_revenue, is_declining_print, is_declining_ad_revenue, is_declining_both  

6. **2021 Readiness vs Pilot Engagement Outlier**  
   Highlighted cities with high digital readiness but low pilot engagement.  
   **Output fields:** city_name, readiness_score_2021, engagement_metric_2021, readiness_rank_desc, engagement_rank_asc, is_outlier  

## Deliverables
- SQL queries for all six business requests (saved in a single `.sql` file).  
- Screenshots of query results for verification.  
- Insights derived from each analysis to support strategic decision-making.
