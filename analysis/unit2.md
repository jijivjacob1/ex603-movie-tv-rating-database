## Task 2.2: Constraint reasoning

### Foreign-key constraints

| Foreign key | ON DELETE choice | Reason |
|---|---|---|
| `movie_genre.movie_id` references `movie.movie_id` | `CASCADE` | A movie-genre link has no meaning after its movie is deleted, so the dependent junction row should be removed automatically. |
| `movie_genre.genre_id` references `genre.genre_id` | `RESTRICT` | A genre may be shared by many movies, so deleting it must be blocked while any movie still uses it. |
| `rating.movie_id` references `movie.movie_id` | `RESTRICT` | A movie with ratings must not be hard-deleted because those ratings are historical user data that should remain valid. |
| `rating.user_id` references `users.user_id` | `CASCADE` | Deleting a user account should also delete that user's ratings because the ratings are personal activity belonging to the deleted account. |

The `movie_genre.movie_id` foreign key governs what happens when a producer removes a movie from the database. The affected rows are the matching entries in `movie_genre`, which only record the association between that movie and its genres. `CASCADE` removes those association rows automatically, preventing orphaned links. Under `RESTRICT`, the movie deletion would fail until every junction row was removed manually. That would be safe but unnecessarily cumbersome, and it could leave stale associations if the cleanup were forgotten. In normal platform use, a movie should be retired by changing `movie.is_available` to `false`; the cascade is a safety rule for a genuine hard delete.

The `movie_genre.genre_id` foreign key governs what happens when an administrator tries to remove a genre from the catalog. The affected data is any `movie_genre` row that still uses that genre. `RESTRICT` blocks the deletion while the genre is attached to one or more movies, protecting the classification data from becoming inconsistent. Under `CASCADE`, deleting a shared genre would silently remove every movie's association with it. That could unexpectedly change the genre information shown for many movies. An administrator must therefore remove or reassign the associations deliberately before deleting the genre.

The `rating.movie_id` foreign key governs what happens when a producer or administrator attempts to hard-delete a movie. The affected records would be all ratings submitted for that movie. `RESTRICT` prevents the deletion, preserving the referential link between each rating and the movie it describes. The intended platform event is usually a soft retirement: setting `is_available` to `false` hides the movie from new catalog activity while retaining its ratings for historical averages and reporting. Under `CASCADE`, hard-deleting the movie would also delete all of its ratings, destroying community history and changing aggregate scores. Under `SET NULL`, the database would retain ratings that no longer identify what was rated, which would make them unusable and conflict with the required `NOT NULL` foreign key.

The `rating.user_id` foreign key governs what happens when a user deletes their account. The affected records are that user's ratings. `CASCADE` removes them automatically, which supports a privacy-oriented account deletion and avoids retaining personal activity after the account is gone. Under `RESTRICT`, account deletion would fail whenever the user had ratings, forcing the application to find and delete those ratings separately and increasing the risk of incomplete cleanup. Under `SET NULL`, the ratings would remain but would no longer identify their author; that is not the chosen privacy policy and is incompatible with the `NOT NULL` constraint on `rating.user_id`.

### CHECK constraints

The `rating.score BETWEEN 1 AND 10` check makes ratings below 1 and above 10 impossible to store. Without it, invalid values such as `0`, `-1`, or `11` could enter the table through a bug, an import, or a client that bypasses normal application validation. Those values would distort average-rating calculations and make scores inconsistent with the platform's ten-point rating scale.
