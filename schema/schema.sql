-- =================================================================
-- EX 603 Assignment 2 — schema.sql
-- Theme: Entertainment / Media Rating & Recommendation System
-- Author: Jiji Jacob
-- Target: PostgreSQL 14+
-- =================================================================


drop table if exists movie_genre cascade;
drop table if exists rating cascade;
drop table if exists users cascade;
drop table if exists movie cascade;
drop table if exists genre cascade;


-- ----------------------------------------------------------------
-- 1. users — first, because it references only users who use the app

-- ----------------------------------------------------------------

create table users(
      user_id int not null,
      email varchar(255) not null,
      displayname varchar(50) not null,
      PRIMARY KEY (user_id),
      unique(email)
  );

-- ----------------------------------------------------------------
-- 2. movie — second, because it references only the movies it rates
-- ----------------------------------------------------------------
create table movie(
      movie_id int not null,
      title varchar(255) not null,
      is_available boolean not null,
      release_year int not null,
      PRIMARY KEY (movie_id)

  );

-- ----------------------------------------------------------------
-- 3. genre — third, because it references only the generes that app rates
-- ----------------------------------------------------------------
create table genre(
      genre_id int not null,
      name varchar(255) not null,
      PRIMARY KEY (genre_id),
      unique(name)
  );

-- ----------------------------------------------------------------
-- 4. movie_genre — junction resolves the M:N between movie and genre.
-- The primary key is the pair of foreign keys, not a new id.

-- ----------------------------------------------------------------
create table movie_genre(
      movie_id int not null,
      genre_id int not null,
      PRIMARY KEY (movie_id,genre_id),
      CONSTRAINT fk_movie_genres_movie
      FOREIGN KEY (movie_id) references movie(movie_id) ON DELETE CASCADE,
      CONSTRAINT fk_movie_genres_genre
      FOREIGN KEY (genre_id) references genre(genre_id) ON DELETE RESTRICT
  );

-- ----------------------------------------------------------------
-- 5. rating — junction table between user and movie has its own primary key
--    primary key is a new id
-- ----------------------------------------------------------------
create table rating(
      rating_id int not null,
      user_id int not null,
      movie_id int not null,
      score int  NOT NULL CHECK (score BETWEEN 1 AND 10),
      rated_at date  NOT NULL DEFAULT CURRENT_DATE,
      PRIMARY KEY (rating_id),
      CONSTRAINT fk_ratings_movie
      FOREIGN KEY (movie_id) references movie(movie_id) ON DELETE RESTRICT,
      CONSTRAINT fk_ratings_user
      FOREIGN KEY (user_id) references users (user_id) ON DELETE CASCADE
  );




