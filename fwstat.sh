#!/bin/bash

# 2 - date
# 3 - time
# 4 - src
# 5 - dst
# 6 - proto
# 7 - service
# 8 - action

HEADER="num;date;time;src;dst;proto;service;action"


for file in $*
do
	if ( ! head -1 $file | fgrep $HEADER > /dev/null 2>&1 ); then
		echo "$file - wrong file format"
		continue
	else
		echo "$file - good file"
		cat $file | fgrep -v $HEADER | egrep -v "drop|reject|control"  | awk -F\; '
		BEGIN { date="_"; time="_"; total=0; min=100; TMPFILE="/tmp/fwstat.tmp";}
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
				conn[$4]++;
				total=1;
			}
			else {
				conn[$4]++;
				total++;			

			}
		}'
	fi
done   
	
