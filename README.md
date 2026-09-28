# ex603-movie-tv-rating-database.
Data Algorithms for scalable systems

Project Title

CineRate: A Movie & TV Show Rating Platform

One-Line Summary

A relational database system that lets users rate, review, and discover movies and TV shows based on aggregated community scores.

Chosen Theme

Entertainment / Media Rating & Recommendation System

Domain

CineRate is a platform designed to help users make informed decisions about what to watch by aggregating ratings and reviews from a community of viewers across both movies and TV shows. At its core, the platform tracks individual pieces of media (titles, release dates, genres), registered users, and the ratings those users submit. 

The platform must answer several core questions to be useful. For any given title, it needs to answer: What is the average rating, and how many people have rated it? For any given user, it needs to answer: What have they rated, and what might they enjoy next based on their rating history.

## Schema

The current PostgreSQL schema contains five tables:

- `users` stores registered users. Each user has an integer primary key, a required display name, and a unique email address.
- `movie` stores catalog titles, including the title, release year, and an `is_available` flag. A movie can be retired without removing its historical data.
- `genre` stores reusable genre names. Genre names are unique so the catalog cannot contain duplicate classifications.
- `movie_genre` is the junction table for the many-to-many relationship between movies and genres. Its composite primary key, `(movie_id, genre_id)`, prevents the same genre from being assigned to the same movie more than once.
- `rating` stores a user's rating of a movie, including the score and date submitted. It has its own primary key and foreign keys to both `users` and `movie`.

Several design decisions are worth noticing:

- The schema uses integer surrogate primary keys rather than titles, email addresses, or genre names as identifiers. Descriptive values can change, while referenced IDs remain stable.
- Foreign keys enforce referential integrity. Deleting a movie cascades to its `movie_genre` links, but is restricted when ratings exist so rating history is not accidentally destroyed. Deleting a genre is restricted while it is still assigned to a movie. Deleting a user cascades to that user's ratings to support account removal and privacy.
- `rating.score` is constrained to the 1-to-10 range with a `CHECK` constraint. Required identifiers and attributes use `NOT NULL`, so incomplete rows cannot be stored.
- The `is_available` flag supports soft retirement: a movie can be removed from active browsing while remaining available for historical ratings and aggregate reporting.

The product description mentions movies and TV shows, but the current schema models movies only. Supporting TV shows requires either a separate TV-show model or a shared media table before ratings can apply to both types without ambiguity.

