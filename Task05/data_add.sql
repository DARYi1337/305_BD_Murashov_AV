-- Запустить один раз после db_init.sql. Адреса example.com учебные.
PRAGMA foreign_keys = ON;
BEGIN IMMEDIATE;

INSERT INTO occupations (name) VALUES ('student')
ON CONFLICT (name) DO NOTHING;

-- Дату регистрации SQLite берёт из системного времени через DEFAULT.
WITH students (first_name, last_name, email, gender) AS (
    VALUES
        ('Александр', 'Михайлов', 'mikhailov.task05@example.com', 'male'),
        ('Дарья', 'Моисеева', 'moiseeva.task05@example.com', 'female'),
        ('Алексей', 'Мурашов', 'murashov.alexey.task05@example.com', 'male'),
        ('Виталий', 'Осипов', 'osipov.task05@example.com', 'male'),
        ('Дмитрий', 'Пасагин', 'pasagin.task05@example.com', 'male')
)
INSERT INTO users (first_name, last_name, email, gender, occupation_id)
SELECT s.first_name, s.last_name, s.email, s.gender, o.id
FROM students AS s JOIN occupations AS o ON o.name = 'student';

INSERT INTO genres (name) VALUES ('Action'), ('Animation'), ('Drama')
ON CONFLICT (name) DO NOTHING;

-- Запоминаем ID сразу после каждой вставки фильма.
CREATE TEMP TABLE new_movies (
    movie_id INTEGER PRIMARY KEY,
    genre TEXT NOT NULL,
    rating REAL NOT NULL
);

INSERT INTO movies (title, year) VALUES ('Джон Уик 4', 2023);
INSERT INTO new_movies VALUES (last_insert_rowid(), 'Action', 4.5);

INSERT INTO movies (title, year) VALUES ('Дикий робот', 2024);
INSERT INTO new_movies VALUES (last_insert_rowid(), 'Animation', 5.0);

INSERT INTO movies (title, year) VALUES ('Идеальные дни', 2023);
INSERT INTO new_movies VALUES (last_insert_rowid(), 'Drama', 4.0);

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.movie_id, g.id
FROM new_movies AS m JOIN genres AS g ON g.name = m.genre;

-- Время оценок также заполняется через DEFAULT.
INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.movie_id, m.rating
FROM users AS u CROSS JOIN new_movies AS m
WHERE u.email = 'murashov.alexey.task05@example.com';

DROP TABLE temp.new_movies;
COMMIT;
