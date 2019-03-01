#!/bin/bash
date
# Firewall names to check
#FIREWALLS="firewall01 firewall02"
FIREWALLS="."

# Additional strng to look for
#NEEDLE1=255.255.255.255



# There must be at least two arguments:
# 1- file with a list of IP-addresses to search for
# 2- CheckPoint log file converted to text

if ((  $# < 2 )); then
        echo "Usage: $0 ip_list_file cp_firewall_log-1.txt cp_firewall_log-2.txt ..."
        exit 1
fi

# Output file name
OUTFILE="fwstat_$1_`date +'%Y%m%d_%H%M'`.log"

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
# Replace newlines, spaces and tabs with pipes
# Escape dots with backslashes
iplist=`cat $1 | tr -s '\n\t ' '|' | sed -e 's/|$//' -e 's/^|//' -e 's/\./\\\./g'`
echo $iplist

# Convert the list of IP addresses from the file in the 1st argument
# from  ;1.2.3.[0-9]; format to
# ^1\.2\.3\.[0-9]$

relist=`cat $1 | sed -e 's/^;/^/' -e 's/;$/$/' | tr -s '\n\t ' '|' | sed -e 's/|$//' -e 's/^|//' -e 's/\./\\\./g'`
echo $relist

shift

echo "Being saved to $OUTFILE"


files=""
for file in $*
do
        if ( ! zcat $file | head -1 | fgrep $HEADER > /dev/null 2>&1 ); then
                echo "$file - wrong file format"
                continue
        else
                echo "$file - good file"
                files=$files" "$file
        fi
done
echo $files

for fw in $FIREWALLS
do
        echo "==================== $fw ==========================="
        zcat $files | egrep -v "drop|reject|control" | fgrep -v ";udp;123;" | fgrep -v icmp | egrep "$iplist" | awk -F\; '
                # TMPFILE - temporary file will be overwritten
                # min - the threshhold for amount of connectins to be shown in the report
                BEGIN { min=0; TMPFILE="/tmp/fw_stat_ip_list_top_tmp.tmp";system("echo \  >" TMPFILE);}
                        { 
                                # Counting either sources (4) or destinations (5)
                                if ( $5 ~ "'$relist'" ) {
                                        src[$4]++;
                                        service=$6 "-" $7;
                                        srv[service]++;
                                        ipservice=$5 ":" service;
                                        pair[ipservice]++;
                                        connection=$4 " -> " $5 ":" service;
                                        conn[connection]++
                                }
                        }
                END {

                        print "====================  sources ==========================="
                        for ( i in src) {
                                if (src[i] >= min) print src[i],i >> TMPFILE;
                        }
                        fflush();
                        # Only the top 100. Change the "head" argument if needed
#                       system("sort -rn " TMPFILE "| head -100");
                        system("sort -rn " TMPFILE);
                        system("echo \  >" TMPFILE);


                        print "====================  services ==========================="
                        for ( i in srv) {
                                print srv[i],i >> TMPFILE;
                        }
                        fflush();
                        # Only the top 100. Change the "head" argument if needed
#                       system("sort -rn " TMPFILE "| head -100");
                        system("sort -rn " TMPFILE );
                        system("echo \  >" TMPFILE);


                        print "====================  destination-services ==========================="
                        for ( i in pair) {
                                if (pair[i] >= min) print pair[i],i >> TMPFILE;
                        }
                        fflush();
                        # Only the top 100. Change the "head" argument if needed
#                       system("sort -rn " TMPFILE "| head -100");
                        system("sort -rn " TMPFILE);
                        system("echo \  >" TMPFILE);

                        print "==================== sources-destination-services ==========================="
                        for ( i in conn) {
                                if (conn[i] >= min) print conn[i],i >> TMPFILE;
                        }
                        fflush();
                        # Only the top 100. Change the "head" argument if needed
#                       system("sort -rn " TMPFILE "| head -100");
                        system("sort -rn " TMPFILE);
                        system("echo \  >" TMPFILE);
                        }' 
done > $OUTFILE

echo "Saved to $OUTFILE"
date
