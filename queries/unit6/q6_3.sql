-- Task 6.3: Build the reporting patterns.

-- Requirement 6.3 Part A: Top N per category
-- Question: What are the three highest-scoring ratings for each movie, and
-- how far is each one from that movie's best rating?
-- Only published ratings count: withdrawn ratings carry a 0.5 placeholder
-- and flagged ratings are still under review.
-- Ties at third place: ROW_NUMBER with rated_at, rating_id as tiebreakers,
-- so every movie shows exactly three ratings and, on equal scores, the
-- earliest rating wins. A "top 3" panel has three fixed slots, and the
-- result must be the same every time it runs. This matters in our data:
-- Movies 5, 7, 8 and 10 each have 4-6 published 5.0 ratings, and Movie 12
-- ties at 4.5, so RANK would return 4-6 rows for them. (RANK would show four or more
-- rows when scores tie at third.)
WITH ranked AS (
    SELECT r.movie_id,
           m.title,
           r.rating_id,
           r.user_id,
           r.rated_at,
           r.score,
           ROW_NUMBER()       OVER w AS rn,
           RANK()             OVER w AS rnk,
           FIRST_VALUE(r.score) OVER w AS best_score_for_movie
    FROM ratings r
         JOIN movies m USING (movie_id)
    WHERE r.rating_status = 'published'
    WINDOW w AS (PARTITION BY r.movie_id ORDER BY r.score DESC, r.rated_at, r.rating_id)
)
SELECT movie_id, title, rn, rnk, rating_id, user_id, rated_at, score,
       best_score_for_movie,
       best_score_for_movie - score AS below_best
FROM ranked
WHERE rn <= 3
ORDER BY movie_id, rn;
-- rnk is shown alongside rn so ties are visible: where rnk repeats, the
-- scores are equal and the tiebreaker decided the order.

-- Requirement 6.3 Part B: Period over period
-- Question: Is the platform getting better or worse each month? Compare each
-- month's rating volume, withdrawal rate and average published score with
-- the month before.
WITH monthly AS (
    SELECT DATE_TRUNC('month', rated_at)::date                         AS month,
           COUNT(*)                                                    AS ratings,
           COUNT(*) FILTER (WHERE rating_status = 'withdrawn')         AS withdrawn,
           ROUND(100.0 * COUNT(*) FILTER (WHERE rating_status = 'withdrawn') / COUNT(*), 1) AS withdrawn_pct,
           ROUND(AVG(score) FILTER (WHERE rating_status = 'published'), 2) AS avg_published_score
    FROM ratings
    GROUP BY DATE_TRUNC('month', rated_at)
)
SELECT month,
       LAG(month) OVER (ORDER BY month)                                AS prev_month,
       ratings,
       LAG(ratings) OVER (ORDER BY month)                              AS prev_ratings,
       ROUND(100.0 * (ratings - LAG(ratings) OVER (ORDER BY month))
             / NULLIF(LAG(ratings) OVER (ORDER BY month), 0), 1)       AS ratings_pct_change,
       withdrawn,
       withdrawn_pct,
       withdrawn_pct - LAG(withdrawn_pct) OVER (ORDER BY month)        AS withdrawn_pct_point_change,
       avg_published_score,
       ROUND(100.0 * (avg_published_score - LAG(avg_published_score) OVER (ORDER BY month))
             / NULLIF(LAG(avg_published_score) OVER (ORDER BY month), 0), 1) AS score_pct_change,
       CASE
           WHEN LAG(month) OVER (ORDER BY month) IS NULL THEN 'first month'
           WHEN LAG(month) OVER (ORDER BY month) = month - INTERVAL '1 month' THEN 'ok'
           ELSE 'MISSING MONTH BEFORE THIS ROW'
       END                                                             AS month_check
FROM monthly
ORDER BY month;
-- withdrawn_pct is already a percentage, so its change is reported in
-- percentage points rather than as a percent of a percent.

-- Requirement 6.3 Part B: Missing-month check
-- Question: Does every calendar month in the data range have at least one
-- rating? If not, LAG above would compare non-adjacent months.
WITH months AS (
    SELECT generate_series(DATE_TRUNC('month', MIN(rated_at)),
                           DATE_TRUNC('month', MAX(rated_at)),
                           INTERVAL '1 month')::date AS month
    FROM ratings
)
SELECT m.month,
       COUNT(r.rating_id) AS ratings
FROM months m
     LEFT JOIN ratings r ON DATE_TRUNC('month', r.rated_at) = m.month
GROUP BY m.month
HAVING COUNT(r.rating_id) = 0
ORDER BY m.month;
-- Returns 0 rows: all 12 months of 2023 are present.
