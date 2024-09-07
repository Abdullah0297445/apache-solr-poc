#!/bin/bash

# if any of the commands in your code fails for any reason, the entire script fails
set -o errexit
# exits if any of your variables is not set
set -o nounset

postgres_ready() {
python << END
import sys
import psycopg

try:
    psycopg.connect(
        dbname="${DB_NAME}",
        user="${DB_USER}",
        password="${DB_PASS}",
        host="${DB_HOST}",
        port="${DB_PORT}",
    )
except psycopg.OperationalError:
    sys.exit(-1)
sys.exit(0)

END
}
until postgres_ready; do
  >&2 echo 'Waiting for PostgreSQL to become available...'
  sleep 1
done
>&2 echo 'PostgreSQL is available'

solr_ready() {
python  << END
import sys
import pysolr

conn = pysolr.Solr("http://${SOLR_HOST}:${SOLR_PORT}/solr/")

try:
    conn.ping()
except (ConnectionError, ConnectionRefusedError, pysolr.SolrError) as exc:
    if '404' in str(exc):
        sys.exit(0)
    sys.exit(-1)
sys.exit(0)

END
}
until solr_ready; do
  >&2 echo 'Waiting for Solr to become available...'
  sleep 1
done
>&2 echo 'Solr is available'

exec "$@"
