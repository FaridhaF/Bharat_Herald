WITH digital_pilot AS
(
    SELECT dc.city,
           SUM(fdp.downloads_or_accesses * (1 - fdp.avg_bounce_rate/100.0)) AS active_users
    FROM fact_digital_pilot fdp
    JOIN dim_city dc
      ON fdp.city_id = dc.city_id
    GROUP BY dc.city
),
engagement_ranked AS
(
    SELECT city,
           ROUND(active_users/1000,0) AS active_users_k,
           CONCAT(ROUND(active_users/1000,0), 'K') AS engagement_metric_2021,
           RANK() OVER (ORDER BY active_users ASC) AS engagement_rank_asc
    FROM digital_pilot
),
readiness AS
(
    SELECT dc.city,
           ROUND(AVG(literacy_rate + smartphone_penetration + internet_penetration)/3, 0) AS readiness_score_2021,
           RANK() OVER (ORDER BY ROUND(AVG(literacy_rate + smartphone_penetration + internet_penetration)/3, 0) DESC) AS readiness_rank_desc
    FROM fact_city_readiness fcr
    JOIN dim_city dc 
      ON fcr.city_id = dc.city_id
    WHERE LEFT(quarter, 4) = "2021"
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
