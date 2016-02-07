#!/bin/bash

ROOT='/inotify_rsync'

. /etc/profile
. $ROOT/app/variables
. $ROOT/app/functions

if [ ! -d $LOG_FOLDER ] ; then
	mkdir -p $LOG_FOLDER
	chmod 1700 $LOG_FOLDER
fi

if [ ! -d $DATA_FOLDER ] ; then
        mkdir -p $DATA_FOLDER
        chmod 700 $DATA_FOLDER
fi

# Making sure we are running as sudo
if [ "$EUID" -ne 0 ] ; then
        printf "$(date +"$DATE_FORMAT") $0: Please run as root\n" >> $LOG_FOLDER'general.err'
        exit 1
fi
