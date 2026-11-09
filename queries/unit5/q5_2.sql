

-- Requirement 5.2 Part A (LEFT JOIN): Use LEFT JOIN to return all producers, including those who have never had an event.
-- Question: For every producer, how many events (ratings) do they have, including producers with zero events?
SELECT m.movie_id,
       m.title,
       COUNT(r.rating_id) AS event_count
FROM movies m
    LEFT JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY m.movie_id;

-- Requirement 5.2 Part A (INNER JOIN): Write an equivalent query using INNER JOIN.
-- Question: For every producer that has at least one event, how many events do they have?
SELECT m.movie_id,
       m.title,
       COUNT(r.rating_id) AS event_count
FROM movies m
    JOIN ratings r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY m.movie_id;

-- Requirement 5.2 Part A (comparison): Compare the results and determine how many producers are excluded by the inner join.
-- Question: How many producers total exist, how many have at least one event, and how many does the inner join drop as a result?
SELECT
    (SELECT COUNT(DISTINCT m.movie_id) FROM movies m) AS total_producers,
    (SELECT COUNT(DISTINCT m.movie_id)
         FROM movies m JOIN ratings r ON r.movie_id = m.movie_id) AS producers_with_events,
    (SELECT COUNT(DISTINCT m.movie_id) FROM movies m)
      - (SELECT COUNT(DISTINCT m.movie_id)
             FROM movies m JOIN ratings r ON r.movie_id = m.movie_id) AS producers_excluded_by_inner_join;

-- Requirement 5.2 Part A (which producers): Explain which producers are missing and why.
-- Question: Which specific producers disappear under the inner join, and is it because they've never had an event?
SELECT m.movie_id,
       m.title
FROM movies m
    LEFT JOIN ratings r ON r.movie_id = m.movie_id
WHERE r.movie_id IS NULL
ORDER BY m.movie_id;

--Why COUNT(r.rating_id) and not COUNT(*) in the first two queries: COUNT(*) would count
-- the single NULL-padded row a LEFT JOIN produces for an unmatched producer as 1 row,
-- wrongly reporting an event count of 1 for producers with zero events

--Why COUNT(DISTINCT m.movie_id) in the comparison query, per the hint: a plain
-- ungrouped join between movies and ratings would return one row per rating, not per movie
-- — a producer with 21 ratings would appear 21 times. COUNT(DISTINCT movie_id) collapses that back
-- down to a true producer count regardless of how many events each one has.

--Results and explanation: total_producers = 15, producers_with_events = 13,
-- so 2 producers are excluded by the inner join.
-- The anti-join query identifies them specifically:
-- Title_14 and Title_15 — confirmed by unit4.md, which already noted "two movies (Title_14, Title_15) have no ratings at all."
-- They're excluded because INNER JOIN only keeps rows where both sides match; since neither movie has any corresponding row in ratings,
-- there's nothing for them to match against, so they're dropped entirely rather than padded with zeros the way LEFT JOIN keeps them.

-- Requirement 5.2 Part B (RIGHT JOIN): Write a RIGHT JOIN that returns the same records as your LEFT JOIN from Part A.
-- Question: For every producer, how many events do they have, including producers with zero events — written as a RIGHT JOIN instead of a LEFT JOIN?
SELECT m.movie_id,
       m.title,
       COUNT(r.rating_id) AS event_count
FROM ratings r
    RIGHT JOIN movies m ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY m.movie_id;

-- Requirement 5.2 Part A (which producers): Explain which producers are missing and why.
-- Question: Which specific producers disappear under the inner join, and is it because they've never had an event?
SELECT m.movie_id,
       m.title
FROM ratings r
    RIGHT JOIN  movies m ON r.movie_id = m.movie_id
WHERE r.movie_id IS NULL
ORDER BY m.movie_id;

