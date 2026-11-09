--5.1.1
-- Requirement: Who are the people behind the events?
-- Question: For each rating, who submitted it, which movie was it for,
-- and when was it submitted?

SELECT
       user_name,
       title,
       rated_at
FROM ratings
     JOIN  users USING(user_id)
     JOIN  movies USING(movie_id)
ORDER BY user_name,title,rated_at;

-- Requirement 5.1.2: Do the producers identified in Assignment 4 share certain catalog credentials or tags?
-- Question: Which genre tag do at least two of our flagged producers (Movie 2, Movie 9, Movie 11) share,
-- and which movies carry that tag?
SELECT
       title,
       genre_name
FROM movies
    JOIN movie_genres mg USING(movie_id)
    JOIN genres USING (genre_id)
WHERE mg.genre_id IN (
    SELECT genre_id
    FROM movie_genres
    WHERE movie_id IN (2, 9, 11)
    GROUP BY genre_id
    HAVING COUNT(DISTINCT movie_id) > 1
)
ORDER BY title,genre_name;


-- Requirement 5.1.3: How do the producers compare with one another?
-- Question: Do our flagged producers (Movie 2, Movie 9, Movie 11) share catalog characteristics —
-- origin country and release era — with other producers, and how does their rating activity compare?
SELECT m1.movie_id          AS flagged_movie_id,
       m1.title             AS flagged_title,
       m1.origin_country,
       m1.release_year      AS flagged_release_year,
       (SELECT COUNT(*) FROM ratings r WHERE r.movie_id = m1.movie_id) AS flagged_rating_count,
       m2.movie_id          AS compared_movie_id,
       m2.title             AS compared_title,
       m2.release_year      AS compared_release_year,
       (SELECT COUNT(*) FROM ratings r WHERE r.movie_id = m2.movie_id) AS compared_rating_count,
       CASE
           WHEN m2.movie_id IS NOT NULL THEN
               'Peer found - both ' || m1.origin_country || ', '
               || (CASE WHEN m1.release_year >= 2015 THEN '2015 or later' ELSE 'Before 2015' END)
               || ' era'
           ELSE
               'No peer found - no other ' || m1.origin_country || ' movie in the '
               || (CASE WHEN m1.release_year >= 2015 THEN '2015 or later' ELSE 'Before 2015' END)
               || ' era'
       END AS match_status
FROM movies m1
    LEFT JOIN movies m2
        ON m1.origin_country = m2.origin_country
       AND (CASE WHEN m1.release_year >= 2015 THEN '2015 or later' ELSE 'Before 2015' END)
         = (CASE WHEN m2.release_year >= 2015 THEN '2015 or later' ELSE 'Before 2015' END)
       AND m1.movie_id <> m2.movie_id
WHERE m1.movie_id IN (2, 9, 11)
ORDER BY m1.movie_id, m2.movie_id;