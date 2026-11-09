-- Requirement 5.3 Part A: Explore CROSS JOIN and verify its row count.
-- The catalog tables are small enough to display every movie/genre pairing.

-- Count the source tables.
SELECT COUNT(*) AS movie_count
FROM movies;

SELECT COUNT(*) AS genre_count
FROM genres;

-- A CROSS JOIN pairs every movie with every genre, whether or not that
-- genre is actually assigned to that movie in movie_genres.
SELECT m.movie_id,
	   m.title,
	   g.genre_id,
	   g.genre_name
FROM movies m
CROSS JOIN genres g
ORDER BY m.movie_id, g.genre_id;

-- Count the resulting rows.
SELECT COUNT(*) AS cross_join_row_count
FROM movies m
CROSS JOIN genres g;

-- Verify that the result count equals the product of the source counts.
WITH source_counts AS (
	SELECT
		(SELECT COUNT(*) FROM movies) AS movie_count,
		(SELECT COUNT(*) FROM genres) AS genre_count
),
cross_join_count AS (
	SELECT COUNT(*) AS row_count
	FROM movies m
	CROSS JOIN genres g
)
SELECT movie_count,
	   genre_count,
	   row_count AS cross_join_row_count,
	   movie_count * genre_count AS expected_row_count,
	   row_count = movie_count * genre_count AS counts_match
FROM source_counts
CROSS JOIN cross_join_count;

-- a CROSS JOIN between movies and genres is useful when you want every possible
-- movie–genre pairing, for example to build a grid for checking which genre assignments are missing.
-- The number of rows will be COUNT(movies) × COUNT(genres).

--It would be a query error if you meant to show only genres actually assigned to each movie.
-- In that case, join movies to genres through movie_genres. A CROSS JOIN would pair every movie with every genre,
-- misrepresent assignments, and could inflate counts in later analysis.

-- Requirement 5.3 Part B: Examine the Task 5.1 three-table join plan.
-- ANALYZE executes this read-only SELECT and reports actual rows and timings.
EXPLAIN ANALYZE
SELECT user_name, title, rated_at
FROM ratings
JOIN users USING (user_id)
JOIN movies USING (movie_id)
ORDER BY user_name, title, rated_at;
