#!/bin/bash

set -u 

PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -d "$DB_NAME" -U "$DB_USER" -p 5432 -a -q -f $@

# BEGIN TRANSACTION;
# CREATE ROLE db-user WITH PASSWORD password;
# GRANT ALL ON DATABASE db TO db-user;
# COMMIT;