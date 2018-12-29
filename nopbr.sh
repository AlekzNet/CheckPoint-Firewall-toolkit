#!/bin/bash
# Remove all PBR tables and rules from CheckPoint GAIA config

BACKUP=~/`uname -n`_`date +'%Y%m%d_%H%M'`.config

arg=$1

if [[ $arg == "yes" ]]; then
	clish -c "show configuration" > $BACKUP
fi

for i in `clish -c "show configuration" | fgrep "set pbr table" | awk '{print $4}'`
#for i in `cat pbr1.txt | fgrep "set pbr table" | awk '{print $4}'`
do
	if [[ $arg == "yes" ]]; then
		clish -c "set pbr table $i off"
	else
		echo "clish -c \"set pbr table $i off\""
	fi
done

for i in `clish -c "show configuration" | fgrep "set pbr rule priority" | awk '{print $5}' | sort -u`
#for i in `cat pbr1.txt | fgrep "set pbr rule priority" | awk '{print $5}' | sort -u`
do
	if [[ $arg == "yes" ]]; then
		clish -c "set pbr rule priority $i off"
	else
		echo "clish -c \"set pbr rule priority $i off\""
	fi
done

if [[ $arg == "yes" ]]; then
	echo "Backup of the configuration is saved in $BACKUP" >&2
else
	echo "To implement the changes directly, run with $0 yes" >&2
	echo "Running in the test mode" >&2
fi
