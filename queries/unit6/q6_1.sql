-- Task 6.1: Compute across a window without collapsing.
-- Note: withdrawn ratings carry a 0.5 placeholder score (see Unit 4), so movie
-- averages below use only non-withdrawn scores.

-- Requirement 6.1.1 (window version)
-- Question: Is each rating unusual for its own movie? Show every rating next
-- to its movie's average score and how far it sits from that average.
SELECT r.rating_id,
       r.movie_id,
       m.title,
       r.rated_at,
       r.rating_status,
       r.score,
       ROUND(AVG(CASE WHEN r.rating_status <> 'withdrawn' THEN r.score END)
             OVER (PARTITION BY r.movie_id), 2)                        AS movie_avg_score,
       ROUND(r.score - AVG(CASE WHEN r.rating_status <> 'withdrawn' THEN r.score END)
             OVER (PARTITION BY r.movie_id), 2)                        AS diff_from_movie_avg
FROM ratings r
     JOIN movies m USING (movie_id)
ORDER BY r.movie_id, r.rated_at;
-- Returns 200 rows: one per rating.

-- Requirement 6.1.1 (GROUP BY version, for comparison)
-- Question: What is each movie's average score?
SELECT r.movie_id,
       m.title,
       COUNT(*)                                                         AS rating_count,
       ROUND(AVG(CASE WHEN r.rating_status <> 'withdrawn' THEN r.score END), 2) AS movie_avg_score
FROM ratings r
     JOIN movies m USING (movie_id)
GROUP BY r.movie_id, m.title
ORDER BY r.movie_id;
-- Returns 13 rows: one per rated movie. The individual ratings (score, user,
-- date, status) are collapsed away, so we can no longer see which ratings
-- are far from their movie's average.

-- Requirement 6.1.2
-- Question: How do movies rank by number of ratings, and how does each
-- ranking function treat movies with the same count?
-- LEFT JOIN keeps Movies 14 and 15, which have no ratings.
WITH movie_counts AS (
    SELECT m.movie_id,
           m.title,
           COUNT(r.rating_id) AS rating_count
    FROM movies m
         LEFT JOIN ratings r USING (movie_id)
    GROUP BY m.movie_id, m.title
)
SELECT movie_id,
       title,
       rating_count,
       ROW_NUMBER() OVER (ORDER BY rating_count DESC, movie_id) AS row_num,
       RANK()       OVER (ORDER BY rating_count DESC)           AS rnk,
       DENSE_RANK() OVER (ORDER BY rating_count DESC)           AS dense_rnk
FROM movie_counts
ORDER BY rating_count DESC, movie_id;
-- Ties: Movies 5 and 7 (18), 2 and 11 (16), 1 and 13 (11), 14 and 15 (0).

-- Requirement 6.1.3
-- Question: If we split movies into four activity bands by number of ratings,
-- which band does each movie land in, and do tied movies get split up?
WITH movie_counts AS (
    SELECT m.movie_id,
           m.title,
           COUNT(r.rating_id) AS rating_count
    FROM movies m
         LEFT JOIN ratings r USING (movie_id)
    GROUP BY m.movie_id, m.title
)
SELECT movie_id,
       title,
       rating_count,
       NTILE(4) OVER (ORDER BY rating_count DESC, movie_id) AS activity_band
FROM movie_counts
ORDER BY rating_count DESC, movie_id;
-- NTILE cuts by row position, not by value: 15 movies become bands of
-- 4, 4, 4 and 3. Tied movies can land in different bands: Movies 5 and 7
-- both have 18 ratings, but Movie 5 is in band 1 and Movie 7 is in band 2.
