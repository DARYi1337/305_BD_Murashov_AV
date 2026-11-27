#!/bin/bash
set -e
if command -v chcp >/dev/null 2>&1; then
    chcp 65001
fi

sqlite3 -bail movies_rating.db < db_init.sql

echo "1. Список фильмов, имеющих хотя бы одну оценку. Сортировка по году выпуска и названию, первые 10 фильмов."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT m.id, m.title, m.year
FROM movies AS m
WHERE EXISTS (SELECT 1 FROM ratings AS r WHERE r.movie_id = m.id)
ORDER BY m.year, m.title
LIMIT 10;"
echo " "

echo "2. Пользователи, фамилии которых начинаются на A. Сортировка по дате регистрации, первые 5 пользователей."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT id, name, email, gender, register_date, occupation
FROM users
WHERE substr(name, instr(name, ' ') + 1, 1) = 'A'
ORDER BY register_date
LIMIT 5;"
echo " "

echo "3. Имя и фамилия эксперта, название и год фильма, оценка и дата оценки. Сортировка по имени эксперта, названию и оценке, первые 50 записей."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT u.name AS expert, m.title, m.year, r.rating,
       date(r.timestamp, 'unixepoch') AS rating_date
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
JOIN movies AS m ON m.id = r.movie_id
ORDER BY u.name, m.title, r.rating
LIMIT 50;"
echo " "

echo "4. Фильмы и присвоенные пользователями теги. Сортировка по году, названию и тегу, первые 40 записей."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT m.title, m.year, t.tag
FROM movies AS m
JOIN tags AS t ON t.movie_id = m.id
ORDER BY m.year, m.title, t.tag
LIMIT 40;"
echo " "

echo "5. Все фильмы последнего года выпуска, имеющиеся в базе данных."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT id, title, year, genres
FROM movies
WHERE year = (SELECT MAX(year) FROM movies)
ORDER BY title;"
echo " "

echo "6. Комедии после 2000 года с мужскими оценками не ниже 4.5. Название, год и количество таких оценок. Сортировка по году и названию."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT m.title, m.year, COUNT(*) AS rating_count
FROM movies AS m
JOIN ratings AS r ON r.movie_id = m.id
JOIN users AS u ON u.id = r.user_id
WHERE ('|' || m.genres || '|') LIKE '%|Comedy|%'
  AND m.year > 2000 AND u.gender = 'male' AND r.rating >= 4.5
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title;"
echo " "

echo "7. Количество пользователей по профессиям, самые распространённые и самые редкие профессии."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT occupation, COUNT(*) AS user_count
FROM users
GROUP BY occupation
ORDER BY user_count DESC, occupation;"
echo " "
echo "Самые распространённые профессии:"
sqlite3 -bail movies_rating.db -box -echo "WITH counts AS (
    SELECT occupation, COUNT(*) AS user_count FROM users GROUP BY occupation
)
SELECT occupation, user_count FROM counts
WHERE user_count = (SELECT MAX(user_count) FROM counts)
ORDER BY occupation;"
echo " "
echo "Самые редкие профессии:"
sqlite3 -bail movies_rating.db -box -echo "WITH counts AS (
    SELECT occupation, COUNT(*) AS user_count FROM users GROUP BY occupation
)
SELECT occupation, user_count FROM counts
WHERE user_count = (SELECT MIN(user_count) FROM counts)
ORDER BY occupation;"
