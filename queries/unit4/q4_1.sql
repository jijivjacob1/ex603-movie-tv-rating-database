--Calculate the following statistics across the entire event table
--using your theme's metric: the count, total,
--average, minimum,
--and maximum of your theme’s metric across the whole event table,
--and how many distinct actors appear.
--Review your results carefully. For example, if your metric should never
--be zero but your minimum value is zero,
--this may indicate another data-quality issue that needs investigation.

-- 1. Summary statistics for the theme metric (score) across the whole event table
SELECT COUNT(score)            AS rating_count,
       SUM(score)              AS total_score,
       ROUND(AVG(score), 2)    AS avg_score,
       MIN(score)              AS min_score,
       MAX(score)              AS max_score,
       COUNT(DISTINCT user_id) AS distinct_users
FROM ratings;

-- 2. Check for missing or zero scores
SELECT COUNT(*)                          AS total_rows,
       COUNT(score)                      AS non_null_scores,
       COUNT(CASE WHEN score is null THEN 1 END) AS zero_scores
FROM ratings;

--All 34 withdrawn ratings have a score of exactly 0.5,
-- which looks like a placeholder rather than a real rating.
-- Those rows pull the average down.
-- Without them the average is 3.33 instead of 2.85, and the minimum is 0.8.

-- 3. Score range by status (shows withdrawn ratings are all 0.5)
SELECT rating_status,
       COUNT(*)   AS ratings,
       MIN(score) AS min_score,
       MAX(score) AS max_score
FROM ratings
GROUP BY rating_status
ORDER BY rating_status;

-- 4. Same statistics, excluding withdrawn ratings
SELECT COUNT(score)            AS rating_count,
       SUM(score)              AS total_score,
       ROUND(AVG(score), 2)    AS avg_score,
       MIN(score)              AS min_score,
       MAX(score)              AS max_score,
       COUNT(DISTINCT user_id) AS distinct_users
FROM ratings
WHERE rating_status <> 'withdrawn';




--Write a query that calculates the event count and average metric for
-- each producer. Sort the results from the producer with the most
-- events to the producer with the fewest.
-- Consider what these results tell you about differences in
-- activity and performance across producers.

SELECT m.movie_id,
       m.title,
       COUNT(r.rating_id)     AS rating_count,
       ROUND(AVG(r.score), 2) AS avg_score
FROM movies m
LEFT JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY rating_count DESC, m.title;

--I used a LEFT JOIN so movies with no ratings still appear,
-- with a count of 0. Notice COUNT(r.rating_id) rather than COUNT(*):
-- COUNT(*) would count the empty joined row and show 1 for those movies.



--What it tells you:

--Activity varies a lot. Counts range from 21 down to 6, and two movies
-- (Title_14, Title_15) have no ratings at all.
-- More ratings doesn't mean better ratings.
--The most-rated movie (Title_06, 21 ratings) has a below-average score of
-- 2.78. Title_05 has the highest average (3.51) with fewer ratings.
--Small samples are less reliable.
-- Title_04's average comes from only 6 ratings,
-- so one rating can move it a lot.
--Withdrawn ratings distort the averages.
-- The 0.5 placeholder scores pull averages down unevenly.
-- Title_11 has 5 withdrawn ratings, and its average rises from 2.09 to 2.82
-- without them.

--. Same, excluding withdrawn ratings
SELECT m.movie_id,
       m.title,
       COUNT(r.rating_id)     AS rating_count,
       ROUND(AVG(r.score), 2) AS avg_score
FROM movies m
LEFT JOIN ratings r ON r.movie_id = m.movie_id
                   AND r.rating_status <> 'withdrawn'
GROUP BY m.movie_id, m.title
ORDER BY rating_count DESC, m.title;

--Which producers have enough volume for their rate to mean anything?
-- A producer with only a few events may have a high failure rate
-- that is not representative of their usual performance.
-- Choose a minimum event-count threshold and use HAVING to
-- include only producers who meet that threshold.
-- Explain why you selected your threshold.



--Withdrawn (failure) rate per movie, only for movies with at least 10 ratings.

SELECT m.movie_id,
       m.title,
       COUNT(*)   AS rating_count,
       SUM(CASE WHEN r.rating_status = 'withdrawn' THEN 1 ELSE 0 END)
           AS withdrawn_count,
       ROUND(100.0 * SUM(CASE WHEN r.rating_status = 'withdrawn'
           THEN 1 ELSE 0 END)  / COUNT(*), 1)   AS withdrawn_pct

FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
HAVING COUNT(*) >= 10
ORDER BY withdrawn_pct DESC, rating_count DESC;

--Why I chose 10:

--Threshold = 10 ratings: at 10, one withdrawal moves the rate by 10 points.
--Below that the rate is mostly noise (Title_04 shows 33% from just 2 of 6).
--Most movies have 11-21 ratings, so 10 keeps 12 of 15 movies.

--How does the picture change along two dimensions at once?
-- Leadership also wants to understand how performance varies across regions.
-- Write a query that groups the data by two dimensions, including region,
-- and calculates the relevant summary statistics.
-- Your results should contain one row for each combination of the
-- two dimensions so that regional leaders can review their results.
SELECT r.device_country AS region,
       CASE WHEN m.release_year >= 2015 THEN '2015 or later'
            ELSE 'Before 2015' END AS release_era,
       COUNT(*)               AS rating_count,
       ROUND(AVG(r.score), 2) AS avg_score,
       ROUND(100.0 * SUM(CASE WHEN r.rating_status = 'withdrawn' THEN 1 ELSE 0 END)
             / COUNT(*), 1)   AS withdrawn_pct
FROM ratings r
JOIN movies m ON m.movie_id = r.movie_id
GROUP BY r.device_country,
         CASE WHEN m.release_year >= 2015 THEN '2015 or later' ELSE 'Before 2015' END
ORDER BY region, release_era;

--Here the second dimension shows something the region totals hide:
-- India's newer movies have a 36% withdrawn rate, almost three times
-- its rate for older movies. The UK is the only region where newer
-- movies score higher than older ones.

