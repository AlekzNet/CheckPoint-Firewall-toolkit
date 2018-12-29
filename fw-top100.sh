#!/bin/bash

# 2 - date
# 3 - time
# 4 - src
# 5 - dst
# 6 - proto
# 7 - service
# 8 - action

HEADER="num;date;time;src;dst;proto;service;action"
NEEDLE1=255.255.255.255
OUTFILE=fwstat_`date +'%Y%m%d_%H%M'`.log
echo "Saved to $OUTFILE"


files=""
for file in $*
do
	if ( ! head -1 $file | fgrep $HEADER > /dev/null 2>&1 ); then
		echo "$file - wrong file format"
		continue
	else
		echo "$file - good file"
		files=$files" "$file
	fi
done
echo $files

for fw in segotfcskf sgsinfcskf
do
	echo "==================== $fw ==========================="
	cat $files | fgrep $NEEDLE1 | fgrep $fw | awk -F\; '
		BEGIN { min=10; TMPFILE="/tmp/fwstat.tmp";}
			{ 
				src[$4]++;
				service=$6 "-" $7;
				srv[service]++;
				ipservice=$4 ":" service;
				pair[ipservice]++;
			}
		END {
			print "==================== top100 sources ==========================="
			for ( i in src) {
				if (src[i] >= min) print src[i],i >> TMPFILE;
			}
			fflush();
			system("sort -rn " TMPFILE "| head -100");
			system("echo \  >" TMPFILE);
			print "==================== top100 services ==========================="
			for ( i in srv) {
				print srv[i],i >> TMPFILE;
			}
			fflush();
			system("sort -rn " TMPFILE "| head -100");
			system("echo \  >" TMPFILE);		
			print "==================== top100 sources-services ==========================="
			for ( i in pair) {
				if (pair[i] >= min) print pair[i],i >> TMPFILE;
			}
			fflush();
			system("sort -rn " TMPFILE "| head -100");
			system("echo \  >" TMPFILE);
			}' 
done > $OUTFILE
