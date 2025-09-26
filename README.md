# Bharat Herald – Data Analytics Ad-Hoc Project

## Project Overview
This project analyzes Bharat Herald’s operational and financial data from 2019–2024 to provide insights for improving print performance and guiding digital transformation. The analysis focuses on trends in circulation, ad revenue, digital readiness, and pilot engagement across multiple cities.

## Ad-Hoc Requests & Analysis
The project addresses six business requests:

1. **Monthly Circulation Drop**  
   Identified the top 3 months with the sharpest month-over-month decline in net circulation.  
   **Output fields:** city_name, month (YYYY-MM), net_circulation  
**Query**
<pre>
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
</pre>
**Report**
| City     | Month    | Net Circulation | Decline |
|----------|---------|----------------|---------|
| VARANASI | 2021-01 | 382K           | 60K     |
| VARANASI | 2019-11 | 432K           | 56K     |
| JAIPUR   | 2020-01 | 421K           | 52K     |


2. **Yearly Revenue by Category**  
   Determined ad categories contributing over 50% of yearly revenue.  
   **Output fields:** year, category_name, category_revenue, total_revenue_year, pct_of_year_total  
**Query**
<pre>
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
</pre>
**Report**
| year | category_name | category_revenue | total_revenue_year | pct_of_year_total |
|------|---------------|-----------------|------------------|-----------------|


3. **2024 Print Efficiency**  
   Ranked cities by print efficiency (net_circulation / copies_printed).  
   **Output fields:** city_name, copies_printed_2024, net_circulation_2024, efficiency_ratio, efficiency_rank_2024  
   **Query**
   <pre>
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
    CONCAT(ROUND(copies_printed_2024/1000000, 2), "M") AS copies_printed_2024,
    CONCAT(ROUND(net_circulation_2024/1000000, 2), "M") AS net_circulation_2024,
    efficiency_ratio,
    efficiency_rank_2024
FROM ranked_efficiency
WHERE efficiency_rank_2024 <= 5
ORDER BY efficiency_rank_2024;
   </pre>
**Report**
| city_name  | copies_printed_2024 | net_circulation_2024 | efficiency_ratio | efficiency_rank_2024 |
|------------|-------------------|--------------------|----------------|-------------------|
| RANCHI     | 2.31M             | 2.09M              | 0.9059         | 1                 |
| AHMEDABAD  | 3.05M             | 2.75M              | 0.9015         | 2                 |
| PATNA      | 2.51M             | 2.25M              | 0.8988         | 3                 |
| JAIPUR     | 4.59M             | 4.13M              | 0.8987         | 4                 |
| VARANASI   | 4.59M             | 4.12M              | 0.8981         | 5                 |


4. **Internet Readiness Growth (2021)**  
   Computed change in internet penetration from Q1 to Q4 2021.  
   **Output fields:** city_name, internet_rate_q1_2021, internet_rate_q4_2021, delta_internet_rate  
   **Query**
   <pre>
	   SELECT 
    UPPER(city) AS city,
    MAX(CASE WHEN quarter = '2021-Q1' THEN internet_penetration END) AS internet_rate_q1_2021,
    MAX(CASE WHEN quarter = '2021-Q4' THEN internet_penetration END) AS internet_rate_q4_2021,
    ROUND(
        (MAX(CASE WHEN quarter = '2021-Q4' THEN internet_penetration END) - 
         MAX(CASE WHEN quarter = '2021-Q1' THEN internet_penetration END)), 2
    ) AS delta_internet_rate
FROM fact_city_readiness fcr
JOIN dim_city c
    ON fcr.city_id = c.city_id
WHERE quarter IN ('2021-Q1', '2021-Q4')
GROUP BY city
ORDER BY delta_internet_rate DESC;
   </pre>
**Report**
| city       | internet_rate_q1_2021 | internet_rate_q4_2021 | delta_internet_rate |
|------------|----------------------|----------------------|-------------------|
| KANPUR     | 74.27                | 76.77                | 2.5               |
| MUMBAI     | 73.31                | 75.74                | 2.43              |
| AHMEDABAD  | 73.03                | 74.8                 | 1.77              |
| DELHI      | 48.68                | 50.41                | 1.73              |
| PATNA      | 67.73                | 68.56                | 0.83              |
| LUCKNOW    | 55                   | 55.71                | 0.71              |
| JAIPUR     | 10                   | 10                   | 0                 |
| VARANASI   | 73.51                | 73.45                | -0.06             |
| BHOPAL     | 68.21                | 66.48                | -1.73             |
| RANCHI     | 63.49                | 60.36                | -3.13             |


