#!/bin/bash

. /inotify_rsync/init.sh

PROCESSES=( $(pgrep $EXECUTABLE) )

# Making sure we are running as sudo
if [ "$EUID" -ne 0 ] ; then
	printf "$(date "+$DATE_FORMAT") $0: Please run as root\n" >> $LOG_FOLDER'general.err'
	exit 1
fi

# Show some help
function print_help() {
	cat <<-HELP
		This script is used to check if there is inotify process running for each host. And restart watch if it's not running
		You need to provide the following arguments:
			1) Full path to file with domains locations
		Usage: (sudo) bash ${0##*/} --domains_source=PATH
		Example: (sudo) bash ${0##*/} --domains_source=/tmp/hosts.list
	HELP
	exit 0
}

# Parse Command Line Arguments
while [ $# -gt 0 ]; do
        case "$1" in
                --domains_source=*)
                        DOMAINS_FILE="${1#*=}"
                        ;;
                --help)
                        print_help
                        ;;
                *)
                        printf "$(date +"$DATE_FORMAT") $0: Error: Invalid argument, run --help for valid arguments.\n" >> $LOG_FOLDER'general.err'
                        print_help
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
			printf "$(date +"$DATE_FORMAT") $0: Error. Watch for $DOMAIN is not running, restarting ...\n" >> $LOG_FOLDER'general.err'
			nohup $RESTART_COMMAND$DOMAIN 1>>$LOG_FOLDER'check_inotify_processes.log' 2>>$LOG_FOLDER'check_inotify_processes.err' &
		fi
	done < $DOMAINS_FILE
fi
