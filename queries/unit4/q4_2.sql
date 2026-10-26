--Part A: total ratings and withdrawn (failure) ratings per movie in one pass.
--No WHERE clause: CASE inside the aggregate does the classifying.

SELECT m.movie_id,
       m.title,
       COUNT(*)                                                       AS total_ratings,
       SUM(CASE WHEN r.rating_status = 'withdrawn' THEN 1 ELSE 0 END) AS withdrawn_ratings
FROM ratings r
JOIN movies m ON m.movie_id = r.movie_id
GROUP BY m.movie_id, m.title
ORDER BY withdrawn_ratings DESC, total_ratings DESC;

--Part B: regional subtotals plus a platform grand total, no detail rows.

SELECT CASE WHEN GROUPING(r.device_country) = 1 THEN 'ALL REGIONS'
            ELSE r.device_country END                          AS region,
       COUNT(*)                                                AS total_ratings,
       SUM(CASE WHEN r.rating_status = 'withdrawn' THEN 1 ELSE 0 END) AS withdrawn_ratings,
       ROUND(AVG(r.score), 2)                                  AS avg_score
FROM ratings r
GROUP BY GROUPING SETS ((r.device_country), ())
ORDER BY GROUPING(r.device_country), r.device_country;

--Rows 1–5 are the regional subtotals, one per region, from the (r.device_country) grouping set.
--    For these, GROUPING(r.device_country) = 0.
--The last row, "ALL REGIONS", is the platform grand total, from the empty grouping set ().
--Here GROUPING(r.device_country) = 1, so the CASE labels it instead of leaving the region NULL.
-- Its numbers match the whole table: 200 ratings, 34 withdrawn, average 2.85.
--The ROLLUP equivalent: GROUP BY ROLLUP (r.device_country) gives exactly the same six rows.
-- ROLLUP over one column produces the per-region groups plus a grand total.
-- I used GROUPING SETS because it states exactly which groupings to produce.
-- If you add a second column later, such as movie,
-- GROUPING SETS ((r.device_country), ()) still leaves out the detail rows,
-- whereas ROLLUP (r.device_country, m.title) would add them back.


--Part C: baseline for high-volume producers (movies with 10+ ratings).

WITH movie_summary AS (                                   -- Step 1: one row per movie
    SELECT r.movie_id,
           COUNT(*)                                                       AS total_ratings,
           SUM(CASE WHEN r.rating_status = 'withdrawn' THEN 1 ELSE 0 END) AS withdrawn_ratings,
           100.0 * SUM(CASE WHEN r.rating_status = 'withdrawn' THEN 1 ELSE 0 END)
                 / COUNT(*)                                               AS withdrawn_pct,
           AVG(r.score)                                                   AS avg_score
    FROM ratings r
    GROUP BY r.movie_id
)
SELECT COUNT(*)                     AS high_volume_movies,      -- Step 2: aggregate the summary
       SUM(total_ratings)           AS ratings_covered,
       ROUND(AVG(withdrawn_pct), 1) AS baseline_withdrawn_pct,
       ROUND(AVG(avg_score), 2)     AS baseline_avg_score
FROM movie_summary
WHERE total_ratings >= 10;