5. **Multi-Year Decline (2019–2024)**  
   Identified cities with declining circulation and ad revenue over six years.  
   **Output fields:** city_name, year, yearly_net_circulation, yearly_ad_revenue, is_declining_print, is_declining_ad_revenue, is_declining_both 
   **Query**
   <pre>
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
Final_conclusion AS (
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
final_report AS (
    SELECT 
        UPPER(city_name) AS city_name,
        Year,
        CONCAT(ROUND(Net_Circulation/1000000, 0), "M") AS Yearly_Net_Circulation,
        CONCAT(ROUND(Ad_Revenue/1000000, 0), "M") AS Yearly_Ad_Revenue,
        is_declining_print,
        is_declining_ad_revenue,
        CASE
            WHEN is_declining_print = 'Yes' AND is_declining_ad_revenue = 'Yes' THEN 'YES'
            ELSE 'No'
        END AS is_declining_both
    FROM Final_conclusion
)
SELECT * 
FROM final_report
WHERE is_declining_both = 'Yes'
ORDER BY city_name, Year;
   </pre>
**Report**
| city_name  | Year | Yearly_Net_Circulation | Yearly_Ad_Revenue | is_declining_print | is_declining_ad_revenue | is_declining_both |
|------------|------|-----------------------|-----------------|------------------|------------------------|-----------------|
| AHMEDABAD  | 2021 | 40M                   | 389M            | Yes              | Yes                    | YES             |
| AHMEDABAD  | 2023 | 35M                   | 376M            | Yes              | Yes                    | YES             |
| BHOPAL     | 2020 | 37M                   | 396M            | Yes              | Yes                    | YES             |
| BHOPAL     | 2023 | 31M                   | 473M            | Yes              | Yes                    | YES             |
| BHOPAL     | 2024 | 29M                   | 446M            | Yes              | Yes                    | YES             |
| DELHI      | 2023 | 41M                   | 457M            | Yes              | Yes                    | YES             |
| DELHI      | 2024 | 39M                   | 314M            | Yes              | Yes                    | YES             |
| JAIPUR     | 2020 | 63M                   | 432M            | Yes              | Yes                    | YES             |
| JAIPUR     | 2022 | 57M                   | 359M            | Yes              | Yes                    | YES             |
| KANPUR     | 2020 | 50M                   | 327M            | Yes              | Yes                    | YES             |
| KANPUR     | 2024 | 39M                   | 377M            | Yes              | Yes                    | YES             |
| LUCKNOW    | 2020 | 27M                   | 394M            | Yes              | Yes                    | YES             |
| LUCKNOW    | 2022 | 24M                   | 391M            | Yes              | Yes                    | YES             |
| MUMBAI     | 2021 | 51M                   | 418M            | Yes              | Yes                    | YES             |
| MUMBAI     | 2022 | 48M                   | 383M            | Yes              | Yes                    | YES             |
| MUMBAI     | 2024 | 43M                   | 416M            | Yes              | Yes                    | YES             |
| PATNA      | 2020 | 34M                   | 377M            | Yes              | Yes                    | YES             |
| PATNA      | 2022 | 30M                   | 405M            | Yes              | Yes                    | YES             |
| RANCHI     | 2020 | 32M                   | 431M            | Yes              | Yes                    | YES             |
| RANCHI     | 2021 | 31M                   | 381M            | Yes              | Yes                    | YES             |
| RANCHI     | 2023 | 27M                   | 339M            | Yes              | Yes                    | YES             |
| VARANASI   | 2021 | 58M                   | 445M            | Yes              | Yes                    | YES             |
| VARANASI   | 2022 | 56M                   | 322M            | Yes              | Yes                    | YES             |
| VARANASI   | 2024 | 49M                   | 387M            | Yes              | Yes                    | YES             |


6. **2021 Readiness vs Pilot Engagement Outlier**  
   Highlighted cities with high digital readiness but low pilot engagement.  
   **Output fields:** city_name, readiness_score_2021, engagement_metric_2021, readiness_rank_desc, engagement_rank_asc, is_outlier  
   **Query**
   <pre>
	   WITH digital_pilot AS (
    SELECT 
        dc.city,
        SUM(fdp.downloads_or_accesses * (1 - fdp.avg_bounce_rate/100.0)) AS active_users
    FROM fact_digital_pilot fdp
    JOIN dim_city dc
        ON fdp.city_id = dc.city_id
    GROUP BY dc.city
),
engagement_ranked AS (
    SELECT 
        city,
        ROUND(active_users/1000, 0) AS active_users_k,
        CONCAT(ROUND(active_users/1000, 0), 'K') AS engagement_metric_2021,
        RANK() OVER (ORDER BY active_users ASC) AS engagement_rank_asc
    FROM digital_pilot
),
readiness AS (
    SELECT 
        dc.city,
        ROUND(AVG(literacy_rate + smartphone_penetration + internet_penetration)/3, 0) AS readiness_score_2021,
        RANK() OVER (ORDER BY ROUND(AVG(literacy_rate + smartphone_penetration + internet_penetration)/3, 0) DESC) AS readiness_rank_desc
    FROM fact_city_readiness fcr
    JOIN dim_city dc 
        ON fcr.city_id = dc.city_id
    WHERE LEFT(quarter, 4) = '2021'
    GROUP BY dc.city
)
SELECT 
    UPPER(r.city) AS city_name,
    r.readiness_score_2021,
    e.engagement_metric_2021,
    r.readiness_rank_desc,
    e.engagement_rank_asc,
    CASE 
        WHEN r.readiness_rank_desc = 1 AND e.engagement_rank_asc <= 3 THEN 'Yes'
        ELSE 'No'
    END AS is_outlier
FROM readiness r
JOIN engagement_ranked e
    ON r.city = e.city
ORDER BY e.engagement_rank_asc;
   </pre>
**Report**
| city_name  | readiness_score_2021 | engagement_metric_2021 | readiness_rank_desc | engagement_rank_asc | is_outlier |
|------------|--------------------|-----------------------|-------------------|-------------------|-----------|
| KANPUR     | 75                 | 9K                    | 1                 | 1                 | Yes       |
| RANCHI     | 69                 | 10K                   | 7                 | 2                 | No        |
| JAIPUR     | 55                 | 19K                   | 10                | 3                 | No        |
| VARANASI   | 74                 | 22K                   | 2                 | 4                 | No        |
| PATNA      | 71                 | 22K                   | 6                 | 5                 | No        |
| MUMBAI     | 68                 | 26K                   | 8                 | 6                 | No        |
| LUCKNOW    | 73                 | 29K                   | 3                 | 7                 | No        |
| DELHI      | 56                 | 31K                   | 9                 | 8                 | No        |
| BHOPAL     | 73                 | 33K                   | 3                 | 9                 | No        |
| AHMEDABAD  | 72                 | 36K                   | 5                 | 10                | No        |


