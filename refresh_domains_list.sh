#!/bin/bash

. /inotify_rsync/app/init.sh

# Making sure we are running as sudo
if [ "$EUID" -ne 0 ] ; then
	printf "$(date +"$DATE_FORMAT") $0: Please run as root\n" >> $LOG_FOLDER'general.err'
	exit 1
fi

# Parse Command Line Arguments
while [ $# -gt 0 ]; do
        case "$1" in
                --dump_to=*)
                        DOMAINS_FILE="${1#*=}"
                        ;;
                --help)
                        print_refresh_domains_list_help
                        ;;
                *)
                        printf "$(date +"$DATE_FORMAT") $0: Error: Invalid argument, run --help for valid arguments.\n" >> $LOG_FOLDER'general.err'
			print_refresh_domains_list_help
        esac
        shift
done

# Making sure file is valid
if [ -z "$DOMAINS_FILE" ] ; then
        printf "$(date +"$DATE_FORMAT") $0: Error: Dump file path is not valid.\n" >> $LOG_FOLDER'general.err'
        exit 1
else
        if [ -f "$DOMAINS_FILE" ] && [ ! -w "$DOMAINS_FILE" ] ; then
                printf "$(date +"$DATE_FORMAT") $0: Error: Cannot write into the file. Check file permissions.\n" >> $LOG_FOLDER'general.err'
                exit 1
        else
                touch $DOMAINS_FILE &>/dev/null
                if [ ! -f "$DOMAINS_FILE" ] ; then
                        printf "$(date +"$DATE_FORMAT") $0: Error: Cannot create dump file. Check folder and it's permissions.\n" >> $LOG_FOLDER'general.err'
                        exit 1
                fi
        fi
fi

# Refreshing the file based on Plesk hosts list
if [ -f "/etc/psa/.psa.shadow" ] ; then
        mysql -u admin -p`cat /etc/psa/.psa.shadow` -e 'SELECT DISTINCT www_root FROM psa.hosting' -NB 2>> $LOG_FOLDER'refresh_domains_list.err' 1>$DOMAINS_FILE
else
        printf "$(date +"$DATE_FORMAT") $0: Error: Can't find plesk authentication file. Are you running plesk?\n" >> $LOG_FOLDER'general.err'
fi
