# Unit 6 Finding: Is the Failure Problem Getting Better or Worse?

To: CineRate Leadership  
From: Data Analysis  
Re: Withdrawn-rating trend for 2023 and priorities for next quarter

## Answer

**The failure problem got better after the first quarter and then held steady. It did not keep improving.** The share of ratings withdrawn fell from **22.6% in Q1** (12 of 53) to **14.6% in Q2** (7 of 48), then stayed flat at **15.7% in Q3** (8 of 51) and **14.6% in Q4** (7 of 48). Across the year, the rate fell from 18.8% in the first half (19 of 101) to 15.2% in the second half (15 of 99). That is roughly one withdrawn rating in every seven, so the problem is smaller, but not solved.

Supporting queries: monthly series with `LAG` and month-over-month change (`queries/unit6/q6_3.sql`, Part B), and the 30-day withdrawn rate (`queries/unit6/q6_2.sql`, Part B).

Three caveats limit how strongly this can be stated:

- **Monthly counts are small** (11 to 21 ratings), so single months swing widely: 27.3% in March, 0% in April, 25.0% in June. The quarterly figures are the reliable signal, not any single month.
- **The improvement is uneven by movie.** Movie 11 went from 4 withdrawals in the first half to 1 in the second, and Movie 2 from 3 to 1. But **Movie 9 got worse**, going from 1 to 3, and it is the movie with the year's longest unexplained gap: 112 days without a rating, from January to April (`q6_2.sql`, Part C).
- **Spam remains the leading cause** in both halves (7 withdrawals, then 5), so the main abuse pattern from Unit 5 is still active.

Activity is also short of target. The platform ended 2023 with 200 ratings against a 240-rating target, **83.3%** of the goal, and quarterly volume stayed flat at 48 to 53 (`q6_2.sql`, Part B running total).

## What the team should do next quarter

1. **Keep the moderation work that came after Q1, and aim it at spam.** The drop from Q1 to Q2 shows the platform can reduce withdrawals, but the rate has been flat for three quarters. Set a Q1 2024 target of **under 12% withdrawn**, and focus review on spam, the largest category in both halves.
2. **Move Movie 9 to the front of the review queue.** It is the only flagged movie whose withdrawals increased, and its status is unclear: it is currently `is_available = false` but received ratings through December. Confirm with the catalog team whether it was unavailable between January and April, and review its 4 withdrawn ratings.
3. **Start recording availability history.** The schema stores only a movie's current availability, so we cannot tell whether a gap like Movie 9's was a real lull or a temporary removal. Logging availability changes with dates would let next year's analysis separate the two.
4. **Report trends quarterly, with a 30-day moving average for monitoring.** At current volume, monthly percentages change by about 9 points per withdrawal, which invites false alarms. Review the month-over-month table only when a change persists for two months.

## Decision

The trend is better than at the start of 2023, but it has stalled at about 15%. Next quarter should focus on breaking that plateau, targeting spam and Movie 9, while fixing the availability data gap that currently prevents us from explaining activity stops.
