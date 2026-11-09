## Task 5.1: Connect Producers to Their Data

### Where the three-table join from Question 1 could be used

The Question 1 query (`users JOIN ratings JOIN movies`) returns, for every rating, the user who submitted it, the movie it was for, and when it happened. That's exactly the shape of data behind an **activity/audit feed** — a screen that lets a moderator or admin scroll through rating events as they occur, rather than only seeing per-movie or per-user summaries.

Concretely, this could power a **moderation review feed**: a list of recent ratings showing `user_name`, `title`, and `rated_at`, so a reviewer can see who rated what and when without cross-referencing three separate screens. That's directly useful for the kind of investigation `unit4-finding.md` recommended — confirming whether the same accounts appear across Movies 11, 2, and 9's withdrawn ratings. Extending the same join with `rating_status` and `withdrawn_reason` would turn it into exactly that review tool: a chronological, per-user, per-movie trail of activity on the flagged titles.

### Why the junction table matters for Question 2

Question 2 asks whether the producers identified in Assignment 4 share catalog tags, by joining `movies` to `genres` through `movie_genres`. The junction table matters because the relationship between movies and genres is **many-to-many**: a single movie can carry several genre tags (Movie 2 is tagged Drama, Comedy, *and* Thriller), and a single genre applies to many movies. Neither side can hold that relationship with a plain foreign key — a foreign key only models "many rows point to one," not "many rows point to many rows."

Without the junction table, there'd be no clean relational way to store or query this. The two realistic fallbacks are both worse:

- **Limit each movie to a single genre column on `movies`.** This is simplest to query, but it's a lossy denormalization — Movie 2 would have to pick just one of Drama, Comedy, or Thriller, discarding real data. The Question 2 analysis (finding that Movie 2 bridges two different pairings — Drama with Movie 9, Comedy with Movie 11) would become impossible, since the overlap only exists because Movie 2 holds multiple tags at once.
- **Store genres as a delimited text field** (e.g. `"Drama,Comedy,Thriller"`). This keeps multiple tags, but breaks ordinary SQL: filtering by a single tag needs string pattern matching instead of equality, counting how many movies share a tag needs string parsing instead of `GROUP BY`/`HAVING`, and there's no `UNIQUE` or foreign-key constraint stopping a typo or duplicate tag from being stored.

With `movie_genres` as a proper junction table, each movie–genre pairing is its own row, so ordinary joins, equality filters, and aggregate functions (the `HAVING COUNT(DISTINCT movie_id) >= 2` query used to find Drama and Comedy as the shared tags) all work directly. Without it, the same analysis would require either giving up on multi-tag movies or writing much more fragile, harder-to-index string-parsing logic in place of a simple join.

## Task 5.2: Find Records That Joins May Exclude

### Which producers were excluded by the inner join

**Movie 14 (Title_14)** and **Movie 15 (Title_15)**. Both appear in the `LEFT JOIN`, `RIGHT JOIN`, `NOT EXISTS`, and `EXCEPT` results with zero events, and both disappear from the `INNER JOIN` result entirely.

### What it means for a producer to have no events

It means no row in `ratings` references that `movie_id` — no user has ever rated that movie, not even once. The data alone just confirms the absence of activity; it doesn't say why. Plausible explanations include: the title was added to the catalog but never promoted or surfaced to users; it's new enough that no one has gotten to it yet; it's geographically or linguistically restricted in a way that limits its visible audience; it was soft-launched or held back intentionally; or there's a data-pipeline gap where ratings for it exist elsewhere but never loaded.

### How an inner-join-only report misleads leadership

A report built only on `INNER JOIN` silently drops Movie 14 and Movie 15 from every result — not by explicitly saying "these have zero activity," but by making them vanish as if they didn't exist in the catalog at all. Leadership reading rating counts, average scores, or withdrawal rates derived that way would see a complete-looking table of, say, 13 movies and have no way to know 2 more titles exist with no data behind them. The report would look internally consistent and complete while actually describing only the subset of the catalog that happens to have engagement — understating the true catalog size and hiding exactly the titles that most need a decision (promote, investigate, or retire).

### Why leadership would want to find producers that have never been active

