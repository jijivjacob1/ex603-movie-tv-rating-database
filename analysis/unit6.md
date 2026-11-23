## Task 6.1: Compute Across a Window Without Collapsing

In these queries the event is a row in `ratings`, the metric is `score`, the producer is a movie, and a *failure* is a rating with `rating_status = 'withdrawn'`. Withdrawn ratings carry a 0.5 placeholder score (found in Unit 4), so movie averages use only non-withdrawn scores.

### A question that needs each row next to its group's average

**"Which individual ratings are unusually low or high for the movie they were given to?"** A moderator reviewing Movie 1 needs to see that rating 2 (score 1.2) sits 2.04 points below Movie 1's average of 3.24, while rating 10 (score 4.8) sits 1.56 above it. The answer is per rating, but the yardstick is per movie.

`GROUP BY movie_id` cannot answer this. It returns 13 rows, one per rated movie, with the average, and every individual rating is collapsed into that single number. Once the rows are gone, there is nothing left to compare against the average. The window version, `AVG(...) OVER (PARTITION BY movie_id)`, returns all 200 ratings and attaches the movie's average to each one, so the score, the average and the difference sit on the same row. The `GROUP BY` version loses the rating ID, user, date, status and the score itself.

### Ranking is never neutral

The ranking query orders movies by number of ratings, and the output contains four ties: Movies 5 and 7 (18 ratings), Movies 2 and 11 (16), Movies 1 and 13 (11), and Movies 14 and 15 (0).

- `ROW_NUMBER` gives every movie a unique position, so Movie 5 is 4th and Movie 7 is 5th. That ordering comes only from the `movie_id` tiebreaker, not from anything the movies did differently.
- `RANK` puts Movies 5 and 7 both at 4th and skips 5, so the next movie (Movie 12) is 6th.
- `DENSE_RANK` puts Movies 5 and 7 at 4th and Movie 12 at 5th, with no gap.

**Feature: a public "Most Rated This Year" leaderboard on the CineRate home page.** It should use **`RANK`**. Two movies with exactly 18 ratings did the same thing, so showing one above the other would favour a title for an arbitrary reason (its ID), and on a public page that is a visible unfairness to the movie and its audience. `RANK` shows them as equal, and the skipped number tells readers honestly that two titles share 4th place, so Movie 12 really is the sixth most-rated title. `DENSE_RANK` would call Movie 12 "5th" even though five titles have more ratings, which overstates its position. `ROW_NUMBER` is the right tool only where exactly N slots must be filled, such as a fixed three-tile carousel (see Task 6.3).

### NTILE(4) and tied producers

`NTILE(4)` splits the 15 movies into bands of 4, 4, 4 and 3 by row position. Movies 5 and 7 both have 18 ratings, but Movie 5 lands in band 1 and Movie 7 in band 2. NTILE cuts by count of rows, not by value, so tied movies can be split across a boundary. If bands drove anything visible, such as "top-tier" badges, the band boundaries should be set by value (for example with `CASE` on `rating_count`, or by checking ties at each cut) rather than by NTILE alone.

## Task 6.2: Compare Each Row to Its Neighbors

### What a large delta tells someone, and what to do about it

For Movie 11, the `delta` column (current score minus previous score) swings sharply: +1.8, then −2.8, then −3.2 when a withdrawn rating's 0.5 placeholder follows a 3.7. A large delta on a published rating means two consecutive viewers disagreed strongly about the same title. One swing is normal opinion. A run of large swings, especially next to withdrawn or flagged ratings, is a sign of rating manipulation (bursts of extreme scores) or of placeholder scores leaking into the series. The action is to check the status of the rows on both sides of the delta first. If both are published, send the burst to the moderation review feed from Unit 5. If one is withdrawn, the delta is an artifact, and the score series used for trends should exclude withdrawn rows.

### Why a running total answers a question a plain SUM cannot

A plain `SUM` answers "how many ratings did 2023 produce?" with one number: 200. A running total answers "where did we stand on any given date, and how did we get there?" The running total reaches 53 by 31 March, 101 by 30 June, 152 by 30 September and 200 by 31 December. Against a stated **target of 240 ratings for the year (20 per month)**, the platform finished at **83.3%** of target. The running total also shows *when* it fell behind: the first quarter ran close to pace, and the March and April months (11 ratings each) are where the shortfall opened. A single `SUM` has no time dimension, so it can show the shortfall but not where it started.

### Why I picked a 30-day moving-average window

The platform averages about 0.55 ratings per day, and most days have zero. A 7-day window would hold only about four ratings, so one withdrawal would swing the 7-day withdrawn rate by roughly 25 points, and the line would mostly show noise. A 30-day window holds about 16 ratings, roughly one month of activity, which is small enough to show the March dip and the June rise in withdrawals, but stable enough that a single rating does not dominate. A 90-day window would be smoother still, but it would hide the March and June changes that matter for moderation.

