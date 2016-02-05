#!/bin/bash

. /etc/profile
. /inotify_rsync/variables

# Making sure we are running as sudo
if [ "$EUID" -ne 0 ] ; then
	printf "$0: Please run as root\n" >> $LOG_FOLDER'general.err'
        exit 1
fi


# Show some help
function print_help() {
	cat <<-HELP
		This script is used to sync folders between instances based on inotifywait reports.
		You need to provide the following arguments:
			1) Full path to watch
		Usage: (sudo) bash ${0##*/} --path=PATH
		Example: (sudo) bash ${0##*/} --path=/var/www/vhosts/website/httpdocs
	HELP
	exit 0
}

# Parse Command Line Arguments
while [ $# -gt 0 ]; do
	case "$1" in
		--path=*)
			WATCH_PATH="${1#*=}"
			WATCH_PATH="${WATCH_PATH%/}" # removing trailing slash to avoid confusion later
			;;
		--help)
			print_help
			;;
		*)
			printf "$0: Error: Invalid argument, run --help for valid arguments.\n" >> $LOG_FOLDER'general.err'
			print_help
	esac
	shift
done

# Making sure path is valid
if [ -z "${WATCH_PATH}" ] || [ ! -d "${WATCH_PATH}" ] ; then
	printf "$0: Error: Please provide a valid path.\n" >> $LOG_FOLDER'general.err'
	exit 1
fi

# Create new
function replicate {
	if [ $1 ] && [ -f $HOSTS_FILE ] ; then
		while read HOST; do
			rsync -aRrzq --rsync-path='sudo rsync' $1 ${HOST}:/ 1>/dev/null 2>>$LOG_FOLDER'launch_inotify.err'
		done < $HOSTS_FILE
	fi
}

# Remove obsolete
function remove {
	if [ $1 ] && [ -f $HOSTS_FILE ] ; then
		while read HOST; do
			ssh ${HOST} 'sudo rm -r '$1' 1>/dev/null 2>>'$LOG_FOLDER'launch_inotify.err'
		done < $HOSTS_FILE
	fi
}

# Establishing watch
while read -r FULL_PATH EVENT ; do
	if [[ $EVENT == *"DELETE_SELF"* && "${FULL_PATH%/}" == "$WATCH_PATH" ]] ; then
		# Need to remove inotifywait process as well. It is running as child process
		# Can't use group ID as this script will be primarily called from another script
		#  in bulk, so all of the processes spawn by the same iteration will have the same group ID
		CHILD_PROCESSES=( $(pgrep -P $$) )
		for PID in "${CHILD_PROCESSES[@]}" ; do
			kill $PID
		done
		# Add need to kill this script running in the background
		kill $$
		exit 1
	elif [[ $EVENT == *"DELETE"* || $EVENT == *"MOVED_FROM"* ]] ; then
		remove $FULL_PATH
	else
		replicate $FULL_PATH
	fi
done < <(exec inotifywait -m -r -q -e modify,attrib,close_write,move,create,delete,delete_self --format '%w%f %e' $WATCH_PATH)
