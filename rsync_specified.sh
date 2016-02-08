#!/bin/bash

. /inotify_rsync/app/init.sh

# Making sure we are running as sudo
if [ "$EUID" -ne 0 ] ; then
        printf "$(date "+$DATE_FORMAT") $0: Please run as root\n" >> $LOG_FOLDER'general.err'
        exit 1
fi

# Parse Command Line Arguments
if [ -z $1 ] ; then
	printf "No path specified.\n"
	exit 1 
else
	FIRST_LETTER="$(echo $1 | head -c 1)"
	if [ ! $FIRST_LETTER == '/' ] ; then
		printf "Should use full path.\n"
		exit 1
	fi
fi

# Sync folders
if [ -f $HOSTS_FILE ] ; then
	while read HOST; do
		rsync -aRrzi --delete --rsync-path='sudo rsync' --log-format='%t [%p] %i /%f' $1 ${HOST}:/
	done < $HOSTS_FILE
fi
