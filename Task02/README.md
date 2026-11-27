# Task02

## Требования к окружению

- Python 3.8 или новее (команда `python`).
- SQLite 3 (команда `sqlite3`).
- Git Bash в Windows или Bash в Linux/macOS.

## Запуск

Перейти в каталог `Task02` и выполнить:

```bash
bash db_init.bat
```

Скрипт генерирует `db_init.sql` из файлов каталога `dataset` и создаёт базу
`movies_rating.db` с таблицами `movies`, `ratings`, `tags`, `users`.
При повторном запуске таблицы удаляются и заполняются заново.
