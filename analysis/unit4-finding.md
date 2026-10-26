# Unit 4 Finding: Where Ratings Are Being Withdrawn

To: Leadership team
From: Data analysis
Re: Rating failure rate across movies

## The true failure rate

We treat a rating as a failure when it has been withdrawn from the platform after it was submitted. Of our 200 ratings, **34 were withdrawn — a failure rate of 17%**, or roughly one rating in six.

Not every withdrawal points to a problem. Seven of the 34 were withdrawn at the user's own request. The other 27 were removed for spam (12), policy violations (8), or because they duplicated an earlier rating (7). Counting only those problem-driven removals, the rate is **13.5%**. Either way, this is well above what we would expect from a healthy rating pool, and it is not spread evenly.

## How it varies across movies

To compare movies fairly, we only judged the 12 movies with at least 10 ratings each. A movie with a handful of ratings can swing to an extreme from one or two withdrawals, so its rate tells us little. Among those 12 movies, the typical withdrawal rate is about 17%, but the range is wide:

- At the healthy end, **Movie 10** has 19 ratings and **none** withdrawn, and **Movie 8** has one withdrawal out of 20.
- At the other end, three movies have a quarter or more of their ratings withdrawn.

One movie, **Movie 4**, shows a high rate (2 of 6), but with only six ratings it is too early to draw a conclusion. Two other movies, **Movies 14 and 15**, have no ratings yet.

## Which movies we would investigate

| Movie | Ratings | Withdrawn | Rate | Why it stands out |
|---|---|---|---|---|
| **Movie 11** | 16 | 5 | 31% | Highest rate, nearly double the typical movie; also the lowest average score in the catalog |
| **Movie 9** | 14 | 4 | 29% | Second-highest rate; withdrawals spread across spam, policy, and user requests |
| **Movie 2** | 16 | 4 | 25% | Three of its four withdrawals were for spam — the clearest sign of a targeted problem |

**Movie 11** is the first priority. It has the most withdrawals, and its low average score is partly caused by them: withdrawn ratings are stored with a placeholder score of 0.5, so they drag the average down. We would want to know whether the movie genuinely has an unhappy audience or is attracting problematic ratings.

**Movie 2** deserves a look for a different reason. Its withdrawal rate is only moderately high, but the pattern — repeated spam removals — suggests someone may be trying to manipulate its rating. Once the spam is removed, its remaining ratings are among the most favorable in the catalog.

**Movie 9** rounds out the list as a high-rate title with no single obvious cause, which makes it worth a manual review.

## What we recommend

Review the withdrawn ratings for Movies 11, 2, and 9 to confirm whether they reflect real abuse, and check whether the same accounts appear across them. Separately, the placeholder score given to withdrawn ratings should be excluded from movie averages, so that a movie isn't penalized in our reports for ratings we have already removed.
