#!/bin/bash

# Use the first part of the CheckPoint log names, e.g. 2019-01 or 2019-01-01
if ((  $# < 1 )); then
        echo "Usage: $0  2019-01 2019-02 ..."
        exit 1
fi

clock
OUTDIR=/var/log/2019.txt
FWLOGDIR=$FWDIR/log

LOGFILES=""
for i in $*
do
        LOGFILES="$LOGFILES  ${FWLOGDIR}/${i}*.log"
done

echo $LOGFILES

for i in $LOGFILES
do 
        echo $i
        out=`echo $i | sed -e 's%.*/%%g'`
        fwm logexport -n -p -i $i |  gzip -c - > ${OUTDIR}/$out.txt.gz
done
clock