Zero-activity titles represent catalog risk that an engagement-only report can't surface: licensing or hosting costs paid for content nobody is watching or rating, a possible content-discovery or metadata problem preventing a title from being found, or a data-ingestion gap that's silently losing real activity. Finding these titles explicitly is what lets leadership distinguish "a deliberately small but fully engaged catalog" from "a catalog with blind spots."

### What action leadership could take

Investigate Movie 14 and Movie 15 specifically: confirm whether they're genuinely visible and searchable in the product (not hidden by a UI bug or missing metadata), check whether their licensing cost is still justified given zero measured engagement, and verify the ratings pipeline isn't simply failing to ingest activity for these two titles specifically. Depending on what that investigation finds, the action is either promotional (feature them to generate first engagement), administrative (retire or deprioritize them), or technical (fix a data gap).

### What the data shows vs. what needs further investigation

The data firmly shows: Movie 14 and Movie 15 have zero rows in `ratings`, and both are over a year old (`added_on` of 2022-02-21 and 2022-04-11) and currently marked `is_available = TRUE` — so "too new to have been rated yet" is not a supported explanation here. What the data does **not** show is *why* they have no activity — whether that's a discoverability problem, a genuine lack of audience interest, a metadata or licensing restriction limiting who can see them, or an ingestion gap in the ratings pipeline. Confirming the actual cause would require looking outside this dataset: product/UI logs showing whether these titles are ever served in search or recommendations, catalog metadata for regional or licensing restrictions, and the ratings ingestion pipeline's logs for the relevant date ranges.

## Task 5.3: Understand Join Performance and Execution Plans

### Part A: CROSS JOIN

The query in `queries/unit5/q5_3.sql` counts `movies` and `genres` separately, lists their `CROSS JOIN`, counts the resulting rows, and verifies that the joined count equals `movie_count * genre_count`. A cross join has no matching condition: every movie is paired with every genre. In the current database, there are 15 movies and 5 genres, so the result has `15 * 5 = 75` rows; the verification query returns `counts_match = TRUE`.

A Cartesian product is useful when every combination is wanted, such as generating all candidate movie/genre pairs for a completeness check or creating a grid of scenarios for analysis. It can also be an error when a join condition was accidentally omitted: unrelated rows multiply, producing more rows than expected and potentially inflating later counts or aggregates. Here the product is intentionally bounded by the small catalog tables. The `CROSS JOIN` does not mean that each genre is assigned to each movie; `movie_genres` contains the actual assignments.

### Part B: Examine a Query Execution Plan

The SQL file runs `EXPLAIN ANALYZE` on the Task 5.1 Part A three-table join. This is a read-only `SELECT`; `ANALYZE` executes it and reports actual rows and timings. The complete plan below was captured from the `ex603_movies` database and returned 200 rows. This run's output also includes buffer counters.

```text
Sort  (cost=35.98..36.48 rows=200 width=524) (actual time=2.678..2.699 rows=200.00 loops=1)
      Sort Key: users.user_name, movies.title, ratings.rated_at
  Sort Method: quicksort  Memory: 34kB
  Buffers: shared hit=30
  ->  Nested Loop  (cost=12.40..28.34 rows=200 width=524) (actual time=0.149..0.366 rows=200.00 loops=1)
        Buffers: shared hit=30
        ->  Hash Join  (cost=12.25..17.80 rows=200 width=270) (actual time=0.111..0.205 rows=200.00 loops=1)
              Hash Cond: (ratings.user_id = users.user_id)
              Buffers: shared hit=4
              ->  Seq Scan on ratings  (cost=0.00..5.00 rows=200 width=16) (actual time=0.050..0.084 rows=200.00 loops=1)
                    Buffers: shared hit=3
              ->  Hash  (cost=11.00..11.00 rows=100 width=262) (actual time=0.041..0.042 rows=30.00 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 10kB
                    Buffers: shared hit=1
                    ->  Seq Scan on users  (cost=0.00..11.00 rows=100 width=262) (actual time=0.021..0.025 rows=30.00 loops=1)
                          Buffers: shared hit=1
        ->  Memoize  (cost=0.15..0.41 rows=1 width=262) (actual time=0.000..0.000 rows=1.00 loops=200)
              Cache Key: ratings.movie_id
              Cache Mode: logical
              Hits: 187  Misses: 13  Evictions: 0  Overflows: 0  Memory Usage: 2kB
              Buffers: shared hit=26
              ->  Index Scan using movies_pkey on movies  (cost=0.14..0.40 rows=1 width=262) (actual time=0.003..0.003 rows=1.00 loops=13)
                    Index Cond: (movie_id = ratings.movie_id)
                    Index Searches: 13
                    Buffers: shared hit=26
Planning Time: 2.467 ms
Execution Time: 2.831 ms

```

