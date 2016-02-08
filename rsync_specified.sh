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

# Making sure file is valid
if [ -z "$DOMAINS_FILE" ] || [ ! -f "$DOMAINS_FILE" ]; then
        printf "$(date +"$DATE_FORMAT") $0: Error: Can't find domains file. Please check file path and make sure file is readable.\n" 
        exit 1
fi

if [ -f $DOMAINS_FILE ] ; then
        while read DOMAIN; do
	        synchronize $1
        done < $DOMAINS_FILE
fi
