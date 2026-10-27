#!/bin/bash
python make_db_init.py || exit 1
sqlite3 -bail movies_rating.db < db_init.sql
