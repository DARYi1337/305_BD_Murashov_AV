#!/bin/bash
set -e
if command -v chcp >/dev/null 2>&1; then
    chcp 65001
fi

sqlite3 -bail movies_rating.db < db_init.sql

echo "1. Пары пользователей, оценивших один и тот же фильм, без дубликатов и пар с самим собой. Имена пользователей и название фильма, первые 100 записей."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "WITH rated AS (
    SELECT DISTINCT user_id, movie_id FROM ratings
)
SELECT u1.name AS user1, u2.name AS user2, m.title
FROM rated AS r1
JOIN rated AS r2 ON r2.movie_id = r1.movie_id AND r1.user_id < r2.user_id
JOIN users AS u1 ON u1.id = r1.user_id
JOIN users AS u2 ON u2.id = r2.user_id
JOIN movies AS m ON m.id = r1.movie_id
ORDER BY u1.name, u2.name, m.title, r1.user_id, r2.user_id, m.id
LIMIT 100;"
echo " "

echo "2. Десять самых свежих оценок от разных пользователей: название фильма, имя пользователя, оценка и дата в формате ГГГГ-ММ-ДД."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "WITH latest AS (
    SELECT r.*, ROW_NUMBER() OVER (
        PARTITION BY user_id ORDER BY timestamp DESC, id DESC
    ) AS rn
    FROM ratings AS r
)
SELECT m.title, u.name, r.rating, date(r.timestamp, 'unixepoch') AS rating_date
FROM latest AS r
JOIN movies AS m ON m.id = r.movie_id
JOIN users AS u ON u.id = r.user_id
WHERE r.rn = 1
ORDER BY r.timestamp DESC, r.id DESC
LIMIT 10;"
echo " "

echo "3. Все фильмы с максимальным и минимальным средним рейтингом. В колонке Рекомендуем указать Да или Нет. Сортировка по году и названию."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "WITH averages AS (
    SELECT m.id, m.title, m.year, AVG(r.rating) AS average_rating
    FROM movies AS m JOIN ratings AS r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
), bounds AS (
    SELECT MAX(average_rating) AS highest, MIN(average_rating) AS lowest
    FROM averages
)
SELECT a.title, a.year, ROUND(a.average_rating, 3) AS average_rating,
       CASE WHEN a.average_rating = b.highest THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем'
FROM averages AS a CROSS JOIN bounds AS b
WHERE a.average_rating = b.highest OR a.average_rating = b.lowest
ORDER BY a.year, a.title;"
echo " "

echo "4. Количество оценок и средняя оценка, выставленная женщинами с 2010 по 2012 год включительно."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT COUNT(*) AS rating_count, ROUND(AVG(r.rating), 3) AS average_rating
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
WHERE u.gender = 'female'
  AND date(r.timestamp, 'unixepoch') >= '2010-01-01'
  AND date(r.timestamp, 'unixepoch') < '2013-01-01';"
echo " "

echo "5. Фильмы со средней оценкой и местом в рейтинге по средней оценке. Сортировка по году и названию, первые 20 записей."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "WITH averages AS (
    SELECT m.id, m.title, m.year, AVG(r.rating) AS average_rating
    FROM movies AS m JOIN ratings AS r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
), ranked AS (
    SELECT *, RANK() OVER (ORDER BY average_rating DESC) AS rating_rank
    FROM averages
)
SELECT title, year, ROUND(average_rating, 3) AS average_rating, rating_rank
FROM ranked
ORDER BY year, title
LIMIT 20;"
echo " "

echo "6. Десять последних зарегистрированных пользователей в формате Фамилия Имя|Дата регистрации."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "SELECT substr(name, instr(name, ' ') + 1) || ' ' ||
       substr(name, 1, instr(name, ' ') - 1) || '|' || register_date AS user_info
FROM users
ORDER BY register_date DESC, id DESC
LIMIT 10;"
echo " "

echo "7. Таблица умножения для чисел от 1 до 10 с помощью рекурсивного CTE."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "WITH RECURSIVE numbers(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT a.n || 'x' || b.n || '=' || (a.n * b.n) AS multiplication
FROM numbers AS a CROSS JOIN numbers AS b
ORDER BY a.n, b.n;"
echo " "

echo "8. Все уникальные жанры из таблицы movies, каждый в отдельной строке, с помощью рекурсивного CTE."
echo "--------------------------------------------------"
sqlite3 -bail movies_rating.db -box -echo "WITH RECURSIVE split(rest, genre) AS (
    SELECT genres || '|', '' FROM movies WHERE genres IS NOT NULL AND genres <> ''
    UNION ALL
    SELECT substr(rest, instr(rest, '|') + 1),
           trim(substr(rest, 1, instr(rest, '|') - 1))
    FROM split WHERE rest <> ''
)
SELECT DISTINCT genre FROM split
WHERE genre <> ''
ORDER BY genre;"
