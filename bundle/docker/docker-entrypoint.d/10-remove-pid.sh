#! /bin/sh
set -e
# Remove pid file if exists
PID_FILE=$ROOT/${RAILS_PID_FILE:-"tmp/pids/server.pid"}
if [[ -f ${PID_FILE} ]]; then
	echo "Removing pid file ${PID_FILE}"
	rm -f "${PID_FILE}"
fi