#!/bin/bash

. /inotify_rsync/app/init.sh

PROCESSES=( $(pgrep $EXECUTABLE) )

# Making sure we are running as sudo
if [ "$EUID" -ne 0 ] ; then
        printf "$(date +"$DATE_FORMAT") $0: Please run as root\n" >> $LOG_FOLDER'general.err'
        exit 1
fi

for PID in "${PROCESSES[@]}" ; do
	CHILD_PROCESSES=( $(pgrep -P $PID) )

	for CPID in "${CHILD_PROCESSES[@]}" ; do
		kill $CPID
	done
	# Add need to kill this script running in the background
	kill $PID
done
