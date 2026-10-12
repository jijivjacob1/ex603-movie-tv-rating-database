

--Find active, highly rated producers. Use your theme’s filter condition from the appendix.
--Sort them and return the first ten. movies



SELECT movie_id,
       title,
       release_year
FROM movies
WHERE is_available = true
AND release_year >= 2015
ORDER BY release_year desc
LIMIT 10;

--Find all possible event statuses. Display the distinct values in the event status column.
--Look carefully at the results. Are there more statuses than you expected?

SELECT distinct rating_status
FROM ratings;

--Filter the events in two different ways. Write: one query that filters a numeric range,
--and one query that filters using an explicit list of values with IN.
SELECT rating_id,
       u.user_name,
       m.title,
       score
FROM ratings r
JOIN USERS u ON u.user_id = r.user_id
JOIN movies m ON m.movie_id = r.movie_id
WHERE score between 3 and 4;

SELECT rating_id,
       u.user_name,
       m.title,
       score,
       rating_status
FROM ratings r
JOIN USERS u ON u.user_id = r.user_id
JOIN movies m ON m.movie_id = r.movie_id
WHERE rating_status IN('flagged','published');


--Work with text and missing values. Write queries that:
--find producers whose names match a text pattern using LIKE,
--and identify records where a reason/value is missing (NULL).
--Use COALESCE to replace a missing value with a useful label such as: No reason provided.

SELECT title,
       release_year,
       score,
       rating_status,
       COALESCE(withdrawn_reason, 'No reason provided') AS withdrwan_reason
FROM movies m
JOIN ratings r ON r.movie_id = m.movie_id
WHERE title like 'Title_0%';

--Make the results easier to understand. Create a query with calculated/computed columns that would make sense to someone who does not work with SQL. Depending on your theme, you might calculate or label:
--a payout amount,
--a time of day,
--a value/rating category,
--or another useful business measure.
  --        Use CASE where appropriate to create plain-language categories.
SELECT
    rating_id,
    title,

    -- Raw score (0.0–5.0) translated into a label anyone understands
    CASE
        WHEN score >= 4.5 THEN 'Excellent'
        WHEN score >= 3.5 THEN 'Good'
        WHEN score >= 2.5 THEN 'Average'
        WHEN score >= 1.5 THEN 'Poor'
        ELSE 'Very Poor'
    END AS rating_category,

    -- Timestamp bucketed into a plain time-of-day label
    CASE
        WHEN EXTRACT(HOUR FROM rated_at) BETWEEN 5  AND 11 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM rated_at) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN EXTRACT(HOUR FROM rated_at) BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Late Night'
    END AS time_of_day_rated,

    -- "Payout"-style business measure: the score weighted by how much
    -- this rating counts toward the movie's overall rating
    ROUND(score * weight, 2) AS weighted_score,

    -- How long it took the user to go from rating to writing a review,
    -- in plain language instead of a raw interval
    CASE
        WHEN reviewed_at IS NULL THEN 'No review written'
        WHEN reviewed_at - rated_at <= INTERVAL '30 minutes' THEN 'Reviewed quickly'
        ELSE 'Reviewed later'
    END AS review_responsiveness,

    -- Status plus the reason, in one readable column (reuses the earlier COALESCE)
    CASE
        WHEN rating_status = 'withdrawn'
            THEN 'Withdrawn — ' || COALESCE(withdrawn_reason, 'No reason provided')
        ELSE UPPER(rating_status)
    END AS status_summary

FROM ratings r
JOIN movies m ON r.movie_id = m.movie_id
ORDER BY rated_at;




