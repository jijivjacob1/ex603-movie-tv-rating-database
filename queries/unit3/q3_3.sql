-- Task 3.3: Answer a two-step question with a subquery.
-- Question: Which users were involved in a flagged (disputed) rating?

--Two-step question: which users were involved in a flagged (disputed) rating event?

SELECT user_id, user_name FROM users
WHERE user_id IN (SELECT user_id FROM ratings WHERE rating_status = 'flagged')
ORDER BY user_id;

WITH flagged_users AS (
    SELECT DISTINCT user_id FROM ratings WHERE rating_status = 'flagged'
)
SELECT u.user_id, u.user_name
FROM users u JOIN flagged_users f ON u.user_id = f.user_id
ORDER BY u.user_id;

SELECT u.user_id, u.user_name
FROM users u
WHERE u.user_id IN (
    SELECT user_id FROM users
    INTERSECT
    SELECT user_id FROM ratings WHERE rating_status = 'flagged'
)
ORDER BY u.user_id;