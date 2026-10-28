"""Generate db_init.sql from the source files in dataset."""

import csv
import math
import re
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
DATASET_DIR = BASE_DIR / "dataset"

SCHEMA = """BEGIN TRANSACTION;

DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS users;

CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT NOT NULL
);

CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    gender TEXT NOT NULL,
    register_date TEXT NOT NULL,
    occupation TEXT NOT NULL
);

"""


def sql_value(value):
    """Serialize a typed value as an SQL literal, escaping apostrophes."""
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        if isinstance(value, float) and not math.isfinite(value):
            raise ValueError("Rating must be a finite number")
        return str(value)
    return "'" + value.replace("'", "''") + "'"


def split_title(title):
    """Extract only the final parenthesized year; retain other parentheses."""
    title = title.strip()
    match = re.search(r"\s*\((\d{4})\)$", title)
    if match:
        return title[:match.start()].rstrip(), int(match.group(1))
    return title, None


def read_csv(filename):
    with (DATASET_DIR / filename).open(encoding="utf-8-sig", newline="") as source:
        yield from csv.DictReader(source)


def write_insert(output, table, columns, values):
    literals = ", ".join(sql_value(value) for value in values)
    output.write(f"INSERT INTO {table} ({columns}) VALUES ({literals});\n")


def main():
    # Publish the finished SQL only after all input has been parsed successfully.
    temporary = BASE_DIR / "db_init.sql.tmp"
    try:
        with temporary.open("w", encoding="utf-8", newline="\n") as output:
            output.write(SCHEMA)

            for row in read_csv("movies.csv"):
                title, year = split_title(row["title"])
                write_insert(output, "movies", "id, title, year, genres",
                             (int(row["movieId"]), title, year, row["genres"]))

            with (DATASET_DIR / "users.txt").open(
                encoding="utf-8-sig", newline=""
            ) as source:
                for row in csv.reader(source, delimiter="|", quoting=csv.QUOTE_NONE):
                    if not row:
                        continue
                    user_id, name, email, gender, registered, occupation = row
                    write_insert(output, "users",
                                 "id, name, email, gender, register_date, occupation",
                                 (int(user_id), name, email, gender, registered, occupation))

            for number, row in enumerate(read_csv("ratings.csv"), start=1):
                write_insert(output, "ratings", "id, user_id, movie_id, rating, timestamp",
                             (number, int(row["userId"]), int(row["movieId"]),
                              float(row["rating"]), int(row["timestamp"])))

            for number, row in enumerate(read_csv("tags.csv"), start=1):
                write_insert(output, "tags", "id, user_id, movie_id, tag, timestamp",
                             (number, int(row["userId"]), int(row["movieId"]),
                              row["tag"], int(row["timestamp"])))

            output.write("\nCOMMIT;\n")
        temporary.replace(BASE_DIR / "db_init.sql")
    finally:
        temporary.unlink(missing_ok=True)
    print("Created db_init.sql")


if __name__ == "__main__":
    main()
