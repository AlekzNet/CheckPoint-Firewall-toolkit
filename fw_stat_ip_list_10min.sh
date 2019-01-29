#!/bin/bash



# There must be at least two arguments:
# 1- file with a list of IP-addresses to search for
# 2- CheckPoint log file converted to text

if ((  $# < 2 )); then
	echo "Usage: $0 ip_list_file cp_firewall_log-1.txt cp_firewall_log-2.txt ..."
	exit 1
fi

# The format of the CheckPoint log file must conform the following format
# 2 - date
# 3 - time
# 4 - src
# 5 - dst
# 6 - proto
# 7 - service
# 8 - action

HEADER="num;date;time;src;dst;proto;service;action"


# Convert the list of IP addresses from the file in the 1st argument 
# to the following format:
# 1\.2\.3\.4|7\.6\.5\.4

iplist=`cat $1 | tr -s '\n\t ' '|' | sed -e 's/|$//' -e 's/^|//' -e 's/\./\\\./g'`
echo $iplist
shift

for file in $*
do

# Check if the header is correct

	if ( ! zcat $file | head -1 | fgrep $HEADER > /dev/null 2>&1 ); then
		echo "$file - wrong file format"
		continue
	else
		echo "$file - good file"
		zcat $file | fgrep -v $HEADER | egrep "$iplist" | egrep -v "drop|reject|control"  | awk -F\; '
# "min" sets the minimum amount of connectins/log entries		
		BEGIN { date="_"; time="_"; total=0; min=0; TMPFILE="/tmp/fwstat.tmp";}
		{
			curtime=gensub("^([0-9][0-9]:[0-9]).*","\\1","g",$3);
			if ( curtime == $3 ) curtime=gensub("^([0-9]:[0-9]).*","0\\1","g",$3);
#			print curtime;
			if ( date == "_") date = $2;
			if ( time == "_") time = curtime;
			if ( date != $2 || time != curtime) {
				print date, time "0", "total=", total,"=========="
				for (i in conn) {
					if (conn[i] > min ) print conn[i], i >> TMPFILE;
				}
				fflush();
				system("sort -rn " TMPFILE "| head -20");
				system("echo \  >" TMPFILE);
				date=$2; 
				time=curtime;
				delete conn;
# Counting either sources (4) or destinations (5)
				conn[$4]++;
				total=1;
			}
			else {
# Counting either sources (4) or destinations (5)				
				conn[$4]++;
				total++;

			}
		}'
	fi
done   