-- Requirement 5.2 Part B (verification): Compare the results to confirm that they match.
-- Question: Does the RIGHT JOIN version return exactly the same rows as the Part A LEFT JOIN version — not just the same row count?
SELECT movie_id, title, event_count FROM (
    SELECT m.movie_id, m.title, COUNT(r.rating_id) AS event_count
    FROM movies m LEFT JOIN ratings r ON r.movie_id = m.movie_id
    GROUP BY m.movie_id, m.title
) AS left_result
EXCEPT
SELECT movie_id, title, event_count FROM (
    SELECT m.movie_id, m.title, COUNT(r.rating_id) AS event_count
    FROM ratings r RIGHT JOIN movies m ON r.movie_id = m.movie_id
    GROUP BY m.movie_id, m.title
) AS right_result;

--EXCEPT returns any row that's in the LEFT JOIN result but not in the RIGHT JOIN result.
-- If the two queries are truly equivalent, this returns zero rows — which is the actual
-- checkable confirmation, rather than just trusting that "LEFT and RIGHT with tables swapped
-- should be the same." It's worth actually running this rather than reasoning it through,
-- since a mistake in which table went on which side of ON would silently produce a different
-- result that still looks plausible.

-- Requirement 5.2 Part B (FULL OUTER JOIN): Write a FULL OUTER JOIN that includes matching and unmatched records from both tables.
-- Question: Across both producers and events, which rows have no counterpart on the other side — from either direction?
SELECT m.movie_id,
       m.title,
       r.rating_id,
       r.score
FROM movies m
    FULL OUTER JOIN ratings r ON r.movie_id = m.movie_id
ORDER BY m.movie_id, r.rating_id;

--What this reveals here, and why it's limited: Scanning the output,
-- the only NULL-padded rows are on the ratings side — for Title_14 and Title_15, rating_id/score come back NULL,
-- exactly matching Part A. There are no rows where movie_id/title are NULL with a populated rating_id
-- — i.e., no "orphan" rating that lacks a producer. That's not a coincidence: ratings.movie_id is NOT NULL
-- with a foreign key to movies (ON DELETE RESTRICT), so the schema makes an orphaned rating structurally impossible.
-- In this specific relationship, FULL OUTER JOIN can't show you anything LEFT JOIN (from Part A) didn't already show,
-- because the "which side can have unmatched rows" question is already settled by the foreign key
-- — only movies can have unmatched rows; ratings never can.

--Where a FULL OUTER JOIN would reveal something a one-sided join can't: exactly the reconciliation scenario
-- from earlier in this conversation — comparing two tables that are supposed to mirror each other but aren't
-- protected by a foreign key (e.g. plays vs. plays_staging). There, orphans genuinely can exist on either side
-- independently (a row dropped from staging, or a row added to production that staging hasn't caught up to yet),
-- and only FULL OUTER JOIN surfaces both directions of drift in one query — a LEFT JOIN would catch one direction
-- and silently miss the other. Here, the referential integrity constraint already rules that case out,
-- so FULL OUTER JOIN's extra generality goes unused — but it's still the right join to reach for whenever
-- you can't be sure in advance which side(s) might have gaps

-- Requirement 5.2 Part C (NOT EXISTS): Identify producers who have never had an event.
-- Question: Which producers have no row in the ratings table at all?
SELECT m.movie_id,
       m.title
FROM movies m
WHERE NOT EXISTS (
    SELECT 1 FROM ratings r WHERE r.movie_id = m.movie_id
)
ORDER BY m.movie_id;

-- Requirement 5.2 Part C (EXCEPT): Identify producers who have never had an event, using a different approach.
-- Question: Which producers appear in the full producer list but disappear once producers with at least one event are subtracted out?
SELECT movie_id, title
FROM movies
EXCEPT
SELECT m.movie_id, m.title
FROM movies m
    JOIN ratings r ON r.movie_id = m.movie_id
ORDER BY movie_id;

--Both return the same two rows — Title_14 and Title_15.

--How they differ: NOT EXISTS works row-by-row — for each movies row, it runs a correlated check asking
-- "does any rating reference this specific movie_id?" and keeps the row if the answer is no, stopping
-- as soon as one match is found.
-- EXCEPT instead computes two complete result sets up front
-- (all producers, and all producers that have a matching rating) and then takes the set difference between them
-- — it's a whole-set operation, not a per-row check. Different mechanics, same outcome here, since both are
-- just different syntax for the identical underlying anti-join logic this conversation covered earlier.