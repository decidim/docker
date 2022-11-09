#! /bin/sh
set -e
# Wait for postgres to be available for connections
echo "Waiting for database, cache and job databases."

wait-for-it "${DATABASE_HOST:-db}:${DATABASE_PORT:-5432}" -t 60
# Wait for cache_host and job_host as it might be two diferents redis instances
if [ -z ${CACHE_HOST+x} ];
then
	wait-for-it "${CACHE_HOST:-redis}:${CACHE_PORT:-6379}" -t 60
fi

if [ -z ${JOB_HOST+x} ];
then
	wait-for-it "${JOB_HOST:-redis}:${JOB_PORT:-6379}" -t 60
fi
