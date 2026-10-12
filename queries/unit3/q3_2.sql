
--200
SELECT COUNT(*) AS total_rows FROM ratings;

--22
SELECT COUNT(*) FROM ratings WHERE withdrawn_reason != 'Spam detected';

--166
SELECT COUNT(*) FROM ratings WHERE withdrawn_reason IS NULL;

SELECT COUNT(*) FROM ratings WHERE withdrawn_reason IS NULL or withdrawn_reason != 'Spam detected';

SELECT COUNT(*) FROM ratings
WHERE COALESCE(withdrawn_reason, '') != 'Spam detected'

166 + 22 + 12

SELECT score * weight AS weighted_score
FROM ratings
WHERE weighted_score > 5;

SELECT score * weight AS weighted_score
FROM ratings
WHERE score * weight > 5

WITH scored AS (
    SELECT score * weight AS weighted_score
    FROM ratings
)
SELECT weighted_score
FROM scored
WHERE weighted_score > 5
LIMIT 5;





