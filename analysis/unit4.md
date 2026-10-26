# Unit 4 Finding: What the Per-Movie Averages Don't Show

To: Catalog manager
From: Data analysis
Re: Reading the per-movie rating breakdown

## Who acts on this

The per-producer breakdown — rating count, average score, and withdrawn rate for each movie — is for the **catalog manager**, the person who decides which titles to feature, which licenses to renew, and which titles need a closer look. A movie near the bottom of the table is a candidate for less promotion or a review; one near the top is a candidate for more. That makes it important to know what the single numbers in each row leave out.

## What the average hides: its distribution

An average reports a middle, but not the shape around it. Across our movies, the spread of scores is wide — a standard deviation of roughly 1.4 to 1.9 on a 0.5–5 scale — so the same average can describe very different audiences:

| Movie | Ratings | Average | Median | Average (published only) |
|---|---|---|---|---|
| Title_10 | 19 | 3.31 | 4.20 | 3.31 |
| Title_13 | 11 | 2.82 | 1.70 | 2.86 |
| Title_02 | 16 | 2.77 | 2.90 | 3.53 |

- **Title_10** looks middling at 3.31, but its median is 4.2: most viewers rated it well, and a smaller group of low scores pulls the average down.
- **Title_13** looks similar to its neighbours at 2.82, but its median is 1.7. Opinion on it is split, not lukewarm, and only 11 ratings stand behind the number.
- **Title_02** appears to be a weak title at 2.77, but that average includes withdrawn ratings, which are all stored with a placeholder score of 0.5. Counting only published ratings, it scores 3.53 — above most of the catalog.

A decision made from the average column alone would demote titles that viewers actually like.

## What the count hides: who is counted

A rating count sounds like a measure of audience size, but it counts ratings, not people, and it counts every status together:

- **Repeat raters.** Title_06's 21 ratings come from 14 distinct users; Title_10's 19 ratings come from 12. Part of the "volume" is the same people rating more than once.
- **One region carrying the number.** Half of Title_11's 16 ratings come from a single region. Its low average may describe one market's reaction rather than the whole audience.
- **Ratings that aren't opinions.** Withdrawn and flagged ratings are included in the count alongside published ones. A movie with many withdrawals looks more popular than it is, and scores lower than it should.

## What we need to see next

Before using this breakdown to decide anything about a title, we would want, for each movie:

1. **The score distribution** — median and spread alongside the average, or a simple count of ratings in each score band, so a split audience is visible.
2. **Distinct raters next to total ratings** — to separate broad interest from a few enthusiastic or repeat users.
3. **Ratings by status** — published, flagged, and withdrawn shown separately, with the headline average calculated on published ratings only.
4. **The regional mix** — how many ratings come from each region, so one market's reaction isn't read as everyone's.
5. **A minimum-volume flag** — titles with fewer than about 10 ratings marked as too thin to judge, as in our withdrawn-rate analysis.

With those additions, the catalog manager can tell the difference between a title that is genuinely weak and one that is polarizing, thinly rated, or dragged down by placeholder scores.
