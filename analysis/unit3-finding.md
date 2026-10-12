# Unit 3 Finding: Why the Payout Looked Frozen-Worthy, and Why It Shouldn't Be

To: Dashboard team
From: Data analysis
Re: This cycle's payout hold

The dashboard's "clean ratings" count — the number used to decide whether this cycle's payout could go through — reported that only 22 of our 200 ratings were clean, with the rest apparently in question. That 11% figure is what triggered the hold: a drop that steep looked like a real spike in disputed or spam activity, serious enough to pause payout until someone could explain it.

It isn't real. When we went back through the underlying data by hand, 188 of the 200 ratings are legitimate — 94%, not 11%. The gap comes from how the report's query was written, not from anything wrong with the ratings themselves. The query tried to count every rating that wasn't specifically marked "spam," but it did that by excluding anything that didn't explicitly say "not spam" in a particular field. The problem is that a normal, never-disputed rating doesn't have anything written in that field at all — it's simply blank, because nothing ever happened to it that would require an explanation. The report's logic treated "blank" the same as "unknown, so leave it out," which meant it silently dropped every one of our 166 completely ordinary, never-flagged ratings, and only counted the small handful that had an explicit "not spam" label attached. The 12 ratings that actually were confirmed spam were correctly set aside either way; the other 166 were never the problem.

We recommend releasing the payout for this cycle. There's no evidence of a genuine spike in disputed activity — the real clean rate is 94%, in line with what we'd expect, and the only thing that changed was how the report counted rows, not what actually happened on the platform. Before this dashboard is used to gate another payout decision, the underlying query needs to be corrected so that a blank field is treated as "not disputed" rather than silently dropped; we're happy to walk through the fix with whoever owns that report.