1. **Cartesian product use:** For CineRate, a `movies CROSS JOIN genres` can generate every possible movie/genre pair for a completeness grid, which can then be compared with `movie_genres` to find missing assignments. It is not appropriate for showing the genres actually assigned to each movie; that requires joining through `movie_genres`.

2. **Join algorithms selected:** PostgreSQL chose a **Hash Join** for `ratings` and `users`, followed by a **Nested Loop** to join those rows to `movies`. It used `Memoize` and a `movies_pkey` **Index Scan** inside that loop. A final **Sort** satisfies the requested `ORDER BY`; the sort is not a join algorithm.

3. **Evidence for the choices:** The plan scans `ratings` (200 actual rows) and `users` (30 actual rows), builds a small hash table for users (10 kB, one batch), and matches on `ratings.user_id = users.user_id`. Scanning and hashing the small `users` table is inexpensive, while the query needs all rating rows. For movie matches, `movies_pkey` supports a lookup by `movie_id`; `Memoize` reports 187 hits and 13 misses over 200 loops, so repeated movie IDs avoid repeated index searches. The planner estimated 100 users versus 30 actual rows, illustrating why accurate statistics matter. The final sort used quicksort and 34 kB. The plan reports 2.831 ms execution time in this run; timing can vary with cache and system load.

4. **Why the algorithms matter:** Join choices affect how much data PostgreSQL scans, hashes, sorts, or probes through indexes. Understanding the plan helps identify whether runtime is dominated by row volume, repeated lookups, sorting, or a poor row-count estimate, and helps guide measured improvements instead of adding indexes blindly.

5. **What could change the choice:** With a much larger `ratings` table and a selective filter on a user or movie, an index-supported Nested Loop could be cheaper than scanning and hashing whole tables; indexes on `ratings.user_id` or `ratings.movie_id` could help those filtered lookup paths. For large inputs already ordered on join keys, or with useful indexes providing that order, a Merge Join could become competitive. Larger or less selective inputs may favor Hash Joins, while hash-table or sort memory pressure can change costs. Table growth, changed value distributions, indexes, and refreshed statistics can all alter the planner's estimates and chosen plan. In this unfiltered query, PostgreSQL must process every matching rating, and the final sort over the growing result is likely to become more expensive and may spill to disk if it outgrows available sort memory.

## Task 5.4: Reflection

The plan reflects the current, small dataset: PostgreSQL scans all 200 ratings, hashes the 30 users in 10 kB, and uses the `movies_pkey` index inside a Nested Loop. If the ratings table grew substantially, the planner might still scan it for this unfiltered query because every rating is needed, but the join and final sort would process more rows. A filter that selected only a small number of ratings could make an index lookup and Nested Loop cheaper than scanning and hashing entire tables. Adding indexes on `ratings.user_id` or `ratings.movie_id` could support those selective lookups, though indexes add storage and slow inserts and updates.

The share of rows that match also matters. If nearly every rating matches a user and movie, sequential scans and a Hash Join can be efficient. If only a few rows match, index probes can avoid reading irrelevant rows. A Merge Join could become attractive if the inputs were large and already ordered by their join keys, perhaps through suitable indexes; otherwise, sorting both inputs first may cost more than hashing them. Finally, updated statistics help PostgreSQL estimate table sizes and match rates. In this plan, it estimated 100 users but found 30, so refreshed, representative statistics could affect its cost estimates and algorithm choice. The planner compares estimated work, not one algorithm in isolation; changes to data distribution, indexes, filters, and available memory may therefore produce a different plan.
