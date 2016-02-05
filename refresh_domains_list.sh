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
		This script is used to refresh list of physical file locations for our domains, which will be used by sync script later.
		You need to provide the following arguments:
			1) Full path to file to dump destinations
		Usage: (sudo) bash ${0##*/} --dump_to=PATH_TO_FILE
		Example: (sudo) bash ${0##*/} --dump_to=/tmp/hosts.list
	HELP
	exit 0
}

# Parse Command Line Arguments
while [ $# -gt 0 ]; do
        case "$1" in
                --dump_to=*)
                        DOMAINS_FILE="${1#*=}"
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

# Making sure file is valid
if [ -z "$DOMAINS_FILE" ] ; then
        printf "$0: Error: Dump file path is not valid.\n" >> $LOG_FOLDER'general.err'
        exit 1
else
        if [ -f "$DOMAINS_FILE" ] && [ ! -w "$DOMAINS_FILE" ] ; then
                printf "$0: Error: Cannot write into the file. Check file permissions.\n" >> $LOG_FOLDER'general.err'
                exit 1
        else
                touch $DOMAINS_FILE &>/dev/null
                if [ ! -f "$DOMAINS_FILE" ] ; then
                        printf "$0: Error: Cannot create dump file. Check folder and it's permissions.\n" >> $LOG_FOLDER'general.err'
                        exit 1
                fi
        fi
fi

if [ -f "/etc/psa/.psa.shadow" ] ; then
        mysql -u admin -p`cat /etc/psa/.psa.shadow` -e 'SELECT www_root FROM psa.hosting' -NB 2>> $LOG_FOLDER'refresh_domains_list.err' 1>$DOMAINS_FILE
else
        printf "$0: Error: Can't find plesk authentication file. Are you running plesk?\n" >> $LOG_FOLDER'general.err'
fi
