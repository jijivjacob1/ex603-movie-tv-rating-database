-- Task 6.2: Compare each row to its neighbors.

-- Requirement 6.2 Part A: Row to row
-- Question: For Movie 11 (the movie with the highest withdrawal rate in
-- Unit 4), are scores going up or down from one rating to the next?
-- Partitioned by movie so each rating is compared only with the same
-- movie's previous and next rating; rating_id breaks ties on rated_at.
WITH neighbours AS (
    SELECT r.movie_id,
           r.rating_id,
           r.rated_at,
           r.rating_status,
           r.score,
           LAG(r.score)  OVER (PARTITION BY r.movie_id ORDER BY r.rated_at, r.rating_id) AS prev_score,
           LEAD(r.score) OVER (PARTITION BY r.movie_id ORDER BY r.rated_at, r.rating_id) AS next_score,
           r.score - LAG(r.score) OVER (PARTITION BY r.movie_id ORDER BY r.rated_at, r.rating_id) AS delta
    FROM ratings r
)
SELECT movie_id, rating_id, rated_at, rating_status, prev_score, score, next_score, delta
FROM neighbours
WHERE movie_id = 11
ORDER BY rated_at, rating_id;
-- The filter is in the outer query so LAG/LEAD are computed over the whole
-- movie history first. Withdrawn ratings show 0.5, so a large negative delta
-- next to a withdrawn row is the placeholder, not a real drop in opinion.

-- Requirement 6.2 Part B: Cumulative and smoothed
-- Question: How is the platform doing over 2023, in total and on a recent
-- average? Target: 240 ratings for the year (20 per month).
-- Step 1 builds one row per calendar day (generate_series) so that days with
-- no ratings count as 0 instead of disappearing.
WITH days AS (
    SELECT generate_series(DATE '2023-01-01', DATE '2023-12-31', INTERVAL '1 day')::date AS rating_day
),
daily AS (
    SELECT d.rating_day,
           COUNT(r.rating_id)                                        AS daily_ratings,
           COUNT(r.rating_id) FILTER (WHERE r.rating_status = 'withdrawn') AS daily_withdrawn
    FROM days d
         LEFT JOIN ratings r ON r.rated_at::date = d.rating_day
    GROUP BY d.rating_day
)
SELECT rating_day,
       daily_ratings,
       daily_withdrawn,
       SUM(daily_ratings) OVER (ORDER BY rating_day
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_ratings,
       SUM(daily_withdrawn) OVER (ORDER BY rating_day
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_withdrawn,
       ROUND(100.0 * SUM(daily_ratings) OVER (ORDER BY rating_day
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / 240, 1) AS pct_of_240_target,
       ROUND(AVG(daily_ratings) OVER (ORDER BY rating_day
                                ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS ratings_per_day_30d_avg,
       ROUND(100.0 * SUM(daily_withdrawn) OVER (ORDER BY rating_day ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
             / NULLIF(SUM(daily_ratings) OVER (ORDER BY rating_day ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 0), 1)
                                                                    AS withdrawn_pct_30d
FROM daily
ORDER BY rating_day;
-- Because every day has a row, the 30-row window is exactly 30 days.
-- ROWS vs RANGE: with ROWS, two rows with the same ORDER BY value get
-- different running totals (one row at a time); with RANGE (the default),
-- tied rows are peers and all get the total through the last of them.

-- Requirement 6.2 Part C: Where the series stops
-- Question: Which movies go quiet for a long stretch and then receive
-- ratings again, and how long is each gap?
WITH gaps AS (
    SELECT movie_id,
           LAG(rated_at) OVER (PARTITION BY movie_id ORDER BY rated_at, rating_id) AS prev_rated_at,
           rated_at,
           rated_at - LAG(rated_at) OVER (PARTITION BY movie_id ORDER BY rated_at, rating_id) AS gap
    FROM ratings
)
SELECT g.movie_id,
       m.title,
       g.prev_rated_at AS last_rating_before_gap,
       g.rated_at      AS first_rating_after_gap,
       g.gap
FROM gaps g
     JOIN movies m USING (movie_id)
WHERE g.gap > INTERVAL '60 days'
ORDER BY g.gap DESC;
-- 60 days is about four times the typical spacing between ratings of a
-- single movie (200 ratings / 13 movies over one year).