Because I first built one row per calendar day with `generate_series` and a `LEFT JOIN` (days with no ratings count as 0), `ROWS BETWEEN 29 PRECEDING AND CURRENT ROW` covers exactly 30 calendar days. Without that step, 30 rows would stretch across many more days and leave out the zero days.

**ROWS vs RANGE:** with `ROWS`, two rows with the same `ORDER BY` value are added one at a time, so each gets its own running total. With `RANGE` (the default frame), tied rows are peers, so they all receive the total through the last of them.

### What the gap means

The longest gap belongs to **Movie 9**: no ratings between 5 January and 28 April 2023, a gap of **112 days**, followed by 13 more ratings through December.

I believe this is a **real stop in activity for this title, not a platform-wide data loss**. During those same 112 days the platform recorded 61 ratings across 11 other movies, so the ratings pipeline was working. What I cannot tell is *why* Movie 9 went quiet. Movie 9 is currently marked `is_available = false`, but the schema keeps only the current value of that flag, not its history, so the data cannot show whether the title was pulled from the catalog during the gap and restored later. That would be a side effect of how availability is recorded. Movie-specific data loss (for example, ratings for one title failing to load) is also possible but less likely, because nothing else about Movie 9's rows looks different.

Each explanation needs a different response. A real lull calls for a discoverability or promotion check. A temporary removal calls for recording availability changes with dates (an `availability_history` table). Movie-specific data loss calls for checking the ingestion logs for Movie 9 between January and April. The first thing to do is ask the catalog team whether Movie 9 was unavailable in that window. That single answer separates the first two explanations.

## Task 6.3: Build the Reporting Patterns

### The feature that top-N would power, and why three

Top-N per category would power a **"Top Reviews" panel on each movie's detail page**: the three highest-scoring published ratings for that title, each with its reviewer and date, plus how far each sits below the movie's best rating (`FIRST_VALUE`).

Three is the right number for this panel. **One** review looks like a single cherry-picked endorsement and is easy to dismiss or game: one coordinated account could own the slot. **Ten** pushes the panel below the fold and starts including middling ratings. In our data, Movie 4 has only four published ratings, so a 10-slot list could not be filled and would include its lowest scores. **Three** fits in a single row on desktop and mobile, shows that more than one person liked the title, and stays within what nearly every movie can fill: every rated movie in the dataset has at least three published ratings.

Ties at third are handled with `ROW_NUMBER` ordered by `score DESC, rated_at, rating_id`, so each movie shows exactly three ratings, and on equal scores the earliest rating wins. This matters here: Movies 5, 7, 8 and 10 each have four to six published 5.0 ratings (and Movie 12 ties at 4.5), so `RANK` would return four to six rows for them and break a three-slot layout. Earliest-first rewards the reviewers who rated the title first, and the result is the same every time the page loads.

### What a large month-over-month change means, and what to do about it

The month-over-month query shows several large swings. Rating volume fell 47.6% from February to March (21 to 11), then rose 54.5% from April to May (11 to 17). The withdrawn rate rose 8.3 points in March (to 27.3%), dropped to 0% in April, then rose 13.2 points in June (to 25.0%). All twelve months are present, so `LAG` always compares adjacent months.

In CineRate, a large rise in the withdrawn rate means a larger share of submitted ratings was removed for spam, policy violations, duplicates or user request. That is either a spike in abuse (for example, a coordinated campaign around a release) or a change in moderation behaviour (new rules, or a review backlog cleared in one month). The action is to drill into that month: break its withdrawn ratings down by `withdrawn_reason` and by movie, using the Unit 4 and Unit 5 queries. If one reason or one title dominates, escalate to Trust & Safety. A large drop in volume, like March, should go to the product team, who can check whether a release, a catalog change or an outage reduced activity. Because monthly counts here are small (11 to 21 ratings), the action threshold should be a change sustained across two months, or a change of several ratings, not a percentage alone: one withdrawal in an 11-rating month moves the rate by 9 points.

## Reflection

In CineRate, a question that is easy with a window function but awkward with `GROUP BY` alone is: **"For each movie, list each of its ratings in date order, showing whether that rating was higher or lower than the one before it, and flag ratings that sit far from the movie's average."** A moderator needs this to spot bursts of extreme scores on a single title.

Two things make it hard with `GROUP BY`. First, the answer has one row per rating, but the comparison values (the movie's average and the previous rating's score) come from other rows. `GROUP BY movie_id` collapses each movie into one row, so the individual ratings the moderator needs to inspect disappear. Getting them back means computing the averages in a subquery and joining them back on `movie_id`. Second, "the previous rating" has no aggregate at all. Without `LAG`, you need a self-join that finds the latest earlier rating of the same movie, which is easy to get wrong when two ratings share a timestamp.

With window functions, both become a single pass: `AVG(score) OVER (PARTITION BY movie_id)` attaches the average to every row, and `LAG(score) OVER (PARTITION BY movie_id ORDER BY rated_at, rating_id)` fetches the previous score, with the tiebreaker making the order deterministic. Every row survives, which is the core difference: aggregates summarize groups, and window functions add group context to each row without losing it.
