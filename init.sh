#!/bin/bash

ROOT=$(pwd)

. /etc/profile
. $ROOT/variables
. $ROOT/functions

if [ ! -d $LOG_FOLDER ] ; then
	mkdir -p $LOG_FOLDER
	chmod 1700 $LOG_FOLDER
fi

# Making sure we are running as sudo
if [ "$EUID" -ne 0 ] ; then
        printf "$(date) $0: Please run as root\n" >> $LOG_FOLDER'general.err'
        exit 1
fi
