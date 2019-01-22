#!/bin/bash
cat $FWDIR/conf/objects.C|egrep ': \(.*[^)]$|:ipaddr' | fgrep -iv referenceobject | sed 's/^\s*:/:/' | awk ' 
BEGIN {ips=""; obj[2]="";}
/^: \(/ { if (ips != "") {
                        print obj[2],ips;
                        ips="";}
                        split($0,obj,"(");
                }

/^:ipaddr_first/ { split($0,ip,/^.* /);
                        ips = ips ip[2] "-";
                        next
                   }


/^:ipaddr/ { split($0,ip,/^.* /);
                         ips = ips ip[2];
                   }
