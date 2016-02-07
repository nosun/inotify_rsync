#!/bin/bash

. ./init.sh

PROCESSES=( $(pgrep $EXECUTABLE) )

# Making sure we are running as sudo
if [ "$EUID" -ne 0 ] ; then
	printf "$(date "+$DATE_FORMAT") $0: Please run as root\n" >> $LOG_FOLDER'general.err'
	exit 1
fi

# Parse Command Line Arguments
while [ $# -gt 0 ]; do
        case "$1" in
                --domains_source=*)
                        DOMAINS_FILE="${1#*=}"
                        ;;
                --help)
                        print_check_inotify_processes_help
                        ;;
                *)
                        printf "$(date +"$DATE_FORMAT") $0: Error: Invalid argument, run --help for valid arguments.\n" >> $LOG_FOLDER'general.err'
			print_check_inotify_processes_help
        esac
        shift
done

# Making sure file is valid
if [ -z "$DOMAINS_FILE" ] || [ ! -f "$DOMAINS_FILE" ]; then
        printf "$(date +"$DATE_FORMAT") $0: Error: Can't find domains file. Please check file path and make sure file is readable.\n" >> $LOG_FOLDER'general.err'
        exit 1
fi

declare -A DOMAINS_RUNNING

for PID in "${PROCESSES[@]}" ; do
	PROCESS=`ps -fp $PID`
	DOMAIN=`expr match "$PROCESS" "[^']\+--path=\([^']\+\)"`
	DOMAINS_RUNNING[$DOMAIN]=1
done

if [ -f $DOMAINS_FILE ] ; then
	while read DOMAIN; do
		if [ ! ${DOMAINS_RUNNING[$DOMAIN]+_} ] ; then
			MSG=$(date "+$DATE_FORMAT")" $0: Error. Watch for $DOMAIN is not running, restarting ..."
			# One for log
			printf $MSG"\n" >> $LOG_FOLDER'general.err'
			# One for crontab notifications
			printf '%s\n' "$MSG Check logs for more details."

			printf "$(date +"$DATE_FORMAT") $0: Doing initial rsync before initiating a watch.\n" >> $LOG_FOLDER'general.err'
			synchronize $DOMAIN	# functions include

			printf "$(date +"$DATE_FORMAT") $0: Initiating a watch.\n" >> $LOG_FOLDER'general.err'
			nohup $RESTART_COMMAND$DOMAIN 1>>$LOG_FOLDER'check_inotify_processes.log' 2>> $LOG_FOLDER'check_inotify_processes.err' &
		fi
	done < $DOMAINS_FILE
fi
